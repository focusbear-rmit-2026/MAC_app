//
//  blockedAppsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 15/03/22.


import Cocoa

class blockedAppsVc: NSViewController {

    @IBOutlet weak var checkBoxImmediatelyBlock: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnAddApp: NSButton!
    @IBOutlet weak var btnRemoveApp: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        checkBoxImmediatelyBlock.title = "Immediately block super distracting apps"
        lblTitle.stringValue = "Super Distracting Apps"
        lblSubTitle.stringValue = "Which apps do you waste time on? Focus Bear will help you be more intentional about how you use these apps. They will be blocked during focus sessions and custom blocking schedules."
        
        if let blockedAppsViewInfo = configjson.value(forKey: "blockedAppsViewInfo") as? NSDictionary{
            if let title = blockedAppsViewInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let subTitleText = blockedAppsViewInfo.value(forKey: "subTitleTextNew") as? String{
                lblSubTitle.stringValue = subTitleText
            }
            checkBoxImmediatelyBlock.title = blockedAppsViewInfo.value(forKey: "checkBoxText") as? String ?? checkBoxImmediatelyBlock.title
        }
        
        if #available(macOS 11.0, *) {
            btnAddApp.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveApp.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
        }
        arrForSearchFromSettings.append(["title": lblTitle.stringValue, "tabId": idBlockedApps, "object": lblTitle as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitle.stringValue, "tabId": idBlockedApps, "object": lblTitle as Any])
    }
    override func viewWillAppear() {
        tblView.reloadData()
        if SettingsManagerObject.immediatelyBlockDistractingApps{
            checkBoxImmediatelyBlock.state = .on
        }else{
            checkBoxImmediatelyBlock.state = .off
        }
    }
    
    @IBAction func btnAddAppClicked(_ sender: Any) {
        addLog(text:"[user-action] blockedAppsVc:- btnAddAppClicked")
        if isExpired{
            if SettingsManagerObject.arrBlockedApps.count >= alwaysBlockedUrlsCountInExpireApp{
                var titleLimitedBlockApps = "Max 3 blocked apps can be added in Basic version."
                if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
                    titleLimitedBlockApps = upgradeToProNagVcInfo.value(forKey: "titleLimitedBlockApps") as? String ?? titleLimitedBlockApps
                }
                showUpgradeToProNagWindow(titleText: titleLimitedBlockApps, reason: "add_always_blocked_app")
                return;
            }
        }

        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.allowedFileTypes = ["app"]
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                openPanel.sharingType = .none
            }
        }
        openPanel.prompt = "Select"
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let title = focusPreferencesInfo.value(forKey: "buttonSelectAppText") as? String{
                openPanel.prompt = title
            }
        }
        openPanel.beginSheetModal(for: self.view.window!) { response in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                return
            }
            let urls = openPanel.urls
            var appsUrlArray = [URL]()
            
            for path in SettingsManagerObject.arrBlockedApps{
                let url = URL(fileURLWithPath: path)
                appsUrlArray.append(url)
            }
            var isContainAlready = false
            var isBrowserAdding = false
            for url in urls{
                var isFoundAlready = false
                var isBrowser = false
                for addedUrl in appsUrlArray{
                    if addedUrl.lastPathComponent.lowercased() == url.lastPathComponent.lowercased(){
                        isFoundAlready = true
                        break;
                    }
                }
                for browser in arrBrowsersLowerCasedNames{
                    if browser == url.deletingPathExtension().lastPathComponent.lowercased(){
                        isBrowser = true
                        break;
                    }
                }
                
                if isFoundAlready{
                    isContainAlready = true
                }else if isBrowser{
                    isBrowserAdding = true
                }else{
                    SettingsManagerObject.arrBlockedApps.append(url.path)
                    if isExpired{// 2.28.453
                        if SettingsManagerObject.arrBlockedApps.count >= alwaysBlockedUrlsCountInExpireApp{
                            var titleLimitedBlockApps = "Max 3 blocked apps can be added in Basic version."
                            if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
                                titleLimitedBlockApps = upgradeToProNagVcInfo.value(forKey: "titleLimitedBlockApps") as? String ?? titleLimitedBlockApps
                            }
                            showUpgradeToProNagWindow(titleText: titleLimitedBlockApps, reason: "add_always_blocked_app")
                            break;
                        }
                    }
                }
                
            }

            self.tblView.reloadData()
            self.tblView.selectRowIndexes(IndexSet(arrayLiteral: (SettingsManagerObject.arrBlockedApps.count - 1)), byExtendingSelection: false)
            self.tblView.scrollRowToVisible(SettingsManagerObject.arrBlockedApps.count - 1)
            SensitiveDefaults.set(SettingsManagerObject.arrBlockedApps, forKey: SettingsManagerObject.kUserdefaultsArrBlockedApps)
            if isContainAlready{
                self.showAlertAppAlreadyAdded()
            }
            if isBrowserAdding{
                self.showAlertCantAddBrowser()
            }
            SettingsManagerObject.isSettingsChanged = true
            allApiObject.capturePosthog(event: "add-always-blocked-app", metadata: [:])
            mainViewControllerObj?.newUrlOrAppAdded()
        }
        
    }
    
    func showAlertAppAlreadyAdded(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var messageText = "Some of the apps selected are already present in the list."
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            messageText = focusPreferencesInfo.value(forKey: "appAlreadyExistsText") as? String ?? messageText
        }
        alert.messageText = messageText
        alert.addButton(withTitle: buttonOkText)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
            }
        })
    }
    func showAlertCantAddBrowser(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var messageText = "Sorry you can't choose browser apps here. Instead put distracting websites in the Super Distracting URLs section."
        if let blockedAppsViewInfo = configjson.value(forKey: "blockedAppsViewInfo") as? NSDictionary{
            messageText = blockedAppsViewInfo.value(forKey: "addBrowserAlertText") as? String ?? messageText
        }
        alert.messageText = messageText
        alert.addButton(withTitle: buttonOkText)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
            }
        })
    }
    @IBAction func btnRemoveAppClicked(_ sender: Any) {
        let selectedAppsRow = tblView.selectedRow
        if selectedAppsRow == -1{
            return
        }
        if selectedAppsRow < SettingsManagerObject.arrBlockedApps.count{
            SettingsManagerObject.arrBlockedApps.remove(at: selectedAppsRow)
            tblView.reloadData()
            SensitiveDefaults.set(SettingsManagerObject.arrBlockedApps, forKey: SettingsManagerObject.kUserdefaultsArrBlockedApps)
        }
        SettingsManagerObject.isSettingsChanged = true
        allApiObject.capturePosthog(event: "remove-always-blocked-app", metadata: [:])//#490
    }

    
    @IBAction func checkBoxImmediatelyBlockClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxImmediatelyBlock.state == .on{
            SettingsManagerObject.immediatelyBlockDistractingApps = true
            allApiObject.capturePosthog(event: "settings-changed-immediately-block-app-enabled", metadata: [:])
        }else{
            SettingsManagerObject.immediatelyBlockDistractingApps = false
            allApiObject.capturePosthog(event: "settings-changed-immediately-block-app-disabled", metadata: [:])
        }
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        //// solved in some cases settingsContainerVcObj is nil so before this added a check to solve problem on 15/9/25 version 2.27.415
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            tabStrictnessContainerVcObj?.showStrictnessView()
            return;
        }
        settingsContainerVcObj?.showStrictnessView()
    }
}

extension blockedAppsVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {

        if SettingsManagerObject.arrBlockedApps.count == 0{
            btnRemoveApp.isEnabled = false
        }else{
            btnRemoveApp.isEnabled = true
        }
        return SettingsManagerObject.arrBlockedApps.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {
            if row < SettingsManagerObject.arrBlockedApps.count{
                let url = URL(fileURLWithPath: SettingsManagerObject.arrBlockedApps[row])
                cell.lblTitle.stringValue = url.lastPathComponent
                cell.imgView.image = NSWorkspace.shared.icon(forFile: url.path)
            }else{
                cell.lblTitle.stringValue = ""
                cell.imgView.image = nil
            }
            return cell
        }
        
        return NSTableCellView()
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard let tblview = notification.object as? NSTableView else {
            return
        }
        let selectedRow = tblview.selectedRow
    
        if tblview == tblView{
            if selectedRow == -1{
                btnRemoveApp.isEnabled = false
            }else{
                btnRemoveApp.isEnabled = true
            }
        }
    }
}
