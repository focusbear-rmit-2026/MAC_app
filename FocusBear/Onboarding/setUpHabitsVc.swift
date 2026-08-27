//
//  setUpHabitsVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 26/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class setUpHabitsVc: NSViewController {

    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var imgViewAllType: NSImageView!
    @IBOutlet weak var btnSkip: hoverUnderlineButton!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleView:BubbleView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Set up habits to focus better"
        lblSubTitle.stringValue = "Research shows that habits like sleeping better, meditating, and exercising improve your focus"
        btnContinue.title = "Set up habits"
        btnSkip.title = "Skip"
        
        if let dic = configjson["setUpHabitsVcInfo"] as? [String: Any] {
            lblTitle.stringValue = dic["titleText"] as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = dic["subTitleText"] as? String ?? lblSubTitle.stringValue
            btnContinue.title = dic["buttonContinue"] as? String ?? btnContinue.title
            btnSkip.title = dic["buttonSkip"] as? String ?? btnSkip.title
        }
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "set-up-habits-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // Show bubble
        
        var bubbleText = "Good habits like these keep your focus sharp all day."

        if let dic = configjson["setUpHabitsVcInfo"] as? [String: Any] {
            bubbleText = dic["bubbleText"] as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: -50, horizontalOffset: 80, fontSize: 14)
        }
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] setUpHabitsVc:- btnSkipClicked")
        allApiObject.capturePosthog(event: "set-up-habits-skipped", metadata: [:])
        isHabitsDisabled = true
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsHabitsDisabledFromOnboarding)
        // Habits is the last section now (after permissions); skipping it finishes onboarding.
        getOnboardingVcObject().navigate(to: ._ALL_SET_)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] setUpHabitsVc:- btnSetuphabitsClicked")
        getOnboardingVcObject().navigate(to: ._START_SET_UP_HABITS_)
    }
}
