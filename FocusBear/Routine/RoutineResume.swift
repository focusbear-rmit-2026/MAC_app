//
//  RoutineResume.swift
//  Focus Bear
//
//  "I had postponed earlier and then stopped the focus session. It should have taken me back to full
//  screen to continue my habits" — report 2026-09-17_12-03-44.
//
//  The resume DID run. `resumeMorningHabit()` opens with a meeting guard —
//
//      if extendPostponeToCoverAnnouncedMeetings(){ return }
//
//  — added so the postpone *timer elapsing* could never land the routine on screen mid-call. But
//  `stopFocusModeAndResumeRoutine()` reuses that same function, so the guard also swallowed the
//  user's explicit "stop this session and give me my habits back", silently re-postponing instead:
//
//      12:02:20  [user-action] Stop focus session started from postpone:- skip password + resume routine
//      12:02:20  Morning habits postpone finished
//      12:02:20  extendPostponeToCoverAnnouncedMeetings:- morning postpone extended to 1819 seconds …
//
//  So the entry point has to be an input to the decision, exactly as it is for
//  `AllowedActivityFullScreen`. An automatic resume still defers to an announced meeting; an explicit
//  request does not, because the person pressing the button knows better than the calendar whether
//  they are actually in that meeting. A LIVE meeting *session* still vetoes both — that is Focus Bear
//  actively running a meeting the user has not stopped, which is a different claim from a calendar
//  entry that merely exists.
//

import Foundation

/// Why a postponed routine is being resumed.
enum RoutineResumeTrigger: Equatable {
    /// The postpone timer elapsed. Nobody asked for this right now, so it must not interrupt a meeting.
    case postponeElapsed
    /// The user explicitly asked for the routine back — stopping a session that was started by
    /// postponing the routine in the first place.
    case userRequested
}

enum RoutineResume {

    /// What should happen to a postponed routine.
    enum Decision: Equatable {
        /// Hand the user back to their habits now.
        case resume
        /// Keep waiting, and stretch the postpone over the meeting that is live or imminent.
        case extendPostponeOverMeeting
        /// Keep waiting, leaving the postpone exactly as it is.
        case stayPostponed
    }

    /// - Parameters:
    ///   - trigger: which entry point is asking. See `RoutineResumeTrigger`.
    ///   - isRoutinePostponed: there is actually a postponed routine to go back to
    ///     (`routinePostponeStateToReCoverOnExtend() != nil`). With nothing postponed there is nothing
    ///     to resume, however the request arrived.
    ///   - hasMeetingToCover: a meeting Focus Bear itself announced is live or imminent
    ///     (`MeetingCoverage.extensionSecondsToCoverMeeting(...) != nil`).
    ///   - isMeetingSessionLive: a meeting focus session is actually running
    ///     (`currentAccountabilityBuddySession?.isMeeting == true`). Sample after an explicit finish;
    ///     the meeting that just ended must no longer veto recovering its postponed routine.
    static func decision(trigger: RoutineResumeTrigger,
                         isRoutinePostponed: Bool,
                         hasMeetingToCover: Bool,
                         isMeetingSessionLive: Bool) -> Decision {
        switch trigger {
        case .userRequested:
            // Nothing postponed means there is no routine to go back to, so the request is a no-op.
            guard isRoutinePostponed else { return .stayPostponed }
            // A live meeting session outranks even an explicit request: Focus Bear is actively running
            // that meeting, which is a much stronger claim than a calendar entry merely existing.
            guard !isMeetingSessionLive else { return .stayPostponed }
            // Otherwise the request wins. A calendar entry is a guess about what someone is doing;
            // pressing "stop this session and give me my habits" is not — and a button that silently
            // does nothing is worse than resuming a routine the user asked for.
            return .resume
        case .postponeElapsed:
            // The postpone timer also fires for a micro break or custom routine that ran *inside* the
            // postpone. Those have no postpone left to stretch and must carry on unwinding exactly as
            // they did before, so they fall straight through to the resume body.
            guard isRoutinePostponed else { return .resume }
            // Automatic, with a routine waiting: an announced meeting means the user is busy. Wait it
            // out rather than putting the routine on screen mid-call.
            return hasMeetingToCover ? .extendPostponeOverMeeting : .resume
        }
    }
}
