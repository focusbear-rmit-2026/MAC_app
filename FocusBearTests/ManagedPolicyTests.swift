@testable import Focus_Bear
import XCTest

final class ManagedPolicyTests: XCTestCase {
    private struct PolicyFixture: Decodable {
        struct Case: Decodable {
            struct Classification: Decodable { var categories: [String]; var classificationStatus: String }
            struct Expected: Decodable {
                var policyId: String?
                var active: Bool
                var allowed: Bool
                var reason: String
                var matchedCategories: [String]
            }
            var id: String
            var at: String
            var url: String
            var snapshot: ManagedPolicySnapshot
            var classification: Classification
            var expected: Expected
        }
        var cases: [Case]
    }

    private struct URLFixture: Decodable {
        struct Case: Decodable {
            var id: String
            var input: String
            var valid: Bool
            var normalizedUrl: String?
            var host: String?
            var resourceHash: String?
        }
        var cases: [Case]
    }

    private func data(_ name: String) throws -> Data {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/managed-" + name + ".v1.json")
        return try Data(contentsOf: file)
    }

    func testSharedSchoolHomeRecurrenceHolidayDSTAndFallbackCases() throws {
        let fixture = try ManagedJSON.decoder().decode(PolicyFixture.self, from: data("policy-evaluation"))
        XCTAssertEqual(fixture.cases.count, 55)
        for item in fixture.cases {
            let date = try XCTUnwrap(ManagedDate.parse(item.at), item.id)
            let policy = item.snapshot.activePolicy(at: date)
            XCTAssertEqual(policy?.id, item.expected.policyId, item.id)
            guard let policy = policy else {
                XCTAssertFalse(item.expected.active, item.id)
                XCTAssertTrue(item.expected.allowed, item.id)
                XCTAssertEqual(item.expected.reason, "no_active_policy", item.id)
                continue
            }
            let result = ManagedPolicyEvaluator.offlineDecision(policy, url: item.url, at: date,
                categories: item.classification.categories, status: item.classification.classificationStatus)
            XCTAssertEqual(result.allowed, item.expected.allowed, item.id)
            XCTAssertEqual(result.reason, item.expected.reason, item.id)
            XCTAssertEqual(Set(result.categories), Set(item.expected.matchedCategories), item.id)
        }
    }

