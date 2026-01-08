//
//  setIntentionBlockedUrlsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class setIntentionBlockedUrlsVc: NSViewController {

    @IBOutlet weak var boxTimerSetIntention: NSBox!
    @IBOutlet weak var boxTimer: NSBox!
    @IBOutlet weak var lblTimerTotalSecondsCopy: NSTextField!
    @IBOutlet weak var boxSetIntention: NSBox!
    @IBOutlet weak var lblTitleSetIntention: NSTextField!
    @IBOutlet weak var btnAllow: Button!
    @IBOutlet weak var lblTimerTotalSeconds: NSTextField!
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var stackViewTotalTimeSpent: NSStackView!
    @IBOutlet weak var lblTotalTimeSpent: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblConfirmUseAgain: NSTextField!
    @IBOutlet weak var popupButtonMinutes: NSPopUpButton!
    @IBOutlet weak var lblSelectMinutes: NSTextField!
    @IBOutlet weak var lblCheckBoxDoNotShowThis: NSTextField!
    @IBOutlet weak var checkBoxDoNotShowThis: NSButton!
    @IBOutlet weak var btnBlockIt: Button!
    @IBOutlet weak var btnSetIntention: Button!
    @IBOutlet var textViewIntention: NSTextView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    
    @IBOutlet weak var btnCancelIntention: Button!
    //    var isAutoBlockEnable = true
    var tabUrl:String = ""
    var script = ""
    var timer:Timer?
    var timerFiveSecond:Timer?
    var currentPid: pid_t?
    var browser: BROWSER?
    var isAppBlocking = true
    var currentApp:NSRunningApplication?
    var appName:String = ""
    var confirmText = "Are you sure? You already spent <MINUTES> minutes"
    var currentTimerToAutoBlock = 0
    var totalDurationToAutoBlock = 30
    
    var indexText = "<CURRENTINDEX> of <TOTALCOUNT>"
    var arrTourMessages: [[String : String]] = []
    var currentTourIndex = 0
    let popoverMenuTour = NSPopover()
    var menuTourPopoverVcObj: menuTourPopoverVc?
    var shouldShowTour = false
    var arrSeconds = [30, 60, 120, 300, 600]
    var isUserTypingIntention = false
    var isUserTypingTime:Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnAllow.title = "Allow"
        lblTitleSetIntention.stringValue = "What do you want to achieve during your time here?"
        lblTitle.stringValue = "You said {site} is super distracting for you."
        btnCancelIntention.title = buttonCancelText
        
//        lblTitle.stringValue = "You said <SITE> is super distracting for you. What do you want to achieve during your time here?"
        btnSetIntention.title = "Set Intention"
        btnBlockIt.title = "Block it"
        lblCheckBoxDoNotShowThis.stringValue = "Don't ask for intentions - block super distracting sites immediately"
        lblSelectMinutes.stringValue = "Select minutes to use this site?"
        
        var titleReason = "Reason"
        var titleDuration = "Duration"
        var titleBlockIt = "Block it"
        
        var subTitleReason = "If you need to access this site, enter the reason why and click on Set Intention button."
        var subTitleDuration = "Choose how long you need to access it."
        var subTitleBlockIt = "If you don't need it, click here to block the site"
        
        
        if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
