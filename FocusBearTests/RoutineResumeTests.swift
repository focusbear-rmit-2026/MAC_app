//
//  RoutineResumeTests.swift
//  FocusBearTests
//
//  "I had postponed earlier and then stopped the focus session. It should have taken me back to full
//  screen to continue my habits" — report 2026-09-17_12-03-44.
//
//  The resume ran and was immediately undone by the meeting guard that `resumeMorningHabit` opens with,
//  which exists for the postpone TIMER but also fired for the user's explicit request:
//
//      12:02:20  [user-action] Stop focus session started from postpone:- skip password + resume routine
//      12:02:20  Morning habits postpone finished
//      12:02:20  extendPostponeToCoverAnnouncedMeetings:- morning postpone extended to 1819 seconds …
//
//  These test the decision, not the window.
//

@testable import Focus_Bear
import XCTest

final class RoutineResumeTests: XCTestCase {

    private func decision(trigger: RoutineResumeTrigger,
                          isRoutinePostponed: Bool = true,
                          hasMeetingToCover: Bool = false,
                          isMeetingSessionLive: Bool = false) -> RoutineResume.Decision {
        RoutineResume.decision(trigger: trigger,
                               isRoutinePostponed: isRoutinePostponed,
                               hasMeetingToCover: hasMeetingToCover,
                               isMeetingSessionLive: isMeetingSessionLive)
    }

    // MARK: - The report

    func testStoppingTheSessionResumesAnIncompletePostponedRoutine() {
        XCTAssertEqual(decision(trigger: .userRequested), .resume)
    }

    /// The actual regression: an announced calendar meeting must not swallow an explicit request. This
    /// is the exact situation in the log — a live "Daily Stand Up Meeting" covering 12:00-12:30.
    func testAnAnnouncedMeetingDoesNotSwallowAnExplicitResume() {
        XCTAssertEqual(decision(trigger: .userRequested, hasMeetingToCover: true), .resume)
    }

    func testStoppingWithNoRoutineToRecoverDoesNotResume() {
        XCTAssertEqual(decision(trigger: .userRequested, isRoutinePostponed: false), .stayPostponed)
    }

    /// The constraint that must never regress: Focus Bear actively running a meeting outranks even an
    /// explicit request. A calendar entry is a guess about what someone is doing; a live meeting session
    /// is not.
    func testStoppingWhileAMeetingSessionIsLiveDoesNotResume() {
        XCTAssertEqual(decision(trigger: .userRequested, isMeetingSessionLive: true), .stayPostponed)
        XCTAssertEqual(decision(trigger: .userRequested, hasMeetingToCover: true, isMeetingSessionLive: true),
                       .stayPostponed)
    }

    /// The postpone timer finished a nested break at 12:47:40, leaving idle and a saved postpone.
    /// Stop at 12:49:08 must recover it before asking the resume guard, even with calendar coverage.
    func testExplicitStopRecoversPostponeAfterNestedBreakTimerUnwinds() {
        for postponedState: CURRENTSTATE in [._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_] {
            let recoveredState = RoutineResume.stateForExplicitResume(
                currentState: ._NOTHING_, recoverablePostponeState: postponedState,
                isMeetingSessionLive: false)
            XCTAssertEqual(recoveredState, postponedState)
            XCTAssertEqual(decision(trigger: .userRequested,
                                    isRoutinePostponed: recoveredState == postponedState,
                                    hasMeetingToCover: true), .resume)
        }
    }

    func testExplicitStopDoesNotRecoverAbsentOrInvalidPostpone() {
        for savedState: CURRENTSTATE? in [nil, ._MORNING_HABIT_, ._MICRO_BREAK_] {
            XCTAssertEqual(RoutineResume.stateForExplicitResume(
                currentState: ._NOTHING_, recoverablePostponeState: savedState,
                isMeetingSessionLive: false), ._NOTHING_)
        }
    }

    func testExplicitStopPreservesAnotherActivityAndAnUnfinishedMeeting() {
        XCTAssertEqual(RoutineResume.stateForExplicitResume(
            currentState: ._CUSTOM_ROUTINE_, recoverablePostponeState: ._POSTPONE_MORNING_HABIT_,
            isMeetingSessionLive: false), ._CUSTOM_ROUTINE_)
        XCTAssertEqual(RoutineResume.stateForExplicitResume(
            currentState: ._NOTHING_, recoverablePostponeState: ._POSTPONE_MORNING_HABIT_,
            isMeetingSessionLive: true), ._NOTHING_)
    }

