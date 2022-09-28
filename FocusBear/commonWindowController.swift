//
//  commonWindowController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class commonWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if appdelegate!.user == nil{
            if self.contentViewController == getAskLogInVcObject(){
                addLog(text: "Ask Login View window close:- quit app")
//                shell(launchPath: "/bin/launchctl", arguments: // no need beacuse unloding launchagent when logout ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
                appdelegate?.terminateFromSelf = true
                NSApp.terminate(self)
            }
        }else if onboardingVideoVcObj != nil{
            if self.contentViewController == onboardingVideoVcObj{
                addLog(text: "Ask Login View window close:- quit app")
                onboardingVideoVcObj?.loadBlankUrl()
            }
        }
        
        return true
    }
}
