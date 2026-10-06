//
//  RegressionManagedSafetyUITests.swift
//  Focus BearUITests
//
//  Regression suite: managed safety — a student whose blocking their school or parent manages, and a
//  teacher's class session. Runs in the Regression test plan.
//
//  Enforcement needs grants the suite's Macs don't have, so these check the managed STATE: what a
//  managed student can and can't change, and who they are told to ask. Each test launches with its own
//  scenario, which the app installs in memory (`UITestManagedSafetyFixture`) — never in the keychain,
//  the policy store or on the server. Nothing here saves a setting or sends a request. On a build
//  without #2700, closing the offline pop-up really quits the test app.
//
//  A managed student's settings stay locked whenever they are enrolled, in school hours or not
//  (`settings_locked` follows enrollment); the time of day decides only whose website categories apply.
//

import XCTest

final class RegressionManagedSafetyUITests: SettingsAreaUITestCase {
    /// "… 29m 57s remaining" or a clock reading ("00:13:43") anywhere in the row's spoken label.
    private static let countdownPattern = ".*([0-9]+m [0-9]+s|[0-9]{2}:[0-9]{2}).*"
    private typealias Safety = UITestContract.Identifier.ManagedSafety
    private typealias Scenario = UITestContract.ManagedPolicyScenario
    private typealias Policies = UITestContract.ManagedPolicyFixture
    private typealias Teacher = UITestContract.Identifier.TeacherSession
    private typealias CustomAlert = UITestContract.Identifier.CustomAlert
    private typealias MenuBar = UITestContract.Identifier.MenuBar
    private typealias FocusStart = UITestContract.Identifier.FocusStart
    private typealias FocusSession = UITestContract.Identifier.FocusSession
    private typealias Sessions = UITestContract.Identifier.SessionsRegression
    private typealias Environment = UITestContract.Environment

    /// Typed into the unlock request, which is never sent.
    private static let unlockAppOrUrl = "desmos.com"
    private static let unlockReason = "Graphing homework"

    // MARK: - School hours: Settings

    func testSettingsPaneSaysSettingsAreLockedInsteadOfShowingItsControls() throws {
        try launchIntoSettings(managedBy: .schoolActive)
        try openPane(Settings.Pane.ui)
        expectInspector(replacing: "Appearance")
        XCTAssertTrue(element(Safety.statusSettingsLocked).exists, "the pane doesn't say that settings are locked")
        XCTAssertFalse(element(Settings.darkModePopup).exists, "Appearance's own controls are still there to change")
        attachScreenshot(named: "locked settings pane")
    }

    func testStrictnessCannotBeLowered() throws {
        try launchIntoSettings(managedBy: .schoolActive)
        try openPane(Settings.Pane.strictness)
        expectInspector(replacing: "Strictness")
        for (identifier, control) in [(Area.strictnessSlider, "strictness slider"), (Area.tabLimiterRow, "tab limiter"),
                                      (Area.alwaysAllowedAppsRow, "always-allowed apps")] {
            XCTAssertFalse(element(identifier).exists, "a managed student can still reach the \(control)")
        }
    }

    /// Signing out or uninstalling would leave the school's policy behind, so neither pane opens.
    func testAccountAndUninstallPanesAreLocked() throws {
        try launchIntoSettings(managedBy: .schoolActive)
        try openPane(Settings.Pane.account)
        expectInspector(replacing: "Account")
        XCTAssertFalse(element(Area.accountEmail).exists, "the Account pane (and its Sign out) is still open")
        try openPane(Settings.Pane.uninstall)
        expectInspector(replacing: "Uninstall")
    }

    /// Browser access is what managed website blocking runs on, so its pane stays open to restore it.
    func testPermissionsPaneStaysOpenToRestoreBrowserAccess() throws {
        try launchIntoSettings(managedBy: .schoolActive)
        try openPane(Settings.Pane.permissions)
        XCTAssertTrue(appears(element(Area.permissionsTable)), "the browser permissions can't be restored")
        XCTAssertFalse(inspector.exists, "the Permissions pane is locked away with the others")
    }

