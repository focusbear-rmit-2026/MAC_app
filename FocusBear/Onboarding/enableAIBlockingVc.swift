//
//  enableAIBlockingVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 02/01/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class enableAIBlockingVc: NSViewController {

    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnNoThanks: Button!
    @IBOutlet weak var lblPointThird: NSTextField!
    @IBOutlet weak var lblPointSecond: NSTextField!
    @IBOutlet weak var lblPointFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!

    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnContinue.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.enableAiBlockingButton)
        btnNoThanks.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.declineAiBlockingButton)
        
        lblPointFirst.stringValue = "The AI never knows who you are."
        lblPointSecond.stringValue = "Your browsing stays private - we don't share it with AI providers."
        lblPointThird.stringValue = "You can turn this off whenever you like."
        
        
        lblTitle.stringValue = "Do you want to use AI to block distractions?"
        lblSubTitle.stringValue = "Focus Bear can use AI to detect if you’re getting distracted and guide you back on track."
        btnNoThanks.title = "No thanks"
        btnContinue.title = "Make me indistractible"
        
        if let enableAIBlockingVcInfo = configjson.value(forKey: "enableAIBlockingVcInfo") as? NSDictionary {
            lblTitle.stringValue = enableAIBlockingVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = enableAIBlockingVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnNoThanks.title = enableAIBlockingVcInfo.value(forKey: "buttonNoThanks") as? String ?? btnNoThanks.title
            btnContinue.title = enableAIBlockingVcInfo.value(forKey: "buttonContinue") as? String ?? btnContinue.title
            
            lblPointFirst.stringValue = enableAIBlockingVcInfo["pointFirstText"] as? String ?? lblPointFirst.stringValue
            lblPointSecond.stringValue = enableAIBlockingVcInfo["pointSecondText"] as? String ?? lblPointSecond.stringValue
            lblPointThird.stringValue = enableAIBlockingVcInfo["pointThirdText"] as? String ?? lblPointThird.stringValue
        }

        
        btnNoThanks.isSecondaryButton = true
        
        
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 1, progress: 0)
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "enable-ai-blocking-screen-shown", metadata: [:])
        viewDidResize()
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
    }
    
    override func viewDidAppear() {
        // Show bubble
        var bubbleText = "Don’t worry, the AI provider doesn’t get your data!"
        if let askSetDistractionsVcInfo = configjson["askSetDistractionsVcInfo"] as? [String: Any] {
            bubbleText = askSetDistractionsVcInfo["bubbleText"] as? String ?? bubbleText
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
    
    @objc func viewDidResize(){
        if self.view.frame.height < 600{
            lblPointFirst.font = NSFont.systemFont(ofSize: 11)
            lblPointSecond.font = NSFont.systemFont(ofSize: 11)
            lblPointThird.font = NSFont.systemFont(ofSize: 11)
        }else if self.view.frame.height < 700{
            lblPointFirst.font = NSFont.systemFont(ofSize: 13)
            lblPointSecond.font = NSFont.systemFont(ofSize: 13)
            lblPointThird.font = NSFont.systemFont(ofSize: 13)
        }else if self.view.frame.height < 900{
            lblPointFirst.font = NSFont.systemFont(ofSize: 14)
            lblPointSecond.font = NSFont.systemFont(ofSize: 14)
            lblPointThird.font = NSFont.systemFont(ofSize: 14)
        }else{
            lblPointFirst.font = NSFont.systemFont(ofSize: 15)
            lblPointSecond.font = NSFont.systemFont(ofSize: 15)
            lblPointThird.font = NSFont.systemFont(ofSize: 15)
        }
    }
    
    @IBAction func btnNoThanksClicked(_ sender: Any) {
        addLog(text: "[user-action] enable ai blocking view:- button No thanks clicked.")
        allApiObject.capturePosthog(event: "opt-in-for-ai-no", metadata: [:])
        SettingsManagerObject.isAiCheckUrlEnabled = false
        getOnboardingVcObject().navigate(to: ._ASK_SET_DISTRACTIONS_)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] enable ai blocking view:- button Continue clicked.")
        allApiObject.capturePosthog(event: "opt-in-for-ai-yes", metadata: [:])
        SettingsManagerObject.isAiCheckUrlEnabled = true
        getOnboardingVcObject().navigate(to: ._ASK_SET_DISTRACTIONS_)
    }
}
