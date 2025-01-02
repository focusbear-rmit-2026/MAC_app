//
//  blockBlurVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/03/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class blockBlurVc: NSViewController {

    @IBOutlet weak var visualEffectView: NSVisualEffectView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
    }
    
}
