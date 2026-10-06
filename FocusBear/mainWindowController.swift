//
//  mainWindowController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

/// The custom borderless fullscreen window still covers the display. Only its interactive content
/// moves below the visible menu bar / camera housing; titled and native-fullscreen windows keep
/// AppKit's own content geometry.
/// Which states full-screen mode actually covers.
///
/// Full screen exists to hold the user inside a ROUTINE that is running. It was being applied to
/// every screen the setting could reach, so a postponed routine — the user getting on with their
/// day — and a one-minute micro break both took over the whole display, with no traffic lights and
/// only "Exit Fullscreen" to escape (report 2026-09-14_16-31-53).
enum FullScreenStates {
    /// Routine states: the routine itself, the flows that belong to it (shutdown, focus summary,
    /// breathing, an allowed-activity habit, the abort prompt — which must not become an escape
    /// hatch) and onboarding, which drives the window itself.
    static let covered: Set<CURRENTSTATE> = [
        ._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_, ._SHUTOFFMAC_,
        ._FOCUS_SUMMARY_, ._BREATHING_, ._SPECIAL_ACTIVITY_, ._ABORT_, ._ONBOARDING_,
    ]

    /// Notably NOT covered: `_POSTPONE_*` (the routine is deferred, the user is working),
    /// `_MICRO_BREAK_` (a break is not a routine), `_NOTHING_` and `_LOGIN_`.
    static func shouldUseFullScreen(setting: Bool, state: CURRENTSTATE) -> Bool {
        setting && covered.contains(state)
    }
}

/// What activating the app — ⌘-Tab, the app switcher, a Dock click — should do about the main window.
///
/// ⌘-Tab itself is not observable: the system app switcher swallows the keystroke and never delivers it
/// to the app. The *activation* it causes is, and that is all this needs. `applicationDidBecomeActive`
/// already fired on every switch-to; it simply did nothing with it, so switching back to Focus Bear
/// after closing its window left the user looking at no window at all (report 2026-09-16_16-01-15).
///
/// The rule is: **restore only when the activation came from outside the app.** A self-activation — the
/// app putting up its own menu, a Late No More meeting announcement, a nudge — is not someone asking for
/// the main window, and answering one with a window would drop it over a meeting prompt or a meeting.
///
/// AppKit will not tell us where an activation came from. `NSApplication.didBecomeActiveNotification`
/// carries no `userInfo`; `NSWorkspace`'s activation notifications name the app that became active, not
/// whatever initiated it; and even macOS 14's cooperative activation exposes no origin (the deployment
/// target here is macOS 11 regardless). Nor is there a choke point to intercept: the app self-activates
/// from ~110 call sites across three different calls (`NSApp.activate`, `NSApplication.shared.activate`,
/// `NSRunningApplication.current.activate`), so no subclass or single wrapper catches them all.
///
/// So origin is **declared, not detected**: the paths that bring the app to the front for a purpose of
/// their own call `AppDelegate.noteSelfActivation()`, and the decision is deferred by
/// `activationSettleSeconds` so that declaration lands first. Two backstops keep the declaration list
/// from having to be exhaustive: a self-activation almost always exists in order to SHOW something, so a
/// window that OPENS during the settle period is treated as one (`didAnotherWindowOpenSinceActivation`);
/// and the routine states own their own window anyway. The list is only needed where neither backstop
/// applies — see `noteSelfActivation`'s callers.
///
/// What is on screen *already* is deliberately not a reason to do nothing. An earlier version stopped
/// whenever any other window was visible; the user's answer to that was explicit — "if an alert/nudge is
/// showing, it should still open the full window, if menu is open it shouldn't" — and it is also what
/// kept the fix from ever firing in practice: any second window the app happened to have up was enough
/// to answer a ⌘-Tab with nothing (report 2026-09-16_16-01-15, fourth round: activations at 16:54:51,
/// 16:55:02, 16:55:04 and 16:55:09 on 17 Sep, all `other=true`, `main=false`, no window shown).
///
/// Pure, so the policy can be tested without instantiating a single AppKit window.
enum AppActivationRestore {
    enum Action: Equatable {
        /// The main window is already up, the menu is, or the window is deliberately absent — leave it
        /// alone.
        case doNothing
        /// Put the main window back as it is.
        case showMainWindow
        /// Put the main window back, restoring its title bar first: the controller is still configured
        /// borderless from a full-screen state that has since ended (a routine the user postponed), and
        /// reopening it borderless would drop them into the screen-filling window they just escaped.
        case showMainWindowAsSmallWindow
    }

    /// States where the routine state machine — not the user's app switching — decides whether the main
    /// window is on screen. A routine keeps running with its window closed (an allowed-activity habit
    /// backgrounds itself), a micro break can be dismissed, onboarding drives the window itself. In all
    /// of them "no window" is a deliberate outcome. An allowed-app habit is the exception when the user
    /// switches back explicitly; menu, popup, and self-activation guards still take precedence.
    ///
    /// Not listed, and so restorable: `_NOTHING_` (the ordinary case), `_LOGIN_` (the login screen IS the
    /// main window — `showAskLoginWindow` already routes the menu-bar click to it) and the `_POSTPONE_*`
    /// states (the routine is deferred, the user is working, the main window is an ordinary browsable
    /// window — and `_POSTPONE_MORNING_HABIT_` is the state the report was filed from).
    static let statesThatOwnMainWindow: Set<CURRENTSTATE> = [
        ._MORNING_HABIT_, ._EVENING_HABIT_, ._MICRO_BREAK_, ._SHUTOFFMAC_, ._BREATHING_,
        ._ABORT_, ._FOCUS_SUMMARY_, ._SPECIAL_ACTIVITY_, ._CUSTOM_ROUTINE_, ._ONBOARDING_,
    ]

    /// How long after launch an activation is assumed to be the system's rather than the user's.
    ///
    /// macOS activates a foreground launch about a second in (visible in the logs as an
    /// `applicationDidBecomeActive` one second after "running app version"), long before the app has
    /// decided whether the user is logging in, onboarding, or going straight to the main window. Focus
    /// Bear also starts at login, and popping its window open on every boot would be its own bug. An
    /// app started into the background never gets that activation, so a ⌘-Tab to it — which can only
    /// come later than this — is still restored.
    static let launchSettlingSeconds: TimeInterval = 5

