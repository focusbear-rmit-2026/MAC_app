//
//  onboardingPrivacyTipVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingPrivacyTipVc: NSViewController {

    @IBOutlet weak var btnTerms: underLineButton!
    @IBOutlet weak var checkBoxTerms: NSButton!
    @IBOutlet weak var btnCheckBox: NSButton!
    @IBOutlet weak var lblMoreDetail: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnPrivacyPolicy: underLineButton!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnTerms.title = "software license agreement."
        checkBoxTerms.title = "I agree to the terms of the"
        btnCheckBox.title = "I accept the"
        btnPrivacyPolicy.title = "Privacy Policy"
        
        var titleTermsAndConditions = "Terms and Conditions"
        var descriptionTermsText = "🤝 To continue using Focus Bear you must agree to the terms of the software license agreement."

        lblTitle.stringValue = "Privacy and Security"
        lblDescription.stringValue = "We take your privacy and security very seriously. We do not log which websites or apps you use. We do sync your habit data to our server but this is only to support cross device distraction blocking. Your data is encrypted and we don't let anyone else see it. for more details or feel free to email team@focusbear.io. Refer to our privacy policy:"
        btnContinue.title = "Continue"
        lblSubTitle.stringValue = "We take your privacy and security very seriously and will never share your data ever."
        lblMoreDetail.stringValue = "For more details, refer to our privacy policy or feel free to email team@focusbear.io."
        
        if let dic = configjson.value(forKey: "onboardingPrivacyTipVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = dic.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            btnContinue.title = dic.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            //btnPrivacyPolicy.title = dic.value(forKey: "buttonViewPrivacyText") as? String ?? btnPrivacyPolicy.title
            lblSubTitle.stringValue = dic.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblMoreDetail.stringValue = dic.value(forKey: "moreDetailText") as? String ?? lblMoreDetail.stringValue
           // btnCheckBox.title = dic.value(forKey: "buttonAcceptPrivacyPolicyText") as? String ?? btnCheckBox.title
          //  btnTerms.title = dic.value(forKey: "buttonViewTermsText") as? String ?? btnTerms.title
         //   checkBoxTerms.title = dic.value(forKey: "buttonAcceptTermsText") as? String ?? checkBoxTerms.title
            titleTermsAndConditions = dic.value(forKey: "titleTermsAndConditions") as? String ?? titleTermsAndConditions
            descriptionTermsText = dic.value(forKey: "descriptionTermsText") as? String ?? descriptionTermsText
            
            btnTerms.title = dic.value(forKey: "buttonViewTermsNewText") as? String ?? btnTerms.title
            checkBoxTerms.title = dic.value(forKey: "buttonAcceptTermsNewText") as? String ?? checkBoxTerms.title
            btnCheckBox.title = dic.value(forKey: "buttonAcceptPrivacyPolicyNewText") as? String ?? btnCheckBox.title
            btnPrivacyPolicy.title = dic.value(forKey: "buttonViewPrivacyPolicyNewText") as? String ?? btnPrivacyPolicy.title
        }
        
        allApiObject.capturePosthog(event: "privacy-and-security-shown", metadata: [:])
        addLog(text: "[user-action] privacy-and-security-shown")
        lblTitle.stringValue = "\(titleTermsAndConditions) / \(lblTitle.stringValue)"
        
        lblDescription.stringValue = lblDescription.stringValue + "\n\n\(descriptionTermsText)"
        btnContinue.isEnabled = false
        btnCheckBox.state = .off
        checkBoxTerms.state = .off
    }
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "privacy-and-security-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
    }
    func resetState(){
        if btnCheckBox.state == .on && checkBoxTerms.state == .on{
            btnContinue.isEnabled = true
        }else{
            btnContinue.isEnabled = false
        }
    }
    override func viewWillAppear() {
        resetState()
    }
    
    @IBAction func btnTermsClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/terms-of-service"){
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func btnPrivacyPolicyClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/en/privacy-policy"){
            NSWorkspace.shared.open(url)
        }
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
        addLog(text: "[user-action] onboardingPrivacyTipVc:- Button Continue clicked")
        self.view.window?.close()
        showAskLoginWindow()
    }
    @IBAction func btnCheckBoxClicked(_ sender: Any) {
        resetState()
    }
    @IBAction func checkBoxTermsClicked(_ sender: Any) {
        resetState()
    }
}
