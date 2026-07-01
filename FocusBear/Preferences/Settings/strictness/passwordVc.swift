//
//  passwordVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/03/22.


import Cocoa

class passwordVc: NSViewController {
    @IBOutlet weak var lblTitleMain: NSTextField!
    @IBOutlet weak var checkBoxSkipEveningHabitAfterCutOff: NSButton!
    @IBOutlet weak var checkBoxQuitApp: NSButton!
    @IBOutlet weak var checkBoxStopPomodoro: NSButton!
    @IBOutlet weak var checkBoxAbortingShutoff: NSButton!
    @IBOutlet weak var checkBoxSkipEveningHabit: NSButton!
    @IBOutlet weak var checkBoxSkipMorningHabit: NSButton!
    @IBOutlet weak var checkBoxChangeSettings: NSButton!
    @IBOutlet weak var checkBoxUseRelaxFocusMode: NSButton!
    @IBOutlet weak var checkBoxCircumventingBlocks: NSButton!
    @IBOutlet weak var checkBoxOpenPreferencesAfterCutOff: NSButton!
    
    @IBOutlet weak var lblCheckBoxSkipEveningHabitAfterCutOff: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxQuitApp: NSTextField!
    @IBOutlet weak var lblCheckBoxStopPomodoro: NSTextField!
    @IBOutlet weak var lblCheckBoxAbortingShutoff: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipEveningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipMorningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxChangeSettings: NSTextField!
    @IBOutlet weak var lblCheckBoxUseRelaxFocusMode: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxCircumventingBlocks: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxOpenPreferencesAfterCutOff: ignoreMouseTextField!
    
    @IBOutlet weak var lblQuestionPassword: NSTextField!
    @IBOutlet weak var lblTitleAskPassword: NSTextField!
    @IBOutlet weak var btnDisablePassword: NSButton!
    @IBOutlet weak var lblConfirmPassword: NSTextField!
    @IBOutlet weak var lblNewPassword: NSTextField!
    @IBOutlet weak var lblPasswordState: NSTextField!
    @IBOutlet weak var lblInfo: NSTextField!
    @IBOutlet weak var btnChangePassword: NSButton!
    @IBOutlet weak var textFieldNewPassword: NSSecureTextField!
    @IBOutlet weak var textFieldConfirmPassword: NSSecureTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    @IBOutlet weak var btnInfoSetPassword: hoverInfoButton!
    
    @IBOutlet weak var btnInfoChangeSettings: hoverInfoButton!
    @IBOutlet weak var btnInfoSkipMorningHabit: hoverInfoButton!
    @IBOutlet weak var btnInfoSkipEveningHabit: hoverInfoButton!
    @IBOutlet weak var btnSkipEveningHabitAfterCutOff: hoverInfoButton!
    @IBOutlet weak var btnInfoAbortingShutoff: hoverInfoButton!
    @IBOutlet weak var btnInfoStopPomodoro: hoverInfoButton!
    @IBOutlet weak var btnInfoQuitApp: hoverInfoButton!
    @IBOutlet weak var btnInfoUseRelaxFocusMode: hoverInfoButton!
    @IBOutlet weak var btnInfoCircumventingBlocks: hoverInfoButton!
    
    @IBOutlet weak var btnInfoOpenPreferencesAfterCutOff: hoverInfoButton!
    
    
    