    /// How long the decision waits after activation, so the app's own reason for coming to the front
    /// can land first.
    ///
    /// Deciding inside `applicationDidBecomeActive` is too early, and the user's own logs prove it: on a
    /// menu-bar click `applicationDidBecomeActive` is logged **before** `togglePopover start`, so at the
    /// moment of activation the popover is opening but not yet open and `isMenuVisible` is still false.
    /// One settle period later the popover is up (or `noteSelfActivation()` has been called), and both
    /// signals read correctly. Short enough that a real ⌘-Tab still feels immediate.
    static let activationSettleSeconds: TimeInterval = 0.35

    /// How long a `noteSelfActivation()` marker stays valid.
    ///
    /// The marker can be set either just before the activation (a deep link that activates us) or just
    /// after it (the menu-bar click, whose action is delivered after `applicationDidBecomeActive`), so
    /// the window has to straddle both. It is also consumed once read, so a self-activation suppresses
    /// exactly one decision rather than blunting every ⌘-Tab for the next couple of seconds.
    static let selfActivationWindowSeconds: TimeInterval = 2

    /// How much of the main window has to land on an attached screen before it counts as "already on
    /// screen". Below this it is stranded, and the user is looking at nothing.
    static let minimumVisibleFractionOfMainWindow: CGFloat = 0.25

    /// Whether a window sits where the user can actually see it.
    ///
    /// `NSWindow.isVisible` means *ordered in*, not *on a display*. A window left on a monitor that has
    /// since been unplugged, or pushed off the edge of the desktop, stays `isVisible == true` forever —
    /// so the restore decision read "you already have a window" and did nothing, on a ⌘-Tab where the
    /// user could see no window at all (report 2026-09-16_16-01-15, third round: two activations logged
    /// 12:01:31 and 12:01:34 on 17 Sep, neither followed by a restore).
    ///
    /// A fraction rather than any overlap at all: a window poking one pixel onto a display is not a
    /// window you can use.
    static func isOnVisibleScreen(windowFrame: NSRect, screenFrames: [NSRect]) -> Bool {
        let area = windowFrame.width * windowFrame.height
        guard area > 0 else { return false }
        let visible = screenFrames.reduce(CGFloat.zero) { total, screen in
            let overlap = screen.intersection(windowFrame)
            return total + (overlap.isNull ? 0 : overlap.width * overlap.height)
        }
        return visible / area >= minimumVisibleFractionOfMainWindow
    }

    /// A running focus session is deliberately NOT an input. A session hides no window of its own, and
    /// someone who switches to Focus Bear mid-session is usually after the session screen itself.
    ///
    /// - Parameter isSelfActivation: the app brought *itself* to the front for a purpose of its own (see
    ///   `AppDelegate.noteSelfActivation`). Only an activation that came from OUTSIDE the app — ⌘-Tab,
    ///   the app switcher, the Dock — is a request for the main window.
    /// - Parameter didAnotherWindowOpenSinceActivation: a window of ours arrived DURING the settle period,
    ///   i.e. the app came to the front in order to show it. That is an undeclared self-activation, and
    ///   the main window must not land on top of whatever it came to say. A window that was already there
    ///   when the user switched in is not this, and no longer suppresses anything.
    /// - Parameter isMainWindowConfiguredBorderless: `mainWindowController.isFullScreenVisible`.
    /// - Parameter isAnotherFocusBearWindowFront: the app's key/main window is one of ITS OWN non-main
    ///   windows (the quit window, and any future window the user works in). When the user switched back
    ///   TO such a window they were not asking for the main window, so opening it on top is wrong. This is
    ///   deliberately the *front/focused* window rather than "anything visible": an incidental alert or
    ///   nudge merely on screen must still let a ⌘-Tab open the main window (report 2026-09-16). Because it
    ///   keys off "is a non-main window the front one" rather than naming any window, a new window that
    ///   hits this same bug is covered automatically, with no per-window special case (#2585).
    /// - Parameter didAnotherWindowCloseSinceActivation: one of our OWN non-main windows was on screen when
    ///   the activation was recorded but is gone by decision time — i.e. a Focus Bear popup CLOSED during
    ///   the settle. Dismissing a popup while the app is in the background activates the app (clicking a
    ///   background window brings its app forward) and closes the popup in the same click; the deferred
    ///   decision then sees "app active, no window" and would wrongly open the main window. The front-window
    ///   check above can't catch it because the popup is already gone at decision time — this is the same
    ///   snapshot read the other way. It does NOT fire for a window that merely stays open across the settle
    ///   (a nudge on a ⌘-Tab), so it can't re-break report 2026-09-16.
    static func action(secondsSinceLaunch: TimeInterval,
                       isSelfActivation: Bool,
                       isMainWindowVisible: Bool,
                       didAnotherWindowOpenSinceActivation: Bool,
                       didAnotherWindowCloseSinceActivation: Bool,
                       isMenuVisible: Bool,
                       isAnotherFocusBearWindowFront: Bool,
                       state: CURRENTSTATE,
                       isMainWindowConfiguredBorderless: Bool,
                       isAllowedActivityHabit: Bool = false) -> Action {
        // Activation fires constantly — every switch-to, every alert, every self-activation the app does
        // when it puts up a window of its own — so everything below stays cheap and idempotent.
        guard secondsSinceLaunch >= launchSettlingSeconds else { return .doNothing }
        guard !isSelfActivation, !didAnotherWindowOpenSinceActivation else { return .doNothing }
        guard !didAnotherWindowCloseSinceActivation else { return .doNothing }
        guard !isMainWindowVisible, !isMenuVisible else { return .doNothing }
        guard !isAnotherFocusBearWindowFront else { return .doNothing }
        let isAllowedRoutineHabit = isAllowedActivityHabit &&
            [CURRENTSTATE._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_].contains(state)
        guard !statesThatOwnMainWindow.contains(state) || isAllowedRoutineHabit else { return .doNothing }
        return isMainWindowConfiguredBorderless ? .showMainWindowAsSmallWindow : .showMainWindow
    }
}