    func testSwitchingGeekModeIsRefused() throws {
        try launchIntoSettings(managedBy: .schoolActive)
        let segments = modeSegments
        guard segments.count >= 2 else { return XCTFail("the Geek / Simple switch has no segments") }
        let wasGeek = isInGeekMode
        tap(wasGeek ? segments[1] : segments[0])
        let close = element(Safety.settingsLockedAlertCloseButton)
        XCTAssertTrue(appears(close), "switching mode didn't say that settings are locked")
        attachScreenshot(named: "settings locked alert")
        tap(close)
        XCTAssertTrue(waitForNonExistence(of: close), "the settings-locked alert didn't close")
        waitUntil { self.isInGeekMode == wasGeek }
        XCTAssertEqual(isInGeekMode, wasGeek, "the refused switch still shows the other mode")
    }

    // MARK: - School hours: blocking

    /// The user's own ask: a blocking schedule can't be edited. The whole Blocks screen — block lists,
    /// schedules, the tab limiter and always-allowed apps — gives way to the school's policy.
    func testBlocksScreenShowsThePolicyInsteadOfTheEditors() throws {
        try launchManaged(.schoolActive)
        openBlocks()
        for (identifier, editor) in [(Blocking.blockListsRow, "block lists"), (Blocking.blockingSchedulesRow, "blocking schedules"),
                                     (Area.scheduleAddButton, "new blocking schedule"), (Area.blockListCreateButton, "new block list"),
                                     (Area.tabLimiterRow, "tab limiter"), (Area.alwaysAllowedAppsRow, "always-allowed apps")] {
            XCTAssertFalse(element(identifier).exists, "a managed student can still open the \(editor) editor")
        }
        attachScreenshot(named: "blocks while managed")
    }

    func testSchoolPolicyIsActiveAndSaysToAskTheSchool() throws {
        try launchManaged(.schoolActive)
        openBlocks()
        XCTAssertTrue(element(Safety.statusActive).exists, "the policy doesn't say a window is active now")
        let school = element(Safety.card(kind: Policies.schoolKind))
        XCTAssertTrue(appears(school), "the school's policy isn't shown")
        XCTAssertTrue(child(Safety.cardState(kind: Policies.schoolKind, .active), of: school).exists, "the school policy isn't marked active")
        XCTAssertTrue(child(Safety.schoolContactNote, of: school).exists, "the school policy doesn't say to contact the school")
        XCTAssertFalse(child(Safety.requestHomeChangesButton, of: school).exists, "the school policy offers a parent's approval instead")
        let home = element(Safety.card(kind: Policies.homeKind))
        XCTAssertTrue(child(Safety.cardState(kind: Policies.homeKind, .scheduled), of: home).exists,
                      "the home policy isn't waiting for school hours to end")
    }

    /// A personal session may add restrictions on top of the school's, so Focus Start stays open and says
    /// what the school blocks. No session is started.
    func testFocusStartShowsWhatTheSchoolBlocks() throws {
        try launchManaged(.schoolActive)
        addTeardownBlock { [weak self] in self?.finishAnyFocusSession() }
        openFocusStartEndingAnyRunningSession()
        let goalCard = element(FocusStart.goalCard)
        if !goalCard.exists { tap(element(FocusStart.modeLink)) }
        XCTAssertTrue(appears(goalCard), "the advanced start screen didn't open")
        let summary = element(Safety.focusStartSummary)
        if !summary.exists { tap(element(Sessions.blockingCard)) }
        XCTAssertTrue(appears(summary), "Focus Start doesn't say what the school blocks")
        XCTAssertTrue(element(FocusStart.startButton).isEnabled, "a personal session can't be started on top of the school's policy")
        attachScreenshot(named: "focus start while managed")
    }

    // MARK: - School hours: the menu-bar popover and quitting

    func testMenuBarPopoverSaysTheMacIsManaged() throws {
        try present(.menuBarPopover, landmark: MenuBar.quitButton, environment: Self.environment(for: .schoolActive))
        attachScreenshot(named: "popover while managed")
        XCTAssertTrue(element(Safety.menuBarStatus).exists, "the popover doesn't say a school manages this Mac")

        press(.escape)
    }

