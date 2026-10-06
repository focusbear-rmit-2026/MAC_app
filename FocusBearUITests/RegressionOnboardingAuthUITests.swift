//
//  RegressionOnboardingAuthUITests.swift
//  Focus BearUITests
//
//  Regression suite: Onboarding and sign-in. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Most of this needs no account: the welcome steps before sign-up, and the email + password form,
//  whose checks all stop short of creating one. The distraction-blocking steps only a brand-new
//  account sees are walked in one test, with the run's single extra account.
//

import AppKit
import XCTest

final class RegressionOnboardingAuthUITests: FocusBearUITestCase {
    private typealias Onboarding = UITestContract.Identifier.Onboarding
    private typealias Regression = UITestContract.Identifier.OnboardingRegression
    private typealias Login = UITestContract.Identifier.Login
    private typealias Settings = UITestContract.Identifier.Settings

    /// The steps `OnboardingStep` doesn't name, as the app names them (`onboardingVc.ONBOARDINGSTATE`).
    private enum Step {
        static let login = "_LOGIN_"
        static let enableAiBlocking = "_ENABLE_AI_BLOCKING_"
        static let askSetDistractions = "_ASK_SET_DISTRACTIONS_"
        static let askOccupation = "_ASK_OCCUPATION_"
        static let blockedUrls = "_BLOCKED_URLS_"
        static let blockedApps = "_BLOCKED_APPS_"
        static let allowedUrls = "_ALLOWED_URLS_"
        static let chooseSchedulePreset = "_CHOOSE_BLOCKING_SCHEDULE_PRESET_"
        static let createSchedule = "_CREATE_BLOCKING_SCHEDULE_"
        static let askPermissions = "_ASK_PERMISSIONS_"
        static let systemEventsPermission = "_SYSTEM_EVENT_PERMISSION_"
    }

    /// The step indicator's VoiceOver name and value (English run), as AccountSignUpUITests reads them.
    private static let progressName = "Onboarding progress"
    private static let progressValuePrefix = "Step "
    /// Blocked sites (step 1), the schedule question (step 2), permissions (step 3).
    private static let expectedAnnouncedSteps: [Int?] = [1, 2, 3]
    /// The Employee tile: the student tile opens a tooltip popover that would swallow the next click.
    private static let employeeOccupationIndex = 2
    /// IANA-reserved, so an added site can never be a real one.
    private static let reservedTopLevelDomain = "example"
    private static let malformedEmail = "not-an-email"
    /// Breaks the length rule and three of the four character-class rules.
    private static let passwordBreakingTheRules = "short"
    /// From confirming the logout to the reopened copy running: quitting, the app's own `sleep 1`,
    /// then `open`. Measured ≈ 1 s on the developer's Mac; the rest is headroom for a loaded CI Mac.
    private static let relaunchTimeout: TimeInterval = 10

    private var announcedSteps = [Int?]()

    // MARK: - Welcome steps (no account)

    func testBackWalksBackThroughEveryWelcomeStep() {
        launchFreshInstall()
        XCTAssertFalse(element(Onboarding.backButton).exists, "the first step offers Back")
        walkToCreateAccount()
        let back = element(Onboarding.backButton)
        for step in [OnboardingStep.privacy, OnboardingStep.setUpAccount, OnboardingStep.letsDoIt,
                     OnboardingStep.welcomeAdhd, OnboardingStep.welcome] {
            tap(back)
            expectOnboardingStep(step)
        }
        XCTAssertTrue(waitForNonExistence(of: back), "Back is still offered on the first step")
    }

