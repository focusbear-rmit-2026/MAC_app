//
//  generalVc.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 09/02/22.

//

import Cocoa

class generalVc: NSViewController, NSTextFieldDelegate {

    
    @IBOutlet weak var btnCheckForUpdates: Button!
    @IBOutlet weak var btnExportStatistics: Button!
    @IBOutlet weak var lblTitleStatistics: NSTextField!
    @IBOutlet weak var lblTitleUpdates: NSTextField!
    @IBOutlet weak var lblTitleSound: NSTextField!
    @IBOutlet weak var lblVersion: NSTextField!
    @IBOutlet weak var lblMinutesBreak: NSTextField!
    @IBOutlet weak var lblMinutesPomodoro: NSTextField!
    @IBOutlet weak var textFieldPomodoroDuration: NSTextField!
    @IBOutlet weak var textFieldBreakDuration: NSTextField!
    
    @IBOutlet weak var lblHardcorePomodoroState: NSTextField!
    @IBOutlet weak var btnAdvancedPmodoroMode: NSButton!
    @IBOutlet weak var popUpBtnselectLanguage: NSPopUpButton!
    @IBOutlet weak var lblTitleSelectLanguage: NSTextField!
    @IBOutlet weak var checkBoxPromptToAskNextHabit: NSButton!
    @IBOutlet weak var lblCheckBoxPromptToAskNextHabit: NSTextField!
    @IBOutlet weak var lblTitleAskNextHabit: NSTextField!
    @IBOutlet weak var lblTitleReduceMotion: NSTextField!
    @IBOutlet weak var lblCheckBoxStringReduceMotion: NSTextField!
    @IBOutlet weak var checkBoxReduceMotion: NSButton!
    @IBOutlet weak var checkBoxPomodoroMode: NSButton!
    @IBOutlet weak var lblCheckBoxStringPomodoroMode: NSTextField!
    @IBOutlet weak var lblTitleSurveillance: NSTextField!
    @IBOutlet weak var lblDescriptionSurveillance: NSTextField!
    @IBOutlet weak var lblCheckBoxStringSurveillance: NSTextField!
    @IBOutlet weak var checkBoxHideAppScreenshots: NSButton!
    
    @IBOutlet weak var lblCheckBoxSound: NSTextField!
    @IBOutlet weak var checkBoxSound: NSButton!
    @IBOutlet weak var lblTitlePomodoroModeDuration: NSTextField!
    @IBOutlet weak var lblTitlePomodoroMode: NSTextField!
    @IBOutlet weak var lblTitleBreakDuration: NSTextField!
    
    var hardCorePomodoroEnabledText = "Hardcore Pomodoro mode enabled to focus on <FOCUSTYPE> for <COUNT> on <DAYS>."
    var hardCorePomodoroNotEnabledText = "Hardcore Pomodoro mode not enabled."
    var automaticPomodoroNotEnabledText = "Automatic Pomodoro mode is disabled."
   
    var workDurationEmptyErrorText = "Work Duration can not be empty."
    var workDurationZeroErrorText = "Work Duration can not be 0."
    var breakDurationEmptyErrorText = "Break Duration can not be empty."
    var breakDurationZeroErrorText = "Break Duration can not be 0."
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        Sound:Play sound effects
        lblTitleStatistics.stringValue = "Statistics:"
        lblTitleUpdates.stringValue = "Updates:"
        btnExportStatistics.title = "Export Statistics"
        btnCheckForUpdates.title = "Check for updates"
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            btnExportStatistics.title = menuInfo.value(forKey: "menuItemExportStatisticsTitle") as? String ?? btnExportStatistics.title
            
