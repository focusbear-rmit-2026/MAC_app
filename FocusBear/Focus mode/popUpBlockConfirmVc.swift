//
//  popUpBlockConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 05/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class popUpBlockConfirmVc: NSViewController {

    @IBOutlet weak var boxAllowDomain: NSBox!
    @IBOutlet weak var checkBoxAllowDomain: NSButton!
    @IBOutlet weak var lblCheckBoxAllowDomain: NSTextField!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var stackViewProgress: NSStackView!
    @IBOutlet weak var btnInfoProgress: hoverInfoButton!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var lblAi: NSTextField!
    @IBOutlet weak var lblIntention: NSTextField!
    @IBOutlet weak var btnEditSettings: Button!
    @IBOutlet weak var btnBlock: Button!
    @IBOutlet weak var btnAllow: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnBlockAndAddToRelaxMode: Button!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var currentApp:NSRunningApplication?
    var currentAppName = ""
    var isAppBlocking = true
    var url:String = ""
    var fullUrl = ""
    var script:String = ""
    var browser:BROWSER?
    var titleText = "Do you need to use <URL> when you're focusing on <FOCUSTYPE>?"
    var intentionText = "Your intention was \"<INTENTION>\""
    var currentPid: pid_t?
    var lastBlockReasonFromAi = ""
    let maxProgressCount = 50
    var isAiWaiting = false
    var isUrlBlockByAi:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnAllow.title = "Yes - just this time"
        btnBlock.title = "No - I was getting distracted"
        btnEditSettings.title = "Edit Settings"
        btnBlockAndAddToRelaxMode.title = "Block and save for Relax mode"
        
        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
            titleText = popUpBlockConfirmVcInfo.value(forKey: "title") as? String ?? titleText
            btnAllow.title = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
            btnBlock.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockText") as? String ?? btnBlock.title
            btnEditSettings.title = popUpBlockConfirmVcInfo.value(forKey: "buttonEditSettingsText") as? String ?? btnEditSettings.title
            intentionText = popUpBlockConfirmVcInfo.value(forKey: "intentionText") as? String ?? intentionText
            btnBlockAndAddToRelaxMode.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockAndAddToRelaxModeText") as? String ?? btnBlockAndAddToRelaxMode.title
        }
        lblTitle.stringValue = titleText
        
        btnAllow.buttonColor = NSColor.white.cgColor
        btnEditSettings.buttonColor = NSColor.white.cgColor
        stackViewProgress.isHidden = true
    }
    

    
    func resetView(blockedAppName:String, currentApp:NSRunningApplication?, url:String, script:String, isBlockApp:Bool, browser:BROWSER?,currentPid: pid_t?, tabTitle:String?, fullUrl:String, aiUrlBlockReason:String, isTimeOut:Bool, isUrlBlockByAi:Bool){
        if self.currentApp != nil{
            if self.currentApp == currentApp{
                return;
            }
        }
        checkBoxAllowDomain.state = .off
        isAiWaiting = false
        isAppBlocking = isBlockApp
        self.script = script
        self.url = url
        self.fullUrl = fullUrl
        var currentRunningFocusModeName = ""
        self.browser = browser
        self.currentPid = currentPid
        lastBlockReasonFromAi = ""
        
        if SettingsManagerObject.cuddlyModeProgressCount >= maxProgressCount{
            stackViewProgress.isHidden = true
        }else{
            stackViewProgress.isHidden = false
            lblProgress.stringValue = "\(SettingsManagerObject.cuddlyModeProgressCount) / \(maxProgressCount)"
            progressBar.doubleValue = Double(SettingsManagerObject.cuddlyModeProgressCount)
        }
        
        if isAnyAllowedFocusModeActivityRunning{
            if currentHabitPlaying != nil{
                currentRunningFocusModeName = currentHabitPlaying?.name ?? ""
            }else if currentActivityPlaying != nil{
                currentRunningFocusModeName = currentActivityPlaying?.name ?? ""
            }
        }else{
            currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
        }
        
        if SettingsManagerObject.isAiCheckUrlEnabled && !isBlockSuperDistractingFocusModeOn(){
            lblFocusAlignmentScore.isHidden = false
            var focusAlignmentScoreText = "Your Focus alignment score is <SCORE>%"
            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                focusAlignmentScoreText = popUpBlockConfirmVcInfo.value(forKey: "focusAlignmentScoreText") as? String ?? focusAlignmentScoreText
            }
            
            focusAlignmentScoreText = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(currentFocusAlignmentScore)")
            lblFocusAlignmentScore.stringValue = focusAlignmentScoreText
        }else{
            lblFocusAlignmentScore.isHidden = true
        }
        
        if isAppBlocking{
            boxAllowDomain.isHidden = true
            var blockTitle = titleText.replacingOccurrences(of: "<URL>", with: blockedAppName)
            blockTitle = blockTitle.replacingOccurrences(of: "<FOCUSTYPE>", with: currentRunningFocusModeName)
            if !whatToAchieveInFocusBlock.isEmpty{
                lblIntention.isHidden = false
                lblIntention.stringValue = intentionText.replacingOccurrences(of: "<INTENTION>", with: whatToAchieveInFocusBlock)
            }else{
                lblIntention.isHidden = true
            }
            lblTitle.stringValue = blockTitle
            lblAi.isHidden = true
            btnBlockAndAddToRelaxMode.isHidden = true
        }else{
            boxAllowDomain.isHidden = true 
            
            
            let domain = getDomainFromUrl(url: fullUrl).lowercased()
            for oldUrl in arrAllowedUrlsInCuddlyModeCurrentFocus{
                var oldUrl = oldUrl
                if !oldUrl.lowercased().contains("http://") && !oldUrl.lowercased().contains("https://"){
                    oldUrl = "https://"+oldUrl
                }
                let oldDomain = getDomainFromUrl(url: oldUrl).lowercased()
                if domain == oldDomain{
                    boxAllowDomain.isHidden = false
                    var buttonAllowDomainText = "Allow all URLs from <DOMAIN> for this focus session"
                    if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                        buttonAllowDomainText = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowDomainText") as? String ?? buttonAllowDomainText
                    }
                    
                    lblCheckBoxAllowDomain.stringValue = buttonAllowDomainText.replacingOccurrences(of: "<DOMAIN>", with: domain)
                    break;
                }
            }
            
            
