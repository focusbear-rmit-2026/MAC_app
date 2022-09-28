//
//  enterPasswordVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/03/22.


import Cocoa

class enterPasswordVc: NSViewController, NSTextFieldDelegate {
   
    
    @IBOutlet weak var lblError: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var textFieldPassword: NSSecureTextField!
    @IBOutlet weak var btnResetPassword: underLineButton!
    @IBOutlet weak var btnOk: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    
    var isCurrentViewInMainWindow = false
    var buttonResetPasswordText = "Reset Password"
    var parentVc:NSViewController?
    override func viewDidLoad() {
        super.viewDidLoad()

        lblTitle.stringValue = "Please enter the password to continue"
        textFieldPassword.placeholderString = "Password"
        
        
        if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
            if let title = enterPasswordViewInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let passwordPlaceholderText = enterPasswordViewInfo.value(forKey: "passwordPlaceholderText") as? String{
                textFieldPassword.placeholderString = passwordPlaceholderText
            }
            if let buttonResetPasswordText = enterPasswordViewInfo.value(forKey: "buttonResetPasswordText") as? String{
                self.buttonResetPasswordText = buttonResetPasswordText
            }
        }
        btnResetPassword.title = buttonResetPasswordText
        
        btnOk.title = buttonOkText//"OK"
        btnCancel.title = buttonCancelText//"Cancel"
        textFieldPassword.delegate = self
    }
    
    
    
    override func viewWillAppear() {
        isCurrentViewInMainWindow = false
        lblError.isHidden = true
        lblError.stringValue = ""
        textFieldPassword.stringValue = ""
        btnResetPassword.isHidden = false
        
        if UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) == nil{//if reset is in progress then disable reset button
            btnResetPassword.setEnable(title: buttonResetPasswordText)
        }else{
            btnResetPassword.setDisable(title: buttonResetPasswordText)
        }
        
        if isMainWindowLodded{
            if mainWindowControllerObj?.window?.isVisible ?? false{
                btnResetPassword.isHidden = true
                isCurrentViewInMainWindow = true
                return;//ho bhi kro is ke uppar kro q ki return k baaad kuch bhi execute ni hoga
            }
        }
    }
    
    override func viewDidAppear() {
        textFieldPassword.selectText(self)
        textFieldPassword.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        addLog(text: "Enter password view - btnOkClicked")//
        if textFieldPassword.stringValue.isEmpty{
            var blankPasswordErrorTitle = "Password cannot be blank."
            var blankPasswordErrorSubTitle = "Please enter a valid password."
            
            
            if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                if let title = enterPasswordViewInfo.value(forKey: "blankPasswordErrorTitle") as? String{
                    blankPasswordErrorTitle = title
                }
                if let title = enterPasswordViewInfo.value(forKey: "blankPasswordErrorSubTitle") as? String{
                    blankPasswordErrorSubTitle = title
                }
            }
            
            if isCurrentViewInMainWindow{
                lblError.isHidden = false
                lblError.stringValue = "\(blankPasswordErrorTitle) \(blankPasswordErrorSubTitle)"
            }else{
               alertforvalidation(question: blankPasswordErrorTitle, text: blankPasswordErrorSubTitle)
            }
            return;
        }
        
        if let passwordBase64 = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) as? String{
            if let password = passwordBase64.fromBase64(){
                if textFieldPassword.stringValue == password{
                    addLog(text: "Enter password view - password is correct")//
                    
                    if parentVc != nil{
                        if parentVc == menuViewControllerObj{
                            self.view.window?.close()
                            menuViewControllerObj?.passwordIsCorrect()
                            return;
                        }else if parentVc == pomodoroVcObj{
                            self.view.window?.close()
                            pomodoroVcObj?.passwordIsCorrect()
                            return;
                        }else if parentVc == getAskPostponeVcObject(){
                            self.view.window?.close()
                            if lastCurrentState == ._MORNING_HABIT_{
                                mainViewControllerObj?.postponeMorningHabitFor(minutes: Int(getAskPostponeVcObject().popUpButtonSelectMinutes.title) ?? 15)
                            }else if lastCurrentState == ._EVENING_HABIT_{
                                mainViewControllerObj?.postponeEveningHabitFor(minutes: Int(getAskPostponeVcObject().popUpButtonSelectMinutes.title) ?? 15)
                            }else if lastCurrentState == ._FOCUS_SUMMARY_{
                                mainViewControllerObj?.postponeFocusSummaryFor(minutes: Int(getAskPostponeVcObject().popUpButtonSelectMinutes.title) ?? 15)
                            }
                            
                        }
                    }
                                        
                    if isMainWindowLodded{
                        if (mainWindowControllerObj?.window!.isVisible)!{//it means isi per aaya hoga
                            self.view.removeFromSuperview()
                            if currentState == ._SHUTOFFMAC_{
                                shutOffTimeVcObj!.getAccessNowClicked()
                            }else{
                                mainViewControllerObj?.showAbortStartView()
                            }
                            return;
                        }
                    }
                    
                    if self.view.window == getQuittingWindowObject().window{
                        getQuittingCountDownVcObject().startTimer()
                        self.view.removeFromSuperview()
                        return;
                    }
                    self.view.removeFromSuperview()
                }else{
                    addLog(text: "Enter password view - Invalid password.")//
                    var alertTitle = "Invalid password."
                    if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                        if let title = enterPasswordViewInfo.value(forKey: "incorrectPasswordErrorTitle") as? String{
                            alertTitle = title
                        }
                    }
                    if isCurrentViewInMainWindow{
                        lblError.isHidden = false
                        lblError.stringValue = alertTitle
                    }else{
                       alertforvalidation(question: alertTitle, text: "")
                    }
                }
            }
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        //check kro ki khase aayya h ye view preferences se ya main  full screen window se
//        agar preferences khuli ho or main window aa jatyi h to preferences band kra do  qki preferences mai ye view hoga jo main window mai bhi aa skta hai
        
        addLog(text: "Enter password view - cancel clicked")//
        
        if parentVc != nil{
            if parentVc == menuViewControllerObj{
//                self.view.window?.close()
//                NSApplication.shared.stopModal()
                self.view.window?.close()
                return;
            }else if parentVc == pomodoroVcObj{
                self.view.window?.close()
                return;
            }else if parentVc == getAskPostponeVcObject(){
                self.view.removeFromSuperview()
                mainViewControllerObj?.abortCancel()
                return;
            }
        }
        
        if isMainWindowLodded{
            if (mainWindowControllerObj?.window!.isVisible)!{//it means isi per aaya hoga
                self.view.removeFromSuperview()
                if currentState != ._SHUTOFFMAC_{
                   mainViewControllerObj?.abortCancel()
                }
                return;
            }
        }
        
        self.view.window?.close()
        self.view.removeFromSuperview()
        
    }
  
   
    @IBAction func btnResetPasswordClicked(_ sender: Any) {
        
        var alertTitle = "Reset Password"
        var alertSubTitle = "Your current password will be removed after 24 hours. You can then set a new password. Proceed?"
        
        if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
            if let title = enterPasswordViewInfo.value(forKey: "alertConfirmResetPasswordTitle") as? String{
                alertTitle = title
            }
            if let title = enterPasswordViewInfo.value(forKey: "alertConfirmResetPasswordSubTitle") as? String{
                alertSubTitle = title
            }
        }
        
        let alertReset: NSAlert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alertReset.window.sharingType = .none
            }
        }
        alertReset.messageText = alertTitle
        alertReset.informativeText = alertSubTitle
        alertReset.alertStyle = NSAlert.Style.warning
        alertReset.addButton(withTitle: buttonOkText)
        alertReset.addButton(withTitle: buttonCancelText)
        
        
        alertReset.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")

                addLog(text: "Enter password view reset clicked")
                if self.timerCheckClearPasswordTime != nil{
                    self.timerCheckClearPasswordTime?.invalidate()
                    self.timerCheckClearPasswordTime = nil
                }
                let Hours:TimeInterval = 24 * 60 * 60
                let date = Date().addingTimeInterval(Hours)//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
                UserDefaults.standard.set(date, forKey: kUserdefaults24HoursClearPasswordTime)
                addLog(text: "password will be clear after 24 hours - \(getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss"))")
                self.timerCheckClearPasswordTime = Timer.scheduledTimer(timeInterval: Hours, target: self, selector: #selector(self.clearPassword), userInfo: nil, repeats: false)
                self.btnResetPassword.setDisable(title: self.buttonResetPasswordText)
                
                var alertTitle = "Password reset in progress"
                var alertSubTitle = "Please set a new password after 24 hours."
                
                if let enterPasswordViewInfo = configjson.value(forKey: "enterPasswordViewInfo") as? NSDictionary{
                    if let title = enterPasswordViewInfo.value(forKey: "alertPasswordResetDoneTitle") as? String{
                        alertTitle = title
                    }
                    if let title = enterPasswordViewInfo.value(forKey: "alertPasswordResetDoneSubTitle") as? String{
                        alertSubTitle = title
                    }
                }
                
                
                let alert: NSAlert = NSAlert()
                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alert.window.sharingType = .none
                    }
                }
                alert.messageText = alertTitle
                alert.informativeText = alertSubTitle
                alert.alertStyle = NSAlert.Style.warning
                alert.addButton(withTitle: buttonOkText)
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                        print("okclicked")
                        // self.txtFieldEmail.stringValue = ""
                        if isMainWindowLodded{
                            if mainWindowControllerObj?.window!.isVisible ?? false{//it means isi per aaya hoga
                                self.view.removeFromSuperview()
                                if currentState != ._SHUTOFFMAC_{
                                    mainViewControllerObj?.abortCancel()
                                }
                                return;
                            }
                        }
                        self.view.window?.close()
                        self.view.removeFromSuperview()
                    }
                })
                
            }
        })
        
        
        
        
        
        
        
        
        
        
    }
    var timerCheckClearPasswordTime:Timer?
    @objc func clearPassword(){
        UserDefaults.standard.removeObject(forKey: kUserdefaults24HoursClearPasswordTime)
        UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
        addLog(text: "password is cleard after 24 hours")
    }
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        if textField == textFieldPassword{
            lblError.isHidden = true
            lblError.stringValue = ""
        }
    }
    func alertforvalidation(question: String, text: String) {
        let alert: NSAlert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alert.window.sharingType = .none
            }
        }
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

