//
//  generalVc.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 09/02/22.

//

import Cocoa

class generalVc: NSViewController, NSTextFieldDelegate {

    //@IBOutlet weak var tabViewItemSetup: NSTabViewItem!
    @IBOutlet weak var tabViewItemUninstall: NSTabViewItem!
    @IBOutlet weak var tabViewItemAccount: NSTabViewItem!
    @IBOutlet weak var tabViewItemPassword: NSTabViewItem!
    @IBOutlet weak var tabViewItemBlockedUrls: NSTabViewItem!
    @IBOutlet weak var tabViewBlockedUrls: NSView!
    
    @IBOutlet weak var btnLearnPomodoroTechnique: underLineButton!
    
    @IBOutlet weak var lblDescriptionPomodoro: NSTextField!
    @IBOutlet weak var lblTitleAppMode: NSTextField!
    @IBOutlet weak var tabViewItemAdvanced: NSTabViewItem!
    @IBOutlet weak var tabViewItemGeneral: NSTabViewItem!
    @IBOutlet weak var tabViewItemPomodoro: NSTabViewItem!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var boxPopupWidth: NSLayoutConstraint!

    @IBOutlet weak var boxPopup: NSBox!
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
    
    
   
    @IBOutlet weak var checkBoxDockIcon: NSButton!
    @IBOutlet weak var lblCheckBoxDockIcon: NSTextField!
    @IBOutlet weak var lblTitleDockIcon: NSTextField!
    
    @IBOutlet weak var lblTitleSkipHabits: NSTextField!
    @IBOutlet weak var lblQuestionSkipHabit: NSTextField!
    @IBOutlet weak var radioButtonEasySkip: NSButton!
    @IBOutlet weak var radioButtonHardSkip: NSButton!
    @IBOutlet weak var lblradioButtonEasySkip: NSTextField!
    @IBOutlet weak var lblradioButtonHardSkip: NSTextField!
    
    @IBOutlet weak var lblDescriptionCuddlyBear: NSTextField!
    @IBOutlet weak var lblDescriptionGrizzlyBear: NSTextField!
    @IBOutlet weak var radioBtnGrizzlyBear: NSButton!
    @IBOutlet weak var radioBtnCuddlyBear: NSButton!
    
    
    
    @IBOutlet weak var lblTitleMeetingDetection: NSTextField!
    @IBOutlet weak var lblDescriptionMeetingDetection: NSTextField!
    @IBOutlet weak var lblCheckBoxMeetingDetection: NSTextField!
    
    @IBOutlet weak var checkBoxMeetingDetection: NSButton!
    
    @IBOutlet weak var lblCheckBoxShowMeetingDetectionPopup: NSTextField!
    
    @IBOutlet weak var checkBoxShowMeetingDetectionPopup: NSButton!
    
    
    @IBOutlet weak var lblTitleHideDock: NSTextField!
    @IBOutlet weak var lblDescriptionHideDock: NSTextField!
    @IBOutlet weak var lblCheckBoxHideDock: NSTextField!
    
    @IBOutlet weak var checkBoxHideDock: NSButton!
    
    
    var hardCorePomodoroEnabledText = "Hardcore Pomodoro mode enabled to focus on <FOCUSTYPE> for <COUNT> on <DAYS>."
    var hardCorePomodoroNotEnabledText = "Hardcore Pomodoro mode not enabled."
    var automaticPomodoroNotEnabledText = "Automatic Pomodoro mode is disabled."
   
    var workDurationEmptyErrorText = "Work Duration can not be empty."
    var workDurationZeroErrorText = "Work Duration can not be 0."
    var breakDurationEmptyErrorText = "Break Duration can not be empty."
    var breakDurationZeroErrorText = "Break Duration can not be 0."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabView.delegate = self
        
        
//        tabViewItemSetup.label = "Setup"//
//        if let setUpVcInfo = configjson.value(forKey: "setUpVcInfo") as? NSDictionary{
//            tabViewItemSetup.label = setUpVcInfo.value(forKey: "title") as? String ?? tabViewItemSetup.label
//        }
        
