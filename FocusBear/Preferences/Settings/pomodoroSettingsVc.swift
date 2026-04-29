//
//  pomodoroSettingsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class pomodoroSettingsVc: NSViewController {
    
    @IBOutlet weak var lineBottomShortcutPomodoro: NSBox!
    @IBOutlet weak var lblTo: NSTextField!
    @IBOutlet weak var textFieldBreakRatio: NSTextField!
    @IBOutlet weak var textFieldWorkRatio: NSTextField!
    @IBOutlet weak var boxWorkToBreakRatio: NSBox!
    @IBOutlet weak var btnInfoPomodoroShortcut: hoverInfoButton!
    @IBOutlet weak var boxShortcutPomodoro: NSBox!
    @IBOutlet weak var boxPomodoroModeDuration: NSBox!// not in use
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var boxSuperPomodoro: NSBox!
    @IBOutlet weak var boxPomodoro: NSBox!
    @IBOutlet weak var lblTitleShortcut: NSTextField!
    @IBOutlet weak var lblrecordShorcutPomodoro: NSTextField!
    @IBOutlet weak var btnClearShortcutPomodoro: NSButton!
    @IBOutlet weak var btnRecordShortcutPomodoro: NSButton!
    @IBOutlet weak var boxRecordShortcutPomodoro: NSBox!
    @IBOutlet weak var btnLearnPomodoroTechnique: underLineButton!
    @IBOutlet weak var lblDescriptionPomodoro: NSTextField!

    @IBOutlet weak var lblTitleWorkToBreakRatio: NSTextField!
    @IBOutlet weak var lblDescriptionWorkToBreakRatio: NSTextField!
    
    var hardCorePomodoroEnabledText = "Hardcore Pomodoro mode enabled to focus on <FOCUSTYPE> for <COUNT> on <DAYS>."
    var hardCorePomodoroNotEnabledText = "Hardcore Pomodoro mode not enabled."
    var automaticPomodoroNotEnabledText = "Automatic Pomodoro mode is disabled."
    var isAddingPomodoroShortcut = false
    var borderPomodoroShortcutNormalColor = NSColor.gray
    var workDurationEmptyErrorText = "Work Duration can not be empty."
    var workDurationZeroErrorText = "Work Duration can not be 0."
    var breakDurationEmptyErrorText = "Break Duration can not be empty."
    var breakDurationZeroErrorText = "Break Duration can not be 0."
    
    let pomodoroItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    
    let superPomodoroItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    var pomodoroPreferencesAdvancedVcObj:pomodoroPreferencesAdvancedVc?
    var descriptionWorkToBreakRatio = "For every <WORKRATIO> minutes you focus, you will have a <BREAKRATIO> minutes break."
    //do not block "Super Distracting Sites" during breaks in super pomodoro
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
//        btnInfoBreakDuration.isHidden = false
        btnInfoPomodoroShortcut.isHidden = false
