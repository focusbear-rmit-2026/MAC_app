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
    @IBOutlet weak var boxBrowsersTabAudit: mainWindowListBox!
    
    @IBOutlet weak var boxCustomRoutine: mainWindowListBox!
    @IBOutlet weak var boxMainItems: accordionBox!
    @IBOutlet weak var boxMicroBreaks: mainWindowListBox!
    @IBOutlet weak var boxFocusSession: mainWindowListBox!
    @IBOutlet weak var boxHabits: mainWindowListBox!
    @IBOutlet weak var boxDashboard: mainWindowListBox!
    
    var disableReasonMorningRoutine = "Disabled because your morning routine is in progress."
    var disableReasonEveningRoutine = "Disabled because your evening routine is in progress."
    var disableReasonFocusSummary = "Disabled because your all-day summary is visible."
    var disableReasonShutoffTime = "Disabled because it’s your shutoff time."
    var disableReasonMircoBreaks = "Disabled because your micro break is in progress."
    var disableReasonCustomRoutine = "Disabled because your custom routine is in progress."
    
    override func viewDidLoad() {
        super.viewDidLoad()

        boxFocusModeSettings.isHidden = true
        
        boxMainItems.title = "MAIN"
        boxToolsItems.title = "TOOLS"
        boxPreferences.title = "PREFERENCES"
        
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

        boxMicroBreaks.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        boxMicroBreaks.title = "Start Micro Break"
        
        boxTodoPlayer.imageIcon = NSImage(named: "validIcon")
        
        if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            boxTodoPlayer.title = "Todo Player"
        }else{
            boxTodoPlayer.title = "Todo List"
        }
        
        boxBrainDump.imageIcon = NSImage(named: "brainDump")
        boxBrainDump.title = "Brain Dump"
        
        
        boxBrowsersTabAudit.imageIcon = NSImage(named: "NSTouchBarOpenInBrowserTemplate")
        boxBrowsersTabAudit.title = "Tab Audit"
        boxBrowsersTabAudit.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        boxFocusMusic.imageIcon = NSImage(named: "music_albums_fill")
        boxFocusMusic.title = "Focus Music"
        
