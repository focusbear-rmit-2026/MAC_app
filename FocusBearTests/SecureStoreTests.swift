import CryptoKit
import XCTest
@testable import Focus_Bear

/// SecureStore's contract: values sealed per account, and what happens when the key is missing.
/// Every store here uses `SecureStoreFixture` (temporary folder, isolated defaults, in-memory keys).
final class SecureStoreTests: XCTestCase {
    private var fixture: SecureStoreFixture!

    override func setUp() {
        super.setUp()
        fixture = SecureStoreFixture()
    }

    override func tearDown() {
        fixture.destroy()
        fixture = nil
        super.tearDown()
    }

    private typealias F = SecureStoreFixture

    @discardableResult
    private func readyStore(account: String = F.accountA) -> SecureStore {
        let store = fixture.makeStore()
        store.activate(accountId: account)
        XCTAssertTrue(store.currentState.isReady)
        return store
    }

    /// Writes through a store that is then thrown away, as the previous launch would have.
    private func seed(account: String = F.accountA, _ writes: (SecureStore) -> Void) {
        let store = readyStore(account: account)
        writes(store)
        store.flush()
    }

    // MARK: - Round trip

    func testValuesRoundTripSealedAndNeverInPlaintext() {
        let store = readyStore()
        store.set("secret habit routine", forKey: F.serverKey)
        store.set(fixture.dayPlanJSON(["2026-10-05": [["id": "t1", "title": "write thesis chapter"]]]), forKey: F.localKey)
        store.flush()

        XCTAssertFalse(fixture.diskContains("secret habit routine"))
        XCTAssertFalse(fixture.diskContains("write thesis chapter"))
        XCTAssertNil(fixture.defaults.object(forKey: F.serverKey), "nothing reaches the preferences plist")
        XCTAssertEqual(fixture.sealedValueFiles(account: F.accountA).count, 2)

        let relaunched = fixture.makeStore()
        relaunched.activate(accountId: F.accountA)
        XCTAssertEqual(relaunched.string(forKey: F.serverKey), "secret habit routine")
        XCTAssertEqual(fixture.decodeDayPlan(relaunched.data(forKey: F.localKey))["2026-10-05"]?.first?["title"] as? String,
                       "write thesis chapter")
    }

    func testUnregisteredKeysStayInUserDefaults() {
        let store = readyStore()
        store.set(true, forKey: "kSomeOrdinarySetting")
        XCTAssertEqual(fixture.defaults.object(forKey: "kSomeOrdinarySetting") as? Bool, true)
        XCTAssertEqual(store.bool(forKey: "kSomeOrdinarySetting"), true)
    }

    func testRelaunchResumesTheLastAccountBeforeSignInFinishes() {
        seed { $0.set("cached", forKey: F.serverKey) }
        let relaunched = fixture.makeStore()
        relaunched.resumeLastAccount()
        XCTAssertTrue(relaunched.currentState.isReady)
        XCTAssertEqual(relaunched.string(forKey: F.serverKey), "cached")
    }

    func testDisabledBuildKeepsTodaysPlaintextBehaviour() {
        let store = fixture.makeStore(isEncryptionEnabled: false)
        store.activate(accountId: F.accountA)
        store.set("value", forKey: F.serverKey)
        XCTAssertEqual(store.currentState, .disabled(reason: "test"))
        XCTAssertEqual(fixture.defaults.string(forKey: F.serverKey), "value")
        XCTAssertEqual(fixture.keys.loadCount, 0, "an ad-hoc build never touches the keychain")
    }

    // MARK: - Key unavailable: server-backed caches

    func testServerBackedCacheIsEmptyWhileTheKeyIsUnavailableAndRefetchedDataIsSealedLater() {
        seed { $0.set("old routine", forKey: F.serverKey) }
        let sealedBefore = try? Data(contentsOf: fixture.sealedValueFiles(account: F.accountA)[0])

        fixture.keys.isAvailable = false
        let store = fixture.makeStore()
        store.activate(accountId: F.accountA)
        guard case .unavailable = store.currentState else { return XCTFail("expected unavailable, got \(store.currentState)") }
        XCTAssertNil(store.string(forKey: F.serverKey), "an unreadable cache reads as empty, so the app re-fetches")

        store.set("fresh routine from the server", forKey: F.serverKey)
        store.flush()
        XCTAssertEqual(store.string(forKey: F.serverKey), "fresh routine from the server")
        XCTAssertNil(fixture.defaults.object(forKey: F.serverKey), "never a plaintext fallback")
        XCTAssertFalse(fixture.diskContains("fresh routine from the server"))
        XCTAssertEqual(try? Data(contentsOf: fixture.sealedValueFiles(account: F.accountA)[0]), sealedBefore)

        fixture.keys.isAvailable = true
        fixture.runScheduledRetries()
        store.flush()
        XCTAssertTrue(store.currentState.isReady)
        XCTAssertEqual(store.string(forKey: F.serverKey), "fresh routine from the server")
        let relaunched = fixture.makeStore()
        relaunched.activate(accountId: F.accountA)
        XCTAssertEqual(relaunched.string(forKey: F.serverKey), "fresh routine from the server")
    }

