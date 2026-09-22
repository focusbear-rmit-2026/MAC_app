import AppKit
import Combine
import Foundation

enum LocalReportCapability {
    static let accountID = "9884b0af-dc9f-4207-964e-e4db537a2234"
    static func isEnabled(for account: String) -> Bool { account == accountID }
    static var currentAccount: String {
        let account = appdelegate?.user?.userId ?? ""
        return isEnabled(for: account) ? account : ""
    }
}

enum LocalReportReviewState: String {
    case queued, investigating, readyForQA, needsClarification, reworkNeeded, confirmedFixed
    /// Fixed on the Mac but not testable until a backend PR ships. Distinct from `readyForQA`, which
    /// invites a test that would fail for a reason the tester cannot act on.
    case blockedOnBackend
}

/// The folder name carrying `blockedOnBackend`. One constant, because it is written by the agent
/// workflow and read here; a typo in either place silently downgrades the report to `queued`.
enum LocalReportFolders {
    static let readyForQA = "Ready for Human QA"
    static let needsClarification = "Needs Clarification"
    static let blockedOnBackend = "Blocked on Backend"
    static let all = [readyForQA, needsClarification, blockedOnBackend]
}

struct LocalReportStatus: Identifiable {
    let id: String
    let accountID: String
    let reportCreated: String
    let createdAt: Date
    let title: String
    let state: LocalReportReviewState
    let notesExcerpt: String?
    let notesURL: URL?
    /// The newest `## Update` in the review notes, when the notes carry one. The row shows this
    /// instead of the oldest note text, and says which update it is (report 2026-09-15_22-26-04).
    let latestUpdate: LocalReportNoteUpdate?
    let latestInstructions: String?
    /// When the review notes were last written — the "last update from AI" the row shows. Nil for a
    /// report nobody has written notes for yet, and the row then says nothing rather than inventing
    /// a date (report 2026-09-17_06-23-46).
    let lastAIUpdate: Date?
    let userStatus: LocalReportUserStatus?
    let userStatusData: Data?
    /// Images the report captured, newest first. The text alone often doesn't say what was wrong
    /// (report 2026-09-13_21-19-23).
    let screenshotURLs: [URL]
}

/// "Last update from AI" as one row: how long ago, and exactly when.
///
/// Both halves were asked for and both earn their place. "2h ago" answers *is this moving* at a
/// glance — the question the list exists to answer — while "Yesterday at 8:30 pm" answers *exactly
/// when*, which the relative form stops being able to do the moment it rolls up to weeks
/// (report 2026-09-17_06-23-46).
struct LocalReportUpdateAge: Equatable {
    /// Glance form: "5m ago", "2h ago", "1y ago", or the system's word for now.
    let relative: String
    /// Unambiguous form: "Yesterday at 8:30 pm".
    let absolute: String
    /// What the row shows, both halves on one line.
    var combined: String { "\(relative) \(LocalReportUpdateAgeFormatter.separator) \(absolute)" }
}

/// Turns a report's last-update date into the two strings its row shows.
///
/// The thresholds are the system's rather than ours: `RelativeDateTimeFormatter` rolls seconds up
/// through minutes, hours, days, weeks, months and years, so a report last touched 400 days ago
/// reads "1y ago" instead of "400d ago", and every unit is already translated for the user's locale.
/// `doesRelativeDateFormatting` does the same for the absolute half, giving "Yesterday at 8:30 pm"
/// for free. Nothing here is hand-built, so nothing here needs a config string or a translation.
///
/// One case is decided here rather than by the formatter: inside the last minute the numeric style
/// says "0s ago", and a note stamped by a clock a few seconds ahead of ours says "in 3s". Neither is
/// a thing to show, so anything newer than `nowThreshold` — the future included — reads as now.
///
/// An instance holds its formatters, because building a `DateFormatter` per row per refresh is the
/// expensive part and this list can hold a hundred rows. Not thread-safe, exactly like the
/// formatters it wraps: `shared` belongs to the main thread, and tests build their own with a
/// pinned locale and time zone.
final class LocalReportUpdateAgeFormatter {
    /// Separates the two halves on the row. One constant: the row writes it, `combined` reads it.
    static let separator = "\u{00b7}"
    /// Below this, elapsed time is noise — the list only rescans every 15 seconds anyway.
    static let nowThreshold: TimeInterval = 60
    static let shared = LocalReportUpdateAgeFormatter()

    private let elapsed = RelativeDateTimeFormatter()
    private let justNow = RelativeDateTimeFormatter()
    private let moment = DateFormatter()

    init(locale: Locale = .current, timeZone: TimeZone = .current) {
        var calendar = Calendar.current
        calendar.locale = locale
        calendar.timeZone = timeZone
        elapsed.unitsStyle = .abbreviated
        elapsed.dateTimeStyle = .numeric
        elapsed.locale = locale
        elapsed.calendar = calendar
        // `.named` is the style that has a word for no elapsed time at all; `.numeric` says "in 0s".
        justNow.unitsStyle = .abbreviated
        justNow.dateTimeStyle = .named
        justNow.locale = locale
        justNow.calendar = calendar
        moment.locale = locale
        moment.calendar = calendar
        moment.timeZone = timeZone
        moment.dateStyle = .medium
        moment.timeStyle = .short
        moment.doesRelativeDateFormatting = true
    }

    /// Nil for a report with no review notes: it has no last update from AI, and "never" or an epoch
    /// date would both be claims the folder never made.
    func describe(_ date: Date?, now: Date) -> LocalReportUpdateAge? {
        guard let date = date else { return nil }
        let relative = now.timeIntervalSince(date) < Self.nowThreshold
            ? justNow.localizedString(for: now, relativeTo: now)
            : elapsed.localizedString(for: date, relativeTo: now)
        return .init(relative: relative, absolute: moment.string(from: date))
    }
}

/// Which part of the app a report is about, worked out from its own words.
///
/// "I can't test focus session UI now. I want to review the day plan parts though" — with a queue
/// this size, reviewing means picking the reports you can actually act on right now
/// (report 2026-09-14_22-14-16). Nothing in a report folder records an area, so it is inferred from
/// the title and the review notes; the first area whose words appear wins, and anything unrecognised
/// stays `other` rather than being filed somewhere wrong.
enum LocalReportArea: String, CaseIterable {
    case dayPlan, focusSession, tasksProjects, blocking, routinesBreaks, reportsFeedback, stats, menuBar, other

    /// Checked in order: earlier areas win a tie, so the more specific phrases come first.
    private static let vocabulary: [(LocalReportArea, [String])] = [
        (.dayPlan, ["day plan", "dayplan", "deep work", "time box", "timebox", "free time", "capacity", "schedule view", "habit block"]),
        (.focusSession, ["focus session", "focus mode", "block list", "blocklist", "ai block", "intention", "pomodoro", "focus start"]),
        (.tasksProjects, ["task", "to-do", "todo", "project", "subtask", "due date", "attachment", "assignee", "objective"]),
        (.blocking, ["blocking", "blocked", "distraction", "website block", "app block", "permission"]),
        (.routinesBreaks, ["routine", "habit", "break", "postpone", "micro break", "stretch", "evening", "morning"]),
        (.reportsFeedback, ["report", "feedback", "instructions", "screenshot", "confirmed fixed", "rework"]),
        (.stats, ["stats", "statistics", "leaderboard", "streak", "motivation", "focus log"]),
        (.menuBar, ["menu bar", "menubar", "menu popover", "tray", "status item", "quick add"]),
    ]

