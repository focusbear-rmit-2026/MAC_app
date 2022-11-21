//
//  askPostponeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askPostponeVc: NSViewController {

    @IBOutlet weak var btnCancelPostpone: cursorButton!
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

        
        lblSelectMinutes.stringValue = "Select minutes to postpone:"
        popUpButtonSelectMinutes.removeAllItems()
        popUpButtonSelectMinutes.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "60", "90"])
        
        btnOkIWillDoBreak.title = "Argh ok I'll take a break!"
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnOkIWillDoBreak.title
            lblSelectMinutes.stringValue = activityPostponeInfo.value(forKey: "selectMinutesText") as? String ?? lblSelectMinutes.stringValue
        }
        
    }
    
    override func viewWillAppear() {
        
    }
    @IBAction func btnCancelPostponeClicked(_ sender: Any) {
        if currentState == ._ACTIVITY_{
            self.timer?.invalidate()
            self.timer = nil
            lblTimer.isHidden = true
            self.view.removeFromSuperview()
            mainViewControllerObj?.btnAbort.isHidden = false
        }else{
            self.view.removeFromSuperview()
            mainViewControllerObj?.abortCancel()
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    func resetView(){
        addLog(text: "Ask postpone view - resetView")
        btnPostpone.isHidden = false
        btnAbortBreak.isHidden = false
        btnOkIWillDoBreak.isHidden = true
        lblTimer.isHidden = true
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if activityPostponeCount == 0{
                showHabitPostponeView()
            }else{
                showHabitTimerView()
            }
            
        }else if currentState == ._FOCUS_SUMMARY_{
            
            
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
            
            btnPostpone.buttonColor = buttonBgColor.cgColor
            btnAbortBreak.buttonColor = NSColor.white.cgColor
            
            
            
        }else if currentState == ._ACTIVITY_{
            popUpButtonSelectMinutes.isHidden = true
            lblSelectMinutes.isHidden = true
            lblTitle.stringValue = "If you have something urgent, you can postpone the Break Activity for 5 Minutes."
            btnPostpone.title = "Postpone Break"
            btnAbortBreak.title = "Switch to office mode"
            
            if SettingsManagerObject.isOfficeModeEnabled{
                btnAbortBreak.isHidden = true
                btnPostpone.buttonColor = buttonBgColor.cgColor
            }else{
                
                let filterArr = arrAllbreakActivities.filter { $0.isOfficeFriendly == true}
                if filterArr.count == 0{// no activity found with isOfficeFriendly //
                    addLog(text: "Ask postpone view - resetView :- no activity found with isOfficeFriendly")
                    btnAbortBreak.isHidden = true
                    btnPostpone.buttonColor = buttonBgColor.cgColor
                }else{
                    btnAbortBreak.isHidden = false
                    btnPostpone.buttonColor = NSColor.white.cgColor
                    btnAbortBreak.buttonColor = buttonBgColor.cgColor
                }
            }
            if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
                lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponeBreakText") as? String ?? lblTitle.stringValue
                btnPostpone.title = activityPostponeInfo.value(forKey: "buttonPostponeBreakText") as? String ?? btnPostpone.title
                btnAbortBreak.title = activityPostponeInfo.value(forKey: "buttonEnableOfficeModeText") as? String ?? btnAbortBreak.title
            }
        }
    }

    func showHabitTimerView(){
        lblTitle.stringValue = "You've postponed your habits a few times. Are you sure you want to postpone again?"
        popUpButtonSelectMinutes.isHidden = true
        lblSelectMinutes.isHidden = true
        btnAbortBreak.isHidden = true
        btnPostpone.isHidden = true
        btnOkIWillDoBreak.isHidden = true
        
        var timer = 0
        switch activityPostponeCount {
        case 1:
            timer = 5
        case 2:
            timer = 10
        case 3:
            timer = 15
        case 4:
            timer = 30
        case 5:
            timer = 45
        case 6:
            timer = 60
        default:
            timer = 60
        }
        
        startTimer(duration: timer)
        btnOkIWillDoBreak.isHidden = false
        btnOkIWillDoBreak.title = "I changed my mind - I'll do my habits"
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            lblTitle.stringValue = activityPostponeInfo.value(forKey: "postponedLastHabitText") as? String ?? lblTitle.stringValue
            btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonDoHabitText") as? String ?? btnOkIWillDoBreak.title
        }
        
    }
    
    func showHabitPostponeView(){
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
        
        btnPostpone.buttonColor = buttonBgColor.cgColor
        btnAbortBreak.buttonColor = NSColor.white.cgColor
        btnOkIWillDoBreak.isHidden = true
        btnPostpone.isHidden = false
        btnAbortBreak.isHidden = false
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "Ask postpone view - button Postpone Clicked")
        if currentState == ._MORNING_HABIT_{
            self.view.removeFromSuperview()
            mainViewControllerObj?.postponeMorningHabitFor(minutes: Int(popUpButtonSelectMinutes.title) ?? 15)
            activityPostponeCount += 1
        }else if currentState == ._EVENING_HABIT_{
            self.view.removeFromSuperview()
            mainViewControllerObj?.postponeEveningHabitFor(minutes: Int(popUpButtonSelectMinutes.title) ?? 15)
            activityPostponeCount += 1
        }else if currentState == ._ACTIVITY_{
            if activityPostponeCount == 0{
                self.view.removeFromSuperview()
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
                btnOkIWillDoBreak.title = "Argh ok I'll take a break!"
                if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
                    btnOkIWillDoBreak.title = activityPostponeInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnOkIWillDoBreak.title
                }
                
                startTimer(duration: 15)
            }
        }else if currentState == ._FOCUS_SUMMARY_{
            self.view.removeFromSuperview()
            
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                mainViewControllerObj?.showPasswordView()
                enterPasswordVcObj?.parentVc = self
            }else{
                mainViewControllerObj?.postponeFocusSummaryFor(minutes: Int(popUpButtonSelectMinutes.title) ?? 15)
            }
        }

        
    }
    @IBAction func btnAbortBreakClicked(_ sender: Any) {
        if currentState == ._ACTIVITY_{
            addLog(text: "Ask postpone view - button Enabled Office Mode")
            self.view.removeFromSuperview()
            mainViewControllerObj!.enableOfficeModeAndRestartBreakActivities()
        }else{
            addLog(text: "Ask postpone view - button Abort Clicked")
            self.view.removeFromSuperview()
            mainViewControllerObj?.processAborting()
        }
        
    }
    @IBAction func btnOkIWillDoBreakClicked(_ sender: Any) {
        addLog(text: "Ask postpone view - button Ok I Will Do activity Clicked")

        if currentState == ._ACTIVITY_{
            self.timer?.invalidate()
            self.timer = nil
            lblTimer.isHidden = true
            self.view.removeFromSuperview()
            mainViewControllerObj?.btnAbort.isHidden = false
        }else{
            self.view.removeFromSuperview()
            mainViewControllerObj?.abortCancel()
            self.timer?.invalidate()
            self.timer = nil
        }
        
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
                
                if currentState == ._ACTIVITY_{
                    self.view.removeFromSuperview()
                    mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5)
                }else if currentState == ._MORNING_HABIT_{
//                    self.view.removeFromSuperview()
//                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
//                        mainViewControllerObj?.showPasswordView()
//                        enterPasswordVcObj?.parentVc = self
//                    }else{
//                        mainViewControllerObj?.postponeMorningHabitFor(minutes: Int(self.popUpButtonSelectMinutes.title) ?? 15)
//                    }
                    self.showHabitPostponeView()
                }else if currentState == ._EVENING_HABIT_{
//                    self.view.removeFromSuperview()
//                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{//
//                        mainViewControllerObj?.showPasswordView()
//                        enterPasswordVcObj?.parentVc = self
//                    }else{
//                        mainViewControllerObj?.postponeEveningHabitFor(minutes: Int(self.popUpButtonSelectMinutes.title) ?? 15)
//                    }
                    self.showHabitPostponeView()
                }
            }
        }
    }
}
