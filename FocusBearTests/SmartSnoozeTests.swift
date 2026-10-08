//
//  SmartSnoozeTests.swift
//  Focus BearTests
//
//  The smart-snooze planner shared by the Day Plan and the To-do list (SmartSnooze.swift): the
//  cumulative-rollover maths, the weekday-only horizon, the "Next free slot" choice and how several
//  tasks spread out. Free time and task load are injected per day, so nothing touches the schedule.
//

@testable import Focus_Bear
import XCTest

final class SmartSnoozeTests: XCTestCase {

    private let calendar = Calendar.current
    /// Monday 7 September 2026.
    private let monday: Date = {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 7
        return Calendar.current.date(from: components)!
    }()

    private func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: monday)! }
    private func weekday(_ date: Date) -> Int { calendar.component(.weekday, from: date) }

    /// A planner whose free minutes come from `free` (keyed by day offset from Monday) and whose open
    /// load comes from `load`; days not listed are empty.
    private func planner(free: [Int: Int], load: [Int: Int] = [:], sourceLoad: Int = 0) -> SmartSnoozePlanner {
        let offset = { (date: Date) -> Int in self.calendar.dateComponents([.day], from: self.monday, to: date).day ?? 0 }
        return SmartSnoozePlanner(sourceDate: monday,
                                  scheduleFreeMinutes: { free[offset($0)] ?? 0 },
                                  openTaskMinutes: { offset($0) == 0 ? sourceLoad : (load[offset($0)] ?? 0) })
    }

    // MARK: - Maths

    func testEffectiveFreeCarriesHalfTheLoadForward() {
        // Day 1 carries 0.5 × 100 = 50 into day 2, which then carries 0.5 × (20 + 50) = 35 into day 3.
        XCTAssertEqual(SmartSnoozeMath.effectiveFree(scheduleFree: [200, 200, 200], load: [100, 20, 0], rolloverFraction: 0.5), [100, 130, 165])
        // The source day's carry seeds the first day.
        XCTAssertEqual(SmartSnoozeMath.effectiveFree(scheduleFree: [200], load: [0], rolloverFraction: 0.5, initialCarry: 60), [140])
    }

    func testDistributeSpreadsTasksToDaysWithRoom() {
        // Two 90-minute tasks: the second can't share day 0 (100 − 180 < 0), and day 1 has the room to
        // absorb it plus the 45 that rolls over from day 0.
        let chosen = SmartSnoozeMath.distribute(taskDurations: [90, 90], scheduleFree: [100, 300, 100], startLoad: [0, 0, 0], rolloverFraction: 0.5)
        XCTAssertEqual(chosen, [0, 1])
        // Nothing fits anywhere: the emptiest day takes it.
        XCTAssertEqual(SmartSnoozeMath.distribute(taskDurations: [500], scheduleFree: [10, 300, 50], startLoad: [0, 0, 0], rolloverFraction: 0.5), [1])
    }

    func testDistributeSkipsPastDaysTheRolloverHasAlreadyFilled() {
        // Equally sized days: the first task takes day 0, and the 45 minutes that rolls over from it puts
        // day 1 out of reach (100 − 135 < 0) — so the second task jumps to day 2, the emptiest day left.
        XCTAssertEqual(SmartSnoozeMath.distribute(taskDurations: [90, 90], scheduleFree: [100, 100, 100], startLoad: [0, 0, 0], rolloverFraction: 0.5),
                       [0, 2])
    }

    // MARK: - Planner

    func testHorizonStartsTomorrowAndSkipsWeekends() {
        let horizon = planner(free: [:]).horizon(days: SmartSnoozePlanner.horizonDays)!
        XCTAssertEqual(horizon.first?.day, day(1), "tomorrow first")
        XCTAssertEqual(horizon.count, 10, "two working weeks")
        XCTAssertFalse(horizon.contains { weekday($0.day) == 1 || weekday($0.day) == 7 })
    }

    func testSlotIsTheFirstWeekdayWithEnoughEffectiveRoom() {
        // Tue has 60 free but 40 of load; Wed has 120 free and nothing on it.
        let slot = planner(free: [1: 60, 2: 120], load: [1: 40]).slot(requiredMinutes: 45)!
        XCTAssertEqual(slot.target, day(2))
        XCTAssertTrue(slot.fits)
        // A zero-length task still gets a day (the first one).
        XCTAssertEqual(planner(free: [1: 60]).slot(requiredMinutes: 0)?.target, day(1))
    }

    func testTodaysRemainingLoadSpillsIntoTomorrow() {
        // Tomorrow has 100 free, but today still holds 120 minutes of undone work: half of it (60) is
        // assumed to spill over, so a 50-minute task no longer fits tomorrow and lands on Wednesday.
        let slot = planner(free: [1: 100, 2: 100], sourceLoad: 120).slot(requiredMinutes: 50)!
        XCTAssertEqual(slot.target, day(2))
    }

    func testNothingFitsFallsBackToTheEmptiestDay() {
        let slot = planner(free: [1: 10, 2: 30, 3: 20]).slot(requiredMinutes: 240)!
        XCTAssertFalse(slot.fits)
        XCTAssertEqual(slot.target, day(2))
        XCTAssertEqual(slot.bestFree, 30)
    }

    func testBookedFortnightExtendsToALaterFreeWeek() {
        // Every weekday of the next two weeks is full; the Monday three weeks out (offset 21) is free.
        var free: [Int: Int] = [:]
        for offset in 1...14 { free[offset] = 0 }
        free[21] = 300
        let slot = planner(free: free).slot(requiredMinutes: 120)!
        XCTAssertEqual(slot.target, day(21))
        XCTAssertTrue(slot.fits)
    }

    func testDistributeMatchesTheSlotForOneTaskAndSpreadsSeveral() {
        let single = planner(free: [1: 60, 2: 120], load: [1: 40])
        XCTAssertEqual(single.distribute(durations: [45])?.first, single.slot(requiredMinutes: 45)?.target)
        let days = planner(free: [1: 100, 2: 300, 3: 100]).distribute(durations: [90, 90])!
        XCTAssertEqual(days, [day(1), day(2)])
    }

    // MARK: - Typed date parsing (parseSnoozeDate)

    /// A fixed "today" for the parser tests: Tuesday 15 September 2026.
    private let september15: Date = {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 15
        return Calendar.current.date(from: components)!
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        return Calendar.current.date(from: components)!
    }

    private func parsed(_ input: String, from base: Date? = nil) -> Date? {
        parseSnoozeDate(input, from: base ?? september15)
    }

    func testWeekdayWithAnExplicitDayNumberDoesNotSkipToday() {
        XCTAssertEqual(parsed("fri 18th", from: date(2026, 9, 18)), date(2026, 9, 18))
        XCTAssertEqual(parsed("Friday 18th", from: september15), date(2026, 9, 18))
        XCTAssertEqual(parsed("Fri, 18", from: september15), date(2026, 9, 18))
        XCTAssertEqual(parsed("fri", from: date(2026, 9, 18)), date(2026, 9, 25))
        XCTAssertNil(parsed("fri 19th", from: september15), "A conflicting day number must not be silently ignored")
    }

    func testExplicitWeekdayDateCanMoveSaturdayTaskBackToFriday() {
        for input in ["fri 18th", "fri 18", "Friday 18th"] {
            XCTAssertEqual(parsed(input, from: date(2026, 9, 19)), date(2026, 9, 18))
        }
        XCTAssertNil(parsed("fri 31st", from: date(2026, 9, 19)))
    }

    func testBareDayNumberMeansThatDayOfTheCurrentMonth() {
        // The reported bug: "23" / "23rd" on the 15th showed "— ?" instead of 23 September.
        XCTAssertEqual(parsed("23"), date(2026, 9, 23))
        XCTAssertEqual(parsed("23rd"), date(2026, 9, 23))
        XCTAssertEqual(parsed(" 23RD "), date(2026, 9, 23), "trimmed and case-insensitive")
        XCTAssertEqual(parsed("1st", from: date(2026, 9, 1)), date(2026, 9, 1), "today counts as this month")
        XCTAssertEqual(parsed("2nd", from: date(2026, 9, 1)), date(2026, 9, 2))
    }

    func testADayAlreadyPastThisMonthMeansNextMonth() {
        // The popover only moves tasks forward, so a day that has gone resolves to its next occurrence.
        XCTAssertEqual(parsed("3"), date(2026, 10, 3))
        XCTAssertEqual(parsed("14th"), date(2026, 10, 14))
        // …and rolls into the next year from December.
        XCTAssertEqual(parsed("5", from: date(2026, 12, 20)), date(2027, 1, 5))
    }

    func testADayTheMonthDoesNotHaveRollsToTheNextMonthThatDoes() {
        // February 2027 has 28 days: "31" means 31 March, never 3 March.
        XCTAssertEqual(parsed("31", from: date(2027, 2, 1)), date(2027, 3, 31))
        XCTAssertEqual(parsed("30", from: date(2027, 2, 1)), date(2027, 3, 30))
        // 2028 is a leap year, so the 29th does exist that February.
        XCTAssertEqual(parsed("29", from: date(2028, 2, 1)), date(2028, 2, 29))
    }

    func testNumbersThatAreNotDaysOfTheMonthAreStillRejected() {
        XCTAssertNil(parsed("0"))
        XCTAssertNil(parsed("32"))
        XCTAssertNil(parsed("99"))
    }

    func testTheExistingGrammarsStillParseAsBefore() {
        XCTAssertEqual(parsed("today"), september15)
        XCTAssertEqual(parsed("tod"), september15)
        XCTAssertEqual(parsed("tom"), date(2026, 9, 16))
        XCTAssertEqual(parsed("tomorrow"), date(2026, 9, 16))
        XCTAssertEqual(parsed("yesterday"), date(2026, 9, 14))
        XCTAssertEqual(parsed("-1d"), date(2026, 9, 14))
        XCTAssertEqual(parsed("2d"), date(2026, 9, 17))
        XCTAssertEqual(parsed("2w"), date(2026, 9, 29))
        XCTAssertEqual(parsed("3mo"), date(2026, 12, 15))
        XCTAssertEqual(parsed("1y"), date(2027, 9, 15))
        XCTAssertEqual(parsed("tue"), date(2026, 9, 22), "next occurrence, strictly after today")
        XCTAssertEqual(parsed("fri"), date(2026, 9, 18))
        XCTAssertEqual(parsed("1 Jul"), date(2027, 7, 1), "a date already past rolls forward a year")
        XCTAssertEqual(parsed("1 Dec"), date(2026, 12, 1))
        XCTAssertNil(parsed(""))
        XCTAssertNil(parsed("   "))
        XCTAssertNil(parsed("not a date"))
    }

    func testSmartButtonNamesTheSuggestedDay() {
        let formatter = DateFormatter()
        formatter.dateFormat = SmartSnoozePopover.suggestionDateFormat
        let slot = SmartSnoozeSlot(target: day(2), fits: true, bestFree: 100)
        XCTAssertTrue(SmartSnoozePopover.smartTitle(for: slot).contains(formatter.string(from: day(2))))
        XCTAssertEqual(SmartSnoozePopover.smartTitle(for: nil), ScheduleText.tasksSnoozeSmart)
    }
}
