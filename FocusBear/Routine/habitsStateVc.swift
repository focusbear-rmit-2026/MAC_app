//
//  habitsStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 07/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class habitsStateVc: NSViewController {

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnUnCancelRoutine: underLineButton!
    @IBOutlet weak var customView: NSView!
    @IBOutlet weak var btnResumeHabits: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var morningRoutinePostponedText = "Morning routine postponed. Resume it now by clicking 'Resume Habits'."
    var eveningRoutinePostponedText = "Evening routine postponed. Resume it now by clicking 'Resume Habits'."
    
    var isFreeTimeBeforeShutoff = false
    var editRoutineButtonShowing = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnUnCancelRoutine.title = "Uncancel my evening routine"
        
        lblTitle.stringValue = ""// v 2.28.453
        btnResumeHabits.title = "Resume Habits"
        
        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
            morningRoutinePostponedText = habitsStateVcInfo.value(forKey: "morningRoutinePostponedText") as? String ?? morningRoutinePostponedText
            eveningRoutinePostponedText = habitsStateVcInfo.value(forKey: "eveningRoutinePostponedText") as? String ?? eveningRoutinePostponedText
            btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonResumeHabits") as? String ?? btnResumeHabits.title
        }
    }
    
    override func viewWillAppear() {
        removeSubViews()
        customView.isHidden = true
        reloadData()
    }
    
    override func viewWillDisappear() {
        removeSubViews()
    }
    
    func reloadData(){
        addLog(text:"habitsStateVc:- reloadData")
        isFreeTimeBeforeShutoff = false
        editRoutineButtonShowing = false
        
        btnResumeHabits.isHidden = false
        lblTitle.isHidden = false
        btnResumeHabits.isSecondaryButton = false
        btnUnCancelRoutine.isHidden = true
        lblDescription.isHidden = true
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
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_{
            btnResumeHabits.isHidden = false
            if currentState == ._POSTPON_MORNING_HABIT_{
                showRutinePostponedInfoView(state: CURRENTSTATE._MORNING_HABIT_)
            }else if currentState == ._POSTPON_EVENING_HABIT_{
                showRutinePostponedInfoView(state: CURRENTSTATE._EVENING_HABIT_)
            }else{
                showRutinePostponedInfoView(state: ._FOCUS_SUMMARY_)
            }
            if currentState == ._POSTPON_MORNING_HABIT_{
                lblTitle.stringValue = morningRoutinePostponedText
            }else{
                lblTitle.stringValue = eveningRoutinePostponedText
            }
            
        }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
            btnResumeHabits.isHidden = false
            lblTitle.stringValue = eveningRoutinePostponedText
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            showRutinePostponedInfoView(state: ._MORNING_HABIT_)
            lblTitle.stringValue = morningRoutinePostponedText
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
            showRutinePostponedInfoView(state: ._EVENING_HABIT_)
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
                updateUncancelRoutineButtonVisibility(isEveningRoutine: false)
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                    if Date().compare(date) == .orderedAscending, let startTime = startTime {
                        var shutoffAbortedText = "Your morning routine starts at <TIME> — time to log off and rest."
                        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                            shutoffAbortedText = habitsStateVcInfo.value(forKey: "shutoffAbortedTextNew") as? String ?? shutoffAbortedText
                        }
                        
                        let startdate = Calendar.current.date(bySettingHour: startTime.hour, minute: startTime.minute, second: startTime.second, of: Date()) ?? Date()
                        
                        let dateString = getStringFromDate(date: startdate, dateFormat: getSystemTimeFormat())
                        shutoffAbortedText = shutoffAbortedText.replacingOccurrences(of: "<TIME>", with: dateString)
                        lblTitle.stringValue = shutoffAbortedText
                        
                        // check if user force completed evening routine
                        updateUncancelRoutineButtonVisibility(isEveningRoutine: true)
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
                }else if !isShutOffTimeGoing() && arrAllDaysMorningHabits.count == 0{
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
            
            let currentDate = Date()
            let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
            let sameDay = Calendar.current.isDate(currentDate, equalTo: firstRunDate, toGranularity: .day)
            if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_  && UserDefaults.standard.object(forKey: kUserdefaultsStartRoutineButtonClicked) == nil{
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
                        if let cutOffTime = cutOffTime, let startTime = startTime {// v 2.28.445
                            let cutOffdate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date()) ?? Date()
                            
                            btnResumeHabits.isHidden = false
                            
                            
                            isFreeTimeBeforeShutoff = true
                            let cutOffDateString = getStringFromDate(date: cutOffdate, dateFormat: getSystemTimeFormat())
                            var freeTimeText = "Well done finishing your evening routine 👏\nYour sleep time is <CUTOFFTIME>.\nYour next morning routine starts at <STARTTIME>.\nRest well and recharge for a strong start tomorrow 💪"
                            
                            btnResumeHabits.title = "Change timing"
                            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                                freeTimeText = habitsStateVcInfo.value(forKey: "freeTimeTextNew") as? String ?? freeTimeText
                                btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonChangeTiming") as? String ?? btnResumeHabits.title
                            }
                            let startdate = Calendar.current.date(bySettingHour: startTime.hour, minute: startTime.minute, second: startTime.second, of: Date()) ?? Date()
                            
                            let dateString = getStringFromDate(date: startdate, dateFormat: getSystemTimeFormat())
                            freeTimeText = freeTimeText.replacingOccurrences(of: "<STARTTIME>", with: dateString)
                            freeTimeText = freeTimeText.replacingOccurrences(of: "<CUTOFFTIME>", with: cutOffDateString)
                            
                            lblTitle.stringValue = freeTimeText
                            
                            // check if user force completed evening routine
                            updateUncancelRoutineButtonVisibility(isEveningRoutine: true)
 
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
                            // check if user force completed evening routine
                            updateUncancelRoutineButtonVisibility(isEveningRoutine: true)
                        }
                        
                    }
                }
            }
        }
    }
    
    func removeSubViews(){
        let viewsArr = customView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
    }
    
    func showRutinePostponedInfoView(state:CURRENTSTATE){
        btnResumeHabits.isHidden = true
        lblTitle.isHidden = true
        customView.isHidden = false
        customView.addSubview(getRutinePostponedInfoVcObject().view)
        customView.addConstraints(subView: getRutinePostponedInfoVcObject().view)
        getRutinePostponedInfoVcObject().lCurrentState = state
    }
    
    @IBAction func btnResumeHabitsClicked(_ sender: Any) {
        
        if isShutOffTimeGoing(){
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                if Date().compare(date) == .orderedAscending, let startTime = startTime {
                    leftMenuVcObj?.showEditHabitsView()
                    return;
                }
            }
        }
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
            if sameDay || !shouldDoHabits(){
                addLog(text:"[user-action] habitsStateVc:- button Start Habits First Time clicked")
                menuViewControllerObj?.btnStartHabitsFirstTimeClicked(self)
                return;
            }
        }
        addLog(text:"[user-action] habitsStateVc:- button Resume Habits clicked")
        menuViewControllerObj?.btnResumeHabitsClicked(self)
    }
    
    
    @IBAction func btnUnCancelRoutineClicked(_ sender: Any) {
        mainViewControllerObj?.showLoaderView()
        if isShutOffTimeGoing(){
            allApiObject.uncompleteCurrentSequence(activity_sequence_id: arrFilteredEveningHabits.first?.activity_sequence_id ?? "", completionHandler: {json in
                if json != nil{
                    DispatchQueue.main.async {
                        mainViewControllerObj?.hideLoaderView()
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsEveningHabitsShowedTillDate)
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
                        appdelegate!.backgroundThread()
                    }
                }
            })
        }else{
            
            allApiObject.uncompleteCurrentSequence(activity_sequence_id: arrFilteredMorningHabits.first?.activity_sequence_id ?? "", completionHandler: {json in
                if json != nil{
                    DispatchQueue.main.async {
                        mainViewControllerObj?.hideLoaderView()
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitShowDate)
                        isHabitAlreadyShowed = false
                        appdelegate!.backgroundThread()
                    }
                }
            })
        }
    }
    
    func updateUncancelRoutineButtonVisibility(isEveningRoutine: Bool) {
        let routineType = isEveningRoutine ? "evening_routine" : "morning_routine"
        
        let sequenceIdToCheck = isEveningRoutine
            ? (arrFilteredEveningHabits.first?.activity_sequence_id ?? "")
            : (arrFilteredMorningHabits.first?.activity_sequence_id ?? "")
        
        allApiObject.getLastActivityInfo { json in
            
            guard
                let todayRoutineProgress = json?["today_routine_progress"] as? NSDictionary,
                let routine = todayRoutineProgress[routineType] as? NSDictionary,
                let todaySequenceId = routine["sequence_id"] as? String,
                let status = routine["status"] as? String,
                let wasForceCompleted = routine["was_force_completed"] as? Bool
            else {
                return
            }
            
            let shouldShowButton =
                todaySequenceId == sequenceIdToCheck &&
                status.lowercased() == "completed" &&
                wasForceCompleted
            
            DispatchQueue.main.async { [self] in
                self.btnUnCancelRoutine.isHidden = !shouldShowButton
                btnResumeHabits.isSecondaryButton = true
                if isEveningRoutine{
                    
                    if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                        if Date().compare(date) == .orderedAscending, let startTime = startTime {
                            

                            if let cutOffTime = cutOffTime{
                                let cutOffdate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date()) ?? Date()
                                let cutOffDateString = getStringFromDate(date: cutOffdate, dateFormat: getSystemTimeFormat())
                                var freeTimeText = "Your sleep time is <CUTOFFTIME>.\n\n(By the way, you cancelled your evening routine. if you changed your mind and want to do your evening habits click Uncancel my evening routine)"//todo text
                                
                                freeTimeText = freeTimeText.replacingOccurrences(of: "<CUTOFFTIME>", with: cutOffDateString)
                                lblTitle.stringValue = freeTimeText
                            }else{
                                var freeTimeText = "You do not have sleep time set.\n\n(By the way, you cancelled your evening routine. if you changed your mind and want to do your evening habits click Uncancel my evening routine)"//todo text
                                lblTitle.stringValue = freeTimeText
                                
                            }
                            
                            var shutoffAbortedText = "Your morning routine starts at <TIME> — time to log off and rest."
                            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                                shutoffAbortedText = habitsStateVcInfo.value(forKey: "shutoffAbortedTextNew") as? String ?? shutoffAbortedText
                            }
                            
                            let startdate = Calendar.current.date(bySettingHour: startTime.hour, minute: startTime.minute, second: startTime.second, of: Date()) ?? Date()
                            
                            let dateString = getStringFromDate(date: startdate, dateFormat: getSystemTimeFormat())
                            shutoffAbortedText = shutoffAbortedText.replacingOccurrences(of: "<TIME>", with: dateString)
                            
                            lblDescription.stringValue = shutoffAbortedText
                            lblDescription.isHidden = false
                            
                            
                            btnResumeHabits.isHidden = false
                            btnResumeHabits.title = "Change timing"
                            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                                btnResumeHabits.title = habitsStateVcInfo.value(forKey: "buttonChangeTiming") as? String ?? btnResumeHabits.title
                            }
                            return;
                        }
                    }
                    
                    if let startTime = startTime {
                        if let cutOffTime = cutOffTime{
                            let cutOffdate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date()) ?? Date()
                            let cutOffDateString = getStringFromDate(date: cutOffdate, dateFormat: getSystemTimeFormat())
                            var freeTimeText = "Your sleep time is <CUTOFFTIME>.\n\n(By the way, you cancelled your evening routine. if you changed your mind and want to do your evening habits click Uncancel my evening routine)"//todo text
                            
                            freeTimeText = freeTimeText.replacingOccurrences(of: "<CUTOFFTIME>", with: cutOffDateString)
                            lblTitle.stringValue = freeTimeText
                        }else{
                            var freeTimeText = "You do not have sleep time set.\n\n(By the way, you cancelled your evening routine. if you changed your mind and want to do your evening habits click Uncancel my evening routine)"//todo text
                            lblTitle.stringValue = freeTimeText
                            
                        }
                        
                        let startdate = Calendar.current.date(bySettingHour: startTime.hour, minute: startTime.minute, second: startTime.second, of: Date()) ?? Date()
                        let dateString = getStringFromDate(date: startdate, dateFormat: getSystemTimeFormat())
                        lblDescription.stringValue = "Your next morning routine starts at <STARTTIME>.\nRest well and recharge for a strong start tomorrow 💪"//todo text
                        lblDescription.stringValue = lblDescription.stringValue.replacingOccurrences(of: "<STARTTIME>", with: dateString)
                        
                        lblDescription.isHidden = false
                    }
                }else{
                    let (nextRoutine, nextRoutineName, nextRoutineIsEveningRoutine) = getNextRoutineInfo()
                    
                   
                    let (dateString) = getStringFromDate(date: nextRoutine, dateFormat: getSystemTimeFormat())
                    var nextRoutineText = "Your next scheduled routine (<ROUTINE>) is set for <TIME>. Be ready to jump back in and continue building those healthy habits. You've got this!\n(By the way, you cancelled your evening routine. if you changed your mind and want to do your evening habits click Uncancel my evening routine)" // todo text
                    if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                        //nextRoutineText = habitsStateVcInfo.value(forKey: "nextRoutineTimeCancelledMorninigRoutine") as? String ?? nextRoutineText
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
                }
                
            }
        }
    }
}
