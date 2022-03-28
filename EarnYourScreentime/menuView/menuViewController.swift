//
//  menuViewController.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 16/02/22.

//

import Cocoa


class menuViewController: NSViewController {

    
    @IBOutlet weak var lblTrialVersionInfo: NSTextField!
    @IBOutlet weak var lblTitleReactivate: NSTextField!
    @IBOutlet weak var lblTitleEnterLicenseKey: NSTextField!
    @IBOutlet weak var lblTitleSettings: NSTextField!
    @IBOutlet weak var lblTitlePreferences: NSTextField!
    @IBOutlet weak var lblTitleExportStatistics: NSTextField!
    @IBOutlet weak var lblTitleFocus: NSTextField!
    @IBOutlet weak var lblTitleFocusPreferences: NSTextField!
    @IBOutlet weak var lblTitleStartPomodoroMode: NSTextField!
    @IBOutlet weak var lblTitleQuit: NSTextField!
    @IBOutlet weak var lblTitleCheckForUpdates: NSTextField!
    
    @IBOutlet weak var bottomLine: NSBox!
    @IBOutlet weak var lblOn: NSTextField!
    @IBOutlet weak var boxFocusMode: NSBox!
    @IBOutlet weak var focusModeBoxHeight: NSLayoutConstraint!
    @IBOutlet weak var boxStartPomodoroMode: customBox!
    @IBOutlet weak var boxCheckForUpdates: customBox!
    @IBOutlet weak var boxQuit: customBox!
    @IBOutlet weak var boxFocusPreferences: customBox!
    @IBOutlet weak var boxExportStatistics: customBox!
    @IBOutlet weak var boxPreferences: customBox!
    @IBOutlet weak var boxSettings: customBox!
    @IBOutlet weak var boxEnterLicenseKey: customBox!
    @IBOutlet weak var boxReactivate: customBox!
    @IBOutlet weak var tblViewFocusMode: NSTableView!
    
    
//    var selectedIndex = -1
    
    var onText = "On"
    var untilTimeText = "On Until <TIME>"
    
    var trialExpiredText = "Your trial has expired!"
    var daysRemainingText = "Trial version - <DAYS> of 7 trial days remaining"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        
        var itemReactivateTitle = "Reactivate"
        var itemEnterLicenseKeyTitle = "Enter License Key"
        
        var itemSettingsTitle = "Settings"
        var itemPreferences = "Preferences"
        var itemExportStatisticsTitle = "Export Statistics"
        var itemFocusTitle = "Focus"
        var itemFocusPreferencesTitle = "Focus Preferences"
        var itemQuitTitle = "Quit"
        var itemStartPomodoroTitle = "Start Pomodoro Mode"
        var menuItemCheckForUpdatesTitle = "Check for updates"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            itemReactivateTitle = menuInfo.value(forKey: "menuItemReactivateTitle") as? String ?? itemReactivateTitle
            itemEnterLicenseKeyTitle = menuInfo.value(forKey: "menuItemEnterLicenseKeyTitle") as? String ?? itemEnterLicenseKeyTitle
            itemSettingsTitle = menuInfo.value(forKey: "menuItemSettingsTitle") as? String ?? itemSettingsTitle
            itemPreferences = menuInfo.value(forKey: "menuItemPreferencesTitle") as? String ?? itemPreferences
            itemExportStatisticsTitle = menuInfo.value(forKey: "menuItemExportStatisticsTitle") as? String ?? itemExportStatisticsTitle
            itemFocusTitle = menuInfo.value(forKey: "menuItemFocusTitle") as? String ?? itemFocusTitle
            itemFocusPreferencesTitle = menuInfo.value(forKey: "menuItemFocusPreferencesTitle") as? String ?? itemFocusPreferencesTitle
            itemQuitTitle = menuInfo.value(forKey: "menuItemQuitTitle") as? String ?? itemQuitTitle
            itemStartPomodoroTitle = menuInfo.value(forKey: "menuItemStartPomodoroTitle") as? String ?? itemStartPomodoroTitle
            menuItemCheckForUpdatesTitle = menuInfo.value(forKey: "menuItemCheckForUpdatesTitle") as? String ?? menuItemCheckForUpdatesTitle
            
