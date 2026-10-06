//
//  DayPlanEditorsUITests.swift
//  Focus BearUITests
//
//  The sheets the Day Plan opens. Each is opened, touched, and cancelled: nothing is saved, and no
//  calendar event is ever created. The routine they edit is a fixture held in memory
//  (`PresentedScreen.dayPlanRoutine`), because the test account has no routine of its own.
//

import XCTest

final class DayPlanEditorsUITests: FocusBearUITestCase {
    private typealias Editors = UITestContract.Identifier.DayPlanEditors

    func testHabitEditorOpensAndCancels() throws {
        try openDayPlan(seedingRoutine: true)
        let edit = try XCTUnwrap(revealHabitEditButton(), "the seeded habit has no Edit action in the Day Plan")
        tap(edit)
        let name = app.textFields[Editors.habitNameField]
        guard appears(name) else {
            throw XCTSkip("Editing habits asks for the settings password on the test account.")
        }
        tap(name)
        typeIntoFocus(" (edited by a UI test)")
        attachScreenshot(named: "habit editor")
        tap(element(Editors.habitEditorCancelButton))
        XCTAssertTrue(waitForNonExistence(of: name), "Cancel didn't close the habit editor")
    }

    func testRoutineTimingOpensAndCancels() throws {
        try openDayPlan(seedingRoutine: true)
        let menu = element(Editors.routineMenuButton)
        XCTAssertTrue(appears(menu), "the seeded routine has no “…” menu")
        // The routine menu's first entry edits its timing.
        chooseMenuItem(at: 0, openedBy: menu)
        let cancel = element(Editors.routineTimingCancelButton)
        guard appears(cancel) else {
            throw XCTSkip("Editing routines asks for the settings password on the test account.")
        }
        attachScreenshot(named: "routine timing")
        tap(cancel)
        XCTAssertTrue(waitForNonExistence(of: cancel), "Cancel didn't close the routine timing sheet")
    }

    func testAddEventFormOpensAndCloses() throws {
        try openDayPlan()
        let addEvent = element(Editors.addEventButton)
        XCTAssertTrue(appears(addEvent), "the Day Plan has no Add event")
        tap(addEvent)
        let close = element(Editors.eventFormCloseButton)
        guard appears(close) else {
            throw XCTSkip("The test app has no calendar access on this Mac, so there is no event form to open.")
        }
        attachScreenshot(named: "add event form")
        tap(close)
        XCTAssertTrue(waitForNonExistence(of: close), "the event form didn't close")
    }

    /// `seedingRoutine` puts a two-habit evening routine into today's Day Plan, in memory only.
    private func openDayPlan(seedingRoutine: Bool = false) throws {
        let seed = [UITestContract.Environment.presentScreen: UITestContract.PresentedScreen.dayPlanRoutine.rawValue]
        try launchSignedIn(environment: seedingRoutine ? seed : [:])
        open(menuItem: UITestContract.Identifier.Menu.dayPlan, expectingAnyOf: element(UITestContract.Identifier.DayPlan.view))
    }
}