    /// ⌘Q and the Dock are refused while managed (`applicationShouldTerminate`); the popover's Quit must
    /// be too. The quit popup, if it opens, is closed — never used.
    func testQuitFromThePopoverIsRefused() throws {
        let quit = try present(.menuBarPopover, landmark: MenuBar.quitButton, environment: Self.environment(for: .schoolActive))
        tap(quit)
        let refusal = element(Safety.settingsLockedAlertCloseButton)
        let popup = element(Area.quitPopup)
        let shown = firstToAppear([refusal, popup])
        // Read now: whichever it was is closed below, and a closed element has no identifier to read.
        let shownIdentifier = shown?.identifier
        attachScreenshot(named: "quit while managed")
        if shown == popup {
            tap(window(containing: Area.quitPopup).buttons[XCUIIdentifierCloseWindow])
            XCTAssertTrue(waitForNonExistence(of: popup), "the quit popup didn't close")
        } else if shown == refusal {
            tap(refusal)
        }
        XCTAssertNotEqual(app.state, .notRunning, "the managed app quit")
        XCTAssertEqual(shownIdentifier, Safety.settingsLockedAlertCloseButton,
                       "Quit offered the quit popup instead of saying that settings are locked")
    }

    /// Offline, the Mac keeps enforcing the last policy it synced, so closing the "you're offline" pop-up
    /// must not quit: it says settings are locked and the pop-up stays, with "I'm online now" to retry.
    /// WARNING: on a build without #2700 the close really quits the test app.
    func testClosingTheOfflinePopupWhileManagedDoesNotQuit() throws {
        let popup = try present(.offlinePopup, landmark: Safety.offlinePopup, environment: Self.environment(for: .offlineLastKnown))
        attachScreenshot(named: "offline pop-up while managed")
        tap(window(containing: Safety.offlinePopup).buttons[XCUIIdentifierCloseWindow])
        let refusal = element(Safety.settingsLockedAlertCloseButton)
        XCTAssertTrue(appears(refusal), "closing the offline pop-up didn't say that settings are locked")

        if refusal.exists { tap(refusal) }
        XCTAssertNotEqual(app.state, .notRunning, "closing the offline pop-up quit the managed app")
        XCTAssertTrue(popup.exists, "the offline pop-up closed, leaving no way to retry the connection")
    }

    // MARK: - VoiceOver

    /// The lock is said, not only shown by missing controls.
    func testLockedSettingsAreAnnouncedToVoiceOver() throws {
        try launchIntoSettings(managedBy: .schoolActive)
        try openPane(Settings.Pane.ui)
        expectInspector(replacing: "Appearance")
        let locked = element(Safety.statusSettingsLocked)
        XCTAssertTrue(appears(locked), "the pane doesn't say that settings are locked")
        XCTAssertFalse(spokenText(of: locked).isEmpty, "VoiceOver reads nothing for the settings lock")
        try checkVoiceOver(on: AccessibilityScreen(name: "Settings: locked by the school"), in: inspector)
    }

    // MARK: - Outside school hours

    func testParentPolicyIsActiveAndChangesGoToAParent() throws {
        try launchManaged(.parentActive)
        openBlocks()
        let home = element(Safety.card(kind: Policies.homeKind))
        XCTAssertTrue(appears(home), "the parent's policy isn't shown")
        XCTAssertTrue(child(Safety.cardState(kind: Policies.homeKind, .active), of: home).exists, "the home policy isn't marked active")
        XCTAssertTrue(child(Safety.requestHomeChangesButton, of: home).exists, "the home policy doesn't offer to ask a parent")
        XCTAssertFalse(child(Safety.schoolContactNote, of: home).exists, "the home policy says to ask the school")
        let school = element(Safety.card(kind: Policies.schoolKind))
        XCTAssertTrue(child(Safety.cardState(kind: Policies.schoolKind, .scheduled), of: school).exists,
                      "the school policy isn't waiting for school hours")
        XCTAssertTrue(element(Safety.statusSettingsLocked).exists, "settings aren't locked outside school hours")
    }

    /// Nothing in the home schedule can be changed until a parent approves; the request is never sent.
    func testHomeScheduleEditorIsReadOnlyUntilAParentApproves() throws {
        try launchManaged(.parentActive)
        openBlocks()
        tap(element(Safety.requestHomeChangesButton))
        let editor = element(Safety.homeEditor)
        XCTAssertTrue(appears(editor), "asking for changes didn't open the home schedule")
        XCTAssertFalse(element(Safety.homeEditorNameField).isEnabled, "the home schedule can be edited without a parent's approval")
        XCTAssertFalse(element(Safety.homeEditorSubmitButton).isEnabled, "changes can be sent without a parent's approval")
        XCTAssertTrue(element(Safety.homeEditorRequestApprovalButton).exists, "the editor doesn't offer to ask a parent")
        attachScreenshot(named: "home schedule awaiting approval")
        tap(element(Safety.homeEditorCloseButton))
        XCTAssertTrue(waitForNonExistence(of: editor), "Close didn't close the home schedule")
    }

