//
//  BusyHoursCalculator.swift
//  Focus Bear
//
//  Pure maths behind the `PUT /portfolio/busy-hours` report (#2418): turns the Mac's calendar events
//  into "hours already taken" per local day so the backend's Day Plan simulation (backend #2363) can
//  subtract them from the user's capacity. Decoupled from EventKit (`BusyEventInput`) so every rule —
//  overlap merging, midnight splitting, the all-day / declined / dismissed exclusions — is unit-tested
//  without a calendar store (see BusyHoursCalculatorTests).
//

import Foundation

/// A calendar event as the busy-hours report sees it. `CalendarManager` maps EKEvents onto this.
struct BusyEventInput: Equatable {
    var start: Date
    var end: Date
    var isAllDay = false
    var isCancelled = false
    /// The user explicitly declined the invitation (accepted / tentative / no-RSVP all count as busy).
    var isDeclined = false
    /// Hidden from the Day Plan by the user ("dismiss" on a meeting).
    var isDismissed = false

    /// Whether the event occupies the user's time: timed, still on, and not opted out of.
    var isBusy: Bool { !isAllDay && !isCancelled && !isDeclined && !isDismissed && end > start }
}

enum BusyHoursCalculator {

    struct Interval: Equatable {
        var start: Date
        var end: Date
    }

    /// The backend validates hours as a number; two decimals keeps the payload stable and readable.
    static let hoursDecimalPlaces = 2
    private static let secondsPerHour = 3600.0

    /// Busy hours for each of the `horizonDays` local days starting at `firstDay`'s day. Every day in
    /// the horizon is present (0 when free) so the report states "free" explicitly rather than by
    /// omission. Overlapping events are merged before summing so a double-booked hour counts once;
    /// an event spanning midnight is split so each day gets its own share.
    static func hoursByDay(events: [BusyEventInput], firstDay: Date, horizonDays: Int,
                           calendar: Calendar = .current) -> [String: Double] {
        let horizonStart = calendar.startOfDay(for: firstDay)
        guard horizonDays > 0, let horizonEnd = calendar.date(byAdding: .day, value: horizonDays, to: horizonStart) else { return [:] }

        var secondsByDay: [String: TimeInterval] = [:]
        for offset in 0..<horizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: horizonStart) else { continue }
            secondsByDay[dayKey(day, calendar: calendar)] = 0
        }
        let busy = merge(events.filter { $0.isBusy }.map { Interval(start: $0.start, end: $0.end) })
        for interval in busy {
            for piece in splitAtMidnight(interval, calendar: calendar) where piece.start >= horizonStart && piece.start < horizonEnd {
                secondsByDay[dayKey(piece.start, calendar: calendar), default: 0] += piece.end.timeIntervalSince(piece.start)
            }
        }
        return secondsByDay.mapValues { rounded($0 / secondsPerHour) }
    }

    /// Coalesces overlapping / touching intervals (sorted by start).
    static func merge(_ intervals: [Interval]) -> [Interval] {
        var merged: [Interval] = []
        for interval in intervals.sorted(by: { $0.start < $1.start }) {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1].end = max(last.end, interval.end)
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    /// Cuts an interval at each local midnight it crosses, so no piece belongs to more than one day.
    static func splitAtMidnight(_ interval: Interval, calendar: Calendar = .current) -> [Interval] {
        var pieces: [Interval] = []
        var cursor = interval.start
        while cursor < interval.end {
            let dayStart = calendar.startOfDay(for: cursor)
            guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
            let pieceEnd = min(nextMidnight, interval.end)
            pieces.append(Interval(start: cursor, end: pieceEnd))
            cursor = pieceEnd
        }
        return pieces
    }

    static func rounded(_ hours: Double) -> Double {
        let scale = pow(10.0, Double(hoursDecimalPlaces))
        return (hours * scale).rounded() / scale
    }

    /// Local `YYYY-MM-DD` in the calendar's own time zone — the key format the backend expects.
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
