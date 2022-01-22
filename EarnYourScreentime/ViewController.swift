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
        
    }
    @IBAction func btnAbortClicked(_ sender: Any) {
//        if currentState == .
//        currentAction
        lastCurrentState = currentState
        lastCurrentAction = currentAction
        btnAbort.isHidden = true
        if isHabitGoing {
            isHabitGoing = false
            if timerViewcontrollerObj != nil {
                if timerViewcontrollerObj?.timer != nil {
                    timerViewcontrollerObj?.timer?.invalidate()
                    if currentAction == ._INPROGRESS_{
                        if timerViewcontrollerObj?.webView.isHidden == false{
                            timerViewcontrollerObj?.loadBlankUrl()
                        }
                    }
                }
            }
        }
        else if isBreakActivitiesGoing {
            if timerViewcontrollerObj != nil {
                if timerViewcontrollerObj?.timer != nil {
                    timerViewcontrollerObj?.timer?.invalidate()
                    if currentAction == ._INPROGRESS_{
                        if timerViewcontrollerObj?.webView.isHidden == false{
                            timerViewcontrollerObj?.loadBlankUrl()
                        }
                    }
                }
            }
            isBreakActivitiesGoing = false
        }else if isBreathingGoing {
            if timerViewcontrollerObj != nil {
                if timerViewcontrollerObj?.timer != nil {
                    timerViewcontrollerObj?.timer?.invalidate()
                    if currentAction == ._INPROGRESS_{
                        if timerViewcontrollerObj?.webView.isHidden == false{
                            timerViewcontrollerObj?.loadBlankUrl()
                        }
                    }
                }
            }
            
            isBreathingGoing = false
        }
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(abortingCountDownVcObj!.view)
        containerView.addConstraints(subView: abortingCountDownVcObj!.view)
        abortingCountDownVcObj?.startTimer()
        currentState = ._ABORT_
    }
    
    func abortCancel(){
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        if lastCurrentState == ._ACTIVITY_{
            isBreakActivitiesGoing = true
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
//                timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: arrAllbreakActivities[currentActivityIndex].durationSeconds, name: arrAllbreakActivities[currentActivityIndex].name!)
                
                
                
                
                if isAnyMandatoryActivityIncluded{
                    if isMandatoryActivityGoing{
                        timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: arrActivitiesIncludeInEveryBreak[currentActivityIndex].durationSeconds, name: arrActivitiesIncludeInEveryBreak[currentActivityIndex].name!, url: arrActivitiesIncludeInEveryBreak[currentActivityIndex].url)
                    }else{
                        timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: arrActivitiesExcludeInEveryBreak[currentActivityIndex].durationSeconds, name: arrActivitiesExcludeInEveryBreak[currentActivityIndex].name!, url: arrActivitiesExcludeInEveryBreak[currentActivityIndex].url)
                    }
                }else{
                    timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: arrAllbreakActivities[currentActivityIndex].durationSeconds, name: arrAllbreakActivities[currentActivityIndex].name!, url: arrAllbreakActivities[currentActivityIndex].url)
                }
                
                
                
                currentState = ._ACTIVITY_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                let viewsArr = containerView.subviews
                for subview in viewsArr {
                    subview.removeFromSuperview()
                }
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._ACTIVITY_
                currentAction = ._END_
                break
            }
        }else if lastCurrentState == ._HABIT_{
            isHabitGoing = true
            switch lastCurrentAction {
            case ._START_:
               showAllHabits()
            case ._INPROGRESS_:
                containerView.addSubview(timerViewcontrollerObj!.view)
                containerView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrAllHabits[currentHabitIndex].durationSeconds, url: arrAllHabits[currentHabitIndex].url)
                currentState = ._HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                btnAbort.isHidden = false
                let viewsArr = containerView.subviews
                for subview in viewsArr {
                    subview.removeFromSuperview()
                }
                containerView.addSubview(thirdVcObj!.view)
                containerView.addConstraints(subView: thirdVcObj!.view)
                currentState = ._HABIT_
                currentAction = ._END_
                break
            }
            
        }else if lastCurrentState == ._SHUTOFFMAC_{
            shutOffMac()
        }
    }
    
    func showAbortConfirmationView(){
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(abortingConfirmVcObj!.view)
        containerView.addConstraints(subView: abortingConfirmVcObj!.view)
        abortingConfirmVcObj!.resetData()
        currentState = ._ABORT_
    }
    func showAbortStartSmallVc(isAnyHabitRemoved:Bool){
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(abortingCantHandleVcObj!.view)
        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = true
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: isAnyHabitRemoved)
        currentState = ._ABORT_
    }
    func showAbortDisableMorningRoutineVc(){
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(abortingCantHandleVcObj!.view)
        containerView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = false
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: false)
        currentState = ._ABORT_
    }
    func showAbortDoneView(){
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(abortDoneVcObj!.view)
        containerView.addConstraints(subView: abortDoneVcObj!.view)
        abortDoneVcObj?.startTimer()
        currentState = ._ABORT_
    }
    func disableApp(){
        UserDefaults.standard.set(false, forKey: kUserdefaultsIsAppEnabled)
        appdelegate?.quitAndRestartApp()
        return;
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        appdelegate?.abortAllProcess()
        mainWindowControllerObj?.window?.setIsVisible(false)
        
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    func shutOffMac(){
        if currentState == ._SHUTOFFMAC_{
            return;
        }
        btnAbort.isHidden = true//changed no abort button in shut off view 
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(shutOffTimeVcObj!.view)
        containerView.addConstraints(subView: shutOffTimeVcObj!.view)
        currentState = ._SHUTOFFMAC_
        if self.breakTimer != nil{
            self.breakTimer?.invalidate()
            self.breakTimer = nil
        }
    }
    func showFirstTimeVc(){
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        firstViewControllerObj?.isFirstTime = true
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        currentState = ._FIRST_TIME_
        currentAction = ._START_
    }
    
    func showAllHabits(){
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        firstViewControllerObj?.isFirstTime = false
        containerView.addSubview(firstViewControllerObj!.view)
        containerView.addConstraints(subView: firstViewControllerObj!.view)
        currentState = ._HABIT_
        currentAction = ._START_
    }
    func startFirstHabit() {
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        isHabitGoing = true
        currentHabitIndex = 0
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllHabits[currentHabitIndex].durationSeconds, url: arrAllHabits[currentHabitIndex].url)
        currentState = ._HABIT_
        currentAction = ._INPROGRESS_
    }
    func startBreathing() {
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        isBreathingGoing = true
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startBreathing()
        currentState = ._BREATHING_
        currentAction = ._INPROGRESS_
    }
    func breathingOver() {
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.breathingFinished()
        currentState = ._BREATHING_
        currentAction = ._END_
    }
    func habitOver() {
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.habitFinished(index: currentHabitIndex)
        currentState = ._HABIT_
        currentAction = ._END_
    }
    func activityOver() {
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(thirdVcObj!.view)
        containerView.addConstraints(subView: thirdVcObj!.view)
        thirdVcObj!.activityFinished(index: currentActivityIndex)
        currentState = ._ACTIVITY_
        currentAction = ._END_
    }
    func changeHabit() {
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        isHabitGoing = true
        currentHabitIndex += 1
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startTimerHabit(durationSeconds: arrAllHabits[currentHabitIndex].durationSeconds, url: arrAllHabits[currentHabitIndex].url)
        currentState = ._HABIT_
        currentAction = ._INPROGRESS_
    }
    func startCurrentActivity() {
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        containerView.addSubview(timerViewcontrollerObj!.view)
        containerView.addConstraints(subView: timerViewcontrollerObj!.view)
        if isMandatoryActivityGoing{
            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: arrActivitiesIncludeInEveryBreak[currentActivityIndex].durationSeconds, name: arrActivitiesIncludeInEveryBreak[currentActivityIndex].name!, url: arrActivitiesIncludeInEveryBreak[currentActivityIndex].url)
        }else{
            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: arrAllbreakActivities[currentActivityIndex].durationSeconds, name: arrAllbreakActivities[currentActivityIndex].name!, url: arrAllbreakActivities[currentActivityIndex].url)
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    func changeActivity() {
        btnAbort.isHidden = false
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        isBreakActivitiesGoing = true
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
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: arrActivitiesExcludeInEveryBreak[currentActivityIndex].durationSeconds, name: arrActivitiesExcludeInEveryBreak[currentActivityIndex].name!, url: arrActivitiesExcludeInEveryBreak[currentActivityIndex].url)
                }else{
                    timerViewcontrollerObj?.startTimerActivity(durationInSeconds: arrActivitiesIncludeInEveryBreak[currentActivityIndex].durationSeconds, name: arrActivitiesIncludeInEveryBreak[currentActivityIndex].name!, url: arrActivitiesIncludeInEveryBreak[currentActivityIndex].url)
                }
            }else{
                timerViewcontrollerObj?.startTimerActivity(durationInSeconds: arrActivitiesExcludeInEveryBreak[currentActivityIndex].durationSeconds, name: arrActivitiesExcludeInEveryBreak[currentActivityIndex].name!, url: arrActivitiesExcludeInEveryBreak[currentActivityIndex].url)
            }
        }else{
            currentActivityIndex += 1
            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: arrAllbreakActivities[currentActivityIndex].durationSeconds, name:  arrAllbreakActivities[currentActivityIndex].name!, url: arrAllbreakActivities[currentActivityIndex].url)
        }
        
        currentState = ._ACTIVITY_
        currentAction = ._INPROGRESS_
    }
    
    func habitsFinishedUnlockMachine() {
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        lblMessage.isHidden = false
        isHabitGoing = false
        currentHabitIndex = -1
        self.perform(#selector(unlockMachine), with: nil, afterDelay: 3)
        currentState = ._NOTHING_
    }
    @objc func unlockMachine() {
        lblMessage.isHidden = true
        mainWindowControllerObj?.window?.setIsVisible(false)
        setActivityTimer()
    }
    var breakTimer: Timer?
    func setActivityTimer(){
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
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        //        lblMessage.isHidden = false
        isBreakActivitiesGoing = false
        currentActivityIndex = -1
        unlockMachine()
        currentState = ._NOTHING_
    }
    func breathingFinishedUnlockMachine(){
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        lblMessage.isHidden = false
        isBreathingGoing = false
        self.perform(#selector(unlockMachine), with: nil, afterDelay: 3)
        currentState = ._NOTHING_
    }
    
    @objc func startBreakActivities() {
        DispatchQueue.main.async {
            if avmonitor.currentState == NSControl.StateValue.on{
                self.setActivityTimer()
                return;
            }
            if currentState == ._SHUTOFFMAC_ || currentState == ._ABORT_{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let currentDate = Date()
            if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
                return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga
            }
            self.breakTimer = nil
            if arrAllbreakActivities.count != 0 {
                self.btnAbort.isHidden = false
                isBreakActivitiesGoing = true
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
                let viewsArr = self.containerView.subviews
                for subview in viewsArr {
                    subview.removeFromSuperview()
                }
                self.containerView.addSubview(thirdVcObj!.view)
                self.containerView.addConstraints(subView: thirdVcObj!.view)
                thirdVcObj?.startBreakActivity()
                mainWindowControllerObj?.window?.setIsVisible(true)
                currentState = ._ACTIVITY_
                currentAction = ._START_
            }
        }
    }
    
    func emergencyStartDone(){
        btnAbort.isHidden = true
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        currentState = ._NOTHING_
        mainWindowControllerObj?.window?.setIsVisible(false)
        
        
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
        mainWindowControllerObj?.window?.close()
    }
}

