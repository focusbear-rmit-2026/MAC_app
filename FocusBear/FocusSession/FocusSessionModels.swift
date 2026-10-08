//
//  FocusSessionModels.swift
//  Focus Bear
//
//  Pure model + logic layer for the ongoing-focus-session screen: the session task queue, the
//  countdown arithmetic and the task-picker filtering. Deliberately free of AppKit/SwiftUI and of the
//  app's globals so every rule here is unit-testable (see FocusBearTests/FocusSessionTests.swift).
//
//  The queue is NOT a new data store. It is the same JSON array the To Do Player and the focus-mode
//  start paths already exchange through `focusModeTaskString`, persisted as the focus mode's
//  `lastTaskUsed` field. These types just give it a typed shape.
//

import Foundation

/// Backend to-do status, as it appears in the queue JSON.
enum FocusSessionTaskStatus: String, CaseIterable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"

    var isCompleted: Bool { self == .completed }
}

/// One task in the focus session's queue.
struct FocusSessionTask: Equatable, Identifiable {
    var id: String
    var title: String
    var details: String
    var durationSeconds: Int
    var status: FocusSessionTaskStatus
    /// The task the session is currently working on — the To Do Player's "playing" flag.
    var isActive: Bool
    /// The to-do's emoji and backend-computed TOP score, when the row came from the to-do API.
    var topScore: Double?
    var iconEmoji: String?
    /// Resolved project name, shown as a chip on the active-task card.
    var projectName: String?

    /// A queue entry needs a duration even when the source to-do has none; the To Do Player defaults
    /// new tasks to ten minutes and we match it so the two stay consistent.
    static let defaultDurationSeconds = 600

    init(id: String,
         title: String,
         details: String = "",
         durationSeconds: Int = FocusSessionTask.defaultDurationSeconds,
         status: FocusSessionTaskStatus = .notStarted,
         isActive: Bool = false,
         topScore: Double? = nil,
         iconEmoji: String? = nil,
         projectName: String? = nil) {
        self.id = id
        self.title = title
        self.details = details
        self.durationSeconds = durationSeconds
        self.status = status
        self.isActive = isActive
        self.topScore = topScore
        self.iconEmoji = iconEmoji
        self.projectName = projectName
    }

    var durationMinutes: Int { max(1, Int((Double(durationSeconds) / 60.0).rounded())) }
}

/// Keys of the queue JSON. Renaming any of these breaks the exchange with the To Do Player web app.
private enum FocusSessionTaskKey {
    static let id = "id"
    static let title = "title"
    static let details = "details"
    static let duration = "duration"
    static let status = "status"
    static let isPlaying = "isPlaying"
    static let topScore = "top_score"
    static let icon = "icon"
    static let projectName = "project_name"
}

