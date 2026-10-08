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

    /// Anything announced as lasting longer than this is an all-day event or a day-long calendar
    /// block, not a call. "Look after Sean", 08:00–20:30, arrived as an ordinary announcement and was
    /// covered like a meeting: it held an appointment popup over the routine from 07:57, and at 11:29
    /// it postponed the morning routine until 20:32 (report 2026-09-25_22-31-53, follow-up).
    static let longestMeetingSeconds = 4 * 60 * 60

    /// The most a single meeting-aware postpone or extension may add. A meeting that runs longer is
    /// still covered to its end, just in steps: `extensionSecondsToCoverMeeting` re-checks shortly
    /// before each postpone ends and extends it while the meeting is live. Bounding each step is what
    /// keeps a bad calendar entry from hiding the routine for the rest of the day.
    static let maximumPostponeSeconds = 60 * 60
}

/// One meeting as announced by Late No More via `focusbear://event-about-to-start`.
struct AnnouncedMeeting: Equatable {
    let title: String
    let start: Date
    let end: Date
}

/// Pure decisions about whether a meeting has to be covered, and for how long.
enum MeetingCoverage {

    /// Whether an announced event is short enough to be a meeting at all — see `longestMeetingSeconds`.
    static func isMeeting(start: Date, end: Date) -> Bool {
        end.timeIntervalSince(start) <= TimeInterval(MeetingPostponeRules.longestMeetingSeconds)
    }

    static func isMeeting(_ meeting: AnnouncedMeeting) -> Bool {
        isMeeting(start: meeting.start, end: meeting.end)
    }

    /// `resumeAt`, pulled in so it is no more than `maximumPostponeSeconds` after `now`.
    private static func capped(_ resumeAt: Date, now: Date) -> Date {
        min(resumeAt, now.addingTimeInterval(TimeInterval(MeetingPostponeRules.maximumPostponeSeconds)))
    }

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
        let upcoming = meetings.filter { $0.end > now && isMeeting($0) }.sorted { $0.start < $1.start }
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

    /// The meeting a routine postpone is being held open for, and when the routine comes back.
    ///
    /// `nil` when no announced meeting is live or imminent, or no postpone is running. The postpone
    /// stretches itself over meetings silently (`extendPostponeToCoverAnnouncedMeetings`), so without
    /// this the user saw a plain "routine postponed" and asked why their habits didn't come back when
    /// the session that postponed them ended (report 2026-09-25_15-36-42: a 15-minute postpone ran on
    /// to 15:47 for a 15:30–15:45 meeting, then again for the 15:45 standup).
    static func hold(now: Date, meetings: [AnnouncedMeeting], postponeEnd: Date?) -> (meeting: AnnouncedMeeting, resumesAt: Date)? {
        guard let postponeEnd = postponeEnd, postponeEnd > now,
              let meeting = meetings.filter({ $0.end > now }).sorted(by: { $0.start < $1.start })
                .first(where: { isLiveOrImminent($0, now: now) }) else { return nil }
        return (meeting, postponeEnd)
    }

    /// Seconds a routine postpone must run when an appointment popup is confirmed or auto-closes.
    ///
    /// It is the latest of: the bare grace period, this popup's own meeting plus grace, the whole
    /// live/imminent meeting chain plus grace — never more than `maximumPostponeSeconds` of it — and
    /// whatever postpone is already running. The chain is what stops the routine resuming in the
    /// seam of back-to-back meetings; the cap is what stops a day-long calendar entry from turning
    /// that into a nine-hour postpone.
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
        resumeAt = capped(resumeAt, now: now)
        // Outside the cap on purpose: a postpone the user already has running is theirs, and this
        // rule only decides what a meeting adds to it.
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

    static func shouldHoldMorningRoutineForMeeting(isUserOnMeeting: Bool,
                                                   isMeetingSessionLive: Bool) -> Bool {
        isUserOnMeeting || isMeetingSessionLive
    }

