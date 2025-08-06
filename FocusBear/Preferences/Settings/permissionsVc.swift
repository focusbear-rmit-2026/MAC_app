//
//  permissionsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class permissionsVc: NSViewController {
    @IBOutlet weak var heightScrollView: NSLayoutConstraint!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    @IBOutlet weak var lblDescription: NSTextField!
    var checkPermissionTimer:Timer?
    var arrBrowsers = [[String:Any]]()
    
    var buttonRequestPermissionText = "Request Permission"
    var enabledText = "✅  Enabled!"
    var accessibilityPermissionText = "(Accessibility permission given)"
    var allPermissionText = "(All needed permissions given)"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.//
        lblTitle.stringValue = "Permissions"
        lblDescription.stringValue = "System-wide access is essential for Focus Bear to effectively prevent distractions in web browsers. The following outlines the current permission status for installed browsers."
        
        if let dic = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
            buttonRequestPermissionText = dic.value(forKey: "buttonRequestPermissionText") as? String ?? buttonRequestPermissionText
            enabledText = dic.value(forKey: "enabledText") as? String ?? enabledText
            accessibilityPermissionText = dic.value(forKey: "accessibilityPermissionText") as? String ?? accessibilityPermissionText
            allPermissionText = dic.value(forKey: "allPermissionText") as? String ?? allPermissionText
        }
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "permissionsSettingTitle") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = settingsNew.value(forKey: "descriptionPermissions") as? String ?? lblDescription.stringValue
        }
        
    }
    
    override func viewWillAppear() {
        settingsContainerVcObj?.isPermissionsViewVisible = true
        reloadData()
    }
    
    override func viewWillDisappear() {
        settingsContainerVcObj?.isPermissionsViewVisible = false
        saveBrowsersPermissionInfo()
        checkPermissionTimer?.invalidate()
    }
    
    func reloadData(){
        arrBrowsers.removeAll()
        let filemanager = FileManager.default
        
        if filemanager.fileExists(atPath: "/Applications/Safari.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Safari.app")
            arrBrowsers.append(["name": "Safari", "image": fileIcon, "isEnabled": false, "browser":BROWSER._SAFARI_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Google Chrome.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Google Chrome.app")
            arrBrowsers.append(["name": "Google Chrome", "image": fileIcon, "isEnabled": false, "browser":BROWSER._GOOGLE_CHROME_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Opera.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Opera.app")
            arrBrowsers.append(["name": "Opera", "image": fileIcon, "isEnabled": false, "browser":BROWSER._OPERA_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Opera GX.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Opera GX.app")
            arrBrowsers.append(["name": "Opera GX", "image": fileIcon, "isEnabled": false, "browser":BROWSER._OPERA_GX_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Vivaldi.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Vivaldi.app")
            arrBrowsers.append(["name": "Vivaldi", "image": fileIcon, "isEnabled": false, "browser":BROWSER._VIVALDI_])
        }
        if filemanager.fileExists(atPath: "/Applications/Sidekick.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Sidekick.app")
            arrBrowsers.append(["name": "Sidekick", "image": fileIcon, "isEnabled": false, "browser":BROWSER._SIDEKICK_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Brave Browser.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Brave Browser.app")
            arrBrowsers.append(["name": "Brave Browser", "image": fileIcon, "isEnabled": false, "browser":BROWSER._BRAVE_BROWSER_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Microsoft Edge.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Microsoft Edge.app")
            arrBrowsers.append(["name": "Microsoft Edge", "image": fileIcon, "isEnabled": false, "browser":BROWSER._MICROSOFT_EDGE_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Firefox.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Firefox.app")
            arrBrowsers.append(["name": "Firefox", "image": fileIcon, "isEnabled": false, "browser":BROWSER._FIREFOX_])
        }
        if filemanager.fileExists(atPath: "/Applications/Arc.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Arc.app")
            arrBrowsers.append(["name": "Arc", "image": fileIcon, "isEnabled": false, "browser":BROWSER._ARC_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/SigmaOS.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/SigmaOS.app")
            arrBrowsers.append(["name": "SigmaOS", "image": fileIcon, "isEnabled": false, "browser":BROWSER._SIGMA_OS_])
        }else if filemanager.fileExists(atPath: "/Applications/SigmaOS_latest.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/SigmaOS_latest.app")
            arrBrowsers.append(["name": "SigmaOS", "image": fileIcon, "isEnabled": false, "browser":BROWSER._SIGMA_OS_])
        }
        
        let height = CGFloat((60 * arrBrowsers.count) + 2)
        if heightScrollView.constant != height{
            heightScrollView.constant = height
        }
        
        
        if let arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
            for info in arrBrowsersInfo{
                let browserRawValue = info["browser"] as? Int ?? 0
                let browserState = info["isEnabled"] as? Bool ?? false
                for i in 0..<arrBrowsers.count{
                    let browser = arrBrowsers[i]
                    let rawValue = (browser["browser"] as? BROWSER)?.rawValue ?? 0
                    if rawValue == browserRawValue{
                        arrBrowsers[i]["isEnabled"] = browserState
                        break;
                    }
                }
            }
            
        }
        if self.lastBrowserClicked == ._FIREFOX_ || self.lastBrowserClicked == ._SIGMA_OS_{
            startTimerCheckPermission()
        }
        tblView.reloadData()
    }
    
    
    func startTimerCheckPermission(){
        DispatchQueue.global().sync {
            if self.checkPermissionTimer != nil{
                self.checkPermissionTimer?.invalidate()
                self.checkPermissionTimer = nil
            }
            self.checkPermissionTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.checkPermission), userInfo: nil, repeats: true)
            
            RunLoop.main.add((checkPermissionTimer!), forMode: RunLoop.Mode.common)
        }
    }

    func saveBrowsersPermissionInfo(){
        var arrBrowsersInfo: [[String : Any]] = []
        for browserInfo in arrBrowsers{
            if let browser = browserInfo["browser"] as? BROWSER{
                arrBrowsersInfo.append(["browser": browser.rawValue, "isEnabled": browserInfo["isEnabled"] as? Bool ?? false])
            }
        }
        UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
    }
    
    var lastBrowserClicked:BROWSER?
    
    @objc func checkPermission(){
        guard let lastBrowserClicked = lastBrowserClicked else {
            return;
        }
        if lastBrowserClicked == ._SIGMA_OS_{
            if !isAccessibilityEnabled(isPrompt: false){
                return;
            }
        }
        let runningApps = NSWorkspace.shared.runningApplications
        for runningApp in runningApps{
            if let name = runningApp.localizedName{
                let nameLowercased = name.lowercased()
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    if lastBrowserClicked == browser{
                        for i in 0..<arrBrowsers.count{
                            if arrBrowsers[i]["browser"] as? BROWSER == browser{
                                let state = arrBrowsers[i]["isEnabled"] as? Bool ?? false
                                if !state{
                                    if getActiveTabUrlOf(browser: browser) != nil{
                                        DispatchQueue.main.async {
                                            self.arrBrowsers[i]["isEnabled"] = true
                                            self.tblView.reloadData()
                                            if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                                                UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
                                            }
                                        }
                                        saveBrowsersPermissionInfo()
                                        
                                        DispatchQueue.main.async {
                                            self.permissionGivenFromBrowser()
                                        }
                                    }
                                }else{
                                    self.checkPermissionTimer?.invalidate()
                                    self.lastBrowserClicked = nil
                                    self.tblView.reloadData()
                                }
                                
                                break;
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    func permissionGivenFromBrowser(){// added on 23/7/25 version 1.26.393
        if permissionBlockDistractionWcObj != nil && onboardingControllingBrowserVcObj != nil{
            if permissionBlockDistractionWcObj?.window?.isVisible ?? false{
                if permissionBlockDistractionWcObj?.contentViewController == onboardingControllingBrowserVcObj{
                    onboardingControllingBrowserVcObj?.reloadData()
                }
            }
        }
    }
}

extension permissionsVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrBrowsers.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellBrowsers"), owner: nil) as? tblCellBrowsers {
            
            cell.lblTitle.stringValue = arrBrowsers[row]["name"] as? String ?? ""
            //            cell.lblDescription.stringValue = arrBrowsers[row]["description"] as? String ?? ""
            cell.imgView.image = arrBrowsers[row]["image"] as? NSImage
            cell.lblFirefoxPermission.isHidden = true
            let state = arrBrowsers[row]["isEnabled"] as? Bool ?? false
            if state{
                cell.lblState.isHidden = false
                cell.btnRequest.isHidden = true
            }else{
                cell.lblState.isHidden = true
                cell.btnRequest.isHidden = false
            }
            
            if row == arrBrowsers.count - 1{
                cell.lineBottom.isHidden = true
            }else{
                cell.lineBottom.isHidden = false
            }
            
            if arrBrowsers[row]["browser"] as? BROWSER == ._FIREFOX_{
                if !state{
                    if isAccessibilityEnabled(isPrompt: false) == true{
                        cell.lblFirefoxPermission.isHidden = false
                        cell.lblFirefoxPermission.stringValue = accessibilityPermissionText
                    }
                }else{
                    cell.lblFirefoxPermission.isHidden = false
                    cell.lblFirefoxPermission.stringValue = allPermissionText
                }
            }
            
            
            cell.btnRequest.title = buttonRequestPermissionText
            cell.lblState.stringValue = enabledText
            
            cell.btnRequest.target = self
            cell.btnRequest.tag = row
            cell.btnRequest.action = #selector(btnRequestClicked(sender:))
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    @objc func btnRequestClicked(sender:NSButton){
        requestPermission(row:sender.tag)
    }
    
    func requestSigmaOSBrowser(){
        for i in 0..<arrBrowsers.count{
            if arrBrowsers[i]["browser"] as? BROWSER == ._SIGMA_OS_{
                let state = arrBrowsers[i]["isEnabled"] as? Bool ?? false
                if !state{
                    requestPermission(row: i)
                }
                
                break;
            }
        }
    }
    
    func requestPermission(row:Int){
        if let browser = arrBrowsers[row]["browser"] as? BROWSER{
            lastBrowserClicked = browser
            if browser == ._FIREFOX_{
                showFirefoxPermissionWindow(showingFromOnboarding: false, currentBrowser: browser)
                self.view.window?.close()
            }else{
                
                if browser == ._SIGMA_OS_{
                    if !isAccessibilityEnabled(isPrompt: false){
                        showFirefoxPermissionWindow(showingFromOnboarding: false, currentBrowser: browser)
                        self.view.window?.close()
                        return;
                    }
                }
                
                let appName = getCurrentBrowserNameFrom(browser: browser) ?? ""
                NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/\(appName).app"))
                var shouldShowPermissionBox = true
                if !permissionAlertShownInfoDic.contains(browser){
                    shouldShowPermissionBox = false// will show Automatically from "getActiveTabUrlOf" func
                }
                if getActiveTabUrlOf(browser: browser) != nil{
                    DispatchQueue.main.async {
                        self.arrBrowsers[row]["isEnabled"] = true
                        self.tblView.reloadData()
                        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
                        }
                        self.saveBrowsersPermissionInfo()
                        self.permissionGivenFromBrowser()
                    }
                }else {
                    DispatchQueue.main.async {
                        if shouldShowPermissionBox{
                            let alert = NSAlert()
                            alert.setSharingType()
                            alert.alertStyle = .informational
                            
                            var urlError = "Unable to get <APPNAME> URL. Please check permissions. Do you want to Open System Preferences -> Security & Privacy > Privacy and check if <APPNAME> is allowed to be accessed by Focus Bear under Automation?"
                            
                            if #available(macOS 13.0, *) {
                                urlError = "Unable to get <APPNAME> URL. Please check permissions. Do you want to Open System Preferences -> Privacy & Security and check if <APPNAME> is allowed to be accessed by Focus Bear under Automation?"
                                
                                if let onboardingControllingBrowserVcInfo = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
                                    urlError = onboardingControllingBrowserVcInfo.value(forKey: "alertOpenPreferencesLatestOsText") as? String ?? urlError
                                }
                            }else {
                                urlError = "Unable to get <APPNAME> URL. Please check permissions. Do you want to Open System Preferences -> Security & Privacy > Privacy and check if <APPNAME> is allowed to be accessed by Focus Bear under Automation?"
                                
                                if let onboardingControllingBrowserVcInfo = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
                                    urlError = onboardingControllingBrowserVcInfo.value(forKey: "alertOpenPreferencesText") as? String ?? urlError
                                }
                            }
                            
                            urlError = urlError.replacingOccurrences(of: "<APPNAME>", with: appName)
                            var buttonPreferencesText = "Open System Preferences"
                            
                            
                            if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
                                buttonPreferencesText = firefoxPermissionsVcInfo.value(forKey: "buttonPreferencesText") as? String ?? buttonPreferencesText
                            }
                            
                            alert.messageText = urlError
                            alert.addButton(withTitle: buttonPreferencesText)
                            alert.addButton(withTitle: buttonCancelText)
                            
                            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                    let urlstring = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation";
                                    NSWorkspace.shared.open(URL(string: urlstring)!)
                                }
                            })
                        }
                        self.startTimerCheckPermission()
                    }
                }
            }
        }
    }
}


