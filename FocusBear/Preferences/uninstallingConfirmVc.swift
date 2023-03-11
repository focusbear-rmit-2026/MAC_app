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
        var otherReasonText = "Other"
        
        lblEnterYourEmail.stringValue = "Your Email (if you want us to reply):"
        btnCancel.title = buttonCancelText
        btnUninstall.title = "Uninstall"
        
        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblTitle.stringValue = common.value(forKey: "uninstallingText") as? String ?? lblTitle.stringValue
//            lblQuestion.stringValue = common.value(forKey: "askUninstallReasonText") as? String ?? lblQuestion.stringValue
            lblQuestion.stringValue = common.value(forKey: "askUninstallReasonText2") as? String ?? lblQuestion.stringValue
            lblMinimumCharacter.stringValue = common.value(forKey: "minimumCharacterText") as? String ?? lblMinimumCharacter.stringValue
            buttonSelectReasonText = common.value(forKey: "buttonSelectReasonText") as? String ?? buttonSelectReasonText
            brokenAppReasonText = common.value(forKey: "brokenAppReasonText") as? String ?? brokenAppReasonText
            habitsHardReasonText = common.value(forKey: "habitsHardReasonText") as? String ?? habitsHardReasonText
            otherReasonText = common.value(forKey: "otherReasonText") as? String ?? otherReasonText
            lblEnterYourEmail.stringValue = common.value(forKey: "emailTitle") as? String ?? lblEnterYourEmail.stringValue
            btnUninstall.title = common.value(forKey: "tabUninstallText") as? String ?? btnUninstall.title
        }
        
        popUpButton.addItem(withTitle: buttonSelectReasonText)
        popUpButton.addItem(withTitle: brokenAppReasonText)
        popUpButton.addItem(withTitle: habitsHardReasonText)
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
            if textView.string.count > 9 && popUpButton.indexOfSelectedItem != 0{
                btnUninstall.isEnabled = true
            }else{
                btnUninstall.isEnabled = false
            }
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "btn Uninstall Cancel in  nag Clicked")//
        self.dismiss(self)
    }
    
    @IBAction func popUpButtonClicked(_ sender: Any) {
        if popUpButton.indexOfSelectedItem != 0 && textView.string.count > 9{
            btnUninstall.isEnabled = true
        }else{
            btnUninstall.isEnabled = false
        }
    }
    @IBAction func btnUninstallClicked(_ sender: Any) {
        addLog(text: "btn Uninstall in nag Clicked")//
        var alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to giveup all your habits and uninstall Focus Bear?"
        var yesText = "Yes"
        var noText = "No"
        var uninstallDoneText = "All the app related processes will abort and the app will close itself and then you can drag the app and move to trash/bin."
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            alert.messageText = common.value(forKey: "uninstallConfirmText") as? String ?? alert.messageText
            yesText = common.value(forKey: "yesText") as? String ?? yesText
            noText = common.value(forKey: "noText") as? String ?? noText
            uninstallDoneText = common.value(forKey: "uninstallDoneText") as? String ?? uninstallDoneText
        }
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: yesText)
        alert.addButton(withTitle: noText)


        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                addLog(text: "btn Uninstall alert yes Clicked")//
                alert = NSAlert()
                alert.setSharingType()
                alert.messageText = uninstallDoneText
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
        allApiObject.capturePosthog(event: "uninstall", metadata: [:])
        allApiObject.getUninstallJsonToUpload(emailAddress: currentUserEmail, uninstallReason: popUpButton.titleOfSelectedItem ?? "", uninstallDescription: textView.string, completionHandler: {dic in
            DispatchQueue.main.async {
                addLog(text: "App uninstall clicked by user")
                shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
                appdelegate!.user = nil
                let _ = appdelegate!.credentialsManager.clear()
                appdelegate!.credential = nil
                
                self.clearAllData()
                appdelegate!.terminateFromSelf = true
                NSApp.terminate(self)
            }
        })
        
    }
    
    func clearAllData(){
        do{
            try FileManager.default.removeItem(at: appdelegate!.applicationSupportURL!)
        }catch{
            print(error)
        }
        
        var firstRun:Bool?
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) as? Bool{
            firstRun = val
        }
        
        var firstVideoShown:Bool?
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) as? Bool{
            firstVideoShown = val
        }
        
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        
        if firstRun != nil{
            UserDefaults.standard.set(firstRun!, forKey: kUserdefaultsFirstRun)
        }
        
        
        if firstVideoShown != nil{
            UserDefaults.standard.set(firstVideoShown!, forKey: kUserdefaultsVideoShown)
        }
        
        

        UserDefaults.standard.synchronize()
//        LaunchOnStartup.setLaunchAtStartup(false)
    }
}