/// Reads and rewrites the session task queue. Every mutation returns a new array so the caller can
/// diff, persist and publish in one place.
enum FocusSessionTaskQueue {
    /// Parses `focusModeTaskString`. An empty, `"[]"` or malformed string is an empty queue — the
    /// screen must never fail to render because the player wrote something unexpected.
    static func decode(_ json: String) -> [FocusSessionTask] {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "[]", let data = trimmed.data(using: .utf8) else { return [] }
        guard let raw = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return [] }
        return raw.compactMap(task(from:))
    }

    private static func task(from raw: [String: Any]) -> FocusSessionTask? {
        let id = raw[FocusSessionTaskKey.id] as? String ?? ""
        let title = raw[FocusSessionTaskKey.title] as? String ?? ""
        // An entry with neither an id nor a title is not something the user can act on.
        guard !id.isEmpty || !title.isEmpty else { return nil }
        let statusText = raw[FocusSessionTaskKey.status] as? String ?? FocusSessionTaskStatus.notStarted.rawValue
        return FocusSessionTask(
            id: id,
            title: title,
            details: raw[FocusSessionTaskKey.details] as? String ?? "",
            durationSeconds: durationSeconds(from: raw[FocusSessionTaskKey.duration]),
            status: FocusSessionTaskStatus(rawValue: statusText.uppercased()) ?? .notStarted,
            isActive: raw[FocusSessionTaskKey.isPlaying] as? Bool ?? false,
            topScore: raw[FocusSessionTaskKey.topScore] as? Double,
            iconEmoji: FocusSessionEmoji.decode(raw[FocusSessionTaskKey.icon] as? String),
            projectName: raw[FocusSessionTaskKey.projectName] as? String
        )
    }

    /// The player and the to-do API have both written durations as numbers and as strings.
    static func durationSeconds(from value: Any?) -> Int {
        if let seconds = value as? Int { return seconds }
        if let seconds = value as? Double { return Int(seconds) }
        if let text = value as? String, let seconds = Int(text) { return seconds }
        return FocusSessionTask.defaultDurationSeconds
    }

    /// Serialises back into the shape `focusModeTaskString` holds.
    static func encode(_ tasks: [FocusSessionTask]) -> String {
        let raw: [[String: Any]] = tasks.map { task in
            [
                FocusSessionTaskKey.id: task.id,
                FocusSessionTaskKey.title: task.title,
                FocusSessionTaskKey.details: task.details,
                FocusSessionTaskKey.duration: task.durationSeconds,
                FocusSessionTaskKey.status: task.status.rawValue,
                FocusSessionTaskKey.isPlaying: task.isActive,
                FocusSessionTaskKey.topScore: task.topScore ?? NSNull(),
                FocusSessionTaskKey.icon: task.iconEmoji ?? NSNull(),
                FocusSessionTaskKey.projectName: task.projectName ?? NSNull(),
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: raw),
              let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }

    /// The task the session is working on: the flagged one, else the first task still to do.
    static func activeTask(in tasks: [FocusSessionTask]) -> FocusSessionTask? {
        tasks.first(where: { $0.isActive && !$0.status.isCompleted })
            ?? tasks.first(where: { !$0.status.isCompleted })
    }

    /// Tasks shown in the queue below the active card: everything else, completed included (the
    /// design strikes completed rows through rather than hiding them).
    static func queuedTasks(in tasks: [FocusSessionTask]) -> [FocusSessionTask] {
        guard let active = activeTask(in: tasks) else { return tasks }
        return tasks.filter { $0.id != active.id || $0.title != active.title }
    }

    /// What the queue still owes: completed rows stay on screen (struck through) but they are not
    /// outstanding work, so the heading counts these instead of every row. The heading read
    /// "Task Queue (1)" with its only task already ticked off (report 2026-09-15_16-46-10).
    static func outstanding(in tasks: [FocusSessionTask]) -> [FocusSessionTask] {
        tasks.filter { !$0.status.isCompleted }
    }

    /// Makes one task the active one; any other task loses the flag.
    static func focusing(_ tasks: [FocusSessionTask], on id: String) -> [FocusSessionTask] {
        tasks.map { task in
            var updated = task
            updated.isActive = task.id == id
            return updated
        }
    }

    /// Completes a task and hands the session on to the next thing to do, so the user is never left
    /// with an empty active card while unfinished work is still queued.
    static func completing(_ tasks: [FocusSessionTask], id: String) -> [FocusSessionTask] {
        var updated = tasks.map { task -> FocusSessionTask in
            guard task.id == id else { return task }
            var completed = task
            completed.status = .completed
            completed.isActive = false
            return completed
        }
        if let next = updated.first(where: { !$0.status.isCompleted }) {
            updated = focusing(updated, on: next.id)
        }
        return updated
    }

    /// Drops a task from the queue, promoting the next one if the removed task was active.
    static func removing(_ tasks: [FocusSessionTask], id: String) -> [FocusSessionTask] {
        let wasActive = tasks.first(where: { $0.id == id })?.isActive ?? false
        var remaining = tasks.filter { $0.id != id }
        if wasActive, let next = remaining.first(where: { !$0.status.isCompleted }) {
            remaining = focusing(remaining, on: next.id)
        }
        return remaining
    }

    /// Appends tasks the queue doesn't already hold. Adding to an empty queue also makes the first
    /// new task active, so a session started without a task immediately has one.
    static func appending(_ tasks: [FocusSessionTask], newTasks: [FocusSessionTask]) -> [FocusSessionTask] {
        let existingIds = Set(tasks.map { $0.id })
        let additions = newTasks.filter { !existingIds.contains($0.id) }
        guard !additions.isEmpty else { return tasks }
        var combined = tasks + additions
        if activeTask(in: tasks) == nil, let first = combined.first(where: { !$0.status.isCompleted }) {
            combined = focusing(combined, on: first.id)
        }
        return combined
    }

    /// Reorders the queue by one position — the keyboard/menu equivalent of the design's drag handle.
    static func moving(_ tasks: [FocusSessionTask], id: String, by offset: Int) -> [FocusSessionTask] {
        guard offset != 0, let index = tasks.firstIndex(where: { $0.id == id }) else { return tasks }
        let destination = index + offset
        guard tasks.indices.contains(destination) else { return tasks }
        var reordered = tasks
        reordered.swapAt(index, destination)
        return reordered
    }
}

/// The two *different* questions the app kept answering with one flag.
///
/// A **custom blocking schedule is not a focus session**. A schedule activates a block list on a
/// timetable and runs itself; a focus session is something a person deliberately starts, gives a goal
/// and a task queue, and can stop. Report 2026-09-16_15-13-57: with an all-day schedule covering
/// 06:00–18:13, the Focus Session screen claimed "Ongoing Focus Session" for the whole working day and
/// there was no way left to start a real one.
///
/// So: ask `isInSession` when deciding whether to show the running-session UI, and `isBlockingActive`
/// when deciding whether anything is blocking right now (badges, AI/URL checks, the headless player).
/// Pure, so both can be tested without AppKit or the app's globals.
enum FocusSessionPresence {
    /// Is the user in a focus session right now — running, paused, or a super-focus (hardcore
    /// pomodoro) session? A blocking schedule is deliberately NOT part of this.
    static func isInSession(isFocusModeOn: Bool,
                            isFocusModePaused: Bool,
                            isSuperFocusOn: Bool) -> Bool {
        isFocusModeOn || isFocusModePaused || isSuperFocusOn
    }

    /// Is anything blocking right now — a focus session, an allowed routine activity, or a custom
    /// blocking schedule? Says nothing about whether a session is running.
    static func isBlockingActive(isInSession: Bool,
                                 isAllowedActivityRunning: Bool,
                                 isCustomScheduleOn: Bool) -> Bool {
        isInSession || isAllowedActivityRunning || isCustomScheduleOn
    }

    /// `isInSession` read off the app's live globals, so callers don't re-assemble them (and can't
    /// quietly leave one out).
    static var isInSessionNow: Bool {
        isInSession(isFocusModeOn: isFocusModeOn(),
                    isFocusModePaused: isFocusModePaused(),
                    isSuperFocusOn: isHardCorePomodoroModeOn)
    }

    /// `isBlockingActive` read off the app's live globals.
    static var isBlockingActiveNow: Bool {
        isBlockingActive(isInSession: isInSessionNow,
                         isAllowedActivityRunning: isAnyAllowedFocusModeActivityRunning,
                         isCustomScheduleOn: customBlockingScheduleManagerObj.isAnyCustomScheduleOn)
    }
}

