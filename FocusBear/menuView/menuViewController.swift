//
//  menuViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/02/22.

//

import Cocoa
import SwiftUI

class menuViewController: NSViewController {


    @IBOutlet weak var boxLblTitleFocusStatus: NSView!
    @IBOutlet weak var boxSectionFocusMode: NSBox!
    @IBOutlet weak var boxLblTitleHabitStatus: NSBox!
    @IBOutlet weak var lblTitleHabitStatus: NSTextField!
    @IBOutlet weak var lblTitleBreakStatus: NSTextField!
    @IBOutlet weak var lblTitleFocusStatus: NSTextField!
    @IBOutlet weak var btnDropDownHabit: cursorButton!
    @IBOutlet weak var btnDropDownBreak: cursorButton!
    @IBOutlet weak var btnDropDownFocus: cursorButton!
    @IBOutlet weak var boxFocusInfo: NSBox!
    @IBOutlet weak var boxHabitsInfo: NSBox!
    @IBOutlet weak var boxBreaksInfo: NSBox!
    @IBOutlet weak var boxStartBreakNew: NSBox!
    @IBOutlet weak var btnOpenCheckLists: iconTitleButton!
    @IBOutlet weak var btnReactivate: iconTitleButton!
    @IBOutlet weak var btnPreferences: iconTitleButton!
    @IBOutlet weak var btnQuit: iconTitleButton!
    @IBOutlet weak var btnCustomRoutine: iconTitleButton!
    @IBOutlet weak var btnEditHabits: iconTitleButton!
    @IBOutlet weak var btnResumeHabits: iconTitleButton!
    @IBOutlet weak var btnStartHabitsFirstTime: iconTitleButton!
    @IBOutlet weak var btnStopHardcorePomodoroMode: iconTitleButton!
    @IBOutlet weak var btnStartSimplePomodoroMode: iconTitleButton!
    @IBOutlet weak var btnStartPomodoroMode: iconTitleButton!
    @IBOutlet weak var btnSetFocusModes: iconTitleButton!
    @IBOutlet weak var btnSetLaterBlockingScheduleFirstTime: underLineButton!
    @IBOutlet weak var btnSetBlockingScheduleFirstTime: Button!
    @IBOutlet weak var lblDescriptionBlockingDisabledFirstTime: NSTextField!
    @IBOutlet weak var lblTitleBlockingDisabledFirstTime: NSTextField!
    @IBOutlet weak var boxBlockingDisabledFirstTime: NSBox!
    @IBOutlet weak var innerTopBoxFocusMode: NSLayoutConstraint!
    @IBOutlet weak var innerBottomBoxFocusMode: NSLayoutConstraint!
    @IBOutlet weak var innerTrailingBoxFocusMode: NSLayoutConstraint!
    @IBOutlet weak var innerLeadingBoxFocusMode: NSLayoutConstraint!
    @IBOutlet weak var boxFocusMode: NSBox!
    @IBOutlet weak var boxSectionMicroBreak: NSBox!
    @IBOutlet weak var lblFocusedToday: NSTextField!
    @IBOutlet weak var lblTotalFocusedTimeToday: NSTextField!
    @IBOutlet weak var lblRemaining: NSTextField!
    @IBOutlet weak var boxFocusModeIntention: NSBox!
    @IBOutlet weak var lblFocusModeIntention: NSTextField!
    @IBOutlet weak var scanningCircleViewForFocusMode: ScanningCircleView!
    @IBOutlet weak var imgViewIconBrainDump: NSImageView!
    @IBOutlet weak var imgViewIconTabAudit: NSImageView!

    @IBOutlet weak var lblCustomBlockingScheduleDayTime: NSTextField!
    @IBOutlet weak var lblCustomBlockingScheduleName: NSTextField!
    @IBOutlet weak var lblCustomBlockingState: NSTextField!
    @IBOutlet weak var btnCustomBlocking: NSSwitch!
    @IBOutlet weak var lblCustomBlocking: NSTextField!
    @IBOutlet weak var boxCustomBlocking: NSBox!
    @IBOutlet weak var btnBrowserTabAudit: mouseDownEffectButton!
    @IBOutlet weak var boxBrowserTabAudit: NSBox!
    @IBOutlet weak var imgViewIconStartBreak: NSImageView!
    @IBOutlet weak var boxForPermissionToolTip: NSBox!
    @IBOutlet weak var stackViewFirst: NSStackView!
    @IBOutlet weak var lblTimerFocusMode: NSTextField!
    @IBOutlet weak var boxFocusModeRemainingTime: NSBox!

    @IBOutlet weak var btnStartBreak: mouseDownEffectButton!
    @IBOutlet weak var boxStartBreak: NSBox!
    @IBOutlet weak var heightButtonSimplePomodoro: NSLayoutConstraint!
    @IBOutlet weak var btnFocusMusic: mouseDownEffectButton!
    @IBOutlet weak var btnTodoPlayer: mouseDownEffectButton!
    @IBOutlet weak var btnBrainDump: mouseDownEffectButton!
    @IBOutlet weak var btnCurrentTrack: mouseDownEffectButton!

    @IBOutlet weak var btnSetPermissions: Button!
    @IBOutlet weak var lblTipPermissions: NSTextField!
    @IBOutlet weak var boxTipPermissions: BlinkingNSBox!
    @IBOutlet weak var btnPin: cursorButton!
    
    @IBOutlet weak var lblTimeSinceLastBreak: NSTextField!
    @IBOutlet weak var boxTimeSinceLastBreak: NSBox!
    @IBOutlet weak var btnEditBlockingSchedule: underLineButton!
    @IBOutlet weak var btnInfoBlockingDisabled: hoverInfoButton!
    @IBOutlet weak var lblBlockingDisabled: NSTextField!
    @IBOutlet weak var boxBlockingDisabled: NSBox!
    @IBOutlet weak var lblTitleToDoPlayer: menuItemLabel!
    @IBOutlet weak var boxToDoPlayer: NSBox!

    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var boxFocusAlignmentScore: NSBox!

    @IBOutlet weak var lblNextBreakTime: NSTextField!
    @IBOutlet weak var boxNextBreak: NSBox!

    @IBOutlet weak var imgViewCurrentTrackState: NSImageView!
    @IBOutlet weak var boxCurrentTrack: NSBox!
    @IBOutlet weak var lblCurrentTrack: NSTextField!
    

    @IBOutlet weak var btnFalseDetection: underLineButton!
    @IBOutlet weak var lblMeetingDetection: NSTextField!
    @IBOutlet weak var btnMeetingDetection: hoverInfoButton!
    @IBOutlet weak var boxMeetingDetection: NSBox!
    @IBOutlet weak var boxTools: NSBox!
    @IBOutlet weak var lblTitleTools: NSTextField!
    @IBOutlet weak var lblTitleBrainDump: NSTextField!
    @IBOutlet weak var boxBrainDump: NSBox!
    @IBOutlet weak var boxFocusMusic: NSBox!
    @IBOutlet weak var lblTitleFocusMusic: menuItemLabel!

    @IBOutlet weak var lblTrialVersionInfo: NSTextField!
    @IBOutlet weak var lblTitleEnterLicenseKey: NSTextField!
    @IBOutlet weak var boxEnterLicenseKey: NSBox!
    @IBOutlet weak var btnEditFocusModeDuration: cursorButton!
    
    
    var imageExpanded = NSImage(named: NSImage.touchBarGoDownTemplateName)
    var imageCollapsed = NSImage(named: NSImage.touchBarGoForwardTemplateName)
    
    var trackingAreaBtnEditBlockingSchedule: NSTrackingArea?
    var trackingAreaBtnEditFocusModeDuration: NSTrackingArea?
    

    var boxPermissionTrackingArea: NSTrackingArea?
    
    var trackingAreaBtnPin: NSTrackingArea?
    
    var toolsMenu:NSMenu!
    var customRoutinesMenu:NSMenu!
    
    var onText = "On"
    var untilTimeText = "ends at <TIME>"
    
    var trialExpiredText = "Your trial has expired!"
    var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
    var itemFocusTitle = "Focus"

    var menuItemUpgradeNowTitle = "Upgrade Now"
    var subscriptionExpiredText = "Your subscription has expired"
    
    var menuItemEnableOfficeModeTitle = "Enable office mode"
    var menuItemDisableOfficeModeTitle = "WFH Mode Enabled"
    
    var toolTipOfficeMode = "When you're working from the office, I will only give you appropriate break activities (e.g. chair stretches rather than pushups)."
    var toolTipWfhMode = "No-one's around! You can do break activities that are a bit more fun, e.g. Dance like no-one's watching"
    
    var iconResumeFocusSession  = NSImage(named: "play_circle")
    var iconStopFocusSession  = NSImage(named: "stop_circle")
    var iconPlayFocusSession = NSImage(named: "play_circle")
    
    var menuItemStartBreak: NSMenuItem!
    var menuItemFocusMusic: NSMenuItem!
    var menuItemToDoList: NSMenuItem!
    var menuItemBrainDump: NSMenuItem!
    var menuItemToDoListTitle = "To Do List"
    var menuItemToDoPlayerTitle = "To Do Player"
    var itemStartPomodoroTitle = "Start Focus Session"
    var itemStopPomodoroTitle = "Stop Focus Session"
    var itemResumePomodoroTitle = "Resume Focus Session"
    var itemPausePomodoroTitle = "Pause Focus Session"
    
    var focusBreakTimeText = "<MINUTE> minutes of break remaining"
    var isMenuShowingFirstTime = false
    var menuItemStopHardcorePomodoroTitle = "Stop Super Focus Session"
    
    
    var enterPasswordVcObj: enterPasswordVc?
    var enterPasswordWcObj: commonWindowController?
    var isShowingPasswordForRelaxFocusMode = false
    var timerReload:Timer?
    var browserPermissionGiven = true
    var accessibilityPermissionGiven = true
    var systemEventsPermissionGiven = true
    var showingPasswordViewForPausingFocusMode = false
    
    var microBreaksTurnedOff = "Micro Breaks are currently turned off."
    var microBreaksDisabledForToday = "Micro Breaks are disabled for today."
    var breaksDisabledFocusSessionRunning = "Focus session is running. Breaks disabled."
    var breaksDisabledSuperFocusSessionRunning = "Super Focus session is running. Breaks disabled."
    var breaksDisabledBlockingScheduleActive = "Blocking schedule is active. Breaks disabled."
    var breaksDisabledRoutinePostponed = "Routine is postponed. Breaks disabled."
    var breaksDisabledHabitInProgress = "A habit is in progress. Breaks disabled."
    
    
        
    // SwiftUI menu redesign — opaque NSHostingView overlaid on the storyboard content.
    // The storyboard outlets/logic stay intact (kept up to date in the background); the
    // SwiftUI view reads a MenuModel that we refresh on each appearance.
    var menuHostingView: NSView?
    var menuModelRef: AnyObject?
    var menuRefreshTimer: Timer?
    /// #2025: a device-mic (LISTEN|START) recording is starting — the recorder starts async, so it may
    /// not be `isRecording` yet when the popover appears and refreshSwiftUIMenu() runs. This one-shot flag
    /// keeps that first refresh on the listening screen instead of resetting to the menu (the race that
    /// made the mic "open the menu but not go into listening state"). Consumed by refreshSwiftUIMenu().
    var pendingDeviceListening = false
    var nextDayPlanHabitName: String?   // raw name of the Day Plan "next habit" (for the play button)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        addLog(text: "menuViewController viewdidload start")
        if #available(macOS 11.0, *) { setupSwiftUIMenu() }
        
        lblTitleHabitStatus.stringValue = "✋Postponed"
        
        lblFocusedToday.stringValue = "FOCUSED TODAY"
        lblRemaining.stringValue = "remaining"
        
        lblTotalFocusedTimeToday.stringValue = ""
        
        boxTipPermissions.isHidden = true
        lblTitleBlockingDisabledFirstTime.stringValue = "Get the most out of Focus Bear"
        
        lblDescriptionBlockingDisabledFirstTime.stringValue = "Set up a blocking schedule to automatically block websites and apps during your focus time."
        
        btnSetBlockingScheduleFirstTime.title = "Set Up Blocking"
        btnSetLaterBlockingScheduleFirstTime.title = "I'll do this later"
        lblBlockingDisabled.stringValue = "🚫 No blocking"
        
        btnEditBlockingSchedule.title = "ENABLE"
        
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            lblFocusedToday.stringValue = menuInfo.value(forKey: "focusedTodayLabel") as? String ?? lblFocusedToday.stringValue
            lblRemaining.stringValue = menuInfo.value(forKey: "remainingText") as? String ?? lblRemaining.stringValue
            lblTitleBlockingDisabledFirstTime.stringValue = menuInfo.value(forKey: "titleBlockingDisabled") as? String ?? lblTitleBlockingDisabledFirstTime.stringValue
            lblDescriptionBlockingDisabledFirstTime.stringValue = menuInfo.value(forKey: "descriptionBlockingDisabled") as? String ?? lblDescriptionBlockingDisabledFirstTime.stringValue
            btnSetBlockingScheduleFirstTime.title = menuInfo.value(forKey: "buttonSetBlockingSchedule") as? String ?? btnSetBlockingScheduleFirstTime.title
            btnSetLaterBlockingScheduleFirstTime.title = menuInfo.value(forKey: "buttonSetLaterBlockingSchedule") as? String ?? btnSetLaterBlockingScheduleFirstTime.title
            lblBlockingDisabled.stringValue = menuInfo.value(forKey: "blockingOff") as? String ?? lblBlockingDisabled.stringValue
            btnEditBlockingSchedule.title = menuInfo.value(forKey: "buttonEnableBlockingSchedule") as? String ?? btnEditBlockingSchedule.title
            lblTitleHabitStatus.stringValue = menuInfo.value(forKey: "habitPostponedState") as? String ?? lblTitleHabitStatus.stringValue
        }
      
        

        if #available(macOS 11.0, *) {
            btnEditHabits.image = NSImage(systemSymbolName: "checkmark.rectangle.fill", accessibilityDescription: nil)
        } else {
            btnEditHabits.image = NSImage(named: "checkmark")
            imgViewIconBrainDump.image = NSImage(named: "brainDump")// for 11.0 already set from storyboard
            imgViewIconTabAudit.image = NSImage(named: NSImage.touchBarOpenInBrowserTemplateName)
        }
        
        
        
        btnEditHabits.title = "Edit Habits"
        lblCustomBlocking.stringValue = "Blocking Schedule"
        if #available(macOS 11.0, *) {
            iconPlayFocusSession = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
        } 

        btnCustomRoutine.title = "Start Custom Routine"
        lblTipPermissions.stringValue = "Grant Focus Bear permissions to block."
        btnSetPermissions.title = "Enable"
        btnStartHabitsFirstTime.title = "Start morning routine"
        btnOpenCheckLists.title = "Open checklist"
        boxTools.wantsLayer = true
        boxTools.layer?.cornerRadius = btnPreferences.cornerRadius
        
        var itemReactivateTitle = "Reactivate"
        var itemEnterLicenseKeyTitle = "Enter License Key"
        var itemPreferences = "Preferences"

        
        lblTitleTools.stringValue = "Tools >"
        var menuItemFocusMusicTitle = "Focus Music"
        
        var titleStartBreak = "Start Break"
        lblTitleBrainDump.stringValue = "Brain Dump"
        
        lblMeetingDetection.stringValue = "Meeting active - breaks off"
        btnFalseDetection.title = "False positive: I'm not in a meeting"
        btnResumeHabits.title = "Resume Habits"
