//
//  FocusSessionStrings.swift
//  Focus Bear
//
//  User-facing text for the ongoing-focus-session screen. Config-driven like every other screen:
//  the English below is only the offline fallback, the shipped copy lives in
//  `configjson["focusStateVcInfo"]` and its Spanish counterpart in the assets repo's config-es.json.
//

import Foundation

/// Placeholder tokens substituted at render time. The same convention the rest of config.json uses.
enum FocusSessionPlaceholder {
    static let count = "<COUNT>"
    static let minutes = "<MINUTES>"
    static let score = "<SCORE>"
    static let time = "<TIME>"
    static let elapsed = "<ELAPSED>"
    static let total = "<TOTAL>"
}

struct FocusSessionStrings {
    // Header
    var sessionRunningTitle = "Ongoing Focus Session"
    var sessionPausedTitle = "Focus Session Paused"
    var superFocusRunningTitle = "Super Focus session running"

    // Reuses the existing translated browser-permission guidance from onboarding.
    var browserPermissionMessage = "Unable to get <APPNAME> URL. Please check permissions. Do you want to Open System Preferences -> Privacy & Security and check if <APPNAME> is allowed to be accessed by Focus Bear under Automation?"
    var openAutomationPreferences = "Open Automation Preferences"

    // Countdown units, used to build "24 min 36 sec".
    var hourUnit = "hr"
    var minuteUnit = "min"
    var secondUnit = "sec"
    var minutesShortLabel = "MIN"

    // Timer controls
    var extendDurationTooltip = "Add time to this session"
    var reduceDurationTooltip = "Take time off this session"
    var pauseTooltip = "Pause"
    var resumeTooltip = "Resume"
    var endSessionTooltip = "End Session"
    var durationLockedInSuperStrictNotice = "The duration cannot be reduced in super strict mode"

    // Session card
    var untitledFocusMode = "Focus session"
    var focusGoalLabel = "Focus Goal:"
    var focusGoalPlaceholder = "What do you want to get done in this session?"
    var focusGoalLockedNotice = "Focus goal cannot be changed in super strict mode"

    // Task panel
    var activeTaskLabel = "ACTIVE TASK"
    var taskQueueLabel = "Task Queue (<COUNT>):"
    var noActiveTaskTitle = "No task chosen yet"
    var noActiveTaskBody = "Add a task so this session has a job to do."
    /// The empty active-task card is itself the button that opens the picker.
    var addTaskButton = "Add a task"
    var emptyQueueLabel = "Nothing else queued."
    var markCompleteButton = "Mark as complete"
    var timeOnTaskLabel = "Working for <TIME>"
    var sessionProgressLabel = "<ELAPSED> of <TOTAL>"
    var addTasksTooltip = "Add tasks to this session"
    var durationBadge = "DURATION: <MINUTES> MINS"

    // Row menu
    var menuMarkComplete = "Mark as Complete"
    var menuFocusOnThisInstead = "Focus on this instead"
    var menuMoveUp = "Move up"
    var menuMoveDown = "Move down"
    var menuRemoveFromQueue = "Remove from queue"

    // Task picker
    var selectTasksTitle = "Select Tasks"
    var searchTaskPlaceholder = "Search for a task"
    var createNewTaskButton = "Create new task"
    var queueTasksButton = "Queue <COUNT> tasks"
    var queueSingleTaskButton = "Queue 1 task"
    var noMatchingTasks = "No matching tasks"
    var noTasksToPick = "Nothing planned for today yet"
    var pickerFromDayPlan = "From today's Day Plan"
    var pickerFromToDoList = "From your to-do list"
    var pickerFromSearch = "Searching all your to-dos"
    var fetchingTasks = "Fetching tasks..."
    var closeButton = "Close"
    var cancelButton = "Cancel"

    // Create task sheet
    var createTaskTitle = "Create new task"
    var taskNameLabel = "Task name:"
    var taskNamePlaceholder = "Give the task a name"
    var taskDescriptionLabel = "Description:"
    var taskDescriptionPlaceholder = "Add a task description"
    var taskDueDateLabel = "Due date:"
    var createTaskButton = "Create task"
    var savingTask = "Saving task..."

