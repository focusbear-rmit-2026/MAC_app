//
//  abortingFocusModeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/02/22.


import Cocoa

class abortingFocusModeVc: NSViewController {

    @IBOutlet weak var stackViewWhyStopFocusMode: NSStackView!
    @IBOutlet weak var lblStrictModeActivated: NSTextField!
    @IBOutlet weak var lblSeconds: NSTextField!
    @IBOutlet weak var btnAbortFocus: Button!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var popUpBtnAbortReasons: NSPopUpButton!
    
    
    var currentTimer = 0
    var totalDuration = 10
    var timer:Timer?
    
    var titleText = "Aborting Focus type - <FOCUSTYPE>"
    var titlePauseText = "Pausing Focus type - <FOCUSTYPE>"
    
    var arrReasons = ["I achieved what I wanted to too early.", "I have an emergency", "Focus mode is not working properly."]
    
    var focusName = ""
    var reasonWorkCompletedText = ""
    var reasonEmergencyText = ""
    var reasonFocusModeNotWorkingText = ""
    var isPausingFocusMode = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblQuestionFirst.stringValue = "Can you share why you're aborting?"
        popUpBtnAbortReasons.removeAllItems()
        btnCancel.title = "Cancel"
        btnAbortFocus.title = "Abort Focus"
        
