//
//  focusModeData.swift
//  FocusBear
//
//  Created by Manish Jain on 23/04/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


var focusModeTaskString = ""
var taskCreatedByBlockPopup = ""

var arrCurrentFocusTasks = [[String:Any]]()
var arrFocusType = [[String:Any]]()
var nextFocusSessionIntention = ""
var arrAllFocusModeTags = [[String:String]]()
var whatToAchieveInFocusBlock = ""

var arrBlockedAppsInCuddlyModeCurrentFocus = [NSRunningApplication]()
var arrAllowedAppsInCuddlyModeCurrentFocus = [NSRunningApplication]()

var arrBlockedUrlsInCuddlyModeCurrentFocus = [String]()
var arrAllowedUrlsInCuddlyModeCurrentFocus = [String]()
var arrAllowedDomianInCuddlyModeCurrentFocus = [String]()
var arrAllowedTabTitlesInCuddlyModeCurrentFocus = [String]()

var dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus = [String:[String:Any]]()

var arrConvinceAiUrlsInCurrentFocus = [[String:String]]()
var arrConvinceAiAppsInCurrentFocus = [[String:String]]()


var arrKeywordsToAllowInFocus = [String]()
var currentRunningFocusType = [String:Any]()
var lastRunningFocusModeId = ""
//var dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus = [String:[String:Any]]()
let dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus = SafeDict()

var lastFocusModeTempInfo:lastFocusTempInfo?

var warningShowSecondsBeforeFocusModeEndTime = 60
struct lastFocusTempInfo {
    var id:String!
    var arrAllowedAppsInCuddlyModeCurrentFocus = [NSRunningApplication]()
    var arrAllowedUrlsInCuddlyModeCurrentFocus = [String]()
    
    init(id:String, arrAllowedAppsInCuddlyModeCurrentFocus:[NSRunningApplication], arrAllowedUrlsInCuddlyModeCurrentFocus:[String]) {
        self.id = id
        self.arrAllowedAppsInCuddlyModeCurrentFocus = arrAllowedAppsInCuddlyModeCurrentFocus
        self.arrAllowedUrlsInCuddlyModeCurrentFocus = arrAllowedUrlsInCuddlyModeCurrentFocus
    }
}

var arrFocusTypeForPomodoro = [[String:Any]]()

//var focusModeStartWindowLodded = false
var isFocusModeStartedAutomatically = false
var isMeetingsFocusStartedAutomatically = false

var isFocusModeStartedFromPomodoroMode = false
var isSkipBreakActivityDuringPomodoro = false

var isSkipBreakActivityDuringFocus = false

var isShowTimerInFocusEnabled = false
var customUrlHandleLastDurationForRelaxFocusMode = 0

var occupationSpecificRelevantSitesForFocusMode:[String:Any]?

func focusModeCloseCurrentUrlForAlignmentScore(){
    let keys = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.keys
    for key in keys{
        if var dictionary = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[key]{
            if dictionary["isVisibleUrl"] as? Bool == true{
                dictionary["isVisibleUrl"] = false
                let startTime = dictionary["startedTime"] as? Date ?? Date()
                let endTime = Date()
                let secondsBetween = endTime.timeIntervalSince(startTime)
                var seconds = dictionary["totalSeconds"] as? Int ?? 0
                seconds += Int(secondsBetween)
                dictionary["totalSeconds"] = seconds
                dictionary["endTime"] = endTime
                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[key] = dictionary
                break;
            }
        }
    }
}




func focusModeCloseCurrentAppForAlignmentScore(){
    let keys = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.keys
    for key in keys{
        if var dictionary = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[key]{
            if dictionary["isVisibleApp"] as? Bool == true{
                dictionary["isVisibleApp"] = false
                let startTime = dictionary["startedTime"] as? Date ?? Date()
                let endTime = Date()
                let secondsBetween = endTime.timeIntervalSince(startTime)
                var seconds = dictionary["totalSeconds"] as? Int ?? 0
                seconds += Int(secondsBetween)
                dictionary["totalSeconds"] = seconds
                dictionary["endTime"] = endTime
                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[key] = dictionary
                break;
            }
        }
    }
}

// v 2.28.449  13/1/26 // solution of Swift EXC_BAD_ACCESS crash Crash likely stems from dictionary subscripting within an asynchronous block in focusModeData.swif
func focusModeOpenCurrentUrlForAlignmentScoreForBackgroundThread(domain:String){
    // Track URLs when AI is enabled (cuddly mode)
    if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn(){
        //check url opening for second time
        if var info = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[domain]{
            if let isVisibleUrl = info["isVisibleUrl"] as? Bool{
                if !isVisibleUrl{
                    focusModeCloseCurrentUrlForAlignmentScore()
                    info["isVisibleUrl"] = true
                    info["startedTime"] = Date()
                    let reason = info["reason"] as? String ?? ""
                    DispatchQueue.main.async {
                        boxForStatusBarForTooltip?.customToolTip = reason
                    }
                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[domain] = info
                }
            }
            let probability = info["probability"] as? Double ?? 0
            DispatchQueue.main.async {
                setAppIconForFocusModeScore(probability: probability)
            }
        }else{
            // check and close all url if any of them is visible
            DispatchQueue.main.async {
                setFocusBearIconToNormal()
            }
            focusModeCloseCurrentUrlForAlignmentScore()
        }
    }
    // Track URLs when AI is disabled - use 0% for super distracting sites, 100% for others
    else if (!SettingsManagerObject.isAIBlockingEnabled() || isBlockSuperDistractingFocusModeOn()) {
        // Check if this URL is in the super distracting list
        let blockedUrls = getBlockedUrlsToBlock()
        var isSuperDistracting = false
        for blockedUrl in blockedUrls {
            if domain.lowercased().contains(blockedUrl.lowercased()) || blockedUrl.lowercased().contains(domain.lowercased()) {
                isSuperDistracting = true
                break
            }
        }
        let probability: Double = isSuperDistracting ? 0.0 : 1.0
        
        if var info = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[domain]{
            if let isVisibleUrl = info["isVisibleUrl"] as? Bool{
                if !isVisibleUrl{
                    focusModeCloseCurrentUrlForAlignmentScore()
                    info["isVisibleUrl"] = true
                    info["startedTime"] = Date()
                    info["probability"] = probability
                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[domain] = info
                }
            }
            DispatchQueue.main.async {
                setAppIconForFocusModeScore(probability: probability)
            }
        }else{
            // Add new entry for this URL
            focusModeCloseCurrentUrlForAlignmentScore()
            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[domain] = ["probability":probability, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason": ""]
            
            DispatchQueue.main.async {
                setAppIconForFocusModeScore(probability: probability)
                calculateFocusAlignmentScore()
            }
        }
    }
}



func focusModeOpenCurrentAppForAlignmentScore(appNameLowercased:String){
    boxForStatusBarForTooltip?.customToolTip = ""
    // Track apps when AI is enabled (cuddly mode)
    if arrBrowsersLowerCasedNames.contains(appNameLowercased){// exclude browsers from Alignment Score
        return;
    }
    if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn(){
        if var info = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]{
            if let isVisibleApp = info["isVisibleApp"] as? Bool{
                if !isVisibleApp{
                    focusModeCloseCurrentAppForAlignmentScore()
                    info["isVisibleApp"] = true
                    info["startedTime"] = Date()
                    boxForStatusBarForTooltip?.customToolTip = info["reason"] as? String ?? ""
                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = info
                }
            }
            let probability = info["probability"] as? Double ?? 0
            setAppIconForFocusModeScore(probability: probability)
        }else{
            setFocusBearIconToNormal()
            focusModeCloseCurrentAppForAlignmentScore()
        }
    }
    // Track apps when AI is disabled - use 0% for super distracting apps, 100% for others
    else if (!SettingsManagerObject.isAIBlockingEnabled() || isBlockSuperDistractingFocusModeOn()){
        // Check if this app is in the super distracting list
        let blockedApps = getBlockedAppsToBlock()
        var isSuperDistracting = false
        for blockedApp in blockedApps {
            if appNameLowercased.contains(blockedApp.lowercased()) || blockedApp.lowercased().contains(appNameLowercased) {
                isSuperDistracting = true
                break
            }
        }
        let probability: Double = isSuperDistracting ? 0.0 : 1.0
        
        if var info = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]{
            if let isVisibleApp = info["isVisibleApp"] as? Bool{
                if !isVisibleApp{
                    focusModeCloseCurrentAppForAlignmentScore()
                    info["isVisibleApp"] = true
                    info["startedTime"] = Date()
                    info["probability"] = probability
                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = info
                }
            }
            setAppIconForFocusModeScore(probability: probability)
        }else{
            // Add new entry for this app (exclude browsers from Alignment Score)
            if !arrBrowsersLowerCasedNames.contains(appNameLowercased){
                focusModeCloseCurrentAppForAlignmentScore()
                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = ["probability":probability, "isVisibleApp":true, "totalSeconds":0, "startedTime":Date(), "reason": ""]
                setAppIconForFocusModeScore(probability: probability)
                calculateFocusAlignmentScore()
            }
        }
    }
}


func focusModeSetCurrentAppAllowedForAlignmentScore(appNameLowercased:String, focusModeName: String, probability:Double, appName:String){
    if /*&&isCuddlyModeEnabled() SettingsManagerObject.isAIBlockingEnabled()  &&*/ !isBlockSuperDistractingFocusModeOn(){
        if !arrBrowsersLowerCasedNames.contains(appNameLowercased){// exclude browsers from Alignment Score
            var reason = appAllowedInFocusModeText.replacingOccurrences(of: "<APP>", with: appName)
            reason = reason.replacingOccurrences(of: "<FOCUSMODE>", with: focusModeName)
            if dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] == nil{
                addEntryInfocusAlignmentScoreCsv(url: appNameLowercased, tabTitle: "", focusMode: focusModeName, intention: whatToAchieveInFocusBlock, aiReason: "", allowedProbability: "\(probability)", totalScore: "")
                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = ["probability":probability, "isVisibleApp":true, "totalSeconds":0, "startedTime":Date(), "reason": reason]
                boxForStatusBarForTooltip?.customToolTip = reason
                setAppIconForFocusModeScore(probability: probability)
                calculateFocusAlignmentScore()
            }else{
                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]!["probability"] = 1.0
                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]!["reason"] = reason
                focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: appNameLowercased)
            }
            
        }
        
    }
}

var defaultFocusAlignmentScoreToShowDistractingPopUp:Int = 80
var minFocusAlignmentScoreToShowDistractingPopUp:Double = 80
var currentFocusAlignmentScore:Double = 100
var lastFocusAlignmentScore:Double = 0
var lastFocusAlignmentShownScore:Double = 0

func calculateFocusAlignmentScore(){
    var totalAlignmentScore:Double = 0
    var totalSeconds = 0
//    let snapshot = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus
    let snapshot = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.snapshot
    let keys = Array(snapshot.keys)
    //let keys = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.keys
    for key in keys{
        if let dictionary = snapshot[key]{
            var seconds = dictionary["totalSeconds"] as? Int ?? 0
            
            var shouldCalculateSecondsOFCurrentUrl = false
            
            if let isVisibleApp = dictionary["isVisibleApp"] as? Bool{
                if isVisibleApp{
                    shouldCalculateSecondsOFCurrentUrl = true
                }
            }
            
            if let isVisibleUrl = dictionary["isVisibleUrl"] as? Bool{
                if isVisibleUrl{
                    shouldCalculateSecondsOFCurrentUrl = true
                }
            }
            if shouldCalculateSecondsOFCurrentUrl{
                let startTime = dictionary["startedTime"] as? Date ?? Date()
                let endTime = Date()
                let secondsBetween = endTime.timeIntervalSince(startTime)
                seconds += Int(secondsBetween)
            }
            
            let probability = dictionary["probability"] as? Double ?? 0
            let score = ((Double(seconds) * probability))
            totalSeconds += seconds
            totalAlignmentScore += score
        }
    }
    if keys.count == 0{
        totalAlignmentScore = 100
    }
    if totalAlignmentScore != 0{
        totalAlignmentScore = (totalAlignmentScore / Double(totalSeconds)) * 100
    }
    if totalAlignmentScore > 100{
        totalAlignmentScore = 100
    }
    totalAlignmentScore = (totalAlignmentScore*100).rounded()/100
    if SettingsManagerObject.isFocusVisualIndicatorEnabled{
        if totalAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
            if lastFocusAlignmentShownScore - totalAlignmentScore > 5{//if decrease by >10 then show
                if let startFocusModeTime = startFocusModeTime{
                    let diffSeconds = Calendar.current.dateComponents([.second], from: startFocusModeTime, to: Date()).second ?? 0
                    if diffSeconds > 15{
                        showNudgeFocusAlignmentScoreWindow(score: totalAlignmentScore)
                    }
                }
            }
        }else{
            lastFocusAlignmentShownScore = totalAlignmentScore// refresh lastFocusAlignmentShownScore
        }
    }
    
    if currentFocusAlignmentScore != totalAlignmentScore{
        currentFocusAlignmentScore = totalAlignmentScore
        taskPlayerVcObj?.setFocusAlignmentScore()
    }
    lastFocusAlignmentScore = totalAlignmentScore
    
    if SettingsManagerObject.isFocusVisualIndicatorEnabled{
        if nudgeFocusAlignmentScoreDippingWcObject != nil{
            if nudgeFocusAlignmentScoreDippingWcObject?.window?.isVisible ?? false{
                if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
                    lastFocusAlignmentShownScore = totalAlignmentScore
                    getNudgeFocusAlignmentScoreDippingVcObject().reloadData(score: totalAlignmentScore, isNudgeVisible: true)
                }
            }
        }
    }
}




