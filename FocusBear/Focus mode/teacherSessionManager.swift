//
//  teacherSessionManager.swift
//  Focus Bear
//
//  Created by Focus Bear on 02/07/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  Teacher Mode:- a teacher starts a super strict class focus session from the web dashboard.
//  This manager owns the teacher session state + handlers. The session never starts without the
//  student accepting the join prompt, cannot be stopped early (only unlock requests), hot-syncs
//  the allow-list live from pusher events and reports presence with heartbeats.
//

import Cocoa
import SwiftUI

let teacherSessionManagerObject = teacherSessionManager()

// Teacher-mode strings live in the `teacherSessionInfo` config block (same block the menu card + locked
// alert read), with an English fallback baked in so the code ships i18n-ready before translations land.
func teacherSessionLocalized(_ key: String, _ fallback: String) -> String {
    if let info = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary,
       let s = info.value(forKey: key) as? String, !s.isEmpty {
        return s
    }
    return fallback
}

class teacherSessionManager: NSObject {

    var activeTeacherSessionId:String?
    var activeTeacherSessionTeamId:String?
    var activeTeacherSessionName = ""
    var appliedAllowlistVersion = 0
    var teacherSessionScheduledFinishTime:Date?
    var isTeacherSessionEndAllowed = false// only true when class-session-ended arrived or scheduled finish time reached
    var pendingInviteSessionId:String?
    // A class session the student declined (or dismissed the prompt for) that is still live and can be
    // re-joined from the status-bar menu (#2267). Held until the join succeeds, the join attempt fails,
    // or the session ends — cleared in all three cases.
    var declinedJoinableSessionDic:[String:Any]?
    var timerTeacherSessionHeartbeat:Timer?
    var teacherUnlockRequestWindow:NSWindow?
    // The PACT invite popup (new 2-screen SwiftUI invite + friction-decline card). Held so a repeat
    // invite for the same session can be de-duped and the window closed once the student acts.
    var teacherPactInviteWindow:NSWindow?

    let teacherSessionHeartbeatIntervalSeconds:Double = 5
    let teacherSessionOpenEndedFallbackHours = 12// mirror backend fallback for sessions with no scheduled finish time
    let teacherSessionDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

    private var isRoutinePostponedByTeacherSession = false
    /// The running session was started by a UI test (`UITestManagedSafetyFixture`) and exists in this
    /// process only, so there is no server session to send heartbeats to.
    private var isUITestSession = false
    
    func isTeacherSessionActive()->Bool{
        return activeTeacherSessionId != nil
    }

    func getSessionIdFromDictionary(dictionary:[String:Any])->String{
        // pusher payloads carry class_session_id, rest api responses carry id
        if let id = dictionary["class_session_id"] as? String{
            return id
        }
        return dictionary["id"] as? String ?? ""
    }

    //***********C1 pusher event handlers (already hopped to main thread in pusherEvents)***************//

    func handleSessionInvite(dictionary:[String:Any]){
        addLog(text: "teacher session:- class-session-invite received")
        if isTeacherSessionActive(){// one teacher session at a time
            return;
        }
        showJoinPrompt(sessionDic: dictionary)
    }

    func handleAllowlistChanged(dictionary:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: dictionary)
        if sessionId.isEmpty || sessionId != activeTeacherSessionId{
            return;
        }
        let version = dictionary["allowlist_version"] as? Int ?? 0
        if version <= appliedAllowlistVersion{// drop stale/duplicate deliveries
            addLog(text: "teacher session:- drop stale class-allowlist-changed version \(version) (applied \(appliedAllowlistVersion))")
            return;
        }
        appliedAllowlistVersion = version

