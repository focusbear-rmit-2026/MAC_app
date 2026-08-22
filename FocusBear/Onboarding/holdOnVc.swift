//
//  holdOnVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 26/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class holdOnVc: NSViewController {

    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleView:BubbleView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "You've blocked the bad habits. How about some good habits?"
        btnContinue.title = "Okay..."
        
        if let holdOnVcInfo = configjson["holdOnVcInfo"] as? [String: Any] {
            lblTitle.stringValue = holdOnVcInfo["titleText"] as? String ?? lblTitle.stringValue
            btnContinue.title = holdOnVcInfo["buttonContinueText"] as? String ?? btnContinue.title
        }
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "holdon-screen-shown", metadata: [:])
        
        //Preload routine suggestions so it's not blank 3.32.492
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        getInstallHabitPacksVcObj().loadWebView(suggestHabits: true)
    }
    
    override func viewDidAppear() {
        // Show bubble
        
        var bubbleText = "Arr… if you want to focus better, you’ve got to get your habits shipshape first."
        
        if let holdOnVcInfo = configjson["holdOnVcInfo"] as? [String: Any] {
            bubbleText = holdOnVcInfo["bubbleText"] as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, horizontalOffset: 50)
        }
    }
    
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] holdOnVc:- btnOkayClicked")
        
        getOnboardingVcObject().navigate(to: ._SET_UP_HABITS_)
    }
}