    // Side rail
    var focusMusicLabel = "FOCUS MUSIC"
    var notesLabel = "NOTES"
    var brainDumpLabel = "BRAINDUMP"
    var brainDumpPlaceholder = "Make a quick braindump"
    var seeOtherNotes = "See other notes"

    // Edit task
    var editTaskTitle = "Edit task"
    var saveTaskButton = "Save task"
    var taskStatusLabel = "Task status:"
    var statusNotStarted = "Not started"
    var statusInProgress = "In Progress"
    var statusCompleted = "Completed"
    var outcomeLabel = "Outcome:"
    var perspirationLabel = "Perspiration:"
    var projectLabel = "Add to project"
    var noProjectOption = "No project"
    var couldNotSaveTask = "Could not save the task"
    var taskServerUpdateRequired = "The server has not provided the details needed to edit this task safely. This needs a service update; reconnecting will not fix it. You can keep working on the task."
    var couldNotLoadTask = "Could not load this task for editing. Reconnect and try again."
    var taskChanged = "This task changed while you were editing. Close and reopen it to review the latest version."
    var outcomeNotSet = "Not set"
    // The scale's own wording lives in `ToDoStrings.outcomeLabel` — one definition for tasks and
    // projects alike, so this sheet can no longer drift from the rest of the app.
    var currentOutcome = "Current: <SCORE>/5"
    var musicLibrary = "Choose focus music"
    var musicEmpty = "No downloaded tracks yet. Open Focus Music to download a track."
    var musicVolume = "Volume"
    var blockListLabel = "Block list:"
    var changeBlockList = "Change the block list for this session"
    var subtaskPlaceholder = "Add a subtask"
    var addSubtask = "Add subtask"
    var removeSubtask = "Remove subtask"
    var retryButton = "Retry"
    var subtaskChanged = "This task changed. Reload the subtasks before trying again."

    var editTaskMenuItem = "Edit task"
    /// Band captions shown beside the Outcome / Perspiration sliders (1-10 split 1-3 / 4-6 / 7-8 / 9-10).
    var bandLow = "Low"
    var bandNormal = "Normal"
    var bandHigh = "High"
    var bandCritical = "Critical"

    // Filters
    var addFiltersTitle = "Add Filters"
    var filterTasksTooltip = "Filter tasks"
    var filterPerspirationLabel = "Perspiration:"
    var filterFullSpoons = "Full Spoons (4-10)"
    var filterLowSpoons = "Low spoons (1-3)"
    var filterProjectLabel = "Project:"
    var searchProjectPlaceholder = "Search for a project"
    var filterDueDateLabel = "Due Date:"
    var dueOverdue = "Overdue"
    var dueToday = "Today"
    var dueInAWeek = "In a week"
    var dueInTwoWeeks = "In 2 weeks"
    var dueInAMonth = "In a month"
    var daysFromToday = "<COUNT> days"
    var addFiltersButton = "Add <COUNT> filters"
    var addSingleFilterButton = "Add 1 filter"
    var topScoreBadge = "TOP: <SCORE>"

    // End-session confirmation
    var endSessionConfirmTitle = "End session early?"
    var endSessionConfirmBody = "A few more minutes could be the difference. Stick with it?"
    var endSessionConfirmButton = "End Session"

    var durationUnits: FocusSessionDurationUnits {
        FocusSessionDurationUnits(hour: hourUnit, minute: minuteUnit, second: secondUnit)
    }

    /// Replaces `<COUNT>` in the task-queue heading.
    func taskQueueHeading(count: Int) -> String {
        taskQueueLabel.replacingOccurrences(of: FocusSessionPlaceholder.count, with: "\(count)")
    }

    /// Replaces `<COUNT>` in the picker's confirm button, with a singular variant for one task.
    func queueTasksButton(count: Int) -> String {
        guard count != 1 else { return queueSingleTaskButton }
        return queueTasksButton.replacingOccurrences(of: FocusSessionPlaceholder.count, with: "\(count)")
    }

    /// Replaces `<TIME>` in the active card's "Working for 12 min" reading.
    func timeOnTask(_ elapsed: String) -> String {
        timeOnTaskLabel.replacingOccurrences(of: FocusSessionPlaceholder.time, with: elapsed)
    }

