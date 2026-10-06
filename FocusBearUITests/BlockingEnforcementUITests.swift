//
//  BlockingEnforcementUITests.swift
//  Focus BearUITests
//
//  Blocking, end to end: the test app really hides TextEdit and redirects Safari. That is only
//  acceptable on the dedicated runner, so these tests run only when the workflow opts in
//  (TEST_RUNNER_FOCUSBEAR_UITEST_ENABLE_BLOCKING=1) and skip everywhere else. The runner also has to
//  have granted the test app Accessibility and Automation over Safari once (docs/ui-tests.md).
//
//  What gets blocked is set up by the app itself (`UITestBlockingFixture`), and every test removes it
//  again — before it starts, in case an earlier run crashed, and in its teardown.
//

import AppKit
import XCTest

final class BlockingEnforcementUITests: FocusBearUITestCase {
    private typealias Fixture = UITestContract.BlockingFixture

    /// Focus Bear redirects a blocked tab to its own page, served on localhost (`blockWebUrlString`).
    private static let blockPageHost = "localhost"
    private static let safariAddressField = "WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD"
    private static let safariPath = "/Applications/Safari.app"
    /// Safari loading the page, the app's next URL check, and its AppleScript redirect. Not yet
    /// measured on a runner with the grants in place; lower it once it has been.
    private static let blockTimeout: TimeInterval = 30
    /// Long enough for several of the app's URL checks to have run and left an allowed page alone.
    private static let allowedObservation: TimeInterval = 12
    /// Launch, sign-in, then the deletes and the settings sync the cleanup launch makes before quitting.
    private static let cleanupTimeout: TimeInterval = 45
    /// Launch and sign-in until the fixture is in place.
    private static let fixtureTimeout: TimeInterval = 45
    private static let automationGranted: Int32 = 0

    private lazy var safari = XCUIApplication(bundleIdentifier: Fixture.browserBundleIdentifier)
    private var didLaunchTextEdit = false

    override func setUpWithError() throws {
        try super.setUpWithError()
        try Self.requireBlockingOptIn()
        try removeFixtures()
        addTeardownBlock { [weak self] in
            self?.quitTextEditIfWeLaunchedIt()
            try? self?.removeFixtures()
        }
    }

    // MARK: - Tests

    func testFocusSessionBlocksListedSiteAndAllowsOthers() throws {
        try apply(.focusSession)
        openInSafari(Fixture.blockedDomain)
        XCTAssertTrue(waitUntilSafariShowsBlockPage(), "\(Fixture.blockedDomain) wasn't blocked during the session")
        attachSafariScreenshot(named: "blocked site")

        openInSafari(Fixture.allowedDomain)
        XCTAssertTrue(safariStaysOn(Fixture.allowedDomain), "\(Fixture.allowedDomain) is allowed but didn't stay open")
    }

    func testFocusSessionBlocksListedApp() throws {
        try apply(.focusSession)
        launchTextEdit()
        XCTAssertTrue(waitUntilTextEditIsBlocked(), "TextEdit was neither hidden nor answered with a Focus Bear prompt")
    }

    func testEndingTheSessionUnblocks() throws {
        try apply(.focusSession)
        openInSafari(Fixture.blockedDomain)
        XCTAssertTrue(waitUntilSafariShowsBlockPage(), "\(Fixture.blockedDomain) wasn't blocked during the session")

        app.activate()
        let end = element(UITestContract.Identifier.FocusSession.endButton)
        open(menuItem: UITestContract.Identifier.Menu.focusSession, expectingAnyOf: end)
        tap(end)
        let confirm = element(UITestContract.Identifier.FocusSession.endConfirmButton)
        if appears(confirm) { tap(confirm) }
        XCTAssertTrue(waitForNonExistence(of: end), "the session didn't end")

        openInSafari(Fixture.blockedDomain)
        XCTAssertTrue(safariStaysOn(Fixture.blockedDomain), "\(Fixture.blockedDomain) is still blocked after the session ended")
    }

    func testAlwaysBlockedSiteIsBlockedOutsideASession() throws {
        try apply(.alwaysBlocked)
        openInSafari(Fixture.blockedDomain)
        // Outside a session the account's settings decide between blocking outright and asking for
        // an intention first; either is Focus Bear stepping in.
        let prompt = element(UITestContract.Identifier.Blocking.intentionPrompt)
        XCTAssertTrue(waitUntilSafariShowsBlockPage() || prompt.exists,
                      "an always-blocked site opened freely outside a session")
        attachSafariScreenshot(named: "always blocked")
        if prompt.exists {
            let window = app.windows.containing(.any, identifier: UITestContract.Identifier.Blocking.intentionPrompt).firstMatch
            try checkVoiceOver(on: AccessibilityScreen(name: "Blocking check-in popup"), in: window)
        }
    }

    func testActiveBlockingScheduleBlocksSite() throws {
        try apply(.blockingSchedule)
        openInSafari(Fixture.blockedDomain)
        XCTAssertTrue(waitUntilSafariShowsBlockPage(), "\(Fixture.blockedDomain) wasn't blocked by a schedule covering now")
        attachSafariScreenshot(named: "blocked by schedule")
    }

