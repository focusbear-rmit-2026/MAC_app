//
//  RegressionMenuBarUITests.swift
//  Focus BearUITests
//
//  Regression suite: The menu-bar menu. Runs in the Regression test plan; the critical path is in Smoke.
//
//  The popover opens through the test hook (`PresentedScreen.menuBarPopover`), anchored to the main
//  window: the menu-bar icon itself is never clicked. Nothing here starts a session or a break, records
//  from the microphone or quits the app.
//

import XCTest

final class RegressionMenuBarUITests: SettingsAreaUITestCase {
    private typealias MenuBar = UITestContract.Identifier.MenuBar

    // MARK: - Opening and closing

    func testPopoverShowsItsSections() throws {
        try presentPopover()
        for (identifier, section) in [(Area.menuBreaksRow, "Breaks"), (Area.menuDayPlanRow, "Day Plan"), (Area.menuToolsRow, "Focus Tools"),
                                      (MenuBar.openDayPlanButton, "expand"), (Area.menuPinButton, "pin"), (MenuBar.quitButton, "quit")] {
            XCTAssertTrue(element(identifier).exists, "the popover has no \(section)")
        }
        attachScreenshot(named: "menu bar popover")
    }

    func testEscapeClosesThePopover() throws {
        let quit = try presentPopover()
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: quit), "Escape didn't close the popover")
        XCTAssertNotEqual(app.state, .notRunning, "closing the popover quit the app")
    }

    /// The power button raises the quit popup instead of quitting; closing that popup keeps the app running.
    func testQuitAsksFirstAndCanBeCancelled() throws {
        let quit = try presentPopover()
        tap(quit)
        let popup = element(Area.quitPopup)
        XCTAssertTrue(appears(popup), "Quit didn't ask first")
        attachScreenshot(named: "quit popup")
        let popupWindow = window(containing: Area.quitPopup)
        tap(popupWindow.buttons[XCUIIdentifierCloseWindow])
        XCTAssertTrue(waitForNonExistence(of: popup), "the quit popup didn't close")
        XCTAssertNotEqual(app.state, .notRunning, "cancelling the quit popup quit the app")
        XCTAssertTrue(app.buttons[Menu.dayPlan].exists, "the main window went away with the quit popup")
    }

    // MARK: - Header buttons

    func testExpandButtonOpensTheDayPlan() throws {
        let quit = try presentPopover()
        tap(element(MenuBar.openDayPlanButton))
        XCTAssertTrue(waitForNonExistence(of: quit), "the popover stayed open")
        XCTAssertTrue(appears(element(UITestContract.Identifier.DayPlan.view)), "expanding didn't show the Day Plan")
    }

    /// Pin turns the popover into a window that stays open; pinning again puts it back. The hook
    /// already chose the popover for this launch, so two presses leave the setting as the hook set it.
    func testPinTurnsThePopoverIntoAWindowAndBack() throws {
        let quit = try presentPopover()
        // A running session's "Focus mode ends in…" window opens a minute before the end and takes the
        // focus, which closes the transient popover mid-test, so the test needs the account idle.
        try requireNothingRunning(because: "its end-of-session warning can open over the menu and close it")
        XCTAssertTrue(isInPopover(quit), "the menu should start as a popover")

        let pin = element(Area.menuPinButton)
        tap(pin)
        XCTAssertTrue(appears(quit), "pinning closed the menu")
        waitUntil { !self.isInPopover(quit) }
        XCTAssertFalse(isInPopover(quit), "pinning didn't turn the menu into a window")
        attachScreenshot(named: "menu pinned as a window")

        // The pinned window opens under the menu-bar icon, which can sit at the top edge of the screen.
        guard pin.isHittable, pin.frame.minY >= Self.menuBarHeight else {
            throw XCTSkip("The pinned menu opened against the menu bar, where the suite never clicks, so it wasn't unpinned.")
        }
        tap(pin)
        // Unpinned, the menu is a popover again — anchored to the menu-bar icon, so possibly off screen.
        waitUntil { self.isInPopover(quit) || !quit.exists }
        XCTAssertTrue(isInPopover(quit) || !quit.exists, "pinning again left the menu as a window")
    }

    /// Voice input is offered to trial and subscription users only. The button is never pressed — it
    /// would start recording.
    func testMicButtonIsOfferedToTrialUsers() throws {
        try presentPopover()
        guard element(Area.menuMicButton).exists else {
            throw XCTSkip("The test account has no trial or subscription, so voice input isn't offered.")
        }
        XCTAssertTrue(element(Area.menuMicButton).isEnabled, "the mic button is disabled")
    }

    // MARK: - Sections

    func testFocusStarterOpensWithoutStartingASession() throws {
        try presentPopover()
        try requireNothingRunning(because: "the popover offers no Start")
        tap(element(Area.menuStartFocusButton))
        XCTAssertTrue(appears(element(Area.menuFocusGoalField)), "Start didn't ask for a focus goal")
        XCTAssertFalse(element(UITestContract.Identifier.FocusSession.endButton).exists, "opening the starter started a session")
        attachScreenshot(named: "focus starter")
    }

    /// The Breaks section opens to its details; "Start a break now" is looked at, never pressed.
    func testBreaksSectionOpens() throws {
        try presentPopover()
        let dayPlanLink = element(Area.menuViewFullDayPlanLink)
        tap(element(Area.menuDayPlanRow))
        XCTAssertTrue(appears(dayPlanLink), "the Day Plan section didn't open")
        tap(element(Area.menuBreaksRow))
        // One section is open at a time, so opening Breaks closes the Day Plan.
        XCTAssertTrue(waitForNonExistence(of: dayPlanLink), "opening Breaks didn't close the Day Plan section")
        let startBreak = element(Area.menuStartBreakLink)
        if startBreak.exists {
            XCTAssertTrue(startBreak.isEnabled, "Start a break now is disabled")
        }
        attachScreenshot(named: "breaks section")
    }

    func testDayPlanSectionOpensTheFullDayPlan() throws {
        let quit = try presentPopover()
        tap(element(Area.menuDayPlanRow))
        let link = element(Area.menuViewFullDayPlanLink)
        XCTAssertTrue(appears(link), "the Day Plan section didn't open")
        tap(link)
        XCTAssertTrue(waitForNonExistence(of: quit), "the popover stayed open")
        XCTAssertTrue(appears(element(UITestContract.Identifier.DayPlan.view)), "View full day plan didn't show the Day Plan")
    }

    func testFocusToolsOpenNotes() throws {
        try openFocusTool(Area.menuNotesButton)
        XCTAssertTrue(appears(element(UITestContract.Identifier.Notes.newNoteButton)), "Notes didn't open in the main window")
    }

    func testFocusToolsOpenTheToDoList() throws {
        try openFocusTool(Area.menuToDoPlayerButton, requiringNothingRunning: "My tasks opens the running session's queue instead")
        XCTAssertTrue(appears(element(UITestContract.Identifier.ToDo.newTaskButton)), "the to-do list didn't open in the main window")
    }

    /// Focus Music has no landmark of its own, so the check is that the main window left the Day Plan for it.
    func testFocusToolsOpenFocusMusic() throws {
        let dayPlan = element(UITestContract.Identifier.DayPlan.view)
        try openFocusTool(Area.menuFocusMusicButton, whileShowing: dayPlan)
        XCTAssertTrue(waitForNonExistence(of: dayPlan), "Focus Music didn't replace the Day Plan in the main window")
        attachScreenshot(named: "focus music")
    }

    // MARK: - Steps

    /// The popover, open over the signed-in app. Returns its Quit button, the one control every state has.
    @discardableResult
    private func presentPopover() throws -> XCUIElement {
        try present(.menuBarPopover, landmark: MenuBar.quitButton)
    }

    /// Skips while a focus session or a routine runs for the test account: the popover then shows no
    /// Start. A session another test ended is still running on the server until its completion screen
    /// is closed (only that sends the finish), and every launch resumes it from there.
    private func requireNothingRunning(because consequence: String) throws {
        guard element(Area.menuStartFocusButton).exists else {
            throw XCTSkip("A session or a routine is running for the test account, so \(consequence).")
        }
    }

    private func isInPopover(_ element: XCUIElement) -> Bool {
        app.popovers.containing(.any, identifier: element.identifier).firstMatch.exists
    }

    /// Opens the Focus Tools section and presses one of its tools, which closes the popover. With
    /// `whileShowing`, skips unless the main window shows that screen first, so the change is visible;
    /// with `requiringNothingRunning`, skips while a session or routine runs, naming what it changes.
    private func openFocusTool(_ tool: String, whileShowing landmark: XCUIElement? = nil,
                               requiringNothingRunning consequence: String? = nil) throws {
        let quit = try presentPopover()
        if let landmark, !landmark.exists {
            throw XCTSkip("The main window isn't on the Day Plan (a routine is due), so a change of screen can't be seen.")
        }
        if let consequence { try requireNothingRunning(because: consequence) }
        tap(element(Area.menuToolsRow))
        let button = element(tool)
        XCTAssertTrue(appears(button), "the Focus Tools section didn't open")
        tap(button)
        XCTAssertTrue(waitForNonExistence(of: quit), "the popover stayed open")
    }
}
