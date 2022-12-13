//
//  menuViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/02/22.

//

import Cocoa

class menuViewController: NSViewController {

    
    
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
    @IBOutlet weak var toggleButtonOfficeMode: CToggleButton!
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
    @IBOutlet weak var lblTitleEnableOfficeMode: NSTextField!
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
    
    var btnInfoOfficeModeTrackingArea: NSTrackingArea?
    
    var toolsMenu:NSMenu!
    
//    var selectedIndex = -1
    
    var onText = "On"
    var untilTimeText = "On Until <TIME>"
    
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
    var menuItemOpenToolbox: NSMenuItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        boxStartBreak.isHidden = true
        boxBrainDump.isHidden = true
        boxLockCurrentFocus.isHidden = true
        boxCheckForUpdates.isHidden = true
        boxExportStatistics.isHidden = true
        boxTitle.fillColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
        boxFocusMode.wantsLayer = true
        boxFocusMode.layer?.cornerRadius = boxPreferences.cornerRadius
        toggleButtonOfficeMode.statetag = 111
        toggleButtonOfficeMode.wantsLayer = true
        toggleButtonOfficeMode.shadow = NSShadow()
        toggleButtonOfficeMode.layer?.shadowOpacity = 0.3
        toggleButtonOfficeMode.layer?.shadowColor = NSColor.black.cgColor
        toggleButtonOfficeMode.layer?.shadowOffset = NSMakeSize(0, -2)
        toggleButtonOfficeMode.layer?.shadowRadius = 3
        NotificationCenter.default.addObserver(self, selector: #selector(btnToggleClicked), name: Notification.Name("toggle"), object: nil)
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
        
        lblTitleStartBreak.stringValue = "Start Break"
        lblTitleBrainDump.stringValue = "Brain Dump"
        var menuItemStopHardcorePomodoroTitle = "Stop Hardcore Pomodoro Mode"
        
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
            
//            lblTitleLockCurrentFocus.stringValue = menuInfo.value(forKey: "menuItemLockFocusTitle") as? String ?? lblTitleLockCurrentFocus.stringValue
        }
        
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
        lblTitleEnableOfficeMode.stringValue = menuItemEnableOfficeModeTitle
        lblTitleStopHardcorePomodoroMode.stringValue = menuItemStopHardcorePomodoroTitle
        
        lblTitleAppName.stringValue = appName
        