func getFocusAlignmentScoreFromLastEntry()->Double{
    let lastEntryInProductivityStatsTime = lastEntryInProductivityStatsTime ?? Date()
    var totalAlignmentScore:Double = 0
    var totalSeconds = 0
    //    var totalTabActive = 0
//    let keys = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.keys
    let snapshot = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.snapshot
    let keys = Array(snapshot.keys)
    for key in keys{
        if let dictionary = snapshot[key] {
            let startTime = dictionary["startedTime"] as? Date ?? Date()
            var seconds = dictionary["totalSeconds"] as? Int ?? 0
            let endTime = dictionary["endTime"] as? Date ?? Date()
            
            var shouldCalculateSecondsOFCurrentUrl = false
            
            if let isVisibleApp = dictionary["isVisibleApp"] as? Bool{
                if isVisibleApp{
                    shouldCalculateSecondsOFCurrentUrl = true
                }
            }
            
            if let isVisibleUrl = dictionary["isVisibleUrl"] as? Bool{
                if isVisibleUrl{
                    shouldCalculateSecondsOFCurrentUrl = true
                }
            }
            
            if startTime < lastEntryInProductivityStatsTime{
                if shouldCalculateSecondsOFCurrentUrl{
                    let endTime = Date()
                    let secondsBetween = endTime.timeIntervalSince(lastEntryInProductivityStatsTime)
                    seconds = Int(secondsBetween)
                }
            }
            
            if !shouldCalculateSecondsOFCurrentUrl{// if only active time is 1 second in last 3 seconds and not visible then get actual duration(1 second)
                let secondsBetween = endTime.timeIntervalSince(lastEntryInProductivityStatsTime)
                seconds = Int(secondsBetween)
                if seconds < 0{
                    continue;
                }
            }else{
                let currentDate = Date()
                var timeToCheck = lastEntryInProductivityStatsTime
                if startTime > lastEntryInProductivityStatsTime{
                    timeToCheck = startTime
                }
                let secondsBetween = Int(currentDate.timeIntervalSince(timeToCheck))
                if seconds > secondsBetween{
                    seconds = secondsBetween
                }
                if seconds < 0{
                    continue;
                }
            }
            if seconds < 0{
                continue;
            }
            let probability = dictionary["probability"] as? Double ?? 0
            let score = 100 * probability * Double(seconds)
            totalSeconds += seconds
            totalAlignmentScore += score
            
        }
    }
    
    if totalAlignmentScore != 0 && totalSeconds > 0{
        totalAlignmentScore = (totalAlignmentScore / Double(totalSeconds))
    }
    if totalAlignmentScore > 100{
        totalAlignmentScore = 100
    }
    totalAlignmentScore = (totalAlignmentScore*100).rounded()/100
    return totalAlignmentScore
}



func updateAllFocusModes(){
    var arrJson = [[String: Any]]()
    for focusType in arrFocusType{
        var json: [String: Any] = [
            "id":focusType["id"] as? String ?? "",
            "allowed_urls":focusType["allowed_urls"] as? [String] ?? [],
            "allowed_apps":focusType["allowed_apps"] as? [String] ?? [],
            "name":focusType["name"] as? String ?? "",
            "metadata": [:]
        ]
        var tagsDic = [[String:Any]]()
        if let tags = focusType["tags"] as? [String]{
            for tag in tags{
                tagsDic.append(["id": getIdForTag(tag: tag), "text": tag])
            }
        }
        json["tags"] = tagsDic
        
        var dic = focusType
        dic.removeValue(forKey: "name")
        dic.removeValue(forKey: "id")
        dic.removeValue(forKey: "allowed_urls")
        dic.removeValue(forKey: "allowed_apps")
        dic.removeValue(forKey: "tags")
        json["metadata"] = dic
        arrJson.append(json)
    }
    allApiObject.updateAllFocusMode(focusModes: arrJson, completionHandler: {json in
        
    })
}




func focusAlllowUrlClickedFromNewBlockPage(url:String, currentBrowser:BROWSER){
    allApiObject.capturePosthog(event: "yes-i-need-found", metadata: [:])
    var endString = "&focus_mode_end_time"
    if isAnyAllowedFocusModeActivityRunning{
        endString = "&block_type"
    }
    if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: endString) {
        print("Extracted substring: \(extractedUrl)")
        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
        let extractedPath = getPathFromUrl(url: extractedUrl)
        arrAllowedUrlsInCuddlyModeCurrentFocus.append(extractedPath)
        allApiObject.capturePosthog(event: "yes-i-need-worked", metadata: [:])
        setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
    }
}

func focusBlockUrlClickedFromNewBlockPage(url:String, currentBrowser:BROWSER)->String?{
    allApiObject.capturePosthog(event: "block-it-found", metadata: [:])
    var endString = "&focus_mode_end_time"
    if isAnyAllowedFocusModeActivityRunning{
        endString = "&block_type"
    }
    if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: endString) {
        print("Extracted substring: \(extractedUrl)")
        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
        let extractedPath = getPathFromUrl(url: extractedUrl)
        allApiObject.capturePosthog(event: "block-it-worked", metadata: [:])
        if !arrBlockedUrlsInCuddlyModeCurrentFocus.contains(extractedPath){
            arrBlockedUrlsInCuddlyModeCurrentFocus.append(extractedPath)
        }
        setUrlToBrowser(browser: currentBrowser, url: extractedUrl)// so that url will block in next turn
        return extractedUrl
    }
    return nil
}


func focusConvinceAiIntentionFromNewBlockPage(url:String, currentBrowser:BROWSER, currentRunningFocusModeName:String)->String?{
    allApiObject.capturePosthog(event: "convince-ai-intention-found", metadata: [:])
    var endString = "&focus_mode_end_time"
    if isAnyAllowedFocusModeActivityRunning{
        endString = "&block_type"
    }
    if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: endString) {
        print("Extracted substring: \(extractedUrl)")
        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
        let extractedPath = getPathFromUrl(url: extractedUrl)
        allApiObject.capturePosthog(event: "convince-ai-intention-worked", metadata: [:])
        setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
        let domain = getDomainFromUrl(url: extractedUrl).lowercased()
        var tabTitle = ""
        if let intention = extractValue(from: url, key: "convince-ai-intention") {
            print(intention)  // Output: I need to read something from wikipedia
            
            if let title = getActiveTabTitleOf(browser: currentBrowser)?.lowercased(){
                tabTitle = title
            }
            
            let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
            var currentHabitName:String?
            if isAnyAllowedFocusModeActivityRunning{
                if currentHabitPlaying != nil{
                    currentHabitName = currentHabitPlaying?.name
                }else if currentActivityPlaying != nil{
                    currentHabitName = currentActivityPlaying?.name
                }
            }
            
            checkUrlFromAiWithNewIntention(url: extractedPath, domain:domain, tab_title: tabTitle, intentionForThisSite: intention, currentRunningFocusModeName: currentRunningFocusModeName, shouldChangeCuddlyModeProgressCount: false, fullUrl:extractedUrl, currentHabitName: currentHabitName)
        }
        
        return extractedUrl
    }
    return nil
}

func focusSetUseIntentionFromNewBlockPage(url:String, currentBrowser:BROWSER)->String?{
    allApiObject.capturePosthog(event: "want-achieve-found", metadata: [:])
    var endString = "&focus_mode_end_time"
    if isAnyAllowedFocusModeActivityRunning{
        endString = "&block_type"
    }
    if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: endString) {
        print("Extracted substring: \(extractedUrl)")
        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
        //        _ = getPathFromUrl(url: extractedUrl)
        allApiObject.capturePosthog(event: "want-achieve-worked", metadata: [:])
        setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
        let domain = getDomainFromUrl(url: extractedUrl).lowercased() // no need now
        
        if let intention = extractValue(from: url, key: "want-achieve"), let time = extractValue(from: url, key: "want-achieve-time") {
            print(intention)  // Output: I need to read something from wikipedia
            let minutesToSet = Double(time) ?? 1
            let seconds = Int(minutesToSet * 60)
            let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
            var totalSeconds = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["totalDurationSpent"] as? Int ?? 0
            totalSeconds += seconds
            dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["totalDurationSpent"] = totalSeconds
            dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["userSetIntention"] = intention
            dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["endTime"] = endTime
        }
        return extractedUrl
    }
    return nil
}


var currentBrowserUrlForAi = ""
var currentRunningAppNameForAi = ""
var currentBrowserUrlAiTimeoutCount = 0
let maxBrowserUrlAiTimeoutCount = 3

var currentAppAiTimeoutCount = 0
var isGettingResponseFromAi = false

func tryCheckUrlFromAi(script: String, url:String, tabTitle:String?, browser:BROWSER?, fullUrl:String, domain:String, runningApp:NSRunningApplication){
    //        if ai is anabled then this fuction will called again and again
    var domain = domain
    if domain.isEmpty{
        domain = getDomainFromUrl(url: fullUrl)
    }
    if let dictionaryAllowedUrlsWithIntention = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]{
        let isAllowedByAi = dictionaryAllowedUrlsWithIntention["isAllowedByAi"] as? Bool ?? false
        if isAllowedByAi{
            return;
        }
        let isAllowedByConvinceAi = dictionaryAllowedUrlsWithIntention["isAllowedByConvinceAi"] as? Bool ?? false
        let reason = dictionaryAllowedUrlsWithIntention["reason"] as? String ?? ""
        let probability = dictionaryAllowedUrlsWithIntention["probability"] as? Double ?? 0
        let payload = dictionaryAllowedUrlsWithIntention["payload"] as? [String:Any] ?? [:]
        let suggestedTask = dictionaryAllowedUrlsWithIntention["suggested_task"] as? String
        let suggestedTaskId = dictionaryAllowedUrlsWithIntention["suggested_task_id"] as? String
        
        
        if let alllowUrlEndTime = dictionaryAllowedUrlsWithIntention["endTime"] as? Date{
            if Date().compare(alllowUrlEndTime) == .orderedDescending{//>
                // showBoxAgain
                if isRunningAppFullScreen(runningApp: runningApp, browser: browser) || stageManagerObject.isStageManagerEnabled{
                    if dictionaryAllowedUrlsWithIntention["userSetIntention"] as? String != nil{
                        let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&ai-focus-block-verification-enabled=true&ai-focus-block-enabled=true&&ai-reask-intention=true")
                        executeScript(script: script) // new
                    }else{
                        //convinces ai but still think distracting
                        let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&ai-focus-block-verification-enabled=true&ai-focus-block-enabled=true&ai-convince-response=\(reason)&ai-relevance-score=\(probability)")
                        executeScript(script: script) // new
                    }
                }else{
                    showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: probability, payload: payload, isBrowser:false, suggestedTask: suggestedTask,suggestedTaskId: suggestedTaskId)
                    
                    if dictionaryAllowedUrlsWithIntention["userSetIntention"] as? String != nil{
                        popUpBlockConfirmVcObj?.showUseDistractingUrlFlow(isSetIntentionFirstTime: false)
                    }else{
                        popUpBlockConfirmVcObj?.showConvincedAiPopUpBox(allowedByConvinceAiAlready: isAllowedByConvinceAi, reason: reason)
                    }
                }
            }
        }
        return;
    }
    
    
    // if user is clicked on cnvince ai once then code below will not be executed
    if currentBrowserUrlForAi == url{
        if SettingsManagerObject.isCuddlyModeEnabled{
            if !isGettingResponseFromAi, let info = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]{
                let reason = info["reason"] as? String ?? ""
                boxForStatusBarForTooltip?.customToolTip = reason
                let probability = info["probability"] as? Double ?? 0.0
                let payload = info["payload"] as? [String:Any] ?? [:]
                let suggestedTask = info["suggested_task"] as? String
                let suggestedTaskId = info["suggested_task_id"] as? String
                calculateFocusAlignmentScore()
                if probability < 0.70{
                    if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                        if reason.lowercased() != "unable to get a decision from ai. trusting you to decide whether the site is relevant 😅"{
                            if isRunningAppFullScreen(runningApp: runningApp, browser: browser) || stageManagerObject.isStageManagerEnabled{
                                let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&ai-focus-block-verification-enabled=true&ai-focus-block-enabled=true&ai-relevance-explanation=\(reason)&ai-relevance-score=\(probability)")
                                executeScript(script: script) // new
                            }else{
                                showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: probability, payload: payload, isBrowser:false, suggestedTask: suggestedTask, suggestedTaskId: suggestedTaskId)
                            }
                        }
                        
                    }
                }
            }
        }
        return;
    }
    currentBrowserUrlForAi = url
    currentBrowserUrlAiTimeoutCount = 0
    var currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
    var currentHabitName:String?
    if isAnyAllowedFocusModeActivityRunning{
        if currentHabitPlaying != nil{
            currentHabitName = currentHabitPlaying?.name
        }else if currentActivityPlaying != nil{
            currentHabitName = currentActivityPlaying?.name
        }
    }
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
    isGettingResponseFromAi = true
    
    checkUrlFromAi(script: script, url: url, tab_title: tab_title, currentRunningFocusModeName: currentRunningFocusModeName, browser:browser, fullUrl:fullUrl, domain: domain, runningApp: runningApp, currentHabitName: currentHabitName)
}

func getArrayOfLast5UrlJustifications()-> [String]{
    var arrayOfLast5Domain = [String]()
    
    let lastFiveElements = arrConvinceAiUrlsInCurrentFocus.suffix(5)
    for info in lastFiveElements{
        if let url = info["url"] {
            let intentionForSite = info["intentionForSite"] ?? ""
            let pageTitle = info["pageTitle"] ?? ""
            
            let json: [String: String] = [
                "url": url,
                "justification": intentionForSite,
                "pageTitle": pageTitle
            ]
            arrayOfLast5Domain.append("\(json)")
        }
    }
    return arrayOfLast5Domain
}

func getArrayOfLast5AppJustifications()-> [String]{
    var arrayOfLast5Domain = [String]()
    
    let lastFiveElements = arrConvinceAiAppsInCurrentFocus.suffix(5)
    for info in lastFiveElements{
        if let app = info["app"] {
            let intentionForApp = info["intentionForApp"] ?? ""
            
            let json: [String: String] = [
                "app": app,
                "justification": intentionForApp
            ]
            arrayOfLast5Domain.append("\(json)")
        }
    }
    return arrayOfLast5Domain
}

