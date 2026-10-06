//
//  RegressionFocusSessionUITests.swift
//  Focus BearUITests
//
//  Regression suite: Focus sessions. Runs in the Regression test plan; the critical path is in Smoke.
//
//  The Focus Start screen (duration, goal, tasks, block list), a running session (pause, extend,
//  the end confirmation, its task picker, goal and notes) and the end screen. The test app enforces
//  nothing (UITestHost), so a session started here blocks nothing on the machine running the suite.
//  A session left running spoils every later test, so each test ends one it finds before it starts
//  and the one it started when it finishes, pass or fail — leaving its end screen too, since only
//  that tells the server the session is over (see the Focus sessions helpers in UITestSupport).
//

import XCTest

final class RegressionFocusSessionUITests: FocusBearUITestCase {
    private typealias FocusStart = UITestContract.Identifier.FocusStart
    private typealias FocusSession = UITestContract.Identifier.FocusSession
    private typealias Ids = UITestContract.Identifier.SessionsRegression
    private typealias Menu = UITestContract.Identifier.Menu

    /// The shortest session worth starting: long enough to read, ended by the test long before it's up.
    private static let shortSessionMinutes = 5
    /// A starting length clear of the dial's ends, so a step either way isn't clamped.
    private static let knownMinutes = 30
    /// One press of the start screen's − / + and of the session's −5 / +5 (`FocusStartDuration.stepMinutes`,
    /// `focusSessionDurationStepMinutes`).
    private static let stepMinutes = 5
    /// Typed into the minutes box: more than an hour, which rolls over into the hours.
    private static let rolledOverMinutes = 90
    private static let typedHours = 2
    private static let abandonedMinutes = 12
    private static let minutesPerHour = 60
    private static let noHours = 0
    private static let ratingStars = 4

    // MARK: - Focus Start: duration

    func testDefaultDurationStartsAndEndsASession() throws {
        try openFocusStart()
        let defaultMinutes = sessionMinutes()
        XCTAssertGreaterThan(defaultMinutes, 0, "the start screen offers no session length")
        tap(element(FocusStart.startButton))
        declineBlockingOfferIfShown()
        XCTAssertTrue(appears(element(Ids.pauseButton)), "the session didn't start")
        let countdown = element(Ids.countdown)
        XCTAssertTrue(sessionsTextChanges(countdown, from: sessionsText(of: countdown)), "the session's countdown isn't counting")
        if defaultMinutes < Self.minutesPerHour {
            XCTAssertEqual(Self.integers(in: sessionsText(of: element(Ids.progress))).last, defaultMinutes,
                           "the session isn't as long as the start screen said")
        }
        attachScreenshot(named: "default session running")
        endFocusSession()
        XCTAssertTrue(appears(element(Ids.completedScreen)), "ending the session didn't show the end screen")
    }

    func testPlusAndMinusStepTheDuration() throws {
        try openFocusStart()
        setDuration(minutes: Self.knownMinutes)
        tap(element(Ids.durationPlusButton))
        XCTAssertEqual(sessionMinutes(), Self.knownMinutes + Self.stepMinutes, "+ didn't add a step")
        tap(element(Ids.durationMinusButton))
        tap(element(Ids.durationMinusButton))
        XCTAssertEqual(sessionMinutes(), Self.knownMinutes - Self.stepMinutes, "− didn't take a step off")
    }

    /// Typing 90 into the minutes means an hour and a half; typing into the hours keeps the minutes.
    func testTypedMinutesRollOverAndTypedHoursKeepThem() throws {
        try openFocusStart()
        setDuration(minutes: Self.rolledOverMinutes)
        XCTAssertEqual(sessionMinutes(), Self.rolledOverMinutes, "90 typed minutes didn't become 1 hr 30")
        let leftoverMinutes = Self.rolledOverMinutes % Self.minutesPerHour
        enterNumber(Self.typedHours, into: FocusStart.durationHours)
        XCTAssertEqual(sessionMinutes(), Self.typedHours * Self.minutesPerHour + leftoverMinutes,
                       "typing the hours lost the minutes")
    }