enum MainWindowContentLayout {
    static func topInset(contentFrameOnScreen: NSRect, screenFrame: NSRect,
                         visibleScreenFrame: NSRect, screenSafeAreaTop: CGFloat,
                         isCustomFullScreen: Bool, styleMask: NSWindow.StyleMask) -> CGFloat {
        guard isCustomFullScreen, !styleMask.contains(.titled), !styleMask.contains(.fullScreen) else { return 0 }
        let safeTop = min(visibleScreenFrame.maxY, screenFrame.maxY - max(0, screenSafeAreaTop))
        return min(contentFrameOnScreen.height, max(0, contentFrameOnScreen.maxY - safeTop))
    }

    /// The single width cap kept on the main window's content view (see `constrainWidthToWindow`).
    static let viewportWidthConstraintIdentifier = "mainWindowViewportWidth"

    static func viewportWidthCap(on root: NSView) -> NSLayoutConstraint? {
        root.constraints.first { $0.identifier == viewportWidthConstraintIdentifier }
    }

    /// The widest a window could ever be dragged: across every screen the desktop spans.
    /// Pure so the ceiling used during a live resize can be unit-tested.
    static func liveResizeCeiling(screenFrames: [NSRect]) -> CGFloat {
        guard let union = screenFrames.reduce(nil as NSRect?, { $0?.union($1) ?? $1 }) else { return 0 }
        return union.width
    }

    /// AppKit can grow an unconstrained window content view beyond the actual window when a split
    /// pane's intrinsic content resists compression. The window still fits the display, but its
    /// trailing task panel and Exit Fullscreen control are clipped. Keep the root tied to the real
    /// viewport, so the pane's text compresses instead. Refresh on layout/resize; never use the
    /// already-expanded root frame as the source of the width.
    ///
    /// The cap is also a ceiling on the WINDOW — see `allowWindowWidth` — so while the user is
    /// dragging an edge it is held open to the whole desktop instead of being pulled back onto the
    /// size being dragged away from (report 2026-09-16_10-36-19: the window grew taller but not wider,
    /// because every layout pass mid-drag re-pinned the cap to the width it already had).
    static func constrainWidthToWindow(_ root: NSView) {
        guard let window = root.window, window.contentView === root else { return }
        let viewport = window.contentLayoutRect.width
        guard viewport.isFinite, viewport > 0 else { return }
        let width = window.inLiveResize
            ? max(viewport, liveResizeCeiling(screenFrames: NSScreen.screens.map(\.frame)))
            : viewport
        if let constraint = viewportWidthCap(on: root) {
            if abs(constraint.constant - width) > 0.5 { constraint.constant = width }
        } else {
            // A CAP, not a pin. As an equality this was a required `width == N` on the content view,
            // which Auto Layout defended against the user dragging the window's edge: the window
            // could not be made narrower at all (report 2026-09-14_15-04-30). `<=` still keeps the
            // content inside the viewport — which is the whole point.
            let constraint = root.widthAnchor.constraint(lessThanOrEqualToConstant: width)
            constraint.identifier = viewportWidthConstraintIdentifier
            constraint.isActive = true
        }
    }

    /// Raise the viewport cap so a resize that is ABOUT to happen isn't vetoed.
    ///
    /// AppKit reads a required width constraint on a window's content view as a limit on the window
    /// itself, so a cap sitting on the current viewport width is a ceiling the window can never pass:
    /// verified offscreen — with the cap in place a window asked to grow by 300pt gained the height
    /// and none of the width, which is exactly what was reported. Lowering the constraint's priority
    /// does not help (AppKit honours an optional cap when it derives that limit), and there is nothing
    /// relative to constrain against: `contentLayoutGuide` is nil in the borderless full-screen window,
    /// and the window's own frame view grows with the content, so neither contains anything. The cap
    /// therefore has to be lifted before the frame changes; `constrainWidthToWindow` brings it back
    /// down to the real viewport on the next layout pass, which is what keeps content contained.
    ///
    /// Only ever raises: shrinking is the layout pass's job.
    @discardableResult
    static func allowWindowWidth(_ width: CGFloat, on root: NSView?) -> Bool {
        guard let root = root, let cap = viewportWidthCap(on: root),
              width.isFinite, width > cap.constant else { return false }
        cap.constant = width
        return true
    }

    /// The single height cap kept on the borderless full-screen window's content view.
    static let fullScreenHeightConstraintIdentifier = "mainWindowFullScreenHeight"

    static func fullScreenHeightCap(on root: NSView) -> NSLayoutConstraint? {
        root.constraints.first { $0.identifier == fullScreenHeightConstraintIdentifier }
    }

    /// How tall the main window's content may be: its display's height while it is the borderless full
    /// screen, and unlimited otherwise — a titled window, or macOS's own full screen, is AppKit's to size.
    static func fullScreenHeightCeiling(isCustomFullScreen: Bool, styleMask: NSWindow.StyleMask,
                                        hostFrame: NSRect?) -> CGFloat? {
        guard isCustomFullScreen, !styleMask.contains(.titled), !styleMask.contains(.fullScreen),
              let hostFrame = hostFrame, hostFrame.height.isFinite, hostFrame.height > 0 else { return nil }
        return hostFrame.height
    }

    /// Keeps the borderless full-screen window no taller than its display.
    ///
    /// AppKit holds a window's size at only `windowSizeStayPut` priority, so content whose required
    /// minimum is taller than the window makes AppKit GROW the window, keeping its top edge. After an
    /// external monitor was unplugged mid-routine the window was framed to the 666pt laptop screen and
    /// then grew to ~744pt, its bottom — the routine's pause button, the sidebar's Help & Support —
    /// hanging below the screen (report 2026-10-05_08-42-51). `maxSize` and `contentMaxSize` do not
    /// stop that growth (verified offscreen); a required cap on the content view does — the same
    /// effect the width cap above has to work around. The content then compresses inside the window
    /// instead of resizing it, and a cap lowered onto a window that has already grown pulls it back,
    /// top edge kept. Passing nil removes the cap.
    static func capFullScreenHeight(_ height: CGFloat?, on root: NSView?) {
        guard let root = root else { return }
        let existingCap = fullScreenHeightCap(on: root)
        guard let height = height else {
            existingCap?.isActive = false
            return
        }
        if let cap = existingCap {
            if abs(cap.constant - height) > 0.5 { cap.constant = height }
            return
        }
        let cap = root.heightAnchor.constraint(lessThanOrEqualToConstant: height)
        cap.identifier = fullScreenHeightConstraintIdentifier
        cap.isActive = true
    }

