//
//  FocusStartStrings.swift
//  Focus Bear
//
//  User-facing text for the focus-session start flow. Config-driven like every other screen: the
//  English below is only the offline fallback, the shipped copy lives in `configjson["focusStartVcInfo"]`
//  and its Spanish counterpart in the assets repo's config-es.json.
//

import Foundation

/// Placeholder tokens substituted at render time. The same convention the rest of config.json uses.
enum FocusStartPlaceholder {
    static let count = "<COUNT>"
    static let duration = "<DURATION>"
    static let time = "<TIME>"
}

struct FocusStartStrings {
    // Headers
    var simpleTitle = "Start a focus session"
    /// Split around the emphasised middle so the advanced title can be drawn "Start **an advanced**
    /// focus session" with the middle in the brand orange.
    var advancedTitlePrefix = "Start "
    var advancedTitleEmphasis = "an advanced"
    var advancedTitleSuffix = " focus session"

    // The two links that swap between the simple and the advanced screen.
    var goAdvancedLinkTop = "Top Secret/"
    var goAdvancedLinkBottom = "Extra Powerful Options"
    var goSimpleLinkTop = "Go back/"
    var goSimpleLinkBottom = "Regular Options"

    // Simple screen
    var setSessionLengthLabel = "Set session length:"
    var startTimedButton = "Start a <DURATION> session"
    var startUntimedButton = "Start an untimed session"
    var startSessionButton = "Start Session"
    var readyToFocusBubble = "Ready to focus?"

    // Duration card
    var durationCardTitle = "How long shall we focus?"
    var durationBubble = "Feeling ambitious? You can tweak the timer."
    /// Retained for the separate Super Focus rest duration; the visible micro-break control uses frequency.
    var breakDurationLabel = "Break duration:"
    var breakDurationUnit = "mins"
    var untimedModeLabel = "Untimed mode:"
    var microBreaksLabel = "Micro-breaks:"
    /// The duration card's collapsible break-settings section (#2449).
    var breakSettingsTitle = "Break settings"
    /// Spelled out because "Micro-breaks: [toggle]" left users guessing when they happen.
    var microBreaksExplainer = "Micro-breaks are short pauses that run during your focus session."
    var superFocusLabel = "Super Focus:"
    var superFocusSessionsUnit = "sessions"
    var hourUnit = "hr"
    var minuteUnit = "min"
    var sliderMinimumLabel = "0 HRS"
    var sliderMaximumLabel = "8 HRS"
    var untimedGlyph = "∞"

    var enableMicroBreaksLabel = "Enable micro-breaks:"
    var breakFrequencyLabel = "Break frequency:"
    var breakFrequencySummary = "Micro-breaks every <COUNT> mins"
    var useGoal = "Use this goal"
    var removeTask = "Remove task from this session"
    var clearSearch = "Clear search"
    var moreTasks = "Show more tasks"
    var noMatchingTasks = "No matching unfinished tasks"
    var workChoicesUnavailable = "Projects or tasks could not be loaded. Please try again."
    var retryWorkChoices = "Try again"
    var changeGoal = "Change goal"
    var clearGoal = "Clear goal"
    var addMoreTasks = "Add more tasks"
    var doneAddingTasks = "Done adding tasks"
    var noMatchingBlockLists = "No matching block lists"

    // Goal card
    var goalCardTitle = "What would you like to achieve?"
    var goalBubble = "Give this session a job to do"
    var goalPlaceholder = "Add a new goal or search for a project"
    var projectsHeading = "Projects"
    var tasksLabel = "Add tasks to focus on:"
    var taskPlaceholder = "Search for tasks"
    var noGoalSummary = "No Goal"
    var taskSummary = "<COUNT> tasks"
    var taskSummarySingular = "<COUNT> task"

    // Blocking card
    var blockingCardTitle = "What distractions shall we block?"
    var blockingBubble = "Choose what to pause during this session"
    var chooseBlockListLabel = "Choose a blocklist:"
    var blockListPlaceholder = "Type to search block lists"
    var editBlockListsButton = "Edit block lists"
    var strictnessLabel = "Strictness level:"
    var aiEnabledBadge = "AI Enabled"
    var aiDisabledBadge = "AI Off"
    var appsAndWebsitesCount = "<COUNT> apps/websites"
    var focusAlignmentScoreLabel = "Show the distracting-site popup only below a focus alignment score of"

    // Strictness levels — the design's names, mapped 1:1 onto the app's existing stored values.
    var juniorTitle = "Junior 🐻"
    var juniorDescription = "Stop any time"
    var captainTitle = "Captain 🏴‍☠️"
    var captainDescription = "15 sec delay"
    var pawfessorTitle = "Pawfessor 🎓"
    var pawfessorDescription = "No Stopping"

