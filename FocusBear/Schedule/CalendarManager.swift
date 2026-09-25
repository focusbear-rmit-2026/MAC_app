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
    private let permissionLogLock = NSLock()
    private var lastLoggedAuthorizationStatus: Int?

    // MARK: - Meetings cache
    //
    // meetings(for:) is called from the Day Plan's 30-second auto-refresh timer, the menu-bar model
    // refresh and the accountability buddy — all on the main thread. EventKit's events(matching:) is a
    // BLOCKING XPC round trip to CalendarAgent that regularly takes 7-24 seconds while the user's
    // calendars sync: in the unified log the EventKit "CADEventPredicate" activity on the main thread
    // is the last thing this process emits before each multi-second freeze (2026-09-15 08:38:58 → 17s,
    // 08:48:58 → 11s, 08:50:27 → 7s), and MainThreadWatchdog reports the matching stall each time.
    //
    // So the main thread never waits for EventKit here. It is answered from `meetingsCache`, and the
    // query runs on `meetingsFetchQueue`. An entry invalidated by a calendar change is kept and SERVED
    // (stale-while-revalidate) rather than dropped — dropping it would put the next main-thread caller
    // straight back on the blocking path — and when the refresh lands with a different answer,
    // `meetingsDidChange` tells the Day Plan to re-render.

    /// Posted on the main thread when a background refresh produced different meetings than callers
    /// have already been served, so the Day Plan can re-render with the new data.
    static let meetingsDidChange = Notification.Name("io.focusbear.calendar.meetingsDidChange")

    private let meetingsCache = MeetingsCache()
    private let meetingsFetchQueue = DispatchQueue(label: "io.focusbear.calendar.meetingsFetch")

    private init() {
        // Any change to the store — edits synced from the user's calendar provider, or our own saves —
        // makes every cached day out of date, so kick off a refresh of each one.
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            self?.invalidateMeetingsCache()
        }
    }

    /// Marks every cached day out of date and refreshes it off the main thread. The stale values stay
    /// readable in the meantime so no caller is ever forced onto the blocking EventKit path.
    private func invalidateMeetingsCache() {
        for key in meetingsCache.invalidateAll() { refreshMeetings(for: key) }
    }

    enum Access { case notDetermined, denied, authorized }

    var access: Access {
        let status = EKEventStore.authorizationStatus(for: .event)
        permissionLogLock.lock()
        let changed = lastLoggedAuthorizationStatus != status.rawValue
        lastLoggedAuthorizationStatus = status.rawValue
        permissionLogLock.unlock()
        if changed {
            addLog(text: "Calendar permission: pid=\(ProcessInfo.processInfo.processIdentifier) status=\(status.rawValue) readable=\(status == .authorized)")
        }
        switch status {
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

        let handler: (Bool, Error?) -> Void = { granted, error in
            self.logPermissionCompletion(operation: "explicit-request", granted: granted, error: error)
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
        let handler: (Bool, Error?) -> Void = { granted, error in
            self.logPermissionCompletion(operation: "revalidate", granted: granted, error: error)
            DispatchQueue.main.async { completion() }
        }
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents(completion: handler)
        } else {
            store.requestAccess(to: .event, completion: handler)
        }
    }

    /// Record permission results without calendar names, event content or localized error text.
    private func logPermissionCompletion(operation: String, granted: Bool, error: Error?) {
        let status = EKEventStore.authorizationStatus(for: .event).rawValue
        let failure = error as NSError?
        addLog(text: "Calendar permission callback: pid=\(ProcessInfo.processInfo.processIdentifier) operation=\(operation) granted=\(granted) status=\(status) errorDomain=\(failure?.domain ?? "none") errorCode=\(failure?.code ?? 0)")
    }

    /// Today's timed meetings the user is actually attending — all-day, cancelled, declined,
    /// tentative, not-yet-responded and user-dismissed events are excluded — sorted by start.
    func todaysMeetings() -> [ScheduleMeetingInput] { meetings(for: Date()) }

    /// Non-declined, non-all-day, non-dismissed meetings for the given day (includes events the
    /// user hasn't RSVP'd to yet).
    ///
    /// Never blocks the main thread: see the "Meetings cache" note above. The main thread is served
    /// from the cache (which may be empty on the very first call, or one refresh behind after a
    /// calendar edit) and told about the fresh data through `meetingsDidChange`. Callers already on a
    /// background thread get live data, since there's no run loop of theirs to protect.
    func meetings(for day: Date, includeDismissed: Bool = false) -> [ScheduleMeetingInput] {
        guard access == .authorized else { return [] }
        let key = MeetingsCache.Key(dayStart: Calendar.current.startOfDay(for: day),
                                    includeDismissed: includeDismissed)
        let lookup = meetingsCache.lookup(key)
        guard lookup.needsRefresh else { return lookup.meetings }
        if !Thread.isMainThread {
            let fresh = meetingsFetchQueue.sync { fetchMeetings(for: key) }
            meetingsCache.store(fresh, for: key)
            return fresh
        }
        refreshMeetings(for: key)
        return lookup.meetings
    }

    /// Whether `meetings(for:)` would answer this day from real data rather than from the cold-cache
    /// placeholder. `meetings(for:)` returns [] both for "this day is clear" and for "nobody has read
    /// this day yet", which is fine for rendering (the background refresh corrects it moments later)
    /// but NOT for deciding something the user reads as a verdict: an unread day looks completely free,
    /// so the date picker painted every future day green until its refreshes landed (report
    /// 2026-09-17_21-51-06). Unauthorized counts as known — [] is then the final answer, not a
    /// placeholder.
    func meetingsAreKnown(for day: Date, includeDismissed: Bool = false) -> Bool {
        guard access == .authorized else { return true }
        return meetingsCache.hasValue(MeetingsCache.Key(dayStart: Calendar.current.startOfDay(for: day),
                                                        includeDismissed: includeDismissed))
    }

    /// Reads every one of `days` that isn't cached yet, off the main thread, then calls `completion` on
    /// the main thread. For callers that must not decide on a day until its meetings are real — they
    /// render the day as unknown, ask for this, and re-render when it returns.
    ///
    /// Deliberately NOT `refreshMeetings`: that is fire-and-forget, so there is nothing to wait on, and
    /// its `beginRefresh` coalescing would silently drop days. Queueing one block on the serial
    /// `meetingsFetchQueue` is its own coalescing — a refresh already queued for a day runs first, and
    /// the `meetingsAreKnown` re-check below then skips it rather than querying EventKit twice.
    func warmMeetings(for days: [Date], includeDismissed: Bool = false, completion: @escaping () -> Void) {
        let keys = days.map { MeetingsCache.Key(dayStart: Calendar.current.startOfDay(for: $0),
                                                includeDismissed: includeDismissed) }
        guard access == .authorized, !keys.isEmpty else { completion(); return }
        meetingsFetchQueue.async { [weak self] in
            guard let self = self else { DispatchQueue.main.async(execute: completion); return }
            for key in keys where !self.meetingsCache.hasValue(key) {
                self.meetingsCache.store(self.fetchMeetings(for: key), for: key)
            }
            DispatchQueue.main.async(execute: completion)
        }
    }

    /// Re-reads EventKit for `key` off the main thread and republishes the result. Coalesced, so the
    /// 30-second reload (and the three Day Plan hosts that each run one) can't stack up queries.
    private func refreshMeetings(for key: MeetingsCache.Key) {
        guard meetingsCache.beginRefresh(key) else { return }
        meetingsFetchQueue.async { [weak self] in
            guard let self = self else { return }
            let fresh = self.fetchMeetings(for: key)
            let changed = self.meetingsCache.store(fresh, for: key)
            self.meetingsCache.endRefresh(key)
            guard changed else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.meetingsDidChange, object: nil)
            }
        }
    }

    /// The actual (blocking) EventKit query behind `meetings(for:)`. Split out so the public API can
    /// serve the cache — this only ever runs on `meetingsFetchQueue`, never on the main thread. Every
    /// `EKEvent` is mapped to a plain `ScheduleMeetingInput` here, so no EventKit object crosses threads.
    private func fetchMeetings(for key: MeetingsCache.Key) -> [ScheduleMeetingInput] {
        fetchMeetings(for: key.dayStart, includeDismissed: key.includeDismissed)
    }

    private func fetchMeetings(for day: Date, includeDismissed: Bool) -> [ScheduleMeetingInput] {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: day)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

        let dismissed = dismissedEventIDs
        let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        return store.events(matching: predicate)
            .filter { $0.endDate > $0.startDate && Self.countsAsBusy(isAllDay: $0.isAllDay,
                availability: $0.availability, isCancelled: $0.status == .canceled, hasDeclined: hasDeclined($0)) }
            // Normally dismissed events are hidden; with "Show dismissed events" on, keep them and tag
            // them so the row can render struck-through with an un-dismiss (👀) control.
            .filter { includeDismissed || !isDismissed($0, in: dismissed, on: day) }
            // Overlay any local, day-plan-only edit the user made to a meeting they don't own. The
            // title always applies; the times only for the occurrence the edit was made on, since a
            // recurring event shares one identifier across the series and replaying a stored time
            // onto another occurrence used to shift the meeting clean off the viewed day.
            .map { ev -> ScheduleMeetingInput in
                let override = localOverride(forEventID: eventKey(ev))
                let times = Self.overrideTimes(override, onDay: Self.dayKey(startOfDay),
                                               occurrenceStart: ev.startDate, calendar: cal)
                let start: Date = times?.start ?? ev.startDate
                // …then the Day Plan's own one-day trim on top, so a meeting the user shortened from
                // the Fix modal gives its freed minutes back to the day it was shortened on.
                let untrimmedEnd: Date = times?.end ?? ev.endDate
                let end = DayPlanMeetingDurations.trimmedEnd(forEventID: eventKey(ev), on: startOfDay,
                                                             start: start, end: untrimmedEnd)
                return ScheduleMeetingInput(id: eventKey(ev),
                                            title: override.map { displayTitle($0.title) } ?? title(for: ev),
                                            start: start,
                                            end: end,
                                            isDismissed: isDismissed(ev, in: dismissed, on: day),
                                            ownership: ownership(of: ev),
                                            hasOtherAttendees: (ev.attendees ?? []).contains { !$0.isCurrentUser },
                                            isRecurring: ev.hasRecurrenceRules)
            }
            .sorted { $0.start < $1.start }
    }

    /// Every timed event from `firstDay`'s midnight for `days` days, tagged with the exclusions the
    /// busy-hours report applies (`BusyEventInput.isBusy`) — the same rules `meetings(for:)` uses to hide
    /// a meeting, applied over the whole planning horizon in one EventKit query. [] without access.
    ///
    /// ⚠️ Blocking, and over a much wider window than `meetings(for:)` — **never call this on the main
    /// thread**. It is deliberately uncached (one caller, fired at most hourly); `BusyHoursReporter`
    /// hops to a background queue for it. See the "Meetings cache" note above for what happens when an
    /// EventKit query runs on the main thread.
    func busyEvents(from firstDay: Date, days: Int) -> [BusyEventInput] {
        guard access == .authorized, days > 0 else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: firstDay)
        guard let end = cal.date(byAdding: .day, value: days, to: start) else { return [] }
        let dismissed = dismissedEventIDs
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map { ev in
            BusyEventInput(start: ev.startDate, end: ev.endDate, isAllDay: ev.isAllDay,
                           isCancelled: ev.status == .canceled, isDeclined: hasDeclined(ev),
                           isDismissed: isDismissed(ev, in: dismissed, on: ev.startDate))
        }
    }

    /// Shared with Time Forecast. An all-day out-of-office event occupies its clipped local
    /// day(s); all-day birthdays/holidays that are free or have no busy status do not consume work.
    static func countsAsBusy(isAllDay: Bool, availability: EKEventAvailability,
                             isCancelled: Bool, hasDeclined: Bool) -> Bool {
        guard !isCancelled, !hasDeclined, availability != .free else { return false }
        return !isAllDay || availability == .busy || availability == .unavailable
    }

    /// Hide only meetings the user has explicitly declined. Accepted, tentative and
    /// not-yet-responded (no RSVP) events are all shown.
    private func hasDeclined(_ event: EKEvent) -> Bool {
        if event.organizer?.isCurrentUser == true { return false }
        guard let attendees = event.attendees, let me = attendees.first(where: { $0.isCurrentUser }) else { return false }
        return me.participantStatus == .declined
    }

    /// `yyyy-MM-dd` in the current calendar — the key a local override records its occurrence under.
    static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Whether an event belongs to a repeating series, so the caller can ask which occurrences an
    /// edit should touch.
    func isRecurring(id: String) -> Bool {
        guard access == .authorized, let event = store.event(withIdentifier: id) else { return false }
        return event.hasRecurrenceRules
    }

    static func eventID(_ event: EKEvent) -> String {
        event.eventIdentifier ?? "\(event.title ?? "")|\(event.startDate.timeIntervalSince1970)"
    }

    private func eventKey(_ event: EKEvent) -> String { Self.eventID(event) }

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
            invalidateMeetingsCache()   // don't wait for .EKEventStoreChanged to show the new event
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
                     calendarID: String?, recurrence: Recurrence, notes: String? = nil,
                     span: EKSpan? = nil) -> Bool {
        guard access == .authorized, let event = store.event(withIdentifier: id) else { return false }
        // Sampled BEFORE any edit: whether this event ALREADY carried a recurrence rule decides whether
        // we may rewrite that rule below.
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
        // The caller asks the user which they meant for a repeating event; without an answer keep
        // the old behaviour (this and every later occurrence).
        let effectiveSpan = span ?? ((recurrence != .none || wasRecurring) ? .futureEvents : .thisEvent)
        // Ported from main: editing a SINGLE occurrence of an already-repeating event must not rewrite
        // the series' recurrence rule. Applying it unconditionally here spoiled the whole series when the
        // user only meant to change one occurrence. Only touch the rule when this edit owns the series
        // (.futureEvents) or the event was not repeating to begin with.
        if effectiveSpan == .futureEvents || !wasRecurring { applyRecurrence(recurrence, to: event) }
        do {
            try store.save(event, span: effectiveSpan)
            invalidateMeetingsCache()   // don't wait for .EKEventStoreChanged to show the edit
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
    /// calendar the other attendees see.
    struct LocalEventOverride: Codable {
        var title: String
        var start: Date
        var end: Date
        var notes: String?
        /// `yyyy-MM-dd` of the occurrence this edit was made on. A recurring event has one identifier
        /// for the whole series, so without this an edit to today's stand-up would be replayed onto
        /// every other occurrence — which is why the times used to be ignored entirely. nil for
        /// overrides stored before this field existed; those keep the old title-only behaviour.
        var occurrenceDay: String?
        /// The user chose "all future events" for an event they don't own. The stored times then
        /// mean a time of day and a duration, applied to every occurrence, rather than one date.
        var appliesToSeries: Bool?
    }

    /// The times a stored override contributes to one occurrence, or nil when it must not move
    /// anything (a different occurrence, or a legacy override that never recorded its day).
    ///
    /// A **series** override carries a time of day and a duration rather than a date: the user asked
    /// for "all future events", and replaying one absolute date onto every occurrence would pile the
    /// whole series onto a single day (reports 2026-09-11_21-00-07 and 2026-09-11_21-00-30).
    static func overrideTimes(_ override: LocalEventOverride?, onDay dayKey: String,
                              occurrenceStart: Date? = nil,
                              calendar: Calendar = .current) -> (start: Date, end: Date)? {
        guard let override = override, override.end > override.start else { return nil }
        if override.appliesToSeries == true {
            guard let occurrence = occurrenceStart else { return nil }
            let time = calendar.dateComponents([.hour, .minute], from: override.start)
            guard let start = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0,
                                            second: 0, of: occurrence) else { return nil }
            return (start, start.addingTimeInterval(override.end.timeIntervalSince(override.start)))
        }
        guard let day = override.occurrenceDay, day == dayKey else { return nil }
        return (override.start, override.end)
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
        invalidateMeetingsCache()   // the overlaid title/time is baked into the cached meetings
    }

    /// Whether the current user owns `event`: a self-created event (no organiser) or one they organise.
    /// A meeting organised by someone else is NOT owned — EventKit refuses to save edits to it — so such
    /// edits can only be stored locally (see `LocalEventOverride`).
    func isEventOwnedByCurrentUser(_ event: EKEvent) -> Bool {
        if let organizer = event.organizer { return organizer.isCurrentUser }
        return event.calendar?.allowsContentModifications ?? true
    }

    /// Ownership as far as EventKit can prove it — the organiser is the only reliable signal, and an
    /// event with no organiser at all (a hand-made local event, a subscribed feed) is genuinely
    /// `.unknown` rather than "mine". `isEventOwnedByCurrentUser` guesses "mine" for a writable
    /// calendar because *editing* one of those locally is harmless; deciding whether to offer to cancel
    /// a meeting for everybody else is not, so it gets the honest three-way answer.
    func ownership(of event: EKEvent) -> EventOwnership {
        EventOwnershipResolver.ownership(organizerIsCurrentUser: event.organizer.map { $0.isCurrentUser })
    }

    // MARK: - One-day trim of a meeting (Day Plan only)

    /// The length the Day Plan would give this meeting on `day` if it were not trimmed — what "Full
    /// length" puts it back to. Includes any local override of the times, since that is the length the
    /// plan was showing before the trim.
    func untrimmedSeconds(forEventID id: String, on day: Date, occurrenceStart: Date) -> Int? {
        guard let event = event(withID: id) else { return nil }
        let times = Self.overrideTimes(localOverride(forEventID: id), onDay: Self.dayKey(day),
                                       occurrenceStart: occurrenceStart)
        let start: Date = times?.start ?? event.startDate
        let end: Date = times?.end ?? event.endDate
        return end > start ? Int(end.timeIntervalSince(start)) : nil
    }

    /// Trim (or, with a nil `seconds`, un-trim) one meeting for one day. Goes through here rather than
    /// straight to `DayPlanMeetingDurations` so the meetings cache — which bakes the trimmed end into
    /// its `ScheduleMeetingInput`s — cannot serve the old length back.
    @discardableResult
    func setMeetingTrim(_ seconds: Int?, forEventID id: String, on day: Date, actualSeconds: Int) -> Int? {
        let applied: Int?
        if let seconds = seconds {
            applied = DayPlanMeetingDurations.setOverride(seconds, forEventID: id, on: day, actual: actualSeconds)
        } else {
            DayPlanMeetingDurations.clearOverride(forEventID: id, on: day)
            applied = nil
        }
        invalidateMeetingsCache()
        return applied
    }

    /// The occurrence of a repeating event that falls at `date`, rather than the series' first one.
    ///
    /// `store.event(withIdentifier:)` always hands back the FIRST occurrence, so removing "just this
    /// one" through it would delete the wrong day. Searching an hour either side of the row's own start
    /// and taking the nearest match pins the removal to the occurrence the user actually clicked.
    private func occurrence(ofEventID id: String, at date: Date) -> EKEvent? {
        guard access == .authorized else { return nil }
        let predicate = store.predicateForEvents(withStart: date.addingTimeInterval(-3600),
                                                 end: date.addingTimeInterval(3600), calendars: nil)
        return store.events(matching: predicate)
            .filter { $0.eventIdentifier == id }
            .min(by: { abs($0.startDate.timeIntervalSince(date)) < abs($1.startDate.timeIntervalSince(date)) })
    }

    /// Remove an event from the calendar store. Returns false when EventKit refuses (read-only
    /// calendar, or the event has already gone).
    ///
    /// What this actually achieves depends on who owns the event, and the caller must not overstate it:
    ///  • Organiser — the account deletes the event and sends the cancellation on to the attendees.
    ///  • Attendee — this removes the user's own copy only. EventKit has no RSVP API (see
    ///    `EventCancellation.swift`), so Focus Bear cannot itself tell the organiser "declined".
    @discardableResult
    func removeEvent(id: String, span: EKSpan, occurrenceStart: Date? = nil) -> Bool {
        guard access == .authorized else { return false }
        // Same trap as updateEvent: store.event(withIdentifier:) hands back the series' FIRST
        // occurrence, so removing "just this one" from the wrong object would delete the wrong day.
        let event: EKEvent
        if let occStart = occurrenceStart, let occ = occurrence(ofEventID: id, at: occStart) {
            event = occ
        } else if let e = store.event(withIdentifier: id) {
            event = e
        } else {
            return false
        }
        do {
            try store.remove(event, span: span)
            invalidateMeetingsCache()
            return true
        } catch {
            return false
        }
    }

    // MARK: - User-dismissed events

    static let dismissedEventsDidChange = Notification.Name("FocusBear.CalendarDismissedEventsDidChange")
    private let dismissedKey = "scheduleDismissedEventIDs"

    /// Capture on the UI thread; the forecast's queue-confined EventKit reader uses this value
    /// without reaching into CalendarManager's event store or mutable caches.
    var dismissalSnapshot: CalendarEventDismissalSnapshot {
        CalendarEventDismissalSnapshot(ids: dismissedEventIDs, calendar: .current)
    }

    private func saveDismissedEventIDs(_ ids: Set<String>) {
        guard ids != dismissedEventIDs else { return }
        UserDefaults.standard.set(Array(ids), forKey: dismissedKey)
        // Dismissal is baked into the cached ScheduleMeetingInputs (`isDismissed`, and whether the row
        // is there at all), and it's a purely local change — EventKit never posts .EKEventStoreChanged
        // for it — so the cache has to be invalidated here or the ✕ / 👀 wouldn't take effect.
        invalidateMeetingsCache()
        NotificationCenter.default.post(name: Self.dismissedEventsDidChange, object: nil)
    }

    private var dismissedEventIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: dismissedKey) ?? [])
    }

    /// Scopes a dismissal to one specific day's occurrence — the "Just for today" choice on a recurring
    /// event's ✕.
    private func perDayDismissKey(_ id: String, _ day: Date) -> String {
        dismissalSnapshot.perDayKey(id, day: day)
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
        CalendarEventDismissalSnapshot(ids: dismissed, calendar: .current)
            .isDismissed(eventID: eventKey(event), externalID: event.calendarItemExternalIdentifier, on: day)
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
        saveDismissedEventIDs(ids)
    }

    /// Hide a calendar event from the schedule for just this one day (the "Just for today" choice on
    /// a recurring event's ✕). Other occurrences of the series are unaffected.
    func dismissEvent(id: String, forDay day: Date) {
        var ids = dismissedEventIDs
        ids.insert(perDayDismissKey(id, day))
        saveDismissedEventIDs(ids)
    }

    /// Un-hide a previously dismissed event (the 👀 shown on a struck-through meeting when
    /// "Show dismissed events" is on). Clears both a whole-series dismissal and this day's single-day
    /// dismissal, whichever is present — either way, `day`'s occurrence reappears.
    func restoreDismissedEvent(id: String, forDay day: Date) {
        var ids = dismissedEventIDs
        ids.remove(id)
        ids.remove(perDayDismissKey(id, day))
        if let event = event(withID: id), let sk = seriesKey(event) { ids.remove(sk) }   // undo a series dismiss too
        saveDismissedEventIDs(ids)
    }

    /// Merge backend-hidden event ids (from another device) into the local dismissed set.
    func mergeDismissedEventIDs(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        let merged = dismissedEventIDs.union(ids)
        saveDismissedEventIDs(merged)
    }
}

