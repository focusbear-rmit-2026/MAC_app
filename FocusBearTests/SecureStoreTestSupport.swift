import Foundation
@testable import Focus_Bear

/// A SecureStore wired to throwaway parts: a temporary folder, an isolated defaults suite and an
/// in-memory key provider. Nothing here can reach the real Application Support folder, UserDefaults or
/// keychain — app-hosted tests run on the developer's Mac, where those are the user's real ones.
final class SecureStoreFixture {
    static let bundleId = "io.focusbear.tests.bundle"
    static let serverKey = "test.server.habits"
    static let localKey = "test.local.dayPlan"
    static let suffixedLocalBase = "test.local.notes."
    static let serverFile = "server-cache.json"
    static let localCsv = "offline-queue.csv"
    static let accountA = "user-a"
    static let accountB = "user-b"

    static let registry = SensitiveKeyRegistry(
        keys: [
            .exact(serverKey, .serverBacked),
            .exact(localKey, .localOnly),
            .userSuffixed(suffixedLocalBase, .localOnly),
        ],
        files: [
            SensitiveFile(fileName: serverFile, durability: .serverBacked),
            SensitiveFile(fileName: localCsv, durability: .localOnly),
        ])

    let root: URL
    let isolated = IsolatedDefaults()
    var defaults: UserDefaults { isolated.defaults }
    let keys = InMemoryDataKeyProvider()
    /// Retries the store asked for; tests run them by hand instead of waiting.
    private(set) var scheduledRetries: [() -> Void] = []

    init() {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("secure-store-tests-" + UUID().uuidString, isDirectory: true)
    }

    var secureRoot: URL { root.appendingPathComponent(SecureStore.folderName, isDirectory: true) }

    func makeStore(isEncryptionEnabled: Bool = true, registry: SensitiveKeyRegistry = SecureStoreFixture.registry) -> SecureStore {
        SecureStore(rootDirectory: secureRoot, keyProvider: keys, legacyDefaults: defaults,
                    legacyDomainName: isolated.suiteName, registry: registry, bundleId: Self.bundleId,
                    isEncryptionEnabled: isEncryptionEnabled, disabledReason: "test",
                    scheduleRetry: { [weak self] _, work in self?.scheduledRetries.append(work) })
    }

    func runScheduledRetries() {
        let retries = scheduledRetries
        scheduledRetries.removeAll()
        retries.forEach { $0() }
    }

    /// A plaintext file where the app's CSVs used to live.
    func plaintextURL(_ name: String) -> URL {
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent(name)
    }

    func destroy() {
        isolated.destroy()
        try? FileManager.default.removeItem(at: root)
    }

    /// Every byte the store wrote, for "no plaintext on disk" checks.
    func allBytesOnDisk() -> Data {
        let enumerator = FileManager.default.enumerator(at: secureRoot, includingPropertiesForKeys: nil)
        var bytes = Data()
        while let url = enumerator?.nextObject() as? URL {
            bytes += (try? Data(contentsOf: url)) ?? Data()
        }
        return bytes
    }

    func diskContains(_ text: String) -> Bool {
        allBytesOnDisk().range(of: Data(text.utf8)) != nil
    }

    func sealedValueFiles(account: String) -> [URL] {
        let folder = secureRoot.appendingPathComponent(SecureStore.accountScope(for: account))
            .appendingPathComponent(SecureStore.valuesFolderName)
        return ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == SecureStore.fileExtension }
    }

    func quarantinedFiles(account: String) -> [URL] {
        let folder = secureRoot.appendingPathComponent(SecureStore.accountScope(for: account))
            .appendingPathComponent(SecureStore.quarantineFolderName)
        return (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
    }

    func backupExists(account: String) -> Bool {
        FileManager.default.fileExists(atPath: secureRoot.appendingPathComponent(SecureStore.accountScope(for: account))
            .appendingPathComponent(SecureStore.backupFolderName).appendingPathComponent(SecureStore.backupFileName).path)
    }

    func dayPlanJSON(_ tasksByDay: [String: [[String: Any]]]) -> Data {
        try! JSONSerialization.data(withJSONObject: tasksByDay, options: [.sortedKeys])
    }

    func decodeDayPlan(_ data: Data?) -> [String: [[String: Any]]] {
        guard let data, let object = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] else { return [:] }
        return object
    }
}
