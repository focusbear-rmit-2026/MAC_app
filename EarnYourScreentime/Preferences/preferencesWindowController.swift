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
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
   func windowShouldClose(_ sender: NSWindow) -> Bool {
       if isGettingSchema{
           return false
       }
    if selectJsonVcObj != nil{
        selectJsonVcObj!.boxWidthConstraint.constant = 500
        selectJsonVcObj!.boxHeightConstraint.constant = 350
        selectJsonVcObj!.customView.isHidden = true
        selectJsonVcObj!.textscrollView.isHidden = true
        selectJsonVcObj!.lblTitle.isHidden = true
        selectJsonVcObj!.lblVisitUrl.isHidden = true
        selectJsonVcObj!.btnCancel.isHidden = true
        selectJsonVcObj!.btnSave.isHidden = true
    }
       return true
   }
}

