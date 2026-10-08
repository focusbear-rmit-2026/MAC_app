//
//  Log.swift
//  FocusBear
//
//  Created by Manish Jain on 23/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation

class Log: TextOutputStream {
    static let queue = DispatchQueue(label: "logQueue")

    static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    static var log = Log()
    private init() {}

    func write(_ string: String) {
        guard let log = DebugLogsURL, let data = string.data(using: .utf8) else { return }

        Self.queue.async {
            // The deprecated non-throwing FileHandle seek/write raise an Objective-C
            // NSException on failure (e.g. NSFileHandleOperationException when the volume
            // is full) that Swift cannot catch — it hits the terminate handler and aborts
            // the whole app. Use the throwing API and swallow errors so logging can never
            // crash the process. (Root cause of the SIGABRT-on-full-disk crashes.)
            guard let handle = try? FileHandle(forWritingTo: log) else {
                LogFilePermissions.createPrivateFile(at: log, contents: data)
                return
            }
            defer { try? handle.close() }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } catch {
                // out of space / write error — drop this line rather than abort
            }
        }
    }
}

func addLog(text: String) {
    Log.queue.async {
        let now = Log.formatter.string(from: Date())
        print("\(now) - \(LogRedactor.redact(LogContentScrubber.scrubEntry(text)))", to: &Log.log)
    }
}

/// The log holds domains, app names and older builds' lines. Owner-only permissions don't stop other
/// processes running as the user, but they do stop other accounts on the Mac reading it.
enum LogFilePermissions {
    static let folderMode: Int16 = 0o700
    static let fileMode: Int16 = 0o600

    static func createPrivateFile(at url: URL, contents: Data) {
        FileManager.default.createFile(atPath: url.path, contents: contents,
                                       attributes: [.posixPermissions: fileMode])
    }

    /// Older builds created the folder 0755 and the files 0644.
    static func tighten(folder: URL) {
        let fileManager = FileManager.default
        try? fileManager.setAttributes([.posixPermissions: folderMode], ofItemAtPath: folder.path)
        let files = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? fileManager.setAttributes([.posixPermissions: fileMode], ofItemAtPath: file.path)
        }
    }
}

/// Older builds logged access tokens (`accessToken is:- …`), password fields, email addresses and
/// signed-URL credentials in plaintext, plus whole settings / block-list / AI-request dumps, current
/// to-do titles, deep-link query text and Focus Button goals. The log files stay on disk for weeks
/// and travel with support uploads and debug reports. Rewrites every existing log file once through
/// `LogContentScrubber` and `LogRedactor`; version 2 adds the content rules and the wider secret rules,
/// version 3 cuts the pages and window titles they logged down to the domain (`LogPrivacy.site`).
///
/// Both passes are idempotent, so an interrupted pass simply runs again next launch; a file is only
/// replaced when its content changed, and keeps its creation date because rotation is keyed on it.
enum LegacyLogScrubber {
    static let completedVersionKey = "kUserdefaultsLegacyLogsScrubbedVersion"
    static let version = 3
    static let logExtension = "txt"

    static func scrubIfNeeded(folder: URL, currentLog: URL?, defaults: UserDefaults = .standard) {
        guard defaults.integer(forKey: completedVersionKey) < version else { return }
        DispatchQueue.global(qos: .utility).async {
            let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
            var scrubbed = 0
            for file in files where file.pathExtension == logExtension {
                // The live log is appended to on Log.queue; rewriting it anywhere else would race a write.
                let changed = file.standardizedFileURL == currentLog?.standardizedFileURL
                    ? Log.queue.sync { scrub(file: file) }
                    : scrub(file: file)
                if changed { scrubbed += 1 }
            }
            defaults.set(version, forKey: completedVersionKey)
            addLog(text: "[at-rest] scrubbed secrets from \(scrubbed) older log file(s)")
        }
    }

    /// Returns true when the file held something to redact and was rewritten.
    @discardableResult
    static func scrub(file: URL) -> Bool {
        let fileManager = FileManager.default
        guard let data = try? Data(contentsOf: file) else { return false }
        let original = String(decoding: data, as: UTF8.self)
        let redacted = LogRedactor.redact(LogContentScrubber.scrub(original))
        guard redacted != original else { return false }
        let creationDate = (try? fileManager.attributesOfItem(atPath: file.path))?[.creationDate] as? Date
        let staging = file.deletingLastPathComponent().appendingPathComponent(".\(file.lastPathComponent).scrub")
        guard fileManager.createFile(atPath: staging.path, contents: Data(redacted.utf8),
                                     attributes: [.posixPermissions: LogFilePermissions.fileMode]) else { return false }
        do {
            _ = try fileManager.replaceItemAt(file, withItemAt: staging)
        } catch {
            try? fileManager.removeItem(at: staging)
            return false
        }
        var attributes: [FileAttributeKey: Any] = [.posixPermissions: LogFilePermissions.fileMode]
        if let creationDate { attributes[.creationDate] = creationDate }
        try? fileManager.setAttributes(attributes, ofItemAtPath: file.path)
        return true
    }
}