/// Rules about where the app should be pointed, and what still needs refreshing, when a focus session
/// starts or resumes. Pure so the conditions can be tested without AppKit.
enum FocusSessionRouting {
    /// Whether the headless To-do Player webview should be reloaded now.
    ///
    /// The player has no screen any more, so this can no longer ride on "the player was displayed".
    /// It reloads when a session-start path has flagged it *and* something is actually blocking — the
    /// same pair of conditions the display path used to check.
    static func shouldReloadHeadlessPlayer(isReloadPending: Bool, isBlockingActive: Bool) -> Bool {
        isReloadPending && isBlockingActive
    }

    /// Which screen the Focus Session tab should be showing.
    enum Destination {
        /// The ongoing-session screen: goal, countdown, task queue, End Session.
        case runningSession
        /// The start-a-session screen (simple or advanced, per geek mode).
        case startSession
    }

    /// Whether the Focus Session tab has a session to show, or should offer to start one.
    ///
    /// A focus session (running, paused or super-focus) has one. So does an allowed routine activity —
    /// it is a live blocking activity with its own task queue, and the routine paths that ask for this
    /// screen are mid-activity. A **custom blocking schedule does not**: it blocks on a timetable, it
    /// has no clock to count down, nothing to pause and nothing to end, so sending it here left the
    /// screen claiming "Ongoing Focus Session" all day with no way to start a real one.
    static func destination(isInSession: Bool, isAllowedActivityRunning: Bool) -> Destination {
        (isInSession || isAllowedActivityRunning) ? .runningSession : .startSession
    }

    /// `destination` read off the app's live globals.
    static var destinationNow: Destination {
        destination(isInSession: FocusSessionPresence.isInSessionNow,
                    isAllowedActivityRunning: isAnyAllowedFocusModeActivityRunning)
    }

    /// What landing on the Focus Session row should do to the main window.
    enum WindowSizing {
        /// Leave the borderless full-screen window filling the screen.
        case keepFullScreen
        /// The borderless window is up but full-screen mode is off — put the title bar back.
        case restoreSmallWindow
        /// A normal titled window: don't touch its size.
        case leaveAsIs
    }

    /// Decides whether showing the running-session screen may resize the main window.
    ///
    /// Starting a session must not resize the window the user sized themselves. Session start selects
    /// the Focus Session row, and every `isSelected = true` re-fires the selection delegate, so whatever
    /// that row does to the window happens on every session start. It used to call
    /// `showSmallScreen(showMinimumSize: true)`, which normalises the content size to 1008x600 whenever
    /// the window differs by more than 100pt — so starting a session snapped a resized window back to
    /// the default, and dropped a full-screen routine out of its borderless window.
    ///
    /// The one case where filling the screen is deliberate is the app's own borderless full-screen mode
    /// (`showFullSizeWindow()`, styleMask `[.borderless, .resizable]`) — NOT macOS's green-button full
    /// screen. While a routine, micro-break or shut-off owns the whole screen that way, shrinking to a
    /// 1008x600 titled window mid-activity would expose the desktop the mode exists to cover. So the
    /// window is only touched when that borderless window is actually up: kept if the mode is still on,
    /// and given its title bar back if the setting has since been turned off (otherwise the user is left
    /// in a borderless window with no way to move or close it).
    static func windowSizing(isFullScreenWindowVisible: Bool,
                             isFullScreenModeEnabled: Bool) -> WindowSizing {
        guard isFullScreenWindowVisible else { return .leaveAsIs }
        return isFullScreenModeEnabled ? .keepFullScreen : .restoreSmallWindow
    }
}

/// How long the user has been on the current task in this session.
///
/// Nothing in the app or the backend records per-task time — there is no `time_spent` on a to-do and
/// no per-task timer — so this is derived from the moment the task became active. It therefore counts
/// **time on this task in this session only**: it resets when the active task changes and when the app
/// restarts, and it is deliberately not persisted, because a persisted timestamp would keep counting
/// across a restart and over-report time the user did not spend working.
///
/// It stops while the session is paused, so a paused session doesn't accrue task time.
struct FocusSessionTaskTimer: Equatable {
    private(set) var taskId: String?
    private(set) var accumulatedSeconds: Int = 0
    private(set) var runningSince: Date?

    var isRunning: Bool { runningSince != nil }

    func elapsedSeconds(now: Date = Date()) -> Int {
        guard let since = runningSince else { return accumulatedSeconds }
        return accumulatedSeconds + max(0, Int(now.timeIntervalSince(since)))
    }

    /// Points the timer at a task. Switching to a different task starts its count from zero; being
    /// told the same task again is a no-op, so a refresh doesn't reset the clock.
    mutating func activate(taskId newId: String?, now: Date = Date()) {
        guard newId != taskId else {
            if newId != nil, runningSince == nil { runningSince = now }
            return
        }
        taskId = newId
        accumulatedSeconds = 0
        runningSince = newId == nil ? nil : now
    }

    mutating func pause(now: Date = Date()) {
        guard let since = runningSince else { return }
        accumulatedSeconds += max(0, Int(now.timeIntervalSince(since)))
        runningSince = nil
    }

    mutating func resume(now: Date = Date()) {
        guard taskId != nil, runningSince == nil else { return }
        runningSince = now
    }
}

/// Where the task picker's rows came from, so the sheet can say so.
enum FocusSessionPickerSource {
    /// Today's Day Plan, in the order the user arranged it.
    case dayPlan
    /// The to-do list in SMART order — used when the Day Plan is empty for today.
    case toDoList
    /// A search across the whole to-do list.
    case search
}

