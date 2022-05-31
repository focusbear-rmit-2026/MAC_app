//
//  uninstallVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 04/05/22.
//  Copyright © 2022 Earn Your Screen Time. All rights reserved.
//

import Cocoa

class uninstallVc: NSViewController {

    @IBOutlet weak var btUninstall: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btUninstall.title = "Uninstall"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            btUninstall.title = common.value(forKey: "buttonUninstallText") as? String ?? "Uninstall"
        }
    }
 
    func clearAllData(){
        
        var firstDate:Date?
        if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
            firstDate = date
        }
        let domain = Bundle.main.bundleIdentifier!//todo
        UserDefaults.standard.removePersistentDomain(forName: domain)
        
        
        UserDefaults.standard.set(firstDate, forKey: kUserdefaultsFirstHabitDay)
        
        
        UserDefaults.standard.synchronize()
        LaunchOnStartup.setLaunchAtStartup(false)
    }
    @IBAction func btnUninstallClicked(_ sender: Any) {
        
        var alert: NSAlert = NSAlert()
        alert.messageText = "Are you sure you want to giveup all your habits and uninstall Earn Your Screen Time?"
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
        
        //            alert.runModal()
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                alert = NSAlert()
                alert.messageText = uninstallDoneText
                alert.addButton(withTitle: buttonOkText)
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                        print("okclicked")
                        
                        addLog(text: "App uninstall clicked by user")
                        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
                        self.clearAllData()
                        appdelegate!.terminateFromSelf = true
                        NSApp.terminate(self)
                    }
                })
            }
        })
        
    }
}

