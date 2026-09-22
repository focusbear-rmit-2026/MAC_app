//
//  DayPlanProjectRepairTests.swift
//  Focus BearTests
//
//  Unit tests for the pure rules behind the Day Plan project repair pass (DayPlanProjectSyncRules):
//  which tasks need their project pushed to the backend, de-duplicating project names so one project
//  is created per name, the once-per-10-minutes throttle, and the tag list mirrored to the web.
//

@testable import Focus_Bear
import XCTest

final class DayPlanProjectRepairTests: XCTestCase {

    // MARK: - Builders

    private func task(_ title: String = "Task", project: String? = nil, sourceTaskId: String? = "todo-1",
                      projectID: String? = nil, quadrant: Int? = 4,
                      hasSyncedExternalProject: Bool? = nil) -> DayPlanTask {
        DayPlanTask(title: title, sourceTaskId: sourceTaskId, project: project, eisenhowerQuadrant: quadrant,
                    projectID: projectID, hasSyncedExternalProject: hasSyncedExternalProject)
    }

    private let knownProjects: Set<String> = ["proj-thesis", "proj-house"]

    // MARK: - Moving a placement between days (the reschedule sheet's only way to move anything)

    /// The store half of `DayPlanRepositioning`. Applying a reschedule proposal used to write a due
    /// date and nothing else, so the over-committed day kept every task on it
    /// (report 2026-09-17_09-04-13, follow-up).
    func testMovingAPlacedTaskTakesItOffTheOldDayAndDropsItsBlockKey() {
        let previousMockMode = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore(mockTasks: [:])
        let monday = Date(timeIntervalSince1970: 4_000_000_000)
        let tuesday = monday.addingTimeInterval(24 * 3600)
        let before = (monday: store.allTasks(for: monday), tuesday: store.allTasks(for: tuesday))
        defer {
            store.loadMock(before.monday, for: monday)
            store.loadMock(before.tuesday, for: tuesday)
            DayPlanTaskStore.mockMode = previousMockMode
        }
        let placed = DayPlanTask(title: "Review ISO docs", durationMinutes: 15, sourceTaskId: "todo-iso",
                                 blockKey: DayPlanBlockKey.habit(named: "📞 Cold calls"))
        store.loadMock([placed], for: monday)
        store.loadMock([], for: tuesday)

        XCTAssertTrue(store.move(taskID: placed.id, from: monday, to: tuesday))
        XCTAssertTrue(store.allTasks(for: monday).isEmpty, "The day the plan called over-committed is emptier")
        XCTAssertEqual(store.allTasks(for: tuesday).map(\.title), ["Review ISO docs"])
        XCTAssertNil(store.allTasks(for: tuesday).first?.blockKey,
                     "A block key names one occurrence on one day; Monday's cold-calls block is not Tuesday's")
        XCTAssertEqual(store.allTasks(for: tuesday).first?.sourceTaskId, "todo-iso",
                       "It is the same task, not a copy")
        XCTAssertFalse(store.move(taskID: placed.id, from: tuesday, to: tuesday), "A move to the same day is not a move")
        XCTAssertFalse(store.move(taskID: "not-here", from: monday, to: tuesday))
    }

    // MARK: - Completion column resolution

