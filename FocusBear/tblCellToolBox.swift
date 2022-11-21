//
//  tblCellToolBox.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 01/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class tblCellToolBox: NSTableCellView {

    @IBOutlet weak var lblUrl: NSTextField!
    var isFirstTime = false
    var trackingArea: NSTrackingArea?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        if !isFirstTime {
            isFirstTime = true
            trackingArea = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
            self.addTrackingArea(trackingArea!)
        }
    }
   
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == trackingArea{
            NSCursor.pointingHand.set()
        }
    }
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
    
}


