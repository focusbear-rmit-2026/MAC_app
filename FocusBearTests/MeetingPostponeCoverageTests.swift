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
    // two answers. These pin the rule that the calendar wins.

    func testTheSessionEndsOnlyWhenBothLiveDetectionAndTheCalendarAgreeItIsOver() {
        XCTAssertTrue(MeetingCoverage.shouldAutoEndMeetingSession(isUserOnMeeting: false,
                                                                  hasLiveAnnouncedMeeting: false))
    }

    func testAnAnnouncedMeetingVetoesTheAutoEndWhileDetectionIsQuiet() {
        XCTAssertFalse(MeetingCoverage.shouldAutoEndMeetingSession(isUserOnMeeting: false,
                                                                   hasLiveAnnouncedMeeting: true),
                       "a call being joined looks exactly like a call that ended; the calendar knows better")
    }

    func testLiveDetectionAloneKeepsTheSessionEvenWithNothingOnTheCalendar() {
        XCTAssertFalse(MeetingCoverage.shouldAutoEndMeetingSession(isUserOnMeeting: true,
                                                                   hasLiveAnnouncedMeeting: false),
                       "an unscheduled call is still a call")
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
        // A back-to-back chain running two more hours past this meeting.
        let meetings = [
            AnnouncedMeeting(title: "standup", start: now, end: thisMeetingEnd),
            AnnouncedMeeting(title: "workshop", start: thisMeetingEnd, end: now.addingTimeInterval(140 * 60)),
        ]
        let grace = TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd)

        let routine = MeetingCoverage.postponeSeconds(now: now, meetings: meetings,
                                                      appointmentEnd: thisMeetingEnd, currentPostponeEnd: nil)
        let breaks = MeetingCoverage.breakPostponeSeconds(now: now, appointmentEnd: thisMeetingEnd,
                                                          breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)

        XCTAssertEqual(TimeInterval(routine), 140 * 60 + grace, accuracy: 1,
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

        XCTAssertGreaterThan(old, 8000, "the old rule really did produce a >2h break postpone")
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
            AnnouncedMeeting(title: "workshop", start: thisMeetingEnd, end: now.addingTimeInterval(140 * 60)),
        ]
        let grace = TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd)

        let breaks = MeetingCoverage.postponeSeconds(for: ._MICRO_BREAK_, now: now, meetings: meetings,
                                                     appointmentEnd: thisMeetingEnd, currentPostponeEnd: nil,
                                                     breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)
        let routine = MeetingCoverage.postponeSeconds(for: ._MORNING_HABIT_, now: now, meetings: meetings,
                                                      appointmentEnd: thisMeetingEnd, currentPostponeEnd: nil,
                                                      breaksAllowedDuringMeetings: false, breakIntervalSeconds: 30 * 60)

        XCTAssertEqual(TimeInterval(breaks), 20 * 60 + grace, accuracy: 1)
        XCTAssertEqual(TimeInterval(routine), 140 * 60 + grace, accuracy: 1)
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
        let end = now.addingTimeInterval(90 * 60)
        let meetings = [AnnouncedMeeting(title: "long one", start: now, end: end)]
        let seconds = MeetingCoverage.postponeSeconds(for: ._MORNING_HABIT_, now: now, meetings: meetings,
                                                      appointmentEnd: end, currentPostponeEnd: nil,
                                                      breaksAllowedDuringMeetings: true,
                                                      breakIntervalSeconds: 30 * 60)
        XCTAssertEqual(TimeInterval(seconds), 90 * 60 + TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd),
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

}
