import XCTest
@testable import Focus_Bear

/// The evening shutdown check runs on a five-second repeating timer. In a user's log on 2026-09-16 it
/// logged "Initiating shut off process." at 20:16:03, :08, :13, :18, :23, :28 and was still doing it
/// at 20:22:48 — the whole pipeline, including a focus grab, re-run every five seconds for the entire
/// evening routine. The user reported it as their menus being dismissed and their clicks eaten.
///
/// The AppKit half of that (alerts, window raising, `activate`) isn't testable, so these cover the two
/// decisions in front of it: whether the nag is owed on this tick, and whether it may take focus.
final class ShutdownNagPolicyTests: XCTestCase {

    private let t0 = Date(timeIntervalSince1970: 1_758_000_000)

    /// `ACTION` and `CURRENTSTATE` are module-qualified: the test target sees a second `ACTION` from an
    /// imported C header, which makes the bare name ambiguous here (it is unambiguous inside the app
    /// module, so `ShutdownNagPolicy` itself needs no qualification).
    private func eveningRoutine(habitIndex: Int = 0,
                                cutOffPassed: Bool = false,
                                action: Focus_Bear.ACTION = ._INPROGRESS_) -> ShutdownNagSituation {
        ShutdownNagSituation(state: ._EVENING_HABIT_, action: action,
                             habitIndex: habitIndex, isCutOffPassed: cutOffPassed)
    }

    // MARK: - It fires once, not every five seconds

    func testTheFirstTickFires() {
        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false,
                                                situation: eveningRoutine(),
                                                lastNag: nil,
                                                now: t0),
                       .fire)
    }

    /// The reported bug, stated as a test: nothing has changed, so the next timer beat must be silent.
    func testItDoesNotFireAgainFiveSecondsLater() {
        let situation = eveningRoutine()
        let lastNag = ShutdownNagRecord(situation: situation, firedAt: t0)

        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false,
                                                situation: situation,
                                                lastNag: lastNag,
                                                now: t0.addingTimeInterval(5)),
                       .stayQuiet)
    }

    /// The user's log, reproduced: eight ticks across 35 seconds produced eight prompts. Now it is one.
    func testAWholeMinuteOfTimerBeatsProducesOneNag() {
        let situation = eveningRoutine()
        var lastNag: ShutdownNagRecord?
        var fired = 0

        for beat in 0...12 {
            let now = t0.addingTimeInterval(Double(beat) * 5)
            if ShutdownNagPolicy.decide(isShutdownAborted: false, situation: situation,
                                        lastNag: lastNag, now: now) == .fire {
                fired += 1
                lastNag = ShutdownNagRecord(situation: situation, firedAt: now)
            }
        }

        XCTAssertEqual(fired, 1, "A minute of five-second ticks is still one shutdown prompt")
    }

    // MARK: - It fires again when something actually changes

    func testFinishingAHabitEarnsAFreshNag() {
        let lastNag = ShutdownNagRecord(situation: eveningRoutine(habitIndex: 0), firedAt: t0)

        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false,
                                                situation: eveningRoutine(habitIndex: 1),
                                                lastNag: lastNag,
                                                now: t0.addingTimeInterval(5)),
                       .fire)
    }

    func testTheCutOffPassingEarnsAFreshNag() {
        let lastNag = ShutdownNagRecord(situation: eveningRoutine(cutOffPassed: false), firedAt: t0)

        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false,
                                                situation: eveningRoutine(cutOffPassed: true),
                                                lastNag: lastNag,
                                                now: t0.addingTimeInterval(5)),
                       .fire)
    }

    /// A user who walked away mid-routine is still picked up, just not every five seconds.
    func testTheBackstopRepeatEventuallyFires() {
        let situation = eveningRoutine()
        let lastNag = ShutdownNagRecord(situation: situation, firedAt: t0)

        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false, situation: situation,
                                                lastNag: lastNag,
                                                now: t0.addingTimeInterval(kShutdownNagRepeatSeconds - 1)),
                       .stayQuiet)
        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false, situation: situation,
                                                lastNag: lastNag,
                                                now: t0.addingTimeInterval(kShutdownNagRepeatSeconds)),
                       .fire)
    }

    // MARK: - An aborted shutdown stays aborted

    func testAnAbortedShutdownStaysAborted() {
        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: true,
                                                situation: eveningRoutine(),
                                                lastNag: nil,
                                                now: t0),
                       .stayQuiet)
    }

    /// Abort outranks every "something changed" trigger — otherwise the next habit boundary would
    /// quietly undo the user's decision.
    func testAbortOutranksAChangedSituation() {
        let lastNag = ShutdownNagRecord(situation: eveningRoutine(habitIndex: 0), firedAt: t0)

        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: true,
                                                situation: eveningRoutine(habitIndex: 1, cutOffPassed: true),
                                                lastNag: lastNag,
                                                now: t0.addingTimeInterval(kShutdownNagRepeatSeconds * 2)),
                       .stayQuiet)
    }

    func testTheAbortExpiresWithItsDate() {
        let until = t0.addingTimeInterval(3600)

        XCTAssertTrue(ShutdownNagPolicy.isAborted(abortedUntil: until, now: t0))
        XCTAssertFalse(ShutdownNagPolicy.isAborted(abortedUntil: until, now: until.addingTimeInterval(1)))
        XCTAssertFalse(ShutdownNagPolicy.isAborted(abortedUntil: nil, now: t0))
    }

    // MARK: - Taking focus

    private var menuOpen: MenuBarActivity {
        MenuBarActivity(isAnyMenuOpen: true, isCursorInMenuBar: false, lastMenuBarClick: nil)
    }

    /// The whole point of the report: the user opens CleanShot's menu bar item and Focus Bear pulls
    /// the screen out from under it.
    func testItNeverTakesFocusOutOfAnOpenMenu() {
        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .notice, menuBar: menuOpen,
                                                  now: t0, waitingSince: nil),
                       .deferToUser)
        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .shutdownStarting, menuBar: menuOpen,
                                                  now: t0, waitingSince: nil),
                       .deferToUser)
    }

    func testAPointerRestingInTheMenuBarAlsoDefers() {
        let hovering = MenuBarActivity(isAnyMenuOpen: false, isCursorInMenuBar: true, lastMenuBarClick: nil)

        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .shutdownStarting, menuBar: hovering,
                                                  now: t0, waitingSince: nil),
                       .deferToUser)
    }

    /// A habit-skipped notice is not worth interrupting anyone for, even with the menu bar idle.
    func testANoticeAsksForAttentionRatherThanTakingIt() {
        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .notice, menuBar: .idle,
                                                  now: t0, waitingSince: nil),
                       .requestAttention)
    }

    func testTheShutdownItselfTakesFocusWhenTheMenuBarIsIdle() {
        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .shutdownStarting, menuBar: .idle,
                                                  now: t0, waitingSince: nil),
                       .takeFocus)
    }

    /// A pointer parked in the menu bar must not hold the shutdown off all night.
    func testTheShutdownStillEscalatesAfterWaitingLongEnough() {
        let waitingSince = t0

        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .shutdownStarting, menuBar: menuOpen,
                                                  now: t0.addingTimeInterval(kShutdownFocusMaximumDeferralSeconds - 1),
                                                  waitingSince: waitingSince),
                       .deferToUser)
        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .shutdownStarting, menuBar: menuOpen,
                                                  now: t0.addingTimeInterval(kShutdownFocusMaximumDeferralSeconds),
                                                  waitingSince: waitingSince),
                       .takeFocus)
    }

    /// A notice never escalates, however long it has been waiting — it is not worth a stolen menu.
    func testANoticeNeverEscalates() {
        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .notice, menuBar: menuOpen,
                                                  now: t0.addingTimeInterval(kShutdownFocusMaximumDeferralSeconds * 10),
                                                  waitingSince: t0),
                       .deferToUser)
    }

    /// A click a moment ago means a menu is probably opening right now, even though nothing is on
    /// screen yet — the same quiet period the Do Not Disturb click policy uses.
    func testARecentMenuBarClickStillCountsAsBusy() {
        let justClicked = MenuBarActivity(isAnyMenuOpen: false, isCursorInMenuBar: false,
                                          lastMenuBarClick: t0)

        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .shutdownStarting, menuBar: justClicked,
                                                  now: t0.addingTimeInterval(1), waitingSince: nil),
                       .deferToUser)
        XCTAssertEqual(ShutdownFocusPolicy.decide(urgency: .shutdownStarting, menuBar: justClicked,
                                                  now: t0.addingTimeInterval(kMenuBarQuietPeriodSeconds + 1),
                                                  waitingSince: nil),
                       .takeFocus)
    }
}

