//
//  UITestSupport.swift
//  Focus BearUITests
//
//  Shared launch and navigation for the suite. See docs/ui-tests.md for how to run it and why the
//  app under test carries its own bundle id.
//

import AppKit
import XCTest

class FocusBearUITestCase: XCTestCase {
    /// A control on a screen that is already loaded, or a screen swap. Anything slower than
    /// `slowScreenThreshold` is also reported as a performance finding.
    static let screenTimeout: TimeInterval = 2
    static let slowScreenThreshold: TimeInterval = 1
    // Waits on the network or the OS — the only ones allowed to be longer. Each is as short as the
    // measured runs on the developer's Mac allow, with headroom for a slower CI network.
    /// Launch until the first screen: config download, then (signed in) the Auth0 sign-in round trip
    /// and the first settings and routine fetch. Measured ≈ 10 s signed in, ≈ 2 s signed out.
    static let firstLaunchTimeout: TimeInterval = 20
    /// The Auth0 sign-up / sign-in round trip from the form. Measured ≈ 2–4 s.
    static let signInTimeout: TimeInterval = 10
    /// A create/save that goes to the API before the list shows it (to-do, note, project).
    static let apiRoundTripTimeout: TimeInterval = 8
    private static let pollInterval: TimeInterval = 0.1
    static let conditionPollInterval: TimeInterval = 0.05
    /// One test's few items, one delete request each, after a relaunch.
    private static let perTestCleanupTimeout: TimeInterval = 30
    /// Wider than the spacing between two shut to-do section headers, narrower than one row.
    private static let collapsedToDoSectionGap: CGFloat = 20

    private(set) var app: XCUIApplication!