    /// The codes and their order are a contract with the backend (`MANAGED_DAY_CODES`) and with the
    /// rest of the app, which has spoken "MON".."SUN" for habits and routines all along. The order
    /// also has to stay the weekday index, because that is what the overnight-window arithmetic
    /// walks backwards through.
    func testDayCodesMatchTheWeekdayIndexTheEvaluatorCountsIn() {
        XCTAssertEqual(ManagedDay.codes, ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"])
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        // 2026-09-20 is a Sunday; walk a full week and check each day against Calendar itself.
        let sunday = try? XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 20)))
        for offset in 0..<7 {
            guard let day = sunday.flatMap({ calendar.date(byAdding: .day, value: offset, to: $0) }) else {
                return XCTFail("Could not build day \(offset)")
            }
            let index = calendar.component(.weekday, from: day) - 1
            XCTAssertEqual(ManagedDay.code(at: index), ManagedDay.codes[index])
            XCTAssertEqual(ManagedDay.index(of: ManagedDay.code(at: index)), index)
        }
        // The evaluator asks for the previous day at the week boundary, so negatives must wrap.
        XCTAssertEqual(ManagedDay.code(at: -1), "SAT")
        XCTAssertEqual(ManagedDay.code(at: 7), "SUN")
        XCTAssertFalse(ManagedDay.isValid("Mon"), "Codes are exact; a near miss must not silently match")
        XCTAssertFalse(ManagedDay.isValid("1"))
        XCTAssertEqual(ManagedDay.ordered(["FRI", "SUN", "TUE"]), ["SUN", "TUE", "FRI"], "Week order, not alphabetical")
        XCTAssertEqual(ManagedDay.ordered(["FRI", "nope"]), ["FRI"])
    }

    /// Two orderings of the same seven tokens live in this app: this one is Sunday-first because its
    /// position is a weekday index, and `HabitEditValues.weekdayCodes` is Monday-first because it is
    /// what a person reads. That split is the confusion `days_of_week` used to have, so the one
    /// thing that must never drift — the vocabulary itself — is asserted here.
    func testManagedDayCodesAreTheSameTokensHabitsUse() {
        XCTAssertEqual(Set(ManagedDay.codes), Set(HabitEditValues.weekdayCodes))
        XCTAssertEqual(ManagedDay.codes.count, HabitEditValues.weekdayCodes.count)
        XCTAssertNotEqual(ManagedDay.codes, HabitEditValues.weekdayCodes, "Different order, deliberately")
        // A habit day handed straight to a managed window must be understood, not silently dropped.
        for code in HabitEditValues.weekdayCodes {
            XCTAssertTrue(ManagedDay.isValid(code), code)
        }
    }

    func testSharedURLNormalizationAndResourceHashCases() throws {
        let fixture = try ManagedJSON.decoder().decode(URLFixture.self, from: data("url-normalization"))
        XCTAssertEqual(fixture.cases.count, 21)
        for item in fixture.cases {
            let resource = ManagedResource(item.input)
            XCTAssertEqual(resource != nil, item.valid, item.id)
            if item.valid {
                XCTAssertEqual(resource?.normalizedURL, item.normalizedUrl, item.id)
                XCTAssertEqual(resource?.host, item.host, item.id)
                XCTAssertEqual(resource?.hash, item.resourceHash, item.id)
            }
        }
    }

    /// `Fixtures/managed-wire-examples.v1.json` is a copy of the backend module's own
    /// `fixtures/wire-examples.v1.json`, so the two sides describe one contract. The copy had drifted
    /// into a subset that omitted `blocked_category` and `approved_safety_appeal` — the only two
    /// responses carrying a policy and a classification, and the two this client exists to act on —
    /// so asserting decodability alone let the interesting half of the contract go unchecked. Name
    /// every shape and read the fields back out: a fixture that loses one now fails here.
    func testWireUnionAndMinimalReportDecoding() throws {
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data("wire-examples")) as? [String: Any])
        let decoder = ManagedJSON.decoder()
        func decode<T: Decodable>(_ type: T.Type, _ key: String) throws -> T {
            try decoder.decode(type, from: JSONSerialization.data(withJSONObject: try XCTUnwrap(object[key], key)))
        }

        let snapshot = try decode(ManagedPolicySnapshot.self, "snapshot")
        XCTAssertEqual(snapshot.schemaVersion, 1)
        XCTAssertEqual(snapshot.snapshotId?.count, 64)

        let examples = try XCTUnwrap(object["online_responses"] as? [[String: Any]])
        let decisions = try examples.map {
            try decoder.decode(ManagedURLDecision.self, from: JSONSerialization.data(withJSONObject: $0))
        }
        XCTAssertEqual(Set(decisions.map(\.reason)), ["no_active_policy", "no_blocked_categories",
            "policy_allowlist", "policy_changed_retry", "blocked_category", "approved_safety_appeal"])

        let blocked = try XCTUnwrap(decisions.first { $0.reason == "blocked_category" })
        XCTAssertFalse(blocked.allowed)
        XCTAssertEqual(blocked.active, true)
        XCTAssertEqual(blocked.matchedCategories, ["games"])
        XCTAssertEqual(blocked.policy?.kind, "school")
        XCTAssertEqual(blocked.policy?.windows.first?.daysOfWeek, ["MON", "TUE", "WED", "THU", "FRI"],
                       "A school week the client must recognise")
        XCTAssertEqual(blocked.classification?.categories, ["games"])
        XCTAssertNotNil(blocked.classification.flatMap { ManagedDate.parse($0.expiresAt) })

        // An approved appeal is signalled by the decision, not by the appeal it carries: the inline
        // shape has an id, a reason and an expiry but no status. `ManagedBlockingRuntime` reads only
        // `decision.appeal == nil`, which is the right test — reading a status here would always be nil.
        let appealed = try XCTUnwrap(decisions.first { $0.reason == "approved_safety_appeal" })
        XCTAssertTrue(appealed.allowed)
        let appeal = try XCTUnwrap(appealed.appeal)
        XCTAssertNil(appeal.status)
        XCTAssertFalse(appeal.id.isEmpty)
        XCTAssertNotNil(appeal.expiresAt.flatMap(ManagedDate.parse))
        XCTAssertEqual(appealed.policy?.kind, "school", "An appeal allows a URL, it does not retire the school policy")

        let batch = try decode(ManagedViolationResults.self, "minimal_batch_response")
        XCTAssertEqual(batch.results.count, 2)
        XCTAssertEqual(Set(batch.results.map(\.status)), Set(["accepted", "rejected"]))
    }

    /// The parent edit session is the only way a home rule changes from the device, and every step of
    /// it crosses this wire. Nothing decoded these shapes before, so a server-side rename would have
    /// surfaced as a parent approval that silently never arrives.
    func testParentEditSessionWireShapesDecodeThroughTheWholeApproval() throws {
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data("wire-examples")) as? [String: Any])
        let decoder = ManagedJSON.decoder()
        func request(_ key: String) throws -> ManagedSettingsRequest {
            try decoder.decode(ManagedSettingsRequest.self,
                from: JSONSerialization.data(withJSONObject: try XCTUnwrap(object[key], key)))
        }

        let pending = try request("settings_pending_response")
        XCTAssertEqual(pending.status, "pending")
        XCTAssertEqual(pending.scope, ["blocked_categories"])
        XCTAssertEqual(pending.before?.kind, "home")
        XCTAssertNil(pending.proposedChanges, "Nothing is proposed until the parent has approved")

        let approved = try request("settings_approved_response")
        let expiry = try XCTUnwrap(ManagedDate.parse(approved.expiresAt))
        XCTAssertTrue(approved.permitsProposal(deviceId: approved.deviceId,
            revision: approved.baseRevision, at: expiry.addingTimeInterval(-1)))
        XCTAssertFalse(approved.permitsProposal(deviceId: approved.deviceId,
            revision: approved.baseRevision, at: expiry), "The session is exclusive of its own expiry")

        let proposed = try request("settings_proposed_response")
        let changes = try XCTUnwrap(proposed.proposedChanges)
        XCTAssertEqual(changes.blockedCategories, ["adult", "gambling"])
        XCTAssertEqual(changes.windows.first?.allDay, true)
        XCTAssertEqual(proposed.changesHash?.count, 64)
        XCTAssertFalse(proposed.permitsProposal(deviceId: proposed.deviceId,
            revision: proposed.baseRevision, at: expiry.addingTimeInterval(-1)),
            "One proposal per approval; a second must not be accepted")

        XCTAssertTrue(ManagedPolicyChanges.editableFields.contains(try XCTUnwrap(pending.scope.first)),
                      "A scope the server issues must be one this client agrees is editable")
    }

    func testProposalRequiresOwnedDeviceCurrentRevisionAndExclusiveExpiry() throws {
        let expiry = try XCTUnwrap(ManagedDate.parse("2026-09-09T10:05:00Z"))
        var request = ManagedSettingsRequest(id: "request", deviceId: "owned", policyId: "home",
            scope: ["windows"], baseRevision: 4, status: "approved", expiresAt: ManagedDate.string(expiry))
        XCTAssertTrue(request.permitsProposal(deviceId: "owned", revision: 4, at: expiry.addingTimeInterval(-1)))
        XCTAssertFalse(request.permitsProposal(deviceId: "other", revision: 4, at: expiry.addingTimeInterval(-1)))
        XCTAssertFalse(request.permitsProposal(deviceId: "owned", revision: 5, at: expiry.addingTimeInterval(-1)))
        XCTAssertFalse(request.permitsProposal(deviceId: "owned", revision: 4, at: expiry))
        request.status = "proposed"
        XCTAssertFalse(request.permitsProposal(deviceId: "owned", revision: 4, at: expiry.addingTimeInterval(-1)))
    }

    func testRecoveryAllowlistIsExactFirstPartyHTTPSOnly() throws {
        XCTAssertTrue(ManagedBrowserAccess.isEssential(try XCTUnwrap(ManagedResource("https://app.focusbear.io/login"))))
        for value in ["https://app.focusbear.io.evil.example/", "http://app.focusbear.io/", "https://app.focusbear.io:8443/", "https://example.org/"] {
            XCTAssertFalse(ManagedBrowserAccess.isEssential(try XCTUnwrap(ManagedResource(value))), value)
        }
    }

    func testQueuedReportCannotSerializePageURLTitleOrQuery() throws {
        let resource = try XCTUnwrap(ManagedResource("https://example.org/private/path?token=secret#fragment"))
        let event = ManagedViolationEvent(eventId: "event", deviceId: "device", policyId: "policy", policyRevision: 2,
            domain: resource.host, resourceHash: resource.hash, categoryIds: ["games"], observedAt: "2026-09-09T10:00:00Z")
        let json = try XCTUnwrap(String(data: ManagedJSON.encoder().encode(event), encoding: .utf8))
        XCTAssertFalse(json.contains("token"))
        XCTAssertFalse(json.contains("private/path"))
        XCTAssertFalse(json.contains("fragment"))
        XCTAssertTrue(json.contains("resource_hash"))
        XCTAssertTrue(json.contains("example.org"))
    }

    private func activeSnapshot() throws -> ManagedPolicySnapshot {
        let fixtures = try ManagedJSON.decoder().decode(PolicyFixture.self, from: data("policy-evaluation"))
        return try XCTUnwrap(fixtures.cases.last).snapshot
    }

    func testSupervisedIdentityCannotSwitchAccountsOrForgetEnrollmentOnDeviceChange() {
        XCTAssertFalse(ManagedIdentityRules.permitsSwitch(isSupervised: true, currentUser: "student", newUser: "other"))
        XCTAssertTrue(ManagedIdentityRules.permitsSwitch(isSupervised: false, currentUser: "student", newUser: "other"))
        XCTAssertTrue(ManagedIdentityRules.requiresManagedDeviceRecovery(isSupervised: true, currentUser: "student", newUser: "student", currentDevice: "old", newDevice: "new"))
        XCTAssertFalse(ManagedIdentityRules.requiresManagedDeviceRecovery(isSupervised: false, currentUser: "student", newUser: "student", currentDevice: "old", newDevice: "new"))
        XCTAssertFalse(ManagedIdentityRules.requiresManagedDeviceRecovery(isSupervised: true, currentUser: "student", newUser: "student", currentDevice: "same", newDevice: "same"))
    }

    func testAPIIdentityRemainsBoundToTheCallerAcrossDeferredAuthentication() {
        let identity = ManagedAPIIdentity(userId: "student-a", deviceId: "device-a")
        XCTAssertTrue(identity.matches(user: "student-a", device: "device-a"))
        XCTAssertFalse(identity.matches(user: "student-b", device: "device-a"))
        XCTAssertFalse(identity.matches(user: "student-a", device: "device-b"))
        XCTAssertFalse(identity.matches(user: nil, device: "device-a"))
        XCTAssertFalse(ManagedAPIIdentity(userId: "", deviceId: "").matches(user: "", device: ""))
    }

    func testColdStartClockUncertaintyAndExclusiveLeaseExpiryRequireRecovery() throws {
        let snapshot = try activeSnapshot()
        let now = try XCTUnwrap(snapshot.serverTime.flatMap(ManagedDate.parse))
        XCTAssertTrue(ManagedPolicyLease.isUsable(snapshot, clockStatus: "trusted", at: now))
        XCTAssertFalse(ManagedPolicyLease.isUsable(snapshot, clockStatus: "uncertain", at: now))
        XCTAssertFalse(ManagedPolicyLease.isUsable(snapshot, clockStatus: "rollback_detected", at: now))
        let expiry = try XCTUnwrap(snapshot.offlineValidUntil.flatMap(ManagedDate.parse))
        XCTAssertFalse(ManagedPolicyLease.isUsable(snapshot, clockStatus: "trusted", at: expiry))
    }

    func testQueuedNavigationRejectsOldSessionRevisionAndFinishedSchoolWindow() throws {
        var snapshot = try activeSnapshot()
        let now = try XCTUnwrap(snapshot.serverTime.flatMap(ManagedDate.parse))
        let policy = try XCTUnwrap(snapshot.activePolicy(at: now))
        let gate = ManagedNavigationGate()
        let session = UUID()
        let binding = ManagedEnforcementBinding(snapshotId: snapshot.snapshotId, session: session,
            policyId: policy.id, revision: policy.revision, recovery: false)
        gate.update(snapshot: snapshot, managed: true, session: session, recovery: false, denied: [], now: now)
        XCTAssertTrue(gate.permits(binding))
        gate.update(snapshot: snapshot, managed: true, session: UUID(), recovery: false, denied: [], now: now)
        XCTAssertFalse(gate.permits(binding))
        snapshot.school?.revision += 1
        gate.update(snapshot: snapshot, managed: true, session: session, recovery: false, denied: [], now: now)
        XCTAssertFalse(gate.permits(binding))
        snapshot.school?.revision = policy.revision
        let end = try XCTUnwrap(ManagedDate.parse("2026-09-07T15:00:00Z"))
        gate.update(snapshot: snapshot, managed: true, session: session, recovery: false, denied: [], now: end)
        XCTAssertFalse(gate.permits(binding))
        gate.update(snapshot: snapshot, managed: true, session: session, recovery: true, denied: [], now: now)
        XCTAssertFalse(gate.permitsRevisit(binding))
        XCTAssertTrue(gate.denies(try XCTUnwrap(ManagedResource("https://example.org/"))))
        XCTAssertFalse(gate.denies(try XCTUnwrap(ManagedResource("https://app.focusbear.io/login"))))
    }

    func testPartialCachedPositiveCategoryCannotBeOverriddenByUnavailableAllow() throws {
        let snapshot = try activeSnapshot()
        let now = try XCTUnwrap(snapshot.serverTime.flatMap(ManagedDate.parse))
        var policy = try XCTUnwrap(snapshot.activePolicy(at: now))
        policy.blockedCategories = ["games", "malware"]
        policy.unavailableAction = "allow"
        let resource = try XCTUnwrap(ManagedResource("https://example.org/game"))
        var classification = ManagedClassification(taxonomyVersion: ManagedPolicyEvaluator.taxonomyVersion,
            modelVersion: "test", classificationStatus: "unavailable", categories: ["games"],
            evaluatedCategories: ["games"], expiresAt: ManagedDate.string(now.addingTimeInterval(30)))
        let decision = try XCTUnwrap(ManagedPolicyEvaluator.cachedDecision(classification, policy: policy, resource: resource, at: now))
        XCTAssertFalse(decision.allowed)
        XCTAssertEqual(decision.categories, ["games"])
        classification.expiresAt = ManagedDate.string(now)
        XCTAssertNil(ManagedPolicyEvaluator.cachedDecision(classification, policy: policy, resource: resource, at: now))
    }

    func testMalformedHTTPNavigationCannotUseLegacyBuddyReopeningToBypassFallback() throws {
        var snapshot = try activeSnapshot()
        let now = try XCTUnwrap(snapshot.serverTime.flatMap(ManagedDate.parse))
        let session = UUID()
        let gate = ManagedNavigationGate()
        gate.update(snapshot: snapshot, managed: true, session: session, recovery: false, denied: [], now: now)
        XCTAssertTrue(gate.deniesMalformedWebsite("https://example.org/invalid%"))
        XCTAssertFalse(gate.deniesMalformedWebsite("about:blank"))
        snapshot.school?.unavailableAction = "allow"
        gate.update(snapshot: snapshot, managed: true, session: session, recovery: false, denied: [], now: now)
        XCTAssertFalse(gate.deniesMalformedWebsite("https://example.org/invalid%"))
        snapshot.school?.blockedCategories.append("not_resolved")
        gate.update(snapshot: snapshot, managed: true, session: session, recovery: false, denied: [], now: now)
        XCTAssertTrue(gate.deniesMalformedWebsite("https://example.org/invalid%"))
    }

}

