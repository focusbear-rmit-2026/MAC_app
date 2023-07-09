//
//  preferencesWindowController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 09/02/22.

//

import Cocoa

class preferencesWindowController: NSWindowController, NSWindowDelegate  {

    var extraSpaceHeightInSettingsTab = 142
    var extraSpaceWidthInSettingsTab = 46
    var settingsTabDefaultWidth = 630
    var settingsTabDefaultWidthForBigFonts = 780//630+150// Big fonts are IntelOneMono and OpenDyslexic

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        self.window?.appearance = getAppAppearance()
        self.window?.styleMask.remove(.miniaturizable)
    }
    
   func windowShouldClose(_ sender: NSWindow) -> Bool {
       if isGettingSchema{
           return false
       }
       return true
   }
}

