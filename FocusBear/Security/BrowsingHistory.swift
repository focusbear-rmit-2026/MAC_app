//
//  BrowsingHistory.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

let kBrowsingHistoryFileName = "browsing-history.jsonl"

/// What the blocker did with a page or an app window.
enum BrowsingDecision: String, Codable {
    /// Looked at; the decision comes in a later entry.
    case seen
    case allowed
    case blocked
    /// A prompt asked the user (block-confirm popup, intention window, AI block buddy).
    case checkInShown = "check-in-shown"
    /// The relevance check answered: `aiScore` and `aiReason` say what it thought.
    case aiVerdict = "ai-verdict"
    /// A relevance answer that arrived too late and was thrown away.
    case verdictDiscarded = "verdict-discarded"
}

/// Why, for the decisions that have no reason code of their own. The blocker's existing codes
/// (`blocked_once_in_this_session`, `block_in_focus_mode`) are recorded as they are.
enum BrowsingReason {
    static let allowedByFocusMode = "focus-mode-allows-site"
    static let notOnAllowList = "not-allowed-in-focus-mode"
    static let aiRelevant = "ai-relevant"
    static let aiUnverified = "ai-unverified-so-allowed"
    static let aiBlock = "ai_blocking"
    static let alwaysBlocked = "always-blocked"
    static let blockedDuringHabit = "blocked-during-habit"
    static let blockConfirmPopup = "block-confirm-popup"
    static let intentionPrompt = "intention-prompt"
    static let aiBlockBuddy = "ai-block-buddy"
    static let pageChanged = "page-changed-during-check"
    static let appWindowForAi = "window-title-for-ai"
    static let claudeChatTitle = "claude-chat-title"
}

/// One thing the blocker saw or decided, with everything a bug report needs: the whole URL, the
/// window title, the front app, the focus mode and the AI's verdict.
struct BrowsingHistoryEntry: Codable, Hashable {
    let time: Date
    let decision: BrowsingDecision
    /// The function that recorded it, so a reader can find the code path.
    let source: String
    var url: String?
    var title: String?
    var app: String?
    var reason: String?
    var focusMode: String?
    var aiScore: Double?
    var aiReason: String?

    /// The same event again, a moment later: a page the user is still on.
    func isRepeat(of other: BrowsingHistoryEntry) -> Bool {
        decision == other.decision && source == other.source && url == other.url && title == other.title
            && app == other.app && reason == other.reason && focusMode == other.focusMode
            && aiScore == other.aiScore && aiReason == other.aiReason
    }
}

/// The last 30 minutes of browsing and blocking, kept for problem reports and nothing else.
///
/// `Debug_Logs.txt` only names the site (`LogPrivacy.site`), because it is plaintext and stays for
/// weeks. The full URLs and window titles live here instead: sealed at rest with the account's data
/// key, in `SecureFileStore`'s `browsing-history.jsonl` (one JSON entry per sealed record), and never
/// older than `retention` plus `compactionSlack`. Entries are pruned in memory on every write and on
/// a timer, and the sealed file is rewritten once its oldest entry is past the window. The in-app
/// report writes the decrypted window to `logs/browsing-history.log` in the local report folder.
///
/// Until the store is ready (no signed-in account yet, the key not unlocked, or an ad-hoc build that
/// never encrypts) entries are kept in memory only — never written in plaintext — and merged into the
/// sealed file once it opens. The file is registered like a server-backed cache: unreadable means
/// gone, and sign-out deletes it.
final class BrowsingHistory {
    /// Jeremy's call: the 30 minutes before a report is what debugging needs; beyond that is not kept.
    static let retention: TimeInterval = 30 * 60
    static let pruneInterval: TimeInterval = 60
    /// A stay on one page is recorded again after this long, so it still shows once its first entry
    /// ages out, without a line for every poll of the browser.
    static let repeatInterval: TimeInterval = 60
    /// How far past the window the sealed file's oldest entry may be before the file is rewritten, so
    /// a steady stream of events rewrites it about once a minute rather than on every write.
    static let compactionSlack: TimeInterval = 60
    /// A ceiling for a flood of distinct events; 30 minutes of real browsing stays far below it.
    static let maximumEntries = 5000
    static let exportFileName = "browsing-history.log"
    static let exportedAtLabel = "# exported-at: "
    static let timestampFormat = "yyyy-MM-dd HH:mm:ss"