final class ManagedSafetyPrecedenceTests: XCTestCase {
    private let now = ManagedDate.parse("2026-09-18T10:00:00Z")!
    private let url = "https://www.roblox.com/"

    private func policy(_ id: String) -> ManagedPolicy {
        ManagedPolicy(id: id, schoolId: "school", kind: id, revision: 1, status: "published", name: id,
            timeZone: "UTC", isEnabled: true,
            windows: [.init(daysOfWeek: ManagedDay.codes, startTime: "00:00", endTime: "00:00", allDay: true)],
            blockedCategories: ["games"], allowlist: [], excludedDates: [], unknownAction: "allow", unavailableAction: "allow")
    }

    private func snapshot(school: ManagedPolicy?, home: ManagedPolicy?) -> ManagedPolicySnapshot {
        ManagedPolicySnapshot(school: school, home: home, settingsLocked: true, schemaVersion: 1,
            serverTime: ManagedDate.string(now), offlineValidUntil: ManagedDate.string(now.addingTimeInterval(3600)),
            snapshotId: String(repeating: "a", count: 64))
    }

    func testSchoolOverridesHomeAllowAndHomeResumesOutsideSchoolWindow() throws {
        var school = policy("school")
        school.windows = [.init(daysOfWeek: ["FRI"], startTime: "09:00", endTime: "10:01", allDay: false)]
        var home = policy("home")
        home.allowlist = [.init(url: url, includeSubdomains: false)]
        let state = snapshot(school: school, home: home)
        let selected = try XCTUnwrap(state.activePolicy(at: now))
        XCTAssertEqual(selected.id, "school")
        XCTAssertFalse(ManagedPolicyEvaluator.offlineDecision(selected, url: url, at: now,
            categories: ["games"], status: "classified").allowed)
        let afterSchool = now.addingTimeInterval(60)
        let outside = try XCTUnwrap(state.activePolicy(at: afterSchool))
        XCTAssertEqual(outside.id, "home")
        XCTAssertTrue(ManagedPolicyEvaluator.offlineDecision(outside, url: url, at: afterSchool,
            categories: ["games"], status: "classified").allowed)
    }

