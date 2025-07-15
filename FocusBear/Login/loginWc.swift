//
//  loginWc.swift
//  Focus Bear
//
//  Created by Manish Jain on 09/07/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class loginWc: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        self.window?.appearance = getAppAppearance()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if appdelegate!.user == nil && askLogInWcObj != nil{
            if self == askLogInWcObj{
                if self.contentViewController == getAskLogInVcObject(){
                    allApiObject.capturePosthog(event: "login-window-closed", metadata: [:])
                    addLog(text: "Ask Login View window close:- quit app")
                    appdelegate?.terminateFromSelf = true
                    quitApplicationSmoothly()
                }
                
                if self.contentViewController == getCustomLoginVcObject(){
                    allApiObject.capturePosthog(event: "login-window-closed", metadata: [:])
                    addLog(text: "custom Login View window close:- quit app")
                    appdelegate?.terminateFromSelf = true
                    quitApplicationSmoothly()
                }
            }
        }
        return true
    }
}
