//
//  preloadFocusModeAppsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/12/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class preloadFocusModeAppsVc: NSViewController {

    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var btnRemoveItem: NSButton!
    @IBOutlet weak var btnAddItem: NSButton!
    @IBOutlet weak var btnDone: Button!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var isAddingApp = true
    var arrApps = [String]()
    var arrUrls = [String]()
    var workType = ""
    var workDic = [String:Any]()
    
    var toolTipAdd = "Add"
    var toolTipRemove = "Remove"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        tblView.delegate = self
        tblView.dataSource = self
        btnDone.title = "Done"
        
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            toolTipAdd = focusPreferencesInfo.value(forKey: "toolTipAdd") as? String ?? toolTipAdd
            toolTipRemove = focusPreferencesInfo.value(forKey: "toolTipRemove") as? String ?? toolTipRemove
        }
        btnAddItem.toolTip = toolTipAdd
        btnRemoveItem.toolTip = toolTipRemove
        
        if let preloadFocusModeAppsVcInfo = configjson.value(forKey: "preloadFocusModeAppsVcInfo") as? NSDictionary{
            btnDone.title = preloadFocusModeAppsVcInfo.value(forKey: "toolTipAdd") as? String ?? btnDone.title
        }
        if #available(macOS 11.0, *) {
            btnAddItem.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveItem.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
        }
    }
    
    func resetView(dic:[String:Any]){
        isAddingApp = true
        workType = dic["name"] as? String ?? ""
        arrApps = dic["allowed_apps"] as? [String] ?? []
        arrUrls = dic["allowed_urls"] as? [String] ?? []
        workDic = dic
        tblView.reloadData()
        
        var titleForApps = "What apps do you normally use while you're doing <WORK_TYPE>?"
        var descriptionApps = "Don't worry you can still use other apps if you need to but these are the apps that are most likely to be productive for you while you're working on <WORK_TYPE>. You can change these settings later on."
        lblSubtitle.stringValue = "Add the apps you plan to use:"
        
        
        if let preloadFocusModeAppsVcInfo = configjson.value(forKey: "preloadFocusModeAppsVcInfo") as? NSDictionary{
            titleForApps = preloadFocusModeAppsVcInfo.value(forKey: "titleForApps") as? String ?? titleForApps
            descriptionApps = preloadFocusModeAppsVcInfo.value(forKey: "descriptionApps") as? String ?? descriptionApps
            lblSubtitle.stringValue = preloadFocusModeAppsVcInfo.value(forKey: "subTitleForApps") as? String ?? lblSubtitle.stringValue
        }
        
        lblTitle.stringValue = titleForApps.replacingOccurrences(of: "<WORK_TYPE>", with: workType)
        lblDescription.stringValue = descriptionApps.replacingOccurrences(of: "<WORK_TYPE>", with: workType)
        
        
    }
    
    @IBAction func btnRemoveItemClicked(_ sender: Any) {
        addLog(text: "preload Focus mode apps&urls:-  button Remove Item clicked")
        let selectedRow = tblView.selectedRow
        if selectedRow == -1{
            return
        }
        if isAddingApp{
            arrApps.remove(at: selectedRow)
        }else{
            arrUrls.remove(at: selectedRow)
        }
        tblView.reloadData()
    }
    @IBAction func btnAddItemClicked(_ sender: Any) {
        addLog(text: "preload Focus mode apps&urls:-  button Add Item clicked")
        if isAddingApp{
            
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.allowsMultipleSelection = true
            openPanel.treatsFilePackagesAsDirectories = false
            openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
            openPanel.allowedFileTypes = ["app"]
            
//            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{/no need
//                if state{
//                    openPanel.sharingType = .none
//                }
//            }
            openPanel.prompt = "Select"
            
            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                if let title = focusPreferencesInfo.value(forKey: "buttonSelectAppText") as? String{
                    openPanel.prompt = title
                }
            }
            openPanel.beginSheetModal(for: self.view.window!) { response in
                guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                    //                if var arr =
                    
                    return
                }
                let urls = openPanel.urls
                var appsArray = [String]()
                var appsUrlArray = [URL]()
                
                appsArray = self.arrApps
                
                //
                for path in appsArray{
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
                    if !isFoundAlready{
                        self.arrApps.append(url.path)
                    }else{
                        isContainAlready = true
                    }
                }
                
                self.tblView.reloadData()
                self.tblView.selectRowIndexes(IndexSet(arrayLiteral: (appsArray.count - 1)), byExtendingSelection: false)
                self.tblView.scrollRowToVisible(appsArray.count - 1)
                
                
                if isContainAlready{
                    self.showAlertAppAlreadyAdded()
                }
            }
            
        }else{
            addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_ALLOW_URL
            addWebUrlVcObj!.isAdding = true
            self.presentAsSheet(addWebUrlVcObj!)
            
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
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
            }
        })
    }
    
    @IBAction func btnDoneClicked(_ sender: Any) {
        if isAddingApp{
            isAddingApp = false
            tblView.reloadData()
            addLog(text: "preload Focus mode apps&urls:-  button Done clicked:- load urls view")
            var titleForUrls = "How about websites?"
            var descriptionUrls = "Don't worry you can still use other websites if you need to but these are the sites that are most likely to be productive for you while you're working on <WORK_TYPE>. You can change these settings later on."
            lblSubtitle.stringValue = "Add the websites you plan to use:"
            
            if let preloadFocusModeAppsVcInfo = configjson.value(forKey: "preloadFocusModeAppsVcInfo") as? NSDictionary{
                titleForUrls = preloadFocusModeAppsVcInfo.value(forKey: "titleForUrls") as? String ?? titleForUrls
                descriptionUrls = preloadFocusModeAppsVcInfo.value(forKey: "descriptionUrls") as? String ?? descriptionUrls
                lblSubtitle.stringValue = preloadFocusModeAppsVcInfo.value(forKey: "subTitleForUrls") as? String ?? lblSubtitle.stringValue
            }
            
            lblTitle.stringValue = titleForUrls
            lblDescription.stringValue = descriptionUrls.replacingOccurrences(of: "<WORK_TYPE>", with: workType)
            
        }else{
            // done adding focus mode
            workDic["allowed_apps"] = arrApps
            workDic["allowed_urls"] = arrUrls
            
            UserDefaults.standard.set(workDic, forKey: kUserdefaultsFocusAddedFromFirstHabit)
            if UserDefaults.standard.object(forKey: kUserDefaultsFirstAppFullLoadDate) == nil{
                UserDefaults.standard.set(Date(), forKey: kUserDefaultsFirstAppFullLoadDate)
            }
            
            preloadFocusModesWindowControllerObj!.contentViewController = getFocusTipsVcObjObj()
            addLog(text: "preload Focus mode apps&urls:-  button Done clicked:- show Focus Tips Vc")
        }
    }
}

extension preloadFocusModeAppsVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        btnRemoveItem.isEnabled = false
        if isAddingApp{
            return arrApps.count
        }else{
            return arrUrls.count
        }
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            
            if isAddingApp{
                let url = URL(fileURLWithPath: arrApps[row])
                cell.lblTitle.stringValue = url.lastPathComponent
            }else{
                cell.lblTitle.stringValue = arrUrls[row]
            }
            
            
            return cell
        }
        
        return NSTableCellView()
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tblView.selectedRow
        if selectedRow == -1{
            btnRemoveItem.isEnabled = false
        }else{
            btnRemoveItem.isEnabled = true
        }
    }

}
