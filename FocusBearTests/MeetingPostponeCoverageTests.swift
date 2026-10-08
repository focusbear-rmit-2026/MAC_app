//
//  MeetingPostponeCoverageTests.swift
//  Focus BearTests
//
//  The meeting-aware postpone rules (MeetingPostponeCoverage.swift): how long a routine postpone
//  has to run so it covers the meetings Late No More announced, that a gapless chain of meetings is
//  treated as one busy block, and that a postpone with nothing ahead of it still ends normally.
//  Everything is pure date maths with the meetings injected, so no timers, windows or UserDefaults
//  are involved.
//
//  Anchored on the incident these rules come from (report 2026-09-15_13-03-02): Lunch 12:45–13:00
//  followed immediately by UX checkin 13:00–13:20, where the postpone collapsed to 160 seconds at
//  13:00 and the "Habit resumes in…" countdown appeared 40 seconds into the UX checkin.
//

@testable import Focus_Bear
import XCTest

final class MeetingPostponeCoverageTests: XCTestCase {

    // MARK: - Fixtures

    /// 15 September 2026, 12:00:00 local — the incident's morning.
    private let noon: Date = {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 15
        components.hour = 12; components.minute = 0; components.second = 0
        return Calendar.current.date(from: components)!
    }()

    /// `minutes` past noon.
    private func time(_ minutes: Double) -> Date { noon.addingTimeInterval(minutes * 60) }

    /// Lunch, 12:45–13:00.
    private var lunch: AnnouncedMeeting { AnnouncedMeeting(title: "Lunch", start: time(45), end: time(60)) }
    /// UX checkin, 13:00–13:20 — starts exactly where Lunch ends.
    private var uxCheckin: AnnouncedMeeting { AnnouncedMeeting(title: "UX checkin", start: time(60), end: time(80)) }

    private var grace: Int { MeetingPostponeRules.graceSecondsAfterMeetingEnd }

    // MARK: - A postpone must cover a meeting starting at the seam

    func testPostponeCoversAMeetingStartingAtTheSeam() {
        // The exact failure: at 13:00 the Lunch popup auto-closes, so its own meeting has zero time
        // left — but UX checkin is starting this very second. The postpone must reach past it
        // (13:20 + grace), not settle for the bare grace period the old `remaining + 160` produced.
        let seconds = MeetingCoverage.postponeSeconds(now: time(60),
                                                      meetings: [lunch, uxCheckin],
                                                      appointmentEnd: time(60),
                                                      currentPostponeEnd: nil)
        XCTAssertEqual(seconds, 20 * 60 + grace)
        XCTAssertNotEqual(seconds, grace, "the old behaviour: a flat 160-second postpone into a live meeting")
    }

    func testPostponeCoversAMeetingThatIsStillImminentRatherThanLive() {
        // Announced two minutes ahead of its start: still inside the imminent window, so the
        // postpone has to span it even though nothing has begun yet.
        let seconds = MeetingCoverage.postponeSeconds(now: time(58),
                                                      meetings: [uxCheckin],
                                                      appointmentEnd: nil,
                                                      currentPostponeEnd: nil)
        XCTAssertEqual(seconds, 22 * 60 + grace)
    }

    // MARK: - Back-to-back meetings are one unbroken block

    func testGaplessChainNeverResumesTheRoutineBetweenMeetings() {
        // Coverage seeded on the live Lunch must chain onto UX checkin, which begins in its seam.
        XCTAssertEqual(MeetingCoverage.coverageEnd(now: time(50), meetings: [lunch, uxCheckin]), time(80))
        // And at no point between the chain's start and its end is the routine allowed to resume.
        for minute in stride(from: 46.0, through: 79.0, by: 1.0) {
            XCTAssertNotNil(MeetingCoverage.extensionSecondsToCoverMeeting(now: time(minute), meetings: [lunch, uxCheckin]),
                            "routine would have resumed at minute \(minute) of the chain")
        }
    }

    func testChainIsOrderIndependent() {
        // Late No More announces meetings as they come up, not in start order.
        XCTAssertEqual(MeetingCoverage.coverageEnd(now: time(50), meetings: [uxCheckin, lunch]), time(80))
    }

    func testAGapWiderThanTheSeamBreaksTheChain() {
        // A meeting an hour later is a separate block: covering it would hold the routine hostage
        // for the whole gap.
        let afternoon = AnnouncedMeeting(title: "Retro", start: time(120), end: time(150))
        XCTAssertEqual(MeetingCoverage.coverageEnd(now: time(50), meetings: [lunch, afternoon]), time(60))
    }

    // MARK: - A postpone with nothing ahead still ends normally

    func testPostponeWithNoMeetingAheadEndsNormally() {
        XCTAssertNil(MeetingCoverage.coverageEnd(now: time(50), meetings: []))
        XCTAssertNil(MeetingCoverage.extensionSecondsToCoverMeeting(now: time(50), meetings: []))
        // The popup's own meeting still sets the postpone; nothing inflates it.
        XCTAssertEqual(MeetingCoverage.postponeSeconds(now: time(50), meetings: [], appointmentEnd: nil, currentPostponeEnd: nil), grace)
    }

    func testMeetingBeyondTheImminentWindowDoesNotHoldTheRoutine() {
        let later = AnnouncedMeeting(title: "Retro", start: time(90), end: time(120))
        XCTAssertNil(MeetingCoverage.extensionSecondsToCoverMeeting(now: time(50), meetings: [later]))
    }