            btnCheckForUpdates.title = menuInfo.value(forKey: "menuItemCheckForUpdatesTitle") as? String ?? btnCheckForUpdates.title
        }
        
        lblTitleSound.stringValue = "Sound:"
        lblCheckBoxSound.stringValue = "Play sound effects"
        
        lblTitleSurveillance.stringValue = "Surveillance:"
        lblCheckBoxStringSurveillance.stringValue = "I'm under employer surveillance"
        lblDescriptionSurveillance.stringValue = "Hide Focus Bear in screenshots"
        
        var versionText = "Version:"
        var titleReduceMotion = "Reduce motion:"
        var checkBoxReduceMotionText = "Prefer reduced motion (don't show animated bears)"
        var titleAskNextHabit = "Next habit reminder:"
        var checkBoxPromptToAskNextHabitText = "Occasionally prompt me to remember the next habit"

        var buttonAdvancedText = "Advanced..."
        var pomodoroModeDurationText = "Pomodoro Mode duration"
        var minutesText = "minutes"
        var breakDurationText = "Break duration:"
        
        var titlePomodoro = "Pomodoro Mode:"
        var checkBoxPomodoroText = "Enter Pomodoro mode after completing morning routine"
        
        var titleSelectLanguage = "Select Language:"
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            titlePomodoro = preferencesInfo.value(forKey: "titlePomodoro") as? String ?? titlePomodoro
            checkBoxPomodoroText = preferencesInfo.value(forKey: "checkBoxPomodoroText") as? String ?? checkBoxPomodoroText
            titleReduceMotion = preferencesInfo.value(forKey: "titleReduceMotion") as? String ?? titleReduceMotion
            checkBoxReduceMotionText = preferencesInfo.value(forKey: "checkBoxReduceMotionText") as? String ?? checkBoxReduceMotionText
            titleAskNextHabit = preferencesInfo.value(forKey: "titleAskNextHabit") as? String ?? titleAskNextHabit
            checkBoxPromptToAskNextHabitText = preferencesInfo.value(forKey: "checkBoxPromptToAskNextHabitText") as? String ?? checkBoxPromptToAskNextHabitText
            titleSelectLanguage = preferencesInfo.value(forKey: "titleSelectLanguage") as? String ?? titleSelectLanguage
            buttonAdvancedText = preferencesInfo.value(forKey: "buttonAdvancedText") as? String ?? buttonAdvancedText
            pomodoroModeDurationText = preferencesInfo.value(forKey: "pomodoroModeDurationText") as? String ?? pomodoroModeDurationText
            minutesText = preferencesInfo.value(forKey: "minutesText") as? String ?? minutesText
            breakDurationText = preferencesInfo.value(forKey: "breakDurationText") as? String ?? breakDurationText
            hardCorePomodoroEnabledText = preferencesInfo.value(forKey: "hardCorePomodoroEnabledText") as? String ?? hardCorePomodoroEnabledText
            hardCorePomodoroNotEnabledText = preferencesInfo.value(forKey: "hardCorePomodoroNotEnabledText") as? String ?? hardCorePomodoroNotEnabledText
            automaticPomodoroNotEnabledText = preferencesInfo.value(forKey: "automaticPomodoroNotEnabledText") as? String ?? automaticPomodoroNotEnabledText
            
            lblTitleSurveillance.stringValue = preferencesInfo.value(forKey: "titleSurveillance") as? String ?? lblTitleSurveillance.stringValue
            lblCheckBoxStringSurveillance.stringValue = preferencesInfo.value(forKey: "checkBoxSurveillanceText") as? String ?? lblCheckBoxStringSurveillance.stringValue
            lblDescriptionSurveillance.stringValue = preferencesInfo.value(forKey: "descriptionSurveillanceText") as? String ?? lblDescriptionSurveillance.stringValue
            
            workDurationEmptyErrorText = preferencesInfo.value(forKey: "workDurationEmptyErrorText") as? String ?? workDurationEmptyErrorText
            workDurationZeroErrorText = preferencesInfo.value(forKey: "workDurationZeroErrorText") as? String ?? workDurationZeroErrorText
            breakDurationEmptyErrorText = preferencesInfo.value(forKey: "breakDurationEmptyErrorText") as? String ?? breakDurationEmptyErrorText
            breakDurationZeroErrorText = preferencesInfo.value(forKey: "breakDurationZeroErrorText") as? String ?? breakDurationZeroErrorText
            versionText = preferencesInfo.value(forKey: "versionText") as? String ?? versionText
            lblTitleSound.stringValue = preferencesInfo.value(forKey: "titleSound") as? String ?? lblTitleSound.stringValue
            lblCheckBoxSound.stringValue = preferencesInfo.value(forKey: "checkBoxSoundText") as? String ?? lblCheckBoxSound.stringValue
            
            lblTitleStatistics.stringValue = preferencesInfo.value(forKey: "statisticsText") as? String ?? lblTitleStatistics.stringValue
            lblTitleUpdates.stringValue = preferencesInfo.value(forKey: "updatesText") as? String ?? lblTitleUpdates.stringValue
            

        }

        lblTitlePomodoroModeDuration.stringValue = pomodoroModeDurationText
        lblTitleBreakDuration.stringValue = breakDurationText
        lblMinutesPomodoro.stringValue = minutesText
        lblMinutesBreak.stringValue = minutesText
        
        lblTitlePomodoroMode.stringValue = titlePomodoro
        lblCheckBoxStringPomodoroMode.stringValue = checkBoxPomodoroText
        
        lblTitleReduceMotion.stringValue = titleReduceMotion
        lblCheckBoxStringReduceMotion.stringValue = checkBoxReduceMotionText
        lblTitleAskNextHabit.stringValue = titleAskNextHabit
        lblCheckBoxPromptToAskNextHabit.stringValue = checkBoxPromptToAskNextHabitText
        lblTitleSelectLanguage.stringValue = titleSelectLanguage
        popUpBtnselectLanguage.removeAllItems()
        
        for language in arrLanguageDic{
            popUpBtnselectLanguage.addItem(withTitle: language["name"] ?? "")
        }
        
        btnAdvancedPmodoroMode.title = buttonAdvancedText

        textFieldPomodoroDuration.formatter = IntegerFormatter()
        textFieldBreakDuration.formatter = IntegerFormatter()
        
        textFieldPomodoroDuration.delegate = self
        textFieldBreakDuration.delegate = self
        

        if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
            lblVersion.stringValue = versionText + " " + version + "." + build
        }else{
            lblVersion.stringValue = ""
        }
    }
    
    
    override func viewWillAppear() {
       
        
        if SettingsManagerObject.isSoundEnabled{
            checkBoxSound.state = .on
        }else{
            checkBoxSound.state = .off
        }
        
        resetPomodoroModeState()
        
        if SettingsManagerObject.kIsReducedMotion{
            checkBoxReduceMotion.state = .on
        }else{
            checkBoxReduceMotion.state = .off
        }
        if SettingsManagerObject.isPromptToRememberHabit{
            checkBoxPromptToAskNextHabit.state = .on
        }else{
            checkBoxPromptToAskNextHabit.state = .off
        }
//        if let state = UserDefaults.standard.object(forKey: kUserdefaultsReducedMotion) as? Bool{
//            if state{
//                checkBoxReduceMotion.state = .on
//                kIsReducedMotion = true
//            }else{
//                checkBoxReduceMotion.state = .off
//                kIsReducedMotion = false
//            }
//        }
//        if let state = UserDefaults.standard.object(forKey: kUserdefaultsPromptToRememberHabit) as? Bool{
//            if state{
//                checkBoxPromptToAskNextHabit.state = .on
//                isPromptToRememberHabit = true
//            }else{
//                checkBoxPromptToAskNextHabit.state = .off
//                isPromptToRememberHabit = false
//            }
//        }
        
        if let language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String{
            for i in 0..<arrLanguageDic.count{
                if arrLanguageDic[i]["id"]  == language{
                    popUpBtnselectLanguage.selectItem(at: i)
                    break;
                }
            }
        }

        
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                checkBoxHideAppScreenshots.state = .on
            }else{
                checkBoxHideAppScreenshots.state = .off
            }
        }
        
        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
            textFieldPomodoroDuration.stringValue = "\(duration)"
        }
        
        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes) as? Int{
            textFieldBreakDuration.stringValue = "\(duration)"
        }
    }
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
    override func viewDidAppear() {
        self.textFieldPomodoroDuration.window?.makeFirstResponder(nil)
        
        if Reachability.isConnectedToNetwork() == false {
            if self.view.window != nil{
                showAlertNoInternet(window: self.view.window!)
            }
            return
        }
        
    }
    
    @IBAction func checkBoxHideAppScreenshotsClicked(_ sender: Any) {
        let windows = NSApp.windows
        SettingsManagerObject.isSettingsChanged = true
        
        if checkBoxHideAppScreenshots.state == .on{
            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots)
            for win in windows{
                print(win)
                win.sharingType = .none
            }
        }else{
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots)
            for win in windows{
                print(win)
                win.sharingType = .readOnly
            }
        }
    }
    
    func resetPomodoroModeState(){
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool{
            if state{
                checkBoxPomodoroMode.state = .on
                if let hardCorePomodoroState = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{

                    if hardCorePomodoroState{
                        var hardCorePomodoroFocusName = ""
                        var hardCorePomodoroCount = 2
                        var arrDaysHardcorePomodoro = [String]()

                        if let arrDays = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroArrDays) as? [String]{
                            arrDaysHardcorePomodoro = arrDays
                        }
                        if let count = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedCount) as? Int{
                            hardCorePomodoroCount = count
                        }
                        if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
                            hardCorePomodoroFocusName = name
                        }
                        
                        var daysString = ""
     
                        
                        var andText = "and"
                        if let common = configjson.value(forKey: "common") as? NSDictionary{
                            andText = common.value(forKey: "andText") as? String ?? andText
                        }
                        for i in 0..<arrDaysHardcorePomodoro.count{
                            var day = arrDaysHardcorePomodoro[i]
                            
                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                switch day {
                                case SettingsManagerObject.kMonday:
                                    day = common.value(forKey: "mondayText") as? String ?? day
                                case SettingsManagerObject.kTuesday:
                                    day = common.value(forKey: "tuesdayText") as? String ?? day
                                case SettingsManagerObject.kWednesday:
                                    day = common.value(forKey: "wednesdayText") as? String ?? day
                                case SettingsManagerObject.kThursday:
                                    day = common.value(forKey: "thursdayText") as? String ?? day
                                case SettingsManagerObject.kFriday:
                                    day = common.value(forKey: "fridayText") as? String ?? day
                                case SettingsManagerObject.kSaturday:
                                    day = common.value(forKey: "saturdayText") as? String ?? day
                                case SettingsManagerObject.kSunday:
                                    day = common.value(forKey: "sundayText") as? String ?? day
                                default:
                                    day = common.value(forKey: "mondayText") as? String ?? day
                                }
                            }
                            
                            if arrDaysHardcorePomodoro.count == 1{
                                daysString = day
                            }else{
                                if i == arrDaysHardcorePomodoro.count - 1{
                                    daysString = daysString + " \(andText) " + day
                                }else{
                                    if daysString.isEmpty{
                                        daysString = day
                                    }else{
                                        daysString = daysString + ", " + day
                                    }
                                }
                            }
                            
                        }
                        var hardcorePomodoroEnabledText = self.hardCorePomodoroEnabledText
                        hardcorePomodoroEnabledText = hardcorePomodoroEnabledText.replacingOccurrences(of: "<FOCUSTYPE>", with: hardCorePomodoroFocusName)
                        hardcorePomodoroEnabledText = hardcorePomodoroEnabledText.replacingOccurrences(of: "<COUNT>", with: "\(hardCorePomodoroCount)")
                        hardcorePomodoroEnabledText = hardcorePomodoroEnabledText.replacingOccurrences(of: "<DAYS>", with: daysString)
                        lblHardcorePomodoroState.stringValue = hardcorePomodoroEnabledText//"Hardcore Pomodoro mode enabled to focus on \(hardCorePomodoroFocusName) for \(hardCorePomodoroCount) on \(daysString)."//
                    }else{
                        lblHardcorePomodoroState.stringValue = hardCorePomodoroNotEnabledText//"Hardcore Pomodoro mode not enabled."
                    }
                }
            }else{
                checkBoxPomodoroMode.state = .off
                lblHardcorePomodoroState.stringValue = automaticPomodoroNotEnabledText//"Automatic Pomodoro mode is disabled."//POMODORO MOD IS DISABLED."
            }
        }
    }
