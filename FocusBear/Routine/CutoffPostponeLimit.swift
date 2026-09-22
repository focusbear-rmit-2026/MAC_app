//
//  CutoffPostponeLimit.swift
//  Focus Bear
//
//  What the user's cutoff time is allowed to say about a routine postpone: how long it may run, and
//  when it must be refused outright instead of granted. Pure date maths so the rules are unit-testable
//  without AppKit, timers, the AI buddy or UserDefaults.
//
//  The bug this exists for (report 2026-09-17_17-05-10) — cutoff 17:00:
//   * 17:00:02 — "Postpone abandoned at the start of cutoff_for_high_priority_activities": the app
//     force-ended the running evening postpone because the cutoff had arrived.
//   * 17:00:07 — the shutdown ran and the Focus Summary appeared.
//   * 17:00:12 — "I still need to work more" routed through `abortCurrentState()`, whose
//     `._FOCUS_SUMMARY_` branch opened the postpone flow with NO password check at all, unlike the
//     `._EVENING_HABIT_` branch a few lines above it.
//   * 17:00:23 — the AI accountability buddy approved 10 minutes; the routine was postponed to 17:10
//     and a scoped focus session started "until 05:10 pm" — ten minutes past the cutoff, no password.
//
//  Two separate rules come out of that, kept as two small functions because they answer different
//  questions and apply at different points in the flow.
//

import Foundation

/// The cutoff's say over a routine postpone.
enum CutoffPostponeLimit {

    /// Whether a postpone must be refused outright rather than granted or password-gated.
    ///
    /// Once the cutoff has passed there is no room left to postpone *into*, so for a user who has
    /// marked the after-cutoff window as their strict one the answer is "no", not a shorter yes.
    /// `isCutoffStrict` is that declaration — the "require a password to postpone the evening routine
    /// after the cutoff" setting, which the reporter had on while leaving the plain before-cutoff
    /// postpone password off. Without it, after-cutoff postponing keeps its previous behaviour.
    ///
    /// - Parameters:
    ///   - hasCutoff: the user has a cutoff time configured at all.
    ///   - isAfterCutoff: we are already in the after-cutoff window.
    ///   - isCutoffStrict: `isPasswordRequireInPostponeEveningAfterCutOff`.
    static func isRefused(hasCutoff: Bool, isAfterCutoff: Bool, isCutoffStrict: Bool) -> Bool {
        hasCutoff && isAfterCutoff && isCutoffStrict
    }

    /// How many minutes a postpone asked for now may actually run.
    ///
    /// The ceiling is the cutoff. This is an honesty fix as much as a strictness one: the app ALREADY
    /// abandons a running postpone the moment the cutoff arrives (the 17:00:02 line above), so minutes
    /// that reached past it were always a promise the app would break. It therefore applies whenever a
    /// cutoff is configured, for strict and non-strict users alike.
    ///
    /// - Parameters:
    ///   - requestedMinutes: what the caller wants — the user's picked minutes, or the AI buddy's
    ///     approved duration.
    ///   - now: the moment the postpone is being granted.
    ///   - cutoff: today's cutoff moment (`cutoff_time_for_non_high_priority_activities`), or `nil`
    ///     when no cutoff is configured.
    ///   - isAfterCutoff: whether we are already past the cutoff. Passed in rather than derived from
    ///     `cutoff`, because the window wraps overnight: at 03:00 with a 17:00 cutoff we are *after*
    ///     yesterday's cutoff even though today's cutoff Date is still hours away. Past the cutoff
    ///     there is nothing to clamp to, so the request stands — `isRefused` owns that case.
    ///   - currentPostponeEnd: the end of the postpone already running, if any.
    static func grantedMinutes(requestedMinutes: Int,
                               now: Date,
                               cutoff: Date?,
                               isAfterCutoff: Bool,
                               currentPostponeEnd: Date?) -> Int {
        let ceiling = minutesUntilCutoff(now: now, cutoff: cutoff, isAfterCutoff: isAfterCutoff) ?? requestedMinutes
        return flooredByRunningPostpone(min(requestedMinutes, ceiling),
                                        currentPostponeEnd: currentPostponeEnd, now: now)
    }

    /// Whole minutes between `now` and the cutoff, or `nil` when no cutoff lies ahead — none is
    /// configured, or it has already passed and there is nothing left to clamp to.
    ///
    /// Also the ceiling the postpone dialog trims its minutes dropdown to, so the user is never
    /// offered a length the grant would silently shorten.
    static func minutesUntilCutoff(now: Date, cutoff: Date?, isAfterCutoff: Bool) -> Int? {
        guard let cutoff, !isAfterCutoff else { return nil }
        let minutes = Int(cutoff.timeIntervalSince(now) / 60)   // whole minutes, rounded down
        return minutes > 0 ? minutes : nil
    }