        var tabUninstallText = "Uninstall"
        var tabAccountsText = "Accounts"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            tabUninstallText = common.value(forKey: "tabUninstallText") as? String ?? tabUninstallText
            tabAccountsText = common.value(forKey: "tabAccountsText") as? String ?? tabAccountsText
        }
        tabViewItemAccount.label = tabAccountsText
        tabViewItemUninstall.label = tabUninstallText
        
        generalVcObj = self
        
        tabView.delegate = self
        tabViewItemPassword.label = "Password"
        tabViewItemBlockedUrls.label = "Blocked URLs"
        lblCheckBoxShowMeetingDetectionPopup.stringValue = "Automatically suggest starting \"Meetings\" focus mode"
        lblTitleHideDock.stringValue = "Hide dock:"
        lblDescriptionHideDock.stringValue = "Enable this to hide dock during allowed apps activities to minimize distractions. \"System Events\" permission will be required for this."
        lblCheckBoxHideDock.stringValue = "Hide dock during activities having allowed apps."
        
        
        
        lblTitleMeetingDetection.stringValue = "Meeting detection"
        lblDescriptionMeetingDetection.stringValue = "Enable meeting detection to automatically suggest starting \"Meetings\" focus mode when Focus Bear detects you are in a call."
        lblCheckBoxMeetingDetection.stringValue = "Enable meeting detection"
        
        
//        btnExportLogs.title = "Click here to export logs to share with Support Team."
        lblTitleSkipHabits.stringValue = "Skip Habits easiness:"
        lblQuestionSkipHabit.stringValue = "How easy do you want it to be to skip your habits?"
        lblradioButtonEasySkip.stringValue = "Really easy - I want to be able to skip habits/breaks in a hurry"
        lblradioButtonHardSkip.stringValue = "Make it hard to skip - otherwise I'll end up skipping habits + breaks most of the time"
        
        
        
        lblDescriptionPomodoro.stringValue = "Pomodoro Mode cycles between deep work blocks where a focus mode is turned on (and distractions turned off) and break periods."
        btnLearnPomodoroTechnique.title = "Learn more about the pomodoro technique here."
        
        
        lblTitleAppMode.stringValue = "Focus bear mode:"
        radioBtnCuddlyBear.title = "Cuddly Bear mode"
        lblDescriptionCuddlyBear.stringValue = "Cuddly Bear mode: kind and gentle - gives you the benefit of the doubt when you open a non-allowed URL. Lets you temporarily allow blocked URLs during a focus mode."
        
        radioBtnGrizzlyBear.title = "Grizzly Bear mode"
        lblDescriptionGrizzlyBear.stringValue = "Grizzly Bear mode: super strict - immediately block URLs that aren't allowed and don't let yourself allow them until the focus mode is over."
        //
        
        tabViewItemPomodoro.label = "Pomodoro"
        tabViewItemGeneral.label = "General"
        tabViewItemAdvanced.label = "Advanced"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            tabViewItemPomodoro.label = common.value(forKey: "tabPomodoroText") as? String ?? tabViewItemPomodoro.label
            tabViewItemGeneral.label = common.value(forKey: "tabGeneralText") as? String ?? tabViewItemGeneral.label
            tabViewItemAdvanced.label = common.value(forKey: "tabAdvancedText") as? String ?? tabViewItemAdvanced.label
            tabViewItemBlockedUrls.label = common.value(forKey: "tabBlockedURLsText") as? String ?? tabViewItemBlockedUrls.label
            tabViewItemPassword.label = common.value(forKey: "tabPasswordText") as? String ?? tabViewItemPassword.label
        }

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
        lblTitleDockIcon.stringValue = "Dock icon:"
        lblCheckBoxDockIcon.stringValue = "Show Dock icon"
        
        
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
            
            
            lblTitleAppMode.stringValue = preferencesInfo.value(forKey: "titleAppMode") as? String ?? lblTitleAppMode.stringValue
            radioBtnCuddlyBear.title = preferencesInfo.value(forKey: "checkBoxCuddlyBearText") as? String ?? radioBtnCuddlyBear.title
            lblDescriptionCuddlyBear.stringValue = preferencesInfo.value(forKey: "descriptionCuddlyBearText") as? String ?? lblDescriptionCuddlyBear.stringValue
            
            radioBtnGrizzlyBear.title = preferencesInfo.value(forKey: "checkBoxGrizzlyBearText") as? String ?? radioBtnGrizzlyBear.title
            lblDescriptionGrizzlyBear.stringValue = preferencesInfo.value(forKey: "descriptionGrizzlyBearText") as? String ?? lblDescriptionGrizzlyBear.stringValue
            
            
            lblDescriptionPomodoro.stringValue = preferencesInfo.value(forKey: "pomodoroDescriptionText") as? String ?? lblDescriptionPomodoro.stringValue
            btnLearnPomodoroTechnique.title = preferencesInfo.value(forKey: "buttonLearnPomodoroTechniqueText") as? String ?? btnLearnPomodoroTechnique.title

            
            lblTitleDockIcon.stringValue = preferencesInfo.value(forKey: "titleDockIcon") as? String ?? lblTitleDockIcon.stringValue
            lblCheckBoxDockIcon.stringValue = preferencesInfo.value(forKey: "checkBoxShowDockIconText") as? String ?? lblCheckBoxDockIcon.stringValue
            
            
            lblTitleSkipHabits.stringValue = preferencesInfo.value(forKey: "titleSkipHabits") as? String ?? lblTitleSkipHabits.stringValue
            lblQuestionSkipHabit.stringValue = preferencesInfo.value(forKey: "questionSkipHabitText") as? String ?? lblQuestionSkipHabit.stringValue
            lblradioButtonEasySkip.stringValue = preferencesInfo.value(forKey: "radioButtonEasySkipText") as? String ?? lblradioButtonEasySkip.stringValue
            lblradioButtonHardSkip.stringValue = preferencesInfo.value(forKey: "radioButtonHardSkipText") as? String ?? lblradioButtonHardSkip.stringValue
            
