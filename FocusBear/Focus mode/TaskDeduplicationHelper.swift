//
//  TaskDeduplicationHelper.swift
//  Focus Bear
//
//  Utility for deduplicating AI-suggested tasks by name (#1679).
//  Prevents creating a new task when one with the same name already exists.
//

import Foundation

/// Helpers for looking up an existing task by name in a flat task list.
enum TaskDeduplicationHelper {

    /// Finds the first task in `tasks` whose `title` matches `name`
    /// using a case-insensitive comparison that ignores surrounding whitespace.
    ///
    /// - Parameters:
    ///   - name:  The task name to search for (e.g. an AI-suggested title).
    ///   - tasks: The collection of task dictionaries fetched from the API.
    /// - Returns: The matching `NSDictionary` and its index, or `nil` if not found.
    static func existingTask(
        named name: String,
        in tasks: [NSDictionary]
    ) -> (task: NSDictionary, index: Int)? {
        let normalised = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for (index, task) in tasks.enumerated() {
            let title = task.value(forKey: "title") as? String ?? ""
            if title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalised {
                return (task, index)
            }
        }
        return nil
    }
}
