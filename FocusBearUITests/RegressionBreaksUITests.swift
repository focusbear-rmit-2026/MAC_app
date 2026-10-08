//
//  RegressionBreaksUITests.swift
//  Focus BearUITests
//
//  Regression suite: Breaks. Runs in the Regression test plan; the critical path is in Smoke.
//
//  A break falls due on the clock, so every test here asks the app to show the warning on launch
//  (`FOCUSBEAR_UITEST_PRESENT_SCREEN`) with a fixture break activity held in memory only. Nothing
//  waits for the warning's countdown or a break's timer: the tests act on the buttons.
//

import XCTest

final class RegressionBreaksUITests: FocusBearUITestCase {
    private typealias Breaks = UITestContract.Identifier.Breaks
    private typealias Routine = UITestContract.Identifier.Routine
    private typealias Ids = UITestContract.Identifier.SessionsRegression

    /// One of the warning's postpone lengths (`BreakWarningViewModel.minutesOptions`), all digits so
    /// the same in every language.
    private static let postponeMinutes = "10"

    // MARK: - The warning

    func testWarningOffersStartSkipMinutesAndPostpone() throws {
        try present(.microBreak, landmark: Breaks.warningStartButton)
        XCTAssertTrue(element(Breaks.warningSkipButton).exists, "the break warning has no Skip")
        XCTAssertTrue(element(Ids.warningPostponeButton).exists, "the break warning has no Postpone")
        XCTAssertTrue(minutesPicker().exists, "the break warning has no postpone length")
        attachScreenshot(named: "break warning")
    }

    func testWarningPostponeLengthCanBeChosen() throws {
        try present(.microBreak, landmark: Breaks.warningStartButton)
        let picker = minutesPicker()
        chooseMenuItem(titled: Self.postponeMinutes, openedBy: picker)
        XCTAssertEqual(picker.value as? String, Self.postponeMinutes, "the postpone length didn't change")
    }

    /// Postponing takes a press held for seconds (#1590); a click must not do it.
    func testClickingPostponeWithoutHoldingDoesNotPostpone() throws {
        let start = try present(.microBreak, landmark: Breaks.warningStartButton, environment: Self.easySkipOff)
        let postpone = element(Ids.warningPostponeButton)
        guard postpone.elementType != .button else {
            throw XCTSkip("Easy skip is on for the test account, so Postpone is an ordinary button.")
        }
        tap(postpone)
        XCTAssertFalse(waitForNonExistence(of: start, timeout: Self.optionalWait), "a click postponed the break without a hold")
    }

    func testSkipClosesTheWarning() throws {
        let start = try present(.microBreak, landmark: Breaks.warningStartButton)
        tap(element(Breaks.warningSkipButton))
        XCTAssertTrue(waitForNonExistence(of: start), "Skip left the break warning up")
        XCTAssertFalse(appears(element(Breaks.startScreenStartButton), within: Self.optionalWait),
                       "skipping the break started it")
    }

    func testMidMeetingBreakCanBeSkipped() throws {
        let start = try present(.meetingBreak, landmark: Breaks.warningStartButton)
        XCTAssertTrue(element(Ids.warningPostponeButton).exists, "the mid-meeting break has no Postpone")
        attachScreenshot(named: "mid-meeting break")
        tap(element(Breaks.warningSkipButton))
        XCTAssertTrue(waitForNonExistence(of: start), "Skip left the mid-meeting break up")
    }

    /// #2674: Start with every break activity already played used to crash on an empty list. The
    /// break is dropped instead.
    func testStartingABreakWithNoActivitiesLeftDropsIt() throws {
        let start = try presentSessionsScreen(.breakWithNoActivities, landmark: Breaks.warningStartButton)
        tap(start)
        XCTAssertTrue(waitForNonExistence(of: start), "Start left the break warning up")
        XCTAssertNotEqual(app.state, .notRunning, "starting a break with no activities crashed the app")
        XCTAssertFalse(appears(element(Breaks.startScreenStartButton), within: Self.optionalWait),
                       "a break with nothing to do was started")
    }

