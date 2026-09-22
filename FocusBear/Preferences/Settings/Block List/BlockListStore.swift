//
//  BlockListStore.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// Keys inside a focus-mode dictionary (`arrFocusType`) that the block-list screen reads or writes.
/// The app models focus modes as untyped `[String: Any]`, so these are the only guard against typos.
enum FocusModeKey {
    static let id = "id"
    static let name = "name"
    static let color = "color"
    static let isDefault = "isDefault"
    static let isMeetings = "isMeetings"
    static let isRelaxFocus = "isRelaxFocus"
    static let isDeepWorkFocus = "isDeepWorkFocus"
    static let isLockedFocus = "isLockedFocus"
    static let isAllowedListApproach = "isAllowedListApproach"
    static let allowedUrls = "allowed_urls"
    static let allowedApps = "allowed_apps"
    static let blockUrlsArray = "blockUrlsArray"
    static let blockAppsArray = "blockAppsArray"
    /// Per-entry categories, `[["entry": …, "category": …]]`. Mirrors the backend's `categories`
    /// column (backend#2400) and is sent top-level, NOT inside `metadata`.
    static let categories = "categories"
}

/// Field names inside one `categories` element. These are the wire format shared with the backend.
enum FocusModeCategoryKey {
    static let entry = "entry"
    static let category = "category"
}

/// Promotes a focus mode's `categories` out of the `metadata` catch-all and onto the top level of a
/// focus-mode request body.
///
/// Every focus-mode write builds `{name, allowed_*, tags, metadata: <every other key>}`. Categories
/// must NOT ride inside `metadata`: that blob is replaced wholesale on each save, so a client that
/// predates categories would silently wipe them. The backend gives them their own field instead
/// (backend#2400), where an omitted value is preserved rather than emptied.
func applyFocusModeCategories(
    from focusType: [String: Any],
    to json: inout [String: Any],
    metadata: inout [String: Any]
) {
    metadata.removeValue(forKey: FocusModeKey.categories)
    json[FocusModeKey.categories] = focusType[FocusModeKey.categories] as? [[String: String]] ?? []
}

/// Whether a blocked entry is a website or an application.
enum BlockListEntryType {
    case website
    case app

    var displayName: String {
        switch self {
        case .website: return BlockListText.typeWebsite
        case .app: return BlockListText.typeApp
        }
    }
}

/// One row of the block-list table.
struct BlockListEntry: Identifiable, Equatable {
    /// The stored string — a URL/keyword for a website, an app path for an app.
    let value: String
    let type: BlockListEntryType
    let category: DistractionCategory

    /// An entry is unique by value *within* its type; an app path and a URL can never collide.
    var id: String { "\(type == .app ? "app" : "url"):\(value)" }

    /// The leading letter shown in the row's avatar tile, per the design's favicon placeholder.
    var avatarLetter: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    /// Apps are stored as full paths (`/Applications/Slack.app`); show just the app's name.
    var displayName: String {
        guard type == .app else { return value }
        let name = (value as NSString).lastPathComponent
        return name.hasSuffix(appBundleExtension)
            ? String(name.dropLast(appBundleExtension.count))
            : name
    }

    private var appBundleExtension: String { ".app" }
}

/// One card in the left rail.
struct BlockListSummary: Identifiable, Equatable {
    /// Index into the global `arrFocusType`, which the legacy screen uses as a focus mode's identity.
    let index: Int
    let id: String
    let name: String
    /// A leading emoji in the name, if the user put one there — the design draws one per card.
    let emoji: String?
    let colorString: String
    let entryCount: Int
    let usesAllowList: Bool
    /// #2571 (14): which per-mode actions the selected card offers, mirroring the legacy list's rules.
    let canDelete: Bool
    let canDuplicate: Bool
    let canHide: Bool
    /// Whether the mode's name may be edited — the built-in modes keep fixed names (colour is still
    /// editable for all). Same set the legacy list locks the name field for.
    let canRename: Bool
    /// Whether this mode is currently hidden from the start/pomodoro/scheduling pickers.
    let isHidden: Bool

    /// The name with any leading emoji stripped, since the emoji is drawn in its own tile.
    var title: String {
        guard let emoji else { return name }
        return String(name.dropFirst(emoji.count)).trimmingCharacters(in: .whitespaces)
    }
}

