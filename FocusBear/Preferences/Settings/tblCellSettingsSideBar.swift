//
//  tblCellSettingsSideBar.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/01/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class tblCellSettingsSideBar: NSTableCellView {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var boxNewBadge: customNewBadgeBox!
    @IBOutlet weak var lblTitle: NSTextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        imgView.hideDecorativeIconFromVoiceOver()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
