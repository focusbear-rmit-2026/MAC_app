//
//  QuickAddTaskParser.swift
//  Focus Bear
//
//  One-line "quick add" grammar for Day Plan tasks, used by the menu-bar popover's inline
//  add-task field. It is deliberately a pure value type (no AppKit, no store access) so the
//  grammar can be unit-tested — see FocusBearTests/QuickAddTaskParserTests.swift.
//
//  The `#project` and `!priority` tokens are NOT re-implemented here: this reuses the Day Plan
//  composer's own `extractProjectToken` / `extractPriorityToken` (DayPlanTasks.swift) so the two
//  entry points can never drift. The only thing added on top is a duration token, which the
//  composer has as a separate `Nm` field rather than as title syntax.
//
//  `TaskNameCommit` below is the one rule both composers ask before writing a typed name, so a line
//  that is nothing but tokens can't be committed as a blank title on either of them.
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

/// What committing a typed task name should do. Pure (no AppKit, no store access) so the rule can be
/// unit-tested on its own — see `FocusBearTests/TaskNameCommitTests.swift`.
///
/// The case that matters is `refuseTokensOnly`. Typing only tokens ("#class", "!3") used to be
/// treated as a rename to the empty string, because the trimmed text is not empty and so escaped the
/// "an empty name discards the row" branch. The title was blanked, a `#project` change then `PUT`
/// the to-do with that empty title, and the blank from-scratch row was pruned by the store's
/// `cleanup()` (and by the next "Add new task") — so the row and everything typed into it were gone,
/// with nothing to recover. A name made only of tokens is an UNFINISHED name, not an empty one:
/// refuse it, keep the text, and say what is missing. Report 2026-09-09_20-38-22.
enum TaskNameCommit: Equatable {
    /// Nothing was typed at all — the Day Plan's long-standing "an empty name discards the row".
    case discard
    /// Every word typed was a token, so stripping them leaves no name to save.
    case refuseTokensOnly
    /// A real name, with the tokens stripped off it and applied to the task.
    case save(ParsedQuickAddTask)
}

extension TaskNameCommit {
    /// The Day Plan row composer's grammar: `#project`, `!priority` and an explicit `*15` duration
    /// are title syntax. A SPELLED duration is not — that row has its own duration field, so a typed
    /// "30m" is part of the name there ("run 30m sprint"), while `*30` cannot be mistaken for prose.
    /// Project is stripped before priority, the order `saveName` has always used.
    static func forDayPlanRow(_ raw: String, knownProjects: [String], pendingProject: String? = nil) -> TaskNameCommit {
        // Accepting a leading project leaves an empty name editor, but it is still an unfinished
        // task. A blur/Tab must not interpret that state as deleting the row.
        if pendingProject != nil, raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .refuseTokensOnly
        }
        return decide(raw) {
            // `*N` comes off FIRST, for the same reason the menu composer strips its duration first:
            // `#project` can run to end-of-line for a multi-word project typed last, so "spec #HR *5"
            // otherwise files the task under a project called "HR *5" and loses the duration
            // entirely (report 2026-09-21_20-39-15). Project still precedes priority, which is the
            // order `saveName` has always used.
            let (withoutStar, minutes) = QuickAddTaskParser.extractStarDurationToken($0)
            let (withoutProject, project) = extractProjectToken(withoutStar, known: knownProjects)
            let (title, outcome) = extractPriorityToken(withoutProject)
            return ParsedQuickAddTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                      project: project,
                                      durationMinutes: minutes,
                                      outcome: outcome)
        }
    }

    /// The menu's one-line quick add, whose grammar also eats a duration token — so "30m" alone is
    /// as nameless there as "#class" is on a Day Plan row.
    static func forQuickAdd(_ raw: String, knownProjects: [String]) -> TaskNameCommit {
        decide(raw) { QuickAddTaskParser.parse($0, knownProjects: knownProjects) }
    }

    /// Whether a committed title has to be pushed to the backend. A task with no backing to-do is
    /// always offered for minting (idempotent); a backed one only when the title really changed. An
    /// unknown original (the begin-edit was never seen) counts as a change, so a rename is never lost.
    static func needsSync(originalTitle: String?, committedTitle: String, isBackedByTodo: Bool) -> Bool {
        !isBackedByTodo || originalTitle != committedTitle
    }

    private static func decide(_ raw: String, parse: (String) -> ParsedQuickAddTask) -> TaskNameCommit {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .discard }
        let parsed = parse(trimmed)
        guard !parsed.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .refuseTokensOnly
        }
        return .save(parsed)
    }
}

