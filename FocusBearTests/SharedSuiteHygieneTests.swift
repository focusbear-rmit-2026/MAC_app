import XCTest
@testable import Focus_Bear

/// Every test uses its own throwaway suite: app-hosted tests would otherwise read and write the real
/// FBHelper shared suite on the machine running them.
final class SharedSuiteHygieneTests: XCTestCase {
    private var isolated: IsolatedDefaults!
    private var defaults: UserDefaults { isolated.defaults }

    override func setUp() {
        super.setUp()
        isolated = IsolatedDefaults()
    }

    override func tearDown() {
        isolated.destroy()
        isolated = nil
        super.tearDown()
    }

    func testRemovesEveryLegacySecretAndKeepsOtherKeys() {
        LegacySharedSuiteSecrets.allKeys.forEach { defaults.set("legacy value", forKey: $0) }
        defaults.set("user-1", forKey: kUserdefaultsSharedUserId)

        SharedSuiteHygiene.removeLegacySecrets(from: defaults)

        for key in LegacySharedSuiteSecrets.allKeys {
            XCTAssertNil(defaults.object(forKey: key), key)
        }
        XCTAssertEqual(defaults.string(forKey: kUserdefaultsSharedUserId), "user-1")
    }

    func testLegacyKeysAreTheNamesOlderBuildsWrote() {
        XCTAssertEqual(Set(LegacySharedSuiteSecrets.allKeys), [
            "kUserdefaultsSharedAccessToken",
            "kUserdefaultsSharedUserEmail",
            "kUserdefaultsSharedUserName",
            "kUserdefaultsSharedLeaderboardUsername",
        ])
    }

    func testInternalTestUserIsStoredAsAFlagNotAnEmail() {
        InternalTestUser.record(email: "someone+InternalTest@example.com", in: defaults)
        XCTAssertTrue(InternalTestUser.isRecorded(in: defaults))
        let stored = defaults.dictionaryRepresentation().values.compactMap { $0 as? String }
        XCTAssertFalse(stored.contains { $0.contains("@") })

        InternalTestUser.record(email: "someone@example.com", in: defaults)
        XCTAssertFalse(InternalTestUser.isRecorded(in: defaults))
    }

    func testQueuedEventsAreSentOnceForTheSignedInUserOnly() {
        let queue = HelperEventQueue(defaults: defaults)
        let queuedAt = Date(timeIntervalSince1970: 1_700_000_000)
        queue.enqueue(event: "show-nudge", metadata: ["shown-after-days": 3], userId: "user-1", at: queuedAt)
        queue.enqueue(event: "daily-nudge-onboarding-shown", metadata: [:], userId: "anonymous-uuid", at: queuedAt)

        var sent: [(String, [String: Any])] = []
        SharedSuiteHygiene.sendQueuedHelperEvents(from: defaults, signedInUserId: "user-1") { sent.append(($0, $1)) }

        XCTAssertEqual(sent.map(\.0), ["show-nudge"])
        XCTAssertEqual(sent.first?.1["shown-after-days"] as? Int, 3)
        XCTAssertNotNil(sent.first?.1[SharedSuiteHygiene.queuedAtMetadataKey] as? String)
        XCTAssertNil(defaults.object(forKey: kUserdefaultsSharedPendingHelperEvents))

        sent.removeAll()
        SharedSuiteHygiene.sendQueuedHelperEvents(from: defaults, signedInUserId: "user-1") { sent.append(($0, $1)) }
        XCTAssertTrue(sent.isEmpty)
    }

    func testQueueKeepsOnlyTheNewestEvents() {
        let queue = HelperEventQueue(defaults: defaults)
        let overflow = 5
        for index in 0..<(HelperEventQueue.maximumPendingEvents + overflow) {
            queue.enqueue(event: "event-\(index)", metadata: [:], userId: "user-1")
        }
        let drained = queue.drain()
        XCTAssertEqual(drained.count, HelperEventQueue.maximumPendingEvents)
        XCTAssertEqual(drained.first?.event, "event-\(overflow)")
    }

    func testNonPropertyListMetadataIsKeptAsText() {
        let queue = HelperEventQueue(defaults: defaults)
        queue.enqueue(event: "e", metadata: ["url": URL(string: "https://focusbear.io")!], userId: "user-1")
        XCTAssertEqual(queue.drain().first?.metadata["url"] as? String, "https://focusbear.io")
    }

    func testNothingIsSentWithoutASignedInUser() {
        HelperEventQueue(defaults: defaults).enqueue(event: "e", metadata: [:], userId: "user-1")
        var sentCount = 0
        SharedSuiteHygiene.sendQueuedHelperEvents(from: defaults, signedInUserId: "") { _, _ in sentCount += 1 }
        XCTAssertEqual(sentCount, 0)
        XCTAssertNotNil(defaults.object(forKey: kUserdefaultsSharedPendingHelperEvents))
    }

    func testWebCacheCleanerMatchesOnlyFocusBearSites() {
        XCTAssertTrue(WebCacheCleaner.isFocusBearRecord(displayName: "focusbear.io"))
        XCTAssertTrue(WebCacheCleaner.isFocusBearRecord(displayName: "dashboard.FocusBear.io"))
        XCTAssertFalse(WebCacheCleaner.isFocusBearRecord(displayName: "notfocusbear.io"))
        XCTAssertFalse(WebCacheCleaner.isFocusBearRecord(displayName: "youtube.com"))
    }
}
