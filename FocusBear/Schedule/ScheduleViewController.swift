//
//  ScheduleViewController.swift
//  Focus Bear
//
//  The "Schedule" tab: an agenda-card timetable of the day built from the current
//  routine's remaining habits plus today's calendar meetings, with the same
//  Play/Done/Skip actions as the simple Habits view. Built fully in code (no
//  storyboard scene) so it can be slotted into the existing habit screen without
//  touching the storyboard.
//

import Cocoa
import EventKit
import SwiftUI

/// Renders the small "(shortened)" marker after a trimmed habit's name in the Day Plan list.
///
/// It is appended to the title label's own attributed string rather than added as a sibling view: a
/// fixed-width sibling competing with the flexible title is exactly how the Day Plan has twice had a
/// column collapse to zero, and this way the marker truncates with the name it belongs to instead of
/// squeezing it. Pure, so the marker is unit-tested without the view controller.
enum DayPlanShortenedTag {
    static let fontSize: CGFloat = 11
    /// On the selected habit's solid-orange header the secondary grey is unreadable — the marker
    /// matches the header's white text at this alpha instead.
    static let onOrangeAlpha: CGFloat = 0.85

    /// `text` with " <tag>" appended in the smaller, dimmer style. An empty base is left alone (there
    /// is no name for the marker to belong to).
    static func appended(to text: NSAttributedString, tag: String, color: NSColor) -> NSAttributedString {
        guard text.length > 0, !tag.isEmpty else { return text }
        let result = NSMutableAttributedString(attributedString: text)
        result.append(NSAttributedString(string: " " + tag, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: color,
        ]))
        return result
    }
}

/// All user-facing strings for the Schedule tab, read from the `scheduleViewInfo` config block
/// (with English fallbacks) so they can be translated like the rest of the app.
enum ScheduleText {
    private static var info: NSDictionary? { configjson.value(forKey: "scheduleViewInfo") as? NSDictionary }
    static func t(_ key: String, _ fallback: String) -> String {
        let value = info?.value(forKey: key) as? String
        if let value = value, !value.isEmpty { return value }
        let language = BundledConfigLanguage.code()
        return bundled[language]?[key] ?? bundled["en"]?[key] ?? fallback
    }
    private static let bundled: [String: [String: String]] = {
        var result: [String: [String: String]] = [:]
        for (language, file) in BundledConfigLanguage.all {
            guard let url = Bundle.main.url(forResource: file, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let values = json["scheduleViewInfo"] as? [String: String] else { continue }
            result[language] = values
        }
        return result
    }()
    static var morningRoutineHabits: String { t("morningRoutineHabits", "Morning routine habits") }
    static var notEnoughTimeToday: String { t("notEnoughTimeToday", "Not enough time today") }
    /// The same note for a past/future day being previewed, where "today" would be a lie.
    static var notEnoughTimeThisDay: String { t("notEnoughTimeThisDay", "Not enough time on this day") }
    static var eveningRoutineHabits: String { t("eveningRoutineHabits", "Evening routine habits") }
    static var habitsSuffix: String { t("habitsSuffix", "habits") }          // "<routine> habits"
    static var play: String { t("play", "Play") }
    static var done: String { t("done", "Done") }
    static var skip: String { t("skip", "Skip") }
    static var habitsDone: String { t("habitsDone", "Habits done") }
    static var meeting: String { t("meeting", "meeting") }
    static var noHabitsLeft: String { t("noHabitsLeft", "No habits left for now — enjoy your free time! 🎉") }
    static var nothingScheduled: String { t("nothingScheduled", "Nothing scheduled for this day.") }
    static var calendarBanner: String { t("calendarBanner", "Connect your calendar to see meetings and free time for deep work.") }
    static var grantAccess: String { t("grantAccess", "Grant access") }
    static var removingFullScreen: String { t("removingFullScreen", "Removing full screen for 30 seconds to grant calendar permissions") }
    // Shown when Focus Bear HAS calendar access but the Mac has no calendars at all (no account added
    // in the macOS Calendar app), so clicking "Connect calendar" would otherwise silently do nothing.
    static var noCalendarsTitle: String { t("noCalendarsTitle", "No calendars connected") }
    static var noCalendarsMessage: String { t("noCalendarsMessage", "Focus Bear has calendar access, but there are no calendars on this Mac yet. Add a calendar account in the macOS Calendar app (or System Settings › Internet Accounts), then reopen your Day Plan to see your meetings and free time for deep work.") }
    static var noCalendarsOpenSettings: String { t("noCalendarsOpenSettings", "Add a calendar account") }
    static var noCalendarsDismiss: String { t("noCalendarsDismiss", "Not now") }
    static var today: String { t("today", "Today") }
    static var backToToday: String { t("backToToday", "Back to today") }
    static var habitPlayerTab: String { t("habitPlayerTab", "Habit Player") }   // allowed-activity player tabs
    static var dayPlanTab: String { t("dayPlanTab", "Day Plan") }
    static var skipRoutineForToday: String { t("skipRoutineForToday", "Skip routine for today") }
    // Confirmation shown when the ✕ (skip routine for today) is clicked on the Day Plan.
    static var cancelRoutineTitle: String { t("cancelRoutineTitle", "Cancel Routine?") }
    static var cancelRoutineMessage: String { t("cancelRoutineMessage", "If you change your mind later, you can click the \"<BUTTON>\" button to restore the routine.") }
    static var cancelRoutineOk: String { t("cancelRoutineOk", "OK") }
    static var cancelRoutineCancel: String { t("cancelRoutineCancel", "Cancel") }
    // Past-habit retroactive completion (Day Plan "earlier today" / previous days).
    static var pastHabitComplete: String { t("pastHabitComplete", "Complete") }
    static var pastHabitCompleteHint: String { t("pastHabitCompleteHint", "I actually did it but forgot to log it 😅") }
    static var engineLabels: ScheduleBuilder.Labels {
        ScheduleBuilder.Labels(
            deepWork: "🧠 " + t("deepWork", "Deep work"),
            breakSprint: "☕️ " + t("breakSprint", "Break"),
            sleep: "😴 " + t("sleep", "Sleep"),
            eveningRoutine: "🌙 " + t("eveningRoutine", "Evening routine"),
            morningRoutine: "🌅 " + t("morningRoutine", "Morning routine"),
            meeting: meeting)
    }
    static var meetingDefaultTitle: String { t("meetingDefaultTitle", "Meeting") }
    static var addEvent: String { t("addEvent", "Add event") }
    static var eventTitlePlaceholder: String { t("eventTitlePlaceholder", "Event title") }
    static var eventCalendarLabel: String { t("eventCalendarLabel", "Calendar") }
    static var eventStartsLabel: String { t("eventStartsLabel", "Starts") }
    static var eventEndsLabel: String { t("eventEndsLabel", "Ends") }
    /// Placeholder in the event form's typed time field — an example of the spellings it accepts.
    static var eventTimePlaceholder: String { t("eventTimePlaceholder", "e.g. 7:30 am") }
    static var eventSave: String { t("eventSave", "Save") }
    static var eventCancel: String { t("eventCancel", "Cancel") }
    static var eventSaveError: String { t("eventSaveError", "Couldn't save the event. Check calendar access and try again.") }
    static var eventNotOwnedWarning: String { t("eventNotOwnedWarning", "Warning: You don't own this event. Changes will only be reflected on your day plan.") }
    /// Tooltip / VoiceOver label for the ✕ that dismisses the event editor (it shows no text of its own).
    static var eventCloseForm: String { t("eventCloseForm", "Close") }
    /// Destructive action shown when the signed-in user organises the event.
    static var eventCancelEventButton: String { t("eventCancelEventButton", "Cancel Event") }
    /// Destructive action shown when someone else organises it (or ownership can't be established).
    static var eventDeclineEventButton: String { t("eventDeclineEventButton", "Decline event") }
    static var eventCancelEventConfirmTitle: String { t("eventCancelEventConfirmTitle", "Cancel this event?") }
    static var eventCancelEventConfirmMessage: String { t("eventCancelEventConfirmMessage", "You organise this event, so deleting it also sends a cancellation to the other attendees through your calendar account. Focus Bear can't undo this.") }
    static var eventDeclineEventConfirmTitle: String { t("eventDeclineEventConfirmTitle", "Decline this event?") }
    static var eventDeclineEventConfirmMessage: String { t("eventDeclineEventConfirmMessage", "This removes the invitation from your own calendar and leaves the meeting in place for everyone else. macOS gives apps no way to send an RSVP, so whether the organiser is told depends on your calendar account — reply in Calendar if they need to know.") }
    /// The confirmation's non-destructive button: back out and leave the event alone.
    static var eventCancelEventKeep: String { t("eventCancelEventKeep", "Keep event") }
    static var eventRemoveFailedTitle: String { t("eventRemoveFailedTitle", "Couldn't remove this event") }
    static var eventRemoveFailedMessage: String { t("eventRemoveFailedMessage", "Your calendar wouldn't let Focus Bear remove this event. It may live in a read-only calendar, or have already been deleted elsewhere.") }
    static var eventRemoveFailedOk: String { t("eventRemoveFailedOk", "OK") }
    /// The repeating-event question, asked for a removal rather than an edit.
    static var removeRepeatingInfo: String { t("removeRepeatingInfo", "Do you want to remove only this event, or all events in the series?") }
    static var showEarlierEvents: String { t("showEarlierEvents", "Show events from earlier today") }
    static var hideDeepWork: String { t("hideDeepWork", "Hide deep work blocks") }
    static var hideHabitBlocks: String { t("hideHabitBlocks", "Hide habits") }
    static var showDismissedEvents: String { t("showDismissedEvents", "Show dismissed events") }
    static var showEventAgain: String { t("showEventAgain", "Show this event again") }
    static var hideEvent: String { t("hideEvent", "Hide this event") }
    /// Short labels for the button itself — the tooltips above stay as the fuller explanation.
    static var hideEventButton: String { t("hideEventButton", "🙈 Hide") }
    static var showEventButton: String { t("showEventButton", "👀 Show") }
    // Matches the strings already authored in the assets repo (config/config.json, commit 6c87745,
    // "i18n: add repeating event dismissal strings (EN/ES)") — reusing those key names/wording rather
    // than inventing new ones, so this picks up the config-driven (and Spanish) copy once that lands.
    static var dismissRepeatingTitle: String { t("dismissRepeatingTitle", "This is a repeating event.") }
    static var dismissRepeatingInfo: String { t("dismissRepeatingInfo", "Would you like to hide all events in the series or just the one for today?") }
    static var dismissRepeatingJustThisOne: String { t("dismissRepeatingJustThisOne", "Just this one") }
    static var dismissRepeatingAllSeries: String { t("dismissRepeatingAllSeries", "All events in series") }
    static var dismissRepeatingCancel: String { t("dismissRepeatingCancel", "Cancel") }
    static var showHabits: String { t("showHabits", "Show habits") }
    static var hideHabits: String { t("hideHabits", "Hide habits") }
    static var routineCompleted: String { t("routineCompleted", "Completed") }
    static var deepWorkSession: String { t("deepWorkSession", "Deep work") }
    /// "(45 min)" under an hour, "(1h43m)" above it, "(2h)" on the hour — see `ScheduleDuration`.
    static func durationMinutesBrackets(_ mins: Int) -> String {
        ScheduleDuration.bracketed(mins,
                                   minutesOnly: t("durationMinutesBrackets", "(%d min)"),
                                   hoursOnly: t("durationHoursBrackets", "(%dh)"),
                                   hoursAndMinutes: t("durationHoursMinutesBrackets", "(%dh%dm)"))
    }
    static var showDeepWorkBreakdown: String { t("showDeepWorkBreakdown", "Show deep work breakdown") }
    static var hideDeepWorkBreakdown: String { t("hideDeepWorkBreakdown", "Hide deep work breakdown") }
    static var cancelledMorningRoutineMessage: String { t("cancelledMorningRoutineMessage", "You cancelled your morning routine. If you changed your mind, click \"Uncancel My Morning Routine\" to continue your morning habits.") }
    static var cancelledEveningRoutineMessage: String { t("cancelledEveningRoutineMessage", "You cancelled your evening routine. If you changed your mind, click \"Uncancel My Evening Routine\" to continue your evening habits.") }
    static var uncancelMorningRoutineButton: String { t("uncancelMorningRoutineButton", "Uncancel My Morning Routine") }
    static var uncancelEveningRoutineButton: String { t("uncancelEveningRoutineButton", "Uncancel My Evening Routine") }
    static var scheduleSettings: String { t("scheduleSettings", "Schedule settings") }
    static var hideEarlierEvents: String { t("hideEarlierEvents", "Hide events from earlier today") }
    static var viewTomorrow: String { t("viewTomorrow", "View tomorrow's schedule") }
    static var editEventTitle: String { t("editEventTitle", "Edit event") }
    static var eventRepeatLabel: String { t("eventRepeatLabel", "Repeat") }
    static var eventColorLabel: String { t("eventColorLabel", "Colour") }
    static var eventParticipantsLabel: String { t("eventParticipantsLabel", "Participants") }
    static var eventParticipantAccepted: String { t("eventParticipantAccepted", "Accepted") }
    static var eventParticipantDeclined: String { t("eventParticipantDeclined", "Declined") }
    static var eventParticipantTentative: String { t("eventParticipantTentative", "Tentative") }
    static var eventParticipantNoResponse: String { t("eventParticipantNoResponse", "No response") }
    static var eventNotesLabel: String { t("eventNotesLabel", "Description (shared with other attendees)") }
    static var eventPrivateNotesLabel: String { t("eventPrivateNotesLabel", "My private notes (only you)") }
    static var freeTimeToday: String { t("freeTimeToday", "🕒 %@ free") }
    static var tasksTotalToDo: String { t("tasksTotalToDo", "≈ %@ of tasks to do") }
    // Free time once the day's tasks are subtracted can go negative (over-committed) — shown in red.
    static var repeatNone: String { t("repeatNone", "Does not repeat") }
    static var repeatDaily: String { t("repeatDaily", "Daily") }
    static var repeatWeekly: String { t("repeatWeekly", "Weekly") }
    static var repeatMonthly: String { t("repeatMonthly", "Monthly") }
    static var tasksForToday: String { t("tasksForToday", "Tasks for today") }
    static var tasksForDay: String { t("tasksForDay", "Tasks for %@") }
    static var tasksShowCompleted: String { t("tasksShowCompleted", "Show completed") }
    static var tasksShowCompletedCount: String { t("tasksShowCompletedCount", "Show completed (%d)") }
    static var tasksExpand: String { t("tasksExpand", "Details") }
    static var tasksNewProjectPrompt: String { t("tasksNewProjectPrompt", "Create new project:") }
    static var tasksNewProjectSave: String { t("tasksNewProjectSave", "Save") }
    static var tasksSnooze: String { t("tasksSnooze", "Snooze") }
    static var tasksRemove: String { t("tasksRemove", "Remove") }
    static var tasksDetailsTitle: String { t("tasksDetailsTitle", "Task details") }
    // "Fix" — the action on the Day Plan's over-capacity warning (report 2026-09-17_08-15-57).
    static var dayFixLink: String { t("dayFixLink", "Fix") }
    static var dayFixTitle: String { t("dayFixTitle", "Make today fit") }
    static var dayFixGap: String { t("dayFixGap", "Today is <DURATION> over what you can fit.") }
    static var dayFixMeetingsOption: String { t("dayFixMeetingsOption", "Cancel or shorten meetings") }
    static var dayFixMeetingsDetail: String { t("dayFixMeetingsDetail", "<DURATION> of meetings still to come") }
    static func dayFixMeetingShortenHint(_ day: String) -> String {
        String(format: t("dayFixMeetingShortenHint", "Applies on %@ only, and only on this Mac. The meeting on your calendar is untouched, so nobody else sees a change."), day)
    }
    static var dayFixMeetingShortenNoOptions: String { t("dayFixMeetingShortenNoOptions", "This meeting is already as short as it goes.") }
    static var dayFixRoutineOption: String { t("dayFixRoutineOption", "Shorten the routine") }
    static var dayFixRoutineDetail: String { t("dayFixRoutineDetail", "<DURATION> of habits before the evening routine") }
    static var dayFixTasksOption: String { t("dayFixTasksOption", "Postpone tasks") }
    static var dayFixTasksDetail: String { t("dayFixTasksDetail", "<DURATION> of tasks planned today") }
    static var dayFixNothingToFree: String { t("dayFixNothingToFree", "Nothing left on today can be shortened or moved from here.") }
    static var dayFixSkip: String { t("dayFixSkip", "Skip") }
    static var dayFixUnskip: String { t("dayFixUnskip", "Un-skip") }
    static var dayFixShorten: String { t("dayFixShorten", "Shorten") }
    static var dayFixBack: String { t("dayFixBack", "Back") }
    static var dayFixDone: String { t("dayFixDone", "Done") }
    static var tasksProjectLabel: String { t("tasksProjectLabel", "Project") }
    static var tasksProjectField: String { t("tasksProjectField", "Project (optional)") }
    static var tasksDurationLabel: String { t("tasksDurationLabel", "Duration (min)") }
    static var tasksSubtasksLabel: String { t("tasksSubtasksLabel", "Sub-tasks") }
    static var tasksDetailsLabel: String { t("tasksDetailsLabel", "Details") }
    static var tasksImportanceLabel: String { t("tasksImportanceLabel", "Importance") }
    static var tasksImportanceUnset: String { t("tasksImportanceUnset", "Not set") }
    static var tasksImportanceTooltip: String { t("tasksImportanceTooltip", "Importance %d (%@)") }
    static var tasksAddSubtask: String { t("tasksAddSubtask", "Add sub-task") }
    static var tasksSubtaskPlaceholder: String { t("tasksSubtaskPlaceholder", "Sub-task") }
    static var tasksSettings: String { t("tasksSettings", "Task settings") }
    static var tasksSelectedCount: String { t("tasksSelectedCount", "%d selected") }
    static var tasksClearSelection: String { t("tasksClearSelection", "Clear") }
    static var tasksAddNew: String { t("tasksAddNew", "Add task") }
    static var tasksAddFromList: String { t("tasksAddFromList", "From to-do list") }
    static var tasksEmpty: String { t("tasksEmpty", "No tasks yet. Add one from scratch or from your to-do list.") }
    static var tasksSearchPlaceholder: String { t("tasksSearchPlaceholder", "Search tasks…") }
    static var tasksAllProjects: String { t("tasksAllProjects", "All projects") }
    static var tasksAddSelected: String { t("tasksAddSelected", "Add") }
    static var tasksNamePlaceholder: String { t("tasksNamePlaceholder", "Task name") }
    static var tasksDragHint: String { t("tasksDragHint", "Drag onto a block to schedule it") }
    static var tasksReturnToPanel: String { t("tasksReturnToPanel", "Move back to tasks") }
    static var tasksTimeBoxed: String { t("tasksTimeBoxed", "Time boxed") }
    /// Tooltip on the time-boxed clock badge; `%@` is the block the task is pinned to.
    static var tasksTimeBoxedUnder: String { t("tasksTimeBoxedUnder", "Time boxed under %@") }
    static var tasksNotTimeBoxed: String { t("tasksNotTimeBoxed", "Not yet time boxed") }
    static var tasksSnoozeHint: String { t("tasksSnoozeHint", "Snooze — move to another day") }
    static var tasksSnoozeTitle: String { t("tasksSnoozeTitle", "Move task to…") }
    static var tasksSnoozePlaceholder: String { t("tasksSnoozePlaceholder", "e.g. 2d, -1d, tue, tom") }
    static var tasksSnoozeHelp: String { t("tasksSnoozeHelp", "2d = in 2 days · 2w = in 2 weeks · tue = next Tuesday · tom = tomorrow · 23 = the 23rd · -1d / yesterday = a past day · 1 Jul = a date") }
    static var tasksSnoozeConfirm: String { t("tasksSnoozeConfirm", "Move") }
    static var tasksSnoozeCancel: String { t("tasksSnoozeCancel", "Cancel") }
    static var tasksSnoozeSmart: String { t("tasksSnoozeSmart", "Choose a good time for me") }
    static var tasksSnoozeSmartInfo: String { t("tasksSnoozeSmartInfo", "Finds the next day which has sufficient free time for the task") }
    static func tasksSnoozeNextSlot(_ day: String) -> String { String(format: t("tasksSnoozeNextSlot", "Next free slot: %@"), day) }
    static var tasksDoesNotFitToday: String { t("tasksDoesNotFitToday", "Doesn't fit today") }
    static func tasksMoveToProjectedDay(_ day: String) -> String { String(format: t("tasksMoveToProjectedDay", "Move to %@"), day) }
    static var tasksNoProject: String { t("tasksNoProject", "No project") }
    static var tasksProjectHint: String { t("tasksProjectHint", "Type #project to group this task") }
    /// Shown when a typed task name is nothing but tokens, so stripping them leaves no name to save.
    /// It also says where the tokens belong, because a `#project` typed FIRST swallows the rest of the line.
    static var tasksNameNeeded: String { t("tasksNameNeeded", "Add a name for this task. Tags like #project, !priority and *minutes go after the name.") }
    // The dismissible card explaining the name-field shortcuts (report 2026-09-21_07-42-02). Each hint
    // is a whole sentence rather than a token plus a separate description, because the token has to sit
    // where the sentence puts it in each language — the shape `tasksProjectHint` already uses.
    static var tasksShortcutsTitle: String { t("tasksShortcutsTitle", "Shortcuts you can type in the name") }
    static var tasksShortcutsDismiss: String { t("tasksShortcutsDismiss", "Don't show this again") }
    static var tasksShortcutProject: String { t("tasksShortcutProject", "#project — file the task under a project") }
    static var tasksShortcutPriority: String { t("tasksShortcutPriority", "!1 to !5 — set importance (!5 is the most important)") }
    static var tasksShortcutMinutes: String { t("tasksShortcutMinutes", "*15 — set the duration to 15 minutes") }
    static var tasksShortcutDurationWords: String { t("tasksShortcutDurationWords", "30m, 2h or 1h30m — set the duration in words") }
    static var customRoutinesTitle: String { t("customRoutinesTitle", "Custom routines") }
    static var customRoutinesEmpty: String { t("customRoutinesEmpty", "No on-demand routines") }
    static var customRoutinesAfterCutoff: String { t("customRoutinesAfterCutoff", "On demand custom routines deactivated until tomorrow morning - time to wind down now") }
    // The habit player's "Tasks" pane: the Day Plan tasks dragged onto the habit being played.
    static var habitTasksTab: String { t("habitTasksTab", "Tasks") }
    static var habitTasksTitle: String { t("habitTasksTitle", "Tasks for this habit") }
    static var tabCustomRoutine: String { t("tabCustomRoutine", "Custom routine") }
    static var tabDayPlan: String { t("tabDayPlan", "Day Plan") }

    // Editing a habit from the Day Plan (the action bar's Edit button → DayPlanHabitEditor sheet).
    static var editHabit: String { t("editHabit", "Edit") }
    /// Caption on the habit action bar's Stats button (sits beside Edit).
    static var habitStats: String { t("habitStats", "Stats") }
    static var editHabitTitle: String { t("editHabitTitle", "Edit habit") }
    static var habitFieldName: String { t("habitFieldName", "Habit name") }
    static var habitFieldUseTimer: String { t("habitFieldUseTimer", "Use timer") }
    static var habitFieldDurationLabel: String { t("habitFieldDurationLabel", "Duration") }
    static var habitDurationMinutesUnit: String { t("habitDurationMinutesUnit", "min") }
    static var habitDurationSecondsUnit: String { t("habitDurationSecondsUnit", "sec") }
    static var habitFieldCompletion: String { t("habitFieldCompletion", "Habit finishes when…") }
    static var habitTabTiming: String { t("habitTabTiming", "Timing") }
    static var habitFieldPriority: String { t("habitFieldPriority", "Priority") }
    static var habitPriorityHigh: String { t("habitPriorityHigh", "Must do") }
    static var habitPriorityStandard: String { t("habitPriorityStandard", "Optional") }
    static var habitFieldDays: String { t("habitFieldDays", "Weekly schedule") }
    static var habitDaysWeekdays: String { t("habitDaysWeekdays", "Weekdays") }
    static var habitDaysWeekend: String { t("habitDaysWeekend", "Weekend") }
    static var habitDaysAll: String { t("habitDaysAll", "Every day") }
    static var habitFieldCutoff: String { t("habitFieldCutoff", "Late cutoff — skip this habit after") }
    static var habitTabVideos: String { t("habitTabVideos", "Add Videos") }
    static var habitFieldVideoUrls: String { t("habitFieldVideoUrls", "YouTube or Vimeo video links (one is played at random)") }
    static var habitTabAllowApps: String { t("habitTabAllowApps", "Allow Apps") }
    static var habitFieldAllowedApps: String { t("habitFieldAllowedApps", "Allowed apps") }
    static var habitFieldAllowedUrls: String { t("habitFieldAllowedUrls", "Allowed websites") }
    static var habitFieldRunMicroBreaks: String { t("habitFieldRunMicroBreaks", "Run micro-breaks during this habit") }
    static var habitFieldUseFocusMode: String { t("habitFieldUseFocusMode", "Use a focus mode (block list) instead of specific apps") }
    static var habitFieldFocusMode: String { t("habitFieldFocusMode", "Focus mode") }
    static var habitFieldShowSavedSites: String { t("habitFieldShowSavedSites", "Show the guilt-free play popup") }
    static var habitTabLogData: String { t("habitTabLogData", "Log Data") }
    static var habitFieldLogQuantity: String { t("habitFieldLogQuantity", "Ask me to log data after this habit") }
    static var habitFieldQuestion: String { t("habitFieldQuestion", "Question") }
    static var habitFieldMin: String { t("habitFieldMin", "Min") }
    static var habitFieldMax: String { t("habitFieldMax", "Max") }
    static var habitAddQuestion: String { t("habitAddQuestion", "Add question") }
    static var habitFieldLogType: String { t("habitFieldLogType", "Report as") }
    static var habitLogTypeSum: String { t("habitLogTypeSum", "Total") }
    static var habitLogTypeAverage: String { t("habitLogTypeAverage", "Average") }
    static var habitFieldTakeNotes: String { t("habitFieldTakeNotes", "Take notes") }
    static var habitNotesNone: String { t("habitNotesNone", "No notes") }
    static var habitNotesDuring: String { t("habitNotesDuring", "During the habit") }
    static var habitNotesEnd: String { t("habitNotesEnd", "At the end of the habit") }
    static var habitTabSubHabits: String { t("habitTabSubHabits", "Sub habits") }
    static var habitFieldChecklist: String { t("habitFieldChecklist", "Steps to tick off") }
    static var habitRandomChoicesNote: String { t("habitRandomChoicesNote", "This habit has %d random sub-habits. They're kept as they are — edit them on the web.") }
    static var habitTabInstructions: String { t("habitTabInstructions", "Instructions") }
    static var habitFieldInstructions: String { t("habitFieldInstructions", "Text instructions") }
    static var habitFieldImages: String { t("habitFieldImages", "Image links") }
    static var habitTabAdvanced: String { t("habitTabAdvanced", "Advanced") }
    static var habitFieldTags: String { t("habitFieldTags", "Tags") }
    static var habitAddItem: String { t("habitAddItem", "Add") }
    static var habitRemoveItem: String { t("habitRemoveItem", "Remove") }
    static var habitAllowedAppsPlaceholder: String { t("habitAllowedAppsPlaceholder", "Type an app name…") }
    static var habitAllowedAppsAddCustom: String { t("habitAllowedAppsAddCustom", "Add “%@”") }
    static var habitDelete: String { t("habitDelete", "Delete habit") }
    static var habitDeleteConfirm: String { t("habitDeleteConfirm", "Remove “%@” from this routine? It's gone once you save and restart.") }
    static var habitDeleteConfirmButton: String { t("habitDeleteConfirmButton", "Delete") }
    static var habitSave: String { t("habitSave", "Save") }
    static var habitCancel: String { t("habitCancel", "Cancel") }
    static var habitInvalidName: String { t("habitInvalidName", "Give the habit a name.") }
    static var habitInvalidDurationRange: String { t("habitInvalidDurationRange", "Duration must be between 1 second and 999 minutes.") }
    static var habitInvalidCompletion: String { t("habitInvalidCompletion", "Say what has to happen for the habit to count as done.") }
    static var habitInvalidDays: String { t("habitInvalidDays", "Pick at least one day.") }
    static var habitInvalidVideo: String { t("habitInvalidVideo", "Video links must be YouTube or Vimeo URLs.") }
    static var habitInvalidQuestions: String { t("habitInvalidQuestions", "Every question needs text, and min must be less than max.") }
    static var habitInvalidTags: String { t("habitInvalidTags", "Tags can only contain letters, spaces, underscores, brackets, commas, & and -.") }
    static var habitEditUnavailable: String { t("habitEditUnavailable", "This habit couldn't be found in your settings. Edit it from Settings › Edit habits instead.") }
    // Routine header "…" menu + the "Edit routine timing" sheet.
    static var routineMoreActions: String { t("routineMoreActions", "Routine options") }
    static var editRoutineTiming: String { t("editRoutineTiming", "Edit routine timing") }
    static var addNewHabit: String { t("addNewHabit", "Add new habit") }
    static var newHabitTitle: String { t("newHabitTitle", "New habit") }
    static var habitPickEmoji: String { t("habitPickEmoji", "Pick an emoji") }
    static var routineTimingQuestion: String { t("routineTimingQuestion", "When do you want %@ to start?") }
    static var routineTimingHint: String { t("routineTimingHint", "This moves the routine on every day it's scheduled.") }
    static var habitSkipAhead: String { t("habitSkipAhead", "Skip") }
    static var habitUnskipAhead: String { t("habitUnskipAhead", "Unskip") }
    // Shortening a habit for one day only (local, never sent to the server).
    static var habitShorten: String { t("habitShorten", "Shorten") }
    static var habitShortened: String { t("habitShortened", "Shortened") }
    static var habitShortenTitle: String { t("habitShortenTitle", "Shorten just for this day") }
    static func habitShortenMinutes(_ minutes: Int) -> String { String(format: t("habitShortenMinutes", "%d min"), minutes) }
    static func habitShortenFullLength(_ length: String) -> String { String(format: t("habitShortenFullLength", "Full length: %@"), length) }
    static var habitShortenFullLengthAction: String { t("habitShortenFullLengthAction", "Full length") }
    static func habitShortenHint(_ day: String) -> String {
        String(format: t("habitShortenHint", "Applies on %@ only, and only on this Mac. The habit keeps its real length everywhere else."), day)
    }
    static var habitShortenNoOptions: String { t("habitShortenNoOptions", "This habit is already as short as it goes.") }
    static var habitShortenTypePlaceholder: String { t("habitShortenTypePlaceholder", "e.g. 25min, 1h30") }
    static var habitShortenUseTyped: String { t("habitShortenUseTyped", "Use this length") }
    static var habitShortenTypeInvalid: String { t("habitShortenTypeInvalid", "Type a length like 25min, 1h30 or 90.") }
    static func habitShortenTypeNotShorter(_ length: String) -> String {
        String(format: t("habitShortenTypeNotShorter", "That isn't shorter than %@. Pick a smaller length, or use Full length to clear the trim."), length)
    }
    /// The small "(shortened)" after a trimmed habit's name in the day's list.
    static var habitShortenedTag: String { t("habitShortenedTag", "(shortened)") }
    static var eventScopeTitle: String { t("eventScopeTitle", "This is a repeating event") }
    static var eventScopeMessage: String { t("eventScopeMessage", "Change only this occurrence, or this one and every later one?") }
    static var eventScopeThis: String { t("eventScopeThis", "Only this event") }
    static var eventScopeFuture: String { t("eventScopeFuture", "All future events") }
    static var routineCutoffLabel: String { t("routineCutoffLabel", "Evening cutoff time") }
    static var routineCutoffHint: String { t("routineCutoffHint", "Optional evening habits stop at this time; must-do habits keep their own late cutoffs.") }
    static var routineCutoffInvalid: String { t("routineCutoffInvalid", "Choose a cutoff between the evening routine start and the next morning routine start.") }
    static var routineNameMorning: String { t("routineNameMorning", "your morning routine") }
    static var routineNameEvening: String { t("routineNameEvening", "your evening routine") }
    static var routineNameCustom: String { t("routineNameCustom", "this routine") }
    // Creating / editing custom routines from the Day Plan (DayPlanCustomRoutines).
    static var customRoutineManage: String { t("customRoutineManage", "Add or edit custom routines") }
    static var customRoutineNew: String { t("customRoutineNew", "New routine") }
    static var customRoutineNewTitle: String { t("customRoutineNewTitle", "New routine") }
    static var customRoutineEditTitle: String { t("customRoutineEditTitle", "Edit routine") }
    static var customRoutineBack: String { t("customRoutineBack", "All routines") }
    static var customRoutineNone: String { t("customRoutineNone", "You don't have any custom routines yet.") }
    static var customRoutineUntitled: String { t("customRoutineUntitled", "Untitled routine") }
    static var customRoutineFieldName: String { t("customRoutineFieldName", "Routine name") }
    static var customRoutineFieldTrigger: String { t("customRoutineFieldTrigger", "How it starts") }
    static var customRoutineTriggerScheduled: String { t("customRoutineTriggerScheduled", "At a scheduled time") }
    static var customRoutineTriggerOnDemand: String { t("customRoutineTriggerOnDemand", "On demand") }
    static var customRoutineOnDemandHint: String { t("customRoutineOnDemandHint", "An on-demand routine only starts when you press play on it, so it has no start time.") }
    static var customRoutineFieldStart: String { t("customRoutineFieldStart", "Starts at") }
    static var customRoutineFieldEnd: String { t("customRoutineFieldEnd", "Ends by") }
    static var customRoutineHabitsTitle: String { t("customRoutineHabitsTitle", "Habits in this routine") }
    static var customRoutineAddHabit: String { t("customRoutineAddHabit", "Add habit") }
    static var customRoutineRemoveHabit: String { t("customRoutineRemoveHabit", "Remove habit") }
    static var customRoutineMoveUp: String { t("customRoutineMoveUp", "Move up") }
    static var customRoutineMoveDown: String { t("customRoutineMoveDown", "Move down") }
    static var customRoutineEmptyHabits: String { t("customRoutineEmptyHabits", "Add at least one habit — a routine with no habits is dropped when your settings are saved.") }
    static var customRoutineCreate: String { t("customRoutineCreate", "Create routine") }
    static var customRoutineDelete: String { t("customRoutineDelete", "Delete routine") }
    static var customRoutineDeleteConfirm: String { t("customRoutineDeleteConfirm", "Delete this routine and all of its habits?") }
    static var customRoutineInvalidName: String { t("customRoutineInvalidName", "Give the routine a name.") }
    static var customRoutineInvalidWindow: String { t("customRoutineInvalidWindow", "The routine must end after it starts.") }
    static var customRoutineHabitCount: String { t("customRoutineHabitCount", "%d habits") }
    static var customRoutineHabitCountOne: String { t("customRoutineHabitCountOne", "1 habit") }
    static var customRoutineHabitUntilDone: String { t("customRoutineHabitUntilDone", "until done") }
    static var customRoutineDraftHint: String { t("customRoutineDraftHint", "Changes are drafted until you press “Save and restart app” on the Day Plan.") }
    static var customRoutineSummarySeparator: String { t("customRoutineSummarySeparator", " · ") }
    static var customRoutineDaySeparator: String { t("customRoutineDaySeparator", ", ") }
    // Drafted-changes banner at the top of the Day Plan.
    static var draftBanner: String { t("draftBanner", "Routine changes drafted: ready to save?") }
    static var draftSaveRestart: String { t("draftSaveRestart", "Save and restart app") }
    static var draftSaving: String { t("draftSaving", "Saving…") }
    static var draftSaveFailedTitle: String { t("draftSaveFailedTitle", "Couldn't save your routine changes") }
    static var draftSaveFailedMessage: String { t("draftSaveFailedMessage", "The server didn't accept the changes (status %d). Your draft is still here — check your connection and try again.") }
    static var draftSaveFailedServerSaid: String { t("draftSaveFailedServerSaid", "The server said:") }
    static var draftSaveFailedOk: String { t("draftSaveFailedOk", "OK") }
}

/// How much net free time a day has, and the (subtle) colour that represents it. Net free =
/// schedule-free minutes minus that day's tasks still to do, so it can be ≤ 0 (over-committed).
/// One place for the thresholds + colour mapping, shared by the tasks-panel header and the
/// date-picker calendar's per-day badges.
enum DayPlanFreeLevel {
    /// ≤ this many minutes free → red ("none left" / over-committed).
    static let noneMaxMinutes = 0
    /// ≤ this → orange (tight).
    static let tightMaxMinutes = 60
    /// ≤ this → blue (some); more than this → green (plenty).
    static let comfortableMaxMinutes = 120

    static func color(forFreeMinutes minutes: Int) -> NSColor {
        if minutes <= noneMaxMinutes { return .systemRed }
        if minutes <= tightMaxMinutes { return .systemOrange }
        if minutes <= comfortableMaxMinutes { return .systemBlue }
        return .systemGreen
    }
}

/// A shared duration scale for meetings, routines and deep-work blocks. Cards keep a
/// content-sized minimum for readability, but long blocks are no longer capped.
enum DayPlanEventHeight {
    static let pointsPerMinute: CGFloat = 0.55

