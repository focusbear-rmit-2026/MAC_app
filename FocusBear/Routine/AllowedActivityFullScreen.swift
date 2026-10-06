//
//  AllowedActivityFullScreen.swift
//  Focus Bear
//
//  "When an allowed app / focus mode habit is playing, the app shouldn't be in full screen mode.
//  (Return to full screen if the habit is paused/completed)" — report 2026-09-16_17-05-07.
//
//  An allowed-activity habit exists precisely so the person goes and uses another app (`allowApps`)
//  or works under an allowed focus mode (`allowedFocusMode`) — see `habit.isAllowedActivityHabit`.
//  The routine's borderless full-screen window covering the whole screen defeats that, so it steps
//  aside for the duration of such a habit and comes back when the habit pauses, is skipped, or ends.
//
//  `action(...)` is pure and AppKit-free so the decision can be unit-tested
//  (`AllowedActivityFullScreenTests`) without standing up a window. `applyFullScreen(for:)` is the
//  thin shim that carries the decision out.
//

import CoreGraphics
import Foundation

enum AllowedActivityFullScreen {

    /// What should happen to the routine's borderless full-screen window.
    enum Action: Equatable {
        /// Shrink to the ordinary titled window so the habit's app is actually usable.
        case leaveFullScreen
        /// Put the borderless window back — the habit that displaced it is paused or over.
        case restoreFullScreen
        /// Leave the window exactly as it is.
        case doNothing
    }

    /// Why the window is being reconsidered. The entry point is an INPUT to the decision, not a
    /// special case at the call site — otherwise every new route back into full screen reopens the
    /// same bug (report 2026-09-16_17-05-07 follow-up: the menu-bar expand button did exactly that).
    enum Trigger: Equatable {
        /// A habit started, paused, resumed, was skipped or finished.
        case habitLifecycle
        /// Anything else that sizes the main window: the menu-bar expand button, a sidebar row, the
        /// re-assert after leaving macOS's own full screen. The user asked to *see* Focus Bear, which
        /// is not the same as asking to be swallowed by it.
        case windowRouting
    }

    /// The decision, as a function of its inputs only.
    ///
    /// - Parameters:
    ///   - trigger: which entry point is asking. See `Trigger`.
    ///   - isAllowedActivityHabitRunning: for `.habitLifecycle`, the habit now playing opens an allowed
    ///     app or runs an allowed focus mode (`habit.isAllowedActivityHabit`) — false also standing for
    ///     "no habit is playing any more". For `.windowRouting`, whether such a habit is *actively*
    ///     playing right now — which `Coordinator` tracks as `isAllowedActivityHabitHoldingTheScreen`,
    ///     since a paused or finished habit has already had its full screen handed back.
    ///   - isFullScreenSettingEnabled: `SettingsManagerObject.isFullScreenEnabled`. The ceiling: with
    ///     full screen off, nothing here may ever *introduce* it.
    ///   - routineState: `currentState`. Full screen only belongs in some states at all — a postponed or
    ///     idle routine is not one of them (`FullScreenStates.covered`).
    ///   - isFullScreenWindowShowing: `mainWindowController.isFullScreenVisible` — the live state.
    ///   - didLeaveFullScreenForHabit: we are the ones who shrank the window for a habit. Restoring is
    ///     only ever undoing our own step-aside, never a fresh decision to cover the screen.
    ///   - isMeetingSessionLive: a Late No More meeting focus session is running. That path deliberately
    ///     drops the routine window so the call is visible; re-covering it would be a worse bug than the
    ///     one this fixes.
    static func action(trigger: Trigger,
                       isAllowedActivityHabitRunning: Bool,
                       isFullScreenSettingEnabled: Bool,
                       routineState: CURRENTSTATE,
                       isFullScreenWindowShowing: Bool,
                       didLeaveFullScreenForHabit: Bool,
                       isMeetingSessionLive: Bool) -> Action {
        if isAllowedActivityHabitRunning {
            switch trigger {
            case .habitLifecycle:
                // Nothing to step aside from unless the borderless window is genuinely up. This keeps
                // `didLeaveFullScreenForHabit` honest: we only ever claim a step-aside we actually made.
                return isFullScreenWindowShowing ? .leaveFullScreen : .doNothing
            case .windowRouting:
                // Idempotent, and deliberately NOT conditioned on the window currently being full
                // screen: the point is that this route must not PUT it there. Answering "do nothing"
                // when it happens to be small already would let the caller's own full-screen routing
                // run and cover the screen anyway — which is the bug being fixed.
                return .leaveFullScreen
            }
        }
        // No allowed-activity habit is running. Ordinary window routing is then none of our business:
        // only the habit lifecycle may hand full screen back.
        guard trigger == .habitLifecycle else { return .doNothing }
        // Restore is conditional, never automatic — every one of these has to still hold.
        guard didLeaveFullScreenForHabit,
              !isFullScreenWindowShowing,
              FullScreenStates.shouldUseFullScreen(setting: isFullScreenSettingEnabled, state: routineState),
              !isMeetingSessionLive else { return .doNothing }
        return .restoreFullScreen
    }

