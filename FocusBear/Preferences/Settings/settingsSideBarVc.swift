//
//  settingsSideBarVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//
var idUi = "ui"
var idAccesibility = "accesibility"
var idAi = "ai"
var idPomodoro = "pomodoro"
var idStrictness = "strictness"
var idAdvanced = "advanced"
var idAccount = "account"
var idUninstall = "uninstall"
var idSuperPomodoro = "isSuperPomodoro"
var idFriction = "friction"
var idPassword = "password"
var idFocusBearMode = "focusbearmode"
var idBrowserTabLimiter = "browsertablimiter"
var idBlockedUrls = "blockedurls"
var idBlockedApps = "blockedapps"
var idMeetings = "meetings"
var idPrivacy = "privacy"
var idMicroBreaks = "microbreaks"
var idAddOns = "addons"
var idPermissions = "permissions"
var idToDoList = "todolist"
var idResearch = "research"

import Cocoa

class settingsSideBarVc: NSViewController {
    
    @IBOutlet weak var btnReleaseNotes: underLineButton!
    @IBOutlet weak var searchField: PopoverAwareSearchField!
    @IBOutlet weak var customViewForSearchList: NSView!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnCheckForUpdates: Button!
    @IBOutlet weak var btnExportStatistics: Button!
    @IBOutlet weak var lblVersion: NSTextField!
    
    var arrSettingsList:[[String:Any]] = []
    var arrSettingsListForGeekMode:[[String:Any]] = []
    var arrSettingsListForSimpleMode:[[String:Any]] = []
    var pomodoroSettingsIndex = 3
    let strictnessSettingsIndex = 0
    var advancedSettingsIndex = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        addLog(text: "settingsSideBarVc viewdidload start")
        settingsSideBarVcObj = self
       