/// Immutable dismissal rules shared by the Day Plan and the background forecast reader.
/// Per-day exclusions clip only that day's portion of a cross-midnight busy event.
struct CalendarEventDismissalSnapshot {
    let ids: Set<String>
    let calendar: Calendar

    func perDayKey(_ id: String, day: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar; formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(id)|day:\(formatter.string(from: day))"
    }

    func isDismissed(eventID: String, externalID: String?, on day: Date) -> Bool {
        if ids.contains(eventID) || ids.contains(perDayKey(eventID, day: day)) { return true }
        return externalID.map { !$0.isEmpty && ids.contains("series:" + $0) } ?? false
    }

    func visiblePortions(eventID: String, externalID: String?, start: Date, end: Date,
                         from rangeStart: Date, to rangeEnd: Date) -> [DateInterval] {
        let first = max(start, rangeStart), last = min(end, rangeEnd)
        guard last > first else { return [] }
        var day = calendar.startOfDay(for: first)
        var result: [DateInterval] = []
        while day < last {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day), next > day else { break }
            if !isDismissed(eventID: eventID, externalID: externalID, on: day) {
                result.append(DateInterval(start: max(first, day), end: min(last, next)))
            }
            day = next
        }
        return result
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

    #if DEBUG
    /// The last `PUT /to-do` status write this process attempted — see `setTodoStatus`. DEBUG only.
    static var lastTodoStatusWrite: (todoID: String, completed: Bool)?
    /// The last `PUT /to-do` importance write this process attempted — see `setTodoOutcome`. DEBUG only.
    static var lastTodoOutcomeWrite: (todoID: String, outcome: Int?)?
    #endif

