//
//  floatingTopBarVc.swift
//  FocusBear
//
//  Created by Manish Jain on 21/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class floatingTopBarVc: NSViewController {

    @IBOutlet weak var boxMain: NSBox!
    @IBOutlet weak var topSpaceMainBox: NSLayoutConstraint!
    @IBOutlet weak var boxFakeView: NSBox!
    
    var boxMainTrackingArea: NSTrackingArea?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        boxMainTrackingArea = NSTrackingArea.init(rect: boxMain.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        boxMain.addTrackingArea(boxMainTrackingArea!)
    }
    
    @IBAction func btnBarClicked(_ sender: Any) {
        appdelegate!.togglePopover(false)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == boxMainTrackingArea{
            isCustomBarIsInFocus = true
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == boxMainTrackingArea{
            isCustomBarIsInFocus = false
        }
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        boxMain.isHidden = true
    }
}
