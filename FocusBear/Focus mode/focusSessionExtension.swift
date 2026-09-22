//
//  focusSessionExtension.swift
//  Focus Bear
//
//  Extending a focus session that is already running.
//
//  Reported by the product owner: "When I extended the focus session a while back, it seemed to
//  cancel the AI blocking that was in place. It should have triggered the AI accountability buddy to
//  ask why I need more time."
//
//  Two rules live here, and every user-initiated extend path goes through them:
//
//  1. An extension CONTINUES the session that is running. It must not tear the blocking context down
//     the way STARTING a session does. `AppDelegate.focusModeStartted()` deliberately finishes a
//     running custom blocking schedule — a brand new session's own block list supersedes it — and the
//     extend path in `addTaskVc` had copied that teardown. Because
//     `SettingsManager.isAIBlockingEnabled()` decides from `isAnyCustomScheduleOn` first and the
//     running block list's `is_ai_enabled` second, finishing the schedule mid-extension moved the
//     decision onto a different block list (or onto the global AI toggle), silently cancelling AI
//     relevance checking for exactly the minutes the user asked for.
//
//  2. Extending is worth a question. When AI relevance checking is on, the AI accountability buddy
//     asks why more time is needed before the extra minutes are granted, and the answer becomes the
//     focus intention the AI judges the extra time against.
//
//  "Use AI for this block list" is a property of the BLOCK LIST, never of a schedule or of an
//  extension (see CLAUDE.md). Nothing here invents that flag for a block list the user never chose —
//  it only stops an extension from changing the flag that was already in force.
//

import Cocoa

/// Analytics event names for the extension flow. One registry, and the *values* never change —
/// renaming a value breaks the event history.
enum FocusExtensionAnalyticsEvent {
    static let buddyAsked = "extend-focus-session-buddy-asked"
    static let buddyAnswered = "extend-focus-session-buddy-answered"
    static let buddySkipped = "extend-focus-session-buddy-skipped"
    /// The buddy judged the stated reason as not matching the session and said so.
    static let buddyPushedBack = "extend-focus-session-buddy-pushed-back"
    /// The user rewrote their answer after the push-back.
    static let buddyRevised = "extend-focus-session-buddy-revised"
    /// The user read the push-back and extended anyway. Watch this one: it is the evidence for how
    /// hard the server should push (backend#2368).
    static let buddyOverridden = "extend-focus-session-buddy-overridden"
}

/// What the extend-reason sheet does once the AI accountability buddy has (or hasn't) judged the
/// stated reason.
enum ExtendReasonVerdict: Equatable {
    /// Grant the extra minutes now.
    case extendNow
    /// Show `reason` and make the user choose again — revise the answer, or extend deliberately.
    case pushBack(reason: String)
}

/// Keys of the focus-mode (block list) dictionaries in `arrFocusType` / `currentRunningFocusType`
/// that the extension flow and the AI block buddy read or write.
enum FocusModeDictionaryKey {
    static let id = "id"
    static let isAiEnabled = "is_ai_enabled"
    static let isOn = "isOn"
    static let lastScheduledEndDate = "lastScheduledEndDate"
    /// The block list's display name, sent to the server as context for an alignment judgement.
    static let name = "name"
}

/// Date format `lastScheduledEndDate` is stored in, matching every other writer of that key.
private let kScheduledEndDateFormat = "yyyy-MM-dd HH:mm:ss"

/// Separator between the original focus intention and the reason the user gave for extending.
private let kIntentionReasonSeparator = " — "

/// How long the buddy's alignment check may take before the extension is granted without it.
///
/// This covers the WHOLE round trip, including the Auth0 token refresh that runs before the request
/// is even built — `URLRequest.timeoutInterval` does not, and offline that refresh is exactly where
/// the call stalls. The user is staring at a modal sheet; it must always end.
private let kExtensionReasonCheckTimeout: TimeInterval = 10

enum FocusSessionExtension {

