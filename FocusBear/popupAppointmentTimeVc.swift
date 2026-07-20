//
//  popupAppointmentTime.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class popupAppointmentTimeVc: NSViewController {

    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnBackToHabits: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    //var duration = 300
    var enterPasswordVcObj: enterPasswordVc?
    var currentTimer = 0
    var totalDuration = 120
    var timer:Timer?
    var endTime:Date?
    // Fires startAppointment() once the meeting's own end time passes, so the popup can't sit open
    // (and the routine stay stuck) indefinitely if the user just doesn't click a button — the window
    // has no close button and nothing else was closing it. Only used on the no-password branch: the
    // password branch already has its own 120s give-up timer (performTimerCount below), and
    // auto-advancing past a required password would defeat the postpone-after-cutoff gate above.
    var autoCloseTimer: Timer?
    var subTitle = "Unlocking your Mac so you can turn off Late No More appointment reminders. You have <TIMELEFT> to turn it off. Enter a password to continue using it until your appointment ends at <TIME>"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        btnOk.title = "Thanks!"
        btnBackToHabits.title = "Back to habits - I don't need to attend"
        
        if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
            lblTitle.stringValue = popupAppointmentTimeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            btnBackToHabits.title = popupAppointmentTimeVcInfo.value(forKey: "buttonBackToHabitsText") as? String ?? btnBackToHabits.title
            subTitle = popupAppointmentTimeVcInfo.value(forKey: "subTitle") as? String ?? subTitle
        }
        btnBackToHabits.isSecondaryButton = true
        lblTimer.isHidden = true
    }
    var shouldAskPassword = false
    func resetView(title:String, endTime:Date){
        self.endTime = endTime
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        if currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_{
            btnBackToHabits.isHidden = true
        }else{
            btnBackToHabits.isHidden = false
        }
        var message = "It looks like you have an appointment that is about to start: <EVENT_TITLE>. Pausing your habits so you can attend the appointment."
        if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
            message = popupAppointmentTimeVcInfo.value(forKey: "title") as? String ?? message
        }
        message = message.replacingOccurrences(of: "<EVENT_TITLE>", with: title)
        lblTitle.stringValue = message
        
        // This popup always POSTPONES the running routine (startAppointment() below calls
        // postponeMorningHabitFor/postponeEveningHabitFor, never a skip), so it must honour the
        // postpone-specific password settings — not the skip ones. It used to check
        // isPasswordRequireInSkip{Morning,Evening,EveningAfterCutOff}, so a user with only the
        // postpone rules enabled (and skip rules off) got no password prompt at all when a Late No
        // More appointment postponed their routine, including after cutoff (bug report 2026-07-17).
        shouldAskPassword = false
        if Focus_Bear.shouldAskPassword(forPostpone: true){
            if currentState == ._MORNING_HABIT_ && SettingsManagerObject.isPasswordRequireInPostponeMorning{
                shouldAskPassword = true
            }else if currentState == ._EVENING_HABIT_ && SettingsManagerObject.isPasswordRequireInPostponeEvening && !isHighPrioritySequenceGoing && !isCutOffTimeGoing(){
                // This is the BEFORE-cutoff evening branch. Exclude cutoff time here so it doesn't
                // short-circuit the else-if and prevent the after-cutoff branch below from running.
                shouldAskPassword = true
            }else if currentState == ._EVENING_HABIT_ && SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff && (isHighPrioritySequenceGoing || isCutOffTimeGoing()){
                // isPasswordRequireInPostponeEveningAfterCutOff is an Evening-Habit-specific setting, so
                // this branch only governs postponing the evening habit — when a meeting/high-priority
                // sequence is running or it's past the cutoff time.
                // NOTE (tradeoff): this intentionally no longer requires the password past cutoff in
                // NON-evening states (shutoff / custom routine / break). An earlier version kept this
                // branch state-independent so a meeting popup appearing past cutoff in those states
                // couldn't be dismissed without a password. If that cross-state protection is still
                // wanted, gate each state on its own postpone-password setting rather than the evening one.
                shouldAskPassword = true
            }
        }
        
        if !shouldAskPassword{
            if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
                btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            }
            lblSubTitle.isHidden = true

            btnOk.title = "Thanks!"
            if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
                btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            }

            let fireInterval = max(endTime.timeIntervalSinceNow, 1)
            autoCloseTimer = Timer.scheduledTimer(withTimeInterval: fireInterval, repeats: false) { [weak self] _ in
                addLog(text: "popupAppointmentTimeVc:- auto-closing at meeting end time, no user action taken")
                self?.startAppointment()
            }
            RunLoop.main.add(autoCloseTimer!, forMode: .common)
        }else{
            lblSubTitle.isHidden = false
            btnOk.title = "Enter Password"
            startTimer()
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        addLog(text: "[user-action] smallCountDownVc:- button Ok clicked")
        if !shouldAskPassword{
            startAppointment()
        }else{
            addLog(text: "smallCountDownVc:- enterPassword")
            if enterPasswordVcObj == nil{
                enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
            }
            self.presentAsSheet(enterPasswordVcObj!)
        }
    }
    
    func startAppointment(){
        addLog(text: "smallCountDownVc:- startAppointment")
        focusButtonServiceObject.dismissNotification()
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        let duration = Calendar.current.dateComponents([.second], from: Date(), to: endTime!).second ?? 0
        if lastCurrentState == ._MORNING_HABIT_{
            getHabitsVcObject().postponeMorningHabitFor(minutes: 0, secondsToPostpone: duration + 160, showAskFocusModeView:false, showAskIntention:false)
        }else if lastCurrentState == ._EVENING_HABIT_{
            getHabitsVcObject().postponeEveningHabitFor(minutes: 0, secondsToPostpone: duration + 160, showAskFocusModeView:false, showAskIntention:false)
        }else if lastCurrentState == ._MICRO_BREAK_{
            getHabitsVcObject().postponeBreakActivitiesFor(minutes: 0, secondsToPostpone: duration + 160, isFromBreakWarningWindow: false)
        }else if lastCurrentState == ._CUSTOM_ROUTINE_{
            getHabitsVcObject().postponeCustomRoutineFor(minutes: 0, secondsToPostpone: duration + 160, showAskFocusModeView: false, showAskIntention: false, fromRoutineWarning:false)
        }
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()
    }
    
    @IBAction func btnBackToHabitsClicked(_ sender: Any) {
        addLog(text: "[user-action] smallCountDownVc:- button back to habits clicked")
        focusButtonServiceObject.dismissNotification()
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()
        if currentHabitPlaying == nil && currentActivityPlaying == nil{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
        }else{
//            getSmallCountDownWindowObject().showWindow(self)
//            getsmallCountDownVcObject().view.isHidden = false
            showSmallTimerView()
        }
        mainViewControllerObj?.showHabitsView()
        getHabitsVcObject().abortCancel()
    }
    
    func startTimer() {
        currentTimer = 0
        totalDuration = 120
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
       
        let stringDate = getStringFromDate(date: endTime!, dateFormat: "hh:mm a")
        var subTitleText = subTitle.replacingOccurrences(of: "<TIMELEFT>", with: "\(minute):\(second)")
        subTitleText = subTitleText.replacingOccurrences(of: "<TIME>", with: stringDate)
        lblSubTitle.stringValue =  subTitleText
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
            let stringDate = getStringFromDate(date: self.endTime!, dateFormat: "hh:mm a")
            var subTitleText = self.subTitle.replacingOccurrences(of: "<TIMELEFT>", with: "\(minute):\(second)")
            subTitleText = subTitleText.replacingOccurrences(of: "<TIME>", with: stringDate)
            self.lblSubTitle.stringValue =  subTitleText
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.lblTimer.isHidden = true
                    if self.enterPasswordVcObj != nil{
                        if self == self.enterPasswordVcObj?.presentingViewController{
                            self.enterPasswordVcObj!.dismiss(self.enterPasswordVcObj!)
                        }
                    }
                    self.btnBackToHabitsClicked(self)
                }
            }
        }
    }
}
