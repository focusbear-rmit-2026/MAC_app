//
//  customAlertVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class naturalBreaksDetectionVc: NSViewController {

 
    @IBOutlet weak var boxDontShowAgain: NSBox!
    @IBOutlet weak var checkBoxDontShowAgain: NSButton!
    @IBOutlet weak var widthBox: NSLayoutConstraint!
    @IBOutlet weak var btnSecond: Button!
    @IBOutlet weak var btnFirst: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var isNormalState = false
    var showBoxTime:Date?
    var duration = 0
    var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        checkBoxDontShowAgain.title = "Don't show this again"
        if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
            widthBox.constant = 350
        }else{
            widthBox.constant = 261
        }
        
        checkBoxDontShowAgain.title = "Don't show this again"
        
        if let confirmRunScriptVcInfo = configjson.value(forKey: "confirmRunScriptVcInfo") as? NSDictionary{
            checkBoxDontShowAgain.title = confirmRunScriptVcInfo.value(forKey: "buttonDontShowAgainText") as? String ?? checkBoxDontShowAgain.title
        }
    }
    
    override func viewWillAppear() {
        addLog(text: "naturalBreaksDetectionVc - viewWillAppear")
        isViewVisible = true
    }
    
    override func viewWillDisappear() {
        addLog(text: "natural Breaks Detection window closed")
        isViewVisible = false
    }
    
    
    func closeView(){
        addLog(text:"naturalBreaksDetectionVc - func closeView")
        if isViewVisible{
            if let window = self.view.window {
                if let _ = window.sheetParent {
                    self.dismiss(self)
                } else if window.contentViewController === self {
                    self.view.window?.close()
                } else {
                    self.view.window?.close()// no chance
                }
            }
        }
    }
    
    func resetView(duration:Int){
        addLog(text: "naturalBreaksDetectionVc - resetView")
        boxDontShowAgain.isHidden = false
        checkBoxDontShowAgain.isHidden = false
        checkBoxDontShowAgain.state = .off
        showBoxTime = Date()
        self.duration = duration
        lblTitle.stringValue = "It looks like you're on a break. Well done on taking care of yourself."
        lblSubTitle.isHidden = true
        btnFirst.title = "Thanks - I feel great"
        btnSecond.title = "You're wrong! I wasn't on a break"
        btnSecond.buttonColor = NSColor.white.cgColor
        isNormalState = true
        isViewVisible = true// aded on 20/11/25 in v2.27.432// asking if I just completed a break multiple times 
        if let naturalBreaksDetectionVcInfo = configjson.value(forKey: "naturalBreaksDetectionVcInfo") as? NSDictionary{
            lblTitle.stringValue = naturalBreaksDetectionVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnFirst.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonThanksText") as? String ?? btnFirst.title
            btnSecond.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonWrongDetectionText") as? String ?? btnSecond.title
        }
    }
    
    func closeForecefully(){// added on 9/9/25 in 2.27.413
        addLog(text: "naturalBreaksDetectionVc - closeForecefully")
        self.closeView()
        
        if let showBoxTime = showBoxTime{
            let idelTimeStartTime = showBoxTime.addingTimeInterval(-Double(duration))
            UserDefaults.standard.set(idelTimeStartTime, forKey: kUserdefaultsLastBreaksStartTime)
            
            if let startTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreaksStartTime) as? Date{
                let currentDate = Date()
                let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: currentDate).second ?? 0
                if diffSeconds > 0{
                    var arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
                    arrDuration.append(diffSeconds)
                    UserDefaults.standard.set(arrDuration, forKey: kUserdefaultsArrayBreaksDurations)
                }
                UserDefaults.standard.set(currentDate, forKey: kUserdefaultsLastBreakEndTime)
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let now = df.string(from: currentDate)
                addLog(text: "Last break recorded at \(now). It will be shown in the menu.")
            }
        }else{
            addLog(text: "Break start time is undefined or not initialized")
        }
        if getHabitsVcObject().breakTimer != nil{
            getHabitsVcObject().setActivityTimer()
        }
    }
    
    @IBAction func btnFirstClicked(_ sender: Any) {
        if isNormalState{
            addLog(text: "[user-action] naturalBreaksDetectionVc - btnThanksClicked")
            allApiObject.capturePosthog(event: "natural-break-detected-correct", metadata: [:])
            self.closeView()
            
            if let showBoxTime = showBoxTime{
                let idelTimeStartTime = showBoxTime.addingTimeInterval(-Double(duration))
                UserDefaults.standard.set(idelTimeStartTime, forKey: kUserdefaultsLastBreaksStartTime) 
                
                if let startTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreaksStartTime) as? Date{
                    let currentDate = Date()
                    let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: currentDate).second ?? 0
                    if diffSeconds > 0{
                        var arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
                        arrDuration.append(diffSeconds)
                        UserDefaults.standard.set(arrDuration, forKey: kUserdefaultsArrayBreaksDurations)
                    }
                    UserDefaults.standard.set(currentDate, forKey: kUserdefaultsLastBreakEndTime)
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let now = df.string(from: currentDate)
                    addLog(text: "Last break recorded at \(now). It will be shown in the menu.")
                }
            }else{
                addLog(text: "Break start time is undefined or not initialized")
            }
            if currentState == ._MICRO_BREAK_{
                getHabitsVcObject().breaksScreenIsIdleResetBreaks()
            }else{
                if getHabitsVcObject().breakTimer != nil{
                    getHabitsVcObject().setActivityTimer()
                }
            }
            
        }else{
            addLog(text: "[user-action] naturalBreaksDetectionVc - btnYupINeedBreak Clicked")
            self.closeView()
            if currentState == ._POSTPON_MORNING_HABIT_{
                isBreakActivityExecuteFromPostponeMorningHabit = true
            }else if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
                isBreakActivityExecuteFromPostponeEveningHabit = true
            }
            if !isMainWindowLoaded{
                mainWindowControllerObj?.loadWindow()
            }
            if currentState != ._MICRO_BREAK_{
                getHabitsVcObject().executeBreakActivities()
            }
        }
    }
    
    @IBAction func btnSecondClicked(_ sender: Any) {
        if isNormalState{
            if currentState != ._MORNING_HABIT_ && (isHabitAlreadyShowed || currentState == ._POSTPON_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !appdelegate!.isUserOnMeeting && currentState != ._BREATHING_ && currentState != ._EVENING_HABIT_ && currentState != ._FOCUS_SUMMARY_{
                addLog(text: "show AskTakeBreakView")
                showAskTakeBreakView()
            }else{
                if currentState == ._MICRO_BREAK_{
                    addLog(text: "show AskTakeBreakView")
                    showAskTakeBreakView()
                }else{
                    addLog(text: "Don't need to show Take Break View")
                    self.closeView()
                }
                
            }
        }else{
            addLog(text: "[user-action] naturalBreaksDetectionVc - btnNoIWillTakeLater Clicked")
            self.closeView()
            if currentState == ._MICRO_BREAK_{
                getHabitsVcObject().breaksScreenIsIdleResetBreaks()
            }
        }
    }
    
    func showAskTakeBreakView(){
        addLog(text: "[user-action] naturalBreaksDetectionVc - btnWrongIWasntOnBreakClicked")
        allApiObject.capturePosthog(event: "wrong-decision-i-wasnt-on-break", metadata: [:])
        lblTitle.stringValue = "Ok do you want to take a break now 😅?"
        btnFirst.title = "Yup I need a break now"
        btnSecond.title = "No - I'll take later"
        isNormalState = false
        boxDontShowAgain.isHidden = true
        checkBoxDontShowAgain.isHidden = true
        if let naturalBreaksDetectionVcInfo = configjson.value(forKey: "naturalBreaksDetectionVcInfo") as? NSDictionary{
            lblTitle.stringValue = naturalBreaksDetectionVcInfo.value(forKey: "titleTakeBreak") as? String ?? lblTitle.stringValue
            btnFirst.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonStartBreakText") as? String ?? btnFirst.title
            btnSecond.title = naturalBreaksDetectionVcInfo.value(forKey: "buttonTakeBreakLaterText") as? String ?? btnSecond.title
        }
    }
    
    @IBAction func checkBoxDontShowAgainClicked(_ sender: Any) {
        addLog(text: "[user-action] naturalBreaksDetectionVc - checkBoxDontShowAgainClicked Clicked")
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxDontShowAgain.state == .off{
            SettingsManagerObject.isDetectNatualBreaksEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-enable-natual-breaks", metadata: [:])
        }else{
            SettingsManagerObject.isDetectNatualBreaksEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-disable-natual-breaks", metadata: [:])
        }
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
}
