//
//  CutoffPostponeLimitTests.swift
//  Focus BearTests
//
//  The cutoff's say over a routine postpone (CutoffPostponeLimit.swift): a postpone may not end after
//  the user's cutoff time, and once the cutoff has passed a user who marked that window strict may not
//  postpone at all. Pure date maths with the cutoff, the clock and the running postpone injected, so no
//  timers, windows, settings or AI buddy are involved.
//
//  Anchored on the incident these rules come from (report 2026-09-17_17-05-10): cutoff 17:00, the
//  running evening postpone abandoned at 17:00:02 because the cutoff arrived, the shutdown's Focus
//  Summary shown at 17:00:11, and at 17:00:23 the AI accountability buddy granting a 10-minute postpone
//  — to 17:10, past the cutoff, with no password asked.
//

@testable import Focus_Bear
import XCTest

final class CutoffPostponeLimitTests: XCTestCase {

    // MARK: - Fixtures

    /// 17 September 2026, 17:00:00 local — the incident's cutoff time.
    private let cutoff: Date = {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 17
        components.hour = 17; components.minute = 0; components.second = 0
        return Calendar.current.date(from: components)!
    }()

    /// `minutes` either side of the cutoff (negative = before it).
    private func time(_ minutes: Double) -> Date { cutoff.addingTimeInterval(minutes * 60) }

    private func granted(_ requested: Int,
                         at now: Date,
                         cutoff: Date?,
                         isAfterCutoff: Bool = false,
                         running: Date? = nil) -> Int {
        CutoffPostponeLimit.grantedMinutes(requestedMinutes: requested, now: now, cutoff: cutoff,
                                           isAfterCutoff: isAfterCutoff, currentPostponeEnd: running)
    }

    // MARK: - The clamp

    func testPostponeThatFitsBeforeTheCutoffIsUntouched() {
        // 16:30, cutoff 17:00, asking for 20 minutes: it ends at 16:50, so nothing to clamp.
        XCTAssertEqual(granted(20, at: time(-30), cutoff: cutoff), 20)
    }

    func testPostponeCrossingTheCutoffIsClampedToTheCutoff() {
        // 16:48, cutoff 17:00: the dropdown's 30 becomes the 12 minutes that are actually left.
        XCTAssertEqual(granted(30, at: time(-12), cutoff: cutoff), 12)
    }

    func testTheBuddysApprovedDurationIsClampedToo() {
        // The incident's shape, replayed a few minutes earlier: at 16:55 the buddy's 10-minute grant
        // has to come back as 5 — the postpone must hand the user to their routine AT the cutoff.
        XCTAssertEqual(granted(10, at: time(-5), cutoff: cutoff), 5)
    }

    func testPartialMinutesRoundDownSoThePostponeNeverOverrunsTheCutoff() {
        // 16:47:30 — 12.5 minutes left. Rounding up would end the postpone half a minute late.
        XCTAssertEqual(granted(30, at: time(-12.5), cutoff: cutoff), 12)
    }

    func testNoCutoffConfiguredLeavesTheRequestAlone() {
        XCTAssertEqual(granted(90, at: time(-5), cutoff: nil), 90)
    }

    func testPastTheCutoffThereIsNothingToClampToSoTheRequestStands() {
        // With no cutoff ahead the clamp has no ceiling to offer; refusing is `isRefused`'s job, and a
        // non-strict user keeps the behaviour they had. A silent 0-minute postpone would be worse than
        // either answer — it would drop the user straight back into their routine with no explanation.
        XCTAssertEqual(granted(10, at: time(0.5), cutoff: cutoff, isAfterCutoff: true), 10)
    }

    func testTheOvernightWindowIsDrivenByTheFlagNotTheDate() {
        // 03:00 with a 17:00 cutoff: today's cutoff Date is 14 hours away, but we are after YESTERDAY's
        // cutoff. `isAfterCutoff` is what knows that, which is why it is passed in rather than derived.
        let threeAm = cutoff.addingTimeInterval(-14 * 60 * 60)
        XCTAssertEqual(granted(30, at: threeAm, cutoff: cutoff, isAfterCutoff: true), 30)
        XCTAssertEqual(granted(30, at: threeAm, cutoff: cutoff, isAfterCutoff: false), 30,
                       "14 hours of room — the ceiling is far above the request either way")
    }

    // MARK: - The clamp vs. a postpone that is already running

    func testAnAlreadyRunningLongerPostponeIsNotCutShortByTheCutoff() {
        // 16:50, cutoff 17:00, a postpone already running to 17:20 (Late No More covering a meeting).
        // Clamping to 10 would resume the routine mid-call — exactly what MeetingPostponeCoverage
        // exists to prevent. The running postpone wins; AppDelegate still abandons it at the cutoff.
        XCTAssertEqual(granted(30, at: time(-10), cutoff: cutoff, running: time(20)), 30)
    }

    func testTheRunningPostponeFloorAppliesEvenWhenItExceedsTheRequest() {
        // A short request can't shorten a long postpone either: 5 asked, 20 minutes still running.
        XCTAssertEqual(granted(5, at: time(-40), cutoff: cutoff, running: time(-20)), 20)
    }

