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
    
    var tabUrl:String = ""
    var script = ""
    var browser: BROWSER?
    var currentPid: pid_t?
    var currentApp:NSRunningApplication?
    var isAppBlocking = true
    var blockedAppName = ""
    var timer:Timer?
    
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
        
        if isAppBlocking{
            saveLastVisibleTimeForCurrentApp()
        }else{
            saveLastVisibleTimeForCurrentUrl()
        }
    }
    
    func setTimerHideWindow(){
        if self.timer != nil{
            self.timer?.invalidate()
            self.timer = nil
        }
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkWindowState), userInfo: nil, repeats: true)
        RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
    }
    
    @objc func checkWindowState(){
        
        var isBlocked = true
        var isUrlAllreadyChecked = false
//        var intention = ""
//        var isClosed = false
        var alllowUrlEndTime:Date?
//        var urlAllreadyCheckedIndex = -1
        for i in 0..<arrAlwaysBlockedSitesData.count{
            let dictionary = arrAlwaysBlockedSitesData[i]
            if let blockUrl = dictionary["url"] as? String{
                if blockUrl.lowercased() == self.tabUrl.lowercased(){
                    isBlocked = dictionary["isBlocked"] as? Bool ?? false
//                    intention = dictionary["intention"] as? String ?? ""
//                    isClosed = dictionary["closed"] as? Bool ?? false
                    alllowUrlEndTime = dictionary["endTime"] as? Date
                    isUrlAllreadyChecked = true
//                    urlAllreadyCheckedIndex = i
                    break;
                }
            }
        }
        if isUrlAllreadyChecked{
            if isBlocked{
                self.view.window?.close()
            }else {
//                var shouldSetIntentionAgain = false
                if alllowUrlEndTime != nil{
                    if Date().compare(alllowUrlEndTime!) == .orderedDescending{ //>
                        self.view.window?.close()
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
    
    func resetView(script: String, url:String, browser: BROWSER?, intention:String, currentPid: pid_t?){
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
        if self.timer != nil{
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    func resetView(currentApp:NSRunningApplication?, blockedAppName:String, intention:String){
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
