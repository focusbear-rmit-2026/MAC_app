//
//  tblCellTracks.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class tblCellTracks: NSTableCellView {

    @IBOutlet weak var lblDuration: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var imgview: NSImageView!
    @IBOutlet weak var lblArtist: NSTextField!
    @IBOutlet weak var btnPlay: NSButton!
 
    @IBOutlet weak var btnDownload: cursorButton!
    @IBOutlet weak var lblTitle: NSTextField!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
