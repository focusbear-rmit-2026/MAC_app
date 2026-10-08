//
//  ToolsUITests.swift
//  Focus BearUITests
//
//  The TOOLS section and the other screens reached from outside the main sidebar list.
//

import XCTest

final class ToolsUITests: FocusBearUITestCase {
    private typealias Tools = UITestContract.Identifier.Tools

    func testEveryStatsTabRenders() throws {
        try launchSignedIn()
        try open(tool: Tools.stats)
        let tabs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", UITestContract.Identifier.Stats.tabPrefix))
        XCTAssertTrue(appears(tabs.firstMatch), "Stats shows no tabs")
        let content = element(UITestContract.Identifier.Stats.content)
        for tab in tabs.allElementsBoundByIndex {
            tap(tab)
            XCTAssertTrue(appears(content), "\(tab.identifier) rendered nothing")
            attachScreenshot(named: tab.identifier)
        }
    }

    func testNoteCanBeCreatedAndDeleted() throws {
        typealias Notes = UITestContract.Identifier.Notes
        try launchSignedIn()
        try open(tool: Tools.notes)
        let title = uniqueTitle("UI test note")

        tap(element(Notes.newNoteButton))
        let titleField = app.textFields[Notes.editorTitleField]
        XCTAssertTrue(appears(titleField), "the note editor didn't open")
        tap(titleField)
        typeIntoFocus(title)
        tap(element(Notes.editorSaveButton))

        let row = app.descendants(matching: .any).matching(identifier: Notes.row)
            .containing(showing(title)).firstMatch
        XCTAssertTrue(appears(row, within: Self.apiRoundTripTimeout, waitsOnNetwork: true), "the saved note isn't listed")
        tap(row.descendants(matching: .any).matching(identifier: Notes.deleteButton).firstMatch)
        confirmDestructiveAlert()
        XCTAssertTrue(waitForNonExistence(of: row), "the deleted note is still listed")
    }

    func testFocusMusicOpens() throws {
        try launchSignedIn()
        try open(tool: Tools.focusMusic)
        attachScreenshot(named: "focus music")
    }

    func testFocusButtonToolOpens() throws {
        try launchSignedIn()
        try open(tool: Tools.focusButton)
        attachScreenshot(named: "focus button")
    }

    /// The habit and routine editor is the web dashboard's, in a web view. It is opened and seen to
    /// load; editing inside it belongs to the web app's own tests.
    func testHabitEditorLoads() throws {
        try launchSignedIn()
        try open(tool: Tools.editHabits)
        XCTAssertTrue(appears(app.webViews.firstMatch), "the habit editor's page didn't load")
        attachScreenshot(named: "edit habits")
    }

    func testMenuBarPopoverOffersTheMainActions() throws {
        typealias MenuBar = UITestContract.Identifier.MenuBar
        try present(.menuBarPopover, landmark: MenuBar.quitButton)
        XCTAssertTrue(element(MenuBar.openDayPlanButton).exists, "the popover has no way to the full Day Plan")
        attachScreenshot(named: "menu bar popover")
        press(.escape)
    }

    /// The local reports list is only built for the developer account (LocalReportCapability).
    func testLocalReportsListShowsForTheDeveloperAccount() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.help, expectingAnyOf: element(UITestContract.Identifier.Help.tabView))
        guard appears(element(UITestContract.Identifier.Help.localReportsTable)) else {
            throw XCTSkip("Local reports are enabled only for the developer's own account, not the test account.")
        }
        attachScreenshot(named: "local reports")
    }
}