    func testEndedMeetingsAreIgnored() {
        // Lunch is over and nothing follows: the postpone must be allowed to finish.
        XCTAssertNil(MeetingCoverage.extensionSecondsToCoverMeeting(now: time(61), meetings: [lunch]))
    }

    // MARK: - The end-of-postpone countdown is suppressed while a meeting is live

    func testEndNotificationIsSuppressedWhileAMeetingIsLive() {
        // The countdown fires `endNotificationLeadSeconds` before the postpone ends. In the incident
        // that moment was 13:00:40, forty seconds into the UX checkin — an extension is available
        // there, which is what suppresses the countdown.
        let fortySecondsIntoTheMeeting = time(60).addingTimeInterval(40)
        let extensionSeconds = MeetingCoverage.extensionSecondsToCoverMeeting(now: fortySecondsIntoTheMeeting,
                                                                             meetings: [lunch, uxCheckin])
        XCTAssertEqual(extensionSeconds, 20 * 60 - 40 + grace)
    }

    func testEndNotificationIsNotSuppressedOnceTheMeetingsAreOver() {
        XCTAssertNil(MeetingCoverage.extensionSecondsToCoverMeeting(now: time(81), meetings: [lunch, uxCheckin]))
    }

    // MARK: - A postpone is never shortened

    func testAppointmentAutoCloseNeverShortensARunningPostpone() {
        // A popup auto-closing at its meeting's end has no time left to offer; the 15-minute
        // postpone already running must survive it untouched.
        let seconds = MeetingCoverage.postponeSeconds(now: time(60),
                                                      meetings: [],
                                                      appointmentEnd: time(60),
                                                      currentPostponeEnd: time(75))
        XCTAssertEqual(seconds, 15 * 60)
    }

    func testAStalePostponeEndDateCannotShortenTheAnswer() {
        let seconds = MeetingCoverage.postponeSeconds(now: time(60),
                                                      meetings: [uxCheckin],
                                                      appointmentEnd: time(60),
                                                      currentPostponeEnd: time(10))
        XCTAssertEqual(seconds, 20 * 60 + grace)
    }

    // MARK: - Re-pointing the appointment popup

    func testPopupIsRetargetedOnlyByAMeetingThatReachesFurther() {
        // The UX checkin trigger arriving while the Lunch popup is up must take the popup over…
        XCTAssertTrue(MeetingCoverage.shouldRetargetAppointmentPopup(showing: lunch.end, incoming: uxCheckin.end))
        // …while a re-announcement of the meeting already on screen, or a shorter overlapping one,
        // must not shrink the coverage.
        XCTAssertFalse(MeetingCoverage.shouldRetargetAppointmentPopup(showing: uxCheckin.end, incoming: uxCheckin.end))
        XCTAssertFalse(MeetingCoverage.shouldRetargetAppointmentPopup(showing: uxCheckin.end, incoming: lunch.end))
    }

    // MARK: - The register of announced meetings

    func testRegisterReplacesAReannouncedMeetingAndDropsOldOnes() {
        let register = AnnouncedMeetingRegister()
        register.record(title: lunch.title, start: lunch.start, end: lunch.end, now: time(45))
        // Late No More re-fires the same meeting with a corrected end time.
        register.record(title: lunch.title, start: lunch.start, end: time(65), now: time(45))
        XCTAssertEqual(register.activeMeetings(now: time(45)),
                       [AnnouncedMeeting(title: lunch.title, start: lunch.start, end: time(65))])

        // Long after it ended, it is forgotten.
        let wellPastRetention = time(65).addingTimeInterval(TimeInterval(MeetingPostponeRules.meetingRetentionSeconds + 60))
        XCTAssertTrue(register.activeMeetings(now: wellPastRetention).isEmpty)
    }

    func testRegisterFeedsTheIncidentTimelineCorrectly() {
        // Replays the report: Lunch announced at 12:42, UX checkin at 12:57 (the trigger that used
        // to be dropped), and the postpone computed when the Lunch popup auto-closes at 13:00.
        let register = AnnouncedMeetingRegister()
        register.record(title: lunch.title, start: lunch.start, end: lunch.end, now: time(42))
        register.record(title: uxCheckin.title, start: uxCheckin.start, end: uxCheckin.end, now: time(57))

        let seconds = MeetingCoverage.postponeSeconds(now: time(60),
                                                      meetings: register.activeMeetings(now: time(60)),
                                                      appointmentEnd: lunch.end,
                                                      currentPostponeEnd: nil)
        XCTAssertEqual(seconds, 20 * 60 + grace, "the postpone must reach past the UX checkin, not stop at 160 seconds")
    }

    // MARK: - Auto-ending a meeting focus session

    // Report 2026-09-16: the meeting focus session died at 10:00:40 while the user was still
    // joining the call — the browser was walking through Teams' launcher, mic detection went quiet
    // for the whole grace window, and the app read that as "the meeting ended". In the very same
    // second the postpone logic extended itself "to cover a live/imminent meeting". Two subsystems,
    // two answers. These pin the rule that the calendar wins while the user is still joining.

    private var quietEnough: TimeInterval { MeetingSessionAutoEndRules.quietSecondsBeforeEnding }
    private var established: TimeInterval { MeetingSessionAutoEndRules.establishedPresenceSeconds }

