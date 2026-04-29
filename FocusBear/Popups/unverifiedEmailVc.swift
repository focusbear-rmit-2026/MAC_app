//
//  unverifiedEmailVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 22/04/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class unverifiedEmailVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnResend: Button!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var isAWindow  = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Your email address hasn’t been verified yet. Please check your inbox for the confirmation email, or click below to resend it."
        btnResend.title = "Resend confirmation email"
        btnCancel.title = buttonCancelText
        btnCancel.isSecondaryButton = true
        
        if let unverifiedEmailVcInfo = configjson.value(forKey: "unverifiedEmailVcInfo") as? NSDictionary{
            lblTitle.stringValue = unverifiedEmailVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnResend.title = unverifiedEmailVcInfo.value(forKey: "buttonResendEmailText") as? String ?? btnResend.title
        }
    }
    
    @IBAction func btnResendClicked(_ sender: Any) {
        addLog(text: "[user-action] unverifiedEmailVc:- button Resend Clicked")
        self.loader.startAnimation(self)
        allApiObject.emailConfirmation(completionHandler: { val in
            DispatchQueue.main.async{
                self.loader.stopAnimation(self)
                if val{
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Verification Email Sent"
                        alert.informativeText = "We've sent a verification link to your email. Please check your inbox to verify your account."
                        if let unverifiedEmailVcInfo = configjson.value(forKey: "unverifiedEmailVcInfo") as? NSDictionary{
                            alert.messageText = unverifiedEmailVcInfo.value(forKey: "titleEmailSent") as? String ?? alert.messageText
                            alert.informativeText = unverifiedEmailVcInfo.value(forKey: "descriptionEmailSent") as? String ?? alert.informativeText
                        }
                        alert.alertStyle = .informational
                        alert.beginSheetModal(for: window, completionHandler: {_ in
                            self.close()
                        })
                    }
                }else{
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Failed to Send Verification Email"
                        alert.informativeText = "Something went wrong while sending the verification email. Please try again later."
                        if let unverifiedEmailVcInfo = configjson.value(forKey: "unverifiedEmailVcInfo") as? NSDictionary{
                            alert.messageText = unverifiedEmailVcInfo.value(forKey: "titleEmailFailed") as? String ?? alert.messageText
                            alert.informativeText = unverifiedEmailVcInfo.value(forKey: "descriptionEmailFailed") as? String ?? alert.informativeText
                        }
                        alert.alertStyle = .warning
                        alert.beginSheetModal(for: window, completionHandler: {_ in
                            self.close()
                        })
                    }
                }
                
            }
        })
    }
    
    func close(){
        if isAWindow{
            self.view.window?.close()
        }else{
            self.dismiss(self)
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "[user-action] unverifiedEmailVc:- button Cancel Clicked")
        close()
    }
}
