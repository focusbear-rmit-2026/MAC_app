//
//  ToolsSectionPreference.swift
//  Focus Bear
//
//  Whether the sidebar's TOOLS section is expanded, remembered across launches.
//

import Foundation

/// Remembers whether the user last left TOOLS open or closed.
///
/// #2352 made TOOLS start collapsed on every launch and deliberately did not persist it. That is
/// the right DEFAULT — a new account should not meet a wall of tool rows — but it was applied as an
/// override, so a user who opened TOOLS found it shut again at the next launch, and after every
/// restart during a working day ("tools keeps collapsing", report 2026-09-21_16-00-46).
///
/// So: collapsed until the user says otherwise, and their answer is kept. Nobody who has never
/// touched it sees any change.
///
/// Only a deliberate click is recorded. TOOLS also auto-expands when a tool inside it becomes the
/// selection, and persisting that would undo a collapse the user had just asked for — see
/// `accordionBox.onUserToggled`.
enum ToolsSectionPreference {

    /// The account segment used when nobody is signed in. A literal rather than the empty string so
    /// a pre-login preference cannot be inherited by the first account to sign in on this Mac — the
    /// ownerless-key hazard `SettingsManager.isUserScopedKey` exists for, which had already cost a
    /// user their full-screen setting (report 2026-09-21_07-45-33).
    static let signedOutAccount = "signed-out"
    private static let keyPrefix = "sidebarToolsSectionExpanded."

    /// Rebuilt from the CURRENT user on every access rather than captured once: the app restores the
    /// signed-in user asynchronously after launch, so a key built at init time is the signed-out one
    /// for everybody.
    static func key(forUserId userId: String?) -> String {
        let account = userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return keyPrefix + (account.isEmpty ? signedOutAccount : account)
    }

    /// Collapsed unless this account has chosen otherwise — `object(forKey:)`, not `bool(forKey:)`,
    /// so "never chosen" stays distinguishable from "chose collapsed".
    static func isExpanded(userId: String?, defaults: UserDefaults = .standard) -> Bool {
        guard let stored = defaults.object(forKey: key(forUserId: userId)) as? Bool else { return false }
        return stored
    }

    static func hasChosen(userId: String?, defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: key(forUserId: userId)) != nil
    }

    static func setExpanded(_ expanded: Bool, userId: String?, defaults: UserDefaults = .standard) {
        defaults.set(expanded, forKey: key(forUserId: userId))
    }

    static var currentUserId: String? { appdelegate?.user?.userId }

    static var isExpandedForCurrentUser: Bool { isExpanded(userId: currentUserId) }

    static func recordUserChoice(_ expanded: Bool) { setExpanded(expanded, userId: currentUserId) }
}
