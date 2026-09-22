//
//  HabitCutoffValidationTests.swift
//  Focus BearTests
//
//  A habit's late cutoff stands on its own: the Day Plan habit editor must not reject a cutoff for
//  falling outside the window between the global shutdown/startup times, nor for being earlier than
//  the global non-high-priority cutoff (bug report 2026-09-09). The editor keeps only the validation
//  that is genuinely the client's job — name, duration, days, videos, questions, tags.
//

@testable import Focus_Bear
import XCTest

final class HabitCutoffValidationTests: XCTestCase {

    private static let globalStartup = "07:00"
    private static let globalShutdown = "21:00"
    private static let globalCutoff = "22:00"

    override func setUp() {
        super.setUp()
        startTime = getTimeFromString(val: Self.globalStartup)
        shutOffTime = getTimeFromString(val: Self.globalShutdown)
        cutOffTime = getTimeFromString(val: Self.globalCutoff)
    }

    override func tearDown() {
        startTime = nil
        shutOffTime = nil
        cutOffTime = nil
        super.tearDown()
    }

    /// A must-do evening habit with a cutoff enabled — the only form that shows the cutoff field.
    private func eveningModel(cutoffMinutes: Int) -> HabitEditModel {
        var values = HabitEditValues.newHabit(in: .evening)
        values.name = "Read"
        values.cutoffEnabled = true
        values.cutoffMinutes = cutoffMinutes
        return HabitEditModel(values: values, section: .evening)
    }

    private static func minutes(_ time: String) -> Int { DayPlanRoutineDraft.minutes(fromTimeString: time) }

    func testCutoffBeforeTheGlobalCutoffIsAccepted() {
        // 21:30 is inside the evening window but EARLIER than the global 22:00 cutoff — the old rule.
        XCTAssertNil(eveningModel(cutoffMinutes: Self.minutes("21:30")).validationMessage)
    }

    func testCutoffBeforeTheEveningRoutineStartIsAccepted() {
        // 18:10 is before the 21:00 shutdown — the exact case from the bug report's screenshot.
        XCTAssertNil(eveningModel(cutoffMinutes: Self.minutes("18:10")).validationMessage)
    }

    func testCutoffAfterTheMorningRoutineStartIsAccepted() {
        // 09:00 sits past the 07:00 startup, i.e. outside the overnight window entirely.
        XCTAssertNil(eveningModel(cutoffMinutes: Self.minutes("09:00")).validationMessage)
    }

    func testCutoffIsAcceptedAtEveryMinuteOfTheDay() {
        for minute in stride(from: 0, to: 24 * 60, by: 15) {
            XCTAssertNil(eveningModel(cutoffMinutes: minute).validationMessage,
                         "cutoff \(DayPlanRoutineDraft.timeString(fromMinutes: minute)) should be allowed")
        }
    }

    func testCutoffIsAcceptedWhenTheGlobalTimesAreUnset() {
        startTime = nil
        shutOffTime = nil
        cutOffTime = nil
        XCTAssertNil(eveningModel(cutoffMinutes: Self.minutes("03:15")).validationMessage)
    }

    /// Removing the cutoff rule must not weaken the validation that is still the client's job.
    func testNamelessHabitIsStillRejected() {
        var values = HabitEditValues.newHabit(in: .evening)
        values.name = "   "
        XCTAssertEqual(HabitEditModel(values: values, section: .evening).validationMessage, ScheduleText.habitInvalidName)
    }

    func testOverlongDurationIsStillRejected() {
        var values = HabitEditValues.newHabit(in: .evening)
        values.name = "Read"
        values.durationSeconds = HabitEditValues.maxDurationSeconds + 1
        XCTAssertEqual(HabitEditModel(values: values, section: .evening).validationMessage,
                       ScheduleText.habitInvalidDurationRange)
    }

    func testEmptyWeeklyScheduleIsStillRejected() {
        var values = HabitEditValues.newHabit(in: .evening)
        values.name = "Read"
        values.daysOfWeek = []
        XCTAssertEqual(HabitEditModel(values: values, section: .evening).validationMessage, ScheduleText.habitInvalidDays)
    }
}
