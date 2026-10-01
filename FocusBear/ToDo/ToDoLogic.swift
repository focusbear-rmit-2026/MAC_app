//
//  ToDoLogic.swift
//  Focus Bear
//
//  Pure logic behind the native To-do List: TOP-score maths, due-date parsing/formatting, sort and
//  filter rules, the Doing / To do / Done section partitioning and the portfolio "This week"
//  grouping. Every rule here mirrors a web-dashboard util (`utils/todo.util.ts`,
//  `utils/snooze-date.util.ts`, `utils/portfolio.util.ts`, `ListOfTasks.tsx`) so the two clients
//  order and label tasks identically. No AppKit/SwiftUI here — it is unit-tested.
//

import CoreGraphics
import Foundation

// MARK: - Dates

enum ToDoDates {
    private static let isoWithFractions: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let iso = ISO8601DateFormatter()
    private static let ymdFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    /// Web `formatAbbrMonthDayYear` ("MMM D, YYYY").
    private static let abbreviated: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    private static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    private static let dayMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    /// "Fri 11 Sep" — the resolved day shown next to a typed due date.
    private static let weekdayDayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()
    /// The same, plus the year, for a day outside the current one.
    private static let weekdayDayMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.dateFormat = "EEE d MMM yyyy"
        return formatter
    }()

    /// Accepts the API's ISO-8601 timestamps (with or without fractional seconds) and plain `YYYY-MM-DD`.
    static func parse(_ string: String?) -> Date? {
        guard let string = string?.trimmingCharacters(in: .whitespaces), !string.isEmpty else { return nil }
        if let date = isoWithFractions.date(from: string) ?? iso.date(from: string) { return date }
        return ymdFormatter.date(from: string)
    }

    /// Local calendar day as `YYYY-MM-DD` (web `formatToYMD`).
    static func ymd(_ date: Date) -> String { ymdFormatter.string(from: date) }

    static func ymd(fromISO string: String?) -> String? {
        parse(string).map(ymd)
    }

    /// Whole calendar days from `now` to `date` (negative = past). Web `daysUntilDue`.
    static func daysBetween(_ now: Date, _ date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func abbreviated(_ isoString: String?) -> String {
        guard let date = parse(isoString) else { return "" }
        return abbreviated.string(from: date)
    }

    /// "Fri 11 Sep", or "Tue 4 Apr 2028" once the day falls outside the current year — a date years
    /// out read as if it were this one (report 2026-09-15_20-52-05). Same rule as `dueLabel`.
    /// Display only: the grammar cannot read either form back, so this is never a field's own text
    /// (`ToDoDueDateFieldText` uses `dayMonthYear`, which always carries the year).
    static func weekdayDayMonth(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = isSameYear(date, as: now, calendar: calendar) ? weekdayDayMonth : weekdayDayMonthYear
        return formatter.string(from: date)
    }

    private static func isSameYear(_ date: Date, as now: Date, calendar: Calendar = .current) -> Bool {
        calendar.component(.year, from: date) == calendar.component(.year, from: now)
    }

    /// "11 Sep 2026" — a due date as the *text* of the typed field. Unlike `weekdayDayMonth` this
    /// is a form `ToDoDueDateParser` reads back, so the value the field shows survives the next save.
    static func dayMonthYear(_ date: Date) -> String { dayMonthYear.string(from: date) }

    /// Web `formatDueDate`: Today / Tomorrow / Yesterday, else "18 Jan" this year, "18 Jan 2027" otherwise.
    static func dueLabel(_ isoString: String?, now: Date = Date(), today: String, tomorrow: String, yesterday: String) -> String {
        guard let date = parse(isoString) else { return "" }
        switch daysBetween(now, date) {
        case 0: return today
        case 1: return tomorrow
        case -1: return yesterday
        default:
            return isSameYear(date, as: now) ? dayMonth.string(from: date) : dayMonthYear.string(from: date)
        }
    }

    /// Web `getDueDateChipVariant`: red when overdue, amber when due today, nothing when completed.
    enum DueState { case none, overdue, today }

    static func dueState(_ isoString: String?, isCompleted: Bool, now: Date = Date()) -> DueState {
        guard !isCompleted, let date = parse(isoString) else { return .none }
        let days = daysBetween(now, date)
        if days < 0 { return .overdue }
        if days == 0 { return .today }
        return .none
    }

    /// Web `formatLocalizedDuration` fallback: "1h 30m", "2h", "45m".
    static func durationLabel(hours: Int, minutes: Int) -> String {
        if hours > 0 && minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }

    /// "Task duration" seconds → "1h 30m"-style label (minutes rounded).
    static func durationLabel(seconds: Int) -> String {
        let totalMinutes = max(0, seconds) / 60
        return durationLabel(hours: totalMinutes / 60, minutes: totalMinutes % 60)
    }
}

// MARK: - TOP score (T × O ÷ P)

/// Mirrors `utils/todo.util.ts` and the backend `TOP_SCORE_SQL` exactly.
enum ToDoScoring {
    static let minLevel = 1
    static let maxLevel = 10
    static let defaultOutcome = 5
    /// Outcome is stored on the server's 1–10 wire scale but shown as 1–5, so a chosen step is
    /// doubled on the way out and halved on the way in. The backend applies no conversion of its
    /// own (backend#2385), which is why the factor lives here.
    static let outcomeSteps = 5
    static let outcomeWireFactor = 2
    static let defaultPerspiration = 2
    private static let scoreFloor = 0.1
    /// Web `getTOPScore`: completed tasks score 0 so they never outrank active work.
    static let completedScore = 0.0
    private static let scorePastDue = 10.0
    private static let scoreToday = 9.0
    private static let perspirationMinutes: [Int: Int] = [1: 5, 2: 15, 3: 30, 4: 60, 5: 240, 6: 240, 7: 480, 8: 480, 9: 3360, 10: 3360]

    static func clampLevel(_ level: Int) -> Int { min(maxLevel, max(minLevel, level)) }

    /// `mapPerspirationLevelToMinutes`.
    static func minutes(forPerspiration level: Int) -> Int { perspirationMinutes[level] ?? 5 }

    /// The inverse of `minutes(forPerspiration:)` for the editor's typed duration: the lowest level
    /// whose work minutes cover the typed value (16 min → level 3 "half an hour"), the top level
    /// beyond the table. A level already matching the minutes is kept, so a slider position that
    /// shares its minutes with a neighbour (5 / 6, 7 / 8, 9 / 10) doesn't snap when the field echoes it.
    static func perspiration(forMinutes minutes: Int, current: Int? = nil) -> Int {
        if let current = current, self.minutes(forPerspiration: current) == minutes { return current }
        return (minLevel...maxLevel).first { self.minutes(forPerspiration: $0) >= minutes } ?? maxLevel
    }

    /// `timePressureScore(dueDate, effortMinutes)`.
    static func timePressure(dueDate: Date?, effortMinutes: Int, now: Date = Date()) -> Double {
        guard let dueDate = dueDate else { return scoreFloor }
        let days = ToDoDates.daysBetween(now, dueDate)
        if days < 0 { return scorePastDue + Double(-days) }
        if days == 0 { return scoreToday }
        guard effortMinutes > 0 else { return scoreFloor }
        let base = max(scoreFloor, 8 - log(Double(days) + 1) * 1.5)
        let workload = Double(effortMinutes) / max(1e-9, Double(effortMinutes) + Double(days) * 60)
        return min(10, max(scoreFloor, (base / 8) * 10 * workload))
    }

    /// `computeTopScorePreview(outcome, perspiration, dueDate)`.
    static func topScore(outcome: Int, perspiration: Int, dueDate: Date?, now: Date = Date()) -> Double {
        let level = clampLevel(perspiration)
        return timePressure(dueDate: dueDate, effortMinutes: minutes(forPerspiration: level), now: now) * Double(outcome) / Double(level)
    }

    /// `getTOPScore(task)`, computed locally rather than read from `top_score`: the server only
    /// materialises the score on write (there is no cron), so a stored value goes stale the moment
    /// the due date passes and the list would disagree with the editor's live preview. The inputs
    /// default exactly as the backend's SQL does (null outcome / perspiration → 1), so the local
    /// value is what the server would store now. The stored score is only a fallback for rows that
    /// carry none of the inputs.
    static func topScore(of task: ToDoTask, now: Date = Date()) -> Double {
        // Web `getTOPScore`: a completed task must not compete with active ones for ranking. The
        // server keeps the score it had on completion (an overdue "TOP 115" outranks every open
        // task forever), so without this a finished task wins every SMART sort it appears in.
        if task.isCompleted { return completedScore }
        let hasInputs = task.outcome != nil || task.perspiration_level != nil || task.due_date != nil
        if !hasInputs, let stored = task.top_score { return stored }
        return topScore(outcome: task.effectiveOutcome, perspiration: task.effectivePerspiration,
                        dueDate: ToDoDates.parse(task.due_date), now: now)
    }

    /// `resolveTaskDurationSeconds`: an explicit duration wins, else the perspiration's minutes.
    static func durationSeconds(explicit: Int?, perspiration: Int) -> Int {
        if let explicit = explicit, explicit > 0 { return explicit }
        return minutes(forPerspiration: clampLevel(perspiration)) * 60
    }

