//
//  leftMenuVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 05/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class leftMenuVc: NSViewController, mainWindowListBoxDelegate {

    
    @IBOutlet weak var boxUpgradeNow: mainWindowListBox!
    @IBOutlet weak var btnExpandLeftMenu: cursorButton!
    @IBOutlet weak var boxHelpAndSupport: mainWindowListBox!
    @IBOutlet weak var boxMotivation: mainWindowListBox!
    @IBOutlet weak var boxEditHabits: mainWindowListBox!
    @IBOutlet weak var boxSettings: mainWindowListBox!
    @IBOutlet weak var boxBlocks: mainWindowListBox!
    @IBOutlet weak var boxFocusModeSettings: mainWindowListBox!
    @IBOutlet weak var boxPreferences: accordionBox!
    
    @IBOutlet weak var boxFocusMusic: mainWindowListBox!
    @IBOutlet weak var boxBrainDump: mainWindowListBox!
    @IBOutlet weak var boxTodoPlayer: mainWindowListBox!
    @IBOutlet weak var boxToolsItems: accordionBox!
    
    @IBOutlet weak var boxCustomRoutine: mainWindowListBox!
    @IBOutlet weak var boxMainItems: accordionBox!
    @IBOutlet weak var boxMicroBreaks: mainWindowListBox!
    @IBOutlet weak var boxFocusSession: mainWindowListBox!
    @IBOutlet weak var boxHabits: mainWindowListBox!
    @IBOutlet weak var boxDashboard: mainWindowListBox!
    
    let disableReasonMorningRoutine = "Disabled because your morning routine is in progress."
    let disableReasonEveningRoutine = "Disabled because your evening routine is in progress."
    let disableReasonFocusSummary = "Disabled because your all-day summary is visible."
    let disableReasonShutoffTime = "Disabled because it’s your shutoff time."
    let disableReasonMircoBreaks = "Disabled because your micro break is in progress."
    let disableReasonCustomRoutine = "Disabled because your custom routine is in progress." // todo text 
    
    override func viewDidLoad() {
        super.viewDidLoad()

       
        boxMainItems.title = "MAIN"
        boxToolsItems.title = "TOOLS"
        boxPreferences.title = "PREFERENCES"
        
//        boxDashboard.imageIcon = NSImage(named: "brainDump")
//        boxDashboard.title = "Dashboard"
        boxDashboard.isHidden = true
        
        boxHabits.imageIcon = NSImage(named: "play_circle")
        boxHabits.title = "Habits"
        
        
        boxCustomRoutine.imageIcon = NSImage(named: "play_circle")
        boxCustomRoutine.title = "Custom Routine"
        
        boxFocusSession.imageIcon = NSImage(named: "start-pomodoro")
        boxFocusSession.title = "Start Focus Session"
        
        
        if #available(macOS 11.0, *) {
            boxMicroBreaks.imageIcon = NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: nil)
        } else {
            boxMicroBreaks.imageIcon = NSImage(named: NSImage.touchBarUserTemplateName)
        }

        boxMicroBreaks.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        boxMicroBreaks.title = "Start Micro Break"
        
        boxTodoPlayer.imageIcon = NSImage(named: "validIcon")
        
        if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
            boxTodoPlayer.title = "Todo Player"
        }else{
            boxTodoPlayer.title = "Todo List"
        }
        
        boxBrainDump.imageIcon = NSImage(named: "brainDump")
        boxBrainDump.title = "Brain Dump"
        
        boxFocusMusic.imageIcon = NSImage(named: "music_albums_fill")
        boxFocusMusic.title = "Focus Music"
        
        boxFocusModeSettings.imageIcon = NSImage(named: "NSTouchBarQuickLookTemplate")
        boxFocusModeSettings.title = "Focus"
        boxFocusModeSettings.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        if #available(macOS 11.0, *) {
            boxBlocks.imageIcon = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: nil)
        } else {
            boxBlocks.imageIcon = NSImage(named: NSImage.stopProgressTemplateName)
        }
        boxBlocks.title = "Blocks"
        boxBlocks.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        if #available(macOS 11.0, *) {
            boxSettings.imageIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        } else {
            boxSettings.imageIcon = NSImage(named: "NSSmartBadgeTemplate")
        }
        boxSettings.title = "Settings"
        boxSettings.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        if #available(macOS 11.0, *) {
            boxEditHabits.imageIcon = NSImage(systemSymbolName: "checkmark.rectangle", accessibilityDescription: nil)
        } else {
            boxEditHabits.imageIcon = NSImage(named: "checkmark")
        }
        boxEditHabits.title = "Edit Habits"
        boxEditHabits.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue

        if #available(macOS 11.0, *) {
            boxMotivation.imageIcon = NSImage(systemSymbolName: "person", accessibilityDescription: nil)
        } else {
            boxMotivation.imageIcon = NSImage(named: "NSTouchBarUserTemplate")
        }
        boxMotivation.title = "Motivation"
        boxMotivation.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue

        boxHelpAndSupport.imageIcon = NSImage(named: NSImage.infoName)
        boxHelpAndSupport.title = "Help & Support"
        boxHelpAndSupport.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        boxUpgradeNow.title = "Upgrade Now"
        boxUpgradeNow.imageIcon = NSImage(named: "upgrade")
        
        boxMainItems.setExpanded(true)
        boxMainItems.onStateChanged = { isExpanded in
            print("MainItems is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxMicroBreaks.isHidden = false
                self.boxFocusSession.isHidden = false
                self.boxHabits.isHidden = false
                //self.boxDashboard.isHidden = false
                if arrAllCustomRoutine.count == 0{
                    self.boxCustomRoutine.isHidden = true
                }else{
                    self.boxCustomRoutine.isHidden = false
                }
            }else{
                self.boxMicroBreaks.isHidden = true
                self.boxFocusSession.isHidden = true
                self.boxHabits.isHidden = true
               // self.boxDashboard.isHidden = true
                self.boxCustomRoutine.isHidden = true
            }
        }
        
        boxToolsItems.setExpanded(true)
        boxToolsItems.onStateChanged = { isExpanded in
            print("Tools is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxFocusMusic.isHidden = false
                self.boxBrainDump.isHidden = false
                self.boxTodoPlayer.isHidden = false
            }else{
                self.boxFocusMusic.isHidden = true
                self.boxBrainDump.isHidden = true
                self.boxTodoPlayer.isHidden = true
            }
            
        }
        
        boxPreferences.setExpanded(true)
        boxPreferences.onStateChanged = { isExpanded in
            print("Preferences is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxMotivation.isHidden = false
                self.boxEditHabits.isHidden = false
                self.boxSettings.isHidden = false
                self.boxBlocks.isHidden = false
                self.boxFocusModeSettings.isHidden = false
            }else{
                self.boxMotivation.isHidden = true
                self.boxEditHabits.isHidden = true
                self.boxSettings.isHidden = true
                self.boxBlocks.isHidden = true
                self.boxFocusModeSettings.isHidden = true
            }
        }

        boxHelpAndSupport.delegate = self
        boxMotivation.delegate = self
        boxEditHabits.delegate = self
        boxSettings.delegate = self
        boxBlocks.delegate = self
        boxFocusModeSettings.delegate = self
        
        boxFocusMusic.delegate = self
        boxBrainDump.delegate = self
        boxTodoPlayer.delegate = self

        boxMicroBreaks.delegate = self
        boxFocusSession.delegate = self
        boxHabits.delegate = self
        //boxDashboard.delegate = self
        boxCustomRoutine.delegate = self
        boxUpgradeNow.delegate = self
       // boxDashboard.isSelected = true
        
        
        
        arrForSearchFromSettings.append(["title": boxSettings.title, "tabId": idSettings])
        arrForSearchFromSimpleModeSettings.append(["title": boxSettings.title, "tabId": idSettings])
        
        arrForSearchFromSettings.append(["title": boxEditHabits.title, "tabId": idEditHabits])
        arrForSearchFromSimpleModeSettings.append(["title": boxEditHabits.title, "tabId": idEditHabits])
        
        arrForSearchFromSettings.append(["title": boxBlocks.title, "tabId": idTabStrictness])
        arrForSearchFromSimpleModeSettings.append(["title": boxBlocks.title, "tabId": idTabStrictness])
        
        arrForSearchFromSettings.append(["title": boxFocusModeSettings.title, "tabId": idFocus])
        arrForSearchFromSimpleModeSettings.append(["title": boxFocusModeSettings.title, "tabId": idFocus])
    }
    
    override func viewWillAppear() {
        resetFocusModeTitle()
        checkPurchaseState()
    }
    
    func reloadHabitStatus(){

    }
    
    
    func checkPurchaseState(){
        if !isPurchased{
            boxUpgradeNow.isHidden = false
        }else{
            boxUpgradeNow.isHidden = true
        }
    }
    
    func resetFocusModeTitle(){
        let isFocusModeOn = isFocusModeOn()
        let isFocusModePaused = isFocusModePaused()

        if isFocusModeOn{
            boxFocusSession.title = "Stop Focus Session"
//            imgViewStopSuperFocusSession.image = iconStopFocusSession
        }else if isFocusModePaused{
            boxFocusSession.title = "Resume Focus Session"
//            imgViewStopSuperFocusSession.image = iconResumeFocusSession
        }else if isHardCorePomodoroModeOn{
            boxFocusSession.title = "Stop Super Focus Session"
//            imgViewStopSuperFocusSession.image = iconStopFocusSession
        }else{
            boxFocusSession.title = "Start Focus Session"
        }
    }/*
      var iconResumeFocusSession  = NSImage(named: "play_circle")
      var iconStopFocusSession  = NSImage(named: "stop_circle")
      var iconPlayFocusSession = NSImage(named: "play_circle")
      */
    
    func selectableListBoxDidChangeSelectionByUser(_ box: mainWindowListBox) {
        switch box{
            
//        case boxDashboard:
//            mainViewControllerObj?.showDashboardView()
        case boxHabits:
            mainViewControllerObj?.showHabitsView()
            if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
                habitsVcObj?.showHabitState()
            }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
                habitsVcObj?.showHabitState()
            }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
                habitsVcObj?.showHabitState()
            }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit{
                habitsVcObj?.showHabitState()
            }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
                habitsVcObj?.showHabitState()
            }else{
                if isHabitAlreadyShowed && !isShutOffTimeGoing(){
                    habitsVcObj?.showHabitState()
                }else{
                    if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                        if Date().compare(date) == .orderedAscending {
                            habitsVcObj?.showHabitState()//showCustomRoutineState
                        }
                    }
                }
            }
            
            break;
        case boxFocusSession:
            let isFocusModeOn = isFocusModeOn()
            let isFocusModePaused = isFocusModePaused()

            if isFocusModeOn{
                mainViewControllerObj?.showFocusModeState()
            }else if isFocusModePaused{
                mainViewControllerObj?.showFocusModeState()
            }else if isHardCorePomodoroModeOn{
                mainViewControllerObj?.showFocusModeState()
            }else{
                if SettingsManagerObject.isGeekModeEnabled{
                    appdelegate?.menuShowPomodoroModeView()
                }else{
                    appdelegate?.menuShowSimplePomodoroModeView()
                }
            }
            //enableAllItems()
        case boxMicroBreaks:
            if currentState == ._MICRO_BREAK_{
                var isBreakWarningVisible = false
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        isBreakWarningVisible = true// will not happened now beacuse changing selection will start break if warning is visible
                    }
                }
                
                if isBreakWarningVisible{
                    mainViewControllerObj?.showHabitsView()
                    habitsVcObj?.showBreakState()
                }else{
                    mainViewControllerObj?.showHabitsView()
                }
            }else{
                mainViewControllerObj?.showHabitsView()
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{ 
                    if Date().compare(date) == .orderedAscending || isShutOffTimeGoing(){
                        habitsVcObj?.showHabitState()
                    }else{
                        habitsVcObj?.showBreakState()
                    }
                }else{
                    habitsVcObj?.showBreakState()
                }
            }
        case boxCustomRoutine:
            if currentState == ._CUSTOM_ROUTINE_ {
                if customRoutineTimeWcObj != nil {
                    if customRoutineTimeWcObj?.window?.isVisible ?? false{
                        mainViewControllerObj?.showHabitsView()
                        habitsVcObj?.showCustomRoutineState()
                    }else{
                        mainViewControllerObj?.showHabitsView()
                    }
                }else{
                    mainViewControllerObj?.showHabitsView()
                }
            }else{
                mainViewControllerObj?.showHabitsView()
                habitsVcObj?.showCustomRoutineState()
            }
        case boxTodoPlayer:
            mainViewControllerObj?.showTaskView()
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                    boxTodoPlayer.isEnabled = true
                }
            }
