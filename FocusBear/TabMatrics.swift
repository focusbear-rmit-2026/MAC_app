//
//  TabMatrics.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 22/01/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation

var tabMatricsObject = TabMatrics()
class TabMatrics:NSObject {

    var arrAllAppsRecodDuringFocusMode = [[String : Any]]()
    var arrAllUrlsRecodDuringFocusMode = [[String : Any]]()
    var keyFocusAppTitle = "appName"
    var keyFocusDomainTitle = "domain"
    var keyFocusStartTime = "startTime"
    var keyFocusEndTime = "endTime"
    var keyFocusDuration = "duration"
    var keyIsBrowser = "isBrowser"
    var lastBrowserTabCalculateTime = Date()
    var arrAllTabsCount = [Int]()
    var currentAppTabCount = 0 // date 21/5/25  // version 1.23.367
    
    func frontAppChanged(name:String){
        if name.caseInsensitiveCompare(selfAppName) == .orderedSame{ // focus bear is front app close old app and url
            closeLastAppIfStarted()
            closeLastDomainIfStarted()// close last domain if open  here
            return;
        }
        
        if name.caseInsensitiveCompare(focusBearTimeTrackerAppName) == .orderedSame{ // fbtt is front app close old app and url
            closeLastAppIfStarted()
            closeLastDomainIfStarted()// close last domain if open  here
            return;
        }
        
        
        
        if let lastApp = arrAllAppsRecodDuringFocusMode.last{
            let lastAppName = lastApp[keyFocusAppTitle] as? String ?? ""
            if lastAppName != name{
                closeLastAppIfStarted()
                startNewAppRecord(name:name)

                // close last domain if open  here
                closeLastDomainIfStarted()
            }
        }else{
            startNewAppRecord(name:name)
        }
    }
    
    func frontDomainChanged(domain:String){
        if let lastDomain = arrAllUrlsRecodDuringFocusMode.last{
            let lastDomainName = lastDomain[keyFocusDomainTitle] as? String ?? ""
            if lastDomainName != domain{
                closeLastDomainIfStarted()// close last domain if open  here
                startNewDomainRecord(domain: domain)
            }else if lastDomain[keyFocusEndTime] != nil{// it means last url was same but closed
                startNewDomainRecord(domain: domain)
            }
        }else{
            startNewDomainRecord(domain: domain)
        }
    }
    
    func closeLastAppIfStarted(){
        if var lastApp = arrAllAppsRecodDuringFocusMode.last{
            let lastAppIndex = arrAllAppsRecodDuringFocusMode.count - 1
            let endTime = Date()
            lastApp[keyFocusEndTime] = endTime
            if let startTime = lastApp[keyFocusStartTime] as? Date{
                let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: endTime).second ?? 0
                
                lastApp[keyFocusDuration] = diffSeconds
                arrAllAppsRecodDuringFocusMode[lastAppIndex] = lastApp
            }
        }
    }
    
    func startNewAppRecord(name:String){
        print("startNewnameRecord:- \(name)")
        var app = [keyFocusAppTitle: name, keyFocusStartTime: Date()] as [String : Any]
        if getCurrentBrowserFrom(browserName: name.lowercased()) != nil{
            app[keyIsBrowser] = true
        }
        arrAllAppsRecodDuringFocusMode.append(app)
    }
    
    func closeLastDomainIfStarted(){//close last url if open  here
        if arrAllUrlsRecodDuringFocusMode.count != 0{
            let lastUrlIndex = arrAllUrlsRecodDuringFocusMode.count - 1
            var lastUrl = arrAllUrlsRecodDuringFocusMode[lastUrlIndex]
            if lastUrl[keyFocusEndTime] == nil{
                let endTime = Date()
                lastUrl[keyFocusEndTime] = endTime
                if let startTime = lastUrl[keyFocusStartTime] as? Date{
                    let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: endTime).second ?? 0
                    
                    lastUrl[keyFocusDuration] = diffSeconds
                    arrAllUrlsRecodDuringFocusMode[lastUrlIndex] = lastUrl
                }
            }
            
        }
    }
    
    func startNewDomainRecord(domain:String){
        print("startNewDomainRecord:- \(domain)")
        let domainItem = [keyFocusDomainTitle: domain, keyFocusStartTime: Date()] as [String : Any]
        arrAllUrlsRecodDuringFocusMode.append(domainItem)
    }
    
    func resetAll(){
        arrAllUrlsRecodDuringFocusMode.removeAll()
        arrAllAppsRecodDuringFocusMode.removeAll()
        arrAllTabsCount.removeAll()
    }
    
    
    func clubAllSameAppEntries(appData:[[String:Any]])-> [[String:Any]]{
        var groupedData: [String: [String: Any]] = [:]
        let currentDate = Date()
        for entry in appData {
            if let appName = entry[keyFocusAppTitle] as? String, let startTime = entry[keyFocusStartTime] as? Date{
                var duration = entry[keyFocusDuration] as? Int
                if duration == nil{
                    duration = Int(currentDate.timeIntervalSince(startTime))
                }
                
                if var existingEntry = groupedData[appName] {
                    // Sum the durations for the same app name
                    if let existingDuration = existingEntry[keyFocusDuration] as? Int {
                        existingEntry[keyFocusDuration] = existingDuration + (duration ?? 0)
                    }
                    
                    groupedData[appName] = existingEntry
                } else {
                    // Add a new entry to the grouped data
                    var entry = entry
                    entry[keyFocusDuration] = duration// if duration is nil
                    groupedData[appName] = entry
                }
            }
        }
        // Convert the grouped dictionary back to an array
        let groupedArray = Array(groupedData.values)        
        return groupedArray
    }
    
    func clubAllSameDomainEntries(appData:[[String:Any]])-> [[String:Any]]{
        var groupedData: [String: [String: Any]] = [:]
        let currentDate = Date()
        for entry in appData {
            if let appName = entry[keyFocusDomainTitle] as? String, let startTime = entry[keyFocusStartTime] as? Date{
                var duration = entry[keyFocusDuration] as? Int
                if duration == nil{
                    duration = Int(currentDate.timeIntervalSince(startTime))
                }
                
                if var existingEntry = groupedData[appName] {
                    // Sum the durations for the same app name
                    if let existingDuration = existingEntry[keyFocusDuration] as? Int {
                        existingEntry[keyFocusDuration] = existingDuration + (duration ?? 0)
                    }
                    
                    groupedData[appName] = existingEntry
                } else {
                    // Add a new entry to the grouped data
                    var entry = entry
                    entry[keyFocusDuration] = duration// if duration is nil
                    groupedData[appName] = entry
                }
            }
        }
        // Convert the grouped dictionary back to an array
        let groupedArray = Array(groupedData.values)
        return groupedArray
    }
    
    func calculateCurrentBrowserTabCount(currentBrowser:BROWSER){
        let diffSeconds = Calendar.current.dateComponents([.second], from: lastBrowserTabCalculateTime, to: Date()).second ?? 0
        
        if diffSeconds < 3 {
            return;
        }
                                                          
        lastBrowserTabCalculateTime = Date()
        if currentBrowser == ._FIREFOX_ || currentBrowser == ._SIGMA_OS_{
            arrAllTabsCount.append(1)
            return; 
        }
    
        if let browserStruct = getBrowserAllWindowStruct(browser: currentBrowser){
            var currentBrowserTabsArr = [String]()
            if currentBrowser == ._ARC_{
                if let allTabs = browserStruct["window"]{
                    currentBrowserTabsArr = allTabs
                }
            }else{
                let keys = browserStruct.keys
                for key in keys{
                    if let tabsArr = browserStruct[key]{
                        currentBrowserTabsArr += tabsArr
                    }
                }
            }
            
            arrAllTabsCount.append(currentBrowserTabsArr.count)
            currentAppTabCount = currentBrowserTabsArr.count
        }
    }

    var last30SecondsDurationRecordedStartTime:Date?