func checkUrlFromAi(script: String, url:String, tab_title:String, currentRunningFocusModeName:String, browser:BROWSER?, fullUrl:String, domain:String, runningApp:NSRunningApplication, currentHabitName:String?){
    //if isCuddlyModeEnabled(){
    appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("thinking_icon"))
    // }
    let currentTaskInToDoPlayer = getCurrentTaskInFocusMode()
    print("********** checkUrlFromAi ************")
    addLog(text: "currentTask in is URL Safe to use:\(currentTaskInToDoPlayer)")//2.27.427
    
    let arrayOfLast5Domain = getArrayOfLast5UrlJustifications()
    
    
    allApiObject.chatGPTIsURLSafe(url: url, tab_title: tab_title, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock,currentTaskInToDoPlayer: currentTaskInToDoPlayer, currentHabitName: currentHabitName, other_explanations_including_domains: arrayOfLast5Domain, completionHandler: {dic, checkedUrl, payload  in
        if dic != nil{
            if currentBrowserUrlForAi == checkedUrl{
                DispatchQueue.main.async{
                    // Race guard: if the user switched their To-Do task while this AI request was in
                    // flight, the relevance score was computed for a now-stale task — ignore it so we
                    // don't show a wrong "have you changed focus?" prompt (mirrors the URL guard above).
                    if getCurrentTaskInFocusMode() != currentTaskInToDoPlayer {
                        addLog(text: "checkUrlFromAi: To-Do task changed during request (\(currentTaskInToDoPlayer ?? "nil") -> \(getCurrentTaskInFocusMode() ?? "nil")); ignoring stale relevance result.")
                        setFocusBearIconToNormal()
                        return
                    }
                    let reason = dic?.value(forKey: "reason") as? String ?? ""
                    setFocusBearIconToNormal()
                    if var dProbability = dic?.value(forKey: "allowed_probability") as? Double{
                        addLog(text: "checked chatGPTIsURLSafe:- \(url), dProbability:\(dProbability)")
                        let currentTaskName = currentTaskInToDoPlayer ?? ""
                        let suggested_task = dic?.value(forKey: "suggested_task") as? String
                        let suggested_task_id = dic?.value(forKey: "suggested_task_id") as? String
                        
                        addEntryInFocusAIDecisionsCsv(url: url, domain: domain, tabTitle: tab_title, score: "\(dProbability)", intention: whatToAchieveInFocusBlock, aiReason: reason, currentTaskName: currentTaskName, additionalUserJustification: "")
                        
                        addAIBlockingLogEntry(
                            urlOrApp: url,
                            isApp: false,
                            focusMode: currentRunningFocusModeName,
                            intention: whatToAchieveInFocusBlock,
                            tabTitle: tab_title,
                            currentTask: currentTaskName,
                            score: dProbability,
                            reason: reason,
                            payload: payload
                        )
                        
                        if var oldData = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]{
                            addEntryInfocusAlignmentScoreCsv(url: url, tabTitle: tab_title, focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: reason, allowedProbability: "\(dProbability)", totalScore: "")
                            let isVisible = oldData["isVisibleUrl"] as? Bool ?? true
                            if isVisible{
                                boxForStatusBarForTooltip?.customToolTip = reason
                            }
                            oldData["probability"] = dProbability
                            oldData["reason"] = reason
                            if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                                oldData["suggested_task"] = suggested_task
                                oldData["suggested_task_id"] = suggested_task_id
                            }
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] = oldData
                        }else{
                            addEntryInfocusAlignmentScoreCsv(url: url, tabTitle: tab_title, focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: reason, allowedProbability: "\(dProbability)", totalScore: "")
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] = ["probability":dProbability, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason":reason]
                            
                            if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]?["suggested_task"] = suggested_task
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]?["suggested_task_id"] = suggested_task_id
                            }
                            
                            if let payload = payload{
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]?["payload"] = payload
                            }
                            boxForStatusBarForTooltip?.customToolTip = reason
                        }
                        calculateFocusAlignmentScore()
                        if SettingsManagerObject.isCuddlyModeEnabled{

                            var shouldShowPopup = true
                            
                            if(dProbability < 0.50){//Getting popup when AI doesn't make a decision#1355
                                if  reason.lowercased() == "unable to get a decision from ai. trusting you to decide whether the site is relevant 😅"{
                                    dProbability = 0.50
                                    shouldShowPopup = false
                                }
                            }
                            
                            if(dProbability >= 0.70){
                                // Safe URL
                                addLog(text: "url is safe according to chat gpt")
                                allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                
                                
                                arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                                arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                                
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if !popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                            }else if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                                //Unsafe url
                                addLog(text: "Unsafe url")
                                var popUpWindowVisible = false
                                
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if !popUpBlockConfirmVcObj!.isAppBlocking{
                                            if popUpBlockConfirmVcObj?.url == currentBrowserUrlForAi{
                                                popUpWindowVisible = true
                                                popUpBlockConfirmVcObj?.lblAi.stringValue = reason
                                                popUpBlockConfirmVcObj?.lastBlockReasonFromAi = reason
                                                return;
                                            }
                                        }
                                    }
                                }
                                if !popUpWindowVisible && shouldShowPopup{
                                    if isRunningAppFullScreen(runningApp: runningApp, browser: browser) || stageManagerObject.isStageManagerEnabled{
                                        let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&ai-focus-block-verification-enabled=true&ai-focus-block-enabled=true&ai-relevance-explanation=\(reason)&ai-relevance-score=\(dProbability)")
                                        executeScript(script: script) // new
                                    }else{
                                        showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tab_title, fullUrl:fullUrl, aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: dProbability, payload: payload, isBrowser:false,suggestedTask: suggested_task,suggestedTaskId: suggested_task_id)
                                    }
                                }
                            }
                        }else{
                            if(dProbability >= 0.70){
                                // Safe URL
                                addLog(text: "url is safe according to chat gpt")
                                allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                
                                arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                                arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                                
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if !popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                            }else{
                                addLog(text: "Unsafe url")
                                focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: reason, browser: browser, isUrlBlockByAi: true, blockReason:"")
                            }
                        }
                        
                    }
                    isGettingResponseFromAi = false
                    
                }
            }else{
                isGettingResponseFromAi = false
            }
        }else{
            DispatchQueue.main.async{
                if currentBrowserUrlForAi == checkedUrl{
                    if currentBrowserUrlAiTimeoutCount >= maxBrowserUrlAiTimeoutCount{
                        isGettingResponseFromAi = false
                        if SettingsManagerObject.isCuddlyModeEnabled{
                            let dProbability = 0.70
                            let reason = ""
                            
                            
                            if dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] == nil{
                                addEntryInfocusAlignmentScoreCsv(url: url, tabTitle: tab_title, focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: reason, allowedProbability: "\(dProbability)", totalScore: "")
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] = ["probability":dProbability, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason":reason]
                                if let payload = payload{
                                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]?["payload"] = payload
                                }
                                boxForStatusBarForTooltip?.customToolTip = reason
                            }
                            calculateFocusAlignmentScore()
                            
                            addLog(text: "The status of this url could not be verified. so we are marking it allowed")
                            allApiObject.capturePosthog(event: "ai-endpoint-timed-out-three-times", metadata: [:])
                            
                            arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                            arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                            
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if !popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                            
                        }else{
                            addLog(text: "The status of this url could not be verified. so we are marking it allowed")
                            allApiObject.capturePosthog(event: "ai-endpoint-timed-out-three-times", metadata: [:])
                            
                            arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                            arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                            
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if !popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                            
                        }
                    }else{//Retry AI blocking API if it fails #1303
                        currentBrowserUrlAiTimeoutCount += 1
                        addLog(text:"failed checkUrlFromAi again \(currentBrowserUrlAiTimeoutCount)")
                        checkUrlFromAi(script: script, url: url, tab_title: tab_title, currentRunningFocusModeName: currentRunningFocusModeName, browser:browser, fullUrl:fullUrl, domain: domain, runningApp: runningApp, currentHabitName: currentHabitName)
                    }
                    
                }else{
                    isGettingResponseFromAi = false
                }
            }
        }
    })
}

let durationAllowedByConviceAi = 90
func checkUrlFromAiWithNewIntention(url:String, domain:String, tab_title:String, intentionForThisSite:String, currentRunningFocusModeName:String, shouldChangeCuddlyModeProgressCount:Bool,fullUrl:String, currentHabitName:String?){// new work
    
    let endTime = Calendar.current.date(byAdding: .second, value: durationAllowedByConviceAi, to: Date()) ?? Date()
    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain] = ["totalDurationSpent":durationAllowedByConviceAi, "convinceAiIntention":intentionForThisSite, "isAllowedByConvinceAi": true, "endTime": endTime, "url": url]
    
    
    let arrayOfLast5Domain = getArrayOfLast5UrlJustifications()
    
    
    arrConvinceAiUrlsInCurrentFocus.append(["url":url, "intentionForSite":intentionForThisSite, "pageTitle":tab_title])
    let currentTaskInToDoPlayer = getCurrentTaskInFocusMode()
    addLog(text: "currentTask in is URL with New Intention Safe to use:\(currentTaskInToDoPlayer)")
    allApiObject.chatGPTIsURLSafeWithNewIntention(url: url, tab_title: tab_title, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, intentionForThisSite: intentionForThisSite, other_explanations_including_domains: arrayOfLast5Domain, currentTaskInToDoPlayer: currentTaskInToDoPlayer, currentHabitName: currentHabitName, completionHandler: {dic, checkedUrl, payload  in
        if dic != nil{
            DispatchQueue.main.async{
                setFocusBearIconToNormal()
                let reason = dic?.value(forKey: "reason") as? String ?? ""
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["endTime"] = Date()// because is block then popup should show again//Convince the AI should show immediate feedback #1419
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["intentionForSite"] = intentionForThisSite
                if let dProbability = dic?.value(forKey: "allowed_probability") as? Double{
                    
                    addLog(text: "checked checkUrlFromAiWithNewIntention:- \(url), dProbability:\(dProbability)")
                    addEntryInfocusAlignmentScoreCsv(url: url, tabTitle: tab_title, focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: reason, allowedProbability: "\(dProbability)", totalScore: "")
                    
                    let suggested_task = dic?.value(forKey: "suggested_task") as? String
                    let suggested_task_id = dic?.value(forKey: "suggested_task_id") as? String
                    
                    let currentTaskName = currentTaskInToDoPlayer ?? ""
                    addEntryInFocusAIDecisionsCsv(url: url, domain: domain, tabTitle: tab_title, score: "\(dProbability)", intention: whatToAchieveInFocusBlock, aiReason: reason, currentTaskName: currentTaskName, additionalUserJustification: intentionForThisSite)
                    
                    if var oldData = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]{
                        let isVisible = oldData["isVisibleUrl"] as? Bool ?? true
                        if isVisible{
                            boxForStatusBarForTooltip?.customToolTip = reason
                        }
                        oldData["probability"] = dProbability
                        oldData["reason"] = reason
                        if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                            oldData["suggested_task"] = suggested_task
                            oldData["suggested_task_id"] = suggested_task_id
                        }
                        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] = oldData
                    }else{
                        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] = ["probability":dProbability, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason":reason]
                        
                        if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]?["suggested_task"] = suggested_task
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]?["suggested_task_id"] = suggested_task_id
                        }
                    }
                    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["reason"] = reason
                    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["payload"] = payload
                    calculateFocusAlignmentScore()
                    if(dProbability >= 0.60){
                        // Safe URL
                        addLog(text: "url is safe according to chat gpt")
                        allApiObject.capturePosthog(event: "allow-automatically-convince-ai", metadata: [:])
                        
                        arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                        arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["probability"] = dProbability
                        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["isAllowedByAi"] = true
                        
                        if shouldChangeCuddlyModeProgressCount{
                            SettingsManagerObject.isSettingsChanged = true
                            SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
                            SettingsManagerObject.putUserLocalDeviceSettings()
                        }
                        
                        // update score
                    }else if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                        //Unsafe url
                        // do not touch cuddlyModeProgressCount here ... after 90 seconds if user use it by setting intention then we will set it
                        addLog(text: "Unsafe url")
                        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["probability"] = dProbability
                    }
                }
            }
        }else{
            if let oldData = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]{
                let probability = oldData["probability"] as? Double ?? 0.0
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["probability"] = probability
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain]?["payload"] = payload
            }
            // do not touch cuddlyModeProgressCount here ... after 90 seconds if user use it by setting intention then we will set it
        }
    })
    
}


func refreshFocusModeData(){
    arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
    arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
    arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
    arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
    arrAllowedDomianInCuddlyModeCurrentFocus.removeAll()
    isNudgeDraggedInCurrentFocusSession = false
    arrCurrentFocusTasks.removeAll()
}


func tryCheckAppFromAi(appName:String, runningApp:NSRunningApplication){
    //        if ai is anabled then this fuction will called again and again
    let appNameLowercased = appName.lowercased()
    
    if arrBrowsersLowerCasedNames.contains(appNameLowercased){// exclude browsers from Alignment Score
        if !isStrictnessLevelNormal(){
            arrAllowedAppsInCuddlyModeCurrentFocus.append(runningApp)
        }else
        if SettingsManagerObject.isDataCollectionModeEnabled{
            arrAllowedAppsInCuddlyModeCurrentFocus.append(runningApp)
        }else{
            showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true, browser: nil, tabTitle: nil, fullUrl:"", aiBlockReason: nil, isTimeOut:false, isBlockByAi: false, scoreForThisSiteApp: nil, payload: nil, isBrowser:true,suggestedTask: nil,suggestedTaskId: nil)
        }
        
        return;
    }
    if let dictionaryAllowedAppsWithIntention = dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]{
        let isAllowedByAi = dictionaryAllowedAppsWithIntention["isAllowedByAi"] as? Bool ?? false
        if isAllowedByAi{
            return;
        }
        let isAllowedByConvinceAi = dictionaryAllowedAppsWithIntention["isAllowedByConvinceAi"] as? Bool ?? false
        let reason = dictionaryAllowedAppsWithIntention["reason"] as? String ?? ""
        let probability = dictionaryAllowedAppsWithIntention["probability"] as? Double ?? 0
        let payload = dictionaryAllowedAppsWithIntention["payload"] as? [String:Any] ?? [:]
        let suggestedTask = dictionaryAllowedAppsWithIntention["suggested_task"] as? String
        let suggestedTaskId = dictionaryAllowedAppsWithIntention["suggested_task_id"] as? String
        
        if let alllowUrlEndTime = dictionaryAllowedAppsWithIntention["endTime"] as? Date{
            if Date().compare(alllowUrlEndTime) == .orderedDescending{//>
                // showBoxAgain
                
                showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true, browser: nil, tabTitle: nil, fullUrl:"", aiBlockReason: nil, isTimeOut:false, isBlockByAi: false, scoreForThisSiteApp: probability, payload: payload, isBrowser:false, suggestedTask: suggestedTask, suggestedTaskId: suggestedTaskId)
                
                if dictionaryAllowedAppsWithIntention["userSetIntention"] as? String != nil{
                    popUpBlockConfirmVcObj?.showUseDistractingUrlFlow(isSetIntentionFirstTime: false)
                }else{
                    popUpBlockConfirmVcObj?.showConvincedAiPopUpBox(allowedByConvinceAiAlready: isAllowedByConvinceAi, reason: reason)
                }
                
            }
        }
        return;
    }
    
    
    // if user is clicked on cnvince ai once then code below will not be executed
    if currentRunningAppNameForAi == appName{
        if SettingsManagerObject.isCuddlyModeEnabled{
            if !isGettingResponseFromAi, let info = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]{
                let reason = info["reason"] as? String ?? ""
                boxForStatusBarForTooltip?.customToolTip = reason
                let probability = info["probability"] as? Double ?? 0.0
                let payload = info["payload"] as? [String:Any] ?? [:]
                let suggestedTask = info["suggested_task"] as? String
                let suggestedTaskId = info["suggested_task_id"] as? String
                calculateFocusAlignmentScore()
                if probability < 0.70{
                    if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                        if reason.lowercased() != "unable to get a decision from ai. trusting you to decide whether the site is relevant 😅"{
                            showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true, browser: nil,tabTitle: nil, fullUrl:"", aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: probability, payload: payload, isBrowser:false, suggestedTask: suggestedTask, suggestedTaskId: suggestedTaskId)
                        }
                        
                    }
                }
            }
        }
        return;
    }
    currentRunningAppNameForAi = appName
    currentAppAiTimeoutCount = 0
    let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
    var currentHabitName:String?
    if isAnyAllowedFocusModeActivityRunning{
        if currentHabitPlaying != nil{
            currentHabitName = currentHabitPlaying?.name
        }else if currentActivityPlaying != nil{
            currentHabitName = currentActivityPlaying?.name
        }
    }
    
    isGettingResponseFromAi = true
    checkAppFromAi(appName: appName, currentRunningFocusModeName: currentRunningFocusModeName, runningApp: runningApp, currentHabitName: currentHabitName)
}




