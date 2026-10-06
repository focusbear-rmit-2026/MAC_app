//
//  RegressionProjectsUITests.swift
//  Focus BearUITests
//
//  Regression suite: Projects. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Every project and task a test creates carries a per-run token in its name, and teardown blocks
//  delete them, pass or fail.
//

import XCTest

final class RegressionProjectsUITests: TasksRegressionUITestCase {
    private static let listModeIndex = 0
    private static let boardModeIndex = 1
    /// Each test here makes projects and tasks over the API, and its teardown deletes every one
    /// through the UI, roughly 12 s a project. Moving a task between two projects runs past the
    /// suite's two minutes with no step stuck; a test that really hangs still stops at three.
    private static let projectTestTimeAllowance: TimeInterval = 180

    override func setUpWithError() throws {
        try super.setUpWithError()
        executionTimeAllowance = Self.projectTestTimeAllowance
    }

    func testCreateRenameAndDeleteProject() throws {
        try launchSignedIn()
        openProjectsTab()
        let name = uniqueTitle("UI test project")
        let token = token(of: name)
        cleanUpTestItemsAfterwards()
        let renamed = "UI test renamed project \(token)"

        createProject(named: name)
        let heading = element(Tasks.projectNameHeading)
        XCTAssertTrue(waitUntil(Self.apiRoundTripTimeout) { self.displayedText(of: heading) == name }, "the new project's page isn't titled with its name")
        tap(heading)
        let field = element(Tasks.projectRenameField)
        XCTAssertTrue(appears(field), "clicking the name didn't offer to rename it")
        replaceText(in: field, with: renamed)
        press(.return)
        XCTAssertTrue(waitUntil(Self.apiRoundTripTimeout) { self.displayedText(of: heading) == renamed }, "the rename didn't take")

        tap(element(Tasks.projectBackButton))
        showAllProjects()
        let renamedButton = openProjectButton(named: renamed)
        XCTAssertTrue(appears(renamedButton, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "All projects doesn't list the new name")
        XCTAssertFalse(openProjectButton(named: name).exists, "All projects still lists the old name")

        tap(renamedButton)
        XCTAssertTrue(appears(element(Projects.detail), within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the project didn't open")
        deleteOpenProject()
        XCTAssertTrue(waitForNonExistence(of: element(Projects.detail), timeout: Self.apiRoundTripTimeout), "the deleted project stayed open")
        let isGone = waitForNonExistence(of: renamedButton, timeout: Self.apiRoundTripTimeout)
        XCTAssertTrue(isGone, "All projects still lists the deleted project")
    }

    func testAllProjectsSearchFindsTheProject() throws {
        try launchSignedIn()
        openProjectsTab()
        let name = uniqueTitle("UI test searched project")
        let token = token(of: name)
        cleanUpTestItemsAfterwards()

        createProject(named: name)
        tap(element(Tasks.projectBackButton))
        showAllProjects()
        let search = element(Tasks.projectsSearchField)
        replaceText(in: search, with: token)
        let found = openProjectButton(named: name)
        XCTAssertTrue(appears(found, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "searching its name didn't find the project")
        replaceText(in: search, with: "no project is called \(token)x")
        XCTAssertTrue(waitForNonExistence(of: found, timeout: Self.apiRoundTripTimeout), "a search that doesn't match still lists the project")
    }

    func testProjectTaskIsOnItsPageInBothViewsAndInTheTaskList() throws {
        try launchSignedIn()
        openProjectsTab()
        let name = uniqueTitle("UI test board project")
        let token = token(of: name)
        let title = "UI test board task \(token)"
        cleanUpTestItemsAfterwards()
        cleanUpTestItemsAfterwards()

        createProject(named: name)
        let card = addProjectTask(titled: title)
        let modes = element(Tasks.projectTasksModePicker)
        tap(modes.radioButtons.element(boundBy: Self.listModeIndex))
        XCTAssertTrue(appears(card), "the list view lost the task")
        tap(modes.radioButtons.element(boundBy: Self.boardModeIndex))
        XCTAssertTrue(appears(card), "the board view lost the task")

        tap(element(Projects.screenTabs).radioButtons.element(boundBy: Self.tasksTabIndex))
        let row = toDoRow(titled: title)
        XCTAssertTrue(toDoRowAppears(row), "the project's task isn't in the task list")
        XCTAssertTrue(rowShowsProject(row, named: name), "the task list doesn't show the task's project")
    }

    func testMovingAToDoBetweenProjects() throws {
        try launchSignedIn()
        openProjectsTab()
        let source = uniqueTitle("UI test source project")
        let token = token(of: source)
        let destination = "UI test destination project \(token)"
        let title = "UI test moved task \(token)"
        cleanUpTestItemsAfterwards()
        cleanUpTestItemsAfterwards()

        createProject(named: source)
        addProjectTask(titled: title)
        tap(element(Tasks.projectBackButton))
        createProject(named: destination)
        openProject(named: source)
        let card = projectCard(titled: title)
        XCTAssertTrue(appears(card, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the task isn't in its project")

        tap(card)
        XCTAssertTrue(appears(app.textFields[ToDo.editorTitleField]), "clicking the card didn't open the task")
        tap(projectChip(Tasks.editorSelectedProjectChip, named: source))
        tap(element(Tasks.editorProjectSearchField))
        typeIntoFocus(destination)
        tap(projectChip(Tasks.editorAvailableProjectChip, named: destination))
        XCTAssertTrue(projectChip(Tasks.editorSelectedProjectChip, named: destination).exists, "the destination project wasn't added")
        saveEditor()

        XCTAssertTrue(waitForNonExistence(of: card, timeout: Self.apiRoundTripTimeout), "the task stayed in its old project")
        openProject(named: destination)
        XCTAssertTrue(appears(card, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the task isn't in its new project")
    }

    func testShowInTaskListFiltersToTheProject() throws {
        try launchSignedIn()
        openProjectsTab()
        let name = uniqueTitle("UI test filtered project")
        let token = token(of: name)
        let title = "UI test filtered project task \(token)"
        cleanUpTestItemsAfterwards()
        cleanUpTestItemsAfterwards()

        createProject(named: name)
        addProjectTask(titled: title)
        tap(element(Tasks.projectShowInTaskListButton))
        XCTAssertTrue(appears(element(ToDo.newTaskButton)), "Show in task list didn't open the task list")
        let clear = element(Tasks.clearFiltersButton)
        XCTAssertTrue(appears(clear), "the task list isn't filtered")
        // The filter bar is wider than the pane, so the list's headers can sit outside the window.
        XCTAssertTrue(toDoRowAppears(toDoRow(titled: title)), "the filtered list doesn't show the project's task")
        tap(clear)
    }

    func testProjectCreatedFromTheTaskEditorTagsTheTask() throws {
        try launchSignedIn()
        openToDoList()
        let title = uniqueTitle("UI test tagged task")
        let token = token(of: title)
        let project = "UI test editor project \(token)"
        cleanUpTestItemsAfterwards()
        cleanUpTestItemsAfterwards()

        tap(element(ToDo.newTaskButton))
        let titleField = app.textFields[ToDo.editorTitleField]
        XCTAssertTrue(appears(titleField), "the new-task editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        tap(element(Tasks.editorProjectSearchField))
        typeIntoFocus(project)
        let create = element(Tasks.editorCreateProjectButton)
        XCTAssertTrue(appears(create), "a new project name offers no Create")
        tap(create)
        let chip = projectChip(Tasks.editorSelectedProjectChip, named: project, timeout: Self.apiRoundTripTimeout)
        XCTAssertTrue(chip.exists, "the created project isn't on the task")
        saveEditor()

        let row = toDoRow(titled: title)
        XCTAssertTrue(toDoRowAppears(row), "the tagged task isn't listed")
        XCTAssertTrue(rowShowsProject(row, named: project), "the task list doesn't show the task's new project")
    }

    func testProjectAccordion() throws {
        throw XCTSkip("""
            Projects has no accordion of its own: the only groups that fold are the "What matters" \
            sections, and only past a screenful of projects. The To-do list's section accordion is covered \
            by RegressionToDoUITests.testSectionsCollapseAndExpand.
            """)
    }

    // MARK: Helpers

    /// A project chip in the task editor: its button's label names the project, or a text inside it does.
    private func projectChip(_ identifier: String, named name: String, timeout: TimeInterval = screenTimeout) -> XCUIElement {
        let chip = element(UITestContract.Identifier.named(identifier, name))
        _ = appears(chip, within: timeout, waitsOnNetwork: timeout > Self.screenTimeout)
        return chip
    }

    /// A task row names each of its projects as a "#name" chip.
    private func rowShowsProject(_ row: XCUIElement, named name: String) -> Bool {
        appears(row.descendants(matching: .any).matching(showingText(containing: "#" + name)).firstMatch,
                within: Self.apiRoundTripTimeout, waitsOnNetwork: true)
    }
}