//        lblTitleSetFocus.stringValue = "Set up Focus Modes"
        btnSetFocusModes.title = "Set up Focus Modes"
        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
            btnEditHabits.title = leftMenuVcInfo.value(forKey: "menuEditHabits") as? String ?? btnEditHabits.title
        }
        
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let suggestFocusInfo = focusInfo.value(forKey: "suggestFocusInfo") as? NSDictionary{
                if let val = suggestFocusInfo.value(forKey: "buttonFalseDetectionText") as? String{
                    btnFalseDetection.title = val
                }
            }
        }
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            itemReactivateTitle = menuInfo.value(forKey: "menuItemReactivateTitle") as? String ?? itemReactivateTitle
            itemEnterLicenseKeyTitle = menuInfo.value(forKey: "menuItemEnterLicenseKeyTitle") as? String ?? itemEnterLicenseKeyTitle
            itemPreferences = menuInfo.value(forKey: "menuItemPreferencesTitle") as? String ?? itemPreferences
            itemFocusTitle = menuInfo.value(forKey: "menuItemFocusTitle") as? String ?? itemFocusTitle
//            itemQuitTitle = menuInfo.value(forKey: "menuItemQuitTitle") as? String ?? itemQuitTitle
            itemStartPomodoroTitle = menuInfo.value(forKey: "menuItemStartPomodoroTitle") as? String ?? itemStartPomodoroTitle
            menuItemEnableOfficeModeTitle = menuInfo.value(forKey: "menuItemEnableOfficeModeTitle") as? String ?? menuItemEnableOfficeModeTitle
            menuItemDisableOfficeModeTitle = menuInfo.value(forKey: "menuItemDisableOfficeModeTitle") as? String ?? menuItemDisableOfficeModeTitle
            untilTimeText = menuInfo.value(forKey: "untilTimeText") as? String ?? untilTimeText
            onText = menuInfo.value(forKey: "onText") as? String ?? onText
            menuItemStopHardcorePomodoroTitle = menuInfo.value(forKey: "menuItemStopHardcorePomodoroTitle") as? String ?? menuItemStopHardcorePomodoroTitle
            
            menuItemUpgradeNowTitle = menuInfo.value(forKey: "menuItemUpgradeNowTitle") as? String ?? menuItemUpgradeNowTitle
            subscriptionExpiredText = menuInfo.value(forKey: "subscriptionExpiredText") as? String ?? subscriptionExpiredText
            titleStartBreak = menuInfo.value(forKey: "menuItemStartBreakTitle") as? String ?? titleStartBreak
            lblTitleBrainDump.stringValue = menuInfo.value(forKey: "menuItemBrainDumpTitle") as? String ?? lblTitleBrainDump.stringValue
            toolTipOfficeMode = menuInfo.value(forKey: "toolTipOfficeMode") as? String ?? toolTipOfficeMode
            toolTipWfhMode = menuInfo.value(forKey: "toolTipWfhMode") as? String ?? toolTipWfhMode
            lblTitleTools.stringValue = menuInfo.value(forKey: "menuItemToolsTitle") as? String ?? lblTitleTools.stringValue