    /// Whether a step-aside made for an allowed-activity habit should be forgotten.
    ///
    /// `abortAllProcess()` resets the coordinator with the comment "aborting ends the routine". It
    /// does not: it is called on every habit TRANSITION — 35 times in one evening — because
    /// finishing a habit and starting the next one goes through it. So the marker saying "we shrank
    /// the window for a habit" was being wiped between the habit starting and the habit ending:
    ///
    ///   21:42:12  leaveFullScreen (allowedActivity=true, holding=true, leftForHabit=true)
    ///   21:42:43  call abort all process.          <- habit finished, next one starting
    ///   21:42:43  doNothing (holding=false, leftForHabit=false)
    ///
    /// With `leftForHabit` false the restore can never fire, so the routine never came back to full
    /// screen (report 2026-09-21_10-04-09, follow-up: "I stopped the scrum meeting habit just before
    /// and it didn't return me to full screen").
    ///
    /// Forget it only when the routine really is over. Mid-routine the state is still a routine
    /// state, which is exactly what tells the two apart.
    static func shouldForgetStepAside(routineState: CURRENTSTATE) -> Bool {
        !FullScreenStates.covered.contains(routineState)
    }
}

/// The mutable state this feature keeps, extracted as a value type so the ORDER of lifecycle and
/// routing calls can be unit-tested without standing up a window.
///
/// The ordering is the whole point. `action(...)` alone was correct at every individual moment and
/// still produced the wrong window: on habit completion the restore fired, and then the `*Over()`
/// teardown called `showHabitsView()` — which routes the window — *before* it cleared
/// `isAnyAllowedFocusModeActivityRunning` / `currentHabitPlaying`. Routing therefore still read "an
/// allowed-activity habit is playing" and tore the just-restored full screen back down in the same
/// second (report 2026-09-16 20:25). A test of the decision in isolation can never catch that.
extension AllowedActivityFullScreen {

    /// Everything about the world outside this feature, read fresh at each call.
    struct Context: Equatable {
        let isFullScreenSettingEnabled: Bool
        let routineState: CURRENTSTATE
        let isFullScreenWindowShowing: Bool
        let isMeetingSessionLive: Bool
        /// The display the borderless window is on — `NSScreen.displayID` of its full-screen host.
        var fullScreenDisplayID: CGDirectDisplayID? = nil
    }

