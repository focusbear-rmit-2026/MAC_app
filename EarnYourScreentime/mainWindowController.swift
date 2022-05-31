//
//  mainWindowController.swift
//  EarnYourScreentime
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
        
        self.contentViewController =  mainViewControllerObj
        
//        setframe()
//        self.perform(#selector(setframe), with: nil, afterDelay: 0)
    }

//    @objc func setframe() {
//        let screenList = NSScreen.screens
//        for screen in screenList {  // create the corresponding windows
//            //                     resetWin(BGWindow(contentRect: NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), styleMask: .borderless, backing: .buffered, defer: true, screen: screen))
//            self.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
//            break;
//        }
//    }
    
}
