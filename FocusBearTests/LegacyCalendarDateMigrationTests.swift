//
//  LegacyCalendarDateMigrationTests.swift
//  FocusBearTests
//
//  Day keys an older build stored in the user's own calendar are rewritten as Gregorian ones. The
//  user's calendar is injected and every store is a throwaway UserDefaults suite — never the app's.
//

@testable import Focus_Bear
import XCTest

final class LegacyCalendarDateMigrationTests: XCTestCase {

    /// 2026-10-06 00:00:00 UTC — "now" for every plausibility check.
    private static let now = Date(timeIntervalSince1970: 1_791_244_800)
    private static let buddhist = Locale(identifier: "th_TH@calendar=buddhist")
    private static let gregorianDay = "2026-10-06"
    private static let buddhistDay = "2569-10-06"

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "LegacyCalendarDateMigrationTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func normalized(_ key: String, in locale: Locale = buddhist) -> String? {
        LegacyCalendarDateMigration.normalizedDayKey(key, legacyLocale: locale, now: Self.now)
    }

    private func migrate() {
        LegacyCalendarDateMigration.migrateUserDefaultsIfNeeded(defaults, legacyLocale: Self.buddhist, now: Self.now)
    }

    // MARK: - Day keys

    func test_dayKeys_fromEachNonGregorianCalendar_becomeGregorian() {
        XCTAssertEqual(normalized(Self.buddhistDay), Self.gregorianDay)
        XCTAssertEqual(normalized("0008-10-06", in: Locale(identifier: "ja_JP@calendar=japanese")), Self.gregorianDay)
        XCTAssertEqual(normalized("1448-04-25", in: Locale(identifier: "en_AU@calendar=islamic-umalqura")), Self.gregorianDay)
        XCTAssertEqual(normalized("١٤٤٨-٠٤-٢٥", in: Locale(identifier: "ar_SA@calendar=islamic-umalqura")), Self.gregorianDay)
    }

    func test_buddhistDayKeys_areRecovered_afterTheMacSwitchedBackToGregorian() {
        XCTAssertEqual(normalized(Self.buddhistDay, in: Locale(identifier: "en_AU")), Self.gregorianDay)
    }

    func test_gregorianAndNonDayKeys_areLeftAlone() {
        XCTAssertNil(normalized(Self.gregorianDay))
        XCTAssertNil(normalized("2027-01-31"))
        XCTAssertNil(normalized("dayPlanSnoozeCloneDedupeDone"))
        XCTAssertNil(normalized(""))
    }

    func test_normalizingDayKeys_mergesALegacyDayIntoTheSameGregorianDay() throws {
        let map = [Self.buddhistDay: ["a", "b"], Self.gregorianDay: ["b", "c"], "2026-10-07": ["d"]]
        let migrated = try XCTUnwrap(LegacyCalendarDateMigration.normalizingDayKeys(
            map, legacyLocale: Self.buddhist, now: Self.now) { existing, legacy in Array(Set(existing).union(legacy)).sorted() })
        XCTAssertEqual(migrated, [Self.gregorianDay: ["a", "b", "c"], "2026-10-07": ["d"]])
    }

    func test_normalizingDayKeys_isNil_whenNothingIsLegacy() {
        let map = [Self.gregorianDay: 1]
        XCTAssertNil(LegacyCalendarDateMigration.normalizingDayKeys(map, legacyLocale: Self.buddhist, now: Self.now) { a, _ in a })
    }

    func test_dayPlanTasks_fromALegacyDay_joinTheGregorianDayWithoutDuplicates() {
        let kept = DayPlanTask(id: "kept", title: "Already on the Gregorian day")
        let duplicate = DayPlanTask(id: "kept", title: "Same task under the legacy key")
        let moved = DayPlanTask(id: "moved", title: "Only under the legacy key")
        let merged = LegacyCalendarDateMigration.mergingDayPlanTasks([kept], [duplicate, moved])
        XCTAssertEqual(merged.map(\.id), ["kept", "moved"])
        XCTAssertEqual(merged.first?.title, kept.title)
    }

    // MARK: - Offline rows

    func test_offlineActivityRows_areUploadedWithGregorianTimestamps() {
        let row: [String: Any] = ["activity_id": "habit", "start_time": "2569-10-06T00:00:00.000Z",
                                  "finish_time": "2026-10-06T00:05:00.000Z", "duration_logged": "300"]
        let normalized = LegacyCalendarDateMigration.normalizingOfflineActivityTimestamps(
            row, legacyLocale: Self.buddhist, now: Self.now)
        XCTAssertEqual(normalized["start_time"] as? String, "2026-10-06T00:00:00.000Z")
        XCTAssertEqual(normalized["finish_time"] as? String, "2026-10-06T00:05:00.000Z")
        XCTAssertEqual(normalized["activity_id"] as? String, "habit")
        XCTAssertEqual(normalized["duration_logged"] as? String, "300")
    }

    // MARK: - UserDefaults stores

    func test_migration_rewritesEveryPerDayStore() {
        defaults.set([Self.buddhistDay: ["habit-a"], Self.gregorianDay: ["habit-b"]], forKey: kDayPlanCompletedHabitIdsByDay)
        defaults.set([Self.buddhistDay: ["habit-c"]], forKey: DayPlanHabitSkips.storageKey)
        defaults.set([Self.buddhistDay: ["habit-d": 300]], forKey: DayPlanHabitDurations.storageKey)
        defaults.set([Self.buddhistDay: ["event-1": 600], Self.gregorianDay: ["event-1": 900]],
                     forKey: DayPlanMeetingDurations.storageKey)

        migrate()

        XCTAssertEqual(defaults.dictionary(forKey: kDayPlanCompletedHabitIdsByDay) as? [String: [String]],
                       [Self.gregorianDay: ["habit-a", "habit-b"]])
        XCTAssertEqual(defaults.dictionary(forKey: DayPlanHabitSkips.storageKey) as? [String: [String]],
                       [Self.gregorianDay: ["habit-c"]])
        XCTAssertEqual(defaults.dictionary(forKey: DayPlanHabitDurations.storageKey) as? [String: [String: Int]],
                       [Self.gregorianDay: ["habit-d": 300]])
        XCTAssertEqual(defaults.dictionary(forKey: DayPlanMeetingDurations.storageKey) as? [String: [String: Int]],
                       [Self.gregorianDay: ["event-1": 900]], "the Gregorian day's own trim wins a collision")
    }

    func test_migration_runsOnce() {
        migrate()
        defaults.set([Self.buddhistDay: ["written-after-the-migration"]], forKey: DayPlanHabitSkips.storageKey)
        migrate()
        XCTAssertEqual(defaults.dictionary(forKey: DayPlanHabitSkips.storageKey) as? [String: [String]],
                       [Self.buddhistDay: ["written-after-the-migration"]])
    }

    func test_migration_leavesGregorianStoresUntouched() {
        let stored = [Self.gregorianDay: ["habit-a"]]
        defaults.set(stored, forKey: DayPlanHabitSkips.storageKey)
        migrate()
        XCTAssertEqual(defaults.dictionary(forKey: DayPlanHabitSkips.storageKey) as? [String: [String]], stored)
        XCTAssertTrue(defaults.bool(forKey: LegacyCalendarDateMigration.userDefaultsMigratedKey))
    }
}
