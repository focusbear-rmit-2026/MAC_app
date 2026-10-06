//
//  RegressionToDoUITests.swift
//  Focus BearUITests
//
//  Regression suite: To-do. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Every to-do a test creates carries a per-run token in its title and is deleted again by a
//  teardown block, so a failing test leaves nothing on the account either. The base class at the
//  bottom holds what the Day Plan and Projects regression classes share with this one.
//

import XCTest

final class RegressionToDoUITests: TasksRegressionUITestCase {
    // MARK: Creating

    func testNewTaskIsStillListedAfterRelaunch() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test persisted to-do")
        cleanUpTestItemsAfterwards()

        createToDo(titled: title)
        app.terminate()
        try launchSignedIn()
        openToDoList()
        XCTAssertTrue(toDoRowAppears(toDoRow(titled: title)), "the to-do didn't survive a relaunch")
    }

    func testCommandNOpensTheEditorAndReturnSaves() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test command-N to-do")
        cleanUpTestItemsAfterwards()

        press("n", modifiers: .command)
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "⌘N didn't open the new-task editor")
        XCTAssertTrue(becomesFocused(titleField), "the new-task editor didn't start in its title")
        typeIntoFocus(title)
        press(.return)
        XCTAssertTrue(waitForNonExistence(of: titleField, timeout: Self.apiRoundTripTimeout), "Return didn't save the task")
        XCTAssertTrue(toDoRowAppears(toDoRow(titled: title)), "the task saved with Return isn't listed")
    }

    func testCancellingAnEditedNewTaskAsksBeforeDiscardingIt() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test discarded to-do")
        let token = token(of: title)
        cleanUpTestItemsAfterwards()

        tap(element(ToDo.newTaskButton))
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "the new-task editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        tap(element(Tasks.editorCancelButton))
        XCTAssertTrue(discardEditorEdits(), "Cancel with unsaved edits didn't ask first")
        XCTAssertTrue(waitForNonExistence(of: titleField), "discarding didn't close the editor")
        XCTAssertFalse(appears(toDoRow(titled: title), within: Self.optionalWait), "a discarded task was saved anyway")
    }

    // MARK: Editing

    func testEditingTitleDescriptionAndDurationIsSaved() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test edited to-do")
        let token = token(of: title)
        cleanUpTestItemsAfterwards()
        let renamed = "UI test renamed to-do \(token)"
        let description = "Notes written by a UI test \(token)"
        let minutes = "45"

        let row = createToDo(titled: title)
        openEditor(forRow: row, titled: title)
        replaceText(in: app.textFields[ToDo.editorTitleField], with: renamed)
        tap(element(Tasks.editorDescription))
        typeIntoFocus(description)
        replaceText(in: element(Tasks.editorDurationField), with: minutes)
        saveEditor()

        let renamedRow = toDoRow(titled: renamed)
        XCTAssertTrue(appears(renamedRow, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the new title isn't listed")
        XCTAssertTrue(waitForNonExistence(of: row), "the old title is still listed")
        openEditor(forRow: renamedRow, titled: renamed)
        XCTAssertTrue(appears(app.textViews.matching(NSPredicate(format: "value == %@", description)).firstMatch),
                      "the description wasn't saved")
        XCTAssertEqual(fieldValue(of: element(Tasks.editorDurationField)), minutes, "the duration wasn't saved")
        closeUnchangedEditor()
    }

    func testDueDateTypedInTheEditorIsSavedAndCanBeCleared() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test due-date to-do")
        cleanUpTestItemsAfterwards()

        let row = createToDo(titled: title)
        openEditor(forRow: row, titled: title)
        let due = element(Tasks.editorDueDateField)
        replaceText(in: due, with: Self.tomorrowShorthand)
        press(.return)
        XCTAssertTrue(waitUntil { ![Self.tomorrowShorthand, ""].contains(self.fieldValue(of: due)) },
                      "the typed date wasn't resolved to a day")
        let resolved = fieldValue(of: due)
        saveEditor()

        openEditor(forRow: row, titled: title)
        XCTAssertEqual(fieldValue(of: due), resolved, "the due date wasn't saved")
        replaceText(in: due, with: "")
        saveEditor()

        openEditor(forRow: row, titled: title)
        XCTAssertEqual(fieldValue(of: due), "", "clearing the due date wasn't saved")
        closeUnchangedEditor()
    }

    func testDueDatePresetsOnTheRowSetAndClearTheDate() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test due-preset to-do")
        cleanUpTestItemsAfterwards()

        let row = createToDo(titled: title)
        setDueDate(ofRow: row, preset: Tasks.duePresetTomorrow)
        let tomorrow = dueDateInEditor(ofRow: row, titled: title)
        XCTAssertFalse(tomorrow.isEmpty, "Tomorrow set no due date")

        setDueDate(ofRow: row, preset: Tasks.duePresetNextWeek)
        let nextWeek = dueDateInEditor(ofRow: row, titled: title)
        XCTAssertFalse(nextWeek.isEmpty, "Next week set no due date")
        XCTAssertNotEqual(nextWeek, tomorrow, "Next week didn't move the due date")

        setDueDate(ofRow: row, preset: Tasks.duePresetClear)
        XCTAssertEqual(dueDateInEditor(ofRow: row, titled: title), "", "Clear left a due date")
    }

    func testOutcomeChosenInTheEditorIsSaved() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test outcome to-do")
        cleanUpTestItemsAfterwards()

        let row = createToDo(titled: title)
        openEditor(forRow: row, titled: title)
        let outcome = element(Tasks.outcomePicker)
        XCTAssertTrue(appears(outcome), "the editor has no Outcome")
        let before = displayedText(of: outcome)
        chooseMenuItem(at: Self.highestOutcomeMenuIndex, openedBy: outcome)
        XCTAssertTrue(waitUntil { self.displayedText(of: outcome) != before }, "choosing an outcome changed nothing")
        let chosen = displayedText(of: outcome)
        saveEditor()

        openEditor(forRow: row, titled: title)
        XCTAssertEqual(displayedText(of: element(Tasks.outcomePicker)), chosen, "the outcome wasn't saved")
        closeUnchangedEditor()
    }

    // MARK: Completing and deleting

    func testCompletedTaskMovesToDoneAndUncompletingBringsItBack() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test completed to-do")
        cleanUpTestItemsAfterwards()

        let row = createToDo(titled: title)
        tap(checkbox(inRow: row))
        XCTAssertTrue(waitForNonExistence(of: row, timeout: Self.apiRoundTripTimeout), "the completed task stayed under To do")
        tap(element(ToDo.doneSection))
        XCTAssertTrue(appears(row), "the completed task isn't under Done")

        tap(checkbox(inRow: row))
        let hasLeftDone = waitForNonExistence(of: row, timeout: Self.apiRoundTripTimeout)
        XCTAssertTrue(hasLeftDone, "the reopened task stayed under Done")

        tap(element(ToDo.notStartedSection))
        XCTAssertTrue(appears(row), "the reopened task isn't back under To do")
    }

    func testDeleteAsksFirstAndCancelKeepsTheTask() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test deleted to-do")
        cleanUpTestItemsAfterwards()

        let row = createToDo(titled: title)
        select(row: row, titled: title)
        // The action bar is drawn in after the click selects the row, not with it.
        let delete = rowControl(ToDo.deleteButton, inRow: row)
        XCTAssertTrue(appears(delete), "the selected row has no Delete")
        tap(delete)
        let cancel = rowControl(Tasks.rowCancelDeleteButton, inRow: row)
        XCTAssertTrue(appears(cancel), "Delete didn't ask first")
        tap(cancel)
        XCTAssertTrue(waitForNonExistence(of: cancel), "Cancel didn't close the question")
        XCTAssertTrue(row.exists, "cancelling the delete removed the task")

        deleteToDo(row, titled: title)
    }

    // MARK: Finding

    func testSearchNarrowsTheListAndClearingRestoresIt() throws {
        try launchSignedIn()
        openToDoList()
        let wanted = uniqueTitle("UI test searched to-do")
        let token = token(of: wanted)
        let other = "UI test other to-do \(token)"
        cleanUpTestItemsAfterwards()

        let wantedRow = createToDo(titled: wanted)
        let otherRow = createToDo(titled: other)
        let search = element(Tasks.searchField)
        tap(search)
        typeIntoFocus(wanted)
        XCTAssertTrue(waitForNonExistence(of: otherRow, timeout: Self.apiRoundTripTimeout), "the search still lists a task it doesn't match")
        XCTAssertTrue(appears(wantedRow), "the search lost the task it matches")

        replaceText(in: search, with: "")
        XCTAssertTrue(toDoRowAppears(otherRow), "clearing the search didn't bring the list back")
    }

    func testDueDateFilterHidesTasksDueOnOtherDays() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test filtered to-do")
        cleanUpTestItemsAfterwards()

        let row = createToDo(titled: title)
        setDueDate(ofRow: row, preset: Tasks.duePresetTomorrow)
        tap(element(Tasks.filterButton))
        let dueFilter = element(Tasks.filterDueDatePicker)
        XCTAssertTrue(appears(dueFilter), "Filter didn't show the filters")
        chooseMenuItem(at: Self.dueTodayFilterIndex, openedBy: dueFilter)
        XCTAssertTrue(waitForNonExistence(of: row), "“Due today” still lists a task due tomorrow")

        let clear = element(Tasks.clearFiltersButton)
        XCTAssertTrue(appears(clear), "an active filter offers no Clear filters")
        tap(clear)
        XCTAssertTrue(toDoRowAppears(row), "clearing the filters didn't bring the task back")
        tap(element(Tasks.filterButton))
        XCTAssertTrue(waitForNonExistence(of: dueFilter), "Filter didn't hide the filters again")
    }

    func testSortModesChangeTheOrder() throws {
        try launchSignedIn()
        openToDoList()
        // Created first but due first: Newest and Due date must disagree about which comes first.
        let older = uniqueTitle("UI test older to-do")
        let token = token(of: older)
        let newer = "UI test newer to-do \(token)"
        cleanUpTestItemsAfterwards()

        let olderRow = createToDo(titled: older)
        setDueDate(ofRow: olderRow, preset: Tasks.duePresetTomorrow)
        let newerRow = createToDo(titled: newer)
        setDueDate(ofRow: newerRow, preset: Tasks.duePresetNextWeek)

        let sort = element(Tasks.sortPicker)
        tap(sort.radioButtons.element(boundBy: Self.newestSortIndex))
        XCTAssertTrue(waitUntil(Self.apiRoundTripTimeout) { self.isAbove(newerRow, olderRow) }, "Newest didn't put the newer task first")
        tap(sort.radioButtons.element(boundBy: Self.dueDateSortIndex))
        XCTAssertTrue(waitUntil(Self.apiRoundTripTimeout) { self.isAbove(olderRow, newerRow) }, "Due date didn't put the sooner task first")
        tap(sort.radioButtons.element(boundBy: Self.smartSortIndex))
    }

    func testSectionsCollapseAndExpand() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test doing to-do")
        cleanUpTestItemsAfterwards()

        tap(element(ToDo.newTaskButton))
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "the new-task editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        tap(element(Tasks.editorStatusPicker).radioButtons.element(boundBy: Self.doingStatusIndex))
        saveEditor()

        let doing = element(Tasks.doingSection)
        let row = toDoRow(titled: title)
        if !appears(row, within: Self.apiRoundTripTimeout, waitsOnNetwork: true) { tap(doing) }
        XCTAssertTrue(appears(row), "the task saved as Doing isn't under Doing")
        tap(doing)
        XCTAssertTrue(waitForNonExistence(of: row), "Doing didn't collapse")
        tap(doing)
        XCTAssertTrue(appears(row), "Doing didn't expand again")
        tap(element(ToDo.notStartedSection))
        XCTAssertTrue(waitForNonExistence(of: row), "opening To do left Doing open too")
        XCTAssertTrue(element(ToDo.doneSection).exists, "the list has no Done section")
    }

    // MARK: More Options

    func testEisenhowerMatrixListsANewTaskUnderDo() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test matrix to-do")
        cleanUpTestItemsAfterwards()

        createToDo(titled: title)
        chooseMoreOption(Tasks.eisenhowerMatrixMenuItem)
        let doQuadrant = element(Tasks.matrixQuadrantPrefix + String(Self.doQuadrant))
        XCTAssertTrue(appears(doQuadrant), "the Eisenhower matrix didn't open")
        let listed = doQuadrant.descendants(matching: .any).matching(showingText(containing: title)).firstMatch
        XCTAssertTrue(appears(listed), "a new task isn't in the matrix's Do quadrant")
        closeToolsSheet()
    }

    func testBrainDumpAndProcrastinateSheetsOpenAndClose() throws {
        try launchSignedIn()
        openToDoList()

        chooseMoreOption(Tasks.brainDumpMenuItem)
        XCTAssertTrue(appears(element(Tasks.brainDumpEditor)), "Brain dump didn't open")
        closeToolsSheet()

        chooseMoreOption(Tasks.procrastinateMenuItem)
        XCTAssertTrue(appears(element(Tasks.procrastinateUrlField)), "Procrastinate didn't open")
        closeToolsSheet()
    }

    func testReschedulePlanCannotApplyWithNothingSelected() throws {
        try launchSignedIn()
        openToDoList()
        chooseMoreOption(ToDo.reschedulePlanMenuItem)

        let close = element(ToDo.reschedulePlanCloseButton)
        XCTAssertTrue(appears(close), "the reschedule plan didn't open")
        XCTAssertTrue(waitForEnabled(close, timeout: Self.apiRoundTripTimeout), "the plan never finished loading")
        let apply = element(Tasks.reschedulePlanApplyButton)
        XCTAssertTrue(appears(apply), "the loaded plan has no Apply")
        XCTAssertFalse(apply.isEnabled, "Apply is offered with nothing selected")
        tap(close)
        XCTAssertTrue(waitForNonExistence(of: close), "Close didn't close the plan")
    }

    // MARK: Helpers

    /// The due-date grammar's word for tomorrow — typed, like a user would, not a translated title.
    private static let tomorrowShorthand = "tomorrow"
    /// Outcome menu: "Not set", then the five levels lowest first.
    private static let highestOutcomeMenuIndex = 5
    /// Due-date filter menu: All, Today, This week, Next week, Next 30 days.
    private static let dueTodayFilterIndex = 1
    private static let smartSortIndex = 0
    private static let newestSortIndex = 1
    private static let dueDateSortIndex = 2
    private static let doingStatusIndex = 1
    /// `EisenhowerQuadrant.doIt` — where a new task lands.
    private static let doQuadrant = 1
    /// More Options, by position, for a menu whose items don't report their identifiers:
    /// reschedule plan, brain dump, export CSV, matrix, procrastinate, integrations. Export and
    /// integrations are never chosen (a file and a browser window).
    private static let moreOptionsOrder = [ToDo.reschedulePlanMenuItem, Tasks.brainDumpMenuItem, nil,
                                           Tasks.eisenhowerMatrixMenuItem, Tasks.procrastinateMenuItem, nil]

    /// Chooses a More Options entry by its identifier, from the menu that button opened.
    private func chooseMoreOption(_ identifier: String) {
        guard let position = Self.moreOptionsOrder.firstIndex(where: { $0 == identifier }) else {
            return XCTFail("More Options has no \(identifier) in its known order")
        }
        chooseMenuItem(identifiedBy: identifier, orAt: position, of: Self.moreOptionsOrder.count, openedBy: element(ToDo.toolsMenu))
    }

    private func closeToolsSheet() {
        let close = element(Tasks.toolsSheetCloseButton)
        XCTAssertTrue(appears(close), "the sheet has no Close")
        tap(close)
        XCTAssertTrue(waitForNonExistence(of: close), "Close didn't close the sheet")
    }

    private func checkbox(inRow row: XCUIElement) -> XCUIElement {
        rowControl(ToDo.taskCheckbox, inRow: row)
    }

    private func setDueDate(ofRow row: XCUIElement, preset: String) {
        tap(rowControl(Tasks.rowDueButton, inRow: row))
        let choice = element(preset)
        XCTAssertTrue(appears(choice), "the due-date popover has no \(preset)")
        tap(choice)
        XCTAssertTrue(waitForNonExistence(of: choice), "choosing \(preset) didn't close the popover")
    }

    /// The task's due date as its editor shows it, "" for none. Closes the editor again.
    private func dueDateInEditor(ofRow row: XCUIElement, titled title: String) -> String {
        XCTAssertTrue(appears(row, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the task left the list")
        openEditor(forRow: row, titled: title)
        let due = fieldValue(of: element(Tasks.editorDueDateField))
        closeUnchangedEditor()
        return due
    }

    private func isAbove(_ upper: XCUIElement, _ lower: XCUIElement) -> Bool {
        upper.exists && lower.exists && upper.frame.minY < lower.frame.minY
    }
}

// MARK: - Shared by the Day Plan, To-do and Projects regression classes

/// Helpers for the task areas' regression classes. A class of its own rather than an extension on
/// `FocusBearUITestCase`, so its names can't collide with the other areas' helpers.
class TasksRegressionUITestCase: FocusBearUITestCase {
    typealias ToDo = UITestContract.Identifier.ToDo
    typealias Tasks = UITestContract.Identifier.TasksRegression
    typealias Projects = UITestContract.Identifier.Projects

    static let tasksTabIndex = 0
    static let projectsTabIndex = 1
    static let allProjectsViewIndex = 1
    /// The editor is the first sheet; a question it asks is attached to it as the second.
    private static let editorQuestionSheetIndex = 1

    // MARK: Waiting and reading

    /// Polls `condition` until it holds or `timeout` passes.
    func waitUntil(_ timeout: TimeInterval = screenTimeout, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else { return false }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.conditionPollInterval))
        }
        return true
    }

    func becomesFocused(_ element: XCUIElement) -> Bool {
        waitUntil { element.exists && hasKeyboardFocus(element) }
    }

    /// What a control shows: a field's or label's value, else a button's title, else its label.
    func displayedText(of element: XCUIElement) -> String {
        guard element.exists else { return "" }
        let candidates = [element.value as? String, element.title, element.label]
        return candidates.compactMap { $0 }.first { !$0.isEmpty } ?? ""
    }

    /// A field's text: its value alone, since an empty field's label is its placeholder.
    func fieldValue(of field: XCUIElement) -> String {
        field.exists ? (field.value as? String ?? "") : ""
    }

    /// Text on screen that includes `text`. Only a static text's value is matched: another element's
    /// value can be a number (a checkbox), which CONTAINS can't be asked of.
    func showingText(containing text: String) -> NSPredicate {
        NSPredicate(format: "label CONTAINS %@ OR (elementType == %lu AND value CONTAINS %@)",
                    text, XCUIElement.ElementType.staticText.rawValue, text)
    }

    /// Answers the task editor's "Discard them?" with Discard; false when it never asked.
    ///
    /// Not the shared `confirmDestructiveAlert`: that takes the first sheet, which is the editor's own,
    /// and — Return doing nothing, since NSAlert gives a destructive first button no Return key — clicks
    /// that sheet's rightmost button, the editor's Save. The question is the second sheet, attached to
    /// the editor's, and NSAlert puts its first action, Discard, rightmost.
    @discardableResult
    func discardEditorEdits() -> Bool {
        let question = app.sheets.element(boundBy: Self.editorQuestionSheetIndex)
        guard appears(question), !question.textFields[ToDo.editorTitleField].exists else { return false }
        let buttons = question.buttons.allElementsBoundByIndex.filter(\.isHittable)
        guard let discard = buttons.max(by: { $0.frame.maxX < $1.frame.maxX }) else { return false }
        tap(discard)
        return true
    }

    /// Selects everything in a field and types over it (an empty `text` just clears it).
    func replaceText(in field: XCUIElement, with text: String) {
        XCTAssertTrue(appears(field), "the field to type into is missing")
        tap(field)
        press("a", modifiers: .command)
        guard !text.isEmpty else {
            press(.delete)
            return
        }
        typeIntoFocus(text)
    }

    /// The per-run part of a `uniqueTitle`, which every title a test derives from it shares.
    func token(of uniqueTitle: String) -> String {
        String(uniqueTitle.split(separator: " ").last ?? Substring(uniqueTitle))
    }

    // MARK: To-do list

    func openToDoList() {
        let tabs = element(Projects.screenTabs)
        open(menuItem: UITestContract.Identifier.Menu.todo, expectingAnyOf: element(ToDo.newTaskButton), tabs)
        guard !element(ToDo.newTaskButton).exists, tabs.exists else { return }
        tap(tabs.radioButtons.element(boundBy: Self.tasksTabIndex))
        XCTAssertTrue(appears(element(ToDo.newTaskButton)), "the Tasks tab didn't open")
    }

    func toDoRow(titled title: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: ToDo.taskRow).containing(showing(title)).firstMatch
    }

    func rowControl(_ identifier: String, inRow row: XCUIElement) -> XCUIElement {
        row.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// New Task → title → Save, and the row it produced.
    @discardableResult
    func createToDo(titled title: String) -> XCUIElement {
        tap(element(ToDo.newTaskButton))
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "the new-task editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        saveEditor()
        let row = toDoRow(titled: title)
        XCTAssertTrue(toDoRowAppears(row), "the saved to-do \(title) isn't in the list")
        return row
    }

    func saveEditor() {
        let titleField = app.textFields[ToDo.editorTitleField]
        tap(element(ToDo.editorSaveButton))
        XCTAssertTrue(waitForNonExistence(of: titleField, timeout: Self.apiRoundTripTimeout), "the editor didn't save and close")
    }

    /// Cancel on an editor with no edits closes it without asking.
    func closeUnchangedEditor() {
        let titleField = app.textFields[ToDo.editorTitleField]
        tap(element(Tasks.editorCancelButton))
        XCTAssertTrue(waitForNonExistence(of: titleField), "Cancel didn't close the unchanged editor")
    }

    /// Clicking a row's title selects it, revealing its action bar.
    func select(row: XCUIElement, titled title: String) {
        tap(row.staticTexts.matching(showing(title)).firstMatch)
    }

    /// The row's Edit, selecting it first when its action bar isn't showing.
    func openEditor(forRow row: XCUIElement, titled title: String) {
        let edit = rowControl(Tasks.rowEditButton, inRow: row)
        if !edit.exists { select(row: row, titled: title) }
        XCTAssertTrue(appears(edit), "the selected row has no Edit")
        tap(edit)
        XCTAssertTrue(appears(app.textFields[ToDo.editorTitleField]), "Edit didn't open the editor")
    }

    // MARK: Cleaning up

    // MARK: Projects

    func openProjectsTab() {
        let tabs = element(Projects.screenTabs)
        open(menuItem: UITestContract.Identifier.Menu.todo, expectingAnyOf: tabs)
        tap(tabs.radioButtons.element(boundBy: Self.projectsTabIndex))
        XCTAssertTrue(firstToAppear([element(Projects.newProjectButton), element(Projects.detail)]) != nil,
                      "the Projects tab didn't open")
    }

    func showAllProjects() {
        let modes = element(Tasks.projectsViewModePicker)
        guard appears(modes) else { return }
        tap(modes.radioButtons.element(boundBy: Self.allProjectsViewIndex))
    }

    func openProjectButton(named name: String) -> XCUIElement {
        element(UITestContract.Identifier.named(Projects.openProjectButton, name))
    }

    /// New project → name → Save, ending on the new project's page.
    func createProject(named name: String) {
        let newProject = element(Projects.newProjectButton)
        XCTAssertTrue(appears(newProject), "no New project button")
        tap(newProject)
        let nameField = app.textFields[Projects.nameField]
        XCTAssertTrue(appears(nameField), "the new-project sheet didn't open")
        tap(nameField)
        typeIntoFocus(name)
        tap(element(Projects.createButton))
        XCTAssertTrue(waitForNonExistence(of: nameField, timeout: Self.apiRoundTripTimeout), "the new-project sheet didn't close")
        // Creating lists the project under All projects without opening it; waiting for its page to
        // open by itself cost a full round trip on every project a test made.
        openProject(named: name)
    }

    /// From anywhere on the Projects tab, the named project's page.
    func openProject(named name: String) {
        let back = element(Tasks.projectBackButton)
        if back.exists { tap(back) }
        showAllProjects()
        let open = openProjectButton(named: name)
        XCTAssertTrue(appears(open, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "All projects doesn't list \(name)")
        tap(open)
        XCTAssertTrue(appears(element(Projects.detail), within: Self.apiRoundTripTimeout, waitsOnNetwork: true),
                      "\(name) didn't open")
    }

    /// Add task → title → Save on the open project's page, and the card it produced.
    @discardableResult
    func addProjectTask(titled title: String) -> XCUIElement {
        tap(element(Projects.addTaskButton))
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "the task editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        saveEditor()
        let card = projectCard(titled: title)
        XCTAssertTrue(appears(card, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the task isn't on the project's page")
        return card
    }

    func projectCard(titled title: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: Projects.taskCard).containing(showing(title)).firstMatch
    }

    func deleteOpenProject() {
        tap(element(Projects.settingsButton))
        let delete = element(Projects.deleteButton)
        XCTAssertTrue(appears(delete), "project settings have no Delete")
        tap(delete)
        confirmDestructiveAlert()
    }
}
