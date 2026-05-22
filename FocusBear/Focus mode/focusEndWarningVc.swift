//
//  focusEndWarningVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 11/03/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class focusEndWarningVc: NSViewController {

    @IBOutlet weak var btnEndFocusSession: Button!
    @IBOutlet weak var btnExtend: Button!
    @IBOutlet weak var popUpBtn: NSPopUpButton!
    @IBOutlet weak var lblSelectMinutes: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    // i am done, end focus session
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var alertExtendPostpone: NSAlert?
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "Focus mode ends in"
        lblQuestion.stringValue = "Still in the flow? Extend the session"
        lblSelectMinutes.stringValue = "Select minutes to extend:"
        btnExtend.title = "Extend"
        btnEndFocusSession.title = "I'm done, End focus session"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblTitle.stringValue = common.value(forKey: "focusEndsText") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = common.value(forKey: "askExtendFocusText") as? String ?? lblQuestion.stringValue
            lblSelectMinutes.stringValue = common.value(forKey: "extendFocusMinutesText") as? String ?? lblSelectMinutes.stringValue
            btnExtend.title = common.value(forKey: "buttonExtendText") as? String ?? btnExtend.title
            btnEndFocusSession.title = common.value(forKey: "buttonEndFocusSessionText") as? String ?? btnEndFocusSession.title
        }
        popUpBtn.removeAllItems()
        popUpBtn.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "90"])
    }
    override func viewWillAppear() {
        startTimer(durationSeconds: warningShowSecondsBeforeFocusModeEndTime)
    }
    override func viewWillDisappear() {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        if alertExtendPostpone != nil{
            if alertExtendPostpone!.window.isVisible{
                self.view.window!.endSheet(alertExtendPostpone!.window)
            }
        }
        
        if enterPasswordVcObj != nil{
            if enterPasswordVcObj?.presentingViewController == self{
                enterPasswordVcObj!.dismiss(enterPasswordVcObj)
            }
        }
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
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
            }
        }
    }
    
    @objc func performTimerCount() {
        currentTimer += 1
        setProgres()
    }
    
    @IBAction func btnExtendClicked(_ sender: Any) {
        let totalMinutes = Int(popUpBtn.title) ?? 0
        if currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            if getHabitsVcObject().postponeTimer != nil {
                if getHabitsVcObject().postponeTimer!.isValid{
                    let currentTime = Date()
                    let breakTime = getHabitsVcObject().postponeTimer!.fireDate
                    let diffMinute = Calendar.current.dateComponents([.minute], from: currentTime, to: breakTime).minute ?? 0
                    if diffMinute < totalMinutes{
                        alertExtendPostpone = NSAlert()
                        alertExtendPostpone!.setSharingType()
                        alertExtendPostpone!.messageText = "Focus duration is longer than habit postpone duration."
                        alertExtendPostpone!.informativeText = "You may want to extend the postpone duration to match the focus session duration. Click on the desired button to start the focus session."
                        var buttonExtendPostponeText = "Extend postpone duration"
                        var buttonDoNotExtendPostponeText = "Do not extend postpone duration"
                        
                        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                            alertExtendPostpone!.messageText = pomodoroInfo.value(forKey: "alertExtendPostponeText") as? String ?? alertExtendPostpone!.messageText
                            alertExtendPostpone!.informativeText = pomodoroInfo.value(forKey: "alertExtendPostponeDescription") as? String ?? alertExtendPostpone!.informativeText
                            buttonExtendPostponeText = pomodoroInfo.value(forKey: "buttonExtendPostponeText") as? String ?? buttonExtendPostponeText
                            buttonDoNotExtendPostponeText = pomodoroInfo.value(forKey: "buttonDoNotExtendPostponeText") as? String ?? buttonDoNotExtendPostponeText
                        }
                        alertExtendPostpone!.alertStyle = NSAlert.Style.warning
                        alertExtendPostpone!.addButton(withTitle: buttonExtendPostponeText)
                        alertExtendPostpone!.addButton(withTitle: buttonDoNotExtendPostponeText)
                        
                        alertExtendPostpone!.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                            if modalResponse == .alertFirstButtonReturn{
                                if currentState == ._POSTPON_MORNING_HABIT_{
                                    if SettingsManagerObject.isEasySkipEnabled{
                                        getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        self.extendFocusMode()
                                    }else{
                                        if SettingsManagerObject.isPasswordRequireInSkipMorning && shouldAskPassword(){
                                            self.presentAsSheet(self.enterPasswordVcObj!)
                                            self.enterPasswordVcObj?.parentVc = self
                                        }else{
                                            getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                            self.extendFocusMode()
                                        }
                                    }
                                }else if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
                                    
                                    var shouldAskPasswordForEvening = false
                                    if shouldAskPassword() &&  !SettingsManagerObject.isEasySkipEnabled{
                                        if isCutOffTimeGoing(){
                                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                                shouldAskPasswordForEvening = true
                                            }
                                        }else{
                                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                                shouldAskPasswordForEvening = true
                                            }
                                        }
                                    }
                                    if shouldAskPasswordForEvening{
                                        self.presentAsSheet(self.enterPasswordVcObj!)
                                        self.enterPasswordVcObj?.parentVc = self
                                    }else{
                                        if currentState == ._EVENING_HABIT_{
                                            getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        }else if currentState == ._POSTPON_FOCUS_SUMMARY_{
                                            getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                                        }
                                        self.extendFocusMode()
                                    }
                                }
                            }else{
                                self.extendFocusMode()
                            }
                            
                        })
                        return;
                    }
                }
            }
        }
        
        
        self.extendFocusMode()
        
    }
    
    func extendFocusMode(){
        allApiObject.capturePosthog(event: "extend-focus-session-from-warning", metadata: [:])
        appdelegate?.extendFocusModeFor(minutes: Int(popUpBtn.title) ?? 0)
        self.view.window?.close()
    }
    
    @IBAction func btnEndFocusSessionClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "end-focus-session-clciked-from-warning", metadata: [:])
        isHardCorePomodoroModeOn = false
        appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false)
        self.view.window?.close()
    }
    
}
