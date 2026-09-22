//
//  ToDoStrings.swift
//  Focus Bear
//
//  User-facing strings for the native To-do List / Projects screens, config-driven like every other
//  screen (`configjson["toDoListViewInfo"]`, English fallbacks below). Spanish lives in the assets
//  repo config-es.json. Keys map 1:1 onto the web dashboard's `to_do_procrastinate.*`, `todos.*`,
//  `portfolio.*` and `project.*` translation keys so the two clients read the same.
//

import Foundation

enum ToDoStringKey: String, CaseIterable {
    // Tabs / shell
    case tabTasks = "tabTasksText"
    case tabProjects = "tabProjectsText"
    case close = "closeText"
    case cancel = "cancelText"
    case save = "saveText"
    case saving = "savingText"
    case delete = "deleteText"
    case add = "addText"
    case done = "doneText"
    case discard = "discardText"
    case loading = "loadingText"
    case requestFailed = "requestFailedText"
    // Toolbar
    case newTask = "newTaskText"
    case searchPlaceholder = "searchPlaceholder"
    case filter = "filterText"
    case moreOptions = "moreOptionsText"
    case sortSmart = "sortSmartText"
    case sortSmartTooltip = "sortSmartTooltip"
    case sortChronological = "sortChronologicalText"
    case sortChronologicalTooltip = "sortChronologicalTooltip"
    case sortDueDate = "sortDueDateText"
    case sortDueDateTooltip = "sortDueDateTooltip"
    case brainDumpToTasks = "brainDumpToTasksText"
    case exportCsv = "exportCsvText"
    case exportCsvTooltip = "exportCsvTooltip"
    case eisenhowerMatrix = "eisenhowerMatrixText"
    case procrastinate = "procrastinateText"
    case manageIntegrations = "manageIntegrationsText"
    case refresh = "refreshText"
    // Filters
    case filterDueDate = "filterDueDateText"
    case filterEnergyLevel = "filterEnergyLevelText"
    case filterProject = "filterProjectText"
    case filterAll = "filterAllText"
    case lowSpoons = "lowSpoonsText"
    case lowSpoonsSubtitle = "lowSpoonsSubtitle"
    case fullSpoons = "fullSpoonsText"
    case fullSpoonsSubtitle = "fullSpoonsSubtitle"
    case dueToday = "dueTodayText"
    case dueThisWeek = "dueThisWeekText"
    case dueNextWeek = "dueNextWeekText"
    case next30Days = "next30DaysText"
    case clearFilters = "clearFiltersText"
    // Sections / list
    case sectionDoing = "sectionDoingText"
    case sectionToDo = "sectionToDoText"
    case sectionDone = "sectionDoneText"
    case sectionEmpty = "sectionEmptyText"
    case addYourFirstTask = "addYourFirstTaskText"
    case noTasksMatchFilters = "noTasksMatchFiltersText"
    case couldNotFindTasks = "couldNotFindTasksText"
    case loadMore = "loadMoreText"
    // Row
    case markComplete = "markCompleteText"
    case markCompleteShort = "markCompleteShortText"
    case markIncomplete = "markIncompleteText"
    case snooze = "snoozeText"
    case edit = "editText"
    case editTask = "editTaskText"
    case taskDescription = "taskDescriptionText"
    case subtasks = "subtasksText"
    case dueShort = "dueShortText"
    case createdShort = "createdShortText"
    case topShort = "topShortText"
    case created = "createdText"
    case today = "todayText"
    case tomorrow = "tomorrowText"
    case yesterday = "yesterdayText"
    case noDueDate = "noDueDateText"
    // Due-date popover
    case editDueDate = "editDueDateText"
    case dueDatePlaceholder = "dueDatePlaceholder"
    case unrecognisedDate = "unrecognisedDateText"
    case dueDateGrammarHelp = "dueDateGrammarHelp"
    case nextWeek = "nextWeekText"
    case clear = "clearText"
    // Editor
    case createTaskTitle = "createTaskTitle"
    case editTaskTitle = "editTaskTitle"
    case addATask = "addATaskPlaceholder"
    case titleIsNeeded = "titleIsNeededText"
    case unsavedChanges = "unsavedChangesText"
    case status = "statusText"
    case statusNotStarted = "statusNotStartedText"
    case statusInProgress = "statusInProgressText"
    case statusCompleted = "statusCompletedText"
    case statusAppliesTo = "statusAppliesToText"
    case due = "dueText"
    case exactDate = "exactDateText"
    case inAFewDays = "inAFewDaysText"
    case inTwoWeeks = "inTwoWeeksText"
    case inAMonth = "inAMonthText"
    case inAFewMonths = "inAFewMonthsText"
    case inAYear = "inAYearText"
    case neverDoThis = "neverDoThisText"
    case topScore = "topScoreText"
    case timelineDueDate = "timelineDueDateText"
    case outcome = "outcomeText"
    case perspiration = "perspirationText"
    case scoreFormula = "scoreFormulaText"
    // Outcome is a SHIFTABILITY scale — how far this can be pushed back, not how much it matters
    // or how urgent it is. Every rung is phrased that way ("can't shift", "a few days", "a year or
    // more"), which is what tells the planner it may only ever resist a move and must never win an
    // earlier slot (reports 2026-09-15_20-12-49, 2026-09-16_08-52-35).
    //
    // Keyed by RUNG, not by the duration a rung currently names: the first set of keys was named
    // after its words (`outcomePostponeWeeksText`), and when the scale was re-cut those names began
    // describing the wrong rung. Position is the part that is stable. The old keys are left in
    // place untouched because other platforms read them (CLAUDE.md: add new keys, never repurpose).
    case outcomeBand1 = "outcomeBand1Text"
    case outcomeBand2 = "outcomeBand2Text"
    case outcomeBand3 = "outcomeBand3Text"
    case outcomeBand4 = "outcomeBand4Text"
    case outcomeBand5 = "outcomeBand5Text"
    case outcomePostponeYears = "outcomePostponeYearsText"
    case outcomePostponeAYear = "outcomePostponeAYearText"
    case outcomePostponeMonths = "outcomePostponeMonthsText"
    case outcomePostponeWeeks = "outcomePostponeWeeksText"
    case outcomeHardDeadline = "outcomeHardDeadlineText"
    case perspirationFiveMinutes = "perspirationFiveMinutesText"
    case perspirationFifteenMinutes = "perspirationFifteenMinutesText"
    case perspirationHalfAnHour = "perspirationHalfAnHourText"
    case perspirationAnHour = "perspirationAnHourText"
    case perspirationHalfADay = "perspirationHalfADayText"
    case perspirationADay = "perspirationADayText"
    case perspirationAWeek = "perspirationAWeekText"
    case projects = "projectsText"
    case searchProjectsPlaceholder = "searchProjectsPlaceholder"
    case noExistingProjects = "noExistingProjectsText"
    case noProjectsFound = "noProjectsFoundText"
    case createProjectNamed = "createProjectNamedText"
    case assignee = "assigneeText"
    case assigneeNotChanged = "assigneeNotChangedText"
    case unassigned = "unassignedText"
    case me = "meText"
    case description = "descriptionText"
    case createSubtasks = "createSubtasksText"
    case addASubtask = "addASubtaskPlaceholder"
    case generateSubtasksViaAI = "generateSubtasksViaAIText"
    case addSubtask = "addSubtaskText"
    case quadrant = "quadrantText"
    case quadrantDo = "quadrantDoText"
    case quadrantDecide = "quadrantDecideText"
    case quadrantDelegate = "quadrantDelegateText"
    case quadrantDelete = "quadrantDeleteText"
    case quadrantUrgentImportant = "quadrantUrgentImportantText"
    case quadrantImportantNotUrgent = "quadrantImportantNotUrgentText"
    case quadrantNotImportantUrgent = "quadrantNotImportantUrgentText"
    case quadrantNotImportantNotUrgent = "quadrantNotImportantNotUrgentText"
    case important = "importantText"
    case notImportant = "notImportantText"
    case urgent = "urgentText"
    case notUrgent = "notUrgentText"
    case objective = "objectiveText"
    case objectivePlaceholder = "objectivePlaceholder"
    case duration = "durationText"
    case durationMinutes = "durationMinutesText"
    case comments = "commentsText"
    case noCommentsYet = "noCommentsYetText"
    case addCommentPlaceholder = "addCommentPlaceholder"
    case reactions = "reactionsText"
    case addReaction = "addReactionText"
    case deleteTaskConfirmation = "deleteTaskConfirmationText"
    case deleteTask = "deleteTaskText"
    // Toasts
    case taskCreated = "taskCreatedText"
    case couldNotCreateTask = "couldNotCreateTaskText"
    case taskUpdated = "taskUpdatedText"
    case couldNotUpdateTask = "couldNotUpdateTaskText"
    case taskDeleted = "taskDeletedText"
    case couldNotDeleteTask = "couldNotDeleteTaskText"
    case taskCompletedSingle = "taskCompletedSingleText"
    case taskCompletedMultiple = "taskCompletedMultipleText"
    case taskCompletedPhrases = "taskCompletedPhrases"
    case subtasksGenerated = "subtasksGeneratedText"
    case couldNotGenerateSubtasks = "couldNotGenerateSubtasksText"
    case commentAdded = "commentAddedText"
    case couldNotAddComment = "couldNotAddCommentText"
    case commentDeleted = "commentDeletedText"
    case couldNotDeleteComment = "couldNotDeleteCommentText"
    case commentUpdated = "commentUpdatedText"
    case couldNotUpdateComment = "couldNotUpdateCommentText"
    case editComment = "editCommentText"
    case deleteComment = "deleteCommentText"
    case couldNotAddReaction = "couldNotAddReactionText"
    case couldNotRemoveReaction = "couldNotRemoveReactionText"
    case exportSaved = "exportSavedText"
    case exportFailed = "exportFailedText"
    case exportTruncated = "exportTruncatedText"
    // Brain dump
    case brainDumpTitle = "brainDumpTitle"
    case tasksFromBrainDump = "tasksFromBrainDumpText"
    case brainDumpPlaceholder = "brainDumpPlaceholder"
    case vagueInputPrompt = "vagueInputPromptText"
    case convertAnyway = "convertAnywayText"
    case converting = "convertingText"
    case createTasks = "createTasksText"
    case tasksWillBeCreated = "tasksWillBeCreatedText"
    case minutes = "minutesText"
    case brainDumpFailed = "brainDumpFailedText"
    case createTasksUsingAI = "createTasksUsingAIText"
    case brainDumpLimit = "brainDumpLimitText"
    case brainDumpPartialSave = "brainDumpPartialSaveText"
    case brainDumpInvalidDraft = "brainDumpInvalidDraftText"
    // Procrastinate
    case procrastinateInfo = "procrastinateInfoText"
    case url = "urlText"
    case note = "noteText"
    case invalidUrl = "invalidUrlText"
    case duplicateUrl = "duplicateUrlText"
    case deleteAll = "deleteAllText"
    case noUrlsFound = "noUrlsFoundText"
    case websitesDeleted = "websitesDeletedText"
    case couldNotDeleteWebsites = "couldNotDeleteWebsitesText"
    // Projects
    case viewWhatMatters = "viewWhatMattersText"
    case viewAllProjects = "viewAllProjectsText"
    case browseAllProjects = "browseAllProjectsText"
    case focusEmptyTitle = "focusEmptyTitle"
    case focusEmptyDescription = "focusEmptyDescription"
    case askForExtensionSection = "askForExtensionSectionText"
    case startNowSection = "startNowSectionText"
    case backBurnerSection = "backBurnerSectionText"
    case overcommittedTitle = "overcommittedTitle"
    case overcommittedDescription = "overcommittedDescription"
    case overcommittedDescriptionFallback = "overcommittedDescriptionFallback"
    case overcommittedAndMore = "overcommittedAndMoreText"
    case bucketOnTrack = "bucketOnTrackText"
    case bucketAtRisk = "bucketAtRiskText"
    case bucketCritical = "bucketCriticalText"
    case bucketNoDeadline = "bucketNoDeadlineText"
    case badgeOvercommitted = "badgeOvercommittedText"
    case badgeStartNow = "badgeStartNowText"
    case badgeSacrifice = "badgeSacrificeText"
    case badgeUnscheduled = "badgeUnscheduledText"
    case badgePushedBack = "badgePushedBackText"
    case scheduledOfRequired = "scheduledOfRequiredText"
    case projectedCompletionTooltip = "projectedCompletionTooltip"
    case nextTask = "nextTaskText"
    case nextTaskEmpty = "nextTaskEmptyText"
    case topScoreTooltip = "topScoreTooltip"
    case dueWithDate = "dueWithDateText"
    case setDueDate = "setDueDateText"
    case setOutcome = "setOutcomeText"
    case editOutcome = "editOutcomeText"
    case requiredHours = "requiredHoursText"
    case requiredHoursTooltip = "requiredHoursTooltipText"
    case recommendedDaily = "recommendedDailyText"
    case recommendedDailyTooltip = "recommendedDailyTooltip"
    case membersCount = "membersCountText"
    case tasksCount = "tasksCountText"
    case tasksToDoCount = "tasksToDoCountText"
    case memberBadge = "memberBadgeText"
    case syncedProject = "syncedProjectText"
    case syncedSourceUnavailable = "syncedSourceUnavailableText"
    case syncedSource = "syncedSourceText"
    case projectTaskCompletion = "projectTaskCompletionText"
    case projectAlphabeticalSubset = "projectAlphabeticalSubsetText"
    case projectSearchPlaceholder = "projectSearchPlaceholder"
    case projectStatusActive = "projectStatusActiveText"
    case projectStatusCompleted = "projectStatusCompletedText"
    case projectStatusArchived = "projectStatusArchivedText"
    case noProjectsYet = "noProjectsYetText"
    case createFirstProject = "createFirstProjectText"
    case noMatchingProjects = "noMatchingProjectsText"
    case tryDifferentSearch = "tryDifferentSearchText"
    case noCompletedProjects = "noCompletedProjectsText"
    case noArchivedProjects = "noArchivedProjectsText"
    case newProject = "newProjectText"
    case projectNamePlaceholder = "projectNamePlaceholder"
    case optional = "optionalText"
    case projectCreated = "projectCreatedText"
    case couldNotCreateProject = "couldNotCreateProjectText"
    case projectUpdated = "projectUpdatedText"
    case couldNotUpdateProject = "couldNotUpdateProjectText"
    case showTasksForProject = "showTasksForProjectText"
    case capacitySettings = "capacitySettingsText"
    case weeklyCapacity = "weeklyCapacityText"
    case weeklyTotal = "weeklyTotalText"
    case planningHorizon = "planningHorizonText"
    case horizonDays = "horizonDaysText"
    case capacitySaved = "capacitySavedText"
    case couldNotSaveCapacity = "couldNotSaveCapacityText"
    case pendingInvitations = "pendingInvitationsText"
    case noPendingInvitations = "noPendingInvitationsText"
    case accept = "acceptText"
    case decline = "declineText"
    case invitationAccepted = "invitationAcceptedText"
    case invitationDeclined = "invitationDeclinedText"
    case couldNotRespondInvitation = "couldNotRespondInvitationText"
    case weekdaysShort = "weekdaysShort"
    // Project detail
    case backToProjects = "backToProjectsText"
    case projectNotFound = "projectNotFoundText"
    case renameProjectHint = "renameProjectHintText"
    case attachments = "attachmentsText"
    case addAttachment = "addAttachmentText"
    case attachmentFailed = "attachmentFailedText"
    case attachmentTooLarge = "attachmentTooLargeText"
    case attachmentLimitReached = "attachmentLimitReachedText"
    case attachmentsAfterSaving = "attachmentsAfterSavingText"
    case attachmentsNeedTodo = "attachmentsNeedTodoText"
    case projectIconAutomatic = "projectIconAutomaticText"
    case projectIconChange = "projectIconChangeText"
    case projectIconSearch = "projectIconSearchText"
    case projectIconNoMatches = "projectIconNoMatchesText"
    case projectIconClear = "projectIconClearText"
    case couldNotSaveIcon = "couldNotSaveIconText"
    case projectTags = "projectTagsText"
    case addProjectTag = "addProjectTagText"
    case projectTagPlaceholder = "projectTagPlaceholderText"
    case removeProjectTag = "removeProjectTagText"
    case addProjectTagNamed = "addProjectTagNamedText"
    case projectTagSuggestions = "projectTagSuggestionsText"
    case projectTagsFull = "projectTagsFullText"
    case couldNotSaveTags = "couldNotSaveTagsText"
    case allTags = "allTagsText"
    case filterByTag = "filterByTagText"
    case noProjectsWithTag = "noProjectsWithTagText"
    case showAllTags = "showAllTagsText"
    case tagAndSearchBothActive = "tagAndSearchBothActiveText"
    case projectTagsApplyImmediately = "projectTagsApplyImmediatelyText"
    case previewAttachment = "previewAttachmentText"
    case attachmentPreviewUnavailable = "attachmentPreviewUnavailableText"
    case attachmentSaveCopy = "attachmentSaveCopyText"
    case attachmentPasteHint = "attachmentPasteHintText"
    case attachmentPastePending = "attachmentPastePendingText"
    case detailTabTasks = "detailTabTasksText"
    case detailTabNotes = "detailTabNotesText"
    case membersWithCount = "membersWithCountText"
    case settings = "settingsText"
    case leave = "leaveText"
    case leaveConfirm = "leaveConfirmText"
    case leftProject = "leftProjectText"
    case couldNotLeave = "couldNotLeaveText"
    case listView = "listViewText"
    case boardView = "boardViewText"
    case addTask = "addTaskText"
    case noTasksYet = "noTasksYetText"
    case createFirstTask = "createFirstTaskText"
    case columnToDo = "columnToDoText"
    case columnInProgress = "columnInProgressText"
    case columnDone = "columnDoneText"
    case noTasksInColumn = "noTasksInColumnText"
    case moveTo = "moveToText"
    case dropMarksComplete = "dropMarksCompleteText"
    case dropReopens = "dropReopensText"
    case inviteMember = "inviteMemberText"
    case emailPlaceholder = "emailPlaceholder"
    case invalidEmail = "invalidEmailText"
    case invite = "inviteText"
    case inviting = "invitingText"
    case roleOwner = "roleOwnerText"
    case roleAdmin = "roleAdminText"
    case roleMember = "roleMemberText"
    case invitationAcceptedStatus = "invitationAcceptedStatusText"
    case invitationPendingStatus = "invitationPendingStatusText"
    case invitationDeclinedStatus = "invitationDeclinedStatusText"
    case invitationFailedStatus = "invitationFailedStatusText"
    case you = "youText"
    case projectOwner = "projectOwnerText"
    case unknownUser = "unknownUserText"
    case removeMember = "removeMemberText"
    case invitationSent = "invitationSentText"
    case couldNotSendInvitation = "couldNotSendInvitationText"
    case resendInvitation = "resendInvitationText"
    case confirmResendInvitation = "confirmResendInvitationText"
    case invitationResent = "invitationResentText"
    case couldNotResendInvitation = "couldNotResendInvitationText"
    case invitationJustSent = "invitationJustSentText"
    case memberRemoved = "memberRemovedText"
    case couldNotRemoveMember = "couldNotRemoveMemberText"
    case memberRoleUpdated = "memberRoleUpdatedText"
    case couldNotUpdateMemberRole = "couldNotUpdateMemberRoleText"
    case name = "nameText"
    case importance = "importanceText"
    case importanceLow = "importanceLowText"
    case importanceMedium = "importanceMediumText"
    case importanceHigh = "importanceHighText"
    case importanceCritical = "importanceCriticalText"
    case customStatuses = "customStatusesText"
    case completesTask = "completesTaskText"
    case newStatusPlaceholder = "newStatusPlaceholder"
    case addStatus = "addStatusText"
    case dangerZone = "dangerZoneText"
    case deleteWarning = "deleteWarningText"
    case deleteProject = "deleteProjectText"
    case deleteProjectConfirm = "deleteProjectConfirmText"
    case projectDeleted = "projectDeletedText"
    case couldNotDeleteProject = "couldNotDeleteProjectText"
    case markCompleteProject = "markCompleteProjectText"
    case archiveProject = "archiveProjectText"
    case restoreProject = "restoreProjectText"
    case projectMarkedComplete = "projectMarkedCompleteText"
    case projectArchived = "projectArchivedText"
    case projectRestored = "projectRestoredText"
    case showAllProjects = "showAllProjectsText"
    case showFewerProjects = "showFewerProjectsText"
    case mergeProject = "mergeProjectText"
    case mergeProjectTitle = "mergeProjectTitleText"
    case mergeProjectExplanation = "mergeProjectExplanationText"
    case mergeProjectSearch = "mergeProjectSearchText"
    case mergeProjectConfirm = "mergeProjectConfirmText"
    case mergeProjectRunning = "mergeProjectRunningText"
    case mergeProjectNoDestinations = "mergeProjectNoDestinationsText"
    case projectMergeMoved = "projectMergeMovedText"
    case projectMergeSkipped = "projectMergeSkippedText"
    case projectMergeFailed = "projectMergeFailedText"
    case projectMergeArchived = "projectMergeArchivedText"
    case couldNotMergeProject = "couldNotMergeProjectText"
    case couldNotLoadProjects = "couldNotLoadProjectsText"
    case projectCompletedBanner = "projectCompletedBannerText"
    case projectArchivedBanner = "projectArchivedBannerText"
    case nameTooLong = "nameTooLongText"
    case nameOnlyDigits = "nameOnlyDigitsText"
    case createNote = "createNoteText"
    case untitledNote = "untitledNoteText"
    case renameNoteHint = "renameNoteHintText"
    case noteRenamed = "noteRenamedText"
    case couldNotRenameNote = "couldNotRenameNoteText"
    case noteBodyWebOnly = "noteBodyWebOnlyText"
    case noNotesYet = "noNotesYetText"
    case noNotesDescription = "noNotesDescriptionText"
    case lastEdited = "lastEditedText"
    case selectNoteTitle = "selectNoteTitleText"
    case editOnWeb = "editOnWebText"
    case deleteNoteConfirm = "deleteNoteConfirmText"
    case noteDeleted = "noteDeletedText"
    case couldNotDeleteNote = "couldNotDeleteNoteText"
    case couldNotCreateNote = "couldNotCreateNoteText"
    case emptyNote = "emptyNoteText"
    case showInTaskList = "showInTaskListText"
}

