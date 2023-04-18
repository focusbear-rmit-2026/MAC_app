//
//  menuViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/02/22.

//

import Cocoa

class menuViewController: NSViewController {
    
    
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
    
    @IBOutlet weak var btnInfoOfficeMode: NSButton!
    @IBOutlet weak var lblTitleLockCurrentFocus: NSTextField!
    @IBOutlet weak var boxLockCurrentFocus: NSBox!
    
    @IBOutlet weak var lblTitleBrainDump: NSTextField!
    @IBOutlet weak var boxBrainDump: NSBox!
    
    @IBOutlet weak var lblTitleStartBreak: NSTextField!
    @IBOutlet weak var boxStartBreak: NSBox!
    @IBOutlet weak var lblTitleAppName: NSTextField!
    @IBOutlet weak var boxTitle: customBoxBg!
    //    @IBOutlet weak var toggleButtonOfficeMode: CToggleButton!
    //    @IBOutlet weak var boxCheckMark: NSBox!
    @IBOutlet weak var lblTrialVersionInfo: NSTextField!
    @IBOutlet weak var lblTitleReactivate: NSTextField!
    @IBOutlet weak var lblTitleEnterLicenseKey: NSTextField!
    
    @IBOutlet weak var lblTitlePreferences: NSTextField!
    @IBOutlet weak var lblTitleExportStatistics: NSTextField!
    @IBOutlet weak var lblTitleFocus: NSTextField!
    @IBOutlet weak var lblTitleStartPomodoroMode: NSTextField!
    @IBOutlet weak var lblTitleQuit: NSTextField!
    @IBOutlet weak var lblTitleCheckForUpdates: NSTextField!
    //    @IBOutlet weak var lblTitleEnableOfficeMode: NSTextField!
    @IBOutlet weak var lblTitleStopHardcorePomodoroMode: NSTextField!
    
    @IBOutlet weak var bottomLine: NSBox!
    @IBOutlet weak var lblOn: NSTextField!
    @IBOutlet weak var boxFocusMode: NSBox!
    @IBOutlet weak var focusModeBoxHeight: NSLayoutConstraint!
    @IBOutlet weak var boxStartPomodoroMode: NSBox!
    @IBOutlet weak var boxCheckForUpdates: NSBox!
    @IBOutlet weak var boxQuit: NSBox!
    @IBOutlet weak var boxExportStatistics: NSBox!
    @IBOutlet weak var boxPreferences: NSBox!
    @IBOutlet weak var boxStopHardcorePomodoroMode: NSBox!
    
    @IBOutlet weak var boxEnterLicenseKey: NSBox!
    @IBOutlet weak var boxReactivate: NSBox!
    @IBOutlet weak var tblViewFocusMode: NSTableView!
    @IBOutlet weak var boxEnableOfficeMode: NSBox!
    
    
//    @IBOutlet weak var lblTitleWorkMode: NSTextField!
    var btnInfoOfficeModeTrackingArea: NSTrackingArea?
    
    
    var segmentOfficeModeTrackingArea: NSTrackingArea?
    var segmentWfhModeTrackingArea: NSTrackingArea?
    
    var btnInfoMeetingDetectionTrackingArea: NSTrackingArea?
    
    var toolsMenu:NSMenu!
    
    //    var selectedIndex = -1
    
    var onText = "On"
    var untilTimeText = "ends at <TIME>"
    
    var trialExpiredText = "Your trial has expired!"
    var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
    var itemFocusTitle = "Focus"
    var itemHardcorePomodoroTitle = "Hardcore Pomodoro Mode"
    
    var menuItemUpgradeNowTitle = "Upgrade Now"
    var subscriptionExpiredText = "Your subscription has expired"
    
    var menuItemEnableOfficeModeTitle = "Enable office mode"
    var menuItemDisableOfficeModeTitle = "WFH Mode Enabled"
    
    var toolTipOfficeMode = "When you're working from the office, I will only give you appropriate break activities (e.g. chair stretches rather than pushups)."
    var toolTipWfhMode = "No-one's around! You can do break activities that are a bit more fun, e.g. Dance like no-one's watching"
    
    
    var menuItemStartBreak: NSMenuItem!
    var menuItemFocusMusic: NSMenuItem!
    var menuItemOpenToolbox: NSMenuItem!
    var menuItemBrainDump: NSMenuItem!
    var titleOfficeMode = "Office Mode"
    var titleWFHMode = "WFH Mode"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        segmentControlOfficeMode.selectedSegmentBezelColor = NSColor.systemBlue
        
        
        
        
        
