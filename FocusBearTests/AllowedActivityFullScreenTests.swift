//
//  AllowedActivityFullScreenTests.swift
//  FocusBearTests
//
//  Covers the decision behind "when an allowed app / focus mode habit is playing, the app shouldn't be
//  in full screen mode — return to full screen if the habit is paused/completed"
//  (report 2026-09-16_17-05-07).
//
//  The dangerous half of that feature is the RESTORE: a borderless window that reasserts itself over a
//  meeting the user is trying to join is a worse bug than the one being fixed. So most of these tests
//  are about the restore refusing to fire. No AppKit window is instantiated here — the decision is a
//  pure function of its inputs.
//
//  The `.windowRouting` cases are the follow-up to that report: the menu-bar expand button put the
//  borderless window straight back mid-habit, because it reached `checkIsFullScreenNeeded()` by a route
//  the habit lifecycle knew nothing about. The entry point is therefore an INPUT to the decision.
//
//  `CoordinatorSequenceTests` at the bottom is the second follow-up, and the important one: the habit
//  ending restored full screen and the teardown immediately undid it. Every individual decision was
//  correct; the ORDER was not. Those tests drive the real sequence of calls the app makes, which is the
//  only kind that can catch it.
//

@testable import Focus_Bear
import XCTest

final class AllowedActivityFullScreenTests: XCTestCase {

    /// The decision under test, with the defaults that describe "a routine is running full screen and an
    /// allowed-activity habit has just displaced it". Each test overrides only what it is about.
    private func action(trigger: AllowedActivityFullScreen.Trigger = .habitLifecycle,
                        isAllowedActivityHabitRunning: Bool,
                        isFullScreenSettingEnabled: Bool = true,
                        routineState: CURRENTSTATE = ._MORNING_HABIT_,
                        isFullScreenWindowShowing: Bool = false,
                        didLeaveFullScreenForHabit: Bool = true,
                        isMeetingSessionLive: Bool = false) -> AllowedActivityFullScreen.Action {
        AllowedActivityFullScreen.action(trigger: trigger,
                                         isAllowedActivityHabitRunning: isAllowedActivityHabitRunning,
                                         isFullScreenSettingEnabled: isFullScreenSettingEnabled,
                                         routineState: routineState,
                                         isFullScreenWindowShowing: isFullScreenWindowShowing,
                                         didLeaveFullScreenForHabit: didLeaveFullScreenForHabit,
                                         isMeetingSessionLive: isMeetingSessionLive)
    }

    // MARK: - Leaving full screen

