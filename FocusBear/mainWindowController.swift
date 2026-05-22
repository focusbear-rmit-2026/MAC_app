//
//  mainWindowController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class mainWindowController: NSWindowController, NSWindowDelegate {
    
    let smallWindowMinWidth = 900
    let smallWindowMinHeight = 450
    let smallWindowAvgHeight = 600
    let smallWindowAvgWidth = 1008
    let spaceKeyCode:uint16 = 49
    let escKeyCode:uint16 = 53
    
    var isFullScreenVisible = false
    override func windowDidLoad() {
        super.windowDidLoad()
        
//        if checkIsFullScreenEnabled(){
//            showFullSizeWindow()
//        }else{
//            showSmallSizeWindow()
//        }
       // showSmallSizeWindow()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window?.sharingType = .none
            }
        }
        
        self.window?.appearance = getAppAppearance()
        self.contentViewController =  mainViewControllerObj
    }
    
    
    func showFullSizeWindow(){
        isFullScreenVisible = true
        window!.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these
        window!.canHide = false
        window!.isExcludedFromWindowsMenu = true
        window!.hidesOnDeactivate = false
        window!.isRestorable = false
        window!.animationBehavior = .none
//        window!.styleMask = .borderless
        window!.styleMask = [.borderless, .resizable]// The window needs to be resizable because when a new screen is added at runtime, the window reframe does not work properly.// resizable added on 1/9/25 on version 2.27.408
        window!.backingType = .buffered
        self.window?.minSize = NSSize(width: 900, height: 450)// unused
        self.window?.title = ""
        
        if isMainWindowLoaded{
            mainViewControllerObj!.boxTopButtons.isHidden = false
            habitsVcObj?.startDateTimer()
            if self.window?.isVisible ?? false{
               // mainViewControllerObj?.setframe() //
            }
            let btnTitle = "Please spare me"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                habitsVcObj?.btnAbort.title = common.value(forKey: "buttonAbortText") as? String ?? btnTitle // 
            }
        }
    }
    
    func showSmallSizeWindow(){
        isFullScreenVisible = false
        window!.isRestorable = true
        window!.collectionBehavior = [.fullScreenAllowsTiling, .fullScreenPrimary]
        self.window?.minSize = NSSize(width: smallWindowMinWidth, height: smallWindowMinHeight)
        if !(self.window?.styleMask.contains(.fullScreen) ?? false){// It means the user was on a small screen and clicked full screen, so no change is needed. If we change the styleMask at this stage, it may cause a crash.
            window!.styleMask = []
            window!.styleMask.insert([.titled, .closable, .resizable])// works good
        }
        
//        self.window?.styleMask = [.resizable, .titled, .closable]// don't use this
        window!.isExcludedFromWindowsMenu = false
        self.window?.title = appName
        window!.animationBehavior = .default
        window!.hasShadow = true
        window!.canHide = true
       
        if isMainWindowLoaded{
            mainViewControllerObj!.boxTopButtons.isHidden = true
            habitsVcObj?.dateTimeTimer?.invalidate()
            habitsVcObj?.lblCurrentDateTime.isHidden = true
         
            let btnTitle = "Postpone"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                habitsVcObj?.btnAbort.title = common.value(forKey: "buttonPostponeText") as? String ?? btnTitle
            }
            if currentState == ._ONBOARDING_{
                let btnTitle = "Skip"
                if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                    habitsVcObj?.btnAbort.title = dic.value(forKey: "buttonSkipText") as? String ?? btnTitle
                }
            }
        }
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {// The window needs to be resizable because when a new screen is added at runtime, the window reframe does not work properly.// resizable added on 1/9/25 on version 2.27.408
        if isFullScreenVisible{
            return sender.frame.size // ignore user resize
        }else{
            return frameSize
        }
    }
    
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        addLog(text: "windowShouldClose delegate called")
        
        if currentState == ._ONBOARDING_ || currentState == ._LOGIN_{
            NSApp.terminate(self)
            return false;
        }
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._CUSTOM_ROUTINE_{
            if isAnyAllowedFocusModeActivityRunning && !(leftMenuVcObj?.boxHabits.isSelected ?? false){ // allowed focus mode habit will be running in background
                if currentAction == ._INPROGRESS_{
                    if timerViewcontrollerObj?.isActivityPaused ?? false{
                        leftMenuVcObj?.showHabitsView()
                        timerViewcontrollerObj?.btnPauseClicked(self)
                        return false
                    }
                }
                return true
            }
            
            // window close if allowed if non timer based habits are running
            if currentAction == ._INPROGRESS_{
                if currentHabitPlaying != nil{
                    if timerViewcontrollerObj?.isActivityPaused ?? false{
                        leftMenuVcObj?.showHabitsView()
                        timerViewcontrollerObj?.btnPauseClicked(self)
                        return false
                    }else{
                        return true
                    }
                }else if currentRelaxHabitPlaying != nil{
                    if relaxModeWcObj != nil{
                        if timerViewcontrollerObj?.isActivityPaused ?? false{
                            leftMenuVcObj?.showHabitsView()
                            timerViewcontrollerObj?.btnPauseClicked(self)
                            return false
                        }else{
                            return true
                        }
                    }
                }
            }
            
            
            if currentState == ._MICRO_BREAK_ {// if break warning is visble then close window is allowed to user. after end of warning window will be visible again
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        return true
                    }
                }
            }
            
            let views = getHabitsVcObject().view.subviews
            if views.count != 1{// it means sub views are added so nothing will happen, user will need to close subviews first(logquantity view, password box)
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                    if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
                        leftMenuVcObj?.showHabitsView()
                    }
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if !(leftMenuVcObj?.boxCustomRoutine.isSelected ?? false){
                        leftMenuVcObj?.showCustomRoutineView()
                    }
                }else if currentState == ._MICRO_BREAK_{
                    if !(leftMenuVcObj?.boxMicroBreaks.isSelected ?? false){
                        leftMenuVcObj?.showBreaksView()
                    }
                }
                
                return false
            }

            if habitsVcObj?.btnAbort.isHidden ?? false{
                return false
            }else{
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                    if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
                        leftMenuVcObj?.showHabitsView()
                    }
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if !(leftMenuVcObj?.boxCustomRoutine.isSelected ?? false){
                        leftMenuVcObj?.showCustomRoutineView()
                    }
                }else if currentState == ._MICRO_BREAK_{
                    if !(leftMenuVcObj?.boxMicroBreaks.isSelected ?? false){
                        leftMenuVcObj?.showBreaksView()
                    }
                }
                getHabitsVcObject().abortCurrentState()
            }
           
            return false
        }
        
        if currentState == ._ONBOARDING_{
            getHabitsVcObject().abortCurrentState()
            return false
        }
        
        
        if leftMenuVcObj?.boxEditHabits.isSelected ?? false{
            if areSettingsEdited{
                leftMenuVcObj?.showAlertSettingsEdited()
                areSettingsEdited = false
                return false
            }
        }
        
        
        if isFocusCompletedViewVisibled(){
            addLog(text: "focus mode completed Window auto close from window close")
            focusCompletedVcObj!.takeBreakClicked(isCloseWindowClicked: true)
            return true
        }
        
        if isGettingSchema{
            return false
        }
        
        if currentState == ._SHUTOFFMAC_{
            if !(shutOffTimeVcObj?.btnGetAccessNow.isHidden ?? true){
                if mainViewControllerObj?.isEnterPasswordViewVisible() ?? false{
                    addLog(text: "Enter password View is visible:- return;")
                    return false
                }
                if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
                    leftMenuVcObj?.showHabitsView()
                }
                shutOffTimeVcObj?.btnGetAccessNowClicked(self)
            }else{
                addLog(text: "btn get access now is hidden:- return;")
            }
            return false
        }
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        print(event.keyCode)

        // ── Keyboard Shortcuts settings panel recording ──────────────────────────
        if activeShortcutRecorder != .none {
            handleKeyboardShortcutRecording(event: event)
            return
        }
        // ────────────────────────────────────────────────────────────────────────

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
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option) || event.modifierFlags.contains(.control) || event.modifierFlags.contains(.shift) {
            
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
    
    
    // MARK: - Keyboard Shortcuts panel recording

    /// Handles a key event when the Keyboard Shortcuts settings panel is recording a shortcut.
    private func handleKeyboardShortcutRecording(event: NSEvent) {
        // ESC cancels recording
        if event.keyCode == escKeyCode {
            keyboardShortcutsSettingsVcObj?.cancelRecording()
            return
        }

        guard event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option) ||
              event.modifierFlags.contains(.control) || event.modifierFlags.contains(.shift) else {
            // No modifier — ignore and cancel
            keyboardShortcutsSettingsVcObj?.cancelRecording()
            return
        }

        var recordChar = ""
        var iserror = false

        if let specialKey = event.specialKey {
            switch specialKey {
            case .f1:  recordChar = "f1"
            case .f2:  recordChar = "f2"
            case .f3:  recordChar = "f3"
            case .f4:  recordChar = "f4"
            case .f5:  recordChar = "f5"
            case .f6:  recordChar = "f6"
            case .f7:  recordChar = "f7"
            case .f8:  recordChar = "f8"
            case .f9:  recordChar = "f9"
            case .f10: recordChar = "f10"
            case .f11: recordChar = "f11"
            case .f12: recordChar = "f12"
            default:   iserror = true
            }
        } else if event.keyCode == spaceKeyCode {
            recordChar = "space"
        } else {
            var chars = event.charactersIgnoringModifiers ?? ""
            if chars == "<" { chars = "," }
            else if chars == ">" { chars = "." }
            if chars.isEmpty { iserror = true } else { recordChar = chars }
        }

        if iserror {
            keyboardShortcutsSettingsVcObj?.cancelRecording()
            return
        }

        var flagsarr = [Int]()
        if event.modifierFlags.contains(.control) { flagsarr.append(shortcutFlags._CONTROL_.rawValue) }
        if event.modifierFlags.contains(.option)  { flagsarr.append(shortcutFlags._OPTION_.rawValue) }
        if event.modifierFlags.contains(.shift)   { flagsarr.append(shortcutFlags._SHIFT_.rawValue) }
        if event.modifierFlags.contains(.command) { flagsarr.append(shortcutFlags._COMMAND_.rawValue) }

        keyboardShortcutsSettingsVcObj?.shortcutRecorded(char: recordChar, flagInts: flagsarr)
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
    
    func windowWillMiniaturize(_ notification: Notification) {
        if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            showNudgeFocusAlignmentScoreWindow(score: currentFocusAlignmentScore)
        }
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        self.window?.close()
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_ || currentState == ._CUSTOM_ROUTINE_{
            if checkIsFullScreenEnabled(){
                if let leftMenuVcObj = leftMenuVcObj{
                    if leftMenuVcObj.boxHabits.isSelected || leftMenuVcObj.boxMicroBreaks.isSelected || leftMenuVcObj.boxCustomRoutine.isSelected{
                        mainViewControllerObj?.checkIsFullScreenNeeded()
                    }
                }
            }
        }
    }
}