    // MARK: - Fixtures

    private static func requireBlockingOptIn() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment[UITestContract.Environment.enableBlocking] == UITestContract.Environment.enabledValue else {
            throw XCTSkip("Blocking tests only run on the dedicated UI-test runner (TEST_RUNNER_\(UITestContract.Environment.enableBlocking)=1).")
        }
    }

    private func fixtureEnvironment(_ kind: Fixture.Kind) -> [String: String] {
        [UITestContract.Environment.enableBlocking: UITestContract.Environment.enabledValue,
         UITestContract.Environment.blockingFixture: kind.rawValue]
    }

    /// Launches the signed-in app with `kind` in place and checks the runner can actually enforce.
    private func apply(_ kind: Fixture.Kind) throws {
        try launchSignedInWithoutWaiting(environment: fixtureEnvironment(kind))
        let status = try XCTUnwrap(waitForStatus(of: kind), "the app never reported the \(kind.rawValue) fixture")
        if let failure = status.failure {
            if kind == .blockingSchedule { throw XCTSkip("No schedule could cover now: \(failure)") }
            XCTFail("the \(kind.rawValue) fixture failed: \(failure)")
        }
        XCTAssertTrue(status.hasAccessibility, "Grant Accessibility to the .uitests app on this runner (docs/ui-tests.md)")
        XCTAssertEqual(status.safariAutomationStatus, Self.automationGranted,
                       "Allow the .uitests app to control Safari on this runner (docs/ui-tests.md)")
    }

    /// Launches the app in cleanup mode and waits for it to quit, which it does once everything the
    /// fixtures created is gone. Needs the account, like the fixtures themselves.
    private func removeFixtures() throws {
        if app.state != .notRunning { app.terminate() }
        try launchSignedInWithoutWaiting(environment: fixtureEnvironment(.cleanup))
        if !app.wait(for: .notRunning, timeout: Self.cleanupTimeout) {
            app.terminate()
            XCTFail("the cleanup launch didn't finish; fixtures may be left on the test account")
        }
    }

    /// The app publishes the fixture's status as JSON in its menu-bar icon's accessibility value.
    private func waitForStatus(of kind: Fixture.Kind) -> Fixture.Status? {
        let statusItem = element(UITestContract.Identifier.MenuBar.statusItem)
        let deadline = Date().addingTimeInterval(Self.fixtureTimeout)
        repeat {
            if let json = statusItem.exists ? statusItem.value as? String : nil,
               let status = try? JSONDecoder().decode(Fixture.Status.self, from: Data(json.utf8)), status.kind == kind {
                return status
            }
            RunLoop.current.run(until: Date().addingTimeInterval(1))
        } while Date() < deadline
        return nil
    }

    // MARK: - Safari

    private func openInSafari(_ domain: String) {
        let url = URL(string: "https://\(domain)/")!
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: Self.safariPath), configuration: configuration)
        _ = safari.wait(for: .runningForeground, timeout: Self.screenTimeout)
    }

    private var safariAddress: String {
        let field = safari.textFields[Self.safariAddressField].firstMatch
        return (field.exists ? field.value as? String : nil) ?? ""
    }

    private func waitUntilSafariShowsBlockPage() -> Bool {
        let deadline = Date().addingTimeInterval(Self.blockTimeout)
        repeat {
            if safariAddress.contains(Self.blockPageHost) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(1))
        } while Date() < deadline
        return false
    }

    /// True if Safari is on `domain` now and still there after the app has had time to act.
    private func safariStaysOn(_ domain: String) -> Bool {
        let loaded = Date().addingTimeInterval(Self.screenTimeout)
        while !safariAddress.contains(domain), Date() < loaded {
            RunLoop.current.run(until: Date().addingTimeInterval(1))
        }
        RunLoop.current.run(until: Date().addingTimeInterval(Self.allowedObservation))
        return safariAddress.contains(domain) && !safariAddress.contains(Self.blockPageHost)
    }

    private func attachSafariScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: safari.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - TextEdit

    private func launchTextEdit() {
        didLaunchTextEdit = NSRunningApplication.runningApplications(withBundleIdentifier: Fixture.blockedAppBundleIdentifier).isEmpty
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: Fixture.blockedAppPath), configuration: configuration)
    }

    /// Focus Bear hides a blocked app, or puts one of its prompts in front of it.
    private func waitUntilTextEditIsBlocked() -> Bool {
        let prompts = [element(UITestContract.Identifier.Blocking.intentionPrompt),
                       element(UITestContract.Identifier.Blocking.focusBlockPrompt)]
        let deadline = Date().addingTimeInterval(Self.blockTimeout)
        repeat {
            let textEdit = NSRunningApplication.runningApplications(withBundleIdentifier: Fixture.blockedAppBundleIdentifier).first
            if textEdit?.isHidden == true || prompts.contains(where: { $0.exists }) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(1))
        } while Date() < deadline
        return false
    }

    private func quitTextEditIfWeLaunchedIt() {
        guard didLaunchTextEdit else { return }
        NSRunningApplication.runningApplications(withBundleIdentifier: Fixture.blockedAppBundleIdentifier).forEach { $0.terminate() }
    }
}
