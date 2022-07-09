//
//  pomodoroVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class pomodoroVc: NSViewController {

    @IBOutlet weak var lblMinutesBreakDuration: NSTextField!
    @IBOutlet weak var lblMinutesWorkDuration: NSTextField!
    @IBOutlet weak var textFieldBreakDuration: NSTextField!
    @IBOutlet weak var textFieldWorkDuration: NSTextField!
    @IBOutlet weak var lblTitleBreakDuration: NSTextField!
    @IBOutlet weak var lblTitleWorkDuration: NSTextField!
    @IBOutlet weak var stackViewPomodoroModeTime: NSStackView!
    @IBOutlet weak var btnCheckBoxHardcodePomodoro: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet weak var popUpBtnFocusType: NSPopUpButton!
    @IBOutlet weak var btnEditFocusMode: underLineButton!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet var textViewAchieve: NSTextView!
    @IBOutlet weak var lblHowManyPomodoro: NSTextField!
    @IBOutlet weak var popupBtnSelectPomodoroCount: NSPopUpButton!
    

    var isShowingMorningHardcorePomodoro = false
    var questionSecondText = "Which focus mode do you want to use?"
    var chooseTheFocusModeText = "Choose the focus mode and duration - you won't be able to change the focus mode until the time is up (you still get to use any app/website during the 5 minutes break)"
    
    var workDurationEmptyErrorText = "Work Duration can not be empty."
    var workDurationZeroErrorText = "Work Duration can not be 0."
    var breakDurationEmptyErrorText = "Break Duration can not be empty."
    var breakDurationZeroErrorText = "Break Duration can not be 0."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        isPomodoroWindowLodded = true
        
        textFieldBreakDuration.formatter = IntegerFormatter()
        textFieldWorkDuration.formatter = IntegerFormatter()
        
        lblTitleWorkDuration.stringValue = "Pomodoro Mode duration:"
        lblTitleBreakDuration.stringValue = "Break duration:"
        lblMinutesWorkDuration.stringValue = "minutes"
        lblMinutesBreakDuration.stringValue = "minutes"
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            lblTitleWorkDuration.stringValue = preferencesInfo.value(forKey: "pomodoroModeDurationText") as? String ?? lblTitleWorkDuration.stringValue
            lblMinutesWorkDuration.stringValue = preferencesInfo.value(forKey: "minutesText") as? String ?? lblMinutesWorkDuration.stringValue
            lblTitleBreakDuration.stringValue = preferencesInfo.value(forKey: "breakDurationText") as? String ?? lblTitleBreakDuration.stringValue
            lblMinutesBreakDuration.stringValue = preferencesInfo.value(forKey: "minutesText") as? String ?? lblMinutesBreakDuration.stringValue
            
            workDurationEmptyErrorText = preferencesInfo.value(forKey: "workDurationEmptyErrorText") as? String ?? workDurationEmptyErrorText
            workDurationZeroErrorText = preferencesInfo.value(forKey: "workDurationZeroErrorText") as? String ?? workDurationZeroErrorText
            breakDurationEmptyErrorText = preferencesInfo.value(forKey: "breakDurationEmptyErrorText") as? String ?? breakDurationEmptyErrorText
            breakDurationZeroErrorText = preferencesInfo.value(forKey: "breakDurationZeroErrorText") as? String ?? breakDurationZeroErrorText
            
        }
        
        lblTitle.stringValue = "It's time to focus"
        var questionFirstText = "What do you want to achieve in this pomodoro session?"
        
        btnEditFocusMode.title = "Edit focus modes"
        btnLetsDoIt.title = "Let's do it"
        btnCheckBoxHardcodePomodoro.title = "Use hardcode pomodoro mode (lock in the focus mode for multiple pomodoros)"
        lblHowManyPomodoro.stringValue = "How many pomodoros you want to focus for:"
        
//        var minute = 25
//        if let duration = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) as? Int{
//            minute = duration
//        }
        
        
        
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            if let title = pomodoroInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let questionFirst = pomodoroInfo.value(forKey: "questionFirstText") as? String{
                questionFirstText = questionFirst
            }
            if let questionSecondText = pomodoroInfo.value(forKey: "questionSecondText") as? String{
                self.questionSecondText = questionSecondText
            }
            if let buttonEditFocusModeText = pomodoroInfo.value(forKey: "buttonEditFocusModeText") as? String{
                btnEditFocusMode.title = buttonEditFocusModeText
            }
            if let buttonLetsDoItText = pomodoroInfo.value(forKey: "buttonLetsDoItText") as? String{
                btnLetsDoIt.title = buttonLetsDoItText
            }
            
            if let buttonHardcorePomodoroText = pomodoroInfo.value(forKey: "buttonHardcorePomodoroText") as? String{
                btnCheckBoxHardcodePomodoro.title = buttonHardcorePomodoroText
            }
            
            if let howManyPomodoroText = pomodoroInfo.value(forKey: "howManyPomodoroText") as? String{
                lblHowManyPomodoro.stringValue = howManyPomodoroText
            }
            
            if let chooseTheFocusModeText = pomodoroInfo.value(forKey: "chooseTheFocusModeText") as? String{
                self.chooseTheFocusModeText = chooseTheFocusModeText
            }
        }
        
