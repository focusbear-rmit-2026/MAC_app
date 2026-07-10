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
import SwiftUI

/// All user-facing strings for the Schedule tab, read from the `scheduleViewInfo` config block
/// (with English fallbacks) so they can be translated like the rest of the app.
enum ScheduleText {
    private static var info: NSDictionary? { configjson.value(forKey: "scheduleViewInfo") as? NSDictionary }
    static func t(_ key: String, _ fallback: String) -> String {
        (info?.value(forKey: key) as? String) ?? fallback
    }
    static var morningRoutineHabits: String { t("morningRoutineHabits", "Morning routine habits") }
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
            deepWorkNoRoom: "🧠 " + t("deepWorkNoRoom", "Deep work (no room for next habit)"),
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
    static var eventSave: String { t("eventSave", "Save") }
    static var eventCancel: String { t("eventCancel", "Cancel") }
    static var eventSaveError: String { t("eventSaveError", "Couldn't save the event. Check calendar access and try again.") }
    static var showEarlierEvents: String { t("showEarlierEvents", "Show events from earlier today") }
    static var hideDeepWork: String { t("hideDeepWork", "Hide deep work blocks") }
    static var showDismissedEvents: String { t("showDismissedEvents", "Show dismissed events") }
    static var showEventAgain: String { t("showEventAgain", "Show this event again") }
    static var hideEvent: String { t("hideEvent", "Hide this event") }
    static var showHabits: String { t("showHabits", "Show habits") }
    static var hideHabits: String { t("hideHabits", "Hide habits") }
    static var deepWorkSession: String { t("deepWorkSession", "Deep work") }
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
    static var eventNotesLabel: String { t("eventNotesLabel", "Description (shared with other attendees)") }
    static var eventPrivateNotesLabel: String { t("eventPrivateNotesLabel", "My private notes (only you)") }
    static var freeTimeToday: String { t("freeTimeToday", "🕒 %@ free") }
    static var repeatNone: String { t("repeatNone", "Does not repeat") }
    static var repeatDaily: String { t("repeatDaily", "Daily") }
    static var repeatWeekly: String { t("repeatWeekly", "Weekly") }
    static var repeatMonthly: String { t("repeatMonthly", "Monthly") }
    static var tasksForToday: String { t("tasksForToday", "Tasks for today") }
    static var tasksForDay: String { t("tasksForDay", "Tasks for %@") }
    static var tasksShowCompleted: String { t("tasksShowCompleted", "Show completed") }
    static var tasksShowCompletedCount: String { t("tasksShowCompletedCount", "Show completed (%d)") }
    static var tasksExpand: String { t("tasksExpand", "Details") }
    static var tasksSnooze: String { t("tasksSnooze", "Snooze") }
    static var tasksRemove: String { t("tasksRemove", "Remove") }
    static var tasksDetailsTitle: String { t("tasksDetailsTitle", "Task details") }
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
    static var tasksNotTimeBoxed: String { t("tasksNotTimeBoxed", "Not yet time boxed") }
    static var tasksSnoozeHint: String { t("tasksSnoozeHint", "Snooze — move to another day") }
    static var tasksSnoozeTitle: String { t("tasksSnoozeTitle", "Move task to…") }
    static var tasksSnoozePlaceholder: String { t("tasksSnoozePlaceholder", "e.g. 2d, 2w, tue, tom") }
    static var tasksSnoozeHelp: String { t("tasksSnoozeHelp", "2d = in 2 days · 2w = in 2 weeks · tue = next Tuesday · tom = tomorrow · 1 Jul = a date") }
    static var tasksSnoozeConfirm: String { t("tasksSnoozeConfirm", "Move") }
    static var tasksSnoozeCancel: String { t("tasksSnoozeCancel", "Cancel") }
    static var tasksNoProject: String { t("tasksNoProject", "No project") }
    static var tasksProjectHint: String { t("tasksProjectHint", "Type #project to group this task") }
    static var customRoutinesTitle: String { t("customRoutinesTitle", "Custom routines") }
    static var customRoutinesEmpty: String { t("customRoutinesEmpty", "No on-demand routines") }
    static var customRoutinesAfterCutoff: String { t("customRoutinesAfterCutoff", "On demand custom routines deactivated until tomorrow morning - time to wind down now") }
    static var tabCustomRoutine: String { t("tabCustomRoutine", "Custom routine") }
    static var tabDayPlan: String { t("tabDayPlan", "Day Plan") }
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
}