    func testUnavailableKeyIsRetriedWithBackoff() {
        fixture.keys.isAvailable = false
        let store = fixture.makeStore()
        store.activate(accountId: F.accountA)
        XCTAssertEqual(fixture.scheduledRetries.count, 1)
        fixture.runScheduledRetries()
        XCTAssertEqual(fixture.scheduledRetries.count, 1, "still locked: one more retry scheduled")
        XCTAssertEqual(fixture.keys.loadCount, 2)
    }

    // MARK: - Key unavailable: local-only data

    func testLocalOnlyEditMadeWhileTheKeyIsUnavailableIsMergedNotOverwritten() {
        seed { $0.set(fixture.dayPlanJSON(["2026-10-05": [["id": "unsent-1", "title": "draft from yesterday"]]]), forKey: F.localKey) }
        let sealedBefore = try? Data(contentsOf: fixture.sealedValueFiles(account: F.accountA)[0])

        fixture.keys.isAvailable = false
        let store = fixture.makeStore()
        store.activate(accountId: F.accountA)
        XCTAssertNil(store.data(forKey: F.localKey))
        // The app saves what it has, built on the empty read.
        store.set(fixture.dayPlanJSON(["2026-10-05": [["id": "new-2", "title": "added while locked"]]]), forKey: F.localKey)
        store.flush()
        XCTAssertEqual(try? Data(contentsOf: fixture.sealedValueFiles(account: F.accountA)[0]), sealedBefore,
                       "the sealed value is never overwritten while it can't be read")
        XCTAssertNil(fixture.defaults.object(forKey: F.localKey))
        XCTAssertFalse(fixture.diskContains("added while locked"))

        fixture.keys.isAvailable = true
        store.retryKeyIfNeeded()
        store.flush()
        let titles = Set((fixture.decodeDayPlan(store.data(forKey: F.localKey))["2026-10-05"] ?? []).compactMap { $0["title"] as? String })
        XCTAssertEqual(titles, ["draft from yesterday", "added while locked"])

        let relaunched = fixture.makeStore()
        relaunched.activate(accountId: F.accountA)
        XCTAssertEqual((fixture.decodeDayPlan(relaunched.data(forKey: F.localKey))["2026-10-05"] ?? []).count, 2)
    }

    func testLocalOnlyRemovalWithoutSeeingTheSealedValueIsNotApplied() {
        seed { $0.set(fixture.dayPlanJSON(["2026-10-05": [["id": "unsent-1", "title": "keep me"]]]), forKey: F.localKey) }
        fixture.keys.isAvailable = false
        let store = fixture.makeStore()
        store.activate(accountId: F.accountA)
        store.removeValue(forKey: F.localKey)
        XCTAssertEqual(fixture.sealedValueFiles(account: F.accountA).count, 1, "nothing sealed is deleted while locked")

        fixture.keys.isAvailable = true
        store.retryKeyIfNeeded()
        store.flush()
        XCTAssertEqual(fixture.decodeDayPlan(store.data(forKey: F.localKey))["2026-10-05"]?.first?["title"] as? String, "keep me")
    }

    func testServerBackedRemovalWhileLockedDeletesTheCopy() {
        seed { $0.set("cached", forKey: F.serverKey) }
        fixture.keys.isAvailable = false
        let store = fixture.makeStore()
        store.activate(accountId: F.accountA)
        store.removeValue(forKey: F.serverKey)
        XCTAssertTrue(fixture.sealedValueFiles(account: F.accountA).isEmpty)
    }

