//
//  ProjectKanbanDragTests.swift
//  Focus BearTests
//
//  The pure rules behind dragging a task card between a project's kanban columns: which column the
//  pointer is over (ProjectBoardDrag), what a drop writes — including whether it completes or
//  reopens the task (ProjectTaskMove.plan) — and what the board keeps once the server answers
//  (ProjectTaskMove.settled). Report 2026-09-15_20-13-04.
//

@testable import Focus_Bear
import XCTest

final class ProjectKanbanDragTests: XCTestCase {

    // MARK: - Builders

    private let statuses = [
        ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
        ProjectCustomStatus(id: "doing", label: "In Progress", color: nil, order: 1, should_complete_task: false),
        ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 2, should_complete_task: true),
    ]

    private func project(members: [(String, ProjectMemberRole)] = [("owner-1", .owner)],
                         usesCustomStatuses: Bool = true) -> Project {
        Project(id: "p", name: "Project", description: nil, owner_id: "owner-1",
                custom_statuses: usesCustomStatuses ? statuses : [], icon: nil,
                members: members.map { ProjectMember(id: "m-\($0.0)", user_id: $0.0, email: "\($0.0)@x.io",
                                                     role: $0.1.rawValue, invitation_status: "accepted") },
                task_count: nil, uncompleted_task_count: nil, synced_project_id: nil, due_date: nil,
                importance: nil, status: nil, created_at: nil, updated_at: nil)
    }

    private func columns(of project: Project) -> [ProjectColumn] {
        ProjectKanban.columns(for: project, defaultLabels: [.notStarted: "To Do", .inProgress: "In Progress", .completed: "Done"])
    }

    private func task(status: ToDoStatus = .notStarted, column: String? = "todo") -> ToDoTask {
        ToDoTask(id: "t-1", title: "Review full stack agreement", details: nil, objective: nil, status: status.rawValue,
                 due_date: nil, created_at: "2026-09-15T00:00:00.000Z", eisenhower_quadrant: 1, outcome: nil,
                 perspiration_level: nil, top_score: nil, duration: nil, icon: nil, tags: [], subtasks: nil,
                 project_id: "p", custom_status_id: column)
    }

    private func plan(_ task: ToDoTask, to columnId: String, project: Project, canMove: Bool = true) -> ToDoTask? {
        ProjectTaskMove.plan(task, toColumn: columnId, project: project, columns: columns(of: project), canMove: canMove)
    }

    // MARK: - Which column is under the pointer

    private let frames: [String: CGRect] = [
        "todo": CGRect(x: 0, y: 0, width: 240, height: 400),
        "doing": CGRect(x: 250, y: 0, width: 240, height: 400),
        "done": CGRect(x: 500, y: 0, width: 240, height: 400),
    ]

    func testPointerOverAColumnNamesThatColumn() {
        XCTAssertEqual(ProjectBoardDrag.columnId(at: CGPoint(x: 300, y: 120), frames: frames), "doing")
        XCTAssertEqual(ProjectBoardDrag.columnId(at: CGPoint(x: 600, y: 10), frames: frames), "done")
    }

    func testPointerBetweenOrOutsideColumnsNamesNone() {
        XCTAssertNil(ProjectBoardDrag.columnId(at: CGPoint(x: 245, y: 120), frames: frames))
        XCTAssertNil(ProjectBoardDrag.columnId(at: CGPoint(x: 300, y: 900), frames: frames))
    }

    func testOverlappingFramesResolveToTheSmallestColumn() {
        let nested: [String: CGRect] = ["outer": CGRect(x: 0, y: 0, width: 500, height: 500),
                                        "inner": CGRect(x: 100, y: 100, width: 100, height: 100)]
        XCTAssertEqual(ProjectBoardDrag.columnId(at: CGPoint(x: 150, y: 150), frames: nested), "inner")
        XCTAssertEqual(ProjectBoardDrag.columnId(at: CGPoint(x: 400, y: 400), frames: nested), "outer")
    }

    // MARK: - What a drop writes

    func testDropOnACompletingColumnCompletesTheTask() {
        let moved = plan(task(), to: "done", project: project())
        XCTAssertEqual(moved?.custom_status_id, "done")
        XCTAssertEqual(moved?.status, ToDoStatus.completed.rawValue)
        XCTAssertTrue(ToDoCompletionState.isFinished(moved!, customStatuses: statuses))
    }

    func testDropOnANonCompletingColumnLeavesTheTaskIncomplete() {
        let moved = plan(task(), to: "doing", project: project())
        XCTAssertEqual(moved?.custom_status_id, "doing")
        XCTAssertEqual(moved?.status, ToDoStatus.inProgress.rawValue)
        XCTAssertFalse(ToDoCompletionState.isFinished(moved!, customStatuses: statuses))
    }

    /// The mirror of `ToDoStatusToggle.apply`: a task completed elsewhere must not stay completed in
    /// a column that does not complete, which is the inconsistency the board is meant to end.
    func testDraggingACompletedTaskBackToAnOpenColumnReopensIt() {
        let finished = task(status: .completed, column: "done")
        let moved = plan(finished, to: "todo", project: project())
        XCTAssertEqual(moved?.custom_status_id, "todo")
        XCTAssertEqual(moved?.status, ToDoStatus.notStarted.rawValue)
        XCTAssertFalse(ToDoCompletionState.isFinished(moved!, customStatuses: statuses))
    }

    func testDropOnItsOwnColumnWritesNothing() {
        XCTAssertNil(plan(task(), to: "todo", project: project()))
    }

    /// Ticked off from the Day Plan, so the row says COMPLETED while its column still says To Do:
    /// the board already draws it under Done, and dropping it on Done must stay a no-op.
    func testDropOnTheColumnTheCardIsAlreadyDrawnInWritesNothing() {
        let completedElsewhere = task(status: .completed, column: "todo")
        XCTAssertNil(plan(completedElsewhere, to: "done", project: project()))
    }

    func testDropOnAColumnThatIsNotOnThisBoardWritesNothing() {
        XCTAssertNil(plan(task(), to: "some-other-projects-column", project: project()))
    }

    func testDropRelinksTheTaskToTheProjectAndItsTag() {
        let moved = plan(task(), to: "doing", project: project())
        XCTAssertEqual(moved?.project_id, "p")
        XCTAssertEqual(moved?.tagList.map(\.id), ["p"])
    }

    /// Without custom statuses the columns are the default statuses themselves.
    func testDropOnADefaultColumnSetsTheStatusItself() {
        let plain = project(usesCustomStatuses: false)
        let moved = ProjectTaskMove.plan(task(column: nil), toColumn: ToDoStatus.completed.rawValue,
                                         project: plain, columns: columns(of: plain), canMove: true)
        XCTAssertEqual(moved?.status, ToDoStatus.completed.rawValue)
        XCTAssertNil(moved?.custom_status_id)
    }

    // MARK: - Permission

    func testAViewerWhoIsNotAMemberCannotMoveACard() {
        let role = ProjectPermissions.viewerRole(in: project(), userId: "someone-else")
        XCTAssertNil(role)
        XCTAssertFalse(ProjectPermissions.canMoveTask(role))
        XCTAssertNil(plan(task(), to: "done", project: project(), canMove: ProjectPermissions.canMoveTask(role)))
    }

    func testEveryMemberOfTheProjectCanMoveACard() {
        for role in ProjectMemberRole.allCases {
            XCTAssertTrue(ProjectPermissions.canMoveTask(role), "\(role) should be able to move a card")
        }
    }

    // MARK: - Optimistic write, and putting the card back

    func testAcceptedWriteKeepsWhatTheServerStored() {
        let previous = task(), attempted = plan(previous, to: "done", project: project())!
        var stored = attempted
        stored.title = "Renamed on the server"
        let outcome = ProjectTaskMove.settled(statusCode: 200, saved: stored, attempted: attempted, previous: previous)
        XCTAssertFalse(outcome.failed)
        XCTAssertEqual(outcome.task.title, "Renamed on the server")
    }

    func testAcceptedWriteWithNoBodyKeepsTheMovedCard() {
        let previous = task(), attempted = plan(previous, to: "done", project: project())!
        let outcome = ProjectTaskMove.settled(statusCode: 204, saved: nil, attempted: attempted, previous: previous)
        XCTAssertFalse(outcome.failed)
        XCTAssertEqual(outcome.task.custom_status_id, "done")
    }

    func testRejectedWriteRestoresTheOriginalColumn() {
        let previous = task(), attempted = plan(previous, to: "done", project: project())!
        let outcome = ProjectTaskMove.settled(statusCode: 500, saved: nil, attempted: attempted, previous: previous)
        XCTAssertTrue(outcome.failed, "a rejected move must be reported, not swallowed")
        XCTAssertEqual(outcome.task.custom_status_id, "todo")
        XCTAssertEqual(outcome.task.status, ToDoStatus.notStarted.rawValue)
    }
}
