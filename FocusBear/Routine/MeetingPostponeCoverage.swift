//
//  MeetingPostponeCoverage.swift
//  Focus Bear
//
//  How long a routine postpone must run so it COVERS the meetings Late No More announced, instead
//  of expiring into one of them. Pure date maths plus a small register of the meetings the
//  `focusbear://event-about-to-start` deep link told us about, so the rules are unit-testable
//  without AppKit, timers or UserDefaults.
//
//  The bug this exists for (report 2026-09-15_13-03-02): "Lunch" 12:45–13:00 and "UX checkin"
//  13:00–13:20 were back to back.
//   * The Lunch appointment popup sat open, unanswered.
//   * The UX checkin trigger at 12:57 was dropped wholesale because that popup was still visible,
//     so nothing in the app knew a second meeting was seconds away.
//   * At 13:00 the Lunch popup auto-closed at its own end time and postponed the morning routine
//     for `remaining (≈ 0) + 160` seconds — cutting the postpone to 2m40s.
//   * 40 seconds into the UX checkin the "Habit resumes in…" countdown appeared.
//
//  So the postpone has to be computed from every announced meeting that is live or imminent —
//  chained across back-to-back meetings — and it must never come out shorter than the postpone
//  that is already running.
//

import Foundation

/// The timing rules behind meeting-aware postpones. These were bare literals at the call sites
/// (`duration + 160`, `seconds - 120`), which is how the 160 ended up being the entire postpone.
enum MeetingPostponeRules {
    /// Breathing room added after a meeting ends before the routine resumes — time to wrap the call
    /// up and get back to the desk. Historically the bare `+ 160` at the appointment-popup call sites.
    static let graceSecondsAfterMeetingEnd = 160

    /// How far ahead of the postpone actually ending the "Habit resumes in…" countdown appears.
    static let endNotificationLeadSeconds = 120

    /// A meeting starting within this long counts as imminent: close enough that letting the routine
    /// resume now would drop the user back into habits seconds before a call.
    static let imminentMeetingLeadSeconds = 5 * 60

    /// Gap at or below which two announced meetings count as one unbroken busy block. The routine
    /// must not resume in the seam of a back-to-back chain.
    static let backToBackGapSeconds = 5 * 60

    /// How long an announced meeting is remembered after it has ended, before the register drops it.
    static let meetingRetentionSeconds = 60 * 60
}

/// One meeting as announced by Late No More via `focusbear://event-about-to-start`.
struct AnnouncedMeeting: Equatable {
    let title: String
    let start: Date
    let end: Date
}

/// Pure decisions about whether a meeting has to be covered, and for how long.
enum MeetingCoverage {

    /// True when `meeting` is running right now or starts within the imminent window.
    static func isLiveOrImminent(_ meeting: AnnouncedMeeting, now: Date) -> Bool {
        guard meeting.end > now else { return false }
        return meeting.start <= now.addingTimeInterval(TimeInterval(MeetingPostponeRules.imminentMeetingLeadSeconds))
    }

    /// The end of the back-to-back chain of announced meetings that is running at — or about to
    /// start at — `now`; `nil` when no meeting needs covering.
    ///
    /// Chaining matters as much as the seed: Lunch ending at 13:00 and UX checkin starting at 13:00
    /// are one busy block, and a postpone that only spans the first of them hands the user back to
    /// their habits inside a meeting.
    static func coverageEnd(now: Date, meetings: [AnnouncedMeeting]) -> Date? {
        let upcoming = meetings.filter { $0.end > now }.sorted { $0.start < $1.start }
        guard var coverage = upcoming.first(where: { isLiveOrImminent($0, now: now) })?.end else { return nil }
        let seam = TimeInterval(MeetingPostponeRules.backToBackGapSeconds)
        var didExtend = true
        while didExtend {
            didExtend = false
            for meeting in upcoming where meeting.end > coverage && meeting.start <= coverage.addingTimeInterval(seam) {
                coverage = meeting.end
                didExtend = true
            }
        }
        return coverage
    }

