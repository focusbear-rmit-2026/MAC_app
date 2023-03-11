//
//  customTooltipVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class customTooltipVc: NSViewController {

    @IBOutlet weak var maxWidth: NSLayoutConstraint!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var maxWidthVal:CGFloat = 230
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    func resetView() {
        maxWidth.constant = maxWidthVal
    }
}