        bottomLine.isHidden = true
        
        
        toolsMenu = NSMenu()
        menuItemStartBreak = NSMenuItem(title: lblTitleStartBreak.stringValue, action: #selector(btnStartBreakClicked(_:)), keyEquivalent: "")
        menuItemStartBreak.target = self
        toolsMenu.addItem(menuItemStartBreak)
        
        let menuItemBrainDump = NSMenuItem(title: lblTitleBrainDump.stringValue, action: #selector(btnBrainDumpClicked(_:)), keyEquivalent: "")
        menuItemBrainDump.target = self
        toolsMenu.addItem(menuItemBrainDump)
     
        menuItemOpenToolbox = NSMenuItem(title: menuItemOpenToolboxTitle, action: #selector(openToolBoxClicked), keyEquivalent: "")
        menuItemOpenToolbox.target = self
        toolsMenu.addItem(menuItemOpenToolbox)
        
        
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
        
    }
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == btnInfoOfficeModeTrackingArea{
            if SettingsManagerObject.isOfficeModeEnabled{
                showTooltip(sender: btnInfoOfficeMode, msg: toolTipOfficeMode, preferredEdge: NSRectEdge.maxX)
            }else{
                showTooltip(sender: btnInfoOfficeMode, msg: toolTipWfhMode, preferredEdge: NSRectEdge.maxX)
            }
        }
    }
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == btnInfoOfficeModeTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
    @objc func btnToggleClicked(notification: Notification) {
        if let state = notification.userInfo!["isOn"] as? Bool, let row = notification.userInfo!["index"] as? Int{
            print(row)
            print(state)
            if row == toggleButtonOfficeMode.statetag{
                btnEnableOfficeModeClicked(self)
            }
        }
    }
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
        if isAppEnable{
            if isShutOffTimeGoing(){
                menuItemStartBreak.isHidden = true
//                boxStartBreak.isHidden = true
            }else{
                if isHabitAlreadyShowed{
                    if currentState == ._MORNING_HABIT_ || currentState == ._ACTIVITY_{
//                        boxStartBreak.isHidden = true
                        menuItemStartBreak.isHidden = true
                    }else{
//                        boxStartBreak.isHidden = false
                        menuItemStartBreak.isHidden = false
                    }
                }else{
//                    boxStartBreak.isHidden = true
                    menuItemStartBreak.isHidden = true
                }
            }
        }else{
//            boxStartBreak.isHidden = true
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
        

        
        
        if isFocusModeOn(){
            boxStartPomodoroMode.isHidden = true
            boxStopHardcorePomodoroMode.isHidden = true
//            boxLockCurrentFocus.isHidden = true
        }else{
            if isHardCorePomodoroModeOn{
//                boxLockCurrentFocus.isHidden = true
                boxStopHardcorePomodoroMode.isHidden = false
                boxStartPomodoroMode.isHidden = true
            }else{
//                boxLockCurrentFocus.isHidden = false
                boxStartPomodoroMode.isHidden = false
                boxStopHardcorePomodoroMode.isHidden = true
            }
        }
        
        
        resetViewHeight()

        tblViewFocusMode.reloadData()
        
        
        if SettingsManagerObject.isOfficeModeEnabled{
//            boxCheckMark.isHidden = false
            toggleButtonOfficeMode.isOn = true
            lblTitleEnableOfficeMode.stringValue = menuItemEnableOfficeModeTitle
        }else{
//            boxCheckMark.isHidden = true
            toggleButtonOfficeMode.isOn = false
            lblTitleEnableOfficeMode.stringValue = menuItemDisableOfficeModeTitle
        }
    }
    func resetViewHeight(){
//        35 16
//        18
//        16
        
        print("tblViewFocusMode resetViewHeight1111")
        var height = 34
        if isHardCorePomodoroModeOn{
            height += 32 // only one focus mode will be visible which is on for hardcore pomodoro mode
        }else{
            if arrFocusType.count > 6{
                height += (6*32)
            }else{
                height += (arrFocusType.count * 32)
            }
            
        }
        
        if isFocusModeOn(){
            //height += 60
            height += 19 //on label space
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
        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            showUpgradeNowWindow()
            return;
        }
        appdelegate?.menuItem_Preferences()
    }
    @IBAction func btnStartBreakClicked(_ sender: Any) {
        addLog(text: "button Start Break Clicked")
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
    
    @IBAction func btnExportStatisticsClicked(_ sender: Any) {
        if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            showUpgradeNowWindow()
            return;
        }
//        appdelegate!.statusItem.menu?.cancelTracking()
//        self.perform(#selector(menuItem_ExportStatistics), with: nil, afterDelay: 0)
    }
     
    @IBAction func btnStartPomodoroModeClicked(_ sender: Any) {
        if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
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
        if isFocusModeOn(){
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
    
    
    @IBAction func btnEnableOfficeModeClicked(_ sender: Any) {
        if isPurchased == false && daysLeft <= 0{//UserDefaults.standard.object(forKey: "trialExpired") != nil{
            showUpgradeNowWindow()
            return;
        }
        
        addLog(text: "menu item Enable Office Mode by user")
        if SettingsManagerObject.isOfficeModeEnabled{
            SettingsManagerObject.isOfficeModeEnabled = false
            allApiObject.capturePosthog(event: "disable-office-mode", metadata: [:])
//            boxCheckMark.isHidden = true
            toggleButtonOfficeMode.isOn = false
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
            lblTitleEnableOfficeMode.stringValue = menuItemDisableOfficeModeTitle
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
        addLog(text: "enableOfficeMode")//
        let alert = NSAlert()
        alert.setSharingType()
        var officeModeEnabledSuccessfullyText = "Ok! I'll just prompt you to do activities that won't weird other people out (doing handstand pushups in the office might raise a few eyebrows)."
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            officeModeEnabledSuccessfullyText = menuInfo.value(forKey: "officeModeEnabledSuccessfullyText") as? String ?? officeModeEnabledSuccessfullyText
        }
        alert.messageText = officeModeEnabledSuccessfullyText
        alert.addButton(withTitle: buttonOkText)
        _ = alert.runModal()
        SettingsManagerObject.isOfficeModeEnabled = true
//        boxCheckMark.isHidden = false
        toggleButtonOfficeMode.isOn = true
        allApiObject.capturePosthog(event: "enable-office-mode", metadata: [:])
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
        lblTitleEnableOfficeMode.stringValue = menuItemEnableOfficeModeTitle
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
        let activity_sequence_id = arrAllbreakActivities.first?.activity_sequence_id ?? ""
        if var breakActivities = mutableDic.value(forKey: "break_activities") as? [NSDictionary] {
            let activityDic: NSMutableDictionary = ["id":id, "name":"Stand up and stretch", "duration_seconds":20, "is_office_friendly":true, "activity_sequence_id":activity_sequence_id]
            breakActivities.append(activityDic)
            mutableDic["break_activities"] = breakActivities
            
            arrAllbreakActivities.append(breakActivity(id:id,name: "Stand up and stretch", durationSeconds: 20, IncludeInEveryBreak: false, urlsArray: [], logQuantity:false, isRandomChoice: false, choices: [], logQuantityQuestion: "", openSpecificApps: false, allowUrls: [], allowApps: [], isOfficeFriendly: true, allowedFocusMode: "", logQuantityType: "",activity_sequence_id:activity_sequence_id))
            
            
            
            
            
            
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

//        do {
//            let data = try (JSONSerialization.data(withJSONObject: mutableDic, options: .prettyPrinted))
//            if let str = String(data: data, encoding: String.Encoding.utf8){
//                UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
//            }
//        } catch let error as NSError {
//            print(error)
//        }
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
            showTooltip(sender: sender as! NSView, msg: toolTipOfficeMode, preferredEdge: NSRectEdge.maxX)
        }else{
            showTooltip(sender: sender as! NSView, msg: toolTipWfhMode, preferredEdge: NSRectEdge.maxX)
        }
        
    }
    @IBAction func btnToolsClicked(_ sender: Any) {
        addLog(text: "menu item tools clicked")
        if isFocusModeOn(){
            var shouldShowToolBoxWindow = false
            
            if !isAllowedAllAppsInFocus && appdelegate!.allowAppsPath.count != 0{
                shouldShowToolBoxWindow = true
            }
            
            if !isAllowedAllUrlsInFocus && appdelegate!.arrAllowedUrlsForFocus.count != 0 && isAllowedListApproachInFocus{
                shouldShowToolBoxWindow = true
            }
            if shouldShowToolBoxWindow{
                menuItemOpenToolbox.isHidden = false
            }else{
                menuItemOpenToolbox.isHidden = true
            }
        }else{
            menuItemOpenToolbox.isHidden = true
        }
        toolsMenu.minimumWidth = boxTools.frame.width
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y )
        toolsMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
    
}

//
extension menuViewController: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("reload")
        if isFocusModeOn(){
            lblOn.isHidden = false
            if isFocusTimeType == ._HOUR_{
                if let date = endFocusModeTime{
                    let stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
                    lblOn.stringValue = untilTimeText.replacingOccurrences(of: "<TIME>", with: stringTime)//"On Until \(stringTime)"
                }else{
                    lblOn.stringValue = onText
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
        return arrFocusType.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocus"), owner: nil) as? tblCellFocus {

            cell.boxtitle.isTableView = true
            
            var cRow = row
            if isHardCorePomodoroModeOn{
                cRow = hardcodePmodoroFocusModeIndex
            }
            
            cell.boxtitle.tagValue = cRow
            
            
            if let name = arrFocusType[cRow]["name"] as? String{
                cell.lblTitle.stringValue = name
            }else{
                cell.lblTitle.stringValue = ""
            }
            cell.imgViewAppIcon.isHidden = false
            if arrFocusType[cRow]["isOn"] as? Bool == false{
                cell.boxColor.fillColor = .tertiaryLabelColor
                cell.imgViewAppIcon.image = NSImage(named: NSImage.Name("NSTouchBarPlayTemplate"))
                cell.lblIntension.isHidden = true
                cell.lblTitle.font = NSFont.systemFont(ofSize: cell.lblTitle.font?.pointSize ?? 12)
                cell.lblTitle.textColor = NSColor.black
            }else{//on NSTouchBarPlayTemplate
                cell.imgViewAppIcon.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
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
            }

            cell.btnEditFocusMode.isHidden = true
            cell.btnEditFocusMode.target = self
            cell.btnEditFocusMode.tag = row
            cell.btnEditFocusMode.action = #selector(btnEditFocusModeClicked(sender:))
            
            cell.boxtitle.fillColor = .clear
            return cell
        }
        
        return NSTableCellView()
    } 
    @objc func btnEditFocusModeClicked(sender:NSButton){
        addLog(text: "btn Edit FocusMode Clicked from menu")
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
        //        if arrFocusType[row]["isOn"] as? Bool == false{
        //            return 32
        //        }else{
        //            return 92
        //        }
        return 32
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        
    }
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}






        

        
        

    