/// The two things a relevance check needs. They are separate values and the endpoint takes separate
/// fields for them (`intention` and `currentTaskInToDoPlayer`) — collapsing them is what made the AI
/// judge against a goal the user had moved on from.
struct FocusSessionWorkContext: Equatable {
    /// The session's stated goal. Locked in a super-strict session.
    var intention: String
    /// What the user is working on right now, if the queue has an active task.
    var currentTask: String?

    static func resolve(activeTaskTitle: String?, intention: String) -> FocusSessionWorkContext {
        let task = (activeTaskTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return FocusSessionWorkContext(intention: intention.trimmingCharacters(in: .whitespacesAndNewlines),
                                       currentTask: task.isEmpty ? nil : task)
    }
}

/// Whether a caller outside the session screen may change each value.
///
/// Changing the current task is always allowed — it is what the user is doing. Changing the intention
/// is the session's stated goal and a super-strict session forbids it, so nothing outside the goal
/// editor may write it.
enum FocusSessionIntentionLock {
    static func mayChangeIntention(isSuperStrict: Bool) -> Bool { !isSuperStrict }
    /// The buddy and the block popup set the task, never the goal, in every strictness.
    static func mayChangeCurrentTask(isSuperStrict: Bool) -> Bool { true }
}

/// Countdown and progress arithmetic for the session timer.
enum FocusSessionClock {
    static let secondsPerMinute = 60
    static let secondsPerHour = 3600

    /// Never negative — an overrun session reads as "0 sec" rather than counting backwards.
    static func remainingSeconds(until end: Date, now: Date) -> Int {
        max(0, Int(end.timeIntervalSince(now).rounded(.down)))
    }

    /// The design's headline format: "24 min 36 sec", growing to "1 hr 24 min" past the hour.
    static func headline(remainingSeconds seconds: Int, units: FocusSessionDurationUnits) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / secondsPerHour
        let minutes = (clamped % secondsPerHour) / secondsPerMinute
        let remainder = clamped % secondsPerMinute
        if hours > 0 {
            return "\(hours) \(units.hour) \(minutes) \(units.minute)"
        }
        if minutes > 0 {
            return "\(minutes) \(units.minute) \(remainder) \(units.second)"
        }
        return "\(remainder) \(units.second)"
    }

    /// Whole minutes left, rounded up so a session with 20 seconds to go still reads "1m" rather than
    /// "0m". Used by the left menu's "Focusing (Nm left)" row.
    static func minutesRemaining(until end: Date, now: Date = Date()) -> Int {
        let seconds = remainingSeconds(until: end, now: now)
        return Int((Double(seconds) / Double(secondsPerMinute)).rounded(.up))
    }

    /// How long the session runs in total, for the progress bar.
    ///
    /// Extend, reduce, pause and resume all re-base the countdown: the time spent so far is banked in
    /// `performedSeconds` (`focusModeActualDurationPerformed`) and `segmentSeconds`
    /// (`focusModeSecondsToPerform`) restarts as the length of the stretch from then on. The total is
    /// the banked time plus that stretch. Reading the stretch alone dropped the time already spent, so
    /// after +5 the bar restarted at zero and the total came up short by exactly that much (#2689).
    ///
    /// Pass `segmentSeconds` as 0 while paused: pausing banks the spent part of the stretch without
    /// shortening it, so the stretch would count that time twice — `remainingSeconds` is the rest.
    ///
    /// `remainingSeconds` also guards the stretch: a stale `focusModeSecondsToPerform` left over from a
    /// previous session can be *shorter* than the time remaining, and a total below `remaining` makes
    /// elapsed clamp to zero — a bar that never advances and a total that contradicts the countdown.
    /// `plannedMinutes` is the requested length, kept current by extend and reduce, and is the floor
    /// for a session whose stretch isn't known.
    static func sessionTotalSeconds(plannedMinutes: Int, performedSeconds: Int, segmentSeconds: Int,
                                    remainingSeconds: Int) -> Int {
        let timerTotal = max(0, performedSeconds) + max(segmentSeconds, remainingSeconds)
        return max(plannedMinutes * secondsPerMinute, timerTotal)
    }

    /// The requested length after +N / −N minutes. Never negative: reducing past the end finishes the
    /// session instead.
    static func plannedMinutes(_ plannedMinutes: Int, changedBy deltaMinutes: Int) -> Int {
        max(0, plannedMinutes + deltaMinutes)
    }

    /// A short elapsed reading for the active-task card: seconds in the first minute, then whole
    /// minutes, then hours and minutes. Deliberately coarse so the card isn't ticking every second.
    static func compactElapsed(seconds: Int, units: FocusSessionDurationUnits) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / secondsPerHour
        let minutes = (clamped % secondsPerHour) / secondsPerMinute
        if hours > 0 { return "\(hours) \(units.hour) \(minutes) \(units.minute)" }
        if clamped >= secondsPerMinute { return "\(minutes) \(units.minute)" }
        return "\(clamped) \(units.second)"
    }

    /// Zero-padded clock text — "07:12" under an hour, "01:07:12" over it.
    static func clockText(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / secondsPerHour
        let minutes = (clamped % secondsPerHour) / secondsPerMinute
        let remainder = clamped % secondsPerMinute
        let padded = { (value: Int) in String(format: "%02d", value) }
        if hours > 0 {
            return "\(padded(hours)):\(padded(minutes)):\(padded(remainder))"
        }
        return "\(padded(minutes)):\(padded(remainder))"
    }

    /// Fraction of the session already spent, clamped to 0…1 for the progress bar.
    static func progress(elapsedSeconds: Int, totalSeconds: Int) -> Double {
        guard totalSeconds > 0 else { return 0 }
        return min(1, max(0, Double(elapsedSeconds) / Double(totalSeconds)))
    }
}