        //C4 hot-sync:- enforcement reads currentRunningFocusType live every tick so mutating the dict is enough, no restart
        currentRunningFocusType["allowed_apps"] = dictionary["allowed_apps"] as? [String] ?? []
        currentRunningFocusType["allowed_urls"] = dictionary["allowed_urls"] as? [String] ?? []
        // Teacher sessions are allowlist-based (block everything except allowed_apps/allowed_urls), so
        // there's no explicit blocklist — keep it empty, matching session start. (Was a no-op self-read.)
        currentRunningFocusType["blockUrlsArray"] = [String]()
        // Teacher can hot-toggle whether not-allowed sites get an AI relevance check before blocking
        // (see startTeacherSession for the property contract/default).
        currentRunningFocusType["isAiBlockingEnabledForAllowList"] = dictionary["ai_blocking_enabled"] as? Bool ?? false
        appdelegate?.checkFcousAllowedApp()// immediate re-eval of the front app; url timer re-scans on its next tick
        addLog(text: "teacher session:- allow-list hot-synced to version \(version)")
    }

    func handleSessionEnded(dictionary:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: dictionary)
        // If the student had declined this session (never active) and it's now ended, drop the stored
        // re-join entry so the menu item disappears (#2267). Handled before the active-session guard
        // below, which would otherwise early-return for a session that was never joined.
        if let declined = declinedJoinableSessionDic, getSessionIdFromDictionary(dictionary: declined) == sessionId{
            clearDeclinedJoinableSession()
        }
        if sessionId.isEmpty || sessionId != activeTeacherSessionId{
            return;
        }
        addLog(text: "teacher session:- class-session-ended received")
        isTeacherSessionEndAllowed = true
        teacherSessionFinished(reason: "ended by teacher")

        var title = "Class focus session ended"
        var body = "Your teacher has ended the class focus session."
        if let teacherSessionInfo = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary{
            title = teacherSessionInfo.value(forKey: "sessionEndedTitle") as? String ?? title
            body = teacherSessionInfo.value(forKey: "sessionEndedBody") as? String ?? body
        }
        showCustomAlert(title: title, body: body, buttonOkText: "OK", buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in

        })
    }

    func handleUnlockResolved(dictionary:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: dictionary)
        if sessionId.isEmpty || sessionId != activeTeacherSessionId{
            return;
        }
        let status = (dictionary["status"] as? String ?? "").lowercased()
        addLog(text: "teacher session:- class-unlock-resolved received with status \(status)")
        if status == "rejected" || status == "expired"{// approvals arrive as class-allowlist-changed, no handling needed here
            let requested = dictionary["requested_app"] as? String ?? dictionary["requested_domain"] as? String ?? ""
            var title = "Unlock request declined"
            var body = "Your teacher declined your unlock request."
            if let teacherSessionInfo = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary{
                title = teacherSessionInfo.value(forKey: "unlockDeclinedTitle") as? String ?? title
                body = teacherSessionInfo.value(forKey: "unlockDeclinedBody") as? String ?? body
            }
            if !requested.isEmpty{
                body = body + " (\(requested))"
            }
            showCustomAlert(title: title, body: body, buttonOkText: "OK", buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in

            })
        }
    }

    //***********C2 join prompt + start (requirement:- no start without approval)***************//

    func showJoinPrompt(sessionDic:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: sessionDic)
        if sessionId.isEmpty{
            return;
        }
        if pendingInviteSessionId == sessionId{// prompt already showing for this session
            return;
        }
        pendingInviteSessionId = sessionId

        addLog(text: "teacher session:- showing PACT invite prompt for session \(sessionId)")
        showTeacherPactInvitePrompt(sessionDic: sessionDic)
    }

    // "<subject> · <topic>" line under the invite title, falling back to whichever of subject/topic/name
    // the session carries (backend may only send `name` today, so this degrades gracefully).
    func teacherSessionSubtitle(sessionDic:[String:Any])->String{
        let subject = (sessionDic["subject"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let topic = (sessionDic["topic"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var parts = [subject, topic].filter { !$0.isEmpty }
        if parts.isEmpty{
            let name = (sessionDic["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty{ parts = [name] }
        }
        return parts.joined(separator: " · ")
    }

    // Human "h:mm a" form of the session's scheduled finish time (e.g. "2:50 PM"); empty for an open-ended
    // session so the card can drop the "Ends …" wording gracefully.
    func teacherSessionEndTimeString(sessionDic:[String:Any])->String{
        let finishTimeString = sessionDic["scheduled_finish_time"] as? String ?? ""
        guard let finishTime = getDateFromStringInUtc(date: finishTimeString, dateFormat: teacherSessionDateFormat) else{
            return ""
        }
        return getDisplayStringFromDate(date: finishTime, dateFormat: "h:mm a")
    }

    // The allowed-site chips shown on the invite: the session's allowed URLs, falling back to allowed apps
    // if no URLs were set.
    func teacherSessionAllowedSites(sessionDic:[String:Any])->[String]{
        let urls = (sessionDic["allowed_urls"] as? [String] ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !urls.isEmpty{
            return urls
        }
        return (sessionDic["allowed_apps"] as? [String] ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    // Present the SwiftUI PACT invite card (screen A) with its friction decline flow (screen B). Activate
    // ⇒ the existing join path; Decline ⇒ store the re-joinable session (#2267) + POST the decline WITH the
    // student's typed reason. The window is non-closable so the student must pick one — closing paths clear
    // pendingInviteSessionId so a later invite can re-prompt.
    func showTeacherPactInvitePrompt(sessionDic:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: sessionDic)
        closeTeacherPactInviteWindowIfVisible()
        let vc = TeacherPactInviteHostingController(
            subtitle: teacherSessionSubtitle(sessionDic: sessionDic),
            endTime: teacherSessionEndTimeString(sessionDic: sessionDic),
            allowedSites: teacherSessionAllowedSites(sessionDic: sessionDic),
            onActivate: { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.closeTeacherPactInviteWindowIfVisible()
                    self.pendingInviteSessionId = nil
                    addLog(text: "[user-action] teacher session:- PACT activated")
                    self.joinTeacherSession(sessionDic: sessionDic)
                }
            },
            onDecline: { [weak self] reason in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.closeTeacherPactInviteWindowIfVisible()
                    self.pendingInviteSessionId = nil
                    let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
                    addLog(text: "[user-action] teacher session:- PACT declined with reason (len \(trimmed.count))")
                    // Keep the session so the student can re-join from the status-bar menu (#2267).
                    self.declinedJoinableSessionDic = sessionDic
                    self.refreshMenuForJoinableSession()
                    allApiObject.declineClassSession(sessionId: sessionId, reason: trimmed, completionHandler: {result in

                    })
                }
            })
        let window = NSWindow(contentViewController: vc)
        window.title = appName
        window.styleMask.remove(.miniaturizable)
        window.styleMask.remove(.resizable)
        window.styleMask.remove(.closable)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        window.center()
        teacherPactInviteWindow = window
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // The class-session-invite pusher event (app already running) carries NO allow-list, so its chips
        // would be empty. Fetch the live session and refresh them once it returns. (The launch path already
        // builds the card from getCurrentClassSession, so its list is present up front.)
        allApiObject.getCurrentClassSession(completionHandler: { [weak self, weak vc] newDic in
            DispatchQueue.main.async {
                guard let self = self, let vc = vc, let dic = newDic as? [String: Any] else { return }
                guard self.getSessionIdFromDictionary(dictionary: dic) == sessionId else { return }   // same session only
                let fresh = self.teacherSessionAllowedSites(sessionDic: dic)
                if !fresh.isEmpty { vc.sitesModel.allowedSites = fresh }   // don't wipe a good list with an empty fetch
            }
        })
    }

    func closeTeacherPactInviteWindowIfVisible(){
        if teacherPactInviteWindow != nil{
            if teacherPactInviteWindow?.isVisible ?? false{
                teacherPactInviteWindow?.close()
            }
            teacherPactInviteWindow = nil
        }
    }

    func joinTeacherSession(sessionDic:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: sessionDic)
        if sessionId.isEmpty{
            return;
        }
        allApiObject.joinClassSession(sessionId: sessionId, completionHandler: {newDic in
            DispatchQueue.main.async {
                if let newDic = newDic as? [String:Any]{
                    self.startTeacherSession(sessionDic: newDic)
                }else{
                    addLog(text: "teacher session:- join api failed for session \(sessionId)")
                    // The session couldn't be joined (most likely it ended) — drop the stored re-join
                    // entry so the menu item disappears (#2267).
                    self.clearDeclinedJoinableSession()
                    showCustomAlert(title: "Could not join the class session", body: "The class focus session is no longer active or could not be joined. Please ask your teacher to start it again.", buttonOkText: "OK", buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in

                    })
                }
            }
        })
    }

    //***********C2b re-join a declined/dismissed session (#2267)***************//

    // True when there's a class session the student declined that is still live and no session is
    // currently active — i.e. the "A class focus session is running / Join session" menu item should show.
    func hasJoinableSession()->Bool{
        return !isTeacherSessionActive() && declinedJoinableSessionDic != nil
    }

    // Name of the declined-but-joinable session (shown under the menu card's title). Empty if none.
    var declinedJoinableSessionName:String{
        return declinedJoinableSessionDic?["name"] as? String ?? ""
    }

    // Re-join the previously declined session (same path as accepting the original prompt). On success
    // startTeacherSession() clears the stored session; on failure joinTeacherSession() clears it.
    func joinDeclinedSession(){
        guard let sessionDic = declinedJoinableSessionDic else{
            return;
        }
        addLog(text: "[user-action] teacher session:- re-joining previously declined session from menu")
        joinTeacherSession(sessionDic: sessionDic)
    }

    func clearDeclinedJoinableSession(){
        if declinedJoinableSessionDic != nil{
            declinedJoinableSessionDic = nil
            refreshMenuForJoinableSession()
        }
    }

    // Refresh the status-bar menu so the "class session running / Join" item appears/disappears in step
    // with hasJoinableSession().
    func refreshMenuForJoinableSession(){
        DispatchQueue.main.async {
            menuViewControllerObj?.reloadIfNeeded()
        }
    }

    func startTeacherSession(sessionDic:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: sessionDic)
        if sessionId.isEmpty{
            return;
        }
        if activeTeacherSessionId == sessionId{// already running:- treat as an allow-list refresh
            handleAllowlistChanged(dictionary: sessionDic)
            return;
        }
        addLog(text: "teacher session:- starting teacher session \(sessionId)")

        // A session is now starting — drop any stored declined-but-joinable session so the menu re-join
        // item goes away (#2267).
        clearDeclinedJoinableSession()

        // the server force-finished any personal focus block on join, clean the local state silently
        if isFocusModeOnOrPaused(){
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
                    arrFocusType[i]["isOn"] = false
                    arrFocusType[i]["isPaused"] = false
                }
            }
        }
        isHardCorePomodoroModeOn = false

        let sessionName = sessionDic["name"] as? String ?? ""
        let allowedApps = sessionDic["allowed_apps"] as? [String] ?? []
        let allowedUrls = sessionDic["allowed_urls"] as? [String] ?? []

        let finishTimeString = sessionDic["scheduled_finish_time"] as? String ?? ""
        var finishTime = getDateFromStringInUtc(date: finishTimeString, dateFormat: teacherSessionDateFormat)
        if finishTime == nil{// open ended session:- mirror the backend 12h fallback
            finishTime = Calendar.current.date(byAdding: .hour, value: teacherSessionOpenEndedFallbackHours, to: Date())
        }
        // Round to the nearest minute (not truncate): the local end timer is minute-granular, and
        // truncating could schedule it up to ~59s BEFORE the scheduled finish while
        // canTeacherSessionFinishNow() only tolerates 30s early — that mismatch made the timer fire,
        // get rejected as "too early", and (being non-repeating) never auto-finish the session.
        // Rounding keeps the timer within ±30s of the true finish, inside that tolerance.
        let diffSeconds = Calendar.current.dateComponents([.second], from: Date(), to: finishTime!).second ?? 0
        var diffMinutes = Int((Double(diffSeconds) / 60.0).rounded())
        if diffMinutes < 1{
            diffMinutes = 1
        }

        activeTeacherSessionId = sessionId
        activeTeacherSessionTeamId = sessionDic["team_id"] as? String ?? ""
        activeTeacherSessionName = sessionName.isEmpty ? "Class focus session" : sessionName
        appliedAllowlistVersion = sessionDic["allowlist_version"] as? Int ?? 1
        teacherSessionScheduledFinishTime = finishTime
        isTeacherSessionEndAllowed = false

        startFocusModeTime = Date()
        endFocusModeTime = finishTime
        currentFocusModeStrictness = ._SUPER_STRICT_
        addLog(text: "teacher session:- focus mode is super strict mode")
        whatToAchieveInFocusBlock = activeTeacherSessionName

        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            setAppIconForFocusModeScore(probability: nil)
            timerForFocusModeEndNotification = nil
        }
        
        
        
        // Joining a class session pushes any routine/summary/break currently on screen past the
        // session end (diffMinutes + 1) so it doesn't compete with the teacher session.
        isRoutinePostponedByTeacherSession = false
        if currentState == ._MORNING_HABIT_{
            getHabitsVcObject().postponeMorningHabitFor(minutes: diffMinutes + 1, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
            isRoutinePostponedByTeacherSession = true
        }else if currentState == ._EVENING_HABIT_{
            getHabitsVcObject().postponeEveningHabitFor(minutes: diffMinutes + 1, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
            isRoutinePostponedByTeacherSession = true
        }else if currentState == ._FOCUS_SUMMARY_{
            getHabitsVcObject().postponeFocusSummaryFor(minutes: diffMinutes + 1, showAskIntention:false)
            isRoutinePostponedByTeacherSession = true
        }else if currentState == ._CUSTOM_ROUTINE_{
            getHabitsVcObject().postponeCustomRoutineFor(minutes: diffMinutes + 1, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false, fromRoutineWarning:false)
        }else if currentState == ._MICRO_BREAK_{
            if breakWarningWcObj != nil{
                if breakWarningWcObj?.window?.isVisible ?? false{
                    breakWarningVcObj?.timer?.invalidate()
                    breakWarningWcObj?.window?.close()
                }
            }
            getHabitsVcObject().postponeBreakActivitiesFor(minutes: diffMinutes + 1, secondsToPostpone: nil, isFromBreakWarningWindow:false)
        }
        

        
        appdelegate?.setFocusModeTimer(hour: nil, minute: diffMinutes)

        //focusButtonService
        focusButtonServiceObject.startFocusSession(seconds: diffMinutes*60)

        // Set explicitly before focusModeStartted() — the teacher dict isn't in arrFocusType, so
        // focusModeStartted()'s own "find the isOn entry in arrFocusType" loop can't populate it
        // and leaves currentRunningFocusType untouched either way. Setting it first matters because
        // focusModeStartted() synchronously calls frontApplicationChanged() at its end (to catch the
        // already-frontmost app), which is what actually starts the URL-blocking timer
        // (setTimeCheckUrlsForFocusMode) — previously that first call ran against the stale/previous
        // session's currentRunningFocusType, so the URL timer wasn't (re)started until whatever app
        // the student had open happened to trigger the next real app-activation event. A student who
        // stayed in an already-open, disallowed browser tab could go unblocked for a while.
        currentRunningFocusType = [
            "id": "teacher-" + sessionId,
            "name": activeTeacherSessionName,
            "color": "",
            "allowed_apps": allowedApps,
            "allowed_urls": allowedUrls,
            "blockUrlsArray": [String](),
            "isOn": false,
            "isAllowedAllApps": false,
            "isAllowedListApproach": true,
            "isTeacherSession": true,
            // API contract: sessionDic["ai_blocking_enabled"] (Bool). When true, a site not on
            // allowed_urls still gets the AI relevance check (chatGPTIsURLSafe) before blocking, same
            // as a regular intention-based focus mode. When false/absent, it's blocked immediately —
            // the teacher's allow-list is a closed list, so "not on it" is already a deterministic
            // decision and doesn't need AI judgment. Defaults to false so this is safe to ship ahead
            // of the backend/web sending the property.
            "isAiBlockingEnabledForAllowList": sessionDic["ai_blocking_enabled"] as? Bool ?? false,
            "tags": [String]()
        ]
        isFocusModeRunning = true

        appdelegate!.focusModeStartted(isStartedByPusher: true)

        startHeartbeatTimer()
        sendTeacherSessionHeartbeat()// immediate first beat so the teacher roster updates right away
        appdelegate?.checkFcousAllowedApp()

        // #2786: render the teacher's checklist natively in the Focus Session tab (parity with
        // windows#1611), instead of handing it to the webview. Back up the student's personal queue,
        // remember the class_session_id, and load the checklist from the join payload into
        // focusModeTaskString — the native ongoing-session screen reads that global. The TodoPlayer
        // webview stays headless and still receives tasks:[] + class_session_id for its blocking role.
        // Only on this committed start path, so an aborted start never strands the personal tasks.
        personalFocusTaskStringBackup = focusModeTaskString
        classSessionTodoSessionId = sessionId
        arrCurrentFocusTasks = []
        applyClassChecklistPayload(sessionDic)

        // #2216: force a fresh TodoPlayer load so it re-reads the class-session metadata (class_session_id
        // + empty tasks) even when its tab was ALREADY selected — an already-loaded webview otherwise
        // keeps showing the student's stale personal task list. Mirrors the pusher focus-mode-started flow.
        if !getTaskPlayerVcObject().isViewLoaded{
            getTaskPlayerVcObject().loadView()
        }
        getTaskPlayerVcObject().loadRequest()
        shouldReloadTaskPlayer = true

        // Mirror the normal focus-start post-start UX (see focusModeData startFocusMode). Without this,
        // a student who joins while sitting on the Start Focus Session tab would keep seeing that stale
        // view — joining must move them into the active-session UI. Auto: surface the task player;
        // otherwise load it and close the main window so the focus tab next renders FocusModeStateVC
        // for the now-active class session.
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
            showRunningFocusSessionWindow()
        }else{
            if !getTaskPlayerVcObject().isViewLoaded{
                getTaskPlayerVcObject().loadView()
            }
            taskPlayerVcObj?.reloadData(totalDuration: diffMinutes, intention: whatToAchieveInFocusBlock)
            shouldReloadTaskPlayer = false
            mainWindowControllerObj?.window?.close()
        }
    }

    //***********Class checklist (native, #2786)***************//

    /// Loads the teacher's checklist from a class-session payload (the join response or
    /// `GET /class-session/current`) into the native focus-session queue and remembers its
    /// `tasks_version`. The native ongoing-session screen renders `focusModeTaskString`, so this is what
    /// makes the checklist visible — and tickable — instead of the removed webview checklist.
    func applyClassChecklistPayload(_ payload: [String: Any]){
        if let parsed = ClassSessionChecklistParser.parse(payload){
            focusModeTaskString = FocusSessionTaskQueue.encode(parsed.tasks)
            classSessionTasksVersion = parsed.version
            addLog(text: "teacher session:- loaded \(parsed.tasks.count) class checklist task(s), version \(parsed.version)")
        }else{
            focusModeTaskString = "[]"
            addLog(text: "teacher session:- class checklist payload carried no tasks array")
        }
        refreshFocusSessionScreenIfVisible()
    }

    /// Pusher `class-session-tasks-updated`: the teacher amended the checklist. Refetch the
    /// authoritative list + this student's ticks when the event's `tasks_version` is newer than held.
    func handleClassTasksUpdated(dictionary: [String: Any]){
        guard isTeacherSessionActive() else { return }
        let incoming = (dictionary["tasks_version"] as? Int)
            ?? Int((dictionary["tasks_version"] as? String) ?? "")
            ?? 0
        if incoming > classSessionTasksVersion{
            addLog(text: "teacher session:- class-session-tasks-updated v\(incoming) > held v\(classSessionTasksVersion), refetching")
            refetchClassChecklist()
        }else{
            addLog(text: "teacher session:- class-session-tasks-updated v\(incoming) not newer than held v\(classSessionTasksVersion), ignoring")
        }
    }

    /// Refetch the authoritative checklist + this student's ticks after a `class-session-tasks-updated`
    /// Pusher event whose `tasks_version` is newer than the one held. Ignored when no class session is
    /// active (a stale event after the session ended).
    func refetchClassChecklist(){
        guard isTeacherSessionActive(), !classSessionTodoSessionId.isEmpty else { return }
        allApiObject.getCurrentClassSession(completionHandler: { newDic in
            DispatchQueue.main.async {
                guard let dict = newDic as? [String: Any], self.isTeacherSessionActive() else { return }
                self.applyClassChecklistPayload(dict)
            }
        })
    }

    /// Re-render the native ongoing-session screen if it's on screen, so a checklist load or a teacher
    /// amendment appears immediately.
    private func refreshFocusSessionScreenIfVisible(){
        if focusModeStateVcObj?.isViewVisible ?? false{
            focusModeStateVcObj?.reloadData()
        }
    }

    #if DEBUG
    /// A class session for the UI tests, joined exactly as an accepted invite joins one.
    func startForUITests(sessionDic:[String:Any]){
        isUITestSession = true
        startTeacherSession(sessionDic: sessionDic)
    }
    #endif

    //***********C3 early-stop lock***************//

    func canTeacherSessionFinishNow()->Bool{
        if isTeacherSessionEndAllowed{
            return true
        }
        if let finishTime = teacherSessionScheduledFinishTime{
            // 30 seconds of tolerance for the local end timer firing marginally before the scheduled finish time
            if let toleratedFinishTime = Calendar.current.date(byAdding: .second, value: -30, to: finishTime){
                if Date().compare(toleratedFinishTime) == .orderedDescending{
                    return true
                }
            }
        }
        return false
    }

    func showTeacherSessionLockedAlert(){
        var title = "This session is controlled by your teacher"
        var body = "You can't stop or pause this focus session early. It ends when your teacher ends it or the scheduled finish time is reached. Need an app or website unlocked? Send your teacher an unlock request."
        var buttonRequestUnlockText = "Request unlock"
        if let teacherSessionInfo = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary{
            title = teacherSessionInfo.value(forKey: "lockedAlertTitle") as? String ?? title
            body = teacherSessionInfo.value(forKey: "lockedAlertBody") as? String ?? body
            buttonRequestUnlockText = teacherSessionInfo.value(forKey: "buttonRequestUnlock") as? String ?? buttonRequestUnlockText
        }
        showCustomAlert(title: title, body: body, buttonOkText: buttonRequestUnlockText, buttonCancelText: "OK", checkBoxText: nil, autoClose: false, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in
            DispatchQueue.main.async {
                if isOkClicked{
                    self.showTeacherUnlockRequestWindow()
                }
            }
        })
        customAlertVcObj?.view.setUITestLandmark(UITestContract.Identifier.TeacherSession.lockedAlert)
    }

    // legit end only:- class-session-ended event or scheduled_finish_time reached
    func teacherSessionFinished(reason:String){
        if activeTeacherSessionId == nil{
            return;
        }
        addLog(text: "teacher session:- finished, reason:- \(reason)")
        let sessionName = activeTeacherSessionName

        stopHeartbeatTimer()
        activeTeacherSessionId = nil
        isUITestSession = false
        activeTeacherSessionTeamId = nil
        activeTeacherSessionName = ""
        appliedAllowlistVersion = 0
        teacherSessionScheduledFinishTime = nil
        isTeacherSessionEndAllowed = false
        closeTeacherUnlockRequestWindowIfVisible()

        // local cleanup mirrors the pusher focus-mode-finished handler (the server already finished the block, no api call here)
        // #2786: during a class session focusModeTaskString held the teacher's checklist (not the
        // student's personal tasks) — do NOT sync it back as personal work. Restore the personal tasks
        // captured at session start and clear the class-session state (guaranteed finish path).
        if classSessionTodoSessionId.isEmpty{
            taskPlayerVcObj?.getToDosFromPlayer()
        }else{
            focusModeTaskString = personalFocusTaskStringBackup
            classSessionTodoSessionId = ""
            personalFocusTaskStringBackup = ""
            classSessionTasksVersion = 0
        }
        setAppIconForFocusModeScore(probability: nil)
        isSkipBreakActivityDuringFocus = false
        lastFocusModeTempInfo = nil
        unfocusedTime = 0

        playFocusPomodorBreakEndsSound()
        endFocusModeTime = nil

        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }

        if focusEndWarningWcObj != nil{
            if focusEndWarningWcObj?.window?.isVisible ?? false{
                focusEndWarningWcObj?.window?.close()
            }
        }

        let totalSeconds = Int(Date().timeIntervalSince(startFocusModeTimeForPauseAndResume ?? Date()))
        focusModeActualDurationPerformed += totalSeconds

        focusModeFinishedCapturePosthog()

        isHardCorePomodoroModeOn = false
        isFocusModeRunning = false

        appdelegate!.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
        appdelegate!.statusbutton?.title = ""

        focusModeHelper.stopUrlTimer()
        appdelegate!.timerCheckAllowedApps?.invalidate()

        //focusButtonService
        focusButtonServiceObject.finishFocusSession()

        arrKeywordsToAllowInFocus.removeAll()

        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        addEntryInStatsCsv(logType: "focus block", activity: sessionName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")

        currentRunningFocusType = [String:Any]()
        currentFocusModeStrictness = ._NORMAL_

        closePupUpBlockIfVisible()
        menuViewControllerObj?.reloadIfNeeded()
        menuViewControllerObj?.stopFocusModeCountDownTimer()
        closeNudgeFocusAlignmentScoreWindow()

        leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
        leftMenuVcObj?.resetFocusModeTitle()

        // If the class session ends while the student is sitting on the Focus Session left tab, that
        // tab is still showing FocusModeStateVC for the just-finished session. Re-render the Focus
        // Session view (only when it's the selected tab and the main window is visible) so it rebuilds
        // to the Start Focus Session view now that no session is active — geek mode uses the pomodoro
        // view, otherwise the simple pomodoro view (matching how that tab is normally shown).
        if mainWindowControllerObj?.window?.isVisible ?? false{
            if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                if SettingsManagerObject.isGeekModeEnabled{
                    appdelegate?.menuShowPomodoroModeView()
                }else{
                    appdelegate?.menuShowSimplePomodoroModeView()
                }
            }else if leftMenuVcObj?.boxTodoPlayer.isSelected ?? false{
                // #2216 Scenario 2: if the class session ends while the student is sitting on the Todo
                // Player tab, that tab is still showing the FE-owned class checklist webview. The
                // personal tasks were restored into focusModeTaskString above, but the visible view
                // isn't refreshed until the tab is reselected. Re-render it here: now that
                // isFocusModeRunning is false, showTaskView() swaps the class-checklist player for the
                // personal Todo List tool (reloaded), so the personal tasks come back immediately
                // instead of only on a manual tab switch / app restart.
                mainViewControllerObj?.showTaskView()
            }
        }
        refreshFocusModeData()
        
        
        
        // Auto-resume a routine we postponed for this class session. On join we pushed the
        // morning/evening routine or focus summary past the session (diffMinutes + 1); now that the
        // session has ended, drop that postpone so the still-due routine comes back straight away
        // instead of waiting out the full postpone:
        //   • state → ._NOTHING_ and clear the saved postpone → backgroundThread re-surfaces the due
        //     routine on its next tick (the teacher guard that suppressed it is gone now).
        //   • cancel habitsVc.postponeTimer → it was armed by postponeMorning/Evening/FocusSummaryFor
        //     to fire resumeMorning/Evening/FocusSummary at diffMinutes+1; killing it stops that
        //     timer-based resume from firing a second time on top of the immediate one.
        if isRoutinePostponedByTeacherSession{
            if currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
                addLog(text: "teacher session:- ended, auto-resuming routine postponed for the session (was \(currentState))")
                currentState = ._NOTHING_
                // Clear the saved postpone so ._POSTPONE_.. state isn't restored on the next launch.
                UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
                UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)

                // Cancel the postpone's own resume timer so it doesn't re-fire at diffMinutes+1.
                if let habitsVcObj = habitsVcObj{
                    if habitsVcObj.postponeTimer != nil{
                        habitsVcObj.stopPostponeEndTimer()
                        addLog(text: "teacher session:- cancelled the routine postpone timer")
                    }
                }
            }
            isRoutinePostponedByTeacherSession = false
        }
    }

    //***********C5 heartbeat + quit + next-launch adoption***************//

    func startHeartbeatTimer(){
        stopHeartbeatTimer()
        timerTeacherSessionHeartbeat = Timer.scheduledTimer(timeInterval: teacherSessionHeartbeatIntervalSeconds, target: self, selector: #selector(self.sendTeacherSessionHeartbeat), userInfo: nil, repeats: true)
        RunLoop.main.add((timerTeacherSessionHeartbeat!), forMode: RunLoop.Mode.common)
    }

    func stopHeartbeatTimer(){
        timerTeacherSessionHeartbeat?.invalidate()
        timerTeacherSessionHeartbeat = nil
    }

    @objc func sendTeacherSessionHeartbeat(){
        guard let sessionId = activeTeacherSessionId, !isUITestSession else{
            stopHeartbeatTimer()
            return;
        }
        allApiObject.classSessionHeartbeat(sessionId: sessionId, inFocus: isFocusModeOn(), completionHandler: {result in

        })
    }

    // best-effort final beat on quit; the server also infers quit from the heartbeat gap
    func sendFinalHeartbeatBeforeTerminate(){
        guard let sessionId = activeTeacherSessionId, !isUITestSession else{
            return;
        }
        addLog(text: "teacher session:- sending final heartbeat before terminate")
        let responsePath = "\(baseUrl)/class-session/\(sessionId)/heartbeat"
        if let responsePathUrl = NSURL(string: responsePath){
            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let json = classSessionHeartbeatBody(inFocus: false)
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: .now() + 2)// don't hold up termination for more than 2 seconds
        }
    }

    // next-launch adoption:- active+unjoined shows the prompt, joined rebuilds the dict + resumes
    func adoptCurrentSessionOnLaunch(){
        allApiObject.getCurrentClassSession(completionHandler: {newDic in
            DispatchQueue.main.async {
                guard let newDic = newDic as? [String:Any] else{
                    return;
                }
                let status = newDic["status"] as? String ?? ""
                if status != "live"{
                    return;
                }
                let joinStatus = newDic["join_status"] as? String ?? ""
                if joinStatus == "joined"{
                    addLog(text: "teacher session:- adopting joined session on launch")
                    self.startTeacherSession(sessionDic: newDic)
                }else if joinStatus == "invited"{
                    addLog(text: "teacher session:- live invitation found on launch")
                    self.showJoinPrompt(sessionDic: newDic)
                }
            }
        })
    }

    //***********C6 unlock request***************//

    func showTeacherUnlockRequestWindow(prefillAppOrUrl: String = ""){
        guard let sessionId = activeTeacherSessionId else{
            return;
        }
        closeTeacherUnlockRequestWindowIfVisible()
        let vc = teacherUnlockRequestVc()
        vc.sessionId = sessionId
        vc.prefillAppOrUrl = prefillAppOrUrl
        let window = NSWindow(contentViewController: vc)
        window.title = appName
        window.styleMask.remove(.miniaturizable)
        window.styleMask.remove(.resizable)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        window.center()
        teacherUnlockRequestWindow = window
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func closeTeacherUnlockRequestWindowIfVisible(){
        if teacherUnlockRequestWindow != nil{
            if teacherUnlockRequestWindow?.isVisible ?? false{
                teacherUnlockRequestWindow?.close()
            }
            teacherUnlockRequestWindow = nil
        }
    }
}

