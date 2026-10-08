//
//  FocusStartModel.swift
//  Focus Bear
//
//  Pure value types behind the focus-session start flow. Everything here is free of AppKit, of the
//  app's globals and of UserDefaults so it can be unit-tested directly (FocusStartTests) — the
//  controller layer (FocusStartState) is what talks to the rest of the app.
//

import Foundation

/// Which accordion card of the advanced screen is open. Exactly one is open at a time; the other two
/// collapse to their summary line.
enum FocusStartCard: Int, CaseIterable {
    case duration
    case goal
    case blocking
}

/// The three strictness levels, in the vocabulary of the new design.
///
/// The stored value is unchanged: `rawValue` is the same 1/2/3 the old strictness slider wrote to
/// `kUserdefaultsLastFocusModeStrictness`, and each level maps 1:1 onto the existing
/// `_NORMAL_` / `_STRICT_` / `_SUPER_STRICT_` enum. Only the labels are new, so nothing downstream
/// (and no analytics property) changes.
enum FocusStartStrictness: Int, CaseIterable {
    case junior = 1
    case captain = 2
    case pawfessor = 3

    /// The value persisted in `kUserdefaultsLastFocusModeStrictness` and read by the old slider.
    var storedValue: Int { rawValue }

    /// Clamps any stored integer (including values written by older builds) onto a valid level.
    static func fromStored(_ value: Int) -> FocusStartStrictness {
        FocusStartStrictness(rawValue: value) ?? .junior
    }
}

/// A focus duration expressed the way the design shows it: whole hours plus minutes, or "untimed".
struct FocusStartDuration: Equatable {
    /// An untimed session is not actually open-ended — the whole app downstream (`endFocusModeTime`,
    /// the countdown, the hardware Focus Button, the server's `finish_time`) needs a finish time. It
    /// is a 12-hour session that the UI presents as ∞, which is longer than any realistic sitting.
    static let untimedSessionMinutes = 12 * 60

    /// The shortest session the app will start. The design's "0 breaks" summary implies a zero
    /// minimum, but the rest of the app treats 0 as invalid, so 1 stays the floor.
    static let minimumMinutes = 1
    /// The top of the design's 0–8 HRS slider.
    static let maximumMinutes = 8 * 60
    /// How much one press of the +/− stepper moves the session.
    static let stepMinutes = 5
    /// What a brand-new install starts on.
    static let defaultMinutes = 25

    /// Total length in minutes as the user set it, ignoring `isUntimed`.
    var minutes: Int
    /// When true the session runs for `untimedSessionMinutes` and the UI shows ∞ instead of a clock.
    var isUntimed: Bool

    init(minutes: Int, isUntimed: Bool = false) {
        self.minutes = minutes
        self.isUntimed = isUntimed
    }

    /// The length actually handed to `setFocusModeTimer` / `startFocusSession`.
    var effectiveMinutes: Int {
        isUntimed ? FocusStartDuration.untimedSessionMinutes : max(FocusStartDuration.minimumMinutes, minutes)
    }

    /// Apply a typed hours or minutes value, clamped to the slider's range.
    ///
    /// The readout was display-only, so setting 55 minutes meant eleven presses of `+`
    /// (report 2026-09-23_16-05-55: "I should be able to click on the number to change the time
    /// rather than only using +/-"). Typing is the obvious way to say a number.
    ///
    /// Anything unparseable leaves the duration alone rather than resetting it — a half-typed or
    /// mistyped field must not silently wipe a session length the user had already set.
    func settingComponent(_ component: Component, fromTyped text: String) -> FocusStartDuration {
        let digits = text.filter(\.isNumber)
        guard !digits.isEmpty, let value = Int(digits) else { return self }
        let combined: Int
        switch component {
        case .hours:
            combined = value * 60 + minutesComponent
        case .minutes:
            // 90 minutes typed into the minutes box means 90 minutes, not 30 — rolling it over is
            // what the user meant, and clamping happens once at the end.
            combined = hoursComponent * 60 + value
        }
        let clamped = min(max(combined, FocusStartDuration.minimumMinutes),
                          FocusStartDuration.maximumMinutes)
        return FocusStartDuration(minutes: clamped, isUntimed: isUntimed)
    }

    enum Component { case hours, minutes }

    var hoursComponent: Int { minutes / 60 }
    var minutesComponent: Int { minutes % 60 }

    /// The slider's position, 0…1 across the 0–8 HRS track.
    var sliderFraction: Double {
        guard FocusStartDuration.maximumMinutes > 0 else { return 0 }
        return min(1, max(0, Double(minutes) / Double(FocusStartDuration.maximumMinutes)))
    }

    /// Moves the duration by whole steps, clamped to the slider's range.
    func stepped(by steps: Int) -> FocusStartDuration {
        let raw = minutes + steps * FocusStartDuration.stepMinutes
        return FocusStartDuration(minutes: FocusStartDuration.clamp(raw), isUntimed: isUntimed)
    }

