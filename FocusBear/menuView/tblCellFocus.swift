//
//  tblCellFocus.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/02/22.

//

import Cocoa

class tblCellFocus: NSTableCellView {


    @IBOutlet weak var rowHeight: NSLayoutConstraint!
    @IBOutlet weak var btnInfoIcon: hoverInfoButton!
    @IBOutlet weak var btnEditFocusMode: NSButton!
    @IBOutlet weak var lblIntension: NSTextField!
    @IBOutlet weak var imgViewAppIcon: NSImageView!
    @IBOutlet weak var boxColor: NSBox!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var boxtitle: customBox!
    var isFirstTime = false
    var trackingArea: NSTrackingArea?
    var isInfoIconVisible = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        if !isFirstTime {
            isFirstTime = true
            trackingArea = NSTrackingArea.init(rect: boxtitle.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
            boxtitle.addTrackingArea(trackingArea!)
        }
    }
   
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == trackingArea{
            if isInfoIconVisible{
                btnInfoIcon.isHidden = false
            }else{
                btnEditFocusMode.isHidden = false
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        btnEditFocusMode.isHidden = true
        btnInfoIcon.isHidden = true
    }
    
}

