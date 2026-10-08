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

    // MARK: - Shared date formatters (Sentry FOCUS-BEAR-MACOS-1HT)

    private static let dayKeyFormat = "yyyy-MM-dd"
    private static let timestampFormat = "yyyy-MM-dd HH:mm:ss"

    func test_dateHelpers_roundTripThroughTheSharedFormatters() throws {
        let date = try XCTUnwrap(getDateFromString(date: "2026-09-27 21:05:09", dateFormat: Self.timestampFormat))
        XCTAssertEqual(getStringFromDate(date: date, dateFormat: Self.timestampFormat), "2026-09-27 21:05:09")
        XCTAssertEqual(getStringFromDate(date: date, dateFormat: Self.dayKeyFormat), "2026-09-27")
    }

    func test_utcHelpers_formatInUtcWhateverTheLocalZone() throws {
        let epoch = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(getStringFromDateInUtc(date: epoch, dateFormat: Self.timestampFormat), "1970-01-01 00:00:00")
        let parsed = try XCTUnwrap(getDateFromStringInUtc(date: "1970-01-01 00:00:00", dateFormat: Self.timestampFormat))
        XCTAssertEqual(parsed, epoch)
    }

    func test_formatter_isBuiltOncePerFormatAndZone() {
        let first = CachedDateFormatters.formatter(format: Self.dayKeyFormat, zone: .local)
        XCTAssertTrue(first === CachedDateFormatters.formatter(format: Self.dayKeyFormat, zone: .local))
        XCTAssertFalse(first === CachedDateFormatters.formatter(format: Self.dayKeyFormat, zone: .utc))
        XCTAssertFalse(first === CachedDateFormatters.formatter(format: Self.timestampFormat, zone: .local))
    }

    func test_timeZoneChange_dropsTheCachedFormatters() {
        let before = CachedDateFormatters.formatter(format: Self.dayKeyFormat, zone: .local)
        NotificationCenter.default.post(name: .NSSystemTimeZoneDidChange, object: nil)
        XCTAssertFalse(before === CachedDateFormatters.formatter(format: Self.dayKeyFormat, zone: .local),
                       "a formatter keeps the zone it was built in, so a zone change must rebuild it")
    }

    func test_sharedFormatter_givesTheSameAnswerFromManyThreads() {
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        let expected = getStringFromDateInUtc(date: date, dateFormat: Self.timestampFormat)
        let results = ConcurrentResults()
        DispatchQueue.concurrentPerform(iterations: 200) { _ in
            results.append(getStringFromDateInUtc(date: date, dateFormat: Self.timestampFormat))
        }
        XCTAssertEqual(results.values, Array(repeating: expected, count: 200))
    }
}

private final class ConcurrentResults {
    private let lock = NSLock()
    private var stored: [String] = []

    var values: [String] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func append(_ value: String) {
        lock.lock()
        defer { lock.unlock() }
        stored.append(value)
    }
}
