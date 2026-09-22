//
//  DayFixPlan.swift
//  Focus Bear
//
//  "Fix" — turning the Day Plan's red over-capacity warning into an action.
//
//  Reported as: "can we have a 'Fix' link after the red warning? It would then pop up a modal giving
//  them three options to make the plan more feasible" (report 2026-09-17_08-15-57).
//
//  Pure decisions only — which routes are worth offering and in what order. The views and the
//  EventKit/UserDefaults writes live with the screens that already own them, so this file can be
//  argued with in a test.
//

import Foundation
import SwiftUI

/// A way to make the day fit, and how much room it could free.
///
/// Ordered by **capacity freed, largest first**, rather than by the order the report listed them.
/// Three equal buttons make the user do arithmetic the app has already done: if the meetings are six
/// hours and the routine is twenty minutes, the routine is not the answer and should not be the first
/// thing offered. Ties keep the report's own order, which reads meetings → routine → tasks.
enum DayFixRoute: Equatable, CaseIterable {
    /// Cancel, decline, skip or shorten the day's meetings.
    case meetings
    /// Skip or shorten the day's habits.
    case routine
    /// Move tasks out of the day, on the re-prioritise screen.
    case tasks

    /// The report's order, used to break ties so the list is stable rather than arbitrary.
    var reportedOrder: Int {
        switch self {
        case .meetings: return 0
        case .routine: return 1
        case .tasks: return 2
        }
    }
}

/// One offered route with the room it could free.
struct DayFixOption: Equatable {
    let route: DayFixRoute
    /// Minutes currently spent on this kind of thing today — the most it could possibly free.
    let freeableMinutes: Double
}

/// What a single meeting on the Fix list offers, per the report: "Cancel (if they own it) / Decline
/// (if there are other attendees but they don't own it) / Skip (if there are no other attendees)".
enum DayFixMeetingAction: Equatable {
    /// Nobody else is on the meeting, so nothing needs to leave this Mac: hide it from today's plan.
    case skip
    /// The user organises it — removing it makes the account send the cancellation to the attendees.
    case cancel
    /// Someone else organises it — removing it takes the user's own copy off their calendar.
    case decline
}

enum DayFixPlan {
    /// The routes worth showing, biggest first.
    ///
    /// A route with nothing behind it is **not offered at all**: an option that cannot free a minute
    /// is a dead button, and the whole point of this modal is that every row in it changes the
    /// number at the top.
    static func options(meetingMinutes: Double, habitMinutes: Double, taskMinutes: Double) -> [DayFixOption] {
        [DayFixOption(route: .meetings, freeableMinutes: meetingMinutes),
         DayFixOption(route: .routine, freeableMinutes: habitMinutes),
         DayFixOption(route: .tasks, freeableMinutes: taskMinutes)]
            .filter { $0.freeableMinutes > 0 }
            .sorted {
                $0.freeableMinutes == $1.freeableMinutes
                    ? $0.route.reportedOrder < $1.route.reportedOrder
                    : $0.freeableMinutes > $1.freeableMinutes
            }
    }

    /// Rows for a list inside the modal: **longest first**, because that is where the minutes are and
    /// the report asked for it ("habits sorted by duration descending"). Ties fall back to the name so
    /// the list does not reshuffle between renders.
    static func longestFirst<T>(_ rows: [T], seconds: (T) -> Int, name: (T) -> String) -> [T] {
        rows.sorted {
            seconds($0) == seconds($1) ? name($0) < name($1) : seconds($0) > seconds($1)
        }
    }