/// Backs the SwiftUI block-list screen over the app's untyped global `arrFocusType`.
///
/// It deliberately does not own the data: `arrFocusType` stays the single source of truth so the
/// legacy sheets (Advanced, Add URL, Add Focus Mode) keep working against the same array. The store
/// re-reads it on `reload()` after any of those run.
@available(macOS 11.0, *)
final class BlockListStore: ObservableObject {

    @Published private(set) var blockLists: [BlockListSummary] = []
    @Published private(set) var entries: [BlockListEntry] = []
    @Published var selectedIndex: Int? {
        didSet { if oldValue != selectedIndex { reloadEntries() } }
    }
    /// `nil` means the "All" chip is active.
    @Published var activeCategory: DistractionCategory? {
        didSet { if oldValue != activeCategory { objectWillChange.send() } }
    }
    /// #2571 (NEW-A): the top field now searches/filters only. This is what it drives.
    @Published var searchText: String = ""
    /// #2571 (NEW-A): the bottom "add a new URL" field, kept separate from the search text so the two
    /// jobs don't share one box.
    @Published var draftEntry: String = ""
    /// The category a newly typed/added entry will be filed under.
    @Published var draftCategory: DistractionCategory = .fallback
    /// #2571 (14): when on, hidden modes are shown (dimmed) in the rail instead of removed — the
    /// "Reveal hidden focus modes" checkbox, mirroring the legacy list.
    @Published var revealHidden: Bool = false {
        didSet { if oldValue != revealHidden { reload() } }
    }
    /// Non-nil when the last edit was written locally but rejected by (or never reached) the server.
    /// Drives the screen's banner, so a sync failure is visible rather than log-only.
    @Published private(set) var syncFailureMessage: String?

    init() {
        reload()
    }

    // MARK: - Reading

    /// Focus modes the screen may show. Hides the "Locked Focus" pseudo-mode (as the legacy table
    /// does) and, unless `revealHidden` is on, the modes the user has hidden from pickers.
    private var visibleFocusModeIndices: [Int] {
        arrFocusType.indices.filter { index in
            guard arrFocusType[index][FocusModeKey.isLockedFocus] as? Bool != true else { return false }
            if revealHidden { return true }
            let id = arrFocusType[index][FocusModeKey.id] as? String ?? "\(index)"
            return !HiddenFocusModeManager.isHidden(id: id)
        }
    }

    /// Whether any non-locked mode is currently hidden — drives the "Reveal hidden focus modes"
    /// checkbox's visibility, which only appears once the user has hidden something.
    var hasHiddenModes: Bool {
        arrFocusType.indices.contains { index in
            arrFocusType[index][FocusModeKey.isLockedFocus] as? Bool != true
                && HiddenFocusModeManager.isHidden(id: arrFocusType[index][FocusModeKey.id] as? String ?? "\(index)")
        }
    }

    func reload() {
        // Nothing hidden any more → leave reveal mode, so the checkbox can disappear (as it did in the
        // legacy list). The didSet re-enters reload once, then this guard is false and it builds.
        if revealHidden && !hasHiddenModes { revealHidden = false; return }
        blockLists = visibleFocusModeIndices.map { index in
            let focusMode = arrFocusType[index]
            let name = focusMode[FocusModeKey.name] as? String ?? ""
            func flag(_ key: String) -> Bool { focusMode[key] as? Bool == true }
            let id = focusMode[FocusModeKey.id] as? String ?? "\(index)"
            // Same visibility rules as the legacy list (focusPreferencesVc.tableView(_:viewFor:row:)):
            // delete is hidden for the built-in modes, duplicate only for Default, hide for anything
            // that isn't Default or the Locked pseudo-mode.
            let isBuiltIn = flag(FocusModeKey.isDefault) || flag(FocusModeKey.isMeetings)
                || flag(FocusModeKey.isLockedFocus) || flag(FocusModeKey.isRelaxFocus)
                || flag(FocusModeKey.isDeepWorkFocus)
            return BlockListSummary(
                index: index,
                id: id,
                name: name,
                emoji: Self.leadingEmoji(in: name),
                colorString: focusMode[FocusModeKey.color] as? String ?? "",
                entryCount: Self.storedEntries(at: index).count,
                usesAllowList: focusMode[FocusModeKey.isAllowedListApproach] as? Bool == true,
                canDelete: !isBuiltIn,
                canDuplicate: !flag(FocusModeKey.isDefault),
                canHide: !flag(FocusModeKey.isDefault) && !flag(FocusModeKey.isLockedFocus),
                canRename: !isBuiltIn,
                isHidden: HiddenFocusModeManager.isHidden(id: id))
        }
        if let selectedIndex, !blockLists.contains(where: { $0.index == selectedIndex }) {
            self.selectedIndex = blockLists.first?.index
        } else if selectedIndex == nil {
            selectedIndex = blockLists.first?.index
        }
        reloadEntries()
    }

