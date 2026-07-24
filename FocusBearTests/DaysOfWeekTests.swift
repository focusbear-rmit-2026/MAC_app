//
//  DaysOfWeekTests.swift
//  Focus BearTests
//
//  Tests for isScheduledForWeekday — the shared days-of-week gate used when
//  filtering routines and morning/evening habits for the current day.
//

import XCTest
@testable import Focus_Bear

final class DaysOfWeekTests: XCTestCase {

    private let allDays = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    func testAllMatchesEveryDay() {
        for day in allDays {
            XCTAssertTrue(isScheduledForWeekday(["all"], currentWeekDay: day), "'all' should match \(day)")
        }
    }

    func testWeekdaysMatchesMondayToFriday() {
        for day in ["MON", "TUE", "WED", "THU", "FRI"] {
            XCTAssertTrue(isScheduledForWeekday(["weekdays"], currentWeekDay: day), "'weekdays' should match \(day)")
        }
    }

    func testWeekdaysExcludesSaturdayAndSunday() {
        XCTAssertFalse(isScheduledForWeekday(["weekdays"], currentWeekDay: "SAT"))
        // Regression: the old inline checks tested "sat" twice, so Sunday
        // incorrectly counted as a weekday.
        XCTAssertFalse(isScheduledForWeekday(["weekdays"], currentWeekDay: "SUN"))
    }

    func testWeekendMatchesSaturdayAndSunday() {
        XCTAssertTrue(isScheduledForWeekday(["weekend"], currentWeekDay: "SAT"))
        // Regression: the old inline checks tested "sat" twice, so 'weekend'
        // never matched Sunday.
        XCTAssertTrue(isScheduledForWeekday(["weekend"], currentWeekDay: "SUN"))
    }

    func testWeekendExcludesWeekdays() {
        for day in ["MON", "TUE", "WED", "THU", "FRI"] {
            XCTAssertFalse(isScheduledForWeekday(["weekend"], currentWeekDay: day), "'weekend' should not match \(day)")
        }
    }

    func testNamedDayMatchesCaseInsensitively() {
        XCTAssertTrue(isScheduledForWeekday(["MON", "WED"], currentWeekDay: "WED"))
        XCTAssertTrue(isScheduledForWeekday(["wed"], currentWeekDay: "WED"))
        XCTAssertFalse(isScheduledForWeekday(["MON", "WED"], currentWeekDay: "TUE"))
    }

    func testEmptyListMatchesNothing() {
        for day in allDays {
            XCTAssertFalse(isScheduledForWeekday([], currentWeekDay: day))
        }
    }

    func testDayOfWeekUsesEnglishDayNames() {
        // 2026-07-05 is a Sunday; en_US_POSIX must yield "SUN" regardless of system locale.
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 5
        let sunday = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(sunday.dayOfWeek(), "SUN")
        XCTAssertTrue(isScheduledForWeekday(["weekend"], currentWeekDay: sunday.dayOfWeek()))
    }
}