/// Grammar for the menu's one-line task composer:
///
///   `<title> [#project] [!priority] [*minutes | duration]`   — tokens may appear in any order
///
///   • `#project` — the Day Plan composer's own convention (`extractProjectToken`): `#word_word`
///     anywhere, or `#` to end-of-line for a multi-word project typed last.
///   • `!N` (1–5, stored on the /10 wire scale) — the composer's importance token (`extractPriorityToken`).
///   • `*N` — an explicit duration in minutes (`extractStarDurationToken`).
///   • duration — `30m`, `45min`, `2h`, `1h30`, `1h30m` (see `extractDurationToken`).
///
/// Duration is stripped FIRST, so a trailing `30m` isn't swallowed by the "`#` to end-of-line"
/// project convention; priority is stripped next for the same reason.
/// The dismissible card that explains what can be typed into a task name, asked for in report
/// 2026-09-21_07-42-02 ("show a card underneath when the user starts adding/editing a task that
/// explains the shortcuts").
///
/// Pure, so the two places that draw it — the Day Plan row's AppKit card and the menu's SwiftUI one —
/// cannot end up listing different things, and so what the card promises is assertable in a test
/// rather than only on screen. See `FocusBearTests/TaskShortcutCardTests.swift`.
enum TaskShortcutCard {

    /// Which composer the card sits under. The two do NOT share a grammar: the menu's one-line quick
    /// add also reads a SPELLED duration ("30m", "1h30m"), while on a Day Plan row that stays part of
    /// the name ("run 30m sprint") because the row has its own duration field — see
    /// `TaskNameCommit.forDayPlanRow` against `.forQuickAdd`. Listing the spelled form on the row
    /// would be promising a behaviour that does not exist there.
    enum Composer {
        case dayPlanRow
        case menuQuickAdd
    }

    static var title: String { ScheduleText.tasksShortcutsTitle }
    static var dismissTooltip: String { ScheduleText.tasksShortcutsDismiss }

    /// The lines the card lists, in the order the tokens are worth learning.
    static func hints(for composer: Composer) -> [String] {
        let shared = [ScheduleText.tasksShortcutProject,
                      ScheduleText.tasksShortcutPriority,
                      ScheduleText.tasksShortcutMinutes]
        guard composer == .menuQuickAdd else { return shared }
        return shared + [ScheduleText.tasksShortcutDurationWords]
    }
}

/// Whether the shortcut card has been dismissed — "if they close it, don't show it again" — kept per
/// account, because it is a thing a person has learned rather than a property of the Mac.
///
/// The key is rebuilt from the CURRENT user on every access instead of being a global that
/// `SettingsManager.resetAllKeys()` appends the id to once. Those keys are the bare name until the
/// account is restored, so anything read or written before login lands in a slot shared by every
/// account that has ever used this Mac and belonging to none of them — see
/// `SettingsManager.isUserScopedKey`. A signed-out session gets its own named slot here instead of
/// silently borrowing somebody's.
enum TaskShortcutCardPreference {
    /// The account segment used when nobody is signed in. A literal rather than the empty string, so
    /// it can never be the prefix of a real key and a pre-login dismissal is not inherited by the
    /// first account to sign in on this Mac.
    static let signedOutAccount = "signed-out"
    private static let keyPrefix = "dayPlanShortcutCardDismissed."

    static func key(forUserId userId: String?) -> String {
        let account = userId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return keyPrefix + (account.isEmpty ? signedOutAccount : account)
    }

    static func isDismissed(userId: String?, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key(forUserId: userId))
    }

    static func setDismissed(userId: String?, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(forUserId: userId))
    }

    /// Asked at the call site, never captured: the app restores the signed-in user asynchronously
    /// after launch, so a value read at init time would be the signed-out one for every user.
    static var currentUserId: String? { appdelegate?.user?.userId }

    static var isDismissedForCurrentUser: Bool { isDismissed(userId: currentUserId) }

    static func dismissForCurrentUser() { setDismissed(userId: currentUserId) }
}

/// Project-name completion for the one-line composer.
///
/// The composer accepted any text after `#`, so a typo quietly filed the task under a NEW project
/// instead of the one the user meant (report 2026-09-14_16-17-22). The suggestions are the same
/// project names the parser already matches against, so what is offered is exactly what would be
/// recognised.
enum QuickAddProjectSuggestions {
    static let maximumShown = 5

