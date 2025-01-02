//
//  blankLayerWc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/03/24.
//

import Cocoa

class blankLayerWc: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        window!.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
        window!.canHide = false
        window!.isExcludedFromWindowsMenu = true
        window!.hidesOnDeactivate = false
        window!.isRestorable = false
        window!.animationBehavior = .none
        window!.styleMask = .borderless
        window!.backingType = .buffered
        window!.backgroundColor = NSColor.clear
        self.window?.minSize = NSSize(width: 900, height: 500)// unused
        self.window?.title = ""
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        self.window?.appearance = getAppAppearance()
    }

}