    /// Memo for `detect`, which both the filter row and the filtered list need for every report.
    ///
    /// `detect` lowercases the title plus its notes and sweeps the whole vocabulary for substrings —
    /// around sixty searches per report. Both callers run inside `LocalReportStatusView.body`, so at
    /// this queue length (~280 reports) every re-render redid tens of thousands of those searches and
    /// the list stalled on its own filter row (Sentry FOCUS-BEAR-MACOS-1G6: `LocalReportArea.detect`
    /// under `LocalReportStatusView.body.getter`). `detect` is a pure function of its two arguments, so
    /// the answer is cached against them and a re-render is a dictionary lookup.
    private static let cache = LocalReportAreaCache()

    static func detect(title: String, notes: String?) -> LocalReportArea {
        cache.area(title: title, notes: notes) {
            let haystack = (title + " " + (notes ?? "")).lowercased()
            for (area, words) in vocabulary where words.contains(where: { haystack.contains($0) }) {
                return area
            }
            return .other
        }
    }

    /// Areas actually present, in the declared order, so the filter never offers an empty one.
    static func present(in reports: [LocalReportStatus]) -> [LocalReportArea] {
        let found = Set(reports.map { detect(title: $0.title, notes: $0.notesExcerpt) })
        return allCases.filter { found.contains($0) }
    }

    static func matching(_ reports: [LocalReportStatus], area: LocalReportArea?) -> [LocalReportStatus] {
        guard let area = area else { return reports }
        return reports.filter { detect(title: $0.title, notes: $0.notesExcerpt) == area }
    }
}

/// Remembers the area worked out for a report's own words.
///
/// Keyed on the exact text it was derived from, so a changed title or a rewritten note simply misses
/// and is recomputed — there is nothing to invalidate. Bounded because the reports list is scanned
/// repeatedly over a long-running session; past the cap the memo is dropped whole rather than evicted
/// one entry at a time, since refilling it costs one scan and the alternative is tracking use order for
/// something that only has to stop growing.
private final class LocalReportAreaCache {
    /// Comfortably more than the reports list keeps on screen, so steady-state rendering always hits.
    private static let capacity = 1000
    private let lock = NSLock()
    private var areasByText: [String: LocalReportArea] = [:]

    func area(title: String, notes: String?, compute: () -> LocalReportArea) -> LocalReportArea {
        // A separator that cannot occur in either field, so a title cannot impersonate title+notes.
        let key = title + "\u{0}" + (notes ?? "")
        lock.lock()
        let cached = areasByText[key]
        lock.unlock()
        if let cached = cached { return cached }

        let area = compute()
        lock.lock()
        if areasByText.count >= Self.capacity { areasByText.removeAll(keepingCapacity: true) }
        areasByText[key] = area
        lock.unlock()
        return area
    }
}

/// How the report list groups its rows.
///
/// The old "Show fixed reports" checkbox meant scanning one long list for the few needing attention.
/// Grouping by status puts those first and keeps the noisy groups shut (report 2026-09-14_19-49-11).
enum LocalReportGrouping {
    /// Attention first, finished last.
    static let order: [LocalReportReviewState] = [
        .reworkNeeded, .needsClarification, .readyForQA, .investigating, .blockedOnBackend,
        .queued, .confirmedFixed,
    ]

    /// Groups that open on their own. Queued and completed stay shut: one is not started, the other
    /// is over, and neither is what the user opened the list to find.
    static let expandedByDefault: Set<LocalReportReviewState> = [
        .reworkNeeded, .needsClarification, .readyForQA, .investigating,
    ]

    /// Non-empty groups in display order, each with its reports in the order given.
    static func groups(_ reports: [LocalReportStatus]) -> [(state: LocalReportReviewState, reports: [LocalReportStatus])] {
        order.compactMap { state in
            let matching = reports.filter { $0.state == state }
            return matching.isEmpty ? nil : (state, matching)
        }
    }
}

/// Filtering the report list by what the user types in the search box.
///
/// With enough reports the list is long enough that finding the one to mark fixed is the hard part
/// (report 2026-09-14_12-08-07). Matching is case- and diacritic-insensitive over the report's own
/// title, its notes excerpt and the instructions the user added — every piece of text on the row.
enum LocalReportSearch {
    static func matching(_ reports: [LocalReportStatus], query: String) -> [LocalReportStatus] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return reports }
        return reports.filter { matches($0, needle: needle) }
    }

    private static func matches(_ report: LocalReportStatus, needle: String) -> Bool {
        [report.title, report.notesExcerpt ?? "", report.latestInstructions ?? "", report.reportCreated]
            .contains { contains($0, needle) }
    }

    private static func contains(_ haystack: String, _ needle: String) -> Bool {
        guard !haystack.isEmpty else { return false }
        return haystack.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

/// User-authored status is independent of reviewer notes and folder moves. Keeping it in a
/// sidecar means confirmation cannot replace TASK.md while instructions are being appended.
struct LocalReportUserStatus: Codable {
    static let fileName = "USER-STATUS.json"
    static let maximumBytes = 4096
    let schemaVersion: Int
    let accountID: String
    let reportCreated: String
    let confirmedFixed: Bool
    let updatedAt: String
    var updatedDate: Date? { ISO8601DateFormatter().date(from: updatedAt) }
    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version", accountID = "account_id", reportCreated = "report_created"
        case confirmedFixed = "confirmed_fixed", updatedAt = "updated_at"
    }
    static func decode(_ data: Data?, accountID: String, reportCreated: String) -> Self? {
        guard LocalReportCapability.isEnabled(for: accountID), let data = data, data.count <= maximumBytes,
              let status = try? JSONDecoder().decode(Self.self, from: data), status.schemaVersion == 1,
              status.accountID == accountID, status.reportCreated == reportCreated,
              status.updatedDate != nil else { return nil }
        return status
    }
    static func read(_ url: URL) throws -> Data? {
        let files = FileManager.default
        guard (try? files.destinationOfSymbolicLink(atPath: url.path)) == nil else { throw LocalReportInstructionError.unavailable }
        guard files.fileExists(atPath: url.path) else { return nil }
        guard LocalReportStatusReader.isRealFile(url), let file = try? FileHandle(forReadingFrom: url) else { throw LocalReportInstructionError.unavailable }
        defer { try? file.close() }
        guard let data = try file.read(upToCount: maximumBytes + 1), data.count <= maximumBytes else { throw LocalReportInstructionError.unavailable }
        return data
    }
}

struct LocalReportStatusSnapshot {
    let reports: [LocalReportStatus]
    let isLimited: Bool
}

// MARK: - Review notes: one original note, then the updates appended to it

/// One later addition to a report's review notes.
///
/// Notes accrete: a diagnosis is written first, and every later change is appended to the same file
/// under its own `## Update` heading. Read as one blob, the newest addition — the only part that is
/// news — is buried in the middle of it ("subsequent updates should appear as separate notes below.
/// It's very hard for me to find the updates currently", report 2026-09-15_22-26-04).
struct LocalReportNoteUpdate: Identifiable {
    /// 1-based position in the order written, whatever the heading calls itself.
    let number: Int
    /// The writer's own words beside the marker. Empty for a bare `## Update`.
    let summary: String
    /// The moment the heading claims, when it carries one. Every note written before updates were
    /// stamped has none, and must still render.
    let date: Date?
    /// Everything under the heading up to the next update, sub-sections included.
    let body: String
    /// The opening prose, before the update's first sub-heading: a row-sized summary of it.
    let lead: String
    var id: Int { number }
}

