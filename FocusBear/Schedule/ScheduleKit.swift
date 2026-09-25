//
//  ScheduleKit.swift
//  Focus Bear
//
//  Pure-logic engine for the "Schedule" view: turns the remaining habits of the
//  current routine — plus today's calendar meetings — into a timetable of blocks
//  (habits, meetings, deep-work gaps) with projected start/finish times.
//
//  Kept free of AppKit so the timing logic can be reasoned about and unit-tested
//  in isolation. Rendering lives in ScheduleViewController.swift.
//

import Foundation

/// Compact habit-duration labels for the Day Plan rows and the habit editor: "45s", "1m 30s", "5m",
/// "1h 5m". Seconds matter — a 1-second "log it" habit used to read as "0m".
enum HabitDurationText {
    static let secondsPerMinute = 60
    static let secondsPerHour = 3600
    private static let hourUnit = "h"
    private static let minuteUnit = "m"
    private static let secondUnit = "s"

    static func short(seconds: Int) -> String {
        let hours = seconds / secondsPerHour
        let minutes = (seconds % secondsPerHour) / secondsPerMinute
        let remainder = seconds % secondsPerMinute
        if hours > 0 { return "\(hours)\(hourUnit) \(minutes)\(minuteUnit)" }
        if minutes > 0 && remainder > 0 { return "\(minutes)\(minuteUnit) \(remainder)\(secondUnit)" }
        if minutes > 0 { return "\(minutes)\(minuteUnit)" }
        return "\(remainder)\(secondUnit)"
    }
}

enum ScheduleBlockKind {
    case habit
    case meeting
    case deepWork
    case breakSprint       // short break between deep-work sprints
    case sleep             // overnight rest, after the evening routine
    case allDone          // marker row: "Habits done"
    case routineTransition // marker row: "Evening/Morning routine starts"
}

struct ScheduleBlock {
    let kind: ScheduleBlockKind
    var title: String          // includes emoji for habits/meetings
    var start: Date
    var end: Date
    var habitIndex: Int?       // index into the current routine's remaining-habits array
    var isActionable: Bool     // show Play/Done/Skip on this card
    /// The habit's settings can be edited from this card (Edit-only bar when it isn't actionable).
    /// Separate from `isActionable`: a preview/future routine can be edited but not started.
    var isEditable: Bool = false
    var isCurrent: Bool        // the next habit up (highlighted)
    var subtitle: String?      // e.g. "meeting", or a duration label
    var didOverflow: Bool      // habit couldn't be placed before day end
    var eventID: String?       // calendar event identifier (for meetings, so they can be dismissed)
    var routineName: String?   // for habits: which routine they belong to (used to group them)
    var isDone: Bool = false   // habit completed today — rendered struck through (earlier-today sections)
    var habitId: String?       // the habit's server id — used to complete/skip a PAST habit by id
    var isEarlier: Bool = false // from an "earlier today" section (past routine); actioned by id, not index
    var isDismissed: Bool = false // a meeting the user hid with ✕, shown only when "Show dismissed events" is on
    var overflowDurationSeconds: Int? = nil // overflow habits are zero-duration at the cursor (so they group
    // and don't skew free time); this carries each habit's own length so the UI can lay the "not enough time
    // today" rows out back-to-back as an illustrative sequential range instead of a bogus 8:29–8:29 slot.

    init(kind: ScheduleBlockKind, title: String, start: Date, end: Date,
         habitIndex: Int? = nil, isActionable: Bool = false, isCurrent: Bool = false,
         subtitle: String? = nil, didOverflow: Bool = false, eventID: String? = nil,
         routineName: String? = nil) {
        self.kind = kind
        self.title = title
        self.start = start
        self.end = end
        self.habitIndex = habitIndex
        self.isActionable = isActionable
        self.isCurrent = isCurrent
        self.subtitle = subtitle
        self.didOverflow = didOverflow
        self.eventID = eventID
        self.routineName = routineName
    }

    var durationSeconds: Int { Int(end.timeIntervalSince(start)) }
}

struct ScheduleHabitInput {
    let index: Int             // position in the routine's remaining-habits array
    let title: String          // emoji + name
    let durationSeconds: Int
    let isPlaying: Bool         // currently running
    let elapsedSeconds: Int     // already elapsed (for the playing habit)
    let cutoff: Date?           // latest time it must be finished by; dropped if it can't be
    var isDone: Bool = false    // completed today — rendered struck through (earlier-today sections)
    var id: String?             // the habit's server id — needed to complete/skip a PAST habit by id
}

struct ScheduleMeetingInput: Equatable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    var isDismissed: Bool = false   // hidden by the user; surfaced (struck through) when "Show dismissed events" is on
    /// Who organises it, as far as EventKit can prove. Read on the same background fetch as the rest
    /// of this struct: the Fix modal decides each meeting's action from these, and doing that from the
    /// modal would put one `EKEventStore` lookup per meeting on the main thread.
    var ownership: EventOwnership = .unknown
    /// Whether anyone besides the signed-in user is on it — the difference between "skip it quietly"
    /// and "someone has to be told".
    var hasOtherAttendees: Bool = false
    /// Whether it repeats, so a removal can ask which occurrences it means.
    var isRecurring: Bool = false
}

/// A routine (morning / evening / a custom routine) and the time window its habits may run in.
/// Habits are packed inside [windowStart, windowEnd] and never spill past it, so one routine
/// doesn't bleed into the next. Only the active routine's habits are `actionable`.
struct ScheduleRoutineSegment {
    let name: String
    let habits: [ScheduleHabitInput]
    let windowStart: Date
    let windowEnd: Date
    let actionable: Bool
    /// #2010: an "earlier today" section (the past morning routine, shown under the "Show events from
    /// earlier today" toggle once we're past it). The builder lays these out at their historical window
    /// [windowStart, windowEnd] instead of clamping the start up to `now` (which would drop a wholly-past
    /// window), and it doesn't apply the per-habit cutoff drop — they're read-only history.
    var isEarlier: Bool = false
}

enum ScheduleBuilder {

    /// Minimum free span that becomes its own "deep work" block.
    static let minDeepWorkSeconds = 10 * 60

