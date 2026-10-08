//
//  DayPlanAndToDoUITests.swift
//  Focus BearUITests
//
//  These write to the test account (a Day Plan task, a to-do). Titles are unique per run and the
//  to-do is deleted again, so repeated runs don't pile up.
//

import XCTest

final class DayPlanAndToDoUITests: FocusBearUITestCase {
    private typealias DayPlan = UITestContract.Identifier.DayPlan
    private typealias ToDo = UITestContract.Identifier.ToDo

    func testDayPlanAddAndCompleteTask() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.dayPlan, expectingAnyOf: element(DayPlan.view))
        let title = uniqueTitle("UI test day plan task")

        tap(element(DayPlan.addTaskButton))
        // The new row's name field takes focus as soon as it is added.
        typeIntoFocus(title + "\n")

        let nameField = app.textFields.matching(NSPredicate(format: "value == %@", title)).firstMatch
        XCTAssertTrue(appears(nameField), "the new task isn't in the Day Plan")
        let taskID = String(nameField.identifier.dropFirst(DayPlan.taskNamePrefix.count))
        let done = app.checkBoxes[taskID]
        XCTAssertTrue(done.exists, "the new task has no done checkbox")
        tap(done)
        // A done task leaves the list unless "Show completed" is on, which a fresh test account hasn't.
        let isCompleted = waitForNonExistence(of: nameField) || (done.exists && done.value as? Int == 1)
        XCTAssertTrue(isCompleted, "the task neither reads as done nor left the list")
        attachScreenshot(named: "day plan task completed")
    }

    func testToDoAddCompleteAndDelete() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.todo, expectingAnyOf: element(ToDo.newTaskButton))
        let title = uniqueTitle("UI test to-do")

        tap(element(ToDo.newTaskButton))
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "the new-task editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        tap(element(ToDo.editorSaveButton))

        let row = taskRow(titled: title)
        XCTAssertTrue(toDoRowAppears(row), "the saved to-do isn't in the list")
        let checkbox = row.descendants(matching: .any).matching(identifier: ToDo.taskCheckbox).firstMatch
        tap(checkbox)
        // A completed task moves to Done, which is collapsed unless it was the section left open.
        if waitForNonExistence(of: row) { tap(element(ToDo.doneSection)) }
        XCTAssertTrue(appears(row), "the completed to-do isn't under Done")
        attachScreenshot(named: "to-do completed")

        // A completed row can be drawn from a stale copy, with no Delete when selected.
        deleteToDo(row, titled: title)
    }

    func testToDoReschedulePlanOpensAndCloses() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.todo, expectingAnyOf: element(ToDo.toolsMenu))
        // The plan is the tools menu's first entry.
        chooseMenuItem(at: 0, openedBy: element(ToDo.toolsMenu))

        let close = element(ToDo.reschedulePlanCloseButton)
        XCTAssertTrue(appears(close), "the reschedule plan sheet didn't open")
        attachScreenshot(named: "reschedule plan")
        XCTAssertTrue(waitForEnabled(close, timeout: Self.apiRoundTripTimeout), "the plan never finished loading")
        tap(close)
        XCTAssertTrue(waitForNonExistence(of: close), "the reschedule plan sheet didn't close")
    }

    private func taskRow(titled title: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: ToDo.taskRow)
            .containing(showing(title))
            .firstMatch
    }
}
