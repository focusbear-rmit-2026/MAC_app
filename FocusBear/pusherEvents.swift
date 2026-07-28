//
//  pusherEvents.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 02/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import PusherSwift

/// Decode a `focus-mode-*` event's JSON body. The payload is the same shape for every focus event
/// (FOCUS_SESSION_SYNC.md §3.2), so the handlers share one decode instead of repeating it.
func focusModePayload(from event: PusherEvent) -> [String: Any]? {
    guard let data = event.data?.data(using: .utf8) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
}

/// Map the session's `block_level` to the Mac's strictness enum. Previously every remotely-started
/// session was hardcoded to `._NORMAL_`, so a strict session started on the phone was enforced
/// leniently on the Mac.
func focusModeStrictness(fromBlockLevel blockLevel: String?) -> FOCUSMODESTRICTNESS {
    switch blockLevel?.lowercased() {
    case "super_strict": return ._SUPER_STRICT_
    case "strict":       return ._STRICT_
    default:             return ._NORMAL_   // "gentle" / null / unknown
    }
}

class pusherEvents:NSObject, PusherDelegate {
    var pusher: Pusher!
    /// The user id whose `private-<id>` channel the current `pusher` is subscribed to. Used to keep
    /// startEventNotifications() idempotent — see the note in that method.
    private var subscribedUserId: String?

    func startEventNotifications() {
        var userId = ""
        if let id = appdelegate?.user?.userId{
            userId = id
        }

        // startEventNotifications() is called from readSettingsAndLoadApp — i.e. on every settings
        // refresh / offline-recovery / re-login, not just once at launch. Building a fresh Pusher each
        // time spins up a new NWWebSocket/NWConnection and abandons the previous one WITHOUT
        // disconnecting it; that orphaned connection's state-update handler can then fire after it's
        // been deallocated, which crashes deep in Network.framework (_Block_copy on the
        // com.apple.network.connection queue — EXC_BAD_ACCESS). So only (re)connect when there's no
        // client yet or the subscribed user actually changed, and tear the old client down explicitly
        // first so its socket is cancelled cleanly rather than released mid-callback.
        if pusher != nil, userId == subscribedUserId {
            return
        }
        if let existing = pusher {
            existing.unbindAll()
            existing.unsubscribeAll()
            existing.disconnect()
            pusher = nil
        }
        subscribedUserId = userId

        let options = PusherClientOptions(
            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder()), host: .cluster("mt1")
        )
        pusher = Pusher(
            key: "e6efc69cb17b6816c56c",
            options: options
        )

        pusher.delegate = self