        boxStartBreak.isHidden = true
        
        boxLockCurrentFocus.isHidden = true
        boxCheckForUpdates.isHidden = true
        boxExportStatistics.isHidden = true
        boxTitle.fillColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
        boxFocusMode.wantsLayer = true
        boxFocusMode.layer?.cornerRadius = boxPreferences.cornerRadius
        //        toggleButtonOfficeMode.statetag = 111
        //        toggleButtonOfficeMode.wantsLayer = true
        //        toggleButtonOfficeMode.shadow = NSShadow()
        //        toggleButtonOfficeMode.layer?.shadowOpacity = 0.3
        //        toggleButtonOfficeMode.layer?.shadowColor = NSColor.black.cgColor
        //        toggleButtonOfficeMode.layer?.shadowOffset = NSMakeSize(0, -2)
        //        toggleButtonOfficeMode.layer?.shadowRadius = 3
        //        NotificationCenter.default.addObserver(self, selector: #selector(btnToggleClicked), name: Notification.Name("toggle"), object: nil)
        var itemReactivateTitle = "Reactivate"
        var itemEnterLicenseKeyTitle = "Enter License Key"
        //        lblTitleLockCurrentFocus.stringValue = "Lock In Current Focus"
        
        var itemPreferences = "Preferences"
        var itemExportStatisticsTitle = "Export Statistics"
        
        var itemQuitTitle = "Quit"
        var itemStartPomodoroTitle = "Start Pomodoro Mode"
        var menuItemCheckForUpdatesTitle = "Check for updates"
        
        lblTitleTools.stringValue = "Tools >"
        var menuItemOpenToolboxTitle = "Open Toolbox"
        var menuItemFocusMusicTitle = "Focus Music"
        
        
        lblTitleStartBreak.stringValue = "Start Break"
        lblTitleBrainDump.stringValue = "Brain Dump"
        var menuItemStopHardcorePomodoroTitle = "Stop Hardcore Pomodoro Mode"
        
        lblMeetingDetection.stringValue = "Meeting active - breaks off"
        btnFalseDetection.title = "False positive: I'm not in a meeting"
        
        lblTitleResumeHabits.stringValue = "Resume Habits"
//        lblTitleWorkMode.stringValue = "Work Mode:"
        lblTitleSetFocus.stringValue = "Set up Focus Modes"
        
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
            itemExportStatisticsTitle = menuInfo.value(forKey: "menuItemExportStatisticsTitle") as? String ?? itemExportStatisticsTitle
            itemFocusTitle = menuInfo.value(forKey: "menuItemFocusTitle") as? String ?? itemFocusTitle
            itemQuitTitle = menuInfo.value(forKey: "menuItemQuitTitle") as? String ?? itemQuitTitle
            itemStartPomodoroTitle = menuInfo.value(forKey: "menuItemStartPomodoroTitle") as? String ?? itemStartPomodoroTitle
            menuItemCheckForUpdatesTitle = menuInfo.value(forKey: "menuItemCheckForUpdatesTitle") as? String ?? menuItemCheckForUpdatesTitle
            menuItemEnableOfficeModeTitle = menuInfo.value(forKey: "menuItemEnableOfficeModeTitle") as? String ?? menuItemEnableOfficeModeTitle
            menuItemDisableOfficeModeTitle = menuInfo.value(forKey: "menuItemDisableOfficeModeTitle") as? String ?? menuItemDisableOfficeModeTitle
            untilTimeText = menuInfo.value(forKey: "untilTimeText") as? String ?? untilTimeText
            onText = menuInfo.value(forKey: "onText") as? String ?? onText
            itemHardcorePomodoroTitle = menuInfo.value(forKey: "menuItemHardcorePomodoroModeTitle") as? String ?? itemHardcorePomodoroTitle
            menuItemStopHardcorePomodoroTitle = menuInfo.value(forKey: "menuItemStopHardcorePomodoroTitle") as? String ?? menuItemStopHardcorePomodoroTitle
            
