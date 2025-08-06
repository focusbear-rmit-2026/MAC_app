//
//  menuViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/02/22.

//

import Cocoa

class menuViewController: NSViewController {
    
    
    @IBOutlet weak var boxForPermissionToolTip: NSBox!
    @IBOutlet weak var stackViewFirst: NSStackView!
    @IBOutlet weak var lblTitleFocusModeTime: NSTextField!
    @IBOutlet weak var lblTimerFocusMode: NSTextField!
    @IBOutlet weak var boxFocusModeRemainingTime: NSBox!
    @IBOutlet weak var widthImageIconSimplePomodoro: NSLayoutConstraint!
    @IBOutlet weak var btnOpenToolBox: mouseDownEffectButton!
    @IBOutlet weak var btnStartBreak: mouseDownEffectButton!
    @IBOutlet weak var boxOpenToolBox: NSBox!
    @IBOutlet weak var boxStartBreak: NSBox!
    @IBOutlet weak var heightButtonSimplePomodoro: NSLayoutConstraint!
    @IBOutlet weak var btnFocusMusic: mouseDownEffectButton!
    @IBOutlet weak var btnTodoPlayer: mouseDownEffectButton!
    @IBOutlet weak var btnBrainDump: mouseDownEffectButton!
    @IBOutlet weak var btnCurrentTrack: mouseDownEffectButton!
    @IBOutlet weak var lblCustomRoutine: menuItemLabel!
    @IBOutlet weak var boxCustomRoutine: NSBox!
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
    @IBOutlet weak var btnRemoveAppModeOption: cursorButton!
    @IBOutlet weak var lblTitleToDoPlayer: menuItemLabel!
    @IBOutlet weak var boxToDoPlayer: NSBox!
    
    @IBOutlet weak var segmentControlGeekMode: GeekModeSegmentedControl!
    @IBOutlet weak var boxGeekMode: NSBox!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var boxFocusAlignmentScore: NSBox!
    @IBOutlet weak var lblStartHabitsFirstTime: menuItemLabel!
    @IBOutlet weak var boxStartHabitsFirstTime: NSBox!
    @IBOutlet weak var lblNextBreakTime: NSTextField!
    @IBOutlet weak var boxNextBreak: NSBox!
    @IBOutlet weak var lblTitleOpenCheckLists: NSTextField!
    @IBOutlet weak var boxOpenCheckLists: NSBox!
    @IBOutlet weak var lblTitleSetFocus: NSTextField!
    @IBOutlet weak var boxSetFocusModes: NSBox!
    @IBOutlet weak var segmentControlOfficeMode: NSSegmentedControl!
    @IBOutlet weak var imgViewCurrentTrackState: NSImageView!
    @IBOutlet weak var boxCurrentTrack: NSBox!
    @IBOutlet weak var lblCurrentTrack: NSTextField!
    
    @IBOutlet weak var boxResumeHabits: NSBox!
    @IBOutlet weak var lblTitleResumeHabits: NSTextField!
    
    
    @IBOutlet weak var btnFalseDetection: underLineButton!
    @IBOutlet weak var lblMeetingDetection: NSTextField!
    @IBOutlet weak var btnMeetingDetection: NSButton!
    @IBOutlet weak var boxMeetingDetection: NSBox!
    @IBOutlet weak var boxTools: NSBox!
    @IBOutlet weak var lblTitleTools: NSTextField!
    @IBOutlet weak var lblTitleBrainDump: NSTextField!
    @IBOutlet weak var boxBrainDump: NSBox!
    @IBOutlet weak var boxFocusMusic: NSBox!
    @IBOutlet weak var lblTitleFocusMusic: menuItemLabel!
    
    @IBOutlet weak var lblTitleAppName: NSTextField!
    @IBOutlet weak var boxTitle: NSBox!
    @IBOutlet weak var lblTrialVersionInfo: NSTextField!
    @IBOutlet weak var lblTitleReactivate: NSTextField!
    @IBOutlet weak var lblTitleEnterLicenseKey: NSTextField!
    @IBOutlet weak var lblTitlePreferences: NSTextField!
    @IBOutlet weak var lblTitleStartSimplePomodoroMode: NSTextField!
    @IBOutlet weak var lblTitleStartPomodoroMode: NSTextField!
    @IBOutlet weak var lblTitleQuit: NSTextField!
    @IBOutlet weak var lblTitleStopHardcorePomodoroMode: NSTextField!
    @IBOutlet weak var bottomLine: NSBox!
    @IBOutlet weak var boxStartPomodoroMode: NSBox!
    @IBOutlet weak var boxStartSimplePomodoroMode: NSBox!
    @IBOutlet weak var boxQuit: NSBox!
    @IBOutlet weak var boxPreferences: NSBox!
    @IBOutlet weak var boxStopHardcorePomodoroMode: NSBox!
    @IBOutlet weak var boxEnterLicenseKey: NSBox!
    @IBOutlet weak var boxReactivate: NSBox!
    @IBOutlet weak var boxEnableOfficeMode: NSBox!

    @IBOutlet weak var imgViewStopSuperFocusSession: NSImageView!
    @IBOutlet weak var imgViewStartSimpleFocusSession: NSImageView!
    
    
    var segmentOfficeModeTrackingArea: NSTrackingArea?
    var segmentWfhModeTrackingArea: NSTrackingArea?
    var trackingAreaBtnEditBlockingSchedule: NSTrackingArea?
    var btnFocusMusicTrackingArea: NSTrackingArea?
    var btnTodoPlayerTrackingArea: NSTrackingArea?
    var btnBrainDumpTrackingArea: NSTrackingArea?
    var btnCurrentTrackTrackingArea: NSTrackingArea?
    var btnStartBreakTrackingArea: NSTrackingArea?
    var btnOpenToolBoxTrackingArea: NSTrackingArea?
    var boxPermissionTrackingArea: NSTrackingArea?
    
    var trackingAreaBtnPin: NSTrackingArea?
    
    var toolsMenu:NSMenu!
    var customRoutinesMenu:NSMenu!
    
    var onText = "On"
    var untilTimeText = "ends at <TIME>"
    
