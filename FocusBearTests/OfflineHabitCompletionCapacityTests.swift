//
//  OfflineHabitCompletionCapacityTests.swift
//  Focus BearTests
//
//  A habit finished while the Mac is offline is still finished. Until it was recorded locally, the
//  routine player dropped it immediately (so the timeline turned its slot into deep work) while the
//  Day Plan's capacity kept charging for it — the panel read "54m of tasks planned · -5m buffer"
//  beside 71 minutes of drawn deep work, and the gap widened with every habit completed
//  (report 2026-09-17_08-56-04: five completions, every one "activityCompletedApi error:- The
//  Internet connection appears to be offline").
//

@testable import Focus_Bear
import XCTest

final class OfflineHabitCompletionCapacityTests: XCTestCase {

    private static let habitIds = ["offline-habit-a", "offline-habit-b", "offline-habit-c"]
    private static let habitMinutes = 20
    private static let dayKeyFormat = "yyyy-MM-dd"

    private var savedMorning: [habit] = []
    private var savedEvening: [habit] = []
    private var savedCustom: [routine] = []
    private var savedStart: Time?
    private var savedShutOff: Time?
    private var savedCutOff: Time?
    private var savedCompleted = Set<String>()
    private var savedCompletedByDay: [String: Set<String>] = [:]

    override func setUp() {
        super.setUp()
        savedMorning = arrAllDaysMorningHabits
        savedEvening = arrAllDaysEveningHabits
        savedCustom = arrAllCustomRoutine
        savedStart = startTime
        savedShutOff = shutOffTime
        savedCutOff = cutOffTime
        savedCompleted = dayPlanCompletedHabitIds
        savedCompletedByDay = dayPlanCompletedHabitIdsByDay

        arrAllDaysMorningHabits = Self.habitIds.map(makeHabit)
        arrAllDaysEveningHabits = []
        arrAllCustomRoutine = []
        startTime = Time(hour: 6, minute: 30, second: 0)
        shutOffTime = Time(hour: 21, minute: 0, second: 0)
        cutOffTime = Time(hour: 18, minute: 0, second: 0)
        dayPlanCompletedHabitIds = []
        dayPlanCompletedHabitIdsByDay = [:]
    }

    override func tearDown() {
        arrAllDaysMorningHabits = savedMorning
        arrAllDaysEveningHabits = savedEvening
        arrAllCustomRoutine = savedCustom
        startTime = savedStart
        shutOffTime = savedShutOff
        cutOffTime = savedCutOff
        dayPlanCompletedHabitIds = savedCompleted
        dayPlanCompletedHabitIdsByDay = savedCompletedByDay
        super.tearDown()
    }

    // MARK: - Fixtures

    private func makeHabit(_ id: String) -> habit {
        habit(id: id, name: id, durationSeconds: Self.habitMinutes * 60, urlsArray: [], logQuantity: false,
              logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [],
              allowedFocusMode: "", activity_sequence_id: "seq", run_micro_breaks: false, take_notes: NO_NOTE,
              isPriorityHigh: false, days_of_week: ["all"], text_instructions: "", imgUrls: [],
              completion_requirements: "", useTimer: true, checkList: [], tutorial: "")
    }

