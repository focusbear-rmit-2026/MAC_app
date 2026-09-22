import Foundation
import CryptoKit
import Security

struct ManagedStoredState: Codable {
    var userId: String
    var deviceId: String
    var snapshot: ManagedPolicySnapshot
    var receivedAt: Date
    var lastSeenAt: Date
    var events: [ManagedViolationEvent]
    var quarantinedEvents: [ManagedViolationEvent]
    var droppedEventCount: Int
}

/// A keychain item carries an ACL bound to the signature of the binary that created it, and macOS
/// answers a mismatch with the "Focus Bear wants to use your confidential information" password
/// sheet. A rebuild, a re-signed build or an ad-hoc QA copy is a different binary by that measure,
/// so the sheet landed on the launch screen of an app a supervised student cannot unlock. Two rules
/// keep it away, and both matter: a mismatched item can be neither read, updated nor deleted, so
/// suppressing the sheet alone would leave supervision permanently wedged behind an unusable item.
enum ManagedKeychain {
    private static let lock = NSLock()

    /// Rule 1: one bucket per signature. The designated requirement is the expression macOS matches
    /// a keychain ACL against, so hashing it groups exactly the builds that can share an item —
    /// stable across rebuilds for a certificate-signed app, per-build for ad-hoc ones, which could
    /// never have shared it anyway. A new signature writes its own items instead of colliding.
    static let signatureScope: String = {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var requirement: SecRequirement?
        var text: CFString?
        guard SecCodeCopySelf(SecCSFlags(rawValue: 0), &code) == errSecSuccess, let code = code,
              SecCodeCopyStaticCode(code, SecCSFlags(rawValue: 0), &staticCode) == errSecSuccess, let staticCode = staticCode,
              SecCodeCopyDesignatedRequirement(staticCode, SecCSFlags(rawValue: 0), &requirement) == errSecSuccess,
              let requirement = requirement,
              SecRequirementCopyString(requirement, SecCSFlags(rawValue: 0), &text) == errSecSuccess,
              let expression = text as String? else { return "unsigned" }
        return String(ManagedResource.hash(expression).prefix(16))
    }()

    /// Rule 2: never prompt. `SecItem` has no per-call way to refuse the sheet on the file keychain —
    /// `kSecUseAuthenticationUIFail` is ignored there and still blocks (measured against a deliberate
    /// signature mismatch) — so the process-wide switch is the only lever. It is held across a single
    /// Security call and restored immediately, and a mismatch then reports `errSecAuthFailed` rather
    /// than stalling launch behind a sheet.
    static func withoutPrompting(_ body: () -> OSStatus) -> OSStatus {
        lock.lock()
        SecKeychainSetUserInteractionAllowed(false)
        defer {
            SecKeychainSetUserInteractionAllowed(true)
            lock.unlock()
        }
        return body()
    }
}

/// Only encrypted, authenticated policy/outbox data reaches disk. The key never leaves Keychain.
final class ManagedPolicyStore {
    private let service = "io.focusbear.managed-blocking.cache.v1"
    private let directory: URL
    private let defaults: UserDefaults
    private let identityKey = "managedBlockingLastIdentity.v1"