        lblStrictModeActivated.stringValue = "Strict mode activated: you asked me to show a 15 second countdown timer before you can pause / deactivate"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let abortingFocusModeInfo = focusInfo.value(forKey: "abortingFocusModeInfo") as? NSDictionary{
                titleText = abortingFocusModeInfo.value(forKey: "title") as? String ?? titleText
                lblQuestionFirst.stringValue = abortingFocusModeInfo.value(forKey: "questionText") as? String ?? lblQuestionFirst.stringValue
                if let reasonsFirstText = abortingFocusModeInfo.value(forKey: "reasonsFirstText") as? String{
                    arrReasons[0] = reasonsFirstText
                }
                if let reasonsSecondText = abortingFocusModeInfo.value(forKey: "reasonsSecondText") as? String{
                    arrReasons[1] = reasonsSecondText
                }
                if let reasonsThirdText = abortingFocusModeInfo.value(forKey: "reasonsThirdText") as? String{
                    arrReasons[2] = reasonsThirdText
                }
                
                btnCancel.title = abortingFocusModeInfo.value(forKey: "buttonCancelText") as? String ?? btnCancel.title
                
                btnAbortFocus.title = abortingFocusModeInfo.value(forKey: "buttonAbortFocusText") as? String ?? btnAbortFocus.title
                titlePauseText = abortingFocusModeInfo.value(forKey: "titlePauseText") as? String ?? titlePauseText
                lblStrictModeActivated.stringValue = abortingFocusModeInfo.value(forKey: "strictModeText") as? String ?? lblStrictModeActivated.stringValue
            }
        }
        
        
        
        btnCancel.isSecondaryButton = true
    }

    var currentReasonIndex = 0
    func ResetData(forPause:Bool){
        isPausingFocusMode = forPause
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let abortingFocusModeInfo = focusInfo.value(forKey: "abortingFocusModeInfo") as? NSDictionary{
                if let reasons = abortingFocusModeInfo.value(forKey: "reasonsFirstText") as? String{
                    reasonWorkCompletedText = reasons
                }
                if let reasons = abortingFocusModeInfo.value(forKey: "reasonsSecondText") as? String{
                    reasonEmergencyText = reasons
                }
                if let reasons = abortingFocusModeInfo.value(forKey: "reasonsThirdText") as? String{
                    reasonFocusModeNotWorkingText = reasons
                }
            }
        }
        
        arrReasons.removeAll()
        let arr = [1,2,3]
        let randomIndex = Int(arc4random_uniform(UInt32(arr.count)))
        let randomnumber = arr[randomIndex]
        if randomnumber == 1{
            arrReasons = [reasonWorkCompletedText, reasonEmergencyText, reasonFocusModeNotWorkingText]
        }else if randomnumber == 2{
            arrReasons = [reasonEmergencyText, reasonFocusModeNotWorkingText, reasonWorkCompletedText]
        }else if randomnumber == 3{
            arrReasons = [reasonFocusModeNotWorkingText, reasonWorkCompletedText, reasonEmergencyText]
        }

        popUpBtnAbortReasons.removeAllItems()
        popUpBtnAbortReasons.addItem(withTitle: "")
        popUpBtnAbortReasons.addItems(withTitles: arrReasons)
        popUpBtnAbortReasons.selectItem(at: 0)
        
        var focusType = ""
        for i in 0..<arrFocusType.count{
            let focus = arrFocusType[i]
            if focus["isOn"] as? Bool == true || focus["isPaused"] as? Bool == true{
                focusType = focus["name"] as? String ?? ""
            }
        }
        focusName = focusType
        

        self.btnAbortFocus.isEnabled = false
        self.lblSeconds.isHidden = true
        self.lblStrictModeActivated.isHidden = true
        if currentFocusModeStrictness == ._STRICT_{
            self.lblStrictModeActivated.isHidden = false
            startTimer()
        }
        if forPause{
            lblTitle.stringValue = titlePauseText.replacingOccurrences(of: "<FOCUSTYPE>", with: focusType)
            btnAbortFocus.title = "Pause Focus Block"
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let abortingFocusModeInfo = focusInfo.value(forKey: "abortingFocusModeInfo") as? NSDictionary{
                    btnAbortFocus.title = abortingFocusModeInfo.value(forKey: "buttonPauseFocusText") as? String ?? btnAbortFocus.title
                }
            }
        }else{
            lblTitle.stringValue = titleText.replacingOccurrences(of: "<FOCUSTYPE>", with: focusType)
            btnAbortFocus.title = "Deactivate Focus Block"
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let abortingFocusModeInfo = focusInfo.value(forKey: "abortingFocusModeInfo") as? NSDictionary{
                    btnAbortFocus.title = abortingFocusModeInfo.value(forKey: "buttonAbortFocusText") as? String ?? btnAbortFocus.title
                }
            }
            
        }
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
                    
                    if self.isPausingFocusMode{
                        self.btnAbortFocus.isEnabled = true
                    }else{
                        self.btnAbortFocus.isEnabled = true
                    }
                }
            }
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        if self.timer != nil{
            self.timer?.invalidate()
        }
        self.view.window?.close()
    }
    
    @IBAction func popUpBtnAbortReasonsClicked(_ sender: Any) {
        if popUpBtnAbortReasons.titleOfSelectedItem == ""{
            self.btnAbortFocus.isEnabled = false
        }else if lblSeconds.isHidden{
            self.btnAbortFocus.isEnabled = true
        }else{
            self.btnAbortFocus.isEnabled = false
        }
    }
    @IBAction func btnAbortFocusClicked(_ sender: Any) {
        addLog(text: "[user-action] abortingFocusModeVc - btnAbortFocusClicked")//
        if isFocusModeOnOrPaused() == false{
            self.view.window?.close()
            return
        }
        if isPausingFocusMode{
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["isOn"] as? Bool == true{
                    appdelegate?.pauseFocusMode(index: i)
//                    menuViewControllerObj?.tblViewFocusMode.reloadData()
                    addLog(text: "Focus mode paused after 15 seconds timer")
                    break;
                }
            }
        }else{
            isHardCorePomodoroModeOn = false
            let isAutoMeetingsModeStarted = appdelegate!.isAutoMeetingsModeStarted
            let appUsedInAutoMeetingFocusMode = appdelegate!.appUsedInAutoMeetingFocusMode
            var reason = ""
//            if popUpBtnAbortReasons.titleOfSelectedItem == reasonFocusModeNotWorkingText{
//                reason = "Focus mode is not working properly."
//                if !focusModeTaskStringIsEmpty(){
//                    appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false)
//                }else{
//                    appdelegate?.focusModeAborted()
//                }
//
//            }else if popUpBtnAbortReasons.titleOfSelectedItem == reasonWorkCompletedText{
//                reason = "I achieved what I wanted to too early."
//                appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false)
//            }else if popUpBtnAbortReasons.titleOfSelectedItem == reasonEmergencyText{
//                reason = "I have an emergency"
//                if !focusModeTaskStringIsEmpty(){
//                    appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false)
//                }else{
//                    appdelegate?.focusModeAborted()
//                }
//            }
            reason = "I achieved what I wanted to too early."
            appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
            
            addLog(text: "Focus mode abort clicked with reason - \(reason)")
            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            if isAutoMeetingsModeStarted{
                addEntryInStatsCsv(logType: "focus mode abort", activity: "focus block - \(focusName)", durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "Meeting using {\(appUsedInAutoMeetingFocusMode)}", distractionsEncountered: "", abortReason: reason, feedback: "", tags:"")
            }else{
               addEntryInStatsCsv(logType: "focus mode abort", activity: "focus block - \(focusName)", durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: reason, feedback: "", tags:"")
            }
        }

//        self.view.window?.close()
    }
}
