//
//  StatsModels.swift
//  Focus Bear
//
//  Codable models for the stats endpoints the web dashboard's /webview/stats page uses
//  (web: `interfaces/stats.interface.ts`, `interfaces/user.interface.ts`; backend DTOs under
//  `modules/user`, `modules/activity`, `modules/focus-mode`). Decoded with `.convertFromSnakeCase`.
//

import Foundation

/// Postgres aggregates come back as strings ("60", "87.08", "137") while other fields are real
/// numbers; the UI doesn't care which, so accept both (and null → nil via Optional).
struct FlexibleNumber: Codable, Equatable {
    let value: Double

    init(_ value: Double) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            value = number
        } else if let text = try? container.decode(String.self), let number = Double(text) {
            value = number
        } else {
            throw DecodingError.typeMismatch(Double.self, .init(codingPath: decoder.codingPath,
                                                                 debugDescription: "Expected a number or numeric string"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension Optional where Wrapped == FlexibleNumber {
    var doubleValue: Double { self?.value ?? 0 }
    var intValue: Int { Int(doubleValue.rounded()) }
}

// MARK: - Streak / Progress (GET /user/stats/onboarding)

struct OnboardingStats: Codable {
    var level: Int
    var morningRoutineCompletionStreakDays: Int?
    var eveningRoutineCompletionStreakDays: Int?
    var focusModeCompletionStreakDays: Int?
    var breakRoutineCompletionStreakDays: Int?
    var averageMorningRoutinesCompletionPercentage: FlexibleNumber?
    var averageEveningRoutinesCompletionPercentage: FlexibleNumber?
    var averageNumFocusModesCompletedPerDay: FlexibleNumber?
    var routinesThreshold: Int?
    var focusModesThreshold: Int?
    var hasChattedWithFocusBear: Bool?
    var hasEditedFocusMode: Bool?
    var hasEditedAlwaysBlockedUrls: Bool?
    var hasInstalledMobileApp: Bool?
    var hasEditedSettings: Bool?
}

// MARK: - Your Goals (GET/PATCH /user/long-term-goals)

struct LongTermGoalsPayload: Encodable {
    let goals: [String]
}

// MARK: - Habit Stats

struct LogQuantityQuestion: Codable, Equatable {
    var id: String
    var question: String?
    /// How the backend aggregates this question's daily answers — `"SUM"` or `"AVG"` (settings key
    /// `log_summary_type`). The `/stats` series already arrives aggregated that way; the app only
    /// needs the setting to label the graph "Total" or "Average".
    var logSummaryType: String?

    /// True when this question's daily figure is a mean rather than a running total.
    var isAveraged: Bool { (logSummaryType ?? "").caseInsensitiveCompare("AVG") == .orderedSame }
}

/// The slice of a routine activity the Habit Stats tab needs (from GET /user-settings).
struct StatsActivity: Codable, Equatable {
    var id: String
    var name: String?
    var habitIcon: String?
    var createdAt: String?
    var logQuantityQuestions: [LogQuantityQuestion]?

    var questions: [LogQuantityQuestion] { logQuantityQuestions ?? [] }
}

struct StatsUserSettings: Codable {
    var morningActivities: [StatsActivity]?
    var breakActivities: [StatsActivity]?
    var eveningActivities: [StatsActivity]?
    var createdAt: String?

    /// Web `getUniqueRoutineActivities`: morning + break + evening, first occurrence of each id wins.
    var uniqueActivities: [StatsActivity] {
        var seen = Set<String>()
        return ((morningActivities ?? []) + (breakActivities ?? []) + (eveningActivities ?? [])).filter { activity in
            seen.insert(activity.id).inserted
        }
    }
}

struct ConsistencyStatsPayload: Encodable {
    let activityIds: [String]
    let daysNumber: Int
    let timezone: String
}

struct BulkConsistencyStats: Codable {
    struct HabitCompletion: Codable {
        var activityId: String
        var completedDays: Int
    }
    var daysNumber: Int?
    var habits: [HabitCompletion]
}

/// One day of a habit's stats. `summary` is the SUM/AVG of the logged quantity or duration seconds.
struct ActivityStatItem: Codable, Equatable {
    var date: String?
    var summary: FlexibleNumber?
    var count: FlexibleNumber?
}

struct CompletedActivityStats: Codable {
    var activityId: String?
    var items: [ActivityStatItem]?
    /// `"duration"` or `"quantity"` — what `items[].summary` measures. For a quantity habit the
    /// summary is the logged amount, NOT seconds, so an "hours spent" figure derived from it is
    /// meaningless and must be hidden.
    var statType: String?

    /// True when `summary` is a count of seconds, i.e. an hours figure is meaningful.
    var isDurationBased: Bool { (statType ?? "duration").caseInsensitiveCompare("duration") == .orderedSame }
}

struct LogQuantityAnswersStats: Codable {
    var questionId: String?
    var items: [ActivityStatItem]?
}

// MARK: - Focus sessions

struct FocusSessionMetadata: Codable, Equatable {
    var focusAlignmentScore: FlexibleNumber?
    var averageTabCount: FlexibleNumber?
    var averageTabDuration: FlexibleNumber?
    var isManual: Bool?
}

/// GET /completed-focus-blocks item (`FocusModeDaySummaryItem`). `duration` is wall-clock seconds.
struct FocusSessionSummary: Codable, Equatable {
    var name: String?
    var startTime: String
    var duration: Double?
    var metadata: FocusSessionMetadata?
}

struct FocusLogFocusMode: Codable, Equatable {
    var id: String?
    var name: String?
}

/// GET /user/weekly-focus-block-summary row (`WeeklyFocusBlockSummary`).
struct FocusLogEntry: Codable, Equatable, Identifiable {
    var id: String
    var startTime: String?
    var finishTime: String?
    var focusDurationSeconds: FlexibleNumber?
    var intention: String?
    var achievements: String?
    var distractions: String?
    var createdAt: String?
    var metadata: FocusSessionMetadata?
    var focusMode: FocusLogFocusMode?

    var focusModeName: String { focusMode?.name ?? "" }
    var isManual: Bool { metadata?.isManual ?? false }
}

struct CreateFocusBlockPayload: Encodable {
    var intention: String
    var achievements: String
    var distractions: String
    var focusDurationSeconds: Int
    var startTime: String
    var finishTime: String
    var focusModeId: String?
}

struct UpdateFocusBlockPayload: Encodable {
    var intention: String
    var achievements: String
    var distractions: String
}

/// PATCH body that sets only the achievements, leaving the session's other fields as they are.
struct FocusBlockAchievementsPayload: Encodable {
    var achievements: String
}

/// GET /user/focus-modes — only what manual-session creation needs.
struct FocusModeSummary: Codable {
    struct Metadata: Codable {
        var isManualEntry: Bool?
    }
    var id: String
    var name: String?
    var metadata: Metadata?
}

// MARK: - Leaderboard

struct LeaderboardUser: Codable, Equatable, Identifiable {
    var id: String
    var username: String?
    var rank: FlexibleNumber?
    var morningRoutinesStreak: FlexibleNumber?
    var eveningRoutinesStreak: FlexibleNumber?
    var focusModesStreak: FlexibleNumber?
    var microBreaksStreak: FlexibleNumber?
    var morningPercentNumberDayOfStatsCompleted: FlexibleNumber?
    var eveningPercentNumberDayOfStatsCompleted: FlexibleNumber?
    var microPercentNumberDayOfStatsCompleted: FlexibleNumber?
    var morningNumberDaysCompleted: FlexibleNumber?
    var morningNumDaysOfStats: FlexibleNumber?
    var eveningNumberDaysCompleted: FlexibleNumber?
    var eveningNumDaysOfStats: FlexibleNumber?
    var microBreaksNumberDaysCompleted: FlexibleNumber?
    var microBreaksNumDaysOfStats: FlexibleNumber?
    var focusModesNumberDaysCompleted: FlexibleNumber?
    var focusModesNumDaysOfStats: FlexibleNumber?
    var numDaysOfStats: FlexibleNumber?
    var numberDaysCompleted: FlexibleNumber?
}

struct LeaderboardResponse: Codable {
    var userRank: LeaderboardUser?
    var usersRankings: [LeaderboardUser]
}

struct UsernamePayload: Encodable {
    let username: String
}

// MARK: - JSON coding

enum StatsJSON {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

// MARK: - Dates

enum StatsDates {
    private static let fractionalISO: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let plainISO = ISO8601DateFormatter()
    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parse(_ text: String?) -> Date? {
        guard let text = text else { return nil }
        return fractionalISO.date(from: text) ?? plainISO.date(from: text)
    }

    static func iso(_ date: Date) -> String { fractionalISO.string(from: date) }

    /// Local-day key (web: `moment(date).format('YYYY-MM-DD')`).
    static func dayKey(_ date: Date) -> String { dayKeyFormatter.string(from: date) }

    static func format(_ date: Date, _ pattern: String, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
