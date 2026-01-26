//
//  alwaysAllowedAppsVc.swift
//  Focus Bear
//
//  Created by Devin AI on 16/01/26.


import Cocoa

class alwaysAllowedAppsVc: NSViewController {

    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnAddApp: NSButton!
    @IBOutlet weak var btnRemoveApp: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var checkBoxImmediatelyBlock: NSButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        checkBoxImmediatelyBlock?.isHidden = true
        lblTitle.stringValue = "Always Allowed Apps"
        lblSubTitle.stringValue = "Apps added here will never be blocked, regardless of focus mode, blocking schedules, or strictness settings. Use this for essential apps that you always need access to."
        
        if let alwaysAllowedAppsViewInfo = configjson.value(forKey: "alwaysAllowedAppsViewInfo") as? NSDictionary{
            if let title = alwaysAllowedAppsViewInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let subTitleText = alwaysAllowedAppsViewInfo.value(forKey: "subTitleText") as? String{
                lblSubTitle.stringValue = subTitleText
            }
        }
        
        if #available(macOS 11.0, *) {
            btnAddApp.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveApp.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
        }
        arrForSearchFromSettings.append(["title": lblTitle.stringValue, "tabId": idAlwaysAllowedApps, "object": lblTitle as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitle.stringValue, "tabId": idAlwaysAllowedApps, "object": lblTitle as Any])
    }
    override func viewWillAppear() {
        tblView.reloadData()
    }
    
    @IBAction func btnAddAppClicked(_ sender: Any) {
        addLog(text:"[user-action] alwaysAllowedAppsVc:- btnAddAppClicked")

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
            
            for path in SettingsManagerObject.arrAlwaysAllowedApps{
                let url = URL(fileURLWithPath: path)
                appsUrlArray.append(url)
            }
            var isContainAlready = false
            for url in urls{
                var isFoundAlready = false
                for addedUrl in appsUrlArray{
                    if addedUrl.lastPathComponent.lowercased() == url.lastPathComponent.lowercased(){
                        isFoundAlready = true
                        break;
                    }
                }
                
                if isFoundAlready{
                    isContainAlready = true
                }else{
                    SettingsManagerObject.arrAlwaysAllowedApps.append(url.path)
                }
                
            }

            self.tblView.reloadData()
            self.tblView.selectRowIndexes(IndexSet(arrayLiteral: (SettingsManagerObject.arrAlwaysAllowedApps.count - 1)), byExtendingSelection: false)
            self.tblView.scrollRowToVisible(SettingsManagerObject.arrAlwaysAllowedApps.count - 1)
            UserDefaults.standard.set(SettingsManagerObject.arrAlwaysAllowedApps, forKey: SettingsManagerObject.kUserdefaultsArrAlwaysAllowedApps)
            if isContainAlready{
                self.showAlertAppAlreadyAdded()
            }
            SettingsManagerObject.isSettingsChanged = true
            allApiObject.capturePosthog(event: "add-always-allowed-app", metadata: [:])
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
    @IBAction func btnRemoveAppClicked(_ sender: Any) {
        let selectedAppsRow = tblView.selectedRow
        if selectedAppsRow == -1{
            return
        }
        if selectedAppsRow < SettingsManagerObject.arrAlwaysAllowedApps.count{
            SettingsManagerObject.arrAlwaysAllowedApps.remove(at: selectedAppsRow)
            tblView.reloadData()
            UserDefaults.standard.set(SettingsManagerObject.arrAlwaysAllowedApps, forKey: SettingsManagerObject.kUserdefaultsArrAlwaysAllowedApps)
        }
        SettingsManagerObject.isSettingsChanged = true
        allApiObject.capturePosthog(event: "remove-always-allowed-app", metadata: [:])
    }

    @IBAction func btnBackClicked(_ sender: Any) {
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            tabStrictnessContainerVcObj?.showStrictnessView()
            return;
        }
        settingsContainerVcObj?.showStrictnessView()
    }
}

extension alwaysAllowedAppsVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {

        if SettingsManagerObject.arrAlwaysAllowedApps.count == 0{
            btnRemoveApp.isEnabled = false
        }else{
            btnRemoveApp.isEnabled = true
        }
        return SettingsManagerObject.arrAlwaysAllowedApps.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {
            if row < SettingsManagerObject.arrAlwaysAllowedApps.count{
                let url = URL(fileURLWithPath: SettingsManagerObject.arrAlwaysAllowedApps[row])
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
