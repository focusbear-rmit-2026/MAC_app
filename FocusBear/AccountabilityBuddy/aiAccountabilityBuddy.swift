//
//  AccountabilityBuddy.swift
//  Focus Bear
//
//  AI accountability buddy: when the user postpones their habits we ask what they want to achieve
//  instead, an LLM judges whether that goal is a legitimate reason to be on the computer, and — if it
//  is — starts a SUPER-STRICT focus session that allows only the specific apps/websites needed for
//  that goal and blocks everything else. A rejected goal gets a gentle explanation and alternatives.
//
//  All AI judgement runs SERVER-SIDE through authenticated backend endpoints (the same Auth0 access
//  token the rest of the app uses): the postpone verdict via `/user/evaluate-focus-postponement`, the
//  block-relevance "argue" re-judge via the existing `/user/is-url-safe-to-use` /
//  `/user/is-app-safe-to-use` safety endpoints, and the extend-session reason check via
//  `/user/task-intention-check`. No OpenAI key ever touches the client.
//

import Cocoa
import SwiftUI

// MARK: - Feature constants

/// Clamp the server's suggested session length to something sane.
private let kAccountabilityMinSessionMinutes = 5
private let kAccountabilityMaxSessionMinutes = 180
private let kAccountabilityDefaultSessionMinutes = 25

// MARK: - Verdict model

/// The structured decision the LLM returns for a stated goal.
struct AccountabilityVerdict: Codable {
    /// Whether the goal is a legitimate reason to be on the computer right now.
    let approved: Bool
    /// One or two sentences shown to the user explaining the decision (kind but firm).
    let message: String
    /// A short focus intention the AI distilled from the conversation (e.g. "Prepare for the standup
    /// meeting") — used as the session's intention instead of the user's raw, rambling message. Optional
    /// so older/short responses without it still decode; the raw goal is the fallback.
    let intention: String?
    /// App names the goal legitimately needs (e.g. "Outlook", "Xcode"). Empty when denied.
    let allowedApps: [String]
    /// Website domains/URLs the goal legitimately needs (e.g. "github.com"). Empty when denied.
    let allowedUrls: [String]
    /// How long the focus session should run, in minutes.
    let durationMinutes: Int
    var selectedTaskIds: [String]? = nil

    enum CodingKeys: String, CodingKey {
        case approved, message, intention, selectedTaskIds
        case allowedApps = "allowed_apps"
        case allowedUrls = "allowed_urls"
        case durationMinutes = "allowed_duration_minutes"
    }

    /// Duration clamped to the allowed range, falling back to a sensible default.
    var clampedDurationMinutes: Int {
        let requested = durationMinutes > 0 ? durationMinutes : kAccountabilityDefaultSessionMinutes
        return min(kAccountabilityMaxSessionMinutes, max(kAccountabilityMinSessionMinutes, requested))
    }
}

/// IDs refer to local Day Plan rows, so a to-do minted during the conversation keeps its identity.
struct AccountabilityTaskCandidate: Codable, Equatable {
    let id: String
    let title: String
    let project: String?

    var apiValue: [String: String] {
        var value = ["id": id, "title": AccountabilityRequestText.bounded(title, limit: 200)]
        if let project = project { value["project"] = AccountabilityRequestText.bounded(project, limit: 200) }
        return value
    }
}

enum AccountabilityTaskSelection {
    static func candidates(from tasks: [DayPlanTask]) -> [AccountabilityTaskCandidate] {
        Array(tasks.filter { !$0.done && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(100).map { .init(id: $0.id, title: $0.title, project: $0.project) })
    }

    /// Intersect the verdict with both the offered snapshot and the current unfinished plan.
    static func queue(selectedIDs: [String]?, offered: [AccountabilityTaskCandidate],
                      currentTasks: [DayPlanTask]) -> [FocusSessionTask] {
        let offeredIDs = Set(offered.map(\.id))
        var seen = Set<String>()
        return Array((selectedIDs ?? []).compactMap { id -> FocusSessionTask? in
            guard offeredIDs.contains(id),
                  let task = currentTasks.first(where: { $0.id == id && !$0.done }),
                  seen.insert(task.sourceTaskId ?? task.id).inserted else { return nil }
            return FocusSessionTask(id: task.sourceTaskId ?? task.id, title: task.title,
                                    details: task.notes ?? "", durationSeconds: max(60, task.durationMinutes * 60),
                                    isActive: seen.count == 1, iconEmoji: task.iconEmoji, projectName: task.project)
        }.prefix(8))
    }
}

// MARK: - Localized strings

/// User-facing strings for the AI buddy, read from the `accountabilityBuddyInfo` config block (same
/// block the sibling human-buddy VCs use) so they stay translatable. Loaded once at presentation.
struct AccountabilityBuddyStrings {
    var windowTitle = ""
    var header = ""
    var checking = ""
    var goalPrompt = ""
    var goalHelp = ""
    var buttonNotNow = ""
    var buttonAsk = ""
    var approvedTitle = ""
    var appsUnlocked = ""
    var sitesUnlocked = ""
    var noApps = ""
    var noSites = ""
    var blockedFor = ""      // contains a "{0}" placeholder for the minutes
    var buttonCancel = ""
    var buttonStart = ""
    var deniedTitle = ""
    var buttonDoHabit = ""
    var buttonTryAgain = ""
    var inputPlaceholder = ""
    var buttonSend = ""

    var recoveryTitle = ""
    var recoveryDuration = ""
    var recoveryMinutes = ""
    var recoveryHold = ""
    var recoveryHolding = ""
    var recoveryHoldHelp = ""
    var recoveryClose = ""
    var annoyingPrompt = ""
    var annoyingYes = ""
    var offlineTitle = ""
    var offlineExplanation = ""
    var unavailableTitle = ""
    var unavailableExplanation = ""
    var startForMinutes = ""

    /// Old downloaded configs can lack newly shipped keys. Fall back to the bundled config for the
    /// selected language, so Spanish remains Spanish even while the assets companion is deploying.
    static func load() -> AccountabilityBuddyStrings {
        var s = AccountabilityBuddyStrings()
        let info = configjson.value(forKey: "accountabilityBuddyInfo") as? NSDictionary
        let fileName = BundledConfigLanguage.current()
        let bundled: [String: String]
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            bundled = json["accountabilityBuddyInfo"] as? [String: String] ?? [:]
        } else { bundled = [:] }
        func str(_ key: String) -> String {
            let remote = info?[key] as? String ?? ""
            return remote.isEmpty ? (bundled[key] ?? "") : remote
        }
        s.windowTitle = str("aiBuddyWindowTitle")
        s.header = str("aiBuddyHeader")
        s.checking = str("aiBuddyChecking")
        s.goalPrompt = str("aiBuddyGoalPrompt")
        s.goalHelp = str("aiBuddyGoalHelp")
        s.buttonNotNow = str("aiBuddyButtonNotNow")
        s.buttonAsk = str("aiBuddyButtonAsk")
        s.approvedTitle = str("aiBuddyApprovedTitle")
        s.appsUnlocked = str("aiBuddyAppsUnlocked")
        s.sitesUnlocked = str("aiBuddySitesUnlocked")
        s.noApps = str("aiBuddyNoApps")
        s.noSites = str("aiBuddyNoSites")
        s.blockedFor = str("aiBuddyBlockedFor")
        s.buttonCancel = str("aiBuddyButtonCancel")
        s.buttonStart = str("aiBuddyButtonStart")
        s.deniedTitle = str("aiBuddyDeniedTitle")
        s.buttonDoHabit = str("aiBuddyButtonDoHabit")
        s.buttonTryAgain = str("aiBuddyButtonTryAgain")
        s.recoveryTitle = str("aiBuddyRecoveryTitle")
        s.recoveryDuration = str("aiBuddyRecoveryDuration")
        s.recoveryMinutes = str("aiBuddyRecoveryMinutes")
        s.recoveryHold = str("aiBuddyRecoveryHold")
        s.recoveryHolding = str("aiBuddyRecoveryHolding")
        s.recoveryHoldHelp = str("aiBuddyRecoveryHoldHelp")
        s.recoveryClose = str("aiBuddyRecoveryClose")
        s.annoyingPrompt = str("aiBuddyAnnoyingPrompt")
        s.annoyingYes = str("aiBuddyAnnoyingYes")
        s.offlineTitle = str("aiBuddyOfflineTitle")
        s.offlineExplanation = str("aiBuddyOfflineExplanation")
        s.unavailableTitle = str("aiBuddyUnavailableTitle")
        s.unavailableExplanation = str("aiBuddyUnavailableExplanation")
        s.startForMinutes = str("aiBuddyStartForMinutes")
        s.inputPlaceholder = str("aiBuddyInputPlaceholder")
        s.buttonSend = str("aiBuddyButtonSend")
        return s
    }
}

// MARK: - Live session state

/// Describes the accountability-buddy session currently running (nil when none). Set when an approved
/// goal starts a session and cleared when the focus session ends.
struct AccountabilityBuddySession {
    let goal: String
    let allowedApps: [String]
    let allowedUrls: [String]
    let durationMinutes: Int
    // True only for the LNM meeting flow (startMeetingFocusSession). Meeting sessions auto-end when the
    // user leaves the meeting (after a grace period); a postpone-buddy session must NOT.
    var isMeeting = false
}

/// The accountability-buddy session currently gating blocking, if any.
var currentAccountabilityBuddySession: AccountabilityBuddySession?

/// The AI accountability-buddy session that JUST completed, kept alive only across the completed screen
/// so its "Extend Session" button can re-activate the buddy (same goal + allow-list + strict AI
/// blocking) instead of extending the loose default focus mode the buddy ran under. Set when a buddy
/// session finishes with an extend offered; consumed by extendFocusMode(); reset to nil on every
/// subsequent finish (so a non-buddy session never inherits a stale buddy).
var lastCompletedAccountabilityBuddySession: AccountabilityBuddySession?

/// Set once the after-restart restore has reached a terminal outcome — attached, or given up because the
/// persisted session has expired or there was none. Until then the 1s focus loop keeps retrying, so the
/// restore isn't lost when it runs before the async focus-mode restore has set `isFocusModeRunning`.
/// Once true, the loop stops re-reading UserDefaults every tick.
var didAttemptAccountabilityBuddyRestore = false

