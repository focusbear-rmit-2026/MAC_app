//
//  LateNoMoreEventMatcherTests.swift
//  Focus BearTests
//
//  Locks in the cross-device meeting-matching rule shared by the Mac, the mobile app and the
//  backend (backend#2395 / mobile-app#5108). Ids differ per platform, so the rule is: id when both
//  sides have one, otherwise trimmed + case-folded title with the start times within ±60s.
//

@testable import Focus_Bear
import XCTest

final class LateNoMoreEventMatcherTests: XCTestCase {

    /// A fixed instant, so nothing here depends on when the suite runs.
    private let start = Date(timeIntervalSince1970: 1_757_000_000)

    private func meeting(id: String? = nil, _ title: String, offsetSeconds: TimeInterval = 0) -> LateNoMoreMeeting {
        LateNoMoreMeeting(id: id, title: title, startDate: start.addingTimeInterval(offsetSeconds))
    }

    // MARK: - Fast path: id

    func testMatchesOnExactIdEvenWhenTitleAndStartDiffer() {
        let local = meeting(id: "evt-123", "Standup", offsetSeconds: 3600)
        let incoming = meeting(id: "evt-123", "Completely different name")
        XCTAssertTrue(LateNoMoreEventMatcher.isSameMeeting(local, as: incoming))
    }

    func testDifferentIdsStillFallBackToTitleAndTime() {
        // The whole point of the rule: EventKit's id never equals the backend's id for one meeting.
        let local = meeting(id: "eventkit-abc", "Standup")
        let incoming = meeting(id: "google-xyz", "Standup", offsetSeconds: 10)
        XCTAssertTrue(LateNoMoreEventMatcher.isSameMeeting(local, as: incoming))
    }

    func testEmptyIdIsNotTreatedAsAnIdMatch() {
        let local = meeting(id: "", "Standup")
        let incoming = meeting(id: "", "Retro")
        XCTAssertFalse(LateNoMoreEventMatcher.isSameMeeting(local, as: incoming))
    }

    // MARK: - Title normalisation

    func testMatchesOnTitleIgnoringCaseAndSurroundingWhitespace() {
        let local = meeting("  Daily STANDUP \n")
        let incoming = meeting("daily standup")
        XCTAssertTrue(LateNoMoreEventMatcher.isSameMeeting(local, as: incoming))
    }

    func testDoesNotMatchAnEmptyTitleAgainstAnEmptyTitle() {
        // Two untitled meetings at the same time must not be collapsed into one.
        XCTAssertFalse(LateNoMoreEventMatcher.isSameMeeting(meeting("   "), as: meeting("")))
    }

    // MARK: - Start-time tolerance

    func testMatchesWhenStartIs59SecondsAway() {
        XCTAssertTrue(LateNoMoreEventMatcher.isSameMeeting(meeting("Standup", offsetSeconds: 59),
                                                           as: meeting("Standup")))
    }

    func testMatchesWhenStartIs59SecondsEarly() {
        XCTAssertTrue(LateNoMoreEventMatcher.isSameMeeting(meeting("Standup", offsetSeconds: -59),
                                                           as: meeting("Standup")))
    }

    func testMatchesExactlyAtTheSixtySecondBoundary() {
        XCTAssertTrue(LateNoMoreEventMatcher.isSameMeeting(meeting("Standup", offsetSeconds: 60),
                                                           as: meeting("Standup")))
    }

    func testDoesNotMatchWhenStartIs61SecondsAway() {
        XCTAssertFalse(LateNoMoreEventMatcher.isSameMeeting(meeting("Standup", offsetSeconds: 61),
                                                            as: meeting("Standup")))
    }

    func testDoesNotMatchARecurringMeetingAtADifferentTime() {
        XCTAssertFalse(LateNoMoreEventMatcher.isSameMeeting(meeting("Standup", offsetSeconds: 86_400),
                                                            as: meeting("Standup")))
    }

    // MARK: - No match

    func testDoesNotMatchADifferentTitleAtTheSameTime() {
        XCTAssertFalse(LateNoMoreEventMatcher.isSameMeeting(meeting("Retro"), as: meeting("Standup")))
    }

    func testDoesNotMatchAPrefixOfTheTitle() {
        XCTAssertFalse(LateNoMoreEventMatcher.isSameMeeting(meeting("Standup with design"), as: meeting("Standup")))
    }

    // MARK: - firstMatch over a list

    func testFirstMatchReturnsTheMatchingMeetingFromAList() {
        let candidates = [meeting("Retro"), meeting("Standup", offsetSeconds: 30), meeting("1:1")]
        let match = LateNoMoreEventMatcher.firstMatch(in: candidates, for: meeting("  standup "))
        XCTAssertEqual(match, candidates[1])
    }

    func testFirstMatchReturnsNilWhenNothingMatches() {
        let candidates = [meeting("Retro"), meeting("1:1")]
        XCTAssertNil(LateNoMoreEventMatcher.firstMatch(in: candidates, for: meeting("Standup")))
    }

    func testFirstMatchOnAnEmptyListIsNil() {
        XCTAssertNil(LateNoMoreEventMatcher.firstMatch(in: [], for: meeting("Standup")))
    }

    // MARK: - Dismissal registry (uses the same rule)

    // The registry drops meetings that are hours in the past, so these use a start near now. Titles
    // are unique per test because the registry is a process-wide singleton.
    private func liveMeeting(_ title: String, offsetSeconds: TimeInterval = 0) -> LateNoMoreMeeting {
        LateNoMoreMeeting(title: title, startDate: Date().addingTimeInterval(offsetSeconds))
    }

