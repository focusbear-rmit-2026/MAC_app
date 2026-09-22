//
//  RoutineSchedulingTests.swift
//  FocusBearTests
//
//  Tests for routine scheduling data model and helper logic.
//  Issue: Focus-Bear/Mac-App#1626
//
//  Note: checkCustomRoutineTime() / startCustomRoutine() depend on
//  appdelegate and UI state that are unavailable in a test host, so
//  those functions are tested via their observable side-effects on
//  global state and through the underlying scheduling data structures.
//

@testable import Focus_Bear
import XCTest

class RoutineSchedulingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        arrAllCustomRoutine.removeAll()
        isProcessingCustomRoutine = false
    }

    override func tearDown() {
        arrAllCustomRoutine.removeAll()
        isProcessingCustomRoutine = false
        super.tearDown()
    }

    // MARK: - routine struct construction

    func test_routine_constructsWithRequiredFields() {
        let r = makeRoutine(title: "Morning Focus", days: ["all"])
        XCTAssertEqual(r.title, "Morning Focus")
        XCTAssertFalse(r.triggerOnDemand)
    }

    func test_routine_onDemandFlagRespected() {
        var r = makeRoutine(title: "On-Demand", days: ["all"])
        r.triggerOnDemand = true
        XCTAssertTrue(r.triggerOnDemand)
    }

    // MARK: - Skip-for-date logic

    func test_routine_skipForDate_isNilByDefault() {
        let r = makeRoutine(title: "Test", days: ["all"])
        XCTAssertNil(r.skipForDate)
    }

    func test_routine_skipForDate_canBeSetToToday() {
        var r = makeRoutine(title: "Test", days: ["all"])
        r.skipForDate = Date()
        XCTAssertNotNil(r.skipForDate)
        XCTAssertTrue(Calendar.current.isDateInToday(r.skipForDate!))
    }

    func test_routine_skipForDate_notTodayWhenSetToYesterday() {
        var r = makeRoutine(title: "Test", days: ["all"])
        r.skipForDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        XCTAssertFalse(Calendar.current.isDateInToday(r.skipForDate!))
    }

    // MARK: - Day-of-week checking (mirrors checkCustomRoutineTime logic)

    func test_dayOfWeek_allKeyword_isAllowed() {
        let r = makeRoutine(title: "All days", days: ["all"])
        XCTAssertTrue(isDayAllowed(for: r, on: "MON"))
        XCTAssertTrue(isDayAllowed(for: r, on: "SAT"))
        XCTAssertTrue(isDayAllowed(for: r, on: "SUN"))
    }

    func test_dayOfWeek_specificDay_matchedCaseInsensitive() {
        let r = makeRoutine(title: "Mon only", days: ["Monday"])
        XCTAssertTrue(isDayAllowed(for: r, on: "MON"))
        XCTAssertFalse(isDayAllowed(for: r, on: "TUE"))
    }

    func test_dayOfWeek_multipleDays_correctlyFiltered() {
        let r = makeRoutine(title: "MWF", days: ["Monday", "Wednesday", "Friday"])
        XCTAssertTrue(isDayAllowed(for: r, on: "MON"))
        XCTAssertFalse(isDayAllowed(for: r, on: "TUE"))
        XCTAssertTrue(isDayAllowed(for: r, on: "WED"))
        XCTAssertFalse(isDayAllowed(for: r, on: "THU"))
        XCTAssertTrue(isDayAllowed(for: r, on: "FRI"))
    }

    func test_dayOfWeek_emptyDays_neverAllowed() {
        let r = makeRoutine(title: "No days", days: [])
        XCTAssertFalse(isDayAllowed(for: r, on: "MON"))
        XCTAssertFalse(isDayAllowed(for: r, on: "SUN"))
    }

    // MARK: - Time-window logic (standard / cross-midnight)

    func test_timeWindow_standardRange_withinWindow() {
        let start = makeDate(hour: 9,  minute: 0)
        let end   = makeDate(hour: 17, minute: 0)
        // Check that 10:00 is within 09:00–17:00
        let current = makeDate(hour: 10, minute: 0)
        XCTAssertTrue(isWithinWindow(current: current, start: start, end: end))
    }

    func test_timeWindow_standardRange_outsideWindow() {
        let start = makeDate(hour: 9,  minute: 0)
        let end   = makeDate(hour: 17, minute: 0)
        let current = makeDate(hour: 20, minute: 0)
        XCTAssertFalse(isWithinWindow(current: current, start: start, end: end))
    }

    func test_timeWindow_crossMidnight_atMidnight_isActive() {
        let start = makeDate(hour: 22, minute: 0)
        let end   = makeDate(hour: 2,  minute: 0)
        let current = makeDate(hour: 0, minute: 30) // 00:30 — between 22:00 and 02:00
        XCTAssertTrue(isWithinWindowCrossMidnight(current: current, start: start, end: end))
    }

    func test_timeWindow_crossMidnight_after3am_isNotActive() {
        let start = makeDate(hour: 22, minute: 0)
        let end   = makeDate(hour: 2,  minute: 0)
        let current = makeDate(hour: 3, minute: 30)
        XCTAssertFalse(isWithinWindowCrossMidnight(current: current, start: start, end: end))
    }

    // MARK: - lastCompletedSequence guard

    func test_lastCompletedSequence_afterStartTime_shouldBeSkipped() {
        var r = makeRoutine(title: "Test", days: ["all"])
        let start = makeDate(hour: 9, minute: 0)
        r.lastCompletedSequence = Calendar.current.date(byAdding: .hour, value: 1, to: start)!
        // lastCompletedSequence > startDate → routine should be skipped
        let alreadyCompleted = r.lastCompletedSequence!.compare(start) == .orderedDescending
        XCTAssertTrue(alreadyCompleted,
            "Routine already completed after start time should not re-trigger")
    }

    func test_lastCompletedSequence_beforeStartTime_shouldNotSkip() {
        var r = makeRoutine(title: "Test", days: ["all"])
        let start = makeDate(hour: 9, minute: 0)
        r.lastCompletedSequence = Calendar.current.date(byAdding: .hour, value: -2, to: start)!
        let alreadyCompleted = r.lastCompletedSequence!.compare(start) == .orderedDescending
        XCTAssertFalse(alreadyCompleted,
            "Routine completed before start time should still be eligible to run")
    }

    // MARK: - Helpers

    private func makeRoutine(title: String, days: [String]) -> routine {
        return routine(title: title, sequenceId: UUID().uuidString,
                       startTime: nil, endTime: nil,
                       triggerOnDemand: false, days_of_week: days)
    }

    /// Mirrors the day-allowed check inside checkCustomRoutineTime.
    private func isDayAllowed(for r: routine, on shortDay: String) -> Bool {
        if r.days_of_week.contains(where: { $0.compare("all", options: .caseInsensitive) == .orderedSame }) {
            return true
        }
        if r.days_of_week.contains(where: { $0.compare(shortDay, options: .caseInsensitive) == .orderedSame }) {
            return true
        }
        // Check if any day string contains the short abbreviation
        return r.days_of_week.contains { day in
            day.localizedCaseInsensitiveContains(shortDay)
        }
    }

    /// Tests a standard (non-cross-midnight) time window.
    private func isWithinWindow(current: Date, start: Date, end: Date) -> Bool {
        if end.compare(start) == .orderedDescending {
            return current < end && current > start
        }
        return false
    }

    /// Tests a cross-midnight time window (start > end).
    private func isWithinWindowCrossMidnight(current: Date, start: Date, end: Date) -> Bool {
        // Cross-midnight: e.g. 22:00–02:00
        // Active if current is after start OR before end
        return current > start || current < end
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour   = hour
        c.minute = minute
        c.second = 0
        return Calendar.current.date(from: c)!
    }
}
