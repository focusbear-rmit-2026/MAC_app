//
//  tblCellFocus.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/02/22.

//

import Cocoa

class tblCellFocus: NSTableCellView {


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
 //   var isFirstTime = true
    
//    var currentRow = 0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
   
}