    /// Build the day's timetable.
    ///
    /// - Parameters:
    ///   - habits: remaining habits, in routine order. `index` is their position in the
    ///     live routine array so the UI can drive Play/Done/Skip against the real data.
    ///   - meetings: today's timed calendar events (any order).
    ///   - now: current time — habits are packed from here.
    ///   - dayEnd: end of the scheduling window (typically the user's shutdown time).
    ///   - leaveBufferSeconds: time reserved before each meeting so a habit doesn't run
    ///     right up to the meeting start.
    ///   - outOfOrderAllowed: when true, every remaining habit is actionable; otherwise
    ///     only the next habit up is.
    /// Display strings for the engine-generated blocks, passed in (localized) by the view so the
    /// engine stays free of any config/localization dependency.
    struct Labels {
        var deepWork = "🧠 Deep work"
        var breakSprint = "☕️ Break"
        var sleep = "😴 Sleep"
        var eveningRoutine = "🌙 Evening routine"
        var morningRoutine = "🌅 Morning routine"
        var meeting = "meeting"
    }

    static func build(segments: [ScheduleRoutineSegment],
                      meetings: [ScheduleMeetingInput],
                      now: Date,
                      dayEnd: Date,
                      leaveBufferSeconds: Int,
                      outOfOrderAllowed: Bool,
                      eveningRoutineStart: Date? = nil,
                      morningRoutineStart: Date? = nil,
                      meetingsFrom: Date? = nil,
                      deepWorkCutoff: Date? = nil,
                      sprintWorkSeconds: Int = 0,
                      sprintBreakSeconds: Int = 0,
                      labels: Labels = Labels()) -> [ScheduleBlock] {

        var blocks = [ScheduleBlock]()

        // Meetings are shown from `now` by default; pass an earlier `meetingsFrom` (e.g. the start
        // of the day) to also surface meetings that already finished — habits still pack from `now`.
        let meetingFloor = meetingsFrom ?? now
        let upcomingMeetings = meetings
            .filter { $0.end > meetingFloor }
            .sorted { $0.start < $1.start }

        // Habits may not run inside [meetingStart - buffer, meetingEnd].
        let habitBusy = upcomingMeetings.map { m -> (Date, Date) in
            (min(m.start.addingTimeInterval(-Double(leaveBufferSeconds)), m.start), m.end)
        }

        // Schedule each routine's habits within its own window, capped at the window end, so the
        // morning routine never bleeds past the evening start and each routine shows in its block.
        var occupied = habitBusy   // grows as we place habits, so deep-work avoids them
        for seg in segments.sorted(by: { $0.windowStart < $1.windowStart }) {
            // Active/preview routines pack from `now` (their remaining habits start here); an "earlier
            // today" section is history, so lay it out at its real window start instead of clamping up
            // to now (which would drop a window that already ended).
            let segStart = seg.isEarlier ? seg.windowStart : max(seg.windowStart, now)
            guard seg.windowEnd > segStart, !seg.habits.isEmpty else { continue }
            // An "earlier today"/past routine is read-only history: render EVERY habit (struck if done,
            // tap-to-complete if not), never truncated to what fit in its window. That window (e.g. a ~3h
            // morning block) is far shorter than the routine's full duration, so the normal overflow path
            // would DROP the later habits — which are typically the still-undone ones — leaving only the
            // early, already-completed habits visible. The card then looks (and, via routineComplete,
            // reports itself) "Completed" when the routine is only partly done. For a non-actionable
            // struck-through list the placement times past the window are cosmetic, so lift the fit
            // constraint for earlier sections and place them all.
            let placementWindowEnd = seg.isEarlier ? Date.distantFuture : seg.windowEnd

            // Habits that still count today: a habit with a cutoff stays visible until that cutoff has
            // actually passed — not merely because its *projected* slot would land after it. The user
            // can still do it (possibly out of order) right up to the cutoff, so don't hide it early.
            // (An "earlier today" section is past history: show every habit regardless of cutoff.)
            let dueHabits = seg.habits.filter { h in
                seg.isEarlier || h.cutoff.map { now <= $0 } ?? true
            }
            let placement = placeHabitsInGaps(dueHabits, from: segStart, to: placementWindowEnd, busy: habitBusy)
            var placed = [Int]()
            for p in placement.placed {
                var b = ScheduleBlock(kind: .habit, title: p.habit.title, start: p.start, end: p.end,
                                      habitIndex: p.habit.index, routineName: seg.name)
                b.isActionable = seg.actionable
                // Every habit row is editable, "earlier today" history and completed habits included: the
                // editor changes the habit's SETTINGS, not the day's record, so a routine that has already
                // run is as editable as one that hasn't. Only what you can *do* to today's row
                // (Play/Done/Skip) is gated on `actionable`.
                b.isEditable = true
                b.isDone = p.habit.isDone
                b.habitId = p.habit.id
                b.isEarlier = seg.isEarlier
                blocks.append(b)
                placed.append(blocks.count - 1)
                occupied.append((p.start, p.end))
            }
            // Where the overflow group is anchored: the end of the last habit that fit (segStart when
            // nothing fit), so it sorts below every placed habit of this routine.
            let overflowAnchor = placement.placed.map { $0.end }.max() ?? segStart

            // Overflow: for the ACTIVE routine (e.g. a packed morning where the habits don't fit before
            // the first meeting), surface the habits that couldn't be placed as a SEPARATE collapsed
            // "not enough time today" group instead of dropping them — the user can still see and do their
            // routine. Anchor them ALL at `overflowAnchor` (the end of the last habit that fit) so the sort
            // keeps them below the placed habits — NOT at the top of a group that did have time (reported:
            // "habits I don't have time for appear at the top of an accordion where I do"). They share the
            // same start deliberately: a deep-work filler occupying the freed time ALSO starts there, and the
            // final sort's kind tie-break (habit before deepWork) plus the habitIndex tie-break keep the whole
            // overflow group CONTIGUOUS and in routine order. (A previous per-item offset gave them distinct
            // starts, so a deep-work block sorted BETWEEN two overflow anchors and split them into two "not
            // enough time today" cards.) When no habit fit at all, the anchor is segStart and this whole
            // segment is one overflow group.
            //
            // This runs for EVERY segment, not just the actionable one. A preview segment (the evening
            // routine, a custom routine, or any routine on a past/future day — `segmentsForDate` builds
            // them all with `actionable: false`) used to drop its unplaced habits silently, so a packed
            // future day rendered "🧩 Morning routine habits · 6:30–6:57am" as if the whole routine fitted
            // in a 27-minute gap between the end of sleep and the first meeting. The plan must say the
            // rest of the routine has nowhere to go on any day the user can look at, not only today.
            // (An "earlier today" section places every habit with no window cap, so it has no unplaced
            // habits to surface.)
            for h in placement.unplaced {
                var b = ScheduleBlock(kind: .habit, title: h.title, start: overflowAnchor, end: overflowAnchor,
                                      habitIndex: h.index, routineName: seg.name)
                b.isActionable = seg.actionable
                b.isEditable = true
                b.isDone = h.isDone
                b.habitId = h.id
                b.didOverflow = true
                // Keep the block zero-duration (start == end) so it groups and doesn't count as busy
                // time, but remember the habit's own length so the UI can show its real length.
                b.overflowDurationSeconds = remainingSeconds(of: h)
                blocks.append(b)
                placed.append(blocks.count - 1)
            }

            // The whole active routine is tappable (tap a habit to move the action bar to it); its
            // next-up habit is the default selection — the earliest TIMED habit, or (if the whole
            // routine overflowed) the first overflow habit. Preview routines aren't actionable.
            if seg.actionable {
                for i in placed { blocks[i].isActionable = true }
                let nextIdx = placed.filter { !blocks[$0].didOverflow }.min(by: { blocks[$0].start < blocks[$1].start })
                    ?? placed.min(by: { blocks[$0].start < blocks[$1].start })
                if let nextIdx = nextIdx { blocks[nextIdx].isCurrent = true }
            } else {
                for i in placed { blocks[i].isActionable = false }
            }
        }

        for m in upcomingMeetings {
            var meetingBlock = ScheduleBlock(kind: .meeting, title: m.title, start: m.start, end: m.end,
                                             subtitle: nil, eventID: m.id)
            meetingBlock.isDismissed = m.isDismissed
            blocks.append(meetingBlock)
        }

        // Marker for the transition into the evening routine (the user's shutdown time).
        if let evening = eveningRoutineStart, evening > now {
            blocks.append(ScheduleBlock(kind: .routineTransition, title: labels.eveningRoutine,
                                        start: evening, end: evening))
        }

        // Deep-work / free time fills gaps up to the day's end (23:59) — but never past the user's
        // cutoff time: we don't suggest deep work once they've called it a day. The timetable still
        // runs to 23:59 (meetings, etc. can sit later); there's just no deep-work filler after cutoff.
        let deepWorkEnd = [deepWorkCutoff, dayEnd].compactMap { $0 }.min() ?? dayEnd
        for iv in freeIntervals(from: now, to: deepWorkEnd, busy: occupied) {
            if iv.1.timeIntervalSince(iv.0) >= Double(minDeepWorkSeconds) {
                blocks.append(contentsOf: deepWorkSprints(from: iv.0, to: iv.1, workTitle: labels.deepWork,
                                                          workSeconds: sprintWorkSeconds,
                                                          breakSeconds: sprintBreakSeconds, labels: labels))
            }
        }

        // The day ends at `dayEnd` (23:59). We no longer trail off into an overnight "Sleep" block
        // or a next-day "Morning routine" marker — the "View tomorrow's schedule" button in the UI
        // takes the user to the next day instead.

        return blocks.sorted { a, b in
            if a.start != b.start { return a.start < b.start }
            if kindOrder(a.kind) != kindOrder(b.kind) { return kindOrder(a.kind) < kindOrder(b.kind) }
            // Same start & kind: order habits by their routine index so the overflow "not enough time
            // today" habits (all anchored at the same cursor) stay contiguous and in routine order — a
            // deep-work block at the same start still sorts after them (habit kindOrder < deepWork).
            return (a.habitIndex ?? Int.max) < (b.habitIndex ?? Int.max)
        }
    }