    /// Builds a duration from a slider position. #2596: the slider is fine-grained (any whole-minute
    /// value, so 17, 19… are reachable) rather than snapping to the stepper's 5-minute grid — the +/-
    /// stepper still moves in `stepMinutes` increments for quick coarse changes.
    static func fromSliderFraction(_ fraction: Double, isUntimed: Bool = false) -> FocusStartDuration {
        let raw = Int((Double(maximumMinutes) * min(1, max(0, fraction))).rounded())
        return FocusStartDuration(minutes: clamp(raw), isUntimed: isUntimed)
    }

    static func clamp(_ value: Int) -> Int {
        min(maximumMinutes, max(minimumMinutes, value))
    }
}

/// Derives the one-line summaries the design shows on a collapsed accordion card.
///
/// Kept separate from the views so the wording can be unit-tested and so both the simple and the
/// advanced screen build them identically.
struct FocusStartSummaryBuilder {
    let strings: FocusStartStrings

    /// "25 mins · 1 break" — the second half counts *micro*-breaks, which the app's minimum of one
    /// keeps at 1 whenever they are enabled (the design's "0 breaks" is below that floor).
    func durationSummary(duration: FocusStartDuration, breakCount: Int) -> String {
        let left = duration.isUntimed
            ? strings.untimedSummary
            : strings.minutesSummary.replacingOccurrences(of: FocusStartPlaceholder.count, with: "\(duration.minutes)")
        let right = (breakCount == 1 ? strings.breakSummarySingular : strings.breakSummary)
            .replacingOccurrences(of: FocusStartPlaceholder.count, with: "\(breakCount)")
        return join(left, right)
    }

    /// "3 min breaks · Micro-breaks on" — the duration card's collapsed break-settings header.
    func breakSettingsSummary(breakDurationMinutes: Int, isMicroBreaksOn: Bool) -> String {
        let left = strings.breakDurationSummary
            .replacingOccurrences(of: FocusStartPlaceholder.count, with: "\(breakDurationMinutes)")
        let right = isMicroBreaksOn ? strings.microBreaksOnSummary : strings.microBreaksOffSummary
        return join(left, right)
    }

    /// "No Goal · 0 tasks" / "Ship the release · 1 task".
    func goalSummary(goal: String, taskCount: Int) -> String {
        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        let left = trimmed.isEmpty ? strings.noGoalSummary : trimmed
        let right = (taskCount == 1 ? strings.taskSummarySingular : strings.taskSummary)
            .replacingOccurrences(of: FocusStartPlaceholder.count, with: "\(taskCount)")
        return join(left, right)
    }

    /// "Block super distracting apps/websites · Junior".
    func blockingSummary(blockListName: String, strictness: FocusStartStrictness) -> String {
        let left = blockListName.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = strings.strictnessTitle(strictness)
        return left.isEmpty ? right : join(left, right)
    }

    private func join(_ left: String, _ right: String) -> String {
        right.isEmpty ? left : "\(left) \(FocusStartSummaryBuilder.separator) \(right)"
    }

    /// The design's middle dot between the two halves of a summary line.
    static let separator = "·"
}

/// Formats the big orange "00 hr 25 min" readout and the Start button's label.
struct FocusStartDurationFormatter {
    let strings: FocusStartStrings

    /// Two-digit hours and minutes, as the design draws them. `nil` when the session is untimed —
    /// the view draws the ∞ glyph instead.
    func clockComponents(for duration: FocusStartDuration) -> (hours: String, minutes: String)? {
        guard !duration.isUntimed else { return nil }
        return (String(format: "%02d", duration.hoursComponent),
                String(format: "%02d", duration.minutesComponent))
    }

    /// "Start a 25 min session" / "Start a 1 hr 30 min session" / "Start an untimed session".
    func startButtonTitle(for duration: FocusStartDuration) -> String {
        guard !duration.isUntimed else { return strings.startUntimedButton }
        let length: String
        if duration.hoursComponent > 0 && duration.minutesComponent > 0 {
            length = "\(duration.hoursComponent) \(strings.hourUnit) \(duration.minutesComponent) \(strings.minuteUnit)"
        } else if duration.hoursComponent > 0 {
            length = "\(duration.hoursComponent) \(strings.hourUnit)"
        } else {
            length = "\(duration.minutesComponent) \(strings.minuteUnit)"
        }
        return strings.startTimedButton.replacingOccurrences(of: FocusStartPlaceholder.duration, with: length)
    }
}

/// The two halves of the flow, and the single flag that decides which one the user lands on.
///
/// Following either link ("Top Secret / Extra Powerful Options ›" on the simple screen, "‹ Go back /
/// Regular Options" on the advanced one) switches the app's geek mode — via `changeAppModeTo` so the
/// existing 75 read/write sites of `isGeekModeEnabled` all stay in step; nothing here writes the flag.
enum FocusStartMode {
    case simple
    case advanced

    static func forGeekMode(_ isGeekModeEnabled: Bool) -> FocusStartMode {
        isGeekModeEnabled ? .advanced : .simple
    }

    /// The geek-mode value the app must be switched to when the user follows this screen's link.
    var geekModeAfterFollowingLink: Bool {
        switch self {
        case .simple: return true
        case .advanced: return false
        }
    }

