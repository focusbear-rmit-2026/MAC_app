//
//  upgradeToProNagVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/07/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa


class upgradeToProNagVc: NSViewController {

    @IBOutlet weak var bottomSpaceTitleKeepRunning: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceTitle: NSLayoutConstraint!
    @IBOutlet weak var topSpaceTitle: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceTitleBasic: NSLayoutConstraint!
    @IBOutlet weak var topSpaceTitleBasic: NSLayoutConstraint!
    @IBOutlet weak var stackViewRightSide: NSStackView!
    @IBOutlet weak var stackViewLeftSide: NSStackView!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblAi: NSTextField!
    @IBOutlet weak var lblUnlimitedBlocking: NSTextField!
    @IBOutlet weak var lblSuperPomodoro: NSTextField!
    @IBOutlet weak var lblGeekMode: NSTextField!
    @IBOutlet weak var lblPro: NSTextField!
    @IBOutlet weak var lblEverything: NSTextField!
    @IBOutlet weak var btnUpgradeNow: Button!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblFree: NSTextField!
    @IBOutlet weak var lblToDoList: NSTextField!
    @IBOutlet weak var lblBrowserTabLimiter: NSTextField!
    @IBOutlet weak var lblLimitedMicroBreaks: NSTextField!
    @IBOutlet weak var lblLimitedHabits: NSTextField!
    @IBOutlet weak var lblBlock5AppsUrls: NSTextField!
    @IBOutlet weak var lblPomodoro: NSTextField!
    @IBOutlet weak var lblSimpleMode: NSTextField!
    @IBOutlet weak var lblKeepYouRunning: NSTextField!
    @IBOutlet weak var lblBasic: NSTextField!
    @IBOutlet weak var lblFocusModes: NSTextField!
    @IBOutlet weak var lblFocusMusic: NSTextField!
    @IBOutlet weak var lblMeetingDetection: NSTextField!
    @IBOutlet weak var lblPartnerPassword: NSTextField!
    @IBOutlet weak var lblCustomizableStrictnessLevel: NSTextField!
    @IBOutlet weak var lblAddOns: NSTextField!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "You're currently using the Basic version of Focus Bear, which offers limited features. Consider upgrading to the Pro version for access to unlimited blocking, habits, and other premium features to maximize your productivity."
        
        lblBasic.stringValue = "Basic"
        lblPro.stringValue = "Pro"
        lblKeepYouRunning.stringValue = "To keep you running"
        lblEverything.stringValue = "Everything In Basic plus..."
        
        lblSimpleMode.stringValue = "Simple mode"
        lblPomodoro.stringValue = "Focus Session"
        var pointLimitedBlockText = "Block up to <COUNT> websites & apps"
        lblLimitedHabits.stringValue = "Morning & Evening Routines With Limited habits"
        lblLimitedMicroBreaks.stringValue = "Micro-Breaks with Limited activities"
        lblBrowserTabLimiter.stringValue = "Browser Tab Limiter"
        lblToDoList.stringValue = "To-Do List"
        lblFree.stringValue = "FREE"
        
        lblGeekMode.stringValue = "GEEK Mode"
        lblSuperPomodoro.stringValue = "Super Focus Session"
        lblUnlimitedBlocking.stringValue = "Unlimited Blocking"
        lblAi.stringValue = "Al Blocking"
        lblFocusModes.stringValue = "Focus Modes"
        lblFocusMusic.stringValue = "Focus Music"
        lblMeetingDetection.stringValue = "Meeting Detection"
        lblPartnerPassword.stringValue = "Partner Password"
        lblCustomizableStrictnessLevel.stringValue = "Customizable Strictness Levels"
        lblAddOns.stringValue = "Other Add-Ons"
        
        btnContinue.title = "Continue with Limited Features"
        btnUpgradeNow.title = "Upgrade now"

