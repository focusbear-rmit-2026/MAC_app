//
//  onboardingPrivacyTipVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingPrivacyTipVc: NSViewController {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblAnd: NSTextField!
    @IBOutlet weak var lblPointThird: NSTextField!
    @IBOutlet weak var lblPointSecond: NSTextField!
    @IBOutlet weak var lblPointFirst: NSTextField!
    
    @IBOutlet weak var btnTerms: underLineButton!
    @IBOutlet weak var checkBoxTerms: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnPrivacyPolicy: underLineButton!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleView:BubbleView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkBoxTerms.setAccessibilityIdentifier(UITestContract.Identifier.Onboarding.termsCheckBox)
        btnContinue.setAccessibilityIdentifier(UITestContract.Identifier.Onboarding.privacyContinueButton)
        btnPrivacyPolicy.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.privacyPolicyLink)
        btnTerms.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.termsLink)
        
        lblPointFirst.stringValue = "We never track which sites or apps you visit."
        lblPointSecond.stringValue = "Your data syncs across devices so blocking works everywhere."
        lblPointThird.stringValue = "Your data is encrypted and yours alone."
        lblAnd.stringValue = "and"
        
        
        checkBoxTerms.title = "I agree to the terms of the"
        btnPrivacyPolicy.title = "Privacy Policy"
        lblTitle.stringValue = "Privacy and Security"
        btnContinue.title = "Continue"
        btnTerms.title = "software license agreement"
        lblSubTitle.stringValue = "We take your privacy and security very seriously and will never share your data ever."
        if let dic = configjson.value(forKey: "onboardingPrivacyTipVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnContinue.title = dic.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            lblSubTitle.stringValue = dic.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            checkBoxTerms.title = dic.value(forKey: "buttonAcceptTermsNewText") as? String ?? checkBoxTerms.title
            btnPrivacyPolicy.title = dic.value(forKey: "buttonViewPrivacyPolicyNewText") as? String ?? btnPrivacyPolicy.title
            btnTerms.title = dic.value(forKey: "buttonViewTermsNewText") as? String ?? btnTerms.title
            
            lblPointFirst.stringValue = dic["pointFirstText"] as? String ?? lblPointFirst.stringValue
            lblPointSecond.stringValue = dic["pointSecondText"] as? String ?? lblPointSecond.stringValue
            lblPointThird.stringValue = dic["pointThirdText"] as? String ?? lblPointThird.stringValue
            lblAnd.stringValue = dic["andText"] as? String ?? lblAnd.stringValue
        }
        
        
    
        btnContinue.isEnabled = false
        checkBoxTerms.state = .off
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "privacy-and-security-screen")
        
        var bubbleText = "We will never compromise on your privacy!"
        if let dic = configjson["onboardingPrivacyTipVcInfo"] as? [String: Any] {
            bubbleText = dic["bubbleText"] as? String ?? bubbleText
        }
        
        // Show left bubble with offset 40px ABOVE center (negative value)
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgView, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: -50, horizontalOffset: 50)
        }
    }
    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
    }
    
    func resetState(){
        if checkBoxTerms.state == .on{
            btnContinue.isEnabled = true
        }else{
            btnContinue.isEnabled = false
        }
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "privacy-and-security-shown", metadata: [:])
        addLog(text: "[user-action] privacy-and-security-shown")
        resetState()
    }
    
    @IBAction func btnTermsClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingPrivacyTipVc:- btnTermsClicked")
        if let url = URL(string: "https://www.focusbear.io/terms-of-service"){
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func btnPrivacyPolicyClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingPrivacyTipVc:- btnPrivacyPolicyClicked")
        if let url = URL(string: "https://www.focusbear.io/en/privacy-policy"){
            NSWorkspace.shared.open(url)
        }
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
        addLog(text: "[user-action] onboardingPrivacyTipVc:- Button Continue clicked")
        appdelegate!.statusbutton?.action = nil
        getOnboardingVcObject().navigate(to: ._CREATE_ACCOUNT_)
    }

    @IBAction func checkBoxTermsClicked(_ sender: Any) {
        resetState()
    }
}
