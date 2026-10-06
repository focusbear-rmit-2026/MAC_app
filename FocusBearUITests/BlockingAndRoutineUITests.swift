//
//  BlockingAndRoutineUITests.swift
//  Focus BearUITests
//
//  Blocking settings, the routine player, the postpone → accountability buddy path, Help and dark
//  mode. The routine tests depend on the time of day: they run when the test account has a routine
//  due and skip, saying so, when it hasn't.
//

import XCTest

final class BlockingAndRoutineUITests: FocusBearUITestCase {
    private typealias Blocking = UITestContract.Identifier.Blocking
    private typealias Routine = UITestContract.Identifier.Routine
    private typealias Settings = UITestContract.Identifier.Settings

    func testBlockListsOpen() throws {
        try openBlocking()
        tap(element(Blocking.blockListsRow))
        XCTAssertTrue(appears(element(Blocking.blockListsEditor)),
                      "the block list editor didn't open")
        attachScreenshot(named: "block lists")
    }

    func testBlockingSchedulesOpen() throws {
        try openBlocking()
        tap(element(Blocking.blockingSchedulesRow))
        XCTAssertTrue(appears(element(Blocking.blockingSchedulesEditor)),
                      "the blocking schedules editor didn't open")
        attachScreenshot(named: "blocking schedules")
    }

    func testRoutinePlayerStartsAndSkipsAHabit() throws {
        try launchSignedIn()
        let start = try routineStartButton()
        tap(start)
        let skip = element(Routine.skipHabitButton)
        XCTAssertTrue(appears(skip), "starting the routine didn't open the player")
        attachScreenshot(named: "routine player")
        tap(skip)
    }

    func testPostponingARoutineAsksTheAccountabilityBuddy() throws {
        try launchSignedIn()
        let postpone = element(Routine.postponeButton)
        guard appears(postpone), postpone.isHittable else {
            throw XCTSkip("No routine is due for the test account, so there is nothing to postpone.")
        }
        tap(postpone)
        let buddy = firstToAppear([element(Routine.accountabilityBuddySheet), app.sheets.firstMatch])
        attachScreenshot(named: "postpone")
        XCTAssertNotNil(buddy, "postponing should ask the accountability buddy")
    }

    /// The AI buddy's chat, up to the point it would call the AI: a message box, and Send held back
    /// until something is typed. Nothing is typed, so no request is made.
    func testAccountabilityBuddyChatWaitsForAMessage() throws {
        try launchSignedIn()
        let postpone = element(Routine.postponeButton)
        guard appears(postpone), postpone.isHittable else {
            throw XCTSkip("No routine is due for the test account, so there is nothing to postpone.")
        }
        tap(postpone)
        let input = element(Routine.buddyChatInput)
        guard appears(input) else {
            throw XCTSkip("The test account uses the human accountability buddy, not the AI chat.")
        }
        XCTAssertFalse(element(Routine.buddyChatSendButton).isEnabled, "Send should wait for a message")
        attachScreenshot(named: "buddy chat")
    }

    func testHelpReportProblemAcceptsADescription() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.help, expectingAnyOf: element(UITestContract.Identifier.Help.tabView))
        let report = element(UITestContract.Identifier.Help.reportProblemText)
        // Tab titles are translated; find the report tab by what it contains.
        // AppKit exposes a tab view's tabs as radio buttons or as tabs, depending on its style.
        let tabView = element(UITestContract.Identifier.Help.tabView)
        let tabs = tabView.radioButtons.allElementsBoundByIndex + tabView.descendants(matching: .tab).allElementsBoundByIndex
        for tab in tabs where !report.isHittable {
            tap(tab)
            _ = appears(report, within: Self.optionalWait)
        }
        if !report.isHittable { recordDiagnostics(named: "help tabs") }
        XCTAssertTrue(report.isHittable, "no Help tab holds the report form")
        // Typed but never submitted: a submitted report would reach the support queue.
        let description = uniqueTitle("UI test description")
        tap(report)
        typeIntoFocus(description)
        XCTAssertEqual(report.value as? String, description)
    }

    func testDarkModeCanBeChosen() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.settings, expectingAnyOf: element(Settings.appearanceTab))
        tap(element(Settings.appearanceTab))
        let popup = app.popUpButtons[Settings.darkModePopup]
        XCTAssertTrue(appears(popup), "the appearance setting is missing")
        let original = popup.value as? String

        let choices = choicesOf(popup)
        guard let other = choices.first(where: { $0 != original }) else {
            throw XCTSkip("The appearance popup offers a single choice.")
        }
        choose(other, in: popup)
        XCTAssertEqual(popup.value as? String, other)
        attachScreenshot(named: "appearance changed")
        if let original { choose(original, in: popup) }   // leave the test account as it was
    }

    // MARK: - Steps

    private func openBlocking() throws {
        try launchSignedIn()
        open(menuItem: UITestContract.Identifier.Menu.blocks, expectingAnyOf: element(Blocking.blockListsRow))
    }

    private func routineStartButton() throws -> XCUIElement {
        guard let start = firstToAppear([element(Routine.startFirstHabitButton), element(Routine.primaryButton)]),
              start.isHittable else {
            throw XCTSkip("No routine is due for the test account at this time of day.")
        }
        return start
    }

    private func choicesOf(_ popup: XCUIElement) -> [String] {
        let titles = openMenu(of: popup)?.map(\.title) ?? []
        press(.escape)
        return titles
    }

    private func choose(_ title: String, in popup: XCUIElement) {
        chooseMenuItem(titled: title, openedBy: popup)
    }
}