/// A review notes file split into the parts a reader actually looks for.
struct LocalReportNotes {
    /// The note's own `# ` title line, when it has one.
    let title: String
    /// The first diagnosis: everything written before the first update.
    let original: String
    /// Updates in the order they were written, oldest first.
    let updates: [LocalReportNoteUpdate]
    var latest: LocalReportNoteUpdate? { updates.last }
    /// Newest first, which is the order the reader shows them in: the update someone opened the
    /// notes to find should not be at the bottom of a scroll.
    var newestFirst: [LocalReportNoteUpdate] { updates.reversed() }
}

/// Splits a notes file on its `## Update` headings.
///
/// New updates are written stamped — `## Update — 2026-09-15 22:40 — what changed` — so the reader
/// can show when each one was made. Nothing depends on that: every note already on disk is
/// unstamped, often nothing but `## Update`, and must still render.
enum LocalReportNoteParser {
    /// A trailing separator or blank line belongs to the layout of the file, not to a note's text.
    private static let ruleLength = 3
    private static let separators = CharacterSet(charactersIn: " \t\u{2014}\u{2013}-:\u{00B7},.")
    private static let datePattern = #"\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2})?"#

    static func parse(_ text: String) -> LocalReportNotes {
        var lines = text.components(separatedBy: .newlines)[...]
        var title = ""
        while let first = lines.first, isBlank(first) { lines = lines.dropFirst() }
        if let first = lines.first, first.hasPrefix("# ") {
            title = String(first.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            lines = lines.dropFirst()
        }
        var original: [String] = []
        var sections: [(heading: String, body: [String])] = []
        for line in lines {
            if let heading = updateHeading(line) { sections.append((heading, [])) }
            else if sections.isEmpty { original.append(line) }
            else { sections[sections.count - 1].body.append(line) }
        }
        let updates = sections.enumerated().map { index, section in
            LocalReportNoteUpdate(number: index + 1, summary: summary(of: section.heading),
                                  date: date(in: section.heading), body: block(section.body),
                                  lead: lead(section.body))
        }
        return LocalReportNotes(title: title, original: block(original), updates: updates)
    }

    /// The text after the hashes and the `Update` marker, or nil when the line starts something else.
    /// Deliberately tolerant: `## Update`, `##Update 2 — …`, `## update (2026-09-15) — …` all count,
    /// because every note already on disk was typed by hand. Deeper headings never do — `### Update
    /// 2 code` is a section inside an update, not a new one.
    static func updateHeading(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("##"), !trimmed.hasPrefix("###") else { return nil }
        let text = trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
        guard let start = markerEnd(in: text) else { return nil }
        return String(text[start...])
    }

    /// Where the `Update`/`Updates` marker ends, when the text opens with one. "Updated the parser"
    /// does not: the marker has to be a whole word.
    private static func markerEnd(in text: String) -> String.Index? {
        let lowercased = text.lowercased()
        for marker in ["updates", "update"] where lowercased.hasPrefix(marker) {
            let end = text.index(text.startIndex, offsetBy: marker.count)
            guard end < text.endIndex else { return end }
            let next = text[end]
            if !next.isLetter && !next.isNumber { return end }
        }
        return nil
    }

    /// The writer's words, with the heading's own scaffolding removed: the ordinal it numbered
    /// itself with and a stamp that is shown as a date instead.
    private static func summary(of heading: String) -> String {
        var value = strip(#"^\d{1,3}(?!\d)"#, from: heading.trimmingCharacters(in: .whitespaces))
        var changed = true
        while changed {
            let before = value
            value = value.trimmingCharacters(in: separators)
            value = strip("^\\(\\s*" + datePattern + "\\s*\\)", from: value)
            value = strip("^" + datePattern, from: value)
            changed = value != before
        }
        return value
    }

    /// The first date a heading mentions, in any of the forms the notes use.
    static func date(in heading: String) -> Date? {
        guard let range = heading.range(of: datePattern, options: .regularExpression) else { return nil }
        let value = String(heading[range])
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.isLenient = false
        for format in ["yyyy-MM-dd HH:mm", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private static func strip(_ pattern: String, from text: String) -> String {
        guard let range = text.range(of: pattern, options: .regularExpression), range.lowerBound == text.startIndex
        else { return text }
        return String(text[range.upperBound...])
    }

    private static func isBlank(_ line: String) -> Bool { line.trimmingCharacters(in: .whitespaces).isEmpty }

    private static func isRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= ruleLength && trimmed.allSatisfy { $0 == "-" }
    }

    /// A note's text without the blank lines and horizontal rules that only separated it from the
    /// next one.
    private static func block(_ lines: [String]) -> String {
        var lines = lines[...]
        while let first = lines.first, isBlank(first) || isRule(first) { lines = lines.dropFirst() }
        while let last = lines.last, isBlank(last) || isRule(last) { lines = lines.dropLast() }
        return lines.joined(separator: "\n")
    }

    private static func lead(_ lines: [String]) -> String {
        let prose = lines.drop { isBlank($0) || isRule($0) }
            .prefix { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#") && !isRule($0) }
        return prose.joined(separator: " ").components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.joined(separator: " ")
    }
}

// MARK: - Re-reading only what changed

/// What one `attributesOfItem` call tells a scan about a file, without following links.
struct LocalReportFileStat: Equatable {
    let type: FileAttributeType?
    let modified: Date?
    let size: UInt64
    var isRegularFile: Bool { type == .typeRegular }
    var isDirectory: Bool { type == .typeDirectory }
}

/// The filesystem a scan reads, gathered in one place so a test can count what it touches.
///
/// The point of the seam is the `text` closure: a refresh of a folder nothing has touched must cost
/// stats, not file reads. With hundreds of reports on disk, reading and re-parsing every TASK.md and
/// every notes file was the whole cost of a refresh.
struct LocalReportFileReader {
    var stat: (URL) -> LocalReportFileStat?
    var contentsOfDirectory: (URL) throws -> [URL]
    var text: (URL) -> String?
    var userStatusData: (URL) throws -> Data?

    static let live = LocalReportFileReader(
        stat: { url in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
            return LocalReportFileStat(type: attributes[.type] as? FileAttributeType,
                                       modified: attributes[.modificationDate] as? Date,
                                       size: (attributes[.size] as? NSNumber)?.uint64Value ?? 0)
        },
        contentsOfDirectory: { url in
            try FileManager.default.contentsOfDirectory(at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: [.skipsHiddenFiles])
        },
        text: { LocalReportStatusReader.readText($0) },
        userStatusData: { try LocalReportUserStatus.read($0) })
}

/// The file identities a folder's parsed content depends on. Anything the scan derives from the text
/// of TASK.md or of the review notes is valid exactly as long as this is unchanged.
struct LocalReportFolderStamp: Equatable {
    let task: LocalReportFileStat
    /// Whichever of the two notes files is the newer one, which is the one the scan reads.
    let notesName: String?
    let notesModified: Date?
    /// The screenshots folder's own modification date: adding or removing a capture changes it.
    let screenshotsModified: Date?
}

/// Everything a scan derives from a report's own text, and nothing that depends on where the folder
/// currently sits or what the user has since confirmed.
struct LocalReportFolderContent {
    let reportCreated: String
    let createdAt: Date
    let title: String
    let notesExcerpt: String?
    let latestUpdate: LocalReportNoteUpdate?
    let latestInstructions: String?
    let latestInstructionsDate: Date?
    /// The state the notes declare for themselves, when they declare one.
    let notesReviewState: LocalReportReviewState?
    /// Whether readable review notes were found. A notes file too large to read still counts as a
    /// notes file for the purpose of moving a queued report to "Review notes available".
    let hasNotes: Bool
    let screenshotURLs: [URL]
}

struct LocalReportFolderRecord {
    let stamp: LocalReportFolderStamp
    /// The single `- User:` line in TASK.md. Read before the review notes are opened, so a folder
    /// belonging to another account never has its notes read at all.
    let owner: String?
    /// The account this folder was read for. A record filled while scanning as somebody else stopped
    /// at the ownership check, so it cannot answer for the account that does own the folder.
    let readFor: String
    /// Nil when TASK.md is not a usable report, or when the folder belongs to another account and
    /// was therefore never opened any further.
    let content: LocalReportFolderContent?
}

/// Per-folder scan results, so a refresh re-reads only folders that actually changed.
///
/// Keyed on the folder's full path. A report moved between state folders — `Ready for Human QA/`
/// back to the top level, which this workflow does constantly — is a different key, so it is re-read
/// and shows the state of where it now lives instead of the state it had where it used to be.
final class LocalReportFolderCache {
    private var records: [String: LocalReportFolderRecord] = [:]
    private let lock = NSLock()

    static func key(for folder: URL) -> String { folder.standardizedFileURL.path }

    func record(for folder: URL, stamp: LocalReportFolderStamp, account: String,
                fill: () -> LocalReportFolderRecord) -> LocalReportFolderRecord {
        let key = Self.key(for: folder)
        lock.lock(); let cached = records[key]; lock.unlock()
        if let cached = cached, cached.stamp == stamp,
           cached.readFor == account || cached.owner != account { return cached }
        let fresh = fill()
        lock.lock(); records[key] = fresh; lock.unlock()
        return fresh
    }

    /// Forget folders this scan no longer saw, so deleted or renamed reports cannot grow the cache
    /// without bound.
    func retain(_ keys: Set<String>) {
        lock.lock(); records = records.filter { keys.contains($0.key) }; lock.unlock()
    }

    var count: Int { lock.lock(); defer { lock.unlock() }; return records.count }
}

/// Reads only bounded TASK/notes text in the three documented local review locations. Logs,
/// screenshots, other accounts and linked files/directories never enter the status model.
enum LocalReportStatusReader {
    static let maximumTextBytes = 64 * 1024
    static let maximumReports = 100
    /// Screenshots offered per report. A report carries a handful; the cap keeps a pathological
    /// folder from filling the list.
    static let maximumScreenshots = 6
    static let screenshotExtensions: Set<String> = ["png", "jpg", "jpeg", "gif"]
    private static let maximumCandidates = 1000
    static var defaultRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("FocusBear-Claude-Tasks", isDirectory: true)
    }

    /// The two names a review-notes file may have, in one place: the scan looks for them, and
    /// `mayOpenNotes` refuses to open anything else.
    static let noteFileNames = ["CLAUDE-NOTES.md", "CODEX-NOTES.md"]
    static let taskFileName = "TASK.md"
    /// Where a report keeps its captures — written by the image writer, read by the scan
    /// and by the guard that decides whether a click may open one.
    static let screenshotsFolderName = "screenshots"

    /// `cache` defaults to a throwaway, so a one-off scan reads everything; the report list keeps one
    /// across refreshes, which is what turns a steady-state refresh into stats rather than reads.
    static func scan(root: URL, accountID: String, includeConfirmedFixed: Bool = true,
                     cache: LocalReportFolderCache = LocalReportFolderCache(),
                     files: LocalReportFileReader = .live) throws -> LocalReportStatusSnapshot {
        guard !accountID.isEmpty else { return .init(reports: [], isLimited: false) }
        guard files.stat(root)?.isDirectory == true else { return .init(reports: [], isLimited: false) }
        let locations: [(URL, LocalReportReviewState)] = [(root, .queued),
            (root.appendingPathComponent(LocalReportFolders.readyForQA, isDirectory: true), .readyForQA),
            (root.appendingPathComponent(LocalReportFolders.needsClarification, isDirectory: true), .needsClarification),
            (root.appendingPathComponent(LocalReportFolders.blockedOnBackend, isDirectory: true), .blockedOnBackend)]
        var reports: [LocalReportStatus] = [], limited = false, seen: Set<String> = []
        for (location, state) in locations {
            guard files.stat(location)?.isDirectory == true else { continue }
            let folders = try files.contentsOfDirectory(location)
                .filter { files.stat($0)?.isDirectory == true && !LocalReportFolders.all.contains($0.lastPathComponent) }
                .sorted { timestamp(in: $0.lastPathComponent) > timestamp(in: $1.lastPathComponent) }
            limited = limited || folders.count > maximumCandidates
            for folder in folders.prefix(maximumCandidates) {
                seen.insert(LocalReportFolderCache.key(for: folder))
                guard let stamp = stamp(of: folder, files: files) else { continue }
                let record = cache.record(for: folder, stamp: stamp, account: accountID) {
                    read(folder: folder, stamp: stamp, accountID: accountID, files: files)
                }
                guard record.owner == accountID, let content = record.content else { continue }
                let userStatusData = try? files.userStatusData(folder.appendingPathComponent(LocalReportUserStatus.fileName))
                let report = status(content, accountID: accountID, folder: folder, source: state,
                                    notesURL: stamp.notesName.map { folder.appendingPathComponent($0) },
                                    userStatusData: userStatusData, notesModified: stamp.notesModified)
                // Apply the user's filter before the display cap, so newer fixed reports
                // cannot crowd older open reports out of the bounded scan.
                if includeConfirmedFixed || report.state != .confirmedFixed { reports.append(report) }
            }
        }
        cache.retain(seen)
        reports.sort { $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt > $1.createdAt }
        return .init(reports: Array(reports.prefix(maximumReports)), isLimited: limited || reports.count > maximumReports)
    }

    /// The identities a folder's parsed content depends on, or nil when it has no readable TASK.md.
    private static func stamp(of folder: URL, files: LocalReportFileReader) -> LocalReportFolderStamp? {
        guard let task = files.stat(folder.appendingPathComponent(taskFileName)), task.isRegularFile else { return nil }
        let notes = noteFileNames
            .compactMap { name -> (String, Date?)? in
                guard let stat = files.stat(folder.appendingPathComponent(name)), stat.isRegularFile else { return nil }
                return (name, stat.modified)
            }
            .sorted { ($0.1 ?? .distantPast) > ($1.1 ?? .distantPast) }
            .first
        let screenshots = files.stat(folder.appendingPathComponent(screenshotsFolderName, isDirectory: true))
        return .init(task: task, notesName: notes?.0, notesModified: notes?.1,
                     screenshotsModified: screenshots?.isDirectory == true ? screenshots?.modified : nil)
    }

    /// Opens a folder's files. Only reached when the folder is new or its stamp has moved.
    private static func read(folder: URL, stamp: LocalReportFolderStamp, accountID: String,
                             files: LocalReportFileReader) -> LocalReportFolderRecord {
        guard let task = files.text(folder.appendingPathComponent(taskFileName)) else {
            return .init(stamp: stamp, owner: nil, readFor: accountID, content: nil)
        }
        let owner = owner(in: task)
        // Check ownership before opening the review notes, not just before displaying them.
        guard owner == accountID else { return .init(stamp: stamp, owner: owner, readFor: accountID, content: nil) }
        let notes = stamp.notesName.map { folder.appendingPathComponent($0) }.flatMap { files.text($0) }
        return .init(stamp: stamp, owner: owner, readFor: accountID,
                     content: content(task: task, notes: notes, screenshotURLs: screenshotURLs(in: folder, files: files)))
    }

    /// Image files sitting directly in the report's own `screenshots` folder. Nothing is followed:
    /// a link, a nested folder, or an unexpected extension is ignored, the same way the notes reader
    /// refuses anything but the two notes files.
    static func screenshotURLs(in folder: URL, files: LocalReportFileReader = .live) -> [URL] {
        let directory = folder.appendingPathComponent(screenshotsFolderName, isDirectory: true)
        guard files.stat(directory)?.isDirectory == true else { return [] }
        let contents = (try? files.contentsOfDirectory(directory)) ?? []
        return contents.filter { screenshotExtensions.contains($0.pathExtension.lowercased())
                                 && files.stat($0)?.isRegularFile == true }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .prefix(maximumScreenshots)
            .map { $0 }
    }

    /// Ownership can change between a scan and the user's click, exactly as for the notes file, and
    /// the path must still be one of this report's own screenshots.
    static func mayOpenScreenshot(_ url: URL, report: LocalReportStatus, accountID: String) -> Bool {
        guard !accountID.isEmpty, report.accountID == accountID,
              screenshotExtensions.contains(url.pathExtension.lowercased()), isRealFile(url) else { return false }
        let folder = URL(fileURLWithPath: report.id, isDirectory: true)
        let directory = folder.appendingPathComponent(screenshotsFolderName, isDirectory: true).standardizedFileURL
        guard url.deletingLastPathComponent().standardizedFileURL == directory,
              isRealDirectory(directory), isRealDirectory(folder),
              let task = readText(folder.appendingPathComponent(taskFileName)) else { return false }
        return parse(task: task, notes: nil, source: .queued, folder: folder,
                     notesURL: nil, accountID: accountID)?.reportCreated == report.reportCreated
    }

    static func parse(task: String, notes: String?, source: LocalReportReviewState, folder: URL, notesURL: URL?,
                      accountID: String, userStatusData: Data? = nil, screenshotURLs: [URL] = [],
                      notesModified: Date? = nil) -> LocalReportStatus? {
        guard !accountID.isEmpty, owner(in: task) == accountID,
              let content = content(task: task, notes: notes, screenshotURLs: screenshotURLs) else { return nil }
        return status(content, accountID: accountID, folder: folder, source: source, notesURL: notesURL,
                      userStatusData: userStatusData, notesModified: notesModified)
    }

    /// Everything the report's own text says, parsed once. The review notes in particular are parsed
    /// a single time here: the excerpt and the latest update are two views of the same parse, and
    /// reading them as two separate calls doubled the parsing cost of every refresh.
    static func content(task: String, notes: String?, screenshotURLs: [URL] = []) -> LocalReportFolderContent? {
        let header = String(task.components(separatedBy: "\n## ").first ?? "")
        let created = header.components(separatedBy: .newlines).first { $0.hasPrefix("- Created: ") }
            .map { String($0.dropFirst("- Created: ".count)).trimmingCharacters(in: .whitespaces) } ?? ""
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"; formatter.isLenient = false
        guard timestamp(in: created) == created, !created.isEmpty, let date = formatter.date(from: created) else { return nil }
        let description = section("What to investigate", in: task)?.components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
        let title = description == "_(no description provided)_" ? "" : String(description.prefix(180))
        let parsed = notes.map(LocalReportNoteParser.parse)
        return .init(reportCreated: created, createdAt: date, title: title,
                     notesExcerpt: notes.flatMap { excerpt($0, parsed: parsed) }, latestUpdate: parsed?.latest,
                     latestInstructions: latestInstructions(in: task), latestInstructionsDate: latestInstructionsDate(in: task),
                     notesReviewState: notes.flatMap(explicitReviewState), hasNotes: notes != nil,
                     screenshotURLs: screenshotURLs)
    }

    /// Where the report currently sits, what the user has confirmed, and how recently they asked for
    /// more — the parts of a row that change without the report's own files changing.
    static func status(_ content: LocalReportFolderContent, accountID: String, folder: URL,
                       source: LocalReportReviewState, notesURL: URL?, userStatusData: Data?,
                       notesModified: Date?) -> LocalReportStatus {
        let userStatus = LocalReportUserStatus.decode(userStatusData, accountID: accountID, reportCreated: content.reportCreated)
        // A queued report that has notes is still QUEUED. It used to become `.notesAvailable`, but that
        // is not a status the PO recognises — and it fires constantly now that notes are written while
        // the work is still in flight and the folder is only filed once the fix is installed
        // (report 2026-09-17_14-30-00). Notes existing is not a state; where the folder sits is.
        var reviewState = content.notesReviewState ?? source
        // Feedback added after the last reviewer note means the report is back in play — the user
        // asked for that to be visible immediately rather than staying "Ready for your review"
        // (report 2026-09-14_20-06-22).
        //
        // This used to exempt confirmed-fixed reports on the reasoning that they were finished. They
        // are not: leaving feedback on something you marked fixed is how you say it wasn't
        // (report 2026-09-16_20-26-48). So a confirmation is just another dated event to beat — the
        // feedback has to be newer than BOTH the last note and the confirmation, or confirming a
        // report that already carried old feedback would bounce straight back to rework.
        let lastReviewed = [notesModified, userStatus?.confirmedFixed == true ? userStatus?.updatedDate : nil]
            .compactMap { $0 }.max()
        if let asked = content.latestInstructionsDate, asked > (lastReviewed ?? .distantPast) {
            reviewState = .reworkNeeded
        }
        // Rework outranks the confirmation, because the rework decision above already took the
        // confirmation's date into account — reaching `.reworkNeeded` means the feedback is newer
        // than the confirmation, so showing "confirmed fixed" here would hide the very thing the
        // user just said (report 2026-09-16_20-26-48).
        let state: LocalReportReviewState = reviewState == .reworkNeeded ? .reworkNeeded
            : (userStatus?.confirmedFixed == true ? .confirmedFixed : reviewState)
        return .init(id: folder.standardizedFileURL.path, accountID: accountID, reportCreated: content.reportCreated,
                     createdAt: content.createdAt, title: content.title, state: state, notesExcerpt: content.notesExcerpt,
                     notesURL: notesURL, latestUpdate: content.latestUpdate, latestInstructions: content.latestInstructions,
                     lastAIUpdate: notesModified, userStatus: userStatus, userStatusData: userStatusData,
                     screenshotURLs: content.screenshotURLs)
    }

    static func owner(in task: String) -> String? {
        let header = task.components(separatedBy: "\n## ").first ?? ""
        let owners = header.components(separatedBy: .newlines).filter { $0.hasPrefix("- User: ") }
        guard owners.count == 1 else { return nil }
        return String(owners[0].dropFirst("- User: ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func timestamp(in name: String) -> String {
        guard let range = name.range(of: #"\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}"#, options: .regularExpression) else { return "" }
        return String(name[range])
    }
    /// Only explicit review metadata declares active work. Mentions in explanations, unknown
    /// statuses, and generic notes cannot silently claim that someone is investigating a report.
    private static func explicitReviewState(in text: String) -> LocalReportReviewState? {
        let value: String?
        if let status = section("Status", in: text) {
            value = status.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
        } else {
            let lines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.hasPrefix("**Status:**") }
            value = lines.count == 1 ? String(lines[0].dropFirst("**Status:**".count)) : nil
        }
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "investigating": return .investigating
        case "queued": return .queued
        default: return nil
        }
    }
    private static func section(_ heading: String, in text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "## \(heading)" }) else { return nil }
        return lines.dropFirst(start + 1).prefix { !$0.hasPrefix("## ") && $0 != "---" }.joined(separator: "\n")
    }
    /// `parsed` is the note split the caller already has, so the file is never parsed twice.
    private static func excerpt(_ text: String, parsed: LocalReportNotes?) -> String? {
        // The newest update is the news. Looking up `## Update` by name found the OLDEST one, which
        // is how a row could still summarise a diagnosis two updates out of date.
        if let latest = (parsed ?? LocalReportNoteParser.parse(text)).latest {
            let value = latest.lead.isEmpty ? latest.summary : latest.lead
            if !value.isEmpty { return String(value.prefix(400)) }
        }
        for heading in ["What a human should decide", "What I need from you", "Input needed", "Next action", "Status"] {
            if let section = section(heading, in: text) {
                let value = section.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
                if !value.isEmpty && !["investigating", "queued"].contains(value.lowercased()) { return String(value.prefix(400)) }
            }
        }
        if let status = text.components(separatedBy: .newlines).first(where: { $0.hasPrefix("**Status:**") }) {
            let value = status.dropFirst("**Status:**".count).trimmingCharacters(in: .whitespaces)
            return ["investigating", "queued"].contains(value.lowercased()) ? nil : String(value.prefix(400))
        }
        return nil
    }
    /// When the user last added instructions, from the `- Added:` stamp the in-app form writes.
    static func latestInstructionsDate(in task: String) -> Date? {
        let stamps = task.components(separatedBy: "\n## Additional instructions\n").dropFirst()
            .compactMap { section -> Date? in
                guard let line = section.components(separatedBy: .newlines).first(where: { $0.hasPrefix("- Added: ") })
                else { return nil }
                return ISO8601DateFormatter().date(from: String(line.dropFirst("- Added: ".count))
                    .trimmingCharacters(in: .whitespaces))
            }
        return stamps.max()
    }

    private static func latestInstructions(in task: String) -> String? {
        let sections = task.components(separatedBy: "\n## Additional instructions\n")
        guard sections.count > 1 else { return nil }
        let lines = (sections.last ?? "").components(separatedBy: .newlines)
        let text = lines.prefix { !$0.hasPrefix("## ") }.filter { !$0.hasPrefix("- Added: ") }
            .joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : String(text.prefix(600))
    }
    fileprivate static func isRealDirectory(_ url: URL) -> Bool {
        // URL resource values may retain the old file type after an item is replaced with a link.
        // FileManager reads fresh attributes of the item itself, without following the link.
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.type] as? FileAttributeType == .typeDirectory
    }
    static func isRealFile(_ url: URL) -> Bool {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.type] as? FileAttributeType == .typeRegular
    }
    static func mayOpenNotes(_ report: LocalReportStatus, accountID: String) -> Bool {
        guard !accountID.isEmpty, report.accountID == accountID, let url = report.notesURL,
              noteFileNames.contains(url.lastPathComponent),
              url.deletingLastPathComponent().standardizedFileURL.path == report.id,
              isRealDirectory(url.deletingLastPathComponent()), isRealFile(url),
              let task = readText(url.deletingLastPathComponent().appendingPathComponent(taskFileName)) else { return false }
        // Ownership can change between a scan and the user's click. Never open stale account data.
        return parse(task: task, notes: nil, source: .queued, folder: url.deletingLastPathComponent(),
                     notesURL: nil, accountID: accountID)?.reportCreated == report.reportCreated
    }
    static func readNotes(_ report: LocalReportStatus, accountID: () -> String) -> String? {
        let account = accountID()
        guard mayOpenNotes(report, accountID: account), let url = report.notesURL,
              let notes = readText(url), accountID() == account,
              mayOpenNotes(report, accountID: account) else { return nil }
        return notes
    }
    private static func modificationDate(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
    }
    fileprivate static func readText(_ url: URL) -> String? {
        guard isRealFile(url), let file = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? file.close() }
        guard let data = try? file.read(upToCount: maximumTextBytes + 1), data.count <= maximumTextBytes else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum LocalReportInstructionError: Error { case unavailable, invalidText, changed }

enum LocalReportInstructionWriter {
    static let maximumCharacters = 4000