    // Summaries on a collapsed card
    var minutesSummary = "<COUNT> mins"
    var untimedSummary = "Untimed"
    var breakSummary = "<COUNT> breaks"
    var breakSummarySingular = "<COUNT> break"
    /// The collapsed break-settings header, so collapsing never hides what the session will do.
    var breakDurationSummary = "<COUNT> min breaks"
    var microBreaksOnSummary = "Micro-breaks on"
    var microBreaksOffSummary = "Micro-breaks off"

    // Banners and validation
    var unfocusedTimer = "Time spent unfocused: <TIME>"
    var fixPermissionsButton = "Fix it"
    var permissionsTipFirst = "Want to block distractions during this focus session? Grant Focus Bear permissions to block."
    var permissionsTipSecond = "Distraction blocking inactive: Focus Bear doesn’t have permissions for any of your browsers."
    var superStrictScheduleBlocksList = "A super strict blocking schedule is active. You'll need to pause it to use a different block list."
    var superStrictScheduleBlocksStart = "A super strict blocking schedule is active. You'll need to pause it to start a session."
    /// Shown while a blocking schedule is running. A schedule is not a focus session, so this only
    /// reports what is already being blocked — starting a session stays available.
    var activeBlockingSchedule = "“<NAME>” is blocking until <TIME>. You can still start a focus session."
    var workDurationZeroError = "Work Duration can not be 0."

    /// "“Deep work” is blocking until 6:13 pm. You can still start a focus session."
    func activeBlockingScheduleText(name: String, until: String) -> String {
        activeBlockingSchedule
            .replacingOccurrences(of: "<NAME>", with: name)
            .replacingOccurrences(of: "<TIME>", with: until)
    }

    func strictnessTitle(_ level: FocusStartStrictness) -> String {
        switch level {
        case .junior: return juniorTitle
        case .captain: return captainTitle
        case .pawfessor: return pawfessorTitle
        }
    }

    func strictnessDescription(_ level: FocusStartStrictness) -> String {
        switch level {
        case .junior: return juniorDescription
        case .captain: return captainDescription
        case .pawfessor: return pawfessorDescription
        }
    }