            menuItemUpgradeNowTitle = menuInfo.value(forKey: "menuItemUpgradeNowTitle") as? String ?? menuItemUpgradeNowTitle
            subscriptionExpiredText = menuInfo.value(forKey: "subscriptionExpiredText") as? String ?? subscriptionExpiredText
            lblTitleStartBreak.stringValue = menuInfo.value(forKey: "menuItemStartBreakTitle") as? String ?? lblTitleStartBreak.stringValue
            lblTitleBrainDump.stringValue = menuInfo.value(forKey: "menuItemBrainDumpTitle") as? String ?? lblTitleBrainDump.stringValue
            toolTipOfficeMode = menuInfo.value(forKey: "toolTipOfficeMode") as? String ?? toolTipOfficeMode
            toolTipWfhMode = menuInfo.value(forKey: "toolTipWfhMode") as? String ?? toolTipWfhMode
            lblTitleTools.stringValue = menuInfo.value(forKey: "menuItemToolsTitle") as? String ?? lblTitleTools.stringValue
            menuItemOpenToolboxTitle = menuInfo.value(forKey: "menuItemOpenToolboxTitle") as? String ?? menuItemOpenToolboxTitle
            menuItemFocusMusicTitle = menuInfo.value(forKey: "menuItemFocusMusicTitle") as? String ?? menuItemFocusMusicTitle
            lblMeetingDetection.stringValue = menuInfo.value(forKey: "menuItemMeetingDetectionTitle") as? String ?? lblMeetingDetection.stringValue
            lblTitleResumeHabits.stringValue = menuInfo.value(forKey: "menuItemResumeHabitsTitle") as? String ?? lblTitleResumeHabits.stringValue
            
