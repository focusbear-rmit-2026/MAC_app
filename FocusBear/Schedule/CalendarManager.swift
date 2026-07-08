//
//  CalendarManager.swift
//  Focus Bear
//
//  Thin EventKit wrapper for the Schedule view: permission state, access request,
//  and today's timed meetings. Deployment target is macOS 11, so it falls back to
//  the legacy requestAccess API and uses requestFullAccessToEvents on macOS 14+.
//

import Foundation
import EventKit
import AppKit

final class CalendarManager {

    static let shared = CalendarManager()
    private let store = EKEventStore()
    private init() {}

    enum Access { case notDetermined, denied, authorized }

    var access: Access {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: return .notDetermined
        case .denied, .restricted: return .denied
        case .authorized: return .authorized       // also covers .fullAccess (same raw value on macOS 14+)
        @unknown default: return .denied            // e.g. .writeOnly — can't read events
        }
    }

    /// Show the "connect your calendar" banner whenever we can't read events yet.
    func shouldShowPermissionBanner() -> Bool { access != .authorized }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        // The system TCC permission dialog is a separate process shown at the normal window level.
        // Focus Bear's window can sit at an elevated level (floating / status-bar during routines and
        // full screen), which covers the dialog so the user never sees it and the app looks stuck.
        // Drop any elevated windows to normal while the prompt is up, then restore once answered.
        let elevated = NSApp.windows.filter { $0.level.rawValue > NSWindow.Level.normal.rawValue }
        let savedLevels = elevated.map { (window: $0, level: $0.level) }
        elevated.forEach { $0.level = .normal }
        NSApp.activate(ignoringOtherApps: true)
        let restore = { savedLevels.forEach { $0.window.level = $0.level } }

        let handler: (Bool, Error?) -> Void = { granted, _ in
            DispatchQueue.main.async { restore() }
            completion(granted)
        }
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents(completion: handler)
        } else {
            store.requestAccess(to: .event, completion: handler)
        }
    }

    /// Re-query Calendar authorization by issuing an access request. macOS keeps returning a stale
    /// `.denied` from `authorizationStatus` to a *running* process after the user grants access in
    /// System Settings; an explicit (re-)request refreshes the in-process status. No system dialog
    /// appears for an already-decided status, so this is safe to call while we're showing the banner.
    /// `completion` runs on the main thread once the status is refreshed.
    func revalidateAccess(_ completion: @escaping () -> Void) {
        let handler: (Bool, Error?) -> Void = { _, _ in DispatchQueue.main.async { completion() } }
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents(completion: handler)
        } else {
            store.requestAccess(to: .event, completion: handler)
        }
    }

    /// Today's timed meetings the user is actually attending — all-day, cancelled, declined,
    /// tentative, not-yet-responded and user-dismissed events are excluded — sorted by start.
    func todaysMeetings() -> [ScheduleMeetingInput] { meetings(for: Date()) }

    /// Non-declined, non-all-day, non-dismissed meetings for the given day (includes events the
    /// user hasn't RSVP'd to yet).
    func meetings(for day: Date) -> [ScheduleMeetingInput] {
        guard access == .authorized else { return [] }
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: day)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        let dismissed = dismissedEventIDs
        let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.status != .canceled && $0.endDate > $0.startDate }
            .filter { !hasDeclined($0) }
            .filter { !dismissed.contains(eventKey($0)) }
            .map { ScheduleMeetingInput(id: eventKey($0), title: title(for: $0), start: $0.startDate, end: $0.endDate) }
            .sorted { $0.start < $1.start }
    }

    /// Hide only meetings the user has explicitly declined. Accepted, tentative and
    /// not-yet-responded (no RSVP) events are all shown.
    private func hasDeclined(_ event: EKEvent) -> Bool {
        if event.organizer?.isCurrentUser == true { return false }
        guard let attendees = event.attendees, let me = attendees.first(where: { $0.isCurrentUser }) else { return false }
        return me.participantStatus == .declined
    }

    private func eventKey(_ event: EKEvent) -> String {
        event.eventIdentifier ?? "\(event.title ?? "")|\(event.startDate.timeIntervalSince1970)"
    }

    private func title(for event: EKEvent) -> String {
        let name = (event.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return "📅 " + (name.isEmpty ? ScheduleText.meetingDefaultTitle : name)
    }

    // MARK: - Creating events

    /// A calendar the user can write new events into.
    struct WritableCalendar { let id: String; let title: String }

    /// Calendars that accept new events (excludes read-only subscribed/holiday calendars),
    /// with the user's default-for-new-events calendar floated to the front.
    func writableCalendars() -> [WritableCalendar] {
        guard access == .authorized else { return [] }
        let defaultID = store.defaultCalendarForNewEvents?.calendarIdentifier
        let cals = store.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .map { WritableCalendar(id: $0.calendarIdentifier, title: $0.title) }
        return cals.sorted { a, b in
            if a.id == defaultID { return true }
            if b.id == defaultID { return false }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    /// How often an event repeats. Maps to an EKRecurrenceRule.
    enum Recurrence: Int, CaseIterable {
        case none, daily, weekly, monthly
        var frequency: EKRecurrenceFrequency? {
            switch self {
            case .none: return nil
            case .daily: return .daily
            case .weekly: return .weekly
            case .monthly: return .monthly
            }
        }
    }

    /// Create a timed event in the given calendar (or the default if `calendarID` is nil/unknown)
    /// and save it to the system store, where it syncs to the user's calendar provider. Returns
    /// true on success.
    /// Returns the new event's identifier on success, nil on failure (so callers can key
    /// per-event settings like colour to it).
    @discardableResult
    func createEvent(title: String, start: Date, end: Date, calendarID: String?,
                     recurrence: Recurrence = .none, notes: String? = nil) -> String? {
        guard access == .authorized else { return nil }
        guard let calendar = calendarID.flatMap({ store.calendar(withIdentifier: $0) })
                ?? store.defaultCalendarForNewEvents else { return nil }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.calendar = calendar
        if let notes = notes, !notes.isEmpty { event.notes = notes }
        applyRecurrence(recurrence, to: event)
        do {
            try store.save(event, span: recurrence == .none ? .thisEvent : .futureEvents)
            return event.eventIdentifier
        } catch {
            return nil
        }
    }

    /// The EKEvent for a schedule meeting's id (its eventIdentifier), if still in the store.
    func event(withID id: String) -> EKEvent? {
        guard access == .authorized else { return nil }
        return store.event(withIdentifier: id)
    }

    /// The current recurrence of an event (first rule's frequency), for pre-filling the edit form.
    func recurrence(of event: EKEvent) -> Recurrence {
        switch event.recurrenceRules?.first?.frequency {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        default: return .none
        }
    }

    /// Update an existing event's title/time/calendar/recurrence and save. For a recurring event
    /// the change spans this and future occurrences; otherwise just the event. Returns true on success.
    @discardableResult
    func updateEvent(id: String, title: String, start: Date, end: Date,
                     calendarID: String?, recurrence: Recurrence, notes: String? = nil) -> Bool {
        guard access == .authorized, let event = store.event(withIdentifier: id) else { return false }
        event.title = title
        event.startDate = start
        event.endDate = end
        if let notes = notes { event.notes = notes.isEmpty ? nil : notes }
        if let cal = calendarID.flatMap({ store.calendar(withIdentifier: $0) }) { event.calendar = cal }
        applyRecurrence(recurrence, to: event)
        let recurring = recurrence != .none || (event.recurrenceRules?.isEmpty == false)
        do {
            try store.save(event, span: recurring ? .futureEvents : .thisEvent)
            return true
        } catch {
            return false
        }
    }

    private func applyRecurrence(_ recurrence: Recurrence, to event: EKEvent) {
        if let freq = recurrence.frequency {
            event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: freq, interval: 1, end: nil)]
        } else if let rules = event.recurrenceRules {
            for r in rules { event.removeRecurrenceRule(r) }
        }
    }

    // MARK: - Per-event colour (local only)

    private let colorsKey = "scheduleEventColors"

    /// User-chosen colour for an event (local only — see backend issue for cross-device sync).
    func color(forEventID id: String) -> NSColor? {
        guard let hex = (UserDefaults.standard.dictionary(forKey: colorsKey) as? [String: String])?[id] else { return nil }
        return NSColor(hex: hex)
    }

    func setColor(_ color: NSColor?, forEventID id: String) {
        var map = (UserDefaults.standard.dictionary(forKey: colorsKey) as? [String: String]) ?? [:]
        if let color = color { map[id] = color.hexString } else { map[id] = nil }
        UserDefaults.standard.set(map, forKey: colorsKey)
    }

    // MARK: - Per-event private notes (local only, never written to the calendar)

    private let privateNotesKey = "scheduleEventPrivateNotes"

    /// A private note the user keeps on an event — stored only in Focus Bear, so other attendees of
    /// a shared calendar event never see it.
    func privateNote(forEventID id: String) -> String? {
        (UserDefaults.standard.dictionary(forKey: privateNotesKey) as? [String: String])?[id]
    }

    func setPrivateNote(_ note: String?, forEventID id: String) {
        var map = (UserDefaults.standard.dictionary(forKey: privateNotesKey) as? [String: String]) ?? [:]
        if let note = note, !note.isEmpty { map[id] = note } else { map[id] = nil }
        UserDefaults.standard.set(map, forKey: privateNotesKey)
    }

    // MARK: - User-dismissed events

    private let dismissedKey = "scheduleDismissedEventIDs"

    private var dismissedEventIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: dismissedKey) ?? [])
    }

    /// Hide a calendar event from the schedule (the ✕ on a meeting card).
    func dismissEvent(id: String) {
        var ids = dismissedEventIDs
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: dismissedKey)
    }

    /// Merge backend-hidden event ids (from another device) into the local dismissed set.
    func mergeDismissedEventIDs(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        let merged = dismissedEventIDs.union(ids)
        UserDefaults.standard.set(Array(merged), forKey: dismissedKey)
    }
}