    func testWritesBeforeSignInAreHeldThenSealedForThatAccount() {
        let store = fixture.makeStore()
        XCTAssertEqual(store.currentState, .awaitingAccount)
        store.set("before sign-in", forKey: F.serverKey)
        XCTAssertNil(fixture.defaults.object(forKey: F.serverKey))
        XCTAssertEqual(store.string(forKey: F.serverKey), "before sign-in")

        store.activate(accountId: F.accountA)
        store.flush()
        XCTAssertEqual(fixture.sealedValueFiles(account: F.accountA).count, 1)
    }

    // MARK: - Migration

    func testMigrationSealsVerifiesThenDeletesPlaintextAndTheBackup() {
        fixture.defaults.set("legacy routine", forKey: F.serverKey)
        fixture.defaults.set(fixture.dayPlanJSON(["2026-10-01": [["id": "a", "title": "legacy task"]]]), forKey: F.localKey)
        fixture.defaults.set("note for a", forKey: F.suffixedLocalBase + F.accountA)

        let store = readyStore()

        XCTAssertEqual(store.lastMigrationReport, SecureStore.MigrationReport(migrated: 3, failed: 0))
        XCTAssertNil(fixture.defaults.object(forKey: F.serverKey))
        XCTAssertNil(fixture.defaults.object(forKey: F.localKey))
        XCTAssertNil(fixture.defaults.object(forKey: F.suffixedLocalBase + F.accountA))
        XCTAssertEqual(store.string(forKey: F.serverKey), "legacy routine")
        XCTAssertEqual(store.string(forKey: F.suffixedLocalBase + F.accountA), "note for a")
        XCTAssertFalse(fixture.backupExists(account: F.accountA), "removed once every value verified")
        XCTAssertFalse(fixture.diskContains("legacy routine"))
        XCTAssertFalse(fixture.diskContains("legacy task"))
    }

    func testMigrationIsIdempotent() {
        fixture.defaults.set("legacy routine", forKey: F.serverKey)
        readyStore()
        let relaunched = readyStore()
        XCTAssertEqual(relaunched.lastMigrationReport, SecureStore.MigrationReport())
        XCTAssertEqual(relaunched.string(forKey: F.serverKey), "legacy routine")
    }

    func testFailedVerificationKeepsPlaintextAndTheBackupForARetry() {
        fixture.defaults.set("legacy routine", forKey: F.serverKey)
        let store = fixture.makeStore()
        store.afterMigrationWrite = { file in try? Data("damaged".utf8).write(to: file) }
        store.activate(accountId: F.accountA)

        XCTAssertEqual(store.lastMigrationReport.failed, 1)
        XCTAssertEqual(fixture.defaults.string(forKey: F.serverKey), "legacy routine", "never drop the only copy")
        XCTAssertEqual(store.string(forKey: F.serverKey), "legacy routine")
        XCTAssertTrue(fixture.backupExists(account: F.accountA))
        XCTAssertNotNil(store.readBackup()?[F.serverKey])

        let relaunched = readyStore()
        XCTAssertEqual(relaunched.lastMigrationReport, SecureStore.MigrationReport(migrated: 1, failed: 0))
        XCTAssertNil(fixture.defaults.object(forKey: F.serverKey))
        XCTAssertFalse(fixture.backupExists(account: F.accountA))
    }

    func testLockedKeychainLeavesPlaintextInPlaceAndMigratesOnRetry() {
        fixture.defaults.set("legacy routine", forKey: F.serverKey)
        fixture.keys.isAvailable = false
        let store = fixture.makeStore()
        store.activate(accountId: F.accountA)

        XCTAssertEqual(store.string(forKey: F.serverKey), "legacy routine", "plaintext stays readable, untouched")
        XCTAssertEqual(fixture.defaults.string(forKey: F.serverKey), "legacy routine")
        XCTAssertTrue(fixture.sealedValueFiles(account: F.accountA).isEmpty)
        XCTAssertFalse(fixture.backupExists(account: F.accountA))

        fixture.keys.isAvailable = true
        fixture.runScheduledRetries()
        XCTAssertTrue(store.currentState.isReady)
        XCTAssertNil(fixture.defaults.object(forKey: F.serverKey))
        XCTAssertEqual(store.string(forKey: F.serverKey), "legacy routine")
    }

