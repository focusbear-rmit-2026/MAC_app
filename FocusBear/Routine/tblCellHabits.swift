//
//  tblCellHabits.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class tblCellHabits: NSTableCellView {
    
    @IBOutlet weak var stackViewActionBar: NSStackView!
    @IBOutlet weak var boxActionBar: NSBox!
    @IBOutlet weak var checkBox: NSButton!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var trackingArea: NSTrackingArea?
    var isFirstTime = false
    var isSelected = false
    
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
            if boxBg != nil && lblTitle.tag == 99 && !isSelected{
                boxBg.layer?.borderColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.blue.cgColor
                NSCursor.pointingHand.set()
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if lblTitle != nil{
            if boxBg != nil && lblTitle.tag == 99 && !isSelected{
                boxBg.layer?.borderColor = NSColor.clear.cgColor
                NSCursor.arrow.set()
            }
        }
    }
}
