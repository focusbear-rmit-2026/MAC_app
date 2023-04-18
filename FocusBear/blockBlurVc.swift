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
//        visualEffectView.alphaValue = 0.95
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        
//        var blurView = NSView(frame: view.bounds)
//        blurView.wantsLayer = true
//        blurView.layer?.backgroundColor = NSColor.clear.cgColor
//        blurView.layer?.masksToBounds = true
//        blurView.layerUsesCoreImageFilters = true
//        blurView.layer?.needsDisplayOnBoundsChange = true
//
//        var satFilter = CIFilter(name: "CIColorControls")
//        satFilter?.setDefaults()
//        satFilter?.setValue(NSNumber(value: 2.0), forKey: "inputSaturation")
//
//        var blurFilter = CIFilter(name: "CIGaussianBlur")
//        blurFilter?.setDefaults()
//        blurFilter?.setValue(NSNumber(value: 2.0), forKey: "inputRadius")
//
//        blurView.layer?.backgroundFilters = [satFilter, blurFilter]
//
//        view.wantsLayer = true
//        view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
//        view.addSubview(blurView)
//        view.addConstraints(subView: blurView)
//        blurView.layer?.needsDisplay()
        
    }
    
}
