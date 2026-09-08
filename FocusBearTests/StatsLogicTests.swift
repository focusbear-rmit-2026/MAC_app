//
//  StatsLogicTests.swift
//  Focus BearTests
//
//  Tests for the pure Stats-screen builders (heat-map grid, leaderboard ordering).
//

import XCTest
@testable import Focus_Bear

final class StatsLogicTests: XCTestCase {

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        StatsCalendar.calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func weekday(_ date: Date) -> Int { StatsCalendar.calendar.component(.weekday, from: date) }

    // Wed 26 Aug → Tue 8 Sep 2026, "today" = Sun 6 Sep: starts mid-week and crosses a month boundary.
    func testGridPadsToWholeWeeksAndGivesEveryDayACell() {
        let counts = [StatsDates.dayKey(day(2026, 8, 26)): 2, StatsDates.dayKey(day(2026, 9, 1)): 1]
        let model = HeatMapBuilder.grid(from: day(2026, 8, 26), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: counts)

        XCTAssertEqual(model.columns.count, 3)
        XCTAssertTrue(model.columns.allSatisfy { $0.count == HeatMapBuilder.daysInWeek })
        XCTAssertEqual(model.columns[0][0].date, day(2026, 8, 23))
        XCTAssertEqual(model.columns[2][6].date, day(2026, 9, 12))
        XCTAssertEqual(weekday(model.columns[0][0].date), StatsCalendar.calendar.firstWeekday)

        let allDays = model.columns.joined().map { $0.dayKey }
        XCTAssertEqual(Set(allDays).count, 21, "every day appears exactly once")
        XCTAssertEqual(model.columns[0][3].count, 2)
        XCTAssertEqual(model.columns[1][2].count, 1)
        XCTAssertEqual(model.maxCount, 2)
    }

    func testGridMarksDaysAfterTodayAsFuture() {
        let model = HeatMapBuilder.grid(from: day(2026, 8, 26), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: [:])
        let futureKeys = model.columns.joined().filter { $0.isFuture }.map { $0.dayKey }
        XCTAssertEqual(futureKeys, (7...12).map { StatsDates.dayKey(day(2026, 9, $0)) })
        XCTAssertFalse(model.columns[2][0].isFuture, "today itself is not future")
    }

    func testMonthLabelSitsOnTheWeekContainingTheFirst() {
        let model = HeatMapBuilder.grid(from: day(2026, 8, 26), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: [:])
        XCTAssertEqual(model.monthLabels.map { $0.weekIndex }, [1], "Aug would overlap Sep on the adjacent column")
        XCTAssertEqual(model.monthLabels[0].label, StatsDates.format(day(2026, 9, 1), "MMM"))
    }

    func testFirstColumnGetsItsOwnMonthWhenThereIsRoom() {
        let model = HeatMapBuilder.grid(from: day(2026, 8, 16), to: day(2026, 9, 8), today: day(2026, 9, 6), counts: [:])
        XCTAssertEqual(model.columns.count, 4)
        XCTAssertEqual(model.monthLabels.map { $0.weekIndex }, [0, 2])
        XCTAssertEqual(model.monthLabels.map { $0.label },
                       [StatsDates.format(day(2026, 8, 1), "MMM"), StatsDates.format(day(2026, 9, 1), "MMM")])
    }

    func testBuildCoversFiveWeeksBackPlusTheCurrentWeek() {
        let today = day(2026, 9, 4)   // a Friday
        let model = HeatMapBuilder.build(items: [], joinDate: nil, today: today)
        XCTAssertEqual(model.columns.count, HeatMapBuilder.weeksToShow + 1)
        XCTAssertEqual(model.columns[0][0].date, day(2026, 7, 26))
        XCTAssertEqual(model.columns.last?.last?.date, day(2026, 9, 5))
        XCTAssertLessThanOrEqual(StatsCalendar.daysBetween(model.columns[0][0].date, today) + 1, HeatMapBuilder.fetchDays,
                                 "the request must cover the whole grid")
    }

    // MARK: - Leaderboard ordering

    private func user(_ name: String, morning: (streak: Double, percent: Double?, done: Double, days: Double) = (0, 0, 0, 90),
                      micro: (streak: Double, percent: Double?, done: Double, days: Double) = (0, 0, 0, 90),
                      evening: (streak: Double, percent: Double?, done: Double, days: Double) = (0, 0, 0, 90),
                      focus: (streak: Double, done: Double, days: Double) = (0, 0, 90)) -> LeaderboardUser {
        LeaderboardUser(id: name, username: name,
                        morningRoutinesStreak: FlexibleNumber(morning.streak), eveningRoutinesStreak: FlexibleNumber(evening.streak),
                        focusModesStreak: FlexibleNumber(focus.streak), microBreaksStreak: FlexibleNumber(micro.streak),
                        morningPercentNumberDayOfStatsCompleted: morning.percent.map(FlexibleNumber.init),
                        eveningPercentNumberDayOfStatsCompleted: evening.percent.map(FlexibleNumber.init),
                        microPercentNumberDayOfStatsCompleted: micro.percent.map(FlexibleNumber.init),
                        morningNumberDaysCompleted: FlexibleNumber(morning.done), morningNumDaysOfStats: FlexibleNumber(morning.days),
                        eveningNumberDaysCompleted: FlexibleNumber(evening.done), eveningNumDaysOfStats: FlexibleNumber(evening.days),
                        microBreaksNumberDaysCompleted: FlexibleNumber(micro.done), microBreaksNumDaysOfStats: FlexibleNumber(micro.days),
                        focusModesNumberDaysCompleted: FlexibleNumber(focus.done), focusModesNumDaysOfStats: FlexibleNumber(focus.days))
    }