//***********C7 PACT invite popup (SwiftUI) — 2 screens: invite + friction decline-with-reason***************//

// The card width, and how long the student must hold to decline (the "deliberate friction" is the point).
let kTeacherPactWidth: CGFloat = 440
private let kTeacherPactHoldSeconds: Double = 15

// Fonts: reuse the app's bundled faces so the card matches the rest of the UI.
private func pactBold(_ s: CGFloat) -> Font { Font(getBoldFont(size: s)) }
private func pactMedium(_ s: CGFloat) -> Font { Font(getMediumFont(size: s)) }
private func pactRegular(_ s: CGFloat) -> Font { Font(getRegularFont(size: s)) }

// Peach/cream teacher-mode palette (light-mode card; the invite is a modal takeover so it doesn't need
// to theme to dark). One place so the chips, notes and buttons stay in sync.
// Resolves to `light` in a light appearance and `dark` in dark, so the PACT card adapts to Dark Mode like
// the app's other SwiftUI screens (e.g. BreakWarningView) instead of staying a white panel. Backed by a
// dynamic NSColor so it re-resolves live when the system appearance changes. Light values are unchanged
// from the original palette, so Light Mode looks exactly as before.
private func pactAdaptive(_ light: (CGFloat, CGFloat, CGFloat), _ dark: (CGFloat, CGFloat, CGFloat)) -> Color {
    Color(NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let c = isDark ? dark : light
        return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
    })
}

