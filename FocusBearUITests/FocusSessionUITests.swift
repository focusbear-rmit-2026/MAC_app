//
//  FocusSessionUITests.swift
//  Focus BearUITests
//
//  The Focus Start screen and one short session. The test app enforces nothing (UITestHost), so a
//  session started here blocks nothing on the machine running the suite.
//

import XCTest

final class FocusSessionUITests: FocusBearUITestCase {
    private typealias FocusStart = UITestContract.Identifier.FocusStart
    private typealias FocusSession = UITestContract.Identifier.FocusSession
    private static let typedMinutes = "45"
    private static let shortSessionMinutes = "5"

    func testTypingADurationSetsIt() throws {
        try openFocusStart()
        setMinutes(to: Self.typedMinutes)
        // SwiftUI Text reports its string as the value, not the label.
        let minutes = element(FocusStart.durationMinutes)
        XCTAssertTrue(appears(minutes), "the minutes didn't come back after typing")
        XCTAssertEqual(minutes.value as? String, Self.typedMinutes)
    }

    func testFocusGoalCanBeSetAndCleared() throws {
        try openFocusStart()
        try openGoalCard()
        let goalField = app.textFields[FocusStart.goalField]
        XCTAssertTrue(appears(goalField), "the goal field is missing")
        tap(goalField)
        typeIntoFocus(uniqueTitle("UI test goal") + "\n")

        let clear = element(FocusStart.clearGoalButton)
        XCTAssertTrue(appears(clear), "the typed goal wasn't taken")
        attachScreenshot(named: "goal set")
        tap(clear)
        XCTAssertTrue(appears(goalField), "clearing the goal should offer the field again")
    }

    func testTaskPickerOffersTasks() throws {
        try openFocusStart()
        try openGoalCard()
        let addMore = element(FocusStart.addMoreTasksButton)
        if appears(addMore) { tap(addMore) }
        XCTAssertTrue(appears(app.textFields[FocusStart.taskSearchField]),
                      "the task search didn't open")
        let suggestion = element(FocusStart.taskSuggestion)
        guard appears(suggestion, within: Self.apiRoundTripTimeout, waitsOnNetwork: true) else {
            throw XCTSkip("The test account has no open to-dos to pick from.")
        }
        tap(suggestion)
        attachScreenshot(named: "task picked")
    }

    func testStartAndEndASession() throws {
        try openFocusStart()
        setMinutes(to: Self.shortSessionMinutes)
        tap(element(FocusStart.startButton))
        declineBlockingOfferIfShown()

        XCTAssertTrue(appears(element(FocusSession.endButton)), "the session didn't start")
        attachScreenshot(named: "session running")
        endFocusSession()
        // Only leaving the end screen tells the server the session is over; quitting on it would hand
        // the session back to the next test's launch.
        leaveFocusEndScreen()
    }

    // MARK: - Steps

    /// Signed in on Focus Start. A session an earlier test or run left on the account is ended rather
    /// than skipped over, and one this test starts is ended when it finishes, pass or fail.
    private func openFocusStart() throws {
        try launchSignedIn()
        addTeardownBlock { [weak self] in self?.finishAnyFocusSession() }
        openFocusStartEndingAnyRunningSession()
    }

    /// The goal card is on the advanced screen; the simple one links to it.
    private func openGoalCard() throws {
        let card = element(FocusStart.goalCard)
        if !card.exists { tap(element(FocusStart.modeLink)) }
        XCTAssertTrue(appears(card), "the goal card is missing")
        // The header toggles, so only press it while the card is shut.
        let isOpen = app.textFields[FocusStart.goalField].exists || element(FocusStart.clearGoalButton).exists
        if !isOpen { tap(card) }
        clearAnyRememberedGoal()
    }

    private func setMinutes(to minutes: String) {
        let shown = element(FocusStart.durationMinutes)
        XCTAssertTrue(appears(shown), "the duration dial is missing")
        tap(shown)
        let field = app.textFields[FocusStart.durationField]
        XCTAssertTrue(appears(field), "clicking the minutes didn't make them editable")
        typeIntoFocus(minutes + "\n")
    }
}
