//
//  TriagedBacklogFixesTests.swift
//  FocusBearTests
//
//  Covers four triaged user reports whose fixes were extracted into pure, injectable decisions:
//
//   * MorningRoutineStartGuard  — 2026-06-24_16-19-02, custom routine kicked back to morning
//   * EventTimeParser           — 2026-06-24_21-08-27, typing "3" in the minutes became "03"
//   * PostponeGate              — 2026-06-24_21-01-49, 5s countdown demanded after the password
//   * DayPlanDestination        — 2026-06-25_18-11-05, "View full day plan" during an allowed app
//

@testable import Focus_Bear
import XCTest

// MARK: - Custom routine must not be aborted into the morning routine

class MorningRoutineStartGuardTests: XCTestCase {

    func test_customRoutineRunning_refusesToStartMorningHabits() {
        // The bug: backgroundThread() fell through to startHabitsCall() while a custom routine was
        // running, and startHabitsCall() calls abortAllProcess() — killing the custom routine.
        XCTAssertFalse(MorningRoutineStartGuard.shouldStartMorningRoutine(currentState: ._CUSTOM_ROUTINE_))
    }

    func test_idleState_allowsMorningHabitsToStart() {
        XCTAssertTrue(MorningRoutineStartGuard.shouldStartMorningRoutine(currentState: ._NOTHING_))
    }

    func test_postponedMorningRoutine_stillResumes() {
        // Resuming a postponed morning routine is the guard's main legitimate caller — it must not
        // be blocked, or the routine could never come back after a postpone.
        XCTAssertTrue(MorningRoutineStartGuard.shouldStartMorningRoutine(currentState: ._POSTPONE_MORNING_HABIT_))
    }

    func test_everyNonCustomRoutineState_allowsMorningHabitsToStart() {
        // Only _CUSTOM_ROUTINE_ vetoes: a blanket guard here would break unrelated resume paths.
        let vetoed: [CURRENTSTATE] = [._CUSTOM_ROUTINE_]
        let allStates: [CURRENTSTATE] = [
            ._NOTHING_, ._MORNING_HABIT_, ._EVENING_HABIT_, ._MICRO_BREAK_, ._SHUTOFFMAC_,
            ._BREATHING_, ._ABORT_, ._FOCUS_SUMMARY_, ._POSTPONE_MORNING_HABIT_,
            ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_, ._ONBOARDING_,
            ._SPECIAL_ACTIVITY_, ._CUSTOM_ROUTINE_, ._LOGIN_,
        ]
        for state in allStates {
            XCTAssertEqual(MorningRoutineStartGuard.shouldStartMorningRoutine(currentState: state),
                           !vetoed.contains(state),
                           "unexpected decision for \(state)")
        }
    }
}

// MARK: - Typing a two-digit minute must work naturally

class EventTimeParserTests: XCTestCase {

    /// The reported bug, stated exactly: type "3", then "0", and you have thirty minutes past —
    /// not "03" that has to be fought with.
    func test_typingThreeThenZero_givesThirtyMinutes() {
        // What the field holds after the first keystroke...
        XCTAssertEqual(EventTimeParser.parse("7:3"), EventTimeParser.ClockTime(hour: 7, minute: 3))
        // ...and after the second. No zero-padding shunted the 3 anywhere.
        XCTAssertEqual(EventTimeParser.parse("7:30"), EventTimeParser.ClockTime(hour: 7, minute: 30))
    }