    static let shared: BrowsingHistory = {
        let history = BrowsingHistory(files: SecureFiles.shared, fileURL: defaultFileURL)
        history.startPruning()
        return history
    }()

    /// Where the file would live in plaintext; `SecureFileStore` keeps the sealed copy under the
    /// account's folder instead and only uses this name.
    static var defaultFileURL: URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return applicationSupport
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? SecureStore.defaultBundleId, isDirectory: true)
            .appendingPathComponent(kBrowsingHistoryFileName)
    }

    private let files: SecureFileStore
    private let fileURL: URL
    private let now: () -> Date
    private let queue = DispatchQueue(label: "io.focusbear.browsing-history", qos: .utility)
    private var entries: [BrowsingHistoryEntry] = []
    /// The oldest entry in the sealed file, nil when there is none.
    private var oldestPersisted: Date?
    /// The account whose sealed file has been read into `entries`.
    private var loadedAccountId: String?
    private var timer: DispatchSourceTimer?
    private var readyObserver: NSObjectProtocol?

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = timestampFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(files: SecureFileStore, fileURL: URL, now: @escaping () -> Date = Date.init) {
        self.files = files
        self.fileURL = fileURL
        self.now = now
        readyObserver = NotificationCenter.default.addObserver(forName: SecureStore.didBecomeReady, object: files.store,
                                                               queue: nil) { [weak self] _ in
            self?.queue.async { self?.loadSealedCopyIfNeeded() }
        }
        queue.async { [weak self] in self?.loadSealedCopyIfNeeded() }
    }

    deinit {
        timer?.cancel()
        if let readyObserver { NotificationCenter.default.removeObserver(readyObserver) }
    }

    // MARK: - Recording

    /// Records one event. Cheap for the caller: the entry is stamped now, sealed on a utility queue.
    func record(_ decision: BrowsingDecision, url: String? = nil, title: String? = nil, app: String? = nil,
                reason: String? = nil, focusMode: String? = nil, aiScore: Double? = nil, aiReason: String? = nil,
                source: String = #function) {
        // `#function` inside a closure names the whole enclosing signature; the name is enough.
        let functionName = String(source.prefix { $0 != "(" })
        let entry = BrowsingHistoryEntry(time: now(), decision: decision, source: functionName, url: nonEmpty(url),
                                         title: nonEmpty(title), app: nonEmpty(app), reason: nonEmpty(reason),
                                         focusMode: nonEmpty(focusMode), aiScore: aiScore, aiReason: nonEmpty(aiReason))
        queue.async { [weak self] in self?.append(entry) }
    }

    /// The entries inside the window, oldest first.
    func currentEntries() -> [BrowsingHistoryEntry] {
        queue.sync {
            loadSealedCopyIfNeeded()
            pruneMemory()
            return entries
        }
    }

    /// Waits for every queued record to be applied. Tests use it; the app never needs to.
    func waitUntilIdle() {
        queue.sync {}
    }

    /// Prunes now rather than at the next tick of the timer.
    func pruneNow() {
        queue.sync { pruneAndCompact() }
    }

    func startPruning() {
        guard timer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.pruneInterval, repeating: Self.pruneInterval)
        timer.setEventHandler { [weak self] in self?.pruneAndCompact() }
        timer.resume()
        self.timer = timer
    }

    // MARK: - Export

    /// The decrypted window as text for a problem report, newest last. Only the in-app report calls
    /// this, and only to write into the report's local folder.
    func exportText() -> String {
        let window = currentEntries()
        let exportedAt = now()
        let header = [
            "# Focus Bear browsing and blocking history: the \(Int(Self.retention / 60)) minutes before this report.",
            Self.exportedAtLabel + Self.formatter.string(from: exportedAt),
            "# entries: \(window.count)",
            "# store: \(files.store.currentState.summary)",
            "# site=<site:…> is what Debug_Logs.txt shows for the same page; grep the log for it.",
            "",
        ]
        let lines = window.isEmpty ? ["# no browsing or blocking events in the window"] : window.map(Self.exportLine)
        return (header + lines).joined(separator: "\n") + "\n"
    }

    static func exportLine(_ entry: BrowsingHistoryEntry) -> String {
        var fields = [formatter.string(from: entry.time), entry.decision.rawValue, entry.source]
        if let url = entry.url { fields.append("site=\(LogPrivacy.site(url))") }
        if let app = entry.app { fields.append("app=\(quoted(app))") }
        if let reason = entry.reason { fields.append("reason=\(quoted(reason))") }
        if let focusMode = entry.focusMode { fields.append("focus-mode=\(quoted(focusMode))") }
        if let aiScore = entry.aiScore { fields.append("ai-score=\(aiScore)") }
        if let aiReason = entry.aiReason { fields.append("ai-reason=\(quoted(aiReason))") }
        if let url = entry.url { fields.append("url=\(quoted(url))") }
        if let title = entry.title { fields.append("title=\(quoted(title))") }
        return fields.joined(separator: " ")
    }

    /// One token per field, whatever the value holds: quotes, backslashes and line breaks escaped.
    private static func quoted(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r")
        return "\"\(escaped)\""
    }

    // MARK: - Memory

    private func append(_ entry: BrowsingHistoryEntry) {
        if let last = entries.last, entry.isRepeat(of: last), entry.time.timeIntervalSince(last.time) < Self.repeatInterval {
            return
        }
        entries.append(entry)
        if entries.count > Self.maximumEntries { entries.removeFirst(entries.count - Self.maximumEntries) }
        pruneMemory()
        persist(entry)
    }

    private var windowStart: Date { now().addingTimeInterval(-Self.retention) }

    private func pruneMemory() {
        let start = windowStart
        entries.removeAll { $0.time < start }
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    // MARK: - Sealed file

    /// Only a registered file on a ready store is ever written: that is what keeps it sealed. Anything
    /// else (no account, no key, an ad-hoc build) leaves the history in memory.
    private var canPersist: Bool {
        files.store.currentState.isReady && files.isRegistered(fileURL)
    }

    private func persist(_ entry: BrowsingHistoryEntry) {
        guard canPersist else { return }
        // Opening the file for the first time writes the whole merged window, this entry included.
        if loadSealedCopyIfNeeded() { return }
        guard let line = Self.encodedLine(entry) else { return }
        do {
            try files.appendText(line, to: fileURL)
            oldestPersisted = oldestPersisted ?? entry.time
        } catch {
            addLog(text: "[browsing-history] could not seal an entry: \(error)")
        }
        compactIfNeeded()
    }

    private func pruneAndCompact() {
        pruneMemory()
        guard canPersist else { return }
        if loadSealedCopyIfNeeded() { return }
        compactIfNeeded()
    }

    /// Reads the account's sealed file into memory once, merges what was recorded while it was
    /// closed, and rewrites it as exactly the window. Returns true when it wrote the file.
    @discardableResult
    private func loadSealedCopyIfNeeded() -> Bool {
        guard canPersist, let account = files.store.currentAccountId, account != loadedAccountId else { return false }
        if loadedAccountId != nil {
            // Another account's history must not be sealed into this one's file.
            entries.removeAll()
        }
        loadedAccountId = account
        let sealed = (try? files.readText(fileURL)).map(Self.decodeLines) ?? []
        entries = Array(Set(sealed + entries)).sorted { $0.time < $1.time }
        pruneMemory()
        rewrite()
        return true
    }

    private func compactIfNeeded() {
        guard let oldest = oldestPersisted, oldest < windowStart.addingTimeInterval(-Self.compactionSlack) else { return }
        pruneMemory()
        rewrite()
    }

    /// Replaces the sealed file with the entries in memory (already pruned to the window).
    private func rewrite() {
        guard !entries.isEmpty else {
            files.remove(fileURL)
            oldestPersisted = nil
            return
        }
        let text = entries.compactMap(Self.encodedLine).joined()
        do {
            try files.writeText(text, to: fileURL)
            oldestPersisted = entries.first?.time
        } catch {
            addLog(text: "[browsing-history] could not rewrite the sealed history: \(error)")
        }
    }

    private static func encodedLine(_ entry: BrowsingHistoryEntry) -> String? {
        guard let data = try? encoder.encode(entry), let json = String(data: data, encoding: .utf8) else { return nil }
        return json + "\n"
    }

    private static func decodeLines(_ text: String) -> [BrowsingHistoryEntry] {
        text.split(separator: "\n").compactMap { try? decoder.decode(BrowsingHistoryEntry.self, from: Data($0.utf8)) }
    }
}
