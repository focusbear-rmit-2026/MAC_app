//
//  intentionBlockedUrlsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class intentionBlockedUrlsVc: NSViewController {

    @IBOutlet weak var btnClose: cursorButton!
    @IBOutlet weak var btnIAmDoneBlockAgain: Button!
    @IBOutlet var textViewIntention: NSTextView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTimer: NSTextField!
    
    var tabUrl:String = ""
    var script = ""
    var browser: BROWSER?
    var currentPid: pid_t?
    var currentApp:NSRunningApplication?
    var isAppBlocking = true
    var blockedAppName = ""
    var timer:Timer?
    var allowFor24Hours = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Your intention for <SITE>"
        btnIAmDoneBlockAgain.title = "I'm done. Block this site now"
        
        
        if let intentionBlockedUrlsVcInfo = configjson.value(forKey: "intentionBlockedUrlsVcInfo") as? NSDictionary{
            lblTitle.stringValue = intentionBlockedUrlsVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnIAmDoneBlockAgain.title = intentionBlockedUrlsVcInfo.value(forKey: "buttonBlockText") as? String ?? btnIAmDoneBlockAgain.title
        }
        
        textViewIntention.isEditable = false
        btnClose.isHidden = true
    }
    override func viewWillDisappear() {
        if self.timer != nil{
            self.timer?.invalidate()
            self.timer = nil
        }
        print("viewWillDisappear********Intentionbox")
        if isAppBlocking{
            saveLastVisibleTimeForCurrentApp()
        }else{
            saveLastVisibleTimeForCurrentUrl()
        }
    }
    
    func setTimerHideWindow(){
        lblTimer.stringValue = ""
        self.timer?.invalidate()
        self.timer = nil
        print("setTimerHideWindow********Intentionbox1")
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            print("setTimerHideWindow********Intentionbox3")
            self?.checkWindowState()
        }
        RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        print("setTimerHideWindow********Intentionbox2")
        checkWindowState()
    }
    
    @objc func checkWindowState(){
        print("checkWindowState********Intentionbox")
        var isBlocked = true
        var isItemAllreadyChecked = false
        var alllowItemEndTime:Date?
        
        if isAppBlocking{
            if !self.blockedAppName.isEmpty{
                for i in 0..<arrAlwaysBlockedAppsData.count{
                    let dictionary = arrAlwaysBlockedAppsData[i]
                    if let blockApp = dictionary["app"] as? String{
                        if blockApp.lowercased() == blockedAppName.lowercased(){
                            isBlocked = dictionary["isBlocked"] as? Bool ?? false
                            alllowItemEndTime = dictionary["endTime"] as? Date
                            isItemAllreadyChecked = true
                            break;
                        }
                    }
                }
            }
        }else{
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == self.tabUrl.lowercased(){
                        isBlocked = dictionary["isBlocked"] as? Bool ?? false
                        alllowItemEndTime = dictionary["endTime"] as? Date
                        isItemAllreadyChecked = true
                        break;
                    }
                }
            }
        }
        
        
        if isItemAllreadyChecked && !allowFor24Hours{
            if isBlocked{
                self.view.window?.close()
            }else {
                if alllowItemEndTime != nil{
                    let diffSeconds = Calendar.current.dateComponents([.second], from: Date(), to: alllowItemEndTime!).second ?? 0
                    
                    if diffSeconds <= 0{
                        self.view.window?.close()
                    }
                    let (h,m,s) = secondsToHoursMinutesSeconds(seconds: diffSeconds)
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
                }
            }
        }
        
    }
    
    func saveLastVisibleTimeForCurrentUrl(){
        if !self.tabUrl.isEmpty{
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == tabUrl.lowercased(){
                        arrAlwaysBlockedSitesData[i]["lastVisibletime"] = Date()
                        break;
                    }
                }
            }
        }
    }
    
    func saveLastVisibleTimeForCurrentApp(){
        if !self.blockedAppName.isEmpty{
            for i in 0..<arrAlwaysBlockedAppsData.count{
                let dictionary = arrAlwaysBlockedAppsData[i]
                if let blockApp = dictionary["app"] as? String{
                    if blockApp.lowercased() == blockedAppName.lowercased(){
                        arrAlwaysBlockedAppsData[i]["lastVisibletime"] = Date()
                        break;
                    }
                }
            }
        }
    }
    
    func resetView(script: String, url:String, browser: BROWSER?, intention:String, currentPid: pid_t?, allowFor24Hours:Bool){
        self.allowFor24Hours = allowFor24Hours
        var title = "You said <SITE> is super distracting for you. What do you want to achieve during your time here?"
        if let intentionBlockedUrlsVcInfo = configjson.value(forKey: "intentionBlockedUrlsVcInfo") as? NSDictionary{
            title = intentionBlockedUrlsVcInfo.value(forKey: "title") as? String ?? title
        }
        title = title.replacingOccurrences(of: "<SITE>", with: url)
        lblTitle.stringValue = title
        self.tabUrl = url
        self.script = script
        self.browser = browser
        self.currentPid = currentPid
        self.currentApp = nil
        isAppBlocking = false
        textViewIntention.string = intention
        blockedAppName = ""
        
        btnIAmDoneBlockAgain.title = "I'm done. Block this site now"
        if let intentionBlockedUrlsVcInfo = configjson.value(forKey: "intentionBlockedUrlsVcInfo") as? NSDictionary{
            btnIAmDoneBlockAgain.title = intentionBlockedUrlsVcInfo.value(forKey: "buttonBlockText") as? String ?? btnIAmDoneBlockAgain.title
        }
        self.setTimerHideWindow()
    }
    
    func resetView(currentApp:NSRunningApplication?, blockedAppName:String, intention:String){
        allowFor24Hours = false
        var title = "You said <SITE> is super distracting for you. What do you want to achieve during your time here?"
        if let intentionBlockedUrlsVcInfo = configjson.value(forKey: "intentionBlockedUrlsVcInfo") as? NSDictionary{
            title = intentionBlockedUrlsVcInfo.value(forKey: "title") as? String ?? title
        }
        title = title.replacingOccurrences(of: "<SITE>", with: blockedAppName)
        lblTitle.stringValue = title
        self.tabUrl = ""
        self.script = ""
        self.browser = nil
        self.currentPid = nil
        self.currentApp = currentApp
        isAppBlocking = true
        textViewIntention.string = intention
        self.blockedAppName = blockedAppName
        
        btnIAmDoneBlockAgain.title = "I'm done. Block this app now"
        if let intentionBlockedUrlsVcInfo = configjson.value(forKey: "intentionBlockedUrlsVcInfo") as? NSDictionary{
            btnIAmDoneBlockAgain.title = intentionBlockedUrlsVcInfo.value(forKey: "buttonBlockAppText") as? String ?? btnIAmDoneBlockAgain.title
        }
        setTimerHideWindow()
    }
    
    
    @IBAction func btnIAmDoneBlockAgainClicked(_ sender: Any) {
        if isAppBlocking{
            if self.currentApp != nil{
                appdelegate?.blockAlwaysBlockedApp(runningApp: self.currentApp!, appName: blockedAppName)
            }
        }else{
            appdelegate?.blockAlwaysBlockedUrl(script: script, browser: browser, url: tabUrl)
        }
        self.view.window?.close()
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {
        
    }
}
