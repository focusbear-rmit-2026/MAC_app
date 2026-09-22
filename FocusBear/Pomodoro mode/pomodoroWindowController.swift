//
//  pomodoroWindowController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class pomodoroWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        self.window?.appearance = getAppAppearance()
    }
    
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if SettingsManagerObject.isGeekModeEnabled{
            if pomodoroVcObj?.isShowingMorningPomodoro ?? false{
                appdelegate?.setTimerForPomodoroMode(delay: 60*10)
            }
        }
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
        return true
    }
}