            titleOfficeMode = menuInfo.value(forKey: "segmentOfficeModeText") as? String ?? titleOfficeMode
            titleWFHMode = menuInfo.value(forKey: "segmentWfhModeText") as? String ?? titleWFHMode
            lblTitleSetFocus.stringValue = menuInfo.value(forKey: "menuItemSetFocusModesTitle") as? String ?? lblTitleSetFocus.stringValue
//            lblTitleWorkMode.stringValue = menuInfo.value(forKey: "titleWorkMode") as? String ?? lblTitleWorkMode.stringValue
        }
        
        segmentControlOfficeMode.setLabel(titleOfficeMode, forSegment: 0)// = "Office Mode"
        segmentControlOfficeMode.setLabel(titleWFHMode, forSegment: 1)//.label(forSegment: 1)// = "WFH Mode"//rodo text
        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "trialExpiredText") as? String{
                trialExpiredText = text
            }
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }
        }
        
        lblTitleReactivate.stringValue = itemReactivateTitle
        lblTitleEnterLicenseKey.stringValue = menuItemUpgradeNowTitle//itemEnterLicenseKeyTitle//
        lblTitlePreferences.stringValue = itemPreferences
        lblTitleExportStatistics.stringValue = itemExportStatisticsTitle
        lblTitleFocus.stringValue = itemFocusTitle
        lblTitleStartPomodoroMode.stringValue = itemStartPomodoroTitle
        lblTitleCheckForUpdates.stringValue = menuItemCheckForUpdatesTitle
        lblTitleQuit.stringValue = itemQuitTitle
        //        lblTitleEnableOfficeMode.stringValue = menuItemEnableOfficeModeTitle
        lblTitleStopHardcorePomodoroMode.stringValue = menuItemStopHardcorePomodoroTitle
        
        lblTitleAppName.stringValue = appName
        
        bottomLine.isHidden = true
        
        
        toolsMenu = NSMenu()
        menuItemStartBreak = NSMenuItem(title: lblTitleStartBreak.stringValue, action: #selector(btnStartBreakClicked(_:)), keyEquivalent: "")
        menuItemStartBreak.target = self
        toolsMenu.addItem(menuItemStartBreak)
        
        menuItemBrainDump = NSMenuItem(title: lblTitleBrainDump.stringValue, action: #selector(btnBrainDumpClicked(_:)), keyEquivalent: "")
        menuItemBrainDump.target = self
        toolsMenu.addItem(menuItemBrainDump)
        
        menuItemOpenToolbox = NSMenuItem(title: menuItemOpenToolboxTitle, action: #selector(openToolBoxClicked), keyEquivalent: "")
        menuItemOpenToolbox.target = self
        toolsMenu.addItem(menuItemOpenToolbox)
        
        menuItemFocusMusic = NSMenuItem(title: menuItemFocusMusicTitle, action: #selector(openAllTracksClicked), keyEquivalent: "")
        menuItemFocusMusic.target = self
        toolsMenu.addItem(menuItemFocusMusic)
        
        if let common = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            for i in 0..<arrFocusType.count{
                if let state = arrFocusType[i]["isDefault"] as? Bool{
                    if  state{
                        if let defaultFocusText = common.value(forKey: "defaultFocusText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                    }
                }
                if let state = arrFocusType[i]["isMeetings"] as? Bool{
                    if  state{
                        if let defaultFocusText = common.value(forKey: "meetingsFocusText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                    }
                }
                if let state = arrFocusType[i]["isLockedFocus"] as? Bool{
                    if  state{
                        if let defaultFocusText = common.value(forKey: "lockedFocusText") as? String{
                            arrFocusType[i]["name"] = defaultFocusText
                        }
                        
                    }
                }
            }
        }
        // load preferences window// // beacuse some times webview dose not load at first time in settings so here we are loading window to load webview before opening it
        if !(preferencesWindowControllerObj?.isWindowLoaded ?? false){
            preferencesWindowControllerObj?.loadWindow()
        }
        btnInfoOfficeModeTrackingArea = NSTrackingArea.init(rect: btnInfoOfficeMode.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnInfoOfficeMode.addTrackingArea(btnInfoOfficeModeTrackingArea!)
        
        
        let boundsOfficeMode = NSRect(x: segmentControlOfficeMode.frame.minX, y: segmentControlOfficeMode.frame.minY, width: segmentControlOfficeMode.frame.width/2, height: segmentControlOfficeMode.frame.height)
        let boundsWfhMode = NSRect(x: segmentControlOfficeMode.frame.midX, y: segmentControlOfficeMode.frame.minY, width: segmentControlOfficeMode.frame.width/2, height: segmentControlOfficeMode.frame.height)
        
        segmentOfficeModeTrackingArea = NSTrackingArea.init(rect: boundsOfficeMode, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        segmentControlOfficeMode.addTrackingArea(segmentOfficeModeTrackingArea!)
        
        
        segmentWfhModeTrackingArea = NSTrackingArea.init(rect: boundsWfhMode, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        segmentControlOfficeMode.addTrackingArea(segmentWfhModeTrackingArea!)
        
        
        
        btnInfoMeetingDetectionTrackingArea = NSTrackingArea.init(rect: btnMeetingDetection.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnMeetingDetection.addTrackingArea(btnInfoMeetingDetectionTrackingArea!)
    }
    @IBAction func btnMeetingDetectionClicked(_ sender: Any) {
        //        appdelegate!.showAlertFalseMicDetection()
    }
    @IBAction func btnSetFocusModesClicked(_ sender: Any) {
        showSetFocusWindow()
    }
    @IBAction func btnFalseDetectionClicked(_ sender: Any) {
        appdelegate!.popover.animates = false
        appdelegate!.popover.close()
        DispatchQueue.global().async {
            usleep(50000)
            DispatchQueue.main.async {
                appdelegate!.popover.animates = true
                appdelegate!.showAlertFalseMicDetection()
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == btnInfoOfficeModeTrackingArea{
            if SettingsManagerObject.isOfficeModeEnabled{
                showTooltip(sender: btnInfoOfficeMode, msg: toolTipOfficeMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
            }else{
                showTooltip(sender: btnInfoOfficeMode, msg: toolTipWfhMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
            }
        }else if event.trackingArea == btnInfoMeetingDetectionTrackingArea{
            var videoCallText = "Looks like you're in a video call. I won't interrupt you with micro-breaks during the meeting to avoid embarrassing screensharing moments. Enjoy the meeting!"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                videoCallText = common.value(forKey: "notificationVideoCallText") as? String ?? videoCallText
            }
            
            showTooltip(sender: btnMeetingDetection, msg: videoCallText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }else if event.trackingArea == segmentOfficeModeTrackingArea{
            showTooltip(sender: segmentControlOfficeMode, msg: toolTipOfficeMode, preferredEdge: NSRectEdge.minX, maxWidthVal:230)
        }else if event.trackingArea == segmentWfhModeTrackingArea{
            showTooltip(sender: segmentControlOfficeMode, msg: toolTipWfhMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == btnInfoOfficeModeTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }else if event.trackingArea == btnInfoMeetingDetectionTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }else if event.trackingArea == segmentOfficeModeTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }else if event.trackingArea == segmentWfhModeTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
    //    @objc func btnToggleClicked(notification: Notification) {
    //        if let state = notification.userInfo!["isOn"] as? Bool, let row = notification.userInfo!["index"] as? Int{
    //            print(row)
    //            print(state)
    //            if row == toggleButtonOfficeMode.statetag{
    //                btnEnableOfficeModeClicked(self)
    //            }
    //        }
    //    }
    override func viewWillDisappear() {//will not call if view is inside nsmenu
        
    }
    override func viewWillAppear() {//will not call if view is inside nsmenu but noe using popover so view will appear will work
        reloadData()
    }
    //Trial version - 7 of 7 trial days remaining
    //Your trial version has expired
    
    func checkPurchaseState(){
        if isPurchased == false{
            let daysremaining = daysLeft
            if daysremaining <= 0{
                lblTrialVersionInfo.stringValue = subscriptionExpiredText//trialExpiredText
                lblTrialVersionInfo.textColor = NSColor.systemRed
            }else{
                lblTrialVersionInfo.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")//"Trial version - \(daysremaining) of 7 trial days remaining"//
                lblTrialVersionInfo.textColor = buttonTitleColor
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
    }
    
    
    func reloadData(){

        //Show brain dump in main menu nav if the user has written something there#515
        var brainDumpText = ""
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            brainDumpText = notes
        }
        
        if brainDumpText.isEmpty{
            boxBrainDump.isHidden = true
            menuItemBrainDump.isHidden = false
        }else{
            boxBrainDump.isHidden = false
            menuItemBrainDump.isHidden = true
        }
        
        
        //
        
        boxCurrentTrack.isHidden = true
        if allTracksVcObj != nil{
            //   if allTracksVcObj?.currentSound != nil{
            //                if allTracksVcObj?.currentSound?.isPlaying ?? false{
            //                    allTracksVcObj?.currentSound?.pause()
            //                }else{// if not playing it means it is paused beacuse if any one stop music we make it nil
            //
            //                }
            
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
            
            //  }
        }
        
        if arrAllTracks.count == 0{
            menuItemFocusMusic.isHidden = true
        }else{
            menuItemFocusMusic.isHidden = false
        }
        
        if currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_MORNING_HABIT_{
            boxResumeHabits.isHidden = false
        }else{
            boxResumeHabits.isHidden = true
        }
        
        if appdelegate!.isUserOnMeeting{
            boxMeetingDetection.isHidden = false
        }else{
            boxMeetingDetection.isHidden = true
        }
        
        if isAppEnable{
            if isShutOffTimeGoing(){
                menuItemStartBreak.isHidden = true
            }else{
                if isHabitAlreadyShowed{
                    if currentState == ._MORNING_HABIT_ || currentState == ._ACTIVITY_ || arrAllbreakActivities.count == 0 || currentState == ._SPECIAL_ACTIVITY_{
                        menuItemStartBreak.isHidden = true
                    }else{
                        menuItemStartBreak.isHidden = false
                    }
                }else{
                    menuItemStartBreak.isHidden = true
                }
            }
        }else{
            menuItemStartBreak.isHidden = true
        }
        
        
        if upgradeButtonWasClicked{
            upgradeButtonWasClicked = false
            appdelegate?.renewToken(window: self.view.window!, completionHandler: {
                DispatchQueue.main.async {
                    self.checkPurchaseState()
                    
                }
                
            })
        }
        
        
        checkPurchaseState()
        
        if !isAppEnable{
            boxReactivate.isHidden = false
        }else{
            boxReactivate.isHidden = true
        }
        
        
        
        
        if isFocusModeOnOrPaused(){
            boxStartPomodoroMode.isHidden = true
            boxStopHardcorePomodoroMode.isHidden = true
        }else{
            if isHardCorePomodoroModeOn{
                boxStopHardcorePomodoroMode.isHidden = false
                boxStartPomodoroMode.isHidden = true
            }else{
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_{
                    boxStartPomodoroMode.isHidden = true
                }else{
                    boxStartPomodoroMode.isHidden = false
                }
                boxStopHardcorePomodoroMode.isHidden = true
            }
        }
        
        
        resetViewHeight()
        
        tblViewFocusMode.reloadData()
        
        
        if SettingsManagerObject.isOfficeModeEnabled{
            //            boxCheckMark.isHidden = false
            //            toggleButtonOfficeMode.isOn = true
            //            lblTitleEnableOfficeMode.stringValue = menuItemEnableOfficeModeTitle
            
            segmentControlOfficeMode.setSelected(true, forSegment: 0)
        }else{
            //            boxCheckMark.isHidden = true
            //            toggleButtonOfficeMode.isOn = false
            //            lblTitleEnableOfficeMode.stringValue = menuItemDisableOfficeModeTitle
            
            segmentControlOfficeMode.setSelected(true, forSegment: 1)
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
            boxSetFocusModes.isHidden = false
        }else{
            boxSetFocusModes.isHidden = true
        }
    }
    func resetViewHeight(){
        //        35 16
        //        18
        //        16
        
        print("tblViewFocusMode resetViewHeight1111")
        var height = 34
        if isHardCorePomodoroModeOn || UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
            height += 32 // only one focus mode will be visible which is on for hardcore pomodoro mode
        }else{
            if arrFocusType.count > 6{
                height += (6*32)
            }else{
                height += (arrFocusType.count * 32)
            }
            
        }
        
        if isFocusModeOnOrPaused(){
            //height += 60
            height += 19 //on label space
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
            height += 34 //set focus mode button space
        }
        
        let cgFlotHeight = CGFloat(height)
        if focusModeBoxHeight.constant != cgFlotHeight{
            focusModeBoxHeight.constant = cgFlotHeight
        }
        print("tblViewFocusMode resetViewHeight")
    }
    @IBAction func btnReactivateClicked(_ sender: Any) {
        appdelegate?.menuItem_Reactivate()
    }
    @IBAction func btnEnterLicenseKeyClicked(_ sender: Any) {
        //        appdelegate?.menuItemEnterLicenseKey()
        showUpgradeNowWindow()
    }
    
    @IBAction func btnPreferencesClicked(_ sender: Any) {
        //        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
        //            showUpgradeNowWindow()
        //            return;
        //        }
        appdelegate?.menuItem_Preferences()
    }
    @IBAction func btnStartBreakClicked(_ sender: Any) {
        addLog(text: "button Start Break Clicked")
        if !isMainWindowLodded{
            mainWindowControllerObj?.loadWindow()
        }
        mainViewControllerObj?.executeBreakActivities()
    }
    @IBAction func btnBrainDumpClicked(_ sender: Any) {
        addLog(text: "button Brain Dump Clicked")
        showBrainDumpWindow()
    }
    
    @objc func openToolBoxClicked(){
        addLog(text: "openToolBoxClicked")
        showToolboxWindow()
    }
    
    @objc func openAllTracksClicked(){
        addLog(text: "openAllTracksClicked")
        showAllTracksWindow()
    }
    @IBAction func btnExportStatisticsClicked(_ sender: Any) {
        if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
            return;
        }
        //        appdelegate!.statusItem.menu?.cancelTracking()
        //        self.perform(#selector(menuItem_ExportStatistics), with: nil, afterDelay: 0)
    }
    
    @IBAction func btnStartPomodoroModeClicked(_ sender: Any) {
        if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
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
    var enterPasswordVcObj: enterPasswordVc?
    var enterPasswordWcObj: commonWindowController?
    func showPasswordWindow(){
        
        if self.enterPasswordVcObj == nil{
            self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc
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
        if isFocusModeOnOrPaused(){
            showAbortingFocusModeVc()
        }else{
            isHardCorePomodoroModeOn = false
        }
    }
    @IBAction func btnStopHardcorePomodoroModeClicked(_ sender: Any) {
        if isHardCorePomodoroModeOn{
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                    showPasswordWindow()
                    addLog(text: "Showing enter password view from hardcodre pomodoro stop from menu")
                }else{
                    isHardCorePomodoroModeOn = false
                }
            }else{
                isHardCorePomodoroModeOn = false
            }
        }else{
            boxStopHardcorePomodoroMode.isHidden = true
        }
        
    }
    
    
    @IBAction func btnCheckForUpdatesClicked(_ sender: Any) {
        addLog(text: "btnCheckForUpdatesClicked")//
        appdelegate!.updater?.checkForUpdates(self)
    }
    
    @IBAction func btnQuitClicked(_ sender: Any) {
        addLog(text: "menu item Quit clicked by user")
        if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            appdelegate?.menuItem_Quit()
            return;
        }
        if quittingWcObj != nil{
            if quittingWcObj?.window?.isVisible ?? false{
                addLog(text: "Quit window already visible")
                return
            }
        }
        
        showQuitWindow()
        
        //        appdelegate?.menuItem_Quit()
    }
    
    @IBAction func btnSegmentControlClicked(_ sender: Any) {
        btnEnableOfficeModeClicked(self)
    }
    
    @IBAction func btnEnableOfficeModeClicked(_ sender: Any) {
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
            allApiObject.capturePosthog(event: "disable-office-mode", metadata: [:])
            //            boxCheckMark.isHidden = true
            //            toggleButtonOfficeMode.isOn = false
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
            //            lblTitleEnableOfficeMode.stringValue = menuItemDisableOfficeModeTitle
            
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
            
            arrAllbreakActivities.append(breakActivity(id:id,name: officeFriendlyActivityName, durationSeconds: 20, IncludeInEveryBreak: false, urlsArray: [], logQuantity:false, isRandomChoice: false, choices: [], logQuantityQuestion: "", openSpecificApps: false, allowUrls: [], allowApps: [], isOfficeFriendly: true, allowedFocusMode: "", logQuantityType: "",activity_sequence_id:activity_sequence_id, take_notes: ""))
            
            
            
            
            
            
            allApiObject.isSettingsValid(settings: mutableDic, completionHandler: {dic,statusCode  in
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
    @IBAction func officeModeInfoIconClicked(_ sender: Any) {
        addLog(text: "office Mode Info Icon Clicked")
        if SettingsManagerObject.isOfficeModeEnabled{
            showTooltip(sender: sender as! NSView, msg: toolTipOfficeMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }else{
            showTooltip(sender: sender as! NSView, msg: toolTipWfhMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
        
    }
    @IBAction func btnToolsClicked(_ sender: Any) {
        addLog(text: "menu item tools clicked")
        
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
        }else if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentHabitPlaying != nil{
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
            menuItemOpenToolbox.isHidden = false
        }else{
            menuItemOpenToolbox.isHidden = true
        }
        toolsMenu.minimumWidth = boxTools.frame.width
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y )
        toolsMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
    
    @IBAction func btnResumeHabitsClicked(_ sender: Any) {
        currentState = ._NOTHING_
        if mainViewControllerObj != nil{
            if mainViewControllerObj?.postponeTimer != nil{
                mainViewControllerObj?.postponeTimer?.invalidate()
                mainViewControllerObj?.postponeTimer = nil
                if smallCountDownWcObj != nil{
                    if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                        smallCountDownVcObj?.closeTimerBox()
                    }
                }
            }
            if mainViewControllerObj?.postponeNotificationTimer != nil{
                mainViewControllerObj?.postponeNotificationTimer?.invalidate()
                mainViewControllerObj?.postponeNotificationTimer = nil
            }
        }
        appdelegate?.backgroundThread()
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
}

//
extension menuViewController: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("reload")
        let isFocusModeOn = isFocusModeOn()
        let isFocusModePaused = isFocusModePaused()
        if isFocusModeOn || isFocusModePaused{
            lblOn.isHidden = false
            if isFocusTimeType == ._HOUR_{
                
                if isFocusModeOn{
                    if let date = endFocusModeTime{
                        let secondsBetween = date.timeIntervalSince(Date())
                        let stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
                        
                        var titleTimeRemainingText = "Time remaining:"
                        
                        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
                            titleTimeRemainingText = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? titleTimeRemainingText
                        }
                        
                        titleTimeRemainingText = titleTimeRemainingText + " " + getStringTimeFromSeconds(seconds: Int(secondsBetween))
                        lblOn.stringValue = titleTimeRemainingText + " " + "(\(untilTimeText.replacingOccurrences(of: "<TIME>", with: stringTime)))"//"On Until \(stringTime)"
                        
                    }else{
                        lblOn.stringValue = onText
                    }
                }else {
                    let secondsBetween = appdelegate!.remainingFocusModeSecondsAfterPaused
                    
                    var titleTimeRemainingText = "Time remaining:"
                    
                    if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
                        titleTimeRemainingText = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? titleTimeRemainingText
                    }
                    
                    titleTimeRemainingText = titleTimeRemainingText + " " + getStringTimeFromSeconds(seconds: Int(secondsBetween))
                    lblOn.stringValue = titleTimeRemainingText
                }
            }else if isFocusTimeType == ._TILL_SHUTOFF_{// will never execute beaacuse till shutoff type is removed
                if let date = shutOffTime{
                    //let stringTime = getStringFromDate(date: date, dateFormat: "HH:mm a")
                    var hour = date.hour
                    let minute = date.minute
                    if hour > 12{
                        hour = hour - 12
                    }
                    var hourString = "\(hour)"
                    var minuteString = "\(minute)"
                    if hourString.count == 1{
                        hourString = "0"+hourString
                    }
                    if minuteString.count == 1{
                        minuteString = "0"+hourString
                    }
                    lblOn.stringValue = untilTimeText.replacingOccurrences(of: "<TIME>", with: "\(hourString):\(minuteString) PM")//"On Until \(hourString):\(minuteString) PM"
                }else{
                    lblOn.stringValue = ""
                }
            }else if isFocusTimeType == ._NONE_{
                lblOn.stringValue = onText
            }
        }else{
            lblOn.isHidden = true
        }
        if isHardCorePomodoroModeOn{
            lblTitleFocus.stringValue = itemHardcorePomodoroTitle
            return 1
        }
        lblTitleFocus.stringValue = itemFocusTitle
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
            return 1
        }
        return arrFocusType.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocus"), owner: nil) as? tblCellFocus {
            
            cell.boxtitle.isTableView = true
            
            var cRow = row
            if isHardCorePomodoroModeOn{
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["name"] as? String == hardcodePmodoroFocusModeName{
                        cRow = i
                        break;
                    }
                }
            }
            
            if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{//Don’t ask them to set up focus modes upfront
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["isDefault"] as? Bool == true{
                        cRow = i
                        break;
                    }
                }
            }
            
            cell.boxtitle.tagValue = cRow
            
            
            if let name = arrFocusType[cRow]["name"] as? String{
                cell.lblTitle.stringValue = name
            }else{
                cell.lblTitle.stringValue = ""
            }
            cell.imgViewAppIcon.isHidden = false
            if arrFocusType[cRow]["isOn"] as? Bool == true{
                cell.imgViewAppIcon.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                cell.lblTitle.font = NSFont.boldSystemFont(ofSize: cell.lblTitle.font?.pointSize ?? 12)
                cell.lblTitle.textColor = buttonTitleColor
                if let color = arrFocusType[cRow]["color"] as? String{
                    cell.boxColor.fillColor = HexToColor(hexString: color)
                }
                
                if whatToAchieveInFocusBlock.isEmpty{
                    cell.lblIntension.isHidden = true
                }else{
                    cell.lblIntension.isHidden = false
                    cell.lblIntension.stringValue = whatToAchieveInFocusBlock
                }
            }else if arrFocusType[cRow]["isPaused"] as? Bool == true{
                cell.boxColor.fillColor = .tertiaryLabelColor
                cell.imgViewAppIcon.image = NSImage(named: NSImage.touchBarPlayPauseTemplateName)
                cell.lblIntension.isHidden = true
                cell.lblTitle.font = NSFont.systemFont(ofSize: cell.lblTitle.font?.pointSize ?? 12)
                cell.lblTitle.textColor = NSColor.black
            }else{//on NSTouchBarPlayTemplate
                cell.boxColor.fillColor = .tertiaryLabelColor
                cell.imgViewAppIcon.image = NSImage(named: NSImage.Name("NSTouchBarPlayTemplate"))
                cell.lblIntension.isHidden = true
                cell.lblTitle.font = NSFont.systemFont(ofSize: cell.lblTitle.font?.pointSize ?? 12)
                cell.lblTitle.textColor = NSColor.black
            }
            
            cell.btnEditFocusMode.isHidden = true
            cell.btnEditFocusMode.target = self
            cell.btnEditFocusMode.tag = cRow
            cell.btnEditFocusMode.action = #selector(btnEditFocusModeClicked(sender:))
            
            
            
            if arrFocusType[cRow]["isLockedFocus"] as? Bool == true{
                cell.btnEditFocusMode.image = NSImage(named: NSImage.infoName)
            }else{
                
                cell.btnEditFocusMode.image = NSImage(named: NSImage.Name("three-dots"))
            }
            
            cell.boxtitle.fillColor = .clear
            return cell
        }
        
        return NSTableCellView()
    }
    
    @objc func btnEditFocusModeClicked(sender:NSButton){
        addLog(text: "btn Edit FocusMode Clicked from menu")
        
        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            if trialExpiredNagWcObj != nil{
                if trialExpiredNagWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            showUpgradeNowWindow()
            return;
        }
        
        if arrFocusType[sender.tag]["isLockedFocus"] as? Bool == true{
            
            var msg = "Use this if you want to focus on using one app/reading one article. We'll detect the current app + site you have open and block everything else."
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                msg = menuInfo.value(forKey: "toolTipLockedFocus") as? String ?? msg
            }
            
            showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
            return;
        }
        
        var shouldShowPassword = true
        if preferencesWindowControllerObj?.window?.isVisible ?? false{
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = 1
                addLog(text: "")
            }
            shouldShowPassword = false
        }else{
            preferencesWindowControllerObj?.showWindow(self)
        }
        addLog(text: "Showing preferences")
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = 1
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil && shouldShowPassword{
                tabview.view.addSubview(Focus_Bear.enterPasswordVcObj!.view)
                tabview.view.addConstraints(subView: Focus_Bear.enterPasswordVcObj!.view)
                Focus_Bear.enterPasswordVcObj?.parentVc = nil
                addLog(text: "Showing enter password view")
            }
        }
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                focusPreferencesVcObj?.tblViewFocusType.selectRowIndexes(IndexSet(integer: sender.tag), byExtendingSelection: false)
                focusPreferencesVcObj?.tblViewFocusType.scrollRowToVisible(sender.tag)
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 32
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        
    }
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}












