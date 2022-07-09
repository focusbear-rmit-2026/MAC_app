//
//  menuViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/02/22.

//

import Cocoa

class menuViewController: NSViewController {

    
    @IBOutlet weak var boxCheckMark: NSBox!
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
    @IBOutlet weak var boxStartPomodoroMode: customBox!
    @IBOutlet weak var boxCheckForUpdates: customBox!
    @IBOutlet weak var boxQuit: customBox!
    @IBOutlet weak var boxExportStatistics: customBox!
    @IBOutlet weak var boxPreferences: customBox!
    @IBOutlet weak var boxStopHardcorePomodoroMode: customBox!
    
    @IBOutlet weak var boxEnterLicenseKey: customBox!
    @IBOutlet weak var boxReactivate: customBox!
    @IBOutlet weak var tblViewFocusMode: NSTableView!
    @IBOutlet weak var boxEnableOfficeMode: customBox!
    
    
//    var selectedIndex = -1
    
    var onText = "On"
    var untilTimeText = "On Until <TIME>"
    
    var trialExpiredText = "Your trial has expired!"
    var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
    var itemFocusTitle = "Focus"
    var itemHardcorePomodoroTitle = "Hardcore Pomodoro Mode"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        
        var itemReactivateTitle = "Reactivate"
        var itemEnterLicenseKeyTitle = "Enter License Key"
        

        var itemPreferences = "Preferences"
        var itemExportStatisticsTitle = "Export Statistics"
        
        var itemQuitTitle = "Quit"
        var itemStartPomodoroTitle = "Start Pomodoro Mode"
        var menuItemCheckForUpdatesTitle = "Check for updates"
        var menuItemEnableOfficeModeTitle = "Enable office mode"
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
            untilTimeText = menuInfo.value(forKey: "untilTimeText") as? String ?? untilTimeText
            onText = menuInfo.value(forKey: "onText") as? String ?? onText
            itemHardcorePomodoroTitle = menuInfo.value(forKey: "menuItemHardcorePomodoroModeTitle") as? String ?? itemHardcorePomodoroTitle
            menuItemStopHardcorePomodoroTitle = menuInfo.value(forKey: "menuItemStopHardcorePomodoroTitle") as? String ?? menuItemStopHardcorePomodoroTitle
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
        lblTitleEnterLicenseKey.stringValue = itemEnterLicenseKeyTitle
        lblTitlePreferences.stringValue = itemPreferences
        lblTitleExportStatistics.stringValue = itemExportStatisticsTitle
        lblTitleFocus.stringValue = itemFocusTitle
        lblTitleStartPomodoroMode.stringValue = itemStartPomodoroTitle
        lblTitleCheckForUpdates.stringValue = menuItemCheckForUpdatesTitle
        lblTitleQuit.stringValue = itemQuitTitle
        lblTitleEnableOfficeMode.stringValue = menuItemEnableOfficeModeTitle
        lblTitleStopHardcorePomodoroMode.stringValue = menuItemStopHardcorePomodoroTitle
        
