//
//  pomodoroWindowController.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class pomodoroWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
        
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        appdelegate?.setTimerForPomodoroMode(delay: 60*10)
        return true
    }

}
