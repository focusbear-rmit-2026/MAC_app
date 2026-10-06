import Foundation
import CryptoKit
import CoreFoundation
import Darwin

struct ProjectNoteIdentity: Hashable, Codable {
    let accountID: String
    let projectID: String
    let noteID: String

    fileprivate var isValid: Bool {
        [accountID, projectID, noteID].allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.utf8.count <= 1024
                && $0.rangeOfCharacter(from: .controlCharacters) == nil
        }
    }
}

enum ProjectNoteDraftError: Error, Equatable {
    case invalidIdentity
    case invalidSnapshot
    case snapshotTooLarge
    case storageUnavailable
}

/// How a draft is kept at rest. Drafts are local-only (unsynced edits), so a draft that can't be sealed
/// right now is not written at all — the editor keeps its state in memory — and one that can't be opened
/// right now reads as absent but is never deleted or overwritten.
protocol ProjectNoteDraftSealing {
    /// The bytes to store, or nil when the data key is unavailable (nothing may be written then).
    func seal(_ envelope: Data, slot: String) -> Data?
    /// The plain envelope, or nil when the stored bytes can't be opened right now.
    func open(_ stored: Data, slot: String) -> Data?
}

/// Seals drafts with the signed-in account's data key (SecureStore). A draft written by an older build
/// is plain JSON: it is still read, and `sealLegacyDrafts` replaces it with a sealed copy.
struct SecureStoreDraftSealing: ProjectNoteDraftSealing {
    static let slotPrefix = "note-draft/"
    var store: SecureStore = .shared

    func seal(_ envelope: Data, slot: String) -> Data? {
        if case .disabled = store.currentState { return envelope }
        guard let context = context() else { return nil }
        return try? store.seal(envelope, slot: Self.slotPrefix + slot, scope: context.scope, with: context.key)
    }

    func open(_ stored: Data, slot: String) -> Data? {
        guard SecureEnvelope.isEnvelope(stored) else { return stored }
        guard let context = context() else { return nil }
        return try? store.open(stored, slot: Self.slotPrefix + slot, scope: context.scope, with: context.key)
    }

    private func context() -> (scope: String, key: SecureStore.SealingKey)? {
        guard store.currentState.isReady, let accountId = store.currentAccountId, let key = store.sealingKey else { return nil }
        return (SecureStore.accountScope(for: accountId), key)
    }
}

/// A private recovery copy, never a replacement for merging Yjs state from the server/peers.
/// All operations require the complete identity; no "last note" or cross-account fallback exists.
/// Callers must also retain/check the current account and note generation around async operations.
final class ProjectNoteDraftStore {
    // Backend feat/project-notes-realtime-3062: constants.ts, SaveNoteDocDto and mergeYjsStates.
    static let maxYjsStateBytes = 5 * 1024 * 1024
    static let maxYjsStateBase64Length = ((maxYjsStateBytes + 2) / 3) * 4
    static let maxSnapshotBytes = 8 * 1024 * 1024
    static let maxRevision: Int64 = 9_007_199_254_740_991 // JavaScript Number.MAX_SAFE_INTEGER

    private struct Envelope: Codable {
        let version: Int
        let identity: ProjectNoteIdentity
        let snapshot: Data
    }

    // Codable Data adds one base64 layer; cap reads before decoding it. Identity fields are bounded.
    private static let maxStoredBytes = ((maxSnapshotBytes + 2) / 3) * 4 + 32 * 1024
    /// Room for the sealed envelope's header, nonce and tag, so a draft at the size limit still loads.
    private static let sealingOverheadBytes = 256
    private static let fileLock = NSLock()
    private static let draftExtension = "json"
    private let directory: URL
    private let sealing: ProjectNoteDraftSealing
    private let files = FileManager.default

