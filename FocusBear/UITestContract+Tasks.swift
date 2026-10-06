//
//  UITestContract+Tasks.swift
//  Focus Bear
//
//  Accessibility identifiers for the regression tests of Day Plan, To-do and Projects (RegressionDayPlanUITests, RegressionToDoUITests, RegressionProjectsUITests).
//  Compiled into the app and the UI-test target, like UITestContract.swift. Each area has its own
//  file so the branches writing those tests never edit the same one.
//

extension UITestContract.Identifier {
    enum TasksRegression {
        // MARK: Day Plan — date bar

        static let previousDayButton = "dayPlanPreviousDayButton"
        static let nextDayButton = "dayPlanNextDayButton"
        /// The date above the schedule; its title is the day being viewed.
        static let dateButton = "dayPlanDateButton"
        /// "Back to today", shown only while another day is viewed.
        static let backToTodayButton = "dayPlanBackToTodayButton"

        // MARK: Day Plan — tasks panel

        /// "Tasks for today" / "Tasks for <weekday>".
        static let tasksHeader = "dayPlanTasksHeader"
        /// The planned-time and buffer line; absent while it has nothing to say.
        static let tasksTotal = "dayPlanTasksTotal"
        static let tasksSettingsButton = "dayPlanTasksSettingsButton"
        static let showCompletedCheckbox = "dayPlanShowCompletedCheckbox"
        /// The prompt a `#token` naming no project raises. Also the AppKit identifier the panel's own
        /// key handling matches, so its value must not change.
        static let newProjectNameField = "newProjectName"

        // MARK: Day Plan — task details (the Expand popover)
        // The fields' values are also their AppKit identifiers, which AppDelegate's Return-key
        // allowlist matches by the `taskModal` prefix — so they must keep it.

        static let taskDetailsTitleField = "taskModalTitle"
        static let taskDetailsDurationField = "taskModalDuration"
        static let taskDetailsNotesView = "taskModalNotes"
        static let taskDetailsSaveButton = "dayPlanTaskDetailsSaveButton"
        static let taskDetailsCancelButton = "dayPlanTaskDetailsCancelButton"

        // MARK: Snooze popover (the Day Plan row's and the To-do row's)

        /// Also the popover's own AppKit identifier for its input.
        static let snoozeField = "snoozeInput"
        static let snoozeMoveButton = "snoozeMoveButton"
        static let snoozeCancelButton = "snoozeCancelButton"

        // MARK: Day Plan — custom routines and routine drafts

        static let customRoutinesManageButton = "dayPlanCustomRoutinesManageButton"
        static let customRoutineManagerCloseButton = "customRoutineManagerCloseButton"
        static let customRoutineNewButton = "customRoutineNewButton"
        static let customRoutineNameField = "customRoutineNameField"
        static let customRoutineEditCancelButton = "customRoutineEditCancelButton"
        /// The evening routine's cut-off switch in the routine timing sheet.
        static let routineTimingCutoffToggle = "routineTimingCutoffToggle"
        /// "Save and restart" on the unsaved-routine-changes banner: present only while a draft exists.
        static let draftSaveButton = "dayPlanDraftSaveButton"

        // MARK: To-do — list

        static let doingSection = UITestContract.Identifier.ToDo.sectionPrefix + "IN_PROGRESS"
        static let searchField = "todoSearchField"
        static let filterButton = "todoFilterButton"
        static let filterDueDatePicker = "todoFilterDueDatePicker"
        static let clearFiltersButton = "todoClearFiltersButton"
        /// Segments: Smart, Newest, Due date — in that order.
        static let sortPicker = "todoSortPicker"
        static let brainDumpMenuItem = "todoBrainDumpMenuItem"
        static let eisenhowerMatrixMenuItem = "todoEisenhowerMatrixMenuItem"
        static let procrastinateMenuItem = "todoProcrastinateMenuItem"
        /// Close on the brain dump, Eisenhower matrix and procrastinate sheets.
        static let toolsSheetCloseButton = "todoToolsSheetCloseButton"
        static let brainDumpEditor = "todoBrainDumpEditor"
        static let procrastinateUrlField = "todoProcrastinateUrlField"
        /// One Eisenhower quadrant: `matrixQuadrantPrefix + EisenhowerQuadrant.rawValue` (1 = Do).
        static let matrixQuadrantPrefix = "todoMatrixQuadrant:"
        static let reschedulePlanApplyButton = "todoReschedulePlanApplyButton"

        // MARK: To-do — a task row

        static let rowEditButton = "todoTaskEditButton"
        static let rowCancelDeleteButton = "todoTaskCancelDeleteButton"
        static let rowDueButton = "todoTaskDueButton"
        static let duePresetToday = "todoDuePresetToday"
        static let duePresetTomorrow = "todoDuePresetTomorrow"
        static let duePresetNextWeek = "todoDuePresetNextWeek"
        static let duePresetClear = "todoDuePresetClear"

        // MARK: To-do — editor

        static let editorCancelButton = "todoEditorCancelButton"
        /// Segments: To do, Doing, Done — `ToDoStatus.allCases` order.
        static let editorStatusPicker = "todoEditorStatusPicker"
        static let editorDueDateField = "todoEditorDueDateField"
        static let editorDurationField = "todoEditorDurationField"
        static let editorDescription = "todoEditorDescription"
        /// The Outcome menu, wherever it is shown (task editor, new-project sheet, project header).
        static let outcomePicker = "todoOutcomePicker"
        static let editorProjectSearchField = "todoEditorProjectSearchField"
        static let editorCreateProjectButton = "todoEditorCreateProjectButton"
        /// A project chip: selected ones are on the task, available ones can be added to it.
        static let editorSelectedProjectChip = "todoEditorSelectedProjectChip"
        static let editorAvailableProjectChip = "todoEditorAvailableProjectChip"

        // MARK: Projects

        /// Segments: What matters, All projects, Forecast.
        static let projectsViewModePicker = "projectsViewModePicker"
        static let projectsSearchField = "projectsSearchField"
        static let projectBackButton = "projectBackButton"
        static let projectShowInTaskListButton = "projectShowInTaskListButton"
        static let projectNameHeading = "projectNameHeading"
        static let projectRenameField = "projectRenameField"
        /// Segments: list, board.
        static let projectTasksModePicker = "projectTasksModePicker"
    }
}
