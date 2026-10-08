import XCTest
@testable import Focus_Bear

/// Sealed CSV / JSON files: same per-account key and failure rules as SecureStore values.
final class SecureFileStoreTests: XCTestCase {
    private typealias F = SecureStoreFixture
    private static let header = "activity_id,duration\n"

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

    private func makeFiles(available: Bool = true) -> (SecureStore, SecureFileStore) {
        fixture.keys.isAvailable = available
        let store = fixture.makeStore()
        store.activate(accountId: F.accountA)
        return (store, SecureFileStore(store: store))
    }

    private var csv: URL { fixture.plaintextURL(F.localCsv) }

    func testAppendsAreSealedAndReadBackInOrder() throws {
        let (_, files) = makeFiles()
        try files.writeText(Self.header, to: csv)
        try files.appendText("habit-1,60\n", to: csv)
        try files.appendText("habit-2,30\n", to: csv)

        XCTAssertEqual(try files.readText(csv), Self.header + "habit-1,60\nhabit-2,30\n")
        XCTAssertFalse(FileManager.default.fileExists(atPath: csv.path), "no plaintext at the usual path")
        XCTAssertFalse(fixture.diskContains("habit-1"))
        XCTAssertTrue(files.exists(csv))
    }

    func testPlaintextFromAnOlderBuildIsSealedThenDeleted() throws {
        try Data((Self.header + "old-row,10\n").utf8).write(to: csv)
        let (_, files) = makeFiles()

        files.sealPlaintextIfPresent(csv)

        XCTAssertFalse(FileManager.default.fileExists(atPath: csv.path))
        XCTAssertEqual(try files.readText(csv), Self.header + "old-row,10\n")
        XCTAssertFalse(fixture.diskContains("old-row"))
    }

    func testAppendsWhileTheKeyIsUnavailableWaitInMemoryAndLandLater() throws {
        do {
            let (_, files) = makeFiles()
            try files.writeText(Self.header + "sealed-row,1\n", to: csv)
        }
        let (store, files) = makeFiles(available: false)
        try files.appendText("unsent-row,2\n", to: csv)

        XCTAssertFalse(FileManager.default.fileExists(atPath: csv.path), "never a plaintext fallback")
        XCTAssertFalse(fixture.diskContains("unsent-row"))
        XCTAssertEqual(try files.readText(csv), "unsent-row,2\n", "readers see the held rows, never the sealed copy")

        fixture.keys.isAvailable = true
        store.retryKeyIfNeeded()
        files.applyHeldWrites()

        XCTAssertEqual(try files.readText(csv), Self.header + "sealed-row,1\nunsent-row,2\n")
    }

    func testALocalOnlyRewriteWithoutSeeingTheSealedCopyKeepsItsRows() throws {
        do {
            let (_, files) = makeFiles()
            try files.writeText(Self.header + "unsent-1,1\n", to: csv)
        }
        let (store, files) = makeFiles(available: false)
        try files.writeText(Self.header + "unsent-2,2\n", to: csv)
        files.remove(csv)
        try files.writeText(Self.header + "unsent-3,3\n", to: csv)

        fixture.keys.isAvailable = true
        store.retryKeyIfNeeded()
        files.applyHeldWrites()

        let rows = try files.readText(csv)
        XCTAssertTrue(rows.contains("unsent-1,1"), "the row nobody saw is kept")
        XCTAssertTrue(rows.contains("unsent-3,3"))
        XCTAssertEqual(rows.components(separatedBy: Self.header).count, 2, "header appears once")
    }

    func testALocalOnlyRemovalWithoutSeeingTheSealedCopyIsNotApplied() throws {
        do {
            let (_, files) = makeFiles()
            try files.writeText(Self.header + "unsent-1,1\n", to: csv)
        }
        let (store, files) = makeFiles(available: false)
        files.remove(csv)
        XCTAssertFalse(files.exists(csv))

        fixture.keys.isAvailable = true
        store.retryKeyIfNeeded()
        files.applyHeldWrites()
        XCTAssertTrue(try files.readText(csv).contains("unsent-1,1"))
    }

    func testServerBackedFilesGoOnSignOutAndLocalOnesStay() throws {
        let (store, files) = makeFiles()
        let cache = fixture.plaintextURL(F.serverFile)
        try files.writeText("{\"cached\":true}", to: cache)
        try files.writeText(Self.header, to: csv)

        store.signOut()

        let reopened = fixture.makeStore()
        reopened.activate(accountId: F.accountA)
        let filesAgain = SecureFileStore(store: reopened)
        XCTAssertFalse(filesAgain.exists(cache))
        XCTAssertTrue(filesAgain.exists(csv))
    }

    func testDisabledBuildWritesPlaintextAsBefore() throws {
        let store = fixture.makeStore(isEncryptionEnabled: false)
        let files = SecureFileStore(store: store)
        try files.writeText(Self.header, to: csv)
        XCTAssertEqual(try String(contentsOf: csv, encoding: .utf8), Self.header)
    }

