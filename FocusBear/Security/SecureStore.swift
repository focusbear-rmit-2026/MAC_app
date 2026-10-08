//
//  SecureStore.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import CryptoKit
import Foundation
import Sentry

enum SecureStoreState: Equatable {
    /// This build never encrypts (ad-hoc signed): registered values stay in UserDefaults, as before.
    /// A build property decided once at launch, never a fallback taken because a key was missing.
    case disabled(reason: String)
    /// No signed-in account yet, so no data key to load.
    case awaitingAccount
    /// The account's key can't be read right now. Nothing is written in plaintext, nothing sealed is
    /// touched; writes wait in memory and the key is retried.
    case unavailable(reason: String)
    case ready(keyId: String)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var summary: String {
        switch self {
        case .disabled(let reason): return "disabled (\(reason))"
        case .awaitingAccount: return "awaiting account"
        case .unavailable(let reason): return "unavailable (\(reason))"
        case .ready(let keyId): return "ready key=\(keyId)"
        }
    }
}

/// Encrypted storage, per Focus Bear account, for the UserDefaults keys `SensitiveKeyRegistry` lists.
///
/// Each value is one sealed file (`SecureEnvelope`, AES-GCM), `Secure/<account scope>/v1/<sha256(key)>.fbs`
/// in the app's Application Support folder — folders 0700, files 0600, written atomically. The key is
/// a random 256-bit data key per account in the keychain (`DataKeyProviding`). Another account has
/// another folder and another key, so it can never read these.
///
/// Reads are served from memory: every value is decrypted once, when the account's key loads. Writes
/// update memory at once and are sealed to disk on a utility queue; `flush()` waits for them.
///
/// What happens when the key is missing depends on the value (`SensitiveKey.Durability`):
///
/// - **Server-backed** caches: an unreadable sealed value is treated as absent (the app re-fetches it)
///   and deleted; writes made while the key is unavailable are held in memory and sealed once it loads.
/// - **Local-only** data: a sealed value that can't be opened is quarantined, never deleted; writes made
///   while the key is unavailable are held in memory and *merged* into the sealed value once it loads
///   (`SecureMerge`), and a removal made without having seen the sealed value is not applied.
///
/// In neither case is anything written in plaintext. Plaintext an older build left in UserDefaults is
/// migrated per key: sealed, read back from disk and compared, and only then deleted, after a one-time
/// sealed backup of everything about to move. While the key is unavailable that plaintext stays exactly
/// where it is and is what reads return.
final class SecureStore {
    static let folderName = "Secure"
    static let valuesFolderName = "v1"
    static let quarantineFolderName = "quarantine"
    static let backupFolderName = "backup"
    static let backupFileName = "pre-migration.fbs"
    static let fileExtension = "fbs"
    static let folderMode: Int16 = 0o700
    static let fileMode: Int16 = 0o600
    static let accountScopeLength = 16
    /// The account the store opened last, so the next launch can open it before sign-in finishes. A
    /// user id, which the app already writes into plaintext key names; never a secret.
    static let lastAccountDefaultsKey = "kSecureStoreAccountId"
    /// How long to wait before asking the keychain again, attempt by attempt; the last repeats.
    static let retryDelays: [TimeInterval] = [5, 30, 120, 300]
    /// Posted on the main queue when an account's values become readable, so stores that cached what
    /// they read while the key was unavailable can reload.
    static let didBecomeReady = Notification.Name("io.focusbear.secureStoreDidBecomeReady")

    private enum PayloadField {
        static let key = "key"
        static let value = "value"
    }

    private enum HeldWrite {
        case set(Any)
        case remove
    }

    struct MigrationReport: Equatable {
        var migrated = 0
        var failed = 0
    }

    let rootDirectory: URL
    let bundleId: String
    let registry: SensitiveKeyRegistry
    let legacyDefaults: UserDefaults
    let legacyDomainName: String
    private let keyProvider: DataKeyProviding
    private let isEncryptionEnabled: Bool
    private let scheduleRetry: (TimeInterval, @escaping () -> Void) -> Void
    /// Folders outside this store holding data sealed with the account keys (project-note drafts): while
    /// anything is in them, sign-out keeps the key.
    private let externalSealedFolders: [URL]
    private let fileManager = FileManager.default