//    var last30SecondsDurationRecordedEntryTime:Date?
    func getLast30SecondsAverageTabDuration()->Int?{
        let currentDate = Date()
        guard let lastEntryInProductivityStatsTime = last30SecondsDurationRecordedStartTime else{
            return nil
        }
//        guard let last30SecondsDurationRecordedEntryTime = last30SecondsDurationRecordedEntryTime else{
//            return nil
//        }
        let thirtySecondsAgo = currentDate.addingTimeInterval(-30)
        
        let diffSeconds = currentDate.timeIntervalSince(lastEntryInProductivityStatsTime)
        if diffSeconds < 30 {
            return nil
        }
        
        var arrAllItemName = [String]()
        var totalDuration = 0
        let allItems = arrAllUrlsRecodDuringFocusMode + arrAllAppsRecodDuringFocusMode
        for item in allItems{
            
            let isBrowser = item[tabMatricsObject.keyIsBrowser] as? Bool ?? false
            if isBrowser{
                continue;
            }
            let appName = item[keyFocusAppTitle] as? String ?? item[keyFocusDomainTitle] as? String ?? ""
            if let startTime = item[keyFocusStartTime] as? Date, let endTime = item[keyFocusEndTime] as? Date, let duration = item[keyFocusDuration] as? Int{
                if startTime > thirtySecondsAgo && endTime > thirtySecondsAgo{
                    // add duration
                    totalDuration += duration
                    if !arrAllItemName.contains(appName){
                        arrAllItemName.append(appName)
                    }
                }else  if startTime < thirtySecondsAgo && endTime > thirtySecondsAgo{
                    // add duration
                    let calDuaration = endTime.timeIntervalSince(thirtySecondsAgo)
                    totalDuration += Int(calDuaration)
                    if !arrAllItemName.contains(appName){
                        arrAllItemName.append(appName)
                    }
                }
            }else if var startTime = item[keyFocusStartTime] as? Date{// current item
                if startTime < thirtySecondsAgo{
                    startTime = thirtySecondsAgo
                }
                // add duration
                let calDuaration = currentDate.timeIntervalSince(startTime)
                totalDuration += Int(calDuaration)
                if !arrAllItemName.contains(appName){
                    arrAllItemName.append(appName)
                }
            }
            
            
        }
        if arrAllItemName.count == 0 || totalDuration == 0{
            return 0
        }
//        self.last30SecondsDurationRecordedEntryTime = Date()
        let averageTabDuration = totalDuration / arrAllItemName.count
//        print("average tab duration in last 30 seconds :- \(averageTabDuration)")
        return averageTabDuration
    }
}

