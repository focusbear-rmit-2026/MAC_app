//
//  tblCellCustomBlockingSchedules.swift
//  Focus Bear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class tblCellCustomBlockingSchedules: NSTableCellView {

    @IBOutlet weak var btnMain: mouseDownEffectButton!
    @IBOutlet weak var dashedView: DashedView!
    @IBOutlet weak var lblAddNewBlock: NSTextField!
    @IBOutlet weak var lblFocusModeName: NSTextField!
    @IBOutlet weak var lblBlockMode: NSTextField!
    @IBOutlet weak var boxFocusMode: NSBox!
    @IBOutlet weak var boxBlockMode: NSBox!
    @IBOutlet weak var lblTime: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var boxAddSchedule: NSBox!
    @IBOutlet weak var boxBlockingSchedule: NSBox!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