    func testExplicitStopRecoversFocusSummaryPostpone() {
        XCTAssertEqual(RoutineResume.stateForExplicitResume(
            currentState: ._NOTHING_, recoverablePostponeState: ._POSTPONE_FOCUS_SUMMARY_,
            isMeetingSessionLive: false), ._POSTPONE_FOCUS_SUMMARY_)
    }

    // MARK: - The automatic path keeps its guard

    func testThePostponeTimerStillDefersToAnAnnouncedMeeting() {
        XCTAssertEqual(decision(trigger: .postponeElapsed, hasMeetingToCover: true), .extendPostponeOverMeeting)
    }

    func testThePostponeTimerResumesWhenNoMeetingNeedsCovering() {
        XCTAssertEqual(decision(trigger: .postponeElapsed), .resume)
    }

    /// The postpone timer also fires for a micro break or custom routine that ran *inside* the postpone.
    /// Those have no postpone left to stretch and must carry on unwinding exactly as they did before —
    /// returning `.stayPostponed` here would strand them.
    func testThePostponeTimerStillUnwindsABreakThatRanInsideThePostpone() {
        XCTAssertEqual(decision(trigger: .postponeElapsed, isRoutinePostponed: false), .resume)
        XCTAssertEqual(decision(trigger: .postponeElapsed, isRoutinePostponed: false, hasMeetingToCover: true),
                       .resume)
    }

    // MARK: - Full screen is decided by the existing function, not a new one

    /// Resuming lands the routine in `_MORNING_HABIT_` / `_EVENING_HABIT_`, and whether that is full
    /// screen is `FullScreenStates.shouldUseFullScreen` — the same predicate every other path uses. A
    /// third answer to "should this state be full screen" is how the last three bugs here happened.
    func testResumingIntoARoutineStateIsFullScreenOnlyWhenTheSettingIsOn() {
        for state: CURRENTSTATE in [._MORNING_HABIT_, ._EVENING_HABIT_] {
            XCTAssertTrue(FullScreenStates.shouldUseFullScreen(setting: true, state: state),
                          "\(state) with the setting on should be full screen")
            XCTAssertFalse(FullScreenStates.shouldUseFullScreen(setting: false, state: state),
                           "the setting being off must suppress full screen entirely")
        }
    }

    /// And while the routine is still postponed — the outcome whenever the decision above declines —
    /// full screen stays off regardless of the setting, so a declined resume cannot put a window up.
    func testADeclinedResumeLeavesAStateThatIsNeverFullScreen() {
        for state: CURRENTSTATE in [._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_] {
            XCTAssertFalse(FullScreenStates.shouldUseFullScreen(setting: true, state: state),
                           "\(state) must never be full screen")
        }
    }
    func testMeetingPopupOutlivingBreakPostponesItsRestoredParent() {
        XCTAssertEqual(RoutineResume.appointmentTarget(captured: ._MICRO_BREAK_, current: ._POSTPONE_MORNING_HABIT_), ._MORNING_HABIT_)
        XCTAssertEqual(RoutineResume.appointmentTarget(captured: ._CUSTOM_ROUTINE_, current: ._POSTPONE_EVENING_HABIT_), ._EVENING_HABIT_)
        XCTAssertEqual(RoutineResume.appointmentTarget(captured: ._MICRO_BREAK_, current: ._MICRO_BREAK_), ._MICRO_BREAK_)
    }

    func testMeetingBorrowingExistingPostponeDoesNotOwnItsStop() {
        XCTAssertFalse(RoutineResume.sessionStopResumesRoutine(isMeeting: true, wasAlreadyPostponed: true))
        XCTAssertTrue(RoutineResume.sessionStopResumesRoutine(isMeeting: true, wasAlreadyPostponed: false))
        XCTAssertTrue(RoutineResume.sessionStopResumesRoutine(isMeeting: false, wasAlreadyPostponed: true))
    }