    /// Outside every window nothing is enforced, but the student is still enrolled, so settings stay locked.
    func testOutsideSchoolHoursNothingIsActiveButSettingsStayLocked() throws {
        try launchIntoSettings(managedBy: .schoolInactive)
        try openPane(Settings.Pane.ui)
        expectInspector(replacing: "Appearance")
        XCTAssertTrue(element(Safety.statusNoActiveWindow).exists, "the policy doesn't say no window is active now")
        XCTAssertTrue(element(Safety.statusSettingsLocked).exists, "the pane doesn't say that settings are locked")
        let school = element(Safety.card(kind: Policies.schoolKind))
        XCTAssertTrue(child(Safety.cardState(kind: Policies.schoolKind, .scheduled), of: school).exists,
                      "the school policy isn't waiting for its next window")
        XCTAssertFalse(element(Settings.darkModePopup).exists, "personal settings unlocked outside school hours")
    }

    // MARK: - Offline

    func testOfflineTheLastKnownPolicyStillApplies() throws {
        try launchManaged(.offlineLastKnown)
        openBlocks()
        XCTAssertTrue(element(Safety.statusOffline).exists, "the policy doesn't say it is offline")
        XCTAssertTrue(element(Safety.statusActive).exists, "offline, the saved school window no longer applies")
        let school = element(Safety.card(kind: Policies.schoolKind))
        XCTAssertTrue(child(Safety.cardState(kind: Policies.schoolKind, .active), of: school).exists, "the saved school policy isn't active")
        XCTAssertTrue(element(Safety.statusSettingsLocked).exists, "offline, settings unlocked")
        XCTAssertFalse(element(Blocking.blockingSchedulesRow).exists, "offline, the blocking schedules can be edited")
    }

    // MARK: - A teacher's class session

    func testClassSessionCannotBeEndedEarly() throws {
        try launchInClassSession()
        let end = element(FocusSession.endButton)
        tap(end)
        expectTeacherLockThenDismissIt(after: "End")
        XCTAssertTrue(end.exists, "the class session ended")
        if element(Sessions.reduceButton).exists {
            XCTAssertFalse(element(Sessions.reduceButton).isEnabled, "the class session can be shortened")
        }
    }

    func testClassSessionCannotBePaused() throws {
        try launchInClassSession()
        let pause = element(Sessions.pauseButton)
        XCTAssertTrue(appears(pause), "the running class session has no Pause to try")
        tap(pause)
        expectTeacherLockThenDismissIt(after: "Pause")
        XCTAssertFalse(element(Sessions.resumeButton).exists, "the class session paused")
    }

    func testQuitDuringAClassSessionShowsTheTeacherLock() throws {
        let quit = try present(.menuBarPopover, landmark: MenuBar.quitButton,
                               environment: [Environment.teacherSession: Environment.teacherSessionActive])
        try requireClassSession()
        // The countdown is started once the popover's view has loaded (the class session began at launch).
        let focusRow = element(MenuBar.focusSection)
        XCTAssertTrue(appears(focusRow), "the popover doesn't show the running class session")
        XCTAssertTrue(waitUntil(NSPredicate(format: "label MATCHES %@", Self.countdownPattern), isTrueOf: focusRow,
                                within: Self.screenTimeout),
                      "the popover shows no time left in the class session (it reads “\(focusRow.label)”)")
        tap(quit)
        let popup = element(Area.quitPopup)
        let lock = element(Teacher.lockedAlert)
        let shown = firstToAppear([lock, popup])
        let shownIdentifier = shown?.identifier   // before the pop-up, if it was that, is closed
        if shown == popup { tap(window(containing: Area.quitPopup).buttons[XCUIIdentifierCloseWindow]) }
        XCTAssertEqual(shownIdentifier, Teacher.lockedAlert, "Quit during a class session didn't show the teacher's lock")
        if shown == lock { dismissTeacherLock() }
        XCTAssertNotEqual(app.state, .notRunning, "the app quit during a class session")
    }

