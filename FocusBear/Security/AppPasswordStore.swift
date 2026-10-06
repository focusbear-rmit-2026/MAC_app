//
//  AppPasswordStore.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import CommonCrypto
import Foundation
import Security

/// What a secret lookup found. `unavailable` — a locked keychain, a signature the item's ACL does not
/// name, any other Security error — is never treated as "there is no secret".
enum SecretLookup: Equatable {
    case found(String)
    case missing
    case unavailable
}

/// Where the app keeps a secret it must be able to read back (not just verify).
protocol SecretItemStoring {
    func read(account: String) -> SecretLookup
    /// True only when the value is stored and reads back identical.
    func write(_ value: String, account: String) -> Bool
    func delete(account: String)
}

/// The login keychain, without ever showing a prompt.
///
/// Accounts are scoped per code signature (`ManagedKeychain.signatureScope`): an ad-hoc rebuild or a
/// re-signed update cannot read an item another signature created, and asking would block on a
/// keychain sheet. A new signature therefore writes its own item instead of colliding with the old one.
struct KeychainSecretItemStore: SecretItemStoring {
    static let service = "io.focusbear.app-password.v1"

    func read(account: String) -> SecretLookup {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = ManagedKeychain.withoutPrompting { SecItemCopyMatching(query as CFDictionary, &item) }
        if status == errSecItemNotFound { return .missing }
        guard status == errSecSuccess, let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            return .unavailable
        }
        return .found(value)
    }

    func write(_ value: String, account: String) -> Bool {
        let data = Data(value.utf8)
        let query = baseQuery(account)
        var status = ManagedKeychain.withoutPrompting {
            SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        }
        if status == errSecItemNotFound {
            var values = query
            values[kSecValueData as String] = data
            values[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = ManagedKeychain.withoutPrompting { SecItemAdd(values as CFDictionary, nil) }
        }
        return status == errSecSuccess && read(account: account) == .found(value)
    }

    func delete(account: String) {
        _ = ManagedKeychain.withoutPrompting { SecItemDelete(baseQuery(account) as CFDictionary) }
    }

    private func baseQuery(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Self.service,
         kSecAttrAccount as String: account + "." + ManagedKeychain.signatureScope]
    }
}

/// Keeps secrets in memory: the logic-test host (which must never touch a person's keychain) and tests.
final class InMemorySecretItemStore: SecretItemStoring {
    static let shared = InMemorySecretItemStore()

    private let lock = NSLock()
    private var items: [String: String] = [:]
    /// Simulates a locked keychain: reads report `unavailable` and writes fail.
    var isAvailable = true

    func read(account: String) -> SecretLookup {
        lock.lock(); defer { lock.unlock() }
        guard isAvailable else { return .unavailable }
        return items[account].map(SecretLookup.found) ?? .missing
    }

    func write(_ value: String, account: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard isAvailable else { return false }
        items[account] = value
        return true
    }

    func delete(account: String) {
        lock.lock(); defer { lock.unlock() }
        items[account] = nil
    }
}

/// A salted PBKDF2 verifier for the app password, so checking it never needs the keychain.
enum AppPasswordVerifier {
    static let rounds = 120_000
    static let saltLength = 16
    static let hashLength = 32
    static let version = 1

    enum Field {
        static let salt = "salt"
        static let hash = "hash"
        static let rounds = "rounds"
        static let version = "version"
    }

    static func make(password: String, salt: Data = randomSalt(), rounds: Int = rounds) -> [String: Any] {
        [Field.salt: salt,
         Field.hash: derive(password: password, salt: salt, rounds: rounds),
         Field.rounds: rounds,
         Field.version: version]
    }

    static func matches(password: String, record: [String: Any]) -> Bool {
        guard let salt = record[Field.salt] as? Data,
              let expected = record[Field.hash] as? Data,
              let rounds = record[Field.rounds] as? Int, rounds > 0 else { return false }
        return constantTimeEqual(derive(password: password, salt: salt, rounds: rounds), expected)
    }

    static func randomSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: saltLength)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    private static func derive(password: String, salt: Data, rounds: Int) -> Data {
        let saltBytes = [UInt8](salt)
        var derived = [UInt8](repeating: 0, count: hashLength)
        _ = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, password.utf8.count,
                                 saltBytes, saltBytes.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                                 UInt32(rounds), &derived, derived.count)
        return Data(derived)
    }

    private static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