    func testNeverHadAnIssueGoesStraightToTheAccountStep() {
        launchFreshInstall()
        advanceOnboarding(with: Onboarding.welcomeContinueButton, to: OnboardingStep.welcomeAdhd)
        advanceOnboarding(with: Regression.welcomeAdhdNeverHadIssueButton, to: OnboardingStep.setUpAccount)
        XCTAssertTrue(element(Onboarding.signUpButton).exists, "the account step doesn't offer sign-up")
        // Offered, never pressed: it creates a real guest account.
        XCTAssertTrue(element(Regression.stayAnonymousButton).exists, "the account step doesn't offer staying anonymous")
        tap(element(Onboarding.backButton))
        expectOnboardingStep(OnboardingStep.welcomeAdhd)
    }

    func testPrivacyStepNeedsTheTermsAcceptedToContinue() {
        launchFreshInstall()
        walkToAccountStep()
        advanceOnboarding(with: Onboarding.signUpButton, to: OnboardingStep.privacy)
        let terms = app.checkBoxes[Onboarding.termsCheckBox]
        let proceed = element(Onboarding.privacyContinueButton)
        XCTAssertTrue(appears(terms), "the terms checkbox is missing")
        XCTAssertFalse(isChecked(terms), "the terms start out accepted")
        XCTAssertFalse(proceed.isEnabled, "Continue works before the terms are accepted")
        // Offered, never opened: both go to the website in the browser.
        XCTAssertTrue(element(Regression.privacyPolicyLink).exists, "no link to the privacy policy")
        XCTAssertTrue(element(Regression.termsLink).exists, "no link to the licence agreement")

        tap(terms)
        XCTAssertTrue(waitUntil(proceed, isEnabled: true), "accepting the terms doesn't enable Continue")
        tap(terms)
        XCTAssertTrue(waitUntil(proceed, isEnabled: false), "withdrawing acceptance leaves Continue enabled")
        tap(terms)
        advanceOnboarding(with: Onboarding.privacyContinueButton, to: OnboardingStep.createAccount)
    }

    func testAccountCreationOffersEveryWayIn() {
        launchFreshInstall()
        walkToCreateAccount()
        // Google and Apple are offered, never pressed: both hand off to a browser sign-in.
        for identifier in [Login.signUpWithEmailButton, Regression.signUpWithGoogleButton,
                           Regression.signUpWithAppleButton, Login.goToSignInButton] {
            XCTAssertTrue(element(identifier).exists, "\(identifier) is missing")
        }
        // "Already have an account? Sign in"
        advanceOnboarding(with: Login.goToSignInButton, to: Step.login)
        expectSignInForm()
        tap(element(Onboarding.backButton))
        expectOnboardingStep(OnboardingStep.createAccount)
    }

    func testWelcomeAlreadyHaveAnAccountOpensSignIn() {
        launchFreshInstall()
        advanceOnboarding(with: Regression.welcomeAlreadyHaveAccountButton, to: Step.login)
        expectSignInForm()
        tap(element(Onboarding.backButton))
        expectOnboardingStep(OnboardingStep.welcome)
    }

    func testSignUpAndSignInFormsSwitchBothWays() {
        launchFreshInstall()
        walkToCreateAccount()
        advanceOnboarding(with: Login.signUpWithEmailButton, to: Step.login)
        expectSignUpForm()
        tap(element(Regression.switchToSignInButton))
        expectSignInForm()
        tap(element(Regression.switchToSignUpButton))
        expectSignUpForm()
    }

    // MARK: - The email + password form (no account is created)

    func testCreateAccountWaitsForAPasswordThatMeetsTheRules() {
        launchLoggedOut()
        let signUpWithEmail = element(Login.signUpWithEmailButton)
        XCTAssertTrue(appears(signUpWithEmail, within: Self.firstLaunchTimeout, waitsOnNetwork: true), "a logged-out launch offers no sign-up")
        tap(signUpWithEmail)
        expectSignUpForm()
        let create = element(Login.createAccountButton)
        let password = app.secureTextFields[Login.passwordField]

        enter(Self.passwordBreakingTheRules, into: password)
        XCTAssertFalse(create.isEnabled, "a password breaking the rules can be submitted")
        replaceText(of: password, with: Self.passwordMeetingTheRules())
        // Never pressed: it would create an account.
        XCTAssertTrue(waitUntil(create, isEnabled: true), "a password meeting the rules can't be submitted")
    }

