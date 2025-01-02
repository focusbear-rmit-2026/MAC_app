//
//  alertLimitedUsageVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/07/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class alertLimitedUsageVc: NSViewController {

    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnUpgradeNow: Button!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnContinue.buttonColor = NSColor.white.cgColor
       
        
        var title = "You are running the Basic FREE Version of Focus Bear"
        var subTitle = "Basic version limits the number of habits to <COUNT> per routine. You'll be able to do your first <COUNT> habits. Upgrade to unlock unlimited access and other premioum features."
        var buttonUpgradeNowText = "Upgrade now"
        var buttonContinueText = "Continue with Basic Version"
        
        
        
        if let alertLimitedUsageVcInfo = configjson.value(forKey: "alertLimitedUsageVcInfo") as? NSDictionary{
            title = alertLimitedUsageVcInfo.value(forKey: "title") as? String ?? title
            subTitle = alertLimitedUsageVcInfo.value(forKey: "subTitle") as? String ?? subTitle
            buttonUpgradeNowText = alertLimitedUsageVcInfo.value(forKey: "buttonUpgradeNowText") as? String ?? buttonUpgradeNowText
            buttonContinueText = alertLimitedUsageVcInfo.value(forKey: "buttonContinueText") as? String ?? buttonContinueText
        }
        
        subTitle = subTitle.replacingOccurrences(of: "<COUNT>", with: "\(activitiesCountInExpireApp)")
        lblTitle.stringValue = title
        lblSubTitle.stringValue = subTitle
        btnUpgradeNow.title = buttonUpgradeNowText
        btnContinue.title = buttonContinueText
    }
    
    @IBAction func btnUpgradeNowClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "alert-limited-usage-button-upgrade-clicked", metadata: [:])
        self.dismiss(self)
        // doNot CurrentState Here
        mainWindowControllerObj?.window?.close()
        hideBlankWindowInSecondaryMonitor()
        showUpgradeNowWindow()
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                upgradeNowVcObj?.vcShownFromExpireUsageAlert = true
                upgradeNowVcObj?.btnUpgradeNowClicked(self)
            }
        }
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "alert-limited-usage-button-continue-clicked", metadata: [:])
        self.dismiss(self)
        firstViewControllerObj?.showConfirmRoutineDurationViewIfNeeded()
    }
}