    struct Coordinator {
        /// We shrank the window for a habit, so we owe it a restore.
        private(set) var didLeaveFullScreenForHabit = false
        /// The habit lifecycle's own answer to "is an allowed-activity habit the thing the user is
        /// doing right now?".
        ///
        /// Window routing reads THIS and never infers it from `isAllowedActivityHabitCurrentlyRunning`,
        /// because those globals are cleared late in teardown (see the note above). The lifecycle is the
        /// single authority: it is told at the start, pause, resume, skip and finish of every habit, so
        /// by the time teardown routes the window this already says "no habit".
        private(set) var isAllowedActivityHabitHoldingTheScreen = false
        /// The display the routine was full screen on when it first stepped aside, so it can go back
        /// there once the habit is over (`FullScreenDisplays.hostAfterAllowedActivityHabit`).
        ///
        /// Kept through a pause: pausing — which is how Skip starts — brings full screen back on the
        /// display the user clicked in, so the skip question appears there, and a resume steps aside
        /// from THAT display. Neither may replace the display the routine really came from, which is
        /// why only the first step-aside records it. Handed out, and forgotten, when the habit is over.
        private(set) var displayBeforeHabit: CGDirectDisplayID?

        /// A habit started, paused, resumed, was skipped or finished.
        mutating func habitLifecycle(isAllowedActivityHabit: Bool, in context: Context) -> Action {
            isAllowedActivityHabitHoldingTheScreen = isAllowedActivityHabit
            return resolve(.habitLifecycle, isAllowedActivityHabit, context)
        }

        /// The allowed-activity habit is over — skipped, finished, cut off, or replaced by an ordinary
        /// habit. Returns the display the routine should go back to, once.
        mutating func takeDisplayBeforeHabit() -> CGDirectDisplayID? {
            defer { displayBeforeHabit = nil }
            return displayBeforeHabit
        }

        /// Something is about to size the main window — the menu-bar expand button, a sidebar row, the
        /// re-assert after leaving macOS's own full screen.
        mutating func windowRouting(in context: Context) -> Action {
            resolve(.windowRouting, isAllowedActivityHabitHoldingTheScreen, context)
        }

        /// The borderless window was (re)created by some route — see `showFullSizeWindow()`. However it
        /// got there, we no longer owe anyone a restore.
        mutating func noteFullScreenWindowShown() { didLeaveFullScreenForHabit = false }

        /// The routine ended or was aborted: forget everything, so nothing stale can claim a restore.
        mutating func reset() {
            didLeaveFullScreenForHabit = false
            isAllowedActivityHabitHoldingTheScreen = false
            displayBeforeHabit = nil
        }

        private mutating func resolve(_ trigger: Trigger, _ isRunning: Bool, _ context: Context) -> Action {
            let action = AllowedActivityFullScreen.action(
                trigger: trigger,
                isAllowedActivityHabitRunning: isRunning,
                isFullScreenSettingEnabled: context.isFullScreenSettingEnabled,
                routineState: context.routineState,
                isFullScreenWindowShowing: context.isFullScreenWindowShowing,
                didLeaveFullScreenForHabit: didLeaveFullScreenForHabit,
                isMeetingSessionLive: context.isMeetingSessionLive)
            switch action {
            case .leaveFullScreen:
                // Only a step-aside from an actual full-screen window is one we owe a restore for. A
                // routing call that merely keeps an already-small window small must not claim one, or a
                // later pause would "restore" a window the user never had covered.
                if context.isFullScreenWindowShowing {
                    didLeaveFullScreenForHabit = true
                    if displayBeforeHabit == nil { displayBeforeHabit = context.fullScreenDisplayID }
                }
            case .restoreFullScreen:
                didLeaveFullScreenForHabit = false
            case .doNothing:
                break
            }
            return action
        }
    }
}

/// The app's single instance of the state above.
var allowedActivityFullScreenCoordinator = AllowedActivityFullScreen.Coordinator()