    func testTheSessionEndsWhenDetectionIsQuietAndTheCalendarAgreesItIsOver() {
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: false,
                                                       lastPresenceSeconds: nil, quietSeconds: quietEnough),
                       .end)
    }

    func testAnAnnouncedMeetingVetoesTheAutoEndWhileTheUserIsStillJoining() {
        // 2026-09-16: an 8-second pre-join device check, then silence while Teams' launcher loaded.
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: true,
                                                       lastPresenceSeconds: 8, quietSeconds: quietEnough),
                       .keepCalendarSaysStillJoining,
                       "a call being joined looks exactly like a call that ended; the calendar knows better")
    }

    func testAnAnnouncedMeetingVetoesTheAutoEndWhenDetectionNeverSawTheCall() {
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: true,
                                                       lastPresenceSeconds: nil, quietSeconds: .infinity),
                       .keepCalendarSaysStillJoining)
    }

    func testLiveDetectionAloneKeepsTheSessionEvenWithNothingOnTheCalendar() {
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: true, hasLiveAnnouncedMeeting: false,
                                                       lastPresenceSeconds: nil, quietSeconds: .infinity),
                       .keepStillInCall,
                       "an unscheduled call is still a call")
    }

    // MARK: Leaving a meeting before its calendar end (report 2026-09-28_09-53-49)
    //
    // A Teams call was detected from 09:29:29 until 09:53:09, while the calendar entry ran to 10:00.
    // The calendar veto re-armed every 15 seconds, so the session (and the postponed morning routine)
    // waited out the calendar instead of ending 30 seconds after the call did.

    func testLeavingAnEstablishedCallEndsTheSessionAfterThirtyQuietSecondsDespiteTheCalendar() {
        let presence: TimeInterval = 23 * 60 + 40
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: true,
                                                       lastPresenceSeconds: presence, quietSeconds: 30),
                       .end,
                       "the calendar says when the meeting was booked to end, not when the user left it")
    }

    func testTheQuietWindowIsThirtySeconds() {
        XCTAssertEqual(MeetingSessionAutoEndRules.quietSecondsBeforeEnding, 30, "the user asked for 30 seconds")
    }

    func testAWitnessDropoutShorterThanTheQuietWindowDoesNotEndTheSession() {
        // 2026-09-15: four missed 5-second samples (~20s) in the middle of a live Google Meet call.
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: false,
                                                       lastPresenceSeconds: 50 * 60, quietSeconds: 20),
                       .keepNotQuietLongEnough)
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: true,
                                                       lastPresenceSeconds: 50 * 60, quietSeconds: 20),
                       .keepNotQuietLongEnough)
    }

    func testTheCalendarStopsVetoingExactlyAtTheEstablishedPresenceThreshold() {
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: true,
                                                       lastPresenceSeconds: established - 1, quietSeconds: quietEnough),
                       .keepCalendarSaysStillJoining)
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: true,
                                                       lastPresenceSeconds: established, quietSeconds: quietEnough),
                       .end)
    }

    func testAPresenceRunThatResumesWithinTheQuietWindowKeepsItsOriginalStart() {
        let callStart = time(0)
        let dropoutStart = time(20)
        let resumed = dropoutStart.addingTimeInterval(quietEnough - 5)
        XCTAssertEqual(MeetingCoverage.presenceRunStart(now: resumed, previousRunStart: callStart,
                                                        previousRunEnd: dropoutStart),
                       callStart,
                       "a dropout must not reset presence and re-arm the calendar veto for the rest of the call")
    }

    func testAPresenceRunAfterALongSilenceStartsAfresh() {
        let resumed = time(20).addingTimeInterval(quietEnough)
        XCTAssertEqual(MeetingCoverage.presenceRunStart(now: resumed, previousRunStart: time(0),
                                                        previousRunEnd: time(20)),
                       resumed)
    }

    func testTheFirstPresenceRunStartsNow() {
        XCTAssertEqual(MeetingCoverage.presenceRunStart(now: time(5), previousRunStart: nil, previousRunEnd: nil),
                       time(5))
    }

    func testAPreJoinCheckBridgedIntoTheCallCountsAsEstablishedPresence() {
        // 2026-09-16 replay: device check 10:00:17–10:00:25, silent until 10:00:50, then in the call.
        let checkStart = time(0)
        let checkEnd = checkStart.addingTimeInterval(8)
        let joined = checkEnd.addingTimeInterval(25)
        let runStart = MeetingCoverage.presenceRunStart(now: joined, previousRunStart: checkStart,
                                                        previousRunEnd: checkEnd)
        let left = joined.addingTimeInterval(20 * 60)
        XCTAssertEqual(MeetingCoverage.autoEndDecision(isUserOnMeeting: false, hasLiveAnnouncedMeeting: true,
                                                       lastPresenceSeconds: left.timeIntervalSince(runStart),
                                                       quietSeconds: quietEnough),
                       .end)
    }

    func testAMeetingRunningRightNowCountsAsLive() {
        XCTAssertTrue(MeetingCoverage.hasLiveOrImminentMeeting(now: time(50), meetings: [lunch]))
    }

    func testTheVetoLiftsOnceTheLastMeetingHasFinished() {
        XCTAssertFalse(MeetingCoverage.hasLiveOrImminentMeeting(now: time(90), meetings: [lunch, uxCheckin]),
                       "otherwise the session could never end on its own")
    }

    func testABackToBackChainStaysLiveAcrossTheSeam() {
        XCTAssertTrue(MeetingCoverage.hasLiveOrImminentMeeting(now: time(60), meetings: [lunch, uxCheckin]),
                      "the instant Lunch ends and the UX checkin begins is the likeliest moment to end a session wrongly")
    }

    // MARK: A micro-break postpone is not a routine postpone (report 2026-09-21_15-14-47)
    //
    // Acknowledging a meeting reminder while a micro-break was on screen postponed BREAKS by the
    // whole live/imminent chain, because both went through `postponeSeconds`. The user's chain ran
    // to 17:30, so a 30-minute break setting produced "Next break in: 138 minutes".

    func testABreakPostponeCoversOnlyThisMeetingNotTheChain() {
        let now = Date()
        let thisMeetingEnd = now.addingTimeInterval(20 * 60)
        // A back-to-back chain running half an hour past this meeting (inside the postpone cap).
        let meetings = [
            AnnouncedMeeting(title: "standup", start: now, end: thisMeetingEnd),
            AnnouncedMeeting(title: "workshop", start: thisMeetingEnd, end: now.addingTimeInterval(50 * 60)),
        ]
        let grace = TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd)

        let routine = MeetingCoverage.postponeSeconds(now: now, meetings: meetings,
                                                      appointmentEnd: thisMeetingEnd, currentPostponeEnd: nil)
        let breaks = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: thisMeetingEnd,
                                                          breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)

        XCTAssertEqual(TimeInterval(routine), 50 * 60 + grace, accuracy: 1,
                       "the routine still covers the whole chain — that rule is correct and unchanged")
        XCTAssertEqual(TimeInterval(breaks), 20 * 60 + grace, accuracy: 1,
                       "the break comes back after THIS meeting; the seam is when you should stand up")
        XCTAssertLessThan(breaks, routine)
    }

    func testABreakPostponeIgnoresARunningRoutinePostpone() {
        let now = Date()
        let end = now.addingTimeInterval(10 * 60)
        // The routine may be postponed for hours; that must not silence breaks for hours.
        let breaks = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: end,
                                                          breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)
        XCTAssertEqual(TimeInterval(breaks), 10 * 60 + TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd),
                       accuracy: 1)
    }

    func testABreakPostponeStillClearsAMeetingThatHasAlreadyEnded() {
        // The auto-close path fires AT the meeting's end, so appointmentEnd is in the past.
        let now = Date()
        let breaks = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: now.addingTimeInterval(-30),
                                                          breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)
        XCTAssertEqual(breaks, MeetingPostponeRules.graceSecondsAfterMeetingEnd,
                       "never negative, never zero — the grace period is the floor")
    }

    func testABreakPostponeWithNoAppointmentIsJustTheGracePeriod() {
        let now = Date()
        XCTAssertEqual(MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: nil,
                                                          breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60),
                       MeetingPostponeRules.graceSecondsAfterMeetingEnd)
    }

    func testTheReportedCase() {
        // 15:08:38, chain running to 17:30. Old behaviour: 8641s. New: this meeting only.
        let now = Date()
        let thisMeetingEnd = now.addingTimeInterval(22 * 60)
        let meetings = [
            AnnouncedMeeting(title: "a", start: now, end: thisMeetingEnd),
            AnnouncedMeeting(title: "b", start: thisMeetingEnd, end: now.addingTimeInterval(141 * 60)),
        ]
        let old = MeetingCoverage.postponeSeconds(now: now, meetings: meetings,
                                                  appointmentEnd: thisMeetingEnd, currentPostponeEnd: nil)
        let new = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: thisMeetingEnd,
                                                          breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)

        // The routine rule is capped now (it produced 8641s then), but still runs past this meeting.
        XCTAssertGreaterThan(old, 22 * 60 + MeetingPostponeRules.graceSecondsAfterMeetingEnd,
                             "the routine rule covers the chain, not just this meeting")
        XCTAssertLessThan(new, 30 * 60, "the new one stays inside a single break interval")
    }


    /// The dispatch itself, so the distinction is enforced rather than conventional: a mutation
    /// that routes breaks back through the chain rule fails HERE even though `breakPostponeSeconds`
    /// takes no meetings and so cannot chain on its own.
    func testOnlyRecurringRoutinesSkipTheChain() {
        XCTAssertTrue(MeetingCoverage.recursThroughTheDay(._MICRO_BREAK_))
        XCTAssertFalse(MeetingCoverage.recursThroughTheDay(._MORNING_HABIT_))
        XCTAssertFalse(MeetingCoverage.recursThroughTheDay(._EVENING_HABIT_))
        XCTAssertFalse(MeetingCoverage.recursThroughTheDay(._CUSTOM_ROUTINE_))
        XCTAssertFalse(MeetingCoverage.recursThroughTheDay(nil))
    }

    func testTheDispatchGivesBreaksThisMeetingAndRoutinesTheChain() {
        let now = Date()
        let thisMeetingEnd = now.addingTimeInterval(20 * 60)
        let meetings = [
            AnnouncedMeeting(title: "standup", start: now, end: thisMeetingEnd),
            AnnouncedMeeting(title: "workshop", start: thisMeetingEnd, end: now.addingTimeInterval(50 * 60)),
        ]
        let grace = TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd)

        let breaks = MeetingCoverage.postponeSeconds(for: ._MICRO_BREAK_, now: now, meetings: meetings,
                                                     appointmentEnd: thisMeetingEnd, currentPostponeEnd: nil,
                                                     breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)
        let routine = MeetingCoverage.postponeSeconds(for: ._MORNING_HABIT_, now: now, meetings: meetings,
                                                      appointmentEnd: thisMeetingEnd, currentPostponeEnd: nil,
                                                      breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)

        XCTAssertEqual(TimeInterval(breaks), 20 * 60 + grace, accuracy: 1)
        XCTAssertEqual(TimeInterval(routine), 50 * 60 + grace, accuracy: 1)
    }

    func testARunningRoutinePostponeDoesNotSilenceBreaks() {
        // The routine may be postponed for hours; passing that through must not extend the break.
        let now = Date()
        let end = now.addingTimeInterval(10 * 60)
        let breaks = MeetingCoverage.postponeSeconds(for: ._MICRO_BREAK_, now: now, meetings: [],
                                                     appointmentEnd: end,
                                                     currentPostponeEnd: now.addingTimeInterval(3 * 60 * 60),
                                                     breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)
        XCTAssertEqual(TimeInterval(breaks), 10 * 60 + TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd),
                       accuracy: 1, "a 3-hour routine postpone must not become a 3-hour break postpone")
    }


    // MARK: "I have breaks enabled during meetings" (report 2026-09-21_15-14-47, follow-up)
    //
    // Covering only this meeting instead of the whole chain was still wrong for a user with
    // kUserdefaultsShowBreaksInCall on. For them a meeting is not a reason to stop having breaks at
    // all — only a reason to skip the one being dismissed to answer the call.

    func testBreaksDuringMeetingsDeferByOneIntervalNotByTheMeeting() {
        let now = Date()
        let longMeetingEnd = now.addingTimeInterval(90 * 60)

        let allowed = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: longMeetingEnd,
                                                           breaksAllowedDuringMeetings: true,
                                                           breakIntervalSeconds: 30 * 60)
        let notAllowed = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: longMeetingEnd,
                                                              breaksAllowedDuringMeetings: false,
                                                              breakIntervalSeconds: 30 * 60)

        XCTAssertEqual(allowed, 30 * 60, "the normal cadence carries on THROUGH the meeting")
        XCTAssertGreaterThan(notAllowed, 90 * 60, "without the setting, wait the meeting out")
    }

    func testTheSettingIsHonouredThroughTheDispatchToo() {
        let now = Date()
        let end = now.addingTimeInterval(90 * 60)
        let seconds = MeetingCoverage.postponeSeconds(for: ._MICRO_BREAK_, now: now, meetings: [],
                                                      appointmentEnd: end, currentPostponeEnd: nil,
                                                      breaksAllowedDuringMeetings: true,
                                                      breakIntervalSeconds: 30 * 60)
        XCTAssertEqual(seconds, 30 * 60)
    }

    func testTheSettingDoesNotChangeARoutinePostpone() {
        // A morning routine still waits out the chain; "breaks during meetings" says nothing about it.
        let now = Date()
        let end = now.addingTimeInterval(45 * 60)
        let meetings = [AnnouncedMeeting(title: "long one", start: now, end: end)]
        let seconds = MeetingCoverage.postponeSeconds(for: ._MORNING_HABIT_, now: now, meetings: meetings,
                                                      appointmentEnd: end, currentPostponeEnd: nil,
                                                      breaksAllowedDuringMeetings: true,
                                                      breakIntervalSeconds: 30 * 60)
        XCTAssertEqual(TimeInterval(seconds), 45 * 60 + TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd),
                       accuracy: 1)
    }

    func testAZeroBreakIntervalCannotProduceAZeroPostpone() {
        // breakAfterMinutes is a runtime global that defaults to 0 until the server answers.
        let now = Date()
        let seconds = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: now.addingTimeInterval(600),
                                                           breaksAllowedDuringMeetings: true,
                                                           breakIntervalSeconds: 0)
        XCTAssertEqual(seconds, MeetingPostponeRules.graceSecondsAfterMeetingEnd,
                       "a 0s postpone would re-fire the break instantly")
    }

    func testMorningRoutineWaitsForLiveSessionWhileWakeDetectionIsQuiet() {
        XCTAssertTrue(MeetingCoverage.shouldHoldMorningRoutineForMeeting(
            isUserOnMeeting: false, isMeetingSessionLive: true))
        XCTAssertTrue(MeetingCoverage.shouldHoldMorningRoutineForMeeting(
            isUserOnMeeting: true, isMeetingSessionLive: false))
        XCTAssertFalse(MeetingCoverage.shouldHoldMorningRoutineForMeeting(
            isUserOnMeeting: false, isMeetingSessionLive: false),
            "After explicit Stop clears the session, habits can resume")
    }

    func testOldAppointmentTimeoutCannotInterruptFollowingMeetingSession() {
        XCTAssertFalse(MeetingCoverage.shouldResumeRoutineAfterAppointmentTimeout(
            now: time(60), meetings: [], isMeetingSessionLive: true))
    }

    func testOldAppointmentTimeoutPreservesAnnouncedFollowingMeeting() {
        XCTAssertFalse(MeetingCoverage.shouldResumeRoutineAfterAppointmentTimeout(
            now: time(60), meetings: [lunch, uxCheckin], isMeetingSessionLive: false))
    }

    func testAppointmentTimeoutReturnsToHabitsOnceAllMeetingsEnd() {
        XCTAssertTrue(MeetingCoverage.shouldResumeRoutineAfterAppointmentTimeout(
            now: time(90), meetings: [lunch, uxCheckin], isMeetingSessionLive: false))
    }

    func testMeetingAnnouncementCannotShortenAnExistingPostpone() {
        XCTAssertEqual(MeetingCoverage.extensionSecondsToCoverMeeting(now: time(50), meetings: [lunch],
            currentPostponeEnd: time(90)), 40 * 60)
        XCTAssertEqual(MeetingCoverage.extensionSecondsToCoverMeeting(now: time(50), meetings: [lunch],
            currentPostponeEnd: time(55)), 10 * 60 + grace)
    }

}