    /// One decimal place, like the web's `roundToDecimals`.
    static func rounded(_ score: Double) -> String {
        let value = (score * 10).rounded() / 10
        return value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// MARK: - Natural-language due-date input ("2d", "fri", "28 sep", "25/9", "in 2 days")

/// Turns typed due dates into a local calendar day. A superset of the web's `parseSnoozeInput`
/// (`utils/snooze-date.util.ts`), shared by the task editor, the row popover and the new-project
/// sheet. Grammar (case-insensitive, English keywords plus the app language's month / weekday names):
///
///   today · tomorrow (hoy · mañana) → that day
///   Nd / Nw / Nm / Ny · in N days… → now + N days / weeks / months / years. `m` is MONTHS, never
///                                 minutes — this grammar has no times in it at all. The longer
///                                 spellings `parseSnoozeDate` takes are accepted too (mo, wk, yr).
///   -1d / -2w / -1m / -1y       → back the same way, for a date that has already passed
///   fri · friday · next fri     → the next occurrence of that weekday, never today
///   28 · 28th                   → that day of this month if still ahead, else next month
///   28 sep · sep 28 · 28th sep  → that date this year if not already past, else next year
///   25/9 · 25/9/2027            → day/month[/year] (month/day is accepted when the day can't be a month)
///   2026-09-25                  → that exact day
///
/// Anything else is nil so the caller can leave the date untouched.
enum ToDoDueDateParser {
    private static let todayKeywords: Set<String> = ["today", "tod", "hoy"]
    private static let tomorrowKeywords: Set<String> = ["tomorrow", "tom", "tmr", "mañana", "manana"]
    private static let englishWeekdays: [String: Int] = [
        "sun": 1, "sunday": 1, "mon": 2, "monday": 2, "tue": 3, "tues": 3, "tuesday": 3,
        "wed": 4, "weds": 4, "wednesday": 4, "thu": 5, "thur": 5, "thurs": 5, "thursday": 5,
        "fri": 6, "friday": 6, "sat": 7, "saturday": 7,
    ]
    private static let englishMonths: [String: Int] = [
        "jan": 1, "january": 1, "feb": 2, "february": 2, "mar": 3, "march": 3, "apr": 4, "april": 4,
        "may": 5, "jun": 6, "june": 6, "jul": 7, "july": 7, "aug": 8, "august": 8,
        "sep": 9, "sept": 9, "september": 9, "oct": 10, "october": 10, "nov": 11, "november": 11,
        "dec": 12, "december": 12,
    ]
    private static let ordinalSuffix = "(?:st|nd|rd|th)?"
    /// The sign is optional so a due date can be moved backwards: "-1d" is yesterday, "-2w" a
    /// fortnight ago. Backdating is how an overdue task gets marked overdue on the day it was
    /// actually due.
    private static let relativePattern = "^(?:in\\s+)?([+-]?\\d+)\\s*(days?|d|weeks?|wks?|w|months?|mo|m|years?|yrs?|y)$"
    private static let weekdayPattern = "^(?:next\\s+)?([\\p{L}.]+)$"
    private static let dayOfMonthPattern = "^(\\d{1,2})\(ordinalSuffix)$"
    private static let isoPattern = "^(\\d{4})-(\\d{1,2})-(\\d{1,2})$"
    private static let numericDatePattern = "^(\\d{1,2})[/.-](\\d{1,2})(?:[/.-](\\d{2,4}))?$"
    private static let dayMonthPattern = "^(\\d{1,2})\(ordinalSuffix)\\s+([\\p{L}.]+)(?:\\s+(\\d{4}))?$"
    private static let monthDayPattern = "^([\\p{L}.]+)\\s+(\\d{1,2})\(ordinalSuffix)(?:,?\\s+(\\d{4}))?$"
    private static let monthsPerYear = 12
    private static let longestMonthDays = 31
    private static let twoDigitYearBase = 2000

    static func parse(_ raw: String, now: Date = Date(), calendar: Calendar = .current,
                      locale: Locale = Locale(identifier: currentLanguageCode)) -> Date? {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        guard !input.isEmpty else { return nil }
        let today = calendar.startOfDay(for: now)
        if todayKeywords.contains(input) { return today }
        if tomorrowKeywords.contains(input) { return calendar.date(byAdding: .day, value: 1, to: today) }
        let names = LocalizedNames(calendar: calendar, locale: locale)
        if let date = parseRelative(input, from: today, calendar: calendar) { return date }
        if let date = parseWeekday(input, from: today, calendar: calendar, names: names) { return date }
        if let date = parseDayOfMonth(input, from: today, calendar: calendar) { return date }
        if let date = parseISODay(input, calendar: calendar) { return date }
        if let date = parseNumericDate(input, from: today, calendar: calendar) { return date }
        if let date = parseDayAndMonthName(input, from: today, calendar: calendar, names: names) { return date }
        return nil
    }

    /// Month / weekday names of the app language, so "vie" or "sept" work alongside the English ones.
    private struct LocalizedNames {
        let weekdays: [String: Int]
        let months: [String: Int]

        init(calendar: Calendar, locale: Locale) {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = locale
            var weekdays = ToDoDueDateParser.englishWeekdays
            for symbols in [formatter.weekdaySymbols ?? [], formatter.shortWeekdaySymbols ?? []] {
                for (index, symbol) in symbols.enumerated() { weekdays[LocalizedNames.key(symbol)] = index + 1 }
            }
            var months = ToDoDueDateParser.englishMonths
            for symbols in [formatter.monthSymbols ?? [], formatter.shortMonthSymbols ?? [], formatter.standaloneMonthSymbols ?? [], formatter.shortStandaloneMonthSymbols ?? []] {
                for (index, symbol) in symbols.enumerated() { months[LocalizedNames.key(symbol)] = index + 1 }
            }
            self.weekdays = weekdays
            self.months = months
        }

        /// Locales abbreviate with a trailing dot ("sept."); typed input rarely includes it.
        static func key(_ symbol: String) -> String {
            symbol.lowercased().replacingOccurrences(of: ".", with: "")
        }
    }

    private static func groups(_ pattern: String, in input: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else { return nil }
        return (1..<match.numberOfRanges).map { Range(match.range(at: $0), in: input).map { String(input[$0]) } }
    }

    /// "2d", "3 weeks", "in 2 days", "1m", and backwards: "-1d" (yesterday), "-2w".
    private static func parseRelative(_ input: String, from today: Date, calendar: Calendar) -> Date? {
        guard let groups = groups(relativePattern, in: input), let amount = Int(groups[0] ?? ""), let unit = groups[1]?.first else { return nil }
        let component: Calendar.Component
        switch unit {
        case "d": component = .day
        case "w": component = .weekOfYear
        case "y": component = .year
        default: component = .month
        }
        return calendar.date(byAdding: component, value: amount, to: today)
    }

    /// "fri", "friday", "next fri" — the next occurrence, never today ("next" reads the same because
    /// a bare weekday already means the coming one).
    private static func parseWeekday(_ input: String, from today: Date, calendar: Calendar, names: LocalizedNames) -> Date? {
        guard let groups = groups(weekdayPattern, in: input), let name = groups[0],
              let weekday = names.weekdays[LocalizedNames.key(name)] else { return nil }
        let current = calendar.component(.weekday, from: today)
        var delta = (weekday - current + 7) % 7
        if delta == 0 { delta = 7 }
        return calendar.date(byAdding: .day, value: delta, to: today)
    }

    /// "28", "28th" — this month while the day is still ahead, else next month; clamped to the
    /// target month's length.
    private static func parseDayOfMonth(_ input: String, from today: Date, calendar: Calendar) -> Date? {
        guard let groups = groups(dayOfMonthPattern, in: input), let day = Int(groups[0] ?? ""), (1...longestMonthDays).contains(day) else { return nil }
        let todayDay = calendar.component(.day, from: today)
        var monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        var daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 31
        if day <= todayDay || day > daysInMonth {
            monthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 31
        }
        return calendar.date(byAdding: .day, value: min(day, daysInMonth) - 1, to: monthStart)
    }

    private static func parseISODay(_ input: String, calendar: Calendar) -> Date? {
        guard let groups = groups(isoPattern, in: input) else { return nil }
        return exactDay(year: Int(groups[0] ?? ""), month: Int(groups[1] ?? ""), day: Int(groups[2] ?? ""), calendar: calendar)
    }

    /// "25/9", "25.9.2027", "9/25" (swapped when only that reading is a valid date).
    private static func parseNumericDate(_ input: String, from today: Date, calendar: Calendar) -> Date? {
        guard let groups = groups(numericDatePattern, in: input), var day = Int(groups[0] ?? ""), var month = Int(groups[1] ?? "") else { return nil }
        if month > monthsPerYear, day <= monthsPerYear { swap(&day, &month) }
        if let yearText = groups[2], let year = Int(yearText) {
            return exactDay(year: yearText.count == 2 ? twoDigitYearBase + year : year, month: month, day: day, calendar: calendar)
        }
        return upcomingDay(month: month, day: day, from: today, calendar: calendar)
    }

    /// "28 sep", "28th september", "sep 28", "sept 28, 2027".
    private static func parseDayAndMonthName(_ input: String, from today: Date, calendar: Calendar, names: LocalizedNames) -> Date? {
        var day: Int?, month: Int?, year: Int?
        if let groups = groups(dayMonthPattern, in: input) {
            day = Int(groups[0] ?? "")
            month = groups[1].flatMap { names.months[LocalizedNames.key($0)] }
            year = groups[2].flatMap { Int($0) }
        } else if let groups = groups(monthDayPattern, in: input) {
            month = groups[0].flatMap { names.months[LocalizedNames.key($0)] }
            day = Int(groups[1] ?? "")
            year = groups[2].flatMap { Int($0) }
        }
        guard let resolvedDay = day, let resolvedMonth = month else { return nil }
        if let year = year { return exactDay(year: year, month: resolvedMonth, day: resolvedDay, calendar: calendar) }
        return upcomingDay(month: resolvedMonth, day: resolvedDay, from: today, calendar: calendar)
    }

    /// A month/day without a year: this year unless that day has already passed, then next year.
    private static func upcomingDay(month: Int, day: Int, from today: Date, calendar: Calendar) -> Date? {
        let year = calendar.component(.year, from: today)
        guard let thisYear = exactDay(year: year, month: month, day: day, calendar: calendar) else { return nil }
        if thisYear >= today { return thisYear }
        return exactDay(year: year + 1, month: month, day: day, calendar: calendar)
    }

    /// Nil for impossible dates (31 Feb, month 13) rather than Foundation's silent roll-over.
    private static func exactDay(year: Int?, month: Int?, day: Int?, calendar: Calendar) -> Date? {
        guard let year = year, let month = month, let day = day else { return nil }
        let components = DateComponents(year: year, month: month, day: day)
        guard components.isValidDate(in: calendar), let date = calendar.date(from: components) else { return nil }
        return calendar.startOfDay(for: date)
    }
}

/// Project tags — the grouping labels stored in `projects.metadata.tags` (backend#2412).
///
/// Tags exist so several projects can sit under one heading (`RCT`, thesis writing and ethics all
/// under `#phd`) and the Projects screen can narrow to one area of life. That is why the server
/// indexes them and offers `GET /projects?tag=`, and why this client keeps the stored form identical
/// to the server's: what the user sees here is exactly what a filter will match.
///
/// The rules mirror `normalizeProjectTags` and the DTO's validator on the server. Normalizing on the
/// client too is not belt-and-braces — it is what stops the UI showing `PhD` for a second before the
/// server answers `phd`, and what keeps a 26th tag from being silently dropped after a round trip.
enum ProjectTags {
    /// Matches `MAX_PROJECT_TAGS` on the server; a 26th tag is a 400, so it is refused here instead.
    static let maxCount = 25
    /// Matches `MAX_PROJECT_TAG_LENGTH`. Measured on the folded form, as the server does.
    static let maxLength = 64

    /// The stored form of one typed tag, or nil when it is blank. Lower-cased because the server
    /// folds: `#PhD` and `#phd` are one heading, and a filter matches the folded value.
    static func normalize(_ raw: String) -> String? {
        let folded = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !folded.isEmpty else { return nil }
        return String(folded.prefix(maxLength))
    }

    /// A whole tag list in stored form: normalized, de-duplicated (first occurrence wins, as the
    /// server does) and capped.
    static func normalize(_ raw: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for tag in raw {
            guard let normalized = normalize(tag), seen.insert(normalized).inserted else { continue }
            result.append(normalized)
            if result.count == maxCount { break }
        }
        return result
    }

    /// `tags` with `raw` added, or nil when it would change nothing — blank, already present, or the
    /// list is already full. A nil answer means "do not call the server".
    static func adding(_ raw: String, to tags: [String]) -> [String]? {
        guard let tag = normalize(raw) else { return nil }
        let current = normalize(tags)
        guard !current.contains(tag), current.count < maxCount else { return nil }
        return current + [tag]
    }

    /// `tags` without `raw`, or nil when it is not there at all.
    static func removing(_ raw: String, from tags: [String]) -> [String]? {
        guard let tag = normalize(raw) else { return nil }
        let current = normalize(tags)
        guard current.contains(tag) else { return nil }
        return current.filter { $0 != tag }
    }

    /// Every tag in use across `projects`, in stored form, for the "add" popover's suggestions.
    ///
    /// Sorted rather than ranked: the point is recognising a heading you already use, and a stable
    /// order is easier to scan than a frequency one that reshuffles. This is also the list a tag
    /// filter would drive later, which is why it reads from the projects the store already holds
    /// rather than asking the server for a vocabulary that does not exist.
    static func known(in projects: [Project]) -> [String] {
        Set(projects.flatMap { normalize($0.tagList) }).sorted()
    }
}

/// What the line beneath a due-date field shows while the user types.
enum ToDoDueDatePreview: Equatable {
    /// Nothing typed and no due date yet — the line stays blank.
    case blank
    /// A day to render: the live parse of what is being typed, or the date already saved.
    case day(Date)
    /// The typed text is not a date the grammar understands.
    case unrecognised
}

/// Resolves that line without touching the saved date, so typing previews rather than commits.
///
/// `hasSettled` is what keeps the red hint from strobing: typing "28th" passes through the
/// unparseable "2", "28t", and only once typing pauses (or Return is pressed) does the caller
/// pass `true` and let the hint show. Until then an unparseable draft keeps showing the saved
/// date, which is still what a lost focus would leave behind.
enum ToDoDueDatePreviewResolver {
    static func preview(input: String, committedDay: Date?, hasSettled: Bool, now: Date = Date(),
                        calendar: Calendar = .current,
                        locale: Locale = Locale(identifier: currentLanguageCode)) -> ToDoDueDatePreview {
        let typed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // An emptied field falls back to the saved date rather than accusing the user of nonsense.
        guard !typed.isEmpty else { return committedDay.map(ToDoDueDatePreview.day) ?? .blank }
        if let parsed = ToDoDueDateParser.parse(typed, now: now, calendar: calendar, locale: locale) {
            return .day(parsed)
        }
        guard hasSettled else { return committedDay.map(ToDoDueDatePreview.day) ?? .blank }
        return .unrecognised
    }
}

/// The text inside the typed due-date field, which is the date itself rather than an empty box
/// behind a placeholder (report 2026-09-15_19-50-02).
///
/// Two rules, kept pure so they can be tested without a window:
///  - `text(for:)` writes a day in a form `ToDoDueDateParser` reads back, so what the field shows is
///    what the next save sends. "Fri 11 Sep" would not: the grammar has no reading for a leading
///    weekday name.
///  - `reseed(current:day:)` re-syncs the text when the day moved for some *other* reason — the
///    calendar picker, a forecast suggestion — while leaving the user's own half-typed text alone.
///    Without the second rule, typing "2" (on the way to "2d") would rewrite the field to "2 Oct
///    2026" under the caret.
enum ToDoDueDateFieldText {
    static func text(for day: Date?) -> String { day.map(ToDoDates.dayMonthYear) ?? "" }

    /// The text the field should switch to, or nil when the typed text already means `day`.
    static func reseed(current: String, day: Date?, now: Date = Date(), calendar: Calendar = .current,
                       locale: Locale = Locale(identifier: currentLanguageCode)) -> String? {
        let typed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        let typedDay = typed.isEmpty ? nil : ToDoDueDateParser.parse(typed, now: now, calendar: calendar, locale: locale)
        guard typedDay != day else { return nil }
        return text(for: day)
    }
}

// MARK: - Sorting / filtering

/// Web `FilterDataProps` (the parts that filter client-side).
struct ToDoFilters: Equatable {
    enum EnergyLevel: String, CaseIterable {
        case low, full
        /// Web: low = perspiration 0…3, full = 4…10.
        var range: ClosedRange<Int> { self == .low ? 0...3 : 4...10 }
    }

    var projectId: String? = nil
    var energyLevel: EnergyLevel? = nil
    var dueDateStart: Date? = nil
    var dueDateEnd: Date? = nil

    var isActive: Bool { projectId != nil || energyLevel != nil || dueDateStart != nil || dueDateEnd != nil }

    /// Web `getFilteredTasks`: project (by tag / project_id), energy level and due-date range.
    func matches(_ task: ToDoTask) -> Bool {
        if let projectId = projectId, !projectId.isEmpty {
            let carries = task.project_id == projectId || task.tagList.contains { $0.id == projectId }
            if !carries { return false }
        }
        if let level = energyLevel, !level.range.contains(task.perspiration_level ?? 1) { return false }
        if dueDateStart != nil || dueDateEnd != nil {
            guard let due = ToDoDates.parse(task.due_date) else { return false }
            let calendar = Calendar.current
            if let start = dueDateStart, due < calendar.startOfDay(for: start) { return false }
            if let end = dueDateEnd, let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end)), due >= endOfDay { return false }
        }
        return true
    }
}