    static var defaultDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        return support.appendingPathComponent("FocusBear/ProjectNoteDrafts-v1", isDirectory: true)
    }

    init(directory: URL? = nil, sealing: ProjectNoteDraftSealing = SecureStoreDraftSealing()) {
        self.directory = directory ?? Self.defaultDirectory
        self.sealing = sealing
    }

    /// Replaces every plain-JSON draft an older build left with a sealed copy: sealed, opened again and
    /// compared in memory, then renamed over the original (so a failure leaves the original in place).
    /// Idempotent; a no-op while the data key is unavailable. Returns how many drafts were sealed.
    @discardableResult
    func sealLegacyDrafts() -> Int {
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        let names = (try? files.contentsOfDirectory(atPath: directory.path)) ?? []
        var sealed = 0
        for name in names where (name as NSString).pathExtension == Self.draftExtension {
            let url = directory.appendingPathComponent(name, isDirectory: false)
            guard let stored = try? Data(contentsOf: url), !SecureEnvelope.isEnvelope(stored),
                  stored.count <= Self.maxStoredBytes,
                  (try? JSONDecoder().decode(Envelope.self, from: stored)) != nil,
                  let replacement = sealing.seal(stored, slot: name), SecureEnvelope.isEnvelope(replacement),
                  sealing.open(replacement, slot: name) == stored else { continue }
            do {
                try atomicWrite(replacement, to: url)
                sealed += 1
            } catch {
                addLog(text: "[secure-store] could not seal a project note draft yet")
            }
        }
        return sealed
    }

    /// Corrupt, oversized, unsupported or differently scoped files are not returned or deleted.
    /// A load never creates directories or mutates app data.
    func load(identity: ProjectNoteIdentity) -> Data? {
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        return loadLocked(identity: identity)
    }

    func save(_ snapshot: Data, identity: ProjectNoteIdentity) throws {
        let data = try encoded(snapshot, identity: identity)
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        try saveLocked(data, identity: identity)
    }

    /// A detached/closing editor may only replace the recovery copy it last owned. `nil` means
    /// the file must be absent, not unreadable or corrupt. Both comparison and atomic replacement
    /// share the same lock across store instances. A mismatch leaves the existing draft untouched.
    @discardableResult
    func save(_ snapshot: Data, identity: ProjectNoteIdentity, replacing expected: Data?) throws -> Bool {
        let data = try encoded(snapshot, identity: identity)
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        if let expected = expected {
            guard loadLocked(identity: identity) == expected else { return false }
        } else {
            var info = stat()
            guard Darwin.lstat(fileURL(identity: identity).path, &info) != 0, errno == ENOENT else { return false }
        }
        try saveLocked(data, identity: identity)
        return true
    }

    private func encoded(_ snapshot: Data, identity: ProjectNoteIdentity) throws -> Data {
        guard identity.isValid else { throw ProjectNoteDraftError.invalidIdentity }
        _ = try Self.revision(in: snapshot)
        let envelope = Envelope(version: 1, identity: identity, snapshot: snapshot)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(envelope)
        guard data.count <= Self.maxStoredBytes - Self.sealingOverheadBytes else { throw ProjectNoteDraftError.snapshotTooLarge }
        return data
    }

    private func saveLocked(_ data: Data, identity: ProjectNoteIdentity) throws {
        do {
            try files.createDirectory(at: directory, withIntermediateDirectories: true,
                                      attributes: [.posixPermissions: 0o700])
            guard try files.attributesOfItem(atPath: directory.path)[.type] as? FileAttributeType == .typeDirectory else {
                throw ProjectNoteDraftError.storageUnavailable
            }
            try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            let destination = fileURL(identity: identity)
            guard let stored = sealing.seal(data, slot: destination.lastPathComponent) else {
                throw ProjectNoteDraftError.storageUnavailable
            }
            try atomicWrite(stored, to: destination)
        } catch {
            // Do not propagate paths or serialized note data into generic error/log pipelines.
            throw ProjectNoteDraftError.storageUnavailable
        }
    }

    /// Explicit discard only. For an asynchronous server acknowledgement, match its exact snapshot.
    func remove(identity: ProjectNoteIdentity) throws {
        guard identity.isValid else { throw ProjectNoteDraftError.invalidIdentity }
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        try removeLocked(identity: identity)
    }

    /// Preferred for server acknowledgements across editor lifetimes: a reopened document can
    /// reuse a revision number, so compare the exact captured snapshot before deleting its draft.
    @discardableResult
    func remove(identity: ProjectNoteIdentity, matching snapshot: Data) throws -> Bool {
        guard identity.isValid else { throw ProjectNoteDraftError.invalidIdentity }
        Self.fileLock.lock()
        defer { Self.fileLock.unlock() }
        guard let current = loadLocked(identity: identity), current == snapshot else { return false }
        try removeLocked(identity: identity)
        return true
    }

    /// Validate the transport shape before persisting. Semantic Yjs decoding/merging belongs to the
    /// bundled Yjs editor/backend; valid base64 alone cannot establish that a CRDT update is valid.
    static func revision(in snapshot: Data) throws -> Int64 {
        guard snapshot.count <= maxSnapshotBytes else { throw ProjectNoteDraftError.snapshotTooLarge }
        guard let object = try? JSONSerialization.jsonObject(with: snapshot) as? [String: Any],
              let base64 = object["yjs_state"] as? String,
              !base64.isEmpty,
              let content = object["content"] as? [String: Any],
              content["type"] as? String == "doc",
              let revision = object["revision"] as? NSNumber,
              CFGetTypeID(revision) != CFBooleanGetTypeID() else {
            throw ProjectNoteDraftError.invalidSnapshot
        }
        guard base64.utf8.count <= maxYjsStateBase64Length else { throw ProjectNoteDraftError.snapshotTooLarge }
        guard let update = Data(base64Encoded: base64), !update.isEmpty,
              update.base64EncodedString() == base64 else { throw ProjectNoteDraftError.invalidSnapshot }
        guard update.count <= maxYjsStateBytes else { throw ProjectNoteDraftError.snapshotTooLarge }
        // ProseMirror omits `content` for an empty root. If present, it must be a node array.
        if let children = content["content"], !(children is [[String: Any]]) {
            throw ProjectNoteDraftError.invalidSnapshot
        }
        let number = revision.doubleValue
        guard number.isFinite, number >= 0, number <= Double(maxRevision),
              number.rounded(.towardZero) == number else { throw ProjectNoteDraftError.invalidSnapshot }
        return revision.int64Value
    }

    private func fileURL(identity: ProjectNoteIdentity) -> URL {
        // Byte-length framing avoids delimiter collisions between the identity components.
        var encoded = Data()
        for value in [identity.accountID, identity.projectID, identity.noteID] {
            var length = UInt64(value.utf8.count).bigEndian
            withUnsafeBytes(of: &length) { encoded.append(contentsOf: $0) }
            encoded.append(contentsOf: value.utf8)
        }
        let digest = SHA256.hash(data: encoded).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(digest + "." + Self.draftExtension, isDirectory: false)
    }

    private func loadLocked(identity: ProjectNoteIdentity) -> Data? {
        guard identity.isValid,
              let attributes = try? files.attributesOfItem(atPath: directory.path),
              attributes[.type] as? FileAttributeType == .typeDirectory else { return nil }
        let path = fileURL(identity: identity)
        let descriptor = Darwin.open(path.path, O_RDONLY | O_NOFOLLOW)
        guard descriptor >= 0 else { return nil }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }
        var info = stat()
        guard fstat(descriptor, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG,
              info.st_size > 0, info.st_size <= Self.maxStoredBytes else { return nil }
        guard let stored = try? handle.read(upToCount: Self.maxStoredBytes + 1),
              stored.count <= Self.maxStoredBytes,
              let data = sealing.open(stored, slot: path.lastPathComponent),
              let value = try? JSONDecoder().decode(Envelope.self, from: data),
              value.version == 1, value.identity == identity,
              (try? Self.revision(in: value.snapshot)) != nil else { return nil }
        return value.snapshot
    }

    private func removeLocked(identity: ProjectNoteIdentity) throws {
        guard files.fileExists(atPath: directory.path) else { return }
        guard let attributes = try? files.attributesOfItem(atPath: directory.path),
              attributes[.type] as? FileAttributeType == .typeDirectory else {
            throw ProjectNoteDraftError.storageUnavailable
        }
        let path = fileURL(identity: identity)
        guard files.fileExists(atPath: path.path) else { return }
        do { try files.removeItem(at: path) }
        catch { throw ProjectNoteDraftError.storageUnavailable }
    }

    private func atomicWrite(_ data: Data, to destination: URL) throws {
        let temporary = directory.appendingPathComponent("." + UUID().uuidString + ".tmp")
        let descriptor = Darwin.open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, mode_t(0o600))
        guard descriptor >= 0 else { throw ProjectNoteDraftError.storageUnavailable }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer {
            try? handle.close()
            try? files.removeItem(at: temporary)
        }
        try handle.write(contentsOf: data)
        try handle.synchronize()
        try handle.close()
        guard Darwin.rename(temporary.path, destination.path) == 0 else { throw ProjectNoteDraftError.storageUnavailable }
        // Sync the rename as well as the file contents. A failed sync is surfaced, not reported saved.
        let directoryDescriptor = Darwin.open(directory.path, O_RDONLY | O_NOFOLLOW)
        guard directoryDescriptor >= 0 else { throw ProjectNoteDraftError.storageUnavailable }
        defer { Darwin.close(directoryDescriptor) }
        guard Darwin.fsync(directoryDescriptor) == 0 else { throw ProjectNoteDraftError.storageUnavailable }
    }
}

