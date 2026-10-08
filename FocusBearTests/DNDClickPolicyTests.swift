import XCTest
@testable import Focus_Bear

/// Every Do Not Disturb toggle costs a synthetic option-click into the system menu bar, and that
/// click lands on whatever menu the user has open. Measured on a real machine in one day: 31 state
/// changes, several of them reversals seconds apart — `16:57:57 → true`, `16:58:01 → false`, two
/// menu-bar clicks in four seconds that cancelled each other out.
///
/// The clicking itself can't be tested (it is the system menu bar), so these cover the three
/// decisions in front of it: whether a click is owed, whether it may be posted now, and how much
/// ceremony it needs.
final class DNDClickPolicyTests: XCTestCase {

    private let t0 = Date(timeIntervalSince1970: 1_758_000_000)

    // MARK: - Collapsing a reversal

    /// The reported case: a meeting focus session auto-starts and is cancelled four seconds later.
    func testAReversalInsideTheSettleWindowCostsNoClick() {
        let coalescer = DNDRequestCoalescer()

        XCTAssertNotNil(coalescer.request(true, at: t0, settle: .standard))
        XCTAssertNil(coalescer.request(false, at: t0.addingTimeInterval(4), settle: .standard),
                     "The reversal should cancel the outstanding request outright")

        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(10)), .nothingPending)
        XCTAssertFalse(coalescer.appliedState, "Nothing was ever clicked into the menu bar")
    }

    /// Nobody asked for an auto-started meeting session, so nobody is waiting on its Do Not Disturb —
    /// which is what lets its window be long enough to cover a user who takes ten seconds to notice
    /// the session and stop it.
    func testAnAutoStartedSessionStoppedTenSecondsLaterCostsNoClick() {
        let coalescer = DNDRequestCoalescer()

        XCTAssertNotNil(coalescer.request(true, at: t0, settle: .autoStartedSession))
        XCTAssertNil(coalescer.request(false, at: t0.addingTimeInterval(10), settle: .standard),
                     "Ten seconds is inside the auto-start window measured on a real machine")

        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(30)), .nothingPending)
        XCTAssertFalse(coalescer.appliedState)
    }

    /// A session that finishes and is extended fifteen seconds later is one continuous session, so
    /// the longer settle window has to swallow the release the same way.
    func testAnExtensionCollapsesTheReleaseFromTheCompletedScreen() {
        let coalescer = DNDRequestCoalescer(appliedState: true)

        XCTAssertNotNil(coalescer.request(false, at: t0, settle: .sessionMayBeExtended))
        XCTAssertNil(coalescer.request(true, at: t0.addingTimeInterval(15), settle: .standard))

        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(30)), .nothingPending)
        XCTAssertTrue(coalescer.appliedState, "DND should never have come off")
    }

    // MARK: - Still clicking when it is genuinely wanted

    func testAToggleWithNoReversalStillClicks() {
        let coalescer = DNDRequestCoalescer()

        XCTAssertEqual(coalescer.request(true, at: t0, settle: .standard),
                       t0.addingTimeInterval(kDNDStandardSettleSeconds))
        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(kDNDStandardSettleSeconds)),
                       .toggle(to: true))
        XCTAssertTrue(coalescer.appliedState)
    }

    func testTheClickWaitsOutItsSettleWindow() {
        let coalescer = DNDRequestCoalescer()
        coalescer.request(true, at: t0, settle: .standard)

        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(1)),
                       .notYetDue(deadline: t0.addingTimeInterval(kDNDStandardSettleSeconds)))
        XCTAssertFalse(coalescer.appliedState)
    }

    /// Requests arriving in a run must not be able to push the click out for ever.
    func testARepeatedRequestDoesNotPostponeThePendingClick() {
        let coalescer = DNDRequestCoalescer()
        coalescer.request(true, at: t0, settle: .standard)
        coalescer.request(true, at: t0.addingTimeInterval(5), settle: .standard)

        XCTAssertEqual(coalescer.pendingDeadline, t0.addingTimeInterval(kDNDStandardSettleSeconds))
    }

    /// A request for the state the menu bar is already in is free.
    func testRequestingTheStateAlreadyAppliedAsksForNothing() {
        let coalescer = DNDRequestCoalescer(appliedState: true)
        XCTAssertNil(coalescer.request(true, at: t0, settle: .standard))
        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(60)), .nothingPending)
    }

    /// Turning it on, letting that land, then turning it off is two real clicks, not one.
    func testASeparatedOnAndOffAreBothApplied() {
        let coalescer = DNDRequestCoalescer()

        coalescer.request(true, at: t0, settle: .standard)
        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(6)), .toggle(to: true))

        coalescer.request(false, at: t0.addingTimeInterval(600), settle: .standard)
        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(606)), .toggle(to: false))
        XCTAssertFalse(coalescer.appliedState)
    }

    // MARK: - The last write always wins

    /// Coalescing must never leave the system in the opposite state from the final request. on → off
    /// → on inside one window ends up on, and costs exactly one click.
    func testOnOffOnEndsOnWithASingleClick() {
        let coalescer = DNDRequestCoalescer()

        coalescer.request(true, at: t0, settle: .standard)
        coalescer.request(false, at: t0.addingTimeInterval(1), settle: .standard)
        coalescer.request(true, at: t0.addingTimeInterval(2), settle: .standard)

        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(60)), .toggle(to: true))
        XCTAssertTrue(coalescer.appliedState)
        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(61)), .nothingPending,
                       "Exactly one click, not one per request")
    }

    /// And the mirror: off → on → off from a system that is already on ends off, one click.
    func testOffOnOffEndsOffWithASingleClick() {
        let coalescer = DNDRequestCoalescer(appliedState: true)

        coalescer.request(false, at: t0, settle: .standard)
        coalescer.request(true, at: t0.addingTimeInterval(1), settle: .standard)
        coalescer.request(false, at: t0.addingTimeInterval(2), settle: .standard)

        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(60)), .toggle(to: false))
        XCTAssertFalse(coalescer.appliedState)
    }

    /// A sequence that cancels out costs zero clicks, however many requests it contained.
    func testASequenceThatCancelsOutCostsNoClicks() {
        let coalescer = DNDRequestCoalescer()

        coalescer.request(true, at: t0, settle: .standard)
        coalescer.request(false, at: t0.addingTimeInterval(1), settle: .standard)
        coalescer.request(true, at: t0.addingTimeInterval(2), settle: .standard)
        coalescer.request(false, at: t0.addingTimeInterval(3), settle: .standard)

        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(60)), .nothingPending)
        XCTAssertFalse(coalescer.appliedState)
    }

    // MARK: - Remembering across a relaunch

    /// The app used to forget what it had done to the menu bar whenever it restarted, so the next
    /// "turn it on" clicked a system that was already on — which turns it off. Yesterday's log has
    /// three consecutive "on" state changes with no "off" between them.
    func testCarriesTheAppliedStateAcrossARestart() {
        XCTAssertTrue(DNDStateRestore.restoredState(persisted: true,
                                                    savedAt: t0.addingTimeInterval(-20), now: t0))
    }

    func testDoesNotTrustAStateFromHoursAgo() {
        XCTAssertFalse(DNDStateRestore.restoredState(persisted: true,
                                                     savedAt: t0.addingTimeInterval(-3600), now: t0))
    }

    func testDefaultsToOffWithNothingRecorded() {
        XCTAssertFalse(DNDStateRestore.restoredState(persisted: nil, savedAt: nil, now: t0))
        XCTAssertFalse(DNDStateRestore.restoredState(persisted: true, savedAt: nil, now: t0))
    }

    /// A clock that has gone backwards must not make a stale state look fresh.
    func testIgnoresAStampFromTheFuture() {
        XCTAssertFalse(DNDStateRestore.restoredState(persisted: true,
                                                     savedAt: t0.addingTimeInterval(60), now: t0))
    }

    /// A restart that finds Do Not Disturb already on makes the next "turn it on" free.
    func testAStartAfterARestartWithDNDStillOnClicksNothing() {
        let coalescer = DNDRequestCoalescer(
            appliedState: DNDStateRestore.restoredState(persisted: true,
                                                        savedAt: t0.addingTimeInterval(-10), now: t0))
        XCTAssertNil(coalescer.request(true, at: t0, settle: .standard))
        XCTAssertEqual(coalescer.reconcile(at: t0.addingTimeInterval(60)), .nothingPending)
    }

    // MARK: - Not clicking while the user is using their menu bar

    func testClicksImmediatelyWhenTheMenuBarIsIdle() {
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: .idle, now: t0, waitingSince: nil), .clickNow)
    }

    func testDefersWhileAMenuIsOpen() {
        let activity = MenuBarActivity(isAnyMenuOpen: true, isCursorInMenuBar: false, lastMenuBarClick: nil)
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: activity, now: t0, waitingSince: nil),
                       .waitForTheUser)
    }

    func testDefersWhileTheCursorIsInTheMenuBar() {
        let activity = MenuBarActivity(isAnyMenuOpen: false, isCursorInMenuBar: true, lastMenuBarClick: nil)
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: activity, now: t0, waitingSince: nil),
                       .waitForTheUser)
    }

    /// The opening click is the last thing our monitors see before the menu's own tracking loop takes
    /// over, so a click just now counts as "in use" even with no other signal.
    func testDefersJustAfterAMenuBarClick() {
        let activity = MenuBarActivity(isAnyMenuOpen: false, isCursorInMenuBar: false,
                                       lastMenuBarClick: t0.addingTimeInterval(-1))
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: activity, now: t0, waitingSince: nil),
                       .waitForTheUser)
    }

    func testAnOldMenuBarClickDoesNotDefer() {
        let activity = MenuBarActivity(isAnyMenuOpen: false, isCursorInMenuBar: false,
                                       lastMenuBarClick: t0.addingTimeInterval(-30))
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: activity, now: t0, waitingSince: nil),
                       .clickNow)
    }

    /// The deferral is a delay, not a cancellation: the request is still pending and goes through as
    /// soon as the user is out of the menu bar.
    func testADeferredClickRunsOnceTheMenuBarIsFree() {
        let coalescer = DNDRequestCoalescer()
        coalescer.request(true, at: t0, settle: .standard)

        let busy = MenuBarActivity(isAnyMenuOpen: true, isCursorInMenuBar: false, lastMenuBarClick: nil)
        let due = t0.addingTimeInterval(kDNDStandardSettleSeconds)
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: busy, now: due, waitingSince: nil),
                       .waitForTheUser)
        XCTAssertFalse(coalescer.appliedState, "Deferring must not apply the state early")

        let later = due.addingTimeInterval(4)
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: .idle, now: later, waitingSince: due),
                       .clickNow)
        XCTAssertEqual(coalescer.reconcile(at: later), .toggle(to: true))
    }

    /// A pointer parked in the menu bar must not disable Do Not Disturb for the rest of the day.
    func testGivesUpDeferringAfterTheMaximumWait() {
        let activity = MenuBarActivity(isAnyMenuOpen: true, isCursorInMenuBar: true, lastMenuBarClick: nil)
        let waitingSince = t0.addingTimeInterval(-kMenuBarMaximumDeferralSeconds)
        XCTAssertEqual(MenuBarClickPolicy.decide(activity: activity, now: t0, waitingSince: waitingSince),
                       .clickAnyway)
    }

    // MARK: - Skipping the reveal

    private let screenFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)

    /// The whole point: a permanently visible menu bar needs neither the warp to the top edge nor the
    /// second of waiting for it to slide down, which is the window the stolen clicks land in.
    func testNoRevealWhenTheMenuBarIsPermanentlyVisible() {
        let visible = CGRect(x: 0, y: 0, width: 1512, height: 982 - 37)
        XCTAssertFalse(MenuBarRevealPolicy.needsReveal(screenFrame: screenFrame, visibleFrame: visible,
                                                       prefersAutoHiddenMenuBar: false))
    }

    func testRevealWhenTheMenuBarIsSetToAutoHide() {
        let visible = CGRect(x: 0, y: 0, width: 1512, height: 982)
        XCTAssertTrue(MenuBarRevealPolicy.needsReveal(screenFrame: screenFrame, visibleFrame: visible,
                                                      prefersAutoHiddenMenuBar: true))
    }

    /// The preference can say the menu bar is permanent while something else has taken the screen —
    /// a full-screen app owning the display. Measure as well as ask.
    func testRevealWhenTheMenuBarIsNotOnScreenDespiteThePreference() {
        let visible = CGRect(x: 0, y: 0, width: 1512, height: 982)
        XCTAssertTrue(MenuBarRevealPolicy.needsReveal(screenFrame: screenFrame, visibleFrame: visible,
                                                      prefersAutoHiddenMenuBar: false))
    }

    /// The Dock eats into the bottom of `visibleFrame`, never the top, so it must not read as a
    /// hidden menu bar.
    func testTheDockDoesNotLookLikeAHiddenMenuBar() {
        let visible = CGRect(x: 0, y: 70, width: 1512, height: 982 - 37 - 70)
        XCTAssertTrue(MenuBarRevealPolicy.isMenuBarOnScreen(screenFrame: screenFrame, visibleFrame: visible))
    }
}