//            else{
//                enableAllItems()
//            }
        case boxBrainDump:
            mainViewControllerObj?.showBrainDumpView()
        case boxFocusMusic:
            mainViewControllerObj?.showAllTracksView()
        case boxFocusModeSettings:
            mainViewControllerObj?.showFocusPreferencesView()
            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
        case boxBlocks:
            mainViewControllerObj?.showBlocksPreferencesView()
            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
        case boxSettings:
            mainViewControllerObj?.showSettingsView()
            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
        case boxEditHabits:
            mainViewControllerObj?.showEditHabitsView()
            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
        case boxMotivation:
            mainViewControllerObj?.showMotivationView()
        case boxHelpAndSupport:
            mainViewControllerObj?.showHelpView()
        default:
            break;
        }
    }
    
    func selectableListBoxSelectionDidChange(_ box: mainWindowListBox) {
        switch box{
            
//        case boxDashboard:
//            mainViewControllerObj?.showSmallScreen()
        case boxHabits:
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                mainViewControllerObj?.checkIsFullScreenNeeded()
            }else{
                mainViewControllerObj?.showSmallScreen()
            }
        case boxFocusSession:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxMicroBreaks:
            if currentState == ._MICRO_BREAK_{
                var isBreakWarningVisible = false
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        isBreakWarningVisible = true // will not happened now beacuse changing selection will start break if warning is visible
                    }
                }
                
                if isBreakWarningVisible{
                    mainViewControllerObj?.showSmallScreen()
                }else{
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }
            }else{
                mainViewControllerObj?.showSmallScreen()
            }
        case boxCustomRoutine:
            if currentState == ._CUSTOM_ROUTINE_{
                mainViewControllerObj?.checkIsFullScreenNeeded()
            }else{
                mainViewControllerObj?.showSmallScreen()
            }
            if currentState == ._CUSTOM_ROUTINE_ {
                if customRoutineTimeWcObj != nil {
                    if customRoutineTimeWcObj?.window?.isVisible ?? false{
                        mainViewControllerObj?.showSmallScreen()
                    }else{
                        mainViewControllerObj?.checkIsFullScreenNeeded()
                    }
                }else{
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }
            }else{
                mainViewControllerObj?.showSmallScreen()
            }
        case boxTodoPlayer:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                self.view.window?.styleMask.insert(.miniaturizable)// task player should be miniaturizable
            }
        case boxBrainDump:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxFocusMusic:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxFocusModeSettings:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxBlocks:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxSettings:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxEditHabits:
            mainViewControllerObj?.showSmallScreen()
        case boxMotivation:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxHelpAndSupport:
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_ || currentState == ._CUSTOM_ROUTINE_ || currentState == ._MICRO_BREAK_{
                
                if !isAnyAllowedFocusModeActivityRunning && checkIsFullScreenEnabled(){
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }else{
                    mainViewControllerObj?.showSmallScreen()
                }
            }else{
                mainViewControllerObj?.showSmallScreen()
            }
            
        default:
            break;
        }
    }
    
    func selectableListBoxShouldChangeSelection(_ box: mainWindowListBox) -> Bool {
        if areSettingsEdited{
            showAlertSettingsEdited()
            areSettingsEdited = false
            return false
        }
        
        if box == boxMicroBreaks{
            if currentState == ._MICRO_BREAK_{ // if currentstate is microbreak and break warning is visible thne if user click on this tab. start break immediately
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        breakWarningVcObj?.btnStartMicroBreakClicked(self)
                        return false
                    }
                }
            }
        }
        if box == boxUpgradeNow{
            addLog(text:"[user-action] leftMenuVc:- btnUpgradeNowClicked")
            showUpgradeNowWindow()
            return false
        }
        
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return false
        }
        return true
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
        if let window = self.view.window{
            alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                }
                
                
            })
        }
    }
    
    
    func habitStarted(){
        disbaleAllExceptHabitTab()
        
        boxHabits.isSelected = true
        mainViewControllerObj?.showHabitsView()
        reloadHabitStatus()
        mainViewControllerObj?.collapseLeftPanel()
//        mainViewControllerObj?.checkIsFullScreenNeeded()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
    }
    
    func customRoutineStarted(){
        disbaleAllExceptCustomRoutineTab()
        
        boxCustomRoutine.isSelected = true
        mainViewControllerObj?.showHabitsView()
        reloadHabitStatus()
        mainViewControllerObj?.collapseLeftPanel()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
    }
    
    func disbaleAllExceptHabitTab(){
        var toolTipDisableReason = ""
        
        if currentState == ._MORNING_HABIT_{
            toolTipDisableReason = disableReasonMorningRoutine
        }else if currentState == ._EVENING_HABIT_{
            toolTipDisableReason = disableReasonEveningRoutine
        }else if currentState == ._FOCUS_SUMMARY_{
            toolTipDisableReason = disableReasonFocusSummary
        }else if currentState == ._SHUTOFFMAC_{
            toolTipDisableReason = disableReasonShutoffTime
        }else if currentState == ._CUSTOM_ROUTINE_{
            toolTipDisableReason = disableReasonCustomRoutine
        }
        
//        boxHelpAndSupport.setDisableWithRaason(reason: toolTipDisableReason)
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusModeSettings.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxFocusMusic.setDisableWithRaason(reason: toolTipDisableReason)
        boxBrainDump.setDisableWithRaason(reason: toolTipDisableReason)
        boxTodoPlayer.setDisableWithRaason(reason: toolTipDisableReason)
        boxMotivation.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.isEnabled = true
//        boxDashboard.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.setDisableWithRaason(reason: toolTipDisableReason)
    }
    
    func disbaleAllExceptCustomRoutineTab(){
        var toolTipDisableReason = ""
        
        if currentState == ._MORNING_HABIT_{
            toolTipDisableReason = disableReasonMorningRoutine
        }else if currentState == ._EVENING_HABIT_{
            toolTipDisableReason = disableReasonEveningRoutine
        }else if currentState == ._FOCUS_SUMMARY_{
            toolTipDisableReason = disableReasonFocusSummary
        }else if currentState == ._SHUTOFFMAC_{
            toolTipDisableReason = disableReasonShutoffTime
        }else if currentState == ._CUSTOM_ROUTINE_{
            toolTipDisableReason = disableReasonCustomRoutine
        }
        
//        boxHelpAndSupport.setDisableWithRaason(reason: toolTipDisableReason)
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusModeSettings.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxFocusMusic.setDisableWithRaason(reason: toolTipDisableReason)
        boxBrainDump.setDisableWithRaason(reason: toolTipDisableReason)
        boxTodoPlayer.setDisableWithRaason(reason: toolTipDisableReason)
        boxMotivation.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxDashboard.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.isEnabled = true
    }
    
    func habitOver(){
        enableAllItems()
        reloadHabitStatus()
        mainViewControllerObj?.expandLeftPanel()
        resumeIfAnyFocusMusicStoppedAutomatically()
    }
    
    func microBreaksStarted(){
        let toolTipDisableReason = disableReasonMircoBreaks
        
//        boxHelpAndSupport.setDisableWithRaason(reason: toolTipDisableReason)
        boxMotivation.setDisableWithRaason(reason: toolTipDisableReason)
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusModeSettings.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxFocusMusic.setDisableWithRaason(reason: toolTipDisableReason)
        boxBrainDump.setDisableWithRaason(reason: toolTipDisableReason)
        boxTodoPlayer.setDisableWithRaason(reason: toolTipDisableReason)

        boxMicroBreaks.isEnabled = true
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.setDisableWithRaason(reason: toolTipDisableReason)
//        boxDashboard.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.isSelected = true
        mainViewControllerObj?.showHabitsView()
       // mainViewControllerObj?.checkIsFullScreenNeeded()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
        mainViewControllerObj?.collapseLeftPanel()
    }
    
    func microBreaksOver(){
        //mainViewControllerObj?.showSmallScreen()
        resumeIfAnyFocusMusicStoppedAutomatically()
        mainViewControllerObj?.expandLeftPanel()
        enableAllItems()
    }

    func enableAllItems(){
//        boxHelpAndSupport.isEnabled = true
        boxMotivation.isEnabled = true
        boxEditHabits.isEnabled = true
        boxSettings.isEnabled = true
        boxBlocks.isEnabled = true
        boxFocusModeSettings.isEnabled = true
        
        boxFocusMusic.isEnabled = true
        boxBrainDump.isEnabled = true
        boxTodoPlayer.isEnabled = true

        boxMicroBreaks.isEnabled = true
        boxFocusSession.isEnabled = true
        boxHabits.isEnabled = true
//        boxDashboard.isEnabled = true
        boxCustomRoutine.isEnabled = true
    }
    
    func showPomodoro(pomodoroVcObj:NSView){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusSessionView(pomodoroView: pomodoroVcObj)
//        enableAllItems()
    }
    
    func showHabitsView(){
        boxHabits.isSelected = true
        mainViewControllerObj?.showHabitsView()
    }
    
    func showBreaksView(){
        boxMicroBreaks.isSelected = true
        mainViewControllerObj?.showHabitsView()
    }
    
    func showCustomRoutineView(){
        boxCustomRoutine.isSelected = true
        mainViewControllerObj?.showHabitsView()
    }
    
