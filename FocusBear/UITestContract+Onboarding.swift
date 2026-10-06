//
//  UITestContract+Onboarding.swift
//  Focus Bear
//
//  Accessibility identifiers for the regression tests of onboarding, sign-in, tools and keyboard shortcuts (RegressionOnboardingAuthUITests, RegressionToolsUITests, RegressionShortcutsUITests).
//  Compiled into the app and the UI-test target, like UITestContract.swift. Each area has its own
//  file so the branches writing those tests never edit the same one.
//

extension UITestContract.Identifier {
    enum OnboardingRegression {
        // MARK: Welcome and account steps (before an account exists)

        static let welcomeAlreadyHaveAccountButton = "onboardingWelcomeAlreadyHaveAccountButton"
        static let welcomeAdhdNeverHadIssueButton = "onboardingWelcomeAdhdNeverHadIssueButton"
        /// Creates a real guest account, so tests only ever check that it is offered.
        static let stayAnonymousButton = "onboardingStayAnonymousButton"
        /// Open the website in the browser, so tests only ever check that they are offered.
        static let privacyPolicyLink = "onboardingPrivacyPolicyLink"
        static let termsLink = "onboardingTermsLink"
        /// Hand off to a browser sign-in, so tests only ever check that they are offered.
        static let signUpWithGoogleButton = "askLoginSignUpWithGoogleButton"
        static let signUpWithAppleButton = "askLoginSignUpWithAppleButton"

        // MARK: The email + password form

        static let showPasswordButton = "loginShowPasswordButton"
        /// The plain-text twin of the password field, shown while the password is revealed.
        static let plainPasswordField = "loginPlainPasswordField"
        static let forgotPasswordButton = "loginForgotPasswordButton"
        /// "Don't have an account? Sign Up" under the sign-in form.
        static let switchToSignUpButton = "loginSwitchToSignUpButton"
        /// "Already have an account? Sign In" under the sign-up form.
        static let switchToSignInButton = "loginSwitchToSignInButton"
        /// The form's own Back, shown only outside onboarding.
        static let formBackButton = "loginFormBackButton"
        static let passwordRules = "loginPasswordRules"
        /// Every validation and sign-in failure message the form raises.
        static let formAlert = "loginFormAlert"

        // MARK: Distraction blocking steps (after sign-up)

        static let setUpDistractionBlockingButton = "onboardingSetUpDistractionBlockingButton"
        static let enableAiBlockingButton = "onboardingEnableAiBlockingButton"
        static let declineAiBlockingButton = "onboardingDeclineAiBlockingButton"
        static let helpPickDistractionsButton = "onboardingHelpPickDistractionsButton"
        static let pickDistractionsMyselfButton = "onboardingPickDistractionsMyselfButton"
        /// Each occupation tile is `occupationOptionPrefix + its index`.
        static let occupationOptionPrefix = "onboardingOccupationOption_"
        static let occupationDetailField = "onboardingOccupationDetailField"
        static let occupationContinueButton = "onboardingOccupationContinueButton"
        static let occupationSkipButton = "onboardingOccupationSkipButton"
        static let blockedUrlField = "onboardingBlockedUrlField"
        static let blockedUrlAddButton = "onboardingBlockedUrlAddButton"
        /// A site's checkbox is `blockedUrlCheckboxPrefix + the site`.
        static let blockedUrlCheckboxPrefix = "onboardingBlockedUrl_"
        static let blockedUrlsCount = "onboardingBlockedUrlsCount"
        static let blockedUrlsProceedButton = "onboardingBlockedUrlsProceedButton"
        static let blockedAppsTable = "onboardingBlockedAppsTable"
        /// Opens the system file panel; tests cancel it.
        static let blockedAppsAddButton = "onboardingBlockedAppsAddButton"
        static let blockedAppsRemoveButton = "onboardingBlockedAppsRemoveButton"
        static let blockedAppsCount = "onboardingBlockedAppsCount"
        static let blockedAppsProceedButton = "onboardingBlockedAppsProceedButton"
        static let allowedUrlField = "onboardingAllowedUrlField"
        static let allowedUrlAddButton = "onboardingAllowedUrlAddButton"
        /// A site's checkbox is `allowedUrlCheckboxPrefix + the site`.
        static let allowedUrlCheckboxPrefix = "onboardingAllowedUrl_"
        static let allowedUrlsContinueButton = "onboardingAllowedUrlsContinueButton"
        static let allowedUrlsSkipButton = "onboardingAllowedUrlsSkipButton"
        static let createBlockingScheduleButton = "onboardingCreateBlockingScheduleButton"
        /// The quick-start preset tiles: one id scheme for both areas, owned by SettingsRegression.
        static let schedulePresetPrefix = SettingsRegression.schedulePresetPrefix
        static let askPermissionsGrantButton = "onboardingAskPermissionsGrantButton"
        static let askPermissionsSkipButton = "onboardingAskPermissionsSkipButton"
        /// Raises the macOS Automation prompt, so tests only ever check that it is offered.
        static let systemEventsOpenSettingsButton = "onboardingSystemEventsOpenSettingsButton"

