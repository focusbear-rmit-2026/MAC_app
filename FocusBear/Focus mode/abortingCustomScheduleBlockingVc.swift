//
//  abortingCustomScheduleBlockingVc.swift
//  FocusBear
//
//  Created by Manish Jain on 27/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class abortingCustomScheduleBlockingVc: NSViewController {
    @IBOutlet weak var lblStrictModeActivated: NSTextField!
    @IBOutlet weak var lblSeconds: NSTextField!
    @IBOutlet weak var btnAbortFocus: Button!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    var currentTimer = 0
    var totalDuration = 10
    var timer:Timer?
    
    var titlePauseText = "Pausing Custom schedule - <SCHEDULE>"
    var reasonWorkCompletedText = ""
    var reasonEmergencyText = ""
    var reasonFocusModeNotWorkingText = ""
    var isPausingFocusMode = false
    var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnCancel.title = buttonCancelText
        btnAbortFocus.title = "Pause Custom Schedule"
        
        lblStrictModeActivated.stringValue = "Strict mode activated: you asked me to show a 15 second countdown timer before you can pause / deactivate"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let abortingFocusModeInfo = focusInfo.value(forKey: "abortingFocusModeInfo") as? NSDictionary{
                btnCancel.title = abortingFocusModeInfo.value(forKey: "buttonCancelText") as? String ?? btnCancel.title
                lblStrictModeActivated.stringValue = abortingFocusModeInfo.value(forKey: "strictModeText") as? String ?? lblStrictModeActivated.stringValue
            }
        }
        
        if let info = configjson.value(forKey: "abortingCustomScheduleBlockingVcInfo") as? NSDictionary{
            btnAbortFocus.title = info.value(forKey: "buttonAbortFocus") as? String ?? btnAbortFocus.title
            titlePauseText = info.value(forKey: "titlePauseText") as? String ?? titlePauseText
        }
        btnCancel.isSecondaryButton = true
    }
    
    override func viewWillAppear() {
        isViewVisible = true
    }
    
    override func viewWillDisappear() {
        isViewVisible = false
    }

    func resetData(){
        var scheduleName = ""
        for i in 0..<customBlockingScheduleManagerObj.arrBlockingSchedule.count{
            let schedule = customBlockingScheduleManagerObj.arrBlockingSchedule[i]
            if schedule.state == .on{
                scheduleName = schedule.name
                break;
            }
        }
        self.btnAbortFocus.isEnabled = false
        self.lblSeconds.isHidden = true
        self.lblStrictModeActivated.isHidden = true
        if currentFocusModeStrictness == ._STRICT_{
            self.lblStrictModeActivated.isHidden = false
            startTimer()
        }else{
            self.btnAbortFocus.isEnabled = true
        }
        lblTitle.stringValue = titlePauseText.replacingOccurrences(of: "<SCHEDULE>", with: scheduleName)
    }
    
    func startTimer() {
        if self.timer != nil{
            self.timer?.invalidate()
        }
        self.btnAbortFocus.isEnabled = false
        self.lblSeconds.isHidden = false
        currentTimer = 0
        totalDuration = 15
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblSeconds.stringValue = "\(minute):\(second)"
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
            self.lblSeconds.stringValue = "\(minute):\(second)"
            if self.view.window?.isVisible == false{
                self.timer?.invalidate()
            }
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.lblSeconds.isHidden = true
                    self.btnAbortFocus.isEnabled = true
                }
            }
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        if self.timer != nil{
            self.timer?.invalidate()
        }
        self.dismiss(self)
    }
    

    @IBAction func btnAbortFocusClicked(_ sender: Any) {
        addLog(text: "[user-action] abortingFocusModeVc - btnAbortFocusClicked")//
        if !customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            self.dismiss(self)
            return;
        }
        self.dismiss(self)
        customBlockingScheduleManagerObj.customBlockingSchedulePaused()
    }
}
