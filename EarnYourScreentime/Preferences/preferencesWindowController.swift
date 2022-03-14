//
//  preferencesWindowController.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 09/02/22.

//

import Cocoa

class preferencesWindowController: NSWindowController, NSWindowDelegate  {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
   func windowShouldClose(_ sender: NSWindow) -> Bool {
       if isGettingSchema{
           return false
       }
       return true
   }
}