enum ToDoSorting {
    /// Web `sortTasksBySortMode` — the API order is never trusted after client-side merges.
    static func sort(_ tasks: [ToDoTask], by mode: ToDoSortMode, now: Date = Date()) -> [ToDoTask] {
        switch mode {
        case .dueDate:
            return tasks.enumerated().sorted { lhs, rhs in
                let l = ToDoDates.parse(lhs.element.due_date)?.timeIntervalSince1970 ?? .infinity
                let r = ToDoDates.parse(rhs.element.due_date)?.timeIntervalSince1970 ?? .infinity
                return l == r ? lhs.offset < rhs.offset : l < r
            }.map { $0.element }
        case .chronological:
            return tasks.enumerated().sorted { lhs, rhs in
                let l = ToDoDates.parse(lhs.element.created_at)?.timeIntervalSince1970 ?? 0
                let r = ToDoDates.parse(rhs.element.created_at)?.timeIntervalSince1970 ?? 0
                return l == r ? lhs.offset < rhs.offset : l > r
            }.map { $0.element }
        case .smart:
            return tasks.enumerated().sorted { lhs, rhs in
                let l = ToDoScoring.topScore(of: lhs.element, now: now)
                let r = ToDoScoring.topScore(of: rhs.element, now: now)
                return l == r ? lhs.offset < rhs.offset : l > r
            }.map { $0.element }
        }
    }
}

// MARK: - Sections (Doing / To do / Done + custom project columns)

/// One accordion section of the list. `status` is nil for a custom project-status column.
struct ToDoSection: Identifiable, Equatable {
    var id: String
    var title: String
    var status: ToDoStatus?
    var tasks: [ToDoTask]

    /// The section's tasks as list rows, each identified by section AND task.
    var rows: [ToDoSectionRow] { tasks.map { ToDoSectionRow(sectionId: id, task: $0) } }
}

/// One task drawn as a row of one section.
///
/// The list is a `LazyVStack` of sections, each an optional nested `ForEach`. Keyed by the task id
/// alone, a task that moved section kept its identity, and the lazy stack reused the row it had
/// cached for it: a to-do completed from Doing showed under Done with an empty circle, no
/// strike-through and its TOP score, and neither its checkbox nor selecting it acted on the
/// completed task (#2681). Scoping the identity to the section makes a moved task a new row.
struct ToDoSectionRow: Identifiable, Equatable {
    let sectionId: String
    let task: ToDoTask

    var id: String { "\(sectionId)/\(task.id)" }
}

enum ToDoSectioning {
    /// Web default order: Doing, To do, Done.
    static let defaultOrder: [ToDoStatus] = [.inProgress, .notStarted, .completed]

    /// Web alias map: a project column named like a default status folds into that default section.
    private static let aliases: [ToDoStatus: [String]] = [
        .notStarted: ["to do", "todo", "not started", "not-started"],
        .inProgress: ["doing", "in progress", "in-progress", "inprogress"],
        .completed: ["done", "completed", "finished"],
    ]

    static func normalized(_ label: String) -> String { label.trimmingCharacters(in: .whitespaces).lowercased() }

    /// Web `partitionCustomTasksForTodosPage` + `mergeCustomStatusSectionsByLabel` +
    /// `buildTodosPageDisplayTasksByStatus`: tasks in an aliased project column stay in their default
    /// section; other custom columns become extra sections merged by label across projects. A
    /// completed task always reads as done (see `ProjectKanban.columnId`).
    static func build(tasks: [ToDoTask], projects: [Project], sortMode: ToDoSortMode,
                      sectionTitles: [ToDoStatus: String], now: Date = Date()) -> [ToDoSection] {
        var labelsByStatusId: [String: String] = [:]
        var completingStatusIds = Set<String>()
        for project in projects {
            for status in project.customStatuses {
                labelsByStatusId[status.id] = status.label
                if status.should_complete_task ?? false { completingStatusIds.insert(status.id) }
            }
        }
        var aliasLookup: [String: ToDoStatus] = [:]
        for (status, names) in aliases { for name in names { aliasLookup[name] = status } }
        for (status, title) in sectionTitles { aliasLookup[normalized(title)] = status }

        var byStatus: [ToDoStatus: [ToDoTask]] = [:]
        var custom: [String: (label: String, tasks: [ToDoTask])] = [:]
        for task in tasks {
            if let customId = task.custom_status_id, let label = labelsByStatusId[customId] {
                // Completed elsewhere while the custom id still names an open column: Done, not the column.
                if task.isCompleted, !completingStatusIds.contains(customId) {
                    byStatus[.completed, default: []].append(task)
                    continue
                }
                let key = normalized(label)
                if let aliased = aliasLookup[key] {
                    byStatus[aliased, default: []].append(task)
                } else {
                    custom[key, default: (label: label.trimmingCharacters(in: .whitespaces), tasks: [])].tasks.append(task)
                }
            } else {
                byStatus[task.defaultStatus, default: []].append(task)
            }
        }
        var sections = defaultOrder.map { status in
            ToDoSection(id: status.rawValue, title: sectionTitles[status] ?? status.rawValue, status: status,
                        tasks: ToDoSorting.sort(unique(byStatus[status] ?? []), by: sortMode, now: now))
        }
        for key in custom.keys.sorted(by: { custom[$0]!.label.localizedCaseInsensitiveCompare(custom[$1]!.label) == .orderedAscending }) {
            let entry = custom[key]!
            sections.append(ToDoSection(id: "custom__\(key)", title: entry.label, status: nil,
                                        tasks: ToDoSorting.sort(unique(entry.tasks), by: sortMode, now: now)))
        }
        return sections
    }

    private static func unique(_ tasks: [ToDoTask]) -> [ToDoTask] {
        var seen = Set<String>()
        return tasks.filter { seen.insert($0.id).inserted }
    }
}

/// The number beside a section heading.
///
/// It used to be the server's `meta.itemCount` for that status bucket, which made the heading and
/// the rows two different answers to the same question: "Doing 1" could sit above "No tasks in this
/// What the To-do screen's footer "Close" button should do.
///
/// It used to always close the window. Inside a project's notes that reads as the whole app
/// disappearing — the window is the app's only visible surface — when the user meant "close this
/// note and go back" (report 2026-09-14_19-4x). Close now steps back one level at a time, and only
/// dismisses the screen once there is nothing left to step back from.
enum ToDoCloseStep: Equatable {
    case closeNote, closeProject, closeScreen

    static func next(hasOpenNote: Bool, hasOpenProject: Bool) -> ToDoCloseStep {
        if hasOpenNote { return .closeNote }
        if hasOpenProject { return .closeProject }
        return .closeScreen
    }
}

/// section". They disagree because a fetched row does not have to end up in the section it was
/// fetched for — `ToDoSectioning.build` re-partitions by the project column a task carries, so an
/// IN_PROGRESS task in a column named "Blocked" leaves Doing for a section of its own — and because
/// an undecodable row (`ToDoPage.receivedRowCount`) never becomes a row at all.
///
/// So the server total is trusted only for what it alone knows: the rows still unfetched behind
/// paging. Everything already delivered is counted by what the section renders. "To do 145" with 50
/// loaded still reads 145; a Doing bucket whose only task moved elsewhere now reads 0, and the
/// heading can no longer promise a task the user cannot reach.
enum ToDoSectionCount {
    static func headerCount(rendered: Int, serverItemCount: Int?, rowsReceived: Int) -> Int {
        guard let serverItemCount = serverItemCount else { return rendered }
        return rendered + max(0, serverItemCount - rowsReceived)
    }
}

// MARK: - Effective completion

/// Whether a to-do reads as finished, wherever it was completed.
///
/// Status FIRST, deliberately. Completing a task from the Day Plan, the To-do list, the routine
/// player or another device sets `status` alone and leaves `custom_status_id` on whatever open
/// column the task was sitting in. `ProjectKanban.columnId` and `ToDoSectioning.build` already draw
/// those rows as done, so any other reading of the same row contradicts what the user is looking at
/// — which is how the forecast came to plan work the user had already ticked off
/// (report 2026-09-15_17-41-45).
enum ToDoCompletionState {
    /// Custom column ids, across any number of projects, whose tasks count as finished.
    static func completingStatusIds(in projects: [Project]) -> Set<String> {
        Set(projects.flatMap { $0.customStatuses }
            .filter { $0.should_complete_task ?? false }
            .map { $0.id })
    }

    static func isFinished(_ task: ToDoTask, completingStatusIds: Set<String>) -> Bool {
        if task.isCompleted { return true }
        guard let columnId = task.custom_status_id, !columnId.isEmpty else { return false }
        return completingStatusIds.contains(columnId)
    }