    func testAnAllowedActivityHabitLeavesFullScreen() {
        // The whole point of the habit is to go and use another app, so the window must get out of the way.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: true,
                              isFullScreenWindowShowing: true,
                              didLeaveFullScreenForHabit: false),
                       .leaveFullScreen)
    }

    func testAnOrdinaryHabitDoesNotLeaveFullScreen() {
        // A normal timer habit is done in Focus Bear itself — full screen is exactly where it belongs.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false,
                              isFullScreenWindowShowing: true,
                              didLeaveFullScreenForHabit: false),
                       .doNothing)
    }

    func testAnAllowedActivityHabitInASmallWindowChangesNothing() {
        // Nothing to step aside from — and nothing that would later owe a restore.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: true,
                              isFullScreenWindowShowing: false,
                              didLeaveFullScreenForHabit: false),
                       .doNothing)
    }

    func testBackToBackAllowedActivityHabitsDoNotReShrink() {
        // The window is already out of the way from the previous allowed-activity habit.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: true, isFullScreenWindowShowing: false),
                       .doNothing)
    }

    // MARK: - Returning to full screen

    func testPausingOrCompletingRestoresFullScreen() {
        // Both reach the decision the same way: no allowed activity is running any more.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false), .restoreFullScreen)
    }

    func testAnOrdinaryHabitTakingOverRestoresFullScreen() {
        // The next habit in the routine is a normal one, so the routine's window belongs back on top.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false, routineState: ._CUSTOM_ROUTINE_),
                       .restoreFullScreen)
    }

    func testNothingIsRestoredThatWeDidNotShrink() {
        // The window may be small for any number of reasons that are not ours to undo.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false, didLeaveFullScreenForHabit: false),
                       .doNothing)
    }

    func testFullScreenIsNotRestoredWhileItIsAlreadyShowing() {
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false, isFullScreenWindowShowing: true),
                       .doNothing)
    }

    /// The follow-up report's consistency requirement: once the user has a full-screen window back by an
    /// explicit action, pausing the habit must not try to "restore" something already showing.
    /// `showFullSizeWindow()` clears the marker, so this is the state the later pause actually sees.
    func testPausingAfterTheUserDeliberatelyReEnteredFullScreenDoesNotRestoreAgain() {
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false,
                              isFullScreenWindowShowing: true,
                              didLeaveFullScreenForHabit: false),
                       .doNothing)
    }

    // MARK: - The guards that keep this from becoming a worse bug

    func testNothingIsRestoredWhenTheFullScreenSettingIsOff() {
        // The setting is the ceiling: this feature may put full screen back, never introduce it.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false, isFullScreenSettingEnabled: false),
                       .doNothing)
        // ...and with the setting off it must not step aside either, because it was never full screen.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: true,
                              isFullScreenSettingEnabled: false,
                              isFullScreenWindowShowing: false,
                              didLeaveFullScreenForHabit: false),
                       .doNothing)
    }

    func testAHabitFinishingDuringAMeetingSessionDoesNotRestoreFullScreen() {
        // The meeting path deliberately drops the routine window so the user can see and join the call.
        // Covering it again would be worse than the bug this fixes.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false, isMeetingSessionLive: true), .doNothing)
    }

    func testAPostponedRoutineDoesNotGetItsFullScreenWindowBack() {
        // The user has stepped out of the routine; full screen does not belong in a postpone state.
        for postponed: CURRENTSTATE in [._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_] {
            XCTAssertEqual(action(isAllowedActivityHabitRunning: false, routineState: postponed), .doNothing,
                           "state \(postponed) must not be re-covered")
        }
    }

    func testAnIdleRoutineDoesNotGetItsFullScreenWindowBack() {
        // The routine was quit or finished: nothing left to cover the screen for.
        XCTAssertEqual(action(isAllowedActivityHabitRunning: false, routineState: ._NOTHING_), .doNothing)
    }

    // MARK: - Window routing (the menu-bar expand button and every sidebar row)

    func testExplicitExpandDuringAnAllowedActivityHabitDoesNotGoFullScreen() {
        // The report: "I'm in an allowed app habit currently and I clicked the expand button in menu -
        // it went back to full screen Focus Bear." The user asked to SEE Focus Bear, not to be swallowed
        // by it while the habit's own app is what they are meant to be using.
        XCTAssertEqual(action(trigger: .windowRouting,
                              isAllowedActivityHabitRunning: true,
                              isFullScreenWindowShowing: true,
                              didLeaveFullScreenForHabit: false),
                       .leaveFullScreen)
    }

    func testExplicitExpandKeepsAnAlreadySmallWindowSmall() {
        // The key asymmetry with `.habitLifecycle`: "already small" must NOT mean "do nothing" here, or
        // the caller's own full-screen routing runs and covers the screen anyway — the actual bug.
        XCTAssertEqual(action(trigger: .windowRouting,
                              isAllowedActivityHabitRunning: true,
                              isFullScreenWindowShowing: false),
                       .leaveFullScreen)
    }

    func testExplicitExpandWithNoAllowedActivityHabitIsLeftAlone() {
        // Ordinary routing is none of this feature's business — the sidebar decides as it always did.
        XCTAssertEqual(action(trigger: .windowRouting,
                              isAllowedActivityHabitRunning: false,
                              isFullScreenWindowShowing: false),
                       .doNothing)
        XCTAssertEqual(action(trigger: .windowRouting,
                              isAllowedActivityHabitRunning: false,
                              isFullScreenWindowShowing: true),
                       .doNothing)
    }

    func testWindowRoutingNeverRestoresFullScreenItself() {
        // Only the habit lifecycle may hand full screen back. Routing that happens to satisfy every
        // restore condition must still not trigger one.
        XCTAssertEqual(action(trigger: .windowRouting,
                              isAllowedActivityHabitRunning: false,
                              isFullScreenWindowShowing: false,
                              didLeaveFullScreenForHabit: true),
                       .doNothing)
    }

    func testExpandDuringAPausedAllowedActivityHabitIsLeftAlone() {
        // A paused habit has already had full screen handed back, so the shim passes
        // `isAllowedActivityHabitActivelyPlaying` — false while paused — and expand behaves normally.
        // Otherwise expanding after a pause would shrink the window the pause just restored.
        XCTAssertEqual(action(trigger: .windowRouting,
                              isAllowedActivityHabitRunning: false,
                              isFullScreenWindowShowing: true),
                       .doNothing)
    }

    // MARK: Forgetting the step-aside (report 2026-09-21_10-04-09, follow-up)
    //
    // "I stopped the scrum meeting habit just before and it didn't return me to full screen."
    //
    // abortAllProcess() reset the coordinator, with a comment saying aborting ends the routine. It
    // does not — finishing a habit and starting the next one runs through it, 35 times in one
    // evening. The log shows the marker being wiped between the habit starting and ending:
    //
    //   21:42:12  leaveFullScreen (allowedActivity=true, holding=true, leftForHabit=true)
    //   21:42:43  call abort all process.
    //   21:42:43  doNothing (holding=false, leftForHabit=false)

    func testAStepAsideIsKeptWhileTheRoutineIsStillRunning() {
        for state in [CURRENTSTATE._EVENING_HABIT_, ._MORNING_HABIT_, ._CUSTOM_ROUTINE_,
                      ._SPECIAL_ACTIVITY_, ._BREATHING_] {
            XCTAssertFalse(AllowedActivityFullScreen.shouldForgetStepAside(routineState: state),
                           "\(state): a habit transition is not the end of the routine")
        }
    }

    func testItIsForgottenOnceTheRoutineIsOver() {
        for state in [CURRENTSTATE._NOTHING_, ._POSTPONE_MORNING_HABIT_, ._MICRO_BREAK_] {
            XCTAssertTrue(AllowedActivityFullScreen.shouldForgetStepAside(routineState: state),
                          "\(state): a stale marker must not let a later moment claim a restore")
        }
    }

    /// The end-to-end shape of the report, through the real decision: step aside for a habit, have
    /// the routine survive a transition, then end the habit and get the screen back.
    func testTheRoutineComesBackToFullScreenAfterAnAllowedActivityHabit() {
        let leaving = AllowedActivityFullScreen.action(
            trigger: .habitLifecycle, isAllowedActivityHabitRunning: true,
            isFullScreenSettingEnabled: true, routineState: ._EVENING_HABIT_,
            isFullScreenWindowShowing: true, didLeaveFullScreenForHabit: false,
            isMeetingSessionLive: false)
        XCTAssertEqual(leaving, .leaveFullScreen)

        // The transition that used to wipe the marker.
        XCTAssertFalse(AllowedActivityFullScreen.shouldForgetStepAside(routineState: ._EVENING_HABIT_))

        let returning = AllowedActivityFullScreen.action(
            trigger: .habitLifecycle, isAllowedActivityHabitRunning: false,
            isFullScreenSettingEnabled: true, routineState: ._EVENING_HABIT_,
            isFullScreenWindowShowing: false, didLeaveFullScreenForHabit: true,
            isMeetingSessionLive: false)
        XCTAssertEqual(returning, .restoreFullScreen,
                       "this is what never happened, because leftForHabit had been reset to false")
    }

    /// The bug, stated as a test: with the marker wiped, the same end-of-habit moment does nothing.
    func testWithoutTheMarkerTheHabitEndingRestoresNothing() {
        let returning = AllowedActivityFullScreen.action(
            trigger: .habitLifecycle, isAllowedActivityHabitRunning: false,
            isFullScreenSettingEnabled: true, routineState: ._EVENING_HABIT_,
            isFullScreenWindowShowing: false, didLeaveFullScreenForHabit: false,
            isMeetingSessionLive: false)
        XCTAssertEqual(returning, .doNothing)
    }

}

