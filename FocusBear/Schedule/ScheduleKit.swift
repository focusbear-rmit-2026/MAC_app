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
    var isCurrent: Bool        // the next habit up (highlighted)
    var subtitle: String?      // e.g. "meeting", or a duration label
    var didOverflow: Bool      // habit couldn't be placed before day end
    var eventID: String?       // calendar event identifier (for meetings, so they can be dismissed)
    var routineName: String?   // for habits: which routine they belong to (used to group them)
    var isDone: Bool = false   // habit completed today — rendered struck through (earlier-today sections)
    var habitId: String?       // the habit's server id — used to complete/skip a PAST habit by id
    var isEarlier: Bool = false // from an "earlier today" section (past routine); actioned by id, not index

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
        var deepWorkNoRoom = "🧠 Deep work (no room for next habit)"
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

            // Place habits strictly in their list order (no reordering). Each starts at the
            // running cursor, pushed past any meeting it would overlap, and everything after it
            // follows — so a long first habit stays first instead of being leap-frogged.
            var cursor = segStart
            var placed = [Int]()
            for h in seg.habits {
                // A habit with a cutoff stays visible until that cutoff time has actually passed —
                // not merely because its *projected* slot would land after it. The user can still do
                // it (possibly out of order) right up to the cutoff, so don't hide it early. (An
                // "earlier today" section is past history: show every habit regardless of cutoff.)
                if !seg.isEarlier, let cutoff = h.cutoff, now > cutoff { continue }
                let remaining = max(0, h.durationSeconds - (h.isPlaying ? h.elapsedSeconds : 0))
                let dur = Double(remaining)
                guard let start = nextFreeStart(from: cursor, duration: dur,
                                                busy: habitBusy, windowEnd: seg.windowEnd) else {
                    // Can't fit before the window ends. Habits run in sequence, so everything after this
                    // one can't fit either — stop here rather than leap-frogging to a shorter later habit
                    // (which made a long habit like "Go for run" vanish while the next one still showed).
                    break
                }
                let end = start.addingTimeInterval(dur)
                cursor = end
                var b = ScheduleBlock(kind: .habit, title: h.title, start: start, end: end,
                                      habitIndex: h.index, routineName: seg.name)
                b.isActionable = seg.actionable
                b.isDone = h.isDone
                b.habitId = h.id
                b.isEarlier = seg.isEarlier
                blocks.append(b)
                placed.append(blocks.count - 1)
                occupied.append((start, end))
            }

            // The whole active routine is tappable (tap a habit to move the action bar to it);
            // its next-up habit is the default selection. Preview routines aren't actionable.
            if seg.actionable, let nextIdx = placed.min(by: { blocks[$0].start < blocks[$1].start }) {
                for i in placed { blocks[i].isActionable = true }
                blocks[nextIdx].isCurrent = true
            } else {
                for i in placed { blocks[i].isActionable = false }
            }
        }

        for m in upcomingMeetings {
            blocks.append(ScheduleBlock(kind: .meeting, title: m.title, start: m.start, end: m.end,
                                        subtitle: labels.meeting, eventID: m.id))
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
        let habitStarts = blocks.filter { $0.kind == .habit }.map { $0.start }
        for iv in freeIntervals(from: now, to: deepWorkEnd, busy: occupied) {
            if iv.1.timeIntervalSince(iv.0) >= Double(minDeepWorkSeconds) {
                // A gap is "no room for the next habit" only when it ends because a meeting
                // begins (the gap closes at the meeting's leave buffer) *and* a habit was pushed
                // to start right after that meeting ends — i.e. the habit couldn't finish before
                // the meeting, so it got bumped past it. Plain free time before a later routine
                // (whose habits sit hours away) isn't flagged.
                let closingMeeting = upcomingMeetings.first {
                    $0.start >= iv.1.addingTimeInterval(-1) &&
                    $0.start <= iv.1.addingTimeInterval(Double(leaveBufferSeconds) + 60)
                }
                let pushedHabitAfter = closingMeeting.map { m in
                    habitStarts.contains {
                        $0 >= m.end.addingTimeInterval(-60) &&
                        $0 <= m.end.addingTimeInterval(Double(minDeepWorkSeconds))
                    }
                } ?? false
                let title = pushedHabitAfter ? labels.deepWorkNoRoom : labels.deepWork
                blocks.append(contentsOf: deepWorkSprints(from: iv.0, to: iv.1, workTitle: title,
                                                          workSeconds: sprintWorkSeconds,
                                                          breakSeconds: sprintBreakSeconds, labels: labels))
            }
        }

        // The day ends at `dayEnd` (23:59). We no longer trail off into an overnight "Sleep" block
        // or a next-day "Morning routine" marker — the "View tomorrow's schedule" button in the UI
        // takes the user to the next day instead.

        return blocks.sorted { a, b in
            if a.start != b.start { return a.start < b.start }
            return kindOrder(a.kind) < kindOrder(b.kind)
        }
    }

    // MARK: - Helpers

    /// Earliest start ≥ `from` where [start, start+duration] fits before `windowEnd` without
    /// overlapping any busy interval — it pushes past a conflicting meeting rather than
    /// reordering habits around it. Returns nil if it can't fit before the window ends.
    static func nextFreeStart(from: Date, duration: TimeInterval,
                              busy: [(Date, Date)], windowEnd: Date) -> Date? {
        let sorted = busy.sorted { $0.0 < $1.0 }
        var start = from
        var advanced = true
        while advanced {
            advanced = false
            if start.addingTimeInterval(duration) > windowEnd.addingTimeInterval(0.5) { return nil }
            for b in sorted where start < b.1 && start.addingTimeInterval(duration) > b.0 {
                start = b.1            // push to the end of the conflicting meeting
                advanced = true
                break
            }
        }
        return start
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