//            btnExportLogs.title = preferencesInfo.value(forKey: "buttonExportLogsText") as? String ?? btnExportLogs.title
            
            lblTitleMeetingDetection.stringValue = preferencesInfo.value(forKey: "titleMeetingDetection") as? String ?? lblTitleMeetingDetection.stringValue
            lblDescriptionMeetingDetection.stringValue = preferencesInfo.value(forKey: "descriptionMeetingDetectionText") as? String ?? lblDescriptionMeetingDetection.stringValue
            lblCheckBoxMeetingDetection.stringValue = preferencesInfo.value(forKey: "checkBoxMeetingDetectionText") as? String ?? lblCheckBoxMeetingDetection.stringValue
            
            
            lblTitleHideDock.stringValue = preferencesInfo.value(forKey: "titleHideDock") as? String ?? lblTitleHideDock.stringValue
            lblDescriptionHideDock.stringValue = preferencesInfo.value(forKey: "descriptionHideDockText") as? String ?? lblDescriptionHideDock.stringValue
            lblCheckBoxHideDock.stringValue = preferencesInfo.value(forKey: "checkBoxHideDockText") as? String ?? lblCheckBoxHideDock.stringValue
            
            lblCheckBoxShowMeetingDetectionPopup.stringValue = preferencesInfo.value(forKey: "checkBoxShowMeetingDetectionPopupText") as? String ?? lblCheckBoxShowMeetingDetectionPopup.stringValue
            
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
//        btnAdvancedMain.title = buttonAdvancedText
        textFieldPomodoroDuration.formatter = IntegerFormatter()
        textFieldBreakDuration.formatter = IntegerFormatter()
        
        textFieldPomodoroDuration.delegate = self
        textFieldBreakDuration.delegate = self
        

        if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
            lblVersion.stringValue = versionText + " " + version + "." + build
        }else{
            lblVersion.stringValue = ""
        }
        
        self.tabViewBlockedUrls.addSubview(getBlockedUrlsVcObject().view)
        self.tabViewBlockedUrls.addConstraints(subView: getBlockedUrlsVcObject().view)
        
        self.tabViewItemPassword.view?.addSubview(getPasswordVcObject().view)
        self.tabViewItemPassword.view?.addConstraints(subView: getPasswordVcObject().view)
        
        