/// Drives the **real sequence of calls the app makes**, not a single decision in isolation.
///
/// Report 2026-09-16 20:25: "After the habit ended it should have gone back to full screen mode but it
/// didn't." The log showed both halves firing in the same second —
///
///     restoreFullScreen (habitLifecycle allowedActivity=false showing=false leftForHabit=true)
///     leaveFullScreen   (windowRouting  allowedActivity=true  showing=true  leftForHabit=false)
///
/// — because `eveningHabitOver()` calls `showHabitsView()`, which routes the window, BEFORE it clears
/// `isAnyAllowedFocusModeActivityRunning` / `currentHabitPlaying`. Routing therefore still believed a
/// habit was playing and tore the restore straight back down. Every `action(...)` answer above was
/// individually right, so no amount of testing the decision alone could have caught it.
final class AllowedActivityFullScreenCoordinatorSequenceTests: XCTestCase {

    /// A tiny stand-in for the window: the sequence tests need the *result* of each step to feed the
    /// next one, exactly as the real `isFullScreenVisible` does. No AppKit involved.
    private struct WindowUnderTest {
        var isFullScreenShowing: Bool
        var coordinator = AllowedActivityFullScreen.Coordinator()
        var settingEnabled = true
        var state: CURRENTSTATE = ._EVENING_HABIT_
        var meetingLive = false

