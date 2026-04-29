//
//  upgradeNowVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class upgradeNowVc: NSViewController {

    @IBOutlet weak var btnContinue: underLineButton!
    @IBOutlet weak var btnUserId: NSButton!
    @IBOutlet weak var lblTitleUserId: NSTextField!
    @IBOutlet weak var textFieldUserId: NSTextField!
    @IBOutlet weak var lblSubscriptionExpired: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnRestorePurchases: Button!
    @IBOutlet weak var lblSyncInfo: NSTextField!
    @IBOutlet weak var lblMoneyBack: NSTextField!
    @IBOutlet weak var btnUpgradeNow: Button!
    @IBOutlet weak var lblPointFourth: NSTextField!
    @IBOutlet weak var lblPointThird: NSTextField!
    @IBOutlet weak var lblPointSecond: NSTextField!
    @IBOutlet weak var lblPointFirst: NSTextField!
    @IBOutlet weak var lblTitleAppName: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var btnInfo: hoverInfoButton!
    
    var vcShownFromExpireUsageAlert = false
    var isViewVisible = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
       
        btnRestorePurchases.isSecondaryButton = true
        
        
        let buttonBlueColor = NSColor(red: 52/255, green: 175/255, blue: 233/255, alpha: 1)
        let buttonDarkBlueColor = NSColor(red: 34/255, green: 126/255, blue: 230/255, alpha: 1)
        btnUpgradeNow.borderColor = buttonBlueColor.cgColor
        btnUpgradeNow.buttonColor = buttonBlueColor.cgColor
        btnUpgradeNow.titleColor = NSColor.white
        btnUpgradeNow.buttonDownColor = buttonDarkBlueColor.cgColor
        
        textFieldUserId.isEditable = false
        textFieldUserId.isSelectable = true
        btnContinue.title = "Continue with limited features"
        btnUserId.toolTip = "Copy user id"
        lblTitleUserId.stringValue = "Your user id:"
        
        
        lblTitleAppName.stringValue = appName
        lblPointFirst.stringValue = "Personalized habit routines"
        lblPointSecond.stringValue = "Productivity-boosting breaks"
        lblPointThird.stringValue = "Customizable focus modes"
        lblPointFourth.stringValue = "Automatic goal tracking"
        btnUpgradeNow.title = "Upgrade Now"
        lblMoneyBack.stringValue = "30 days money back guarantee"
        lblSyncInfo.stringValue = "After you pay, click the Sync Payment Status button below"
        btnRestorePurchases.title = "Sync Payment Status"
        lblSubscriptionExpired.stringValue = "Your subscription has expired"
        
        
        if let upgradeNowVcInfo = configjson.value(forKey: "upgradeNowVcInfo") as? NSDictionary{
            lblPointFirst.stringValue = upgradeNowVcInfo.value(forKey: "pointFirstText") as? String ?? lblPointFirst.stringValue
            lblPointSecond.stringValue = upgradeNowVcInfo.value(forKey: "pointSecondText") as? String ?? lblPointSecond.stringValue
            lblPointThird.stringValue = upgradeNowVcInfo.value(forKey: "pointThirdText") as? String ?? lblPointThird.stringValue
            lblPointFourth.stringValue = upgradeNowVcInfo.value(forKey: "pointFourthText") as? String ?? lblPointFourth.stringValue
            btnUpgradeNow.title = upgradeNowVcInfo.value(forKey: "buttonUpgradeNowText") as? String ?? btnUpgradeNow.title
            lblMoneyBack.stringValue = upgradeNowVcInfo.value(forKey: "moneyBackText") as? String ?? lblMoneyBack.stringValue
            lblSyncInfo.stringValue = upgradeNowVcInfo.value(forKey: "syncInfoText") as? String ?? lblSyncInfo.stringValue
            btnRestorePurchases.title = upgradeNowVcInfo.value(forKey: "buttonRestoreText") as? String ?? btnRestorePurchases.title
            lblSubscriptionExpired.stringValue = upgradeNowVcInfo.value(forKey: "subscriptionExpiredText") as? String ?? lblSubscriptionExpired.stringValue
            
            btnUserId.toolTip = upgradeNowVcInfo.value(forKey: "toolTipCopyId") as? String ?? btnUserId.toolTip
            lblTitleUserId.stringValue = upgradeNowVcInfo.value(forKey: "titleUserId") as? String ?? lblTitleUserId.stringValue
            btnContinue.title = upgradeNowVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
    }
    
    override func viewWillAppear() {
        addLog(text: "upgradeNowVc:- viewWillAppear.")
        if !isPurchased && daysLeft <= 0{
            lblSubscriptionExpired.isHidden = false
        }else{
            lblSubscriptionExpired.isHidden = true
        }
        textFieldUserId.stringValue = appdelegate!.user?.userId ?? ""
        isViewVisible = true
    }
    
    override func viewWillDisappear() {
        isViewVisible = false
    }
    
    func closeView(){
        if isViewVisible{
            if let window = self.view.window {
                if let _ = window.sheetParent {
                    self.dismiss(self)
                } else if window.contentViewController === self {
                    self.view.window?.close()
                } else {
                    self.view.window?.close()// no chance
                }
            }
        }
    }
    
    @IBAction func btnUserIdClicked(_ sender: Any) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(appdelegate!.user?.userId ?? "", forType: .string)
        
        var msg = "Copied"
        if let upgradeNowVcInfo = configjson.value(forKey: "upgradeNowVcInfo") as? NSDictionary{
            msg = upgradeNowVcInfo.value(forKey: "toolTipCopied") as? String ?? msg
        }
        showTooltip(sender: btnUserId, msg: msg, preferredEdge: NSRectEdge.minY, maxWidthVal:230)
        DispatchQueue.global().async {
            sleep(2)
            DispatchQueue.main.async {
                popoverTooltip?.close()
            }
        }
    }
    
    @IBAction func btnUpgradeNowClicked(_ sender: Any) {
        addLog(text: "[user-action] btnUpgradeNowClicked.")
        allApiObject.capturePosthog(event: "upgrade-nag-button-upgrade-clicked", metadata: [:])
//        let buynow_path = upgradeNowUrl
//        NSWorkspace.shared.open(URL(string: buynow_path)!)
        self.presentAsSheet(getManageSubscriptionVcObject())
        
//        upgradeButtonWasClicked = true// 
    }
    
    @IBAction func btnRestorePurchasesClicked(_ sender: Any) {
        addLog(text: "[user-action] btnRestorePurchasesClicked.")
        allApiObject.capturePosthog(event: "sync-payment-status", metadata: ["from":"upgrade_nag"])
        self.loader.startAnimation(self)
        self.btnRestorePurchases.isEnabled = false
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnRestorePurchases.isEnabled = true

                if daysLeft > 0{
//                    self.view.window?.close()
                    self.closeView()
                }
                
                if !isPurchased && daysLeft <= 0{
                    self.lblSubscriptionExpired.isHidden = false
                }else{
                    self.lblSubscriptionExpired.isHidden = true
                }
                
            }
            
        })
    }
    
    func syncPaymentStatus(){
        self.loader.startAnimation(self)
        self.btnRestorePurchases.isEnabled = false
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnRestorePurchases.isEnabled = true

                if daysLeft > 0{
//                    self.view.window?.close()
                    self.closeView()
                }
                
                if !isPurchased && daysLeft <= 0{
                    self.lblSubscriptionExpired.isHidden = false
                }else{
                    self.lblSubscriptionExpired.isHidden = true
                }
                
            }
            
        })
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] btnContinueClicked.")
        allApiObject.capturePosthog(event: "upgrade-nag-button-continue-clicked", metadata: [:])
        self.closeView()
        if !isAppInitialLodded{
            appdelegate?.initialWork()
        }
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_) && vcShownFromExpireUsageAlert{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            leftMenuVcObj?.showHabitsView()
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                firstViewControllerObj?.showConfirmRoutineDurationViewIfNeeded()
            }
        }
        vcShownFromExpireUsageAlert = false
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        
        var titleBasicVersion = "Basic Version allow you access to limited features"
        var pointSimplePomodoroText = "* Simple Pomodoro"
        var pointLimitedBlockText = "* Block up to <COUNT> websites & apps"
        var pointLimitedHabitsText = "* Limited Morning & Evening Routines"
        var pointLimitedMicroBreaksText = "* Limited Micro-Breaks"
        var pointNoGeekModeText = "* No access to Geek Mode"
        
        if let upgradeNowVcInfo = configjson.value(forKey: "upgradeNowVcInfo") as? NSDictionary{
            titleBasicVersion = upgradeNowVcInfo.value(forKey: "titleBasicVersion") as? String ?? titleBasicVersion
            pointSimplePomodoroText = upgradeNowVcInfo.value(forKey: "pointSimplePomodoroText") as? String ?? pointSimplePomodoroText
            pointLimitedBlockText = upgradeNowVcInfo.value(forKey: "pointLimitedBlockText") as? String ?? pointLimitedBlockText
            pointLimitedHabitsText = upgradeNowVcInfo.value(forKey: "pointLimitedHabitsText") as? String ?? pointLimitedHabitsText
            pointLimitedMicroBreaksText = upgradeNowVcInfo.value(forKey: "pointLimitedMicroBreaksText") as? String ?? pointLimitedMicroBreaksText
            pointNoGeekModeText = upgradeNowVcInfo.value(forKey: "pointNoGeekModeText") as? String ?? pointNoGeekModeText
        }
        
        
        pointLimitedBlockText = pointLimitedBlockText.replacingOccurrences(of: "<COUNT>", with: "\(alwaysBlockedUrlsCountInExpireApp)")
        
        var msg = titleBasicVersion

        msg = msg + "\n\n"
        msg = msg + pointSimplePomodoroText
        
        msg = msg + "\n"
        msg = msg + pointLimitedBlockText
        
        
        msg = msg + "\n"
        msg = msg + pointLimitedHabitsText
        
        
        msg = msg + "\n"
        msg = msg + pointLimitedMicroBreaksText
        
        msg = msg + "\n"
        msg = msg + pointNoGeekModeText
        
        
//        if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
//            msg = setIntentionBlockedUrlsVcInfo.value(forKey: "privacyNoteText") as? String ?? msg
//        }
        showTooltip(sender: btnInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}
