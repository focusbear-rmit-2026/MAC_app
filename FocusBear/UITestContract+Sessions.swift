//
//  UITestContract+Sessions.swift
//  Focus Bear
//
//  Accessibility identifiers for the regression tests of focus sessions, breaks and routines (RegressionFocusSessionUITests, RegressionBreaksUITests, RegressionRoutineUITests).
//  Compiled into the app and the UI-test target, like UITestContract.swift. Each area has its own
//  file so the branches writing those tests never edit the same one.
//

extension UITestContract.Identifier {
    enum SessionsRegression {
        // MARK: Focus start

        static let durationMinusButton = "focusStartDurationMinusButton"
        static let durationPlusButton = "focusStartDurationPlusButton"
        static let untimedToggle = "focusStartUntimedToggle"
        /// The blocking card's header (the goal card's is `FocusStart.goalCard`).
        static let blockingCard = "focusStartBlockingCard"
        /// The chosen goal, shown in place of the goal field, and its pencil.
        static let selectedGoal = "focusStartSelectedGoal"
        static let editGoalButton = "focusStartEditGoalButton"
        /// A task picked for the session, and its ✕.
        static let selectedTask = "focusStartSelectedTask"
        static let removeTaskButton = "focusStartRemoveTaskButton"
        /// Every row of the block-list picker, and the name of the list the session will use.
        static let blockListChoice = "focusStartBlockListChoice"
        static let selectedBlockListName = "focusStartSelectedBlockListName"

        // MARK: Running session

        static let pauseButton = "focusSessionPauseButton"
        static let resumeButton = "focusSessionResumeButton"
        static let extendButton = "focusSessionExtendButton"
        static let reduceButton = "focusSessionReduceButton"
        /// "24 min 59 sec": minutes first while under an hour.
        static let countdown = "focusSessionCountdown"
        /// "0 sec of 5 min": the session's total last.
        static let progress = "focusSessionProgress"
        static let goalToggle = "focusSessionGoalToggle"
        static let goalEditor = "focusSessionGoalEditor"
        /// The empty active-task card, which opens the task picker.
        static let addFirstTaskButton = "focusSessionAddFirstTaskButton"
        static let taskPickerCloseButton = "focusSessionTaskPickerCloseButton"
        static let notesButton = "focusSessionNotesButton"
        /// Cancel on the "End session early?" sheet.
        static let endCancelButton = "focusSessionEndCancelButton"

        // MARK: Session end screen

        static let completedScreen = "focusCompletedScreen"
        static let completedStartAnotherButton = "focusCompletedStartAnotherButton"
        static let completedCloseButton = "focusCompletedCloseButton"
        static let completedAchievementToggle = "focusCompletedAchievementToggle"
        static let completedAchievementField = "focusCompletedAchievementField"
        /// Star `n` of the rating is `completedRatingStarPrefix + n`, 1 to 5.
        static let completedRatingStarPrefix = "focusCompletedRatingStar"

        // MARK: Breaks

        /// The hold-to-postpone control (a plain button when easy skip is on).
        static let warningPostponeButton = "breakWarningPostponeButton"
        static let warningMinutesPicker = "breakWarningMinutesPicker"
        static let breakStartModePicker = "breakStartModePicker"

        // MARK: Routine player

        static let habitTimerLabel = "routineHabitTimer"
        static let habitPauseButton = "routineHabitPauseButton"
        static let habitNotes = "routineHabitNotes"
        /// The screen after a habit or break activity: what's done, and the button to go on.
        static let habitFinishedScreen = "routineHabitFinishedScreen"
        static let habitFinishedMainButton = "routineHabitFinishedMainButton"
        /// "Why do you want to skip?"
        static let whySkipScreen = "routineWhySkipScreen"
        static let whySkipAlreadyDidItButton = "routineWhySkipAlreadyDidItButton"
        static let whySkipCanNotDoItButton = "routineWhySkipCanNotDoItButton"
        static let whySkipBreakCompletelyButton = "routineWhySkipBreakCompletelyButton"
        /// The "Skipping habit in 00:15" countdown, and its "I changed my mind".
        static let skipCountdownScreen = "routineSkipCountdownScreen"
        static let skipCountdownKeepHabitButton = "routineSkipCountdownKeepHabitButton"
        static let logQuantityScreen = "routineLogQuantityScreen"
        static let logQuantityOkButton = "routineLogQuantityOkButton"
        static let logQuantityCancelButton = "routineLogQuantityCancelButton"
        /// A free-entry answer, and a slider answer's value field.
        static let logQuantityField = "routineLogQuantityField"
        static let logQuantitySliderValue = "routineLogQuantitySliderValue"
        /// "What comes next?"
        static let rememberNextScreen = "routineRememberNextScreen"
        static let rememberNextHabitField = "routineRememberNextHabitField"
        static let rememberNextStartButton = "routineRememberNextStartButton"

        /// More values of `UITestContract.Environment.presentScreen`, read by
        /// `AppDelegate.presentSessionsScreenForUITest`. Everything they put on screen is held in
        /// memory only and never saved.
        enum Screen: String {
            /// A one-habit morning routine whose habit runs a timer (`Fixture.timedHabitSeconds`).
            case timedHabit = "sessionsTimedHabit"
            /// The same with a timer short enough to run out during a test.
            case shortTimedHabit = "sessionsShortTimedHabit"
            /// An untimed habit that takes notes while it runs.
            case habitWithNotes = "sessionsHabitWithNotes"
            /// An untimed habit that asks for a free-entry quantity when it's done.
            case habitWithLogQuantity = "sessionsHabitWithLogQuantity"
            /// An untimed habit whose quantity is a slider answer.
            case habitWithSliderQuantity = "sessionsHabitWithSliderQuantity"
            /// Two habits: an untimed one, then a timed one.
            case twoHabitRoutine = "sessionsTwoHabitRoutine"
            /// The two-habit routine with its first habit done and "What comes next?" asked.
            case rememberNextHabit = "sessionsRememberNextHabit"
            /// The micro-break warning for an untimed break activity, so "I'm done" can finish it.
            case untimedBreak = "sessionsUntimedBreak"
            /// The micro-break warning when no break activity is left to play (#2674).
            case breakWithNoActivities = "sessionsBreakWithNoActivities"
            /// A one-habit morning routine whose habit is an allowed-app habit (untimed, so "I'm done"
            /// finishes it). Ending a routine on one left the habit player's Day Plan tab behind: a blank
            /// pane after the routine, and the Day Plan over the next break's activity (#2731).
            case allowedAppHabitRoutine = "sessionsAllowedAppHabitRoutine"
        }

        /// What the `Screen`s put on screen.
        enum Fixture {
            static let timedHabitName = "UI test plank"
            static let timedHabitSeconds = 120
            static let shortTimedHabitSeconds = 2
            static let untimedHabitName = "UI test journal"
            /// An untimed habit's duration is only its fallback; it never counts down.
            static let untimedHabitSeconds = 300
            static let untimedHabitRequirement = "Tick this off when you've written a line"
            static let quantityQuestion = "How many lines did you write?"
            static let sliderMinimum = 0
            static let sliderMaximum = 10
            static let untimedBreakName = "UI test shoulder rolls"
            static let untimedBreakSeconds = 60
            static let untimedBreakRequirement = "Roll your shoulders five times"
            static let allowedAppHabitName = "UI test work on the content calendar"
            /// The habit's allowed app. No app has this name, so playing the habit launches nothing
            /// that could take focus from the test app; it only has to make it an allowed-app habit.
            static let allowedAppName = "UI Test Allowed App"
        }
    }
}