    // MARK: - The break start screen

    func testStartOpensTheBreakStartScreen() throws {
        try openBreakStartScreen()
        XCTAssertTrue(element(Breaks.startScreenSkipButton).exists, "the break start screen has no Skip")
        XCTAssertTrue(element(Ids.breakStartModePicker).exists, "the break start screen has no chair / full-movement choice")
        attachScreenshot(named: "break start")
    }

    /// The brain dump takes typing, and Return in it is a newline rather than Start.
    func testBrainDumpTakesTextAndKeepsReturn() throws {
        let start = try openBreakStartScreen()
        let brainDump = try openBrainDump()
        tap(brainDump)
        let thought = uniqueTitle("UI test parked thought")
        typeIntoFocus(thought)
        press(.return)
        XCTAssertTrue(start.exists, "Return in the brain dump started the break")
        XCTAssertTrue(sessionsText(of: brainDump).contains(thought), "the brain dump didn't take the text")
        // It is the account's real brain dump (saved through the Notes API), so take back what was typed.
        for _ in 0..<(thought.count + Self.newlineLength) { press(.delete) }
    }

    private static let newlineLength = 1

    /// The brain dump's editor. Older start screens show it straight away; the redesigned one shows it
    /// at once only when the note has text, and otherwise behind a "Make a quick braindump" button.
    private func openBrainDump() throws -> XCUIElement {
        let brainDump = mainWindow.textViews.firstMatch
        if appears(brainDump, within: Self.optionalWait) { return brainDump }
        let open = element(Breaks.startScreenBrainDumpOpenButton)
        guard appears(open) else {
            recordDiagnostics(named: "break start brain dump")
            throw SetupError(description: "the break start screen has no brain dump")
        }
        tap(open)
        XCTAssertTrue(appears(brainDump), "opening the brain dump didn't show its editor")
        return brainDump
    }

    /// Chair exercises ↔ full movement is the office-mode setting, so the test puts it back.
    func testBreakModeCanBeSwitchedAndBack() throws {
        try openBreakStartScreen()
        let picker = element(Ids.breakStartModePicker)
        let segments = picker.radioButtons.allElementsBoundByIndex + picker.buttons.allElementsBoundByIndex
        guard let original = segments.firstIndex(where: isChosen),
              let other = segments.indices.first(where: { $0 != original }) else {
            recordDiagnostics(named: "break mode picker")
            return XCTFail("the break mode picker shows no current choice")
        }
        chooseSegment(segments[other])
        XCTAssertTrue(isChosen(segments[other]), "the other break mode wasn't chosen")
        XCTAssertTrue(element(Breaks.startScreenStartButton).exists, "switching mode left the break start screen")
        chooseSegment(segments[original])
        XCTAssertTrue(isChosen(segments[original]), "the break mode wasn't put back")
    }

    func testSkippingFromTheStartScreenCanSkipTheBreak() throws {
        let start = try openBreakStartScreen()
        tap(element(Breaks.startScreenSkipButton))
        let skipBreak = element(Ids.whySkipBreakCompletelyButton)
        XCTAssertTrue(appears(skipBreak), "Skip didn't ask why, with Skip micro break completely")
        tap(skipBreak)
        XCTAssertTrue(waitForNonExistence(of: element(Ids.whySkipScreen)), "the why-skip question stayed up")
        XCTAssertTrue(waitForNonExistence(of: start), "skipping completely left the break start screen up")
    }

    // MARK: - Doing the break