/// The settings/quit password, kept out of the preferences plist.
///
/// Older builds stored it base64-encoded (i.e. readable) in `UserDefaults` under `legacyKey`, and
/// it still has to reach the server in that form because settings sync sends it (`kAppPassword`) and
/// the other apps compare against it. So it lives in two places:
///
/// - a salted PBKDF2 **verifier** in `UserDefaults`: its presence means "a password is set", and
///   checking an entered password needs nothing else, so a locked or unreadable keychain can never lock
///   the user out;
/// - the encoded value in the **keychain**, read only to sync settings.
///
/// The legacy plaintext is deleted only after the keychain copy reads back. If the keychain is
/// unavailable it stays where it is and the next launch tries again — losing the password would turn
/// off the user's protection, and keeping it costs no more than before.
struct AppPasswordStore {
    static let verifierSuffix = ".verifier"

    let defaults: UserDefaults
    let secrets: SecretItemStoring
    /// The (user-scoped) key older builds stored the encoded password under; also the keychain account.
    let legacyKey: String

    var verifierKey: String { legacyKey + Self.verifierSuffix }

    /// Whether a password is set. Never touches the keychain.
    var isSet: Bool { legacyValue != nil || verifier != nil }

    /// The encoded value settings sync sends, or nil when none is set or it cannot be read right now
    /// (check `isSet` to tell those apart).
    var encodedValue: String? {
        if let legacyValue { return legacyValue }
        guard verifier != nil, case .found(let value) = secrets.read(account: legacyKey) else { return nil }
        return value
    }

    /// True when a password is set but its encoded value is unreadable, so a settings upload now would
    /// tell the server there is no password.
    var isEncodedValueUnavailable: Bool { isSet && encodedValue == nil }

    func matches(_ password: String) -> Bool {
        if let legacyValue { return legacyValue.fromBase64() == password }
        guard let verifier, AppPasswordVerifier.matches(password: password, record: verifier) else { return false }
        repairKeychainCopy(encoded: password.toBase64())
        return true
    }

    /// Stores a new encoded password. Returns false when the keychain refused it, in which case the
    /// value is kept in the legacy key so it is not lost.
    @discardableResult
    func set(encoded: String) -> Bool {
        guard let password = encoded.fromBase64() else {
            // Not something this build can verify: keep it exactly as older builds would.
            defaults.set(encoded, forKey: legacyKey)
            return false
        }
        defaults.set(AppPasswordVerifier.make(password: password), forKey: verifierKey)
        guard secrets.write(encoded, account: legacyKey) else {
            defaults.set(encoded, forKey: legacyKey)
            addLog(text: "[at-rest] app password: keychain unavailable, kept the legacy value for a later retry")
            return false
        }
        defaults.removeObject(forKey: legacyKey)
        return true
    }

    /// Applies the value settings sync delivered. Skips the (deliberately slow) verifier when the
    /// keychain already holds exactly this value.
    func adoptServerValue(_ encoded: String) {
        if legacyValue == nil, verifier != nil, secrets.read(account: legacyKey) == .found(encoded) { return }
        set(encoded: encoded)
    }

    func clear() {
        defaults.removeObject(forKey: legacyKey)
        defaults.removeObject(forKey: verifierKey)
        secrets.delete(account: legacyKey)
    }

    /// Moves a plaintext value older builds left into the verifier + keychain. Idempotent; a no-op once
    /// done, and a retry next launch if the keychain was unavailable.
    @discardableResult
    func migrateLegacyValue() -> Bool {
        guard let legacyValue else { return true }
        return set(encoded: legacyValue)
    }

    private var legacyValue: String? {
        guard let value = defaults.string(forKey: legacyKey), !value.isEmpty else { return nil }
        return value
    }

    private var verifier: [String: Any]? { defaults.dictionary(forKey: verifierKey) }

    /// A keychain copy written under another signature, or lost, is rebuilt from a password the user
    /// just proved they know.
    private func repairKeychainCopy(encoded: String) {
        guard secrets.read(account: legacyKey) == .missing else { return }
        _ = secrets.write(encoded, account: legacyKey)
    }
}
