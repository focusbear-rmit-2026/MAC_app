//
//  ClassSessionChecklist.swift
//  Focus Bear
//
//  Native class-session checklist: the teacher-owned task list a student works through during a class
//  focus session. Mac parity with the Windows app (windows#1611, Core/Focus/ClassSessionChecklist.cs)
//  and the web dashboard's class-ordered-tasks.util.ts.
//
//  Before this, a class session handed the checklist to the (now headless) TodoPlayer webview, so the
//  native Focus Session tab showed nothing for teacher sessions (#2786). Now the checklist is parsed
//  from the join / `GET /class-session/current` payload straight into the native focus-session queue
//  (`focusModeTaskString`), and ticking a task reports back to the class session over its own endpoints.
//
//  This file is pure (no AppKit, no app globals) so the ordering and tick/un-tick rules are unit-tested
//  by the logic-test host.
//

import Foundation

/// Parses a class-session payload (the `POST /class-session/{id}/join` response, or
/// `GET /class-session/current`) into the native focus-session queue, applying this student's ticks.
enum ClassSessionChecklistParser {
    /// Payload keys (the backend's class-session task contract — do not rename).
    private enum Key {
        static let tasks = "tasks"
        static let version = "tasks_version"
        static let completedIds = "completed_task_ids"
        static let id = "id"
        static let title = "title"
        static let durationMinutes = "duration_minutes"
        static let order = "order"
    }

    struct Parsed: Equatable {
        var tasks: [FocusSessionTask]
        var version: Int
    }

    /// Reads `tasks` (each `{ id, title, duration_minutes, order }`), `tasks_version` and this
    /// student's `completed_task_ids`, returning the queue in the teacher's order with completed rows
    /// marked and the first incomplete task made active. Titles are HTML-unescaped. Returns nil when
    /// the payload carries no `tasks` array at all (so callers can leave the queue untouched rather
    /// than blanking it on a malformed response).
    static func parse(_ payload: [String: Any]) -> Parsed? {
        guard let rawTasks = payload[Key.tasks] as? [[String: Any]] else { return nil }
        let completedIds = Set((payload[Key.completedIds] as? [String]) ?? [])
        let version = intValue(payload[Key.version]) ?? 0

        // Sort by the teacher's `order`; entries without one keep their payload position (stable).
        let ordered = rawTasks.enumerated().sorted { lhs, rhs in
            let lo = intValue(lhs.element[Key.order]) ?? lhs.offset
            let ro = intValue(rhs.element[Key.order]) ?? rhs.offset
            if lo != ro { return lo < ro }
            return lhs.offset < rhs.offset
        }.map { $0.element }

        var tasks: [FocusSessionTask] = ordered.compactMap { raw in
            let id = (raw[Key.id] as? String) ?? stringValue(raw[Key.id])
            guard let id = id, !id.isEmpty else { return nil }
            let rawTitle = (raw[Key.title] as? String) ?? ""
            let minutes = intValue(raw[Key.durationMinutes]) ?? 0
            let seconds = minutes > 0 ? minutes * 60 : FocusSessionTask.defaultDurationSeconds
            return FocusSessionTask(
                id: id,
                title: ClassSessionChecklistText.unescapeHTML(rawTitle),
                durationSeconds: seconds,
                status: completedIds.contains(id) ? .completed : .notStarted,
                isActive: false
            )
        }

        // The first still-to-do task is the active one (the only one the student may tick next).
        if let firstIncomplete = tasks.firstIndex(where: { !$0.status.isCompleted }) {
            tasks[firstIncomplete].isActive = true
        }
        return Parsed(tasks: tasks, version: version)
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String { return Int(s) }
        return nil
    }

    private static func stringValue(_ value: Any?) -> String? {
        if let s = value as? String { return s }
        if let i = value as? Int { return String(i) }
        return nil
    }
}

