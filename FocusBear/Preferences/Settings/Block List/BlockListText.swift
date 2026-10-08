//
//  BlockListText.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// All user-facing strings for the block-list screen, read from the `blockListViewInfo` config
/// block (with English fallbacks) so they translate like the rest of the app.
enum BlockListText {
    private static var info: NSDictionary? { configjson.value(forKey: "blockListViewInfo") as? NSDictionary }

    static func t(_ key: String, _ fallback: String) -> String {
        // Treat an EMPTY config value like a missing one and use the English fallback — a blank string
        // in the (downloaded) config must never render as an empty label or button.
        let value = info?.value(forKey: key) as? String
        return (value?.isEmpty == false) ? value! : fallback
    }

    // Left rail
    static var myBlockLists: String { t("myBlockLists", "MY BLOCKLISTS") }
    static var createNewBlockList: String { t("createNewBlockList", "Create New Block") }
    /// "<COUNT> blocks" — the badge on each block-list card. Rendered upper-cased, per the design.
    static var blocksCount: String { t("blocksCount", "<COUNT> blocks") }
    static var oneBlockCount: String { t("oneBlockCount", "1 block") }

    // Right panel
    static var searchPlaceholder: String { t("searchPlaceholder", "Add a new URL to this blocklist") }
    /// "Add a new URL to <CATEGORY>" — shown when a category filter is active.
    static var searchPlaceholderForCategory: String {
        t("searchPlaceholderForCategory", "Add a new URL to <CATEGORY>")
    }
    static var addEntry: String { t("addEntry", "Add") }
    static var editBlockList: String { t("editBlockList", "Edit this block list") }
    static var filterAll: String { t("filterAll", "All") }
    static var back: String { t("back", "Back") }
    // #2571 (NEW-A / 11): the search field and the separate add-entry controls at the bottom.
    static var searchEntries: String { t("searchEntries", "Search URLs and apps") }
    static var addUrlPlaceholder: String { t("addUrlPlaceholder", "Add a new URL") }
    static var addUrl: String { t("addUrl", "Add URL") }
    static var addApp: String { t("addApp", "Add App") }
    // Search-driven quick-add cards (eyebrow labels + the manual-app fallback).
    static var addUrlEyebrow: String { t("addUrlEyebrow", "ADD URL") }
    static var addKeywordEyebrow: String { t("addKeywordEyebrow", "ADD KEYWORD") }
    static var addAppEyebrow: String { t("addAppEyebrow", "ADD APP") }
    static var addAppManuallyEyebrow: String { t("addAppManuallyEyebrow", "LOOKING FOR SOMETHING ELSE?") }
    static var addAppManually: String { t("addAppManually", "Add app manually") }

    // Per-mode actions shown on the selected card (#2571 14).
    static var deleteBlockList: String { t("deleteBlockList", "Delete") }
    static var duplicateBlockList: String { t("duplicateBlockList", "Duplicate") }
    static var hideBlockList: String { t("hideBlockList", "Hide from pickers") }
    static var showBlockList: String { t("showBlockList", "Show in pickers") }
    static var revealHiddenModes: String { t("revealHiddenModes", "Reveal hidden focus modes") }
    /// Appended to a hidden mode's name while reveal mode is on. Includes its own leading space.
    static var hiddenSuffix: String { t("hiddenSuffix", " (Hidden)") }
    static var renameBlockList: String { t("renameBlockList", "Rename this block list") }
    static var changeColor: String { t("changeColor", "Change colour") }
    static var duplicateName: String {
        t("duplicateName", "A block list with this name already exists.")
    }

    // Table
    static var columnName: String { t("columnName", "NAME") }
    static var columnCategory: String { t("columnCategory", "CATEGORY") }
    static var columnType: String { t("columnType", "TYPE") }
    static var typeWebsite: String { t("typeWebsite", "Website") }
    static var typeApp: String { t("typeApp", "App") }
    static var removeEntry: String { t("removeEntry", "Remove") }

    // Suggestions
    /// "COMMONLY BLOCKED IN <CATEGORY>:" — heading above the one-tap suggestion chips.
    static var commonlyBlockedIn: String { t("commonlyBlockedIn", "COMMONLY BLOCKED IN <CATEGORY>:") }

    // Empty / error states
    static var noBlockListSelected: String {
        t("noBlockListSelected", "Select a block list on the left, or create a new one.")
    }
    static var noEntries: String { t("noEntries", "Nothing is blocked in this list yet.") }
    static var noEntriesForCategory: String {
        t("noEntriesForCategory", "Nothing in this category yet. Add a site above.")
    }
    static var allowListNotice: String {
        t("allowListNotice",
          "This block list uses an allow list: everything is blocked except the sites and apps below.")
    }
    /// Shown when an edit was stored on this Mac but the server refused or never received it.
    /// "<NAME>" is the block list's name.
    static var syncFailed: String {
        t("syncFailed",
          "Saved on this Mac only \u{2014} \u{201C}<NAME>\u{201D} couldn\u{2019}t be synced, so these changes won\u{2019}t reach your other devices yet.")
    }
    static var dismiss: String { t("dismiss", "Dismiss") }

    /// Fills the `<COUNT>` placeholder in the card badge, keeping the singular form when there is one.
    static func blocksBadge(for count: Int) -> String {
        guard count != 1 else { return oneBlockCount }
        return blocksCount.replacingOccurrences(of: countPlaceholder, with: "\(count)")
    }

    static func searchPlaceholder(for category: DistractionCategory?) -> String {
        guard let category else { return searchPlaceholder }
        return searchPlaceholderForCategory.replacingOccurrences(
            of: categoryPlaceholder, with: category.displayName)
    }

    static func commonlyBlockedIn(_ category: DistractionCategory) -> String {
        commonlyBlockedIn.replacingOccurrences(
            of: categoryPlaceholder, with: category.displayName.uppercased())
    }

    static func syncFailed(listName: String) -> String {
        syncFailed.replacingOccurrences(of: namePlaceholder, with: listName)
    }

    private static let countPlaceholder = "<COUNT>"
    private static let namePlaceholder = "<NAME>"
    private static let categoryPlaceholder = "<CATEGORY>"
}
