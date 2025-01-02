//
//  tblCellLogQuantity.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 11/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class tblCellLogQuantity: NSTableCellView {

    @IBOutlet weak var topSpaceStackView: NSLayoutConstraint!
    @IBOutlet weak var lblMaximum: NSTextField!
    @IBOutlet weak var lblMinimum: NSTextField!
    @IBOutlet weak var lblMaximumDescription: NSTextField!
    @IBOutlet weak var lblMinimumDescription: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var textFieldCount: NSTextField!
    @IBOutlet weak var lblSliderValue: NSTextField!
    @IBOutlet weak var sliderQuantity: NSSlider!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

}