//        btnInfoPomodoroModeDuration.isHidden = false
        
        lblTitleWorkToBreakRatio.stringValue = "Work to break ratio:"
        lblDescriptionWorkToBreakRatio.stringValue = "For every 5 minutes you focus, you will have a 1 minutes break."
        lblTo.stringValue = "to"

        lblTitleShortcut.stringValue = "Shortcut to start focus session:"
        lblrecordShorcutPomodoro.stringValue = "Record Shortcut"
        lblDescriptionPomodoro.stringValue = "Pomodoro Mode cycles between deep work blocks where a focus mode is turned on (and distractions turned off) and break periods."
        btnLearnPomodoroTechnique.title = "Learn more about the pomodoro technique here."
        
        var pomodoroModeDurationText = "Pomodoro Mode duration"
        var minutesText = "minutes"
        var breakDurationText = "Break duration:"
    
        var checkBoxPomodoroText = "Enter Focus session after completing morning routine"
        var buttonAdvancedText = "Advanced..."

        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            checkBoxPomodoroText = preferencesInfo.value(forKey: "checkBoxPomodoroText") as? String ?? checkBoxPomodoroText
            pomodoroModeDurationText = preferencesInfo.value(forKey: "pomodoroModeDurationText") as? String ?? pomodoroModeDurationText
            minutesText = preferencesInfo.value(forKey: "minutesText") as? String ?? minutesText
            breakDurationText = preferencesInfo.value(forKey: "breakDurationText") as? String ?? breakDurationText
            hardCorePomodoroEnabledText = preferencesInfo.value(forKey: "hardCorePomodoroEnabledText") as? String ?? hardCorePomodoroEnabledText
            hardCorePomodoroNotEnabledText = preferencesInfo.value(forKey: "hardCorePomodoroNotEnabledText") as? String ?? hardCorePomodoroNotEnabledText
            automaticPomodoroNotEnabledText = preferencesInfo.value(forKey: "automaticPomodoroNotEnabledText") as? String ?? automaticPomodoroNotEnabledText
            
            lblDescriptionPomodoro.stringValue = preferencesInfo.value(forKey: "pomodoroDescriptionText") as? String ?? lblDescriptionPomodoro.stringValue
            btnLearnPomodoroTechnique.title = preferencesInfo.value(forKey: "buttonLearnPomodoroTechniqueText") as? String ?? btnLearnPomodoroTechnique.title
            lblTitleShortcut.stringValue = preferencesInfo.value(forKey: "titlePomodoroShortcut") as? String ?? lblTitleShortcut.stringValue
            lblrecordShorcutPomodoro.stringValue = preferencesInfo.value(forKey: "recordShorcutText") as? String ?? lblrecordShorcutPomodoro.stringValue
            
            workDurationEmptyErrorText = preferencesInfo.value(forKey: "workDurationEmptyErrorText") as? String ?? workDurationEmptyErrorText
            workDurationZeroErrorText = preferencesInfo.value(forKey: "workDurationZeroErrorText") as? String ?? workDurationZeroErrorText
            breakDurationEmptyErrorText = preferencesInfo.value(forKey: "breakDurationEmptyErrorText") as? String ?? breakDurationEmptyErrorText
            breakDurationZeroErrorText = preferencesInfo.value(forKey: "breakDurationZeroErrorText") as? String ?? breakDurationZeroErrorText
            buttonAdvancedText = preferencesInfo.value(forKey: "buttonAdvancedText") as? String ?? buttonAdvancedText
            
            
            lblTitleWorkToBreakRatio.stringValue = preferencesInfo.value(forKey: "titleWorkToBreakRatio") as? String ?? lblTitleWorkToBreakRatio.stringValue
            descriptionWorkToBreakRatio = preferencesInfo.value(forKey: "descriptionWorkToBreakRatio") as? String ?? descriptionWorkToBreakRatio
            lblTo.stringValue = preferencesInfo.value(forKey: "toText") as? String ?? lblTo.stringValue
            
        }
        
//        lblTitlePomodoroModeDuration.stringValue = pomodoroModeDurationText
//        lblTitleBreakDuration.stringValue = breakDurationText
//        lblMinutesPomodoro.stringValue = minutesText
//        lblMinutesBreak.stringValue = minutesText

//        textFieldPomodoroDuration.formatter = IntegerFormatter()
//        textFieldBreakDuration.formatter = IntegerFormatter()
        textFieldWorkRatio.formatter = IntegerFormatter()
        textFieldBreakRatio.formatter = IntegerFormatter()
        
