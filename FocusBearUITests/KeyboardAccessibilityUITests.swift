//
//  KeyboardAccessibilityUITests.swift
//  Focus BearUITests
//
//  Everything a mouse user can do, from the keyboard: every control reachable with Tab and
//  Shift-Tab, no focus traps, Return/Space activate, Escape dismisses, and the main flows finished
//  without touching the mouse. Tab reaches buttons only with Full Keyboard Access ("Keyboard
//  navigation" in System Settings), which AppKit reads from the global domain alone, so it can't be
//  switched on for the test app by itself; the Tab tests skip, saying so, when it is off.
//

import XCTest

final class KeyboardAccessibilityUITests: FocusBearUITestCase {
    private typealias ToDo = UITestContract.Identifier.ToDo
    private typealias FocusStart = UITestContract.Identifier.FocusStart
    private typealias FocusSession = UITestContract.Identifier.FocusSession
    private typealias Menu = UITestContract.Identifier.Menu

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = true   // list every unreachable control, not just the first
    }

    private func requireFullKeyboardAccess() throws {
        guard isFullKeyboardAccessOn else {
            throw XCTSkip("Keyboard navigation is off in System Settings → Keyboard, so Tab can't reach buttons. Turn it on for this runner (docs/ui-tests.md).")
        }
    }

    // MARK: - Reachability

    func testOnboardingIsKeyboardReachable() throws {
        try requireFullKeyboardAccess()
        app.launchArguments = [UITestContract.LaunchArgument.uiTest,
                                         UITestContract.LaunchArgument.reset,
                                         UITestContract.LaunchArgument.freshInstall]
        launchIsolated()
        expectOnboardingStep(OnboardingStep.welcome, timeout: Self.firstLaunchTimeout)
        try checkKeyboardReachability(on: AccessibilityScreen(name: "Onboarding welcome"))
        // Return presses the focused "continue" button.
        let next = element(UITestContract.Identifier.Onboarding.welcomeContinueButton)
        guard tab(to: next) else {
            throw KeyboardUnreachable(screen: "Onboarding welcome", what: "can't reach with Tab: the continue button")
        }
        press(.return, on: next)
        expectOnboardingStep(OnboardingStep.welcomeAdhd)
    }

    func testSignUpFormIsKeyboardReachable() throws {
        try requireFullKeyboardAccess()
        launchLoggedOut()
        let signUp = element(UITestContract.Identifier.Login.signUpWithEmailButton)
        XCTAssertTrue(appears(signUp, within: Self.firstLaunchTimeout, waitsOnNetwork: true))
        try checkKeyboardReachability(on: .signInForm("Sign-in choices"))
        tap(signUp)
        XCTAssertTrue(appears(element(UITestContract.Identifier.Login.createAccountButton)))
        try checkKeyboardReachability(on: .signInForm("Sign-up form"))
    }

    // One test per screen: once Tab walks a whole page (#2663), a page is a minute of key presses.

    func testDayPlanIsKeyboardReachable() throws {
        try openForKeyboard(Menu.dayPlan, landmark: element(UITestContract.Identifier.DayPlan.view))
        try checkKeyboardReachability(on: AccessibilityScreen(name: "Day Plan"))
    }

    func testToDoListIsKeyboardReachable() throws {
        try openForKeyboard(Menu.todo, landmark: element(ToDo.newTaskButton))
        try checkKeyboardReachability(on: AccessibilityScreen(name: "To-do list"))
    }

    func testFocusStartIsKeyboardReachable() throws {
        try requireFullKeyboardAccess()
        try launchSignedIn()
        let shown = open(menuItem: Menu.focusSession, expectingAnyOf: element(FocusStart.startButton), element(FocusSession.endButton))
        guard shown?.identifier == FocusStart.startButton else {
            throw XCTSkip("A focus session is already running for the test account.")
        }
        try checkKeyboardReachability(on: AccessibilityScreen(name: "Focus start"))
    }

    /// The duration slider is one adjustable control: → adds time, ← takes it away (#2663).
    func testFocusStartDurationSliderStepsWithArrowKeys() throws {
        try requireFullKeyboardAccess()
        try launchSignedIn()
        let shown = open(menuItem: Menu.focusSession, expectingAnyOf: element(FocusStart.startButton), element(FocusSession.endButton))
        guard shown?.identifier == FocusStart.startButton else {
            throw XCTSkip("A focus session is already running for the test account.")
        }
        showFocusStartDurationCard()
        // The page's one slider. It has no id of its own: set on the dial, an id lands on its + button.
        let slider = element(UITestContract.Identifier.Screen.shown(byMenuItem: Menu.focusSession)).sliders.firstMatch
        guard appears(slider), tab(to: slider) else {
            throw KeyboardUnreachable(screen: "Focus start", what: "can't reach with Tab: the duration slider")
        }
        let before = sessionMinutes()
        press(.rightArrow, on: slider)
        XCTAssertGreaterThan(sessionMinutes(), before, "[Focus start] → on the duration slider didn't add time")
        press(.leftArrow, on: slider)
        XCTAssertEqual(sessionMinutes(), before, "[Focus start] ← on the duration slider didn't take the time back off")
    }

    private func sessionMinutes() -> Int {
        let hours = Int(element(FocusStart.durationHours).value as? String ?? "") ?? 0
        let minutes = Int(element(FocusStart.durationMinutes).value as? String ?? "") ?? 0
        return hours * Self.minutesPerHour + minutes
    }

    private static let minutesPerHour = 60

    func testSettingsIsKeyboardReachable() throws {
        try openForKeyboard(Menu.settings, landmark: element(UITestContract.Identifier.Settings.appearanceTab))
        try checkKeyboardReachability(on: AccessibilityScreen(name: "Settings"))
    }

    private func openForKeyboard(_ menuItem: String, landmark: XCUIElement) throws {
        try requireFullKeyboardAccess()
        try launchSignedIn()
        open(menuItem: menuItem, expectingAnyOf: landmark)
    }

    // MARK: - Screens shown on demand

    func testMicroBreakScreensAreKeyboardReachable() throws {
        try requireFullKeyboardAccess()
        let start = try present(.microBreak, landmark: UITestContract.Identifier.Breaks.warningStartButton)
        let warning = window(containing: UITestContract.Identifier.Breaks.warningStartButton)
        try checkKeyboardReachability(on: .breakWarning, in: warning)
        checkPostponeMinutesIsNamed(in: warning, on: .breakWarning)
        tap(start)
        let breakStart = element(UITestContract.Identifier.Breaks.startScreenStartButton)
        guard appears(breakStart) else {
            throw XCTSkip("The test account has no break activities, so the break start screen never opens.")
        }
        try checkKeyboardReachability(on: .breakStart)
    }

    func testMidMeetingBreakPopupIsKeyboardReachable() throws {
        try requireFullKeyboardAccess()
        try present(.meetingBreak, landmark: UITestContract.Identifier.Breaks.warningStartButton)
        let popup = window(containing: UITestContract.Identifier.Breaks.warningStartButton)
        try checkKeyboardReachability(on: .meetingBreak, in: popup)
        checkPostponeMinutesIsNamed(in: popup, on: .meetingBreak)
    }

    /// The break reminder's minutes pop-up, reached with Tab, says what it is (English run).
    private func checkPostponeMinutesIsNamed(in window: XCUIElement, on screen: AccessibilityScreen) {
        let minutes = window.popUpButtons.firstMatch
        let name = minutes.exists ? minutes.label : "(missing)"
        guard name != Self.postponeMinutesName else { return }
        report(["the minutes pop-up is announced “\(name)”, not “\(Self.postponeMinutesName)”"],
               on: screen.name)
    }

    private static let postponeMinutesName = "Select minutes to postpone:"

    /// Email → … → Go back → the sidebar, and back again with Shift-Tab — with macOS's AutoFill list
    /// closed, then open (typing in the email field opens it when there are saved addresses).
    func testSignUpFormTabOrder() throws {
        try requireFullKeyboardAccess()
        launchLoggedOut()
        let signUp = element(UITestContract.Identifier.Login.signUpWithEmailButton)
        XCTAssertTrue(appears(signUp, within: Self.firstLaunchTimeout, waitsOnNetwork: true))
        tap(signUp)
        let email = app.textFields[UITestContract.Identifier.Login.emailField]
        XCTAssertTrue(appears(email))
        for opensAutoFill in [false, true] {
            tap(email)
            if opensAutoFill { typeIntoFocus(Self.autoFillPrefix) }
            let context = opensAutoFill ? "with AutoFill open" : "with AutoFill closed"
            let goBack = app.buttons.matching(showing(Self.goBackName)).firstMatch
            guard tab(to: goBack) else {
                report(["Tab from Email doesn't reach Go back (\(context))"], on: "Sign-up form")
                continue
            }
            press(.tab)
            let isInSidebar = focusedElement().map { $0.frame.midX < mainWindow.frame.minX + Self.sidebarWidth } ?? false
            if !isInSidebar {
                report(["Tab after Go back doesn't go to the sidebar (\(context))"], on: "Sign-up form")
            }
            press(.tab, modifiers: .shift)
            if !hasKeyboardFocus(goBack) {
                report(["Shift-Tab from the sidebar doesn't come back to Go back (\(context))"], on: "Sign-up form")
            }
            if opensAutoFill {   // leave the field as it was: close the list, select all, delete
                press(.escape)
                press("a", modifiers: .command)
                press(.delete)
            }
        }
    }

    private static let goBackName = "Go back"
    private static let autoFillPrefix = "a"
    /// Everything left of this, measured from the window's edge, is the sidebar.
    private static let sidebarWidth: CGFloat = 260

    func testDayPlanTaskNameTabGoesToDuration() throws {
        try requireFullKeyboardAccess()
        try checkDayPlanTaskNameTabGoesToDuration()
    }

    /// Return should complete a habit that has no timer (#688: it did nothing).
    func testNonTimerActivityIsKeyboardOperable() throws {
        try requireFullKeyboardAccess()
        let done = try present(.nonTimerActivity, landmark: UITestContract.Identifier.Routine.doneButton)
        try checkKeyboardReachability(on: .nonTimerActivity)
        press(.return)
        if !waitForNonExistence(of: done) {
            report(["Return doesn't complete the activity (focus: \(focusedElementDescription() ?? "nothing"))"],
                   on: AccessibilityScreen.nonTimerActivity.name)
        }
    }

    // MARK: - Escape dismisses

    func testEscapeClosesSheetsAndMenus() throws {
        try launchSignedIn()
        open(menuItem: Menu.todo, expectingAnyOf: element(ToDo.newTaskButton))
        tap(element(ToDo.newTaskButton))
        let title = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(title))
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: title), "[To-do editor] Escape doesn't close the sheet")

        chooseMenuItem(at: 0, openedBy: element(ToDo.toolsMenu))
        let close = element(ToDo.reschedulePlanCloseButton)
        if appears(close), waitForEnabled(close, timeout: Self.apiRoundTripTimeout) {
            press(.escape)
            XCTAssertTrue(waitForNonExistence(of: close), "[Reschedule plan] Escape doesn't close the sheet")
        }

        guard open(menuItem: Menu.settings, expectingAnyOf: element(UITestContract.Identifier.Settings.appearanceTab)) != nil else { return }
        tap(element(UITestContract.Identifier.Settings.appearanceTab))
        let popup = app.popUpButtons[UITestContract.Identifier.Settings.darkModePopup]
        XCTAssertTrue(appears(popup))
        tap(popup)
        let menuItem = popup.menuItems.firstMatch
        XCTAssertTrue(appears(menuItem))
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: menuItem), "[Settings: appearance] Escape doesn't close the pop-up menu")

    }

    func testEscapeClosesTheMenuBarPopover() throws {
        let popoverButton = try present(.menuBarPopover, landmark: UITestContract.Identifier.MenuBar.quitButton)
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: popoverButton), "[Menu-bar popover] Escape doesn't close the popover")
    }

    // MARK: - No mouse at all

    /// Sidebar → To-do → New task → type → Return, with the keyboard only.
    func testAddAToDoWithoutTheMouse() throws {
        try requireFullKeyboardAccess()
        try launchSignedIn()
        try goWithKeyboard(to: Menu.todo, landmark: element(ToDo.newTaskButton))
        press("n", modifiers: .command)
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "[To-do] ⌘N doesn't open the new-task editor")
        let title = uniqueTitle("UI test keyboard to-do")
        typeIntoFocus(title)
        press(.return)
        let row = app.descendants(matching: .any).matching(identifier: ToDo.taskRow)
            .containing(showing(title)).firstMatch
        XCTAssertTrue(toDoRowAppears(row), "[To-do] Return didn't save the new task")
        deleteToDo(row, titled: title)   // clean-up only, with the mouse, not part of the flow under test
    }

    /// Sidebar → Focus → Start (Space) → End → confirm (Return), with the keyboard only.
    func testStartAndEndAFocusSessionWithoutTheMouse() throws {
        try requireFullKeyboardAccess()
        try launchSignedIn()
        try goWithKeyboard(to: Menu.focusSession, landmark: element(FocusStart.startButton))
        let start = element(FocusStart.startButton)
        guard tab(to: start) else {
            throw KeyboardUnreachable(screen: "Focus start", what: "can't reach with Tab: Start")
        }
        press(.space, on: start)
        declineBlockingOfferIfShown(usingKeyboard: true)
        let end = element(FocusSession.endButton)
        XCTAssertTrue(appears(end), "[Focus start] Space on Start didn't start a session")
        guard tab(to: end) else {
            throw KeyboardUnreachable(screen: "Focus session", what: "can't reach with Tab: End")
        }
        press(.space, on: end)
        let confirm = element(FocusSession.endConfirmButton)
        if appears(confirm) {
            XCTAssertTrue(tab(to: confirm), "[End-session confirmation] can't Tab to End")
            press(.space, on: confirm)
        }
        XCTAssertTrue(waitForNonExistence(of: end), "[Focus session] the session didn't end from the keyboard")
    }

    /// Day Plan → routine "…" menu → Edit timing → Escape, with the keyboard only.
    func testOpenAndCancelADayPlanEditorWithoutTheMouse() throws {
        try requireFullKeyboardAccess()
        typealias Editors = UITestContract.Identifier.DayPlanEditors
        try launchSignedIn(environment: [UITestContract.Environment.presentScreen: UITestContract.PresentedScreen.dayPlanRoutine.rawValue])
        try goWithKeyboard(to: Menu.dayPlan, landmark: element(UITestContract.Identifier.DayPlan.view))
        let menu = element(Editors.routineMenuButton)
        guard appears(menu) else {
            throw XCTSkip("Today's Day Plan shows no routine for the test account.")
        }
        guard tab(to: menu) else {
            throw KeyboardUnreachable(screen: "Day Plan", what: "can't reach with Tab: the routine's “…” menu")
        }
        press(.space, on: menu)
        press(.downArrow)
        press(.return)
        let cancel = element(Editors.routineTimingCancelButton)
        XCTAssertTrue(appears(cancel), "[Day Plan] the routine menu didn't open its timing editor from the keyboard")
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: cancel), "[Routine timing sheet] Escape doesn't close it")
    }

    // MARK: - Steps

    /// Reaches a sidebar item with Tab and opens it with Space.
    private func goWithKeyboard(to menuItem: String, landmark: XCUIElement) throws {
        let item = app.buttons[menuItem]
        if !item.exists { try expandToolsWithKeyboard() }
        XCTAssertTrue(appears(item))
        guard tab(to: item) else {
            throw KeyboardUnreachable(screen: "Sidebar", what: "can't reach with Tab: \(menuItem)")
        }
        press(.space, on: item)
        XCTAssertTrue(appears(landmark), "[Sidebar] Space on \(menuItem) didn't open it")
    }

    /// TOOLS starts collapsed; its header is a button like the rest of the sidebar.
    private func expandToolsWithKeyboard() throws {
        let section = app.buttons[UITestContract.Identifier.Tools.section]
        guard tab(to: section) else {
            throw KeyboardUnreachable(screen: "Sidebar", what: "can't reach with Tab: TOOLS")
        }
        press(.space, on: section)
    }
}