        // MARK: Signing out (Settings → Account)

        static let logoutButton = "accountLogoutButton"

        // MARK: Tools

        static let timeTrackerMenuItem = "timeTrackerMenuItem"
        static let lateNoMoreMenuItem = "lateNoMoreMenuItem"
        static let tabAuditMenuItem = "tabAuditMenuItem"
        /// A TOOLS row's ✕, shown while the pointer is over the row.
        static let hideToolButton = "leftMenuHideToolButton"
        /// The TOOLS header's gear, which lists the hidden tools.
        static let hiddenToolsButton = "leftMenuHiddenToolsButton"
        /// Restore for a hidden tool is `restoreToolPrefix + its ToolID raw value`.
        static let restoreToolPrefix = "restoreHiddenTool_"
        static let noteEditButton = "notesEditButton"
        static let noteEditorCancelButton = "notesEditorCancelButton"
        static let statsEmptyState = "statsEmptyState"
        static let statsError = "statsError"
        static let statsCard = "statsCard"
        static let statsChart = "statsChart"
        static let statsTable = "statsTable"
        /// A library track's play/stop button is `musicTrackPlayPrefix + its index`; its download
        /// button is `musicTrackDownloadPrefix + its index`.
        static let musicTrackPlayPrefix = "focusMusicPlay_"
        static let musicTrackDownloadPrefix = "focusMusicDownload_"
        static let musicNowPlaying = "focusMusicNowPlaying"
        static let musicNowPlayingStopButton = "focusMusicNowPlayingStopButton"
        static let musicAddOwnButton = "focusMusicAddOwnButton"
        static let musicSpotifyField = "focusMusicSpotifyField"
        static let musicSpotifyAddButton = "focusMusicSpotifyAddButton"
        static let musicSpotifyError = "focusMusicSpotifyError"
        static let musicYouTubeField = "focusMusicYouTubeField"
        static let musicYouTubeAddButton = "focusMusicYouTubeAddButton"
        static let musicYouTubeError = "focusMusicYouTubeError"
        /// Would look for a Focus Button over USB, so tests only ever check that it is offered.
        static let focusButtonConnectButton = "focusButtonConnectButton"
        static let focusButtonStatus = "focusButtonStatus"
        static let focusButtonShopLink = "focusButtonShopLink"
        /// Turning it on can launch the Time Tracker app, which a test never does.
        static let timeTrackerEnableToggle = "timeTrackerEnableToggle"
        static let externalToolStatus = "externalToolStatus"
        /// Opens or downloads the external app, so tests only ever check that it is offered.
        static let externalToolPrimaryButton = "externalToolPrimaryButton"
        /// Reads every browser's tabs, so tests only ever check that it is offered.
        static let tabAuditExtractButton = "tabAuditExtractButton"
        /// Sends a real report, so tests only ever check whether it is enabled.
        static let reportProblemSendButton = "helpReportProblemSendButton"

        // MARK: Keyboard shortcuts

        static let brainDumpShortcutLabel = "shortcutBrainDumpLabel"
        static let focusMusicShortcutLabel = "shortcutFocusMusicLabel"
        static let taskListShortcutLabel = "shortcutTaskListLabel"
    }
}