    /// `true` only with a logged-in user + token — guests / logged-out skip all sync.
    var isAuthed: Bool {
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

    /// Fire the request; `completion(succeeded)` (optional, main thread) reports a 2xx so callers that
    /// must record the outcome — the project link — can, while the rest stay fire-and-forget.
    private func send(_ request: NSMutableURLRequest, label: String,
                      completion: ((_ succeeded: Bool) -> Void)? = nil) {
        guard isAuthed else { DispatchQueue.main.async { completion?(false) }; return }
        URLSession.shared.dataTask(with: request as URLRequest) { _, response, error in
            var succeeded = false
            if let error = error {
                addLog(text: "DayPlanSync \(label) error: \(error.localizedDescription)")
            } else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                succeeded = (200..<300).contains(code)
                if !succeeded { addLog(text: "DayPlanSync \(label) http \(code)") }
            }
            if let completion = completion { DispatchQueue.main.async { completion(succeeded) } }
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
    ///
    /// `column` moves the card on the project board in the SAME write. Flipping the status alone left
    /// finished tasks sitting in "To Do", where the kanban, web, mobile and the server's own
    /// `exclude_completed` all still read them as outstanding (report 2026-09-15_17-41-45). Keys the
    /// body omits are left as they are by the backend, so `.leaveAlone` preserves the stored column
    /// rather than clearing it — and one PUT means the status and the column cannot half-fail.
    func setTodoStatus(todoID: String, title: String, quadrant: Int, completed: Bool,
                       column: ToDoCompletionState.ColumnWrite = .leaveAlone) {
        #if DEBUG
        // Test seam: lets a test prove a completion that arrived FROM the server (the `todo-completed`
        // Pusher event) doesn't echo a write back at it. Never read by the app itself.
        Self.lastTodoStatusWrite = (todoID: todoID, completed: completed)
        #endif
        var body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "status": completed ? "COMPLETED" : "NOT_STARTED",
        ]
        if case .move(let columnID) = column { body["custom_status_id"] = columnID }
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
        body["due_date"] = (dueDate ?? plannedDate).map { dayString($0) } ?? NSNull()
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoPlanned")
    }

    // MARK: Projects (native Focus Bear projects: `POST /projects`, `to-do.project_id`)

    /// What a `setTodoProject` push ended up doing, so the store can record (or not) the link.
    enum ProjectLinkOutcome {
        case linked(projectID: String)
        case cleared
        case failed
    }

    /// Resolve a project NAME to a backend project id: the cached `/projects` entry (case-insensitive),
    /// else `POST /projects` — deduped while in flight, so ten tasks given `#thesis` at once make ONE
    /// project. If the projects list hasn't loaded yet it is fetched first: a name that merely hasn't
    /// loaded must not be created a second time. `completion(nil)` on failure (offline / not authed /
    /// the list fetch didn't land), always on the main thread.
    func ensureProjectSynced(named name: String, completion: @escaping (String?) -> Void) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, isAuthed else { DispatchQueue.main.async { completion(nil) }; return }
        let store = DayPlanTaskStore.shared
        if let id = store.remoteProjectID(named: trimmed) {
            DispatchQueue.main.async { completion(id) }
            return
        }
        guard store.remoteProjectsLoaded else {
            store.refreshRemoteProjects { [weak self] loaded in
                guard loaded, let self = self else { completion(nil); return }
                if let id = store.remoteProjectID(named: trimmed) { completion(id); return }
                self.createProject(named: trimmed, completion: completion)
            }
            return
        }
        createProject(named: trimmed, completion: completion)
    }

