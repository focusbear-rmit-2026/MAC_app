//
//  CustomRoutineDraftTests.swift
//  Focus BearTests
//
//  Creating, editing, deleting a custom routine and reordering its habits, all through
//  `DayPlanRoutineDraft`. The JSON these write must match the web dashboard's `INIT_CUSTOM_ROUTINE`
//  (web_dashboard/src/assets/data/index.ts:1093) key for key, because the same blob is PUT back to
//  `/user/settings` and re-parsed by AppDelegate.readSettingsJsonDictionary.
//

@testable import Focus_Bear
import XCTest

final class CustomRoutineDraftTests: XCTestCase {

    private static let existingSequence = "seq-lunch"
    private static let habitA = "custom-a"
    private static let habitB = "custom-b"
    private static let habitC = "custom-c"

    private static let fixture: [String: Any] = [
        "startup_time": "07:00",
        "shutdown_time": "21:00",
        "morning_activities": [],
        "evening_activities": [],
        "custom_routines": [[
            "id": "routine-1",
            "activity_sequence_id": existingSequence,
            "name": "Lunch",
            "trigger": "ON_SCHEDULE",
            "days_of_week": ["MON", "TUE", "WED"],
            "start_time": "12:00",
            "end_time": "13:00",
            "standalone_activities": [habitEntry(habitA, "Walk", seconds: 900),
                                      habitEntry(habitB, "Stretch", seconds: 300),
                                      habitEntry(habitC, "Water", seconds: 60)],
        ]],
    ]

    private static func habitEntry(_ id: String, _ name: String, seconds: Int) -> [String: Any] {
        ["id": id, "name": name, "duration_seconds": seconds, "days_of_week": ["MON", "TUE", "WED"],
         "activity_sequence_id": existingSequence, "activity_type": "standalone"]
    }

    private func makeDraft() -> DayPlanRoutineDraft {
        let data = try! JSONSerialization.data(withJSONObject: Self.fixture)
        let json = String(data: data, encoding: .utf8)
        return DayPlanRoutineDraft(savedSettingsJSON: { json })
    }

    private func routineEntries(_ draft: DayPlanRoutineDraft) -> [[String: Any]] {
        (draft.settings?["custom_routines"] as? [[String: Any]]) ?? []
    }

    private func routineEntry(_ draft: DayPlanRoutineDraft, sequenceId: String) -> [String: Any]? {
        routineEntries(draft).first { $0["activity_sequence_id"] as? String == sequenceId }
    }

