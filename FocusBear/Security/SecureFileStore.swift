//
//  SecureFileStore.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// Sealed storage for the files `SensitiveKeyRegistry.files` lists (the stats, offline-activity and
/// AI-decision CSVs and the like), with the same per-account key and failure rules as `SecureStore`.
///
/// Callers keep passing the file's usual URL. While the store is ready the data lives in
/// `Secure/<account scope>/files/<file name>.fbl`:
///
///     "FBL2" | record | record | …        record = length (UInt32, big endian) | SecureEnvelope
///
/// An append adds one sealed record, so a crash can only cut off the last record (which a reader
/// ignores). A plaintext file older builds left at the usual URL is folded into the sealed file on the
/// next access (or at launch) and deleted once the sealed copy reads back identically.
///
/// While the key is unavailable nothing is written anywhere: writes and appends wait in memory and are
/// sealed when the key loads, reads see the plaintext an older build left (if any) plus those waiting
/// writes, and the sealed file is never touched. A local-only file rewritten while its sealed copy
/// couldn't be read is merged with that copy (rows are kept, never dropped) rather than replaced.
final class SecureFileStore {
    static let folderName = "files"
    static let magic = Data("FBL2".utf8)
    static let sealedExtension = "fbl"
    static let slotPrefix = "file/"
    private static let recordLengthBytes = 4
    private static let newline = "\n"

    /// How two versions of a file combine.
    enum Kind {
        /// Rows after a header: the incoming rows the existing copy lacks are appended.
        case csv
        /// One JSON object per line: likewise, by line.
        case jsonLines
        /// A whole document: the incoming copy replaces the existing one.
        case document

        init(fileName: String) {
            switch (fileName as NSString).pathExtension.lowercased() {
            case "csv": self = .csv
            case "jsonl": self = .jsonLines
            default: self = .document
            }
        }
    }

    private enum HeldFileWrite {
        /// The whole file, as the caller last wrote it (plus anything appended since).
        case replace(Data)
        /// Records appended to whatever the file holds.
        case append(Data)
        case remove
    }

    let store: SecureStore
    private let fileManager = FileManager.default
    /// One lock for every file: appends arrive from several logger queues, reads from the main thread.
    private let lock = NSRecursiveLock()
    private var held: [String: (url: URL, write: HeldFileWrite)] = [:]
    private var readyObserver: NSObjectProtocol?

    init(store: SecureStore) {
        self.store = store
        readyObserver = NotificationCenter.default.addObserver(forName: SecureStore.didBecomeReady, object: store,
                                                               queue: nil) { [weak self] _ in
            self?.applyHeldWrites()
        }
    }

    deinit {
        if let readyObserver { NotificationCenter.default.removeObserver(readyObserver) }
    }

    // MARK: - API

    func isRegistered(_ url: URL) -> Bool {
        store.registry.fileEntry(for: url.lastPathComponent) != nil
    }

    func exists(_ url: URL) -> Bool {
        synchronized {
            if fileManager.fileExists(atPath: url.path) { return true }
            guard isRegistered(url) else { return false }
            if let pending = held[url.path] {
                if case .remove = pending.write { return false }
                return true
            }
            // Existence needs no key: a sealed copy the key can't open yet still means "don't recreate".
            guard let accountId = store.currentAccountId else { return false }
            return fileManager.fileExists(atPath: sealedURL(for: url, scope: SecureStore.accountScope(for: accountId)).path)
        }
    }

    /// Throws `CocoaError(.fileReadNoSuchFile)` when there is nothing to read, like `Data(contentsOf:)`.
    func readData(_ url: URL) throws -> Data {
        try synchronized {
            guard isRegistered(url), isEncrypting else { return try Data(contentsOf: url) }
            guard let context = sealingContext() else { return try unsealedView(of: url) }
            try adoptPlaintext(at: url, context: context)
            let sealed = sealedURL(for: url, scope: context.scope)
            guard fileManager.fileExists(atPath: sealed.path) else { throw CocoaError(.fileReadNoSuchFile) }
            return try openAll(sealed, slot: slot(for: url), context: context)
        }
    }

    func readText(_ url: URL) throws -> String {
        guard let text = String(data: try readData(url), encoding: .utf8) else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        return text
    }

    /// Replaces the whole file.
    func write(_ data: Data, to url: URL) throws {
        try synchronized {
            guard isRegistered(url), isEncrypting else {
                try data.write(to: url, options: .atomic)
                return
            }
            guard let context = sealingContext() else {
                hold(.replace(data), for: url)
                return
            }
            try writeSealed(data, for: url, context: context)
            // The new content supersedes any plaintext copy.
            try? fileManager.removeItem(at: url)
        }
    }

    func writeText(_ text: String, to url: URL) throws {
        try write(Data(text.utf8), to: url)
    }

    func append(_ data: Data, to url: URL) throws {
        try synchronized {
            guard isRegistered(url), isEncrypting else {
                try appendPlaintext(data, to: url)
                return
            }
            guard let context = sealingContext() else {
                hold(.append(data), for: url)
                return
            }
            try appendSealed(data, to: url, context: context)
        }
    }

