import Foundation

/// Day codes, not indexes. The rest of Focus Bear already speaks these for exactly this concept —
/// habits and routines send and match "MON".."SUN" (see `Date.dayOfWeek()`, a fixed en_US_POSIX
/// "EEE"), and the dashboard has its own `DaysOfWeek` enum — so a numeric vocabulary here was a
/// second way of saying the same thing. Nothing about `[1,2,3,4,5]` in a stored policy says whether
/// 1 is Monday, and an off-by-one reads as a school policy that activates on the wrong days.
enum ManagedDay {
    /// Ordered so the position is `Calendar.component(.weekday) - 1`, which the overnight-window
    /// arithmetic still needs. `code(at:)` is the only place that conversion happens.
    ///
    /// This is a DIFFERENT order from `HabitEditValues.weekdayCodes`, which is Monday-first because
    /// it is what a person reads. Same seven tokens, two orderings, for two different jobs — which
    /// is precisely the confusion that made `days_of_week` numeric to begin with, so
    /// `ManagedPolicyTests` asserts the two hold the same set. It is spelled out here rather than
    /// derived from `HabitEditValues` so this module keeps no dependency on the Schedule code.
    static let codes = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    static let daysInWeek = codes.count

    static func code(at index: Int) -> String {
        codes[((index % daysInWeek) + daysInWeek) % daysInWeek]
    }

    static func index(of code: String) -> Int? { codes.firstIndex(of: code) }

    static func isValid(_ code: String) -> Bool { known.contains(code) }

    /// Week order, not alphabetical — "FRI, MON, SAT" is not a week.
    static func ordered(_ values: [String]) -> [String] {
        values.compactMap { code in index(of: code).map { ($0, code) } }
            .sorted { $0.0 < $1.0 }
            .map(\.1)
    }

    private static let known = Set(codes)
}

struct ManagedWindow: Codable, Equatable {
    var daysOfWeek: [String]
    var startTime: String
    var endTime: String
    var allDay: Bool?
}

struct ManagedException: Codable, Equatable {
    var url: String
    var includeSubdomains: Bool
    var reason: String?
    var expiresAt: String?
}

struct ManagedExcludedDates: Codable, Equatable {
    var startDate: String
    var endDate: String
}

struct ManagedPolicy: Codable, Equatable, Identifiable {
    var id: String
    var schoolId: String
    var studentId: String?
    var kind: String
    var revision: Int
    var status: String
    var name: String
    var timeZone: String
    var isEnabled: Bool
    var windows: [ManagedWindow]
    var blockedCategories: [String]
    var allowlist: [ManagedException]
    var excludedDates: [ManagedExcludedDates]
    var unknownAction: String
    var unavailableAction: String

    var changes: ManagedPolicyChanges {
        ManagedPolicyChanges(name: name, timeZone: timeZone, isEnabled: isEnabled,
            windows: windows, blockedCategories: blockedCategories, allowlist: allowlist,
            excludedDates: excludedDates, unknownAction: unknownAction, unavailableAction: unavailableAction)
    }
}

struct ManagedPolicyChanges: Codable, Equatable {
    var name: String
    var timeZone: String
    var isEnabled: Bool
    var windows: [ManagedWindow]
    var blockedCategories: [String]
    var allowlist: [ManagedException]
    var excludedDates: [ManagedExcludedDates]
    var unknownAction: String
    var unavailableAction: String
    static let editableFields = ["name", "time_zone", "is_enabled", "windows", "blocked_categories",
        "allowlist", "excluded_dates", "unknown_action", "unavailable_action"]
}

struct ManagedPolicySnapshot: Codable, Equatable {
    var school: ManagedPolicy?
    var home: ManagedPolicy?
    var settingsLocked: Bool
    var schemaVersion: Int?
    var serverTime: String?
    var offlineValidUntil: String?
    var snapshotId: String?

    func activePolicy(at date: Date) -> ManagedPolicy? {
        if let school = school, ManagedPolicyEvaluator.isActive(school, at: date) { return school }
        if let home = home, ManagedPolicyEvaluator.isActive(home, at: date) { return home }
        return nil
    }
}

struct ManagedURLDecision: Decodable {
    var allowed: Bool
    var reason: String
    var policy: ManagedPolicy?
    var active: Bool?
    var matchedCategories: [String]?
    var violationId: String?
    var classification: ManagedClassification?
    var appeal: ManagedAppeal?
}

struct ManagedClassification: Codable {
    var taxonomyVersion: String
    var modelVersion: String
    var classificationStatus: String
    var categories: [String]
    var evaluatedCategories: [String]?
    var expiresAt: String
}

struct ManagedAppeal: Decodable {
    var id: String
    var status: String?
    var reason: String?
    var expiresAt: String?
}

struct ManagedSettingsRequest: Codable, Identifiable {
    var id: String
    var deviceId: String
    var policyId: String
    var scope: [String]
    var baseRevision: Int
    var status: String
    var expiresAt: String
    var proposedChanges: ManagedPolicyChanges?
    var changesHash: String?
    var before: ManagedPolicy?

    func permitsProposal(deviceId: String, revision: Int, at date: Date) -> Bool {
        status == "approved" && self.deviceId == deviceId && baseRevision == revision &&
            (ManagedDate.parse(expiresAt).map { $0 > date } ?? false)
    }
}

enum ManagedDate {
    static func parse(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    static func string(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

enum ManagedJSON {
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