/// Persist the running buddy session so it survives an app restart. The session state
/// (currentAccountabilityBuddySession + the currentRunningFocusType allow-list overrides) is in-memory
/// only, so without this a relaunch restores the focus timer but reverts to the default super-distracting
/// (non-AI) mode — the "AI blocking removed after restart" symptom.
func persistAccountabilityBuddySession(endTime: Date) {
    guard let session = currentAccountabilityBuddySession else { return }
    SensitiveDefaults.set([
        "goal": session.goal,
        "allowedApps": session.allowedApps,
        "allowedUrls": session.allowedUrls,
        "durationMinutes": session.durationMinutes,
        "endTime": endTime.timeIntervalSince1970,
        // Persist the session's strictness so a normal (non-strict) meeting session isn't resurrected as
        // super-strict after a restart. Read here right after startScopedAiFocusSession set it.
        "superStrict": currentFocusModeStrictness == ._SUPER_STRICT_,
        // Persist isMeeting so a restored meeting session still auto-ends when the meeting ends.
        "isMeeting": session.isMeeting,
    ] as [String: Any], forKey: kAccountabilityBuddySessionPersistKey)
}

func clearPersistedAccountabilityBuddySession() {
    SensitiveDefaults.removeObject(forKey: kAccountabilityBuddySessionPersistKey)
}

/// When the saved MEETING focus session ends, or nil when none is saved. The record is written when a
/// session starts and cleared when it finishes, so this is the live meeting session's end — and, at
/// launch, the end of one that was running when the app quit.
func persistedMeetingSessionEnd(defaults: UserDefaults = .standard) -> Date? {
    guard let dict = defaults.dictionary(forKey: kAccountabilityBuddySessionPersistKey),
          dict["isMeeting"] as? Bool == true,
          let endInterval = dict["endTime"] as? TimeInterval else { return nil }
    return Date(timeIntervalSince1970: endInterval)
}

/// Re-attach a persisted buddy session to the focus session restored after a restart, re-applying the
/// overrides `startAccountabilityBuddySession` sets so the AI URL/app check resumes against the original
/// goal for the session's remaining time. Driven by the 1s focus loop, on the main RunLoop.
///
/// Retried every tick until it reaches a terminal outcome, because the focus mode is restored
/// ASYNCHRONOUSLY (resumeFocusModeAfterAppStartted runs off the focus-modes API response) and sets
/// `isFocusModeRunning` last. This used to be one-shot AND cleared the persisted session whenever
/// `isFocusModeRunning` was merely not true YET, so a tick that beat the restore destroyed the session
/// permanently: the focus mode then came back with no AI allow-list (roughly a quarter of relaunches
/// during a session, in the logs). Give up on TIME — the session's own end — not on one unlucky tick.
func restoreAccountabilityBuddySessionIfNeeded() {
    guard currentAccountabilityBuddySession == nil else {
        didAttemptAccountabilityBuddyRestore = true
        return
    }
    guard let dict = SensitiveDefaults.dictionary(forKey: kAccountabilityBuddySessionPersistKey),
          let endInterval = dict["endTime"] as? TimeInterval else {
        didAttemptAccountabilityBuddyRestore = true   // nothing persisted; stop re-reading every tick
        return
    }
    let endTime = Date(timeIntervalSince1970: endInterval)
    // Past its own end → genuinely over. Drop it and stop retrying. (A session the user STOPPED is
    // already cleared by tryFocusModeFinished, so this only has to catch one that simply ran out.)
    guard endTime > Date() else {
        clearPersistedAccountabilityBuddySession()
        didAttemptAccountabilityBuddyRestore = true
        return
    }
    // No focus session to attach to yet. Keep the persisted session and try again next tick — the
    // restore may still be in flight. Bounded by the endTime check above.
    guard isFocusModeRunning else { return }
    // …but only re-attach to a session that is itself AUTO-started. A persisted buddy record can outlive
    // its session (the app killed before tryFocusModeFinished's clear was flushed), and the running
    // session might by then be one the USER started — re-attaching there would silently overwrite their
    // intention, allow-list and strictness with a finished meeting's. `focusModeStartted` clears the
    // marker on every start, so a user-started session can never match. Terminal: the marker won't change
    // for the life of this session.
    // The marker being ABSENT means this session predates it (first launch after the upgrade), where the
    // persisted buddy record is the only evidence we have — keep the old behaviour and attach.
    guard isFocusSessionAutoStarted || focusSessionAutoStartedMarkerIsAbsent() else {
        addLog(text: "accountability buddy: not restoring — the running focus session is user-started")
        clearPersistedAccountabilityBuddySession()
        didAttemptAccountabilityBuddyRestore = true
        return
    }

    let goal = dict["goal"] as? String ?? ""
    let allowedApps = dict["allowedApps"] as? [String] ?? []
    let allowedUrls = dict["allowedUrls"] as? [String] ?? []
    currentAccountabilityBuddySession = AccountabilityBuddySession(
        goal: goal, allowedApps: allowedApps, allowedUrls: allowedUrls,
        durationMinutes: dict["durationMinutes"] as? Int ?? 0,
        isMeeting: dict["isMeeting"] as? Bool ?? false)

    var running = currentRunningFocusType
    running["allowed_apps"] = allowedApps
    running["allowed_urls"] = allowedUrls
    running["isAllowedAllApps"] = false
    running["isAllowedListApproach"] = true
    running["isDefault"] = false
    if running["blockAppsArray"] == nil { running["blockAppsArray"] = [String]() }
    currentRunningFocusType = running

    whatToAchieveInFocusBlock = goal
    // Default true keeps the approved-postpone buddy super-strict for sessions persisted before this key
    // existed; a normal meeting session persists superStrict=false and restores as normal.
    let wasSuperStrict = dict["superStrict"] as? Bool ?? true
    currentFocusModeStrictness = wasSuperStrict ? ._SUPER_STRICT_ : ._NORMAL_
    // A restored buddy session is by definition auto-started. resumeFocusModeAfterAppStartted normally
    // restores this already; re-asserting it covers a session persisted by a build that predates the
    // marker, so its Stop/Pause bypass survives the NEXT relaunch too.
    setFocusSessionAutoStarted(true)
    didAttemptAccountabilityBuddyRestore = true
    addLog(text: "accountability buddy: restored \(wasSuperStrict ? "super-strict" : "normal") session after restart for goal \(LogPrivacy.text(goal))")
}

// MARK: - Context the buddy reasons over

/// Names + rough durations of the healthy habits the user still has to do today (morning + evening),
/// so the buddy can weigh them against the urgent thing (e.g. "meditate before emails", or scale one
/// back). Uses the same source + per-day completion logic as the Day Plan schedule.
/// The habits of the routine the user is ACTUALLY in — otherwise the buddy suggested evening habits
/// during a morning routine (and vice versa).
private func accountabilityBuddyRoutineHabits() -> [habit] {
    switch currentState {
    case ._EVENING_HABIT_, ._POSTPONE_EVENING_HABIT_, ._FOCUS_SUMMARY_, ._POSTPONE_FOCUS_SUMMARY_:
        return arrAllDaysEveningHabits
    default:
        return arrAllDaysMorningHabits
    }
}

/// How much of the current routine is done, 0...100, or nil when it has no habits today.
func accountabilityBuddyRoutineCompletionPercent() -> Int? {
    let source = accountabilityBuddyRoutineHabits()
    let now = Date()
    return AccountabilityDayContext.routineCompletionPercent(
        totalHabits: ScheduleTab.habitInputs(from: source, now: now, dropCompleted: false).count,
        remainingHabits: ScheduleTab.habitInputs(from: source, now: now, dropCompleted: true).count)
}

/// Minutes left before the user's shutdown time, or nil when they haven't set one.
func accountabilityBuddyMinutesLeftInDay() -> Int? {
    AccountabilityDayContext.minutesLeftInDay(now: Date(), shutOff: shutOffTime, isShutOffTime: isShutOffTimeGoing())
}

func accountabilityBuddyUncompletedHabits() -> [String] {
    let habits = ScheduleTab.habitInputs(from: accountabilityBuddyRoutineHabits(), now: Date(), dropCompleted: true)
        .map { "\($0.title) (~\(max(1, $0.durationSeconds / 60)) min)" }
    addLog(text: "accountability buddy: \(habits.count) uncompleted habits for state \(currentState)")
    return habits
}

/// Today's not-yet-done Day Plan tasks (title, project, estimated minutes) so the buddy can check
/// whether the user's stated task is already in their plan.
func accountabilityBuddyDayPlanTasks() -> [String] {
    return DayPlanTaskStore.shared.tasks(for: Date()).filter { !$0.done }.map { task in
        var line = task.title
        if let project = task.project, !project.isEmpty { line += " [#\(project)]" }
        return line + " (~\(task.durationMinutes) min)"
    }
}

/// The top incomplete Day Plan tasks for today, in the SAME order the user sees at the top of their Day
/// Plan panel (grouped by their project order, store order within). Used by the AI block screen to offer
/// the user their real top-of-plan tasks when a distraction is caught, and to judge "is this relevant to
/// my TOP task?". Deliberately matches the panel's display order rather than a separate importance re-sort
/// — the previous `outcome`-based sort diverged confusingly from the plan the user was looking at.
func topDayPlanTasks(limit: Int = 3) -> [DayPlanTask] {
    Array(DayPlanTaskStore.shared.incompleteTasksInDisplayOrder(for: Date()).prefix(limit))
}

// MARK: - Meeting awareness

/// Fallback label when the app's live meeting detection says the user is in a meeting but no matching
/// calendar event gives us a title.
private let kGenericMeetingTitle = "your meeting"

/// The title of the meeting happening RIGHT NOW, or nil when none. Reads two live signals: the app's
/// mic/browser meeting detection (`isUserOnMeeting`) and the calendar (a timed event whose range covers
/// now). Meant to be called at present-/evaluation-time — meeting state changes, so never cache it.
func currentMeetingTitleIfAny() -> String? {
    if let calendarTitle = currentCalendarMeetingTitle() { return calendarTitle }
    if appdelegate?.isUserOnMeeting == true { return kGenericMeetingTitle }
    return nil
}

