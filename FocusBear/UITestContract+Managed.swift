//
//  UITestContract+Managed.swift
//  Focus Bear
//
//  Launch keys and accessibility identifiers for the managed-safety regression tests
//  (RegressionManagedSafetyUITests): school- and parent-managed blocking, and a teacher's class session.
//  Compiled into the app and the UI-test target, like UITestContract.swift. Each area has its own file
//  so the branches writing those tests never edit the same one.
//

extension UITestContract.Environment {
    /// A `ManagedPolicyScenario` raw value: the policy `UITestManagedSafetyFixture` installs in memory
    /// at launch. Nothing is written to the keychain, the policy store or the server.
    static let managedPolicy = "FOCUSBEAR_UITEST_MANAGED_POLICY"
    /// `teacherSessionActive` starts a class session held in this process only; the server never hears of it.
    static let teacherSession = "FOCUSBEAR_UITEST_TEACHER_SESSION"
    static let teacherSessionActive = "active"
}

extension UITestContract {
    /// Who manages the test student right now. A managed student's settings are locked whenever they are
    /// enrolled (`settings_locked` follows enrollment, not the time of day); the windows decide only which
    /// policy's website categories are enforced.
    enum ManagedPolicyScenario: String {
        /// School hours: the school policy's window covers now; the home policy waits for the evening.
        case schoolActive = "school-active"
        /// Outside school hours: the home policy's window covers now; the school's doesn't.
        case parentActive = "parent-active"
        /// Enrolled in a school policy whose window doesn't cover now, and no home policy.
        case schoolInactive = "school-inactive"
        /// School hours, but the last sync was a while ago and the app can't reach the server.
        case offlineLastKnown = "offline-last-known"
    }

    /// The policies the scenarios install, as the server would send them.
    enum ManagedPolicyFixture {
        static let schoolKind = "school"
        static let homeKind = "home"
        static let schoolPolicyName = "UI test school safety"
        static let homePolicyName = "UI test home safety"
    }

    /// The class session `UITestContract.Environment.teacherSession` starts.
    enum TeacherSessionFixture {
        static let sessionName = "UI test class session"
        static let minutes = 30
        /// IANA-reserved, so the allow-list never matches anything real.
        static let allowedDomain = "example.org"
    }
}

extension UITestContract.Identifier {
    enum ManagedSafety {
        /// The safety-policy inspector a managed student sees in place of Settings panes and the Blocks editors.
        static let inspector = "managedPolicyInspector"
        static let statusActive = "managedPolicyStatusActive"
        static let statusNoActiveWindow = "managedPolicyStatusNoActiveWindow"
        static let statusOffline = "managedPolicyStatusOffline"
        /// "Settings are locked…": the lock, said in words rather than shown only as disabled controls.
        static let statusSettingsLocked = "managedPolicyStatusSettingsLocked"
        /// "Contact your school…", on the school policy's card only.
        static let schoolContactNote = "managedPolicySchoolContactNote"
        /// "Request parent-approved changes", on the home policy's card only.
        static let requestHomeChangesButton = "managedPolicyRequestHomeChangesButton"
        /// "Close" on the "Settings are locked" alert a refused change raises.
        static let settingsLockedAlertCloseButton = "managedSettingsLockedAlertCloseButton"

        /// A policy's card is `cardPrefix + its kind` (`ManagedPolicyFixture.schoolKind` / `homeKind`).
        static let cardPrefix = "managedPolicyCard_"
        static func card(kind: String) -> String { cardPrefix + kind }

        /// The badge on a policy's card, named for what it says: active now, scheduled for later, or disabled.
        enum CardState: String {
            case active, scheduled, disabled
        }
        static func cardState(kind: String, _ state: CardState) -> String { card(kind: kind) + "_" + state.rawValue }

        // MARK: The parent-approved home schedule editor

        static let homeEditor = "managedHomeEditor"
        static let homeEditorNameField = "managedHomeEditorNameField"
        static let homeEditorRequestApprovalButton = "managedHomeEditorRequestApprovalButton"
        static let homeEditorSubmitButton = "managedHomeEditorSubmitButton"
        static let homeEditorCloseButton = "managedHomeEditorCloseButton"

        /// Focus Start's blocking card, for a managed student: what the school and parent block right now.
        static let focusStartSummary = "focusStartManagedSafetySummary"
        /// Where the menu-bar popover would say the Mac is managed. The app doesn't set it yet: the popover
        /// shows nothing about managed state (see RegressionManagedSafetyUITests).
        static let menuBarStatus = "menuBarManagedSafetyStatus"
        /// The "you're offline" pop-up (`PresentedScreen.offlinePopup`), whose close quits the app.
        static let offlinePopup = "managedSafetyOfflinePopup"
    }

    /// The app's own alert window (`customAlertVc`), shown by `showCustomAlert`.
    enum CustomAlert {
        static let view = "customAlert"
        static let okButton = "customAlertOkButton"
        static let cancelButton = "customAlertCancelButton"
    }

    enum TeacherSession {
        /// The custom alert, when it is "This session is controlled by your teacher". Its OK button asks
        /// for an unlock; its Cancel button closes it.
        static let lockedAlert = "teacherSessionLockedAlert"
        static let unlockRequestAppOrUrlField = "teacherUnlockRequestAppOrUrlField"
        static let unlockRequestReasonField = "teacherUnlockRequestReasonField"
        static let unlockRequestSendButton = "teacherUnlockRequestSendButton"
        static let unlockRequestCancelButton = "teacherUnlockRequestCancelButton"
    }
}
