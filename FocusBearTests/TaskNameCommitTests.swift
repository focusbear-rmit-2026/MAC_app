//
//  TaskNameCommitTests.swift
//  Focus BearTests
//
//  The rule both task composers commit a typed name by. The case worth protecting is
//  `refuseTokensOnly`: typing only a `#project` (or only a `!priority`, or only a duration) used to
//  be committed as a rename to the empty string, which blanked the title, pushed that blank title
//  onto the backing to-do, and left a nameless from-scratch row for the store's `cleanup()` to
//  prune — so the row and the typing were gone with nothing to recover. Report 2026-09-09_20-38-22.
//

import XCTest
import Cocoa
@testable import Focus_Bear

final class TaskNameCommitTests: XCTestCase {

    @MainActor
    func testPlannedTaskTotalRemainsVisibleWhenItsTimeFitsInsideAHabitBlock() {
        let previousMock = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore.shared
        let day = Calendar.current.date(from: DateComponents(year: 2060, month: 9, day: 20))!
        let previousTasks = store.allTasks(for: day)
        store.loadMock([DayPlanTask(title: "Check password issue", durationMinutes: 5)], for: day)
        defer {
            store.loadMock(previousTasks, for: day)
            DayPlanTaskStore.mockMode = previousMock
        }
        let panel = DayPlanTasksPanel(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        panel.date = day
        panel.scheduleFreeMinutes = 10
        func labels(in view: NSView) -> [NSTextField] {
            (view as? NSTextField).map { [$0] } ?? view.subviews.flatMap { labels(in: $0) }
        }
        for (absorbed, buffer) in [(5.0, 10.0), (2.0, 7.0), (0.0, 5.0)] {
            panel.forecastAbsorbedMinutes = absorbed
            let planned = ForecastText.format(.plannedTotal, ["<DURATION>": ForecastText.duration(5)])
            let slack = ForecastText.format(.bufferTotal, ["<BUFFER>": ForecastText.signedDuration(buffer)])
            XCTAssertTrue(labels(in: panel).contains { !$0.isHidden && $0.stringValue == planned + " · " + slack },
                "All five minutes must remain visible while the buffer accounts for absorbed work")
        }
    }

    @MainActor
    func testProjectTabRegroupsDraftAndRestoresItsEmptyNameEditor() {
        verifyProjectCompletion(command: #selector(NSResponder.insertTab(_:)))
    }

    @MainActor
    func testProjectReturnRegroupsDraftAndKeepsTypingFocus() {
        verifyProjectCompletion(command: #selector(NSResponder.insertNewline(_:)))
    }

    @MainActor
    private func verifyProjectCompletion(command: Selector) {
        let previousMock = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore.shared
        let day = Calendar.current.date(from: DateComponents(year: 2060, month: 9, day: 18))!
        let previousTasks = store.allTasks(for: day)
        let project = "Codex Autocomplete Regression"
        let existing = DayPlanTask(title: "Existing project task", project: project)
        let draft = DayPlanTask(title: "#Codex Autocomplete")
        store.loadMock([existing, draft], for: day)
        let panel = DayPlanTasksPanel(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        let window = NSWindow(contentRect: panel.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = panel
        panel.date = day
        defer {
            window.makeFirstResponder(nil)
            window.close()
            store.loadMock(previousTasks, for: day)
            DayPlanTaskStore.mockMode = previousMock
        }
        func nameField(in view: NSView) -> NSTextField? {
            if let field = view as? NSTextField, field.identifier?.rawValue == "name:" + draft.id { return field }
            return view.subviews.lazy.compactMap { nameField(in: $0) }.first
        }
        guard let original = nameField(in: panel) else { return XCTFail("Draft row missing") }
        XCTAssertTrue(window.makeFirstResponder(original))
        guard let editor = original.currentEditor() as? NSTextView else { return XCTFail("Name editor missing") }
        editor.string = "#Codex Autocomplete"
        editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
        original.stringValue = editor.string
        panel.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: original, userInfo: ["NSFieldEditor": editor]))
        XCTAssertTrue(panel.control(original, textView: editor, doCommandBy: command))
        let restored = expectation(description: "Project row is rebuilt and typing resumes")
        DispatchQueue.main.async {
            guard let replacement = nameField(in: panel) else { XCTFail("Regrouped draft missing"); restored.fulfill(); return }
            XCTAssertFalse(replacement === original, "Autocomplete must regroup into the existing project now")
            XCTAssertEqual(replacement.stringValue, "")
            XCTAssertEqual(replacement.placeholderString, "#" + project)
            XCTAssertTrue(replacement.currentEditor() === window.firstResponder)
            XCTAssertNotNil(replacement.currentEditor())
            panel.reload() // A refresh arriving before the first keystroke must not take focus back.
            XCTAssertTrue(nameField(in: panel) === replacement)
            XCTAssertTrue(replacement.currentEditor() === window.firstResponder)
            XCTAssertNotNil(replacement.currentEditor())
            XCTAssertEqual(store.allTasks(for: day).first(where: { $0.id == draft.id })?.project, project)
            restored.fulfill()
        }
        wait(for: [restored], timeout: 3)
    }

    @MainActor
    func testSnoozeEndsEditingAndRemovesTheMovedRowFromTheCurrentDay() {
        let previousMock = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore.shared
        let friday = Calendar.current.date(from: DateComponents(year: 2060, month: 9, day: 17))!
        let monday = Calendar.current.date(byAdding: .day, value: 3, to: friday)!
        let before = (store.allTasks(for: friday), store.allTasks(for: monday))
        let task = DayPlanTask(title: "Move this task")
        store.loadMock([task], for: friday)
        store.loadMock([], for: monday)
        let panel = DayPlanTasksPanel(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        let window = NSWindow(contentRect: panel.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = panel
        panel.date = friday
        defer {
            window.makeFirstResponder(nil)
            window.close()
            store.loadMock(before.0, for: friday)
            store.loadMock(before.1, for: monday)
            DayPlanTaskStore.mockMode = previousMock
        }
        func nameField(in view: NSView) -> NSTextField? {
            if let field = view as? NSTextField, field.identifier?.rawValue == "name:" + task.id { return field }
            return view.subviews.lazy.compactMap { nameField(in: $0) }.first
        }
        guard let field = nameField(in: panel) else { return XCTFail("Task row missing") }
        XCTAssertTrue(window.makeFirstResponder(field))
        XCTAssertNotNil(field.currentEditor())
        panel.snoozeTasks([task.id: monday])
        panel.reload()
        XCTAssertFalse(store.allTasks(for: friday).contains { $0.id == task.id })
        XCTAssertTrue(store.allTasks(for: monday).contains { $0.id == task.id })
        XCTAssertNil(nameField(in: panel), "Snoozed row must disappear immediately, even while it had keyboard focus")
    }

    private let known = ["Focus Bear", "class"]

    private func savedTask(_ commit: TaskNameCommit,
                           file: StaticString = #filePath, line: UInt = #line) -> ParsedQuickAddTask? {
        guard case .save(let parsed) = commit else {
            XCTFail("expected .save, got \(commit)", file: file, line: line)
            return nil
        }
        return parsed
    }

    // MARK: A name made only of tokens is refused

    func testAcceptedLeadingProjectKeepsAnEmptyNameAsAnUnfinishedTask() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("", knownProjects: ["Focus Bear"], pendingProject: "Focus Bear"),
                       .refuseTokensOnly)
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("   ", knownProjects: ["Focus Bear"], pendingProject: "Focus Bear"),
                       .refuseTokensOnly)
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("", knownProjects: ["Focus Bear"]), .discard)
        let result = TaskNameCommit.forDayPlanRow("Write report", knownProjects: ["Focus Bear"], pendingProject: "Focus Bear")
        guard case .save(let parsed) = result else { return XCTFail("Typing a name must finish the draft") }
        XCTAssertEqual(parsed.title, "Write report")
    }

    func testBareProjectTokenIsRefused() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("#class", knownProjects: known), .refuseTokensOnly)
    }

    func testBareUnknownProjectTokenIsRefused() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("#gardening", knownProjects: known), .refuseTokensOnly)
    }

    func testBareMultiWordProjectTokenIsRefused() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("#Focus Bear", knownProjects: known), .refuseTokensOnly)
    }

    func testBarePriorityTokenIsRefused() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("!3", knownProjects: known), .refuseTokensOnly)
    }

    /// `*N` is a DURATION since 2026-09-21 (report 2026-09-21_07-42-02), and a duration on its own
    /// still leaves nothing to call the task.
    func testBareMinutesTokenIsRefused() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("*15", knownProjects: known), .refuseTokensOnly)
    }

    func testSeveralTokensAndNothingElseAreRefused() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("!3 #class", knownProjects: known), .refuseTokensOnly)
        XCTAssertEqual(TaskNameCommit.forQuickAdd("30m !3 #class", knownProjects: known), .refuseTokensOnly)
    }

    func testSurroundingWhitespaceDoesNotRescueATokenOnlyName() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("   #class   ", knownProjects: known), .refuseTokensOnly)
    }

    // MARK: Duration — a token in the quick-add grammar, plain text on a Day Plan row

    func testBareDurationTokenIsRefusedInQuickAdd() {
        XCTAssertEqual(TaskNameCommit.forQuickAdd("30m", knownProjects: known), .refuseTokensOnly)
        XCTAssertEqual(TaskNameCommit.forQuickAdd("1h30", knownProjects: known), .refuseTokensOnly)
    }

    /// The Day Plan row keeps duration in its own field, so "30m" typed into the NAME is a name.
    func testBareDurationTokenIsANameOnADayPlanRow() {
        let parsed = savedTask(TaskNameCommit.forDayPlanRow("30m", knownProjects: known))
        XCTAssertEqual(parsed?.title, "30m")
        XCTAssertNil(parsed?.durationMinutes)
    }

    // MARK: A token plus a real title still saves, with the token stripped

    func testProjectTokenWithTitleSaves() {
        let parsed = savedTask(TaskNameCommit.forDayPlanRow("draft the brief #Focus Bear", knownProjects: known))
        XCTAssertEqual(parsed?.title, "draft the brief")
        XCTAssertEqual(parsed?.project, "Focus Bear")
    }

    func testProjectTokenReusesTheKnownProjectCasing() {
        let parsed = savedTask(TaskNameCommit.forDayPlanRow("read chapter 4 #focus bear", knownProjects: known))
        XCTAssertEqual(parsed?.project, "Focus Bear")
    }

    func testPriorityTokenWithTitleSaves() {
        let parsed = savedTask(TaskNameCommit.forDayPlanRow("draft report !3", knownProjects: known))
        XCTAssertEqual(parsed?.title, "draft report")
        XCTAssertNotNil(parsed?.outcome)
    }

    /// The same row now also takes an explicit duration, which it did not before 2026-09-21.
    func testStarDurationWithTitleSavesOnTheRow() {
        let parsed = savedTask(TaskNameCommit.forDayPlanRow("draft report *25", knownProjects: known))
        XCTAssertEqual(parsed?.title, "draft report")
        XCTAssertEqual(parsed?.durationMinutes, 25)
        XCTAssertNil(parsed?.outcome, "a star is a duration now, not a priority")
    }

    func testEveryTokenWithTitleSavesInQuickAdd() {
        let parsed = savedTask(TaskNameCommit.forQuickAdd("write the essay #class !3 45m", knownProjects: known))
        XCTAssertEqual(parsed?.title, "write the essay")
        XCTAssertEqual(parsed?.project, "class")
        XCTAssertEqual(parsed?.durationMinutes, 45)
        XCTAssertNotNil(parsed?.outcome)
    }

    func testPlainTitleSaves() {
        let parsed = savedTask(TaskNameCommit.forDayPlanRow("tidy the inbox", knownProjects: known))
        XCTAssertEqual(parsed?.title, "tidy the inbox")
        XCTAssertNil(parsed?.project)
        XCTAssertNil(parsed?.outcome)
    }

    /// A lone `#` isn't a project token, so it is just an odd little name — not a refusal.
    func testStrayHashIsATitle() {
        let parsed = savedTask(TaskNameCommit.forDayPlanRow("#", knownProjects: known))
        XCTAssertEqual(parsed?.title, "#")
        XCTAssertNil(parsed?.project)
    }

    // MARK: A genuinely empty name still discards, exactly as before

    func testEmptyStringDiscards() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("", knownProjects: known), .discard)
        XCTAssertEqual(TaskNameCommit.forQuickAdd("", knownProjects: known), .discard)
    }

    func testWhitespaceOnlyDiscards() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("   \n  ", knownProjects: known), .discard)
    }

    // MARK: The row composer carries the duration too (report 2026-09-21_20-39-15)
    //
    // "! and * were ignored when I created a new task". The parser was never the problem — it
    // stripped both tokens correctly. `*N` was then dropped on the floor by the caller, and the row
    // kept showing the raw text, so BOTH tokens looked ignored when only one was.

    func testTheReportedLineParsesEveryToken() {
        guard case .save(let parsed) = TaskNameCommit.forDayPlanRow("Denzel attend MCP meeting !5 *2",
                                                                    knownProjects: ["HR"]) else {
            return XCTFail("a line with a real name must save")
        }
        XCTAssertEqual(parsed.title, "Denzel attend MCP meeting", "both tokens stripped from the name")
        XCTAssertEqual(parsed.durationMinutes, 2, "*2 is two minutes — this was the value being discarded")
        XCTAssertEqual(parsed.outcome, 10, "!5 on the /10 wire scale")
    }

    func testTheStarTokenSurvivesWhateverElseIsOnTheLine() {
        for (line, minutes) in [("write the spec *45", 45),
                                ("write the spec *45 !3", 45),
                                ("*90 write the spec", 90),
                                ("write the spec #HR *5", 5)] {
            guard case .save(let parsed) = TaskNameCommit.forDayPlanRow(line, knownProjects: ["HR"]) else {
                return XCTFail("\(line) should save")
            }
            XCTAssertEqual(parsed.durationMinutes, minutes, line)
        }
    }

    func testALineWithNoStarTokenLeavesTheDurationToTheCaller() {
        guard case .save(let parsed) = TaskNameCommit.forDayPlanRow("write the spec !2",
                                                                    knownProjects: []) else {
            return XCTFail("should save")
        }
        XCTAssertNil(parsed.durationMinutes,
                     "nil, not a default — the row applies its own, and a default here would " +
                     "overwrite a duration the user set in the field")
    }

    /// A bare "30m" stays in the NAME on a row, because the row has its own duration field. Only the
    /// unambiguous `*30` is a duration here. Pinned so the two composers do not quietly converge.
    func testASpelledDurationIsStillPartOfTheNameOnARow() {
        guard case .save(let parsed) = TaskNameCommit.forDayPlanRow("run 30m sprint", knownProjects: []) else {
            return XCTFail("should save")
        }
        XCTAssertEqual(parsed.title, "run 30m sprint")
        XCTAssertNil(parsed.durationMinutes)
    }

}

