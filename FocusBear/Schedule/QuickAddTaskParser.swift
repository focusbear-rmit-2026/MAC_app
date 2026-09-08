//
//  QuickAddTaskParser.swift
//  Focus Bear
//
//  One-line "quick add" grammar for Day Plan tasks, used by the menu-bar popover's inline
//  add-task field. It is deliberately a pure value type (no AppKit, no store access) so the
//  grammar can be unit-tested — see FocusBearTests/QuickAddTaskParserTests.swift.
//
//  The `#project` and `*priority` tokens are NOT re-implemented here: this reuses the Day Plan
//  composer's own `extractProjectToken` / `extractPriorityToken` (DayPlanTasks.swift) so the two
//  entry points can never drift. The only thing added on top is a duration token, which the
//  composer has as a separate `Nm` field rather than as title syntax.
//

import Foundation

/// What a quick-add line was understood to mean. `durationMinutes` is nil when the line carried no
/// duration token, so the caller can apply its own default rather than guessing one here.
struct ParsedQuickAddTask: Equatable {
    var title: String
    var project: String?
    var durationMinutes: Int?
    var outcome: Int?

    /// True when the line has nothing worth adding (only tokens, or blank).
    var isEmpty: Bool { title.isEmpty }
}

/// Grammar for the menu's one-line task composer:
///
///   `<title> [#project] [*priority] [duration]`   — tokens may appear in any order
///
///   • `#project` — the Day Plan composer's own convention (`extractProjectToken`): `#word_word`
///     anywhere, or `#` to end-of-line for a multi-word project typed last.
///   • `*N` (1–10) — the composer's importance token (`extractPriorityToken`).
///   • duration — `30m`, `45min`, `2h`, `1h30`, `1h30m` (see `extractDurationToken`).
///
/// Duration is stripped FIRST, so a trailing `30m` isn't swallowed by the "`#` to end-of-line"
/// project convention; priority is stripped next for the same reason.
enum QuickAddTaskParser {
    /// Duration used when the line carries no duration token — matches `DayPlanTask`'s own default.
    static let defaultDurationMinutes = 15
    /// Same ceiling the Day Plan's duration field clamps to.
    static let maxDurationMinutes = 24 * 60

    static func parse(_ raw: String, knownProjects: [String] = []) -> ParsedQuickAddTask {
        let (withoutDuration, minutes) = extractDurationToken(raw)
        let (withoutPriority, outcome) = extractPriorityToken(withoutDuration)
        let (title, project) = extractProjectToken(withoutPriority, known: knownProjects)
        return ParsedQuickAddTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                  project: project,
                                  durationMinutes: minutes,
                                  outcome: outcome)
    }

    /// Pull a standalone duration token out of a typed line and strip it:
    /// `"write report 1h30"` → `("write report", 90)`. Recognised forms (case-insensitive):
    /// `Nm` / `Nmin` / `Nmins` (minutes), `Nh` / `Nhr` / `Nhrs` (hours), `NhM` / `NhMm` (hours+minutes).
    /// The token must stand alone (whitespace or line edge on both sides) so "swimming" or a bare
    /// number in the title is never mistaken for one. The LAST such token wins, mirroring
    /// `extractPriorityToken`. Result is clamped to 1...`maxDurationMinutes`; `0m` is not a duration
    /// and is left in the title.
    static func extractDurationToken(_ raw: String) -> (title: String, minutes: Int?) {
        let pattern = "(?:^|\\s)(?:(\\d{1,2})\\s*h(?:rs?)?\\s*(\\d{1,2})\\s*m?(?:ins?)?|(\\d{1,2})\\s*h(?:rs?)?|(\\d{1,4})\\s*m(?:ins?)?)(?=\\s|$)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return (raw.trimmingCharacters(in: .whitespaces), nil)
        }
        let ns = raw as NSString
        let matches = regex.matches(in: raw, range: NSRange(location: 0, length: ns.length))
        guard let match = matches.last else { return (raw.trimmingCharacters(in: .whitespaces), nil) }

        func group(_ i: Int) -> Int? {
            let r = match.range(at: i)
            return r.location == NSNotFound ? nil : Int(ns.substring(with: r))
        }
        let total: Int
        if let h = group(1), let m = group(2) {
            total = h * 60 + m
        } else if let h = group(3) {
            total = h * 60
        } else if let m = group(4) {
            total = m
        } else {
            return (raw.trimmingCharacters(in: .whitespaces), nil)
        }
        guard total > 0 else { return (raw.trimmingCharacters(in: .whitespaces), nil) }

        var title = ns.replacingCharacters(in: match.range, with: " ")
        title = title.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
        return (title, min(total, maxDurationMinutes))
    }

    /// Compact duration label for the parse-preview chip: `45m`, `2h`, `1h 30m`. Unit letters match
    /// the Day Plan's own duration field, which also renders bare `Nm`.
    static func durationLabel(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }        // i18n-ignore: numeric duration token, same format as the Day Plan field
        if m == 0 { return "\(h)h" }        // i18n-ignore: numeric duration token
        return "\(h)h \(m)m"                // i18n-ignore: numeric duration token
    }
}
