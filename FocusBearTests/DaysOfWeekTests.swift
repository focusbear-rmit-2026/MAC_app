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

    // MARK: - isHabitAlreadyShown (crash regression)
    //
    // AppDelegate.checkLastHabitShowDate force-unwrapped the global `startTime`, so a nil start time
    // took the app down on launch with EXC_BREAKPOINT — reported as "Focus Bear quit unexpectedly",
    // trace readSettingsAndLoadApp -> checkWindowState -> checkLastHabitShowDate.

    private func moment(_ hour: Int, _ minute: Int, day: Int = 10) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 9; c.day = day; c.hour = hour; c.minute = minute; c.second = 0
        return Calendar.current.date(from: c)!
    }

    func testNoRoutineStartTimeDoesNotCrashAndComparesOnCalendarDay() {
        // The crash case: settings not loaded yet, or a profile whose startup time never parsed.
        XCTAssertFalse(isHabitAlreadyShown(lastShown: moment(9, 0, day: 9), now: moment(9, 0), routineStart: nil))
        XCTAssertTrue(isHabitAlreadyShown(lastShown: moment(9, 0), now: moment(11, 0), routineStart: nil))
    }

    func testBeforeRoutineStartStillCountsAsYesterdaysRoutineDay() {
        // 01:00 against an 07:00 start is still the 9th's routine day, so the 9th's showing stands.
        XCTAssertTrue(isHabitAlreadyShown(lastShown: moment(8, 0, day: 9), now: moment(1, 0), routineStart: Time(hour: 7, minute: 0, second: 0)))
    }

    func testAfterRoutineStartANewDayHasNotBeenShown() {
        XCTAssertFalse(isHabitAlreadyShown(lastShown: moment(8, 0, day: 9), now: moment(9, 0), routineStart: Time(hour: 7, minute: 0, second: 0)))
    }

    func testSameRoutineDayCountsAsAlreadyShown() {
        XCTAssertTrue(isHabitAlreadyShown(lastShown: moment(8, 0), now: moment(9, 0), routineStart: Time(hour: 7, minute: 0, second: 0)))
    }

    func testAFutureLastShownDateIsTreatedAsAlreadyShown() {
        // A clock change or restored backup can leave the stored date ahead of now; don't re-show on that.
        XCTAssertTrue(isHabitAlreadyShown(lastShown: moment(9, 0, day: 11), now: moment(9, 0), routineStart: nil))
    }
}