func checkAppFromAi(appName:String, currentRunningFocusModeName:String, runningApp:NSRunningApplication, currentHabitName:String?){
    print("checkAppFromAi****************")
    let appNameLowercased = appName.lowercased()
    //if isCuddlyModeEnabled(){
    appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("thinking_icon"))
    //}
    let arrayOfLast5Apps = getArrayOfLast5AppJustifications()
    
    let currentTaskInToDoPlayer = getCurrentTaskInFocusMode()
    addLog(text: "currentTask in is App Safe :\(currentTaskInToDoPlayer)")
    allApiObject.chatGPTIsAppSafe(appName: appName, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, other_explanations_including_apps: arrayOfLast5Apps,currentTaskInToDoPlayer: currentTaskInToDoPlayer, currentHabitName: currentHabitName, completionHandler: {dic, checkedApp, payload  in
        if dic != nil{
            if currentRunningAppNameForAi == checkedApp{
                DispatchQueue.main.async{
                    // Race guard: ignore the result if the user switched their To-Do task while the
                    // request was in flight (the score is for a stale task).
                    if getCurrentTaskInFocusMode() != currentTaskInToDoPlayer {
                        addLog(text: "checkAppFromAi: To-Do task changed during request; ignoring stale relevance result.")
                        setFocusBearIconToNormal()
                        return
                    }
                    let reason = dic?.value(forKey: "reason") as? String ?? ""
                    setFocusBearIconToNormal()
                    if var dProbability = dic?.value(forKey: "allowed_probability") as? Double{
                        print("dProbability is \(dProbability) ****")
                        addLog(text: "checked chatGPTIsAppSafe:- \(appName), dProbability:\(dProbability)")
                        let suggested_task = dic?.value(forKey: "suggested_task") as? String
                        let suggested_task_id = dic?.value(forKey: "suggested_task_id") as? String
                        
                        let currentTaskName = currentTaskInToDoPlayer ?? ""
                        addEntryInFocusAIDecisionsCsv(url: appName, domain: "", tabTitle: "", score: "\(dProbability)", intention: whatToAchieveInFocusBlock, aiReason: reason, currentTaskName: currentTaskName, additionalUserJustification: "")
                        
                        addAIBlockingLogEntry(
                            urlOrApp: appName,
                            isApp: true,
                            focusMode: currentRunningFocusModeName,
                            intention: whatToAchieveInFocusBlock,
                            tabTitle: "",
                            currentTask: currentTaskName,
                            score: dProbability,
                            reason: reason,
                            payload: payload
                        )
                        
                        if !arrBrowsersLowerCasedNames.contains(appNameLowercased){// exclude browsers from Alignment Score
                            if var oldData = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]{
                                addEntryInfocusAlignmentScoreCsv(url: appNameLowercased, tabTitle: "", focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: "", allowedProbability: "\(dProbability)", totalScore: "")
                                let isVisible = oldData["isVisibleApp"] as? Bool ?? true
                                if isVisible{
                                    boxForStatusBarForTooltip?.customToolTip = reason
                                }
                                oldData["probability"] = dProbability
                                oldData["reason"] = reason
                                if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                                    oldData["suggested_task"] = suggested_task
                                    oldData["suggested_task_id"] = suggested_task_id
                                }
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = oldData
                            }else{
                                addEntryInfocusAlignmentScoreCsv(url: appNameLowercased, tabTitle: "", focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: "", allowedProbability: "\(dProbability)", totalScore: "")
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = ["probability":dProbability, "isVisibleApp":true, "totalSeconds":0, "startedTime":Date(), "reason":reason]
                                if let payload = payload{
                                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]?["payload"] = payload
                                }
                                
                                if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]?["suggested_task"] = suggested_task
                                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]?["suggested_task_id"] = suggested_task_id
                                }
                                boxForStatusBarForTooltip?.customToolTip = reason
                            }
                            
                        }
                        calculateFocusAlignmentScore()
                        if SettingsManagerObject.isCuddlyModeEnabled{
                            
                            
                            var shouldShowPopup = true
                            
                            if(dProbability < 0.50){//Getting popup when AI doesn't make a decision#1355
                                if  reason.lowercased() == "unable to get a decision from ai. trusting you to decide whether the site is relevant 😅"{
                                    dProbability = 0.50
                                    shouldShowPopup = false
                                }
                            }
                            
                            if(dProbability >= 0.70){
                                // Safe URL
                                addLog(text: "app is safe according to chat gpt")
                                allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                
                                
                                arrAllowedAppsInCuddlyModeCurrentFocus.append(runningApp)
                                //arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                                
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                                if arrBrowsersLowerCasedNames.contains(appNameLowercased){
                                    if isFocusModeOn() || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                                        appdelegate?.setTimeCheckUrlsForFocusMode(nameLowercased: appNameLowercased)
                                    }else if isAnyAllowedFocusModeActivityRunning{
                                        DispatchQueue.global().sync {
                                            appdelegate?.setTimeCheckUrlsForHabits(nameLowercased: appNameLowercased)
                                        }
                                    }
                                }
                            }else if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                                //Unsafe url
                                
                                var popUpWindowVisible = false
                                
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            if popUpBlockConfirmVcObj?.currentAppName == currentRunningAppNameForAi{
                                                popUpWindowVisible = true
                                                popUpBlockConfirmVcObj?.lblAi.stringValue = reason
                                                popUpBlockConfirmVcObj?.lastBlockReasonFromAi = reason
                                                return;
                                            }
                                        }
                                    }
                                }
                                if !popUpWindowVisible && shouldShowPopup{
                                    showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url: "", script:"", isBlockApp:true, browser: nil,tabTitle: nil, fullUrl:"", aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: dProbability, payload: payload, isBrowser:false, suggestedTask: suggested_task, suggestedTaskId: suggested_task_id)
                                }
                            }else{
                                if arrBrowsersLowerCasedNames.contains(appNameLowercased){
                                    if isFocusModeOn() || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                                        appdelegate?.setTimeCheckUrlsForFocusMode(nameLowercased: appNameLowercased)
                                    }else if isAnyAllowedFocusModeActivityRunning{
                                        DispatchQueue.global().sync {
                                            appdelegate?.setTimeCheckUrlsForHabits(nameLowercased: appNameLowercased)
                                        }
                                    }
                                }
                            }
                        }else{
                            if(dProbability >= 0.70){
                                // Safe URL
                                addLog(text: "app is safe according to chat gpt")
                                allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                
                                arrAllowedAppsInCuddlyModeCurrentFocus.append(runningApp)
                                //                                arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                                
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                                
                                if arrBrowsersLowerCasedNames.contains(appNameLowercased){
                                    if isFocusModeOn() || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                                        appdelegate?.setTimeCheckUrlsForFocusMode(nameLowercased: appNameLowercased)
                                    }else if isAnyAllowedFocusModeActivityRunning{
                                        DispatchQueue.global().sync {
                                            appdelegate?.setTimeCheckUrlsForHabits(nameLowercased: appNameLowercased)
                                        }
                                    }
                                }
                            }else{
                                focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true, isAppBlockByAi: true)
                            }
                        }
                        
                    }
                    isGettingResponseFromAi = false
                    
                }
            }else{
                isGettingResponseFromAi = false
            }
        }else{
            DispatchQueue.main.async{
                if currentRunningAppNameForAi == checkedApp{
                    if currentAppAiTimeoutCount >= maxBrowserUrlAiTimeoutCount{
                        isGettingResponseFromAi = false
                        if SettingsManagerObject.isCuddlyModeEnabled{
                            let dProbability = 0.70
                            let reason = ""
                            
                            if !arrBrowsersLowerCasedNames.contains(appNameLowercased){// exclude browsers from Alignment Score
                                if dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] == nil{
                                    addEntryInfocusAlignmentScoreCsv(url: appNameLowercased, tabTitle: "", focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: "", allowedProbability: "\(dProbability)", totalScore: "")
                                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = ["probability":dProbability, "isVisibleApp":true, "totalSeconds":0, "startedTime":Date(), "reason":reason]
                                    if let payload = payload{
                                        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]?["payload"] = payload
                                    }
                                    boxForStatusBarForTooltip?.customToolTip = reason
                                }
                            }
                            
                            calculateFocusAlignmentScore()
                            
                            addLog(text: "The status of this app could not be verified. so we are marking it allowed")
                            allApiObject.capturePosthog(event: "ai-endpoint-timed-out-three-times", metadata: [:])
                            
                            arrAllowedAppsInCuddlyModeCurrentFocus.append(runningApp)
                            
                            
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    popUpBlockConfirmVcObj?.closeWindow()
                                }
                            }
                            
                        }else{
                            addLog(text: "The status of this url could not be verified. so we are marking it allowed")
                            allApiObject.capturePosthog(event: "ai-endpoint-timed-out-three-times", metadata: [:])
                            
                            arrAllowedAppsInCuddlyModeCurrentFocus.append(runningApp)
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    popUpBlockConfirmVcObj?.closeWindow()
                                }
                            }
                            
                        }
                    }else{//Retry AI blocking API if it fails #1303
                        currentAppAiTimeoutCount += 1
                        addLog(text:"failed checkUrlFromAi again \(currentAppAiTimeoutCount)")
                        checkAppFromAi(appName: appName, currentRunningFocusModeName: currentRunningFocusModeName, runningApp: runningApp, currentHabitName: currentHabitName)
                    }
                    
                }else{
                    isGettingResponseFromAi = false
                }
            }
        }
    })
}





func checkAppFromAiWithNewIntention(appName:String, intentionForThisApp:String, currentRunningFocusModeName:String, shouldChangeCuddlyModeProgressCount:Bool, runningApp:NSRunningApplication, currentHabitName:String?){// new work
    let endTime = Calendar.current.date(byAdding: .second, value: durationAllowedByConviceAi, to: Date()) ?? Date()
    let appNameLowercased = appName.lowercased()
    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased] = ["totalDurationSpent":durationAllowedByConviceAi, "convinceAiIntention":intentionForThisApp, "isAllowedByConvinceAi": true, "endTime": endTime, "appName": appName]
    
    let arrayOfLast5Apps = getArrayOfLast5AppJustifications()
    arrConvinceAiAppsInCurrentFocus.append(["app":appName, "intentionForApp":intentionForThisApp])
    let currentTaskInToDoPlayer = getCurrentTaskInFocusMode()
    addLog(text: "currentTask in is App Safe with New Intention to use:\(currentTaskInToDoPlayer)")
    allApiObject.chatGPTIsAppSafeWithNewIntention(appName: appName, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, intentionForThisApp: intentionForThisApp, other_explanations_including_apps: arrayOfLast5Apps, currentTaskInToDoPlayer: currentTaskInToDoPlayer, currentHabitName: currentHabitName, completionHandler: {dic, checkedUrl, payload  in
        if dic != nil{
            DispatchQueue.main.async{
                setFocusBearIconToNormal()
                let reason = dic?.value(forKey: "reason") as? String ?? ""
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["endTime"] = Date()// because is block then popup should show again//Convince the AI should show immediate feedback #1419
                if let dProbability = dic?.value(forKey: "allowed_probability") as? Double{
                    addLog(text: "checked checkAppFromAiWithNewIntention:- \(appName), dProbability:\(dProbability)")
                    addEntryInfocusAlignmentScoreCsv(url: appNameLowercased, tabTitle: "", focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: reason, allowedProbability: "\(dProbability)", totalScore: "")
                    
                    let suggested_task = dic?.value(forKey: "suggested_task") as? String
                    let suggested_task_id = dic?.value(forKey: "suggested_task_id") as? String
                    
                    let currentTaskName = currentTaskInToDoPlayer ?? ""
                    addEntryInFocusAIDecisionsCsv(url: appName, domain: "", tabTitle: "", score: "\(dProbability)", intention: whatToAchieveInFocusBlock, aiReason: reason, currentTaskName: currentTaskName, additionalUserJustification: intentionForThisApp)
                    if !arrBrowsersLowerCasedNames.contains(appNameLowercased){// exclude browsers from Alignment Score
                        if var oldData = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]{
                            let isVisible = oldData["isVisibleApp"] as? Bool ?? true
                            if isVisible{
                                boxForStatusBarForTooltip?.customToolTip = reason
                            }
                            oldData["probability"] = dProbability
                            oldData["reason"] = reason
                            if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                                oldData["suggested_task"] = suggested_task
                                oldData["suggested_task_id"] = suggested_task_id
                            }
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = oldData
                        }else{
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased] = ["probability":dProbability, "isVisibleApp":true, "totalSeconds":0, "startedTime":Date(), "reason":reason]
                            
                            if let suggested_task = suggested_task, let suggested_task_id = suggested_task_id{
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]?["suggested_task"] = suggested_task
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]?["suggested_task_id"] = suggested_task_id
                            }
                        }
                    }
                    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["reason"] = reason
                    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["payload"] = payload
                    calculateFocusAlignmentScore()
                    if(dProbability >= 0.60){
                        // Safe URL
                        addLog(text: "url is safe according to chat gpt")
                        allApiObject.capturePosthog(event: "app-allow-automatically-convince-ai", metadata: [:])
                        
                        arrAllowedAppsInCuddlyModeCurrentFocus.append(runningApp)
                        //                        arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["probability"] = dProbability
                        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["isAllowedByAi"] = true
                        
                        if shouldChangeCuddlyModeProgressCount{
                            SettingsManagerObject.isSettingsChanged = true
                            SettingsManagerObject.cuddlyModeProgressCount = SettingsManagerObject.cuddlyModeProgressCount + 1
                            SettingsManagerObject.putUserLocalDeviceSettings()
                        }
                        
                        // update score
                    }else if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                        //Unsafe url
                        // do not touch cuddlyModeProgressCount here ... after 90 seconds if user use it by setting intention then we will set it
                        addLog(text: "Unsafe url")
                        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["probability"] = dProbability
                    }
                }
            }
        }else{
            if let oldData = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[appNameLowercased]{
                let probability = oldData["probability"] as? Double ?? 0.0
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased]?["probability"] = probability
            }
            // do not touch cuddlyModeProgressCount here ... after 90 seconds if user use it by setting intention then we will set it
        }
    })
    
}