// MARK: - Waking the Mac brings the evening routine straight back (report 2026-09-25_22-31-53)
//
// "why is it not in full screen mode currently?" The Mac woke at 22:31:07; the wake handler ended the
// running evening routine so the shutdown check could rebuild it, and that check stayed quiet because
// the state looked the same as the one it last prompted about. The routine (and full screen) only came
// back at 22:36:18, on the ten-minute backstop. Lives here rather than in ShutdownNagPolicyTests because
// CI selects test classes by name and this one is on the list.
extension ShutdownNagPolicyTests {
    private var nagAt: Date { Date(timeIntervalSince1970: 1_790_000_000) }

    private func idleAfterTeardown() -> ShutdownNagSituation {
        ShutdownNagSituation(state: ._NOTHING_, action: Focus_Bear.ACTION._START_, habitIndex: -1, isCutOffPassed: true)
    }

    func testAWakeAfterTheLastPromptBringsTheRoutineBackImmediately() {
        let last = ShutdownNagRecord(situation: idleAfterTeardown(), firedAt: nagAt)
        let fiveMinutesLater = nagAt.addingTimeInterval(293)
        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false, situation: idleAfterTeardown(),
                                                lastNag: last, now: fiveMinutesLater,
                                                routineTornDownForWakeAt: fiveMinutesLater),
                       .fire, "same-looking situation, but the wake ended the routine after the last prompt")
    }

    func testAWakeBeforeTheLastPromptDoesNotBringBackTheFiveSecondNag() {
        let last = ShutdownNagRecord(situation: idleAfterTeardown(), firedAt: nagAt)
        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: false, situation: idleAfterTeardown(),
                                                lastNag: last, now: nagAt.addingTimeInterval(5),
                                                routineTornDownForWakeAt: nagAt.addingTimeInterval(-60)),
                       .stayQuiet, "the prompt already answered that wake; one prompt per situation still holds")
    }

    func testCancellingTonightsShutdownStillWinsOverAWake() {
        let last = ShutdownNagRecord(situation: idleAfterTeardown(), firedAt: nagAt)
        let later = nagAt.addingTimeInterval(120)
        XCTAssertEqual(ShutdownNagPolicy.decide(isShutdownAborted: true, situation: idleAfterTeardown(),
                                                lastNag: last, now: later, routineTornDownForWakeAt: later),
                       .stayQuiet)
    }
}