// MARK: - A meeting-aware postpone is bounded (report 2026-09-25_22-31-53, follow-up)
//
// 26 September, 11:29:59: the "BDA meeting" popup (10:30–11:30) auto-closed at its end and postponed
// the morning routine for 32560 seconds — until 20:32. The chain it covered was "Look after Sean",
// 08:00–20:30: a day-long calendar block announced like any meeting. The routine stayed postponed, so
// it never came back in full screen. All times here are fixed so the tests pass at any hour.

extension MeetingPostponeCoverageTests {

    /// 26 September 2026 at `hour`:`minute`:`second` local.
    private func september26(_ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 26
        components.hour = hour; components.minute = minute; components.second = second
        return Calendar.current.date(from: components)!
    }

    private var lookAfterSean: AnnouncedMeeting {
        AnnouncedMeeting(title: "Look after Sean", start: september26(8, 0), end: september26(20, 30))
    }

    private var bdaMeeting: AnnouncedMeeting {
        AnnouncedMeeting(title: "BDA meeting", start: september26(10, 30), end: september26(11, 30))
    }

    private var maximumPostpone: Int { MeetingPostponeRules.maximumPostponeSeconds }

    func testTheIncidentNoLongerPostponesUntilTheEvening() {
        let seconds = MeetingCoverage.postponeSeconds(now: september26(11, 29, 59),
                                                      meetings: [lookAfterSean, bdaMeeting],
                                                      appointmentEnd: bdaMeeting.end,
                                                      currentPostponeEnd: nil)
        XCTAssertNotEqual(seconds, 32560, "the incident: postponed until 20:32")
        XCTAssertEqual(seconds, 1 + MeetingPostponeRules.graceSecondsAfterMeetingEnd,
                       "only the BDA meeting's last second plus grace is left to cover")
    }

