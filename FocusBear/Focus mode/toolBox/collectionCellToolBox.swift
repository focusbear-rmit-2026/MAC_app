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
    var appName = ""
    var trackingArea: NSTrackingArea?
    @IBOutlet weak var lblAppName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        

    }
 
    override func viewWillAppear() {
        
    }
    func setTrackingArea(){
        if trackingArea !=  nil{
            btnIcon.removeTrackingArea(trackingArea!)
            trackingArea = nil
        }
        trackingArea = NSTrackingArea.init(rect: self.view.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.view.addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == trackingArea{
            if !appName.isEmpty{
                showTooltip(sender: self.view, msg: appName, preferredEdge: NSRectEdge.maxY, maxWidthVal:230, autoCloseOnMouseExit: true)
            }
        }
    }
    override func mouseExited(with event: NSEvent) {
        if popoverTooltip != nil{
            if popoverTooltip!.isShown{
                popoverTooltip?.close()
            }
        }
    }
}