/// Title of the calendar meeting covering `now` (start ≤ now ≤ end), stripped of the schedule's 📅
/// prefix. nil when calendar access is off or no meeting is current.
private func currentCalendarMeetingTitle() -> String? {
    let now = Date()
    guard let meeting = CalendarManager.shared.todaysMeetings()
        .first(where: { $0.start <= now && now <= $0.end }) else { return nil }
    let title = meeting.title.replacingOccurrences(of: "📅 ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    return title.isEmpty ? kGenericMeetingTitle : title
}

/// The user's meetings around NOW — anything just ended (last 15 min), happening now, or coming up over
/// the next few hours today — each as a "Title — when" line WITH the actual time and how far away it is,
/// so the buddy can answer "when is my meeting" itself instead of asking (or claiming it can't see the
/// calendar). A ±30-min window was too narrow: a meeting the user is prepping for is usually further out.
/// Empty only when calendar access is off or truly nothing is scheduled in that span.
/// Shapes the calendar lines for the request body.
///
/// The DTO bounds both the number of events and each line's length, and a busy or shared calendar
/// can exceed either. Trimming here means a crowded day degrades to the nearest events rather than
/// 400ing the whole request — which would put the buddy back to arguing without a calendar, the very
/// thing this fixes.
enum AccountabilityCalendarPayload {
    /// The DTO's own outer bounds (`MAX_CALENDAR_EVENTS_INPUT`, `MAX_CALENDAR_EVENT_LENGTH_INPUT`),
    /// which are what a request gets 400'd for exceeding — not the tighter limits the service then
    /// truncates to. Matching the outer bounds rather than guessing something smaller means nothing
    /// is dropped here that the server would have been happy to receive and curate itself.
    ///
    /// In practice the window is about six hours, so neither is reached; these exist so a shared or
    /// agenda-stuffed calendar degrades instead of failing the request, which would put the buddy
    /// back to arguing with no calendar at all.
    static let maximumEvents = 500
    static let maximumLineLength = 2000

    static func forRequest(_ events: [String]) -> [String] {
        events
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(maximumEvents)
            .map { String($0.prefix(maximumLineLength)) }
    }
}

func accountabilityBuddyCalendarContext() -> [String] {
    let now = Date()
    let windowStart = now.addingTimeInterval(-15 * 60)
    let windowEnd = now.addingTimeInterval(6 * 60 * 60)   // recent + the rest of the near-term day
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let all = CalendarManager.shared.todaysMeetings()
    let lines = all
        .filter { $0.end > windowStart && $0.start < windowEnd }
        .sorted { $0.start < $1.start }
        .prefix(6)
        .map { event -> String in
            let title = event.title.replacingOccurrences(of: "📅 ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let name = title.isEmpty ? kGenericMeetingTitle : title
            let when: String
            if event.start <= now && now <= event.end {
                when = "happening now until \(formatter.string(from: event.end))"
            } else if event.start > now {
                let mins = max(0, Int(event.start.timeIntervalSince(now) / 60))
                when = "at \(formatter.string(from: event.start)) (in \(mins) min)"
            } else {
                when = "ended at \(formatter.string(from: event.end))"
            }
            return "\(name) — \(when)"
        }
    addLog(text: "accountability buddy: \(all.count) todaysMeetings, \(lines.count) in calendar context")
    return Array(lines)
}

// MARK: - LLM evaluation

extension AllApi {
    /// Evaluate the accountability conversation and return a fresh verdict. `messages` is the chat so
    /// far — the user's stated reason and any follow-up arguments, plus the buddy's prior replies — so
    /// the user can try to convince the buddy across turns. Judged SERVER-SIDE (the prompt + long-term
    /// goals/habits/day-plan/calendar reasoning lives on the backend) via the authenticated
    /// `/user/evaluate-focus-postponement` endpoint, so no OpenAI key touches the client. The endpoint
    /// returns `{ verdict, intention, clampedDurationMinutes, allowedApps, allowedUrls, reason }`, mapped
    /// onto the existing `AccountabilityVerdict` so callers are unaffected.
    func evaluateAccountabilityConversation(messages: [(role: String, text: String)],
                                            longTermGoals: [String],
                                            uncompletedHabits: [String] = [],
                                            dayPlanTasks: [String] = [],
                                            dayPlanTaskCandidates: [AccountabilityTaskCandidate] = [],
                                            calendarEvents: [String] = [],
                                            isInMeeting: Bool = false,
                                            routineCompletionPercent: Int? = nil,
                                            minutesLeftInDay: Int? = nil,
                                            completion: @escaping (Result<AccountabilityVerdict, Error>) -> Void) {
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil else {
                let err = NSError(domain: "AccountabilityBuddy", code: 1, userInfo: [NSLocalizedDescriptionKey:
                    "You need to be signed in to Focus Bear to use the accountability buddy."])
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            let responsePath = "\(baseUrl)/user/evaluate-focus-postponement"
            guard let responsePathUrl = NSURL(string: responsePath) else {
                let err = NSError(domain: "AccountabilityBuddy", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: "Couldn't reach the accountability buddy"])
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            addLog(text: "api call evaluateAccountabilityConversation \(responsePathUrl)")

            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            // Field names + shape match the backend EvaluateFocusPostponementDto EXACTLY — camelCase,
            // uncompletedHabits/dayPlanTasks required, optional currentMeetingTitle, calendarEvents
            // and language.
            //
            // `calendarEvents` USED to be dropped here, under a comment saying the endpoint did not
            // accept it. It does, and has for a while: the DTO declares it and the prompt interpolates
            // it with an explicit instruction — "when the calendar events list is non-empty, you can
            // see the calendar, never claim you cannot". The client computed the list, logged it, and
            // then left it out of the body, so the buddy answered "I can see your calendar is not
            // provided here, so I can't verify the meeting" about a meeting ten minutes away and
            // plainly on the calendar (report 2026-09-23_09-25-08).
            //
            // `longTermGoals` and `isInMeeting` genuinely are not in the DTO and are still not sent.
            // They stay as parameters because callers supply them and the server may take them later.
            let language = BundledConfigLanguage.apiName().capitalized
            let apiMessages = messages.map { ["role": $0.role, "content": AccountabilityRequestText.bounded($0.text, limit: 500)] }

            var json: [String: Any] = [
                "messages": apiMessages,
                "uncompletedHabits": AccountabilityRequestText.context(uncompletedHabits),
                "dayPlanTasks": AccountabilityRequestText.context(dayPlanTasks),
                "dayPlanTaskCandidates": dayPlanTaskCandidates.map(\.apiValue),
                "language": language,
            ]
            if let meetingTitle = currentMeetingTitleIfAny() {
                json["currentMeetingTitle"] = AccountabilityRequestText.bounded(meetingTitle, limit: 500)
            }
            // Only when there is something to say: the prompt reads an EMPTY list as "the client did
            // not send any", which is a different claim from "the calendar is empty" and is the one
            // it is told not to hold against the user.
            let calendar = AccountabilityCalendarPayload.forRequest(calendarEvents)
            if !calendar.isEmpty {
                json["calendarEvents"] = calendar
            }
            // Optional, so a server that predates them ignores them. Sent only when known: "no habits
            // today" and "no shutdown time set" must not read as "0% done" or "no time left".
            if let percent = routineCompletionPercent {
                json["routineCompletionPercent"] = percent
            }
            if let minutes = minutesLeftInDay {
                json["minutesLeftInDay"] = minutes
            }
            addLog(text: "evaluateAccountabilityConversation: json data for api is:- \(json)")
            request.httpBody = try? JSONSerialization.data(withJSONObject: json)

            URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error = error {
                    addLog(text: "api call evaluateAccountabilityConversation error:- \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard let data = data,
                      (200...299).contains(statusCode),
                      let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    if let data = data { self.writeJsonInLog(data: data) }
                    addLog(text: "api call evaluateAccountabilityConversation error:- statusCode is \(statusCode)")
                    let err = NSError(domain: "AccountabilityBuddy", code: statusCode, userInfo: [NSLocalizedDescriptionKey:
                        "Couldn't understand the accountability buddy's response"])
                    DispatchQueue.main.async { completion(.failure(err)) }
                    return
                }
                let verdict = AccountabilityVerdict(
                    approved: (jsonResult["verdict"] as? String)?.lowercased() == "approve",
                    message: jsonResult["reason"] as? String ?? "",
                    intention: jsonResult["intention"] as? String,
                    allowedApps: jsonResult["allowedApps"] as? [String] ?? [],
                    allowedUrls: jsonResult["allowedUrls"] as? [String] ?? [],
                    durationMinutes: jsonResult["clampedDurationMinutes"] as? Int ?? 0,
                    selectedTaskIds: jsonResult["selectedTaskIds"] as? [String])
                DispatchQueue.main.async { completion(.success(verdict)) }
            }.resume()
        }
    }
}

// MARK: - Task/intention alignment check

/// Field caps matching the backend `TaskIntentionCheckDto` (`MAX_WORD_LENGTH.intention` and
/// `.default`), so an over-long answer is trimmed here instead of 400ing the whole check.
private let kTaskIntentionMaxIntentionLength = 500
private let kTaskIntentionMaxTaskNameLength = 200

/// Transport timeout for the alignment check. Short on purpose: the user is sitting in front of a
/// modal sheet waiting for it, and the answer is only ever advisory.
private let kTaskIntentionCheckTimeout: TimeInterval = 8

/// The server's verdict on whether a stated task supports the session's focus intention
/// (`POST /user/task-intention-check`, backend#2344).
struct TaskIntentionAlignment: Equatable {
    /// Deliberately LENIENT: the server answers `false` only for a clear conflict, so a `false` here
    /// is worth showing the user.
    let aligns: Bool
    /// One short, kind sentence naming both the intention and the task, already localised to the
    /// user's language by the server. May be empty.
    let reason: String

    /// The verdict to use whenever the server can't be reached or understood. The check FAILS OPEN —
    /// the same rule the endpoint itself follows — because a user who is offline must never be
    /// stopped from extending their own focus session.
    static let failOpen = TaskIntentionAlignment(aligns: true, reason: "")
}

/// Why an alignment check couldn't produce an answer. Never shown to the user: every case is treated
/// as `TaskIntentionAlignment.failOpen`; the cases exist so the debug log says which one happened.
enum TaskIntentionCheckError: Error {
    case notSignedIn
    case malformedUrl
    case badResponse(statusCode: Int)
}

/// The one thing the extend-reason flow needs from the network, so the decision around it can be
/// tested without a server (see `FocusSessionExtension.checkExtensionReason`).
protocol TaskIntentionChecking {
    /// - Note: implementations must deliver `completion` on the main queue.
    func checkTaskIntentionAlignment(intention: String,
                                     taskName: String,
                                     focusMode: String?,
                                     completion: @escaping (Result<TaskIntentionAlignment, Error>) -> Void)
}

extension AllApi: TaskIntentionChecking {

    /// Ask the server whether `taskName` supports `intention`. Judged SERVER-SIDE (Gemini, via the
    /// authenticated `/user/task-intention-check` endpoint), so no AI key touches the client.
    func checkTaskIntentionAlignment(intention: String,
                                     taskName: String,
                                     focusMode: String?,
                                     completion: @escaping (Result<TaskIntentionAlignment, Error>) -> Void) {
        func fail(_ error: Error) {
            addLog(text: "api call checkTaskIntentionAlignment error:- \(error)")
            DispatchQueue.main.async { completion(.failure(error)) }
        }

        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil else {
                fail(TaskIntentionCheckError.notSignedIn)
                return
            }
            guard let responsePathUrl = NSURL(string: "\(baseUrl)/user/task-intention-check") else {
                fail(TaskIntentionCheckError.malformedUrl)
                return
            }
            addLog(text: "api call checkTaskIntentionAlignment \(responsePathUrl)")

            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = kTaskIntentionCheckTimeout

            // snake_case field names match the backend TaskIntentionCheckDto exactly.
            var json: [String: Any] = [
                "intention": AccountabilityRequestText.bounded(intention, limit: kTaskIntentionMaxIntentionLength),
                "task_name": AccountabilityRequestText.bounded(taskName, limit: kTaskIntentionMaxTaskNameLength),
            ]
            let trimmedFocusMode = (focusMode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedFocusMode.isEmpty {
                json["focus_mode"] = AccountabilityRequestText.bounded(trimmedFocusMode,
                                                                       limit: kTaskIntentionMaxTaskNameLength)
            }
            request.httpBody = try? JSONSerialization.data(withJSONObject: json)

            URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error = error {
                    fail(error)
                    return
                }
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard let data = data,
                      (200...299).contains(statusCode),
                      let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let aligns = jsonResult["aligns"] as? Bool else {
                    fail(TaskIntentionCheckError.badResponse(statusCode: statusCode))
                    return
                }
                let alignment = TaskIntentionAlignment(aligns: aligns,
                                                       reason: jsonResult["reason"] as? String ?? "")
                addLog(text: "checkTaskIntentionAlignment: aligns=\(alignment.aligns)")
                DispatchQueue.main.async { completion(.success(alignment)) }
            }.resume()
        }
    }
}

// MARK: - Block-relevance argument (argue with the AI)

/// Clamp for how long the argue→allow flow may unblock an app/site before re-checking in. The USER's
/// chosen minutes always wins; these just bound both the AI's suggestion and the user's picker.
let kAiBlockMinAllowMinutes = 1
let kAiBlockMaxAllowMinutes = 120
let kAiBlockDefaultAllowMinutes = 15

/// The structured decision the LLM returns when the user argues that a blocked app/site IS relevant to
/// their top Day Plan task. Deliberately minimal — this is a relevance re-judgement, not a session grant.
struct AiRelevanceVerdict: Codable {
    /// Whether the app/site genuinely helps the user do their top Day Plan task right now.
    let relevant: Bool
    /// One or two sentences shown to the user explaining the decision (kind but firm).
    let message: String
    /// The AI's optional suggestion for how many minutes to allow it for. Only a hint — the user's
    /// chosen minutes wins. Optional so older/short responses without it still decode.
    let suggestedDurationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case relevant, message
        case suggestedDurationMinutes = "suggested_duration_minutes"
    }

    /// The AI's suggestion clamped to the allowed range, or nil when it didn't propose one — the caller
    /// falls back to `kAiBlockDefaultAllowMinutes` for the picker's initial value.
    var clampedSuggestedMinutes: Int? {
        guard let requested = suggestedDurationMinutes, requested > 0 else { return nil }
        return min(kAiBlockMaxAllowMinutes, max(kAiBlockMinAllowMinutes, requested))
    }
}