    func testPlaintextAnOlderBuildWroteMergesIntoSealedLocalData() {
        seed { $0.set(fixture.dayPlanJSON(["2026-10-05": [["id": "sealed", "title": "sealed task"]]]), forKey: F.localKey) }
        // A downgrade to a build without encryption wrote plaintext again.
        fixture.defaults.set(fixture.dayPlanJSON(["2026-10-05": [["id": "older-build", "title": "plaintext task"]]]),
                             forKey: F.localKey)
        let store = readyStore()
        let titles = Set((fixture.decodeDayPlan(store.data(forKey: F.localKey))["2026-10-05"] ?? []).compactMap { $0["title"] as? String })
        XCTAssertEqual(titles, ["sealed task", "plaintext task"])
        XCTAssertNil(fixture.defaults.object(forKey: F.localKey))
    }

    func testAnotherAccountsSuffixedPlaintextWaitsForThatAccount() {
        fixture.defaults.set("b's note", forKey: F.suffixedLocalBase + F.accountB)
        readyStore(account: F.accountA)
        XCTAssertEqual(fixture.defaults.string(forKey: F.suffixedLocalBase + F.accountB), "b's note")
    }

    // MARK: - Wrong key

    func testValuesSealedWithAnotherKeyAreDroppedOrQuarantinedNeverMisread() {
        let first = readyStore()
        first.set("cached", forKey: F.serverKey)
        first.set(fixture.dayPlanJSON(["d": [["id": "x", "title": "only copy"]]]), forKey: F.localKey)
        first.flush()
        fixture.keys.replaceKey(accountScope: SecureStore.accountScope(for: F.accountA))

        let store = readyStore()

        XCTAssertNil(store.string(forKey: F.serverKey), "server-backed: treated as empty and fetched again")
        XCTAssertNil(store.data(forKey: F.localKey))
        XCTAssertEqual(fixture.quarantinedFiles(account: F.accountA).count, 1, "local-only: kept aside, never deleted")
        XCTAssertTrue(fixture.sealedValueFiles(account: F.accountA).isEmpty)
    }

    func testEnvelopeRejectsAWrongKeyIdBeforeDecrypting() throws {
        let key = SymmetricKey(size: .bits256)
        let sealed = try SecureEnvelope.seal(Data("x".utf8), keyId: "aaaa", key: key, bundleId: "b", slot: "s")
        XCTAssertThrowsError(try SecureEnvelope.open(sealed, keyId: "bbbb", key: key, bundleId: "b", slot: "s")) { error in
            XCTAssertEqual(error as? SecureEnvelopeError, .wrongKey(found: "aaaa", expected: "bbbb"))
        }
        XCTAssertThrowsError(try SecureEnvelope.open(sealed, keyId: "aaaa", key: key, bundleId: "b", slot: "other"))
        XCTAssertEqual(try SecureEnvelope.open(sealed, keyId: "aaaa", key: key, bundleId: "b", slot: "s"), Data("x".utf8))
    }

    func testKeyFingerprintIdentifiesTheKey() {
        let key = SymmetricKey(size: .bits256)
        XCTAssertEqual(DataKeyFingerprint.id(of: key), DataKeyFingerprint.id(of: key))
        XCTAssertNotEqual(DataKeyFingerprint.id(of: key), DataKeyFingerprint.id(of: SymmetricKey(size: .bits256)))
    }

    // MARK: - Accounts

    func testAnotherAccountNeverReadsTheValues() throws {
        let storeA = readyStore(account: F.accountA)
        storeA.set("a's routine", forKey: F.serverKey)
        storeA.flush()

        storeA.activate(accountId: F.accountB)
        XCTAssertNil(storeA.string(forKey: F.serverKey))

        // Even A's file copied into B's folder can't be opened with B's key.
        let fileA = try XCTUnwrap(fixture.sealedValueFiles(account: F.accountA).first)
        let folderB = fixture.secureRoot.appendingPathComponent(SecureStore.accountScope(for: F.accountB))
            .appendingPathComponent(SecureStore.valuesFolderName)
        try FileManager.default.createDirectory(at: folderB, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fileA, to: folderB.appendingPathComponent(fileA.lastPathComponent))
        let storeB = readyStore(account: F.accountB)
        XCTAssertNil(storeB.string(forKey: F.serverKey))

        storeB.activate(accountId: F.accountA)
        XCTAssertEqual(storeB.string(forKey: F.serverKey), "a's routine")
    }

    // MARK: - Sign-out and reset

