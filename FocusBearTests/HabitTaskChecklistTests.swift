//
//  HabitTaskChecklistTests.swift
//  Focus BearTests
//
//  The pure half of the habit player's task checklist (HabitTaskChecklist.swift): which Day Plan
//  tasks belong to the habit being played, what a tick maps onto in the to-do world, and the pane
//  height the player gives the list. Nothing here touches the store, the network or AppKit.
//

@testable import Focus_Bear
import XCTest

final class HabitTaskChecklistTests: XCTestCase {

    private func task(_ title: String, blockKey: String?, done: Bool = false,
                      sourceTaskId: String? = nil) -> DayPlanTask {
        DayPlanTask(title: title, done: done, sourceTaskId: sourceTaskId, blockKey: blockKey)
    }

    // MARK: - The key format

    func testBlockKeyIsThePrefixedHabitName() {
        XCTAssertEqual(HabitTaskChecklist.blockKey(forHabitNamed: "Linkedin outreach"), "habit:Linkedin outreach")
    }

    /// The Day Plan wrote `"habit:<name>"` long before this feature existed; the reader has to keep
    /// agreeing with it exactly, so round-trip the name through both directions.
    func testHabitNameRoundTripsThroughTheKey() {
        let name = "Deep work: write the 2pm brief"
        XCTAssertEqual(HabitTaskChecklist.habitName(inBlockKey: HabitTaskChecklist.blockKey(forHabitNamed: name)), name)
    }

    func testHabitNameIsNilForNonHabitKeys() {
        XCTAssertNil(HabitTaskChecklist.habitName(inBlockKey: nil))
        XCTAssertNil(HabitTaskChecklist.habitName(inBlockKey: "event:ABC-123"))
        XCTAssertNil(HabitTaskChecklist.habitName(inBlockKey: "deepwork:1757000000"))
        // The degenerate key an unnamed habit would produce must not read as a habit.
        XCTAssertNil(HabitTaskChecklist.habitName(inBlockKey: "habit:"))
    }

    // MARK: - Which tasks belong to a habit

    func testOnlyTasksDroppedOnThisHabitAreListed() {
        let tasks = [
            task("Ask Josh how he found Focus Button", blockKey: "habit:Linkedin outreach"),
            task("Draft the V2 post", blockKey: "habit:V2 outreach"),
            task("Reply to Sam", blockKey: "event:cal-1"),
            task("Refactor the sync", blockKey: "deepwork:1757000000"),
            task("Buy milk", blockKey: nil),
            task("Publish the changelog", blockKey: "habit:Linkedin outreach", done: true),
        ]
        let mine = HabitTaskChecklist.tasks(forHabitNamed: "Linkedin outreach", in: tasks)
        XCTAssertEqual(mine.map { $0.title },
                       ["Ask Josh how he found Focus Button", "Publish the changelog"])
    }

    func testCompletedTasksStayOnTheList() {
        // Ticking a row must leave it visible (struck through) rather than making it vanish mid-habit.
        let tasks = [task("Done already", blockKey: "habit:Reading", done: true)]
        XCTAssertEqual(HabitTaskChecklist.tasks(forHabitNamed: "Reading", in: tasks).count, 1)
    }

    func testAHabitWithNoNameOwnsNothing() {
        // Guards the degenerate "habit:" key: an unnamed habit must not adopt every malformed row.
        let tasks = [task("Orphan", blockKey: "habit:"), task("Real", blockKey: "habit:Reading")]
        XCTAssertTrue(HabitTaskChecklist.tasks(forHabitNamed: nil, in: tasks).isEmpty)
        XCTAssertTrue(HabitTaskChecklist.tasks(forHabitNamed: "", in: tasks).isEmpty)
    }

    func testNamesAreMatchedWholeNotByPrefix() {
        let tasks = [task("Wrong habit", blockKey: "habit:Reading time")]
        XCTAssertTrue(HabitTaskChecklist.tasks(forHabitNamed: "Reading", in: tasks).isEmpty)
    }