    func testUnregisteredFilesAreUntouched() throws {
        let (_, files) = makeFiles()
        let other = fixture.plaintextURL("not-registered.txt")
        try files.writeText("plain", to: other)
        XCTAssertEqual(try String(contentsOf: other, encoding: .utf8), "plain")
    }

    func testCsvMergeKeepsEveryRowOnce() {
        let merged = SecureFileStore.merge(existing: Data("h\na\nb\n".utf8), incoming: Data("h\nb\nc\n".utf8), kind: .csv)
        XCTAssertEqual(String(decoding: merged, as: UTF8.self), "h\na\nb\nc\n")
    }
}

/// Project-note drafts (unsynced edits) sealed with the account key.
final class ProjectNoteDraftSealingTests: XCTestCase {
    private typealias F = SecureStoreFixture
    private let identity = ProjectNoteIdentity(accountID: F.accountA, projectID: "project", noteID: "note")
    private let secretText = "unsynced meeting notes about the merger"

    private var fixture: SecureStoreFixture!
    private var store: SecureStore!
    private var directory: URL { fixture.root.appendingPathComponent("drafts", isDirectory: true) }

    override func setUp() {
        super.setUp()
        fixture = SecureStoreFixture()
        store = fixture.makeStore()
        store.activate(accountId: F.accountA)
    }

    override func tearDown() {
        fixture.destroy()
        fixture = nil
        store = nil
        super.tearDown()
    }

    private func drafts() -> ProjectNoteDraftStore {
        ProjectNoteDraftStore(directory: directory, sealing: SecureStoreDraftSealing(store: store))
    }

    private func snapshot(revision: Int = 1) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "revision": revision, "yjs_state": "AAA=",
            "content": ["type": "doc", "content": [["type": "paragraph", "content": [["type": "text", "text": secretText]]]]],
        ], options: [.sortedKeys])
    }

    private func draftBytes() throws -> Data {
        let file = try XCTUnwrap(try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first)
        return try Data(contentsOf: file)
    }

    func testDraftsAreSealedAndRoundTrip() throws {
        let data = try snapshot()
        try drafts().save(data, identity: identity)
        XCTAssertTrue(SecureEnvelope.isEnvelope(try draftBytes()))
        XCTAssertNil(try draftBytes().range(of: Data(secretText.utf8)))
        XCTAssertEqual(drafts().load(identity: identity), data)
    }

    func testLockedKeyNeverOverwritesOrDeletesADraft() throws {
        let original = try snapshot(revision: 1)
        try drafts().save(original, identity: identity)
        let sealedBefore = try draftBytes()

        fixture.keys.isAvailable = false
        let locked = fixture.makeStore()
        locked.activate(accountId: F.accountA)
        let lockedDrafts = ProjectNoteDraftStore(directory: directory, sealing: SecureStoreDraftSealing(store: locked))

        XCTAssertNil(lockedDrafts.load(identity: identity), "unreadable reads as absent")
        XCTAssertThrowsError(try lockedDrafts.save(try snapshot(revision: 2), identity: identity))
        XCTAssertFalse(try lockedDrafts.save(try snapshot(revision: 2), identity: identity, replacing: nil),
                       "a sealed draft exists, so it is not 'absent'")
        XCTAssertFalse(try lockedDrafts.remove(identity: identity, matching: original))
        XCTAssertEqual(try draftBytes(), sealedBefore)

        fixture.keys.isAvailable = true
        locked.retryKeyIfNeeded()
        XCTAssertEqual(lockedDrafts.load(identity: identity), original)
    }

    func testPlainDraftsFromAnOlderBuildAreSealedInPlace() throws {
        let plainStore = ProjectNoteDraftStore(directory: directory, sealing: PlainDraftSealing())
        let data = try snapshot()
        try plainStore.save(data, identity: identity)
        XCTAssertFalse(SecureEnvelope.isEnvelope(try draftBytes()))
        XCTAssertEqual(drafts().load(identity: identity), data, "still readable before it is sealed")

        XCTAssertEqual(drafts().sealLegacyDrafts(), 1)
        XCTAssertTrue(SecureEnvelope.isEnvelope(try draftBytes()))
        XCTAssertEqual(drafts().load(identity: identity), data)
        XCTAssertEqual(drafts().sealLegacyDrafts(), 0, "idempotent")
    }

    func testAnotherAccountCannotOpenTheDraft() throws {
        try drafts().save(try snapshot(), identity: identity)
        store.activate(accountId: F.accountB)
        XCTAssertNil(drafts().load(identity: identity))
    }

    private struct PlainDraftSealing: ProjectNoteDraftSealing {
        func seal(_ envelope: Data, slot: String) -> Data? { envelope }
        func open(_ stored: Data, slot: String) -> Data? { stored }
    }
}
