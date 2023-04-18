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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblInfo.stringValue = "If you want more of a nudge to stick to your habits, open preferences and change the friction level from the general settings tab."
        lblTitle.stringValue = "Ok I get it - now's not a good time. I'll try again in 5 minutes. You can postpone for longer if you need to."
        lblTitleSelectMinutes.stringValue = "Select minutes to postpone:"
        
        popupButtonMinutes.removeAllItems()
        popupButtonMinutes.addItems(withTitles: ["5", "10", "15", "20", "30", "45", "60"])
        
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
        addLog(text: "easyPostponeVc:- button postpone clicked")
        
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
            mainViewControllerObj?.postponeMorningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil)
        }else if lastCurrentState == ._EVENING_HABIT_{
            mainViewControllerObj?.postponeEveningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil)
        }else if lastCurrentState == ._ACTIVITY_{
            mainViewControllerObj?.postponeBreakActivitiesFor(minutes: Int(popupButtonMinutes.title) ?? 5)
        }else if lastCurrentState == ._POSTPON_MORNING_HABIT_{
            mainViewControllerObj?.postponeMorningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil)
        }else if lastCurrentState == ._POSTPON_EVENING_HABIT_{
            mainViewControllerObj?.postponeEveningHabitFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil)
        }
        self.view.window?.close()
    }
    @IBAction func btnDeactivateAppClicked(_ sender: Any) {
        let date = Date().addingTimeInterval(4 * 60 * 60)
        UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "easyPostponeVc:- App Deactivated for 4 hours")

        
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        addLog(text: "get Last Activity Info - forceCompleteIfAnyActivityGoing")

        var sequenceId = ""
        if lastCurrentState == ._MORNING_HABIT_{
            sequenceId = arrFilteredMorningHabits.first?.activity_sequence_id ?? ""
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastHabitShowDate)
            
        }else if lastCurrentState == ._FOCUS_SUMMARY_ || lastCurrentState == ._EVENING_HABIT_{
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            
            sequenceId = arrFilteredEveningHabits.first?.activity_sequence_id ?? ""
        }else{
            addLog(text: "force Complete Current Sequence - no Sequence found to complete")
            return
        }
        
        if sequenceId.isEmpty{
            addLog(text: "force Complete Current Sequence - SequenceId is blank :- return")
            return
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

