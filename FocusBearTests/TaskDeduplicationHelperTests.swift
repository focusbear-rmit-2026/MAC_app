//
//  TaskDeduplicationHelperTests.swift
//  Focus BearTests
//
//  Tests for TaskDeduplicationHelper (issue #1679).
//  Ensures that AI-suggested tasks are not duplicated when
//  a task with the same name already exists.
//

@testable import Focus_Bear
import XCTest

class TaskDeduplicationHelperTests: XCTestCase {

    // MARK: - Helpers

    private func makeTask(id: String, title: String) -> NSDictionary {
        return ["id": id, "title": title]
    }

    // MARK: - existingTask(named:in:)

    func test_existingTask_returnsNil_whenListIsEmpty() {
        let result = TaskDeduplicationHelper.existingTask(named: "Buy milk", in: [])
        XCTAssertNil(result, "Should return nil for an empty task list")
    }

    func test_existingTask_returnsNil_whenNoMatchFound() {
        let tasks = [makeTask(id: "1", title: "Write report")]
        let result = TaskDeduplicationHelper.existingTask(named: "Buy milk", in: tasks)
        XCTAssertNil(result, "Should return nil when the name does not match any task")
    }

    func test_existingTask_findsExactMatch() {
        let tasks = [makeTask(id: "42", title: "Write report")]
        let result = TaskDeduplicationHelper.existingTask(named: "Write report", in: tasks)
        XCTAssertNotNil(result, "Should find an exact-match task")
        XCTAssertEqual(result?.index, 0)
        XCTAssertEqual(result?.task.value(forKey: "id") as? String, "42")
    }

    func test_existingTask_isCaseInsensitive_suggestedTitleIsLower() {
        let tasks = [makeTask(id: "10", title: "Write Report")]
        // AI often returns lower-case titles; the check must still match.
        let result = TaskDeduplicationHelper.existingTask(named: "write report", in: tasks)
        XCTAssertNotNil(result, "Case-insensitive match should succeed when suggested name is lowercase")
    }

    func test_existingTask_isCaseInsensitive_existingTitleIsLower() {
        let tasks = [makeTask(id: "11", title: "write report")]
        let result = TaskDeduplicationHelper.existingTask(named: "Write Report", in: tasks)
        XCTAssertNotNil(result, "Case-insensitive match should succeed when existing title is lowercase")
    }

    func test_existingTask_isCaseInsensitive_mixedCase() {
        let tasks = [makeTask(id: "12", title: "WRITE REPORT")]
        let result = TaskDeduplicationHelper.existingTask(named: "Write Report", in: tasks)
        XCTAssertNotNil(result, "Case-insensitive match should succeed for mixed-case input")
    }

    func test_existingTask_returnsFirstMatchIndex() {
        let tasks = [
            makeTask(id: "1", title: "Alpha task"),
            makeTask(id: "2", title: "Duplicate Task"),
            makeTask(id: "3", title: "duplicate task"),  // second occurrence (same when lowercased)
        ]
        let result = TaskDeduplicationHelper.existingTask(named: "duplicate task", in: tasks)
        XCTAssertEqual(result?.index, 1, "Should return the first matching index")
        XCTAssertEqual(result?.task.value(forKey: "id") as? String, "2")
    }

    func test_existingTask_doesNotMatchPartialTitle() {
        let tasks = [makeTask(id: "9", title: "Write a report")]
        let result = TaskDeduplicationHelper.existingTask(named: "Write", in: tasks)
        XCTAssertNil(result, "Partial match should not be treated as a duplicate")
    }

    func test_existingTask_handlesWhitespace() {
        // Leading/trailing whitespace must be ignored so a spaced variant is
        // still treated as a duplicate (regression guard for #1679).
        let tasks = [makeTask(id: "5", title: " Write report ")]
        let result = TaskDeduplicationHelper.existingTask(named: "Write report", in: tasks)
        XCTAssertNotNil(result, "Tasks differing only by surrounding whitespace are duplicates")
        XCTAssertEqual(result?.task.value(forKey: "id") as? String, "5")
    }

    /// Regression test for issue #1679:
    /// When the AI suggests a task name that already exists in the todo player,
    /// `existingTask` must find the match so creation is skipped.
    func test_regression_1679_aiSuggestedDuplicateIsFound() {
        let existingTasks = [
            makeTask(id: "100", title: "Review pull requests"),
            makeTask(id: "101", title: "Write unit tests"),
        ]
        // Simulate the AI suggesting exactly the same name as an existing task.
        let aiSuggestedName = "Write unit tests"

        let result = TaskDeduplicationHelper.existingTask(named: aiSuggestedName, in: existingTasks)
        XCTAssertNotNil(result, "#1679: AI-suggested task that already exists should be found, preventing duplication")
        XCTAssertEqual(result?.task.value(forKey: "id") as? String, "101")
    }
}
