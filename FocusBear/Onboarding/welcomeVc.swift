//
//  welcomeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class welcomeVc: NSViewController {

    @IBOutlet weak var imgViewWelcomeBear: NSImageView!
    @IBOutlet weak var imgViewWave: NSImageView!
    @IBOutlet weak var btnAlreadyHaveAccount: underLineButton!
    @IBOutlet weak var lblAllRights: NSTextField!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet weak var lblDescriptionSecond: NSTextField!
    @IBOutlet weak var lblDescriptionFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTitleAppName: NSTextField!
    
    var bubbleView:BubbleView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnLetsDoIt.setAccessibilityIdentifier(UITestContract.Identifier.Onboarding.welcomeContinueButton)
        btnAlreadyHaveAccount.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.welcomeAlreadyHaveAccountButton)
        btnAlreadyHaveAccount.title = "I already have a Focus Bear account"
        lblTitleAppName.stringValue = appName
        lblSubTitle.stringValue = "Welcome aboard!"
        lblDescriptionFirst.stringValue = "Focus Bear helps you avoid distractions and build healthy habits."
        lblDescriptionSecond.stringValue = "Let's start out by blocking distractions."
        btnLetsDoIt.title = "Howdy!"
        lblAllRights.stringValue = "© 2022-2026 Focus Bear All Rights Reserved."
        
        if let welcomeOnboardingVcInfo = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = welcomeOnboardingVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblAllRights.stringValue = welcomeOnboardingVcInfo.value(forKey: "allRightsReservedText") as? String ?? lblAllRights.stringValue
        }
        
        if let welcomeVcInfo = configjson.value(forKey: "welcomeVcInfo") as? NSDictionary{
            lblDescriptionFirst.stringValue = welcomeVcInfo.value(forKey: "descriptionFirstText") as? String ?? lblDescriptionFirst.stringValue
            lblDescriptionSecond.stringValue = welcomeVcInfo.value(forKey: "descriptionSecondText") as? String ?? lblDescriptionSecond.stringValue
            btnAlreadyHaveAccount.title = welcomeVcInfo.value(forKey: "buttonAlreadyHaveAccountText") as? String ?? btnAlreadyHaveAccount.title
            btnLetsDoIt.title = welcomeVcInfo.value(forKey: "buttonHowdy") as? String ?? btnLetsDoIt.title
        }
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding)


        lblDescriptionSecond.isHidden = true
        
        lblSubTitle.isHidden = true
        lblDescriptionFirst.isHidden = true
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "welcome-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // bubbleView
        
        var bubbleText = "Howdy! I’m Focus Bear Junior"
        if let welcomeVcInfo = configjson.value(forKey: "welcomeVcInfo") as? NSDictionary{
            bubbleText = welcomeVcInfo.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewWelcomeBear, edge: .minX, selfView: self.view, text: bubbleText, horizontalOffset: 50)
        }
    }
    
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "[user-action] welcomeVc:- btnLetsDoItClicked")
        getOnboardingVcObject().navigate(to: ._WELCOME_ADHD_)
    }
    
    @IBAction func btnAlreadyHaveAccountClicked(_ sender: Any) {
        addLog(text: "[user-action] welcomeVc:- btnAlreadyHaveAccountClicked")
        allApiObject.capturePosthog(event: "button-already-have-account-clicked", metadata: [:])
        isHabitsDisabled = false

        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
//        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate) commented 3.31.474
        showCustomLoginWindow(isLogin: true)
    }
    
}