//        questionFirstText = questionFirstText.replacingOccurrences(of: "25", with: "\(minute)")
        lblQuestionFirst.stringValue = questionFirstText
        popUpBtnFocusType.removeAllItems()

        lblQuestionSecond.stringValue = questionSecondText

        popupBtnSelectPomodoroCount.removeAllItems()
        for i in 2...20{
            popupBtnSelectPomodoroCount.addItem(withTitle: "\(i)")
        }

    }
    override func viewWillAppear() {
        
        
        whatToAchieveInFocusBlock = ""
        textViewAchieve.string = ""
        reFillFocusTypeList()
        if startingFocusWindowControllerObj?.window?.isVisible ?? false{
            if startingFocusWindowControllerObj?.contentViewController == startingFocusModeVcObj{
                startingFocusWindowControllerObj?.close()
            }
        }
        

        if isShowingMorningHardcorePomodoro{
            
            if let count = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedCount) as? Int{
                popupBtnSelectPomodoroCount.selectItem(withTitle: "\(count)")
            }
           if let name = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedName) as? String{
               popUpBtnFocusType.selectItem(withTitle: name)
           }
            btnLetsDoIt.isEnabled = true
            btnCheckBoxHardcodePomodoro.state = .on
            btnCheckBoxHardcodePomodoro.isEnabled = false
            popUpBtnFocusType.isEnabled = false
            btnEditFocusMode.isEnabled = false
            popupBtnSelectPomodoroCount.isEnabled = false
            lblQuestionSecond.stringValue = chooseTheFocusModeText
            stackViewPomodoroModeTime.isHidden = false
            textFieldWorkDuration.isEnabled = false
            textFieldBreakDuration.isEnabled = false
            
            if let duration = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) as? Int{
                textFieldWorkDuration.stringValue = "\(duration)"
            }
            
            if let duration = UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationMinutes) as? Int{
                textFieldBreakDuration.stringValue = "\(duration)"
            }
        }else if isHardCorePomodoroModeOn{
            btnLetsDoIt.isEnabled = true
            btnCheckBoxHardcodePomodoro.isEnabled = false
            popUpBtnFocusType.selectItem(at: hardcodePmodoroFocusModeIndex)
            popUpBtnFocusType.isEnabled = false
            btnEditFocusMode.isEnabled = false
            popupBtnSelectPomodoroCount.isEnabled = false
            lblQuestionSecond.stringValue = chooseTheFocusModeText
            stackViewPomodoroModeTime.isHidden = false
            btnCheckBoxHardcodePomodoro.state = .on
            textFieldWorkDuration.isEnabled = false
            textFieldBreakDuration.isEnabled = false
        }else{
            textFieldWorkDuration.isEnabled = true
            textFieldBreakDuration.isEnabled = true
            btnCheckBoxHardcodePomodoro.state = .off
            btnCheckBoxHardcodePomodoro.isEnabled = true
            popUpBtnFocusType.isEnabled = true
            btnEditFocusMode.isEnabled = true
            btnLetsDoIt.isEnabled = true
            popupBtnSelectPomodoroCount.isEnabled = true
            if btnCheckBoxHardcodePomodoro.state == .on{
                lblQuestionSecond.stringValue = chooseTheFocusModeText
                stackViewPomodoroModeTime.isHidden = false
            }else{
                lblQuestionSecond.stringValue = questionSecondText
                stackViewPomodoroModeTime.isHidden = true
                
            }
            if let duration = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) as? Int{
                textFieldWorkDuration.stringValue = "\(duration)"
            }
            
            if let duration = UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationMinutes) as? Int{
                textFieldBreakDuration.stringValue = "\(duration)"
            }
        }
        
        if isShowingMorningHardcorePomodoro{
            isHardCorePomodoroModeOn = true
            self.view.window?.styleMask.remove(.closable)
            currentPomodoroWorkDuration = textFieldWorkDuration.integerValue
            currentPomodoroBreakDuration = textFieldBreakDuration.integerValue
            hardcodePmodoroFocusModeIndex = popUpBtnFocusType.indexOfSelectedItem
            let totalPopmodoroCount = Int(popupBtnSelectPomodoroCount.title) ?? 2
            let minutes = currentPomodoroWorkDuration

            
            let totoalMinutes = (totalPopmodoroCount * minutes) //* 60//(textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
            totalMinutesRemainingForHardcodePomodoro = totoalMinutes
            pomodoroModeStarted()
        }else{
            if isHardCorePomodoroModeOn{
                pomodoroModeStarted()
                self.view.window?.styleMask.remove(.closable)
            }else{
                self.view.window?.styleMask.insert(.closable)
            }
        }
        
    }
    func reFillFocusTypeList(){
        var index = popUpBtnFocusType.indexOfSelectedItem
        if index == -1{
            index = 0
        }
        popUpBtnFocusType.removeAllItems()
        for i in 0..<arrFocusType.count{
            if let name = arrFocusType[i]["name"] as? String{
                popUpBtnFocusType.addItem(withTitle: name)
            }
        }
        if arrFocusType.count <= index{
            index = 0
        }
        popUpBtnFocusType.selectItem(at: index)
    }
    @IBAction func popUpBtnFocusTypeClicked(_ sender: Any) {
    }
    
    @IBAction func btnEditFocusModeClicked(_ sender: Any) {
        if preferencesWindowControllerObj?.window?.isVisible ?? false{
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = 1
            }
            return;
        }
        preferencesWindowControllerObj?.showWindow(self)
        addLog(text: "Showing preferences from edit focus mode")
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = 1
            if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{
                tabview.view.addSubview(Focus_Bear.enterPasswordVcObj!.view)
                tabview.view.addConstraints(subView: Focus_Bear.enterPasswordVcObj!.view)
                addLog(text: "Showing enter password view")
                
            }
        }
        
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func showAlert(msg:String){
        let alertWarning = NSAlert()
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alertWarning.window.sharingType = .none
            }
        }
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler:nil)
    }
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        if textFieldWorkDuration.isEnabled{
            if textFieldWorkDuration.stringValue.isEmpty{
                showAlert(msg: workDurationEmptyErrorText)
                return;
            }
            if textFieldWorkDuration.integerValue < 1{
                showAlert(msg: workDurationZeroErrorText)
                return;
            }
        }
        if textFieldBreakDuration.isEnabled{
           if textFieldBreakDuration.stringValue.isEmpty{
                  showAlert(msg: breakDurationEmptyErrorText)
                return;
            }
            if textFieldBreakDuration.integerValue < 1{
                showAlert(msg: breakDurationZeroErrorText)
                return;
            }
        }
        if isDiscourageDefaultFocusVcVisible{
            return
        }
        if isHardCorePomodoroModeOn{
            whatToAchieveInFocusBlock = textViewAchieve.string
            self.view.window?.close()
            return;
        }
        if textFieldWorkDuration.isEnabled{
            currentPomodoroWorkDuration = textFieldWorkDuration.integerValue
        }
        if textFieldBreakDuration.isEnabled{
            currentPomodoroBreakDuration = textFieldBreakDuration.integerValue
        }
        if arrFocusType[popUpBtnFocusType.indexOfSelectedItem]["isDefault"] as? Bool == true{
            self.presentAsSheet(getDiscourageDefaultFocusVcObject())
            getDiscourageDefaultFocusVcObject().resetData()
        }else{
            if isHardCorePomodoroModeOn{
                
            }else if btnCheckBoxHardcodePomodoro.state == .on{
                isHardCorePomodoroModeOn = true
                hardcodePmodoroFocusModeIndex = popUpBtnFocusType.indexOfSelectedItem
                let totalPopmodoroCount = Int(popupBtnSelectPomodoroCount.title) ?? 2
                let minutes = textFieldWorkDuration.integerValue

                
                let totoalMinutes = (totalPopmodoroCount * minutes) //* 60//(textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
                totalMinutesRemainingForHardcodePomodoro = totoalMinutes
                
            }
            pomodoroModeStarted()
            self.view.window?.close()
        }
    }
    
   
    func pomodoroModeStarted(){
        addLog(text: "pomodoro mode Started")
        
        if getEndFocusModeWindowControllerObj().window!.isVisible{
            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "")
            getEndFocusModeWindowControllerObj().window?.close()
        }
        let minute = textFieldWorkDuration.integerValue