    /// Start on the break start screen must hand the content pane to the break's activity. On
    /// ff153db19 it showed the Day Plan instead, with "Start Micro Break" still selected (2026-09-28).
    func testStartingTheBreakShowsItsActivityNotTheDayPlan() throws {
        let start = try openBreakStartScreen()
        tap(start)
        let timer = element(Ids.habitTimerLabel), done = element(Routine.doneButton)
        XCTAssertNotNil(firstToAppear([timer, done], timeout: Self.screenTimeout),
                        "Start didn't show the break activity (no timer, no I'm done)")
        let dayPlan = element(UITestContract.Identifier.DayPlan.view)
        XCTAssertFalse(dayPlan.exists && dayPlan.isHittable, "Start showed the Day Plan instead of the break activity")
        attachScreenshot(named: "break activity after Start")
    }

    /// #2731, the real repro: after a routine ending on an allowed-app habit, the next break's
    /// activity reused the habit player with its leftover Day Plan tab in front.
    func testBreakAfterARoutineEndingOnAnAllowedAppHabitShowsItsActivity() throws {
        try finishARoutineEndingOnAnAllowedAppHabit()
        presentInRunningApp(UITestContract.PresentedScreen.microBreak.rawValue)
        let warningStart = element(Breaks.warningStartButton)
        XCTAssertTrue(appears(warningStart), "the micro break didn't fall due")
        tap(warningStart)
        let start = element(Breaks.startScreenStartButton)
        XCTAssertTrue(appears(start), "Start on the warning didn't open the break start screen")
        tap(start)
        XCTAssertNotNil(firstToAppear([element(Ids.habitTimerLabel), element(Routine.doneButton)], timeout: Self.screenTimeout),
                        "Start didn't show the break activity (no timer, no I'm done)")
        let dayPlan = element(UITestContract.Identifier.DayPlan.view)
        XCTAssertFalse(dayPlan.exists && dayPlan.isHittable, "the break activity played under the Day Plan")
        attachScreenshot(named: "break after an allowed-app routine")
    }

    func testUntimedBreakActivityIsFinishedWithImDone() throws {
        let warningStart = try presentSessionsScreen(.untimedBreak, landmark: Breaks.warningStartButton)
        tap(warningStart)
        let start = element(Breaks.startScreenStartButton)
        XCTAssertTrue(appears(start), "Start didn't open the break start screen")
        tap(start)
        let done = element(Routine.doneButton)
        XCTAssertTrue(appears(done), "starting the break didn't show the activity with I'm done")
        attachScreenshot(named: "break activity")
        tap(done)
        let finish = element(Ids.habitFinishedMainButton)
        XCTAssertTrue(appears(finish), "I'm done didn't finish the break activity")
        tap(finish)
        XCTAssertTrue(waitForNonExistence(of: element(Ids.habitFinishedScreen)), "finishing the break left its screen up")
    }

    // MARK: - Steps

    @discardableResult
    private func openBreakStartScreen() throws -> XCUIElement {
        let warningStart = try present(.microBreak, landmark: Breaks.warningStartButton)
        tap(warningStart)
        let start = element(Breaks.startScreenStartButton)
        XCTAssertTrue(appears(start), "Start on the warning didn't open the break start screen")
        return start
    }

    /// The warning's minutes pop-up: the identifier can land on the Picker's wrapper rather than its
    /// pop-up button.
    private func minutesPicker() -> XCUIElement {
        let picker = element(Ids.warningMinutesPicker)
        guard picker.exists, picker.elementType != .popUpButton else { return picker }
        let inside = picker.popUpButtons.firstMatch
        return inside.exists ? inside : window(containing: Breaks.warningStartButton).popUpButtons.firstMatch
    }

    private func isChosen(_ segment: XCUIElement) -> Bool {
        segment.isSelected || (segment.value as? Int) == 1
    }

    /// Choosing chair exercises the first time says so in an alert; Return dismisses it.
    private func chooseSegment(_ segment: XCUIElement) {
        tap(segment)
        if firstToAppear([app.sheets.firstMatch, app.dialogs.firstMatch], timeout: Self.optionalWait) != nil {
            confirmDestructiveAlert()
        }
    }
}
