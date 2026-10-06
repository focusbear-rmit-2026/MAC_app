//
//  welcomeAdhdVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 25/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class welcomeAdhdVc: NSViewController {

    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnMeToo: Button!
    @IBOutlet weak var btnNeverHadIssue: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleViewLeft:BubbleView?
    var bubbleViewRight:BubbleView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnMeToo.setAccessibilityIdentifier(UITestContract.Identifier.Onboarding.welcomeAdhdContinueButton)
        btnNeverHadIssue.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.welcomeAdhdNeverHadIssueButton)

        btnNeverHadIssue.title = "I never had that issue"
        btnMeToo.title = "Me too!"
        
        if let welcomeAdhdVcInfo = configjson.value(forKey: "welcomeAdhdVcInfo") as? NSDictionary{
            btnNeverHadIssue.title = welcomeAdhdVcInfo.value(forKey: "buttonNeverHadIssue") as? String ?? btnNeverHadIssue.title
            btnMeToo.title = welcomeAdhdVcInfo.value(forKey: "buttonMeToo") as? String ?? btnMeToo.title
        }
        
        btnNeverHadIssue.isSecondaryButton = true
        lblTitle.isHidden = true
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "welcome-adhd-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        
        var bubbleLeftText = "I’m actually not that good at focusing though"
        var bubbleRightText = "I’ve got ADHD and get distracted all the time 😢"
        
        if let welcomeAdhdVcInfo = configjson.value(forKey: "welcomeAdhdVcInfo") as? NSDictionary{
            bubbleLeftText = welcomeAdhdVcInfo.value(forKey: "bubbleLeftText") as? String ?? bubbleLeftText
            bubbleRightText = welcomeAdhdVcInfo.value(forKey: "bubbleRightText") as? String ?? bubbleRightText
        }
        
        // Show left bubble with offset 40px ABOVE center (negative value)
        if bubbleViewLeft == nil{
            bubbleViewLeft = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleLeftText, verticalOffset: -50, horizontalOffset: 50)
        }
        
        //// Show right bubble with offset 40px BELOW center (positive value)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            if bubbleViewRight == nil{
                bubbleViewRight = PopupManager.showPopup(for: imgViewBear, edge: .maxX, selfView: view, text: bubbleRightText, verticalOffset: 50, horizontalOffset: -50)
            }
        }
    }
    
    @IBAction func btnNeverHadIssueClicked(_ sender: Any) {
        addLog(text: "[user-action] welcomeAdhdVc:- btnNeverHadIssueClicked")
        allApiObject.capturePosthog(event: "button-never-had-issue-clicked", metadata: [:])
        getOnboardingVcObject().navigate(to: ._SET_UP_ACCOUNT_)
    }
    
    @IBAction func btnMeTooClicked(_ sender: Any) {
        addLog(text: "[user-action] welcomeAdhdVc:- btnMeTooClicked")
        allApiObject.capturePosthog(event: "button-me-too-clicked", metadata: [:])
        getOnboardingVcObject().navigate(to: ._WELCOME_LETS_DO_IT_)
    }
    
}
