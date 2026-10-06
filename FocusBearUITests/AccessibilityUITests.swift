//
//  AccessibilityUITests.swift
//  Focus BearUITests
//
//  VoiceOver: every screen the suite reaches gets Apple's accessibility audit plus the checks in
//  AccessibilityChecks.swift. Keyboard: see KeyboardAccessibilityUITests.
//

import XCTest

/// Tickets already being fixed on other branches. Their findings are expected failures here.
enum AccessibilityTicket {
    static let swiftUIMenusAndWebHabits = "Mac-App#2676"
    /// Text colours are waiting on a design decision: the contrast fixes (#2714, #2673) were reverted
    /// because black on orange looked wrong, so the audit's contrast findings stand until it's made.
    static let textColourDecision = "Mac-App#2707"
}

extension KnownAccessibilityIssue {
    /// Every screen's contrast findings, until `AccessibilityTicket.textColourDecision` is decided.
    static let textContrastAwaitingDesign = KnownAccessibilityIssue(
        ticket: AccessibilityTicket.textColourDecision,
        appliesTo: AccessibilityAuditName.finding(AccessibilityAuditName.contrast),
        reason: "text colours await a design decision")
    /// Known on every screen, not just the ones a test names.
    static let everyScreen = [textContrastAwaitingDesign]

    /// The SwiftUI editor sheets (to-do, habit, routine timing): the audit finds a parent/child
    /// mismatch in the hosting view's tree but gives no element for it, so it can't be pinned to a
    /// control. Scoped to these screens, so the same finding anywhere else still fails.
    static let swiftUISheetParentChild = KnownAccessibilityIssue(
        ticket: AccessibilityTicket.swiftUIMenusAndWebHabits,
        appliesTo: AccessibilityAuditName.elementlessFinding(AccessibilityAuditName.parentChild))
}

extension AccessibilityScreen {
    static let breakWarning = AccessibilityScreen(name: "Micro-break warning")
    static let breakStart = AccessibilityScreen(name: "Break start (intention and brain dump)")
    static let meetingBreak = AccessibilityScreen(name: "Mid-meeting break popup")
    static let nonTimerActivity = AccessibilityScreen(name: "Non-timer routine activity")

    static func onboarding(_ step: String) -> AccessibilityScreen {
        AccessibilityScreen(name: "Onboarding \(step)")
    }

    static func signInForm(_ name: String) -> AccessibilityScreen {
        AccessibilityScreen(name: name)
    }
}

