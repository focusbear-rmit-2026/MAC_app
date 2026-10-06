//
//  MachineDateFormat.swift
//  Focus Bear
//
//  Dates written for machines — API bodies and query strings, persisted day keys, analytics
//  properties, file names — in the Gregorian calendar with ASCII digits, whatever the Mac is set to.
//

import Foundation

/// The one place machine-readable dates are formatted and parsed.
///
/// A bare `DateFormatter()` inherits the user's calendar, locale and numbering system. On a Mac set to
/// the Buddhist calendar `yyyy` writes 2569 for 2026, on the Japanese calendar it writes the era year
/// (0008), and an Arabic locale writes Arabic-Indic digits. That sent activity, routine and
/// focus-session timestamps 543 years into the future (backend#2526) and keyed the Day Plan by
/// Buddhist days. Text a person reads keeps their calendar: format it with `getDisplayStringFromDate`.
enum MachineDateFormat {
    /// A local calendar day, e.g. the Day Plan's per-day storage keys and the API's `day` parameters.
    static let dayKey = "yyyy-MM-dd"
    /// The API's UTC timestamp.
    static let utcTimestamp = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    /// A report folder or attachment name; sorts chronologically and is safe in a path.
    static let fileNameTimestamp = "yyyy-MM-dd_HH-mm-ss"
    /// A 24-hour wall-clock time the API stores, e.g. a blocking schedule's start.
    static let clockTime = "HH:mm"

    static let locale = Locale(identifier: "en_US_POSIX")
    static let calendar = Calendar(identifier: .gregorian)
    static let utc = TimeZone(secondsFromGMT: 0)!

    /// No date this app writes is further than this from today. A machine string that parses further
    /// away was written in another calendar (Buddhist: +543 years, Islamic: -578, Japanese: the era
    /// year), so it is read again the way an older build wrote it.
    static let plausibleDistance: TimeInterval = 200 * 365.25 * 24 * 60 * 60

    /// Pins `formatter` to the Gregorian calendar, the POSIX locale and `timeZone`, whatever it inherited.
    static func configure(_ formatter: DateFormatter, timeZone: TimeZone) {
        formatter.locale = locale
        // Set explicitly: a calendar assigned earlier (e.g. `Calendar.current`) survives a locale change.
        formatter.calendar = calendar
        formatter.timeZone = timeZone
    }

    static func formatter(_ format: String, timeZone: TimeZone = .current, legacyLocale: Locale = .current,
                          now: @escaping () -> Date = Date.init) -> DateFormatter {
        MachineDateFormatter(format: format, timeZone: timeZone, legacyLocale: legacyLocale, now: now)
    }

    static func string(from date: Date, format: String, timeZone: TimeZone = .current) -> String {
        formatter(format, timeZone: timeZone).string(from: date)
    }

    /// Parses a machine string, recovering one an older build wrote in the user's own calendar.
    static func date(from text: String, format: String, timeZone: TimeZone = .current,
                     legacyLocale: Locale = .current, now: Date = Date()) -> Date? {
        formatter(format, timeZone: timeZone, legacyLocale: legacyLocale, now: { now }).date(from: text)
    }

    /// `text` rewritten in the Gregorian calendar when an older build wrote it in another one; nil when
    /// it is already Gregorian or is not a date in `format` at all.
    static func normalizedLegacyString(_ text: String, format: String, timeZone: TimeZone = .current,
                                       legacyLocale: Locale = .current, now: Date = Date()) -> String? {
        let formatter = formatter(format, timeZone: timeZone, legacyLocale: legacyLocale, now: { now })
        guard let date = formatter.date(from: text), isPlausible(date, now: now) else { return nil }
        let normalized = formatter.string(from: date)
        return normalized == text ? nil : normalized
    }

    /// `parsed` when it is a plausible date, else the first plausible reading by `legacyFormatters`,
    /// else `parsed` unchanged (a deliberate sentinel such as 1970-01-01 stays what it was).
    static func recoveringLegacyDate(_ text: String, parsed: Date?, now: Date,
                                     legacyFormatters: () -> [DateFormatter]) -> Date? {
        if let parsed = parsed, isPlausible(parsed, now: now) { return parsed }
        guard !text.isEmpty else { return parsed }
        for formatter in legacyFormatters() {
            if let legacy = formatter.date(from: text), isPlausible(legacy, now: now) { return legacy }
        }
        return parsed
    }

    static func isPlausible(_ date: Date, now: Date) -> Bool {
        abs(date.timeIntervalSince(now)) <= plausibleDistance
    }

    /// The ways an older build could have written a machine string: in `legacyLocale`'s calendar exactly
    /// as a bare `DateFormatter()` did, then in the Buddhist calendar alone, for a Mac since switched
    /// back to Gregorian (its +543 years are unambiguous; other calendars' offsets are not).
    static func legacyFormatters(_ format: String, timeZone: TimeZone, legacyLocale: Locale) -> [DateFormatter] {
        var formatters: [DateFormatter] = []
        let identifier = legacyLocale.calendar.identifier
        if identifier != .gregorian {
            let userCalendar = DateFormatter()
            userCalendar.locale = legacyLocale
            formatters.append(userCalendar)
        }
        if identifier != .buddhist {
            let buddhist = DateFormatter()
            buddhist.locale = locale
            buddhist.calendar = Calendar(identifier: .buddhist)
            formatters.append(buddhist)
        }
        for formatter in formatters {
            formatter.timeZone = timeZone
            formatter.dateFormat = format
        }
        return formatters
    }
}

/// A Gregorian, POSIX formatter that also reads back what an older build wrote in the user's calendar,
/// so every machine parse — the shared helpers and the stores' own formatters — recovers legacy data.
final class MachineDateFormatter: DateFormatter {
    private let legacyLocale: Locale
    private let now: () -> Date
    private let legacyLock = NSLock()
    /// Built on the first implausible parse and kept, since a string that fails once tends to recur.
    private var legacyReaders: (key: String, formatters: [DateFormatter])?

    init(format: String, timeZone: TimeZone, legacyLocale: Locale = .current, now: @escaping () -> Date = Date.init) {
        self.legacyLocale = legacyLocale
        self.now = now
        super.init()
        MachineDateFormat.configure(self, timeZone: timeZone)
        dateFormat = format
    }

    required init?(coder: NSCoder) {
        legacyLocale = .current
        now = Date.init
        super.init(coder: coder)
    }

    override func date(from string: String) -> Date? {
        MachineDateFormat.recoveringLegacyDate(string, parsed: super.date(from: string), now: now()) {
            legacyFormatters()
        }
    }

    private func legacyFormatters() -> [DateFormatter] {
        let key = "\(dateFormat ?? "")|\(timeZone.identifier)"
        legacyLock.lock()
        defer { legacyLock.unlock() }
        if let readers = legacyReaders, readers.key == key { return readers.formatters }
        let formatters = MachineDateFormat.legacyFormatters(dateFormat ?? "", timeZone: timeZone, legacyLocale: legacyLocale)
        legacyReaders = (key, formatters)
        return formatters
    }
}
