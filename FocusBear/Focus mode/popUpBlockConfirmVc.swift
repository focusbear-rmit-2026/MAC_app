//
//  popUpBlockConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 05/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class popUpBlockConfirmVc: NSViewController {

    @IBOutlet weak var lblAi: NSTextField!
    @IBOutlet weak var lblIntention: NSTextField!
    @IBOutlet weak var btnEditSettings: Button!
    @IBOutlet weak var btnBlock: Button!
    @IBOutlet weak var btnAllow: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var currentApp:NSRunningApplication?
    var currentAppName = ""
    var isAppBlocking = true
    var url:String = ""
    var script:String = ""
    var browser:BROWSER?
    var titleText = "Do you need to use <URL> when you're focusing on <FOCUSTYPE>?"
    var intentionText = "Your intention was \"<INTENTION>\""
    var currentPid: pid_t?
    var timerHideAlert:Timer?
    var lastBlockReasonFromAi = ""
//    var alertTimer:NSAlert?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnAllow.title = "Yes - just this time"
        btnBlock.title = "No - I was getting distracted"
        btnEditSettings.title = "Edit Settings"

        if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
            titleText = popUpBlockConfirmVcInfo.value(forKey: "title") as? String ?? titleText
            btnAllow.title = popUpBlockConfirmVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
            btnBlock.title = popUpBlockConfirmVcInfo.value(forKey: "buttonBlockText") as? String ?? btnBlock.title
            btnEditSettings.title = popUpBlockConfirmVcInfo.value(forKey: "buttonEditSettingsText") as? String ?? btnEditSettings.title
            intentionText = popUpBlockConfirmVcInfo.value(forKey: "intentionText") as? String ?? intentionText
        }
        lblTitle.stringValue = titleText
        
        btnAllow.buttonColor = NSColor.white.cgColor
        btnEditSettings.buttonColor = NSColor.white.cgColor
    }
    
    func setTimerHideAlertFewSeconds(){
        DispatchQueue.global().sync {
            self.timerHideAlert = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.hideAlert), userInfo: nil, repeats: false)
            RunLoop.main.add((self.timerHideAlert!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func hideAlert(){
        if alertReasonAutoAllowWcObj != nil{
            if alertReasonAutoAllowWcObj?.window != nil{
                //self.view.window?.endSheet(self.alertTimer!.window)
                alertReasonAutoAllowWcObj?.window?.close()
            }
        }
        if timerHideAlert != nil{
            timerHideAlert?.invalidate()
            timerHideAlert = nil
        }
    }
    func resetView(blockedAppName:String, currentApp:NSRunningApplication?, url:String, script:String, isBlockApp:Bool, browser:BROWSER?,currentPid: pid_t?, tabTitle:String?){
        if self.currentApp != nil{
            if self.currentApp == currentApp{
                return;
            }
        }
        isAppBlocking = isBlockApp
        self.script = script
        self.url = url
        var currentRunningFocusModeName = ""
        self.browser = browser
        self.currentPid = currentPid
        lastBlockReasonFromAi = ""
        
        if isAnyAllowedFocusModeActivityRunning{
            if currentHabitPlaying != nil{
                currentRunningFocusModeName = currentHabitPlaying?.name ?? ""
            }else if currentActivityPlaying != nil{
                currentRunningFocusModeName = currentActivityPlaying?.name ?? ""
            }
        }else{
            currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
        }
        
        if isAppBlocking{
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
        }else{
            
            if alertReasonAutoAllowWcObj != nil{
                if alertReasonAutoAllowWcObj?.window != nil{
                    if alertReasonAutoAllowWcObj?.window?.isVisible ?? false{
                        alertReasonAutoAllowWcObj?.window?.close()
                    }
                }
            }
            if timerHideAlert != nil{
                timerHideAlert?.invalidate()
                timerHideAlert = nil
            }
            
            var blockTitle = titleText.replacingOccurrences(of: "<URL>", with: url)
            blockTitle = blockTitle.replacingOccurrences(of: "<FOCUSTYPE>", with: currentRunningFocusModeName)
            //var intentionText = ""//\n\n" + intentionText.replacingOccurrences(of: "<INTENTION>", with: whatToAchieveInFocusBlock)
            if !whatToAchieveInFocusBlock.isEmpty{
                lblIntention.isHidden = false
                lblIntention.stringValue = self.intentionText.replacingOccurrences(of: "<INTENTION>", with: whatToAchieveInFocusBlock)
            }else{
                lblIntention.isHidden = true
            }
            
            
            
            lblTitle.stringValue = blockTitle
            

            //ye sara kaam agar ai ki setting enable h to hi hoga vrna na hoga //
            
            
            if SettingsManagerObject.isAiCheckUrlEnabled{
                
                var checkingUrlText = "Checking if this URL is safe to use for your current focus mode. Will take about 4-5 seconds to check. If safe, it will automatically be allowed."
                
                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                    checkingUrlText = popUpBlockConfirmVcInfo.value(forKey: "checkingUrlText") as? String ?? checkingUrlText
                }
                lblAi.stringValue = checkingUrlText
                lblAi.isHidden = false
                var tab_title = ""
                if tabTitle == nil{
                    if browser != nil{
                        if let title = getActiveTabTitleOf(browser: browser!){
                            tab_title = title
                        }
                    }
                }else{
                    tab_title = tabTitle!
                }
                
                allApiObject.chatGPTIsURLSafe(url: url, tab_title: tab_title, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, completionHandler: {dic, checkedUrl, payload  in
                    if dic != nil && !self.isAppBlocking{
                        if url == checkedUrl{
                            DispatchQueue.main.async{
                                let reason = dic?.value(forKey: "reason") as? String ?? ""
                                self.lastBlockReasonFromAi = reason
                                self.lblAi.stringValue = reason
                                if let dProbability = dic?.value(forKey: "allowed_probability") as? Double{
                                    if(dProbability >= 0.80){
                                        // Safe URL
                                        addLog(text: "popUpBlockConfirmVc:- url is safe according to chat gpt")
                                        allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                        
                                        arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                                        arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                                        
                                        self.timer?.invalidate()
                                        self.view.window?.close()
                                        blurWcObj?.window?.close()
                                        
                                        var shouldShowAlert = true

                                        if alertReasonAutoAllowWcObj != nil{
                                            if alertReasonAutoAllowWcObj?.window != nil{
                                                if alertReasonAutoAllowWcObj?.window?.isVisible ?? false{
                                                    shouldShowAlert = false
                                                }
                                            }
                                        }
                                        if !SettingsManagerObject.isAiAllowUrlShowAlertEnabled{
                                            shouldShowAlert = false
                                        }
                                        if shouldShowAlert{
                                            self.setTimerHideAlertFewSeconds()
                                            let percentage = dProbability * 100
                                            
                                            var titleUrlSafeText = "Safe site according to AI (probability <PERCENTAGE>%)"
                                            var reasonText = "Reason: <REASON>"
                                            var buttonBadDecisionText = "Bad decision"
                                            var checkboxDonotShowText = "Don't show this anymore"
                                            
                                            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                                                titleUrlSafeText = popUpBlockConfirmVcInfo.value(forKey: "titleUrlSafeText") as? String ?? titleUrlSafeText
                                                reasonText = popUpBlockConfirmVcInfo.value(forKey: "reasonText") as? String ?? reasonText
                                                buttonBadDecisionText = popUpBlockConfirmVcInfo.value(forKey: "buttonBadDecisionText") as? String ?? buttonBadDecisionText
                                                checkboxDonotShowText = popUpBlockConfirmVcInfo.value(forKey: "checkboxDonotShowText") as? String ?? checkboxDonotShowText
                                            }
                                            
                                            titleUrlSafeText = titleUrlSafeText.replacingOccurrences(of: "<PERCENTAGE>", with: "\(percentage)")
                                            reasonText = reasonText.replacingOccurrences(of: "<REASON>", with: reason)
                                            
                                            showAutoUrlAllowWindow(title: titleUrlSafeText, subTitle: reasonText, buttonCancelText: buttonBadDecisionText, checkBoxText: checkboxDonotShowText, payload: payload!, response: dic!)
                                            
                                        }
                                        
                                        
                                    }else if(dProbability >= 0.50 && dProbability < 0.80){
                                        //Ask user
                                        
                                    }else{
                                        //Unsafe url
                                    }
                                }
                                
                            }
                        }
                    }else{
                        DispatchQueue.main.async{
                            if !self.isAppBlocking{
                                var urlNotVerifiedText = "The status of this url could not be verified."
                                if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                                    urlNotVerifiedText = popUpBlockConfirmVcInfo.value(forKey: "urlNotVerifiedText") as? String ?? urlNotVerifiedText
                                }
                                self.lblAi.stringValue = urlNotVerifiedText
                            }
                        }
                    }
                })
                
                
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
                            if height > 100{
                                let width = windowFrame.value(forKey: "Width") as? Int ?? 0
                                let x = windowFrame.value(forKey: "X") as? Int ?? 0
                                let y = windowFrame.value(forKey: "Y") as? Int ?? 0
                                
                                if self.view.window?.isVisible ?? false{
                                    showBlurWindow(frame: NSRect(x: x, y: y, width: width, height: height))
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
            let blurWindowFrame = blurWcObj?.window?.frame
            let midX = blurWindowFrame?.midX ?? 0
            let midY = blurWindowFrame?.midY ?? 0
            let width = popUpBlockConfirmWcObj?.window?.frame.width ?? 500
            let height = popUpBlockConfirmWcObj?.window?.frame.height ?? 500
            
            
            self.view.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
            
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
//                    if ai enable then//
                    //self.script = lastBlockReasonFromAi
                    if SettingsManagerObject.isAiCheckUrlEnabled{
                        appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: self.lastBlockReasonFromAi)
                    }else{
                        appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: nil)
                    }
                    
                }
            }
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1 
        setProgres()
    }
    
    @IBAction func btnEditSettingClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "block-popup-edit-settings-clicked", metadata: [:])
        addLog(text: "popUpBlockConfirmVc:- btnEditSettingClicked")
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
                tabview.selectedTabViewItemIndex = 1
                addLog(text: "")
            }
            shouldShowPassword = false
        }else{
            preferencesWindowControllerObj?.showWindow(self)
        }
        addLog(text: "Showing preferences")
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = 1
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil && shouldShowPassword{
                tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
                tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
                getEnterPasswordVcObjForPreferences().parentVc = nil
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
        addLog(text: "popUpBlockConfirmVc:- btnBlockAppClicked")
        allApiObject.capturePosthog(event: "block-popup-no-i-was-getting-distracted-clicked", metadata: [:])
        if self.currentApp != nil && isAppBlocking{
            appdelegate?.focusBlockUnwantedApp(runningApp: self.currentApp!, appName: self.currentAppName, showNotification: false)
            self.currentApp = nil
        }else{
            if SettingsManagerObject.isAiCheckUrlEnabled{
                appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: self.lastBlockReasonFromAi)
            }else{
                appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url, lastBlockReasonFromAi: nil)
            }
            
            if timerHideAlert != nil{
                timerHideAlert?.invalidate()
                timerHideAlert = nil
            }
            
        }
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
    }
    
    @IBAction func btnAllowAppClicked(_ sender: Any) {
        addLog(text: "popUpBlockConfirmVc:- btnAllowAppClicked")
        allApiObject.capturePosthog(event: "block-popup-yes-just-this-time-clicked", metadata: [:])
        if self.currentApp != nil && isAppBlocking{
            arrAllowedAppsInCuddlyModeCurrentFocus.append(currentApp!)
        }else{
            arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
            if timerHideAlert != nil{
                timerHideAlert?.invalidate()
                timerHideAlert = nil
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
    }
    
    func closeWindow(){
        self.currentApp = nil
        self.timer?.invalidate()
        self.view.window?.close()
        blurWcObj?.window?.close()
    }
}
//[NEEDSTRANSLATION]
