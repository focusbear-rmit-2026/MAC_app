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
        
        
//        if #available(macOS 11.0, *) {
//            let searchItem = NSSearchToolbarItem(itemIdentifier: .searchItem)
//            
//        } else {
//            // Fallback on earlier versions
//        }
      //  window?.toolbar?.insertItem(withItemIdentifier: .searchItem, at: 0)
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        self.window?.appearance = getAppAppearance()
        
        self.window?.styleMask.remove(.miniaturizable)
//        self.window?.toolbar?.fullScreenAccessoryView?.bounds
    }
    
   func windowShouldClose(_ sender: NSWindow) -> Bool {
       if isGettingSchema{
           return false
       }
//       isSettingsChanged = false
//    if selectJsonVcObj != nil{
//        selectJsonVcObj!.boxWidthConstraint.constant = 500
//        selectJsonVcObj!.boxHeightConstraint.constant = 350
//        selectJsonVcObj!.customView.isHidden = true
//        selectJsonVcObj!.textscrollView.isHidden = true
//        selectJsonVcObj!.lblTitle.isHidden = true
//        selectJsonVcObj!.lblVisitUrl.isHidden = true
//        selectJsonVcObj!.btnCancel.isHidden = true
//        selectJsonVcObj!.btnSave.isHidden = true
//    }
       return true
   }
}

