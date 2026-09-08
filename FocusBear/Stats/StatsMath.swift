//
//  StatsMath.swift
//  Focus Bear
//
//  Pure, AppKit-free calculations behind the Stats screen — ports of the web dashboard's
//  `utils/stats.util.ts` and `utils/stats/habit-consistency.util.ts` so the native numbers match
//  the dashboard. Everything takes `today`/`now` explicitly so it can be verified offline.
//

import Foundation

enum StatsCalendar {
    /// The web's moment() weeks start on Sunday regardless of locale; match it so heat-map columns
    /// line up with the dashboard.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        return calendar
    }()

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    /// Sunday-first short weekday names ("Sun", "Mon", …) in the app's language, for the heat-map rows.
    static func shortWeekdaySymbols(languageCode: String) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode.isEmpty ? "en" : languageCode)
        formatter.calendar = calendar
        return formatter.shortWeekdaySymbols ?? calendar.shortWeekdaySymbols
    }

    static func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day ?? 0
    }

    static func startOfWeek(_ date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? startOfDay(date)
    }

    /// Per-day stat rows are `date_trunc('day', finish_time AT TIME ZONE tz)` serialised as UTC
    /// midnight, so the day they name is the UTC calendar day — not the local one.
    static func serverDayKey(_ isoDate: String?) -> String? {
        guard let date = StatsDates.parse(isoDate) else { return nil }
        let parts = utcCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

// MARK: - Habit consistency ranking

struct HabitConsistencyItem: Identifiable, Equatable {
    var id: String { activity.id }
    let activity: StatsActivity
    let completedDays: Int
    let windowDays: Int
    /// 0–100, rounded.
    let percentage: Int
}

enum HabitConsistencyRanking {
    static let windowMaxDays = 90
    static let topVisible = 5
    /// The "least consistent" list only appears once there is something beyond the top five.
    static let minimumForLeastSection = topVisible + 1

    struct Split {
        let mostConsistent: [HabitConsistencyItem]
        let leastConsistent: [HabitConsistencyItem]
        var showsLeastSection: Bool { !leastConsistent.isEmpty }
    }

    /// Habits created less than 90 days ago are scored against the days they have existed.
    static func windowDays(createdAt: Date?, today: Date) -> Int {
        guard let created = createdAt else { return windowMaxDays }
        return min(max(StatsCalendar.daysBetween(created, today) + 1, 1), windowMaxDays)
    }

    static func build(activities: [StatsActivity], stats: BulkConsistencyStats, today: Date) -> [HabitConsistencyItem] {
        let completedById = Dictionary(stats.habits.map { ($0.activityId, $0.completedDays) }, uniquingKeysWith: { first, _ in first })
        return activities.compactMap { activity -> HabitConsistencyItem? in
            guard let completed = completedById[activity.id] else { return nil }
            let window = windowDays(createdAt: StatsDates.parse(activity.createdAt), today: today)
            let percentage = min(max(Int((Double(completed) / Double(window) * 100).rounded()), 0), 100)
            return HabitConsistencyItem(activity: activity, completedDays: completed, windowDays: window, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }
    }

    static func split(_ ranked: [HabitConsistencyItem]) -> Split {
        let most = Array(ranked.prefix(topVisible))
        let least = ranked.count >= minimumForLeastSection ? Array(ranked.dropFirst(topVisible).reversed()) : []
        return Split(mostConsistent: most, leastConsistent: least)
    }
}

// MARK: - Heat map

struct HeatMapCell: Identifiable, Equatable {
    var id: String { dayKey }
    let dayKey: String
    let date: Date
    let count: Int
    /// After today — drawn as a placeholder so the last column is still a whole week.
    var isFuture = false
}

struct HeatMapMonthLabel: Identifiable, Equatable {
    var id: Int { weekIndex }
    let label: String
    let weekIndex: Int
}

struct HeatMapModel: Equatable {
    var columns: [[HeatMapCell]] = []
    var monthLabels: [HeatMapMonthLabel] = []
    var maxCount = 0
    var totalCount: Int { columns.joined().reduce(0) { $0 + $1.count } }
}

enum HeatMapBuilder {
    static let weeksToShow = 5
    static let daysInWeek = 7
    static let intensityLevels = 5
    /// The grid starts at the beginning of the week five weeks back, i.e. up to six weeks ago; the
    /// web's 35-day fetch (`DAYS_TO_FETCH_HEATMAP`) leaves the oldest column blank on most weekdays.
    static let fetchDays = (weeksToShow + 1) * daysInWeek
    private static let monthLabelPattern = "MMM"
    private static let firstDayOfMonth = 1

    static func countsByDay(_ items: [ActivityStatItem]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for item in items {
            guard let key = StatsCalendar.serverDayKey(item.date) else { continue }
            counts[key, default: 0] += item.count.intValue
        }
        return counts
    }

    /// Web `processHeatMapData`'s range: from the start of the week five weeks ago (or the week the
    /// account was created, whichever is later) through today, padded out to a whole final week.
    static func build(items: [ActivityStatItem], joinDate: Date?, today: Date) -> HeatMapModel {
        let endDate = StatsCalendar.startOfDay(today)
        let defaultStart = StatsCalendar.startOfWeek(StatsCalendar.addDays(-weeksToShow * daysInWeek, to: endDate))
        var start = defaultStart
        if let joined = joinDate {
            let joinWeek = StatsCalendar.startOfWeek(joined)
            if joinWeek > defaultStart { start = joinWeek }
        }
        return grid(from: start, to: endDate, today: endDate, counts: countsByDay(items))
    }

    /// One column per week from the week containing `start` through the week containing `end`,
    /// every column a full seven cells (Sunday-first), so no day in the range is skipped.
    static func grid(from start: Date, to end: Date, today: Date, counts: [String: Int]) -> HeatMapModel {
        var model = HeatMapModel()
        model.maxCount = counts.values.max() ?? 0
        let todayStart = StatsCalendar.startOfDay(today)
        let lastWeekStart = StatsCalendar.startOfWeek(end)
        var weekStart = StatsCalendar.startOfWeek(start)
        while weekStart <= lastWeekStart {
            model.columns.append(weekColumn(from: weekStart, today: todayStart, counts: counts))
            weekStart = StatsCalendar.addDays(daysInWeek, to: weekStart)
        }
        model.monthLabels = monthLabels(for: model.columns)
        return model
    }

    private static func weekColumn(from weekStart: Date, today: Date, counts: [String: Int]) -> [HeatMapCell] {
        (0..<daysInWeek).map { offset in
            let date = StatsCalendar.addDays(offset, to: weekStart)
            let key = StatsDates.dayKey(date)
            return HeatMapCell(dayKey: key, date: date, count: counts[key] ?? 0, isFuture: date > today)
        }
    }

    /// A month is labelled over the column holding its 1st. The first column also gets its own
    /// month unless the next column is already labelled, where the two labels would overlap.
    static func monthLabels(for columns: [[HeatMapCell]]) -> [HeatMapMonthLabel] {
        var labels: [HeatMapMonthLabel] = []
        for (weekIndex, column) in columns.enumerated() {
            guard let monthStart = column.first(where: { StatsCalendar.calendar.component(.day, from: $0.date) == firstDayOfMonth }) else { continue }
            labels.append(HeatMapMonthLabel(label: StatsDates.format(monthStart.date, monthLabelPattern), weekIndex: weekIndex))
        }
        let firstLabelledWeek = labels.first?.weekIndex ?? Int.max
        if firstLabelledWeek > 1, let firstDay = columns.first?.first {
            labels.insert(HeatMapMonthLabel(label: StatsDates.format(firstDay.date, monthLabelPattern), weekIndex: 0), at: 0)
        }
        return labels
    }

    /// 0 = no completions, 1…4 = quartiles of the busiest day (web `getColorIntensity`).
    static func intensityLevel(count: Int, maxCount: Int) -> Int {
        guard count > 0 else { return 0 }
        let intensity = min(Double(count) / Double(max(maxCount, 1)), 1)
        if intensity <= 0.25 { return 1 }
        if intensity <= 0.5 { return 2 }
        if intensity <= 0.75 { return 3 }
        return 4
    }
}

// MARK: - Selected habit stat cards

struct HabitStatSummary: Equatable {
    static let recentWindowDays = 30

    var totalCompletions = 0
    /// One decimal, like the web.
    var hoursSpent = 0.0
    var currentStreak = 0
    var last30DaysPercentage = 0

    /// Web `calculateTotalCompletions` / `calculateTotalHoursSpent` / `calculateCurrentStreak` /
    /// `calculateLast30DaysPercentage`. The streak is anchored on yesterday, so a habit done only
    /// today reads 0 — same as the dashboard.
    static func compute(items: [ActivityStatItem], today: Date) -> HabitStatSummary {
        var summary = HabitStatSummary()
        let counts = HeatMapBuilder.countsByDay(items)
        summary.totalCompletions = counts.values.reduce(0, +)
        let seconds = items.reduce(0.0) { $0 + $1.summary.doubleValue }
        summary.hoursSpent = (seconds / 3600 * 10).rounded() / 10

        let yesterdayKey = StatsDates.dayKey(StatsCalendar.addDays(-1, to: today))
        var streak = 0
        var cursorKey = yesterdayKey
        var cursor = StatsCalendar.addDays(-1, to: today)
        while (counts[cursorKey] ?? 0) > 0 {
            streak += 1
            cursor = StatsCalendar.addDays(-1, to: cursor)
            cursorKey = StatsDates.dayKey(cursor)
        }
        summary.currentStreak = streak

        let windowStart = StatsCalendar.addDays(-recentWindowDays, to: StatsCalendar.startOfDay(today))
        let activeDays = (0...recentWindowDays).filter { offset in
            (counts[StatsDates.dayKey(StatsCalendar.addDays(offset, to: windowStart))] ?? 0) > 0
        }.count
        summary.last30DaysPercentage = Int((Double(activeDays) / Double(recentWindowDays) * 100).rounded())
        return summary
    }
}

// MARK: - Line-chart points

struct GraphPoint: Identifiable, Equatable {
    var id: String { label + "\(date.timeIntervalSince1970)" }
    let label: String
    let value: Double
    let date: Date
}

enum LogQuantityGraph {
    static let labelPattern = "MMM dd, yyyy"

    /// Web `transformSummariesToGraphData`: oldest first, value = the day's summary.
    static func points(_ items: [ActivityStatItem]) -> [GraphPoint] {
        items.compactMap { item -> GraphPoint? in
            guard let date = StatsDates.parse(item.date) else { return nil }
            return GraphPoint(label: StatsDates.format(date, labelPattern), value: item.summary.doubleValue, date: date)
        }
        .sorted { $0.date < $1.date }
    }
}

// MARK: - Productivity

enum ProductivityPeriod: String, CaseIterable {
    case daily, monthly, yearly

    var component: Calendar.Component {
        switch self {
        case .daily: return .day
        case .monthly: return .month
        case .yearly: return .year
        }
    }

    /// Chart label pattern (web: `'MMM DD'` / `'MMM YYYY'` / `'YYYY'`).
    var labelPattern: String {
        switch self {
        case .daily: return "MMM dd"
        case .monthly: return "MMM yyyy"
        case .yearly: return "yyyy"
        }
    }

    /// Focus-log summary labels (web: `'MMM DD, YYYY'` / `'MMM YYYY'` / `'YYYY'`).
    var focusLogLabelPattern: String { self == .daily ? "MMM dd, yyyy" : labelPattern }

    func bucketStart(_ date: Date) -> Date {
        let calendar = StatsCalendar.calendar
        switch self {
        case .daily: return calendar.startOfDay(for: date)
        case .monthly: return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        case .yearly: return calendar.date(from: calendar.dateComponents([.year], from: date)) ?? date
        }
    }
}

struct HumanizedFocusTime: Equatable {
    enum Unit { case minutes, hours, days }
    let value: Double
    let unit: Unit
    let remainingHours: Int

    /// Web `humanizeFocusedTime`.
    static func from(totalMinutes: Double) -> HumanizedFocusTime {
        if totalMinutes < 60 { return HumanizedFocusTime(value: totalMinutes.rounded(), unit: .minutes, remainingHours: 0) }
        let hours = totalMinutes / 60
        if hours >= 48 {
            return HumanizedFocusTime(value: (hours / 24).rounded(.down), unit: .days,
                                      remainingHours: Int(hours.truncatingRemainder(dividingBy: 24).rounded()))
        }
        return HumanizedFocusTime(value: (hours * 10).rounded() / 10, unit: .hours, remainingHours: 0)
    }
}

struct ProductivitySummary: Equatable {
    static let dataLimit = 30
    static let defaultAlignmentScore = 100.0
    /// Switch the chart to hours once a bucket reaches this many minutes.
    static let hoursThresholdMinutes = 1000.0

    var focusedMinutes = 0.0
    var averageMinutesPerDay = 0.0
    var mostFocusedDay: GraphPoint? = nil
    var averageTabCount = 0.0
    var averageTabDuration = 0.0
    var chart: [GraphPoint] = []
    var usesHours = false

    var hasTabMetrics: Bool { averageTabCount > 0 || averageTabDuration > 0 }

    /// Web `getDateRangeForSummary`: 30 days / months / years back, aligned to the period start.
    static func dateRange(_ period: ProductivityPeriod, now: Date) -> (from: Date, to: Date) {
        let calendar = StatsCalendar.calendar
        let back = calendar.date(byAdding: period.component, value: -dataLimit, to: now) ?? now
        return (period.bucketStart(back), now)
    }

    static func focusedMinutes(_ session: FocusSessionSummary) -> Double {
        let score = session.metadata?.focusAlignmentScore?.value ?? defaultAlignmentScore
        return max(session.duration ?? 0, 0) * (score / 100) / 60
    }

    static func compute(sessions: [FocusSessionSummary], period: ProductivityPeriod) -> ProductivitySummary {
        var summary = ProductivitySummary()
        var byDay: [String: (Date, Double)] = [:]
        var byBucket: [Date: Double] = [:]
        var tabSessions = 0
        var tabCountTotal = 0.0
        var tabDurationTotal = 0.0

        for session in sessions {
            guard let start = StatsDates.parse(session.startTime) else { continue }
            let minutes = focusedMinutes(session)
            summary.focusedMinutes += minutes
            let dayKey = StatsDates.dayKey(start)
            byDay[dayKey] = (StatsCalendar.startOfDay(start), (byDay[dayKey]?.1 ?? 0) + minutes)
            byBucket[period.bucketStart(start), default: 0] += minutes
            if session.metadata?.averageTabCount != nil || session.metadata?.averageTabDuration != nil {
                tabSessions += 1
                tabCountTotal += session.metadata?.averageTabCount.doubleValue ?? 0
                tabDurationTotal += session.metadata?.averageTabDuration.doubleValue ?? 0
            }
        }

        if !byDay.isEmpty {
            summary.averageMinutesPerDay = (summary.focusedMinutes / Double(byDay.count)).rounded()
            if let best = byDay.values.max(by: { $0.1 < $1.1 }) {
                summary.mostFocusedDay = GraphPoint(label: StatsDates.dayKey(best.0), value: best.1.rounded(), date: best.0)
            }
        }
        if tabSessions > 0 {
            summary.averageTabCount = (tabCountTotal / Double(tabSessions) * 10).rounded() / 10
            summary.averageTabDuration = (tabDurationTotal / Double(tabSessions)).rounded()
        }

        let buckets = byBucket.keys.sorted().suffix(dataLimit)
        let maxMinutes = buckets.map { byBucket[$0] ?? 0 }.max() ?? 0
        summary.usesHours = maxMinutes >= hoursThresholdMinutes
        summary.chart = buckets.map { bucket in
            let minutes = byBucket[bucket] ?? 0
            let value = summary.usesHours ? (minutes / 60 * 10).rounded() / 10 : minutes.rounded()
            return GraphPoint(label: StatsDates.format(bucket, period.labelPattern), value: value, date: bucket)
        }
        return summary
    }
}

// MARK: - Focus log

enum FocusLogColumn: CaseIterable, Identifiable {
    case duration, startTime, finishTime, intention, distractions, focusMode
    var id: Self { self }
    var isDateColumn: Bool { self == .startTime || self == .finishTime }
}

enum FocusLogMath {
    static let csvFileName = "focus_summary.csv"

    /// Web `getEffectiveFocusDurationSeconds`: wall-clock finish − start when it is at least the
    /// stored focus duration, else the stored value.
    static func effectiveDurationSeconds(_ entry: FocusLogEntry) -> Int {
        let stored = entry.focusDurationSeconds.intValue
        guard let start = StatsDates.parse(entry.startTime), let finish = StatsDates.parse(entry.finishTime) else { return stored }
        let wallClock = Int(finish.timeIntervalSince(start).rounded())
        return wallClock >= stored ? wallClock : stored
    }

    /// Web `getValidFocusSummaryColumnValue`: intentions arrive form-encoded from some clients.
    static func displayText(_ raw: String?) -> String {
        guard let raw = raw, !raw.isEmpty else { return "-" }
        let spaced = raw.replacingOccurrences(of: "+", with: " ")
        return spaced.removingPercentEncoding ?? spaced
    }

    /// Web `sortFocusSummariesByColumn` — always descending.
    static func sorted(_ entries: [FocusLogEntry], by column: FocusLogColumn) -> [FocusLogEntry] {
        switch column {
        case .duration:
            return entries.sorted { effectiveDurationSeconds($0) > effectiveDurationSeconds($1) }
        case .startTime:
            return entries.sorted { ($0.startTime ?? "") > ($1.startTime ?? "") }
        case .finishTime:
            return entries.sorted { ($0.finishTime ?? "") > ($1.finishTime ?? "") }
        case .intention:
            return entries.sorted { ($0.intention ?? "").lowercased() > ($1.intention ?? "").lowercased() }
        case .distractions:
            return entries.sorted { ($0.distractions ?? "").lowercased() > ($1.distractions ?? "").lowercased() }
        case .focusMode:
            return entries.sorted { $0.focusModeName.lowercased() > $1.focusModeName.lowercased() }
        }
    }

    /// Web `getFocusSummaryFilteredData`: text columns match case-insensitively, date columns match
    /// the calendar day, the duration column matches its humanised text.
    static func filtered(_ entries: [FocusLogEntry], column: FocusLogColumn, text: String, day: Date?) -> [FocusLogEntry] {
        let needle = text.trimmingCharacters(in: .whitespaces).lowercased()
        return entries.filter { entry in
            switch column {
            case .duration:
                return needle.isEmpty || humanizeSeconds(effectiveDurationSeconds(entry)).lowercased().contains(needle)
            case .startTime, .finishTime:
                guard let day = day else { return true }
                let raw = column == .startTime ? entry.startTime : entry.finishTime
                guard let date = StatsDates.parse(raw) else { return false }
                return StatsDates.dayKey(date) == StatsDates.dayKey(day)
            case .intention:
                return needle.isEmpty || displayText(entry.intention).lowercased().contains(needle)
            case .distractions:
                return needle.isEmpty || displayText(entry.distractions).lowercased().contains(needle)
            case .focusMode:
                return needle.isEmpty || entry.focusModeName.lowercased().contains(needle)
            }
        }
    }

    /// Web `getFocusSummaryGraphLabelsAndData`: seconds per bucket keyed by `created_at`, latest 30.
    static func graphPoints(_ entries: [FocusLogEntry], period: ProductivityPeriod) -> [GraphPoint] {
        var byBucket: [Date: Double] = [:]
        for entry in entries {
            guard let created = StatsDates.parse(entry.createdAt) else { continue }
            byBucket[period.bucketStart(created), default: 0] += Double(effectiveDurationSeconds(entry))
        }
        return byBucket.keys.sorted().suffix(ProductivitySummary.dataLimit).map { bucket in
            GraphPoint(label: StatsDates.format(bucket, period.focusLogLabelPattern), value: byBucket[bucket] ?? 0, date: bucket)
        }
    }

    /// Web `downloadFocusSummaryCSVFile` (same columns and raw values), but with proper CSV quoting so
    /// a comma in an intention doesn't corrupt the row.
    static func csv(_ entries: [FocusLogEntry], headers: [String]) -> String {
        let rows = entries.map { entry -> String in
            [entry.focusModeName, String(effectiveDurationSeconds(entry)), entry.startTime ?? "", entry.finishTime ?? "",
             entry.intention ?? "", entry.achievements ?? "", entry.distractions ?? ""]
                .map(csvField).joined(separator: ",")
        }
        return ([headers.map(csvField).joined(separator: ",")] + rows).joined(separator: "\n")
    }

    private static func csvField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2
        return formatter
    }()

    /// Localised "1 hour, 25 minutes" style (web: `moment.duration(...).humanize()`).
    static func humanizeSeconds(_ seconds: Int) -> String {
        durationFormatter.allowedUnits = seconds < 60 ? [.second] : [.day, .hour, .minute]
        return durationFormatter.string(from: TimeInterval(max(seconds, 0))) ?? "\(seconds)s"
    }
}

// MARK: - Leaderboard

/// The leaderboard's sortable columns. `rawValue` is the backend `StreakTypes` enum value sent as
/// `streak_type`, which picks the top-N pool and the `rank` the server returns.
enum LeaderboardSortKey: String, CaseIterable, Identifiable {
    case morning = "morning_routines_streak"
    case microBreak = "micro_breaks_streak"
    case evening = "evening_routines_streak"
    case focusMode = "focus_modes_streak"
    var id: Self { self }
}

/// One leaderboard column for one user: the completion percentage over the stats window plus the
/// `(completed/window)` fraction behind it and the current streak.
struct LeaderboardMetric: Equatable {
    let percentage: Double
    let completedDays: Double
    let windowDays: Double
    let streak: Double
}

enum LeaderboardSorting {
    private static let fullPercentage = 100.0

    /// Whole-number percentage like the server's `*_percent_number_day_of_stats_completed` columns.
    static func percentage(completedDays: Double, windowDays: Double) -> Double {
        guard windowDays > 0 else { return 0 }
        return (completedDays / windowDays * fullPercentage).rounded()
    }

    /// Morning / break / evening use the server's percentage (what the web shows); focus mode has no
    /// percentage column on the server, so it is derived from the day pair the API does return.
    static func metric(_ user: LeaderboardUser, key: LeaderboardSortKey) -> LeaderboardMetric {
        let completed: Double
        let window: Double
        let serverPercent: FlexibleNumber?
        let streak: Double
        switch key {
        case .morning:
            completed = user.morningNumberDaysCompleted?.value ?? user.numberDaysCompleted.doubleValue
            window = user.morningNumDaysOfStats?.value ?? user.numDaysOfStats.doubleValue
            serverPercent = user.morningPercentNumberDayOfStatsCompleted
            streak = user.morningRoutinesStreak.doubleValue
        case .microBreak:
            completed = user.microBreaksNumberDaysCompleted?.value ?? user.numberDaysCompleted.doubleValue
            window = user.microBreaksNumDaysOfStats?.value ?? user.numDaysOfStats.doubleValue
            serverPercent = user.microPercentNumberDayOfStatsCompleted
            streak = user.microBreaksStreak.doubleValue
        case .evening:
            completed = user.eveningNumberDaysCompleted?.value ?? user.numberDaysCompleted.doubleValue
            window = user.eveningNumDaysOfStats?.value ?? user.numDaysOfStats.doubleValue
            serverPercent = user.eveningPercentNumberDayOfStatsCompleted
            streak = user.eveningRoutinesStreak.doubleValue
        case .focusMode:
            completed = user.focusModesNumberDaysCompleted?.value ?? user.numberDaysCompleted.doubleValue
            window = user.focusModesNumDaysOfStats?.value ?? user.numDaysOfStats.doubleValue
            serverPercent = nil
            streak = user.focusModesStreak.doubleValue
        }
        return LeaderboardMetric(percentage: serverPercent?.value ?? percentage(completedDays: completed, windowDays: window),
                                 completedDays: completed, windowDays: window, streak: streak)
    }

    /// Stable order by the column's percentage, then days completed, then current streak; `ascending`
    /// flips the comparison (fully tied rows keep the server's order either way).
    static func sort(_ users: [LeaderboardUser], by key: LeaderboardSortKey, ascending: Bool) -> [LeaderboardUser] {
        let ranked = users.enumerated().map { (index: $0.offset, user: $0.element, metric: metric($0.element, key: key)) }
        return ranked.sorted { lhs, rhs in
            let left = [lhs.metric.percentage, lhs.metric.completedDays, lhs.metric.streak]
            let right = [rhs.metric.percentage, rhs.metric.completedDays, rhs.metric.streak]
            if left != right { return ascending ? left.lexicographicallyPrecedes(right) : right.lexicographicallyPrecedes(left) }
            return lhs.index < rhs.index
        }.map { $0.user }
    }
}

// MARK: - Levels (Progress tab)

struct LevelRequirement: Identifiable, Equatable {
    enum Kind: Equatable { case morning, microBreak, evening, focusMode, chat, focusModeSetup }
    var id: Kind { kind }
    let kind: Kind
    let current: Int
    let target: Int
    /// Boolean goals ("Chat with Focus Bear") show a tick instead of a counter.
    var isBoolean: Bool { kind == .chat || kind == .focusModeSetup }
    var isMet: Bool { current >= target }
}

enum LevelTargets {
    static let maxLevel = 9
    static let visibleLevels = 7
    static let chatAndFocusModeLevel = 3

    /// Web `GOALS_LEVEL_TARGET`: (morning, micro break, evening, focus mode) streak days per level.
    private static let table: [Int: (Int, Int, Int, Int)] = [
        1: (1, 1, 1, 1), 2: (2, 2, 2, 2), 3: (5, 5, 5, 5), 4: (7, 7, 7, 10), 5: (10, 10, 10, 15),
        6: (15, 15, 15, 30), 7: (30, 30, 30, 50), 8: (60, 60, 60, 100), 9: (100, 100, 100, 200),
    ]

    static func requirements(level: Int, stats: OnboardingStats) -> [LevelRequirement] {
        guard let targets = table[level] else { return [] }
        var list = [
            LevelRequirement(kind: .morning, current: stats.morningRoutineCompletionStreakDays ?? 0, target: targets.0),
            LevelRequirement(kind: .microBreak, current: stats.breakRoutineCompletionStreakDays ?? 0, target: targets.1),
            LevelRequirement(kind: .evening, current: stats.eveningRoutineCompletionStreakDays ?? 0, target: targets.2),
            LevelRequirement(kind: .focusMode, current: stats.focusModeCompletionStreakDays ?? 0, target: targets.3),
        ]
        if level == chatAndFocusModeLevel {
            list.append(LevelRequirement(kind: .chat, current: (stats.hasChattedWithFocusBear ?? false) ? 1 : 0, target: 1))
            list.append(LevelRequirement(kind: .focusModeSetup, current: (stats.hasEditedFocusMode ?? false) ? 1 : 0, target: 1))
        }
        return list
    }

    /// Web `computeVisibleHeaderRange`: which of the Start / Level 1…9 / End headers (indices 0…10)
    /// are shown — a window of seven ending at the current level once past level 5.
    static func visibleHeaderRange(level: Int) -> Range<Int> {
        let windowEnd = visibleLevels - 1
        let start = level < windowEnd ? 0 : level - windowEnd + 1
        let end = level >= windowEnd ? level + 1 : visibleLevels
        return start..<min(end, maxLevel + 2)
    }
}

/// Explainer links the web's onboarding rows open (`GOALS_INSTRUCTION_URL`, `DOWNLOAD_LINK.MOBILE`).
enum StatsExternalLinks {
    static let setupBlockedUrls = "https://youtu.be/3U3ktaodAzk"
    static let installMobileApp = "https://youtube.com/shorts/zv6be2sNOsk"
    static let editHabits = "https://youtu.be/BCVdt210PGA"
    static let iosApp = "https://apps.apple.com/us/app/focus-bear/id1673296334"
    static let androidApp = "https://play.google.com/store/apps/details?id=com.focusbear"
}
