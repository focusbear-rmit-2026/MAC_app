//
//  passwordVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 10/03/22.
//  Copyright © 2022 MugPhotography. All rights reserved.
//

import Cocoa

class passwordVc: NSViewController {

    @IBOutlet weak var lblPasswordState: NSTextField!
    @IBOutlet weak var lblInfo: NSTextField!
    @IBOutlet weak var btnChangePassword: NSButton!
    @IBOutlet weak var textFieldNewPassword: NSSecureTextField!
    @IBOutlet weak var textFieldConfirmPassword: NSSecureTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        

        lblInfo.stringValue = "You will need to enter your password - When opening preferences, When aborting an evening routine, When aborting the morning routine."
        
        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
            if let title = passwordPreferencesInfo.value(forKey: "infoText") as? String{
                lblInfo.stringValue = title
            }
        }
    }
    
    override func viewWillAppear() {
        textFieldNewPassword.stringValue = ""
        textFieldConfirmPassword.stringValue = ""
        if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) == nil{
            lblTitle.stringValue = "Set Password"
            btnChangePassword.title = "Set Password"
            textFieldNewPassword.placeholderString = "New Password"
            textFieldConfirmPassword.placeholderString = "Confirm Password"
            lblPasswordState.stringValue = "You do not have a password set."
            
            
            
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let titleSetPassword = passwordPreferencesInfo.value(forKey: "titleSetPassword") as? String{
                    lblTitle.stringValue = titleSetPassword
                }
                if let buttonSetPasswordText = passwordPreferencesInfo.value(forKey: "buttonSetPasswordText") as? String{
                    btnChangePassword.title = buttonSetPasswordText
                }
                if let newPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "newPasswordPlaceholderText") as? String{
                    textFieldNewPassword.placeholderString = newPasswordPlaceholderText
                }
                if let confirmPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "confirmPasswordPlaceholderText") as? String{
                    textFieldConfirmPassword.placeholderString = confirmPasswordPlaceholderText
                }
                if let passwordNotSetText = passwordPreferencesInfo.value(forKey: "passwordNotSetText") as? String{
                    lblPasswordState.stringValue = passwordNotSetText
                }
            }
            
        }else{
            lblTitle.stringValue = "Change Password"
            btnChangePassword.title = "Change Password"
            textFieldNewPassword.placeholderString = "*****"
            textFieldConfirmPassword.placeholderString = "*****"
            lblPasswordState.stringValue = "You have an active password set."
            
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
            }
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
            
            if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) == nil{
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
            
            UserDefaults.standard.set(base64password, forKey: kUserdefaultsAppPassword)

            textFieldNewPassword.stringValue = ""
            textFieldConfirmPassword.stringValue = ""
            lblTitle.stringValue = "Change Password"
            btnChangePassword.title = "Change Password"
            textFieldNewPassword.placeholderString = "*****"
            textFieldConfirmPassword.placeholderString = "*****"
            lblPasswordState.stringValue = "You have an active password set."
            
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
            }
            
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
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonOkText)
        
        //            alert.runModal()
        alert.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                // self.txtFieldEmail.stringValue = ""
            }
        })
        
    }
}