func finishOldFocusModeIfRunning(startNewFocusId:String?,intention:String, start_time:Date?, finish_time:Date?){
    addLog(text: "func finish Old FocusMode If Running")
    allApiObject.getLastActivityInfo(completionHandler: { json in
        
        if json != nil{
            print(json!)
            
            if let currentFocusMode = json?.value(forKey: "current_focus_mode") as? NSDictionary{//current_focus_mode_finish_time
                if let currentFocusModeId = currentFocusMode.value(forKey: "id") as? String{
                    print(currentFocusModeId)
                    //arrFocusType
                    addLog(text: "old focus mode is running- finish it")
                    var finishFocusMoedTime = Date()
                    if let currentFocusModeFinishTime = json?.value(forKey: "current_focus_mode_finish_time") as? String{
                        finishFocusMoedTime = getDateFromStringInUtc(date: currentFocusModeFinishTime, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") ?? finishFocusMoedTime
                    }
                    allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: finishFocusMoedTime, rating:nil, completionHandler: {newDic in
                        DispatchQueue.main.async {
                            if startNewFocusId != nil{
                                addLog(text: "start focus mode after finish old")
                                allApiObject.startFocusMode(id: startNewFocusId!, intention: intention, start_time: start_time!, finish_time: finish_time!, completionHandler: {newDic in
                                    
                                })
                            }
                            
                        }
                    })
                }
            }
        }
        
    })
}


func checkIsAnyOldFoucsModeRemaining(){
    addLog(text: "func check Is Any Old Foucs Mode Remaining")
    allApiObject.getLastActivityInfo(completionHandler: { json in
        
        if json != nil{
            print(json!)
            
            if let currentFocusMode = json?.value(forKey: "current_focus_mode") as? NSDictionary{//current_focus_mode_finish_time
                if let currentFocusModeId = currentFocusMode.value(forKey: "id") as? String{
                    print(currentFocusModeId)
                    //arrFocusType
                    let name = currentFocusMode.value(forKey: "name") as? String ?? ""
                    addLog(text: "old focus mode with id: \(currentFocusModeId) and name: \(name) is running")
                    var finishFocusMoedTime = Date()
                    if let currentFocusModeFinishTime = json?.value(forKey: "current_focus_mode_finish_time") as? String{
                        finishFocusMoedTime = getDateFromStringInUtc(date: currentFocusModeFinishTime, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") ?? finishFocusMoedTime
                        addLog(text: "current_focus_mode_finish_time is \(currentFocusModeFinishTime)")
                    }else{
                        addLog(text: "current_focus_mode_finish_time is nil")
                    }
                    
                    
                    var diffSeconds = Calendar.current.dateComponents([.second], from: Date(), to: finishFocusMoedTime).second ?? 0
                    appdelegate!.remainingFocusModeSecondsAfterPaused = diffSeconds
                    for i in 0..<arrFocusType.count{
                        let focusMode = arrFocusType[i]
                        if focusMode["id"] as? String == currentFocusModeId{
                            
                            addLog(text: "A focus mode with the same ID was found in the focus mode list. Now checking if there are any locally saved start or finish times for this focus mode.")
                            if let startDateString = focusMode["lastStartedDate"] as? String, let endDateString = focusMode["lastScheduledEndDate"] as? String{
                                let startDate = getDateFromString(date: startDateString, dateFormat: "yyyy-MM-dd HH:mm:ss") ?? Date()
                                startFocusModeTime = startDate
                                var endDate = getDateFromString(date: endDateString, dateFormat: "yyyy-MM-dd HH:mm:ss") ?? finishFocusMoedTime
                                
                                addLog(text: "Retrieved startDateString: \(startDateString) and endDateString: \(endDateString) from local")
                                
                                // Focus mode end time - actual duration to be stored and also the end time..if current time is more than 24 hrs + end time, cancel it, else resume it 3.32.490
                                
                                // Recovery logic for interrupted focus modes.
                                // If a matching focus mode is found in local storage with saved remaining time,
                                // allow it to resume even after its scheduled end time has passed.
                                // However, if more than 24 hours have elapsed since the scheduled end time,
                                // consider the session expired and do not restore it.
                                
                                var lastRunningFocusModeDurationFromLocal:Int = 0
                                var shouldExtendFocusModeIfRemaining = false
                                if let lastRunningFocusModeInfo = UserDefaults.standard.object(forKey: kUserdefaultsLastRunningFocusModeInfo) as? [String:Any]{
                                    if let lastRunningFocusModeId = lastRunningFocusModeInfo["id"] as? String, let remainingSeconds = lastRunningFocusModeInfo["remainingSeconds"] as? Int{
                                        if lastRunningFocusModeId == currentFocusModeId{
                                            addLog(text: "Local recovery data matches current focus mode id: \(currentFocusModeId)")
                                            lastRunningFocusModeDurationFromLocal = remainingSeconds
                                            addLog(text: "Recovered remaining duration from local storage: \(remainingSeconds) seconds")
                                            let twentyFourHoursLater = endDate.addingTimeInterval(24 * 60 * 60)

                                            if Date() > twentyFourHoursLater {
                                                addLog(text: "More than 24 hours have passed since focus mode ended")
                                                shouldExtendFocusModeIfRemaining = false
                                            }else{
                                                shouldExtendFocusModeIfRemaining = true
                                            }
                                        }
                                    }
                                }
                                
                                
                                if shouldExtendFocusModeIfRemaining{
                                    diffSeconds = lastRunningFocusModeDurationFromLocal
                                    addLog(text: "Recovered remaining duration from local storage: \(diffSeconds) seconds")
                                    endDate = Calendar.current.date(byAdding: .second, value: diffSeconds, to: Date()) ?? Date()
                                    appdelegate!.remainingFocusModeSecondsAfterPaused = diffSeconds
                                    DispatchQueue.main.async {
                                        addLog(text: "Focus mode resumed. Remaining duration: \(diffSeconds) seconds. Reason: Current time < end time + 24 hrs") // added in v 3.32.490
                                        resumeFocusModeAfterAppStartted(diffSeconds: diffSeconds, focusMode: focusMode, finishFocusMoedTime: endDate, index: i)
                                        focusModeActualDurationPerformed = Calendar.current.dateComponents([.second], from: startDate, to: Date()).second ?? diffSeconds//dont change this line place because  focusModeActualDurationPerformed = 0 in resumeFocusModeAfterAppStartted func
                                        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                                            let minute = diffSeconds / 60
                                            getTaskPlayerVcObject().loadView()
                                            getTaskPlayerVcObject().loadRequest()
                                            shouldReloadTaskPlayer = true
                                            showTaskPlayerWindow(totalDuration: minute, intention: whatToAchieveInFocusBlock, automatically:true)
                                        }else{
                                            let minute = diffSeconds / 60
                                            if !getTaskPlayerVcObject().isViewLoaded{
                                                getTaskPlayerVcObject().loadView()
                                            }
                                            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: whatToAchieveInFocusBlock)
                                            shouldReloadTaskPlayer = false
                                        }
                                    }
                                }
                                //-------------------------------------------//
                                else if Date().compare(endDate) == .orderedDescending {
                                    focusModeActualDurationPerformed = Calendar.current.dateComponents([.second], from: startDate, to: endDate).second ?? diffSeconds
                                    addLog(text: "focus mode finished with duration seconds: \(focusModeActualDurationPerformed) reason:- current time is greater then focus mode end time ")
                                    allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: endDate, rating:nil, completionHandler: {newDic in
                                        DispatchQueue.main.async {
                                            
                                            
                                        }
                                    })
                                    
                                }else{
                                    diffSeconds = Calendar.current.dateComponents([.second], from: Date(), to: endDate).second ?? diffSeconds
                                    appdelegate!.remainingFocusModeSecondsAfterPaused = diffSeconds
                                    DispatchQueue.main.async {
                                        addLog(text: "Focus mode resumed. Remaining duration: \(diffSeconds) seconds. Reason: Current time < end time") // added in v 3.32.483
                                        resumeFocusModeAfterAppStartted(diffSeconds: diffSeconds, focusMode: focusMode, finishFocusMoedTime: endDate, index: i)
                                        focusModeActualDurationPerformed = Calendar.current.dateComponents([.second], from: startDate, to: Date()).second ?? diffSeconds//dont change this line place because  focusModeActualDurationPerformed = 0 in resumeFocusModeAfterAppStartted func
                                        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                                            let minute = diffSeconds / 60
                                            getTaskPlayerVcObject().loadView()
                                            getTaskPlayerVcObject().loadRequest()
                                            shouldReloadTaskPlayer = true
                                            showTaskPlayerWindow(totalDuration: minute, intention: whatToAchieveInFocusBlock, automatically:true)
                                        }else{
                                            let minute = diffSeconds / 60
                                            if !getTaskPlayerVcObject().isViewLoaded{
                                                getTaskPlayerVcObject().loadView()
                                            }
                                            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: whatToAchieveInFocusBlock)
                                            shouldReloadTaskPlayer = false
                                        }
                                    }
                                    
                                }
                                
                            }else{
                                
                                addLog(text: "There is no locally saved start or finish times for this focus mode. now beleive on current_focus_mode_finish_time retrives from api")
                                if Date().compare(finishFocusMoedTime) == .orderedDescending{
                                    addLog(text: "focus mode finished reason:- current time is greater then focus mode end time ")
                                    allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: finishFocusMoedTime, rating:nil, completionHandler: {newDic in
                                        DispatchQueue.main.async {
                                            
                                            
                                        }
                                    })
                                }else{
                                    DispatchQueue.main.async {
                                        resumeFocusModeAfterAppStartted(diffSeconds: diffSeconds, focusMode: focusMode, finishFocusMoedTime: finishFocusMoedTime, index: i)
                                        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                                            getTaskPlayerVcObject().loadView()
                                            getTaskPlayerVcObject().loadRequest()
                                            shouldReloadTaskPlayer = true
                                            let minute = diffSeconds / 60
                                            showTaskPlayerWindow(totalDuration: minute, intention: whatToAchieveInFocusBlock, automatically:true)
                                        }else{
                                            let minute = diffSeconds / 60
                                            if !getTaskPlayerVcObject().isViewLoaded{
                                                getTaskPlayerVcObject().loadView()
                                            }
                                            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: whatToAchieveInFocusBlock)
                                            shouldReloadTaskPlayer = false
                                        }
                                    }
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }
        
    })
}


func resumeFocusModeAfterAppStartted(diffSeconds: Int, focusMode: [String : Any], finishFocusMoedTime: Date, index: Int){
    addLog(text: "resume Focus Mode After App Started")
    if let index = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeStrictness) as? Int{
        if index == 1{
            addLog(text: "focus mode is normal mode")
            currentFocusModeStrictness = ._NORMAL_
        }else if index == 2{
            addLog(text: "focus mode is strict mode")
            currentFocusModeStrictness = ._STRICT_
        }else if index == 3{
            addLog(text: "focus mode is super strict mode")
            currentFocusModeStrictness = ._SUPER_STRICT_
        }
    }else{
        if SettingsManagerObject.isCuddlyModeEnabled{
            currentFocusModeStrictness = ._NORMAL_
            addLog(text: "focus mode is normal mode")
        }else{
            currentFocusModeStrictness = ._SUPER_STRICT_
            addLog(text: "focus mode is super strict mode")
        }
    }
    
    focusModeMinutesToPerform = diffSeconds / 60
    isFocusModeStartedFromPomodoroMode = true
    
    if SettingsManagerObject.isGeekModeEnabled{
        isSkipBreakActivityDuringPomodoro = SettingsManagerObject.isSkipBreakActivityDuringPomodoro
    }else{
        isSkipBreakActivityDuringPomodoro = true
    }
    focusModeTaskString = focusMode["lastTaskUsed"] as? String ?? ""
    taskCreatedByBlockPopup = ""
    whatToAchieveInFocusBlock = focusMode["lastIntentionUsed"] as? String ?? ""
    focusModeStarttedResetAllData()
    appdelegate?.resumeFocusMode(index: index)
    endFocusModeTime = finishFocusMoedTime
    currentRunningFocusType = focusMode
    startFocusModeTimeForPauseAndResume = Date()
    isFocusModeRunning = true
    if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
        if  isRelaxFocus{
            showSavedSitesForLaterWindowForBreaks()
        }
    }
}



func updateFocusModeIntention(intention:String){
    if whatToAchieveInFocusBlock != intention{
        whatToAchieveInFocusBlock = intention
        arrConvinceAiUrlsInCurrentFocus.removeAll()//reset it if the intention changes
        arrConvinceAiAppsInCurrentFocus.removeAll()
    }
}

func updateFocusModeTask(taskString:String){
    focusModeTaskString = taskString
    taskCreatedByBlockPopup = ""
    getArrayOfTaskForApi()
    if let currentString = getCurrentTaskInFocusMode(){
        if currentPlayingTaskString != currentString{
            currentPlayingTaskString = currentString
        }
    }else{
        currentPlayingTaskString = ""
    }
}


