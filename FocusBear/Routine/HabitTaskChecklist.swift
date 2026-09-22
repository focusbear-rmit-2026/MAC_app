//
//  HabitTaskChecklist.swift
//  Focus Bear
//
//  Day Plan tasks the user dragged onto a habit, surfaced as a checklist inside the habit player.
//
//  The task↔habit association already existed before this file: the Day Plan gives every habit row
//  its own drop target keyed `"habit:<habit name>"`, and a dropped task keeps that string in
//  `DayPlanTask.blockKey` (persisted in UserDefaults `dayPlanTasksByDay`, mirrored to the backend as
//  `planned_block_key`). Nothing new is stored here — this is the key format, written down once
//  instead of being spelled out at each call site, plus the lookup and the completion mapping.
//

import Foundation

/// The Day-Plan-tasks-attached-to-a-habit relation: how the association is keyed, which tasks a
/// habit owns, and what ticking one of them completes. Pure — no store, no UI — so it can be tested
/// on plain values (`HabitTaskChecklistTests`).
enum HabitTaskChecklist {

    /// Prefix of the `DayPlanTask.blockKey` written when a task is dropped onto a habit row.
    /// Defined once, in `DayPlanBlockKey`, alongside the event and deep-work prefixes.
    static let blockKeyPrefix = DayPlanBlockKey.habitPrefix

    /// The block key a task carries once it is attached to the habit called `name`.
    static func blockKey(forHabitNamed name: String) -> String { DayPlanBlockKey.habit(named: name) }

    /// The habit name inside a habit block key, or nil for a meeting/deep-work/unassigned key.
    static func habitName(inBlockKey key: String?) -> String? {
        guard let key = key, key.hasPrefix(blockKeyPrefix) else { return nil }
        let name = String(key.dropFirst(blockKeyPrefix.count))
        return name.isEmpty ? nil : name
    }

    /// The tasks attached to the habit called `name`, in stored order. Empty for an unnamed habit —
    /// an empty name would otherwise match the degenerate `"habit:"` key.
    static func tasks(forHabitNamed name: String?, in tasks: [DayPlanTask]) -> [DayPlanTask] {
        guard let name = name, !name.isEmpty else { return [] }
        let key = blockKey(forHabitNamed: name)
        return tasks.filter { $0.blockKey == key }
    }

    /// The backend to-do a tick on this row completes, or nil when the row is a from-scratch Day Plan
    /// task that only exists locally (it still toggles — just nowhere else to tell).
    static func todoID(for task: DayPlanTask) -> String? {
        guard let id = task.sourceTaskId, !id.isEmpty else { return nil }
        return id
    }

    /// `task` with its completion flipped to `done`, or nil when it already reads that way — nil is
    /// how the caller skips a redundant write (and a redundant `PUT /to-do`).
    static func applying(done: Bool, to task: DayPlanTask) -> DayPlanTask? {
        guard task.done != done else { return nil }
        var updated = task
        updated.done = done
        return updated
    }
}

// MARK: - Store-backed convenience

extension HabitTaskChecklist {

    /// The tasks attached to `habitName` on `date`, read from the live Day Plan store.
    static func storedTasks(forHabitNamed habitName: String?, on date: Date = Date()) -> [DayPlanTask] {
        guard let habitName = habitName, !habitName.isEmpty else { return [] }
        return tasks(forHabitNamed: habitName, in: DayPlanTaskStore.shared.tasks(for: date))
    }

    /// Tick / untick one checklist row. Routed through `DayPlanTaskStore.update`, the Day Plan's own
    /// write path — it pushes the completion to the backing to-do (`PUT /to-do`) and announces it on
    /// `TodoCompletionBus`, so the To-do list, project views and Day Plan all follow. A task with no
    /// backing to-do simply flips locally.
    static func setDone(_ done: Bool, taskID: String, on date: Date = Date()) {
        guard let task = DayPlanTaskStore.shared.task(withID: taskID, for: date),
              let updated = applying(done: done, to: task) else { return }
        DayPlanAnalytics.capture(done ? DayPlanAnalytics.taskCompleted : DayPlanAnalytics.taskUncompleted,
                                 ["from_todo": todoID(for: updated) != nil, "habit_player": true])
        DayPlanTaskStore.shared.update(updated, for: date)
    }
}
