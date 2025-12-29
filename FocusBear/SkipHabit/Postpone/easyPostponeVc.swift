//
//  easyPostponeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class easyPostponeVc: NSViewController {

    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var lblInfo: NSTextField!
    @IBOutlet weak var btnDeactivateApp: underLineButton!
    @IBOutlet weak var btnPostpone: Button!
    @IBOutlet weak var popupButtonMinutes: NSPopUpButton!
    @IBOutlet weak var lblTitleSelectMinutes: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc // only for cutOffTime in hardskip
    
    // if current routine is custom routine and postpone end notification is showing for morning routine .then we need not to confuse about for what easy postpone window is showing. there may be two options first is to postpone cusotm routine and second is to extend postpone duartion of morning routine . so we use this variable to understand without any confusion
    var isForExtendPostponeDuringCustomRoutine = false
    
    var isViewVisible = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblInfo.stringValue = "If you want more of a nudge to stick to your habits, open preferences and change the friction level from the general settings tab."
        lblTitle.stringValue = "Ok I get it - now's not a good time. I'll try again in 5 minutes. You can postpone for longer if you need to."
        lblTitleSelectMinutes.stringValue = "Select minutes to postpone:"
        
        popupButtonMinutes.removeAllItems()
        popupButtonMinutes.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "60", "90"])
        
        btnPostpone.title = "Postpone"
        btnDeactivateApp.title = "Deactivate Focus Bear for 4 hours"
        
        btnCancel.title = "Resume Habits"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            btnCancel.title = menuInfo.value(forKey: "menuItemResumeHabitsTitle") as? String ?? btnCancel.title
        }
        
        if let easyPostponeVcInfo = configjson.value(forKey: "easyPostponeVcInfo") as? NSDictionary{
            lblTitle.stringValue = easyPostponeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleSelectMinutes.stringValue = easyPostponeVcInfo.value(forKey: "titleSelectMinutes") as? String ?? lblTitleSelectMinutes.stringValue
            btnPostpone.title = easyPostponeVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
            btnDeactivateApp.title = easyPostponeVcInfo.value(forKey: "buttonDeactivateText") as? String ?? btnDeactivateApp.title
            lblInfo.stringValue = easyPostponeVcInfo.value(forKey: "infoText") as? String ?? lblInfo.stringValue
        }
        btnPostpone.buttonColor = NSColor.white.cgColor
    }
    
    override func viewDidAppear() {
        //Shouldn't be able to postpone during cutoff time without password after postponing once(wjem habit is about to resume) #797
        if currentState == ._POSTPON_EVENING_HABIT_ && !SettingsManagerObject.isEasySkipEnabled{
            if cutOffTime != nil{
                if shouldAskPassword(){
                    if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                        let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                        let currentDate = Date()
                        if currentDate > cutOffDate{
                            if self.view.window != nil{
                                self.presentAsSheet(enterPasswordVcObj!)
                                enterPasswordVcObj?.parentVc = self
                                enterPasswordVcObj?.isShowingForDeactivatingApp = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear() {
        isViewVisible = true
    }
    override func viewWillDisappear() {
        isViewVisible = false
        if enterPasswordVcObj != nil{
            if self == enterPasswordVcObj!.presentingViewController{
                enterPasswordVcObj!.dismiss(enterPasswordVcObj!)
            }
        }
    }
    
    func closeView(){
        if self.presentingViewController == mainViewControllerObj{
            self.dismiss(self)
        }else{
            self.view.window?.close()
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {// resume habit
        addLog(text: "[user-action] easyPostponeVc:- button Cancel clicked")// log added on 14/4/25
        
        // if custom rouine is ongoing and morning/evening routine is postponed and user click postpone on morning/evening routine postpone end warning and then cliking on resume habit button on easypostponevc then it will start morning evening routine
        
        var isViewForMorningEveningRoutineExtendPostponed = false
        
        if currentState == ._CUSTOM_ROUTINE_{
            if isForExtendPostponeDuringCustomRoutine && isCustomRoutineWasRunningInPostponeMorningHabit{
                isViewForMorningEveningRoutineExtendPostponed = true
            }else if isForExtendPostponeDuringCustomRoutine && isCustomRoutineWasRunningInPostponeEveningHabit{
                isViewForMorningEveningRoutineExtendPostponed = true
            }
        }
        
        if currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_EVENING_HABIT_ || isViewForMorningEveningRoutineExtendPostponed{

            if (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit) || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit){
                habitsVcObj?.stopActivityCountDownTimer()
                if currentActivityPlaying != nil{
                    closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                }
                currentHabitPlaying = nil
                isCustomRoutineWasRunningInPostponeMorningHabit = false
                isCustomRoutineWasRunningInPostponeEveningHabit = false
            }
            
            currentState = ._NOTHING_
            if mainViewControllerObj != nil{
                if getHabitsVcObject().postponeTimer != nil{
                    getHabitsVcObject().postponeTimer?.invalidate()
                    getHabitsVcObject().postponeTimer = nil
                    closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
                }
                if getHabitsVcObject().postponeNotificationTimer != nil{
                    getHabitsVcObject().postponeNotificationTimer?.invalidate()
                    getHabitsVcObject().postponeNotificationTimer = nil
                }
            }
            
            
            
            appdelegate?.backgroundThread()
            closeView()
            return;
        }
        
       
        
        if currentAction == ._INPROGRESS_  && (currentHabitPlaying != nil || currentActivityPlaying != nil){// if background abit is going on
//            getSmallCountDownWindowObject().showWindow(self)
//            getsmallCountDownVcObject().view.isHidden = false
            showSmallTimerView()
        }else{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
        }
        
        getHabitsVcObject().abortCancel()
        closeView()
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "[user-action] easyPostponeVc:- button postpone clicked")
        
        if currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_EVENING_HABIT_{
            
            if mainViewControllerObj != nil{
                if getHabitsVcObject().postponeTimer != nil{
                    getHabitsVcObject().postponeTimer?.invalidate()
                    getHabitsVcObject().postponeTimer = nil
                    closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
                }
                if getHabitsVcObject().postponeNotificationTimer != nil{
                    getHabitsVcObject().postponeNotificationTimer?.invalidate()
                    getHabitsVcObject().postponeNotificationTimer = nil
                }
            }

        }
        
        if lastCurrentState == ._MORNING_HABIT_{
            if SettingsManagerObject.isStrictnessLevelSuperGentle(){//Ultra low friction level #1357
                addLog(text: "easyPostponeVc:- strictness level is super gentle so don't show postpone Intention view")
                getHabitsVcObject().postponeMorningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: false)
            }else{
                addLog(text: "easyPostponeVc:- askPostponeIntention")// added in 2.28.444
                self.presentAsSheet(getAskPostponeIntentionVcObject())
                askPostponeIntentionVcObj?.resetData(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: true, lastCurrentState: ._MORNING_HABIT_)
                return;// return here because we do not want to close the window
            }
            
        }else if lastCurrentState == ._EVENING_HABIT_{
            if SettingsManagerObject.isStrictnessLevelSuperGentle(){//Ultra low friction level #1357
                addLog(text: "easyPostponeVc:- strictness level is super gentle so don't show postpone Intention view")
                getHabitsVcObject().postponeEveningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: false)
            }else{
                addLog(text: "easyPostponeVc:- askPostponeIntention")// added in 2.28.444
                self.presentAsSheet(getAskPostponeIntentionVcObject())
                askPostponeIntentionVcObj?.resetData(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: true, lastCurrentState: ._EVENING_HABIT_)
                return;// return here because we do not want to close the window
            }
        }else if lastCurrentState == ._CUSTOM_ROUTINE_{
            if isForExtendPostponeDuringCustomRoutine && isCustomRoutineWasRunningInPostponeMorningHabit{
                getHabitsVcObject().postponeMorningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
            }else if isForExtendPostponeDuringCustomRoutine && isCustomRoutineWasRunningInPostponeEveningHabit{
                getHabitsVcObject().postponeMorningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
            }else{
                getHabitsVcObject().postponeCustomRoutineFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false, fromRoutineWarning:false)
            }
        }else if lastCurrentState == ._MICRO_BREAK_{
            getHabitsVcObject().postponeBreakActivitiesFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, isFromBreakWarningWindow: false)
        }else if lastCurrentState == ._POSTPON_MORNING_HABIT_{
            getHabitsVcObject().postponeMorningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
        }else if lastCurrentState == ._POSTPON_EVENING_HABIT_{
            getHabitsVcObject().postponeEveningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
        }
        closeView()
    }
    
    @IBAction func btnDeactivateAppClicked(_ sender: Any) {
        addLog(text: "[user-action] easyPostponeVc:- button deactivated app clicked")
        if shouldAskPassword(){
            if SettingsManagerObject.isPasswordRequireInQuitApp{
                self.presentAsSheet(enterPasswordVcObj!)
                enterPasswordVcObj?.parentVc = self
                enterPasswordVcObj?.isShowingForDeactivatingApp = true
                return;
            }
        }
        deactivateApp()
    }
    
    func deactivateApp(){

        let date = Date().addingTimeInterval(4 * 60 * 60)
        UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "easyPostponeVc:- App Deactivated for 4 hours")

        
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        addLog(text: "get Last Activity Info - forceCompleteIfAnyActivityGoing")

        var sequenceId = ""
        if lastCurrentState == ._MORNING_HABIT_{// no need to force complete in morning routine
            sequenceId = arrFilteredMorningHabits.first?.activity_sequence_id ?? ""
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastHabitShowDate)
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"easy postpone"])
        }else if lastCurrentState == ._FOCUS_SUMMARY_ || lastCurrentState == ._EVENING_HABIT_{
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"easy postpone"])
            sequenceId = arrFilteredEveningHabits.first?.activity_sequence_id ?? ""
        }else if lastCurrentState == ._MICRO_BREAK_{
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"easy postpone"])
        }else if lastCurrentState == ._CUSTOM_ROUTINE_{
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"custom_routine", "deactivate-reason":"easy postpone"])
        }else{
            addLog(text: "force Complete Current Sequence - no Sequence found to complete")
            return
        }
        
        if sequenceId.isEmpty{
            addLog(text: "force Complete Current Sequence - SequenceId is blank")
            DispatchQueue.global().async {//waiting for posthog
                sleep(1)
                DispatchQueue.main.async {
                    mainViewControllerObj?.disableApp()
                }
            }
            return;
        }
        addLog(text: "force Complete Current Sequence - forceCompleteIfAnyActivityGoing")
        allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in

            // and strt break activity
            DispatchQueue.main.async {
                mainViewControllerObj?.disableApp()
            }
        })
        
    }
}

