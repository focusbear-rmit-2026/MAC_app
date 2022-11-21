//
//  popUpBlockConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 05/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class popUpBlockConfirmVc: NSViewController {

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
    
    var titleText = "Do you need to use <URL> when you're focusing on <FOCUSTYPE>?"
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
        }
        lblTitle.stringValue = titleText
        
        btnAllow.buttonColor = NSColor.white.cgColor
        btnEditSettings.buttonColor = NSColor.white.cgColor
    }
    
    func resetView(blockedAppName:String, currentApp:NSRunningApplication?, url:String, script:String, isBlockApp:Bool){
        if self.currentApp != nil{
            if self.currentApp == currentApp{
                return;
            }
        }
        isAppBlocking = isBlockApp
        self.script = script
        self.url = url
        if isAppBlocking{
            var blockTitle = titleText.replacingOccurrences(of: "<URL>", with: blockedAppName)
            blockTitle = blockTitle.replacingOccurrences(of: "<FOCUSTYPE>", with: appdelegate!.currentRunningFocusModeName)
            lblTitle.stringValue = blockTitle
        }else{
            var blockTitle = titleText.replacingOccurrences(of: "<URL>", with: url)
            blockTitle = blockTitle.replacingOccurrences(of: "<FOCUSTYPE>", with: appdelegate!.currentRunningFocusModeName)
            lblTitle.stringValue = blockTitle
        }
        
        self.currentApp = currentApp
        currentAppName = blockedAppName
        startTimer(durationSeconds: 15)
    }
    func startTimer(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }

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
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
                if self.currentApp != nil && self.isAppBlocking{
                    appdelegate?.focusBlockUnwantedApp(runningApp: self.currentApp!, appName: self.currentAppName, showNotification: false)
                    self.currentApp = nil
                }else{
                    appdelegate?.focusBlockUnwantedUrl(script: self.script, url: self.url)
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
        addLog(text: "btn Edit FocusMode Clicked from menu")
        closeWindow()
        for i in 0..<arrFocusType.count{
            let dic = arrFocusType[i]
            if dic["isOn"] as? Bool == true{
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
                        tabview.view.addSubview(Focus_Bear.enterPasswordVcObj!.view)
                        tabview.view.addConstraints(subView: Focus_Bear.enterPasswordVcObj!.view)
                        Focus_Bear.enterPasswordVcObj?.parentVc = nil
                        addLog(text: "Showing enter password view")
                    }
                }
                
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        focusPreferencesVcObj?.tblViewFocusType.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                        focusPreferencesVcObj?.tblViewFocusType.scrollRowToVisible(i)
                    }
                }
                
                break;
            }
        }
        
    }
    @IBAction func btnBlockAppClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "block-popup-no-i-was-getting-distracted-clicked", metadata: [:])
        if self.currentApp != nil && isAppBlocking{
            appdelegate?.focusBlockUnwantedApp(runningApp: self.currentApp!, appName: self.currentAppName, showNotification: false)
            self.currentApp = nil
        }else{
            appdelegate?.focusBlockUnwantedUrl(script: script, url: url)
        }
        self.timer?.invalidate()
        self.view.window?.close()
    }
    @IBAction func btnAllowAppClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "block-popup-yes-just-this-time-clicked", metadata: [:])
        if self.currentApp != nil && isAppBlocking{
            appdelegate!.arrAllowedAppsInCuddlyModeCurrentFocus.append(currentApp!)
        }else{
            appdelegate!.arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
        }
        self.timer?.invalidate()
        self.view.window?.close()
    }
    
    func closeWindow(){
        self.currentApp = nil
        self.timer?.invalidate()
        self.view.window?.close()
    }
}
