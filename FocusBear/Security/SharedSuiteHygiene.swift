//
//  SharedSuiteHygiene.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// Keeps secrets out of the suite shared with FBHelper, and sends the events FBHelper queued there.
enum SharedSuiteHygiene {
    /// Added to a queued helper event so analytics sees when it happened, not when it was sent.
    static let queuedAtMetadataKey = "helper_queued_at"

    /// Removes the token, email, name and leaderboard username older builds copied into the suite.
    static func removeLegacySecrets(from defaults: UserDefaults?) {
        guard let defaults else { return }
        let removed = LegacySharedSuiteSecrets.purge(from: defaults)
        if !removed.isEmpty {
            addLog(text: "[at-rest] removed legacy shared-suite keys: \(removed.joined(separator: ", "))")
        }
    }

    /// Sends the helper's queued events that belong to the signed-in user and drops the rest.
    static func sendQueuedHelperEvents(from defaults: UserDefaults?,
                                       signedInUserId: String,
                                       send: (_ event: String, _ metadata: [String: Any]) -> Void) {
        guard let defaults, !signedInUserId.isEmpty else { return }
        let pending = HelperEventQueue(defaults: defaults).drain()
        let ours = pending.filter { $0.userId == signedInUserId }
        for queued in ours {
            send(queued.event, metadataWithQueueTime(queued))
        }
        if !pending.isEmpty {
            addLog(text: "[at-rest] helper events: sent \(ours.count), dropped \(pending.count - ours.count)")
        }
    }

    private static func metadataWithQueueTime(_ queued: PendingHelperEvent) -> [String: Any] {
        var metadata = queued.metadata
        metadata[queuedAtMetadataKey] = ISO8601DateFormatter().string(from: queued.queuedAt)
        return metadata
    }
}