    // MARK: - Helpers

    /// A habit the gap filler found a concrete slot for.
    struct PlacedHabit {
        let habit: ScheduleHabitInput
        let start: Date
        let end: Date
    }

    /// Slack allowed past a gap's end so a habit that ends a fraction of a second late (because `now`
    /// carries sub-second time while window/meeting bounds are whole minutes) still counts as fitting.
    private static let fitToleranceSeconds: TimeInterval = 0.5

    /// Packs `habits` into the free gaps of [from, to] (everything not covered by `busy`, i.e. meetings
    /// plus their leave buffer), gap by gap in time order. Within a gap, the earliest habit in routine
    /// order that still fits is placed next — so when the next habit in order can't finish before a
    /// meeting, a shorter later habit is pulled forward into that gap instead of leaving it to deep
    /// work, and the long habit takes the first later gap that fits it. Only what's needed to fill a
    /// gap is pulled forward, so the list order stays as stable as possible.
    ///
    /// "Fits nowhere" is judged against the routine's whole window: a habit is `unplaced` only when no
    /// gap between `from` and `to` is long enough for it. The active morning routine's window runs to
    /// the user's shutdown time, so a habit that can't fit before the morning's meetings but does fit
    /// after them is placed there (later today), not reported as "not enough time today"; the overflow
    /// group appears only when the window is genuinely full.
    static func placeHabitsInGaps(_ habits: [ScheduleHabitInput], from: Date, to: Date,
                                  busy: [(Date, Date)]) -> (placed: [PlacedHabit], unplaced: [ScheduleHabitInput]) {
        var remaining = habits
        var placed = [PlacedHabit]()
        for gap in freeIntervals(from: from, to: to, busy: busy) {
            var cursor = gap.0
            let gapEnd = gap.1.addingTimeInterval(fitToleranceSeconds)
            while let i = remaining.firstIndex(where: { cursor.addingTimeInterval(Double(remainingSeconds(of: $0))) <= gapEnd }) {
                let habit = remaining.remove(at: i)
                let end = cursor.addingTimeInterval(Double(remainingSeconds(of: habit)))
                placed.append(PlacedHabit(habit: habit, start: cursor, end: end))
                cursor = end
            }
            if remaining.isEmpty { break }
        }
        return (placed, remaining)
    }

    /// Seconds a habit still needs: its full duration, less what has already elapsed if it's playing.
    static func remainingSeconds(of h: ScheduleHabitInput) -> Int {
        max(0, h.durationSeconds - (h.isPlaying ? h.elapsedSeconds : 0))
    }

