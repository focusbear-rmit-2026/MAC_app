//
//  ProjectsUITests.swift
//  Focus BearUITests
//
//  One project through its life: created, given a task, the task moved across the board, deleted.
//  The project is uniquely named and deleted at the end, taking its task with it.
//

import XCTest

final class ProjectsUITests: FocusBearUITestCase {
    private typealias Projects = UITestContract.Identifier.Projects
    private typealias ToDo = UITestContract.Identifier.ToDo
    private static let projectsTabIndex = 1

    func testProjectKanbanLifecycle() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.todo, expectingAnyOf: element(Projects.screenTabs))
        tap(element(Projects.screenTabs).radioButtons.element(boundBy: Self.projectsTabIndex))

        let projectName = uniqueTitle("UI test project")
        try createProject(named: projectName)
        let detail = element(Projects.detail)
        if !appears(detail, within: Self.apiRoundTripTimeout, waitsOnNetwork: true) { openProject(named: projectName) }
        XCTAssertTrue(appears(detail), "the new project didn't open")

        let taskTitle = uniqueTitle("UI test project task")
        addTask(titled: taskTitle)
        let card = app.descendants(matching: .any).matching(identifier: Projects.taskCard)
            .containing(showing(taskTitle)).firstMatch
        XCTAssertTrue(appears(card, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the task isn't on the board")
        try moveToAnotherColumn(card, titled: taskTitle)
        attachScreenshot(named: "task moved")

        deleteProject()
        XCTAssertTrue(waitForNonExistence(of: detail), "the project didn't close after being deleted")
    }

    private func createProject(named name: String) throws {
        let newProject = element(Projects.newProjectButton)
        XCTAssertTrue(appears(newProject), "no New project button")
        tap(newProject)
        let nameField = app.textFields[Projects.nameField]
        XCTAssertTrue(appears(nameField), "the new-project sheet didn't open")
        tap(nameField)
        typeIntoFocus(name)
        tap(element(Projects.createButton))
    }

    private func openProject(named name: String) {
        tap(element(UITestContract.Identifier.named(Projects.openProjectButton, name)))
    }

    private func addTask(titled title: String) {
        tap(element(Projects.addTaskButton))
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "the task editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        tap(element(ToDo.editorSaveButton))
    }

    /// Through the card's "Move to" menu: the same move a drag makes, without depending on pointer
    /// speed. The card must end up in a different column.
    private func moveToAnotherColumn(_ card: XCUIElement, titled title: String) throws {
        let columns = app.descendants(matching: .any).matching(identifier: Projects.column)
        guard columns.count > 1 else { throw XCTSkip("The project board has a single column.") }
        let startColumn = columnIndex(ofTaskTitled: title, in: columns)

        let menu = card.descendants(matching: .any).matching(identifier: Projects.moveTaskMenu).firstMatch
        let targets = openMenu(of: menu) ?? []
        let target = try XCTUnwrap(targets.indices.first { $0 != startColumn }, "the move menu offers no other column")
        targets[target].click()   // an item of the menu that control just opened (see openMenu)

        let moved = NSPredicate { _, _ in self.columnIndex(ofTaskTitled: title, in: columns) != startColumn }
        XCTAssertTrue(waitUntil(moved, isTrueOf: NSNull(), within: Self.screenTimeout), "the task stayed in its column")
    }

    private func columnIndex(ofTaskTitled title: String, in columns: XCUIElementQuery) -> Int? {
        columns.allElementsBoundByIndex.firstIndex { column in
            column.descendants(matching: .any).matching(showing(title)).count > 0
        }
    }

    private func deleteProject() {
        tap(element(Projects.settingsButton))
        let delete = element(Projects.deleteButton)
        XCTAssertTrue(appears(delete), "project settings have no Delete")
        tap(delete)
        confirmDestructiveAlert()
    }
}
