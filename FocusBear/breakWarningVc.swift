//
//  breakWarningVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class breakWarningVc: NSViewController {

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var btnPostpone: Button!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var isPostponing = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblDescription.stringValue = "Micro breaks help keep your energy + alertness levels consistent throughout the day and have positive impacts on your posture (no more screen headaches)."
        if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
            lblDescription.stringValue = breakWarningVcInfo.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
        }
    }
    override func viewWillDisappear() {
        if transparentWcObj != nil{
            transparentWcObj?.window?.close()
        }
    }
    func resetView(){
        var totalDuration = 0
        for activity in arrFinalBreakActivities{
            if activity.activity.useTimer{
                totalDuration += activity.activity.durationSeconds
            }
        }
        
        progressBar.isHidden = false
        isPostponing = false
        var title = "Your <DURATION> seconds micro break starts in"
        btnPostpone.title = "Postpone for 5 minutes"
        startTimer(durationSeconds: 30)
        setProgres()
        
        if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
            if isBreakActivityShowingWhileMeeting{
                title = "Your <DURATION> seconds mid meeting break starts in"
                lblDescription.stringValue = "Micro breaks can help you stay focused in meetings."
                
                title = breakWarningVcInfo.value(forKey: "titleMeetings") as? String ?? title
                lblDescription.stringValue = breakWarningVcInfo.value(forKey: "descriptionMeetingsText") as? String ?? lblDescription.stringValue
            }else{
                title = "Your <DURATION> seconds micro break starts in"
                lblDescription.stringValue = "Micro breaks help keep your energy + alertness levels consistent throughout the day and have positive impacts on your posture (no more screen headaches)."
                
                title = breakWarningVcInfo.value(forKey: "title") as? String ?? title
                lblDescription.stringValue = breakWarningVcInfo.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            }
            btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
        }
        
        lblTitle.stringValue = title.replacingOccurrences(of: "<DURATION>", with: "\(totalDuration)")
    }
    func startTimer(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        
        currentTimer = 0
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
    func setProgres(){
        let remainingSeconds = self.totalDuration-currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
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
        
        DispatchQueue.main.async {
            if !self.isPostponing{
                self.progressBar.doubleValue = Double(remainingSeconds)
                if transparentWcObj != nil{
                    if transparentWcObj!.window?.isVisible ?? false{
                        transparentWcObj?.window?.alphaValue = CGFloat(self.currentTimer) / CGFloat(self.totalDuration)
                    }
                }
            }
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
                transparentWcObj?.window?.close()
                if self.isPostponing{
                    mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5, secondsToPostpone: nil)
                }else{
                    if currentState == ._ACTIVITY_{// whenever show waring then make current state _ACTIVITY_ beacuse if any thing will happen during waring curent state will change (ex. app can bhi in shutoff state when warning is about to over in this case we will not execute break activity)
                        mainViewControllerObj?.performBreakActivities()
                    }
                }
            }
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1 //todo 1 kro
        setProgres()
    }
    
    @IBAction func btnPostponeClicked(_ sender: Any) {
        addLog(text: "breakWarningVc:- btnPostponeClicked")
        if isPostponing{
            addLog(text: "breakWarningVc:- btn take break clicked")
            self.timer?.invalidate()
            self.view.window?.close()
            if currentState == ._ACTIVITY_{// whenever show waring then make current state _ACTIVITY_ beacuse if any thing will happen during waring curent state will change (ex. app can bhi in shutoff state when warning is about to over in this case we will not execute break activity)
                mainViewControllerObj?.performBreakActivities()
            }
            
        }else{
            addLog(text: "breakWarningVc:- btn Postpone clicked")
            if activityPostponeCount > 0 && !SettingsManagerObject.isEasySkipEnabled{
                addLog(text: "breakWarningVc:- btn Postpone timer begin")
                isPostponing = true
                self.timer?.invalidate()
                lblTitle.stringValue = "You postponed the last break - are you sure you can't make time for The break now?"
                btnPostpone.title = "Argh ok I'll take a break!"
                progressBar.isHidden = true
                startTimer(durationSeconds: 15)
                if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
                    lblTitle.stringValue = breakWarningVcInfo.value(forKey: "postponeConfirmText") as? String ?? lblTitle.stringValue
                    btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnPostpone.title
                }
            }else{
                self.timer?.invalidate()
                self.view.window?.close()
                activityPostponeCount += 1
                mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5, secondsToPostpone: nil)
            }
        }
    }
}