    private func habitIds(_ entry: [String: Any]?) -> [String] {
        (entry?["standalone_activities"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? []
    }

    override func tearDown() {
        arrAllCustomRoutine = []
        super.tearDown()
    }

    // MARK: Reading

    func testSummariesReadTheSavedRoutines() {
        let summaries = makeDraft().customRoutineSummaries()
        XCTAssertEqual(summaries.count, 1)
        let routine = summaries[0]
        XCTAssertEqual(routine.id, Self.existingSequence)
        XCTAssertEqual(routine.values.name, "Lunch")
        XCTAssertFalse(routine.values.triggerOnDemand)
        XCTAssertEqual(routine.values.orderedDays, ["MON", "TUE", "WED"])
        XCTAssertEqual(routine.values.startMinutes, 12 * 60)
        XCTAssertEqual(routine.values.endMinutes, 13 * 60)
        XCTAssertEqual(routine.habits.map { $0.id }, [Self.habitA, Self.habitB, Self.habitC])
        XCTAssertEqual(routine.habits.map { $0.name }, ["Walk", "Stretch", "Water"])
        XCTAssertFalse(routine.isEmpty)
    }

    func testAnOnDemandRoutineIsReadAsSuch() {
        var fixture = Self.fixture
        var routine = (fixture["custom_routines"] as! [[String: Any]])[0]
        routine["trigger"] = "on_demand"   // the parser upper-cases before comparing
        fixture["custom_routines"] = [routine]
        let json = String(data: try! JSONSerialization.data(withJSONObject: fixture), encoding: .utf8)
        let draft = DayPlanRoutineDraft(savedSettingsJSON: { json })
        XCTAssertTrue(draft.customRoutineSummaries()[0].values.triggerOnDemand)
    }

    // MARK: Creating

    func testAddWritesTheWebsCustomRoutineShape() throws {
        let draft = makeDraft()
        let values = CustomRoutineEditValues(name: "  Wind down  ", triggerOnDemand: false,
                                             daysOfWeek: ["SAT", "MON"], startMinutes: 20 * 60,
                                             endMinutes: 20 * 60 + 30)
        let sequenceId = try XCTUnwrap(draft.applyCustomRoutineAdd(values: values))

        let entry = try XCTUnwrap(routineEntry(draft, sequenceId: sequenceId))
        XCTAssertEqual(entry["name"] as? String, "Wind down")                     // trimmed
        XCTAssertEqual(entry["trigger"] as? String, "ON_SCHEDULE")
        XCTAssertEqual(entry["days_of_week"] as? [String], ["MON", "SAT"])        // display order
        XCTAssertEqual(entry["start_time"] as? String, "20:00")
        XCTAssertEqual(entry["end_time"] as? String, "20:30")
        XCTAssertEqual(entry["activity_sequence_id"] as? String, sequenceId)
        XCTAssertEqual((entry["standalone_activities"] as? [Any])?.count, 0)
        // The web gives a routine BOTH an `id` and an `activity_sequence_id`, and they differ.
        let id = try XCTUnwrap(entry["id"] as? String)
        XCTAssertNotEqual(id, sequenceId)
        XCTAssertNotNil(UUID(uuidString: id))
        XCTAssertNotNil(UUID(uuidString: sequenceId))
        // The existing routine is untouched and still first.
        XCTAssertEqual(routineEntries(draft).count, 2)
        XCTAssertEqual(routineEntries(draft)[0]["activity_sequence_id"] as? String, Self.existingSequence)
    }

    func testAddMirrorsTheRoutineIntoTheLiveArray() throws {
        let draft = makeDraft()
        let values = CustomRoutineEditValues(name: "Wind down", triggerOnDemand: true,
                                             daysOfWeek: Set(HabitEditValues.weekdayCodes),
                                             startMinutes: 20 * 60, endMinutes: 21 * 60)
        let sequenceId = try XCTUnwrap(draft.applyCustomRoutineAdd(values: values))
        let live = try XCTUnwrap(arrAllCustomRoutine.first { $0.sequenceId == sequenceId })
        XCTAssertEqual(live.title, "Wind down")
        XCTAssertTrue(live.triggerOnDemand)
        XCTAssertEqual(live.days_of_week.count, 7)
        XCTAssertEqual(live.startTime?.hour, 20)
    }

    /// The API rejects `end_time <= start_time`, and the editor doesn't ask an on-demand routine for a
    /// window — so one is always written.
    func testAnInvalidWindowIsRepairedOnWrite() throws {
        let draft = makeDraft()
        let values = CustomRoutineEditValues(name: "Ad hoc", triggerOnDemand: true,
                                             daysOfWeek: Set(HabitEditValues.weekdayCodes),
                                             startMinutes: 9 * 60, endMinutes: 9 * 60)
        let sequenceId = try XCTUnwrap(draft.applyCustomRoutineAdd(values: values))
        let entry = try XCTUnwrap(routineEntry(draft, sequenceId: sequenceId))
        XCTAssertEqual(entry["start_time"] as? String, "09:00")
        XCTAssertEqual(entry["end_time"] as? String, "10:00")
    }

    func testNewRoutineDefaultsMatchTheWeb() {
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let values = CustomRoutineEditValues.newRoutine(now: noon)
        XCTAssertEqual(values.name, "")
        XCTAssertFalse(values.triggerOnDemand)                       // web: ON_SCHEDULE
        XCTAssertEqual(values.daysOfWeek, Set(HabitEditValues.weekdayCodes))
        XCTAssertEqual(values.startMinutes, 12 * 60)
        XCTAssertEqual(values.endMinutes, 13 * 60)                   // start + 60 min
    }

    // MARK: Editing

    func testEditWritesEveryRoutineField() throws {
        let draft = makeDraft()
        let values = CustomRoutineEditValues(name: "Lunch walk", triggerOnDemand: true,
                                             daysOfWeek: ["TUE"], startMinutes: 12 * 60 + 30,
                                             endMinutes: 13 * 60 + 15)
        XCTAssertTrue(draft.applyCustomRoutineEdit(sequenceId: Self.existingSequence, values: values))

        let entry = try XCTUnwrap(routineEntry(draft, sequenceId: Self.existingSequence))
        XCTAssertEqual(entry["name"] as? String, "Lunch walk")
        XCTAssertEqual(entry["trigger"] as? String, "ON_DEMAND")
        XCTAssertEqual(entry["days_of_week"] as? [String], ["TUE"])
        XCTAssertEqual(entry["start_time"] as? String, "12:30")
        XCTAssertEqual(entry["end_time"] as? String, "13:15")
        XCTAssertEqual(habitIds(entry), [Self.habitA, Self.habitB, Self.habitC])   // habits untouched
    }

    /// The API requires a custom routine's habits to run on a subset of the routine's own days.
    func testNarrowingTheRoutinesDaysNarrowsItsHabits() throws {
        let draft = makeDraft()
        let values = CustomRoutineEditValues(name: "Lunch", triggerOnDemand: false,
                                             daysOfWeek: ["MON"], startMinutes: 12 * 60, endMinutes: 13 * 60)
        XCTAssertTrue(draft.applyCustomRoutineEdit(sequenceId: Self.existingSequence, values: values))
        let entry = try XCTUnwrap(routineEntry(draft, sequenceId: Self.existingSequence))
        let habits = try XCTUnwrap(entry["standalone_activities"] as? [[String: Any]])
        for habit in habits {
            XCTAssertEqual(habit["days_of_week"] as? [String], ["MON"])
        }
    }

    func testEditingAnUnknownRoutineChangesNothing() {
        let draft = makeDraft()
        XCTAssertFalse(draft.applyCustomRoutineEdit(sequenceId: "nope", values: .newRoutine()))
        XCTAssertNil(draft.settings)
    }

    // MARK: Deleting

    func testDeleteRemovesTheRoutineAndItsHabits() {
        let draft = makeDraft()
        XCTAssertTrue(draft.applyCustomRoutineDelete(sequenceId: Self.existingSequence))
        XCTAssertEqual(routineEntries(draft).count, 0)
        XCTAssertNil(draft.habitEntry(id: Self.habitA))
        XCTAssertTrue(arrAllCustomRoutine.isEmpty)
    }

    func testDeletingAnUnknownRoutineChangesNothing() {
        let draft = makeDraft()
        XCTAssertFalse(draft.applyCustomRoutineDelete(sequenceId: "nope"))
        XCTAssertNil(draft.settings)
    }

    // MARK: Adding habits to a custom routine

    func testAddingAHabitUsesTheWebsStandaloneDefaults() throws {
        let draft = makeDraft()
        let section = RoutineSettingsSection.custom(sequenceId: Self.existingSequence)
        var values = HabitEditValues.newHabit(in: section)
        values.name = "Fresh air"
        let id = try XCTUnwrap(draft.applyHabitAdd(routine: section, values: values))

        let entry = try XCTUnwrap(routineEntry(draft, sequenceId: Self.existingSequence))
        XCTAssertEqual(habitIds(entry), [Self.habitA, Self.habitB, Self.habitC, id])
        let added = try XCTUnwrap((entry["standalone_activities"] as? [[String: Any]])?.last)
        XCTAssertEqual(added["name"] as? String, "Fresh air")
        XCTAssertEqual(added["activity_type"] as? String, "standalone")
        XCTAssertEqual(added["activity_sequence_id"] as? String, Self.existingSequence)
        XCTAssertEqual(added["duration_seconds"] as? Int, NewHabitDefaultSeconds.custom)   // web DEFAULT_DURATION.STANDALONE
        XCTAssertEqual(added["days_of_week"] as? [String], ["MON", "TUE", "WED"])          // inherits the routine's days
    }

    func testANewCustomRoutineHabitStartsAtSixtySeconds() {
        XCTAssertEqual(NewHabitDefaultSeconds.custom, 60)
        let values = HabitEditValues.newHabit(in: .custom(sequenceId: Self.existingSequence))
        XCTAssertEqual(values.durationSeconds, 60)
    }

    // MARK: Reordering habits

    func testMovingAHabitDownReordersTheSettingsList() throws {
        let draft = makeDraft()
        XCTAssertTrue(draft.applyHabitMove(in: .custom(sequenceId: Self.existingSequence), from: 0, to: 2))
        XCTAssertEqual(habitIds(routineEntry(draft, sequenceId: Self.existingSequence)),
                       [Self.habitB, Self.habitC, Self.habitA])
    }

    func testMovingAHabitUpReordersTheSettingsList() throws {
        let draft = makeDraft()
        XCTAssertTrue(draft.applyHabitMove(in: .custom(sequenceId: Self.existingSequence), from: 2, to: 0))
        XCTAssertEqual(habitIds(routineEntry(draft, sequenceId: Self.existingSequence)),
                       [Self.habitC, Self.habitA, Self.habitB])
    }

    func testAnOutOfRangeOrNoOpMoveChangesNothing() {
        let draft = makeDraft()
        XCTAssertFalse(draft.applyHabitMove(in: .custom(sequenceId: Self.existingSequence), from: 1, to: 1))
        XCTAssertFalse(draft.applyHabitMove(in: .custom(sequenceId: Self.existingSequence), from: 0, to: 9))
        XCTAssertFalse(draft.applyHabitMove(in: .custom(sequenceId: "nope"), from: 0, to: 1))
        XCTAssertNil(draft.settings)
    }

    func testMovingAHabitReordersTheLiveRoutineArrays() throws {
        let draft = makeDraft()
        arrAllCustomRoutine = [routine(title: "Lunch", sequenceId: Self.existingSequence, startTime: nil,
                                       endTime: nil, triggerOnDemand: false,
                                       arrAllHabits: [liveHabit(Self.habitA), liveHabit(Self.habitB), liveHabit(Self.habitC)],
                                       arrAllFilteredHabits: [liveHabit(Self.habitA), liveHabit(Self.habitB), liveHabit(Self.habitC)],
                                       days_of_week: ["MON"])]
        XCTAssertTrue(draft.applyHabitMove(in: .custom(sequenceId: Self.existingSequence), from: 0, to: 2))
        XCTAssertEqual(arrAllCustomRoutine[0].arrAllHabits.map { $0.id }, [Self.habitB, Self.habitC, Self.habitA])
        XCTAssertEqual(arrAllCustomRoutine[0].arrAllFilteredHabits.map { $0.id }, [Self.habitB, Self.habitC, Self.habitA])
    }

    // MARK: Validation

    func testWindowValidity() {
        var values = CustomRoutineEditValues.newRoutine()
        values.triggerOnDemand = false
        values.startMinutes = 10 * 60
        values.endMinutes = 10 * 60
        XCTAssertFalse(values.isWindowValid)
        values.endMinutes = 10 * 60 + 1
        XCTAssertTrue(values.isWindowValid)
        // An on-demand routine has no window to get wrong.
        values.triggerOnDemand = true
        values.endMinutes = values.startMinutes
        XCTAssertTrue(values.isWindowValid)
    }

    private func liveHabit(_ id: String) -> habit {
        habit(id: id, name: id, durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil,
              openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "",
              run_micro_breaks: false, take_notes: NO_NOTE, isPriorityHigh: false, days_of_week: [], text_instructions: "",
              imgUrls: [], completion_requirements: "", useTimer: true, checkList: [], tutorial: "")
    }
}