    /// The habits the routine route may offer: the ones that sit inside the working day.
    ///
    /// "Evening routine isn't relevant as we assume all tasks get completed before evening routine —
    /// just offer to shorten morning routine" (report 2026-09-17_08-15-57, follow-up). Shortening
    /// something that runs *after* the tasks were supposed to be done frees nothing for those tasks,
    /// and counting it made the route claim 5h 54m of habits on a day whose morning routine was a
    /// fraction of that.
    ///
    /// The rule is the reason, not the routine's name: anything starting at or after the evening
    /// routine begins is out, which also excludes a custom routine parked at the end of the day,
    /// while a custom routine at lunchtime — which really does eat into the day's tasks — stays in.
    static func habitsInsideWorkingDay<T>(_ habits: [T],
                                          start: (T) -> Date,
                                          isEveningRoutine: (T) -> Bool,
                                          eveningRoutineStart: Date?) -> [T] {
        habits.filter { habit in
            if isEveningRoutine(habit) { return false }
            guard let eveningStart = eveningRoutineStart else { return true }
            return start(habit) < eveningStart
        }
    }

    /// Which action one meeting gets. The ownership half deliberately keeps coming from
    /// `EventCancelAction`, so the rule that **unknown ownership never offers to cancel** (that would
    /// take the meeting off everyone else's calendar on a guess) is stated in exactly one place.
    static func meetingAction(hasOtherAttendees: Bool, ownership: EventOwnership) -> DayFixMeetingAction {
        // No one else is on it, so there is nobody to notify and nothing to decline.
        guard hasOtherAttendees else { return .skip }
        return EventCancelAction(ownership: ownership) == .cancelEvent ? .cancel : .decline
    }
}

// MARK: - "Fix" — the action on the over-capacity warning (report 2026-09-17_08-15-57)

/// One habit on the routine list inside the Fix modal.
struct DayFixHabitRow: Identifiable, Equatable {
    let id: String
    let title: String
    let seconds: Int
    let isSkipped: Bool
    let isShortened: Bool
}

/// One meeting on the meetings list inside the Fix modal.
struct DayFixMeetingRow: Identifiable, Equatable {
    /// Unique per occurrence — a repeating event carries the same `eventID` on every one of them.
    let id: String
    let eventID: String
    let title: String
    /// This occurrence's start. A repeating meeting shares one identifier across every occurrence, so
    /// removing or trimming it needs the day's own start rather than the series'.
    let start: Date
    /// When it starts, already formatted by the host (which owns the locale-aware formatters).
    let timeLabel: String
    let seconds: Int
    let action: DayFixMeetingAction
    /// Whether it repeats, so the removal can ask which occurrences the user means.
    let isRecurring: Bool
    /// Hidden from this day's plan already, so it is costing the day nothing.
    let isSkipped: Bool
    /// Carrying a shorter length for this day.
    let isShortened: Bool
}

/// The Fix modal: what is over, and the ways to close the gap.
///
/// Routes are ordered by how much room each could free, largest first — three equal buttons would
/// make the user do arithmetic the app has already done (`DayFixPlan.options`). Only routes that
/// could actually free something are listed, so no row here is a dead button.
struct DayFixView: View {
    let overcommittedMinutes: Double
    let options: [DayFixOption]
    /// Meetings for the meetings route, longest first.
    let meetings: [DayFixMeetingRow]
    /// Habits for the routine route, longest first.
    let habits: [DayFixHabitRow]
    let onSkip: (String) -> Void
    let onShorten: (String) -> Void
    /// Skip / un-skip one meeting for this day — local only, nothing leaves the Mac.
    let onSkipMeeting: (DayFixMeetingRow) -> Void
    /// Cancel or decline one meeting. Outward-facing, so the host confirms before anything is removed.
    let onCancelMeeting: (DayFixMeetingRow) -> Void
    let onShortenMeeting: (DayFixMeetingRow) -> Void
    let onPostponeTasks: () -> Void
    let onClose: () -> Void

    @SwiftUI.State private var openRoute: DayFixRoute?