    private func names(_ users: [LeaderboardUser]) -> [String] { users.map { $0.username ?? "" } }

    /// The reported bug: rows in rank order (77%, 10%, 28%, 0%, 2%) because the sort used the raw
    /// streak count. Break streak must order by the percentage the column shows.
    func testBreakStreakSortsByPercentageNotStreakCount() {
        let users = [user("jeznag", micro: (19, 77, 69, 90)), user("andrea", micro: (0, 10, 9, 90)),
                     user("bev", micro: (0, 28, 25, 90)), user("gwest", micro: (0, 0, 0, 90)), user("richter", micro: (0, 2, 2, 90))]
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .microBreak, ascending: false)),
                       ["jeznag", "bev", "andrea", "richter", "gwest"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .microBreak, ascending: true)),
                       ["gwest", "richter", "andrea", "bev", "jeznag"])
    }

    func testEachColumnSortsByItsOwnPercentage() {
        let users = [user("a", morning: (1, 10, 9, 90), micro: (1, 90, 81, 90), evening: (1, 50, 45, 90), focus: (1, 9, 90)),
                     user("b", morning: (1, 90, 81, 90), micro: (1, 10, 9, 90), evening: (1, 20, 18, 90), focus: (1, 81, 90)),
                     user("c", morning: (1, 50, 45, 90), micro: (1, 50, 45, 90), evening: (1, 90, 81, 90), focus: (1, 45, 90))]
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .morning, ascending: false)), ["b", "c", "a"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .microBreak, ascending: false)), ["a", "c", "b"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .evening, ascending: false)), ["c", "a", "b"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .focusMode, ascending: false)), ["b", "c", "a"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .morning, ascending: true)), ["a", "c", "b"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .focusMode, ascending: true)), ["a", "c", "b"])
    }

    func testTiesBreakOnDaysCompletedThenStreakThenServerOrder() {
        // Same 50%: more days completed wins; same days: longer streak wins; identical: server order.
        let users = [user("first", evening: (2, 50, 30, 60)), user("second", evening: (9, 50, 30, 60)),
                     user("third", evening: (3, 50, 45, 90)), user("fourth", evening: (2, 50, 30, 60))]
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .evening, ascending: false)), ["third", "second", "first", "fourth"])
        XCTAssertEqual(names(LeaderboardSorting.sort(users, by: .evening, ascending: true)), ["first", "fourth", "second", "third"],
                       "ascending flips the comparison but fully tied rows keep the server's order")
    }

    func testFocusModePercentageComesFromTheDayPair() {
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (138, 84, 90)), key: .focusMode).percentage, 93)
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (138, 84, 90)), key: .focusMode).streak, 138)
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (0, 1, 3)), key: .focusMode).percentage, 33)
        XCTAssertEqual(LeaderboardSorting.metric(user("x", focus: (0, 0, 0)), key: .focusMode).percentage, 0, "no window → 0%, not NaN")
        XCTAssertEqual(LeaderboardSorting.percentage(completedDays: 90, windowDays: 90), 100)
    }

    func testServerPercentageWinsWhenPresentAndIsDerivedOtherwise() {
        XCTAssertEqual(LeaderboardSorting.metric(user("x", morning: (1, 50, 88, 90)), key: .morning).percentage, 50,
                       "the web shows the server's percentage column as-is")
        XCTAssertEqual(LeaderboardSorting.metric(user("x", morning: (1, nil, 88, 90)), key: .morning).percentage, 98)
    }

    func testSortKeysAreTheBackendStreakTypes() {
        XCTAssertEqual(LeaderboardSortKey.allCases.map { $0.rawValue },
                       ["morning_routines_streak", "micro_breaks_streak", "evening_routines_streak", "focus_modes_streak"])
    }

    // MARK: - Heat-map weekday labels

    func testWeekdayLabelsAreSundayFirstInTheAppLanguage() {
        XCTAssertEqual(StatsCalendar.shortWeekdaySymbols(languageCode: "en"), ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        let spanish = StatsCalendar.shortWeekdaySymbols(languageCode: "es")
        XCTAssertEqual(spanish.count, 7)
        XCTAssertTrue(spanish[0].lowercased().hasPrefix("dom"), "\(spanish)")
        XCTAssertEqual(StatsCalendar.shortWeekdaySymbols(languageCode: "").count, 7)
    }
}