    /// Everything `SettingsManager.isAIBlockingEnabled()` consults about the session running right
    /// now, captured before an extension is applied so the extension can be checked against it.
    struct BlockingContext: Equatable {
        /// Whether a custom blocking schedule was enforcing the block list.
        var isCustomScheduleOn: Bool
        /// The block list that was in force.
        var runningFocusModeId: String
        /// That block list's own AI switch. `nil` when the block list carries no such key, which the
        /// rest of the app reads as "AI on".
        var isAiEnabledForRunningFocusMode: Bool?
        /// The gate's answer before the extension — the value the extension must not change.
        var isAIBlockingEnabled: Bool
    }

    // MARK: - Capturing and restoring the blocking context

    /// Snapshot the live blocking context. Call immediately before applying an extension.
    static func captureBlockingContext() -> BlockingContext {
        BlockingContext(
            isCustomScheduleOn: customBlockingScheduleManagerObj.isAnyCustomScheduleOn,
            runningFocusModeId: currentRunningFocusType[FocusModeDictionaryKey.id] as? String ?? "",
            isAiEnabledForRunningFocusMode: currentRunningFocusType[FocusModeDictionaryKey.isAiEnabled] as? Bool,
            isAIBlockingEnabled: SettingsManagerObject.isAIBlockingEnabled()
        )
    }

    /// The block-list dictionary an extended session must keep running with.
    ///
    /// `next` is whatever the extend path is about to make current — normally a fresh copy of the same
    /// block list out of `arrFocusType`. When it IS the same block list, its AI switch is forced back
    /// to the value that was actually in force, so an extension can never silently flip AI relevance
    /// checking on or off. A genuinely different block list is returned untouched: the flag belongs to
    /// the list, and this must not fabricate one for a list the user never chose.
    static func focusModePreservingAI(_ next: [String: Any], before: BlockingContext) -> [String: Any] {
        guard next[FocusModeDictionaryKey.id] as? String == before.runningFocusModeId else { return next }
        guard let wasAiEnabled = before.isAiEnabledForRunningFocusMode else { return next }
        var preserved = next
        preserved[FocusModeDictionaryKey.isAiEnabled] = wasAiEnabled
        return preserved
    }

    /// Re-assert the captured context on the live globals after an extension has been applied, and log
    /// the gate either side of it so a regression shows up in the debug logs rather than only in a
    /// user report.
    /// - Returns: `true` when something had drifted and was put back.
    @discardableResult
    static func reapplyBlockingContext(_ before: BlockingContext) -> Bool {
        var didRestore = false

        if before.isCustomScheduleOn && !customBlockingScheduleManagerObj.isAnyCustomScheduleOn {
            addLog(text: "extend: a running blocking schedule was torn down by the extension — its block list no longer governs AI blocking")
            didRestore = true
        }

        let preserved = focusModePreservingAI(currentRunningFocusType, before: before)
        if (preserved[FocusModeDictionaryKey.isAiEnabled] as? Bool)
            != (currentRunningFocusType[FocusModeDictionaryKey.isAiEnabled] as? Bool) {
            didRestore = true
        }
        currentRunningFocusType = preserved

        let after = SettingsManagerObject.isAIBlockingEnabled()
        addLog(text: "extend: AI blocking before=\(before.isAIBlockingEnabled) after=\(after)\(didRestore ? " (restored)" : "")")
        return didRestore
    }

    /// Enforce the cutoff again at the point of mutation, including after chat/password sheets.
    /// A nil end means a completed session is being restarted from now.
    static func cutoffLimitedMinutes(_ minutes: Int, from currentEnd: Date?, now: Date = Date()) -> Int {
        let protectsRoutine = routinePostponeStateToReCoverOnExtend() != nil ||
            currentAccountabilityBuddySession.map { !$0.isMeeting } == true ||
            lastCompletedAccountabilityBuddySession.map { !$0.isMeeting } == true
        let granted = FocusExtensionCutoffLimit.grantedMinutes(requested: minutes, now: now,
            currentEnd: currentEnd, cutoff: todaysCutoffDate(now: now), isAfterCutoff: isCutOffTimeGoing(),
            isCutoffStrict: SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff,
            protectsRoutine: protectsRoutine)
        if granted < minutes { addLog(text: "extend: cutoff \(cutOffTimeString) limits extra minutes \(minutes) -> \(granted)") }
        if minutes > 0 && granted == 0 { showCutoffPostponeRefusedAlert(forExtension: true) }
        return granted
    }