    /// "5 min of 30 min" under the session progress bar.
    func sessionProgress(elapsed: String, total: String) -> String {
        sessionProgressLabel
            .replacingOccurrences(of: FocusSessionPlaceholder.elapsed, with: elapsed)
            .replacingOccurrences(of: FocusSessionPlaceholder.total, with: total)
    }

    /// Replaces `<COUNT>` in the filter sheet's confirm button, with a singular variant for one filter.
    func addFiltersButton(count: Int) -> String {
        guard count != 1 else { return addSingleFilterButton }
        return addFiltersButton.replacingOccurrences(of: FocusSessionPlaceholder.count, with: "\(count)")
    }

    /// Replaces `<COUNT>` in a due-date handle's caption. The sign is part of the number, as in the
    /// design's "0 days" / "+8 days".
    func daysFromToday(_ days: Int) -> String {
        let signed = days > 0 ? "+\(days)" : "\(days)"
        return daysFromToday.replacingOccurrences(of: FocusSessionPlaceholder.count, with: signed)
    }

    /// Replaces `<SCORE>` in the TOP badge, to one decimal place as the design shows it.
    func topScoreBadge(_ score: Double) -> String {
        topScoreBadge.replacingOccurrences(of: FocusSessionPlaceholder.score,
                                           with: String(format: "%.1f", score))
    }

    /// The caption beside an Outcome / Perspiration slider for a 1-10 level.
    func bandLabel(forLevel level: Int) -> String {
        switch level {
        case ...3: return bandLow
        case 4...6: return bandNormal
        case 7...8: return bandHigh
        default: return bandCritical
        }
    }

    func statusLabel(for status: FocusSessionTaskStatus) -> String {
        switch status {
        case .notStarted: return statusNotStarted
        case .inProgress: return statusInProgress
        case .completed: return statusCompleted
        }
    }

    /// Replaces `<MINUTES>` in a task's duration badge.
    func durationBadge(minutes: Int) -> String {
        durationBadge.replacingOccurrences(of: FocusSessionPlaceholder.minutes, with: "\(minutes)")
    }

    func taskLoadError(_ result: Result<[String: Any], FocusSessionTaskLookup.Failure>) -> String {
        if case .failure(.incompleteServerSnapshot) = result { return taskServerUpdateRequired }
        return couldNotLoadTask
    }