//            menuItemOpenToolboxTitle = menuInfo.value(forKey: "menuItemOpenToolboxTitle") as? String ?? menuItemOpenToolboxTitle
            menuItemFocusMusicTitle = menuInfo.value(forKey: "menuItemFocusMusicTitle") as? String ?? menuItemFocusMusicTitle
            menuItemToDoListTitle = menuInfo.value(forKey: "menuItemToDoListTitle") as? String ?? menuItemToDoListTitle
            menuItemToDoPlayerTitle = menuInfo.value(forKey: "menuItemToDoPlayerTitle") as? String ?? menuItemToDoPlayerTitle
            lblMeetingDetection.stringValue = menuInfo.value(forKey: "menuItemMeetingDetectionTitle") as? String ?? lblMeetingDetection.stringValue
            btnResumeHabits.title = menuInfo.value(forKey: "menuItemResumeHabitsTitle") as? String ?? btnResumeHabits.title
            

            
            btnSetFocusModes.title = menuInfo.value(forKey: "menuItemSetFocusModesTitle") as? String ?? btnSetFocusModes.title
            btnOpenCheckLists.title = menuInfo.value(forKey: "menuItemOpenChecklistTitle") as? String ?? btnOpenCheckLists.title
            btnStartHabitsFirstTime.title = menuInfo.value(forKey: "menuItemStartMorningHabitsFirstTimeTitle") as? String ?? btnStartHabitsFirstTime.title
            itemStopPomodoroTitle = menuInfo.value(forKey: "menuItemStopPomodoroTitle") as? String ?? itemStopPomodoroTitle
            focusBreakTimeText = menuInfo.value(forKey: "focusBreakTimeText") as? String ?? focusBreakTimeText
            itemResumePomodoroTitle = menuInfo.value(forKey: "menuItemResumeFocusTitle") as? String ?? itemResumePomodoroTitle
            itemPausePomodoroTitle = menuInfo.value(forKey: "menuItemPauseFocusTitle") as? String ?? itemPausePomodoroTitle
          //  lblBlockingDisabled.stringValue = menuInfo.value(forKey: "menuItemBlockingDisabledTitle") as? String ?? lblBlockingDisabled.stringValue
            btnCustomRoutine.title = menuInfo.value(forKey: "menuItemStartCustomRoutineTitle") as? String ?? btnCustomRoutine.title
            lblTipPermissions.stringValue = menuInfo.value(forKey: "permissionsNotSetText") as? String ?? lblTipPermissions.stringValue
            lblCustomBlocking.stringValue = menuInfo.value(forKey: "titleBlockingSchedule") as? String ?? lblCustomBlocking.stringValue
            lblCustomBlockingState.stringValue = menuInfo.value(forKey: "stateActive") as? String ?? lblCustomBlockingState.stringValue
            btnSetPermissions.title = menuInfo.value(forKey: "buttonEnable") as? String ?? btnSetPermissions.title
            lblFocusedToday.stringValue = menuInfo.value(forKey: "focusedTodayText") as? String ?? lblFocusedToday.stringValue
            lblRemaining.stringValue = menuInfo.value(forKey: "remainingText") as? String ?? lblRemaining.stringValue
        }
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            microBreaksTurnedOff = menuInfo.value(forKey: "microBreaksTurnedOff") as? String ?? microBreaksTurnedOff
            microBreaksDisabledForToday = menuInfo.value(forKey: "microBreaksDisabledForToday") as? String ?? microBreaksDisabledForToday
            breaksDisabledFocusSessionRunning = menuInfo.value(forKey: "breaksDisabledFocusSessionRunning") as? String ?? breaksDisabledFocusSessionRunning
            breaksDisabledSuperFocusSessionRunning = menuInfo.value(forKey: "breaksDisabledSuperFocusSessionRunning") as? String ?? breaksDisabledSuperFocusSessionRunning
            breaksDisabledBlockingScheduleActive = menuInfo.value(forKey: "breaksDisabledBlockingScheduleActive") as? String ?? breaksDisabledBlockingScheduleActive
            breaksDisabledHabitInProgress = menuInfo.value(forKey: "breaksDisabledHabitInProgress") as? String ?? breaksDisabledHabitInProgress
            breaksDisabledRoutinePostponed = menuInfo.value(forKey: "breaksDisabledRoutinePostponed") as? String ?? breaksDisabledRoutinePostponed
        }
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "trialExpiredText") as? String{
                trialExpiredText = text
            }
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }
        }
        
        btnReactivate.title = itemReactivateTitle
        lblTitleEnterLicenseKey.stringValue = menuItemUpgradeNowTitle
        btnPreferences.title = itemPreferences
        btnStartPomodoroMode.title = itemStartPomodoroTitle
        btnStartSimplePomodoroMode.title = itemStartPomodoroTitle
        
        if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let quittingConfirmInfo = quitInfo.value(forKey: "quittingConfirmInfo") as? NSDictionary{
                if let buttonQuitText = quittingConfirmInfo.value(forKey: "buttonQuitText") as? String{
                    btnQuit.title = buttonQuitText
                }
            }
        }
        
        btnStopHardcorePomodoroMode.title = menuItemStopHardcorePomodoroTitle
        btnStopHardcorePomodoroMode.image = iconStopFocusSession
        btnStartSimplePomodoroMode.image = iconPlayFocusSession

        toolsMenu = NSMenu()
        menuItemStartBreak = NSMenuItem(title: titleStartBreak, action: #selector(btnStartBreakClicked(_:)), keyEquivalent: "")
        menuItemStartBreak.target = self
        toolsMenu.addItem(menuItemStartBreak)
        
        menuItemBrainDump = NSMenuItem(title: lblTitleBrainDump.stringValue, action: #selector(btnBrainDumpClicked(_:)), keyEquivalent: "")
        menuItemBrainDump.target = self
        toolsMenu.addItem(menuItemBrainDump)
        
        menuItemToDoList = NSMenuItem(title: menuItemToDoListTitle, action: #selector(openToDoListClicked), keyEquivalent: "")
        menuItemToDoList.target = self
        toolsMenu.addItem(menuItemToDoList)
        
        menuItemFocusMusic = NSMenuItem(title: menuItemFocusMusicTitle, action: #selector(openAllTracksClicked), keyEquivalent: "")
        menuItemFocusMusic.target = self
        toolsMenu.addItem(menuItemFocusMusic)

        
        customRoutinesMenu = NSMenu()
        for i in 0..<arrAllCustomRoutine.count{
            let routine = arrAllCustomRoutine[i]
            if routine.triggerOnDemand{
                let menuItem = NSMenuItem(title: routine.title, action: #selector(menuItemStartRoutineClicked(sender:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.tag = i
                customRoutinesMenu.addItem(menuItem)
            }
        }
        
        
        lblTitleFocusMusic.stringValue = menuItemFocusMusicTitle
        
        if let common = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            for i in 0..<arrFocusType.count{
                if let isDefault = arrFocusType[i]["isDefault"] as? Bool{
                    if  isDefault{
                        if let defaultFocusText = common.value(forKey: "defaultFocusText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                    }
                }
                if let isMeetings = arrFocusType[i]["isMeetings"] as? Bool{
                    if  isMeetings{
                        if let defaultFocusText = common.value(forKey: "meetingsFocusText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                    }
                }
                if let isLockedFocus = arrFocusType[i]["isLockedFocus"] as? Bool{
                    if  isLockedFocus{
                        if let defaultFocusText = common.value(forKey: "lockedFocusText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                        
                    }
                }
                if let isRelaxFocus = arrFocusType[i]["isRelaxFocus"] as? Bool{
                    if  isRelaxFocus{
                        if let defaultFocusText = common.value(forKey: "relaxFocusText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                        
                    }
                }
                if let isRelaxFocus = arrFocusType[i]["isWorkFocus"] as? Bool{
                    if  isRelaxFocus{
                        if let defaultFocusText = common.value(forKey: "workFocusModeText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                        
                    }
                }
            }
        }
        addLog(text: "Set Focus Mode Names from config file")

        
        trackingAreaBtnEditBlockingSchedule = NSTrackingArea.init(rect: btnEditBlockingSchedule.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnEditBlockingSchedule.addTrackingArea(trackingAreaBtnEditBlockingSchedule!)
        
        
        trackingAreaBtnEditFocusModeDuration = NSTrackingArea.init(rect: btnEditFocusModeDuration.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnEditFocusModeDuration.addTrackingArea(trackingAreaBtnEditFocusModeDuration!)
        
        trackingAreaBtnPin = NSTrackingArea.init(rect: btnPin.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnPin.addTrackingArea(trackingAreaBtnPin!)
        

        boxPermissionTrackingArea = NSTrackingArea.init(rect: boxForPermissionToolTip.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        boxForPermissionToolTip.addTrackingArea(boxPermissionTrackingArea!)
        
        
        
        addLog(text: "menuViewController viewdidload end")
        lblTitleToDoPlayer.stringValue = menuItemToDoPlayerTitle


        if SettingsManagerObject.isGeekModeEnabled{
            preferencesSettingsIndex = 3
            preferencesEditHabitsIndex = 4
            preferencesBlocksIndex = 2
        }else{
            preferencesSettingsIndex = 2
            preferencesEditHabitsIndex = 3
            preferencesBlocksIndex = 1
        }
//        boxTipPermissions.isHidden = true
        
        if #available(macOS 11.0, *) {
            imgViewIconStartBreak.image = NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: nil)
        } else {
            imgViewIconStartBreak.image = NSImage(named: NSImage.touchBarUserTemplateName)
        }

        boxFocusModeRemainingTime.isHidden = true

        scanningCircleViewForFocusMode.wantsLayer = true
        scanningCircleViewForFocusMode.layer?.cornerRadius = scanningCircleViewForFocusMode.frame.width / 2
        scanningCircleViewForFocusMode.startAnimating()
        
        expandFocusInfo()
    }

    override func viewDidAppear() {
        if !SettingsManagerObject.isGeekModeEnabled{// geek popupbtn is lokking disabled in simple mode so do this
            self.view.window?.makeKey()
        }
    }
    
    deinit {
        print("MyViewController is deallocated")
    }
    
    @IBAction func btnMeetingDetectionClicked(_ sender: Any) {
        // Explain WHY breaks are off/on during the meeting — text depends on the current state.
        var msg: String
        if SettingsManagerObject.IsShowBreaksInCallEnabled {
            msg = "Breaks are still on during this meeting because you've turned on \"Show breaks in call\". You can turn that off in Settings if you'd rather not be interrupted while presenting."
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary {
                msg = menuInfo.value(forKey: "menuItemMeetingDetectionBreaksOnTooltip") as? String ?? msg
            }
        } else {
            msg = "Looks like you're in a video call. I won't interrupt you with micro-breaks during the meeting to avoid embarrassing screensharing moments. Enjoy the meeting!"
            if let common = configjson.value(forKey: "common") as? NSDictionary {
                msg = common.value(forKey: "notificationVideoCallText") as? String ?? msg
            }
        }
        showTooltip(sender: btnMeetingDetection, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnSetFocusModesClicked(_ sender: Any) {
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnFalseDetectionClicked(_ sender: Any) {
        getMenuWindowObject().window?.close()
        DispatchQueue.global().async {
            usleep(50000)
            DispatchQueue.main.async {
                appdelegate!.showAlertFalseMicDetection()
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == trackingAreaBtnEditBlockingSchedule{
            var toolTipButtonEditBlockingSchedule = "Add blocking schedule"
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                toolTipButtonEditBlockingSchedule = menuInfo.value(forKey: "buttonAddBlockingSchedule") as? String ?? toolTipButtonEditBlockingSchedule
            }
            showTooltipWithOsTahoe(sender: btnEditBlockingSchedule, msg: toolTipButtonEditBlockingSchedule, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
        }else if event.trackingArea == trackingAreaBtnEditFocusModeDuration{
            var buttonEditFocusModeDuration = "Click here to update duration, intention and current task"
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                buttonEditFocusModeDuration = menuInfo.value(forKey: "buttonEditFocusModeDuration") as? String ?? buttonEditFocusModeDuration
            }
            showTooltipWithOsTahoe(sender: btnEditFocusModeDuration, msg: buttonEditFocusModeDuration, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
        }else if event.trackingArea == trackingAreaBtnPin{
            var msg = ""
            if SettingsManagerObject.isMenuPopoverEnabled{
                msg = "Show Focus Bear menu as floating window"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "toolTipPopoverDisable") as? String ?? msg
                }
                
            }else{
                msg = "Show Focus Bear menu as popover"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "toolTipPopoverEnable") as? String ?? msg
                }
            }
            showTooltipWithOsTahoe(sender: btnPin, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:290, autoCloseOnMouseExit: true)
        }else if event.trackingArea == boxPermissionTrackingArea{
            var msg = lblTipPermissions.stringValue
            if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                msg = "- No permissions granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "noPermissionSet") as? String ?? msg
                }
            }else if !browserPermissionGiven{
                msg = "- Permission to any browser not granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "browserPermissionNotSet") as? String ?? msg
                }
            }else if !accessibilityPermissionGiven{
                msg = "- Accessibility permission not granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "accessibilityNotSet") as? String ?? msg
                }
            }else if !systemEventsPermissionGiven{
                msg = "- System Events permission not granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "systemEventsPermissionNotSet") as? String ?? msg
                }
            }
            
            
            showTooltip(sender: boxForPermissionToolTip, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:400, autoCloseOnMouseExit: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == trackingAreaBtnEditBlockingSchedule{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == trackingAreaBtnEditFocusModeDuration{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == trackingAreaBtnPin{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == boxPermissionTrackingArea{
            closePopoverTooltipIfVisible()
        }
    }
    
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()// for geek mode change

        var anyNotificationVisibleInFloatingBear = false
        if floatingTopBarVcObj != nil{
            let visibleViews = floatingTopBarVcObj!.stackViewMoreItems.arrangedSubviews.filter { !$0.isHidden }
            if visibleViews.count != 0{
                anyNotificationVisibleInFloatingBear = true
            }
        }
        
        if (appdelegate?.menuOpenedFromFloatingBar ?? false) || anyNotificationVisibleInFloatingBear{
            if let frame = self.view.window?.frame{
                let windowTopLeftPoint = NSPoint(x: frame.midX, y: frame.maxY)
                showFloatingTopBarWindow(windowTopMidPoint: windowTopLeftPoint)
            }
        }
        
        //If the big floating bear is open, I don’t think we need the little one as well.

        if nudgeFocusAlignmentScoreDippingWcObject != nil{
            if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
                if floatingTopBarVcObj == nil{
                    getFloatingTopBarVObject().loadView()
                }
                getFloatingTopBarVObject().boxMain.isHidden = true
                getFloatingTopBarVObject().boxMoreItems.isHidden = true
            }
        }
    }
    
    
    override func viewWillAppear() {//will not call if view is inside nsmenu but noe using popover so view will appear will work
        if floatingTopBarWcObj != nil{
            if getFloatingTopBarWObject().window?.isVisible ?? false{
                getFloatingTopBarVObject().boxMain.isHidden = true
                getFloatingTopBarVObject().boxMoreItems.isHidden = true
            }
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
        self.view.window?.appearance = getAppAppearance()
        reloadData()
        if #available(macOS 11.0, *) {
            refreshSwiftUIMenu()
            startMenuRefreshTimer()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = nil
    }
    
    func checkPurchaseState(){
        addLog(text: "menuViewController reloadData:- checkPurchaseState:- start, isPurchased:\(isPurchased)")
        if isPurchased == false{
            let daysremaining = daysLeft
            if daysremaining <= 0{
                lblTrialVersionInfo.stringValue = subscriptionExpiredText//trialExpiredText
                lblTrialVersionInfo.textColor = NSColor.systemRed
            }else{
                lblTrialVersionInfo.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")
                lblTrialVersionInfo.textColor = NSColor.black
            }
            boxEnterLicenseKey.isHidden = false
        }else{
            if upgradeNowVcObj != nil{
                if upgradeNowVcObj?.isViewVisible ?? false{
                    upgradeNowVcObj?.closeView()
                }
            }
            boxEnterLicenseKey.isHidden = true
        }
        addLog(text: "menuViewController reloadData:- checkPurchaseState:- end")
    }
    
    func setFocusAlignmentScore(totalSeconds:Int){
        var totalAlignmentScore:Double = 0
        calculateFocusAlignmentScore()
        totalAlignmentScore = currentFocusAlignmentScore//(totalAlignmentScore*100).rounded()/100
        addEntryInfocusAlignmentScoreCsv(url: "", tabTitle: "", focusMode: "", intention: "", aiReason: "", allowedProbability: "", totalScore: "\(totalAlignmentScore)")
        var focusAlignmentScoreText = "Focus alignment score = <SCORE>"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            focusAlignmentScoreText = menuInfo.value(forKey: "focusAlignmentScoreText") as? String ?? focusAlignmentScoreText
        }
        lblFocusAlignmentScore.stringValue = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(totalAlignmentScore)%")
    }
    
    func reloadData(){
        allApiObject.capturePosthog(event: "opened-menu", metadata: [:])
        
        
        if customBlockingScheduleManagerObj.arrBlockingSchedule.count == 0{
            
            if UserDefaults.standard.object(forKey: kUserDefaultsBlockingScheduleAddedFirstTime) == nil{
                boxBlockingDisabledFirstTime.isHidden = false
                boxBlockingDisabled.isHidden = true
            }else{
                boxBlockingDisabledFirstTime.isHidden = true
                boxBlockingDisabled.isHidden = false
            }
        }else{
            boxBlockingDisabledFirstTime.isHidden = true
            boxBlockingDisabled.isHidden = true
        }
        
        
        
        
        if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            boxCustomBlocking.isHidden = false
            lblCustomBlockingState.stringValue = "Active"
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                lblCustomBlockingState.stringValue = menuInfo.value(forKey: "stateActive") as? String ?? lblCustomBlockingState.stringValue
            }
            btnCustomBlocking.state = .on
            for schedule in customBlockingScheduleManagerObj.arrBlockingSchedule{
                if schedule.state == .on{
                    lblCustomBlockingScheduleName.stringValue = schedule.name
                    lblCustomBlockingScheduleDayTime.stringValue = schedule.displayString
                    break;
                }
            }
            
        }else if customBlockingScheduleManagerObj.isAnyCustomSchedulePaused{
            boxCustomBlocking.isHidden = false
            lblCustomBlockingState.stringValue = "Paused"
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                lblCustomBlockingState.stringValue = menuInfo.value(forKey: "statePaused") as? String ?? lblCustomBlockingState.stringValue
            }
            btnCustomBlocking.state = .off
            for schedule in customBlockingScheduleManagerObj.arrBlockingSchedule{
                if schedule.state == .pause{
                    lblCustomBlockingScheduleName.stringValue = schedule.name
                    lblCustomBlockingScheduleDayTime.stringValue = schedule.displayString
                    break;
                }
            }
        }else{
            boxCustomBlocking.isHidden = true
        }

        if customRoutinesMenu.items.count == 0{
            btnCustomRoutine.isHidden = true
        }else{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._CUSTOM_ROUTINE_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                btnCustomRoutine.isHidden = true
            }else{
                if isPurchased == false && daysLeft <= 0{//
                    // will not execute custom rouine if app if subscription is active
                    btnCustomRoutine.isHidden = true
                }else{
                    if isShutOffTimeGoing(){
                        if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
                            btnCustomRoutine.isHidden = false
                        }else{
                            btnCustomRoutine.isHidden = true
                        }
                    }else{
                        btnCustomRoutine.isHidden = false
                    }
                    
                }
            }
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
//            boxTipPermissions.isHidden = false
            browserPermissionGiven = false
            accessibilityPermissionGiven = false
            systemEventsPermissionGiven = false
        }else{
//            if !browserPermissionGiven || !accessibilityPermissionGiven || !systemEventsPermissionGiven{
//                boxTipPermissions.isHidden = false
//            }else{
//                boxTipPermissions.isHidden = true
//            }
            DispatchQueue.global().async {
                var isPermissionGiven = false
                if let arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
                    for i in 0..<arrBrowsersInfo.count{
                        let info = arrBrowsersInfo[i]
                        let isEnabled = info["isEnabled"] as? Bool ?? false
                        if isEnabled{
                            isPermissionGiven = true
                            break;
                        }
                    }
                }
                self.browserPermissionGiven = isPermissionGiven

                if !isAccessibilityEnabled(isPrompt: false){
                    self.accessibilityPermissionGiven = false
                }else{
                    self.accessibilityPermissionGiven = true
                }
                
                if !checkAutomationPermissionWithAppleScript(){
                    self.systemEventsPermissionGiven = false
                }else{
                    self.systemEventsPermissionGiven = true
                }
                
                DispatchQueue.main.async {
                    if !self.browserPermissionGiven || !self.accessibilityPermissionGiven || !self.systemEventsPermissionGiven{
//                        self.boxTipPermissions.isHidden = false
                    }else{
                        self.browserPermissionGiven = true
                    }
                }
            }
        }
        
        boxToDoPlayer.isHidden = false
        if isFocusModeRunning || ((currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && isAnyAllowedFocusModeActivityRunning){
            menuItemToDoList.title = menuItemToDoPlayerTitle

            btnPreferences.borderWidth = 1
            btnPreferences.bgColor = NSColor.white
            btnPreferences.borderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
        }else{
            menuItemToDoList.title = menuItemToDoListTitle
            btnPreferences.borderWidth = 0
            btnPreferences.bgColor = buttonBgColor
        }
        
        
        if isFocusModeRunning{
            boxFocusModeIntention.isHidden = false
            lblFocusModeIntention.stringValue = whatToAchieveInFocusBlock
            let (h,m,_) = secondsToHoursMinutesSeconds(seconds: Int(totalFocuseTime))
            lblTotalFocusedTimeToday.stringValue = "\(h)\(hoursHText) \(m)\(minutesMText)"
            
            
            innerTopBoxFocusMode.constant = 5
            innerBottomBoxFocusMode.constant = 5
            innerTrailingBoxFocusMode.constant = 5
            innerLeadingBoxFocusMode.constant = 5
            boxFocusMode.borderWidth = 1
            boxFocusMode.fillColor = NSColor(named: "settings_BackgroundColor") ?? NSColor.blue
            boxBlockingDisabledFirstTime.isHidden = true// will be hidden during focus session
            boxFocusMode.appearance = NSAppearance(named: .aqua)
            
            btnStopHardcorePomodoroMode.bgColor = NSColor.white
            btnStopHardcorePomodoroMode.borderWidth = 1
            
            btnStartSimplePomodoroMode.bgColor = NSColor.white
            btnStartSimplePomodoroMode.borderWidth = 1
        }else{
            boxFocusModeIntention.isHidden = true
            innerTopBoxFocusMode.constant = 0
            innerBottomBoxFocusMode.constant = 0
            innerTrailingBoxFocusMode.constant = 0
            innerLeadingBoxFocusMode.constant = 0
            boxFocusMode.borderWidth = 0
            boxFocusMode.fillColor = .clear
            boxFocusMode.appearance = getAppAppearance()
            btnStopHardcorePomodoroMode.bgColor = NSColor(named: "light_OrangeColor") ?? NSColor.blue
            btnStopHardcorePomodoroMode.borderWidth = 0
            
            btnStartSimplePomodoroMode.bgColor = NSColor(named: "light_OrangeColor") ?? NSColor.blue
            btnStartSimplePomodoroMode.borderWidth = 0
        }
        
        
        btnEditHabits.borderWidth = btnPreferences.borderWidth
        btnEditHabits.bgColor = btnPreferences.bgColor
        
        if SettingsManagerObject.isMenuPopoverEnabled{
            btnPin.image = #imageLiteral(resourceName: "pin")
        }else{
            btnPin.image = #imageLiteral(resourceName: "unPin")
        }
        
        btnStartHabitsFirstTime.isHidden = true
        
        
        if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_  && UserDefaults.standard.object(forKey: kUserdefaultsStartRoutineButtonClicked) == nil{
            let currentDate = Date()
            let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
            let sameDay = Calendar.current.isDate(currentDate, equalTo: firstRunDate, toGranularity: .day)
            let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false
            if isHabitsDisabled{
                UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
            }else{
                if sameDay || !shouldDoHabits(){
                    btnStartHabitsFirstTime.isHidden = false
                }else{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                }
            }
        }
        
        if !btnStartHabitsFirstTime.isHidden{
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                if isShutOffTimeGoing(){
                    btnStartHabitsFirstTime.title = "Start evening routine"
                    btnStartHabitsFirstTime.title = menuInfo.value(forKey: "menuItemStartEveningHabitsFirstTimeTitle") as? String ?? btnStartHabitsFirstTime.title
                }else{
                    btnStartHabitsFirstTime.title = "Start morning routine"
                    btnStartHabitsFirstTime.title = menuInfo.value(forKey: "menuItemStartMorningHabitsFirstTimeTitle") as? String ?? btnStartHabitsFirstTime.title
                }
            }
        }
        if isFocusModeOnOrPaused(){
            btnStartHabitsFirstTime.isHidden = true
        }
        
        if isAppEnable{
            if isShutOffTimeGoing(){
                boxStartBreak.isHidden = true
                menuItemStartBreak.isHidden = true
            }else{
                if isHabitAlreadyShowed{
                    if currentState == ._MORNING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._CUSTOM_ROUTINE_ || arrAllbreakActivities.count == 0 || currentState == ._SPECIAL_ACTIVITY_{
                        menuItemStartBreak.isHidden = true
                        boxStartBreak.isHidden = true
                    }else{
                        menuItemStartBreak.isHidden = false
                        boxStartBreak.isHidden = false
                    }
                }else{
                    menuItemStartBreak.isHidden = true
                    boxStartBreak.isHidden = true

                }
            }
        }else{
            menuItemStartBreak.isHidden = true
            boxStartBreak.isHidden = true
        }
        boxStartBreakNew.isHidden = boxStartBreak.isHidden
        
        
        
        
        
        
        if arrAllTracks.count == 0{
            menuItemFocusMusic.isHidden = true
            boxFocusMusic.isHidden = true
            boxCurrentTrack.isHidden = true
        }else{
            menuItemFocusMusic.isHidden = false
            var isAnyCurrentMusicVisible = false
            if allTracksVcObj != nil{
                for i in 0..<arrAllTracks.count{
                    if arrAllTracks[i]["isPlaying"] as? Bool == true{
                        lblCurrentTrack.stringValue = arrAllTracks[i]["name"] as? String ?? ""
                        imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                        isAnyCurrentMusicVisible = true
                        break;
                    }else if arrAllTracks[i]["isPaused"] as? Bool == true{
                        lblCurrentTrack.stringValue = arrAllTracks[i]["name"] as? String ?? ""
                        imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                        isAnyCurrentMusicVisible = true
                        break;
                    }
                }
            }
            if isAnyCurrentMusicVisible{
                boxFocusMusic.isHidden = true
                boxCurrentTrack.isHidden = false
            }else{
                boxFocusMusic.isHidden = false
                boxCurrentTrack.isHidden = true
            }
            
        }
        
        if SettingsManagerObject.isGeekModeEnabled{
            boxTimeSinceLastBreak.isHidden = true
            
            if currentState != ._MICRO_BREAK_ && currentState != ._SHUTOFFMAC_{
                if let lastBreakTimeText = getTimeSinceLastBreak(){
                    lblTimeSinceLastBreak.stringValue = lastBreakTimeText
                    boxTimeSinceLastBreak.isHidden = false
                }
            }
            
            boxBrainDump.isHidden = false
           
            boxTools.isHidden = false
            
            boxNextBreak.isHidden = true
            
            
            //we should probably change the break indicator to show "4 minutes of break remaining" if you're in a pomodoro break. 30/5/24
            if appdelegate!.timerPomodoroMode != nil{
                if appdelegate!.timerPomodoroMode!.isValid{
                    boxNextBreak.isHidden = false
                    let currentTime = Date()
                    let breakTime = appdelegate!.timerPomodoroMode!.fireDate
                    let diffMinute = Calendar.current.dateComponents([.minute], from: currentTime, to: breakTime).minute ?? 0
                    lblNextBreakTime.stringValue = focusBreakTimeText.replacingOccurrences(of: "<MINUTE>", with: "\(diffMinute)")
                }
            }
            
            if boxNextBreak.isHidden{
                var breakDisableReason = microBreaksTurnedOff// topdo text for all
                var isBreakEnabled = SettingsManagerObject.isMicroBreaksEnabled
                
                
                if let disableBreaksForTodayDate = UserDefaults.standard.object(forKey: kUserdefaultsDisableBreaksForToday) as? Date{
                    if Calendar.current.isDateInToday(disableBreaksForTodayDate){
                        isBreakEnabled = false
                        breakDisableReason = microBreaksDisabledForToday
                    }
                }

                if getHabitsVcObject().breakTimer != nil{
                    if  isBreakEnabled{
                        if isFocusModeRunning && isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
                            isBreakEnabled = false
                            breakDisableReason = breaksDisabledFocusSessionRunning
                        }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
                            isBreakEnabled = false
                            breakDisableReason = breaksDisabledSuperFocusSessionRunning
                        }else if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                            if !customBlockingScheduleManagerObj.isMicroBreaksEnabled(){
                                isBreakEnabled = false
                                breakDisableReason = breaksDisabledBlockingScheduleActive
                            }
                        }else if currentState == ._CUSTOM_ROUTINE_ || currentState == ._SPECIAL_ACTIVITY_{
                            breakDisableReason = breaksDisabledHabitInProgress
                            isBreakEnabled = false
                        }else if currentState == ._POSTPONE_FOCUS_SUMMARY_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_{
                            if !SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                                isBreakEnabled = false
                                breakDisableReason = breaksDisabledRoutinePostponed
                            }
                        }
                    }
                 
                    
                    if getHabitsVcObject().breakTimer!.isValid && isBreakEnabled{
                        boxNextBreak.isHidden = false
                        let currentTime = Date()
                        let breakTime = getHabitsVcObject().breakTimer!.fireDate
                        let diffMinute = Calendar.current.dateComponents([.minute], from: currentTime, to: breakTime).minute ?? 0
                        var timeText = "\(diffMinute) \(minutesText)"
                        if diffMinute < 1{
                            timeText = "< 1 \(minuteText)"
                        }
                        var nextBreakText = "Next break in: <DURATION>"
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            nextBreakText = menuInfo.value(forKey: "nextBreakText") as? String ?? nextBreakText
                        }
                        nextBreakText = nextBreakText.replacingOccurrences(of: "<DURATION>", with: timeText)
                        lblNextBreakTime.stringValue = nextBreakText
                        lblNextBreakTime.font = getBoldFont(size: 13)
                        
                        
                        if diffMinute < 1{//show the break as soon as there are 5 seconds of inactivity
                            let diffSeconds = Calendar.current.dateComponents([.second], from: currentTime, to: breakTime).second ?? 0
                            if diffSeconds < 5{
                                lblNextBreakTime.stringValue = "It's time for a break. Waiting for a good moment"
                                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                                    lblNextBreakTime.stringValue = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? lblNextBreakTime.stringValue
                                }
                            }
                        }
                    }else{
                        boxNextBreak.isHidden = false
                        lblNextBreakTime.stringValue = breakDisableReason
                        lblNextBreakTime.font = getRegularFont(size: 11)
                    }
                }
            }
            
            if boxNextBreak.isHidden{
                if arrAllbreakActivities.count == 0 {
                    boxNextBreak.isHidden = false
                    lblNextBreakTime.stringValue = "No break activities added yet."
                    if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                        lblNextBreakTime.stringValue = breakStateVcInfo.value(forKey: "noBreakAddedText") as? String ?? lblNextBreakTime.stringValue
                    }
                    lblNextBreakTime.font = getRegularFont(size: 11)
                }
            }
            
            if boxBlockingDisabled.isHidden && boxFocusInfo.isHidden && isFocusModeRunning{
                 boxLblTitleFocusStatus.isHidden = false
             }else{
                 boxLblTitleFocusStatus.isHidden = true
             }
            
            
            
            
            if !lblNextBreakTime.stringValue.isEmpty && boxBreaksInfo.isHidden && !boxNextBreak.isHidden{
                lblTitleBreakStatus.isHidden = false
                lblTitleBreakStatus.stringValue = lblNextBreakTime.stringValue
            }else{
                lblTitleBreakStatus.isHidden = true
            }
            
            if appdelegate!.isUserOnMeeting{
                boxMeetingDetection.isHidden = false
                if SettingsManagerObject.IsShowBreaksInCallEnabled{
                    // Keep the info button visible so the "why" is reachable (hover/click) in the
                    // breaks-on state too — previously it was hidden, leaving no explanation.
                    btnMeetingDetection.isHidden = false
                    lblMeetingDetection.stringValue = "Meeting active - breaks on"
                    if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                        lblMeetingDetection.stringValue = menuInfo.value(forKey: "menuItemMeetingDetectionBreaksOnTitle") as? String ?? lblMeetingDetection.stringValue
                    }
                }else{
                    btnMeetingDetection.isHidden = false
                    lblMeetingDetection.stringValue = "Meeting active - breaks off"
                    if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                        lblMeetingDetection.stringValue = menuInfo.value(forKey: "menuItemMeetingDetectionTitle") as? String ?? lblMeetingDetection.stringValue
                    }
                    boxNextBreak.isHidden = true
                }
            }else{
                boxMeetingDetection.isHidden = true
            }
            
            
            boxSectionMicroBreak.isHidden = false

            if boxNextBreak.isHidden && boxMeetingDetection.isHidden && boxTimeSinceLastBreak.isHidden{
                boxSectionMicroBreak.isHidden = true
            }
            
            if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
                btnSetFocusModes.isHidden = false
            }else{
                btnSetFocusModes.isHidden = true
            }
            let isFocusModeOn = isFocusModeOn()
            let isFocusModePaused = isFocusModePaused()
            
            if isFocusModeOn || isFocusModePaused{
                if isFocusModeOn{
                    if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn(){
                        boxFocusAlignmentScore.isHidden = false
                        setFocusAlignmentScore(totalSeconds: focusModeMinutesToPerform * 60)
                    }else{
                        boxFocusAlignmentScore.isHidden = true
                    }
                    btnStopHardcorePomodoroMode.title = itemStopPomodoroTitle
                    btnStopHardcorePomodoroMode.image = iconStopFocusSession
                }else {
                    boxFocusAlignmentScore.isHidden = true
                    btnStopHardcorePomodoroMode.title = itemResumePomodoroTitle
                    btnStopHardcorePomodoroMode.image = iconResumeFocusSession
                }
                btnStartPomodoroMode.isHidden = true
                btnStopHardcorePomodoroMode.isHidden = false
                
            }else{
                boxFocusAlignmentScore.isHidden = true
                if isHardCorePomodoroModeOn{
                    
                    if currentFocusModeStrictness == ._SUPER_STRICT_{
                        btnStopHardcorePomodoroMode.isHidden = true// not showing stop pomodoro button in pomodoro breaks if strictness is super strict
                    }else{
                        btnStopHardcorePomodoroMode.isHidden = false
                        btnStopHardcorePomodoroMode.title = menuItemStopHardcorePomodoroTitle
                        btnStopHardcorePomodoroMode.image = iconStopFocusSession
                    }
                    btnStartPomodoroMode.isHidden = true
                }else{
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                        btnStartPomodoroMode.isHidden = true
                    }else{
                        btnStartPomodoroMode.isHidden = false
                    }
                    btnStopHardcorePomodoroMode.isHidden = true
                }
                
                if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                    boxFocusAlignmentScore.isHidden = false
                    setFocusAlignmentScore(totalSeconds: focusModeMinutesToPerform * 60)
                }else{
                    boxFocusAlignmentScore.isHidden = true
                    
                }
            }
            
            
            
            if boxFocusAlignmentScore.isHidden{
                if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && (currentHabitPlaying != nil) && isAnyAllowedFocusModeActivityRunning{
                    if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn(){
                        boxFocusAlignmentScore.isHidden = false
                        setFocusAlignmentScore(totalSeconds: currentHabitPlaying?.durationSeconds ?? 200)
                    }
                }
            }
            btnStartSimplePomodoroMode.isHidden = true
            
        }else{
            boxTimeSinceLastBreak.isHidden = true
            boxBrainDump.isHidden = false
            boxTools.isHidden = false// 19/7/25 version 1.26.392   #1467
            boxNextBreak.isHidden = true
            boxMeetingDetection.isHidden = true
            btnSetFocusModes.isHidden = true
            boxFocusAlignmentScore.isHidden = true
            btnStartPomodoroMode.isHidden = true
            btnStopHardcorePomodoroMode.isHidden = true
            //boxEnableOfficeMode.isHidden = true
            boxSectionMicroBreak.isHidden = true
            
            let isFocusModeOn = isFocusModeOn()
            let isFocusModePaused = isFocusModePaused()

            if isFocusModeOn || isFocusModePaused{
                btnStartSimplePomodoroMode.font = NSFont.systemFont(ofSize: 13)
                if isFocusModeStartedFromPomodoroMode{
                    if isFocusModeOn{
                        btnStartSimplePomodoroMode.title = itemStopPomodoroTitle
                        btnStartSimplePomodoroMode.image = iconStopFocusSession
                    }else{
                        btnStartSimplePomodoroMode.title = itemResumePomodoroTitle
                        btnStartSimplePomodoroMode.image = iconResumeFocusSession
                    }
                    btnStartSimplePomodoroMode.isHidden = false
                }else{
                    btnStartSimplePomodoroMode.isHidden = true
                }
                
                heightButtonSimplePomodoro.constant = 35
                btnStartSimplePomodoroMode.iconSize = 23
                btnStartSimplePomodoroMode.borderWidth = 0
            }else{
                btnStartSimplePomodoroMode.title = itemStartPomodoroTitle
                btnStartSimplePomodoroMode.image = iconPlayFocusSession
                heightButtonSimplePomodoro.constant = 46
                btnStartSimplePomodoroMode.borderWidth = 2
                btnStartSimplePomodoroMode.iconSize = 28
                btnStartSimplePomodoroMode.font = NSFont.boldSystemFont(ofSize: 16)
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                    btnStartSimplePomodoroMode.isHidden = true
                }else{
                    btnStartSimplePomodoroMode.isHidden = false
                }
            }
            
            
        }
        

        if boxCustomBlocking.isHidden && boxFocusAlignmentScore.isHidden && boxFocusModeIntention.isHidden && boxFocusModeRemainingTime.isHidden && btnStartPomodoroMode.isHidden && btnStartSimplePomodoroMode.isHidden && btnStopHardcorePomodoroMode.isHidden && btnSetFocusModes.isHidden{
            boxSectionFocusMode.isHidden = true
        }else{
            boxSectionFocusMode.isHidden = false
        }
        
        if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
            btnResumeHabits.isHidden = false
            boxLblTitleHabitStatus.isHidden = false
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            boxLblTitleHabitStatus.isHidden = false
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
            btnResumeHabits.isHidden = false
            boxLblTitleHabitStatus.isHidden = false
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit{
            btnResumeHabits.isHidden = false
            boxLblTitleHabitStatus.isHidden = false
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
            btnResumeHabits.isHidden = false
            boxLblTitleHabitStatus.isHidden = false
        }else{
            btnResumeHabits.isHidden = true
            boxLblTitleHabitStatus.isHidden = true
        }
        
        
        checkPurchaseState()
        
        if !isAppEnable{
            btnReactivate.isHidden = false
        }else{
            btnReactivate.isHidden = true
        }

        
        btnOpenCheckLists.isHidden = true
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._CUSTOM_ROUTINE_{
            if currentAction == ._INPROGRESS_{
                if isMainWindowLoaded{
                    if !(mainWindowControllerObj?.window?.isVisible ?? false){
                        if let checkList = currentHabitPlaying?.checkList{
                            if checkList.count != 0{
                                btnOpenCheckLists.isHidden = false
                            }
                        }
                        if let checkList = currentActivityPlaying?.checkList{
                            if checkList.count != 0{
                                btnOpenCheckLists.isHidden = false
                            }
                        }
                    }
                }
            }
        }
        
        if isMenuShowingFirstTime{
            isMenuShowingFirstTime = false
            if !self.btnStartSimplePomodoroMode.isHidden{
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.btnStartSimplePomodoroMode.wantsLayer = true
                        self.showAnimationSimplePomodoro()
                        var msg = "You may want to Start a Focus session to focus on specific work for a set duration." 
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            msg = menuInfo.value(forKey: "toolTipPomodoroSessionText") as? String ?? msg
                        }
                        showTooltip(sender: self.btnStartSimplePomodoroMode, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
                    }
                }
            }
            
            
        }
        
        addLog(text: "menuViewController reloadData end")
        if SettingsManagerObject.isMenuPopoverEnabled{
            self.timerReload?.invalidate()
            self.timerReload = nil
        }else{
            if self.timerReload == nil || !(self.timerReload?.isValid ?? false){
                DispatchQueue.global().sync {
                    self.timerReload = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.reloadIfNeeded), userInfo: nil, repeats: true)
                    RunLoop.main.add((self.timerReload!), forMode: RunLoop.Mode.common)
                }
            }
        }
    }
    
    func showFocusModeCountDownIfNeeded(){
        if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning) && endFocusModeTime != nil{
            setFocusModeCoundDownTimer()
        }else{
            stopFocusModeCountDownTimer()
        }
    }
    
    var timerFocusModeCoundDown:Timer?
    func setFocusModeCoundDownTimer(){
        stopFocusModeCountDownTimer()
        boxFocusModeRemainingTime.isHidden = false
        DispatchQueue.global().sync {
            self.timerFocusModeCoundDown = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performFocusModeCoundDown), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerFocusModeCoundDown!), forMode: RunLoop.Mode.common)
        }
        performFocusModeCoundDown()
    }
    
    func stopFocusModeCountDownTimer(){
        self.timerFocusModeCoundDown?.invalidate()
        self.timerFocusModeCoundDown = nil
        boxFocusModeRemainingTime.isHidden = true
    }
    
    @objc func performFocusModeCoundDown(){
        if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning){
            if let date = endFocusModeTime{
                let secondsBetween = date.timeIntervalSince(Date())
                if secondsBetween < 0{
                    stopFocusModeCountDownTimer()
                }
                let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
                var hour = "\(h)"
                var minute = "\(m)"
                var second = "\(s)"
                
                if hour.count == 1 {
                    hour = "0\(h)"
                }
                if minute.count == 1 {
                    minute = "0\(m)"
                }
                if second.count == 1 {
                    second = "0\(s)"
                }
                

                let finalTitle = "\(hour):\(minute):\(second)"
                lblTimerFocusMode.stringValue = finalTitle
                lblTitleFocusStatus.stringValue = finalTitle
                if nudgeFocusAlignmentScoreDippingWcObject != nil{
                    if nudgeFocusAlignmentScoreDippingWcObject?.window?.isVisible ?? false{
                        if nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ?? false{
                            nudgeFocusAlignmentScoreDippingVcObj?.lblTimer.stringValue = finalTitle
                        }
                    }
                }
            }else{
                stopFocusModeCountDownTimer()
            }
        }else{
            stopFocusModeCountDownTimer()
        }
    }
    
    
    @objc func reloadIfNeeded(){
        if !SettingsManagerObject.isMenuPopoverEnabled{
            if menuWcObj?.window?.isVisible ?? false{
                reloadData()
            }
        }else{
            self.timerReload?.invalidate()
            self.timerReload = nil
        }
    }
    
    
    func showAnimationSimplePomodoro(){
        DispatchQueue.global().async {
            usleep(50000)
            for i in 0..<8{
                if i % 2 == 0{
                    DispatchQueue.main.async {
                        if self.btnStartSimplePomodoroMode.isHidden{
                            return;
                        }
                        self.btnStartSimplePomodoroMode.bgColor = NSColor.systemYellow
                    }
                }else{
                    DispatchQueue.main.async {
                        self.btnStartSimplePomodoroMode.bgColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
                        if self.btnStartSimplePomodoroMode.isHidden{
                            return;
                        }
                    }
                }
                usleep(500000)
            }
        }
    }

    @IBAction func btnReactivateClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- menu Item Reactivate clicked")
        appdelegate?.menuItem_Reactivate()
        closeMenuWindowIsVisible()
    }
    
    @objc func menuItemStartRoutineClicked(sender:NSMenuItem){
        addLog(text:"[user-action] menuViewController:- menuItemStartRoutineClicked")
        if isPurchased == false && daysLeft <= 0{
            showUpgradeNowWindow(reason: "start_routine_expired")
            return;
        }
        startCustomRoutine(index: sender.tag, isOnDemand:true)
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnEnterLicenseKeyClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnEnterLicenseKeyClicked")
        showUpgradeNowWindow(reason: "enter_license_key")
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnPreferencesClicked(_ sender: Any) {
        appdelegate?.menuItem_Preferences()
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnStartBreakClicked(_ sender: Any) {
        addLog(text: "[user-action] button Start Break Clicked")
        // A class session is in control — don't let the student start a micro break manually.
        if teacherSessionManagerObject.isTeacherSessionActive(){
            teacherSessionManagerObject.showTeacherSessionLockedAlert()
            return
        }
        if !isMainWindowLoaded{
            mainWindowControllerObj?.loadWindow()
        }
        isBreakActivityExecuteFromPostponeMorningHabit = false
        isBreakActivityExecuteFromPostponeEveningHabit = false
        isBreakActivityExecuteFromPostponeEveningHabit = false
        if currentState == ._POSTPONE_MORNING_HABIT_{// ⚠️ do not change current state inside this block
            // new work // 20/04/23
            isBreakActivityExecuteFromPostponeMorningHabit = true//
        }
        
        if currentState == ._POSTPONE_EVENING_HABIT_{// ⚠️ do not change current state inside this block
            isBreakActivityExecuteFromPostponeEveningHabit = true
        }
        
        if currentState == ._POSTPONE_FOCUS_SUMMARY_{// ⚠️ do not change current state inside this block
            isBreakActivityExecuteFromPostponeEveningHabit = true
        }
        getHabitsVcObject().executeBreakActivities()
        closeMenuWindowIsVisible()
    }
    
    
    @IBAction func btnBrainDumpClicked(_ sender: Any) {
        addLog(text: "[user-action] button Brain Dump Clicked")
        showBrainDumpWindow()
        closeMenuWindowIsVisible()
        teachShortcut(.brainDump)
    }

    @IBAction func btnToDoPlayerClicked(_ sender: Any) {
        addLog(text: "[user-action] btnToDoPlayerClicked")
        openToDoListClicked()
        closeMenuWindowIsVisible()
        teachShortcut(.taskList)
    }

    @IBAction func btnFocusMusicClicked(_ sender: Any) {
        openAllTracksClicked()
        closeMenuWindowIsVisible()
        teachShortcut(.focusMusic)
    }

    /// Show the "try the shortcut next time" toast. Only called from the click entry points
    /// above — the Carbon hotkey handlers bypass these, so users who already use the shortcut
    /// don't get nagged (#2003).
    private func teachShortcut(_ action: ShortcutTeachableAction) {
        ShortcutHintToast.shared.teach(action)
    }
    
    @objc func openToolBoxClicked(){
        addLog(text: "[user-action] openToolBoxClicked")
        closeMenuWindowIsVisible()
    }
    
    @objc func openToDoListClicked(){
        addLog(text: "[user-action] openToDoListClicked")
        if isFocusModeOn() || ((currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && isAnyAllowedFocusModeActivityRunning) || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            showTaskPlayerWindow(totalDuration: focusModeMinutesToPerform, intention: whatToAchieveInFocusBlock, automatically:false)
            closeMenuWindowIsVisible()
        }else{
            showToDoListWindow()
            closeMenuWindowIsVisible()
        }
    }
    
    @objc func openAllTracksClicked(){
        addLog(text: "[user-action] openAllTracksClicked")
        showAllTracksWindow()
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnExportStatisticsClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnExportStatisticsClicked")
        if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            showUpgradeNowWindow(reason: "export_statistics_expired")
            closeMenuWindowIsVisible()
            return;
        }
    }
    
    @IBAction func btnStartSimplePomodoroModeClicked(_ sender: Any) {

        var isFocusModeOn = false
        
        for index in 0..<arrFocusType.count{
            if arrFocusType[index]["isOn"] as? Bool == true || arrFocusType[index]["isPaused"] as? Bool == true{
                //abort focus mode
                // new work 13/3/22
                isFocusModeOn = true
                if arrFocusType[index]["isOn"] as? Bool == true{
                    let menu = NSMenu()
                    if timerForFocusMode != nil{
                        let menuItemPause = NSMenuItem(title: itemPausePomodoroTitle, action: #selector(pauseFocusModeClicked), keyEquivalent: "")
                        menuItemPause.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                        menuItemPause.target = self
                        menu.addItem(menuItemPause)
                    }
                    
                    let menuItemStop = NSMenuItem(title: itemStopPomodoroTitle, action: #selector(stopFocusMode), keyEquivalent: "")
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    menu.minimumWidth = btnStartSimplePomodoroMode.frame.width
                    let p = NSPoint(x: btnStartSimplePomodoroMode.frame.origin.x, y: btnStartSimplePomodoroMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStartSimplePomodoroMode)
                    
                    break;
                }else if arrFocusType[index]["isPaused"] as? Bool == true{
                    
                    let menu = NSMenu()
                    let menuItemResume = NSMenuItem(title: itemResumePomodoroTitle, action: #selector(resumeFocusMode), keyEquivalent: "")
                    menuItemResume.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                    menuItemResume.target = self
                    menu.addItem(menuItemResume)
                    
                    let menuItemStop = NSMenuItem(title: itemStopPomodoroTitle, action: #selector(stopFocusMode), keyEquivalent: "")
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    
                    
                    menu.minimumWidth = btnStartSimplePomodoroMode.frame.width
                    let p = NSPoint(x: btnStartSimplePomodoroMode.frame.origin.x, y: btnStartSimplePomodoroMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStartSimplePomodoroMode)
                    break;
                }
            }
        }
        
        if !isFocusModeOn{
            appdelegate?.menuShowSimplePomodoroModeView()
            closeMenuWindowIsVisible()
        }
    }
    
    @IBAction func btnStartPomodoroModeClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnStartPomodoroModeClicked")
        if isPurchased == false && daysLeft <= 0{
            showUpgradeNowWindow(reason: "start_pomodoro_expired")
            return;
        }
        appdelegate?.menuShowPomodoroModeView()
        closeMenuWindowIsVisible()
    }

    func showPasswordWindow(){
        showingPasswordViewForPausingFocusMode = false
        isShowingPasswordForRelaxFocusMode = false
        if self.enterPasswordVcObj == nil{
            self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
            enterPasswordVcObj?.parentVc = self
        }
        if enterPasswordWcObj == nil{
            self.enterPasswordWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as?commonWindowController
            enterPasswordWcObj?.contentViewController = enterPasswordVcObj
            self.enterPasswordWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        }
        enterPasswordWcObj?.showWindow(self)
        
    }
    
    func passwordIsCorrect(){
        if isShowingPasswordForRelaxFocusMode{
            for i in 0..<arrFocusType.count{
                if let isRelaxFocus = arrFocusType[i]["isRelaxFocus"] as? Bool{
                    if  isRelaxFocus{
                        appdelegate?.menuShowPomodoroModeView()
                        if !(pomodoroVcObj?.isViewLoaded ?? false){
                            pomodoroVcObj?.loadView()
                        }
                        pomodoroVcObj!.selectFocusModeWithId(id: arrFocusType[i]["id"] as? String ?? "", duration: customUrlHandleLastDurationForRelaxFocusMode)
                        closeMenuWindowIsVisible()
                        break;
                    }
                }
            }
        }else{
            if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                customBlockingScheduleManagerObj.customBlockingSchedulePaused()
                return;
            }
            if isFocusModeOnOrPaused(){
                if showingPasswordViewForPausingFocusMode{
                    pauseFocusMode()
                }else{
                    showAbortingFocusModeVc(forPause: false)
                }
                closeMenuWindowIsVisible()
            }else{
                isHardCorePomodoroModeOn = false
                if mainWindowControllerObj?.window?.isVisible ?? false{
                    if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                        if SettingsManagerObject.isGeekModeEnabled{
                            appdelegate?.menuShowPomodoroModeView()
                        }else{
                            appdelegate?.menuShowSimplePomodoroModeView()
                        }
                    }
                }
                reloadData()
                closeMenuWindowIsVisible()
            }
        }
        showingPasswordViewForPausingFocusMode = false
    }
    
    @IBAction func btnStopHardcorePomodoroModeClicked(_ sender: Any) {
        if isFocusCompletedViewVisibled(){
            addLog(text: "focus mode clicked:- focus mode completed Window is visible:- return")
            return;
        }
        
        var isFocusModeOn = false
        
        for index in 0..<arrFocusType.count{
            if arrFocusType[index]["isOn"] as? Bool == true || arrFocusType[index]["isPaused"] as? Bool == true{
                //abort focus mode
                // new work 13/3/22
                isFocusModeOn = true
                if arrFocusType[index]["isOn"] as? Bool == true{
                    let menu = NSMenu()
                    if timerForFocusMode != nil{
                        let menuItemPause = NSMenuItem(title: itemPausePomodoroTitle, action: #selector(pauseFocusModeClicked), keyEquivalent: "")
                        menuItemPause.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                        menuItemPause.target = self
                        menu.addItem(menuItemPause)
                    }
                    
                    let menuItemStop = NSMenuItem(title: itemStopPomodoroTitle, action: #selector(stopFocusMode), keyEquivalent: "")
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    menu.minimumWidth = btnStopHardcorePomodoroMode.frame.width
                    let p = NSPoint(x: btnStopHardcorePomodoroMode.frame.origin.x, y: btnStopHardcorePomodoroMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStopHardcorePomodoroMode)
                    
                    break;
                }else if arrFocusType[index]["isPaused"] as? Bool == true{
                    
                    let menu = NSMenu()
                    let menuItemResume = NSMenuItem(title: itemResumePomodoroTitle, action: #selector(resumeFocusMode), keyEquivalent: "")
                    menuItemResume.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                    menuItemResume.target = self
                    menu.addItem(menuItemResume)
                    
                    let menuItemStop = NSMenuItem(title: itemStopPomodoroTitle, action: #selector(stopFocusMode), keyEquivalent: "")
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    
                    
                    menu.minimumWidth = btnStopHardcorePomodoroMode.frame.width
                    let p = NSPoint(x: btnStopHardcorePomodoroMode.frame.origin.x, y: btnStopHardcorePomodoroMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStopHardcorePomodoroMode)
                    break;
                }
            }
        }
        
        if !isFocusModeOn{
            if isHardCorePomodoroModeOn{
                if shouldAskPassword(){
                    if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                        showPasswordWindow()
                        addLog(text: "Showing enter password view from hardcodre pomodoro stop from menu")
                    }else{
                        isHardCorePomodoroModeOn = false
                        closeMenuWindowIsVisible()
                    }
                }else{
                    isHardCorePomodoroModeOn = false
                    closeMenuWindowIsVisible()
                }
            }else{
                btnStopHardcorePomodoroMode.isHidden = true
                closeMenuWindowIsVisible()
            }
        }
    }
    
    
    @objc func pauseFocusModeClicked(){
        if teacherSessionManagerObject.isTeacherSessionActive(){// C3:- no pausing a teacher controlled session, route to the unlock request ux instead of the password view
            addLog(text: "pause focus mode blocked:- teacher session is active")
            teacherSessionManagerObject.showTeacherSessionLockedAlert()
            closeMenuWindowIsVisible()
            return;
        }
        if currentFocusModeStrictness == ._SUPER_STRICT_{
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if let lastUnlockTimeByAccountabilityBuddy = lastUnlockTimeByAccountabilityBuddy{// if no password is set  then chance of getting lastUnlockTimeByAccountabilityBuddy is 0% but if password is set then check this
                    if Date() < lastUnlockTimeByAccountabilityBuddy{
                        pauseFocusMode()
                        return;
                    }
                }
            }
            
            showPasswordWindow()// show without checking . if password not there then show enter random characters view
            addLog(text: "Showing enter password view for super strict focus stop from focus stop menu")
            showingPasswordViewForPausingFocusMode = true
        }else if currentFocusModeStrictness == ._STRICT_{
            showAbortingFocusModeVc(forPause: true)
        }else{
            pauseFocusMode()
        }
    }
    
    @IBAction func btnEditFocusModeDurationClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnEditFocusModeDurationClicked")
        
        if mainWindowControllerObj?.window?.isVisible ?? false{
            leftMenuVcObj?.showFocusModeStateView()
        }else{
            mainWindowControllerObj?.showWindow(self)
            leftMenuVcObj?.showFocusModeStateView()
        }
        closeMenuWindowIsVisible()
    }
    
    func pauseFocusMode(){
        for index in 0..<arrFocusType.count{
            if arrFocusType[index]["isOn"] as? Bool == true{
                appdelegate?.pauseFocusMode(index: index)
                if SettingsManagerObject.isMenuPopoverEnabled{
                    appdelegate?.popover.close()
                }else{
                    closeMenuWindowIsVisible()
                }
                break;
            }
        }
    }
    
    @objc func stopFocusMode(){
        if teacherSessionManagerObject.isTeacherSessionActive(){// C3:- no stopping a teacher controlled session early, route to the unlock request ux instead of the password view
            addLog(text: "stop focus mode blocked:- teacher session is active")
            teacherSessionManagerObject.showTeacherSessionLockedAlert()
            closeMenuWindowIsVisible()
            return;
        }
        var needToShowPassword = false
        if currentFocusModeStrictness == ._SUPER_STRICT_{
            needToShowPassword = true// show without checking . if password not there then show enter random characters view
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if let lastUnlockTimeByAccountabilityBuddy = lastUnlockTimeByAccountabilityBuddy{// if no password is set  then chance of getting lastUnlockTimeByAccountabilityBuddy is 0% but if password is set then check this
                    if Date() < lastUnlockTimeByAccountabilityBuddy{
                        needToShowPassword = false
                    }
                }
            }
            addLog(text: "Showing enter password view for super strict focus stop from focus stop menu:- \(needToShowPassword)")
        }
        
        if needToShowPassword{
            showPasswordWindow()// show without checking . if password not there then show enter random characters view
            addLog(text: "Showing enter password view for super strict focus stop from focus stop menu")
        }else if isHardCorePomodoroModeOn{
            if shouldAskPassword(){
                if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                    showPasswordWindow()
                    addLog(text: "Showing enter password view from hardcore pomodoro stop from focus stop menu")
                }else{
                    showAbortingFocusModeVc(forPause: false)
                    closeMenuWindowIsVisible()
                }
            }else{
                showAbortingFocusModeVc(forPause: false)
                closeMenuWindowIsVisible()
            }
        }else{
            showAbortingFocusModeVc(forPause: false)
            closeMenuWindowIsVisible()
        }
    }
    
    @objc func resumeFocusMode(){
        for index in 0..<arrFocusType.count{
            if arrFocusType[index]["isPaused"] as? Bool == true{
                appdelegate?.resumeFocusMode(index: index)
                if SettingsManagerObject.isMenuPopoverEnabled{
                    appdelegate?.popover.close()
                }else{
                    closeMenuWindowIsVisible()
                }
                break;
            }
        }
    }

    
    @IBAction func btnQuitClicked(_ sender: Any) {
        addLog(text: "[user-action] menu item Quit clicked by user")
        if quittingWcObj != nil{
            if quittingWcObj?.window?.isVisible ?? false{
                addLog(text: "Quit window already visible")
                return
            }
        }
        
        showQuitWindow()
        closeMenuWindowIsVisible()
    }
    

    
    func addOfficeFriendlyActivityInSettings(){
        addLog(text: "addOfficeFriendlyActivityInSettings")//
        var jsonResult = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            //            jsonResult = dic
            if let data = stringDic.data(using: String.Encoding.utf8) {
                
                do {
                    jsonResult = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                    
                } catch let error as NSError {
                    print(error)
                }
            }
            
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    do {
                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            jsonResult = dicResult
                            print(jsonResult)
                        }
                    }catch {
                        print(error)
                    }
                } catch {
                    // handle error
                }
            }
        }
        guard let mutableDic = jsonResult.mutableCopy() as? NSMutableDictionary else{
            return
        }
        let id = getUuid()
        var activity_sequence_id = getUuid()
        
        if let firstActivity = arrAllbreakActivities.first{
            activity_sequence_id = firstActivity.activity_sequence_id
        }
        
        var officeFriendlyActivityName = "Stand up and stretch"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            officeFriendlyActivityName = common.value(forKey: "officeFriendlyActivityName") as? String ?? officeFriendlyActivityName
        }
        
        
        if var breakActivities = mutableDic.value(forKey: "break_activities") as? [NSDictionary] {
            let activityDic: NSMutableDictionary = ["id":id, "name":officeFriendlyActivityName, "duration_seconds":20, "is_office_friendly":true, "activity_sequence_id":activity_sequence_id]
            breakActivities.append(activityDic)
            mutableDic["break_activities"] = breakActivities
            
            arrAllbreakActivities.append(breakActivity(id:id,name: officeFriendlyActivityName, durationSeconds: 20, IncludeInEveryBreak: false, urlsArray: [], logQuantity:false, choiceType: ._NONE_, choices: [], logQuantityQuestion: "", openSpecificApps: false, allowUrls: [], allowApps: [], isOfficeFriendly: true, allowedFocusMode: "", logQuantityType: "",activity_sequence_id:activity_sequence_id, take_notes: "", text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[]))

            allApiObject.isSettingsValid(settings: mutableDic, isOnboarding:false, completionHandler: {dic,statusCode  in
                DispatchQueue.main.async {
                    
                    
                    if dic == nil{
                        
                        
                    }else{
                        if statusCode == 200{
                            do {
                                let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                                
                                print(jsonResultData)
                                
                                if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                    UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                    
                                }
                                
                                
                            } catch let myJSONError {
                                print(myJSONError)
                            }
                            
                        }else{
                            
                        }
                    }
                }
            })
            
        }
        
        
    }
    

    
    @IBAction func btnOpenCheckListsClicked(_ sender: Any) {
        addLog(text: "[user-action] menu item Open CheckLists clicked")
        if currentHabitPlaying != nil{
            if let checkList = currentHabitPlaying?.checkList{
                if checkList.count != 0{
                    showPopUpCheckListWindow(title: currentHabitPlaying?.name ?? "", list: currentHabitPlaying?.checkList ?? [])
                }
            }
        }else if currentActivityPlaying != nil{
            if let checkList = currentActivityPlaying?.checkList{
                if checkList.count != 0{
                    showPopUpCheckListWindow(title: currentActivityPlaying?.name ?? "", list: currentActivityPlaying?.checkList ?? [])
                }
            }
        }
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnToolsClicked(_ sender: Any) {
        addLog(text: "[user-action] menu item tools clicked")
        
        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            showUpgradeNowWindow(reason: "tools_menu_expired")
            return;
        }
        toolsMenu.minimumWidth = boxTools.frame.width
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y )
        toolsMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
    
    @IBAction func btnResumeHabitsClicked(_ sender: Any) {
        addLog(text: "[user-action] btnResumeHabitsClicked")
        if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
            getHabitsVcObject().stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            
            isBreakActivityExecuteFromPostponeMorningHabit = false
            currentState = ._NOTHING_
            closePupUpBlockIfVisible()
            currentActivityPlaying = nil
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
            getHabitsVcObject().stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            
            isBreakActivityExecuteFromPostponeEveningHabit = false
            currentState = ._NOTHING_
            closePupUpBlockIfVisible()
            currentActivityPlaying = nil
        }else if currentState == ._CUSTOM_ROUTINE_ && (isCustomRoutineWasRunningInPostponeMorningHabit || isCustomRoutineWasRunningInPostponeEveningHabit){
            getHabitsVcObject().stopActivityCountDownTimer()
            if currentHabitPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            
            isCustomRoutineWasRunningInPostponeMorningHabit = false
            isCustomRoutineWasRunningInPostponeEveningHabit = false
            currentState = ._NOTHING_
            closePupUpBlockIfVisible()
            currentActivityPlaying = nil
        }
        
        hideCustomRoutineTimeWindowIfVisible()// hide custom routine coming window if visible
        getHabitsVcObject().stopActivityTimer()
        
        currentState = ._NOTHING_
        leftMenuVcObj?.enableAllItems()
        getHabitsVcObject().stopPostponeEndTimer()
        closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
        appdelegate?.backgroundThread()
        closeMenuWindowIsVisible()
        
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            self.reloadIfNeeded()
        }
    }
    
    @IBAction func btnCurrentTrackClicked(_ sender: Any) {
        isFocusMusicPausedAutomatically = false
        for i in 0..<arrAllTracks.count{
            if arrAllTracks[i]["isPlaying"] as? Bool == true{
                arrAllTracks[i]["isPlaying"] = false
                arrAllTracks[i]["isPaused"] = true
                if allTracksVcObj?.currentSound?.isPlaying ?? false{
                    allTracksVcObj?.currentSound?.pause()
                }
                
                imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPlayTemplateName)

                reloadFocusMusicListIfVisible()
                FocusMusicViewModel.shared.updateNowPlaying()   // keep the hardware media-key state in sync

                return;
            }else if arrAllTracks[i]["isPaused"] as? Bool == true{
                
                arrAllTracks[i]["isPlaying"] = true
                arrAllTracks[i]["isPaused"] = false
                allTracksVcObj?.currentSound?.resume()
                
                imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPauseTemplateName)

                reloadFocusMusicListIfVisible()
                FocusMusicViewModel.shared.updateNowPlaying()   // keep the hardware media-key state in sync
                return;
                
            }
        }
    }
    
    @IBAction func btnStartHabitsFirstTimeClicked(_ sender: Any) {
        addLog(text: "[user-action] button Start Habits First Time Clicked")
        if isShutOffTimeGoing(){
            if arrAllDaysEveningHabits.count == 0{
                showAlertNoHabits()
                return;
            }
        }else{
            if arrAllDaysMorningHabits.count == 0{
                showAlertNoHabits()
                return;
            }
        }
        
        UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
        UserDefaults.standard.set(Date.yesterday, forKey: kUserDefaultsFirstAppFullLoadDate)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitShowDate)
        isHabitAlreadyShowed = false
        appdelegate?.backgroundThread()
        closeMenuWindowIsVisible()
    }
    
    
    func showAlertNoHabits(){
        addLog(text: "show Alert No Habits")
        let alert = NSAlert()
        alert.setSharingType()
        var title = "There are no habits set for your account. Do you want to set habits now?"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            title = menuInfo.value(forKey: "alertNoHabitsFound") as? String ?? title
        }
        alert.messageText = title
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        let result = alert.runModal()
        if result == .alertFirstButtonReturn{

            if mainWindowControllerObj?.window?.isVisible ?? false{
                leftMenuVcObj?.showEditHabitsView()
            }else{
                mainWindowControllerObj?.showWindow(self)
                leftMenuVcObj?.showEditHabitsView()
            }
            closeMenuWindowIsVisible()
            addLog(text: "Showing preferences")
        }
    }
    
    @IBAction func btnInfoBlockingDisabledClicked(_ sender: hoverInfoButton) {
        var msg = "Blocking is off because no custom blocking schedules have been added."
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            msg = menuInfo.value(forKey: "addBlockingScheduleInfo") as? String ?? msg
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnPinClicked(_ sender: Any) {
        if SettingsManagerObject.isMenuPopoverEnabled{
            disableMenuPopover()
        }else{
            enableMenuPopover()
        }
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
    
    @IBAction func btnEditBlockingScheduleClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnEditBlockingScheduleClicked")
        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            showUpgradeNowWindow(reason: "edit_blocking_schedule_expired")
            return;
        }
        
        closePopoverTooltipIfVisible()
        
        if mainWindowControllerObj?.window?.isVisible ?? false{
            leftMenuVcObj?.showBlocksView()
        }else{
            mainWindowControllerObj?.showWindow(self)
            leftMenuVcObj?.showBlocksView()
        }
        addLog(text: "Showing preferences")
        tabStrictnessContainerVcObj?.showCustomBlockingSchedulesView()////now super distarcting sites will block only in focus modes and custom blocking schedules  24/9/25 version 2.27.417
        // Focus Bear is a menu-bar (accessory) app, so showWindow alone leaves the window behind other
        // apps. Activate so it actually comes to the foreground (same as openDayPlanSchedule()).
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnSetPermissionsClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnSetPermissionsClicked")// 23/7/25  v 1.26.393
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }else if !browserPermissionGiven{
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }else if !accessibilityPermissionGiven{
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }else if !systemEventsPermissionGiven{
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnCustomRoutineClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnCustomRoutineClicked")
        customRoutinesMenu.minimumWidth = btnCustomRoutine.frame.width
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y )
        customRoutinesMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
    
    @IBAction func btnBrowserTabAuditClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnBrowserTabAuditClicked")
        showBrowsersTabAuditView()
    }
    
    @IBAction func btnCustomBlockingClicked(_ sender: Any) {
        if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            for i in 0..<customBlockingScheduleManagerObj.arrBlockingSchedule.count{
                if customBlockingScheduleManagerObj.arrBlockingSchedule[i].state == .on{
                    if customBlockingScheduleManagerObj.arrBlockingSchedule[i].blockLevel == ._STRICT_{
                        
                        if mainWindowControllerObj?.window?.isVisible ?? false{
                            leftMenuVcObj?.showCustomScheduleAbortedView()
                        }else{
                            mainWindowControllerObj?.showWindow(self)
                            leftMenuVcObj?.showCustomScheduleAbortedView()
                        }
                        btnCustomBlocking.state = .on
                    }else if customBlockingScheduleManagerObj.arrBlockingSchedule[i].blockLevel == ._SUPER_STRICT_{
                        
                        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                            if let lastUnlockTimeByAccountabilityBuddy = lastUnlockTimeByAccountabilityBuddy{// if no password is set  then chance of getting lastUnlockTimeByAccountabilityBuddy is 0% but if password is set then check this
                                if Date() < lastUnlockTimeByAccountabilityBuddy{
                                    customBlockingScheduleManagerObj.customBlockingSchedulePaused()
                                    return;
                                }
                            }
                        }
                        showPasswordWindow()// show without checking . if password not there then show enter random characters view
                        btnCustomBlocking.state = .on
                    }else{
                        customBlockingScheduleManagerObj.customBlockingSchedulePaused()
                    }
                    break;
                }
            }
        }else{
            for i in 0..<customBlockingScheduleManagerObj.arrBlockingSchedule.count{
                if customBlockingScheduleManagerObj.arrBlockingSchedule[i].state == .pause{
                    customBlockingScheduleManagerObj.startCustomBlockingSchedule(index: i)
                    break;
                }
            }
        }
    }
    
    @IBAction func btnEditHabitsClicked(_ sender: Any) {// v 2.28.454
        addLog(text:"[user-action] menuViewController:- btnEditHabitsClicked")
        if !(mainWindowControllerObj?.window?.isVisible ?? false){
            mainWindowControllerObj?.showWindow(self)
        }
        leftMenuVcObj?.showEditHabitsView()
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
        closeMenuWindowIsVisible()
    }

    /// "View full day plan" from the menu — opens the Habits / Day-Plan schedule timeline
    /// (NOT the Preferences habit editor that btnEditHabitsClicked opens).
    func openDayPlanSchedule() {
        if !(mainWindowControllerObj?.window?.isVisible ?? false){
            mainWindowControllerObj?.showWindow(self)
        }
        // Select the sidebar's Day Plan row. The sidebar path gets this from the user's click; opening
        // from the menu is programmatic, so without it the Day Plan showed with no tab selected. The
        // setter deselects the other rows itself, and only fires the window-sizing delegate — not the
        // by-user handler — so it doesn't re-enter the dispatch below.
        leftMenuVcObj?.boxHabits.isSelected = true
        // Populate the habits area with the Day Plan for the current state — the SAME dispatch the
        // sidebar's boxHabits selection uses. Without this the menu path left the habits area blank on
        // first open in the postpone states until a break-then-back happened to trigger it.
        leftMenuVcObj?.showDayPlanForCurrentState()
        // Safety net for the active routine states (which the dispatch above intentionally leaves
        // alone): if a "Start Micro Break" left the break view up there, restore the Day Plan.
        if getHabitsVcObject().habitsView.subviews.contains(getBreaksStateVcObject().view) {
            getHabitsVcObject().showHabitState()
        }
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
        closeMenuWindowIsVisible()
    }
    
    
    
    @IBAction func btnSetBlockingScheduleFirstTimeClicked(_ sender: Any) {
        btnEditBlockingScheduleClicked(self)
        boxBlockingDisabledFirstTime.isHidden = true
        boxBlockingDisabled.isHidden = false
        lblTitleBreakStatus.isHidden = true
        // Deliberately do NOT set kUserDefaultsBlockingScheduleAddedFirstTime here. This only opens the
        // blocking-schedule editor — the user hasn't set anything up yet. Setting the flag here cleared
        // the "set up blocking" card/banner in the new menu the moment it was clicked. The flag (which
        // hides the card — see reloadData / showBlockingBanner) is set only when blocking is actually
        // dismissed (onDismissBlocking) or the user picks "later" (btnSetLaterBlockingScheduleFirstTimeClicked);
        // once a schedule actually exists the card is hidden by the arrBlockingSchedule count check anyway.
    }
    
    
    @IBAction func btnSetLaterBlockingScheduleFirstTimeClicked(_ sender: Any) {
        boxBlockingDisabledFirstTime.isHidden = true
        boxBlockingDisabled.isHidden = false
        UserDefaults.standard.set(true, forKey: kUserDefaultsBlockingScheduleAddedFirstTime)
        lblTitleBreakStatus.isHidden = true
    }
    
    
}