var currentPlayingTaskString = ""

func getFocusModeTaskString()->String{
    if !focusModeTaskStringIsEmpty(){
        if let data = focusModeTaskString.data(using: String.Encoding.utf8) {
            do {
                let jsonResult:[[String: Any]] = try (JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? [])
                print(jsonResult)
                var taskString = ""
                for i in 0..<jsonResult.count{
                    let task = jsonResult[i]
                    let title = task["title"] as? String ?? ""
                    if i == 0{
                        taskString += title
                    }else{
                        taskString += "\n" + title
                    }
                }
                return taskString
            }catch{
                print(error)
            }
        }
    }
    return ""
}

func getArrayOfTaskForApi(){//at start of focus mode we get array of taks from api so we do not need to call it again and again when showing on popup block v2.48.451
    var arrTasks = [[String: Any]]()
    if !focusModeTaskStringIsEmpty(){
        if let data = focusModeTaskString.data(using: String.Encoding.utf8) {
            do {
                let jsonResult:[[String: Any]] = try (JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? [])
                //print(jsonResult)
//                var taskString = ""
                for i in 0..<jsonResult.count{
                    let task = jsonResult[i]
                    let title = task["title"] as? String ?? ""
                    let id = task["id"] as? String ?? ""
                    var isCompleted = false
                    if let status = task["status"] as? String{
                        if status == "COMPLETED"{
                            isCompleted = true
                        }
                    }
                    if !isCompleted{
                        arrTasks.append(["task_name":title, "task_id":id])
                    }
                }
            }catch{
                print(error)
            }
        }
    }
    arrCurrentFocusTasks = arrTasks
}

func getStatusTextForTask(status:String)-> String{
    var completedText = "Completed"
    var inProgressText = "In Progress"
    var notStartedText = "Not Started"
    
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        completedText = common.value(forKey: "completedText") as? String ?? completedText
        inProgressText = common.value(forKey: "inProgressText") as? String ?? inProgressText
        notStartedText = common.value(forKey: "notStartedText") as? String ?? notStartedText
    }
    
    if(status == "COMPLETED"){
        return completedText;
    }else if(status == "IN_PROGRESS"){
        return inProgressText;
    }else if (status == "NOT_STARTED"){
        return notStartedText;
    }
    return "";
}



func getCurrentTaskInFocusMode()-> String?{
    if !taskCreatedByBlockPopup.isEmpty{
        return taskCreatedByBlockPopup
    }
    if !focusModeTaskStringIsEmpty(){
        if let data = focusModeTaskString.data(using: String.Encoding.utf8) {
            do {
                let jsonResult:[[String: Any]] = try (JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? [])
                //print(jsonResult)
                for i in 0..<jsonResult.count{
                    let task = jsonResult[i]//isPlaying
                    if let isPlaying = task["isPlaying"] as? Bool, let title = task["title"] as? String{
                        if isPlaying{
                            return title
                        }
                    }
                }
                
            }catch{
                print(error)
            }
        }
        
    }
    return nil
}

var timerForFocusMode:Timer?
var timerForFocusModeEndNotification:Timer?


var endFocusModeTime:Date?// this is focusMode end time wich we calculate at the begning of focus mode
var startFocusModeTime:Date?
var startFocusModeTimeForPauseAndResume:Date?
var focusModeActualDurationPerformed:Int = 0// this will be useful to save in csv and showing focus summary
var focusModeMinutesToPerform = 0
var focusModeSecondsToPerform = 0 //useful in pause resume focus mode
var unfocusedTime = 0

var isFocusModeRunning = false

func isFocusModeOn()->Bool{
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            return true
        }
    }
    return false
}
func isFocusModePaused()->Bool{
    for dic in arrFocusType{
        if dic["isPaused"] as? Bool == true{
            return true
        }
    }
    return false
}
func isFocusModeOnOrPaused()->Bool{
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            return true
        }else if dic["isPaused"] as? Bool == true{
            return true
        }
    }
    return false
}

func getRunningFocusModeId()->String{
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            return dic["id"] as? String ?? ""
        }
    }
    return ""
}

func focusModeTaskStringIsEmpty()->Bool{
    if focusModeTaskString.isEmpty || focusModeTaskString == "[]"{
        return true
    }else{
        return false
    }
}
func sortFocusModes(){// this is also removing multiple isDefault focus modes
    var isDefaultContain = false
    var islockedFocusContain = false
    var defaultFocus: [String : Any]?
    var lockedFocus: [String : Any]?
    
    var index = 0
    var count = arrFocusType.count
    while index < count{
        if let isDefault = arrFocusType[index]["isDefault"] as? Bool{
            if  isDefault{
                isDefaultContain = isDefault
                defaultFocus = arrFocusType[index]
                arrFocusType.remove(at: index)
                count -= 1
                continue;
            }
        }
        if let isLockedFocus = arrFocusType[index]["isLockedFocus"] as? Bool{
            if  isLockedFocus{
                islockedFocusContain = isLockedFocus
                lockedFocus = arrFocusType[index]
                arrFocusType.remove(at: index)
                count -= 1
                continue;
            }
        }
        index += 1
    }
    
    arrFocusType = arrFocusType.sorted{
        return $0["name"] as? String ?? "" < $1["name"] as? String ?? ""
    }
    
    if isDefaultContain{
        arrFocusType.insert(defaultFocus!, at: 0)
    }
    if islockedFocusContain{
        arrFocusType.append(lockedFocus!)
    }
}

var isAnyAllowedFocusModeActivityRunning = false// whenever allowed focus activity started set true this variable
var isAnyAllowedFocusModeActivityWasRunningInLastActivity = false
var isAnyAllowedFocusModeActivityFinishTime = Date()

func reSetCurrentFocusMode(focusType:[String:Any]){
    if isFocusModeOn() || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
        if focusType["id"] as? String ?? ""  == currentRunningFocusType["id"] as? String ?? ""{
            currentRunningFocusType = focusType
        }
    }
}

enum FOCUSMODESTRICTNESS:Int,Codable{
    case _NORMAL_ = 45, _STRICT_, _SUPER_STRICT_
}

var currentFocusModeStrictness = FOCUSMODESTRICTNESS._NORMAL_

// 2.28.450   In Super strict mode, now the AI popups will be shown for the urls and user can try to convince AI but cannot change the intention 19/1/25
func isStrictnessLevelNormal()->Bool{
    if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
        return customBlockingScheduleManagerObj.isStrictnessLevelNormal()
    }
    
    if currentFocusModeStrictness == ._SUPER_STRICT_{
        return false
    }
    return true
}


var isNudgeDraggedInCurrentFocusSession = false


func getBlockScriptForFocusMode(url:String, currentBrowser:BROWSER, intention:String, cuddly_bear_modeString:String, aiReasonToBlockString:String, focusMode:String, focusModeExpiryTimeString:String)->String{
    var script: String = ""
    switch currentBrowser{
        
    case ._SAFARI_:
        script = getSafariBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        
    case ._GOOGLE_CHROME_:
        script = getGoogleChromeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        
    case ._OPERA_:
        script = getOperaBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        
    case ._OPERA_GX_:
        script = getOperaGxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        
    case ._VIVALDI_:
        script = getVivaldiBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        
    case ._BRAVE_BROWSER_:
        script = getBraveBrowserBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        
    case ._SIDEKICK_:
        script = getSidekickBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        
    case ._MICROSOFT_EDGE_:
        script = getMicrosoftEdgeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
    case ._ARC_:
        script = getArcBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
    case ._FIREFOX_:
        script = getFirefoxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
    case ._SIGMA_OS_:
        script = getSigmaOsBrowserBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
    case ._COMET_:
        script = getCometBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
    }
    return script
}


var focusModeHelper = focusTimerManager()
var suggestWorkFocusManagerObject = suggestWorkFocusManager()
var habitBlockTimerHelper = habitBlockTimerManager()



func focusBlockUnwantedUrl(script: String, url:String, lastBlockReasonFromAi:String?, browser: BROWSER?, isUrlBlockByAi:Bool, blockReason:String){
    addLog(text:"focusBlockUnwantedUrl:- \(url)")
    var newScript = script
    newScript = newScript.replacingOccurrences(of: "<NEWPAGE>", with: "")
    currentBrowserUrlForAi = ""
    if lastBlockReasonFromAi != nil{
        newScript = newScript.replacingOccurrences(of: "<AIREASON>", with: "&reason=\(lastBlockReasonFromAi!)")
    }else{
        newScript = newScript.replacingOccurrences(of: "<AIREASON>", with: "")
    }
    if browser == ._ARC_{
        NSWorkspace.shared.launchApplication("Arc")
    }
    if browser == ._FIREFOX_{
        firefoxServer.sendBlockNow(url: url,params: newScript)
    }else{
        executeScript(script: newScript)
    }
    
    var blockMode = ""
    if currentFocusModeStrictness == ._SUPER_STRICT_{
        blockMode = "super_strict"
    }else if currentFocusModeStrictness == ._STRICT_{
        blockMode = "strict"
    }else if currentFocusModeStrictness == ._NORMAL_{
        blockMode = "normal"
    }
    
    if isUrlBlockByAi{
        allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":"ai_blocking", "block-mode": blockMode])
    }else{
        allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":blockReason, "block-mode": blockMode])
    }
    if !arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
        arrBlockedUrlsInCuddlyModeCurrentFocus.append(url)
    }
}


func focusTryToBlockUnwantedUrl(script: String, url:String, browser: BROWSER?, tabTitle:String?, fullUrl:String, runningApp:NSRunningApplication, domain:String){
    if popUpBlockConfirmWcObj != nil{
        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
            if !popUpBlockConfirmVcObj!.isAppBlocking{
                if popUpBlockConfirmVcObj?.url == url{
                    exitFullScreen(runningApp:runningApp)
                    return;
                }else{
                    popUpBlockConfirmVcObj?.closeWindow()
                }
            }
        }
    }
    addLog(text: "focusTryToBlockUnwantedUrl:- \(url)")
    if SettingsManagerObject.isCuddlyModeEnabled{
        if arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
            focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: false, blockReason: "blocked_once_in_this_session")
        }else{
            if SettingsManagerObject.isAIBlockingEnabled(){
                tryCheckUrlFromAi(script: script, url: url, tabTitle: tabTitle, browser: browser, fullUrl: fullUrl, domain:domain, runningApp: runningApp)
            }else{
                if isRunningAppFullScreen(runningApp: runningApp, browser: browser) || stageManagerObject.isStageManagerEnabled{
                    let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&ai-focus-block-verification-enabled=true")
                    executeScript(script: script)
                }else{
                    exitFullScreen(runningApp:runningApp)
                    showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiBlockReason: nil, isTimeOut:false, isBlockByAi: false, scoreForThisSiteApp: nil, payload: nil, isBrowser:false, suggestedTask: nil, suggestedTaskId: nil)
                }
            }
        }
    }else{
        if arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
            focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: false, blockReason: "blocked_once_in_this_session")
        }else{
            if SettingsManagerObject.isAIBlockingEnabled(){
                tryCheckUrlFromAi(script: script, url: url, tabTitle: tabTitle, browser: browser, fullUrl: fullUrl, domain:domain, runningApp: runningApp)
            }else{
                exitFullScreen(runningApp:runningApp)
                focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: false, blockReason: "block_in_focus_mode")
                
            }
        }
    }
    
}

func focusBlockUnwantedApp(runningApp: NSRunningApplication, appName:String, showNotification:Bool, isAppBlockByAi:Bool){
    addLog(text: "focusBlockUnwantedApp:- \(appName)")
    exitFullScreen(runningApp:runningApp)
    runningApp.hide()
    allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
    if showNotification{
        showFocusAppBlockNotification(appName:appName)
    }
    if !arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
        arrBlockedAppsInCuddlyModeCurrentFocus.append(runningApp)
    }
}

func focusTryToBlockUnwantedApp(runningApp: NSRunningApplication, appName:String, appNameLowercased:String){
    
    for path in SettingsManagerObject.arrAlwaysAllowedApps{
        let url = URL(fileURLWithPath: path)
        if url.deletingPathExtension().lastPathComponent.lowercased() == appNameLowercased{
            return;
        }
    }
    
    if popUpBlockConfirmWcObj != nil{
        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
            if popUpBlockConfirmVcObj!.isAppBlocking{
                if popUpBlockConfirmVcObj?.currentApp == runningApp{
                    return;
                }else{
                    popUpBlockConfirmVcObj?.closeWindow()
                }
            }
        }
    }
    exitFullScreen(runningApp:runningApp)
    addLog(text: "focusTryToBlockUnwantedApp:- \(appName)")
    if SettingsManagerObject.isCuddlyModeEnabled{
        if arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
            focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true, isAppBlockByAi: false)
        }else{
            if SettingsManagerObject.isAIBlockingEnabled(){
                tryCheckAppFromAi(appName: appName, runningApp: runningApp)
            }else{
                showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true, browser: nil, tabTitle: nil, fullUrl:"", aiBlockReason: nil, isTimeOut:false, isBlockByAi: false, scoreForThisSiteApp: nil, payload: nil, isBrowser:false, suggestedTask: nil, suggestedTaskId: nil)
            }
        }
    }else{
        if arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
            focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true, isAppBlockByAi: false)
        }else{
            if SettingsManagerObject.isAIBlockingEnabled(){
                tryCheckAppFromAi(appName: appName, runningApp: runningApp)
            }else{
                focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true, isAppBlockByAi: false)
                
            }
        }
    }
}



/**
 THREAD-SAFE DICTIONARY FOR FOCUS MODE ALIGNMENT SCORE
 
 Problem: Multiple threads (timer, UI, AI) accessing same dictionary → random crashes
 Solution: NSLock serializes access (one thread at a time)
 Performance: <0.1ms overhead for <100 entries
 Usage: .snapshot for bulk reads, subscript for single operations
*/

// safe dict v 2.28.452
final class SafeDict {
    private var storage = [String: [String: Any]]()
    private let lock = NSLock()
    
    var snapshot: [String: [String: Any]] {
        lock.lock()
        let copy = storage
        lock.unlock()
        return copy
    }
    
    subscript(key: String) -> [String: Any]? {
        get {
            lock.lock()
            let value = storage[key]
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            storage[key] = newValue
            lock.unlock()
        }
    }
    
