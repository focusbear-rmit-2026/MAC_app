//
//  allSetVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 30/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class allSetVc: NSViewController {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var customViewProgress: NSView!
    
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        lblTitle.stringValue = "Fantastic! We are all set."
        lblSubTitle.stringValue = "You are now ready to become a creature of habit."
        btnContinue.title = "Start using Focus Bear"
        
        // Load localized text
        if let allSetVcInfo = configjson["allSetVcInfo"] as? [String: Any] {
            lblTitle.stringValue = allSetVcInfo["title"] as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = allSetVcInfo["subTitle"] as? String ?? lblSubTitle.stringValue
            btnContinue.title = allSetVcInfo["buttonContinue"] as? String ?? btnContinue.title
        }
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setCompletedAll()
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "all-set-screen-shown", metadata: [:])
    }
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] allSetVc:- btnContinueClicked")
        getOnboardingVcObject().onboardingFinished()
    }
}