    /// Seconds a routine postpone must run when an appointment popup is confirmed or auto-closes.
    ///
    /// It is the latest of: the bare grace period, this popup's own meeting plus grace, the whole
    /// live/imminent meeting chain plus grace, and whatever postpone is already running. The last
    /// two are the fix: when the popup auto-closes AT its meeting's end, `appointmentEnd` is
    /// already in the past and the old `remaining + 160` collapsed to 160 seconds flat.
    static func postponeSeconds(now: Date,
                                meetings: [AnnouncedMeeting],
                                appointmentEnd: Date?,
                                currentPostponeEnd: Date?) -> Int {
        let grace = TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd)
        var resumeAt = now.addingTimeInterval(grace)
        if let appointmentEnd {
            resumeAt = max(resumeAt, appointmentEnd.addingTimeInterval(grace))
        }
        if let coverage = coverageEnd(now: now, meetings: meetings) {
            resumeAt = max(resumeAt, coverage.addingTimeInterval(grace))
        }
        if let currentPostponeEnd {
            resumeAt = max(resumeAt, currentPostponeEnd)
        }
        return Int(resumeAt.timeIntervalSince(now).rounded())
    }

    /// Seconds a MICRO-BREAK postpone must run when an appointment popup is confirmed.
    ///
    /// Deliberately NOT `postponeSeconds`, and the difference is the whole point. A routine is a
    /// once-a-day event, so it must not resume in the seam of a back-to-back chain — hence
    /// `coverageEnd`. A micro-break is the opposite: it recurs every `breakAfterMinutes`, and the
    /// seam between two meetings is precisely when the user should stand up.
    ///
    /// Sharing the routine rule meant acknowledging a meeting reminder while a micro-break was on
    /// screen postponed breaks across the ENTIRE chain — 8641 seconds on a 30-minute break setting,
    /// so "Next break in: 138 minutes" (report 2026-09-21_15-14-47).
    ///
    /// A break falling due during a LATER meeting needs no prediction here:
    /// `rescheduleBreakSoonAfterBlocked()` already re-checks shortly when a break cannot be shown,
    /// so it waits for that meeting to end and then fires.
    /// Whether what is being postponed recurs through the day, and so must come back between
    /// meetings rather than after the last one.
    ///
    /// This is the distinction the appointment popup got wrong, and it is here rather than at the
    /// call site so it can be tested. A `switch` also means a routine added later has to answer the
    /// question instead of silently inheriting the chain.
    static func recursThroughTheDay(_ routine: CURRENTSTATE?) -> Bool {
        switch routine {
        case ._MICRO_BREAK_?:
            return true
        case ._MORNING_HABIT_?, ._EVENING_HABIT_?, ._CUSTOM_ROUTINE_?:
            return false
        default:
            return false
        }
    }

    /// The postpone an appointment confirmation should apply, picked by what is being postponed.
    /// Recurring things get this meeting only; once-a-day routines get the whole chain.
    static func postponeSeconds(for routine: CURRENTSTATE?,
                                now: Date,
                                meetings: [AnnouncedMeeting],
                                appointmentEnd: Date?,
                                currentPostponeEnd: Date?,
                                breaksAllowedDuringMeetings: Bool,
                                breakIntervalSeconds: Int) -> Int {
        if recursThroughTheDay(routine) {
            return breakPostponeSeconds(now: now, appointmentEnd: appointmentEnd,
                                        breaksAllowedDuringMeetings: breaksAllowedDuringMeetings,
                                        breakIntervalSeconds: breakIntervalSeconds)
        }
        return postponeSeconds(now: now, meetings: meetings, appointmentEnd: appointmentEnd,
                               currentPostponeEnd: currentPostponeEnd)
    }

    /// - Parameters:
    ///   - breaksAllowedDuringMeetings: the user's "show breaks while in a call" setting.
    ///   - breakIntervalSeconds: one normal gap between breaks (`breakAfterMinutes` × 60).
    static func breakPostponeSeconds(now: Date,
                                     appointmentEnd: Date?,
                                     breaksAllowedDuringMeetings: Bool,
                                     breakIntervalSeconds: Int) -> Int {
        let grace = TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd)
        // "I have breaks enabled during meetings." Then a meeting is not a reason to stop having
        // them — only a reason to skip the one being dismissed right now to answer the call. Defer
        // by one ordinary interval and let the normal cadence carry on THROUGH the meeting, rather
        // than waiting the meeting out (report 2026-09-21_15-14-47, follow-up).
        if breaksAllowedDuringMeetings {
            return max(breakIntervalSeconds, MeetingPostponeRules.graceSecondsAfterMeetingEnd)
        }
        var resumeAt = now.addingTimeInterval(grace)
        if let appointmentEnd {
            resumeAt = max(resumeAt, appointmentEnd.addingTimeInterval(grace))
        }
        return Int(resumeAt.timeIntervalSince(now).rounded())
    }

    /// Seconds to extend a RUNNING postpone by so it covers the meeting chain that is live or
    /// imminent right now; `nil` when nothing needs covering and the postpone may end normally.
    ///
    /// This is what suppresses the "Habit resumes in…" countdown mid-meeting: the countdown fires
    /// `endNotificationLeadSeconds` before the postpone ends, and if a meeting is live at that
    /// moment the postpone is extended instead of announced.
    static func extensionSecondsToCoverMeeting(now: Date, meetings: [AnnouncedMeeting]) -> Int? {
        guard let coverage = coverageEnd(now: now, meetings: meetings) else { return nil }
        let resumeAt = coverage.addingTimeInterval(TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd))
        guard resumeAt > now else { return nil }
        return Int(resumeAt.timeIntervalSince(now).rounded())
    }

    /// Whether a meeting focus session may be auto-ended now that live detection has gone quiet.
    ///
    /// Detection is microphone- and AppleScript-based, so it goes quiet whenever a call is *being
    /// joined* — a browser walking through Teams' launcher, a meeting app relaunching — which is
    /// indistinguishable from the meeting having ended. Lengthening the grace window does not fix
    /// that; a join can take longer than any grace worth waiting.
    ///
    /// The calendar does know, so it gets a veto. Ending the session while an announced meeting is
    /// still running is always wrong, and the cost of being late to end is one quiet re-check
    /// (report 2026-09-16: the session died at 10:00:40 mid-join, in the same second the postpone
    /// logic extended itself "to cover a live/imminent meeting" — two subsystems, two answers).
    static func shouldAutoEndMeetingSession(isUserOnMeeting: Bool, hasLiveAnnouncedMeeting: Bool) -> Bool {
        !isUserOnMeeting && !hasLiveAnnouncedMeeting
    }

    /// Whether the calendar currently announces a meeting that is running or about to start.
    static func hasLiveOrImminentMeeting(now: Date, meetings: [AnnouncedMeeting]) -> Bool {
        coverageEnd(now: now, meetings: meetings) != nil
    }

    /// Whether an appointment popup already on screen for a meeting ending at `showing` should be
    /// re-pointed at a newly announced meeting ending at `incoming`.
    ///
    /// The deep-link handler used to drop EVERY trigger that arrived while a popup was visible —
    /// which is dedupe for a re-announced meeting but silently discards the next one in a
    /// back-to-back chain. Re-point only when the new meeting reaches further, so a duplicate (or a
    /// shorter overlapping) trigger can never shorten the coverage already on screen.
    static func shouldRetargetAppointmentPopup(showing: Date, incoming: Date) -> Bool {
        incoming > showing
    }
}

