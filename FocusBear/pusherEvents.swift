//
//  pusherEvents.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 02/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import PusherSwift

class pusherEvents:NSObject, PusherDelegate {
    var pusher: Pusher!

    func startEventNotifications() {
        // Insert code here to initialize your application //AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
        
        let options = PusherClientOptions(
            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder()), host: .cluster("mt1")
        )
        pusher = Pusher(
            key: "e6efc69cb17b6816c56c",
            options: options
        )
        
        pusher.delegate = self
        var userId = ""
        if let id = appdelegate!.user?.userId{
            userId = id
        }
    
        let channelName = "private-"+userId
        let channel = pusher.subscribe(channelName)
        
        
        // bind a callback to handle an event
        _ = channel.bind(eventName: "focus-mode-started", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                if isFocusModeOn() || isHardCorePomodoroModeOn || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._SHUTOFFMAC_ || currentState == ._CUSTOM_ROUTINE_{
                    return;
                }
                if let data = data.data(using: .utf8) {
                        do {
                            if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                                print(dictionary)
                                if dictionary["device_id"] as? String == currentDeviceId{
                                    return;
                                }
                                let startTimeString = dictionary["start_time"] as? String ?? ""
                                let finishTimeString = dictionary["scheduled_finish_time"] as? String ?? ""
                                let focusModeId = dictionary["focus_mode_id"] as? String ?? ""
                                let intention = dictionary["intention"] as? String ?? ""
                                
                                if let startTime = getDateFromStringInUtc(date: startTimeString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"), let finishTime = getDateFromStringInUtc(date: finishTimeString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"){
                                     
                                    let diffMinutes = Calendar.current.dateComponents([.minute], from: startTime, to: finishTime).minute ?? 0
                                    print(diffMinutes)
                                    if diffMinutes > 0{
                                        var currentFocusModeIndex = -1
                                        for i in 0..<arrFocusType.count{
                                            if arrFocusType[i]["id"] as? String  == focusModeId{
                                                currentFocusModeIndex = i
                                                break;
                                            }
                                        }
                                        
                                        if currentFocusModeIndex == -1{
                                            return;
                                        }
                                        if getEndFocusModeWindowControllerObj().window!.isVisible{
                                            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                                            addEntryInStatsCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
                                            getEndFocusModeWindowControllerObj().window?.close()
                                        }
                                        
                                        let calendar = Calendar.current
                                        startFocusModeTime = Date()
                                        endFocusModeTime = calendar.date(byAdding: .minute, value: diffMinutes, to: startFocusModeTime!)
                                        currentFocusModeStrictness = ._NORMAL_
                                        addLog(text: "focus mode is normal mode")
                                        arrFocusType[currentFocusModeIndex]["isOn"] = true
                                        arrFocusType[currentFocusModeIndex]["lastStartedDate"] = getStringFromDate(date: startFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
                                        arrFocusType[currentFocusModeIndex]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
                                        shouldReloadTaskPlayer = true
                                        if let isAutoDoNotDisturbEnabled = arrFocusType[currentFocusModeIndex]["isAutoDoNotDisturbEnabled"] as? Bool{
                                            if isAutoDoNotDisturbEnabled{
                                                if isAccessibilityEnabled(isPrompt: true){
                                                    enableDND()
                                                }
                                            }
                                        }
                                        if !isDndEnabled{
                                            if let isDeepWorkFocus = arrFocusType[currentFocusModeIndex]["isDeepWorkFocus"] as? Bool{
                                                if  isDeepWorkFocus{
                                                    if isAccessibilityEnabled(isPrompt: true){
                                                        enableDND()
                                                    }
                                                }
                                            }else if let isDefault = arrFocusType[currentFocusModeIndex]["isDefault"] as? Bool{
                                                if  isDefault{
                                                    if isAccessibilityEnabled(isPrompt: true){
                                                        enableDND()
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
                                        isFocusTimeType = ._HOUR_
                                        appdelegate?.setFocusModeTimer(hour: nil, minute: diffMinutes)
                                       // isFocusModeStartedFromPomodoroMode = false
                                        closePomodoroWindowIOfVisible()
                                        if startingFocusWindowControllerObj != nil{
                                            if startingFocusWindowControllerObj!.window!.isVisible{
                                                startingFocusWindowControllerObj?.window?.close()
                                            }
                                        }
                                        whatToAchieveInFocusBlock = intention
                                        
                                        appdelegate!.focusModeStartted(isStartedByPusher: true)
                                        appdelegate!.setIntentionInBrainDumpWindow()
  
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
                if isFocusModeOnOrPaused() == false{
                    return;
                }
                
                if getEndFocusModeWindowControllerObj().window!.isVisible{
                    getEndFocusModeWindowControllerObj().window?.close()
                    return;
                }
                closeTaskPlayerWindowIfVisible()
                isHardCorePomodoroModeOn = false

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
                    setAppIconForFocusModeScore(probability: nil)
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
                if brainDumpWcObj != nil{
                    if brainDumpWcObj?.window != nil{
                        if brainDumpWcObj!.window!.isVisible{
                            brainDumpWcObj?.window?.close()
                        }
                    }
                }
                
                var currentFocusModeName = ""
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
                        arrFocusType[i]["isOn"] = false
                        arrFocusType[i]["isPaused"] = false
                        currentFocusModeName = arrFocusType[i]["name"] as? String ?? ""
                        
                        if let isAutoDoNotDisturbEnabled = arrFocusType[i]["isAutoDoNotDisturbEnabled"] as? Bool{
                            if isAutoDoNotDisturbEnabled{
                                if isAccessibilityEnabled(isPrompt: false){
                                    disableDND()
                                }
                            }
                        }
                        
                        workAfterFocusBegin(index: i)
                        break;
                    }
                }
                if timerForFocusMode != nil{
                    timerForFocusMode?.invalidate()
                }
                closePupUpBlockIfVisible()
                
                appdelegate!.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
                appdelegate!.statusbutton?.title = ""
                
                isFocusTimeType = ._NONE_
                if appdelegate!.timerAllowUrl != nil{
                    appdelegate!.timerAllowUrl!.invalidate()
                }
                appdelegate!.timerCheckAllowedApps?.invalidate()
                
                arrKeywordsToAllowInFocus.removeAll()
                if toolBoxWcObj != nil{
                    if toolBoxWcObj!.window!.isVisible{
                        toolBoxWcObj?.window?.close()
                    }
                }

                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")

                appdelegate!.isAutoMeetingsModeStarted = false
                appdelegate!.appUsedInAutoMeetingFocusMode = ""
                refreshFocusModeData()
                closePupUpBlockIfVisible()
            }
        })
        
        
        _ = channel.bind(eventName: "activity-completed", eventCallback: { (event: PusherEvent) in
            if let data = event.data {
                print(data)
                if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
                    menuViewControllerObj?.btnResumeHabitsClicked(self)
                    return;
                }else if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeMorningHabit{
                    menuViewControllerObj?.btnResumeHabitsClicked(self)
                    return;
                }else if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeEveningHabit{
                    menuViewControllerObj?.btnResumeHabitsClicked(self)
                    return;
                }
                
                if let data = data.data(using: .utf8) {
                    do {
                        if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                            print(dictionary)
                            
                            
                            var shouldIgnore = false
                            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
                                if dictionary["leader_device_id"] as? String == currentDeviceId{
                                    shouldIgnore = true
                                }
                                if !shouldIgnore{
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
