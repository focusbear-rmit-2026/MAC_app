//
//  tblCellHabits.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class tblCellHabits: NSTableCellView {
    
    @IBOutlet weak var checkBox: NSButton!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var lblTitle: NSTextField!
    var trackingArea: NSTrackingArea?
    var isFirstTime = false
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        if boxBg != nil {
            if !isFirstTime{
                isFirstTime = true
                trackingArea = NSTrackingArea.init(rect: boxBg.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
                boxBg.addTrackingArea(trackingArea!)
            }
        }
    }
    
    
    override func mouseEntered(with event: NSEvent) {
        if lblTitle != nil{
            if boxBg != nil && lblTitle.tag == 99{
                boxBg.borderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
                NSCursor.pointingHand.set()
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if lblTitle != nil{
            if boxBg != nil && lblTitle.tag == 99{
                boxBg.borderColor = NSColor.clear
                NSCursor.arrow.set()
            }
        }
    }
}
