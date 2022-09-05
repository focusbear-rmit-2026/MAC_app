//
//  askPostponeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askPostponeVc: NSViewController {

    @IBOutlet weak var lblSelectMinutes: NSTextField!
    @IBOutlet weak var btnOkIWillDoBreak: Button!
    @IBOutlet weak var btnAbortBreak: Button!
    @IBOutlet weak var btnPostpone: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var popUpButtonSelectMinutes: NSPopUpButton!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        btnOkIWillDoBreak.title = "Argh ok I'll take a break!"
        lblSelectMinutes.stringValue = "Select minutes to postpone:"
        popUpButtonSelectMinutes.removeAllItems()
        popUpButtonSelectMinutes.addItems(withTitles: ["5", "10", "15", "20", "25", "30"])
        
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnOkIWillDoBreak.title
            lblSelectMinutes.stringValue = activityPostponeInfo.value(forKey: "selectMinutesText") as? String ?? lblSelectMinutes.stringValue
        }
        
    }
    
    override func viewWillAppear() {
        
    }
    func resetView(){
        btnPostpone.isHidden = false
        btnAbortBreak.isHidden = false
        btnOkIWillDoBreak.isHidden = true
        lblTimer.isHidden = true
        if currentState == ._MORNING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._EVENING_HABIT_{
            popUpButtonSelectMinutes.isHidden = false
            lblSelectMinutes.isHidden = false
            popUpButtonSelectMinutes.selectItem(at: 0)
            lblTitle.stringValue = "If you have something urgent, you can postpone Habits for few Minutes."
            btnPostpone.title = "Postpone Habit"
            btnAbortBreak.title = "Completely Skip"
            
            if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
                lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponeHabitsText") as? String ?? lblTitle.stringValue
                btnPostpone.title = activityPostponeInfo.value(forKey: "buttonPostponeHabitText") as? String ?? btnPostpone.title
                btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonCompletelySkipText") as? String ?? btnAbortBreak.title
            }
            
        }else if currentState == ._ACTIVITY_{
            popUpButtonSelectMinutes.isHidden = true
            lblSelectMinutes.isHidden = true
            lblTitle.stringValue = "If you have something urgent, you can postpone the Break Activity for 5 Minutes."
            btnPostpone.title = "Postpone Break"
            btnAbortBreak.title = "Abort Break Activity"
            
            if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
                lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponeBreakText") as? String ?? lblTitle.stringValue
                btnPostpone.title = activityPostponeInfo.value(forKey: "buttonPostponeBreakText") as? String ?? btnPostpone.title
                btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonAbortBreakText") as? String ?? btnAbortBreak.title
            }
        }
    }
//    habits for few minutes
//    Postpone Habit
//    Completely Skip
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "Ask postpone view - button Postpone Clicked")
        
        if currentState == ._MORNING_HABIT_{
            if activityPostponeCount == 0{
                mainViewControllerObj?.postponeMorningHabitFor(minutes: (popUpButtonSelectMinutes.indexOfSelectedItem + 1) * 5)
                activityPostponeCount += 1
            }else{// agar password set na ho to
                self.view.removeFromSuperview()
                if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                    mainViewControllerObj?.showPasswordView()
                    enterPasswordVcObj?.parentVc = self
                }else{
                    mainViewControllerObj?.postponeMorningHabitFor(minutes: (popUpButtonSelectMinutes.indexOfSelectedItem + 1) * 5)
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            if activityPostponeCount == 0{
                mainViewControllerObj?.postponeEveningHabitFor(minutes: (popUpButtonSelectMinutes.indexOfSelectedItem + 1) * 5)
                activityPostponeCount += 1
            }else{// agar password set na ho to
                self.view.removeFromSuperview()
                if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                    mainViewControllerObj?.showPasswordView()
                    enterPasswordVcObj?.parentVc = self
                }else{
                    mainViewControllerObj?.postponeEveningHabitFor(minutes: (popUpButtonSelectMinutes.indexOfSelectedItem + 1) * 5)
                }
            }
        }else if currentState == ._ACTIVITY_{
            if activityPostponeCount == 0{
                mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5)
                activityPostponeCount += 1
            }else{
                btnAbortBreak.isHidden = true
                btnPostpone.isHidden = true
                btnOkIWillDoBreak.isHidden = false
                lblTitle.stringValue = "You postponed the last break - are you sure you can't make time for the break now?"
                if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
                    lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponedLastBreakText") as? String ?? lblTitle.stringValue
                }
                startTimer(duration: 15)
            }
        }else if currentState == ._FOCUS_SUMMARY_{
            self.view.removeFromSuperview()
            
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.parentVc = self
            }else{
                mainViewControllerObj?.postponeFocusSummaryFor(minutes: (popUpButtonSelectMinutes.indexOfSelectedItem + 1) * 5)
            }
        }

        
    }
    @IBAction func btnAbortBreakClicked(_ sender: Any) {
        addLog(text: "Ask postpone view - button Abort Clicked")
        self.view.removeFromSuperview()
        mainViewControllerObj?.processAborting()
    }
    @IBAction func btnOkIWillDoBreakClicked(_ sender: Any) {
        addLog(text: "Ask postpone view - button Ok I Will Do Break Clicked")
        self.timer?.invalidate()
        self.timer = nil
        lblTimer.isHidden = true
        self.view.removeFromSuperview()
        mainViewControllerObj?.btnAbort.isHidden = false
    }
    

    func startTimer(duration:Int) {
        lblTimer.isHidden = false
        currentTimer = 0
        totalDuration = duration
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimer.stringValue = "\(minute):\(second)"
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lblTimer.isHidden = false
            self.lblTimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            
            self.timer?.invalidate()
            DispatchQueue.main.async {

                self.lblTimer.isHidden = true
                self.view.removeFromSuperview()
                mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5)
            }
        }
    }
}
