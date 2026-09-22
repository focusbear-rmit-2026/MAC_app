//
//  AppDelegate.swift
//  FBHelper
//
//  Created by Prashant Sawnani on 25/06/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let startMainAppForceQuitMonitoring = Notification.Name("startMainAppForceQuitMonitoring")
    let stopMainAppForceQuitMonitoring = Notification.Name("stopMainAppForceQuitMonitoring")
    // #2575: main app asks us to relaunch it at a stored time ("turn everything off until tomorrow").
    let scheduleMainAppRestart = Notification.Name("scheduleMainAppRestart")

    let mainAppQuitByUser = Notification.Name("MainAppQuitByUser")
    var timerBackgroundThread:Timer?
    var timerMainAppForceQuitMonitoring:Timer?
    var timerScheduledRestart:Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let systemVersion = ProcessInfo().operatingSystemVersion
        macOSVersion = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
        
        if FileManager.default.fileExists(atPath: "/Users/\(NSUserName())/Desktop/is_fb_test_user.txt"){
            isTestUser = true
        }

        
        let bundel = Bundle.main.bundleIdentifier ?? ""
        let applicationSupportPath = "/Users/\(NSUserName())/Library/Application Support/\(bundel)"
        CreateDirectoryIfNotExist(path: applicationSupportPath)
        let applicationSupportURL  = URL(fileURLWithPath: applicationSupportPath)
        DebugLogsURL = applicationSupportURL.appendingPathComponent("Debug_Logs.txt")
        
        addLog(text: "applicationDidFinishLaunching")
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.setTimerMainAppForceQuitMonitoring), name: startMainAppForceQuitMonitoring, object: "com.App.EarnYourScreentime")
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.stopTimerMainAppForceQuitMonitoring), name: stopMainAppForceQuitMonitoring, object: "com.App.EarnYourScreentime")
        
        if let state = sharedDefaults?.object(forKey: kUserdefaultsStartMainAppIfNotRunning) as? Bool{
            if state{
                setTimerMainAppForceQuitMonitoring()
            }
        }

        // #2575: watch for the main app's scheduled-restart request, and also pick up an outstanding one
        // written before we (re)launched — the reboot case, where the target time may already have passed.
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.onScheduleMainAppRestart), name: scheduleMainAppRestart, object: "com.App.EarnYourScreentime")
        if sharedDefaults?.object(forKey: kUserdefaultsMainAppScheduledRestartDate) is Date{
            startScheduledRestartTimer()
        }


        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.mainAppQuit), name: mainAppQuitByUser, object: "com.App.EarnYourScreentime")
        if sharedDefaults?.object(forKey: kUserdefaultsAppQuitForUser) is Date{
            if let state = sharedDefaults?.object(forKey: kUserdefaultsDontShowNudgeView) as? Bool{
                if state{
                    return;
                }
            }
            setBackgroundThreadTimer()
        }
//        getConfigFile()
    }
    