    static func points(forDurationSeconds seconds: Int) -> CGFloat {
        guard seconds > 0 else { return 0 }
        return CGFloat(seconds) / 60 * pointsPerMinute
    }
}

/// The badge decision for one day in the date-picker's month grid, kept out of the AppKit cell so the
/// rule itself can be tested: **a day whose inputs have not loaded is unknown, never "fits"**.
///
/// Capacity is computed from the day's meetings, and `CalendarManager` answers the main thread from a
/// cache that holds nothing for a day until a background EventKit read lands. Feeding that cold [] into
/// the capacity model describes a completely free day — the top of the scale — so the first time the
/// picker opened, every future day it had never read painted GREEN, and only reopening it once the
/// refreshes had landed showed the real orange/red (report 2026-09-17_21-51-06). Optimism is the worst
/// possible default here: the badge exists precisely to warn that a day is already full.
///
/// No badge is the honest rendering of "not known yet" — the same blank a past day gets — and the
/// caller fills it in once the day's meetings have been read.
enum DayPlanDayBadge {
    /// - Parameters:
    ///   - isFuture: past days and today are never badged (today's free time is in the panel header).
    ///   - inputsAreLoaded: false while the day's meetings are still unread.
    ///   - netFreeMinutes: nil when the day has no schedule to measure. Evaluated only when it counts,
    ///     so an unknown day costs no schedule build.
    static func color(isFuture: Bool, inputsAreLoaded: Bool,
                      netFreeMinutes: @autoclosure () -> Int?) -> NSColor? {
        guard isFuture, inputsAreLoaded, let minutes = netFreeMinutes() else { return nil }
        return DayPlanFreeLevel.color(forFreeMinutes: minutes)
    }
}

/// Implemented by each habit-list screen that can present the Schedule tab
/// (the normal `firstViewController` and the postponed `routinePostponedInfoVc`),
/// so the Schedule view can read habits and drive actions against whichever screen
/// is currently on-screen.
protocol ScheduleHost: AnyObject {
    /// All routines to show today (active one + previews of evening / custom routines),
    /// each with the time window its habits may run in.
    func scheduleSegments(now: Date) -> [ScheduleRoutineSegment]
    func scheduleStart(index: Int)
    func scheduleDone(index: Int)
    func scheduleSkip(index: Int)
    /// Skip the rest of the active routine for today — opens the "choose which habits to do"
    /// sheet (equivalent of the Habits view's "I don't have time for all these habits").
    func scheduleSkipRoutineForToday()
    /// Re-sync the host's habit-list / Day-Plan visibility with the current state. Called by the
    /// Day Plan when it hides/shows its own content so the host list shows through (or stays hidden).
    func updateScheduleTabForState()
    /// Lightweight: re-apply ONLY the host habit-list's hidden state for the current Day-Plan content
    /// visibility. Unlike updateScheduleTabForState() this does NOT reload/auto-refresh, so it's safe
    /// to call from within a reload (setDayPlanContentHidden) without recursing.
    func refreshHabitListVisibilityForDayPlan()

    /// #2010: when a routine is force-cancelled we keep the whole Day Plan visible, but replace THAT
    /// routine's section with an "uncancel" message + button. Return the section to replace (its
    /// `routineName`, matched in makeHabitGroupCard) plus the message/button text, or nil if nothing is
    /// cancelled. Default: nil (only the between-routines state uses this).
    func cancelledRoutine() -> (sectionName: String, message: String, buttonTitle: String)?
    /// Perform the uncancel (force-uncomplete) for the cancelled routine — fired by that button.
    func uncancelRoutine()
    /// Mark a PAST morning habit as done **by id**, without disturbing the live routine. No Play (you
    /// can't start a past habit) and no Skip (an un-struck past habit is already evidently un-done).
    /// Surfaced both in today's "earlier today" accordion and when viewing a previous calendar day.
    /// `performedAt` is the habit's slot on that day, sent as the backdated completion time so the
    /// backend records it against the right date (via /completed-activity, same timestamps the offline
    /// activity-sync uses). Default no-op; only the active host (`firstViewController`) implements it.
    /// See `firstViewController.completePastHabit`.
    func schedulePastHabitDone(id: String, performedAt: Date)

    /// Whether cancelling the routine from the Day Plan ✕ should KEEP the window open (planning) rather
    /// than close it. The active-routine host (firstViewController) returns false — cancelling while a
    /// routine is in progress closes the window, like an in-routine skip. The planning hosts
    /// (routinePostponedInfoVc / habitsStateVc) keep it open and reload the Day Plan.
    var cancelRoutineKeepsWindowOpen: Bool { get }

    /// Whether this host can actually perform the live Play/Done/Skip habit actions. The between-
    /// routines host (`habitsStateVc`, `currentState == ._NOTHING_`) is READ-ONLY — its
    /// scheduleStart/Done/Skip are deliberate no-ops (the live flows + their skip-password gates only
    /// apply while a routine is active). A block can still be flagged `isActionable` there (e.g. an
    /// evening routine shown after it was force-completed), so the Schedule view must gate the
    /// Play/Done/Skip bar on THIS, not just `isActionable` — otherwise it renders a dead action bar
    /// whose buttons do nothing. Default true; only the idle between-routines host returns false.
    var supportsLiveHabitActions: Bool { get }
}

extension ScheduleHost {
    func cancelledRoutine() -> (sectionName: String, message: String, buttonTitle: String)? { nil }
    func uncancelRoutine() {}
    var supportsLiveHabitActions: Bool { true }
    // Default no-op so hosts that don't surface past habits (routinePostponedInfoVc, habitsStateVc)
    // needn't implement it — past-habit completion is only actionable on the active host.
    func schedulePastHabitDone(id: String, performedAt: Date) {}
    // Default: planning hosts keep the window open on cancel. Only firstViewController overrides (false).
    var cancelRoutineKeepsWindowOpen: Bool { true }
}

/// Shared helpers for installing the Schedule tab into a host habit screen. Each host
/// owns its own scheduleViewController instance (the view can only live in one place),
/// so this builds + wires the tab/container and maps habits to schedule inputs.
enum ScheduleTab {

    /// Adds the full-screen Day Plan container over the host's view, shown by default. Returns the
    /// new schedule VC (already a child). There's no longer a "Schedule | Habits" tab — the Day
    /// Plan is always shown; app state hides it during breaks to reveal the Habits view beneath.
    static func install(in host: NSViewController) -> scheduleViewController {
        let sched = scheduleViewController()
        host.addChild(sched)

        let container = sched.view
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        // Resolve against the view's own appearance (the window/app-theme), not NSApp's system one,
        // so the canvas behind the date bar isn't a white strip in Dark mode (or vice versa).
        container.layer?.backgroundColor = sched.resolvedCGColor(.textBackgroundColor, in: container)
        container.isHidden = false          // Day Plan is the default view now
        host.view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: host.view.topAnchor),
            container.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: host.view.bottomAnchor),
        ])
        return sched
    }

    /// Maps a routine's remaining habits to schedule inputs (index = live array position).
    /// When `dropCompleted` is true (today's actionable view), habits the server reports as already
    /// completed today are dropped (safety net over the arrFiltered* arrays). For other days this
    /// must be false, or tomorrow's routine would hide whatever you finished *today*. The original
    /// index is preserved on the kept habits so Play/Done/Skip still target the right row.
    static func habitInputs(from habits: [habit], now: Date, dropCompleted: Bool = true,
                            includeOptional: Bool = true) -> [ScheduleHabitInput] {
        // Completion is per-day: derive the day from `now` so a PAST-day view reflects that day's
        // (backdated) completions, not only today's — dayPlanCompletedHabitIds is today-only.
        let dayKey = getStringFromDate(date: now, dateFormat: "yyyy-MM-dd")
        return habits.enumerated().compactMap { idx, h in
            if !includeOptional && !h.isPriorityHigh { return nil }
            // Skipped ahead of time for this day: not part of the plan, and not counted as missed.
            if DayPlanHabitSkips.isSkipped(h.id, on: now) { return nil }
            if dropCompleted, let id = h.id, isHabitDoneForDay(id, dayKey: dayKey) { return nil }
            let playing = currentHabitPlaying?.id != nil && currentHabitPlaying?.id == h.id
            let done = h.id.map { isHabitDoneForDay($0, dayKey: dayKey) } ?? false
            return ScheduleHabitInput(index: idx,
                                      title: h.name ?? "Habit",
                                      durationSeconds: plannedDuration(for: h, on: now),
                                      isPlaying: playing,
                                      elapsedSeconds: 0,
                                      cutoff: timeToday(h.cutOffTime, now: now),
                                      isDone: done,
                                      id: h.id)
        }
    }

    /// Duration to schedule a habit for on `day` — its real length, trimmed by a "shorten for this
    /// day" override if the user set one. Every Day Plan and forecast input goes through here, so the
    /// trim re-flows the whole day (and its capacity numbers) without touching the habit itself.
    static func plannedDuration(for h: habit, on day: Date) -> Int {
        DayPlanHabitDurations.effectiveSeconds(for: h.id, on: day, actual: estimatedDuration(for: h))
    }

    /// The routine habit with this server id, wherever it lives — the morning routine, the evening
    /// routine, or any custom routine. Used by actions addressed by habit id rather than row index.
    static func routineHabit(withId id: String) -> habit? {
        let lists = [arrAllDaysMorningHabits, arrAllDaysEveningHabits] + arrAllCustomRoutine.map { $0.arrAllHabits }
        for list in lists {
            if let found = list.first(where: { $0.id == id }) { return found }
        }
        return nil
    }

    /// Duration to schedule a habit for. Timer habits use their set duration; non-timer
    /// habits (which have no fixed duration) use the average of their recently recorded
    /// durations so they show with a realistic estimate instead of collapsing to ~0.
    static func estimatedDuration(for h: habit) -> Int {
        if h.useTimer {
            let d = h.durationSeconds ?? 0
            return (d > 0 && d < 86400) ? d : 5 * 60   // 86400 is the "no duration set" sentinel
        }
        if let id = h.id, let past = nonTimerBasedHabitsObject.arrNonTimerBasedHabitsDurations[id], !past.isEmpty {
            let avg = past.reduce(0, +) / past.count
            if avg > 0 { return avg }
        }
        return 60   // no history yet — a sensible default for a quick log-style habit
    }

    /// Builds the day's routine segments: the active routine (actionable), plus read-only
    /// previews of the evening routine and any custom routines scheduled later today.
    static func standardSegments(activeName: String,
                                 activeHabits: [ScheduleHabitInput],
                                 isMorningActive: Bool,
                                 now: Date) -> [ScheduleRoutineSegment] {
        var segs = [ScheduleRoutineSegment]()
        let cal = Calendar.current
        let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now
        let eveningStart = timeToday(shutOffTime, now: now)

        // Active routine: capped at the evening start when it's the morning/day routine.
        let activeEnd = (isMorningActive && (eveningStart.map { $0 > now } ?? false)) ? eveningStart! : endOfDay
        segs.append(ScheduleRoutineSegment(name: activeName, habits: activeHabits,
                                           windowStart: now, windowEnd: activeEnd, actionable: true))

        // Evening routine preview, once the morning/day routine hands off at the shutdown time.
        if isMorningActive, let es = eveningStart, es > now {
            let eveningHabits = habitInputs(from: arrAllDaysEveningHabits, now: now)
            if !eveningHabits.isEmpty {
                segs.append(ScheduleRoutineSegment(name: ScheduleText.eveningRoutineHabits, habits: eveningHabits,
                                                   windowStart: es, windowEnd: endOfDay, actionable: false))
            }
        }

        // Custom routines scheduled later today, shown in their own time block.
        for r in arrAllCustomRoutine {
            guard isScheduledToday(r.days_of_week), let st = timeToday(r.startTime, now: now), st > now else { continue }
            let source = r.arrAllFilteredHabits.isEmpty ? r.arrAllHabits : r.arrAllFilteredHabits
            let habitsC = habitInputs(from: source, now: now)
            guard !habitsC.isEmpty else { continue }
            let totalDur = Double(habitsC.reduce(0) { $0 + $1.durationSeconds })
            let end = (timeToday(r.endTime, now: now).flatMap { $0 > st ? $0 : nil }) ?? st.addingTimeInterval(totalDur)
            segs.append(ScheduleRoutineSegment(name: "\(r.title) \(ScheduleText.habitsSuffix)", habits: habitsC,
                                               windowStart: st, windowEnd: end, actionable: false))
        }
        return segs
    }

    static func timeToday(_ t: Time?, now: Date) -> Date? {
        guard let t = t else { return nil }
        return Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: t.second, of: now)
    }

    static func isScheduledToday(_ days: [String]) -> Bool {
        isScheduledOn(days, weekday: Date().dayOfWeek())
    }

    /// Whether a days-of-week list ("all"/"weekdays"/"weekend"/named days) includes `weekday`.
    static func isScheduledOn(_ days: [String], weekday: String) -> Bool {
        if days.isEmpty { return true }
        let wd = weekday.lowercased()
        let isWeekend = wd.hasPrefix("sat") || wd.hasPrefix("sun")
        for d in days {
            let dl = d.lowercased()
            if dl == "all" { return true }
            if dl == "weekdays" && !isWeekend { return true }
            if dl == "weekend" && isWeekend { return true }
            if wd.hasPrefix(String(dl.prefix(3))) { return true }
        }
        return false
    }

    static func timeOnDate(_ t: Time?, date: Date) -> Date? {
        guard let t = t else { return nil }
        return Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: t.second, of: date)
    }

    static func filterByWeekday(_ habits: [habit], weekday: String) -> [habit] {
        habits.filter { isScheduledOn($0.days_of_week, weekday: weekday) }
    }

    /// Read-only timetable segments for an arbitrary day (past or future): morning + evening
    /// routine habits scheduled for that weekday, plus custom routines scheduled then. All
    /// non-actionable — you can't act on another day's habits. The portfolio forecast excludes
    /// optional evening habits before placement; the actual Day Plan keeps its full routine.
    static func segmentsForDate(_ date: Date, includeCompleted: Bool = false,
                                includeOptionalEvening: Bool = true) -> [ScheduleRoutineSegment] {
        var segs = [ScheduleRoutineSegment]()
        let cal = Calendar.current
        let weekday = date.dayOfWeek()
        let dayStart = cal.startOfDay(for: date)
        let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 0, of: date) ?? date
        let morningStart = timeOnDate(startTime, date: date) ?? dayStart
        let eveningStart = timeOnDate(shutOffTime, date: date)
        // Only filter out "already completed" habits when previewing TODAY — for other days the full
        // routine should show (dayPlanCompletedHabitIds only reflects today's completions).
        let isToday = cal.isDateInToday(date)

        let morning = habitInputs(from: filterByWeekday(arrAllDaysMorningHabits, weekday: weekday), now: morningStart, dropCompleted: isToday && !includeCompleted)
        if !morning.isEmpty {
            segs.append(ScheduleRoutineSegment(name: ScheduleText.morningRoutineHabits, habits: morning,
                                               windowStart: morningStart, windowEnd: eveningStart ?? endOfDay,
                                               actionable: false))
        }
        if let es = eveningStart {
            let evening = habitInputs(from: filterByWeekday(arrAllDaysEveningHabits, weekday: weekday), now: es,
                                      dropCompleted: isToday && !includeCompleted, includeOptional: includeOptionalEvening)
            if !evening.isEmpty {
                segs.append(ScheduleRoutineSegment(name: ScheduleText.eveningRoutineHabits, habits: evening,
                                                   windowStart: es, windowEnd: endOfDay, actionable: false))
            }
        }
        for r in arrAllCustomRoutine {
            guard isScheduledOn(r.days_of_week, weekday: weekday), let st = timeOnDate(r.startTime, date: date) else { continue }
            let habitsC = habitInputs(from: r.arrAllHabits, now: st, dropCompleted: isToday && !includeCompleted)
            guard !habitsC.isEmpty else { continue }
            let totalDur = Double(habitsC.reduce(0) { $0 + $1.durationSeconds })
            let end = timeOnDate(r.endTime, date: date).flatMap { $0 > st ? $0 : nil } ?? st.addingTimeInterval(totalDur)
            segs.append(ScheduleRoutineSegment(name: "\(r.title) \(ScheduleText.habitsSuffix)", habits: habitsC,
                                               windowStart: st, windowEnd: end, actionable: false))
        }
        return segs
    }
}

/// A non-editable multi-line label that keeps `preferredMaxLayoutWidth` synced to its laid-out
/// width and reports its wrapped height — so a long schedule title wraps/truncates within its
/// column instead of demanding a huge width (which blew the window out past the screen edge).
final class WrappingScheduleLabel: NSTextField {
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if abs(preferredMaxLayoutWidth - newSize.width) > 0.5 {
            preferredMaxLayoutWidth = newSize.width
            invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: NSSize {
        let width = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        guard width > 0, let cell = self.cell else {
            return NSSize(width: NSView.noIntrinsicMetric, height: super.intrinsicContentSize.height)
        }
        let measured = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        return NSSize(width: NSView.noIntrinsicMetric, height: ceil(measured.height))
    }
}

/// A row that reliably captures a click anywhere on it (plain NSClickGestureRecognizer gets
/// swallowed by the child text fields), used to select a habit and reveal its action bar.
final class ClickableRowView: NSView {
    var onClick: (() -> Void)?
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard onClick != nil else { return super.hitTest(point) }
        return NSPointInRect(point, frame) ? self : nil
    }
    override func mouseDown(with event: NSEvent) {
        if onClick != nil { onClick?() } else { super.mouseDown(with: event) }
    }
}

/// A plain container view that calls back when the system Light/Dark appearance flips — used to
/// re-apply layer cgColor backgrounds (which AppKit does NOT auto-update) and rebuild the cards.
final class AppearanceReactiveView: NSView {
    var onAppearanceChange: (() -> Void)?
    /// Fired whenever this view is added to (or removed from) a window — used to catch up a render that
    /// was skipped while the view had no window. NSViewController has no window-attach callback, so the
    /// container view forwards NSView's viewDidMoveToWindow up to the VC.
    var onDidMoveToWindow: (() -> Void)?
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onDidMoveToWindow?()
    }
}

class scheduleViewController: NSViewController {

    /// A flipped clip view makes the scroll view lay its document out top-to-bottom
    /// (AppKit's default clip is bottom-up, which left content invisible/cramped).
    final class FlippedClipView: NSClipView { override var isFlipped: Bool { true } }

    private let scrollView = NSScrollView()
    /// Pinned between the date bar and the schedule scroll view (so it never scrolls away) — holds the
    /// "Routine changes drafted" banner while DayPlanRoutineDraft has changes, otherwise it's empty (0pt).
    private let draftBannerContainer = NSStackView()
    private let stackView = NSStackView()
    private let tasksPanel = DayPlanTasksPanel()
    private let customRoutinesPanel = CustomRoutinesPanel()
    private let panelResizeHandle = PanelResizeHandle()
    private var tasksPanelWidthConstraint: NSLayoutConstraint?
    private let kTasksPanelWidth = "dayPlanPanelWidth"
    private let tasksPanelMinWidth: CGFloat = 260
    private let tasksPanelMaxWidth: CGFloat = 600
    private var refreshTimer: Timer?
    private var didBecomeActiveObserver: NSObjectProtocol?
    /// Watches for a background meetings refresh landing (see CalendarManager.meetingsDidChange).
    private var meetingsChangedObserver: NSObjectProtocol?
    private var dayChangedObserver: NSObjectProtocol?
    private var forecastSettingsObserver: NSObjectProtocol?
    /// True while the Day Plan is showing "today" and should FOLLOW the day across midnight (the default).
    /// Cleared when the user navigates to a specific other day; re-set when they return to today.
    private var followingToday = true
    private var postponeHiddenObservation: NSKeyValueObservation?
    private var viewHiddenObservation: NSKeyValueObservation?
    private var hasPendingRenderWhileHidden = false
    private var dateBarTopConstraint: NSLayoutConstraint?
    private var crHeightConstraint: NSLayoutConstraint?
    // Two leading positions for the settings cog: top-left by default, or just right of the
    // [Custom routine | Day Plan] toggle while that toggle occupies the corner (so they don't overlap).
    private var cogLeadingDefault: NSLayoutConstraint?
    private var cogLeadingBesideToggle: NSLayoutConstraint?
    // When a custom routine is active, a toggle lets the user switch between viewing the active
    // routine and the full Day Plan. true = show the Day Plan instead of the active routine.
    private let routineToggle = NSSegmentedControl()
    private var showDayPlanDuringRoutine = false
    /// True while the Day Plan's own content is hidden (e.g. the "Custom routine" tab, which reveals
    /// the host's habit list underneath). The host reads this so it doesn't *also* hide that list,
    /// which would leave a blank screen.
    private(set) var isDayPlanContentHidden = false

    // Date navigation bar (‹ date › Today).
    private let dateLabelButton = cursorButton()
    private let todayButton = cursorButton()
    private let scheduleCog = cursorButton()
    private var scheduleSettingsPopover: NSPopover?
    private let todayIndicatorLabel = NSTextField(labelWithString: "")
    private let addEventButton = cursorButton()
    /// Add-event button's vertical alignment vs. the date bar. Normally 0 (centred). For the
    /// allowed-activity Day Plan overlay it's dropped a little so it clears the "Habit Player | Day
    /// Plan" tab bar sitting at the top of that overlay (#2083). fileprivate so the host VC can set it
    /// on the overlay instance it creates.
    fileprivate var addEventCenterYConstraint: NSLayoutConstraint?
    /// Date bar's horizontal offset from the schedule column centre. Normally 0. For the allowed-
    /// activity Day Plan overlay it's shifted left so the date's ▶ arrow clears the centred
    /// "Habit Player | Day Plan" tabs (#2083). fileprivate so the host VC can set it on the overlay.
    fileprivate var dateBarCenterXConstraint: NSLayoutConstraint?
    private var datePopover: NSPopover?
    private var dismissRepeatingPopover: NSPopover?

    // "Add event" form state (rebuilt each time the popover opens).
    private var addEventPopover: NSPopover?
    private var addTitleField: NSTextField?
    private var addCalendarPopup: NSPopUpButton?
    private var addStartPicker: EventDateTimeField?
    private var addEndPicker: EventDateTimeField?
    private var addRecurrencePopup: NSPopUpButton?
    private var addNotesView: NSTextView?
    /// The description exactly as the calendar stores it (HTML), kept so an untouched description is
    /// saved back unchanged instead of being replaced by its rendered plain text.
    private var addNotesSourceHTML = ""
    /// What `addNotesSourceHTML` renders to — the yardstick for "did the user actually edit this?".
    private var addNotesRenderedText = ""
    private var addPrivateNotesView: NSTextView?
    private var addErrorLabel: NSTextField?
    private var addCalendarIDs: [String] = []
    /// True when the calendar popup's selection actually reflects a choice (the event's real calendar, or
    /// the default for a new event). False when the event's calendar couldn't be resolved — the popup is
    /// then showing an unrelated calendar and saving must leave the event's calendar alone.
    private var addCalendarIsUserChoice = false
    /// Event id being edited (nil = creating a new event).
    private var editingEventID: String?
    /// The occurrence of a recurring event the open editor is editing, when known.
    private var editingEventOccurrence: (start: Date, end: Date)?
    /// Which occurrences the open edit applies to, chosen when the form opened (nil = not repeating).
    private var editingEventScope: EKSpan?
    /// True when the event being edited is NOT owned by the current user (a meeting someone else
    /// organised). The save then can't touch the shared calendar, so we store a local, day-plan-only
    /// override instead and warn the user in the form.
    private var editingEventIsNotOwned = false
    /// Who owns the event being edited — decides whether the editor's destructive action is
    /// "Cancel Event" (the user organises it) or "Decline event" (an invitation, or ownership EventKit
    /// can't establish). See EventCancellation.swift.
    private var editingEventOwnership: EventOwnership = .unknown
    /// Whether the event being edited repeats, so the destructive action knows to ask
    /// this-occurrence-vs-series before removing anything.
    private var editingEventIsRecurring = false
    private var addSelectedColor: NSColor?
    private var addColorButtons: [NSButton] = []

    // "Add from to-do list" picker state.
    private var todoPopover: NSPopover?
    private var todoAllTasks: [NSDictionary] = []
    private var todoSearchWorkItem: DispatchWorkItem?   // debounces the backend to-do search
    private var todoSelectedIDs = Set<String>()
    private var todoSearch = ""
    private var todoProjectFilterID: String?
    private var todoProjectIDs: [String] = []
    private weak var todoListStack: NSStackView?
    /// Fixed palette for per-event colour (first = default meeting blue).
    private static let eventColorPalette: [NSColor] = [
        .systemBlue, .systemRed, .systemOrange, .systemGreen, .systemPurple, .systemTeal
    ]

    /// The habit-list screen currently presenting the Schedule tab.
    weak var host: ScheduleHost?

    /// Routine-array index of the habit whose action bar is shown (nil = the next-up habit).
    private var selectedHabitIndex: Int?
    /// Habit id of the PAST habit whose Done action bar is shown (click-to-reveal, like the live view).
    /// Kept separate from selectedHabitIndex because past habits are keyed by id, not live-array index.
    private var selectedPastHabitId: String?
    /// The selected habit of a preview/future routine (editable, not actionable) — shows an Edit-only bar.
    private var selectedEditableHabitId: String?

    // Temporary full-screen exit while granting calendar permission.
    private var grantCountdownWindow: NSWindow?
    private var grantCountdownTimer: Timer?
    private var grantCountdownLabel: NSTextField?
    private var grantSecondsLeft = 0

    // Calendar permission banner (shown until access is granted or dismissed).
    private var bannerBox: NSView?
    private var bannerDismissed = false

    /// When viewing today, also show calendar events that already finished earlier in the day.
    private var showEarlierEvents = false

    /// Persisted setting: hide deep-work blocks in the Day Plan, so it's easier to just see
    /// appointments. Deep-work time still counts as free/taskable; the blocks are just not drawn.
    private var hideDeepWorkBlocks: Bool {
        get { UserDefaults.standard.bool(forKey: "kUserdefaultsHideDeepWorkInDayPlan") }
        set { UserDefaults.standard.set(newValue, forKey: "kUserdefaultsHideDeepWorkInDayPlan") }
    }

    /// Persisted setting: hide habit/routine blocks in the Day Plan, so the user sees just their
    /// calendar events. The habits still run as normal; the routine accordion rows are just not drawn.
    private var hideHabitBlocks: Bool {
        get { UserDefaults.standard.bool(forKey: "kUserdefaultsHideHabitsInDayPlan") }
        set { UserDefaults.standard.set(newValue, forKey: "kUserdefaultsHideHabitsInDayPlan") }
    }

    /// Persisted setting: show events the user dismissed (✕) — rendered struck-through with a 👀 to
    /// bring them back — instead of hiding them.
    private var showDismissedEvents: Bool {
        get { UserDefaults.standard.bool(forKey: "kUserdefaultsShowDismissedEventsInDayPlan") }
        set { UserDefaults.standard.set(newValue, forKey: "kUserdefaultsShowDismissedEventsInDayPlan") }
    }

    /// Explicit expand/collapse overrides for routine sections (accordions), keyed by
    /// "routineName|dayOrdinal|sectionId", where sectionId is the section's FIRST habit id. A day can
    /// hold several same-named routine sections (e.g. two "Morning routine habits" runs split by a
    /// meeting), and keying by name alone made them all toggle together (#accordion). The first-habit
    /// id is unique per section AND stable across reloads — unlike the section start, which for the
    /// active routine re-packs from `now` every reload, so a start-keyed override went stale between
    /// the header click and the re-render and the toggle silently did nothing. Absent → default:
    /// collapsed on future days, expanded today/past.
    private var routineCollapseOverrides: [String: Bool] = [:]

    /// #2010: routine sections surfaced as *earlier today* items under the "Show events from earlier
    /// today" toggle (currently the past morning routine, once the evening routine has started). They
    /// default to collapsed even on today — they're history, shown alongside the earlier meetings —
    /// unlike the active routine. Rebuilt each reload(); a user click still overrides (see below).
    private var earlierRoutineNames: Set<String> = []

    // A routine can appear as several separate cards in one day (e.g. a morning routine split around a
    // meeting, plus its "not enough time" overflow card). Keying only by name|day made them share one
    // accordion state, so expanding one expanded them all — include the group's start so each card
    // toggles independently.
    private func routineCollapseKey(_ name: String, date: Date, sectionId: String, overflow: Bool = false) -> String {
        // Key by the section's FIRST-habit id (unique + stable per card) — NOT the group start time,
        // which the active routine re-packs from `now` (unstable across reloads) and which the "not
        // enough time today" overflow card can share with the active card (so toggling the overflow card
        // toggled the active card above it). The overflow flag is kept as belt-and-suspenders.
        "\(name)|\(Int(date.timeIntervalSince1970 / 86400))|\(sectionId)\(overflow ? "|of" : "")"
    }
    private func isRoutineCollapsed(name: String, date: Date, sectionId: String, completed: Bool = false, overflow: Bool = false) -> Bool {
        if let explicit = routineCollapseOverrides[routineCollapseKey(name, date: date, sectionId: sectionId, overflow: overflow)] { return explicit }
        // Past routines shown under the "earlier today" toggle start collapsed even on today.
        if earlierRoutineNames.contains(name) { return true }
        // A finished routine (every habit done) collapses by default — it's history, no need to fill the
        // plan with struck-through rows — but a user expand still wins (the override above).
        if completed { return true }
        // Default: future days start collapsed; today (and past) stay expanded.
        return Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }
    private func toggleRoutineCollapsed(name: String, date: Date, sectionId: String, completed: Bool = false, overflow: Bool = false) {
        let key = routineCollapseKey(name, date: date, sectionId: sectionId, overflow: overflow)
        routineCollapseOverrides[key] = !isRoutineCollapsed(name: name, date: date, sectionId: sectionId, completed: completed, overflow: overflow)
        lastRenderSignature = nil
        reload()
    }

    /// Expand/collapse overrides for deep-work sessions (a consecutive run of deep-work + break
    /// blocks), keyed by "dayOrdinal|dw|runIndex". Runs collapse into one accordion row by default so
    /// the plan shows a single "Deep work · 9:03am–12pm" line instead of every sprint and break.
    private var deepWorkCollapseOverrides: [String: Bool] = [:]
    private func deepWorkCollapseKey(runIndex: Int, date: Date) -> String {
        "\(Int(date.timeIntervalSince1970 / 86400))|dw|\(runIndex)"
    }
    private func isDeepWorkCollapsed(runIndex: Int, date: Date) -> Bool {
        deepWorkCollapseOverrides[deepWorkCollapseKey(runIndex: runIndex, date: date)] ?? true   // collapsed by default
    }
    private func toggleDeepWorkCollapsed(runIndex: Int, date: Date) {
        let key = deepWorkCollapseKey(runIndex: runIndex, date: date)
        deepWorkCollapseOverrides[key] = !isDeepWorkCollapsed(runIndex: runIndex, date: date)
        lastRenderSignature = nil
        reload()
    }
    /// Whether the "Show/Hide events from earlier today" toggle is relevant for what's on screen.
    private var canShowEarlierToggle = false

    override func loadView() {
        let root = AppearanceReactiveView()
        root.wantsLayer = true
        // Resolve against the window's (app-theme) appearance, not NSApp's system-following one.
        root.layer?.backgroundColor = resolvedCGColor(.textBackgroundColor, in: root)
        // Layer cgColors don't flip on a live Light/Dark switch — re-apply the canvas + rebuild cards.
        root.onAppearanceChange = { [weak self, weak root] in
            guard let self = self else { return }
            if !self.scrollView.isHidden, let root = root {
                root.layer?.backgroundColor = self.resolvedCGColor(.textBackgroundColor, in: root)
            }
            self.reload()
            self.tasksPanel.reload()
        }
        // Catch up a render skipped while this view had no window (see the guard in render(blocks:)) the
        // moment it's attached to one — the window-attach counterpart to the isHidden KVO catch-up in
        // startAutoRefresh(). render() re-checks both conditions, so it stays skipped if still hidden.
        root.onDidMoveToWindow = { [weak self] in
            guard let self = self, self.view.window != nil, !self.view.isHidden,
                  self.hasPendingRenderWhileHidden else { return }
            self.hasPendingRenderWhileHidden = false
            self.reload()
        }

        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 8
        // The tab now lives in its own header bar above this scroll view, so only a small
        // breathing inset is needed at the top.
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let clip = FlippedClipView()
        clip.drawsBackground = false
        scrollView.contentView = clip
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        // Legacy scrollers reserve layout width, so the clip (and our cards) never sit under
        // an overlay scrollbar — that was clipping the Skip button at the right edge.
        scrollView.scrollerStyle = .legacy
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor   // adapts to dark mode (was hardcoded white)
        scrollView.documentView = stackView

        let dateBar = makeDateBar()
        // "Tasks for today" side panel on the right, with a hairline separator.
        tasksPanel.translatesAutoresizingMaskIntoConstraints = false
        tasksPanel.onChange = { [weak self] in self?.refreshTasksHighlights() }
        tasksPanel.onAddFromList = { [weak self] in self?.showTodoPicker() }
        // Smart snooze asks the host (which owns the routine/calendar → schedule build) how much free
        // time a future day has, so it can move a task to the next day it actually fits.
        tasksPanel.scheduleFreeMinutesForDate = { scheduleViewController.scheduleFreeMinutes(on: $0) }
        // The Fix modal's routine route drives exactly the same skip/shorten paths the Day Plan rows
        // already use — the panel asks the host rather than reaching into habits itself, because the
        // day's blocks live here (report 2026-09-17_08-15-57).
        tasksPanel.dayFixHabits = { [weak self] in self?.dayFixHabitRows() ?? [] }
        tasksPanel.dayFixSkipHabit = { [weak self] id in
            guard let self = self else { return }
            _ = DayPlanHabitSkips.toggle(id, on: self.selectedDate)
            addLog(text: "[user-action] day plan: habit skip toggled from Fix for \(DayPlanHabitDurations.dayKey(self.selectedDate))")
            self.reloadAfterShorten()
        }
        tasksPanel.dayFixShortenHabit = { [weak self] id in self?.openShortenHabitSheet(habitId: id) }
        // The meetings route asks the host for the same reason: the day's meetings (and the editor's
        // cancel/decline flow) live here, not in the tasks panel.
        tasksPanel.dayFixMeetings = { [weak self] in self?.dayFixMeetingRows() ?? [] }
        tasksPanel.dayFixSkipMeeting = { [weak self] row in self?.dayFixToggleSkipMeeting(row) }
        tasksPanel.dayFixCancelMeeting = { [weak self] row in self?.dayFixCancelMeeting(row) }
        tasksPanel.dayFixShortenMeeting = { [weak self] row in self?.dayFixShortenMeeting(row) }
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false

        // Custom Routines panel sits at the bottom of the right column (1/5 of the height), with a
        // hairline above it separating it from the tasks panel.
        customRoutinesPanel.translatesAutoresizingMaskIntoConstraints = false
        let crSeparator = NSView()
        crSeparator.wantsLayer = true
        // A plain separatorColor hairline between two same-coloured panels is nearly invisible —
        // use a more contrasty line so the division reads clearly.
        crSeparator.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.2).cgColor
        crSeparator.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(dateBar)
        root.addSubview(addEventButton)        // pinned to the right of the schedule column
        // Schedule settings cog, top-left of the column (holds "show earlier events" etc).
        scheduleCog.bezelStyle = .inline; scheduleCog.isBordered = false
        if #available(macOS 11.0, *) { scheduleCog.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Schedule settings") } else { scheduleCog.title = "⚙" }
        scheduleCog.contentTintColor = .secondaryLabelColor
        scheduleCog.toolTip = ScheduleText.scheduleSettings
        scheduleCog.target = self; scheduleCog.action = #selector(openScheduleSettings(_:))
        scheduleCog.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(scheduleCog)
        draftBannerContainer.orientation = .vertical
        draftBannerContainer.alignment = .width
        draftBannerContainer.spacing = 0
        draftBannerContainer.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(draftBannerContainer)
        root.addSubview(scrollView)
        root.addSubview(separator)
        root.addSubview(tasksPanel)
        root.addSubview(customRoutinesPanel)
        customRoutinesPanel.onManage = { [weak self] in self?.openCustomRoutineManager() }
        root.addSubview(crSeparator)

        // Toggle shown only while a custom routine is active: [Custom routine | Day Plan].
        routineToggle.segmentCount = 2
        routineToggle.setLabel(ScheduleText.tabCustomRoutine, forSegment: 0)
        routineToggle.setLabel(ScheduleText.tabDayPlan, forSegment: 1)
        routineToggle.selectedSegment = 0
        routineToggle.segmentStyle = .rounded
        routineToggle.target = self
        routineToggle.action = #selector(routineToggleChanged)
        routineToggle.isHidden = true
        routineToggle.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(routineToggle)

        // Draggable resize strip sitting over the separator (added last so it's on top).
        panelResizeHandle.translatesAutoresizingMaskIntoConstraints = false
        panelResizeHandle.onResize = { [weak self] dx in
            guard let self = self, let c = self.tasksPanelWidthConstraint else { return }
            // Panel is pinned to the right edge: dragging the strip left (dx < 0) widens it.
            let newW = min(self.tasksPanelMaxWidth, max(self.tasksPanelMinWidth, c.constant - dx))
            c.constant = newW
            UserDefaults.standard.set(Double(newW), forKey: self.kTasksPanelWidth)
        }
        root.addSubview(panelResizeHandle)

        let savedPanelWidth = UserDefaults.standard.object(forKey: kTasksPanelWidth) as? Double
        let initialPanelWidth = CGFloat(savedPanelWidth.map { min(Double(tasksPanelMaxWidth), max(Double(tasksPanelMinWidth), $0)) } ?? 340)
        let panelWidth = tasksPanel.widthAnchor.constraint(equalToConstant: initialPanelWidth)
        tasksPanelWidthConstraint = panelWidth