        private var context: AllowedActivityFullScreen.Context {
            .init(isFullScreenSettingEnabled: settingEnabled,
                  routineState: state,
                  isFullScreenWindowShowing: isFullScreenShowing,
                  isMeetingSessionLive: meetingLive)
        }

        private mutating func perform(_ action: AllowedActivityFullScreen.Action) {
            switch action {
            case .leaveFullScreen: isFullScreenShowing = false
            case .restoreFullScreen: isFullScreenShowing = true
            case .doNothing: break
            }
        }

        /// `startTimerHabit` / `btnPauseClicked` / `performTimerCount` / `skipHabit`.
        @discardableResult
        mutating func habitLifecycle(isAllowedActivityHabit: Bool) -> AllowedActivityFullScreen.Action {
            let action = coordinator.habitLifecycle(isAllowedActivityHabit: isAllowedActivityHabit, in: context)
            perform(action)
            return action
        }

        /// Anything reaching `checkIsFullScreenNeeded()` — the teardown's `showHabitsView()`, the
        /// menu-bar expand button, a sidebar row.
        @discardableResult
        mutating func windowRouting() -> AllowedActivityFullScreen.Action {
            let action = coordinator.windowRouting(in: context)
            perform(action)
            return action
        }
    }

    /// The regression this round is about.
    func testCompletingAHabitLeavesTheWindowFullScreenEvenThoughTeardownRoutesTheWindow() {
        var window = WindowUnderTest(isFullScreenShowing: true)
        window.habitLifecycle(isAllowedActivityHabit: true)          // startTimerHabit
        XCTAssertFalse(window.isFullScreenShowing, "the habit must get the screen out of the way")

        window.habitLifecycle(isAllowedActivityHabit: false)         // performTimerCount / btnIAmDoneClicked
        XCTAssertTrue(window.isFullScreenShowing, "finishing the habit must hand full screen back")

        // eveningHabitOver() -> showHabitsView() -> boxHabits.isSelected -> checkIsFullScreenNeeded().
        // This runs while the old globals still say a habit is playing; it must not undo the restore.
        window.windowRouting()
        XCTAssertTrue(window.isFullScreenShowing, "teardown routing must not tear the restore back down")
    }

    func testPausingThenResumingTogglesFullScreenBothWays() {
        var window = WindowUnderTest(isFullScreenShowing: true)
        window.habitLifecycle(isAllowedActivityHabit: true)
        XCTAssertFalse(window.isFullScreenShowing)

        window.habitLifecycle(isAllowedActivityHabit: false)         // pause
        XCTAssertTrue(window.isFullScreenShowing)

        window.habitLifecycle(isAllowedActivityHabit: true)          // resume
        XCTAssertFalse(window.isFullScreenShowing)

        window.habitLifecycle(isAllowedActivityHabit: false)         // finish
        XCTAssertTrue(window.isFullScreenShowing)
    }

    /// The 20:25 fix must not regress: expand mid-habit still may not cover the screen.
    func testExpandMidHabitStillDoesNotCoverTheScreen() {
        var window = WindowUnderTest(isFullScreenShowing: true)
        window.habitLifecycle(isAllowedActivityHabit: true)
        XCTAssertFalse(window.isFullScreenShowing)

        window.windowRouting()                                        // menu-bar expand button
        XCTAssertFalse(window.isFullScreenShowing, "expand must not swallow the screen mid-habit")

        // ...and the habit still gets its full screen back when it ends.
        window.habitLifecycle(isAllowedActivityHabit: false)
        XCTAssertTrue(window.isFullScreenShowing)
    }

    /// Expanding after a pause must leave the restored full screen alone — the pause already handed it
    /// back, so the habit no longer holds the screen.
    func testExpandAfterAPauseLeavesFullScreenAlone() {
        var window = WindowUnderTest(isFullScreenShowing: true)
        window.habitLifecycle(isAllowedActivityHabit: true)
        window.habitLifecycle(isAllowedActivityHabit: false)          // pause -> full screen back
        XCTAssertTrue(window.isFullScreenShowing)

        window.windowRouting()
        XCTAssertTrue(window.isFullScreenShowing, "a paused habit must not re-shrink on expand")
    }

    /// A live meeting still vetoes the restore, through the whole sequence.
    func testAHabitEndingDuringAMeetingNeverGetsFullScreenBack() {
        var window = WindowUnderTest(isFullScreenShowing: true)
        window.habitLifecycle(isAllowedActivityHabit: true)
        XCTAssertFalse(window.isFullScreenShowing)

        window.meetingLive = true
        window.habitLifecycle(isAllowedActivityHabit: false)          // habit ends mid-meeting
        XCTAssertFalse(window.isFullScreenShowing, "a meeting must never be re-covered")

        window.windowRouting()
        XCTAssertFalse(window.isFullScreenShowing)
    }