/// Rewrites the user's own content in the shapes log calls have written it (whole-structure dumps,
/// `currentTask … Optional("…")`, deep links and request paths with query text, Focus Button protocol
/// lines, the pages and window titles the blocker looked at) the way `LogPrivacy` describes it.
///
/// Call sites describe their content themselves; this is the net under them. `addLog` runs every
/// entry through it, so a call site in another branch that still logs the old way is caught, and
/// `LegacyLogScrubber` runs older log files through it once.
enum LogContentScrubber {
    static let removedDump = "<removed>"
    private static let entryStart = regex(#"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} - "#)
    /// Log calls that dumped a whole settings, device-settings, block-list or AI-request structure,
    /// often across many lines. The label stays; the dump goes.
    private static let dumpLabel = regex(
        #"(?:json is:- |User Local Device Settings:- |json data for api is:- |syncWithDevices payload is:- |Blocking schedule (?:added|updated):- |Read Custom Blocking Schedule Data: )"#)
    private static let currentTask = regex(#"(current ?[Tt]ask[^:\n]*:-?\s*)Optional\("((?:[^"\\]|\\.)*)"\)"#)
    /// Deep links run to the end of the line: older builds logged them decoded, spaces and all.
    private static let deepLinkOrRequestPath = regex(#"(focusbear://.*$|api (?:todo|notes|stats|voice) [A-Z]+ \S+)"#)
    private static let focusButtonProtocol = regex(#"(FocusButton: (?:SendCmd >> |HandleLine << ))(.*)$"#)
    /// A page address anywhere in a line. Focus Bear's own services stay readable: they are requests
    /// the app made, not pages the user looked at, and their paths are what an API bug report needs.
    private static let browsingURL = regex(#"\b(?:https?|file|chrome|chrome-extension|edge|devtools|view-source)://[^\s"'<>]+"#)
    /// Punctuation a log call wrote straight after a URL (`for https://x/y: superseded`).
    private static let urlTrailingPunctuation = CharacterSet(charactersIn: ".,:;)]")
    /// The blocker logs most pages without a scheme (`youtube.com/watch?v=…`), so those are found by
    /// the label in front of them. The value ends at a space, a comma, or `: ` (a label after it).
    private static let labelledBareURL = regex(
        #"((?:focusTryToBlockUnwantedUrl|focusBlockUnwantedUrl|blockAlwaysBlockedUrl|blockActivityBlockedUrl|checked chatGPTIsURLSafe|checked checkUrlFromAiWithNewIntention|current url is|video url is) ?:- |relevance verdict (?:discarded|applied) for |relevance verdict dropped: checked | but current page is |\burl: |auto-opening |(?:reprompt scheduled for|not re-showing) url:)([^\s,]+?)(?=: |,|\s|$)"#)
    private static let aiBuddyItem = regex(#"(showAiBlockBuddyWindow item=)(.*?)( isApp=false)"#)
    /// Window titles hold quotes of their own, so the shapes logged with text after the title are
    /// matched to that text rather than to the next quote.
    private static let anchoredWindowTitle = regex(#"((?:window title|claude chat title:) )'(.*)'( added to AI context| frame=)"#)
    private static let quotedWindowTitle = regex(#"\b((?:window|chat|tab) title:?\s*)(['"])(.*?)\2"#)
    /// The discarded-verdict detail ends `liveTitle=<title> keyTitle=<title>`, both free text.
    private static let verdictTitles = regex(#"( liveTitle=)(.*?)( keyTitle=)(.*)$"#)
    private static let missingValue = "nil"

    /// One log call's text, as `addLog` receives it: no timestamp, possibly several lines.
    static func scrubEntry(_ text: String) -> String {
        if let end = dumpEnd(in: text) { return String(text[..<end]) + removedDump }
        return text.components(separatedBy: "\n").map(scrubLine).joined(separator: "\n")
    }

    /// A whole log file: timestamped entries, a dump's continuation lines going with its entry.
    static func scrub(_ text: String) -> String {
        var lines: [String] = []
        var isInsideDump = false
        text.enumerateLines { line, _ in
            let startsEntry = matches(entryStart, line)
            if isInsideDump && !startsEntry { return }
            isInsideDump = false
            if let end = dumpEnd(in: line) {
                lines.append(String(line[..<end]) + removedDump)
                isInsideDump = true
                return
            }
            lines.append(scrubLine(line))
        }
        let trailingNewline = text.hasSuffix("\n") ? "\n" : ""
        return lines.joined(separator: "\n") + trailingNewline
    }

    /// Where a dump label ends, unless what follows is already a description (`<dictionary keys=…>`,
    /// `<removed>`): current call sites describe their payloads, and a second pass must change nothing.
    private static func dumpEnd(in text: String) -> String.Index? {
        guard let end = firstMatchEnd(of: dumpLabel, in: text) else { return nil }
        let rest = text[end...].trimmingCharacters(in: .whitespacesAndNewlines)
        return LogPrivacy.isDescription(rest) ? nil : end
    }

    private static func scrubLine(_ line: String) -> String {
        var result = line
        if result.contains("Optional(\"") {
            result = replace(currentTask, in: result) { groups in groups[1] + LogPrivacy.text(groups[2]) }
        }
        if result.contains("?") {
            result = replace(deepLinkOrRequestPath, in: result) { groups in LogPrivacy.url(groups[1]) }
        }
        if result.contains("FocusButton: ") {
            result = replace(focusButtonProtocol, in: result) { groups in groups[1] + FocusButtonLogFormat.describe(groups[2]) }
        }
        return scrubWindowTitles(in: scrubBrowsingURLs(in: result))
    }

    /// Pages become `LogPrivacy.site`: the domain stays, the path, query and fragment go.
    private static func scrubBrowsingURLs(in line: String) -> String {
        var result = line
        if result.contains("://") {
            result = replace(browsingURL, in: result) { groups in describeURLKeepingPunctuation(groups[0]) }
        }
        result = replace(labelledBareURL, in: result) { groups in groups[1] + describeSite(groups[2]) }
        if result.contains("showAiBlockBuddyWindow item=") {
            result = replace(aiBuddyItem, in: result) { groups in groups[1] + describeSite(groups[2]) + groups[3] }
        }
        return result
    }

    private static func describeURLKeepingPunctuation(_ match: String) -> String {
        var url = Substring(match)
        while let last = url.unicodeScalars.last, urlTrailingPunctuation.contains(last) { url = url.dropLast() }
        let trailing = match.dropFirst(url.count)
        if LogPrivacy.isAppOwned(String(url)) { return match }
        return LogPrivacy.site(String(url)) + trailing
    }

    private static func scrubWindowTitles(in line: String) -> String {
        var result = line
        guard result.range(of: "title", options: .caseInsensitive) != nil else { return result }
        result = replace(anchoredWindowTitle, in: result) { groups in groups[1] + LogPrivacy.text(groups[2]) + groups[3] }
        result = replace(quotedWindowTitle, in: result) { groups in groups[1] + LogPrivacy.text(groups[3]) }
        result = replace(verdictTitles, in: result) { groups in
            groups[1] + describeTitle(groups[2]) + groups[3] + describeTitle(groups[4])
        }
        return result
    }

    /// `nil` says the browser read failed, and a description is already safe: both stay as they are.
    private static func describeTitle(_ value: String) -> String {
        value == missingValue || LogPrivacy.isDescription(value) ? value : LogPrivacy.text(value)
    }

    private static func describeSite(_ value: String) -> String {
        value == missingValue ? value : LogPrivacy.site(value)
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // The patterns are literals; failing to compile one is a programming error.
        try! NSRegularExpression(pattern: pattern)
    }

    private static func matches(_ expression: NSRegularExpression, _ line: String) -> Bool {
        expression.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
    }

    private static func firstMatchEnd(of expression: NSRegularExpression, in line: String) -> String.Index? {
        guard let match = expression.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { return nil }
        return Range(match.range, in: line)?.upperBound
    }

    private static func replace(_ expression: NSRegularExpression, in line: String,
                                with replacement: ([String]) -> String) -> String {
        let nsLine = line as NSString
        let matches = expression.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        guard !matches.isEmpty else { return line }
        let result = NSMutableString(string: line)
        for match in matches.reversed() {
            let groups = (0..<match.numberOfRanges).map { index -> String in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : nsLine.substring(with: range)
            }
            result.replaceCharacters(in: match.range, with: replacement(groups))
        }
        return result as String
    }
}