//    func showDashboardView(){
//        boxDashboard.isSelected = true
//        mainViewControllerObj?.showDashboardView()
//    }
    
    
    func showBrainDump(){
        boxBrainDump.isSelected = true
        mainViewControllerObj?.showBrainDumpView()
//        enableAllItems()
    }
    
    func showAllTracks(){
        boxFocusMusic.isSelected = true
        mainViewControllerObj?.showAllTracksView()
//        enableAllItems()
    }
    
    func showTaskPlayer(){
        boxTodoPlayer.isSelected = true
        mainViewControllerObj?.showTaskView()
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                boxTodoPlayer.isEnabled = true
            }
        }
//        else{
//            enableAllItems()
//        }
    }
    
    func showFocusCompletedView(){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusCompletedView()
//        enableAllItems()
    }
    
    func showFocusAbortedView(){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusAbortedView()
       // enableAllItems()
    }
    
    func showHelpAndSupportView(){
        boxHelpAndSupport.isSelected = true
        mainViewControllerObj?.showHelpView()
    }
    
    
    func showSettingsView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        if !(mainWindowControllerObj!.window?.isVisible ?? false){
            mainWindowControllerObj?.showWindow(self)
        }
        boxSettings.isSelected = true
        mainViewControllerObj?.showSettingsView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    
    func showFocusModeSettingsView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        
        boxFocusModeSettings.isSelected = true
        mainViewControllerObj?.showFocusPreferencesView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    
    func showBlocksView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        
        boxBlocks.isSelected = true
        mainViewControllerObj?.showBlocksPreferencesView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    func showEditHabitsView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        
        boxEditHabits.isSelected = true
        mainViewControllerObj?.showEditHabitsView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    func focusModeOrFocusModeHabitStarted(){
        boxTodoPlayer.title = "Todo Player"
    }
    
    func focusModeOrFocusModeHabitFinished(){
        boxTodoPlayer.title = "Todo List"
    }
    
    @IBAction func btnExpandLeftMenuClicked(_ sender: Any) {
        mainViewControllerObj?.toggleLeftPaneWidth()
    }
}
