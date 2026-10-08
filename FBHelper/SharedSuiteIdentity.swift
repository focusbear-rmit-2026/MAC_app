//
//  SharedSuiteIdentity.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// Keys older builds wrote to the shared suite that must not live there.
///
/// The shared suite is a plain plist in `~/Library/Preferences`, readable by any process running as
/// the user without a prompt. It held the Auth0 access token (so FBHelper could call `/events`) and
/// the account's email, name and leaderboard username. FBHelper no longer needs any of them, so the
/// main app removes them at launch and on logout.
enum LegacySharedSuiteSecrets {
    static let accessTokenKey = "kUserdefaultsSharedAccessToken"
    static let userEmailKey = "kUserdefaultsSharedUserEmail"
    static let userNameKey = "kUserdefaultsSharedUserName"
    static let leaderboardUsernameKey = "kUserdefaultsSharedLeaderboardUsername"

    static let allKeys = [accessTokenKey, userEmailKey, userNameKey, leaderboardUsernameKey]

    /// Returns the keys that were present, so the caller can log names (never values).
    @discardableResult
    static func purge(from defaults: UserDefaults) -> [String] {
        let present = allKeys.filter { defaults.object(forKey: $0) != nil }
        present.forEach { defaults.removeObject(forKey: $0) }
        return present
    }
}

/// Internal test accounts are recognised by their email address. FBHelper needs the answer, not the
/// address, so the main app stores only this flag in the shared suite.
enum InternalTestUser {
    static let emailMarker = "internaltest"

    static func isInternal(email: String) -> Bool {
        email.lowercased().contains(emailMarker)
    }

    static func record(email: String, in defaults: UserDefaults) {
        defaults.set(isInternal(email: email), forKey: kUserdefaultsSharedIsInternalTestUser)
    }

    static func isRecorded(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: kUserdefaultsSharedIsInternalTestUser)
    }

    static func clear(in defaults: UserDefaults) {
        defaults.removeObject(forKey: kUserdefaultsSharedIsInternalTestUser)
    }
}

/// An analytics event FBHelper raised, waiting for the main app to send it.
struct PendingHelperEvent {
    let event: String
    let metadata: [String: Any]
    let userId: String
    let queuedAt: Date
}

/// FBHelper's analytics events, queued in the shared suite for the main app to send.
///
/// FBHelper used to call `/events` itself with an access token the main app copied into the shared
/// suite. Now it has no credentials: it queues the event, and the main app sends it with its own
/// token the next time it signs in. Each entry carries the user id FBHelper saw, so the main app
/// drops events raised for someone else (for example the anonymous id during onboarding, which the
/// old token check also skipped).
struct HelperEventQueue {
    /// FBHelper can run for days while the main app is closed; keep only the newest events.
    static let maximumPendingEvents = 200

    private enum Field {
        static let event = "event"
        static let metadata = "metadata"
        static let userId = "userId"
        static let queuedAt = "queuedAt"
    }

    let defaults: UserDefaults

    func enqueue(event: String, metadata: [String: Any], userId: String, at date: Date = Date()) {
        let entry: [String: Any] = [
            Field.event: event,
            Field.metadata: Self.propertyListValues(of: metadata),
            Field.userId: userId,
            Field.queuedAt: date,
        ]
        let pending = storedEntries() + [entry]
        defaults.set(Array(pending.suffix(Self.maximumPendingEvents)), forKey: kUserdefaultsSharedPendingHelperEvents)
    }

    /// Removes and returns everything queued. Entries that cannot be read are dropped.
    func drain() -> [PendingHelperEvent] {
        let entries = storedEntries()
        defaults.removeObject(forKey: kUserdefaultsSharedPendingHelperEvents)
        return entries.compactMap(Self.decode)
    }

    private func storedEntries() -> [[String: Any]] {
        defaults.array(forKey: kUserdefaultsSharedPendingHelperEvents) as? [[String: Any]] ?? []
    }

    private static func decode(_ entry: [String: Any]) -> PendingHelperEvent? {
        guard let event = entry[Field.event] as? String,
              let userId = entry[Field.userId] as? String,
              let queuedAt = entry[Field.queuedAt] as? Date else { return nil }
        return PendingHelperEvent(event: event,
                                  metadata: entry[Field.metadata] as? [String: Any] ?? [:],
                                  userId: userId,
                                  queuedAt: queuedAt)
    }

    /// UserDefaults rejects a whole array if one value is not a property-list type, so anything
    /// else is stored as its description rather than losing the event.
    private static func propertyListValues(of metadata: [String: Any]) -> [String: Any] {
        metadata.mapValues { value in
            switch value {
            case is String, is NSNumber, is Date: return value
            default: return "\(value)"
            }
        }
    }
}