    var keys: [String] {
        lock.lock()
        let keys = Array(storage.keys)
        lock.unlock()
        return keys
    }
    
    func removeAll() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }
    
    func removeValue(forKey key: String) {
        lock.lock()
        storage.removeValue(forKey: key)
        lock.unlock()
    }
}




func startWorkFocusAutomaticallyClicked(id:String, minutes:Int, intention:String){
    addLog(text: "Alert Start Wrok Focus Clicked")
    
    if !getTaskPlayerVcObject().isViewLoaded{
        getTaskPlayerVcObject().loadView()
    }
    getTaskPlayerVcObject().loadRequest()
    
    for i in 0..<arrFocusType.count{
        let focus = arrFocusType[i]
        if let focusId = focus["id"] as? String{
            if focusId == id{
                let calendar = Calendar.current
                endFocusModeTime = calendar.date(byAdding: .minute, value: minutes, to: Date())
                startFocusModeTime = Date()
                currentFocusModeStrictness = ._NORMAL_
                addLog(text: "focus mode is normal mode")
                arrFocusType[i]["isOn"] = true
                shouldReloadTaskPlayer = true
                if let isAutoDoNotDisturbEnabled = arrFocusType[i]["isAutoDoNotDisturbEnabled"] as? Bool{
                    if isAutoDoNotDisturbEnabled{
                        if isAccessibilityEnabled(isPrompt: true){
                            DNDManager.shared.setDND(true)
                        }
                    }
                }
                workBeforeFocusBegin(index: i)
                focusModeMinutesToPerform = 0
                
                appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString: arrFocusType[i]["color"] as? String ?? "")
                appdelegate!.statusbutton?.title = buttonStatusStateFocusText
                appdelegate!.statusbutton?.imagePosition = .imageLeft
                if timerForFocusMode != nil{
                    timerForFocusMode?.invalidate()
                    timerForFocusMode = nil
                    setAppIconForFocusModeScore(probability: nil)
                    timerForFocusModeEndNotification?.invalidate()
                    timerForFocusModeEndNotification = nil
                }
                appdelegate?.setFocusModeTimer(hour: nil, minute: minutes)

                //focusButtonService
                focusButtonServiceObject.startFocusSession(seconds: minutes*60)
                
                
                isFocusModeStartedFromPomodoroMode = false
                whatToAchieveInFocusBlock = intention
                
                DispatchQueue.global().async {
                    sleep(1)
                    DispatchQueue.main.async {
                        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                            showTaskPlayerWindow(totalDuration: minutes, intention: whatToAchieveInFocusBlock, automatically:true)
                        }else{
                            if !getTaskPlayerVcObject().isViewLoaded{
                                getTaskPlayerVcObject().loadView()
                            }
                            taskPlayerVcObj?.reloadData(totalDuration: minutes, intention: whatToAchieveInFocusBlock)
                            shouldReloadTaskPlayer = false
                            mainWindowControllerObj?.window?.close()
                        }
                    }
                }
                
                
                appdelegate!.focusModeStartted(isStartedByPusher: false)
                allApiObject.capturePosthog(event: "start-work-focus-mode", metadata: [:])
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                isFocusModeStartedAutomatically = false
                break;
            }
        }
    }
}

var lastEntryInProductivityStatsTime:Date?
func addEntryInProductivityStatsCsv(){
    
    if !SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
        return;
    }
    
    
    let currentDate = Date()
    if let lastEntryInProductivityStatsTime = lastEntryInProductivityStatsTime {
        let diffSeconds = currentDate.timeIntervalSince(lastEntryInProductivityStatsTime)
        if diffSeconds < 2.6 {//Log focusProductivityStats.csv every 3 seconds instead of every 10 seconds #1378
            return// this will always show gap of 3 seconds between each entry
        }
        //        print(diffSeconds)
    }
    let averageScoreFromLastEntry = getFocusAlignmentScoreFromLastEntry()
    
    lastEntryInProductivityStatsTime = currentDate

    let date = currentDate
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime] // Standard ISO 8601 format
    
    let isoString = isoFormatter.string(from: date)
    
    var lastEvent:CFTimeInterval = 0
    lastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
    let idleTimeValue = Int(lastEvent)
    var averageTabCount = 0
    var averageTabDuration = 0

    let arrAllTabsCount = tabMatricsObject.arrAllTabsCount
    let sumOfCount =  arrAllTabsCount.reduce(0, +)
    if arrAllTabsCount.count > 0{
        averageTabCount = sumOfCount / arrAllTabsCount.count
    }
    
    var arrAllUrlsRecodDuringFocusMode = tabMatricsObject.arrAllUrlsRecodDuringFocusMode
    var arrAllAppsRecodDuringFocusMode = tabMatricsObject.arrAllAppsRecodDuringFocusMode
    
    
    arrAllAppsRecodDuringFocusMode = tabMatricsObject.clubAllSameAppEntries(appData: arrAllAppsRecodDuringFocusMode)
    arrAllUrlsRecodDuringFocusMode = tabMatricsObject.clubAllSameDomainEntries(appData: arrAllUrlsRecodDuringFocusMode)
    var arrAllAppsTabsData = arrAllAppsRecodDuringFocusMode
    arrAllAppsTabsData += arrAllUrlsRecodDuringFocusMode
    
    
    
    // Calculate the average duration per tab
    var allAppsWithoutBrowsers = [[String : Any]]()//
    //  ignore browser in average tab count
    for item in arrAllAppsTabsData{
        let isBrowser = item[tabMatricsObject.keyIsBrowser] as? Bool ?? false
        if !isBrowser{
            allAppsWithoutBrowsers.append(item)
        }
    }
    
    let totalDuration = allAppsWithoutBrowsers.reduce(0) { total, entry in
        if let duration = entry["duration"] as? Int {
            return total + duration
        }else{
            print("duration not found:- \(entry["appName"] as? String ?? entry["domain"] as? String ?? "")")
        }
        return total
    }
    
    averageTabDuration = allAppsWithoutBrowsers.isEmpty ? 0 : totalDuration / allAppsWithoutBrowsers.count
    
    // calculate averageTabDurationInLast30Seconds // date 22/5/25  // version 1.23.368
    let last30SecondsAverageTabDuration = tabMatricsObject.getLast30SecondsAverageTabDuration()
    let last30SecondsAverageTabDurationString = last30SecondsAverageTabDuration == nil ? "" : "\(String(describing: last30SecondsAverageTabDuration ?? 0))"
    
    
    addEntryInProductivityStatsCsv(isoString: isoString, currentFocusAlignmentScore: currentFocusAlignmentScore, averageTabCount: averageTabCount, averageTabDuration: averageTabDuration, idleTimeValue: idleTimeValue, averageScoreFromLastEntry: averageScoreFromLastEntry, currentAppTabCount: tabMatricsObject.currentAppTabCount, last30SecondsAverageTabDurationString: last30SecondsAverageTabDurationString)
}

func addEntryInUsageTimingsExplanationCsv(){
    addLog(text: "Try Add Entry In Usage Timings Explanation Csv")
    if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
        addLog(text: "Setting advanced analytics is enabled")
        var arrAllAppsTabsData = [[String:Any]]()
        let arrAllUrlsRecodDuringFocusMode = tabMatricsObject.arrAllUrlsRecodDuringFocusMode
        let arrAllAppsRecodDuringFocusMode = tabMatricsObject.arrAllAppsRecodDuringFocusMode
        
        arrAllAppsTabsData = arrAllAppsRecodDuringFocusMode
        arrAllAppsTabsData += arrAllUrlsRecodDuringFocusMode
        
        arrAllAppsTabsData = arrAllAppsTabsData.sorted { dict1, dict2 in
            guard let startTime1 = dict1[tabMatricsObject.keyFocusStartTime] as? Date,
                  let startTime2 = dict2[tabMatricsObject.keyFocusStartTime] as? Date else {
                return false
            }
            return startTime1 < startTime2
        }
        var arrAllCsvLinesToAdd = [String]()
        for data in arrAllAppsTabsData{
            if let startDate = data[tabMatricsObject.keyFocusStartTime] as? Date, let endDate = data[tabMatricsObject.keyFocusEndTime] as? Date, let duration = data[tabMatricsObject.keyFocusDuration] as? Int{
                let startDateString = getStringFromDate(date: startDate, dateFormat: "HH:mm:ss")
                let endDateString = getStringFromDate(date: endDate, dateFormat: "HH:mm:ss")
                var appOrUrltitle = ""
                if let title = data[tabMatricsObject.keyFocusAppTitle] as? String{
                    appOrUrltitle = title
                }else if let title = data[tabMatricsObject.keyFocusDomainTitle] as? String{
                    appOrUrltitle = title
                }
                let csvString = "\(startDateString),\(endDateString),\(appOrUrltitle),\(duration)"
                arrAllCsvLinesToAdd.append(csvString)
            }
            
        }
        addEntriesInUsageTimingsExplanationCsv(arrAllCsvLinesToAdd: arrAllCsvLinesToAdd)
    }
}


func focusModeFinishedCapturePosthog(){
    let focusDurationMinutes = focusModeActualDurationPerformed / 60
    let isRelaxed = currentRunningFocusType["isRelaxFocus"] as? Bool ?? false
    if isMeetingsFocusStartedAutomatically{
        allApiObject.capturePosthog(event: "completed-meetings-focus-mode", metadata: ["IS_RELAXED": isRelaxed])
    }else if isFocusModeStartedFromPomodoroMode{
        if isFocusModeStartedAutomatically{
            allApiObject.capturePosthog(event: "completed-focus-session", metadata: ["focus-type":"automated_focus", "focusDurationMinutes":focusDurationMinutes, "IS_RELAXED": isRelaxed])
        }else{
            allApiObject.capturePosthog(event: "completed-focus-session", metadata: ["focus-type":"pomodoro", "focusDurationMinutes":focusDurationMinutes, "IS_RELAXED": isRelaxed])
        }
    }else{
        allApiObject.capturePosthog(event: "completed-focus-session", metadata: ["focus-type":"manual_focus", "focusDurationMinutes":focusDurationMinutes, "IS_RELAXED": isRelaxed])
    }
}

func focusModeFinishedResetAllData(){
    refreshFocusModeData()
    arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
}

func focusModeStarttedResetAllData(){
    currentRunningAppNameForAi = ""
    currentBrowserUrlForAi = ""
    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus.removeAll()
    tabMatricsObject.last30SecondsDurationRecordedStartTime = Date()
    arrConvinceAiUrlsInCurrentFocus.removeAll()
    arrConvinceAiAppsInCurrentFocus.removeAll()
    lastEntryInProductivityStatsTime = Date()
    tabMatricsObject.resetAll()
    lastFocusAlignmentShownScore = minFocusAlignmentScoreToShowDistractingPopUp
    isMeetingsFocusStartedAutomatically = false
    focusModeActualDurationPerformed = 0
    unfocusedTime = 0
    UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastFocusModeDoneDate)
    lastFocusModeTempInfo = nil
    appdelegate!.isAutoMeetingsModeStarted = false
    stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
}


// MARK: - Focus New device button

func startFocusModeFromFocusDeviceButton(diffMinutes:Int, shouldUpdateFocusButton:Bool, goal:String?, initiatedByRecording:Bool){
    
    if initiatedByRecording {
        addLog(text: "Focus session triggered by recording activity ")
    } else {
        addLog(text: "Focus session triggered manually from focus device button")
    }
    
    if let goal = goal {
        addLog(text: "Starting focus session for \(diffMinutes) minutes with goal: \(goal)")
    } else {
        addLog(text: "Starting focus session for \(diffMinutes) minutes")
    }
    
    let isFocusModeOn = isFocusModeOn()
    let isFocusModePaused = isFocusModePaused()
    
    if isFocusModeOn{
        addLog(text: "Ignoring focus device button: focus mode already running")
        return;
    }else if isFocusModePaused{
        addLog(text: "Ignoring focus device button: focus mode is paused")
        return;
    }else if isHardCorePomodoroModeOn{
        addLog(text: "Ignoring focus device button: hardcore pomodoro mode is active")
        return;
    }else if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_ || currentState == ._SHUTOFFMAC_{
        addLog(text: "Ignoring focus device button: reason :- current state is \(currentState)")
        return;
    }
    
    
    if diffMinutes > 0{
        addLog(text: "Start focus mode from focus device button")
        if !getTaskPlayerVcObject().isViewLoaded{
            getTaskPlayerVcObject().loadView()
        }
        getTaskPlayerVcObject().loadRequest()
        
        var currentFocusModeIndex = 0
        
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String  == lastRunningFocusModeId{
                currentFocusModeIndex = i
                break;
            }
        }
        
        let calendar = Calendar.current
        startFocusModeTime = Date()
        endFocusModeTime = calendar.date(byAdding: .minute, value: diffMinutes, to: startFocusModeTime!)
        currentFocusModeStrictness = ._NORMAL_
        addLog(text: "focus mode is normal mode")
        arrFocusType[currentFocusModeIndex]["isOn"] = true
        arrFocusType[currentFocusModeIndex]["lastStartedDate"] = getStringFromDate(date: startFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
        arrFocusType[currentFocusModeIndex]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        
        var intention = ""
        if let goal = goal{
            arrFocusType[currentFocusModeIndex]["lastIntentionUsed"] = goal
            intention = goal
        }else{
            intention = arrFocusType[currentFocusModeIndex]["lastIntentionUsed"] as? String ?? ""
        }
        
        
        shouldReloadTaskPlayer = true
        
        if let isAutoDoNotDisturbEnabled = arrFocusType[currentFocusModeIndex]["isAutoDoNotDisturbEnabled"] as? Bool{
            if isAutoDoNotDisturbEnabled{
                if isAccessibilityEnabled(isPrompt: true){
                    DNDManager.shared.setDND(true)
                }
            }
        }
        if !DNDManager.shared.isDndEnabled{
            if let isDeepWorkFocus = arrFocusType[currentFocusModeIndex]["isDeepWorkFocus"] as? Bool{
                if  isDeepWorkFocus{
                    if isAccessibilityEnabled(isPrompt: true){
                        DNDManager.shared.setDND(true)
                    }
                }
            }else if let isDefault = arrFocusType[currentFocusModeIndex]["isDefault"] as? Bool{
                if  isDefault{
                    if isAccessibilityEnabled(isPrompt: true){
                        DNDManager.shared.setDND(true)
                    }
                }
            }
        }
        
        workBeforeFocusBegin(index: currentFocusModeIndex)
        isFocusModeRunning = true
        appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString:arrFocusType[currentFocusModeIndex]["color"] as? String ?? "")
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: intention)
        
        whatToAchieveInFocusBlock = intention
        
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                    showTaskPlayerWindow(totalDuration: diffMinutes, intention: whatToAchieveInFocusBlock, automatically:true)
                }else{
                    if !getTaskPlayerVcObject().isViewLoaded{
                        getTaskPlayerVcObject().loadView()
                    }
                    taskPlayerVcObj?.reloadData(totalDuration: diffMinutes, intention: whatToAchieveInFocusBlock)
                    shouldReloadTaskPlayer = false
                    mainWindowControllerObj?.window?.close()
                }
            }
        }
        
        appdelegate!.statusbutton?.imagePosition = .imageLeft
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            setAppIconForFocusModeScore(probability: nil)
            timerForFocusModeEndNotification = nil
        }
        appdelegate?.setFocusModeTimer(hour: nil, minute: diffMinutes)
        
        //focusButtonService
        if shouldUpdateFocusButton{
            focusButtonServiceObject.startFocusSession(seconds: diffMinutes*60)
        }
        //
        
        appdelegate!.focusModeStartted(isStartedByPusher: false)
    }else{
        addLog(text: "Ignoring focus device button: invalid diffMinutes \(diffMinutes)")
    }
}