    /// Both caps on the content view are also ceilings on the window, so they have to make room for a
    /// frame BEFORE it is applied — e.g. full screen moving onto a taller display.
    static func prepareContent(_ root: NSView?, forFrame frame: NSRect, heightCeiling: CGFloat?) {
        allowWindowWidth(frame.width, on: root)
        capFullScreenHeight(heightCeiling, on: root)
    }

    /// The Main storyboard pins boxContainer.top to its root view. A positive AppKit top-anchor
    /// constant moves the box down, including for the storyboard's unflipped NSView/NSBox pair.
    @discardableResult
    static func apply(topInset: CGFloat, to content: NSView, in root: NSView) -> Bool {
        guard let constraint = root.constraints.first(where: {
            ($0.firstItem as? NSView) === content && $0.firstAttribute == .top &&
                ($0.secondItem as? NSView) === root && $0.secondAttribute == .top
        }) else { return false }
        if abs(constraint.constant - topInset) > 0.5 { constraint.constant = topInset }
        return true
    }

    /// The storyboard nests its custom minimize control inside boxContainer. Window chrome must
    /// stay at the window's top edge when the sidebar/page host moves below the fullscreen inset.
    /// Keep the original view (including its action and tracking area), above the content host.
    static func attachWindowControls(_ controls: NSView, to root: NSView) {
        guard controls !== root, controls.superview !== root else { return }
        controls.removeFromSuperview()
        controls.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(controls, positioned: .above, relativeTo: nil)
        NSLayoutConstraint.activate([
            controls.topAnchor.constraint(equalTo: root.topAnchor),
            controls.leadingAnchor.constraint(equalTo: root.leadingAnchor)
        ])
    }
}

class mainWindowController: NSWindowController, NSWindowDelegate {
    
    let smallWindowMinWidth = 900
    let smallWindowMinHeight = 450
    let smallWindowAvgHeight = 600
    let smallWindowAvgWidth = 1008
    let spaceKeyCode:uint16 = 49
    let escKeyCode:uint16 = 53

    // Issue #2091 — a user who steps away is given a grace period: the 60s away-timer re-centres the
    // routine window once (moveWindowToCenter). Only AFTER that first re-centre, if the user drags the
    // window aside again in the same routine session, do we ask whether to postpone rather than
    // silently fighting them. This only applies to the small, titled routine window — the borderless
    // full-screen window has no title bar and isn't movable-by-background, so it can't be dragged.
    let dragAwayDriftThreshold: CGFloat = 40
    let dragAwaySettleDelay: TimeInterval = 0.35
    private var dragAwayCheckWorkItem: DispatchWorkItem?
    // Set true once the away-timer re-centres the routine window; reset at each routine-session start
    // (currentState.didSet). Gates whether a further drag triggers the postpone prompt.
    var hasRecenteredRoutineWindowThisSession = false
    // The origin the window sat at right after the programmatic re-centre, so "moved away" is measured
    // from where WE put it (exact) rather than a guessed geometric centre.
    var routineWindowCenteredOrigin: NSPoint?
    // Guards the windowDidMove that our own center() triggers so it isn't read as a user drag.
    private var isProgrammaticallyCenteringRoutineWindow = false

    var isFullScreenVisible = false

    /// The display chosen when the borderless window was last shown; the window's frame and the blank
    /// covers both read it, so they cannot pick different displays. See `FullScreenDisplays`.
    var fullScreenHostScreen: NSScreen?
    private var fullScreenDisplaySelection = FullScreenDisplaySelection<CGDirectDisplayID>()

    /// The display the routine goes full screen on: the one chosen at entry, else the window's own.
    var fullScreenDisplay: NSScreen? {
        FullScreenDisplays.reconfiguredHost(preferredIDs: [fullScreenHostScreen?.displayID, window?.screen?.displayID],
                                            all: NSScreen.screens, displayID: { $0.displayID })
    }

