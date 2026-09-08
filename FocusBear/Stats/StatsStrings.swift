//
//  StatsStrings.swift
//  Focus Bear
//
//  User-facing strings for the native Stats screen, config-driven like every other screen
//  (`configjson["statsViewInfo"]`, English fallbacks below). Spanish lives in the assets repo
//  config-es.json. Templates use `{name}` placeholders filled via `StatsStrings.fill`.
//

import Foundation

struct StatsStrings {
    // Tabs (web: STATS.EMBEDDED_TABS order)
    var tabGoals = "Your Goals"
    var tabProgress = "Progress"
    var tabStreak = "Streak"
    var tabPepTalk = "Pep Talk"
    var tabLeaderboard = "Leaderboard"
    var tabHabitStats = "Habit Stats"
    var tabProductivity = "Productivity"
    var tabFocusLog = "Focus Log"

    // Shared
    var title = "Stats"
    var loadFailed = "Could not load stats. Check your connection and try again."
    var retry = "Retry"
    var refresh = "Refresh"
    var save = "Save"
    var cancel = "Cancel"
    var delete = "Delete"
    var edit = "Edit"
    var close = "Close"
    var date = "Date"

    // Streak
    var morningRoutine = "Morning Routine"
    var eveningRoutine = "Evening Routine"
    var focusBlocks = "Focus Blocks"
    var daysUntilLevelUp = "{days} more days until you level up"
    var averageCompletion = "Average completion:"
    var percentValue = "{value}%"
    var perDayValue = "{value}/day"
    var dayStreak = "Day Streak"

    // Progress (levels)
    var start = "Start"
    var end = "End"
    var levelTitle = "Level {level}"
    var levelGoals = "Level {level} goals:"
    var nextLevelRequirements = "Next level requirements"
    var morningRoutineStreak = "Morning Routine Streak"
    var microBreakStreak = "Micro Break Streak"
    var eveningRoutineStreak = "Evening Routine Streak"
    var focusModeStreak = "Focus Mode Streak"
    var chatWithFocusBear = "Chat with Focus Bear"
    var setUpFocusMode = "Set up a Focus Mode"
    var setupBlockedUrls = "Setup always blocked URLs"
    var installMobileApp = "Install mobile application"
    var editYourHabits = "Edit your habits"
    var levelNames = ["Novice", "Apprentice", "Explorer", "Disciplined", "Diligent",
                      "Strategist", "Mentor", "Scholar", "Guardian", "Achiever"]

    // Your Goals
    var noLongTermGoals = "You haven't set long term goals."
    var addGoal = "Add goal"
    var goalPlaceholder = "Enter a goal"
    var goalsSaved = "Goals saved"
    var goalsSaveFailed = "Could not save goals"

    // Pep Talk
    var toneNames: [String: String] = [
        "humorous": "Humorous", "sassy": "Sassy", "court jester": "court jester", "pirate": "pirate",
        "future self in twenty years": "future self in twenty years", "scientist": "scientist",
        "cheerleader": "cheerleader", "upbeat": "upbeat", "factual": "factual",
    ]
    var pepTalkUnavailable = "We couldn't generate a personalized message today. Please try again later."
    var motivationalStyle = "Motivational Style"
    var motivationalNotice = "Your routine streak and your routine activities will be sent to Open AI. No other details will be shared, but if anything in your habit titles would identify you, we recommend you remove it."

    // Leaderboard
    var sortBy = "Sort by"
    var morningStreak = "Morning Streak"
    var breakStreak = "Break Streak"
    var eveningStreak = "Evening Streak"
    var focusMode = "Focus Mode"
    var rank = "Rank"
    var name = "Name"
    var noUserFound = "No User Found"
    var leaderboardUsername = "Leaderboard Username"
    var update = "Update"
    var usernameRule = "Letters and underscores only"
    var streakValue = "Streak: {streak}"
    var daysCompletedOutOf = "{completed} days completed out of last {total} days"
    var ascending = "Ascending"
    var descending = "Descending"

    // Habit Stats
    var noHabitsTitle = "Add a habit to see your stats"
    var noHabitsDescription = "Go to \"{navItem}\" in the side menu, then add a habit to a routine."
    var editHabitsNavItem = "Edit Habits"
    var mostConsistentHabits = "Most consistent habits"
    var leastConsistentHabits = "Least consistent habits"
    var percentOfLastDays = "% of last {days} days"
    var totalCompletions = "Total completions"
    var hoursSpent = "Hours spent"
    var currentStreak = "Current streak"
    var last30Days = "Last 30 days"
    var hoursValue = "{value} hrs"
    var daysValue = "{value} days"
    var minutesValue = "{value} min"
    var habitCompletionHistory = "Habit Completion History"
    var less = "Less"
    var more = "More"
    var selectQuestions = "Select questions"
    var quantityLogged = "Quantity Logged"
    var noDataAvailable = "No data available for this habit yet"
    var logQuantityHistory = "Log Quantity History"
    var completion = "completion"
    var completions = "completions"

