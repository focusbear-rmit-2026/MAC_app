@testable import Focus_Bear
import Foundation
import XCTest

final class ProjectNoteSyncSupportTests: XCTestCase {
    private var root: URL!
    private var directory: URL!
    private var store: ProjectNoteDraftStore!
    private let identity = ProjectNoteIdentity(accountID: "account-a", projectID: "project-a", noteID: "note-a")

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = FileManager.default.temporaryDirectory.appendingPathComponent("ProjectNoteSyncSupportTests-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        directory = root.appendingPathComponent("drafts", isDirectory: true)
        store = ProjectNoteDraftStore(directory: directory)
    }

    override func tearDownWithError() throws {
        if let root = root { try FileManager.default.removeItem(at: root) }
        store = nil; root = nil; directory = nil
        try super.tearDownWithError()
    }

    private func snapshot(revision: Any = 1, state: String = "AAA=", content: Any = ["type": "doc", "content": [["type": "paragraph"]]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["revision": revision, "yjs_state": state, "content": content], options: [.sortedKeys])
    }

    private func draftFiles() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    }

    func test_missingDraftReadDoesNotCreateStorageOrMutateSettings() {
        XCTAssertNil(store.load(identity: identity))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func test_savedDraftRoundTripsExactBytesAcrossStoreInstances() throws {
        let data = try snapshot(revision: 3)
        try store.save(data, identity: identity)
        let reopened = ProjectNoteDraftStore(directory: directory)
        XCTAssertEqual(reopened.load(identity: identity), data)
        XCTAssertEqual(try ProjectNoteDraftStore.revision(in: data), 3)
    }

    func test_everyIdentityComponentSeparatesDrafts() throws {
        let data = try snapshot()
        try store.save(data, identity: identity)
        for other in [
            ProjectNoteIdentity(accountID: "account-b", projectID: identity.projectID, noteID: identity.noteID),
            ProjectNoteIdentity(accountID: identity.accountID, projectID: "project-b", noteID: identity.noteID),
            ProjectNoteIdentity(accountID: identity.accountID, projectID: identity.projectID, noteID: "note-b")
        ] {
            XCTAssertNil(store.load(identity: other))
            try store.remove(identity: other)
            XCTAssertEqual(store.load(identity: identity), data)
        }
    }

    func test_identityHashUsesFramingAndNeverPlacesIdentifiersInFileNames() throws {
        let first = ProjectNoteIdentity(accountID: "a:b", projectID: "c", noteID: "../note")
        let second = ProjectNoteIdentity(accountID: "a", projectID: "b:c", noteID: "../note")
        try store.save(try snapshot(revision: 1), identity: first)
        try store.save(try snapshot(revision: 2), identity: second)
        XCTAssertEqual(try ProjectNoteDraftStore.revision(in: XCTUnwrap(store.load(identity: first))), 1)
        XCTAssertEqual(try ProjectNoteDraftStore.revision(in: XCTUnwrap(store.load(identity: second))), 2)
        let files = try draftFiles()
        XCTAssertEqual(files.count, 2)
        for url in files {
            XCTAssertNotNil(url.lastPathComponent.range(of: "^[a-f0-9]{64}\\.json$", options: .regularExpression))
        }
    }

    func test_copiedFileCannotLoadUnderAnotherAccount() throws {
        let data = try snapshot()
        try store.save(data, identity: identity)
        let first = try XCTUnwrap(draftFiles().first)
        let other = ProjectNoteIdentity(accountID: "account-b", projectID: identity.projectID, noteID: identity.noteID)
        try store.save(try snapshot(revision: 2), identity: other)
        let second = try XCTUnwrap(draftFiles().first { $0 != first })
        try Data(contentsOf: first).write(to: second)
        XCTAssertNil(store.load(identity: other))
        XCTAssertEqual(store.load(identity: identity), data)
    }

    func test_oldAcknowledgementCannotDeleteReopenedNoteWithSameRevision() throws {
        let closingSnapshot = try snapshot(revision: 1)
        let reopenedSnapshot = try snapshot(revision: 1, content: ["type": "doc", "content": [["type": "paragraph", "content": [["type": "text", "text": "New local edit"]]]]])
        try store.save(closingSnapshot, identity: identity)
        let reopened = ProjectNoteDraftStore(directory: directory)
        try reopened.save(reopenedSnapshot, identity: identity)
        XCTAssertFalse(try store.remove(identity: identity, matching: closingSnapshot))
        XCTAssertEqual(reopened.load(identity: identity), reopenedSnapshot)
        XCTAssertTrue(try reopened.remove(identity: identity, matching: reopenedSnapshot))
        XCTAssertNil(store.load(identity: identity))
    }

    func test_exactAcknowledgementRetainsLaterEditWithinOneSession() throws {
        let earlier = try snapshot(revision: 7)
        let data = try snapshot(revision: 8)
        try store.save(data, identity: identity)
        XCTAssertFalse(try store.remove(identity: identity, matching: earlier))
        XCTAssertEqual(store.load(identity: identity), data)
        XCTAssertTrue(try store.remove(identity: identity, matching: data))
        XCTAssertNil(store.load(identity: identity))
    }

    func test_closingEditorCannotOverwriteReopenedDraftDuringServerMerge() throws {
        let previous = try snapshot(revision: 1)
        let reopened = try snapshot(revision: 1, content: ["type": "doc", "content": [["type": "paragraph", "content": [["type": "text", "text": "Reopened local work"]]]]])
        let closingMerge = try snapshot(revision: 2)
        try store.save(previous, identity: identity)
        let newEditorStore = ProjectNoteDraftStore(directory: directory)
        try newEditorStore.save(reopened, identity: identity)
        XCTAssertFalse(try store.save(closingMerge, identity: identity, replacing: previous))
        XCTAssertEqual(store.load(identity: identity), reopened)
        XCTAssertFalse(try store.remove(identity: identity, matching: previous))
    }

    func test_compareAndSwapCreatesOnlyWhenAbsentAndReplacesOnlyItsOwnedDraft() throws {
        let first = try snapshot(revision: 1)
        let second = try snapshot(revision: 2)
        XCTAssertTrue(try store.save(first, identity: identity, replacing: nil))
        XCTAssertFalse(try store.save(second, identity: identity, replacing: nil))
        XCTAssertEqual(store.load(identity: identity), first)
        XCTAssertTrue(try store.save(second, identity: identity, replacing: first))
        XCTAssertEqual(store.load(identity: identity), second)
    }

    func test_compareAndSwapDoesNotTreatCorruptExistingFileAsAbsent() throws {
        let data = try snapshot()
        try store.save(data, identity: identity)
        let file = try XCTUnwrap(draftFiles().first)
        let corrupt = Data("{truncated".utf8)
        try corrupt.write(to: file)
        XCTAssertFalse(try store.save(data, identity: identity, replacing: nil))
        XCTAssertFalse(try store.save(data, identity: identity, replacing: data))
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
    }

    func test_twoStoreInstancesCannotBothWinTheSameDraftCompareAndSwap() throws {
        let previous = try snapshot()
        try store.save(previous, identity: identity)
        let first = try snapshot(revision: 2)
        let second = try snapshot(revision: 3)
        let otherStore = ProjectNoteDraftStore(directory: directory)
        let resultLock = NSLock()
        var outcomes: [Bool] = []
        var failures = 0
        let group = DispatchGroup()
        for (writer, update) in [(store!, first), (otherStore, second)] {
            group.enter()
            DispatchQueue.global().async {
                defer { group.leave() }
                do {
                    let won = try writer.save(update, identity: self.identity, replacing: previous)
                    resultLock.lock(); outcomes.append(won); resultLock.unlock()
                } catch {
                    resultLock.lock(); failures += 1; resultLock.unlock()
                }
            }
        }
        XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
        XCTAssertEqual(failures, 0)
        XCTAssertEqual(outcomes.filter { $0 }.count, 1)
        let saved = try XCTUnwrap(store.load(identity: identity))
        XCTAssertTrue(saved == first || saved == second)
    }

    func test_invalidSnapshotsCannotReplaceAnExistingRecoveryCopy() throws {
        let saved = try snapshot()
        try store.save(saved, identity: identity)
        let invalid = try [
            snapshot(state: ""), snapshot(state: "not base64?"), snapshot(state: "AA==\n"), snapshot(state: "AB=="),
            snapshot(revision: true), snapshot(revision: -1), snapshot(revision: 0.5),
            snapshot(revision: NSNumber(value: ProjectNoteDraftStore.maxRevision + 1)),
            snapshot(content: [:]), snapshot(content: ["type": "paragraph"]),
            snapshot(content: ["type": "doc", "content": "not nodes"]),
            snapshot(content: ["type": "doc", "content": [1, 2]]),
            snapshot(content: NSNull())
        ] + [Data("{}".utf8), Data("[]".utf8), Data("{broken".utf8)]
        for data in invalid {
            XCTAssertThrowsError(try store.save(data, identity: identity))
            XCTAssertEqual(store.load(identity: identity), saved)
        }
    }

    func test_emptyProseMirrorRootAndSafeRevisionBoundsAreAccepted() throws {
        XCTAssertEqual(try ProjectNoteDraftStore.revision(in: snapshot(revision: 0, content: ["type": "doc"])), 0)
        XCTAssertEqual(try ProjectNoteDraftStore.revision(in: snapshot(revision: ProjectNoteDraftStore.maxRevision)), ProjectNoteDraftStore.maxRevision)
    }

    func test_decodedStateLimitRejectsExtraByteEvenWithSameBase64Length() throws {
        let atLimit = Data(repeating: 0, count: ProjectNoteDraftStore.maxYjsStateBytes).base64EncodedString()
        let overLimit = Data(repeating: 0, count: ProjectNoteDraftStore.maxYjsStateBytes + 1).base64EncodedString()
        XCTAssertEqual(atLimit.count, ProjectNoteDraftStore.maxYjsStateBase64Length)
        XCTAssertEqual(overLimit.count, atLimit.count, "base64 character limit alone misses this boundary")
        XCTAssertEqual(try ProjectNoteDraftStore.revision(in: snapshot(state: atLimit)), 1)
        XCTAssertThrowsError(try ProjectNoteDraftStore.revision(in: snapshot(state: overLimit))) {
            XCTAssertEqual($0 as? ProjectNoteDraftError, .snapshotTooLarge)
        }
    }

    func test_oversizedRawSnapshotIsRejectedBeforeItCanReplaceDraft() throws {
        let saved = try snapshot()
        try store.save(saved, identity: identity)
        let oversized = Data(repeating: 32, count: ProjectNoteDraftStore.maxSnapshotBytes + 1)
        XCTAssertThrowsError(try store.save(oversized, identity: identity)) {
            XCTAssertEqual($0 as? ProjectNoteDraftError, .snapshotTooLarge)
        }
        XCTAssertEqual(store.load(identity: identity), saved)
    }

    func test_invalidIdentityNeverCreatesAFile() throws {
        for invalid in [
            ProjectNoteIdentity(accountID: "", projectID: "p", noteID: "n"),
            ProjectNoteIdentity(accountID: "a", projectID: " \n", noteID: "n"),
            ProjectNoteIdentity(accountID: "a", projectID: "p", noteID: "x\0y"),
            ProjectNoteIdentity(accountID: String(repeating: "a", count: 1025), projectID: "p", noteID: "n")
        ] {
            XCTAssertNil(store.load(identity: invalid))
            XCTAssertThrowsError(try store.save(snapshot(), identity: invalid))
            XCTAssertThrowsError(try store.remove(identity: invalid))
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func test_atomicReplacementLeavesOnlyPrivateFinalFile() throws {
        try store.save(try snapshot(), identity: identity)
        let replacement = try snapshot(revision: 4)
        try store.save(replacement, identity: identity)
        let files = try draftFiles()
        XCTAssertEqual(files.count, 1)
        let file = try XCTUnwrap(files.first)
        let fileMode = try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? NSNumber
        let directoryMode = try FileManager.default.attributesOfItem(atPath: directory.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(fileMode?.intValue, 0o600)
        XCTAssertEqual(directoryMode?.intValue, 0o700)
        XCTAssertEqual(store.load(identity: identity), replacement)
    }

    func test_corruptDraftIsNotReturnedOrSilentlyDeleted() throws {
        try store.save(try snapshot(), identity: identity)
        let file = try XCTUnwrap(draftFiles().first)
        try Data("{truncated".utf8).write(to: file)
        XCTAssertNil(store.load(identity: identity))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        try store.save(try snapshot(revision: 2), identity: identity)
        XCTAssertEqual(try ProjectNoteDraftStore.revision(in: XCTUnwrap(store.load(identity: identity))), 2)
    }

    func test_oversizedStoredEnvelopeIsNotReadAsADraft() throws {
        try store.save(try snapshot(), identity: identity)
        let file = try XCTUnwrap(draftFiles().first)
        let handle = try FileHandle(forWritingTo: file)
        try handle.truncate(atOffset: UInt64(ProjectNoteDraftStore.maxSnapshotBytes * 2))
        try handle.close()
        XCTAssertNil(store.load(identity: identity))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
    }

    func test_symlinkDraftIsNotFollowedAndReplacementDoesNotWriteThroughIt() throws {
        let initial = try snapshot()
        try store.save(initial, identity: identity)
        let file = try XCTUnwrap(draftFiles().first)
        let outside = root.appendingPathComponent("outside.json")
        let outsideData = try Data(contentsOf: file)
        try outsideData.write(to: outside)
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createSymbolicLink(at: file, withDestinationURL: outside)
        XCTAssertNil(store.load(identity: identity))
        let updated = try snapshot(revision: 2)
        try store.save(updated, identity: identity)
        XCTAssertEqual(store.load(identity: identity), updated)
        XCTAssertEqual(try Data(contentsOf: outside), outsideData)
    }

    func test_symlinkStorageDirectoryIsRejectedWithoutTouchingItsTarget() throws {
        let outside = root.appendingPathComponent("outside", isDirectory: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: directory, withDestinationURL: outside)
        XCTAssertNil(store.load(identity: identity))
        XCTAssertThrowsError(try store.save(snapshot(), identity: identity))
        XCTAssertThrowsError(try store.remove(identity: identity))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: outside.path), [])
    }

    private func message(_ index: Int = 0, event: String = "client-yjs-update") throws -> ProjectNoteOutboundMessage {
        ProjectNoteOutboundMessage(event: event, payload: try JSONSerialization.data(withJSONObject: ["id": "fixture", "i": index, "n": 20, "d": "AAA="]))
    }

    func test_outboundQueueLimitsBurstyTimersToEightMessagesPerRollingSecond() throws {
        var queue = ProjectNoteOutboundQueue(identity: identity)
        let messages = try (0..<10).map { try message($0) }
        XCTAssertEqual(queue.enqueue(messages, identity: identity), .accepted)
        for index in 0..<8 { XCTAssertEqual(queue.next(at: 10, identity: identity), messages[index]) }
        XCTAssertNil(queue.next(at: 10.999, identity: identity))
        XCTAssertEqual(queue.next(at: 11, identity: identity), messages[8])
        XCTAssertEqual(queue.next(at: 11, identity: identity), messages[9])
        XCTAssertNil(queue.next(at: 11, identity: identity))
    }

    func test_allEventTypesShareTheSameRollingLimit() throws {
        var queue = ProjectNoteOutboundQueue(identity: identity)
        let events = ["client-yjs-update", "client-yjs-awareness", "client-yjs-sync-request", "client-yjs-sync-reply"]
        for index in 0..<12 {
            let next = try message(index, event: events[index % events.count])
            XCTAssertEqual(queue.enqueue(event: next.event, payload: next.payload, identity: identity), .accepted)
        }
        for index in 0..<8 { XCTAssertNotNil(queue.next(at: Double(index) * 0.1, identity: identity)) }
        XCTAssertNil(queue.next(at: 0.999, identity: identity))
        XCTAssertNotNil(queue.next(at: 1, identity: identity))
        XCTAssertNil(queue.next(at: 1.01, identity: identity), "seven earlier events are still inside the rolling second")
    }

    func test_outboundQueueNeverAcceptsOrDrainsAnotherAccountOrNote() throws {
        var queue = ProjectNoteOutboundQueue(identity: identity)
        let next = try message()
        let other = ProjectNoteIdentity(accountID: "other", projectID: identity.projectID, noteID: identity.noteID)
        XCTAssertEqual(queue.enqueue([next], identity: other), .wrongIdentity)
        XCTAssertEqual(queue.count, 0)
        XCTAssertFalse(queue.requiresResync)
        XCTAssertEqual(queue.enqueue([next], identity: identity), .accepted)
        XCTAssertNil(queue.next(at: 1000, identity: other))
        XCTAssertEqual(queue.next(at: 1, identity: identity), next)
    }

    func test_chunkGroupCapacityOverflowSignalsRecoveryWithoutAPartialSuffix() throws {
        var queue = ProjectNoteOutboundQueue(identity: identity)
        let next = try message()
        XCTAssertEqual(queue.enqueue(Array(repeating: next, count: ProjectNoteOutboundQueue.maxPendingMessages - 1), identity: identity), .accepted)
        XCTAssertEqual(queue.enqueue([next, next], identity: identity), .resyncRequired)
        XCTAssertEqual(queue.count, 0)
        XCTAssertTrue(queue.requiresResync)
        XCTAssertNil(queue.next(at: 1, identity: identity))
        XCTAssertEqual(queue.enqueue([next], identity: identity), .resyncRequired)
    }

    func test_outboundByteCapacityIsBoundedIndependentlyOfMessageCount() throws {
        var queue = ProjectNoteOutboundQueue(identity: identity)
        let payload = try JSONSerialization.data(withJSONObject: ["d": String(repeating: "A", count: 9000)])
        let next = ProjectNoteOutboundMessage(event: "client-yjs-update", payload: payload)
        XCTAssertLessThan(payload.count, ProjectNoteOutboundQueue.maxPayloadBytes)
        XCTAssertEqual(queue.enqueue(Array(repeating: next, count: 1000), identity: identity), .resyncRequired)
        XCTAssertTrue(queue.requiresResync)
        XCTAssertEqual(queue.count, 0)
    }

    func test_invalidOrOversizedEventRequiresResyncInsteadOfBeingSilentlyLost() throws {
        let invalid = [
            ProjectNoteOutboundMessage(event: "client-other", payload: Data("{}".utf8)),
            ProjectNoteOutboundMessage(event: "client-yjs-update", payload: Data("[]".utf8)),
            ProjectNoteOutboundMessage(event: "client-yjs-update", payload: Data("{broken".utf8)),
            ProjectNoteOutboundMessage(event: "client-yjs-update", payload: Data(repeating: 32, count: ProjectNoteOutboundQueue.maxPayloadBytes + 1))
        ]
        for message in invalid {
            var queue = ProjectNoteOutboundQueue(identity: identity)
            XCTAssertEqual(queue.enqueue([message], identity: identity), .resyncRequired)
            XCTAssertTrue(queue.requiresResync)
            XCTAssertEqual(queue.count, 0)
        }
    }

    func test_resyncDoesNotResetConnectionRateHistory() throws {
        var queue = ProjectNoteOutboundQueue(identity: identity)
        let next = try message()
        _ = queue.enqueue(Array(repeating: next, count: 8), identity: identity)
        for _ in 0..<8 { XCTAssertNotNil(queue.next(at: 1, identity: identity)) }
        queue.markRequiresResync()
        queue.resumeAfterResync()
        XCTAssertEqual(queue.enqueue([next], identity: identity), .accepted)
        XCTAssertNil(queue.next(at: 1.5, identity: identity))
        XCTAssertEqual(queue.next(at: 2, identity: identity), next)
    }

    func test_invalidOrBackwardsClockDoesNotDrainQueuedWork() throws {
        var queue = ProjectNoteOutboundQueue(identity: identity)
        let next = try message()
        _ = queue.enqueue([next, next], identity: identity)
        XCTAssertNil(queue.next(at: -1, identity: identity))
        XCTAssertEqual(queue.next(at: 10, identity: identity), next)
        for time in [Double(9), .nan, .infinity, -.infinity] {
            XCTAssertNil(queue.next(at: time, identity: identity))
        }
        XCTAssertEqual(queue.count, 1)
        XCTAssertEqual(queue.next(at: 10.1, identity: identity), next)
    }
}
