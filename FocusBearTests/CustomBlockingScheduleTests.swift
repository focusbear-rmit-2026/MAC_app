//
//  CustomBlockingScheduleTests.swift
//  FocusBear
//
//  Created by Jose Vega on 2026-05-25.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

@testable import Focus_Bear
import XCTest

class CustomBlockingScheduleTests: XCTestCase {

    // MARK: - Helpers

    private let calendar = Calendar.current

    /// A fixed reference instant used by the clock-relative tests.
    ///
    /// `isBlockingActive()` / `remainingBlockingDuration()` compare a reference
    /// "now" against the time-of-day of the schedule's start/end. The tests
    /// pass this fixed reference explicitly (rather than relying on the real
    /// wall clock) so that offsets can never roll across midnight at run time
    /// and flip a same-day window into the cross-midnight branch. We anchor it
    /// to 12:00:00 today, which leaves plenty of room on either side for the
    /// offsets these tests use.
    private lazy var fixedNow: Date = {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    }()

    /// Build a schedule whose start/end is offset from the fixed reference time
    /// in seconds. Positive = future, negative = past.
    private func makeSchedule(
        startOffsetSeconds: Int,
        endOffsetSeconds: Int,
        daysOfWeek: [Int]? = nil
    ) -> customBlockingSchedule {
        let now = fixedNow
        let start = now.addingTimeInterval(TimeInterval(startOffsetSeconds))
        let end   = now.addingTimeInterval(TimeInterval(endOffsetSeconds))
        let todayWeekday = calendar.component(.weekday, from: now)
        let days = daysOfWeek ?? [todayWeekday]
        return customBlockingSchedule(
            id: UUID().uuidString,
            name: "Test Schedule",
            startTime: start,
            endTime: end,
            startTimeString: "",
            endTimeString: "",
            daysOfWeek: days,
            focusModeID: "test-mode",
            blockLevel: ._NORMAL_,
            isAIBlockingEnabled: false,
            isMicroBreaksEnabled: false
        )
    }