    func testSignInWithEmptyFieldsIsRejected() {
        openSignInForm()
        tap(element(Login.signInButton))
        XCTAssertTrue(dismissFormAlert(), "signing in without an email says nothing")
        enter(Self.unknownEmail(), into: app.textFields[Login.emailField])
        tap(element(Login.signInButton))
        XCTAssertTrue(dismissFormAlert(), "signing in without a password says nothing")
        expectSignInForm()
    }

    func testSignInRejectsAMalformedEmail() {
        openSignInForm()
        enter(Self.malformedEmail, into: app.textFields[Login.emailField])
        enter(Self.passwordMeetingTheRules(), into: app.secureTextFields[Login.passwordField])
        tap(element(Login.signInButton))
        XCTAssertTrue(dismissFormAlert(), "a malformed email is sent to sign in")
        expectSignInForm()
    }

    /// The run's own account with a password it doesn't have. One failure per run: every signed-in
    /// test after it signs in successfully, which resets Auth0's failed-attempt count.
    func testSignInWithAWrongPasswordShowsAnError() throws {
        let account = try requireTestAccount()
        openSignInForm()
        enter(account.email, into: app.textFields[Login.emailField])
        enter(Self.passwordMeetingTheRules(), into: app.secureTextFields[Login.passwordField])
        tap(element(Login.signInButton))
        XCTAssertTrue(dismissFormAlert(within: Self.signInTimeout), "a wrong password raises no error")
        expectSignInForm()
    }

    func testShowPasswordRevealsAndHidesThePassword() {
        openSignInForm()
        let secure = app.secureTextFields[Login.passwordField]
        let plain = app.textFields[Regression.plainPasswordField]
        let show = element(Regression.showPasswordButton)
        let typed = Self.passwordMeetingTheRules()
        enter(typed, into: secure)
        XCTAssertFalse(plain.exists, "the password starts out readable")

        tap(show)
        XCTAssertTrue(appears(plain), "Show password doesn't reveal it")
        XCTAssertEqual(plain.value as? String, typed, "the revealed password isn't the one typed")
        XCTAssertFalse(secure.exists, "the hidden field is still shown beside the revealed one")

        tap(show)
        XCTAssertTrue(appears(secure), "the password can't be hidden again")
        XCTAssertTrue(waitForNonExistence(of: plain), "the password stays readable after hiding it")
    }

    /// Forgot Password sends a reset email to the address in the field, so it is only ever pressed
    /// with the field empty.
    func testForgotPasswordAsksForTheEmailFirst() {
        openSignInForm()
        tap(element(Regression.forgotPasswordButton))
        XCTAssertTrue(dismissFormAlert(), "Forgot Password without an email says nothing")
        expectSignInForm()
    }

    func testSignInFormBackReturnsToTheAccountChoices() {
        openSignInForm()
        tap(element(Regression.formBackButton))
        XCTAssertTrue(appears(element(Login.goToSignInButton)), "Back doesn't return to the sign-in choices")
        XCTAssertTrue(element(Login.signUpWithEmailButton).exists, "the sign-in choices offer no sign-up")
        XCTAssertTrue(waitForNonExistence(of: app.textFields[Login.emailField]), "the form is still up")
    }

