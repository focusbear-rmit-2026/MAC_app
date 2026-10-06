//
//  SensitiveDefaults.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

extension SecureStore {
    static let defaultBundleId = LogicTestHost.SHIPPING_BUNDLE_IDENTIFIER
    static let logicTestHostSuitePrefix = "io.focusbear.tests.secure-store."
    static let adHocDisabledReason = "ad-hoc signed build"
    /// The logic test host has no signed-in user; its throwaway store opens this account so registered
    /// keys behave as they do in the app.
    static let logicTestHostAccountId = "logic-test-host"

    /// The app's store, opened on the previous launch's account the first time anything touches it.
    ///
    /// Under the logic test host it uses an in-memory key, a temporary folder and a throwaway defaults
    /// suite, so no test can reach the real Application Support folder, the real UserDefaults or the
    /// keychain. UI-test and other ad-hoc builds keep today's plaintext storage (`.disabled`): their key
    /// would change with every build.
    static let shared: SecureStore = {
        let store = makeShared()
        if LogicTestHost.isEnabled {
            store.activate(accountId: logicTestHostAccountId)
        } else {
            store.resumeLastAccount()
        }
        addLog(text: "[secure-store] \(store.currentState.summary)")
        return store
    }()

    private static func makeShared() -> SecureStore {
        let bundleId = Bundle.main.bundleIdentifier ?? defaultBundleId
        if LogicTestHost.isEnabled {
            let suiteName = logicTestHostSuitePrefix + UUID().uuidString
            return SecureStore(
                rootDirectory: FileManager.default.temporaryDirectory
                    .appendingPathComponent(suiteName, isDirectory: true)
                    .appendingPathComponent(folderName, isDirectory: true),
                keyProvider: InMemoryDataKeyProvider(),
                legacyDefaults: UserDefaults(suiteName: suiteName) ?? UserDefaults(),
                legacyDomainName: suiteName,
                registry: .app,
                bundleId: bundleId)
        }
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return SecureStore(rootDirectory: applicationSupport
                               .appendingPathComponent(bundleId, isDirectory: true)
                               .appendingPathComponent(folderName, isDirectory: true),
                           keyProvider: KeychainDataKeyProvider(bundleId: bundleId),
                           legacyDefaults: .standard,
                           legacyDomainName: bundleId,
                           registry: .app,
                           bundleId: bundleId,
                           isEncryptionEnabled: !CodeSigningInfo.isAdHoc,
                           disabledReason: adHocDisabledReason,
                           externalSealedFolders: [ProjectNoteDraftStore.defaultDirectory])
    }
}

/// Drop-in for the `UserDefaults.standard` calls the app makes for keys that hold personal data.
///
/// A key listed in `SensitiveKeyRegistry` is read from and written to `SecureStore`; any other key goes
/// straight to `UserDefaults.standard`. Moving a key is a one-word edit per call site —
/// `UserDefaults.standard.set(v, forKey: k)` → `SensitiveDefaults.set(v, forKey: k)` — and
/// `scripts/check-sensitive-defaults.sh` fails the build when a registered key is still written the old way.
enum SensitiveDefaults {
    static var store: SecureStore { SecureStore.shared }

    static func object(forKey key: String) -> Any? { store.object(forKey: key) }
    /// `UserDefaults.value(forKey:)` is KVC, which for a defaults key means `object(forKey:)`.
    static func value(forKey key: String) -> Any? { store.object(forKey: key) }
    static func string(forKey key: String) -> String? { store.string(forKey: key) }
    static func data(forKey key: String) -> Data? { store.data(forKey: key) }
    static func dictionary(forKey key: String) -> [String: Any]? { store.dictionary(forKey: key) }
    static func array(forKey key: String) -> [Any]? { store.array(forKey: key) }
    static func stringArray(forKey key: String) -> [String]? { store.stringArray(forKey: key) }
    static func bool(forKey key: String) -> Bool { store.bool(forKey: key) }
    static func integer(forKey key: String) -> Int { store.integer(forKey: key) }
    static func double(forKey key: String) -> Double { store.double(forKey: key) }

    static func set(_ value: Any?, forKey key: String) { store.set(value, forKey: key) }
    static func setValue(_ value: Any?, forKey key: String) { store.set(value, forKey: key) }
    static func removeObject(forKey key: String) { store.removeValue(forKey: key) }
}

/// The app's sealed files (CSVs, JSON logs).
enum SecureFiles {
    static let shared = SecureFileStore(store: .shared)
}