    private func boardColumns(done: Bool = true) -> [ProjectCustomStatus] {
        [ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
         ProjectCustomStatus(id: "doing", label: "In Progress", color: nil, order: 1, should_complete_task: false),
         ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 2, should_complete_task: done)]
    }

    /// Report 2026-09-15_17-41-45 follow-up. Ticking a Day Plan task has to move its card as well as
    /// flip the status, and the store is what joins a task to its project's columns.
    func testDayPlanCompletionResolvesTheProjectsDoneColumn() {
        let store = DayPlanTaskStore.shared
        let previous = store.customStatusesByProject
        defer { store.setCustomStatusesByProject(previous) }
        store.setCustomStatusesByProject(["proj": boardColumns(), "no-done": boardColumns(done: false)])

        var planned = task(project: "Thesis", projectID: "proj")
        planned.customStatusID = "todo"
        XCTAssertEqual(store.columnWrite(for: planned, completed: true), .move(to: "done"))
        XCTAssertEqual(store.columnWrite(for: planned, completed: false), .leaveAlone)

        var finished = planned
        finished.customStatusID = "done"
        XCTAssertEqual(store.columnWrite(for: finished, completed: true), .leaveAlone, "Already filed")
        XCTAssertEqual(store.columnWrite(for: finished, completed: false), .move(to: "todo"))
    }

    /// A task with no project, an unloaded project, or a project without a completing column must be
    /// left exactly as it is — never parked somewhere the server reads as open.
    func testDayPlanCompletionLeavesUnresolvableTasksAlone() {
        let store = DayPlanTaskStore.shared
        let previous = store.customStatusesByProject
        defer { store.setCustomStatusesByProject(previous) }
        store.setCustomStatusesByProject(["proj": boardColumns(), "no-done": boardColumns(done: false)])

        XCTAssertEqual(store.columnWrite(for: task(project: "Local only"), completed: true), .leaveAlone,
                       "No backend project")
        XCTAssertEqual(store.columnWrite(for: task(project: "Thesis", projectID: "never-loaded"), completed: true), .leaveAlone)
        var noDone = task(project: "Chores", projectID: "no-done")
        noDone.customStatusID = "todo"
        XCTAssertEqual(store.columnWrite(for: noDone, completed: true), .leaveAlone,
                       "No completing column: leave it where it is rather than pick a column the server calls open")
    }

    // MARK: - One-off repair of already-completed to-dos

    private func columns(done: Bool = true) -> [ProjectCustomStatus] { boardColumns(done: done) }

    private func repairTask(_ id: String, status: ToDoStatus, column: String?, project: String?) -> ToDoTask {
        ToDoTask(id: id, title: id, details: nil, objective: nil, status: status.rawValue, due_date: nil,
                 created_at: "2026-01-01T00:00:00.000Z", eisenhower_quadrant: 1, outcome: nil,
                 perspiration_level: nil, top_score: nil, duration: nil, icon: nil, tags: [], subtasks: nil,
                 project_id: project, custom_status_id: column)
    }

    /// The one row shape the sweep exists for: the backend says COMPLETED, but the card is parked in
    /// an open column, so every other client still reads it as outstanding.
    func testRepairMovesACompletedTaskOutOfAnOpenColumnIntoTheDoneColumn() {
        let plan = TodoColumnRepairRules.plan(
            tasks: [repairTask("stuck", status: .completed, column: "todo", project: "p")],
            columnsByProject: ["p": columns()])
        XCTAssertEqual(plan.repairs, [.init(taskID: "stuck", projectID: "p", fromColumnID: "todo", toColumnID: "done")])
        XCTAssertTrue(plan.skips.isEmpty)
    }

    /// Completion is read from `status` and never from a column — inferring it the other way is the
    /// bug this whole change removes, and doing it here would complete tasks the user had not.
    func testRepairNeverMovesATaskThatIsNotCompleted() {
        for status in [ToDoStatus.notStarted, .inProgress] {
            let plan = TodoColumnRepairRules.plan(
                tasks: [repairTask("open", status: status, column: "todo", project: "p")],
                columnsByProject: ["p": columns()])
            XCTAssertTrue(plan.repairs.isEmpty, "\(status) must never be re-filed as done")
            XCTAssertEqual(plan.skips, [.init(taskID: "open", reason: .notCompleted)])
        }
    }

    func testRepairLeavesCorrectlyFiledAndUnreasonableRowsAlone() {
        let tasks = [repairTask("already-done", status: .completed, column: "done", project: "p"),
                     repairTask("no-column", status: .completed, column: nil, project: "p"),
                     repairTask("no-project", status: .completed, column: "todo", project: nil),
                     repairTask("unloaded-project", status: .completed, column: "todo", project: "unknown"),
                     repairTask("unknown-column", status: .completed, column: "ghost", project: "p"),
                     repairTask("no-done-column", status: .completed, column: "todo", project: "q")]
        let plan = TodoColumnRepairRules.plan(tasks: tasks,
                                              columnsByProject: ["p": columns(), "q": columns(done: false)])
        XCTAssertTrue(plan.repairs.isEmpty)
        XCTAssertEqual(plan.skips, [.init(taskID: "already-done", reason: .columnAlreadyCompletes),
                                    .init(taskID: "no-column", reason: .noColumn),
                                    .init(taskID: "no-project", reason: .noProject),
                                    .init(taskID: "unloaded-project", reason: .projectNotLoaded),
                                    .init(taskID: "unknown-column", reason: .columnUnknown),
                                    .init(taskID: "no-done-column", reason: .projectHasNoDoneColumn)])
        XCTAssertEqual(TodoColumnRepairRules.summary(plan.skips),
                       "columnAlreadyCompletes=1 columnUnknown=1 noColumn=1 noProject=1 projectHasNoDoneColumn=1 projectNotLoaded=1")
    }

    /// Idempotence, proved the way it actually happens: apply the plan, feed the result back in, and
    /// the second pass must want to write nothing.
    func testRepairRunTwiceOverItsOwnOutputPlansNoFurtherWrites() {
        let columnsByProject = ["p": columns()]
        var rows = [repairTask("a", status: .completed, column: "todo", project: "p"),
                    repairTask("b", status: .completed, column: "doing", project: "p"),
                    repairTask("c", status: .completed, column: "done", project: "p"),
                    repairTask("d", status: .notStarted, column: "todo", project: "p")]
        let first = TodoColumnRepairRules.plan(tasks: rows, columnsByProject: columnsByProject)
        XCTAssertEqual(first.repairs.map(\.taskID), ["a", "b"])
        // Apply exactly what the sweep would have PUT.
        for repair in first.repairs {
            guard let index = rows.firstIndex(where: { $0.id == repair.taskID }) else { continue }
            rows[index].custom_status_id = repair.toColumnID
        }
        let second = TodoColumnRepairRules.plan(tasks: rows, columnsByProject: columnsByProject)
        XCTAssertTrue(second.repairs.isEmpty, "A repaired row must never be rewritten")
        XCTAssertEqual(second.skips.count, rows.count)
    }

    /// A `custom_status_id` the response OMITS and one it returns as null are identical once
    /// decoded. The first pass of this sweep reported `noColumn=500`, zero repairs and stored its
    /// marker on an account with 47 rows to fix, so the two have to be told apart at the JSON level
    /// before a pass is allowed to call itself complete.
    func testAMissingColumnFieldIsCountedApartFromANullOne() throws {
        func payload(_ rows: String) -> Data { Data("{\"data\":[\(rows)],\"meta\":{\"page\":1}}".utf8) }
        let row = #"{"id":"%@","title":"%@","status":"COMPLETED","created_at":"2026-01-01T00:00:00.000Z""#
        let present = payload(String(format: row, "a", "A") + #","custom_status_id":"todo"}"#
                              + "," + String(format: row, "b", "B") + #","custom_status_id":null}"#)
        XCTAssertEqual(TodoColumnRepair.rowsCarryingColumnField(in: present), 2,
                       "An explicit null still proves the server sends the field")
        let absent = payload(String(format: row, "a", "A") + "}," + String(format: row, "b", "B") + "}")
        XCTAssertEqual(TodoColumnRepair.rowsCarryingColumnField(in: absent), 0,
                       "No field at all: the pass is blind and must not record success")
        XCTAssertEqual(TodoColumnRepair.rowsCarryingColumnField(in: payload("")), 0)
        XCTAssertEqual(TodoColumnRepair.rowsCarryingColumnField(in: Data("not json".utf8)), 0)
        // Both rows still decode with a nil column, which is exactly why the count above is needed.
        let decoded = try JSONDecoder().decode(ToDoPage.self, from: absent)
        XCTAssertEqual(decoded.data.count, 2)
        XCTAssertTrue(decoded.data.allSatisfy { $0.custom_status_id == nil })
    }

    // MARK: - Selector: which tasks need repair

    func testLocalOnlyProjectNeedsRepair() {
        XCTAssertTrue(DayPlanProjectSyncRules.needsRepair(task(project: "Thesis"), remoteProjectIDs: knownProjects))
    }

    func testTaskLinkedToKnownProjectDoesNotNeedRepair() {
        let linked = task(project: "Thesis", projectID: "proj-thesis")
        XCTAssertFalse(DayPlanProjectSyncRules.needsRepair(linked, remoteProjectIDs: knownProjects))
    }

    func testTaskLinkedToProjectMissingFromRemoteListNeedsRepair() {
        let stale = task(project: "Thesis", projectID: "proj-deleted")
        XCTAssertTrue(DayPlanProjectSyncRules.needsRepair(stale, remoteProjectIDs: knownProjects))
    }

    func testTaskWithoutProjectDoesNotNeedRepair() {
        XCTAssertFalse(DayPlanProjectSyncRules.needsRepair(task(project: nil), remoteProjectIDs: knownProjects))
        XCTAssertFalse(DayPlanProjectSyncRules.needsRepair(task(project: "   "), remoteProjectIDs: knownProjects))
    }

    func testPureLocalTaskWithoutTodoIsOutOfScope() {
        let unminted = task(project: "Thesis", sourceTaskId: nil)
        XCTAssertFalse(DayPlanProjectSyncRules.needsRepair(unminted, remoteProjectIDs: knownProjects))
    }

    func testExternallySyncedTodoIsLeftToTheIntegration() {
        let clickUp = task(project: "ClickUp List", hasSyncedExternalProject: true)
        XCTAssertFalse(DayPlanProjectSyncRules.needsRepair(clickUp, remoteProjectIDs: knownProjects))
    }

    func testCandidatesScanEveryDayInDateOrder() {
        let byDay: [String: [DayPlanTask]] = [
            "2026-09-08": [task("today linked", project: "House", projectID: "proj-house"),
                           task("today local", project: "Thesis")],
            "2026-08-30": [task("old local", project: "Garden"), task("old no project")],
            "2026-09-10": [task("future local", project: "thesis")],
        ]
        let found = DayPlanProjectSyncRules.candidates(in: byDay, remoteProjectIDs: knownProjects)
        XCTAssertEqual(found.map { $0.task.title }, ["old local", "today local", "future local"])
        XCTAssertEqual(found.map { $0.dayKey }, ["2026-08-30", "2026-09-08", "2026-09-10"])
    }

    func testSplitSeparatesTasksThatCannotBeLinkedYet() {
        let byDay = ["2026-09-08": [task("has quadrant", project: "Thesis"),
                                    task("imported before quadrant", project: "Thesis", quadrant: nil)]]
        let (linkable, missingQuadrant) = DayPlanProjectSyncRules.split(
            DayPlanProjectSyncRules.candidates(in: byDay, remoteProjectIDs: []))
        XCTAssertEqual(linkable.map { $0.task.title }, ["has quadrant"])
        XCTAssertEqual(missingQuadrant.map { $0.task.title }, ["imported before quadrant"])
    }

    // MARK: - Dedupe by project name

    func testTenTasksWithTheSameProjectYieldOneName() {
        let tasks = (1...10).map { task("t\($0)", project: $0 % 2 == 0 ? "thesis" : "Thesis") }
        let names = DayPlanProjectSyncRules.distinctProjectNames(
            DayPlanProjectSyncRules.candidates(in: ["2026-09-08": tasks], remoteProjectIDs: []))
        XCTAssertEqual(names, ["Thesis"])   // first-seen casing wins
    }

    func testDistinctNamesKeepFirstSeenOrderAndTrimWhitespace() {
        let tasks = [task(project: " House "), task(project: "Thesis"), task(project: "house")]
        let names = DayPlanProjectSyncRules.distinctProjectNames(
            DayPlanProjectSyncRules.candidates(in: ["2026-09-08": tasks], remoteProjectIDs: []))
        XCTAssertEqual(names, ["House", "Thesis"])
    }

    // MARK: - Throttling

    func testFirstEverPassIsDue() {
        XCTAssertTrue(DayPlanProjectSyncRules.isDue(now: Date(), lastRun: nil))
    }

    func testPassWithinTenMinutesIsNotDue() {
        let now = Date()
        XCTAssertFalse(DayPlanProjectSyncRules.isDue(now: now, lastRun: now.addingTimeInterval(-9 * 60)))
        XCTAssertFalse(DayPlanProjectSyncRules.isDue(now: now, lastRun: now))
    }

    func testPassAfterTenMinutesIsDue() {
        let now = Date()
        XCTAssertTrue(DayPlanProjectSyncRules.isDue(now: now, lastRun: now.addingTimeInterval(-10 * 60)))
        XCTAssertTrue(DayPlanProjectSyncRules.isDue(now: now, lastRun: now.addingTimeInterval(-3 * 60 * 60)))
    }

    func testMinimumIntervalIsTenMinutes() {
        XCTAssertEqual(DayPlanProjectSyncRules.minimumInterval, 600)
    }

    // MARK: - Tag mirroring (web `ensureProjectTaskTags`)

    func testEnsureProjectTagAppendsExactlyOneProjectTagAfterLabels() {
        let labels = [DayPlanTaskTag(id: "tag-urgent", text: "urgent"),
                      DayPlanTaskTag(id: "proj-thesis", text: "Old name")]
        let tags = DayPlanProjectSyncRules.ensureProjectTag(labels, projectID: "proj-thesis", projectName: "Thesis")
        XCTAssertEqual(tags, [DayPlanTaskTag(id: "tag-urgent", text: "urgent"),
                              DayPlanTaskTag(id: "proj-thesis", text: "Thesis")])
    }

    func testEnsureProjectTagWithoutProjectKeepsLabelsUntouched() {
        let labels = [DayPlanTaskTag(id: "tag-urgent", text: "urgent")]
        XCTAssertEqual(DayPlanProjectSyncRules.ensureProjectTag(labels, projectID: nil, projectName: nil), labels)
    }
}