    /// The moment both builds are anchored to — a fixed time today, so the test doesn't depend on
    /// when it runs.
    private var buildPoint: Date {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private func capacity(of segments: [ScheduleRoutineSegment]) -> Double {
        let now = buildPoint
        let dayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now
        let blocks = ScheduleBuilder.build(segments: segments, meetings: [], now: now, dayEnd: dayEnd,
                                           leaveBufferSeconds: 120, outOfOrderAllowed: false,
                                           eveningRoutineStart: ScheduleTab.timeOnDate(shutOffTime, date: now),
                                           morningRoutineStart: ScheduleTab.timeOnDate(startTime, date: now),
                                           meetingsFrom: now,
                                           deepWorkCutoff: ScheduleTab.timeOnDate(cutOffTime, date: now))
        let day = LocalTimeForecast.DayInput.fromDayPlan(date: now, blocks: blocks, availableFrom: now)
        let result = LocalTimeForecast.calculate(days: [day], projects: [], tasks: [], calendar: .current)
        return result.days.first?.capacity.availableWorkMinutes ?? 0
    }

    /// What the capacity panel builds today from: the all-days routine minus whatever is recorded done.
    private var panelSegments: [ScheduleRoutineSegment] { ScheduleTab.segmentsForDate(buildPoint) }

    /// What the timeline draws today from: the routine player's REMAINING habits, which it drops the
    /// moment one is finished, online or not.
    private func timelineSegments(remaining: [String]) -> [ScheduleRoutineSegment] {
        let now = buildPoint
        return ScheduleTab.standardSegments(activeName: ScheduleText.morningRoutineHabits,
                                            activeHabits: ScheduleTab.habitInputs(from: remaining.map(makeHabit), now: now),
                                            isMorningActive: true, now: now)
    }

    // MARK: - The bug

    /// Two habits finished offline must free their time in the capacity panel, exactly as they freed
    /// it in the timeline. Before the fix nothing recorded them, so the panel kept subtracting 40
    /// minutes the plan no longer spends.
    func testHabitsFinishedOfflineStopBeingChargedToTodaysCapacity() {
        let untouched = capacity(of: panelSegments)
        let finished = Array(Self.habitIds.prefix(2))

        finished.forEach { markPastHabitDoneInDayPlan(id: $0) }

        let afterFinishing = capacity(of: panelSegments)
        XCTAssertEqual(afterFinishing - untouched, Double(finished.count * Self.habitMinutes), accuracy: 0.01,
                       "each habit finished offline must give its own minutes back to the day")
    }

    /// The panel and the timeline are two readings of one day: once the completions are recorded, the
    /// capacity built from the all-days routine has to match the capacity of the blocks the timeline
    /// actually drew.
    func testCapacityMatchesTheBlocksTheTimelineDraws() {
        let finished = Array(Self.habitIds.prefix(2))
        let remaining = Self.habitIds.filter { !finished.contains($0) }

        finished.forEach { markPastHabitDoneInDayPlan(id: $0) }

        XCTAssertEqual(capacity(of: panelSegments), capacity(of: timelineSegments(remaining: remaining)),
                       accuracy: 0.01, "the panel's capacity and the drawn day must be the same number")
    }

    /// The header arithmetic is unchanged by any of this, and a day genuinely over capacity still says so.
    func testPlannedPlusBufferStillEqualsCapacityAndOvercommitmentSurvives() {
        markPastHabitDoneInDayPlan(id: Self.habitIds[0])
        let free = capacity(of: panelSegments)

        let comfortable = LocalTimeForecast.dayLoad(day: buildPoint, capacityMinutes: free, plannedMinutes: free - 10)
        XCTAssertEqual(comfortable.committedMinutes + comfortable.bufferMinutes, comfortable.capacityMinutes,
                       accuracy: 0.01, "planned + buffer = capacity still holds")
        XCTAssertFalse(comfortable.isOvercommitted)

        let overloaded = LocalTimeForecast.dayLoad(day: buildPoint, capacityMinutes: free, plannedMinutes: free + 30)
        XCTAssertEqual(overloaded.committedMinutes + overloaded.bufferMinutes, overloaded.capacityMinutes,
                       accuracy: 0.01, "planned + buffer = capacity still holds when the day is over")
        XCTAssertTrue(overloaded.isOvercommitted, "a day genuinely over capacity must still report as over")
        XCTAssertEqual(overloaded.bufferMinutes, -30, accuracy: 0.01)
    }

    // MARK: - Which day an offline row belongs to

    /// The CSV stores UTC, completion is tracked per LOCAL day. Matching the raw UTC text instead lost
    /// every row whose local time falls on the previous UTC day — which, at UTC+10, is the whole
    /// morning routine.
    func testOfflineRowBelongsToItsLocalDayNotItsUtcOne() {
        let cal = Calendar.current
        guard let earlyLocal = cal.date(bySettingHour: 0, minute: 30, second: 0, of: Date()) else {
            return XCTFail("could not build a local early-morning time")
        }
        let localDay = getStringFromDate(date: earlyLocal, dateFormat: Self.dayKeyFormat)
        let storedUtc = getStringFromDateInUtc(date: earlyLocal, dateFormat: offlineActivityTimestampFormat)

        XCTAssertEqual(offlineActivityLocalDayKey(storedUtc), localDay)
        if TimeZone.current.secondsFromGMT(for: earlyLocal) > 0 {
            XCTAssertFalse(storedUtc.hasPrefix(localDay),
                           "east of Greenwich this row's UTC text names the previous day — the case the prefix match lost")
        }
    }

    func testUnparseableTimestampHasNoDay() {
        XCTAssertNil(offlineActivityLocalDayKey(""))
        XCTAssertNil(offlineActivityLocalDayKey("not-a-timestamp"))
    }
}
