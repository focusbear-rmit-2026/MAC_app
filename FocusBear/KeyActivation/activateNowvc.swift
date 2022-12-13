//
//  activateNowvc.swift
//  Wise Memory Optimizer
//
//  Created by Prashant on 02/01/19.
//  Copyright © 2019 Wise Tech Labs Private Limited. All rights reserved.
//

import Cocoa

class activateNowvc: NSViewController,NSTextFieldDelegate {
    
    
    @IBOutlet weak var lblTrialExpired: NSTextField!
    @IBOutlet weak var btnback: NSButton!
    @IBOutlet weak var lbltitle: NSTextField!
    
    @IBOutlet weak var boxbg: NSBox!
    @IBOutlet weak var btnclose: NSButton!
    @IBOutlet weak var imgicon: NSImageView!
    @IBOutlet weak var btnpastebutton: SYFlatButton!
    @IBOutlet weak var btnPurchaseNow: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var btnactivate: NSButton!
    @IBOutlet weak var txtFldLicense: NSTextField!
    @IBOutlet weak var lblpastelicesekey: NSTextField!
    
    var trialExpiredText = "Your trial has expired!"
    var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
    
    
    var viewopenfromSevendaysTrial = false
    func firstcall(){
        if viewopenfromSevendaysTrial == true{
            btnclose.isHidden = true
            //  boxbg.isHidden = true
            boxbg.wantsLayer = true
            boxbg.layer?.cornerRadius = 0
            self.view.frame = boxbg.frame
            btnback.isHidden = false
        }else{
            btnclose.isHidden = false
            btnback.isHidden = true
            boxbg.wantsLayer = true
            boxbg.layer?.cornerRadius = 6
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //        btnclose.image = NSImage(data: Data(base64Encoded: closeImage)!)
        
        
        var title = "Focus Bear Activation"
        var description = "Paste License key in the text box below and click Activate to unlock all features."
        var buttonPasteText = "Click here to paste the copied License Key."
        var buttonActivateText = "Activate"
        var buttonBuyLicenseText = "Buy License"
        var buttonBackText = "Back"
        
        
        if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{
            if let text = activationNagInfo.value(forKey: "title") as? String{
                title = text
            }
            if let text = activationNagInfo.value(forKey: "description") as? String{
                description = text
            }
            if let text = activationNagInfo.value(forKey: "buttonPasteText") as? String{
                buttonPasteText = text
            }
            
            if let text = activationNagInfo.value(forKey: "buttonActivateText") as? String{
                buttonActivateText = text
            }
            if let text = activationNagInfo.value(forKey: "buttonBuyLicenseText") as? String{
                buttonBuyLicenseText = text
            }
            if let text = activationNagInfo.value(forKey: "buttonBackText") as? String{
                buttonBackText = text
            }
            
        }
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "trialExpiredText") as? String{
                trialExpiredText = text
            }
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }
        }
        
        lbltitle.stringValue = title
        lblpastelicesekey.stringValue = description
        btnpastebutton.title = buttonPasteText
        lblTrialExpired.stringValue = trialExpiredText
        btnactivate.title = buttonActivateText
        btnPurchaseNow.title = buttonBuyLicenseText
        btnback.title = buttonBackText
        
        
        
        
        
        btnactivate.keyEquivalent = "\r"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.gray, NSAttributedString.Key.paragraphStyle: paragraph]
        let placeHolderStr = NSAttributedString(string: "XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX", attributes: attrs)
        txtFldLicense.placeholderAttributedString = placeHolderStr
        txtFldLicense.delegate = self
        updateActiveLicenseUI()
        
    }
    
    
    
    
    @IBAction func btnbuyLicense(_ sender: Any) {
//        purchaseNow_clicked()
    }
    
    
    @IBAction func btnactivate(_ sender: Any) {
        
        self.view.window?.standardWindowButton(.closeButton)?.isEnabled = false
        btnactivate.isEnabled = false
        btnback.isEnabled = false
        spinner.isHidden = false
        spinner.startAnimation(self)
        if Reachability.isConnectedToNetwork() == false {
            DispatchQueue.main.async {
                var noInternetTitle = "No Internet Connection"
                var noInternetSubTitle = "Make sure your device is connected to the internet."
                addLog(text: "Button Activate Clicked :- No Internet Connection")
                if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{
                    if let text = activationNagInfo.value(forKey: "noInternetTitle") as? String{
                        noInternetTitle = text
                    }
                    if let text = activationNagInfo.value(forKey: "noInternetSubTitle") as? String{
                        noInternetSubTitle = text
                    }
                }
                self.showAlertAfterActivate(title: noInternetTitle, Message: noInternetSubTitle, isHide: false)
                self.responceMilgaya()
            }
            return
        }
        let sKey = txtFldLicense.stringValue
        //"80F7CCF5-7FE54D41-B5A2DD9F-4A84B894"key"
        allApiObject.activateKey(license_key: sKey, completionHandler: { jsonResult in
            DispatchQueue.main.async {
                self.responceMilgaya()
            }
            if jsonResult != nil{
                var success = false
                var refunded = false
                if let val = jsonResult!.value(forKey: "success") as? Bool{
                    success = val
                }
                if let purchaseDic = jsonResult!.value(forKey: "purchase") as? NSDictionary{
                    if let val = purchaseDic.value(forKey: "refunded") as? Bool{
                        refunded = val
                    }
                }//80F7CCF5-7FE54D41-B5A2DD9F-4A84B894 key
                if success && !refunded{
                    //
                    isPurchased = true
                    UserDefaults.standard.removeObject(forKey: "trialExpired")
//                    UserDefaults.standard.set(true, forKey: kIsPurchased)
//                    UserDefaults.standard.set(sKey, forKey: kRegisteredLicenseKey)
                    DispatchQueue.main.async {
                        
                        var successfullyActivatedTitle = "Thank You!"
                        var successfullyActivatedSubTitle = "You have successfully activated Focus Bear!"
                        var buttonOkText = "OK"
                        addLog(text: "Button Activate Clicked :- uccessfully activated Focus Bear!")
                        
                        if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{
                            if let text = activationNagInfo.value(forKey: "successfullyActivatedTitle") as? String{
                                successfullyActivatedTitle = text
                            }
                            if let text = activationNagInfo.value(forKey: "successfullyActivatedSubTitle") as? String{
                                successfullyActivatedSubTitle = text
                            }
                            if let text = activationNagInfo.value(forKey: "buttonOkText") as? String{
                                buttonOkText = text
                            }
                            
                        }
                        
                        let alert = NSAlert()
                        alert.setSharingType()
                        alert.messageText = successfullyActivatedTitle
                        alert.informativeText = successfullyActivatedSubTitle
                        alert.alertStyle = .warning
                        alert.addButton(withTitle:  buttonOkText)
                        alert.beginSheetModal(for: (activationWindowControllerObj?.window)!, completionHandler: { (modalResponse) in
                            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                            }
                            
                            if isAppInitialLodded == false{
                                appdelegate?.initialWork()
                            }
                            self.view.window?.close()
                        })
                    }
                    
                }else{
                    //failed
                    DispatchQueue.main.async {
                        var activationErrorTitle = "Enable to activate."
                        var activationErrorSubTitle = "Please enter a valid License key."
                        addLog(text: "Button Activate Clicked :- Enable to activate., invalid Key")
                        if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{
                            if let text = activationNagInfo.value(forKey: "activationErrorTitle") as? String{
                                activationErrorTitle = text
                            }
                            if let text = activationNagInfo.value(forKey: "activationErrorSubTitle") as? String{
                                activationErrorSubTitle = text
                            }
                        }
                        
                        self.dialogOKCancel(title: activationErrorTitle, Message: activationErrorSubTitle)
                    }
                }
                
            }else{
                //failed
                DispatchQueue.main.async {
                    var activationErrorTitle = "Enable to activate."
                    var activationErrorSubTitle = "Please enter a valid License key."
                    addLog(text: "Button Activate Clicked :- Enable to activate., invalid Key")
                    if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{
                        if let text = activationNagInfo.value(forKey: "activationErrorTitle") as? String{
                            activationErrorTitle = text
                        }
                        if let text = activationNagInfo.value(forKey: "activationErrorSubTitle") as? String{
                            activationErrorSubTitle = text
                        }
                    }
                    self.dialogOKCancel(title: activationErrorTitle, Message: activationErrorSubTitle)
                }
            }
            
        })
    }

    
    override func viewWillAppear() {
        
        txtFldLicense.stringValue = ""
        btnactivate.isEnabled = false
        lblTrialExpired.isHidden = false

        var daysremaining = 0
//        if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
//            let secondsBetween = Date().timeIntervalSince(date)
//            let numberOfDays_afterinstall = Int((secondsBetween) / 86400)
//            daysremaining = daysFreeTrial-numberOfDays_afterinstall
//            if daysremaining < 0 {
//                daysremaining = 0
//            }
//            if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//                daysremaining = 0
//            }
//            if daysremaining == 0{
//                if UserDefaults.standard.object(forKey: "trialExpired") == nil{
//                    UserDefaults.standard.set(true, forKey: "trialExpired")
//                }
//            }
//        }else{
//            daysremaining = daysFreeTrial
//            
//        }
        
        if daysremaining == 0{
            lblTrialExpired.stringValue = trialExpiredText
            lblTrialExpired.textColor = NSColor.systemRed
        }else{
            lblTrialExpired.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")//"Trial version - \(daysremaining) of 7 trial days remaining"
            lblTrialExpired.textColor = NSColor.labelColor
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        updateActiveLicenseUI()
    }
    func controlTextDidBeginEditing(_ obj: Notification) {
        
    }
    func updateActiveLicenseUI() {
        if txtFldLicense.stringValue.count > 35 {
            txtFldLicense.stringValue = (txtFldLicense?.stringValue as NSString?)?.substring(with: NSRange(location: 0, length: 35)) ?? ""
        }
        
        if self.txtFldLicense.stringValue == ""{
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs = [NSAttributedString.Key.foregroundColor: NSColor.gray, NSAttributedString.Key.paragraphStyle: paragraph]
            let placeHolderStr = NSAttributedString(string: "XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX", attributes: attrs)
            txtFldLicense.placeholderAttributedString = placeHolderStr
            
        }
        if self.txtFldLicense.stringValue.count == 35 && self.txtFldLicense.stringValue != "XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX" {
            btnactivate.isEnabled = true
        } else {
            btnactivate.isEnabled = false
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    
    
    @IBAction func tappedCopiedLicenseKey(_ sender: NSButton) {
        if let licenseKey = NSPasteboard.general.string(forType: .string) {
            if licenseKey.count > 35 {
                txtFldLicense.stringValue = (licenseKey as NSString?)?.substring(with: NSRange(location: 0, length: 35)) ?? ""
            }
            else{
                txtFldLicense.stringValue = licenseKey
            }
            txtFldLicense.selectText(self)
            txtFldLicense.currentEditor()?.selectedRange = NSRange(location: txtFldLicense.stringValue.count, length: 0)
        }
        updateActiveLicenseUI()
    }
    
    func showAlertAfterActivate(title: String, Message:String, isHide:Bool) {
        _ = dialogOKCancel(title: title, Message: Message)
        
    }
    func dialogOKCancel(title: String, Message: String) {
        var buttonOkText = "OK"
        if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{
            if let text = activationNagInfo.value(forKey: "buttonOkText") as? String{
                buttonOkText = text
            }
        }
        
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = title
        alert.informativeText = Message
        alert.alertStyle = .warning
        alert.addButton(withTitle:  buttonOkText)
        alert.beginSheetModal(for: (activationWindowControllerObj?.window)!, completionHandler: nil)
    }

    
    
    func responceMilgaya(){
        spinner.isHidden = true
        spinner.stopAnimation(self)
        btnactivate.isEnabled = true
        btnback.isEnabled = true
        self.view.window?.standardWindowButton(.closeButton)?.isEnabled = true
    }
    
    @IBAction func btnclose(_ sender: Any) {
        //activateNowviewopen = false
        self.view.removeFromSuperview()
        
    }
    @IBAction func btnbackClicked(_ sender: Any) {
        activationWindowControllerObj?.showSevenDayTrialVc()
    }
    
}