    // MARK: - Applying an extension

    /// Apply the local state an extension changes: the block list runs again, the scheduled end moves
    /// out, and the blocking context that was in force is carried across unchanged.
    ///
    /// Everything AppKit — windows, Do Not Disturb, before-focus scripts, the countdown timers — stays
    /// in the view controllers; this is the part that has to be right for blocking, so it lives where
    /// it can be tested.
    ///
    /// - Returns: the index of the block list the extended session runs, or `nil` when the id can't be
    ///   resolved (in which case nothing is changed).
    @discardableResult
    static func applyLocalExtension(focusModeId: String, minutes: Int, now: Date = Date()) -> Int? {
        let before = captureBlockingContext()

        guard let index = arrFocusType.firstIndex(where: {
            $0[FocusModeDictionaryKey.id] as? String == focusModeId
        }) else {
            addLog(text: "extend: block list \(focusModeId) is not in arrFocusType — extension not applied")
            return nil
        }

        let newEnd = Calendar.current.date(byAdding: .minute, value: minutes, to: now)
        endFocusModeTime = newEnd
        arrFocusType[index][FocusModeDictionaryKey.isOn] = true
        if let newEnd = newEnd {
            arrFocusType[index][FocusModeDictionaryKey.lastScheduledEndDate] =
                getStringFromDate(date: newEnd, dateFormat: kScheduledEndDateFormat)
        }

        currentRunningFocusType = focusModePreservingAI(arrFocusType[index], before: before)
        isFocusModeRunning = true
        reapplyBlockingContext(before)
        return index
    }

    // MARK: - Judging the stated reason