    var trialExpiredText = "Your trial has expired!"
    var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
    var itemFocusTitle = "Focus"
//    var itemHardcorePomodoroTitle = "Hardcore Pomodoro Mode"
    
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
    var menuItemOpenToolbox: NSMenuItem!
    var menuItemToDoList: NSMenuItem!
    var menuItemBrainDump: NSMenuItem!
    var titleOfficeMode = "Office Mode"
    var titleWFHMode = "WFH Mode"
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        addLog(text: "menuViewController viewdidload start")
        
        
        if #available(macOS 11.0, *) {
            iconPlayFocusSession = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
        } 
        
        segmentControlOfficeMode.selectedSegmentBezelColor = NSColor.systemBlue
        btnRemoveBrainDumpItem.isHidden = true
        lblTitleFocusModeTime.stringValue = "Focus mode ends in:"
        lblCustomRoutine.stringValue = "Start Custom Routine"
        lblTipPermissions.stringValue = "Grant Focus Bear permissions to block."
        btnSetPermissions.title = "Fix it"
        lblBlockingDisabled.stringValue = "Limited blocking"
        lblStartHabitsFirstTime.stringValue = "Start morning routine"
        lblTitleOpenCheckLists.stringValue = "Open checklist"
        boxTools.wantsLayer = true
        boxTools.layer?.cornerRadius = boxPreferences.cornerRadius
        
        var itemReactivateTitle = "Reactivate"
        var itemEnterLicenseKeyTitle = "Enter License Key"
        var itemPreferences = "Preferences"
        var itemQuitTitle = "Quit"
        
        lblTitleTools.stringValue = "Tools >"
        var menuItemOpenToolboxTitle = "Open Toolbox"
        var menuItemFocusMusicTitle = "Focus Music"
        
        var titleStartBreak = "Start Break"
        lblTitleBrainDump.stringValue = "Brain Dump"
        
        lblMeetingDetection.stringValue = "Meeting active - breaks off"
        btnFalseDetection.title = "False positive: I'm not in a meeting"
        lblTitleResumeHabits.stringValue = "Resume Habits"
        lblTitleSetFocus.stringValue = "Set up Focus Modes"
        
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
            btnSetPermissions.title = simplePomodoroVcInfo.value(forKey: "buttonFixItText") as? String ?? btnSetPermissions.title
        }
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let focusEndsText = common.value(forKey: "focusEndsText") as? String {
                lblTitleFocusModeTime.stringValue = focusEndsText + ":"
            }
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
            itemQuitTitle = menuInfo.value(forKey: "menuItemQuitTitle") as? String ?? itemQuitTitle
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
            menuItemOpenToolboxTitle = menuInfo.value(forKey: "menuItemOpenToolboxTitle") as? String ?? menuItemOpenToolboxTitle
            menuItemFocusMusicTitle = menuInfo.value(forKey: "menuItemFocusMusicTitle") as? String ?? menuItemFocusMusicTitle
            menuItemToDoListTitle = menuInfo.value(forKey: "menuItemToDoListTitle") as? String ?? menuItemToDoListTitle
            menuItemToDoPlayerTitle = menuInfo.value(forKey: "menuItemToDoPlayerTitle") as? String ?? menuItemToDoPlayerTitle
            lblMeetingDetection.stringValue = menuInfo.value(forKey: "menuItemMeetingDetectionTitle") as? String ?? lblMeetingDetection.stringValue
            lblTitleResumeHabits.stringValue = menuInfo.value(forKey: "menuItemResumeHabitsTitle") as? String ?? lblTitleResumeHabits.stringValue
            
            titleOfficeMode = menuInfo.value(forKey: "segmentOfficeModeText") as? String ?? titleOfficeMode
            titleWFHMode = menuInfo.value(forKey: "segmentWfhModeText") as? String ?? titleWFHMode
            lblTitleSetFocus.stringValue = menuInfo.value(forKey: "menuItemSetFocusModesTitle") as? String ?? lblTitleSetFocus.stringValue
            lblTitleOpenCheckLists.stringValue = menuInfo.value(forKey: "menuItemOpenChecklistTitle") as? String ?? lblTitleOpenCheckLists.stringValue
            lblStartHabitsFirstTime.stringValue = menuInfo.value(forKey: "menuItemStartMorningHabitsFirstTimeTitle") as? String ?? lblStartHabitsFirstTime.stringValue
            itemStopPomodoroTitle = menuInfo.value(forKey: "menuItemStopPomodoroTitle") as? String ?? itemStopPomodoroTitle
            focusBreakTimeText = menuInfo.value(forKey: "focusBreakTimeText") as? String ?? focusBreakTimeText
            itemResumePomodoroTitle = menuInfo.value(forKey: "menuItemResumeFocusTitle") as? String ?? itemResumePomodoroTitle
            itemPausePomodoroTitle = menuInfo.value(forKey: "menuItemPauseFocusTitle") as? String ?? itemPausePomodoroTitle
            lblBlockingDisabled.stringValue = menuInfo.value(forKey: "menuItemBlockingDisabledTitle") as? String ?? lblBlockingDisabled.stringValue
            lblCustomRoutine.stringValue = menuInfo.value(forKey: "menuItemStartCustomRoutineTitle") as? String ?? lblCustomRoutine.stringValue
            lblTipPermissions.stringValue = menuInfo.value(forKey: "permissionsNotSetText") as? String ?? lblTipPermissions.stringValue
        }
        segmentControlOfficeMode.setLabel(titleOfficeMode, forSegment: 0)
        segmentControlOfficeMode.setLabel(titleWFHMode, forSegment: 1)
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "trialExpiredText") as? String{
                trialExpiredText = text
            }
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }
        }
        
        lblTitleReactivate.stringValue = itemReactivateTitle
        lblTitleEnterLicenseKey.stringValue = menuItemUpgradeNowTitle
        lblTitlePreferences.stringValue = itemPreferences
        lblTitleStartPomodoroMode.stringValue = itemStartPomodoroTitle
        lblTitleStartSimplePomodoroMode.stringValue = itemStartPomodoroTitle
        lblTitleQuit.stringValue = itemQuitTitle
        lblTitleStopHardcorePomodoroMode.stringValue = menuItemStopHardcorePomodoroTitle
        imgViewStopSuperFocusSession.image = iconStopFocusSession
        imgViewStartSimpleFocusSession.image = iconPlayFocusSession
        
        lblTitleAppName.stringValue = appName
        bottomLine.isHidden = true
        
        toolsMenu = NSMenu()
        menuItemStartBreak = NSMenuItem(title: titleStartBreak, action: #selector(btnStartBreakClicked(_:)), keyEquivalent: "")
        menuItemStartBreak.target = self
        toolsMenu.addItem(menuItemStartBreak)
        
        menuItemBrainDump = NSMenuItem(title: lblTitleBrainDump.stringValue, action: #selector(btnBrainDumpClicked(_:)), keyEquivalent: "")
        menuItemBrainDump.target = self
        toolsMenu.addItem(menuItemBrainDump)
        
        menuItemOpenToolbox = NSMenuItem(title: menuItemOpenToolboxTitle, action: #selector(openToolBoxClicked), keyEquivalent: "")
        menuItemOpenToolbox.target = self
        toolsMenu.addItem(menuItemOpenToolbox)
        
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
        // load preferences window// // beacuse some times webview dose not load at first time in settings so here we are loading window to load webview before opening it
        if !(preferencesWindowControllerObj?.isWindowLoaded ?? false){
            preferencesWindowControllerObj?.loadWindow()
        }
        addLog(text: "preferencesWindowControllerObj load window end")
        let boundsOfficeMode = NSRect(x: segmentControlOfficeMode.frame.minX, y: (segmentControlOfficeMode.frame.minY - 9), width: (segmentControlOfficeMode.frame.width/2) - 5, height: segmentControlOfficeMode.frame.height)
        let boundsWfhMode = NSRect(x: (segmentControlOfficeMode.frame.midX + 5), y: (segmentControlOfficeMode.frame.minY - 9), width: (segmentControlOfficeMode.frame.width/2) - 5, height: segmentControlOfficeMode.frame.height)// keep y to  egmentControlOfficeMode.frame.midY  do not change
        
        segmentOfficeModeTrackingArea = NSTrackingArea.init(rect: boundsOfficeMode, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        segmentControlOfficeMode.addTrackingArea(segmentOfficeModeTrackingArea!)
        
        segmentWfhModeTrackingArea = NSTrackingArea.init(rect: boundsWfhMode, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        segmentControlOfficeMode.addTrackingArea(segmentWfhModeTrackingArea!)
        
        trackingAreaBtnEditBlockingSchedule = NSTrackingArea.init(rect: btnEditBlockingSchedule.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnEditBlockingSchedule.addTrackingArea(trackingAreaBtnEditBlockingSchedule!)
        
        trackingAreaBtnPin = NSTrackingArea.init(rect: btnPin.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnPin.addTrackingArea(trackingAreaBtnPin!)
        
        btnFocusMusicTrackingArea = NSTrackingArea.init(rect: btnFocusMusic.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnFocusMusic.addTrackingArea(btnFocusMusicTrackingArea!)
        
        btnTodoPlayerTrackingArea = NSTrackingArea.init(rect: btnTodoPlayer.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnTodoPlayer.addTrackingArea(btnTodoPlayerTrackingArea!)
        
        btnBrainDumpTrackingArea = NSTrackingArea.init(rect: btnBrainDump.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnBrainDump.addTrackingArea(btnBrainDumpTrackingArea!)
        
        btnCurrentTrackTrackingArea = NSTrackingArea.init(rect: btnCurrentTrack.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnCurrentTrack.addTrackingArea(btnCurrentTrackTrackingArea!)
        
        
        btnStartBreakTrackingArea = NSTrackingArea.init(rect: btnStartBreak.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnStartBreak.addTrackingArea(btnStartBreakTrackingArea!)
        
        btnOpenToolBoxTrackingArea = NSTrackingArea.init(rect: btnOpenToolBox.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnOpenToolBox.addTrackingArea(btnOpenToolBoxTrackingArea!)
        
        boxPermissionTrackingArea = NSTrackingArea.init(rect: boxForPermissionToolTip.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        boxForPermissionToolTip.addTrackingArea(boxPermissionTrackingArea!)
        
        
        
        addLog(text: "menuViewController viewdidload end")
        lblTitleToDoPlayer.stringValue = menuItemToDoPlayerTitle
        segmentControlGeekMode.isMenuButton = true

        if SettingsManagerObject.isGeekModeEnabled{
            preferencesSettingsIndex = 3
            preferencesEditHabitsIndex = 4
            preferencesBlocksIndex = 2
        }else{
            preferencesSettingsIndex = 2
            preferencesEditHabitsIndex = 3
            preferencesBlocksIndex = 1
        }
        boxTipPermissions.isHidden = true
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
        showTooltip(sender: btnMeetingDetection, msg: videoCallText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnSetFocusModesClicked(_ sender: Any) {
        showSetFocusWindow()
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
        if event.trackingArea == segmentOfficeModeTrackingArea{
            showTooltip(sender: segmentControlOfficeMode, msg: toolTipOfficeMode, preferredEdge: NSRectEdge.minX, maxWidthVal:230)
        }else if event.trackingArea == segmentWfhModeTrackingArea{
            showTooltip(sender: segmentControlOfficeMode, msg: toolTipWfhMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }else if event.trackingArea == btnFocusMusicTrackingArea{
            showTooltip(sender: btnFocusMusic, msg: lblTitleFocusMusic.stringValue, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
        }else if event.trackingArea == btnTodoPlayerTrackingArea{
            showTooltip(sender: btnTodoPlayer, msg: menuItemToDoList.title, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
        }else if event.trackingArea == btnBrainDumpTrackingArea{
            showTooltip(sender: btnBrainDump, msg: lblTitleBrainDump.stringValue, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
        }else if event.trackingArea == btnCurrentTrackTrackingArea{
            showTooltip(sender: btnCurrentTrack, msg: lblCurrentTrack.stringValue, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
        }else if event.trackingArea == btnStartBreakTrackingArea{
            showTooltip(sender: btnStartBreak, msg: menuItemStartBreak.title, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
        }else if event.trackingArea == btnOpenToolBoxTrackingArea{
            showTooltip(sender: btnOpenToolBox, msg: menuItemOpenToolbox.title, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
        }else if event.trackingArea == trackingAreaBtnEditBlockingSchedule{
            var toolTipButtonEditBlockingSchedule = "Edit blocking schedule"
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                toolTipButtonEditBlockingSchedule = menuInfo.value(forKey: "toolTipButtonEditBlockingSchedule") as? String ?? toolTipButtonEditBlockingSchedule
            }
            showTooltip(sender: btnEditBlockingSchedule, msg: toolTipButtonEditBlockingSchedule, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
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
            showTooltip(sender: btnPin, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:290)
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
            
            
            showTooltip(sender: boxForPermissionToolTip, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:400)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == segmentOfficeModeTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == segmentWfhModeTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == btnFocusMusicTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == btnTodoPlayerTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == btnBrainDumpTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == btnCurrentTrackTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == trackingAreaBtnEditBlockingSchedule{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == trackingAreaBtnPin{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == btnStartBreakTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == btnOpenToolBoxTrackingArea{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == boxPermissionTrackingArea{
            closePopoverTooltipIfVisible()
        }
    }
    
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()// for geek mode change
        if !boxTipPermissions.isHidden{
            boxTipPermissions.stopBlinking()
        }
    }
    
    override func viewWillAppear() {//will not call if view is inside nsmenu but noe using popover so view will appear will work
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
        self.view.window?.appearance = getAppAppearance()
        reloadData()
        if !boxTipPermissions.isHidden{
            boxTipPermissions.startBlinking()
        }
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
            if upgradeNowWcObj != nil{
                if upgradeNowWcObj!.window?.isVisible ?? false{
                    upgradeNowWcObj!.window?.close()
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
        if SettingsManagerObject.blockingSchedule != ._UNTIL_I_FINISH_WORK_{
            boxBlockingDisabled.isHidden = false
        }else{
            boxBlockingDisabled.isHidden = true
        }
        if customRoutinesMenu.items.count == 0{
            boxCustomRoutine.isHidden = true
        }else{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                boxCustomRoutine.isHidden = true
            }else{
                if isPurchased == false && daysLeft <= 0{//
                    // will not execute custom rouine if app if subscription is active
                    boxCustomRoutine.isHidden = true
                }else{
                    if isShutOffTimeGoing(){
                        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
                            boxCustomRoutine.isHidden = false
                        }else{
                            boxCustomRoutine.isHidden = true
                        }
                    }else{
                        boxCustomRoutine.isHidden = false
                    }
                    
                }
            }
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            boxTipPermissions.isHidden = false
            browserPermissionGiven = false
            accessibilityPermissionGiven = false
            systemEventsPermissionGiven = false
        }else{
            if !browserPermissionGiven || !accessibilityPermissionGiven || !systemEventsPermissionGiven{
                boxTipPermissions.isHidden = false
            }else{
                boxTipPermissions.isHidden = true
            }
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
                        self.boxTipPermissions.isHidden = false
                    }else{
                        self.browserPermissionGiven = true
                    }
                }
            }
        }
        
        boxToDoPlayer.isHidden = false
        if isFocusModeOn() || ((currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && isAnyAllowedFocusModeActivityRunning){
            menuItemToDoList.title = menuItemToDoPlayerTitle
//            boxToDoPlayer.isHidden = false
            boxPreferences.borderWidth = 1
            boxPreferences.fillColor = NSColor.white
            boxPreferences.borderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
        }else{
            menuItemToDoList.title = menuItemToDoListTitle
//            boxToDoPlayer.isHidden = true
            boxPreferences.borderWidth = 0
            boxPreferences.fillColor = buttonBgColor
        }
        showFocusModeCountDownIfNeeded()
        if SettingsManagerObject.isMenuPopoverEnabled{
            btnPin.image = #imageLiteral(resourceName: "pin")
        }else{
            btnPin.image = #imageLiteral(resourceName: "unPin")
        }
        boxGeekMode.isHidden = true// 19/7/25 version 1.26.392   #1467
        
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
        
        boxStartHabitsFirstTime.isHidden = true
        
        
        if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_  && UserDefaults.standard.object(forKey: kUserdefaultsStartRoutineButtonClicked) == nil{
            let currentDate = Date()
            let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
            let sameDay = Calendar.current.isDate(currentDate, equalTo: firstRunDate, toGranularity: .day)
            let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false
            if isHabitsDisabled{
                UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
            }else{
                if sameDay || !shouldDoHabits(){
                    boxStartHabitsFirstTime.isHidden = false
                }else{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                }
            }
        }
        
        if !boxStartHabitsFirstTime.isHidden{
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                if isShutOffTimeGoing(){
                    lblStartHabitsFirstTime.stringValue = "Start evening routine"
                    lblStartHabitsFirstTime.stringValue = menuInfo.value(forKey: "menuItemStartEveningHabitsFirstTimeTitle") as? String ?? lblStartHabitsFirstTime.stringValue
                }else{
                    lblStartHabitsFirstTime.stringValue = "Start morning routine"
                    lblStartHabitsFirstTime.stringValue = menuInfo.value(forKey: "menuItemStartMorningHabitsFirstTimeTitle") as? String ?? lblStartHabitsFirstTime.stringValue
                }
            }
        }
        if isFocusModeOnOrPaused(){
            boxStartHabitsFirstTime.isHidden = true
        }
        
        if isAppEnable{
            if isShutOffTimeGoing(){
                boxStartBreak.isHidden = true
                menuItemStartBreak.isHidden = true
            }else{
                if isHabitAlreadyShowed{
                    if currentState == ._MORNING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_ || arrAllbreakActivities.count == 0 || currentState == ._SPECIAL_ACTIVITY_{
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
        
        var shouldShowToolBoxWindow = false
        if isAnyAllowedFocusModeActivityRunning || isFocusModeOn(){
            let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
            
            if !isAllowedAllAppsInFocus && allowAppsPath.count != 0{
                shouldShowToolBoxWindow = true
            }
            let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
            let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
            
            if arrAllowedUrlsForFocus.count != 0 && isAllowedListApproachInFocus{//!isAllowedAllUrlsInFocus &&#453
                shouldShowToolBoxWindow = true
            }
        }else if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentHabitPlaying != nil{
            let allowAppsPath = currentHabitPlaying?.allowApps ?? []
            if allowAppsPath.count != 0{
                shouldShowToolBoxWindow = true
            }
            let arrAllowedUrlsForFocus = currentHabitPlaying?.allowUrls ?? []
            
            if arrAllowedUrlsForFocus.count != 0{
                shouldShowToolBoxWindow = true
            }
        }
        if shouldShowToolBoxWindow{
            boxOpenToolBox.isHidden = false
            menuItemOpenToolbox.isHidden = false
        }else{
            boxOpenToolBox.isHidden = true
            menuItemOpenToolbox.isHidden = true
        }
        
        
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
            
            if currentState != ._ACTIVITY_ && currentState != ._SHUTOFFMAC_{
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
                var isBreakEnabled = SettingsManagerObject.isMicroBreaksEnabled
                
                if let disableBreaksForTodayDate = UserDefaults.standard.object(forKey: kUserdefaultsDisableBreaksForToday) as? Date{
                    if Calendar.current.isDateInToday(disableBreaksForTodayDate){
                        isBreakEnabled = false
                    }
                }
                
                if getHabitsVcObject().breakTimer != nil && isBreakEnabled{
                    if mainViewControllerObj!.breakTimer!.isValid{
                        boxNextBreak.isHidden = false
                        let currentTime = Date()
                        let breakTime = mainViewControllerObj!.breakTimer!.fireDate
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
                        
                        
                        
                        if diffMinute < 1{//show the break as soon as there are 5 seconds of inactivity
                            let diffSeconds = Calendar.current.dateComponents([.second], from: currentTime, to: breakTime).second ?? 0
                            if diffSeconds < 5{
                                lblNextBreakTime.stringValue = "It's time for a break. Waiting for a good moment"
                                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                                    lblNextBreakTime.stringValue = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? lblNextBreakTime.stringValue
                                }
                            }
                        }
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
                }
            }else{
                boxMeetingDetection.isHidden = true
            }

            
            
            
            
            if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
                boxSetFocusModes.isHidden = false
            }else{
                boxSetFocusModes.isHidden = true
            }
            let isFocusModeOn = isFocusModeOn()
            let isFocusModePaused = isFocusModePaused()
            
            if isFocusModeOn || isFocusModePaused{
                if isFocusModeOn{
                    if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && !isBlockSuperDistractingFocusModeOn(){
                        boxFocusAlignmentScore.isHidden = false
                        setFocusAlignmentScore(totalSeconds: focusModeMinutesToPerform * 60)
                    }else{
                        boxFocusAlignmentScore.isHidden = true
                    }
                    lblTitleStopHardcorePomodoroMode.stringValue = itemStopPomodoroTitle
                    imgViewStopSuperFocusSession.image = iconStopFocusSession
                }else {
                    boxFocusAlignmentScore.isHidden = true
                    lblTitleStopHardcorePomodoroMode.stringValue = itemResumePomodoroTitle
                    imgViewStopSuperFocusSession.image = iconResumeFocusSession
                }
                boxStartPomodoroMode.isHidden = true
                boxStopHardcorePomodoroMode.isHidden = false
                
            }else{
                boxFocusAlignmentScore.isHidden = true
                if isHardCorePomodoroModeOn{
                    
                    if currentFocusModeStrictness == ._SUPER_STRICT_{
                        boxStopHardcorePomodoroMode.isHidden = true
                    }else{
                        boxStopHardcorePomodoroMode.isHidden = false
                        lblTitleStopHardcorePomodoroMode.stringValue = menuItemStopHardcorePomodoroTitle
                        imgViewStopSuperFocusSession.image = iconStopFocusSession
                    }
                    boxStartPomodoroMode.isHidden = true
                }else{
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                        boxStartPomodoroMode.isHidden = true
                    }else{
                        boxStartPomodoroMode.isHidden = false
                    }
                    boxStopHardcorePomodoroMode.isHidden = true
                }
            }
            if boxFocusAlignmentScore.isHidden{
                if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && (currentHabitPlaying != nil) && isAnyAllowedFocusModeActivityRunning{
                    if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && !isBlockSuperDistractingFocusModeOn(){
                        boxFocusAlignmentScore.isHidden = false
                        setFocusAlignmentScore(totalSeconds: currentHabitPlaying?.durationSeconds ?? 200)
                    }
                }
            }
//            stackViewFocusMode.isHidden = false
//            resetViewHeight()
//            tblViewFocusMode.reloadData()
            if SettingsManagerObject.isOfficeModeEnabled{
                segmentControlOfficeMode.setSelected(true, forSegment: 0)
            }else{
                segmentControlOfficeMode.setSelected(true, forSegment: 1)
            }
            boxEnableOfficeMode.isHidden = true
            boxStartSimplePomodoroMode.isHidden = true
        }else{
            boxTimeSinceLastBreak.isHidden = true
            boxBrainDump.isHidden = false
            boxTools.isHidden = false// 19/7/25 version 1.26.392   #1467
            boxNextBreak.isHidden = true
            boxMeetingDetection.isHidden = true
            boxSetFocusModes.isHidden = true
            boxFocusAlignmentScore.isHidden = true
            boxStartPomodoroMode.isHidden = true
            boxStopHardcorePomodoroMode.isHidden = true
            boxEnableOfficeMode.isHidden = true
            
            
            let isFocusModeOn = isFocusModeOn()
            if isFocusModeOn{
                lblTitleStartSimplePomodoroMode.font = NSFont.systemFont(ofSize: 13)
                if isFocusModeStartedFromPomodoroMode{
                    lblTitleStartSimplePomodoroMode.stringValue = itemStopPomodoroTitle
                    imgViewStartSimpleFocusSession.image = iconStopFocusSession
                    boxStartSimplePomodoroMode.isHidden = false
                }else{
                    boxStartSimplePomodoroMode.isHidden = true
                }
                heightButtonSimplePomodoro.constant = 28
                widthImageIconSimplePomodoro.constant = 23
                boxStartSimplePomodoroMode.borderWidth = 0
            }else{
                lblTitleStartSimplePomodoroMode.stringValue = itemStartPomodoroTitle
                imgViewStartSimpleFocusSession.image = iconPlayFocusSession
                heightButtonSimplePomodoro.constant = 46
                boxStartSimplePomodoroMode.borderWidth = 2
                widthImageIconSimplePomodoro.constant = 28
                lblTitleStartSimplePomodoroMode.font = NSFont.boldSystemFont(ofSize: 16)
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                    boxStartSimplePomodoroMode.isHidden = true
                }else{
                    boxStartSimplePomodoroMode.isHidden = false
                }
            }
            
            
        }
        

        
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_{
            boxResumeHabits.isHidden = false
        }else if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeMorningHabit{
            boxResumeHabits.isHidden = false
        }else if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeEveningHabit{
            boxResumeHabits.isHidden = false
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit{
            boxResumeHabits.isHidden = false
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
            boxResumeHabits.isHidden = false
        }else{
            boxResumeHabits.isHidden = true
        }
        
        
        checkPurchaseState()
        
        if !isAppEnable{// button title "Quit" if app is disabled
            boxReactivate.isHidden = false
            if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
                if let quittingConfirmInfo = quitInfo.value(forKey: "quittingConfirmInfo") as? NSDictionary{
                    if let buttonQuitText = quittingConfirmInfo.value(forKey: "buttonQuitText") as? String{
                        lblTitleQuit.stringValue = buttonQuitText
                    }
                }
            }
            
        }else{// button title "Pause blocking" if app is disabled
            boxReactivate.isHidden = true
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                lblTitleQuit.stringValue = menuInfo.value(forKey: "menuItemQuitTitle") as? String ?? lblTitleQuit.stringValue
            }
        }

        
        boxOpenCheckLists.isHidden = true
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
            if currentAction == ._INPROGRESS_{
                if isMainWindowLoaded{
                    if !(mainWindowControllerObj?.window?.isVisible ?? false){
                        if let checkList = currentHabitPlaying?.checkList{
                            if checkList.count != 0{
                                boxOpenCheckLists.isHidden = false
                            }
                        }
                        if let checkList = currentActivityPlaying?.checkList{
                            if checkList.count != 0{
                                boxOpenCheckLists.isHidden = false
                            }
                        }
                    }
                }
            }
        }
        
        if isMenuShowingFirstTime{
            isMenuShowingFirstTime = false
            if !self.boxStartSimplePomodoroMode.isHidden{
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.boxStartSimplePomodoroMode.wantsLayer = true
                        self.showAnimationSimplePomodoro()
                        var msg = "You may want to Start a Focus session to focus on specific work for a set duration." 
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            msg = menuInfo.value(forKey: "toolTipPomodoroSessionText") as? String ?? msg
                        }
                        showTooltip(sender: self.boxStartSimplePomodoroMode, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
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
    
    func reloadPermission(){
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) != nil{
            if !browserPermissionGiven || !accessibilityPermissionGiven || !systemEventsPermissionGiven{
                boxTipPermissions.isHidden = false
            }else{
                boxTipPermissions.isHidden = true
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
                        if self.boxStartSimplePomodoroMode.isHidden{
                            return;
                        }
                        self.boxStartSimplePomodoroMode.fillColor = NSColor.systemYellow
                    }
                }else{
                    DispatchQueue.main.async {
                        self.boxStartSimplePomodoroMode.fillColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
                        if self.boxStartSimplePomodoroMode.isHidden{
                            return;
                        }
                    }
                }
                usleep(500000)
            }
        }
    }

    @IBAction func btnReactivateClicked(_ sender: Any) {
        appdelegate?.menuItem_Reactivate()
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
    }
    
    @IBAction func btnEnterLicenseKeyClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnEnterLicenseKeyClicked")
        showUpgradeNowWindow()
    }
    
    @IBAction func btnPreferencesClicked(_ sender: Any) {
        appdelegate?.menuItem_Preferences()
    }
    @IBAction func btnStartBreakClicked(_ sender: Any) {
        addLog(text: "[user-action] button Start Break Clicked")
        if !isMainWindowLoaded{
            mainWindowControllerObj?.loadWindow()
        }
        getHabitsVcObject().executeBreakActivities()
    }
    
    @IBAction func btnOpenToolBoxClicked(_ sender: Any) {
        openToolBoxClicked()
    }
    
    @IBAction func btnBrainDumpClicked(_ sender: Any) {
        addLog(text: "[user-action] button Brain Dump Clicked")
        showBrainDumpWindow()
    }
    
    @IBAction func btnToDoPlayerClicked(_ sender: Any) {
        addLog(text: "[user-action] btnToDoPlayerClicked")
        openToDoListClicked()
    }
    
    @IBAction func btnFocusMusicClicked(_ sender: Any) {
        openAllTracksClicked()
    }
    
    @objc func openToolBoxClicked(){
        addLog(text: "[user-action] openToolBoxClicked")
        showToolboxWindow()
    }
    
    @objc func openToDoListClicked(){
        addLog(text: "[user-action] openToDoListClicked")
        if isFocusModeOn() || ((currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && isAnyAllowedFocusModeActivityRunning){
            showTaskPlayerWindow(totalDuration: focusModeMinutesToPerform, intention: whatToAchieveInFocusBlock, automatically:false)
        }else{
            showToDoListWindow()
        }
    }
    
    @objc func openAllTracksClicked(){
        addLog(text: "[user-action] openAllTracksClicked")
        showAllTracksWindow()
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
            return;
        }
    }
    
    @IBAction func btnStartSimplePomodoroModeClicked(_ sender: Any) {
//        if isPurchased == false && daysLeft <= 0{
//            if trialExpiredNagWcObj != nil{
//                if trialExpiredNagWcObj?.window?.isVisible ?? false{
//                    return;
//                }
//            }
//            showUpgradeNowWindow()
//            return;
//        }
        if isFocusModeOn(){
            if currentFocusModeStrictness == ._SUPER_STRICT_{
                addLog(text: "can't stop focus mode in super strict focus mode :- return")
                var cantStopFocusModeText = "Super strict mode activated: You cannot stop this focus session until it ends."
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    cantStopFocusModeText = menuInfo.value(forKey: "cantStopFocusModeText") as? String ?? cantStopFocusModeText
                }
                showTooltip(sender: boxStartSimplePomodoroMode, msg: cantStopFocusModeText, preferredEdge: .minX, maxWidthVal: 250)
                return;
            }
            showAbortingFocusModeVc(forPause: false)
        }else{
            appdelegate?.menuShowSimplePomodoroModeView()
        }
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
    }

    func showPasswordWindow(){
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
                        showStartingFocusMode(focusModeIndex: i, focusType: arrFocusType[i]["name"] as? String ?? "")
                        if customUrlHandleLastDurationForRelaxFocusMode != 0{
                            startingFocusModeVcObj?.textFieldHourValue.integerValue = 0
                            startingFocusModeVcObj?.textFieldMinutesValue.integerValue = customUrlHandleLastDurationForRelaxFocusMode/60
                        }
                    }
                }
            }
        }else{
            if isFocusModeOnOrPaused(){
                showAbortingFocusModeVc(forPause: false)
            }else{
                isHardCorePomodoroModeOn = false
            }
        }
    }
    
    @IBAction func btnStopHardcorePomodoroModeClicked(_ sender: Any) {
        if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
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
                    if currentFocusModeStrictness == ._SUPER_STRICT_{
                        addLog(text: "can't stop focus mode in super strict focus mode :- return")
                        var cantStopFocusModeText = "Super strict mode activated: You cannot stop this focus session until it ends."
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            cantStopFocusModeText = menuInfo.value(forKey: "cantStopFocusModeText") as? String ?? cantStopFocusModeText
                        }
                        showTooltip(sender: boxStopHardcorePomodoroMode, msg: cantStopFocusModeText, preferredEdge: .minX, maxWidthVal: 250)
                        return;
                    }
                    
                    let menu = NSMenu()
                    if timerForFocusMode != nil{
                        let menuItemPause = NSMenuItem(title: itemPausePomodoroTitle, action: #selector(pauseFocusMode), keyEquivalent: "")
                        menuItemPause.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                        menuItemPause.target = self
                        menu.addItem(menuItemPause)
                    }
                    
                    let menuItemStop = NSMenuItem(title: itemStopPomodoroTitle, action: #selector(stopFocusMode), keyEquivalent: "")
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    menu.minimumWidth = boxStopHardcorePomodoroMode.frame.width
                    let p = NSPoint(x: boxStopHardcorePomodoroMode.frame.origin.x, y: boxStopHardcorePomodoroMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: boxStopHardcorePomodoroMode)
                    
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
                    
                    
                    menu.minimumWidth = boxStopHardcorePomodoroMode.frame.width
                    let p = NSPoint(x: boxStopHardcorePomodoroMode.frame.origin.x, y: boxStopHardcorePomodoroMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: boxStopHardcorePomodoroMode)
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
                        reloadData()
                    }
                }else{
                    isHardCorePomodoroModeOn = false
                    reloadData()
                }
            }else{
                boxStopHardcorePomodoroMode.isHidden = true
            }
        }else{
            
        }
    }
    
    @objc func pauseFocusMode(){
        if currentFocusModeStrictness == ._STRICT_{
            showAbortingFocusModeVc(forPause: true)
        }else{
            for index in 0..<arrFocusType.count{
                if arrFocusType[index]["isOn"] as? Bool == true{
                    appdelegate?.pauseFocusMode(index: index)
                    if SettingsManagerObject.isMenuPopoverEnabled{
                        appdelegate?.popover.close()
                    }else{
                        reloadData()
                    }
                    break;
                }
            }
            
        }
    }
    
    @objc func stopFocusMode(){
        if isHardCorePomodoroModeOn{
            if shouldAskPassword(){
                if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                    menuViewControllerObj?.showPasswordWindow()
                    addLog(text: "Showing enter password view from hardcore pomodoro stop from focus stop menu")
                }else{
                    showAbortingFocusModeVc(forPause: false)
                }
            }else{
                showAbortingFocusModeVc(forPause: false)
            }
        }else{
            showAbortingFocusModeVc(forPause: false)
        }
    }
    
    @objc func resumeFocusMode(){
        for index in 0..<arrFocusType.count{
            if arrFocusType[index]["isPaused"] as? Bool == true{
                appdelegate?.resumeFocusMode(index: index)
                if SettingsManagerObject.isMenuPopoverEnabled{
                    appdelegate?.popover.close()
                }else{
                    reloadData()
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
    }
    
    @IBAction func btnSegmentControlClicked(_ sender: Any) {
        btnEnableOfficeModeClicked(self)
    }
    
    @IBAction func btnSegmentControlGeekMode(_ sender: Any) {
        if segmentControlGeekMode.selectedSegment == 0{
            if SettingsManagerObject.isGeekModeEnabled{
                return;
            }
            segmentControlGeekMode.changeAppModeTo(geekMode: true)
        }else{
            if !SettingsManagerObject.isGeekModeEnabled{
                return;
            }
            segmentControlGeekMode.changeAppModeTo(geekMode: false)
        }
    }
    
    @IBAction func btnEnableOfficeModeClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnEnableOfficeModeClicked")
        if isPurchased == false && daysLeft <= 0{//UserDefaults.standard.object(forKey: "trialExpired") != nil{
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
            return;
        }
        
        addLog(text: "menu item Enable Office Mode by user")
        if SettingsManagerObject.isOfficeModeEnabled{
            SettingsManagerObject.isOfficeModeEnabled = false
            NSApplication.shared.applicationIconImage = nil
            allApiObject.capturePosthog(event: "disable-office-mode", metadata: [:])
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
            segmentControlOfficeMode.setSelected(true, forSegment: 1)
        }else{
            let filterArr = arrAllbreakActivities.filter { $0.isOfficeFriendly == true}
            if filterArr.count == 0{// no activity found with isOfficeFriendly //
                let alert = NSAlert()
                alert.setSharingType()
                var noOfficeFriendlyActivityAlertText = "You don't have any office friendly break activities. Do you want me to add one for you to stand up and stretch for 20 seconds?"
                var noOfficeFriendlyActivityButtonFirstText = "Yeah sounds good"
                var noOfficeFriendlyActivityButtonSecondText = "No I'm a machine! I don't need breaks"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    noOfficeFriendlyActivityAlertText = menuInfo.value(forKey: "noOfficeFriendlyActivityAlertText") as? String ?? noOfficeFriendlyActivityAlertText
                    noOfficeFriendlyActivityButtonFirstText = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonFirstText") as? String ?? noOfficeFriendlyActivityButtonFirstText
                    noOfficeFriendlyActivityButtonSecondText = menuInfo.value(forKey: "noOfficeFriendlyActivityButtonSecondText") as? String ?? noOfficeFriendlyActivityButtonSecondText
                }
                alert.messageText = noOfficeFriendlyActivityAlertText//
                alert.addButton(withTitle: noOfficeFriendlyActivityButtonFirstText)
                alert.addButton(withTitle: noOfficeFriendlyActivityButtonSecondText)
                NSApplication.shared.activate(ignoringOtherApps: true)
                let result = alert.runModal()
                if result == .alertFirstButtonReturn{
                    print("first button")
                    addOfficeFriendlyActivityInSettings()
                    enableOfficeMode()
                }else{
                    print("second button")
                    //cancel
                }
                
            }else{
                enableOfficeMode()
                
            }
            
        }
        
    }
    
    func enableOfficeMode(){
        addLog(text: "enableOfficeMode")
        
        if UserDefaults.standard.object(forKey: "officeModeEnabledSuccessAlertShown") == nil{
            let alert = NSAlert()
            alert.setSharingType()
            var officeModeEnabledSuccessfullyText = "Ok! I'll just prompt you to do activities that won't weird other people out (doing handstand pushups in the office might raise a few eyebrows)."
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                officeModeEnabledSuccessfullyText = menuInfo.value(forKey: "officeModeEnabledSuccessfullyText") as? String ?? officeModeEnabledSuccessfullyText
            }
            alert.messageText = officeModeEnabledSuccessfullyText
            alert.addButton(withTitle: buttonOkText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            _ = alert.runModal()
            UserDefaults.standard.set(true, forKey: "officeModeEnabledSuccessAlertShown")
        }
        
        
        SettingsManagerObject.isOfficeModeEnabled = true
        allApiObject.capturePosthog(event: "enable-office-mode", metadata: [:])
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
        segmentControlOfficeMode.setSelected(true, forSegment: 0)
        NSApplication.shared.applicationIconImage = NSImage(named: NSImage.Name("Bear-Office-icon"))
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
    
    @IBAction func btnLockCurrentFocusClicked(_ sender: Any) {
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isLockedFocus"] as? Bool == true{
                showStartingFocusMode(focusModeIndex: i, focusType: arrFocusType[i]["name"] as? String ?? "")
                break;
            }
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
        var shouldShowToolBoxWindow = false
        if isAnyAllowedFocusModeActivityRunning || isFocusModeOn(){
            let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
            
            if !isAllowedAllAppsInFocus && allowAppsPath.count != 0{
                shouldShowToolBoxWindow = true
            }
            let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
            let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
            
            if arrAllowedUrlsForFocus.count != 0 && isAllowedListApproachInFocus{//!isAllowedAllUrlsInFocus &&#453
                shouldShowToolBoxWindow = true
            }
        }else if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentHabitPlaying != nil{
            let allowAppsPath = currentHabitPlaying?.allowApps ?? []
            if allowAppsPath.count != 0{
                shouldShowToolBoxWindow = true
            }
            let arrAllowedUrlsForFocus = currentHabitPlaying?.allowUrls ?? []
            
            if arrAllowedUrlsForFocus.count != 0{
                shouldShowToolBoxWindow = true
            }
        }
        if shouldShowToolBoxWindow{
            boxOpenToolBox.isHidden = false
            menuItemOpenToolbox.isHidden = false
        }else{
            boxOpenToolBox.isHidden = true
            menuItemOpenToolbox.isHidden = true
        }
        toolsMenu.minimumWidth = boxTools.frame.width
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y )
        toolsMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
    
    @IBAction func btnResumeHabitsClicked(_ sender: Any) {
        if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeMorningHabit{
            getHabitsVcObject().stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                    if smallCountDownWcObj?.window != nil{
                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                            getSmallCountDownWindowObject().window?.close()
                        }
                    }
                }
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            
            isBreakActivityExecuteFromPostponeMorningHabit = false
            currentState = ._NOTHING_
            closePupUpBlockIfVisible()
            currentActivityPlaying = nil
        }else if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeEveningHabit{
            getHabitsVcObject().stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                    if smallCountDownWcObj?.window != nil{
                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                            getSmallCountDownWindowObject().window?.close()
                        }
                    }
                }
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
                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                    if smallCountDownWcObj?.window != nil{
                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                            getSmallCountDownWindowObject().window?.close()
                        }
                    }
                }
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
                if smallCountDownWcObj != nil{
                    if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                        smallCountDownVcObj?.closeTimerBox()
                    }
                }
            }
            if getHabitsVcObject().postponeNotificationTimer != nil{
                getHabitsVcObject().postponeNotificationTimer?.invalidate()
                getHabitsVcObject().postponeNotificationTimer = nil
            }
        }
        
        appdelegate?.backgroundThread()
        
        
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
                
                if allTracksWindowControllerObj != nil{
                    if allTracksWindowControllerObj?.window?.isVisible ?? false{
                        allTracksVcObj?.tblView.reloadData()
                    }
                }
                return;
            }else if arrAllTracks[i]["isPaused"] as? Bool == true{
                
                arrAllTracks[i]["isPlaying"] = true
                arrAllTracks[i]["isPaused"] = false
                allTracksVcObj?.currentSound?.resume()
                
                imgViewCurrentTrackState.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                
                if allTracksWindowControllerObj != nil{
                    if allTracksWindowControllerObj?.window?.isVisible ?? false{
                        allTracksVcObj?.tblView.reloadData()
                    }
                }
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
    }
    
    @IBAction func btnRemoveAppModeOptionClicked(_ sender: Any) {
        addLog(text: "btnRemoveAppModeOptionClicked")
        boxGeekMode.isHidden = true
        UserDefaults.standard.set(true, forKey: kUserDefaultsHideAppModeOption)
    }
    
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
            var shouldShowPassword = true
            if preferencesWindowControllerObj?.window?.isVisible ?? false{
                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                    tabview.selectedTabViewItemIndex = preferencesEditHabitsIndex
                    addLog(text: "")
                }
                shouldShowPassword = false
            }else{
                preferencesWindowControllerObj?.showWindow(self)
            }
            addLog(text: "Showing preferences")
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = preferencesEditHabitsIndex
                if isPasswordRequireInOpenSettings() && shouldShowPassword{
                    tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
                    tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
                    getEnterPasswordVcObjForPreferences().parentVc = nil
                    enterPasswordVcObjForPreferences?.removeConstraints()
                    addLog(text: "Showing enter password view")
                }
            }
        }
    }
    
    @IBAction func btnInfoBlockingDisabledClicked(_ sender: hoverInfoButton) {
        var msg = "Blocking disabled because you chose to only activate blocks during focus sessions."
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            msg = menuInfo.value(forKey: "toolTipBlockingDisabled") as? String ?? msg
        }
        
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
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
        
        var shouldShowPassword = true
        if preferencesWindowControllerObj?.window?.isVisible ?? false{
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = preferencesBlocksIndex
                addLog(text: "")
            }
            shouldShowPassword = false
        }else{
            preferencesWindowControllerObj?.showWindow(self)
        }
        addLog(text: "Showing preferences")
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = preferencesBlocksIndex
            if isPasswordRequireInOpenSettings() && shouldShowPassword{
                tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
                tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
                getEnterPasswordVcObjForPreferences().parentVc = nil
                enterPasswordVcObjForPreferences?.removeConstraints()
                addLog(text: "Showing enter password view")
            }
        }
        tabStrictnessContainerVcObj?.showBlockingScheduleView()
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
    }
    
    @IBAction func btnCustomRoutineClicked(_ sender: Any) {
        customRoutinesMenu.minimumWidth = boxCustomRoutine.frame.width
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y )
        customRoutinesMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
}