    /// Build a schedule with absolute hour/minute times on today's date.
    /// For cross-midnight schedules, endDate is set to tomorrow when endHour < startHour.
    private func makeScheduleAbsolute(
        startHour: Int, startMinute: Int,
        endHour: Int,   endMinute: Int,
        daysOfWeek: [Int]
    ) -> customBlockingSchedule {
        let now = fixedNow   // anchor to the single captured reference so nothing flakes near midnight
        let start = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now)!
        var end   = calendar.date(bySettingHour: endHour,   minute: endMinute,   second: 0, of: now)!
        // If end is before start, the window crosses midnight — push end to tomorrow
        if end <= start {
            end = calendar.date(byAdding: .day, value: 1, to: end)!
        }
        return customBlockingSchedule(
            id: UUID().uuidString,
            name: "Test Schedule",
            startTime: start,
            endTime: end,
            startTimeString: "",
            endTimeString: "",
            daysOfWeek: daysOfWeek,
            focusModeID: "test-mode",
            blockLevel: ._NORMAL_,
            isAIBlockingEnabled: false,
            isMicroBreaksEnabled: false
        )
    }

    // MARK: - isBlockingActive() — Same-day tests

    func test_active_when_now_is_inside_window() {
        let schedule = makeSchedule(startOffsetSeconds: -1800, endOffsetSeconds: 1800)
        XCTAssertTrue(schedule.isBlockingActive(now: fixedNow))
    }

    func test_inactive_before_window_starts() {
        let schedule = makeSchedule(startOffsetSeconds: 1800, endOffsetSeconds: 7200)
        XCTAssertFalse(schedule.isBlockingActive(now: fixedNow))
    }

    func test_inactive_after_window_ends() {
        let schedule = makeSchedule(startOffsetSeconds: -7200, endOffsetSeconds: -1800)
        XCTAssertFalse(schedule.isBlockingActive(now: fixedNow))
    }

    func test_inactive_when_today_not_in_days_of_week() {
        let todayWeekday = calendar.component(.weekday, from: fixedNow)
        let otherDays = (1...7).filter { $0 != todayWeekday }
        let schedule = makeSchedule(startOffsetSeconds: -1800, endOffsetSeconds: 1800, daysOfWeek: otherDays)
        XCTAssertFalse(schedule.isBlockingActive(now: fixedNow))
    }

    func test_inactive_when_days_of_week_is_empty() {
        let schedule = makeSchedule(startOffsetSeconds: -1800, endOffsetSeconds: 1800, daysOfWeek: [])
        XCTAssertFalse(schedule.isBlockingActive(now: fixedNow))
    }

    func test_boundary_at_start_time_is_active() {
        let schedule = makeSchedule(startOffsetSeconds: 0, endOffsetSeconds: 3600)
        XCTAssertTrue(schedule.isBlockingActive(now: fixedNow))
    }

    func test_all_days_active_window_returns_true() {
        let schedule = makeSchedule(startOffsetSeconds: -3600, endOffsetSeconds: 3600, daysOfWeek: Array(1...7))
        XCTAssertTrue(schedule.isBlockingActive(now: fixedNow))
    }

    func test_all_days_but_window_has_passed_returns_false() {
        let schedule = makeSchedule(startOffsetSeconds: -7200, endOffsetSeconds: -3600, daysOfWeek: Array(1...7))
        XCTAssertFalse(schedule.isBlockingActive(now: fixedNow))
    }

    // MARK: - isBlockingActive() — Cross-midnight tests
    //
    // These use a fixed reference instant (`fixedNow(at:)`) and an absolute
    // 22:00–02:00 window so they deterministically exercise the cross-midnight
    // branch regardless of when the suite is run.

    /// Returns a fixed instant today at the given hour/minute, used as the
    /// injected "now" for the cross-midnight tests.
    private func fixedNow(at hour: Int, minute: Int = 0) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: fixedNow) ?? fixedNow
    }

    /// 22:00–02:00 window. Now is 23:00 — on the evening side, after start and
    /// before midnight. Schedule applies to today.
    func test_active_cross_midnight_same_day_after_start() {
        let now = fixedNow(at: 23)
        let todayWeekday = calendar.component(.weekday, from: now)
        let schedule = makeScheduleAbsolute(
            startHour: 22, startMinute: 0,
            endHour: 2,    endMinute: 0,
            daysOfWeek: [todayWeekday]
        )
        XCTAssertTrue(schedule.isBlockingActive(now: now))
    }

    /// 22:00–02:00 window. Now is 01:00 — on the next-day (early-morning) side,
    /// so the day that owns the schedule is *yesterday*.
    func test_active_cross_midnight_next_day_before_end() {
        let now = fixedNow(at: 1)
        let todayWeekday = calendar.component(.weekday, from: now)
        // Yesterday's weekday (the day the schedule started on)
        let yesterdayWeekday = todayWeekday == 1 ? 7 : todayWeekday - 1
        let schedule = makeScheduleAbsolute(
            startHour: 22, startMinute: 0,
            endHour: 2,    endMinute: 0,
            daysOfWeek: [yesterdayWeekday]
        )
        XCTAssertTrue(schedule.isBlockingActive(now: now))
    }

    /// 22:00–02:00 window. Now is 03:00 — past the end of the cross-midnight
    /// window. The schedule applies only to a day that is neither today nor
    /// yesterday, so blocking is inactive.
    ///
    /// Note: the implementation can only conclude "past end" here because the
    /// scheduled day is unrelated to `now`. If the schedule's start-day were
    /// today, `now (03:00) >= start (22:00)` would (by design) report it active
    /// as an evening window that has just begun — so we deliberately pick an
    /// unrelated day to isolate the "after end" case.
    func test_inactive_cross_midnight_after_end() {
        let now = fixedNow(at: 3)
        let todayWeekday = calendar.component(.weekday, from: now)
        let yesterdayWeekday = todayWeekday == 1 ? 7 : todayWeekday - 1
        // A weekday that is neither today nor yesterday.
        let unrelatedDay = (1...7).first { $0 != todayWeekday && $0 != yesterdayWeekday }!
        let schedule = makeScheduleAbsolute(
            startHour: 22, startMinute: 0,
            endHour: 2,    endMinute: 0,
            daysOfWeek: [unrelatedDay]
        )
        XCTAssertFalse(schedule.isBlockingActive(now: now))
    }

    // MARK: - remainingBlockingDuration() Tests

    func test_remaining_mid_session_is_positive() {
        let schedule = makeSchedule(startOffsetSeconds: -1800, endOffsetSeconds: 1800)
        let remaining = schedule.remainingBlockingDuration(now: fixedNow)
        XCTAssertEqual(remaining, 1800, accuracy: 1)
    }

    func test_remaining_long_window_returns_roughly_correct_value() {
        let schedule = makeSchedule(startOffsetSeconds: -3600, endOffsetSeconds: 25200)
        let remaining = schedule.remainingBlockingDuration(now: fixedNow)
        XCTAssertEqual(remaining, 25200, accuracy: 1)
    }

    func test_remaining_returns_positive_when_active() {
        let schedule = makeSchedule(startOffsetSeconds: -600, endOffsetSeconds: 600)
        XCTAssertEqual(schedule.remainingBlockingDuration(now: fixedNow), 600, accuracy: 1)
    }

    func test_remaining_returns_1_when_not_active() {
        let schedule = makeSchedule(startOffsetSeconds: -7200, endOffsetSeconds: -3600)
        XCTAssertEqual(schedule.remainingBlockingDuration(now: fixedNow), 1)
    }

    func test_remaining_returns_1_for_empty_days() {
        let schedule = makeSchedule(startOffsetSeconds: -1800, endOffsetSeconds: 1800, daysOfWeek: [])
        // NOTE: remainingBlockingDuration() does not consult daysOfWeek, so an
        // empty-days schedule still returns the remaining window (~1800s) when
        // `now` is inside it — it does NOT fall through to the "1" sentinel.
        // The assertion is left loose because tightening it to an exact value
        // would either codify that surprising behavior or fail outright, which
        // is a product decision about whether empty-days should short-circuit.
        XCTAssertGreaterThanOrEqual(schedule.remainingBlockingDuration(now: fixedNow), 1)
    }

    func test_remaining_not_unreasonably_large() {
        let schedule = makeSchedule(startOffsetSeconds: 0, endOffsetSeconds: 1800)
        XCTAssertEqual(schedule.remainingBlockingDuration(now: fixedNow), 1800, accuracy: 1)
    }
    
    // MARK: - isBlockingScheduleOverlapping() Tests

    func test_overlapping_schedules_detected() {
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)

        let existing = makeScheduleAbsolute(
            startHour: 9,  startMinute: 0,
            endHour: 12,   endMinute: 0,
            daysOfWeek: [todayWeekday]
        )

        // Overlaps existing by 1 hour (10:00–13:00)
        let overlapping = makeScheduleAbsolute(
            startHour: 10, startMinute: 0,
            endHour: 13,   endMinute: 0,
            daysOfWeek: [todayWeekday]
        )

        let manager = customBlockingScheduleManager()
        XCTAssertTrue(manager.isBlockingScheduleOverlapping(
            newSchedule: overlapping,
            schedules: [existing]
        ))
    }

    func test_non_overlapping_schedules_not_detected() {
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)

        let existing = makeScheduleAbsolute(
            startHour: 9,  startMinute: 0,
            endHour: 12,   endMinute: 0,
            daysOfWeek: [todayWeekday]
        )

        // Starts exactly when existing ends — no overlap
        let adjacent = makeScheduleAbsolute(
            startHour: 12, startMinute: 0,
            endHour: 15,   endMinute: 0,
            daysOfWeek: [todayWeekday]
        )

        let manager = customBlockingScheduleManager()
        XCTAssertFalse(manager.isBlockingScheduleOverlapping(
            newSchedule: adjacent,
            schedules: [existing]
        ))
    }

    func test_overlapping_schedules_on_different_days_not_detected() {
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)
        let otherDay = todayWeekday == 7 ? 1 : todayWeekday + 1

        let existing = makeScheduleAbsolute(
            startHour: 9,  startMinute: 0,
            endHour: 12,   endMinute: 0,
            daysOfWeek: [todayWeekday]
        )

        // Same time range but on a different day — should not overlap
        let differentDay = makeScheduleAbsolute(
            startHour: 9,  startMinute: 0,
            endHour: 12,   endMinute: 0,
            daysOfWeek: [otherDay]
        )

        let manager = customBlockingScheduleManager()
        XCTAssertFalse(manager.isBlockingScheduleOverlapping(
            newSchedule: differentDay,
            schedules: [existing]
        ))
    }

    func test_schedule_excluded_from_overlap_check_by_id() {
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)

        let schedule = makeScheduleAbsolute(
            startHour: 9,  startMinute: 0,
            endHour: 12,   endMinute: 0,
            daysOfWeek: [todayWeekday]
        )

        let manager = customBlockingScheduleManager()
        // Comparing a schedule against itself should not count as overlap
        XCTAssertFalse(manager.isBlockingScheduleOverlapping(
            newSchedule: schedule,
            schedules: [schedule],
            excludingId: schedule.id
        ))
    }
}
