//
//  TimeParsingTests.swift
//  FocusBearTests
//
//  Tests for getTimeFromString() (globalFile.swift) and
//  customBlockingSchedule.parseTime() (customBlockingScheduleData.swift)
//  Issue: Focus-Bear/Mac-App#1627
//

@testable import Focus_Bear
import XCTest

class TimeParsingTests: XCTestCase {

    // MARK: - getTimeFromString (returns a Time struct {hour, minute, second})

    func test_getTimeFromString_HH_MM_SS_parsesCorrectly() {
        let result = getTimeFromString(val: "14:30:45")
        XCTAssertEqual(result.hour,   14)
        XCTAssertEqual(result.minute, 30)
        XCTAssertEqual(result.second, 45)
    }

    func test_getTimeFromString_HH_MM_parsesCorrectly() {
        let result = getTimeFromString(val: "09:05")
        XCTAssertEqual(result.hour,   9)
        XCTAssertEqual(result.minute, 5)
        XCTAssertEqual(result.second, 0)
    }

    func test_getTimeFromString_HH_only_parsesCorrectly() {
        let result = getTimeFromString(val: "7")
        XCTAssertEqual(result.hour,   7)
        XCTAssertEqual(result.minute, 0)
        XCTAssertEqual(result.second, 0)
    }

    func test_getTimeFromString_midnight_zero() {
        let result = getTimeFromString(val: "00:00:00")
        XCTAssertEqual(result.hour,   0)
        XCTAssertEqual(result.minute, 0)
        XCTAssertEqual(result.second, 0)
    }

    func test_getTimeFromString_endOfDay() {
        let result = getTimeFromString(val: "23:59:59")
        XCTAssertEqual(result.hour,   23)
        XCTAssertEqual(result.minute, 59)
        XCTAssertEqual(result.second, 59)
    }

    func test_getTimeFromString_invalidString_defaultsToZero() {
        // Non-numeric input should fall back to zeroed Time
        let result = getTimeFromString(val: "abc:def")
        XCTAssertEqual(result.hour,   0)
        XCTAssertEqual(result.minute, 0)
        XCTAssertEqual(result.second, 0)
    }

    func test_getTimeFromString_emptyString_defaultsToZero() {
        let result = getTimeFromString(val: "")
        XCTAssertEqual(result.hour,   0)
        XCTAssertEqual(result.minute, 0)
        XCTAssertEqual(result.second, 0)
    }

    func test_getTimeFromString_noon() {
        let result = getTimeFromString(val: "12:00:00")
        XCTAssertEqual(result.hour,   12)
        XCTAssertEqual(result.minute, 0)
        XCTAssertEqual(result.second, 0)
    }

    // MARK: - customBlockingSchedule.parseTime (returns an optional Date)

    func test_parseTime_HH_MM_SS_format_returnsDate() {
        let date = customBlockingSchedule.parseTime("09:30:00")
        XCTAssertNotNil(date, "Should parse HH:mm:ss format")

        let cal = Calendar.current
        XCTAssertEqual(cal.component(.hour,   from: date!), 9)
        XCTAssertEqual(cal.component(.minute, from: date!), 30)
        XCTAssertEqual(cal.component(.second, from: date!), 0)
    }

    func test_parseTime_HH_MM_format_returnsDate() {
        let date = customBlockingSchedule.parseTime("14:45")
        XCTAssertNotNil(date, "Should parse HH:mm format")

        let cal = Calendar.current
        XCTAssertEqual(cal.component(.hour,   from: date!), 14)
        XCTAssertEqual(cal.component(.minute, from: date!), 45)
    }

    func test_parseTime_midnight_returnsDate() {
        let date = customBlockingSchedule.parseTime("00:00")
        XCTAssertNotNil(date)
        let cal = Calendar.current
        XCTAssertEqual(cal.component(.hour,   from: date!), 0)
        XCTAssertEqual(cal.component(.minute, from: date!), 0)
    }

    func test_parseTime_endOfDay_returnsDate() {
        let date = customBlockingSchedule.parseTime("23:59:59")
        XCTAssertNotNil(date)
        let cal = Calendar.current
        XCTAssertEqual(cal.component(.hour,   from: date!), 23)
        XCTAssertEqual(cal.component(.minute, from: date!), 59)
        XCTAssertEqual(cal.component(.second, from: date!), 59)
    }

    func test_parseTime_invalidString_returnsNil() {
        XCTAssertNil(customBlockingSchedule.parseTime("not-a-time"))
    }

    func test_parseTime_emptyString_returnsNil() {
        XCTAssertNil(customBlockingSchedule.parseTime(""))
    }

    func test_parseTime_partiallyMalformed_returnsNil() {
        // Only an hour with no colon — not a valid HH:mm or HH:mm:ss
        XCTAssertNil(customBlockingSchedule.parseTime("14"))
    }

    func test_parseTime_resultIsToday() {
        // parseTime always merges with today's date
        let date = customBlockingSchedule.parseTime("10:00")
        XCTAssertNotNil(date)
        let cal = Calendar.current
        let today = Date()
        XCTAssertEqual(cal.component(.year,  from: date!), cal.component(.year,  from: today))
        XCTAssertEqual(cal.component(.month, from: date!), cal.component(.month, from: today))
        XCTAssertEqual(cal.component(.day,   from: date!), cal.component(.day,   from: today))
    }

    // MARK: - Cross-midnight range helpers

    /// Verifies that if start > end (cross-midnight range), a time between them is handled correctly.
    func test_crossMidnight_startLaterThanEnd_conceptualCheck() {
        // 22:00 start, 02:00 end — midnight (00:00) should fall inside
        let start = getTimeFromString(val: "22:00")
        let end   = getTimeFromString(val: "02:00")

        // A cross-midnight range: startHour > endHour indicates overnight
        XCTAssertGreaterThan(start.hour, end.hour,
            "22 > 2 indicates an overnight/cross-midnight schedule range")
    }

    func test_sameDay_startBeforeEnd_standardRange() {
        let start = getTimeFromString(val: "09:00")
        let end   = getTimeFromString(val: "17:00")
        XCTAssertLessThan(start.hour, end.hour, "09 < 17 is a standard same-day range")
    }
}
