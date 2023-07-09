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
        self.window?.appearance = getAppAppearance()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        
        if self == breakWarningWcObj{
            breakWarningVcObj?.timer?.invalidate()
            activityPostponeCount += 1
            mainViewControllerObj?.postponeBreakActivitiesFor(minutes: 5, secondsToPostpone: nil)
            return true
        }
        
        if popUpOfflineWcObj != nil{
            if self == popUpOfflineWcObj{
                addLog(text: "pop Up Offline Window close :- quit app")
                appdelegate?.terminateFromSelf = true
                NSApp.terminate(self)
                return true
            }
        }
        if endingFocusWindowControllerObj != nil{
            if self == endingFocusWindowControllerObj{
                addLog(text: "focus mode completed Window close")
                focusCompletedVcObj!.btnTakeBreakClicked(self)
                return false
            }
        }
        if appdelegate!.user == nil{
            if askLogInWcObj != nil{
                if self.contentViewController == getAskLogInVcObject(){
                    addLog(text: "Ask Login View window close:- quit app")
                    appdelegate?.terminateFromSelf = true
                    NSApp.terminate(self)
                }
                
                if self.contentViewController == getCustomLoginVcObject(){
                    addLog(text: "custom Login View window close:- quit app")
                    appdelegate?.terminateFromSelf = true
                    NSApp.terminate(self)
                }
            }
        }else if onboardingVideoVcObj != nil{
            if self.contentViewController == onboardingVideoVcObj{
                addLog(text: "onboarding video window close")
                onboardingVideoVcObj?.loadBlankUrl()
                appdelegate!.loadCredentialsAndDeviceId()
                let secondsBetween = Date().timeIntervalSince(onboardingVideoStartTime ?? Date())
                allApiObject.capturePosthog(event: "onboarding-video-watched", metadata: ["watched_duration_seconds":Int(secondsBetween)])
                showMenuTourWindow()
            }
        }
        
        return true
    }
}