    /// An old reminder can expire after a following meeting has started while the Mac was locked.
    /// Its timeout must not restore habits over a session that still owns the user's attention.
    static func shouldResumeRoutineAfterAppointmentTimeout(now: Date, meetings: [AnnouncedMeeting],
                                                          isMeetingSessionLive: Bool) -> Bool {
        !isMeetingSessionLive && !hasLiveOrImminentMeeting(now: now, meetings: meetings)
    }

    /// Seconds to extend a RUNNING postpone by so it covers the meeting chain that is live or
    /// imminent right now; `nil` when nothing needs covering and the postpone may end normally.
    ///
    /// This is what suppresses the "Habit resumes in…" countdown mid-meeting: the countdown fires
    /// `endNotificationLeadSeconds` before the postpone ends, and if a meeting is live at that
    /// moment the postpone is extended instead of announced.
    static func extensionSecondsToCoverMeeting(now: Date, meetings: [AnnouncedMeeting],
                                               currentPostponeEnd: Date? = nil) -> Int? {
        guard let coverage = coverageEnd(now: now, meetings: meetings) else { return nil }
        let meetingEnd = capped(coverage.addingTimeInterval(TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd)),
                                now: now)
        let resumeAt = max(meetingEnd, currentPostponeEnd ?? meetingEnd)
        guard resumeAt > now else { return nil }
        return Int(resumeAt.timeIntervalSince(now).rounded())
    }

    /// Whether a meeting focus session may be auto-ended now that live detection has gone quiet.
    ///
    /// Detection is microphone- and AppleScript-based, so it goes quiet whenever a call is *being
    /// joined* — a browser walking through Teams' launcher, a meeting app relaunching — which is
    /// indistinguishable from the meeting having ended. So while the user has not yet been seen IN
    /// the call, the calendar gets a veto (report 2026-09-16: the session died at 10:00:40 mid-join,
    /// after an 8-second pre-join device check, in the same second the postpone logic extended
    /// itself "to cover a live/imminent meeting").
    ///
    /// That veto must not outlive the join. Once detection has established the user was in the
    /// call, the call going quiet for `quietSecondsBeforeEnding` means they left — the calendar
    /// only says when the meeting was *booked* to end. Report 2026-09-28_09-53-49: a 23-minute Teams
    /// call ended at 09:53:09 and the veto held the session (and the morning routine) until the
    /// calendar entry ran out at 10:00.
    ///
    /// - Parameters:
    ///   - isUserOnMeeting: live detection currently sees a call.
    ///   - hasLiveAnnouncedMeeting: `hasLiveOrImminentMeeting` for now.
    ///   - lastPresenceSeconds: how long the most recent run of detected presence lasted, or `nil`
    ///     when detection has never seen the call.
    ///   - quietSeconds: how long detection has seen no call since that run ended.
    static func autoEndDecision(isUserOnMeeting: Bool,
                                hasLiveAnnouncedMeeting: Bool,
                                lastPresenceSeconds: TimeInterval?,
                                quietSeconds: TimeInterval) -> MeetingSessionAutoEndDecision {
        guard !isUserOnMeeting else { return .keepStillInCall }
        guard quietSeconds >= MeetingSessionAutoEndRules.quietSecondsBeforeEnding else { return .keepNotQuietLongEnough }
        guard hasLiveAnnouncedMeeting else { return .end }
        let wasInTheCall = (lastPresenceSeconds ?? 0) >= MeetingSessionAutoEndRules.establishedPresenceSeconds
        return wasInTheCall ? .end : .keepCalendarSaysStillJoining
    }

    /// When a new run of detected presence counts as starting. A run that resumes within the quiet
    /// window is the same call after a witness dropout (the 4-sample gap of 2026-09-15, the 25-second
    /// join gap of 2026-09-16), so it keeps the original start; otherwise it starts now. Without this
    /// a dropout would reset presence below `establishedPresenceSeconds` and re-arm the calendar veto
    /// for the rest of the call.
    static func presenceRunStart(now: Date, previousRunStart: Date?, previousRunEnd: Date?) -> Date {
        guard let previousRunStart, let previousRunEnd,
              now.timeIntervalSince(previousRunEnd) < MeetingSessionAutoEndRules.quietSecondsBeforeEnding
        else { return now }
        return previousRunStart
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

/// Timing for ending a meeting focus session on its own once live detection stops seeing the call.
enum MeetingSessionAutoEndRules {
    /// "The focus session should have ended automatically after 30 seconds of no meeting" (report
    /// 2026-09-28_09-53-49). Also outlasts every witness dropout seen in a live call so far: four
    /// missed 5-second samples on 2026-09-15 and a 25-second gap mid-join on 2026-09-16.
    static let quietSecondsBeforeEnding: TimeInterval = 30

    /// Detected presence at least this long means the user was in the call rather than passing
    /// through a pre-join device check (8 seconds on 2026-09-16), so the calendar stops vetoing.
    static let establishedPresenceSeconds: TimeInterval = 2 * 60
}

/// What to do with a meeting focus session when its auto-end check fires.
enum MeetingSessionAutoEndDecision: Equatable {
    /// The meeting is over: end the session and hand back any postponed routine.
    case end
    /// Live detection still sees the call.
    case keepStillInCall
    /// The call has not been quiet for `quietSecondsBeforeEnding` yet — possibly a witness dropout.
    case keepNotQuietLongEnough
    /// Detection never established the user in the call and the calendar says the meeting is on,
    /// so this is most likely a join in progress.
    case keepCalendarSaysStillJoining
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

/// A meeting-aware routine postpone lives exactly as long as the meeting focus session covering it.
///
/// "If a meeting postponed it, it should be in a meeting focus mode." On 26 September the two came
/// apart: the appointment popup postponed the morning routine until 20:32 while the meeting session it
/// started ran for one minute, so from 11:31 the routine was postponed with nothing running and never
/// came back in full screen. Tying the postpone to the session — sized to it, ended with it, dropped at
/// launch without it — makes that state impossible.
///
/// The tie is recorded by saving the tied postpone's end date under its own key: a later postpone of any
/// other kind writes a different end date, so it can never be mistaken for a tied one.
enum MeetingPostponeSession {

    /// Whole minutes a meeting session runs for `secondsRemaining` of meeting — at least one, so a
    /// session is never started empty. Shared by every place that starts one, so the postpone sized
    /// from a session that is ABOUT to start matches the session exactly.
    static func sessionMinutes(secondsRemaining: Int) -> Int {
        max(1, secondsRemaining / 60)
    }

    /// Seconds to postpone the routine for when the user confirms an appointment popup.
    ///
    /// A meeting-owned postpone ends with its session. A borrowed postpone retains
    /// `chainPostponeSeconds`, which already includes the user's existing deadline.
    static func postponeSeconds(now: Date, chainPostponeSeconds: Int, meetingSessionEnd: Date?,
                                ownsRoutinePostpone: Bool = true) -> Int {
        guard ownsRoutinePostpone, let meetingSessionEnd, meetingSessionEnd > now else { return chainPostponeSeconds }
        return Int(meetingSessionEnd.timeIntervalSince(now).rounded())
    }

    /// Whether the saved routine postpone is the one a meeting session was covering.
    static func isTiedToMeetingSession(postponeEnd: Date?, tiedPostponeEnd: Date?) -> Bool {
        guard let postponeEnd, let tiedPostponeEnd else { return false }
        return postponeEnd == tiedPostponeEnd
    }

    /// A meeting that still needs covering once the current one's session has ended: live or imminent,
    /// and with more than the wrap-up grace still to run. The grace excludes the meeting that just
    /// ended — its session is sized in whole minutes, so it stops up to a minute before the calendar
    /// entry does.
    static func followOnMeeting(now: Date, meetings: [AnnouncedMeeting]) -> AnnouncedMeeting? {
        let wrapUp = now.addingTimeInterval(TimeInterval(MeetingPostponeRules.graceSecondsAfterMeetingEnd))
        return meetings
            .filter { MeetingCoverage.isMeeting($0) && MeetingCoverage.isLiveOrImminent($0, now: now) && $0.end > wrapUp }
            .min { $0.start < $1.start }
    }

    /// What a meeting session that has just run out means for the routine postpone it covered.
    enum SessionRunOutOutcome: Equatable {
        /// No tied postpone: finish the session the ordinary way.
        case finishNormally
        /// End the postpone with the session and hand the user back to their routine.
        case resumeRoutine
        /// Another meeting follows straight on: cover it with its own session and postpone.
        case continueInto(AnnouncedMeeting)
    }

    static func outcomeWhenSessionRunsOut(now: Date,
                                          isRoutinePostponed: Bool,
                                          postponeEnd: Date?,
                                          tiedPostponeEnd: Date?,
                                          meetings: [AnnouncedMeeting]) -> SessionRunOutOutcome {
        guard isRoutinePostponed,
              isTiedToMeetingSession(postponeEnd: postponeEnd, tiedPostponeEnd: tiedPostponeEnd) else { return .finishNormally }
        if let next = followOnMeeting(now: now, meetings: meetings) {
            return .continueInto(next)
        }
        return .resumeRoutine
    }
}

/// Which routine postpone saved across a relaunch may be restored.
enum PersistedPostponeRestore {

    static func isLongerThanTheCap(now: Date, postponeEnd: Date) -> Bool {
        postponeEnd.timeIntervalSince(now) > TimeInterval(MeetingPostponeRules.maximumPostponeSeconds)
    }

    /// - Parameters:
    ///   - meetingSessionEnd: when the meeting focus session saved alongside it ends, if one was saved.
    ///   - isFirstLaunchWithCap: builds before the cap saved the nine-hour meeting postpone like any
    ///     other, with no tie recorded, so it can't be told apart from a postpone the user chose. On
    ///     the first launch with the cap anything longer than it is dropped; after that every saved
    ///     postpone is either tied (and judged by its session) or one the user chose.
    static func shouldDiscard(now: Date,
                              postponeEnd: Date,
                              tiedPostponeEnd: Date?,
                              meetingSessionEnd: Date?,
                              isFirstLaunchWithCap: Bool) -> Bool {
        if MeetingPostponeSession.isTiedToMeetingSession(postponeEnd: postponeEnd, tiedPostponeEnd: tiedPostponeEnd) {
            guard let meetingSessionEnd else { return true }
            return meetingSessionEnd <= now
        }
        return isFirstLaunchWithCap && isLongerThanTheCap(now: now, postponeEnd: postponeEnd)
    }

    /// Applies `shouldDiscard` to what `defaults` holds, clearing the saved postpone when it must go.
    /// Returns whether it did, in which case the routine is no longer postponed.
    @discardableResult
    static func discardInvalidPostpone(in defaults: UserDefaults,
                                       now: Date,
                                       meetingSessionEnd: Date?,
                                       endDateKey: String = kUserDefaultsLastRoutinePostponeEndDate,
                                       stateKey: String = kUserDefaultsLastRoutinePostponeState,
                                       tiedEndDateKey: String = kUserDefaultsMeetingSessionPostponeEndDate,
                                       capCheckedKey: String = kUserDefaultsPersistedPostponeCapChecked) -> Bool {
        let isFirstLaunchWithCap = !defaults.bool(forKey: capCheckedKey)
        defaults.set(true, forKey: capCheckedKey)
        guard let postponeEnd = defaults.object(forKey: endDateKey) as? Date,
              shouldDiscard(now: now, postponeEnd: postponeEnd,
                            tiedPostponeEnd: defaults.object(forKey: tiedEndDateKey) as? Date,
                            meetingSessionEnd: meetingSessionEnd,
                            isFirstLaunchWithCap: isFirstLaunchWithCap) else { return false }
        defaults.removeObject(forKey: endDateKey)
        defaults.removeObject(forKey: stateKey)
        defaults.removeObject(forKey: tiedEndDateKey)
        return true
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