struct ToDoStrings {
    static let configBlockKey = "toDoListViewInfo"
    /// Placeholder tokens inside templated strings.
    static let titleToken = "<TITLE>"
    static let countToken = "<COUNT>"
    static let dateToken = "<DATE>"
    static let scoreToken = "<SCORE>"
    static let hoursToken = "<HOURS>"
    static let durationToken = "<DURATION>"
    static let projectToken = "<PROJECT>"
    static let projectsToken = "<PROJECTS>"
    static let phraseToken = "<PHRASE>"
    static let daysToken = "<DAYS>"
    static let scheduledToken = "<SCHEDULED>"
    static let totalToken = "<TOTAL>"
    /// Multi-value strings (phrases, weekday names) are stored `|`-separated.
    static let listSeparator = "|"

    /// English fallbacks, keyed by config key. Every key must also exist in config.json and the
    /// assets repo (config.json + config-es.json).
    static let fallbacks: [ToDoStringKey: String] = [
        .tabTasks: "Tasks", .tabProjects: "Projects", .close: "Close", .cancel: "Cancel", .save: "Save",
        .saving: "Saving…", .delete: "Delete", .add: "Add", .done: "Done", .discard: "Discard", .loading: "Loading…",
        .requestFailed: "Could not process the request",
        .newTask: "New Task", .searchPlaceholder: "Search...", .filter: "Filter", .moreOptions: "More Options",
        .sortSmart: "Smart", .sortSmartTooltip: "Smart sort — ADHD-friendly. Sorted by TOP score, highest priority first.",
        .sortChronological: "Newest", .sortChronologicalTooltip: "Chronological sort. Most recently created tasks first.",
        .sortDueDate: "Due date", .sortDueDateTooltip: "Due date sort. Overdue first, then soonest due. Tasks without a due date last.",
        .brainDumpToTasks: "Use AI to convert brain dump to tasks", .exportCsv: "Export CSV",
        .exportCsvTooltip: "Exports all tasks. Filtered views are not applied to the export.",
        .eisenhowerMatrix: "View Eisenhower Matrix", .procrastinate: "Procrastinate",
        .manageIntegrations: "Manage integrations on the web", .refresh: "Refresh",
        .filterDueDate: "Due Date", .filterEnergyLevel: "Energy Level", .filterProject: "Project", .filterAll: "All",
        .lowSpoons: "Low spoons", .lowSpoonsSubtitle: "Perspiration level 0 - 3", .fullSpoons: "Full spoons",
        .fullSpoonsSubtitle: "Perspiration level 4 - 10", .dueToday: "Due Today", .dueThisWeek: "Due This Week",
        .dueNextWeek: "Due Next Week", .next30Days: "Next 30 Days", .clearFilters: "Clear filters",
        .sectionDoing: "Doing", .sectionToDo: "To do", .sectionDone: "Done", .sectionEmpty: "No tasks in this section.",
        .addYourFirstTask: "🚀 Add your first task", .noTasksMatchFilters: "No tasks match your filters",
        .couldNotFindTasks: "Could not find any tasks", .loadMore: "Load more",
        .markComplete: "Mark \"<TITLE>\" complete", .markCompleteShort: "Mark complete", .markIncomplete: "Mark incomplete",
        .snooze: "Snooze", .edit: "Edit", .editTask: "Edit \"<TITLE>\"", .taskDescription: "Task description",
        .subtasks: "Subtasks", .dueShort: "Due", .createdShort: "Created", .topShort: "TOP", .created: "Created <DATE>",
        .today: "Today", .tomorrow: "Tomorrow", .yesterday: "Yesterday", .noDueDate: "No due date",
        .editDueDate: "Edit due date", .dueDatePlaceholder: "e.g. 2d, 30th, fri", .unrecognisedDate: "Unrecognised date",
        .dueDateGrammarHelp: "Type a date and press Return: 2d, 3w, 1m (months), 2y (years), -1d for yesterday, fri, next fri, tomorrow, 28th, 28 sep, 25/9, 2026-09-25, in 2 days",
        .nextWeek: "Next week", .clear: "Clear",
        .createTaskTitle: "New task", .editTaskTitle: "Edit task", .addATask: "Add a task",
        .titleIsNeeded: "Write a title to save the task", .unsavedChanges: "Your changes will be lost. Discard them?",
        .status: "Status", .statusNotStarted: "Not Started", .statusInProgress: "In Progress", .statusCompleted: "Completed",
        .statusAppliesTo: "Status applies to", .due: "Due", .exactDate: "Exact Date", .inAFewDays: "In a Few Days",
        .inTwoWeeks: "In Two Weeks", .inAMonth: "In a Month", .inAFewMonths: "In a Few Months", .inAYear: "In a Year",
        .neverDoThis: "Hah I'll never actually do this", .topScore: "TOP score", .timelineDueDate: "Timeline (due date)",
        .outcome: "Outcome", .perspiration: "Perspiration", .scoreFormula: "Score → T × O ÷ P = <SCORE>",
        .outcomeBand1: "Can postpone a year or more", .outcomeBand2: "Can postpone a few months",
        .outcomeBand3: "Can postpone a few weeks", .outcomeBand4: "Can postpone a few days",
        .outcomeBand5: "Hard deadline — can't shift",
        .outcomePostponeYears: "Can postpone for years", .outcomePostponeAYear: "Can postpone for a year",
        .outcomePostponeMonths: "Can postpone a few months", .outcomePostponeWeeks: "Can postpone a few weeks",
        .outcomeHardDeadline: "Hard deadline — can't move",
        .perspirationFiveMinutes: "5 minutes job", .perspirationFifteenMinutes: "15 minutes work",
        .perspirationHalfAnHour: "Half an hour", .perspirationAnHour: "An hour", .perspirationHalfADay: "Half a day",
        .perspirationADay: "A day", .perspirationAWeek: "A week",
        .projects: "Projects", .searchProjectsPlaceholder: "Search projects...", .noExistingProjects: "No existing projects",
        .noProjectsFound: "No projects found", .createProjectNamed: "Create “<PROJECT>”",
        .assignee: "Assignee", .unassigned: "Unassigned", .me: "Me", .description: "Description",
        .assigneeNotChanged: "Only the person who created this task can change who it’s assigned to.",
        .createSubtasks: "Create subtasks", .addASubtask: "Add a subtask…", .generateSubtasksViaAI: "Generate Subtasks via AI",
        .addSubtask: "Add Subtask", .quadrant: "Eisenhower quadrant", .quadrantDo: "Do", .quadrantDecide: "Decide",
        .quadrantDelegate: "Delegate", .quadrantDelete: "Delete", .quadrantUrgentImportant: "Urgent and Important",
        .quadrantImportantNotUrgent: "Important but not urgent", .quadrantNotImportantUrgent: "Not important and urgent",
        .quadrantNotImportantNotUrgent: "Not important and not urgent", .important: "Important",
        .notImportant: "Not important", .urgent: "Urgent", .notUrgent: "Not urgent",
        .objective: "Objective", .objectivePlaceholder: "Why do you want to do this task?", .duration: "Duration",
        .durationMinutes: "<COUNT> min", .comments: "Comments", .noCommentsYet: "No comments yet",
        .addCommentPlaceholder: "Add a comment...", .reactions: "Reactions", .addReaction: "Add reaction",
        .deleteTaskConfirmation: "Are you sure you want to delete this task?", .deleteTask: "Delete task",
        .taskCreated: "Task created successfully", .couldNotCreateTask: "Could not create the task",
        .taskUpdated: "Task updated successfully", .couldNotUpdateTask: "Could not update the status of task with title: <TITLE>",
        .taskDeleted: "Task deleted successfully", .couldNotDeleteTask: "Could not delete the task",
        .taskCompletedSingle: "<PHRASE>, '<TITLE>' completed!", .taskCompletedMultiple: "<PHRASE>, you're on a roll! <COUNT> tasks completed",
        .taskCompletedPhrases: "Woah|Cool|Awesome|Incredible|Fantastic",
        .subtasksGenerated: "Subtasks generated successfully", .couldNotGenerateSubtasks: "Could not generate subtasks",
        .commentAdded: "Comment added successfully", .couldNotAddComment: "Could not add comment",
        .commentDeleted: "Comment deleted successfully", .couldNotDeleteComment: "Could not delete comment",
        .commentUpdated: "Comment updated successfully", .couldNotUpdateComment: "Could not update comment",
        .editComment: "Edit comment", .deleteComment: "Delete comment",
        .couldNotAddReaction: "Could not add reaction", .couldNotRemoveReaction: "Could not remove reaction",
        .exportSaved: "Tasks exported", .exportFailed: "Couldn't load all tasks — exported the tasks already loaded.",
        .exportTruncated: "Export may be incomplete — the task list is very large.",
        .brainDumpTitle: "Brain dump", .tasksFromBrainDump: "Tasks from Brain Dump",
        .brainDumpPlaceholder: "Dump down ideas you have so you don't forget",
        .vagueInputPrompt: "Your input seems a bit brief. Adding more details will help generate better tasks. Try describing what you want to accomplish in more detail.",
        .convertAnyway: "Convert anyway", .converting: "Converting…", .createTasks: "Create tasks",
        .tasksWillBeCreated: "<COUNT> tasks will be created", .minutes: "minutes",
        .createTasksUsingAI: "Create tasks using AI",
        .brainDumpLimit: "Use up to <COUNT> characters for task suggestions. Your original note is unchanged.",
        .brainDumpPartialSave: "Confirmed <COUNT> tasks saved. The remaining tasks are still here. Review them and try again.",
        .brainDumpInvalidDraft: "Give each task a title and a valid estimate greater than zero minutes, or remove it before saving.",
        .brainDumpFailed: "Sorry, we were unable to convert your brain dump. Please try again.",
        .procrastinateInfo: "Save distracting links for later so you can get back to your task now.",
        .url: "URL", .note: "Note", .invalidUrl: "Enter a valid URL", .duplicateUrl: "This URL is already saved",
        .deleteAll: "Delete All", .noUrlsFound: "No URLs found!", .websitesDeleted: "Websites deleted successfully",
        .couldNotDeleteWebsites: "Couldn't delete saved websites",
        .viewWhatMatters: "What matters", .viewAllProjects: "All projects", .browseAllProjects: "Browse all projects",
        .focusEmptyTitle: "Nothing needs attention this week",
        .focusEmptyDescription: "You're clear for now. Browse all projects to plan ahead or create something new.",
        .askForExtensionSection: "Ask for an extension", .startNowSection: "Still achievable - start now",
        .backBurnerSection: "Backburner - plenty of time", .overcommittedTitle: "This plan is overloaded",
        .overcommittedDescription: "There's more work here than the time available. An extension on these would ease the squeeze: <PROJECTS>.",
        .overcommittedDescriptionFallback: "There's more work here than the time available. An extension on your highest-priority projects would ease the squeeze.",
        .overcommittedAndMore: "and <COUNT> more", .bucketOnTrack: "On track", .bucketAtRisk: "At risk",
        .bucketCritical: "Critical", .bucketNoDeadline: "No deadline", .badgeOvercommitted: "Overloaded",
        .badgeStartNow: "Start now", .badgeSacrifice: "Consider dropping", .badgeUnscheduled: "Not scheduled",
        .badgePushedBack: "Pushed back", .scheduledOfRequired: "Scheduled <SCHEDULED> of <TOTAL>",
        .projectedCompletionTooltip: "Projected to finish <DATE> based on your Day Plan", .nextTask: "Next",
        .nextTaskEmpty: "No effort estimate — add tasks to plan next steps",
        .topScoreTooltip: "TOP ranks which task to do next. Higher means more urgent and valuable relative to effort.",
        .dueWithDate: "Due: <DATE>", .setDueDate: "Set due date", .requiredHours: "<DURATION> left",
        .setOutcome: "Set outcome", .editOutcome: "Edit outcome",
        .requiredHoursTooltip: "Time still to do on this project. Finished tasks aren't counted.",
        .recommendedDaily: "<DURATION>/day to finish",
        .recommendedDailyTooltip: "Work about <DURATION> each day to finish by the due date",
        .membersCount: "<COUNT> members", .tasksCount: "<COUNT> tasks", .tasksToDoCount: "<COUNT> to do", .memberBadge: "Member", .syncedProject: "Synced project",
        .syncedSourceUnavailable: "Synced project · source unavailable",
        .syncedSource: "Synced from <SOURCE>",
        .projectTaskCompletion: "<PERCENT>% complete (<DONE>/<TOTAL> tasks)",
        .projectAlphabeticalSubset: "Loaded projects are shown alphabetically. Load more to include the rest.",
        .projectSearchPlaceholder: "Search projects…", .projectStatusActive: "Active",
        .projectStatusCompleted: "Completed", .projectStatusArchived: "Archived", .noProjectsYet: "No projects yet",
        .createFirstProject: "Create your first project to get started", .noMatchingProjects: "No matching projects",
        .tryDifferentSearch: "Try a different search term or clear your search.",
        .noCompletedProjects: "No completed projects", .noArchivedProjects: "No archived projects",
        .newProject: "New Project", .projectNamePlaceholder: "Project name", .optional: "Optional",
        .projectCreated: "Project created successfully", .couldNotCreateProject: "Could not create project",
        .projectUpdated: "Project updated successfully", .couldNotUpdateProject: "Could not update project",
        .showTasksForProject: "Show tasks", .capacitySettings: "Time budget",
        .weeklyCapacity: "Weekly capacity (hours per day)", .weeklyTotal: "Weekly capacity: <HOURS> hours",
        .planningHorizon: "Planning horizon", .horizonDays: "<DAYS> days", .capacitySaved: "Capacity settings saved",
        .couldNotSaveCapacity: "Could not save capacity settings", .pendingInvitations: "Pending Invitations",
        .noPendingInvitations: "No pending invitations", .accept: "Accept", .decline: "Decline",
        .invitationAccepted: "Invitation accepted successfully", .invitationDeclined: "Invitation declined successfully",
        .couldNotRespondInvitation: "Could not respond to the invitation",
        .weekdaysShort: "Mon|Tue|Wed|Thu|Fri|Sat|Sun",
        .backToProjects: "Back to Projects",
        .projectNotFound: "Project not found",
        .renameProjectHint: "Click to rename this project",
        .attachments: "Attachments", .addAttachment: "Add file…",
        .attachmentFailed: "Couldn't attach that file. Try again.",
        .attachmentTooLarge: "Files must be 20 MB or smaller.",
        .attachmentLimitReached: "A task can hold 20 attachments.",
        .attachmentsAfterSaving: "Save the task first, then you can attach files to it.",
        .attachmentsNeedTodo: "Files are stored on this task's to-do. It hasn't synced to your to-do list yet, so nothing can be attached — reopen these details once it has.",
        .projectIconAutomatic: "Focus Bear picks this icon automatically",
        .projectIconChange: "Change icon",
        .projectIconSearch: "Search emoji, or paste one",
        .projectIconNoMatches: "No emoji match that",
        .projectIconClear: "Use the automatic icon",
        .couldNotSaveIcon: "Could not save the icon",
        .projectTags: "Tags",
        .addProjectTag: "Add tag",
        .projectTagPlaceholder: "e.g. phd",
        .removeProjectTag: "Remove \"<TITLE>\"",
        .addProjectTagNamed: "Add \"<TITLE>\"",
        .projectTagSuggestions: "Tags you already use",
        .projectTagsFull: "A project can have up to 25 tags",
        .couldNotSaveTags: "Could not save the tags",
        .allTags: "All tags",
        .filterByTag: "Filter by tag",
        .noProjectsWithTag: "No projects tagged \"<TITLE>\"",
        .showAllTags: "Show all tags",
        .tagAndSearchBothActive: "A search is also active",
        .projectTagsApplyImmediately: "Tag changes save straight away",
        .previewAttachment: "Preview this file",
        .attachmentPreviewUnavailable: "Focus Bear can't show this kind of file. Save a copy to open it yourself.",
        .attachmentSaveCopy: "Save a copy…",
        .attachmentPasteHint: "Or copy an image and press Command-V to attach it.",
        .attachmentPastePending: "Image pasted — it will be attached once this task syncs.",
        .detailTabTasks: "Tasks",
        .detailTabNotes: "Notes",
        .membersWithCount: "Members (<COUNT>)",
        .settings: "Settings",
        .leave: "Leave",
        .leaveConfirm: "Are you sure you want to leave this project?",
        .leftProject: "You left the project",
        .couldNotLeave: "Could not leave the project",
        .listView: "List",
        .boardView: "Board",
        .addTask: "Add task",
        .noTasksYet: "No tasks yet",
        .createFirstTask: "Create your first task to get started",
        .columnToDo: "To Do",
        .columnInProgress: "In Progress",
        .columnDone: "Done",
        .noTasksInColumn: "No tasks",
        .moveTo: "Move to",
        .dropMarksComplete: "Completes this task", .dropReopens: "Reopens this task",
        .inviteMember: "Invite Member",
        .emailPlaceholder: "Enter email address",
        .invalidEmail: "Please enter a valid email address.",
        .invite: "Invite",
        .inviting: "Inviting...",
        .roleOwner: "Owner",
        .roleAdmin: "Admin",
        .roleMember: "Member",
        .invitationAcceptedStatus: "Accepted",
        .invitationPendingStatus: "Pending",
        .invitationDeclinedStatus: "Declined",
        .invitationFailedStatus: "Not delivered",
        .you: "You",
        .projectOwner: "Project Owner",
        .unknownUser: "Unknown User",
        .removeMember: "Remove member",
        .invitationSent: "Invitation sent successfully",
        .couldNotSendInvitation: "Could not send invitation",
        .resendInvitation: "Resend invitation",
        .confirmResendInvitation: "Click again to resend",
        .invitationResent: "Invitation sent again",
        .couldNotResendInvitation: "Could not resend invitation",
        .invitationJustSent: "Just sent — try again in a minute",
        .memberRemoved: "Member removed successfully",
        .couldNotRemoveMember: "Could not remove member",
        .memberRoleUpdated: "Member role updated successfully",
        .couldNotUpdateMemberRole: "Could not update member role",
        .name: "Name",
        .importance: "Importance",
        .importanceLow: "Low",
        .importanceMedium: "Medium",
        .importanceHigh: "High",
        .importanceCritical: "Critical",
        .customStatuses: "Custom Statuses",
        .completesTask: "Completes task",
        .newStatusPlaceholder: "New status name…",
        .addStatus: "Add Status",
        .dangerZone: "Danger Zone",
        .deleteWarning: "This action cannot be undone.",
        .deleteProject: "Delete Project",
        .deleteProjectConfirm: "Are you sure you want to delete this project? This action cannot be undone.",
        .projectDeleted: "Project deleted successfully",
        .couldNotDeleteProject: "Could not delete project",
        .showAllProjects: "Show all <COUNT>",
        .showFewerProjects: "Show fewer",
        .mergeProject: "Merge into another project…",
        .mergeProjectTitle: "Merge <PROJECT> into…",
        .mergeProjectExplanation: "Every task moves to the project you pick, and <PROJECT> is archived once it's empty. Tasks synced from another tool stay where they are.",
        .mergeProjectSearch: "Search projects...",
        .mergeProjectConfirm: "Merge",
        .mergeProjectRunning: "Moving tasks…",
        .mergeProjectNoDestinations: "No other active project to merge into.",
        .projectMergeMoved: "Moved <COUNT> tasks into <PROJECT>",
        .projectMergeSkipped: "<COUNT> synced tasks stayed with their own tool",
        .projectMergeFailed: "<COUNT> tasks could not be moved",
        .projectMergeArchived: "<PROJECT> is empty and has been archived",
        .couldNotMergeProject: "Could not merge the project. Nothing was changed.",
        .couldNotLoadProjects: "Could not load your projects",
        .markCompleteProject: "Mark complete",
        .archiveProject: "Archive project",
        .restoreProject: "Restore to active",
        .projectMarkedComplete: "Project marked complete",
        .projectArchived: "Project archived",
        .projectRestored: "Project restored to active",
        .projectCompletedBanner: "This project is complete. It's hidden from your active list and portfolio.",
        .projectArchivedBanner: "This project is archived. It's hidden from your active list and portfolio.",
        .nameTooLong: "Project name is too long (max 80 characters)",
        .nameOnlyDigits: "Project name cannot be only numbers",
        .createNote: "Create note",
        .untitledNote: "Untitled note",
        .renameNoteHint: "Click to rename this note",
        .noteRenamed: "Note renamed",
        .couldNotRenameNote: "Could not rename the note",
        .noteBodyWebOnly: "The note body is edited on the web, where several people can type in it at once. You can rename, create and delete notes here.",
        .noNotesYet: "No notes yet",
        .noNotesDescription: "Create a shared note for everyone in this project.",
        .lastEdited: "Last edited <DATE>",
        .selectNoteTitle: "Open a note to read it",
        .editOnWeb: "Edit on the web",
        .deleteNoteConfirm: "Delete this note? This cannot be undone.",
        .noteDeleted: "Note deleted",
        .couldNotDeleteNote: "Could not delete the note",
        .couldNotCreateNote: "Could not create the note",
        .emptyNote: "This note is empty.",
        .showInTaskList: "Show in task list",
    ]