    /// Reads the shipped copy over the fallbacks above. New keys live alongside the screen's existing
    /// `titleIntention` / `titleTask` in the same config block.
    static func load() -> FocusSessionStrings {
        var strings = FocusSessionStrings()
        strings.applyCommonBlocks()
        let language = BundledConfigLanguage.current()
        let bundled: [String: Any] = Bundle.main.url(forResource: language, withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] } ?? [:]
        let bundledPermissions = bundled["onboardingControllingBrowserVcInfo"] as? [String: Any] ?? [:]
        let remotePermissions = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? [String: Any] ?? [:]
        let permissions = bundledPermissions.merging(remotePermissions.filter { ($0.value as? String)?.isEmpty == false }) { _, live in live }
        let permissionMessageKey: String
        if #available(macOS 13.0, *) {
            permissionMessageKey = "alertOpenPreferencesLatestOsText"
        } else {
            permissionMessageKey = "alertOpenPreferencesText"
        }
        if let message = permissions[permissionMessageKey] as? String, !message.isEmpty {
            strings.browserPermissionMessage = message
        }
        if let button = permissions["buttonOpenPreferences"] as? String, !button.isEmpty {
            strings.openAutomationPreferences = button
        }
        let fallback = bundled["focusStateVcInfo"] as? [String: Any] ?? [:]
        let remote = configjson.value(forKey: "focusStateVcInfo") as? [String: Any] ?? [:]
        let info = fallback.merging(remote.filter { ($0.value as? String)?.isEmpty == false }) { _, live in live }
        func read(_ key: String, _ target: inout String) {
            if let value = info[key] as? String, !value.isEmpty { target = value }
        }
        read("titleOngoingSession", &strings.sessionRunningTitle)
        read("titleSessionPaused", &strings.sessionPausedTitle)
        read("titleSuperFocusRunning", &strings.superFocusRunningTitle)
        read("unitHourText", &strings.hourUnit)
        read("unitMinuteText", &strings.minuteUnit)
        read("unitSecondText", &strings.secondUnit)
        read("labelMinutesShort", &strings.minutesShortLabel)
        read("toolTipExtendDuration", &strings.extendDurationTooltip)
        read("toolTipReduceDuration", &strings.reduceDurationTooltip)
        read("noticeDurationLockedInSuperStrict", &strings.durationLockedInSuperStrictNotice)
        read("titleUntitledFocusMode", &strings.untitledFocusMode)
        read("titleIntention", &strings.focusGoalLabel)
        read("placeholderFocusGoal", &strings.focusGoalPlaceholder)
        read("labelActiveTask", &strings.activeTaskLabel)
        read("labelTaskQueue", &strings.taskQueueLabel)
        read("titleNoActiveTask", &strings.noActiveTaskTitle)
        read("bodyNoActiveTask", &strings.noActiveTaskBody)
        read("buttonAddTask", &strings.addTaskButton)
        read("labelEmptyQueue", &strings.emptyQueueLabel)
        read("buttonMarkComplete", &strings.markCompleteButton)
        read("labelTimeOnTask", &strings.timeOnTaskLabel)
        read("labelSessionProgress", &strings.sessionProgressLabel)
        read("toolTipAddTasks", &strings.addTasksTooltip)
        read("labelDurationBadge", &strings.durationBadge)
        read("menuMarkComplete", &strings.menuMarkComplete)
        read("menuFocusOnThisInstead", &strings.menuFocusOnThisInstead)
        read("menuMoveTaskUp", &strings.menuMoveUp)
        read("menuMoveTaskDown", &strings.menuMoveDown)
        read("menuRemoveFromQueue", &strings.menuRemoveFromQueue)
        read("titleSelectTasks", &strings.selectTasksTitle)
        read("placeholderSearchTask", &strings.searchTaskPlaceholder)
        read("buttonCreateNewTask", &strings.createNewTaskButton)
        read("buttonQueueTasks", &strings.queueTasksButton)
        read("buttonQueueSingleTask", &strings.queueSingleTaskButton)
        read("labelNoMatchingTasks", &strings.noMatchingTasks)
        read("labelNoTasksToPick", &strings.noTasksToPick)
        read("labelPickerFromDayPlan", &strings.pickerFromDayPlan)
        read("labelPickerFromToDoList", &strings.pickerFromToDoList)
        read("labelPickerFromSearch", &strings.pickerFromSearch)
        read("titleCreateTask", &strings.createTaskTitle)
        read("labelTaskName", &strings.taskNameLabel)
        read("placeholderTaskName", &strings.taskNamePlaceholder)
        read("labelTaskDescription", &strings.taskDescriptionLabel)
        read("placeholderTaskDescription", &strings.taskDescriptionPlaceholder)
        read("labelTaskDueDate", &strings.taskDueDateLabel)
        read("buttonCreateTask", &strings.createTaskButton)
        read("labelFocusMusic", &strings.focusMusicLabel)
        read("labelNotes", &strings.notesLabel)
        read("labelBrainDump", &strings.brainDumpLabel)
        read("placeholderBrainDump", &strings.brainDumpPlaceholder)
        read("buttonSeeOtherNotes", &strings.seeOtherNotes)
        read("titleEditTask", &strings.editTaskTitle)
        read("buttonSaveTask", &strings.saveTaskButton)
        read("labelTaskStatus", &strings.taskStatusLabel)
        read("labelOutcome", &strings.outcomeLabel)
        read("labelPerspiration", &strings.perspirationLabel)
        read("labelAddToProject", &strings.projectLabel)
        read("labelNoProject", &strings.noProjectOption)
        read("errorCouldNotSaveTask", &strings.couldNotSaveTask)
        read("errorCouldNotLoadTask", &strings.couldNotLoadTask)
        read("errorTaskServerUpdateRequired", &strings.taskServerUpdateRequired)
        read("errorTaskChanged", &strings.taskChanged)
        read("outcomeNotSet", &strings.outcomeNotSet)
        read("currentOutcome", &strings.currentOutcome)
        read("musicLibrary", &strings.musicLibrary)
        read("musicEmpty", &strings.musicEmpty)
        read("musicVolume", &strings.musicVolume)
        read("blockListLabel", &strings.blockListLabel)
        read("changeBlockList", &strings.changeBlockList)
        read("placeholderAddSubtask", &strings.subtaskPlaceholder)
        read("buttonAddSubtask", &strings.addSubtask)
        read("buttonRemoveSubtask", &strings.removeSubtask)
        read("buttonRetry", &strings.retryButton)
        read("errorSubtaskChanged", &strings.subtaskChanged)
        read("menuEditTask", &strings.editTaskMenuItem)
        read("labelBandLow", &strings.bandLow)
        read("labelBandNormal", &strings.bandNormal)
        read("labelBandHigh", &strings.bandHigh)
        read("labelBandCritical", &strings.bandCritical)
        read("titleAddFilters", &strings.addFiltersTitle)
        read("toolTipFilterTasks", &strings.filterTasksTooltip)
        read("labelFilterPerspiration", &strings.filterPerspirationLabel)
        read("chipFullSpoons", &strings.filterFullSpoons)
        read("chipLowSpoons", &strings.filterLowSpoons)
        read("labelFilterProject", &strings.filterProjectLabel)
        read("placeholderSearchProject", &strings.searchProjectPlaceholder)
        read("labelFilterDueDate", &strings.filterDueDateLabel)
        read("labelDueOverdue", &strings.dueOverdue)
        read("labelDueToday", &strings.dueToday)
        read("labelDueInAWeek", &strings.dueInAWeek)
        read("labelDueInTwoWeeks", &strings.dueInTwoWeeks)
        read("labelDueInAMonth", &strings.dueInAMonth)
        read("labelDaysFromToday", &strings.daysFromToday)
        read("buttonAddFilters", &strings.addFiltersButton)
        read("buttonAddSingleFilter", &strings.addSingleFilterButton)
        read("labelTopScoreBadge", &strings.topScoreBadge)
        read("titleEndSessionConfirm", &strings.endSessionConfirmTitle)
        read("bodyEndSessionConfirm", &strings.endSessionConfirmBody)
        return strings
    }

    /// Copy this screen shares with the rest of the app — reused rather than duplicated so the
    /// translations stay in one place.
    private mutating func applyCommonBlocks() {
        if let progress = configjson.value(forKey: "focusProgressInfo") as? NSDictionary {
            if let text = progress.value(forKey: "pauseText") as? String, !text.isEmpty { pauseTooltip = text }
            if let text = progress.value(forKey: "resumeText") as? String, !text.isEmpty { resumeTooltip = text }
            if let text = progress.value(forKey: "endFocusSessionText") as? String, !text.isEmpty {
                endSessionTooltip = text
                endSessionConfirmButton = text
            }
        }
        if let common = configjson.value(forKey: "common") as? NSDictionary {
            if let text = common.value(forKey: "buttonCancelText") as? String, !text.isEmpty { cancelButton = text }
            if let text = common.value(forKey: "notStartedText") as? String, !text.isEmpty { statusNotStarted = text }
            if let text = common.value(forKey: "inProgressText") as? String, !text.isEmpty { statusInProgress = text }
            if let text = common.value(forKey: "completedText") as? String, !text.isEmpty { statusCompleted = text }
        }
        if let goalInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary {
            if let text = goalInfo.value(forKey: "cannotChangeIntentionInSuperStrictText") as? String, !text.isEmpty {
                focusGoalLockedNotice = text
            }
            if let text = goalInfo.value(forKey: "fetchingTaskText") as? String, !text.isEmpty { fetchingTasks = text }
            if let text = goalInfo.value(forKey: "SavingTaskText") as? String, !text.isEmpty { savingTask = text }
        }
        if let notes = configjson.value(forKey: "notesViewInfo") as? NSDictionary {
            if let text = notes.value(forKey: "closeText") as? String, !text.isEmpty { closeButton = text }
        }
    }
}
