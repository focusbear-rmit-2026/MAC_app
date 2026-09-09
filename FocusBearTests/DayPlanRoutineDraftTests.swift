//
//  DayPlanRoutineDraftTests.swift
//  Focus BearTests
//
//  The Day Plan habit editor's draft store: deleting a habit is a plain removal from its routine's
//  list (web `removeHabit` semantics), durations round-trip in seconds, and the compact duration label.
//

@testable import Focus_Bear
import XCTest

final class DayPlanRoutineDraftTests: XCTestCase {

    private static let morningA = "morning-a"
    private static let morningB = "morning-b"
    private static let morningC = "morning-c"
    private static let eveningA = "evening-a"
    private static let customA = "custom-a"
    private static let morningSequence = "seq-morning"
    private static let eveningSequence = "seq-evening"
    private static let customSequence = "seq-custom"
    private static let fixtureDays = ["MON", "TUE"]

    /// Two routines plus a custom one, the way `GET /user-settings` shapes them.
    private static let fixture: [String: Any] = [
        "startup_time": "07:00",
        "shutdown_time": "21:00",
        "morning_activities": [habitEntry(morningA, "Stretch", seconds: 1, sequence: morningSequence),
                               habitEntry(morningB, "Water", seconds: 30, sequence: morningSequence),
                               habitEntry(morningC, "Plan", seconds: 300, sequence: morningSequence)],
        "evening_activities": [habitEntry(eveningA, "Read", seconds: 600, sequence: eveningSequence)],
        "custom_routines": [[
            "activity_sequence_id": customSequence,
            "name": "Lunch",
            "start_time": "12:00",
            "end_time": "13:00",
            "standalone_activities": [habitEntry(customA, "Walk", seconds: 900, sequence: customSequence)],
        ]],
    ]

    private static func habitEntry(_ id: String, _ name: String, seconds: Int, sequence: String) -> [String: Any] {
        ["id": id, "name": name, "duration_seconds": seconds, "days_of_week": fixtureDays, "activity_sequence_id": sequence]
    }

    private func habitEntries(_ list: Any?) -> [[String: Any]] { list as? [[String: Any]] ?? [] }

    private func makeDraft() -> DayPlanRoutineDraft {
        let data = try! JSONSerialization.data(withJSONObject: Self.fixture)
        let json = String(data: data, encoding: .utf8)
        return DayPlanRoutineDraft(savedSettingsJSON: { json })
    }

