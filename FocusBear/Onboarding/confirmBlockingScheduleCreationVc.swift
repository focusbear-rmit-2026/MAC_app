//
//  confirmBlockingScheduleCreationVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 06/01/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class confirmBlockingScheduleCreationVc: NSViewController {

    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnYes: Button!
    @IBOutlet weak var btnNo: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var customViewProgress: NSView!
    
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnNo.setAccessibilityIdentifier(UITestContract.Identifier.Onboarding.skipBlockingScheduleButton)
        btnYes.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.createBlockingScheduleButton)
        lblTitle.stringValue = "Add a New Blocking Schedule"
        lblSubTitle.stringValue = "You can have distracting sites and apps blocked during work hours or at night ⏰"
        btnNo.title = "No thanks"
        btnYes.title = "Yes! Save my focus"
        
        
        if let confirmBlockingScheduleCreationVcInfo =
            configjson.value(forKey: "confirmBlockingScheduleCreationVcInfo") as? NSDictionary {

            lblTitle.stringValue =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "title") as? String
                ?? lblTitle.stringValue

            lblSubTitle.stringValue =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "subTitle") as? String
                ?? lblSubTitle.stringValue

            btnNo.title =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "buttonNo") as? String
                ?? btnNo.title

            btnYes.title =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "buttonYes") as? String
                ?? btnYes.title
        }

        
        btnNo.isSecondaryButton = true
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 2, progress: 0)
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "blocking-schedule-creation-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // Show bubble
        var bubbleText = "An automatic blocking schedule helps me to nudge you at certain times"
        if let confirmBlockingScheduleCreationVcInfo = configjson.value(forKey: "confirmBlockingScheduleCreationVcInfo") as? NSDictionary{
            bubbleText = confirmBlockingScheduleCreationVcInfo.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: -40, horizontalOffset: 25, fontSize: 13)
        }
    }
    
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @IBAction func btnNoClicked(_ sender: Any) {
        addLog(text: "[user-action] confirmBlockingScheduleCreationVc:- btnNoClicked")
        allApiObject.capturePosthog(event: "add-new-block-skipped", metadata: [:])
        getOnboardingVcObject().blockingScheduleSkipped()
    }
    
    @IBAction func btnYesClicked(_ sender: Any) {
        addLog(text: "[user-action] confirmBlockingScheduleCreationVc:- btnYesClicked")
        allApiObject.capturePosthog(event: "add-new-block-clicked", metadata: [:])
        // Show the quick-start presets first (same grid the running app offers when adding a schedule);
        // picking one pre-fills the editor. The presets step then advances to _CREATE_BLOCKING_SCHEDULE_.
        getOnboardingVcObject().navigate(to: ._CHOOSE_BLOCKING_SCHEDULE_PRESET_)

    }
}