//            lblTitle.stringValue = setIntentionBlockedUrlsVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnSetIntention.title = setIntentionBlockedUrlsVcInfo.value(forKey: "buttonSetIntentionText") as? String ?? btnSetIntention.title
            btnBlockIt.title = setIntentionBlockedUrlsVcInfo.value(forKey: "buttonBlockText") as? String ?? btnBlockIt.title
            lblCheckBoxDoNotShowThis.stringValue = setIntentionBlockedUrlsVcInfo.value(forKey: "buttonDontShowAgainText") as? String ?? lblCheckBoxDoNotShowThis.stringValue
            lblSelectMinutes.stringValue = setIntentionBlockedUrlsVcInfo.value(forKey: "selectMinutesText") as? String ?? lblSelectMinutes.stringValue
            confirmText = setIntentionBlockedUrlsVcInfo.value(forKey: "confirmUseAgainText") as? String ?? confirmText
            
            titleReason = setIntentionBlockedUrlsVcInfo.value(forKey: "titleReason") as? String ?? titleReason
            titleDuration = setIntentionBlockedUrlsVcInfo.value(forKey: "titleDuration") as? String ?? titleDuration
            titleBlockIt = setIntentionBlockedUrlsVcInfo.value(forKey: "titleBlockIt") as? String ?? titleBlockIt
            subTitleReason = setIntentionBlockedUrlsVcInfo.value(forKey: "subTitleReason") as? String ?? subTitleReason
            subTitleDuration = setIntentionBlockedUrlsVcInfo.value(forKey: "subTitleDuration") as? String ?? subTitleDuration
            subTitleBlockIt = setIntentionBlockedUrlsVcInfo.value(forKey: "subTitleBlockIt") as? String ?? subTitleBlockIt
            btnAllow.title = setIntentionBlockedUrlsVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
            lblTitleSetIntention.stringValue = setIntentionBlockedUrlsVcInfo.value(forKey: "titleSetIntention") as? String ?? lblTitleSetIntention.stringValue
        }
        
        btnCancelIntention.buttonColor = NSColor.white.cgColor
        textViewIntention.delegate = self
        
        popupButtonMinutes.removeAllItems()
        popupButtonMinutes.addItems(withTitles: ["30\(secondsSText)", "1\(minutesMText)", "2\(minutesMText)", "5\(minutesMText)", "10\(minutesMText)"])
        
        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"
        
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
            indexText = menuTourVcInfo.value(forKey: "indexText") as? String ?? indexText
        }
        
        arrTourMessages = [
            ["title": titleReason, "description": subTitleReason],
            ["title": titleDuration, "description": subTitleDuration],
            ["title": titleBlockIt, "description": subTitleBlockIt]
        ]
        
        
        for i in 0..<arrTourMessages.count{
            if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
        }
        
        if welcomeOnboardingWcObj != nil && onboardingBlockedUrlsVcObj != nil{
            if welcomeOnboardingWcObj?.window?.isVisible ?? false{
                if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                    shouldShowTour = true
                }
            }
        }
        btnAllow.buttonColor = NSColor.white.cgColor
    }
    
    override func viewWillAppear() {
        if shouldShowTour{
            var titleTour =  "Block distractions"
            if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
                titleTour = setIntentionBlockedUrlsVcInfo.value(forKey: "titleTour") as? String ?? titleTour
            }
            menuTourPopoverVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuTourPopoverVc")) as? menuTourPopoverVc
            popoverMenuTour.contentViewController = menuTourPopoverVcObj
            popoverMenuTour.animates = false
            popoverMenuTour.behavior = .applicationDefined
            currentTourIndex = 0
            menuTourPopoverVcObj?.delegate = self
            menuTourPopoverVcObj?.loadView()
            menuTourPopoverVcObj?.lblMainTitle.stringValue = titleTour
        }
        currentTimerToAutoBlock = 0
        if self.timer != nil{
            self.timer?.invalidate()
            self.timer = nil
        }
        

        totalDurationToAutoBlock = 30
        if isAppInstalledWithinLast3Days(){
            totalDurationToAutoBlock = 60
        }
        
        boxTimer.fillColor = NSColor.clear
        boxTimerSetIntention.fillColor = NSColor.clear
        lblTimerTotalSeconds.textColor = .labelColor
        lblTimerTotalSecondsCopy.textColor = .labelColor
        
        
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDurationToAutoBlock-currentTimerToAutoBlock)
        DispatchQueue.main.async {
            var minute = "\(m)"
            var second = "\(s)"
            if minute.count == 1 {
                minute = "0\(m)"
            }
            if second.count == 1 {
                second = "0\(s)"
            }
            self.lblTimerTotalSeconds.stringValue = "\(minute):\(second)"
            self.lblTimerTotalSecondsCopy.stringValue = "\(minute):\(second)"
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
        RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        checkBoxDoNotShowThis.state = .off
    }
    
    override func viewDidAppear() {
        if shouldShowTour{
            shouldShowTour = false
//            isAutoBlockEnable = false
            popoverMenuTour.show(relativeTo: textViewIntention.bounds, of: textViewIntention, preferredEdge: NSRectEdge.minX)
            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentTourIndex + 1)")
            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentTourIndex]["title"] ?? "", description: arrTourMessages[currentTourIndex]["description"] ?? "", buttonTitle: arrTourMessages[currentTourIndex]["buttonTitle"] ?? "", indexText: currentIndexText, arrList: [], progress: currentTourIndex + 1, progressMaxValue: arrTourMessages.count)
        }
    }
    
    func disableAll(){
        self.lblTimerTotalSeconds.isHidden = true
        self.self.lblTimerTotalSecondsCopy.isHidden = true
        self.textViewIntention.isHidden = true
        self.btnBlockIt.isHidden = true
        self.checkBoxDoNotShowThis.isHidden = true
        self.popupButtonMinutes.isHidden = true
        btnSetIntention.isHidden = true
        lblCheckBoxDoNotShowThis.isHidden = true
        self.textViewIntention.enclosingScrollView?.isHidden = true
        lblSelectMinutes.isHidden = true
        btnAllow.isHidden = true
    }
    
    func enableAll(){
        self.lblTimerTotalSeconds.isHidden = false
        self.self.lblTimerTotalSecondsCopy.isHidden = false
        self.textViewIntention.isHidden = false
        self.btnBlockIt.isHidden = false
        self.checkBoxDoNotShowThis.isHidden = false
        self.popupButtonMinutes.isHidden = false
        btnSetIntention.isHidden = false
        lblCheckBoxDoNotShowThis.isHidden = false
        self.textViewIntention.enclosingScrollView?.isHidden = false
        lblSelectMinutes.isHidden = false
        stackViewTotalTimeSpent.isHidden = true
        btnAllow.isHidden = false
        if !isAppBlocking{
            var totalDurationaSaved = 0
            if let timeSpentInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalTimeSpentOnDistractingSites) as? [String:Any]{
                if let date = timeSpentInfo["date"] as? Date, let duration = timeSpentInfo["duration"] as? Int{
                    if Calendar.current.isDateInToday(date){
                        totalDurationaSaved = duration
                    }
                }
            }
            if totalDurationaSaved != 0{
                stackViewTotalTimeSpent.isHidden = false
                let time = getStringTimeFromSeconds(seconds:totalDurationaSaved)
                var timeSpentText = "Total time spent: <TIME>"
                if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
                    timeSpentText = setIntentionBlockedUrlsVcInfo.value(forKey: "timeSpentText") as? String ?? timeSpentText
                }
                timeSpentText = timeSpentText.replacingOccurrences(of: "<TIME>", with: "\(time)")
                lblTotalTimeSpent.stringValue = timeSpentText
            }
        }
    }
    
    func resetView(script: String, url:String, currentPid: pid_t?, browser: BROWSER?, allreadyCheckedIndex:Int, isAppBlocking:Bool, currentApp:NSRunningApplication?, blockedAppName:String, blockItem:String){
        boxSetIntention.isHidden = true
        if self.timerFiveSecond != nil{
            self.timerFiveSecond?.invalidate()
            self.timerFiveSecond = nil
        }
        popupButtonMinutes.selectItem(at: 0)
        var title = "You said <SITE> is super distracting for you."
        if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
            title = setIntentionBlockedUrlsVcInfo.value(forKey: "titleDistracting") as? String ?? title
        }
        self.isAppBlocking = isAppBlocking
        self.currentApp = currentApp
        self.appName = blockedAppName
        self.lblConfirmUseAgain.isHidden = true
        self.lblTimer.isHidden = true
        btnSetIntention.isEnabled = false
        textViewIntention.string = ""
        self.tabUrl = url
        self.script = script
        self.currentPid = currentPid
        self.browser = browser
        enableAll()
        
        if self.isAppBlocking{
            stackViewTotalTimeSpent.isHidden = true
            lblCheckBoxDoNotShowThis.stringValue = "Don't ask for intentions - block super distracting apps immediately"
            if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
                lblCheckBoxDoNotShowThis.stringValue = setIntentionBlockedUrlsVcInfo.value(forKey: "buttonDontShowAgainForBlockAppText") as? String ?? lblCheckBoxDoNotShowThis.stringValue
            }
            title = title.replacingOccurrences(of: "<SITE>", with: blockedAppName)
            lblTitle.stringValue = title
            if allreadyCheckedIndex != -1{
                if allreadyCheckedIndex < arrAlwaysBlockedAppsData.count{
                    let dictionary = arrAlwaysBlockedAppsData[allreadyCheckedIndex]
                    if let blockApp = dictionary["app"] as? String{
                        if blockApp.lowercased() == blockedAppName.lowercased(){
                            let lastDuration = dictionary["duration"] as? Int ?? 0
                            if let lastVisibletime = dictionary["lastVisibletime"] as? Date{
                                
                                let currentDate = Date()
                                let diffMinute = Calendar.current.dateComponents([.minute], from: lastVisibletime, to: currentDate).minute ?? 0
                                
                                if diffMinute < 10{
                                    startTimer(duration: 5)
                                    lblConfirmUseAgain.isHidden = false
                                    let minutes = lastDuration/60
                                    if lastDuration == 30{
                                        lblConfirmUseAgain.stringValue = confirmText.replacingOccurrences(of: "<MINUTES>", with: "0.5")
                                    }else{
                                        lblConfirmUseAgain.stringValue = confirmText.replacingOccurrences(of: "<MINUTES>", with: "\(minutes)")
                                    }
                                    disableAll()
                                }else{
                                    self.lblConfirmUseAgain.isHidden = true
                                    self.lblTimer.isHidden = true
                                    
                                    enableAll()
                                }
                                
                            }
                        }
                    }
                }
            }

        }else{
            lblCheckBoxDoNotShowThis.stringValue = "Don't ask for intentions - block super distracting sites immediately"
            if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
                lblCheckBoxDoNotShowThis.stringValue = setIntentionBlockedUrlsVcInfo.value(forKey: "buttonDontShowAgainText") as? String ?? lblCheckBoxDoNotShowThis.stringValue
            }
            
            
            if blockItem.isEmpty{
                title = title.replacingOccurrences(of: "<SITE>", with: url)
            }else{
                title = title.replacingOccurrences(of: "<SITE>", with: "\"\(blockItem)\"")
            }
            lblTitle.stringValue = title
            if allreadyCheckedIndex != -1{
                if allreadyCheckedIndex < arrAlwaysBlockedSitesData.count{
                    let dictionary = arrAlwaysBlockedSitesData[allreadyCheckedIndex]
                    if let blockUrl = dictionary["url"] as? String{
                        if blockUrl.lowercased() == url.lowercased(){
                            let lastDuration = dictionary["duration"] as? Int ?? 0
                            if let lastVisibletime = dictionary["lastVisibletime"] as? Date{
                                
                                let currentDate = Date()
                                let diffMinute = Calendar.current.dateComponents([.minute], from: lastVisibletime, to: currentDate).minute ?? 0
                                
                                if diffMinute < 10{
                                    startTimer(duration: 5)
                                    lblConfirmUseAgain.isHidden = false
                                    let minutes = lastDuration/60
                                    if lastDuration == 30{
                                        lblConfirmUseAgain.stringValue = confirmText.replacingOccurrences(of: "<MINUTES>", with: "0.5")
                                    }else{
                                        lblConfirmUseAgain.stringValue = confirmText.replacingOccurrences(of: "<MINUTES>", with: "\(minutes)")
                                    }
                                    disableAll()
                                }else{
                                    self.lblConfirmUseAgain.isHidden = true
                                    self.lblTimer.isHidden = true
                                    
                                    enableAll()
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    }
    var currentTimer = 0
    var totalDuration = 0
    func startTimer(duration:Int) {
        lblTimer.isHidden = false
        currentTimer = 0
        totalDuration = duration
        setProgress()
        DispatchQueue.global().sync {
            self.timerFiveSecond = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerFiveSecond), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerFiveSecond!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func performTimerFiveSecond() {
        currentTimer += 1
        setProgress()
    }
    
    func setProgress(){
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        DispatchQueue.main.async {
            var minute = "\(m)"
            var second = "\(s)"
            if minute.count == 1 {
                minute = "0\(m)"
            }
            if second.count == 1 {
                second = "0\(s)"
            }

            self.lblTimer.isHidden = false
            self.lblTimer.stringValue = "\(minute):\(second)"
            
            if self.totalDuration <= self.currentTimer {
                
                self.timerFiveSecond?.invalidate()
                
                self.lblConfirmUseAgain.isHidden = true
                self.lblTimer.isHidden = true
                
                self.enableAll()
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        if self.view.window?.isVisible ?? false{
                            let blurWindowFrame = blurWcObj?.window?.frame
                            var midX = blurWindowFrame?.midX ?? 0
                            var midY = blurWindowFrame?.midY ?? 0
                            let width = self.view.frame.width
                            let height = self.view.frame.height
                            
                            if !(blurWcObj?.window?.isVisible ?? false){
                                let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
                                midX = screenFrame.width / 2
                                midY = screenFrame.height / 2
                            }
                            
                            self.view.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
                        }
                    }
                }
                
            }
        }
    }
    func closeWindow(){
        self.view.window?.close()
        blurWcObj?.window?.close()
    }
    
    
    override func viewWillDisappear() {
        self.timer?.invalidate()
        self.timerFiveSecond?.invalidate()
        boxSetIntention.isHidden = true
    }
    
    @objc func performTimerCount() {
        if isUserTypingIntention{
            if let isUserTypingTime = isUserTypingTime{
                let diffSeconds = Calendar.current.dateComponents([.second], from: isUserTypingTime, to: Date()).second ?? 0
                if diffSeconds > 2{
                    isUserTypingIntention = false
                }
            }
        }
        
        if !popoverMenuTour.isShown && !isUserTypingIntention{
            currentTimerToAutoBlock += 1
            if self.totalDurationToAutoBlock <= self.currentTimerToAutoBlock {
                btnBlockItClicked(self)
                return;
            }
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
                                    frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: browser!)
                                }
                                showBlurWindow(frame: frame, browser: self.browser)
                            }else{
                                if blurWcObj != nil{
                                    if blurWcObj?.window?.isVisible ?? false{
                                        blurWcObj?.window?.close()
                                    }
                                }
                            }
                            break;
                        }
                        
                    }
                    
                }
            }
        }
        
        if self.view.window?.isVisible ?? false{
            let blurWindowFrame = blurWcObj?.window?.frame
            var midX = blurWindowFrame?.midX ?? 0
            var midY = blurWindowFrame?.midY ?? 0
            let width = self.view.frame.width
            let height = self.view.frame.height
            
            if !(blurWcObj?.window?.isVisible ?? false){
                let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
                midX = screenFrame.width / 2
                midY = screenFrame.height / 2
            }
            self.view.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
        }
        
        let remainingSeconds = self.totalDurationToAutoBlock-currentTimerToAutoBlock
        
        
        
        if remainingSeconds < 16{
            boxTimer.fillColor = NSColor(resource: .darkOrange)
            boxTimerSetIntention.fillColor = NSColor(resource: .darkOrange)
            lblTimerTotalSeconds.textColor = .white
            lblTimerTotalSecondsCopy.textColor = .white
        }else{
            boxTimer.fillColor = NSColor.clear
            boxTimerSetIntention.fillColor = NSColor.clear
            lblTimerTotalSeconds.textColor = .labelColor
            lblTimerTotalSecondsCopy.textColor = .labelColor
        }
        
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
        DispatchQueue.main.async {
            var minute = "\(m)"
            var second = "\(s)"
            if minute.count == 1 {
                minute = "0\(m)"
            }
            if second.count == 1 {
                second = "0\(s)"
            }
            self.lblTimerTotalSeconds.stringValue = "\(minute):\(second)"
            self.lblTimerTotalSecondsCopy.stringValue = "\(minute):\(second)"
        }
    }
    
    @IBAction func btnSetIntentionClicked(_ sender: Any) {
        let seconds = arrSeconds[popupButtonMinutes.indexOfSelectedItem]
        allApiObject.capturePosthog(event: "set-super-distracting-intention", metadata: ["seconds": seconds])
        if isAppBlocking{
            if self.currentApp != nil{
                appdelegate?.saveIntentionForBlockedApp(intention: textViewIntention.string, seconds: seconds, runningApp: self.currentApp!, appName: self.appName)
            }
        }else{
            appdelegate?.saveIntentionForBlockedUrl(url: self.tabUrl, script: self.script, browser: self.browser, intention: textViewIntention.string, seconds: seconds, currentPid:currentPid)
        }
        closeWindow()
        boxSetIntention.isHidden = true
    }
    @IBAction func btnBlockItClicked(_ sender: Any) {
        if isAppBlocking{
            if self.currentApp != nil{
                appdelegate?.blockAlwaysBlockedApp(runningApp: self.currentApp!, appName: self.appName)
            }
        }else{
            appdelegate?.blockAlwaysBlockedUrl(script: self.script, browser: browser, url:tabUrl)
        }
        
        closeWindow()
    }
    @IBAction func checkBoxDoNotShowThisClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if isAppBlocking{
            if checkBoxDoNotShowThis.state == .on{
                SettingsManagerObject.immediatelyBlockDistractingApps = true
                allApiObject.capturePosthog(event: "settings-changed-immediately-block-app-enabled", metadata: [:])
            }else{
                SettingsManagerObject.immediatelyBlockDistractingApps = false
                allApiObject.capturePosthog(event: "settings-changed-immediately-block-app-disabled", metadata: [:])
            }
        }else{
            if checkBoxDoNotShowThis.state == .on{
                SettingsManagerObject.immediatelyBlockDistractingSites = true
                allApiObject.capturePosthog(event: "settings-changed-immediately-block-url-enabled", metadata: [:])
            }else{
                SettingsManagerObject.immediatelyBlockDistractingSites = false
                allApiObject.capturePosthog(event: "settings-changed-immediately-block-url-disabled", metadata: [:])
            }
        }
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        var msg = "Privacy note: we only store this data on your local machine not on our servers"
        if let setIntentionBlockedUrlsVcInfo = configjson.value(forKey: "setIntentionBlockedUrlsVcInfo") as? NSDictionary{
            msg = setIntentionBlockedUrlsVcInfo.value(forKey: "privacyNoteText") as? String ?? msg
        }
        showTooltip(sender: btnInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    @IBAction func btnAllowClicked(_ sender: Any) {
        boxSetIntention.isHidden = false
        isUserTypingIntention = true
        isUserTypingTime = Date()
    }
    
    
    @IBAction func btnCancelIntentionClicked(_ sender: Any) {
        boxSetIntention.isHidden = true
    }
}