    /// Coordinate an atomic replacement of this one existing TASK, preserving all original text.
    /// Reading the current file here allows notes/instructions added since the list was refreshed.
    static func append(_ text: String, to report: LocalReportStatus,
                       root: URL = LocalReportStatusReader.defaultRoot,
                       accountID: () -> String, now: Date = Date()) throws {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= maximumCharacters else { throw LocalReportInstructionError.invalidText }
        let account = accountID()
        guard LocalReportCapability.isEnabled(for: account), report.accountID == account else { throw LocalReportInstructionError.unavailable }
        let folder = URL(fileURLWithPath: report.id, isDirectory: true)
        let parent = folder.deletingLastPathComponent().standardizedFileURL
        let locations = ([root] + LocalReportFolders.all.map(root.appendingPathComponent)).map(\.standardizedFileURL)
        guard locations.contains(parent), LocalReportStatusReader.isRealDirectory(root),
              LocalReportStatusReader.isRealDirectory(parent), LocalReportStatusReader.isRealDirectory(folder) else { throw LocalReportInstructionError.unavailable }
        let url = folder.appendingPathComponent(LocalReportStatusReader.taskFileName)
        var coordinationError: NSError?, writeError: Error?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forMerging, error: &coordinationError) { coordinatedURL in
            do {
                guard accountID() == account, let original = LocalReportStatusReader.readText(coordinatedURL),
                      LocalReportStatusReader.owner(in: original) == account else { throw LocalReportInstructionError.unavailable }
                let formatter = ISO8601DateFormatter()
                let updated = original + "\n\n## Additional instructions\n\n- Added: \(formatter.string(from: now))\n\n\(text)\n"
                guard updated.utf8.count <= LocalReportStatusReader.maximumTextBytes else { throw LocalReportInstructionError.invalidText }
                // Detect an external review update or account switch before replacing the file.
                guard accountID() == account, LocalReportStatusReader.readText(coordinatedURL) == original else { throw LocalReportInstructionError.changed }
                try updated.write(to: coordinatedURL, atomically: true, encoding: .utf8)
            } catch { writeError = error }
        }
        if let error = coordinationError { throw error }
        if let error = writeError { throw error }
    }
}

