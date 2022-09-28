//
//  activationWindowController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 04/02/22.

//

import Cocoa

class activationWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
    }

    func showSevenDayTrialVc(){
        addLog(text: "Showing Seven day trial view")
        self.contentViewController = sevenDaysTrialvcObj
        self.showWindow(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showActivateNowVc(){
        self.contentViewController = activateNowvcObj
        self.showWindow(self)
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if !isAppInitialLodded{
            if isPurchased == false && daysLeft <= 0{//UserDefaults.standard.object(forKey: "trialExpired") != nil{//agar exipire ho chuka h to app quit ni hogi
                
            }else{
                self.window?.close()
                appdelegate?.initialWork()
            }
        }
        return true
    }
}
