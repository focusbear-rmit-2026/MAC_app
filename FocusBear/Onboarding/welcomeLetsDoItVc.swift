//
//  welcomeLetsDoItVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 25/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class welcomeLetsDoItVc: NSViewController {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleViewLeft:BubbleView?
    var bubbleViewRight:BubbleView?
    var welcomeLetsDoItVcInfo: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnLetsDoIt.setAccessibilityIdentifier(UITestContract.Identifier.Onboarding.letsDoItButton)
        
        btnLetsDoIt.title = "Let’s do it!"
        
        welcomeLetsDoItVcInfo = configjson["welcomeLetsDoItVcInfo"] as? [String: Any]

        btnLetsDoIt.title = welcomeLetsDoItVcInfo?["buttonLetsDoIt"] as? String ?? btnLetsDoIt.title
        
        
        lblTitle.isHidden = true
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "welcome-lets-do-it-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        let bubbleLeftText =
            welcomeLetsDoItVcInfo?["bubbleLeftText"] as? String
            ?? "It’s so hard to focus with all the fun... I mean distracting websites!"

        let bubbleRightText =
            welcomeLetsDoItVcInfo?["bubbleRightText"] as? String
            ?? "Want to team up? We can focus together!"
        
        // Show left bubble with offset 40px ABOVE center (negative value)
        if bubbleViewLeft == nil{
            bubbleViewLeft = PopupManager.showPopup(for: imgView, edge: .minX, selfView: self.view, text: bubbleLeftText, verticalOffset: -50, horizontalOffset: 50)
        }
        
        //// Show right bubble with offset 40px BELOW center (positive value)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            if bubbleViewRight == nil{
                bubbleViewRight = PopupManager.showPopup(for: imgView, edge: .maxX, selfView: view, text: bubbleRightText, verticalOffset: 50, horizontalOffset: -50)
            }
        }
    }
    
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "[user-action] welcomeLetsDoItVc:- btnLetsDoItClicked")
        getOnboardingVcObject().navigate(to: ._SET_UP_ACCOUNT_)
    }
    
}
