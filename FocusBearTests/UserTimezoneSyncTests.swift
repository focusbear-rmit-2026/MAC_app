//
//  UserTimezoneSyncTests.swift
//  Focus BearTests
//
//  The declared-timezone sync's "should send?" rule: first run and a changed zone send, an unchanged
//  zone never does, and a fixed-offset identifier (rejected by the backend) is never sent.
//

@testable import Focus_Bear
import XCTest

final class UserTimezoneSyncTests: XCTestCase {

    func testFirstRunSends() {
        XCTAssertTrue(UserTimezoneSyncDecision.shouldSend(current: "Australia/Melbourne", lastSent: nil))
    }

    func testUnchangedZoneIsNotResent() {
        XCTAssertFalse(UserTimezoneSyncDecision.shouldSend(current: "Australia/Melbourne", lastSent: "Australia/Melbourne"))
    }

    func testChangedZoneSends() {
        XCTAssertTrue(UserTimezoneSyncDecision.shouldSend(current: "America/Los_Angeles", lastSent: "Australia/Melbourne"))
    }

    func testFixedOffsetIdentifiersAreNeverSent() {
        // TimeZone.current.identifier can be "GMT+1000" for a fixed-offset zone; the server only accepts IANA names.
        XCTAssertFalse(UserTimezoneSyncDecision.shouldSend(current: "GMT+1000", lastSent: nil))
        XCTAssertFalse(UserTimezoneSyncDecision.isNamedTimeZone("+05:00"))
        XCTAssertTrue(UserTimezoneSyncDecision.isNamedTimeZone("UTC"))
        XCTAssertTrue(UserTimezoneSyncDecision.isNamedTimeZone("Europe/London"))
    }

    func testCurrentMacZoneIsSendable() {
        // Whatever this machine runs in must be a named zone, or the sync would silently never fire.
        XCTAssertTrue(UserTimezoneSyncDecision.isNamedTimeZone(TimeZone.current.identifier))
    }
}
