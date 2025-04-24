//
//  tblCellFocsedCompletedItem.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/01/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class tblCellFocsedCompletedItem: NSTableCellView {

    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var lblDuration: NSTextField!
    @IBOutlet weak var lblTitleName: NSTextField!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