    /// The `#token` still being typed: everything after the LAST `#`. That mirrors the parser's own
    /// "`#` to end-of-line" rule, so a multi-word project ("#life admin") completes like any other.
    static func activeToken(in text: String) -> String? {
        guard let hash = text.lastIndex(of: "#") else { return nil }
        return String(text[text.index(after: hash)...])
    }

    /// Known projects worth offering for what has been typed so far: names that start with the token
    /// first, then names that merely contain it. An exact match needs no suggesting.
    static func matches(for text: String, knownProjects: [String], limit: Int = maximumShown) -> [String] {
        guard let token = activeToken(in: text) else { return [] }
        let needle = token.trimmingCharacters(in: .whitespaces)
        let candidates = knownProjects.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !needle.isEmpty else { return Array(candidates.prefix(limit)) }
        guard !candidates.contains(where: { $0.caseInsensitiveCompare(needle) == .orderedSame }) else { return [] }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let starting = candidates.filter { $0.range(of: needle, options: options.union(.anchored)) != nil }
        let containing = candidates.filter {
            !starting.contains($0) && $0.range(of: needle, options: options) != nil
        }
        return Array((starting + containing).prefix(limit))
    }

    /// The line with the half-typed token replaced by the chosen project.
    static func applying(_ project: String, to text: String) -> String {
        guard let hash = text.lastIndex(of: "#") else { return text }
        return String(text[..<hash]) + "#" + project
    }

    /// Accepting the suggestion at `index` — the ONE rule both ways of accepting one go through:
    /// pressing Tab with the highlight on that row, and clicking that row. Returns nil when there is
    /// nothing to accept, so Tab can fall through to its usual "move to the next control" meaning
    /// instead of being swallowed (report 2026-09-15_12-24-31).
    ///
    /// Accepting only rewrites the `#token`; it never adds the task. A line that is still nothing but
    /// a token therefore stays `isEmpty`, and Enter goes on refusing it.
    static func accepting(_ text: String, knownProjects: [String], suggestion index: Int) -> String? {
        let options = matches(for: text, knownProjects: knownProjects)
        guard options.indices.contains(index) else { return nil }
        return applying(options[index], to: text)
    }
}

enum QuickAddTaskParser {
    /// Duration used when the line carries no duration token — matches `DayPlanTask`'s own default.
    static let defaultDurationMinutes = 15
    /// Same ceiling the Day Plan's duration field clamps to.
    static let maxDurationMinutes = 24 * 60

    static func parse(_ raw: String, knownProjects: [String] = []) -> ParsedQuickAddTask {
        let (withoutStar, starMinutes) = extractStarDurationToken(raw)
        let (withoutDuration, spelledMinutes) = extractDurationToken(withoutStar)
        let minutes = starMinutes ?? spelledMinutes
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
    /// What a duration *field* should accept, as opposed to a duration token buried in a task title.
    ///
    /// The Day Plan's two duration fields did `filter(\.isNumber)`, so "4h" became 4 minutes and
    /// "1h30" became 130 (report 2026-07-15_20-25-27). `extractDurationToken` already understands
    /// every form a person types, but it deliberately ignores a **bare** number so that a title's
    /// "call Bob 5" is not eaten as a duration — in a field that is the commonest input of all, so it
    /// falls back to reading bare digits as minutes.
    static func durationMinutes(fromFieldText text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let minutes = extractDurationToken(trimmed).minutes { return minutes }
        guard let bare = Int(trimmed.filter(\.isNumber)), bare > 0 else { return nil }
        return min(bare, maxDurationMinutes)
    }

    /// `*15` — an explicit duration in minutes.
    ///
    /// Kept separate from `extractDurationToken` because the two grammars disagree about bare
    /// durations, not about this one. A Day Plan row has its own duration field, so a typed "30m"
    /// there is part of the name ("run 30m sprint"); `*30` cannot be mistaken for prose, so both
    /// grammars take it. Report 2026-09-21_07-42-02 asked for this shape.
    static func extractStarDurationToken(_ raw: String) -> (title: String, minutes: Int?) {
        let pattern = "(?:^|\\s)\\*(\\d{1,4})(?=\\s|$)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (raw.trimmingCharacters(in: .whitespaces), nil)
        }
        let ns = raw as NSString
        let matches = regex.matches(in: raw, range: NSRange(location: 0, length: ns.length))
        guard let match = matches.last,
              let minutes = Int(ns.substring(with: match.range(at: 1))), minutes > 0 else {
            return (raw.trimmingCharacters(in: .whitespaces), nil)
        }
        var title = ns.replacingCharacters(in: match.range, with: " ")
        title = title.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
        return (title, min(minutes, maxDurationMinutes))
    }

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
