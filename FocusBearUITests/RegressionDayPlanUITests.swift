//
//  RegressionDayPlanUITests.swift
//  Focus BearUITests
//
//  Regression suite: Day Plan. Runs in the Regression test plan; the critical path is in Smoke.
//
//  Day Plan rows live in the test app's own preferences, which every launch resets, but naming one
//  creates a to-do on the account. Each test's names carry a per-run token and a teardown block
//  deletes those to-dos, pass or fail. Nothing here saves a routine or a calendar event.
//

import XCTest

final class RegressionDayPlanUITests: TasksRegressionUITestCase {
    private typealias DayPlan = UITestContract.Identifier.DayPlan
    private typealias Editors = UITestContract.Identifier.DayPlanEditors

    // MARK: Adding and editing

    func testTabFromTaskNameMovesToItsDuration() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test tabbed task")
        cleanUpTestItemsAfterwards()

        tap(element(DayPlan.addTaskButton))
        typeIntoFocus(title)
        press(.tab)
        let taskID = try idOfTask(titled: title)
        XCTAssertTrue(becomesFocused(durationField(of: taskID)), "Tab from the task name didn't go to its duration")
    }

    func testDurationTypedAfterTheNameIsSaved() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test timed task")
        cleanUpTestItemsAfterwards()

        let taskID = try addTask(titled: title, minutes: Self.firstDuration)
        XCTAssertEqual(fieldValue(of: durationField(of: taskID)), Self.durationText(Self.firstDuration),
                       "the typed duration isn't on the row")
    }

    func testEmptyNewTaskIsDiscarded() throws {
        try openDayPlan()
        let before = nameFields.count

        tap(element(DayPlan.addTaskButton))
        XCTAssertTrue(waitUntil { self.nameFields.count == before + 1 }, "Add task added no row")
        press(.return)
        XCTAssertTrue(waitUntil { self.nameFields.count == before }, "a task with no name was kept")
    }

    func testTaskDetailsSaveTitleDurationAndNotes() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test detailed task")
        let token = token(of: title)
        cleanUpTestItemsAfterwards()
        let renamed = "UI test renamed task \(token)"
        let notes = "Notes written by a UI test \(token)"

        let taskID = try addTask(titled: title)
        try openDetails(ofTask: taskID)
        replaceText(in: app.textFields[Tasks.taskDetailsTitleField], with: renamed)
        replaceText(in: app.textFields[Tasks.taskDetailsDurationField], with: String(Self.secondDuration))
        tap(app.textViews[Tasks.taskDetailsNotesView])
        typeIntoFocus(notes)
        tap(element(Tasks.taskDetailsSaveButton))
        XCTAssertTrue(waitForNonExistence(of: element(Tasks.taskDetailsSaveButton)), "Save didn't close the details")

        let isRenamed = waitUntil { self.fieldValue(of: self.nameField(of: taskID)) == renamed }
        XCTAssertTrue(isRenamed, "the new title isn't on the row")

        XCTAssertEqual(fieldValue(of: durationField(of: taskID)), Self.durationText(Self.secondDuration),
                       "the new duration isn't on the row")
        try openDetails(ofTask: taskID)
        XCTAssertEqual(fieldValue(of: app.textViews[Tasks.taskDetailsNotesView]), notes, "the notes weren't saved")
        tap(element(Tasks.taskDetailsCancelButton))
    }

    func testTaskDetailsCancelKeepsTheTaskAsItWas() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test unedited task")
        let token = token(of: title)
        cleanUpTestItemsAfterwards()

        let taskID = try addTask(titled: title)
        try openDetails(ofTask: taskID)
        replaceText(in: app.textFields[Tasks.taskDetailsTitleField], with: "UI test discarded title \(token)")
        tap(element(Tasks.taskDetailsCancelButton))
        XCTAssertTrue(waitForNonExistence(of: element(Tasks.taskDetailsCancelButton)), "Cancel didn't close the details")
        XCTAssertEqual(fieldValue(of: nameField(of: taskID)), title, "Cancel kept the edited title")
    }

    func testPlannedTotalFollowsTaskDurations() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test planned task")
        cleanUpTestItemsAfterwards()
        let total = element(Tasks.tasksTotal)
        let before = displayedText(of: total)

        let taskID = try addTask(titled: title, minutes: Self.firstDuration)
        XCTAssertTrue(waitUntil { self.displayedText(of: total) != before }, "adding a timed task didn't change the planned total")
        let withTask = displayedText(of: total)
        replaceText(in: durationField(of: taskID), with: String(Self.secondDuration))
        press(.return)
        XCTAssertTrue(waitUntil { self.displayedText(of: total) != withTask }, "a longer task didn't change the planned total")
    }

    func testProjectTokenOffersToCreateAMissingProject() throws {
        try openDayPlan()
        let before = nameFields.count
        // No project on the account is called this, so the prompt offers to create it.
        let project = "uitestproject" + UUID().uuidString.prefix(8).lowercased()

        tap(element(DayPlan.addTaskButton))
        typeIntoFocus("UI test project token #\(project)")
        let prompt = app.textFields[Tasks.newProjectNameField]
        XCTAssertTrue(appears(prompt), "typing #\(project) offered nothing")
        XCTAssertEqual(fieldValue(of: prompt), project, "the prompt doesn't offer the typed name")

        // Leave without creating anything: close the prompt and empty the name, which discards the row.
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: prompt), "Escape didn't close the prompt")
        press("a", modifiers: .command)
        press(.delete)
        press(.return)
        XCTAssertTrue(waitUntil { self.nameFields.count == before }, "the emptied task wasn't discarded")
    }

    func testReorderingTasksByDragging() throws {
        throw XCTSkip("Reordering is a drag of the row's grip, and the suite has no safe drag: SafeInteraction offers clicks and keys only.")
    }

    // MARK: Completing, removing, moving

    func testCompletingAndUncompletingATask() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test uncompleted task")
        cleanUpTestItemsAfterwards()
        setShowCompleted(true)

        let taskID = try addTask(titled: title)
        let done = app.checkBoxes[taskID]
        tap(done)
        XCTAssertTrue(waitUntil { self.isChecked(done) }, "the task didn't tick")
        tap(done)
        // The server's echo of the tick lands after the untick and must not tick it again (#2690).
        XCTAssertTrue(waitUntil { !self.isChecked(done) }, "the task didn't untick")
        setShowCompleted(false)
        // The plan rebuilds its rows when the setting changes, so give the row that rebuild.
        XCTAssertTrue(appears(nameField(of: taskID)), "an unticked task was hidden with the completed ones")
    }

    func testShowCompletedSettingRevealsDoneTasks() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test hidden done task")
        cleanUpTestItemsAfterwards()

        let taskID = try addTask(titled: title)
        tap(app.checkBoxes[taskID])
        XCTAssertTrue(waitForNonExistence(of: nameField(of: taskID)), "a done task stayed with Show completed off")
        setShowCompleted(true)
        XCTAssertTrue(appears(nameField(of: taskID)), "Show completed didn't bring the done task back")
        XCTAssertTrue(isChecked(app.checkBoxes[taskID]), "the revealed task doesn't read as done")
        setShowCompleted(false)
        XCTAssertTrue(waitForNonExistence(of: nameField(of: taskID)), "turning Show completed off didn't hide it again")
    }

    func testRemoveTakesTheTaskOffThePlan() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test removed task")
        cleanUpTestItemsAfterwards()

        let taskID = try addTask(titled: title)
        tap(try actions(ofTask: taskID).remove)
        XCTAssertTrue(waitForNonExistence(of: nameField(of: taskID)), "Remove left the task on the plan")
    }

    func testSnoozeCancelKeepsTheTaskAndTomorrowMovesIt() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test snoozed task")
        cleanUpTestItemsAfterwards()

        let taskID = try addTask(titled: title)
        tap(try actions(ofTask: taskID).snooze)
        let field = app.textFields[Tasks.snoozeField]
        XCTAssertTrue(appears(field), "Snooze didn't open")
        tap(element(Tasks.snoozeCancelButton))
        XCTAssertTrue(waitForNonExistence(of: field), "Cancel didn't close Snooze")
        XCTAssertTrue(nameField(of: taskID).exists, "cancelling Snooze moved the task")

        tap(try actions(ofTask: taskID).snooze)
        XCTAssertTrue(appears(field), "Snooze didn't open again")
        tap(field)
        typeIntoFocus(Self.tomorrowShorthand)
        tap(element(Tasks.snoozeMoveButton))
        XCTAssertTrue(waitForNonExistence(of: nameField(of: taskID)), "the snoozed task is still on today")
        tap(element(Tasks.nextDayButton))
        XCTAssertTrue(appears(nameField(of: taskID)), "the snoozed task isn't on tomorrow")
    }

    // MARK: Days

    func testDayNavigationPreviousNextAndBackToToday() throws {
        try openDayPlan()
        let date = element(Tasks.dateButton)
        let header = element(Tasks.tasksHeader)
        let backToToday = element(Tasks.backToTodayButton)
        XCTAssertTrue(appears(date), "the Day Plan shows no date")
        let today = displayedText(of: date)
        let todayHeader = displayedText(of: header)
        XCTAssertFalse(backToToday.exists, "“Back to today” is offered on today")

        tap(element(Tasks.nextDayButton))
        XCTAssertTrue(waitUntil { self.displayedText(of: date) != today }, "the next-day arrow didn't change the day")
        let tomorrow = displayedText(of: date)
        XCTAssertTrue(appears(backToToday), "another day offers no “Back to today”")
        XCTAssertNotEqual(displayedText(of: header), todayHeader, "the task list still says it is today's")

        tap(element(Tasks.previousDayButton))
        XCTAssertTrue(waitUntil { self.displayedText(of: date) == today }, "the previous-day arrow didn't come back to today")
        XCTAssertTrue(waitForNonExistence(of: backToToday), "“Back to today” stayed on today")

        tap(element(Tasks.previousDayButton))
        XCTAssertTrue(waitUntil { ![today, tomorrow].contains(self.displayedText(of: date)) }, "the previous-day arrow didn't go to yesterday")
        tap(backToToday)
        XCTAssertTrue(waitUntil { self.displayedText(of: date) == today }, "“Back to today” didn't return to today")
        XCTAssertEqual(displayedText(of: header), todayHeader, "the task list didn't return to today's")
    }

    func testTaskAddedOnAnotherDayStaysOnThatDay() throws {
        try openDayPlan()
        let title = uniqueTitle("UI test tomorrow task")
        cleanUpTestItemsAfterwards()

        tap(element(Tasks.nextDayButton))
        XCTAssertTrue(appears(element(Tasks.backToTodayButton)), "the next-day arrow didn't leave today")
        let taskID = try addTask(titled: title)
        tap(element(Tasks.backToTodayButton))
        XCTAssertTrue(waitForNonExistence(of: nameField(of: taskID)), "tomorrow's task is on today")
        tap(element(Tasks.nextDayButton))
        XCTAssertTrue(appears(nameField(of: taskID)), "tomorrow's task isn't on tomorrow")
    }

    // MARK: Routines (nothing is ever saved)

    func testCustomRoutineManagerOpensAndCancels() throws {
        try openDayPlan()
        let manage = element(Tasks.customRoutinesManageButton)
        guard appears(manage) else {
            throw XCTSkip("The custom routines panel is hidden while a routine is running for the test account.")
        }
        tap(manage)
        let close = element(Tasks.customRoutineManagerCloseButton)
        guard appears(close) else {
            throw XCTSkip("Managing custom routines asks for the settings password on the test account.")
        }
        let newRoutine = element(Tasks.customRoutineNewButton)
        XCTAssertTrue(appears(newRoutine), "the custom routine list has no New")
        tap(newRoutine)
        let name = element(Tasks.customRoutineNameField)
        XCTAssertTrue(appears(name), "New didn't open the routine form")
        tap(name)
        typeIntoFocus(uniqueTitle("UI test routine"))
        tap(element(Tasks.customRoutineEditCancelButton))
        XCTAssertTrue(waitForNonExistence(of: name), "Cancel didn't leave the routine form")
        XCTAssertTrue(appears(newRoutine), "Cancel didn't go back to the routine list")

        tap(close)
        XCTAssertTrue(waitForNonExistence(of: close), "the custom routine manager didn't close")
        XCTAssertFalse(appears(element(Tasks.draftSaveButton), within: Self.optionalWait), "a cancelled routine left unsaved changes")
    }

    func testRoutineTimingChangeIsDiscardedOnCancel() throws {
        let seed = [UITestContract.Environment.presentScreen: UITestContract.PresentedScreen.dayPlanRoutine.rawValue]
        try openDayPlan(environment: seed)
        let menu = element(Editors.routineMenuButton)
        guard appears(menu) else {
            throw XCTSkip("The seeded evening routine isn't in today's Day Plan (it starts after midnight).")
        }
        // The routine menu's first entry edits its timing.
        chooseMenuItem(at: 0, openedBy: menu)
        let cancel = element(Editors.routineTimingCancelButton)
        guard appears(cancel) else {
            throw XCTSkip("Editing routines asks for the settings password on the test account.")
        }
        let cutoff = element(Tasks.routineTimingCutoffToggle)
        XCTAssertTrue(appears(cutoff), "the evening routine's timing has no cut-off switch")
        let wasOn = isChecked(cutoff)
        tap(cutoff)
        XCTAssertTrue(waitUntil { self.isChecked(cutoff) != wasOn }, "the cut-off switch didn't change")

        tap(cancel)
        XCTAssertTrue(waitForNonExistence(of: cancel), "Cancel didn't close the routine timing")
        XCTAssertFalse(appears(element(Tasks.draftSaveButton), within: Self.optionalWait), "a cancelled timing change left unsaved changes")
    }

    // MARK: Helpers

    private static let firstDuration = 45
    private static let secondDuration = 105
    /// The snooze grammar's word for tomorrow — typed, like a user would, not a translated title.
    private static let tomorrowShorthand = "tomorrow"

    /// How a row shows a duration.
    private static func durationText(_ minutes: Int) -> String { "\(minutes)m" }

    private func openDayPlan(environment: [String: String] = [:]) throws {
        try launchSignedIn(environment: environment)
        open(menuItem: UITestContract.Identifier.Menu.dayPlan, expectingAnyOf: element(DayPlan.view))
    }

    private var nameFields: XCUIElementQuery {
        app.textFields.matching(NSPredicate(format: "identifier BEGINSWITH %@", DayPlan.taskNamePrefix))
    }

    private func nameField(of taskID: String) -> XCUIElement {
        app.textFields[DayPlan.taskNamePrefix + taskID]
    }

    private func durationField(of taskID: String) -> XCUIElement {
        app.textFields[DayPlan.taskDurationPrefix + taskID]
    }

    /// The row's name field carries `taskNamePrefix + id`; the id names the row's other controls.
    private func idOfTask(titled title: String) throws -> String {
        let field = nameFields.matching(NSPredicate(format: "value == %@", title)).firstMatch
        XCTAssertTrue(appears(field), "\(title) isn't in the Day Plan")
        return try XCTUnwrap(field.exists ? String(field.identifier.dropFirst(DayPlan.taskNamePrefix.count)) : nil,
                             "\(title) has no task row")
    }

    /// Add task → name → Return, or → name → Tab → minutes → Return when `minutes` is given.
    private func addTask(titled title: String, minutes: Int? = nil) throws -> String {
        tap(element(DayPlan.addTaskButton))
        typeIntoFocus(title)
        if let minutes = minutes {
            press(.tab)
            typeIntoFocus("\(minutes)\n")
        } else {
            typeIntoFocus("\n")
        }
        return try idOfTask(titled: title)
    }

    /// Clicking a task's name reveals Expand · Snooze · Remove under it. They carry the task's id as
    /// their identifier (their actions read it, so it can't be replaced), as can a sub-task count or a
    /// "Move to" hint inside the row above them: the action row is the lowest three, left to right.
    private func actions(ofTask taskID: String) throws -> (expand: XCUIElement, snooze: XCUIElement, remove: XCUIElement) {
        tap(nameField(of: taskID))
        let taskButtons = app.buttons.matching(identifier: taskID)
        XCTAssertTrue(waitUntil { taskButtons.count >= Self.actionCount }, "clicking the task revealed no actions")
        let actionRow = taskButtons.allElementsBoundByIndex
            .sorted { $0.frame.minY > $1.frame.minY }
            .prefix(Self.actionCount)
            .sorted { $0.frame.minX < $1.frame.minX }
        let buttons = try XCTUnwrap(actionRow.count == Self.actionCount ? actionRow : nil, "the task's actions didn't appear")
        return (buttons[0], buttons[1], buttons[2])
    }

    private static let actionCount = 3

    private func openDetails(ofTask taskID: String) throws {
        tap(try actions(ofTask: taskID).expand)
        XCTAssertTrue(appears(app.textFields[Tasks.taskDetailsTitleField]), "Expand didn't open the task details")
    }

    /// The tasks panel's cog holds one switch, Show completed. Its popover closes on a click outside
    /// it, given to the panel's heading, which does nothing with it.
    private func setShowCompleted(_ isOn: Bool) {
        tap(element(Tasks.tasksSettingsButton))
        let showCompleted = element(Tasks.showCompletedCheckbox)
        XCTAssertTrue(appears(showCompleted), "the tasks settings have no Show completed")
        if isChecked(showCompleted) != isOn { tap(showCompleted) }
        XCTAssertTrue(waitUntil { self.isChecked(showCompleted) == isOn }, "Show completed didn't switch")
        tapCenter(of: element(Tasks.tasksHeader))
        XCTAssertTrue(waitForNonExistence(of: showCompleted), "the tasks settings didn't close")
    }

    private func isChecked(_ checkbox: XCUIElement) -> Bool {
        checkbox.exists && ((checkbox.value as? Int) == 1 || (checkbox.value as? Bool) == true)
    }
}