//        self.tabViewItemSetup.view?.addSubview(getSetUpVcObject().view)
//        self.tabViewItemSetup.view?.addConstraints(subView: getSetUpVcObject().view)
        
        
        self.tabViewItemAccount.view?.addSubview(getAccountVcObject().view)
        self.tabViewItemAccount.view?.addConstraints(subView: getAccountVcObject().view)
        
        self.tabViewItemUninstall.view?.addSubview(getUninstallVcObject().view)
        self.tabViewItemUninstall.view?.addConstraints(subView: getUninstallVcObject().view)
        
        
    }
    
        // Ask for password:
        // Quitting app
        // Aborting shutoff
        // Stopping Super pomodoro mode
    
    override func viewWillAppear() {
//        if currentLanguageCode == "es"{
//            boxPopupWidth.constant = 380
//        }else{
//            boxPopupWidth.constant = 280
//        }
//        boxPopup.isHidden = true
//        BoxBlackLayerForPopup.isHidden = true
        
        if isPurchased == false && daysLeft <= 0{
            self.tabView.selectTabViewItem(tabViewItemAccount)
        }
        
        if SettingsManagerObject.isSoundEnabled{
            checkBoxSound.state = .on
        }else{
            checkBoxSound.state = .off
        }
        
        if SettingsManagerObject.isCuddlyModeEnabled{
            radioBtnCuddlyBear.state = .on
            radioBtnGrizzlyBear.state = .off
        }else{
            radioBtnCuddlyBear.state = .off
            radioBtnGrizzlyBear.state = .on
        }
        
        
        resetPomodoroModeState()
        
        if SettingsManagerObject.kIsReducedMotion{
            checkBoxReduceMotion.state = .on
        }else{
            checkBoxReduceMotion.state = .off
        }
        
        if SettingsManagerObject.isMeetingDetectionEnabled{
            checkBoxMeetingDetection.state = .on
            checkBoxShowMeetingDetectionPopup.isEnabled = true
        }else{
            checkBoxMeetingDetection.state = .off
            checkBoxShowMeetingDetectionPopup.isEnabled = false
        }
        
        if SettingsManagerObject.showMeetingDetectionAlert{
            checkBoxShowMeetingDetectionPopup.state = .on
        }else{
            checkBoxShowMeetingDetectionPopup.state = .off
        }
        
        if SettingsManagerObject.isHideDockInActivity{
            checkBoxHideDock.state = .on
        }else{
            checkBoxHideDock.state = .off
        }
        
        
        if SettingsManagerObject.isPromptToRememberHabit{
            checkBoxPromptToAskNextHabit.state = .on
        }else{
            checkBoxPromptToAskNextHabit.state = .off
        }
        if SettingsManagerObject.isEasySkipEnabled{
            radioButtonEasySkip.state = .on
            radioButtonHardSkip.state = .off
        }else{
            radioButtonEasySkip.state = .off
            radioButtonHardSkip.state = .on
        }
        
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
        
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
            if state{
                checkBoxDockIcon.state = .on
            }else{
                checkBoxDockIcon.state = .off
            }
        }
    }
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
    override func viewDidAppear() {
        self.textFieldPomodoroDuration.window?.makeFirstResponder(nil)
        
        if Reachability.isConnectedToNetwork() == false {
            
            allApiObject.isInternetOn(completionHandler: {isInternetOn in
                DispatchQueue.main.async {
                    if !isInternetOn{
                        if self.view.window != nil{
                            showAlertNoInternet(window: self.view.window!)
                        }
                    }
                }
            })
            
        }
        
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            if self.tabView.selectedTabViewItem == tabViewItemPassword{
                if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                    if !SettingsManagerObject.isPasswordRequireInChangeSettings{
                        tabview.view.addSubview(enterPasswordVcObj!.view)
                        tabview.view.addConstraints(subView: enterPasswordVcObj!.view)
                        enterPasswordVcObj?.parentVc = nil
                        addLog(text: "Showing enter password view inside preferences")
                    }
                }
            }
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
            allApiObject.capturePosthog(event: "settings-changed-disable-app-screenshots", metadata: [:])//#490/
        }else{
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots)
            for win in windows{
                print(win)
                win.sharingType = .readOnly
            }
            allApiObject.capturePosthog(event: "settings-changed-enable-app-screenshots", metadata: [:])//#490
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
                            tabview.selectedTabViewItemIndex = 3
                        }
                        self.tabView.selectTabViewItem(self.tabViewItemPomodoro)
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
                            tabview.selectedTabViewItemIndex = 3
                        }
                        self.tabView.selectTabViewItem(self.tabViewItemPomodoro)
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
                allApiObject.capturePosthog(event: "settings-changed-pomodoro-duration", metadata: [:])//#490
            }else if textfield == textFieldBreakDuration{
                if textFieldBreakDuration.stringValue.isEmpty{
                    showAlert(msg: breakDurationEmptyErrorText, completionHandler: {_ in
                        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                            tabview.selectedTabViewItemIndex = 3
                        }
                        self.tabView.selectTabViewItem(self.tabViewItemPomodoro)
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
                            tabview.selectedTabViewItemIndex = 3
                        }
                        self.tabView.selectTabViewItem(self.tabViewItemPomodoro)
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
                allApiObject.capturePosthog(event: "settings-changed-pomodoro-break-duration", metadata: [:])//#490
            }
        }
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
        alert.setSharingType()
        var alertChangeLanguageMessageText = "Are you sure you want to change the language to <LANGUAGE>?"
        var alertChangeLanguageInfoText = "Focus Bear will restart for the changes to take effect."
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            alertChangeLanguageMessageText = preferencesInfo.value(forKey: "alertChangeLanguageMessageText") as? String ?? alertChangeLanguageMessageText
            alertChangeLanguageInfoText = preferencesInfo.value(forKey: "alertChangeLanguageInfoText") as? String ?? alertChangeLanguageInfoText
        }
        alertChangeLanguageMessageText = alertChangeLanguageMessageText.replacingOccurrences(of: "<LANGUAGE>", with: popUpBtnselectLanguage.title)
        alert.messageText = alertChangeLanguageMessageText
        alert.informativeText = alertChangeLanguageInfoText
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                

                addLog(text: "language changed by user to \(self.popUpBtnselectLanguage.title)")
                UserDefaults.standard.set(arrLanguageDic[self.popUpBtnselectLanguage.indexOfSelectedItem]["id"], forKey: kUserdefaultsSelectedLanguage)
                
                
                var languageName = arrLanguageDic[self.popUpBtnselectLanguage.indexOfSelectedItem]["languageName"] ?? ""
                languageName = languageName.lowercased()
                
                self.view.window?.close()
                
                
                allApiObject.capturePosthog(event: "settings-changed-language", metadata: ["language":languageName])//#490//
                DispatchQueue.global().async {
                    sleep(1)
                    DispatchQueue.main.async {
                        appdelegate?.quitAndRestartApp()
                    }
                }
                
                
                
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
    @IBAction func checkBoxSoundClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSound.state == .on{
            SettingsManagerObject.isSoundEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-sound-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isSoundEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-sound-disabled", metadata: [:])//#490
        }
    }

    @IBAction func radioBtnCuddlyBearClicked(_ sender: Any) {
        if SettingsManagerObject.isCuddlyModeEnabled == true{
            return;
        }
        SettingsManagerObject.isSettingsChanged = true
        radioBtnGrizzlyBear.state = .off
        SettingsManagerObject.isCuddlyModeEnabled = true
        allApiObject.capturePosthog(event: "settings-changed-focus-bear-mode-cuddly", metadata: [:])//#490
    }
    
    @IBAction func radioBtnGrizzlyBearClicked(_ sender: Any) {
        if SettingsManagerObject.isCuddlyModeEnabled == false{
            return;
        }
        SettingsManagerObject.isSettingsChanged = true
        radioBtnCuddlyBear.state = .off
        SettingsManagerObject.isCuddlyModeEnabled = false
        allApiObject.capturePosthog(event: "settings-changed-focus-bear-mode-grizzly", metadata: [:])//#490
        
        let alert = NSAlert()
        alert.setSharingType()
        var warningText = "Warning: Grizzly Bear mode is not recommended until you have fully fleshed out your focus modes. We recommend starting with cuddly bear mode and switching to Grizzly Bear mode after a few weeks"
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            warningText = preferencesInfo.value(forKey: "warningGrizzlyBearText") as? String ?? warningText
        }
        
        alert.messageText = warningText
        alert.addButton(withTitle: buttonOkText)
        
        if self.view.window != nil{
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    
                }
            })
        }
    }
    
    @IBAction func checkBoxReduceMotionClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxReduceMotion.state == .on{
            SettingsManagerObject.kIsReducedMotion = true
            allApiObject.capturePosthog(event: "settings-changed-enable-reduce-motion", metadata: [:])//#490
        }else{
            SettingsManagerObject.kIsReducedMotion = false
            allApiObject.capturePosthog(event: "settings-changed-disable-reduce-motion", metadata: [:])//#490
        }
        
    }
    
    @IBAction func checkBoxMeetingDetectionClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxMeetingDetection.state == .on{
            checkBoxShowMeetingDetectionPopup.isEnabled = true
            SettingsManagerObject.isMeetingDetectionEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-enable-meeting-detection", metadata: [:])//#490
        }else{
            checkBoxShowMeetingDetectionPopup.isEnabled = false
            SettingsManagerObject.isMeetingDetectionEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-disable-meeting-detection", metadata: [:])//#490
        }
    }
    @IBAction func checkBoxShowMeetingDetectionPopupClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxShowMeetingDetectionPopup.state == .on{
            SettingsManagerObject.showMeetingDetectionAlert = true
            allApiObject.capturePosthog(event: "settings-changed-enable-meeting-popup", metadata: [:])//#490
        }else{
            SettingsManagerObject.showMeetingDetectionAlert = false
            allApiObject.capturePosthog(event: "settings-changed-disable-meeting-popup", metadata: [:])//#490
        }
        
        
    }
    
    @IBAction func checkBoxHideDockClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxHideDock.state == .on{
            SettingsManagerObject.isHideDockInActivity = true
            let _ = checkDocBarState()
            allApiObject.capturePosthog(event: "settings-changed-hide-dock-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isHideDockInActivity = false
            allApiObject.capturePosthog(event: "settings-changed-hide-dock-disabled", metadata: [:])//#490
        }
        
    }
    @IBAction func checkBoxPromptToAskNextHabitClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxPromptToAskNextHabit.state == .on{
//            UserDefaults.standard.set(true, forKey: kUserdefaultsPromptToRememberHabit)
            SettingsManagerObject.isPromptToRememberHabit = true
            allApiObject.capturePosthog(event: "settings-changed-enable-next-habit-reminder", metadata: [:])//#490
        }else{
//            UserDefaults.standard.set(false, forKey: kUserdefaultsPromptToRememberHabit)
            SettingsManagerObject.isPromptToRememberHabit = false
            allApiObject.capturePosthog(event: "settings-changed-disable-next-habit-reminder", metadata: [:])//#490
        }
    }
    var pomodoroPreferencesAdvancedVcObj:pomodoroPreferencesAdvancedVc?
    @IBAction func btnAdvancedPmodoroModeClicked(_ sender: Any) {
        showHardCorePomodoroSetting()
    }
    
    @IBAction func btnAdvanceMainClicked(_ sender: Any) {
        if boxPopup.isHidden == true{
            allApiObject.capturePosthog(event: "open-advanced-general-preferences", metadata: [:])
            boxPopup.isHidden = false
//            BoxBlackLayerForPopup.isHidden = false
        }
    }
    
    func showHardCorePomodoroSetting(){
        if pomodoroPreferencesAdvancedVcObj == nil{
            pomodoroPreferencesAdvancedVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroPreferencesAdvancedVc")) as? pomodoroPreferencesAdvancedVc
        }
        self.presentAsSheet(pomodoroPreferencesAdvancedVcObj!)
    }
    
    /*
     let url = URL(fileURLWithPath: "/Users/prashant/Library/Application Support/com.App.EarnYourScreentime/Logs")
     let destUrl = URL(fileURLWithPath: "/Users/prashant/Library/Application Support/com.App.EarnYourScreentime/Logs.zip")
     do{
        try url.zip(dest: destUrl)
     }catch{
         
     }
     */