//    func controlTextDidChange(_ obj: Notification) {
//        if let textfield = obj.object as? NSTextField{
//            if textfield == textFieldPomodoroDuration{
//                var count = textfield.integerValue
//                if count < 5 {
//                    count = 5
//                }
//                if count > 720{
//                    count = 720
//                }
////                if count < 10{
////                    textfield.stringValue = "0\(count)"
////                }else{
//                    textfield.stringValue = "\(count)"
////                }
//                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes)
//            }
//        }
//    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldPomodoroDuration{
                
                if textFieldPomodoroDuration.stringValue.isEmpty{
                    showAlert(msg: workDurationEmptyErrorText, completionHandler: {_ in
                        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                            tabview.selectedTabViewItemIndex = 0
                        }
                        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
                            self.textFieldPomodoroDuration.stringValue = "\(duration)"
                        }
                        textfield.setFocus()
                    })
                    return;
                }
                if textFieldPomodoroDuration.integerValue < 1{
                    showAlert(msg: workDurationZeroErrorText, completionHandler: {_ in
                        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                            tabview.selectedTabViewItemIndex = 0
                        }
                        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
                            self.textFieldPomodoroDuration.stringValue = "\(duration)"
                        }
                        textfield.setFocus()
                    })
                    return;
                }
                let count = textfield.integerValue
                if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
                    if count == oldCount{
                        return;
                    }
                }
                SettingsManagerObject.isSettingsChanged = true
                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes)
            }else if textfield == textFieldBreakDuration{
                if textFieldBreakDuration.stringValue.isEmpty{
                    showAlert(msg: breakDurationEmptyErrorText, completionHandler: {_ in
                        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                            tabview.selectedTabViewItemIndex = 0
                        }
                        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes) as? Int{
                            self.textFieldBreakDuration.stringValue = "\(duration)"
                        }
                        textfield.setFocus()
                    })
                    return;
                }
                if textFieldBreakDuration.integerValue < 1{
                    showAlert(msg: breakDurationZeroErrorText, completionHandler: {_ in
                        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                            tabview.selectedTabViewItemIndex = 0
                        }
                        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes) as? Int{
                            self.textFieldBreakDuration.stringValue = "\(duration)"
                        }
                        textfield.setFocus()
                    })
                    return;
                }
                let count = textfield.integerValue
                if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes) as? Int{
                    if count == oldCount{
                        return;
                    }
                }
                SettingsManagerObject.isSettingsChanged = true
                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes)
            }
        }
    }
    
    
    func showAlert(msg:String, completionHandler: @escaping(_ result: Bool) -> ()) {
        let alertWarning = NSAlert()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alertWarning.window.sharingType = .none
            }
        }
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
//            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
//                print("okclicked")
//                // self.txtFieldEmail.stringValue = ""
//            }
            completionHandler(true)
            return
        })
    }
    
    @IBAction func popUpBtnselectLanguageClicked(_ sender: Any) {
        //        var
        var oldSelectedIndex = 0
        if let language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String{
            for i in 0..<arrLanguageDic.count{
                if arrLanguageDic[i]["id"]  == language{
                    oldSelectedIndex = i
                    break;
                }
            }
        }
        if popUpBtnselectLanguage.indexOfSelectedItem == oldSelectedIndex{
            return;
        }
//        SettingsManagerObject.isSettingsChanged = true
        let alert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alert.window.sharingType = .none
            }
        }
        var alertChangeLanguageMessageText = "Are you sure you want to change the language to <LANGUAGE>?"
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            alertChangeLanguageMessageText = preferencesInfo.value(forKey: "alertChangeLanguageMessageText") as? String ?? alertChangeLanguageMessageText
        }
        alertChangeLanguageMessageText = alertChangeLanguageMessageText.replacingOccurrences(of: "<LANGUAGE>", with: popUpBtnselectLanguage.title)
        alert.messageText = alertChangeLanguageMessageText
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                addLog(text: "language changed by user to \(self.popUpBtnselectLanguage.title)")
                UserDefaults.standard.set(arrLanguageDic[self.popUpBtnselectLanguage.indexOfSelectedItem]["id"], forKey: kUserdefaultsSelectedLanguage)
                
                appdelegate?.quitAndRestartApp()
            }else{
                self.popUpBtnselectLanguage.selectItem(at: oldSelectedIndex)
            }
        })
    }