    private func reloadEntries() {
        guard let index = selectedIndex, arrFocusType.indices.contains(index) else {
            entries = []
            return
        }
        let assigned = Self.assignedCategories(at: index)
        entries = Self.storedEntries(at: index).map { stored in
            BlockListEntry(
                value: stored.value,
                type: stored.type,
                category: assigned[stored.value]
                    ?? DistractionCategoryCatalog.inferredCategory(for: stored.value)
                    ?? .fallback)
        }
    }

    /// Entries after the search box and the active category chip are applied.
    var visibleEntries: [BlockListEntry] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries.filter { entry in
            let matchesCategory = activeCategory == nil || entry.category == activeCategory
            let matchesSearch = needle.isEmpty || entry.displayName.lowercased().contains(needle)
            return matchesCategory && matchesSearch
        }
    }

    /// How many entries sit in each category, for the filter-chip counts.
    func count(for category: DistractionCategory?) -> Int {
        guard let category else { return entries.count }
        return entries.filter { $0.category == category }.count
    }

    /// Seed domains for the active category that this block list does not already contain — the
    /// design's "COMMONLY BLOCKED IN …" one-tap chips.
    func suggestions(limit: Int = BlockListStore.maxSuggestions) -> [String] {
        guard let category = activeCategory else { return [] }
        let existing = Set(entries.map { $0.value.lowercased() })
        return DistractionCategoryCatalog.seedEntries(for: category)
            .filter { !existing.contains($0.lowercased()) }
            .prefix(limit)
            .map { $0 }
    }

    var selectedBlockList: BlockListSummary? {
        guard let selectedIndex else { return nil }
        return blockLists.first { $0.index == selectedIndex }
    }

    /// The selected mode's stored name, for pre-filling a rename prompt.
    var selectedName: String {
        guard let index = selectedIndex, arrFocusType.indices.contains(index) else { return "" }
        return arrFocusType[index][FocusModeKey.name] as? String ?? ""
    }

    // MARK: - Renaming and recolouring the selected mode (#2571 14)

    /// The outcome of a rename attempt, so the host can show the right feedback.
    enum RenameResult { case renamed, unchanged, empty, duplicate }

    /// Renames the selected mode. Names must be unique across modes (case-insensitively), matching
    /// the legacy inline rename; the local write and server sync both go through `persist`.
    @discardableResult
    func renameSelected(to rawName: String) -> RenameResult {
        guard let index = selectedIndex, arrFocusType.indices.contains(index) else { return .empty }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .empty }
        let current = arrFocusType[index][FocusModeKey.name] as? String ?? ""
        if name == current { return .unchanged }
        let clashes = arrFocusType.indices.contains { other in
            other != index
                && (arrFocusType[other][FocusModeKey.name] as? String)?.lowercased() == name.lowercased()
        }
        if clashes { return .duplicate }
        arrFocusType[index][FocusModeKey.name] = name
        persist(index: index)
        return .renamed
    }

    /// Sets the selected mode's colour swatch. `hexString` is `RRGGBB`, as `getColorString` produces.
    func setColor(_ hexString: String) {
        guard let index = selectedIndex, arrFocusType.indices.contains(index) else { return }
        arrFocusType[index][FocusModeKey.color] = hexString
        persist(index: index)
    }

    // MARK: - Writing

    /// Adds a website entry to the selected block list, filed under `draftCategory`.
    /// Returns false when the entry is blank or already present.
    @discardableResult
    func addWebsite(_ rawValue: String) -> Bool {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, let index = selectedIndex, arrFocusType.indices.contains(index) else {
            return false
        }
        guard !entries.contains(where: { $0.type == .website && $0.value.lowercased() == value.lowercased() })
        else { return false }

        var urls = Self.storedUrls(at: index)
        urls.append(value)
        Self.writeUrls(urls, at: index)
        setCategory(draftCategory, forEntry: value, persist: false)
        persist(index: index)
        return true
    }

    /// Adds an application entry (a full `.app` path, as the file picker yields) to the selected block
    /// list, filed under `draftCategory`. Returns false when blank or already present. (#2571 11)
    @discardableResult
    func addApp(_ rawPath: String) -> Bool {
        let value = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, let index = selectedIndex, arrFocusType.indices.contains(index) else {
            return false
        }
        guard !entries.contains(where: { $0.type == .app && $0.value == value }) else { return false }

        var apps = Self.storedApps(at: index)
        apps.append(value)
        Self.writeApps(apps, at: index)
        setCategory(draftCategory, forEntry: value, persist: false)
        persist(index: index)
        return true
    }

    func remove(_ entry: BlockListEntry) {
        guard let index = selectedIndex, arrFocusType.indices.contains(index) else { return }
        switch entry.type {
        case .website:
            Self.writeUrls(Self.storedUrls(at: index).filter { $0 != entry.value }, at: index)
        case .app:
            Self.writeApps(Self.storedApps(at: index).filter { $0 != entry.value }, at: index)
        }
        // Drop the orphaned category so the stored list can't grow without bound as entries churn.
        var assigned = Self.assignedCategories(at: index)
        assigned.removeValue(forKey: entry.value)
        Self.writeAssignedCategories(assigned, at: index)
        persist(index: index)
    }

    func setCategory(_ category: DistractionCategory, forEntry value: String) {
        setCategory(category, forEntry: value, persist: true)
    }

    private func setCategory(_ category: DistractionCategory, forEntry value: String, persist shouldPersist: Bool) {
        guard let index = selectedIndex, arrFocusType.indices.contains(index) else { return }
        var assigned = Self.assignedCategories(at: index)
        assigned[value] = category
        Self.writeAssignedCategories(assigned, at: index)
        if shouldPersist { persist(index: index) }
    }

    /// Writes the mutated focus mode to UserDefaults and syncs it to the server.
    ///
    /// The local write comes first, so an edit is never lost to a failed request — the screen keeps
    /// showing what the user chose either way. A rejected sync is logged rather than swallowed: the
    /// server bounds `categories` independently of the block list itself (backend#2400), so a very
    /// large list is the one way a save can be accepted locally and refused remotely, and that
    /// divergence should be visible in the debug log rather than invisible.
    private func persist(index: Int) {
        Self.pruneOrphanedCategories(at: index)
        UserDefaults.standard.set(plistSafeFocusModes(arrFocusType), forKey: kUserdefaultsArrFocusTypes)
        // `editFocusMode` no-ops for Locked Focus modes, which the rail never shows anyway.
        let name = arrFocusType[index][FocusModeKey.name] as? String ?? ""
        allApiObject.editFocusMode(focusType: arrFocusType[index], completionHandler: { [weak self] updated in
            // URLSession calls back off the main thread; `syncFailureMessage` drives SwiftUI.
            DispatchQueue.main.async {
                guard updated == nil else {
                    self?.syncFailureMessage = nil
                    return
                }
                addLog(text: "BlockListStore: categories for '\(name)' saved locally but not synced to the server")
                self?.syncFailureMessage = BlockListText.syncFailed(listName: name)
            }
        })
        reload()
    }

    /// Clears the banner. The edit itself is already stored locally, so dismissing loses nothing.
    func dismissSyncFailure() {
        syncFailureMessage = nil
    }

    /// Drops categories whose entry is no longer in the block list.
    ///
    /// Removing an entry through this screen already prunes its category, but an older client (or
    /// another platform) can delete a URL without knowing categories exist, stranding the row. The
    /// stored list would otherwise only ever grow. Pruning on write rather than on read keeps it a
    /// side effect of an edit the user actually made.
    static func pruneOrphanedCategories(at index: Int) {
        guard arrFocusType.indices.contains(index) else { return }
        let assigned = assignedCategories(at: index)
        guard !assigned.isEmpty else { return }
        let live = Set(storedEntries(at: index).map { $0.value })
        let kept = assigned.filter { live.contains($0.key) }
        guard kept.count != assigned.count else { return }
        writeAssignedCategories(kept, at: index)
    }

    // MARK: - Focus-mode dictionary access

    private struct StoredEntry {
        let value: String
        let type: BlockListEntryType
    }

    private static func storedEntries(at index: Int) -> [StoredEntry] {
        storedUrls(at: index).map { StoredEntry(value: $0, type: .website) }
            + storedApps(at: index).map { StoredEntry(value: $0, type: .app) }
    }

    /// The Default mode edits the app-wide "super distracting sites" list, and Relax modes block
    /// nothing — both match how the legacy table sources its rows.
    private static func storedUrls(at index: Int) -> [String] {
        let focusMode = arrFocusType[index]
        if focusMode[FocusModeKey.isRelaxFocus] as? Bool == true { return [] }
        if focusMode[FocusModeKey.isDefault] as? Bool == true { return SettingsManagerObject.arrBlockedUrls }
        let key = usesAllowList(focusMode) ? FocusModeKey.allowedUrls : FocusModeKey.blockUrlsArray
        return focusMode[key] as? [String] ?? []
    }

    private static func storedApps(at index: Int) -> [String] {
        let focusMode = arrFocusType[index]
        if focusMode[FocusModeKey.isRelaxFocus] as? Bool == true { return [] }
        if focusMode[FocusModeKey.isDefault] as? Bool == true { return SettingsManagerObject.arrBlockedApps }
        let key = usesAllowList(focusMode) ? FocusModeKey.allowedApps : FocusModeKey.blockAppsArray
        return focusMode[key] as? [String] ?? []
    }

    private static func usesAllowList(_ focusMode: [String: Any]) -> Bool {
        focusMode[FocusModeKey.isAllowedListApproach] as? Bool == true
    }

    private static func writeUrls(_ urls: [String], at index: Int) {
        if arrFocusType[index][FocusModeKey.isDefault] as? Bool == true {
            SettingsManagerObject.arrBlockedUrls = urls
            UserDefaults.standard.set(urls, forKey: SettingsManagerObject.kUserdefaultsArrBlockedUrls)
            return
        }
        let key = usesAllowList(arrFocusType[index]) ? FocusModeKey.allowedUrls : FocusModeKey.blockUrlsArray
        arrFocusType[index][key] = urls
    }

    private static func writeApps(_ apps: [String], at index: Int) {
        if arrFocusType[index][FocusModeKey.isDefault] as? Bool == true {
            SettingsManagerObject.arrBlockedApps = apps
            UserDefaults.standard.set(apps, forKey: SettingsManagerObject.kUserdefaultsArrBlockedApps)
            return
        }
        let key = usesAllowList(arrFocusType[index]) ? FocusModeKey.allowedApps : FocusModeKey.blockAppsArray
        arrFocusType[index][key] = apps
    }

    // MARK: - Category persistence (wire format)

    /// Decodes `arrFocusType[index]["categories"]` into an entry → category map.
    ///
    /// Unknown category ids (an entry filed by a newer client, or by another platform) are dropped
    /// rather than treated as an error, so a mixed-version fleet degrades to "uncategorised".
    static func assignedCategories(at index: Int) -> [String: DistractionCategory] {
        guard arrFocusType.indices.contains(index),
              let stored = arrFocusType[index][FocusModeKey.categories] as? [[String: String]]
        else { return [:] }

        var result: [String: DistractionCategory] = [:]
        for item in stored {
            guard let entry = item[FocusModeCategoryKey.entry], !entry.isEmpty,
                  let raw = item[FocusModeCategoryKey.category],
                  let category = DistractionCategory(rawValue: raw)
            else { continue }
            result[entry] = category
        }
        return result
    }

    /// Encodes the map back to the wire shape. Sorted so the payload is stable between saves and
    /// doesn't churn the server row on every unrelated edit.
    static func encodeCategories(_ assigned: [String: DistractionCategory]) -> [[String: String]] {
        assigned.keys.sorted().map { entry in
            [FocusModeCategoryKey.entry: entry,
             FocusModeCategoryKey.category: assigned[entry]!.rawValue]
        }
    }

    private static func writeAssignedCategories(_ assigned: [String: DistractionCategory], at index: Int) {
        guard arrFocusType.indices.contains(index) else { return }
        arrFocusType[index][FocusModeKey.categories] = encodeCategories(assigned)
    }

    // MARK: - Helpers

    /// The emoji a user typed at the start of a block-list name, if any. Focus modes have no emoji
    /// field, so the design's per-card emoji comes from the name itself.
    static func leadingEmoji(in name: String) -> String? {
        guard let first = name.trimmingCharacters(in: .whitespaces).first else { return nil }
        // `isEmoji` alone is true for plain digits and `#`/`*` (they have emoji presentation
        // sequences), so require either a dedicated emoji presentation or a multi-scalar cluster
        // such as a flag or a ZWJ family. Returning the whole grapheme keeps those intact.
        let scalars = first.unicodeScalars
        let isEmoji = scalars.first?.properties.isEmojiPresentation == true || scalars.count > 1
        guard isEmoji, scalars.contains(where: { $0.properties.isEmoji }) else { return nil }
        return String(first)
    }

    static let maxSuggestions = 4
}