/// Words used to build the countdown headline. Config-driven so Spanish reads correctly.
struct FocusSessionDurationUnits {
    var hour: String
    var minute: String
    var second: String
}

/// A to-do offered in the "add from existing tasks" picker, and the row the edit sheet works on.
/// `raw` is the payload the server sent, kept verbatim so an edit can be sent back as a full upsert
/// without dropping fields this screen doesn't know about.
struct FocusSessionPickerTask: Identifiable {
    var id: String
    var title: String
    var details: String
    var durationSeconds: Int
    var status: FocusSessionTaskStatus
    var topScore: Double?
    var iconEmoji: String?
    var outcome: Int?
    var perspirationLevel: Int
    var projectId: String?
    /// Resolved project name, shown as a chip. From the Day Plan's own project, or resolved from
    /// `project_id` / the project tag the way the To-do list does.
    var projectName: String?
    var dueDate: Date?
    var raw: [String: Any]

    init(id: String,
         title: String,
         details: String = "",
         durationSeconds: Int = FocusSessionTask.defaultDurationSeconds,
         status: FocusSessionTaskStatus = .notStarted,
         topScore: Double? = nil,
         iconEmoji: String? = nil,
         outcome: Int? = nil,
         perspirationLevel: Int = FocusSessionScoring.minimum,
         projectId: String? = nil,
         projectName: String? = nil,
         dueDate: Date? = nil,
         raw: [String: Any] = [:]) {
        self.id = id
        self.title = title
        self.details = details
        self.durationSeconds = durationSeconds
        self.status = status
        self.topScore = topScore
        self.iconEmoji = iconEmoji
        self.outcome = outcome
        self.perspirationLevel = perspirationLevel
        self.projectId = projectId
        self.projectName = projectName
        self.dueDate = dueDate
        self.raw = raw
    }

    var asQueueTask: FocusSessionTask {
        FocusSessionTask(id: id, title: title, details: details, durationSeconds: durationSeconds,
                         status: status, topScore: topScore, iconEmoji: iconEmoji,
                         projectName: projectName)
    }

    /// The edit sheet's starting point.
    var edits: FocusSessionTaskEdits {
        FocusSessionTaskEdits(title: title, details: details, status: status, dueDate: dueDate,
                              outcome: outcome, perspirationLevel: perspirationLevel, projectId: projectId,
                              durationMinutes: max(1, Int((Double(durationSeconds) / 60).rounded())))
    }

    /// `raw` is untyped, so equality is on the fields the UI actually renders.
    static func == (lhs: FocusSessionPickerTask, rhs: FocusSessionPickerTask) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.details == rhs.details
            && lhs.durationSeconds == rhs.durationSeconds && lhs.status == rhs.status
            && lhs.topScore == rhs.topScore && lhs.iconEmoji == rhs.iconEmoji
            && lhs.outcome == rhs.outcome && lhs.perspirationLevel == rhs.perspirationLevel
            && lhs.projectId == rhs.projectId && lhs.projectName == rhs.projectName
            && lhs.dueDate == rhs.dueDate
    }

    /// Builds a picker row from the app's canonical to-do model.
    ///
    /// Everything derived — the TOP score, the duration — goes through `ToDoScoring`, the same helpers
    /// the native To-do list and the editor use, rather than being read straight off the payload:
    ///
    ///   * `top_score` is only materialised server-side on write, so a stored value goes stale as soon
    ///     as the due date moves and every row can read the same number. `ToDoScoring.topScore(of:)`
    ///     recomputes it from outcome / perspiration / due date and falls back to the stored value only
    ///     for rows carrying none of those inputs.
    ///   * `duration` is often absent, in which case the effort implied by the perspiration level is
    ///     the real answer — `ToDoScoring.durationSeconds(explicit:perspiration:)`. Reading the raw
    ///     field alone made every row show the same minimum.
    static func make(from task: ToDoTask, now: Date = Date()) -> FocusSessionPickerTask? {
        guard !task.id.isEmpty, !task.title.isEmpty else { return nil }
        return FocusSessionPickerTask(
            id: task.id,
            title: task.title,
            details: task.details ?? "",
            durationSeconds: ToDoScoring.durationSeconds(explicit: task.duration?.value,
                                                         perspiration: task.effectivePerspiration),
            status: FocusSessionTaskStatus(rawValue: task.defaultStatus.rawValue) ?? .notStarted,
            topScore: ToDoScoring.topScore(of: task, now: now),
            iconEmoji: task.iconEmoji,
            outcome: task.outcome.map(FocusSessionScoring.clamp),
            perspirationLevel: FocusSessionScoring.clamp(task.effectivePerspiration),
            projectId: task.project_id,
            // This branch's `projectName` takes a TodoProjectFields, not the (id, tags) pair main has.
            projectName: DayPlanTaskStore.shared.projectName(
                for: TodoProjectFields(todo: ["project_id": task.project_id as Any,
                                              "tags": task.tagList.map { ["id": $0.id, "text": $0.text] }])),
            dueDate: FocusSessionDates.parse(task.due_date),
            raw: FocusSessionPickerTask.payload(of: task)
        )
    }

    /// Retain a picker payload for display. Editing always obtains a fresh by-ID snapshot.
    private static func payload(of task: ToDoTask) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(task),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [FocusSessionToDoKey.id: task.id]
        }
        return object
    }
}