private enum PactPalette {
    static let cream    = pactAdaptive((1.0, 0.957, 0.914), (0.11, 0.105, 0.10))   // page behind the panel
    static let card     = pactAdaptive((1.0, 1.0, 1.0),     (0.17, 0.165, 0.16))   // the raised card
    static let accent   = Color(NSColor(named: "dark_OrangeColor") ?? .systemOrange) // app-wide button orange
    static let chipBg   = pactAdaptive((1.0, 0.925, 0.835), (0.28, 0.20, 0.09))
    static let chipText = pactAdaptive((0.62, 0.36, 0.10),  (0.98, 0.80, 0.55))
    static let noteBg   = pactAdaptive((1.0, 0.90, 0.78),   (0.30, 0.21, 0.09))
    static let noteText = pactAdaptive((0.52, 0.30, 0.06),  (0.99, 0.83, 0.60))
    static let title    = pactAdaptive((0.20, 0.18, 0.15),  (0.96, 0.95, 0.93))
    static let subtitle = pactAdaptive((0.45, 0.42, 0.38),  (0.70, 0.68, 0.65))
    static let bodyText = pactAdaptive((0.30, 0.28, 0.25),  (0.86, 0.85, 0.83))
}

// Every user-facing string on the card, resolved from config (`teacherSessionInfo`) at present-time with
// English fallbacks, and with the end-time already substituted where it appears.
struct TeacherPactStrings {
    let inviteTitle: String
    let youCanUseHeader: String
    let endsLine: String        // "Ends 2:50 PM" (empty when the session is open-ended)
    let inviteBody: String      // <TIME> already substituted
    let activateButton: String
    let declineLink: String
    let beforeDeclineTitle: String
    let beforeDeclineBody: String
    let reportNote: String
    let whyDecliningLabel: String
    let reasonHelper: String
    let reasonPlaceholder: String
    let holdToDecline: String
    let keepHoldingTemplate: String  // "Keep holding, <N>s"
    let mindfulNote: String
    let backToJoinLink: String
}

