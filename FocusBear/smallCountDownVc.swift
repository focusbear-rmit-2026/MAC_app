//
//  smallCountDownVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/05/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class smallCountDownVc: NSViewController {

    @IBOutlet weak var btnSkip: underLineButton!
    @IBOutlet weak var btnClose: cursorButton!
   // @IBOutlet weak var lblTimerTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnPostpone: underLineButton!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var isFocusBreak = false/// it measn postpone notification, focus break and focus is about to end notification
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnSkip.title = "Skip"
        btnSkip.isHidden = true
        
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            btnSkip.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
        }
    }
    
    func closeTimerBox(){
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
//        self.view.window?.close()
//        self.view.isHidden = true
        floatingTopBarVcObj?.boxTimer.isHidden = true
        floatingTopBarVcObj?.timerBoxClosed()
    }
    
//    func isVisible()-> Bool{
//        return !self.view.isHidden
//    }
    
    override func viewWillAppear() {
//        btnPostpone.isHidden = true
        //****** Allow  postpone from timer window in morning evening routine in allow app case******//#213  date- 5/9/22
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] smallCountDownVc:- button Skip Clicked")
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_{
            isLastActivityStoppedInRunningState = true
            lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            timerViewcontrollerObj?.btnPauseClicked(self)
            timerViewcontrollerObj?.menuItemSkipHabitClicked()

            if currentState == ._CUSTOM_ROUTINE_{
                leftMenuVcObj?.showCustomRoutineView()
                leftMenuVcObj?.disableAllExceptCustomRoutineTab()
            }else{
                leftMenuVcObj?.showHabitsView()
                leftMenuVcObj?.disableAllExceptHabitTab()
            }
            
            closeTimerBox()
            
            if relaxModeWcObj != nil{
                if relaxModeWcObj!.window?.isVisible ?? false{
                    relaxModeVcObj?.closeTimerBox()
                }
            }
        }else{
            closeTimerBox()
        }
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && !isFocusBreak{
            addLog(text:"[user-action] smallCountDownVc:- button Postpone Clicked")
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            if currentState == ._CUSTOM_ROUTINE_{
                leftMenuVcObj?.showCustomRoutineView()
                leftMenuVcObj?.disableAllExceptCustomRoutineTab()
            }else{
                leftMenuVcObj?.showHabitsView()
                leftMenuVcObj?.disableAllExceptHabitTab()
            }
          //  if checkIsFullScreenEnabled(){
             //   mainViewControllerObj?.checkIsFullScreenNeeded()
           // }
            getHabitsVcObject().abortCurrentState()
            if quittingWcObj != nil{
                if quittingWcObj?.window?.isVisible ?? false{
                    quittingWcObj?.window?.close()
                }
            }
            setDocBarTo(isHide: false)
        }else if currentState == ._FOCUS_SUMMARY_{
            addLog(text:"button Back To My Habits")
            closeTimerBox()
            getHabitsVcObject().timerGiveOneMoreMinut?.invalidate()
            getHabitsVcObject().timerGiveOneMoreMinut = nil
            getHabitsVcObject().showFocusSummaryView()
            leftMenuVcObj?.showHabitsView()
        }else if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_ || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit) || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit){
            addLog(text:"[user-action] button Extend postpone time Clicked")
            lastCurrentState = currentState 
            closeTimerBox()
            showEasyPostponeWindow()//  (if customroutine is on and custom routine was from postpone morning) if is focus break is false then this should be ongoing custom  routine other wise this should be extend postpone of morning evening
            easyPostponeVcObj?.isForExtendPostponeDuringCustomRoutine = true
        }
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {// not in use
        addLog(text:"[user-action] smallCountDownVc:- btnCloseClicked")
        if isFocusBreak{
            closeTimerBox()
        }else{  
            self.view.window?.alphaValue = 0
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_) && !(mainWindowControllerObj?.window?.isVisible ?? false){
                if currentHabitPlaying != nil || currentActivityPlaying != nil{
                    var isAnyStanderdWindowVisible = false
                    
                    for win in NSApp.windows{
                        if win.isVisible && win.hasTitleBar{
                            isAnyStanderdWindowVisible = true
                        }
                    }
                    if !isAnyStanderdWindowVisible{
                        NSApp.hide(self)
                    }
                }
            }
        }
    }
    
    func resumeTimerHabit(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        lblTimer.isHidden = false
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1 {
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    
    func startTimerHabit(durationSeconds:Int, msg:String, currentTimerValue:Int) {
        let lblTopSpaceInBigFont:CGFloat = 3
        let lblTopSpaceInNormalFont:CGFloat = 10
        let lblTopSpaceDefault:CGFloat = 15
        
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && !isFocusBreak{
            if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
                //lblTimerTopSpaceConstraint.constant = lblTopSpaceInBigFont
            }else{
                //lblTimerTopSpaceConstraint.constant = lblTopSpaceInNormalFont
            }
            btnPostpone.isHidden = false
            btnPostpone.title = "Postpone"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnPostpone.title = common.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
            }
            btnSkip.isHidden = false
        }else if currentState == ._FOCUS_SUMMARY_{
            if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
               // lblTimerTopSpaceConstraint.constant = lblTopSpaceInBigFont
            }else{
              //  lblTimerTopSpaceConstraint.constant = lblTopSpaceInNormalFont
            }
            btnPostpone.isHidden = false
            btnPostpone.title = "Back to my habits"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnPostpone.title = common.value(forKey: "buttonBackToMyHabitsText") as? String ?? btnPostpone.title
            }
            btnSkip.isHidden = true
        }else if (currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_ || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit) || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit)) && !msg.isEmpty{
            
            if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
               // lblTimerTopSpaceConstraint.constant = lblTopSpaceInBigFont
            }else{
                //lblTimerTopSpaceConstraint.constant = lblTopSpaceInNormalFont
            }
            btnPostpone.isHidden = false
            btnPostpone.title = "Postpone"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnPostpone.title = common.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
            }
            btnSkip.isHidden = false   // allow skipping a postponed/allowed-app habit too
        }else{
           // lblTimerTopSpaceConstraint.constant = lblTopSpaceDefault
            btnPostpone.isHidden = true
            btnSkip.isHidden = true
        }
        self.view.window?.alphaValue = 1
        
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        if isFocusBreak && msg.isEmpty{
            lblTitle.stringValue = "Your break ends in"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                lblTitle.stringValue = common.value(forKey: "focusBreakNotificationTitle") as? String ?? lblTitle.stringValue
            }
        }else{
            lblTitle.stringValue = msg//getDoSomeActivityText(activityName: name)
        }
        
        lblTimer.isHidden = false
        
        currentTimer = currentTimerValue
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1 {
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func performTimerCount() {
        
        currentTimer += 1 
        let remainingSeconds = self.totalDuration-currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        if remainingSeconds == 120{
            DispatchQueue.main.async {
                if self.view.window?.alphaValue == 0{
                    self.view.window?.alphaValue = 1
                    //NSApplication.shared.activate(ignoringOtherApps: true)//done 
                }
            }
        }
        if hour.count == 1 {
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                if self.view.window?.alphaValue == 0{
                    self.view.window?.alphaValue = 1
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
//                self.timer?.invalidate()
//                self.view.window?.close()
//                self.view.isHidden = true
                self.closeTimerBox()
                if self.isFocusBreak{
                    playFocusPomodorBreakEndsSound()
                }
            }
        }
        
    }
}