        bottomLine.isHidden = true
        
    }
    
    override func viewWillDisappear() {//will not call if view is inside nsmenu
        
    }
    override func viewWillAppear() {//will not call if view is inside nsmenu
        
    }
    //Trial version - 7 of 7 trial days remaining
    //Your trial version has expired
    func reloadData(){
        if isPurchased == false{
            var daysremaining = 0
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
                let secondsBetween = Date().timeIntervalSince(date)
                let numberOfDays_afterinstall = Int((secondsBetween) / 86400)
                daysremaining = daysFreeTrial-numberOfDays_afterinstall
                if daysremaining < 0 {
                    daysremaining = 0
                }
                if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                    daysremaining = 0
                }
                if daysremaining == 0{
                    if UserDefaults.standard.object(forKey: "trialExpired") == nil{
                        UserDefaults.standard.set(true, forKey: "trialExpired")
                    }
                }
            }else{
                daysremaining = daysFreeTrial
                
            }
            
            if daysremaining == 0{
                lblTrialVersionInfo.stringValue = trialExpiredText
                lblTrialVersionInfo.textColor = NSColor.systemRed
            }else{
                lblTrialVersionInfo.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")//"Trial version - \(daysremaining) of 7 trial days remaining"//
                lblTrialVersionInfo.textColor = NSColor.secondaryLabelColor
            }
        }else{
            UserDefaults.standard.removeObject(forKey: "trialExpired")
        }
    
        boxQuit.fillColor = .clear
        boxExportStatistics.fillColor = .clear
        boxPreferences.fillColor = .clear
        boxEnterLicenseKey.fillColor = .clear
        boxReactivate.fillColor = .clear
        boxEnableOfficeMode.fillColor = .clear
        if !isAppEnable{
            boxReactivate.isHidden = false
        }else{
            boxReactivate.isHidden = true
        }
        
        if isPurchased == false{
            boxEnterLicenseKey.isHidden = false
        }else{
            boxEnterLicenseKey.isHidden = true
        }
        
        
        if isFocusModeOn(){
            boxStartPomodoroMode.isHidden = true
            boxStopHardcorePomodoroMode.isHidden = true
        }else{
            if isHardCorePomodoroModeOn{
                boxStopHardcorePomodoroMode.isHidden = false
                boxStartPomodoroMode.isHidden = true
            }else{
                boxStartPomodoroMode.isHidden = false
                boxStopHardcorePomodoroMode.isHidden = true
            }
        }
        
        
        resetViewHeight()

        tblViewFocusMode.reloadData()
        
        
        if isOfficeModeEnabled{
            boxCheckMark.isHidden = false
        }else{
            boxCheckMark.isHidden = true
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
            height += (arrFocusType.count * 32)
        }
        
        if isFocusModeOn(){
            //height += 60
            height += 19 //on label space
        }
        focusModeBoxHeight.constant = CGFloat(height)
        print("tblViewFocusMode resetViewHeight")
    }
    @IBAction func btnReactivateClicked(_ sender: Any) {
        appdelegate?.menuItem_Reactivate()
    }
    @IBAction func btnEnterLicenseKeyClicked(_ sender: Any) {
        appdelegate?.menuItemEnterLicenseKey()
    }
//    @IBAction func btnSettingsClicked(_ sender: Any) {
//        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//            activationWindowControllerObj?.showSevenDayTrialVc()
//            return;
//        }
//        appdelegate?.menuItem_ChangeJson()
//    }
    @IBAction func btnPreferencesClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            activationWindowControllerObj?.showSevenDayTrialVc()
            return;
        }
        appdelegate?.menuItem_Preferences()
    }
    @IBAction func btnExportStatisticsClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            activationWindowControllerObj?.showSevenDayTrialVc()
            return;
        }
        appdelegate?.menuItem_ExportStatistics()
    }
    @IBAction func btnStartPomodoroModeClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            activationWindowControllerObj?.showSevenDayTrialVc()
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
            if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{
//                if self.enterPasswordVcObj == nil{
//                    self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc
//                }
//                self.presentAsModalWindow(enterPasswordVcObj!)
//                enterPasswordVcObj?.parentVc = self
//                DispatchQueue.global().async {
//                    DispatchQueue.main.async {
//                        self.enterPasswordVcObj?.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
//                    }
//                }
                showPasswordWindow()
                addLog(text: "Showing enter password view from hardcodre pomodoro stop from menu")
            }else{
                isHardCorePomodoroModeOn = false
            }
        }else{
            boxStopHardcorePomodoroMode.isHidden = true
        }
        
    }
    //    @IBAction func btnFocusPreferencesClicked(_ sender: Any) {
