//
//  pomodoroWindowController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class pomodoroWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {

        appdelegate?.setTimerForPomodoroMode(delay: 60*10)//todo jitni bar window close hoti hai utni bar timer lag jata hai jisse multile timer hote hai or window agar 3 bar kholer kar  3 bar close ki to 3 timer ho gaye to 3 bar bari se window show hoti hai
        return true
    }

}