    /// Longest a single test may take, so one stuck on a sheet fails instead of stalling the run.
    private static let testTimeAllowance: TimeInterval = 120
    private var systemAppsAtStart = Set<pid_t>()
    private var testStart = Date()
    private var isCleanUpRegistered = false

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = Self.testTimeAllowance
        try Self.requireIsolatedAppUnderTest()
        systemAppsAtStart = Self.runningSystemWindowApps()
        testStart = Date()
        app = XCUIApplication()
    }

    private var hasFailed: Bool { (testRun?.failureCount ?? 0) + (testRun?.unexpectedExceptionCount ?? 0) > 0 }

    override func tearDownWithError() throws {
        closeStraySystemWindows(openedSince: systemAppsAtStart, testStart: testStart)
        guard let app, app.state != .notRunning else { return }
        attachScreenshot(named: "final state")
        app.terminate()
    }

    // MARK: - Launching

    /// A fresh, logged-out test app. Needs no account.
    func launchLoggedOut() {
        app.launchArguments = [UITestContract.LaunchArgument.uiTest, UITestContract.LaunchArgument.reset]
        launchIsolated()
    }

    /// Signed in with the CI account, onboarding skipped, main window up. Skips when no account is
    /// configured, so a contributor without the secrets still gets a green (partial) run.
    func launchSignedIn(environment: [String: String] = [:]) throws {
        try launchSignedInWithoutWaiting(environment: environment)
        let dayPlan = app.buttons[UITestContract.Identifier.Menu.dayPlan]
        guard appears(dayPlan, within: Self.firstLaunchTimeout, waitsOnNetwork: true) else {
            recordDiagnostics(named: "main window never appeared")
            throw XCTSkip("The main window didn't appear. A routine due for the test account right now covers it; see docs/ui-tests.md.")
        }
        // Signed out, the sidebar is there but disabled.
        guard waitForEnabled(dayPlan, timeout: Self.firstLaunchTimeout) else {
            recordDiagnostics(named: "not signed in")
            throw SetupError(description: "the app came up signed out; see the UITestHost lines in its log")
        }
    }

    /// Every launch starts from the same place: the test app's settings reset (`--uiTestReset`, so
    /// nothing a previous test left — TOOLS expanded, a sidebar scrolled, a Day Plan task — carries
    /// over), and no windows restored from the last launch.
    func launchIsolated() {
        app.launchArguments += Self.noStateRestorationArguments + Self.noAnimationArguments
        // A crash ends the app at once: Swift's backtracer otherwise holds the dead app for minutes
        // while XCUITest waits on it, and the test only fails at its time allowance.
        app.launchEnvironment[Self.swiftBacktraceVariable] = Self.swiftBacktraceOff
        app.launch()
        failIfCovered()
    }

    private static let swiftBacktraceVariable = "SWIFT_BACKTRACE"
    private static let swiftBacktraceOff = "enable=no"
    /// AppKit's own switch for "don't reopen windows as they were at the last quit".
    private static let noStateRestorationArguments = ["-ApplePersistenceIgnoreState", "YES"]
    /// AppKit's defaults for window, sheet and scroll animations, for the test app only. XCUITest
    /// waits for the app to go idle after every event, and a sheet sliding out held that wait at a
    /// second. Nothing a test checks depends on a window animating.
    private static let noAnimationArguments = ["-NSAutomaticWindowAnimationsEnabled", "NO", "-NSWindowResizeTime", "0.001",
                                               "-NSScrollAnimationEnabled", "NO"]

    /// Starts the signed-in app without waiting for its window — for launches that never show one.
    func launchSignedInWithoutWaiting(environment: [String: String] = [:]) throws {
        let account = try requireTestAccount()
        app.launchArguments = [UITestContract.LaunchArgument.uiTest, UITestContract.LaunchArgument.reset,
                               UITestContract.LaunchArgument.skipOnboarding]
        app.launchEnvironment = environment
        // Its prompt covers a starting session; a test about the prompt asks for it explicitly.
        app.launchEnvironment[UITestContract.Environment.focusMusic] = environment[UITestContract.Environment.focusMusic]
            ?? UITestContract.Environment.focusMusicOff
        app.launchEnvironment[UITestContract.Environment.email] = account.email
        app.launchEnvironment[UITestContract.Environment.password] = account.password
        launchIsolated()
    }

    // MARK: - Signing up

    /// A first launch on a new Mac, through the welcome steps and account creation with a new
    /// `internaltest+macuitest…@focusbear.io` account, which is saved for the rest of the run. Leaves
    /// the app on the first step after the account exists.
    @discardableResult
    /// `atDistractionBlocking` runs on the first step after sign-up, the first to show the step
    /// progress indicator.
    func signUpThroughOnboarding(atDistractionBlocking: () -> Void = {}) throws -> TestAccount {
        typealias Onboarding = UITestContract.Identifier.Onboarding
        typealias Login = UITestContract.Identifier.Login
        app.launchArguments = [UITestContract.LaunchArgument.uiTest,
                               UITestContract.LaunchArgument.reset,
                               UITestContract.LaunchArgument.freshInstall]
        app.launchEnvironment = [:]
        launchIsolated()

        expectOnboardingStep(OnboardingStep.welcome, timeout: Self.firstLaunchTimeout)
        advanceOnboarding(with: Onboarding.welcomeContinueButton, to: OnboardingStep.welcomeAdhd)
        advanceOnboarding(with: Onboarding.welcomeAdhdContinueButton, to: OnboardingStep.letsDoIt)
        advanceOnboarding(with: Onboarding.letsDoItButton, to: OnboardingStep.setUpAccount)
        advanceOnboarding(with: Onboarding.signUpButton, to: OnboardingStep.privacy)
        let terms = app.checkBoxes[Onboarding.termsCheckBox]
        if terms.exists, terms.value as? Int == 0 { tap(terms) }
        advanceOnboarding(with: Onboarding.privacyContinueButton, to: OnboardingStep.createAccount)

        let signUpWithEmail = element(Login.signUpWithEmailButton)
        XCTAssertTrue(appears(signUpWithEmail), "no Sign up with email")
        tap(signUpWithEmail)

        let account = TestAccountStore.makeNew()
        let email = app.textFields[Login.emailField]
        XCTAssertTrue(appears(email), "the sign-up form didn't open")
        tap(email)
        typeIntoFocus(account.email)
        enterSecret(account.password, into: app.secureTextFields[Login.passwordField])
        let confirm = app.secureTextFields[Login.confirmPasswordField]
        if confirm.exists, confirm.isHittable { enterSecret(account.password, into: confirm) }
        attachScreenshot(named: "sign-up form")
        tap(element(Login.createAccountButton))

        // The account exists once the form is gone; onboarding then carries on.
        guard waitForNonExistence(of: email, timeout: Self.signInTimeout) else {
            attachScreenshot(named: "sign-up failed")
            throw SetupError(description: "the sign-up form stayed up; see the screenshot for the message")
        }
        try TestAccountStore.save(account)
        finishOnboardingWithoutBlocking(atDistractionBlocking: atDistractionBlocking)
        return account
    }

    /// The rest of onboarding, the shortest way: no distraction blocking, no schedule, no habits.
    /// Nothing is left enforcing on the machine, and the account starts from a clean slate.
    private func finishOnboardingWithoutBlocking(atDistractionBlocking: () -> Void) {
        typealias Onboarding = UITestContract.Identifier.Onboarding
        expectOnboardingStep(OnboardingStep.setDistractionBlocking, timeout: Self.firstLaunchTimeout)
        atDistractionBlocking()
        advanceOnboarding(with: Onboarding.skipDistractionBlockingButton, to: OnboardingStep.askCreateBlockingSchedule)
        advanceOnboarding(with: Onboarding.skipBlockingScheduleButton, to: OnboardingStep.holdOn)
        advanceOnboarding(with: Onboarding.holdOnContinueButton, to: OnboardingStep.setUpHabits)
        advanceOnboarding(with: Onboarding.skipHabitsButton, to: OnboardingStep.allSet)
        tap(element(Onboarding.finishButton))
        XCTAssertTrue(appears(app.buttons[UITestContract.Identifier.Menu.dayPlan], within: Self.firstLaunchTimeout, waitsOnNetwork: true),
                      "finishing onboarding should open the app")
        attachScreenshot(named: "onboarding finished")
    }

    /// `timeout` longer than `screenTimeout` means the step waits on the network (first launch, sign-up).
    func expectOnboardingStep(_ step: String, timeout: TimeInterval = screenTimeout) {
        let shown = appears(element(UITestContract.Identifier.Onboarding.stepPrefix + step), within: timeout,
                            waitsOnNetwork: timeout > Self.screenTimeout)
        attachScreenshot(named: step)
        XCTAssertTrue(shown, "onboarding didn't reach \(step)")
    }

    func advanceOnboarding(with button: String, to step: String) {
        let control = element(button)
        XCTAssertTrue(appears(control), "\(button) is missing")
        tap(control)
        expectOnboardingStep(step)
    }

    // MARK: - Navigating

    /// Opens a sidebar destination and waits for something only that screen has. Returns whichever
    /// landmark appeared (some screens have more than one state). Items in the collapsed TOOLS
    /// section are revealed first.
    @discardableResult
    func open(menuItem identifier: String, expectingAnyOf landmarks: XCUIElement...) -> XCUIElement? {
        let item = app.buttons[identifier]
        // The sidebar is up by now (the launch waited for it), so an item missing now is in the
        // collapsed TOOLS section. Waiting two seconds for it first was most of every trip to To-do.
        if !item.exists { expandToolsSection() }
        guard appears(item) else {
            recordDiagnostics(named: "sidebar item \(identifier) missing")
            XCTFail("sidebar item \(identifier) missing")
            return nil
        }
        tap(item)
        let shown = firstToAppear(landmarks)
        if shown == nil {
            recordDiagnostics(named: "\(identifier) didn't open its screen")
            XCTFail("\(identifier) didn't open its screen")
        }
        return shown
    }

    /// Without blocking permissions (the test build has none) starting a session first asks "Do you
    /// want to block distractions?"; the tests say no, so nothing asks for permissions.
    func declineBlockingOfferIfShown(usingKeyboard: Bool = false) {
        let decline = element(UITestContract.Identifier.FocusStart.declineBlockingButton)
        guard appears(decline, within: Self.optionalWait) else { return }
        guard usingKeyboard else { return tap(decline) }
        XCTAssertTrue(tab(to: decline), "[Block-distractions offer] can't Tab to No thanks")
        press(.space, on: decline)
    }

    /// Waits for a saved to-do's row. One list section is open at a time, so with tasks already in
    /// Doing, To do starts collapsed and the new row is inside it.
    func toDoRowAppears(_ row: XCUIElement) -> Bool {
        openNotStartedToDos()
        if appears(row, within: Self.apiRoundTripTimeout, waitsOnNetwork: true) { return true }
        // The first fetch of a session may still open a section of its own choosing.
        openNotStartedToDos()
        return appears(row)
    }

    /// Opens the To do section unless it is already open. Its header toggles, so pressing it blindly
    /// shut an open section — and waiting a full round trip first, to find out, cost every to-do
    /// test's clean-up eight seconds.
    func openNotStartedToDos() {
        typealias ToDo = UITestContract.Identifier.ToDo
        let header = element(ToDo.notStartedSection)
        guard appears(header), !isToDoSectionOpen(header, followedBy: element(ToDo.doneSection)) else { return }
        tap(header)
    }

    /// The headers carry no open/closed state, so tell by the gap: a shut section's header sits right
    /// above the next one, an open one has its rows (or its "no tasks" line) in between.
    private func isToDoSectionOpen(_ header: XCUIElement, followedBy next: XCUIElement) -> Bool {
        guard next.exists else { return true }
        return next.frame.minY - header.frame.maxY > Self.collapsedToDoSectionGap
    }

    /// The confirmation on top: over an editor sheet the alert is a second sheet, and the first is
    /// the editor, whose rightmost button is Save.
    func topmostAlert() -> XCUIElement? {
        let open = (app.sheets.allElementsBoundByIndex + app.dialogs.allElementsBoundByIndex).filter(\.exists)
        return open.last
    }

    /// Deletes a to-do from the list: clicking its title selects the row, revealing its action bar.
    func deleteToDo(_ row: XCUIElement, titled title: String) {
        // A row that just moved (completed → Done) is redrawn when the list refetches; a click during
        // that lands on the old copy and selects nothing (1 run in 2).
        waitUntilSettled(row)
        tap(row.staticTexts.matching(showing(title)).firstMatch)
        let delete = row.descendants(matching: .any).matching(identifier: UITestContract.Identifier.ToDo.deleteButton).firstMatch
        XCTAssertTrue(appears(delete), "the selected row has no Delete")
        tap(delete)
        let confirm = element(UITestContract.Identifier.ToDo.confirmDeleteButton)
        XCTAssertTrue(appears(confirm), "Delete didn't ask to confirm")
        tap(confirm)
        XCTAssertTrue(waitForNonExistence(of: row), "the deleted to-do is still listed")
    }

    /// A step a known app bug breaks: recorded as an expected (non-strict) failure against its
    /// ticket, so the suite stays green and simply stops reporting it once the fix lands.
    func expectingAppBug(_ ticket: String, _ step: () -> Void) {
        XCTExpectFailure("\(ticket): app bug, not yet fixed", options: .nonStrict(), failingBlock: step)
    }

    /// Focus Start's advanced screen is an accordion: the duration dial and its slider exist only
    /// while the "How long shall we focus?" card is open. The simple screen always shows them.
    func showFocusStartDurationCard() {
        typealias FocusStart = UITestContract.Identifier.FocusStart
        let header = element(FocusStart.durationCard)
        guard !element(FocusStart.durationMinutes).exists, header.exists else { return }
        tap(header)
        _ = appears(element(FocusStart.durationMinutes))
    }

    /// Focus Start comes back with the last session's goal already filled in, which hides the goal
    /// field the goal tests type into; clearing it gives them the empty field a new session shows.
    func clearAnyRememberedGoal() {
        typealias FocusStart = UITestContract.Identifier.FocusStart
        let clear = element(FocusStart.clearGoalButton)
        let goalField = app.textFields[FocusStart.goalField]
        // The open card shows one or the other; waiting for Clear alone cost a second without a goal.
        guard firstToAppear([clear, goalField]) == clear else { return }
        tap(clear)
        _ = appears(goalField)
    }

    /// With easy skip off (a new account has it on), postponing needs a hold and a skip counts down.
    static let easySkipOff = [UITestContract.Environment.easySkip: UITestContract.Environment.disabledValue]

    /// TOOLS starts collapsed, hiding To-do and the other tools.
    func expandToolsSection() {
        let section = app.buttons[UITestContract.Identifier.Tools.section]
        if section.exists { tap(section) }
    }

    /// A screenshot and the app's element tree, for working out why a step found nothing.
    func recordDiagnostics(named name: String) {
        attachScreenshot(named: name, force: true)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "element tree — \(name)"
        tree.lifetime = .keepAlways
        add(tree)
    }

    /// Opens a TOOLS item, expanding the section first (it starts collapsed), and waits for its screen.
    /// Skips when the test account has hidden that tool.
    func open(tool identifier: String) throws {
        let item = app.buttons[identifier]
        if !item.exists { expandToolsSection() }
        guard appears(item) else {
            throw XCTSkip("\(identifier) isn't in the sidebar: the test account has hidden that tool.")
        }
        tap(item)
        XCTAssertTrue(appears(element(UITestContract.Identifier.Screen.shown(byMenuItem: identifier))),
                      "\(identifier) didn't open its screen")
    }

    /// Confirms a destructive alert. SwiftUI alerts can't carry identifiers, and their destructive
    /// button is the default one, so Return is the language-independent way to press it.
    func confirmDestructiveAlert() {
        // Deleting a project asks only once the app has counted its tasks, which can take a round trip.
        guard firstToAppear([app.sheets.firstMatch, app.dialogs.firstMatch], timeout: Self.apiRoundTripTimeout) != nil,
              let alert = topmostAlert() else {
            return XCTFail("no confirmation was asked for")
        }
        press(.return)
        // A SwiftUI alert rightly gives its destructive button no Return key; it sits rightmost.
        guard !waitForNonExistence(of: alert, timeout: Self.optionalWait) else { return }
        let rightmost = alert.buttons.allElementsBoundByIndex.filter(\.isHittable).max { $0.frame.maxX < $1.frame.maxX }
        if let rightmost { tap(rightmost) }
    }

    /// A habit's Edit action in the Day Plan, selecting the seeded habit first if it isn't showing.
    func revealHabitEditButton() -> XCUIElement? {
        let edit = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", UITestContract.Identifier.DayPlanEditors.habitEditPrefix)).firstMatch
        if appears(edit) { return edit }
        let habit = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@",
                                                         UITestContract.RoutineFixture.timedHabitName,
                                                         UITestContract.RoutineFixture.timedHabitName)).firstMatch
        guard appears(habit) else { return nil }
        tapCenter(of: habit)
        return appears(edit) ? edit : nil
    }

    /// Deletes this test's to-dos, Day Plan tasks and projects after it, pass or fail. Registered once
    /// however often it is asked for.
    func cleanUpTestItemsAfterwards() {
        guard !isCleanUpRegistered else { return }
        isCleanUpRegistered = true
        addTeardownBlock { [weak self] in self?.askTheAppToRemoveTestItems() }
    }

    /// Asks the running app to sweep now (`UITestContract.Command`), so the clean-up needs no
    /// relaunch; relaunches into the sweep only when the app isn't running any more.
    private func askTheAppToRemoveTestItems() {
        guard app.state == .runningForeground || app.state == .runningBackground else {
            removeTestItemsThroughTheApp(within: Self.perTestCleanupTimeout)
            return
        }
        let requestId = UUID().uuidString
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(UITestContract.Command.cleanAccountNow),
                                                                     object: requestId, userInfo: nil, deliverImmediately: true)
        let answered = NSPredicate(format: "value CONTAINS %@", requestId + ":")
        let statusItem = element(UITestContract.Identifier.MenuBar.statusItem)
        if !waitUntil(answered, isTrueOf: statusItem, within: Self.perTestCleanupTimeout) {
            removeTestItemsThroughTheApp(within: Self.perTestCleanupTimeout)
        }
    }

    /// Relaunches the app to delete everything titled like `uniqueTitle` makes titles (the app's
    /// UITestAccountCleanup, gated to the test build). Deleting through the UI took 15–40 s a test —
    /// a search, a delete and a confirmation per item — and was a third of a Regression run.
    @discardableResult
    func removeTestItemsThroughTheApp(within timeout: TimeInterval) -> Bool {
        typealias Environment = UITestContract.Environment
        app.terminate()
        guard (try? launchSignedIn(environment: [Environment.cleanAccount: Environment.enabledValue])) != nil else { return false }
        let statusItem = element(UITestContract.Identifier.MenuBar.statusItem)
        let isDone = NSPredicate(format: "value BEGINSWITH %@", Environment.accountCleanupDonePrefix)
        return waitUntil(isDone, isTrueOf: statusItem, within: timeout)
    }

    /// Chooses a Settings sidebar row: selected in the app as a click on it does, or else scrolled in
    /// and clicked. The list is taller than the test window and XCUITest calls a row below its fold
    /// hittable, so an unscrolled click landed in the gap under the list.
    func tapSettingsTab(_ paneId: String) {
        let row = element(UITestContract.Identifier.Settings.tabPrefix + paneId)
        if selectRowInApp(row) { return }
        scrollIntoView(row)
        tap(row)
    }

    /// Pastes a password rather than typing it: XCUITest logs typed text ("Type 'Fb!…' into"), and
    /// that log is printed by CI and uploaded with the result bundle. The clipboard is put back after.
    func enterSecret(_ secret: String, into field: XCUIElement) {
        tap(field)
        paste(secret)
    }

    /// Until `element` has stayed put for `settleInterval` (or `screenTimeout` passes).
    func waitUntilSettled(_ element: XCUIElement) {
        let deadline = Date().addingTimeInterval(Self.screenTimeout)
        var last = (try? element.snapshot())?.frame
        var stillSince = Date()
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(Self.conditionPollInterval))
            let now = (try? element.snapshot())?.frame
            if now != last { last = now; stillSince = Date() }
            if now != nil, Date().timeIntervalSince(stillSince) >= Self.settleInterval { return }
        }
    }

    private static let settleInterval: TimeInterval = 0.3

    /// Waits for the first of several elements to exist.
    func firstToAppear(_ elements: [XCUIElement], timeout: TimeInterval = screenTimeout) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let shown = elements.first(where: { $0.exists }) { return shown }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.pollInterval))
        } while Date() < deadline
        return nil
    }

    func waitForNonExistence(of element: XCUIElement, timeout: TimeInterval = screenTimeout) -> Bool {
        wait(for: element, toMatch: "exists == false", timeout: timeout)
    }

    func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = screenTimeout) -> Bool {
        wait(for: element, toMatch: "isEnabled == true", timeout: timeout)
    }

    func wait(for element: XCUIElement, toMatch predicate: String, timeout: TimeInterval) -> Bool {
        waitUntil(NSPredicate(format: predicate), isTrueOf: element, within: timeout)
    }

    /// Polls every `conditionPollInterval`. XCTNSPredicateExpectation re-checks about once a second,
    /// so every "wait for the sheet to close" cost a full second even when it closed at once.
    func waitUntil(_ predicate: NSPredicate, isTrueOf object: Any, within timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !predicate.evaluate(with: object) {
            guard Date() < deadline else { return false }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.conditionPollInterval))
        }
        return true
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Text on screen reading `text`: an AppKit label carries it as its label, SwiftUI's Text as its value.
    func showing(_ text: String) -> NSPredicate {
        NSPredicate(format: "label == %@ OR value == %@", text, text)
    }

    /// A per-run title, so a test only ever acts on what it created.
    func uniqueTitle(_ prefix: String) -> String {
        "\(prefix) \(UUID().uuidString.prefix(8))"
    }

    /// The window a screen lives in: the largest one on screen. `windows.firstMatch` is often the
    /// floating top bar, a small window parked beside the menu-bar icon (or off screen with it).
    var mainWindow: XCUIElement {
        let displays = NSScreen.screens.map(\.frame)
        let onScreen = app.windows.allElementsBoundByIndex.filter { window in
            window.exists && displays.contains { $0.intersects(window.frame) }
        }
        return onScreen.max { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height } ?? app.windows.firstMatch
    }

    /// Of the app's main window only, so nothing else on the Mac (another app, a terminal) ends up in
    /// the result bundle or a PR.
    /// A capture can fail while a window is mid-transition ("Image creation failed"); that is a
    /// missing picture, not a failure of what the test checks.
    /// Only once the test has failed: a screenshot costs about a second, and a passing test's are
    /// never looked at. Diagnostics for a failure call this before failing, so they pass `force`.
    func attachScreenshot(named name: String, force: Bool = false) {
        guard force || hasFailed else { return }
        XCTExpectFailure("a diagnostic screenshot, not what the test checks", options: .nonStrict()) {
            let window = mainWindow
            let attachment = XCTAttachment(screenshot: window.exists ? window.screenshot() : app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    // MARK: - Guards

    struct UnisolatedBuildError: Error, CustomStringConvertible {
        let description: String
    }

    struct SetupError: Error, CustomStringConvertible {
        let description: String
    }

    /// The account signed-in tests use: the CI secrets if set, otherwise the one this run's sign-up
    /// test created — and if there is none yet, one is created now, through the real onboarding.
    func requireTestAccount() throws -> TestAccount {
        if let account = TestAccountStore.existing() {
            guard UITestContract.TestAccount.isAllowed(email: account.email) else {
                throw SetupError(description: "Refusing to sign in: UI tests require a dedicated internaltest+macuitest account at focusbear.io.")
            }
            return account
        }
        let account = try signUpThroughOnboarding()
        if app.state != .notRunning { app.terminate() }
        return account
    }

    /// XCUIApplication quits any running app with the target's bundle id before launching it. Built
    /// without the `.uitests` suffix that is the developer's own Focus Bear, so the built product is
    /// checked before an XCUIApplication even exists.
    static func requireIsolatedAppUnderTest() throws {
        let productsDirectory = Bundle(for: FocusBearUITestCase.self).bundleURL   // …/Focus BearUITests.xctest
            .deletingLastPathComponent()   // PlugIns
            .deletingLastPathComponent()   // Contents
            .deletingLastPathComponent()   // Focus BearUITests-Runner.app
            .deletingLastPathComponent()
        let appUnderTest = productsDirectory.appendingPathComponent(appProductName)
        let bundleIdentifier = Bundle(url: appUnderTest)?.bundleIdentifier
        guard bundleIdentifier == UITestContract.bundleIdentifier else {
            throw UnisolatedBuildError(description: """
                Not launching \(appUnderTest.path): it is \(bundleIdentifier ?? "missing"), not \(UITestContract.bundleIdentifier), \
                and launching it would quit the Focus Bear you are using. Run scripts/run-ui-tests.sh (docs/ui-tests.md).
                """)
        }
    }

    private static let appProductName = "Focus Bear.app"
}

/// Onboarding steps, named as the app names them (`onboardingVc.ONBOARDINGSTATE`).
enum OnboardingStep {
    static let welcome = "_WELCOME_"
    static let welcomeAdhd = "_WELCOME_ADHD_"
    static let letsDoIt = "_WELCOME_LETS_DO_IT_"
    static let setUpAccount = "_SET_UP_ACCOUNT_"
    static let privacy = "_PRIVACY_POLICY_"
    static let createAccount = "_CREATE_ACCOUNT_"
    static let setDistractionBlocking = "_SET_DISTRACTION_BLOCKING_"
    static let askCreateBlockingSchedule = "_ASK_CREATE_BLOCKING_SCHEDULE_"
    static let holdOn = "_HOLD_ON_"
    static let setUpHabits = "_SET_UP_HABITS_"
    static let allSet = "_ALL_SET_"
}

struct TestAccount: Codable {
    let email: String
    let password: String
}

/// Where the run's test account comes from: the CI secrets (`TEST_RUNNER_FOCUSBEAR_UITEST_EMAIL` /
/// `_PASSWORD`, forwarded by xcodebuild without the prefix) if set, else the file the sign-up test
/// wrote. The runner is sandboxed, so the file lives in its own container's Application Support —
/// outside the repository, and never the developer's keychain.
enum TestAccountStore {
    /// `internaltest` addresses are left out of product analytics.
    private static let emailPrefix = UITestContract.TestAccount.EMAIL_PREFIX
    private static let emailDomain = UITestContract.TestAccount.EMAIL_DOMAIN
    private static let fileName = "focusbear-uitest-account.json"

    static func existing() -> TestAccount? {
        let environment = ProcessInfo.processInfo.environment
        if let email = environment[UITestContract.Environment.email], !email.isEmpty,
           let password = environment[UITestContract.Environment.password], !password.isEmpty {
            return TestAccount(email: email, password: password)
        }
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode(TestAccount.self, from: data) else { return nil }
        return hasOutlivedTrial(saved) ? nil : saved
    }

    /// A new account gets a seven-day Pro trial and then drops to Basic, where Geek mode — and with it
    /// Focus Start's goal card and task picker — sits behind the upgrade nag. A run that skips the
    /// sign-up test reuses the saved account, so on 2026-10-05 two FocusSessionUITests failed ("the
    /// goal card is missing") exactly seven days after it signed up. One a day short of its trial's
    /// end is retired instead, and the run signs up a new one.
    private static let trialDays = 7
    private static let retirementMarginDays = 1
    private static let secondsPerDay: TimeInterval = 24 * 60 * 60
    private static let accountLifetime = TimeInterval(trialDays - retirementMarginDays) * secondsPerDay

    /// Whether `account` is one of ours signed up more than `accountLifetime` ago. An account this
    /// store didn't name (the CI secrets) carries no sign-up time and is never retired.
    static func hasOutlivedTrial(_ account: TestAccount, now: Date = Date()) -> Bool {
        guard let signedUp = signUpDate(of: account) else { return false }
        return now.timeIntervalSince(signedUp) > accountLifetime
    }

    /// The Unix time `makeNew` puts straight after the prefix.
    private static func signUpDate(of account: TestAccount) -> Date? {
        let localPart = account.email.lowercased().split(separator: "@").first ?? ""
        guard localPart.hasPrefix(emailPrefix) else { return nil }
        let stamp = localPart.dropFirst(emailPrefix.count).prefix(while: \.isNumber)
        guard let seconds = TimeInterval(stamp) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    static func makeNew() -> TestAccount {
        let stamp = Int(Date().timeIntervalSince1970)
        let email = "\(emailPrefix)\(stamp)-\(UUID().uuidString.prefix(6).lowercased())@\(emailDomain)"
        // Meets Auth0's strongest policy: length, all four character classes, no repeats that matter.
        let password = "Fb!\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16))a9Z"
        return TestAccount(email: email, password: password)
    }

    static func save(_ account: TestAccount) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(account).write(to: fileURL, options: .atomic)
    }

    private static var fileURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent(fileName)
    }
}

// MARK: - Focus sessions

/// The whole run shares one test account, and on launch the app picks up a session the server still
/// has running. The server only hears that a session is over when its end screen ("You did it!") is
/// left; ending a session and quitting on that screen leaves it running until its scheduled end, and
/// every later launch brings it back. So a test that ends a session also leaves the end screen, and
/// one that needs Focus Start ends (and finishes) any session it finds first.
extension FocusBearUITestCase {
    /// A session the app restores a few seconds after launch relabels the sidebar item ("Focusing
    /// (4m left)") and can swallow the click that was meant to open Focus Start, so it is retried.
    private static let focusStartOpenAttempts = 3

    /// Opens Focus Start with no session running: a session left by an earlier test or run is ended
    /// and finished on the server first. Fails the test if Focus Start never shows.
    @discardableResult
    func openFocusStartEndingAnyRunningSession(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let focusStart = element(UITestContract.Identifier.FocusStart.startButton)
        for _ in 0..<Self.focusStartOpenAttempts {
            switch showFocusSessionDestination(file: file, line: line)?.identifier ?? "" {
            case UITestContract.Identifier.FocusStart.startButton:
                return true
            case UITestContract.Identifier.FocusSession.endButton:
                endFocusSession(file: file, line: line)
                leaveFocusEndScreen(file: file, line: line)
            case UITestContract.Identifier.SessionsRegression.completedStartAnotherButton:
                leaveFocusEndScreen(file: file, line: line)
            default:
                continue
            }
            if focusStart.exists { return true }
        }
        recordDiagnostics(named: "Focus Start didn't open")
        XCTFail("the Focus session sidebar item didn't open Focus Start", file: file, line: line)
        return false
    }

    /// Ends the running session: End, then the confirmation. Leaves the end screen up, for the tests
    /// that look at it — `leaveFocusEndScreen()` finishes the session on the server.
    func endFocusSession(file: StaticString = #filePath, line: UInt = #line) {
        let end = element(UITestContract.Identifier.FocusSession.endButton)
        tap(end, file: file, line: line)
        let confirm = element(UITestContract.Identifier.FocusSession.endConfirmButton)
        if appears(confirm) { tap(confirm, file: file, line: line) }
        XCTAssertTrue(waitForNonExistence(of: end),
                      "the session didn't end (a stop password or buddy on the test account would hold it)",
                      file: file, line: line)
    }

    /// Leaves a finished session's end screen through "Start new focus session", which tells the server
    /// the session is over and opens Focus Start. (The sidebar item doesn't navigate away from it, and
    /// the end screen's other way out, "Relax for N minutes", can start a relax timer.) Does nothing if no end
    /// screen shows.
    func leaveFocusEndScreen(file: StaticString = #filePath, line: UInt = #line) {
        let startAnother = element(UITestContract.Identifier.SessionsRegression.completedStartAnotherButton)
        guard appears(startAnother) else { return }
        tap(startAnother, file: file, line: line)
        XCTAssertTrue(appears(element(UITestContract.Identifier.FocusStart.startButton)),
                      "Start new focus session didn't open Focus Start", file: file, line: line)
    }

    /// Teardown for a test that may have started a session, whatever state it left the screen in: a
    /// session still running is ended, and a finished one's end screen left, so the next test's launch
    /// doesn't get it back from the server.
    func finishAnyFocusSession() {
        // Brought back to the front first: a session left running because another app had focus
        // would spoil every later test.
        guard app.state != .notRunning, bringTestAppToFront() == nil, isFocusInsideTestApp else { return }
        let confirm = element(UITestContract.Identifier.FocusSession.endConfirmButton)
        if confirm.exists {
            tap(confirm)
            return leaveFocusEndScreen()
        }
        if element(UITestContract.Identifier.SessionsRegression.completedStartAnotherButton).exists {
            return leaveFocusEndScreen()
        }
        let item = app.buttons[UITestContract.Identifier.Menu.focusSession]
        // A sheet left open over the session takes clicks away from the sidebar.
        guard item.exists, item.isHittable else { return }
        tap(item)
        switch focusSessionDestination()?.identifier ?? "" {
        case UITestContract.Identifier.FocusSession.endButton:
            endFocusSession()
            leaveFocusEndScreen()
        case UITestContract.Identifier.SessionsRegression.completedStartAnotherButton:
            leaveFocusEndScreen()
        default:
            return
        }
    }

    /// Clicks the Focus session sidebar item and returns whichever of its states shows.
    private func showFocusSessionDestination(file: StaticString, line: UInt) -> XCUIElement? {
        let item = app.buttons[UITestContract.Identifier.Menu.focusSession]
        guard appears(item) else {
            recordDiagnostics(named: "sidebar item \(UITestContract.Identifier.Menu.focusSession) missing")
            XCTFail("sidebar item \(UITestContract.Identifier.Menu.focusSession) missing", file: file, line: line)
            return nil
        }
        tap(item, file: file, line: line)
        return focusSessionDestination()
    }

    /// Focus Start, a running session, or a finished session's end screen — whichever shows.
    private func focusSessionDestination() -> XCUIElement? {
        firstToAppear([element(UITestContract.Identifier.FocusStart.startButton),
                       element(UITestContract.Identifier.FocusSession.endButton),
                       element(UITestContract.Identifier.SessionsRegression.completedStartAnotherButton)])
    }
}