final class AccessibilityVoiceOverUITests: FocusBearUITestCase {
    private typealias Onboarding = UITestContract.Identifier.Onboarding

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = true   // list every finding on a screen, not just the first
    }

    func testOnboardingScreens() throws {
        app.launchArguments = [UITestContract.LaunchArgument.uiTest,
                                         UITestContract.LaunchArgument.reset,
                                         UITestContract.LaunchArgument.freshInstall]
        launchIsolated()
        // Each step, and the button that leads to the next one.
        let steps: [(step: String, continueButton: String?)] = [
            (OnboardingStep.welcome, Onboarding.welcomeContinueButton),
            (OnboardingStep.welcomeAdhd, Onboarding.welcomeAdhdContinueButton),
            (OnboardingStep.letsDoIt, Onboarding.letsDoItButton),
            (OnboardingStep.setUpAccount, Onboarding.signUpButton),
            (OnboardingStep.privacy, nil),
        ]
        expectOnboardingStep(OnboardingStep.welcome, timeout: Self.firstLaunchTimeout)
        for (index, current) in steps.enumerated() {
            try checkVoiceOver(on: .onboarding(current.step))
            guard let button = current.continueButton else { break }
            advanceOnboarding(with: button, to: steps[index + 1].step)
        }
    }

    func testSignInForm() throws {
        launchLoggedOut()
        let goToSignIn = app.buttons[UITestContract.Identifier.Login.goToSignInButton]
        XCTAssertTrue(appears(goToSignIn, within: Self.firstLaunchTimeout, waitsOnNetwork: true), "no sign-in offer")
        try checkVoiceOver(on: .signInForm("Sign-in choices"))
        tap(goToSignIn)
        XCTAssertTrue(appears(app.textFields[UITestContract.Identifier.Login.emailField]))
        try checkVoiceOver(on: .signInForm("Sign-in form"))
    }

    func testSignUpForm() throws {
        launchLoggedOut()
        let signUp = element(UITestContract.Identifier.Login.signUpWithEmailButton)
        XCTAssertTrue(appears(signUp, within: Self.firstLaunchTimeout, waitsOnNetwork: true), "no sign-up offer")
        tap(signUp)
        XCTAssertTrue(appears(element(UITestContract.Identifier.Login.createAccountButton)))
        try checkVoiceOver(on: .signInForm("Sign-up form"))
    }

    /// The names #2664 gives these controls (English run). Expected failures until it merges.
    func testOnboardingAndSignInControlsHaveDescriptiveNames() throws {
        typealias Login = UITestContract.Identifier.Login
        app.launchArguments = [UITestContract.LaunchArgument.uiTest,
                                         UITestContract.LaunchArgument.reset,
                                         UITestContract.LaunchArgument.freshInstall]
        launchIsolated()
        expectOnboardingStep(OnboardingStep.welcome, timeout: Self.firstLaunchTimeout)
        advanceOnboarding(with: Onboarding.welcomeContinueButton, to: OnboardingStep.welcomeAdhd)
        expectName(of: element(Onboarding.backButton), toBe: ExpectedName.back)

        app.terminate()
        launchLoggedOut()
        let goToSignIn = app.buttons[Login.goToSignInButton]
        XCTAssertTrue(appears(goToSignIn, within: Self.firstLaunchTimeout, waitsOnNetwork: true))
        tap(goToSignIn)
        XCTAssertTrue(appears(app.textFields[Login.emailField]))
        expectName(of: app.textFields[Login.emailField], toBe: ExpectedName.email)
        expectName(of: app.secureTextFields[Login.passwordField], toBe: ExpectedName.password)
    }

    private enum ExpectedName {
        static let back = "Go back"
        static let email = "Email Address"
        static let password = "Password"
    }

    private func expectName(of element: XCUIElement, toBe expected: String) {
        let actual = element.exists ? element.label : "(missing)"
        XCTAssertEqual(actual, expected, "\(element.identifier) is announced “\(actual)”, not “\(expected)”")
    }

    func testDayPlan() throws {
        try openDayPlanWithSeededRoutine()
        try checkVoiceOver(on: AccessibilityScreen(name: "Day Plan"))
    }

    func testDayPlanEditors() throws {
        typealias Editors = UITestContract.Identifier.DayPlanEditors
        try openDayPlanWithSeededRoutine()
        var checked = 0
        let menu = element(Editors.routineMenuButton)
        if appears(menu) {
            chooseMenuItem(at: 0, openedBy: menu)
            let cancel = element(Editors.routineTimingCancelButton)
            if appears(cancel) {
                try checkVoiceOver(on: AccessibilityScreen(name: "Routine timing sheet"))
                tap(cancel)
                checked += 1
            }
        }
        if let edit = revealHabitEditButton() {
            tap(edit)
            let cancel = element(Editors.habitEditorCancelButton)
            if appears(cancel) {
                try checkVoiceOver(on: AccessibilityScreen(name: "Habit editor",
                                                           voiceOverKnownIssues: [KnownAccessibilityIssue.swiftUISheetParentChild]))
                tap(cancel)
                checked += 1
            }
        }
        if checked == 0 { throw XCTSkip("Today's Day Plan offers no routine or habit editor for the test account.") }
    }

    /// Two of the app's 5-second background ticks, so the first one after the settings load — the
    /// one that seeds the routine and brings the main window up on the Day Plan — falls inside it.
    private static let seededRoutineTimeout: TimeInterval = 10

    /// Signed in, on the Day Plan, with the seeded evening routine (`PresentedScreen.dayPlanRoutine`).
    ///
    /// The launch can hand over before that first tick: on 2026-09-27 a focus session still running
    /// on the account put the window up early. Clicking the Day Plan sidebar row while the tick swaps
    /// the window's content (under a loader) hit-tested a view of the test app's own that was being
    /// torn down — "found AX element pid <the test app> … cannot be mapped". So wait for the tick to
    /// show the seeded routine, and click Day Plan only when it left another screen in front.
    private func openDayPlanWithSeededRoutine() throws {
        try launchSignedIn(environment: [UITestContract.Environment.presentScreen: UITestContract.PresentedScreen.dayPlanRoutine.rawValue])
        let dayPlan = element(UITestContract.Identifier.DayPlan.view)
        let habitName = UITestContract.RoutineFixture.timedHabitName
        // CONTAINS, as `revealHabitEditButton` matches it: the row may read its times with the name.
        let seededHabit = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", habitName, habitName)).firstMatch
        // Waits on the app's timer, not on a screen being slow, so it isn't a performance finding.
        if appears(seededHabit, within: Self.seededRoutineTimeout, waitsOnNetwork: true), dayPlan.exists { return }
        open(menuItem: UITestContract.Identifier.Menu.dayPlan, expectingAnyOf: dayPlan)
    }

    func testFocusSessionScreens() throws {
        typealias FocusStart = UITestContract.Identifier.FocusStart
        typealias FocusSession = UITestContract.Identifier.FocusSession
        try launchSignedIn()
        let shown = open(menuItem: UITestContract.Identifier.Menu.focusSession,
                         expectingAnyOf: element(FocusStart.startButton), element(FocusSession.endButton))
        if shown?.identifier == FocusStart.startButton {
            try checkBothFocusStartModes()
            expectDurationSliderIsSpoken()
            tap(element(FocusStart.startButton))
            declineBlockingOfferIfShown()
        }
        let end = element(FocusSession.endButton)
        XCTAssertTrue(appears(end), "the session didn't start")
        try checkVoiceOver(on: AccessibilityScreen(name: "Focus session running"))
        tap(end)
        let confirm = element(FocusSession.endConfirmButton)
        if appears(confirm) {
            try checkVoiceOver(on: AccessibilityScreen(name: "End-session confirmation"))
            tap(confirm)
        }
    }

    /// Focus Start opens in whichever mode the account last used, so check that one, switch to the
    /// other, and switch back so the next test finds it as this one did. Only advanced has a goal card.
    private func checkBothFocusStartModes() throws {
        typealias FocusStart = UITestContract.Identifier.FocusStart
        let goal = element(FocusStart.goalCard)
        let modeLink = element(FocusStart.modeLink)
        let startsAdvanced = goal.exists
        if startsAdvanced {
            try checkAdvancedFocusStart(goalCard: goal)
            tap(modeLink)
            XCTAssertTrue(waitForNonExistence(of: goal), "the mode link didn't switch Focus Start to simple")
            try checkVoiceOver(on: AccessibilityScreen(name: "Focus start (simple)"))
        } else {
            try checkVoiceOver(on: AccessibilityScreen(name: "Focus start (simple)"))
            tap(modeLink)
            XCTAssertTrue(appears(goal), "the mode link didn't switch Focus Start to advanced")
            try checkAdvancedFocusStart(goalCard: goal)
        }
        tap(modeLink)
        XCTAssertEqual(appears(goal), startsAdvanced, "the mode link didn't switch Focus Start back")
    }

    /// The dial is drawn, so VoiceOver knows it only through what #2663 exposes: a slider, named, whose
    /// value says the length ("25 min").
    private func expectDurationSliderIsSpoken() {
        showFocusStartDurationCard()
        let slider = element(UITestContract.Identifier.Screen.shown(byMenuItem: UITestContract.Identifier.Menu.focusSession))
            .sliders.firstMatch
        XCTAssertTrue(appears(slider), "[Focus start] VoiceOver finds no duration slider")
        guard let node = try? slider.snapshot() else { return }
        XCTAssertFalse(node.label.isEmpty, "[Focus start] the duration slider has no name")
        // AppKit gives a slider's value as a number; either way VoiceOver needs something to read.
        let value = node.value.map { String(describing: $0) } ?? ""
        XCTAssertFalse(value.isEmpty, "[Focus start] the duration slider says no length")
    }

    private func checkAdvancedFocusStart(goalCard: XCUIElement) throws {
        try checkVoiceOver(on: AccessibilityScreen(name: "Focus start (advanced)"))
        tap(goalCard)
        try checkVoiceOver(on: AccessibilityScreen(name: "Focus start (advanced, goal card)"))
    }

    func testToDoScreens() throws {
        typealias ToDo = UITestContract.Identifier.ToDo
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.todo, expectingAnyOf: element(ToDo.newTaskButton))
        try checkVoiceOver(on: AccessibilityScreen(name: "To-do list"))
        tap(element(ToDo.newTaskButton))
        XCTAssertTrue(appears(app.textFields[ToDo.editorTitleField]))
        try checkVoiceOver(on: AccessibilityScreen(name: "To-do editor", voiceOverKnownIssues: [KnownAccessibilityIssue.swiftUISheetParentChild]))
        press(.escape)
    }

    func testHabitsAndRoutine() throws {
        try launchSignedIn()
        try open(tool: UITestContract.Identifier.Tools.editHabits)
        _ = appears(app.webViews.firstMatch)
        try checkVoiceOver(on: AccessibilityScreen(name: "Edit habits (web)", voiceOverKnownIssues: [
            // The web habits page's own order: fixed in web_dashboard#3847, not yet deployed.
            KnownAccessibilityIssue(ticket: AccessibilityTicket.swiftUIMenusAndWebHabits, appliesTo: "reading order goes up"),
        ]))
        let start = firstToAppear([element(UITestContract.Identifier.Routine.startFirstHabitButton),
                                   element(UITestContract.Identifier.Routine.primaryButton)])
        if let start, start.isHittable {
            try checkVoiceOver(on: AccessibilityScreen(name: "Routine"))
        }
    }

    // One test per Settings pane: each is a full audit, and a failure names its pane.

    func testSettingsAppearancePane() throws { try auditSettingsPane(SettingsPane.ui) }

    func testSettingsAccessibilityPane() throws { try auditSettingsPane(SettingsPane.accessibility) }

    func testSettingsAIPane() throws { try auditSettingsPane(SettingsPane.ai) }

    func testSettingsPomodoroPane() throws { try auditSettingsPane(SettingsPane.pomodoro) }

    func testSettingsStrictnessPane() throws { try auditSettingsPane(SettingsPane.strictness) }

    func testSettingsAccountPane() throws { try auditSettingsPane(SettingsPane.account) }

    func testSettingsUninstallPane() throws { try auditSettingsPane(SettingsPane.uninstall) }

    func testSettingsMicroBreaksPane() throws { try auditSettingsPane(SettingsPane.microBreaks) }

    func testSettingsPermissionsPane() throws { try auditSettingsPane(SettingsPane.permissions) }

    func testSettingsToDoListPane() throws { try auditSettingsPane(SettingsPane.toDoList) }

    func testSettingsKeyboardShortcutsPane() throws { try auditSettingsPane(SettingsPane.keyboardShortcuts) }

    func testSettingsOfficeModePane() throws { try auditSettingsPane(SettingsPane.officeMode) }

    private typealias SettingsPane = UITestContract.Identifier.Settings.Pane

    private func auditSettingsPane(_ paneId: String) throws {
        typealias Settings = UITestContract.Identifier.Settings
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.settings, expectingAnyOf: element(Settings.appearanceTab))
        let row = element(Settings.tabPrefix + paneId)
        guard appears(row) else { throw XCTSkip("The test account's Settings have no \(paneId) pane.") }
        tapSettingsTab(paneId)
        XCTAssertTrue(appears(element(Settings.panePrefix + paneId)), "the \(paneId) pane didn't open")
        try checkVoiceOver(on: AccessibilityScreen(name: "Settings: \(paneId)"))
    }

    func testToolScreens() throws {
        typealias Tools = UITestContract.Identifier.Tools
        try launchSignedIn()
        for (tool, name) in [(Tools.stats, "Stats"), (Tools.notes, "Notes"), (Tools.focusMusic, "Focus Music"), (Tools.focusButton, "Focus Button")] {
            do { try open(tool: tool) } catch is XCTSkip { continue }
            try checkVoiceOver(on: AccessibilityScreen(name: name))
        }
        open(menuItem: UITestContract.Identifier.Menu.blocks, expectingAnyOf: element(UITestContract.Identifier.Blocking.blockListsRow))
        try checkVoiceOver(on: AccessibilityScreen(name: "Blocks"))
        open(menuItem: UITestContract.Identifier.Menu.help, expectingAnyOf: element(UITestContract.Identifier.Help.tabView))
        try checkVoiceOver(on: AccessibilityScreen(name: "Help"))
    }

    func testMicroBreakScreens() throws {
        let start = try present(.microBreak, landmark: UITestContract.Identifier.Breaks.warningStartButton)
        try checkVoiceOver(on: .breakWarning, in: window(containing: UITestContract.Identifier.Breaks.warningStartButton))
        tap(start)
        let breakStart = element(UITestContract.Identifier.Breaks.startScreenStartButton)
        guard appears(breakStart) else {
            throw XCTSkip("The test account has no break activities, so the break start screen never opens.")
        }
        try checkVoiceOver(on: .breakStart)
    }

    func testMidMeetingBreakPopup() throws {
        try present(.meetingBreak, landmark: UITestContract.Identifier.Breaks.warningStartButton)
        try checkVoiceOver(on: .meetingBreak, in: window(containing: UITestContract.Identifier.Breaks.warningStartButton))
    }

    func testNonTimerActivity() throws {
        try present(.nonTimerActivity, landmark: UITestContract.Identifier.Routine.doneButton)
        try checkVoiceOver(on: .nonTimerActivity)
    }

    func testMenuBarPopover() throws {
        try present(.menuBarPopover, landmark: UITestContract.Identifier.MenuBar.quitButton)
        try checkVoiceOver(on: AccessibilityScreen(name: "Menu-bar popover"),
                           in: window(containing: UITestContract.Identifier.MenuBar.quitButton))
        press(.escape)
    }
}

extension FocusBearUITestCase {
    /// Signed in, with a screen the app normally shows only when the clock or a meeting says so.
    @discardableResult
    func present(_ screen: UITestContract.PresentedScreen, landmark: String,
                 environment: [String: String] = [:]) throws -> XCUIElement {
        try launchSignedIn(environment: environment.merging([UITestContract.Environment.presentScreen: screen.rawValue]) { $1 })
        let shown = element(landmark)
        // The hook presents the screen once sign-in and the account's settings have loaded, on the
        // app's 5-second tick — a popover waits a tick more for the app to become active.
        XCTAssertTrue(appears(shown, within: Self.firstLaunchTimeout, waitsOnNetwork: true), "\(screen.rawValue) wasn't presented")
        return shown
    }

    func window(containing identifier: String) -> XCUIElement {
        app.windows.containing(.any, identifier: identifier).firstMatch
    }
}