//        boxFocusModeSettings.imageIcon = NSImage(named: "NSTouchBarQuickLookTemplate")
//        boxFocusModeSettings.title = "Focus"
//        boxFocusModeSettings.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
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
                if arrAllCustomRoutine.count == 0{
                    self.boxCustomRoutine.isHidden = true
                }else{
                    self.boxCustomRoutine.isHidden = false
                }
            }else{
                self.boxMicroBreaks.isHidden = true
                self.boxFocusSession.isHidden = true
                self.boxHabits.isHidden = true
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
                self.boxMotivation.isHidden = false
                self.boxBrowsersTabAudit.isHidden = false
            }else{
                self.boxFocusMusic.isHidden = true
                self.boxBrainDump.isHidden = true
                self.boxTodoPlayer.isHidden = true
                self.boxMotivation.isHidden = true
                self.boxBrowsersTabAudit.isHidden = true
            }
            
        }
        
        boxPreferences.setExpanded(true)
        boxPreferences.onStateChanged = { isExpanded in
            print("Preferences is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxEditHabits.isHidden = false
                self.boxSettings.isHidden = false
                self.boxBlocks.isHidden = false
            }else{
                self.boxEditHabits.isHidden = true
                self.boxSettings.isHidden = true
                self.boxBlocks.isHidden = true
            }
        }

        boxHelpAndSupport.delegate = self
        boxEditHabits.delegate = self
        boxSettings.delegate = self
        boxBlocks.delegate = self
        
        boxFocusMusic.delegate = self
        boxBrainDump.delegate = self
        boxTodoPlayer.delegate = self
        boxMotivation.delegate = self
        boxBrowsersTabAudit.delegate = self
        
        boxMicroBreaks.delegate = self
        boxFocusSession.delegate = self
        boxHabits.delegate = self
        boxCustomRoutine.delegate = self
        boxUpgradeNow.delegate = self
        
        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
            boxMainItems.title = leftMenuVcInfo.value(forKey: "titleMain") as? String ?? boxMainItems.title
            boxToolsItems.title = leftMenuVcInfo.value(forKey: "titleTools") as? String ?? boxToolsItems.title
            boxPreferences.title = leftMenuVcInfo.value(forKey: "titlePreferences") as? String ?? boxPreferences.title
            

            boxHabits.title = leftMenuVcInfo.value(forKey: "menuHabits") as? String ?? boxHabits.title
            boxCustomRoutine.title = leftMenuVcInfo.value(forKey: "menuCustomRoutine") as? String ?? boxCustomRoutine.title
            boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuStartFocusSession") as? String ?? boxFocusSession.title
            boxMicroBreaks.title = leftMenuVcInfo.value(forKey: "menuStartMicroBreak") as? String ?? boxMicroBreaks.title
            
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                boxTodoPlayer.title = leftMenuVcInfo.value(forKey: "menuTodoPlayer") as? String ?? boxTodoPlayer.title
            }else{
                boxTodoPlayer.title = leftMenuVcInfo.value(forKey: "menuTodoList") as? String ?? boxTodoPlayer.title
            }
            boxBrainDump.title = leftMenuVcInfo.value(forKey: "menuBrainDump") as? String ?? boxBrainDump.title
            boxBrowsersTabAudit.title = leftMenuVcInfo.value(forKey: "menuTabAudit") as? String ?? boxBrowsersTabAudit.title
            boxFocusMusic.title = leftMenuVcInfo.value(forKey: "menuFocusMusic") as? String ?? boxFocusMusic.title
            
            boxBlocks.title = leftMenuVcInfo.value(forKey: "menuBlocksPreferences") as? String ?? boxFocusMusic.title
            boxSettings.title = leftMenuVcInfo.value(forKey: "menuSettings") as? String ?? boxFocusMusic.title
            boxEditHabits.title = leftMenuVcInfo.value(forKey: "menuEditHabits") as? String ?? boxFocusMusic.title
            boxMotivation.title = leftMenuVcInfo.value(forKey: "menuMotivation") as? String ?? boxFocusMusic.title
            boxHelpAndSupport.title = leftMenuVcInfo.value(forKey: "menuHelpAndSupport") as? String ?? boxFocusMusic.title
            boxUpgradeNow.title = leftMenuVcInfo.value(forKey: "menuUpgradeNow") as? String ?? boxFocusMusic.title
            
            disableReasonMorningRoutine = leftMenuVcInfo.value(forKey: "disableReasonMorningRoutine") as? String ?? disableReasonMorningRoutine
            disableReasonEveningRoutine = leftMenuVcInfo.value(forKey: "disableReasonEveningRoutine") as? String ?? disableReasonEveningRoutine
            disableReasonFocusSummary = leftMenuVcInfo.value(forKey: "disableReasonFocusSummary") as? String ?? disableReasonFocusSummary
            disableReasonShutoffTime = leftMenuVcInfo.value(forKey: "disableReasonShutoffTime") as? String ?? disableReasonShutoffTime
            disableReasonMircoBreaks = leftMenuVcInfo.value(forKey: "disableReasonMircoBreaks") as? String ?? disableReasonMircoBreaks
            disableReasonCustomRoutine = leftMenuVcInfo.value(forKey: "disableReasonCustomRoutine") as? String ?? disableReasonCustomRoutine
        }
        
        arrForSearchFromSettings.append(["title": boxSettings.title, "tabId": idSettings])
        arrForSearchFromSimpleModeSettings.append(["title": boxSettings.title, "tabId": idSettings])
        
        arrForSearchFromSettings.append(["title": boxEditHabits.title, "tabId": idEditHabits])
        arrForSearchFromSimpleModeSettings.append(["title": boxEditHabits.title, "tabId": idEditHabits])
        
        arrForSearchFromSettings.append(["title": boxBlocks.title, "tabId": idTabStrictness])
        arrForSearchFromSimpleModeSettings.append(["title": boxBlocks.title, "tabId": idTabStrictness])
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
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuStopFocusSession") as? String ?? boxFocusSession.title
            }
        }else if isFocusModePaused{
            boxFocusSession.title = "Resume Focus Session"
//            imgViewStopSuperFocusSession.image = iconResumeFocusSession
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuResumeFocusSession") as? String ?? boxFocusSession.title
            }
        }else if isHardCorePomodoroModeOn{
            boxFocusSession.title = "Stop Super Focus Session"
//            imgViewStopSuperFocusSession.image = iconStopFocusSession
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuStopSuperFocusSession") as? String ?? boxFocusSession.title
            }
        }else{
            boxFocusSession.title = "Start Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuStartFocusSession") as? String ?? boxFocusSession.title
            }
        }
    }
    
    func selectableListBoxDidChangeSelectionByUser(_ box: mainWindowListBox) {
        switch box{
            
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

                let currentDate = Date()
                let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
                let sameDay = Calendar.current.isDate(currentDate, equalTo: firstRunDate, toGranularity: .day)
                let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false
                
                
                if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_  && UserDefaults.standard.object(forKey: kUserdefaultsStartRoutineButtonClicked) == nil{
                    if isHabitsDisabled{
                        UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                        habitsVcObj?.showHabitState()
                    }else{
                        if sameDay || !shouldDoHabits(){
                            habitsVcObj?.showHabitState()
                        }else{
                            UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                        }
                    }
                }else{
                    if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                        if Date().compare(date) == .orderedAscending {//"Evening habits already shown for today
                            if isShutOffTimeGoing() && !isCutOffTimeGoing(){
                                habitsVcObj?.showHabitState()// free time 
                            }
                        }
                    }else if isShutOffTimeGoing() && currentState != ._EVENING_HABIT_ && currentState != ._FOCUS_SUMMARY_ && currentState != ._POSTPON_EVENING_HABIT_ && currentState != ._POSTPON_FOCUS_SUMMARY_ && arrAllDaysEveningHabits.count == 0{
                        habitsVcObj?.showHabitState()// v 2.28.437
                    }else if (appdelegate?.isUserOnMeeting ?? false) && !isHabitAlreadyShowed && !isShutOffTimeGoing(){
                        habitsVcObj?.showHabitState()// v 2.28.445
                    }else if !isAppEnable{
                        habitsVcObj?.showHabitState()// v 2.28.456
                    }else if sameDay || !shouldDoHabits(){
                        if isHabitsDisabled{
                            UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                        }
                        habitsVcObj?.showHabitState()
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
        case boxBrainDump:
            mainViewControllerObj?.showBrainDumpView()
        case boxBrowsersTabAudit:
            mainViewControllerObj?.showBrowsersTabAuditView()
        case boxFocusMusic:
            mainViewControllerObj?.showAllTracksView()
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

        case boxHabits:
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                mainViewControllerObj?.checkIsFullScreenNeeded()
            }else{
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            }
        case boxFocusSession:
            if currentState == ._MICRO_BREAK_{// if micro break started while focus mode is running and focus mode finished after miro break started then dont show small view if full screen is enabled v 2.28.438 
                if checkIsFullScreenEnabled(){
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }else{
                    mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
                }
            }else{
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            }
        case boxMicroBreaks:
            if currentState == ._MICRO_BREAK_{
                var isBreakWarningVisible = false
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        isBreakWarningVisible = true // will not happened now beacuse changing selection will start break if warning is visible
                    }
                }
                
                if isBreakWarningVisible{
                    mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
                }else{
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }
            }else{
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            }
        case boxCustomRoutine:
            if currentState == ._CUSTOM_ROUTINE_ {
                if customRoutineTimeWcObj != nil {
                    if customRoutineTimeWcObj?.window?.isVisible ?? false{
                        mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
                    }else{
                        mainViewControllerObj?.checkIsFullScreenNeeded()
                    }
                }else{
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }
            }else{
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            }
        case boxTodoPlayer:
            checkScreenSizeIfFullScreenHabitIsRunning()
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                self.view.window?.styleMask.insert(.miniaturizable)// task player should be miniaturizable
            }
        case boxBrainDump:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxBrowsersTabAudit:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxFocusMusic:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxBlocks:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxSettings:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxEditHabits:
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        case boxMotivation:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxHelpAndSupport:
            checkScreenSizeIfFullScreenHabitIsRunning()
        default:
            break;
        }
    }
    
    func checkScreenSizeIfFullScreenHabitIsRunning(){
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_ || currentState == ._CUSTOM_ROUTINE_ || currentState == ._MICRO_BREAK_{
            
            if !isAnyAllowedFocusModeActivityRunning && checkIsFullScreenEnabled(){
                mainViewControllerObj?.checkIsFullScreenNeeded()
            }else{
                if isAnyAllowedFocusModeActivityRunning{
                    mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
                }
            }
        }else{
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
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
        disableAllExceptHabitTab()
        
        boxHabits.isSelected = true
        mainViewControllerObj?.showHabitsView()
        reloadHabitStatus()
        mainViewControllerObj?.collapseLeftPanel()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        
    }
    
    func customRoutineStarted(){
        disableAllExceptCustomRoutineTab()
        
        boxCustomRoutine.isSelected = true
        mainViewControllerObj?.showHabitsView()
        reloadHabitStatus()
        mainViewControllerObj?.collapseLeftPanel()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    
    func disableAllExceptHabitTab(){
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
        
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.isEnabled = true
        boxCustomRoutine.setDisableWithRaason(reason: toolTipDisableReason)
    }
    
    func disableAllTabForOnboarding(){
        let toolTipDisableReason = ""
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxFocusMusic.setDisableWithRaason(reason: toolTipDisableReason)
        boxBrainDump.setDisableWithRaason(reason: toolTipDisableReason)
        boxBrowsersTabAudit.setDisableWithRaason(reason: toolTipDisableReason)
        boxTodoPlayer.setDisableWithRaason(reason: toolTipDisableReason)
        boxMotivation.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxUpgradeNow.setDisableWithRaason(reason: toolTipDisableReason)
        boxHelpAndSupport.setDisableWithRaason(reason: toolTipDisableReason)
    }
    
    
    func disableAllExceptCustomRoutineTab(){
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

        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)

        boxMicroBreaks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.isEnabled = true
    }
    
    func habitOver(){
        enableAllItems()
        reloadHabitStatus()
        mainViewControllerObj?.expandLeftPanel()
        resumeIfAnyFocusMusicStoppedAutomatically()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
    }
    
    func microBreaksStarted(){
        let toolTipDisableReason = disableReasonMircoBreaks
        
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.isEnabled = true
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.isSelected = true
        mainViewControllerObj?.showHabitsView()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
        mainViewControllerObj?.collapseLeftPanel()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    
    func microBreaksOver(){
        resumeIfAnyFocusMusicStoppedAutomatically()
        mainViewControllerObj?.expandLeftPanel()
        enableAllItems()
        
        //Don't show brain dump after microbreak
        //        #1565     v 2.28.436  28/11/25
        if isFocusModeOn(){
            if let breaksBrainDumpVcObj = breaksBrainDumpVcObj{
                if let id = breaksBrainDumpVcObj.taskIdSaveFromBrainDump, let taskTitle = breaksBrainDumpVcObj.taskSaveFromBrainDump{
                    taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskTitle, id: id, duration: 600, shouldCompleteCurrentTask: false)
                    breaksBrainDumpVcObj.taskIdSaveFromBrainDump = nil
                    breaksBrainDumpVcObj.taskSaveFromBrainDump = nil
                }
            }
        }else if isHardCorePomodoroModeOn{//Super Focus session stops blocking after closing the break popup; session remains active but blocking and timer disappear#1572  v 2.28.440   (resume super pomodoro after micro breaks)
            appdelegate?.showAutoPomodoroModeView()
        }
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
    }

    func enableAllItems(){
        boxMotivation.isEnabled = true
        boxEditHabits.isEnabled = true
        boxSettings.isEnabled = true
        boxBlocks.isEnabled = true

        boxFocusMusic.isEnabled = true
        boxBrainDump.isEnabled = true
        boxBrowsersTabAudit.isEnabled = true
        boxTodoPlayer.isEnabled = true

        boxMicroBreaks.isEnabled = true
        boxFocusSession.isEnabled = true
        boxHabits.isEnabled = true

        boxCustomRoutine.isEnabled = true
        boxUpgradeNow.isEnabled = true
        boxHelpAndSupport.isEnabled = true
    }
    
    func showPomodoro(pomodoroVcObj:NSView){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusSessionView(pomodoroView: pomodoroVcObj)
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

    func showBrainDump(){
        boxBrainDump.isSelected = true
        mainViewControllerObj?.showBrainDumpView()
    }
    
    func showBrowsersTabAuditView(){
        boxBrowsersTabAudit.isSelected = true
        mainViewControllerObj?.showBrowsersTabAuditView()
    }
    
    func showAllTracks(){
        boxFocusMusic.isSelected = true
        mainViewControllerObj?.showAllTracksView()
    }
    
    func showTaskPlayer(){
        boxTodoPlayer.isSelected = true
        mainViewControllerObj?.showTaskView()
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                boxTodoPlayer.isEnabled = true
            }
        }
    }
    
    func showFocusCompletedView(){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusCompletedView()
    }
    
    func showFocusAbortedView(){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusAbortedView()
    }
    
    func showCustomScheduleAbortedView(){
        if abortingCustomScheduleBlockingVcObj != nil{
            if abortingCustomScheduleBlockingVcObj?.isViewVisible ?? false{
                return;
            }
        }
        boxFocusSession.isSelected = true
        if SettingsManagerObject.isGeekModeEnabled{
            appdelegate?.menuShowPomodoroModeView()
        }else{
            appdelegate?.menuShowSimplePomodoroModeView()
        }
        if self.view.window != nil{
            self.presentAsSheet(getAbortingCustomScheduleBlockingVcObject())
        }
        getAbortingCustomScheduleBlockingVcObject().resetData()
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
        if !(leftMenuVcObj?.boxBlocks.isSelected ?? false){
            leftMenuVcObj?.boxBlocks.isSelected = true
        }
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
    
    func showFocusModeStateView(){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusModeState()
    }
    
    func showEditHabitsView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        
        boxEditHabits.isSelected = true
        mainViewControllerObj?.showEditHabitsView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    func focusModeOrFocusModeHabitStarted(){// also for custom schedule blocking
        boxTodoPlayer.title = "Todo Player"
        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
            boxTodoPlayer.title = leftMenuVcInfo.value(forKey: "menuTodoPlayer") as? String ?? boxTodoPlayer.title
        }
    }
    
    func focusModeOrFocusModeHabitFinished(){
        boxTodoPlayer.title = "Todo List"
        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
            boxTodoPlayer.title = leftMenuVcInfo.value(forKey: "menuTodoList") as? String ?? boxTodoPlayer.title
        }
    }

    @IBAction func btnExpandLeftMenuClicked(_ sender: Any) {
        mainViewControllerObj?.toggleLeftPaneWidth()
    }
}

var idGeneral = "General"
var idStats = "Stats"
var idFocus = "Focus"
var idEditHabits = "EditHabits"
var idSettings = "Settings"
var idHelp = "Help"
var idTabStrictness = "tabStrictness"