//            arrAllowedUrlsInCuddlyModeCurrentFocus
            
            btnBlockAndAddToRelaxMode.isHidden = false
            var urlString = url
            let maxUrlStringCount = 100
            if urlString.count > maxUrlStringCount{
                urlString = String(urlString.prefix(maxUrlStringCount)) + "..."
            }
            
            var blockTitle = titleText.replacingOccurrences(of: "<URL>", with: urlString)
            blockTitle = blockTitle.replacingOccurrences(of: "<FOCUSTYPE>", with: currentRunningFocusModeName)

            if !whatToAchieveInFocusBlock.isEmpty{
                lblIntention.isHidden = false
                lblIntention.stringValue = self.intentionText.replacingOccurrences(of: "<INTENTION>", with: whatToAchieveInFocusBlock)
            }else{
                lblIntention.isHidden = true
            }

            lblTitle.stringValue = blockTitle
            self.isUrlBlockByAi = isUrlBlockByAi
            if SettingsManagerObject.isAiCheckUrlEnabled && !isBlockSuperDistractingFocusModeOn(){
                lblAi.isHidden = false
                if !aiUrlBlockReason.isEmpty{
                    lastBlockReasonFromAi = aiUrlBlockReason
                    self.lblAi.stringValue = aiUrlBlockReason
                }else{
                    if isTimeOut{
                        isAiWaiting = true
                        var waitingAiText = "Waiting for AI decision..."
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            waitingAiText = popUpBlockConfirmVcInfo.value(forKey: "waitingAiText") as? String ?? waitingAiText
                        }
                        self.lblAi.stringValue = waitingAiText
                    }else{
                        var urlNotVerifiedText = "The status of this url could not be verified."
                        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                            urlNotVerifiedText = popUpBlockConfirmVcInfo.value(forKey: "urlNotVerifiedText") as? String ?? urlNotVerifiedText
                        }
                        self.lblAi.stringValue = urlNotVerifiedText
                    }
                    
                }
            }else{
                lblAi.isHidden = true
            }
            
        }
        
        self.currentApp = currentApp
        currentAppName = blockedAppName
        startTimer(durationSeconds: 15)
    }
    
    func startTimer(durationSeconds:Int) {
        currentTimer = 0
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1 {
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }
        
        DispatchQueue.main.async {
            if self.timer != nil{
                self.timer?.invalidate()
                self.timer = nil
            }
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func setProgres(){
        let remainingSeconds = self.totalDuration-currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"

        if hour.count == 1 {
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {

            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
   
            if let pid = self.currentPid{
                
                
                let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
                let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
                let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]
           
                for info in windowInfoList! {
                    let windowPID = info["kCGWindowOwnerPID"] as! UInt32
                    if  windowPID == pid {
                        if let windowFrame = info["kCGWindowBounds"] as? NSDictionary{
                            let height = windowFrame.value(forKey: "Height") as? Int ?? 0
                            if height > 250{
                                let width = windowFrame.value(forKey: "Width") as? Int ?? 0
                                let x = windowFrame.value(forKey: "X") as? Int ?? 0
                                let y = windowFrame.value(forKey: "Y") as? Int ?? 0
                                if self.view.window?.isVisible ?? false{
                                    var frame = NSRect(x: x, y: y, width: width, height: height)
                                    if self.browser != nil{
                                        frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: self.browser!)
                                    }
                                    showBlurWindow(frame: frame, browser: self.browser)
                                }else{
                                    if blurWcObj != nil{
                                        blurWcObj?.window?.close()
                                    }
                                } 
                                break;
                            }
                            
                        }
                        
                    }
                }
            }
//            let blurWindowFrame = blurWcObj?.window?.frame
//            var midX = blurWindowFrame?.midX ?? 0
//            var midY = blurWindowFrame?.midY ?? 0
//            let width = self.view.frame.width
//            let height = self.view.frame.height
//            
//            if !(blurWcObj?.window?.isVisible ?? false){
//                let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//                midX = screenFrame.width / 2
//                midY = screenFrame.height / 2
//            }
//            self.view.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
            
            
//            self.view.window?.setFrameOrigin(NSPoint(x: (midX-(width/2)), y: (midY-(height/2))))
            if self.totalDuration <= self.currentTimer {
                addLog(text: "popUpBlockConfirmVc:- 15 seconds counter completed")
                self.timer?.invalidate()
                self.view.window?.close()
                blurWcObj?.window?.close()
                if self.currentApp != nil && self.isAppBlocking{
                    appdelegate?.focusBlockUnwantedApp(runningApp: self.currentApp!, appName: self.currentAppName, showNotification: false)
                    self.currentApp = nil
                }else{
                    if SettingsManagerObject.isAiCheckUrlEnabled{
                        appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: self.lastBlockReasonFromAi, browser: self.browser, isUrlBlockByAi: self.isUrlBlockByAi, blockReason:"")
                    }else{
                        appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: nil, browser: self.browser, isUrlBlockByAi: self.isUrlBlockByAi, blockReason:"")
                    }
                    
                }
            }
        }
    }
    @objc func performTimerCount() {
        if currentApp != nil{
            exitFullScreen(runningApp:currentApp!)
        }
        currentTimer += 1 
        setProgres()
    }
    
    @IBAction func btnEditSettingClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "block-popup-edit-settings-clicked", metadata: [:])
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnEditSettingClicked")
        closeWindow()
        var focusModeIndex = 0
        if isAnyAllowedFocusModeActivityRunning{
            for i in 0..<arrFocusType.count{
                let dic = arrFocusType[i]
                if dic["id"] as? String ?? ""  == currentRunningFocusType["id"] as? String ?? ""{
                    focusModeIndex = i
                    break;
                }
            }
        }else{
            for i in 0..<arrFocusType.count{
                let dic = arrFocusType[i]
                if dic["isOn"] as? Bool == true{
                    focusModeIndex = i
                    break;
                }
            }
        }
        
        
        var shouldShowPassword = true
        if preferencesWindowControllerObj?.window?.isVisible ?? false{
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = preferencesFocusModesIndex
                addLog(text: "")
            }
            shouldShowPassword = false
        }else{
            preferencesWindowControllerObj?.showWindow(self)
        }
        addLog(text: "Showing preferences")
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = preferencesFocusModesIndex 
            if shouldAskPassword() && shouldShowPassword{
                tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
                tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
                getEnterPasswordVcObjForPreferences().parentVc = nil
                enterPasswordVcObjForPreferences?.removeConstraints()
                addLog(text: "Showing enter password view")
            }
        }
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                focusPreferencesVcObj?.tblViewFocusType.selectRowIndexes(IndexSet(integer: focusModeIndex), byExtendingSelection: false)
                focusPreferencesVcObj?.tblViewFocusType.scrollRowToVisible(focusModeIndex)
            }
        }
    }
    
    
    @IBAction func btnBlockAppClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnBlockAppClicked")
        allApiObject.capturePosthog(event: "block-popup-no-i-was-getting-distracted-clicked", metadata: [:])
        blockClicked()
    }
    
    @IBAction func btnAllowAppClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnAllowAppClicked")
        allApiObject.capturePosthog(event: "block-popup-yes-just-this-time-clicked", metadata: [:])
        if self.currentApp != nil && isAppBlocking{
            arrAllowedAppsInCuddlyModeCurrentFocus.append(currentApp!)
        }else{
            arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
            if checkBoxAllowDomain.state == .on{
                let domain = getDomainFromUrl(url: fullUrl).lowercased()
                arrAllowedDomianInCuddlyModeCurrentFocus.append(domain)
                allApiObject.capturePosthog(event: "allow-all-urls-from-domain-clicked", metadata: ["domain":domain]) // todo test
            }
        }
        
        if let browser = self.browser{
            if let title = getActiveTabTitleOf(browser: browser)?.lowercased(){
                arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(title)
            }
        }
        
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
        if UserDefaults.standard.object(forKey: kUserdefaultsAlertShownFirstTempAllow)  == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsAlertShownFirstTempAllow)
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Allowed! Heads up: it might be a little annoying at first to have to keep allowing sites/apps but within a few days, you'll have taught Focus Bear what apps and websites are productive."
            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                alert.messageText = popUpBlockConfirmVcInfo.value(forKey: "firstTempItemAllowText") as? String ?? alert.messageText
            }
            
            alert.addButton(withTitle: buttonOkText)
            alert.runModal()
        }
        
        if stackViewProgress.isHidden == false{
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
            SettingsManagerObject.putUserLocalDeviceSettings()
        }
    }
    
    func closeWindow(){
        self.currentApp = nil
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
    }
    @IBAction func btnInfoProgressClicked(_ sender: Any) {
        var messageText = "You're teaching Focus Bear what sites and apps are productive for you. It takes a bit of effort at first but within a few days, you'll have taught Focus Bear what apps and websites are productive."
        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
            messageText = popUpBlockConfirmVcInfo.value(forKey: "progressInfoText") as? String ?? messageText
        }
        showTooltip(sender: btnInfoProgress, msg: messageText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    func blockClicked(){
        if self.currentApp != nil && isAppBlocking{
            appdelegate?.focusBlockUnwantedApp(runningApp: self.currentApp!, appName: self.currentAppName, showNotification: false)
            self.currentApp = nil
        }else{
            if SettingsManagerObject.isAiCheckUrlEnabled{
                appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: self.lastBlockReasonFromAi, browser: browser, isUrlBlockByAi: self.isUrlBlockByAi, blockReason:"")
            }else{
                appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: self.isUrlBlockByAi, blockReason:"")
            }

        }
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
        
        if stackViewProgress.isHidden == false{
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
            SettingsManagerObject.putUserLocalDeviceSettings()
        }
    }
    @IBAction func btnBlockAndAddToRelaxModeClicked(_ sender: Any) {
        addLog(text: "[user-action] popUpBlockConfirmVc:- btnBlockAndAddToRelaxModeClicked")
        allApiObject.capturePosthog(event: "save-distraction-for-later", metadata: [:])
        blockClicked()
        allApiObject.postSavedWebsite(url: fullUrl, completionHandler: {json in
            
        })
    }
}