    private static let width: CGFloat = 420
    private static let listMaxHeight: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ScheduleText.dayFixTitle).font(.fbSemibold(16))
            Text(ScheduleText.dayFixGap.replacingOccurrences(
                of: "<DURATION>", with: ForecastText.duration(overcommittedMinutes)))
                .font(.fbRegular(13)).foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)

            if options.isEmpty {
                Text(ScheduleText.dayFixNothingToFree)
                    .font(.fbRegular(12)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                switch openRoute {
                case .routine?: routineList
                case .meetings?: meetingList
                default: ForEach(options, id: \.route) { option in routeButton(option) }
                }
            }

            // Push the buttons to the bottom and keep the title at the top: the sheet is a fixed 420pt
            // tall, so without this the shorter initial content (the route buttons) was centred in it —
            // the title floated down from the top and Done floated up from the bottom until a taller route
            // (the routine list) filled the sheet.
            Spacer(minLength: 12)
            HStack {
                if openRoute != nil {
                    SwiftUI.Button(ScheduleText.dayFixBack) { openRoute = nil }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true))
                }
                Spacer()
                SwiftUI.Button(ScheduleText.dayFixDone, action: onClose)
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(AppOrangeButtonStyle(secondary: false))
            }
        }
        .padding(18)
        .frame(width: DayFixView.width)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder private func routeButton(_ option: DayFixOption) -> some View {
        SwiftUI.Button(action: {
            switch option.route {
            case .routine: openRoute = .routine
            case .meetings: openRoute = .meetings
            case .tasks: onPostponeTasks()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title(for: option.route)).font(.fbSemibold(13))
                    Text(detail(for: option.route, minutes: option.freeableMinutes))
                        .font(.fbRegular(11)).foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    private func title(for route: DayFixRoute) -> String {
        switch route {
        case .meetings: return ScheduleText.dayFixMeetingsOption
        case .routine: return ScheduleText.dayFixRoutineOption
        case .tasks: return ScheduleText.dayFixTasksOption
        }
    }

    private func detail(for route: DayFixRoute, minutes: Double) -> String {
        let text: String
        switch route {
        case .meetings: text = ScheduleText.dayFixMeetingsDetail
        case .routine: text = ScheduleText.dayFixRoutineDetail
        case .tasks: text = ScheduleText.dayFixTasksDetail
        }
        return text.replacingOccurrences(of: "<DURATION>", with: ForecastText.duration(minutes))
    }

    /// The day's habits, longest first — that is where the minutes are.
    private var routineList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(habits) { habit in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(habit.title).font(.fbRegular(13))
                                .strikethrough(habit.isSkipped)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(ForecastText.duration(Double(habit.seconds) / 60))
                                .font(.fbRegular(11))
                                .foregroundColor(habit.isShortened ? .orange : .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        SwiftUI.Button(habit.isSkipped ? ScheduleText.dayFixUnskip : ScheduleText.dayFixSkip) {
                            onSkip(habit.id)
                        }
                        SwiftUI.Button(ScheduleText.dayFixShorten) { onShorten(habit.id) }
                            .disabled(habit.isSkipped)
                    }
                }
            }
        }
        .frame(maxHeight: DayFixView.listMaxHeight)
    }

    /// The day's remaining meetings, longest first. Each one carries the single action its ownership
    /// and its attendees allow, plus Shorten — never a choice between cancelling and skipping, which
    /// would leave the user to work out which of the two is the safe one.
    private var meetingList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(meetings) { meeting in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(meeting.title).font(.fbRegular(13))
                                .strikethrough(meeting.isSkipped)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(meeting.timeLabel) · \(ForecastText.duration(Double(meeting.seconds) / 60))")
                                .font(.fbRegular(11))
                                .foregroundColor(meeting.isShortened ? .orange : .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        meetingActionButton(meeting)
                        SwiftUI.Button(ScheduleText.dayFixShorten) { onShortenMeeting(meeting) }
                    }
                }
            }
        }
        .frame(maxHeight: DayFixView.listMaxHeight)
    }

    @ViewBuilder private func meetingActionButton(_ meeting: DayFixMeetingRow) -> some View {
        switch meeting.action {
        case .skip:
            SwiftUI.Button(meeting.isSkipped ? ScheduleText.dayFixUnskip : ScheduleText.dayFixSkip) {
                onSkipMeeting(meeting)
            }
        case .cancel:
            SwiftUI.Button(ScheduleText.eventCancelEventButton) { onCancelMeeting(meeting) }
        case .decline:
            SwiftUI.Button(ScheduleText.eventDeclineEventButton) { onCancelMeeting(meeting) }
        }
    }
}
