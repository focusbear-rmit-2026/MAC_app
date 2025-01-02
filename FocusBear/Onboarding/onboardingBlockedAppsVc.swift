//
//  onboardingBlockedAppsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/11/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingBlockedAppsVc: NSViewController {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblBottom: NSTextField!
    @IBOutlet weak var lblTip: NSTextField!
    @IBOutlet weak var lblBlockedCount: NSTextField!
    @IBOutlet weak var btnRemove: NSButton!
    @IBOutlet weak var btnAdd: NSButton!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    var arrBlockedApps = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Which apps are most distracting?"
        lblSubTitle.stringValue = "Which apps do you waste time on? Focus Bear will help you be more intentional about how you use these apps. They will be blocked during focus sessions. The rest of the time, Focus Bear will ask you why you want to use the app."
        lblBlockedCount.stringValue = "6 apps will always be blocked."
        lblTip.stringValue = "In case you're curious - we don't track which apps you're using."
        lblBottom.stringValue = "(You can change this later)"
        btnContinue.title = buttonContinueText
        
        
        
        if let onboardingBlockedAppsVcInfo = configjson.value(forKey: "onboardingBlockedAppsVcInfo") as? NSDictionary{
            lblTitle.stringValue = onboardingBlockedAppsVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = onboardingBlockedAppsVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblBlockedCount.stringValue = onboardingBlockedAppsVcInfo.value(forKey: "blockAppsCountText") as? String ?? lblBlockedCount.stringValue
            lblTip.stringValue = onboardingBlockedAppsVcInfo.value(forKey: "tipText") as? String ?? lblTip.stringValue
        }
        
        
        if let onboardingBlockedUrlsInfo = configjson.value(forKey: "onboardingBlockedUrlsInfo") as? NSDictionary{
            lblBottom.stringValue = onboardingBlockedUrlsInfo.value(forKey: "bottomText") as? String ?? lblBottom.stringValue
        }
        
        allApiObject.capturePosthog(event: "onboarding-blocked-apps-shown", metadata: [:])
        addLog(text: "onboardingBlockedAppsVc-shown")
    }
    @IBAction func btnAddAppClicked(_ sender: Any) {
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.allowedFileTypes = ["app"]
        
        openPanel.prompt = "Select"
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let title = focusPreferencesInfo.value(forKey: "buttonSelectAppText") as? String{
                openPanel.prompt = title
            }
        }
        openPanel.beginSheetModal(for: self.view.window!) { [self] response in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                return
            }
            let urls = openPanel.urls
            var appsUrlArray = [URL]()
            
            for path in self.arrBlockedApps{
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
                    arrBlockedApps.append(url.path)
                }
                
            }

            self.tblView.reloadData()
            self.tblView.selectRowIndexes(IndexSet(arrayLiteral: (arrBlockedApps.count - 1)), byExtendingSelection: false)
            self.tblView.scrollRowToVisible(arrBlockedApps.count - 1)

            if isContainAlready{
                self.showAlertAppAlreadyAdded()
            }
            if isBrowserAdding{
                self.showAlertCantAddBrowser()
            }
            allApiObject.capturePosthog(event: "new-block-app-added", metadata: [:])
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
        if selectedAppsRow < arrBlockedApps.count{
            arrBlockedApps.remove(at: selectedAppsRow)
            tblView.reloadData()
        }
        allApiObject.capturePosthog(event: "remove-new-blocked-app", metadata: [:])
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingBlockedAppsVc:- Button Continue clicked")
        UserDefaults.standard.set(arrBlockedApps, forKey: kUserdefaultsBlockedAppsFromOnboarding)
        self.view.window?.contentViewController = getOnboardingBlockingScheduleVcObject()
    }
}

extension onboardingBlockedAppsVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if arrBlockedApps.count == 0{
            btnRemove.isEnabled = false
        }else{
            btnRemove.isEnabled = true
        }
        var blockAppsCountText = ""
        
        if arrBlockedApps.count == 1{
            blockAppsCountText = "1 app will be blocked."
            if let onboardingBlockedAppsVcInfo = configjson.value(forKey: "onboardingBlockedAppsVcInfo") as? NSDictionary{
                blockAppsCountText = onboardingBlockedAppsVcInfo.value(forKey: "oneAppBlockText") as? String ?? blockAppsCountText
            }
            
            blockAppsCountText = blockAppsCountText.replacingOccurrences(of: "<COUNT>", with: "\(arrBlockedApps.count)")
        }else{
            blockAppsCountText = "<COUNT> apps will be blocked."
            if let onboardingBlockedAppsVcInfo = configjson.value(forKey: "onboardingBlockedAppsVcInfo") as? NSDictionary{
                blockAppsCountText = onboardingBlockedAppsVcInfo.value(forKey: "blockAppsCountText") as? String ?? blockAppsCountText
            }
            
            blockAppsCountText = blockAppsCountText.replacingOccurrences(of: "<COUNT>", with: "\(arrBlockedApps.count)")
        }

        lblBlockedCount.stringValue = blockAppsCountText
        
        return arrBlockedApps.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {
            if row < arrBlockedApps.count{
                let url = URL(fileURLWithPath: arrBlockedApps[row])
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
                btnRemove.isEnabled = false
            }else{
                btnRemove.isEnabled = true
            }
        }
    }
}
