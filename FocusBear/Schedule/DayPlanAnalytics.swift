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
    static let taskMovedToProjectedDay = "day-plan-task-moved-to-projected-day"
    static let taskRemoved = "day-plan-task-removed"
    static let taskSettingsOpened = "day-plan-task-settings-opened"

    // Calendar-event actions
    static let eventRemoved = "day-plan-event-removed"
    static let eventSettingsOpened = "day-plan-event-settings-opened"
    /// The organiser cancelled their own event (deleted it, which the calendar account passes on to
    /// the attendees as a cancellation).
    static let eventCancelled = "day-plan-event-cancelled"
    /// An attendee declined an invitation (removed their own copy of it).
    static let eventDeclined = "day-plan-event-declined"
    /// The Fix modal's "Shorten" on a meeting — a local, one-day trim of the slot the Day Plan keeps
    /// for it (never written to the calendar).
    static let eventShortenOpened = "day-plan-event-shorten-opened"
    static let eventShortened = "day-plan-event-shortened"
    static let eventShortenCleared = "day-plan-event-shorten-cleared"

    // Navigation
    static let dayChanged = "day-plan-day-changed"

    // Editing habits / routine timing from the Day Plan (DayPlanRoutineDraft)
    static let habitEditOpened = "day-plan-habit-edit-opened"
    static let habitEdited = "day-plan-habit-edited"
    static let habitDeleted = "day-plan-habit-deleted"
    static let habitAddOpened = "day-plan-habit-add-opened"
    static let habitAdded = "day-plan-habit-added"
    /// The "Stats" button next to Edit — this habit's own streak / heat map / logged-quantity charts.
    static let habitStatsOpened = "day-plan-habit-stats-opened"
    /// The "Shorten" button — a local, one-day trim of a habit's length (never sent to the server).
    static let habitShortenOpened = "day-plan-habit-shorten-opened"
    static let habitShortened = "day-plan-habit-shortened"
    static let habitShortenCleared = "day-plan-habit-shorten-cleared"
    static let routineTimingEdited = "day-plan-routine-timing-edited"
    static let routineDraftSaved = "day-plan-routine-draft-saved"

    // Creating / editing custom routines from the Day Plan (DayPlanCustomRoutines)
    static let customRoutineManagerOpened = "day-plan-custom-routine-manager-opened"
    static let customRoutineAdded = "day-plan-custom-routine-added"
    static let customRoutineEdited = "day-plan-custom-routine-edited"
    static let customRoutineDeleted = "day-plan-custom-routine-deleted"
    static let customRoutineHabitMoved = "day-plan-custom-routine-habit-moved"

    // Calendar connection (permission grant flow)
    static let calendarConnectStarted = "day-plan-calendar-connect-started"
    static let calendarConnectSucceeded = "day-plan-calendar-connect-succeeded"
    static let calendarConnectFailed = "day-plan-calendar-connect-failed"

    static func capture(_ event: String, _ metadata: [String: Any] = [:]) {
        allApiObject.capturePosthog(event: event, metadata: metadata)
    }
}
