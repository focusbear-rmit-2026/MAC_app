//
//  deactivateBreaksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/06/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class deactivateBreaksVc: NSViewController {

    @IBOutlet weak var btnTurnBreaksOff: underLineButton!
    @IBOutlet weak var btnKeepThemOn: Button!
    @IBOutlet weak var btnTurnOffForToday: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Do you want to turn breaks off completely?"
        btnTurnOffForToday.title = "Turn them off for today"
        btnKeepThemOn.title = "Keep them on"
        btnTurnBreaksOff.title = "Turn breaks off completely"
        
        if let deactivateBreaksVcInfo = configjson.value(forKey: "deactivateBreaksVcInfo") as? NSDictionary{
            lblTitle.stringValue = deactivateBreaksVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnTurnOffForToday.title = deactivateBreaksVcInfo.value(forKey: "buttonTurnOffForTodayText") as? String ?? btnTurnOffForToday.title
            btnKeepThemOn.title = deactivateBreaksVcInfo.value(forKey: "buttonKeepThemOnText") as? String ?? btnKeepThemOn.title
            btnTurnBreaksOff.title = deactivateBreaksVcInfo.value(forKey: "buttonTurnBreaksOffText") as? String ?? btnTurnBreaksOff.title
        }
        btnTurnOffForToday.isSecondaryButton = true
    }
    
    @IBAction func btnTurnOffForTodayClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "disable-breaks-for-today", metadata: [:])
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsDisableBreaksForToday)

        // Track consecutive break-off days and prompt to increase frequency if
        // the user has turned off breaks for 2 days in a row (#1144).
        BreakFrequencyStreakTracker.shared.recordBreaksOffForToday()

        self.view.window?.close()
    }
    
    @IBAction func btnKeepThemOnClicked(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func btnTurnBreaksOffClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "settings-changed-disable-breaks", metadata: [:])
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isMicroBreaksEnabled = false
        SettingsManagerObject.putUserLocalDeviceSettings()
        self.view.window?.close()
    }
}