/// Saving an image the user pasted while writing follow-up instructions.
///
/// A screenshot says in one glance what a paragraph struggles to (report 2026-09-14_12-08-59). The
/// image lands in the report's own `screenshots` folder, where the list already looks for thumbnails
/// and where a reviewer already looks for evidence — no new location, no new reader.
enum LocalReportImageWriter {
    /// Generous enough for a full-screen Retina grab, small enough that a stray paste can't fill the disk.
    static let maximumBytes = 12 * 1024 * 1024

    /// `pasted-<timestamp>.png`. Sorts beside the report's own captures and can't collide with them.
    static func fileName(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "pasted-\(formatter.string(from: now)).png"
    }

    /// The line appended to the instructions so the reviewer knows an image came with them, and which.
    static func reference(_ fileName: String) -> String { "[image: screenshots/\(fileName)]" }

    /// PNG bytes for a pasted image, or nil when it cannot be represented (or is implausibly large).
    static func pngData(for image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]),
              png.count <= maximumBytes else { return nil }
        return png
    }

    /// Write one pasted image into `report`'s screenshots folder, returning its file name.
    /// Guarded exactly like an instructions append: this account, this report, a real folder.
    @discardableResult
    static func save(_ image: NSImage, to report: LocalReportStatus,
                     root: URL = LocalReportStatusReader.defaultRoot,
                     accountID: () -> String, now: Date = Date()) throws -> String {
        let account = accountID()
        guard LocalReportCapability.isEnabled(for: account), report.accountID == account else {
            throw LocalReportInstructionError.unavailable
        }
        let folder = URL(fileURLWithPath: report.id, isDirectory: true)
        let parent = folder.deletingLastPathComponent().standardizedFileURL
        let locations = ([root] + LocalReportFolders.all.map(root.appendingPathComponent)).map(\.standardizedFileURL)
        guard locations.contains(parent), LocalReportStatusReader.isRealDirectory(root),
              LocalReportStatusReader.isRealDirectory(parent),
              LocalReportStatusReader.isRealDirectory(folder) else { throw LocalReportInstructionError.unavailable }
        guard let png = pngData(for: image) else { throw LocalReportInstructionError.invalidText }
        let directory = folder.appendingPathComponent(LocalReportStatusReader.screenshotsFolderName, isDirectory: true)
        if !LocalReportStatusReader.isRealDirectory(directory) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        }
        let name = fileName(now: now)
        try png.write(to: directory.appendingPathComponent(name), options: .atomic)
        return name
    }
}

