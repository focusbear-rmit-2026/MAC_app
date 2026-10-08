//
//  RegressionRoutineUITests.swift
//  Focus BearUITests
//
//  Regression suite: Routines. Runs in the Regression test plan; the critical path is in Smoke.
//
//  The routine player, whatever the time of day: each test asks the app to play a fixture routine on
//  launch (`FOCUSBEAR_UITEST_PRESENT_SCREEN`), held in memory only and never saved to the account.
//  Timed habits are either paused or two seconds long, so no test waits out a real habit.
//

import XCTest

final class RegressionRoutineUITests: FocusBearUITestCase {
    private typealias Routine = UITestContract.Identifier.Routine
    private typealias Ids = UITestContract.Identifier.SessionsRegression
    private typealias Fixture = UITestContract.Identifier.SessionsRegression.Fixture

    /// A running timer ticks every second, so one that hasn't moved in this long is stopped.
    private static let pausedCheckSeconds: TimeInterval = 1.5
    /// The first item of the habit's "more actions" menu is "Skip this habit for today".
    private static let skipMenuItemIndex = 0
    private static let firstNoteLine = "First line"
    private static let secondNoteLine = "Second line"
    private static let loggedQuantity = "7"

    // MARK: - Timed habits

    func testTimedHabitCountsDownPausesAndResumes() throws {
        let timer = try presentSessionsScreen(.timedHabit, landmark: Ids.habitTimerLabel)
        XCTAssertTrue(sessionsTextChanges(timer, from: sessionsText(of: timer)), "the habit's timer doesn't count down")

        tap(element(Ids.habitPauseButton))
        let skip = element(Routine.skipHabitButton)
        XCTAssertTrue(appears(skip), "pausing the habit didn't offer Skip")
        XCTAssertFalse(sessionsTextChanges(timer, from: sessionsText(of: timer), within: Self.pausedCheckSeconds),
                       "the paused habit's timer kept counting")
        attachScreenshot(named: "habit paused")

        tap(element(Ids.habitPauseButton))
        XCTAssertTrue(waitForNonExistence(of: skip), "resuming the habit left Skip up")
        XCTAssertTrue(sessionsTextChanges(timer, from: sessionsText(of: timer)), "the resumed habit's timer doesn't count down")
    }

    func testTimedHabitFinishesWhenItsTimeIsUp() throws {
        // The habit lasts `Fixture.shortTimedHabitSeconds`; the finish screen replaces it by itself.
        try presentSessionsScreen(.shortTimedHabit, landmark: Ids.habitFinishedMainButton)
        XCTAssertTrue(waitForNonExistence(of: element(Ids.habitTimerLabel)), "the finished habit's timer is still showing")
        attachScreenshot(named: "timed habit finished")
    }

    func testPostponeIsOfferedDuringARoutine() throws {
        try presentSessionsScreen(.timedHabit, landmark: Ids.habitTimerLabel)
        let postpone = element(Routine.postponeButton)
        XCTAssertTrue(appears(postpone), "a playing routine offers no Postpone")
        XCTAssertTrue(postpone.isEnabled && postpone.isHittable, "Postpone can't be pressed during a routine")
    }

    // MARK: - Untimed habits and the routine's end

    func testImDoneFinishesTheRoutineAndTheSummaryClosesIt() throws {
        let done = try present(.nonTimerActivity, landmark: Routine.doneButton, environment: Self.routineEndsOnDayPlan)
        tap(done)
        let finish = element(Ids.habitFinishedMainButton)
        XCTAssertTrue(appears(finish), "I'm done didn't finish the habit")
        attachScreenshot(named: "routine finished")
        tap(finish)
        XCTAssertTrue(waitForNonExistence(of: element(Ids.habitFinishedScreen)), "the routine's summary stayed up")
        // What comes after a finished routine is the Day Plan, with the after-routine Pomodoro off.
        XCTAssertTrue(isDayPlanInFront(), "the content pane is empty after the routine finished")
        attachScreenshot(named: "after the routine")
    }

    /// #2731: a routine ending on an allowed-app habit left the habit player's Day Plan tab behind, and
    /// the Day Plan went into that off-screen player — the content pane was blank.
    func testARoutineEndingOnAnAllowedAppHabitLeavesTheDayPlanShowing() throws {
        try finishARoutineEndingOnAnAllowedAppHabit()
        XCTAssertTrue(isDayPlanInFront(), "the content pane is empty after a routine that ended on an allowed-app habit")
        attachScreenshot(named: "after an allowed-app routine")
    }

    /// #688: Return finishes a habit that has no timer.
    func testReturnFinishesAnUntimedHabit() throws {
        try present(.nonTimerActivity, landmark: Routine.doneButton)
        press(.return)
        XCTAssertTrue(appears(element(Ids.habitFinishedMainButton)), "Return didn't finish the untimed habit")
    }