    func testADayLongBlockIsNotAMeeting() {
        XCTAssertFalse(MeetingCoverage.isMeeting(lookAfterSean))
        XCTAssertTrue(MeetingCoverage.isMeeting(bdaMeeting))
        let wholeDay = AnnouncedMeeting(title: "Public holiday", start: september26(0, 0),
                                        end: september26(0, 0).addingTimeInterval(24 * 60 * 60))
        XCTAssertFalse(MeetingCoverage.isMeeting(wholeDay), "an all-day event is not a call")
    }

    func testADayLongBlockNeitherHoldsNorExtendsTheRoutine() {
        let now = september26(9, 0)
        XCTAssertNil(MeetingCoverage.coverageEnd(now: now, meetings: [lookAfterSean]))
        XCTAssertFalse(MeetingCoverage.hasLiveOrImminentMeeting(now: now, meetings: [lookAfterSean]),
                       "it would also veto ending every meeting focus session until 20:30")
        XCTAssertNil(MeetingCoverage.extensionSecondsToCoverMeeting(now: now, meetings: [lookAfterSean]))
    }

    func testAMeetingInsideADayLongBlockIsStillCovered() {
        // The block must be ignored, not the real call running inside it.
        let now = september26(10, 45)
        XCTAssertEqual(MeetingCoverage.coverageEnd(now: now, meetings: [lookAfterSean, bdaMeeting]), bdaMeeting.end)
        let seconds = MeetingCoverage.postponeSeconds(now: now, meetings: [lookAfterSean, bdaMeeting],
                                                      appointmentEnd: bdaMeeting.end, currentPostponeEnd: nil)
        XCTAssertEqual(seconds, 45 * 60 + MeetingPostponeRules.graceSecondsAfterMeetingEnd)
    }