    init(directory: URL? = nil, defaults: UserDefaults = .standard) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FocusBear/ManagedBlocking", isDirectory: true)
        self.defaults = defaults
    }

    var lastIdentity: (userId: String, deviceId: String)? {
        if let data = try? readKeychain("last-identity"),
           let value = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let user = value["user"], let device = value["device"] { return (user, device) }
        guard let value = defaults.dictionary(forKey: identityKey),
              let user = value["user"] as? String, let device = value["device"] as? String else { return nil }
        return (user, device)
    }

    func isKnownManaged(userId: String, deviceId: String) -> Bool {
        if let data = try? readKeychain(marker(userId: userId, deviceId: deviceId)) { return data != Data([0]) }
        return defaults.bool(forKey: marker(userId: userId, deviceId: deviceId))
    }

    func rememberManagedIdentity(userId: String, deviceId: String) throws {
        defaults.set(["user": userId, "device": deviceId], forKey: identityKey)
        defaults.set(true, forKey: marker(userId: userId, deviceId: deviceId))
        try writeKeychain(marker(userId: userId, deviceId: deviceId), data: Data([1]))
        try writeKeychain("last-identity", data: JSONSerialization.data(withJSONObject: ["user": userId, "device": deviceId]))
    }

    func save(_ value: ManagedStoredState) throws {
        let identity = value.userId + ":" + value.deviceId
        // Persist enrollment before writing so interrupted/corrupt writes cannot become an unlock.
        defaults.set(["user": value.userId, "device": value.deviceId], forKey: identityKey)
        if value.snapshot.settingsLocked { defaults.set(true, forKey: marker(userId: value.userId, deviceId: value.deviceId)) }
        try writeKeychain("last-identity", data: JSONSerialization.data(withJSONObject: ["user": value.userId, "device": value.deviceId]))
        if value.snapshot.settingsLocked { try writeKeychain(marker(userId: value.userId, deviceId: value.deviceId), data: Data([1])) }
        let bytes = try ManagedJSON.encoder().encode(value)
        let sealed = try AES.GCM.seal(bytes, using: key(create: true), authenticating: Data(identity.utf8))
        guard let combined = sealed.combined else { throw ManagedStorageError.unavailable }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        let path = sealedPath(identity)
        try combined.write(to: path, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path.path)
        if !value.snapshot.settingsLocked {
            try writeKeychain(marker(userId: value.userId, deviceId: value.deviceId), data: Data([0]))
            defaults.set(false, forKey: marker(userId: value.userId, deviceId: value.deviceId))
        }
    }

    func load(userId: String, deviceId: String) throws -> ManagedStoredState? {
        let identity = userId + ":" + deviceId
        let path = sealedPath(identity)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        let data = try Data(contentsOf: path)
        guard let key = try? key(create: false) else { return discard(path) }
        let plaintext: Data
        do {
            let sealed = try AES.GCM.SealedBox(combined: data)
            plaintext = try AES.GCM.open(sealed, using: key, authenticating: Data(identity.utf8))
        } catch {
            // Unopenable ciphertext is either a cache sealed under a key this signature cannot reach
            // or a tampered file, and neither can be told apart from here. Dropping it costs a server
            // refresh, and the enrollment marker still holds supervision until that refresh lands.
            return discard(path)
        }
        // Plaintext this build cannot decode is a cache written by an older schema — `days_of_week`
        // went from integers to day codes, for instance. That is the same situation as ciphertext it
        // cannot open: the cache is unusable, not evidence of anything, and refetching costs one
        // request. Reporting it as a storage failure instead would put a supervised device into
        // recovery on the first launch after an update.
        guard let state = try? ManagedJSON.decoder().decode(ManagedStoredState.self, from: plaintext) else {
            return discard(path)
        }
        guard state.userId == userId, state.deviceId == deviceId else { throw ManagedStorageError.unavailable }
        return state
    }

    private func discard(_ path: URL) -> ManagedStoredState? {
        try? FileManager.default.removeItem(at: path)
        return nil
    }

    private func sealedPath(_ identity: String) -> URL {
        directory.appendingPathComponent(ManagedResource.hash(identity) + ".sealed")
    }

    private func marker(userId: String, deviceId: String) -> String {
        "managedBlockingEnrolled." + ManagedResource.hash(userId + ":" + deviceId)
    }

    /// Keychain accounts are per signature; see `ManagedKeychain.signatureScope`. UserDefaults keys
    /// stay unscoped so an enrollment marker survives a re-signed update.
    private func scoped(_ account: String) -> String {
        account + "." + ManagedKeychain.signatureScope
    }

    private func key(create: Bool) throws -> SymmetricKey {
        if let data = try? readKeychain("cache-encryption-key"), data.count == 32 { return SymmetricKey(data: data) }
        guard create else { throw ManagedStorageError.unavailable }
        let key = SymmetricKey(size: .bits256)
        try writeKeychain("cache-encryption-key", data: key.withUnsafeBytes { Data($0) })
        return key
    }

    private func readKeychain(_ account: String) throws -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: scoped(account),
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status = ManagedKeychain.withoutPrompting { SecItemCopyMatching(query as CFDictionary, &item) }
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw ManagedStorageError.unavailable }
        return data
    }

    private func writeKeychain(_ account: String, data: Data) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: scoped(account)]
        // `save()` rewrites the identity and the enrollment marker on every persist, but they only
        // actually change when the account, device or lock state does — so almost every one of those
        // writes stores the bytes that are already there. `SecItemUpdate` is not free: the Security
        // framework commits the whole keychain database, which `copyfile`s it, and on the main thread
        // that showed up as a multi-second beachball (Sentry FOCUS-BEAR-MACOS-1F4: `ManagedPolicyStore.save`
        // → `SecItemUpdate` → `DLTransaction::commit` → `copyfile` → `ffsctl`). Reading first costs a
        // lookup with no commit, so skipping the no-op write removes the disk cost from the common path
        // rather than moving it to another thread — which would have meant the caller learning about a
        // storage failure asynchronously, and `validateLease()` reads `isStorageHealthy` synchronously
        // to decide whether supervision can still be trusted.
        if let existing = try? readKeychain(account), existing == data { return }
        let status = ManagedKeychain.withoutPrompting {
            SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        }
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw ManagedStorageError.unavailable }
        var values = query
        values[kSecValueData as String] = data
        values[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let added = ManagedKeychain.withoutPrompting { SecItemAdd(values as CFDictionary, nil) }
        guard added == errSecSuccess else { throw ManagedStorageError.unavailable }
    }
}

enum ManagedStorageError: Error { case unavailable }
