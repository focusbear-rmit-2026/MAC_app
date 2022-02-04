//
//  selectJsonWindowController.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 05/01/22.
//  .
//

import Cocoa

class selectJsonWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        self.contentViewController = selectJsonVcObj!
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isGettingSchema{
            return false
        }
        return true
    }
}
