//
//  DayPlanAnalytics.swift
//  Focus Bear
//
//  Single registry of Day Plan PostHog event names + a capture helper, so the event strings live in
//  one place. NEVER rename the string values — that breaks event history in PostHog; only rename the
//  Swift constants. Fired through allApiObject.capturePosthog.
//

import Foundation

enum DayPlanAnalytics {
    // Task actions
    static let taskAdded = "day-plan-task-added"
    static let taskCompleted = "day-plan-task-completed"
    static let taskUncompleted = "day-plan-task-uncompleted"
    static let taskSnoozed = "day-plan-task-snoozed"
    static let taskRemoved = "day-plan-task-removed"
    static let taskSettingsOpened = "day-plan-task-settings-opened"

    // Calendar-event actions
    static let eventRemoved = "day-plan-event-removed"
    static let eventSettingsOpened = "day-plan-event-settings-opened"

    // Navigation
    static let dayChanged = "day-plan-day-changed"

    // Editing habits / routine timing from the Day Plan (DayPlanRoutineDraft)
    static let habitEditOpened = "day-plan-habit-edit-opened"
    static let habitEdited = "day-plan-habit-edited"
    static let habitDeleted = "day-plan-habit-deleted"
    static let habitAddOpened = "day-plan-habit-add-opened"
    static let habitAdded = "day-plan-habit-added"
    static let routineTimingEdited = "day-plan-routine-timing-edited"
    static let routineDraftSaved = "day-plan-routine-draft-saved"

    // Calendar connection (permission grant flow)
    static let calendarConnectStarted = "day-plan-calendar-connect-started"
    static let calendarConnectSucceeded = "day-plan-calendar-connect-succeeded"
    static let calendarConnectFailed = "day-plan-calendar-connect-failed"

    static func capture(_ event: String, _ metadata: [String: Any] = [:]) {
        allApiObject.capturePosthog(event: event, metadata: metadata)
    }
}
