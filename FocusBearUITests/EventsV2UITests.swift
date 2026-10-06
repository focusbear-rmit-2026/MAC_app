//
//  EventsV2UITests.swift
//  Focus BearUITests
//
//  The events-v2 stack (aws-infra #94) accepts the Mac's analytics payload as the app sends it. The
//  app posts one probe event through its real request path (the signed-in test account's Auth0 token,
//  its headers, the batched body) and reports the HTTP status on its status item
//  (`UITestEventsProbe`).
//
//  It writes to the production events database, for the test account only, so it runs only when the
//  runner opts in: `FOCUSBEAR_EVENTS_V2=1 ./scripts/run-ui-tests.sh -only-testing:…`. v2 is the app's
//  default stack; the launch sets the same variable so the probe stays on v2 even if that changes.
//

import XCTest

final class EventsV2UITests: FocusBearUITestCase {
    /// Sign-in and the first settings fetch (the probe waits for the access token), then one request.
    private static let probeReplyTimeout = firstLaunchTimeout + apiRoundTripTimeout

    func testV2AcceptsTheMacEventPayload() throws {
        typealias Environment = UITestContract.Environment
        typealias Probe = UITestContract.EventsProbe
        guard ProcessInfo.processInfo.environment[EventsEndpoint.environmentKey] == EventsEndpoint.enabledValue else {
            throw XCTSkip("Posts a real event to events-v2; runs only with TEST_RUNNER_\(EventsEndpoint.environmentKey)=\(EventsEndpoint.enabledValue).")
        }
        try launchSignedInWithoutWaiting(environment: [EventsEndpoint.environmentKey: EventsEndpoint.enabledValue,
                                                       Environment.eventsProbe: Environment.enabledValue])

        let statusItem = element(UITestContract.Identifier.MenuBar.statusItem)
        let replied = NSPredicate(format: "value BEGINSWITH %@", Environment.eventsProbeDonePrefix)
        guard waitUntil(replied, isTrueOf: statusItem, within: Self.probeReplyTimeout) else {
            recordDiagnostics(named: "no events probe reply")
            return XCTFail("the app never reported the probe's reply; see the UITestEventsProbe lines in its log")
        }

        let reply = String((statusItem.value as? String ?? "").dropFirst(Environment.eventsProbeDonePrefix.count))
        let fields = reply.split(separator: Probe.fieldSeparator).map(String.init)
        XCTAssertEqual(fields.first, EventsEndpoint.v2.rawValue, "the probe went to the wrong stack: \(reply)")
        let status = Int(fields.last ?? "") ?? 0
        XCTAssertTrue((200...299).contains(status), "events-v2 did not accept the Mac's payload: \(reply)")
        print("EventsV2UITests: events-v2 replied \(reply)")
    }
}