        if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
            lblTitle.stringValue = upgradeToProNagVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblBasic.stringValue = upgradeToProNagVcInfo.value(forKey: "basicVersionTitle") as? String ?? lblBasic.stringValue
            lblPro.stringValue = upgradeToProNagVcInfo.value(forKey: "proVersionTitle") as? String ?? lblPro.stringValue
            lblKeepYouRunning.stringValue = upgradeToProNagVcInfo.value(forKey: "keepRunningText") as? String ?? lblKeepYouRunning.stringValue
            lblEverything.stringValue = upgradeToProNagVcInfo.value(forKey: "allInProVersionText") as? String ?? lblEverything.stringValue
            lblSimpleMode.stringValue = upgradeToProNagVcInfo.value(forKey: "pointSimplePomodoroText") as? String ?? lblSimpleMode.stringValue
            lblPomodoro.stringValue = upgradeToProNagVcInfo.value(forKey: "pointPomodoroText") as? String ?? lblPomodoro.stringValue
            pointLimitedBlockText = upgradeToProNagVcInfo.value(forKey: "pointLimitedBlockText") as? String ?? pointLimitedBlockText
            lblLimitedHabits.stringValue = upgradeToProNagVcInfo.value(forKey: "pointLimitedHabitsText") as? String ?? lblLimitedHabits.stringValue
            lblLimitedMicroBreaks.stringValue = upgradeToProNagVcInfo.value(forKey: "pointLimitedMicroBreaksText") as? String ?? lblLimitedMicroBreaks.stringValue
            lblBrowserTabLimiter.stringValue = upgradeToProNagVcInfo.value(forKey: "pointBrowserTabLimiterText") as? String ?? lblBrowserTabLimiter.stringValue
            lblToDoList.stringValue = upgradeToProNagVcInfo.value(forKey: "pointToDoListText") as? String ?? lblToDoList.stringValue
            lblFree.stringValue = upgradeToProNagVcInfo.value(forKey: "freeText") as? String ?? lblFree.stringValue
            
            lblGeekMode.stringValue = upgradeToProNagVcInfo.value(forKey: "pointGeekModeText") as? String ?? lblGeekMode.stringValue
            lblSuperPomodoro.stringValue = upgradeToProNagVcInfo.value(forKey: "pointSuperPomodoroText") as? String ?? lblSuperPomodoro.stringValue
            lblUnlimitedBlocking.stringValue = upgradeToProNagVcInfo.value(forKey: "pointUnlimitedBlockingText") as? String ?? lblUnlimitedBlocking.stringValue
            lblAi.stringValue = upgradeToProNagVcInfo.value(forKey: "pointAlBlockingText") as? String ?? lblAi.stringValue
            lblFocusModes.stringValue = upgradeToProNagVcInfo.value(forKey: "pointFocusModesText") as? String ?? lblFocusModes.stringValue
            lblFocusMusic.stringValue = upgradeToProNagVcInfo.value(forKey: "pointFocusMusicText") as? String ?? lblFocusMusic.stringValue
            lblMeetingDetection.stringValue = upgradeToProNagVcInfo.value(forKey: "pointMeetingDetectionText") as? String ?? lblMeetingDetection.stringValue
            lblPartnerPassword.stringValue = upgradeToProNagVcInfo.value(forKey: "pointPartnerPasswordText") as? String ?? lblPartnerPassword.stringValue
            lblCustomizableStrictnessLevel.stringValue = upgradeToProNagVcInfo.value(forKey: "pointCustomizableStrictnessText") as? String ?? lblCustomizableStrictnessLevel.stringValue
            lblAddOns.stringValue = upgradeToProNagVcInfo.value(forKey: "pointAddOnsText") as? String ?? lblAddOns.stringValue
            