    /// Logging out quits the app and reopens it a second later (`AppDelegate.logout` →
    /// `quitAndRestartApp`, `sleep 1; open <its own bundle>`), outside XCUITest's launch. `app` goes
    /// on to address the new process: XCUITest finds the application by bundle id.
    ///
    /// The reopened copy gets none of this launch's arguments but all of its environment, so this test
    /// signs in through the form rather than with `launchSignedIn`: a copy started with the sign-in
    /// variables signs itself straight back in on relaunch and never shows sign-in (2026-09-27 run:
    /// credentials were back 3 s after logging out, and with no `--uiTestSkipOnboarding` no window came up).
    func testSignOutThenSignBackIn() throws {
        let account = try requireTestAccount()
        try launchSignedInThroughTheForm(as: account)
        addTeardownBlock { Self.quitTheRelaunchedTestApp() }
        open(menuItem: UITestContract.Identifier.Menu.settings, expectingAnyOf: element(Settings.appearanceTab))
        let accountPane = element(Settings.tabPrefix + Settings.Pane.account)
        XCTAssertTrue(appears(accountPane), "Settings has no Account pane")
        tapSettingsTab(Settings.Pane.account)
        let logout = element(Regression.logoutButton)
        XCTAssertTrue(appears(logout), "the Account pane offers no way to log out")

        tap(logout)
        declineConfirmation()
        XCTAssertTrue(logout.exists, "saying no to logging out still logged out")

        let launchedCopies = Self.runningTestAppProcesses()
        tap(logout)
        confirmDestructiveAlert()
        XCTAssertTrue(waitForRelaunch(replacing: launchedCopies), "logging out didn't quit and reopen the app")
        // The reopened copy remembers the email (#1308) and opens the form with it filled in.
        showSignInForm(failure: "logging out doesn't come back to sign-in")
        signIn(as: account)
        XCTAssertTrue(waitForNonExistence(of: app.textFields[Login.emailField], timeout: Self.signInTimeout),
                      "signing back in leaves the form up")
        XCTAssertFalse(element(Regression.formAlert).exists, "signing back in raised an error")
        attachScreenshot(named: "signed back in")
    }

    // MARK: - Distraction blocking steps (the run's one extra account)

    /// The steps only a brand-new account sees: the skip path's first hop and back, AI opt-in,
    /// occupation, blocked sites and apps, allowed sites, the schedule presets, and the permissions
    /// steps (never granting), with the step indicator counting 1, 2, 3 on the way. It creates the one
    /// extra account a regression run makes — a new account is the only way onto these steps — and
    /// leaves it mid-onboarding: nothing is blocked or scheduled on it.
    func testDistractionBlockingSetupWalksEveryStep() {
        signUpAnExtraAccount()
        skipBlockingAndComeBack()
        declineAiAndChooseAnOccupation()
        addAndUntickABlockedSite()
        removeABlockedApp()
        addAndUntickAnAllowedSite()
        pickASchedulePresetAndComeBack()
        visitPermissionsWithoutGranting()
        checkTheStepIndicatorCounted()
    }

    private func signUpAnExtraAccount() {
        launchFreshInstall()
        walkToCreateAccount()
        advanceOnboarding(with: Login.signUpWithEmailButton, to: Step.login)
        // An internaltest+macuitest… address. Deliberately not saved: the run's account stays the one
        // AccountSignUpUITests made.
        let account = TestAccountStore.makeNew()
        enter(account.email, into: app.textFields[Login.emailField])
        enterSecret(account.password, into: app.secureTextFields[Login.passwordField])
        let confirm = app.secureTextFields[Login.confirmPasswordField]
        if confirm.exists, confirm.isHittable { enterSecret(account.password, into: confirm) }
        tap(element(Login.createAccountButton))
        expectOnboardingStep(OnboardingStep.setDistractionBlocking, timeout: Self.signInTimeout + Self.firstLaunchTimeout)
    }

    private func skipBlockingAndComeBack() {
        let back = element(Onboarding.backButton)
        XCTAssertFalse(back.exists, "the first step after sign-up offers Back into the account steps")
        advanceOnboarding(with: Onboarding.skipDistractionBlockingButton, to: OnboardingStep.askCreateBlockingSchedule)
        tap(back)
        expectOnboardingStep(OnboardingStep.setDistractionBlocking)
    }