//        textFieldPomodoroDuration.delegate = self
//        textFieldBreakDuration.delegate = self
        textFieldWorkRatio.delegate = self
        textFieldBreakRatio.delegate = self

        boxSuperPomodoro.addSubview(superPomodoroItemVcObj!.view)
        boxSuperPomodoro.addConstraints(subView: superPomodoroItemVcObj!.view)
        superPomodoroItemVcObj?.lblTitle.stringValue = buttonAdvancedText
        superPomodoroItemVcObj?.imgViewIcon.isHidden = true
        superPomodoroItemVcObj?.lblDescription.stringValue = ""
        superPomodoroItemVcObj?.delegate = self

        var pomodoro_AfterMorning = "Supercharge your morning routine! If you activate this feature, you will seamlessly transition into Pomodoro mode right after completing your morning routine, boosting your productivity to new heights."
        var pomodoro_DoNotBlockDistractingSites = "We actually recommend you turn this off because breaks are much better if you get away from the computer. You could go for a walk instead :) However, if you don’t feel like giving your brain a break, you can turn off blocking and enjoy unrestricted breaks where you can access all of those distracting sites."
        
        
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            pomodoro_AfterMorning = tooltips.value(forKey: "pomodoro_AfterMorning") as? String ?? pomodoro_AfterMorning
            pomodoro_DoNotBlockDistractingSites = tooltips.value(forKey: "pomodoro_DoNotBlockDistractingSites") as? String ?? pomodoro_DoNotBlockDistractingSites
        }
        
        boxPomodoro.addSubview(pomodoroItemVcObj!.view)
        boxPomodoro.addConstraints(subView: pomodoroItemVcObj!.view)
        pomodoroItemVcObj?.lblTitle.stringValue = checkBoxPomodoroText
        pomodoroItemVcObj?.btnSwitch.toolTip = checkBoxPomodoroText
        pomodoroItemVcObj?.lblSubTitle.isHidden = true
        pomodoroItemVcObj?.delegate = self
        pomodoroItemVcObj?.toolTip = pomodoro_AfterMorning
        
        lineBottomShortcutPomodoro.isHidden = true
        
        arrForSearchFromSettings.append(["title": checkBoxPomodoroText, "tabId": idPomodoro, "object": pomodoroItemVcObj!.bgBox as Any])