extension AllApi {
    /// Re-judge whether the blocked `item` (an app name or a website/URL) is relevant to the user's
    /// `currentTask` (their live focus intention — what they deliberately chose to work on right now),
    /// falling back to `topTask` when no current intention is set, given the back-and-forth `messages`
    /// where the user argues their case. Runs SERVER-SIDE through the existing authenticated safety
    /// endpoints — `/user/is-url-safe-to-use` for a website, `/user/is-app-safe-to-use` for an app —
    /// reusing `chatGPTIsURLSafe`/`chatGPTIsAppSafe`, so no OpenAI key touches the client. The user's argue
    /// turns are passed as `lastFiveJustificationsInThisFocusSession` (the field these endpoints already
    /// weigh), and `currentTask` flows through as `currentTaskInToDoPlayer` so the human's current-task
    /// relevance keeps working. The endpoints return `allowed_probability` (0..1) + `reason`, mapped onto
    /// `AiRelevanceVerdict` (probability ≥ 0.5 ⇒ relevant) so `AiBlockBuddyScreen` callers are unaffected.
    /// `dayPlanTasks` is unused here — the server derives the wider plan from `current_tasks`.
    func evaluateBlockRelevanceConversation(item: String,
                                            topTask: String,
                                            currentTask: String = "",
                                            intention: String = "",
                                            windowTitle: String = "",
                                            isApp: Bool,
                                            messages: [(role: String, text: String)],
                                            dayPlanTasks: [String] = [],
                                            completion: @escaping (Result<AiRelevanceVerdict, Error>) -> Void) {
        let currentTaskTrimmed = currentTask.trimmingCharacters(in: .whitespacesAndNewlines)
        // Judge against the current task (what the user chose to work on) when set, else the SMART top task.
        let referenceTask = currentTaskTrimmed.isEmpty ? topTask : currentTaskTrimmed
        // The session GOAL is its own field on these endpoints, distinct from the current task — sending the
        // task as the "intention" hid the goal from the AI (and made a task switch look like a goal change).
        // Fall back to the reference task only when the session has no stated goal.
        let intentionTrimmed = intention.trimmingCharacters(in: .whitespacesAndNewlines)
        let intentionForApi = intentionTrimmed.isEmpty ? referenceTask : intentionTrimmed
        // The user's argue turns are exactly the "justifications" these endpoints already reason over.
        let justifications = messages.filter { $0.role == "user" }.map { $0.text }
        let currentTaskForApi: String? = currentTaskTrimmed.isEmpty ? nil : currentTaskTrimmed
        let focusModeName = currentRunningFocusType["name"] as? String ?? ""

        // Map the safety endpoint's dictionary response onto AiRelevanceVerdict. `allowed_probability`
        // ≥ 0.5 is the same threshold the focus loop uses to allow a gray-area site/app. These endpoints
        // don't return a suggested duration, so the picker falls back to `kAiBlockDefaultAllowMinutes`.
        let handle: (NSDictionary?, String?, [String: Any]?) -> Void = { dic, _, _ in
            guard let dic = dic, let probability = dic.value(forKey: "allowed_probability") as? Double else {
                let err = NSError(domain: "AiBlockBuddy", code: 0,
                                  userInfo: [NSLocalizedDescriptionKey: "Couldn't understand the AI response"])
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            let reason = dic.value(forKey: "reason") as? String ?? ""
            let verdict = AiRelevanceVerdict(relevant: probability >= 0.5, message: reason,
                                             suggestedDurationMinutes: nil)
            DispatchQueue.main.async { completion(.success(verdict)) }
        }

        let titleTrimmed = windowTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if isApp {
            // is-app-safe doesn't take an app window title yet (backend coord t86). Until it does, surface
            // the app's focused-window title (e.g. iTerm's "literature-search") as leading context in the
            // justifications the endpoint already weighs, so the AI judges what the app is actually showing
            // instead of the bare app name ("iTerm").
            let appJustifications = titleTrimmed.isEmpty
                ? justifications
                : ["The \(item) window is currently titled: \"\(titleTrimmed)\""] + justifications
            chatGPTIsAppSafe(appName: item, focus_mode: focusModeName, intention: intentionForApi,
                             other_explanations_including_apps: appJustifications,
                             currentTaskInToDoPlayer: currentTaskForApi, currentHabitName: nil,
                             completionHandler: handle)
        } else {
            // is-url-safe already weighs the tab title; the argue re-judge was sending it empty. Pass the
            // page title so the AI has the same context the initial block check had.
            chatGPTIsURLSafe(url: item, tab_title: titleTrimmed, focus_mode: focusModeName,
                             intention: intentionForApi, currentTaskInToDoPlayer: currentTaskForApi,
                             currentHabitName: nil, other_explanations_including_domains: justifications,
                             completionHandler: handle)
        }
    }
}

// MARK: - Task-title guess (save what I'm doing)

extension AllApi {
    /// Guess a short, actionable Day Plan task title from the app/site the user was on when blocked, so
    /// "Save what I'm doing as a task" can prefill something meaningful instead of the raw URL.
    ///
    /// There is NO backend endpoint for a standalone page→title guess: per #2310 the safety endpoints'
    /// `suggested_task` is a "switch to this EXISTING to-do" pointer, not a fresh title for the current
    /// page, so it can't stand in here. The old client-side OpenAI call was removed for security. Until a
    /// backend title endpoint ships this degrades gracefully — it returns nil, so the caller falls back to
    /// `fallbackTitle()` (the caught page's title, else the domain/app name) and the feature still works,
    /// just without an AI-tidied title. NEEDS A BACKEND ENDPOINT (see report / /coord).
    func suggestTaskTitleForBlockedItem(appName: String, url: String, pageTitle: String,
                                        completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async { completion(nil) }
    }
}

// MARK: - Session orchestration

/// Start a super-strict focus session for an approved goal, allowing only the sanctioned apps + URLs.
///
/// Reuses the tested `startFocusFromMenu` start path (timers, DND, Focus Button, `focusModeStartted`),
/// then overrides the RUNNING focus mode's allow-lists in memory. `currentRunningFocusType` is a
/// value-type copy the blocking loops read each tick, so overriding it scopes the allow-list to this
/// session and never mutates the user's saved focus modes.
///
/// Known POC limitation: a server focus-mode update can call `reSetCurrentFocusMode` and reset the
/// running copy from `arrFocusType`, dropping the override mid-session. Acceptable for the POC; the
/// production version should carry the allow-list in a dedicated session-scoped store the blocking
/// loops consult directly.
@MainActor
/// `minutes` is the duration the postpone was actually granted (the verdict's, clamped to the user's
/// cutoff), NOT the raw verdict duration — report 2026-09-17_17-05-10 had the buddy start a session
/// "until 05:10 pm" against a 17:00 cutoff, so the session outlived the routine it was covering for.
func startAccountabilityBuddySession(verdict: AccountabilityVerdict, goal: String, minutes: Int,
                                     taskCandidates: [AccountabilityTaskCandidate] = []) {
    // Prefer the AI's tidy, concrete intention for the on-screen focus intention; the user's raw
    // message is only a fallback if the model didn't supply one.
    let aiIntention = verdict.intention?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let intention = aiIntention.isEmpty ? goal : aiIntention
    // A server without task selection starts an empty queue; it must never revive a previous
    // session's saved tasks. Once supported, only the validated selected IDs populate this queue.
    let queue = AccountabilityTaskSelection.queue(selectedIDs: verdict.selectedTaskIds, offered: taskCandidates,
                                                   currentTasks: DayPlanTaskStore.shared.tasks(for: Date()))
    startScopedAiFocusSession(goal: intention, minutes: minutes,
                              allowedApps: verdict.allowedApps, allowedUrls: verdict.allowedUrls,
                              event: "accountability-buddy-session-started", initialTasks: queue)
}

/// True when a Late-No-More meeting starts while a routine is actually in progress (so the meeting
/// postpones it) or one is already in a recoverable postpone — the cases where the meeting has a routine
/// to protect and should run SUPER-STRICT. False only when the routine is done/idle (`._NOTHING_` with no
/// live postpone): a meeting that starts over already-finished habits has nothing to protect, so it runs
/// as a normal focus session. For a morning/evening postpone this also lines up with Stop→habits: the
/// same recoverable-postpone state `routinePostponeStateToReCoverOnExtend()` reports is what lets Stop
/// hand the user back to the habits the meeting postponed.
///
/// Timing note: at the `event-about-to-start` call site the routine hasn't been postponed yet (the
/// appointment popup does that on confirm), so `currentState` is still the running routine state — hence
/// the running-state check covers the states that popup postpones. At the popup fallback call site the
/// postpone has already happened, so `routinePostponeStateToReCoverOnExtend()` reports it.
@MainActor
func meetingIsProtectingARoutine() -> Bool {
    // Only an INCOMPLETE routine (habits still to do) is worth protecting with a super-strict,
    // password-gated meeting session. Count ONLY the unambiguous "actively in a routine habit" states +
    // postpone states. NOT _MICRO_BREAK_ / _SPECIAL_ACTIVITY_: those are the periodic WORK breaks/activities
    // that fire after the routine is already done, so a meeting starting during a work micro-break was
    // wrongly locked super-strict (user completed their morning routine, was on a work break). NOT
    // _FOCUS_SUMMARY_ / _POSTPONE_FOCUS_SUMMARY_ either (routine already done). Repeated reports of meetings
    // locking after habits were finished traced back to these states.
    switch currentState {
    case ._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_,
         ._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_:
        return true
    case ._NOTHING_:
        // A very-recent postpone of an INCOMPLETE habit still counts (Stop should hand the user back
        // to it); a postponed summary does not (nothing left to do).
        let recovered = routinePostponeStateToReCoverOnExtend()
        return recovered == ._POSTPONE_MORNING_HABIT_ || recovered == ._POSTPONE_EVENING_HABIT_
    default:
        return false
    }
}

/// Late No More: when a meeting starts (the user attends), run an AI session for the meeting's duration
/// with the meeting TITLE as the intention. It runs AS the app's **Meeting** focus mode (its allow-list —
/// Teams/Zoom/Slack/browsers + meet.google/webex/… — so meeting apps and sites are allowed without an AI
/// popup); gray-area apps/sites still reach the AI relevance check against the meeting title. It's
/// SUPER-STRICT only when it postpones a running routine (so Stop hands the user back to their habits, like
/// the postpone flow); when the routine is already done/idle it runs as a normal focus session.
@MainActor
func startMeetingFocusSession(title: String, durationMinutes: Int, wasRoutineAlreadyPostponed: Bool? = nil) {
    // Dedupe: never stack a second meeting session on top of a live one. The event-about-to-start
    // handler, the popup "attend" fallback, and rapid handleMeetingDetected re-fires can each try to
    // start a meeting session, so an already-live meeting session must short-circuit here — otherwise a
    // single meeting spawns overlapping sessions, each recording its own "Meetings" focus block. A
    // resumed meeting is handled by cancelling the auto-end grace (handleMeetingDetected), not a restart.
    if currentAccountabilityBuddySession?.isMeeting == true ||
        (meetingFocusHandoff.generation != nil && !isFocusModeOn() && !isFocusModePaused()) {
        addLog(text: "startMeetingFocusSession: a meeting focus session is already live — not starting another")
        return
    }
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let goal = trimmed.isEmpty ? "your meeting" : "attend and stay focused in your meeting: \(trimmed)"
    let minutes = min(max(durationMinutes, 1), 240)   // clamp to a sane meeting length
    let protectingRoutine = meetingIsProtectingARoutine()
    // Run as the Meeting focus mode so meeting apps/sites are pre-approved. Falls back to the default mode
    // (empty id, empty allow-list = AI decides everything) if the Meetings mode isn't present.
    let meetingMode = arrFocusType.first { ($0["isMeetings"] as? Bool) == true }
    let meetingModeId = meetingMode?["id"] as? String ?? ""
    let meetingApps = meetingMode?["allowed_apps"] as? [String] ?? []
    let meetingUrls = meetingMode?["allowed_urls"] as? [String] ?? []
    addLog(text: "startMeetingFocusSession: state=\(currentState) protectingRoutine=\(protectingRoutine) meetingModeFound=\(meetingMode != nil) → \(protectingRoutine ? "super-strict" : "normal")")
    guard !teacherSessionManagerObject.isTeacherSessionActive() else { return }
    let startMeeting = {
        startScopedAiFocusSession(goal: goal, minutes: minutes, allowedApps: meetingApps, allowedUrls: meetingUrls,
                                  event: "meeting-ai-focus-session-started",
                                  superStrict: protectingRoutine, focusModeId: meetingModeId, isMeeting: true,
                                  wasRoutineAlreadyPostponed: wasRoutineAlreadyPostponed)
    }
    if let generation = suspendFocusForMeeting(), let delegate = appdelegate {
        let transportSegment = MeetingFocusTransport.Segment()
        let identity = FocusLifecycleIdentity.shared.capture()
        scheduleMeetingFocusHandoff(finish: { finishSegmentForMeetingHandoff(delegate, next: transportSegment) },
            currentState: { currentState },
            enqueue: { DispatchQueue.main.async(execute: $0) },
            cancelled: { meetingFocusHandoff.cancel(ifCurrent: generation) }) {
                guard identity.isCurrent, !teacherSessionManagerObject.isTeacherSessionActive(),
                      meetingFocusHandoff.beginStart(generation) else {
                    meetingFocusHandoff.cancel(ifCurrent: generation)
                    return
                }
                defer { meetingFocusHandoff.endStart() }
                MeetingFocusTransport.shared.start(transportSegment, action: startMeeting)
            }
    } else {
        startMeeting()
    }
}

/// Core that starts a scoped AI focus session: the in-session relevance check judges every gray-area
/// app/site against `goal` (whatToAchieveInFocusBlock). Shared by the accountability buddy (approved
/// postpone) and the Late-No-More meeting flow. `allowedApps`/`allowedUrls` are pre-approved
/// (empty ⇒ the AI decides everything against the goal). `superStrict` (default true, for the approved-
/// postpone buddy) gates SUPER-STRICT: the meeting flow passes false when no routine is being postponed,
/// so a meeting that starts while habits are already done is a normal (password-free) focus session.
@MainActor
func startScopedAiFocusSession(goal: String, minutes: Int, allowedApps: [String], allowedUrls: [String], event: String, superStrict: Bool = true, focusModeId: String = "", isMeeting: Bool = false, initialTasks: [FocusSessionTask]? = nil, wasRoutineAlreadyPostponed: Bool? = nil) {
    guard let appDelegate = appdelegate else { return }

    let stopResumesRoutine = RoutineResume.sessionStopResumesRoutine(
        isMeeting: isMeeting, wasAlreadyPostponed: wasRoutineAlreadyPostponed ?? currentState.isRoutinePostponed)
    currentAccountabilityBuddySession = AccountabilityBuddySession(
        goal: goal, allowedApps: allowedApps, allowedUrls: allowedUrls, durationMinutes: minutes, isMeeting: isMeeting)

    // Clear any focus mode that's already on/paused BEFORE starting this one, so exactly one entry is
    // ever `isOn`. Otherwise a second `isOn` mode (e.g. a normal session, or a prior scoped session
    // that started over a running one) survived this session's end — `tryFocusModeFinished` only clears
    // the first `isOn` and stops — leaving the menu stuck on "Stop Focus Session" and blocking a new
    // session, and making the completed screen concatenate both sessions' intentions.
    for i in 0..<arrFocusType.count {
        arrFocusType[i]["isOn"] = false
        arrFocusType[i]["isPaused"] = false
    }

    // Stamp THIS session's real start time. The focus-block row written on finish (tryFocusModeFinished)
    // records `startFocusModeTime` as the block's start — but startFocusFromMenu never updates that global,
    // so without this a scoped/meeting session inherits a stale value from a previously-started focus mode.
    // A meeting that started+ended the next morning was logged against the PRIOR evening's start, so the
    // focus summary computed an impossible overnight wall-clock duration (13–15h) for a ~10-minute meeting.
    startFocusModeTime = Date()

    // Start the session on the given focus mode (empty id → the app's default focus mode), then tighten it.
    // The meeting flow passes the Meeting mode's id so the session runs AS the Meetings focus mode.
    appDelegate.startFocusFromMenu(focusModeId: focusModeId, minutes: minutes, intention: goal,
                                   isAutoStarted: true,
                                   initialTaskQueue: initialTasks.map(FocusSessionTaskQueue.encode))

    // startFocusFromMenu force-disables breaks (isSkipBreakActivityDuringPomodoro = true). This session is
    // AUTO-started (a meeting, or an approved postpone) — the user didn't opt into skipping breaks and was
    // surprised they silently turned off. Honour their saved skip-breaks-during-focus preference instead of
    // forcing breaks off for the whole meeting.
    isSkipBreakActivityDuringPomodoro = SettingsManagerObject.isSkipBreakActivityDuringPomodoro

    if let session = currentAccountabilityBuddySession {
        applyAccountabilityBuddyBlockingContext(session)
    }

    // The goal is the relevance target the AI URL check judges gray-area sites against.
    whatToAchieveInFocusBlock = goal
    // Super-strict is what password-gates Stop and locks the focus goal — appropriate only when a routine
    // is being protected/postponed. When it isn't (a meeting starting over already-done habits), fall back
    // to normal strictness so the user can just end the session, and set it explicitly rather than trust
    // whatever strictness was left over from a previous session.
    currentFocusModeStrictness = superStrict ? ._SUPER_STRICT_ : ._NORMAL_
    // Mark the session AUTO-started (and persist it) so Stop and Pause skip the password gate for the
    // session's whole life — including after a relaunch, where the strictness above IS restored from
    // UserDefaults but the buddy globals are not, which is what left a resumed meeting session
    // super-strict and impossible to stop. Set AFTER startFocusFromMenu, whose focusModeStartted()
    // resets the marker for every start.
    setFocusSessionAutoStarted(true)
    // An approved postpone session owns its routine return. A meeting that borrows an existing
    // postpone must leave that independent timer running when stopped.
    isFocusSessionStartedFromPostponeIntention = stopResumesRoutine

    // Persist so the session (and its AI overrides) survives an app restart for its remaining time.
    persistAccountabilityBuddySession(endTime: Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) ?? Date())
    didAttemptAccountabilityBuddyRestore = true   // already live; no restore needed this launch