    func testEscapeAbandonsATypedDuration() throws {
        try openFocusStart()
        setDuration(minutes: Self.knownMinutes)
        let field = beginTyping(into: FocusStart.durationMinutes)
        typeIntoFocus(String(Self.abandonedMinutes))
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: field), "Escape didn't close the minutes field")
        XCTAssertEqual(sessionMinutes(), Self.knownMinutes, "Escape kept the half-typed minutes")
    }

    /// With Full Keyboard Access the slider is one Tab stop: → adds time, ← takes it off.
    func testDurationSliderStepsWithArrowKeys() throws {
        guard isFullKeyboardAccessOn else {
            throw XCTSkip("Keyboard navigation is off in System Settings → Keyboard, so Tab can't reach the slider.")
        }
        try openFocusStart()
        showFocusStartDurationCard()
        setDuration(minutes: Self.knownMinutes)
        let slider = element(UITestContract.Identifier.Screen.shown(byMenuItem: Menu.focusSession)).sliders.firstMatch
        guard appears(slider), tab(to: slider) else {
            throw KeyboardUnreachable(screen: "Focus start", what: "can't reach with Tab: the duration slider")
        }
        press(.rightArrow, on: slider)
        XCTAssertGreaterThan(sessionMinutes(), Self.knownMinutes, "→ on the slider didn't add time")
        press(.leftArrow, on: slider)
        XCTAssertEqual(sessionMinutes(), Self.knownMinutes, "← on the slider didn't take the time back off")
    }

    func testUntimedModeReplacesTheClock() throws {
        try openFocusStart()
        openAdvancedScreen()
        let untimed = element(Ids.untimedToggle)
        XCTAssertTrue(appears(untimed), "the advanced screen has no untimed switch")
        tap(untimed)
        XCTAssertTrue(waitForNonExistence(of: element(FocusStart.durationMinutes)), "untimed mode still shows a clock")
        XCTAssertFalse(element(Ids.durationPlusButton).isEnabled, "+ still works in untimed mode")
        attachScreenshot(named: "untimed")
        tap(untimed)
        XCTAssertTrue(appears(element(FocusStart.durationMinutes)), "switching untimed off didn't bring the clock back")
    }

    // MARK: - Focus Start: goal, tasks, block list

    func testGoalCanBeSetEditedAndCleared() throws {
        try openFocusStart()
        openGoalCard()
        let goal = uniqueTitle("UI test goal")
        chooseGoal(goal)

        tap(element(Ids.editGoalButton))
        let goalField = app.textFields[FocusStart.goalField]
        XCTAssertTrue(appears(goalField), "the pencil didn't reopen the goal field")
        XCTAssertEqual(goalField.value as? String, goal, "editing the goal didn't start from the goal")
        tap(goalField)
        press("a", modifiers: .command)
        let changed = uniqueTitle("UI test changed goal")
        typeIntoFocus(changed + "\n")
        XCTAssertTrue(appears(selectedGoal(showing: changed)), "the changed goal wasn't taken")

        tap(element(FocusStart.clearGoalButton))
        XCTAssertTrue(appears(goalField), "clearing the goal should offer the field again")
    }

    func testGoalIsCarriedIntoTheSession() throws {
        try openFocusStart()
        openGoalCard()
        let goal = uniqueTitle("UI test session goal")
        chooseGoal(goal)
        startSession()
        XCTAssertTrue(goalCardShows(goal), "the session doesn't show the goal chosen")
        endFocusSession()
    }

    func testPickedTaskCanBeRemoved() throws {
        try openFocusStart()
        openGoalCard()
        let addMore = element(FocusStart.addMoreTasksButton)
        if appears(addMore) { tap(addMore) }
        let suggestion = element(FocusStart.taskSuggestion)
        guard appears(suggestion, within: Self.apiRoundTripTimeout, waitsOnNetwork: true) else {
            throw XCTSkip("The test account has no open to-dos to pick from.")
        }
        tap(suggestion)
        let picked = element(Ids.selectedTask)
        XCTAssertTrue(appears(picked), "the picked task isn't listed for the session")
        tap(element(Ids.removeTaskButton))
        XCTAssertTrue(waitForNonExistence(of: picked), "✕ didn't take the task off the session")
    }

    func testAnotherBlockListCanBeChosen() throws {
        try openFocusStart()
        openAdvancedScreen()
        tap(element(Ids.blockingCard))
        let chosenName = element(Ids.selectedBlockListName)
        XCTAssertTrue(appears(chosenName), "the blocking card doesn't say which block list the session uses")
        let choices = app.descendants(matching: .any).matching(identifier: Ids.blockListChoice).allElementsBoundByIndex
        guard choices.count > 1 else { throw XCTSkip("The test account has only one block list.") }
        let original = sessionsText(of: chosenName)
        tap(choices[0])
        let first = sessionsText(of: chosenName)
        tap(choices[1])
        let second = sessionsText(of: chosenName)
        XCTAssertNotEqual(first, second, "choosing another block list didn't change the session's block list")
        attachScreenshot(named: "block list chosen")
        if let originalChoice = choices.first(where: { $0.label.contains(original) }) { tap(originalChoice) }
    }

    // MARK: - Running session

    func testSessionPausesAndResumes() throws {
        try openFocusStart()
        startSession()
        tap(element(Ids.pauseButton))
        let resume = element(Ids.resumeButton)
        XCTAssertTrue(appears(resume), "pausing didn't offer Resume (a strict session asks first)")
        XCTAssertTrue(element(FocusSession.endButton).exists, "a paused session can't be stopped")
        attachScreenshot(named: "paused")
        tap(resume)
        XCTAssertTrue(appears(element(Ids.pauseButton)), "resuming didn't bring back Pause")
        endFocusSession()
    }

    func testExtendAndReduceChangeTheSessionLength() throws {
        try openFocusStart()
        startSession()
        XCTAssertTrue(sessionTotal(becomes: Self.shortSessionMinutes), "the session isn't as long as was set")
        tap(element(Ids.extendButton))
        XCTAssertTrue(sessionTotal(becomes: Self.shortSessionMinutes + Self.stepMinutes), "+5 didn't extend the session")

        tap(element(Ids.reduceButton))
        XCTAssertTrue(sessionTotal(becomes: Self.shortSessionMinutes), "−5 didn't shorten the session")

        endFocusSession()
    }

    func testCancellingTheEndConfirmationKeepsTheSession() throws {
        try openFocusStart()
        startSession()
        tap(element(FocusSession.endButton))
        let cancel = element(Ids.endCancelButton)
        XCTAssertTrue(appears(cancel), "ending the session didn't ask to confirm")
        tap(cancel)
        XCTAssertTrue(waitForNonExistence(of: cancel), "Cancel didn't close the confirmation")
        XCTAssertTrue(element(Ids.pauseButton).exists, "cancelling ended the session anyway")
        endFocusSession()
    }

    func testSessionTaskPickerOpensAndCloses() throws {
        try openFocusStart()
        startSession()
        let addTask = element(Ids.addFirstTaskButton)
        XCTAssertTrue(appears(addTask), "a session without tasks doesn't offer to add one")
        tap(addTask)
        let close = element(Ids.taskPickerCloseButton)
        XCTAssertTrue(appears(close), "the task picker didn't open")
        attachScreenshot(named: "task picker")
        tap(close)
        XCTAssertTrue(waitForNonExistence(of: close), "✕ didn't close the task picker")
        endFocusSession()
    }

    func testGoalCanBeTypedDuringTheSession() throws {
        try openFocusStart()
        startSession()
        tap(goalToggle)
        let editor = element(Ids.goalEditor)
        XCTAssertTrue(appears(editor), "opening the goal card shows no editor")
        // A real click: #2691 was a border drawn over the editor taking it.
        clickWithPointer(editor)
        let goal = uniqueTitle("UI test goal typed in session")
        let focusPredicate = "hasKeyboardFocus == true"
        let focused = app.descendants(matching: .any).matching(NSPredicate(format: focusPredicate)).firstMatch
        guard wait(for: editor, toMatch: focusPredicate, timeout: Self.screenTimeout) else {
            recordDiagnostics(named: "goal editor not focused")
            return XCTFail("clicking the goal editor didn't give it the keyboard; focus is on \(focused.exists ? focused.debugDescription : "nothing")")
        }
        typeIntoFocus(goal)
        tap(goalToggle)
        XCTAssertTrue(goalCardShows(goal), "the closed goal card doesn't show the typed goal")
        endFocusSession()
    }

    /// The notes lightbox has no Close of its own (#2598 dropped it for the title-bar close, which a
    /// sheet doesn't have), so Escape is the way out.
    func testSessionNotesOpenAndCloseWithEscape() throws {
        try openFocusStart()
        startSession()
        tap(element(Ids.notesButton))
        let notes = element(UITestContract.Identifier.Notes.newNoteButton)
        XCTAssertTrue(appears(notes), "Notes didn't open over the session")
        attachScreenshot(named: "session notes")
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: notes), "Escape doesn't close the notes over the session")
        endFocusSession()
    }

    // MARK: - End screen

    func testEndScreenStartsAnotherSession() throws {
        try openFocusStart()
        startSession()
        endFocusSession()
        let startAnother = element(Ids.completedStartAnotherButton)
        XCTAssertTrue(appears(startAnother), "the end screen doesn't offer another session")
        tap(startAnother)
        XCTAssertTrue(appears(element(FocusStart.startButton)), "Start new focus session didn't open the start screen")
    }

    func testEndScreenTakesAnAchievementAndARating() throws {
        try openFocusStart()
        startSession()
        endFocusSession()
        let achievement = element(Ids.completedAchievementField)
        let toggle = element(Ids.completedAchievementToggle)
        XCTAssertTrue(appears(toggle), "the end screen has no achievement section")
        if !achievement.exists { tap(toggle) }
        XCTAssertTrue(appears(achievement), "opening the section shows no achievement field")
        tap(achievement)
        let text = uniqueTitle("UI test achievement")
        typeIntoFocus(text)
        XCTAssertEqual(achievement.value as? String, text, "the achievement wasn't typed")
        tap(element(Ids.completedRatingStarPrefix + String(Self.ratingStars)))
        attachScreenshot(named: "achievement and rating")
        tap(element(Ids.completedCloseButton))
        XCTAssertTrue(waitForNonExistence(of: element(Ids.completedScreen)), "closing the end screen left it up")
    }

    // MARK: - Steps

    /// Signed in on Focus Start with no session running — one left by an earlier test is ended first.
    private func openFocusStart() throws {
        try launchSignedIn()
        addTeardownBlock { [weak self] in self?.finishAnyFocusSession() }
        openFocusStartEndingAnyRunningSession()
    }

    /// The goal card and the untimed switch are on the advanced screen; the simple one links to it.
    private func openAdvancedScreen() {
        let card = element(FocusStart.goalCard)
        if !card.exists { tap(element(FocusStart.modeLink)) }
        XCTAssertTrue(appears(card), "the advanced start screen didn't open")
    }

    private func openGoalCard() {
        openAdvancedScreen()
        // The header toggles, so only press it while the card is shut.
        if !isGoalCardOpen { tap(element(FocusStart.goalCard)) }
        clearAnyRememberedGoal()
    }

    private var isGoalCardOpen: Bool {
        app.textFields[FocusStart.goalField].exists || element(FocusStart.clearGoalButton).exists
    }

    private func chooseGoal(_ goal: String) {
        let goalField = app.textFields[FocusStart.goalField]
        XCTAssertTrue(appears(goalField), "the goal field is missing")
        tap(goalField)
        typeIntoFocus(goal + "\n")
        XCTAssertTrue(appears(selectedGoal(showing: goal)), "the typed goal wasn't taken")
    }

    private func selectedGoal(showing goal: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: Ids.selectedGoal).matching(showing(goal)).firstMatch
    }

    /// One card is open at a time; shutting the goal card opens the duration card again.
    private func startSession(minutes: Int = shortSessionMinutes) {
        showFocusStartDurationCard()
        setDuration(minutes: minutes)
        tap(element(FocusStart.startButton))
        declineBlockingOfferIfShown()
        XCTAssertTrue(appears(element(Ids.pauseButton)), "the session didn't start")
    }

    /// Sets the dial to `minutes` in total: the minutes box rolls anything over an hour into the hours.
    private func setDuration(minutes: Int) {
        if sessionHours() != Self.noHours { enterNumber(Self.noHours, into: FocusStart.durationHours) }
        enterNumber(minutes, into: FocusStart.durationMinutes)
    }

    private func enterNumber(_ number: Int, into readout: String) {
        beginTyping(into: readout)
        typeIntoFocus(String(number) + "\n")
    }

    /// Clicking a half of the readout swaps it for a field, which takes focus on the next run-loop turn.
    @discardableResult
    private func beginTyping(into readout: String) -> XCUIElement {
        let shown = element(readout)
        XCTAssertTrue(appears(shown), "the duration dial is missing")
        tap(shown)
        let field = app.textFields[FocusStart.durationField]
        XCTAssertTrue(appears(field), "clicking the number didn't make it editable")
        sessionsWaitForKeyboardFocus(on: field)
        return field
    }

    private func sessionMinutes() -> Int {
        sessionHours() * Self.minutesPerHour + (Int(sessionsText(of: element(FocusStart.durationMinutes))) ?? 0)
    }

    private func sessionHours() -> Int {
        Int(sessionsText(of: element(FocusStart.durationHours))) ?? 0
    }

    /// The session's total is the last number of its "0 sec of 5 min" line.
    /// The running session's goal card header. macOS folds it into a disclosure triangle, and SwiftUI
    /// doubles the identifier on the way ("id-id").
    private var goalToggle: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", Ids.goalToggle)).firstMatch
    }

    /// Whether the shut goal card names `goal`: the header's accessible name carries it.
    private func goalCardShows(_ goal: String) -> Bool {
        let deadline = Date().addingTimeInterval(Self.screenTimeout)
        repeat {
            if goalToggle.exists, goalToggle.label.contains(goal) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.sessionsPollInterval))
        } while Date() < deadline
        return false
    }

    private func sessionTotal(becomes minutes: Int) -> Bool {
        let progress = element(Ids.progress)
        let deadline = Date().addingTimeInterval(Self.screenTimeout)
        repeat {
            if Self.integers(in: sessionsText(of: progress)).last == minutes { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.sessionsPollInterval))
        } while Date() < deadline
        return false
    }

    private static func integers(in text: String) -> [Int] {
        text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
    }
}