        let channelName = "private-"+userId
        let channel = pusher.subscribe(channelName)
        
        
        // bind a callback to handle an event
        _ = channel.bind(eventName: "focus-mode-started", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                addLog(text: "Pusher focus-mode-started received (focusOn=\(isFocusModeOn()), state=\(currentState))")
                if isFocusModeOn() || isHardCorePomodoroModeOn || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._SHUTOFFMAC_ || currentState == ._CUSTOM_ROUTINE_{
                    addLog(text: "Pusher focus-mode-started IGNORED: Mac already busy (focusOn=\(isFocusModeOn()), hardcore=\(isHardCorePomodoroModeOn), state=\(currentState))")
                    return;
                }
                if let data = data.data(using: .utf8) {
                        do {
                            if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                                print(dictionary)
                                if dictionary["device_id"] as? String == currentDeviceId{
                                    addLog(text: "Pusher focus-mode-started IGNORED: event is from this device")
                                    return;
                                }
                                let startTimeString = dictionary["start_time"] as? String ?? ""
                                let finishTimeString = dictionary["scheduled_finish_time"] as? String ?? ""
                                let focusModeId = dictionary["focus_mode_id"] as? String ?? ""
                                let intention = dictionary["intention"] as? String ?? ""
                                // Fuller payload (FOCUS_SESSION_SYNC.md §3.2): the session may already be
                                // paused when we hear about it (started elsewhere, paused before this Mac
                                // saw it), and its strictness is the session's, not always normal.
                                let status = dictionary["status"] as? String ?? ""
                                let blockLevel = dictionary["block_level"] as? String
                                
                                if let startTime = getDateFromStringInUtc(date: startTimeString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"), let finishTime = getDateFromStringInUtc(date: finishTimeString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"){
                                     
                                    let diffMinutes = Calendar.current.dateComponents([.minute], from: startTime, to: finishTime).minute ?? 0
                                    print(diffMinutes)
                                    if diffMinutes <= 0 { addLog(text: "Pusher focus-mode-started IGNORED: non-positive duration (\(diffMinutes) min)") }
                                    if diffMinutes > 0{
                                        addLog(text: "Start focus mode from pusher event")// v 2.32484
                                        if !getTaskPlayerVcObject().isViewLoaded{
                                            getTaskPlayerVcObject().loadView()
                                        }
                                        getTaskPlayerVcObject().loadRequest()
                                        
                                        var currentFocusModeIndex = -1
                                        for i in 0..<arrFocusType.count{
                                            if arrFocusType[i]["id"] as? String  == focusModeId{
                                                currentFocusModeIndex = i
                                                break;
                                            }
                                        }
                                        
                                        if currentFocusModeIndex == -1{
                                            addLog(text: "Pusher focus-mode-started IGNORED: focus_mode_id \(focusModeId) not in local arrFocusType (count \(arrFocusType.count))")
                                            return;
                                        }
                                        
                                        let calendar = Calendar.current
                                        startFocusModeTime = Date()
                                        endFocusModeTime = calendar.date(byAdding: .minute, value: diffMinutes, to: startFocusModeTime!)
                                        currentFocusModeStrictness = focusModeStrictness(fromBlockLevel: blockLevel)
                                        addLog(text: "focus mode strictness from block_level \(blockLevel ?? "nil"): \(currentFocusModeStrictness)")
                                        arrFocusType[currentFocusModeIndex]["isOn"] = true
                                        arrFocusType[currentFocusModeIndex]["lastStartedDate"] = getStringFromDate(date: startFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
                                        arrFocusType[currentFocusModeIndex]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
                                        shouldReloadTaskPlayer = true
                                        if let isAutoDoNotDisturbEnabled = arrFocusType[currentFocusModeIndex]["isAutoDoNotDisturbEnabled"] as? Bool{
                                            if isAutoDoNotDisturbEnabled{
                                                if isAccessibilityEnabled(isPrompt: true){
                                                    DNDManager.shared.setDND(true)
                                                }
                                            }
                                        }
                                        if !DNDManager.shared.isDndEnabled{
                                            if let isDeepWorkFocus = arrFocusType[currentFocusModeIndex]["isDeepWorkFocus"] as? Bool{
                                                if  isDeepWorkFocus{
                                                    if isAccessibilityEnabled(isPrompt: true){
                                                        DNDManager.shared.setDND(true)
                                                    }
                                                }
                                            }else if let isDefault = arrFocusType[currentFocusModeIndex]["isDefault"] as? Bool{
                                                if  isDefault{
                                                    if isAccessibilityEnabled(isPrompt: true){
                                                        DNDManager.shared.setDND(true)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        workBeforeFocusBegin(index: currentFocusModeIndex)
                                        isFocusModeRunning = true
                                        appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString:arrFocusType[currentFocusModeIndex]["color"] as? String ?? "")
                                        appdelegate!.setStatusBarButtonTitleForFocusMode(title: intention)
                                        appdelegate!.statusbutton?.imagePosition = .imageLeft
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
                                        

                                        whatToAchieveInFocusBlock = intention
                                        
                                        DispatchQueue.global().async {
                                            sleep(1)
                                            DispatchQueue.main.async {
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
                                        }
                                        
                                        //focusButtonService
                                        focusButtonServiceObject.startFocusSession(seconds: diffMinutes*60)
                                        
                                        appdelegate!.focusModeStartted(isStartedByPusher: true)

                                        // The session can already be paused by the time we hear about it
                                        // (started on the phone, paused before this Mac joined). Start it
                                        // normally above so all the session state is set up, then apply the
                                        // pause — shouldSyncToServer:false since the pause isn't ours.
                                        if status.lowercased() == "paused"{
                                            addLog(text: "focus mode started from pusher event is already paused - applying pause")
                                            appdelegate?.pauseFocusMode(index: currentFocusModeIndex, shouldSyncToServer: false)
                                        }
                                    }
                                }
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
            }
        })
        
        _ = channel.bind(eventName: "focus-mode-finished", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)
                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            if dictionary["device_id"] as? String == currentDeviceId{
                                return;
                            }
                        }
                    }catch{
                        
                    }
                }
                if teacherSessionManagerObject.isTeacherSessionActive(){// a teacher controlled class session only ends via class-session-ended or its scheduled finish time
                    return;
                }
                if isFocusModeOnOrPaused() == false{
                    return;
                }
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
                
                if isFocusModeOn(){// if is paused then already calculated, otherwise calculate
                    let totalSeconds = Int(Date().timeIntervalSince(startFocusModeTimeForPauseAndResume ?? Date()))
                    focusModeActualDurationPerformed += totalSeconds
                }
                
                focusModeFinishedCapturePosthog()
                
                isHardCorePomodoroModeOn = false
                
                
                var currentFocusModeName = ""
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
                        arrFocusType[i]["isOn"] = false
                        arrFocusType[i]["isPaused"] = false
                        currentFocusModeName = arrFocusType[i]["name"] as? String ?? ""

                        if DNDManager.shared.isDndEnabled{
                            DNDManager.shared.setDND(true)
                        }
                        
                        workAfterFocusBegin(index: i)
                        break;
                    }
                }
                