    func testSafetyNavigationGateDeniesKnownResourceUntilScheduleEnd() throws {
        var school = policy("school")
        school.windows = [.init(daysOfWeek: ["FRI"], startTime: "09:00", endTime: "10:01", allDay: false)]
        let state = snapshot(school: school, home: nil)
        let gate = ManagedNavigationGate()
        let resource = try XCTUnwrap(ManagedResource(url))
        let denied: Set<String> = ["school:1:" + resource.hash]
        gate.update(snapshot: state, managed: true, session: UUID(), recovery: false, denied: denied, now: now)
        XCTAssertTrue(gate.denies(resource))
        gate.update(snapshot: state, managed: true, session: UUID(), recovery: false, denied: denied,
                    now: now.addingTimeInterval(60))
        XCTAssertFalse(gate.denies(resource), "An inactive safety window must stop deferring personal enforcement")
    }

    func testSafetyAllowContinuesToPersonalRestrictionsAndNeverCreatesGlobalAllow() throws {
        var school = policy("school")
        school.allowlist = [.init(url: url, includeSubdomains: false)]
        let state = snapshot(school: school, home: nil)
        let gate = ManagedNavigationGate()
        gate.update(snapshot: state, managed: true, session: UUID(), recovery: false, denied: [], now: now)
        XCTAssertTrue(ManagedPolicyEvaluator.offlineDecision(school, url: url, at: now,
            categories: ["games"], status: "classified").allowed)
        XCTAssertFalse(gate.denies(try XCTUnwrap(ManagedResource(url))), "False continues personal/habit enforcement")
    }