    func appendText(_ text: String, to url: URL) throws {
        try append(Data(text.utf8), to: url)
    }

    /// Seals a plaintext copy now rather than on the file's next read or append, which for a rarely
    /// touched CSV could be weeks away. A no-op until the key is available.
    func sealPlaintextIfPresent(_ url: URL) {
        synchronized {
            guard isRegistered(url), isEncrypting, let context = sealingContext() else { return }
            do {
                try adoptPlaintext(at: url, context: context)
            } catch {
                addLog(text: "[secure-store] could not seal \(url.lastPathComponent) yet: \(error)")
            }
        }
    }

    func remove(_ url: URL) {
        synchronized {
            guard isRegistered(url), isEncrypting else {
                try? fileManager.removeItem(at: url)
                return
            }
            guard let context = sealingContext() else {
                hold(.remove, for: url)
                guard durability(of: url) == .serverBacked else { return }
                // Deleting needs no key; a server-backed copy can always be fetched again.
                try? fileManager.removeItem(at: url)
                if let scope = store.currentAccountId.map(SecureStore.accountScope(for:)) {
                    try? fileManager.removeItem(at: sealedURL(for: url, scope: scope))
                }
                return
            }
            try? fileManager.removeItem(at: url)
            try? fileManager.removeItem(at: sealedURL(for: url, scope: context.scope))
        }
    }

    // MARK: - Held writes

    private func hold(_ write: HeldFileWrite, for url: URL) {
        let previous = held[url.path]?.write
        let combined: HeldFileWrite
        switch (previous, write) {
        case (.replace(let base)?, .append(let more)):
            combined = .replace(Self.joined(base, more))
        case (.append(let base)?, .append(let more)):
            combined = .append(Self.joined(base, more))
        case (.remove?, .append(let more)):
            combined = .replace(more)
        default:
            combined = write
        }
        if previous == nil {
            addLog(text: "[secure-store] holding \(url.lastPathComponent) in memory until the data key is available")
        }
        held[url.path] = (url, combined)
    }

    /// What a reader sees while the key is unavailable: older plaintext plus the writes waiting for the
    /// key. Never the sealed copy, which can't be opened.
    private func unsealedView(of url: URL) throws -> Data {
        let plaintext = try? Data(contentsOf: url)
        switch held[url.path]?.write {
        case .replace(let data)?:
            return data
        case .append(let data)?:
            return plaintext.map { Self.joined($0, data) } ?? data
        case .remove?:
            throw CocoaError(.fileReadNoSuchFile)
        case nil:
            guard let plaintext else { throw CocoaError(.fileReadNoSuchFile) }
            return plaintext
        }
    }

    /// Seals what waited for the key. Appends always land; a local-only rewrite made without seeing the
    /// sealed copy merges into it; a local-only removal made without seeing it is not applied.
    func applyHeldWrites() {
        synchronized {
            guard let context = sealingContext(), !held.isEmpty else { return }
            let writes = held
            held.removeAll()
            for (_, pending) in writes {
                let url = pending.url
                do {
                    let sealed = sealedURL(for: url, scope: context.scope)
                    let unseenSealed = durability(of: url) == .localOnly && fileManager.fileExists(atPath: sealed.path)
                    switch pending.write {
                    case .append(let data):
                        try appendSealed(data, to: url, context: context)
                    case .replace(let data):
                        if unseenSealed {
                            let existing = try openAll(sealed, slot: slot(for: url), context: context)
                            try writeSealed(Self.merge(existing: existing, incoming: data, kind: Kind(fileName: url.lastPathComponent)),
                                            for: url, context: context)
                        } else {
                            try writeSealed(data, for: url, context: context)
                        }
                        try? fileManager.removeItem(at: url)
                    case .remove:
                        if unseenSealed {
                            addLog(text: "[secure-store] kept \(url.lastPathComponent): it was removed before its sealed copy could be read")
                            continue
                        }
                        try? fileManager.removeItem(at: url)
                        try? fileManager.removeItem(at: sealed)
                    }
                } catch {
                    addLog(text: "[secure-store] could not seal the held \(url.lastPathComponent): \(error); kept in memory")
                    held[url.path] = pending
                }
            }
        }
    }

    // MARK: - Account housekeeping (called by SecureStore)

