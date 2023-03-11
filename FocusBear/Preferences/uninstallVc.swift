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
    var uninstallingConfirmVcObj: uninstallingConfirmVc?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btUninstall.title = "Uninstall"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            btUninstall.title = common.value(forKey: "buttonUninstallText") as? String ?? "Uninstall"
        }
    }
 
    
    @IBAction func btnUninstallClicked(_ sender: Any) {
        addLog(text: "btn Uninstall in settings Clicked")//

        if self.uninstallingConfirmVcObj == nil{
            self.uninstallingConfirmVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uninstallingConfirmVc")) as? uninstallingConfirmVc
        }
        self.presentAsSheet(self.uninstallingConfirmVcObj!)
    }
    
}