    func testManagedChromeObservationBindsProcessWindowAndTabWithoutBlankWindowFallback() throws {
        let properties = NSAppleEventDescriptor.record()
        properties.setDescriptor(.init(int32: 23), forKeyword: ChromeProcessTabs.code("ID  "))
        properties.setDescriptor(.init(string: "about:blank"), forKeyword: ChromeProcessTabs.code("URL "))
        var replies: [NSAppleEventDescriptor] = [.init(int32: 17), properties, .init(int32: 17), .init(int32: 23)]
        let result = try XCTUnwrap(ManagedBrowserAccess.chromeObservation(pid: 123) { _ in replies.removeFirst() })
        XCTAssertEqual(result.processId, 123)
        XCTAssertEqual(result.windowId, 17)
        XCTAssertEqual(result.tabId, 23)
        XCTAssertEqual(result.url, "about:blank")
        replies = [.init(int32: 17), properties, .init(int32: 18)]
        XCTAssertNil(try ManagedBrowserAccess.chromeObservation(pid: 123) { _ in replies.removeFirst() })
    }
}

/// The keychain ACL binds an item to the signature that wrote it, and the failure it produces is a
/// password sheet on the launch screen rather than an error the app can handle. These cover the two
/// properties that keep that sheet away: interaction stays suppressed only for the Security call
/// itself, and a cache the current signature cannot open is dropped instead of wedging supervision.
final class ManagedPolicyStoreAccessTests: XCTestCase {
    private func temporaryDirectory() throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("managed-store-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory
    }

