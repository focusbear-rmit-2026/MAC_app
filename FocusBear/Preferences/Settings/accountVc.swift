//
//  accountVc.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 03/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import Auth0

class accountVc: NSViewController {

    
    @IBOutlet weak var loaderResetPassword: NSProgressIndicator!
    @IBOutlet weak var btnResetPassword: Button!
    @IBOutlet weak var lblTitleMain: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnRestorePurchase: Button!
    @IBOutlet weak var lblRestore: NSTextField!
    @IBOutlet weak var lblUserId: NSTextField!
    @IBOutlet weak var lblTitleUserId: NSTextField!
    @IBOutlet weak var btnLogout: NSButton!
    @IBOutlet weak var lblEmaiId: NSTextField!
    @IBOutlet weak var lblTitleEmailId: NSTextField!
    @IBOutlet weak var lblName: NSTextField!
    @IBOutlet weak var lblTitleName: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblVersionState: NSTextField!
    
    var restoreText = "If you've already purchased Focus Bear subscription, you can restore that purchase."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnRestorePurchase.title = "Sync Payment Status"
        
        lblTitleUserId.stringValue = "User Id:"
        lblTitle.stringValue = "Your Account Information"
        lblTitleName.stringValue = "Name:"
        lblTitleEmailId.stringValue = "Email Id:"
        btnLogout.title = "Logout"
        btnResetPassword.title = "Reset Password"
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            lblTitle.stringValue = accountVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleName.stringValue = accountVcInfo.value(forKey: "titleNameText") as? String ?? lblTitleName.stringValue
            lblTitleEmailId.stringValue = accountVcInfo.value(forKey: "titleEmailIdText") as? String ?? lblTitleEmailId.stringValue
            btnLogout.title = accountVcInfo.value(forKey: "buttonLogoutText") as? String ?? btnLogout.title
            lblTitleUserId.stringValue = accountVcInfo.value(forKey: "titleUserIdText") as? String ?? lblTitleUserId.stringValue
            restoreText = accountVcInfo.value(forKey: "restoreText") as? String ?? restoreText
            btnRestorePurchase.title = accountVcInfo.value(forKey: "buttonRestoreText") as? String ?? btnRestorePurchase.title
            btnResetPassword.title = accountVcInfo.value(forKey: "buttonResetPasswordText") as? String ?? btnResetPassword.title
        }
        
        arrForSearchFromSettings.append(["title": lblTitle.stringValue, "tabId": idAccount, "object": lblTitle as Any])
        arrForSearchFromSettings.append(["title": btnRestorePurchase.title, "tabId": idAccount, "object": btnRestorePurchase as Any])
        arrForSearchFromSettings.append(["title": btnLogout.title, "tabId": idAccount, "object": btnLogout as Any])
        arrForSearchFromSettings.append(["title": lblTitleEmailId.stringValue, "tabId": idAccount, "object": lblTitleEmailId as Any])
        arrForSearchFromSettings.append(["title": lblTitleName.stringValue, "tabId": idAccount, "object": lblTitleName as Any])
        arrForSearchFromSettings.append(["title": lblTitleUserId.stringValue, "tabId": idAccount, "object": lblTitleUserId as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": lblTitle.stringValue, "tabId": idAccount, "object": lblTitle as Any])
        arrForSearchFromSimpleModeSettings.append(["title": btnRestorePurchase.title, "tabId": idAccount, "object": btnRestorePurchase as Any])
        arrForSearchFromSimpleModeSettings.append(["title": btnLogout.title, "tabId": idAccount, "object": btnLogout as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleEmailId.stringValue, "tabId": idAccount, "object": lblTitleEmailId as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleName.stringValue, "tabId": idAccount, "object": lblTitleName as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleUserId.stringValue, "tabId": idAccount, "object": lblTitleUserId as Any])
        
        
    }
    
    override func viewWillAppear(){
        addLog(text: "accountVc:- viewWillAppear")
        
        if let userId = appdelegate!.user?.userId{
            lblUserId.stringValue = userId
        }else{
            lblUserId.stringValue = ""
        }
        lblName.stringValue = currentUserName
        lblEmaiId.stringValue = currentUserEmail
        
        var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
        var trialExpiredText = "Your subscription has expired"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }

        }
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            trialExpiredText = menuInfo.value(forKey: "subscriptionExpiredText") as? String ?? trialExpiredText
        }
        if isPurchased == false{
            let daysremaining = daysLeft

            
            if daysremaining <= 0{
                lblVersionState.stringValue = trialExpiredText 
            }else{
                lblVersionState.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")//"Trial version - \(daysremaining) of 7 trial days remaining"//
            }
        }else{
            lblVersionState.stringValue = "Registered Version"
            if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                lblVersionState.stringValue = accountVcInfo.value(forKey: "registeredVersionText") as? String ?? lblVersionState.stringValue
            }
        }
        
        if !isPurchased{
            lblRestore.stringValue = restoreText
        }else{
            lblRestore.stringValue = ""
        }
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitleMain.stringValue = ""
            }else{
                lblTitleMain.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitleMain.stringValue = ""
        }
    }
    
    @IBAction func btnLogoutClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- btnLogoutClicked")
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to logout?"
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            alert.messageText = accountVcInfo.value(forKey: "logoutAlertText") as? String ?? alert.messageText
        }
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                allApiObject.capturePosthog(event: "logout", metadata: [:])
                appdelegate?.logout(isAutomatic: false)
            }
        })
       
    }
    @IBAction func btnRestorePurchaseClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- btnRestorePurchaseClicked")
        loader.startAnimation(self)
        btnRestorePurchase.isEnabled = false
        allApiObject.capturePosthog(event: "sync-payment-status", metadata: ["from":"accounts_tab"])
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnRestorePurchase.isEnabled = true
                self.viewWillAppear()
            }
            
        })
    }
    
    @IBAction func btnResetPasswordClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- Reset Password Clicked")
        loaderResetPassword.startAnimation(self)
        if !isEmailVerified{
            btnResetPassword.isEnabled = false
            allApiObject.getuserDetailsInfo(completionHandler: {dic in
                DispatchQueue.main.async {
                    self.loaderResetPassword.stopAnimation(self)
                    self.btnResetPassword.isEnabled = true
                    if dic != nil{
                        isEmailVerified = dic?.value(forKey: "email_verified") as? Bool ?? false 
                        if !isEmailVerified{
                            if unverifiedEmailWcObj != nil{
                                if unverifiedEmailWcObj?.window?.isVisible ?? false{
                                    unverifiedEmailWcObj?.window?.close()
                                }
                            }
                            self.presentAsSheet(getUnverifiedEmailVcObject())
                            getUnverifiedEmailVcObject().isAWindow = false
                        }else{
                            self.resetPassword()
                        }
                    }
                }
            })
        }else{
            resetPassword()
        }
    }

    
    func resetPassword(){
        addLog(text: "func resetPassword called")
        loaderResetPassword.startAnimation(self)
        btnResetPassword.isEnabled = false
        DispatchQueue.global().async{
            sleep(20) // makes it
            DispatchQueue.main.async{
                self.btnResetPassword.isEnabled = true
            }
        }
//        Auth0.authentication().resetPassword(email: currentUserEmail, connection: "Username-Password-Authentication").start{ result in
//            DispatchQueue.main.async {
//                self.loaderResetPassword.stopAnimation(self)
//                switch result {
//                case .success():
//                    if let window = self.view.window {
//                        let alert = NSAlert()
//                        alert.messageText = "Reset Link Sent" text
//                        alert.informativeText = "We've sent a password reset link to your email. Please check your inbox."
//                        alert.alertStyle = .informational
//                        alert.beginSheetModal(for: window, completionHandler: nil)
//                    }
//                case .failure(_):
//                    if let window = self.view.window {
//                        let alert = NSAlert()
//                        alert.messageText = "Unable to Send Reset Email"
//                        alert.informativeText = "Something went wrong while sending the reset link. Please check your internet connection and try again."
//                        alert.alertStyle = .warning
//                        alert.beginSheetModal(for: window, completionHandler: nil)
//                    }
//                }
//            }
//        }
        
        
        
        allApiObject.resetPassword(completionHandler: {(bool, message) in
            DispatchQueue.main.async {
                self.loaderResetPassword.stopAnimation(self)
                switch bool {
                case true:
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Reset Link Sent"
                        alert.informativeText = "We've sent a password reset link to your email. Please check your inbox."
                        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                            alert.messageText = accountVcInfo.value(forKey: "linkSentTitle") as? String ?? alert.messageText
                            alert.informativeText = accountVcInfo.value(forKey: "linkSentDescription") as? String ?? alert.informativeText
                        }
                        
                        alert.alertStyle = .informational
                        alert.beginSheetModal(for: window, completionHandler: nil)
                    }
                case false:
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Unable to Send Reset Email"
                        alert.informativeText = message ?? "Something went wrong while sending the reset link. Please check your internet connection and try again."
                        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                            alert.messageText = accountVcInfo.value(forKey: "linkSendFailedTitle") as? String ?? alert.messageText
                            alert.informativeText = accountVcInfo.value(forKey: "linkSendFailedDescription") as? String ?? alert.informativeText
                        }
                        alert.alertStyle = .warning
                        alert.beginSheetModal(for: window, completionHandler: nil)
                    }
                }
            }
            
        })
    }
}
