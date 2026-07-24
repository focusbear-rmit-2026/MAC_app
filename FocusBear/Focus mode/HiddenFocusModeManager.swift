//
//  HiddenFocusModeManager.swift
//  FocusBear
//
//  Created by Jose Vega on 2026-04-30.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


//
//  HiddenFocusModeManager.swift
//  Focus Bear
//
//  Manages a persisted set of focus mode IDs that the user has hidden from pickers.
//  Hidden modes are NOT deleted — they remain in arrFocusType and on the server.
//  They are simply excluded from the start/pomodoro/scheduling pickers.
//

import Foundation

/// Main-thread-only helper for reading and writing the set of hidden focus mode IDs.
enum HiddenFocusModeManager {

    // MARK: - Read

    static var hiddenIDs: Set<String> {
        let arr = UserDefaults.standard.array(forKey: kUserdefaultsHiddenFocusModeIDs) as? [String] ?? []
        return Set(arr)
    }

    static func isHidden(id: String) -> Bool {
        return hiddenIDs.contains(id)
    }

    // MARK: - Write

    static func hide(id: String) {
        var ids = hiddenIDs
        ids.insert(id)
        persist(ids)
        addLog(text: "HiddenFocusModeManager: hid focus mode \(id)")
    }

    static func show(id: String) {
        var ids = hiddenIDs
        ids.remove(id)
        persist(ids)
        addLog(text: "HiddenFocusModeManager: showed focus mode \(id)")
    }

    @discardableResult
    static func toggle(id: String) -> Bool {
        if isHidden(id: id) {
            show(id: id)
            return false
        } else {
            hide(id: id)
            return true
        }
    }

    // MARK: - Filtering

    static func visibleFocusModes(from focusModes: [[String: Any]]) -> [[String: Any]] {
        let hidden = hiddenIDs
        return focusModes.filter { dic in
            guard let id = dic["id"] as? String else { return true }
            return !hidden.contains(id)
        }
    }

    // MARK: - Reconcile

    /// Drops hidden IDs that no longer correspond to a live focus mode — e.g. the mode was
    /// deleted (locally or on another device), leaving its ID orphaned in the hidden set.
    /// Persists only when something actually changed.
    /// - Parameter focusModes: the current focus-mode list (each dict keyed by "id").
    /// - Returns: true if any stale IDs were pruned.
    @discardableResult
    static func reconcile(against focusModes: [[String: Any]]) -> Bool {
        let liveIDs = Set(focusModes.compactMap { $0["id"] as? String })
        let current = hiddenIDs
        let alive = current.intersection(liveIDs)
        guard alive != current else { return false }
        persist(alive)
        addLog(text: "HiddenFocusModeManager: pruned \(current.count - alive.count) stale hidden id(s)")
        return true
    }

    // MARK: - Private

    private static func persist(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: kUserdefaultsHiddenFocusModeIDs)
    }
}