    // Productivity
    var daily = "Daily"
    var monthly = "Monthly"
    var yearly = "Yearly"
    var focusedMinutes = "Focused Minutes"
    var focusedHours = "Focused Hours"
    var total = "Total"
    var averageFocusPerDay = "Average Focus Per Day"
    var mostFocusedDay = "Most Focused Day"
    var averageTabCount = "Average Tab Count"
    var averageTabDuration = "Average Tab Duration"
    var tabsValue = "{value} tabs"
    var secondsShortValue = "{value}s"
    var focusedMinutesDescription = "Time spent in focus sessions weighted by alignment score"
    var alignmentScoreTooltip = "Alignment score measures how well you stayed focused during a session. Time is weighted by this score, so sessions with higher focus contribute more to your total."
    var noProductivityData = "No productivity data available yet. Complete some focus sessions to see your stats."

    // Focus Log
    var addManualSession = "Add Manual Session"
    var focusBlockSummary = "Focus Block Summary"
    var export = "Export"
    var duration = "Duration"
    var startTime = "Start Time"
    var finishTime = "Finish Time"
    var intention = "Intention"
    var achievements = "Achievements"
    var distractions = "Distractions"
    var noFocusSummary = "No focus summary available"
    var startFocusSessionHint = "Start a focus session to see your performance summary here."
    var loadMoreSessions = "Load more sessions"
    var confirmDeleteSession = "Are you sure you want to delete this focus session?"
    var finishAfterStart = "Finish time must be after start time"
    var startInFuture = "Start time cannot be in the future"
    var finishInFuture = "Finish time cannot be in the future"
    var durationHours = "Duration (hours)"
    var filterPlaceholder = "Filter"
    var sessionSaveFailed = "Could not save the focus session"

