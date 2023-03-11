//
//  collectionCellToolBox.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class collectionCellToolBox: NSCollectionViewItem {

    @IBOutlet weak var btnIcon: NSButton!
//    var isUrl = false
    var urlString = ""
    var trackingArea: NSTrackingArea?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        

    }
 
    override func viewWillAppear() {
        if trackingArea !=  nil{
            btnIcon.removeTrackingArea(trackingArea!)
            trackingArea = nil
        }
        trackingArea = NSTrackingArea.init(rect: btnIcon.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnIcon.addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        print("mouseEntered")
        if event.trackingArea == trackingArea{
            if !urlString.isEmpty{
                showTooltip(sender: btnIcon, msg: urlString, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
            }
        }
    }
    override func mouseExited(with event: NSEvent) {
        print("mouseExited")
        if !urlString.isEmpty{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
}