// Helper: Expand/Collapse all sections
extension menuViewController{
    @IBAction func btnDropDownFocusClicked(_ sender: Any) {
        if boxFocusInfo.isHidden{
            expandFocusInfo()
        }else{
            collapseFocusInfo()
        }
    }
    
    @IBAction func btnDropDownBreakClicked(_ sender: Any) {
        if boxBreaksInfo.isHidden{
            expandBreakInfo()
        }else{
            collapseBreakInfo()
        }
    }
    
    @IBAction func btnDropDownHabitClicked(_ sender: Any) {
        if boxHabitsInfo.isHidden{
            expandHabitInfo()
        }else{
            collapseHabitInfo()
        }
    }
    
    func expandFocusInfo(){
        boxFocusInfo.isHidden = false
        btnDropDownFocus.image = imageExpanded
        
        collapseBreakInfo()
        collapseHabitInfo()
        boxLblTitleFocusStatus.isHidden = true
    }
    
    func collapseFocusInfo(){
        boxFocusInfo.isHidden = true
        btnDropDownFocus.image = imageCollapsed
        if boxBlockingDisabled.isHidden && boxFocusInfo.isHidden && isFocusModeRunning{
            boxLblTitleFocusStatus.isHidden = false
        }else{
            boxLblTitleFocusStatus.isHidden = true
        }
    }
    