        NSLayoutConstraint.activate([
            panelWidth,
            // Grab strip straddling the separator, full height.
            panelResizeHandle.centerXAnchor.constraint(equalTo: separator.centerXAnchor),
            panelResizeHandle.topAnchor.constraint(equalTo: root.topAnchor),
            panelResizeHandle.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            panelResizeHandle.widthAnchor.constraint(equalToConstant: 10),
        ])
        let dateBarTop = dateBar.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 14)
        dateBarTopConstraint = dateBarTop
        let dateBarCenterX = dateBar.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
        dateBarCenterXConstraint = dateBarCenterX
        let crHeight = customRoutinesPanel.heightAnchor.constraint(equalToConstant: customRoutinesPanel.preferredHeight)
        crHeight.priority = .defaultHigh   // yields to the ≤1/5 max above
        crHeightConstraint = crHeight
        // Cog leading: default top-left; alternate sits just right of the routine toggle (activated in
        // updateRoutineToggle while the toggle is shown, so the cog doesn't land on the toggle).
        let cogLeadDefault = scheduleCog.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16)
        cogLeadingDefault = cogLeadDefault
        cogLeadingBesideToggle = scheduleCog.leadingAnchor.constraint(equalTo: routineToggle.trailingAnchor, constant: 10)
        let addEventCenterY = addEventButton.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor)
        addEventCenterYConstraint = addEventCenterY
        NSLayoutConstraint.activate([
            // ("Back to today" now lives under the date inside the date bar — see makeDateBar.)
            // Settings cog, level with the date line (centred on the date-bar row with the toggle/add).
            cogLeadDefault,
            scheduleCog.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor),
            // Custom-routine toggle sits top-left, level with the date bar (only visible during an
            // active custom routine, when "Back to today" is hidden since you're on today).
            routineToggle.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor),
            routineToggle.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            // Tasks panel: right-edge column, from the top down to the Custom Routines panel.
            tasksPanel.topAnchor.constraint(equalTo: root.topAnchor),
            tasksPanel.bottomAnchor.constraint(equalTo: crSeparator.topAnchor),
            tasksPanel.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            // width is set via tasksPanelWidthConstraint above (default 340, user-resizable)
            separator.trailingAnchor.constraint(equalTo: tasksPanel.leadingAnchor),
            separator.topAnchor.constraint(equalTo: root.topAnchor),
            separator.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            separator.widthAnchor.constraint(equalToConstant: 1),

            // Custom Routines panel: bottom of the right column, 1/5 of the window height, same width.
            crSeparator.leadingAnchor.constraint(equalTo: separator.trailingAnchor),
            crSeparator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            crSeparator.heightAnchor.constraint(equalToConstant: 1),
            crSeparator.bottomAnchor.constraint(equalTo: customRoutinesPanel.topAnchor),
            customRoutinesPanel.leadingAnchor.constraint(equalTo: separator.trailingAnchor),
            customRoutinesPanel.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            customRoutinesPanel.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            // Height hugs the content (set in reload) but never exceeds 1/5 of the window.
            customRoutinesPanel.heightAnchor.constraint(lessThanOrEqualTo: root.heightAnchor, multiplier: 0.2),
            crHeight,

            // Date bar near the top, centred over the schedule column. Pinned to the safe-area top;
            // `dateBarTopConstraint.constant` gets extra padding in full screen (set in
            // updateFullScreenInsets) so it clears the menu-bar reveal overlay.
            dateBarTop,
            dateBarCenterX,

            // Add-event button at the right of the schedule column, level with the date bar.
            addEventCenterY,
            addEventButton.trailingAnchor.constraint(equalTo: separator.leadingAnchor, constant: -16),

            // Schedule scroll fills the left column (up to the panel separator).
            // Sticky draft banner sits between the date bar and the scroll view (0pt tall when empty).
            draftBannerContainer.topAnchor.constraint(equalTo: dateBar.bottomAnchor, constant: 6),
            draftBannerContainer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            draftBannerContainer.trailingAnchor.constraint(equalTo: separator.leadingAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: draftBannerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: separator.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor),

            // Pin top/sides + width to the flipped clip; leave the bottom free so the
            // stack grows downward and scrolls vertically.
            stackView.topAnchor.constraint(equalTo: clip.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: clip.widthAnchor),
        ])
        self.view = root
        tasksPanel.date = selectedDate
        fetchProjectsForAutocomplete()
    }

    /// Load the user's backend projects so the `#project` autocomplete can suggest real projects
    /// (e.g. "House") even before any task on the day uses them. With the list in hand, any task whose
    /// project only ever existed on this Mac can be told apart from a real one — so repair those.
    private func fetchProjectsForAutocomplete() {
        DayPlanTaskStore.shared.refreshRemoteProjects { loaded in
            if loaded { DayPlanProjectRepair.shared.runIfDue(trigger: .projectsLoaded) }
        }
    }

    /// Placeholder for now — task→block highlighting comes with drag-and-drop (next stage).
    private func refreshTasksHighlights() { reload() }

    // MARK: - Date navigation

    private func makeDateBar() -> NSView {
        func arrow(_ symbol: String, _ action: Selector) -> NSButton {
            let b = cursorButton(title: "", target: self, action: action)
            b.bezelStyle = .texturedRounded
            b.isBordered = false
            if #available(macOS 11.0, *) { b.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) }
            else { b.title = symbol == "chevron.left" ? "‹" : "›" }
            b.translatesAutoresizingMaskIntoConstraints = false
            return b
        }
        let prev = arrow("chevron.left", #selector(prevDayClicked))
        let next = arrow("chevron.right", #selector(nextDayClicked))

        dateLabelButton.bezelStyle = .rounded
        dateLabelButton.isBordered = false
        dateLabelButton.font = .boldSystemFont(ofSize: 14)
        dateLabelButton.alignment = .center
        dateLabelButton.target = self
        dateLabelButton.action = #selector(pickDateClicked)
        dateLabelButton.translatesAutoresizingMaskIntoConstraints = false
        // Fixed width so the ‹ › arrows never shift as the date string changes length.
        dateLabelButton.widthAnchor.constraint(equalToConstant: 150).isActive = true

        todayButton.isBordered = false
        todayButton.bezelStyle = .inline
        todayButton.controlSize = .small
        todayButton.target = self
        todayButton.action = #selector(goTodayClicked)
        todayButton.attributedTitle = NSAttributedString(string: ScheduleText.backToToday, attributes: [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: NSFont.systemFont(ofSize: 12)
        ])
        todayButton.translatesAutoresizingMaskIntoConstraints = false

        addEventButton.title = ScheduleText.addEvent
        if let plus = NSImage(systemSymbolName: "plus", accessibilityDescription: ScheduleText.addEvent) {
            addEventButton.image = plus
            addEventButton.imagePosition = .imageLeading
        }
        addEventButton.bezelStyle = .rounded
        addEventButton.controlSize = .small
        addEventButton.contentTintColor = .controlAccentColor
        addEventButton.toolTip = ScheduleText.addEvent
        addEventButton.target = self
        addEventButton.action = #selector(addEventClicked)
        addEventButton.translatesAutoresizingMaskIntoConstraints = false

        // "Today" indicator shown UNDER the date when viewing today (so the date string — and thus
        // the arrows — stays a constant width whether or not it's today).
        todayIndicatorLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        todayIndicatorLabel.textColor = .secondaryLabelColor
        todayIndicatorLabel.alignment = .center
        todayIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        // Reserve its line height always (text cleared off-today) so the bar height — and thus the
        // ＋ / Back-to-today buttons pinned to its centre — never shifts between days.
        todayIndicatorLabel.heightAnchor.constraint(equalToConstant: 13).isActive = true

        let row = NSStackView(views: [prev, dateLabelButton, next])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 6
        // Sub-line under the date: shows "TODAY · 10:06 am" when on today, or the centred "Back to
        // today" link otherwise — so the layout matches whichever day you're viewing.
        todayButton.translatesAutoresizingMaskIntoConstraints = false
        let subLine = NSView()
        subLine.translatesAutoresizingMaskIntoConstraints = false
        subLine.addSubview(todayIndicatorLabel)
        subLine.addSubview(todayButton)
        NSLayoutConstraint.activate([
            subLine.heightAnchor.constraint(equalToConstant: 16),
            todayIndicatorLabel.centerXAnchor.constraint(equalTo: subLine.centerXAnchor),
            todayIndicatorLabel.centerYAnchor.constraint(equalTo: subLine.centerYAnchor),
            todayButton.centerXAnchor.constraint(equalTo: subLine.centerXAnchor),
            todayButton.centerYAnchor.constraint(equalTo: subLine.centerYAnchor),
        ])
        let bar = NSStackView(views: [row, subLine])
        bar.orientation = .vertical
        bar.alignment = .centerX
        bar.spacing = 0
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }

    /// Show the [Custom routine | Day Plan] toggle only while a custom routine is active. In
    /// "Custom routine" mode we hide the Day Plan's own content (keeping just the toggle) so the
    /// underlying habit-list view shows through; "Day Plan" shows the full plan.
    private func updateRoutineToggle() {
        let active = (currentState == ._CUSTOM_ROUTINE_)
        routineToggle.isHidden = !active
        // The toggle and the settings cog both live top-left. While the toggle is shown, slide the cog
        // to just right of it so they don't overlap (the cog stays visible on the Day Plan tab; it's
        // hidden with the rest of the Day Plan content on the "Custom routine" tab via
        // setDayPlanContentHidden). Deactivate one leading before activating the other to avoid a clash.
        if active {
            cogLeadingDefault?.isActive = false
            cogLeadingBesideToggle?.isActive = true
        } else {
            cogLeadingBesideToggle?.isActive = false
            cogLeadingDefault?.isActive = true
        }
        if !active {
            routineToggle.selectedSegment = 0
            showDayPlanDuringRoutine = false
            setDayPlanContentHidden(false)   // routine ended — restore the Day Plan
        } else {
            setDayPlanContentHidden(routineToggle.selectedSegment == 0)
        }
    }

    @objc private func routineToggleChanged() {
        let dayPlan = (routineToggle.selectedSegment == 1)
        showDayPlanDuringRoutine = dayPlan
        setDayPlanContentHidden(!dayPlan)
        if dayPlan { lastRenderSignature = nil; reload() }
    }

    /// Hide every Day Plan subview except the toggle (and make the background transparent) so the
    /// old habit-list view underneath shows through — used for the "Custom routine" tab.
    private func setDayPlanContentHidden(_ hidden: Bool) {
        isDayPlanContentHidden = hidden
        for v in view.subviews where v !== routineToggle { v.isHidden = hidden }
        view.layer?.backgroundColor = hidden ? NSColor.clear.cgColor : resolvedCGColor(.textBackgroundColor, in: view)
        // Restoring content un-hides everything, including views with their own visibility rules —
        // re-apply them (e.g. "Back to today" must stay hidden while already on today).
        if !hidden { updateDateBar() }
        // Re-sync ONLY the host's habit-list visibility (lightweight): when our content is hidden
        // (Custom routine tab) the host list must show through; when shown, it stays hidden behind us.
        // Must NOT call updateScheduleTabForState() here — that calls startAutoRefresh()→reload()→
        // reloadLive()→updateRoutineToggle()→setDayPlanContentHidden(), an infinite recursion / crash.
        host?.refreshHabitListVisibilityForDayPlan()
    }

    /// Refresh the date label + today indicator to match `selectedDate`.
    // Cached formatters: creating a DateFormatter (or reassigning its dateFormat) triggers an
    // expensive ICU pattern regeneration. updateDateBar runs on the main thread on every reload/day
    // change, and building fresh formatters each time stalled it long enough to trip Sentry's
    // "App Hanging (>= 2000 ms)" in ScheduleViewController.updateDateBar. Reuse per-format instances.
    private static let dateFormatterThisYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM"; return f
    }()
    private static let dateFormatterOtherYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM yyyy"; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()

    private func updateDateBar() {
        let sameYear = Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .year)
        let f = sameYear ? Self.dateFormatterThisYear : Self.dateFormatterOtherYear
        dateLabelButton.title = f.string(from: selectedDate)   // date only — "Today" goes below
        if isViewingToday {
            todayIndicatorLabel.stringValue = ScheduleText.today.uppercased() + " · " + Self.timeFormatter.string(from: Date())
        } else {
            todayIndicatorLabel.stringValue = ""
        }
        // The indicator and the "Back to today" link share the sub-line slot under the date.
        todayIndicatorLabel.isHidden = !isViewingToday
        todayButton.isHidden = isViewingToday
    }

    private func changeDay(by days: Int) {
        guard let d = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = d
        followingToday = Calendar.current.isDateInToday(d)   // only keep following if they landed on today
        DayPlanAnalytics.capture(DayPlanAnalytics.dayChanged,
                                 ["days": days, "direction": days >= 0 ? "forward" : "back",
                                  "is_today": Calendar.current.isDateInToday(d)])
        selectedHabitIndex = nil
        selectedPastHabitId = nil       // a past selection is date-specific
        lastRenderSignature = nil
        reload()
    }

    /// At midnight (or a timezone/clock change) the Day Plan should roll to the new day on its own,
    /// instead of stranding the user on "yesterday" needing to tap "Back to today". Only auto-advances
    /// when it was FOLLOWING today (the user hadn't navigated to a specific day). Returns true if it
    /// advanced (and reloaded).
    @discardableResult
    private func advanceToTodayIfFollowing() -> Bool {
        guard followingToday, !isViewingToday else { return false }
        selectedDate = Date()
        selectedHabitIndex = nil; selectedPastHabitId = nil; lastRenderSignature = nil
        reload()
        return true
    }

    /// Drop any manual habit pick so the highlight falls back to the current habit. Called when the
    /// Day Plan is (re)shown for a state change — e.g. after starting a habit (which reorders the
    /// in-progress habit to the top) and tapping Back, the old picked index would otherwise highlight
    /// whatever habit now sits at that position instead of the in-progress one.
    func clearSelectedHabit() {
        guard selectedHabitIndex != nil else { return }
        selectedHabitIndex = nil
        lastRenderSignature = nil
    }

    @objc private func prevDayClicked() { changeDay(by: -1) }
    @objc private func nextDayClicked() { changeDay(by: 1) }
    @objc private func goTodayClicked() {
        selectedDate = Date()
        followingToday = true   // back on today → follow the day across midnight again
        // "Back to today" is a day change too (like the prev/next arrows in changeDay) — track it.
        DayPlanAnalytics.capture(DayPlanAnalytics.dayChanged, ["direction": "today", "is_today": true])
        selectedHabitIndex = nil; selectedPastHabitId = nil; lastRenderSignature = nil; reload()
    }

    @objc private func pickDateClicked() {
        // A custom month grid (not NSDatePicker) so each day can carry a free-time colour badge —
        // NSDatePicker's calendar draws its own cells and offers no per-day customisation hook.
        let controller = DayPlanDatePickerController(
            selectedDate: selectedDate,
            freeMinutesProvider: { [weak self] in self?.netFreeMinutes(on: $0) ?? nil },
            onSelect: { [weak self] date in
                self?.datePopover?.close()
                self?.chooseDate(date)
            })
        let pop = NSPopover()
        pop.contentViewController = controller
        pop.behavior = .transient
        pop.show(relativeTo: dateLabelButton.bounds, of: dateLabelButton, preferredEdge: .maxY)
        datePopover = pop
    }

    /// Jump the Day Plan to `date` picked from the calendar grid. Mirrors the prev/next arrows.
    private func chooseDate(_ date: Date) {
        guard !Calendar.current.isDate(date, inSameDayAs: selectedDate) else { return }
        selectedDate = date
        followingToday = Calendar.current.isDateInToday(date)   // only follow midnight if they picked today
        DayPlanAnalytics.capture(DayPlanAnalytics.dayChanged,
                                 ["direction": "picker", "is_today": Calendar.current.isDateInToday(date)])
        selectedHabitIndex = nil
        selectedPastHabitId = nil
        lastRenderSignature = nil
        reload()
    }

    // MARK: - Add calendar event

    @objc private func addEventClicked() {
        requestCalendarThen { [weak self] in
            guard let self = self else { return }
            self.presentEventForm(editingID: nil, relativeTo: self.addEventButton)
        }
    }

    /// Open the edit form for an existing calendar event, anchored to its card.
    func openEventEditor(eventID: String, occurrence: (start: Date, end: Date)? = nil, from view: NSView) {
        DayPlanAnalytics.capture(DayPlanAnalytics.eventSettingsOpened)
        requestCalendarThen { [weak self] in
            self?.presentEventForm(editingID: eventID, occurrence: occurrence, relativeTo: view)
        }
    }

    /// Run `action` once we have calendar access (requesting it first if undetermined).
    private func requestCalendarThen(_ action: @escaping () -> Void) {
        switch CalendarManager.shared.access {
        case .authorized:
            guard CalendarManager.shared.hasAnyCalendars() else { showNoCalendarsInfo(); return }
            action()
        case .notDetermined:
            CalendarManager.shared.requestAccess { [weak self] granted in
                DispatchQueue.main.async {
                    self?.lastRenderSignature = nil
                    self?.reload()                      // refresh banner / meetings now we may have access
                    guard granted else { return }
                    // Access without any calendars can't hold a new event — explain rather than
                    // opening an event form that could never save (issue #2115).
                    guard CalendarManager.shared.hasAnyCalendars() else { self?.showNoCalendarsInfo(); return }
                    action()
                }
            }
        case .denied:
            NSSound.beep()                              // can't write without access; banner explains how to grant
        }
    }

    /// Default start for a new event: the next half-hour when viewing today, else 9am that day.
    private func defaultEventStart() -> Date {
        let cal = Calendar.current
        if isViewingToday {
            let now = Date()
            let minute = cal.component(.minute, from: now)
            let bump = (minute < 30) ? (30 - minute) : (60 - minute)
            let rounded = cal.date(byAdding: .minute, value: bump, to: now) ?? now
            return cal.date(bySetting: .second, value: 0, of: rounded) ?? rounded
        }
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
    }

    /// Shared create/edit event form. `editingID` nil = create; otherwise pre-fills from the event.
    /// `scope` is the already-chosen span for a repeating event. nil on the first call: a repeating
    /// event asks, then re-enters with the answer — so the check below is "have we asked yet", not
    /// "is it repeating", and it cannot ask twice.
    private func presentEventForm(editingID: String?, occurrence: (start: Date, end: Date)? = nil,
                                  relativeTo anchor: NSView, scope: EKSpan? = nil) {
        // A repeating event gets the question every calendar app asks — up front, so the rest of the
        // form is edited knowing what it applies to. Declining leaves the plan untouched.
        if scope == nil, let editID = editingID, CalendarManager.shared.isRecurring(id: editID) {
            askEventEditScope { [weak self] chosen in
                guard let self = self, let chosen = chosen else { return }
                self.presentEventForm(editingID: editingID, occurrence: occurrence,
                                      relativeTo: anchor, scope: chosen)
            }
            return
        }
        editingEventID = editingID
        editingEventScope = scope
        let existing = editingID.flatMap { CalendarManager.shared.event(withID: $0) }
        editingEventIsNotOwned = existing.map { !CalendarManager.shared.isEventOwnedByCurrentUser($0) } ?? false
        editingEventOwnership = existing.map { CalendarManager.shared.ownership(of: $0) } ?? .unknown
        editingEventIsRecurring = existing?.hasRecurrenceRules ?? false
        // For a non-owned event the user may have a prior local-only edit — prefill from it so re-opening
        // shows their tweaks rather than the untouched calendar values.
        let localOverride = editingID.flatMap { CalendarManager.shared.localOverride(forEventID: $0) }
        // The clicked row's own times win: they are this occurrence's, while the event fetched by id
        // carries the series' first occurrence. A stored override only applies to its own occurrence.
        let overrideTimes = occurrence.flatMap { row in
            CalendarManager.overrideTimes(localOverride, onDay: CalendarManager.dayKey(row.start))
        }
        editingEventOccurrence = occurrence
        let start = overrideTimes?.start ?? occurrence?.start ?? localOverride?.start ?? existing?.startDate ?? defaultEventStart()
        let end = overrideTimes?.end ?? occurrence?.end ?? localOverride?.end ?? existing?.endDate ?? start.addingTimeInterval(30 * 60)

        // Title plus the ✕ that dismisses the form. Dismissing used to be a button labelled "Cancel"
        // sitting beside "Save", which reads as "cancel the meeting" — that name now belongs to the
        // destructive action in the footer.
        let header = NSHostingView(rootView: EventFormHeaderView(
            title: editingID == nil ? ScheduleText.addEvent : ScheduleText.editEventTitle,
            closeHint: ScheduleText.eventCloseForm,
            onClose: { [weak self] in self?.cancelEventForm() }))
        header.translatesAutoresizingMaskIntoConstraints = false

        // Warns that edits to an event the user doesn't own can't reach the shared calendar — they're
        // kept locally on the user's own day plan only.
        let ownershipWarningLabel = makeLabel(ScheduleText.eventNotOwnedWarning, size: 12, bold: false)
        ownershipWarningLabel.textColor = .systemOrange
        ownershipWarningLabel.preferredMaxLayoutWidth = 300
        ownershipWarningLabel.lineBreakMode = .byWordWrapping
        ownershipWarningLabel.usesSingleLineMode = false

        let titleField = NSTextField()
        titleField.placeholderString = ScheduleText.eventTitlePlaceholder
        titleField.stringValue = localOverride?.title ?? existing?.title ?? ""
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.widthAnchor.constraint(equalToConstant: 300).isActive = true
        addTitleField = titleField

        let calendarPopup = NSPopUpButton()
        // The event's own calendar is listed even when it's read-only (a subscribed feed, or one shared
        // read-only), so the popup shows where the event really lives instead of falling back to the
        // first calendar in the list and mislabelling it.
        let owningCalendar = existing.flatMap { CalendarManager.shared.calendar(of: $0) }
        let cals = EventCalendarPicker.choices(writable: CalendarManager.shared.writableCalendars(),
                                               owning: owningCalendar)
        addCalendarIDs = cals.map { $0.id }
        for title in EventCalendarPicker.menuTitles(for: cals) { calendarPopup.addItem(withTitle: title) }
        if let idx = EventCalendarPicker.selectedIndex(in: cals, owningID: owningCalendar?.id) {
            calendarPopup.selectItem(at: idx)
            addCalendarIsUserChoice = true
        } else {
            // A new event legitimately starts on the default calendar; for an edit we couldn't resolve,
            // the popup's selection means nothing and must never be written back (see saveEventForm).
            addCalendarIsUserChoice = (editingID == nil)
        }
        // An event in a read-only calendar can't be moved out of it, and an event someone else organises
        // can't be rewritten at all — show the true calendar, but don't offer to change it.
        calendarPopup.isEnabled = (owningCalendar?.isWritable ?? true) && !editingEventIsNotOwned
        calendarPopup.translatesAutoresizingMaskIntoConstraints = false
        addCalendarPopup = calendarPopup

        // Day via a date picker, time via a typed field — see EventDateTimeField for why the time
        // is NOT an NSDatePicker segment (typing "30" for the minutes was near-impossible).
        let startPicker = EventDateTimeField(date: start, target: self, action: #selector(startPickerChanged))
        let endPicker = EventDateTimeField(date: end, target: nil, action: nil)
        addStartPicker = startPicker
        addEndPicker = endPicker

        let recurrencePopup = NSPopUpButton()
        recurrencePopup.addItems(withTitles: [ScheduleText.repeatNone, ScheduleText.repeatDaily,
                                              ScheduleText.repeatWeekly, ScheduleText.repeatMonthly])
        if let ev = existing { recurrencePopup.selectItem(at: CalendarManager.shared.recurrence(of: ev).rawValue) }
        recurrencePopup.translatesAutoresizingMaskIntoConstraints = false
        addRecurrencePopup = recurrencePopup

        // Colour swatches — pre-select the event's saved colour (matched by hex) or the default.
        let savedColor = editingID.flatMap { CalendarManager.shared.color(forEventID: $0) }
        addSelectedColor = Self.eventColorPalette.first { $0.hexString == savedColor?.hexString } ?? Self.eventColorPalette.first
        addColorButtons = []
        let colorStack = NSStackView()
        colorStack.orientation = .horizontal
        colorStack.spacing = 6
        for (i, c) in Self.eventColorPalette.enumerated() {
            let b = makeColorSwatch(c, tag: i)
            addColorButtons.append(b)
            colorStack.addArrangedSubview(b)
        }
        updateColorSelection()

        func row(_ text: String, _ control: NSView) -> NSStackView {
            let label = makeLabel(text, size: 13, bold: false)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.widthAnchor.constraint(equalToConstant: 70).isActive = true
            let s = NSStackView(views: [label, control])
            s.orientation = .horizontal
            s.alignment = .firstBaseline
            s.spacing = 8
            return s
        }

        // Helper to build a bordered, editable multi-line text box. The text view must be sized and
        // made resizable explicitly — a bare NSTextView() has a zero frame and the scroll view won't
        // size its documentView, so the contents (e.g. the event's existing description) show blank.
        func notesBox(_ text: String) -> (NSTextView, NSScrollView) {
            let width: CGFloat = 300, height: CGFloat = 60
            let tv = NSTextView(frame: NSRect(x: 0, y: 0, width: width, height: height))
            tv.minSize = NSSize(width: 0, height: 0)
            tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            tv.isVerticallyResizable = true
            tv.isHorizontallyResizable = false
            tv.autoresizingMask = [.width]
            tv.textContainer?.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            tv.textContainer?.widthTracksTextView = true
            tv.font = .systemFont(ofSize: 13)
            tv.isEditable = true
            tv.isRichText = false
            tv.textContainerInset = NSSize(width: 4, height: 4)
            tv.string = text
            let sc = NSScrollView()
            sc.documentView = tv
            sc.hasVerticalScroller = true
            sc.borderType = .bezelBorder
            sc.translatesAutoresizingMaskIntoConstraints = false
            sc.widthAnchor.constraint(equalToConstant: width).isActive = true
            sc.heightAnchor.constraint(equalToConstant: height).isActive = true
            return (tv, sc)
        }

        // Description — written to the calendar event, so it's shared with the other attendees. (For a
        // non-owned event this can't reach the shared calendar; it's kept in the local override instead.)
        //
        // Google Calendar stores descriptions as HTML, so what's on the event is markup. The field
        // shows it rendered (<br>/<b>/<a> only — see EventDescriptionHTML); the source is kept in
        // `addNotesSourceHTML` so saving an untouched description writes the original back verbatim
        // rather than flattening the other attendees' copy.
        let notesSource = localOverride?.notes ?? existing?.notes ?? ""
        let notesRendered = EventDescriptionHTML.plainText(from: notesSource)
        let (notesView, notesScroll) = notesBox(notesRendered)
        notesView.isRichText = true                     // so the rendered bold/links actually draw
        notesView.isAutomaticLinkDetectionEnabled = false
        notesView.delegate = self                       // gates which links may open
        notesView.textStorage?.setAttributedString(
            EventDescriptionHTML.attributedString(from: notesSource,
                                                  font: .systemFont(ofSize: 13),
                                                  textColor: .textColor))
        addNotesView = notesView
        addNotesSourceHTML = notesSource
        addNotesRenderedText = notesRendered

        // Private notes — stored only in Focus Bear (never written to the calendar), so attendees of a
        // shared event can't see them.
        let (privateView, privateScroll) = notesBox(editingID.flatMap { CalendarManager.shared.privateNote(forEventID: $0) } ?? "")
        addPrivateNotesView = privateView

        let errorLabel = makeLabel("", size: 12, bold: false)
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true
        errorLabel.preferredMaxLayoutWidth = 300
        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.usesSingleLineMode = false
        addErrorLabel = errorLabel

        let saveButton = cursorButton(title: ScheduleText.eventSave, target: self, action: #selector(saveEventForm))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"                 // Return
        // An existing event gets the destructive action on the left of the footer; a brand-new one has
        // nothing to cancel yet, so ✕ (or Esc) is the only way out of it.
        var buttonRowViews: [NSView] = []
        if editingID != nil {
            let destructive = NSHostingView(rootView: EventDestructiveActionView(
                title: EventCancelAction(ownership: editingEventOwnership).buttonTitle,
                action: { [weak self] in self?.cancelOrDeclineEvent() }))
            destructive.translatesAutoresizingMaskIntoConstraints = false
            buttonRowViews.append(destructive)
        }
        buttonRowViews += [NSView(), saveButton]
        let buttonRow = NSStackView(views: buttonRowViews)
        buttonRow.orientation = .horizontal
        buttonRow.spacing = EventFormMetrics.rowSpacing

        // Participants — read-only list of the event's attendees, so you can see who you're meeting
        // with. Only shown when the calendar event actually has attendees (skipped for solo/new
        // events). Prefer the other attendees; fall back to the full list if that leaves it empty.
        var attendeeViews: [NSView] = []
        if let attendees = existing?.attendees, !attendees.isEmpty {
            let others = attendees.filter { !$0.isCurrentUser }
            let people = others.isEmpty ? attendees : others
            // One row per participant so each can show its own RSVP status (accepted / declined /
            // tentative / no response). A single joined label couldn't carry per-person status.
            let rows: [NSView] = people.map { p in makeParticipantRow(p) }
            let peopleStack = NSStackView(views: rows)
            peopleStack.orientation = .vertical
            peopleStack.alignment = .leading
            peopleStack.spacing = 2
            peopleStack.translatesAutoresizingMaskIntoConstraints = false
            attendeeViews = [makeLabel(ScheduleText.eventParticipantsLabel, size: 12, bold: false), peopleStack]
        }

        var formViews: [NSView] = [header]
        if editingEventIsNotOwned { formViews.append(ownershipWarningLabel) }
        formViews += [
            titleField,
            row(ScheduleText.eventCalendarLabel, calendarPopup),
            row(ScheduleText.eventStartsLabel, startPicker),
            row(ScheduleText.eventEndsLabel, endPicker),
            row(ScheduleText.eventRepeatLabel, recurrencePopup),
            row(ScheduleText.eventColorLabel, colorStack),
        ]
        formViews += attendeeViews
        formViews += [
            makeLabel(ScheduleText.eventNotesLabel, size: 12, bold: false),
            notesScroll,
            makeLabel(ScheduleText.eventPrivateNotesLabel, size: 12, bold: false),
            privateScroll,
            errorLabel,
            buttonRow,
        ]
        let form = NSStackView(views: formViews)
        form.orientation = .vertical
        form.alignment = .leading
        form.spacing = 10
        form.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.widthAnchor.constraint(equalTo: titleField.widthAnchor).isActive = true
        header.widthAnchor.constraint(equalTo: titleField.widthAnchor).isActive = true

        let container = NSView()
        container.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            form.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        let vc = NSViewController()
        vc.view = container

        let pop = NSPopover()
        pop.contentViewController = vc
        pop.behavior = .transient
        pop.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        addEventPopover = pop
        vc.view.window?.makeFirstResponder(titleField)
    }

    private func makeColorSwatch(_ color: NSColor, tag: Int) -> NSButton {
        let b = cursorButton(title: "", target: self, action: #selector(colorSwatchClicked(_:)))
        b.tag = tag
        b.isBordered = false
        b.wantsLayer = true
        b.layer?.backgroundColor = color.cgColor
        b.layer?.cornerRadius = 4
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(equalToConstant: 22).isActive = true
        b.heightAnchor.constraint(equalToConstant: 22).isActive = true
        return b
    }

    @objc private func colorSwatchClicked(_ sender: NSButton) {
        guard Self.eventColorPalette.indices.contains(sender.tag) else { return }
        addSelectedColor = Self.eventColorPalette[sender.tag]
        updateColorSelection()
    }

    private func updateColorSelection() {
        for (i, b) in addColorButtons.enumerated() {
            let selected = Self.eventColorPalette[i].hexString == addSelectedColor?.hexString
            b.layer?.borderWidth = selected ? 3 : 0
            b.layer?.borderColor = NSColor.labelColor.cgColor
        }
    }

    @objc private func startPickerChanged() {
        guard let start = addStartPicker?.dateValue, let end = addEndPicker else { return }
        if editingEventID == nil {
            // Creating: changing the start re-anchors the end to 30 minutes later.
            end.dateValue = start.addingTimeInterval(30 * 60)
        } else if end.dateValue <= start {
            // Editing: only nudge the end if the start moved past it.
            end.dateValue = start.addingTimeInterval(30 * 60)
        }
    }

    @objc private func cancelEventForm() {
        addEventPopover?.close()
        addEventPopover = nil
        clearEventFormState()
    }

    /// Forget whatever the editor was editing. Shared by dismissing the form, saving it, and the
    /// destructive Cancel/Decline action, so none of this state can outlive the form it belonged to.
    private func clearEventFormState() {
        editingEventID = nil
        editingEventScope = nil
        editingEventIsNotOwned = false
        editingEventOwnership = .unknown
        editingEventIsRecurring = false
        addCalendarIsUserChoice = false
        addNotesSourceHTML = ""
        addNotesRenderedText = ""
    }

    /// "Only this event" / "All future events" for a repeating event, the way every calendar app
    /// asks (report 2026-09-11_21-00-30). Returns nil when the user cancels, so the form stays open
    /// with their edits intact.
    /// Ask which occurrences a change covers — as a SHEET, and BEFORE the form opens.
    ///
    /// It used to be `NSAlert.runModal()` at save time. Two problems, both reported: asking at save is
    /// too late to be useful ("it should ask when I first click on it not when I save"), and a modal
    /// with no parent window can appear behind the app while still holding keyboard focus — "I can't
    /// see it but it has keyboard focus so I can't interact with anything else"
    /// (report 2026-09-11_21-00-30). A sheet is attached to the window and cannot hide behind it.
    ///
    /// This is the one occurrence-scope question in the editor, and it is asked ONCE per editing
    /// session: opening the form asks it, and cancelling/declining reuses that answer
    /// (`EventCancellationFlow.run(knownScope:)`). It is only asked again when the form was never
    /// opened on a repeating event, in which case `message` names the destructive action instead.
    private func askEventEditScope(message: String = ScheduleText.eventScopeMessage,
                                   completion: @escaping (EKSpan?) -> Void) {
        let alert = NSAlert()
        alert.messageText = ScheduleText.eventScopeTitle
        alert.informativeText = message
        alert.addButton(withTitle: ScheduleText.eventScopeThis)     // .alertFirstButtonReturn
        alert.addButton(withTitle: ScheduleText.eventScopeFuture)   // .alertSecondButtonReturn
        alert.addButton(withTitle: ScheduleText.habitCancel)        // .alertThirdButtonReturn
        alert.presentAsSheet(for: view.window) { response in
            switch response {
            case .alertFirstButtonReturn: completion(.thisEvent)
            case .alertSecondButtonReturn: completion(.futureEvents)
            default: completion(nil)
            }
        }
    }

    @objc private func saveEventForm() {
        guard let startPicker = addStartPicker, let endPicker = addEndPicker else { return }
        let title = (addTitleField?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let start = startPicker.dateValue
        let end = endPicker.dateValue
        let finalTitle = title.isEmpty ? ScheduleText.meetingDefaultTitle : title

        guard end > start else { showAddEventError(); NSSound.beep(); return }
        let idx = addCalendarPopup?.indexOfSelectedItem ?? -1
        // Never write back a selection the user didn't make: when the event's own calendar couldn't be
        // resolved the popup sits on an unrelated calendar, and passing it would MOVE the event there.
        let calendarID = (addCalendarIsUserChoice && addCalendarIDs.indices.contains(idx))
            ? addCalendarIDs[idx] : nil
        let recurrence = CalendarManager.Recurrence(rawValue: addRecurrencePopup?.indexOfSelectedItem ?? 0) ?? .none

        // Rendered for display only: unless the user actually edited the description, the event's
        // original HTML goes back untouched, so moving a meeting never strips the links and
        // formatting the other attendees see.
        let notes = EventDescriptionHTML.notesToSave(edited: addNotesView?.string ?? "",
                                                     rendered: addNotesRenderedText,
                                                     original: addNotesSourceHTML)
        let wasEditing = editingEventID != nil
        // The scope was chosen when the form opened, not here — asking at save is too late to shape
        // what the user is editing (report 2026-09-11_21-00-30, follow-up).
        let span: EKSpan? = editingEventScope
        let eventID: String?
        if let editID = editingEventID {
            if editingEventIsNotOwned {
                // Can't write to a calendar event we don't own — persist the edit locally so it shows on
                // the user's own day plan only, never on the shared calendar the other attendees see.
                // "All future events" on an event we don't own means the time of day, not the date:
                // the override is applied to every occurrence from its start/end clock times.
                let wholeSeries = span == .futureEvents
                CalendarManager.shared.setLocalOverride(
                    CalendarManager.LocalEventOverride(title: finalTitle, start: start, end: end,
                                                       notes: notes.isEmpty ? nil : notes,
                                                       occurrenceDay: CalendarManager.dayKey(editingEventOccurrence?.start ?? start),
                                                       appliesToSeries: wholeSeries ? true : nil),
                    forEventID: editID)
            } else {
                guard CalendarManager.shared.updateEvent(id: editID, title: finalTitle, start: start, end: end,
                                                         calendarID: calendarID, recurrence: recurrence,
                                                         notes: notes, span: span) else {
                    showAddEventError(); NSSound.beep(); return
                }
            }
            eventID = editID
        } else {
            guard let newID = CalendarManager.shared.createEvent(title: finalTitle, start: start, end: end,
                                                                 calendarID: calendarID, recurrence: recurrence, notes: notes) else {
                showAddEventError(); NSSound.beep(); return
            }
            eventID = newID
        }
        if let id = eventID {
            CalendarManager.shared.setColor(addSelectedColor, forEventID: id)
            // Mirror the colour to the backend (global per-event override, syncs across devices).
            if let hex = addSelectedColor?.hexString {
                DayPlanSync.shared.setEventColour(eventID: id, colour: hex)
            } else {
                DayPlanSync.shared.deleteEventColour(eventID: id)
            }
            // Private notes live only in Focus Bear, keyed by the event id — never on the calendar event.
            CalendarManager.shared.setPrivateNote(addPrivateNotesView?.string, forEventID: id)
        }

        addEventPopover?.close()
        addEventPopover = nil
        clearEventFormState()
        // For a brand-new event, jump to its day so the user sees it land. For an edit, stay on the
        // day the user was viewing — a repeating event's `start` is its first instance, so jumping
        // would yank the view back weeks/months (e.g. editing today's task sent the user to May).
        if !wasEditing {
            selectedDate = start
        }
        selectedHabitIndex = nil
        lastRenderSignature = nil
        reload()
    }

    private func showAddEventError() {
        addErrorLabel?.stringValue = ScheduleText.eventSaveError
        addErrorLabel?.isHidden = false
    }

    // MARK: - Cancel / decline the event

    /// The event editor's destructive action: "Cancel Event" when the user organises the event,
    /// "Decline event" when they were invited to it (or when EventKit can't say who owns it — the
    /// non-destructive choice, because cancelling would take the meeting off everyone else's calendar).
    ///
    /// Confirm first, always; then — only if the editor has not already been told — the
    /// this-occurrence-vs-series question; only then does anything get removed. See
    /// EventCancellationFlow, which is unit-tested.
    private func cancelOrDeclineEvent() {
        guard let editID = editingEventID else { return }
        let action = EventCancelAction(ownership: editingEventOwnership)
        let occurrenceStart = editingEventOccurrence?.start
        let isRecurring = editingEventIsRecurring
        // The scope the user picked when the form opened. It has to be read BEFORE the teardown below,
        // which nils it — not reading it here is what made declining a series ask the very same
        // question a second time, after the user had already answered it ("I'd already said at the
        // start that I wanted to edit all future events", report 2026-09-15_20-53-31).
        let chosenScope = editingEventScope
        // Close the popover before the first sheet: a transient popover dismisses itself the moment a
        // sheet takes key focus, which would leave the sheet floating over a half-vanished form.
        addEventPopover?.close()
        addEventPopover = nil
        clearEventFormState()

        removeEvent(eventID: editID, action: action, isRecurring: isRecurring,
                    occurrenceStart: occurrenceStart, knownScope: chosenScope)
    }

    /// Confirm → (for a repeating meeting) which occurrences → remove, for one event. Shared by the
    /// editor's destructive button and the Fix modal's meetings route, so there is one implementation
    /// of taking a meeting off the calendar and one confirmation in front of it.
    ///
    /// - Parameter knownScope: the span the caller has already asked the user for; nil means nobody has
    ///   asked yet and the flow must.
    private func removeEvent(eventID: String, action: EventCancelAction, isRecurring: Bool,
                             occurrenceStart: Date?, knownScope: EKSpan?) {
        EventCancellationFlow.run(
            action: action,
            isRecurring: isRecurring,
            knownScope: knownScope,
            confirm: { [weak self] pending, done in self?.confirmEventRemoval(pending, done) },
            askScope: { [weak self] done in
                self?.askEventEditScope(message: ScheduleText.removeRepeatingInfo, completion: done)
            },
            remove: { span in
                CalendarManager.shared.removeEvent(id: eventID, span: span, occurrenceStart: occurrenceStart)
            },
            completion: { [weak self] outcome in
                guard let self = self else { return }
                switch outcome {
                case .cancelledByUser:
                    break                                   // nothing was touched
                case .failed:
                    self.showEventRemovalError()
                case .removed:
                    DayPlanAnalytics.capture(action == .cancelEvent ? DayPlanAnalytics.eventCancelled
                                                                    : DayPlanAnalytics.eventDeclined)
                    self.selectedHabitIndex = nil
                    self.lastRenderSignature = nil
                    self.reload()
                }
            })
    }

    /// Destructive actions get an explicit confirmation, and it spells out what the removal really does
    /// — including that Focus Bear cannot itself send an RSVP when declining (EventKit exposes no such
    /// API; see EventCancellation.swift).
    private func confirmEventRemoval(_ action: EventCancelAction, _ done: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = action.confirmTitle
        alert.informativeText = action.confirmMessage
        alert.addButton(withTitle: action.buttonTitle)                  // .alertFirstButtonReturn
        alert.addButton(withTitle: ScheduleText.eventCancelEventKeep)
        alert.presentAsSheet(for: view.window) { done($0 == .alertFirstButtonReturn) }
    }

    /// The editor is already closed by the time a removal can fail, so the error can't go in its inline
    /// error label — it gets its own sheet rather than failing silently.
    private func showEventRemovalError() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = ScheduleText.eventRemoveFailedTitle
        alert.informativeText = ScheduleText.eventRemoveFailedMessage
        alert.addButton(withTitle: ScheduleText.eventRemoveFailedOk)
        alert.presentAsSheet(for: view.window) { _ in }
    }

    // MARK: - Lifecycle / refresh

    func startAutoRefresh() {
        // Every time the Day Plan is (re)shown, force a fresh task hydrate — the same thing navigating
        // days does. Without this, re-opening the Day Plan keeps whatever the local store had, missing
        // completions/changes made elsewhere since it was last hydrated this session.
        lastHydratedDay = nil
        reload()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.autoRefreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Roll to the new day if midnight passed (backup for the NSCalendarDayChanged observer);
            // advanceToTodayIfFollowing reloads itself when it advances, so don't reload twice.
            if self.advanceToTodayIfFollowing() { return }
            self.reload()
        }
        if let t = refreshTimer { RunLoop.main.add(t, forMode: .common) }
        // CalendarManager answers the main thread from its cache and reads EventKit in the background,
        // so a reload can render meetings that are one refresh behind (the first ever render, or the
        // tick straight after a calendar edit). This is how the fresh data gets on screen without
        // waiting for the next 30s tick.
        if meetingsChangedObserver == nil {
            meetingsChangedObserver = NotificationCenter.default.addObserver(
                forName: CalendarManager.meetingsDidChange, object: nil, queue: .main) { [weak self] _ in
                guard let self = self, !self.view.isHidden else { return }
                self.reload()
            }
        }
        if forecastSettingsObserver == nil {
            forecastSettingsObserver = NotificationCenter.default.addObserver(
                forName: LocalForecastPreferences.didChange, object: nil, queue: .main) { [weak self] _ in
                    self?.lastRenderSignature = nil
                    self?.reload()
                }
        }
        // Immediate roll-over at midnight (and on timezone/clock changes) so the user isn't left on
        // yesterday until the next 30s tick.
        if dayChangedObserver == nil {
            dayChangedObserver = NotificationCenter.default.addObserver(
                forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
                    self?.advanceToTodayIfFollowing()
                }
        }
        // Re-check Calendar permission when the user returns to the app (e.g. after granting it in
        // System Settings). Force a fresh render so the "Grant access" banner re-evaluates and clears
        // once access is authorized. Only active while the Day Plan is shown.
        if didBecomeActiveObserver == nil {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self = self else { return }
                // macOS returns a stale `.denied` from authorizationStatus to a running process after
                // the user grants Calendar access in System Settings (confirmed via diagnostics). A
                // passive reload would keep reading `.denied`, so when we're in the denied state issue
                // an explicit re-request first (no dialog for an already-decided status) to refresh
                // the in-process status, then reload so the banner clears.
                // Returning to the app should re-fetch task status too (tasks may have been completed on
                // another device while away) — reset the hydrate throttle so the reload re-hydrates.
                self.lastHydratedDay = nil
                if CalendarManager.shared.access == .denied {
                    CalendarManager.shared.revalidateAccess { [weak self] in
                        self?.lastRenderSignature = nil
                        self?.reload()
                    }
                } else {
                    self.lastRenderSignature = nil
                    self.reload()
                }
            }
        }
        // Recompute the tasks-panel top inset the moment the routine player's "Postpone" button
        // (habitsVc.btnAbort) shows or hides, so "Tasks for today" clears it as soon as it becomes
        // available — not only on the next 30s reload.
        if postponeHiddenObservation == nil, habitsVcObj?.isViewLoaded == true, let btn = habitsVcObj?.btnAbort {
            postponeHiddenObservation = btn.observe(\.isHidden, options: [.new]) { [weak self] _, _ in
                DispatchQueue.main.async { self?.updateFullScreenInsets() }
            }
        }
        // Catch up on any render() skipped while this host's view was hidden (see the guard at the
        // top of render(blocks:)) as soon as it becomes visible again.
        if viewHiddenObservation == nil {
            viewHiddenObservation = view.observe(\.isHidden, options: [.old, .new]) { [weak self] _, change in
                guard let self = self, change.oldValue == true, change.newValue == false,
                      self.hasPendingRenderWhileHidden else { return }
                self.hasPendingRenderWhileHidden = false
                self.reload()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        if let observer = forecastSettingsObserver {
            NotificationCenter.default.removeObserver(observer)
            forecastSettingsObserver = nil
        }
        if let obs = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(obs)
            didBecomeActiveObserver = nil
        }
        if let obs = meetingsChangedObserver {
            NotificationCenter.default.removeObserver(obs)
            meetingsChangedObserver = nil
        }
        if let obs = dayChangedObserver {
            NotificationCenter.default.removeObserver(obs)
            dayChangedObserver = nil
        }
        postponeHiddenObservation?.invalidate()
        postponeHiddenObservation = nil
    }

    // MARK: Full-screen top inset
    //
    // In full screen the menu bar is auto-hidden (no safe-area inset), and reveals as an OVERLAY on
    // hover — covering anything sitting at the very top (the date bar and "Tasks for today" header).
    // So we add explicit top padding while full screen, removed otherwise.

    override func viewDidAppear() {
        super.viewDidAppear()
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(fullScreenChanged), name: NSWindow.didEnterFullScreenNotification, object: nil)
        nc.addObserver(self, selector: #selector(fullScreenChanged), name: NSWindow.didExitFullScreenNotification, object: nil)
        updateFullScreenInsets()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        NotificationCenter.default.removeObserver(self, name: NSWindow.didEnterFullScreenNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSWindow.didExitFullScreenNotification, object: nil)
    }


    @objc private func fullScreenChanged(_ note: Notification) {
        guard (note.object as? NSWindow) == view.window else { return }
        updateFullScreenInsets()
    }

    private func updateFullScreenInsets() {
        // Only macOS's real full screen reveals the menu bar as a top overlay that needs clearing.
        // The app's borderless full screen does NOT need content pushed down — the tasks settings cog
        // now lives on the totals row (not the top-right corner) so it no longer collides with the
        // "Exit Fullscreen" button.
        let isFullScreen = view.window?.styleMask.contains(.fullScreen) ?? false
        let menuBarInset: CGFloat = isFullScreen ? ((NSApp.mainMenu?.menuBarHeight ?? 24) + 6) : 0
        // The routine player's abort button (habitsVc.btnAbort — titled "Postpone" while a habit is
        // running) floats over the top of the tasks panel once a habit has been started (e.g. after
        // pausing and tapping Back) and overlaps the "Tasks for today" header. It lives in habitsVc,
        // NOT in the host, so reserve top inset by measuring its actual position over THIS panel and
        // dropping the header just below it. The left date bar isn't under it, so it keeps only the
        // menu-bar inset.
        var overlayInset: CGFloat = 0
        if let win = tasksPanel.window,
           habitsVcObj?.isViewLoaded == true, let btn = habitsVcObj?.btnAbort,
           !btn.isHidden, btn.window === win {
            let panel = tasksPanel.convert(tasksPanel.bounds, to: nil)
            let b = btn.convert(btn.bounds, to: nil)
            let overlapsHorizontally = b.maxX > panel.minX && b.minX < panel.maxX
            let overlapsTopBand = b.maxY > panel.maxY - 70 && b.minY < panel.maxY
            if overlapsHorizontally && overlapsTopBand {
                // The header sits (14 + inset) below the panel's top edge; push it just below the
                // button's bottom (panel.maxY - b.minY is how far the button reaches below the top).
                overlayInset = max(0, (panel.maxY - b.minY) - 14 + 8)   // +8 gap below the button
            }
        }
        dateBarTopConstraint?.constant = 14 + menuBarInset
        tasksPanel.extraTopInset = max(menuBarInset, overlayInset)
    }

    /// Last finalized habit set, so the timer can re-lay-out for the new time without
    /// re-reading the live arrays while a routine refetch is rebuilding them.
    private var lastGoodSegments: [ScheduleRoutineSegment]?

    /// Drop a habit from the cached segment set immediately, so a just-completed/skipped habit
    /// doesn't momentarily reappear while the routine refetch (which transiently repopulates the
    /// live arrays with the full list) runs.
    private func removeHabitFromCache(index: Int) {
        guard let segs = lastGoodSegments else { return }
        lastGoodSegments = segs.map { seg in
            ScheduleRoutineSegment(name: seg.name,
                                   habits: seg.habits.filter { $0.index != index },
                                   windowStart: seg.windowStart, windowEnd: seg.windowEnd,
                                   actionable: seg.actionable)
        }
    }

    /// When the current refetch window started — used to cap how long we trust the flag.
    private var refetchGuardStart: Date?

    /// True while the app is mid-refetch of the routine (current-activity-props): during this
    /// window `arrFilteredMorningHabits` is transiently the *unfiltered* full list, so reading
    /// it would briefly show already-completed habits as undone. Mirrors how the habit table
    /// only reloads at finalized points.
    ///
    /// The trust is time-capped: a refetch flag that gets stuck "true" on some code path must not
    /// freeze the schedule forever on its cached (e.g. already-completed) habit list. After a few
    /// seconds we stop honouring the flag and read the live, completed-filtered arrays again —
    /// the same source the habit list shows.
    private var isRoutineRefetchInProgress: Bool {
        let flag = (appdelegate?.isProcessingHabitRoutine ?? false) || isProcessingCustomRoutine
        guard flag else { refetchGuardStart = nil; return false }
        let start = refetchGuardStart ?? Date()
        refetchGuardStart = start
        return Date().timeIntervalSince(start) < 4.0
    }

    /// The day the schedule is showing (defaults to today). Past/future days are read-only.
    var selectedDate = Date()
    var isViewingToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    /// The day being viewed has already gone by, so there is nothing left to plan for it.
    var isViewingPastDay: Bool {
        Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: Date())
    }
    /// "Shorten for this day" is a planning tool: offered for today and any day still ahead.
    var canShortenHabits: Bool { !isViewingPastDay }
    /// Last day we pulled the backend Day Plan for, so hydration fires once per day shown (not on
    /// every timer-driven reload). Reset when the selected day changes.
    private var lastHydratedDay: Date?
    /// How often TODAY's planned-tasks are re-pulled from the backend. Past/future days are immutable
    /// so they hydrate exactly once; only today re-hydrates on this interval, so a task completed on
    /// another device (mobile/web) shows here without a manual day-navigation — the earlier once-per-day
    /// throttle meant a completion made after the first successful fetch never appeared until you
    /// stepped to another day and back (which resets `lastHydratedDay`). Kept well above the 30s reload
    /// cadence so re-hydrating stays gentle on the backend, and `hydrate()` only re-renders the panel
    /// when the fetched status actually changed, so idle ticks don't flicker or re-order the list.
    private static let todayTaskRehydrateInterval: TimeInterval = 60
    /// How often the Day Plan rebuilds itself while it's on screen.
    private static let autoRefreshInterval: TimeInterval = 30
    /// A reload that takes at least this long gets a per-phase breakdown in the log. Well under
    /// MainThreadWatchdog's 4s stall threshold, so a reload heading towards a beachball is recorded
    /// with its slowest phase named before the watchdog ever fires — and a healthy tick (single-digit
    /// milliseconds) logs nothing.
    private static let slowReloadLogThreshold: TimeInterval = 0.5
    /// When the last successful task hydrate landed, so TODAY can be re-pulled once it goes stale (see
    /// `todayTaskRehydrateInterval`). Only advanced after a real fetch — a skipped/failed fetch leaves it
    /// unchanged so the retry keeps firing (same guarantee as `lastHydratedDay`; does not regress #2145).
    private var lastTaskHydrateAt: Date?
    /// The day whose task hydrate is currently in flight — stops the 30s refresh from firing overlapping
    /// fetches while one is pending (lastHydratedDay is now only stamped once a fetch actually lands).
    private var hydratingDay: Date?
    /// Separate throttle for the #2150 routine-progress fetch: unlike task hydration it also fires for
    /// TODAY once the routine completes (see hydrateTasksIfNeeded), so it can't share lastHydratedDay
    /// (which was already set when the Day Plan was first shown earlier today, before completion).
    private var lastProgressFetchDay: Date?

#if DEBUG
    /// When set, reload() renders this fixed mock data instead of the live routine/calendar state
    /// (used by the offscreen DayPlanMockup renderer, defined at the bottom of this file).
    /// DEBUG-only — the whole mockup harness is compiled out of Release builds.
    var mockConfig: DayPlanMockConfig?

    /// Full pixel height of the day timeline's content (the scroll view's document view), so the
    /// offscreen mockup renderer can size its window tall enough to show the whole day un-clipped.
    /// `scrollView` is private, so this lives on the VC rather than in the DayPlanMockup renderer.
    func mockTimelineContentHeight() -> CGFloat {
        view.layoutSubtreeIfNeeded()
        return scrollView.documentView?.fittingSize.height ?? view.bounds.height
    }
#endif

    /// Rebuild the timetable from the live routine + calendar state.
    func reload() {
#if DEBUG
        if let m = mockConfig {
            bannerDismissed = true   // no calendar-permission banner in a mockup
            let blocks = ScheduleBuilder.build(
                segments: m.segments, meetings: m.meetings, now: m.dayStart, dayEnd: m.dayEnd,
                leaveBufferSeconds: 2 * 60, outOfOrderAllowed: false,
                eveningRoutineStart: m.eveningStart, morningRoutineStart: m.morningStart,
                meetingsFrom: m.dayStart, deepWorkCutoff: m.deepWorkCutoff,
                sprintWorkSeconds: m.sprintWorkSeconds, sprintBreakSeconds: m.sprintBreakSeconds,
                labels: ScheduleText.engineLabels)
            render(blocks: blocks)
            updateDateBar()
            tasksPanel.date = selectedDate   // didSet triggers tasksPanel.reload()
            // NB: do NOT call refreshTasksHighlights() here — it calls reload(), which would recurse.
            return
        }
#endif
        hydrateTasksIfNeeded()
        reloadLive()
    }

    /// Pull the day's backend state once per day shown, then refresh so completions made on other
    /// devices appear: planned to-dos (task panel) and — for a PAST day — the habits actually
    /// completed that day (#2150), which populate the per-day cache the "earlier today" accordion
    /// strikes through. Today's habit completions already come from current-activity-props, so we only
    /// fetch routine-progress for past days. Throttled by `lastHydratedDay`.
    private func hydrateTasksIfNeeded() {
        // Task-panel hydration — once per day shown, but only stamp lastHydratedDay AFTER a real (authed)
        // fetch actually lands. Stamping it optimistically (before the async result) meant a fetch that
        // bailed because the Auth0 token wasn't ready yet at launch marked today "hydrated" for the whole
        // session — so the stale local store kept showing and the 30s refresh never retried (only
        // navigating days reset it). Now the timer retries today until the fetch succeeds, then throttles.
        let day = selectedDate
        let isNewDay = lastHydratedDay == nil || !Calendar.current.isDate(lastHydratedDay!, inSameDayAs: day)
        // Current and future views refresh periodically so due-date edits and completions made
        // elsewhere surface without navigating away. Past views retain their historical hydration.
        let todayIsStale = day >= Calendar.current.startOfDay(for: Date())
            && (lastTaskHydrateAt.map { Date().timeIntervalSince($0) >= Self.todayTaskRehydrateInterval } ?? true)
        let needsHydrate = isNewDay || todayIsStale
        let inFlight = hydratingDay.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false
        if needsHydrate && !inFlight {
            hydratingDay = day
            DayPlanTaskStore.shared.loadAndHydrate(for: day, onChange: { [weak self] in
                self?.tasksPanel.reload()
            }, onComplete: { [weak self] fetched in
                guard let self = self else { return }
                self.hydratingDay = nil
                if fetched { self.lastHydratedDay = day; self.lastTaskHydrateAt = Date() }
            })
            // Reconcile by due date, with overdue work assigned only to the real current day.
            if day >= Calendar.current.startOfDay(for: Date()) {
                DayPlanTaskStore.shared.loadAndMergeDueTodos(for: day, onChange: { [weak self] in
                    self?.tasksPanel.reload()
                })
            }
        }

        // Routine-progress (#2150) → per-day completed-habit cache (strike-through). Fetch for PAST
        // days always; for TODAY whenever we're between routines (._NOTHING_ — not in progress /
        // postponed). This covers BOTH the completed morning (daytime) AND the completed evening (which
        // runs during the shutoff window). We deliberately do NOT gate on isHabitAlreadyShowed: after
        // the evening routine that flag is FALSE (it ends into the shutoff flow — confirmed via
        // diagnostics), which would block the fetch. A genuine not-started ._NOTHING_ just fetches an
        // empty result (harmless no-op).
        //
        // Reset the throttle whenever a routine is active/postponed, so each time we settle back into
        // ._NOTHING_ (a routine just finished — morning OR evening) we fetch fresh progress once, rather
        // than being blocked by an earlier same-day fetch.
        if isViewingToday && currentState != ._NOTHING_ { lastProgressFetchDay = nil }
        let todayRoutineComplete = isViewingToday && currentState == ._NOTHING_
        let shouldFetchProgress = !isViewingToday || todayRoutineComplete
        let alreadyFetched = lastProgressFetchDay.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } ?? false
        guard shouldFetchProgress, !alreadyFetched else { return }
        lastProgressFetchDay = selectedDate
        let dayKey = getStringFromDate(date: selectedDate, dateFormat: "yyyy-MM-dd")
        allApiObject.fetchDayRoutineProgress(dayKey: dayKey) { completedIds in
            guard let completedIds = completedIds, !completedIds.isEmpty else { return }
            // Backend is the source of truth for the day; union with any local backdated completions
            // not yet synced. The didSet re-renders the Day Plan.
            dayPlanCompletedHabitIdsByDay[dayKey, default: []].formUnion(completedIds)
        }
    }

    /// Rebuild the timetable from the live routine + calendar state.
    private func reloadLive() {
        addLog(text: "reloadLive: enter host=\(host != nil ? String(describing: type(of: host!)) : "NIL")")   // freeze-diag: pairs with the "dayplan reload:" log near the end to bracket the render
        // NOTE: we deliberately do NOT auto-request calendar access here. Firing the system TCC
        // prompt the first time the Day Plan renders surprises a brand-new user with a permission
        // dialog they never asked for. Instead, the "Connect your calendar" banner (with its
        // "Grant access" button) shows whenever access isn't authorized, so the request is always
        // gated behind an explicit user tap (grantCalendarClicked / requestCalendarThen).
        var timing = DayPlanReloadTiming()
        var phaseStart = Date()
        /// Closes off the phase that just ran and starts the next one's clock.
        func endPhase(_ record: (TimeInterval) -> Void) {
            let finished = Date()
            record(finished.timeIntervalSince(phaseStart))
            phaseStart = finished
        }

        let isToday = isViewingToday
        // Today anchors to the current moment; other days anchor to that day's morning routine
        // start so the whole day's plan lays out from the top.
        let now: Date = isToday ? Date()
            : (ScheduleTab.timeOnDate(startTime, date: selectedDate) ?? Calendar.current.startOfDay(for: selectedDate))

        var segments: [ScheduleRoutineSegment]
        if !isToday {
            // Read-only preview for another day: habits by that weekday + custom routines.
            segments = ScheduleTab.segmentsForDate(selectedDate)
        } else if currentState == ._CUSTOM_ROUTINE_ && showDayPlanDuringRoutine {
            // A custom routine is active but the user toggled to view the full Day Plan instead of
            // just the active routine's habits.
            segments = ScheduleTab.segmentsForDate(selectedDate)
        } else if isRoutineRefetchInProgress, let cached = lastGoodSegments,
                  cached.contains(where: { $0.actionable && !$0.habits.isEmpty }) {
            // While the routine is being refetched, keep the last finalized habit set so completed
            // habits don't momentarily reappear — but only when that cache actually has the active
            // routine's habits. On the first morning load the active list is still empty (the live
            // arrFilteredMorningHabits is populated asynchronously *during* this refetch window), so
            // fall through to the fresh data instead; otherwise the morning list wouldn't appear
            // until the refetch ends / the 30s auto-refresh fires.
            segments = cached
        } else {
            let fresh = host?.scheduleSegments(now: now) ?? []
            if !fresh.isEmpty { lastGoodSegments = fresh }
            segments = fresh.isEmpty ? (lastGoodSegments ?? []) : fresh
        }
        endPhase { timing.segments = $0 }
        // The day always runs through to 23:59 of the day being viewed.
        let cal = Calendar.current
        let dayEnd = cal.date(bySettingHour: 23, minute: 59, second: 0, of: selectedDate) ?? scheduleDayEnd(now: now)
        let meetings = CalendarManager.shared.meetings(for: selectedDate, includeDismissed: showDismissedEvents)   // [] when no calendar access
        endPhase { timing.meetings = $0 }

        // "Show events from earlier today" only makes sense on today, and only when there actually
        // are meetings that already finished. Other days already show their whole timetable.
        let earlierEvents = isToday ? meetings.filter { $0.end <= Date() } : []

        // #2010: a *past* morning routine (we're now in the evening routine) is also "earlier today".
        // Surface it under the same toggle as a collapsed accordion so completed morning habits are
        // visible — and (once wired) markable — instead of vanishing once the morning is done. Only when
        // the active list on screen isn't already the morning routine (avoid duplicating it).
        let morningStart = ScheduleTab.timeOnDate(startTime, date: selectedDate)
        let pastMorningHabits: [ScheduleHabitInput] = {
            guard isToday,
                  !segments.contains(where: { $0.name == ScheduleText.morningRoutineHabits }) else { return [] }
            // dropCompleted:false so already-done morning habits still render (struck through — the
            // isDone flag flows through to makeHabitRow).
            return ScheduleTab.habitInputs(
                from: ScheduleTab.filterByWeekday(arrAllDaysMorningHabits, weekday: selectedDate.dayOfWeek()),
                now: morningStart ?? now, dropCompleted: false)
        }()

        canShowEarlierToggle = !earlierEvents.isEmpty || !pastMorningHabits.isEmpty
        if !canShowEarlierToggle { showEarlierEvents = false }
        let meetingsFrom = (isToday && showEarlierEvents) ? cal.startOfDay(for: selectedDate) : now

        earlierRoutineNames = []
        if showEarlierEvents, !pastMorningHabits.isEmpty, let ms = morningStart {
            let morningSeg = ScheduleRoutineSegment(
                name: ScheduleText.morningRoutineHabits, habits: pastMorningHabits,
                windowStart: ms, windowEnd: ScheduleTab.timeOnDate(shutOffTime, date: selectedDate) ?? ms,
                actionable: false, isEarlier: true)
            segments = [morningSeg] + segments
            // Show it collapsed by default — it's an "earlier today" item, not the active routine.
            earlierRoutineNames.insert(ScheduleText.morningRoutineHabits)
        }

        // Break duration can be 0 (no enforced screen-break time) — but for the Day Plan we still
        // want deep-work blocks split at the break *frequency*, so fall back to 5 min so the split
        // renders. The split cadence (breakAfterMinutes) is what's meaningful here.
        let storedBreakDur = (UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes) as? Int) ?? 5
        let dwBreakMinutes = storedBreakDur > 0 ? storedBreakDur : 5

        let blocks = ScheduleBuilder.build(
            segments: segments,
            meetings: meetings,
            now: now,
            dayEnd: dayEnd,
            leaveBufferSeconds: 2 * 60,
            outOfOrderAllowed: SettingsManagerObject.isOutOfOrderHabitsAllowed,
            eveningRoutineStart: shutOffToday(now: now),
            morningRoutineStart: morningRoutineStart(now: now),
            meetingsFrom: meetingsFrom,
            deepWorkCutoff: ScheduleTab.timeOnDate(cutOffTime, date: selectedDate),
            sprintWorkSeconds: breakAfterMinutes * 60,
            sprintBreakSeconds: dwBreakMinutes * 60,
            labels: ScheduleText.engineLabels)
        endPhase { timing.build = $0 }

        // Diagnostic for the reported blank Day Plan: capture the state that produced this render so a
        // reproduction pinpoints an empty/hidden plan (host nil → no segments, wrong state, etc.).
        // `dwMins` vs the panel's free figure is the check for "it says I have time but the plan has
        // no deep work in it" (report 2026-09-14_09-09-13): the two are built from the same blocks and
        // should agree, so a gap between them in a log is the bug, not the user's reading of it.
        let deepWorkMinutes = Int(blocks.filter { $0.kind == .deepWork }
            .reduce(0) { $0 + $1.end.timeIntervalSince($1.start) } / 60)
        addLog(text: "dayplan reload: state=\(currentState) host=\(host != nil ? String(describing: type(of: host!)) : "NIL") isToday=\(isToday) segs=\(segments.count) blocks=\(blocks.count) dwMins=\(deepWorkMinutes) viewHidden=\(view.isHidden) contentHidden=\(isDayPlanContentHidden)")
        render(blocks: blocks)
        endPhase { timing.render = $0 }
        updateDateBar()
        updateFullScreenInsets()   // self-correct if full-screen state changed
        updateRoutineToggle()
        customRoutinesPanel.reload()
        crHeightConstraint?.constant = customRoutinesPanel.preferredHeight
        // Keep the tasks panel on the viewed day (only rebuild when the day actually changes).
        if !Calendar.current.isDate(tasksPanel.date, inSameDayAs: selectedDate) {
            tasksPanel.date = selectedDate
        }
        // The plan just rebuilt from the live calendars — tell the portfolio what they occupy (#2418).
        BusyHoursReporter.shared.report(trigger: .dayPlanBuilt)
        // A project a task only has locally (pre-#2392, or a push that failed offline) gets another
        // chance to reach the backend each build — throttled inside, so this is cheap to call here.
        DayPlanProjectRepair.shared.runIfDue(trigger: .dayPlanBuild)
        endPhase { timing.finish = $0 }
        // Freeze-diag: MainThreadWatchdog says the main thread stopped, this says which part of the
        // reload was holding it. Only logged when the reload was actually slow, so a healthy tick
        // stays quiet.
        if timing.isSlow(threshold: Self.slowReloadLogThreshold) {
            addLog(text: "dayplan reload SLOW: \(timing.summary)")
        }
    }

    // MARK: - Data gathering

    /// End of the scheduling window: the user's shutdown time today, or +8h as a fallback.
    private func scheduleDayEnd(now: Date) -> Date {
        if let t = shutOffToday(now: now), t > now { return t }
        return now.addingTimeInterval(8 * 3600)
    }

    private func shutOffToday(now: Date) -> Date? {
        guard let s = shutOffTime else { return nil }
        return Calendar.current.date(bySettingHour: s.hour, minute: s.minute, second: s.second, of: now)
    }

    /// Start of the next morning routine (today if still ahead, else tomorrow) — for the
    /// sleep → morning hand-off at the bottom of the day.
    private func morningRoutineStart(now: Date) -> Date? {
        guard let s = startTime else { return nil }
        var t = Calendar.current.date(bySettingHour: s.hour, minute: s.minute, second: s.second, of: now) ?? now
        if t <= now { t = Calendar.current.date(byAdding: .day, value: 1, to: t) ?? t }
        return t
    }

    // MARK: - Rendering

    /// Signature of what's currently rendered, so back-to-back refreshes (timer tick + an
    /// explicit refresh firing together) don't needlessly rebuild the stack and reset scroll.
    private var lastRenderSignature: String?

    /// Signature of the day's task state (id + assignment + done + title) as of the last render, so a
    /// task-done event — including one hydrated from another device — reloads the right-hand tasks
    /// panel in lockstep with the nested rows (which rebuild from the same `taskSig` below). Without
    /// this the panel only reloaded on `loadAndHydrate`'s one-shot `onChange`; if that single reload
    /// was missed, a task completed elsewhere kept showing in the panel until a day-navigation, even
    /// though its nested row (keyed on `taskSig`) had already struck through. Tracked separately from
    /// `lastRenderSignature` so a forced rebuild with unchanged tasks doesn't needlessly reload.
    private var lastTaskSig: String?

    /// Unscheduled (free) time left in the productive day. Deep-work blocks are NOT busy — they're the
    /// open, task-able time the engine fills with "deep work" sprints (drop tasks into them), so they
    /// count as FREE. Only meetings, breaks and habits are genuinely busy.
    ///
    /// The window is clipped to `[from, until]`: `from` is NOW for today (so already-elapsed free time
    /// this morning isn't offered as still-available), and `until` is the evening-routine start (the end
    /// of the productive day — time after you've wound down doesn't count). Without these clamps a day
    /// with a big morning gap reported it all as "free" hours into the afternoon.
    private func freeTimeSeconds(in blocks: [ScheduleBlock], from: Date?, until: Date?) -> Int {
        let busyKinds: Set<ScheduleBlockKind> = [.meeting, .breakSprint, .habit]
        let intervals = blocks.filter { busyKinds.contains($0.kind) && $0.end > $0.start }
        guard let firstBusy = intervals.map({ $0.start }).min(),
              let lastBusy = intervals.map({ $0.end }).max() else { return 0 }
        let windowStart = max(firstBusy, from ?? firstBusy)
        let windowEnd = min(lastBusy, until ?? lastBusy)
        guard windowEnd > windowStart else { return 0 }
        let busy = Self.busySeconds(in: blocks, windowStart: windowStart, windowEnd: windowEnd)
        return max(0, Int(windowEnd.timeIntervalSince(windowStart)) - busy)
    }

    /// Total busy seconds (meetings, breaks and habits — deep-work is FREE, task-able time) inside
    /// `[windowStart, windowEnd]`, with overlapping busy blocks merged so nothing is double-counted.
    /// Used by `scheduleFreeMinutes(on:)` (fixed productive-day window) for smart snooze.
    private static func busySeconds(in blocks: [ScheduleBlock], windowStart: Date, windowEnd: Date) -> Int {
        guard windowEnd > windowStart else { return 0 }
        let busyKinds: Set<ScheduleBlockKind> = [.meeting, .breakSprint, .habit]
        var merged: [(Date, Date)] = []
        for iv in blocks.filter({ busyKinds.contains($0.kind) && $0.end > $0.start })
            .map({ (max($0.start, windowStart), min($0.end, windowEnd)) })   // clip to the window
            .filter({ $0.1 > $0.0 })
            .sorted(by: { $0.0 < $1.0 }) {
            if let m = merged.last, iv.0 <= m.1 {
                merged[merged.count - 1].1 = max(m.1, iv.1)
            } else {
                merged.append(iv)
            }
        }
        return merged.reduce(0) { $0 + Int($1.1.timeIntervalSince($1.0)) }
    }

    /// Where a forecast snapshot of `date` starts, and whether completed habits belong in it.
    ///
    /// Today has to be built from the CURRENT time, exactly like the rendered Day Plan: a habit that
    /// hasn't run yet is re-placed into the time that is *left*, so it occupies the afternoon rather
    /// than the morning slot it was scheduled in. Building today from midnight left those habits in
    /// the past, where `availableFrom` clips them away, and the budget then counted gaps the plan had
    /// already spent on the routine — "45m available" on a day with no deep-work block in it at all
    /// (report 2026-09-14_09-09-13). Completed habits drop out with them: re-placing a habit that has
    /// already run would book its time twice. Other days keep the whole timetable from midnight.
    static func forecastBuildPoint(for date: Date, now: Date = Date(),
                                   calendar: Calendar = .current) -> (start: Date, includeCompleted: Bool) {
        calendar.isDate(date, inSameDayAs: now) ? (now, false) : (calendar.startOfDay(for: date), true)
    }

    /// Full-day, read-only Day Plan snapshot used by capacity and smart date suggestions.
    /// Hidden meetings follow the forecast reader.
    static func localForecastBlocks(on date: Date) -> [ScheduleBlock] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let point = forecastBuildPoint(for: date, calendar: calendar)
        return ScheduleBuilder.build(segments: ScheduleTab.segmentsForDate(date, includeCompleted: point.includeCompleted),
            meetings: CalendarManager.shared.meetings(for: date, includeDismissed: false),
            now: point.start, dayEnd: end, leaveBufferSeconds: 120,
            outOfOrderAllowed: SettingsManagerObject.isOutOfOrderHabitsAllowed,
            meetingsFrom: start, labels: ScheduleText.engineLabels)
    }

    static func scheduleFreeMinutes(on date: Date) -> Int {
        Int(localForecast(on: date).days.first?.capacity.availableWorkMinutes ?? 0)
    }

    private static func localForecast(on date: Date) -> LocalTimeForecast.Result {
        let settings = LocalForecastPreferences.load(account: appdelegate?.user?.userId ?? "")
        let day = LocalTimeForecast.DayInput.fromDayPlan(date: date, blocks: localForecastBlocks(on: date),
                                                       settings: settings, availableFrom: Date())
        let tasks = DayPlanTaskStore.shared.tasks(for: date).map { task in
            LocalTimeForecast.TaskInput(id: task.id, estimatedMinutes: Double(task.durationMinutes), outcome: task.outcome ?? 2,
                blockAssignment: DayPlanBlockKey.absorbs(task.blockKey)
                    ? task.blockKey.map { .init(date: date, blockKey: $0) } : nil,
                completed: task.done)
        }
        return LocalTimeForecast.calculate(days: [day], projects: [], tasks: tasks, calendar: Calendar.current)
    }

    /// Build the day's schedule blocks for an arbitrary date, headless (no rendering) — used to
    /// measure free time for the date-picker calendar badges. Mirrors the core `ScheduleBuilder.build`
    /// call in `reload()` (minus its on-screen-only concerns like the "earlier today" toggle). For
    /// today it uses the live/actionable segments so its free figure matches the tasks-panel header.
    private func scheduleBlocks(for date: Date) -> [ScheduleBlock] {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        let now = isToday ? Date() : cal.startOfDay(for: date)
        let segments = isToday
            ? (host?.scheduleSegments(now: now) ?? ScheduleTab.segmentsForDate(date))
            : ScheduleTab.segmentsForDate(date)
        let dayEnd = cal.date(bySettingHour: 23, minute: 59, second: 0, of: date) ?? date
        let meetings = CalendarManager.shared.meetings(for: date, includeDismissed: false)
        let storedBreakDur = (UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes) as? Int) ?? 5
        let dwBreakMinutes = storedBreakDur > 0 ? storedBreakDur : 5
        return ScheduleBuilder.build(
            segments: segments,
            meetings: meetings,
            now: now,
            dayEnd: dayEnd,
            leaveBufferSeconds: 2 * 60,
            outOfOrderAllowed: SettingsManagerObject.isOutOfOrderHabitsAllowed,
            eveningRoutineStart: ScheduleTab.timeOnDate(shutOffTime, date: date),
            morningRoutineStart: ScheduleTab.timeOnDate(startTime, date: date),
            meetingsFrom: now,
            deepWorkCutoff: ScheduleTab.timeOnDate(cutOffTime, date: date),
            sprintWorkSeconds: breakAfterMinutes * 60,
            sprintBreakSeconds: dwBreakMinutes * 60,
            labels: ScheduleText.engineLabels)
    }

    /// The same remaining-day capacity and task absorption as the header. Net out all unfinished
    /// task work, including work that does not fit, so an overcommitted date remains negative.
    func netFreeMinutes(on date: Date) -> Int? {
        let forecast = Self.localForecast(on: date)
        guard let day = forecast.days.first else { return nil }
        let remaining = forecast.tasks.filter { !$0.task.completed }.reduce(0) { $0 + ($1.task.estimatedMinutes ?? 0) }
        return Int(day.capacity.availableWorkMinutes - max(0, remaining - day.absorbedBlockMinutes))
    }

    /// Run `body` with this view's appearance current, so any `NSColor.cgColor` resolved inside
    /// tracks the window's (app-theme) Light/Dark setting. Without this, cgColors resolve against
    /// NSApp's system-following appearance, which mismatches when the user's in-app theme differs
    /// from the system one — producing white cards in Dark mode (and dark ones in Light mode).
    func withViewAppearance(_ body: () -> Void) {
        let appearance = (isViewLoaded ? view.effectiveAppearance : nil) ?? NSApp.effectiveAppearance
        if #available(macOS 11.0, *) {
            appearance.performAsCurrentDrawingAppearance { body() }
        } else {
            let saved = NSAppearance.current
            NSAppearance.current = appearance
            body()
            NSAppearance.current = saved
        }
    }

    /// `color.cgColor` resolved against `view`'s effectiveAppearance (the window / app-theme
    /// appearance), so layer backgrounds track the in-app Light/Dark setting rather than NSApp's
    /// system-following one.
    func resolvedCGColor(_ color: NSColor, in view: NSView) -> CGColor {
        var cg = color.cgColor
        if #available(macOS 11.0, *) {
            view.effectiveAppearance.performAsCurrentDrawingAppearance { cg = color.cgColor }
        } else {
            let saved = NSAppearance.current
            NSAppearance.current = view.effectiveAppearance
            cg = color.cgColor
            NSAppearance.current = saved
        }
        return cg
    }

    private func render(blocks: [ScheduleBlock]) {
        // Rebuilding the block stack view is expensive (up to ~90 cards worth of fresh NSViews), and
        // per the #2078/#2075 investigation each full rebuild is also a chance to hit a rare AppKit/
        // dyld lock-contention hang — reducing rebuild frequency is the only lever we have on that.
        // Skip it entirely while this host's Day Plan isn't actually on screen — either its own view is
        // hidden (behind a micro break, or a non-fronted habitsStateVc host — a routinePostponedInfoVc
        // render can happen while a hidden habitsStateVc host is ALSO mid-render behind it), or the view
        // isn't attached to any window at all (diagnostics showed ~half of all rebuilds ran for a host
        // with no window). Catch up the moment it becomes visible again: viewHiddenObservation (in
        // startAutoRefresh()) covers un-hide, and AppearanceReactiveView.onDidMoveToWindow covers
        // window re-attachment.
        guard !view.isHidden else {
            hasPendingRenderWhileHidden = true
            return
        }
        guard view.window != nil else {
            hasPendingRenderWhileHidden = true
            return
        }
        withViewAppearance { renderImpl(blocks: blocks) }
    }

    private func renderImpl(blocks: [ScheduleBlock]) {
        let bannerOn = CalendarManager.shared.shouldShowPermissionBanner() && !bannerDismissed
        // Include nested-task state so dropping / completing / un-nesting a task forces a rebuild.
        let taskSig = DayPlanTaskStore.shared.tasks(for: selectedDate)
            .map { "\($0.id)\($0.blockKey ?? "")\($0.done)\($0.title)\($0.durationMinutes)\($0.outcome ?? 0)" }.joined()
        // The cards bake cgColors for the current Light/Dark appearance, and AppKit doesn't
        // re-resolve them on a live switch. Include the effective (window/app-theme) appearance in
        // the cache key so an appearance flip forces a rebuild instead of being skipped here —
        // otherwise the selected habit unit (Play/Done/Skip) keeps its old colors and goes invisible.
        let appearanceName = ((isViewLoaded ? view.effectiveAppearance : nil) ?? NSApp.effectiveAppearance).name.rawValue
        let collapseSig = routineCollapseOverrides.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        let dwCollapseSig = deepWorkCollapseOverrides.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        // #2010: a cancelled routine swaps its section for an uncancel message — include it so toggling
        // cancel/uncancel forces a re-render instead of being cached away.
        let cancelledSig = host?.cancelledRoutine()?.sectionName ?? ""
        // Completion state for the viewed day — WITHOUT this, marking a (past) habit done doesn't change
        // the signature, so reload() early-returns and the strike-through never appears. Counts suffice
        // since completion is append-only per day.
        let dayKey = getStringFromDate(date: selectedDate, dateFormat: "yyyy-MM-dd")
        let completedSig = "\(dayPlanCompletedHabitIds.count)-\(dayPlanCompletedHabitIdsByDay[dayKey]?.count ?? 0)"
        // Deep-work/free-time blocks are recomputed relative to `now` on every reload() (habits/deep
        // work "pack from now" — see ScheduleBuilder), so an in-progress block's start time drifts by
        // however long it's been since the last reload, every single tick. timeString() below only
        // ever displays HH:MM, never seconds, so that drift is never actually visible — but keying the
        // cache on raw seconds made the signature change on essentially every 30s auto-refresh tick
        // regardless, defeating the cache and forcing a full rebuild of the whole (~90-card) stack view
        // continuously all day (root cause of the hangs tracked in #2075: that rebuild rate gave a rare
        // AppKit/dyld lock-contention hang far more chances to fire than it should have needed).
        // Round to the minute — matching what's actually shown — so a reload that only advanced the
        // clock without changing anything visible correctly no-ops instead of rebuilding.
        func minuteEpoch(_ date: Date) -> Int { Int(date.timeIntervalSince1970 / 60) }
        let signature = "\(appearanceName)|\(bannerOn)|\(DayPlanRoutineDraft.shared.hasChanges)|\(Int(selectedDate.timeIntervalSince1970/86400))|\(selectedHabitIndex.map(String.init) ?? "-")|\(selectedPastHabitId ?? "-")|\(selectedEditableHabitId ?? "-")|\(completedSig)|\(canShowEarlierToggle)\(showEarlierEvents)|\(hideDeepWorkBlocks)|\(hideHabitBlocks)|\(collapseSig)|\(dwCollapseSig)|\(cancelledSig)|\(shouldShowEveningShutdownPrompt())|\(taskSig)|"
            + blocks.map { "\($0.kind)\($0.title)\(minuteEpoch($0.start))\(minuteEpoch($0.end))\($0.isCurrent)\($0.isActionable)" }.joined(separator: ";")
        if signature == lastRenderSignature, !stackView.arrangedSubviews.isEmpty { return }
        lastRenderSignature = signature

        // A task-done event reloads the panel on the SAME signal that rebuilds the nested rows below,
        // so the two can't diverge (nested struck / panel still showing). Only when the task state
        // actually changed — not on every clock-tick rebuild — so panel scroll/edit isn't disturbed
        // needlessly. Local task edits already reload the panel directly; this additionally covers the
        // cross-device path (hydrate flips `done`, `taskSig` changes) that the one-shot onChange missed.
        if taskSig != lastTaskSig {
            lastTaskSig = taskSig
            tasksPanel.reload()
        }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if CalendarManager.shared.shouldShowPermissionBanner() && !bannerDismissed {
            addCard(makeCalendarBanner())
        }
        updateDraftBanner()

        // The "show events from earlier today" option now lives in the schedule settings cog popover.
        // Keep it hidden during a custom routine — the [Custom routine | Day Plan] toggle sits in the
        // same top-left corner and the cog would overlap it.
        scheduleCog.isHidden = (currentState == ._CUSTOM_ROUTINE_)

        // The same remaining-day capacity/absorption formula used by Time Forecast. In particular,
        // dragging a 17-minute task onto a 10-minute habit — or onto a 10-minute calendar event —
        // adds only seven minutes of task work. The day already pays for both kinds of block.
        let capacity = Self.localForecast(on: selectedDate).days.first
        tasksPanel.scheduleFreeMinutes = Int(capacity?.capacity.availableWorkMinutes ?? 0)
        addLog(text: "dayplan capacity: free=\(Int(capacity?.capacity.availableWorkMinutes ?? 0))m absorbed=\(Int(capacity?.absorbedBlockMinutes ?? 0))m")
        tasksPanel.forecastAbsorbedMinutes = capacity?.absorbedBlockMinutes ?? 0


        if blocks.isEmpty {
            let empty = makeLabel(isViewingToday ? ScheduleText.noHabitsLeft : ScheduleText.nothingScheduled, size: 14, bold: false)
            empty.textColor = .secondaryLabelColor
            stackView.addArrangedSubview(empty)
            stackView.addArrangedSubview(makeViewTomorrowButton())
            return
        }


        // Consecutive habits of the same routine collapse into one grouped block; a routine
        // boundary (or any non-habit block) starts a new card.
        // Deep-work tasks are keyed by the sprint's start time, but sprints shift as the day moves,
        // so map each task to the nearest current deep-work sprint (by its ordinal) up front.
        let dwBlocks = blocks.filter { $0.kind == .deepWork }
        let dwTasksByOrdinal = deepWorkTasksByOrdinal(dwBlocks)

        // Let the panel's time-boxed badge name the block each task is pinned to.
        tasksPanel.timeBoxedBlockTitles = timeBoxedTitles(in: blocks, dwBlocks: dwBlocks,
                                                          dwTasksByOrdinal: dwTasksByOrdinal)

        var i = 0
        var dwOrdinal = 0
        var dwRunIndex = 0
        while i < blocks.count {
            if blocks[i].kind == .habit {
                let name = blocks[i].routineName
                // Split on didOverflow too: the "not enough time today" habits form their OWN collapsed
                // card, so they never sit at the top of the group that DID have time for its habits.
                let overflowFlag = blocks[i].didOverflow
                var group = [ScheduleBlock]()
                while i < blocks.count, blocks[i].kind == .habit, blocks[i].routineName == name,
                      blocks[i].didOverflow == overflowFlag {
                    group.append(blocks[i]); i += 1
                }
                // Hide-habits setting: drop the whole routine group so the plan shows just calendar
                // events. The group is still consumed above so `i` has advanced past it.
                if hideHabitBlocks { continue }
                // Each habit inside the group is its own drop target (handled in makeHabitGroupCard).
                addCard(makeHabitGroupCard(group))
            } else if !hideDeepWorkBlocks, blocks[i].kind == .deepWork {
                // A consecutive run of deep-work + break blocks collapses into one accordion row
                // ("Deep work · 9:03am–12pm"); expanding shows the individual sprints and breaks.
                var run = [ScheduleBlock]()
                while i < blocks.count, blocks[i].kind == .deepWork || blocks[i].kind == .breakSprint {
                    run.append(blocks[i]); i += 1
                }
                renderDeepWorkRun(run, runIndex: dwRunIndex, dwOrdinal: &dwOrdinal,
                                  dwTasksByOrdinal: dwTasksByOrdinal)
                dwRunIndex += 1
            } else {
                let block = blocks[i]
                // Hide-deep-work setting: skip the deep-work card (and its nested tasks) plus the
                // 5-minute break blocks paired with each sprint, so the plan shows just
                // appointments/routines. Keep dwOrdinal in step with dwBlocks (deep-work blocks only).
                if hideDeepWorkBlocks, block.kind == .deepWork || block.kind == .breakSprint {
                    if block.kind == .deepWork { dwOrdinal += 1 }
                    i += 1
                    continue
                }
                let card = makeCard(for: block)
                let key = blockKey(for: block)
                if let key = key {
                    card.onDrop = { [weak self] tid in self?.assignTask(tid, toKey: key) ?? false }
                }
                addCard(card)   // the card itself must be added — then its nested tasks beneath it
                if block.kind == .deepWork {
                    for task in dwTasksByOrdinal[dwOrdinal] ?? [] { addCard(makeNestedTaskRow(task)) }
                    dwOrdinal += 1
                } else if let key = key {
                    addNestedTasks(forKey: key)
                }
                i += 1
            }
        }

        // #2005 part 4: once the evening routine is done, the "well done — sleep / shut down" prompt sits
        // at the bottom of today's plan (not a standalone popup). "Not now" dismisses it for the day.
        if isViewingToday, shouldShowEveningShutdownPrompt() {
            let hosting = NSHostingView(rootView: makeEveningShutdownView(onDismiss: { dismissEveningShutdownPrompt() }))
            addCard(hosting)
        }

        // The day ends at 11:59pm; offer a jump to the next day's schedule.
        stackView.addArrangedSubview(makeViewTomorrowButton())
    }

    /// Render a run of consecutive deep-work + break blocks as one accordion: a header row
    /// ("▸ 🧠 Deep work · 9:03am–12pm") that toggles collapse, and — when expanded — the individual
    /// sprint/break cards (with nested deep-work tasks) exactly as they render standalone. `dwOrdinal`
    /// is advanced for every deep-work block whether collapsed or not, to stay in step with dwBlocks.
    private func renderDeepWorkRun(_ run: [ScheduleBlock], runIndex: Int, dwOrdinal: inout Int,
                                   dwTasksByOrdinal: [Int: [DayPlanTask]]) {
        guard let first = run.first, let last = run.last else { return }
        let dateForToggle = selectedDate
        let collapsed = isDeepWorkCollapsed(runIndex: runIndex, date: dateForToggle)
        let chevron = makeDisclosureChevron(collapsed: collapsed)
        let dwMinutes = max(0, Int(last.end.timeIntervalSince(first.start) / 60))
        let header = makeLabel("🧠 \(ScheduleText.deepWorkSession)  ·  \(timeString(first.start))–\(timeString(last.end))  \(ScheduleText.durationMinutesBrackets(dwMinutes))",
                               size: 15, bold: false)
        header.textColor = .labelColor
        header.setContentHuggingPriority(.defaultLow, for: .horizontal)
        header.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        header.lineBreakMode = .byTruncatingTail
        let headerRow = ClickableStack()
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 8
        headerRow.distribution = .fill
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addArrangedSubview(chevron)
        headerRow.addArrangedSubview(header)
        headerRow.onClick = { [weak self] in self?.toggleDeepWorkCollapsed(runIndex: runIndex, date: dateForToggle) }
        headerRow.toolTip = collapsed ? ScheduleText.showDeepWorkBreakdown : ScheduleText.hideDeepWorkBreakdown
        addCard(styledCard(fill: NSColor.systemGreen.withAlphaComponent(0.05),
                           border: NSColor.separatorColor, hasBorder: true, content: headerRow,
                           minimumHeight: collapsed ? DayPlanEventHeight.points(forDurationSeconds: dwMinutes * 60) : 0))

        for block in run {
            if collapsed {
                if block.kind == .deepWork { dwOrdinal += 1 }
                continue
            }
            let card = makeCard(for: block)
            let key = blockKey(for: block)
            if let key = key {
                card.onDrop = { [weak self] tid in self?.assignTask(tid, toKey: key) ?? false }
            }
            addCard(card)
            if block.kind == .deepWork {
                for task in dwTasksByOrdinal[dwOrdinal] ?? [] { addCard(makeNestedTaskRow(task)) }
                dwOrdinal += 1
            } else if let key = key {
                addNestedTasks(forKey: key)
            }
        }
    }

    /// Stable key a task is nested under for a given block. Deep-work sprints are keyed by start
    /// time (matched fuzzily on render); meetings by event id.
    private func blockKey(for block: ScheduleBlock) -> String? {
        switch block.kind {
        case .meeting: return block.eventID.map { DayPlanBlockKey.event(id: $0) }
        case .deepWork: return DayPlanBlockKey.deepWork(startingAt: block.start)
        default: return nil
        }
    }

    /// blockKey → the human name of the block, so the tasks panel's time-boxed badge can say which
    /// block a task is pinned to instead of just "Time boxed". Deep-work keys are resolved through the
    /// same ordinal matching the timeline uses, so a drifted key still names the sprint it renders under.
    private func timeBoxedTitles(in blocks: [ScheduleBlock], dwBlocks: [ScheduleBlock],
                                 dwTasksByOrdinal: [Int: [DayPlanTask]]) -> [String: String] {
        var titles: [String: String] = [:]
        func label(_ block: ScheduleBlock) -> String {
            "\(block.title)  ·  \(timeString(block.start))–\(timeString(block.end))"
        }
        for block in blocks where block.kind != .deepWork {
            if let key = blockKey(for: block) { titles[key] = label(block) }
        }
        for (ordinal, tasks) in dwTasksByOrdinal {
            guard dwBlocks.indices.contains(ordinal) else { continue }
            let sprint = label(dwBlocks[ordinal])
            for task in tasks { if let key = task.blockKey { titles[key] = sprint } }
        }
        return titles
    }

    /// The anchor timestamp stored in a deep-work task's key ("deepwork:<epoch>"), if any.
    private func deepWorkAnchor(_ key: String?) -> Double? {
        guard let key = key, key.hasPrefix("deepwork:") else { return nil }
        return Double(key.dropFirst("deepwork:".count))
    }

    /// Assigns each deep-work task to the nearest current sprint (the one whose time range holds its
    /// anchor, else the closest by start), keyed by the sprint's ordinal in render order.
    private func deepWorkTasksByOrdinal(_ dwBlocks: [ScheduleBlock]) -> [Int: [DayPlanTask]] {
        guard !dwBlocks.isEmpty else { return [:] }
        var map: [Int: [DayPlanTask]] = [:]
        let tasks = DayPlanTaskStore.shared.tasks(for: selectedDate).filter { ($0.blockKey?.hasPrefix("deepwork")) == true }
        for task in tasks {
            let anchor = deepWorkAnchor(task.blockKey)
            var bestOrd = 0
            var bestScore = Double.greatestFiniteMagnitude
            for (ord, b) in dwBlocks.enumerated() {
                let score: Double
                if let a = anchor {
                    let s = b.start.timeIntervalSince1970, e = b.end.timeIntervalSince1970
                    score = (a >= s && a <= e) ? 0 : min(abs(a - s), abs(a - e))
                } else {
                    score = Double(ord)   // legacy "deepwork" (no anchor) → first sprint
                }
                if score < bestScore { bestScore = score; bestOrd = ord }
            }
            map[bestOrd, default: []].append(task)
        }
        return map
    }

    private func addNestedTasks(forKey key: String) {
        for task in DayPlanTaskStore.shared.tasks(assignedTo: key, for: selectedDate) {
            addCard(makeNestedTaskRow(task))
        }
    }

    /// A task nested under a schedule block: indented, with a completion checkbox and a button to
    /// send it back to the panel.
    private func makeNestedTaskRow(_ task: DayPlanTask) -> NSView {
        let check = cursorButton(checkboxWithTitle: "", target: self, action: #selector(nestedTaskToggled(_:)))
        check.state = task.done ? .on : .off
        check.identifier = NSUserInterfaceItemIdentifier(task.id)
        let name = WrappingScheduleLabel(labelWithString: task.title)
        name.font = .systemFont(ofSize: 13)
        name.translatesAutoresizingMaskIntoConstraints = false
        // Wrap up to 2 lines then truncate so a long nested task can't force the card/window wide.
        name.usesSingleLineMode = false
        name.cell?.wraps = true
        name.cell?.isScrollable = false
        name.maximumNumberOfLines = 2
        name.lineBreakMode = .byTruncatingTail
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        name.setContentHuggingPriority(.defaultLow, for: .horizontal)
        name.textColor = task.done ? .secondaryLabelColor : .labelColor
        if task.done {
            name.attributedStringValue = NSAttributedString(string: task.title, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: 13)])
        }
        name.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let dur = makeLabel("\(task.durationMinutes)m", size: 12, bold: false)
        dur.textColor = .tertiaryLabelColor
        let back = cursorButton(title: "↩", target: self, action: #selector(nestedTaskUnassign(_:)))
        back.bezelStyle = .circular; back.controlSize = .small
        back.identifier = NSUserInterfaceItemIdentifier(task.id)
        back.toolTip = ScheduleText.tasksReturnToPanel

        let row = NSStackView(views: [check, name, dur, back])
        row.orientation = .horizontal; row.alignment = .centerY; row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView()
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 44),   // indent under the card
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 1),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1),
        ])
        return container
    }

    @discardableResult
    private func assignTask(_ id: String, toKey key: String) -> Bool {
        DayPlanTaskStore.shared.setBlockKey(key, forTaskID: id, date: selectedDate)
        lastRenderSignature = nil
        DispatchQueue.main.async { [weak self] in self?.reload(); self?.tasksPanel.reload() }
        return true
    }

    @objc private func nestedTaskToggled(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue,
              var t = DayPlanTaskStore.shared.task(withID: id, for: selectedDate) else { return }
        t.done = (sender.state == .on)
        // A task nested under a habit toggles here, NOT via DayPlanTasks.toggleDone — capture the same
        // completed/uncompleted event so these aren't missed. `nested: true` segments this entry point.
        DayPlanAnalytics.capture(t.done ? DayPlanAnalytics.taskCompleted : DayPlanAnalytics.taskUncompleted,
                                 ["from_todo": t.sourceTaskId != nil, "nested": true])
        DayPlanTaskStore.shared.update(t, for: selectedDate)
        lastRenderSignature = nil; reload(); tasksPanel.reload()
    }

    @objc private func nestedTaskUnassign(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        DayPlanTaskStore.shared.setBlockKey(nil, forTaskID: id, date: selectedDate)
        lastRenderSignature = nil; reload(); tasksPanel.reload()
    }

    /// A borderless link that toggles whether earlier-today events are shown.
    @objc private func openScheduleSettings(_ sender: NSButton) {
        let heading = makeLabel(ScheduleText.scheduleSettings, size: 13, bold: true)
        let check = cursorButton(checkboxWithTitle: ScheduleText.showEarlierEvents,
                             target: self, action: #selector(toggleEarlierEvents(_:)))
        check.state = showEarlierEvents ? .on : .off
        check.isEnabled = canShowEarlierToggle   // only meaningful when today has earlier events
        let hideDW = cursorButton(checkboxWithTitle: ScheduleText.hideDeepWork,
                              target: self, action: #selector(toggleHideDeepWork(_:)))
        hideDW.state = hideDeepWorkBlocks ? .on : .off
        let hideHabits = cursorButton(checkboxWithTitle: ScheduleText.hideHabitBlocks,
                                  target: self, action: #selector(toggleHideHabits(_:)))
        hideHabits.state = hideHabitBlocks ? .on : .off
        let showDismissed = cursorButton(checkboxWithTitle: ScheduleText.showDismissedEvents,
                                     target: self, action: #selector(toggleShowDismissedEvents(_:)))
        showDismissed.state = showDismissedEvents ? .on : .off
        let form = NSStackView(views: [heading, check, hideDW, hideHabits, showDismissed])
        form.orientation = .vertical; form.alignment = .leading; form.spacing = 10
        form.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView(); container.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            form.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])
        let vc = NSViewController(); vc.view = container
        let pop = NSPopover(); pop.contentViewController = vc; pop.behavior = .transient
        pop.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        scheduleSettingsPopover = pop
    }

    @objc private func toggleEarlierEvents(_ sender: NSButton) {
        showEarlierEvents = (sender.state == .on)
        lastRenderSignature = nil
        reload()
    }

    @objc private func toggleHideDeepWork(_ sender: NSButton) {
        hideDeepWorkBlocks = (sender.state == .on)
        lastRenderSignature = nil
        reload()
    }

    @objc private func toggleHideHabits(_ sender: NSButton) {
        hideHabitBlocks = (sender.state == .on)
        lastRenderSignature = nil
        reload()
    }

    @objc private func toggleShowDismissedEvents(_ sender: NSButton) {
        showDismissedEvents = (sender.state == .on)
        lastRenderSignature = nil
        reload()
    }

    /// A centered button at the bottom of the day to step forward to the next day's schedule.
    private func makeViewTomorrowButton() -> NSView {
        let button = cursorButton(title: ScheduleText.viewTomorrow, target: self, action: #selector(viewTomorrowClicked))
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.translatesAutoresizingMaskIntoConstraints = false
        let row = NSView()
        row.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            button.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -16),
            button.centerXAnchor.constraint(equalTo: row.centerXAnchor),
        ])
        return row
    }

    @objc private func viewTomorrowClicked() { changeDay(by: 1) }

    /// Adds a card to the stack and pins its width — the width constraint must be set
    /// *after* the card joins the stack so the two views share a common ancestor. The 48pt
    /// inset reserves room on the right so action buttons clear the scrollbar even when the
    /// system forces overlay scrollers (which ignore our `.legacy` request).
    private func addCard(_ card: NSView) {
        stackView.addArrangedSubview(card)
        card.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -48).isActive = true
    }

    // MARK: Habit group

    /// One bordered block holding all consecutive habits of a routine. Only the *selected*
    /// actionable habit shows a Play/Done/Skip bar underneath it; tapping another habit moves it.
    private func makeHabitGroupCard(_ habits: [ScheduleBlock]) -> DropTargetView {
        let durationHeight = DayPlanEventHeight.points(forDurationSeconds:
            habits.filter { !$0.didOverflow }.reduce(0) { $0 + max(0, $1.durationSeconds) })
        let inner = NSStackView()
        inner.orientation = .vertical
        inner.alignment = .leading
        inner.spacing = 4
        inner.translatesAutoresizingMaskIntoConstraints = false

        // Only render live-action affordances (Play/Done/Skip bar, "Skip routine", habit selection)
        // when the current host can actually perform them. The between-routines host (habitsStateVc,
        // ._NOTHING_) leaves those actions as no-ops, so without this gate a still-`isActionable`
        // block renders a dead action bar (buttons do nothing).
        let canAct = host?.supportsLiveHabitActions ?? false
        // The active routine (the one with the currently-actionable habit) gets a quick
        // "Skip routine for today" action on its header — the Day Plan equivalent of the Habits
        // view's "I don't have time for all these habits".
        let isActiveRoutine = canAct && habits.contains { $0.isActionable }
        // Routine sections are accordions: the header toggles collapse (chevron ▸/▾). They start
        // collapsed on future days so the plan is easy to scan for appointments.
        let routineName = habits.first?.routineName ?? "Habits"
        // The section's FIRST habit id keys the accordion so several same-named runs on one day
        // (e.g. two "Morning routine habits" blocks split by a meeting) expand/collapse independently.
        // It's stable across reloads — unlike the section start, which for the active routine re-packs
        // from `now` and would leave a start-keyed override stale after the toggle's reload. Falls back
        // to the habit index, then a start stamp, if a block ever lacks a server id.
        let sectionId = habits.first?.habitId
            ?? habits.first.flatMap { $0.habitIndex.map { "idx\($0)" } }
            ?? "start\(Int((habits.first?.start ?? selectedDate).timeIntervalSince1970))" // i18n-ignore — internal accordion key, never shown
        let dateForToggle = selectedDate
        // An overflow group (the routine didn't fit in the day) defaults to collapsed so it doesn't
        // dominate a packed plan — but a user expand/collapse still wins.
        let isOverflow = habits.first?.didOverflow == true
        // A routine with every habit done is complete → collapse by default (see isRoutineCollapsed).
        let habitBlocks = habits.filter { $0.kind == .habit }
        let routineComplete = !habitBlocks.isEmpty && habitBlocks.allSatisfy { $0.isDone }
        let collapsed = isOverflow
            ? (routineCollapseOverrides[routineCollapseKey(routineName, date: dateForToggle, sectionId: sectionId, overflow: true)] ?? true)
            : isRoutineCollapsed(name: routineName, date: dateForToggle, sectionId: sectionId, completed: routineComplete)
        // #2010: is THIS routine's section force-cancelled? Drives the uncancel message and hides the
        // "Skip routine for today" action (there's nothing to skip once it's cancelled).
        let cancel = host?.cancelledRoutine()
        let isCancelled = (cancel?.sectionName == routineName)
        if let first = habits.first, let last = habits.last {
            // A proper disclosure chevron (SF Symbol) instead of a tiny ▸/▾ glyph buried in the label —
            // it was too small to read as a tap target for collapse/expand.
            let chevron = makeDisclosureChevron(collapsed: collapsed)
            // Overflow groups have no meaningful time range (they're anchored after the last habit that
            // fit) — say "not enough time" instead of a "4:51pm–4:51pm" range. On another day's plan the
            // note must not claim "today".
            let overflowNote = isViewingToday ? ScheduleText.notEnoughTimeToday : ScheduleText.notEnoughTimeThisDay
            let headerSuffix = isOverflow ? overflowNote : "\(timeString(first.start))–\(timeString(last.end))"
            // A completed routine should read as "done" at a glance: swap the puzzle glyph for a green
            // check and dim the title, plus a trailing "Completed" badge added below.
            let routineGlyph = routineComplete ? "✅" : "🧩"
            let header = makeLabel("\(routineGlyph) \(routineName)  ·  \(headerSuffix)", size: 15, bold: false)
            header.textColor = routineComplete ? .secondaryLabelColor : .labelColor
            // Title stretches to fill and TRUNCATES in a narrow window; the skip button keeps its
            // intrinsic width pinned to the trailing edge.
            header.setContentHuggingPriority(.defaultLow, for: .horizontal)
            header.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            header.lineBreakMode = .byTruncatingTail

            let headerRow = ClickableStack()
            headerRow.orientation = .horizontal
            headerRow.alignment = .centerY
            headerRow.spacing = 8
            headerRow.distribution = .fill
            headerRow.translatesAutoresizingMaskIntoConstraints = false
            headerRow.addArrangedSubview(chevron)
            headerRow.addArrangedSubview(header)
            if routineComplete {
                // Explicit green "Completed" badge pinned to the trailing edge — the clearest signal the
                // routine is finished (the collapsed-by-default state alone didn't say why).
                let completedBadge = makeLabel("✓ \(ScheduleText.routineCompleted)", size: 13, bold: true)
                completedBadge.textColor = .systemGreen
                completedBadge.setContentHuggingPriority(.required, for: .horizontal)
                completedBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
                headerRow.addArrangedSubview(completedBadge)
            }
            // The header's "…" menu: "Skip routine for today" (active, unfinished routine only) and "Edit
            // routine timing" (any routine we can trace back to the settings JSON via one of its habit ids).
            let section = habits.first?.habitId.flatMap { DayPlanRoutineDraft.shared.routineSection(forHabitId: $0) }
            let showsSkip = isActiveRoutine && !routineComplete
            if !isCancelled && (showsSkip || section != nil) {
                let menuBtn = makeRoutineMenuButton(section: section, showsSkip: showsSkip)
                menuBtn.setContentHuggingPriority(.required, for: .horizontal)
                menuBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
                headerRow.addArrangedSubview(menuBtn)
            }
            headerRow.onClick = { [weak self] in self?.toggleRoutineCollapsed(name: routineName, date: dateForToggle, sectionId: sectionId, completed: routineComplete, overflow: isOverflow) }
            headerRow.toolTip = collapsed ? ScheduleText.showHabits : ScheduleText.hideHabits
            inner.addArrangedSubview(headerRow)
            headerRow.widthAnchor.constraint(equalTo: inner.widthAnchor).isActive = true
        }

        // #2010: a force-cancelled routine keeps its section (and accordion header) but swaps the habit
        // rows for an "uncancel" message with the button on its own line below it — the Day Plan stays visible.
        if isCancelled, let cancel = cancel {
            if !collapsed {
                let msg = makeLabel(cancel.message, size: 13, bold: false)
                msg.textColor = .secondaryLabelColor
                msg.maximumNumberOfLines = 0
                msg.lineBreakMode = .byWordWrapping
                msg.setContentHuggingPriority(.defaultLow, for: .horizontal)
                msg.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                inner.addArrangedSubview(msg)
                msg.widthAnchor.constraint(equalTo: inner.widthAnchor).isActive = true

                let btn = makeUncancelButton(title: cancel.buttonTitle)
                inner.addArrangedSubview(btn)
            }
            return styledCard(fill: NSColor.systemOrange.withAlphaComponent(0.05),
                              border: NSColor.separatorColor, hasBorder: true, content: inner, minimumHeight: durationHeight)
        }

        // Default selection = the next-up habit; keep the user's pick if it's still valid.
        let actionableIdxs = habits.filter { $0.isActionable }.compactMap { $0.habitIndex }
        let currentIdx = habits.first { $0.isCurrent }?.habitIndex
        let selected: Int? = (selectedHabitIndex.flatMap { actionableIdxs.contains($0) ? $0 : nil }) ?? currentIdx

        // A whole previous calendar day is in the past (so its habits are retroactively completable),
        // as is today's "earlier today" accordion (h.isEarlier). A future day is neither.
        let isPastDay = isViewingPastDay
        for h in habits where !collapsed {
            let isSel = canAct && h.isActionable && h.habitIndex == selected
            let isPastCompletable = (h.isEarlier || isPastDay) && !h.isDone && h.habitId != nil
            let rowView: NSView
            if isPastCompletable, let id = h.habitId {
                // #2012: a PAST habit that wasn't logged. Click-to-reveal, exactly like the live view —
                // a plain row until selected, then an orange unit with a Complete + Edit bar (no wall of
                // Done buttons). Completed by id with a backdated `performedAt` (its slot on the viewed
                // day), never the index-based live-routine path. An already-DONE past habit falls through
                // to the editable branch below: struck through, and selectable for an Edit-only bar.
                if selectedPastHabitId == id {
                    rowView = makeSelectedPastHabitUnit(h, id: id, performedAt: h.start)
                } else {
                    rowView = makeHabitRow(h, isSelected: false, onSelect: { [weak self] in
                        self?.selectedHabitIndex = nil
                        self?.selectedEditableHabitId = nil
                        self?.selectedPastHabitId = id
                        self?.lastRenderSignature = nil
                        self?.reload()
                    })
                }
            } else if isSel, let idx = h.habitIndex {
                // Selected: render as one connected orange unit (header + action bar, no gap),
                // matching the habit view.
                rowView = makeSelectedHabitUnit(h, idx: idx)
            } else if h.isEditable, let id = h.habitId, selectedEditableHabitId == id {
                // A preview/future routine's habit, a COMPLETED past habit, or any habit when the host
                // can't act: the same orange unit with an Edit-only bar — it can't be started (or is
                // already done), but its settings can still change.
                rowView = makeSelectedEditableHabitUnit(h, id: id)
            } else {
                rowView = makeHabitRow(h, isSelected: false)
            }
            // Wrap each habit in its own drop target so a dragged task attaches to this specific
            // habit (keyed by its title), and nests directly beneath it — not at the group's end.
            // The same key is what the habit player reads to show these tasks as a checklist.
            let key = HabitTaskChecklist.blockKey(forHabitNamed: h.title)
            let drop = DropTargetView()
            drop.translatesAutoresizingMaskIntoConstraints = false
            drop.onDrop = { [weak self] tid in self?.assignTask(tid, toKey: key) ?? false }
            rowView.translatesAutoresizingMaskIntoConstraints = false
            drop.addSubview(rowView)
            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: drop.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: drop.trailingAnchor),
                rowView.topAnchor.constraint(equalTo: drop.topAnchor),
                rowView.bottomAnchor.constraint(equalTo: drop.bottomAnchor),
            ])
            inner.addArrangedSubview(drop)
            drop.widthAnchor.constraint(equalTo: inner.widthAnchor).isActive = true
            for task in DayPlanTaskStore.shared.tasks(assignedTo: key, for: selectedDate) {
                let nested = makeNestedTaskRow(task)
                inner.addArrangedSubview(nested)
                nested.widthAnchor.constraint(equalTo: inner.widthAnchor).isActive = true
            }
        }

        return styledCard(fill: NSColor.systemOrange.withAlphaComponent(0.05),
                          border: isActiveRoutine ? NSColor.systemOrange : NSColor.separatorColor,
                          hasBorder: true, content: inner, minimumHeight: durationHeight)
    }

    /// A larger, sharper disclosure chevron for a routine/section accordion header (replaces the tiny
    /// ▸/▾ text glyph). Points right when collapsed, down when expanded.
    private func makeDisclosureChevron(collapsed: Bool) -> NSView {
        let iv = NSImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        let symbol = collapsed ? "chevron.forward" : "chevron.down"
        if #available(macOS 11.0, *), let base = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            iv.image = base.withSymbolConfiguration(cfg) ?? base
        } else {
            iv.image = nil
        }
        iv.contentTintColor = .secondaryLabelColor
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        iv.widthAnchor.constraint(equalToConstant: 16).isActive = true
        return iv
    }

    /// The routine header's "…" button. Opens a menu with "Skip routine for today" (replaces the old ✕,
    /// active routine only) and "Edit routine timing" (when the routine is known to the settings JSON).
    private func makeRoutineMenuButton(section: RoutineSettingsSection?, showsSkip: Bool) -> NSButton {
        let btn = RoutineMenuButton(title: "", target: self, action: #selector(routineMenuClicked(_:)))
        btn.section = section
        btn.showsSkip = showsSkip
        btn.isBordered = false
        btn.bezelStyle = .inline
        btn.imagePosition = .imageOnly
        btn.contentTintColor = .secondaryLabelColor
        if #available(macOS 11.0, *), let base = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: ScheduleText.routineMoreActions) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            btn.image = base.withSymbolConfiguration(cfg) ?? base
        } else {
            btn.title = "…"   // i18n-ignore — glyph only
        }
        btn.toolTip = ScheduleText.routineMoreActions
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        return btn
    }

    /// Header "…" carries the routine it belongs to so the menu can act on it without a lookup table.
    private final class RoutineMenuButton: cursorButton {
        var section: RoutineSettingsSection?
        var showsSkip = false
    }

    @objc private func routineMenuClicked(_ sender: RoutineMenuButton) {
        let menu = NSMenu()
        if sender.showsSkip {
            menu.addItem(withTitle: ScheduleText.skipRoutineForToday, action: #selector(skipRoutineForTodayClicked), keyEquivalent: "").target = self
        }
        if let section = sender.section {
            var actions = [(ScheduleText.editRoutineTiming, #selector(editRoutineTimingClicked(_:))),
                           (ScheduleText.addNewHabit, #selector(addNewHabitClicked(_:)))]
            // A custom routine has more than a start time to edit (name, days, on-demand, its habits'
            // order), so it also gets a way into the custom-routine manager.
            if case .custom = section {
                actions.append((ScheduleText.customRoutineEditTitle, #selector(editCustomRoutineClicked(_:))))
            }
            for (title, action) in actions {
                let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
                item.target = self
                item.representedObject = sender
            }
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    @objc private func editRoutineTimingClicked(_ item: NSMenuItem) {
        guard let section = (item.representedObject as? RoutineMenuButton)?.section else { return }
        openRoutineTimingEditor(section: section)
    }

    @objc private func addNewHabitClicked(_ item: NSMenuItem) {
        guard let section = (item.representedObject as? RoutineMenuButton)?.section else { return }
        openNewHabitEditor(section: section)
    }

    @objc private func skipRoutineForTodayClicked() {
        // Confirm before cancelling. Previously the ✕ opened ChooseHabitsVC and the routine was cancelled
        // via its Cancel button; now the ✕ asks directly and, on OK, runs the same cancel actions
        // (cancelRoutineForToday). Cancel leaves the routine unchanged.
        guard let window = view.window else { return }
        // Name only the routine this ✕ is actually cancelling (morning vs evening — same split as
        // cancelRoutineForToday), so the message points at the right Uncancel button.
        let isEvening = currentState == ._EVENING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_
            || currentState == ._FOCUS_SUMMARY_ || currentState == ._POSTPONE_FOCUS_SUMMARY_
        let uncancelButton = isEvening ? ScheduleText.uncancelEveningRoutineButton
                                       : ScheduleText.uncancelMorningRoutineButton
        let alert = NSAlert()
        alert.messageText = ScheduleText.cancelRoutineTitle
        alert.informativeText = ScheduleText.cancelRoutineMessage.replacingOccurrences(of: "<BUTTON>", with: uncancelButton)
        alert.addButton(withTitle: ScheduleText.cancelRoutineOk)       // first button → .alertFirstButtonReturn
        alert.addButton(withTitle: ScheduleText.cancelRoutineCancel)
        // Whether cancelling keeps the window open depends on the host: the active-routine host
        // (firstViewController) closes it (in-routine skip), the planning hosts keep it open. Hardcoding
        // true here was a regression — an in-progress routine's window stopped closing on cancel.
        let keepWindowOpen = host?.cancelRoutineKeepsWindowOpen ?? true
        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn else { return }   // Cancel → leave the routine unchanged
            cancelRoutineForToday(openedFromDayPlan: keepWindowOpen)    // OK
        }
    }

    /// The "Uncancel My Morning/Evening Routine" link shown in place of a force-cancelled routine's
    /// habits (#2010). Fires host.uncancelRoutine().
    private func makeUncancelButton(title: String) -> NSButton {
        // cursorButton shows the pointing-hand cursor on hover (via resetCursorRects/addCursorRect).
        let btn = cursorButton(title: title, target: self, action: #selector(uncancelRoutineClicked))
        btn.isBordered = false
        btn.bezelStyle = .inline
        btn.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.foregroundColor: NSColor.systemBlue,
                         .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                         .underlineStyle: NSUnderlineStyle.single.rawValue])
        return btn
    }

    @objc private func uncancelRoutineClicked() {
        host?.uncancelRoutine()
    }

    /// The leading time column of a habit row. An overflow habit has no slot in the day — the builder
    /// parks it zero-duration at the cursor — so rendering its start–end would read "6:57am–6:57am".
    /// Show how long it needs instead, which is the number that explains why it didn't fit.
    private func timeColumn(for block: ScheduleBlock) -> String {
        if block.didOverflow {
            let seconds = block.overflowDurationSeconds ?? block.durationSeconds
            if seconds > 0 { return HabitDurationText.short(seconds: seconds) }
        }
        return "\(timeString(block.start))–\(timeString(block.end))"
    }

    /// A single tappable habit line: time · emoji · name. No inline buttons — selecting it
    /// reveals the action bar underneath (see makeHabitGroupCard).
    private func makeHabitRow(_ block: ScheduleBlock, isSelected: Bool, onSelect: (() -> Void)? = nil) -> NSView {
        let container = ClickableRowView()
        container.wantsLayer = true
        container.translatesAutoresizingMaskIntoConstraints = false
        if isSelected {
            container.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.16).cgColor
            container.layer?.cornerRadius = 6
        }
        // A caller-supplied select handler (past-habit rows) wins; otherwise the live-routine row
        // selects itself by index.
        if let onSelect = onSelect {
            container.onClick = onSelect
        } else if block.isActionable, let idx = block.habitIndex, host?.supportsLiveHabitActions ?? false {
            // Only allow tap-to-select (which reveals the Play/Done/Skip bar) when the host can act;
            // in the read-only between-routines state selecting would just show a dead bar.
            container.onClick = { [weak self] in
                self?.selectedHabitIndex = idx
                self?.selectedEditableHabitId = nil
                self?.reload()
            }
        } else if block.isEditable, let id = block.habitId {
            // Not startable here (a preview/future routine, or a read-only host) but editable:
            // selecting reveals an Edit-only bar.
            container.onClick = { [weak self] in
                self?.selectedHabitIndex = nil
                self?.selectedPastHabitId = nil
                self?.selectedEditableHabitId = id
                self?.lastRenderSignature = nil
                self?.reload()
            }
        }

        let (titleLabel, _) = layoutColumns(in: container,
                                            time: timeColumn(for: block),
                                            title: block.title, leadingInset: 6, vPad: 6,
                                            timeColor: .secondaryLabelColor, titleColor: .labelColor)
        if block.isDone {
            strikeThrough(titleLabel, color: .secondaryLabelColor)
        } else if block.didOverflow {
            titleLabel.textColor = .systemRed
        }
        // After the strike-through / colour, which both rewrite the label's attributed string.
        if isHabitShortened(block.habitId) { appendShortenedTag(to: titleLabel) }
        return container
    }

    /// Whether this habit is running a shortened length on the day being viewed. The one answer behind
    /// both the action bar's "Shortened" caption and the list row's "(shortened)" tag, so the two can't
    /// disagree.
    func isHabitShortened(_ habitId: String?) -> Bool {
        DayPlanHabitDurations.overrideSeconds(for: habitId, on: selectedDate) != nil
    }

    /// Adds the small "(shortened)" after the habit's name so a trimmed habit is obvious in the list
    /// without opening its action bar.
    private func appendShortenedTag(to label: NSTextField, color: NSColor = .secondaryLabelColor) {
        label.attributedStringValue = DayPlanShortenedTag.appended(to: label.attributedStringValue,
                                                                   tag: ScheduleText.habitShortenedTag,
                                                                   color: color)
    }

    /// Strikes a completed habit's title through (same style as a done nested task). Uses the label's own
    /// text — layoutColumns splits the emoji into a separate leading label, so re-using `block.title`
    /// (emoji + name) here would render the emoji twice.
    private func strikeThrough(_ label: NSTextField, color: NSColor) {
        label.attributedStringValue = NSAttributedString(string: label.stringValue, attributes: [
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: color,
            .foregroundColor: color,
            .font: label.font ?? NSFont.systemFont(ofSize: 13)])
    }

    /// The selected habit as the habit-view's connected unit: a solid-orange header (white
    /// time · emoji · name) with the Play/Done/Skip bar joined directly beneath, all inside
    /// one orange rounded border with no gap between them.
    private func makeSelectedHabitUnit(_ block: ScheduleBlock, idx: Int) -> NSView {
        makeSelectedUnit(block, bar: makeActionBar(idx: idx, habitId: block.habitId, liveActions: true,
                                                   canShorten: canShortenHabits && !block.isDone))
    }

    /// The selected habit of a routine that can't be acted on here — a preview/future routine, or a habit
    /// already completed earlier today: Edit is the only action.
    private func makeSelectedEditableHabitUnit(_ block: ScheduleBlock, id: String) -> NSView {
        makeSelectedUnit(block, bar: makeActionBar(idx: block.habitIndex ?? 0, habitId: id, liveActions: false,
                                                   canShorten: canShortenHabits && !block.isDone))
    }

    /// One connected orange unit — header (white text, same column x-positions as the plain rows so it
    /// lines up) with `bar` joined directly beneath on the control background, inside a single orange
    /// rounded border (clipped so the header fills the top). Shared by the live, editable and past units.
    private func makeSelectedUnit(_ block: ScheduleBlock, bar: NSView) -> NSView {
        let header = NSView()
        header.wantsLayer = true
        header.layer?.backgroundColor = NSColor.systemOrange.cgColor
        header.translatesAutoresizingMaskIntoConstraints = false
        let (headerTitle, _) = layoutColumns(in: header, time: timeColumn(for: block),
                                            title: block.title, leadingInset: 6, vPad: 8,
                                            timeColor: .white, titleColor: .white)
        // A completed habit stays struck through while it's selected, so the Edit bar doesn't make it
        // read as un-done (white strike on the orange header, matching the plain row's grey one).
        if block.isDone { strikeThrough(headerTitle, color: .white) }
        // On the solid-orange header the secondary grey is unreadable — match the header's white text.
        if isHabitShortened(block.habitId) {
            appendShortenedTag(to: headerTitle,
                               color: NSColor.white.withAlphaComponent(DayPlanShortenedTag.onOrangeAlpha))
        }

        let unit = NSStackView(views: [header, bar])
        unit.orientation = .vertical
        unit.alignment = .leading
        unit.spacing = 0
        unit.translatesAutoresizingMaskIntoConstraints = false
        header.widthAnchor.constraint(equalTo: unit.widthAnchor).isActive = true
        bar.widthAnchor.constraint(equalTo: unit.widthAnchor).isActive = true

        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 8
        card.layer?.masksToBounds = true
        card.layer?.borderWidth = 2
        card.layer?.borderColor = NSColor.systemOrange.cgColor
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(unit)
        NSLayoutConstraint.activate([
            unit.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            unit.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            unit.topAnchor.constraint(equalTo: card.topAnchor),
            unit.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
        return card
    }

    private static let actionBarSpacing: CGFloat = 28
    private static let actionButtonDiameter: CGFloat = 40

    /// A 1pt vertical rule in the separator colour, the height of an action button (it sits in the
    /// top-aligned bar, so it spans the button row and stops above the labels).
    private func makeActionBarDivider() -> NSView {
        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: Self.actionButtonDiameter),
        ])
        return divider
    }

    /// The Play / Done / Skip / Edit / Stats bar shown beneath the selected habit (icon + label
    /// columns). Edit and Stats both need the habit's server id (they address the settings entry and
    /// the completed-activity history, not today's row), so both are omitted for a habit without one.
    /// `liveActions` is false for a routine that isn't running (preview/future): only Edit and Stats.
    private func makeActionBar(idx: Int, habitId: String?, liveActions: Bool, canShorten: Bool) -> NSView {
        let secondaryFill = NSColor.systemGray.withAlphaComponent(0.3)
        var columns = liveActions ? [
            makeActionColumn("play.fill", "▶", ScheduleText.play, .play, idx: idx, habitId: habitId, fill: .systemOrange),
            makeActionColumn("checkmark", "✓", ScheduleText.done, .done, idx: idx, habitId: habitId, fill: secondaryFill),
            makeActionColumn("forward.fill", "≫", ScheduleText.skip, .skip, idx: idx, habitId: habitId, fill: secondaryFill),
        ] : []
        if let habitId = habitId {
            // Edit/Stats are about the habit itself rather than today's row, so a hairline sets them
            // apart from Play/Done/Skip. The Edit-only bar (preview routines) has nothing to separate.
            if !columns.isEmpty { columns.append(makeActionBarDivider()) }
            // Skipping ahead only makes sense on a day that hasn't started — today's routine has its
            // own live Skip above (report 2026-09-13_20-13-58).
            if !liveActions { columns.append(makeSkipAheadColumn(idx: idx, habitId: habitId)) }
            // Shortening is about the plan for the day being viewed, so unlike Skip ahead it is offered
            // on today as well as on future days — just not on a day that has already been and gone.
            if canShorten { columns.append(makeShortenColumn(idx: idx, habitId: habitId)) }
            columns.append(makeEditColumn(idx: idx, habitId: habitId))
            columns.append(makeStatsColumn(idx: idx, habitId: habitId))
        }
        return makeActionBarContainer(columns: columns)
    }

    /// One action of the bar: the round icon button with its caption underneath.
    private func makeActionColumn(_ symbol: String, _ fallback: String, _ label: String, _ kind: ActionKind,
                                  idx: Int, habitId: String?, fill: NSColor) -> NSView {
        let btn = makeActionButton(symbol: symbol, fallback: fallback, idx: idx, kind: kind, habitId: habitId,
                                   diameter: Self.actionButtonDiameter, fill: fill)
        return makeActionColumn(button: btn, label: label)
    }

    private func makeActionColumn(button: NSView, label: String) -> NSView {
        let lbl = makeLabel(label, size: 12, bold: false)
        lbl.textColor = .secondaryLabelColor
        let col = NSStackView(views: [button, lbl])
        col.orientation = .vertical; col.alignment = .centerX; col.spacing = 3
        col.translatesAutoresizingMaskIntoConstraints = false
        return col
    }

    /// The Edit action, shared by the live, preview and past bars (it edits the settings entry, so the
    /// row index doesn't matter — only the habit id, which the button carries in its identifier).
    private func makeEditColumn(idx: Int, habitId: String) -> NSView {
        makeActionColumn("pencil", "✎", ScheduleText.editHabit, .edit,
                         idx: idx, habitId: habitId, fill: NSColor.systemGray.withAlphaComponent(0.3))
    }

    /// Skip this habit on the day being viewed, before it starts — and unskip it again. The state is
    /// per day, so skipping tomorrow's meditation leaves every other day alone.
    private func makeSkipAheadColumn(idx: Int, habitId: String) -> NSView {
        let skipped = DayPlanHabitSkips.isSkipped(habitId, on: selectedDate)
        return makeActionColumn(skipped ? "arrow.uturn.backward" : "forward.end.fill", skipped ? "↩" : "⏭",
                                skipped ? ScheduleText.habitUnskipAhead : ScheduleText.habitSkipAhead, .skipAhead,
                                idx: idx, habitId: habitId, fill: NSColor.systemGray.withAlphaComponent(0.3))
    }

    /// Trim this habit for the day being viewed only — and put it back. The trim lives on this Mac and
    /// never touches the habit, so every other day keeps the real length.
    private func makeShortenColumn(idx: Int, habitId: String) -> NSView {
        let shortened = isHabitShortened(habitId)
        return makeActionColumn("timer", "⏱", shortened ? ScheduleText.habitShortened : ScheduleText.habitShorten,
                                .shorten, idx: idx, habitId: habitId,
                                fill: shortened ? NSColor.systemOrange.withAlphaComponent(0.35)
                                                : NSColor.systemGray.withAlphaComponent(0.3))
    }

    /// The Stats action, sitting beside Edit — it opens this habit's own streak / heat map / logged-
    /// quantity history, so like Edit it's addressed by habit id rather than row index.
    private func makeStatsColumn(idx: Int, habitId: String) -> NSView {
        makeActionColumn("chart.bar", "📊", ScheduleText.habitStats, .stats,
                         idx: idx, habitId: habitId, fill: NSColor.systemGray.withAlphaComponent(0.3))
    }

    /// The bar's chrome: columns laid out left-to-right, inset from the orange header above them.
    private func makeActionBarContainer(columns: [NSView]) -> NSView {
        let bar = NSStackView(views: columns)
        bar.orientation = .horizontal
        bar.alignment = .top
        bar.spacing = Self.actionBarSpacing
        bar.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            // Breathing room above the buttons so they don't sit flush against the orange
            // header, matching the habit view's spacing.
            bar.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            bar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            bar.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
        ])
        return container
    }

    /// #2012: the SELECTED past habit — same connected orange unit as the live selected habit
    /// (makeSelectedHabitUnit), but with a Complete + Edit action bar (no Play/Skip: you can't start a
    /// past habit, and an un-struck one is already evidently un-done). Shown only when the user has
    /// clicked the row; other past rows are plain (click-to-reveal), so there's no wall of Done buttons.
    /// Completion is by id with the backdated `performedAt`.
    private func makeSelectedPastHabitUnit(_ block: ScheduleBlock, id: String, performedAt: Date) -> NSView {
        makeSelectedUnit(block, bar: makePastActionBar(habitId: id, performedAt: performedAt))
    }

    /// A Complete + Edit bar for a past habit — there's no Skip because an un-struck earlier-today habit
    /// is already evidently un-done, and no Play because you can't start it. The Complete button carries
    /// the habit id in its identifier so the tap dispatches host.schedulePastHabitDone(id:); Edit sits
    /// after the same hairline the live bar uses, since it changes the settings rather than the record.
    private func makePastActionBar(habitId: String, performedAt: Date) -> NSView {
        // Orange (primary) tick — it's the ONLY action here, so it gets the same emphasis Play gets in
        // the live bar (grey read as disabled). Label "Complete" + a reassuring micro-copy line.
        let btn = makePastActionButton(symbol: "checkmark", fallback: "✓", habitId: habitId,
                                       performedAt: performedAt, tag: "pastdone",
                                       diameter: 40, fill: .systemOrange)
        let title = makeLabel(ScheduleText.pastHabitComplete, size: 13, bold: true)
        title.textColor = .labelColor
        let hint = makeLabel(ScheduleText.pastHabitCompleteHint, size: 11, bold: false)
        hint.textColor = .secondaryLabelColor
        hint.lineBreakMode = .byTruncatingTail
        hint.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let textStack = NSStackView(views: [title, hint])
        textStack.orientation = .vertical; textStack.alignment = .leading; textStack.spacing = 1
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let complete = NSStackView(views: [btn, textStack])
        complete.orientation = .horizontal; complete.alignment = .centerY; complete.spacing = 10
        complete.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [complete, makeActionBarDivider(), makeEditColumn(idx: 0, habitId: habitId)])
        row.orientation = .horizontal; row.alignment = .centerY; row.spacing = Self.actionBarSpacing
        row.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            row.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12),
        ])
        return container
    }

    /// Like makeActionButton but keyed by habit id + backdated completion time (in the identifier)
    /// rather than a row index, dispatching to pastActionButtonClicked. `tag` is "pastdone".
    private func makePastActionButton(symbol: String, fallback: String, habitId: String, performedAt: Date,
                                      tag: String, diameter: CGFloat = 30, fill: NSColor? = nil) -> NSView {
        let disc = NSView()
        disc.wantsLayer = true
        disc.layer?.backgroundColor = (fill ?? .clear).cgColor
        disc.layer?.cornerRadius = diameter / 2
        disc.layer?.masksToBounds = true
        disc.translatesAutoresizingMaskIntoConstraints = false

        let btn = cursorButton(title: "", target: self, action: #selector(pastActionButtonClicked(_:)))
        btn.imagePosition = .imageOnly
        btn.isBordered = false
        btn.wantsLayer = true
        if #available(macOS 11.0, *), let base = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: diameter * 0.42, weight: .semibold)
            btn.image = base.withSymbolConfiguration(cfg) ?? base
        } else {
            btn.title = fallback
        }
        btn.contentTintColor = .white   // white tick on the orange (primary) disc
        btn.translatesAutoresizingMaskIntoConstraints = false
        // Encode kind + backdated epoch + id. Parsed on the first two ":" so the id (which never
        // contains ":") is the remainder — carries the completion date without extra plumbing.
        btn.identifier = NSUserInterfaceItemIdentifier("\(tag):\(Int(performedAt.timeIntervalSince1970)):\(habitId)")

        disc.addSubview(btn)
        NSLayoutConstraint.activate([
            disc.widthAnchor.constraint(equalToConstant: diameter),
            disc.heightAnchor.constraint(equalToConstant: diameter),
            btn.leadingAnchor.constraint(equalTo: disc.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: disc.trailingAnchor),
            btn.topAnchor.constraint(equalTo: disc.topAnchor),
            btn.bottomAnchor.constraint(equalTo: disc.bottomAnchor),
        ])
        disc.setContentHuggingPriority(.required, for: .horizontal)
        disc.setContentCompressionResistancePriority(.required, for: .horizontal)
        return disc
    }

    @objc private func pastActionButtonClicked(_ sender: NSButton) {
        // identifier = "<kind>:<epoch>:<habitId>" (habitId never contains ":").
        guard let raw = sender.identifier?.rawValue else { return }
        let parts = raw.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, let epoch = TimeInterval(parts[1]) else { return }
        let kind = String(parts[0]); let id = String(parts[2])
        guard !id.isEmpty else { return }
        switch kind {
        case "pastdone":
            host?.schedulePastHabitDone(id: id, performedAt: Date(timeIntervalSince1970: epoch))
            selectedPastHabitId = nil   // it's now done → next render strikes it through, no action bar
            scheduleReload(after: 0.3)
        default: break
        }
    }

    // MARK: Non-habit cards (meeting / deep work / markers)

    private func makeCard(for block: ScheduleBlock) -> DropTargetView {
        let fill: NSColor
        let border: NSColor
        switch block.kind {
        case .meeting:
            // Use the user's chosen colour for this event if set, else the default blue.
            let base = block.eventID.flatMap { CalendarManager.shared.color(forEventID: $0) } ?? .systemBlue
            fill = base.withAlphaComponent(0.10); border = base.withAlphaComponent(0.5)
        case .deepWork:
            fill = NSColor.systemGreen.withAlphaComponent(0.10); border = NSColor.systemGreen.withAlphaComponent(0.5)
        case .breakSprint:
            fill = NSColor.systemOrange.withAlphaComponent(0.10); border = NSColor.systemOrange.withAlphaComponent(0.5)
        case .routineTransition:
            fill = NSColor.systemPurple.withAlphaComponent(0.10); border = NSColor.systemPurple.withAlphaComponent(0.5)
        case .sleep:
            fill = NSColor.systemIndigo.withAlphaComponent(0.10); border = NSColor.systemIndigo.withAlphaComponent(0.4)
        case .allDone, .habit:
            fill = .clear; border = .clear
        }

        let showStartOnly = block.kind == .allDone || block.kind == .routineTransition
        let timeText = showStartOnly ? timeString(block.start) : "\(timeString(block.start))–\(timeString(block.end))"
        let title = block.kind == .allDone ? "✅ " + ScheduleText.habitsDone : block.title

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        let (titleLabel, titleTrailing) = layoutColumns(in: content, time: timeText, title: title,
                                                        leadingInset: 6, vPad: 8,
                                                        timeColor: .secondaryLabelColor, titleColor: .labelColor)
        if block.isDismissed {
            // A dismissed meeting surfaced by "Show dismissed events": strike it through and dim it.
            titleLabel.attributedStringValue = NSAttributedString(string: titleLabel.stringValue, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: titleLabel.font ?? NSFont.systemFont(ofSize: 13)])
        }
        var lastTrailing = titleTrailing
        if let subtitle = block.subtitle {
            let sub = makeLabel(subtitle, size: 13, bold: false)
            sub.textColor = .tertiaryLabelColor
            sub.lineBreakMode = .byTruncatingTail
            sub.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            content.addSubview(sub)
            sub.leadingAnchor.constraint(equalTo: lastTrailing, constant: 8).isActive = true
            sub.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
            // Never let the subtitle push past the card edge (a meeting's Hide button sits ~72pt in).
            sub.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor,
                                          constant: block.kind == .meeting ? -80 : -8).isActive = true
            lastTrailing = sub.trailingAnchor
        }
        if block.kind == .deepWork || block.kind == .sleep || block.kind == .breakSprint {
            let dur = makeLabel(durationString(block.durationSeconds), size: 13, bold: false)
            dur.textColor = .secondaryLabelColor
            dur.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            content.addSubview(dur)
            dur.leadingAnchor.constraint(equalTo: lastTrailing, constant: 8).isActive = true
            dur.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
            dur.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -8).isActive = true
        }
        // ✕ to hide a calendar meeting (or 👀 to bring back a dismissed one), pinned to the trailing edge.
        if block.kind == .meeting, let eid = block.eventID {
            // A bare ✕ read as "delete this event" — a user assumed clicking it would remove the meeting
            // from their calendar. It only hides the row, so say so: a labelled button, not a glyph.
            let x = cursorButton(title: block.isDismissed ? ScheduleText.showEventButton : ScheduleText.hideEventButton,
                                 target: self, action: #selector(dismissMeetingClicked(_:)))
            x.bezelStyle = .rounded
            x.font = NSFont.systemFont(ofSize: 11)
            x.translatesAutoresizingMaskIntoConstraints = false
            x.identifier = NSUserInterfaceItemIdentifier((block.isDismissed ? "undismiss:" : "dismiss:") + eid)
            x.toolTip = block.isDismissed ? ScheduleText.showEventAgain : ScheduleText.hideEvent
            content.addSubview(x)
            NSLayoutConstraint.activate([
                // Sized to its label rather than a fixed square, so "🙈 Hide" and "👀 Show" both fit.
                x.heightAnchor.constraint(equalToConstant: 22),
                x.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
                x.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            ])
        }

        let durationHeight = [.meeting, .deepWork, .breakSprint].contains(block.kind)
            ? DayPlanEventHeight.points(forDurationSeconds: block.durationSeconds) : 0
        let card = styledCard(fill: fill, border: border, hasBorder: block.kind != .allDone,
                              content: content, minimumHeight: durationHeight)
        // Click a meeting card (anywhere but the ✕) to open its edit form.
        if block.kind == .meeting, let eid = block.eventID {
            // The occurrence travels with the id: a recurring event's identifier names the whole
            // series, so without it the editor would open on the series' first occurrence — which is
            // how an edit made in September showed an August date (report 2026-09-11_21-00-07).
            card.identifier = NSUserInterfaceItemIdentifier(
                "edit:\(eid)\(Self.occurrenceSeparator)\(block.start.timeIntervalSince1970)-\(block.end.timeIntervalSince1970)")
            let click = NSClickGestureRecognizer(target: self, action: #selector(meetingCardClicked(_:)))
            click.delegate = self   // so it ignores clicks on the ✕ (dismiss) button
            card.addGestureRecognizer(click)
        }
        return card
    }

    /// Separates a card's event id from the occurrence times appended after it. Chosen so it cannot
    /// appear inside an EventKit identifier.
    static let occurrenceSeparator = "|occ:"

    /// Splits `edit:<id>|occ:<start>-<end>` back into its parts. The occurrence is absent for cards
    /// written before this, and for anything that isn't a meeting card.
    static func parseMeetingCardIdentifier(_ raw: String) -> (eventID: String, start: Date, end: Date)? {
        guard raw.hasPrefix("edit:") else { return nil }
        let body = String(raw.dropFirst("edit:".count))
        let parts = body.components(separatedBy: occurrenceSeparator)
        guard parts.count == 2, !parts[0].isEmpty else {
            return body.isEmpty ? nil : (body, .distantPast, .distantPast)
        }
        let times = parts[1].components(separatedBy: "-")
        guard times.count == 2, let start = Double(times[0]), let end = Double(times[1]), end > start else {
            return (parts[0], .distantPast, .distantPast)
        }
        return (parts[0], Date(timeIntervalSince1970: start), Date(timeIntervalSince1970: end))
    }

    @objc private func meetingCardClicked(_ g: NSClickGestureRecognizer) {
        guard let card = g.view, let raw = card.identifier?.rawValue,
              let parsed = Self.parseMeetingCardIdentifier(raw) else { return }
        let occurrence = parsed.start == .distantPast ? nil : (start: parsed.start, end: parsed.end)
        openEventEditor(eventID: parsed.eventID, occurrence: occurrence, from: card)
    }

    /// Finds the meeting card's ✕ (dismiss) button, if any, anywhere in its subtree.
    private func dismissButton(in view: NSView) -> NSView? {
        // Match both the ✕ (dismiss:) and the 👀 (undismiss:) buttons so the card's click gesture ignores
        // clicks on either — otherwise tapping 👀 falls through to the card and opens the event editor.
        if let id = view.identifier?.rawValue, id.hasPrefix("dismiss:") || id.hasPrefix("undismiss:") { return view }
        for sub in view.subviews { if let f = dismissButton(in: sub) { return f } }
        return nil
    }

    /// A rounded, optionally-bordered card sized to its content and the stack width. It's a
    /// DropTargetView so the caller can accept a dragged task (set its `onDrop`).
    ///
    /// `minimumHeight` reserves duration space and centres content within it.
    /// Zero keeps a content-sized card.
    private func styledCard(fill: NSColor, border: NSColor, hasBorder: Bool, content: NSView,
                            minimumHeight: CGFloat = 0) -> DropTargetView {
        let card = DropTargetView()
        card.wantsLayer = true
        card.layer?.backgroundColor = fill.cgColor
        card.layer?.cornerRadius = 8
        card.layer?.borderWidth = hasBorder ? 1 : 0
        card.layer?.borderColor = border.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            content.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            content.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 8),
            card.bottomAnchor.constraint(greaterThanOrEqualTo: content.bottomAnchor, constant: 8),
        ])
        // A weak preferred height lets intrinsic content grow while keeping unused space
        // symmetric above and below the title and its time range.
        let preferredHeight = card.heightAnchor.constraint(equalToConstant: minimumHeight)
        preferredHeight.priority = NSLayoutConstraint.Priority(249)
        preferredHeight.isActive = true
        if minimumHeight > 0 {
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight).isActive = true
        }
        return card   // width is constrained by addCard(), once the card is in the stack
    }

    private enum ActionKind { case play, done, skip, edit, stats, skipAhead, shorten }
    /// Edit buttons carry the habit id after this prefix in their identifier (Play/Done/Skip are index-based).
    private static let editActionPrefix = "edit:"
    /// Stats buttons carry the habit id the same way.
    private static let statsActionPrefix = "stats:"
    /// Skip-ahead buttons too — the skip is recorded against the habit id and the viewed day.
    private static let skipAheadActionPrefix = "skipAhead:"
    /// Shorten buttons — the one-day trim is recorded against the habit id and the viewed day.
    private static let shortenActionPrefix = "shorten:"

    /// The habit-id-addressed actions and the prefix each stamps into its button identifier.
    private static func actionPrefix(for kind: ActionKind) -> String? {
        switch kind {
        case .edit: return editActionPrefix
        case .stats: return statsActionPrefix
        case .skipAhead: return skipAheadActionPrefix
        case .shorten: return shortenActionPrefix
        default: return nil
        }
    }

    private func makeActionButton(symbol: String, fallback: String, idx: Int, kind: ActionKind, habitId: String? = nil,
                                  diameter: CGFloat = 30, fill: NSColor? = nil) -> NSView {
        // The colored circle is drawn on a dedicated disc view (not the NSButton's own managed
        // layer, which AppKit can redraw as a rounded rect) so it's always a clean circle.
        let disc = NSView()
        disc.wantsLayer = true
        disc.layer?.backgroundColor = (fill ?? .clear).cgColor
        disc.layer?.cornerRadius = diameter / 2
        disc.layer?.masksToBounds = true
        disc.translatesAutoresizingMaskIntoConstraints = false

        let btn = cursorButton(title: "", target: self, action: #selector(actionButtonClicked(_:)))
        btn.imagePosition = .imageOnly
        btn.isBordered = false
        btn.wantsLayer = true
        if #available(macOS 11.0, *), let base = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: diameter * 0.42, weight: .semibold)
            btn.image = base.withSymbolConfiguration(cfg) ?? base
        } else {
            btn.title = fallback
        }
        btn.contentTintColor = (kind == .play) ? .white : .labelColor
        btn.tag = idx
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.identifier = NSUserInterfaceItemIdentifier(
            Self.actionPrefix(for: kind).map { $0 + (habitId ?? "") } ?? "\(kind)")

        disc.addSubview(btn)
        NSLayoutConstraint.activate([
            disc.widthAnchor.constraint(equalToConstant: diameter),
            disc.heightAnchor.constraint(equalToConstant: diameter),
            btn.leadingAnchor.constraint(equalTo: disc.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: disc.trailingAnchor),
            btn.topAnchor.constraint(equalTo: disc.topAnchor),
            btn.bottomAnchor.constraint(equalTo: disc.bottomAnchor),
        ])
        disc.setContentHuggingPriority(.required, for: .horizontal)
        disc.setContentCompressionResistancePriority(.required, for: .horizontal)
        return disc
    }

    @objc private func actionButtonClicked(_ sender: NSButton) {
        let idx = sender.tag
        guard let id = sender.identifier?.rawValue else { return }
        switch id {
        case "play":
            host?.scheduleStart(index: idx)
            scheduleReload(after: 0.3)
        case "done":
            // #2103: mirror Skip exactly. The old code green-flashed the row and animated it to
            // alphaValue 0 (hidden) before scheduleDone showed the password prompt, so cancelling the
            // prompt left the row/Done button gone — and any pre-confirm visual (fade or green tint)
            // lingered when the action didn't complete. Keep the row visible on click and let the normal
            // reload/refetch reflect the outcome: restored on cancel, struck through on success.
            removeHabitFromCache(index: idx)   // so it can't flash back during the refetch
            host?.scheduleDone(index: idx)
            scheduleReload(after: 0.25)
        case "skip":
            removeHabitFromCache(index: idx)
            host?.scheduleSkip(index: idx)
            scheduleReload(after: 0.25)
        case _ where id.hasPrefix(Self.skipAheadActionPrefix):
            let habitId = String(id.dropFirst(Self.skipAheadActionPrefix.count))
            let skipped = DayPlanHabitSkips.toggle(habitId, on: selectedDate)
            addLog(text: "[user-action] day plan: habit \(skipped ? "skipped" : "unskipped") ahead for \(DayPlanHabitSkips.dayKey(selectedDate))")
            lastRenderSignature = nil
            reload()
        case _ where id.hasPrefix(Self.shortenActionPrefix):
            openShortenHabitSheet(habitId: String(id.dropFirst(Self.shortenActionPrefix.count)))
        case _ where id.hasPrefix(Self.editActionPrefix):
            openHabitEditor(habitId: String(id.dropFirst(Self.editActionPrefix.count)))
        case _ where id.hasPrefix(Self.statsActionPrefix):
            openHabitStats(habitId: String(id.dropFirst(Self.statsActionPrefix.count)))
        default: break
        }
    }

    // MARK: - Per-habit stats

    /// The habit's "✍️ Journal" style title from the routine settings, handed to the stats sheet so its
    /// header reads correctly while `/user-settings` is still in flight.
    private func habitDisplayTitle(habitId: String) -> String {
        guard let values = DayPlanRoutineDraft.shared.habitEditValues(id: habitId) else { return ScheduleText.habitStats }
        let composed = [values.icon, values.name].filter { !$0.isEmpty }.joined(separator: " ")
        return composed.isEmpty ? ScheduleText.habitStats : composed
    }

    /// The day's habits for the Fix modal, **longest first** — that is where the minutes are, and the
    /// report asked for it. Skipped habits stay on the list so the skip can be undone from the same
    /// place it was made.
    ///
    /// The evening routine is left out: "we assume all tasks get completed before evening routine -
    /// just offer to shorten morning routine" (report 2026-09-17_08-15-57, follow-up). Counting it made
    /// the route offer 5h 54m of habits on a day whose morning routine was a fraction of that.
    private func dayFixHabitRows() -> [DayFixHabitRow] {
        let day = selectedDate
        let eveningStart = ScheduleTab.timeOnDate(shutOffTime, date: day)
        let habitBlocks = DayFixPlan.habitsInsideWorkingDay(
            scheduleBlocks(for: day).filter { $0.kind == .habit && !$0.didOverflow },
            start: { $0.start },
            isEveningRoutine: { $0.routineName == ScheduleText.eveningRoutineHabits },
            eveningRoutineStart: eveningStart)
        var seen = Set<String>()
        let rows: [DayFixHabitRow] = habitBlocks.compactMap { block in
            guard let id = block.habitId, !id.isEmpty, seen.insert(id).inserted else { return nil }
            return DayFixHabitRow(id: id, title: block.title,
                                  seconds: block.durationSeconds,
                                  isSkipped: DayPlanHabitSkips.isSkipped(id, on: day),
                                  isShortened: DayPlanHabitDurations.overrideSeconds(for: id, on: day) != nil)
        }
        return DayFixPlan.longestFirst(rows, seconds: { $0.seconds }, name: { $0.title })
    }

    // MARK: - The Fix modal's meetings route

    /// The meetings the Fix modal can still claw time back from, longest first.
    ///
    /// Only what is still ahead on the day being viewed: a meeting that has already finished cannot
    /// give the day a minute back, so offering to cancel it would be a dead button. Dismissed meetings
    /// stay on the list (struck through) so a skip can be undone where it was made — they are not
    /// counted towards what the route could free, because they already cost the day nothing.
    private func dayFixMeetingRows() -> [DayFixMeetingRow] {
        let day = selectedDate
        let cal = Calendar.current
        let floor = cal.isDateInToday(day) ? Date() : cal.startOfDay(for: day)
        // The SAME cache key the day's own render uses. Asking for a different one would hand back an
        // empty list the first time the modal is opened (the meetings cache never blocks the main
        // thread — it refreshes in the background and answers from what it has), which is exactly the
        // "missing calendar events" this route exists to fix.
        let rows = CalendarManager.shared.meetings(for: day, includeDismissed: showDismissedEvents)
            .filter { $0.end > floor }
            .map { meeting -> DayFixMeetingRow in
                DayFixMeetingRow(
                    id: "\(meeting.id)|\(meeting.start.timeIntervalSince1970)",
                    eventID: meeting.id,
                    title: meeting.title,
                    start: meeting.start,
                    timeLabel: Self.timeFormatter.string(from: meeting.start),
                    seconds: Int(meeting.end.timeIntervalSince(meeting.start)),
                    // Ownership and attendees were read on the background fetch, so deciding the action
                    // costs nothing here.
                    action: DayFixPlan.meetingAction(hasOtherAttendees: meeting.hasOtherAttendees,
                                                     ownership: meeting.ownership),
                    isRecurring: meeting.isRecurring,
                    isSkipped: meeting.isDismissed,
                    isShortened: DayPlanMeetingDurations.overrideSeconds(forEventID: meeting.id, on: day) != nil)
            }
        return DayFixPlan.longestFirst(rows, seconds: { $0.seconds }, name: { $0.title })
    }

    /// Skip / un-skip one meeting for the day being viewed. Same per-day dismissal the row's own ✕
    /// makes, so a meeting skipped from the Fix modal can be brought back with "Show dismissed events"
    /// like any other.
    private func dayFixToggleSkipMeeting(_ row: DayFixMeetingRow) {
        if row.isSkipped {
            lastRenderSignature = nil
            CalendarManager.shared.restoreDismissedEvent(id: row.eventID, forDay: selectedDate)
            DayPlanSync.shared.undismissEvent(eventID: row.eventID, on: selectedDate)
            reload()
        } else {
            // This day only — the Fix modal is about one day, and the series-wide question the Day Plan
            // row asks would be the wrong question here.
            dismissMeeting(eventId: row.eventID, seriesWide: false)
        }
    }

    /// Cancel or decline one meeting from the Fix modal. The confirmation, the this-occurrence-or-the-
    /// series question and the removal itself are the editor's, unchanged — this only supplies the
    /// event, so there is one implementation of "take a meeting off the calendar" (`EventCancellationFlow`).
    private func dayFixCancelMeeting(_ row: DayFixMeetingRow) {
        // The row already carries which of the two it is (`DayFixPlan.meetingAction`), so the rule is
        // not re-derived — and a row offering Skip never reaches here.
        guard row.action != .skip else { return }
        let action: EventCancelAction = row.action == .cancel ? .cancelEvent : .declineEvent
        removeEvent(eventID: row.eventID, action: action,
                    isRecurring: row.isRecurring,
                    occurrenceStart: row.start,
                    // Nothing has asked which occurrences yet — the Fix modal has no form to have
                    // asked in — so the flow asks, once, for a repeating meeting.
                    knownScope: nil)
    }

    /// The shorten sheet for one meeting: the same sheet a habit gets, saying honestly that the trim is
    /// the Day Plan's and the calendar copy is untouched.
    private func dayFixShortenMeeting(_ row: DayFixMeetingRow) {
        guard #available(macOS 11.0, *) else { return }
        let day = selectedDate
        guard let actualSeconds = CalendarManager.shared.untrimmedSeconds(forEventID: row.eventID, on: day,
                                                                         occurrenceStart: row.start) else {
            showDraftAlert(title: ScheduleText.eventRemoveFailedTitle, message: "")
            return
        }
        DayPlanAnalytics.capture(DayPlanAnalytics.eventShortenOpened)
        var sheet: DayPlanSheetController!
        let view = DayPlanShortenHabitView(
            habitTitle: row.title,
            copy: .meeting(dayLabel: Self.dateFormatterThisYear.string(from: day)),
            actualSeconds: actualSeconds,
            currentSeconds: DayPlanMeetingDurations.overrideSeconds(forEventID: row.eventID, on: day),
            onPick: { [weak self] seconds in
                let applied = CalendarManager.shared.setMeetingTrim(seconds, forEventID: row.eventID, on: day,
                                                                    actualSeconds: actualSeconds)
                DayPlanAnalytics.capture(applied == nil ? DayPlanAnalytics.eventShortenCleared
                                                        : DayPlanAnalytics.eventShortened)
                addLog(text: "[user-action] day plan: meeting shortened to \(applied.map(String.init) ?? "full") seconds for \(DayPlanMeetingDurations.dayKey(day))")
                self?.dismissDraftSheet(sheet)
                self?.reloadAfterShorten()
            },
            onFullLength: { [weak self] in
                CalendarManager.shared.setMeetingTrim(nil, forEventID: row.eventID, on: day,
                                                      actualSeconds: actualSeconds)
                DayPlanAnalytics.capture(DayPlanAnalytics.eventShortenCleared)
                addLog(text: "[user-action] day plan: meeting restored to full length for \(DayPlanMeetingDurations.dayKey(day))")
                self?.dismissDraftSheet(sheet)
                self?.reloadAfterShorten()
            },
            onCancel: { [weak self] in self?.dismissDraftSheet(sheet) })
        sheet = DayPlanSheetController(size: Self.shortenHabitSheetSize, content: view)
        presentAsSheet(sheet)
    }

    // MARK: - Shortening a habit for one day

    /// Opens the "Shorten" sheet for the habit and the day currently being viewed. The chosen length is
    /// stored locally against that day only (`DayPlanHabitDurations`); the habit itself is untouched, so
    /// Settings › Edit habits still shows the real duration (report 2026-09-15_20-29-02).
    private func openShortenHabitSheet(habitId: String) {
        guard #available(macOS 11.0, *), !habitId.isEmpty else { return }
        guard let model = ScheduleTab.routineHabit(withId: habitId) else {
            showDraftAlert(title: ScheduleText.habitEditUnavailable, message: "")
            return
        }
        let actualSeconds = ScheduleTab.estimatedDuration(for: model)
        let day = selectedDate
        DayPlanAnalytics.capture(DayPlanAnalytics.habitShortenOpened)
        var sheet: DayPlanSheetController!
        let view = DayPlanShortenHabitView(
            habitTitle: model.name ?? ScheduleText.habitShortenTitle,
            copy: .habit(dayLabel: Self.dateFormatterThisYear.string(from: day)),
            actualSeconds: actualSeconds,
            currentSeconds: DayPlanHabitDurations.overrideSeconds(for: habitId, on: day),
            onPick: { [weak self] seconds in
                let applied = DayPlanHabitDurations.setOverride(seconds, for: habitId, on: day, actual: actualSeconds)
                DayPlanAnalytics.capture(applied == nil ? DayPlanAnalytics.habitShortenCleared
                                                        : DayPlanAnalytics.habitShortened)
                addLog(text: "[user-action] day plan: habit shortened to \(applied.map(String.init) ?? "full") seconds for \(DayPlanHabitDurations.dayKey(day))")
                self?.dismissDraftSheet(sheet)
                self?.reloadAfterShorten()
            },
            onFullLength: { [weak self] in
                DayPlanHabitDurations.clearOverride(for: habitId, on: day)
                DayPlanAnalytics.capture(DayPlanAnalytics.habitShortenCleared)
                addLog(text: "[user-action] day plan: habit restored to full length for \(DayPlanHabitDurations.dayKey(day))")
                self?.dismissDraftSheet(sheet)
                self?.reloadAfterShorten()
            },
            onCancel: { [weak self] in self?.dismissDraftSheet(sheet) })
        sheet = DayPlanSheetController(size: Self.shortenHabitSheetSize, content: view)
        presentAsSheet(sheet)
    }

    /// The trim changes every block after it, so the cached render signature has to be dropped before
    /// the day is laid out again (same as skipping a habit ahead). The 90-day forecast reuses its
    /// snapshot for fifteen minutes and only re-reads on this notification, so it has to be told too —
    /// a shortened habit really does free capacity on that day.
    private func reloadAfterShorten() {
        lastRenderSignature = nil
        NotificationCenter.default.post(name: DayPlanTaskStore.forecastSnapshotDidChange, object: nil)
        reload()
    }

    /// Tall enough for the presets, the typed-length row (with a validation line under it) and the
    /// two-line hint without scrolling in English; the sheet scrolls if a translation needs more.
    private static let shortenHabitSheetSize = NSSize(width: 430, height: 440)

    /// Opens this habit's own stats — current streak, completion heat map and a chart per log-quantity
    /// question — as a sheet, reusing the native Stats screen's components.
    private func openHabitStats(habitId: String) {
        guard #available(macOS 11.0, *), !habitId.isEmpty else { return }
        DayPlanAnalytics.capture(DayPlanAnalytics.habitStatsOpened)
        let store = SingleHabitStatsStore(habitId: habitId, fallbackTitle: habitDisplayTitle(habitId: habitId))
        var sheet: DayPlanSheetController!
        let view = SingleHabitStatsView(store: store, strings: StatsStrings.load(), onClose: { [weak self] in
            self?.dismissDraftSheet(sheet)
        })
        sheet = DayPlanSheetController(size: Self.habitStatsSheetSize, content: view)
        presentAsSheet(sheet)
    }

    private static let habitStatsSheetSize = NSSize(width: 720, height: 620)

    // MARK: - Editing habits / routine timing (DayPlanRoutineDraft)

    /// Opens the SwiftUI habit editor as a sheet. Saving applies the edit live (the arrays' didSet
    /// re-renders every Day Plan host) and parks it in the draft until "Save and restart app".
    private func openHabitEditor(habitId: String, authorized: Bool = false) {
        if requireSettingsPasswordIfNeeded(authorized: authorized, then: { [weak self] in
            self?.openHabitEditor(habitId: habitId, authorized: true)
        }) { return }
        guard #available(macOS 11.0, *) else { return }
        let draft = DayPlanRoutineDraft.shared
        guard let values = draft.habitEditValues(id: habitId), let section = draft.routineSection(forHabitId: habitId) else {
            showDraftAlert(title: ScheduleText.habitEditUnavailable, message: "")
            return
        }
        DayPlanAnalytics.capture(DayPlanAnalytics.habitEditOpened)
        let model = HabitEditModel(values: values, section: section, canDelete: currentHabitPlaying?.id != habitId)
        var sheet: DayPlanSheetController!
        let editor = HabitEditView(model: model, onSave: { [weak self] in
            draft.applyHabitEdit(id: habitId, values: model.values)
            DayPlanAnalytics.capture(DayPlanAnalytics.habitEdited)
            self?.dismissDraftSheet(sheet)
        }, onCancel: { [weak self] in
            self?.dismissDraftSheet(sheet)
        }, onDelete: { [weak self] in
            draft.applyHabitDelete(id: habitId)
            DayPlanAnalytics.capture(DayPlanAnalytics.habitDeleted)
            self?.selectedHabitIndex = nil   // the selected row no longer exists
            self?.selectedEditableHabitId = nil
            self?.dismissDraftSheet(sheet)
        })
        sheet = DayPlanSheetController(size: Self.habitEditorSheetSize, content: editor)
        presentAsSheet(sheet)
    }

    private static let habitEditorSheetSize = NSSize(width: 700, height: 600)

    /// The same editor in "new habit" mode (the routine menu's "Add new habit"): web defaults, no delete.
    /// Saving appends the habit to the routine in the draft — it shows in the Day Plan straight away.
    private func openNewHabitEditor(section: RoutineSettingsSection, authorized: Bool = false) {
        // Adding a habit IS editing habits — an ungated "Add new habit" would leave the password
        // guarding the front door while this one stood open.
        if requireSettingsPasswordIfNeeded(authorized: authorized, then: { [weak self] in
            self?.openNewHabitEditor(section: section, authorized: true)
        }) { return }
        guard #available(macOS 11.0, *) else { return }
        let draft = DayPlanRoutineDraft.shared
        DayPlanAnalytics.capture(DayPlanAnalytics.habitAddOpened)
        let model = HabitEditModel(values: HabitEditValues.newHabit(in: section), section: section, canDelete: false, isNew: true)
        var sheet: DayPlanSheetController!
        let editor = HabitEditView(model: model, onSave: { [weak self] in
            if draft.applyHabitAdd(routine: section, values: model.values) != nil {
                DayPlanAnalytics.capture(DayPlanAnalytics.habitAdded)
            } else {
                self?.showDraftAlert(title: ScheduleText.habitEditUnavailable, message: "")
            }
            self?.dismissDraftSheet(sheet)
        }, onCancel: { [weak self] in
            self?.dismissDraftSheet(sheet)
        })
        sheet = DayPlanSheetController(size: Self.habitEditorSheetSize, content: editor)
        presentAsSheet(sheet)
    }

    /// "When do you want <routine> to start?" — a time picker sheet for the routine's start time.
    /// Ask for the settings password before a routine edit, when the settings rule says to.
    ///
    /// Routine timing already did this; editing a HABIT and managing CUSTOM ROUTINES did not, so the
    /// same password that guards Settings could be walked straight around from the Day Plan
    /// (report 2026-09-22_21-41-33). The rule itself is `isPasswordRequireInOpenSettings()` — which
    /// already covers "after cutoff", "super-strict session" and "always" — so this deliberately
    /// adds no policy of its own; it only puts the existing gate in front of two more doors.
    ///
    /// Returns true when the caller should stop and wait: the sheet is up, and `authorized` runs
    /// only if the password is accepted.
    private func requireSettingsPasswordIfNeeded(authorized alreadyAuthorized: Bool,
                                                 then authorized: @escaping () -> Void) -> Bool {
        guard !alreadyAuthorized, isPasswordRequireInOpenSettings() else { return false }
        guard let main = mainViewControllerObj else {
            // No way to ask means no way to verify. Refusing is the safe direction — silently
            // allowing the edit is the hole the password exists to close.
            addLog(text: "routine edit: cannot present the password view, refusing")
            return true
        }
        main.askPasswordForSettings()
        getEnterPasswordVcObjForPreferences().requestAuthorization(action: authorized, onCancel: {})
        return true
    }

    private func openRoutineTimingEditor(section: RoutineSettingsSection, authorized: Bool = false) {
        if requireSettingsPasswordIfNeeded(authorized: authorized, then: { [weak self] in
            self?.openRoutineTimingEditor(section: section, authorized: true)
        }) { return }
        guard #available(macOS 11.0, *) else { return }
        let draft = DayPlanRoutineDraft.shared
        var sheet: DayPlanSheetController!
        let account = appdelegate?.user?.userId ?? ""
        let cutoff = draft.eveningCutoffMinutes()
        let picker = RoutineTimingView(routineName: draft.routineDisplayName(section),
                                       minutes: draft.routineStartMinutes(section) ?? 7 * 60,
                                       showsCutoff: section == .evening,
                                       cutoffEnabled: cutoff != nil,
                                       cutoffMinutes: cutoff ?? draft.routineStartMinutes(section) ?? 21 * 60,
                                       morningStartMinutes: draft.routineStartMinutes(.morning),
                                       onSave: { [weak self] minutes, cutoff in
            guard !account.isEmpty, appdelegate?.user?.userId == account,
                  draft.applyRoutineTiming(section, minutes: minutes, eveningCutoffMinutes: cutoff) else {
                self?.showDraftAlert(title: ScheduleText.habitEditUnavailable, message: "")
                self?.dismissDraftSheet(sheet)
                return
            }
            DayPlanAnalytics.capture(DayPlanAnalytics.routineTimingEdited)
            self?.dismissDraftSheet(sheet)
        }, onCancel: { [weak self] in
            self?.dismissDraftSheet(sheet)
        })
        sheet = DayPlanSheetController(size: NSSize(width: 420, height: section == .evening ? 380 : 210), content: picker)
        presentAsSheet(sheet)
    }

    /// The custom-routine manager: list every custom routine, create one, edit or delete one, and add /
    /// remove / reorder its habits. Reuses the same draft store (and the same habit editor) as the
    /// Day Plan's habit editing, so nothing is written to the server until "Save and restart app".
    private func openCustomRoutineManager(sequenceId: String? = nil, authorized: Bool = false) {
        if requireSettingsPasswordIfNeeded(authorized: authorized, then: { [weak self] in
            self?.openCustomRoutineManager(sequenceId: sequenceId, authorized: true)
        }) { return }
        guard #available(macOS 11.0, *) else { return }
        DayPlanAnalytics.capture(DayPlanAnalytics.customRoutineManagerOpened)
        let model = CustomRoutineManagerModel()
        if let sequenceId = sequenceId, let routine = model.routines.first(where: { $0.id == sequenceId }) {
            model.startEditing(routine)
        }
        var sheet: DayPlanSheetController!
        let manager = CustomRoutineManagerView(model: model, onClose: { [weak self] in
            self?.dismissDraftSheet(sheet)
        })
        sheet = DayPlanSheetController(size: Self.customRoutineManagerSheetSize, content: manager)
        presentAsSheet(sheet)
    }

    private static let customRoutineManagerSheetSize = NSSize(width: 620, height: 560)

    @objc private func editCustomRoutineClicked(_ item: NSMenuItem) {
        guard case .custom(let sequenceId)? = (item.representedObject as? RoutineMenuButton)?.section else { return }
        openCustomRoutineManager(sequenceId: sequenceId)
    }

    private func dismissDraftSheet(_ sheet: NSViewController?) {
        if let sheet = sheet { dismiss(sheet) }
        // Force a re-render: a timing-only edit doesn't change the arrays, and the banner keys off the draft.
        lastRenderSignature = nil
        reload()
    }

    /// Show/clear the sticky banner to match the draft state. Called from every render (the draft flag is
    /// part of the render signature) and directly after a save attempt.
    private func updateDraftBanner() {
        draftBannerContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard DayPlanRoutineDraft.shared.hasChanges else { return }
        let banner = makeDraftBanner()
        draftBannerContainer.addArrangedSubview(banner)
        draftBannerContainer.setCustomSpacing(6, after: banner)
    }

    /// "Routine changes drafted: ready to save?" + the Save-and-restart button (see updateDraftBanner).
    private func makeDraftBanner() -> NSView {
        let label = makeLabel("✏️ " + ScheduleText.draftBanner, size: 12, bold: true)
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let save = cursorButton(title: DayPlanRoutineDraft.shared.isSaving ? ScheduleText.draftSaving : ScheduleText.draftSaveRestart,
                                target: self, action: #selector(saveDraftAndRestartClicked(_:)))
        save.bezelStyle = .rounded
        save.isEnabled = !DayPlanRoutineDraft.shared.isSaving
        save.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [label, save])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        return styledCard(fill: NSColor.systemOrange.withAlphaComponent(0.12),
                          border: NSColor.systemOrange.withAlphaComponent(0.6),
                          hasBorder: true, content: row)
    }

    @objc private func saveDraftAndRestartClicked(_ sender: NSButton) {
        sender.isEnabled = false
        sender.title = ScheduleText.draftSaving
        DayPlanRoutineDraft.shared.saveAndRestart { [weak self] statusCode, serverMessage in
            guard let self = self else { return }
            self.updateDraftBanner()   // re-enable the button; the draft is still pending
            var message = String(format: ScheduleText.draftSaveFailedMessage, statusCode)
            if let serverMessage = serverMessage, !serverMessage.isEmpty {
                message += "\n\n\(ScheduleText.draftSaveFailedServerSaid)\n\(serverMessage)"
            }
            self.showDraftAlert(title: ScheduleText.draftSaveFailedTitle, message: message)
        }
    }

    private func showDraftAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: ScheduleText.draftSaveFailedOk)
        if let window = view.window { alert.beginSheetModal(for: window) } else { alert.runModal() }
    }

    private func scheduleReload(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.reload() }
    }

    @objc private func dismissMeetingClicked(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue else { return }
        if raw.hasPrefix("undismiss:") {
            let eventId = String(raw.dropFirst("undismiss:".count))
            // Force a re-render: with "Show dismissed events" on, un-dismissing keeps the meeting in the
            // list at the same position, so the render signature wouldn't change and reload() would
            // no-op (the event would stay struck through). Same reset the settings toggles use.
            lastRenderSignature = nil
            CalendarManager.shared.restoreDismissedEvent(id: eventId, forDay: selectedDate)
            DayPlanSync.shared.undismissEvent(eventID: eventId, on: selectedDate)   // mirror to backend (cross-device)
            reload()
        } else if raw.hasPrefix("dismiss:") {
            let eventId = String(raw.dropFirst("dismiss:".count))
            // A recurring event's eventIdentifier is the SAME across every occurrence (verified against
            // live EventKit data), so dismissing it outright hides the whole series — ask which the user
            // means instead of silently doing that. A one-off event has no series to ask about.
            guard let event = CalendarManager.shared.event(withID: eventId), event.hasRecurrenceRules else {
                dismissMeeting(eventId: eventId, seriesWide: true)
                return
            }
            showDismissRepeatingConfirm(eventId: eventId, anchor: sender)
        }
    }

    /// "Just this one" / "All events in series" / "Cancel" — shown from a recurring event's ✕, anchored
    /// to the button that was clicked (same NSPopover pattern DayPlanTasksPanel uses for its own
    /// transient confirmations, e.g. the task-details modal).
    private func showDismissRepeatingConfirm(eventId: String, anchor: NSButton) {
        let title = makeLabel(ScheduleText.dismissRepeatingTitle, size: 13, bold: true)
        let info = makeLabel(ScheduleText.dismissRepeatingInfo, size: 12, bold: false)
        info.textColor = .secondaryLabelColor
        info.lineBreakMode = .byWordWrapping
        info.maximumNumberOfLines = 0
        info.preferredMaxLayoutWidth = 260
        info.widthAnchor.constraint(lessThanOrEqualToConstant: 260).isActive = true

        // boxButton, not the app Button class: it sets up its layer/background in init(frame:), so it
        // draws correctly when created programmatically (Button only styles from awakeFromNib, which
        // doesn't run here — leaving it with no background).
        let justThisOne = boxButton(frame: .zero)   // primary (orange) — the default/expected choice
        justThisOne.setTitle(ScheduleText.dismissRepeatingJustThisOne)
        justThisOne.target = self; justThisOne.action = #selector(dismissRepeatingJustThisOneClicked)
        justThisOne.setButtonColor(NSColor(named: "dark_OrangeColor") ?? .orange)
        justThisOne.borderColor = NSColor(named: "dark_OrangeColor") ?? .orange
        justThisOne.setTitleColor(.white)
        justThisOne.iconView.isHidden = true
        let allSeries = boxButton(frame: .zero)     // secondary (white bg, gray border, black title) by default
        allSeries.setTitle(ScheduleText.dismissRepeatingAllSeries)
        allSeries.target = self; allSeries.action = #selector(dismissRepeatingAllSeriesClicked)
        allSeries.iconView.isHidden = true
        
        let cancel = boxButton(frame: .zero)        // same secondary style as "All events in series"
        cancel.setTitle(ScheduleText.dismissRepeatingCancel)
        cancel.target = self; cancel.action = #selector(dismissRepeatingCancelClicked)
        cancel.iconView.isHidden = true
        for b in [justThisOne, allSeries, cancel] { b.translatesAutoresizingMaskIntoConstraints = false }

        let stack = NSStackView(views: [title, info, justThisOne, allSeries, cancel])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        justThisOne.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        allSeries.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        // boxButton centres its content and doesn't self-size vertically, so give it an explicit height.
        cancel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        justThisOne.heightAnchor.constraint(equalToConstant: 32).isActive = true
        allSeries.heightAnchor.constraint(equalToConstant: 32).isActive = true
        cancel.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        let vc = NSViewController(); vc.view = container
        let pop = NSPopover(); pop.contentViewController = vc; pop.behavior = .transient
        pendingDismissEventId = eventId
        pop.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        dismissRepeatingPopover = pop
    }

    /// The recurring event a dismiss-repeating popover is currently asking about — set right before
    /// showing it, read by whichever of the three button actions the user clicks.
    private var pendingDismissEventId: String?

    @objc private func dismissRepeatingJustThisOneClicked() {
        dismissRepeatingPopover?.close()
        guard let eventId = pendingDismissEventId else { return }
        dismissMeeting(eventId: eventId, seriesWide: false)
    }

    @objc private func dismissRepeatingAllSeriesClicked() {
        dismissRepeatingPopover?.close()
        guard let eventId = pendingDismissEventId else { return }
        dismissMeeting(eventId: eventId, seriesWide: true)
    }

    @objc private func dismissRepeatingCancelClicked() {
        dismissRepeatingPopover?.close()
        pendingDismissEventId = nil
    }

    /// Shared by both the recurring-event confirmation and the direct (non-recurring) dismiss path.
    private func dismissMeeting(eventId: String, seriesWide: Bool) {
        pendingDismissEventId = nil
        DayPlanAnalytics.capture(DayPlanAnalytics.eventRemoved, ["series_wide": seriesWide])
        // Force a re-render — see the matching comment in dismissMeetingClicked's undismiss path.
        lastRenderSignature = nil
        if seriesWide {
            CalendarManager.shared.dismissEvent(id: eventId)
        } else {
            CalendarManager.shared.dismissEvent(id: eventId, forDay: selectedDate)
        }
        DayPlanSync.shared.dismissEvent(eventID: eventId, on: selectedDate)   // mirror to backend (cross-device)
        reload()
    }

    // MARK: - Calendar permission banner

    private func makeCalendarBanner() -> NSView {
        let label = makeLabel("⚠️ " + ScheduleText.calendarBanner,
                              size: 12, bold: false)
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let grant = cursorButton(title: ScheduleText.grantAccess, target: self, action: #selector(grantCalendarClicked))
        grant.bezelStyle = .rounded
        grant.translatesAutoresizingMaskIntoConstraints = false

        let dismiss = cursorButton(title: "✕", target: self, action: #selector(dismissBannerClicked))
        dismiss.bezelStyle = .circular
        dismiss.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView(views: [label, grant, dismiss])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        let card = styledCard(fill: NSColor.systemYellow.withAlphaComponent(0.12),
                              border: NSColor.systemYellow.withAlphaComponent(0.6),
                              hasBorder: true, content: row)
        bannerBox = card
        return card
    }

    @objc private func grantCalendarClicked() {
        switch CalendarManager.shared.access {
        case .authorized:
            reloadOrExplainNoCalendars()
        case .notDetermined:
            // First-time ask: show the system (TCC) prompt. It can't appear over Focus Bear's
            // borderless full-screen cover window, so drop full-screen (with a countdown) first.
            if mainWindowControllerObj?.isFullScreenVisible ?? false {
                beginFullScreenCalendarGrant()
            } else {
                NSApplication.shared.activate(ignoringOtherApps: true)   // make sure the prompt is frontmost
                CalendarManager.shared.requestAccess { [weak self] _ in
                    DispatchQueue.main.async { self?.reloadOrExplainNoCalendars() }
                }
            }
        case .denied:
            // macOS won't re-prompt once access was denied/dismissed — the only way to grant is in
            // System Settings, so take the user straight there.
            openSystemCalendarSettings()
        }
    }

    /// Refresh the schedule after we (may) have access — but if the user is authorized yet has no
    /// calendars at all, the schedule would silently stay empty, so explain that instead of leaving
    /// the "Connect calendar" click looking like a no-op (issue #2115).
    private func reloadOrExplainNoCalendars() {
        if CalendarManager.shared.access == .authorized && !CalendarManager.shared.hasAnyCalendars() {
            showNoCalendarsInfo()
            return
        }
        reload()
    }

    /// Tell the user Focus Bear has calendar access but the Mac has no calendars, and offer to open
    /// the settings where a calendar account is added.
    private func showNoCalendarsInfo() {
        guard let window = view.window else { NSSound.beep(); return }
        let alert = NSAlert()
        alert.messageText = ScheduleText.noCalendarsTitle
        alert.informativeText = ScheduleText.noCalendarsMessage
        alert.addButton(withTitle: ScheduleText.noCalendarsOpenSettings)   // first button → .alertFirstButtonReturn
        alert.addButton(withTitle: ScheduleText.noCalendarsDismiss)
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            self?.openInternetAccountsSettings()
        }
    }

    private func openSystemCalendarSettings() {
        openReachableExternalWindow {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// System Settings › Internet Accounts — where the user adds a calendar account (iCloud, Google, …).
    private func openInternetAccountsSettings() {
        openReachableExternalWindow {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.internetaccounts") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// Run `open` (which surfaces another app's window, e.g. System Settings) with any elevated Focus
    /// Bear windows temporarily dropped to normal level. Focus Bear's window can sit at an elevated
    /// level (floating during routines, or the borderless full-screen cover), which floats above other
    /// apps' windows too — so the window we open would otherwise appear *behind* ours and be
    /// unreachable. Levels are restored once the user returns to Focus Bear (these opens have no
    /// completion callback, so we restore on app reactivation).
    private func openReachableExternalWindow(_ open: () -> Void) {
        let elevated = NSApp.windows.filter { $0.level.rawValue > NSWindow.Level.normal.rawValue }
        if !elevated.isEmpty {
            let savedLevels = elevated.map { (window: $0, level: $0.level) }
            elevated.forEach { $0.level = .normal }
            var token: NSObjectProtocol?
            token = NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
                savedLevels.forEach { $0.window.level = $0.level }
                if let token = token { NotificationCenter.default.removeObserver(token) }
            }
        }
        open()
    }

    // MARK: - Add tasks from the to-do list

    private func showTodoPicker() {
        todoSelectedIDs.removeAll(); todoSearch = ""; todoProjectFilterID = nil; todoAllTasks = []

        let title = makeLabel(ScheduleText.tasksAddFromList, size: 14, bold: true)

        let search = NSSearchField()
        search.placeholderString = ScheduleText.tasksSearchPlaceholder
        search.target = self; search.action = #selector(todoSearchChanged(_:))
        search.translatesAutoresizingMaskIntoConstraints = false
        search.widthAnchor.constraint(equalToConstant: 300).isActive = true

        let projectPopup = NSPopUpButton()
        projectPopup.addItem(withTitle: ScheduleText.tasksAllProjects)
        todoProjectIDs = [""]
        for tag in arrAllFocusModeTags {
            if let id = tag["id"], let text = tag["text"] { projectPopup.addItem(withTitle: text); todoProjectIDs.append(id) }
        }
        projectPopup.target = self; projectPopup.action = #selector(todoProjectChanged(_:))
        projectPopup.translatesAutoresizingMaskIntoConstraints = false

        let listStack = NSStackView()
        listStack.orientation = .vertical; listStack.alignment = .leading; listStack.spacing = 4
        listStack.translatesAutoresizingMaskIntoConstraints = false
        todoListStack = listStack

        let listClip = FlippedClipView(); listClip.drawsBackground = false
        let listScroll = NSScrollView()
        listScroll.contentView = listClip
        listScroll.hasVerticalScroller = true
        listScroll.drawsBackground = false
        listScroll.documentView = listStack
        listScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listScroll.heightAnchor.constraint(equalToConstant: 260),
            listScroll.widthAnchor.constraint(equalToConstant: 300),
            listStack.topAnchor.constraint(equalTo: listClip.topAnchor),
            listStack.leadingAnchor.constraint(equalTo: listClip.leadingAnchor),
            listStack.trailingAnchor.constraint(equalTo: listClip.trailingAnchor),
            listStack.widthAnchor.constraint(equalTo: listClip.widthAnchor),
        ])

        let cancel = cursorButton(title: ScheduleText.eventCancel, target: self, action: #selector(closeTodoPicker))
        cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"
        let add = cursorButton(title: ScheduleText.tasksAddSelected, target: self, action: #selector(addSelectedTodos))
        add.bezelStyle = .rounded; add.keyEquivalent = "\r"
        let buttons = NSStackView(views: [NSView(), cancel, add])
        buttons.orientation = .horizontal; buttons.spacing = 8

        let form = NSStackView(views: [title, search, projectPopup, listScroll, buttons])
        form.orientation = .vertical; form.alignment = .leading; form.spacing = 10
        form.translatesAutoresizingMaskIntoConstraints = false
        buttons.widthAnchor.constraint(equalTo: search.widthAnchor).isActive = true

        let container = NSView()
        container.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            form.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        let vc = NSViewController(); vc.view = container
        let pop = NSPopover(); pop.contentViewController = vc; pop.behavior = .transient
        pop.show(relativeTo: tasksPanel.bounds, of: tasksPanel, preferredEdge: .minX)
        todoPopover = pop

        rebuildTodoList()
        // SMART = the backend's TOP-score priority order; the endpoint also filters to NOT_STARTED.
        allApiObject.getSmartTasks { [weak self] result in
            DispatchQueue.main.async {
                self?.todoAllTasks = result ?? []
                self?.rebuildTodoList()
            }
        }
    }

    private func rebuildTodoList() {
        guard let stack = todoListStack else { return }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let filtered = todoAllTasks.filter { task in
            let title = (task.value(forKey: "title") as? String) ?? ""
            let id = (task.value(forKey: "id") as? String) ?? ""
            let titleOK = todoSearch.isEmpty || title.localizedCaseInsensitiveContains(todoSearch)
            let projOK: Bool
            if let pid = todoProjectFilterID, !pid.isEmpty {
                let tags = (task.value(forKey: "tags") as? [[String: String]]) ?? []
                projOK = tags.contains { $0["id"] == pid }
            } else { projOK = true }
            let notAdded = !DayPlanTaskStore.shared.contains(sourceTaskId: id, for: selectedDate)
            return titleOK && projOK && notAdded
        }
        // No client-side re-sort: the server already returns SMART (TOP-score) order; `.filter`
        // preserves it.
        if filtered.isEmpty {
            let empty = makeLabel(todoAllTasks.isEmpty ? "…" : ScheduleText.tasksEmpty, size: 12, bold: false)
            empty.textColor = .secondaryLabelColor
            stack.addArrangedSubview(empty)
            return
        }
        for task in filtered {
            let id = (task.value(forKey: "id") as? String) ?? ""
            let title = (task.value(forKey: "title") as? String) ?? ""
            let check = cursorButton(checkboxWithTitle: title, target: self, action: #selector(todoRowToggled(_:)))
            check.state = todoSelectedIDs.contains(id) ? .on : .off
            check.identifier = NSUserInterfaceItemIdentifier(id)
            stack.addArrangedSubview(check)
        }
    }

    @objc private func todoSearchChanged(_ s: NSSearchField) {
        todoSearch = s.stringValue
        rebuildTodoList()            // instant: filter the cached SMART list
        scheduleTodoApiSearch()      // fallback: search the full to-do list on the backend
    }

    /// The cached SMART list only holds ~50 tasks, so searching for one further down finds nothing
    /// locally. Debounce a backend title search (GET /to-do/search) and merge its results into the list.
    private func scheduleTodoApiSearch() {
        todoSearchWorkItem?.cancel()
        let query = todoSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { return }
        let work = DispatchWorkItem { [weak self] in
            allApiObject.searchToDos(title: query) { results in
                DispatchQueue.main.async {
                    guard let self = self,
                          self.todoSearch.trimmingCharacters(in: .whitespacesAndNewlines) == query,  // still the current query
                          let results = results, !results.isEmpty else { return }
                    let existingIDs = Set(self.todoAllTasks.compactMap { $0.value(forKey: "id") as? String })
                    let fresh = results.filter { r in (r.value(forKey: "id") as? String).map { !existingIDs.contains($0) } ?? false }
                    guard !fresh.isEmpty else { return }
                    self.todoAllTasks.append(contentsOf: fresh)
                    self.rebuildTodoList()
                }
            }
        }
        todoSearchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }
    @objc private func todoProjectChanged(_ p: NSPopUpButton) {
        let idx = p.indexOfSelectedItem
        todoProjectFilterID = todoProjectIDs.indices.contains(idx) ? todoProjectIDs[idx] : nil
        rebuildTodoList()
    }
    @objc private func todoRowToggled(_ b: NSButton) {
        guard let id = b.identifier?.rawValue else { return }
        if b.state == .on { todoSelectedIDs.insert(id) } else { todoSelectedIDs.remove(id) }
    }
    @objc private func closeTodoPicker() { todoPopover?.close(); todoPopover = nil }
    @objc private func addSelectedTodos() {
        var addedCount = 0
        for task in todoAllTasks {
            let id = (task.value(forKey: "id") as? String) ?? ""
            guard todoSelectedIDs.contains(id) else { continue }
            let title = (task.value(forKey: "title") as? String) ?? "Task"
            // Use the to-do's own estimated duration (seconds) if set, else a 15-minute default.
            let minutes = TodoFieldParsing.durationMinutes(task.value(forKey: "duration"))
            // Group imported tasks under their to-do's project (`project_id`, else its first tag) and
            // record the link so the repair pass knows this one is already on the backend.
            let fields = TodoProjectFields(todo: task)
            let project = DayPlanTaskStore.shared.projectName(for: fields)
            // Capture the to-do's Eisenhower quadrant so completion/planning can round-trip through
            // the `PUT /to-do` upsert (which requires it) without clobbering it.
            let quadrant = (task.value(forKey: "eisenhower_quadrant") as? Int)
            DayPlanTaskStore.shared.add(DayPlanTask(title: title, durationMinutes: minutes, sourceTaskId: id,
                                                    project: project, eisenhowerQuadrant: quadrant,
                                                    projectID: fields.projectID, tags: fields.tags,
                                                    hasSyncedExternalProject: fields.hasSyncedExternalProject),
                                        for: selectedDate)
            addedCount += 1
        }
        // Adding from the to-do list is a task-added action too (the scratch add already captures this);
        // fire one event with the count so the metric covers both entry points, segmented by source.
        if addedCount > 0 {
            DayPlanAnalytics.capture(DayPlanAnalytics.taskAdded, ["source": "todo_list", "count": addedCount])
        }
        closeTodoPicker()
        tasksPanel.reload()
    }

    private func beginFullScreenCalendarGrant() {
        mainWindowControllerObj?.showSmallSizeWindow()
        // The system calendar (TCC) dialog kept appearing *behind* the Focus Bear window. Order
        // the main window out entirely for the duration so the prompt is unobstructed on the
        // desktop; the countdown popup (top of screen) explains what's happening. The window is
        // restored in endFullScreenCalendarGrant().
        mainWindowControllerObj?.window?.orderOut(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        showGrantCountdown(seconds: 30)
        CalendarManager.shared.requestAccess { [weak self] granted in
            DispatchQueue.main.async {
                self?.endFullScreenCalendarGrant()           // restore full-screen as soon as answered
                self?.reloadOrExplainNoCalendars()
            }
        }
    }

    private func showGrantCountdown(seconds: Int) {
        grantSecondsLeft = seconds
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 120),
                           styleMask: [.borderless], backing: .buffered, defer: false)
        win.level = .modalPanel
        win.isReleasedWhenClosed = false
        win.backgroundColor = .windowBackgroundColor
        win.hasShadow = true

        let title = makeLabel(ScheduleText.removingFullScreen, size: 14, bold: true)
        title.alignment = .center
        title.lineBreakMode = .byWordWrapping
        title.maximumNumberOfLines = 2
        let count = makeLabel("", size: 22, bold: true)
        count.alignment = .center
        count.textColor = .systemOrange
        grantCountdownLabel = count

        let stack = NSStackView(views: [title, count])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])
        win.contentView = content
        // Sit near the top of the screen so the popup doesn't cover the centered TCC prompt.
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            win.setFrameOrigin(NSPoint(x: f.midX - 210, y: f.maxY - 140))
        } else {
            win.center()
        }
        win.orderFrontRegardless()
        grantCountdownWindow = win
        updateGrantCountdownLabel()

        grantCountdownTimer?.invalidate()
        grantCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.grantSecondsLeft -= 1
            self.updateGrantCountdownLabel()
            if self.grantSecondsLeft <= 0 { self.endFullScreenCalendarGrant() }
        }
        if let t = grantCountdownTimer { RunLoop.main.add(t, forMode: .common) }
    }

    private func updateGrantCountdownLabel() {
        grantCountdownLabel?.stringValue = "\(max(grantSecondsLeft, 0))s"
    }

    private func endFullScreenCalendarGrant() {
        grantCountdownTimer?.invalidate()
        grantCountdownTimer = nil
        grantCountdownWindow?.close()
        grantCountdownWindow = nil
        // Restore full-screen if the focus/habit session that needs it is still active.
        if checkIsFullScreenEnabled() {
            mainWindowControllerObj?.showFullSizeWindow()
            // showFullSizeWindow() only flips the style/flags — it doesn't re-cover the screen,
            // so the window would stay wherever it was dragged while small. Snap it back to fill
            // its screen.
            if let win = mainWindowControllerObj?.window, let screen = win.screen ?? NSScreen.main {
                win.setFrame(NSMakeRect(NSMinX(screen.frame), NSMinY(screen.frame),
                                        NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
                win.orderFrontRegardless()
            }
        }
    }

    @objc private func dismissBannerClicked() {
        bannerDismissed = true
        reload()
    }

    // MARK: - Small helpers

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    /// A participant's RSVP status as a status glyph + human-readable word. The word is nil for
    /// statuses we don't surface (unknown / delegated / completed / in-process) — many calendar
    /// providers report `.unknown` when they don't expose RSVPs, and we'd rather show just the name
    /// than assert a status we don't actually have.
    private func participantStatusDisplay(_ status: EKParticipantStatus) -> (glyph: String, word: String?) {
        switch status {
        case .accepted:  return ("✅", ScheduleText.eventParticipantAccepted)
        case .declined:  return ("❌", ScheduleText.eventParticipantDeclined)
        case .tentative: return ("🟡", ScheduleText.eventParticipantTentative)
        case .pending:   return ("⚪️", ScheduleText.eventParticipantNoResponse)
        default:         return ("•", nil)
        }
    }

    /// Display name for a participant, falling back to the bare email when EventKit has no name.
    private func participantDisplayName(_ p: EKParticipant) -> String {
        if let n = p.name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty { return n }
        let s = p.url.absoluteString
        return s.hasPrefix("mailto:") ? String(s.dropFirst("mailto:".count)) : s
    }

    /// One wrapping row in the Edit-event participants list: "<glyph> <name> · <status>".
    private func makeParticipantRow(_ p: EKParticipant) -> NSView {
        let (glyph, word) = participantStatusDisplay(p.participantStatus)
        let name = participantDisplayName(p)
        let text = word.map { "\(glyph) \(name) · \($0)" } ?? "\(glyph) \(name)"
        let label = makeLabel(text, size: 13, bold: false)
        label.usesSingleLineMode = false
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = 300
        label.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
        return label
    }

    /// A time-range label with a fixed width and monospaced digits, so every row's emoji and
    /// name line up in one straight column regardless of the exact digits in the time.
    private func makeTimeLabel(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabelColor
        l.alignment = .left
        l.lineBreakMode = .byClipping
        l.translatesAutoresizingMaskIntoConstraints = false
        // Wide enough for "12:02 pm–12:27 pm" so it never truncates; a hard fixed width keeps
        // every row's emoji column starting at the same x.
        l.widthAnchor.constraint(equalToConstant: 140).isActive = true
        return l
    }

    /// Splits a "🛏 Make bed" title into its leading emoji and the rest, so the emoji can be
    /// rendered at a larger size than the text.
    private func splitTitle(_ title: String) -> (emoji: String, text: String) {
        // Skip any leading whitespace, then peel off a run of emoji/symbol characters whether or
        // not a space follows. Habit names arrive in several shapes — "🖥️Check VMs" (no space),
        // " 🗒️ Review day plan" (leading space), "📝 Break down…" — all of which a naive split
        // would mishandle, leaving the emoji glued into the title and pushing that row right.
        var idx = title.startIndex
        while idx < title.endIndex, title[idx].isWhitespace { idx = title.index(after: idx) }
        var emoji = ""
        while idx < title.endIndex {
            let ch = title[idx]
            if ch.isWhitespace { break }
            guard ch.isEmojiLike else { break }
            emoji.append(ch)
            idx = title.index(after: idx)
        }
        let rest = String(title[idx...]).trimmingCharacters(in: .whitespaces)
        if !emoji.isEmpty && !rest.isEmpty { return (emoji, rest) }
        return ("", title)
    }

    /// Fixed widths for the row columns. Rows are laid out with explicit leading constraints
    /// (not a stack) using these, so every title starts at exactly the same x.
    private static let timeColWidth: CGFloat = 140
    private static let emojiColWidth: CGFloat = 26
    private static let colGap: CGFloat = 8

    /// Builds [emoji?, title] labels for a block title. The emoji is a fixed-width label whose
    /// width can't be overridden (compression resistance is lowered so the width constraint
    /// always wins), keeping the title column aligned across all rows.
    private func titleLabels(_ title: String, textSize: CGFloat, bold: Bool) -> (emoji: NSTextField?, text: NSTextField) {
        let (emoji, text) = splitTitle(title)
        let textLabel = WrappingScheduleLabel(labelWithString: emoji.isEmpty ? title : text)
        textLabel.font = bold ? .boldSystemFont(ofSize: textSize) : .systemFont(ofSize: textSize)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        // A long event/habit title must never force the card (and the whole window) wider than the
        // column — wrap up to 2 lines, then truncate, and never resist horizontal compression.
        textLabel.usesSingleLineMode = false
        textLabel.cell?.wraps = true
        textLabel.cell?.isScrollable = false
        textLabel.maximumNumberOfLines = 2
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        guard !emoji.isEmpty else { return (nil, textLabel) }
        let emojiLabel = makeLabel(emoji, size: textSize, bold: false)
        emojiLabel.alignment = .left
        emojiLabel.lineBreakMode = .byClipping
        emojiLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        emojiLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        emojiLabel.widthAnchor.constraint(equalToConstant: Self.emojiColWidth).isActive = true
        return (emojiLabel, textLabel)
    }

    /// Lays the [time | emoji | title] columns into `container` at fixed x-positions via explicit
    /// leading constraints, so the title column is pixel-identical on every row. Returns the
    /// title label (caller can recolour) and the title's trailing anchor (for accessories).
    @discardableResult
    private func layoutColumns(in container: NSView, time: String, title: String,
                               leadingInset: CGFloat, vPad: CGFloat,
                               timeColor: NSColor, titleColor: NSColor) -> (title: NSTextField, trailing: NSLayoutXAxisAnchor) {
        let timeLabel = makeTimeLabel(time); timeLabel.textColor = timeColor
        let (emojiLabel, titleLabel) = titleLabels(title, textSize: 16, bold: false)
        titleLabel.textColor = titleColor
        for v in [timeLabel, emojiLabel, titleLabel].compactMap({ $0 }) { container.addSubview(v) }

        // The title has no intrinsic width of its own (WrappingScheduleLabel deliberately reports
        // none, so it can wrap to whatever width it's given) and nothing else pins its trailing edge
        // to a specific point — only the `<=` cap below. That leaves its width genuinely ambiguous to
        // Auto Layout: any value from 0 up to the cap satisfies every required constraint equally, so
        // the solver is free to (and sometimes does) settle on ~0. A low-priority pull to the same
        // trailing point makes "fill the available width" the preferred solution while still losing to
        // a subtitle/duration label added after this call: its content-compression-resistance is
        // explicitly set to .defaultLow (250, see makeCard) precisely so it can shrink to make room for
        // the title, so this pull must stay below that — otherwise it wins the trade-off instead and
        // the subtitle collapses to zero width.
        let preferFullWidth = titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        preferFullWidth.priority = NSLayoutConstraint.Priority(200)
        var cons: [NSLayoutConstraint] = [
            timeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leadingInset),
            timeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: vPad),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -vPad),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8),
            preferFullWidth,
        ]
        if let emojiLabel = emojiLabel {
            cons += [
                emojiLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: Self.colGap),
                emojiLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: Self.colGap),
            ]
        } else {
            // No emoji — keep the title in the same column anyway.
            cons.append(titleLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor,
                                                            constant: Self.colGap + Self.emojiColWidth + Self.colGap))
        }
        NSLayoutConstraint.activate(cons)
        return (titleLabel, titleLabel.trailingAnchor)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        // Zero-pad the hour ("hh") so every time is the same width (e.g. "01:01 pm", not
        // "1:01 pm"), keeping the start/dash/end columns aligned across rows.
        f.dateFormat = "hh:mm a"
        f.amSymbol = "am"; f.pmSymbol = "pm"
        return f.string(from: date)
    }

    private func durationString(_ seconds: Int) -> String { HabitDurationText.short(seconds: seconds) }
}