    func testOrderFollowsTheStoredOrder() {
        let tasks = [
            task("Third", blockKey: "habit:Reading"),
            task("Elsewhere", blockKey: nil),
            task("First", blockKey: "habit:Reading"),
        ]
        XCTAssertEqual(HabitTaskChecklist.tasks(forHabitNamed: "Reading", in: tasks).map { $0.title },
                       ["Third", "First"])
    }

    // MARK: - What a tick maps onto

    func testTickMapsToTheBackingTodoId() {
        let imported = task("From the to-do list", blockKey: "habit:Reading", sourceTaskId: "todo-77")
        XCTAssertEqual(HabitTaskChecklist.todoID(for: imported), "todo-77")
    }

    func testTickOnAFromScratchTaskHasNoTodoToComplete() {
        // A local-only Day Plan row still toggles — there is just nothing to tell the backend about.
        XCTAssertNil(HabitTaskChecklist.todoID(for: task("Typed here", blockKey: "habit:Reading")))
        XCTAssertNil(HabitTaskChecklist.todoID(for: task("Blank id", blockKey: "habit:Reading", sourceTaskId: "")))
    }

    func testApplyingDoneFlipsTheTask() {
        let open = task("Ask Josh", blockKey: "habit:Reading", sourceTaskId: "todo-1")
        let ticked = HabitTaskChecklist.applying(done: true, to: open)
        XCTAssertEqual(ticked?.done, true)
        XCTAssertEqual(ticked?.sourceTaskId, "todo-1", "the to-do link must survive the flip")
    }

    func testUntickingReversesIt() {
        let ticked = task("Ask Josh", blockKey: "habit:Reading", done: true, sourceTaskId: "todo-1")
        XCTAssertEqual(HabitTaskChecklist.applying(done: false, to: ticked)?.done, false)
    }

    func testApplyingTheStateItAlreadyHasIsNoChange() {
        // nil is how the caller skips a redundant write — and a redundant PUT /to-do.
        let open = task("Ask Josh", blockKey: "habit:Reading")
        XCTAssertNil(HabitTaskChecklist.applying(done: false, to: open))
        let done = task("Ask Josh", blockKey: "habit:Reading", done: true)
        XCTAssertNil(HabitTaskChecklist.applying(done: true, to: done))
    }

    // MARK: - Pane sizing

    func testPaneHeightGrowsWithTheListButStaysBounded() {
        let one = timerViewcontroller.habitTaskPaneHeight(rowCount: 1)
        let four = timerViewcontroller.habitTaskPaneHeight(rowCount: 4)
        let many = timerViewcontroller.habitTaskPaneHeight(rowCount: 50)
        XCTAssertLessThanOrEqual(one, four)
        XCTAssertLessThan(four, many)
        XCTAssertEqual(many, timerViewcontroller.habitTaskPaneHeight(rowCount: 500),
                       "a long list scrolls rather than stretching the player")
        XCTAssertGreaterThanOrEqual(one, 90)
    }

    // MARK: Focus-session queue → planned task (report 2026-09-14_10-09-59)

    func testFocusQueueEntryResolvesByTheToDoIdItCarries() {
        let planned = DayPlanTask(title: "Expand synopsis", sourceTaskId: "todo-1")
        let other = DayPlanTask(title: "Something else", sourceTaskId: "todo-2")
        XCTAssertEqual(FocusQueueTaskMatch.task(for: "todo-1", in: [other, planned])?.id, planned.id)
    }

    func testFocusQueueEntryFallsBackToTheLocalIdForATaskWithNoToDo() {
        let local = DayPlanTask(title: "Local only")
        XCTAssertEqual(FocusQueueTaskMatch.task(for: local.id, in: [local])?.id, local.id)
    }

    func testAToDoIdBeatsALocalIdWhenBothCouldMatch() {
        let byLocalId = DayPlanTask(title: "Local")
        let byTodoId = DayPlanTask(title: "Synced", sourceTaskId: byLocalId.id)
        XCTAssertEqual(FocusQueueTaskMatch.task(for: byLocalId.id, in: [byLocalId, byTodoId])?.title, "Synced",
                       "The queue carries the to-do id whenever there is one")
    }

    func testAnEmptyQueueIdMatchesNothing() {
        XCTAssertNil(FocusQueueTaskMatch.task(for: "", in: [DayPlanTask(title: "Anything")]))
    }

}
