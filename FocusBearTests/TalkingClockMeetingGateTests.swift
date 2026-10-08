//
//  TalkingClockMeetingGateTests.swift
//  Focus BearTests
//
//  When the talking clock stays silent for a meeting (TalkingClockMeetingGate). Anchored on report
//  2026-10-06_13-30-40: the clock spoke at 13:30 (Teams web) and 16:30 (Google Meet), at the start of
//  meetings Late No More had announced two minutes earlier, with a meeting focus session running —
//  but live detection had not (yet) seen either call.
//

@testable import Focus_Bear
import XCTest

final class TalkingClockMeetingGateTests: XCTestCase {

    private func shouldSuppress(enabled: Bool = true, onMeeting: Bool = false,
                                sessionLive: Bool = false, calendar: Bool = false) -> Bool {
        TalkingClockMeetingGate.shouldSuppress(isSuppressionEnabled: enabled,
                                               isUserOnMeeting: onMeeting,
                                               isMeetingSessionLive: sessionLive,
                                               hasLiveOrImminentAnnouncedMeeting: calendar)
    }

    func testTheReportsStateIsSilent() {
        // 13:30:00 and 16:30:00: detection saw no call, but the session and the calendar did.
        XCTAssertTrue(shouldSuppress(onMeeting: false, sessionLive: true, calendar: true))
    }

    func testEachMeetingSignalSilencesTheClockOnItsOwn() {
        XCTAssertTrue(shouldSuppress(onMeeting: true))
        XCTAssertTrue(shouldSuppress(sessionLive: true))
        XCTAssertTrue(shouldSuppress(calendar: true))
    }

    func testNoMeetingSignalLetsTheClockSpeak() {
        XCTAssertFalse(shouldSuppress())
    }

    func testTurningTheSettingOffAlwaysLetsTheClockSpeak() {
        XCTAssertFalse(shouldSuppress(enabled: false, onMeeting: true, sessionLive: true, calendar: true))
    }

    /// The calendar signal is `MeetingCoverage.hasLiveOrImminentMeeting` over Late No More's
    /// announcements: the 16:30–16:45 meeting announced at 16:27:56.
    func testAnAnnouncedMeetingStartingNowCountsAsLive() {
        let start = Date(timeIntervalSince1970: 1_791_264_600) // any fixed instant
        let meeting = AnnouncedMeeting(title: "Weekly sync", start: start, end: start.addingTimeInterval(15 * 60))
        XCTAssertTrue(MeetingCoverage.hasLiveOrImminentMeeting(now: start, meetings: [meeting]))
        XCTAssertTrue(MeetingCoverage.hasLiveOrImminentMeeting(now: start.addingTimeInterval(-2 * 60), meetings: [meeting]))
        XCTAssertFalse(MeetingCoverage.hasLiveOrImminentMeeting(now: start.addingTimeInterval(16 * 60), meetings: [meeting]))
    }
}
