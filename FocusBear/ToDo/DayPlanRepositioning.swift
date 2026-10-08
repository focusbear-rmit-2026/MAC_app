//
//  DayPlanRepositioning.swift
//  Focus Bear
//
//  Where a reschedule proposal leaves the user's Day Plan.
//
//  Pure decisions only, so the rules can be argued with in a test rather than inside the apply loop.
//

import Foundation

/// The reschedule sheet writes **due dates**. A due date is a deadline, not a position — so applying
/// "Sep 21 → Sep 22" to a task the user had dragged onto Monday left that task sitting on Monday, and
/// the day the plan had just declared over-committed was still over-committed by exactly the same
/// amount. That is the whole of "It still didn't reschedule Monday for me — it didn't suggest moving
/// any of these tasks" (report 2026-09-17_09-04-13, follow-up): the rows existed, they were applied,
/// and the Day Plan was untouched because nothing in the apply path had ever written a placement.
///
/// The proposed date is the forecast's **completion day** — the day the work actually gets done once
/// everything ahead of it is done — so it is also the day the Day Plan placement belongs on. Moving
/// it is not an extra opinion; it is making the Day Plan agree with the plan the user just approved.
enum DayPlanRepositioning {
    /// One placement to relocate. `from` and `to` are start-of-day.
    struct Move: Equatable {
        let taskID: String
        let from: Date
        let to: Date
    }

    /// The move an applied due-date change implies, or `nil` when the Day Plan should be left alone.
    ///
    /// - `plannedOn` is the day the task currently sits on in the Day Plan; `nil` means the user never
    ///   placed it, and a task with no place has no place to move.
    /// - A placement **before today** is history, not a plan. `DayPlanTaskStore.rollOverIfNeeded`
    ///   already owns those, and dragging months of past placements forward would be a fiction of a
    ///   different kind.
    /// - A proposal that lands on a **locked** day is refused. `proposeWorkPlan` never names one, but
    ///   a hand-typed date bypasses that check, and "today and tomorrow are locked in" has to mean the
    ///   same thing whoever chose the date (`LocalTimeForecast.lockedPlanDays`).
    /// - A proposal in the past is refused for the same reason: it is not somewhere work can be planned.
    static func move(taskID: String, plannedOn: Date?, proposedDate: Date, today: Date,
                     lockedDays: [Date], calendar: Calendar) -> Move? {
        guard let plannedOn = plannedOn else { return nil }
        let from = calendar.startOfDay(for: plannedOn)
        let to = calendar.startOfDay(for: proposedDate)
        let today = calendar.startOfDay(for: today)
        guard from >= today, to >= today, from != to else { return nil }
        guard !lockedDays.contains(where: { calendar.isDate($0, inSameDayAs: to) }) else { return nil }
        return Move(taskID: taskID, from: from, to: to)
    }
}