//    @IBAction func btnSelectFolderClicked(_ sender: Any) {
//        let dialog = NSOpenPanel()
//        dialog.canChooseFiles = false
//        dialog.canChooseDirectories = true
//        dialog.message = "Please select a folder"
//        dialog.prompt = "Select"
//        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
//            dialog.message = preferencesInfo.value(forKey: "selectFolderText") as? String ?? dialog.message
//            dialog.prompt = preferencesInfo.value(forKey: "buttonSelectText") as? String ?? dialog.prompt
//        }
//        dialog.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
//            if modalResponse.rawValue == NSApplication.ModalResponse.OK.rawValue {
//                if let url = dialog.url {
//                    UserDefaults.standard.set(url.path, forKey: kUserdefaultsSelectedFolder)
//                    self.lblCurrentFolderUrl.stringValue = url.path
//                }
//            }
//        })
//    }

    
    @IBAction func checkBoxPomodoroModeClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxPomodoroMode.state == .on{
            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled)
            
            if let hardCorePomodoroState = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
                if hardCorePomodoroState{
                    if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
                        let filterArr = arrFocusType.filter { $0["name"] as? String ?? "" == name}
                        if filterArr.count == 0{
                            let alert = NSAlert()
                            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                                if state{
                                    alert.window.sharingType = .none
                                }
                            }
                            var messageText = "Please review focus mode settings for hardcore pomodoro mode."
                            if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                                messageText = preferencesInfo.value(forKey: "reviewFocusModeAlertText") as? String ?? messageText
                            }
                            
                            alert.messageText = messageText
                            alert.addButton(withTitle: buttonOkText)
                            
                            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                    self.showHardCorePomodoroSetting()
                                }else{
                                    
                                }
                            })
                        }
                    }
                }
            }
        }else{
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled)
        }
        resetPomodoroModeState()
    }
    @IBAction func checkBoxSoundClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSound.state == .on{
            SettingsManagerObject.isSoundEnabled = true
        }else{
            SettingsManagerObject.isSoundEnabled = false
        }
    }
    @IBAction func checkBoxReduceMotionClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxReduceMotion.state == .on{
//            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsReducedMotion)
            SettingsManagerObject.kIsReducedMotion = true
        }else{
//            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsReducedMotion)
            SettingsManagerObject.kIsReducedMotion = false
        }
        
    }
    @IBAction func checkBoxPromptToAskNextHabitClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxPromptToAskNextHabit.state == .on{
//            UserDefaults.standard.set(true, forKey: kUserdefaultsPromptToRememberHabit)
            SettingsManagerObject.isPromptToRememberHabit = true
        }else{
//            UserDefaults.standard.set(false, forKey: kUserdefaultsPromptToRememberHabit)
            SettingsManagerObject.isPromptToRememberHabit = false
        }
    }
    var pomodoroPreferencesAdvancedVcObj:pomodoroPreferencesAdvancedVc?
    @IBAction func btnAdvancedPmodoroModeClicked(_ sender: Any) {
        showHardCorePomodoroSetting()
    }
    func showHardCorePomodoroSetting(){
        if pomodoroPreferencesAdvancedVcObj == nil{
            pomodoroPreferencesAdvancedVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroPreferencesAdvancedVc")) as? pomodoroPreferencesAdvancedVc
            pomodoroPreferencesAdvancedVcObj!.generalVcObj = self
        }
        self.presentAsSheet(pomodoroPreferencesAdvancedVcObj!)
    }
    
    @IBAction func btnExportStatisticsClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.prompt = "Export"
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                openPanel.sharingType = .none
            }
        }
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            openPanel.prompt = common.value(forKey: "buttonExportText") as? String ?? "Export"
        }
        
        openPanel.beginSheetModal(for: self.view.window!) { response in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                //                if var arr =
                
                return
            }
            //        if button == NSApplication.ModalResponse.OK {
            if let url = openPanel.url {
                let filemanager = FileManager.default
                let destUrl = url.appendingPathComponent(quantityCsvURL.lastPathComponent)
                if filemanager.fileExists(atPath: destUrl.path){
                    do{
                        try filemanager.removeItem(at: destUrl)
                    }catch{
                        print(error)
                    }
                }
                
                do{
                    try FileManager.default.copyItem(at: quantityCsvURL, to: destUrl)
                }catch{
                    print(error)
                }
            }
            //        }
        }
    }
    @IBAction func btnCheckForUpdatesClicked(_ sender: Any) {
        addLog(text: "btnCheckForUpdatesClicked")//
        appdelegate!.updater?.checkForUpdates(self)
        preferencesWindowControllerObj?.window?.miniaturize(self)
    }
}

