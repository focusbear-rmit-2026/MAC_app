//
//  onboardingBlockedAppsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/11/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingBlockedAppsVc: NSViewController {

    
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var lblAddFirstApp: NSTextField!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblBlockedCount: NSTextField!
    @IBOutlet weak var btnRemove: Button!
    @IBOutlet weak var btnAdd: Button!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var arrBlockedApps = [String]()
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblView.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.blockedAppsTable)
        btnAdd.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.blockedAppsAddButton)
        btnRemove.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.blockedAppsRemoveButton)
        lblBlockedCount.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.blockedAppsCount)
        btnContinue.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.blockedAppsProceedButton)
        // Do view setup here.
        lblTitle.stringValue = "Choose apps to block"
        btnContinue.title = "Proceed"
        lblAddFirstApp.stringValue = "Tap on the + button to block a new app"
        btnAdd.title = "Add"
        btnRemove.title = "Remove"
        
        if let info = configjson.value(forKey: "onboardingBlockedAppsVcInfo") as? NSDictionary{
            lblTitle.stringValue = info.value(forKey: "titleNew") as? String ?? lblTitle.stringValue
            btnContinue.title = info.value(forKey: "buttonProceed") as? String ?? btnContinue.title
            lblAddFirstApp.stringValue = info.value(forKey: "description") as? String ?? lblAddFirstApp.stringValue
            btnAdd.title = info.value(forKey: "buttonAdd") as? String ?? btnAdd.title
            btnRemove.title = info.value(forKey: "buttonRemove") as? String ?? btnRemove.title
        }
 
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 1, progress: 0.80)
        
        btnAdd.horizontalPadding = 25
        btnRemove.horizontalPadding = 25
        
        addDefaultBlockedApps()
        tblView.reloadData()
        
        addLog(text: "onboardingBlockedAppsVc-shown")
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "onboarding-blocked-apps-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // Show bubble
        var bubbleText = "Don’t worry, we don’t track which apps you’re using"
        if let onboardingBlockedAppsVcInfo = configjson.value(forKey: "onboardingBlockedAppsVcInfo") as? NSDictionary{
            bubbleText = onboardingBlockedAppsVcInfo.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: "Don’t worry, we don’t track which apps you’re using", verticalOffset: -40, horizontalOffset: 25, fontSize: 13)
        }
        
        showOnboardingBellIcon(view: self.view, screen: "onboarding-blocked-apps-screen")
    }
    
    // added in v 3.32.492
    private func addDefaultBlockedApps() {
        let defaultApps = [
            "Chess",
            "Stocks",
            "TV",
            "News"
        ]

        for appName in defaultApps {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier(for: appName)) {
                if !arrBlockedApps.contains(appURL.path) {
                    arrBlockedApps.append(appURL.path)
                }
            }
        }
    }

    private func bundleIdentifier(for appName: String) -> String {
        switch appName {
        case "Chess":
            return "com.apple.Chess"
        case "Stocks":
            return "com.apple.stocks"
        case "TV":
            return "com.apple.TV"
        case "News":
            return "com.apple.news"
        default:
            return ""
        }
    }
    
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
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
            allApiObject.capturePosthog(event: "added-always-blocked-app", metadata: [:])
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
        allApiObject.capturePosthog(event: "remove-always-blocked-app", metadata: [:])
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingBlockedAppsVc:- Button Continue clicked")
        UserDefaults.standard.set(arrBlockedApps, forKey: kUserdefaultsBlockedAppsFromOnboarding)

        SettingsManagerObject.arrBlockedApps = arrBlockedApps
        SensitiveDefaults.set(SettingsManagerObject.arrBlockedApps, forKey: SettingsManagerObject.kUserdefaultsArrBlockedApps)//
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAnyDistractionSetByUser)
        // After blocked URLs + apps, continue through allowed URLs → blocking schedule → permissions;
        // the habits intro comes last, after permissions. Jumping straight to _HOLD_ON_ here (added in
        // #2569) skipped the blocking-schedule and permission screens for users who set up blocking, so
        // blocking couldn't actually be enforced. (#2599)
        getOnboardingVcObject().navigateToAllowedUrlsVc()
        
    }
}

extension onboardingBlockedAppsVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if arrBlockedApps.count == 0{
            btnRemove.isEnabled = false
            lblAddFirstApp.isHidden = false
        }else{
            btnRemove.isEnabled = true
            lblAddFirstApp.isHidden = true
        }
        var blockAppsCountText = ""
        
        if arrBlockedApps.count == 1{
            blockAppsCountText = "1 app selected (you can change this later)"
            if let onboardingBlockedAppsVcInfo = configjson.value(forKey: "onboardingBlockedAppsVcInfo") as? NSDictionary{
                blockAppsCountText = onboardingBlockedAppsVcInfo.value(forKey: "oneAppBlockText") as? String ?? blockAppsCountText
            }
        }else{
            blockAppsCountText = "<COUNT> apps selected (you can change this later)"
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
