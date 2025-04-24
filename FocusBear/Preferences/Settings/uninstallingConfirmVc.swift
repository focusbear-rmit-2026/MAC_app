//
//  uninstallingConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class uninstallingConfirmVc: NSViewController, NSTextViewDelegate {
    
    @IBOutlet weak var lblMinimumCharacter: NSTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var scrollView: shadowScrollViewForTextView!
    @IBOutlet weak var btnCancel: NSButton!
    @IBOutlet weak var lblEnterYourEmail: NSTextField!
    @IBOutlet weak var textFieldEmail: NSTextField!
    @IBOutlet weak var popUpButton: NSPopUpButton!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnUninstall: NSButton!
    
    let minimumCharacterCount = 9
    let brokenAppReasonIndex = 1
    let selectReasonIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Uninstalling.."
        lblQuestion.stringValue = "Damn sorry, it seems like we let you down. We're in the early stages of this product and really want to get feedback to make it better. Could you tell us why you're uninstalling?"
        lblMinimumCharacter.stringValue = "(Minimum 10 characters)"
        popUpButton.removeAllItems()
        
        var buttonSelectReasonText = "Select a reason"
        var brokenAppReasonText = "The app is broken"
        var habitsHardReasonText = "My habits are too hard - I can't handle them"
         var doNotUSeEnoughReasonText  = "I don't use it enough"
        var tooExpensiveReasonText  = "Too expensive"
        var missingFeaturesReasonText  = "Missing features"
        var tooComplicatedReasonText = "Too complicated"
        var otherReasonText = "Other"
        
        lblEnterYourEmail.stringValue = "Your Email (if you want us to reply):"
        btnCancel.title = buttonCancelText
        btnUninstall.title = "Uninstall"
        
        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblTitle.stringValue = common.value(forKey: "uninstallingText") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = common.value(forKey: "askUninstallReasonText2") as? String ?? lblQuestion.stringValue
            lblMinimumCharacter.stringValue = common.value(forKey: "minimumCharacterText") as? String ?? lblMinimumCharacter.stringValue
            buttonSelectReasonText = common.value(forKey: "buttonSelectReasonText") as? String ?? buttonSelectReasonText
            brokenAppReasonText = common.value(forKey: "brokenAppReasonText") as? String ?? brokenAppReasonText
            habitsHardReasonText = common.value(forKey: "habitsHardReasonText") as? String ?? habitsHardReasonText
            otherReasonText = common.value(forKey: "otherReasonText") as? String ?? otherReasonText
            doNotUSeEnoughReasonText = common.value(forKey: "doNotUSeEnoughReasonText") as? String ?? doNotUSeEnoughReasonText
            tooExpensiveReasonText = common.value(forKey: "tooExpensiveReasonText") as? String ?? tooExpensiveReasonText
            missingFeaturesReasonText = common.value(forKey: "missingFeaturesReasonText") as? String ?? missingFeaturesReasonText
            tooComplicatedReasonText = common.value(forKey: "tooComplicatedReasonText") as? String ?? tooComplicatedReasonText
            lblEnterYourEmail.stringValue = common.value(forKey: "emailTitle") as? String ?? lblEnterYourEmail.stringValue
            btnUninstall.title = common.value(forKey: "tabUninstallText") as? String ?? btnUninstall.title
        }
        
        popUpButton.addItem(withTitle: buttonSelectReasonText)
        popUpButton.addItem(withTitle: brokenAppReasonText)
        popUpButton.addItem(withTitle: habitsHardReasonText)
        popUpButton.addItem(withTitle: doNotUSeEnoughReasonText)
        popUpButton.addItem(withTitle: tooExpensiveReasonText)
        popUpButton.addItem(withTitle: missingFeaturesReasonText)
        popUpButton.addItem(withTitle: tooComplicatedReasonText)
        popUpButton.addItem(withTitle: otherReasonText)
        
        
        scrollView.shadowRadius = 1.5
        scrollView.shadowOffset = NSMakeSize(0, 2)
        scrollView.shadowOpacity = 0.15
        scrollView.setShadow()
        
        textView.delegate = self   
    }
    override func viewWillAppear() {
        textFieldEmail.stringValue = ""
        popUpButton.selectItem(at: 0)
        btnUninstall.isEnabled = false
        textView.string = ""
    }
    
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textView{
            if textView.string.count > minimumCharacterCount && popUpButton.indexOfSelectedItem != selectReasonIndex{
                btnUninstall.isEnabled = true
            }else{
                btnUninstall.isEnabled = false
            }
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "[user-action] btn Uninstall Cancel in  nag Clicked")//
        self.dismiss(self)
    }
    
    @IBAction func popUpButtonClicked(_ sender: Any) {
        if popUpButton.indexOfSelectedItem != selectReasonIndex && textView.string.count > 9{
            btnUninstall.isEnabled = true
        }else{
            btnUninstall.isEnabled = false
        }
    }
    @IBAction func btnUninstallClicked(_ sender: Any) {
        addLog(text: "[user-action] btn Uninstall in nag Clicked")//
        
        if popUpButton.indexOfSelectedItem == brokenAppReasonIndex{
            let alert: NSAlert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Do you want to upload the logs to our server for us to review what was broken?"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                alert.messageText = common.value(forKey: "alertUploadLogText") as? String ?? alert.messageText
            }
            let yesText = buttonYesText
            let noText = buttonNoText
            
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: yesText)
            alert.addButton(withTitle: noText)
            
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    print("okclicked")
                    addLog(text: "[user-action] btn Upload logs alert yes Clicked")//
                    
                    self.view.addSubview(getLogsUploadingVcObjObj().view)
                    self.view.addConstraints(subView: getLogsUploadingVcObjObj().view)
                    let uninstallReason = self.textView.string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self.textView.string
                    allApiObject.uploadAppLogs(feedback: uninstallReason, completionHandler: {json in 
                        DispatchQueue.main.async {
                            getLogsUploadingVcObjObj().view.removeFromSuperview()
                            self.showAppCloseAlert()
                        }
                    })
                }else{
                    self.showAppCloseAlert()
                }
            })
        }else{
            self.showAppCloseAlert()
        }
    }
    
    
    func showAppCloseAlert(){
        var alert = NSAlert()
        alert.setSharingType()
        
        var uninstallDoneText = "All the app related processes will abort and the app will close itself and then you can drag the app and move to trash/bin."
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            uninstallDoneText = common.value(forKey: "uninstallDoneText") as? String ?? uninstallDoneText
        }
        
        alert.messageText = uninstallDoneText
        alert.addButton(withTitle: buttonOkText)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                
                
                alert = NSAlert()
                alert.setSharingType()
                
                var reminderText = "Quick reminder: you need to drag the Focus Bear from the Applications folder to Trash to fully uninstall the app."
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    reminderText = common.value(forKey: "reminderUninstallText") as? String ?? uninstallDoneText
                }
                allApiObject.capturePosthog(event: "uninstall", metadata: ["emailAddress":currentUserEmail, "uninstallReason":self.popUpButton.titleOfSelectedItem ?? "", "uninstallDescription":self.textView.string, "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
                alert.messageText = reminderText
                alert.addButton(withTitle: buttonOkText)
                
                
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                        print("okclicked")
                        self.dismiss(self)
                        self.uninstallApp()
                        
                    }
                })

            }
        })
    }
    
    func uninstallApp(){
        
        addLog(text: "App uninstall clicked by user")
        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        appdelegate!.user = nil
        let _ = appdelegate!.credentialsManager.clear()
        appdelegate!.credential = nil
        self.clearAllData()
        appdelegate!.terminateFromSelf = true
        quitApplicationSmoothly()
      //  allApiObject.getUninstallJsonToUpload(emailAddress: currentUserEmail, uninstallReason: popUpButton.titleOfSelectedItem ?? "", uninstallDescription: textView.string, completionHandler: {dic in
        //    DispatchQueue.main.async {
                
           // }
       // })
    }
    
    func clearAllData(){
        let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey,URLResourceKey.nameKey]
        let array = try? FileManager.default.contentsOfDirectory(at: appdelegate!.applicationSupportURL!, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
        if array != nil{
            for url in array!{
                
                if url.path.lowercased() != DebugLogsFolderURL.path.lowercased(){
                    do{
                        try FileManager.default.removeItem(at: url)
                    }catch{
                        print(error)
                    }
                }
            }
        }
        
        var firstRun:Bool?
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) as? Bool{
            firstRun = val
        }
        
//        var firstVideoShown:Bool?
//        if let val = UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) as? Bool{
//            firstVideoShown = val
//        }
        
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        
        if firstRun != nil{
            UserDefaults.standard.set(firstRun!, forKey: kUserdefaultsFirstRun)
        }

//        if firstVideoShown != nil{
//            UserDefaults.standard.set(firstVideoShown!, forKey: kUserdefaultsVideoShown)
//        }
        
        UserDefaults.standard.synchronize()
    }
}