/// Filtering rules for the task picker.
enum FocusSessionTaskFilter {
    /// Orders picker rows exactly as the Day Plan and the native To-do list do — `ToDoSorting.sort`
    /// in SMART mode. The endpoint returns SMART order already, but any client-side filtering or
    /// merging can disturb it, so the canonical comparator is applied rather than trusting the wire
    /// order (and rather than writing a second comparator here).
    static func ordered(_ tasks: [FocusSessionPickerTask], sourceTasks: [ToDoTask], now: Date = Date()) -> [FocusSessionPickerTask] {
        let rank = Dictionary(uniqueKeysWithValues:
            ToDoSorting.sort(sourceTasks, by: .smart, now: now).enumerated().map { ($0.element.id, $0.offset) })
        return tasks.enumerated().sorted { lhs, rhs in
            let l = rank[lhs.element.id] ?? Int.max
            let r = rank[rhs.element.id] ?? Int.max
            return l == r ? lhs.offset < rhs.offset : l < r
        }.map { $0.element }
    }

    /// Case- and diacritic-insensitive substring match on the title, narrowed further by the filter
    /// sheet. Tasks already queued and finished tasks are excluded — the picker only offers new work.
    static func matching(_ tasks: [FocusSessionPickerTask],
                         query: String,
                         excludingIds excluded: Set<String>,
                         filters: FocusSessionTaskFilters = .none,
                         now: Date = Date()) -> [FocusSessionPickerTask] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return tasks.filter { task in
            guard !excluded.contains(task.id) else { return false }
            guard !task.status.isCompleted else { return false }
            guard filters.matches(task, now: now) else { return false }
            guard !trimmed.isEmpty else { return true }
            return task.title.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    /// Case- and diacritic-insensitive project search, for the filter sheet's project field.
    static func matching(_ projects: [FocusSessionProject], query: String) -> [FocusSessionProject] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return projects }
        return projects.filter { $0.name.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
}

// MARK: - To-do fields

/// Keys of the `/to-do` payload. The same names are read from `GET /to-do` and written back by
/// `PUT /to-do`, so they live in one place.
enum FocusSessionToDoKey {
    static let id = "id"
    static let title = "title"
    static let details = "details"
    static let status = "status"
    static let dueDate = "due_date"
    static let duration = "duration"
    static let outcome = "outcome"
    static let perspirationLevel = "perspiration_level"
    static let topScore = "top_score"
    static let icon = "icon"
    static let projectId = "project_id"
    static let name = "name"
}

/// The 1…10 scales the backend stores for a to-do's TOP score inputs.
enum FocusSessionScoring {
    static let minimum = 1
    static let maximum = 10
    /// The design's "Low spoons (1-3)" / "Full Spoons (4-10)" split.
    static let lowSpoonsUpperBound = 3

    static func clamp(_ value: Int) -> Int { min(maximum, max(minimum, value)) }
}

/// `icon` comes back either as an emoji glyph or as a hex "unified" code ("1f4da", "1f1e6-1f1e8").
/// Mirrors `ToDoTask.iconEmoji` on the native to-do branch so both render the same glyph.
enum FocusSessionEmoji {
    static func decode(_ icon: String?) -> String? {
        guard let trimmed = icon?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty else { return nil }
        let parts = trimmed.lowercased().split(separator: "-")
        let looksLikeHexCode = parts.allSatisfy { part in
            part.count >= 4 && part.count <= 6 && part.allSatisfy { $0.isHexDigit }
        }
        guard looksLikeHexCode else { return trimmed }
        var glyph = ""
        for part in parts {
            guard let value = UInt32(part, radix: 16), let scalar = Unicode.Scalar(value) else { return trimmed }
            glyph.unicodeScalars.append(scalar)
        }
        return glyph
    }
}

/// Dates on the to-do API are ISO-8601; `due_date` is sometimes a plain `yyyy-MM-dd`.
enum FocusSessionDates {
    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    static let apiFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    static let dayFormat = "yyyy-MM-dd"

    static func parse(_ text: String?) -> Date? {
        guard let text = text, !text.isEmpty else { return nil }
        if let date = formatter(apiFormat).date(from: text) { return date }
        if let date = formatter("yyyy-MM-dd'T'HH:mm:ss'Z'").date(from: text) { return date }
        return formatter(dayFormat).date(from: text)
    }

    static func apiString(_ date: Date) -> String { formatter(apiFormat).string(from: date) }

    /// Whole days from `now` to `date`, negative when the date has passed.
    static func daysFromNow(to date: Date, now: Date = Date()) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let from = calendar.startOfDay(for: now)
        let to = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }
}

/// A project the filter sheet can narrow the picker by.
struct FocusSessionProject: Equatable, Identifiable {
    var id: String
    var name: String
    /// The project's `icon` as the backend stores it; decoded for display like a to-do's.
    var icon: String?
    var iconEmoji: String? { EmojiIcon.resolve(icon) }

    static func list(from raw: [NSDictionary]?) -> [FocusSessionProject] {
        guard let raw = raw else { return [] }
        return raw.compactMap { entry in
            guard let id = entry.value(forKey: FocusSessionToDoKey.id) as? String, !id.isEmpty,
                  let name = entry.value(forKey: FocusSessionToDoKey.name) as? String, !name.isEmpty else { return nil }
            return FocusSessionProject(id: id, name: name, icon: entry.value(forKey: FocusSessionToDoKey.icon) as? String)
        }
    }

    /// The icon to show beside a picker row's project chip. A Day Plan row carries only the project
    /// name it was imported with, so fall back to a name match when the row has no project id.
    static func icon(for projectId: String?, name: String?, in projects: [FocusSessionProject]) -> String? {
        if let projectId = projectId, !projectId.isEmpty,
           let match = projects.first(where: { $0.id == projectId }) { return match.iconEmoji }
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
        return projects.first { $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }?.iconEmoji
    }
}