    private func habitIds(_ list: Any?) -> [String] {
        (list as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? []
    }

    private func liveHabit(_ id: String) -> habit {
        habit(id: id, name: id, durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil,
              openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "",
              run_micro_breaks: false, take_notes: NO_NOTE, isPriorityHigh: false, days_of_week: [], text_instructions: "",
              imgUrls: [], completion_requirements: "", useTimer: true, checkList: [], tutorial: "")
    }

    override func tearDown() {
        arrFilteredMorningHabits = []
        arrPreFilteredMorningHabits = []
        arrAllDaysMorningHabits = []
        currentHabitPlaying = nil
        currentHabitIndex = -1
        super.tearDown()
    }

    // MARK: - Deleting

    func testDeleteRemovesOnlyThatHabitFromItsRoutine() {
        let draft = makeDraft()
        XCTAssertFalse(draft.hasChanges)

        XCTAssertTrue(draft.applyHabitDelete(id: Self.morningB))

        XCTAssertTrue(draft.hasChanges)
        XCTAssertEqual(habitIds(draft.settings?["morning_activities"]), [Self.morningA, Self.morningC])
        XCTAssertEqual(habitIds(draft.settings?["evening_activities"]), [Self.eveningA])
        XCTAssertNil(draft.habitEntry(id: Self.morningB))
    }

    func testDeleteCustomRoutineHabitLeavesTheRoutine() {
        let draft = makeDraft()

        XCTAssertTrue(draft.applyHabitDelete(id: Self.customA))

        let routines = draft.settings?["custom_routines"] as? [[String: Any]]
        XCTAssertEqual(routines?.count, 1)
        XCTAssertEqual(routines?.first?["activity_sequence_id"] as? String, Self.customSequence)
        XCTAssertEqual(habitIds(routines?.first?["standalone_activities"]), [])
    }

    func testDeleteUnknownHabitChangesNothing() {
        let draft = makeDraft()

        XCTAssertFalse(draft.applyHabitDelete(id: "nope"))

        XCTAssertFalse(draft.hasChanges)
    }

    func testDeleteBeforePlayingHabitKeepsPlayerOnSameHabit() {
        let draft = makeDraft()
        arrFilteredMorningHabits = [liveHabit(Self.morningA), liveHabit(Self.morningB), liveHabit(Self.morningC)]
        arrPreFilteredMorningHabits = arrFilteredMorningHabits
        arrAllDaysMorningHabits = arrFilteredMorningHabits
        currentHabitPlaying = arrFilteredMorningHabits[2]
        currentHabitIndex = 2

        draft.applyHabitDelete(id: Self.morningA)

        XCTAssertEqual(arrFilteredMorningHabits.map { $0.id }, [Self.morningB, Self.morningC])
        XCTAssertEqual(arrAllDaysMorningHabits.map { $0.id }, [Self.morningB, Self.morningC])
        XCTAssertEqual(currentHabitIndex, 1, "the player must still point at the playing habit")
        XCTAssertEqual(arrFilteredMorningHabits[currentHabitIndex].id, Self.morningC)
    }

    func testDeleteAfterPlayingHabitLeavesPlayerIndex() {
        let draft = makeDraft()
        arrFilteredMorningHabits = [liveHabit(Self.morningA), liveHabit(Self.morningB), liveHabit(Self.morningC)]
        currentHabitPlaying = arrFilteredMorningHabits[0]
        currentHabitIndex = 0

        draft.applyHabitDelete(id: Self.morningC)

        XCTAssertEqual(currentHabitIndex, 0)
        XCTAssertEqual(arrFilteredMorningHabits.map { $0.id }, [Self.morningA, Self.morningB])
    }

    // MARK: - Adding

    func testNewHabitDefaultsMirrorTheWeb() {
        let morning = HabitEditValues.newHabit(in: .morning)
        XCTAssertEqual(morning.name, "")
        XCTAssertEqual(morning.icon, "")
        XCTAssertTrue(morning.usesTimer)
        XCTAssertEqual(morning.durationSeconds, 300)
        XCTAssertTrue(morning.isHighPriority)
        XCTAssertEqual(morning.daysOfWeek, Set(HabitEditValues.weekdayCodes))
        XCTAssertFalse(morning.cutoffEnabled)
        XCTAssertFalse(morning.logQuantity)
        XCTAssertEqual(morning.takeNotes, NO_NOTE)
        XCTAssertEqual(HabitEditValues.newHabit(in: .evening).durationSeconds, 600)
        XCTAssertEqual(HabitEditValues.newHabit(in: .custom(sequenceId: Self.customSequence)).durationSeconds, 60)
    }

    func testAddAppendsHabitInTheWebShape() {
        let draft = makeDraft()
        var values = HabitEditValues.newHabit(in: .morning)
        values.icon = "🧘"
        values.name = "Meditate"

        let id = draft.applyHabitAdd(routine: .morning, values: values)

        XCTAssertNotNil(id)
        XCTAssertNotNil(UUID(uuidString: id ?? ""), "the web gives a new habit a uuid v4 id")
        XCTAssertTrue(draft.hasChanges)
        let morning = habitEntries(draft.settings?["morning_activities"])
        XCTAssertEqual(morning.map { $0["id"] as? String }, [Self.morningA, Self.morningB, Self.morningC, id])
        let added = morning.last!
        XCTAssertEqual(added["name"] as? String, "Meditate")
        XCTAssertEqual(added["habit_icon"] as? String, "🧘")
        XCTAssertEqual(added["duration_seconds"] as? Int, 300)
        XCTAssertNil(added["completion_requirements"])
        XCTAssertEqual(added["activity_sequence_id"] as? String, Self.morningSequence, "joins the routine's sequence")
        XCTAssertEqual(added["activity_type"] as? String, "morning")
        XCTAssertEqual(added["priority"] as? String, "HIGH")
        XCTAssertEqual(added["days_of_week"] as? [String], HabitEditValues.weekdayCodes)
        XCTAssertEqual(added["video_urls"] as? [String], [])
        XCTAssertEqual(added["allowed_apps"] as? [String], [])
        XCTAssertEqual(added["allowed_urls"] as? [String], [])
        XCTAssertEqual(added["log_quantity"] as? Bool, false)
        XCTAssertEqual(added["log_summary_type"] as? String, "SUM")
        XCTAssertNil(added["cutoff_time_for_doing_activity"])
        XCTAssertNil(added["allowed_focus_mode_id"])
        XCTAssertEqual(habitIds(draft.settings?["evening_activities"]), [Self.eveningA], "other routines untouched")
        XCTAssertEqual(draft.habitEditValues(id: id!)?.name, "Meditate", "the new habit can be re-opened for editing")
    }

    func testAddToCustomRoutineInheritsTheRoutineDays() {
        let draft = makeDraft()
        var values = HabitEditValues.newHabit(in: .custom(sequenceId: Self.customSequence))
        values.name = "Stroll"

        let id = draft.applyHabitAdd(routine: .custom(sequenceId: Self.customSequence), values: values)

        let routine = habitEntries(draft.settings?["custom_routines"]).first
        let habits = habitEntries(routine?["standalone_activities"])
        XCTAssertEqual(habits.map { $0["id"] as? String }, [Self.customA, id])
        XCTAssertEqual(habits.last?["activity_sequence_id"] as? String, Self.customSequence)
        XCTAssertEqual(habits.last?["activity_type"] as? String, "standalone")
        XCTAssertEqual(habits.last?["days_of_week"] as? [String], Self.fixtureDays, "a subset of the routine's days, like its siblings")
        XCTAssertEqual(habits.last?["duration_seconds"] as? Int, 60)
    }

    func testAddToUnknownRoutineChangesNothing() {
        let draft = makeDraft()

        XCTAssertNil(draft.applyHabitAdd(routine: .custom(sequenceId: "nope"), values: HabitEditValues.newHabit(in: .morning)))

        XCTAssertFalse(draft.hasChanges)
    }

    func testAddThenDeleteRoundTrips() {
        let draft = makeDraft()
        var values = HabitEditValues.newHabit(in: .evening)
        values.name = "Floss"
        let before = draft.settings?["evening_activities"]
        XCTAssertNil(before)

        let id = draft.applyHabitAdd(routine: .evening, values: values)!
        XCTAssertEqual(habitIds(draft.settings?["evening_activities"]), [Self.eveningA, id])

        XCTAssertTrue(draft.applyHabitDelete(id: id))

        XCTAssertEqual(habitIds(draft.settings?["evening_activities"]), [Self.eveningA])
        XCTAssertNil(draft.habitEntry(id: id))
    }

    func testAddAppendsToLiveArraysWithoutMovingThePlayer() {
        let draft = makeDraft()
        arrFilteredMorningHabits = [liveHabit(Self.morningA), liveHabit(Self.morningB)]
        arrPreFilteredMorningHabits = arrFilteredMorningHabits
        arrAllDaysMorningHabits = arrFilteredMorningHabits
        currentHabitPlaying = arrFilteredMorningHabits[1]
        currentHabitIndex = 1
        var values = HabitEditValues.newHabit(in: .morning)
        values.icon = "💧"
        values.name = "Drink water"

        let id = draft.applyHabitAdd(routine: .morning, values: values)

        XCTAssertEqual(arrAllDaysMorningHabits.map { $0.id }, [Self.morningA, Self.morningB, id])
        XCTAssertEqual(arrPreFilteredMorningHabits.map { $0.id }, [Self.morningA, Self.morningB, id])
        XCTAssertEqual(arrFilteredMorningHabits.map { $0.id }, [Self.morningA, Self.morningB, id], "an every-day habit is scheduled today")
        XCTAssertEqual(currentHabitIndex, 1)
        let added = arrAllDaysMorningHabits.last!
        XCTAssertEqual(added.name, "💧 Drink water")
        XCTAssertEqual(added.nameWithoutIcon, "Drink water")
        XCTAssertEqual(added.habitIcon, "💧")
        XCTAssertEqual(added.durationSeconds, 300)
        XCTAssertTrue(added.useTimer)
        XCTAssertEqual(added.days_of_week, HabitEditValues.weekdayCodes)
    }

    // MARK: - Duration in seconds

    func testOneSecondHabitReadsAsOneSecond() {
        let values = makeDraft().habitEditValues(id: Self.morningA)

        XCTAssertEqual(values?.durationSeconds, 1)
        XCTAssertEqual(values?.durationMinutesPart, 0)
        XCTAssertEqual(values?.durationSecondsPart, 1)
    }

    func testEditWritesDurationSecondsUnchanged() {
        let draft = makeDraft()
        var values = draft.habitEditValues(id: Self.morningB)!
        values.durationMinutesPart = 1
        values.durationSecondsPart = 30

        XCTAssertTrue(draft.applyHabitEdit(id: Self.morningB, values: values))

        XCTAssertEqual(draft.habitEntry(id: Self.morningB)?.entry["duration_seconds"] as? Int, 90)
    }

    func testDurationPartsClampToTheirFields() {
        var values = makeDraft().habitEditValues(id: Self.morningC)!
        values.durationSecondsPart = 75
        XCTAssertEqual(values.durationSecondsPart, HabitEditValues.maxSecondsPart)
        values.durationMinutesPart = 5000
        XCTAssertEqual(values.durationMinutesPart, HabitEditValues.maxDurationMinutes)
        values.durationMinutesPart = 0
        values.durationSecondsPart = 0
        XCTAssertFalse(values.isDurationValid)
        values.durationSecondsPart = 1
        XCTAssertTrue(values.isDurationValid)
    }

    func testShortDurationText() {
        XCTAssertEqual(HabitDurationText.short(seconds: 1), "1s")
        XCTAssertEqual(HabitDurationText.short(seconds: 45), "45s")
        XCTAssertEqual(HabitDurationText.short(seconds: 90), "1m 30s")
        XCTAssertEqual(HabitDurationText.short(seconds: 300), "5m")
        XCTAssertEqual(HabitDurationText.short(seconds: 3900), "1h 5m")
    }
}
