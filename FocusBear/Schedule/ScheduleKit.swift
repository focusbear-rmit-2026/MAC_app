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

struct ScheduleMeetingInput {
    let id: String
    let title: String
    let start: Date
    let end: Date
    var isDismissed: Bool = false   // hidden by the user; surfaced (struck through) when "Show dismissed events" is on
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
            // segment is one overflow group. Preview/earlier routines drop them.
            if seg.actionable {
                for h in placement.unplaced {
                    var b = ScheduleBlock(kind: .habit, title: h.title, start: overflowAnchor, end: overflowAnchor,
                                          habitIndex: h.index, routineName: seg.name)
                    b.isActionable = true
                    b.isEditable = true
                    b.isDone = h.isDone
                    b.habitId = h.id
                    b.didOverflow = true
                    // Keep the block zero-duration (start == end) so it groups and doesn't count as busy
                    // time, but remember the habit's own length so the UI can show a sequential range.
                    b.overflowDurationSeconds = remainingSeconds(of: h)
                    blocks.append(b)
                    placed.append(blocks.count - 1)
                }
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