func makeTeacherPactStrings(endTime: String) -> TeacherPactStrings {
    let timeToken = endTime.isEmpty
        ? teacherSessionLocalized("pactEndFallback", "the session ends")
        : endTime
    let endsLine = endTime.isEmpty ? "" :
        teacherSessionLocalized("pactEndsLine", "Ends <TIME>").replacingOccurrences(of: "<TIME>", with: endTime)
    let body = teacherSessionLocalized("pactInviteBody",
        "Everything else is paused until <TIME>. If you need another site, you can ask your teacher to add it. You cannot end the session early.")
        .replacingOccurrences(of: "<TIME>", with: timeToken)
    return TeacherPactStrings(
        inviteTitle: teacherSessionLocalized("pactInviteTitle", "Your teacher invited you to join a PACT session"),
        youCanUseHeader: teacherSessionLocalized("pactYouCanUseHeader", "YOU CAN USE"),
        endsLine: endsLine,
        inviteBody: body,
        activateButton: teacherSessionLocalized("pactActivateButton", "Activate the PACT"),
        declineLink: teacherSessionLocalized("pactDeclineLink", "Decline"),
        beforeDeclineTitle: teacherSessionLocalized("pactBeforeDeclineTitle", "Before you decline"),
        beforeDeclineBody: teacherSessionLocalized("pactBeforeDeclineBody",
            "Declining is allowed but it will be reported to your teacher. Once in a while is genuinely fine, nobody is going to chase you over one lesson."),
        reportNote: teacherSessionLocalized("pactDeclineReportNote",
            "If you decline most lessons, it shows up in your teacher's report and they will want a conversation about how the laptop is going for you."),
        whyDecliningLabel: teacherSessionLocalized("pactWhyDecliningLabel", "WHY ARE YOU DECLINING?"),
        reasonHelper: teacherSessionLocalized("pactReasonHelper", "Your teacher will see this alongside your name."),
        reasonPlaceholder: teacherSessionLocalized("pactReasonPlaceholder", "Type your reason here..."),
        holdToDecline: teacherSessionLocalized("pactHoldToDecline", "Hold for 15 seconds to decline"),
        keepHoldingTemplate: teacherSessionLocalized("pactKeepHolding", "Keep holding, <N>s"),
        mindfulNote: teacherSessionLocalized("pactMindfulNote",
            "Please be mindful with how you use your laptop. Research shows that students who play games, watch videos and so on distract their classmates as well."),
        backToJoinLink: teacherSessionLocalized("pactBackToJoinLink", "Actually, I'll join"))
}