    func expandBreakInfo(){
        lblTitleBreakStatus.isHidden = true
        boxBreaksInfo.isHidden = false
        btnDropDownBreak.image = imageExpanded
        collapseHabitInfo()
        collapseFocusInfo()
    }
    
    func collapseBreakInfo(){
        boxBreaksInfo.isHidden = true
        btnDropDownBreak.image = imageCollapsed
        if !lblNextBreakTime.stringValue.isEmpty && boxBreaksInfo.isHidden && !boxNextBreak.isHidden{
            lblTitleBreakStatus.isHidden = false
            lblTitleBreakStatus.stringValue = lblNextBreakTime.stringValue
        }else{
            lblTitleBreakStatus.isHidden = true
        }
    }
    
    func expandHabitInfo(){
        boxHabitsInfo.isHidden = false
        btnDropDownHabit.image = imageExpanded
        collapseBreakInfo()
        collapseFocusInfo()
    }
    
    func collapseHabitInfo(){
        boxHabitsInfo.isHidden = true
        btnDropDownHabit.image = imageCollapsed
    }
}

// MARK: - SwiftUI menu hosting (redesign)

@available(macOS 11.0, *)
extension menuViewController {

    private var menuModel: MenuModel? { menuModelRef as? MenuModel }

    /// Overlay the SwiftUI menu on top of the storyboard content. The storyboard views stay
    /// loaded (and keep updating in the background) but are hidden behind the opaque host.
    func setupSwiftUIMenu() {
        let model = MenuModel()
        wireMenuModel(model)
        observeVoiceEvents(model)
        menuModelRef = model

        // The SwiftUI view reports its own height; we resize the popover to match so nothing clips
        // (incl. when an accordion expands). Pin the host to all four edges and let the reported
        // height drive the popover/window content size.
        let root = FocusBearMenuView(model: model, onHeight: { [weak self] h in self?.applyMenuHeight(h) })
        let host = NSHostingView(rootView: root)
        host.translatesAutoresizingMaskIntoConstraints = false
        for sub in view.subviews { sub.isHidden = true }
        // Drop the storyboard's view-level constraints so the (hidden) storyboard subviews no longer
        // force the view tall; the host fills the view and the SwiftUI content top-aligns within it.
        NSLayoutConstraint.deactivate(view.constraints)
        view.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.topAnchor.constraint(equalTo: view.topAnchor),
            host.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        menuHostingView = host
        // Only populate live (label-backed) fields at load time. The Day Plan summary calls
        // getNextRoutineInfo()/DayPlanTaskStore, which aren't safe this early in app startup
        // (viewDidLoad can run during focus-mode resume before routine data is loaded). The full
        // refresh — including the Day Plan — runs in viewWillAppear, when the menu is actually shown.
        updateLiveMenuFields(model)
        model.micAvailable = isPurchased || daysLeft > 0
    }

