import Foundation

/// Snapshot before an asynchronous edit. Credential refresh must not transfer an old user's write to
/// the newly signed-in account, and a newly received school lock must stop a pending personal edit.
struct LegacySettingsMutationContext: Equatable {
    let userId: String
    let deviceId: String
    let sessionToken: UUID

    func permits(userId: String?, deviceId: String, sessionToken: UUID, isLocked: Bool) -> Bool {
        !self.userId.isEmpty && !self.deviceId.isEmpty && !isLocked
            && userId == self.userId && deviceId == self.deviceId && sessionToken == self.sessionToken
    }

    func permitsCredential(userId: String?) -> Bool { !self.userId.isEmpty && userId == self.userId }
}

extension LegacySettingsMutationContext {
    static func captureCurrent() -> Self? {
        let runtime = ManagedBlockingRuntime.shared
        guard !runtime.isSettingsLocked, let userId = appdelegate?.user?.userId,
              !userId.isEmpty, !currentDeviceId.isEmpty else { return nil }
        return Self(userId: userId, deviceId: currentDeviceId, sessionToken: runtime.sessionToken)
    }

    var isCurrent: Bool {
        permits(userId: appdelegate?.user?.userId, deviceId: currentDeviceId,
                sessionToken: ManagedBlockingRuntime.shared.sessionToken,
                isLocked: ManagedBlockingRuntime.shared.isSettingsLocked)
    }
}

/// Resolve the confirmed ID again; a table index can now refer to a different mode after server sync.
enum LegacyFocusModeDeletion {
    static func index(for id: String, modes: [[String: Any]], scheduledModeIDs: Set<String>,
                      hardcoreIsRunning: Bool, configuredHardcoreModeName: String?) -> Int? {
        guard !id.isEmpty, !hardcoreIsRunning, !scheduledModeIDs.contains(id) else { return nil }
        let matches = modes.indices.filter { modes[$0]["id"] as? String == id }
        guard matches.count == 1, let index = matches.first else { return nil }
        let mode = modes[index]
        guard !["isDefault", "isMeetings", "isLockedFocus", "isOn", "isPaused"].contains(where: { mode[$0] as? Bool == true }) else { return nil }
        if let configured = configuredHardcoreModeName, mode["name"] as? String == configured { return nil }
        return index
    }
}