    private func declineAiAndChooseAnOccupation() {
        advanceOnboarding(with: Regression.setUpDistractionBlockingButton, to: Step.enableAiBlocking)
        XCTAssertTrue(element(Regression.enableAiBlockingButton).exists, "the AI step doesn't offer AI blocking")
        advanceOnboarding(with: Regression.declineAiBlockingButton, to: Step.askSetDistractions)
        XCTAssertTrue(element(Regression.pickDistractionsMyselfButton).exists, "no way to pick distractions yourself")
        advanceOnboarding(with: Regression.helpPickDistractionsButton, to: Step.askOccupation)

        let proceed = element(Regression.occupationContinueButton)
        XCTAssertFalse(proceed.isEnabled, "Continue works before an occupation is chosen")
        XCTAssertTrue(element(Regression.occupationSkipButton).exists, "the occupation step can't be skipped")
        tap(element(Regression.occupationOptionPrefix + "\(Self.employeeOccupationIndex)"))
        XCTAssertTrue(waitUntil(proceed, isEnabled: true), "choosing an occupation doesn't enable Continue")
        XCTAssertTrue(appears(app.textFields[Regression.occupationDetailField]), "the occupation step asks for no detail")
        tap(proceed)
        // Continue first asks the API for sites suited to the occupation.
        expectOnboardingStep(Step.blockedUrls, timeout: Self.apiRoundTripTimeout)
    }

    private func addAndUntickABlockedSite() {
        noteAnnouncedStep()
        let count = element(Regression.blockedUrlsCount)
        let countBefore = shownText(of: count)
        let site = Self.uniqueSite()
        enter(site, into: app.textFields[Regression.blockedUrlField])
        tap(element(Regression.blockedUrlAddButton))
        let checkbox = element(Regression.blockedUrlCheckboxPrefix + site)
        XCTAssertTrue(appears(checkbox), "the added site isn't listed")
        XCTAssertTrue(isChecked(checkbox), "the added site isn't ticked for blocking")
        XCTAssertNotEqual(shownText(of: count), countBefore, "the count leaves out the added site")
        tap(checkbox)
        XCTAssertFalse(isChecked(checkbox), "the site can't be unticked")
        XCTAssertEqual(shownText(of: count), countBefore, "the count still includes the unticked site")
        advanceOnboarding(with: Regression.blockedUrlsProceedButton, to: Step.blockedApps)
    }

    private func removeABlockedApp() {
        let table = element(Regression.blockedAppsTable)
        XCTAssertTrue(appears(table), "the blocked apps list is missing")
        // Chess, Stocks, TV and News are suggested whenever the Mac has them, which macOS always does.
        let rows = table.tableRows
        XCTAssertGreaterThan(rows.count, 0, "no apps are suggested for blocking")
        let rowsBefore = rows.count
        let count = element(Regression.blockedAppsCount)
        let countBefore = shownText(of: count)
        tap(rows.element(boundBy: 0))
        tap(element(Regression.blockedAppsRemoveButton))
        XCTAssertEqual(rows.count, rowsBefore - 1, "Remove didn't take the selected app off the list")
        XCTAssertNotEqual(shownText(of: count), countBefore, "the count still includes the removed app")

        // Add opens the system's app chooser; it is cancelled, so nothing is added.
        tap(element(Regression.blockedAppsAddButton))
        let chooser = firstToAppear([app.sheets.firstMatch, app.dialogs.firstMatch])
        XCTAssertNotNil(chooser, "Add doesn't open the app chooser")
        press(.escape)
        if let chooser { XCTAssertTrue(waitForNonExistence(of: chooser), "the app chooser can't be cancelled") }
        XCTAssertEqual(rows.count, rowsBefore - 1, "cancelling the app chooser changed the list")
        advanceOnboarding(with: Regression.blockedAppsProceedButton, to: Step.allowedUrls)
    }