    func testSignOutWipesServerBackedCachesAndKeepsUnsentLocalData() {
        let store = readyStore()
        store.set("cached routine", forKey: F.serverKey)
        store.set(fixture.dayPlanJSON(["d": [["id": "x", "title": "unsent"]]]), forKey: F.localKey)

        store.signOut()

        XCTAssertEqual(store.currentState, .awaitingAccount)
        XCTAssertNil(fixture.defaults.object(forKey: SecureStore.lastAccountDefaultsKey))
        XCTAssertEqual(fixture.sealedValueFiles(account: F.accountA).count, 1, "only the local-only value is left")
        XCTAssertTrue(fixture.keys.hasKey(accountScope: SecureStore.accountScope(for: F.accountA)))

        let signedBackIn = readyStore()
        XCTAssertNil(signedBackIn.string(forKey: F.serverKey))
        XCTAssertNotNil(signedBackIn.data(forKey: F.localKey))
    }

    func testSignOutWithNothingLocalDeletesTheKeyAndTheFolder() {
        let store = readyStore()
        store.set("cached routine", forKey: F.serverKey)
        store.signOut()
        XCTAssertFalse(fixture.keys.hasKey(accountScope: SecureStore.accountScope(for: F.accountA)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.secureRoot
            .appendingPathComponent(SecureStore.accountScope(for: F.accountA)).path))
    }

    func testEraseAllDataRemovesEverythingAndTheKey() {
        let store = readyStore()
        store.set(fixture.dayPlanJSON(["d": [["id": "x", "title": "unsent"]]]), forKey: F.localKey)
        store.eraseAllData()
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.secureRoot.path))
        XCTAssertFalse(fixture.keys.hasKey(accountScope: SecureStore.accountScope(for: F.accountA)))
        XCTAssertEqual(store.currentState, .awaitingAccount)
    }

    // MARK: - The app's store

    func testTheAppStoreUnderTheLogicTestHostNeverTouchesRealData() throws {
        try XCTSkipUnless(LogicTestHost.isEnabled, "only the isolated logic test host may open SecureStore.shared")
        let shared = SecureStore.shared
        XCTAssertTrue(shared.currentState.isReady)
        XCTAssertTrue(shared.rootDirectory.path.hasPrefix(FileManager.default.temporaryDirectory.path))
        XCTAssertNotEqual(shared.legacyDomainName, Bundle.main.bundleIdentifier)
        XCTAssertTrue(shared.legacyDomainName.hasPrefix(SecureStore.logicTestHostSuitePrefix))
    }

    func testRegistryCoversThePersonalStoresAndClassifiesThem() {
        let registry = SensitiveKeyRegistry.app
        XCTAssertEqual(registry.entry(for: kUserdefaultsSelectedJson)?.durability, .serverBacked)
        XCTAssertEqual(registry.entry(for: kUserdefaultsArrFocusTypesBase + "user-1")?.durability, .serverBacked)
        XCTAssertEqual(registry.entry(for: kUserdefaultsDayPlanTasksByDay)?.durability, .localOnly)
        XCTAssertEqual(registry.entry(for: kUserdefaultsLastHabitSavedNotesBase + "user-1")?.durability, .localOnly)
        XCTAssertEqual(registry.fileEntry(for: kOfflineActivitiesCsvFileName)?.durability, .localOnly)
        XCTAssertEqual(registry.fileEntry(for: kBlockingSchedulesCacheFileName)?.durability, .serverBacked)
        XCTAssertNil(registry.entry(for: kUserDefaultsLastUserEmailBeforeLogout), "needed before any account is open")
        XCTAssertNil(registry.entry(for: kUserdefaultsBlockedUrlsFromOnboarding), "written before sign-in")
        XCTAssertEqual(Set(registry.keys.map(\.baseName)).count, registry.keys.count, "no duplicate entries")
    }

    /// Late No More reads the calendar dismissal snapshot from its own process, so it has to stay
    /// plaintext (it holds only calendar/event identifiers and days, by design). Sealing it — or the
    /// dismissed-key set it is derived from — would silently bring back every hidden meeting's alert.
    /// Literals, because `SharedCalendarDismissals.FILE_NAME` and `CalendarManager.dismissedKey` live
    /// in the Day Plan cluster; their values are a shipped contract and never change.
    func testLateNoMoreDismissalSnapshotIsNeverSealed() {
        let lateNoMoreSnapshotFileName = "dismissals-v1.json"
        let dayPlanDismissedEventsKey = "scheduleDismissedEventIDs"
        XCTAssertNil(SensitiveKeyRegistry.app.fileEntry(for: lateNoMoreSnapshotFileName))
        XCTAssertNil(SensitiveKeyRegistry.app.entry(for: dayPlanDismissedEventsKey))
    }

    // MARK: - Merge

    func testMergeKeepsBothSidesOfRecordsById() {
        let base: [String: Any] = ["d1": [["id": "a", "v": 1], ["id": "b", "v": 1]], "d2": [["id": "c"]]]
        let incoming: [String: Any] = ["d1": [["id": "b", "v": 2], ["id": "n", "v": 1]]]
        let merged = SecureMerge.unionObjects(base, incoming) as? [String: [[String: Any]]]
        XCTAssertEqual(Set(merged?["d1"]?.compactMap { $0["id"] as? String } ?? []), ["a", "b", "n"])
        XCTAssertEqual(merged?["d1"]?.first { $0["id"] as? String == "b" }?["v"] as? Int, 2, "incoming wins per record")
        XCTAssertEqual(merged?["d2"]?.count, 1)
    }

    func testMergeOfScalarsAndPlainListsPrefersIncomingAndKeepsBaseExtras() {
        XCTAssertEqual(SecureMerge.unionObjects("old", "new") as? String, "new")
        XCTAssertEqual(SecureMerge.unionObjects(["a", "b"], ["b", "c"]) as? [String], ["b", "c", "a"])
    }
}