struct ProjectNoteOutboundMessage: Equatable {
    let event: String
    let payload: Data
}

/// All four client-event types must share this queue for one Pusher connection. Supply monotonic
/// uptime to `next`; draining on a 0.15-second timer is fine, and late/bursty timers cannot exceed
/// eight events in a rolling second. Check identity again immediately before calling the transport.
struct ProjectNoteOutboundQueue {
    enum EnqueueResult: Equatable { case accepted, wrongIdentity, resyncRequired }
    static let maxMessagesPerSecond = 8
    static let maxPayloadBytes = 9500
    static let maxPendingMessages = 1024
    static let maxPendingBytes = 8 * 1024 * 1024
    private static let events: Set<String> = ["client-yjs-update", "client-yjs-awareness", "client-yjs-sync-request", "client-yjs-sync-reply"]

    let identity: ProjectNoteIdentity
    private var pending: [ProjectNoteOutboundMessage] = []
    private var pendingBytes = 0
    private var sentAt: [TimeInterval] = []
    private var lastDrainAt: TimeInterval?
    private(set) var requiresResync = false
    var count: Int { pending.count }

    init(identity: ProjectNoteIdentity) { self.identity = identity }

    @discardableResult
    mutating func enqueue(event: String, payload: Data, identity: ProjectNoteIdentity) -> EnqueueResult {
        enqueue([ProjectNoteOutboundMessage(event: event, payload: payload)], identity: identity)
    }

