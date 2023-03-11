//
//  tblCellFocus.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/02/22.

//

import Cocoa

class tblCellFocus: NSTableCellView {


    @IBOutlet weak var btnEditFocusMode: NSButton!
    @IBOutlet weak var lblIntension: NSTextField!
    //  @IBOutlet weak var hoursPopupBtn: NSPopUpButton!
    @IBOutlet weak var horizaontalLine: NSBox!
    @IBOutlet weak var lblUntil: NSTextField!
    @IBOutlet weak var lblHour: NSTextField!
    @IBOutlet weak var lblFor: NSTextField!
    @IBOutlet weak var imgViewAppIcon: NSImageView!
    @IBOutlet weak var stepperHourValue: NSStepper!
    @IBOutlet weak var boxColor: NSBox!
    @IBOutlet weak var textFieldCustomHour: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewCheckMarkSecond: NSImageView!
    @IBOutlet weak var imgViewCheckMarkFirst: NSImageView!
    @IBOutlet weak var boxtitle: customBox!
    @IBOutlet weak var boxChildFirst: customBox!
    @IBOutlet weak var boxChildSecond: customBox!
    var isFirstTime = false
    var trackingArea: NSTrackingArea?

    var isEditButttonEnable = true
    
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
            if isEditButttonEnable{
                btnEditFocusMode.isHidden = false
            }
//            NSCursor.pointingHand.set()
        }
    }
    override func mouseExited(with event: NSEvent) {
        btnEditFocusMode.isHidden = true
//        NSCursor.pointingHand.set()
    }
    
}