/// The keychain-backed provider, against a scripted backend (never the real keychain).
final class DataKeyProviderTests: XCTestCase {
    private final class ScriptedKeychain: KeychainItemBackend {
        var readStatuses: [OSStatus] = []
        var addStatus: OSStatus = errSecSuccess
        var stored: Data?
        private(set) var addCount = 0
        private(set) var accounts: [String] = []

        func read(service: String, account: String) -> (status: OSStatus, data: Data?) {
            accounts.append(account)
            if !readStatuses.isEmpty { return (readStatuses.removeFirst(), nil) }
            return stored.map { (errSecSuccess, $0) } ?? (errSecItemNotFound, nil)
        }

        func add(service: String, account: String, data: Data) -> OSStatus {
            addCount += 1
            if addStatus == errSecSuccess { stored = data }
            return addStatus
        }

        func delete(service: String, account: String) -> OSStatus {
            stored = nil
            return errSecSuccess
        }
    }

    private func provider(_ backend: ScriptedKeychain) -> KeychainDataKeyProvider {
        KeychainDataKeyProvider(bundleId: "io.focusbear.tests", signatureScope: "sig", backend: backend)
    }

    func testCreatesAKeyOnlyWhenTheItemDoesNotExistAndReadsItBack() {
        let backend = ScriptedKeychain()
        guard case .key(let created) = provider(backend).loadKey(accountScope: "acct") else { return XCTFail() }
        XCTAssertEqual(backend.addCount, 1)
        guard case .key(let loaded) = provider(backend).loadKey(accountScope: "acct") else { return XCTFail() }
        XCTAssertEqual(DataKeyFingerprint.id(of: created), DataKeyFingerprint.id(of: loaded))
        XCTAssertEqual(backend.addCount, 1)
        XCTAssertEqual(backend.accounts.first, "dek.v1.acct.sig", "one key per account and signature")
    }

    func testLockedOrForeignItemIsUnavailableAndNeverReplaced() {
        for status in [errSecInteractionNotAllowed, errSecAuthFailed, errSecIO] {
            let backend = ScriptedKeychain()
            backend.readStatuses = [status]
            guard case .unavailable = provider(backend).loadKey(accountScope: "acct") else { return XCTFail("\(status)") }
            XCTAssertEqual(backend.addCount, 0, "a key that can't be read is never replaced (\(status))")
        }
    }

    func testDuplicateItemFromAnotherLaunchIsReadRatherThanAddedTwice() {
        let backend = ScriptedKeychain()
        backend.addStatus = errSecDuplicateItem
        backend.stored = Data(repeating: 7, count: KeychainDataKeyProvider.keyLength)
        backend.readStatuses = [errSecItemNotFound]
        guard case .key = provider(backend).loadKey(accountScope: "acct") else { return XCTFail() }
    }

    func testAKeyThatDoesNotReadBackIsUnavailable() {
        let backend = ScriptedKeychain()
        backend.addStatus = errSecDuplicateItem
        backend.readStatuses = [errSecItemNotFound, errSecAuthFailed]
        guard case .unavailable = provider(backend).loadKey(accountScope: "acct") else { return XCTFail() }
    }
}
