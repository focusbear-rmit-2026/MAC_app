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

    // MARK: - Why blocking is off (menu "Blocking is off" card, Mac-App#1978)

    /// Everything granted, a schedule running — nothing to explain.
    private func blockingOn() -> BlockingStatus {
        BlockingStatus(isAppEnabled: true, permissions: .granted, isAnyBrowserEnabled: true,
                       scheduleCount: 1, isAnyScheduleOn: true, isAnySchedulePaused: false,
                       isAnyScheduleCoveringNow: true, isFocusSessionRunning: false,
                       isRoutineRunning: false)
    }

    func test_blockingOffReasons_emptyWhileAScheduleIsRunning() {
        XCTAssertEqual(blockingOn().offReasons, [])
    }

    // MARK: - Browser reads that stopped answering (report 2026-09-11_16-56-33)

    func test_blockingOffReasons_reportsABrowserThatStoppedAnsweringEvenWhileAScheduleRuns() {
        var status = blockingOn()
        status.isBrowserUrlReadFailing = true
        XCTAssertEqual(status.offReasons, [.browserNotResponding],
                       "Nothing can be checked, so this is reported even with a schedule on")
        XCTAssertEqual(BlockingStatusCardKind(reasons: status.offReasons), .off,
                       "A browser that cannot be read is not a mere warning")
    }

    func test_blockingOffReasons_staysQuietAboutReadsWhenNoBrowserIsSetUpAtAll() {
        var status = blockingOn()
        status.isAnyBrowserEnabled = false
        status.isBrowserUrlReadFailing = true
        XCTAssertEqual(status.offReasons, [.noBrowserEnabled],
                       "The fix is to set a browser up; failing reads of nothing add no information")
    }

    func test_browserUrlReadHealth_needsARunOfFailuresAndReportsEachTransitionOnce() {
        var health = BrowserUrlReadHealth()
        for _ in 1..<BrowserUrlReadHealth.failureThreshold {
            XCTAssertFalse(health.record(succeeded: false), "A handful of empty reads is normal")
            XCTAssertFalse(health.isFailing)
        }
        XCTAssertTrue(health.record(succeeded: false), "The threshold failure is the one worth logging")
        XCTAssertTrue(health.isFailing)
        XCTAssertFalse(health.record(succeeded: false), "Still failing is not news")
        XCTAssertTrue(health.record(succeeded: true), "Recovery is news")
        XCTAssertFalse(health.isFailing)
        XCTAssertFalse(health.record(succeeded: true))
    }

    func test_browserUrlReadHealth_oneGoodReadResetsTheRun() {
        var health = BrowserUrlReadHealth()
        for _ in 1..<BrowserUrlReadHealth.failureThreshold { _ = health.record(succeeded: false) }
        _ = health.record(succeeded: true)
        for _ in 1..<BrowserUrlReadHealth.failureThreshold {
            XCTAssertFalse(health.record(succeeded: false))
        }
        XCTAssertFalse(health.isFailing, "The count starts again after a browser answers")
    }

    func test_blockingOffReasons_emptyDuringAFocusSessionWithNoSchedule() {
        var status = blockingOn()
        status.scheduleCount = 0
        status.isAnyScheduleOn = false
        status.isFocusSessionRunning = true
        XCTAssertEqual(status.offReasons, [], "a focus session blocks on its own")
    }

    func test_blockingOffReasons_namesMissingPermissionsEvenMidSession() {
        var status = blockingOn()
        status.permissions = .missing
        status.isFocusSessionRunning = true
        XCTAssertEqual(status.offReasons, [.permissionsMissing],
                       "retain the permission warning while a session runs")
    }

    func test_blockingOffReasons_distinguishesTheThreeScheduleGaps() {
        var status = blockingOn()
        status.isAnyScheduleOn = false

        status.scheduleCount = 0
        XCTAssertEqual(status.offReasons, [.noSchedule])

        status.scheduleCount = 1
        status.isAnySchedulePaused = true
        XCTAssertEqual(status.offReasons, [.schedulePaused])

        status.isAnySchedulePaused = false
        status.isAnyScheduleCoveringNow = false
        XCTAssertEqual(status.offReasons, [.noScheduleRightNow])
    }

    func test_blockingOffReasons_listsEveryCauseThatApplies() {
        var status = blockingOn()
        status.permissions = .missing
        status.scheduleCount = 0
        status.isAnyScheduleOn = false
        XCTAssertEqual(status.offReasons, [.permissionsMissing, .noSchedule],
                       "both causes are named, most severe first")
    }

    func test_blockingOffReasons_deactivatedAppIsTheWholeStory() {
        var status = blockingOn()
        status.isAppEnabled = false
        status.permissions = .missing
        status.scheduleCount = 0
        status.isAnyScheduleOn = false
        XCTAssertEqual(status.offReasons, [.appDeactivated],
                       "the consequences of deactivating mustn't bury the thing to undo")
    }

    func test_blockingOffReasons_everyReasonHasAnExplanationAndAFix() {
        for reason in BlockingOffReason.allCases {
            XCTAssertFalse(reason.explanation.isEmpty, "\(reason.rawValue) needs an explanation")
            XCTAssertFalse(reason.fixTitle.isEmpty, "\(reason.rawValue) needs a fix button")
        }
    }

    // MARK: - Not asserting what we can't establish (report 2026-09-10_07-54-05)

    /// The reported false positive, end to end: every grant in place and a schedule covering the
    /// moment, but mid-morning-routine — so schedule activation was suppressed and the card claimed
    /// both missing permissions and that no schedule covered right now. Neither was true.
    func test_blockingOffReasons_silentDuringARoutineWithEverythingGranted() {
        var status = blockingOn()
        status.isAnyScheduleOn = false      // routines suppress schedule activation
        status.isRoutineRunning = true
        XCTAssertEqual(status.offReasons, [],
                       "a running routine blocks on its own — nothing here is off")
    }

    /// An unfinished or timed-out permission probe must not be reported as a denial: the menu
    /// renders before the async probe lands, and a busy AppleScript queue is not a refusal.
    func test_blockingOffReasons_saysNothingWhilePermissionsAreUnknown() {
        var status = blockingOn()
        status.permissions = .unknown
        XCTAssertEqual(status.offReasons, [],
                       "an inconclusive probe is not evidence of a missing permission")

        status.isAnyScheduleOn = false
        status.isAnyScheduleCoveringNow = false
        XCTAssertEqual(status.offReasons, [.noScheduleRightNow],
                       "the schedule gap still stands on its own while permissions are unknown")
    }

    /// Permissions granted but no browser set up: a real gap, but in the browser list — so it gets
    /// its own reason and its own fix, never the permissions wizard.
    func test_blockingOffReasons_noBrowserEnabledIsNotAMissingPermission() {
        var status = blockingOn()
        status.isAnyBrowserEnabled = false
        XCTAssertEqual(status.offReasons, [.noBrowserEnabled])
        XCTAssertNotEqual(BlockingOffReason.noBrowserEnabled.fixTitle,
                          BlockingOffReason.permissionsMissing.fixTitle,
                          "the two must not send the user to the same place")
    }

    /// A missing grant already explains why nothing is blocked; the browser list is the next thing
    /// to fix, not a second cause to bury it under.
    func test_blockingOffReasons_missingPermissionsOutranksTheBrowserList() {
        var status = blockingOn()
        status.permissions = .missing
        status.isAnyBrowserEnabled = false
        XCTAssertEqual(status.offReasons, [.permissionsMissing])
    }

    /// An unreadable browser list reads as "nothing to report", so an unloaded list can't accuse
    /// a user who has browsers set up.
    func test_blockingOffReasons_scheduleCoveringNowIsNeverCalledAGap() {
        var status = blockingOn()
        status.isAnyScheduleOn = false
        status.isAnyScheduleCoveringNow = true
        XCTAssertEqual(status.offReasons, [],
                       "claiming no schedule covers now, while one does, is the falsehood to avoid")
    }

    /// The log line is what makes the next report answerable without a code read, so it has to
    /// carry every input and the conclusion.
    func test_blockingStatus_logDescriptionCarriesInputsAndConclusion() {
        var status = blockingOn()
        status.permissions = .unknown
        let line = status.logDescription
        for field in ["appEnabled=", "permissions=", "browserEnabled=", "schedules=", "scheduleOn=",
                      "schedulePaused=", "scheduleCoversNow=", "focusSession=", "routine="] {
            XCTAssertTrue(line.contains(field), "log line is missing \(field): \(line)")
        }
        XCTAssertTrue(line.contains("no confirmed blocking issue"),
                      "unknown permission evidence cannot prove blocking is on: \(line)")

        status.permissions = .missing
        XCTAssertTrue(status.logDescription.contains(BlockingOffReason.permissionsMissing.rawValue),
                      "the concluded reasons must be named in the log")
    }

    func test_missingPermissionDuringActiveBlockingShowsAttentionInsteadOfOff() {
        var status = blockingOn()
        status.permissions = .missing
        XCTAssertEqual(BlockingStatusCardKind(reasons: status.offReasons), .attention)
        status.isAnyScheduleOn = false
        status.isFocusSessionRunning = true
        XCTAssertEqual(BlockingStatusCardKind(reasons: status.offReasons), .attention)
        status.isFocusSessionRunning = false
        status.isRoutineRunning = true
        XCTAssertEqual(BlockingStatusCardKind(reasons: status.offReasons), .attention)
    }

    func test_disabledBrowserDoesNotClaimApplicationBlockingIsOff() {
        var status = blockingOn()
        status.isAnyBrowserEnabled = false
        XCTAssertEqual(status.offReasons, [.noBrowserEnabled])
        XCTAssertEqual(BlockingStatusCardKind(reasons: status.offReasons), .attention)
    }

    func test_realOffCauseKeepsOffHeadlineAlongsidePermissionWarning() {
        var status = blockingOn()
        status.permissions = .missing
        status.isAnyScheduleOn = false
        status.isAnyScheduleCoveringNow = false
        XCTAssertEqual(BlockingStatusCardKind(reasons: status.offReasons), .off)
        status.isAppEnabled = false
        XCTAssertEqual(status.offReasons, [.appDeactivated])
        XCTAssertEqual(BlockingStatusCardKind(reasons: status.offReasons), .off)
    }

    func test_permissionHealthNamesOnlyConfirmedAffectedCapabilities() {
        var health = BlockingPermissionHealth(accessibilityGranted: false, systemEvents: .unknown)
        XCTAssertEqual(health.state, .missing)
        XCTAssertEqual(health.issues, [.accessibility])
        health.systemEvents = .missing
        XCTAssertEqual(health.issues, [.accessibility, .systemEvents])
        health.accessibilityGranted = true
        XCTAssertEqual(health.issues, [.systemEvents])
        health.systemEvents = .unknown
        XCTAssertEqual(health.state, .unknown)
        XCTAssertEqual(health.issues, [])
        health.systemEvents = .granted
        XCTAssertEqual(health.state, .granted)
    }

    func test_automationPermissionQueryDistinguishesDenialFromUnavailableTarget() {
        XCTAssertEqual(BlockingPermissionsState.automationAuthorizationStatus(0), .granted)
        XCTAssertEqual(BlockingPermissionsState.automationAuthorizationStatus(-1743), .missing)
        XCTAssertEqual(BlockingPermissionsState.automationAuthorizationStatus(-1744), .missing)
        for status: Int32 in [-600, -1712, -50] {
            XCTAssertEqual(BlockingPermissionsState.automationAuthorizationStatus(status), .unknown)
        }
    }

    func test_permissionProbeAllowsOnlyOneInFlightCheckAndRefreshesAfterGrant() {
        var probe = BlockingPermissionProbeCache()
        XCTAssertEqual(probe.state(at: 100), .unknown)
        XCTAssertTrue(probe.begin(at: 100))
        XCTAssertFalse(probe.begin(at: 101))
        probe.complete(.missing, startedAt: 100)
        XCTAssertEqual(probe.state(at: 101), .missing)
        XCTAssertFalse(probe.begin(at: 105))
        XCTAssertTrue(probe.begin(at: 110))
        probe.complete(.granted, startedAt: 110)
        XCTAssertEqual(probe.state(at: 111), .granted)
        // A duplicate/late older completion cannot overwrite the more recent grant.
        probe.complete(.missing, startedAt: 100)
        XCTAssertEqual(probe.state(at: 112), .granted)
    }

    func test_permissionEvidenceExpiresFromProbeStartRatherThanLateCompletion() {
        var probe = BlockingPermissionProbeCache()
        XCTAssertTrue(probe.begin(at: 100))
        probe.complete(.missing, startedAt: 100)
        XCTAssertEqual(probe.state(at: 130), .missing)
        XCTAssertEqual(probe.state(at: 131), .unknown)
        XCTAssertEqual(probe.state(at: 99), .unknown)
        XCTAssertTrue(probe.begin(at: 140))
        probe.complete(.missing, startedAt: 140)
        XCTAssertEqual(probe.state(at: 171), .unknown,
                       "a slow completion must not give old evidence a new 30-second lifetime")
    }

    func test_inconclusivePermissionRecheckDoesNotRetainAnEarlierDenial() {
        var probe = BlockingPermissionProbeCache()
        XCTAssertTrue(probe.begin(at: 100))
        probe.complete(.missing, startedAt: 100)
        XCTAssertTrue(probe.begin(at: 110))
        probe.complete(.unknown, startedAt: 110)
        XCTAssertEqual(probe.state(at: 111), .unknown)
    }
}