extension scheduleViewController: NSTextViewDelegate {

    /// A link in an event description opens only if it is http(s). The description is markup from
    /// whoever sent the invite, so a `javascript:` or `file:` href must not be actionable — the
    /// renderer already refuses to attach one, and this is the second gate in case a link ever
    /// reaches the text view another way. Returning true in both branches means "handled", so AppKit
    /// never falls back to opening it itself.
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        let href = (link as? URL)?.absoluteString ?? (link as? String) ?? ""
        guard let url = EventDescriptionHTML.openableURL(from: href) else { return true }
        NSWorkspace.shared.open(url)
        return true
    }
}

extension scheduleViewController: NSGestureRecognizerDelegate {
    /// Don't let the meeting card's edit gesture fire when the click is on the ✕ (dismiss) button —
    /// let the button handle its own click instead.
    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        guard let card = gestureRecognizer.view, let xBtn = dismissButton(in: card) else { return true }
        let pointInButton = xBtn.convert(event.locationInWindow, from: nil)
        return !xBtn.bounds.contains(pointInButton)
    }
}

private extension Character {
    /// True for emoji / pictographic symbols (including those that need a U+FE0F variation
    /// selector to render in emoji form, e.g. 🖥️), but not plain ASCII digits/#/* — which
    /// Unicode also flags as `isEmoji`.
    var isEmojiLike: Bool {
        if unicodeScalars.contains(where: { $0.value == 0xFE0F }) { return true }
        return unicodeScalars.contains {
            $0.properties.isEmojiPresentation || ($0.properties.isEmoji && $0.value > 0x2600)
        }
    }
}