    allApiObject.capturePosthog(event: event, metadata: ["duration_minutes": "\(minutes)",
                                                          "allowed_apps": "\(allowedApps.count)",
                                                          "allowed_urls": "\(allowedUrls.count)"])
    addLog(text: "\(event): started \(superStrict ? "super-strict" : "normal") session for goal \(LogPrivacy.text(goal)) (\(minutes)m)")
}

/// Scoped buddy allowances override the current block-list snapshot only for that buddy session.
private func applyAccountabilityBuddyBlockingContext(_ session: AccountabilityBuddySession) {
    var running = currentRunningFocusType
    running[FocusModeKey.allowedApps] = session.allowedApps
    running[FocusModeKey.allowedUrls] = session.allowedUrls
    running[FocusModeDictionaryKey.isAllowedAllApps] = false
    running[FocusModeKey.isAllowedListApproach] = true
    running[FocusModeKey.isDefault] = false
    if running[FocusModeKey.blockAppsArray] == nil { running[FocusModeKey.blockAppsArray] = [String]() }
    currentRunningFocusType = running
}

// MARK: - Focus interrupted by an LNM meeting

/// A generation prevents an enqueued handoff from resurrecting work after another session starts.
struct MeetingFocusHandoff<Snapshot> {
    private(set) var snapshot: Snapshot?
    private(set) var generation: UUID?
    private(set) var isStartingHandoff = false

