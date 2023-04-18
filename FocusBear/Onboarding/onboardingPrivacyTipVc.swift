//
//  onboardingPrivacyTipVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingPrivacyTipVc: NSViewController {

    @IBOutlet weak var lblMoreDetail: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnPrivacyPolicy: underLineButton!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Privacy and Security"
        lblDescription.stringValue = "We take your privacy and security very seriously. We do not log which websites or apps you use. We do sync your habit data to our server but this is only to support cross device distraction blocking. Your data is encrypted and we don't let anyone else see it. for more details or feel free to email team@focusbear.io. Refer to our privacy policy:"
        btnPrivacyPolicy.title = "Click here to view Privacy Policy"
        btnContinue.title = "Continue"
        lblSubTitle.stringValue = "We take your privacy and security very seriously and will never share your data ever."
        lblMoreDetail.stringValue = "For more details, refer to our privacy policy or feel free to email team@focusbear.io."
        if let dic = configjson.value(forKey: "onboardingPrivacyTipVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = dic.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            btnContinue.title = dic.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            btnPrivacyPolicy.title = dic.value(forKey: "buttonViewPrivacyText") as? String ?? btnPrivacyPolicy.title
            lblSubTitle.stringValue = dic.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblMoreDetail.stringValue = dic.value(forKey: "moreDetailText") as? String ?? lblMoreDetail.stringValue
        }
        allApiObject.capturePosthog(event: "privacy-and-security-shown", metadata: [:])
    }
    
    @IBAction func btnPrivacyPolicyClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/en/privacy-policy"){
            NSWorkspace.shared.open(url)
        }
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        self.view.window?.contentViewController = getOnboardingControllingBrowserVcObject()
    }
}
