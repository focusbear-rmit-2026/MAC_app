//
//  TodoCompletionSync.swift
//  Focus Bear
//
//  The Day Plan and the native To-do list are two views of the SAME backend to-do
//  (`DayPlanTask.sourceTaskId` is the to-do's id), so ticking one has to tick the other at once —
//  previously each only found out on its next refresh. The screen the user acted on announces the
//  change here; every other screen applies it to its own cache and never announces it again. The
//  appliers no-op when their copy already carries the new state, which is what stops a change from
//  bouncing back and forth (and what keeps the completion banner counting a tick exactly once).
//

import Foundation

/// One announcement that a backend to-do was completed or uncompleted somewhere in the app.
enum TodoCompletionBus {
    static let notificationName = Notification.Name("io.focusbear.todoCompletionChanged")
    private static let todoIDKey = "todoID"
    private static let completedKey = "completed"

    struct Change: Equatable {
        let todoID: String
        let completed: Bool
    }

    /// Announce a completion the user just made. Only the screen the change ORIGINATED on posts;
    /// appliers must not, or the two stores would answer each other forever.
    static func post(todoID: String, completed: Bool) {
        guard !todoID.isEmpty else { return }
        let userInfo: [String: Any] = [todoIDKey: todoID, completedKey: completed]
        let send = { NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo) }
        if Thread.isMainThread { send() } else { DispatchQueue.main.async(execute: send) }
    }

    static func change(in notification: Notification) -> Change? {
        guard let info = notification.userInfo,
              let todoID = info[todoIDKey] as? String,
              let completed = info[completedKey] as? Bool else { return nil }
        return Change(todoID: todoID, completed: completed)
    }

    /// Observe on the main queue. Keep the returned token for as long as the handler should run, and
    /// hand it to `NotificationCenter.removeObserver` when done.
    static func observe(_ handler: @escaping (Change) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: .main) { notification in
            guard let change = change(in: notification) else { return }
            handler(change)
        }
    }
}

/// The pure half of the Day Plan's side of the sync: which stored entries a to-do's completion
/// touches, and what they become. Kept free of the store so it can be tested on plain values.
enum TodoCompletionMapping {
    /// `byDay` (the Day Plan's storage, keyed `yyyy-MM-dd`) with every copy of `todoID` set to
    /// `completed`, or nil when nothing changes — nil is how the caller tells an echo of its own
    /// change from a real one. A to-do normally sits on exactly one day, but a stale duplicate must
    /// not be left half-ticked, so every copy is updated rather than the first one found.
    static func applying(completed: Bool, toSourceTaskId todoID: String,
                         in byDay: [String: [DayPlanTask]]) -> [String: [DayPlanTask]]? {
        var updated = byDay
        var changed = false
        for (day, tasks) in byDay {
            for (index, task) in tasks.enumerated() where task.sourceTaskId == todoID && task.done != completed {
                updated[day]?[index].done = completed
                changed = true
            }
        }
        return changed ? updated : nil
    }
}

/// The backend's `todo-completed` Pusher event: a to-do was marked complete SOMEWHERE — this Mac, the
/// phone, the web dashboard — broadcast on the user's own `private-<user_id>` channel.
///
/// The string keys mirror the backend's `TodoCompletedEventPayload` and are a wire contract shared
/// with Windows and mobile: change the constants' names freely, never their values.
enum TodoCompletedPusherEvent {
    /// Pusher event name, bound in `pusherEvents.startEventNotifications()`.
    static let eventName = "todo-completed"

    private static let todoIDKey = "todo_id"
    private static let isCompletedKey = "is_completed"
    private static let completedAtKey = "completed_at"

    struct Payload: Equatable {
        let todoID: String
        let isCompleted: Bool
        /// ISO-8601 instant the backend persisted the completion. Carried for logging/diagnostics —
        /// the app has nowhere to show it yet.
        let completedAt: String?
    }

    /// Decode an event body. Returns nil for anything without a usable to-do id, so a malformed or
    /// future-shaped payload is ignored rather than mutating state from half-understood data.
    /// `is_completed` defaults to true when absent: the event name already says what happened, and a
    /// missing flag must not silently UN-tick a task.
    static func payload(fromJSON json: String?) -> Payload? {
        guard let data = json?.data(using: .utf8),
              let body = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
              let todoID = body[todoIDKey] as? String, !todoID.isEmpty else { return nil }
        return Payload(todoID: todoID,
                       isCompleted: body[isCompletedKey] as? Bool ?? true,
                       completedAt: body[completedAtKey] as? String)
    }

    /// Route a received event into the app. Announcing on `TodoCompletionBus` is deliberately the ONLY
    /// effect: both `DayPlanTaskStore` and `ToDoStore` apply a bus change straight to their own caches
    /// and never write it back, so a completion that arrived FROM the server can't echo a `PUT /to-do`
    /// at it — which is what would loop. Anything that needs the server told must not be wired here.
    /// Returns whether the event was understood, for the caller's log line and for tests.
    @discardableResult
    static func handle(eventData: String?,
                       announce: (String, Bool) -> Void = TodoCompletionBus.post) -> Bool {
        guard let payload = payload(fromJSON: eventData) else { return false }
        announce(payload.todoID, payload.isCompleted)
        return true
    }
}