    func testAMeetingThatHasEndedAddsOnlyTheGracePeriod() {
        let seconds = MeetingCoverage.postponeSeconds(now: september26(11, 35), meetings: [bdaMeeting],
                                                      appointmentEnd: bdaMeeting.end, currentPostponeEnd: nil)
        XCTAssertEqual(seconds, MeetingPostponeRules.graceSecondsAfterMeetingEnd)
    }

    func testALongMeetingChainIsCoveredOneCappedStepAtATime() {
        // Three hours of real, back-to-back meetings: each postpone is capped, and the extension that
        // runs before it ends picks the chain up again, so the routine still never resumes mid-call.
        let workshop = AnnouncedMeeting(title: "Workshop", start: september26(13, 0), end: september26(14, 30))
        let review = AnnouncedMeeting(title: "Review", start: september26(14, 30), end: september26(16, 0))
        let now = september26(13, 0)

        let first = MeetingCoverage.postponeSeconds(now: now, meetings: [workshop, review],
                                                    appointmentEnd: workshop.end, currentPostponeEnd: nil)
        XCTAssertEqual(first, maximumPostpone)

        let countdownMoment = now.addingTimeInterval(TimeInterval(first - MeetingPostponeRules.endNotificationLeadSeconds))
        let extensionSeconds = MeetingCoverage.extensionSecondsToCoverMeeting(now: countdownMoment,
                                                                             meetings: [workshop, review])
        XCTAssertEqual(extensionSeconds, maximumPostpone, "an extension is capped too")
    }

    func testTheCapNeverShortensAPostponeTheUserAlreadyHas() {
        let now = september26(13, 0)
        let usersOwnPostponeEnd = now.addingTimeInterval(2 * 60 * 60)
        let seconds = MeetingCoverage.postponeSeconds(now: now, meetings: [], appointmentEnd: nil,
                                                      currentPostponeEnd: usersOwnPostponeEnd)
        XCTAssertEqual(seconds, 2 * 60 * 60)
    }

