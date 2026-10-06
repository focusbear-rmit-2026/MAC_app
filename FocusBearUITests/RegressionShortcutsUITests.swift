//
//  RegressionShortcutsUITests.swift
//  Focus BearUITests
//
//  Regression suite: Keyboard shortcuts. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Only the app's own shortcuts can be pressed here. The global ones from #934 (Brain Dump, Focus
//  Music, Task List) are machine-wide, so the UI-test build never registers them
//  (HotkeyService.registerAll) — a run would otherwise take them from the Focus Bear in use. For
//  those, the suite checks what they are set to.
//

import XCTest

final class RegressionShortcutsUITests: FocusBearUITestCase {
    private typealias ToDo = UITestContract.Identifier.ToDo
    private typealias Notes = UITestContract.Identifier.Notes
    private typealias Menu = UITestContract.Identifier.Menu
    private typealias Settings = UITestContract.Identifier.Settings
    private typealias Regression = UITestContract.Identifier.OnboardingRegression

    /// The #934 defaults (SettingsManager), as the Keyboard Shortcuts pane writes them.
    private static let defaultGlobalShortcuts = [
        (label: Regression.brainDumpShortcutLabel, combo: "⌥⌘B"),
        (label: Regression.focusMusicShortcutLabel, combo: "⌥⌘M"),
        (label: Regression.taskListShortcutLabel, combo: "⌥⌘T"),
    ]

    // MARK: - To-do list

    func testCommandNOpensANewToDo() throws {
        try openToDoList()
        press("n", modifiers: .command)
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "⌘N doesn't open the new-task editor")
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: titleField), "Escape doesn't close an untouched new task")
    }

    func testCommandSSavesTheToDoBeingWritten() throws {
        try openToDoList()
        let title = uniqueTitle("UI test shortcut to-do")
        let titleField = startNewToDo(titled: title)
        press("s", modifiers: .command)
        XCTAssertTrue(waitForNonExistence(of: titleField, timeout: Self.apiRoundTripTimeout), "⌘S doesn't save the task")
        let row = toDoRow(titled: title)
        XCTAssertTrue(toDoRowAppears(row), "the task saved with ⌘S isn't listed")
        deleteToDo(row, titled: title)
    }

    func testEscapeAsksBeforeDiscardingAnEditedToDo() throws {
        try openToDoList()
        let title = uniqueTitle("UI test discarded to-do")
        let titleField = startNewToDo(titled: title)
        press(.escape)
        discardUnsavedChanges()
        XCTAssertTrue(waitForNonExistence(of: titleField), "discarding leaves the editor open")
        XCTAssertFalse(appears(toDoRow(titled: title), within: Self.optionalWait), "a discarded task was saved")
    }

    // MARK: - Notes

    func testEscapeClosesTheNoteEditor() throws {
        try launchSignedIn()
        try open(tool: UITestContract.Identifier.Tools.notes)
        tap(element(Notes.newNoteButton))
        let titleField = app.textFields[Notes.editorTitleField]
        XCTAssertTrue(appears(titleField), "the note editor didn't open")
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: titleField), "Escape doesn't close the note editor")
    }

    // MARK: - Main window

    /// ⌃⇧⌘Esc is the app's escape hatch: it closes the main window whatever is on it.
    func testControlShiftCommandEscapeHidesTheMainWindow() throws {
        try launchSignedIn()
        let dayPlan = app.buttons[Menu.dayPlan]
        // The shortcut only acts on key presses aimed at the main window, so it is made key first.
        tap(dayPlan)
        press(.escape, modifiers: [.control, .shift, .command])
        XCTAssertTrue(waitForNonExistence(of: dayPlan), "⌃⇧⌘Esc doesn't hide the main window")
    }

    // MARK: - Global shortcuts (#934)

    func testKeyboardShortcutsPaneShowsTheGlobalShortcuts() throws {
        try launchSignedIn()
        open(menuItem: Menu.settings, expectingAnyOf: element(Settings.appearanceTab))
        let tab = element(Settings.keyboardShortcutsTab)
        guard appears(tab) else {
            throw XCTSkip("Keyboard shortcuts are an advanced-mode pane, and the test account is in simple mode.")
        }
        tap(tab)
        for shortcut in Self.defaultGlobalShortcuts {
            let label = element(shortcut.label)
            XCTAssertTrue(appears(label), "\(shortcut.label) is missing")
            XCTAssertEqual(shownText(of: label), shortcut.combo, "\(shortcut.label) isn't set to its default")
        }
    }

    func testGlobalShortcutsOpenTheirScreens() throws {
        throw XCTSkip("""
            The #934 global shortcuts are machine-wide, and the UI-test build never registers them \
            (HotkeyService.registerAll): pressing them would reach the Focus Bear in use, not the test app.
            """)
    }

    // MARK: - Helpers

    private func openToDoList() throws {
        try launchSignedIn()
        open(menuItem: Menu.todo, expectingAnyOf: element(ToDo.newTaskButton))
    }

    /// ⌘N, then the title typed into the field it focuses.
    private func startNewToDo(titled title: String) -> XCUIElement {
        press("n", modifiers: .command)
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "⌘N doesn't open the new-task editor")
        tap(titleField)
        typeIntoFocus(title)
        return titleField
    }

    /// The unsaved-changes question is a sheet on the editor's own sheet, so it is the second sheet —
    /// the shared confirmDestructiveAlert would take the editor for it (and Return there saves).
    /// NSAlert puts its first action, Discard, rightmost.
    private func discardUnsavedChanges() {
        let question = app.sheets.element(boundBy: 1)
        guard appears(question) else { return XCTFail("Escape on an edited task doesn't ask before discarding it") }
        XCTAssertFalse(question.textFields[ToDo.editorTitleField].exists, "took the editor for the unsaved-changes question")
        let discard = question.buttons.allElementsBoundByIndex.filter(\.isHittable).max { $0.frame.maxX < $1.frame.maxX }
        guard let discard else { return XCTFail("the unsaved-changes question has no buttons") }
        tap(discard)
        XCTAssertTrue(waitForNonExistence(of: question), "the unsaved-changes question didn't close")
    }

    private func toDoRow(titled title: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: ToDo.taskRow).containing(showing(title)).firstMatch
    }

    /// An AppKit label's text is its value; fall back to its label.
    private func shownText(of element: XCUIElement) -> String {
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }
}
