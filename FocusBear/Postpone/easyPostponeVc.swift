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
                            self.presentAsSheet(enterPasswordVcObj!)
                            enterPasswordVcObj?.parentVc = self
                            enterPasswordVcObj?.isShowingForDeactivatingApp = false
                        }
                    }
                }
            }
        }
        
        
    }
    override func viewWillDisappear() {
        if enterPasswordVcObj != nil{
            if self == enterPasswordVcObj!.presentingViewController{
                enterPasswordVcObj!.dismiss(enterPasswordVcObj!)
            }
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        if currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_EVENING_HABIT_{
            currentState = ._NOTHING_
            if mainViewControllerObj != nil{
                if mainViewControllerObj?.postponeTimer != nil{
                    mainViewControllerObj?.postponeTimer?.invalidate()
                    mainViewControllerObj?.postponeTimer = nil
                    if smallCountDownWcObj != nil{
                        if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                            smallCountDownVcObj?.closeTimerBox()
                        }
                    }
                }
                if mainViewControllerObj?.postponeNotificationTimer != nil{
                    mainViewControllerObj?.postponeNotificationTimer?.invalidate()
                    mainViewControllerObj?.postponeNotificationTimer = nil
                }
            }
            appdelegate?.backgroundThread()
            self.view.window?.close()
            return;
        }
        if currentHabitPlaying == nil && currentActivityPlaying == nil{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
        }else{
            getSmallCountDownWindowObject().showWindow(self)
        }
        
        mainViewControllerObj?.abortCancel()
        self.view.window?.close()
    }
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "[user-action] easyPostponeVc:- button postpone clicked")
        
        if currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_EVENING_HABIT_{
            
            if mainViewControllerObj != nil{
                if mainViewControllerObj?.postponeTimer != nil{
                    mainViewControllerObj?.postponeTimer?.invalidate()
                    mainViewControllerObj?.postponeTimer = nil
                    if smallCountDownWcObj != nil{
                        if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                            smallCountDownVcObj?.closeTimerBox()
                        }
                    }
                }
                if mainViewControllerObj?.postponeNotificationTimer != nil{
                    mainViewControllerObj?.postponeNotificationTimer?.invalidate()
                    mainViewControllerObj?.postponeNotificationTimer = nil
                }
            }

        }
        
        if lastCurrentState == ._MORNING_HABIT_{
            self.presentAsSheet(getAskPostponeIntentionVcObject())
            askPostponeIntentionVcObj?.resetData(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: true, lastCurrentState: ._MORNING_HABIT_)
            return;// return here because we do not want to close the window
        }else if lastCurrentState == ._EVENING_HABIT_{
            self.presentAsSheet(getAskPostponeIntentionVcObject())
            askPostponeIntentionVcObj?.resetData(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView: true, lastCurrentState: ._EVENING_HABIT_)
            return;// return here because we do not want to close the window
        }else if lastCurrentState == ._ACTIVITY_{
            mainViewControllerObj?.postponeBreakActivitiesFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil)
        }else if lastCurrentState == ._POSTPON_MORNING_HABIT_{
            mainViewControllerObj?.postponeMorningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
        }else if lastCurrentState == ._POSTPON_EVENING_HABIT_{
            mainViewControllerObj?.postponeEveningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, showAskFocusModeView:false, showAskIntention:false)
        }
        self.view.window?.close()
    }
    @IBAction func btnDeactivateAppClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
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
        }else if lastCurrentState == ._ACTIVITY_{
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"easy postpone"])
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

