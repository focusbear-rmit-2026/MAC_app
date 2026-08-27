//
//  askPermissionsVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 28/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class askPermissionsVc: NSViewController {

    @IBOutlet weak var btnSkip: underLineButton!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var customViewProgress: NSView!
    
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "The schedule is set up! Now let's sort permissions."
        lblSubTitle.stringValue = "Focus Bear needs System Events, Accessibility, and Browser permissions to keep distractions blocked."
        btnSkip.title = "Skip"
        btnContinue.title = "Grant permissions"
        
        if let askPermissionsVcInfo = configjson.value(forKey: "askPermissionsVcInfo") as? NSDictionary {
            lblTitle.stringValue = askPermissionsVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = askPermissionsVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnSkip.title = askPermissionsVcInfo.value(forKey: "buttonSkip") as? String ?? btnSkip.title
            btnContinue.title = askPermissionsVcInfo.value(forKey: "buttonGrantPermissions") as? String ?? btnContinue.title
        }
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 3, progress: 0)
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "ask-permissions-screen-shown", metadata: [:])
    }
    
    func blockingScheduleSkipped(){
        lblTitle.stringValue = "Let's sort permissions."
        if let askPermissionsVcInfo = configjson.value(forKey: "askPermissionsVcInfo") as? NSDictionary {
            lblTitle.stringValue = askPermissionsVcInfo.value(forKey: "titleBlockingScheduleSkipped") as? String ?? lblTitle.stringValue
        }
    }
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    override func viewDidAppear() {
        // Show bubble
        var bubbleText = "Grant me powers so those distractions don't sneak back in! 🐾"
        if let info = configjson.value(forKey: "askPermissionsVcInfo") as? NSDictionary{
            bubbleText = info.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: -40, horizontalOffset: 25, fontSize: 13)
        }
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] askPermissionsVc:- btnGrantPermissionsClicked")
        getOnboardingVcObject().navigate(to: ._SYSTEM_EVENT_PERMISSION_)
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] askPermissionsVc:- btnSkipClicked")
        allApiObject.capturePosthog(event: "ask-permissions-skipped", metadata: [:])
        // Habits come after permissions now → skipping permissions continues to the habits section.
        getOnboardingVcObject().navigate(to: ._HOLD_ON_)
    }
}