    private var values: [ToDoStringKey: String]

    subscript(_ key: ToDoStringKey) -> String {
        values[key] ?? ToDoStrings.fallbacks[key] ?? key.rawValue
    }

    /// Replaces one `<TOKEN>` placeholder.
    func format(_ key: ToDoStringKey, _ token: String, _ value: String) -> String {
        self[key].replacingOccurrences(of: token, with: value)
    }

    func format(_ key: ToDoStringKey, _ replacements: [String: String]) -> String {
        replacements.reduce(self[key]) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
    }

    /// A `|`-separated list value (phrases, weekday names).
    func list(_ key: ToDoStringKey) -> [String] {
        self[key].components(separatedBy: ToDoStrings.listSeparator).map { $0.trimmingCharacters(in: .whitespaces) }
    }

    init(values: [ToDoStringKey: String] = [:]) {
        self.values = values
    }

    static func load() -> ToDoStrings {
        let language = BundledConfigLanguage.code()
        var values: [ToDoStringKey: String] = [:]
        // Keep newly shipped copy translated even when downloaded config predates this screen.
        if let bundled = bundledValues[language] {
            for key in ToDoStringKey.allCases { if let value = bundled[key.rawValue] { values[key] = value } }
        }
        if let info = configjson.value(forKey: configBlockKey) as? NSDictionary {
            for key in ToDoStringKey.allCases {
                if let value = info.value(forKey: key.rawValue) as? String, !value.isEmpty { values[key] = value }
            }
        }
        return ToDoStrings(values: values)
    }