    /// The way out of a locked class session is asking the teacher; the request needs a reason, and is
    /// never sent.
    func testUnlockRequestAsksTheTeacherAndNeedsAReason() throws {
        try launchInClassSession()
        let send = openUnlockRequest()
        XCTAssertFalse(send.isEnabled, "an empty unlock request can be sent")
        tap(element(Teacher.unlockRequestAppOrUrlField))
        typeIntoFocus(Self.unlockAppOrUrl)
        XCTAssertFalse(send.isEnabled, "an unlock request without a reason can be sent")
        tap(element(Teacher.unlockRequestReasonField))
        typeIntoFocus(Self.unlockReason)
        XCTAssertTrue(waitForEnabled(send), "a complete unlock request can't be sent")
        attachScreenshot(named: "unlock request")
        tap(element(Teacher.unlockRequestCancelButton))
        XCTAssertTrue(waitForNonExistence(of: send), "Cancel didn't close the unlock request")
    }

    func testUnlockRequestIsAnnouncedToVoiceOver() throws {
        try launchInClassSession()
        let send = openUnlockRequest()
        try checkVoiceOver(on: AccessibilityScreen(name: "Teacher unlock request"), in: window(containing: Teacher.unlockRequestSendButton))
        tap(element(Teacher.unlockRequestCancelButton))
        XCTAssertTrue(waitForNonExistence(of: send), "Cancel didn't close the unlock request")
    }

    // MARK: - Steps

    private static func environment(for scenario: Scenario) -> [String: String] {
        [Environment.managedPolicy: scenario.rawValue]
    }

    private func launchManaged(_ scenario: Scenario) throws {
        try launchSignedIn(environment: Self.environment(for: scenario))
    }

    private func launchIntoSettings(managedBy scenario: Scenario) throws {
        try launchManaged(scenario)
        openSettings()
    }

    /// The Blocks screen, which for a managed student is the safety policy.
    private func openBlocks() {
        open(menuItem: Menu.blocks, expectingAnyOf: inspector)
    }

    private var inspector: XCUIElement { element(Safety.inspector) }

    private func expectInspector(replacing screen: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(appears(inspector), "\(screen) isn't replaced by the safety policy for a managed student", file: file, line: line)
    }

    private func child(_ identifier: String, of parent: XCUIElement) -> XCUIElement {
        parent.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// An AppKit label carries its text as its label, SwiftUI's Text as its value.
    private func spokenText(of element: XCUIElement) -> String {
        [element.label, element.value as? String ?? ""].joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Geek, then Simple (`GeekModeSegmentedControl`).
    private var modeSegments: [XCUIElement] {
        let control = element(Area.geekModeControl)
        return (control.radioButtons.allElementsBoundByIndex + control.buttons.allElementsBoundByIndex)
            .filter(\.exists).sorted { $0.frame.minX < $1.frame.minX }
    }

    /// Signed in with a class session running (`UITestManagedSafetyFixture`), on its running-session screen.
    private func launchInClassSession() throws {
        try launchSignedIn(environment: [Environment.teacherSession: Environment.teacherSessionActive])
        try requireClassSession()
    }

    /// The class session joins once settings load, and waits while a routine or a personal session runs.
    private func requireClassSession() throws {
        guard appears(element(FocusSession.endButton), within: Self.firstLaunchTimeout, waitsOnNetwork: true) else {
            recordDiagnostics(named: "no class session")
            throw XCTSkip("The class session didn't start: a routine or a focus session is running for the test account.")
        }
    }

    private func expectTeacherLockThenDismissIt(after action: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(appears(element(Teacher.lockedAlert)), "\(action) didn't show the teacher's lock", file: file, line: line)
        attachScreenshot(named: "teacher lock after \(action)")
        dismissTeacherLock(file: file, line: line)
    }

    /// Its Cancel button ("OK") closes it; its OK button asks the teacher for an unlock.
    private func dismissTeacherLock(file: StaticString = #filePath, line: UInt = #line) {
        let lock = element(Teacher.lockedAlert)
        tap(child(CustomAlert.cancelButton, of: lock), file: file, line: line)
        XCTAssertTrue(waitForNonExistence(of: lock), "the teacher's lock didn't close", file: file, line: line)
    }

    /// End, the teacher's lock, then Request unlock. Returns the request's Send button.
    private func openUnlockRequest() -> XCUIElement {
        tap(element(FocusSession.endButton))
        let lock = element(Teacher.lockedAlert)
        XCTAssertTrue(appears(lock), "End didn't show the teacher's lock")
        tap(child(CustomAlert.okButton, of: lock))
        let send = element(Teacher.unlockRequestSendButton)
        XCTAssertTrue(appears(send), "Request unlock didn't open the unlock request")
        return send
    }
}