    var other: FocusStartMode {
        switch self {
        case .simple: return .advanced
        case .advanced: return .simple
        }
    }
}


/// Preserve the Day Plan's order, using IDs first and an unambiguous name only for older local tasks.
enum FocusStartWorkSelection {
    /// The player's vocabulary for "no tasks". Written whenever a session starts with nothing chosen.
    static let emptyQueue = "[]"

    /// The task queue a session must start with.
    ///
    /// A session inherits an existing queue in exactly one case: it is *continuing* a run that is
    /// already going and the user has not re-picked their work. Every other start — including one
    /// from the simple screen, which has no task picker at all — uses only what was chosen on the
    /// start screen. It must never fall back to the block list's persisted `lastTaskUsed`: that is
    /// the *previous* session's queue, and restoring it puts work in front of the user they never
    /// chose ("it keeps adding this old Software Development task that I didn't actually choose",
    /// report 2026-09-15_16-46-10).
    static func queueForSessionStart(chosen: String,
                                     runningQueue: String,
                                     isContinuingRun: Bool,
                                     hasChangedSelection: Bool) -> String {
        isContinuingRun && !hasChangedSelection ? runningQueue : chosen
    }

    static func sessionQueue(_ tasks: [ToDoTask], projects: [Project]) -> String {
        // Keep the existing player/server JSON contract, including to-do identities and metadata.
        // This screen must also work without the separate Focus Session UI/model feature.
        guard let encoded = try? JSONEncoder().encode(tasks),
              var rows = try? JSONSerialization.jsonObject(with: encoded) as? [[String: Any]] else { return emptyQueue }
        for (index, task) in tasks.enumerated() {
            rows[index]["duration"] = task.durationSeconds > 0 ? task.durationSeconds : 600
            rows[index]["details"] = task.details ?? ""
            rows[index]["isPlaying"] = index == 0
            rows[index]["icon"] = task.iconEmoji
            let project = projects.first { $0.id == task.project_id }
                ?? projects.first { task.synced_project_id != nil && $0.synced_project_id == task.synced_project_id }
            rows[index]["project_name"] = project?.name
        }
        guard let data = try? JSONSerialization.data(withJSONObject: rows),
              let json = String(data: data, encoding: .utf8) else { return emptyQueue }
        return json
    }

    static func topDayPlanProject(_ projects: [Project], dayPlan: [DayPlanTask]) -> Project? {
        for task in dayPlan where !task.done {
            if let id = task.projectID, let project = projects.first(where: { $0.id == id }) { return project }
            if task.projectID == nil, let name = task.project {
                let matches = projects.filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }
                if matches.count == 1 { return matches.first }
            }
        }
        return nil
    }

    static func projects(_ projects: [Project], dayPlan: [DayPlanTask]) -> [Project] {
        var result: [Project] = []
        for task in dayPlan {
            if let project = topDayPlanProject(projects, dayPlan: [task]), !result.contains(where: { $0.id == project.id }) {
                result.append(project)
            }
        }
        let seen = Set(result.map { $0.id })
        return result + projects.filter { !seen.contains($0.id) }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The chosen project's tasks first, then everything else, each group in TOP-score order.
    ///
    /// This used to order by the task's position in today's Day Plan and fall back to TOP only for
    /// ties, which put a 4.6 above a 20.2 and made the scores on the rows look meaningless
    /// (report 2026-09-11_09-27-50). The Day Plan's own order stays where the user arranged it —
    /// on the Day Plan.
    /// The page of task suggestions to fetch when nothing has been typed.
    ///
    /// Asks the SERVER for unfinished tasks only. The list used to fetch 50 tasks by SMART score and
    /// then drop the completed ones here — but the score does not care whether a task is done, so for
    /// someone with a long history a whole page could be completed tasks, leaving nothing, and "Show
    /// more tasks" fetched another page of the same (report 2026-09-23_16-07-21, follow-up
    /// 2026-09-25 15:37: "No matching unfinished tasks" under an empty search box, no project chosen,
    /// after two completed SMART loads). The server filters before paging, so every page is usable.
    static func suggestionQuery(page: Int, project: Project?) -> ToDoListQuery {
        ToDoListQuery(page: page, status: nil, sortMode: .smart,
                      projectId: project?.isSynced == true ? nil : project?.id,
                      syncedProjectId: project?.synced_project_id,
                      excludeCompleted: true)
    }

    static func tasks(_ tasks: [ToDoTask], project: Project?, dayPlan: [DayPlanTask]) -> [ToDoTask] {
        func belongs(_ task: ToDoTask) -> Bool {
            guard let project = project else { return false }
            return project.isSynced ? task.synced_project_id == project.synced_project_id : task.project_id == project.id
        }
        return ToDoSorting.sort(tasks.filter { !$0.isCompleted }, by: .smart).enumerated().sorted { lhs, rhs in
            if belongs(lhs.element) != belongs(rhs.element) { return belongs(lhs.element) }
            return lhs.offset < rhs.offset
        }.map { $0.element }
    }
}
