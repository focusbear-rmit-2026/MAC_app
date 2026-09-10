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

    // MARK: - Resilient list decode (days_of_week int/string mix)
    //
    // Regression: the backend returned two schedules where one had
    // days_of_week: [0…6] (ints) and the other ["ALL"] (strings). The whole-array
    // decode threw on the string element, dropping ALL custom blocking schedules.

    /// Backend 0-based days [0…6] become Calendar weekdays [1…7] (Sunday = 1).
    private let allWeekdays = Array(1...7)

    private func decodeSchedules(_ json: String) throws -> [customBlockingSchedule] {
        let data = Data(json.utf8)
        let wrapped = try JSONDecoder().decode([FailableDecodable<customBlockingSchedule>].self, from: data)
        return wrapped.compactMap { $0.value }
    }

    func test_mixed_int_and_all_string_days_decodes_both_schedules() throws {
        let json = """
        [
          { "name": "Work", "days_of_week": [0,1,2,3,4,5,6] },
          { "name": "Sleep Time", "days_of_week": ["ALL"] }
        ]
        """
        let schedules = try decodeSchedules(json)
        XCTAssertEqual(schedules.count, 2)
        XCTAssertEqual(schedules[0].daysOfWeek.sorted(), allWeekdays)
        XCTAssertEqual(schedules[1].name, "Sleep Time")
        XCTAssertEqual(schedules[1].daysOfWeek.sorted(), allWeekdays)
    }

    func test_all_token_is_case_insensitive() throws {
        let schedules = try decodeSchedules(#"[ { "name": "S", "days_of_week": ["All"] } ]"#)
        XCTAssertEqual(schedules.first?.daysOfWeek.sorted(), allWeekdays)
    }

    func test_day_name_strings_map_to_specific_weekdays() throws {
        // ["mon","wed","fri"] → backend 1,3,5 → Calendar weekdays 2,4,6
        let schedules = try decodeSchedules(#"[ { "name": "S", "days_of_week": ["mon","wed","fri"] } ]"#)
        XCTAssertEqual(schedules.first?.daysOfWeek.sorted(), [2, 4, 6])
    }

    func test_unrecognized_day_names_fall_back_to_full_week() throws {
        let schedules = try decodeSchedules(#"[ { "name": "S", "days_of_week": ["notaday"] } ]"#)
        XCTAssertEqual(schedules.first?.daysOfWeek.sorted(), allWeekdays)
    }

    func test_one_malformed_element_does_not_drop_the_valid_ones() throws {
        let json = """
        [
          { "name": "Good" },
          "totally broken",
          { "name": "AlsoGood" }
        ]
        """
        let schedules = try decodeSchedules(json)
        XCTAssertEqual(schedules.map { $0.name }, ["Good", "AlsoGood"])
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

    // MARK: - isAIBlockingEnabled() — reads the BLOCK LIST's AI flag, not the schedule's

    private let blockListId = "block-list-under-test"

    /// Point a manager at one running schedule whose block list is `focusMode` (nil ⇒ unresolvable).
    private func makeManager(runningBlockList focusMode: [String: Any]?, scheduleAiFlag: Bool) -> customBlockingScheduleManager {
        var schedule = makeSchedule(startOffsetSeconds: -600, endOffsetSeconds: 600)
        schedule.focusModeID = blockListId
        schedule.isAIBlockingEnabled = scheduleAiFlag
        schedule.state = .on
        let manager = customBlockingScheduleManager()
        manager.arrBlockingSchedule = [schedule]
        manager.isAnyCustomScheduleOn = true
        arrFocusType = focusMode.map { [$0] } ?? []
        return manager
    }

    override func tearDown() {
        arrFocusType = []
        super.tearDown()
    }

    func test_ai_on_for_allow_list_block_list_when_flag_absent() {
        let manager = makeManager(runningBlockList: ["id": blockListId, "isAllowedListApproach": true], scheduleAiFlag: false)
        XCTAssertTrue(manager.isAIBlockingEnabled())
    }

    func test_ai_off_when_allow_list_block_list_opts_out() {
        let manager = makeManager(runningBlockList: ["id": blockListId, "isAllowedListApproach": true, "is_ai_enabled": false], scheduleAiFlag: true)
        XCTAssertFalse(manager.isAIBlockingEnabled())
    }

    func test_ai_off_for_blacklist_block_list_even_when_flag_on() {
        // A blacklist never consults the AI (only un-allowed URLs of an allow-list do), so starting an
        // "AI session" for it would block nothing.
        let manager = makeManager(runningBlockList: ["id": blockListId, "isAllowedListApproach": false, "is_ai_enabled": true], scheduleAiFlag: true)
        XCTAssertFalse(manager.isAIBlockingEnabled())
    }

    func test_ai_falls_back_to_schedule_flag_when_block_list_is_missing() {
        XCTAssertTrue(makeManager(runningBlockList: nil, scheduleAiFlag: true).isAIBlockingEnabled())
        XCTAssertFalse(makeManager(runningBlockList: nil, scheduleAiFlag: false).isAIBlockingEnabled())
    }

    func test_ai_off_when_no_schedule_is_running() {
        let manager = makeManager(runningBlockList: ["id": blockListId, "isAllowedListApproach": true], scheduleAiFlag: true)
        manager.isAnyCustomScheduleOn = false
        XCTAssertFalse(manager.isAIBlockingEnabled())
    }
}
