//
//  onboardingControllingBrowserVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingControllingBrowserVc: NSViewController {

    @IBOutlet weak var boxScrollView: NSBox!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var btnDidNotWork: Button!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnSkip: underLineButton!
    
    var checkPermissionTimer:DispatchSourceTimer?
    var arrBrowsers = [[String:Any]]()
    var anyBrowserPermissionSet = false
    
    var buttonRequestPermissionText = "Request Permission"
    var enabledText = "✅  Enabled!"
    var accessibilityPermissionText = "(Accessibility permission given)"
    var allPermissionText = "(All needed permissions given)"
    var settingsFirefoxText = "Awaiting settings update in Firefox"
    var descriptionFirefoxExtensiont = "Install the Focus Bear Blocker extension in Firefox."
    var buttonAddFirefoxExtensiont = "Add Firefox Extension"
    
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    private let queue = DispatchQueue(label: "queueTimerCheckPermission")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.//
        
        btnContinue.title = "Proceed"
        lblTitle.stringValue = "Grant Browser Permissions"
        lblDescription.stringValue = "Click on ‘Request Permission’ to view the prompt on the browser. Then, select the ‘Allow’ option:"
        btnSkip.title = "Skip"
        
        btnDidNotWork.title = "It didn't work"

        if let dic = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "titleNew") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = dic.value(forKey: "descriptionNew") as? String ?? lblDescription.stringValue
            btnContinue.title = dic.value(forKey: "buttonProceed") as? String ?? btnContinue.title
            btnDidNotWork.title = dic.value(forKey: "buttonDidNotWorkText") as? String ?? btnDidNotWork.title
            buttonRequestPermissionText = dic.value(forKey: "buttonRequestPermissionText") as? String ?? buttonRequestPermissionText
            enabledText = dic.value(forKey: "enabledText") as? String ?? enabledText
            accessibilityPermissionText = dic.value(forKey: "accessibilityPermissionText") as? String ?? accessibilityPermissionText
            allPermissionText = dic.value(forKey: "allPermissionText") as? String ?? allPermissionText
            settingsFirefoxText = dic.value(forKey: "settingsFirefoxText") as? String ?? settingsFirefoxText
            descriptionFirefoxExtensiont = dic.value(forKey: "descriptionFirefoxExtensiont") as? String ?? descriptionFirefoxExtensiont
            buttonAddFirefoxExtensiont = dic.value(forKey: "buttonAddFirefoxExtensiont") as? String ?? buttonAddFirefoxExtensiont
            btnSkip.title = dic.value(forKey: "buttonSkip") as? String ?? btnSkip.title
        }
        

        btnDidNotWork.isSecondaryButton = true

        boxScrollView.wantsLayer = true
        boxScrollView.layer?.cornerRadius = 10
        boxScrollView.layer?.borderWidth = 1
        boxScrollView.layer?.borderColor = NSColor.gray.withAlphaComponent(0.3).cgColor
        
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 3, progress: 0.75)
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
        
        if filemanager.fileExists(atPath: "/Applications/Comet.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Comet.app")
            arrBrowsers.append(["name": "Comet", "image": fileIcon, "isEnabled": false, "browser":BROWSER._COMET_])
        }else if filemanager.fileExists(atPath: NSString(string: "~/Applications/Comet.app").expandingTildeInPath){
            let fileIcon = NSWorkspace.shared.icon(forFile: NSString(string: "~/Applications/Comet.app").expandingTildeInPath)
            arrBrowsers.append(["name": "Comet", "image": fileIcon, "isEnabled": false, "browser":BROWSER._COMET_])
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
                        if browserState{
                            self.anyBrowserPermissionSet = true
                        }
                        break;
                    }
                }
            }
            
        }
        tblView.reloadData()
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "permission-to-block-distractions-screen")
        
        // Show bubble
        
        var bubbleText = "We need this to redirect the browser to the blocked page when you visit a distracting site"

        if let info = configjson["onboardingControllingBrowserVcInfo"] as? [String: Any] {
            bubbleText = info["bubbleText"] as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: -40, horizontalOffset: 25, fontSize: 13)
        }
    }
    
    override func viewWillDisappear() {
        if self.checkPermissionTimer != nil{
            self.checkPermissionTimer?.cancel()
            self.checkPermissionTimer = nil
        }
        hideOnboardingBellIcon(view: self.view)
    }
    
    override func viewWillAppear() {
        UserDefaults.standard.set(true, forKey: kUserdefaultsControllingBrowserVcShown)
        reloadData()
        startTimerCheckPermission()
        allApiObject.capturePosthog(event: "permission-to-block-distractions-shown", metadata: [:])
    }
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    func startTimerCheckPermission(){
        if self.checkPermissionTimer != nil{
            self.checkPermissionTimer?.cancel()
            self.checkPermissionTimer = nil
        }
        let newTimer = DispatchSource.makeTimerSource(queue: queue)
        newTimer.schedule(deadline: .now(), repeating: 1)
        
        newTimer.setEventHandler { [weak self] in
            self?.checkPermission()
        }
        
        newTimer.resume()
        checkPermissionTimer = newTimer
    }
    
    
    @objc func checkPermission(){
        let runningApps = NSWorkspace.shared.runningApplications
        for runningApp in runningApps{
            if let name = runningApp.localizedName{
                let nameLowercased = name.lowercased()
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    
                    if browser == ._SIGMA_OS_{
                        if !isAccessibilityEnabled(isPrompt: false){
                            continue;
                        }
                    }
                    
                    for i in 0..<arrBrowsers.count{
                        if arrBrowsers[i]["browser"] as? BROWSER == browser{
                            let state = arrBrowsers[i]["isEnabled"] as? Bool ?? false
                            if !state{
                                if getActiveTabUrlOf(browser: browser) != nil{
                                    DispatchQueue.main.async {
                                        self.arrBrowsers[i]["isEnabled"] = true
                                        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                                            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
                                        }
                                        
                                        var browserNameForPosthog = ""
                                        if browser == ._SAFARI_{
                                            browserNameForPosthog =  "safari"
                                        }else if browser == ._GOOGLE_CHROME_{
                                            browserNameForPosthog = "chrome"
                                        }else if browser == ._OPERA_{
                                            browserNameForPosthog = "opera"
                                        }else if browser == ._OPERA_GX_{
                                            browserNameForPosthog = "opera gx"
                                        }else if browser == ._VIVALDI_{
                                            browserNameForPosthog = "vivaldi"
                                        }else if browser == ._SIDEKICK_ {
                                            browserNameForPosthog = "sidekick"
                                        }else if browser == ._BRAVE_BROWSER_{
                                            browserNameForPosthog = "brave"
                                        }else if browser == ._MICROSOFT_EDGE_{
                                            browserNameForPosthog = "edge"
                                        }else if browser == ._ARC_{
                                            browserNameForPosthog = "arc"
                                        }else if browser == ._FIREFOX_{
                                            browserNameForPosthog = "firefox"
                                        }else if browser == ._SIGMA_OS_{
                                            browserNameForPosthog = "sigmaos"
                                        }else if browser == ._COMET_{
                                            browserNameForPosthog = "comet"
                                        }
                                        addLog(text: "Permission granted for browser:- \(browserNameForPosthog)")
                                        allApiObject.capturePosthog(event: "onboarding-granted-permission-\(browserNameForPosthog)", metadata: [:])
                                        self.tblView.reloadData()
                                        self.saveBrowsersPermissionInfo()
                                        
                                        self.permissionGivenFromBrowser()
                                        self.anyBrowserPermissionSet = true
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func permissionGivenFromBrowser(){// added on 23/7/25 version 1.26.393        
        if mainWindowControllerObj != nil && permissionsVcObj != nil && settingsContainerVcObj != nil{//working
            if mainWindowControllerObj?.window?.isVisible ?? false{
                if leftMenuVcObj?.boxSettings.isSelected ?? false{
                    if settingsContainerVcObj?.isPermissionsViewVisible ?? false{
                        permissionsVcObj?.reloadData()
                    }
                }
            }
        }
        
        menuViewControllerObj?.browserPermissionGiven = true
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] btnContinueClicked")
        if !self.anyBrowserPermissionSet{
            addLog(text: "Haven’t granted permission to any browser: show alert")
            let alert = NSAlert()// added on 23/7/25 version 1.26.393
            alert.setSharingType()
            alert.alertStyle = .informational
            alert.messageText = "You haven’t granted permission to any browser, which could cause blocking issues. Do you want to proceed without giving permission?"
            if let dic = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
                alert.messageText = dic.value(forKey: "permissionNotGrantedText") as? String ?? alert.messageText
            }
            alert.addButton(withTitle: buttonCancelText)
            alert.addButton(withTitle: buttonYesText)
            
            alert.buttons[0].isHighlighted = true
            alert.buttons[0].keyEquivalent = "\r" // Enter key
            

            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if modalResponse == .alertSecondButtonReturn{
                    self.closeView()
                }
            })
        }else{
            closeView()
        }
    }
   
    func closeView(){
        addLog(text: "closeView")
        saveBrowsersPermissionInfo()
        if currentState == ._ONBOARDING_{
            getOnboardingVcObject().navigate(to: ._ALL_SET_)
        }else{
            self.view.window?.close()
            
            reloadPermissionsIfNeeded()
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
    
    @IBAction func btnDidNotWorkClicked(_ sender: Any) {// hidden not in use
        allApiObject.capturePosthog(event: "onboarding-browser-permission-did-not-work", metadata: [:])
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] btnSkipClicked")
        closeView()
    }
}

extension onboardingControllingBrowserVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrBrowsers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellBrowsers"), owner: nil) as? tblCellBrowsers {
            
            cell.btnInfo.isHidden = true
            cell.lblTitle.stringValue = arrBrowsers[row]["name"] as? String ?? ""
            cell.imgView.image = arrBrowsers[row]["image"] as? NSImage
            cell.lblFirefoxPermission.isHidden = true
            let state = arrBrowsers[row]["isEnabled"] as? Bool ?? false
            if state{
                cell.imgViewTick.isHidden = false
                cell.btnRequest.isHidden = true
            }else{
                cell.imgViewTick.isHidden = true
                cell.btnRequest.isHidden = false
            }
            
            
            if !cell.btnRequest.isHidden {
                addPulseRing(to: cell.btnRequest)
            } else {
                cell.btnRequest.layer?.sublayers?.removeAll {
                    $0.name == "PulseRing"
                }
            }
            
            if arrBrowsers[row]["browser"] as? BROWSER == ._FIREFOX_{
                if !state{
                    cell.lblFirefoxPermission.isHidden = false
                    cell.btnInfo.isHidden = false
                    cell.lblFirefoxPermission.stringValue = descriptionFirefoxExtensiont
                    cell.btnRequest.title = buttonAddFirefoxExtensiont
                }
            }else{
                cell.btnRequest.title = buttonRequestPermissionText
            }

            
            cell.lblState.stringValue = enabledText
            cell.lblState.isHidden = true
            
            cell.btnRequest.target = self
            cell.btnRequest.tag = row
            cell.btnRequest.action = #selector(btnRequestClicked(sender:))
            
            
            cell.btnInfo.target = self
            cell.btnInfo.tag = row
            cell.btnInfo.action = #selector(btnFirefoxInfoClicked(sender:))
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    @objc func btnRequestClicked(sender:NSButton){
        requestPermission(row: sender.tag)
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
        UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        if let browser = arrBrowsers[row]["browser"] as? BROWSER{
            var browserNameForPosthog = ""
            if browser == ._SAFARI_{
                browserNameForPosthog =  "safari"
            }else if browser == ._GOOGLE_CHROME_{
                browserNameForPosthog = "chrome"
            }else if browser == ._OPERA_{
                browserNameForPosthog = "opera"
            }else if browser == ._OPERA_GX_{
                browserNameForPosthog = "opera gx"
            }else if browser == ._VIVALDI_{
                browserNameForPosthog = "vivaldi"
            }else if browser == ._SIDEKICK_ {
                browserNameForPosthog = "sidekick"
            }else if browser == ._BRAVE_BROWSER_{
                browserNameForPosthog = "brave"
            }else if browser == ._MICROSOFT_EDGE_{
                browserNameForPosthog = "edge"
            }else if browser == ._ARC_{
                browserNameForPosthog = "arc"
            }else if browser == ._FIREFOX_{
                browserNameForPosthog = "firefox"
            }else if browser == ._SIGMA_OS_{
                browserNameForPosthog = "SigmaOS"
            }else if browser == ._COMET_{
                browserNameForPosthog = "comet"
            }
            allApiObject.capturePosthog(event: "onboarding-request-permission-\(browserNameForPosthog)", metadata: [:])
            addLog(text: "Request permission for browser:- \(browserNameForPosthog)")
            if browser == ._FIREFOX_{// in settings also
                //showFirefoxPermissionWindow(showingFromOnboarding: true, currentBrowser: browser)
                let urlString = "https://addons.mozilla.org/en-US/firefox/addon/focus-bear-blocker/"
                let firefoxPath = "/Applications/Firefox.app"

                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(
                        [url],
                        withApplicationAt: URL(fileURLWithPath: firefoxPath),
                        configuration: NSWorkspace.OpenConfiguration(),
                        completionHandler: nil
                    )
                }
            }else{
                
                if browser == ._SIGMA_OS_{
                    if !isAccessibilityEnabled(isPrompt: false){
                        showFirefoxPermissionWindow(showingFromOnboarding: true, currentBrowser: browser)
                        self.view.window?.close()
                        return;
                    }
                }
                let appName = getCurrentBrowserNameFrom(browser: browser) ?? ""
                NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/\(appName).app"))
                if getActiveTabUrlOf(browser: browser) != nil{
                    DispatchQueue.main.async {
                        self.arrBrowsers[row]["isEnabled"] = true
                        self.tblView.reloadData()
                        allApiObject.capturePosthog(event: "onboarding-granted-permission-\(browserNameForPosthog)", metadata: [:])
                        addLog(text: "Permission granted for browser:- \(browserNameForPosthog)")
                        self.saveBrowsersPermissionInfo()
                        self.permissionGivenFromBrowser()
                        self.anyBrowserPermissionSet = true
                    }
                }else{
                    DispatchQueue.main.async {
                        addLog(text: "⚠️ Permission not granted for browser:- \(browserNameForPosthog)")
                        
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
                        var buttonPreferencesText = "Open Automation Preferences"
                        
                        if let onboardingControllingBrowserVcInfo = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
                            buttonPreferencesText = onboardingControllingBrowserVcInfo.value(forKey: "buttonOpenPreferences") as? String ?? buttonPreferencesText
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
                }
            }
        }
        
        
    }
    
    @objc func btnFirefoxInfoClicked(sender:NSButton){
        if let browser = arrBrowsers[sender.tag]["browser"] as? BROWSER{
            if browser == ._FIREFOX_{
                var msg = "Firefox can’t detect which site you're on unless you install the Focus Bear extension. Sorry for the extra step—other browsers don’t need this."
                if let onboardingControllingBrowserVcInfo = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
                    msg = onboardingControllingBrowserVcInfo.value(forKey: "toolTipFirefoxExtensiont") as? String ?? msg
                }
                showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
            }
        }
    }
    
    func addPulseRing(to button: Button) {
        
        button.wantsLayer = true
        let color = NSColor(named: "dark_OrangeColor") ?? .orange
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = color.cgColor
        animation.toValue = NSColor.brown.cgColor
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        
        button.layer?.add(animation, forKey: "bgPulse")
    }
}