    static func isFinished(_ task: ToDoTask, customStatuses: [ProjectCustomStatus]) -> Bool {
        isFinished(task, completingStatusIds: Set(customStatuses.filter { $0.should_complete_task ?? false }.map(\.id)))
    }

    /// What a completion write should do with the to-do's board column.
    enum ColumnWrite: Equatable {
        /// Omit `custom_status_id` from the PUT, so the backend keeps whatever it has. The right
        /// answer whenever we cannot improve on the stored column.
        case leaveAlone
        /// Send this column id alongside the new status, in the same write.
        case move(to: String)
    }

    /// Where a to-do should sit after being completed (or re-opened) outside the project board —
    /// from the Day Plan, the routine player or the focus session.
    ///
    /// Completing has to move the card as well as flip the status. Setting the status alone leaves
    /// the task in whatever open column it was in, which is how five finished tasks kept reading as
    /// outstanding on the kanban, on web and on mobile (report 2026-09-15_17-41-45, "why are tasks
    /// remaining in ToDo when they were completed?").
    ///
    /// - A completion moves to the project's **first** column flagged `should_complete_task`, which
    ///   is the column the kanban checkbox uses (`ProjectKanban.doneStatus`), so the same task lands
    ///   in the same place whichever screen ticked it.
    /// - A project with **no** completing column is left alone. `ProjectKanban.doneStatus` falls back
    ///   to the project's last column; that fallback must not be used here, because parking a
    ///   finished task in a non-completing column is exactly the state that makes the server call it
    ///   outstanding. Leaving the column untouched keeps `status` as the only signal, which is what
    ///   happens today and is read correctly.
    /// - Re-opening moves back to the project's first column, but ONLY from a completing one. A task
    ///   the user had in "In Progress" must not be dragged back to "To Do" by an un-tick, and a task
    ///   left sitting in "Done" while its status says NOT_STARTED is the same inconsistency mirrored.
    static func columnWrite(completed: Bool, currentColumnID: String?,
                            customStatuses: [ProjectCustomStatus]) -> ColumnWrite {
        let ordered = customStatuses.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
        guard let completing = ordered.first(where: { $0.should_complete_task ?? false }) else { return .leaveAlone }
        if completed {
            return currentColumnID == completing.id ? .leaveAlone : .move(to: completing.id)
        }
        // Only a column we know finishes tasks is worth undoing.
        guard let current = currentColumnID,
              ordered.contains(where: { $0.id == current && ($0.should_complete_task ?? false) }),
              let first = ordered.first, first.id != current else { return .leaveAlone }
        return .move(to: first.id)
    }
}

// MARK: - Status toggle (checkbox)

enum ToDoStatusToggle {
    /// Web `buildProjectDetailsTaskStatusToggle`: with custom columns the task moves to the project's
    /// done column or back to the first column; without them the default status flips and any custom
    /// id is dropped.
    ///
    /// Completing uses the first column flagged `should_complete_task` and nothing else. Web's
    /// `resolveProjectKanbanColumnId` falls back to the project's LAST column when none completes,
    /// and `ProjectKanban.doneStatus` keeps that fallback for rendering — but writing it would park a
    /// finished task in a column the server reads as open, which is how completed work kept showing
    /// as outstanding (report 2026-09-15_17-41-45). Nothing is lost by not writing it:
    /// `ProjectKanban.columnId` already draws a COMPLETED task under the done column whatever its
    /// stored id, so the card lands in the same place either way.
    static func apply(to task: ToDoTask, completed: Bool, customStatuses: [ProjectCustomStatus]) -> ToDoTask {
        var updated = task
        updated.status = completed ? ToDoStatus.completed.rawValue : ToDoStatus.notStarted.rawValue
        let ordered = customStatuses.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
        guard !ordered.isEmpty else {
            updated.custom_status_id = nil
            return updated
        }
        guard completed else {
            updated.custom_status_id = ordered.first?.id
            return updated
        }
        if let completing = ordered.first(where: { $0.should_complete_task ?? false }) {
            updated.custom_status_id = completing.id
        }
        return updated
    }
}

// MARK: - Upsert body (PUT /to-do)

enum ToDoUpsertBody {
    /// Web `persistToDoTask` PUTs the whole task; this sends the writable subset of `CreateToDoDto`
    /// (read-only fields like `top_score` / `assignee` / `external_task_status` are left out). Keys
    /// with a nil value are sent as JSON null so the backend clears them (`hasDtoProperty`).
    static func make(from task: ToDoTask, clearOutcome: Bool = false) -> [String: Any] {
        var body: [String: Any] = [
            "id": task.id,
            "title": task.title,
            "details": task.details ?? "",
            "objective": task.objective ?? "",
            "status": task.status,
            "eisenhower_quadrant": task.eisenhower_quadrant ?? EisenhowerQuadrant.doIt.rawValue,
            "tags": task.tagList.map { ["id": $0.id, "text": $0.text] },
            "subtasks": task.subtaskList.map { ["name": $0.name, "is_completed": $0.is_completed] as [String: Any] },
            "duration": task.durationSeconds,
            "custom_status_id": task.custom_status_id ?? NSNull(),
            "project_id": task.project_id ?? NSNull(),
        ]
        // An explicit null clears the date; the DTO's @IsDate would reject an empty string.
        body["due_date"] = task.due_date.flatMap { $0.isEmpty ? nil : $0 } ?? NSNull()
        if let outcome = task.outcome { body["outcome"] = outcome }
        else if clearOutcome { body["outcome"] = NSNull() }
        if let perspiration = task.perspiration_level { body["perspiration_level"] = perspiration }
        if let icon = task.icon, !icon.isEmpty { body["icon"] = icon }
        if let focusType = task.focus_type, !focusType.isEmpty { body["focus_type"] = focusType }
        if let externalId = task.external_task_id, !externalId.isEmpty { body["external_task_id"] = externalId }
        if let synced = task.synced_project_id, !synced.isEmpty { body["synced_project_id"] = synced }
        // Explicit null clears the assignment — the picker has an "Unassigned" option, so nil here
        // really is the user's choice.
        // `assignee_id == nil` means UNASSIGNED here, and nothing else. Resolving it from the
        // `assignee` relation at this point would make nil ambiguous — "the user chose Unassigned"
        // and "the server never sent the flat field" would look identical — and the picker's
        // Unassigned option would stop working. Callers holding a task straight off the wire must
        // resolve the two shapes BEFORE they get here (see `ToDoDraft.editable` and
        // `ProjectDetailStore.persist`).
        body["assignee_id"] = task.assignee_id ?? NSNull()
        // Not so for the MCP token: nothing in this app can read or set it, and `GET /to-do` never
        // returns it, so nil only ever means "this client never knew". Sending null unconditionally
        // wiped an agent's claim on the task every time a human opened it and pressed Save.
        if let mcpToken = task.assigned_mcp_token_id, !mcpToken.isEmpty {
            body["assigned_mcp_token_id"] = mcpToken
        }
        return body
    }
}

// MARK: - Who a task is assigned to

/// One entry in an assignee picker.
struct ToDoAssigneeOption: Equatable {
    let id: String
    let label: String
}

/// The rules an assignee picker follows, shared by the to-do editor and the Day Plan's task details so
/// the two cannot come to mean different things by "Assignee" (report 2026-09-17_09-01-33).
enum ToDoAssigneeChoices {
    /// What a picker uses for "nobody". Empty rather than nil so it can be an `NSMenuItem` tag or a
    /// SwiftUI `.tag` without needing a second optional case.
    static let unassignedTag = ""

    /// The assignee id, read from whichever shape the server sent.
    ///
    /// `GET /to-do` returns the assignee as a RELATION (`assignee: { id, username }`) and carries no
    /// flat `assignee_id` key at all — backend#2414, still open, so this is the live contract. Reading
    /// only the flat field showed every assigned task as Unassigned, and because the save sends
    /// `assignee_id`, pressing Save on an assigned task then silently unassigned it server-side. Flat
    /// first where it exists, relation as the fallback that actually fires in production.
    static func assigneeId(flat: String?, relation relationId: String?) -> String? {
        [flat, relationId].compactMap { $0 }.first { !$0.isEmpty }
    }

    /// Me, then the project's accepted members, then whoever the task is assigned to if that is
    /// somebody neither list knows — so an existing assignment is never quietly dropped from the menu.
    static func options(me: ToDoAssigneeOption?, members: [ToDoAssigneeOption],
                        current: ToDoAssigneeOption?) -> [ToDoAssigneeOption] {
        var options: [ToDoAssigneeOption] = []
        var seen = Set<String>()
        for candidate in [me].compactMap({ $0 }) + members + [current].compactMap({ $0 }) {
            guard !candidate.id.isEmpty, !seen.contains(candidate.id) else { continue }
            seen.insert(candidate.id)
            options.append(candidate)
        }
        return options
    }

    /// Is this task somebody ELSE's work?
    ///
    /// The Day Plan hides those: "if it's assigned to someone else, it shouldn't appear on my day
    /// plan" (report 2026-09-17_09-01-33 follow-up). Deliberately narrow — only a task assigned to a
    /// known other person counts:
    ///
    /// - **Unassigned is not someone else.** Most tasks are unassigned and they are the user's own
    ///   day; treating nil as "not mine" would empty the plan.
    /// - **Assigned to me** obviously stays.
    /// - With **no signed-in user** nothing is hidden. Guessing while the account is unknown would
    ///   blank the day on a cold launch, which is far worse than briefly showing one extra row.
    ///
    /// `assigneeId` must come from `assigneeId(flat:relation:)`. `GET /to-do` sends only the nested
    /// relation (backend#2414), so a caller that reads the flat field alone sees every task as
    /// unassigned and this quietly answers false for all of them.
    static func isAssignedToSomebodyElse(assigneeId: String?, meId: String?) -> Bool {
        guard let assignee = assigneeId, !assignee.isEmpty else { return false }
        guard let me = meId, !me.isEmpty else { return false }
        return assignee != me
    }

    /// Assigning is meaningless in a project the user is alone in — the only option would be
    /// themselves, so the control is noise (report 2026-09-14_19-50-36) and the PO asked for it only
    /// "if the project has other members". It appears as soon as a project has another accepted
    /// member, and stays when the task is already assigned to somebody else so an existing assignment
    /// is never hidden behind a control that is not on screen.
    static func canAssign(options: [ToDoAssigneeOption], currentAssigneeId: String?,
                          meId: String?) -> Bool {
        if let current = currentAssigneeId, !current.isEmpty, current != meId { return true }
        return options.count > 1
    }
}

// MARK: - Editor drafts

/// The task the editor starts from (web `DEFAULT_TODO_NEW_TASK` / `mapTaskToFormData`).
enum ToDoDraft {
    /// A new task: due tomorrow, default TOP levels, quadrant "Do" (the web's silent default now
    /// that the quadrant picker is hidden). Opened from a project detail it is pre-linked to that
    /// project — tag, `project_id` and the project's first column (web `getInitFormData`) — from
    /// the project object itself, never a catalogue lookup that may not know a just-created project.
    /// `dueDate` is the caller's "next free day" from the forecast; without one this still falls back
    /// to tomorrow, which is what it always did.
    static func newTask(title: String, project: Project? = nil, now: Date = Date(),
                        dueDate: Date? = nil) -> ToDoTask {
        let fallback = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let due = dueDate ?? fallback
        var task = ToDoTask(id: UUID().uuidString.lowercased(), title: title, details: "", objective: "",
                            status: ToDoStatus.notStarted.rawValue, due_date: ToDoDates.ymd(due), created_at: "",
                            eisenhower_quadrant: EisenhowerQuadrant.doIt.rawValue, outcome: ToDoScoring.defaultOutcome,
                            perspiration_level: ToDoScoring.defaultPerspiration, tags: [], subtasks: [])
        guard let project = project else { return task }
        task.tags = [ToDoTag(id: project.id, text: project.name)]
        task.project_id = project.id
        task.custom_status_id = project.usesCustomStatuses ? project.orderedStatuses.first?.id : nil
        return task
    }