    private var menuWidth: CGFloat { FocusBearMenuView.width }

    /// Resize the popover/window to the height the SwiftUI view reports (also on accordion expand).
    func applyMenuHeight(_ height: CGFloat) {
        let size = NSSize(width: menuWidth, height: max(height.rounded(.up), 120))
        preferredContentSize = size
        // Popover path: setting contentSize re-anchors + grows the popover automatically.
        appdelegate?.popover.contentSize = size
        // Window path: resize and keep the top edge pinned under the status bar.
        if let win = view.window {
            let topLeft = NSPoint(x: win.frame.minX, y: win.frame.maxY)
            win.setContentSize(size)
            win.setFrameTopLeftPoint(topLeft)
        }
    }

    func wireMenuModel(_ model: MenuModel) {
        model.onStartFocus = { [weak self] in
            guard let self = self else { return }
            if SettingsManagerObject.isGeekModeEnabled {
                appdelegate?.menuShowPomodoroModeView()
            } else {
                appdelegate?.menuShowSimplePomodoroModeView()
            }
            closeMenuWindowIsVisible()
        }
        // Inline quick-start: begin a focus session directly with the chosen minutes/intention/block list.
        model.onStartFocusConfigured = { [weak self] minutes, intention, blockListId in
            guard let self = self else { return }
            let id = blockListId.isEmpty ? (model.focusBlockLists.first?.id ?? "") : blockListId
            appdelegate?.startFocusFromMenu(focusModeId: id, minutes: minutes, intention: intention)
            closeMenuWindowIsVisible()
        }
        model.onMic            = {
            // Same flow as the Focus Button microphone (LISTEN|START → recorder). Keep the popover
            // open so the voice UI stays visible while recording.
            recorder.requestPermissionAndStartRecording()
        }
        model.onStopRecording  = { recorder.stopRecording() }
        model.onCancelRecording = { recorder.cancelRecording() }
        model.onOpenMicSettings = {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
        model.onShowStats      = { [weak self] in self?.btnPreferencesClicked(self as Any) }
        model.onUpgrade        = { showUpgradeNowWindow(reason: "menu_subscription_status") }   // #2081
        model.onStopFocus      = { [weak self] in self?.stopFocusMode() }
        // #2148: restore Pause/Resume. These route through the same handlers the legacy Stop-Focus
        // popup menu used, so strictness / teacher-session / password checks are preserved.
        model.onPauseFocus     = { [weak self] in self?.pauseFocusModeClicked() }
        model.onResumeFocus    = { [weak self] in self?.resumeFocusMode() }
        model.onTogglePin      = { [weak self] in self?.btnPinClicked(self as Any) }   // popover <-> window
        model.onOpenBreaks     = { [weak self] in self?.btnStartBreakClicked(self as Any) }
        model.onOpenDayPlan    = { [weak self] in self?.openDayPlanSchedule() }
        model.onOpenFocusMusic = { [weak self] in self?.btnFocusMusicClicked(self as Any) }
        model.onToggleMusic    = { [weak self] in
            // A built-in track (in arrAllTracks) uses the local play/pause. Otherwise toggle the
            // Spotify / YouTube-Music track that FocusMusicViewModel is playing.
            let localActive = arrAllTracks.contains {
                ($0["isPlaying"] as? Bool == true) || ($0["isPaused"] as? Bool == true)
            }
            if localActive { self?.btnCurrentTrackClicked(self as Any); return }
            switch FocusMusicViewModel.shared.nowPlaying?.source {
            case .spotify(let track): FocusMusicViewModel.shared.toggleSpotifyTrack(track)
            // YouTube pauses/resumes in place (matches the hardware media key) rather than stopping.
            case .youtube: FocusMusicViewModel.shared.toggleYouTubePlayPause()
            default: self?.btnCurrentTrackClicked(self as Any)
            }
        }
        model.onToggleTask     = { [weak self] id in
            guard var t = DayPlanTaskStore.shared.tasks(for: Date()).first(where: { $0.id == id }) else { return }
            t.done.toggle()
            DayPlanTaskStore.shared.update(t, for: Date())
            self?.refreshSwiftUIMenu()
        }
        model.onStartNextHabit = { [weak self] in self?.startNextDayPlanHabit() }
        model.onSetUpBlocking  = { [weak self] in self?.btnSetBlockingScheduleFirstTimeClicked(self as Any) }
        model.onDismissBlocking = { UserDefaults.standard.set(true, forKey: kUserDefaultsBlockingScheduleAddedFirstTime) }
        model.onToggleBlockingSchedule = { [weak self] in self?.btnCustomBlockingClicked(self as Any) }
        model.onOpenBlockingScheduleConfig = { [weak self] in self?.btnEditBlockingScheduleClicked(self as Any) }
        model.onSaveIntention = { [weak self] newIntention in
            // Persist via the canonical setter (updates whatToAchieveInFocusBlock + resets the
            // convince-AI caches), then refresh the legacy label that feeds the menu and the in-focus
            // to-do player — mirrors editing the intention from the focus screen.
            updateFocusModeIntention(intention: newIntention)
            self?.lblFocusModeIntention?.stringValue = newIntention
            taskPlayerVcObj?.updateIntentionToPlayer()
        }
        // Forward Skip / Postpone to the exact handlers the floating timer popup (smallCountDownVc)
        // uses, so the menu's habit card behaves identically to it. The habit card only shows in the
        // same routine-in-progress states (_MORNING_/_EVENING_HABIT_/_CUSTOM_ROUTINE_ + _INPROGRESS_)
        // that those handlers' first branch acts on, so this is state-consistent. Forwarding (rather
        // than re-implementing) also picks up the pause + isLastActivityStopped bookkeeping and the
        // navigation back to the habits view that the previous menu handlers were missing.
        model.onSkipHabit      = {
            getsmallCountDownVcObject().btnSkipClicked(NSNull())
            closeMenuWindowIsVisible()
        }
        model.onPostponeHabit  = {
            getsmallCountDownVcObject().btnPostponeClicked(NSNull())
            closeMenuWindowIsVisible()
        }
        model.onOpenBrainDump  = { [weak self] in self?.btnBrainDumpClicked(self as Any) }
        model.onOpenToDoPlayer = { [weak self] in self?.btnToDoPlayerClicked(self as Any) }
        model.onPreferences    = { [weak self] in self?.btnPreferencesClicked(self as Any) }
        model.onQuit           = { [weak self] in self?.btnQuitClicked(self as Any) }
    }

    /// Pull the latest values out of the (hidden) storyboard labels / app state into the model.
    /// Observe recorder notifications so the voice screen can show progress + results.
    private func observeVoiceEvents(_ model: MenuModel) {
        let nc = NotificationCenter.default
        nc.addObserver(forName: VoiceEvents.permissionDenied, object: nil, queue: .main) { _ in
            model.voicePermissionDenied = true
        }
        nc.addObserver(forName: VoiceEvents.processing, object: nil, queue: .main) { _ in
            model.voiceStatus = .processing
            // Safety net: if transcription/intent never returns, don't hang on "Thinking…".
            DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
                if model.voiceStatus == .processing {
                    model.voiceResult = "Timed out. Please try again."
                    model.voiceStatus = .error
                }
            }
        }
        nc.addObserver(forName: VoiceEvents.transcript, object: nil, queue: .main) { note in
            model.voiceTranscript = note.userInfo?["text"] as? String ?? ""
        }
        nc.addObserver(forName: VoiceEvents.actionDone, object: nil, queue: .main) { note in
            model.voiceResult = note.userInfo?["text"] as? String ?? "Done"
            model.voiceStatus = .done
        }
        nc.addObserver(forName: VoiceEvents.error, object: nil, queue: .main) { note in
            model.voiceResult = note.userInfo?["text"] as? String ?? "Something went wrong"
            model.voiceStatus = .error
        }
        nc.addObserver(forName: VoiceEvents.deviceListening, object: nil, queue: .main) { [weak self] _ in
            // The Focus Button mic started a recording with the menu closed — open the popover and
            // land on the voice screen so the user can watch the transcript/result. The recorder starts
            // async (permission + start), so it may not be isRecording yet when the popover appears and
            // refreshSwiftUIMenu() runs during viewWillAppear — set a one-shot flag it honours, else that
            // refresh resets inVoiceMode and the menu opens but never enters listening state.
            self?.pendingDeviceListening = true
            if !isFocusBearMenuVisible() {
                appdelegate?.showPopover()
            }
            model.inVoiceMode = true
            model.voiceStatus = .listening
            model.voiceTranscript = ""
            model.voiceResult = ""
        }
    }