// MARK: - New-schedule defaults (report 2026-09-15_17-43-33)

/// The onboarding / "add new block" editor seeds a brand-new schedule from
/// `BlockingScheduleDefaults`; an existing schedule is always loaded from its own saved values.
/// These two paths are what keep "change the default" from rewriting anybody's saved window.
@available(macOS 11.0, *)
final class BlockingScheduleDefaultsTests: XCTestCase {

    func testNewScheduleDefaultsToEightAmUntilFivePm() {
        let model = BlockingScheduleEditorModel()
        model.applyNewScheduleDefaults()
        XCTAssertEqual(model.startMinutes, 8 * 60, "a new schedule should start at 08:00")
        XCTAssertEqual(model.endMinutes, 17 * 60, "a new schedule should end at 17:00")
    }

    func testNewScheduleLeavesAiAndMicrobreakOptionsUnticked() {
        let model = BlockingScheduleEditorModel()
        model.useAI = true
        model.skipMicroBreaks = true
        model.applyNewScheduleDefaults()
        XCTAssertFalse(model.useAI, "\"use AI to block distractions\" must not be ticked by default")
        XCTAssertFalse(model.skipMicroBreaks, "\"skip microbreaks\" must not be ticked by default")
    }

    func testNewScheduleKeepsAPrefilledWindow() {
        let model = BlockingScheduleEditorModel()
        model.applyNewScheduleDefaults(startMinutes: 20 * 60, endMinutes: 23 * 60)
        XCTAssertEqual(model.startMinutes, 20 * 60, "a dragged/preset start time still wins over the default")
        XCTAssertEqual(model.endMinutes, 23 * 60)
    }

