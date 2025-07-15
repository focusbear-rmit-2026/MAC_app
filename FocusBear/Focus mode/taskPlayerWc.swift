//
//  taskPlayerWc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/10/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class taskPlayerWc: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        self.window?.appearance = getAppAppearance()
        self.window?.isMovableByWindowBackground = true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {

        if taskPlayerVcObj != nil && UserDefaults.standard.object(forKey: kUserdefaultsToDoPlayerWindowClosedFirstTime) == nil && SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
            if self.contentViewController == taskPlayerVcObj{
                UserDefaults.standard.set(true, forKey: kUserdefaultsToDoPlayerWindowClosedFirstTime)
                let alert = NSAlert()
                alert.setSharingType()
                
                var alertStopLaunchingToDoPlayer = "Do you want to stop the To Do player from launching automatically?"
                var buttonKeepItText = "Keep it"
                var buttonDontShowText = "Don't Show it Again"
                
                if let toDoPlayerVcInfo = configjson.value(forKey: "toDoPlayerVcInfo") as? NSDictionary{
                    alertStopLaunchingToDoPlayer = toDoPlayerVcInfo.value(forKey: "alertStopLaunchingToDoPlayer") as? String ?? alertStopLaunchingToDoPlayer
                    buttonKeepItText = toDoPlayerVcInfo.value(forKey: "buttonKeepItText") as? String ?? buttonKeepItText
                    buttonDontShowText = toDoPlayerVcInfo.value(forKey: "buttonDontShowText") as? String ?? buttonDontShowText
                }
                    
                alert.messageText = alertStopLaunchingToDoPlayer
                alert.addButton(withTitle: buttonKeepItText)
                alert.addButton(withTitle: buttonDontShowText)
                
                alert.beginSheetModal(for: self.window!, completionHandler: {result in
                    if result == .alertSecondButtonReturn{
                        SettingsManagerObject.isSettingsChanged = true
                        SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = false
                        SettingsManagerObject.putUserLocalDeviceSettings()
                    }
                    self.window?.close()
                })
                return false;
            }
        }
        return true
    }
}
