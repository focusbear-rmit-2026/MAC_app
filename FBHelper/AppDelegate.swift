//
//  AppDelegate.swift
//  FBHelper
//
//  Created by Prashant Sawnani on 25/06/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    
    let mainAppQuitByUser = Notification.Name("MainAppQuitByUser")
    var timerBackgroundThread:Timer?
    
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
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

