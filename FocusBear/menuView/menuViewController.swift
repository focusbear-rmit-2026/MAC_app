//
//  menuViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/02/22.

//

import Cocoa

class menuViewController: NSViewController {

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
    @IBOutlet weak var btnRemoveBrainDumpItem: cursorButton!
    
    @IBOutlet weak var lblTimeSinceLastBreak: NSTextField!
    @IBOutlet weak var boxTimeSinceLastBreak: NSBox!
    @IBOutlet weak var btnEditBlockingSchedule: cursorButton!
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
    
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        addLog(text: "menuViewController viewdidload start")
        
        // todo text
        lblFocusedToday.stringValue = "FOCUSED TODAY"
        lblRemaining.stringValue = "remaining" // todo text
        
        lblTotalFocusedTimeToday.stringValue = ""
        
        boxTipPermissions.isHidden = true
        lblTitleBlockingDisabledFirstTime.stringValue = "Get the most out of Focus Bear"
        
        lblDescriptionBlockingDisabledFirstTime.stringValue = "Set up a blocking schedule to automatically block websites and apps during your focus time."
        
        btnSetBlockingScheduleFirstTime.title = "Set Up Blocking"
        btnSetLaterBlockingScheduleFirstTime.title = "I'll do this later"
        lblBlockingDisabled.stringValue = "🚫 No blocking"
        
        btnEditBlockingSchedule.title = "ENABLE"
        
        
        //=====todo text above
        

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

        btnRemoveBrainDumpItem.isHidden = true
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
        
//        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
//            btnSetPermissions.title = simplePomodoroVcInfo.value(forKey: "buttonFixItText") as? String ?? btnSetPermissions.title
//        }
        
//        if let common = configjson.value(forKey: "common") as? NSDictionary{
//            if let focusEndsText = common.value(forKey: "focusEndsText") as? String {
//                lblTitleFocusModeTime.stringValue = focusEndsText + ":"
//            }
//        }
        
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
        
//        menuItemOpenToolbox = NSMenuItem(title: menuItemOpenToolboxTitle, action: #selector(openToolBoxClicked), keyEquivalent: "")
//        menuItemOpenToolbox.target = self
//        toolsMenu.addItem(menuItemOpenToolbox)
        
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
        if !SettingsManagerObject.isGeekModeEnabled{// geek popupbtn is lokking disbaled in simple mode so do this
            self.view.window?.makeKey()
        }
    }
    
    deinit {
        print("MyViewController is deallocated")
    }
    
    @IBAction func btnMeetingDetectionClicked(_ sender: Any) {
        var videoCallText = "Looks like you're in a video call. I won't interrupt you with micro-breaks during the meeting to avoid embarrassing screensharing moments. Enjoy the meeting!"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            videoCallText = common.value(forKey: "notificationVideoCallText") as? String ?? videoCallText
        }
        showTooltip(sender: btnMeetingDetection, msg: videoCallText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnSetFocusModesClicked(_ sender: Any) {
        showSetFocusWindow()
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnFalseDetectionClicked(_ sender: Any) {
//        appdelegate!.popover.close()
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
            showTooltip(sender: btnEditBlockingSchedule, msg: toolTipButtonEditBlockingSchedule, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
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
            if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil && UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                msg = "- Distraction blocking not set and no browser permission granted."
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "distractionsAndpPermissionNotSet") as? String ?? msg
                }
            }else if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil{
                msg = "- Distraction blocking not set"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "distractionsNotSet") as? String ?? msg
                }
            }else if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
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
//        if !boxTipPermissions.isHidden{
//            boxTipPermissions.stopBlinking()
//        }
        
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
//        if !boxTipPermissions.isHidden{
//            boxTipPermissions.startBlinking()
//        }
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
                        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
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
        
        
        //btnEditHabits.borderColor =  boxPreferences.borderColor
        btnEditHabits.borderWidth = btnPreferences.borderWidth
        btnEditHabits.bgColor = btnPreferences.bgColor
        
        //showFocusModeCountDownIfNeeded()
        if SettingsManagerObject.isMenuPopoverEnabled{
            btnPin.image = #imageLiteral(resourceName: "pin")
        }else{
            btnPin.image = #imageLiteral(resourceName: "unPin")
        }
       // boxGeekMode.isHidden = true// 19/7/25 version 1.26.392   #1467
        
