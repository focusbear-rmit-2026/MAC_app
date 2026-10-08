//
//  LegacyCalendarDateMigration.swift
//  Focus Bear
//
//  Older builds wrote machine dates in the user's own calendar (2569-10-06 on a Buddhist-calendar
//  Mac). Every build now writes Gregorian (see MachineDateFormat), so data stored the old way is
//  rewritten here — once for the per-day maps in UserDefaults, on every load for the encrypted Day
//  Plan, and row by row for offline activities still waiting to upload.
//

import Foundation

enum LegacyCalendarDateMigration {
    /// Set once the UserDefaults stores have been checked, so later launches skip the scan.
    static let userDefaultsMigratedKey = "legacyCalendarDayKeysMigrated"
    /// The offline activities CSV columns holding UTC timestamps the server stores as sent.
    static let offlineActivityTimestampColumns = ["start_time", "finish_time"]

    /// The Gregorian day for a key an older build wrote in another calendar; nil for anything else,
    /// including keys that are already Gregorian and strings that are not a day at all.
    static func normalizedDayKey(_ key: String, legacyLocale: Locale = .current, now: Date = Date()) -> String? {
        MachineDateFormat.normalizedLegacyString(key, format: MachineDateFormat.dayKey,
                                                 legacyLocale: legacyLocale, now: now)
    }

    /// `map` with every legacy day key rewritten, or nil when it had none. A rewritten key that lands
    /// on an existing Gregorian one is combined as `merge(existing, legacy)`.
    static func normalizingDayKeys<Value>(_ map: [String: Value], legacyLocale: Locale = .current, now: Date = Date(),
                                          merge: (Value, Value) -> Value) -> [String: Value]? {
        var result = map
        var changed = false
        for (key, value) in map {
            guard let gregorian = normalizedDayKey(key, legacyLocale: legacyLocale, now: now) else { continue }
            result.removeValue(forKey: key)
            result[gregorian] = result[gregorian].map { merge($0, value) } ?? value
            changed = true
        }
        return changed ? result : nil
    }

    /// An offline activity row with its timestamps rewritten in the Gregorian calendar, so a row an
    /// older build queued is not uploaded 543 years in the future.
    static func normalizingOfflineActivityTimestamps(_ row: [String: Any], legacyLocale: Locale = .current,
                                                     now: Date = Date()) -> [String: Any] {
        var result = row
        for column in offlineActivityTimestampColumns {
            guard let text = row[column] as? String,
                  let gregorian = MachineDateFormat.normalizedLegacyString(text, format: offlineActivityTimestampFormat,
                                                                           timeZone: MachineDateFormat.utc,
                                                                           legacyLocale: legacyLocale, now: now)
            else { continue }
            result[column] = gregorian
        }
        return result
    }

    /// Day Plan tasks from a legacy day join the same Gregorian day's, skipping any already there.
    static func mergingDayPlanTasks(_ existing: [DayPlanTask], _ legacy: [DayPlanTask]) -> [DayPlanTask] {
        let existingIDs = Set(existing.map(\.id))
        return existing + legacy.filter { !existingIDs.contains($0.id) }
    }

    /// Rewrites the per-day maps kept in UserDefaults. Runs once per install; a no-op on a Mac that
    /// never stored a non-Gregorian day.
    static func migrateUserDefaultsIfNeeded(_ defaults: UserDefaults = .standard, legacyLocale: Locale = .current,
                                            now: Date = Date()) {
        guard !defaults.bool(forKey: userDefaultsMigratedKey) else { return }
        for key in [kDayPlanCompletedHabitIdsByDay, DayPlanHabitSkips.storageKey] {
            migrateDictionary(forKey: key, in: defaults, legacyLocale: legacyLocale, now: now, merge: unionOfIDs)
        }
        for key in [DayPlanHabitDurations.storageKey, DayPlanMeetingDurations.storageKey] {
            migrateDictionary(forKey: key, in: defaults, legacyLocale: legacyLocale, now: now, merge: keepingExisting)
        }
        defaults.set(true, forKey: userDefaultsMigratedKey)
    }

    private static func migrateDictionary<Value>(forKey key: String, in defaults: UserDefaults, legacyLocale: Locale,
                                                 now: Date, merge: (Value, Value) -> Value) {
        guard let stored = defaults.dictionary(forKey: key) as? [String: Value],
              let migrated = normalizingDayKeys(stored, legacyLocale: legacyLocale, now: now, merge: merge)
        else { return }
        defaults.set(migrated, forKey: key)
        addLog(text: "Rewrote legacy-calendar day keys in \(key)")
    }

    private static func unionOfIDs(_ existing: [String], _ legacy: [String]) -> [String] {
        Array(Set(existing).union(legacy)).sorted()
    }

    private static func keepingExisting(_ existing: [String: Int], _ legacy: [String: Int]) -> [String: Int] {
        existing.merging(legacy) { current, _ in current }
    }
}