//    @IBAction func btnExportLogsClicked(_ sender: Any) {
//        let openPanel = NSOpenPanel()
//        openPanel.canChooseFiles = false
//        openPanel.canChooseDirectories = true
//        openPanel.allowsMultipleSelection = false
//        openPanel.treatsFilePackagesAsDirectories = false
//        openPanel.prompt = "Export Logs"
//        openPanel.message = "Export logs to share with Focus Bear Support Team"
//        
//        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
//            openPanel.prompt = preferencesInfo.value(forKey: "buttonPanelExportLogsText") as? String ?? openPanel.prompt
//            openPanel.message = preferencesInfo.value(forKey: "panelExportLogsText") as? String ?? openPanel.message
//        }
//        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
//            if state{
//                openPanel.sharingType = .none
//            }
//        }
//    
//        
//        openPanel.beginSheetModal(for: self.view.window!) { response in
//            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
//                return
//            }
//            if let url = openPanel.url {
//                let filemanager = FileManager.default
//                let destUrl = url.appendingPathComponent("FocusBearLogs.zip")
//                if filemanager.fileExists(atPath: destUrl.path){
//                    do{
//                        try filemanager.removeItem(at: destUrl)
//                    }catch{
//                        print(error)
//                    }
//                }
//                //FocusBearLogs.zip
//
//     
//                do{
//                    _ = try DebugLogsFolderURL!.zip(dest: destUrl)
//                }catch{
//                    
//                }
//                
//                
//                var successText = "Your logs are available to share in the FocusBearLogs.zip file in the <URL> directory"
//                if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
//                    successText = preferencesInfo.value(forKey: "exportSuccessText") as? String ?? successText
//                }
//                
//                successText = successText.replacingOccurrences(of: "<URL>", with: url.path)
//                
//                self.showAlert(msg: successText, completionHandler: {_ in
//                    NSWorkspace.shared.activateFileViewerSelecting([destUrl])
//                })
//                
//                allApiObject.capturePosthog(event: "export-logs", metadata: [:])
//                
//            }
//        }
//    }
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
                
                
                let destUrl = url.appendingPathComponent("Focus Bear Data")
                if filemanager.fileExists(atPath: destUrl.path){
                    do{
                        try filemanager.removeItem(at: destUrl)
                    }catch{
                        print(error)
                    }
                }
                
                do{
                    try filemanager.createDirectory(at: destUrl, withIntermediateDirectories: false)

                    
                    // stats
                    let destCsvUrl = destUrl.appendingPathComponent("Stats.csv")
                    do{
                        try FileManager.default.copyItem(at: quantityCsvURL, to: destCsvUrl)
                    }catch{
                        print(error)
                    }
                    
                    
                    // settings
                    
                    let destSettingsUrl = destUrl.appendingPathComponent("Habit settings.json")
                    var jsonString = ""
                    if let text = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
                        jsonString = text
                    }
                    if let data = jsonString.data(using: String.Encoding.utf8) {
                        do{
                        try data.write(to: destSettingsUrl)
                        }catch{
                            print(error)
                        }
                    }
                    
                    //Preferences
                    
                    var preferencesJSon = SettingsManagerObject.getLocalJsonToUpload()
                    preferencesJSon.removeValue(forKey: "kAppPassword")
                    let destPreferencessUrl = destUrl.appendingPathComponent("Preferences.json")
                    
                    let data = try JSONSerialization.data(withJSONObject: preferencesJSon, options: .init(rawValue: 0))
                    do{
                        try data.write(to: destPreferencessUrl)
                    }catch{
                        print(error)
                    }
                    
                
                    //
                    
                    
                    //focus modes
                    
                    let focusJSon = arrFocusType
                    let destFocusJsonUrl = destUrl.appendingPathComponent("Focus Mode settings.json")
                    
                    let focusData = try JSONSerialization.data(withJSONObject: focusJSon, options: .init(rawValue: 0))
                    do{
                        try focusData.write(to: destFocusJsonUrl)
                    }catch{
                        print(error)
                    }
                    //
                    
                    
                    
                    allApiObject.capturePosthog(event: "export-data", metadata: [:])
                    
                }catch{
                    
                }
                
                
            }
        }
    }
    @IBAction func btnCheckForUpdatesClicked(_ sender: Any) {
        addLog(text: "btnCheckForUpdatesClicked")//
        appdelegate!.updater?.checkForUpdates(self)
        preferencesWindowControllerObj?.window?.miniaturize(self)
        allApiObject.capturePosthog(event: "check-for-updates-manually", metadata: [:])
    }
    @IBAction func btnBlackLayerClicked(_ sender: Any) {
        boxPopup.isHidden = true
//        BoxBlackLayerForPopup.isHidden = true
    }
    @IBAction func btnLearnPomodoroTechniqueClicked(_ sender: Any) {
        if let url = URL(string: "https://medium.com/@focusbearteam/studying-on-tomato-oclock-a-student-s-guide-to-using-the-pomodoro-technique-efficiently-9a037cc509be"){
            NSWorkspace.shared.open(url)
        }
    }
    @IBAction func checkBoxDockIconClicked(_ sender: Any) {//will not sync it
        if checkBoxDockIcon.state == .on{
            UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
            allApiObject.capturePosthog(event: "settings-changed-show-dock-icon", metadata: [:])//#490
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsShowDockIcon)
            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
            NSApplication.shared.activate(ignoringOtherApps: true)
            allApiObject.capturePosthog(event: "settings-changed-hide-dock-icon", metadata: [:])//#490
        }
    }
    @IBAction func radioBtnEasySkipClick(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isEasySkipEnabled = true
        radioButtonHardSkip.state = .off
        allApiObject.capturePosthog(event: "settings-changed-friction-for-skipping-easy", metadata: [:])//#490
    }
    
    @IBAction func radioBtnHardSkipClick(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isEasySkipEnabled = false
        radioButtonEasySkip.state = .off
        allApiObject.capturePosthog(event: "settings-changed-friction-for-skipping-hard", metadata: [:])//#490
    }
    
}


extension generalVc:NSTabViewDelegate{
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        print("tab view selection change")
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            if tabViewItem == tabViewItemPassword{
                if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                    if !SettingsManagerObject.isPasswordRequireInChangeSettings{
                        tabview.view.addSubview(enterPasswordVcObj!.view)
                        tabview.view.addConstraints(subView: enterPasswordVcObj!.view)
                        enterPasswordVcObj?.parentVc = nil
                        addLog(text: "Showing enter password view inside preferences")
                    }
                }
            }
        }
    }

    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if isPurchased == false && daysLeft <= 0{
            if tabViewItem != tabViewItemAccount && tabViewItem != tabViewItemUninstall{
                return false
            }
        }
        return true
    }
}

