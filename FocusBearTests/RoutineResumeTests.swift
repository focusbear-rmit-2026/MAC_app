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
}
