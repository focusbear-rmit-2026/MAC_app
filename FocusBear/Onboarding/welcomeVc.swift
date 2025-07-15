//
//  welcomeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class welcomeVc: NSViewController {

    @IBOutlet weak var btnAlreadyHaveAccount: underLineButton!
    @IBOutlet weak var lblAllRights: NSTextField!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet weak var lblDescriptionSecond: NSTextField!
    @IBOutlet weak var lblDescriptionFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTitleAppName: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnAlreadyHaveAccount.title = "I already have a Focus Bear account"
        lblTitleAppName.stringValue = appName
        lblSubTitle.stringValue = "Welcome aboard!"
        lblDescriptionFirst.stringValue = "Focus Bear helps you avoid distractions and build healthy habits."
        lblDescriptionSecond.stringValue = "Let's start out by blocking distractions."
        btnLetsDoIt.title = "Let's do it"
        lblAllRights.stringValue = "© 2022-2025 Focus Bear All Rights Reserved."
        
        if let welcomeOnboardingVcInfo = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = welcomeOnboardingVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnLetsDoIt.title = welcomeOnboardingVcInfo.value(forKey: "buttonLetsDoItText") as? String ?? btnLetsDoIt.title
            lblAllRights.stringValue = welcomeOnboardingVcInfo.value(forKey: "allRightsReservedText") as? String ?? lblAllRights.stringValue
        }
        if let welcomeVcInfo = configjson.value(forKey: "welcomeVcInfo") as? NSDictionary{
            lblDescriptionFirst.stringValue = welcomeVcInfo.value(forKey: "descriptionFirstText") as? String ?? lblDescriptionFirst.stringValue
            lblDescriptionSecond.stringValue = welcomeVcInfo.value(forKey: "descriptionSecondText") as? String ?? lblDescriptionSecond.stringValue
            btnAlreadyHaveAccount.title = welcomeVcInfo.value(forKey: "buttonAlreadyHaveAccountText") as? String ?? btnAlreadyHaveAccount.title
        }
        
        allApiObject.capturePosthog(event: "welcome-aboard-shown", metadata: [:])
        UserDefaults.standard.removeObject(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsBlockingScheduleFromOnboarding)
        
        getOnboardingFocusExplainVcObject().loadView()
        getOnboardingHabitExplainVcObject().loadView()
        
        
        
        lblDescriptionSecond.isHidden = true // change onboarding 20/12/24
    }
    
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "[user-action] btnLetsDoItClicked.")
        self.view.window?.contentViewController = getOnboardingPrivacyTipVcObject()
    }
    
    @IBAction func btnAlreadyHaveAccountClicked(_ sender: Any) {
        addLog(text: "[user-action] btnAlreadyHaveAccountClicked.")
        allApiObject.capturePosthog(event: "button-already-have-account-clicked", metadata: [:])
        isHabitsDisabled = false

        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        
        self.view.window?.close()
        showCustomLoginWindow(isLogin: true)
        askLogInWcObj?.window?.center()
    }
    
}