    private let lock = NSRecursiveLock()
    private var state: SecureStoreState
    private var accountId: String?
    private var key: SymmetricKey?
    private var keyId: String?
    private var cache: [String: Any] = [:]
    private var held: [String: HeldWrite] = [:]
    private var reportedHeldKeys = Set<String>()
    private var retryAttempt = 0
    private var isRetryScheduled = false
    private var diskPending: [String: Any?] = [:]
    private let writeQueue = DispatchQueue(label: "io.focusbear.secure-store.write", qos: .utility)
    private(set) var lastMigrationReport = MigrationReport()

    /// Tests: runs between sealing a migrated value and reading it back, to damage the file.
    var afterMigrationWrite: ((_ file: URL) -> Void)?

    init(rootDirectory: URL, keyProvider: DataKeyProviding, legacyDefaults: UserDefaults, legacyDomainName: String,
         registry: SensitiveKeyRegistry, bundleId: String, isEncryptionEnabled: Bool = true,
         disabledReason: String = "", externalSealedFolders: [URL] = [],
         scheduleRetry: ((TimeInterval, @escaping () -> Void) -> Void)? = nil) {
        self.rootDirectory = rootDirectory
        self.keyProvider = keyProvider
        self.legacyDefaults = legacyDefaults
        self.legacyDomainName = legacyDomainName
        self.registry = registry
        self.bundleId = bundleId
        self.isEncryptionEnabled = isEncryptionEnabled
        self.externalSealedFolders = externalSealedFolders
        self.scheduleRetry = scheduleRetry ?? { delay, work in
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay, execute: work)
        }
        state = isEncryptionEnabled ? .awaitingAccount : .disabled(reason: disabledReason)
    }

    // MARK: - Lifecycle

    var currentState: SecureStoreState {
        lock.lock(); defer { lock.unlock() }
        return state
    }

    var currentAccountId: String? {
        lock.lock(); defer { lock.unlock() }
        return accountId
    }

    /// Opens the account the previous launch used, so its values are readable before sign-in finishes.
    func resumeLastAccount() {
        guard isEncryptionEnabled, let last = legacyDefaults.string(forKey: Self.lastAccountDefaultsKey), !last.isEmpty else { return }
        activate(accountId: last)
    }

    /// Opens `accountId`'s values. Called when the signed-in user becomes known; a no-op when that
    /// account is already open. Switching accounts seals what the previous one had queued first.
    func activate(accountId newAccount: String) {
        guard isEncryptionEnabled, !newAccount.isEmpty else { return }
        lock.lock()
        if accountId == newAccount, state.isReady || isRetryScheduled {
            lock.unlock()
            return
        }
        if let previous = accountId, previous != newAccount {
            lock.unlock()
            flush()
            lock.lock()
            if !held.isEmpty {
                addLog(text: "[secure-store] account changed with \(held.count) value(s) still waiting for the previous account's key; they are dropped")
            }
            closeAccountLocked()
        }
        accountId = newAccount
        legacyDefaults.set(newAccount, forKey: Self.lastAccountDefaultsKey)
        lock.unlock()
        loadKeyAndOpen()
    }

    /// Asks the keychain again when the key was unavailable. Safe to call at any time.
    func retryKeyIfNeeded() {
        lock.lock()
        let shouldRetry: Bool
        if case .unavailable = state { shouldRetry = true } else { shouldRetry = false }
        lock.unlock()
        if shouldRetry { loadKeyAndOpen() }
    }

    private func loadKeyAndOpen() {
        lock.lock()
        guard let accountId, !state.isReady else {
            lock.unlock()
            return
        }
        let scope = Self.accountScope(for: accountId)
        switch keyProvider.loadKey(accountScope: scope) {
        case .unavailable(let reason):
            state = .unavailable(reason: reason)
            addLog(text: "[secure-store] data key unavailable (\(reason)): nothing is written in plaintext; "
                   + "\(held.count) change(s) wait in memory and the key is retried")
            addBreadcrumb("secure-store key unavailable: \(reason)")
            scheduleNextRetryLocked()
            lock.unlock()
        case .key(let dataKey):
            key = dataKey
            keyId = DataKeyFingerprint.id(of: dataKey)
            open(scope: scope)
            state = .ready(keyId: keyId ?? "")
            retryAttempt = 0
            addLog(text: "[secure-store] ready key=\(keyId ?? "") migrated=\(lastMigrationReport.migrated) "
                   + "failed=\(lastMigrationReport.failed)")
            lock.unlock()
            DispatchQueue.main.async { NotificationCenter.default.post(name: Self.didBecomeReady, object: self) }
        }
    }

    private func scheduleNextRetryLocked() {
        guard !isRetryScheduled else { return }
        isRetryScheduled = true
        let delay = Self.retryDelays[min(retryAttempt, Self.retryDelays.count - 1)]
        retryAttempt += 1
        scheduleRetry(delay) { [weak self] in
            guard let self else { return }
            self.lock.lock()
            self.isRetryScheduled = false
            self.lock.unlock()
            self.retryKeyIfNeeded()
        }
    }

    /// Sign-out. The account's server-backed caches are deleted (the next sign-in fetches them again).
    /// Local-only data and its key stay, readable only by this account, so nothing unsent is lost; once
    /// the account has no local-only data left its key is deleted too.
    func signOut() {
        guard isEncryptionEnabled else { return }
        flush()
        lock.lock()
        defer { lock.unlock() }
        legacyDefaults.removeObject(forKey: Self.lastAccountDefaultsKey)
        guard let accountId else { return }
        let scope = Self.accountScope(for: accountId)
        let entries = slotEntries(for: accountId)
        let heldLocalOnly = held.keys.filter { registry.entry(for: $0)?.durability == .localOnly }
        if !heldLocalOnly.isEmpty {
            addLog(text: "[secure-store] sign-out while the key is unavailable: \(heldLocalOnly.count) local-only change(s) could not be sealed")
        }
        for file in valueFiles(scope: scope) {
            let slot = file.deletingPathExtension().lastPathComponent
            if entries[slot]?.entry.durability == .serverBacked { try? fileManager.removeItem(at: file) }
        }
        SecureFileStore.removeServerBackedFiles(in: filesDirectory(scope: scope), registry: registry)
        if !hasLocalOnlyData(scope: scope) {
            try? fileManager.removeItem(at: accountDirectory(scope: scope))
            keyProvider.deleteKey(accountScope: scope)
        }
        closeAccountLocked()
        state = .awaitingAccount
    }

    /// Reset: every account's sealed values, files and backups, and the open account's key.
    func eraseAllData() {
        flush()
        lock.lock()
        defer { lock.unlock() }
        if isEncryptionEnabled {
            let accounts = [accountId, legacyDefaults.string(forKey: Self.lastAccountDefaultsKey)].compactMap { $0 }
            Set(accounts).forEach { keyProvider.deleteKey(accountScope: Self.accountScope(for: $0)) }
        }
        try? fileManager.removeItem(at: rootDirectory)
        legacyDefaults.removeObject(forKey: Self.lastAccountDefaultsKey)
        held.removeAll()
        closeAccountLocked()
        if isEncryptionEnabled { state = .awaitingAccount }
    }

    private func closeAccountLocked() {
        accountId = nil
        key = nil
        keyId = nil
        cache.removeAll()
        held.removeAll()
        reportedHeldKeys.removeAll()
        diskPending.removeAll()
        retryAttempt = 0
        isRetryScheduled = false
        if isEncryptionEnabled { state = .awaitingAccount }
    }

    // MARK: - Reading

    func object(forKey name: String) -> Any? {
        guard registry.contains(name) else { return legacyDefaults.object(forKey: name) }
        lock.lock()
        defer { lock.unlock() }
        switch state {
        case .disabled:
            return legacyDefaults.object(forKey: name)
        case .ready:
            // Plaintext is only left behind for a key whose migration failed (or another account's
            // suffixed key): it is still the user's value, so it must stay visible.
            return cache[name] ?? legacyDefaults.object(forKey: name)
        case .awaitingAccount, .unavailable:
            if let write = held[name] {
                if case .set(let value) = write { return value }
                return nil
            }
            // Never sealed data (no key): plaintext an older build left, not yet migrated, or nothing.
            return legacyDefaults.object(forKey: name)
        }
    }

    func data(forKey name: String) -> Data? { object(forKey: name) as? Data }
    func string(forKey name: String) -> String? { object(forKey: name) as? String }
    func dictionary(forKey name: String) -> [String: Any]? { object(forKey: name) as? [String: Any] }
    func array(forKey name: String) -> [Any]? { object(forKey: name) as? [Any] }
    func stringArray(forKey name: String) -> [String]? { object(forKey: name) as? [String] }
    func bool(forKey name: String) -> Bool { (object(forKey: name) as? NSNumber)?.boolValue ?? false }
    func integer(forKey name: String) -> Int { (object(forKey: name) as? NSNumber)?.intValue ?? 0 }
    func double(forKey name: String) -> Double { (object(forKey: name) as? NSNumber)?.doubleValue ?? 0 }

    // MARK: - Writing

    func set(_ value: Any?, forKey name: String) {
        guard let value else {
            removeValue(forKey: name)
            return
        }
        guard registry.contains(name) else {
            legacyDefaults.set(value, forKey: name)
            return
        }
        guard let value = Self.propertyListCopy(of: value) else {
            addLog(text: "[secure-store] refused a non-property-list value for \(name)")
            return
        }
        lock.lock()
        switch state {
        case .disabled:
            lock.unlock()
            legacyDefaults.set(value, forKey: name)
        case .ready:
            cache[name] = value
            enqueueDiskWriteLocked(name, value: value)
            lock.unlock()
        case .awaitingAccount, .unavailable:
            held[name] = .set(value)
            reportHeldLocked(name)
            lock.unlock()
        }
    }

    func removeValue(forKey name: String) {
        guard let entry = registry.entry(for: name) else {
            legacyDefaults.removeObject(forKey: name)
            return
        }
        lock.lock()
        defer { lock.unlock() }
        switch state {
        case .disabled:
            legacyDefaults.removeObject(forKey: name)
        case .ready:
            cache.removeValue(forKey: name)
            legacyDefaults.removeObject(forKey: name)
            enqueueDiskWriteLocked(name, value: nil)
        case .awaitingAccount, .unavailable:
            held[name] = .remove
            reportHeldLocked(name)
            guard entry.durability == .serverBacked else { return }
            // A server-backed copy can go now: deleting needs no key, and the server still has it.
            legacyDefaults.removeObject(forKey: name)
            if let accountId { try? fileManager.removeItem(at: valueFile(forKey: name, scope: Self.accountScope(for: accountId))) }
        }
    }

    /// Removes every stored key starting with `prefix`.
    func removeAll(matchingPrefix prefix: String) {
        lock.lock()
        let names = Set(cache.keys.filter { $0.hasPrefix(prefix) })
            .union(held.keys.filter { $0.hasPrefix(prefix) })
            .union((legacyDefaults.persistentDomain(forName: legacyDomainName) ?? [:]).keys.filter { $0.hasPrefix(prefix) })
            .filter(registry.contains)
        lock.unlock()
        names.forEach(removeValue(forKey:))
    }

    /// Waits for every queued write to reach disk.
    func flush() {
        writeQueue.sync {}
    }

    private static func merged(base: Any, incoming: Any) -> Any {
        let union = SecureMerge.union(base: base, incoming: incoming)
        return propertyListCopy(of: union) ?? union
    }

    /// The value as UserDefaults would hand it back: a property-list round trip, so numbers come back
    /// as NSNumber and callers' `as? Bool` / `as? Int` casts behave exactly as they did before.
    static func propertyListCopy(of value: Any) -> Any? {
        guard let data = try? PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, format: nil)
    }

    private func reportHeldLocked(_ name: String) {
        guard !reportedHeldKeys.contains(name) else { return }
        reportedHeldKeys.insert(name)
        addLog(text: "[secure-store] holding \(name) in memory until the data key is available (\(state.summary))")
    }

    private func enqueueDiskWriteLocked(_ name: String, value: Any?) {
        diskPending[name] = .some(value)
        writeQueue.async { [weak self] in self?.performDiskWrite(name) }
    }

    private func performDiskWrite(_ name: String) {
        lock.lock()
        guard let pending = diskPending.removeValue(forKey: name), let accountId, let sealing = sealingKey else {
            lock.unlock()
            return
        }
        let scope = Self.accountScope(for: accountId)
        lock.unlock()
        do {
            if let value = pending {
                try writeSealed(value, forKey: name, scope: scope, with: sealing)
            } else if fileManager.fileExists(atPath: valueFile(forKey: name, scope: scope).path) {
                try fileManager.removeItem(at: valueFile(forKey: name, scope: scope))
            }
            // The sealed value (or its removal) supersedes any plaintext an older build left.
            legacyDefaults.removeObject(forKey: name)
        } catch {
            addLog(text: "[secure-store] write failed for \(name): \(error)")
            addBreadcrumb("secure-store write failed")
        }
    }

    // MARK: - Opening an account

    /// Loads every sealed value, migrates plaintext, then applies the writes held while the key was
    /// unavailable. Runs under the lock, once per account per launch.
    private func open(scope: String) {
        let entries = slotEntries(for: accountId ?? "")
        let loaded = loadAll(scope: scope, entries: entries)
        cache = loaded
        lastMigrationReport = migrateLegacyPlaintext(scope: scope)
        applyHeldWrites(scope: scope, sealedKeys: Set(loaded.keys))
    }

    private func loadAll(scope: String, entries: [String: (name: String, entry: SensitiveKey)]) -> [String: Any] {
        var loaded: [String: Any] = [:]
        for file in valueFiles(scope: scope) {
            let slot = file.deletingPathExtension().lastPathComponent
            do {
                let (name, value) = try readSealed(file, slot: slot, scope: scope)
                loaded[name] = value
            } catch {
                discardUnreadable(file, durability: entries[slot]?.entry.durability, because: error, scope: scope)
            }
        }
        return loaded
    }

    /// A server-backed copy that won't open is deleted: the app fetches it again. Anything else is
    /// moved aside, never deleted — restoring the key it was sealed with makes it readable again.
    private func discardUnreadable(_ file: URL, durability: SensitiveKey.Durability?, because error: Error, scope: String) {
        if durability == .serverBacked {
            addLog(text: "[secure-store] dropped an unreadable server-backed cache (\(error)); it will be fetched again")
            try? fileManager.removeItem(at: file)
            return
        }
        addLog(text: "[secure-store] quarantined an unreadable local value (\(error))")
        addBreadcrumb("secure-store quarantined a value")
        do {
            let quarantine = accountDirectory(scope: scope).appendingPathComponent(Self.quarantineFolderName, isDirectory: true)
            try ensureDirectory(quarantine)
            let stamp = Int(Date().timeIntervalSince1970)
            try fileManager.moveItem(at: file, to: quarantine.appendingPathComponent("\(stamp)-\(file.lastPathComponent)"))
        } catch {
            addLog(text: "[secure-store] could not quarantine \(file.lastPathComponent): \(error)")
        }
    }

    /// Writes held while the key was unavailable. Local-only values merge into what was sealed (the
    /// writer never saw it); a removal is skipped when there was a sealed value the writer never saw.
    private func applyHeldWrites(scope: String, sealedKeys: Set<String>) {
        let writes = held
        held.removeAll()
        reportedHeldKeys.removeAll()
        for (name, write) in writes {
            let durability = registry.entry(for: name)?.durability ?? .localOnly
            let unseenSealed = durability == .localOnly && sealedKeys.contains(name)
            switch write {
            case .set(let value):
                let merged = unseenSealed ? cache[name].map { Self.merged(base: $0, incoming: value) } ?? value : value
                cache[name] = merged
                enqueueDiskWriteLocked(name, value: merged)
            case .remove:
                if unseenSealed {
                    addLog(text: "[secure-store] kept \(name): it was removed before its sealed value could be read")
                    continue
                }
                cache.removeValue(forKey: name)
                enqueueDiskWriteLocked(name, value: nil)
            }
        }
    }

    // MARK: - Migration

    /// Moves this account's registered plaintext out of UserDefaults. Plaintext is found only when a
    /// key was never migrated, a migration was interrupted, or an older build ran since; it wins over
    /// a sealed copy (server-backed) or merges into it (local-only). Each value is sealed, read back
    /// from disk and compared before its plaintext is deleted. A sealed backup of everything about to
    /// move is written (once) first and removed when nothing is left to migrate.
    @discardableResult
    func migrateLegacyPlaintext(scope: String) -> MigrationReport {
        var report = MigrationReport()
        let domain = legacyDefaults.persistentDomain(forName: legacyDomainName) ?? [:]
        let candidates = domain.keys.filter(isOwnedByOpenAccount).sorted()
        let backup = backupFile(scope: scope)
        guard !candidates.isEmpty else {
            try? fileManager.removeItem(at: backup)
            return report
        }
        for name in candidates {
            guard let plaintext = domain[name] else { continue }
            let durability = registry.entry(for: name)?.durability ?? .localOnly
            cache[name] = durability == .localOnly ? cache[name].map { Self.merged(base: $0, incoming: plaintext) } ?? plaintext : plaintext
        }
        do {
            try writeBackupIfNeeded(candidates.reduce(into: [String: Any]()) { $0[$1] = domain[$1] }, to: backup, scope: scope)
        } catch {
            // Without a backup nothing is migrated: the plaintext stays exactly where it is.
            addLog(text: "[secure-store] backup failed, migration skipped this launch: \(error)")
            report.failed = candidates.count
            return report
        }
        for name in candidates {
            guard let merged = cache[name] else { continue }
            do {
                try writeSealed(merged, forKey: name, scope: scope)
                afterMigrationWrite?(valueFile(forKey: name, scope: scope))
                let (_, readBack) = try readSealed(valueFile(forKey: name, scope: scope),
                                                   slot: Self.slot(forKey: name), scope: scope)
                guard (readBack as AnyObject).isEqual(merged) else { throw SecureEnvelopeError.authenticationFailed }
                legacyDefaults.removeObject(forKey: name)
                report.migrated += 1
            } catch {
                addLog(text: "[secure-store] migration kept the plaintext of \(name) for a retry: \(error)")
                report.failed += 1
            }
        }
        if report.failed == 0 { try? fileManager.removeItem(at: backup) }
        if report.migrated > 0 { addBreadcrumb("secure-store migrated \(report.migrated) value(s)") }
        return report
    }

    /// Keys the open account owns: unsuffixed registry keys, and suffixed ones carrying its user id.
    /// Another account's suffixed plaintext waits for that account.
    private func isOwnedByOpenAccount(_ name: String) -> Bool {
        guard let entry = registry.entry(for: name) else { return false }
        if case .userSuffixed = entry.match {
            return name == entry.baseName || name == entry.baseName + (accountId ?? "")
        }
        return true
    }

    private func writeBackupIfNeeded(_ values: [String: Any], to url: URL, scope: String) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        try ensureDirectory(url.deletingLastPathComponent())
        let slot = Self.backupFolderName
        try atomicWrite(try seal(try payload(name: slot, value: values), slot: slot, scope: scope), to: url)
        let (_, readBack) = try readSealed(url, slot: slot, scope: scope)
        guard (readBack as AnyObject).isEqual(values) else { throw SecureEnvelopeError.authenticationFailed }
    }

    /// The backup's contents, for support: a migration that went wrong can be inspected or replayed.
    func readBackup() -> [String: Any]? {
        lock.lock(); defer { lock.unlock() }
        guard state.isReady, let accountId else { return nil }
        let scope = Self.accountScope(for: accountId)
        return (try? readSealed(backupFile(scope: scope), slot: Self.backupFolderName, scope: scope))?.1 as? [String: Any]
    }

    // MARK: - Sealing

    /// The open account's key and its fingerprint, captured together so a write queued before an
    /// account switch is sealed with the key of the folder it lands in.
    struct SealingKey {
        let key: SymmetricKey
        let id: String
    }

    var sealingKey: SealingKey? {
        lock.lock(); defer { lock.unlock() }
        guard let key, let keyId else { return nil }
        return SealingKey(key: key, id: keyId)
    }

    func seal(_ plaintext: Data, slot: String, scope: String, with sealing: SealingKey? = nil) throws -> Data {
        guard let sealing = sealing ?? sealingKey else { throw SecureEnvelopeError.authenticationFailed }
        return try SecureEnvelope.seal(plaintext, keyId: sealing.id, key: sealing.key, bundleId: bundleId, slot: scope + "/" + slot)
    }

    func open(_ envelope: Data, slot: String, scope: String, with sealing: SealingKey? = nil) throws -> Data {
        guard let sealing = sealing ?? sealingKey else { throw SecureEnvelopeError.authenticationFailed }
        return try SecureEnvelope.open(envelope, keyId: sealing.id, key: sealing.key, bundleId: bundleId, slot: scope + "/" + slot)
    }

    private func payload(name: String, value: Any) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: [PayloadField.key: name, PayloadField.value: value],
                                           format: .binary, options: 0)
    }

    private func writeSealed(_ value: Any, forKey name: String, scope: String, with sealing: SealingKey? = nil) throws {
        let file = valueFile(forKey: name, scope: scope)
        try ensureDirectory(file.deletingLastPathComponent())
        let sealed = try seal(try payload(name: name, value: value), slot: Self.slot(forKey: name), scope: scope, with: sealing)
        try atomicWrite(sealed, to: file)
    }

    private func readSealed(_ file: URL, slot: String, scope: String) throws -> (String, Any) {
        let plaintext = try open(try Data(contentsOf: file), slot: slot, scope: scope)
        guard let payload = try PropertyListSerialization.propertyList(from: plaintext, format: nil) as? [String: Any],
              let name = payload[PayloadField.key] as? String, let value = payload[PayloadField.value] else {
            throw SecureEnvelopeError.authenticationFailed
        }
        return (name, value)
    }

    // MARK: - Paths

    static func accountScope(for accountId: String) -> String {
        String(slot(forKey: accountId).prefix(accountScopeLength))
    }

    static func slot(forKey name: String) -> String {
        SHA256.hash(data: Data(name.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func accountDirectory(scope: String) -> URL {
        rootDirectory.appendingPathComponent(scope, isDirectory: true)
    }

    func filesDirectory(scope: String) -> URL {
        accountDirectory(scope: scope).appendingPathComponent(SecureFileStore.folderName, isDirectory: true)
    }

    private func valuesDirectory(scope: String) -> URL {
        accountDirectory(scope: scope).appendingPathComponent(Self.valuesFolderName, isDirectory: true)
    }

    func valueFile(forKey name: String, scope: String) -> URL {
        valuesDirectory(scope: scope).appendingPathComponent(Self.slot(forKey: name)).appendingPathExtension(Self.fileExtension)
    }

    private func backupFile(scope: String) -> URL {
        accountDirectory(scope: scope).appendingPathComponent(Self.backupFolderName, isDirectory: true)
            .appendingPathComponent(Self.backupFileName)
    }

    private func valueFiles(scope: String) -> [URL] {
        ((try? fileManager.contentsOfDirectory(at: valuesDirectory(scope: scope), includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == Self.fileExtension }
    }

    /// Sealed file name → registry entry, for every key this account can have. Lets an unreadable file
    /// be classified (server-backed or local-only) without opening it.
    private func slotEntries(for accountId: String) -> [String: (name: String, entry: SensitiveKey)] {
        var entries: [String: (name: String, entry: SensitiveKey)] = [:]
        for entry in registry.keys {
            var names = [entry.baseName]
            if case .userSuffixed = entry.match, !accountId.isEmpty { names.append(entry.baseName + accountId) }
            names.forEach { entries[Self.slot(forKey: $0)] = ($0, entry) }
        }
        return entries
    }

    private func hasLocalOnlyData(scope: String) -> Bool {
        let quarantine = accountDirectory(scope: scope).appendingPathComponent(Self.quarantineFolderName, isDirectory: true)
        let quarantined = (try? fileManager.contentsOfDirectory(atPath: quarantine.path)) ?? []
        return !valueFiles(scope: scope).isEmpty || !quarantined.isEmpty
            || fileManager.fileExists(atPath: backupFile(scope: scope).path)
            || SecureFileStore.hasFiles(in: filesDirectory(scope: scope))
            || externalSealedFolders.contains { !((try? fileManager.contentsOfDirectory(atPath: $0.path)) ?? []).isEmpty }
    }

    func ensureDirectory(_ url: URL) throws {
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true,
                                        attributes: [.posixPermissions: Self.folderMode])
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true,
                                        attributes: [.posixPermissions: Self.folderMode])
    }

    /// Temp file in the same folder, fsync, rename: a crash leaves the old value or the new one.
    func atomicWrite(_ data: Data, to url: URL) throws {
        let temporary = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        guard fileManager.createFile(atPath: temporary.path, contents: nil,
                                     attributes: [.posixPermissions: Self.fileMode]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        do {
            let handle = try FileHandle(forWritingTo: temporary)
            defer { try? handle.close() }
            try handle.write(contentsOf: data)
            try handle.synchronize()
        } catch {
            try? fileManager.removeItem(at: temporary)
            throw error
        }
        guard rename(temporary.path, url.path) == 0 else {
            try? fileManager.removeItem(at: temporary)
            throw CocoaError(.fileWriteUnknown)
        }
    }

    private func addBreadcrumb(_ message: String) {
        let crumb = Breadcrumb(level: .info, category: "secure-store")
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }
}
