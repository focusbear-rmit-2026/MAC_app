//
//  BusyHoursCalculatorTests.swift
//  Focus BearTests
//
//  The pure maths behind the `PUT /portfolio/busy-hours` report (#2418): overlapping events count
//  once, an event across midnight is shared between its days, and all-day / declined / cancelled /
//  dismissed events don't occupy the user's time.
//

@testable import Focus_Bear
import XCTest

final class BusyHoursCalculatorTests: XCTestCase {

    private let calendar = Calendar.current
    private lazy var today = calendar.startOfDay(for: Date())
    private lazy var todayKey = BusyHoursCalculator.dayKey(today, calendar: calendar)
    private lazy var tomorrowKey = BusyHoursCalculator.dayKey(day(1), calendar: calendar)

    private func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today)! }

    private func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day(dayOffset))!
    }

    private func event(_ start: Date, _ end: Date, allDay: Bool = false, cancelled: Bool = false,
                       declined: Bool = false, dismissed: Bool = false) -> BusyEventInput {
        BusyEventInput(start: start, end: end, isAllDay: allDay, isCancelled: cancelled, isDeclined: declined, isDismissed: dismissed)
    }

    private func hours(_ events: [BusyEventInput], horizonDays: Int = 3) -> [String: Double] {
        BusyHoursCalculator.hoursByDay(events: events, firstDay: today, horizonDays: horizonDays, calendar: calendar)
    }

    // MARK: - Merging

    func testOverlappingEventsCountOnce() {
        // 9–10:30 and 10–11 overlap by 30 minutes: 2 hours of busy time, not 2.5.
        let result = hours([event(at(0, 9), at(0, 10, 30)), event(at(0, 10), at(0, 11))])
        XCTAssertEqual(result[todayKey], 2)
    }

    func testNestedAndTouchingEventsMerge() {
        // 9–12 contains 10–11; 12–13 touches 9–12 → one 9–13 block.
        let result = hours([event(at(0, 10), at(0, 11)), event(at(0, 9), at(0, 12)), event(at(0, 12), at(0, 13))])
        XCTAssertEqual(result[todayKey], 4)
    }

    func testMergeKeepsSeparateIntervalsApart() {
        let merged = BusyHoursCalculator.merge([
            BusyHoursCalculator.Interval(start: at(0, 14), end: at(0, 15)),
            BusyHoursCalculator.Interval(start: at(0, 9), end: at(0, 10)),
        ])
        XCTAssertEqual(merged, [BusyHoursCalculator.Interval(start: at(0, 9), end: at(0, 10)),
                                BusyHoursCalculator.Interval(start: at(0, 14), end: at(0, 15))])
    }

    // MARK: - Midnight

    func testEventAcrossMidnightIsSplitBetweenDays() {
        // 22:00 → 02:00 next day: 2 hours today, 2 hours tomorrow.
        let result = hours([event(at(0, 22), at(1, 2))])
        XCTAssertEqual(result[todayKey], 2)
        XCTAssertEqual(result[tomorrowKey], 2)
    }

    func testSplitAtMidnightProducesOnePiecePerDay() {
        let pieces = BusyHoursCalculator.splitAtMidnight(BusyHoursCalculator.Interval(start: at(0, 23), end: at(2, 1)), calendar: calendar)
        XCTAssertEqual(pieces.count, 3)
        XCTAssertEqual(pieces[0].end, day(1))
        XCTAssertEqual(pieces[1], BusyHoursCalculator.Interval(start: day(1), end: day(2)))
        XCTAssertEqual(pieces[2].start, day(2))
    }

    // MARK: - Exclusions

    func testAllDayEventsAreExcluded() {
        let result = hours([event(day(0), day(1), allDay: true), event(at(0, 9), at(0, 10))])
        XCTAssertEqual(result[todayKey], 1)
    }

    func testDeclinedEventsAreExcluded() {
        let result = hours([event(at(0, 9), at(0, 10), declined: true), event(at(0, 13), at(0, 13, 30))])
        XCTAssertEqual(result[todayKey], 0.5)
    }

    func testCancelledAndDismissedEventsAreExcluded() {
        let result = hours([event(at(0, 9), at(0, 10), cancelled: true), event(at(0, 10), at(0, 11), dismissed: true)])
        XCTAssertEqual(result[todayKey], 0)
    }

    func testInvertedEventIsIgnored() {
        XCTAssertFalse(BusyEventInput(start: at(0, 10), end: at(0, 9)).isBusy)
    }

    // MARK: - Horizon and rounding

    func testEveryDayInHorizonIsReportedEvenWhenFree() {
        let result = hours([], horizonDays: 14)
        XCTAssertEqual(result.count, 14)
        XCTAssertTrue(result.values.allSatisfy { $0 == 0 })
        XCTAssertNotNil(result[todayKey])
    }

    func testEventsOutsideTheHorizonAreDropped() {
        // Yesterday's event and one three days out both fall outside a 3-day horizon (today, +1, +2).
        let result = hours([event(at(-1, 9), at(-1, 10)), event(at(3, 9), at(3, 10)), event(at(2, 9), at(2, 10))], horizonDays: 3)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[BusyHoursCalculator.dayKey(day(2), calendar: calendar)], 1)
        XCTAssertEqual(result.values.reduce(0, +), 1)
    }

    func testHoursRoundToTwoDecimals() {
        // 20 minutes = 0.3333… → 0.33
        let result = hours([event(at(0, 9), at(0, 9, 20))])
        XCTAssertEqual(result[todayKey], 0.33)
        XCTAssertEqual(BusyHoursCalculator.rounded(1.005), 1.0, accuracy: 0.011)
        XCTAssertEqual(BusyHoursCalculator.rounded(2.456), 2.46)
    }

    func testEmptyHorizonYieldsNothing() {
        XCTAssertTrue(hours([event(at(0, 9), at(0, 10))], horizonDays: 0).isEmpty)
    }

    // MARK: - Report fingerprint

    func testFingerprintIsOrderIndependent() {
        let a = BusyHoursReport(source: BusyHoursReport.macEventKitSource, days: ["2026-09-08": 1.5, "2026-09-07": 2])
        let b = BusyHoursReport(source: BusyHoursReport.macEventKitSource, days: ["2026-09-07": 2, "2026-09-08": 1.5])
        XCTAssertEqual(BusyHoursReporter.fingerprint(a), BusyHoursReporter.fingerprint(b))
        let changed = BusyHoursReport(source: BusyHoursReport.macEventKitSource, days: ["2026-09-07": 2, "2026-09-08": 1.75])
        XCTAssertNotEqual(BusyHoursReporter.fingerprint(a), BusyHoursReporter.fingerprint(changed))
    }

    func testReportEncodesTheBackendContract() throws {
        let report = BusyHoursReport(source: BusyHoursReport.macEventKitSource, days: ["2026-09-07": 2.5])
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(report)) as? [String: Any])
        XCTAssertEqual(json["source"] as? String, "mac-eventkit")
        XCTAssertEqual((json["days"] as? [String: Double])?["2026-09-07"], 2.5)
    }
}