// MARK: - Task editing

/// The fields the edit / create sheets can change. Omitted fields retain their server values.
struct FocusSessionTaskEdits: Equatable {
    var title: String
    var details: String
    var status: FocusSessionTaskStatus
    var dueDate: Date?
    var outcome: Int?
    var perspirationLevel: Int
    var projectId: String?
    var durationMinutes: Int?

    init(title: String = "",
         details: String = "",
         status: FocusSessionTaskStatus = .notStarted,
         dueDate: Date? = nil,
         outcome: Int? = nil,
         perspirationLevel: Int = FocusSessionScoring.minimum,
         projectId: String? = nil,
         durationMinutes: Int? = nil) {
        self.title = title
        self.details = details
        self.status = status
        self.dueDate = dueDate
        self.outcome = outcome
        self.perspirationLevel = perspirationLevel
        self.projectId = projectId
        self.durationMinutes = durationMinutes
    }

    var effectiveDurationMinutes: Int { durationMinutes ?? ToDoScoring.minutes(forPerspiration: perspirationLevel) }
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && effectiveDurationMinutes > 0 && effectiveDurationMinutes <= Int.max / 60
    }
}

/// The backend merges omitted fields on an existing row. Send mandatory identity fields and only
/// changes made in this editor; tags, subtasks, assignments and unsupported metadata remain untouched.
enum FocusSessionTaskUpsert {
    /// Keys the client must not echo back: server-owned bookkeeping that `CreateToDoDto` rejects or
    /// recomputes.
    static let serverOwnedKeys: Set<String> = [
        "created_at", "updated_at", "deleted_at", "user_id", "top_score", "assignee", "project",
        "comments", "reactions", "custom_status", "external_task_status",
    ]

    static func body(updating original: [String: Any]?, with edits: FocusSessionTaskEdits) -> [String: Any] {
        var body: [String: Any] = [:]
        if let id = original?[FocusSessionToDoKey.id] { body[FocusSessionToDoKey.id] = id }
        body[FocusSessionToDoKey.title] = edits.title.trimmingCharacters(in: .whitespacesAndNewlines)
        body["eisenhower_quadrant"] = original?["eisenhower_quadrant"] ?? EisenhowerQuadrant.doIt.rawValue
        let old = original.flatMap(FocusSessionTaskSnapshot.edits)
        if old?.details != edits.details { body[FocusSessionToDoKey.details] = edits.details }
        if old?.status != edits.status { body[FocusSessionToDoKey.status] = edits.status.rawValue }
        if old == nil || old?.outcome != edits.outcome {
            body[FocusSessionToDoKey.outcome] = edits.outcome.map { FocusSessionScoring.clamp($0) as Any } ?? NSNull()
        }
        if old == nil || old?.perspirationLevel != edits.perspirationLevel {
            body[FocusSessionToDoKey.perspirationLevel] = FocusSessionScoring.clamp(edits.perspirationLevel)
        }
        if old == nil || (edits.durationMinutes != nil && old?.durationMinutes != edits.durationMinutes) {
            body["duration"] = edits.effectiveDurationMinutes * 60
        }
        if old == nil || old?.dueDate != edits.dueDate {
            body[FocusSessionToDoKey.dueDate] = edits.dueDate.map(FocusSessionDates.apiString) ?? NSNull()
        }
        if old == nil || old?.projectId != edits.projectId { body[FocusSessionToDoKey.projectId] = edits.projectId ?? NSNull() }
        return body
    }

    /// A create: the same body without an id, so the upsert inserts.
    static func creationBody(with edits: FocusSessionTaskEdits) -> [String: Any] {
        var body = body(updating: nil, with: edits)
        body.removeValue(forKey: FocusSessionToDoKey.id)
        return body
    }
}

/// `/to-do/by-ids` must include the complete editable subset. A missing field is not the same as an
/// explicitly unrated/null value; do not fabricate editable defaults from a partial search result.
enum FocusSessionTaskSnapshot {
    static let requiredKeys: Set<String> = ["id", "title", "status", "details", "due_date", "outcome",
        "perspiration_level", "project_id", "synced_project_id", "eisenhower_quadrant", "updated_at"]

    static func isEditable(_ raw: [String: Any], id: String) -> Bool {
        requiredKeys.isSubset(of: Set(raw.keys)) && raw["id"] as? String == id
            && raw["title"] is String && raw["eisenhower_quadrant"] is Int
            && raw["updated_at"] is String && edits(raw) != nil
    }

    static func edits(_ raw: [String: Any]) -> FocusSessionTaskEdits? {
        guard let title = raw["title"] as? String,
              let statusValue = raw["status"] as? String,
              let status = FocusSessionTaskStatus(rawValue: statusValue) else { return nil }
        return .init(title: title, details: raw["details"] as? String ?? "", status: status,
                     dueDate: FocusSessionDates.parse(raw["due_date"] as? String),
                     outcome: raw["outcome"] as? Int,
                     perspirationLevel: raw["perspiration_level"] as? Int ?? FocusSessionScoring.minimum,
                     projectId: raw["project_id"] as? String,
                     durationMinutes: (raw["duration"] as? NSNumber).flatMap {
                         $0.intValue > 0 ? max(1, Int(($0.doubleValue / 60).rounded())) : nil
                     })
    }

