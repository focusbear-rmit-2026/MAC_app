//
//  smallCountDownVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/05/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class smallCountDownVc: NSViewController {

    @IBOutlet weak var btnClose: cursorButton!
    @IBOutlet weak var lblTimerTopSpaceConstraint: NSLayoutConstraint!
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
        
    }
    
    func closeTimerBox(){
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()
    }
    
    override func viewWillAppear() {
//        btnPostpone.isHidden = true
        //****** Allow  postpone from timer window in morning evening routine in allow app case******//#213  date- 5/9/22
        
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && !isFocusBreak{
            addLog(text:"button Postpone Clicked")
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            mainViewControllerObj?.btnAbortClicked(self)
        }else if currentState == ._FOCUS_SUMMARY_{
            addLog(text:"button Back To My Habits")
            closeTimerBox()
            mainViewControllerObj?.timerGiveOneMoreMinut?.invalidate()
            mainViewControllerObj?.timerGiveOneMoreMinut = nil
            mainViewControllerObj?.showFocusSummaryView()
        }
        
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        if isFocusBreak{
            closeTimerBox()
        }else{
//            let (_,m,_) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
//            if m < 2{
//                closeTimerBox()
//            }else{
//                self.view.window?.alphaValue = 0
//            }
            self.view.window?.alphaValue = 0
            
            
            
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_) && !(mainWindowControllerObj?.window?.isVisible ?? false){
                if currentHabitPlaying != nil || currentActivityPlaying != nil{
                    NSApp.hide(self)
                }
            }
        }
    }
    
    func resumeTimerHabit(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
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
        
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && !isFocusBreak{
            lblTimerTopSpaceConstraint.constant = 10
            btnPostpone.isHidden = false
            btnPostpone.title = "Postpone"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnPostpone.title = common.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
            }
        }else if currentState == ._FOCUS_SUMMARY_{
            lblTimerTopSpaceConstraint.constant = 10
            btnPostpone.isHidden = false
            btnPostpone.title = "Back to my habits"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnPostpone.title = common.value(forKey: "buttonBackToMyHabitsText") as? String ?? btnPostpone.title
            }
        }else{
            lblTimerTopSpaceConstraint.constant = 15
            btnPostpone.isHidden = true
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
                    NSApplication.shared.activate(ignoringOtherApps: true)
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
                self.timer?.invalidate()
                self.view.window?.close()
                if self.isFocusBreak{
                    playFocusPomodorBreakEndsSound()
                }
            }
        }
        
    }
}
