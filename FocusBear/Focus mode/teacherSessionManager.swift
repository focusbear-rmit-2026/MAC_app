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

let teacherSessionManagerObject = teacherSessionManager()

class teacherSessionManager: NSObject {

    var activeTeacherSessionId:String?
    var activeTeacherSessionTeamId:String?
    var activeTeacherSessionName = ""
    var appliedAllowlistVersion = 0
    var teacherSessionScheduledFinishTime:Date?
    var isTeacherSessionEndAllowed = false// only true when class-session-ended arrived or scheduled finish time reached
    var pendingInviteSessionId:String?
    var timerTeacherSessionHeartbeat:Timer?
    var teacherUnlockRequestWindow:NSWindow?

    let teacherSessionHeartbeatIntervalSeconds:Double = 25// canonical 20-30s heartbeat interval
    let teacherSessionOpenEndedFallbackHours = 12// mirror backend fallback for sessions with no scheduled finish time
    let teacherSessionDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

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
        appdelegate?.checkFcousAllowedApp()// immediate re-eval of the front app; url timer re-scans on its next tick
        addLog(text: "teacher session:- allow-list hot-synced to version \(version)")
    }

    func handleSessionEnded(dictionary:[String:Any]){
        let sessionId = getSessionIdFromDictionary(dictionary: dictionary)
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

        let sessionName = sessionDic["name"] as? String ?? ""
        var title = "Your teacher started a class focus session"
        var body = "Join to start the focus session on this Mac. Only the apps and websites your teacher allowed will be usable, and you won't be able to stop the session early."
        var buttonJoinText = "Join session"
        var buttonDeclineText = "Decline"
        if let teacherSessionInfo = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary{
            title = teacherSessionInfo.value(forKey: "invitePromptTitle") as? String ?? title
            body = teacherSessionInfo.value(forKey: "invitePromptBody") as? String ?? body
            buttonJoinText = teacherSessionInfo.value(forKey: "buttonJoin") as? String ?? buttonJoinText
            buttonDeclineText = teacherSessionInfo.value(forKey: "buttonDecline") as? String ?? buttonDeclineText
        }
        if !sessionName.isEmpty{
            title = title + ":- \(sessionName)"
        }

        addLog(text: "teacher session:- showing join prompt for session \(sessionId)")
        showCustomAlert(title: title, body: body, buttonOkText: buttonJoinText, buttonCancelText: buttonDeclineText, checkBoxText: nil, autoClose: false, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in
            DispatchQueue.main.async {
                self.pendingInviteSessionId = nil
                if isOkClicked{
                    addLog(text: "[user-action] teacher session:- join prompt accepted")
                    self.joinTeacherSession(sessionDic: sessionDic)
                }else{
                    addLog(text: "[user-action] teacher session:- join prompt declined")
                    allApiObject.declineClassSession(sessionId: sessionId, completionHandler: {result in

                    })
                }
            }
        })
        NSApplication.shared.activate(ignoringOtherApps: true)
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
                    showCustomAlert(title: "Could not join the class session", body: "The class focus session is no longer active or could not be joined. Please ask your teacher to start it again.", buttonOkText: "OK", buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in

                    })
                }
            }
        })
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
        appdelegate?.setFocusModeTimer(hour: nil, minute: diffMinutes)

        //focusButtonService
        focusButtonServiceObject.startFocusSession(seconds: diffMinutes*60)

        appdelegate!.focusModeStartted(isStartedByPusher: true)

        // set explicitly after focusModeStartted because the teacher dict is not in arrFocusType
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
            "tags": [String]()
        ]
        isFocusModeRunning = true

        startHeartbeatTimer()
        sendTeacherSessionHeartbeat()// immediate first beat so the teacher roster updates right away
        appdelegate?.checkFcousAllowedApp()

        // Mirror the normal focus-start post-start UX (see focusModeData startFocusMode). Without this,
        // a student who joins while sitting on the Start Focus Session tab would keep seeing that stale
        // view — joining must move them into the active-session UI. Auto: surface the task player;
        // otherwise load it and close the main window so the focus tab next renders FocusModeStateVC
        // for the now-active class session.
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
            showTaskPlayerWindow(totalDuration: diffMinutes, intention: whatToAchieveInFocusBlock, automatically:true)
        }else{
            if !getTaskPlayerVcObject().isViewLoaded{
                getTaskPlayerVcObject().loadView()
            }
            taskPlayerVcObj?.reloadData(totalDuration: diffMinutes, intention: whatToAchieveInFocusBlock)
            shouldReloadTaskPlayer = false
            mainWindowControllerObj?.window?.close()
        }
    }

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
        activeTeacherSessionTeamId = nil
        activeTeacherSessionName = ""
        appliedAllowlistVersion = 0
        teacherSessionScheduledFinishTime = nil
        isTeacherSessionEndAllowed = false
        closeTeacherUnlockRequestWindowIfVisible()

        // local cleanup mirrors the pusher focus-mode-finished handler (the server already finished the block, no api call here)
        taskPlayerVcObj?.getToDosFromPlayer()
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
            }
        }
        refreshFocusModeData()
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
        guard let sessionId = activeTeacherSessionId else{
            stopHeartbeatTimer()
            return;
        }
        allApiObject.classSessionHeartbeat(sessionId: sessionId, inFocus: isFocusModeOn(), completionHandler: {result in

        })
    }

    // best-effort final beat on quit; the server also infers quit from the heartbeat gap
    func sendFinalHeartbeatBeforeTerminate(){
        guard let sessionId = activeTeacherSessionId else{
            return;
        }
        addLog(text: "teacher session:- sending final heartbeat before terminate")
        let responsePath = "\(baseUrl)/class-session/\(sessionId)/heartbeat"
        if let responsePathUrl = NSURL(string: responsePath){
            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let json: [String: Any] = [
                "in_focus": false,
                "device_id": currentDeviceId
            ]
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

    func showTeacherUnlockRequestWindow(){
        guard let sessionId = activeTeacherSessionId else{
            return;
        }
        closeTeacherUnlockRequestWindowIfVisible()
        let vc = teacherUnlockRequestVc()
        vc.sessionId = sessionId
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
