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
    func windowDidBecomeKey(_ notification: Notification) {
//        if self.window == brainDumpWcObj?.window{
//            print("windowDidBecomeKey")
//            brainDumpVcObj?.checkCurrentUrl()
//        }
    }

    func windowDidResignKey(_ notification: Notification) {
//        if self.window == brainDumpWcObj?.window{
//            print("windowDidResignKey")
//        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if permissionBlockDistractionWcObj != nil{
            if self == permissionBlockDistractionWcObj{
                allApiObject.capturePosthog(event: "permission-popup-closed", metadata: [:])
                return true
            }
        }
        
        if todoListToolVcObj != nil{
            if self.contentViewController == todoListToolVcObj{
                allApiObject.capturePosthog(event: "todo-list-popup-closed", metadata: [:])
                return true
            }
        }
        
        if upgradeToProNagVcObj != nil{
            if self.contentViewController == upgradeToProNagVcObj{
                upgradeToProNagVcObj?.btnContinueClicked(self)
                return false
            }
        }
        
        if upgradeNowVcObj != nil{
            if self.contentViewController == upgradeNowVcObj{
                upgradeNowVcObj?.btnContinueClicked(self)
                return false
            }
        }
        
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
        
        if self == breakWarningWcObj{
            breakWarningVcObj?.timer?.invalidate()
            activityPostponeCount += 1
            getHabitsVcObject().postponeBreakActivitiesFor(minutes: 5, secondsToPostpone: nil, isFromBreakWarningWindow: true)
            return true
        }
        
        if popUpOfflineWcObj != nil{
            if self == popUpOfflineWcObj{
                addLog(text: "pop Up Offline Window close :- quit app")
                appdelegate?.terminateFromSelf = true
                quitApplicationSmoothly()
                return true
            }
        }
        
        if intentionBlockedUrlsWcObj != nil{
            if self == intentionBlockedUrlsWcObj{
                addLog(text: "intention Blocked Urls window close")
                let url = intentionBlockedUrlsVcObj?.tabUrl ?? ""
                for i in 0..<arrAlwaysBlockedSitesData.count{
                    var dictionary = arrAlwaysBlockedSitesData[i]
                    if let blockUrl = dictionary["url"] as? String{
                        if blockUrl.lowercased() == url.lowercased(){
                            dictionary["closed"] = true
                            arrAlwaysBlockedSitesData[i] = dictionary
                            break;
                        }
                    }
                    
                }
                return true
            }
        }
        
        if intentionBlockedAppsWcObj != nil{
            if self == intentionBlockedAppsWcObj{
                addLog(text: "intention Blocked Apps window close")
                let appName = intentionBlockedAppsVcObj?.blockedAppName ?? ""
                for i in 0..<arrAlwaysBlockedAppsData.count{
                    var dictionary = arrAlwaysBlockedAppsData[i]
                    if let blockApp = dictionary["app"] as? String{
                        if blockApp.lowercased() == appName.lowercased(){
                            dictionary["closed"] = true
                            arrAlwaysBlockedAppsData[i] = dictionary
                            break;
                        }
                    }
                    
                }
                return true
            }
        }
        
//        if endingFocusWindowControllerObj != nil{
//            if self == endingFocusWindowControllerObj{
//                addLog(text: "focus mode completed Window close")
//                focusCompletedVcObj!.takeBreakClicked(isCloseWindowClicked: true)
//                return false
//            }
//        }
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
//        else if onboardingVideoVcObj != nil{
//            if self.contentViewController == onboardingVideoVcObj{
//                addLog(text: "onboarding video window close")
//                onboardingVideoVcObj?.loadBlankUrl()
//                appdelegate!.loadCredentialsAndDeviceId()
//                let secondsBetween = Date().timeIntervalSince(onboardingVideoStartTime ?? Date())
//                allApiObject.capturePosthog(event: "onboarding-video-watched", metadata: ["watched_duration_seconds":Int(secondsBetween)])
//                showMenuTourWindow()
//                appdelegate!.statusbutton?.action = nil
//            }
//        }
        
        return true
    }
}
