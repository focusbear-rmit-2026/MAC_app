//
//  onboardingFeedbackVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/09/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingFeedbackVc: NSViewController {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "We want your feedback"
        lblDescription.stringValue = "We're a small independent team, not a faceless mega-corporation. Focus Bear is still a new app and we really want your feedback. If you have suggestions, please click the 📣 icon (bottom left) at any point."
        btnContinue.title = "Continue"
        if let dic = configjson.value(forKey: "onboardingFeedbackVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
           // lblDescription.stringValue = dic.value(forKey: "subTitle") as? String ?? lblDescription.stringValue
            btnContinue.title = dic.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        imgView.wantsLayer = true
        imgView.layer?.cornerRadius = 10
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "want-feedback-screen")
    }
    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] btnContinueClicked.")
        self.view.window?.contentViewController = getOnboardingFocusExplainVcObject()
        addLog(text: "[user-action] Showing Onboarding Focus Explain view.")
        allApiObject.capturePosthog(event: "focus-explain-screen-shown", metadata: [:])
    }
    
}