    /// Enqueue a chunk group atomically, so a local capacity rejection never accepts only a prefix.
    @discardableResult
    mutating func enqueue(_ messages: [ProjectNoteOutboundMessage], identity: ProjectNoteIdentity) -> EnqueueResult {
        guard identity == self.identity, identity.isValid else { return .wrongIdentity }
        guard !requiresResync else { return .resyncRequired }
        guard messages.count <= Self.maxPendingMessages - pending.count else {
            markRequiresResync()
            return .resyncRequired
        }
        var bytes = 0
        for message in messages {
            guard Self.events.contains(message.event), !message.payload.isEmpty,
                  message.payload.count <= Self.maxPayloadBytes,
                  (try? JSONSerialization.jsonObject(with: message.payload)) is [String: Any] else {
                markRequiresResync()
                return .resyncRequired
            }
            bytes += message.payload.count
            guard bytes <= Self.maxPendingBytes else { markRequiresResync(); return .resyncRequired }
        }
        guard bytes <= Self.maxPendingBytes - pendingBytes else {
            markRequiresResync()
            return .resyncRequired
        }
        pending.append(contentsOf: messages)
        pendingBytes += bytes
        return .accepted
    }

    mutating func next(at now: TimeInterval, identity: ProjectNoteIdentity) -> ProjectNoteOutboundMessage? {
        guard identity == self.identity, !requiresResync, now.isFinite, now >= 0,
              lastDrainAt.map({ now >= $0 }) ?? true else { return nil }
        lastDrainAt = now
        sentAt.removeAll { now - $0 >= 1 }
        guard !pending.isEmpty, sentAt.count < Self.maxMessagesPerSecond else { return nil }
        let message = pending.removeFirst()
        pendingBytes -= message.payload.count
        sentAt.append(now)
        return message
    }

    /// Overflow or transport failure must persist/recover a fresh merged document snapshot and
    /// resynchronise peers. The sticky signal prevents silently continuing after missing updates.
    mutating func markRequiresResync() {
        requiresResync = true
        pending.removeAll(keepingCapacity: false)
        pendingBytes = 0
    }

    /// Only call after the owner has scheduled full document persistence and peer resynchronisation.
    /// Retain rate history so recovery cannot bypass the connection's rolling event limit.
    mutating func resumeAfterResync() { requiresResync = false }
}