/// The meetings Late No More has announced to this app session.
///
/// The postpone has to be able to see the NEXT meeting, not just the one whose popup happens to be
/// on screen, so every accepted `event-about-to-start` trigger is recorded here — including ones
/// that don't open a popup of their own. Entries are dropped once they are well past.
final class AnnouncedMeetingRegister {

    static let shared = AnnouncedMeetingRegister()

    private let lock = NSLock()
    private var meetings: [AnnouncedMeeting] = []

    /// Records an announced meeting, replacing any earlier announcement of the same one (Late No
    /// More re-fires its trigger, and a re-announced meeting can carry a corrected end time).
    func record(title: String, start: Date, end: Date, now: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        meetings.removeAll { $0.title == title && $0.start == start }
        meetings.append(AnnouncedMeeting(title: title, start: start, end: end))
        prune(now: now)
    }

    /// The announced meetings still worth considering at `now`.
    func activeMeetings(now: Date = Date()) -> [AnnouncedMeeting] {
        lock.lock()
        defer { lock.unlock() }
        prune(now: now)
        return meetings
    }

    private func prune(now: Date) {
        let cutoff = now.addingTimeInterval(-TimeInterval(MeetingPostponeRules.meetingRetentionSeconds))
        meetings.removeAll { $0.end < cutoff }
    }
}

// MARK: - App glue

/// The end of the routine postpone that is running right now, or `nil` when none is.
///
/// Read so a fresh postpone can never come out SHORTER than the one it replaces — a Late No More
/// popup auto-closing at its own meeting's end used to overwrite a long postpone with the bare
/// grace period.
func currentRoutinePostponeEndDate() -> Date? {
    switch currentState {
    case ._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_:
        return UserDefaults.standard.object(forKey: kUserDefaultsLastRoutinePostponeEndDate) as? Date
    default:
        return nil
    }
}