extension setIntentionBlockedUrlsVc: NSTextViewDelegate{
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textViewIntention{
            if textView.string.count > 0{
                btnSetIntention.isEnabled = true
            }else{
                btnSetIntention.isEnabled = false
            }
            
            isUserTypingIntention = true
            isUserTypingTime = Date()
        }
    }
}




extension setIntentionBlockedUrlsVc: TourDelegate{
    func buttonNextClicked() {
        currentTourIndex += 1
        if currentTourIndex == 1{
            popoverMenuTour.show(relativeTo: lblSelectMinutes.bounds, of: lblSelectMinutes, preferredEdge: NSRectEdge.minX)
        }else if currentTourIndex == 2{
            popoverMenuTour.show(relativeTo: btnBlockIt.bounds, of: btnBlockIt, preferredEdge: NSRectEdge.minX)
        }
        if currentTourIndex < arrTourMessages.count{
            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentTourIndex + 1)")
            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentTourIndex]["title"] ?? "", description: arrTourMessages[currentTourIndex]["description"] ?? "", buttonTitle: arrTourMessages[currentTourIndex]["buttonTitle"] ?? "", indexText: currentIndexText, arrList: [], progress: currentTourIndex + 1, progressMaxValue: arrTourMessages.count)
        }else{
            popoverMenuTour.close()
        }
    }
    func buttonCloseClicked() {
        popoverMenuTour.close()
    }
}