    private func addAndUntickAnAllowedSite() {
        let site = Self.uniqueSite()
        enter(site, into: app.textFields[Regression.allowedUrlField])
        tap(element(Regression.allowedUrlAddButton))
        let checkbox = element(Regression.allowedUrlCheckboxPrefix + site)
        XCTAssertTrue(appears(checkbox), "the added work site isn't listed")
        XCTAssertTrue(isChecked(checkbox), "the added work site isn't ticked")
        tap(checkbox)
        XCTAssertFalse(isChecked(checkbox), "the work site can't be unticked")
        XCTAssertTrue(element(Regression.allowedUrlsContinueButton).exists, "the work sites step has no way on")
        advanceOnboarding(with: Regression.allowedUrlsSkipButton, to: OnboardingStep.askCreateBlockingSchedule)
    }

    private func pickASchedulePresetAndComeBack() {
        noteAnnouncedStep()
        advanceOnboarding(with: Regression.createBlockingScheduleButton, to: Step.chooseSchedulePreset)
        let presets = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", Regression.schedulePresetPrefix))
        XCTAssertTrue(appears(presets.firstMatch), "no quick-start presets are offered")
        XCTAssertGreaterThan(presets.count, 1, "only one preset is offered")
        tap(presets.firstMatch)
        expectOnboardingStep(Step.createSchedule)

        // Nothing is saved: Back all the way, then no schedule.
        let back = element(Onboarding.backButton)
        tap(back)
        expectOnboardingStep(Step.chooseSchedulePreset)
        tap(back)
        expectOnboardingStep(OnboardingStep.askCreateBlockingSchedule)
        // Sites were chosen for blocking, so skipping the schedule leads on to permissions.
        advanceOnboarding(with: Onboarding.skipBlockingScheduleButton, to: Step.askPermissions)
    }

    /// Only the first permission step is reachable without granting: its "can't grant" way on shows
    /// only after macOS has refused. Its button is checked, never pressed — it raises the Automation prompt.
    private func visitPermissionsWithoutGranting() {
        noteAnnouncedStep()
        advanceOnboarding(with: Regression.askPermissionsGrantButton, to: Step.systemEventsPermission)
        let openSettings = element(Regression.systemEventsOpenSettingsButton)
        XCTAssertTrue(openSettings.exists, "the System Events step has no button to grant it")
        XCTAssertTrue(openSettings.isEnabled, "the System Events grant button is disabled")
        tap(element(Onboarding.backButton))
        expectOnboardingStep(Step.askPermissions)
        advanceOnboarding(with: Regression.askPermissionsSkipButton, to: OnboardingStep.holdOn)
        XCTAssertFalse(element(Onboarding.backButton).exists, "the habits section offers Back into blocking")
    }

    private func noteAnnouncedStep() {
        let progress = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", Self.progressName)).firstMatch
        guard progress.exists, let value = progress.value as? String, value.hasPrefix(Self.progressValuePrefix) else {
            announcedSteps.append(nil)
            return
        }
        announcedSteps.append(Int(value.dropFirst(Self.progressValuePrefix.count).prefix { $0.isNumber }))
    }

    private func checkTheStepIndicatorCounted() {
        guard announcedSteps.contains(where: { $0 != nil }) else {
            XCTFail("“\(Self.progressName)” announces no step")
            return
        }
        XCTAssertEqual(announcedSteps, Self.expectedAnnouncedSteps, "the step indicator doesn't count 1, 2, 3")
    }

    // MARK: - Getting there

    private func launchFreshInstall() {
        app.launchArguments = [UITestContract.LaunchArgument.uiTest,
                               UITestContract.LaunchArgument.reset,
                               UITestContract.LaunchArgument.freshInstall]
        launchIsolated()
        expectOnboardingStep(OnboardingStep.welcome, timeout: Self.firstLaunchTimeout)
    }

    private func walkToAccountStep() {
        advanceOnboarding(with: Onboarding.welcomeContinueButton, to: OnboardingStep.welcomeAdhd)
        advanceOnboarding(with: Onboarding.welcomeAdhdContinueButton, to: OnboardingStep.letsDoIt)
        advanceOnboarding(with: Onboarding.letsDoItButton, to: OnboardingStep.setUpAccount)
    }

