//
//  settingsSplitViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class settingsSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        addLog(text: "settingsSplitViewController viewdidload")
    }
    
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
}