    /// Reads the shipped copy out of config.json, falling back to the English above for any key the
    /// config doesn't carry (older config, or a partially translated locale).
    static func load() -> FocusStartStrings {
        var strings = FocusStartStrings()
        strings.applyCommonBlocks()
        guard let info = configjson.value(forKey: "focusStartVcInfo") as? NSDictionary else { return strings }

        func read(_ key: String, _ target: inout String, allowEmpty: Bool = false) {
            if let text = info.value(forKey: key) as? String, allowEmpty || !text.isEmpty { target = text }
        }

        read("titleSimple", &strings.simpleTitle)
        read("titleAdvancedPrefix", &strings.advancedTitlePrefix, allowEmpty: true)
        read("titleAdvancedEmphasis", &strings.advancedTitleEmphasis)
        read("titleAdvancedSuffix", &strings.advancedTitleSuffix, allowEmpty: true)
        read("linkAdvancedTop", &strings.goAdvancedLinkTop)
        read("linkAdvancedBottom", &strings.goAdvancedLinkBottom)
        read("linkSimpleTop", &strings.goSimpleLinkTop)
        read("linkSimpleBottom", &strings.goSimpleLinkBottom)
        read("labelSetSessionLength", &strings.setSessionLengthLabel)
        read("buttonStartTimed", &strings.startTimedButton)
        read("buttonStartUntimed", &strings.startUntimedButton)
        read("buttonStartSession", &strings.startSessionButton)
        read("bubbleReadyToFocus", &strings.readyToFocusBubble)
        read("titleDurationCard", &strings.durationCardTitle)
        read("bubbleDuration", &strings.durationBubble)
        read("labelBreakDuration", &strings.breakDurationLabel)
        read("unitBreakDuration", &strings.breakDurationUnit)
        read("labelUntimedMode", &strings.untimedModeLabel)
        read("labelMicroBreaks", &strings.microBreaksLabel)
        read("labelSuperFocus", &strings.superFocusLabel)
        read("unitSuperFocusSessions", &strings.superFocusSessionsUnit)
        read("unitHour", &strings.hourUnit)
        read("unitMinute", &strings.minuteUnit)
        read("labelSliderMinimum", &strings.sliderMinimumLabel)
        read("labelSliderMaximum", &strings.sliderMaximumLabel)
        read("titleGoalCard", &strings.goalCardTitle)
        read("bubbleGoal", &strings.goalBubble)
        read("placeholderGoal", &strings.goalPlaceholder)
        read("headingProjects", &strings.projectsHeading)
        read("labelTasks", &strings.tasksLabel)
        read("placeholderTask", &strings.taskPlaceholder)
        read("summaryNoGoal", &strings.noGoalSummary)
        read("summaryTasks", &strings.taskSummary)
        read("summaryTaskSingular", &strings.taskSummarySingular)
        read("titleBlockingCard", &strings.blockingCardTitle)
        read("bubbleBlocking", &strings.blockingBubble)
        read("labelChooseBlockList", &strings.chooseBlockListLabel)
        read("labelStrictness", &strings.strictnessLabel)
        read("badgeAiEnabled", &strings.aiEnabledBadge)
        read("badgeAiDisabled", &strings.aiDisabledBadge)
        read("countAppsAndWebsites", &strings.appsAndWebsitesCount)
        read("labelFocusAlignmentScore", &strings.focusAlignmentScoreLabel)
        read("titleJunior", &strings.juniorTitle)
        read("descriptionJunior", &strings.juniorDescription)
        read("titleCaptain", &strings.captainTitle)
        read("descriptionCaptain", &strings.captainDescription)
        read("titlePawfessor", &strings.pawfessorTitle)
        read("descriptionPawfessor", &strings.pawfessorDescription)
        read("summaryMinutes", &strings.minutesSummary)
        read("summaryUntimed", &strings.untimedSummary)
        read("summaryBreaks", &strings.breakSummary)
        read("summaryBreakSingular", &strings.breakSummarySingular)
        read("titleBreakSettings", &strings.breakSettingsTitle)
        read("explainerMicroBreaks", &strings.microBreaksExplainer)
        read("summaryBreakDuration", &strings.breakDurationSummary)
        read("summaryMicroBreaksOn", &strings.microBreaksOnSummary)
        read("summaryMicroBreaksOff", &strings.microBreaksOffSummary)
        read("placeholderBlockList", &strings.blockListPlaceholder)
        read("labelEnableMicroBreaks", &strings.enableMicroBreaksLabel)
        read("labelBreakFrequency", &strings.breakFrequencyLabel)
        read("summaryBreakFrequency", &strings.breakFrequencySummary)
        read("buttonUseGoal", &strings.useGoal)
        read("buttonRemoveTask", &strings.removeTask)
        read("buttonClearSearch", &strings.clearSearch)
        read("buttonMoreTasks", &strings.moreTasks)
        read("noMatchingTasks", &strings.noMatchingTasks)
        read("workChoicesUnavailable", &strings.workChoicesUnavailable)
        read("buttonRetryWorkChoices", &strings.retryWorkChoices)
        read("buttonChangeGoal", &strings.changeGoal)
        read("buttonClearGoal", &strings.clearGoal)
        read("buttonAddMoreTasks", &strings.addMoreTasks)
        read("buttonDoneAddingTasks", &strings.doneAddingTasks)
        read("noMatchingBlockLists", &strings.noMatchingBlockLists)
        read("noticeActiveBlockingSchedule", &strings.activeBlockingSchedule)
        return strings
    }

    /// Copy this screen shares with the rest of the app — reused rather than duplicated so the
    /// translations stay in one place.
    private mutating func applyCommonBlocks() {
        if let pomodoro = configjson.value(forKey: "pomodoroInfo") as? NSDictionary {
            if let text = pomodoro.value(forKey: "buttonLetsDoItText") as? String, !text.isEmpty { startSessionButton = text }
            if let text = pomodoro.value(forKey: "buttonEditBlockListsText") as? String, !text.isEmpty { editBlockListsButton = text }
            if let text = pomodoro.value(forKey: "titleSelectBlockList") as? String, !text.isEmpty { chooseBlockListLabel = text }
            if let text = pomodoro.value(forKey: "timerText") as? String, !text.isEmpty { unfocusedTimer = text }
            if let text = pomodoro.value(forKey: "superStrictBlockingActiveMessage") as? String, !text.isEmpty {
                superStrictScheduleBlocksList = text
            }
            if let text = pomodoro.value(forKey: "simpleSuperStrictBlockingActiveMessage") as? String, !text.isEmpty {
                superStrictScheduleBlocksStart = text
            }
            if let text = pomodoro.value(forKey: "questionFirstText") as? String, !text.isEmpty { goalCardTitle = text }
        }
        if let simple = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary {
            if let text = simple.value(forKey: "buttonFixItText") as? String, !text.isEmpty { fixPermissionsButton = text }
            if let text = simple.value(forKey: "tipPermissionsFirst") as? String, !text.isEmpty { permissionsTipFirst = text }
            if let text = simple.value(forKey: "tipPermissionsSecond") as? String, !text.isEmpty { permissionsTipSecond = text }
            if let text = simple.value(forKey: "titleStrictnessLevel") as? String, !text.isEmpty { strictnessLabel = text }
            if let text = simple.value(forKey: "enterFirstTask") as? String, !text.isEmpty { taskPlaceholder = text }
        }
    }
}