    let viewHeightDefault = 511
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleMain.stringValue = "Password"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitleMain.stringValue = settingsNew.value(forKey: "passwordSettingTitle") as? String ?? lblTitleMain.stringValue
        }
        lblCheckBoxUseRelaxFocusMode.stringValue = "Allow using relax focus mode"
        lblTitleAskPassword.stringValue = "Ask for password:"
        lblQuestionPassword.stringValue = "When do you want to require a password?"
       
        lblCheckBoxQuitApp.stringValue = "Quitting/deactivating app"
        lblCheckBoxStopPomodoro.stringValue = "Stopping Super pomodoro mode"
        lblCheckBoxAbortingShutoff.stringValue = "Aborting shutoff"
        lblCheckBoxSkipEveningHabit.stringValue = "Skipping evening routine"
        lblCheckBoxSkipMorningHabit.stringValue = "Skipping morning routine"
        lblCheckBoxChangeSettings.stringValue = "Changing settings"
        
        
        lblCheckBoxCircumventingBlocks.stringValue = "Changing settings that allow circumventing blocks"
        btnDisablePassword.title = "Disable Password"
        lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = "Skipping evening routine after cutoff time"
        
        lblCheckBoxOpenPreferencesAfterCutOff.stringValue = "Require password for opening Preferences after cutoff time"
        
        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{

            btnDisablePassword.title = passwordPreferencesInfo.value(forKey: "buttonDisablePasswordText") as? String ?? btnDisablePassword.title
            lblTitleAskPassword.stringValue = passwordPreferencesInfo.value(forKey: "titleAskPassword") as? String ?? lblTitleAskPassword.stringValue
            lblQuestionPassword.stringValue = passwordPreferencesInfo.value(forKey: "questionPassword") as? String ?? lblQuestionPassword.stringValue
            lblCheckBoxQuitApp.stringValue = passwordPreferencesInfo.value(forKey: "buttonQuitAppText") as? String ?? lblCheckBoxQuitApp.stringValue
            lblCheckBoxStopPomodoro.stringValue = passwordPreferencesInfo.value(forKey: "buttonStopPomodoroText") as? String ?? lblCheckBoxStopPomodoro.stringValue
            lblCheckBoxAbortingShutoff.stringValue = passwordPreferencesInfo.value(forKey: "buttonAbortingShutoffText") as? String ?? lblCheckBoxAbortingShutoff.stringValue
            lblCheckBoxSkipEveningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitText") as? String ?? lblCheckBoxSkipEveningHabit.stringValue
            lblCheckBoxSkipMorningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipMorningHabitText") as? String ?? lblCheckBoxSkipMorningHabit.stringValue
            lblCheckBoxChangeSettings.stringValue = passwordPreferencesInfo.value(forKey: "buttonChangeSettingsText") as? String ?? lblCheckBoxChangeSettings.stringValue
            lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitAfterCutOffText") as? String ?? lblCheckBoxSkipEveningHabitAfterCutOff.stringValue
            lblCheckBoxUseRelaxFocusMode.stringValue = passwordPreferencesInfo.value(forKey: "buttonUseRelaxFocusModeText") as? String ?? lblCheckBoxUseRelaxFocusMode.stringValue
            lblCheckBoxCircumventingBlocks.stringValue = passwordPreferencesInfo.value(forKey: "buttonCircumventingBlocksText") as? String ?? lblCheckBoxCircumventingBlocks.stringValue
            lblCheckBoxOpenPreferencesAfterCutOff.stringValue = passwordPreferencesInfo.value(forKey: "buttonOpenPreferencesAfterCutOffText") as? String ?? lblCheckBoxOpenPreferencesAfterCutOff.stringValue
        }
        

        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
            if let titleChangePassword = passwordPreferencesInfo.value(forKey: "titleChangePassword") as? String{
                arrForSearchFromSettings.append(["title": titleChangePassword, "tabId": idPassword, "object": lblTitle as Any])
            }
            if let titleSetPassword = passwordPreferencesInfo.value(forKey: "titleSetPassword") as? String{
                arrForSearchFromSettings.append(["title": titleSetPassword, "tabId": idPassword, "object": lblTitle as Any])
            }
            if let title = passwordPreferencesInfo.value(forKey: "titleAskPassword") as? String {
                arrForSearchFromSettings.append(["title": title, "tabId": idPassword, "object": lblTitleAskPassword as Any])
            }
        }
            
         
        
        checkBoxChangeSettings.toolTip = lblCheckBoxChangeSettings.stringValue
        checkBoxSkipMorningHabit.toolTip = lblCheckBoxSkipMorningHabit.stringValue
        checkBoxSkipEveningHabit.toolTip = lblCheckBoxSkipEveningHabit.stringValue
        checkBoxSkipEveningHabitAfterCutOff.toolTip = lblCheckBoxSkipEveningHabitAfterCutOff.stringValue
        checkBoxAbortingShutoff.toolTip = lblCheckBoxAbortingShutoff.stringValue
        checkBoxStopPomodoro.toolTip = lblCheckBoxStopPomodoro.stringValue
        checkBoxQuitApp.toolTip = lblCheckBoxQuitApp.stringValue
        checkBoxUseRelaxFocusMode.toolTip = lblCheckBoxUseRelaxFocusMode.stringValue
        checkBoxCircumventingBlocks.toolTip = lblCheckBoxCircumventingBlocks.stringValue
        
        checkBoxOpenPreferencesAfterCutOff.toolTip = lblCheckBoxOpenPreferencesAfterCutOff.stringValue

        setupPostponeCheckboxes()
    }

    // MARK: Postpone password checkboxes (separate from Skip) — added in code, just below the skip
    // rows. Local device settings, persisted to UserDefaults.
    private var checkBoxPostponeMorning: NSButton?
    private var checkBoxPostponeEvening: NSButton?
    private var checkBoxPostponeAfterCutOff: NSButton?

    private func setupPostponeCheckboxes() {
        // Walk up from a skip checkbox to its enclosing vertical stack.
        var v: NSView? = checkBoxSkipEveningHabitAfterCutOff
        var vstack: NSStackView?
        while let cur = v { if let s = cur as? NSStackView, s.orientation == .vertical { vstack = s; break }; v = cur.superview }
        guard let stack = vstack else { return }
        func make(_ title: String, _ action: Selector) -> NSButton {
            let cb = NSButton(checkboxWithTitle: title, target: self, action: action)
            cb.translatesAutoresizingMaskIntoConstraints = false
            return cb
        }
        let m = make("Postponing morning routine", #selector(checkBoxPostponeMorningClicked))
        let e = make("Postponing evening routine", #selector(checkBoxPostponeEveningClicked))
        let c = make("Postponing evening routine after cutoff time", #selector(checkBoxPostponeAfterCutOffClicked))
        checkBoxPostponeMorning = m; checkBoxPostponeEvening = e; checkBoxPostponeAfterCutOff = c
        for cb in [m, e, c] { stack.addArrangedSubview(cb) }
        refreshPostponeCheckboxStates()
    }

    private func refreshPostponeCheckboxStates() {
        checkBoxPostponeMorning?.state = SettingsManagerObject.isPasswordRequireInPostponeMorning ? .on : .off
        checkBoxPostponeEvening?.state = SettingsManagerObject.isPasswordRequireInPostponeEvening ? .on : .off
        checkBoxPostponeAfterCutOff?.state = SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff ? .on : .off
    }

    private func setPostpone(_ value: Bool, key: String, set: (Bool) -> Void) {
        SettingsManagerObject.isSettingsChanged = true
        set(value)
        UserDefaults.standard.set(value, forKey: key)
    }

    @objc private func checkBoxPostponeMorningClicked() {
        setPostpone(checkBoxPostponeMorning?.state == .on, key: SettingsManagerObject.kUserdefaultsPasswordRequireInPostponeMorning) { SettingsManagerObject.isPasswordRequireInPostponeMorning = $0 }
    }
    @objc private func checkBoxPostponeEveningClicked() {
        setPostpone(checkBoxPostponeEvening?.state == .on, key: SettingsManagerObject.kUserdefaultsPasswordRequireInPostponeEvening) { SettingsManagerObject.isPasswordRequireInPostponeEvening = $0 }
    }
    @objc private func checkBoxPostponeAfterCutOffClicked() {
        setPostpone(checkBoxPostponeAfterCutOff?.state == .on, key: SettingsManagerObject.kUserdefaultsPasswordRequireInPostponeEveningAfterCutOff) { SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff = $0 }
    }

    override func viewWillAppear() {
        if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
//            preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: (preferencesWindowControllerObj?.settingsTabDefaultWidthForBigFonts ?? 0) + (preferencesWindowControllerObj?.extraSpaceWidthInSettingsTab ?? 0), height: viewHeightDefault + (preferencesWindowControllerObj?.extraSpaceHeightInSettingsTab ?? 0)))
        }else{
//            preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: (preferencesWindowControllerObj?.settingsTabDefaultWidth ?? 0) + (preferencesWindowControllerObj?.extraSpaceWidthInSettingsTab ?? 0), height: viewHeightDefault + (preferencesWindowControllerObj?.extraSpaceHeightInSettingsTab ?? 0)))
        }
        resetView()
    }//your password has been disabled.
    //
    
    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here 
        btnChangePassword.title = btnChangePassword.title
    }
    
    func resetView(){
        textFieldNewPassword.stringValue = ""
        textFieldConfirmPassword.stringValue = ""
        lblNewPassword.stringValue = "New Password"
        lblConfirmPassword.stringValue = "Confirm Password"

        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
            lblTitle.stringValue = "Set Password"
            btnChangePassword.title = "Set Password"
            textFieldNewPassword.placeholderString = "New Password"
            textFieldConfirmPassword.placeholderString = "Confirm Password"
            lblPasswordState.stringValue = "You do not have a password set."
            
            btnDisablePassword.isHidden = true
            
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let titleSetPassword = passwordPreferencesInfo.value(forKey: "titleSetPassword") as? String{
                    lblTitle.stringValue = titleSetPassword
                }
                if let buttonSetPasswordText = passwordPreferencesInfo.value(forKey: "buttonSetPasswordText") as? String{
                    btnChangePassword.title = buttonSetPasswordText
                }
                if let newPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "newPasswordPlaceholderText") as? String{
                    textFieldNewPassword.placeholderString = newPasswordPlaceholderText
                    lblNewPassword.stringValue = newPasswordPlaceholderText
                }
                if let confirmPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "confirmPasswordPlaceholderText") as? String{
                    textFieldConfirmPassword.placeholderString = confirmPasswordPlaceholderText
                    lblConfirmPassword.stringValue = confirmPasswordPlaceholderText
                }
                if let passwordNotSetText = passwordPreferencesInfo.value(forKey: "passwordNotSetText") as? String{
                    lblPasswordState.stringValue = passwordNotSetText
                }
            }
            checkBoxQuitApp.isEnabled = false
            checkBoxStopPomodoro.isEnabled = false
            checkBoxAbortingShutoff.isEnabled = false
            checkBoxSkipEveningHabit.isEnabled = false
            checkBoxSkipMorningHabit.isEnabled = false
            checkBoxChangeSettings.isEnabled = false
            checkBoxSkipEveningHabitAfterCutOff.isEnabled = false
            checkBoxUseRelaxFocusMode.isEnabled = false
            checkBoxCircumventingBlocks.isEnabled = false
            checkBoxOpenPreferencesAfterCutOff.isEnabled = false
        }else{
            lblTitle.stringValue = "Change Password"
            btnChangePassword.title = "Change Password"
            textFieldNewPassword.placeholderString = "*****"
            textFieldConfirmPassword.placeholderString = "*****"
            lblPasswordState.stringValue = "You have an active password set."
            
            btnDisablePassword.isHidden = false
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let titleChangePassword = passwordPreferencesInfo.value(forKey: "titleChangePassword") as? String{
                    lblTitle.stringValue = titleChangePassword
                }
                if let buttonChangePasswordText = passwordPreferencesInfo.value(forKey: "buttonChangePasswordText") as? String{
                    btnChangePassword.title = buttonChangePasswordText
                }
                if let passwordSetText = passwordPreferencesInfo.value(forKey: "passwordSetText") as? String{
                    lblPasswordState.stringValue = passwordSetText
                }
                
                if let newPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "newPasswordPlaceholderText") as? String{
                    lblNewPassword.stringValue = newPasswordPlaceholderText
                }
                if let confirmPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "confirmPasswordPlaceholderText") as? String{
                    lblConfirmPassword.stringValue = confirmPasswordPlaceholderText
                }
                
            }
            checkBoxQuitApp.isEnabled = true
            checkBoxStopPomodoro.isEnabled = true
            checkBoxAbortingShutoff.isEnabled = true
            checkBoxSkipEveningHabit.isEnabled = true
            checkBoxSkipMorningHabit.isEnabled = true
            checkBoxChangeSettings.isEnabled = true
            checkBoxSkipEveningHabitAfterCutOff.isEnabled = true
            checkBoxUseRelaxFocusMode.isEnabled = true
            checkBoxCircumventingBlocks.isEnabled = true
            checkBoxOpenPreferencesAfterCutOff.isEnabled = true
        }
        
        
        
        if SettingsManagerObject.isPasswordRequireInChangeSettings{
            checkBoxChangeSettings.state = .on
        }else{
            checkBoxChangeSettings.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
            checkBoxCircumventingBlocks.state = .on
        }else{
            checkBoxCircumventingBlocks.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff{
            checkBoxOpenPreferencesAfterCutOff.state = .on
        }else{
            checkBoxOpenPreferencesAfterCutOff.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInSkipMorning{
            checkBoxSkipMorningHabit.state = .on
        }else{
            checkBoxSkipMorningHabit.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInSkipEvening{
            checkBoxSkipEveningHabit.state = .on
        }else{
            checkBoxSkipEveningHabit.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
            checkBoxSkipEveningHabitAfterCutOff.state = .on
        }else{
            checkBoxSkipEveningHabitAfterCutOff.state = .off
        }
        refreshPostponeCheckboxStates()
        
        if SettingsManagerObject.isPasswordRequireInAbortShutoff{
            checkBoxAbortingShutoff.state = .on
        }else{
            checkBoxAbortingShutoff.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInStopPomodoro{
            checkBoxStopPomodoro.state = .on
        }else{
            checkBoxStopPomodoro.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInQuitApp{
            checkBoxQuitApp.state = .on
        }else{
            checkBoxQuitApp.state = .off
        }
        if SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode{
            checkBoxUseRelaxFocusMode.state = .on
        }else{
            checkBoxUseRelaxFocusMode.state = .off
        }

    }
    
    
    @IBAction func checkBoxUseRelaxFocusModeClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxUseRelaxFocusMode.state == .on{
            SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode = true
            allApiObject.capturePosthog(event: "require-password-in-use-relax-focus-mode-enabled", metadata: [:])
        }else{
            SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode = false
            allApiObject.capturePosthog(event: "require-password-in-use-relax-focus-mode-disabled", metadata: [:])
        }
    }
    @IBAction func checkBoxQuitAppClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxQuitApp.state == .on{
            SettingsManagerObject.isPasswordRequireInQuitApp = true
            allApiObject.capturePosthog(event: "require-password-in-quitting-app-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInQuitApp = false
            allApiObject.capturePosthog(event: "require-password-in-quitting-app-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxStopPomodoroClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxStopPomodoro.state == .on{
            SettingsManagerObject.isPasswordRequireInStopPomodoro = true
            allApiObject.capturePosthog(event: "require-password-in-stop-pomodoro-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInStopPomodoro = false
            allApiObject.capturePosthog(event: "require-password-in-stop-pomodoro-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxAbortingShutoffClicked(_ sender: Any) {
        SettingsManagerObject.isPasswordRequireInAbortShutoff = true
        if checkBoxAbortingShutoff.state == .on{
            SettingsManagerObject.isPasswordRequireInAbortShutoff = true
            allApiObject.capturePosthog(event: "require-password-in-using-mac-late-at-night-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInAbortShutoff = false
            allApiObject.capturePosthog(event: "require-password-in-using-mac-late-at-night-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxSkipEveningHabitClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSkipEveningHabit.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipEvening = true
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipEvening = false
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-disabled", metadata: [:])//#490
        }
    }
    @IBAction func checkBoxSkipEveningHabitAfterCutOffClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSkipEveningHabitAfterCutOff.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff = true
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-after-cutoff-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff = false
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-after-cutoff-disabled", metadata: [:])//#490
        }
        
    }
    
    @IBAction func checkBoxSkipMorningHabitClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSkipMorningHabit.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipMorning = true
            allApiObject.capturePosthog(event: "require-password-in-skip-morning-routine-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipMorning = false
            allApiObject.capturePosthog(event: "require-password-in-skip-morning-routine-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxChangeSettingsClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxChangeSettings.state == .on{
            SettingsManagerObject.isPasswordRequireInChangeSettings = true
            allApiObject.capturePosthog(event: "require-password-in-change-settings-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInChangeSettings = false
            allApiObject.capturePosthog(event: "require-password-in-change-settings-disabled", metadata: [:])//#490
        }
    }
    
    
    @IBAction func checkBoxCircumventingBlocksClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxCircumventingBlocks.state == .on{
            SettingsManagerObject.isPasswordRequireInCircumventingBlocks = true
            allApiObject.capturePosthog(event: "require-password-in-allow-circumventing-blocks-enabled", metadata: [:])//#1015
        }else{
            SettingsManagerObject.isPasswordRequireInCircumventingBlocks = false
            allApiObject.capturePosthog(event: "require-password-in-allow-circumventing-blocks-disabled", metadata: [:])//#1015
        }
    }
    
    @IBAction func checkBoxOpenPreferencesAfterCutOffClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxOpenPreferencesAfterCutOff.state == .on{
            SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff = true
            allApiObject.capturePosthog(event: "require-password-in-preferences-after-cutoff-enabled", metadata: [:])//#1071
        }else{
            SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff = false
            allApiObject.capturePosthog(event: "require-password-in-preferences-after-cutoff-disabled", metadata: [:])//#1071
        }
    }
    
    
    
    @IBAction func btnDisablePasswordClicked(_ sender: Any) {
        
        var alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to disable your password?"
        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
            if let passwordDisableAskText = passwordPreferencesInfo.value(forKey: "passwordDisableAskText") as? String{
                alert.messageText = passwordDisableAskText
            }
        }
        alert.informativeText = ""
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        alert.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
                self.resetView()
                allApiObject.capturePosthog(event: "disable-password", metadata: [:])
                alert = NSAlert()
                alert.setSharingType()
                alert.messageText = "Your password has been disabled."
                if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                    if let passwordDisableDoneText = passwordPreferencesInfo.value(forKey: "passwordDisableDoneText") as? String{
                        alert.messageText = passwordDisableDoneText
                    }
                }
                alert.informativeText = ""
                alert.alertStyle = NSAlert.Style.warning
                alert.addButton(withTitle: buttonOkText)
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                        print("okclicked")
                        // self.txtFieldEmail.stringValue = ""
                    }
                })
            }
        })
    }
    
    @IBAction func btnChangePasswordClicked(_ sender: Any) {

        if textFieldNewPassword.stringValue.isEmpty{
            var passwordBlankAlertTitle = "Password cannot be blank."
            var passwordBlankAlertSubTitle = "Please enter a valid password."
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let title = passwordPreferencesInfo.value(forKey: "passwordBlankAlertTitle") as? String{
                    passwordBlankAlertTitle = title
                }
                if let title = passwordPreferencesInfo.value(forKey: "passwordBlankAlertSubTitle") as? String{
                    passwordBlankAlertSubTitle = title
                }
            }
            alertforvalidation(question: passwordBlankAlertTitle, text: passwordBlankAlertSubTitle)//
            return
        }
        if textFieldConfirmPassword.stringValue.isEmpty{
            var confirmPasswordBlankAlertTitle = "Confirm password cannot be blank."
            var confirmPasswordBlankAlertSubTitle = "Please enter a valid \"Confirm password\"."
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let title = passwordPreferencesInfo.value(forKey: "confirmPasswordBlankAlertTitle") as? String{
                    confirmPasswordBlankAlertTitle = title
                }
                if let title = passwordPreferencesInfo.value(forKey: "confirmPasswordBlankAlertSubTitle") as? String{
                    confirmPasswordBlankAlertSubTitle = title
                }
            }
            alertforvalidation(question: confirmPasswordBlankAlertTitle, text: confirmPasswordBlankAlertSubTitle)
            return
        }
        
        if textFieldNewPassword.stringValue == textFieldConfirmPassword.stringValue{
            let base64password = textFieldConfirmPassword.stringValue.toBase64()
            
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
                allApiObject.capturePosthog(event: "set-password", metadata: [:])
                var passwordSetAlertTitle = "Password successfully set."
                if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                    if let title = passwordPreferencesInfo.value(forKey: "passwordSetAlertTitle") as? String{
                        passwordSetAlertTitle = title
                    }
                }
                alertforvalidation(question: passwordSetAlertTitle, text: "")
            }else{
                allApiObject.capturePosthog(event: "change-password", metadata: [:])
                var passwordChagedAlertTitle = "Password successfully changed."
                if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                    if let title = passwordPreferencesInfo.value(forKey: "passwordChagedAlertTitle") as? String{
                        passwordChagedAlertTitle = title
                    }
                }
                alertforvalidation(question: passwordChagedAlertTitle, text: "")
            }
            
            UserDefaults.standard.set(base64password, forKey: SettingsManagerObject.kUserdefaultsAppPassword)
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
            
            resetView()
            
        }else{
            var passwordNotMatchAlertTitle = "Passwords do not match."
            var passwordNotMatchAlertSubTitle = "Confirm Password does not match with the main password. Please re enter."
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let title = passwordPreferencesInfo.value(forKey: "passwordNotMatchAlertTitle") as? String{
                    passwordNotMatchAlertTitle = title
                }
                if let title = passwordPreferencesInfo.value(forKey: "passwordNotMatchAlertSubTitle") as? String{
                    passwordNotMatchAlertSubTitle = title
                }
            }
            alertforvalidation(question: passwordNotMatchAlertTitle, text: passwordNotMatchAlertSubTitle)
            return
        }
    }
    func alertforvalidation(question: String, text: String) {
        let alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonOkText)

        alert.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                // self.txtFieldEmail.stringValue = ""
            }
        })
        
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showStrictnessView()
    }
    @IBAction func btnInfoSetPasswordClicked(_ sender: Any) {
        var toolTip = "Make sure that your account is secure! Click here to set a password, and remember to choose a strong and unique combination of characters for enhanced account protection."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SetPassword") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoSetPassword, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoChangeSettingsClicked(_ sender: Any) {
        var toolTip = "Secure adjustments! Tick this box to enforce password entry for setting changes, adding a secure barrier to prevent any unintended or unauthorized modifications."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_ChangeSettings") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoChangeSettings, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoSkipMorningHabitClicked(_ sender: Any) {
        var toolTip = "Password-protected mornings! Enable this setting to require a password when postponing or skipping your morning routine, ensuring that your choice is intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SkipMorningHabit") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoSkipMorningHabit, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoSkipEveningHabitClicked(_ sender: Any) {
        var toolTip = "Password-protected evenings! Enable this setting to require a password when postponing or skipping your evening routine, ensuring that your choice is intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SkipEveningHabit") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoSkipEveningHabit, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnSkipEveningHabitAfterCutOffClicked(_ sender: Any) {
        var toolTip = "Password shield for evenings! Select this option to enforce password entry when adjusting your evening routine after the cutoff time, this is just to make sure that your choice is intentional and securing the consistency of your nighttime habits."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SkipEveningHabitAfterCutOffTime") as? String ?? toolTip
        }
        showTooltip(sender: btnSkipEveningHabitAfterCutOff, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoAbortingShutoffClicked(_ sender: Any) {
        var toolTip = "Late-night access control! Tick this box to demand your password when using your computer late at night, offering secure and intentional access during nighttime hours."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_AbortingShutoff") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoAbortingShutoff, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoStopPomodoroClicked(_ sender: Any) {
        var toolTip = "Guard your focus zone! Activate this setting to require a password when stopping the Super Pomodoro mode."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_StopSuperPomodoro") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoStopPomodoro, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoQuitAppClicked(_ sender: Any) {
        var toolTip = "Secure goodbyes! Enable this setting to require a password when you decide to quit the Focus Bear, adding an extra layer of security to your intentional exits."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_QuitApp") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoQuitApp, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoUseRelaxFocusModeClicked(_ sender: Any) {
        var toolTip = "Browse freely with control! Enable this feature to require a password when allowing the use of Relax Focus mode, adding a security layer to your leisurely internet sessions."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_UseRelaxFocusMode") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoUseRelaxFocusMode, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    
    @IBAction func btnInfoCircumventingBlocksClicked(_ sender: Any) {
        var toolTip = "Some settings like \"Show Dock Icon\" and \"Restart after force quit\" can reduce the strictness of blocking. If you tick this box, it will prompt for a password if the setting is changed to the less strict version."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_CircumventingBlocks") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoCircumventingBlocks, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoOpenPreferencesAfterCutOffClicked(_ sender: Any) {
        var toolTip = lblCheckBoxOpenPreferencesAfterCutOff.stringValue
//        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
//            toolTip = tooltips.value(forKey: "strictness_Password_CircumventingBlocks") as? String ?? toolTip
//        }
        showTooltip(sender: btnInfoOpenPreferencesAfterCutOff, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}
