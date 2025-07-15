//
//  mainWindowController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class mainWindowController: NSWindowController, NSWindowDelegate {
    
    let smallWindowMinWidth = 1008
    let smallWindowMinHeight = 600
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if checkIsFullScreenEnabled(){
            showFullSizeWindow()
        }else{
            showSmallSizeWindow()
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        
        self.window?.appearance = getAppAppearance()
        self.contentViewController =  mainViewControllerObj
    }
    
    
    func showFullSizeWindow(){
        window!.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these
        window!.canHide = false
        window!.isExcludedFromWindowsMenu = true
        window!.hidesOnDeactivate = false
        window!.isRestorable = false
        window!.animationBehavior = .none
        window!.styleMask = .borderless
        window!.backingType = .buffered
        self.window?.minSize = NSSize(width: 900, height: 500)// unused
        self.window?.title = ""
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        
        if isMainWindowLoaded{
            mainViewControllerObj!.boxTopButtons.isHidden = false
            mainViewControllerObj!.startDateTimer()
            if self.window?.isVisible ?? false{
                mainViewControllerObj?.setframe()
            }
            let btnTitle = "Please spare me"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                mainViewControllerObj?.btnAbort.title = common.value(forKey: "buttonAbortText") as? String ?? btnTitle
            }
        }
    }
    
    func showSmallSizeWindow(){
        window!.isRestorable = true
        window!.collectionBehavior = [.fullScreenAllowsTiling, .fullScreenPrimary]
        self.window?.styleMask = [.resizable, .titled]
        self.window?.minSize = NSSize(width: smallWindowMinWidth, height: smallWindowMinHeight)
        window!.isExcludedFromWindowsMenu = false
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.floatingWindow)))
        self.window?.title = appName
        
        if isMainWindowLoaded{
            mainViewControllerObj!.boxTopButtons.isHidden = true
            mainViewControllerObj!.dateTimeTimer?.invalidate()
            mainViewControllerObj!.lblCurrentDateTime.isHidden = true
            if mainViewControllerObj?.btnAbort.isHidden ?? false{
                self.window?.styleMask.remove(.closable)
            }else{
                self.window?.styleMask.insert(.closable)
            }
            
            let btnTitle = "Postpone"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                mainViewControllerObj?.btnAbort.title = common.value(forKey: "buttonPostponeText") as? String ?? btnTitle
            }
            if currentState == ._ASK_APP_WORK_{
                let btnTitle = "Skip"
                if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                    mainViewControllerObj?.btnAbort.title = dic.value(forKey: "buttonSkipText") as? String ?? btnTitle
                }
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        addLog(text: "windowShouldClose delegate called")
        let views = mainViewControllerObj?.view.subviews ?? []
        if views.count != 1{// it means sub views are added so nothing will happen, user will need to close subviews first(logquantity view, password box)
            return false
        }
        mainViewControllerObj?.abortCurrentState()
        return false
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        print("windowWillEnterFullScreen****")
        if !checkIsFullScreenEnabled(){
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
                if !state{
                    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
                }
            }
        }
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        print("windowWillExitFullScreen****")
        if !checkIsFullScreenEnabled(){
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
                if !state{
                    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
        
    }
}