    func testExplicitFocusStopResumesPostponedHabitsDespiteCalendarCoverage() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let end = now.addingTimeInterval(900)
        for isMeetingSession in [false, true] {
            XCTAssertFalse(RoutineResume.shouldPreservePostponeOnFocusStop(
                trigger: .userRequested, isMeetingSession: isMeetingSession,
                hasMeetingCoverage: true, postponeEnd: end, now: now))
        }
    }

    func testAutomaticFocusStopPreservesNewMeetingCoverage() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let end = now.addingTimeInterval(900)
        XCTAssertTrue(RoutineResume.shouldPreservePostponeOnFocusStop(trigger: .postponeElapsed, isMeetingSession: false, hasMeetingCoverage: true, postponeEnd: end, now: now))
        XCTAssertFalse(RoutineResume.shouldPreservePostponeOnFocusStop(trigger: .postponeElapsed, isMeetingSession: true, hasMeetingCoverage: true, postponeEnd: end, now: now))
        XCTAssertFalse(RoutineResume.shouldPreservePostponeOnFocusStop(trigger: .postponeElapsed, isMeetingSession: false, hasMeetingCoverage: false, postponeEnd: end, now: now))
        XCTAssertFalse(RoutineResume.shouldPreservePostponeOnFocusStop(trigger: .postponeElapsed, isMeetingSession: false, hasMeetingCoverage: true, postponeEnd: now, now: now))
    }

}

extension RoutineResumeTests {
    private static let completionTestTimeout: TimeInterval = 2
    private static let inactiveTestTimerInterval: TimeInterval = 60

    func testReturningToRoutineListInvalidatesLiveTimerAndQueuedCompletion() {
        let controller = timerViewcontroller()
        let timer = Timer(timeInterval: Self.inactiveTestTimerInterval, repeats: false) { _ in }
        controller.timer = timer
        let completion = ActivityTimerCompletion(generation: controller.activityTimerGeneration,
                                                 state: ._MORNING_HABIT_)
        controller.cancelActivityTimer()
        XCTAssertFalse(timer.isValid)
        XCTAssertNil(controller.timer)
        XCTAssertFalse(completion.isCurrent(generation: controller.activityTimerGeneration,
                                            state: ._MORNING_HABIT_, action: ._INPROGRESS_))
    }

    func testBackCancelsTimerCreationAlreadyQueuedOnMainThread() {
        let controller = timerViewcontroller()
        controller.setCountDownTimer()
        controller.cancelActivityTimer()
        let drained = expectation(description: "Queued timer creation was cancelled")
        DispatchQueue.main.async {
            XCTAssertNil(controller.timer)
            XCTAssertFalse(controller.isViewLoaded)
            drained.fulfill()
        }
        wait(for: [drained], timeout: Self.completionTestTimeout)
    }

    func testValidCompletionRemainsAcceptedForEveryTimerActivity() {
        let generation = UUID()
        for state: CURRENTSTATE in [._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_,
                                    ._MICRO_BREAK_, ._SPECIAL_ACTIVITY_, ._BREATHING_] {
            let completion = ActivityTimerCompletion(generation: generation, state: state)
            XCTAssertTrue(completion.isCurrent(generation: generation, state: state, action: ._INPROGRESS_))
            XCTAssertFalse(completion.isCurrent(generation: generation, state: state, action: ._START_))
            XCTAssertFalse(completion.isCurrent(generation: generation, state: state, action: ._END_))
        }
    }

    func testQueuedCompletionCannotFinishAReplacementActivity() {
        let generation = UUID()
        let completion = ActivityTimerCompletion(generation: generation, state: ._MORNING_HABIT_)
        XCTAssertFalse(completion.isCurrent(generation: UUID(), state: ._MORNING_HABIT_, action: ._INPROGRESS_))
        XCTAssertFalse(completion.isCurrent(generation: generation, state: ._EVENING_HABIT_, action: ._INPROGRESS_))
    }

    func testManualDoneCanClaimCompletionWhileTimerIsPaused() {
        let controller = timerViewcontroller()
        let timer = Timer(timeInterval: Self.inactiveTestTimerInterval, repeats: false) { _ in }
        controller.timer = timer
        let completion = ActivityTimerCompletion(generation: controller.activityTimerGeneration,
                                                 state: ._MORNING_HABIT_)
        // btnPauseClicked invalidates the timer without changing the activity action or generation.
        timer.invalidate()
        XCTAssertTrue(controller.claimActivityCompletion(completion, state: ._MORNING_HABIT_, action: ._INPROGRESS_))
        XCTAssertFalse(controller.isViewLoaded)
    }