/// Tab with Full Keyboard Access OFF, the macOS default most people have. #2663 drives Tab itself in
/// the main window, so this checks that ordinary behaviour survived: Tab moves between text fields
/// only, and the fields that give Tab a meaning of their own still do.
final class KeyboardDefaultsUITests: FocusBearUITestCase {
    private typealias Login = UITestContract.Identifier.Login
    private typealias ToDo = UITestContract.Identifier.ToDo

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard !isFullKeyboardAccessOn else {
            throw XCTSkip("Full Keyboard Access is on; these check the default, off.")
        }
    }

    func testSignInFormTabGoesFromEmailToPassword() throws {
        launchLoggedOut()
        let goToSignIn = app.buttons[Login.goToSignInButton]
        XCTAssertTrue(appears(goToSignIn, within: Self.firstLaunchTimeout, waitsOnNetwork: true))
        tap(goToSignIn)
        checkTabGoesFromEmailToPassword(on: "Sign-in form")
    }

    func testSignUpFormTabGoesFromEmailToPassword() throws {
        launchLoggedOut()
        let signUp = element(Login.signUpWithEmailButton)
        XCTAssertTrue(appears(signUp, within: Self.firstLaunchTimeout, waitsOnNetwork: true))
        tap(signUp)
        checkTabGoesFromEmailToPassword(on: "Sign-up form")
    }

    func testDayPlanTaskNameTabGoesToDuration() throws {
        try checkDayPlanTaskNameTabGoesToDuration()
    }

    /// Tab in the new-task title moves on to the next field; it neither saves nor closes the editor.
    func testToDoEditorTitleTabMovesOn() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.todo, expectingAnyOf: element(ToDo.newTaskButton))
        tap(element(ToDo.newTaskButton))
        let title = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(title), "the new-task editor didn't open")
        tap(title)
        typeIntoFocus(uniqueTitle("UI test tab"))
        press(.tab)
        XCTAssertTrue(title.exists, "[To-do editor] Tab in the title closed the editor")
        XCTAssertFalse(hasKeyboardFocus(title), "[To-do editor] Tab left focus in the title")
        press(.escape)
    }

    private func checkTabGoesFromEmailToPassword(on screen: String) {
        let email = app.textFields[Login.emailField]
        XCTAssertTrue(appears(email), "[\(screen)] no email field")
        tap(email)
        press(.tab)
        XCTAssertTrue(hasKeyboardFocus(app.secureTextFields[Login.passwordField]),
                      "[\(screen)] Tab from Email went to \(focusedElementDescription() ?? "nothing"), not Password")
    }
}