enum LocalReportConfirmationWriter {
    static func setConfirmedFixed(_ confirmed: Bool, for report: LocalReportStatus,
                                  root: URL = LocalReportStatusReader.defaultRoot,
                                  accountID: () -> String, now: Date = Date()) throws {
        let account = accountID()
        guard LocalReportCapability.isEnabled(for: account), report.accountID == account else { throw LocalReportInstructionError.unavailable }
        let folder = URL(fileURLWithPath: report.id, isDirectory: true)
        let parent = folder.deletingLastPathComponent().standardizedFileURL
        let locations = ([root] + LocalReportFolders.all.map(root.appendingPathComponent)).map(\.standardizedFileURL)
        guard locations.contains(parent), LocalReportStatusReader.isRealDirectory(root),
              LocalReportStatusReader.isRealDirectory(parent), LocalReportStatusReader.isRealDirectory(folder) else { throw LocalReportInstructionError.unavailable }
        let taskURL = folder.appendingPathComponent(LocalReportStatusReader.taskFileName)
        let statusURL = folder.appendingPathComponent(LocalReportUserStatus.fileName)
        // Reject even dangling links before NSFileCoordinator can resolve the destination.
        _ = try LocalReportUserStatus.read(statusURL)
        var coordinationError: NSError?, writeError: Error?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: statusURL, options: .forMerging, error: &coordinationError) { coordinatedURL in
            do {
                guard accountID() == account, let task = LocalReportStatusReader.readText(taskURL),
                      let current = LocalReportStatusReader.parse(task: task, notes: nil, source: .queued, folder: folder,
                          notesURL: nil, accountID: account), current.reportCreated == report.reportCreated else { throw LocalReportInstructionError.unavailable }
                let previous = try LocalReportUserStatus.read(statusURL)
                // Do not overwrite a confirmation changed in another window or a future/foreign
                // metadata format. Refresh gives the user the current state before another action.
                guard previous == report.userStatusData else { throw LocalReportInstructionError.changed }
                if let previous = previous, LocalReportUserStatus.decode(previous, accountID: account, reportCreated: report.reportCreated) == nil {
                    throw LocalReportInstructionError.unavailable
                }
                let status = LocalReportUserStatus(schemaVersion: 1, accountID: account, reportCreated: report.reportCreated,
                    confirmedFixed: confirmed, updatedAt: ISO8601DateFormatter().string(from: now))
                let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(status)
                guard accountID() == account, LocalReportStatusReader.readText(taskURL) == task,
                      try LocalReportUserStatus.read(statusURL) == previous else { throw LocalReportInstructionError.changed }
                try data.write(to: coordinatedURL, options: .atomic)
            } catch { writeError = error }
        }
        if let error = coordinationError { throw error }
        if let error = writeError { throw error }
    }
}