    static func unchanged(_ current: [String: Any], since previous: [String: Any]) -> Bool {
        guard let id = previous["id"] as? String, isEditable(current, id: id), isEditable(previous, id: id) else { return false }
        return requiredKeys.union(["duration"]).allSatisfy { key in
            let lhs = current[key] as? NSObject, rhs = previous[key] as? NSObject
            return lhs?.isEqual(rhs) == true
        }
    }
}

enum FocusSessionOutcome {
    static func wireValue(forDisplay value: Int) -> Int { min(5, max(1, value)) * 2 }
    static func displayValue(forWire value: Int) -> Double { min(5, max(1, Double(value) / 2)) }
}

enum FocusSessionSubtasks {
    static func decode(_ raw: [String: Any]) -> [ToDoSubtask]? {
        guard let value = raw["subtasks"] else { return nil }
        if value is NSNull { return [] }
        guard let data = try? JSONSerialization.data(withJSONObject: value) else { return nil }
        return try? JSONDecoder().decode([ToDoSubtask].self, from: data)
    }

    static func body(updating raw: [String: Any], subtasks: [ToDoSubtask]) -> [String: Any]? {
        guard let id = raw["id"] as? String, FocusSessionTaskSnapshot.isEditable(raw, id: id),
              decode(raw) != nil else { return nil }
        return ["id": id, "title": raw["title"]!, "eisenhower_quadrant": raw["eisenhower_quadrant"]!,
                "subtasks": subtasks.map { ["name": $0.name, "is_completed": $0.is_completed] as [String: Any] }]
    }

    static func sameValues(_ lhs: [ToDoSubtask], _ rhs: [ToDoSubtask]) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { pair in
            pair.0.name == pair.1.name && pair.0.is_completed == pair.1.is_completed
        }
    }
}

// MARK: - Picker filters

/// The design's "Perspiration" filter — how much effort the task is expected to cost.
enum FocusSessionSpoonsBand: String, CaseIterable, Identifiable {
    // Declaration order is the order the filter sheet shows the chips in.
    case fullSpoons
    case lowSpoons

    var id: String { rawValue }

    func contains(_ level: Int) -> Bool {
        switch self {
        case .lowSpoons: return level <= FocusSessionScoring.lowSpoonsUpperBound
        case .fullSpoons: return level > FocusSessionScoring.lowSpoonsUpperBound
        }
    }
}

/// The design's due-date axis: five labelled stops at fixed positions along the track, with days
/// interpolated between them. The positions come from the label centres in the Figma frame, so the
/// slider handles line up with the captions.
enum FocusSessionDueDateScale {
    /// `days` is days from today; the "overdue" stop matches anything already past due.
    static let stops: [(days: Int, position: Double)] = [
        (-1, 0.042), (0, 0.184), (7, 0.383), (14, 0.597), (30, 0.820),
    ]
    /// Anything at or below this stop includes tasks whose due date has passed.
    static let overdueDays = -1
    static var lowestDays: Int { stops.first?.days ?? overdueDays }
    static var highestDays: Int { stops.last?.days ?? 30 }

    /// Days at a fraction along the track, interpolating between the labelled stops.
    static func days(atPosition position: Double) -> Int {
        let clamped = min(1, max(0, position))
        if clamped <= stops[0].position { return stops[0].days }
        for index in 1..<stops.count where clamped <= stops[index].position {
            let previous = stops[index - 1]
            let current = stops[index]
            let span = current.position - previous.position
            guard span > 0 else { return current.days }
            let ratio = (clamped - previous.position) / span
            return previous.days + Int((Double(current.days - previous.days) * ratio).rounded())
        }
        return stops[stops.count - 1].days
    }

    /// Where a day count sits along the track — the inverse of `days(atPosition:)`.
    static func position(forDays days: Int) -> Double {
        if days <= stops[0].days { return stops[0].position }
        for index in 1..<stops.count where days <= stops[index].days {
            let previous = stops[index - 1]
            let current = stops[index]
            let span = Double(current.days - previous.days)
            guard span > 0 else { return current.position }
            let ratio = Double(days - previous.days) / span
            return previous.position + (current.position - previous.position) * ratio
        }
        return stops[stops.count - 1].position
    }
}

/// Everything the "Add Filters" sheet can narrow the task picker by.
struct FocusSessionTaskFilters: Equatable {
    var spoons: FocusSessionSpoonsBand?
    var projectId: String?
    /// Inclusive range in days from today; `nil` means the due date is not filtered.
    var dueInDaysLowerBound: Int?
    var dueInDaysUpperBound: Int?

    static let none = FocusSessionTaskFilters()

    var isEmpty: Bool { activeCount == 0 }

    /// How many of the three controls are actually narrowing the list — the count in "Add 3 filters".
    var activeCount: Int {
        var count = 0
        if spoons != nil { count += 1 }
        if let projectId = projectId, !projectId.isEmpty { count += 1 }
        if dueInDaysLowerBound != nil || dueInDaysUpperBound != nil { count += 1 }
        return count
    }

    func matches(_ task: FocusSessionPickerTask, now: Date = Date()) -> Bool {
        if let spoons = spoons, !spoons.contains(task.perspirationLevel) { return false }
        if let projectId = projectId, !projectId.isEmpty, task.projectId != projectId { return false }
        if dueInDaysLowerBound != nil || dueInDaysUpperBound != nil {
            guard let dueDate = task.dueDate else { return false }
            let days = FocusSessionDates.daysFromNow(to: dueDate, now: now)
            // The lowest stop is "Overdue", so a range starting there keeps everything already past due.
            if let lower = dueInDaysLowerBound, lower > FocusSessionDueDateScale.overdueDays, days < lower { return false }
            if let upper = dueInDaysUpperBound, days > upper { return false }
        }
        return true
    }
}
