//
//  DataKeyProvider.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import CryptoKit
import Foundation
import Security

/// The data key `SecureStore` seals one account's values with, or why this launch can't have it.
enum DataKeyLookup {
    case key(SymmetricKey)
    /// The item exists but can't be read without a prompt (keychain locked, another signature), or the
    /// keychain answered with something unexpected. Never "there is no key": a new key is only ever
    /// created when the keychain says the item does not exist.
    case unavailable(reason: String)
}

protocol DataKeyProviding {
    func loadKey(accountScope: String) -> DataKeyLookup
    /// Forgets the account's key (logout with nothing local-only left, reset).
    func deleteKey(accountScope: String)
}

/// A short, stable identity for a data key, stored in every envelope so ciphertext sealed with another
/// key is recognised as such. Derived (HKDF), so it reveals nothing about the key.
enum DataKeyFingerprint {
    private static let info = Data("fb.securestore.key-id.v1".utf8)
    private static let length = 8

    static func id(of key: SymmetricKey) -> String {
        let derived = HKDF<SHA256>.deriveKey(inputKeyMaterial: key, info: info, outputByteCount: length)
        return derived.withUnsafeBytes { Data($0) }.map { String(format: "%02x", $0) }.joined()
    }
}

/// The keychain calls `KeychainDataKeyProvider` makes, so tests can script every status code without
/// touching a real keychain.
protocol KeychainItemBackend {
    func read(service: String, account: String) -> (status: OSStatus, data: Data?)
    func add(service: String, account: String, data: Data) -> OSStatus
    func delete(service: String, account: String) -> OSStatus
}

/// The login (file) keychain, without ever showing a prompt (`ManagedKeychain.withoutPrompting`).
///
/// The data-protection keychain is deliberately not used: it needs the restricted
/// `keychain-access-groups` entitlement, and the signed Release build that tried it for the Auth0
/// tokens stored items it then could not read back (#2588). A file-keychain item created by a
/// certificate-signed build carries that build's designated requirement in its ACL, so updates read it
/// without a prompt.
struct LoginKeychainItemBackend: KeychainItemBackend {
    func read(service: String, account: String) -> (status: OSStatus, data: Data?) {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = ManagedKeychain.withoutPrompting { SecItemCopyMatching(query as CFDictionary, &item) }
        return (status, item as? Data)
    }

    func add(service: String, account: String, data: Data) -> OSStatus {
        var values = baseQuery(service: service, account: account)
        values[kSecAttrLabel as String] = KeychainDataKeyProvider.label
        values[kSecValueData as String] = data
        values[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        values[kSecAttrSynchronizable as String] = false
        return ManagedKeychain.withoutPrompting { SecItemAdd(values as CFDictionary, nil) }
    }

    func delete(service: String, account: String) -> OSStatus {
        ManagedKeychain.withoutPrompting { SecItemDelete(baseQuery(service: service, account: account) as CFDictionary) }
    }

    private func baseQuery(service: String, account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }
}

/// Loads an account's data key from the keychain, creating it the first time.
///
/// The keychain account is `dek.v1.<account scope>.<signature scope>`: one key per Focus Bear account,
/// and one per code signature, because an item another signature created can be neither read, updated
/// nor deleted (see `ManagedKeychain`). Never prompts, never replaces a key it can't read, and never
/// adds a second item while one exists: a duplicate-item error means another launch got there first,
/// so it reads again.
struct KeychainDataKeyProvider: DataKeyProviding {
    static let keyLength = 32
    static let label = "Focus Bear data key"
    static let accountPrefix = "dek.v1."
    static let serviceSuffix = ".data-key"

    let service: String
    let signatureScope: String
    let backend: KeychainItemBackend

    init(bundleId: String, signatureScope: String = ManagedKeychain.signatureScope,
         backend: KeychainItemBackend = LoginKeychainItemBackend()) {
        service = bundleId + Self.serviceSuffix
        self.signatureScope = signatureScope
        self.backend = backend
    }

    func keychainAccount(for accountScope: String) -> String {
        Self.accountPrefix + accountScope + "." + signatureScope
    }