    /// Splits a deep-work interval into work/break sprints based on the user's break cadence.
    /// `workSeconds` is the break frequency (how long you work before a break). With no cadence
    /// set (workSeconds <= 0) the interval stays one big deep-work block. A trailing remainder too
    /// small for a break is absorbed into the final work sprint, so we never end on a stray break.
    private static func deepWorkSprints(from start: Date, to end: Date, workTitle: String,
                                        workSeconds: Int, breakSeconds: Int,
                                        labels: Labels) -> [ScheduleBlock] {
        guard workSeconds > 0, breakSeconds > 0 else {
            return [ScheduleBlock(kind: .deepWork, title: workTitle, start: start, end: end)]
        }
        var out = [ScheduleBlock]()
        var t = start
        while t < end {
            var workEnd = min(t.addingTimeInterval(Double(workSeconds)), end)
            // If what's left after a full work sprint is too small for a break, fold it in.
            if end.timeIntervalSince(workEnd) <= Double(breakSeconds) { workEnd = end }
            out.append(ScheduleBlock(kind: .deepWork, title: workTitle, start: t, end: workEnd))
            t = workEnd
            if t >= end { break }
            let breakEnd = min(t.addingTimeInterval(Double(breakSeconds)), end)
            out.append(ScheduleBlock(kind: .breakSprint, title: labels.breakSprint, start: t, end: breakEnd))
            t = breakEnd
        }
        return out
    }

    /// Tie-break ordering when two blocks share a start time.
    private static func kindOrder(_ k: ScheduleBlockKind) -> Int {
        switch k {
        case .routineTransition: return 0  // a transition marker precedes that routine's habits
        case .habit: return 1
        case .allDone: return 2
        case .meeting: return 3
        case .deepWork: return 4
        case .breakSprint: return 4
        case .sleep: return 5
        }
    }

    /// Free intervals within [from, to] after removing the (possibly overlapping) busy intervals.
    static func freeIntervals(from: Date, to: Date, busy: [(Date, Date)]) -> [(Date, Date)] {
        guard to > from else { return [] }
        let merged = mergeIntervals(busy.map { (max($0.0, from), min($0.1, to)) }.filter { $0.1 > $0.0 })
        var result = [(Date, Date)]()
        var cursor = from
        for b in merged {
            if b.0 > cursor { result.append((cursor, b.0)) }
            cursor = max(cursor, b.1)
        }
        if cursor < to { result.append((cursor, to)) }
        return result
    }

    private static func mergeIntervals(_ intervals: [(Date, Date)]) -> [(Date, Date)] {
        let sorted = intervals.sorted { $0.0 < $1.0 }
        var merged = [(Date, Date)]()
        for iv in sorted {
            if var last = merged.last, iv.0 <= last.1 {
                last.1 = max(last.1, iv.1)
                merged[merged.count - 1] = last
            } else {
                merged.append(iv)
            }
        }
        return merged
    }
}

/// Pure ordering rule for switching the live routine to another habit mid-flight.
///
/// The Habit Player's "Select another habit" sheet (startAnotherHabitVc) moves the chosen habit to
/// the position of the habit that's currently playing, which leaves that habit directly behind it —
/// so it isn't skipped or completed, it just comes up next. The Day Plan's Play button does the same
/// thing, but it can offer any habit in the routine, including one *before* the current position.
enum RoutineReorder {

    /// `habits` with the item at `from` moved to `anchor` (the currently-playing position).
    /// Returns nil when there's nothing to do — the index is out of range, or the item already sits
    /// where it would land.
    static func moving<T>(_ habits: [T], at from: Int, toAnchor anchor: Int) -> [T]? {
        guard habits.indices.contains(from) else { return nil }
        let target = min(max(anchor, 0), habits.count - 1)
        guard from != target else { return nil }
        var out = habits
        let moved = out.remove(at: from)
        // Removing an item that sat *before* the anchor shifts the anchor down one place.
        out.insert(moved, at: min(from < target ? target - 1 : target, out.count))
        return out
    }
}

// MARK: - Day Plan: due-date projection

/// Synced unfinished work has one canonical home: its due date, or today if overdue.
/// Future days contain only work due on that day; viewing a future date does not age today's work.
enum DayPlanDueProjection {
    static func canonicalDay(dueDate: String?, today: String) -> String? {
        guard let date = ToDoDates.parse(dueDate) else { return nil }
        return max(today, ToDoDates.ymd(date))
    }

    static func reconcile(_ stored: [String: [DayPlanTask]],
                          rows: [(due: String, task: DayPlanTask)], today: String) -> [String: [DayPlanTask]] {
        var result = stored.mapValues { $0.filter { $0.sourceTaskId == nil || $0.done } }
        let completedToday = Set((stored[today] ?? []).filter(\.done).compactMap(\.sourceTaskId))
        var seen = Set<String>()
        for row in rows {
            guard let id = row.task.sourceTaskId, seen.insert(id).inserted,
                  !completedToday.contains(id) else { continue }
            result[row.due, default: []].append(row.task)
        }
        // Preserve the user's row order when a refresh leaves tasks on the same due day.
        for day in result.keys {
            let order = Dictionary((stored[day] ?? []).enumerated().map { ($0.element.id, $0.offset) },
                                   uniquingKeysWith: { first, _ in first })
            result[day] = result[day]?.enumerated().sorted {
                let left = order[$0.element.id] ?? Int.max, right = order[$1.element.id] ?? Int.max
                return left == right ? $0.offset < $1.offset : left < right
            }.map(\.element)
        }
        return result.filter { !$0.value.isEmpty }
    }


}

// MARK: - Day Plan: free time vs. time-boxed task load

/// How the tasks nested under a time-boxed block (a meeting or a deep-work sprint) affect the
/// "🕒 Nh free" figure in the Day Plan's tasks panel.
enum DayPlanFreeTime {

    /// Minutes a block's nested tasks add to the day *beyond* the block's own duration.
    ///
    /// Tasks dropped onto a block are meant to be worked inside it, so that time is already carved
    /// out of the day — counting them again on top makes the day look fuller than it is. Only the
    /// overflow costs anything: a 10-minute block carrying 20 minutes of tasks costs 10 extra
    /// minutes, not 30. Tasks that fit inside the block cost nothing, and an under-filled block
    /// never hands time back (the result is never negative).
    static func excessMinutes(taskMinutes: Int, blockMinutes: Int) -> Int {
        max(0, taskMinutes - max(0, blockMinutes))
    }

    /// One time-boxed block's own length and the total length of the tasks nested under it.
    struct BlockLoad: Equatable {
        let blockMinutes: Int
        let taskMinutes: Int
        init(blockMinutes: Int, taskMinutes: Int) {
            self.blockMinutes = blockMinutes
            self.taskMinutes = taskMinutes
        }
    }

