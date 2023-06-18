//
//  uninstallVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 04/05/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
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
        
        arrForSearchFromSettings.append(["title": btUninstall.title, "tabId": idUninstall, "object": btUninstall as Any])
    }
 
    override func viewWillAppear() {
        preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: 630 + 46, height: 382 + 142))
    }
    @IBAction func btnUninstallClicked(_ sender: Any) {
        addLog(text: "btn Uninstall in settings Clicked")//

        if uninstallingConfirmVcObj == nil{
            uninstallingConfirmVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uninstallingConfirmVc")) as? uninstallingConfirmVc
        }
        self.presentAsSheet(uninstallingConfirmVcObj!)
    }
    
}

