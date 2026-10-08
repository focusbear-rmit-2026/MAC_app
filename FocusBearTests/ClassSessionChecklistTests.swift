//
//  ClassSessionChecklistTests.swift
//  Focus BearTests
//
//  Pure-logic tests for the native class-session checklist (ClassSessionChecklist.swift): parsing the
//  join / GET /class-session/current payload into the focus queue, the teacher-order + tick/un-tick
//  rules (first incomplete tickable, latest completed un-tickable, nothing else), and HTML-entity
//  decoding of titles. Mirrors the Windows app's ClassSessionChecklistTests.cs (windows#1611) so the
//  two clients agree. No AppKit or app globals, so these run on the isolated logic-test host.
//

@testable import Focus_Bear
import XCTest

final class ClassSessionChecklistTests: XCTestCase {

    // MARK: - Parsing

    private func payload(tasks: [[String: Any]],
                         version: Int = 1,
                         completed: [String] = []) -> [String: Any] {
        ["tasks": tasks, "tasks_version": version, "completed_task_ids": completed]
    }

    func testParseOrdersByTeacherOrderAndMapsFields() {
        let parsed = ClassSessionChecklistParser.parse(payload(tasks: [
            ["id": "b", "title": "Second", "duration_minutes": 5, "order": 2],
            ["id": "a", "title": "First", "duration_minutes": 10, "order": 1],
            ["id": "c", "title": "Third", "order": 3],
        ], version: 7))
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.version, 7)
        XCTAssertEqual(parsed?.tasks.map { $0.id }, ["a", "b", "c"])
        XCTAssertEqual(parsed?.tasks[0].durationSeconds, 600)
        XCTAssertEqual(parsed?.tasks[1].durationSeconds, 300)
        // No duration_minutes → the queue's default (10 min), never zero.
        XCTAssertEqual(parsed?.tasks[2].durationSeconds, FocusSessionTask.defaultDurationSeconds)
    }

    func testParseMarksCompletedAndActivatesFirstIncomplete() {
        let parsed = ClassSessionChecklistParser.parse(payload(tasks: [
            ["id": "a", "title": "A", "order": 1],
            ["id": "b", "title": "B", "order": 2],
            ["id": "c", "title": "C", "order": 3],
        ], completed: ["a"]))
        XCTAssertEqual(parsed?.tasks[0].status, .completed)
        XCTAssertEqual(parsed?.tasks[1].status, .notStarted)
        // First incomplete (b) is the active task; nothing else is active.
        XCTAssertEqual(parsed?.tasks.filter { $0.isActive }.map { $0.id }, ["b"])
    }

    func testParseAllCompletedHasNoActiveTask() {
        let parsed = ClassSessionChecklistParser.parse(payload(tasks: [
            ["id": "a", "title": "A", "order": 1],
            ["id": "b", "title": "B", "order": 2],
        ], completed: ["a", "b"]))
        XCTAssertEqual(parsed?.tasks.filter { $0.isActive }.count, 0)
    }

    func testParseWithoutOrderKeepsPayloadOrder() {
        let parsed = ClassSessionChecklistParser.parse(payload(tasks: [
            ["id": "x", "title": "X"],
            ["id": "y", "title": "Y"],
        ]))
        XCTAssertEqual(parsed?.tasks.map { $0.id }, ["x", "y"])
    }

    func testParseReturnsNilWhenNoTasksArray() {
        XCTAssertNil(ClassSessionChecklistParser.parse(["tasks_version": 3]))
        XCTAssertNil(ClassSessionChecklistParser.parse([:]))
    }

    func testParseSkipsEntriesWithoutAnId() {
        let parsed = ClassSessionChecklistParser.parse(payload(tasks: [
            ["title": "no id", "order": 1],
            ["id": "a", "title": "A", "order": 2],
        ]))
        XCTAssertEqual(parsed?.tasks.map { $0.id }, ["a"])
    }

    func testParseDecodesHTMLEscapedTitles() {
        let parsed = ClassSessionChecklistParser.parse(payload(tasks: [
            ["id": "a", "title": "Jamie&#39;s &amp; Pat&#39;s task", "order": 1],
        ]))
        XCTAssertEqual(parsed?.tasks.first?.title, "Jamie's & Pat's task")
    }

    // MARK: - Tick / un-tick rules

    private func tasks(_ spec: [(String, FocusSessionTaskStatus)]) -> [FocusSessionTask] {
        var result = spec.map { FocusSessionTask(id: $0.0, title: $0.0, status: $0.1) }
        if let active = result.firstIndex(where: { !$0.status.isCompleted }) {
            result[active].isActive = true
        }
        return result
    }

    func testOnlyFirstIncompleteIsTickable() {
        let q = tasks([("a", .completed), ("b", .notStarted), ("c", .notStarted)])
        XCTAssertEqual(ClassSessionChecklistRules.firstIncompleteId(in: q), "b")
        XCTAssertTrue(ClassSessionChecklistRules.canTick(id: "b", in: q))
        XCTAssertFalse(ClassSessionChecklistRules.canTick(id: "a", in: q))
        XCTAssertFalse(ClassSessionChecklistRules.canTick(id: "c", in: q))
    }

    func testOnlyLatestCompletedIsUntickable() {
        let q = tasks([("a", .completed), ("b", .completed), ("c", .notStarted)])
        XCTAssertEqual(ClassSessionChecklistRules.latestCompletedId(in: q), "b")
        XCTAssertTrue(ClassSessionChecklistRules.canUntick(id: "b", in: q))
        XCTAssertFalse(ClassSessionChecklistRules.canUntick(id: "a", in: q))
        XCTAssertFalse(ClassSessionChecklistRules.canUntick(id: "c", in: q))
    }

    func testTickingAdvancesActiveToNext() {
        let q = tasks([("a", .notStarted), ("b", .notStarted)])
        let after = ClassSessionChecklistRules.ticking(q, id: "a")
        XCTAssertEqual(after.first(where: { $0.id == "a" })?.status, .completed)
        XCTAssertEqual(after.filter { $0.isActive }.map { $0.id }, ["b"])
    }

    func testTickingDisallowedRowIsNoOp() {
        let q = tasks([("a", .notStarted), ("b", .notStarted)])
        XCTAssertEqual(ClassSessionChecklistRules.ticking(q, id: "b"), q)
    }

    func testUntickingReactivatesTheRow() {
        let q = tasks([("a", .completed), ("b", .notStarted)])
        let after = ClassSessionChecklistRules.unticking(q, id: "a")
        XCTAssertEqual(after.first(where: { $0.id == "a" })?.status, .notStarted)
        XCTAssertEqual(after.filter { $0.isActive }.map { $0.id }, ["a"])
    }

    func testUntickingDisallowedRowIsNoOp() {
        let q = tasks([("a", .completed), ("b", .completed), ("c", .notStarted)])
        XCTAssertEqual(ClassSessionChecklistRules.unticking(q, id: "a"), q)
    }

    func testProgressCountsCompleted() {
        let q = tasks([("a", .completed), ("b", .completed), ("c", .notStarted)])
        let progress = ClassSessionChecklistRules.progress(in: q)
        XCTAssertEqual(progress.completed, 2)
        XCTAssertEqual(progress.total, 3)
    }

    // MARK: - HTML unescape

    func testUnescapeHTMLHandlesNamedNumericAndHexEntities() {
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("a&amp;b"), "a&b")
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("&lt;tag&gt;"), "<tag>")
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("quote&quot;s"), "quote\"s")
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("it&#39;s"), "it's")
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("it&#x27;s"), "it's")
    }

    func testUnescapeHTMLLeavesPlainTextAndStrayAmpersands() {
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("plain title"), "plain title")
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("Tom & Jerry"), "Tom & Jerry")
        XCTAssertEqual(ClassSessionChecklistText.unescapeHTML("A&unknown;B"), "A&unknown;B")
    }
}
