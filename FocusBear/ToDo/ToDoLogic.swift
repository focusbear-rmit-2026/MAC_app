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

    static func weekdayDayMonth(_ date: Date) -> String { weekdayDayMonth.string(from: date) }

    /// Web `formatDueDate`: Today / Tomorrow / Yesterday, else "18 Jan" this year, "18 Jan 2027" otherwise.
    static func dueLabel(_ isoString: String?, now: Date = Date(), today: String, tomorrow: String, yesterday: String) -> String {
        guard let date = parse(isoString) else { return "" }
        switch daysBetween(now, date) {
        case 0: return today
        case 1: return tomorrow
        case -1: return yesterday
        default:
            let sameYear = Calendar.current.component(.year, from: date) == Calendar.current.component(.year, from: now)
            return sameYear ? dayMonth.string(from: date) : dayMonthYear.string(from: date)
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
    static let defaultPerspiration = 2
    private static let scoreFloor = 0.1
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
///   Nd / Nw / Nm · in N days…   → now + N days / weeks / months
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
    private static let relativePattern = "^(?:in\\s+)?(\\d+)\\s*(d|w|m|day|days|week|weeks|month|months)$"
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

    /// "2d", "3 weeks", "in 2 days", "1m".
    private static func parseRelative(_ input: String, from today: Date, calendar: Calendar) -> Date? {
        guard let groups = groups(relativePattern, in: input), let amount = Int(groups[0] ?? ""), let unit = groups[1]?.first else { return nil }
        let component: Calendar.Component
        switch unit {
        case "d": component = .day
        case "w": component = .weekOfYear
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

// MARK: - Status toggle (checkbox)

enum ToDoStatusToggle {
    /// Web `buildProjectDetailsTaskStatusToggle`: with custom columns the task moves to the project's
    /// done column (the first that completes, else the last) or back to the first column; without
    /// them the default status flips and any custom id is dropped.
    static func apply(to task: ToDoTask, completed: Bool, customStatuses: [ProjectCustomStatus]) -> ToDoTask {
        var updated = task
        updated.status = completed ? ToDoStatus.completed.rawValue : ToDoStatus.notStarted.rawValue
        let ordered = customStatuses.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
        guard !ordered.isEmpty else {
            updated.custom_status_id = nil
            return updated
        }
        updated.custom_status_id = completed ? ProjectKanban.doneStatus(in: ordered)?.id : ordered.first?.id
        return updated
    }
}

// MARK: - Upsert body (PUT /to-do)

enum ToDoUpsertBody {
    /// Web `persistToDoTask` PUTs the whole task; this sends the writable subset of `CreateToDoDto`
    /// (read-only fields like `top_score` / `assignee` / `external_task_status` are left out). Keys
    /// with a nil value are sent as JSON null so the backend clears them (`hasDtoProperty`).
    static func make(from task: ToDoTask) -> [String: Any] {
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
        if let perspiration = task.perspiration_level { body["perspiration_level"] = perspiration }
        if let icon = task.icon, !icon.isEmpty { body["icon"] = icon }
        if let focusType = task.focus_type, !focusType.isEmpty { body["focus_type"] = focusType }
        if let externalId = task.external_task_id, !externalId.isEmpty { body["external_task_id"] = externalId }
        if let synced = task.synced_project_id, !synced.isEmpty { body["synced_project_id"] = synced }
        body["assignee_id"] = task.assignee_id ?? NSNull()
        body["assigned_mcp_token_id"] = task.assigned_mcp_token_id ?? NSNull()
        return body
    }
}

// MARK: - Editor drafts

/// The task the editor starts from (web `DEFAULT_TODO_NEW_TASK` / `mapTaskToFormData`).
enum ToDoDraft {
    /// A new task: due tomorrow, default TOP levels, quadrant "Do" (the web's silent default now
    /// that the quadrant picker is hidden). Opened from a project detail it is pre-linked to that
    /// project — tag, `project_id` and the project's first column (web `getInitFormData`) — from
    /// the project object itself, never a catalogue lookup that may not know a just-created project.
    static func newTask(title: String, project: Project? = nil, now: Date = Date()) -> ToDoTask {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        var task = ToDoTask(id: UUID().uuidString.lowercased(), title: title, details: "", objective: "",
                            status: ToDoStatus.notStarted.rawValue, due_date: ToDoDates.ymd(tomorrow), created_at: "",
                            eisenhower_quadrant: EisenhowerQuadrant.doIt.rawValue, outcome: ToDoScoring.defaultOutcome,
                            perspiration_level: ToDoScoring.defaultPerspiration, tags: [], subtasks: [])
        guard let project = project else { return task }
        task.tags = [ToDoTag(id: project.id, text: project.name)]
        task.project_id = project.id
        task.custom_status_id = project.usesCustomStatuses ? project.orderedStatuses.first?.id : nil
        return task
    }

    /// An existing task as the editor holds it: due date as a local `YYYY-MM-DD`, levels defaulted,
    /// details as plain text.
    static func editable(_ task: ToDoTask) -> ToDoTask {
        var copy = task
        copy.due_date = ToDoDates.ymd(fromISO: task.due_date)
        copy.outcome = task.outcome ?? ToDoScoring.defaultOutcome
        copy.perspiration_level = task.perspiration_level ?? ToDoScoring.defaultPerspiration
        copy.details = ToDoHTML.plainText(task.details ?? "")
        // GET /to-do rows carry the assignee as the nested `assignee` object, not the scalar
        // `assignee_id` the picker binds to — so a saved assignee looked unset on reopen. Backfill it.
        copy.assignee_id = task.assignee_id ?? task.assignee?.id
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

    static func message(from data: Data?) -> String? {
        guard let data = data, let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let text = object[messageKey] as? String { return nonEmpty(text) }
        guard let items = object[messageKey] as? [Any] else { return nil }
        let parts = items.flatMap { item -> [String] in
            if let text = item as? String { return [text] }
            guard let error = item as? [String: Any], let constraints = error[constraintsKey] as? [String: Any] else { return [] }
            return constraints.keys.sorted().compactMap { constraints[$0] as? String }
        }
        return nonEmpty(parts.joined(separator: separator))
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
    static let overcommittedNameLimit = 3
    static let recommendedTodayVisibleLimit = 3
    private static let paceRoundMinutes = 5

    static func group(_ projects: [PortfolioProject]) -> PortfolioActionGroups {
        var groups = PortfolioActionGroups()
        for project in projects {
            switch project.portfolioBucket {
            case .critical: groups.askForExtension.append(project)
            case .atRisk: groups.startNow.append(project)
            case .onTrack, .noDeadline:
                if project.badgeList.contains(.startNow) { groups.startNow.append(project) } else { groups.backBurner.append(project) }
            }
        }
        if !groups.startNow.isEmpty { return sorted(groups) }
        return promoteFromBackBurner(groups)
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
