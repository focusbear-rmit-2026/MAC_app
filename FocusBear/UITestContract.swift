//
//  UITestContract.swift
//  Focus Bear
//
//  Compiled into BOTH the app and Focus BearUITests, so the launch arguments, environment keys and
//  accessibility identifiers the tests look for can never drift from the ones the app sets.
//  Identifiers are deliberately language-independent: the app's strings come from config.json and
//  are translated, so a test that matched on titles would break in Spanish.
//

import Foundation

enum UITestContract {
    /// The UI-test build's bundle id suffix. `FB_BUNDLE_ID_SUFFIX` must match (docs/ui-tests.md).
    static let bundleIdentifierSuffix = ".uitests"
    static let bundleIdentifier = "com.App.EarnYourScreentime" + bundleIdentifierSuffix

    enum TestAccount {
        static let EMAIL_PREFIX = "internaltest+macuitest"
        static let EMAIL_DOMAIN = "focusbear.io"

        static func isAllowed(email: String) -> Bool {
            guard email.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return false }
            let parts = email.lowercased().split(separator: "@", omittingEmptySubsequences: false)
            guard parts.count == 2, parts[1] == EMAIL_DOMAIN else { return false }
            return parts[0].hasPrefix(EMAIL_PREFIX) && parts[0].count > EMAIL_PREFIX.count
        }
    }

    enum LaunchArgument {
        /// Passed by every UI test. On its own it only asserts the build is isolated.
        static let uiTest = "--uiTest"
        /// Start logged out, from the test app's own (isolated) credentials and preferences.
        static let reset = "--uiTestReset"
        /// Skip the onboarding wizard and present the main window once the schedule has loaded.
        static let skipOnboarding = "--uiTestSkipOnboarding"
        /// With `reset`: behave like a first launch on a new Mac, so the welcome onboarding shows.
        static let freshInstall = "--uiTestFreshInstall"
    }

    /// Read by the app only when it carries the isolated bundle id. CI supplies them from secrets;
    /// nothing in the repository holds a password.
    enum Environment {
        static let email = "FOCUSBEAR_UITEST_EMAIL"
        static let password = "FOCUSBEAR_UITEST_PASSWORD"
        /// The blocking tests' opt-in (`UITestHost.isBlockingEnabled`); set only on the CI runner.
        static let enableBlocking = "FOCUSBEAR_UITEST_ENABLE_BLOCKING"
        static let enabledValue = "1"
        /// A screen that normally needs the clock or a meeting to appear (`PresentedScreen`), shown on
        /// demand so the accessibility suites can reach it.
        static let presentScreen = "FOCUSBEAR_UITEST_PRESENT_SCREEN"
        /// Which `BlockingFixture.Kind` to set up (or tear down) once the app has loaded settings.
        static let blockingFixture = "FOCUSBEAR_UITEST_BLOCKING_FIXTURE"
        /// `disabledValue` turns easy skip off for this launch (in memory), so a test can reach the
        /// hold-to-postpone button and the skip countdown a new account (easy skip on) never shows.
        static let easySkip = "FOCUSBEAR_UITEST_EASY_SKIP"
        static let disabledValue = "0"
        /// `focusMusicOff` stops the "Want to play some focus music?" prompt covering a session.
        static let focusMusic = "FOCUSBEAR_UITEST_FOCUS_MUSIC"
        static let focusMusicOff = "off"
        /// `enabledValue` deletes the test account's leftovers from earlier runs (`TestTitle`) once
        /// the app has signed in, then reports on the status item (`accountCleanupDonePrefix`).
        static let cleanAccount = "FOCUSBEAR_UITEST_CLEAN_ACCOUNT"
        /// `enabledValue` turns off the account's after-routine Pomodoro and brain dump for this launch
        /// (the test app's own settings), so a finished morning routine lands on the Day Plan — the path
        /// that went blank after an allowed-app habit (#2731). The test account has Pomodoro on.
        static let routineEndsOnDayPlan = "FOCUSBEAR_UITEST_ROUTINE_ENDS_ON_DAY_PLAN"
        static let accountCleanupDonePrefix = "uiTestAccountCleanup:"
        /// `enabledValue` posts one `EventsProbe.eventType` event once the app has signed in, and
        /// reports the reply on the status item: `eventsProbeDonePrefix + stack + ":" + HTTP status`,
        /// or `EventsProbe.noReply` in place of the status. It goes to `EventsEndpoint.current` (v2
        /// unless the launch forces v1); set `EventsEndpoint.environmentKey` to pin a stack.
        static let eventsProbe = "FOCUSBEAR_UITEST_EVENTS_PROBE"
        static let eventsProbeDonePrefix = "uiTestEventsProbe:"
    }

    /// The one analytics event the test build sends (`Environment.eventsProbe`), to its own test
    /// account. The name is on none of the events service's routing lists (quit, uninstall, 4-hour
    /// break, bad-AI report, mobile postpones), so v2 only records it: no chat alert, support email,
    /// push or impact entry.
    enum EventsProbe {
        static let eventType = "mac-ui-test-events-probe"
        static let noReply = "noReply"
        static let fieldSeparator: Character = ":"
    }

    /// Asks the running test app to delete the account's test items now, without a relaunch: the
    /// test posts `cleanAccountNow` as a distributed notification whose object is a request id, and
    /// the app reports `Environment.accountCleanupDonePrefix + id + ":"` on the status item when done.
    enum Command {
        static let cleanAccountNow = "com.focusbear.uitests.cleanAccountNow"
        /// Shows a `PresentedScreen` or sessions `Screen` in the running app, as the launch
        /// environment does at launch; the object is its raw value. For what only happens after
        /// something else: a break falling due once a routine has finished.
        static let presentScreen = "com.focusbear.uitests.presentScreen"
        /// Presses a control as VoiceOver does, or focuses a text field. The object is
        /// `request id|identifier|x|y|PressAction|sent at`: the control with that identifier whose frame
        /// holds the screen point (top-left origin); `sent at` is seconds since 1970. The app answers
        /// `pressDonePrefix + request id + ":" + PressOutcome` on the status item, and ignores a request
        /// older than `pressRequestLifetime` — by then the test has clicked instead.
        static let press = "com.focusbear.uitests.press"
        static let pressDonePrefix = "uiTestPress:"
        static let requestFieldSeparator: Character = "|"
        static let pressRequestLifetime: TimeInterval = 0.35
        /// Asks which control has the keyboard focus, for the one XCUITest can't see: a secure text
        /// field doesn't report hasKeyboardFocus. The object is a request id; the app answers
        /// `focusAnswerPrefix + request id + ":" + the focused control's accessibility identifier`.
        static let focusQuery = "com.focusbear.uitests.focus"
        static let focusAnswerPrefix = "uiTestFocus:"
    }

    enum PressOutcome: String {
        case pressed, missing, ambiguous, notPressable
    }

    enum PressAction: String {
        /// `select` chooses the table row a control sits in, as clicking the row does.
        case press, focus, select
    }

    /// What every to-do, project and note a test creates is called: "UI test <what> <8 hex digits>"
    /// (`FocusBearUITestCase.uniqueTitle`). Account clean-up deletes only titles matching this exactly.
    enum TestTitle {
        static let prefix = "UI test "
        private static let pattern = "^UI test .+ [0-9A-F]{8}$"

        static func matches(_ title: String) -> Bool {
            title.range(of: pattern, options: .regularExpression) != nil
        }
    }

    enum PresentedScreen: String {
        /// The micro-break warning, as when a break falls due.
        case microBreak
        /// The same warning during a meeting ("mid meeting break").
        case meetingBreak
        /// A routine habit with no timer, only a completion requirement.
        case nonTimerActivity
        /// The menu-bar popover. Its icon can be hidden or crowded out of the menu bar, so tests open
        /// it through this rather than by clicking.
        case menuBarPopover
        /// A small evening routine (one timed habit, one untimed) in today's Day Plan, so its editors
        /// have something to edit. Held locally only and never saved.
        case dayPlanRoutine
        /// The "you're offline" pop-up, as after a sign-in refresh fails with no internet. Closing it
        /// quits the app unless a managed lock or class session refuses.
        case offlinePopup
    }

    /// The habits `PresentedScreen.dayPlanRoutine` and `.nonTimerActivity` put on screen.
    enum RoutineFixture {
        static let timedHabitName = "UI test stretch"
        static let timedHabitSeconds = 120
        static let untimedHabitName = "UI test activity"
        static let untimedHabitSeconds = 300
        static let untimedHabitRequirement = "Tick this off when you're done"
        /// The seeded evening routine starts this long from now, so the Day Plan has room to show its
        /// habits (a new account's routine starts at 23:59, leaving none) and it isn't due mid-test.
        static let eveningStartsInMinutes = 30
        /// The break activity the break screens get when the account has none (the real break
        /// trigger never fires without one, and starting a break with none crashes).
        static let breakActivityName = "UI test stretch break"
        static let breakActivitySeconds = 60
    }

    /// What the blocking tests block, set up by the app itself through its normal settings and API
    /// paths (`UITestBlockingFixture`). The domains are IANA-reserved examples, so they never collide
    /// with anything real on the test account.
    enum BlockingFixture {
        enum Kind: String, Codable {
            /// example.com and TextEdit on the always-blocked lists; no session.
            case alwaysBlocked
            /// A block list (blocks example.com and TextEdit, allows example.org) and a running session on it.
            case focusSession
            /// The same block list, run by a blocking schedule that covers the current time.
            case blockingSchedule
            /// Remove everything any of the above created, then quit.
            case cleanup
        }

        static let blockedDomain = "example.com"
        static let allowedDomain = "example.org"
        static let blockedAppBundleIdentifier = "com.apple.TextEdit"
        /// The browser the tests drive. The app's own Automation permission for it is reported in `Status`.
        static let browserBundleIdentifier = "com.apple.Safari"
        static let blockedAppPath = "/System/Applications/TextEdit.app"
        /// Every block list and schedule the fixture creates is named with this, so cleanup can find
        /// leftovers from a run that crashed before its own teardown.
        static let namePrefix = "UI test fixture"
        static let sessionMinutes = 15
        static let scheduleLeadMinutes = 5
        static let scheduleMinutes = 30

        /// Published by the app, as JSON in the menu-bar icon's accessibility value, once a fixture is
        /// in place. The test runner is sandboxed, so this is how it reads the app's state.
        struct Status: Codable {
            let kind: Kind
            let isApplied: Bool
            let failure: String?
            /// Accessibility is what lets the test app act on other apps; it is granted by hand on
            /// the runner (docs/ui-tests.md), so a missing grant is reported rather than guessed at.
            let hasAccessibility: Bool
            /// `AEDeterminePermissionToAutomateTarget` for Safari, without prompting (0 = granted).
            let safariAutomationStatus: Int32
        }
    }

    enum Identifier {
        /// One of several same-kind controls, told apart by what it is for: `kind + ":" + name`. A
        /// test then finds it by identifier alone; matching on the label reads every button's label,
        /// which took about 1.5 s on the To-do screen.
        static func named(_ kind: String, _ name: String) -> String { kind + ":" + name }

        enum Login {
            static let signUpWithEmailButton = "signUpWithEmailButton"
            static let confirmPasswordField = "confirmPasswordField"
            static let createAccountButton = "createAccountSubmitButton"
            static let goToSignInButton = "goToSignInButton"
            static let emailField = "emailField"
            static let passwordField = "passwordField"
            static let signInButton = "signInSubmitButton"
        }

        enum Menu {
            static let dayPlan = "dayPlanMenuItem"
            static let focusSession = "focusSessionMenuItem"
            static let todo = "todoMenuItem"
            static let settings = "settingsMenuItem"
            static let blocks = "blocksMenuItem"
            static let help = "helpMenuItem"
        }

        enum DayPlan {
            static let view = "dayPlanView"
            static let addTaskButton = "dayPlanAddTaskButton"
            /// A task row's name field is `taskNamePrefix + task id`; its done checkbox is the bare id.
            static let taskNamePrefix = "name:"
            /// …and its duration field is `taskDurationPrefix + task id`.
            static let taskDurationPrefix = "dur:"
        }

        enum ToDo {
            /// A list section's header is `sectionPrefix + section id`; a status section's id is the
            /// status's raw value (`ToDoStatus`).
            static let sectionPrefix = "todoSection:"
            static let notStartedSection = sectionPrefix + "NOT_STARTED"
            static let doneSection = sectionPrefix + "COMPLETED"
            static let newTaskButton = "todoNewTaskButton"
            static let toolsMenu = "todoToolsMenu"
            static let reschedulePlanMenuItem = "todoReschedulePlanMenuItem"
            static let reschedulePlanCloseButton = "todoReschedulePlanCloseButton"
            static let taskRow = "todoTaskRow"
            static let taskCheckbox = "todoTaskCheckbox"
            static let deleteButton = "todoTaskDeleteButton"
            static let confirmDeleteButton = "todoTaskConfirmDeleteButton"
            static let editorTitleField = "todoEditorTitleField"
            static let editorSaveButton = "todoEditorSaveButton"
        }

        enum FocusStart {
            static let startButton = "focusStartStartButton"
            static let modeLink = "focusStartModeLink"
            static let durationHours = "focusStartDurationHours"
            static let durationMinutes = "focusStartDurationMinutes"
            static let durationField = "focusStartDurationField"
            static let goalCard = "focusStartGoalCard"
            /// The advanced screen's "How long shall we focus?" card header; the dial and its slider
            /// exist only while it is open.
            static let durationCard = "focusStartDurationCard"
            static let goalField = "focusStartGoalField"
            static let clearGoalButton = "focusStartClearGoalButton"
            static let addMoreTasksButton = "focusStartAddMoreTasksButton"
            static let taskSearchField = "focusStartTaskSearchField"
            static let taskSuggestion = "focusStartTaskSuggestion"
            /// "No thanks" on the "Do you want to block distractions?" sheet a start raises without permissions.
            static let declineBlockingButton = "focusStartDeclineBlockingButton"
        }

        enum FocusSession {
            static let endButton = "focusSessionEndButton"
            static let endConfirmButton = "focusSessionEndConfirmButton"
        }

        enum Blocking {
            /// The prompts Focus Bear raises instead of (or before) blocking outright.
            static let intentionPrompt = "blockingIntentionPrompt"
            static let focusBlockPrompt = "blockingFocusBlockPrompt"
            static let blockListsRow = "blockingBlockListsRow"
            static let blockingSchedulesRow = "blockingSchedulesRow"
            static let blockListsEditor = "blockingBlockListsEditor"
            static let blockingSchedulesEditor = "blockingSchedulesEditor"
        }

        enum Breaks {
            static let warningStartButton = "breakWarningStartButton"
            static let warningSkipButton = "breakWarningSkipButton"
            static let startScreenStartButton = "breakStartStartButton"
            static let startScreenSkipButton = "breakStartSkipButton"
            /// "Make a quick braindump": the redesigned start screen keeps the brain dump closed until
            /// this is clicked, unless the note already has something in it.
            static let startScreenBrainDumpOpenButton = "breakStartBrainDumpOpenButton"
        }

        enum Routine {
            static let primaryButton = "habitsStatePrimaryButton"
            static let startFirstHabitButton = "routineStartFirstHabitButton"
            static let postponeButton = "routinePostponeButton"
            static let skipHabitButton = "routineSkipHabitButton"
            static let doneButton = "routineHabitDoneButton"
            static let accountabilityBuddySheet = "accountabilityBuddySheet"
            static let buddyChatInput = "accountabilityBuddyChatInput"
            static let buddyChatSendButton = "accountabilityBuddyChatSendButton"
        }

        enum Help {
            static let tabView = "helpTabView"
            static let reportProblemText = "helpReportProblemText"
            static let localReportsTable = "helpLocalReportsTable"
        }

        enum Settings {
            /// Each sidebar row is `tabPrefix + the row's id` (settingsSideBarVc's `idUi` etc.).
            static let tabPrefix = "settingsTab_"
            static let appearanceTab = tabPrefix + Pane.ui
            static let keyboardShortcutsTab = tabPrefix + Pane.keyboardShortcuts
            /// The sidebar rows' ids — the values of settingsSideBarVc's `idUi`, `idAccesibility`…
            enum Pane {
                static let ui = "ui"
                static let accessibility = "accesibility"
                static let ai = "ai"
                static let pomodoro = "pomodoro"
                static let strictness = "strictness"
                static let account = "account"
                static let uninstall = "uninstall"
                static let microBreaks = "microbreaks"
                static let permissions = "permissions"
                static let toDoList = "todolist"
                static let keyboardShortcuts = "keyboardshortcuts"
                static let officeMode = "officeMode"
            }
            /// The pane area, named `panePrefix + the id of the row that opened it`.
            static let panePrefix = "settingsPane_"
            static let darkModePopup = "darkModePopup"
            /// Appearance → "Enable popover menu": changes nothing but how the menu-bar icon opens.
            static let popoverMenuSwitch = "settingsPopoverMenuSwitch"
        }

        /// The main window's content area, named `prefix + the sidebar item's identifier` for the
        /// screen a sidebar item opened. One landmark for every tool, whatever it is built with.
        enum Screen {
            static let prefix = "screen_"
            static func shown(byMenuItem menuItem: String) -> String { prefix + menuItem }
        }

        enum Tools {
            static let section = "leftMenuToolsSection"
            /// The PREFERENCES header, the other collapsible sidebar section.
            static let preferencesSection = "leftMenuPreferencesSection"
            static let notes = "notesMenuItem"
            static let stats = "statsMenuItem"
            static let focusMusic = "focusMusicMenuItem"
            static let focusButton = "focusButtonMenuItem"
            static let editHabits = "editHabitsMenuItem"
        }

        enum Stats {
            /// Each tab button is `tabPrefix + the tab's raw value`.
            static let tabPrefix = "statsTab_"
            static let content = "statsContent"
        }

        enum Notes {
            static let newNoteButton = "notesNewNoteButton"
            static let editorTitleField = "notesEditorTitleField"
            static let editorSaveButton = "notesEditorSaveButton"
            static let row = "notesRow"
            static let deleteButton = "notesDeleteButton"
        }

        enum Projects {
            static let screenTabs = "todoScreenTabs"
            static let newProjectButton = "projectsNewProjectButton"
            static let nameField = "projectsNameField"
            static let createButton = "projectsCreateButton"
            static let openProjectButton = "projectsOpenProjectButton"
            static let detail = "projectDetailView"
            static let addTaskButton = "projectAddTaskButton"
            static let column = "projectKanbanColumn"
            static let taskCard = "projectTaskCard"
            static let moveTaskMenu = "projectMoveTaskMenu"
            static let settingsButton = "projectSettingsButton"
            static let deleteButton = "projectDeleteButton"
        }

        enum DayPlanEditors {
            static let addEventButton = "dayPlanAddEventButton"
            static let eventFormCloseButton = "dayPlanEventFormCloseButton"
            static let routineMenuButton = "dayPlanRoutineMenuButton"
            /// Habit action buttons already carry `edit:<habit id>` as their identifier.
            static let habitEditPrefix = "edit:"
            static let habitNameField = "dayPlanHabitNameField"
            static let habitEditorCancelButton = "dayPlanHabitEditorCancelButton"
            static let routineTimingCancelButton = "dayPlanRoutineTimingCancelButton"
        }

        enum MenuBar {
            static let statusItem = "focusBearStatusItem"
            static let popover = "menuBarPopover"
            static let openDayPlanButton = "menuBarOpenDayPlanButton"
            static let preferencesButton = "menuBarPreferencesButton"
            static let quitButton = "menuBarQuitButton"
            /// The running session's row: "Focus: <mode>" over "<hh:mm:ss> remaining".
            static let focusSection = "menuBarFocusSection"
        }

        enum Onboarding {
            /// The current step, named `stepPrefix + the ONBOARDINGSTATE case`, e.g. `_WELCOME_`.
            static let stepPrefix = "onboardingStep_"
            static let backButton = "onboardingBackButton"
            static let welcomeContinueButton = "onboardingWelcomeContinueButton"
            static let welcomeAdhdContinueButton = "onboardingWelcomeAdhdContinueButton"
            static let letsDoItButton = "onboardingLetsDoItButton"
            /// "Sign up" on the account step. Its neighbour, "stay anonymous", creates a real guest
            /// account and is deliberately never pressed.
            static let signUpButton = "onboardingSignUpButton"
            static let termsCheckBox = "onboardingTermsCheckBox"
            static let privacyContinueButton = "onboardingPrivacyContinueButton"
            /// After the account exists, the shortest way through: no blocking, no schedule, no habits.
            static let skipDistractionBlockingButton = "onboardingSkipDistractionBlockingButton"
            static let skipBlockingScheduleButton = "onboardingSkipBlockingScheduleButton"
            static let holdOnContinueButton = "onboardingHoldOnContinueButton"
            static let skipHabitsButton = "onboardingSkipHabitsButton"
            static let finishButton = "onboardingFinishButton"
        }
    }
}