    func testManualDoneAndTimerExpiryCanClaimOnlyOneCompletion() {
        let controller = timerViewcontroller()
        let completion = ActivityTimerCompletion(generation: controller.activityTimerGeneration,
                                                 state: ._BREATHING_)
        XCTAssertTrue(controller.claimActivityCompletion(completion, state: ._BREATHING_, action: ._INPROGRESS_))
        XCTAssertFalse(controller.claimActivityCompletion(completion, state: ._BREATHING_, action: ._INPROGRESS_))
    }

    func testMorningCompletionRejectsStaleIndicesBeforeLoadingViews() {
        let completionController = activityCompletionVc()
        completionController.morningHabitFinished(index: -1)
        completionController.morningHabitFinished(index: arrFilteredMorningHabits.count)
        XCTAssertFalse(completionController.isViewLoaded)

        let previousIndex = currentHabitIndex
        defer { currentHabitIndex = previousIndex }
        currentHabitIndex = -1
        let habitsController = habitsVc()
        habitsController.morningHabitOver()
        XCTAssertFalse(habitsController.isViewLoaded)
    }
}


extension RoutineResumeTests {
    private enum CompletionFixture {
        static let morning = "morning-sequence"
        static let evening = "evening-sequence"
        static let custom = "custom-sequence"
    }

    func testRemoteCompletionCannotInterruptDifferentActiveOrPostponedRoutine() {
        let sequences = RoutineCompletionEvent.SequenceIDs(morning: CompletionFixture.morning,
            evening: CompletionFixture.evening, custom: CompletionFixture.custom)
        let states: [(CURRENTSTATE, String)] = [
            (._MORNING_HABIT_, CompletionFixture.morning),
            (._POSTPONE_MORNING_HABIT_, CompletionFixture.morning),
            (._EVENING_HABIT_, CompletionFixture.evening),
            (._POSTPONE_EVENING_HABIT_, CompletionFixture.evening),
            (._CUSTOM_ROUTINE_, CompletionFixture.custom)
        ]
        for (state, expected) in states {
            let active = RoutineCompletionEvent.activeSequenceID(state: state, sequences: sequences,
                isBreakFromPostponedMorning: false, isBreakFromPostponedEvening: false)
            XCTAssertEqual(active, expected)
            XCTAssertTrue(RoutineCompletionEvent.shouldApply(eventSequenceID: expected, activeSequenceID: active))
            for other in [CompletionFixture.morning, CompletionFixture.evening, CompletionFixture.custom]
                where other != expected {
                XCTAssertFalse(RoutineCompletionEvent.shouldApply(eventSequenceID: other, activeSequenceID: active))
            }
        }
    }

    func testBreakCompletionChecksThePostponedRoutineItWouldResume() {
        let sequences = RoutineCompletionEvent.SequenceIDs(morning: CompletionFixture.morning,
            evening: CompletionFixture.evening, custom: CompletionFixture.custom)
        XCTAssertEqual(RoutineCompletionEvent.activeSequenceID(state: ._MICRO_BREAK_, sequences: sequences,
            isBreakFromPostponedMorning: true, isBreakFromPostponedEvening: false), CompletionFixture.morning)
        XCTAssertEqual(RoutineCompletionEvent.activeSequenceID(state: ._MICRO_BREAK_, sequences: sequences,
            isBreakFromPostponedMorning: false, isBreakFromPostponedEvening: true), CompletionFixture.evening)
        XCTAssertNil(RoutineCompletionEvent.activeSequenceID(state: ._MICRO_BREAK_, sequences: sequences,
            isBreakFromPostponedMorning: false, isBreakFromPostponedEvening: false))
    }

    func testCompletionWithoutKnownSequenceKeepsLegacyResyncBehavior() {
        for missing in [nil, ""] as [String?] {
            XCTAssertTrue(RoutineCompletionEvent.shouldApply(eventSequenceID: missing,
                activeSequenceID: CompletionFixture.evening))
            XCTAssertTrue(RoutineCompletionEvent.shouldApply(eventSequenceID: CompletionFixture.evening,
                activeSequenceID: missing))
        }
    }
}