                isFocusModeRunning = false

                appdelegate!.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
                appdelegate!.statusbutton?.title = ""
                
                focusModeHelper.stopUrlTimer()
                appdelegate!.timerCheckAllowedApps?.invalidate()
                
                //focusButtonService
                focusButtonServiceObject.finishFocusSession()
 
                arrKeywordsToAllowInFocus.removeAll()


                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")

                appdelegate!.isAutoMeetingsModeStarted = false
                appdelegate!.appUsedInAutoMeetingFocusMode = ""
                
                
                closePupUpBlockIfVisible()
                menuViewControllerObj?.reloadIfNeeded()
                closeNudgeFocusAlignmentScoreWindow()
                
                leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
                leftMenuVcObj?.resetFocusModeTitle()
                
                if mainWindowControllerObj?.window?.isVisible ?? false{
                    if leftMenuVcObj?.boxTodoPlayer.isSelected ?? false{
                        leftMenuVcObj?.showTaskPlayer()
                    }
                }
                
                refreshFocusModeData()
            }
        })
        
        
        // A pause/resume performed on another device (phone, Windows). Mac used to bind only
        // started/finished, so a remote pause never reached it and the two devices silently disagreed
        // (FOCUS_SESSION_SYNC.md §1/§6). We reuse the local pauseFocusMode/resumeFocusMode so the timer
        // arithmetic, focus-button and UI all behave exactly as a local pause — but with
        // shouldSyncToServer:false, otherwise applying the event would POST it straight back.
        _ = channel.bind(eventName: "focus-mode-paused", eventCallback: { (event: PusherEvent) in
            guard let dictionary = focusModePayload(from: event) else { return }
            if dictionary["device_id"] as? String == currentDeviceId{ return }        // our own echo
            if teacherSessionManagerObject.isTeacherSessionActive(){ return }         // teacher-controlled, not user-controlled
            guard isFocusModeOn() else { return }                                     // nothing running to pause
            addLog(text: "Pause focus mode from pusher event")
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["isOn"] as? Bool == true{
                    appdelegate?.pauseFocusMode(index: i, shouldSyncToServer: false)
                    break;
                }
            }
        })

        _ = channel.bind(eventName: "focus-mode-resumed", eventCallback: { (event: PusherEvent) in
            guard let dictionary = focusModePayload(from: event) else { return }
            if dictionary["device_id"] as? String == currentDeviceId{ return }
            if teacherSessionManagerObject.isTeacherSessionActive(){ return }
            guard isFocusModePaused() else { return }                                 // nothing paused to resume
            addLog(text: "Resume focus mode from pusher event")
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["isPaused"] as? Bool == true{
                    appdelegate?.resumeFocusMode(index: i, shouldSyncToServer: false)
                    break;
                }
            }
        })

        _ = channel.bind(eventName: "activity-completed", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)
                
                
                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            
                            var shouldIgnore = false
                            
                            if dictionary["leader_device_id"] as? String == currentDeviceId{
                                shouldIgnore = true
                            }
                            
                            if !shouldIgnore {
                                if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
                                    menuViewControllerObj?.btnResumeHabitsClicked(self)
                                    return;
                                }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
                                    menuViewControllerObj?.btnResumeHabitsClicked(self)
                                    return;
                                }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
                                    menuViewControllerObj?.btnResumeHabitsClicked(self)
                                    return;
                                }
     
                                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
                                    // If the user is looking at the Schedule tab, keep them there
                                    // after the re-sync rather than navigating into the next habit.
                                    if firstViewControllerObj?.isScheduleTabSelected == true
                                        || routinePostponedInfoVcObj?.isScheduleTabSelected == true {
                                        pendingReturnToSchedule = true
                                    }
                                    appdelegate!.abortAllProcess()
                                    currentState = ._NOTHING_
                                    appdelegate!.backgroundThread()
                                    if appdelegate!.isUserOnMeeting && currentState == ._NOTHING_{
                                        addLog(text: "isUserOnMeeting True and currentState is None: Hide Main Window.")
                                        if mainWindowControllerObj?.window?.isVisible ?? false{
                                            mainWindowControllerObj?.window?.close()
                                            hideBlankWindowInSecondaryMonitor()
                                        }
                                    }
                                }
                            }
                        }
                    }catch{
                        
                    }
                    
                }
            }
        })
        
        //***********Teacher Mode class session events (canonical names, same vocabulary as backend + FCM data.type)***************//
        // unlike focus-mode-started (auto starts), class-session-invite shows the JOIN prompt first - the session never starts without the student's approval
        _ = channel.bind(eventName: "class-session-invite", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)
                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            DispatchQueue.main.async {
                                teacherSessionManagerObject.handleSessionInvite(dictionary: dictionary)
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        })

        // stale/duplicate deliveries are dropped in the manager via allowlist_version
        _ = channel.bind(eventName: "class-allowlist-changed", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)
                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            DispatchQueue.main.async {
                                teacherSessionManagerObject.handleAllowlistChanged(dictionary: dictionary)
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        })

        _ = channel.bind(eventName: "class-session-ended", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)
                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            DispatchQueue.main.async {
                                teacherSessionManagerObject.handleSessionEnded(dictionary: dictionary)
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        })

        // approvals arrive as class-allowlist-changed; this one only carries denials/expiries back to the requesting student
        _ = channel.bind(eventName: "class-unlock-resolved", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)
                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            DispatchQueue.main.async {
                                teacherSessionManagerObject.handleUnlockResolved(dictionary: dictionary)
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        })

        _ = channel.bind(eventName: "settings-updated", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)

                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            var shouldIgnore = false
                            if dictionary["device_id"] as? String == currentDeviceId{
                                shouldIgnore = true
                            }
                            if !shouldIgnore{
                                appdelegate?.quitAndRestartApp() 
                            }
                        }
                    }catch{

                    }

                }
            }
        })
        pusher.connect()
    }

    /// Cleanly drop the realtime connection before the Mac sleeps. On sleep — especially with the lid
    /// closed and no network — PusherSwift's NWWebSocket keeps trying to reconnect and hits a
    /// use-after-free in Network.framework (nw_connection_report_state → objc_retain; see #2125).
    /// Disconnecting ourselves takes the socket out of that unstable transition window before the OS
    /// tears the network down; reconnectAfterWake() brings it back.
    func disconnectForSleep() {
        guard pusher != nil else { return }
        addLog(text: "Pusher: disconnect before sleep")
        pusher.disconnect()
    }

    /// Reconnect the realtime socket after wake, but only once the network is actually back —
    /// reconnecting into no network is the churn that crashes. If it isn't up yet, retry a few times as
    /// it comes back; a still-connected Pusher just no-ops on connect().
    func reconnectAfterWake(attempt: Int = 0) {
        guard pusher != nil else { return }
        if Reachability.isConnectedToNetwork() {
            // A bare connect() can't recover a socket stuck mid-teardown: if the pre-sleep disconnect
            // didn't finish before the Mac slept, the connection wakes stuck in `disconnecting`, and
            // connect() from there transitions to `connecting` but never reaches `connected` (confirmed
            // in the logs). Rebuild the client from scratch so we always get a clean NWWebSocket — safe
            // now that the vendored NWWebSocket fix cancels the old connection without a use-after-free.
            addLog(text: "Pusher: reconnect after wake — rebuilding client")
            rebuildConnection()
        } else if attempt < 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.reconnectAfterWake(attempt: attempt + 1)
            }
        }
    }

    /// Fully tear down the current Pusher client (which can be stuck half-disconnected after sleep) and
    /// build a fresh one via startEventNotifications(). Clears subscribedUserId so that method doesn't
    /// treat the rebuild as a no-op. The unbind/unsubscribe/disconnect mirrors startEventNotifications'
    /// own teardown path, and the vendored NWWebSocket fix makes cancelling the old socket crash-safe.
    private func rebuildConnection() {
        if let existing = pusher {
            existing.unbindAll()
            existing.unsubscribeAll()
            existing.disconnect()
        }
        pusher = nil
        subscribedUserId = nil
        startEventNotifications()
    }

    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        print("changedConnectionState")
    }
    
    func debugLog(message: String) {
        print("debugLog:- \(message)")
    }
    
    func subscribedToChannel(name: String) {
        print("subscribedToChannel:- \(name)")
    }

    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        print("failedToSubscribeToChannel:- \(name) :- \(error?.localizedDescription)")
    }
    
    func receivedError(error: PusherError) {
        let message = error.message
        if let code = error.code {
            // ...
        }
        print("receivedError:- \(error.message)")
    }
    
    func failedToDecryptEvent(eventName: String, channelName: String, data: String?) {
        print("failedToDecryptEvent:- \(data)")
    }
    
}

class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        let responsePath = "\(baseUrl)/pusher/user-auth"//https://api.focusbear.io/pusher/user-auth"
        if let responsePathUrl = NSURL(string: responsePath){
            var request = URLRequest(url:responsePathUrl as URL);
            request.httpMethod = "POST"
            let token = appdelegate!.credential!.accessToken
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            
            let json: [String: Any] = [
                "socket_id": socketID
            ]
            
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            
            return request
        }
        return nil
    }
}