    func testSignatureScopeIsStableWithinTheProcessAndNarrowsTheAccount() {
        let scope = ManagedKeychain.signatureScope
        XCTAssertFalse(scope.isEmpty)
        XCTAssertEqual(scope, ManagedKeychain.signatureScope)
        XCTAssertLessThanOrEqual(scope.count, 16, "A scope longer than the hash prefix means the lookup changed shape")
    }

    /// Auth0 reads the login keychain from other call sites, so leaving interaction disabled would
    /// turn a prompt they can answer into a sign-out they cannot.
    func testInteractionIsRestoredAfterASuppressedCallAndAfterOneThatFails() {
        var allowed: DarwinBoolean = false
        XCTAssertEqual(ManagedKeychain.withoutPrompting { errSecSuccess }, errSecSuccess)
        XCTAssertEqual(SecKeychainGetUserInteractionAllowed(&allowed), errSecSuccess)
        XCTAssertTrue(allowed.boolValue, "A completed call must hand user interaction back")

        XCTAssertEqual(ManagedKeychain.withoutPrompting { errSecAuthFailed }, errSecAuthFailed)
        XCTAssertEqual(SecKeychainGetUserInteractionAllowed(&allowed), errSecSuccess)
        XCTAssertTrue(allowed.boolValue, "A failed call must hand user interaction back too")
    }