//        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//            activationWindowControllerObj?.showSevenDayTrialVc()
//            return;
//        }
//        preferencesWindowControllerObj?.showWindow(self)
//        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//            tabview.selectedTabViewItemIndex = 1
//        }
//        NSApplication.shared.activate(ignoringOtherApps: true)
//    }
    
    @IBAction func btnCheckForUpdatesClicked(_ sender: Any) {
        appdelegate!.updater?.checkForUpdates(self)
    }
    
    @IBAction func btnQuitClicked(_ sender: Any) {
        addLog(text: "menu item Quit clicked by user")
        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            appdelegate?.menuItem_Quit()
            return;
        }
        if quittingWcObj != nil{
            if quittingWcObj?.window?.isVisible ?? false{
                addLog(text: "Quit window already visible")
                return
            }
        }
        addLog(text: "Showing quit window")
        getQuittingWindowObject().contentViewController = getQuittingCountDownVcObject()
        getQuittingWindowObject().showWindow(self)
        getQuittingCountDownVcObject().resetData()
        getQuittingWindowObject().window?.styleMask.remove(.closable)
        
        quittingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
        
        NSApplication.shared.activate(ignoringOtherApps: true)
//        appdelegate?.menuItem_Quit()
    }
    @IBAction func btnEnableOfficeModeClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            activationWindowControllerObj?.showSevenDayTrialVc()
            return;
        }
        
        addLog(text: "menu item Enable Office Mode by user")
        if isOfficeModeEnabled{
            isOfficeModeEnabled = false
            boxCheckMark.isHidden = true
            UserDefaults.standard.set(false, forKey: kUserdefaultsOfficeModeEnabled)
        }else{
            
                
            let filterArr = arrAllbreakActivities.filter { $0.isOfficeFriendly == true}
            if filterArr.count == 0{// no activity found with isOfficeFriendly
                let alert = NSAlert()
                if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alert.window.sharingType = .none
                    }
                }
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
                alert.window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
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
        let alert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alert.window.sharingType = .none
            }
        }
        var officeModeEnabledSuccessfullyText = "Ok! I'll just prompt you to do activities that won't weird other people out (doing handstand pushups in the office might raise a few eyebrows)."
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            officeModeEnabledSuccessfullyText = menuInfo.value(forKey: "officeModeEnabledSuccessfullyText") as? String ?? officeModeEnabledSuccessfullyText
        }
        alert.messageText = officeModeEnabledSuccessfullyText
        alert.addButton(withTitle: buttonOkText)
        _ = alert.runModal()
        isOfficeModeEnabled = true
        boxCheckMark.isHidden = false
        UserDefaults.standard.set(true, forKey: kUserdefaultsOfficeModeEnabled)
    }
    func addOfficeFriendlyActivityInSettings(){
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

        if var breakActivities = mutableDic.value(forKey: "breakActivities") as? [NSDictionary] {
            let activityDic: NSMutableDictionary = ["name":"Stand up and stretch", "durationSeconds":20, "isOfficeFriendly":true]
            breakActivities.append(activityDic)
            mutableDic["breakActivities"] = breakActivities
            
            arrAllbreakActivities.append(breakActivity(name: "Stand up and stretch", durationSeconds: 20, IncludeInEveryBreak: false, urlsArray: [], logQuantity:false, isRandomChoice: false, choices: [], logQuantityQuestion: "", openSpecificApps: false, allowUrls: [], allowApps: [], isOfficeFriendly: true, allowedFocusMode: "", logQuantityType: ""))
        }

        do {
            let data = try (JSONSerialization.data(withJSONObject: mutableDic, options: .prettyPrinted))
            if let str = String(data: data, encoding: String.Encoding.utf8){
                UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
            }
        } catch let error as NSError {
            print(error)
        }
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
            }else{//on NSTouchBarPlayTemplate
                cell.imgViewAppIcon.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                if let color = arrFocusType[cRow]["color"] as? String{
                    cell.boxColor.fillColor = HexToColor(hexString: color)
                }
            }


            cell.boxtitle.fillColor = .clear
            return cell
        }
        
        return NSTableCellView()
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






        

        
        

    