/// Merging a duplicate project archived the source, and the Day Plan kept naming it. Because
/// `GET /projects` hides archived projects, the next sync could not find the name and created the
/// project again — so the user merged "Classroom mode" three times and collected three archived
/// copies of it (report 2026-09-18_21-46-48).
final class DayPlanProjectMergeFollowTests: XCTestCase {
    private func task(_ title: String, project: String?, projectID: String? = nil,
                      tags: [DayPlanTaskTag]? = nil, hasSyncedExternalProject: Bool? = nil) -> DayPlanTask {
        DayPlanTask(title: title, sourceTaskId: "todo-" + title, project: project,
                    eisenhowerQuadrant: 4, projectID: projectID, tags: tags,
                    hasSyncedExternalProject: hasSyncedExternalProject)
    }

    func testTasksNamingTheMergedAwayProjectFollowItToTheTarget() {
        let before = ["2026-09-18": [task("A", project: "Classroom mode", projectID: "old-id"),
                                     task("B", project: "Unrelated", projectID: "other-id")]]
        let after = DayPlanProjectSyncRules.followingMerge(before, from: "Classroom mode",
                                                           to: "classroom-mode", targetID: "new-id")
        XCTAssertEqual(after["2026-09-18"]?[0].project, "classroom-mode")
        XCTAssertEqual(after["2026-09-18"]?[0].projectID, "new-id")
        XCTAssertEqual(after["2026-09-18"]?[1].project, "Unrelated", "An unrelated project is untouched")
        XCTAssertEqual(after["2026-09-18"]?[1].projectID, "other-id")
    }