//    func getConfigFile(){
//        var configFileName = ""
//        var languageCode = "en"
//        if let code = sharedDefaults?.object(forKey: kUserdefaultsSharedSelectedLanguage) as? String{
//            languageCode = code
//        }
//        if languageCode == "en"{
//            configFileName = "config"
//        }else{
//            configFileName = "config-\(languageCode)"
//        }
//
//        FBHelper.getConfigFile(fileUrl:"https://focus-bear.github.io/assets/config/\(configFileName).json", completionHandler: {dic in
//            print("response mila")
//            if dic != nil{//todo != kro
//                configjson = dic!
//            }else{
//                if let path = Bundle.main.path(forResource: configFileName, ofType: "json") {
//                    let url = URL(fileURLWithPath: path)
//                    do {
//                        let data = try Data(contentsOf: url, options: .mappedIfSafe)
//                        do {
//                            if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
//                                configjson = dicResult
//                                print(configjson)
//                            }
//                        }catch {
//                            print(error)
//                        }
//
//                    } catch {
//                        // handle error
//                    }
//
//                }
//            }
//        }
//        )
//    }
    
    
    
    @objc func mainAppQuit(){
        print("mainAppQuit")
        addLog(text: "mainAppQuit")
        sharedDefaults?.removeObject(forKey: kUserdefaultsStartHabitNagCount)
        sharedDefaults?.removeObject(forKey: kUserdefaultsLastNagShowDate)
        sharedDefaults?.synchronize()
        setBackgroundThreadTimer()
        capturePosthog(event: "nudge-main-app-quit", metadata: [:])
    }
    func setBackgroundThreadTimer(){
        addLog(text: "setBackgroundThreadTimer")
        DispatchQueue.global().sync {//async {
            self.timerBackgroundThread = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.backgroundThread), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerBackgroundThread!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func backgroundThread(){
        DispatchQueue.main.async {
            addLog(text: "backgroundThread")
            if FileManager.default.fileExists(atPath: "/Applications/Focus Bear.app"){
                if let date = sharedDefaults?.object(forKey: kUserdefaultsAppQuitForUser) as? Date{
                    var totalNagShowCount = 0
                    if let count = sharedDefaults?.object(forKey: kUserdefaultsStartHabitNagCount) as? Int{
                        totalNagShowCount = count
                    }
                    let lastNagShowDate = sharedDefaults?.object(forKey: kUserdefaultsLastNagShowDate) as? Date ?? date
                    addLog(text: "lastNagShowDate is \(lastNagShowDate)")
                    let currentDate = Date()
                    addLog(text: "currentDate is \(currentDate)")
                    if currentDate > lastNagShowDate{
                        let diffHours = Calendar.current.dateComponents([.hour], from: lastNagShowDate, to: currentDate).hour ?? 0

                        addLog(text: "diffHours is \(diffHours)")
                        if diffHours > 23{
                            showNudgeWindow(day: totalNagShowCount + 1)
                        }
                    }
                    
                }else{
                    self.timerBackgroundThread?.invalidate()
                    self.timerBackgroundThread = nil
                    addLog(text: "appQuitForUser is nil")
                }
            }else{
                capturePosthog(event: "daily-nudge-app-uninstalled", metadata: [:])
                self.timerBackgroundThread?.invalidate()
                self.timerBackgroundThread = nil
                addLog(text: "focus bear uninstalled.")
            }
        }
    }
    
    @objc func setTimerMainAppForceQuitMonitoring(){
        addLog(text: "setTimerMainAppForceQuitMonitoring")
        
        stopTimerMainAppForceQuitMonitoring()
        
        DispatchQueue.global().sync {//async {
            self.timerMainAppForceQuitMonitoring = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.checkIsMainAppForceQuit), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerMainAppForceQuitMonitoring!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func stopTimerMainAppForceQuitMonitoring(){
        addLog(text: "stopTimerMainAppForceQuitMonitoring")
        if self.timerMainAppForceQuitMonitoring != nil{
            self.timerMainAppForceQuitMonitoring?.invalidate()
            self.timerMainAppForceQuitMonitoring = nil
        }
    }
    
    
    // MARK: #2575 scheduled restart (turn everything off until tomorrow)

    @objc func onScheduleMainAppRestart(){
        addLog(text: "onScheduleMainAppRestart")
        startScheduledRestartTimer()
    }

    func startScheduledRestartTimer(){
        addLog(text: "startScheduledRestartTimer")
        stopScheduledRestartTimer()
        DispatchQueue.global().sync {//async {
            self.timerScheduledRestart = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.checkScheduledRestart), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerScheduledRestart!), forMode: RunLoop.Mode.common)
        }
        // Check immediately too: if the target time has already passed (helper started after a reboot),
        // there's no reason to wait a full interval.
        checkScheduledRestart()
    }

    func stopScheduledRestartTimer(){
        addLog(text: "stopScheduledRestartTimer")
        if self.timerScheduledRestart != nil{
            self.timerScheduledRestart?.invalidate()
            self.timerScheduledRestart = nil
        }
    }

    @objc func checkScheduledRestart(){
        DispatchQueue.main.async {
            guard let date = sharedDefaults?.object(forKey: kUserdefaultsMainAppScheduledRestartDate) as? Date else {
                self.stopScheduledRestartTimer()
                return
            }
            if Date() >= date {
                addLog(text: "scheduled restart time reached (\(date)) - launching main app if needed")
                if !self.isMainAppRunning(){
                    self.launchMainApp()
                }
                sharedDefaults?.removeObject(forKey: kUserdefaultsMainAppScheduledRestartDate)
                sharedDefaults?.synchronize()
                self.stopScheduledRestartTimer()
            }
        }
    }

    /// Launch the main Focus Bear app that this helper is bundled inside — the helper's bundle sits three
    /// levels below the .app (…/Focus Bear.app/Contents/…/FBHelper.app), the same derivation the force-quit
    /// relaunch uses.
    func launchMainApp(){
        let path = Bundle.main.bundlePath as NSString
        var components = path.pathComponents
        components.removeLast()
        components.removeLast()
        components.removeLast()
        let newPath = NSString.path(withComponents: components)
        addLog(text: "launchMainApp \(newPath)")
        NSWorkspace.shared.launchApplication(newPath)
    }

    @objc func checkIsMainAppForceQuit(){
        DispatchQueue.main.async {
            if let state = sharedDefaults?.object(forKey: kUserdefaultsStartMainAppIfNotRunning) as? Bool{
                if state{
                    if !self.isMainAppRunning(){
                        let path = Bundle.main.bundlePath as NSString
                        var components = path.pathComponents
                        components.removeLast()
                        components.removeLast()
                        components.removeLast()
                        
                        let newPath = NSString.path(withComponents: components)
                        NSWorkspace.shared.launchApplication(newPath)
                    }
                }else{
                    self.stopTimerMainAppForceQuitMonitoring()
                }
            }else{
                self.stopTimerMainAppForceQuitMonitoring()
            }
        }
    }
    
    func isMainAppRunning() -> Bool {
        let mainAppBundleID = "com.App.EarnYourScreentime"
        
        return NSRunningApplication.runningApplications(withBundleIdentifier: mainAppBundleID).count > 0
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