func pauseFocusModeFromFocusDeviceButton(shouldUpdateFocusButton:Bool){
    addLog(text: "Pause focus mode from focus device button")
    if isFocusModeRunning{
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true{
                appdelegate?.pauseFocusMode(index: i, shouldUpdateFocusButton: shouldUpdateFocusButton)
                addLog(text: "Successfully Paused focus mode from focus device button")
                break;
            }
        }
    }
}

func resumeFocusModeFromFocusDeviceButton(shouldUpdateFocusButton:Bool)->Bool{
    addLog(text: "Resume focus mode from focus device button")
    
    let isFocusModeOn = isFocusModeOn()
    let isFocusModePaused = isFocusModePaused()
    
    if isFocusModeOn{
        addLog(text: "Ignoring focus device button: focus mode already running")
        return false;
    }else if isFocusModePaused{
        //addLog(text: "Ignoring focus device button: focus mode is paused")
       // return false;
    }else if isHardCorePomodoroModeOn{
        addLog(text: "Ignoring focus device button: hardcore pomodoro mode is active")
        return false;
    }else if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
        addLog(text: "Ignoring focus device button: blocked by current state \(currentState)")
        return false;
    }
    
    
    for index in 0..<arrFocusType.count{
        if arrFocusType[index]["isPaused"] as? Bool == true{
            appdelegate?.resumeFocusMode(index: index, shouldUpdateFocusButton:shouldUpdateFocusButton)
            return true
        }
    }
    return false
}

func finishFocusModeFromFocusDeviceButton(shouldUpdateFocusButton:Bool){
    addLog(text: "Finsh focus mode from focus device button")
    isHardCorePomodoroModeOn = false
    appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: shouldUpdateFocusButton)
}


func createTask(with name:String, dateString:String, shouldShowNotification:Bool){
    addLog(text: "Create task with \(name)")
    allApiObject.addTask(title: name, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result,json in
        if result{
            addLog(text: "\(name) task created successfully.")
            if shouldShowNotification{
                DispatchQueue.main.async {
                    var taskCreatedText = "\"<TASK>\" task created successfully."
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        taskCreatedText = common.value(forKey: "taskCreated") as? String ?? taskCreatedText
                    }
                    taskCreatedText = taskCreatedText.replacingOccurrences(of: "<TASK>", with: name)
                    showCustomAlert(title: taskCreatedText, body: nil, buttonOkText: buttonOkText, buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl:nil, buttonLinkText: nil, completionHandler: {isOkClicked in
                        print(isOkClicked)
                    })
                }
            }
        }
    })
}

func checkAllFocusModes(){
    var isDefaultContain = false
    var defaultContainLocation = -1
    var isMeetingsContain = false
    var islockedFocusContain = false
    var isRelaxFocusContain = false
    
    var isDeepWorkFocusContain = false
    
    
    if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrFocusTypes) as? [[String:Any]]{
        arrFocusType = arr
        
        for i in 0..<arrFocusType.count{
            arrFocusType[i].removeValue(forKey: "doNotSuggestAnyMore")
            arrFocusType[i]["isOn"] = false
            arrFocusType[i]["isPaused"] = false
            if let isDefault = arrFocusType[i]["isDefault"] as? Bool{//this key will only be awailable in default focus type
                if  isDefault{
                    isDefaultContain = isDefault
                    defaultContainLocation = i
                }
            }
            if let isMeetings = arrFocusType[i]["isMeetings"] as? Bool{//this key will only be awailable in default focus type
                if  isMeetings{
                    isMeetingsContain = isMeetings
                }
            }
            if let isLockedFocus = arrFocusType[i]["isLockedFocus"] as? Bool{//this key will only be awailable in default focus type
                if  isLockedFocus{
                    islockedFocusContain = isLockedFocus
                }
            }
            if let isRelaxFocus = arrFocusType[i]["isRelaxFocus"] as? Bool{//this key will only be awailable in default focus type
                if  isRelaxFocus{
                    isRelaxFocusContain = isRelaxFocus
                }
            }
            if let isDeepWorkFocus = arrFocusType[i]["isDeepWorkFocus"] as? Bool{//this key will only be awailable in default focus type
                if  isDeepWorkFocus{
                    isDeepWorkFocusContain = isDeepWorkFocus
                }
            }
            
        }
        
    }
    if !isDefaultContain{
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":"Block super distracting sites/apps", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)),"allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":false, "isDefault":true, "isAllowedListApproach":false, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp, "isAutoDoNotDisturbEnabled": true]//#453//tags
        
        arrFocusType.insert(dic, at: 0)
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.addFocusMode(focusType: dic, completionHandler: {success in
            if success{
                // create first pending blocking schedule for new onboarding
                customBlockingScheduleManagerObj.createFirstBlockingSchedule(focusModeId: id)
            }
        })
        
        
    }
    else{//defalt focus mode will always be first in list so rearranging it
        if defaultContainLocation == 0{
            if arrFocusType[defaultContainLocation]["isAllowedAllApps"] as? Bool == true{
                arrFocusType[defaultContainLocation]["isAllowedAllApps"] = false
                arrFocusType[defaultContainLocation]["allowed_apps"] = []
                arrFocusType[defaultContainLocation]["isAllowedListApproach"] = false
                arrFocusType[defaultContainLocation]["allowed_urls"] = []
                arrFocusType[defaultContainLocation]["blockUrlsArray"] = []
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                
                allApiObject.editFocusMode(focusType: arrFocusType[defaultContainLocation], completionHandler: {newDic in
                    DispatchQueue.main.async {
                        print("*************************api called*****************")
                        
                    }
                })
            }
            
        }else{
            var focusMode = arrFocusType[defaultContainLocation]
            if focusMode["isAllowedAllApps"] as? Bool == true{
                focusMode["isAllowedAllApps"] = false
                focusMode["allowed_apps"] = []
                focusMode["isAllowedListApproach"] = false
                focusMode["allowed_urls"] = []
                focusMode["blockUrlsArray"] = []
                
                allApiObject.editFocusMode(focusType: focusMode, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        print("*************************api called*****************")
                        
                    }
                })
            }
            arrFocusType.remove(at: defaultContainLocation)
            arrFocusType.insert(focusMode, at: 0)
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        }
        
    }// if any new default focus mode created then count should be changed in kUserdefaultsFocusTipsShown
    
    if !isMeetingsContain{
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":"Meetings", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Teams.app", "/Applications/Microsoft Teams classic.app", "/Applications/zoom.us.app", "/Applications/Jitsi.app", "/Applications/Safari.app", "/Applications/Google Chrome.app", "/Applications/Firefox.app", "/Applications/Slack.app", "/Applications/Sidekick.app", "/Applications/Brave Browser.app"], "allowed_urls": ["http://meet.google.com", "http://meet.zoho.com", "focusmate.com", "shimmer.care", "webex.com", "gotomeeting.com", "goto.com/meeting",  "skype.com", "adobeconnect", "join.me", "joinme.com", "slack.com", "whereby.com", "chime.aws", "aws.amazon.com/chime/", "dialpad.com"], "isOn": false, "isAllowedAllApps":false, "isMeetings":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp, "isAutoDoNotDisturbEnabled": true]//#453 , "isBlockedAllUrls":false , "isAllowedAllUrls":false
        
        if arrFocusType.count == 0{
            arrFocusType.append(dic)
        }else{
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.addFocusMode(focusType: dic, completionHandler: {success in
        })
    }
    if !islockedFocusContain{
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":"Locked Focus on current activity", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":false, "isLockedFocus":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp, "isAutoDoNotDisturbEnabled": true]//#453 , "isAllowedAllUrls":false , "isBlockedAllUrls":false
        
        if arrFocusType.count == 0{
            arrFocusType.append(dic)
        }else{
            arrFocusType.append(dic)
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.addFocusMode(focusType: dic, completionHandler: {success in
        })
        
    }
    
    if !isRelaxFocusContain{
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":"Free time - block nothing", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":true, "isRelaxFocus":true, "isAllowedListApproach":false, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp, "isAutoDoNotDisturbEnabled": true]
        
        if arrFocusType.count == 0{
            arrFocusType.append(dic)
        }else{
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.addFocusMode(focusType: dic, completionHandler: {success in
        })
    }
    
    
    if !isDeepWorkFocusContain{
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":"Deep Work", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": ["google.com"], "isOn": false, "isAllowedAllApps":true, "isDeepWorkFocus":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp, "isAutoDoNotDisturbEnabled": true]
        
        if arrFocusType.count == 0{
            arrFocusType.append(dic)
        }else{
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.addFocusMode(focusType: dic, completionHandler: {success in
        })
    }

    
    // occupation relevant focus mode
    if let occupationSpecificRelevantData = occupationSpecificRelevantSitesForFocusMode{
        let userRelevantSites = occupationSpecificRelevantData["user_relevant_sites"] as? [String] ?? []
        let userDistractions = occupationSpecificRelevantData["user_typical_distractions"] as? [String] ?? []
        
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":"Work", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": userRelevantSites, "isOn": false, "isAllowedAllApps":true, "isWorkFocus":true, "isAllowedListApproach":true, "blockUrlsArray": userDistractions, "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp, "autoSuggestFocusModeOnAllowedURL": true, "isAutoDoNotDisturbEnabled": true]
        
        
        if arrFocusType.count == 0{
            arrFocusType.append(dic)
        }else{
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.addFocusMode(focusType: dic, completionHandler: {success in
        })
        
    }
    
    for i in 0..<arrFocusType.count{
        if arrFocusType[i]["isAllowedListApproach"] == nil{
            arrFocusType[i]["isAllowedListApproach"] = true
        }
    }
    
    // locked in current focus should not be visible in focus prefrences thats why removing it and adding it at the end so that we will not show last item in list//486 - Remove Locked Focus
    for i in 0..<arrFocusType.count{
        if let isLockedFocus = arrFocusType[i]["isLockedFocus"] as? Bool{
            if  isLockedFocus{
                if i != arrFocusType.count - 1{
                    let focusMode = arrFocusType[i]
                    arrFocusType.remove(at: i)
                    arrFocusType.append(focusMode)
                }
                break;
            }
        }
        
    }
    sortFocusModes()
    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
    
    
    arrFocusTypeForPomodoro.removeAll()
    for i in 0..<arrFocusType.count{
        if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true){
            arrFocusTypeForPomodoro.append(arrFocusType[i])
        }
    }
    
    UserDefaults.standard.set(true, forKey: kUserdefaultsFocusTipsShown)// The option to setup Focus Mode is no longer required for the user.
}


//saveRemainingFocusModeDuration
// Focus mode end time - actual duration to be stored and also the end time..if current time is more than 24 hrs + end time, cancel it, else resume it 3.32.490
func saveRemainingFocusModeDuration() {
    guard let endFocusModeTime = endFocusModeTime,
          isFocusModeRunning,
          !appdelegate!.isAutoMeetingsModeStarted else {
        return
    }

    guard let selectedFocusMode = arrFocusType.first(where: {
        ($0["isOn"] as? Bool) == true
    }),
    let id = selectedFocusMode["id"] as? String else {
        return
    }

    let remainingSeconds:Int = Int(max(0, endFocusModeTime.timeIntervalSince(Date())))

    UserDefaults.standard.set(
        ["id": id, "remainingSeconds": remainingSeconds],
        forKey: kUserdefaultsLastRunningFocusModeInfo
    )
}



//func readClaudeAppChatTitle(runningApp:NSRunningApplication){
//    let appElement = AXUIElementCreateApplication(runningApp.processIdentifier)
//
//    var windowRef: CFTypeRef?
//
//    let result = AXUIElementCopyAttributeValue(
//        appElement,
//        kAXFocusedWindowAttribute as CFString,
//        &windowRef
//    )
//
//    if result == .success,
//       let window = windowRef {
//        let title = getClaudeConversationTitle(from: window as! AXUIElement)
//        print(title)
//    }
//}
//
//func getClaudeConversationTitle(from window: AXUIElement) -> String? {
//    var texts: [String] = []
//
//    func collectTexts(_ element: AXUIElement) {
//        var roleRef: CFTypeRef?
//
//        if AXUIElementCopyAttributeValue(
//            element,
//            kAXRoleAttribute as CFString,
//            &roleRef
//        ) == .success,
//           let role = roleRef as? String,
//           role == kAXStaticTextRole {
//
//            var valueRef: CFTypeRef?
//
//            if AXUIElementCopyAttributeValue(
//                element,
//                kAXValueAttribute as CFString,
//                &valueRef
//            ) == .success,
//               let value = valueRef as? String,
//               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//
//                texts.append(value)
//            }
//        }
//
//        var childrenRef: CFTypeRef?
//
//        if AXUIElementCopyAttributeValue(
//            element,
//            kAXChildrenAttribute as CFString,
//            &childrenRef
//        ) == .success,
//           let children = childrenRef as? [AXUIElement] {
//
//            children.forEach(collectTexts)
//        }
//    }
//
//    collectTexts(window)
//
//    guard texts.count > 3 else {
//        return nil
//    }
//
//    return texts[3] // 4th item
//}