// MARK: - DayPlanSync (backend mirror for the Day Plan, contract = backend #2104)
//
// The Day Plan is offline-first: local UserDefaults (CalendarManager / DayPlanTaskStore) is the
// source of truth for rendering, and this layer mirrors the cross-device pieces to the backend so a
// user's plan follows them between devices. All calls are best-effort, fire-and-forget — a failure
// just means the change isn't mirrored this time; local stays correct. Day strings are 'yyyy-MM-dd'.
//
// Contract (backend #2104, merged 2026-06-29):
//   • GET    /day-plan/day/:day                          -> { day, tasks: ToDo[], dismissed_event_ids: [String] }
//   • PUT/DELETE /day-plan/day/:day/dismissed-event/:eventId   (hide / un-hide a meeting for that day)
//   • GET    /day-plan/event-colour  -> [{ event_id, colour }]   ·  PUT body { event_id, colour }  ·  DELETE /:eventId
//   • Tasks-for-today / time-boxing / reorder use the EXISTING PUT /to-do upsert with new optional
//     fields planned_date ('yyyy-MM-dd' | null to unplan), planned_block_key, planned_order.
final class DayPlanSync {
    static let shared = DayPlanSync()
    private init() {}

    /// `true` only with a logged-in user + token — guests / logged-out skip all sync.
    private var isAuthed: Bool {
        let token = appdelegate?.credential?.accessToken ?? ""
        let uid = appdelegate?.user?.userId ?? ""
        return !token.isEmpty && !uid.isEmpty
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func dayString(_ date: Date) -> String { Self.dayFormatter.string(from: date) }

    private func request(_ path: String, method: String, body: [String: Any]? = nil) -> NSMutableURLRequest? {
        guard let url = NSURL(string: "\(baseUrl)\(path)") else { return nil }
        let req = makeRequest(responsePathUrl: url)
        req.httpMethod = method
        if let body = body {
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return req
    }

    private func send(_ request: NSMutableURLRequest, label: String) {
        guard isAuthed else { return }
        URLSession.shared.dataTask(with: request as URLRequest) { _, response, error in
            if let error = error { addLog(text: "DayPlanSync \(label) error: \(error.localizedDescription)"); return }
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            if !(200..<300).contains(code) { addLog(text: "DayPlanSync \(label) http \(code)") }
        }.resume()
    }

    private func encodedEventID(_ id: String) -> String {
        id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    }

    // MARK: Day load
    /// Loads a single day; `completion` gets the dismissed event ids hidden for that day (the full
    /// task objects are also in the dict under "tasks" for callers that want them).
    func loadDay(_ date: Date, completion: @escaping (_ dismissedEventIDs: [String], _ raw: NSDictionary?) -> Void) {
        guard isAuthed, let req = request("/day-plan/day/\(dayString(date))", method: "GET") else {
            completion([], nil); return
        }
        URLSession.shared.dataTask(with: req as URLRequest) { data, response, _ in
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            var ids = [String](); var json: NSDictionary?
            if (200..<300).contains(code), let data = data, !data.isEmpty {
                json = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary
                ids = (json?["dismissed_event_ids"] as? [String]) ?? []
            }
            DispatchQueue.main.async { completion(ids, json) }
        }.resume()
    }

    // MARK: Dismissed events (per day)
    func dismissEvent(eventID: String, on date: Date) {
        guard let req = request("/day-plan/day/\(dayString(date))/dismissed-event/\(encodedEventID(eventID))", method: "PUT") else { return }
        send(req, label: "dismissEvent")
    }

    func undismissEvent(eventID: String, on date: Date) {
        guard let req = request("/day-plan/day/\(dayString(date))/dismissed-event/\(encodedEventID(eventID))", method: "DELETE") else { return }
        send(req, label: "undismissEvent")
    }

    // MARK: Day Plan tasks (per day) — #2104 backs completion/time-box so it syncs across devices.
    /// Upsert a Day Plan task (incl. its `done` state) to the backend so ticking a task is preserved.
    func saveTask(_ task: DayPlanTask, on date: Date) {
        var body: [String: Any] = [
            "id": task.id,
            "title": task.title,
            "duration_minutes": task.durationMinutes,
            "done": task.done,
        ]
        if let src = task.sourceTaskId { body["source_task_id"] = src }
        if let bk = task.blockKey { body["block_key"] = bk }
        guard let req = request("/day-plan/day/\(dayString(date))/task", method: "PUT", body: body) else { return }
        send(req, label: "saveTask")
    }

    func deleteTask(_ taskID: String, on date: Date) {
        guard let req = request("/day-plan/day/\(dayString(date))/task/\(encodedEventID(taskID))", method: "DELETE") else { return }
        send(req, label: "deleteTask")
    }

    // MARK: Event colours (global, per event)
    func loadEventColours(completion: @escaping (_ byEventID: [String: String]) -> Void) {
        guard isAuthed, let req = request("/day-plan/event-colour", method: "GET") else { completion([:]); return }
        URLSession.shared.dataTask(with: req as URLRequest) { data, _, _ in
            var map = [String: String]()
            if let data = data, let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] {
                for item in arr where (item["event_id"] as? String) != nil {
                    if let ev = item["event_id"] as? String, let c = item["colour"] as? String { map[ev] = c }
                }
            }
            DispatchQueue.main.async { completion(map) }
        }.resume()
    }

    func setEventColour(eventID: String, colour: String) {
        guard let req = request("/day-plan/event-colour", method: "PUT", body: ["event_id": eventID, "colour": colour]) else { return }
        send(req, label: "setEventColour")
    }

    func deleteEventColour(eventID: String) {
        guard let req = request("/day-plan/event-colour/\(encodedEventID(eventID))", method: "DELETE") else { return }
        send(req, label: "deleteEventColour")
    }

    // MARK: Planned tasks (pointer-based, via the existing /to-do upsert)
    /// Sets/clears the day-plan pointer fields on an existing todo. `plannedDate` nil unplans it (the
    /// todo is kept). The /to-do upsert requires the todo's title + eisenhower quadrant. Best-effort;
    /// planned_* only sticks on plain-local todos (per the backend note). Not yet wired — increment 2.
    func setTodoPlanned(todoID: String, title: String, quadrant: Int,
                        plannedDate: Date?, blockKey: String?, order: Int?) {
        var body: [String: Any] = ["id": todoID, "title": title, "eisenhower_quadrant": quadrant]
        body["planned_date"] = plannedDate.map { dayString($0) } ?? NSNull()
        if let blockKey = blockKey { body["planned_block_key"] = blockKey }
        if let order = order { body["planned_order"] = order }
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoPlanned")
    }
}