    func loadKey(accountScope: String) -> DataKeyLookup {
        let account = keychainAccount(for: accountScope)
        let read = backend.read(service: service, account: account)
        switch read.status {
        case errSecSuccess:
            return Self.key(from: read.data).map(DataKeyLookup.key) ?? .unavailable(reason: "key item has the wrong length")
        case errSecItemNotFound:
            return create(account: account)
        default:
            return .unavailable(reason: Self.describe(read.status))
        }
    }

    func deleteKey(accountScope: String) {
        let status = backend.delete(service: service, account: keychainAccount(for: accountScope))
        if status != errSecSuccess && status != errSecItemNotFound {
            addLog(text: "[secure-store] could not delete the data key: \(Self.describe(status))")
        }
    }

    private func create(account: String) -> DataKeyLookup {
        let key = SymmetricKey(size: .bits256)
        let status = backend.add(service: service, account: account, data: key.withUnsafeBytes { Data($0) })
        switch status {
        case errSecSuccess, errSecDuplicateItem:
            // Read back either way: only a key that round-trips may seal anything.
            let reread = backend.read(service: service, account: account)
            guard reread.status == errSecSuccess, let stored = Self.key(from: reread.data) else {
                return .unavailable(reason: "new key did not read back (\(Self.describe(reread.status)))")
            }
            return .key(stored)
        default:
            return .unavailable(reason: Self.describe(status))
        }
    }

    private static func key(from data: Data?) -> SymmetricKey? {
        guard let data, data.count == keyLength else { return nil }
        return SymmetricKey(data: data)
    }

    static func describe(_ status: OSStatus) -> String {
        switch status {
        case errSecInteractionNotAllowed: return "keychain locked"
        case errSecAuthFailed: return "key belongs to another signature"
        default: return "keychain status \(status)"
        }
    }
}

/// Keys that live only as long as the process: unit tests and the logic test host, which must never
/// touch a person's keychain.
final class InMemoryDataKeyProvider: DataKeyProviding {
    private let lock = NSLock()
    private var keys: [String: SymmetricKey] = [:]
    private var available = true
    private(set) var loadCount = 0

    /// Simulates a locked keychain (or another signature's item): lookups report `unavailable`.
    var isAvailable: Bool {
        get { lock.lock(); defer { lock.unlock() }; return available }
        set { lock.lock(); available = newValue; lock.unlock() }
    }

    func loadKey(accountScope: String) -> DataKeyLookup {
        lock.lock(); defer { lock.unlock() }
        loadCount += 1
        guard available else { return .unavailable(reason: "keychain locked") }
        if let key = keys[accountScope] { return .key(key) }
        let key = SymmetricKey(size: .bits256)
        keys[accountScope] = key
        return .key(key)
    }

    func deleteKey(accountScope: String) {
        lock.lock(); defer { lock.unlock() }
        keys[accountScope] = nil
    }

    /// Simulates the keychain item being lost and recreated: the next lookup makes a different key.
    func replaceKey(accountScope: String) {
        lock.lock(); defer { lock.unlock() }
        keys[accountScope] = SymmetricKey(size: .bits256)
    }

    func hasKey(accountScope: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return keys[accountScope] != nil
    }
}

/// Whether this binary may keep long-lived keychain items at all.
enum CodeSigningInfo {
    /// Ad-hoc builds (the Debug default without `Config/Local.xcconfig`, CI test builds) have a bare
    /// cdhash as their designated requirement, so every rebuild is a new app to the keychain: a data key
    /// they created would be unreadable to the next build, and local-only data sealed with it lost.
    static let isAdHoc: Bool = {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var information: CFDictionary?
        guard SecCodeCopySelf(SecCSFlags(rawValue: 0), &code) == errSecSuccess, let code,
              SecCodeCopyStaticCode(code, SecCSFlags(rawValue: 0), &staticCode) == errSecSuccess, let staticCode,
              SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
              let info = information as? [String: Any] else { return true }
        let flags = (info[kSecCodeInfoFlags as String] as? NSNumber)?.uint32Value ?? 0
        let team = info[kSecCodeInfoTeamIdentifier as String] as? String
        return flags & SecCodeSignatureFlags.adhoc.rawValue != 0 || (team ?? "").isEmpty
    }()
}