    func testAShorterRunningPostponeDoesNotRaiseTheClampedResult() {
        // Running to 16:55, cutoff 17:00, asking 30 at 16:48: the ceiling (12) still governs.
        XCTAssertEqual(granted(30, at: time(-12), cutoff: cutoff, running: time(-5)), 12)
    }

    // MARK: - Minutes left before the cutoff (what the dropdown is trimmed to)

    func testMinutesUntilCutoff() {
        XCTAssertEqual(CutoffPostponeLimit.minutesUntilCutoff(now: time(-12), cutoff: cutoff, isAfterCutoff: false), 12)
        XCTAssertNil(CutoffPostponeLimit.minutesUntilCutoff(now: time(-12), cutoff: nil, isAfterCutoff: false),
                     "no cutoff configured — no ceiling")
        XCTAssertNil(CutoffPostponeLimit.minutesUntilCutoff(now: time(1), cutoff: cutoff, isAfterCutoff: true),
                     "already past it — no ceiling")
        XCTAssertNil(CutoffPostponeLimit.minutesUntilCutoff(now: time(-0.5), cutoff: cutoff, isAfterCutoff: false),
                     "less than a whole minute left is no room at all, not a zero-minute postpone")
    }

    // MARK: - The refusal

    func testAfterTheCutoffAStrictUserIsRefused() {
        // The incident: 17:00:23, cutoff 17:00, "require a password to postpone after the cutoff" on.
        XCTAssertTrue(CutoffPostponeLimit.isRefused(hasCutoff: true, isAfterCutoff: true, isCutoffStrict: true))
    }

    func testBeforeTheCutoffEvenAStrictUserMayPostpone() {
        XCTAssertFalse(CutoffPostponeLimit.isRefused(hasCutoff: true, isAfterCutoff: false, isCutoffStrict: true))
    }

    func testWithoutTheAfterCutoffPasswordSettingNothingIsRefused() {
        // The setting is the user's declaration that after the cutoff is different from before it.
        // Someone who never made that declaration keeps the postpone they have always had.
        XCTAssertFalse(CutoffPostponeLimit.isRefused(hasCutoff: true, isAfterCutoff: true, isCutoffStrict: false))
    }

    func testWithNoCutoffConfiguredNothingIsRefused() {
        XCTAssertFalse(CutoffPostponeLimit.isRefused(hasCutoff: false, isAfterCutoff: true, isCutoffStrict: true))
    }
}


final class FocusExtensionCutoffLimitTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func grant(_ request: Int = 5, remaining: TimeInterval? = nil, untilCutoff: TimeInterval? = 60,
                       after: Bool = false, strict: Bool = true, protects: Bool = true) -> Int {
        FocusExtensionCutoffLimit.grantedMinutes(requested: request, now: now,
            currentEnd: remaining.map { now.addingTimeInterval($0) },
            cutoff: untilCutoff.map { now.addingTimeInterval($0) }, isAfterCutoff: after,
            isCutoffStrict: strict, protectsRoutine: protects)
    }

    func testReportedFiveMinuteExtensionWithFortyTwoSecondsLeftCannotCrossCutoff() {
        XCTAssertEqual(grant(remaining: 42, untilCutoff: 60), 0)
        XCTAssertEqual(grant(remaining: 42, untilCutoff: 59), 0, "The last minute is a real limit, never an absent cutoff")
    }

    func testExtraMinutesAreMeasuredFromTheExistingEnd() {
        XCTAssertEqual(grant(remaining: 10 * 60, untilCutoff: 12 * 60), 2)
        XCTAssertEqual(grant(remaining: 42, untilCutoff: 102), 1)
        XCTAssertEqual(grant(remaining: 42, untilCutoff: 101.9), 0)
        XCTAssertEqual(grant(remaining: 15 * 60, untilCutoff: 12 * 60), 0, "An existing longer grant cannot authorize more time")
    }

    func testCompletedSessionRestartsFromNowAndStillRespectsCutoff() {
        XCTAssertEqual(grant(untilCutoff: 120), 2)
        XCTAssertEqual(grant(remaining: -30, untilCutoff: 120), 2)
        XCTAssertEqual(grant(untilCutoff: 59.9), 0)
    }

    func testApprovalAfterCutoffCannotReuseAnEarlierGrant() {
        let cutoff = now.addingTimeInterval(120)
        XCTAssertEqual(grant(untilCutoff: 120), 2)
        XCTAssertEqual(FocusExtensionCutoffLimit.grantedMinutes(requested: 2,
            now: cutoff.addingTimeInterval(1), currentEnd: nil, cutoff: cutoff,
            isAfterCutoff: true, isCutoffStrict: true, protectsRoutine: true), 0)
    }

    func testUnrelatedFocusAndExistingNonStrictAfterCutoffPolicyRemainUnchanged() {
        XCTAssertEqual(grant(after: true, protects: false), 5)
        XCTAssertEqual(grant(untilCutoff: nil), 5)
        XCTAssertEqual(grant(after: true, strict: false), 5)
        XCTAssertEqual(grant(after: true), 0)
        XCTAssertEqual(grant(0), 0)
    }
}