    /// Free minutes left once every time-boxed block's overflow is deducted. Clamped at zero — an
    /// over-committed day reports no free time rather than a negative one.
    static func adjustedFreeMinutes(rawFreeMinutes: Int, blocks: [BlockLoad]) -> Int {
        let overflow = blocks.reduce(0) { $0 + excessMinutes(taskMinutes: $1.taskMinutes, blockMinutes: $1.blockMinutes) }
        return max(0, rawFreeMinutes - overflow)
    }
}

// MARK: - Day Plan: block keys

/// The `DayPlanTask.blockKey` vocabulary — which block of the day a time-boxed task is pinned to.
///
/// The prefixes were written out as literals in `scheduleViewController.blockKey(for:)`, again in
/// `HabitTaskChecklist`, and again in every capacity path that asked "is this a habit key?". That
/// last repetition is how the capacity model came to absorb task work into habits but not into
/// calendar events: two of the three places tested for `"habit:"` and nobody noticed the third kind
/// of key existed (report 2026-09-17_09-08-25). One vocabulary, one place.
enum DayPlanBlockKey {
    static let habitPrefix = "habit:"
    static let eventPrefix = "event:"
    static let deepWorkPrefix = "deepwork:"

    /// Habits are keyed by NAME, not by server id — the Day Plan builds its rows from the routine's
    /// habit titles, so renaming a habit detaches its tasks.
    static func habit(named name: String) -> String { habitPrefix + name }
    static func event(id: String) -> String { eventPrefix + id }
    /// Deep-work sprints drift as the day repacks, so their key is the start time they were pinned
    /// at and the timeline re-matches it to the nearest current sprint.
    static func deepWork(startingAt start: Date) -> String {
        deepWorkPrefix + String(Int(start.timeIntervalSince1970))
    }

    /// Whether a task pinned to this block is worked inside time the day has ALREADY committed, so
    /// its minutes must not be charged against the day's free time a second time.
    ///
    /// Habits and calendar events qualify — "if I drag a task to an event, it should be the same
    /// impact on day plan free time as if I drag it to a habit" (report 2026-09-17_09-08-25).
    /// Deep work does not: a deep-work block is not committed time, it IS the day's free work time,
    /// so absorbing into it would refund the very minutes it represents.
    static func absorbs(_ key: String?) -> Bool {
        guard let key = key else { return false }
        return key.hasPrefix(habitPrefix) || key.hasPrefix(eventPrefix)
    }
}

// MARK: - Day Plan: backend to-do field parsing

/// Field readers for the raw `/to-do` JSON the Day Plan imports.
enum TodoFieldParsing {

    /// A to-do's estimated duration in seconds.
    ///
    /// The API returns `duration` as a **string** (`"300"`, `"3600"`, `"0"`) — a Postgres numeric
    /// rendered as text — so a plain `as? Int` cast always fails and every imported to-do silently
    /// fell back to the 15-minute default, inflating the Day Plan's task totals. Accept both shapes.
    static func durationSeconds(_ raw: Any?) -> Int {
        if let i = raw as? Int { return i }
        if let n = raw as? NSNumber { return n.intValue }
        if let s = raw as? String, let i = Int(s.trimmingCharacters(in: .whitespaces)) { return i }
        if let d = raw as? Double { return Int(d) }
        return 0
    }

    /// The Day Plan duration (minutes) for a to-do, defaulting to `fallbackMinutes` when unset.
    static func durationMinutes(_ raw: Any?, fallbackMinutes: Int = 15) -> Int {
        let secs = durationSeconds(raw)
        return secs > 0 ? max(1, secs / 60) : fallbackMinutes
    }
}

// MARK: - The routine's "get focused" prompt

/// Whether the motivation / visualise screen has already been shown for a routine today.
///
/// It was gated only by an in-memory flag, so restarting a routine — or the app — showed the star
/// rating and "what's motivating you today?" again, several times in one evening
/// (report 2026-09-13_20-30-50). The answer is per routine per day, so that is what gets stored.
enum RoutineVisualizePrompt {
    /// One routine's prompt. Custom routines are keyed individually so answering one doesn't
    /// silence another.
    enum Routine: Equatable {
        case morning, evening, custom(String)

        var storageKey: String {
            switch self {
            case .morning: return "routineVisualizeShownDay.morning"
            case .evening: return "routineVisualizeShownDay.evening"
            case .custom(let id): return "routineVisualizeShownDay.custom.\(id)"
            }
        }

        /// The custom routine at `index` in `arrAllCustomRoutine`, keyed by its sequence id when there
        /// is one. Shared by everything that asks about a custom routine's prompt, so they agree.
        static func custom(at index: Int) -> Routine {
            .custom(arrAllCustomRoutine.indices.contains(index) ? arrAllCustomRoutine[index].sequenceId : "\(index)")
        }

        /// The routine being played in `state`, or nil outside a routine.
        static func current(state: CURRENTSTATE, customRoutineIndex: Int) -> Routine? {
            switch state {
            case ._MORNING_HABIT_: return .morning
            case ._EVENING_HABIT_: return .evening
            case ._CUSTOM_ROUTINE_: return custom(at: customRoutineIndex)
            default: return nil
            }
        }
    }

    /// Pure rule: show it unless it has already been shown on this day.
    static func shouldShow(lastShownDay: String?, today: String) -> Bool {
        guard let lastShownDay = lastShownDay, !lastShownDay.isEmpty else { return true }
        return lastShownDay != today
    }

    static func dayKey(_ date: Date = Date()) -> String {
        getStringFromDate(date: date, dateFormat: "yyyy-MM-dd")
    }

    static func shouldShow(for routine: Routine, now: Date = Date(),
                           defaults: UserDefaults = .standard) -> Bool {
        shouldShow(lastShownDay: defaults.string(forKey: routine.storageKey), today: dayKey(now))
    }

    static func markShown(for routine: Routine, now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(dayKey(now), forKey: routine.storageKey)
    }
}

// MARK: - Habits skipped ahead of time

/// Habits the user has skipped for a specific day, before that day arrives.
///
/// "Allow me to skip certain habits in advance so if I know I don't have much time for habits for
/// tomorrow I can" (report 2026-09-13_20-13-58). Today's skips are a server concern
/// (`skipped_habit_ids` on the routine), but a skip for a future day has nowhere to live yet, so it
/// is kept on this Mac and applied when that day is built.
enum DayPlanHabitSkips {
    private static let storageKey = "dayPlanSkippedHabitIdsByDay"
    /// Days kept. Old entries are dropped so the list can't grow without bound.
    static let retainedDays = 60

