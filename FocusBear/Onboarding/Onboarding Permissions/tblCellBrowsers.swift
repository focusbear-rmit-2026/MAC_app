//
//  tblCellBrowsers.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class tblCellBrowsers: NSTableCellView {

    @IBOutlet weak var btnSkipBrowser: underLineButton!
    @IBOutlet weak var imgViewTick: NSImageView!
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var lineBottom: NSBox!
    @IBOutlet weak var lblFirefoxPermission: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblState: NSTextField!
    @IBOutlet weak var btnRequest: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