final class LocalReportStatusStore: ObservableObject {
    typealias Loader = (String, Bool, @escaping (Result<LocalReportStatusSnapshot, Error>) -> Void) -> Void
    /// Writing one confirmation, given the account it was clicked under. Injectable so the wait the
    /// row shows can be tested without a real report folder on disk.
    typealias Confirmer = (Bool, LocalReportStatus, String) throws -> Void
    /// The one scan whose result may still change this list.
    private struct ActiveLoad {
        let token: Int
        let startedAt: Date
    }
    @Published private(set) var reports: [LocalReportStatus] = []
    @Published private(set) var failed = false
    @Published private(set) var isLimited = false
    /// A scan whose result the list is still waiting for. Only `refresh` claims it, and only the
    /// load that claimed it releases it.
    @Published private var activeLoad: ActiveLoad?
    /// True exactly while a scan that can still update this list is in flight.
    ///
    /// Derived rather than stored, because a stored flag could be — and was — left behind by a
    /// callback that took an early return: the list then said "Loading reports…" with Refresh greyed
    /// out for the rest of the session, and the 15s timer refused to start another scan because it
    /// believed one was already running (report 2026-09-16_10-25-00).
    var isLoading: Bool { activeLoad != nil }
    /// A scan still unfinished after this long has been lost — starved on the global queue, or a
    /// callback that never came. Waiting on it forever is exactly what leaves the list stuck, so a
    /// timer refresh is allowed to supersede it; the generation check keeps the loser harmless.
    static let abandonedLoadTimeout: TimeInterval = 60

    /// How long a confirmation's spinner may wait on the rescan that follows the write.
    ///
    /// The file is already on disk before that rescan starts, so the row is only waiting for the list
    /// to catch up — and if the scan is slow or lost, waiting forever is strictly worse than showing a
    /// status that is one refresh out of date. Without this cap the spinner turned indefinitely and
    /// the control stayed disabled, which reads as "the app has hung" on a click that in fact worked
    /// (report 2026-09-17: "it seems to be stuck at confirming fixed?").
    static let confirmationRescanTimeout: TimeInterval = 5

