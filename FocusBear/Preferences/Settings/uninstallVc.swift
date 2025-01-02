//
//  uninstallVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 04/05/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class uninstallVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btUninstall: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btUninstall.title = "Uninstall"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            btUninstall.title = common.value(forKey: "buttonUninstallText") as? String ?? "Uninstall"
        }
        
        arrForSearchFromSettings.append(["title": btUninstall.title, "tabId": idUninstall, "object": btUninstall as Any])
        arrForSearchFromSimpleModeSettings.append(["title": btUninstall.title, "tabId": idUninstall, "object": btUninstall as Any])
    }
 
    override func viewWillAppear() {
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitle.stringValue = ""
            }else{
                lblTitle.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitle.stringValue = ""
        }
    }
    @IBAction func btnUninstallClicked(_ sender: Any) {
        addLog(text: "[user-action] btn Uninstall in settings Clicked")//

        let alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to giveup all your habits and uninstall Focus Bear?"
        var yesText = "Yes"
        var noText = "No"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            alert.messageText = common.value(forKey: "uninstallConfirmText") as? String ?? alert.messageText
            yesText = common.value(forKey: "yesText") as? String ?? yesText
            noText = common.value(forKey: "noText") as? String ?? noText
        }
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: yesText)
        alert.addButton(withTitle: noText)


        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                addLog(text: "[user-action] btn Uninstall alert yes Clicked")//
                if uninstallingConfirmVcObj == nil{
                    uninstallingConfirmVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uninstallingConfirmVc")) as? uninstallingConfirmVc
                }
                self.presentAsSheet(uninstallingConfirmVcObj!)
                
                
            }
        })
        
    }
    
}