extension FocusBearUITestCase {
    private static let keyboardUIModeKey = "AppleKeyboardUIMode"
    /// The Full Keyboard Access bit of `AppleKeyboardUIMode`.
    private static let fullKeyboardAccessBit = 2

    /// AppKit reads it from the global domain only, so it can't be set for the test app alone.
    var isFullKeyboardAccessOn: Bool {
        UserDefaults.standard.integer(forKey: Self.keyboardUIModeKey) & Self.fullKeyboardAccessBit != 0
    }

    /// Tab in a Day Plan task's name moves to its duration (or takes a highlighted #project
    /// suggestion — none shows for a plain name). With and without Full Keyboard Access.
    func checkDayPlanTaskNameTabGoesToDuration() throws {
        typealias DayPlan = UITestContract.Identifier.DayPlan
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.dayPlan, expectingAnyOf: element(DayPlan.view))
        tap(element(DayPlan.addTaskButton))
        let title = uniqueTitle("UI test tab task")
        typeIntoFocus(title)
        press(.tab)
        let focused = focusedElement()?.identifier ?? ""
        XCTAssertTrue(focused.hasPrefix(DayPlan.taskDurationPrefix),
                      "[Day Plan] Tab in a task name went to \(focusedElementDescription() ?? "nothing"), not its duration")
        let name = app.textFields.matching(NSPredicate(format: "value == %@", title)).firstMatch
        XCTAssertTrue(name.exists, "[Day Plan] the task name wasn't kept")
        completeDayPlanTask(named: name)
    }

    /// Ticks a task this test added, so it leaves the Day Plan: open tasks left by earlier runs pile up
    /// on the account and every later Day Plan screen and audit sees them.
    func completeDayPlanTask(named nameField: XCUIElement) {
        typealias DayPlan = UITestContract.Identifier.DayPlan
        guard nameField.exists else { return }
        let taskID = String(nameField.identifier.dropFirst(DayPlan.taskNamePrefix.count))
        let done = app.checkBoxes[taskID]
        guard appears(done) else { return }
        tap(done)
        _ = waitForNonExistence(of: nameField)
    }
}

/// A control a keyboard-only flow can't reach with Tab: the flow can't go on, so the test stops
/// here, failed, naming the screen and the control.
struct KeyboardUnreachable: Error, CustomStringConvertible {
    let screen: String
    let what: String
    var description: String { "[\(screen)] \(what)" }
}