    /// An existing task as the editor holds it: due date as a local `YYYY-MM-DD`, levels defaulted,
    /// details as plain text, assignee resolved from whichever shape the server sent.
    static func editable(_ task: ToDoTask) -> ToDoTask {
        var copy = task
        copy.due_date = ToDoDates.ymd(fromISO: task.due_date)
        copy.outcome = task.outcome
        copy.perspiration_level = task.perspiration_level ?? ToDoScoring.defaultPerspiration
        copy.details = ToDoHTML.plainText(task.details ?? "")
        // `GET /to-do` returns the assignee as a relation (`assignee: { id, username }`) and carries
        // no flat `assignee_id` key at all — verified against production, where a row the user had
        // just assigned came back with `assignee.id` set and no `assignee_id`. Reading only the flat
        // field showed every assigned task as Unassigned, and since the save sends `assignee_id`
        // unconditionally, the next Save then wiped the assignment (report 2026-09-16_15-14-36).
        copy.assignee_id = ToDoAssigneeChoices.assigneeId(flat: task.assignee_id, relation: task.assignee?.id)
        return copy
    }
}

// MARK: - Server error bodies

/// The message inside a NestJS error body so a failed write can say *why* instead of the generic
/// toast. `message` is a string, an array of strings, or — from the global `ValidationPipe` — an
/// array of `ValidationError` objects whose `constraints` hold the readable reasons.
enum ToDoServerError {
    private static let messageKey = "message"
    private static let constraintsKey = "constraints"
    private static let separator = "; "

    /// A plain-text body longer than this is a proxy's HTML page, not a reason worth showing.
    private static let maxPlainTextLength = 200

    static func message(from data: Data?) -> String? {
        guard let data = data else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return plainText(data)
        }
        if let text = object[messageKey] as? String { return nonEmpty(text) }
        guard let items = object[messageKey] as? [Any] else { return nil }
        let parts = items.flatMap { item -> [String] in
            if let text = item as? String { return [text] }
            guard let error = item as? [String: Any], let constraints = error[constraintsKey] as? [String: Any] else { return [] }
            return constraints.keys.sorted().compactMap { constraints[$0] as? String }
        }
        return nonEmpty(parts.joined(separator: separator))
    }

    /// Not every rejection is JSON. The API's auth layer answers `text/plain` ("Token missing or
    /// corrupted!"), and that body used to be discarded — so a save that failed 401 showed the user
    /// "Could not update task …" with no reason and left no trace in the debug log of why
    /// (report 2026-09-16_15-14-36).
    private static func plainText(_ data: Data) -> String? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.hasPrefix("<"), trimmed.count <= maxPlainTextLength else { return nil }
        return nonEmpty(trimmed)
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - CSV export