            btnContinue.title = upgradeToProNagVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            btnUpgradeNow.title = upgradeToProNagVcInfo.value(forKey: "buttonUpgradeNowText") as? String ?? btnUpgradeNow.title
        }
        pointLimitedBlockText = pointLimitedBlockText.replacingOccurrences(of: "<COUNT>", with: "\(alwaysBlockedUrlsCountInExpireApp)")
        lblBlock5AppsUrls.stringValue = pointLimitedBlockText
        
        btnContinue.buttonColor = NSColor.clear.cgColor
        
        var fontSizefourteen:CGFloat = 14
        var fontSizeFifteen:CGFloat = 15
        var fontSizeSixteen:CGFloat = 16
        var fontSizeSeventeen:CGFloat = 17
        var fontSizeThirtyThree:CGFloat = 33
        var fontSizeTwentyFour:CGFloat = 24
        
        stackViewLeftSide.spacing = 8
        stackViewRightSide.spacing = 8
        
        
        if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
            fontSizefourteen = 12
            fontSizeFifteen = 13
            fontSizeSixteen = 14
            fontSizeSeventeen = 14
            fontSizeThirtyThree = 26
            fontSizeTwentyFour = 22
            stackViewLeftSide.spacing = 0
            stackViewRightSide.spacing = 0
            
            topSpaceTitle.constant = 15
            bottomSpaceTitle.constant = 5
            topSpaceTitleBasic.constant = 2
            bottomSpaceTitleBasic.constant = 2
            bottomSpaceTitleKeepRunning.constant = 2
        }else if SettingsManagerObject.selectedFontIndex == poppinsIndex{
            topSpaceTitle.constant = 25
            bottomSpaceTitle.constant = 10
            topSpaceTitleBasic.constant = 10
            bottomSpaceTitleBasic.constant = 5
            bottomSpaceTitleKeepRunning.constant = 10
        }else{
            topSpaceTitle.constant = 30
            bottomSpaceTitle.constant = 15
            topSpaceTitleBasic.constant = 20
            bottomSpaceTitleBasic.constant = 12
            bottomSpaceTitleKeepRunning.constant = 18
        }
        lblTitle.font = getRegularFont(size: fontSizeSeventeen)

        lblBasic.font = getBoldFont(size: fontSizeThirtyThree)
        lblPro.font = getBoldFont(size: fontSizeThirtyThree)
        lblKeepYouRunning.font = getRegularFont(size: fontSizeSixteen)
        lblEverything.font = getRegularFont(size: fontSizeSixteen)

        lblSimpleMode.font = getRegularFont(size: fontSizeFifteen)
        lblPomodoro.font = getRegularFont(size: fontSizeFifteen)
        lblBlock5AppsUrls.font = getRegularFont(size: fontSizeFifteen)
        lblLimitedHabits.font = getRegularFont(size: fontSizeFifteen)
        lblLimitedMicroBreaks.font = getRegularFont(size: fontSizeFifteen)
        lblBrowserTabLimiter.font = getRegularFont(size: fontSizeFifteen)
        lblToDoList.font = getRegularFont(size: fontSizeFifteen)
        lblFree.font = getRegularFont(size: fontSizeTwentyFour)

        lblGeekMode.font = getRegularFont(size: fontSizeFifteen)
        lblSuperPomodoro.font = getRegularFont(size: fontSizeFifteen)
        lblUnlimitedBlocking.font = getRegularFont(size: fontSizeFifteen)
        lblAi.font = getRegularFont(size: fontSizeFifteen)
        lblFocusModes.font = getRegularFont(size: fontSizeFifteen)
        lblFocusMusic.font = getRegularFont(size: fontSizeFifteen)
        lblMeetingDetection.font = getRegularFont(size: fontSizeFifteen)
        lblPartnerPassword.font = getRegularFont(size: fontSizeFifteen)
        lblCustomizableStrictnessLevel.font = getRegularFont(size: fontSizeFifteen)
        lblAddOns.font = getRegularFont(size: fontSizeFifteen)

        btnContinue.font = getRegularFont(size: fontSizefourteen)
        btnUpgradeNow.font = getRegularFont(size: fontSizefourteen)
    }
    
    func resetData(titleText:String){
        var generalTitle = "You're currently using the Basic version of Focus Bear, which offers limited features. Consider upgrading to the Pro version for access to unlimited blocking, habits, and other premium features to maximize your productivity."
        if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
            generalTitle = upgradeToProNagVcInfo.value(forKey: "title") as? String ?? generalTitle
        }
        if titleText.isEmpty{
            lblTitle.stringValue = generalTitle
        }else{
            lblTitle.stringValue = titleText + " " + generalTitle
        }
    }
    
    func syncPaymentStatus(){
        allApiObject.capturePosthog(event: "sync-payment-status", metadata: ["from":"upgrade-pro-nag"])
        self.loader.startAnimation(self)
        self.btnUpgradeNow.isEnabled = false
        self.btnContinue.isEnabled = false
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnUpgradeNow.isEnabled = true
                self.btnContinue.isEnabled = true
            }

        })
    }
    
    @IBAction func btnUpgradeNowClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "upgrade-pro-nag-button-upgrade-clicked", metadata: [:])
        addLog(text: "[user-action] upgradeToProNagVc:- btnUpgradeNowClicked.")
        self.presentAsSheet(getManageSubscriptionVcObject())
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] upgradeToProNagVc:- btnContinueClicked.")
        allApiObject.capturePosthog(event: "upgrade-pro-nag-button-continue-clicked", metadata: [:])
        self.view.window?.close()
        if !isAppInitialLodded{
            appdelegate?.initialWork()
        }
    }
}
