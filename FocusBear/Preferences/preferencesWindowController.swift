//
//  preferencesWindowController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 09/02/22.

//

import Cocoa

class preferencesWindowController: NSWindowController, NSWindowDelegate  {

    var extraSpaceHeightInSettingsTab = 142
    var extraSpaceWidthInSettingsTab = 46
    var settingsTabDefaultWidth = 800
    var settingsTabDefaultWidthForBigFonts = 950//630+150// Big fonts are IntelOneMono and OpenDyslexic
    let spaceKeyCode:uint16 = 49
    let escKeyCode:uint16 = 53
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow))) // todo 
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        self.window?.appearance = getAppAppearance()
        self.window?.styleMask.remove(.miniaturizable)
    }
    
   func windowShouldClose(_ sender: NSWindow) -> Bool {
       if areSettingsEdited{
           showAlertSettingsEdited()
           areSettingsEdited = false
           return false
       }
       if isGettingSchema{
           return false
       }
       return true
   }

    override func keyDown(with event: NSEvent) {
        print(event.keyCode)

        if pomodoroSettingsVcObj == nil{
            super.keyDown(with: event)
            return;
        }

        if !pomodoroSettingsVcObj!.isAddingPomodoroShortcut{
            super.keyDown(with: event)
            return;
        }
        var handled = false
        if event.keyCode == escKeyCode { // ESC, same as `CMD + .`
            handled = true
            print("ESC")
        }
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option) || event.modifierFlags.contains(.control) || event.modifierFlags.contains(.shift) || event.specialKey != nil{
            
            if var chars = event.charactersIgnoringModifiers {
                
                if chars == "<"{
                    chars = ","
                }else if chars == ">"{
                    chars = "."
                }
                if let specialKey = event.specialKey{
                    switch specialKey {
                    case .f1:
                        char = "f1"
                    case .f2:
                        char = "f2"
                    case .f3:
                        char = "f3"
                    case .f4:
                        char = "f4"
                    case .f5:
                        char = "f5"
                    case .f6:
                        char = "f6"
                    case .f7:
                        char = "f7"
                    case .f8:
                        char = "f8"
                    case .f9:
                        char = "f9"
                    case .f10:
                        char = "f10"
                    case .f11:
                        char = "f11"
                    case .f12:
                        char = "f12"
                    default:
                        char = "f12"
                    }
                }else if event.keyCode == spaceKeyCode {
                    char = "space"
                }else{
                    char = chars
                }

                let errArray = ["c", "v", "z", "f", ",", "h", "q", "n", "z", "a", "x", "\r", "m", "-", "+" ]
                var iserror = false
                if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.option) && !event.modifierFlags.contains(.control) && !event.modifierFlags.contains(.shift){
                    
                    if errArray.contains(char.lowercased()){
                        iserror = true
                    }
                }
                
                if event.modifierFlags.contains(.numericPad){
                    switch char {
                    case "0":
                        char = "keypad0"
                    case "1":
                        char = "keypad1"
                    case "2":
                        char = "keypad2"
                    case "3":
                        char = "keypad3"
                    case "4":
                        char = "keypad4"
                    case "5":
                        char = "keypad5"
                    case "6":
                        char = "keypad6"
                    case "7":
                        char = "keypad7"
                    case "8":
                        char = "keypad8"
                    case "9":
                        char = "keypad9"
                    case ".":
                        char = "keypaddecimal"
                    case "*":
                        char = "keypadmultiply"
                    case "+":
                        char = "keypadplus"
                    case "/":
                        char = "keypaddivide"
                    case "-":
                        char = "keypadminus"
                    default:
                        char = "keypad0"
                    }
                }
                if iserror == true{
                    char = ""
                    flags = []
 
                    pomodoroSettingsVcObj?.lblrecordShorcutPomodoro.stringValue = ""
 
                    
                    let alertShortcutFailed = NSAlert()
                    alertShortcutFailed.setSharingType()
                    alertShortcutFailed.alertStyle = .informational
                    alertShortcutFailed.messageText =  "Please use a different key combination."
                    if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                        alertShortcutFailed.messageText = preferencesInfo.value(forKey: "alertShortcutErrorText") as? String ?? alertShortcutFailed.messageText
                    }
                    alertShortcutFailed.addButton(withTitle: buttonOkText)
                    
                    alertShortcutFailed.beginSheetModal(for: self.window!, completionHandler: { (modalResponse) in
                        if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                            
                        }

                    })
                    return
                }
                
                flags = event.modifierFlags

                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.startPomodoroShortcutChar = char
                var flagsarr = [Int]()
                
                if event.modifierFlags.contains(.control){
                    flagsarr.append(shortcutFlags._CONTROL_.rawValue)
                }
                if event.modifierFlags.contains(.option){
                    flagsarr.append(shortcutFlags._OPTION_.rawValue)
                }
                if event.modifierFlags.contains(.shift){
                    flagsarr.append(shortcutFlags._SHIFT_.rawValue)
                }
                if event.modifierFlags.contains(.command){
                    flagsarr.append(shortcutFlags._COMMAND_.rawValue)
                }
                
                pomodoroSettingsVcObj?.lblrecordShorcutPomodoro.stringValue = "\(event.modifierFlags)\(char)"
                SettingsManagerObject.startPomodoroShortcutFlags = flagsarr
                appdelegate?.registerPomodoroShortcut()

                handled = true // likely we are interested with that key
                pomodoroSettingsVcObj!.shortcutAdded()
                
                switch char {
                case "r":
                    print("CMD + r")
                case ",":
                    print("CMD + ,")
                case "/":
                    print("CMD + /")
                default:
                    handled = false
                }
            }
        }
        if !handled {
            
            // super.keyDown(with: event) // let system handle it(may contains sound)
        }
    }
    func showAlertSettingsEdited(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var message = "You've made changes to your habits/breaks but haven't saved them yet. It is recommended to review and save the changes (the app will restart)?"
        var buttonReviewSettingsText = "I'll review and Save"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            message = settings.value(forKey: "settingsEditedButNotSavedText") as? String ?? message
            buttonReviewSettingsText = settings.value(forKey: "buttonReviewSettingsText") as? String ?? buttonReviewSettingsText
        }
        alert.messageText = message
        alert.addButton(withTitle: buttonReviewSettingsText)
        
        alert.beginSheetModal(for: self.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
            }
            
            
        })
    }
    func shortcutFailed_alert(){
        char = ""
        flags = []
        pomodoroSettingsVcObj?.lblrecordShorcutPomodoro.stringValue = ""

        let alertShortcutFailed = NSAlert()
        alertShortcutFailed.setSharingType()
        alertShortcutFailed.alertStyle = .informational
        alertShortcutFailed.messageText = "Please use a different key combination."
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            alertShortcutFailed.messageText = preferencesInfo.value(forKey: "alertShortcutErrorText") as? String ?? alertShortcutFailed.messageText
        }
        alertShortcutFailed.addButton(withTitle: buttonOkText)
        alertShortcutFailed.beginSheetModal(for: self.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                
            }
            char = ""
            flags = []
            
            pomodoroSettingsVcObj?.lblrecordShorcutPomodoro.stringValue = ""
            pomodoroSettingsVcObj?.btnRecordShortcutPomodoroClicked(self)
            
        })
    }
}