//        arrForSearchFromSettings.append(["title": pomodoroModeDurationText, "tabId": idPomodoro, "object": boxPomodoroModeDuration as Any])
        arrForSearchFromSettings.append(["title": lblTitleWorkToBreakRatio.stringValue, "tabId": idPomodoro, "object": boxWorkToBreakRatio as Any])
        arrForSearchFromSettings.append(["title": lblTitleShortcut.stringValue, "tabId": idPomodoro, "object": boxShortcutPomodoro as Any])
        
        
        var titleUseHardcorePomodoro = ""
        var titleSkipMicrobreaks = ""
        if let pomodoroPreferencesAdvancedInfo = configjson.value(forKey: "pomodoroPreferencesAdvancedInfo") as? NSDictionary{
            titleUseHardcorePomodoro = pomodoroPreferencesAdvancedInfo.value(forKey: "checkBoxUseHardcorePomodoroText") as? String ?? titleUseHardcorePomodoro
            titleSkipMicrobreaks = pomodoroPreferencesAdvancedInfo.value(forKey: "buttonSkipMicrobreaksText") as? String ?? titleSkipMicrobreaks
        }
        
        if pomodoroPreferencesAdvancedVcObj == nil{
            pomodoroPreferencesAdvancedVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroPreferencesAdvancedVc")) as? pomodoroPreferencesAdvancedVc
            pomodoroPreferencesAdvancedVcObj?.loadView()
        }
        arrForSearchFromSettings.append(["title": titleUseHardcorePomodoro, "tabId": "isSuperPomodoro", "object": pomodoroPreferencesAdvancedVcObj?.checkBoxUseHardcorePomodoro as Any])
        arrForSearchFromSettings.append(["title": titleSkipMicrobreaks, "tabId": "isSuperPomodoro", "object": pomodoroPreferencesAdvancedVcObj?.checkBoxSkipMicrobreaks as Any])
        
        boxPomodoroModeDuration.isHidden = true
    }
    
    override func viewWillAppear() {
        isAddingPomodoroShortcut = false
        boxRecordShortcutPomodoro.borderColor = borderPomodoroShortcutNormalColor
        reload_newShotShortcut()
        resetPomodoroModeState()

//        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
//            textFieldPomodoroDuration.stringValue = "\(duration)"
//        }
        
//        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakDurationMinutes) as? Int{
//            textFieldBreakDuration.stringValue = "\(duration)"
//        }
        var workRatio = 5
        var breakRatio = 1
        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro) as? Int{
            workRatio = ratio
            if workRatio <= 0{
                workRatio = 1
                UserDefaults.standard.set(workRatio, forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro)
            }
            textFieldWorkRatio.stringValue = "\(workRatio)"
        }
        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro) as? Int{
            breakRatio = ratio
            if breakRatio <= 0{
                breakRatio = 1
                UserDefaults.standard.set(breakRatio, forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro)
            }
            textFieldBreakRatio.stringValue = "\(breakRatio)"
        }
        var descriptionWorkToBreakRatio = descriptionWorkToBreakRatio
        descriptionWorkToBreakRatio = descriptionWorkToBreakRatio.replacingOccurrences(of: "<WORKRATIO>", with: "\(workRatio)")
        descriptionWorkToBreakRatio = descriptionWorkToBreakRatio.replacingOccurrences(of: "<BREAKRATIO>", with: "\(breakRatio)")
        lblDescriptionWorkToBreakRatio.stringValue = descriptionWorkToBreakRatio
        
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitle.stringValue = ""
            }else{
                lblTitle.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitle.stringValue = ""
        }
    }
    override func viewDidAppear() {
//        self.textFieldPomodoroDuration.window?.makeFirstResponder(nil)
    }
    override func viewWillDisappear() {
        resetCurrentRecording()
        isAddingPomodoroShortcut = false
    }
    @IBAction func btnRecordShortcutPomodoroClicked(_ sender: Any) {
        resetCurrentRecording()
        isAddingPomodoroShortcut = true
        lblrecordShorcutPomodoro.stringValue = ""
        btnClearShortcutPomodoro.isHidden = true
        boxRecordShortcutPomodoro.borderColor = NSColor.blue
        appdelegate?.unregisterPomodoroShortcut()
        flags = []
        char = ""
        self.view.window?.makeFirstResponder(nil)
    }
    
    @objc func resetCurrentRecording(){
        if isAddingPomodoroShortcut{
            reload_newShotShortcut()
            if flags.isEmpty == false{
                appdelegate?.registerPomodoroShortcut()
            }
        }
    }
    
    func resetPomodoroModeState(){
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool{
            if state{
                pomodoroItemVcObj?.btnSwitch.state = .on
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
                        superPomodoroItemVcObj?.lblDescription.stringValue = hardcorePomodoroEnabledText//"Hardcore Pomodoro mode enabled to focus on \(hardCorePomodoroFocusName) for \(hardCorePomodoroCount) on \(daysString)."//
                    }else{
                        superPomodoroItemVcObj?.lblDescription.stringValue = hardCorePomodoroNotEnabledText//"Hardcore Pomodoro mode not enabled."
                    }
                }
            }else{
                pomodoroItemVcObj?.btnSwitch.state = .off
                superPomodoroItemVcObj?.lblDescription.stringValue = automaticPomodoroNotEnabledText//"Automatic Pomodoro mode is disabled."//POMODORO MOD IS DISABLED."
            }
        }
    }
    
    @objc func reload_newShotShortcut(){
        char = ""
        flags = NSEvent.modifierFlags
        char = SettingsManagerObject.startPomodoroShortcutChar

        let sflags = SettingsManagerObject.startPomodoroShortcutFlags
        updateFlags(sflags: sflags)
        
        
        if flags.isEmpty == true && char == ""{
            lblrecordShorcutPomodoro.stringValue = "Record Shortcut"
            if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                lblrecordShorcutPomodoro.stringValue = preferencesInfo.value(forKey: "recordShorcutText") as? String ?? lblrecordShorcutPomodoro.stringValue
            }
            btnClearShortcutPomodoro.isHidden = true
        }else{
            lblrecordShorcutPomodoro.stringValue = "\(flags)\(char)"
            btnClearShortcutPomodoro.isHidden = false
        }
        boxRecordShortcutPomodoro.borderColor = borderPomodoroShortcutNormalColor
    }
    
    
    func shortcutAdded(){
        isAddingPomodoroShortcut  = false
        boxRecordShortcutPomodoro.borderColor = borderPomodoroShortcutNormalColor
        btnClearShortcutPomodoro.isHidden = false
    }
    @IBAction func btnClearShortcutPomodoroClicked(_ sender: Any) {
        flags = []
        char = ""
        appdelegate?.unregisterPomodoroShortcut()
        SettingsManagerObject.startPomodoroShortcutChar = ""
        SettingsManagerObject.startPomodoroShortcutFlags = []
        lblrecordShorcutPomodoro.stringValue = "Record Shortcut"
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            lblrecordShorcutPomodoro.stringValue = preferencesInfo.value(forKey: "recordShorcutText") as? String ?? lblrecordShorcutPomodoro.stringValue
        }
        btnClearShortcutPomodoro.isHidden = true
        boxRecordShortcutPomodoro.borderColor = borderPomodoroShortcutNormalColor
        SettingsManagerObject.isSettingsChanged = true
        
    }
    func showAlert(msg:String, completionHandler: @escaping(_ result: Bool) -> ()) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            
            completionHandler(true)
            return
        })
    }

    

    func showHardCorePomodoroSetting(){
        if pomodoroPreferencesAdvancedVcObj == nil{
            pomodoroPreferencesAdvancedVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroPreferencesAdvancedVc")) as? pomodoroPreferencesAdvancedVc
        }
        self.presentAsSheet(pomodoroPreferencesAdvancedVcObj!)
    }
    
    @IBAction func btnLearnPomodoroTechniqueClicked(_ sender: Any) {
        if let url = URL(string: "https://medium.com/@focusbearteam/studying-on-tomato-oclock-a-student-s-guide-to-using-the-pomodoro-technique-efficiently-9a037cc509be"){
            NSWorkspace.shared.open(url)
        }
    }
    
    