extension ScheduleHost {
    func cancelledRoutine() -> (sectionName: String, message: String, buttonTitle: String)? { nil }
    func uncancelRoutine() {}
    // Default no-op so hosts that don't surface past habits (routinePostponedInfoVc, habitsStateVc)
    // needn't implement it — past-habit completion is only actionable on the active host.
    func schedulePastHabitDone(id: String, performedAt: Date) {}
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
    static func habitInputs(from habits: [habit], now: Date, dropCompleted: Bool = true) -> [ScheduleHabitInput] {
        // Completion is per-day: derive the day from `now` so a PAST-day view reflects that day's
        // (backdated) completions, not only today's — dayPlanCompletedHabitIds is today-only.
        let dayKey = getStringFromDate(date: now, dateFormat: "yyyy-MM-dd")
        return habits.enumerated().compactMap { idx, h in
            if dropCompleted, let id = h.id, isHabitDoneForDay(id, dayKey: dayKey) { return nil }
            let playing = currentHabitPlaying?.id != nil && currentHabitPlaying?.id == h.id
            let done = h.id.map { isHabitDoneForDay($0, dayKey: dayKey) } ?? false
            return ScheduleHabitInput(index: idx,
                                      title: h.name ?? "Habit",
                                      durationSeconds: estimatedDuration(for: h),
                                      isPlaying: playing,
                                      elapsedSeconds: 0,
                                      cutoff: timeToday(h.cutOffTime, now: now),
                                      isDone: done,
                                      id: h.id)
        }
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
    /// non-actionable — you can't act on another day's habits.
    static func segmentsForDate(_ date: Date) -> [ScheduleRoutineSegment] {
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

        let morning = habitInputs(from: filterByWeekday(arrAllDaysMorningHabits, weekday: weekday), now: morningStart, dropCompleted: isToday)
        if !morning.isEmpty {
            segs.append(ScheduleRoutineSegment(name: ScheduleText.morningRoutineHabits, habits: morning,
                                               windowStart: morningStart, windowEnd: eveningStart ?? endOfDay,
                                               actionable: false))
        }
        if let es = eveningStart {
            let evening = habitInputs(from: filterByWeekday(arrAllDaysEveningHabits, weekday: weekday), now: es, dropCompleted: isToday)
            if !evening.isEmpty {
                segs.append(ScheduleRoutineSegment(name: ScheduleText.eveningRoutineHabits, habits: evening,
                                                   windowStart: es, windowEnd: endOfDay, actionable: false))
            }
        }
        for r in arrAllCustomRoutine {
            guard isScheduledOn(r.days_of_week, weekday: weekday), let st = timeOnDate(r.startTime, date: date) else { continue }
            let habitsC = habitInputs(from: r.arrAllHabits, now: st, dropCompleted: isToday)
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
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}

class scheduleViewController: NSViewController {

    /// A flipped clip view makes the scroll view lay its document out top-to-bottom
    /// (AppKit's default clip is bottom-up, which left content invisible/cramped).
    final class FlippedClipView: NSClipView { override var isFlipped: Bool { true } }

    private let scrollView = NSScrollView()
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
    private var postponeHiddenObservation: NSKeyValueObservation?
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
    private let dateLabelButton = NSButton()
    private let todayButton = NSButton()
    private let scheduleCog = NSButton()
    private var scheduleSettingsPopover: NSPopover?
    private let todayIndicatorLabel = NSTextField(labelWithString: "")
    private let addEventButton = NSButton()
    private var datePopover: NSPopover?

    // "Add event" form state (rebuilt each time the popover opens).
    private var addEventPopover: NSPopover?
    private var addTitleField: NSTextField?
    private var addCalendarPopup: NSPopUpButton?
    private var addStartPicker: NSDatePicker?
    private var addEndPicker: NSDatePicker?
    private var addRecurrencePopup: NSPopUpButton?
    private var addNotesView: NSTextView?
    private var addPrivateNotesView: NSTextView?
    private var addErrorLabel: NSTextField?
    private var addCalendarIDs: [String] = []
    /// Event id being edited (nil = creating a new event).
    private var editingEventID: String?
    private var addSelectedColor: NSColor?
    private var addColorButtons: [NSButton] = []

    // "Add from to-do list" picker state.
    private var todoPopover: NSPopover?
    private var todoAllTasks: [NSDictionary] = []
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

    /// Persisted setting: show events the user dismissed (✕) — rendered struck-through with a 👀 to
    /// bring them back — instead of hiding them.
    private var showDismissedEvents: Bool {
        get { UserDefaults.standard.bool(forKey: "kUserdefaultsShowDismissedEventsInDayPlan") }
        set { UserDefaults.standard.set(newValue, forKey: "kUserdefaultsShowDismissedEventsInDayPlan") }
    }

    /// Explicit expand/collapse overrides for routine sections (accordions), keyed by
    /// "routineName|dayOrdinal". Absent → default: collapsed on future days, expanded today/past.
    private var routineCollapseOverrides: [String: Bool] = [:]

    /// #2010: routine sections surfaced as *earlier today* items under the "Show events from earlier
    /// today" toggle (currently the past morning routine, once the evening routine has started). They
    /// default to collapsed even on today — they're history, shown alongside the earlier meetings —
    /// unlike the active routine. Rebuilt each reload(); a user click still overrides (see below).
    private var earlierRoutineNames: Set<String> = []

    private func routineCollapseKey(_ name: String, date: Date) -> String {
        "\(name)|\(Int(date.timeIntervalSince1970 / 86400))"
    }
    private func isRoutineCollapsed(name: String, date: Date) -> Bool {
        if let explicit = routineCollapseOverrides[routineCollapseKey(name, date: date)] { return explicit }
        // Past routines shown under the "earlier today" toggle start collapsed even on today.
        if earlierRoutineNames.contains(name) { return true }
        // Default: future days start collapsed; today (and past) stay expanded.
        return Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }
    private func toggleRoutineCollapsed(name: String, date: Date) {
        let key = routineCollapseKey(name, date: date)
        routineCollapseOverrides[key] = !isRoutineCollapsed(name: name, date: date)
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
        root.addSubview(scrollView)
        root.addSubview(separator)
        root.addSubview(tasksPanel)
        root.addSubview(customRoutinesPanel)
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
        let crHeight = customRoutinesPanel.heightAnchor.constraint(equalToConstant: customRoutinesPanel.preferredHeight)
        crHeight.priority = .defaultHigh   // yields to the ≤1/5 max above
        crHeightConstraint = crHeight
        // Cog leading: default top-left; alternate sits just right of the routine toggle (activated in
        // updateRoutineToggle while the toggle is shown, so the cog doesn't land on the toggle).
        let cogLeadDefault = scheduleCog.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16)
        cogLeadingDefault = cogLeadDefault
        cogLeadingBesideToggle = scheduleCog.leadingAnchor.constraint(equalTo: routineToggle.trailingAnchor, constant: 10)
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
            dateBar.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

            // Add-event button at the right of the schedule column, level with the date bar.
            addEventButton.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor),
            addEventButton.trailingAnchor.constraint(equalTo: separator.leadingAnchor, constant: -16),

            // Schedule scroll fills the left column (up to the panel separator).
            scrollView.topAnchor.constraint(equalTo: dateBar.bottomAnchor, constant: 6),
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
    /// (e.g. "House") even before any task on the day uses them.
    private func fetchProjectsForAutocomplete() {
        allApiObject.getProjectsList { dicts in
            DispatchQueue.main.async {
                guard let dicts = dicts else { return }
                let names = dicts.compactMap { $0.value(forKey: "name") as? String }
                DayPlanTaskStore.shared.remoteProjectNames = names
            }
        }
    }

    /// Placeholder for now — task→block highlighting comes with drag-and-drop (next stage).
    private func refreshTasksHighlights() { reload() }

    // MARK: - Date navigation

    private func makeDateBar() -> NSView {
        func arrow(_ symbol: String, _ action: Selector) -> NSButton {
            let b = NSButton(title: "", target: self, action: action)
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
    private func updateDateBar() {
        let f = DateFormatter()
        f.dateFormat = Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .year)
            ? "EEE d MMM" : "EEE d MMM yyyy"
        dateLabelButton.title = f.string(from: selectedDate)   // date only — "Today" goes below
        if isViewingToday {
            let tf = DateFormatter(); tf.dateFormat = "h:mm a"
            todayIndicatorLabel.stringValue = ScheduleText.today.uppercased() + " · " + tf.string(from: Date())
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
        selectedHabitIndex = nil
        selectedPastHabitId = nil       // a past selection is date-specific
        lastRenderSignature = nil
        reload()
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
        selectedDate = Date(); selectedHabitIndex = nil; selectedPastHabitId = nil; lastRenderSignature = nil; reload()
    }

    @objc private func pickDateClicked() {
        let picker = NSDatePicker()
        picker.datePickerStyle = .clockAndCalendar
        picker.datePickerElements = .yearMonthDay
        picker.dateValue = selectedDate
        picker.target = self
        picker.action = #selector(datePicked(_:))
        picker.translatesAutoresizingMaskIntoConstraints = false
        let vc = NSViewController()
        vc.view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 160))
        vc.view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
        ])
        let pop = NSPopover()
        pop.contentViewController = vc
        pop.behavior = .transient
        pop.show(relativeTo: dateLabelButton.bounds, of: dateLabelButton, preferredEdge: .maxY)
        datePopover = pop
    }