//        if SettingsManagerObject.isGeekModeEnabled{
//            if let val = UserDefaults.standard.object(forKey: kUserDefaultsHideAppModeOption) as? Bool{
//                if val{
//                    boxGeekMode.isHidden = true
//                }else{
//                    boxGeekMode.isHidden = false
//                }
//            }else{
//                boxGeekMode.isHidden = false
//            }
//            
//            segmentControlGeekMode.setSelected(true, forSegment: 0)
//            btnRemoveAppModeOption.isHidden = false
//            segmentControlGeekMode.setWidth(126, forSegment: 0)
//            segmentControlGeekMode.setWidth(126, forSegment: 1)
//        }else{
//            boxGeekMode.isHidden = false
//            segmentControlGeekMode.setSelected(true, forSegment: 1)
//            btnRemoveAppModeOption.isHidden = true
//            segmentControlGeekMode.setWidth(132, forSegment: 0)
//            segmentControlGeekMode.setWidth(132, forSegment: 1)
//        }
        
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
//        var shouldShowToolBoxWindow = false
//        if isAnyAllowedFocusModeActivityRunning || isFocusModeOn(){
//            let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
//            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
//            
//            if !isAllowedAllAppsInFocus && allowAppsPath.count != 0{
//                shouldShowToolBoxWindow = true
//            }
//            let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
//            let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
//            
//            if arrAllowedUrlsForFocus.count != 0 && isAllowedListApproachInFocus{//!isAllowedAllUrlsInFocus &&#453
//                shouldShowToolBoxWindow = true
//            }
//        }else if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentHabitPlaying != nil{
//            let allowAppsPath = currentHabitPlaying?.allowApps ?? []
//            if allowAppsPath.count != 0{
//                shouldShowToolBoxWindow = true
//            }
//            let arrAllowedUrlsForFocus = currentHabitPlaying?.allowUrls ?? []
//            
//            if arrAllowedUrlsForFocus.count != 0{
//                shouldShowToolBoxWindow = true
//            }
//        }
//        if shouldShowToolBoxWindow{
//            boxOpenToolBox.isHidden = false
//            menuItemOpenToolbox.isHidden = false
//        }else{
//            boxOpenToolBox.isHidden = true
//            menuItemOpenToolbox.isHidden = true
//        }
        
        
        boxCurrentTrack.isHidden = true
        if allTracksVcObj != nil{
            for i in 0..<arrAllTracks.count{
                if arrAllTracks[i]["isPlaying"] as? Bool == true{
                    lblCurrentTrack.stringValue = arrAllTracks[i]["name"] as? String ?? ""
                    imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                    boxCurrentTrack.isHidden = false
                    break;
                }else if arrAllTracks[i]["isPaused"] as? Bool == true{
                    lblCurrentTrack.stringValue = arrAllTracks[i]["name"] as? String ?? ""
                    imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                    boxCurrentTrack.isHidden = false
                    break;
                }
            }
        }
        
        
        if arrAllTracks.count == 0{
            menuItemFocusMusic.isHidden = true
            boxFocusMusic.isHidden = true
        }else{
            menuItemFocusMusic.isHidden = false
            boxFocusMusic.isHidden = false
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
                        }else if currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_{
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
            
            
            
            if appdelegate!.isUserOnMeeting{
                boxMeetingDetection.isHidden = false
                if SettingsManagerObject.IsShowBreaksInCallEnabled{
                    btnMeetingDetection.isHidden = true
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
//            stackViewFocusMode.isHidden = false
//            resetViewHeight()
//            tblViewFocusMode.reloadData()
//            if SettingsManagerObject.isOfficeModeEnabled{
//                segmentControlOfficeMode.setSelected(true, forSegment: 0)
//            }else{
//                segmentControlOfficeMode.setSelected(true, forSegment: 1)
//            }
           // boxEnableOfficeMode.isHidden = true
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
        

        
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            btnResumeHabits.isHidden = false
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
            btnResumeHabits.isHidden = false
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
            btnResumeHabits.isHidden = false
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit{
            btnResumeHabits.isHidden = false
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
            btnResumeHabits.isHidden = false
        }else{
            btnResumeHabits.isHidden = true
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
                var (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
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
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
            return;
        }
        startCustomRoutine(index: sender.tag, isOnDemand:true)
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnEnterLicenseKeyClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnEnterLicenseKeyClicked")
        showUpgradeNowWindow()
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnPreferencesClicked(_ sender: Any) {
        appdelegate?.menuItem_Preferences()
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnStartBreakClicked(_ sender: Any) {
        addLog(text: "[user-action] button Start Break Clicked")
        if !isMainWindowLoaded{
            mainWindowControllerObj?.loadWindow()
        }
        isBreakActivityExecuteFromPostponeMorningHabit = false
        isBreakActivityExecuteFromPostponeEveningHabit = false
        isBreakActivityExecuteFromPostponeEveningHabit = false
        if currentState == ._POSTPON_MORNING_HABIT_{// ⚠️ do not change current state inside this block
            // new work // 20/04/23
            isBreakActivityExecuteFromPostponeMorningHabit = true//
        }
        
        if currentState == ._POSTPON_EVENING_HABIT_{// ⚠️ do not change current state inside this block
            isBreakActivityExecuteFromPostponeEveningHabit = true
        }
        
        if currentState == ._POSTPON_FOCUS_SUMMARY_{// ⚠️ do not change current state inside this block
            isBreakActivityExecuteFromPostponeEveningHabit = true
        }
        getHabitsVcObject().executeBreakActivities()
        closeMenuWindowIsVisible()
    }
    
    
    @IBAction func btnBrainDumpClicked(_ sender: Any) {
        addLog(text: "[user-action] button Brain Dump Clicked")
        showBrainDumpWindow()
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnToDoPlayerClicked(_ sender: Any) {
        addLog(text: "[user-action] btnToDoPlayerClicked")
        openToDoListClicked()
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnFocusMusicClicked(_ sender: Any) {
        openAllTracksClicked()
        closeMenuWindowIsVisible()
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
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
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
//        if isFocusModeOn{
//            if currentFocusModeStrictness == ._SUPER_STRICT_{
//                addLog(text: "can't stop focus mode in super strict focus mode :- return")
//                var cantStopFocusModeText = "Super strict mode activated: You cannot stop this focus session until it ends."
//                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                    cantStopFocusModeText = menuInfo.value(forKey: "cantStopFocusModeText") as? String ?? cantStopFocusModeText
//                }
//                showTooltip(sender: boxStartSimplePomodoroMode, msg: cantStopFocusModeText, preferredEdge: .minX, maxWidthVal: 250)
//                return;
//            }
//            showAbortingFocusModeVc(forPause: false)
//            closeMenuWindowIsVisible()
//        }else{
//            appdelegate?.menuShowSimplePomodoroModeView()
//            closeMenuWindowIsVisible()
//        }
    }
    
    @IBAction func btnStartPomodoroModeClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnStartPomodoroModeClicked")
        if isPurchased == false && daysLeft <= 0{
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
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
//        if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
//            addLog(text: "focus mode clicked:- focus mode completed Window is visible:- return")
//            return;
//        }
        
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
    
//    @IBAction func btnLockCurrentFocusClicked(_ sender: Any) {
//        for i in 0..<arrFocusType.count{
//            if arrFocusType[i]["isLockedFocus"] as? Bool == true{
//                showStartingFocusMode(focusModeIndex: i, focusType: arrFocusType[i]["name"] as? String ?? "")
//                break;
//            }
//        }
//    }

    
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
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
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
                if isSmallCountDownTimerViewVisible(){
                    if !(smallCountDownVcObj?.isFocusBreak ?? false){
                        smallCountDownVcObj?.closeTimerBox()
                    }
                }
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
        if mainViewControllerObj != nil{
            if getHabitsVcObject().postponeTimer != nil{
                getHabitsVcObject().postponeTimer?.invalidate()
                getHabitsVcObject().postponeTimer = nil
                closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
            }
            if getHabitsVcObject().postponeNotificationTimer != nil{
                getHabitsVcObject().postponeNotificationTimer?.invalidate()
                getHabitsVcObject().postponeNotificationTimer = nil
            }
        }
        
        appdelegate?.backgroundThread()
        closeMenuWindowIsVisible()
        
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
                
                return;
            }else if arrAllTracks[i]["isPaused"] as? Bool == true{
                
                arrAllTracks[i]["isPlaying"] = true
                arrAllTracks[i]["isPaused"] = false
                allTracksVcObj?.currentSound?.resume()
                
                imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                
                reloadFocusMusicListIfVisible()
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
    
//    @IBAction func btnRemoveAppModeOptionClicked(_ sender: Any) {
//        addLog(text: "btnRemoveAppModeOptionClicked")
//        boxGeekMode.isHidden = true
//        UserDefaults.standard.set(true, forKey: kUserDefaultsHideAppModeOption)
//    }
    
    @IBAction func btnRemoveBrainDumpItemClicked(_ sender: Any) { // not in use
//        addLog(text: "btnRemoveBrainDumpItemClicked")
//        boxBrainDump.isHidden = true
//        menuItemBrainDump.isHidden = false
//        UserDefaults.standard.set(true, forKey: kUserDefaultsHideShowBrainDumpOption)
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
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
            return;
        }
        
        
        
        if mainWindowControllerObj?.window?.isVisible ?? false{
            leftMenuVcObj?.showBlocksView()
        }else{
            mainWindowControllerObj?.showWindow(self)
            leftMenuVcObj?.showBlocksView()
        }
        addLog(text: "Showing preferences")
        tabStrictnessContainerVcObj?.showCustomBlockingSchedulesView()////now super distarcting sites will block only in focus modes and custom blocking schedules  24/9/25 version 2.27.417
        closeMenuWindowIsVisible()
    }
    
    @IBAction func btnSetPermissionsClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnSetPermissionsClicked")// 23/7/25  v 1.26.393
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil && UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            showDistractionTypesWindow(showingFromPomodoro: false)
        }else if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil{
            showDistractionTypesWindow(showingFromPomodoro: false)
        }else if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
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
    
    
    
    @IBAction func btnSetBlockingScheduleFirstTimeClicked(_ sender: Any) {
        btnEditBlockingScheduleClicked(self)
        boxBlockingDisabledFirstTime.isHidden = true
        boxBlockingDisabled.isHidden = false
        UserDefaults.standard.set(true, forKey: kUserDefaultsBlockingScheduleAddedFirstTime)
    }
    
    
    @IBAction func btnSetLaterBlockingScheduleFirstTimeClicked(_ sender: Any) {
        boxBlockingDisabledFirstTime.isHidden = true
        boxBlockingDisabled.isHidden = false
        UserDefaults.standard.set(true, forKey: kUserDefaultsBlockingScheduleAddedFirstTime)
    }
    
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
    }
    
    func collapseFocusInfo(){
        boxFocusInfo.isHidden = true
        btnDropDownFocus.image = imageCollapsed
    }
    
    func expandBreakInfo(){
        boxBreaksInfo.isHidden = false
        btnDropDownBreak.image = imageExpanded
        collapseHabitInfo()
        collapseFocusInfo()
    }
    
    func collapseBreakInfo(){
        boxBreaksInfo.isHidden = true
        btnDropDownBreak.image = imageCollapsed
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