// UPPER clamp for the card window: never taller than the visible screen, so the hold button / links stay
// reachable on a laptop. This is only a MAX — the window is sized to fit each screen's ACTUAL content
// (see TeacherPactInviteHostingController.resizeWindowToFit), so the shorter invite screen no longer
// leaves an empty gap below the card. When a screen's content is taller than this, the ScrollView scrolls.
// (Previously this returned a fixed height with a 460 floor sized for the taller decline screen, which is
// what left the empty cream gap under the shorter invite card.)
func teacherPactMaxWindowHeight() -> CGFloat {
    let usable = NSScreen.main?.visibleFrame.height ?? 700
    return min(680, usable - 80)
}

// MARK: - Hosting controller

// Hosts `TeacherPactInviteView` in the invite window. Strings are resolved fresh here (present-time) so a
// config sync is reflected without a relaunch, mirroring how the other teacher-mode screens read config.
// Observable so the invite card can refresh its allowed-sites chips AFTER the popup is already showing:
// the class-session-invite pusher event carries no allow-list, so the presenter fetches the live session
// (getCurrentClassSession) and updates this — the SwiftUI view then re-renders and re-fits.
final class PactInviteSitesModel: ObservableObject {
    @Published var allowedSites: [String]
    init(allowedSites: [String]) { self.allowedSites = allowedSites }
}

