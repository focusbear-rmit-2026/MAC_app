//
//  mainWindowController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class mainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        
    //todo
        window!.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these
        window!.canHide = false
        window!.isExcludedFromWindowsMenu = true
        window!.hidesOnDeactivate = false
        window!.isRestorable = false
        window!.animationBehavior = .none
        window!.styleMask = .borderless
        window!.backingType = .buffered
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        
        
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        
        
        self.contentViewController =  mainViewControllerObj
       
  
    }
//    @objc func preventRecording(){
//        avmonitor.preventWindow(fromBeingCaptured: self.window)
//    }
//    func preventWindowFromBeingCaptured(){
//
//    }
//    @objc func setframe() {
//        let screenList = NSScreen.screens
//        for screen in screenList {  // create the corresponding windows
//            //                     resetWin(BGWindow(contentRect: NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), styleMask: .borderless, backing: .buffered, defer: true, screen: screen))
//            self.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
//            break;
//        }
//    }
    
}