    static func dayKey(_ date: Date) -> String { getStringFromDate(date: date, dateFormat: "yyyy-MM-dd") }

    static func skippedIds(on day: Date, defaults: UserDefaults = .standard) -> Set<String> {
        Set(stored(defaults)[dayKey(day)] ?? [])
    }

    static func isSkipped(_ habitId: String?, on day: Date, defaults: UserDefaults = .standard) -> Bool {
        guard let habitId = habitId, !habitId.isEmpty else { return false }
        return skippedIds(on: day, defaults: defaults).contains(habitId)
    }

    /// Returns the new state, so the caller can report what it did.
    @discardableResult
    static func toggle(_ habitId: String, on day: Date, defaults: UserDefaults = .standard) -> Bool {
        var map = stored(defaults)
        let key = dayKey(day)
        var ids = Set(map[key] ?? [])
        let nowSkipped = ids.insert(habitId).inserted
        if !nowSkipped { ids.remove(habitId) }
        if ids.isEmpty { map.removeValue(forKey: key) } else { map[key] = Array(ids).sorted() }
        defaults.set(pruned(map), forKey: storageKey)
        return nowSkipped
    }

    static func clear(on day: Date, defaults: UserDefaults = .standard) {
        var map = stored(defaults)
        map.removeValue(forKey: dayKey(day))
        defaults.set(map, forKey: storageKey)
    }

    private static func stored(_ defaults: UserDefaults) -> [String: [String]] {
        defaults.dictionary(forKey: storageKey) as? [String: [String]] ?? [:]
    }

    /// Keeps the most recent days only — `yyyy-MM-dd` sorts chronologically as a string.
    static func pruned(_ map: [String: [String]]) -> [String: [String]] {
        guard map.count > retainedDays else { return map }
        let keep = map.keys.sorted().suffix(retainedDays)
        return map.filter { keep.contains($0.key) }
    }
}

/// Whether a habit belongs in a given day's routine.
///
/// One rule, asked by both the Day Plan and the routine player. `DayPlanHabitSkips` used to be read
/// only when drawing the plan, so a habit skipped ahead for tomorrow disappeared from tomorrow's
/// plan and then played anyway when tomorrow's routine started (report 2026-09-16_15-14-58 — a
/// habit skipped the night before was offered the next morning). Anything that decides which habits
/// run must go through here, so the two answers cannot drift apart again.
enum RoutineHabitSchedule {
    static func shouldPlay(habitId: String?, daysOfWeek: [String], on day: Date,
                           defaults: UserDefaults = .standard) -> Bool {
        isScheduledForWeekday(daysOfWeek, currentWeekDay: day.dayOfWeek())
            && !DayPlanHabitSkips.isSkipped(habitId, on: day, defaults: defaults)
    }
}

// MARK: - Habits shortened for one day

/// A habit trimmed for one specific day, without changing the habit itself.
///
/// "Can we add a shorten option that makes the habit shorter just for today (only persists locally).
/// Available both for current day and future days" (report 2026-09-15_20-29-02). A habit's real
/// duration is a server setting shared with every other day and every other device, so a one-day trim
/// has nowhere to live but this Mac — it is kept here and applied when that day is built, exactly like
/// `DayPlanHabitSkips`. Nothing here is ever sent to the server, so Settings › Edit habits keeps
/// showing the true duration.
enum DayPlanHabitDurations {
    private static let storageKey = "dayPlanHabitDurationOverridesByDay"
    /// Days kept. Old entries are dropped so the map can't grow without bound.
    static let retainedDays = 60
    /// The shortest trim offered or accepted — below a minute a habit block stops being a usable slot.
    static let minimumSeconds = 60
    /// The lengths offered in the sheet, longest first once filtered against the habit's real length.
    static let presetMinutes = [30, 20, 15, 10, 5]

    static func dayKey(_ date: Date) -> String { getStringFromDate(date: date, dateFormat: "yyyy-MM-dd") }

    /// The trim recorded for this habit on this day, or nil when it runs its real length.
    static func overrideSeconds(for habitId: String?, on day: Date, defaults: UserDefaults = .standard) -> Int? {
        guard let habitId = habitId, !habitId.isEmpty else { return nil }
        guard let seconds = stored(defaults)[dayKey(day)]?[habitId], seconds > 0 else { return nil }
        return seconds
    }

    /// How long to schedule (or run) this habit on this day: the trim when there is one, never longer
    /// than the habit's real length — this only ever shortens.
    static func effectiveSeconds(for habitId: String?, on day: Date, actual: Int,
                                 defaults: UserDefaults = .standard) -> Int {
        guard let trimmed = overrideSeconds(for: habitId, on: day, defaults: defaults) else { return actual }
        return min(trimmed, actual)
    }

    /// Records a trim, clamped to at least `minimumSeconds`. Asking for the real length (or longer)
    /// clears the trim instead of storing one. Returns the trim now in force, nil when cleared.
    @discardableResult
    static func setOverride(_ seconds: Int, for habitId: String, on day: Date, actual: Int,
                            defaults: UserDefaults = .standard) -> Int? {
        guard !habitId.isEmpty else { return nil }
        let wanted = max(seconds, minimumSeconds)
        guard wanted < actual else {
            clearOverride(for: habitId, on: day, defaults: defaults)
            return nil
        }
        var map = stored(defaults)
        let key = dayKey(day)
        var dayMap = map[key] ?? [:]
        dayMap[habitId] = wanted
        map[key] = dayMap
        defaults.set(pruned(map), forKey: storageKey)
        return wanted
    }

    /// Back to the habit's real length on this day.
    static func clearOverride(for habitId: String, on day: Date, defaults: UserDefaults = .standard) {
        var map = stored(defaults)
        let key = dayKey(day)
        guard var dayMap = map[key], dayMap.removeValue(forKey: habitId) != nil else { return }
        if dayMap.isEmpty { map.removeValue(forKey: key) } else { map[key] = dayMap }
        defaults.set(map, forKey: storageKey)
    }

    static func clear(on day: Date, defaults: UserDefaults = .standard) {
        var map = stored(defaults)
        map.removeValue(forKey: dayKey(day))
        defaults.set(map, forKey: storageKey)
    }