    private func walkToCreateAccount() {
        walkToAccountStep()
        advanceOnboarding(with: Onboarding.signUpButton, to: OnboardingStep.privacy)
        let terms = app.checkBoxes[Onboarding.termsCheckBox]
        XCTAssertTrue(appears(terms), "the terms checkbox is missing")
        if !isChecked(terms) { tap(terms) }
        advanceOnboarding(with: Onboarding.privacyContinueButton, to: OnboardingStep.createAccount)
    }

    /// Logged out, outside onboarding: the sign-in choices in the main window, then the form.
    private func openSignInForm() {
        launchLoggedOut()
        showSignInForm(failure: "a logged-out launch doesn't offer sign-in")
    }

    /// The sign-in form of a logged-out app that is starting up: through the sign-in choices, or
    /// straight away when the app opens on the form (it does after a logout).
    private func showSignInForm(failure message: String, file: StaticString = #filePath, line: UInt = #line) {
        let goToSignIn = element(Login.goToSignInButton)
        let email = app.textFields[Login.emailField]
        guard let shown = firstToAppear([email, goToSignIn], timeout: Self.firstLaunchTimeout) else {
            return XCTFail(message, file: file, line: line)
        }
        if shown != email { tap(goToSignIn) }
        expectSignInForm(file: file, line: line)
    }

    /// Signed in, onboarding skipped, main window up — as `launchSignedIn`, but through the form, so
    /// no credentials are in the environment for a relaunched copy to inherit.
    private func launchSignedInThroughTheForm(as account: TestAccount) throws {
        app.launchArguments = [UITestContract.LaunchArgument.uiTest, UITestContract.LaunchArgument.reset,
                               UITestContract.LaunchArgument.skipOnboarding]
        app.launchEnvironment = [:]
        launchIsolated()
        showSignInForm(failure: "a logged-out launch doesn't offer sign-in")
        signIn(as: account)
        let dayPlan = app.buttons[UITestContract.Identifier.Menu.dayPlan]
        // The form's round trip, then the first settings and routine fetch a signed-in launch waits for.
        guard appears(dayPlan, within: Self.signInTimeout + Self.firstLaunchTimeout, waitsOnNetwork: true) else {
            recordDiagnostics(named: "main window never appeared")
            throw XCTSkip("The main window didn't appear. A routine due for the test account right now covers it; see docs/ui-tests.md.")
        }
        XCTAssertTrue(waitForEnabled(dayPlan, timeout: Self.firstLaunchTimeout), "signing in through the form left the app signed out")
    }

    /// Fills in and sends the sign-in form. The email field may already hold the last account's
    /// address (#1308), so its text is replaced rather than added to.
    private func signIn(as account: TestAccount) {
        replaceText(of: app.textFields[Login.emailField], with: account.email)
        enterSecret(account.password, into: app.secureTextFields[Login.passwordField])
        tap(element(Login.signInButton))
    }

    private func expectSignInForm(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(appears(app.textFields[Login.emailField]), "the sign-in form has no email field", file: file, line: line)
        XCTAssertTrue(app.secureTextFields[Login.passwordField].exists, "the sign-in form has no password field", file: file, line: line)
        XCTAssertTrue(element(Login.signInButton).exists, "the sign-in form has no Sign In", file: file, line: line)
        XCTAssertTrue(element(Regression.forgotPasswordButton).exists, "the sign-in form has no Forgot Password", file: file, line: line)
        XCTAssertFalse(element(Login.createAccountButton).exists, "the sign-in form offers Create Account", file: file, line: line)
    }

