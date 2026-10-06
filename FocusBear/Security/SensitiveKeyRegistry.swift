//
//  SensitiveKeyRegistry.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// A UserDefaults key whose value SecureStore keeps encrypted instead.
struct SensitiveKey: Equatable {
    /// Decides what a missing or unreadable key costs, and so how the store behaves without it.
    enum Durability: Equatable {
        /// A copy of what the server holds: unreadable means "fetch it again".
        case serverBacked
        /// Exists only on this Mac (unsent edits, local-only notes, queues): never overwritten or
        /// deleted without having been read.
        case localOnly
    }

    enum Match: Equatable {
        /// The key is exactly `baseName`.
        case exact
        /// `baseName` + a user id (the app appends it at sign-in), or `baseName` alone before that —
        /// except the listed keys, which merely share the prefix.
        case userSuffixed(excluding: [String])
    }

    let baseName: String
    let match: Match
    let durability: Durability

    /// `scripts/check-sensitive-defaults.sh` reads these two constructors to learn which constants must
    /// not reach `UserDefaults.standard`; keep every registry entry on one of them.
    static func exact(_ name: String, _ durability: Durability) -> SensitiveKey {
        SensitiveKey(baseName: name, match: .exact, durability: durability)
    }

    static func userSuffixed(_ name: String, _ durability: Durability, excluding: [String] = []) -> SensitiveKey {
        SensitiveKey(baseName: name, match: .userSuffixed(excluding: excluding), durability: durability)
    }

    func matches(_ key: String) -> Bool {
        switch match {
        case .exact:
            return key == baseName
        case .userSuffixed(let excluded):
            return key.hasPrefix(baseName) && !excluded.contains { key.hasPrefix($0) }
        }
    }
}

/// A file `SecureFileStore` keeps sealed, identified by its file name (the app keeps them in a
/// per-user folder under Application Support, so the same name recurs per account).
struct SensitiveFile: Equatable {
    let fileName: String
    let durability: SensitiveKey.Durability
}

/// Everything SecureStore encrypts. A key listed here is read and written through `SensitiveDefaults`,
/// migrated out of plaintext when the account opens, and refused by the lint when a call site uses
/// `UserDefaults.standard` for it directly. The PR description of #2863 carries the full inventory,
/// including what is deliberately left out and why.
struct SensitiveKeyRegistry {
    let keys: [SensitiveKey]
    let files: [SensitiveFile]

    init(keys: [SensitiveKey], files: [SensitiveFile] = []) {
        self.keys = keys
        self.files = files
    }

    func entry(for key: String) -> SensitiveKey? {
        keys.first { $0.matches(key) }
    }

    func contains(_ key: String) -> Bool {
        entry(for: key) != nil
    }

    func fileEntry(for fileName: String) -> SensitiveFile? {
        files.first { $0.fileName == fileName }
    }

    static let app = SensitiveKeyRegistry(
        keys: [
            // Server-backed: refilled by getSettings / getAllFocusModes / getUserLocalDeviceSettings.
            .exact(kUserdefaultsSelectedJson, .serverBacked),
            .userSuffixed(kUserdefaultsArrFocusTypesBase, .serverBacked),
            .userSuffixed(kUserdefaultsAllFocusModesTagsBase, .serverBacked),
            .userSuffixed(kUserdefaultsArrBlockedUrlsBase, .serverBacked),
            .userSuffixed(kUserdefaultsArrBlockedAppsBase, .serverBacked),
            .userSuffixed(kUserdefaultsArrAlwaysAllowedAppsBase, .serverBacked),
            .userSuffixed(kUserdefaultsLocalDeviceSettingsBase, .serverBacked),
            // Local-only: the Day Plan (from-scratch tasks never reach the server), calendar notes and
            // edits, AI decisions, Wi-Fi networks, brain dump, unsent habit notes, quit reasons, the
            // running accountability-buddy session.
            .exact(kUserdefaultsDayPlanTasksByDay, .localOnly),
            .exact(kUserdefaultsScheduleEventPrivateNotes, .localOnly),
            .exact(kUserdefaultsScheduleEventLocalOverrides, .localOnly),
            .exact(kUserdefaultsAiBlockingLogEntries, .localOnly),
            .exact(kUserdefaultsWiFiProfileMappings, .localOnly),
            .userSuffixed(kUserdefaultsFocusModeNotesBase, .localOnly),
            .userSuffixed(kUserdefaultsLastHabitSavedNotesBase, .localOnly),
            .userSuffixed(kUserdefaultsLastActivitySavedNotesBase, .localOnly),
            .userSuffixed(kUserdefaultsLastCustomRoutineHabitSavedNotesBase, .localOnly),
            .exact(kUserdefaultsLastSpecaialActivitySavedNotes, .localOnly),
            .userSuffixed(kUserDefaultsLastQuitReasonBase, .localOnly),
            .exact(kAccountabilityBuddySessionPersistKey, .localOnly),
        ],
        files: [
            // Deliberately NOT here: FocusBearCalendarBridge/dismissals-v1.json, which Late No More reads
            // as plaintext (identifiers and days only; testLateNoMoreDismissalSnapshotIsNeverSealed).
            // The offline-activities CSV is the queue of habit completions not yet uploaded.
            SensitiveFile(fileName: kOfflineActivitiesCsvFileName, durability: .localOnly),
            SensitiveFile(fileName: kStatsCsvFileName, durability: .localOnly),
            SensitiveFile(fileName: kFocusAlignmentScoreCsvFileName, durability: .localOnly),
            SensitiveFile(fileName: kFocusAIDecisionsCsvFileName, durability: .localOnly),
            SensitiveFile(fileName: kFocusProductivityStatsCsvFileName, durability: .localOnly),
            SensitiveFile(fileName: kUsageTimingsCsvFileName, durability: .localOnly),
            SensitiveFile(fileName: kRelevanceShadowLogFileName, durability: .localOnly),
            // Server-backed: refilled from the blocking-schedules API on the next fetch.
            SensitiveFile(fileName: kBlockingSchedulesCacheFileName, durability: .serverBacked),
            // Disposable, so treated like a server-backed cache: the 30-minute browsing history is
            // worthless once unreadable, and goes at sign-out rather than keeping the account's key.
            SensitiveFile(fileName: kBrowsingHistoryFileName, durability: .serverBacked),
        ])
}