//    @IBAction func btnInfoPomodoroModeDurationClicked(_ sender: Any) {
//        var toolTip = "Normally pomodoro work blocks are 25 minutes long (with a 5 minute break) but you can customize it to a different time"
//        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
//            toolTip = tooltips.value(forKey: "pomodoro_PomodoroModeDuration") as? String ?? toolTip
//        }
//        showTooltip(sender: btnInfoPomodoroModeDuration, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
//    }
    
//    @IBAction func btnInfoBreakDurationClicked(_ sender: Any) {
//        var toolTip = "Normally pomodoro breaks are 5 minutes long but you can take a break on your terms! Customize the Break Duration to align with your preferred downtime interval, allowing you to recharge and refresh in a way that perfectly complements your unique work style and preferences."
//        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
//            toolTip = tooltips.value(forKey: "pomodoro_BreakDuration") as? String ?? toolTip
//        }
//        showTooltip(sender: btnInfoBreakDuration, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
//    }
    @IBAction func btnInfoPomodoroShortcutClicked(_ sender: Any) {
        var toolTip = "Instant focus mode! The default shortcut is (^⌥⌘P) but you can easily assign a personalized shortcut for immediate access to concentrated work sessions, providing you with seamless productivity whenever and wherever you need it most."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "pomodoro_Shortcut") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoPomodoroShortcut, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}

