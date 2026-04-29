//
//  askSetDistractionsVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 27/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class askSetDistractionsVc: NSViewController {
    
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnNoThanks: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!

    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Not sure which distractions to block?"
        lblSubTitle.stringValue = "We can suggest distractions based on your job - so you can stay in the zone."
        btnNoThanks.title = "I’ll pick them myself"
        btnContinue.title = "Yes, help me pick!"

        if let askSetDistractionsVcInfo = configjson["askSetDistractionsVcInfo"] as? [String: Any] {
            lblTitle.stringValue = askSetDistractionsVcInfo["title"] as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = askSetDistractionsVcInfo["subTitle"] as? String ?? lblSubTitle.stringValue
            btnNoThanks.title = askSetDistractionsVcInfo["buttonNoThanks"] as? String ?? btnNoThanks.title
            btnContinue.title = askSetDistractionsVcInfo["buttonContinue"] as? String ?? btnContinue.title
        }
        
        btnNoThanks.isSecondaryButton = true
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 1, progress: 0.15)
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "suggest-distractions-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // Show bubble
        
        var bubbleText = "I see far too many distracting websites"
        if let enableAIBlockingVcInfo = configjson["enableAIBlockingVcInfo"] as? [String: Any] {
            bubbleText = enableAIBlockingVcInfo["bubbleText"] as? String ?? bubbleText
        }
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, horizontalOffset: 25, fontSize: 14)
        }
    }
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }

    @IBAction func btnNoThanksClicked(_ sender: Any) {
        addLog(text: "[user-action] askSetDistractionsVc:- btnNoThanks")
        getOnboardingVcObject().navigate(to: ._ALLOWED_URLS_)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] askSetDistractionsVc:- btnYesPickClicked")
        getOnboardingVcObject().navigate(to: ._ASK_OCCUPATION_)
    }
}
