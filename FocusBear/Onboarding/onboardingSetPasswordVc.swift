//
//  passwordVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/03/22.


import Cocoa

class onboardingSetPasswordVc: NSViewController {// not in use 

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var checkBoxSkipEveningHabitAfterCutOff: NSButton!
    @IBOutlet weak var checkBoxQuitApp: NSButton!
    @IBOutlet weak var checkBoxStopPomodoro: NSButton!
    @IBOutlet weak var checkBoxAbortingShutoff: NSButton!
    @IBOutlet weak var checkBoxSkipEveningHabit: NSButton!
    @IBOutlet weak var checkBoxSkipMorningHabit: NSButton!
    @IBOutlet weak var checkBoxChangeSettings: NSButton!
    @IBOutlet weak var checkBoxUseRelaxFocusMode: NSButton!
    
    @IBOutlet weak var lblCheckBoxSkipEveningHabitAfterCutOff: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxQuitApp: NSTextField!
    @IBOutlet weak var lblCheckBoxStopPomodoro: NSTextField!
    @IBOutlet weak var lblCheckBoxAbortingShutoff: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipEveningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipMorningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxChangeSettings: NSTextField!
    @IBOutlet weak var lblCheckBoxUseRelaxFocusMode: ignoreMouseTextField!
    
    @IBOutlet weak var lblQuestionPassword: NSTextField!
    @IBOutlet weak var lblTitleAskPassword: NSTextField!
    @IBOutlet weak var lblConfirmPassword: NSTextField!
    @IBOutlet weak var lblNewPassword: NSTextField!
    @IBOutlet weak var btnChangePassword: NSButton!
    @IBOutlet weak var textFieldNewPassword: NSSecureTextField!
    @IBOutlet weak var textFieldConfirmPassword: NSSecureTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    @IBOutlet weak var checkBoxSavedPassword: NSButton!
    @IBOutlet weak var lblCheckBoxSavedPassword: ignoreMouseTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Set a password to unlock the computer"
        lblDescription.stringValue = "To make it harder to impulsively use your computer late at night or before you've done your morning routine, you can set a password. This is not the same as your login password. We recommend that you get an accountability partner to set the password. That way, you have to ask them to use your computer at a time you probably shouldn't be using it."
        lblCheckBoxUseRelaxFocusMode.stringValue = "Allow using relax focus mode"
        lblTitleAskPassword.stringValue = "Ask for password:"
        lblQuestionPassword.stringValue = "When do you want to require a password?"
       
        lblCheckBoxQuitApp.stringValue = "Quitting/deactivating app"
        lblCheckBoxStopPomodoro.stringValue = "Stopping Super pomodoro mode"
        lblCheckBoxAbortingShutoff.stringValue = "Aborting shutoff"
        lblCheckBoxSkipEveningHabit.stringValue = "Postponing/skipping evening routine"
        lblCheckBoxSkipMorningHabit.stringValue = "Postponing/skipping morning routine"
        lblCheckBoxChangeSettings.stringValue = "Changing settings"
        
        btnContinue.title = "Continue"
        
