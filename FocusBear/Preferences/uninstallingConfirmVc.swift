//
//  uninstallingConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class uninstallingConfirmVc: NSViewController {

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
        lblQuestion.stringValue = "Can you share why you're uninstalling?"
        
        popUpButton.removeAllItems()
        
        var buttonSelectReasonText = "Select a reason"
        var brokenAppReasonText = "The app is broken"
        var habitsHardReasonText = "My habits are too hard - I can't handle them"
        
        
        lblEnterYourEmail.stringValue = "Your Email (if you want us to reply):"
        btnCancel.title = buttonCancelText
        btnUninstall.title = "Uninstall"
        
        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblTitle.stringValue = common.value(forKey: "uninstallingText") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = common.value(forKey: "askUninstallReasonText") as? String ?? lblQuestion.stringValue
            buttonSelectReasonText = common.value(forKey: "buttonSelectReasonText") as? String ?? buttonSelectReasonText
            brokenAppReasonText = common.value(forKey: "brokenAppReasonText") as? String ?? brokenAppReasonText
            habitsHardReasonText = common.value(forKey: "habitsHardReasonText") as? String ?? habitsHardReasonText
            lblEnterYourEmail.stringValue = common.value(forKey: "emailTitle") as? String ?? lblEnterYourEmail.stringValue
            btnUninstall.title = common.value(forKey: "tabUninstallText") as? String ?? btnUninstall.title
        }
        
        popUpButton.addItem(withTitle: buttonSelectReasonText)
        popUpButton.addItem(withTitle: brokenAppReasonText)
        popUpButton.addItem(withTitle: habitsHardReasonText)
        
    }
    override func viewWillAppear() {
        textFieldEmail.stringValue = ""
        popUpButton.selectItem(at: 0)
        btnUninstall.isEnabled = false
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text: "btn Uninstall Cancel in  nag Clicked")//
        self.dismiss(self)
    }
    
    @IBAction func popUpButtonClicked(_ sender: Any) {
        if popUpButton.indexOfSelectedItem == 0{
            btnUninstall.isEnabled = false
        }else{
            btnUninstall.isEnabled = true
        }
    }
    @IBAction func btnUninstallClicked(_ sender: Any) {
        addLog(text: "btn Uninstall in nag Clicked")//
        var alert: NSAlert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alert.window.sharingType = .none
            }
        }
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
                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alert.window.sharingType = .none
                    }
                }
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
        allApiObject.getUninstallJsonToUpload(emailAddress: appdelegate?.user?.email ?? "", uninstallReason: popUpButton.titleOfSelectedItem ?? "", completionHandler: {dic in
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
        
        var firstDate:Date?
        if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
            firstDate = date
        }
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        
        
        UserDefaults.standard.set(firstDate, forKey: kUserdefaultsFirstHabitDay)

        UserDefaults.standard.synchronize()
        LaunchOnStartup.setLaunchAtStartup(false)
    }
}

