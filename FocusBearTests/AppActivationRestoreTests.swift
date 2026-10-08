//
//  AppActivationRestoreTests.swift
//  FocusBearTests
//
//  Covers what activating the app — ⌘-Tab, the app switcher, a Dock click — does about the main window.
//
//  Regression: ⌘-Tab cannot be detected as a keystroke (the system app switcher consumes it), but the
//  activation it causes reaches `applicationDidBecomeActive`, which logged and did nothing. Switching
//  back to Focus Bear with its window closed therefore showed nothing at all (report
//  2026-09-16_16-01-15, filed from `_POSTPONE_MORNING_HABIT_`).
//
//  These test the DECISION only — no AppKit windows are instantiated.
//

@testable import Focus_Bear
import XCTest

final class AppActivationRestoreTests: XCTestCase {

    /// The reported case: a postponed morning routine, every window closed, nothing else on screen.
    func testPostponedRoutineWithNoWindowRestoresTheMainWindow() {
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_), .showMainWindow)
        XCTAssertEqual(action(state: ._POSTPONE_EVENING_HABIT_), .showMainWindow)
        XCTAssertEqual(action(state: ._POSTPONE_FOCUS_SUMMARY_), .showMainWindow)
    }

    func testIdleAppWithNoWindowRestoresTheMainWindow() {
        XCTAssertEqual(action(state: ._NOTHING_), .showMainWindow)
    }

    /// The login screen IS the main window, so activation has to be able to bring it back.
    func testLoginStateRestoresTheMainWindow() {
        XCTAssertEqual(action(state: ._LOGIN_), .showMainWindow)
    }

    // MARK: - Don't double-show

    func testVisibleMainWindowDoesNothing() {
        XCTAssertEqual(action(state: ._NOTHING_, isMainWindowVisible: true), .doNothing)
    }

    /// The fourth round of report 2026-09-16_16-01-15, and the reason the first three failed: an earlier
    /// version stopped whenever ANY other window was visible, so any second window the app happened to
    /// have up answered a ⌘-Tab with nothing (17 Sep 16:54:51, 16:55:02, 16:55:04, 16:55:09 — all
    /// `other=true`, `main=false`, no window shown). The instruction on the report is
    /// explicit: "if an alert/nudge is showing, it should still open the full window, if menu is open it
    /// shouldn't".
    func testAWindowThatWasAlreadyOpenDoesNotSuppressTheRestore() {
        XCTAssertEqual(action(state: ._POSTPONE_EVENING_HABIT_,
                              didAnotherWindowOpenSinceActivation: false),
                       .showMainWindow)
    }

    /// #2585: but when one of our OWN non-main windows is the one the user is focused on (the quit window,
    /// or any future window), they switched back TO it, not to summon the main window — so don't open the
    /// main window on top of it. Contrast with the test above: a window merely on screen does not suppress;
    /// being the front/key window does. Keyed off "a non-main window is front" rather than naming the quit
    /// window, so a new window that hits this same bug is covered automatically.
    func testUserFocusedOnAnotherFocusBearWindowDoesNothing() {
        XCTAssertEqual(action(state: ._NOTHING_, isAnotherFocusBearWindowFront: true), .doNothing)
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_, isAnotherFocusBearWindowFront: true),
                       .doNothing)
    }

    /// Dismissing a Focus Bear popup while the app is in the background activates the app (clicking a
    /// background window brings its app forward) and closes the popup in the same click. By decision time
    /// the popup is gone, so the front-window check can't catch it — but the activation snapshot recorded a
    /// non-main window that is no longer there, and that must NOT open the main window.
    func testAFocusBearWindowClosingSinceActivationDoesNothing() {
        XCTAssertEqual(action(state: ._NOTHING_, didAnotherWindowCloseSinceActivation: true), .doNothing)
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_, didAnotherWindowCloseSinceActivation: true),
                       .doNothing)
    }

    /// The mirror of the test above and the guard against re-breaking report 2026-09-16: a window that was
    /// up at activation and STAYS up (a nudge on a genuine ⌘-Tab) did not close, so it does not suppress.
    func testAWindowThatStaysOpenAcrossTheSettleStillRestores() {
        XCTAssertEqual(action(state: ._NOTHING_, didAnotherWindowCloseSinceActivation: false), .showMainWindow)
    }

    /// The backstop that replaced it. A self-activation almost always exists in order to SHOW something,
    /// so a window that arrives DURING the settle period means the app pulled itself forward, and the
    /// main window must not land on top of whatever it came to say.
    func testAWindowThatOpenedWithTheActivationDoesNothing() {
        XCTAssertEqual(action(state: ._NOTHING_, didAnotherWindowOpenSinceActivation: true), .doNothing)
    }

    /// Showing the menu-bar menu activates the app, so this fires with the menu on screen. Opening the
    /// main window there would both duplicate the UI and dismiss the transient popover under the user.
    func testOpenMenuDoesNothing() {
        XCTAssertEqual(action(state: ._NOTHING_, isMenuVisible: true), .doNothing)
    }

    /// macOS activates a foreground launch about a second in, long before the app has decided whether the
    /// user is onboarding, logging in or going straight to the main window — and Focus Bear starts at
    /// login, so opening the window there would mean a window on every boot.
    func testLaunchActivationDoesNothing() {
        XCTAssertEqual(action(state: ._NOTHING_, secondsSinceLaunch: 0), .doNothing)
        XCTAssertEqual(action(state: ._NOTHING_,
                              secondsSinceLaunch: AppActivationRestore.launchSettlingSeconds - 0.1),
                       .doNothing)
    }

    /// An app started into the background never gets that launch activation, so its user's first ⌘-Tab
    /// arrives well after the settling window and must still be restored.
    func testActivationAfterTheSettlingWindowRestores() {
        XCTAssertEqual(action(state: ._NOTHING_,
                              secondsSinceLaunch: AppActivationRestore.launchSettlingSeconds),
                       .showMainWindow)
    }

    // MARK: - Only an activation from OUTSIDE the app is a request for the window

    /// Clicking the menu-bar item activates the app, and that activation reaches
    /// `applicationDidBecomeActive` BEFORE `togglePopover` is delivered — proven in the user's own logs,
    /// where `applicationDidBecomeActive` is logged immediately above `togglePopover start`. So at
    /// decision time the popover is opening but not yet open and `isMenuVisible` is still false: the
    /// self-activation marker is the only thing standing between the user and a full window over the menu
    /// they actually asked for.
    func testMenuBarClickDoesNotRestoreEvenBeforeTheMenuIsOpen() {
        XCTAssertEqual(action(state: ._NOTHING_, isSelfActivation: true, isMenuVisible: false),
                       .doNothing)
    }

    /// Late No More announcing a meeting activates the app itself. With a routine already postponed the
    /// handler takes its `else` branch and shows NO window, so "something is already on screen" cannot
    /// catch it — and `_POSTPONE_MORNING_HABIT_` is on the restorable list. Without the marker this is
    /// exactly the case that would drop a window over a meeting.
    func testLateNoMoreSelfActivationDuringPostponedRoutineDoesNotRestore() {
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_, isSelfActivation: true), .doNothing)
    }

    /// The original report, and it must keep working: the same state, the same empty screen, but the
    /// activation came from the user rather than from us.
    func testOrdinaryCommandTabDuringPostponedRoutineStillRestores() {
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_, isSelfActivation: false), .showMainWindow)
    }

    /// A declared self-activation still wins even though nothing opened during the settle period — the
    /// Late No More case shows no window at all, which is why the marker exists in the first place.
    func testSelfActivationWithNoNewWindowStillDoesNothing() {
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_,
                              isSelfActivation: true,
                              didAnotherWindowOpenSinceActivation: false),
                       .doNothing)
    }

    /// The menu is the one thing the user asked to keep suppressing the window, and it does so whatever
    /// else is or is not on screen.
    func testOpenMenuStillDoesNothingWithNothingElseOnScreen() {
        XCTAssertEqual(action(state: ._POSTPONE_EVENING_HABIT_,
                              didAnotherWindowOpenSinceActivation: false,
                              isMenuVisible: true),
                       .doNothing)
    }

    // MARK: - Don't fight a deliberate hide

    /// A routine keeps running with its window closed (an allowed-activity habit backgrounds itself),
    /// a micro break can be dismissed, onboarding drives the window itself. Forcing the borderless
    /// full-screen routine window back mid-meeting would be worse than the reported bug.
    func testStatesThatOwnTheWindowDoNothing() {
        for state in AppActivationRestore.statesThatOwnMainWindow {
            XCTAssertEqual(action(state: state), .doNothing,
                           "\(state) owns the main window; activation must not open one")
        }
    }

    func testEveryRoutineAndBreakStateIsTreatedAsOwningTheWindow() {
        // Guards the list itself: a state added to CURRENTSTATE should be classified deliberately.
        let restorable: Set<CURRENTSTATE> = [._NOTHING_, ._LOGIN_, ._POSTPONE_MORNING_HABIT_,
                                             ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_]
        for state in restorable {
            XCTAssertFalse(AppActivationRestore.statesThatOwnMainWindow.contains(state),
                           "\(state) leaves the main window to the user")
        }
        XCTAssertEqual(AppActivationRestore.statesThatOwnMainWindow.count + restorable.count, 15,
                       "every CURRENTSTATE must be either restorable or owned by the state machine")
    }

    // MARK: - Which window

    /// A postponed routine leaves the controller still configured borderless. Reopening it as-is would
    /// drop the user back into the screen-filling window they escaped, so the title bar goes back first.
    func testBorderlessLeftoverRestoresAsASmallWindow() {
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_, isMainWindowConfiguredBorderless: true),
                       .showMainWindowAsSmallWindow)
        XCTAssertEqual(action(state: ._NOTHING_, isMainWindowConfiguredBorderless: true),
                       .showMainWindowAsSmallWindow)
    }

    /// Belt and braces: a borderless leftover still must not reopen a window in a state that owns one.
    func testBorderlessLeftoverStillDoesNothingWhenTheStateOwnsTheWindow() {
        XCTAssertEqual(action(state: ._MORNING_HABIT_, isMainWindowConfiguredBorderless: true),
                       .doNothing)
    }

    // MARK: - A focus session is not a reason to stay hidden

    /// A session hides no window of its own, and someone switching to Focus Bear mid-session usually
    /// wants the session screen. So the decision does not take a session flag at all — and neither the
    /// session's overlays nor a nudge already on screen changes the answer.
    func testRunningSessionDoesNotSuppressTheRestore() {
        XCTAssertEqual(action(state: ._NOTHING_), .showMainWindow)
        XCTAssertEqual(action(state: ._NOTHING_, didAnotherWindowOpenSinceActivation: false),
                       .showMainWindow,
                       "a window already on screen is not the app answering this activation")
    }

    // MARK: - A window that is "visible" but not on any attached screen

    func testWindowFullyOnAScreenCountsAsOnScreen() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        XCTAssertTrue(AppActivationRestore.isOnVisibleScreen(
            windowFrame: NSRect(x: 100, y: 100, width: 800, height: 600), screenFrames: [screen]))
    }

    func testWindowLeftOnAnUnpluggedMonitorIsNotOnScreen() {
        // The whole third round of report 2026-09-16_16-01-15: `isVisible` stays true for a window on
        // a display that is no longer there, so the restore read "you already have a window".
        let remainingScreen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let onTheOldSecondMonitor = NSRect(x: 2200, y: 300, width: 800, height: 600)
        XCTAssertFalse(AppActivationRestore.isOnVisibleScreen(
            windowFrame: onTheOldSecondMonitor, screenFrames: [remainingScreen]))
    }

    func testWindowStillCountsWhenItSpansTwoScreens() {
        let left = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let right = NSRect(x: 1920, y: 0, width: 1920, height: 1080)
        let straddling = NSRect(x: 1600, y: 200, width: 800, height: 600)
        XCTAssertTrue(AppActivationRestore.isOnVisibleScreen(windowFrame: straddling,
                                                            screenFrames: [left, right]))
    }

    func testWindowPeekingOnlyAtItsEdgeIsNotOnScreen() {
        // A sliver is not a usable window, and treating it as one shows the user nothing.
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let mostlyPastTheEdge = NSRect(x: 1880, y: 200, width: 800, height: 600)
        XCTAssertFalse(AppActivationRestore.isOnVisibleScreen(windowFrame: mostlyPastTheEdge,
                                                             screenFrames: [screen]))
    }

    func testNoScreensAtAllMeansNothingIsOnScreen() {
        XCTAssertFalse(AppActivationRestore.isOnVisibleScreen(
            windowFrame: NSRect(x: 0, y: 0, width: 800, height: 600), screenFrames: []))
    }

    func testAZeroSizedWindowIsNotOnScreen() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        XCTAssertFalse(AppActivationRestore.isOnVisibleScreen(windowFrame: .zero, screenFrames: [screen]))
    }

    func testAStrandedMainWindowStillRestores() {
        // `isMainWindowVisible` is what the caller passes AFTER discounting a stranded window, so the
        // decision itself only has to agree that "no visible window" means restore.
        XCTAssertEqual(action(state: ._POSTPONE_MORNING_HABIT_, isMainWindowVisible: false),
                       .showMainWindow)
    }

    func testUserActivationRestoresAllowedAppHabitWindow() {
        for state: CURRENTSTATE in [._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_] {
            XCTAssertEqual(action(state: state, isAllowedActivityHabit: true), .showMainWindow)
            XCTAssertEqual(action(state: state), .doNothing)
        }
    }

    func testAllowedHabitStillSuppressesMenuAndSelfActivation() {
        XCTAssertEqual(action(state: ._MORNING_HABIT_, isSelfActivation: true,
                              isAllowedActivityHabit: true), .doNothing)
        XCTAssertEqual(action(state: ._MORNING_HABIT_, isMenuVisible: true,
                              isAllowedActivityHabit: true), .doNothing)
        XCTAssertEqual(action(state: ._MORNING_HABIT_, didAnotherWindowOpenSinceActivation: true,
                              isAllowedActivityHabit: true), .doNothing)
    }

    // MARK: - Helper

    private func action(state: CURRENTSTATE,
                        secondsSinceLaunch: TimeInterval = 60,
                        isSelfActivation: Bool = false,
                        isMainWindowVisible: Bool = false,
                        didAnotherWindowOpenSinceActivation: Bool = false,
                        didAnotherWindowCloseSinceActivation: Bool = false,
                        isMenuVisible: Bool = false,
                        isAnotherFocusBearWindowFront: Bool = false,
                        isMainWindowConfiguredBorderless: Bool = false,
                        isAllowedActivityHabit: Bool = false) -> AppActivationRestore.Action {
        AppActivationRestore.action(secondsSinceLaunch: secondsSinceLaunch,
                                    isSelfActivation: isSelfActivation,
                                    isMainWindowVisible: isMainWindowVisible,
                                    didAnotherWindowOpenSinceActivation: didAnotherWindowOpenSinceActivation,
                                    didAnotherWindowCloseSinceActivation: didAnotherWindowCloseSinceActivation,
                                    isMenuVisible: isMenuVisible,
                                    isAnotherFocusBearWindowFront: isAnotherFocusBearWindowFront,
                                    state: state,
                                    isMainWindowConfiguredBorderless: isMainWindowConfiguredBorderless,
                                    isAllowedActivityHabit: isAllowedActivityHabit)
    }
}
