//
//  tblCellFocusPreferences.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 17/02/22.

//

import Cocoa

class tblCellFocusPreferences: NSTableCellView {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var boxColor: NSBox!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnCell: NSButton!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