    /// With the setting off the sequence must never produce a full-screen window at any step.
    func testTheWholeSequenceNeverIntroducesFullScreenWhenTheSettingIsOff() {
        var window = WindowUnderTest(isFullScreenShowing: false)
        window.settingEnabled = false
        for step in [true, false, true, false] {
            window.habitLifecycle(isAllowedActivityHabit: step)
            window.windowRouting()
            XCTAssertFalse(window.isFullScreenShowing, "setting off must stay windowed at every step")
        }
    }

    /// However the user got full screen back by an explicit route, the marker must not still claim a
    /// step-aside — otherwise the next lifecycle moment "restores" something already showing.
    func testAFullScreenWindowShownByAnotherRouteClearsTheDebt() {
        var window = WindowUnderTest(isFullScreenShowing: true)
        window.habitLifecycle(isAllowedActivityHabit: true)
        XCTAssertTrue(window.coordinator.didLeaveFullScreenForHabit)

        // e.g. endFullScreenCalendarGrant(), which calls showFullSizeWindow() directly.
        window.isFullScreenShowing = true
        window.coordinator.noteFullScreenWindowShown()
        XCTAssertFalse(window.coordinator.didLeaveFullScreenForHabit)

        XCTAssertEqual(window.habitLifecycle(isAllowedActivityHabit: false), .doNothing)
        XCTAssertTrue(window.isFullScreenShowing)
    }

    /// Aborting the routine must not leave a step-aside owing that a later, unrelated moment could claim.
    func testAbortingTheRoutineForgetsTheDebt() {
        var window = WindowUnderTest(isFullScreenShowing: true)
        window.habitLifecycle(isAllowedActivityHabit: true)
        XCTAssertTrue(window.coordinator.didLeaveFullScreenForHabit)

        window.coordinator.reset()
        XCTAssertFalse(window.coordinator.didLeaveFullScreenForHabit)
        XCTAssertFalse(window.coordinator.isAllowedActivityHabitHoldingTheScreen)
        XCTAssertEqual(window.habitLifecycle(isAllowedActivityHabit: false), .doNothing)
    }
}

// MARK: - Which display the routine takes, and which get covered (report 2026-09-25_14-51-33)
//
// Skipping an allowed-app habit from the menu restored full screen on the display the window had
// been left on, while the blank covers went on every display except the primary. With the window on
// the secondary display, a cover landed on top of it and hid the "Why do you want to skip?" question.
// An extension of the CI-selected class rather than its own, because CI selects classes by name.
extension AllowedActivityFullScreenTests {
    private static let primary = CGRect(x: 0, y: 0, width: 1600, height: 900)
    private static let left = CGRect(x: -1024, y: 234, width: 1024, height: 666)

    func testTheFocusedDisplayWinsSoTheQuestionAppearsWhereTheUserClicked() {
        // The menu was on the primary display; the window had been left on the left one.
        let host = FullScreenDisplays.host(preferred: [Self.primary, Self.left], all: [Self.primary, Self.left])
        XCTAssertEqual(host, Self.primary)
    }

    func testTheRoutinesDisplayIsNeverCovered() {
        for host in [Self.primary, Self.left] {
            let covered = FullScreenDisplays.screensToCover(all: [Self.primary, Self.left], host: host)
            XCTAssertFalse(covered.contains(host), "the routine's own display must stay uncovered")
            XCTAssertEqual(covered.count, 1, "every other display is covered")
        }
    }

    func testTheSecondaryDisplayCanHostTheRoutine() {
        // The old rule covered every display but the primary, whichever one the window was on.
        XCTAssertEqual(FullScreenDisplays.screensToCover(all: [Self.primary, Self.left], host: Self.left), [Self.primary])
    }

    func testADisconnectedDisplayFallsBackToThePrimary() {
        let unplugged = CGRect(x: 1600, y: 0, width: 2560, height: 1440)
        XCTAssertEqual(FullScreenDisplays.host(preferred: [unplugged, nil], all: [Self.primary, Self.left]), Self.primary)
        XCTAssertEqual(FullScreenDisplays.screensToCover(all: [Self.primary, Self.left], host: unplugged), [Self.left])
    }

    func testASingleDisplayGetsNoCovers() {
        XCTAssertEqual(FullScreenDisplays.screensToCover(all: [Self.primary], host: Self.primary), [])
    }
}
