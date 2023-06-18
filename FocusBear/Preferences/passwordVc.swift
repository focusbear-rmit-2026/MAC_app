//
//  passwordVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/03/22.


import Cocoa

class passwordVc: NSViewController {

    @IBOutlet weak var checkBoxSkipEveningHabitAfterCutOff: NSButton!
    @IBOutlet weak var checkBoxQuitApp: NSButton!
    @IBOutlet weak var checkBoxStopPomodoro: NSButton!
    @IBOutlet weak var checkBoxAbortingShutoff: NSButton!
    @IBOutlet weak var checkBoxSkipEveningHabit: NSButton!
    @IBOutlet weak var checkBoxSkipMorningHabit: NSButton!
    @IBOutlet weak var checkBoxChangeSettings: NSButton!
    
    @IBOutlet weak var lblCheckBoxSkipEveningHabitAfterCutOff: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxQuitApp: NSTextField!
    @IBOutlet weak var lblCheckBoxStopPomodoro: NSTextField!
    @IBOutlet weak var lblCheckBoxAbortingShutoff: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipEveningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipMorningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxChangeSettings: NSTextField!
    
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleAskPassword.stringValue = "Ask for password:"
        lblQuestionPassword.stringValue = "When do you want to require a password?"
       
        lblCheckBoxQuitApp.stringValue = "Quitting app"
        lblCheckBoxStopPomodoro.stringValue = "Stopping Super pomodoro mode"
        lblCheckBoxAbortingShutoff.stringValue = "Aborting shutoff"
        lblCheckBoxSkipEveningHabit.stringValue = "Postponing/skipping evening routine"
        lblCheckBoxSkipMorningHabit.stringValue = "Postponing/skipping morning routine"
        lblCheckBoxChangeSettings.stringValue = "Changing settings"
        
        
        
        btnDisablePassword.title = "Disable Password"
//        lblInfo.stringValue = "You will need to enter your password - When opening preferences, When aborting an evening routine, When aborting the morning routine."
        
        lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = "Postponing/skipping evening routine after cutoff time"
        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
//            if let title = passwordPreferencesInfo.value(forKey: "infoText") as? String{
//                lblInfo.stringValue = title
//            }
            if let title = passwordPreferencesInfo.value(forKey: "buttonDisablePasswordText") as? String{
                btnDisablePassword.title = title
            }
            
            lblTitleAskPassword.stringValue = passwordPreferencesInfo.value(forKey: "titleAskPassword") as? String ?? lblTitleAskPassword.stringValue
            lblQuestionPassword.stringValue = passwordPreferencesInfo.value(forKey: "questionPassword") as? String ?? lblQuestionPassword.stringValue
            lblCheckBoxQuitApp.stringValue = passwordPreferencesInfo.value(forKey: "buttonQuitAppText") as? String ?? lblCheckBoxQuitApp.stringValue
            lblCheckBoxStopPomodoro.stringValue = passwordPreferencesInfo.value(forKey: "buttonStopPomodoroText") as? String ?? lblCheckBoxStopPomodoro.stringValue
            lblCheckBoxAbortingShutoff.stringValue = passwordPreferencesInfo.value(forKey: "buttonAbortingShutoffText") as? String ?? lblCheckBoxAbortingShutoff.stringValue
            lblCheckBoxSkipEveningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitText") as? String ?? lblCheckBoxSkipEveningHabit.stringValue
            lblCheckBoxSkipMorningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipMorningHabitText") as? String ?? lblCheckBoxSkipMorningHabit.stringValue
            lblCheckBoxChangeSettings.stringValue = passwordPreferencesInfo.value(forKey: "buttonChangeSettingsText") as? String ?? lblCheckBoxChangeSettings.stringValue
            lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitAfterCutOffText") as? String ?? lblCheckBoxSkipEveningHabitAfterCutOff.stringValue
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
    }
    
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
    override func viewWillAppear() {
        preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: 630 + 46, height: 511 + 142))
        resetView()
    }//your password has been disabled.
    //
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
        }
        
        
        
        if SettingsManagerObject.isPasswordRequireInChangeSettings{
            checkBoxChangeSettings.state = .on
        }else{
            checkBoxChangeSettings.state = .off
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
                var passwordSetAlertTitle = "Password successfully set."
                if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                    if let title = passwordPreferencesInfo.value(forKey: "passwordSetAlertTitle") as? String{
                        passwordSetAlertTitle = title
                    }
                }
                alertforvalidation(question: passwordSetAlertTitle, text: "")
            }else{
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
            allApiObject.capturePosthog(event: "change-password", metadata: [:])
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
}