final class TeacherPactInviteHostingController: NSViewController {
    private let subtitle: String
    private let endTime: String
    let sitesModel: PactInviteSitesModel
    private let onActivate: () -> Void
    private let onDecline: (String) -> Void

    init(subtitle: String, endTime: String, allowedSites: [String],
         onActivate: @escaping () -> Void, onDecline: @escaping (String) -> Void) {
        self.subtitle = subtitle
        self.endTime = endTime
        self.sitesModel = PactInviteSitesModel(allowedSites: allowedSites)
        self.onActivate = onActivate
        self.onDecline = onDecline
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var didInitialFit = false
    // Last height reported by the SwiftUI card. The first preference callback can arrive BEFORE the view
    // is in a window (view.window == nil), and for the static invite screen it never fires again — so we
    // remember it and apply the fit in viewDidAppear once the window exists.
    private var latestContentHeight: CGFloat = 0

    override func loadView() {
        let maxHeight = teacherPactMaxWindowHeight()
        var root = TeacherPactInviteView(
            strings: makeTeacherPactStrings(endTime: endTime),
            subtitle: subtitle,
            sitesModel: sitesModel,
            onActivate: onActivate,
            onDecline: onDecline)
        // Size the window to the CURRENT screen's actual content height (clamped to maxHeight) and
        // resize when the view toggles invite ↔ decline, so neither screen leaves an empty gap below the
        // card. Content taller than maxHeight scrolls inside the ScrollView.
        root.onContentHeight = { [weak self] h in self?.resizeWindowToFit(contentHeight: h) }
        let host = NSHostingView(rootView: root)
        // Start at the max height so the first layout has room to report its natural size; the callback
        // shrinks it to fit immediately (without animation on that first pass).
        host.frame = NSRect(x: 0, y: 0, width: kTeacherPactWidth, height: maxHeight)
        self.view = host
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // The window now exists; apply the most recent measured height (the initial preference callback
        // may have fired before attachment). A next-runloop retry covers the case where the measurement
        // hasn't arrived yet at appear-time.
        applyPendingFit()
        DispatchQueue.main.async { [weak self] in self?.applyPendingFit() }
    }

    private func applyPendingFit() {
        if latestContentHeight > 0 { resizeWindowToFit(contentHeight: latestContentHeight) }
    }

    /// Fit the window to the reported content height, clamped to the screen, keeping it centred. Called
    /// on first layout and whenever the SwiftUI card switches between the invite and decline screens.
    private func resizeWindowToFit(contentHeight: CGFloat) {
        guard contentHeight > 0 else { return }
        latestContentHeight = contentHeight
        guard let window = view.window else { return }   // not attached yet — viewDidAppear re-applies
        let target = min(contentHeight, teacherPactMaxWindowHeight())
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero,
                                                             size: NSSize(width: kTeacherPactWidth, height: target)))
        guard abs(frame.height - window.frame.height) > 0.5 else { return }
        if !didInitialFit {
            // First show: centre on screen.
            let vis = (window.screen ?? NSScreen.main)?.visibleFrame ?? frame
            frame.origin.x = vis.midX - frame.width / 2
            frame.origin.y = vis.midY - frame.height / 2
        } else {
            // invite <-> decline toggle: keep the TOP-LEFT corner fixed so the window grows/shrinks
            // downward in place instead of jumping back to centre. Clamp to stay on the visible screen.
            frame.origin.x = window.frame.origin.x
            frame.origin.y = window.frame.maxY - frame.height   // anchor the top edge
            if let vis = (window.screen ?? NSScreen.main)?.visibleFrame {
                if frame.maxY > vis.maxY { frame.origin.y = vis.maxY - frame.height }
                if frame.minY < vis.minY { frame.origin.y = vis.minY }
            }
        }
        // First fit snaps (no animating down from the oversized initial frame); later toggles animate.
        window.setFrame(frame, display: true, animate: didInitialFit)
        didInitialFit = true
    }
}

// MARK: - The card (screen A ↔ screen B)

// Reports the card's natural laid-out height so the hosting window can size to fit each screen (no gap).
private struct PactContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct TeacherPactInviteView: View {
    let strings: TeacherPactStrings
    let subtitle: String
    @ObservedObject var sitesModel: PactInviteSitesModel
    let onActivate: () -> Void
    let onDecline: (String) -> Void
    // Set by the hosting controller to size its window to the current screen's content height.
    var onContentHeight: ((CGFloat) -> Void)? = nil

    @SwiftUI.State private var showDecline = false
    @SwiftUI.State private var reason = ""
    @SwiftUI.State private var isHolding = false