    mutating func suspend(_ snapshot: Snapshot) -> UUID {
        let generation = UUID()
        self.snapshot = snapshot
        self.generation = generation
        return generation
    }

    mutating func sessionStarted() {
        if !isStartingHandoff { cancel() }
    }

    mutating func beginStart(_ generation: UUID) -> Bool {
        guard self.generation == generation else { return false }
        isStartingHandoff = true
        return true
    }

    mutating func endStart() { isStartingHandoff = false }

    mutating func consume() -> (Snapshot, UUID)? {
        guard let snapshot, let generation else { return nil }
        self.snapshot = nil
        return (snapshot, generation)
    }

    mutating func cancel(ifCurrent generation: UUID) {
        if self.generation == generation { cancel() }
    }

    mutating func cancel() {
        snapshot = nil
        generation = nil
        isStartingHandoff = false
    }
}

/// Snapshot state after synchronous finish cleanup, then yield behind its queued UI cleanup.
/// Injected scheduling keeps ordering/routine-change regressions testable without launching sessions.
func scheduleMeetingFocusHandoff<State: Equatable>(finish: () -> Void,
    currentState: @escaping () -> State,
    enqueue: (@escaping () -> Void) -> Void,
    cancelled: @escaping () -> Void,
    start: @escaping () -> Void) {
    finish()
    let finishedState = currentState()
    enqueue {
        guard currentState() == finishedState else {
            cancelled()
            return
        }
        start()
    }
}

@MainActor
private func finishSegmentForMeetingHandoff(_ delegate: AppDelegate, next: MeetingFocusTransport.Segment) {
    MeetingFocusTransport.shared.finishPredecessor(of: next) {
        delegate.tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false,
            allowExtend: false, isCustomRoutineTime: false, shouldUpdateFocusButton: true)
    }
}

enum MeetingFocusResumeTiming {
    static let SECONDS_PER_MINUTE = 60

    static func storedStrictness(_ strictness: FOCUSMODESTRICTNESS) -> Int {
        switch strictness {
        case ._NORMAL_: return FocusStartStrictness.junior.storedValue
        case ._STRICT_: return FocusStartStrictness.captain.storedValue
        case ._SUPER_STRICT_: return FocusStartStrictness.pawfessor.storedValue
        }
    }

    static func remainingSeconds(end: Date?, pausedSeconds: Int?, now: Date) -> Int? {
        if let pausedSeconds { return pausedSeconds > 0 ? pausedSeconds : nil }
        guard let end else { return nil }
        let seconds = end.timeIntervalSince(now)
        guard seconds.isFinite, seconds > 0, seconds < Double(Int.max) else { return nil }
        return Int(seconds.rounded(.up))
    }
}

private struct InterruptedMeetingFocus {
    let identity: FocusLifecycleIdentity.Snapshot
    let modeId: String
    let remainingSeconds: Int
    let intention: String
    let taskQueue: String
    let strictness: FOCUSMODESTRICTNESS
    let wasPaused: Bool
    let wasAutoStarted: Bool
    let wasStartedFromPostpone: Bool
    let wasHardcore: Bool
    let skipPomodoroBreaks: Bool
    let skipFocusBreaks: Bool
    let buddySession: AccountabilityBuddySession?
    let temporaryApps: [NSRunningApplication]
    let temporaryURLs: [String]
    let temporaryTabTitles: [String]
    let temporaryURLIntentions: [String: [String: Any]]
    let convincedURLs: [[String: String]]
    let convincedApps: [[String: String]]
}

// Intentionally process-local: after a relaunch only the active meeting resumes via the existing
// persistence path. Restoring interrupted work across launches needs a separately reviewed format.
private var meetingFocusHandoff = MeetingFocusHandoff<InterruptedMeetingFocus>()

func invalidateMeetingFocusHandoffForNewSession() {
    meetingFocusHandoff.sessionStarted()
    MeetingFocusTransport.shared.sessionStarted()
}

@MainActor
private func suspendFocusForMeeting() -> UUID? {
    guard let delegate = appdelegate,
          currentAccountabilityBuddySession?.isMeeting != true,
          !teacherSessionManagerObject.isTeacherSessionActive(),
          isFocusModeOn() || isFocusModePaused(),
          let modeId = currentRunningFocusType[FocusModeDictionaryKey.id] as? String,
          !modeId.isEmpty,
          let remaining = MeetingFocusResumeTiming.remainingSeconds(end: endFocusModeTime,
            pausedSeconds: isFocusModePaused() ? delegate.remainingFocusModeSecondsAfterPaused : nil,
            now: Date()) else { return nil }
    let snapshot = InterruptedMeetingFocus(identity: FocusLifecycleIdentity.shared.capture(),
        modeId: modeId, remainingSeconds: remaining,
        intention: whatToAchieveInFocusBlock, taskQueue: focusModeTaskString,
        strictness: currentFocusModeStrictness,
        wasPaused: isFocusModePaused(), wasAutoStarted: isFocusSessionAutoStarted,
        wasStartedFromPostpone: isFocusSessionStartedFromPostponeIntention,
        wasHardcore: isHardCorePomodoroModeOn,
        skipPomodoroBreaks: isSkipBreakActivityDuringPomodoro, skipFocusBreaks: isSkipBreakActivityDuringFocus,
        buddySession: currentAccountabilityBuddySession,
        temporaryApps: arrAllowedAppsInCuddlyModeCurrentFocus,
        temporaryURLs: arrAllowedUrlsInCuddlyModeCurrentFocus,
        temporaryTabTitles: arrAllowedTabTitlesInCuddlyModeCurrentFocus,
        temporaryURLIntentions: dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus,
        convincedURLs: arrConvinceAiUrlsInCurrentFocus,
        convincedApps: arrConvinceAiAppsInCurrentFocus)
    return meetingFocusHandoff.suspend(snapshot)
}

