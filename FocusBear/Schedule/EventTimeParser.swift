//
//  EventTimeParser.swift
//  Focus Bear
//
//  Lenient parsing/formatting of a typed time-of-day for the Day Plan's Add/Edit event form.
//
//  Why this exists: the form used a stock `NSDatePicker(.textFieldAndStepper)` whose hour/minute
//  segments zero-pad and commit each keystroke on its own — typing "3" in the minute segment shows
//  "03", so getting to "30" is fiddly. A plain text field has no segments: the characters just
//  accumulate, so "3" then "0" is simply "30". This enum holds the parsing that makes such a field
//  forgiving, kept free of AppKit so it can be unit-tested directly.
//
//  User report: 2026-06-24_21-08-27 — "If I type 3 in the minutes input, it converts it to 03 -
//  makes it very difficult to type 30."
//

import Foundation

enum EventTimeParser {

    /// A time of day on a 24-hour clock, independent of any calendar date.
    struct ClockTime: Equatable {
        let hour: Int
        let minute: Int
    }

    // MARK: - Clock constants

    private static let minutesPerHour = 60
    private static let hoursPerDay = 24
    private static let hoursPerHalfDay = 12
    /// "730" -> 7:30: a 3-digit entry is one hour digit followed by two minute digits.
    private static let shortDigitsCount = 3
    /// "1930" -> 19:30: a 4-digit entry is two hour digits followed by two minute digits.
    private static let longDigitsCount = 4
    private static let minuteDigitsCount = 2

    private static let meridiemSeparator: Character = ":"
    /// Characters a user might reasonably type between hours and minutes ("7.30", "7 30").
    private static let alternateSeparators: Set<Character> = [".", " ", "h"]

    // MARK: - Parsing

    /// Interpret free-typed text as a time of day, or `nil` if it can't be understood.
    ///
    /// Accepts, case- and space-insensitively: `7:30 am`, `7:30am`, `7.30`, `730`, `1930`,
    /// `19:30`, `7`, `7pm`. Rejects out-of-range values (`25:00`, `7:60`) rather than clamping, so
    /// the caller can keep the last good value instead of silently saving a wrong time.
    static func parse(_ text: String) -> ClockTime? {
        let lowercased = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lowercased.isEmpty else { return nil }

        let (body, meridiem) = splitMeridiem(from: lowercased)
        guard let (hour, minute) = splitHourMinute(body) else { return nil }
        guard (0..<minutesPerHour).contains(minute) else { return nil }

        return applyMeridiem(meridiem, toHour: hour, minute: minute)
    }

    /// Whether `text` names a time this parser understands.
    static func isValid(_ text: String) -> Bool { parse(text) != nil }

    private enum Meridiem { case am, pm }

    /// Strip a trailing am/pm (in any of the forms people type) and report which one it was.
    private static func splitMeridiem(from text: String) -> (body: String, meridiem: Meridiem?) {
        // Longest-first so "a.m." is matched before a bare "a" would be.
        let markers: [(suffix: String, meridiem: Meridiem)] = [
            ("a.m.", .am), ("p.m.", .pm), ("am", .am), ("pm", .pm), ("a", .am), ("p", .pm),
        ]
        for marker in markers where text.hasSuffix(marker.suffix) {
            let body = String(text.dropLast(marker.suffix.count))
            return (body.trimmingCharacters(in: .whitespaces), marker.meridiem)
        }
        return (text, nil)
    }

    /// Split the numeric part into hour and minute, accepting separated ("7:30", "7.30", "7 30")
    /// and run-together ("730", "1930", "7") spellings alike.
    private static func splitHourMinute(_ body: String) -> (hour: Int, minute: Int)? {
        let normalised = String(body.map { alternateSeparators.contains($0) ? meridiemSeparator : $0 })

        if normalised.contains(meridiemSeparator) {
            let parts = normalised.split(separator: meridiemSeparator, omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let hour = intValue(parts[0]),
                  let minute = intValue(parts[1]) else { return nil }
            return (hour, minute)
        }

        guard let digits = allDigits(normalised) else { return nil }
        switch digits.count {
        case 1, minuteDigitsCount:
            guard let hour = intValue(digits[...]) else { return nil }
            return (hour, 0)
        case shortDigitsCount, longDigitsCount:
            let split = digits.index(digits.endIndex, offsetBy: -minuteDigitsCount)
            guard let hour = intValue(digits[..<split]),
                  let minute = intValue(digits[split...]) else { return nil }
            return (hour, minute)
        default:
            return nil
        }
    }

    /// Convert a 12-hour reading to 24-hour, or validate an already-24-hour one.
    private static func applyMeridiem(_ meridiem: Meridiem?, toHour hour: Int, minute: Int) -> ClockTime? {
        guard let meridiem = meridiem else {
            guard (0..<hoursPerDay).contains(hour) else { return nil }
            return ClockTime(hour: hour, minute: minute)
        }
        // With am/pm attached, only 12-hour readings make sense — "19pm" is a typo, not 7pm.
        guard (1...hoursPerHalfDay).contains(hour) else { return nil }
        switch meridiem {
        case .am: return ClockTime(hour: hour == hoursPerHalfDay ? 0 : hour, minute: minute)
        case .pm: return ClockTime(hour: hour == hoursPerHalfDay ? hoursPerHalfDay : hour + hoursPerHalfDay,
                                   minute: minute)
        }
    }

    private static func allDigits(_ text: some StringProtocol) -> String? {
        guard !text.isEmpty, text.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return String(text)
    }

    private static func intValue(_ text: some StringProtocol) -> Int? {
        guard let digits = allDigits(text) else { return nil }
        return Int(digits)
    }

    // MARK: - Formatting

    /// Render a time the way this user's Mac writes times, so what the field shows on open is also
    /// something `parse` accepts back (round-trip safe).
    static func format(_ time: ClockTime, locale: Locale = .current) -> String {
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        // Any date works — only the time-of-day is rendered.
        guard let date = calendar.date(from: dateComponentsForFormatting(components)) else {
            return String(format: "%02d:%02d", time.hour, time.minute)
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private static func dateComponentsForFormatting(_ time: DateComponents) -> DateComponents {
        var components = time
        components.year = 2000
        components.month = 1
        components.day = 1
        return components
    }

    // MARK: - Date bridging

    /// The time-of-day part of `date`.
    static func clockTime(of date: Date, calendar: Calendar = .current) -> ClockTime {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return ClockTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    /// `day`'s calendar date carrying `time`'s time-of-day (seconds zeroed).
    static func combine(day: Date, time: ClockTime, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day) ?? day
    }
}