    /// The name lookup that would recreate the project compares case-insensitively, so this must too,
    /// or the very casing difference that made the duplicate survives the merge that removed it.
    func testMatchingIgnoresCaseAndSurroundingSpace() {
        let before = ["d": [task("A", project: "  CLASSROOM MODE ")]]
        let after = DayPlanProjectSyncRules.followingMerge(before, from: "classroom mode",
                                                           to: "classroom-mode", targetID: "new-id")
        XCTAssertEqual(after["d"]?[0].project, "classroom-mode")
    }

    func testAnExternallySyncedProjectIsLeftWhereTheMergeLeftIt() {
        let before = ["d": [task("A", project: "Classroom mode", projectID: "old-id",
                                 hasSyncedExternalProject: true)]]
        let after = DayPlanProjectSyncRules.followingMerge(before, from: "Classroom mode",
                                                           to: "classroom-mode", targetID: "new-id")
        XCTAssertEqual(after["d"]?[0].project, "Classroom mode")
        XCTAssertEqual(after["d"]?[0].projectID, "old-id")
    }

    func testMergingAProjectIntoItselfChangesNothing() {
        let before = ["d": [task("A", project: "Classroom mode", projectID: "id")]]
        XCTAssertEqual(DayPlanProjectSyncRules.followingMerge(before, from: "Classroom mode",
                                                              to: "classroom mode", targetID: "id"), before)
        XCTAssertEqual(DayPlanProjectSyncRules.followingMerge(before, from: "   ",
                                                              to: "classroom-mode", targetID: "id"), before)
    }

    func testTheProjectTagFollowsSoTheWebSeesTheSameProject() {
        let tags = [DayPlanTaskTag(id: "old-id", text: "Classroom mode"),
                    DayPlanTaskTag(id: "label-1", text: "urgent")]
        let after = DayPlanProjectSyncRules.followingMerge(["d": [task("A", project: "Classroom mode",
                                                                      projectID: "old-id", tags: tags)]],
                                                           from: "Classroom mode", to: "classroom-mode",
                                                           targetID: "new-id")
        let moved = try? XCTUnwrap(after["d"]?[0].tags)
        XCTAssertEqual(moved?.first { $0.id == "new-id" }?.text, "classroom-mode")
        XCTAssertNil(moved?.first { $0.id == "old-id" }, "The retired project must not stay on the task")
        XCTAssertNotNil(moved?.first { $0.id == "label-1" }, "Ordinary labels survive")
    }
}