    /// A saved fullscreen preference alone must not cover other displays while Help or another
    /// ordinary titled window is open, or after the main window has been hidden.
    var shouldCoverSecondaryScreens: Bool {
        guard isFullScreenVisible, let window = window else { return false }
        return window.isVisible && !window.isMiniaturized && !window.styleMask.contains(.titled)
    }
    func reconcileFullScreenDisplays(isFullScreenEnabled: () -> Bool = checkIsFullScreenEnabled,
                                    rebuildCovers: () -> Void) {
        hideBlankWindowInSecondaryMonitor()
        guard shouldCoverSecondaryScreens, isFullScreenEnabled(), let window = window else { return }
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        let preferences = fullScreenDisplaySelection.preferencesAfterReconfiguration(
            primaryID: screens.first?.displayID, rememberedID: fullScreenHostScreen?.displayID,
            currentID: window.screen?.displayID)
        guard let host = FullScreenDisplays.reconfiguredHost(preferredIDs: preferences, all: screens,
                                                             displayID: { $0.displayID }) else { return }
        fullScreenHostScreen = host
        if window.frame != host.frame {
            addLog(text: "full screen refit: window \(window.frame) -> display \(displayLogName(host.displayID)) \(host.frame)")
        }
        MainWindowContentLayout.prepareContent(window.contentView, forFrame: host.frame, heightCeiling: host.frame.height)
        window.setFrame(host.frame, display: true)
        refreshContentInsets()
        rebuildCovers()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
//        if checkIsFullScreenEnabled(){
//            showFullSizeWindow()
//        }else{
//            showSmallSizeWindow()
//        }
       // showSmallSizeWindow()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        
        self.window?.appearance = getAppAppearance()
        self.contentViewController =  mainViewControllerObj
        NotificationCenter.default.addObserver(self, selector: #selector(refreshContentInsets),
                                              name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func refreshContentInsets() {
        (contentViewController as? ViewController)?.updateFullScreenContentInsets()
    }

    func windowDidResize(_ notification: Notification) { refreshContentInsets() }
    func windowDidChangeScreen(_ notification: Notification) { refreshContentInsets() }
    func windowDidBecomeKey(_ notification: Notification) {
        refreshContentInsets()
        // A fullscreen request may arrive before showWindow makes the host visible. Retry only
        // after AppKit orders it in, so the visibility guard never drops legitimate first-show covers.
        restoreSecondaryScreenCoversIfNeeded()
    }

    func windowWillClose(_ notification: Notification) {
        hideBlankWindowInSecondaryMonitor()
    }

    #if DEBUG
    /// While the routine steps aside for a UI test run, any route that orders it back in is undone here.
    func windowDidChangeOcclusionState(_ notification: Notification) {
        UITestRunnerYieldController.shared.mainWindowVisibilityChanged()
    }
    #endif

    private func restoreSecondaryScreenCoversIfNeeded() {
        guard arrWindows.isEmpty, shouldCoverSecondaryScreens, checkIsFullScreenEnabled() else { return }
        // Lifecycle events only restore coverage; they must not run the legacy modal cleanup.
        appdelegate?.showExtraWindows()
    }
    
    
    /// - Parameter requestedHost: the display to use when the caller knows better than the usual rule —
    ///   the display the routine was on before an allowed-activity habit that is now over.
    func showFullSizeWindow(on requestedHost: NSScreen? = nil){
        fullScreenDisplaySelection.beginEntry(primaryID: NSScreen.screens.first?.displayID,
            requestedID: requestedHost?.displayID, continuing: isFullScreenVisible && window?.isVisible == true)
        // Chosen once, before anything is framed or covered. See `FullScreenDisplays.preferredHosts`.
        let preferred = FullScreenDisplays.preferredHosts(requested: requestedHost, isAlreadyFullScreen: isFullScreenVisible,
                                                          focused: NSScreen.main, current: window?.screen, state: currentState,
                                                          primary: NSScreen.screens.first, isWindowVisible: window?.isVisible == true)
        fullScreenHostScreen = FullScreenDisplays.host(preferred: preferred, all: NSScreen.screens)
        if fullScreenHostScreen != window?.screen {
            addLog(text: "full screen host: display \(displayLogName(fullScreenHostScreen?.displayID)) (window was on \(displayLogName(window?.screen?.displayID)), requested \(displayLogName(requestedHost?.displayID)))")
        }
        isFullScreenVisible = true
        // However the window got back to full screen — this restore, or a route that bypasses
        // `checkIsFullScreenNeeded()` entirely such as `endFullScreenCalendarGrant()` — we no longer owe
        // anyone a step-aside restore. Clearing it HERE, at the one place the borderless window is
        // actually created, is what keeps the marker honest without enumerating entry points.
        allowedActivityFullScreenCoordinator.noteFullScreenWindowShown()
        // Optional-chained rather than force-unwrapped (#2522): `window` can legitimately be nil in a
        // race between a window-state change and this call landing, and the rest of the codebase
        // already treats mainWindowControllerObj.window as nilable (customBlockingScheduleData.swift,
        // habitsVc.swift) — this was the one place that did not.
        window?.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these
        window?.canHide = false
        window?.isExcludedFromWindowsMenu = true
        window?.hidesOnDeactivate = false
        window?.isRestorable = false
        window?.animationBehavior = .none
//        window!.styleMask = .borderless
        window?.styleMask = [.borderless, .resizable]// The window needs to be resizable because when a new screen is added at runtime, the window reframe does not work properly.// resizable added on 1/9/25 on version 2.27.408
        window?.backingType = .buffered
        self.window?.minSize = NSSize(width: 900, height: 450)// unused
        self.window?.title = ""
        refreshContentInsets()
        // Also cover the transition when an already-key titled Help window becomes fullscreen.
        restoreSecondaryScreenCoversIfNeeded()
        
        if isMainWindowLoaded{
            mainViewControllerObj!.boxTopButtons.isHidden = false
            habitsVcObj?.startDateTimer()
            if self.window?.isVisible ?? false{
               // mainViewControllerObj?.setframe() //
            }
            let btnTitle = "Please spare me"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                habitsVcObj?.btnAbort.title = common.value(forKey: "buttonAbortText") as? String ?? btnTitle // 
            }
        }
    }
    
    /// See `FullScreenDisplays.hostAfterAllowedActivityHabit`.
    func hostAfterAllowedActivityHabit(displayBeforeHabit: CGDirectDisplayID) -> NSScreen? {
        FullScreenDisplays.hostAfterAllowedActivityHabit(displayBeforeHabit: displayBeforeHabit, focused: NSScreen.main,
                                                         all: NSScreen.screens, displayID: { $0.displayID })
    }

    /// Moves a borderless window that is already full screen to `host`, re-placing the blank covers
    /// around it. Used when an allowed-activity habit is over while its skip question left the routine on
    /// the display the user clicked in.
    func moveFullScreenWindow(to host: NSScreen?) {
        guard isFullScreenVisible, let host = host, host != fullScreenDisplay else { return }
        // The covers are built per display around the host, so they have to be rebuilt, not moved.
        hideBlankWindowInSecondaryMonitor()
        showFullSizeWindow(on: host)
        mainViewControllerObj?.setframe()
    }

    /// Approval may start/reveal a focus session without navigating to a different sidebar item.
    /// Its routing deliberately preserves existing window size, so finish the routine's fullscreen
    /// transition explicitly after the approval callback unwinds. Never interrupt a newer routine.
    func restoreWindowAfterPostponement(stateProvider: @escaping () -> CURRENTSTATE = { currentState }) {
        let postponedState = stateProvider()
        guard [CURRENTSTATE._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_].contains(postponedState),
              isFullScreenVisible, let postponedWindow = window else { return }
        DispatchQueue.main.async { [weak self, weak postponedWindow] in
            guard let self = self, let window = postponedWindow, self.window === window,
                  stateProvider() == postponedState, self.isFullScreenVisible,
                  !window.styleMask.contains(.fullScreen) else { return }
            // A style-mask change calls viewWillDisappear. Keep the newly opened focus/Help page,
            // including unsaved input, just as checkIsFullScreenNeeded preserves it on entry.
            let root = window.contentViewController as? ViewController
            let previousIgnore = root?.shouldIgnoreViewWilDisappear ?? false
            root?.shouldIgnoreViewWilDisappear = true
            defer { root?.shouldIgnoreViewWilDisappear = previousIgnore }
            self.showSmallSizeWindow()
        }
    }

    /// Reusing a loaded routine view does not trigger its window layout lifecycle. Reframe and
    /// order the host before rebuilding covers so an old cover cannot obscure the restored page.
    func restoreRoutineWindowAfterAppointment(
        prepareLayout: () -> Void = { mainViewControllerObj?.checkIsFullScreenNeeded() },
        showSecondaryCovers: () -> Void = { showBlankWindowInSecondaryMonitor() }
    ) {
        hideBlankWindowInSecondaryMonitor()
        prepareLayout()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        // Layout/key-window callbacks may have built covers using the previous frame.
        hideBlankWindowInSecondaryMonitor()
        showSecondaryCovers()
    }

    func showSmallSizeWindow(){
        isFullScreenVisible = false
        hideBlankWindowInSecondaryMonitor()
        // Optional-chained here too — see showFullSizeWindow above (#2522).
        window?.isRestorable = true
        window?.collectionBehavior = [.fullScreenAllowsTiling, .fullScreenPrimary]
        self.window?.minSize = NSSize(width: smallWindowMinWidth, height: smallWindowMinHeight)
        if !(self.window?.styleMask.contains(.fullScreen) ?? false){// It means the user was on a small screen and clicked full screen, so no change is needed. If we change the styleMask at this stage, it may cause a crash.
            window?.styleMask = []
            window?.styleMask.insert([.titled, .closable, .resizable])// works good
        }

//        self.window?.styleMask = [.resizable, .titled, .closable]// don't use this
        window?.isExcludedFromWindowsMenu = false
        self.window?.title = appName
        window?.animationBehavior = .default
        window?.hasShadow = true
        window?.canHide = true
        refreshContentInsets()
       
        if isMainWindowLoaded{
            mainViewControllerObj!.boxTopButtons.isHidden = true
            habitsVcObj?.dateTimeTimer?.invalidate()
            habitsVcObj?.lblCurrentDateTime.isHidden = true
         
            let btnTitle = "Postpone"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                habitsVcObj?.btnAbort.title = common.value(forKey: "buttonPostponeText") as? String ?? btnTitle
            }
            if currentState == ._ONBOARDING_{
                let btnTitle = "Skip"
                if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                    habitsVcObj?.btnAbort.title = dic.value(forKey: "buttonSkipText") as? String ?? btnTitle
                }
            }
        }
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {// The window needs to be resizable because when a new screen is added at runtime, the window reframe does not work properly.// resizable added on 1/9/25 on version 2.27.408
        if isFullScreenVisible{
            return sender.frame.size // ignore user resize
        }else{
            // The viewport cap is also the window's own maximum width, so lift it to the size being
            // resized to before AppKit applies it (report 2026-09-16_10-36-19).
            MainWindowContentLayout.allowWindowWidth(frameSize.width, on: sender.contentView)
            return frameSize
        }
    }

