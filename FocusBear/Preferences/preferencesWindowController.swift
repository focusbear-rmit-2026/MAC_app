//
//  preferencesWindowController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 09/02/22.

//

import Cocoa

class preferencesWindowController: NSWindowController, NSWindowDelegate  {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        
        self.window?.styleMask.remove(.miniaturizable)
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

