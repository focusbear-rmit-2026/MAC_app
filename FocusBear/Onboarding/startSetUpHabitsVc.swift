//
//  startSetUpHabitsVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 26/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class startSetUpHabitsVc: NSViewController {

    @IBOutlet weak var btnGiveMeHabits: Button!
    @IBOutlet weak var btnNo: Button!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleView:BubbleView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Need some fresh ideas for habits?"
        lblSubTitle.stringValue = "If you have your own habit list, you can import them too."
        btnNo.title = "Nay - I already have some habits"
        btnGiveMeHabits.title = "Aye - Give me some ideas, Cap’n"
        
        btnNo.isSecondaryButton = true
        
        if let dic = configjson["startSetUpHabitsVcInfo"] as? [String: Any] {
            lblTitle.stringValue = dic["titleText"] as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = dic["subTitleText"] as? String ?? lblSubTitle.stringValue
            btnGiveMeHabits.title = dic["buttonGiveMeHabits"] as? String ?? btnGiveMeHabits.title
            btnNo.title = dic["buttonNo"] as? String ?? btnNo.title
        }
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "setting-up-habits-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // Show bubble
        var bubbleText = "Want me to bring aboard some new habits?"

        if let dic = configjson["startSetUpHabitsVcInfo"] as? [String: Any] {
            bubbleText = dic["bubbleText"] as? String ?? bubbleText
        }
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, horizontalOffset: 50)
        }
    }
    
    @IBAction func btnGiveMeHabitsClicked(_ sender: Any) {
        addLog(text: "[user-action] startSetUpHabitsVc:- btnGiveSomeIdeasClicked")
        allApiObject.capturePosthog(event: "button-give-me-some-ideas-clicked", metadata: [:])
        getOnboardingVcObject().navigateToInstallHabitVc(suggestHabits: true)
    }
    @IBAction func btnNoClicked(_ sender: Any) {
        addLog(text: "[user-action] startSetUpHabitsVc:- btnIAlreadyHaveHabitsClicked")
        allApiObject.capturePosthog(event: "button-already-have-habits-clicked", metadata: [:])
        getOnboardingVcObject().navigateToInstallHabitVc(suggestHabits: false)
    }
}