            untilTimeText = menuInfo.value(forKey: "untilTimeText") as? String ?? untilTimeText
            onText = menuInfo.value(forKey: "onText") as? String ?? onText

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
        lblTitleSettings.stringValue = itemSettingsTitle
        lblTitlePreferences.stringValue = itemPreferences
        lblTitleExportStatistics.stringValue = itemExportStatisticsTitle
        lblTitleFocus.stringValue = itemFocusTitle
        lblTitleFocusPreferences.stringValue = itemFocusPreferencesTitle
        lblTitleStartPomodoroMode.stringValue = itemStartPomodoroTitle
        lblTitleCheckForUpdates.stringValue = menuItemCheckForUpdatesTitle
        lblTitleQuit.stringValue = itemQuitTitle
        
        
        boxSettings.isHidden = true//todo remove text from config
        boxFocusPreferences.isHidden = true//todo remove text from config
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
                daysremaining = 7-numberOfDays_afterinstall
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
                daysremaining = 7
                
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
        boxFocusPreferences.fillColor = .clear
        boxExportStatistics.fillColor = .clear
        boxPreferences.fillColor = .clear
        boxSettings.fillColor = .clear
        boxEnterLicenseKey.fillColor = .clear
        boxReactivate.fillColor = .clear
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
        }else{
            boxStartPomodoroMode.isHidden = false
        }
        
        resetViewHeight()

        tblViewFocusMode.reloadData()
    }
    func resetViewHeight(){
//        35 16
//        18
//        16
        
        print("tblViewFocusMode resetViewHeight1111")
        var height = 34
        height += (arrFocusType.count * 32)
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
    @IBAction func btnSettingsClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            activationWindowControllerObj?.showSevenDayTrialVc()
            return;
        }
        appdelegate?.menuItem_ChangeJson()
    }
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
        appdelegate?.showPomodoroModeView()
    }
    @IBAction func btnFocusPreferencesClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            activationWindowControllerObj?.showSevenDayTrialVc()
            return;
        }
        preferencesWindowControllerObj?.showWindow(self)
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = 1
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    @IBAction func btnCheckForUpdatesClicked(_ sender: Any) {
        appdelegate!.updater?.checkForUpdates(self)
    }
    @IBAction func btnQuitClicked(_ sender: Any) {
        appdelegate?.menuItem_Quit()
    }
}


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
                    lblOn.stringValue = ""
                }
            }else if isFocusTimeType == ._TILL_SHUTOFF_{
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
//        if arrFocusType.count == 0{
//            bottomLine.isHidden = true
//        }else{
//            bottomLine.isHidden = false
//        }
        return arrFocusType.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocus"), owner: nil) as? tblCellFocus {

            cell.boxtitle.tagValue = row
            cell.boxtitle.isTableView = true
            
            if let name = arrFocusType[row]["name"] as? String{
                cell.lblTitle.stringValue = name
            }else{
                cell.lblTitle.stringValue = ""
            }
            cell.imgViewAppIcon.isHidden = false
            if arrFocusType[row]["isOn"] as? Bool == false{
                cell.boxColor.fillColor = .tertiaryLabelColor
                cell.imgViewAppIcon.image = NSImage(named: NSImage.Name("NSTouchBarPlayTemplate"))
            }else{//on NSTouchBarPlayTemplate
                cell.imgViewAppIcon.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                if let color = arrFocusType[row]["color"] as? String{
                    cell.boxColor.fillColor = HexToColor(hexString: color)
                }
            }
            
            
//            if let hourValue = arrFocusType[row]["hourValue"] as? Int{
//                cell.textFieldCustomHour.integerValue = hourValue
//                cell.stepperHourValue.integerValue = hourValue
//            }
            cell.currentRow = row
            
//            if row == arrFocusType.count-1{
//                cell.horizaontalLine.isHidden = true
//            }else{
//                cell.horizaontalLine.isHidden = false
//            }
            cell.boxtitle.fillColor = .clear
//            cell.boxChildFirst.fillColor = .clear
//            cell.boxChildSecond.fillColor = .clear
            
//            cell.lblFor.stringValue = forText
//            cell.lblHour.stringValue = hourText
//            cell.lblUntil.stringValue = untilShutOffTimeText
//            if isFocusTimeType == ._HOUR_{
//                cell.imgViewCheckMarkFirst.isHidden = false
//                cell.imgViewCheckMarkSecond.isHidden = true
//            }else if isFocusTimeType == ._TILL_SHUTOFF_{
//                cell.imgViewCheckMarkFirst.isHidden = true
//                cell.imgViewCheckMarkSecond.isHidden = false
//            }else{
//                cell.imgViewCheckMarkFirst.isHidden = true
//                cell.imgViewCheckMarkSecond.isHidden = true
//            }
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