extension pomodoroSettingsVc: NSTextFieldDelegate{
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
//            if textfield == textFieldPomodoroDuration{
//                
//                if textFieldPomodoroDuration.stringValue.isEmpty{
//                    showAlert(msg: workDurationEmptyErrorText, completionHandler: {_ in
//                        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                            tabview.selectedTabViewItemIndex = preferencesSettingsIndex
//                        }
//                        if settingsSideBarVcObj != nil{
//                            settingsSideBarVcObj?.tblView.selectRowIndexes(IndexSet(integer: settingsSideBarVcObj?.pomodoroSettingsIndex ?? 6), byExtendingSelection: false)
//                        }
//                        
////                        self.tabView.selectTabViewItem(self.tabViewItemPomodoro)
//                        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
//                            self.textFieldPomodoroDuration.stringValue = "\(duration)"
//                        }
//                        textfield.setFocus()
//                    })
//                    return;
//                }
//                if textFieldPomodoroDuration.integerValue < 1{
//                    showAlert(msg: workDurationZeroErrorText, completionHandler: {_ in
//                        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                            tabview.selectedTabViewItemIndex = preferencesSettingsIndex
//                        }
//                        if settingsSideBarVcObj != nil{
//                            settingsSideBarVcObj?.tblView.selectRowIndexes(IndexSet(integer: settingsSideBarVcObj?.pomodoroSettingsIndex ?? 6), byExtendingSelection: false)
//                        }
////                        self.tabView.selectTabViewItem(self.tabViewItemPomodoro)
//                        if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
//                            self.textFieldPomodoroDuration.stringValue = "\(duration)"
//                        }
//                        textfield.setFocus()
//                    })
//                    return;
//                }
//                let count = textfield.integerValue
//                if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int{
//                    if count == oldCount{
//                        return;
//                    }
//                }
//                SettingsManagerObject.isSettingsChanged = true
//                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes)
//                allApiObject.capturePosthog(event: "settings-changed-pomodoro-duration", metadata: [:])//#490
//            }
//            else
            if textfield == textFieldWorkRatio{
                var count = textfield.integerValue
                if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro) as? Int{
                    if count == oldCount{
                        return;
                    }
                }
                if count <= 0{
                    count = 1
                }
                SettingsManagerObject.isSettingsChanged = true
                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro)
                allApiObject.capturePosthog(event: "settings-changed-pomodoro-work-ratio", metadata: [:])
                
                if pomodoroWindowControllerObj != nil{
                    if pomodoroWindowControllerObj!.window!.isVisible{
                        pomodoroVcObj?.updateWorkBreakRatio()
                        pomodoroVcObj?.updateBreakDuration()
                    }
                }
            }else if textfield == textFieldBreakRatio{
                var count = textfield.integerValue
                if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro) as? Int{
                    if count == oldCount{
                        return;
                    }
                }
                if count <= 0{
                    count = 1
                }
                SettingsManagerObject.isSettingsChanged = true
                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro)
                allApiObject.capturePosthog(event: "settings-changed-pomodoro-break-ratio", metadata: [:])
                
                if pomodoroWindowControllerObj != nil{
                    if pomodoroWindowControllerObj!.window!.isVisible{
                        pomodoroVcObj?.updateWorkBreakRatio()
                        pomodoroVcObj?.updateBreakDuration()
                    }
                }
            }
        }
    }
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldWorkRatio || textfield == textFieldBreakRatio{
                if textfield.integerValue < 1 || textfield.stringValue.isEmpty{
                    textfield.stringValue = "1"
                }
            }
            let workRatio = textFieldWorkRatio.stringValue
            let breakRatio = textFieldBreakRatio.stringValue
            
            var descriptionWorkToBreakRatio = descriptionWorkToBreakRatio
            descriptionWorkToBreakRatio = descriptionWorkToBreakRatio.replacingOccurrences(of: "<WORKRATIO>", with: "\(workRatio)")
            descriptionWorkToBreakRatio = descriptionWorkToBreakRatio.replacingOccurrences(of: "<BREAKRATIO>", with: "\(breakRatio)")
            lblDescriptionWorkToBreakRatio.stringValue = descriptionWorkToBreakRatio
        }
    }
}




extension pomodoroSettingsVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == pomodoroItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled)
                allApiObject.capturePosthog(event: "settings-changed-enable-pomodoro-after-morning-routine", metadata: [:])//#490//
                
                if let hardCorePomodoroState = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
                    if hardCorePomodoroState{
                        if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
                            let filterArr = arrFocusType.filter { $0["name"] as? String ?? "" == name}
                            if filterArr.count == 0{
                                let alert = NSAlert()
                                alert.setSharingType()
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
                allApiObject.capturePosthog(event: "settings-changed-disable-pomodoro-after-morning-routine", metadata: [:])//#490//
                UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled)
            }
            resetPomodoroModeState()
        }
    }
}

extension pomodoroSettingsVc: SettingListItemDelegate{
    func buttonClicked(object:settingListItemVc) {
        if object == superPomodoroItemVcObj{
            showHardCorePomodoroSetting()
        }
    }
}