    /// The trims worth offering for a habit of this real length: the presets that are genuinely
    /// shorter, longest first. A habit already near the floor gets the one-minute trim, and a habit at
    /// or under the floor gets nothing to choose from.
    static func options(forActualSeconds actual: Int) -> [Int] {
        let fromPresets = presetMinutes.map { $0 * 60 }.filter { $0 >= minimumSeconds && $0 < actual }
        if !fromPresets.isEmpty { return fromPresets }
        return actual > minimumSeconds ? [minimumSeconds] : []
    }

    /// What a typed length means for a habit of `actualSeconds`.
    ///
    /// Kept here, pure, so the field's grammar and the "only ever shortens" rule are unit-tested
    /// rather than living in the sheet. The grammar itself is `QuickAddTaskParser` — the same parser
    /// the Day Plan's other duration fields use, so "4h", "1h30", "90min" and a bare number all mean
    /// here exactly what they mean there.
    enum TypedTrim: Equatable {
        case apply(seconds: Int)
        /// Nothing in the text reads as a length.
        case notADuration
        /// A real length, but not shorter than the habit — refused rather than applied, because this
        /// only ever shortens. "Full length" is how you clear a trim.
        case notShorter
    }

    static func typedTrim(_ text: String, actualSeconds: Int) -> TypedTrim {
        guard let minutes = QuickAddTaskParser.durationMinutes(fromFieldText: text) else { return .notADuration }
        let seconds = max(minutes * 60, minimumSeconds)
        guard seconds < actualSeconds else { return .notShorter }
        return .apply(seconds: seconds)
    }

    /// Whole minutes to show for a length — a 90-second habit reads "2 min", never "0 min".
    static func minutesLabel(_ seconds: Int) -> Int { max(1, Int((Double(seconds) / 60.0).rounded())) }

    private static func stored(_ defaults: UserDefaults) -> [String: [String: Int]] {
        defaults.dictionary(forKey: storageKey) as? [String: [String: Int]] ?? [:]
    }

    /// Keeps the most recent days only — `yyyy-MM-dd` sorts chronologically as a string.
    static func pruned(_ map: [String: [String: Int]]) -> [String: [String: Int]] {
        guard map.count > retainedDays else { return map }
        let keep = map.keys.sorted().suffix(retainedDays)
        return map.filter { keep.contains($0.key) }
    }
}

/// A meeting trimmed for one specific day, in the Day Plan only.
///
/// The Fix modal's meetings route offers "shorten - similar to the habit shorten UI"
/// (report 2026-09-17_08-15-57), and "similar to the habit shorten UI" is the whole specification:
/// like `DayPlanHabitDurations`, this is one day, on this Mac, and reversible.
///
/// It is deliberately **not** a write to the calendar. Shortening a meeting from a "make today fit"
/// modal would push an update to every attendee, and on a repeating event EventKit would happily
/// apply it to the wrong occurrence (`store.event(withIdentifier:)` hands back the series' first
/// one). Cancelling and declining are the actions that reach other people, and they keep their
/// confirmation; trimming the slot the day plan reserves does not need to.
///
/// It is also deliberately not `CalendarManager.LocalEventOverride`, which holds the user's own
/// manual edits (title, notes, a series-wide time shift) to events they don't own. A trim written
/// there would have to overwrite that record to change one end time.
enum DayPlanMeetingDurations {
    private static let storageKey = "dayPlanMeetingDurationOverridesByDay"
    /// Days kept, so the map can't grow without bound — same horizon as the habit trims.
    static let retainedDays = 60

    static func dayKey(_ date: Date) -> String { DayPlanHabitDurations.dayKey(date) }

    /// The trim recorded for this meeting on this day, or nil when it keeps its calendar length.
    static func overrideSeconds(forEventID id: String, on day: Date,
                                defaults: UserDefaults = .standard) -> Int? {
        guard !id.isEmpty, let seconds = stored(defaults)[dayKey(day)]?[id], seconds > 0 else { return nil }
        return seconds
    }

    /// The end the Day Plan should use for this occurrence: the trim when there is one, and never
    /// later than the meeting really ends — this only ever shortens.
    static func trimmedEnd(forEventID id: String, on day: Date, start: Date, end: Date,
                           defaults: UserDefaults = .standard) -> Date {
        guard let seconds = overrideSeconds(forEventID: id, on: day, defaults: defaults) else { return end }
        let trimmed = start.addingTimeInterval(TimeInterval(seconds))
        return min(trimmed, end)
    }

    /// Records a trim, clamped to at least a minute. Asking for the meeting's real length (or longer)
    /// clears the trim instead of storing one. Returns the trim now in force, nil when cleared.
    @discardableResult
    static func setOverride(_ seconds: Int, forEventID id: String, on day: Date, actual: Int,
                            defaults: UserDefaults = .standard) -> Int? {
        guard !id.isEmpty else { return nil }
        let wanted = max(seconds, DayPlanHabitDurations.minimumSeconds)
        guard wanted < actual else {
            clearOverride(forEventID: id, on: day, defaults: defaults)
            return nil
        }
        var map = stored(defaults)
        let key = dayKey(day)
        var dayMap = map[key] ?? [:]
        dayMap[id] = wanted
        map[key] = dayMap
        defaults.set(pruned(map), forKey: storageKey)
        return wanted
    }

    /// Back to the meeting's real length on this day.
    static func clearOverride(forEventID id: String, on day: Date, defaults: UserDefaults = .standard) {
        var map = stored(defaults)
        let key = dayKey(day)
        guard var dayMap = map[key], dayMap.removeValue(forKey: id) != nil else { return }
        if dayMap.isEmpty { map.removeValue(forKey: key) } else { map[key] = dayMap }
        defaults.set(map, forKey: storageKey)
    }

    private static func stored(_ defaults: UserDefaults) -> [String: [String: Int]] {
        defaults.dictionary(forKey: storageKey) as? [String: [String: Int]] ?? [:]
    }

    /// Keeps the most recent days only — `yyyy-MM-dd` sorts chronologically as a string.
    static func pruned(_ map: [String: [String: Int]]) -> [String: [String: Int]] {
        guard map.count > retainedDays else { return map }
        let keep = map.keys.sorted().suffix(retainedDays)
        return map.filter { keep.contains($0.key) }
    }
}

// MARK: - Day Plan reload instrumentation