    /// A postpone must never come out SHORTER than the one already running — the meeting-coverage rule
    /// in `MeetingPostponeCoverage`, which exists so a Late No More popup closing at its own meeting's
    /// end can't hand the user back to their habits mid-call.
    ///
    /// So when the cutoff is nearer than a running postpone's end, the running postpone wins and the
    /// clamp does not cut it short. That is safe: `AppDelegate` abandons the running postpone at the
    /// cutoff anyway, so the cutoff is still enforced — by the mechanism that owns it — while the clamp
    /// keeps to its own job of not pushing the deadline out further.
    private static func flooredByRunningPostpone(_ minutes: Int, currentPostponeEnd: Date?, now: Date) -> Int {
        guard let currentPostponeEnd else { return minutes }
        let runningMinutes = Int((currentPostponeEnd.timeIntervalSince(now) / 60).rounded(.up))
        return max(minutes, runningMinutes)
    }
}

/// Extra focus minutes are added to the existing session end, not to the time of approval.
/// Unlike routine meeting coverage, a running postpone is not a floor for this NEW grant.
enum FocusExtensionCutoffLimit {
    static func grantedMinutes(requested: Int, now: Date, currentEnd: Date?, cutoff: Date?,
                               isAfterCutoff: Bool, isCutoffStrict: Bool, protectsRoutine: Bool) -> Int {
        guard requested > 0 else { return 0 }
        guard protectsRoutine, let cutoff = cutoff else { return requested }
        if isAfterCutoff { return isCutoffStrict ? 0 : requested }
        let base = max(now, currentEnd ?? now)
        let available = max(0, Int(floor(cutoff.timeIntervalSince(base) / 60)))
        return min(requested, available)
    }
}

// MARK: - App glue

/// Today's cutoff moment (`cutoff_time_for_non_high_priority_activities`), or `nil` when the user has
/// no cutoff configured.
func todaysCutoffDate(now: Date = Date()) -> Date? {
    guard let cutOffTime = cutOffTime else { return nil }
    return Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute,
                                 second: cutOffTime.second, of: now)
}

/// True when postponing the routine right now needs the password the user asked for.
///
/// `isPasswordRequireInPostponeEveningAfterCutOff` is the setting "require a password for postponing
/// the evening routine after the cutoff time". It means ASK, not FORBID. An earlier version of this
/// read it as a declaration that the window was off-limits and refused outright — the alert even
/// told the user their own setting meant "this is the time you decided to stop". It does not; the
/// user who turned it on is the one who wanted a way through, guarded by a password.
///
/// The real bug behind that change (report 2026-09-17_17-05-10) was a postpone granted past the
/// cutoff with NO password asked. Asking fixes that; refusing overshoots it.
func isRoutinePostponeAfterCutoffPasswordRequired() -> Bool {
    CutoffPostponeLimit.isRefused(hasCutoff: cutOffTime != nil,
                                  isAfterCutoff: isCutOffTimeGoing(),
                                  isCutoffStrict: SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff)
}

/// Whole minutes left before the cutoff, or `nil` when no cutoff lies ahead, reading the live globals.
func minutesUntilCutoff(now: Date = Date()) -> Int? {
    CutoffPostponeLimit.minutesUntilCutoff(now: now,
                                           cutoff: todaysCutoffDate(now: now),
                                           isAfterCutoff: isCutOffTimeGoing())
}

/// `requestedMinutes` clamped so the postpone can't end after the cutoff, reading the live globals.
func cutoffLimitedPostponeMinutes(_ requestedMinutes: Int, now: Date = Date()) -> Int {
    CutoffPostponeLimit.grantedMinutes(requestedMinutes: requestedMinutes,
                                       now: now,
                                       cutoff: todaysCutoffDate(now: now),
                                       isAfterCutoff: isCutOffTimeGoing(),
                                       currentPostponeEnd: currentRoutinePostponeEndDate())
}

/// `requestedSeconds` clamped so the postpone can't end after the cutoff.
///
/// The ceiling is whole minutes, so an unclamped request keeps its exact seconds and only a request
/// that actually overruns the cutoff is cut back — to a whole number of minutes.
func cutoffLimitedPostponeSeconds(_ requestedSeconds: Int, now: Date = Date()) -> Int {
    let requestedMinutes = Int((Double(requestedSeconds) / 60).rounded(.up))
    let grantedMinutes = cutoffLimitedPostponeMinutes(requestedMinutes, now: now)
    return grantedMinutes >= requestedMinutes ? requestedSeconds : grantedMinutes * 60
}