// MARK: - Allowed-activity habit: Habit Player | Day Plan tabs
//
// When the main window is open during an "allowed activity" habit (allowed apps / websites / focus
// mode — see habit.isAllowedActivityHabit), the player gains a top segmented control that swaps the
// pane between the Habit Player and the Day Plan, so the user can still see their schedule while the
// habit runs. For normal habits the control stays hidden and the player looks exactly as before.
// Built as an extension with associated objects so the storyboard + 1k-line timerViewcontroller
// stay untouched apart from one call in startTimerHabit.

private var tvcScheduleVCKey: UInt8 = 0
private var tvcSegmentKey: UInt8 = 0
private var tvcDayPlanBoxKey: UInt8 = 0

/// The allowed-activity player's two panes, in the order its segmented control lists them.
/// (Previously these were bare 0/1 literals spread across the tab code.)
enum AllowedActivityTab: Int {
    case habitPlayer = 0
    case dayPlan = 1
}

extension timerViewcontroller {

    private var allowedActivityScheduleVC: scheduleViewController? {
        get { objc_getAssociatedObject(self, &tvcScheduleVCKey) as? scheduleViewController }
        set { objc_setAssociatedObject(self, &tvcScheduleVCKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var allowedActivitySegment: NSSegmentedControl? {
        get { objc_getAssociatedObject(self, &tvcSegmentKey) as? NSSegmentedControl }
        set { objc_setAssociatedObject(self, &tvcSegmentKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    /// The full-pane Day Plan overlay (shown when the "Day Plan" segment is selected).
    private var allowedActivityDayPlanBox: NSView? {
        get { objc_getAssociatedObject(self, &tvcDayPlanBoxKey) as? NSView }
        set { objc_setAssociatedObject(self, &tvcDayPlanBoxKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Whether the allowed-activity player's embedded "Day Plan" tab is the visible pane. The habit
    /// player's time-of-day clock must be hidden then (it overlaps the Day Plan's tasks panel and the
    /// Day Plan 2has its own clock) — same as the other Day Plan hosts.
    var isAllowedActivityDayPlanFront: Bool {
        guard let seg = allowedActivitySegment, seg.superview?.isHidden == false else { return false }
        return seg.selectedSegment == AllowedActivityTab.dayPlan.rawValue
    }

    /// Whether the allowed-activity player's "Habit Player | Day Plan" tab bar is on screen, i.e.
    /// an allowed-app habit is the thing currently playing.
    var hasAllowedActivityTabs: Bool {
        allowedActivitySegment?.superview?.isHidden == false
    }

    /// Builds the segmented control + Day Plan overlay once, lazily. Idempotent.
    private func installAllowedActivityScheduleTabIfNeeded() {
        guard allowedActivitySegment == nil, let host = firstViewControllerObj else { return }

        // Day Plan overlay — its own schedule VC, driven by the habit screen's host data, covering
        // the whole player when the "Day Plan" segment is selected.
        let sched = scheduleViewController()
        addChild(sched)
        sched.host = host
        let plan = sched.view
        plan.translatesAutoresizingMaskIntoConstraints = false
        plan.wantsLayer = true
        // Resolve against the view's own appearance (window/app-theme), not NSApp's system one.
        plan.layer?.backgroundColor = sched.resolvedCGColor(.textBackgroundColor, in: plan)
        plan.isHidden = true
        view.addSubview(plan)
        NSLayoutConstraint.activate([
            plan.topAnchor.constraint(equalTo: view.topAnchor),
            plan.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            plan.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            plan.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        allowedActivityScheduleVC = sched
        allowedActivityDayPlanBox = plan
        // #2083: this overlay always sits under the "Habit Player | Day Plan" tab bar, so its
        // "+ Add event" button (top-right, level with the date bar) collides with the tabs. Drop it
        // a little so it clears them. Only this overlay instance is affected — the normal Day Plan
        // has no tab bar and keeps the button centred on the date bar (constant 0).
        sched.addEventCenterYConstraint?.constant = 13
        // Shift the date section (date + ◀ ▶ arrows) left so its right arrow clears the centred tabs
        // too (negative moves left). Overlay-only, like the drop above.
        sched.dateBarCenterXConstraint?.constant = -50

        // Segmented control sits in a top bar added LAST, so it stays on top of (and clickable over)
        // either pane.
        let seg = NSSegmentedControl(labels: [ScheduleText.habitPlayerTab, ScheduleText.dayPlanTab],
                                     trackingMode: .selectOne, target: self,
                                     action: #selector(allowedActivityTabChanged(_:)))
        seg.selectedSegment = AllowedActivityTab.habitPlayer.rawValue
        seg.translatesAutoresizingMaskIntoConstraints = false
        let bar = NSView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.isHidden = true
        view.addSubview(bar)
        bar.addSubview(seg)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            seg.topAnchor.constraint(equalTo: bar.topAnchor, constant: 6),
            seg.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -6),
            seg.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
        ])
        allowedActivitySegment = seg
    }

    /// Show the Habit Player | Day Plan tabs for allowed-activity habits; hide them (and reset to the
    /// plain player) for normal habits. Call from startTimerHabit with the habit being played.
    func updateAllowedActivityScheduleTab(for habit: habit?) {
        // A habit player is starting. The time-of-day clock is shown only in full screen while an
        // activity runs (refreshDateTimeClockVisibility) — sync it once the tab state below settles.
        let show = habit?.isAllowedActivityHabit ?? false
        if show { installAllowedActivityScheduleTabIfNeeded() }
        guard let seg = allowedActivitySegment else {            // plain player, no tabs built
            getHabitsVcObject().refreshDateTimeClockVisibility()
            return
        }
        seg.superview?.isHidden = !show                          // the top bar
        // Always reset to the player pane when (re)starting a habit.
        seg.selectedSegment = AllowedActivityTab.habitPlayer.rawValue
        allowedActivityDayPlanBox?.isHidden = true
        allowedActivityScheduleVC?.stopAutoRefresh()
        getHabitsVcObject().refreshDateTimeClockVisibility()
    }

    @objc private func allowedActivityTabChanged(_ sender: NSSegmentedControl) {
        let showDayPlan = sender.selectedSegment == AllowedActivityTab.dayPlan.rawValue
        allowedActivityDayPlanBox?.isHidden = !showDayPlan
        getHabitsVcObject().refreshDateTimeClockVisibility()    // clock hidden on the Day Plan tab
        if showDayPlan {
            allowedActivityScheduleVC?.reload()
            allowedActivityScheduleVC?.startAutoRefresh()
        } else {
            allowedActivityScheduleVC?.stopAutoRefresh()
        }
    }

    /// Switch the allowed-activity tabs back to the Habit Player pane. Called when the user taps a
    /// habit in the Day Plan that's already playing — switch tabs rather than restarting it.
    func showAllowedActivityPlayerTab() {
        guard let seg = allowedActivitySegment, seg.superview?.isHidden == false else { return }
        seg.selectedSegment = AllowedActivityTab.habitPlayer.rawValue
        allowedActivityDayPlanBox?.isHidden = true
        allowedActivityScheduleVC?.stopAutoRefresh()
        getHabitsVcObject().refreshDateTimeClockVisibility()
        mainWindowControllerObj?.window?.makeKeyAndOrderFront(nil)
    }

    /// Switch the allowed-activity tabs to the **Day Plan** pane — the counterpart to
    /// `showAllowedActivityPlayerTab()`, and what the menu's "View full day plan" needs during an
    /// allowed-app habit: the main window's Day Plan dispatch (`showDayPlanForCurrentState`)
    /// deliberately bails while a routine is live, so without this the user landed on the Habit
    /// Player tab instead (report 2026-06-25_18-11-05).
    /// - Returns: whether the Day Plan tab was actually shown (false when no tabs are on screen).
    @discardableResult
    func showAllowedActivityDayPlanTab() -> Bool {
        guard let seg = allowedActivitySegment, seg.superview?.isHidden == false else { return false }
        seg.selectedSegment = AllowedActivityTab.dayPlan.rawValue
        allowedActivityDayPlanBox?.isHidden = false
        // Mirror allowedActivityTabChanged's Day Plan branch — the segment is set programmatically
        // here, so the control's action doesn't fire and the pane wouldn't otherwise be populated.
        allowedActivityScheduleVC?.reload()
        allowedActivityScheduleVC?.startAutoRefresh()
        getHabitsVcObject().refreshDateTimeClockVisibility()
        mainWindowControllerObj?.window?.makeKeyAndOrderFront(nil)
        return true
    }
}


// MARK: - Day Plan mockup renderer (folded into this file so it compiles in-target without .pbxproj edits)
//
// DEBUG-only: the entire mockup harness below is compiled out of Release builds. In a Debug build it
// stays dormant until launched with the FB_MOCKUP_* env vars (see scripts/mockups/render-mockup.sh).
#if DEBUG

// MARK: - Scenario JSON model

struct MockScenario: Codable {
    var title: String?
    var baseDate: String?            // "yyyy-MM-dd"; default 2026-06-22 (a Monday) for reproducibility
    var dayStart: String             // "HH:mm"
    var dayEnd: String
    var morningStart: String
    var eveningStart: String
    var deepWorkCutoff: String?
    var sprintWorkMinutes: Int?
    var sprintBreakMinutes: Int?
    var routines: [MockRoutine]
    var events: [MockEvent]
    var tasks: [MockTask]
}

struct MockRoutine: Codable { var name: String; var start: String; var end: String; var habits: [MockHabit] }
struct MockHabit: Codable { var title: String; var minutes: Int }
struct MockEvent: Codable { var title: String; var start: String; var end: String }
struct MockTask: Codable {
    var title: String
    var minutes: Int?
    var project: String?
    var outcome: Int?
    var done: Bool?
    var subtasks: [String]?
    /// "HH:mm" — timebox this task: nest it under whichever schedule block covers this time
    /// (a calendar event, or an afternoon deep-work/homework sprint). Omit to leave it in the panel.
    var at: String?
}

/// Everything the schedule engine needs, resolved to concrete dates — set on the VC for the mock render.
struct DayPlanMockConfig {
    let segments: [ScheduleRoutineSegment]
    let meetings: [ScheduleMeetingInput]
    let dayStart: Date
    let dayEnd: Date
    let morningStart: Date
    let eveningStart: Date
    let deepWorkCutoff: Date?
    let sprintWorkSeconds: Int
    let sprintBreakSeconds: Int
}

// MARK: - Renderer

enum DayPlanMockup {

    /// Called from applicationDidFinishLaunching. No-op unless FB_MOCKUP_FILE is set.
    static func runIfRequested() {
        let env = ProcessInfo.processInfo.environment
        guard let file = env["FB_MOCKUP_FILE"], let out = env["FB_MOCKUP_OUT"] else { return }
        let size = parseSize(env["FB_MOCKUP_SIZE"]) ?? NSSize(width: 1280, height: 1000)
        // This window is never placed on an actual screen, so its backingScaleFactor (and thus
        // bitmapImageRepForCachingDisplay's default pixel density) is 1x regardless of the Retina
        // display the PNG ends up being viewed on — hence the blurry output. Default to 2x (matching
        // a standard Retina display); FB_MOCKUP_SCALE overrides for a sharper (or smaller) render.
        let scale = env["FB_MOCKUP_SCALE"].flatMap(Double.init).map { CGFloat($0) } ?? 2.0
        // Render after launch settles so config/fonts are ready, then quit.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let ok = render(scenarioPath: file, outPath: out, size: size, scale: scale)
            FileHandle.standardError.write("FB_MOCKUP: \(ok ? "wrote" : "FAILED") \(out)\n".data(using: .utf8)!)
            // applicationShouldTerminate cancels a normal quit when logged in (it pops a confirm window);
            // terminateFromSelf bypasses that so the headless render actually exits.
            appdelegate?.terminateFromSelf = true
            NSApp.terminate(nil)
        }
    }

    private static func parseSize(_ s: String?) -> NSSize? {
        guard let parts = s?.lowercased().split(separator: "x"), parts.count == 2,
              let w = Double(parts[0]), let h = Double(parts[1]) else { return nil }
        return NSSize(width: w, height: h)
    }

    @discardableResult
    static func render(scenarioPath: String, outPath: String, size: NSSize, scale: CGFloat = 2.0) -> Bool {
        guard let data = FileManager.default.contents(atPath: scenarioPath),
              let scenario = try? JSONDecoder().decode(MockScenario.self, from: data) else {
            FileHandle.standardError.write("FB_MOCKUP: could not read/parse \(scenarioPath)\n".data(using: .utf8)!)
            return false
        }

        let cal = Calendar.current
        let baseDate: Date = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.calendar = cal
            return scenario.baseDate.flatMap { f.date(from: $0) } ?? (f.date(from: "2026-06-22") ?? Date())
        }()
        func at(_ hhmm: String) -> Date {
            let p = hhmm.split(separator: ":").compactMap { Int($0) }
            var c = cal.dateComponents([.year, .month, .day], from: baseDate)
            c.hour = p.first ?? 0; c.minute = p.count > 1 ? p[1] : 0; c.second = 0
            return cal.date(from: c) ?? baseDate
        }

        // Routines → segments (read-only preview style; not actionable).
        let segments: [ScheduleRoutineSegment] = scenario.routines.map { r in
            let habits = r.habits.enumerated().map { i, h in
                ScheduleHabitInput(index: i, title: h.title, durationSeconds: h.minutes * 60,
                                   isPlaying: false, elapsedSeconds: 0, cutoff: nil)
            }
            return ScheduleRoutineSegment(name: r.name, habits: habits,
                                          windowStart: at(r.start), windowEnd: at(r.end), actionable: false)
        }
        let meetings: [ScheduleMeetingInput] = scenario.events.enumerated().map { i, e in
            ScheduleMeetingInput(id: "mock-event-\(i)", title: "📅 " + e.title, start: at(e.start), end: at(e.end))
        }

        let config = DayPlanMockConfig(
            segments: segments, meetings: meetings,
            dayStart: at(scenario.dayStart), dayEnd: at(scenario.dayEnd),
            morningStart: at(scenario.morningStart), eveningStart: at(scenario.eveningStart),
            deepWorkCutoff: scenario.deepWorkCutoff.map(at),
            sprintWorkSeconds: (scenario.sprintWorkMinutes ?? 25) * 60,
            sprintBreakSeconds: (scenario.sprintBreakMinutes ?? 5) * 60)

        // Seed the (non-persisting) task store for the mock day.
        DayPlanTaskStore.mockMode = true
        // Resolve a task's "at" time to the block it should nest under: a calendar event if the time
        // falls inside one, otherwise a deep-work (homework) sprint anchored at that time. The block
        // keys mirror scheduleViewController.blockKey(for:) — "event:<id>" / "deepwork:<epoch>".
        func boxKey(_ hhmm: String?) -> String? {
            guard let hhmm = hhmm else { return nil }
            let when = at(hhmm)
            if let i = scenario.events.firstIndex(where: { at($0.start) <= when && when < at($0.end) }) {
                return "event:mock-event-\(i)"
            }
            return "deepwork:\(Int(when.timeIntervalSince1970))"
        }
        let tasks: [DayPlanTask] = scenario.tasks.map { t in
            DayPlanTask(title: t.title, durationMinutes: t.minutes ?? 15, done: t.done ?? false,
                        blockKey: boxKey(t.at),
                        project: t.project, notes: nil,
                        subtasks: t.subtasks.map { $0.map { DayPlanSubtask(title: $0) } },
                        outcome: t.outcome)
        }
        DayPlanTaskStore.shared.loadMock(tasks, for: baseDate)

        // Build the VC offscreen and render the mock config.
        let vc = scheduleViewController()
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentViewController = vc
        // Installing a controller adopts its default 590x415 view size. Restore the
        // requested render size before measuring or the mockup clips most of the day.
        window.setContentSize(size)
        vc.selectedDate = baseDate
        vc.mockConfig = config
        vc.reload()
        window.layoutIfNeeded()
        vc.view.layoutSubtreeIfNeeded()

        // The day timeline lives in a scroll view, so a fixed-height window clips the afternoon/evening.
        // Grow the window to fit the full day's content (+ chrome) unless the caller pinned a height via
        // FB_MOCKUP_SIZE that's already taller. Re-layout so the whole day is on-screen for the snapshot.
        let chrome: CGFloat = 70   // date bar + "add event" row + spacing above the scroll view
        let neededHeight = vc.mockTimelineContentHeight() + chrome
        if neededHeight > size.height {
            window.setContentSize(NSSize(width: size.width, height: ceil(neededHeight)))
            window.layoutIfNeeded()
        }
        // Two more layout passes so multi-line task fields settle to their wrapped heights.
        vc.view.layoutSubtreeIfNeeded()
        vc.view.layoutSubtreeIfNeeded()

        let view = vc.view
        // Build the bitmap at `scale`x the view's point size ourselves — bitmapImageRepForCachingDisplay
        // would size it off view.window?.backingScaleFactor, which is 1x here since this window is
        // never placed on a real screen, producing a blurry PNG once viewed at normal Retina density.
        let pixelsWide = Int((view.bounds.width * scale).rounded(.up))
        let pixelsHigh = Int((view.bounds.height * scale).rounded(.up))
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixelsWide, pixelsHigh: pixelsHigh,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return false }
        rep.size = view.bounds.size   // point size; pixel density above implies the render scale
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try png.write(to: URL(fileURLWithPath: outPath))
            return true
        } catch {
            FileHandle.standardError.write("FB_MOCKUP: write failed: \(error)\n".data(using: .utf8)!)
            return false
        }
    }
}

#endif  // DEBUG — Day Plan mockup renderer

// MARK: - Day Plan date picker (month grid with free-time badges)

/// One day in the date-picker's month grid: a day number with a small coloured dot underneath
/// showing how much net free time that day has (see `DayPlanFreeLevel`). Padding cells (leading /
/// trailing days outside the month) have no date, number or dot.
private final class DayPlanDayCell: NSView {
    static let size: CGFloat = 34
    private static let underlineWidth: CGFloat = 14   // free-time badge: a short line under the number
    private static let underlineThickness: CGFloat = 2
    private static let discDiameter: CGFloat = 19   // selection/today disc — kept snug so it doesn't dominate
    private static let numberRaise: CGFloat = 3      // slight lift so the badge underline sits below

    private let numberLabel = NSTextField(labelWithString: "")
    // Layer-backed square view for the selection/today circle. A drawn `ovalIn:` rect renders as an OVAL
    // when the stack stretches the cell non-square; a layer with cornerRadius = size/2 is ALWAYS a
    // perfect circle regardless of the cell's frame.
    private let discView = NSView()
    private var date: Date?
    private var isToday = false
    private var isSelected = false
    private var dotColor: NSColor?
    var onSelect: ((Date) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        discView.wantsLayer = true
        discView.layer?.cornerRadius = Self.discDiameter / 2
        discView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(discView)   // behind the number

        numberLabel.font = .systemFont(ofSize: 12)
        numberLabel.alignment = .center
        numberLabel.isBezeled = false
        numberLabel.drawsBackground = false
        numberLabel.isEditable = false
        numberLabel.isSelectable = false
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numberLabel)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.size),
            heightAnchor.constraint(equalToConstant: Self.size),
            numberLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: Self.numberRaise),
            discView.widthAnchor.constraint(equalToConstant: Self.discDiameter),
            discView.heightAnchor.constraint(equalToConstant: Self.discDiameter),
            discView.centerXAnchor.constraint(equalTo: numberLabel.centerXAnchor),
            discView.centerYAnchor.constraint(equalTo: numberLabel.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(day: Int?, date: Date?, isToday: Bool, isSelected: Bool, dotColor: NSColor?) {
        self.date = date
        self.isToday = isToday
        self.isSelected = isSelected
        self.dotColor = dotColor
        numberLabel.stringValue = day.map(String.init) ?? ""
        numberLabel.textColor = isSelected ? .white : .labelColor
        // Selected = filled accent circle; today (not selected) = thin accent ring; else nothing.
        let layer = discView.layer
        if isSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            layer?.borderWidth = 0
        } else if isToday {
            layer?.backgroundColor = NSColor.clear.cgColor
            layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.55).cgColor
            layer?.borderWidth = 1
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            layer?.borderWidth = 0
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if let color = dotColor {
            // A short underline beneath the day number (a line, not a dot — subtler).
            let r = NSRect(x: bounds.midX - Self.underlineWidth / 2, y: 5,
                           width: Self.underlineWidth, height: Self.underlineThickness)
            color.setFill()
            NSBezierPath(rect: r).fill()
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard let date = date else { return }
        onSelect?(date)
    }
}

/// The popover content behind the Day Plan's date label: a month calendar the user can page through,
/// each day carrying a subtle free-time dot. Free minutes per day are computed once via the provider
/// and cached for the popover's lifetime (a schedule build per day).
///
/// A day is badged only once its meetings have actually been read — see `DayPlanDayBadge`. The grid
/// therefore renders in two passes: unread days come up blank, `warmMeetings` reads them off the main
/// thread, and the grid rebuilds with their real colours. Two passes rather than one blocking pass
/// because the EventKit read behind each day regularly takes seconds (CalendarManager's "Meetings
/// cache" note), and a popover that freezes on open is not an improvement on a wrong colour.
private final class DayPlanDatePickerController: NSViewController {
    private let freeMinutesProvider: (Date) -> Int?
    private let onSelect: (Date) -> Void
    private let selectedDate: Date
    private var monthAnchor: Date                 // first day of the displayed month
    private var freeCache: [Date: Int?] = [:]     // startOfDay → net free minutes (nil = no schedule)
    /// Days already handed to `warmMeetings`, so a rebuild triggered by one warm pass can't start another
    /// for the same days — that would loop for as long as the popover is open.
    private var warmRequested: Set<Date> = []

    private let calendar = Calendar.current
    private let titleLabel = NSTextField(labelWithString: "")
    private let weeksStack = NSStackView()

    private static let columns = 7
    private static let weeks = 6
    private static let outerPadding: CGFloat = 12
    private static let rowSpacing: CGFloat = 2

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; f.calendar = Calendar.current; return f
    }()

    init(selectedDate: Date, freeMinutesProvider: @escaping (Date) -> Int?, onSelect: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.freeMinutesProvider = freeMinutesProvider
        self.onSelect = onSelect
        self.monthAnchor = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate)) ?? selectedDate
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let gridWidth = DayPlanDayCell.size * CGFloat(Self.columns)
        let container = NSView(frame: NSRect(x: 0, y: 0,
                                             width: gridWidth + Self.outerPadding * 2, height: 260))

        let prev = navButton(symbol: "chevron.left", fallback: "‹", action: #selector(prevMonth))
        let next = navButton(symbol: "chevron.right", fallback: "›", action: #selector(nextMonth))
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.isBezeled = false; titleLabel.drawsBackground = false; titleLabel.isEditable = false
        let header = NSStackView(views: [prev, titleLabel, next])
        header.orientation = .horizontal
        header.distribution = .fill
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let weekdayRow = makeWeekdayHeaderRow()

        weeksStack.orientation = .vertical
        weeksStack.spacing = Self.rowSpacing
        weeksStack.alignment = .centerX

        let outer = NSStackView(views: [header, weekdayRow, weeksStack])
        outer.orientation = .vertical
        outer.spacing = 8
        outer.alignment = .centerX
        outer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: container.topAnchor, constant: Self.outerPadding),
            outer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Self.outerPadding),
            outer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Self.outerPadding),
            outer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Self.outerPadding),
            header.widthAnchor.constraint(equalToConstant: gridWidth),
        ])
        view = container
        rebuildGrid()
    }

    private func navButton(symbol: String, fallback: String, action: Selector) -> NSButton {
        let b = NSButton(title: "", target: self, action: action)
        b.bezelStyle = .inline
        b.isBordered = false
        if #available(macOS 11.0, *) {
            b.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        } else {
            b.title = fallback
        }
        b.setContentHuggingPriority(.required, for: .horizontal)
        return b
    }

    /// The weekday initials (S M T W T F S), ordered from the locale's first weekday.
    private func makeWeekdayHeaderRow() -> NSStackView {
        let symbols = Self.monthTitleFormatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let firstWeekdayIndex = calendar.firstWeekday - 1     // 0-based into `symbols` (which start on Sunday)
        var labels: [NSView] = []
        for offset in 0..<Self.columns {
            let symbol = symbols[(firstWeekdayIndex + offset) % Self.columns]
            let l = NSTextField(labelWithString: symbol)
            l.font = .systemFont(ofSize: 10)
            l.textColor = .secondaryLabelColor
            l.alignment = .center
            l.widthAnchor.constraint(equalToConstant: DayPlanDayCell.size).isActive = true
            labels.append(l)
        }
        let row = NSStackView(views: labels)
        row.orientation = .horizontal
        row.spacing = 0
        return row
    }

    @objc private func prevMonth() { changeMonth(by: -1) }
    @objc private func nextMonth() { changeMonth(by: 1) }
    private func changeMonth(by delta: Int) {
        guard let m = calendar.date(byAdding: .month, value: delta, to: monthAnchor) else { return }
        monthAnchor = m
        rebuildGrid()
    }

    /// Net free minutes for `date`, computed once then memoised for the popover's lifetime.
    private func freeMinutes(for date: Date) -> Int? {
        let key = calendar.startOfDay(for: date)
        if let cached = freeCache[key] { return cached }
        let value = freeMinutesProvider(date)
        freeCache[key] = value
        return value
    }

    /// Read the meetings of every day the grid had to leave blank, then rebuild it with their colours.
    /// One pass per set of days: `warmRequested` stops the rebuild this completion triggers from
    /// asking again.
    private func warmUnknownDays(_ days: [Date]) {
        let pending = days.filter { warmRequested.insert(calendar.startOfDay(for: $0)).inserted }
        guard !pending.isEmpty else { return }
        CalendarManager.shared.warmMeetings(for: pending) { [weak self] in
            guard let self = self, self.isViewLoaded else { return }
            self.rebuildGrid()
        }
    }

    private func rebuildGrid() {
        titleLabel.stringValue = Self.monthTitleFormatter.string(from: monthAnchor)
        weeksStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var unknownDays: [Date] = []

        let weekday = calendar.component(.weekday, from: monthAnchor)     // 1 = Sunday
        let leadingBlanks = (weekday - calendar.firstWeekday + Self.columns) % Self.columns
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30

        for week in 0..<Self.weeks {
            var cells: [NSView] = []
            for column in 0..<Self.columns {
                let cellIndex = week * Self.columns + column
                let dayNumber = cellIndex - leadingBlanks + 1
                let cell = DayPlanDayCell()
                if dayNumber >= 1, dayNumber <= daysInMonth,
                   let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthAnchor) {
                    // Only badge FUTURE days — past days can't be re-planned and today's free time is
                    // already in the tasks-panel header, so badging them is just noise.
                    let isFuture = calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
                    let loaded = CalendarManager.shared.meetingsAreKnown(for: date)
                    if isFuture, !loaded { unknownDays.append(date) }
                    let badgeColor = DayPlanDayBadge.color(isFuture: isFuture, inputsAreLoaded: loaded,
                                                           netFreeMinutes: self.freeMinutes(for: date))
                    cell.configure(day: dayNumber, date: date,
                                   isToday: calendar.isDateInToday(date),
                                   isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                   dotColor: badgeColor)
                    cell.onSelect = { [weak self] in self?.onSelect($0) }
                } else {
                    cell.configure(day: nil, date: nil, isToday: false, isSelected: false, dotColor: nil)
                }
                cells.append(cell)
            }
            let row = NSStackView(views: cells)
            row.orientation = .horizontal
            row.spacing = 0
            weeksStack.addArrangedSubview(row)
        }
        warmUnknownDays(unknownDays)
    }
}