    func testUnopenableCacheIsDiscardedRatherThanReportedAsAStorageFailure() throws {
        let directory = try temporaryDirectory()
        let store = ManagedPolicyStore(directory: directory,
            defaults: try XCTUnwrap(UserDefaults(suiteName: "managed-store-" + UUID().uuidString)))
        let sealed = directory.appendingPathComponent(ManagedResource.hash("user-1:device-1") + ".sealed")
        try Data(repeating: 0xAB, count: 96).write(to: sealed)

        XCTAssertNil(try store.load(userId: "user-1", deviceId: "device-1"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sealed.path),
                       "A cache this signature cannot open is left behind on every launch unless it is removed")
    }

    /// A schema change (day indexes became day codes) makes every existing cache undecodable. If
    /// that surfaced as a storage failure, the first launch after the update would drop a supervised
    /// device into recovery.
    func testACacheFromAnOlderSchemaIsDiscardedRatherThanFailingStorage() throws {
        let directory = try temporaryDirectory()
        let store = ManagedPolicyStore(directory: directory,
            defaults: try XCTUnwrap(UserDefaults(suiteName: "managed-store-" + UUID().uuidString)))
        let sealed = directory.appendingPathComponent(ManagedResource.hash("user-1:device-1") + ".sealed")
        try Data("not the shape this build decodes".utf8).write(to: sealed)

        XCTAssertNil(try store.load(userId: "user-1", deviceId: "device-1"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sealed.path))
    }

    func testAnUnrelatedIdentityNeverReadsAnotherIdentitysCache() throws {
        let directory = try temporaryDirectory()
        let store = ManagedPolicyStore(directory: directory,
            defaults: try XCTUnwrap(UserDefaults(suiteName: "managed-store-" + UUID().uuidString)))
        try Data(repeating: 0xCD, count: 96)
            .write(to: directory.appendingPathComponent(ManagedResource.hash("user-1:device-1") + ".sealed"))

        XCTAssertNil(try store.load(userId: "user-2", deviceId: "device-1"))
    }
}