    func testRegistryRecognisesADismissedMeetingWithinTolerance() {
        let title = "Registry tolerance \(UUID().uuidString)"
        LateNoMoreDismissalRegistry.shared.recordDismissal(of: liveMeeting(title))
        XCTAssertTrue(LateNoMoreDismissalRegistry.shared.isDismissed(liveMeeting(title.uppercased(), offsetSeconds: 45)))
    }

    func testRegistryDoesNotRecogniseADifferentOccurrenceOfTheSameMeeting() {
        let title = "Registry occurrence \(UUID().uuidString)"
        LateNoMoreDismissalRegistry.shared.recordDismissal(of: liveMeeting(title))
        XCTAssertFalse(LateNoMoreDismissalRegistry.shared.isDismissed(liveMeeting(title, offsetSeconds: 3600)))
    }

    func testRegistryReportsAnUnknownMeetingAsNotDismissed() {
        XCTAssertFalse(LateNoMoreDismissalRegistry.shared.isDismissed(liveMeeting("Never dismissed \(UUID().uuidString)")))
    }

    // MARK: - Inbound broadcast (`late-no-more-event-dismissed`)

    private let ownDeviceId = "9f1c2b6e-3d4a-4f5b-8c7d-0e1f2a3b4c5d"
    private let otherDeviceId = "1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d"

    private func broadcast(deviceId: String?, title: String = "Standup",
                           begins: String = "2026-09-14T09:00:00.000Z") -> [String: Any] {
        var payload: [String: Any] = ["notification_type": "late_no_more_event_dismissed",
                                      "event_title": title, "event_begins": begins, "event_id": "abc123"]
        if let deviceId { payload["device_id"] = deviceId }
        return payload
    }

    func testBroadcastFromAnotherDeviceNamesTheMeeting() {
        let meeting = LateNoMoreDismissalDecoder.meetingFromBroadcast(broadcast(deviceId: otherDeviceId), ownDeviceId: ownDeviceId)
        XCTAssertEqual(meeting?.title, "Standup")
        XCTAssertEqual(meeting?.id, "abc123")
        XCTAssertEqual(meeting?.startDate, ISO8601DateFormatter().date(from: "2026-09-14T09:00:00Z"))
    }

    func testOwnEchoIsIgnored() {
        XCTAssertNil(LateNoMoreDismissalDecoder.meetingFromBroadcast(broadcast(deviceId: ownDeviceId), ownDeviceId: ownDeviceId))
    }

    func testBroadcastWithoutDeviceIdIsStillHonoured() {
        // The phone's PATCH path may not identify itself; its dismissal must still reach the Mac.
        XCTAssertNotNil(LateNoMoreDismissalDecoder.meetingFromBroadcast(broadcast(deviceId: nil), ownDeviceId: ownDeviceId))
    }

    func testUnknownOwnDeviceIdDoesNotSwallowSenderlessBroadcasts() {
        // Before the device id has loaded it is "", which must not equal a missing or empty sender.
        XCTAssertNotNil(LateNoMoreDismissalDecoder.meetingFromBroadcast(broadcast(deviceId: ""), ownDeviceId: ""))
    }

    func testBroadcastWithoutTitleOrStartIsIgnored() {
        XCTAssertNil(LateNoMoreDismissalDecoder.meetingFromBroadcast(broadcast(deviceId: otherDeviceId, title: "  "), ownDeviceId: ownDeviceId))
        XCTAssertNil(LateNoMoreDismissalDecoder.meetingFromBroadcast(broadcast(deviceId: otherDeviceId, begins: "not a date"), ownDeviceId: ownDeviceId))
    }

    // MARK: - Late No More app bridge

    func testAcknowledgementFromLateNoMoreRoundTripsWithWholeSecondDates() {
        let sent = LateNoMoreMeeting(title: "Retro", startDate: start)
        var userInfo: [AnyHashable: Any] = LateNoMoreDismissalDecoder.lateNoMoreUserInfo(for: sent)
        userInfo[LateNoMoreBridgeContract.dismissReasonKey] = "joined_on_mac"
        let received = LateNoMoreDismissalDecoder.acknowledgementFromLateNoMore(userInfo)
        XCTAssertEqual(received?.meeting, sent)
        XCTAssertEqual(received?.reason, .joinedOnMac)
    }

    func testAcknowledgementWithAnUnknownReasonFallsBackToStopReminders() {
        var userInfo: [AnyHashable: Any] = LateNoMoreDismissalDecoder.lateNoMoreUserInfo(for: LateNoMoreMeeting(title: "Retro", startDate: start))
        userInfo[LateNoMoreBridgeContract.dismissReasonKey] = "something_new"
        XCTAssertEqual(LateNoMoreDismissalDecoder.acknowledgementFromLateNoMore(userInfo)?.reason, .stopReminders)
    }

    func testMalformedAcknowledgementIsRejected() {
        XCTAssertNil(LateNoMoreDismissalDecoder.acknowledgementFromLateNoMore([LateNoMoreBridgeContract.eventTitleKey: "Retro"]))
        XCTAssertNil(LateNoMoreDismissalDecoder.acknowledgementFromLateNoMore(nil))
    }

    // MARK: - device_id on the report

    func testOnlyAUuidDeviceIdIsReported() {
        XCTAssertEqual(LateNoMoreDismissalDecoder.reportableDeviceId(ownDeviceId), ownDeviceId)
        XCTAssertNil(LateNoMoreDismissalDecoder.reportableDeviceId(""))
        XCTAssertNil(LateNoMoreDismissalDecoder.reportableDeviceId("mac-1234"))
    }
}
