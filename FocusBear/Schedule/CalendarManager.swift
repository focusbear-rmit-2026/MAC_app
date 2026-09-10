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

    // MARK: - Meetings cache
    //
    // meetings(for:) is called from the Schedule Day Plan's 30-second auto-refresh timer. EventKit's
    // events(matching:) is a blocking query that can stall for seconds while the user's calendars sync
    // — a recurring main-thread App Hang (Sentry FOCUS-BEAR-MACOS-19G). The result only changes on a
    // calendar edit (which posts .EKEventStoreChanged) or a local dismiss/restore, so cache it and
    // re-query only when something actually invalidates it — not on every tick. Accessed on the main
    // thread only (the auto-refresh timer, render, and dismiss actions all run there).
    private struct MeetingsCacheKey: Hashable { let day: String; let includeDismissed: Bool }
    private var meetingsCache: [MeetingsCacheKey: [ScheduleMeetingInput]] = [:]

    private init() {
        // Any change to the store — edits synced from the user's calendar provider, or our own saves —
        // drops the cache so the next query re-reads fresh events.
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            self?.invalidateMeetingsCache()
        }
    }

    private func invalidateMeetingsCache() { meetingsCache.removeAll() }

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

    /// Whether the Mac has any event calendars at all. An authorized user with zero calendars (no
    /// account added in the macOS Calendar app) can't see meetings or add events, so callers show a
    /// "no calendars connected" info message instead of silently rendering an empty schedule.
    func hasAnyCalendars() -> Bool {
        guard access == .authorized else { return false }
        return !store.calendars(for: .event).isEmpty
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        // Only an undetermined status shows a real system prompt — treat that as the user's calendar
        // connect attempt (an already-decided status returns immediately, no dialog, so don't log it).
        let isConnectAttempt = (access == .notDetermined)
        if isConnectAttempt { DayPlanAnalytics.capture(DayPlanAnalytics.calendarConnectStarted) }
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
            if isConnectAttempt {
                DayPlanAnalytics.capture(granted ? DayPlanAnalytics.calendarConnectSucceeded
                                                 : DayPlanAnalytics.calendarConnectFailed)
            }
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
    func meetings(for day: Date, includeDismissed: Bool = false) -> [ScheduleMeetingInput] {
        guard access == .authorized else { return [] }
        let key = MeetingsCacheKey(day: getStringFromDate(date: day, dateFormat: "yyyy-MM-dd"),
                                   includeDismissed: includeDismissed)
        if let cached = meetingsCache[key] { return cached }
        let result = fetchMeetings(for: day, includeDismissed: includeDismissed)
        meetingsCache[key] = result
        return result
    }

    /// The actual (blocking) EventKit query behind `meetings(for:)`. Split out so the public API can
    /// serve the cache — this only runs on a cold miss or after an invalidation, never on every tick.
    private func fetchMeetings(for day: Date, includeDismissed: Bool) -> [ScheduleMeetingInput] {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: day)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        let dismissed = dismissedEventIDs
        let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay && $0.status != .canceled && $0.endDate > $0.startDate }
            .filter { !hasDeclined($0) }
            // Normally dismissed events are hidden; with "Show dismissed events" on, keep them and tag
            // them so the row can render struck-through with an un-dismiss (👀) control.
            .filter { includeDismissed || !isDismissed($0, in: dismissed, on: day) }
            // Overlay any local, day-plan-only edit the user made to a meeting they don't own — TITLE ONLY.
            // We deliberately keep the event's own per-occurrence start/end for positioning: a recurring
            // event's stored override time is the series' first-occurrence start, and overlaying that onto
            // today's occurrence shifted the meeting off the viewed day so it vanished from the Day Plan.
            // The real calendar time is authoritative (the user can't move an event they don't own anyway).
            .map { ev -> ScheduleMeetingInput in
                let override = localOverride(forEventID: eventKey(ev))
                return ScheduleMeetingInput(id: eventKey(ev),
                                            title: override.map { displayTitle($0.title) } ?? title(for: ev),
                                            start: ev.startDate,
                                            end: ev.endDate,
                                            isDismissed: isDismissed(ev, in: dismissed, on: day))
            }
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

    private func title(for event: EKEvent) -> String { displayTitle(event.title) }

    /// The schedule row label for a meeting title — the 📅 prefix plus a default when the title is blank.
    /// Shared by real events and locally-overridden non-owned events so both render identically.
    private func displayTitle(_ raw: String?) -> String {
        let name = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return "📅 " + (name.isEmpty ? ScheduleText.meetingDefaultTitle : name)
    }

    // MARK: - Creating events

    /// A calendar offered in the event editor's calendar popup.
    struct EventCalendar: Equatable {
        let id: String
        let title: String
        /// The account the calendar lives in (`EKSource.title`) — used to tell apart two accounts that
        /// each have a calendar of the same name (e.g. a personal and a university Google account).
        let source: String
        /// False for a calendar that can't take events: a subscribed ICS feed, a holiday calendar, or a
        /// calendar someone else shared read-only. Such a calendar is only ever offered as the calendar
        /// an event *already* lives in, never as a destination.
        let isWritable: Bool
    }

    /// Calendars that accept new events (excludes read-only subscribed/holiday calendars),
    /// with the user's default-for-new-events calendar floated to the front.
    func writableCalendars() -> [EventCalendar] {
        guard access == .authorized else { return [] }
        let defaultID = store.defaultCalendarForNewEvents?.calendarIdentifier
        let cals = store.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .map { descriptor(for: $0) }
        return cals.sorted { a, b in
            if a.id == defaultID { return true }
            if b.id == defaultID { return false }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    /// The calendar an event actually lives in — including a read-only one, which `writableCalendars()`
    /// deliberately omits. The editor needs this to show where the event really is instead of falling
    /// back to an unrelated calendar.
    func calendar(of event: EKEvent) -> EventCalendar? {
        event.calendar.map { descriptor(for: $0) }
    }

    private func descriptor(for calendar: EKCalendar) -> EventCalendar {
        EventCalendar(id: calendar.calendarIdentifier,
                      title: calendar.title,
                      source: calendar.source?.title ?? "",
                      isWritable: calendar.allowsContentModifications)
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
            invalidateMeetingsCache()
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

    /// The specific occurrence of a recurring series (all occurrences share one `eventIdentifier`) whose
    /// start is at/near `date`. `store.event(withIdentifier:)` only ever returns the FIRST occurrence, so a
    /// per-occurrence edit must fetch the occurrence via a date-bounded predicate and pick the closest match.
    private func occurrence(ofEventID id: String, at date: Date) -> EKEvent? {
        guard access == .authorized else { return nil }
        let predicate = store.predicateForEvents(withStart: date.addingTimeInterval(-3600),
                                                 end: date.addingTimeInterval(3600), calendars: nil)
        return store.events(matching: predicate)
            .filter { $0.eventIdentifier == id }
            .min(by: { abs($0.startDate.timeIntervalSince(date)) < abs($1.startDate.timeIntervalSince(date)) })
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

    /// Update an existing event's title/time/calendar/recurrence and save. The caller passes the
    /// `span`: `.thisEvent` edits a single occurrence, `.futureEvents` the whole series. Editing a
    /// single occurrence of a recurring event must NOT rewrite the series recurrence rule, so the
    /// recurrence change is only applied when the edit spans the series (or the event wasn't recurring).
    /// Returns true on success.
    @discardableResult
    func updateEvent(id: String, title: String, start: Date, end: Date,
                     calendarID: String?, recurrence: Recurrence, notes: String? = nil,
                     span: EKSpan = .futureEvents, occurrenceStart: Date? = nil) -> Bool {
        guard access == .authorized else { return false }
        // store.event(withIdentifier:) returns the FIRST occurrence of a recurring series, so ANY edit of
        // a LATER occurrence must target THAT specific occurrence (fetched by date) — for BOTH spans:
        //  • .thisEvent   → editing the first occurrence left the picked one (e.g. tomorrow's) unchanged.
        //  • .futureEvents → editing the first occurrence with the picked occurrence's date rebased the
        //    WHOLE series to that future date, spoiling every event. Anchoring .futureEvents on the picked
        //    occurrence instead changes that occurrence and all future ones (standard "this and future").
        let event: EKEvent
        if let occStart = occurrenceStart, let occ = occurrence(ofEventID: id, at: occStart) {
            event = occ
        } else if let e = store.event(withIdentifier: id) {
            event = e
        } else {
            return false
        }
        let wasRecurring = event.hasRecurrenceRules
        event.title = title
        event.startDate = start
        event.endDate = end
        if let notes = notes { event.notes = notes.isEmpty ? nil : notes }
        // Only ever move the event into a calendar that can actually take it — assigning a read-only
        // calendar (a subscribed feed, or one shared read-only) makes the save throw and lose the edit.
        if let cal = calendarID.flatMap({ store.calendar(withIdentifier: $0) }), cal.allowsContentModifications {
            event.calendar = cal
        }
        if span == .futureEvents || !wasRecurring { applyRecurrence(recurrence, to: event) }
        do {
            try store.save(event, span: span)
            invalidateMeetingsCache()
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

    // MARK: - Local, day-plan-only overrides (events the user doesn't own)

    /// A locally-stored edit of an event the current user doesn't own (a meeting someone else organised).
    /// EventKit won't let us write changes back to such an event, so the user's tweaks (title / time /
    /// notes) live only in Focus Bear and are overlaid onto their schedule — never sent to the shared
    /// calendar the other attendees see. Only the title is overlaid on the Day Plan (see `fetchMeetings`);
    /// the time is kept for the record but the calendar's own occurrence time stays authoritative.
    struct LocalEventOverride: Codable {
        var title: String
        var start: Date
        var end: Date
        var notes: String?
    }

    private let localOverridesKey = "scheduleEventLocalOverrides"

    private func localOverridesMap() -> [String: LocalEventOverride] {
        guard let data = UserDefaults.standard.data(forKey: localOverridesKey),
              let map = try? JSONDecoder().decode([String: LocalEventOverride].self, from: data) else { return [:] }
        return map
    }

    /// The user's local-only edit of a non-owned event, if they've made one.
    func localOverride(forEventID id: String) -> LocalEventOverride? {
        localOverridesMap()[id]
    }

    func setLocalOverride(_ override: LocalEventOverride?, forEventID id: String) {
        var map = localOverridesMap()
        map[id] = override
        if let data = try? JSONEncoder().encode(map) { UserDefaults.standard.set(data, forKey: localOverridesKey) }
        invalidateMeetingsCache()   // the overlaid title is baked into the cached meetings
    }

    /// Whether the current user owns `event`: a self-created event (no organiser) or one they organise.
    /// A meeting organised by someone else is NOT owned — EventKit refuses to save edits to it — so such
    /// edits can only be stored locally (see `LocalEventOverride`).
    func isEventOwnedByCurrentUser(_ event: EKEvent) -> Bool {
        if let organizer = event.organizer { return organizer.isCurrentUser }
        return event.calendar?.allowsContentModifications ?? true
    }

    // MARK: - User-dismissed events

    private let dismissedKey = "scheduleDismissedEventIDs"

    private var dismissedEventIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: dismissedKey) ?? [])
    }

    /// Scopes a dismissal to one specific day's occurrence — the "Just for today" choice on a recurring
    /// event's ✕.
    private func perDayDismissKey(_ id: String, _ day: Date) -> String {
        "\(id)|day:\(getStringFromDate(date: day, dateFormat: "yyyy-MM-dd"))"
    }

    /// Series-wide dismiss key from the provider's iCalUID (calendarItemExternalIdentifier), which
    /// EventKit keeps the SAME across every occurrence of a recurring series — unlike eventIdentifier,
    /// which can differ per occurrence (that left occurrences after ~tomorrow still visible). nil when
    /// the event has no external id (e.g. local calendars).
    private func seriesKey(_ event: EKEvent) -> String? {
        let ext = event.calendarItemExternalIdentifier ?? ""
        return ext.isEmpty ? nil : "series:\(ext)"
    }

    /// Whether `event` is hidden on `day` — the whole series was dismissed (series key, or the legacy
    /// plain id from before the series-key fix), or just this one day's occurrence was (per-day key).
    private func isDismissed(_ event: EKEvent, in dismissed: Set<String>, on day: Date) -> Bool {
        let id = eventKey(event)
        if dismissed.contains(id) || dismissed.contains(perDayDismissKey(id, day)) { return true }
        if let sk = seriesKey(event), dismissed.contains(sk) { return true }
        return false
    }

    /// Hide a calendar event from the schedule for every occurrence (the "Hide entire series" choice
    /// on a recurring event's ✕ — or the only choice for a non-recurring event's ✕).
    func dismissEvent(id: String) {
        var ids = dismissedEventIDs
        // Prefer the series-stable key so EVERY occurrence of a recurring event is hidden —
        // eventIdentifier isn't reliably the same across occurrences. Falls back to the plain id when
        // there's no external id. A non-recurring event has a unique external id, so this still hides
        // just that one event.
        if let event = event(withID: id), let sk = seriesKey(event) {
            ids.insert(sk)
        } else {
            ids.insert(id)
        }
        UserDefaults.standard.set(Array(ids), forKey: dismissedKey)
        invalidateMeetingsCache()
    }

    /// Hide a calendar event from the schedule for just this one day (the "Just for today" choice on
    /// a recurring event's ✕). Other occurrences of the series are unaffected.
    func dismissEvent(id: String, forDay day: Date) {
        var ids = dismissedEventIDs
        ids.insert(perDayDismissKey(id, day))
        UserDefaults.standard.set(Array(ids), forKey: dismissedKey)
        invalidateMeetingsCache()
    }

    /// Un-hide a previously dismissed event (the 👀 shown on a struck-through meeting when
    /// "Show dismissed events" is on). Clears both a whole-series dismissal and this day's single-day
    /// dismissal, whichever is present — either way, `day`'s occurrence reappears.
    func restoreDismissedEvent(id: String, forDay day: Date) {
        var ids = dismissedEventIDs
        ids.remove(id)
        ids.remove(perDayDismissKey(id, day))
        if let event = event(withID: id), let sk = seriesKey(event) { ids.remove(sk) }   // undo a series dismiss too
        UserDefaults.standard.set(Array(ids), forKey: dismissedKey)
        invalidateMeetingsCache()
    }

    /// Merge backend-hidden event ids (from another device) into the local dismissed set.
    func mergeDismissedEventIDs(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        let merged = dismissedEventIDs.union(ids)
        UserDefaults.standard.set(Array(merged), forKey: dismissedKey)
        invalidateMeetingsCache()
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

    // MARK: Day Plan tasks (per day)
    // #2104 (final) makes the Day Plan a POINTER into to-dos via `planned_date`, not a copy table —
    // there is no `/day-plan/day/:day/task` route. So a Day Plan task that came from a to-do syncs
    // through the to-do itself: `setTodoPlanned` (below) plans/unplans it, `setTodoStatus` marks it
    // complete — both via the `PUT /to-do` upsert (the only to-do write endpoint). From-scratch tasks
    // (no `sourceTaskId`) stay local-only.

    /// Reflect a Day Plan task's completion onto its backend to-do so web/mobile lists update too.
    /// The upsert reuses the create DTO, so `title` + `quadrant` are echoed back to avoid clobbering.
    func setTodoStatus(todoID: String, title: String, quadrant: Int, completed: Bool) {
        let body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "status": completed ? "COMPLETED" : "NOT_STARTED",
        ]
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoStatus")
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

    // MARK: Planned tasks (pointer-based, PUT /to-do upsert)
    /// Sets/clears the day-plan pointer fields on an existing to-do so its Day Plan placement syncs
    /// across devices (GET /day-plan/day hydrates it on the other device). `plannedDate` nil unplans
    /// it (the to-do is kept). `dueDate` (snooze only) also pushes the to-do's `due_date`.
    ///
    /// Uses the `PUT /to-do` upsert — the ONLY to-do write endpoint. The planner `PATCH /to-do/:id`
    /// route this used to call was refactored away (#2016): it silently 404'd, so planner moves never
    /// reached the backend. After a snooze/move the to-do stayed planned on its ORIGINAL day and then
    /// re-hydrated there as a phantom duplicate (with no project, since that to-do carries no tag).
    /// `title` + `quadrant` are required by the upsert DTO and echoed back to avoid clobbering them;
    /// `tags` are omitted so the backend preserves the task's project.
    func setTodoPlanned(todoID: String, title: String, quadrant: Int, plannedDate: Date?,
                        blockKey: String?, order: Int?, dueDate: Date? = nil) {
        var body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "planned_date": plannedDate.map { dayString($0) } ?? NSNull(),
        ]
        if let blockKey = blockKey { body["planned_block_key"] = blockKey }
        if let order = order { body["planned_order"] = order }
        if let dueDate = dueDate {
            body["due_date"] = getStringFromDateInUtc(date: dueDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        }
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoPlanned")
    }

    // MARK: Projects (native Focus Bear projects: `POST /projects`, `to-do.project_id`)
    /// Points `todoID` at the backend project named `projectName` — creating the project first when
    /// the name is new — so a `#project` typed in the Day Plan shows up on web and mobile (they read
    /// `project_id`; a project that only lives in this Mac's UserDefaults is invisible to them). `nil`
    /// clears the project. `title` + `quadrant` are echoed back like every other upsert here.
    func setTodoProject(todoID: String, title: String, quadrant: Int, projectName: String?) {
        let name = (projectName ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            upsertTodoProject(todoID: todoID, title: title, quadrant: quadrant, projectID: nil)
            return
        }
        if let id = DayPlanTaskStore.shared.remoteProjectID(named: name) {
            upsertTodoProject(todoID: todoID, title: title, quadrant: quadrant, projectID: id)
            return
        }
        createProject(named: name) { [weak self] id in
            guard let id = id else { return }
            self?.upsertTodoProject(todoID: todoID, title: title, quadrant: quadrant, projectID: id)
        }
    }

    private func upsertTodoProject(todoID: String, title: String, quadrant: Int, projectID: String?) {
        let body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "project_id": projectID ?? NSNull(),
        ]
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoProject")
    }

    /// Completions waiting on an in-flight `POST /projects`, keyed by lowercased name, so two tasks
    /// given the same new project before the first create returns share one project.
    private var pendingProjectCreations: [String: [(String?) -> Void]] = [:]

    /// `POST /projects { name }` → the new project's id (nil on failure), registered with the task
    /// store so later assignments resolve it locally. `completion` runs on the main thread.
    func createProject(named name: String, completion: @escaping (String?) -> Void) {
        let key = name.lowercased()
        if pendingProjectCreations[key] != nil {
            pendingProjectCreations[key]?.append(completion)
            return
        }
        pendingProjectCreations[key] = [completion]
        guard isAuthed, let req = request("/projects", method: "POST", body: ["name": name]) else {
            finishProjectCreation(key: key, id: nil); return
        }
        URLSession.shared.dataTask(with: req as URLRequest) { [weak self] data, response, error in
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            var id: String?
            if (200..<300).contains(code), let data = data,
               let json = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary {
                id = json["id"] as? String
            }
            if id == nil { addLog(text: "DayPlanSync createProject http \(code) \(error?.localizedDescription ?? "")") }
            DispatchQueue.main.async {
                if let id = id { DayPlanTaskStore.shared.registerRemoteProject(id: id, name: name) }
                self?.finishProjectCreation(key: key, id: id)
            }
        }.resume()
    }

    private func finishProjectCreation(key: String, id: String?) {
        let waiting = pendingProjectCreations.removeValue(forKey: key) ?? []
        waiting.forEach { $0(id) }
    }

    /// Push a renamed Day Plan task's title onto its backend to-do so the new name syncs to other
    /// devices. Uses the `PUT /to-do` upsert (like `setTodoStatus`); the create DTO requires the
    /// quadrant, so it is echoed back to avoid clobbering it.
    func setTodoTitle(todoID: String, title: String, quadrant: Int) {
        let body: [String: Any] = ["id": todoID, "title": title, "eisenhower_quadrant": quadrant]
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoTitle")
    }

    /// Push a Day Plan task's checklist sub-tasks onto its backend to-do so they sync to web/mobile
    /// (which read the to-do's `subtasks` jsonb column). The backend's canonical subtask shape is
    /// `{ name, is_completed }` — NOT the Mac's local `{ title, done }` — so we map field names on the
    /// way out; `hydrateSubtasks` maps them back. Uses the `PUT /to-do` upsert (the only to-do write
    /// endpoint); `title` + `quadrant` are echoed back because the create DTO requires them, and
    /// sending the FULL list makes the backend take it as authoritative for this to-do.
    func setTodoSubtasks(todoID: String, title: String, quadrant: Int, subtasks: [DayPlanSubtask]) {
        let payload = subtasks.map { ["name": $0.title, "is_completed": $0.done] as [String: Any] }
        let body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "subtasks": payload,
        ]
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoSubtasks")
    }
}

// MARK: - Event editor calendar picker

/// Pure rules behind the event editor's "Calendar" popup: which calendars to list, what to label them
/// and which one to preselect.
///
/// The popup used to list only *writable* calendars and preselect by looking the event's calendar up in
/// that list. For an event living in a read-only calendar — a subscribed ICS feed (how a university
/// timetable is usually delivered), a holiday calendar, or a calendar shared read-only — the lookup found
/// nothing, so the popup silently sat on whichever calendar happened to be first and claimed the event
/// belonged to it. Saving then moved the event into that unrelated calendar.
enum EventCalendarPicker {

    /// The calendars to list: everything the user can write to, plus the calendar the event being edited
    /// already lives in when that one isn't writable (so the editor tells the truth about where it is).
    static func choices(writable: [CalendarManager.EventCalendar],
                        owning: CalendarManager.EventCalendar?) -> [CalendarManager.EventCalendar] {
        guard let owning = owning, !writable.contains(where: { $0.id == owning.id }) else { return writable }
        return writable + [owning]
    }

    /// Menu labels for `choices`. A title shared by calendars in different accounts is qualified with the
    /// account name, so two Google accounts that both have a "Work" calendar stay distinguishable.
    static func menuTitles(for choices: [CalendarManager.EventCalendar]) -> [String] {
        var countsByTitle: [String: Int] = [:]
        for choice in choices { countsByTitle[choice.title, default: 0] += 1 }
        return choices.map { choice in
            guard countsByTitle[choice.title, default: 0] > 1, !choice.source.isEmpty else { return choice.title }
            return "\(choice.title) (\(choice.source))"
        }
    }

    /// The index to preselect: the calendar the event actually lives in. nil when that calendar is unknown
    /// (a brand-new event, or an event the store can no longer resolve) — the caller must then treat the
    /// popup's selection as "not chosen by the user" rather than as the event's calendar.
    static func selectedIndex(in choices: [CalendarManager.EventCalendar], owningID: String?) -> Int? {
        guard let owningID = owningID else { return nil }
        return choices.firstIndex { $0.id == owningID }
    }
}
