//
//  SettingsManagerTests.swift
//  FocusBearTests
//
//  Tests for SettingsManager utility methods.
//  Issue: Focus-Bear/Mac-App#1629
//

@testable import Focus_Bear
import XCTest

class SettingsManagerTests: XCTestCase {

    var settings: SettingsManager!

    override func setUp() {
        super.setUp()
        settings = SettingsManager()
        // getCurrentStrictnessLevel() reads this UserDefaults key directly.
        // Set it to a known value so strictness tests are deterministic.
        UserDefaults.standard.set(false,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
    }

    override func tearDown() {
        settings = nil
        UserDefaults.standard.removeObject(
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        super.tearDown()
    }

    // MARK: - getDayOfWeek

    func test_getDayOfWeek_sunday() {
        // 2024-01-07 was a Sunday
        let date = makeDateWith(year: 2024, month: 1, day: 7)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Sunday")
    }

    func test_getDayOfWeek_monday() {
        // 2024-01-08 was a Monday
        let date = makeDateWith(year: 2024, month: 1, day: 8)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Monday")
    }

    func test_getDayOfWeek_tuesday() {
        let date = makeDateWith(year: 2024, month: 1, day: 9)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Tuesday")
    }

    func test_getDayOfWeek_wednesday() {
        let date = makeDateWith(year: 2024, month: 1, day: 10)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Wednesday")
    }

    func test_getDayOfWeek_thursday() {
        let date = makeDateWith(year: 2024, month: 1, day: 11)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Thursday")
    }

    func test_getDayOfWeek_friday() {
        let date = makeDateWith(year: 2024, month: 1, day: 12)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Friday")
    }

    func test_getDayOfWeek_saturday() {
        let date = makeDateWith(year: 2024, month: 1, day: 13)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Saturday")
    }

    func test_getDayOfWeek_yearBoundary() {
        // 2024-12-31 was a Tuesday
        let date = makeDateWith(year: 2024, month: 12, day: 31)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Tuesday")
    }

    func test_getDayOfWeek_leapDay() {
        // 2024-02-29 was a Thursday
        let date = makeDateWith(year: 2024, month: 2, day: 29)!
        XCTAssertEqual(settings.getDayOfWeek(fromDate: date), "Thursday")
    }

    // MARK: - SettingsManager default values

    func test_defaultBlockedUrls_isEmpty() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.arrBlockedUrls.isEmpty,
            "A freshly initialised SettingsManager should have no blocked URLs")
    }

    func test_defaultBlockedApps_isEmpty() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.arrBlockedApps.isEmpty,
            "A freshly initialised SettingsManager should have no blocked apps")
    }

    func test_defaultAlwaysAllowedApps_isEmpty() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.arrAlwaysAllowedApps.isEmpty)
    }

    func test_defaultEasySkipEnabled_isTrue() {
        let fresh = SettingsManager()
        XCTAssertTrue(fresh.isEasySkipEnabled,
            "Easy-skip should be on by default")
    }

    func test_defaultFullScreenEnabled_isFalse() {
        let fresh = SettingsManager()
        XCTAssertFalse(fresh.isFullScreenEnabled,
            "Full-screen blocking should be off by default (set false for onboarding)")
    }

    // MARK: - getCurrentStrictnessLevel

    func test_getCurrentStrictnessLevel_returnsAnInt() {
        // Use a freshly-initialised instance with known property values so the
        // result does not depend on whatever state other tests left on the
        // shared SettingsManagerObject global.
        let fresh = SettingsManager()
        fresh.isFullScreenEnabled              = false
        fresh.isCuddlyModeEnabled              = true
        fresh.isEasySkipEnabled                = true
        fresh.shouldReloadAfterForceQuitEnabled = false
        fresh.immediatelyBlockDistractingSites = false
        fresh.immediatelyBlockDistractingApps  = false
        fresh.isRequiredIntentionInPostpone    = false

        let level = fresh.getCurrentStrictnessLevel()
        // Strictness buckets are 1...5 (see strictnessLevel* constants).
        XCTAssertGreaterThanOrEqual(level, 1)
        XCTAssertLessThanOrEqual(level, 5)
    }

    func test_getCurrentStrictnessLevel_withFullScreenEnabled_higherThanWithout() {
        let sm1 = SettingsManager()
        sm1.isFullScreenEnabled = false
        sm1.isCuddlyModeEnabled = true
        sm1.isEasySkipEnabled   = true
        let levelLow = sm1.getCurrentStrictnessLevel()

        let sm2 = SettingsManager()
        sm2.isFullScreenEnabled = true
        sm2.isCuddlyModeEnabled = false
        sm2.isEasySkipEnabled   = false
        let levelHigh = sm2.getCurrentStrictnessLevel()

        XCTAssertLessThan(levelLow, levelHigh,
            "Stricter settings should produce a higher strictness level")
    }

    // MARK: - Helpers

    private func makeDateWith(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year  = year
        components.month = month
        components.day   = day
        return Calendar(identifier: .gregorian).date(from: components)
    }
}