    private static let bundledValues: [String: [String: String]] = {
        var result: [String: [String: String]] = [:]
        for (language, file) in BundledConfigLanguage.all {
            guard let url = Bundle.main.url(forResource: file, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let values = json[configBlockKey] as? [String: String] else { continue }
            result[language] = values
        }
        return result
    }()

    // MARK: Derived labels

    func projectSyncSource(_ project: Project) -> String {
        let names = ["zoho": "Zoho", "clickup": "ClickUp", "trello": "Trello", "jira": "Jira",
                     "asana": "Asana", "monday": "monday.com", "google": "Google", "microsoft": "Microsoft"]
        guard project.isSynced, let platform = project.synced_platform, let name = names[platform] else {
            return self[.syncedSourceUnavailable]
        }
        return format(.syncedSource, ["<SOURCE>": name])
    }

    /// One sentence for a finished merge: what moved, plus anything left behind. The parts are
    /// separate strings so a translation can order them naturally.
    func projectMergeResult(moved: Int, skipped: Int, failed: Int, target: String) -> String {
        var parts = [format(.projectMergeMoved, [ToDoStrings.countToken: "\(moved)",
                                                 ToDoStrings.projectToken: target])]
        if skipped > 0 { parts.append(format(.projectMergeSkipped, [ToDoStrings.countToken: "\(skipped)"])) }
        if failed > 0 { parts.append(format(.projectMergeFailed, [ToDoStrings.countToken: "\(failed)"])) }
        return parts.joined(separator: ". ")
    }

    func projectMergeArchived(_ name: String) -> String {
        format(.projectMergeArchived, [ToDoStrings.projectToken: name])
    }

    func sectionTitles() -> [ToDoStatus: String] {
        [.inProgress: self[.sectionDoing], .notStarted: self[.sectionToDo], .completed: self[.sectionDone]]
    }

    func statusLabel(_ status: ToDoStatus) -> String {
        switch status {
        case .notStarted: return self[.statusNotStarted]
        case .inProgress: return self[.statusInProgress]
        case .completed: return self[.statusCompleted]
        }
    }

    /// The ONE definition of the outcome scale, for tasks and for projects alike — every picker and
    /// every chip in the app reads this, so the two screens cannot describe the same number
    /// differently again (report 2026-09-15_20-12-49).
    ///
    /// The bands are the wire `/10` values behind each displayed `/5` step, and they line up exactly
    /// with `LocalTimeForecast.postponementDays`, which plans against the same thresholds: 5/5 = no
    /// slack, 4/5 ≈ a few days, 3/5 ≈ a few weeks, 2/5 ≈ a few months, 1/5 no finite limit. The
    /// words and the day allowances are re-cut together, on purpose: if the planner does something
    /// to a 5 that "hard deadline — can't shift" does not describe, the planner is wrong.
    func outcomeLabel(_ value: Int) -> String {
        let steps: [(Int, ToDoStringKey)] = [(1, .outcomeBand1), (4, .outcomeBand2),
                                             (6, .outcomeBand3), (8, .outcomeBand4),
                                             (10, .outcomeBand5)]
        return stepLabel(steps, value)
    }

    /// One picker row: the displayed `/5` step and the word for it, e.g. `4 / 5 · Can postpone a few
    /// weeks`. Every outcome picker composes its rows through here so they read alike.
    func outcomeOptionLabel(displayValue: Int) -> String {
        let step = min(ToDoScoring.outcomeSteps, max(1, displayValue))
        return "\(step) / \(ToDoScoring.outcomeSteps) · \(outcomeLabel(step * ToDoScoring.outcomeWireFactor))"
    }

    /// Web `getPerspirationSteps`.
    func perspirationLabel(_ value: Int) -> String {
        let steps: [(Int, ToDoStringKey)] = [(1, .perspirationFiveMinutes), (2, .perspirationFifteenMinutes),
                                             (3, .perspirationHalfAnHour), (4, .perspirationAnHour), (5, .perspirationHalfADay),
                                             (7, .perspirationADay), (9, .perspirationAWeek)]
        return stepLabel(steps, value)
    }

    private func stepLabel(_ steps: [(Int, ToDoStringKey)], _ value: Int) -> String {
        let clamped = ToDoScoring.clampLevel(value)
        let key = steps.last { $0.0 <= clamped }?.1 ?? steps[0].1
        return self[key]
    }

    func quadrantLabel(_ quadrant: EisenhowerQuadrant) -> String {
        switch quadrant {
        case .doIt: return self[.quadrantUrgentImportant]
        case .decide: return self[.quadrantImportantNotUrgent]
        case .delegate: return self[.quadrantNotImportantUrgent]
        case .delete: return self[.quadrantNotImportantNotUrgent]
        }
    }

    func quadrantShortLabel(_ quadrant: EisenhowerQuadrant) -> String {
        switch quadrant {
        case .doIt: return self[.quadrantDo]
        case .decide: return self[.quadrantDecide]
        case .delegate: return self[.quadrantDelegate]
        case .delete: return self[.quadrantDelete]
        }
    }

    func bucketLabel(_ bucket: PortfolioBucket) -> String {
        switch bucket {
        case .onTrack: return self[.bucketOnTrack]
        case .atRisk: return self[.bucketAtRisk]
        case .critical: return self[.bucketCritical]
        case .noDeadline: return self[.bucketNoDeadline]
        }
    }

    func badgeLabel(_ badge: PortfolioBadge) -> String {
        switch badge {
        case .overcommitted: return self[.badgeOvercommitted]
        case .startNow: return self[.badgeStartNow]
        case .sacrifice: return self[.badgeSacrifice]
        case .unscheduled: return self[.badgeUnscheduled]
        case .pushedBack: return self[.badgePushedBack]
        case .unknown: return ""
        }
    }

    func sectionLabel(_ section: PortfolioActionSection) -> String {
        switch section {
        case .askForExtension: return self[.askForExtensionSection]
        case .startNow: return self[.startNowSection]
        case .backBurner: return self[.backBurnerSection]
        }
    }

    func roleLabel(_ role: ProjectMemberRole?) -> String {
        switch role {
        case .owner: return self[.roleOwner]
        case .admin: return self[.roleAdmin]
        case .member, .none: return self[.roleMember]
        }
    }

    func invitationLabel(_ status: ProjectInvitationStatus) -> String {
        switch status {
        case .accepted: return self[.invitationAcceptedStatus]
        case .pending: return self[.invitationPendingStatus]
        case .declined: return self[.invitationDeclinedStatus]
        case .failed: return self[.invitationFailedStatus]
        }
    }

    func importanceLabel(_ importance: PortfolioImportance) -> String {
        switch importance {
        case .low: return self[.importanceLow]
        case .medium: return self[.importanceMedium]
        case .high: return self[.importanceHigh]
        case .critical: return self[.importanceCritical]
        }
    }

    /// Default kanban column labels (web `kanban_column_*`).
    func columnTitles() -> [ToDoStatus: String] {
        [.notStarted: self[.columnToDo], .inProgress: self[.columnInProgress], .completed: self[.columnDone]]
    }

    func projectStatusLabel(_ status: ProjectLifecycleStatus) -> String {
        switch status {
        case .active: return self[.projectStatusActive]
        case .completed: return self[.projectStatusCompleted]
        case .archived: return self[.projectStatusArchived]
        }
    }

    /// Synced (Zoho / ClickUp…) projects are stored with the external id as their name; the web
    /// renders that id verbatim. Show "Synced project …2013" instead, never a bare id.
    func projectName(_ raw: String?) -> String {
        let name = (raw ?? "").trimmingCharacters(in: .whitespaces)
        guard ToDoStrings.looksLikeIdentifier(name) else { return name }
        return "\(self[.syncedProject]) …\(name.suffix(ToDoStrings.identifierSuffixLength))"
    }

    private static let identifierMinLength = 12
    private static let identifierSuffixLength = 4

    static func looksLikeIdentifier(_ name: String) -> Bool {
        guard name.count >= identifierMinLength, !name.contains(" ") else { return false }
        return name.allSatisfy { $0.isHexDigit || $0 == "-" } && name.contains { $0.isNumber }
    }

    func dueLabel(_ isoString: String?, now: Date = Date()) -> String {
        ToDoDates.dueLabel(isoString, now: now, today: self[.today], tomorrow: self[.tomorrow], yesterday: self[.yesterday])
    }
}