/// Wall-clock cost of one Day Plan reload, split into the phases that have actually been slow, so a
/// freeze shows up in the log as "which phase", not just "the app stopped responding".
///
/// Kept pure (no AppKit, no clock of its own) so the thresholding and the log wording are unit-tested;
/// `scheduleViewController.reloadLive()` fills in the measured durations.
struct DayPlanReloadTiming: Equatable {
    /// Gathering the routine's habit segments (in-memory arrays).
    var segments: TimeInterval = 0
    /// Reading the day's calendar meetings — the phase that used to block on EventKit for 7-24s.
    var meetings: TimeInterval = 0
    /// ScheduleBuilder laying habits/meetings/deep-work out across the day.
    var build: TimeInterval = 0
    /// Building and installing the AppKit rows for the resulting blocks.
    var render: TimeInterval = 0
    /// The date bar, insets, routine toggle and panels that follow the render.
    var finish: TimeInterval = 0

    private var phases: [(name: String, seconds: TimeInterval)] {
        [("segments", segments), ("meetings", meetings), ("build", build),
         ("render", render), ("finish", finish)]
    }

    var total: TimeInterval { phases.reduce(0) { $0 + $1.seconds } }

    /// Whether this reload was slow enough to be worth a log line.
    func isSlow(threshold: TimeInterval) -> Bool { total >= threshold }

    /// The phase that dominated, so the log line names a suspect. "none" for a reload that did no
    /// measurable work (every phase zero), which would otherwise always report the first phase.
    var slowestPhase: String {
        guard let worst = phases.max(by: { $0.seconds < $1.seconds }), worst.seconds > 0 else { return "none" }
        return worst.name
    }

    /// e.g. "total=17204ms slowest=meetings segments=2ms meetings=17180ms build=9ms render=11ms finish=2ms"
    var summary: String {
        let breakdown = phases.map { "\($0.name)=\(Self.milliseconds($0.seconds))ms" }.joined(separator: " ")
        return "total=\(Self.milliseconds(total))ms slowest=\(slowestPhase) \(breakdown)"
    }

    private static func milliseconds(_ seconds: TimeInterval) -> Int { Int((seconds * 1000).rounded()) }
}

/// The Day Plan's meetings cache. Free of EventKit so its staleness policy is unit-testable without a
/// live event store — `CalendarManager` owns the actual query and calls into this.
///
/// The policy exists because reading EventKit blocks for seconds (see CalendarManager's "Meetings
/// cache" note): an entry that has gone out of date is still served while a background refresh
/// replaces it, so a caller on the main thread is never made to wait.
final class MeetingsCache {

    /// One cached day. `dayStart` is midnight, so two Dates on the same day share an entry.
    struct Key: Hashable {
        let dayStart: Date
        let includeDismissed: Bool
    }

    /// What a caller should do: use `meetings` now, and start a background refresh if `needsRefresh`.
    struct Lookup: Equatable {
        let meetings: [ScheduleMeetingInput]
        let needsRefresh: Bool
    }

    private let lock = NSLock()
    private var values: [Key: [ScheduleMeetingInput]] = [:]
    private var staleKeys: Set<Key> = []
    private var refreshingKeys: Set<Key> = []

    /// The value to serve for `key`. A key that has never been fetched serves [] — the same thing an
    /// unauthorized store returns — and asks for a refresh.
    func lookup(_ key: Key) -> Lookup {
        lock.lock(); defer { lock.unlock() }
        guard let cached = values[key] else { return Lookup(meetings: [], needsRefresh: true) }
        return Lookup(meetings: cached, needsRefresh: staleKeys.contains(key))
    }

    /// Whether `key` has ever been fetched — i.e. whether the [] a cold `lookup` serves means "no
    /// meetings" or merely "not read yet". `lookup` deliberately conflates the two so the main thread
    /// always has something to render; a caller that must not *decide* on an unread day (the date
    /// picker's capacity badge) asks this first. A stale-but-present entry counts as known: it holds a
    /// real answer, just one refresh old.
    func hasValue(_ key: Key) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return values[key] != nil
    }

    /// Records a fetched value and clears its stale mark. Returns true when the value differs from what
    /// lookups were already being served, i.e. when the UI must be told to re-render.
    @discardableResult
    func store(_ meetings: [ScheduleMeetingInput], for key: Key) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let changed = values[key] != meetings
        values[key] = meetings
        staleKeys.remove(key)
        return changed
    }

    /// Claims the refresh for `key`. False when one is already in flight, so repeated ticks (and the
    /// three Day Plan hosts that each reload) collapse into a single query.
    func beginRefresh(_ key: Key) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return refreshingKeys.insert(key).inserted
    }

    func endRefresh(_ key: Key) {
        lock.lock(); defer { lock.unlock() }
        refreshingKeys.remove(key)
    }

    /// Marks every entry out of date WITHOUT dropping it, and returns the keys that now owe a refresh.
    @discardableResult
    func invalidateAll() -> [Key] {
        lock.lock(); defer { lock.unlock() }
        staleKeys = Set(values.keys)
        return Array(values.keys)
    }
}

/// How a block's length is written next to it — "(45 min)", "(1h43m)", "(2h)".
///
/// The Day Plan showed every duration in bare minutes, so a deep-work block read "(103 min)" and the
/// reader had to do the division (report 2026-09-21_17-57-15). Anything an hour or longer now says so.
///
/// The three patterns are passed in rather than read from `configjson` here, so the thresholds can be
/// tested without the config globals and the strings stay translatable.
enum ScheduleDuration {

    /// Whole hours and the remaining minutes. Negative input is treated as zero — a block cannot run
    /// backwards, and `(-1h-43m)` is a worse way to show a bug than `(0 min)`.
    static func hoursAndMinutes(_ totalMinutes: Int) -> (hours: Int, minutes: Int) {
        let safe = max(totalMinutes, 0)
        return (safe / 60, safe % 60)
    }

    /// Picks among the three forms. An exact hour drops the minutes ("2h", not "2h0m"); under an
    /// hour stays in minutes, because "0h45m" is noise.
    static func bracketed(_ totalMinutes: Int,
                          minutesOnly: String,
                          hoursOnly: String,
                          hoursAndMinutes hoursAndMinutesPattern: String) -> String {
        let split = hoursAndMinutes(totalMinutes)
        if split.hours == 0 { return String(format: minutesOnly, split.minutes) }
        if split.minutes == 0 { return String(format: hoursOnly, split.hours) }
        return String(format: hoursAndMinutesPattern, split.hours, split.minutes)
    }
}
