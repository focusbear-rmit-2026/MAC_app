//
//  EventsServiceTests.swift
//  Focus BearTests
//
//  The v1/v2 events-stack switch, and the event body checked against the v2 ingest contract.
//

import XCTest
@testable import Focus_Bear

final class EventsServiceTests: XCTestCase {

    // MARK: - Choosing a stack

    func testDefaultsToV2NowThatItIsLiveOnProduction() {
        XCTAssertEqual(EventsEndpoint.defaultEndpoint, .v2)
        XCTAssertEqual(EventsEndpoint.select(environment: [:], arguments: []), .v2)
    }

    func testEnvironmentOverrideForcesV1() {
        let environment = [EventsEndpoint.environmentKey: EventsEndpoint.disabledValue]
        XCTAssertEqual(EventsEndpoint.select(environment: environment, arguments: []), .v1)
    }

    func testLaunchArgumentForcesV1() {
        XCTAssertEqual(EventsEndpoint.select(environment: [:], arguments: [EventsEndpoint.forceV1LaunchArgument]), .v1)
    }

    /// The UI probe (`EventsV2UITests`) pins v2 this way, so it keeps testing v2 whatever the default.
    func testEnvironmentSwitchSelectsV2() {
        let environment = [EventsEndpoint.environmentKey: EventsEndpoint.enabledValue]
        XCTAssertEqual(EventsEndpoint.select(environment: environment, arguments: []), .v2)
    }

    func testV1OverrideWinsOverTheV2Switch() {
        let environment = [EventsEndpoint.environmentKey: EventsEndpoint.enabledValue]
        XCTAssertEqual(EventsEndpoint.select(environment: environment, arguments: [EventsEndpoint.forceV1LaunchArgument]), .v1)
    }

    func testAnyOtherEnvironmentValueKeepsTheDefault() {
        for value in ["", "true", "yes", "false", "v1"] {
            XCTAssertEqual(EventsEndpoint.select(environment: [EventsEndpoint.environmentKey: value], arguments: []),
                           EventsEndpoint.defaultEndpoint, "\"\(value)\" should not switch stacks")
        }
    }

    func testEachStackPostsToItsOwnProductionEventsURL() {
        XCTAssertEqual(EventsEndpoint.v1.url.absoluteString, "https://events.aws.focusbear.io/events")
        XCTAssertEqual(EventsEndpoint.v2.url.absoluteString, "https://events-v2.aws.focusbear.io/events")
    }

    // MARK: - The v2 ingest contract

    /// Every field v2's `TrackEventDto` requires is present with the JSON type it validates, and
    /// nothing else is sent that the whitelist would silently drop, so adding a field fails here
    /// until the fixture (and the server) are updated to match.
    func testPayloadCarriesEveryFieldV2Requires() throws {
        let contract = try loadContract()
        let requiredFields = try XCTUnwrap(contract["required_fields"] as? [String: String])
        let droppedFields = Set(try XCTUnwrap(contract["dropped_by_whitelist"] as? [String]))
        let payload = makePayload(metadata: ["quantity": 5, "nested": ["a": 1]])

        for (field, kind) in requiredFields {
            XCTAssertTrue(value(payload[field], matches: kind), "\(field) should be a \(kind)")
        }
        XCTAssertEqual(Set(payload.keys).subtracting(requiredFields.keys), droppedFields)
    }

    /// The body `EventBuffer` sends must still serialise to exactly the shape the fixture's
    /// server-accepted example has, key for key.
    func testPayloadMatchesTheExampleV2Accepts() throws {
        let contract = try loadContract()
        let accepted = try XCTUnwrap(contract["accepted_example"] as? [String: Any])
        let payload = makePayload(metadata: ["source": "ui-test", "nested": ["a": 1]])

        XCTAssertEqual(Set(payload.keys), Set(accepted.keys))
        let payloadUser = try XCTUnwrap(payload[TrackEventPayload.Key.userProperties] as? [String: Any])
        let acceptedUser = try XCTUnwrap(accepted[TrackEventPayload.Key.userProperties] as? [String: Any])
        XCTAssertEqual(Set(payloadUser.keys), Set(acceptedUser.keys))
        XCTAssertEqual(payload[TrackEventPayload.Key.operatingSystem] as? String,
                       accepted[TrackEventPayload.Key.operatingSystem] as? String)
        XCTAssertNoThrow(try JSONSerialization.data(withJSONObject: [payload]),
                         "EventBuffer posts a JSON array of these")
    }

    func testMetadataIsNestedUnderEventDataData() {
        let payload = makePayload(metadata: ["quantity": 5])
        let eventData = payload[TrackEventPayload.Key.eventData] as? [String: Any]
        let data = eventData?[TrackEventPayload.Key.data] as? [String: Any]
        XCTAssertEqual(data?["quantity"] as? Int, 5, "fanout reads event_data.data.quantity for impact events")
    }

    func testTheFixtureRejectsWhatTheServerRejects() throws {
        let contract = try loadContract()
        let requiredFields = try XCTUnwrap(contract["required_fields"] as? [String: String])
        let rejected = try XCTUnwrap(contract["rejected_examples"] as? [String: [String: Any]])
        for (name, example) in rejected {
            let passes = requiredFields.allSatisfy { value(example[$0.key], matches: $0.value) }
            XCTAssertFalse(passes, "\(name) is rejected by v2 but passes this test's check")
        }
    }

    func testChunksFitInOneV2Request() throws {
        let contract = try loadContract()
        XCTAssertEqual(EventsEndpoint.serverMaxEventsPerRequest, contract["max_batch_size"] as? Int)
        XCTAssertLessThanOrEqual(EventBuffer.maxEventsPerChunk, EventsEndpoint.serverMaxEventsPerRequest)
    }

    // MARK: - Helpers

    private enum FieldKind {
        static let nonEmptyString = "non_empty_string"
        static let string = "string"
        static let object = "object"
    }

    private func makePayload(metadata: [String: Any]) -> [String: Any] {
        TrackEventPayload.make(event: "mac-events-v2-probe", metadata: metadata,
                               userId: "00000000-0000-0000-0000-000000000000", userName: "Test", appVersion: "2.30.0")
    }

    private func value(_ value: Any?, matches kind: String) -> Bool {
        switch kind {
        case FieldKind.nonEmptyString: return (value as? String)?.isEmpty == false
        case FieldKind.string: return value is String
        case FieldKind.object: return value is [String: Any]
        default:
            XCTFail("unknown field kind \(kind) in the fixture")
            return false
        }
    }

    private func loadContract() throws -> [String: Any] {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/events-v2-track-event.v1.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
    }
}
