//
//  bellVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/11/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class bellVc: NSViewController {

    @IBOutlet weak var lblBell: NSTextField!
    
    var trackingArea: NSTrackingArea?
    var screen:String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        trackingArea = NSTrackingArea.init(rect: lblBell.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        lblBell.addTrackingArea(trackingArea!)
        
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == trackingArea{
            var toolTipBellIcon = "Share your feedback or suggestions"
            if let bellSuggestionsVcInfo = configjson.value(forKey: "bellSuggestionsVcInfo") as? NSDictionary{
                toolTipBellIcon = bellSuggestionsVcInfo.value(forKey: "toolTipBellIcon") as? String ?? toolTipBellIcon
            }
            showTooltip(sender: lblBell, msg: toolTipBellIcon, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == trackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
    @IBAction func btnBellClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "onboarding-user-feedback-screen-shown", metadata: [:])
        
        self.presentAsSheet(getBellSuggestionsVcObj())
    }
    
}
