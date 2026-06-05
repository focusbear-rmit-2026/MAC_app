//
//  DNDManager.swift
//  FocusBear
//
//  Created by Manish Jain on 28/05/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


class DNDManager {
    static let shared = DNDManager()
    var isDndEnabled = false
    func setDND(_ enable: Bool) {
        addLog(text: "Request DND: \(enable)")
        if enable{
            if isDndEnabled{
                addLog(text: "Return:- Already enabled")
                return;
            }
            if isDNDOrFocusActive(){
                addLog(text: "Return:- Dnd Already enabled")
                return;
            }
        }else{
            if !isDndEnabled{
                addLog(text: "Return:- Already disabled")
                return;
            }
        }
        isDndEnabled = !isDndEnabled
        addLog(text: "Local DND state updated: \(enable)")
        optionClickClock()
        // Usage
    }

//    func optionClickClock() {
//        guard let menuBarScreen = NSScreen.main else { return }
//        
//        // NSScreen.frame is in AppKit flipped coords (Y up from bottom of primary screen)
//        // CGEvent uses CG coords (Y down from top of primary screen)
//        // Convert: CGY = primaryScreenHeight - (frame.origin.y + frame.height)
//        
//        let primaryScreenHeight = NSScreen.screens[0].frame.height
//        let screenFrame = menuBarScreen.frame
//        
//        // Top-right of the menu bar screen in CG coordinates
//        let cgY = primaryScreenHeight - (screenFrame.origin.y + screenFrame.height)
//        let cgX = screenFrame.origin.x + screenFrame.width - 60
//        
//        let clickPoint = CGPoint(x: cgX, y: cgY + 11)
//
//        let src = CGEventSource(stateID: .combinedSessionState)
//
//        let down = CGEvent(mouseEventSource: src,
//                           mouseType: .leftMouseDown,
//                           mouseCursorPosition: clickPoint,
//                           mouseButton: .left)
//        down?.flags = .maskAlternate
//
//        let up = CGEvent(mouseEventSource: src,
//                         mouseType: .leftMouseUp,
//                         mouseCursorPosition: clickPoint,
//                         mouseButton: .left)
//        up?.flags = .maskAlternate
//
//        down?.post(tap: .cgSessionEventTap)
//        Thread.sleep(forTimeInterval: 0.05)
//        up?.post(tap: .cgSessionEventTap)
//    }
    func optionClickClock() {
//        // 1. Force the system to reveal the auto-hidden menu bar
//         NSApp.presentationOptions = [.autoHideMenuBar]
//         
//         // 2. Restore normal behavior after a brief delay so it doesn't get locked open.
//         // The menu bar will remain slid down until the user interacts or clicks away.
//         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//             NSApp.presentationOptions = []
//         }
//        return;
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                guard let menuBarScreen = NSScreen.main else { return }
                
                // Save current mouse position
                let oldLocation = NSEvent.mouseLocation
                
                let primaryScreenHeight = NSScreen.screens[0].frame.height
                let screenFrame = menuBarScreen.frame
                
                let cgY = primaryScreenHeight - (screenFrame.origin.y + screenFrame.height)
                let cgX = screenFrame.origin.x + screenFrame.width - 60
                
                let menuBarHidePosition = CGPoint(x: cgX, y: cgY)
                
                let clickPoint = CGPoint(x: cgX, y: cgY + 11)
                
                // Move cursor first to reveal auto-hidden menu bar
                CGWarpMouseCursorPosition(menuBarHidePosition)
                
                if let move = CGEvent(
                    mouseEventSource: nil,
                    mouseType: .mouseMoved,
                    mouseCursorPosition: menuBarHidePosition,
                    mouseButton: .left
                ) {
                    move.post(tap: .cgSessionEventTap)
                }
                
                //        Thread.sleep(forTimeInterval: 0.1)
                //        let menuBarHidePositionEdge = CGPoint(x: cgX-1, y: cgY)
                //        CGWarpMouseCursorPosition(menuBarHidePositionEdge)
                // Give macOS time to show menu bar
                //        Thread.sleep(forTimeInterval: 0.5)
                //        return;
                DispatchQueue.global().async {
                    //            usleep(200000)
                    sleep(1)
                    DispatchQueue.main.async {
                        let src = CGEventSource(stateID: .combinedSessionState)
                        
                        let down = CGEvent(
                            mouseEventSource: src,
                            mouseType: .leftMouseDown,
                            mouseCursorPosition: clickPoint,
                            mouseButton: .left
                        )
                        down?.flags = .maskAlternate
                        
                        let up = CGEvent(
                            mouseEventSource: src,
                            mouseType: .leftMouseUp,
                            mouseCursorPosition: clickPoint,
                            mouseButton: .left
                        )
                        up?.flags = .maskAlternate
                        
                        down?.post(tap: .cgSessionEventTap)
                        Thread.sleep(forTimeInterval: 0.05)
                        up?.post(tap: .cgSessionEventTap)
                        
                        // Restore cursor position
                        let primaryHeight = NSScreen.screens[0].frame.height
                        
                        let quartzPoint = CGPoint(
                            x: oldLocation.x,
                            y: primaryHeight - oldLocation.y
                        )
                        Thread.sleep(forTimeInterval: 0.05)// to prevent opening right menu 3.32.491
                        CGWarpMouseCursorPosition(quartzPoint)
                        if let move = CGEvent(
                            mouseEventSource: nil,
                            mouseType: .mouseMoved,
                            mouseCursorPosition: quartzPoint,
                            mouseButton: .left
                        ) {
                            move.post(tap: .cgSessionEventTap)
                        }
                    }
                }
            }
        }
    }
    
    func isDNDOrFocusActive() -> Bool {
        let defaults = UserDefaults.standard
        //isDNDIconInMenuBar()
        // Read the persistent domain for the Control Center directly
        defaults.synchronize()
        if let controlCenterPrefs = defaults.persistentDomain(forName: "com.apple.controlcenter") {
            
            // 1. Check the universal master focus visibility token (macOS 13+)
            if let focusModeState = controlCenterPrefs["NSStatusItem Visible FocusModes"] as? Int, focusModeState == 1 {
                return true
            }
            
            // 2. Check the legacy standalone DND visibility token
            if let dndState = controlCenterPrefs["NSStatusItem Visible DoNotDisturb"] as? String, dndState == "1" {
                return true
            }
        }
        
        return false
    }
}