/// Steps the routine's full-screen window aside for an allowed-activity habit, or puts it back once one
/// is paused/skipped/finished. Safe to call from any habit-lifecycle point: it is a no-op unless the
/// decision says otherwise.
///
/// Must be called at EVERY lifecycle moment, including the ones that change nothing about the window:
/// it is what keeps `isAllowedActivityHabitHoldingTheScreen` — the flag window routing trusts — current.
///
/// - Parameters:
///   - isAllowedActivityHabit: pass `false` from the pause / completion / skip points, which is what asks
///     for the window back.
///   - isPausingHabit: the habit is only paused, not over. Full screen comes back on the display the user
///     clicked in (that is where the skip question belongs); every other `false` means the habit is over,
///     and the routine goes back to the display it was on before the habit.
func applyFullScreen(forAllowedActivityHabit isAllowedActivityHabit: Bool, isPausingHabit: Bool = false) {
    let isHabitOver = !isAllowedActivityHabit && !isPausingHabit
    applyAllowedActivityFullScreen(description: "lifecycle(allowedActivity=\(isAllowedActivityHabit) over=\(isHabitOver))",
                                   isHabitOver: isHabitOver) { coordinator, context in
        coordinator.habitLifecycle(isAllowedActivityHabit: isAllowedActivityHabit, in: context)
    }
}

/// The window-routing entry point: the menu-bar expand button, a sidebar row, or any other route that
/// would otherwise size the main window while an allowed-activity habit is playing.
///
/// - Returns: true if the window was deliberately kept out of full screen, in which case the caller must
///   NOT run its own full-screen routing.
@discardableResult
func keepWindowedForAllowedActivityHabit() -> Bool {
    applyAllowedActivityFullScreen(description: "routing") { coordinator, context in
        coordinator.windowRouting(in: context)
    }
}

/// - Returns: true if this call actually moved the window (either direction).
@discardableResult
private func applyAllowedActivityFullScreen(
    description: String,
    isHabitOver: Bool = false,
    decide: (inout AllowedActivityFullScreen.Coordinator, AllowedActivityFullScreen.Context) -> AllowedActivityFullScreen.Action
) -> Bool {
    guard let windowController = mainWindowControllerObj, windowController.window != nil,
          let rootViewController = mainViewControllerObj else { return false }
    let context = AllowedActivityFullScreen.Context(
        isFullScreenSettingEnabled: SettingsManagerObject.isFullScreenEnabled,
        routineState: currentState,
        isFullScreenWindowShowing: windowController.isFullScreenVisible,
        isMeetingSessionLive: currentAccountabilityBuddySession?.isMeeting == true,
        fullScreenDisplayID: windowController.fullScreenDisplay?.displayID)
    let action = decide(&allowedActivityFullScreenCoordinator, context)
    let displayBeforeHabit = isHabitOver ? allowedActivityFullScreenCoordinator.takeDisplayBeforeHabit() : nil
    let hostAfterHabit = displayBeforeHabit.flatMap(windowController.hostAfterAllowedActivityHabit)
    addLog(text: "allowed-activity full screen: \(action) (\(description) state=\(currentState) showing=\(context.isFullScreenWindowShowing) holding=\(allowedActivityFullScreenCoordinator.isAllowedActivityHabitHoldingTheScreen) leftForHabit=\(allowedActivityFullScreenCoordinator.didLeaveFullScreenForHabit) display=\(displayLogName(context.fullScreenDisplayID)) returnTo=\(displayLogName(displayBeforeHabit)))")
    switch action {
    case .leaveFullScreen:
        // `showSmallSizeWindow()` alone only restyles — the window would keep the full-screen FRAME and
        // carry on covering everything, just with a title bar. `showSmallScreen` is the canonical shrink:
        // it restyles, drops the secondary-monitor covers, and resizes down to the ordinary window so the
        // habit's app is actually reachable.
        rootViewController.showSmallScreen(showMinimumSize: true)
        return true
    case .restoreFullScreen:
        // The canonical re-entry: re-applies the borderless style AND re-frames the window to the screen.
        // Flagged as the restore so it is not itself treated as ordinary routing and turned back around.
        rootViewController.checkIsFullScreenNeeded(isRestoringAfterAllowedActivityHabit: true, on: hostAfterHabit)
        return true
    case .doNothing:
        // Skipping paused the habit first, which already brought full screen back — on the display the
        // user clicked Skip in. Now that the habit is over, the routine goes home.
        guard hostAfterHabit != nil, windowController.isFullScreenVisible else { return false }
        windowController.moveFullScreenWindow(to: hostAfterHabit)
        return true
    }
}