    func testFinishedHabitGoesOnToTheNextOne() throws {
        let done = try presentSessionsScreen(.twoHabitRoutine, landmark: Routine.doneButton)
        tap(done)
        let next = element(Ids.habitFinishedMainButton)
        XCTAssertTrue(appears(next), "I'm done didn't finish the first habit")
        tap(next)
        // Now and then the app asks "What comes next?" before starting it.
        let shown = firstToAppear([element(Ids.habitTimerLabel), element(Ids.rememberNextHabitField)])
        XCTAssertNotNil(shown, "the second habit didn't start")
    }

    func testWhatComesNextStartsTheNextHabit() throws {
        let field = try presentSessionsScreen(.rememberNextHabit, landmark: Ids.rememberNextHabitField)
        let start = element(Ids.rememberNextStartButton)
        XCTAssertFalse(start.exists && start.isHittable, "Start was offered before the next habit was named")
        tap(field)
        typeIntoFocus(Fixture.timedHabitName)
        press(.return)
        XCTAssertTrue(appears(start), "naming the next habit didn't offer to start it")
        attachScreenshot(named: "what comes next")
        tap(start)
        XCTAssertTrue(appears(element(Ids.habitTimerLabel)), "the next habit didn't start")
        XCTAssertFalse(element(Ids.rememberNextScreen).exists, "“What comes next?” stayed up over the next habit")
    }

    // MARK: - Skipping

    func testSkippingAHabitAlreadyDoneFinishesIt() throws {
        try openWhySkip()
        tap(element(Ids.whySkipAlreadyDidItButton))
        XCTAssertTrue(appears(element(Ids.habitFinishedMainButton)), "“I already did it” didn't finish the habit")
    }

    func testChangingMyMindAboutASkipKeepsTheHabit() throws {
        try openWhySkip(environment: Self.easySkipOff)
        tap(element(Ids.whySkipCanNotDoItButton))
        let keep = element(Ids.skipCountdownKeepHabitButton)
        guard firstToAppear([keep, element(Ids.habitFinishedMainButton)])?.identifier == Ids.skipCountdownKeepHabitButton else {
            throw XCTSkip("Easy skip is on for the test account, so the habit was skipped with no countdown.")
        }
        tap(keep)
        XCTAssertTrue(waitForNonExistence(of: element(Ids.skipCountdownScreen)), "“I changed my mind” left the skip countdown up")
        XCTAssertTrue(element(Ids.habitTimerLabel).exists, "changing my mind didn't keep the habit")
    }

    // MARK: - Notes

    func testReturnInHabitNotesAddsANewLine() throws {
        try typeFirstNoteLine()
        press(.return)
        typeIntoFocus(Self.secondNoteLine)
        let notes = element(Ids.habitNotes)
        XCTAssertTrue(sessionsText(of: notes).contains(Self.firstNoteLine + "\n" + Self.secondNoteLine),
                      "Return in the notes didn't start a new line")
        XCTAssertFalse(element(Ids.habitFinishedMainButton).exists, "Return in the notes finished the habit")
    }

    func testCommandReturnInHabitNotesFinishesTheHabit() throws {
        try typeFirstNoteLine()
        press(.return, modifiers: .command)
        XCTAssertTrue(appears(element(Ids.habitFinishedMainButton)), "⌘Return in the notes didn't finish the habit")
    }

    // MARK: - Logging a quantity

    func testLogQuantityReturnSubmitsTheAnswer() throws {
        try openLogQuantity(for: .habitWithLogQuantity)
        let field = element(Ids.logQuantityField)
        XCTAssertTrue(appears(field), "the log-quantity dialog has no answer field")
        sessionsWaitForKeyboardFocus(on: field)
        typeIntoFocus(Self.loggedQuantity)
        press(.return)
        XCTAssertTrue(waitForNonExistence(of: element(Ids.logQuantityScreen)), "Return didn't submit the quantity")
        XCTAssertTrue(appears(element(Ids.habitFinishedMainButton)), "submitting the quantity didn't finish the habit")
    }

    func testLogQuantityEscapeCancels() throws {
        try openLogQuantity(for: .habitWithLogQuantity)
        press(.escape)
        XCTAssertTrue(waitForNonExistence(of: element(Ids.logQuantityScreen)), "Escape didn't close the log-quantity dialog")
    }

    /// ↑ / ↓ in a slider answer's value field step the answer (#768).
    func testLogQuantityArrowsStepASliderAnswer() throws {
        try openLogQuantity(for: .habitWithSliderQuantity)
        let value = element(Ids.logQuantitySliderValue)
        XCTAssertTrue(appears(value), "the slider answer has no value field")
        tap(value)
        let start = quantity(in: value)
        press(.upArrow)
        XCTAssertGreaterThan(quantity(in: value), start, "↑ didn't raise the answer")
        press(.downArrow)
        XCTAssertEqual(quantity(in: value), start, "↓ didn't bring the answer back down")
        XCTAssertTrue(element(Ids.logQuantityOkButton).exists && element(Ids.logQuantityCancelButton).exists,
                      "the log-quantity dialog lost its OK / Cancel")
    }

