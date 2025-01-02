//
//  collectionViewItemOccupation.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/04/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class collectionViewItemOccupation: NSCollectionViewItem {

    @IBOutlet weak var widthBoxCircle: NSLayoutConstraint!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var boxForCircle: NSBox!
    @IBOutlet weak var boxForBorder: NSBox!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    var isItemSelected: Bool = false
    
    func updateSelection() {
        if isItemSelected{
            boxForCircle.borderWidth = 3
            boxForBorder.borderWidth = 1
            boxForBorder.borderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxForCircle.borderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxForBorder.fillColor = buttonBgColor
            lblTitle.textColor = .black
            boxForCircle.fillColor = .white
        }else{
            boxForCircle.borderWidth = 1
            boxForBorder.borderWidth = 1
            boxForBorder.borderColor = NSColor.tertiaryLabelColor
            boxForCircle.borderColor = NSColor.tertiaryLabelColor
            boxForBorder.fillColor = .clear
            lblTitle.textColor = .labelColor
            boxForCircle.fillColor = .clear
        }
    }
}