    /// A drag starts before any layout pass can notice `inLiveResize`, so open the ceiling here —
    /// otherwise the first resize event of the drag is clamped to the width the window already has.
    func windowWillStartLiveResize(_ notification: Notification) {
        guard !isFullScreenVisible, let root = window?.contentView else { return }
        MainWindowContentLayout.allowWindowWidth(
            MainWindowContentLayout.liveResizeCeiling(screenFrames: NSScreen.screens.map(\.frame)), on: root)
    }

    /// The drag is over, so the cap can be pulled back onto the window the user settled on — which is
    /// what keeps the Day Plan's content inside the viewport.
    func windowDidEndLiveResize(_ notification: Notification) { refreshContentInsets() }
    
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        addLog(text: "windowShouldClose delegate called")
        
        if currentState == ._ONBOARDING_ || currentState == ._LOGIN_{
            NSApp.terminate(self)
            return false;
        }
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._CUSTOM_ROUTINE_{
            // Allowed-activity habits (allowed apps / websites / focus mode) keep running in the
            // background, so minimising or closing the window should just background it — never the
            // postpone prompt (which only makes sense for normal timer habits). This used to be gated
            // on the Habits tab not being selected, so it leaked into the postpone flow whenever the
            // user was actually looking at the player.
            if isAllowedActivityHabitCurrentlyRunning { // allowed-activity habit runs in background; window can go
                if currentAction == ._INPROGRESS_{
                    if timerViewcontrollerObj?.isActivityPaused ?? false{
                        leftMenuVcObj?.showHabitsView()
                        timerViewcontrollerObj?.btnPauseClicked(self)
                        return false
                    }
                }
                return true
            }
            
            // window close if allowed if non timer based habits are running
            if currentAction == ._INPROGRESS_{
                if currentHabitPlaying != nil{
                    if timerViewcontrollerObj?.isActivityPaused ?? false{
                        leftMenuVcObj?.showHabitsView()
                        timerViewcontrollerObj?.btnPauseClicked(self)
                        return false
                    }else{
                        return true
                    }
                }else if currentRelaxHabitPlaying != nil{
                    if relaxModeWcObj != nil{
                        if timerViewcontrollerObj?.isActivityPaused ?? false{
                            leftMenuVcObj?.showHabitsView()
                            timerViewcontrollerObj?.btnPauseClicked(self)
                            return false
                        }else{
                            return true
                        }
                    }
                }
            }
            
            
            if currentState == ._MICRO_BREAK_ {// if break warning is visble then close window is allowed to user. after end of warning window will be visible again
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        return true
                    }
                }
            }
            
            let views = getHabitsVcObject().view.subviews
            if views.count != 1{// it means sub views are added so nothing will happen, user will need to close subviews first(logquantity view, password box)
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                    if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
                        leftMenuVcObj?.showHabitsView()
                    }
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if !(leftMenuVcObj?.boxCustomRoutine.isSelected ?? false){
                        leftMenuVcObj?.showCustomRoutineView()
                    }
                }else if currentState == ._MICRO_BREAK_{
                    if !(leftMenuVcObj?.boxMicroBreaks.isSelected ?? false){
                        leftMenuVcObj?.showBreaksView()
                    }
                }
                
                return false
            }

            if habitsVcObj?.btnAbort.isHidden ?? false{
                return false
            }else{
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                    if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
                        leftMenuVcObj?.showHabitsView()
                    }
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if !(leftMenuVcObj?.boxCustomRoutine.isSelected ?? false){
                        leftMenuVcObj?.showCustomRoutineView()
                    }
                }else if currentState == ._MICRO_BREAK_{
                    if !(leftMenuVcObj?.boxMicroBreaks.isSelected ?? false){
                        leftMenuVcObj?.showBreaksView()
                    }
                }
                getHabitsVcObject().abortCurrentState()
            }
           
            return false
        }
        
        if currentState == ._ONBOARDING_{
            getHabitsVcObject().abortCurrentState()
            return false
        }
        
        
        if leftMenuVcObj?.boxEditHabits.isSelected ?? false{
            if areSettingsEdited{
                leftMenuVcObj?.showAlertSettingsEdited()
                areSettingsEdited = false
                return false
            }
        }
        
        
        if isFocusCompletedViewVisibled(){
            addLog(text: "focus mode completed Window auto close from window close")
            focusCompletedVcObj!.takeBreakClicked(isCloseWindowClicked: true)
            return true
        }
        
        if isGettingSchema{
            return false
        }
        
        if currentState == ._SHUTOFFMAC_{
            if !(shutOffTimeVcObj?.btnGetAccessNow.isHidden ?? true){
                if mainViewControllerObj?.isEnterPasswordViewVisible() ?? false{
                    addLog(text: "Enter password View is visible:- return;")
                    return false
                }
                if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
                    leftMenuVcObj?.showHabitsView()
                }
                shutOffTimeVcObj?.btnGetAccessNowClicked(self)
            }else{
                addLog(text: "btn get access now is hidden:- return;")
            }
            return false
        }
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        print(event.keyCode)

        // ── Keyboard Shortcuts settings panel recording ──────────────────────────
        if activeShortcutRecorder != .none {
            handleKeyboardShortcutRecording(event: event)
            return
        }
        // ───────────────────────────────────────────────────────────────────────
    }
    
    
    // MARK: - Keyboard Shortcuts panel recording

    /// Handles a key event when the Keyboard Shortcuts settings panel is recording a shortcut.
    private func handleKeyboardShortcutRecording(event: NSEvent) {
        // ESC cancels recording
        if event.keyCode == escKeyCode {
            keyboardShortcutsSettingsVcObj?.cancelRecording()
            return
        }

        guard event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option) ||
              event.modifierFlags.contains(.control) || event.modifierFlags.contains(.shift) else {
            // No modifier — ignore and cancel
            keyboardShortcutsSettingsVcObj?.cancelRecording()
            return
        }

        var recordChar = ""
        var iserror = false

        if let specialKey = event.specialKey {
            switch specialKey {
            case .f1:  recordChar = "f1"
            case .f2:  recordChar = "f2"
            case .f3:  recordChar = "f3"
            case .f4:  recordChar = "f4"
            case .f5:  recordChar = "f5"
            case .f6:  recordChar = "f6"
            case .f7:  recordChar = "f7"
            case .f8:  recordChar = "f8"
            case .f9:  recordChar = "f9"
            case .f10: recordChar = "f10"
            case .f11: recordChar = "f11"
            case .f12: recordChar = "f12"
            default:   iserror = true
            }
        } else if event.keyCode == spaceKeyCode {
            recordChar = "space"
        } else {
            var chars = event.charactersIgnoringModifiers ?? ""
            if chars == "<" { chars = "," }
            else if chars == ">" { chars = "." }
            if chars.isEmpty { iserror = true } else { recordChar = chars }
        }
        
        let errArray = ["c", "v", "z", "f", ",", "h", "q", "n", "z", "a", "x", "\r", "m", "-", "+" ]
        if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.option) && !event.modifierFlags.contains(.control) && !event.modifierFlags.contains(.shift){
            
            if errArray.contains(recordChar.lowercased()){
                iserror = true
            }
        }
        
        if event.modifierFlags.contains(.numericPad){
            switch recordChar {
            case "0":
                recordChar = "keypad0"
            case "1":
                recordChar = "keypad1"
            case "2":
                recordChar = "keypad2"
            case "3":
                recordChar = "keypad3"
            case "4":
                recordChar = "keypad4"
            case "5":
                recordChar = "keypad5"
            case "6":
                recordChar = "keypad6"
            case "7":
                recordChar = "keypad7"
            case "8":
                recordChar = "keypad8"
            case "9":
                recordChar = "keypad9"
            case ".":
                recordChar = "keypaddecimal"
            case "*":
                recordChar = "keypadmultiply"
            case "+":
                recordChar = "keypadplus"
            case "/":
                recordChar = "keypaddivide"
            case "-":
                recordChar = "keypadminus"
            default:
                recordChar = "keypad0"
            }
        }
        if iserror {
            keyboardShortcutsSettingsVcObj?.cancelRecording()
            
            let alertShortcutFailed = NSAlert()
            alertShortcutFailed.setSharingType()
            alertShortcutFailed.alertStyle = .informational
            alertShortcutFailed.messageText =  "Please use a different key combination."
            if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                alertShortcutFailed.messageText = preferencesInfo.value(forKey: "alertShortcutErrorText") as? String ?? alertShortcutFailed.messageText
            }
            alertShortcutFailed.addButton(withTitle: buttonOkText)
            
            alertShortcutFailed.beginSheetModal(for: self.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    
                }

            })
            
            return
        }

        var flagsarr = [Int]()
        if event.modifierFlags.contains(.control) { flagsarr.append(shortcutFlags._CONTROL_.rawValue) }
        if event.modifierFlags.contains(.option)  { flagsarr.append(shortcutFlags._OPTION_.rawValue) }
        if event.modifierFlags.contains(.shift)   { flagsarr.append(shortcutFlags._SHIFT_.rawValue) }
        if event.modifierFlags.contains(.command) { flagsarr.append(shortcutFlags._COMMAND_.rawValue) }

        keyboardShortcutsSettingsVcObj?.shortcutRecorded(char: recordChar, flagInts: flagsarr)
    }

    func shortcutFailed_alert(){
        char = ""
        flags = []

        let alertShortcutFailed = NSAlert()
        alertShortcutFailed.setSharingType()
        alertShortcutFailed.alertStyle = .informational
        alertShortcutFailed.messageText = "Please use a different key combination."
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            alertShortcutFailed.messageText = preferencesInfo.value(forKey: "alertShortcutErrorText") as? String ?? alertShortcutFailed.messageText
        }
        alertShortcutFailed.addButton(withTitle: buttonOkText)
        alertShortcutFailed.beginSheetModal(for: self.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                
            }
            char = ""
            flags = []
            
            if activeShortcutRecorder == .brainDump {
                keyboardShortcutsSettingsVcObj?.boxBrainDumpClicked()
            }else if activeShortcutRecorder == .focusMusic {
                keyboardShortcutsSettingsVcObj?.boxFocusMusicClicked()
            }else if activeShortcutRecorder == .focusSession {
                keyboardShortcutsSettingsVcObj?.boxFocusSessionClicked()
            }else if activeShortcutRecorder == .taskList {
                keyboardShortcutsSettingsVcObj?.boxTaskListClicked()
            }
        })
    }

    
    func windowWillEnterFullScreen(_ notification: Notification) {
        print("windowWillEnterFullScreen****")
        if !checkIsFullScreenEnabled(){
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
                if !state{
                    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
                }
            }
        }
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        print("windowWillExitFullScreen****")
        if !checkIsFullScreenEnabled(){
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
                if !state{
                    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
        
    }
    
    func windowWillMiniaturize(_ notification: Notification) {
        if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            showNudgeFocusAlignmentScoreWindow(score: currentFocusAlignmentScore)
        }
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        // Allowed-activity habits run in the background, so a minimise should just leave the window
        // minimised in the Dock — don't slam it closed (closing here is what fed normal habits into
        // the close→postpone path). The habit keeps running either way.
        if isAllowedActivityHabitCurrentlyRunning { return }
        self.window?.close()
    }
    
    /// Re-centre the routine window for the 60s away-timer (#2091). Marks the move as programmatic so
    /// the resulting windowDidMove isn't read as a user drag, records the centred origin, and flags
    /// that a re-centre has happened this session — so a *subsequent* user drag triggers the postpone
    /// prompt instead of another silent re-centre. Preserves the old center()+activate behaviour.
    func recenterRoutineWindowForAwayTimer() {
        guard let window = self.window, window.isVisible else { return }
        isProgrammaticallyCenteringRoutineWindow = true
        window.center()
        routineWindowCenteredOrigin = window.frame.origin
        hasRecenteredRoutineWindowThisSession = true
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
        // Clear the guard after the move settles so genuine user drags are seen again.
        DispatchQueue.main.async { [weak self] in self?.isProgrammaticallyCenteringRoutineWindow = false }
    }

    func windowDidMove(_ notification: Notification) {
        refreshContentInsets()
        scheduleDragAwayCheck()
    }

    /// Issue #2091: debounce window-move events so a settled user drag — not our own re-centre —
    /// triggers the postpone prompt exactly once, and only after the away-timer already re-centred.
    private func scheduleDragAwayCheck() {
        guard currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ else { return }
        // No full-screen check needed: the away-timer re-centre (which sets hasRecentered) only runs in
        // the non-full-screen path, so this gate already implies we're on the small, draggable window.
        guard hasRecenteredRoutineWindowThisSession, !isProgrammaticallyCenteringRoutineWindow else { return }
        dragAwayCheckWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.presentDragAwayPromptIfStillDrifted() }
        dragAwayCheckWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + dragAwaySettleDelay, execute: work)
    }

    private func presentDragAwayPromptIfStillDrifted() {
        guard currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ else { return }
        guard hasRecenteredRoutineWindowThisSession else { return }
        guard !DragAwayPostponePromptManager.shared.isVisible else { return }
        guard let window = self.window, window.isVisible, let centered = routineWindowCenteredOrigin else { return }

        let drift = hypot(window.frame.origin.x - centered.x, window.frame.origin.y - centered.y)
        guard drift > dragAwayDriftThreshold else { return }

        // Bring the window back to centre and to the front BEFORE showing the prompt: the overlay is
        // hosted on the window's content view, so on the dragged-aside window the user might never see
        // it. Centring here puts the nag where they're looking. #2091
        recenterRoutineWindowForAwayTimer()

        DragAwayPostponePromptManager.shared.present(onPostpone: {
            // Reuse the existing postpone path — same as the on-screen Postpone / abort button.
            getHabitsVcObject().abortCurrentState()
        }, onKeepGoing: {
            // Keep going: the window is already centred+front from the recenter above, so just dismiss
            // (handled by the manager). The flag stays set, so a further drag asks once more.
        })
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_ || currentState == ._CUSTOM_ROUTINE_{
            if checkIsFullScreenEnabled(){
                // Re-enter full screen on ANY exit while a locked habit / micro-break / routine /
                // shut-off is active — not only when the Habits tab happens to be selected. Otherwise
                // navigating to Settings (or another sidebar tab) deselects the Habits box and lets the
                // full-screen lock drop, which is a way to escape the block. The legitimate way out is
                // ending / skipping the activity, which changes currentState so this guard stops firing.
                mainViewControllerObj?.checkIsFullScreenNeeded()
            }
        }
    }
}