    /// Points `todoID` at the backend project named `projectName` — creating the project first when
    /// the name is new — so a `#project` typed in the Day Plan shows up on web and mobile (they read
    /// `project_id`; a project that only lives in this Mac's UserDefaults is invisible to them). `nil`
    /// / empty clears the project. `title` + `quadrant` are echoed back like every other upsert here.
    ///
    /// The upsert replaces the to-do's WHOLE tag list, so the web's convention (`ensureProjectTaskTags`
    /// in the dashboard) is mirrored: `labelTags` plus exactly one `{ id: projectID, text: name }` tag.
    /// When the label tags aren't known (`labelTags` nil — a task stored before they were captured)
    /// `tags` is omitted so the backend keeps whatever it has rather than losing the user's labels.
    /// Go through `DayPlanTaskStore.syncProject(of:)`, which records the outcome, not this directly.
    func setTodoProject(todoID: String, title: String, quadrant: Int, projectName: String?,
                        labelTags: [DayPlanTaskTag]?, completion: @escaping (ProjectLinkOutcome) -> Void) {
        let name = (projectName ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            upsertTodoProject(todoID: todoID, title: title, quadrant: quadrant, projectID: nil, tags: labelTags) {
                completion($0 ? .cleared : .failed)
            }
            return
        }
        ensureProjectSynced(named: name) { [weak self] projectID in
            guard let self = self, let projectID = projectID else { completion(.failed); return }
            let tags = labelTags.map {
                DayPlanProjectSyncRules.ensureProjectTag($0, projectID: projectID, projectName: name)
            }
            self.upsertTodoProject(todoID: todoID, title: title, quadrant: quadrant, projectID: projectID, tags: tags) {
                completion($0 ? .linked(projectID: projectID) : .failed)
            }
        }
    }