    // MARK: - Steps

    /// Pause, then Skip's menu → "Skip this habit for today" → "Why do you want to skip?".
    private func openWhySkip(environment: [String: String] = [:]) throws {
        try presentSessionsScreen(.timedHabit, landmark: Ids.habitTimerLabel, environment: environment)
        tap(element(Ids.habitPauseButton))
        let skip = element(Routine.skipHabitButton)
        XCTAssertTrue(appears(skip), "pausing the habit didn't offer Skip")
        chooseMenuItem(at: Self.skipMenuItemIndex, openedBy: skip)
        XCTAssertTrue(appears(element(Ids.whySkipScreen)), "skipping didn't ask why")
    }

    private func typeFirstNoteLine() throws {
        try presentSessionsScreen(.habitWithNotes, landmark: Ids.habitNotes)
        let notes = element(Ids.habitNotes)
        tap(notes)
        typeIntoFocus(Self.firstNoteLine)
    }

    private func openLogQuantity(for screen: Ids.Screen) throws {
        let done = try presentSessionsScreen(screen, landmark: Routine.doneButton)
        tap(done)
        XCTAssertTrue(appears(element(Ids.logQuantityScreen)), "finishing the habit didn't ask for its quantity")
    }

    private func quantity(in field: XCUIElement) -> Double {
        Double(sessionsText(of: field)) ?? .nan
    }
}

// MARK: - Shared by the focus session, break and routine regression suites

extension FocusBearUITestCase {
    static let sessionsPollInterval: TimeInterval = 0.1

    /// Signed in, with one of the sessions suites' screens put up by the app (`SessionsRegression.Screen`).
    @discardableResult
    /// Shows another screen in the app that is already running (`UITestContract.Command.presentScreen`),
    /// for what only happens after something else — a break falling due once a routine has finished.
    func presentInRunningApp(_ rawScreen: String) {
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(UITestContract.Command.presentScreen),
                                                                     object: rawScreen, userInfo: nil, deliverImmediately: true)
    }

    /// A routine that ends on the Day Plan: the test account's after-routine Pomodoro turned off.
    static let routineEndsOnDayPlan = [UITestContract.Environment.routineEndsOnDayPlan: UITestContract.Environment.enabledValue]

    /// Plays `.allowedAppHabitRoutine` to its end, on the Day Plan path: I'm done, then the summary's
    /// main button.
    func finishARoutineEndingOnAnAllowedAppHabit() throws {
        let done = try presentSessionsScreen(.allowedAppHabitRoutine, landmark: UITestContract.Identifier.Routine.doneButton,
                                             environment: Self.routineEndsOnDayPlan)
        tap(done)
        let finish = element(UITestContract.Identifier.SessionsRegression.habitFinishedMainButton)
        XCTAssertTrue(appears(finish), "I'm done didn't finish the allowed-app habit")
        tap(finish)
        XCTAssertTrue(waitForNonExistence(of: element(UITestContract.Identifier.SessionsRegression.habitFinishedScreen)),
                      "the routine's summary stayed up")
    }

    /// The Day Plan in front of the content pane, as after a routine: its Add task can be pressed.
    func isDayPlanInFront() -> Bool {
        let addTask = element(UITestContract.Identifier.DayPlan.addTaskButton)
        return appears(addTask) && addTask.isHittable
    }

    func presentSessionsScreen(_ screen: UITestContract.Identifier.SessionsRegression.Screen,
                               landmark: String, environment: [String: String] = [:]) throws -> XCUIElement {
        try launchSignedIn(environment: environment.merging([UITestContract.Environment.presentScreen: screen.rawValue]) { $1 })
        let shown = element(landmark)
        // As for `present(_:landmark:)`: the app puts the screen up once sign-in and the account's
        // settings have loaded, on its 5-second tick.
        XCTAssertTrue(appears(shown, within: Self.firstLaunchTimeout, waitsOnNetwork: true), "\(screen.rawValue) wasn't presented")
        return shown
    }

    /// What a label or field shows: AppKit puts it in the value, SwiftUI's Text in the value or label.
    func sessionsText(of element: XCUIElement) -> String {
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }

    /// Whether `element` shows something other than `before` within `timeout`.
    func sessionsTextChanges(_ element: XCUIElement, from before: String, within timeout: TimeInterval = screenTimeout) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if sessionsText(of: element) != before { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.sessionsPollInterval))
        }
        return sessionsText(of: element) != before
    }

    /// A field that takes focus on the next run-loop turn; typing before then would go elsewhere.
    @discardableResult
    func sessionsWaitForKeyboardFocus(on element: XCUIElement) -> Bool {
        let deadline = Date().addingTimeInterval(Self.screenTimeout)
        while !hasKeyboardFocus(element), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(Self.sessionsPollInterval))
        }
        return hasKeyboardFocus(element)
    }
}