// MARK: - A typed `!N` reaches the to-do (report 2026-09-24_20-33-35)
//
// "I typed !5 and it went red but it seems like it didn't persist because when I go back to day plan
// it's white background again." The importance was saved locally only, and the next to-do refresh
// copied the server's untouched `outcome` back over it. `DayPlanOutcomeSync` decides when the store
// must write it to the backing to-do.

extension TaskNameCommitTests {

    private func synced(_ title: String = "3MT", outcome: Int?) -> DayPlanTask {
        var task = DayPlanTask(title: title, sourceTaskId: "todo-3mt")
        task.outcome = outcome
        return task
    }

    func testATypedImportanceOnASyncedTaskIsWrittenToItsToDo() {
        guard case .save(let parsed) = TaskNameCommit.forDayPlanRow("3MT !5", knownProjects: []) else {
            return XCTFail("a named task with a token should save")
        }
        let edited = synced(outcome: parsed.outcome)
        XCTAssertEqual(DayPlanOutcomeSync.write(previousOutcome: nil, task: edited),
                       .init(todoID: "todo-3mt", outcome: 10), "!5 is 10 on the wire")
    }

    func testAnUnchangedImportanceWritesNothing() {
        XCTAssertNil(DayPlanOutcomeSync.write(previousOutcome: 6, task: synced(outcome: 6)))
    }

    func testClearingImportanceIsWrittenAsUnrated() {
        XCTAssertEqual(DayPlanOutcomeSync.write(previousOutcome: 8, task: synced(outcome: nil)),
                       .init(todoID: "todo-3mt", outcome: nil),
                       "clearing must reach the server, or the old value comes back on the next refresh")
    }

    func testATaskWithNoToDoYetIsLeftToTheMint() {
        var local = DayPlanTask(title: "3MT", sourceTaskId: nil)
        local.outcome = 10
        XCTAssertNil(DayPlanOutcomeSync.write(previousOutcome: nil, task: local))
    }

    func testANamelessTaskIsNeverWritten() {
        // The upsert echoes the title back; an empty one would blank the to-do on every device.
        XCTAssertNil(DayPlanOutcomeSync.write(previousOutcome: nil, task: synced("  ", outcome: 10)))
    }
}