    func test_parsesTwentyFourHourTimes() {
        XCTAssertEqual(EventTimeParser.parse("19:30"), EventTimeParser.ClockTime(hour: 19, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("00:00"), EventTimeParser.ClockTime(hour: 0, minute: 0))
        XCTAssertEqual(EventTimeParser.parse("23:59"), EventTimeParser.ClockTime(hour: 23, minute: 59))
    }

    func test_parsesRunTogetherDigits() {
        XCTAssertEqual(EventTimeParser.parse("730"), EventTimeParser.ClockTime(hour: 7, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("1930"), EventTimeParser.ClockTime(hour: 19, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("7"), EventTimeParser.ClockTime(hour: 7, minute: 0))
        XCTAssertEqual(EventTimeParser.parse("19"), EventTimeParser.ClockTime(hour: 19, minute: 0))
    }

    func test_parsesAlternateSeparators() {
        XCTAssertEqual(EventTimeParser.parse("7.30"), EventTimeParser.ClockTime(hour: 7, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("7 30"), EventTimeParser.ClockTime(hour: 7, minute: 30))
    }

    func test_parsesMeridiem() {
        XCTAssertEqual(EventTimeParser.parse("7:30 am"), EventTimeParser.ClockTime(hour: 7, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("7:30am"), EventTimeParser.ClockTime(hour: 7, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("7:30 PM"), EventTimeParser.ClockTime(hour: 19, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("7:30 p.m."), EventTimeParser.ClockTime(hour: 19, minute: 30))
        XCTAssertEqual(EventTimeParser.parse("7pm"), EventTimeParser.ClockTime(hour: 19, minute: 0))
    }

    func test_twelveAmIsMidnight_andTwelvePmIsNoon() {
        XCTAssertEqual(EventTimeParser.parse("12:00 am"), EventTimeParser.ClockTime(hour: 0, minute: 0))
        XCTAssertEqual(EventTimeParser.parse("12:00 pm"), EventTimeParser.ClockTime(hour: 12, minute: 0))
        XCTAssertEqual(EventTimeParser.parse("12:30 am"), EventTimeParser.ClockTime(hour: 0, minute: 30))
    }

    func test_toleratesSurroundingWhitespaceAndCase() {
        XCTAssertEqual(EventTimeParser.parse("  7:30 AM  "), EventTimeParser.ClockTime(hour: 7, minute: 30))
    }

    func test_rejectsNonsenseRatherThanClamping() {
        // Rejecting (not clamping) is what lets the field fall back to the last good value instead
        // of silently saving a time the user never typed.
        XCTAssertNil(EventTimeParser.parse(""))
        XCTAssertNil(EventTimeParser.parse("   "))
        XCTAssertNil(EventTimeParser.parse("abc"))
        XCTAssertNil(EventTimeParser.parse("25:00"))
        XCTAssertNil(EventTimeParser.parse("7:60"))
        XCTAssertNil(EventTimeParser.parse("99999"))
        XCTAssertNil(EventTimeParser.parse("7:30:15"))
    }

    func test_rejectsTwentyFourHourReadingWithMeridiem() {
        // "19pm" is a typo, not 7pm — don't guess.
        XCTAssertNil(EventTimeParser.parse("19pm"))
        XCTAssertNil(EventTimeParser.parse("0am"))
    }

    func test_formatRoundTripsThroughParse() {
        // Whatever the field renders on open must be something it can read back, or a save without
        // an edit would change the time.
        for hour in 0..<24 {
            for minute in [0, 3, 30, 45, 59] {
                let time = EventTimeParser.ClockTime(hour: hour, minute: minute)
                let rendered = EventTimeParser.format(time, locale: Locale(identifier: "en_AU"))
                XCTAssertEqual(EventTimeParser.parse(rendered), time, "round trip failed for \(rendered)")
            }
        }
    }

    func test_formatRoundTripsInTwentyFourHourLocale() {
        for hour in 0..<24 {
            let time = EventTimeParser.ClockTime(hour: hour, minute: 5)
            let rendered = EventTimeParser.format(time, locale: Locale(identifier: "en_GB"))
            XCTAssertEqual(EventTimeParser.parse(rendered), time, "round trip failed for \(rendered)")
        }
    }

    func test_combineKeepsTheDayAndAppliesTheTime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        let day = calendar.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 16, minute: 19))!
        let combined = EventTimeParser.combine(day: day,
                                               time: EventTimeParser.ClockTime(hour: 7, minute: 30),
                                               calendar: calendar)
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: combined)
        XCTAssertEqual(parts.year, 2026)
        XCTAssertEqual(parts.month, 6)
        XCTAssertEqual(parts.day, 24)
        XCTAssertEqual(parts.hour, 7)
        XCTAssertEqual(parts.minute, 30)
        XCTAssertEqual(parts.second, 0)
    }

    func test_clockTimeReadsTheTimeOfDayBack() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 19, minute: 30))!
        XCTAssertEqual(EventTimeParser.clockTime(of: date, calendar: calendar),
                       EventTimeParser.ClockTime(hour: 19, minute: 30))
    }

    func test_isValidAgreesWithParse() {
        for text in ["7:30", "730", "7:30 pm", "19:30", "7", ""] {
            XCTAssertEqual(EventTimeParser.isValid(text), EventTimeParser.parse(text) != nil,
                           "isValid disagreed with parse for \"\(text)\"")
        }
        XCTAssertTrue(EventTimeParser.isValid("7:30"))
        // A bare "30" reads as an HOUR (like "19" does), and there is no 30 o'clock.
        XCTAssertFalse(EventTimeParser.isValid("30"))
    }
}

// MARK: - Password already paid for the postpone; don't also demand the hold

class PostponeGateTests: XCTestCase {

    func test_passwordSatisfied_skipsTheHoldCountdown() {
        // The report: "it shouldn't bother with the 5s countdown if a password is required".
        XCTAssertEqual(PostponeGate.step(activityPostponeCount: 3, passwordAlreadySatisfied: true),
                       .postponeOptions)
    }

    func test_repeatedPostponeWithoutPassword_stillHoldsToConfirm() {
        XCTAssertEqual(PostponeGate.step(activityPostponeCount: 1, passwordAlreadySatisfied: false),
                       .holdToConfirm)
        XCTAssertEqual(PostponeGate.step(activityPostponeCount: 9, passwordAlreadySatisfied: false),
                       .holdToConfirm)
    }

    func test_firstPostponeOfTheDay_goesStraightToTheOptions() {
        XCTAssertEqual(PostponeGate.step(activityPostponeCount: 0, passwordAlreadySatisfied: false),
                       .postponeOptions)
        XCTAssertEqual(PostponeGate.step(activityPostponeCount: 0, passwordAlreadySatisfied: true),
                       .postponeOptions)
    }
}

// MARK: - "View full day plan" resolves to the tab the user can actually see

class DayPlanDestinationTests: XCTestCase {

    func test_allowedActivityHabitPlaying_targetsTheEmbeddedDayPlanTab() {
        // The bug: this landed on the Habit Player tab, because the main window's Day Plan dispatch
        // early-returns while a routine is live.
        XCTAssertEqual(DayPlanDestination.target(hasAllowedActivityTabs: true),
                       .allowedActivityDayPlanTab)
    }

    func test_noAllowedActivityTabs_targetsTheMainWindowDayPlan() {
        XCTAssertEqual(DayPlanDestination.target(hasAllowedActivityTabs: false),
                       .mainWindowDayPlan)
    }

    func test_dayPlanIsTheSecondSegment() {
        // The routing above is only correct if it selects the segment the tab bar actually builds
        // second — guards against the labels/order being reshuffled without the writer following.
        XCTAssertEqual(AllowedActivityTab.habitPlayer.rawValue, 0)
        XCTAssertEqual(AllowedActivityTab.dayPlan.rawValue, 1)
    }
}