    private func upsertTodoProject(todoID: String, title: String, quadrant: Int, projectID: String?,
                                   tags: [DayPlanTaskTag]?, completion: @escaping (_ succeeded: Bool) -> Void) {
        var body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "project_id": projectID ?? NSNull(),
        ]
        if let tags = tags { body["tags"] = tags.map { ["id": $0.id, "text": $0.text] } }
        guard let req = request("/to-do", method: "PUT", body: body) else {
            DispatchQueue.main.async { completion(false) }; return
        }
        send(req, label: "setTodoProject", completion: completion)
    }

    /// Completions waiting on an in-flight `POST /projects`, keyed by lowercased name, so two tasks
    /// given the same new project before the first create returns share one project.
    private var pendingProjectCreations: [String: [(String?) -> Void]] = [:]

    /// `POST /projects { name }` → the new project's id (nil on failure), registered with the task
    /// store so later assignments resolve it locally. `completion` runs on the main thread.
    /// Prefer `ensureProjectSynced(named:)`, which looks the name up first.
    private func createProject(named name: String, completion: @escaping (String?) -> Void) {
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
    /// Change who a to-do is assigned to. `assigneeID` nil is the picker's "Unassigned", sent as an
    /// explicit null so the backend clears the field.
    ///
    /// A PARTIAL body on purpose. The full upsert also carries `assigned_mcp_token_id`, which nothing
    /// here can read (`GET /to-do` never returns it) — sending it would wipe an agent's claim on the
    /// task, which is exactly the bug behind backend#2414. A key that is absent is left alone, so this
    /// touches the assignment and nothing else.
    ///
    /// `completion(false)` also covers the 401 from backend#2413: `validateUpdatingToDo` gates every
    /// write on `existingToDo.user_id === userId` and never consults project membership, so a member
    /// editing a task somebody else created is refused. The caller has to show that rather than let
    /// the menu sit on a value the server rejected.
    func setTodoAssignee(todoID: String, title: String, quadrant: Int, assigneeID: String?,
                         completion: @escaping (_ succeeded: Bool) -> Void) {
        let body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "assignee_id": assigneeID ?? NSNull(),
        ]
        guard let req = request("/to-do", method: "PUT", body: body) else {
            DispatchQueue.main.async { completion(false) }; return
        }
        send(req, label: "setTodoAssignee", completion: completion)
    }

    /// Push a Day Plan task's importance (`outcome`, the /10 wire scale) onto its backend to-do. A nil
    /// outcome is sent as JSON null — "unrated" — so clearing importance in the Day Plan clears it
    /// everywhere rather than leaving the old value to come back on the next refresh.
    func setTodoOutcome(todoID: String, title: String, quadrant: Int, outcome: Int?) {
        #if DEBUG
        Self.lastTodoOutcomeWrite = (todoID: todoID, outcome: outcome)
        #endif
        let body: [String: Any] = [
            "id": todoID,
            "title": title,
            "eisenhower_quadrant": quadrant,
            "outcome": outcome.map { $0 as Any } ?? NSNull(),
        ]
        guard let req = request("/to-do", method: "PUT", body: body) else { return }
        send(req, label: "setTodoOutcome")
    }

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
