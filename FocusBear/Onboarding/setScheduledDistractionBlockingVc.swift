//
//  setScheduledDistractionBlockingVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 27/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class setScheduledDistractionBlockingVc: NSViewController {
    
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var btnNoThanks: Button!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var imgViewMacBook: NSImageView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnNoThanks.setAccessibilityIdentifier(UITestContract.Identifier.Onboarding.skipDistractionBlockingButton)
        btnContinue.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.setUpDistractionBlockingButton)
        lblTitle.stringValue = "Set up Scheduled Distraction Blocking"
        lblSubTitle.stringValue = "Here’s what it will look like:"
        btnContinue.title = "Set up distraction blocking"
        btnNoThanks.title = "No thanks"
        
        if let dic = configjson["setScheduledDistractionBlockingVcInfo"] as? [String: Any] {
            lblTitle.stringValue = dic["titleText"] as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = dic["subTitleText"] as? String ?? lblSubTitle.stringValue
            btnContinue.title = dic["buttonContinue"] as? String ?? btnContinue.title
            btnNoThanks.title = dic["buttonNoThanks"] as? String ?? btnNoThanks.title
        }
        
        btnNoThanks.isSecondaryButton = true
        
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setClearAll()
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "set-distraction-blocking-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // Show bubble
        
        var bubbleText = "Set up distraction blocking in three quick steps!"

        if let dic = configjson["setScheduledDistractionBlockingVcInfo"] as? [String: Any] {
            bubbleText = dic["bubbleText"] as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, horizontalOffset: 50, fontSize: 14) 
        }
    }

    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @IBAction func btnNoThanksClicked(_ sender: Any) {
        addLog(text: "[user-action] setScheduledDistractionBlockingVc:- btnNoThanksClicked")
        allApiObject.capturePosthog(event: "set-distraction-blocking-skipped", metadata: [:])
        // Blocking is the first section; skipping it jumps past the rest of the blocking-config
        // steps to the blocking schedule step (habits now come later, after permissions).
        getOnboardingVcObject().navigate(to: ._ASK_CREATE_BLOCKING_SCHEDULE_)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] setScheduledDistractionBlockingVc:- btnSetupDistractionBlockingClicked")
        getOnboardingVcObject().navigate(to: ._ENABLE_AI_BLOCKING_)
    }
}


