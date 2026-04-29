//
//  collectionViewItemOccupation.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/04/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class collectionViewItemOccupation: NSCollectionViewItem {

    @IBOutlet weak var imgViewTick: NSImageView!
    @IBOutlet weak var boxSmall: NSBox!
    @IBOutlet weak var widthBoxCircle: NSLayoutConstraint!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var boxForCircle: NSBox!
    @IBOutlet weak var boxForBorder: NSBox!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        boxSmall.isHidden = true
        boxForCircle.fillColor = .clear
        boxForCircle.borderColor = NSColor.tertiaryLabelColor
        boxForBorder.borderWidth = 1
        boxForCircle.borderWidth = 1
    }
    var isItemSelected: Bool = false
    
    func updateSelection() {
        if isItemSelected{
            boxForBorder.borderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            boxForBorder.fillColor = buttonBgColor
            lblTitle.textColor = .black
            imgViewTick.isHidden = false
            boxForCircle.isHidden = true
        }else{
            boxForBorder.borderColor = NSColor.tertiaryLabelColor
            boxForBorder.fillColor = .clear
            lblTitle.textColor = .labelColor
            imgViewTick.isHidden = true
            boxForCircle.isHidden = false
        }
    }
}
