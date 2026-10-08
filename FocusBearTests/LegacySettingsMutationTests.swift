import XCTest
@testable import Focus_Bear

final class LegacySettingsMutationTests: XCTestCase {
    private let session = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private var context: LegacySettingsMutationContext {
        LegacySettingsMutationContext(userId: "account-a", deviceId: "device-a", sessionToken: session)
    }
    private let modes: [[String: Any]] = [["id": "a", "name": "Work"], ["id": "b", "name": "Study"]]

    func testLockArrivingDuringCredentialLookupRejectsOriginalWrite() {
        let pending = context
        XCTAssertTrue(pending.permits(userId: "account-a", deviceId: "device-a", sessionToken: session, isLocked: false))
        XCTAssertFalse(pending.permits(userId: "account-a", deviceId: "device-a", sessionToken: session, isLocked: true))
    }

    func testOldResponseAndRetryCannotMoveToAnotherAccountOrDevice() {
        let pending = context
        XCTAssertFalse(pending.permits(userId: "account-b", deviceId: "device-a", sessionToken: session, isLocked: false))
        XCTAssertFalse(pending.permits(userId: "account-a", deviceId: "device-b", sessionToken: session, isLocked: false))
        XCTAssertFalse(pending.permits(userId: nil, deviceId: "device-a", sessionToken: session, isLocked: false))
    }

    func testNewManagedSessionRejectsOldCallbackEvenWhenAccountAndDeviceMatch() {
        XCTAssertFalse(context.permits(userId: "account-a", deviceId: "device-a", sessionToken: UUID(), isLocked: false))
    }

    func testCredentialRefreshMustStillBelongToCapturedAccount() {
        XCTAssertTrue(context.permitsCredential(userId: "account-a"))
        XCTAssertFalse(context.permitsCredential(userId: "account-b"))
        XCTAssertFalse(context.permitsCredential(userId: nil))
    }

    func testUnidentifiedMutationCannotBeAuthorizedByMatchingEmptyValues() {
        let unidentified = LegacySettingsMutationContext(userId: "", deviceId: "", sessionToken: session)
        XCTAssertFalse(unidentified.permits(userId: "", deviceId: "", sessionToken: session, isLocked: false))
        XCTAssertFalse(unidentified.permitsCredential(userId: ""))
    }

    private func deletionIndex(_ id: String = "a", modes: [[String: Any]]? = nil,
                               scheduled: Set<String> = [], running: Bool = false, configured: String? = nil) -> Int? {
        LegacyFocusModeDeletion.index(for: id, modes: modes ?? self.modes, scheduledModeIDs: scheduled,
                                      hardcoreIsRunning: running, configuredHardcoreModeName: configured)
    }

    func testConfirmationResolvesTheReviewedIDAfterServerReordersRows() {
        XCTAssertEqual(deletionIndex(), 0)
        let refreshed = [modes[1], modes[0]]
        let index = deletionIndex(modes: refreshed)
        XCTAssertEqual(index, 1)
        XCTAssertEqual(index.flatMap { refreshed[$0]["id"] as? String }, "a")
    }

    func testSameRowCountWithDifferentTargetNeverDeletesTheReplacement() {
        XCTAssertNil(deletionIndex(modes: [["id": "replacement"], modes[1]]))
        XCTAssertNil(deletionIndex(""))
        XCTAssertNil(deletionIndex(modes: [["id": "a"], ["id": "a"]]))
    }

    func testModeBecomingProtectedWhileConfirmationIsOpenCannotBeDeleted() {
        for flag in ["isDefault", "isMeetings", "isLockedFocus", "isOn", "isPaused"] {
            var target = modes[0]
            target[flag] = true
            XCTAssertNil(deletionIndex(modes: [target, modes[1]]), flag)
        }
    }

    func testNewScheduleOrHardcoreUsePreventsPendingDeletion() {
        XCTAssertNil(deletionIndex(scheduled: ["a"]))
        XCTAssertNil(deletionIndex(running: true))
        XCTAssertNil(deletionIndex(configured: "Work"))
        XCTAssertEqual(deletionIndex(scheduled: ["b"], configured: "Study"), 0)
    }
}