    // MARK: The postpone lives as long as the meeting session covering it

    func testBorrowedPostponeKeepsItsIndependentDeadline() {
        let now = september26(10, 30)
        let sessionEnd = september26(10, 45)
        let userPostponeSeconds = 60 * 60
        let chainSeconds = MeetingCoverage.postponeSeconds(now: now, meetings: [],
            appointmentEnd: sessionEnd, currentPostponeEnd: now.addingTimeInterval(TimeInterval(userPostponeSeconds)))
        XCTAssertEqual(chainSeconds, userPostponeSeconds)
        XCTAssertEqual(MeetingPostponeSession.postponeSeconds(now: now,
            chainPostponeSeconds: chainSeconds, meetingSessionEnd: sessionEnd,
            ownsRoutinePostpone: false), userPostponeSeconds)
        XCTAssertEqual(MeetingPostponeSession.postponeSeconds(now: now,
            chainPostponeSeconds: chainSeconds, meetingSessionEnd: sessionEnd,
            ownsRoutinePostpone: true), 15 * 60)
    }

    func testThePostponeEndsExactlyWhenTheMeetingSessionDoes() {
        let now = september26(10, 30)
        let sessionEnd = september26(11, 29)
        let seconds = MeetingPostponeSession.postponeSeconds(now: now, chainPostponeSeconds: maximumPostpone,
                                                             meetingSessionEnd: sessionEnd)
        XCTAssertEqual(now.addingTimeInterval(TimeInterval(seconds)), sessionEnd)
    }

    func testWithoutAMeetingSessionTheCappedChainRuleApplies() {
        let now = september26(10, 30)
        XCTAssertEqual(MeetingPostponeSession.postponeSeconds(now: now, chainPostponeSeconds: 1234, meetingSessionEnd: nil), 1234)
        XCTAssertEqual(MeetingPostponeSession.postponeSeconds(now: now, chainPostponeSeconds: 1234,
                                                              meetingSessionEnd: september26(10, 29)),
                       1234, "a session that has already ended covers nothing")
    }

    func testASessionIsSizedInWholeMinutesAndNeverEmpty() {
        XCTAssertEqual(MeetingPostponeSession.sessionMinutes(secondsRemaining: 62 * 60 + 9), 62)
        XCTAssertEqual(MeetingPostponeSession.sessionMinutes(secondsRemaining: 1), 1)
        XCTAssertEqual(MeetingPostponeSession.sessionMinutes(secondsRemaining: -30), 1)
    }

    func testWhenTheSessionRunsOutTheRoutineComesBack() {
        let tiedEnd = september26(11, 29, 51)
        let outcome = MeetingPostponeSession.outcomeWhenSessionRunsOut(
            now: tiedEnd, isRoutinePostponed: true, postponeEnd: tiedEnd, tiedPostponeEnd: tiedEnd,
            meetings: [lookAfterSean, bdaMeeting])
        XCTAssertEqual(outcome, .resumeRoutine,
                       "nine seconds of the BDA meeting are left, and a day-long block is not a follow-on")
    }

    func testAMeetingFollowingStraightOnGetsItsOwnSession() {
        let tiedEnd = september26(11, 29, 51)
        let next = AnnouncedMeeting(title: "Design review", start: september26(11, 30), end: september26(12, 0))
        let outcome = MeetingPostponeSession.outcomeWhenSessionRunsOut(
            now: tiedEnd, isRoutinePostponed: true, postponeEnd: tiedEnd, tiedPostponeEnd: tiedEnd,
            meetings: [bdaMeeting, next])
        XCTAssertEqual(outcome, .continueInto(next))
    }

    func testAPostponeTheUserChoseIsNotEndedByAMeetingSession() {
        let tiedEnd = september26(11, 29, 51)
        let usersOwnPostponeEnd = september26(12, 30)
        let outcome = MeetingPostponeSession.outcomeWhenSessionRunsOut(
            now: tiedEnd, isRoutinePostponed: true, postponeEnd: usersOwnPostponeEnd, tiedPostponeEnd: tiedEnd,
            meetings: [])
        XCTAssertEqual(outcome, .finishNormally)
    }

    func testNothingPostponedMeansTheSessionFinishesNormally() {
        let tiedEnd = september26(11, 29, 51)
        let outcome = MeetingPostponeSession.outcomeWhenSessionRunsOut(
            now: tiedEnd, isRoutinePostponed: false, postponeEnd: tiedEnd, tiedPostponeEnd: tiedEnd, meetings: [])
        XCTAssertEqual(outcome, .finishNormally)
    }

    // MARK: A saved postpone at launch

    private func withScratchDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "mtgpp-restore-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }

    private var endDateKey: String { "mtgpp-end" }
    private var stateKey: String { "mtgpp-state" }
    private var tiedEndDateKey: String { "mtgpp-tied-end" }
    private var capCheckedKey: String { "mtgpp-cap-checked" }

    private func savePostpone(until end: Date, tied: Bool, in defaults: UserDefaults) {
        defaults.set(end, forKey: endDateKey)
        defaults.set(CURRENTSTATE._POSTPONE_MORNING_HABIT_.rawValue, forKey: stateKey)
        if tied { defaults.set(end, forKey: tiedEndDateKey) }
    }

    private func discard(in defaults: UserDefaults, now: Date, meetingSessionEnd: Date?) -> Bool {
        PersistedPostponeRestore.discardInvalidPostpone(in: defaults, now: now, meetingSessionEnd: meetingSessionEnd,
                                                        endDateKey: endDateKey, stateKey: stateKey,
                                                        tiedEndDateKey: tiedEndDateKey, capCheckedKey: capCheckedKey)
    }