    /// Overridable so a test does not have to wait five real seconds to prove the cap releases.
    var confirmationRescanTimeout: TimeInterval = LocalReportStatusStore.confirmationRescanTimeout
    /// The list groups reports into status accordions and keeps completed ones in a collapsed group at
    /// the bottom, so every scan loads them — there is no longer a "Show fixed reports" filter to hide
    /// them at the source (report 2026-09-14_19-49-11). The loader keeps the parameter because the
    /// scanner still takes it.
    let showConfirmedFixed = true
    private(set) var loadedAccount = ""
    private var generation = 0
    private let accountID: () -> String
    private let loader: Loader
    private let confirmer: Confirmer

    init(accountID: @escaping () -> String = { LocalReportCapability.currentAccount },
         loader: Loader? = nil, confirmer: Confirmer? = nil) {
        self.accountID = accountID
        self.confirmer = confirmer ?? { confirmed, report, account in
            try LocalReportConfirmationWriter.setConfirmedFixed(confirmed, for: report, accountID: { account })
        }
        // One cache for the life of the store: it is what makes the repeated timer refresh cost a
        // directory listing and a stat per folder instead of re-reading every report on disk.
        let cache = LocalReportFolderCache()
        self.loader = loader ?? { account, includeConfirmedFixed, done in
            DispatchQueue.global(qos: .utility).async {
                done(Result { try LocalReportStatusReader.scan(root: LocalReportStatusReader.defaultRoot, accountID: account,
                                                              includeConfirmedFixed: includeConfirmedFixed, cache: cache) })
            }
        }
    }
    func checkAccount() { if loadedAccount != accountID() { refresh() } }
    /// Timer/activation refreshes never overlap an existing scan or reset the user's filter — unless
    /// that scan is old enough to have plainly been lost, in which case waiting on it is worse than
    /// replacing it.
    func refreshIfIdle(now: Date = Date()) {
        if let load = activeLoad, now.timeIntervalSince(load.startedAt) < Self.abandonedLoadTimeout { return }
        refresh(now: now)
    }
    /// `completion` runs on the main thread when this load has landed — and also when it is
    /// superseded or abandoned, so a caller that waits on it is never left waiting forever.
    func refresh(completion: (() -> Void)? = nil, now: Date = Date()) {
        generation += 1
        let token = generation, account = accountID()
        if loadedAccount != account { reports = []; isLimited = false }
        loadedAccount = account; failed = false
        guard !account.isEmpty else { activeLoad = nil; completion?(); return }
        activeLoad = ActiveLoad(token: token, startedAt: now)
        loader(account, showConfirmedFixed) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { completion?(); return }
                self.land(result, token: token, account: account)
                completion?()
            }
        }
    }

    /// Lands one scan, whatever became of it.
    ///
    /// Every outcome passes through here — landed, superseded, account changed — so the load that
    /// claimed `activeLoad` always releases it, and only it can: a newer load's claim is its own.
    private func land(_ result: Result<LocalReportStatusSnapshot, Error>, token: Int, account: String) {
        if activeLoad?.token == token { activeLoad = nil }
        guard generation == token else { return }
        guard accountID() == account else { checkAccount(); return }
        switch result {
        case .success(let snapshot): reports = snapshot.reports; isLimited = snapshot.isLimited
        case .failure: failed = true; reports = []
        }
    }
    func mayOpenNotes(for report: LocalReportStatus) -> Bool {
        report.accountID == loadedAccount && LocalReportStatusReader.mayOpenNotes(report, accountID: accountID())
    }
    func readNotes(for report: LocalReportStatus) -> String? {
        guard report.accountID == loadedAccount else { return nil }
        return LocalReportStatusReader.readNotes(report, accountID: accountID)
    }

    /// Opens one of the report's own screenshots in the user's image viewer. Returns false when the
    /// file is no longer something this account may open, so the row can say so instead of silently
    /// doing nothing.
    /// Whether this account may still look at that screenshot — the same check `openScreenshot` makes,
    /// so the in-window lightbox is gated exactly like handing the file to another app.
    func mayOpenScreenshot(_ url: URL, for report: LocalReportStatus) -> Bool {
        report.accountID == loadedAccount
            && LocalReportStatusReader.mayOpenScreenshot(url, report: report, accountID: accountID())
    }

    @discardableResult
    func openScreenshot(_ url: URL, for report: LocalReportStatus) -> Bool {
        guard mayOpenScreenshot(url, for: report) else { return false }
        return NSWorkspace.shared.open(url)
    }
    func addInstructions(_ text: String, to report: LocalReportStatus) throws {
        guard loadedAccount == report.accountID else { throw LocalReportInstructionError.unavailable }
        try LocalReportInstructionWriter.append(text, to: report, accountID: accountID)
        refresh()
    }

    /// Save an image pasted into the instructions box, returning the line that names it.
    func attachPastedImage(_ image: NSImage, to report: LocalReportStatus) throws -> String {
        guard loadedAccount == report.accountID else { throw LocalReportInstructionError.unavailable }
        let name = try LocalReportImageWriter.save(image, to: report, accountID: accountID)
        refresh()
        return LocalReportImageWriter.reference(name)
    }
    /// Reports whose confirmation is being written right now. Only these rows disable, so one click
    /// no longer greys out the whole list (report 2026-09-14_20-07-12).
    @Published private(set) var pendingConfirmations: Set<String> = []

    /// Writes run one at a time, off the main thread: the click returns immediately and the rescan
    /// that follows no longer has to finish before the user can touch anything else.
    private static let writeQueue = DispatchQueue(label: "io.focusbear.localReportWrites")

    func setConfirmedFixed(_ confirmed: Bool, for report: LocalReportStatus,
                           completion: ((Error?) -> Void)? = nil) {
        guard loadedAccount == report.accountID else {
            completion?(LocalReportInstructionError.unavailable)
            return
        }
        guard !pendingConfirmations.contains(report.id) else { return }
        pendingConfirmations.insert(report.id)
        // The account is pinned here, on the main thread, rather than read again inside the write.
        // The writer's other guards (the folder is still this report, TASK.md unchanged, the previous
        // status unchanged) all still run; only the mid-write account re-read is replaced by this.
        let account = accountID()
        Self.writeQueue.async { [weak self] in
            var thrown: Error?
            do { try self?.confirmer(confirmed, report, account) } catch { thrown = error }
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard thrown == nil else {
                    self.pendingConfirmations.remove(report.id)
                    completion?(thrown)
                    return
                }
                // Writing the file is only half the wait. Until the rescan that follows it lands,
                // the row still shows the old status and its own untouched button — which is what
                // made a confirmed report look unconfirmed, and invited the second click whose
                // stale write then failed (report 2026-09-15_20-52-29). Hold this row's spinner,
                // and its disabled button, until the list can actually show what the click did —
                // but only for `confirmationRescanTimeout`, because the write itself is already done
                // and a rescan that never lands must not strand the row.
                var didRelease = false
                let release = { [weak self] in
                    guard !didRelease else { return }
                    didRelease = true
                    self?.pendingConfirmations.remove(report.id)
                    completion?(nil)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.confirmationRescanTimeout, execute: release)
                self.refresh(completion: release)
            }
        }
    }
}
