//
//  habitsStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 07/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class habitsStateVc: NSViewController {

    @IBOutlet weak var btnResumeHabits: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var morningRoutinePostponedText = "Morning routine postponed. Resume it now by clicking 'Resume Habits'."
    var eveningRoutinePostponedText = "Evening routine postponed. Resume it now by clicking 'Resume Habits'."
    
    var isFreeTimeBeforeShutoff = false
    var editRoutineButtonShowing = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = ""// v 2.28.453
        btnResumeHabits.title = "Resume Habits"
        
        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
            morningRoutinePostponedText = habitsStateVcInfo.value(forKey: "morningRoutinePostponedText") as? String ?? morningRoutinePostponedText
            eveningRoutinePostponedText = habitsStateVcInfo.value(forKey: "eveningRoutinePostponedText") as? String ?? eveningRoutinePostponedText
            btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonResumeHabits") as? String ?? btnResumeHabits.title
        }
    }
    
    override func viewWillAppear() {
        reloadData()
    }
    
    func reloadData(){
        addLog(text:"habitsStateVc:- reloadData")
        isFreeTimeBeforeShutoff = false
        editRoutineButtonShowing = false
        if !isAppEnable{
            btnResumeHabits.title = "Activate Distraction Blocking"
            lblTitle.stringValue = "Distraction Blocking is currently paused. You can turn it back on anytime to stay focused."

            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                btnResumeHabits.title = menuInfo.value(forKey: "menuItemReactivateTitle") as? String ?? btnResumeHabits.title
            }
            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                lblTitle.stringValue = habitsStateVcInfo.value(forKey: "titleAppDisabled") as? String ?? lblTitle.stringValue
            }
            
            btnResumeHabits.isHidden = false
            return;
        }

        btnResumeHabits.title = "Resume Habits"
        
        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
            btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonResumeHabits") as? String ?? btnResumeHabits.title
        }
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            btnResumeHabits.isHidden = false
            if currentState == ._POSTPON_MORNING_HABIT_{
                lblTitle.stringValue = morningRoutinePostponedText
            }else{
                lblTitle.stringValue = eveningRoutinePostponedText
            }
            
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = morningRoutinePostponedText
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = eveningRoutinePostponedText
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = morningRoutinePostponedText
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = eveningRoutinePostponedText
        }else{
            btnResumeHabits.isHidden = true
            if isHabitAlreadyShowed && !isShutOffTimeGoing(){
                let (nextRoutine, nextRoutineName, nextRoutineIsEveningRoutine) = getNextRoutineInfo()
                
               
                let (dateString) = getStringFromDate(date: nextRoutine, dateFormat: getSystemTimeFormat())
                var nextRoutineText = "Great job staying on track! Your next scheduled routine (<ROUTINE>) is set for <TIME>. Be ready to jump back in and continue building those healthy habits. You've got this!"
                if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                    nextRoutineText = habitsStateVcInfo.value(forKey: "nextRoutineText") as? String ?? nextRoutineText
                }
                nextRoutineText = nextRoutineText.replacingOccurrences(of: "<ROUTINE>", with: nextRoutineName)
                nextRoutineText = nextRoutineText.replacingOccurrences(of: "<TIME>", with: dateString)
                lblTitle.stringValue = nextRoutineText
                
                if nextRoutineIsEveningRoutine{
                    if arrAllDaysEveningHabits.count == 0{
                       
                        var title = "There are no habits set for your account. Do you want to set habits now?"
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            title = menuInfo.value(forKey: "alertNoHabitsFound") as? String ?? title
                        }
                        lblTitle.stringValue = nextRoutineText + "\n\n\n" + title
                        btnResumeHabits.title = "Edit Habits"
                        editRoutineButtonShowing = true
                        btnResumeHabits.isHidden = false
                        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                            btnResumeHabits.title = leftMenuVcInfo.value(forKey: "menuEditHabits") as? String ?? btnResumeHabits.title
                        }
                    }
                }
                
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                    if Date().compare(date) == .orderedAscending {
                        var shutoffAbortedText = "Your morning routine starts at <TIME> — time to log off and rest."
                        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                            shutoffAbortedText = habitsStateVcInfo.value(forKey: "shutoffAbortedTextNew") as? String ?? shutoffAbortedText
                        }
                        
                        let startdate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                        
                        let dateString = getStringFromDate(date: startdate, dateFormat: getSystemTimeFormat())
                        shutoffAbortedText = shutoffAbortedText.replacingOccurrences(of: "<TIME>", with: dateString)
                        lblTitle.stringValue = shutoffAbortedText
                    }
                }
                if isShutOffTimeGoing() && arrAllDaysEveningHabits.count == 0{
                   
                    var title = "There are no habits set for your account. Do you want to set habits now?"
                    if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                        title = menuInfo.value(forKey: "alertNoHabitsFound") as? String ?? title
                    }
                    lblTitle.stringValue = title
                    btnResumeHabits.title = "Edit Habits"
                    editRoutineButtonShowing = true 
                    btnResumeHabits.isHidden = false
                    
                    if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                        btnResumeHabits.title = leftMenuVcInfo.value(forKey: "menuEditHabits") as? String ?? btnResumeHabits.title
                    }
                }
            }
            
            if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_  && UserDefaults.standard.object(forKey: kUserdefaultsStartRoutineButtonClicked) == nil{
                let currentDate = Date()
                let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
                let sameDay = Calendar.current.isDate(currentDate, equalTo: firstRunDate, toGranularity: .day)
                let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false
                lblTitle.stringValue = ""
                if sameDay || !shouldDoHabits(){
                    btnResumeHabits.isHidden = false
                   
                    if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                        if isShutOffTimeGoing(){
                            btnResumeHabits.title = "Start evening routine"
                            btnResumeHabits.title = menuInfo.value(forKey: "menuItemStartEveningHabitsFirstTimeTitle") as? String ?? btnResumeHabits.title
                        }else{
                            btnResumeHabits.title = "Start morning routine"
                            btnResumeHabits.title = menuInfo.value(forKey: "menuItemStartMorningHabitsFirstTimeTitle") as? String ?? btnResumeHabits.title
                        }
                    }
                }
            }else if (appdelegate?.isUserOnMeeting ?? false) && !isHabitAlreadyShowed && !isShutOffTimeGoing() && currentState != ._POSTPON_MORNING_HABIT_{
                // v 2.28.445
                btnResumeHabits.isHidden = true
                lblTitle.stringValue = "Morning routine will resume after the call ends."
                if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                    lblTitle.stringValue = habitsStateVcInfo.value(forKey: "resumeAfterCall") as? String ?? lblTitle.stringValue
                }
            }
            
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                if Date().compare(date) == .orderedAscending {//"Evening habits already shown for today
                    if isShutOffTimeGoing() && !isCutOffTimeGoing(){
                        if let cutOffTime = cutOffTime{// v 2.28.445
                            let cutOffdate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                            
                            btnResumeHabits.isHidden = false
                            
                            
                            isFreeTimeBeforeShutoff = true
                            let cutOffDateString = getStringFromDate(date: cutOffdate, dateFormat: getSystemTimeFormat())
                            var freeTimeText = "Well done finishing your evening routine 👏\nYour sleep time is <CUTOFFTIME>.\nYour next morning routine starts at <STARTTIME>.\nRest well and recharge for a strong start tomorrow 💪"
                            
                            btnResumeHabits.title = "Change timing"
                            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                                freeTimeText = habitsStateVcInfo.value(forKey: "freeTimeTextNew") as? String ?? freeTimeText
                                btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonChangeTiming") as? String ?? btnResumeHabits.title
                            }
                            let startdate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                            
                            let dateString = getStringFromDate(date: startdate, dateFormat: getSystemTimeFormat())
                            freeTimeText = freeTimeText.replacingOccurrences(of: "<STARTTIME>", with: dateString)
                            freeTimeText = freeTimeText.replacingOccurrences(of: "<CUTOFFTIME>", with: cutOffDateString)
                            
                            lblTitle.stringValue = freeTimeText
                        }else{//// v  2.28.453
                            isFreeTimeBeforeShutoff = true
                            btnResumeHabits.isHidden = false
                            var setSleepTime = "You do not have sleep time set."
                            btnResumeHabits.title = "Set timing"
                            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                                setSleepTime = habitsStateVcInfo.value(forKey: "setSleepTime") as? String ?? setSleepTime
                                btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonSetTiming") as? String ?? btnResumeHabits.title
                            }
                            
                            lblTitle.stringValue = setSleepTime
                        }
                        
                    }
                }
            }
        }
    }
    
    @IBAction func btnResumeHabitsClicked(_ sender: Any) {
        if editRoutineButtonShowing{
            addLog(text:"[user-action] habitsStateVc:- no habit in evening routine :- button Edit Habits clicked")
            leftMenuVcObj?.showEditHabitsView()
            return;
        }
        if isFreeTimeBeforeShutoff{
            leftMenuVcObj?.showEditHabitsView()
            return;
        }
        if !isAppEnable{
            addLog(text:"[user-action] habitsStateVc:- button Reactivate clicked")
            appdelegate?.menuItem_Reactivate()
            return;
        }
        
        if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_  && UserDefaults.standard.object(forKey: kUserdefaultsStartRoutineButtonClicked) == nil{
            let currentDate = Date()
            let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
            let sameDay = Calendar.current.isDate(currentDate, equalTo: firstRunDate, toGranularity: .day)
            let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false
            if sameDay || !shouldDoHabits(){
                addLog(text:"[user-action] habitsStateVc:- button Start Habits First Time clicked")
                menuViewControllerObj?.btnStartHabitsFirstTimeClicked(self)
                return;
            }
        }
        addLog(text:"[user-action] habitsStateVc:- button Resume Habits clicked")
        menuViewControllerObj?.btnResumeHabitsClicked(self)
    }
}
