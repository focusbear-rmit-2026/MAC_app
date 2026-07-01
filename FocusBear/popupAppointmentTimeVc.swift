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
        
        shouldAskPassword = false
        if Focus_Bear.shouldAskPassword(){
            if currentState == ._MORNING_HABIT_ && SettingsManagerObject.isPasswordRequireInSkipMorning{
                shouldAskPassword = true
            }else if currentState == ._EVENING_HABIT_ && SettingsManagerObject.isPasswordRequireInSkipEvening && !isHighPrioritySequenceGoing{
                shouldAskPassword = true
            }else if currentState == ._EVENING_HABIT_ && SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff && isHighPrioritySequenceGoing{
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