/// Only explicit Stop of the meeting resumes work; other automatic/routine transitions retain their rules.
@MainActor
func resumeFocusInterruptedByMeetingIfAvailable() -> Bool {
    guard currentAccountabilityBuddySession?.isMeeting == true,
          let delegate = appdelegate,
          !teacherSessionManagerObject.isTeacherSessionActive(),
          let (snapshot, generation) = meetingFocusHandoff.consume() else { return false }
    guard snapshot.identity.isCurrent,
          arrFocusType.contains(where: { $0[FocusModeDictionaryKey.id] as? String == snapshot.modeId }) else {
        meetingFocusHandoff.cancel()
        return false
    }
    let transportSegment = MeetingFocusTransport.Segment()
    scheduleMeetingFocusHandoff(finish: { finishSegmentForMeetingHandoff(delegate, next: transportSegment) },
        currentState: { currentState },
        enqueue: { DispatchQueue.main.async(execute: $0) },
        cancelled: { meetingFocusHandoff.cancel(ifCurrent: generation) }) {
        guard snapshot.identity.isCurrent, !teacherSessionManagerObject.isTeacherSessionActive(),
              let index = arrFocusType.firstIndex(where: { $0[FocusModeDictionaryKey.id] as? String == snapshot.modeId }),
              meetingFocusHandoff.beginStart(generation) else {
            meetingFocusHandoff.cancel(ifCurrent: generation)
            return
        }
        defer { meetingFocusHandoff.cancel() }
        startFocusModeTime = Date()
        currentFocusModeStrictness = snapshot.strictness
        MeetingFocusTransport.shared.start(transportSegment) {
            delegate.startFocusFromMenu(focusModeId: snapshot.modeId,
                minutes: max(1, snapshot.remainingSeconds / MeetingFocusResumeTiming.SECONDS_PER_MINUTE),
                intention: snapshot.intention, isAutoStarted: snapshot.wasAutoStarted,
                initialTaskQueue: snapshot.taskQueue, durationSeconds: snapshot.remainingSeconds)
        }
        currentFocusModeStrictness = snapshot.strictness
        UserDefaults.standard.set(MeetingFocusResumeTiming.storedStrictness(snapshot.strictness), forKey: kUserdefaultsLastFocusModeStrictness)
        setFocusSessionAutoStarted(snapshot.wasAutoStarted)
        isFocusSessionStartedFromPostponeIntention = snapshot.wasStartedFromPostpone
        isHardCorePomodoroModeOn = snapshot.wasHardcore
        isSkipBreakActivityDuringPomodoro = snapshot.skipPomodoroBreaks
        isSkipBreakActivityDuringFocus = snapshot.skipFocusBreaks
        arrAllowedAppsInCuddlyModeCurrentFocus = snapshot.temporaryApps
        arrAllowedUrlsInCuddlyModeCurrentFocus = snapshot.temporaryURLs
        arrAllowedTabTitlesInCuddlyModeCurrentFocus = snapshot.temporaryTabTitles
        // Keep original absolute expiry dates: a meeting must not renew a time-limited exception.
        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus = snapshot.temporaryURLIntentions
        arrConvinceAiUrlsInCurrentFocus = snapshot.convincedURLs
        arrConvinceAiAppsInCurrentFocus = snapshot.convincedApps
        currentAccountabilityBuddySession = snapshot.buddySession
        if let session = snapshot.buddySession { applyAccountabilityBuddyBlockingContext(session) }
        if let end = endFocusModeTime { persistAccountabilityBuddySession(endTime: end) }
        if snapshot.wasPaused { delegate.pauseFocusMode(index: index) }
        showRunningFocusSessionWindow()
        addLog(text: "meeting ended: restored interrupted focus with saved remaining time")
    }
    return true
}

// MARK: - Presentation

/// Hosts the accountability-buddy CHAT and presents it as a SHEET on the routine window, so it reliably
/// appears over the borderless full-screen routine (a plain window gets covered by the app's
/// forced-front routine window — the reason a separate window showed nothing). This REPLACES the old
/// AppKit "what do you intend to do instead?" postpone dialog. It GATES the postpone: the habit is only
/// postponed via `onApproved(goal)` when the AI approves and the user starts; giving up or closing the
/// sheet calls `onCancel`, keeping the user in their routine.
enum AccountabilityChatPurpose {
    case postponeRoutine
    case extendSession(minutes: Int)

    func grantedMinutes(_ approved: Int) -> Int {
        switch self {
        case .postponeRoutine: return approved
        case .extendSession(let requested): return min(max(0, requested), max(0, approved))
        }
    }
}

final class AccountabilityBuddyChatViewController: NSViewController {

    private let onApproved: (String, Int) -> Void
    private let onCancel: () -> Void
    private let dismissSheet: (NSViewController) -> Void
    private let initialGoal: String
    private let strings: AccountabilityBuddyStrings
    private let purpose: AccountabilityChatPurpose
    private var didResolve = false
    private let routineAtPresentation = currentState
    private var longTermGoals: [String] = []   // filled asynchronously; evaluate uses whatever is loaded
    private let uncompletedHabits = accountabilityBuddyUncompletedHabits()   // snapshot at open
    private let dayPlanTasks = accountabilityBuddyDayPlanTasks()
    private let taskCandidates = AccountabilityTaskSelection.candidates(
        from: DayPlanTaskStore.shared.incompleteTasksInDisplayOrder(for: Date()))

    /// Present the buddy chat as a sheet on `presenter`. `initialGoal` seeds the first message (empty ⇒
    /// the buddy greets and asks). `onApproved` receives the goal AND the AI-approved duration (minutes)
    /// and should run the postpone; `onCancel` returns to the routine.
    static func present(over presenter: NSViewController, initialGoal: String,
                        purpose: AccountabilityChatPurpose = .postponeRoutine,
                        onApproved: @escaping (String, Int) -> Void, onCancel: @escaping () -> Void) {
        let vc = AccountabilityBuddyChatViewController(initialGoal: initialGoal,
                                                       purpose: purpose,
                                                       onApproved: onApproved, onCancel: onCancel)
        presenter.presentAsSheet(vc)
    }

    init(initialGoal: String, purpose: AccountabilityChatPurpose,
         onApproved: @escaping (String, Int) -> Void, onCancel: @escaping () -> Void,
         dismissSheet: @escaping (NSViewController) -> Void = { controller in
             // Dismiss the presented controller through its presenter, not itself as a child.
             controller.presentingViewController?.dismiss(controller)
         }) {
        self.initialGoal = initialGoal
        self.purpose = purpose
        var strings = AccountabilityBuddyStrings.load()
        if case .extendSession(let minutes) = purpose {
            let extensionStrings = ExtendReasonBuddyStrings.load(minutes: minutes)
            strings.goalPrompt = extensionStrings.subtitle
            strings.startForMinutes = extensionStrings.buttonContinue
        }
        self.strings = strings
        self.onApproved = onApproved
        self.onCancel = onCancel
        self.dismissSheet = dismissSheet
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let chat = AccountabilityChatView(
            initialGoal: initialGoal,
            strings: strings,
            onEvaluate: { [weak self] conversation, done in
                let msgs = conversation.map { (role: $0.role.apiRole, text: $0.text) }
                allApiObject.evaluateAccountabilityConversation(messages: msgs,
                                                                longTermGoals: self?.longTermGoals ?? [],
                                                                uncompletedHabits: self?.uncompletedHabits ?? [],
                                                                dayPlanTasks: self?.dayPlanTasks ?? [],
                                                                dayPlanTaskCandidates: self?.taskCandidates ?? [],
                                                                calendarEvents: accountabilityBuddyCalendarContext(),
                                                                isInMeeting: appdelegate?.isUserOnMeeting ?? false,
                                                                routineCompletionPercent: accountabilityBuddyRoutineCompletionPercent(),
                                                                minutesLeftInDay: accountabilityBuddyMinutesLeftInDay(),
                                                                completion: done)
            },
            onStart: { [weak self] verdict, goalText in
                self?.startApprovedSession(verdict: verdict, goal: goalText)
            },
            onErrorPostpone: { [weak self] minutes in
                self?.postponeAfterBackendError(minutes: minutes)
            },
            onGiveUp: { [weak self] in self?.cancelChat() })
        let host = NSHostingView(rootView: chat)
        host.frame = NSRect(x: 0, y: 0, width: 460, height: 560)
        host.setAccessibilityIdentifier(UITestContract.Identifier.Routine.accountabilityBuddySheet)
        self.view = host
    }

    /// A routine can change while the sheet is open (wake, break, cutoff). A stale approval
    /// must close as a cancellation rather than leave a resolved SwiftUI view trapping the user.
    private func beginApproval() -> Bool {
        guard !didResolve else { return false }
        guard currentState == routineAtPresentation else {
            addLog(text: "accountability buddy: stale approval dismissed; presented=\(routineAtPresentation), current=\(currentState)")
            cancelChat()
            return false
        }
        didResolve = true
        dismissSheet(self)
        return true
    }

    func startApprovedSession(verdict: AccountabilityVerdict, goal: String) {
        guard beginApproval() else { return }
        let approved = purpose.grantedMinutes(verdict.clampedDurationMinutes)
        let granted: Int
        switch purpose {
        case .postponeRoutine: granted = cutoffLimitedPostponeMinutes(approved)
        case .extendSession: granted = approved
        }
        onApproved(goal, granted)
        if case .postponeRoutine = purpose {
            startAccountabilityBuddySession(verdict: verdict, goal: goal, minutes: granted,
                                            taskCandidates: taskCandidates)
        }
    }

    func postponeAfterBackendError(minutes: Int) {
        guard beginApproval() else { return }
        addLog(text: "[user-action] accountability buddy: backend-error postpone confirmed after 10-second hold, minutes=\(minutes)")
        onApproved("", purpose.grantedMinutes(minutes))
    }

    func cancelChat() {
        // Closing remains available even if an earlier start already marked the chat resolved.
        // Mark before dismissal because viewDidDisappear can run synchronously from dismiss.
        let needsCancel = !didResolve
        didResolve = true
        dismissSheet(self)
        if needsCancel { onCancel() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 460, height: 560)
        allApiObject.getuserLongTermGoals { [weak self] goals in
            DispatchQueue.main.async { self?.longTermGoals = goals ?? [] }
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        // Dismissed without approving → the user stays in their routine (habit not postponed).
        if !didResolve { didResolve = true; onCancel() }
    }
}

// MARK: - Chat model

/// One line in the buddy conversation.
struct AccountabilityChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    enum Role {
        case buddy, user
        var apiRole: String { self == .buddy ? "assistant" : "user" }
    }
}

// MARK: - SwiftUI chat view

/// A chat with the accountability buddy: the user makes their case for postponing, the AI replies each
/// turn, and the user can keep arguing to convince it. When the AI approves, a "start" bar appears that
/// begins the scoped super-strict session. Presentation-only; the window controller injects callbacks.
/// Notices when the accountability buddy has stopped making progress.
///
/// Report 2026-09-22_16-07-17 ("terrible experience"): the user answered every question asked —
/// the task ("fix Open AI account"), the duration ("30m"), the urgency ("client is chasing me"),
/// their habit status — and the buddy kept demanding the same things, eventually repeating one
/// sentence verbatim while the user replied "I already answered that", "get lost", "I already told
/// you". The only ways out were to keep answering or to abandon the request entirely.
///
/// A denial that repeats itself is the FEATURE failing, not the user failing to explain. The app
/// already knows what to do when this feature fails — it offers a held-button postpone — so a stuck
/// conversation is routed to the same escape rather than continuing to argue.
enum AccountabilityLoopGuard {

    /// Unanswered demands before the conversation is treated as stuck, counting only the buddy's
    /// turns. Four is two more chances than the user in the report needed to lose patience, and
    /// still short of the six they actually endured.
    static let maxBuddyTurns = 4

