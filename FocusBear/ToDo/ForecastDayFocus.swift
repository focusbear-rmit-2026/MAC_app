//
//  ForecastDayFocus.swift
//  Focus Bear
//
//  Opening the reschedule sheet from one day's "Fix", rather than from "re-prioritise everything".
//
//  Pure decisions only, so what the sheet promises about a day can be argued with in a test.
//

import Foundation

/// The reschedule sheet answering a *specific* question.
///
/// "It still didn't improve the day plan for Monday - there were several tasks that should have been
/// proposed to move but they weren't in the list" (report 2026-09-16_22-22-50, follow-up).
///
/// They were in the list. Every one of them moves a single day, so they landed in **"Minor changes —
/// moved less than 5 days"**, which is collapsed by default because the PO asked for exactly that:
/// "I want to scrutinise major changes but don't care about minor changes" (report
/// 2026-09-16_17-49-54). Both instructions are right, and together they hide the answer: from the
/// user's seat, "not in the list" and "in a collapsed section I did not open" are the same thing.
///
/// The resolution is that the two are not the same request. Major/minor sorts a **whole-backlog**
/// re-prioritisation by how much each proposal interferes. When the user has clicked Fix on one
/// over-committed day, the proposals that clear *that day* are not a side-effect to be skimmed — they
/// are the thing they asked for. So they get their own section, above the accordions and open, and
/// they are removed from the major/minor piles rather than duplicated into them.
///
/// The general case is untouched: open the sheet from the menu and there is no focused day, so the
/// major/minor split is exactly what it was.
enum ForecastDayFocus {
    /// What the user asked to fix, captured at the moment they asked.
    ///
    /// Carry the shortfall the user saw when opening Fix. Placed tasks use their Day Plan durations
    /// in the forecast too, so the offered relief and the original warning measure the same work.
    struct Target: Equatable {
        let day: Date
        let shortfallMinutes: Double
    }

    /// Whether this proposal actually takes work off `day`.
    ///
    /// Being placed on the day is not enough, and neither is being proposed for it: only a task that
    /// is on the day now and is proposed for a different one frees any of the day's time.
    static func movesWorkOff(_ day: Date, change: LocalTimeForecast.DueDateChange,
                             plannedDay: (String) -> Date?, calendar: Calendar) -> Bool {
        guard change.kind == .task, let planned = plannedDay(change.itemID) else { return false }
        return calendar.isDate(planned, inSameDayAs: day)
            && !calendar.isDate(change.proposedDate, inSameDayAs: day)
    }

    /// The proposals that clear the focused day, in the order the plan made them.
    static func changes(movingWorkOff day: Date, in changes: [LocalTimeForecast.DueDateChange],
                        plannedDay: (String) -> Date?, calendar: Calendar) -> [LocalTimeForecast.DueDateChange] {
        changes.filter { movesWorkOff(day, change: $0, plannedDay: plannedDay, calendar: calendar) }
    }

    /// How much of the day's shortfall these proposals actually clear — and how much they cannot.
    ///
    /// The honest half of this feature. Five rows that do not add up to the gap are worse than being
    /// told the gap cannot be closed from here, because the user applies them and finds the day still
    /// red. `immovableMinutes` is what stays behind on the user's own instruction: "It shouldn't move
    /// hard deadline tasks from their current position in the day plan" (report 2026-09-16_09-40-20).
    struct Relief: Equatable {
        let freedMinutes: Double
        let shortfallMinutes: Double
        /// Work left on the day that the plan is not allowed to move, and how much of it there is.
        let immovableCount: Int
        let immovableMinutes: Double
        /// What is still over after every offered move is applied. Zero when the day comes good.
        var remainingMinutes: Double { max(0, shortfallMinutes - freedMinutes) }
        var clearsTheDay: Bool { remainingMinutes <= epsilon }
        /// The remainder is entirely explained by work the user pinned. Worth saying, because then
        /// the sheet has done all it may and the answer is elsewhere (shorten the routine, or unpin).
        var remainderIsPinned: Bool { !clearsTheDay && immovableMinutes >= remainingMinutes - epsilon }
    }

    private static let epsilon = 0.000_001

    /// `minutes` is asked in the **Day Plan's** currency, for the same reason `shortfallMinutes` is:
    /// freed minutes and the gap they are set against have to be measured on one ruler.
    static func relief(freeing changes: [LocalTimeForecast.DueDateChange], target: Target,
                       minutes: (String) -> Double,
                       immovable: [(id: String, minutes: Double)]) -> Relief {
        Relief(freedMinutes: changes.reduce(0) { $0 + minutes($1.itemID) },
               shortfallMinutes: max(0, target.shortfallMinutes),
               immovableCount: immovable.count,
               immovableMinutes: immovable.reduce(0) { $0 + $1.minutes })
    }
}