/// The client-side interaction rules for a class checklist (mirror of the web's
/// class-ordered-tasks.util.ts): tasks run in the teacher's order, only the first incomplete task can
/// be ticked, only the latest completed task can be un-ticked, and nothing may be added, edited or
/// reordered. Pure so every rule is unit-tested.
enum ClassSessionChecklistRules {
    /// The one task the student may tick next: the first still-to-do task, in order.
    static func firstIncompleteId(in tasks: [FocusSessionTask]) -> String? {
        tasks.first(where: { !$0.status.isCompleted })?.id
    }

    /// The one task the student may un-tick: the most recently completed, i.e. the last completed task
    /// in the teacher's order (completions are sequential, so this is the boundary row).
    static func latestCompletedId(in tasks: [FocusSessionTask]) -> String? {
        tasks.last(where: { $0.status.isCompleted })?.id
    }

    static func canTick(id: String, in tasks: [FocusSessionTask]) -> Bool {
        firstIncompleteId(in: tasks) == id
    }

    static func canUntick(id: String, in tasks: [FocusSessionTask]) -> Bool {
        latestCompletedId(in: tasks) == id
    }

    /// Ticks `id` (when allowed): marks it completed and makes the next still-to-do task active.
    static func ticking(_ tasks: [FocusSessionTask], id: String) -> [FocusSessionTask] {
        guard canTick(id: id, in: tasks) else { return tasks }
        var updated = tasks.map { task -> FocusSessionTask in
            var t = task
            if t.id == id { t.status = .completed }
            t.isActive = false
            return t
        }
        if let next = updated.firstIndex(where: { !$0.status.isCompleted }) {
            updated[next].isActive = true
        }
        return updated
    }

    /// Un-ticks `id` (when allowed): marks it not-started and makes it the active task again.
    static func unticking(_ tasks: [FocusSessionTask], id: String) -> [FocusSessionTask] {
        guard canUntick(id: id, in: tasks) else { return tasks }
        var updated = tasks.map { task -> FocusSessionTask in
            var t = task
            if t.id == id { t.status = .notStarted }
            t.isActive = false
            return t
        }
        if let active = updated.firstIndex(where: { !$0.status.isCompleted }) {
            updated[active].isActive = true
        }
        return updated
    }

    /// "N/total done" — completed count and total, for the checklist heading.
    static func progress(in tasks: [FocusSessionTask]) -> (completed: Int, total: Int) {
        (tasks.filter { $0.status.isCompleted }.count, tasks.count)
    }
}

/// Decodes the HTML entities the backend escapes class-task titles with (`&#39;` → `'`, `&amp;` → `&`,
/// numeric decimal/hex entities, and the common named ones). Kept tiny and dependency-free — the
/// heavyweight NSAttributedString HTML path must not run on every checklist row.
enum ClassSessionChecklistText {
    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00a0}",
    ]

    static func unescapeHTML(_ input: String) -> String {
        guard input.contains("&") else { return input }
        var result = ""
        result.reserveCapacity(input.count)
        var remainder = Substring(input)
        while let amp = remainder.firstIndex(of: "&") {
            result += remainder[remainder.startIndex..<amp]
            let afterAmp = remainder[remainder.index(after: amp)...]
            guard let semicolon = afterAmp.firstIndex(of: ";"),
                  afterAmp.distance(from: afterAmp.startIndex, to: semicolon) <= 8 else {
                // Not an entity we recognise — keep the ampersand and move past it.
                result.append("&")
                remainder = afterAmp
                continue
            }
            let entity = afterAmp[afterAmp.startIndex..<semicolon]
            if let decoded = decode(entity: String(entity)) {
                result += decoded
            } else {
                result += "&" + entity + ";"
            }
            remainder = afterAmp[afterAmp.index(after: semicolon)...]
        }
        result += remainder
        return result
    }

    private static func decode(entity: String) -> String? {
        if entity.hasPrefix("#") {
            let digits = entity.dropFirst()
            let scalarValue: UInt32?
            if digits.first == "x" || digits.first == "X" {
                scalarValue = UInt32(digits.dropFirst(), radix: 16)
            } else {
                scalarValue = UInt32(digits, radix: 10)
            }
            if let value = scalarValue, let scalar = Unicode.Scalar(value) {
                return String(scalar)
            }
            return nil
        }
        return named[entity]
    }
}
