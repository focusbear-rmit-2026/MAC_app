//
//  ViewController.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var btnAbort: NSButton!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var boxContainer: NSBox!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblMessage.stringValue = "OK - Stay focused throughout the day!"
        lblMessage.isHidden = true
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblMessage.stringValue = common.value(forKey: "stayFocusedText") as? String ?? lblMessage.stringValue
        }
        isMainWindowLodded = true
    }
    func showFocusCompletedView(){
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(focusCompletedVcObj!.view)
        containerView.addConstraints(subView: focusCompletedVcObj!.view)
        currentState = ._FOCUS_COMPLETED_
    }
    
    func showFocusSummaryView(){
        addLog(text: "Showing Focus Summary")
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(focusSummaryVcObj!.view)
        containerView.addConstraints(subView: focusSummaryVcObj!.view)
        currentState = ._FOCUS_SUMMARY_
        
        if startTime == nil || shutOffTime == nil{
            return;
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }
        
    }
    func showLogQuantityView(){
        self.view.addSubview(logQuantityVcObj!.view)
        self.view.addConstraints(subView: logQuantityVcObj!.view)
    }
    @IBAction func btnAbortClicked(_ sender: Any) {
        lastCurrentState = currentState
        lastCurrentAction = currentAction
        btnAbort.isHidden = true
        if currentAction == ._INPROGRESS_{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_{
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        if timerViewcontrollerObj?.webView.isHidden == false{
                            timerViewcontrollerObj?.loadBlankUrl()
                        }
                    }
                }
            }
        }
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{
                self.view.addSubview(enterPasswordVcObj!.view)
                self.view.addConstraints(subView: enterPasswordVcObj!.view)
                addLog(text: "Showing enter password view")
            }else{
                showAbortStartView()
            }
        }else{
            showAbortStartView()
        }
    }
    func showAbortStartView(){
        removeSubViews()
        containerView.addSubview(abortingCountDownVcObj!.view)
        containerView.addConstraints(subView: abortingCountDownVcObj!.view)
        abortingCountDownVcObj?.startTimer()
        currentState = ._ABORT_
    }
    func abortCancel(){
        btnAbort.isHidden = false
        removeSubViews()
        if lastCurrentState == ._ACTIVITY_{
            switch lastCurrentAction {
            case ._START_:
               self.containerView.addSubview(thirdVcObj!.view)
               self.containerView.addConstraints(subView: thirdVcObj!.view)
               thirdVcObj?.startBreakActivity()
               currentState = ._ACTIVITY_
               currentAction = ._START_
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
//                if isAnyMandatoryActivityIncluded{
//                    if isMandatoryActivityGoing{
//                        timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: timerViewcontrollerObj?.currentDurationInSeconds ?? 0, name: timerViewcontrollerObj?.currentActicityTitle ?? "", url: timerViewcontrollerObj?.currentUrl)
//                    }else{
//                        timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: arrActivitiesExcludeInEveryBreak[currentActivityIndex].durationSeconds, name: arrActivitiesExcludeInEveryBreak[currentActivityIndex].name!, url: arrActivitiesExcludeInEveryBreak[currentActivityIndex].urlsArray.randomElement())
//                    }
//                }else{
//                    timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: arrAllbreakActivities[currentActivityIndex].durationSeconds, name: arrAllbreakActivities[currentActivityIndex].name!, url: arrAllbreakActivities[currentActivityIndex].urlsArray.randomElement())
//                }
                timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: timerViewcontrollerObj?.currentDurationInSeconds ?? 0, name: timerViewcontrollerObj?.currentActicityTitle ?? "", url: timerViewcontrollerObj?.currentUrl)
                currentState = ._ACTIVITY_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                removeSubViews()
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._ACTIVITY_
                currentAction = ._END_
                break
            }
        }else if lastCurrentState == ._MORNING_HABIT_{
            switch lastCurrentAction {
            case ._START_:
               showAllMorningHabits()
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!)
                currentState = ._MORNING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                removeSubViews()
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._MORNING_HABIT_
                currentAction = ._END_
                break
            }
            
        }else if lastCurrentState == ._EVENING_HABIT_{
            switch lastCurrentAction {
            case ._START_:
               showAllEveningHabits()
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!)
                currentState = ._EVENING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                removeSubViews()
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._EVENING_HABIT_
                currentAction = ._END_
                break
            }
            
        }else if lastCurrentState == ._SHUTOFFMAC_{
            shutOffMac()
        }
    }
    
    func showAbortConfirmationView(){
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(abortingConfirmVcObj!.view)
        containerView.addConstraints(subView: abortingConfirmVcObj!.view)
        abortingConfirmVcObj!.resetData()
        currentState = ._ABORT_
    }
    func showAbortStartSmallVc(isAnyHabitRemoved:Bool){
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(abortingCantHandleVcObj!.view)
        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = true
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: isAnyHabitRemoved)
        currentState = ._ABORT_
    }
    func showAbortDisableMorningRoutineVc(){
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(abortingCantHandleVcObj!.view)
        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = false
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: false)
        currentState = ._ABORT_
    }
    func showAbortDoneView(){
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(abortDoneVcObj!.view)
        containerView.addConstraints(subView: abortDoneVcObj!.view)
        abortDoneVcObj?.startTimer()
        currentState = ._ABORT_
    }
    func disableApp(){
        addLog(text: "App Deactivated by user (Aborted)")
        UserDefaults.standard.set(false, forKey: kUserdefaultsIsAppEnabled)
        if lastCurrentState == ._MORNING_HABIT_{
            UserDefaults.standard.set(true, forKey: kUserdefaultsShowPomodoroView)
        }else{
            UserDefaults.standard.removeObject(forKey: kUserdefaultsShowPomodoroView)
        }
        appdelegate?.quitAndRestartApp()
        return;
       
//        removeSubViews()
//        appdelegate?.abortAllProcess()
//        mainWindowControllerObj?.window?.setIsVisible(false)
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    func removeSubViews(){
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
    }
    func shutOffMac(){
        isHabitAlreadyShowed = false
        if currentState == ._SHUTOFFMAC_{
            return;
        }
        addLog(text: "Showing Shut Off screen.")
        btnAbort.isHidden = true//changed no abort button in shut off view 
        removeSubViews()
        containerView.addSubview(shutOffTimeVcObj!.view)
        containerView.addConstraints(subView: shutOffTimeVcObj!.view)
        currentState = ._SHUTOFFMAC_
        if self.breakTimer != nil{
            self.breakTimer?.invalidate()
            self.breakTimer = nil
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showFirstTimeVc(){
        addLog(text: "Showing first time welcome activity.")
        btnAbort.isHidden = true
        removeSubViews()
        firstViewControllerObj?.isFirstTime = true
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        currentState = ._BREATHING_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showAllEveningHabits(){
        addLog(text: "Initiate and run Evening Habits.")
        btnAbort.isHidden = false
        removeSubViews()
        currentState = ._EVENING_HABIT_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
        writeEveningRoutineDate()
        if startTime == nil || shutOffTime == nil{
            return;
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
        }
        
    }
    func showAllMorningHabits(){
        addLog(text: "Showing morning habits.")
        btnAbort.isHidden = false
        removeSubViews()
        currentState = ._MORNING_HABIT_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func startFirstMorningHabit() {
        btnAbort.isHidden = false
        removeSubViews()
        currentHabitIndex = 0
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!)
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    func startFirstEveningHabit() {
        btnAbort.isHidden = false
        removeSubViews()
        currentHabitIndex = 0
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!)
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
    }
    func startBreathing() {
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startBreathing()
        currentState = ._BREATHING_
        currentAction = ._INPROGRESS_
    }
    func breathingOver() {
        btnAbort.isHidden = true
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.breathingFinished()
        currentState = ._BREATHING_
        currentAction = ._END_
    }
    func morningHabitOver() {
        btnAbort.isHidden = false
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.morningHabitFinished(index: currentHabitIndex)
        currentState = ._MORNING_HABIT_
        currentAction = ._END_
    }
    func eveningHabitOver() {
        btnAbort.isHidden = false
        removeSubViews()
        if currentHabitIndex < arrAllEveningHabits.count-1 {
            containerView.addSubview(thirdVcObj!.view)
            containerView.addConstraints(subView: thirdVcObj!.view)
            thirdVcObj!.eveningHabitFinished(index: currentHabitIndex)
            currentState = ._EVENING_HABIT_
            currentAction = ._END_
        }else{
            playAfterMorningRoutineSound()
            shutOffMac()
            if arrAllEveningHabits[currentHabitIndex].logQuantity{
                mainViewControllerObj!.showLogQuantityView()
                let lastHabit = arrAllEveningHabits[currentHabitIndex].name
                logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(arrAllEveningHabits[currentHabitIndex].durationSeconds!)", logQuantityQuestion: arrAllEveningHabits[currentHabitIndex].logQuantityQuestion, currentState: ._EVENING_HABIT_)
            }else{
                let lastHabit = arrAllEveningHabits[currentHabitIndex].name
                let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
                addEntryInCsv(logType: "evening routine", activity: lastHabit!, durationInSeconds: "\(arrAllEveningHabits[currentHabitIndex].durationSeconds!)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            }
        }
        
    }
    func activityOver() {
        btnAbort.isHidden = false
        removeSubViews()
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.activityFinished(index: currentActivityIndex)
        currentState = ._ACTIVITY_
        currentAction = ._END_
    }
    func changeMorningHabit() {
        btnAbort.isHidden = false
        removeSubViews()
        currentHabitIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllMorningHabits[currentHabitIndex].durationSeconds, url: arrAllMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllMorningHabits[currentHabitIndex].name!)
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    func changeEveningHabit() {
        btnAbort.isHidden = false
        removeSubViews()
        currentHabitIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllEveningHabits[currentHabitIndex].durationSeconds, url: arrAllEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrAllEveningHabits[currentHabitIndex].name!)
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    
    func startCurrentActivity() {
        btnAbort.isHidden = false
        removeSubViews()
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        if isMandatoryActivityGoing{
            let currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
            
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion)
            }else{//random choice
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                }
            }
            
            
        }else{
            let currentActivity = arrAllbreakActivities[currentActivityIndex]
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion)
            }else{//random choice
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                }
            }
            
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    func changeActivity() {
        btnAbort.isHidden = false
        removeSubViews()
      //  isBreakActivitiesGoing = true
//        currentActivityIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        if isAnyMandatoryActivityIncluded{
            if isMandatoryActivityGoing{
                let lastIndex = currentActivityIndex
                currentActivityIndex += 1
                if currentActivityIndex > arrActivitiesIncludeInEveryBreak.count - 1{
                    currentActivityIndex = lastIndex// phle hi current index awt ki thi ..is condition k liye
                    isMandatoryActivityGoing = false//
                    
                    let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                    
                    if !currentActivity.isRandomChoice{
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion)
                    }else{
                        if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                        }else if let randomChoice = currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                        }
                    }
                    
                }else{
                    let currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
                    
                    if !currentActivity.isRandomChoice{
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion)
                    }else{
                        if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                        }else if let randomChoice = currentActivity.choices.randomElement(){
                            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                        }
                    }
                }
            }else{
                let currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                
                if !currentActivity.isRandomChoice{
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion)
                }else{
                    if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                    }else if let randomChoice = currentActivity.choices.randomElement(){
                        timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                    }
                }
            }
        }else{
            currentActivityIndex += 1
            let currentActivity = arrAllbreakActivities[currentActivityIndex]
            
            if !currentActivity.isRandomChoice{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, url: currentActivity.urlsArray.randomElement(), logQuantityQuestion: currentActivity.logQuantityQuestion)
            }else{
                if let randomChoice = thirdVcObj?.currentActivityChoice{//currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                }else if let randomChoice = currentActivity.choices.randomElement(){
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, url: randomChoice.urlsArray.randomElement(), logQuantityQuestion: randomChoice.logQuantityQuestion ?? currentActivity.logQuantityQuestion)
                }
            }
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    
    func habitsFinishedUnlockMachine() {
        btnAbort.isHidden = true
        removeSubViews()
        lblMessage.isHidden = false
        currentHabitIndex = -1
        self.perform(#selector(unlockMachine), with: nil, afterDelay: 3)
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) as? Bool{
            if state{
                appdelegate?.showPomodoroModeView()
            }
        }
        currentState = ._NOTHING_
    }
    @objc func unlockMachine() {
        lblMessage.isHidden = true
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        setActivityTimer()
        if isFirstRun{//welcome routine k baad set krenge (when first time)
            appdelegate!.setBackgroundThreadTimer()
            isFirstRun = false
        }
    }
    var breakTimer: Timer?
    func setActivityTimer(){
        addLog(text: "Break Activity Timer reset Done.")
        if arrAllbreakActivities.count != 0 {
            DispatchQueue.global().async {
                print("breakAfterMinutesxxxx")
                if self.breakTimer != nil{
                    self.breakTimer?.invalidate()
                    self.breakTimer = nil
                }
                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(breakAfterMinutes*60), target: self, selector: #selector(self.startBreakActivities), userInfo: nil, repeats: false)
                RunLoop.current.add(self.breakTimer!, forMode: RunLoop.Mode.common)
                RunLoop.current.run()
            }
        }
    }
    func activityFinishedUnlockMachine() {
        btnAbort.isHidden = true
        removeSubViews()
        //        lblMessage.isHidden = false
//        isBreakActivitiesGoing = false
        currentActivityIndex = -1
        unlockMachine()
        currentState = ._NOTHING_
    }
    func breathingFinishedUnlockMachine(){
        btnAbort.isHidden = true
        removeSubViews()
        lblMessage.isHidden = false
//        isBreathingGoing = false
        self.perform(#selector(unlockMachine), with: nil, afterDelay: 3)
        currentState = ._NOTHING_
    }
    
    @objc func startBreakActivities() {
        DispatchQueue.main.async {
            addLog(text: "Initiating Break Activities")
            if avmonitor.isMicOn(){
                self.setActivityTimer()
                addLog(text: "Mic is in use, Break Activities cancelled.")
                return;
            }
            if avmonitor.isACameraOn(){
                self.setActivityTimer()
                addLog(text: "Camera is in use, Break Activities cancelled.")
                return;
            }
            if currentState == ._SHUTOFFMAC_{
                addLog(text: "App is in shutoff state, Break Activities cancelled.")
                return;
            }
            if currentState == ._ABORT_{
                addLog(text: "App is disabled, Break Activities cancelled.")
                return;
            }
            
            
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let currentDate = Date()
            if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
                return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga// iise focus summary or evening routine k time per bhi rreturn ho jayga
            }
            self.breakTimer = nil
            if arrAllbreakActivities.count != 0 {
                self.btnAbort.isHidden = false
//                isBreakActivitiesGoing = true
                isAnyMandatoryActivityIncluded = false
                arrActivitiesExcludeInEveryBreak.removeAll()
                arrActivitiesIncludeInEveryBreak.removeAll()
                isMandatoryActivityGoing = false
                if showEveryBreak{
                    currentActivityIndex = 0
                }else{
                    for activity in arrAllbreakActivities{
                        if activity.IncludeInEveryBreak{
                            isAnyMandatoryActivityIncluded = true//than two step will be happen// first mandatory arra than normal array
                            arrActivitiesIncludeInEveryBreak.append(activity)
                        }else{
                            arrActivitiesExcludeInEveryBreak.append(activity)
                        }
                    }
                    if isAnyMandatoryActivityIncluded{
                        isMandatoryActivityGoing = true
                        currentActivityIndex = 0
                    }else{
                        currentActivityIndex = Int(arc4random_uniform(UInt32(arrAllbreakActivities.count)))
                    }
                }
                self.removeSubViews()
                self.containerView.addSubview(thirdVcObj!.view)
                self.containerView.addConstraints(subView: thirdVcObj!.view)
                thirdVcObj?.startBreakActivity()
                mainWindowControllerObj?.window?.setIsVisible(true)
                showBlankWindowInSecondaryMonitor()
                NSApplication.shared.activate(ignoringOtherApps: true)
                currentState = ._ACTIVITY_
                currentAction = ._START_
            }
        }
    }
    
    func emergencyStartDone(){
        btnAbort.isHidden = true
        removeSubViews()
        currentState = ._NOTHING_
        mainWindowControllerObj?.window?.setIsVisible(false)
        hideBlankWindowInSecondaryMonitor()
        
        if startTime == nil || shutOffTime == nil{
            return;
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsShutdownAborted)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsShutdownAborted)
        }
        
    }
    @IBAction func btnHiddenClicked(_ sender: Any) {
        //mainWindowControllerObj?.window?.close()
    }
}