    /// Whether the stated reason is worth asking the server about.
    ///
    /// Nothing to compare against (no intention set for the session) or nothing stated (Skip) means
    /// there is no question to ask, and the extension goes ahead unjudged. The endpoint rejects an
    /// empty `intention`/`task_name` anyway.
    static func shouldCheckExtensionReason(intention: String, reason: String) -> Bool {
        !intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Turn the server's answer into what the sheet should do.
    ///
    /// FAILS OPEN. An unreachable server, a timed-out request or a body that didn't parse all extend:
    /// the check is advisory, and being offline must never cost a user the extra minutes they asked
    /// for. Only an explicit `aligns: false` — which the deliberately lenient classifier gives only
    /// for a clear conflict — pushes back, and even then it asks rather than forbids.
    static func verdictForExtensionReason(_ outcome: Result<TaskIntentionAlignment, Error>,
                                          fallbackPushBackMessage: String) -> ExtendReasonVerdict {
        guard case .success(let alignment) = outcome else { return .extendNow }
        guard !alignment.aligns else { return .extendNow }
        let message = alignment.reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return .pushBack(reason: message.isEmpty ? fallbackPushBackMessage : message)
    }

    /// Ask the buddy whether the stated reason belongs to this session and report what the sheet
    /// should do next.
    ///
    /// Never blocks the caller, and never leaves it waiting: a check that has not answered within
    /// `timeout` extends anyway. `completion` is always called exactly once, on the main queue.
    static func checkExtensionReason(_ reason: String,
                                     intention: String,
                                     focusMode: String?,
                                     checker: TaskIntentionChecking,
                                     fallbackPushBackMessage: String,
                                     timeout: TimeInterval = kExtensionReasonCheckTimeout,
                                     completion: @escaping (ExtendReasonVerdict) -> Void) {
        guard shouldCheckExtensionReason(intention: intention, reason: reason) else {
            DispatchQueue.main.async { completion(.extendNow) }
            return
        }

        // `hasFinished` is only ever touched on the main queue — both the timeout and the checker's
        // answer hop there first — so the two racing paths can't both fire the completion.
        var hasFinished = false
        func finishOnMain(_ verdict: ExtendReasonVerdict) {
            guard !hasFinished else { return }
            hasFinished = true
            completion(verdict)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !hasFinished else { return }
            addLog(text: "extend: buddy alignment check timed out — extending anyway")
            finishOnMain(.extendNow)
        }

        checker.checkTaskIntentionAlignment(intention: intention,
                                            taskName: reason,
                                            focusMode: focusMode) { outcome in
            let verdict = verdictForExtensionReason(outcome,
                                                    fallbackPushBackMessage: fallbackPushBackMessage)
            DispatchQueue.main.async { finishOnMain(verdict) }
        }
    }

    // MARK: - The AI accountability buddy's question

    /// Whether the buddy should ask why more time is needed.
    ///
    /// Ask for running or just-completed buddy sessions even after their live blocking stops.
    /// Ordinary sessions ask only when AI relevance checking governs their block list.
    static func shouldAskWhyMoreTimeIsNeeded() -> Bool {
        currentAccountabilityBuddySession != nil || lastCompletedAccountabilityBuddySession != nil ||
            SettingsManagerObject.isAIBlockingEnabled()
    }

    /// The focus intention the extended session runs with.
    ///
    /// The AI relevance checks judge every app and site against `whatToAchieveInFocusBlock`, so folding
    /// the stated reason into it is what makes the buddy's question do something: the extra minutes are
    /// judged against the reason the user gave for wanting them. A blank answer changes nothing.
    static func intentionAfterExtension(previousIntention: String, reason: String) -> String {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else { return previousIntention }
        let trimmedPrevious = previousIntention.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrevious.isEmpty else { return trimmedReason }
        guard !trimmedPrevious.localizedCaseInsensitiveContains(trimmedReason) else { return trimmedPrevious }
        return trimmedPrevious + kIntentionReasonSeparator + trimmedReason
    }

    /// Record the reason on the running session and report it, then hand back to the extend path.
    static func applyExtensionReason(_ reason: String) {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            allApiObject.capturePosthog(event: FocusExtensionAnalyticsEvent.buddySkipped, metadata: [:])
            return
        }
        whatToAchieveInFocusBlock = intentionAfterExtension(
            previousIntention: whatToAchieveInFocusBlock, reason: trimmed)
        addLog(text: "extend: buddy reason recorded, intention is now \"\(whatToAchieveInFocusBlock)\"")
        allApiObject.capturePosthog(event: FocusExtensionAnalyticsEvent.buddyAnswered, metadata: [:])
    }

    /// Reuse the real postpone conversation. Denials stay in chat; approval extends this session
    /// without starting a replacement or changing its allow-list. Dismissing grants no time.
    static func askWhyMoreTimeIsNeeded(minutes requestedMinutes: Int,
                                       presenter: NSViewController?,
                                       restarting: Bool = false,
                                       extend: @escaping (Int) -> Void) {
        let minutes = cutoffLimitedMinutes(requestedMinutes, from: restarting ? nil : endFocusModeTime)
        guard minutes > 0 else { return }
        guard shouldAskWhyMoreTimeIsNeeded() else { extend(minutes); return }
        guard let presenter = presenter, presenter.view.window != nil else { return }
        let sessionStarted = startFocusModeTime
        let focusID = currentRunningFocusType[FocusModeDictionaryKey.id] as? String
        AccountabilityBuddyChatViewController.present(over: presenter, initialGoal: "",
            purpose: .extendSession(minutes: minutes), onApproved: { reason, approvedMinutes in
                guard startFocusModeTime == sessionStarted,
                      currentRunningFocusType[FocusModeDictionaryKey.id] as? String == focusID,
                      approvedMinutes > 0 else { return }
                let granted = cutoffLimitedMinutes(approvedMinutes, from: restarting ? nil : endFocusModeTime)
                guard granted > 0 else { return }
                applyExtensionReason(reason)
                extend(granted)
            }, onCancel: {})
        allApiObject.capturePosthog(event: FocusExtensionAnalyticsEvent.buddyAsked, metadata: [:])
    }
}