    @objc private func datePicked(_ sender: NSDatePicker) {
        selectedDate = sender.dateValue
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
    func openEventEditor(eventID: String, from view: NSView) {
        requestCalendarThen { [weak self] in self?.presentEventForm(editingID: eventID, relativeTo: view) }
    }

    /// Run `action` once we have calendar access (requesting it first if undetermined).
    private func requestCalendarThen(_ action: @escaping () -> Void) {
        switch CalendarManager.shared.access {
        case .authorized:
            action()
        case .notDetermined:
            CalendarManager.shared.requestAccess { [weak self] granted in
                DispatchQueue.main.async {
                    self?.lastRenderSignature = nil
                    self?.reload()                      // refresh banner / meetings now we may have access
                    if granted { action() }
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
    private func presentEventForm(editingID: String?, relativeTo anchor: NSView) {
        editingEventID = editingID
        let existing = editingID.flatMap { CalendarManager.shared.event(withID: $0) }
        let start = existing?.startDate ?? defaultEventStart()
        let end = existing?.endDate ?? start.addingTimeInterval(30 * 60)

        let header = makeLabel(editingID == nil ? ScheduleText.addEvent : ScheduleText.editEventTitle, size: 14, bold: true)

        let titleField = NSTextField()
        titleField.placeholderString = ScheduleText.eventTitlePlaceholder
        titleField.stringValue = existing?.title ?? ""
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.widthAnchor.constraint(equalToConstant: 300).isActive = true
        addTitleField = titleField

        let calendarPopup = NSPopUpButton()
        let cals = CalendarManager.shared.writableCalendars()
        addCalendarIDs = cals.map { $0.id }
        for c in cals { calendarPopup.addItem(withTitle: c.title) }
        if let calID = existing?.calendar?.calendarIdentifier, let idx = addCalendarIDs.firstIndex(of: calID) {
            calendarPopup.selectItem(at: idx)
        }
        calendarPopup.translatesAutoresizingMaskIntoConstraints = false
        addCalendarPopup = calendarPopup

        func picker(_ value: Date, action: Selector?) -> NSDatePicker {
            let p = NSDatePicker()
            p.datePickerStyle = .textFieldAndStepper
            p.datePickerElements = [.yearMonthDay, .hourMinute]
            p.dateValue = value
            if let action = action { p.target = self; p.action = action }
            p.translatesAutoresizingMaskIntoConstraints = false
            return p
        }
        let startPicker = picker(start, action: #selector(startPickerChanged))
        let endPicker = picker(end, action: nil)
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

        // Description — written to the calendar event, so it's shared with the other attendees.
        let (notesView, notesScroll) = notesBox(existing?.notes ?? "")
        addNotesView = notesView

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

        let cancelButton = NSButton(title: ScheduleText.eventCancel, target: self, action: #selector(cancelEventForm))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"           // Esc
        let saveButton = NSButton(title: ScheduleText.eventSave, target: self, action: #selector(saveEventForm))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"                 // Return
        let buttonRow = NSStackView(views: [NSView(), cancelButton, saveButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8

        // Participants — read-only list of the event's attendees, so you can see who you're meeting
        // with. Only shown when the calendar event actually has attendees (skipped for solo/new
        // events). Prefer the other attendees; fall back to the full list if that leaves it empty.
        var attendeeViews: [NSView] = []
        if let attendees = existing?.attendees, !attendees.isEmpty {
            let others = attendees.filter { !$0.isCurrentUser }
            let people = others.isEmpty ? attendees : others
            let names: [String] = people.map { p in
                if let n = p.name?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty { return n }
                let s = p.url.absoluteString
                return s.hasPrefix("mailto:") ? String(s.dropFirst("mailto:".count)) : s
            }
            let value = makeLabel(names.joined(separator: ", "), size: 13, bold: false)
            value.translatesAutoresizingMaskIntoConstraints = false
            value.usesSingleLineMode = false
            value.lineBreakMode = .byWordWrapping
            value.preferredMaxLayoutWidth = 300
            value.widthAnchor.constraint(equalToConstant: 300).isActive = true
            attendeeViews = [makeLabel(ScheduleText.eventParticipantsLabel, size: 12, bold: false), value]
        }

        var formViews: [NSView] = [
            header,
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
        let b = NSButton(title: "", target: self, action: #selector(colorSwatchClicked(_:)))
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
        editingEventID = nil
    }

    @objc private func saveEventForm() {
        guard let startPicker = addStartPicker, let endPicker = addEndPicker else { return }
        let title = (addTitleField?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let start = startPicker.dateValue
        let end = endPicker.dateValue
        let finalTitle = title.isEmpty ? ScheduleText.meetingDefaultTitle : title

        guard end > start else { showAddEventError(); NSSound.beep(); return }
        let idx = addCalendarPopup?.indexOfSelectedItem ?? -1
        let calendarID = addCalendarIDs.indices.contains(idx) ? addCalendarIDs[idx] : nil
        let recurrence = CalendarManager.Recurrence(rawValue: addRecurrencePopup?.indexOfSelectedItem ?? 0) ?? .none

        let notes = addNotesView?.string ?? ""
        let wasEditing = editingEventID != nil
        let eventID: String?
        if let editID = editingEventID {
            guard CalendarManager.shared.updateEvent(id: editID, title: finalTitle, start: start, end: end,
                                                     calendarID: calendarID, recurrence: recurrence, notes: notes) else {
                showAddEventError(); NSSound.beep(); return
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
        editingEventID = nil
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

    // MARK: - Lifecycle / refresh

    func startAutoRefresh() {
        reload()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.reload()
        }
        if let t = refreshTimer { RunLoop.main.add(t, forMode: .common) }
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
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        if let obs = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(obs)
            didBecomeActiveObserver = nil
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
    /// Last day we pulled the backend Day Plan for, so hydration fires once per day shown (not on
    /// every timer-driven reload). Reset when the selected day changes.
    private var lastHydratedDay: Date?
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
        // Task-panel hydration — once per day shown.
        if lastHydratedDay == nil || !Calendar.current.isDate(lastHydratedDay!, inSameDayAs: selectedDate) {
            lastHydratedDay = selectedDate
            DayPlanTaskStore.shared.loadAndHydrate(for: selectedDate) { [weak self] in
                self?.tasksPanel.reload()
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
        // The day always runs through to 23:59 of the day being viewed.
        let cal = Calendar.current
        let dayEnd = cal.date(bySettingHour: 23, minute: 59, second: 0, of: selectedDate) ?? scheduleDayEnd(now: now)
        let meetings = CalendarManager.shared.meetings(for: selectedDate, includeDismissed: showDismissedEvents)   // [] when no calendar access

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

        // Diagnostic for the reported blank Day Plan: capture the state that produced this render so a
        // reproduction pinpoints an empty/hidden plan (host nil → no segments, wrong state, etc.).
        addLog(text: "dayplan reload: state=\(currentState) host=\(host != nil ? String(describing: type(of: host!)) : "NIL") isToday=\(isToday) segs=\(segments.count) blocks=\(blocks.count) viewHidden=\(view.isHidden) contentHidden=\(isDayPlanContentHidden)")
        render(blocks: blocks)
        updateDateBar()
        updateFullScreenInsets()   // self-correct if full-screen state changed
        updateRoutineToggle()
        customRoutinesPanel.reload()
        crHeightConstraint?.constant = customRoutinesPanel.preferredHeight
        // Keep the tasks panel on the viewed day (only rebuild when the day actually changes).
        if !Calendar.current.isDate(tasksPanel.date, inSameDayAs: selectedDate) {
            tasksPanel.date = selectedDate
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

    /// Unscheduled time inside the day's active span: the span from the first to the last time-occupying
    /// block, minus the union of those blocks (so overlaps aren't double-counted). Sleep and the
    /// zero-length markers (all-done / routine transitions) don't count as "busy".
    private func freeTimeSeconds(in blocks: [ScheduleBlock]) -> Int {
        // Deep-work blocks are NOT busy — they're the open, task-able time the engine fills with
        // "deep work" sprints (you can drop tasks into them), so they count as FREE. Only meetings,
        // breaks and habits are genuinely busy. (Counting deep work as busy made a day full of
        // deep-work blocks report only the tiny gaps as free, e.g. "42m free".)
        let busyKinds: Set<ScheduleBlockKind> = [.meeting, .breakSprint, .habit]
        let intervals = blocks.filter { busyKinds.contains($0.kind) && $0.end > $0.start }
            .map { ($0.start, $0.end) }
            .sorted { $0.0 < $1.0 }
        guard let first = intervals.first?.0, let last = intervals.map({ $0.1 }).max() else { return 0 }
        var merged: [(Date, Date)] = []
        for iv in intervals {
            if let m = merged.last, iv.0 <= m.1 {
                merged[merged.count - 1].1 = max(m.1, iv.1)
            } else {
                merged.append(iv)
            }
        }
        let busy = merged.reduce(0) { $0 + Int($1.1.timeIntervalSince($1.0)) }
        return max(0, Int(last.timeIntervalSince(first)) - busy)
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
        withViewAppearance { renderImpl(blocks: blocks) }
    }

    private func renderImpl(blocks: [ScheduleBlock]) {
        let bannerOn = CalendarManager.shared.shouldShowPermissionBanner() && !bannerDismissed
        // Include nested-task state so dropping / completing / un-nesting a task forces a rebuild.
        let taskSig = DayPlanTaskStore.shared.tasks(for: selectedDate)
            .map { "\($0.id)\($0.blockKey ?? "")\($0.done)\($0.title)" }.joined()
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
        let signature = "\(appearanceName)|\(bannerOn)|\(Int(selectedDate.timeIntervalSince1970/86400))|\(selectedHabitIndex.map(String.init) ?? "-")|\(selectedPastHabitId ?? "-")|\(completedSig)|\(canShowEarlierToggle)\(showEarlierEvents)|\(hideDeepWorkBlocks)|\(collapseSig)|\(dwCollapseSig)|\(cancelledSig)|\(shouldShowEveningShutdownPrompt())|\(taskSig)|"
            + blocks.map { "\($0.kind)\($0.title)\(Int($0.start.timeIntervalSince1970))\(Int($0.end.timeIntervalSince1970))\($0.isCurrent)\($0.isActionable)" }.joined(separator: ";")
        if signature == lastRenderSignature, !stackView.arrangedSubviews.isEmpty { return }
        lastRenderSignature = signature

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if CalendarManager.shared.shouldShowPermissionBanner() && !bannerDismissed {
            addCard(makeCalendarBanner())
        }

        // The "show events from earlier today" option now lives in the schedule settings cog popover.
        // Keep it hidden during a custom routine — the [Custom routine | Day Plan] toggle sits in the
        // same top-left corner and the cog would overlap it.
        scheduleCog.isHidden = (currentState == ._CUSTOM_ROUTINE_)

        if blocks.isEmpty {
            let empty = makeLabel(isViewingToday ? ScheduleText.noHabitsLeft : ScheduleText.nothingScheduled, size: 14, bold: false)
            empty.textColor = .secondaryLabelColor
            stackView.addArrangedSubview(empty)
            stackView.addArrangedSubview(makeViewTomorrowButton())
            return
        }

        // How much unscheduled (free) time the day's plan leaves — shown in the tasks panel next to
        // the "tasks to do" total.
        let freeSecs = freeTimeSeconds(in: blocks)
        tasksPanel.freeTimeMinutes = freeSecs >= 60 ? freeSecs / 60 : nil

        // Consecutive habits of the same routine collapse into one grouped block; a routine
        // boundary (or any non-habit block) starts a new card.
        // Deep-work tasks are keyed by the sprint's start time, but sprints shift as the day moves,
        // so map each task to the nearest current deep-work sprint (by its ordinal) up front.
        let dwBlocks = blocks.filter { $0.kind == .deepWork }
        let dwTasksByOrdinal = deepWorkTasksByOrdinal(dwBlocks)

        var i = 0
        var dwOrdinal = 0
        var dwRunIndex = 0
        while i < blocks.count {
            if blocks[i].kind == .habit {
                let name = blocks[i].routineName
                var group = [ScheduleBlock]()
                while i < blocks.count, blocks[i].kind == .habit, blocks[i].routineName == name {
                    group.append(blocks[i]); i += 1
                }
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
                // Hide-deep-work setting: skip the deep-work card (and its nested tasks) entirely, so
                // the plan shows just appointments/routines. Keep dwOrdinal in step with dwBlocks.
                if block.kind == .deepWork, hideDeepWorkBlocks {
                    dwOrdinal += 1
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
        let header = makeLabel("🧠 \(ScheduleText.deepWorkSession)  ·  \(timeString(first.start))–\(timeString(last.end))",
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
                           border: NSColor.separatorColor, hasBorder: true, content: headerRow))

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
        case .meeting: return block.eventID.map { "event:\($0)" }
        case .deepWork: return "deepwork:\(Int(block.start.timeIntervalSince1970))"
        default: return nil
        }
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
        let check = NSButton(checkboxWithTitle: "", target: self, action: #selector(nestedTaskToggled(_:)))
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
        let back = NSButton(title: "↩", target: self, action: #selector(nestedTaskUnassign(_:)))
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
        let check = NSButton(checkboxWithTitle: ScheduleText.showEarlierEvents,
                             target: self, action: #selector(toggleEarlierEvents(_:)))
        check.state = showEarlierEvents ? .on : .off
        check.isEnabled = canShowEarlierToggle   // only meaningful when today has earlier events
        let hideDW = NSButton(checkboxWithTitle: ScheduleText.hideDeepWork,
                              target: self, action: #selector(toggleHideDeepWork(_:)))
        hideDW.state = hideDeepWorkBlocks ? .on : .off
        let showDismissed = NSButton(checkboxWithTitle: ScheduleText.showDismissedEvents,
                                     target: self, action: #selector(toggleShowDismissedEvents(_:)))
        showDismissed.state = showDismissedEvents ? .on : .off
        let form = NSStackView(views: [heading, check, hideDW, showDismissed])
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

    @objc private func toggleShowDismissedEvents(_ sender: NSButton) {
        showDismissedEvents = (sender.state == .on)
        lastRenderSignature = nil
        reload()
    }

    /// A centered button at the bottom of the day to step forward to the next day's schedule.
    private func makeViewTomorrowButton() -> NSView {
        let button = NSButton(title: ScheduleText.viewTomorrow, target: self, action: #selector(viewTomorrowClicked))
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
        let inner = NSStackView()
        inner.orientation = .vertical
        inner.alignment = .leading
        inner.spacing = 4
        inner.translatesAutoresizingMaskIntoConstraints = false

        // The active routine (the one with the currently-actionable habit) gets a quick
        // "Skip routine for today" action on its header — the Day Plan equivalent of the Habits
        // view's "I don't have time for all these habits".
        let isActiveRoutine = habits.contains { $0.isActionable }
        // Routine sections are accordions: the header toggles collapse (chevron ▸/▾). They start
        // collapsed on future days so the plan is easy to scan for appointments.
        let routineName = habits.first?.routineName ?? "Habits"
        let dateForToggle = selectedDate
        let collapsed = isRoutineCollapsed(name: routineName, date: dateForToggle)
        // #2010: is THIS routine's section force-cancelled? Drives the uncancel message and hides the
        // "Skip routine for today" action (there's nothing to skip once it's cancelled).
        let cancel = host?.cancelledRoutine()
        let isCancelled = (cancel?.sectionName == routineName)
        if let first = habits.first, let last = habits.last {
            // A proper disclosure chevron (SF Symbol) instead of a tiny ▸/▾ glyph buried in the label —
            // it was too small to read as a tap target for collapse/expand.
            let chevron = makeDisclosureChevron(collapsed: collapsed)
            let header = makeLabel("🧩 \(routineName)  ·  \(timeString(first.start))–\(timeString(last.end))", size: 15, bold: false)
            header.textColor = .labelColor
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
            if isActiveRoutine && !isCancelled {
                let skipBtn = makeSkipRoutineButton()
                skipBtn.setContentHuggingPriority(.required, for: .horizontal)
                skipBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
                headerRow.addArrangedSubview(skipBtn)
            }
            headerRow.onClick = { [weak self] in self?.toggleRoutineCollapsed(name: routineName, date: dateForToggle) }
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
                              border: NSColor.separatorColor, hasBorder: true, content: inner)
        }

        // Default selection = the next-up habit; keep the user's pick if it's still valid.
        let actionableIdxs = habits.filter { $0.isActionable }.compactMap { $0.habitIndex }
        let currentIdx = habits.first { $0.isCurrent }?.habitIndex
        let selected: Int? = (selectedHabitIndex.flatMap { actionableIdxs.contains($0) ? $0 : nil }) ?? currentIdx

        // A whole previous calendar day is in the past (so its habits are retroactively completable),
        // as is today's "earlier today" accordion (h.isEarlier). A future day is neither.
        let isPastDay = Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: Date())
        for h in habits where !collapsed {
            let isSel = h.isActionable && h.habitIndex == selected
            let isPastCompletable = (h.isEarlier || isPastDay) && !h.isDone && h.habitId != nil
            let rowView: NSView
            if isPastCompletable, let id = h.habitId {
                // #2012: a PAST habit that wasn't logged. Click-to-reveal, exactly like the live view —
                // a plain row until selected, then an orange unit with a Done-only bar (no wall of Done
                // buttons). Completed by id with a backdated `performedAt` (its slot on the viewed day),
                // never the index-based live-routine path. Done habits fall through → struck-through row.
                if selectedPastHabitId == id {
                    rowView = makeSelectedPastHabitUnit(h, id: id, performedAt: h.start)
                } else {
                    rowView = makeHabitRow(h, isSelected: false, onSelect: { [weak self] in
                        self?.selectedHabitIndex = nil
                        self?.selectedPastHabitId = id
                        self?.lastRenderSignature = nil
                        self?.reload()
                    })
                }
            } else if isSel, let idx = h.habitIndex {
                // Selected: render as one connected orange unit (header + action bar, no gap),
                // matching the habit view.
                rowView = makeSelectedHabitUnit(h, idx: idx)
            } else {
                rowView = makeHabitRow(h, isSelected: false)
            }
            // Wrap each habit in its own drop target so a dragged task attaches to this specific
            // habit (keyed by its title), and nests directly beneath it — not at the group's end.
            let key = "habit:\(h.title)"
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
                          hasBorder: true, content: inner)
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

    /// A compact red "skip routine for today" ICON button (an ✕) for the active routine header — the
    /// text link was replaced with an icon. Tooltip spells out the action so the ✕ isn't ambiguous.
    private func makeSkipRoutineButton() -> NSButton {
        let btn = NSButton(title: "", target: self, action: #selector(skipRoutineForTodayClicked))
        btn.isBordered = false
        btn.bezelStyle = .inline
        btn.imagePosition = .imageOnly
        btn.contentTintColor = .systemRed
        if #available(macOS 11.0, *), let base = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: ScheduleText.skipRoutineForToday) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            btn.image = base.withSymbolConfiguration(cfg) ?? base
        } else {
            // Pre-11 fallback: keep the (red) text so the action stays reachable.
            btn.attributedTitle = NSAttributedString(
                string: ScheduleText.skipRoutineForToday,
                attributes: [.foregroundColor: NSColor.systemRed,
                             .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                             .underlineStyle: NSUnderlineStyle.single.rawValue])
        }
        btn.toolTip = ScheduleText.skipRoutineForToday
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        return btn
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
        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn else { return }   // Cancel → leave the routine unchanged
            cancelRoutineForToday(openedFromDayPlan: true)              // OK; the ✕ lives on the Day Plan
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
        } else if block.isActionable, let idx = block.habitIndex {
            container.onClick = { [weak self] in
                self?.selectedHabitIndex = idx
                self?.reload()
            }
        }

        let (titleLabel, _) = layoutColumns(in: container,
                                            time: "\(timeString(block.start))–\(timeString(block.end))",
                                            title: block.title, leadingInset: 6, vPad: 6,
                                            timeColor: .secondaryLabelColor, titleColor: .labelColor)
        if block.isDone {
            // Completed earlier today: strike it through (same style as a done nested task). Use the
            // label's own text — layoutColumns splits the emoji into a separate leading label, so
            // block.title (emoji + name) would render the emoji twice.
            titleLabel.attributedStringValue = NSAttributedString(string: titleLabel.stringValue, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: titleLabel.font ?? NSFont.systemFont(ofSize: 13)])
        } else if block.didOverflow {
            titleLabel.textColor = .systemRed
        }
        return container
    }

    /// The selected habit as the habit-view's connected unit: a solid-orange header (white
    /// time · emoji · name) with the Play/Done/Skip bar joined directly beneath, all inside
    /// one orange rounded border with no gap between them.
    private func makeSelectedHabitUnit(_ block: ScheduleBlock, idx: Int) -> NSView {
        // Orange header — white text, same column x-positions as the plain rows so it lines up.
        let header = NSView()
        header.wantsLayer = true
        header.layer?.backgroundColor = NSColor.systemOrange.cgColor
        header.translatesAutoresizingMaskIntoConstraints = false
        layoutColumns(in: header, time: "\(timeString(block.start))–\(timeString(block.end))",
                      title: block.title, leadingInset: 6, vPad: 8,
                      timeColor: .white, titleColor: .white)

        // Action bar joined directly beneath, on the control background.
        let bar = makeActionBar(idx: idx)

        let unit = NSStackView(views: [header, bar])
        unit.orientation = .vertical
        unit.alignment = .leading
        unit.spacing = 0
        unit.translatesAutoresizingMaskIntoConstraints = false
        header.widthAnchor.constraint(equalTo: unit.widthAnchor).isActive = true
        bar.widthAnchor.constraint(equalTo: unit.widthAnchor).isActive = true

        // One orange rounded border around the whole unit; clip so the header fills the top.
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

    /// The Play / Done / Skip bar shown beneath the selected habit (icon + label columns).
    private func makeActionBar(idx: Int) -> NSView {
        func column(_ symbol: String, _ fallback: String, _ label: String, _ kind: ActionKind, fill: NSColor) -> NSView {
            let btn = makeActionButton(symbol: symbol, fallback: fallback, idx: idx, kind: kind, diameter: 40, fill: fill)
            let lbl = makeLabel(label, size: 12, bold: false)
            lbl.textColor = .secondaryLabelColor
            let col = NSStackView(views: [btn, lbl])
            col.orientation = .vertical; col.alignment = .centerX; col.spacing = 3
            col.translatesAutoresizingMaskIntoConstraints = false
            return col
        }
        let bar = NSStackView(views: [
            column("play.fill", "▶", ScheduleText.play, .play, fill: .systemOrange),
            column("checkmark", "✓", ScheduleText.done, .done, fill: NSColor.systemGray.withAlphaComponent(0.3)),
            column("forward.fill", "≫", ScheduleText.skip, .skip, fill: NSColor.systemGray.withAlphaComponent(0.3)),
        ])
        bar.orientation = .horizontal
        bar.alignment = .top
        bar.spacing = 28
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
    /// (makeSelectedHabitUnit), but with a Done-ONLY action bar (no Play/Skip: you can't start a past
    /// habit, and an un-struck one is already evidently un-done). Shown only when the user has clicked
    /// the row; other past rows are plain (click-to-reveal), so there's no wall of Done buttons.
    /// Completion is by id with the backdated `performedAt`.
    private func makeSelectedPastHabitUnit(_ block: ScheduleBlock, id: String, performedAt: Date) -> NSView {
        let header = NSView()
        header.wantsLayer = true
        header.layer?.backgroundColor = NSColor.systemOrange.cgColor
        header.translatesAutoresizingMaskIntoConstraints = false
        layoutColumns(in: header, time: "\(timeString(block.start))–\(timeString(block.end))",
                      title: block.title, leadingInset: 6, vPad: 8,
                      timeColor: .white, titleColor: .white)

        let bar = makePastActionBar(habitId: id, performedAt: performedAt)

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

    /// A Done-only bar for retroactively logging a past morning habit — there's no Skip because an
    /// un-struck earlier-today habit is already evidently un-done. The button carries the habit id in
    /// its identifier so the tap dispatches host.schedulePastHabitDone(id:).
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

        let row = NSStackView(views: [btn, textStack])
        row.orientation = .horizontal; row.alignment = .centerY; row.spacing = 10
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

        let btn = NSButton(title: "", target: self, action: #selector(pastActionButtonClicked(_:)))
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
            // Never let the subtitle push past the card edge (a meeting's ✕ sits ~34pt in).
            sub.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor,
                                          constant: block.kind == .meeting ? -42 : -8).isActive = true
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
            // cursorButton gives the pointing-hand cursor on hover for both the ✕ and the 👀.
            let x = cursorButton(title: block.isDismissed ? "👀" : "✕", target: self, action: #selector(dismissMeetingClicked(_:)))
            // The wide 👀 double-eye emoji gets clipped by the circular bezel, so render the un-dismiss control
            // borderless (no button background) — the full emoji shows cleanly at the default font. The narrow
            // ✕ fits its circle fine, so keep the circular bezel for the dismiss control.
            if block.isDismissed {
                x.isBordered = false
            } else {
                x.bezelStyle = .circular
            }
            x.translatesAutoresizingMaskIntoConstraints = false
            x.identifier = NSUserInterfaceItemIdentifier((block.isDismissed ? "undismiss:" : "dismiss:") + eid)
            x.toolTip = block.isDismissed ? ScheduleText.showEventAgain : ScheduleText.hideEvent
            content.addSubview(x)
            NSLayoutConstraint.activate([
                x.widthAnchor.constraint(equalToConstant: 26),
                x.heightAnchor.constraint(equalToConstant: 26),
                x.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
                x.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            ])
        }

        let card = styledCard(fill: fill, border: border, hasBorder: block.kind != .allDone, content: content)
        // Click a meeting card (anywhere but the ✕) to open its edit form.
        if block.kind == .meeting, let eid = block.eventID {
            card.identifier = NSUserInterfaceItemIdentifier("edit:\(eid)")
            let click = NSClickGestureRecognizer(target: self, action: #selector(meetingCardClicked(_:)))
            click.delegate = self   // so it ignores clicks on the ✕ (dismiss) button
            card.addGestureRecognizer(click)
        }
        return card
    }

    @objc private func meetingCardClicked(_ g: NSClickGestureRecognizer) {
        guard let card = g.view, let raw = card.identifier?.rawValue, raw.hasPrefix("edit:") else { return }
        openEventEditor(eventID: String(raw.dropFirst("edit:".count)), from: card)
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
    private func styledCard(fill: NSColor, border: NSColor, hasBorder: Bool, content: NSView) -> DropTargetView {
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
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
        ])
        return card   // width is constrained by addCard(), once the card is in the stack
    }

    private enum ActionKind { case play, done, skip }

    private func makeActionButton(symbol: String, fallback: String, idx: Int, kind: ActionKind,
                                  diameter: CGFloat = 30, fill: NSColor? = nil) -> NSView {
        // The colored circle is drawn on a dedicated disc view (not the NSButton's own managed
        // layer, which AppKit can redraw as a rounded rect) so it's always a clean circle.
        let disc = NSView()
        disc.wantsLayer = true
        disc.layer?.backgroundColor = (fill ?? .clear).cgColor
        disc.layer?.cornerRadius = diameter / 2
        disc.layer?.masksToBounds = true
        disc.translatesAutoresizingMaskIntoConstraints = false

        let btn = NSButton(title: "", target: self, action: #selector(actionButtonClicked(_:)))
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
        btn.identifier = NSUserInterfaceItemIdentifier("\(kind)")

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
            removeHabitFromCache(index: idx)   // so it can't flash back during the refetch
            // Green flash + fade on the habit row for clear "completed" feedback.
            let rowContainer = sender.superview?.superview
            rowContainer?.wantsLayer = true
            rowContainer?.layer?.cornerRadius = 6
            rowContainer?.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.45).cgColor
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                rowContainer?.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                self?.host?.scheduleDone(index: idx)
                self?.reload()
            })
        case "skip":
            removeHabitFromCache(index: idx)
            host?.scheduleSkip(index: idx)
            scheduleReload(after: 0.25)
        default: break
        }
    }

    private func scheduleReload(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.reload() }
    }

    @objc private func dismissMeetingClicked(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue else { return }
        // Force a re-render: with "Show dismissed events" on, un-dismissing keeps the meeting in the list
        // at the same position, so the render signature wouldn't change and reload() would no-op (the
        // event would stay struck through). Same reset the settings toggles use.
        lastRenderSignature = nil
        if raw.hasPrefix("undismiss:") {
            let eventId = String(raw.dropFirst("undismiss:".count))
            CalendarManager.shared.restoreDismissedEvent(id: eventId)
            DayPlanSync.shared.undismissEvent(eventID: eventId, on: selectedDate)   // mirror to backend (cross-device)
            reload()
        } else if raw.hasPrefix("dismiss:") {
            let eventId = String(raw.dropFirst("dismiss:".count))
            CalendarManager.shared.dismissEvent(id: eventId)
            DayPlanSync.shared.dismissEvent(eventID: eventId, on: selectedDate)   // mirror to backend (cross-device)
            reload()
        }
    }

    // MARK: - Calendar permission banner

    private func makeCalendarBanner() -> NSView {
        let label = makeLabel("⚠️ " + ScheduleText.calendarBanner,
                              size: 12, bold: false)
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let grant = NSButton(title: ScheduleText.grantAccess, target: self, action: #selector(grantCalendarClicked))
        grant.bezelStyle = .rounded
        grant.translatesAutoresizingMaskIntoConstraints = false

        let dismiss = NSButton(title: "✕", target: self, action: #selector(dismissBannerClicked))
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
            reload()
        case .notDetermined:
            // First-time ask: show the system (TCC) prompt. It can't appear over Focus Bear's
            // borderless full-screen cover window, so drop full-screen (with a countdown) first.
            if mainWindowControllerObj?.isFullScreenVisible ?? false {
                beginFullScreenCalendarGrant()
            } else {
                NSApplication.shared.activate(ignoringOtherApps: true)   // make sure the prompt is frontmost
                CalendarManager.shared.requestAccess { [weak self] _ in
                    DispatchQueue.main.async { self?.reload() }
                }
            }
        case .denied:
            // macOS won't re-prompt once access was denied/dismissed — the only way to grant is in
            // System Settings, so take the user straight there.
            openSystemCalendarSettings()
        }
    }

    private func openSystemCalendarSettings() {
        // Focus Bear's window can sit at an elevated level (floating during routines, or the
        // borderless full-screen cover). Elevated levels float above other apps' windows too, so the
        // System Settings window we're about to open would appear *behind* ours and be unreachable.
        // Drop any elevated windows to normal so Settings is reachable, then restore them once the
        // user returns to Focus Bear. (Same idea as CalendarManager.requestAccess does for the TCC
        // prompt; opening Settings has no completion callback, so we restore on app reactivation.)
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
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
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

        let cancel = NSButton(title: ScheduleText.eventCancel, target: self, action: #selector(closeTodoPicker))
        cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"
        let add = NSButton(title: ScheduleText.tasksAddSelected, target: self, action: #selector(addSelectedTodos))
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
            let check = NSButton(checkboxWithTitle: title, target: self, action: #selector(todoRowToggled(_:)))
            check.state = todoSelectedIDs.contains(id) ? .on : .off
            check.identifier = NSUserInterfaceItemIdentifier(id)
            stack.addArrangedSubview(check)
        }
    }

    @objc private func todoSearchChanged(_ s: NSSearchField) { todoSearch = s.stringValue; rebuildTodoList() }
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
        for task in todoAllTasks {
            let id = (task.value(forKey: "id") as? String) ?? ""
            guard todoSelectedIDs.contains(id) else { continue }
            let title = (task.value(forKey: "title") as? String) ?? "Task"
            // Use the to-do's own estimated duration (seconds) if set, else a 15-minute default.
            let secs = (task.value(forKey: "duration") as? Int) ?? 0
            let minutes = secs > 0 ? max(1, secs / 60) : 15
            // Group imported tasks under their to-do's first tag (its "project").
            let tags = (task.value(forKey: "tags") as? [[String: String]]) ?? []
            let project = tags.first?["text"]
            // Capture the to-do's Eisenhower quadrant so completion/planning can round-trip through
            // the `PUT /to-do` upsert (which requires it) without clobbering it.
            let quadrant = (task.value(forKey: "eisenhower_quadrant") as? Int)
            DayPlanTaskStore.shared.add(DayPlanTask(title: title, durationMinutes: minutes, sourceTaskId: id,
                                                    project: project, eisenhowerQuadrant: quadrant),
                                        for: selectedDate)
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
                self?.reload()
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

        var cons: [NSLayoutConstraint] = [
            timeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leadingInset),
            timeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: vPad),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -vPad),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8),
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

    private func durationString(_ seconds: Int) -> String {
        let m = seconds / 60
        if m >= 60 { return "\(m / 60)h \(m % 60)m" }
        return "\(m)m"
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
    /// Day Plan has its own clock) — same as the other Day Plan hosts.
    var isAllowedActivityDayPlanFront: Bool {
        guard let seg = allowedActivitySegment, seg.superview?.isHidden == false else { return false }
        return seg.selectedSegment == 1
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

        // Segmented control sits in a top bar added LAST, so it stays on top of (and clickable over)
        // either pane.
        let seg = NSSegmentedControl(labels: [ScheduleText.habitPlayerTab, ScheduleText.dayPlanTab],
                                     trackingMode: .selectOne, target: self,
                                     action: #selector(allowedActivityTabChanged(_:)))
        seg.selectedSegment = 0
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
        seg.selectedSegment = 0
        allowedActivityDayPlanBox?.isHidden = true
        allowedActivityScheduleVC?.stopAutoRefresh()
        getHabitsVcObject().refreshDateTimeClockVisibility()
    }

    @objc private func allowedActivityTabChanged(_ sender: NSSegmentedControl) {
        let showDayPlan = sender.selectedSegment == 1
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
        seg.selectedSegment = 0
        allowedActivityDayPlanBox?.isHidden = true
        allowedActivityScheduleVC?.stopAutoRefresh()
        getHabitsVcObject().refreshDateTimeClockVisibility()
        mainWindowControllerObj?.window?.makeKeyAndOrderFront(nil)
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
        // Render after launch settles so config/fonts are ready, then quit.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let ok = render(scenarioPath: file, outPath: out, size: size)
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
    static func render(scenarioPath: String, outPath: String, size: NSSize) -> Bool {
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
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return false }
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