enum ToDoCSV {
    /// Web `downloadToDoCSVFile` columns.
    static func build(tasks: [ToDoTask], headers: [String], statusLabel: (ToDoTask) -> String,
                      quadrantLabel: (ToDoTask) -> String) -> String {
        var lines = [headers.map(escape).joined(separator: ",")]
        for task in tasks {
            let row = [
                task.title,
                ToDoHTML.plainText(task.details ?? ""),
                ToDoHTML.plainText(task.objective ?? ""),
                statusLabel(task),
                quadrantLabel(task),
                task.tagList.map { $0.text }.joined(separator: ","),
                task.subtaskList.map { $0.name }.joined(separator: ","),
                task.due_date ?? "",
                task.created_at,
            ]
            lines.append(row.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// Task details can carry HTML from the web editor; the native screen shows plain text.
enum ToDoHTML {
    static func plainText(_ html: String) -> String {
        guard html.contains("<") else { return decodeEntities(html) }
        let stripped = html.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return decodeEntities(stripped).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}

// MARK: - Project permissions (web `utils/projects/project.util.ts`)

enum ProjectPermissions {
    /// `getViewerProjectRole`: the member row's role, else owner when `owner_id` matches.
    static func viewerRole(in project: Project, userId: String?) -> ProjectMemberRole? {
        guard let userId = userId, !userId.isEmpty else { return nil }
        if let role = project.members?.first(where: { $0.user_id == userId })?.memberRole { return role }
        return project.owner_id == userId ? .owner : nil
    }

    static func canManageMembers(_ role: ProjectMemberRole?) -> Bool { role == .owner || role == .admin }
    static func canViewSettings(_ role: ProjectMemberRole?) -> Bool { canManageMembers(role) }
    static func canEditName(_ role: ProjectMemberRole?) -> Bool { role == .owner }
    static func canLeave(_ role: ProjectMemberRole?) -> Bool { role == .admin || role == .member }
    static func canAddTask(_ role: ProjectMemberRole?) -> Bool { role != nil }
    static func canEditTask(_ role: ProjectMemberRole?) -> Bool { canManageMembers(role) }
    static func canDeleteProject(_ role: ProjectMemberRole?) -> Bool { role == .owner }

    /// Moving a task between the board's columns is a change to a task, not to the project, so it
    /// takes the same role as putting a task there in the first place: any member. Someone looking
    /// at a project they do not belong to has no role, and for them the card neither drags nor
    /// offers a "Move to" menu.
    static func canMoveTask(_ role: ProjectMemberRole?) -> Bool { canAddTask(role) }

    struct MemberActions: Equatable {
        var canInvite: Bool
        var canRemove: Bool
        var canChangeRole: Bool
    }

    /// `getProjectMemberActionPermissions`.
    static func memberActions(viewer: ProjectMemberRole?, target: ProjectMemberRole?, isTargetCurrentUser: Bool) -> MemberActions {
        let isOwner = viewer == .owner
        let canInvite = isOwner || viewer == .admin
        let denied = MemberActions(canInvite: canInvite, canRemove: false, canChangeRole: false)
        if !canInvite || isTargetCurrentUser || target == .owner { return denied }
        if target == .admin { return MemberActions(canInvite: canInvite, canRemove: isOwner, canChangeRole: isOwner) }
        return MemberActions(canInvite: canInvite, canRemove: true, canChangeRole: true)
    }
}

// MARK: - Re-sending a project invitation

/// The rules behind the members sheet's "Resend invitation" button.
///
/// There is no dedicated resend endpoint — `POST /projects/:id/members` already *is* the resend: the
/// server updates the existing row, stamps a fresh `invitation_sent_at` and emails the invitation
/// again, refusing only an already-accepted member. So the client's whole job is deciding *when* to
/// offer it, and making a mis-click unable to put a second email in someone else's inbox.
enum ProjectInvitationResend {
    /// How long after an invitation went out before the same one may be sent again. Read from the
    /// server's own `invitation_sent_at`, so it also holds across a restart or a second admin.
    static let cooldownSeconds: TimeInterval = 60
    /// How long the "click again to resend" state stays armed before it disarms itself.
    static let confirmWindowSeconds: TimeInterval = 8

    /// A resend only makes sense while the invitation is still outstanding, and only for someone who
    /// could have sent it in the first place. An accepted member has nothing to re-send (the server
    /// 400s on that), and a declined invitation was answered — re-sending it would be nagging.
    static func canResend(viewer: ProjectMemberRole?, status: ProjectInvitationStatus) -> Bool {
        ProjectPermissions.canManageMembers(viewer) && (status == .pending || status == .failed)
    }

    /// When this invitation last went out, as the server recorded it.
    static func lastSentAt(_ member: ProjectMember) -> Date? { ToDoDates.parse(member.invitation_sent_at) }

    /// Whether enough time has passed since the last send for another one. A row with no recorded
    /// send time (an older invitation) is treated as sendable.
    static func cooldownElapsed(sentAt: Date?, now: Date, cooldown: TimeInterval = cooldownSeconds) -> Bool {
        guard let sentAt = sentAt else { return true }
        return now.timeIntervalSince(sentAt) >= cooldown
    }
}

// MARK: - Project kanban (web `utils/projects/project-details.util.ts`)

/// One board column: a project custom status, or a default `ToDoStatus` when the project has none.
struct ProjectColumn: Identifiable, Equatable {
    var id: String
    var label: String
    var color: String?
    var completes: Bool
}

enum ProjectKanban {
    /// Custom statuses sorted by `order`, else To Do / In Progress / Done.
    static func columns(for project: Project, defaultLabels: [ToDoStatus: String]) -> [ProjectColumn] {
        let ordered = project.orderedStatuses
        if !ordered.isEmpty {
            return ordered.map { ProjectColumn(id: $0.id, label: $0.label, color: $0.color, completes: $0.should_complete_task ?? false) }
        }
        return [ToDoStatus.notStarted, .inProgress, .completed].map {
            ProjectColumn(id: $0.rawValue, label: defaultLabels[$0] ?? $0.rawValue, color: nil, completes: $0 == .completed)
        }
    }

    /// The column that completes a task: the first flagged `should_complete_task`, else the last
    /// (web `buildProjectDetailsTaskStatusToggle` / `resolveProjectKanbanColumnId` fallback).
    static func doneStatus(in ordered: [ProjectCustomStatus]) -> ProjectCustomStatus? {
        ordered.first { $0.should_complete_task ?? false } ?? ordered.last
    }

    static func doneColumn(in columns: [ProjectColumn]) -> ProjectColumn? {
        columns.first { $0.completes } ?? columns.last
    }

    /// `resolveProjectKanbanColumnId`: the task's custom status when it is a column, else the legacy
    /// status → column mapping (first two non-done columns, the done column). One deliberate step
    /// beyond the web: a task whose `status` is COMPLETED but whose custom id still points at an
    /// open column — ticked off from the Day Plan, mobile or a list that didn't know the project's
    /// columns — lands in the done column rather than struck through under "To Do".
    static func columnId(for task: ToDoTask, columns: [ProjectColumn], usesCustomStatuses: Bool) -> String? {
        guard usesCustomStatuses else { return task.defaultStatus.rawValue }
        let done = doneColumn(in: columns)
        if let custom = task.custom_status_id, let column = columns.first(where: { $0.id == custom }) {
            return task.isCompleted && !column.completes ? done?.id : custom
        }
        let open = columns.filter { !$0.completes }
        switch task.defaultStatus {
        case .notStarted: return open.first?.id ?? columns.first?.id
        case .inProgress: return (open.count > 1 ? open[1] : open.first)?.id ?? columns.first?.id
        case .completed: return done?.id
        }
    }

    /// `deriveProjectKanbanStatusFromColumn`: done column → COMPLETED, first column → NOT_STARTED, else IN_PROGRESS.
    static func status(forColumn columnId: String, columns: [ProjectColumn]) -> ToDoStatus {
        guard let index = columns.firstIndex(where: { $0.id == columnId }) else { return .inProgress }
        if columns[index].completes { return .completed }
        return index == 0 ? .notStarted : .inProgress
    }

    /// `buildProjectKanbanMovedTask`.
    static func moved(_ task: ToDoTask, toColumn columnId: String, columns: [ProjectColumn], usesCustomStatuses: Bool) -> ToDoTask {
        var copy = task
        if usesCustomStatuses {
            copy.custom_status_id = columnId
            copy.status = status(forColumn: columnId, columns: columns).rawValue
        } else {
            copy.status = columnId
            copy.custom_status_id = nil
        }
        return copy
    }

    /// `ensureProjectTaskTags`: keep label tags, put the project's own tag last.
    static func tags(for task: ToDoTask, project: Project) -> [ToDoTag] {
        let others = task.tagList.filter { $0.id != project.id }
        let own = task.tagList.first { $0.id == project.id } ?? ToDoTag(id: project.id, text: project.name)
        return others + [own]
    }
}

// MARK: - Dragging a card between columns

/// The geometry behind dragging a task card onto another column.
///
/// The board tracks the drag itself — a `DragGesture` plus the columns' own frames — instead of
/// `onDrag`/`onDrop`. Those sit on `NSDraggingSession`, which draws no drag image and highlights no
/// destination inside this app's windows; the Day Plan hit exactly that and pumps its own mouse loop
/// (`TaskDragHandle`) for the same reason. A board shipped on `onDrag` could not be dragged at all,
/// which is why the same request came back twice (reports 2026-09-09_20-22-27, 2026-09-15_20-13-04).
enum ProjectBoardDrag {
    /// How far the pointer must travel before a press on a card becomes a drag rather than the click
    /// that opens the task editor.
    static let minimumDistance: CGFloat = 4

    /// The column under `point`, whose frames are in the tasks area's own coordinate space.
    ///
    /// The smallest containing frame wins: in list mode a column is a section stacked with the
    /// others and nothing overlaps, but that keeps the answer the column actually under the pointer
    /// rather than whichever happened to be registered first. Ties break on the column id so the
    /// highlight never flickers between two equally sized columns.
    static func columnId(at point: CGPoint, frames: [String: CGRect]) -> String? {
        frames.filter { $0.value.contains(point) }
            .min { lhs, rhs in
                let left = lhs.value.width * lhs.value.height, right = rhs.value.width * rhs.value.height
                return left == right ? lhs.key < rhs.key : left < right
            }?.key
    }
}

/// What a drop (or a "Move to" menu pick) should write, and what the board should hold once the
/// server has answered. Both paths and the tests go through this, so the board cannot drift from the
/// menu and neither can drift from what the server was actually told.
enum ProjectTaskMove {
    /// The task as it will be PUT, or nil when nothing should be written at all: the viewer may not
    /// change this project's tasks, the column is not one of this board's, or the card was dropped
    /// back on the column it came from — a no-op must not cost a request.
    ///
    /// Column and status are decided together by `ProjectKanban.moved` and travel in the one
    /// `ToDoUpsertBody`, so a drop on a `should_complete_task` column completes the task and a drop
    /// on any other column reopens it. That is the mirror of `ToDoStatusToggle.apply`, which moves
    /// the column when a task is completed elsewhere; there is no third rule.
    static func plan(_ task: ToDoTask, toColumn columnId: String, project: Project,
                     columns: [ProjectColumn], canMove: Bool) -> ToDoTask? {
        guard canMove, columns.contains(where: { $0.id == columnId }) else { return nil }
        let current = ProjectKanban.columnId(for: task, columns: columns, usesCustomStatuses: project.usesCustomStatuses)
        guard current != columnId else { return nil }
        var moved = ProjectKanban.moved(task, toColumn: columnId, columns: columns, usesCustomStatuses: project.usesCustomStatuses)
        moved.tags = ProjectKanban.tags(for: moved, project: project)
        moved.project_id = project.isSynced ? moved.project_id : project.id
        return moved
    }

    /// The row the board keeps after the write: what the server stored on success, and the row as it
    /// was before the drag on failure — the card returns to the column it came from instead of
    /// sitting in one the server never accepted.
    static func settled(statusCode: Int, saved: ToDoTask?, attempted: ToDoTask,
                        previous: ToDoTask) -> (task: ToDoTask, failed: Bool) {
        guard (200..<300).contains(statusCode) else { return (previous, true) }
        return (saved ?? attempted, false)
    }
}

// MARK: - Completion banner batching

/// One "Woah, 'X' completed!" banner that absorbs rapid completions instead of stacking: the
/// first completion starts a batch with a random phrase; each further completion within the
/// lifetime bumps the count and restarts the clock; uncompleting a task takes one back.
struct ToDoCompletionBatch: Equatable {
    static let lifetime: TimeInterval = 6

    var phrase: String
    var lastTitle: String
    var count: Int
    var expiresAt: Date

    func isExpired(at now: Date) -> Bool { now >= expiresAt }

    /// Adds a completion to `current` (a fresh batch when there is none or it has expired).
    static func recording(_ title: String, into current: ToDoCompletionBatch?, phrase: String, now: Date) -> ToDoCompletionBatch {
        let expiresAt = now.addingTimeInterval(lifetime)
        guard let current = current, !current.isExpired(at: now) else {
            return ToDoCompletionBatch(phrase: phrase, lastTitle: title, count: 1, expiresAt: expiresAt)
        }
        return ToDoCompletionBatch(phrase: current.phrase, lastTitle: title, count: current.count + 1, expiresAt: expiresAt)
    }

    /// Takes one completion back; nil when the batch is empty or already gone.
    func uncompleting(at now: Date) -> ToDoCompletionBatch? {
        guard !isExpired(at: now), count > 1 else { return nil }
        var copy = self
        copy.count -= 1
        return copy
    }
}

// MARK: - Portfolio "This week" grouping

struct PortfolioActionGroups: Equatable {
    var askForExtension: [PortfolioProject] = []
    var startNow: [PortfolioProject] = []
    var backBurner: [PortfolioProject] = []

    var isEmpty: Bool { askForExtension.isEmpty && startNow.isEmpty && backBurner.isEmpty }
}

/// Web `utils/portfolio.util.ts`. Buckets and risk come from the server; this only regroups them.
enum PortfolioGrouping {
    static let encouragedStartNowLimit = 3
    static let startNowVisibleLimit = 6
    static let backBurnerVisibleLimit = 6

    /// Badges worth showing on a card that already sits under a section heading.
    ///
    /// A card in "Ask for an extension" carried an "Overloaded" badge and a "Start now" badge at
    /// once — the first repeats the heading above it, the second contradicts it (report
    /// 2026-09-11_20-39-23). "Start now" is a section of its own, so it never earns a badge; a
    /// card outside the grouped view (All projects) keeps everything, having no heading to lean on.
    static func badges(_ badges: [PortfolioBadge], in section: PortfolioActionSection?) -> [PortfolioBadge] {
        guard let section = section else { return badges }
        return badges.filter { badge in
            switch badge {
            case .startNow: return false
            case .overcommitted: return section != .askForExtension
            default: return true
            }
        }
    }

    /// Filters portfolio rows by name for the "What matters" search box. Blank query = everything,
    /// so the sections behave exactly as before until the user types (report 2026-09-11_21-39-35).
    static func matching(_ projects: [PortfolioProject], query: String) -> [PortfolioProject] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return projects }
        return projects.filter { $0.name.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
    static let overcommittedNameLimit = 3
    private static let paceRoundMinutes = 5

    static func group(_ projects: [PortfolioProject]) -> PortfolioActionGroups {
        var groups = PortfolioActionGroups()
        for project in projects {
            switch project.portfolioBucket {
            case .critical: groups.askForExtension.append(project)
            case .atRisk: groups.startNow.append(project)
            case .onTrack, .noDeadline:
                if needsStartNow(project) { groups.startNow.append(project) } else { groups.backBurner.append(project) }
            }
        }
        if !groups.startNow.isEmpty { return sorted(groups) }
        return promoteFromBackBurner(groups)
    }

    /// An on-track project still needs starting when the server says so, or when it has a deadline
    /// but nothing of it is in the Day Plan yet (#2418) — "on track" then only means "there is free
    /// space", not "it's planned".
    private static func needsStartNow(_ project: PortfolioProject) -> Bool {
        project.badgeList.contains(.startNow) || (project.isUnscheduled && project.hasDueDate)
    }

    /// With nothing to start now, encourage up to 3 due-dated on-track projects (soonest first), else
    /// up to 3 high/critical-importance ones.
    private static func promoteFromBackBurner(_ groups: PortfolioActionGroups) -> PortfolioActionGroups {
        let dueDated = groups.backBurner
            .filter { $0.portfolioBucket == .onTrack && $0.hasDueDate }
            .sorted(by: byDueDateSoonestThenImportance)
        var encouraged = Array(dueDated.prefix(encouragedStartNowLimit))
        if encouraged.isEmpty {
            encouraged = Array(groups.backBurner
                .filter { $0.importanceLevel == .high || $0.importanceLevel == .critical }
                .sorted { $0.importanceLevel.rawValue > $1.importanceLevel.rawValue }
                .prefix(encouragedStartNowLimit))
        }
        let encouragedIds = Set(encouraged.map { $0.id })
        var result = groups
        result.startNow = encouraged
        result.backBurner = groups.backBurner.filter { !encouragedIds.contains($0.id) }
        return sorted(result)
    }

    private static func sorted(_ groups: PortfolioActionGroups) -> PortfolioActionGroups {
        var result = groups
        result.askForExtension.sort { $0.riskScore > $1.riskScore }
        result.startNow.sort(by: byStartNowPriority)
        result.backBurner.sort(by: byBackBurnerPriority)
        return result
    }

    private static func byDueDateSoonestThenImportance(_ a: PortfolioProject, _ b: PortfolioProject) -> Bool {
        let da = a.due_date ?? "", db = b.due_date ?? ""
        if da != db { return da < db }
        return a.importanceLevel.rawValue > b.importanceLevel.rawValue
    }

    /// Overdue first, then higher risk.
    private static func byStartNowPriority(_ a: PortfolioProject, _ b: PortfolioProject) -> Bool {
        if a.isOverdue != b.isOverdue { return a.isOverdue }
        return a.riskScore > b.riskScore
    }

    /// Due-dated first, then higher risk, then higher importance.
    private static func byBackBurnerPriority(_ a: PortfolioProject, _ b: PortfolioProject) -> Bool {
        if a.hasDueDate != b.hasDueDate { return a.hasDueDate }
        if a.riskScore != b.riskScore { return a.riskScore > b.riskScore }
        return a.importanceLevel.rawValue > b.importanceLevel.rawValue
    }

    /// Web `getRecommendedDailyHours`: nil without effort or due date; the full effort when due today/overdue.
    static func recommendedDailyHours(_ project: PortfolioProject) -> Double? {
        guard project.requiredHours > 0, let days = project.days_until_due else { return nil }
        if days <= 0 { return project.requiredHours }
        return project.requiredHours / Double(days)
    }

    /// Web `roundHoursToDurationParts`: to the nearest 5 minutes, never below 5.
    static func durationParts(hours: Double) -> (hours: Int, minutes: Int) {
        guard hours > 0 else { return (0, 0) }
        let rounded = max(paceRoundMinutes, Int((hours * 60 / Double(paceRoundMinutes)).rounded()) * paceRoundMinutes)
        return (rounded / 60, rounded % 60)
    }

    /// Web `formatOverCommittedProjectNames`: "A, B, C, and 2 more".
    static func overcommittedNames(_ projects: [PortfolioProject], andMore: (Int) -> String) -> String {
        let names = projects.map { $0.name }
        guard !names.isEmpty else { return "" }
        if names.count <= overcommittedNameLimit { return names.joined(separator: ", ") }
        return names.prefix(overcommittedNameLimit).joined(separator: ", ") + ", " + andMore(names.count - overcommittedNameLimit)
    }

    /// Web `getRiskRank` / `sortProjectsByRisk` for the All-projects grid: risk desc, no-deadline last.
    static func sortByRisk(_ projects: [Project], risks: [String: PortfolioProject]) -> [Project] {
        func rank(_ project: Project) -> Double {
            guard let risk = risks[project.id], risk.portfolioBucket != .noDeadline else { return -1 }
            return risk.riskScore
        }
        return projects.enumerated().sorted { lhs, rhs in
            let l = rank(lhs.element), r = rank(rhs.element)
            return l == r ? lhs.offset < rhs.offset : l > r
        }.map { $0.element }
    }
}

// MARK: - Project card "NEXT" task

/// Web `utils/portfolio-top-priority-task/`: which task a project card offers as the next one to do.
///
/// The wire payload's `top_priority_task` (on both `GET /projects` and `GET /portfolio`) is not
/// trusted — the server picks the highest stored `top_score` across *all* the project's to-dos,
/// completed ones included, and a completed task keeps the score it had when it was finished. On a
/// real account that made 14 of 30 cards advertise a task the user had already ticked off. The web
/// works around the same backend behaviour by recomputing the task client-side, and so do we:
/// fetch the project's to-dos, drop the completed ones, and take the highest local TOP score.
enum PortfolioNextTask {
    /// `GET /to-do` page size per project. The server's SMART order is itself polluted by completed
    /// tasks, so the whole first page is fetched and re-ranked locally rather than the web's take of 3.
    static let fetchTake = 50
    /// How many project fetches run at once (web `PORTFOLIO_TOP_PRIORITY_TASK.MAX_CONCURRENCY`).
    static let maxConcurrency = 3

    /// One project whose next task still has to be fetched.
    struct FetchTarget: Equatable {
        var projectId: String
        var syncedProjectId: String?
    }

    /// Web `pickTopPriorityTask`: open tasks only, highest TOP score wins.
    static func pick(from tasks: [ToDoTask], now: Date = Date()) -> ProjectTopPriorityTask? {
        let open = tasks.filter { !$0.isCompleted }
        guard let top = ToDoSorting.sort(open, by: .smart, now: now).first else { return nil }
        return ProjectTopPriorityTask(id: top.id, title: top.title, top_score: ToDoScoring.topScore(of: top, now: now))
    }

    /// Web `collectTopPriorityTaskFetchTargets`: listed projects that have tasks, plus portfolio-only ids.
    static func fetchTargets(projects: [Project], additionalProjectIds: [String] = []) -> [FetchTarget] {
        let projectsById = Dictionary(projects.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let withTasks = projects.filter { ($0.task_count ?? 0) > 0 }.map { $0.id }
        let portfolioOnly = additionalProjectIds.filter { projectsById[$0] == nil }
        var seen = Set<String>()
        return (withTasks + portfolioOnly).compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return FetchTarget(projectId: id, syncedProjectId: projectsById[id]?.synced_project_id)
        }
    }

    /// Web `filterUncachedTopPriorityTargets`.
    static func uncached(_ targets: [FetchTarget], resolved: Set<String>) -> [FetchTarget] {
        targets.filter { !resolved.contains($0.projectId) }
    }
}

// MARK: - Merging one project into another

/// Report 2026-09-11_07-31-36: "Should also be able to merge a project with another one — I have
/// several with similar names. That project's tasks would get transferred to this one."
///
/// There is no server-side merge, so a merge is a task-by-task `PUT /to-do` that re-points each of
/// the source project's tasks at the target, followed by archiving the emptied source. Everything
/// that decides *what* is sent lives here as pure functions so the rules are tested without the API.
enum ProjectMerge {

    /// Why a task cannot be moved. A merge reports these rather than silently leaving tasks behind.
    enum Skip: Error, Equatable {
        /// The task belongs to an external provider (Zoho, Jira, …). Its project membership is owned
        /// by that provider; re-pointing it here would be undone on the next sync.
        case externallySynced
    }

    /// Projects offered as a merge destination: active, manageable, never the source itself, and
    /// never a synced project (its tasks live in the external system). `query` filters by name.
    static func destinations(_ projects: [Project], excluding source: Project,
                             query: String = "", userId: String?) -> [Project] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return projects.filter { project in
            guard project.id != source.id, !project.isSynced, project.lifecycleStatus == .active,
                  ProjectPermissions.canAddTask(ProjectPermissions.viewerRole(in: project, userId: userId)) else { return false }
            guard !trimmed.isEmpty else { return true }
            return project.name.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// A merge may only be started between two native projects the user can write to.
    static func canMerge(_ source: Project, into target: Project, userId: String?) -> Bool {
        guard source.id != target.id, !source.isSynced, !target.isSynced else { return false }
        return ProjectPermissions.canManageMembers(ProjectPermissions.viewerRole(in: source, userId: userId))
            && ProjectPermissions.canAddTask(ProjectPermissions.viewerRole(in: target, userId: userId))
    }

    /// The `PUT /to-do` body that moves one task into `target`, or the reason it was left behind.
    ///
    /// Three fields have to change together. `project_id` is the link itself; the project **tag** is
    /// what the to-do list and Day Plan actually display, so a stale source tag would keep showing
    /// the old project; and `custom_status_id` names a column on the *source's* board, which does not
    /// exist on the target — carrying it over would leave the task in a column the target cannot show.
    ///
    /// `source` is optional so a task that is in no project yet can be filed into one; there is then
    /// simply no source tag to strip. Merge passes a real source, the reschedule row's project picker
    /// passes whatever the task currently has.
    static func reassignment(of task: ToDoTask, from source: Project?,
                             to target: Project) -> Result<[String: Any], Skip> {
        guard (task.synced_project_id ?? "").isEmpty, (task.external_task_id ?? "").isEmpty else {
            return .failure(.externallySynced)
        }
        var body = ToDoUpsertBody.make(from: task)
        body["project_id"] = target.id
        var tags = task.tagList.filter { $0.id != source?.id }
        if !tags.contains(where: { $0.id == target.id }) {
            tags.append(ToDoTag(id: target.id, text: target.name))
        }
        body["tags"] = tags.map { ["id": $0.id, "text": $0.text] }
        body["custom_status_id"] = target.usesCustomStatuses
            ? (target.orderedStatuses.first?.id as Any? ?? NSNull())
            : NSNull()
        return .success(body)
    }

    /// What a finished merge tells the user: how many tasks moved, how many were left behind, and
    /// whether the source may now be archived (only a fully emptied project is).
    struct Outcome: Equatable {
        var moved: Int
        var skipped: Int
        var failed: Int
        var archivesSource: Bool { failed == 0 && skipped == 0 }
        var succeeded: Bool { failed == 0 }
    }
}

// MARK: - Task editor

/// When the task editor's Save button is live.
///
/// Deliberately NOT gated on "the draft changed". Attachments, comments and reactions persist on
/// their own and never reach the task draft, so a rule of the shape `isNew || hasChanges` leaves
/// Save dead after a file is attached: the user has visibly changed the task and the only way out
/// of the editor is Cancel (report 2026-09-15_11-16-30, "after I upload an attachment, it doesn't
/// let me save"). Every field therefore saves through the same always-live button: no edit — the
/// assignee included — can leave Save dead, and `save()` always sends the PUT.
///
/// An upload still in flight does disable Save, so the sheet cannot close out from under bytes that
/// are still streaming to storage.
enum ToDoEditorSave {
    static func canSave(titleIsBlank: Bool, isSavingTask: Bool, isUploadingAttachment: Bool) -> Bool {
        !titleIsBlank && !isSavingTask && !isUploadingAttachment
    }
}

/// Everything the task editor can change, in one comparable value.
///
/// "Has this sheet been edited?" used to be a hand-written expression: the draft, plus a tail of
/// "and also these three things that live outside the draft". `statusOwnerProjectId` was never in
/// that tail, so changing only "status applies to" and pressing Cancel threw the edit away with no
/// warning — and the next field added beside the draft would have gone the same way
/// (report 2026-09-16_15-14-36, "make sure every edit allows saving"). Holding the whole editable
/// state here makes the synthesised `Equatable` the rule: a field counts as an edit the moment it is
/// stored, with nothing to remember to update. `ToDoEditorSnapshotTests` fails if a field is added
/// without a case proving it.
struct ToDoEditorSnapshot: Equatable {
    var draft: ToDoTask
    var selectedProjectIds: [String]
    var statusOwnerProjectId: String?
    var durationMinutesText: String
    /// Trimmed, so trailing whitespace in the "add a subtask" field is not an edit.
    var pendingSubtask: String
}

// MARK: - Image previews

/// How large an image preview (an attachment, a report screenshot) should be drawn.
///
/// Picking a fixed maximum makes the picture tiny on a large display and clipped on a small one, so
/// the size comes from the screen it will appear on and the image's own resolution.
enum ImagePreviewSizing {
    /// Of the screen's usable area — the rest is breathing room plus the sheet's own chrome.
    static let availableFraction: CGFloat = 0.8
    /// Never enlarge past the image's natural size: an upscaled screenshot is just a blurry one.
    static let maximumScale: CGFloat = 1
    /// A sheet narrower than this is awkward to dismiss, whatever the image measures.
    static let minimumSide: CGFloat = 320
    /// A document area smaller than this is not worth previewing in — on a very short screen the sheet
    /// keeps this much for the picture rather than squeezing it out to fit its own chrome.
    static let minimumDocumentSide: CGFloat = 160

    /// The area a preview may occupy on a screen of this size. Documents (a PDF, a text file) scroll
    /// inside it; an image is fitted to it by `fit`.
    static func box(available: CGSize) -> CGSize {
        guard available.width > 0, available.height > 0 else { return .zero }
        return CGSize(width: (available.width * availableFraction).rounded(),
                      height: (available.height * availableFraction).rounded())
    }

    /// What is left for the picture or document once the sheet's own chrome — its header row, its
    /// footer row, the spacing between them and the padding around the lot — has taken `chromeHeight`.
    ///
    /// A sheet that handed its WHOLE height to the document pushed its own header and footer off the
    /// top and bottom edges. That is how "it didn't have a close button on the top right" happened
    /// (report 2026-09-15_20-54-33 follow-up): the ✕ was rendered, just not inside the sheet.
    static func documentBox(available: CGSize, chromeHeight: CGFloat) -> CGSize {
        let outer = box(available: available)
        guard outer.width > 0, outer.height > 0 else { return .zero }
        return CGSize(width: outer.width,
                      height: max(minimumDocumentSide, outer.height - max(0, chromeHeight)))
    }

    /// The EXACT size a preview sheet should be given — document plus chrome.
    ///
    /// Exact, not "a minimum and an ideal". `NSHostingController` turns a SwiftUI `minHeight` into a
    /// REQUIRED constraint and an `idealHeight` into a low-priority preference, and AppKit resolves a
    /// sheet from the required ones — so a view asking for `minHeight: 320, idealHeight: 700` is
    /// presented 320 points tall while `fittingSize` still cheerfully reports 700. Measured, on the
    /// Day Plan's `presentAsSheet` path (report 2026-09-15_20-54-33 follow-up, "it was not tall
    /// enough"). The width never showed the bug only because its minimum and ideal were both set.
    static func sheetSize(available: CGSize, chromeHeight: CGFloat) -> CGSize {
        let document = documentBox(available: available, chromeHeight: chromeHeight)
        guard document.width > 0, document.height > 0 else { return .zero }
        return CGSize(width: max(minimumSide, document.width), height: document.height + max(0, chromeHeight))
    }

    /// The size to draw `image` at so it fills as much of `box` as its aspect ratio allows.
    static func fit(image: CGSize, within box: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0, box.width > 0, box.height > 0 else { return .zero }
        let scale = min(box.width / image.width, box.height / image.height, maximumScale)
        return CGSize(width: (image.width * scale).rounded(), height: (image.height * scale).rounded())
    }

    /// As `fit(image:within:)`, against the whole of a screen's preview box.
    static func fit(image: CGSize, available: CGSize) -> CGSize {
        fit(image: image, within: box(available: available))
    }

    /// The size to draw `image` at inside a box it is allowed to SCROLL in: fitted to the box's width,
    /// never enlarged past its own resolution, and free to be taller than the box.
    ///
    /// `fit` squeezes both dimensions in, which is right for a thumbnail and wrong for a preview: a
    /// long screenshot — the shape most people attach — comes out a few hundred points wide and
    /// unreadable. Fitting the width instead keeps it at a legible scale and lets the scroll view do
    /// the rest (report 2026-09-15_11-16-30 follow-up, "it could be wider and have scrollbars").
    static func scrollableFit(image: CGSize, within box: CGSize) -> CGSize {
        guard image.width > 0, image.height > 0, box.width > 0 else { return .zero }
        let scale = min(box.width / image.width, maximumScale)
        return CGSize(width: (image.width * scale).rounded(), height: (image.height * scale).rounded())
    }

    /// Whether content of this size has to scroll to be seen whole inside `box` — the one place that
    /// decides whether a preview shows scrollers, so an image, a document and a text file cannot
    /// answer it differently. The tolerance keeps a rounded-off point from claiming a fitted picture
    /// overflows.
    static func needsScrolling(content: CGSize, within box: CGSize) -> Bool {
        guard content.width > 0, content.height > 0, box.width > 0, box.height > 0 else { return false }
        return content.width > box.width + overflowTolerance || content.height > box.height + overflowTolerance
    }

    /// Rounding slack: `scrollableFit` rounds to whole points, so an exactly-fitting picture can
    /// measure a fraction over the box it was fitted to.
    private static let overflowTolerance: CGFloat = 0.5
}

// MARK: - Project icons

/// One offer in the project icon picker: the emoji itself plus the words that should find it.
struct ProjectIconChoice: Equatable, Identifiable {
    let emoji: String
    let keywords: [String]

    var id: String { emoji }
}

/// The project `icon` wire format and the emoji the picker offers.
///
/// The server stores the **literal emoji character**, not a hex codepoint: its own icon generator
/// writes `normalizeSingleEmoji(...)` (backend `shared/utils/emoji.ts`), and `PUT /projects/:id`
/// validates the same shape. Sending "1f3af" is rejected (report 2026-09-14_20-07-42). `habit_icon`
/// is the odd one out that genuinely is hex — `EmojiIcon.resolve` still reads that shape back for
/// display, but nothing writes it.
enum ProjectIcon {
    /// What to send for "use the automatic icon".
    static let cleared = ""

    /// The single emoji character to send for what the user typed, pasted or picked, or `cleared`
    /// if there is no usable emoji in it. Only the first grapheme cluster is kept, so a ZWJ
    /// sequence like "💆‍♂️" stays one icon instead of fragmenting.
    static func normalise(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, isEmoji(first) else { return cleared }
        return String(first)
    }

    /// True when the whole string is exactly one emoji — what the server will accept.
    static func isSingleEmoji(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 1 && trimmed.first.map(isEmoji) == true
    }

    private static func isEmoji(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        return character.unicodeScalars.count > 1 ? scalar.properties.isEmoji : scalar.properties.isEmojiPresentation
    }

    /// The choices to show for a search box.
    ///
    /// An empty query shows the curated grid; typing searches the curated keywords first and then
    /// every emoji macOS can render. Report 2026-09-17 ("it seems to only have a limited set of
    /// icons?") was about exactly that gap: the grid is a starting point, not the whole set.
    static func choices(matching query: String) -> [ProjectIconChoice] {
        // An emoji the user typed or pasted leads, so one the catalogue does not carry still works.
        let typed = normalise(query)
        if !typed.isEmpty {
            return [ProjectIconChoice(emoji: typed, keywords: [])] + catalogue.filter { $0.emoji != typed }
        }

        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return catalogue }
        // Curated first: those keywords are the words people search projects by, and they are the
        // ones chosen to read well at icon size.
        return matches(needle, in: catalogue) + matches(needle, in: searchIndex)
    }

    private static func matches(_ needle: String, in choices: [ProjectIconChoice]) -> [ProjectIconChoice] {
        choices.filter { choice in choice.keywords.contains { $0.hasPrefix(needle) } }
    }

    /// Every emoji this platform renders, keyed by the words in its official Unicode name, built
    /// once on the first search.
    ///
    /// Names come from ICU rather than a hardcoded table, so the index stays correct as Unicode
    /// grows and costs nothing to maintain. The curated catalogue still leads, because ICU calls
    /// 🎯 "DIRECT HIT" and 🚀 "ROCKET" — accurate, but not what someone naming a project types.
    private static let searchIndex: [ProjectIconChoice] = buildSearchIndex()

    /// The Unicode blocks that hold emoji: the symbol/dingbat stretch in the BMP, and the
    /// supplementary planes from Miscellaneous Symbols and Pictographs onwards.
    private static let emojiScalarRanges: [ClosedRange<UInt32>] = [0x203C...0x3299, 0x1F000...0x1FAFF]

    private static func buildSearchIndex() -> [ProjectIconChoice] {
        // Compared without the variation selector: the catalogue writes ⭐️ with U+FE0F, and the
        // bare U+2B50 in the block would otherwise be indexed as a second, identical-looking row.
        let curated = Set(catalogue.map { $0.emoji.filter { $0 != ProjectIcon.variationSelector } })
        var choices: [ProjectIconChoice] = []
        for range in emojiScalarRanges {
            for value in range {
                guard let scalar = Unicode.Scalar(value), scalar.properties.isEmojiPresentation else { continue }
                let emoji = String(scalar)
                guard !curated.contains(emoji), let keywords = unicodeNameKeywords(for: emoji) else { continue }
                choices.append(ProjectIconChoice(emoji: emoji, keywords: keywords))
            }
        }
        return choices
    }

    private static let variationSelector: Character = "\u{FE0F}"

    /// `["grinning", "cat", "face"]` for 😸 — ICU renders the name as `\N{GRINNING CAT FACE}`.
    private static func unicodeNameKeywords(for emoji: String) -> [String]? {
        guard let name = emoji.applyingTransform(StringTransform("Any-Name"), reverse: false) else { return nil }
        let words = name.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        // "n" is the escape wrapper (\N{...}), not part of any name.
        let meaningful = words.filter { $0 != "n" }
        return meaningful.isEmpty ? nil : meaningful
    }

    /// A working set of project-shaped emoji with the words people search them by. Deliberately
    /// short — it is the grid shown before anyone types, not the limit: search falls through to
    /// `searchIndex` (every emoji, by Unicode name) and the field accepts any pasted emoji.
    static let catalogue: [ProjectIconChoice] = [
        ProjectIconChoice(emoji: "🎯", keywords: ["target", "goal", "focus", "aim"]),
        ProjectIconChoice(emoji: "🚀", keywords: ["rocket", "launch", "startup", "ship"]),
        ProjectIconChoice(emoji: "💡", keywords: ["idea", "light", "insight", "invent"]),
        ProjectIconChoice(emoji: "🛠️", keywords: ["tools", "build", "fix", "maintenance"]),
        ProjectIconChoice(emoji: "🧱", keywords: ["brick", "build", "foundation", "infrastructure"]),
        ProjectIconChoice(emoji: "📦", keywords: ["package", "release", "shipping", "product"]),
        ProjectIconChoice(emoji: "💻", keywords: ["laptop", "code", "software", "dev", "engineering"]),
        ProjectIconChoice(emoji: "🐛", keywords: ["bug", "defect", "fix", "issue"]),
        ProjectIconChoice(emoji: "🤖", keywords: ["robot", "ai", "automation", "bot"]),
        ProjectIconChoice(emoji: "🔬", keywords: ["research", "science", "lab", "experiment"]),
        ProjectIconChoice(emoji: "📊", keywords: ["chart", "analytics", "data", "metrics", "report"]),
        ProjectIconChoice(emoji: "📈", keywords: ["growth", "sales", "revenue", "trend", "up"]),
        ProjectIconChoice(emoji: "💰", keywords: ["money", "finance", "budget", "funding", "pricing"]),
        ProjectIconChoice(emoji: "🧾", keywords: ["invoice", "receipt", "accounting", "tax", "billing"]),
        ProjectIconChoice(emoji: "📣", keywords: ["marketing", "announce", "promo", "campaign"]),
        ProjectIconChoice(emoji: "✍️", keywords: ["writing", "content", "blog", "copy", "draft"]),
        ProjectIconChoice(emoji: "🎨", keywords: ["design", "art", "creative", "brand", "ui"]),
        ProjectIconChoice(emoji: "🎬", keywords: ["video", "film", "youtube", "recording", "media"]),
        ProjectIconChoice(emoji: "🎙️", keywords: ["podcast", "audio", "interview", "recording"]),
        ProjectIconChoice(emoji: "📸", keywords: ["photo", "camera", "shoot", "images"]),
        ProjectIconChoice(emoji: "🎵", keywords: ["music", "song", "practice", "instrument"]),
        ProjectIconChoice(emoji: "📚", keywords: ["study", "books", "learning", "course", "reading"]),
        ProjectIconChoice(emoji: "🎓", keywords: ["university", "school", "degree", "study", "thesis"]),
        ProjectIconChoice(emoji: "🗣️", keywords: ["language", "speaking", "talk", "presentation"]),
        ProjectIconChoice(emoji: "🧠", keywords: ["brain", "thinking", "strategy", "mental", "learning"]),
        ProjectIconChoice(emoji: "🩺", keywords: ["health", "doctor", "medical", "checkup", "clinic"]),
        ProjectIconChoice(emoji: "🏥", keywords: ["health", "hospital", "medical", "care"]),
        ProjectIconChoice(emoji: "💊", keywords: ["health", "medication", "pills", "treatment"]),
        ProjectIconChoice(emoji: "🏃", keywords: ["health", "running", "exercise", "fitness", "training"]),
        ProjectIconChoice(emoji: "🏋️", keywords: ["health", "gym", "strength", "workout", "fitness"]),
        ProjectIconChoice(emoji: "🧘", keywords: ["health", "meditation", "mindfulness", "calm", "yoga"]),
        ProjectIconChoice(emoji: "🥗", keywords: ["health", "food", "diet", "nutrition", "meal"]),
        ProjectIconChoice(emoji: "🛌", keywords: ["health", "sleep", "rest", "recovery"]),
        ProjectIconChoice(emoji: "🏡", keywords: ["home", "house", "renovation", "household", "family"]),
        ProjectIconChoice(emoji: "🧹", keywords: ["home", "cleaning", "chores", "tidy", "declutter"]),
        ProjectIconChoice(emoji: "🌱", keywords: ["garden", "plants", "growth", "sustainability", "green"]),
        ProjectIconChoice(emoji: "🐕", keywords: ["dog", "pet", "animal", "walk"]),
        ProjectIconChoice(emoji: "👨‍👩‍👧", keywords: ["family", "kids", "parenting", "home"]),
        ProjectIconChoice(emoji: "🎁", keywords: ["gift", "present", "birthday", "christmas"]),
        ProjectIconChoice(emoji: "🎉", keywords: ["party", "celebration", "event", "launch"]),
        ProjectIconChoice(emoji: "✈️", keywords: ["travel", "flight", "trip", "holiday", "vacation"]),
        ProjectIconChoice(emoji: "🗺️", keywords: ["travel", "map", "planning", "roadmap", "journey"]),
        ProjectIconChoice(emoji: "🚗", keywords: ["car", "driving", "commute", "vehicle"]),
        ProjectIconChoice(emoji: "🏢", keywords: ["office", "work", "company", "business", "admin"]),
        ProjectIconChoice(emoji: "🤝", keywords: ["partnership", "sales", "deal", "clients", "networking"]),
        ProjectIconChoice(emoji: "📞", keywords: ["calls", "support", "phone", "outreach"]),
        ProjectIconChoice(emoji: "✉️", keywords: ["email", "inbox", "newsletter", "mail"]),
        ProjectIconChoice(emoji: "🗓️", keywords: ["calendar", "schedule", "planning", "dates"]),
        ProjectIconChoice(emoji: "✅", keywords: ["done", "tasks", "checklist", "todo", "admin"]),
        ProjectIconChoice(emoji: "🔥", keywords: ["urgent", "hot", "priority", "streak"]),
        ProjectIconChoice(emoji: "⭐️", keywords: ["star", "favourite", "important", "quality"]),
        ProjectIconChoice(emoji: "🧩", keywords: ["puzzle", "problem", "integration", "pieces"]),
        ProjectIconChoice(emoji: "🔒", keywords: ["security", "privacy", "lock", "compliance"]),
        ProjectIconChoice(emoji: "⚖️", keywords: ["legal", "law", "contract", "compliance", "balance"]),
        ProjectIconChoice(emoji: "🌍", keywords: ["world", "global", "translation", "international"]),
        ProjectIconChoice(emoji: "🎮", keywords: ["game", "gaming", "play", "hobby"]),
    ]
}