    /// Full refresh (on menu open): live fields + mic gate + day-plan summary.
    func refreshSwiftUIMenu() {
        guard let model = menuModel else { return }
        if recorder.isRecording || pendingDeviceListening {
            // A recording is in progress — or a device-mic one is just starting (pendingDeviceListening,
            // set before the recorder flips isRecording) — land on the voice screen so the capture is
            // visible, instead of resetting to the menu. One-shot: consume the flag.
            pendingDeviceListening = false
            model.inVoiceMode = true
            model.voiceStatus = .listening
        } else {
            model.inVoiceMode = false   // opening the menu always starts on the menu, never a stale voice screen
        }
        updateLiveMenuFields(model)
        model.micAvailable = isPurchased || daysLeft > 0
        // Show the "set up distraction blocking" card only when there's no schedule AND the user
        // hasn't already set one up or dismissed the card (persisted via the first-time flag) — so
        // "Remove" sticks across restarts.
        model.showBlockingBanner = customBlockingScheduleManagerObj.arrBlockingSchedule.count == 0
            && UserDefaults.standard.object(forKey: kUserDefaultsBlockingScheduleAddedFirstTime) == nil
        // (Active blocking-schedule card is populated in updateLiveMenuFields so it refreshes every tick.)
        updateDayPlan(model)
    }

    /// Time-sensitive fields, refreshed every second while the menu is open (timer counts down,
    /// "last break" grows, music play/pause state, etc.).
    func tickMenu() {
        guard let model = menuModel else { return }
        // Don't churn the model while the voice screen is up — its updates can disrupt that view.
        if model.inVoiceMode { return }
        updateLiveMenuFields(model)
    }

    /// Live break subtitle for the SwiftUI menu. Returns the disable reason when breaks are currently
    /// off (micro-breaks turned off, disabled-for-today, focus/super-focus session, an active blocking
    /// schedule with skip-micro-breaks, a habit in progress, or a postponed routine), the
    /// "Next break in: X" countdown when they're on, or nil to fall back to "Take a mindful break".
    /// Mirrors the legacy gate in reloadData() but is evaluated fresh every tick so it never goes stale.
    private func breakSubtitleForMenu() -> String? {
        var isBreakEnabled = SettingsManagerObject.isMicroBreaksEnabled
        var reason = microBreaksTurnedOff

        if let d = UserDefaults.standard.object(forKey: kUserdefaultsDisableBreaksForToday) as? Date,
           Calendar.current.isDateInToday(d) {
            isBreakEnabled = false; reason = microBreaksDisabledForToday
        }

        guard let timer = getHabitsVcObject().breakTimer else { return isBreakEnabled ? nil : reason }

        if isBreakEnabled {
            if isFocusModeRunning && isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro {
                isBreakEnabled = false; reason = breaksDisabledFocusSessionRunning
            } else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro {
                isBreakEnabled = false; reason = breaksDisabledSuperFocusSessionRunning
            } else if customBlockingScheduleManagerObj.isAnyCustomScheduleOn {
                if !customBlockingScheduleManagerObj.isMicroBreaksEnabled() {
                    isBreakEnabled = false; reason = breaksDisabledBlockingScheduleActive
                }
            } else if currentState == ._CUSTOM_ROUTINE_ || currentState == ._SPECIAL_ACTIVITY_ {
                isBreakEnabled = false; reason = breaksDisabledHabitInProgress
            } else if currentState == ._POSTPONE_FOCUS_SUMMARY_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_ {
                if !SettingsManagerObject.IsShowBreaksInPostponeEnabled {
                    isBreakEnabled = false; reason = breaksDisabledRoutinePostponed
                }
            }
        }

        if !isBreakEnabled { return reason }
        guard timer.isValid else { return nil }

        let now = Date()
        let diffMinute = Calendar.current.dateComponents([.minute], from: now, to: timer.fireDate).minute ?? 0
        if diffMinute < 1 {
            let diffSeconds = Calendar.current.dateComponents([.second], from: now, to: timer.fireDate).second ?? 0
            if diffSeconds < 5 {
                var waiting = "It's time for a break. Waiting for a good moment"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary {
                    waiting = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? waiting
                }
                return waiting
            }
        }
        let timeText = diffMinute < 1 ? "< 1 \(minuteText)" : "\(diffMinute) \(minutesText)"
        var nextBreakText = "Next break in: <DURATION>"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary {
            nextBreakText = menuInfo.value(forKey: "nextBreakText") as? String ?? nextBreakText
        }
        return nextBreakText.replacingOccurrences(of: "<DURATION>", with: timeText)
    }