//        if let duration = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) as? Int{
//            minute = duration
//        }
        let calendar = Calendar.current
        endFocusModeTime = calendar.date(byAdding: .minute, value: minute, to: Date())
        startFocusModeTime = Date()
        arrFocusType[popUpBtnFocusType.indexOfSelectedItem]["isOn"] = true
        runAppleScriptBeforeFocusBeginIfAvailable(index: popUpBtnFocusType.indexOfSelectedItem)
        
        appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: arrFocusType[popUpBtnFocusType.indexOfSelectedItem]["color"] as? String ?? "")
        appdelegate!.statusbutton?.title = buttonStatusStateFocusText
        
        appdelegate!.statusbutton?.imagePosition = .imageLeft

        for i in 0..<arrFocusType.count{
            if i != popUpBtnFocusType.indexOfSelectedItem{
                arrFocusType[i]["isOn"] = false
            }
        }
        
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        isFocusTimeType = ._HOUR_
        
        appdelegate?.setFocusModeTimer(hour: nil, minute: minute)
        isFocusModeStartedFromPomodoroMode = true
        appdelegate!.focusModeStartted()
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        whatToAchieveInFocusBlock = textViewAchieve.string
//        if focusPreferencesVcObj != nil{
//            if (preferencesWindowControllerObj?.window!.isVisible)!{
//                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                    if tabview.selectedTabViewItemIndex == 1{
//                        focusPreferencesVcObj?.focusModeStarted()
//                    }
//                }
//            }
//        }

    }
    @IBAction func btnCheckBoxHardcodePomodoroClicked(_ sender: Any) {
        if btnCheckBoxHardcodePomodoro.state == .on{
            lblQuestionSecond.stringValue = chooseTheFocusModeText
            stackViewPomodoroModeTime.isHidden = false

            if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) == nil{
                let alertWarning = NSAlert()
                if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alertWarning.window.sharingType = .none
                    }
                }
                if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alertWarning.window.sharingType = .none
                    }
                }
                alertWarning.messageText = "To make hardcore pomodoro mode more effective, we recommend setting a password (ask someone else to do it for you) otherwise you'll still be able to cancel the focus modes before the time is up."
                if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                    if let alertWarningPaswwordSetText = pomodoroInfo.value(forKey: "alertWarningPaswwordSetText") as? String{
                        alertWarning.messageText = alertWarningPaswwordSetText
                    }
                }
                alertWarning.beginSheetModal(for: self.view.window!, completionHandler:nil)
            }
            
        }else{
            lblQuestionSecond.stringValue = questionSecondText
            stackViewPomodoroModeTime.isHidden = true
            btnLetsDoIt.isEnabled = true
        }
        
    }
    var enterPasswordVcObj: enterPasswordVc?
    func closeAndAbortHardcodePomodoroMode(){
        if self.enterPasswordVcObj == nil{
            self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc
        }
        self.presentAsModalWindow(enterPasswordVcObj!)
        enterPasswordVcObj?.parentVc = self
//        self.view.addSubview(self.enterPasswordVcObj!.view)
//        self.view.addConstraints(subView: self.enterPasswordVcObj!.view)
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.enterPasswordVcObj?.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
                self.enterPasswordVcObj?.view.window?.title = ""
                self.enterPasswordVcObj?.view.window?.styleMask.remove(.closable)
                self.enterPasswordVcObj?.view.window?.styleMask.remove(.resizable)
            }
        }
        addLog(text: "Showing enter password view from hardcodre pomodoro close")
        
    }
    func passwordIsCorrect(){
        print("password Correct")
        isHardCorePomodoroModeOn = false
        self.view.window?.close()
    }
    
}


//extension pomodoroVc:NSTextFieldDelegate{
//    func controlTextDidChange(_ obj: Notification) {
//        if let textfield = obj.object as? NSTextField{
//            if textfield == textFieldWorkDuration{
//                let count = textfield.integerValue
////                if count < 5 {
////                    count = 5
////                }
////                if count > 720{
////                    count = 720
////                }
//                textfield.stringValue = "\(count)"
//            }else if textfield == textFieldBreakDuration{
//                let count = textfield.integerValue
//                textfield.stringValue = "\(count)"
//            }
//        }
//    }
//}
class IntegerFormatter: NumberFormatter {

    let maxLength = 3

    let wrongCharacterSet = CharacterSet(charactersIn: "0123456789").inverted
     override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        self.maximumFractionDigits = 2
        self.minimumFractionDigits = 0

        if partialString.count > maxLength {
                return false
        }
        if partialString.rangeOfCharacter(from: wrongCharacterSet) != nil {
                return false


        }

        return true

    }
}