        btnReleaseNotes.title = "Release notes"
        
        
        var uiSettingTitle = "UI"
        var accessibilitySettingTitle = "Accessibility"
        var aISettingTitle = "AI Features"
        var breaksSettingTitle = "Breaks"
        var toDoListSettingTitle = "To Do List"
        var pomodoroSettingTitle = "Focus Sessions"
        var strictnessSettingTitle = "Strictness"
        var advancedSettingTitle = "Advanced"
        var accountSettingTitle = "Account"
        var uninstallSettingTitle = "Uninstall"
        var permissionsSettingTitle = "Permissions"
        
        
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            uiSettingTitle = settingsNew.value(forKey: "uiSettingTitle") as? String ?? uiSettingTitle
            accessibilitySettingTitle = settingsNew.value(forKey: "accessibilitySettingTitle") as? String ?? accessibilitySettingTitle
            aISettingTitle = settingsNew.value(forKey: "aISettingTitle") as? String ?? aISettingTitle
            pomodoroSettingTitle = settingsNew.value(forKey: "pomodoroSettingTitle") as? String ?? pomodoroSettingTitle
            strictnessSettingTitle = settingsNew.value(forKey: "strictnessSettingTitle") as? String ?? strictnessSettingTitle
            advancedSettingTitle = settingsNew.value(forKey: "advancedSettingTitle") as? String ?? advancedSettingTitle
            accountSettingTitle = settingsNew.value(forKey: "accountSettingTitle") as? String ?? accountSettingTitle
            uninstallSettingTitle = settingsNew.value(forKey: "uninstallSettingTitle") as? String ?? uninstallSettingTitle
            permissionsSettingTitle = settingsNew.value(forKey: "permissionsSettingTitle") as? String ?? permissionsSettingTitle
            breaksSettingTitle = settingsNew.value(forKey: "breaksNewSettingTitle") as? String ?? breaksSettingTitle
            toDoListSettingTitle = settingsNew.value(forKey: "toDoListSettingTitle") as? String ?? toDoListSettingTitle
            btnReleaseNotes.title = settingsNew.value(forKey: "buttonReleaseNotesText") as? String ?? btnReleaseNotes.title
        }
        var iconAccount:NSImage?
        var iconUi:NSImage?
        var iconAccessibility:NSImage?
        var iconAi:NSImage?
        var iconPomodoro:NSImage?
        var iconStrictness:NSImage?
        var iconAdvanced:NSImage?
        var iconUninstall:NSImage?
        var iconPermission:NSImage?
        var iconBreaks:NSImage?
        var iconToDoList:NSImage?
        if #available(macOS 11.0, *) {
            iconUi = NSImage(systemSymbolName: "text.and.command.macwindow", accessibilityDescription: nil)
            iconAccessibility = NSImage(systemSymbolName: "figure.walk.circle", accessibilityDescription: nil)
            iconAi = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: nil)
            iconPomodoro = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
            iconStrictness = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: nil)
            iconAccount = NSImage(systemSymbolName: "person", accessibilityDescription: nil)
            iconAdvanced = NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: nil)
            iconUninstall = NSImage(systemSymbolName: "minus.circle", accessibilityDescription: nil)
            iconPermission = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: nil)
            iconBreaks = NSImage(systemSymbolName: "clock.arrow.2.circlepath", accessibilityDescription: nil)
            iconToDoList = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil)
        } else {
            iconUi = NSImage(named: NSImage.homeTemplateName)
            iconAccessibility = NSImage(named: NSImage.preferencesGeneralName)
            iconAi = NSImage(named: NSImage.smartBadgeTemplateName)
            iconPomodoro = NSImage(named: NSImage.folderBurnableName)
            iconStrictness = NSImage(named: NSImage.stopProgressTemplateName)
            iconAccount = NSImage(named: "NSTouchBarUserTemplate")
            iconAdvanced = NSImage(named: NSImage.advancedName)
            iconUninstall = NSImage(named: NSImage.touchBarDeleteTemplateName)
            iconPermission = NSImage(named: NSImage.lockUnlockedTemplateName)
            iconBreaks = NSImage(named: NSImage.touchBarAlarmTemplateName)
            iconToDoList = NSImage(named: NSImage.menuOnStateTemplateName)
        }
        
        
        pomodoroSettingsIndex = 6
        advancedSettingsIndex = 7
        arrSettingsListForGeekMode = [["title": strictnessSettingTitle, "icon": iconStrictness as Any, "id": idStrictness],
                                      ["title": uiSettingTitle, "icon": iconUi as Any, "id": idUi],
                                      ["title": accessibilitySettingTitle, "icon": iconAccessibility as Any, "id": idAccesibility],
                                      ["title": aISettingTitle, "icon": iconAi as Any, "id": idAi],
                                      ["title": breaksSettingTitle, "icon": iconBreaks as Any, "id": idMicroBreaks],
                                      ["title": toDoListSettingTitle, "icon": iconToDoList as Any, "id": idToDoList],
                                      ["title": pomodoroSettingTitle, "icon": iconPomodoro as Any, "id": idPomodoro],
                                      ["title": advancedSettingTitle, "icon": iconAdvanced as Any, "id": idAdvanced],
                                      ["title": permissionsSettingTitle, "icon": iconPermission as Any, "id": idPermissions],
                                      ["title": accountSettingTitle, "icon": iconAccount as Any, "id": idAccount],
                                      ["title": uninstallSettingTitle, "icon": iconUninstall as Any, "id": idUninstall]]
        
        
        arrSettingsListForSimpleMode = [["title": strictnessSettingTitle, "icon": iconStrictness as Any, "id": idStrictness],
                                        ["title": uiSettingTitle, "icon": iconUi as Any, "id": idUi],
                                        ["title": accessibilitySettingTitle, "icon": iconAccessibility as Any, "id": idAccesibility],
                                        ["title": aISettingTitle, "icon": iconAi as Any, "id": idAi],
                                        ["title": breaksSettingTitle, "icon": iconBreaks as Any, "id": idMicroBreaks],
                                        ["title": toDoListSettingTitle, "icon": iconToDoList as Any, "id": idToDoList],
                                        ["title": accountSettingTitle, "icon": iconAccount as Any, "id": idAccount],
                                        ["title": uninstallSettingTitle, "icon": iconUninstall as Any, "id": idUninstall]]
        
        arrSettingsList = arrSettingsListForGeekMode
        
        self.searchField.delegate = self
        
        let popoverViewControllerObj = PopoverViewControllerForSearch()
        searchField.popoverViewControllerObj = popoverViewControllerObj
        self.customViewForSearchList.addSubview(popoverViewControllerObj.view)
        self.customViewForSearchList.addConstraints(subView: popoverViewControllerObj.view)
        searchField.popoverViewControllerObj?.view.isHidden = true
        searchField.parentVcObj = self
        
        
        btnExportStatistics.title = "Export Statistics"
        btnCheckForUpdates.title = "Check for updates"
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            btnExportStatistics.title = menuInfo.value(forKey: "menuItemExportStatisticsTitle") as? String ?? btnExportStatistics.title
            btnCheckForUpdates.title = menuInfo.value(forKey: "menuItemCheckForUpdatesTitle") as? String ?? btnCheckForUpdates.title
        }
        
        var versionText = "Version:"
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            versionText = preferencesInfo.value(forKey: "versionText") as? String ?? versionText
        }
        if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
            lblVersion.stringValue = versionText + " " + version + "." + build
        }else{
            lblVersion.stringValue = ""
        }
        
        
        customViewForSearchList.wantsLayer = true
        customViewForSearchList.shadow = NSShadow()
        customViewForSearchList.layer?.shadowOpacity = 0.3
        customViewForSearchList.layer?.shadowColor = NSColor.black.cgColor
        customViewForSearchList.layer?.shadowOffset = NSMakeSize(0, -2)
        customViewForSearchList.layer?.shadowRadius = 5
        addLog(text: "settingsSideBarVc viewdidload end")
    }
    override func viewWillAppear() {
        reloadDataForAppMode()
    }
    
    func reloadDataForAppMode(){
        if SettingsManagerObject.isGeekModeEnabled{
            searchField.itemsArr = arrForSearchFromSettings
            arrSettingsList = arrSettingsListForGeekMode
        }else{
            searchField.itemsArr = arrForSearchFromSimpleModeSettings
            arrSettingsList = arrSettingsListForSimpleMode
        }
        tblView.reloadData()
    }
    override func viewDidAppear() {
        if tblView.selectedRow == -1{
            tblView.selectRowIndexes(IndexSet(integer: strictnessSettingsIndex), byExtendingSelection: false)
        }
        
        if Reachability.isConnectedToNetwork() == false {
            allApiObject.isInternetOn(completionHandler: {isInternetOn in
                DispatchQueue.main.async {
                    if !isInternetOn{
                        if self.view.window != nil{
                            showAlertNoInternet(window: self.view.window!)
                        }
                    }
                }
            })
            
        }
   
    }
    
    func optionSelectedByUser(id:String, object:NSView?){
        addLog(text:"generalVc:- optionSelectedByUser")
        
        if let object = object{
            object.wantsLayer = true
            object.layer?.cornerRadius = 3
            object.layer?.borderWidth = 1
            object.layer?.borderColor = NSColor.labelColor.cgColor
            DispatchQueue.global().async {
                sleep(2)
                DispatchQueue.main.async {
                    object.layer?.cornerRadius = 0
                    object.layer?.borderWidth = 0
                    object.layer?.borderColor = NSColor.clear.cgColor
                    object.wantsLayer = false
                }
            }
        }
        if !id.isEmpty{
//            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                let tabviewItems = tabview.tabViewItems
//                for i in 0..<tabviewItems.count{
//                    let item = tabviewItems[i]
//                    if item.identifier as? String == id{
//                        tabview.selectedTabViewItemIndex = i
//                        return;
//                    }
//                }
//                
//            }
            

            if id == idSettings{
                
            }else if id == idFocus{
                leftMenuVcObj?.showFocusModeSettingsView()
            }else if id == idEditHabits{
                leftMenuVcObj?.showEditHabitsView()
            }else if id == idTabStrictness{
                leftMenuVcObj?.showBlocksView()
            }
            
            if id == "focusAdvanced"{
//                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                    tabview.selectedTabViewItemIndex = preferencesFocusModesIndex
//                    focusPreferencesVcObj?.btnAdvancedClicked(self)
//                    return;
//                }
                leftMenuVcObj?.showFocusModeSettingsView()
                focusPreferencesVcObj?.btnAdvancedClicked(self)
            }
            
            for i in 0..<self.arrSettingsList.count{
                //let item = self.tabView.tabViewItems[i]
                if arrSettingsList[i]["id"] as? String == id{
                    tblView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                    break;
                }
            }
            if id == idSuperPomodoro{
                tblView.selectRowIndexes(IndexSet(integer: pomodoroSettingsIndex), byExtendingSelection: false)
                pomodoroSettingsVcObj?.showHardCorePomodoroSetting()
                return;
            }
            
            if id == idFriction{
                tblView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                settingsContainerVcObj?.showFrictionView()
                return;
            }
            if id == idPassword{
                tblView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                settingsContainerVcObj?.showPasswordView()
                return;
            }
            if id == idFocusBearMode{
                tblView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                settingsContainerVcObj?.showFocusBearModeView()
                return;
            }
            if id == idBrowserTabLimiter{
                tblView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                settingsContainerVcObj?.showBrowserTabLimiterView()
                return;
            }
            if id == idBlockedUrls{
                tblView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                settingsContainerVcObj?.showBlockedUrlsView()
                return;
            }
            if id == idBlockedApps{
                tblView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                settingsContainerVcObj?.showBlockedAppsView()
                return;
            }
            
            if id == idMeetings{
                tblView.selectRowIndexes(IndexSet(integer: advancedSettingsIndex), byExtendingSelection: false)
                settingsContainerVcObj?.showMeetingDetactionView()
                return;
            }
            if id == idPrivacy{
                tblView.selectRowIndexes(IndexSet(integer: advancedSettingsIndex), byExtendingSelection: false)
                settingsContainerVcObj?.showPrivacyView()
                return;
            }
            
            if id == idMicroBreaks{
                tblView.selectRowIndexes(IndexSet(integer: 4), byExtendingSelection: false)
                settingsContainerVcObj?.showMicroBreaksView()
                return;
            }
            if id == idAddOns{
                tblView.selectRowIndexes(IndexSet(integer: advancedSettingsIndex), byExtendingSelection: false)
                settingsContainerVcObj?.showAddOnsView()
                return;
            }
            if id == idToDoList{
                tblView.selectRowIndexes(IndexSet(integer: 5), byExtendingSelection: false)
                settingsContainerVcObj?.showTodoListSettingView()
                return;
            }
            if id == idResearch{
                tblView.selectRowIndexes(IndexSet(integer: advancedSettingsIndex), byExtendingSelection: false)
                settingsContainerVcObj?.showResearchSettingView()
                return;
            }
        }
        searchField.stringValue = ""
    }
    @IBAction func btnExportStatisticsClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.prompt = "Export"
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                openPanel.sharingType = .none
            }
        }
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            openPanel.prompt = common.value(forKey: "buttonExportText") as? String ?? "Export"
        }
        
        openPanel.beginSheetModal(for: self.view.window!) { response in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                //                if var arr =
                
                return
            }
            //        if button == NSApplication.ModalResponse.OK {
            if let url = openPanel.url {
                let filemanager = FileManager.default
                
                
                let destUrl = url.appendingPathComponent("Focus Bear Data")
                if filemanager.fileExists(atPath: destUrl.path){
                    do{
                        try filemanager.removeItem(at: destUrl)
                    }catch{
                        print(error)
                    }
                }
                
                do{
                    try filemanager.createDirectory(at: destUrl, withIntermediateDirectories: false)
                    
                    
                    // stats
                    let destCsvUrl = destUrl.appendingPathComponent("Stats.csv")
                    do{
                        try FileManager.default.copyItem(at: quantityCsvURL, to: destCsvUrl)
                    }catch{
                        print(error)
                    }
                    
                    
                    // settings
                    
                    let destSettingsUrl = destUrl.appendingPathComponent("Habit settings.json")
                    var jsonString = ""
                    if let text = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
                        jsonString = text
                    }
                    if let data = jsonString.data(using: String.Encoding.utf8) {
                        do{
                            try data.write(to: destSettingsUrl)
                        }catch{
                            print(error)
                        }
                    }
                    
                    //Preferences
                    
                    var preferencesJSon = SettingsManagerObject.getLocalJsonToUpload()
                    preferencesJSon.removeValue(forKey: "kAppPassword")
                    let destPreferencessUrl = destUrl.appendingPathComponent("Preferences.json")
                    
                    let data = try JSONSerialization.data(withJSONObject: preferencesJSon, options: .init(rawValue: 0))
                    do{
                        try data.write(to: destPreferencessUrl)
                    }catch{
                        print(error)
                    }
                    
                    
                    //
                    
                    
                    //focus modes
                    
                    let focusJSon = arrFocusType
                    let destFocusJsonUrl = destUrl.appendingPathComponent("Focus Mode settings.json")
                    
                    let focusData = try JSONSerialization.data(withJSONObject: focusJSon, options: .init(rawValue: 0))
                    do{
                        try focusData.write(to: destFocusJsonUrl)
                    }catch{
                        print(error)
                    }
                    //
                    
                    
                    
                    allApiObject.capturePosthog(event: "export-data", metadata: [:])
                    
                }catch{
                    
                }
                
                
            }
        }
    }
    
    @IBAction func btnReleaseNotesClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/release-notes-mac"){
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func btnCheckForUpdatesClicked(_ sender: Any) {
        addLog(text: "[user-action] settingsSideBarVc:- btnCheckForUpdatesClicked")//
//        appdelegate!.updater?.checkForUpdates(self)
        appdelegate!.updaterController?.checkForUpdates(self)
        allApiObject.capturePosthog(event: "check-for-updates-manually", metadata: [:])
    }
    
}
extension settingsSideBarVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrSettingsList.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellView: NSTableCellView?
        
        if tableView == self.tblView {
            let title = arrSettingsList[row]["title"] as? String ?? ""
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("tblCellSettingsSideBar"), owner: nil) as? tblCellSettingsSideBar
            cell?.lblTitle.stringValue = title
            cell?.imgView.image = arrSettingsList[row]["icon"] as? NSImage ?? NSImage(named: NSImage.preferencesGeneralName)
            
            cell?.boxNewBadge.isHidden = true
            cellView = cell
        }
        
        return cellView
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
//        if isPurchased == false && daysLeft <= 0{ //
//            let id = arrSettingsList[row]["id"] as? String ?? ""
//
//            if id != idAccount && id != idUninstall{
//                return false
//            }
//        }
        return true
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tblView.selectedRow
        if selectedRow == -1{
            return;
        }
        
        if let settingsContainerVcObj = (self.parent as? NSSplitViewController)?.splitViewItems.last?.viewController as? settingsContainerVc{
            let id = arrSettingsList[selectedRow]["id"] as? String ?? ""
            
            switch id {
            case idUi:
                settingsContainerVcObj.showUiView()
            case idAccesibility:
                settingsContainerVcObj.showAccesibilityView()
            case idAi:
                settingsContainerVcObj.showAiView()
            case idPomodoro:
                settingsContainerVcObj.showPomodoroSettingsView()
            case idStrictness:
                settingsContainerVcObj.showStrictnessView()
            case idAdvanced:
                settingsContainerVcObj.showAdvancedView()
            case idAccount:
                settingsContainerVcObj.showAccountView()
            case idUninstall:
                settingsContainerVcObj.showUninstallView()
            case idPermissions:
                settingsContainerVcObj.showPermissionsView()
            case idMicroBreaks:
                settingsContainerVcObj.showMicroBreaksView()
            case idToDoList:
                settingsContainerVcObj.showTodoListSettingView()
            default:
                break;
            }
        }
        
        
    }
}
extension settingsSideBarVc: NSSearchFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        print("controlTextDidChange")
        if let searchfield = obj.object as? NSSearchField{
            if self.searchField == searchfield{
                let searchVal = searchField.stringValue
                if searchVal.isEmpty{
                    searchfield.complete(self)
                }
                
            }
        }
    }
}