    private func updateLiveMenuFields(_ model: MenuModel) {
        // Reflect the current menu presentation so the header's pin icon matches reality
        // (window/pinned vs popover). The pin button toggles between the two via btnPinClicked.
        model.menuPinnedAsWindow = !SettingsManagerObject.isMenuPopoverEnabled

        // #2081: trial / expired subscription status. Computed here (a live field) so a mid-session change
        // to isPurchased/daysLeft anywhere in the app — e.g. a purchase completing — hides/updates the
        // banner within ~1s while the menu is open, not only on the next menu-open. Mirrors the old menu's
        // checkPurchaseState(): paid → nothing (banner hidden); trial → days remaining; else → expired.
        if isPurchased {
            model.subscriptionStatus = ""
            model.subscriptionExpired = false
        } else if daysLeft <= 0 {
            model.subscriptionStatus = subscriptionExpiredText
            model.subscriptionExpired = true
        } else {
            model.subscriptionStatus = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysLeft)")
            model.subscriptionExpired = false
        }

        let running = isFocusModeOnOrPaused()
        model.focusRunning     = running
        model.focusPaused      = isFocusModePaused()
        // Only timed sessions can be paused (matches the legacy `timerForFocusMode != nil` gate). #2148
        model.focusPausable    = (timerForFocusMode != nil)
        model.focusRemaining   = formatFocusRemaining(lblTimerFocusMode?.stringValue ?? "")
        model.focusedTodayText = lblTotalFocusedTimeToday?.stringValue ?? ""
        model.focusTaskTitle   = lblFocusModeIntention?.stringValue ?? ""

        // Inline focus-starter: offer the available block lists (focus modes) and default the duration
        // to the last session's. Only sync the duration/selection while the card is collapsed so a
        // live refresh doesn't wipe an in-progress customisation.
        // The focus modes may not be loaded into the global yet (that normally happens when the
        // pomodoro screen appears), so fall back to UserDefaults — otherwise the dropdown is empty.
        var focusTypes = arrFocusType
        if focusTypes.isEmpty {
            focusTypes = (UserDefaults.standard.object(forKey: kUserdefaultsArrFocusTypes) as? [[String: Any]]) ?? []
        }
        model.focusBlockLists = focusTypes.compactMap { ft in
            guard let id = ft["id"] as? String, let name = ft["name"] as? String, !name.isEmpty else { return nil }
            return MenuBlockList(id: id, name: name)
        }
        if !model.focusStarterExpanded {
            if model.selectedBlockListId.isEmpty || !model.focusBlockLists.contains(where: { $0.id == model.selectedBlockListId }) {
                let lastId = UserDefaults.standard.string(forKey: kUserdefaultsLastFocusModeId) ?? ""
                let defaultId = focusTypes.first(where: { ($0["isDefault"] as? Bool) == true })?["id"] as? String ?? ""
                model.selectedBlockListId = model.focusBlockLists.first(where: { $0.id == lastId })?.id
                    ?? model.focusBlockLists.first(where: { $0.id == defaultId })?.id
                    ?? model.focusBlockLists.first?.id ?? ""
            }
            let lastMinutes = UserDefaults.standard.integer(forKey: kUserdefaultsLastFocusModeMinutes)
            if lastMinutes > 0 { model.focusMinutes = min(180, max(5, lastMinutes)) }
        }
        // The focus-alignment score only exists when AI blocking is on. The storyboard label is just
        // a cache that the gated reloadData() paths refresh; it's never cleared when AI is off, so it
        // retains a previous session's score (or its "xx…" placeholder). Gate on AI here — matching
        // the boxFocusAlignmentScore gating — so a no-AI focus session doesn't surface a stale score.
        let onTask = lblFocusAlignmentScore?.stringValue ?? ""
        let aiScoreAvailable = SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn()
        model.focusOnTaskText  = (running && aiScoreAvailable && !onTask.isEmpty) ? onTask : ""

        // Breaks: normally subtitle = "next break in"; but during an allowed-app habit (breaks are
        // paused) show "last break X ago" instead. The body shows the other one.
        // Compute the break subtitle LIVE each tick (don't read the legacy lblNextBreakTime label —
        // it's only refreshed inside reloadData(), so between reloads it goes stale and showed a
        // "next break in X" countdown even while breaks were actually disabled by an active blocking
        // schedule). This evaluates the same disable gate fresh, so the subtitle correctly reads e.g.
        // "Blocking schedule is active. Breaks disabled." the moment that schedule is on.
        let nextBreak = breakSubtitleForMenu() ?? ""
        var lastBreakStr = ""
        if let lastBreak = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakEndTime) as? Date {
            let secs = max(0, Int(Date().timeIntervalSince(lastBreak)))
            lastBreakStr = menuLocalized("menuLastBreak", "Last break") + " " + getStringTimeFromSecondsWithoutSeconds(seconds: secs) + " " + menuLocalized("menuAgo", "ago")
        }
        let takeBreak = menuLocalized("menuTakeBreak", "Take a mindful break")
        if isAnyAllowedFocusModeActivityRunning {
            model.breaksSummary = lastBreakStr.isEmpty ? takeBreak : lastBreakStr
            model.lastBreakText = ""
        } else {
            model.breaksSummary = nextBreak.isEmpty ? takeBreak : nextBreak
            model.lastBreakText = lastBreakStr
        }

        // Active blocking-schedule card — refreshed every tick so it appears/updates as soon as a
        // schedule turns on (or is loaded after the menu opened), not just on the initial open.
        let blockingMgr = customBlockingScheduleManagerObj
        if blockingMgr.isAnyCustomScheduleOn, let s = blockingMgr.arrBlockingSchedule.first(where: { $0.state == .on }) {
            model.blockingScheduleActive = true
            model.blockingSchedulePaused = false
            model.blockingScheduleName = s.name
            model.blockingScheduleTime = s.displayString
        } else if blockingMgr.isAnyCustomSchedulePaused, let s = blockingMgr.arrBlockingSchedule.first(where: { $0.state == .pause }) {
            model.blockingScheduleActive = true
            model.blockingSchedulePaused = true
            model.blockingScheduleName = s.name
            model.blockingScheduleTime = s.displayString
        } else {
            model.blockingScheduleActive = false
        }

        // Focus music: current track name + playing/paused state (drives the play/pause control).
        // Built-in tracks live in arrAllTracks; Spotify / YouTube-Music tracks are stored separately and
        // only surface through FocusMusicViewModel.nowPlaying — so fall back to that when no local track
        // is active, otherwise the menu can't see (or pause) a playing YouTube/Spotify track.
        var trackName = ""
        var playing = false
        for t in arrAllTracks {
            if t["isPlaying"] as? Bool == true { trackName = t["name"] as? String ?? ""; playing = true; break }
            if t["isPaused"] as? Bool == true { trackName = t["name"] as? String ?? ""; playing = false }
        }
        if trackName.isEmpty, let np = FocusMusicViewModel.shared.nowPlaying {
            switch np.source {
            case .spotify:
                trackName = np.title
                playing = true   // Spotify exposes play/stop, not a paused state — treat as playing.
            case .youtube:
                trackName = np.title
                playing = !FocusMusicViewModel.shared.youtubePaused   // YouTube can be paused in place.
            case .local:
                break            // handled by the arrAllTracks scan above
            }
        }
        model.musicTrackName = trackName
        model.musicPlaying = playing

        // Currently-playing habit → show the habit card (name + live timer + Skip/Postpone)
        // instead of the Start Focus button.
        let habitInProgress = currentHabitPlaying != nil
            && (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_)
            && currentAction == ._INPROGRESS_
        model.habitPlaying = habitInProgress
        if habitInProgress {
            model.habitName = currentHabitPlaying?.name ?? ""
            let requirement = (currentHabitPlaying?.completion_requirements ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if requirement.isEmpty {
                // Timer-based habit → live countdown.
                model.habitTimer = timerViewcontrollerObj?.lblTimer?.stringValue ?? ""
                model.habitCompletionRequirement = ""
            } else {
                // Non-timer habit → show the completion requirement instead of the 24h fallback timer.
                model.habitTimer = ""
                model.habitCompletionRequirement = requirement
            }
        } else {
            model.habitCompletionRequirement = ""
        }
    }

    /// Day Plan: next uncompleted habit in the active routine; if that routine is done, the next
    /// routine's start time; plus today's top undone tasks.
    private func updateDayPlan(_ model: MenuModel) {
        let activeHabits: [habit]
        let isMorningRoutine: Bool
        switch currentState {
        case ._EVENING_HABIT_, ._POSTPONE_EVENING_HABIT_:
            activeHabits = arrFilteredEveningHabits
            isMorningRoutine = false
        case ._CUSTOM_ROUTINE_:
            activeHabits = currentRoutineIndex < arrAllCustomRoutine.count
                ? arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits : []
            isMorningRoutine = false
        default:
            activeHabits = arrFilteredMorningHabits
            isMorningRoutine = true
        }
        let playingId = currentHabitPlaying?.id ?? ""
        // #2013: once the morning routine is done (before shutoff) and we're no longer in it, don't
        // surface a leftover "next" morning habit. Some completed habits may not be in
        // dayPlanCompletedHabitIds yet (e.g. before the #2150 refetch), so the first-not-completed check
        // would otherwise pick one. Same isHabitAlreadyShowed signal the Day Plan uses; the if/else below
        // then shows the next routine's start ("Evening routine starts at …") instead.
        let morningRoutineDone = isMorningRoutine && isHabitAlreadyShowed && !isShutOffTimeGoing()
            && currentState != ._MORNING_HABIT_ && currentState != ._POSTPONE_MORNING_HABIT_
        let nextHabit = morningRoutineDone ? nil : activeHabits.first { h in
            let id = h.id ?? ""
            return id != playingId && !dayPlanCompletedHabitIds.contains(id)
        }
        if let nh = nextHabit {
            model.dayPlanNextHabit = nh.nameWithoutIcon.isEmpty ? (nh.name ?? "") : nh.nameWithoutIcon
            nextDayPlanHabitName = nh.name
        } else if shutOffTime != nil {
            nextDayPlanHabitName = nil
            // All habits in the current routine are done — show the next routine's start.
            // (getNextRoutineInfo() force-unwraps shutOffTime, so only call it once that's loaded.)
            let (date, name, _) = getNextRoutineInfo()
            model.dayPlanNextHabit = name + " " + menuLocalized("dayPlanStartsAt", "starts at") + " " + menuTimeString(date)
        } else {
            model.dayPlanNextHabit = ""
            nextDayPlanHabitName = nil
        }

        // "Start" next to the next habit only makes sense when habits are postponed (you can resume them).
        model.nextHabitStartable = (currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_)

        // Date subtitle, e.g. "Tuesday, June 25".
        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: currentLanguageCode)
        dateFmt.dateFormat = "EEEE, MMMM d"
        model.dayPlanDate = dateFmt.string(from: Date())

        // Next calendar event (upcoming meeting), if any.
        let now = Date()
        if let nextMeeting = CalendarManager.shared.todaysMeetings()
            .filter({ $0.start > now }).sorted(by: { $0.start < $1.start }).first {
            model.dayPlanNextEventTitle = nextMeeting.title
            model.dayPlanNextEventTime = menuTimeString(nextMeeting.start)
            model.dayPlanNextEventRelative = relativeTimeString(to: nextMeeting.start)
        } else {
            model.dayPlanNextEventTitle = ""
            model.dayPlanNextEventTime = ""
            model.dayPlanNextEventRelative = ""
        }

        // Today's tasks, shown with tickable checkboxes (matches the Day Plan panel's order).
        model.dayPlanTasks = topDayPlanTasks(limit: 4)
    }

    /// The first N "Tasks for today" in the same order the Day Plan side-panel shows them:
    /// not-yet-time-boxed tasks (blockKey == nil), grouped by project in the user's project order,
    /// with no-project tasks last.
    private func topDayPlanTasks(limit: Int) -> [DayPlanMenuTask] {
        // Uncompleted, not-yet-time-boxed tasks only (we don't show completed tasks in the menu).
        let unboxed = DayPlanTaskStore.shared.tasks(for: Date()).filter { $0.blockKey == nil && !$0.done }
        var order: [String] = []
        var groups: [String: [DayPlanTask]] = [:]
        var noProject: [DayPlanTask] = []
        for t in unboxed {
            if let p = t.project, !p.isEmpty {
                if groups[p] == nil { groups[p] = []; order.append(p) }
                groups[p]?.append(t)
            } else {
                noProject.append(t)
            }
        }
        var ordered: [DayPlanTask] = []
        for p in DayPlanTaskStore.shared.orderedProjects(order) { ordered.append(contentsOf: groups[p] ?? []) }
        ordered.append(contentsOf: noProject)
        return ordered.prefix(limit).map { DayPlanMenuTask(id: $0.id, title: $0.title, done: $0.done) }
    }

    /// Reformat a "HH:MM:SS" (or "MM:SS") countdown into "1h 1m 09s" style (seconds always 2 digits).
    private func formatFocusRemaining(_ hms: String) -> String {
        let parts = hms.split(separator: ":").compactMap { Int($0) }
        var h = 0, m = 0, s = 0
        if parts.count == 3 { h = parts[0]; m = parts[1]; s = parts[2] }
        else if parts.count == 2 { m = parts[0]; s = parts[1] }
        else { return hms }
        var out = ""
        if h > 0 { out += "\(h)h " }
        if h > 0 || m > 0 { out += "\(m)m " }
        out += String(format: "%02ds", s)
        return out.trimmingCharacters(in: .whitespaces)
    }

    /// "in 40 min" / "in 1h 5m" until the given date.
    private func relativeTimeString(to date: Date) -> String {
        let mins = max(0, Int(date.timeIntervalSince(Date()) / 60))
        let inWord = menuLocalized("dayPlanIn", "in")
        if mins < 60 { return "\(inWord) \(mins) min" }
        let h = mins / 60, m = mins % 60
        return m > 0 ? "\(inWord) \(h)h \(m)m" : "\(inWord) \(h)h"
    }

    private func menuTimeString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        df.locale = Locale(identifier: currentLanguageCode)
        return df.string(from: date)
    }

    /// Start the Day Plan "next habit" from its play button (mirrors the device-button habit start).
    func startNextDayPlanHabit() {
        guard let name = nextDayPlanHabitName?.lowercased(), !name.isEmpty else {
            btnEditHabitsClicked(self as Any)   // no startable habit — open the full Day Plan instead
            return
        }
        switch currentState {
        case ._MORNING_HABIT_, ._POSTPONE_MORNING_HABIT_:
            getHabitsVcObject().startMorningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
        case ._EVENING_HABIT_, ._POSTPONE_EVENING_HABIT_:
            getHabitsVcObject().startEveningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
        default:
            btnEditHabitsClicked(self as Any)
            return
        }
        closeMenuWindowIsVisible()
    }

    func startMenuRefreshTimer() {
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickMenu()
        }
    }
}