        lblCheckBoxSavedPassword.stringValue = "I've saved the password somewhere safe"
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            btnContinue.title = chooseFrictionLevelVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }

        lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = "Postponing/skipping evening routine after cutoff time"
        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
            lblTitleAskPassword.stringValue = passwordPreferencesInfo.value(forKey: "titleAskPassword") as? String ?? lblTitleAskPassword.stringValue
            lblQuestionPassword.stringValue = passwordPreferencesInfo.value(forKey: "questionPassword") as? String ?? lblQuestionPassword.stringValue
            lblCheckBoxQuitApp.stringValue = passwordPreferencesInfo.value(forKey: "buttonQuitAppText") as? String ?? lblCheckBoxQuitApp.stringValue
            lblCheckBoxStopPomodoro.stringValue = passwordPreferencesInfo.value(forKey: "buttonStopPomodoroText") as? String ?? lblCheckBoxStopPomodoro.stringValue
            lblCheckBoxAbortingShutoff.stringValue = passwordPreferencesInfo.value(forKey: "buttonAbortingShutoffText") as? String ?? lblCheckBoxAbortingShutoff.stringValue
            lblCheckBoxSkipEveningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitText") as? String ?? lblCheckBoxSkipEveningHabit.stringValue
            lblCheckBoxSkipMorningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipMorningHabitText") as? String ?? lblCheckBoxSkipMorningHabit.stringValue
            lblCheckBoxChangeSettings.stringValue = passwordPreferencesInfo.value(forKey: "buttonChangeSettingsText") as? String ?? lblCheckBoxChangeSettings.stringValue
            lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitAfterCutOffText") as? String ?? lblCheckBoxSkipEveningHabitAfterCutOff.stringValue
            lblCheckBoxSavedPassword.stringValue = passwordPreferencesInfo.value(forKey: "buttonSavedPasswordText") as? String ?? lblCheckBoxSavedPassword.stringValue
            lblCheckBoxUseRelaxFocusMode.stringValue = passwordPreferencesInfo.value(forKey: "buttonUseRelaxFocusModeText") as? String ?? lblCheckBoxUseRelaxFocusMode.stringValue
            
            lblTitle.stringValue = passwordPreferencesInfo.value(forKey: "titleSetPasswordOnboarding") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = passwordPreferencesInfo.value(forKey: "descriptionSetPasswordOnboarding") as? String ?? lblDescription.stringValue
        }

        checkBoxSavedPassword.isHidden = true
        lblCheckBoxSavedPassword.isHidden = true
        btnContinue.isEnabled = true
    }
    

    override func viewWillAppear() {
        resetView()
    }//your password has been disabled.
    //
    func resetView(){
        textFieldNewPassword.stringValue = ""
        textFieldConfirmPassword.stringValue = ""
        lblNewPassword.stringValue = "New Password"
        lblConfirmPassword.stringValue = "Confirm Password"

        if UserDefaults.standard.object(forKey: kUserdefaultsPasswordSetInOnboarding) == nil{
            
            btnChangePassword.title = "Set Password"
            textFieldNewPassword.placeholderString = "New Password"
            textFieldConfirmPassword.placeholderString = "Confirm Password"
            //lblPasswordState.stringValue = "You do not have a password set."
            
//            btnDisablePassword.isHidden = true
            
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let titleSetPassword = passwordPreferencesInfo.value(forKey: "titleSetPassword") as? String{
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
                  //  lblPasswordState.stringValue = passwordNotSetText
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
        }
        
        else{
            btnChangePassword.title = "Change Password"
            textFieldNewPassword.placeholderString = "*****"
            textFieldConfirmPassword.placeholderString = "*****"
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let titleChangePassword = passwordPreferencesInfo.value(forKey: "titleChangePassword") as? String{
                }
                if let buttonChangePasswordText = passwordPreferencesInfo.value(forKey: "buttonChangePasswordText") as? String{
                    btnChangePassword.title = buttonChangePasswordText
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
        }

        checkBoxChangeSettings.state = .on
        checkBoxSkipMorningHabit.state = .on
        checkBoxSkipEveningHabit.state = .on
        checkBoxSkipEveningHabitAfterCutOff.state = .on
        checkBoxAbortingShutoff.state = .on
        checkBoxStopPomodoro.state = .on
        checkBoxQuitApp.state = .on
        checkBoxUseRelaxFocusMode.state = .on
    }
    
    @IBAction func checkBoxUseRelaxFocusModeClicked(_ sender: Any) {
        if checkBoxUseRelaxFocusMode.state == .on{
            SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode = true
            allApiObject.capturePosthog(event: "require-password-in-use-relax-focus-mode-enabled", metadata: [:])
        }else{
            SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode = false
            allApiObject.capturePosthog(event: "require-password-in-use-relax-focus-mode-disabled", metadata: [:])
        }
    }
    
    
    @IBAction func checkBoxQuitAppClicked(_ sender: Any) {
        if checkBoxQuitApp.state == .on{
            SettingsManagerObject.isPasswordRequireInQuitApp = true
            allApiObject.capturePosthog(event: "require-password-in-quitting-app-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInQuitApp = false
            allApiObject.capturePosthog(event: "require-password-in-quitting-app-disabled", metadata: [:])//#490//
        }
    }
    
    @IBAction func checkBoxStopPomodoroClicked(_ sender: Any) {
        if checkBoxStopPomodoro.state == .on{
            SettingsManagerObject.isPasswordRequireInStopPomodoro = true
            allApiObject.capturePosthog(event: "require-password-in-stop-pomodoro-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInStopPomodoro = false
            allApiObject.capturePosthog(event: "require-password-in-stop-pomodoro-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxAbortingShutoffClicked(_ sender: Any) {
        if checkBoxAbortingShutoff.state == .on{
            SettingsManagerObject.isPasswordRequireInAbortShutoff = true
            allApiObject.capturePosthog(event: "require-password-in-using-mac-late-at-night-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInAbortShutoff = false
            allApiObject.capturePosthog(event: "require-password-in-using-mac-late-at-night-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxSkipEveningHabitClicked(_ sender: Any) {
        if checkBoxSkipEveningHabit.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipEvening = true
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipEvening = false
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-disabled", metadata: [:])//#490
        }
    }
    @IBAction func checkBoxSkipEveningHabitAfterCutOffClicked(_ sender: Any) {
        if checkBoxSkipEveningHabitAfterCutOff.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff = true
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-after-cutoff-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff = false
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-after-cutoff-disabled", metadata: [:])//#490
        }
        
    }
    
    @IBAction func checkBoxSkipMorningHabitClicked(_ sender: Any) {
        if checkBoxSkipMorningHabit.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipMorning = true
            allApiObject.capturePosthog(event: "require-password-in-skip-morning-routine-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipMorning = false
            allApiObject.capturePosthog(event: "require-password-in-skip-morning-routine-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxChangeSettingsClicked(_ sender: Any) {
        if checkBoxChangeSettings.state == .on{
            SettingsManagerObject.isPasswordRequireInChangeSettings = true
            allApiObject.capturePosthog(event: "require-password-in-change-settings-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInChangeSettings = false
            allApiObject.capturePosthog(event: "require-password-in-change-settings-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxSavedPasswordClicked(_ sender: Any) {
        if checkBoxSavedPassword.state == .on{
            btnContinue.isEnabled = true
        }else{
            btnContinue.isEnabled = false
        }
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
            
            if UserDefaults.standard.object(forKey: kUserdefaultsPasswordSetInOnboarding) == nil{
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
            
            UserDefaults.standard.set(base64password, forKey: kUserdefaultsPasswordSetInOnboarding)
            resetView()
            allApiObject.capturePosthog(event: "change-password", metadata: [:])//
            checkBoxSavedPassword.isHidden = false
            lblCheckBoxSavedPassword.isHidden = false
            checkBoxSavedPassword.state = .off
            btnContinue.isEnabled = false
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
    
    @IBAction func btnContinueClicked(_ sender: Any) {
//        showHowHeardWindow()
    }
}