    static func load() -> StatsStrings {
        var strings = StatsStrings()
        guard let info = configjson.value(forKey: "statsViewInfo") as? NSDictionary else { return strings }
        func read(_ key: String, _ target: inout String) {
            if let value = info.value(forKey: key) as? String, !value.isEmpty { target = value }
        }
        read("tabGoals", &strings.tabGoals)
        read("tabProgress", &strings.tabProgress)
        read("tabStreak", &strings.tabStreak)
        read("tabPepTalk", &strings.tabPepTalk)
        read("tabLeaderboard", &strings.tabLeaderboard)
        read("tabHabitStats", &strings.tabHabitStats)
        read("tabProductivity", &strings.tabProductivity)
        read("tabFocusLog", &strings.tabFocusLog)
        read("title", &strings.title)
        read("loadFailedText", &strings.loadFailed)
        read("retryText", &strings.retry)
        read("refreshText", &strings.refresh)
        read("saveText", &strings.save)
        read("cancelText", &strings.cancel)
        read("deleteText", &strings.delete)
        read("editText", &strings.edit)
        read("closeText", &strings.close)
        read("dateText", &strings.date)
        read("morningRoutineText", &strings.morningRoutine)
        read("eveningRoutineText", &strings.eveningRoutine)
        read("focusBlocksText", &strings.focusBlocks)
        read("daysUntilLevelUpText", &strings.daysUntilLevelUp)
        read("averageCompletionText", &strings.averageCompletion)
        read("percentValueText", &strings.percentValue)
        read("perDayValueText", &strings.perDayValue)
        read("dayStreakText", &strings.dayStreak)
        read("startText", &strings.start)
        read("endText", &strings.end)
        read("levelTitleText", &strings.levelTitle)
        read("levelGoalsText", &strings.levelGoals)
        read("nextLevelRequirementsText", &strings.nextLevelRequirements)
        read("morningRoutineStreakText", &strings.morningRoutineStreak)
        read("microBreakStreakText", &strings.microBreakStreak)
        read("eveningRoutineStreakText", &strings.eveningRoutineStreak)
        read("focusModeStreakText", &strings.focusModeStreak)
        read("chatWithFocusBearText", &strings.chatWithFocusBear)
        read("setUpFocusModeText", &strings.setUpFocusMode)
        read("setupBlockedUrlsText", &strings.setupBlockedUrls)
        read("installMobileAppText", &strings.installMobileApp)
        read("editYourHabitsText", &strings.editYourHabits)
        if let names = info.value(forKey: "levelNames") as? [String], names.count == strings.levelNames.count {
            strings.levelNames = names
        }
        read("noLongTermGoalsText", &strings.noLongTermGoals)
        read("addGoalText", &strings.addGoal)
        read("goalPlaceholder", &strings.goalPlaceholder)
        read("goalsSavedText", &strings.goalsSaved)
        read("goalsSaveFailedText", &strings.goalsSaveFailed)
        if let tones = info.value(forKey: "toneNames") as? [String: String] {
            strings.toneNames.merge(tones) { _, translated in translated }
        }
        read("pepTalkUnavailableText", &strings.pepTalkUnavailable)
        read("motivationalStyleText", &strings.motivationalStyle)
        read("motivationalNoticeText", &strings.motivationalNotice)
        read("sortByText", &strings.sortBy)
        read("morningStreakText", &strings.morningStreak)
        read("breakStreakText", &strings.breakStreak)
        read("eveningStreakText", &strings.eveningStreak)
        read("focusModeText", &strings.focusMode)
        read("rankText", &strings.rank)
        read("nameText", &strings.name)
        read("noUserFoundText", &strings.noUserFound)
        read("leaderboardUsernameText", &strings.leaderboardUsername)
        read("updateText", &strings.update)
        read("usernameRuleText", &strings.usernameRule)
        read("streakValueText", &strings.streakValue)
        read("daysCompletedOutOfText", &strings.daysCompletedOutOf)
        read("ascendingText", &strings.ascending)
        read("descendingText", &strings.descending)
        read("noHabitsTitle", &strings.noHabitsTitle)
        read("noHabitsDescription", &strings.noHabitsDescription)
        read("editHabitsNavItem", &strings.editHabitsNavItem)
        read("mostConsistentHabitsText", &strings.mostConsistentHabits)
        read("leastConsistentHabitsText", &strings.leastConsistentHabits)
        read("percentOfLastDaysText", &strings.percentOfLastDays)
        read("totalCompletionsText", &strings.totalCompletions)
        read("hoursSpentText", &strings.hoursSpent)
        read("currentStreakText", &strings.currentStreak)
        read("last30DaysText", &strings.last30Days)
        read("hoursValueText", &strings.hoursValue)
        read("daysValueText", &strings.daysValue)
        read("minutesValueText", &strings.minutesValue)
        read("habitCompletionHistoryText", &strings.habitCompletionHistory)
        read("lessText", &strings.less)
        read("moreText", &strings.more)
        read("selectQuestionsText", &strings.selectQuestions)
        read("quantityLoggedText", &strings.quantityLogged)
        read("noDataAvailableText", &strings.noDataAvailable)
        read("logQuantityHistoryText", &strings.logQuantityHistory)
        read("completionText", &strings.completion)
        read("completionsText", &strings.completions)
        read("dailyText", &strings.daily)
        read("monthlyText", &strings.monthly)
        read("yearlyText", &strings.yearly)
        read("focusedMinutesText", &strings.focusedMinutes)
        read("focusedHoursText", &strings.focusedHours)
        read("totalText", &strings.total)
        read("averageFocusPerDayText", &strings.averageFocusPerDay)
        read("mostFocusedDayText", &strings.mostFocusedDay)
        read("averageTabCountText", &strings.averageTabCount)
        read("averageTabDurationText", &strings.averageTabDuration)
        read("tabsValueText", &strings.tabsValue)
        read("secondsShortValueText", &strings.secondsShortValue)
        read("focusedMinutesDescriptionText", &strings.focusedMinutesDescription)
        read("alignmentScoreTooltipText", &strings.alignmentScoreTooltip)
        read("noProductivityDataText", &strings.noProductivityData)
        read("addManualSessionText", &strings.addManualSession)
        read("focusBlockSummaryText", &strings.focusBlockSummary)
        read("exportText", &strings.export)
        read("durationText", &strings.duration)
        read("startTimeText", &strings.startTime)
        read("finishTimeText", &strings.finishTime)
        read("intentionText", &strings.intention)
        read("achievementsText", &strings.achievements)
        read("distractionsText", &strings.distractions)
        read("noFocusSummaryText", &strings.noFocusSummary)
        read("startFocusSessionHintText", &strings.startFocusSessionHint)
        read("loadMoreSessionsText", &strings.loadMoreSessions)
        read("confirmDeleteSessionText", &strings.confirmDeleteSession)
        read("finishAfterStartText", &strings.finishAfterStart)
        read("startInFutureText", &strings.startInFuture)
        read("finishInFutureText", &strings.finishInFuture)
        read("durationHoursText", &strings.durationHours)
        read("filterPlaceholder", &strings.filterPlaceholder)
        read("sessionSaveFailedText", &strings.sessionSaveFailed)
        return strings
    }

    /// Fills `{name}` placeholders: `fill("Level {level}", ["level": "3"])`.
    static func fill(_ template: String, _ values: [String: String]) -> String {
        values.reduce(template) { partial, entry in
            partial.replacingOccurrences(of: "{\(entry.key)}", with: entry.value)
        }
    }

    func levelName(_ level: Int) -> String {
        guard level >= 0, level < levelNames.count else { return "" }
        return levelNames[level]
    }

    func toneName(_ tone: String) -> String { toneNames[tone] ?? tone }
}