    func testAMeetingPostponeWithNoMeetingSessionRunningIsDropped() {
        withScratchDefaults { defaults in
            defaults.set(true, forKey: capCheckedKey)
            savePostpone(until: september26(11, 29), tied: true, in: defaults)

            XCTAssertTrue(discard(in: defaults, now: september26(11, 0), meetingSessionEnd: nil))
            XCTAssertNil(defaults.object(forKey: endDateKey), "the routine must not come back postponed")
            XCTAssertNil(defaults.object(forKey: stateKey))
            XCTAssertNil(defaults.object(forKey: tiedEndDateKey))
        }
    }

    func testAMeetingPostponeWhoseSessionHasEndedIsDropped() {
        withScratchDefaults { defaults in
            defaults.set(true, forKey: capCheckedKey)
            savePostpone(until: september26(11, 29), tied: true, in: defaults)
            XCTAssertTrue(discard(in: defaults, now: september26(11, 0), meetingSessionEnd: september26(10, 59)))
        }
    }

    func testAMeetingPostponeIsRestoredWhileItsSessionIsRunning() {
        withScratchDefaults { defaults in
            defaults.set(true, forKey: capCheckedKey)
            savePostpone(until: september26(11, 29), tied: true, in: defaults)
            XCTAssertFalse(discard(in: defaults, now: september26(11, 0), meetingSessionEnd: september26(11, 29)))
            XCTAssertNotNil(defaults.object(forKey: endDateKey))
        }
    }

    func testTheIncidentsSavedPostponeIsDroppedOnTheFirstLaunchWithTheCap() {
        // Saved by the old build: nine hours long, and no tie recorded.
        withScratchDefaults { defaults in
            savePostpone(until: september26(20, 32, 39), tied: false, in: defaults)
            XCTAssertTrue(discard(in: defaults, now: september26(12, 0), meetingSessionEnd: nil))
            XCTAssertNil(defaults.object(forKey: endDateKey))
        }
    }

    func testAShortUntiedPostponeIsRestoredOnTheFirstLaunch() {
        withScratchDefaults { defaults in
            savePostpone(until: september26(12, 20), tied: false, in: defaults)
            XCTAssertFalse(discard(in: defaults, now: september26(12, 0), meetingSessionEnd: nil))
            XCTAssertEqual(defaults.object(forKey: endDateKey) as? Date, september26(12, 20))
        }
    }

    func testTheCapCheckOnUntiedPostponesRunsOnlyOnce() {
        // After the first launch an untied postpone is one the user chose, however long.
        withScratchDefaults { defaults in
            XCTAssertFalse(discard(in: defaults, now: september26(12, 0), meetingSessionEnd: nil), "nothing saved yet")
            savePostpone(until: september26(15, 0), tied: false, in: defaults)
            XCTAssertFalse(discard(in: defaults, now: september26(12, 5), meetingSessionEnd: nil))
            XCTAssertEqual(defaults.object(forKey: endDateKey) as? Date, september26(15, 0))
        }
    }
}

extension MeetingPostponeCoverageTests {

    // MARK: - Saying what a meeting-held postpone is waiting for (report 2026-09-25_15-36-42)

    /// A 15-minute postpone was stretched to 15:47 for a 15:30–15:45 meeting. The screen must name the
    /// meeting and the real resume time rather than a bare "routine postponed".
    func testALiveMeetingNamesItselfAndThePostponesRealEnd() {
        let postponeEnd = time(62)
        let hold = MeetingCoverage.hold(now: time(50), meetings: [lunch], postponeEnd: postponeEnd)
        XCTAssertEqual(hold?.meeting.title, "Lunch")
        XCTAssertEqual(hold?.resumesAt, postponeEnd)
    }

    func testAnImminentMeetingCountsToo() {
        let startsSoon = AnnouncedMeeting(title: "Standup", start: time(30), end: time(45))
        let justBefore = time(30).addingTimeInterval(-TimeInterval(MeetingPostponeRules.imminentMeetingLeadSeconds))
        XCTAssertEqual(MeetingCoverage.hold(now: justBefore, meetings: [startsSoon], postponeEnd: time(47))?.meeting.title,
                       "Standup")
    }

    func testAnOrdinaryPostponeKeepsThePlainMessage() {
        XCTAssertNil(MeetingCoverage.hold(now: time(10), meetings: [lunch], postponeEnd: time(20)),
                     "the meeting is 35 minutes away, so nothing is being held for it")
        XCTAssertNil(MeetingCoverage.hold(now: time(90), meetings: [lunch, uxCheckin], postponeEnd: time(95)),
                     "both meetings are over")
    }

    func testNoRunningPostponeMeansNoHold() {
        XCTAssertNil(MeetingCoverage.hold(now: time(50), meetings: [lunch], postponeEnd: nil))
        XCTAssertNil(MeetingCoverage.hold(now: time(50), meetings: [lunch], postponeEnd: time(49)),
                     "a postpone that has already ended is not holding anything")
    }

    func testTheChainsCurrentMeetingIsTheOneNamed() {
        // At 13:05 Lunch is over and UX checkin is live: name UX checkin, not the finished one.
        XCTAssertEqual(MeetingCoverage.hold(now: time(65), meetings: [lunch, uxCheckin], postponeEnd: time(83))?.meeting.title,
                       "UX checkin")
    }

}