    /// Sign-out: the server-backed sealed files go, local-only ones stay for the account's next sign-in.
    static func removeServerBackedFiles(in directory: URL, registry: SensitiveKeyRegistry) {
        for file in sealedFiles(in: directory) {
            let name = file.deletingPathExtension().lastPathComponent
            if registry.fileEntry(for: name)?.durability == .serverBacked {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    static func hasFiles(in directory: URL) -> Bool {
        !sealedFiles(in: directory).isEmpty
    }

    private static func sealedFiles(in directory: URL) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == sealedExtension }
    }

    // MARK: - Paths

    func sealedURL(for url: URL, scope: String) -> URL {
        store.filesDirectory(scope: scope).appendingPathComponent(url.lastPathComponent)
            .appendingPathExtension(Self.sealedExtension)
    }

    private func slot(for url: URL) -> String {
        Self.slotPrefix + url.lastPathComponent
    }

    private func durability(of url: URL) -> SensitiveKey.Durability {
        store.registry.fileEntry(for: url.lastPathComponent)?.durability ?? .localOnly
    }

    // MARK: - Sealed format

    private struct SealingContext {
        let scope: String
        let key: SecureStore.SealingKey
    }

    private var isEncrypting: Bool {
        if case .disabled = store.currentState { return false }
        return true
    }

    private func sealingContext() -> SealingContext? {
        guard store.currentState.isReady, let accountId = store.currentAccountId, let key = store.sealingKey else { return nil }
        return SealingContext(scope: SecureStore.accountScope(for: accountId), key: key)
    }

    private func record(_ plaintext: Data, slot: String, context: SealingContext) throws -> Data {
        let envelope = try store.seal(plaintext, slot: slot, scope: context.scope, with: context.key)
        var length = UInt32(envelope.count).bigEndian
        return withUnsafeBytes(of: &length) { Data($0) } + envelope
    }

    /// Every readable record, in order. A record that won't open is skipped (and logged); a record cut
    /// short by a crash ends the file.
    private func openAll(_ sealed: URL, slot: String, context: SealingContext) throws -> Data {
        let bytes = try Data(contentsOf: sealed)
        guard bytes.prefix(Self.magic.count) == Self.magic else { throw SecureEnvelopeError.notAnEnvelope }
        var offset = Self.magic.count
        var plaintext = Data()
        while offset + Self.recordLengthBytes <= bytes.count {
            let length = bytes.subdata(in: offset..<offset + Self.recordLengthBytes).reduce(0) { ($0 << 8) | Int($1) }
            let start = offset + Self.recordLengthBytes
            guard length > 0, start + length <= bytes.count else {
                addLog(text: "[secure-store] ignored a truncated record at the end of \(sealed.lastPathComponent)")
                break
            }
            do {
                plaintext += try store.open(bytes.subdata(in: start..<start + length), slot: slot,
                                            scope: context.scope, with: context.key)
            } catch {
                addLog(text: "[secure-store] skipped an unreadable record in \(sealed.lastPathComponent): \(error)")
            }
            offset = start + length
        }
        return plaintext
    }

    private func writeSealed(_ data: Data, for url: URL, context: SealingContext) throws {
        let sealed = sealedURL(for: url, scope: context.scope)
        try store.ensureDirectory(sealed.deletingLastPathComponent())
        try store.atomicWrite(Self.magic + record(data, slot: slot(for: url), context: context), to: sealed)
    }

    private func appendSealed(_ data: Data, to url: URL, context: SealingContext) throws {
        try adoptPlaintext(at: url, context: context)
        let sealed = sealedURL(for: url, scope: context.scope)
        if !fileManager.fileExists(atPath: sealed.path) {
            try store.ensureDirectory(sealed.deletingLastPathComponent())
            guard fileManager.createFile(atPath: sealed.path, contents: Self.magic,
                                         attributes: [.posixPermissions: SecureStore.fileMode]) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forWritingTo: sealed)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: try record(data, slot: slot(for: url), context: context))
    }

    // MARK: - Plaintext

    /// Folds a plaintext file at the usual URL into the sealed file, then deletes it — only after the
    /// sealed file reads back as exactly the merged content.
    private func adoptPlaintext(at url: URL, context: SealingContext) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        let plaintext = try Data(contentsOf: url)
        let sealed = sealedURL(for: url, scope: context.scope)
        let existing = fileManager.fileExists(atPath: sealed.path) ? try openAll(sealed, slot: slot(for: url), context: context) : nil
        let merged = existing.map { Self.merge(existing: $0, incoming: plaintext, kind: Kind(fileName: url.lastPathComponent)) } ?? plaintext
        try writeSealed(merged, for: url, context: context)
        guard try openAll(sealed, slot: slot(for: url), context: context) == merged else {
            throw SecureEnvelopeError.authenticationFailed
        }
        try fileManager.removeItem(at: url)
        addLog(text: "[secure-store] sealed \(url.lastPathComponent)")
    }

    static func merge(existing: Data, incoming: Data, kind: Kind) -> Data {
        guard !existing.isEmpty else { return incoming }
        switch kind {
        case .document:
            return incoming
        case .csv, .jsonLines:
            let existingLines = String(decoding: existing, as: UTF8.self).components(separatedBy: newline)
            let known = Set(existingLines)
            let missing = String(decoding: incoming, as: UTF8.self).components(separatedBy: newline)
                .filter { !$0.isEmpty && !known.contains($0) }
            guard !missing.isEmpty else { return existing }
            return joined(existing, Data((missing.joined(separator: newline) + newline).utf8))
        }
    }

    private static func joined(_ first: Data, _ second: Data) -> Data {
        guard !first.isEmpty, !second.isEmpty else { return first + second }
        let needsNewline = first.last != UInt8(ascii: "\n")
        return first + (needsNewline ? Data(newline.utf8) : Data()) + second
    }

    private func appendPlaintext(_ data: Data, to url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            try data.write(to: url)
            return
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }

    private func synchronized<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