    /// Punctuation, case and spacing removed, so "I still need one concrete answer: what exactly…"
    /// and "I still need one concrete answer — what exactly…" count as the same demand.
    static func normalised(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// True when the buddy has asked too many times, or has just repeated something it already said.
    static func isStuck(buddyMessages: [String]) -> Bool {
        let meaningful = buddyMessages.map(normalised).filter { !$0.isEmpty }
        guard let latest = meaningful.last else { return false }
        if meaningful.count >= maxBuddyTurns { return true }
        // Repetition is the clearer signal, and it fires sooner than the turn count.
        return meaningful.dropLast().contains(latest)
    }
}

struct AccountabilityChatView: View {

    let strings: AccountabilityBuddyStrings
    let onEvaluate: ([AccountabilityChatMessage], @escaping (Result<AccountabilityVerdict, Error>) -> Void) -> Void
    let onStart: (AccountabilityVerdict, String) -> Void
    let onGiveUp: () -> Void
    let onErrorPostpone: (Int) -> Void

    private let initialGoal: String
    // The app defines global `State`/`Button` types that shadow SwiftUI's — qualify them.
    @SwiftUI.State private var messages: [AccountabilityChatMessage] = []
    @SwiftUI.State private var input: String = ""
    @SwiftUI.State private var isThinking = false
    @SwiftUI.State private var approvedVerdict: AccountabilityVerdict?
    @SwiftUI.State private var hasBackendError = false
    @SwiftUI.State private var recoveryReason: AccountabilityRecoveryReason = .unavailable
    @SwiftUI.State private var isRecoveryExpanded = false
    @SwiftUI.State private var selectedRecoveryMinutes = AccountabilityPostponeRecovery.defaultMinutes
    @SwiftUI.State private var holdProgress: Double = 0
    @SwiftUI.State private var activeRequest: UUID?
    @SwiftUI.State private var isVisible = false
    @SwiftUI.State private var didResolve = false
    @SwiftUI.State private var didSeed = false
    @SwiftUI.State private var firstUserMessage = ""   // the goal, used as the session intention

    init(initialGoal: String,
         strings: AccountabilityBuddyStrings,
         onEvaluate: @escaping ([AccountabilityChatMessage], @escaping (Result<AccountabilityVerdict, Error>) -> Void) -> Void,
         onStart: @escaping (AccountabilityVerdict, String) -> Void,
         onErrorPostpone: @escaping (Int) -> Void,
         onGiveUp: @escaping () -> Void) {
        self.initialGoal = initialGoal
        self.strings = strings
        self.onEvaluate = onEvaluate
        self.onStart = onStart
        self.onErrorPostpone = onErrorPostpone
        self.onGiveUp = onGiveUp
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            transcript
            if hasBackendError { recoveryBar }
            if let verdict = approvedVerdict { approvedBar(verdict) }
            Divider()
            inputBar
        }
        .frame(width: 460, height: 560)
        .onAppear { isVisible = true; seedIfNeeded() }
        .onDisappear { isVisible = false; activeRequest = nil; hasBackendError = false }
        .onExitCommand(perform: giveUp)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill").foregroundColor(.accentColor)
            Text(strings.header).font(.headline)
            Spacer()
            // Close (give up) — replaces the old "Do my habit" button; keeps the user in their routine.
            SwiftUI.Button(action: giveUp) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(strings.buttonDoHabit)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { bubble($0) }
                    if isThinking {
                        HStack(spacing: 8) { ProgressView().scaleEffect(0.6); Text(strings.checking).font(.callout).foregroundColor(.secondary) }
                            .id("thinking")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: messages.count) { _ in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: isThinking) { thinking in
                if thinking { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
            }
        }
    }

    private func bubble(_ message: AccountabilityChatMessage) -> some View {
        let isUser = message.role == .user
        return HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(isUser ? Color.accentColor : Color.gray.opacity(0.18))
                .foregroundColor(isUser ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if !isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private func approvedBar(_ verdict: AccountabilityVerdict) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            let apps = verdict.allowedApps.isEmpty ? strings.noApps : verdict.allowedApps.joined(separator: " · ")
            let sites = verdict.allowedUrls.isEmpty ? strings.noSites : verdict.allowedUrls.joined(separator: " · ")
            Text("\(strings.appsUnlocked): \(apps)").font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(strings.sitesUnlocked): \(sites)").font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            SwiftUI.Button {
                guard !didResolve, !isThinking, !hasBackendError else { return }
                didResolve = true
                onStart(verdict, firstUserMessage.isEmpty ? initialGoal : firstUserMessage)
            } label: {
                Text(strings.startForMinutes.replacingOccurrences(of: "{minutes}", with: "\(verdict.clampedDurationMinutes)"))
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.green.opacity(0.08))
    }

    /// Report 2026-09-25_15-40-49. A stuck conversation gets one quiet question first; an outage says
    /// plainly what happened. "Try my buddy again" and "Do my habit" are gone: sending another message
    /// already retries, and the X closes the card. The ten-second hold is unchanged, so this is no
    /// easier to use as an escape hatch than before.
    private var recoveryBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                recoveryHeading
                Spacer(minLength: 8)
                SwiftUI.Button(action: dismissRecovery) {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(strings.recoveryClose)
                .accessibilityLabel(Text(strings.recoveryClose))
            }
            if isRecoveryExpanded { recoveryControls }
        }
        .padding(.horizontal, 16).padding(.vertical, isRecoveryExpanded ? 16 : 8)
        .background(Color.orange.opacity(isRecoveryExpanded ? 0.08 : 0.04))
    }

    @ViewBuilder
    private var recoveryHeading: some View {
        switch recoveryReason {
        case .stuck where !isRecoveryExpanded:
            HStack(spacing: 8) {
                Text(strings.annoyingPrompt).font(.callout).foregroundColor(.secondary)
                SwiftUI.Button(strings.annoyingYes) { isRecoveryExpanded = true }.controlSize(.small)
            }
        case .stuck:
            Text(strings.recoveryTitle).font(.headline)
        case .offline:
            recoveryExplanation(title: strings.offlineTitle, body: strings.offlineExplanation)
        case .unavailable:
            recoveryExplanation(title: strings.unavailableTitle, body: strings.unavailableExplanation)
        }
    }

    private func recoveryExplanation(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(body).font(.callout).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var recoveryControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(strings.recoveryDuration, selection: $selectedRecoveryMinutes) {
                ForEach(AccountabilityPostponeRecovery.durations, id: \.self) { minutes in
                    Text(strings.recoveryMinutes.replacingOccurrences(of: "{minutes}", with: "\(minutes)")).tag(minutes)
                }
            }
            AccountabilityHoldButton(
                minutes: selectedRecoveryMinutes,
                title: holdProgress > 0
                    ? strings.recoveryHolding.replacingOccurrences(of: "{seconds}", with: "\(max(1, Int(ceil((1 - holdProgress) * AccountabilityPostponeRecovery.requiredHoldSeconds))))")
                    : strings.recoveryHold,
                help: strings.recoveryHoldHelp,
                onProgress: { holdProgress = $0 },
                onConfirmed: { minutes in
                    guard hasBackendError, !isThinking, !didResolve, isVisible else { return }
                    didResolve = true
                    hasBackendError = false
                    onErrorPostpone(minutes)
                })
                .frame(height: 34)
            ProgressView(value: holdProgress).accessibilityLabel(Text(strings.recoveryHold))
            Text(strings.recoveryHoldHelp).font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Hides the card; the conversation stays open. A stuck conversation brings it back on the next
    /// repeated denial, an outage on the next failed send.
    private func dismissRecovery() {
        hasBackendError = false
        isRecoveryExpanded = false
        holdProgress = 0
    }

    private func giveUp() {
        // Escape and Close must still work after a rejected/stale Start action.
        didResolve = true
        activeRequest = nil
        hasBackendError = false
        onGiveUp()
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField(strings.inputPlaceholder, text: $input, onCommit: send)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(UITestContract.Identifier.Routine.buddyChatInput)
            SwiftUI.Button(strings.buttonSend, action: send)
                .disabled(isThinking || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier(UITestContract.Identifier.Routine.buddyChatSendButton)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func seedIfNeeded() {
        guard !didSeed else { return }
        didSeed = true
        let goal = initialGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        if goal.isEmpty {
            messages.append(AccountabilityChatMessage(role: .buddy, text: strings.goalPrompt))
        } else {
            firstUserMessage = goal
            messages.append(AccountabilityChatMessage(role: .user, text: goal))
            evaluate()
        }
    }


    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking, !didResolve else { return }
        if firstUserMessage.isEmpty { firstUserMessage = text }
        // Clear on the next runloop tick: resetting the binding synchronously inside a TextField's
        // onCommit is overwritten by AppKit's own commit cycle, so the just-sent text stays (selected)
        // in the field. Deferring the reset makes it stick for both the Send button and the Return key.
        DispatchQueue.main.async { input = "" }
        approvedVerdict = nil
        messages.append(AccountabilityChatMessage(role: .user, text: text))
        evaluate()
    }

    private func showRecovery(_ reason: AccountabilityRecoveryReason) {
        recoveryReason = reason
        isRecoveryExpanded = !reason.startsCollapsed
        hasBackendError = true
    }

    private func evaluate() {
        guard !isThinking, !didResolve, isVisible else { return }
        let requestID = UUID()
        activeRequest = requestID
        hasBackendError = false
        isRecoveryExpanded = false
        holdProgress = 0
        approvedVerdict = nil
        isThinking = true
        onEvaluate(messages) { result in
            DispatchQueue.main.async {
                guard isVisible, !didResolve, activeRequest == requestID else { return }
                activeRequest = nil
                isThinking = false
                switch result {
                case .success(let verdict):
                    messages.append(AccountabilityChatMessage(role: .buddy, text: verdict.message))
                    approvedVerdict = verdict.approved ? verdict : nil
                    // A denial that keeps repeating itself is this feature failing. Offer the same
                    // escape a backend error would, instead of arguing indefinitely.
                    if approvedVerdict == nil,
                       AccountabilityLoopGuard.isStuck(buddyMessages: messages
                                                        .filter { $0.role == .buddy }
                                                        .map { $0.text }) {
                        showRecovery(.stuck)
                    }
                case .failure(let error):
                    // Every failure takes the same deliberate, held fallback, and errors never invoke the
                    // postpone callback. The card says which kind of failure it was, so no chat bubble.
                    showRecovery(AccountabilityRecoveryReason.from(error: error))
                }
            }
        }
    }
}