    var body: some View {
        // showsIndicators: false hides the scroll bar (it flickered on/off as the window fits the content
        // exactly) WITHOUT changing the ScrollView or its scrolling — kept for the screen-clamp case.
        ScrollView(.vertical, showsIndicators: false) {
            card
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(PactPalette.card))
                .padding(16)
                .frame(width: kTeacherPactWidth)
                // Measure the actual card height (card + paddings) so the window can fit it exactly.
                .background(GeometryReader { geo in
                    Color.clear.preference(key: PactContentHeightKey.self, value: geo.size.height)
                })
        }
        .frame(width: kTeacherPactWidth)
        .background(PactPalette.cream.edgesIgnoringSafeArea(.all))
        .onPreferenceChange(PactContentHeightKey.self) { onContentHeight?($0) }
    }

    @ViewBuilder private var card: some View {
        if showDecline {
            declineScreen
        } else {
            inviteScreen
        }
    }

    // Screen A — INVITE
    private var inviteScreen: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 10) {
                Image("welcome_bear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 66, height: 66)
                Text(strings.inviteTitle)
                    .font(pactBold(19))
                    .foregroundColor(PactPalette.title)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(pactMedium(14))
                    .foregroundColor(PactPalette.subtitle)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            if !strings.endsLine.isEmpty {
                Text(strings.endsLine)
                    .font(pactMedium(13))
                    .foregroundColor(PactPalette.subtitle)
                    .frame(maxWidth: .infinity)
            }

            if !sitesModel.allowedSites.isEmpty {
                Text(strings.youCanUseHeader)
                    .font(pactBold(11))
                    .kerning(0.6)
                    .foregroundColor(PactPalette.subtitle)
                    .padding(.top, 4)
                PactChipsFlow(items: sitesModel.allowedSites)
            }

            Text(strings.inviteBody)
                .font(pactRegular(13))
                .foregroundColor(PactPalette.bodyText)
                .fixedSize(horizontal: false, vertical: true)

            SwiftUI.Button(action: onActivate) {
                Text(strings.activateButton)
                    .font(pactBold(15))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(PactPalette.accent))
                    .contentShape(Rectangle())
            }
            .buttonStyle(FBButtonStyle())
            .padding(.top, 4)

            SwiftUI.Button(action: { withAnimation { showDecline = true } }) {
                Text(strings.declineLink)
                    .font(pactMedium(13))
                    .foregroundColor(PactPalette.subtitle)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FBButtonStyle())
        }
    }

    // Screen B — BEFORE YOU DECLINE
    private var declineScreen: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.beforeDeclineTitle)
                .font(pactBold(19))
                .foregroundColor(PactPalette.title)

            Text(strings.beforeDeclineBody)
                .font(pactRegular(13))
                .foregroundColor(PactPalette.bodyText)
                .fixedSize(horizontal: false, vertical: true)

            noteBox(strings.reportNote)

            VStack(alignment: .leading, spacing: 6) {
                Text(strings.whyDecliningLabel)
                    .font(pactBold(11))
                    .kerning(0.6)
                    .foregroundColor(PactPalette.subtitle)
                PactReasonEditor(text: $reason, placeholder: strings.reasonPlaceholder)
                Text(strings.reasonHelper)
                    .font(pactRegular(11))
                    .foregroundColor(PactPalette.subtitle)
            }

            PactHoldToDeclineButton(
                enabled: !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                idleLabel: strings.holdToDecline,
                holdingLabelTemplate: strings.keepHoldingTemplate,
                onHoldingChanged: { holding in withAnimation(.easeInOut(duration: 0.2)) { isHolding = holding } },
                onComplete: { onDecline(reason) })

            // Shown only while holding — BELOW the hold button so its appearance grows the card downward
            // and the button stays put under the user's cursor (above it, it shifted the button mid-hold).
            if isHolding {
                noteBox(strings.mindfulNote)
            }

            SwiftUI.Button(action: { withAnimation { showDecline = false } }) {
                Text(strings.backToJoinLink)
                    .font(pactMedium(13))
                    .foregroundColor(PactPalette.accent)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(FBButtonStyle())
        }
    }

    private func noteBox(_ text: String) -> some View {
        Text(text)
            .font(pactMedium(12))
            .foregroundColor(PactPalette.noteText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(PactPalette.noteBg))
    }
}

// MARK: - Allowed-site chips (wrapping row, macOS 11 compatible)

// A wrapped row of pill chips. Uses the alignment-guide flow pattern (works on the macOS 11 deployment
// target, where the `Layout` protocol isn't available).
struct PactChipsFlow: View {
    let items: [String]
    @SwiftUI.State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geo in
            self.content(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func content(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                chip(item)
                    .padding([.trailing, .bottom], 6)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if index == items.count - 1 { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == items.count - 1 { height = 0 }
                        return result
                    }
            }
        }
        .background(heightReader($totalHeight))
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(pactMedium(12))
            .foregroundColor(PactPalette.chipText)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(PactPalette.chipBg))
    }

    private func heightReader(_ binding: SwiftUI.Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async { binding.wrappedValue = geo.frame(in: .local).size.height }
            return Color.clear
        }
    }
}

// MARK: - Reason editor (multi-line with placeholder)

struct PactReasonEditor: View {
    @SwiftUI.Binding var text: String
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(pactRegular(13))
                .foregroundColor(PactPalette.bodyText)
                .padding(6)
                .frame(height: 72)
            if text.isEmpty {
                Text(placeholder)
                    .font(pactRegular(13))
                    .foregroundColor(Color.gray.opacity(0.7))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 72)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.35), lineWidth: 1))
    }
}

// MARK: - Hold-to-decline button (Timer-driven 15s countdown; resets on release)

// The decline gate: the student must PRESS-AND-HOLD for the full `kTeacherPactHoldSeconds`. A Timer drives
// the countdown + progress bar; releasing early cancels and resets. Disabled (a no-op hold) until a reason
// is entered — decline requires BOTH a reason and the completed hold. The deliberate friction is the point.
struct PactHoldToDeclineButton: View {
    let enabled: Bool
    let idleLabel: String
    let holdingLabelTemplate: String
    let onHoldingChanged: (Bool) -> Void
    let onComplete: () -> Void

    @SwiftUI.State private var progress: CGFloat = 0
    @SwiftUI.State private var remaining: Int = Int(kTeacherPactHoldSeconds)
    @SwiftUI.State private var isHolding = false
    @SwiftUI.State private var startDate: Date? = nil
    @SwiftUI.State private var timer: Timer? = nil

    private var label: String {
        if isHolding {
            return holdingLabelTemplate.replacingOccurrences(of: "<N>", with: "\(max(remaining, 0))")
        }
        return idleLabel
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10).fill(PactPalette.accent.opacity(enabled ? 0.14 : 0.06))
                    RoundedRectangle(cornerRadius: 10).fill(PactPalette.accent.opacity(0.40))
                        .frame(width: geo.size.width * progress)
                }
            }
            Text(label)
                .font(pactBold(14))
                .foregroundColor(enabled ? PactPalette.accent : Color.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
        }
        .frame(height: 46)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(enabled ? PactPalette.accent : Color.gray.opacity(0.5), lineWidth: 1.5))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .pointingHandCursor()
        .opacity(enabled ? 1 : 0.6)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in cancelHold() }
        )
    }

    private func startHold() {
        guard enabled, !isHolding else { return }
        isHolding = true
        onHoldingChanged(true)
        startDate = Date()
        progress = 0
        remaining = Int(kTeacherPactHoldSeconds)
        let t = Timer(timeInterval: 0.05, repeats: true) { _ in
            guard let start = startDate else { return }
            let elapsed = Date().timeIntervalSince(start)
            progress = min(1, CGFloat(elapsed / kTeacherPactHoldSeconds))
            remaining = max(0, Int(ceil(kTeacherPactHoldSeconds - elapsed)))
            if elapsed >= kTeacherPactHoldSeconds {
                finishHold()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func cancelHold() {
        guard isHolding else { return }
        endTimer()
        isHolding = false
        onHoldingChanged(false)
        remaining = Int(kTeacherPactHoldSeconds)
        withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
    }

    private func finishHold() {
        endTimer()
        isHolding = false
        onHoldingChanged(false)
        progress = 1
        onComplete()
    }

    private func endTimer() {
        timer?.invalidate()
        timer = nil
        startDate = nil
    }
}
