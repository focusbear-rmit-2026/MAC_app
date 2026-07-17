//
//  ToolVisibilityStore.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

/// Identifies a TOOLS sidebar row the user can hide via its hover ✕ and bring back via the
/// TOOLS gear icon.
enum ToolID: String, CaseIterable {
    case focusMusic
    case brainDump
    case todoList
    case stats
    case tabAudit
    case focusButton
    case timeTracker
    case lateNoMore

    var displayName: String {
        // Config-driven i18n: reuse the same leftMenuVcInfo keys the sidebar rows use, falling back to
        // the English default if the key is absent. (stats uses its own "menuStats" key — the existing
        // "menuMotivation" reads "Motivation" in the server config, which wouldn't match the "Stats" row.)
        let key: String
        let fallback: String
        switch self {
        case .focusMusic:  key = "menuFocusMusic";  fallback = "Focus Music"
        case .brainDump:   key = "menuBrainDump";   fallback = "Brain Dump"
        case .todoList:    key = "menuTodoList";    fallback = "Todo List"
        case .stats:       key = "menuStats";       fallback = "Stats"
        case .tabAudit:    key = "menuTabAudit";    fallback = "Tab Audit"
        case .focusButton: key = "menuFocusButton"; fallback = "Focus Button"
        case .timeTracker: key = "menuTimeTracker"; fallback = "Time Tracker"
        case .lateNoMore:  key = "menuLateNoMore";  fallback = "Late No More"
        }
        return leftMenuConfigString(key) ?? fallback
    }
}

/// Reads a string from the `leftMenuVcInfo` config block (the config-driven i18n path used across the
/// left menu), returning nil if the block or key is absent so callers can fall back to an English default.
func leftMenuConfigString(_ key: String) -> String? {
    (configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary)?.value(forKey: key) as? String
}

/// Local (per-device) persistence for hidden TOOLS rows, mirroring CalendarManager's
/// dismissed-events add/remove/contains pattern.
enum ToolVisibilityStore {
    static func isHidden(_ id: ToolID) -> Bool {
        hiddenIds().contains(id.rawValue)
    }

    static func hide(_ id: ToolID) {
        var ids = hiddenIds()
        ids.insert(id.rawValue)
        save(ids)
    }

    static func restore(_ id: ToolID) {
        var ids = hiddenIds()
        ids.remove(id.rawValue)
        save(ids)
    }

    static func hiddenTools() -> [ToolID] {
        let ids = hiddenIds()
        return ToolID.allCases.filter { ids.contains($0.rawValue) }
    }

    private static func hiddenIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: kUserdefaultsHiddenToolIds) ?? [])
    }

    private static func save(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: kUserdefaultsHiddenToolIds)
    }
}