    private func expectSignUpForm(file: StaticString = #filePath, line: UInt = #line) {
        let create = element(Login.createAccountButton)
        XCTAssertTrue(appears(create), "the sign-up form has no Create Account", file: file, line: line)
        XCTAssertFalse(create.isEnabled, "Create Account works before a password is typed", file: file, line: line)
        XCTAssertTrue(element(Regression.passwordRules).exists, "the sign-up form doesn't show the password rules", file: file, line: line)
        XCTAssertFalse(element(Login.signInButton).exists, "the sign-up form offers Sign In", file: file, line: line)
        XCTAssertFalse(element(Regression.forgotPasswordButton).exists, "the sign-up form offers Forgot Password", file: file, line: line)
    }

    // MARK: - Helpers

    private func enter(_ text: String, into field: XCUIElement) {
        tap(field)
        typeIntoFocus(text)
    }

    private func replaceText(of field: XCUIElement, with text: String) {
        tap(field)
        press("a", modifiers: .command)
        typeIntoFocus(text)
    }

    /// Dismisses the form's validation or sign-in failure message. False when none was shown.
    private func dismissFormAlert(within timeout: TimeInterval = screenTimeout) -> Bool {
        guard let alert = firstToAppear([element(Regression.formAlert), app.sheets.firstMatch], timeout: timeout) else { return false }
        tap(alert.buttons.firstMatch)
        return waitForNonExistence(of: alert)
    }

    /// The confirmation's "No": NSAlert lays its buttons out right to left, so the second is leftmost.
    private func declineConfirmation() {
        guard let alert = firstToAppear([app.sheets.firstMatch, app.dialogs.firstMatch]) else {
            return XCTFail("nothing asked for confirmation")
        }
        let leftmost = alert.buttons.allElementsBoundByIndex.filter(\.isHittable).min { $0.frame.minX < $1.frame.minX }
        guard let leftmost else { return XCTFail("the confirmation has no buttons") }
        tap(leftmost)
        XCTAssertTrue(waitForNonExistence(of: alert), "the confirmation didn't close")
    }

    private func waitUntil(_ element: XCUIElement, isEnabled: Bool) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == %@", NSNumber(value: isEnabled))
        return waitUntil(predicate, isTrueOf: element, within: Self.screenTimeout)
    }

    private func isChecked(_ checkbox: XCUIElement) -> Bool {
        (checkbox.value as? Int) == 1
    }

    /// An AppKit label's text is its value; fall back to its label.
    private func shownText(of element: XCUIElement) -> String {
        guard element.exists else { return "" }
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }

    private static func uniqueSite() -> String {
        "uitest-\(UUID().uuidString.prefix(8).lowercased()).\(reservedTopLevelDomain)"
    }

    /// Meets every rule (length, upper case, a digit, a symbol) and is never used for any account.
    private static func passwordMeetingTheRules() -> String {
        "Aa1!" + UUID().uuidString.prefix(8)
    }

    /// An approved test address that no account has.
    private static func unknownEmail() -> String {
        TestAccountStore.makeNew().email
    }

    /// The test build's processes that are running now.
    private static func runningTestAppProcesses() -> Set<pid_t> {
        Set(NSRunningApplication.runningApplications(withBundleIdentifier: UITestContract.bundleIdentifier)
            .filter { !$0.isTerminated }
            .map(\.processIdentifier))
    }

    /// True once every copy in `launched` has quit and a new one is running.
    private func waitForRelaunch(replacing launched: Set<pid_t>) -> Bool {
        let relaunched = NSPredicate { _, _ in
            let running = Self.runningTestAppProcesses()
            return !running.isEmpty && running.isDisjoint(with: launched)
        }
        return waitUntil(relaunched, isTrueOf: NSNull(), within: Self.relaunchTimeout)
    }

    /// Logging out relaunches the app outside XCUITest's own launch; make sure that copy doesn't
    /// outlive the test.
    private static func quitTheRelaunchedTestApp() {
        let relaunched = XCUIApplication(bundleIdentifier: UITestContract.bundleIdentifier)
        if relaunched.state != .notRunning { relaunched.terminate() }
    }
}