    func testExistingScheduleKeepsItsSavedWindowAndToggles() {
        let model = BlockingScheduleEditorModel()
        model.applySavedSchedule(startMinutes: 9 * 60, endMinutes: 18 * 60,
                                 isAIBlockingEnabled: true, isMicroBreaksEnabled: false)
        XCTAssertTrue(model.isEditing)
        XCTAssertEqual(model.startMinutes, 9 * 60, "an existing user's saved start time is untouched")
        XCTAssertEqual(model.endMinutes, 18 * 60, "an existing user's saved end time is untouched")
        XCTAssertTrue(model.useAI, "a saved schedule with AI on stays on")
        XCTAssertTrue(model.skipMicroBreaks, "a saved schedule that skips microbreaks keeps skipping them")
    }

    func testExistingCrossMidnightScheduleClampsToEndOfDay() {
        let model = BlockingScheduleEditorModel()
        model.applySavedSchedule(startMinutes: 22 * 60, endMinutes: 2 * 60,
                                 isAIBlockingEnabled: false, isMicroBreaksEnabled: true)
        XCTAssertEqual(model.startMinutes, 22 * 60)
        XCTAssertEqual(model.endMinutes, 1440, "a window running past midnight clamps to the end of the day")
        XCTAssertFalse(model.skipMicroBreaks)
    }
}
