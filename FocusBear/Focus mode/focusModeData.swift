//
//  focusModeData.swift
//  FocusBear
//
//  Created by Manish Jain on 23/04/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


var focusModeTaskString = ""
var taskCreatedByBlockPopup = ""

// #2216: class focus session (teacher) TodoPlayer state — parity with windows-app-v2#1393.
// When `classSessionTodoSessionId` is non-empty the TodoPlayer runs in class-session mode: it opens with
// an empty task list + the `class_session_id`, and the frontend loads/completes the class checklist via
// class-session APIs. `personalFocusTaskStringBackup` holds the student's personal `focusModeTaskString`
// captured at session start, restored when the session ends. In-memory only (not persisted).
var classSessionTodoSessionId = ""
var personalFocusTaskStringBackup = ""
// #2786: the teacher's checklist is now rendered natively in the Focus Session tab (parity with
// windows#1611) rather than handed to the webview. `classSessionTasksVersion` is the `tasks_version`
// currently held; a `class-session-tasks-updated` Pusher event with a newer version triggers a refetch.
var classSessionTasksVersion = 0

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
        if focusModeCloseAppForAlignmentScore(appNameLowercased: key){
            break;
        }
    }
}

/// Stops the alignment-score clock on one app's entry. Returns false when there is no visible entry
/// under that name (nothing to close).
@discardableResult
func focusModeCloseAppForAlignmentScore(appNameLowercased key: String) -> Bool{
    guard var dictionary = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[key],
          dictionary["isVisibleApp"] as? Bool == true else{
        return false
    }
    dictionary["isVisibleApp"] = false
    let startTime = dictionary["startedTime"] as? Date ?? Date()
    let endTime = Date()
    let secondsBetween = endTime.timeIntervalSince(startTime)
    var seconds = dictionary["totalSeconds"] as? Int ?? 0
    seconds += Int(secondsBetween)
    dictionary["totalSeconds"] = seconds
    dictionary["endTime"] = endTime
    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[key] = dictionary
    return true
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
        applyFocusModeTopLevelColumns(from: focusType, to: &json, metadata: &dic)
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


// Ordinary relevance results only. Managed safety checks and appeal re-verification retain their
// own authorization paths and never consult this cache.
private struct CachedAiRelevanceDecision {
    let response: NSDictionary?
    let payload: [String: Any]?
}
private let aiRelevanceDecisionCache = AiRelevanceDecisionCache<CachedAiRelevanceDecision>()
private var currentUrlRelevanceKey: AiRelevanceDecisionKey?
private var currentAppRelevanceKey: AiRelevanceDecisionKey?

func currentAiRelevanceContext() -> Data {
    let fields: [String: Any] = [
        "generation": aiRelevanceDecisionCache.generation,
        "account": appdelegate?.user?.userId ?? "",
        "endpoint": baseUrl,
        "modelContract": "is-safe-to-use-v1",
        "modelVersion": RelevanceModelArtifacts.version,
        "managedPolicyId": ManagedBlockingRuntime.shared.activePolicy?.id ?? "",
        "managedPolicyRevision": ManagedBlockingRuntime.shared.activePolicy?.revision ?? 0,
        "modeAiEnabled": currentRunningFocusType["is_ai_enabled"] as? Bool ?? true,
        "dataCollection": SettingsManagerObject.isDataCollectionModeEnabled,
        "focusId": currentRunningFocusType["id"] as? String ?? "",
        "focusName": currentRunningFocusType["name"] as? String ?? "",
        "aiEnabled": SettingsManagerObject.isAIBlockingEnabled(),
        "strictness": String(describing: currentFocusModeStrictness),
        "cuddly": SettingsManagerObject.isCuddlyModeEnabled,
        "buddy": currentAccountabilityBuddySession != nil,
        "session": startFocusModeTime?.timeIntervalSince1970 ?? 0,
        "classSession": classSessionTodoSessionId,
        "intention": whatToAchieveInFocusBlock,
        "activeTask": AiRelevanceDecisionKey.activeTaskIdentity(in: focusModeTaskString, popupTask: taskCreatedByBlockPopup),
        "tasks": arrCurrentFocusTasks,
        "habitId": currentHabitPlaying?.id ?? "",
        "habitName": currentHabitPlaying?.name ?? currentActivityPlaying?.name ?? "",
        "habitActive": isAnyAllowedFocusModeActivityRunning,
        "language": currentLanguageCode
    ]
    // Unserializable context must miss, never collapse into a reusable empty key.
    return (try? JSONSerialization.data(withJSONObject: fields, options: .sortedKeys)) ?? Data(UUID().uuidString.utf8)
}

private func appRelevanceContent(appName: String, runningApp: NSRunningApplication) -> [String] {
    var context = getArrayOfLast5AppJustifications()
    // A preview is described by its file, never by a window title, so it needs no Accessibility read.
    if isQuickLookService(runningApp) {
        context.insert(quickLookPreviewMonitor.shared.aiContext(forFileNamed: appName), at: 0)
        return context
    }
    // One cache read covers both titles, so an app that wants the conversation title does not pay for
    // two separate Accessibility reads. This never blocks the caller — see claudeTitleReader.
    let titles = claudeTitleReader.shared.titles(for: runningApp)
    if let title = titles.focusedWindow {
        context.insert("The \(appName) window is currently titled: \"\(title)\"", at: 0)
    }
    // Claude's chat title is also sent by the existing API adapter.
    if let title = titles.chat {
        context.append("Claude chat: " + title)
    }
    return context
}

private func urlRelevanceKey(url: String, fullUrl: String, title: String, runningApp: NSRunningApplication) -> AiRelevanceDecisionKey {
    AiRelevanceDecisionKey(context: currentAiRelevanceContext(), kind: "url",
                           target: fullUrl.isEmpty ? url : fullUrl,
                           content: [url, title, runningApp.bundleIdentifier ?? ""] + getArrayOfLast5UrlJustifications())
}

private func appRelevanceKey(appName: String, runningApp: NSRunningApplication) -> AiRelevanceDecisionKey {
    AiRelevanceDecisionKey(context: currentAiRelevanceContext(), kind: "app",
                           target: runningApp.bundleIdentifier ?? appName,
                           content: [appName] + appRelevanceContent(appName: appName, runningApp: runningApp))
}

/// Wraps a read so that repeated calls cost exactly one execution.
///
/// The reads this exists for are blocking AppleScript round-trips capped at 1.2s each, made on the
/// main thread while the user waits for a relevance verdict. The freshness decision and the log line
/// explaining a discarded verdict each asked the browser for the same URL and title, so a single
/// discarded verdict could spend four of those in a row.
///
/// Not thread-safe, and deliberately so: one call site, one synchronous pass, no escaping.
func memoisedRead<T>(_ read: @escaping () -> T?) -> () -> T? {
    var hasRead = false
    var value: T?
    return {
        if !hasRead {
            value = read()
            hasRead = true
        }
        return value
    }
}

/// Why a relevance verdict was or wasn't applied. A discarded verdict has no visible effect, so
/// without naming the reason an AI check that ran, succeeded and was thrown away looks identical in
/// the logs to one that never happened at all.
enum RelevanceFreshness: Equatable {
    case current
    /// A newer check superseded this one, or the page genuinely changed.
    case superseded
    /// Another app is frontmost — the user really did move on.
    case userLeft(frontmost: String)
    /// A browser read failed, so we cannot prove anything either way.
    case unverifiable

    var shouldApplyVerdict: Bool {
        switch self {
        // A failed browser read is not evidence the user moved on. The request key already pins the
        // URL, title and app captured when the check started, and `currentUrlRelevanceKey == key`
        // proves no newer check has begun — so applying the verdict is better than silently dropping
        // it because one AppleScript call happened to time out.
        case .current, .unverifiable: return true
        case .superseded, .userLeft: return false
        }
    }
}

extension RelevanceFreshness {
    /// Pure decision, deliberately free of globals and AppKit so it can be tested directly.
    ///
    /// - `keyIsLive`: no newer check has superseded this one and the request key still matches.
    /// - `liveURL`/`liveTitle`: a fresh re-read of the tab, or nil when the browser read failed.
    /// `liveURL`/`liveTitle` are closures, not values: each is an AppleScript round-trip capped at
    /// 1.2s on the main thread, so they must only run once the cheap checks have already passed.
    /// Evaluating them eagerly froze the UI — two blocking scripts per response, including for the
    /// responses about to be discarded.
    static func decide(keyIsLive: Bool, frontmostBundleID: String?, selfBundleID: String?,
                       targetBundleID: String?, liveURL: () -> String?, liveTitle: () -> String?,
                       observationMatches: (String, String, String?) -> Bool) -> RelevanceFreshness {
        guard keyIsLive else { return .superseded }

        // Focus Bear's own windows — the block popup, the AI buddy, the Day Plan — take focus while a
        // check is in flight. That is us interrupting, not the user navigating away, so it must not
        // invalidate the verdict we asked for.
        let isSelf = selfBundleID != nil && frontmostBundleID == selfBundleID
        let effectiveFrontmost = isSelf ? targetBundleID : frontmostBundleID
        guard effectiveFrontmost == targetBundleID else {
            return .userLeft(frontmost: frontmostBundleID ?? "unknown")
        }

        // Only now — after the frontmost check has passed — is it worth paying for two browser reads.
        guard let liveURL = liveURL(), let liveTitle = liveTitle() else { return .unverifiable }
        return observationMatches(liveURL, liveTitle, effectiveFrontmost) ? .current : .superseded
    }
}

private func urlRelevanceTargetIsCurrent(_ key: AiRelevanceDecisionKey, url: String, fullUrl: String,
                                         title: String, browser: BROWSER?, runningApp: NSRunningApplication) -> Bool {
    let keyIsLive = currentUrlRelevanceKey == key
        && key == urlRelevanceKey(url: url, fullUrl: fullUrl, title: title, runningApp: runningApp)
        && browser != nil
    // Memoised because these are blocking AppleScript round-trips on the main thread, capped at 1.2s
    // EACH, and the diagnostics below used to re-read both — four scripts where two will do, on the
    // path where the user is already waiting for a verdict. Laziness is still what keeps them from
    // running at all until the cheap checks have passed; this is what stops them running twice.
    let readLiveURL = memoisedRead { browser.flatMap { getActiveTabUrlOf(browser: $0) } }
    let readLiveTitle = memoisedRead { browser.flatMap { getActiveTabTitleOf(browser: $0) } }
    let freshness = RelevanceFreshness.decide(
        keyIsLive: keyIsLive,
        frontmostBundleID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
        selfBundleID: Bundle.main.bundleIdentifier,
        targetBundleID: runningApp.bundleIdentifier,
        liveURL: readLiveURL,
        liveTitle: readLiveTitle,
        observationMatches: { liveURL, liveTitle, frontmost in
            key.matchesURLObservation(url: liveURL, title: liveTitle, bundleIdentifier: frontmost)
        })
    if !freshness.shouldApplyVerdict {
        // Name the field that failed. "superseded" alone collapses two very different causes — a
        // newer check replacing this one, versus the tab genuinely reading differently — and the
        // second is usually a comparison mismatch rather than the user moving on.
        var detail = ""
        if freshness == .superseded {
            let liveURL = readLiveURL()
            let liveTitle = readLiveTitle()
            let keyStillLive = currentUrlRelevanceKey == key
            detail = " keyLive=\(keyStillLive)"
                + " urlMatch=\(liveURL == key.target) liveURL=\(liveURL ?? "nil") keyTarget=\(key.target)"
                + " titleMatch=\(liveTitle == (key.content.count > 1 ? key.content[1] : nil))"
                + " liveTitle=\(liveTitle ?? "nil") keyTitle=\(key.content.count > 1 ? key.content[1] : "nil")"
        }
        addLog(text: "relevance verdict discarded for \(url): \(freshness)\(detail)")
    } else if freshness == .unverifiable {
        addLog(text: "relevance verdict applied for \(url) without re-reading the tab (browser read failed)")
    }
    return freshness.shouldApplyVerdict
}

private func appRelevanceTargetIsCurrent(_ key: AiRelevanceDecisionKey, appName: String,
                                         runningApp: NSRunningApplication) -> Bool {
    guard currentAppRelevanceKey == key,
          key == appRelevanceKey(appName: appName, runningApp: runningApp) else { return false }
    if isQuickLookService(runningApp) {
        return quickLookPreviewMonitor.shared.isPreviewOpen(fileName: appName, service: runningApp)
    }
    return NSWorkspace.shared.frontmostApplication?.bundleIdentifier == runningApp.bundleIdentifier
}

/// Reuses the full prior response through the normal decision handler, retaining probability, reason,
/// suggestions and existing strictness behavior. A cache hit performs no credential refresh/API request.
private func cachedAiRelevanceCheck(
    key: AiRelevanceDecisionKey, checkedTarget: String,
    isCurrent: @escaping () -> Bool,
    load: (@escaping (NSDictionary?, String?, [String: Any]?) -> Void) -> Void,
    completion: @escaping (NSDictionary?, String?, [String: Any]?) -> Void
) {
    let guardedCurrent = {
        guard isCurrent() else {
            // Permit a fresh check on returning after an in-flight request was abandoned.
            if currentUrlRelevanceKey == key { currentUrlRelevanceKey = nil }
            if currentAppRelevanceKey == key { currentAppRelevanceKey = nil }
            return false
        }
        return true
    }
    aiRelevanceDecisionCache.resolve(for: key, isCurrent: guardedCurrent, shouldCache: { decision in
        AiRelevanceDecisionKey.isCacheable(probability: decision.response?["allowed_probability"] as? Double,
                                           reason: decision.response?["reason"] as? String ?? "")
    }, load: { done in
        load { response, _, payload in
            DispatchQueue.main.async {
                done(CachedAiRelevanceDecision(response: response?.copy() as? NSDictionary, payload: payload))
            }
        }
    }, completion: { decision in
        completion(decision.response, checkedTarget, decision.payload)
    })
}

var currentBrowserUrlForAi = ""
var currentRunningAppNameForAi = ""
var currentBrowserUrlAiTimeoutCount = 0
let maxBrowserUrlAiTimeoutCount = 3

var currentAppAiTimeoutCount = 0
var isGettingResponseFromAi = false

func tryCheckUrlFromAi(script: String, url:String, tabTitle:String?, browser:BROWSER?, fullUrl:String, domain:String, runningApp:NSRunningApplication){
    guard Thread.isMainThread else {
        DispatchQueue.main.async { tryCheckUrlFromAi(script: script, url: url, tabTitle: tabTitle, browser: browser, fullUrl: fullUrl, domain: domain, runningApp: runningApp) }
        return
    }
    // Bind any eventual redirect to this exact resource inside the browser script as well.
    let script = AiRelevanceRedirectGuard.script(script, expectedURL: fullUrl.isEmpty ? url : fullUrl)
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
    
    
    let observedTitle = tabTitle ?? browser.flatMap { getActiveTabTitleOf(browser: $0) } ?? ""
    let observedKey = urlRelevanceKey(url: url, fullUrl: fullUrl, title: observedTitle, runningApp: runningApp)
    // A same-URL navigation/title/task change is a new input, even before leaving this tab.
    if currentBrowserUrlForAi == url, currentUrlRelevanceKey == observedKey {
        if SettingsManagerObject.isCuddlyModeEnabled{
            if let cached = aiRelevanceDecisionCache.value(for: observedKey), let info = cached.response {
                let reason = info["reason"] as? String ?? ""
                boxForStatusBarForTooltip?.customToolTip = reason
                let probability = info["allowed_probability"] as? Double ?? 0.0
                let payload = cached.payload ?? [:]
                let suggestedTask = info["suggested_task"] as? String
                let suggestedTaskId = info["suggested_task_id"] as? String
                calculateFocusAlignmentScore()
                if probability < 0.70{
                    if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                        if reason.lowercased() != "unable to get a decision from ai. trusting you to decide whether the site is relevant 😅"{
                            guard urlRelevanceTargetIsCurrent(observedKey, url: url, fullUrl: fullUrl, title: observedTitle, browser: browser, runningApp: runningApp) else { return }
                            if isRunningAppFullScreen(runningApp: runningApp, browser: browser) || stageManagerObject.isStageManagerEnabled{
                                let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&ai-focus-block-verification-enabled=true&ai-focus-block-enabled=true&ai-relevance-explanation=\(reason)&ai-relevance-score=\(probability)")
                                executeScript(script: script) // new
                            }else{
                                showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: probability, payload: payload, isBrowser:false, suggestedTask: suggestedTask, suggestedTaskId: suggestedTaskId, isTaskMisalignedWithIntention: info["isTaskMisalignedWithIntention"] as? Bool)
                            }
                        }
                        
                    }
                }
            }
        }
        return;
    }
    currentBrowserUrlForAi = url
    currentUrlRelevanceKey = observedKey
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
    let tab_title = observedTitle
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
    
    
    let requestKey = urlRelevanceKey(url: url, fullUrl: fullUrl, title: tab_title, runningApp: runningApp)
    let isCurrent = {
        urlRelevanceTargetIsCurrent(requestKey, url: url, fullUrl: fullUrl, title: tab_title,
                                    browser: browser, runningApp: runningApp)
    }
    cachedAiRelevanceCheck(key: requestKey, checkedTarget: url, isCurrent: isCurrent, load: { done in
        allApiObject.chatGPTIsURLSafe(url: url, tab_title: tab_title, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, currentTaskInToDoPlayer: currentTaskInToDoPlayer, currentHabitName: currentHabitName, other_explanations_including_domains: arrayOfLast5Domain, completionHandler: done)
    }, completion: {dic, checkedUrl, payload in
        if dic != nil{
            if currentBrowserUrlForAi == checkedUrl{
                do {
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

                        // Shadow mode (Focus-Bear-research/FocusBear-Distraction-Detection-Model#18):
                        // observe-only, never affects the decision above.
                        logRelevanceShadowCheck(focusIntention: whatToAchieveInFocusBlock, tabTitle: tab_title,
                                                currentTask: currentTaskName, url: url, existingProbability: dProbability)

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
                                
                                
                                // Allowed for this exact request key; reused by the relevance cache.
                                
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
                                        showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tab_title, fullUrl:fullUrl, aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: dProbability, payload: payload, isBrowser:false,suggestedTask: suggested_task,suggestedTaskId: suggested_task_id, isTaskMisalignedWithIntention: dic?["isTaskMisalignedWithIntention"] as? Bool)
                                    }
                                }
                            }
                        }else{
                            if(dProbability >= 0.70){
                                // Safe URL
                                addLog(text: "url is safe according to chat gpt")
                                allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                
                                // Allowed for this exact request key; reused by the relevance cache.
                                
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
                // The front tab moved on while the check was in flight, so the verdict is dropped.
                // Log it: the check cost an API call, and a silently discarded decision is otherwise
                // indistinguishable in the logs from one that never ran.
                addLog(text: "relevance verdict dropped: checked \(checkedUrl ?? "nil") but current page is \(currentBrowserUrlForAi)")
                isGettingResponseFromAi = false
            }
        }else{
            do {
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


/// Record an argue-chat justification from the AI-block buddy into the SAME session state the legacy
/// convince-AI flow writes (`checkUrlFromAiWithNewIntention` / `checkAppFromAiWithNewIntention`), but
/// WITHOUT re-calling the backend — the buddy has already decided to allow. This is what lets later
/// backend URL/app safety checks see the reason the user gave:
///  • it appends to `arrConvinceAiUrlsInCurrentFocus` / `arrConvinceAiAppsInCurrentFocus`, which feed
///    `lastFiveJustificationsInThisFocusSession` (via `getArrayOfLast5UrlJustifications` /
///    `getArrayOfLast5AppJustifications`) on every subsequent `chatGPTIsURLSafe`/`chatGPTIsAppSafe` — so a
///    DIFFERENT URL on the same allowed domain is judged with the prior justification, not from scratch, and
///  • it writes the `convinceAiIntention` into `dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus`
///    (keyed by lowercased domain for URLs / lowercased app name for apps, matching `tryCheckUrlFromAi` /
///    `tryCheckAppFromAi`), which becomes `extraJustificationForThisSite` / `justificationForThisSpecificApp`
///    on a same-domain convince re-check.
/// `allowedMinutes` sets how long the entry stays convince-allowed, matching the buddy's chosen time box.
func recordAiBlockBuddyJustification(justification: String, isApp: Bool, appName: String, url: String, fullUrl: String, pageTitle: String, allowedMinutes: Int) {
    let trimmed = justification.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let allowedSeconds = max(0, allowedMinutes) * 60
    let endTime = Calendar.current.date(byAdding: .second, value: allowedSeconds, to: Date()) ?? Date()
    if isApp {
        let appNameLowercased = appName.lowercased()
        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[appNameLowercased] = ["totalDurationSpent": allowedSeconds, "convinceAiIntention": trimmed, "isAllowedByConvinceAi": true, "endTime": endTime, "appName": appName]
        arrConvinceAiAppsInCurrentFocus.append(["app": appName, "intentionForApp": trimmed])
    } else {
        let resolvedUrl = fullUrl.isEmpty ? url : fullUrl
        let domain = getDomainFromUrl(url: resolvedUrl).lowercased()
        dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus[domain] = ["totalDurationSpent": allowedSeconds, "convinceAiIntention": trimmed, "isAllowedByConvinceAi": true, "endTime": endTime, "url": resolvedUrl]
        arrConvinceAiUrlsInCurrentFocus.append(["url": resolvedUrl, "intentionForSite": trimmed, "pageTitle": pageTitle])
    }
    addLog(text: "recordAiBlockBuddyJustification: recorded argue justification for backend relevance checks (isApp:\(isApp))")
}


func refreshFocusModeData(){
    aiRelevanceDecisionCache.removeAll()
    aiBlockBuddyTaskIntentionCache.removeAll()
    currentUrlRelevanceKey = nil
    currentAppRelevanceKey = nil
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
    guard Thread.isMainThread else {
        DispatchQueue.main.async { tryCheckAppFromAi(appName: appName, runningApp: runningApp) }
        return
    }
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
    
    
    // The relevance key below includes the app's window title, which is now read off the main thread.
    // On the first tick after switching to an app that title is not back yet; keying without it would
    // fire one AI check on the bare app name and a second one a tick later when the title landed. Wait
    // for that first read instead — the app stays blocked meanwhile, and the reader's own deadline
    // guarantees this stops waiting (and the check still runs) if the title never arrives.
    // A Quick Look preview is keyed on its file, not a window title, so it never waits for one.
    guard isQuickLookService(runningApp) || claudeTitleReader.shared.hasSettledTitles(for: runningApp) else { return }
    let observedKey = appRelevanceKey(appName: appName, runningApp: runningApp)
    if currentRunningAppNameForAi == appName, currentAppRelevanceKey == observedKey {
        if SettingsManagerObject.isCuddlyModeEnabled{
            if let cached = aiRelevanceDecisionCache.value(for: observedKey), let info = cached.response {
                let reason = info["reason"] as? String ?? ""
                boxForStatusBarForTooltip?.customToolTip = reason
                let probability = info["allowed_probability"] as? Double ?? 0.0
                let payload = cached.payload ?? [:]
                let suggestedTask = info["suggested_task"] as? String
                let suggestedTaskId = info["suggested_task_id"] as? String
                calculateFocusAlignmentScore()
                if probability < 0.70{
                    if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                        if reason.lowercased() != "unable to get a decision from ai. trusting you to decide whether the site is relevant 😅"{
                            guard appRelevanceTargetIsCurrent(observedKey, appName: appName, runningApp: runningApp) else { return }
                            showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true, browser: nil,tabTitle: nil, fullUrl:"", aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: probability, payload: payload, isBrowser:false, suggestedTask: suggestedTask, suggestedTaskId: suggestedTaskId, isTaskMisalignedWithIntention: info["isTaskMisalignedWithIntention"] as? Bool)
                        }
                        
                    }
                }
            }
        }
        return;
    }
    currentRunningAppNameForAi = appName
    currentAppRelevanceKey = observedKey
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
    var appJustifications = getArrayOfLast5AppJustifications()
    if isQuickLookService(runningApp){
        // A Quick Look preview is checked under the previewed file's name; is-app-safe has no file field, so
        // surface the file type + the app it opens with as leading context in the justifications it already weighs.
        appJustifications.insert(quickLookPreviewMonitor.shared.aiContext(forFileNamed: appName), at: 0)
    } else if let windowTitle = claudeTitleReader.shared.focusedWindowTitle(for: runningApp) {
        // The app name alone ("iTerm") is uninformative — give the AI the app's focused-window title (e.g.
        // "literature-search") so its INITIAL block decision judges what's actually on screen, not just the
        // bare app. is-app-safe has no dedicated title field yet (backend coord t86), so surface it as leading
        // context in the justifications it already weighs.
        appJustifications.insert("The \(appName) window is currently titled: \"\(windowTitle)\"", at: 0)
        addLog(text: "checkAppFromAi: \(appName) window title '\(windowTitle)' added to AI context")
    }

    let currentTaskInToDoPlayer = getCurrentTaskInFocusMode()
    addLog(text: "currentTask in is App Safe :\(currentTaskInToDoPlayer)")
    let requestKey = appRelevanceKey(appName: appName, runningApp: runningApp)
    let isCurrent = {
        appRelevanceTargetIsCurrent(requestKey, appName: appName, runningApp: runningApp)
    }
    cachedAiRelevanceCheck(key: requestKey, checkedTarget: appName, isCurrent: isCurrent, load: { done in
        allApiObject.chatGPTIsAppSafe(appName: appName, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, other_explanations_including_apps: appJustifications, currentTaskInToDoPlayer: currentTaskInToDoPlayer, currentHabitName: currentHabitName, completionHandler: done)
    }, completion: {dic, checkedApp, payload in
        if dic != nil{
            if currentRunningAppNameForAi == checkedApp{
                do {
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
                                
                                
                                // Allowed for this exact app/window/task key; no app-wide grant.
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
                                    showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url: "", script:"", isBlockApp:true, browser: nil,tabTitle: nil, fullUrl:"", aiBlockReason: reason, isTimeOut:false, isBlockByAi: true, scoreForThisSiteApp: dProbability, payload: payload, isBrowser:false, suggestedTask: suggested_task, suggestedTaskId: suggested_task_id, isTaskMisalignedWithIntention: dic?["isTaskMisalignedWithIntention"] as? Bool)
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
                                
                                // Allowed for this exact app/window/task key; no app-wide grant.
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
            do {
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
                                // The most this session could legitimately have run: start → its (possibly
                                // extended) scheduled end. Cap the RECORDED duration at this so a resume after
                                // the app was quit/asleep for hours doesn't log all that wall-clock time as
                                // focus (reported: an 18h "focus block" after an overnight force-quit). Captured
                                // before endDate is reassigned in the resume-with-remaining branch below.
                                let scheduledDurationSeconds = max(0, Calendar.current.dateComponents([.second], from: startDate, to: endDate).second ?? 0)

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
                                        // Cap at the scheduled length so an overnight quit/sleep gap isn't recorded as focus time.
                                        focusModeActualDurationPerformed = min(Calendar.current.dateComponents([.second], from: startDate, to: Date()).second ?? diffSeconds, scheduledDurationSeconds)//dont change this line place because  focusModeActualDurationPerformed = 0 in resumeFocusModeAfterAppStartted func
                                        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                                            let minute = diffSeconds / 60
                                            getTaskPlayerVcObject().loadView()
                                            getTaskPlayerVcObject().loadRequest()
                                            shouldReloadTaskPlayer = true
                                            showRunningFocusSessionWindow()
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
                                        // Cap at the scheduled length so an overnight quit/sleep gap isn't recorded as focus time.
                                        focusModeActualDurationPerformed = min(Calendar.current.dateComponents([.second], from: startDate, to: Date()).second ?? diffSeconds, scheduledDurationSeconds)//dont change this line place because  focusModeActualDurationPerformed = 0 in resumeFocusModeAfterAppStartted func
                                        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                                            let minute = diffSeconds / 60
                                            getTaskPlayerVcObject().loadView()
                                            getTaskPlayerVcObject().loadRequest()
                                            shouldReloadTaskPlayer = true
                                            showRunningFocusSessionWindow()
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
                                            showRunningFocusSessionWindow()
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
    // Restore WHO started this session beside the strictness just restored, and from the same durable
    // store — otherwise a session the app auto-started (a Late No More meeting) comes back super-strict
    // with no sign it wasn't the user's own, and Stop/Pause demand a password the user never agreed to.
    // Deliberately independent of restoreAccountabilityBuddySessionIfNeeded(): that one can only attach
    // once isFocusModeRunning is true, which this very function sets further down.
    restoreFocusSessionAutoStartedFlag(resumedFocusModeId: focusMode["id"] as? String ?? "")

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
    // Restoring our own local view of a session that's still running — NOT a user resume, so it must
    // not POST to the backend. Otherwise merely launching the Mac would resume (and broadcast) a
    // session the user had deliberately paused on another device.
    appdelegate?.resumeFocusMode(index: index, shouldSyncToServer: false)
    endFocusModeTime = finishFocusMoedTime
    currentRunningFocusType = focusMode
    startFocusModeTimeForPauseAndResume = Date()
    isFocusModeRunning = true
    if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
        if  isRelaxFocus{
            showSavedSitesForLaterWindowForBreaks()
        }
    }
    // Relaunched into a still-running focus session: restart focus music if the user opted to auto-play
    // it. Never prompts on resume; deferred internally until the async track library has loaded.
    FocusMusicPromptManager.autoStartMusicOnResumeIfEnabled()
}



func updateFocusModeIntention(intention:String){
    if whatToAchieveInFocusBlock != intention{
        whatToAchieveInFocusBlock = intention
        clearAiBlockingDecisionsForNewFocusTarget()// a new intention invalidates the old allow/deny decisions
    }
}

/// Wipe every AI-block decision cached for the CURRENT focus target (the intention + the playing To-Do
/// task) so an app/site that was allowed — or the reasoning gathered — for the OLD target is re-judged
/// against the NEW one. Called whenever the intention changes OR the current task changes: an allow that
/// made sense for the previous task must never silently carry over to a different task. Also cancels the
/// pending time-boxed re-prompts, which were scheduled for the now-stale target. The alignment-score
/// history (`dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus`) is intentionally left intact — it's an
/// observability/score record, not an allow decision, and clearing it would corrupt the session score.
func clearAiBlockingDecisionsForNewFocusTarget() {
    aiRelevanceDecisionCache.removeAll()
    currentUrlRelevanceKey = nil
    currentAppRelevanceKey = nil
    currentBrowserUrlForAi = ""
    currentRunningAppNameForAi = ""
    isGettingResponseFromAi = false
    arrConvinceAiUrlsInCurrentFocus.removeAll()
    arrConvinceAiAppsInCurrentFocus.removeAll()
    arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
    arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
    arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
    dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus.removeAll()
    AiBlockRepromptScheduler.shared.cancelAll()
    addLog(text: "cleared AI blocking decisions for new focus target (intention/task changed)")
}

func updateFocusModeTask(taskString:String){
    // #2216: during a class focus session the TodoPlayer shows the FE-owned class checklist, not the
    // student's personal tasks — never write the player's tasks back into the personal focus task list.
    if !classSessionTodoSessionId.isEmpty{
        addLog(text: "#2216: skip player→personal task sync during class session \(classSessionTodoSessionId)")
        return
    }
    let previousPlayingTask = AiRelevanceDecisionKey.activeTaskIdentity(in: focusModeTaskString, popupTask: taskCreatedByBlockPopup)
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
    // Completing (or switching) the current task changes what counts as relevant — drop the AI decisions
    // made for the previous task so the next site/app is judged against the new one. Only on an actual
    // change of the playing task, so routine task-list refreshes that don't move the current task are cheap.
    if AiRelevanceDecisionKey.activeTaskIdentity(in: focusModeTaskString, popupTask: taskCreatedByBlockPopup) != previousPlayingTask {
        clearAiBlockingDecisionsForNewFocusTarget()
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

/// The session's stated goal, set when the session starts.
///
/// This is NOT the same thing as the current task, and the two must not be conflated: the relevance
/// endpoint takes them as separate fields (`intention` and `currentTaskInToDoPlayer`), and the
/// intention is *locked* in a super-strict session — see `popUpAddNewFocusGoalVc` and
/// `FocusSessionStore.isGoalLocked`.
func currentFocusIntention() -> String {
    whatToAchieveInFocusBlock.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// What the user is working on right now: the task queue's active entry. Changeable from the session
/// screen and from the AI-block buddy's picker; nil when the session has no task.
func currentFocusTaskTitle() -> String? {
    let title = getCurrentTaskInFocusMode()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return title.isEmpty ? nil : title
}

/// Sets the task the user is working on right now, from anywhere outside the session screen (the
/// AI-block buddy's picker, the block popup).
///
/// It deliberately routes through the task queue and **never writes `whatToAchieveInFocusBlock`**.
/// Writing the intention from here was a strictness bypass: a super-strict session forbids changing
/// the focus goal, and a caller that "changed the current task" by assigning the intention silently
/// edited a value the user is not allowed to edit — and made the AI judge against a goal that no
/// longer matched the task on screen.
func setCurrentFocusTask(title: String, id: String, durationSeconds: Int = 600) {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    addLog(text: "setCurrentFocusTask: \(trimmed)")
    taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: trimmed, id: id,
                                                 duration: durationSeconds,
                                                 shouldCompleteCurrentTask: false)
}

var timerForFocusMode:Timer?
var timerForFocusModeEndNotification:Timer?


var endFocusModeTime:Date?// this is focusMode end time wich we calculate at the begning of focus mode
var startFocusModeTime:Date?
var startFocusModeTimeForPauseAndResume:Date?
// For indefinite (no-countdown) focus sessions — e.g. a blocking-schedule-activated block list —
// the timer-based pause/resume flow (`macSleepPauseFocusModeIfRunning`) never runs, so system-sleep
// time would otherwise be counted as focus time and inflate the recorded block duration (a session
// left running overnight logged ~14h and pushed the day's total focus time past 24h). When the Mac
// sleeps mid-session we stamp this; on wake we push `startFocusModeTimeForPauseAndResume` forward by
// the slept interval so the sleep gap is excluded from the block's duration. nil when not asleep.
var indefiniteFocusSleepStartDate:Date?
var focusModeActualDurationPerformed:Int = 0// this will be useful to save in csv and showing focus summary
var focusModeMinutesToPerform = 0
var focusModeSecondsToPerform = 0 //useful in pause resume focus mode
var unfocusedTime = 0

var isFocusModeRunning = false

func isFocusModeOn()->Bool{
    if teacherSessionManagerObject.isTeacherSessionActive(){// a teacher controlled class session runs outside arrFocusType
        return true
    }
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
    if teacherSessionManagerObject.isTeacherSessionActive(){// a teacher controlled class session runs outside arrFocusType
        return true
    }
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

/// Whether the session demands that what the user does align with the stated focus intention — the
/// `task_must_align_to_focus_intention` flag the relevance requests send.
///
/// Two sessions ask for that judgement: the strictest focus mode, and an accountability-buddy session
/// (which judges every app/site against the goal, so it forces the flag even if
/// `currentFocusModeStrictness` was reset mid-session). One predicate, not four copies and a fifth
/// derived one on the block screen: the wording the check-in shows must appear exactly when the server
/// was asked to judge strictly, or the two drift apart.
///
/// Deliberately NOT `isStrictnessLevelNormal()`: that folds in a running custom blocking schedule's
/// `blockLevel`, and a blocking schedule is not a focus session — it has no intention to diverge from,
/// and the relevance request does not ask for strict alignment on its behalf.
func isTaskRequiredToAlignToFocusIntention() -> Bool {
    currentFocusModeStrictness == ._SUPER_STRICT_ || currentAccountabilityBuddySession != nil
}

/// Whether the running session's block list may be swapped for another.
///
/// Report 2026-09-11_10-15-13: "It should show the block list used and let me change it if it's not
/// a super strict session." Super-strict is the whole point of super-strict — swapping to a laxer
/// list mid-session would undo it — and during a class session the teacher owns the settings.
enum FocusSessionBlockListSwitch {
    static func isAllowed(isSessionRunning: Bool, strictness: FOCUSMODESTRICTNESS, isClassSession: Bool) -> Bool {
        isSessionRunning && strictness != ._SUPER_STRICT_ && !isClassSession
    }
}

/// Swap the block list a running focus session enforces, keeping the session itself — its clock, its
/// goal and its task queue — exactly where it is.
///
/// Blocking is driven by `arrFocusType[i]["isOn"]` and `currentRunningFocusType`, which the focus
/// timer re-reads on every tick, so setting those *is* the switch; there is no separate enforcement
/// to restart. The session record on the server keeps the block list it was started with — this is a
/// local change to what gets blocked, not a new session.
@discardableResult
func switchRunningFocusMode(toIndex index: Int) -> Bool {
    guard FocusSessionBlockListSwitch.isAllowed(isSessionRunning: isFocusModeRunning,
                                                strictness: currentFocusModeStrictness,
                                                isClassSession: teacherSessionManagerObject.isTeacherSessionActive()),
          arrFocusType.indices.contains(index) else { return false }
    let newId = arrFocusType[index]["id"] as? String ?? ""
    guard !newId.isEmpty, newId != (currentRunningFocusType["id"] as? String ?? "") else { return false }

    for i in arrFocusType.indices where i != index && arrFocusType[i]["isOn"] as? Bool == true {
        arrFocusType[i]["isOn"] = false
    }
    arrFocusType[index]["isOn"] = true
    arrFocusType[index]["isPaused"] = false
    arrFocusType[index]["lastStartedDate"] = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
    if let end = endFocusModeTime {
        arrFocusType[index]["lastScheduledEndDate"] = getStringFromDate(date: end, dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    // The session's own goal and queue follow it onto the new list, so reopening either later shows
    // what this session was actually doing.
    arrFocusType[index]["lastIntentionUsed"] = whatToAchieveInFocusBlock
    arrFocusType[index]["lastTaskUsed"] = focusModeTaskString
    currentRunningFocusType = arrFocusType[index]
    shouldReloadTaskPlayer = true
    applyAutoDoNotDisturb(forFocusModeAt: index, includingDeepWorkAndDefault: true)
    workBeforeFocusBegin(index: index)
    appdelegate?.setStatusBarButtonColorForFocusMode(color: nil,
                                                     colorString: arrFocusType[index]["color"] as? String ?? "")
    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
    updateAllFocusModes()
    addLog(text: "[user-action] focus session: block list switched to \(arrFocusType[index]["name"] as? String ?? "")")
    return true
}

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
        // A URL the AI determined isn't relevant to the current focus session — worth drawing the
        // user's eye back to the glow border, since this is exactly the kind of drift it's there for.
        FocusGlowBorderManager.shared.pulseWorm()
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
    // A Quick Look preview can't be hidden like an app (the XPC service that hosts it isn't activatable):
    // close the preview window instead. `appName` is the previewed file's name there.
    let isQuickLookPreview = isQuickLookService(runningApp)
    if isQuickLookPreview{
        quickLookPreviewMonitor.shared.closePreviews(hostedBy: runningApp)
    }else{
        exitFullScreen(runningApp:runningApp)
        runningApp.hide()
    }
    allApiObject.capturePosthog(event: "block-distracting-app", metadata: isQuickLookPreview ? ["quick_look_preview": true] : [:])
    if showNotification{
        showFocusAppBlockNotification(appName: appName, runningApp: runningApp, isQuickLookPreview: isQuickLookPreview)
    }
    // The service outlives the preview and hosts every later one, so it must never be remembered as a
    // blocked "app" — each preview is judged on its own file.
    if !isQuickLookPreview && !arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
        arrBlockedAppsInCuddlyModeCurrentFocus.append(runningApp)
    }
}

func focusTryToBlockUnwantedApp(runningApp: NSRunningApplication, appName:String, appNameLowercased:String){
    
    for path in SettingsManagerObject.effectiveAlwaysAllowedApps{
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
    // NOTE: don't exit fullscreen here — this runs BEFORE the block/allow decision below, so an app that
    // ends up allowed (e.g. a browser silently allowed by tryCheckAppFromAi) would be yanked out of
    // fullscreen for nothing. Fullscreen is now exited only where a block actually happens:
    // focusBlockUnwantedApp() and showPopupBlockConfirmWindow() each do it themselves.
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

    // Defense in depth: never start an auto-suggested focus session while a super-strict custom
    // blocking schedule is active — its blocklist must not be overridden by a stale suggestion.
    if customBlockingScheduleManagerObj.isSuperStrictScheduleActive(){
        addLog(text: "Ignored auto-suggested focus start: super-strict blocking schedule active")
        return;
    }

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
                applyAutoDoNotDisturb(forFocusModeAt: i, includingDeepWorkAndDefault: false)
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
                            showRunningFocusSessionWindow()
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
    
    let idleTimeValue = Int(secondsSinceLastUserInput())
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
    // The session is over — cancel any pending AI-block time-boxed re-prompts so none fires afterwards.
    AiBlockRepromptScheduler.shared.cancelAll()
    // Stop focus music that belongs to this session: the "want to play some music?" prompt auto-started
    // it (isFocusMusicStartedFromPrompt), or the user started it from the session's own music controls
    // (#2600, isFocusMusicStartedFromSession). Music started from the standalone Focus Music tab is left
    // playing. Call the shared model directly (allTracksVcObj may never have been created).
    if isFocusMusicStartedFromPrompt || isFocusMusicStartedFromSession {
        FocusMusicViewModel.shared.stopLocalTrack()
        isFocusMusicStartedFromPrompt = false
        isFocusMusicStartedFromSession = false
    }
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
    indefiniteFocusSleepStartDate = nil
    unfocusedTime = 0
    UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastFocusModeDoneDate)
    lastFocusModeTempInfo = nil
    appdelegate!.isAutoMeetingsModeStarted = false
    stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
    // #2600: start clean so a stale flag from a session that ended abnormally can't stop unrelated music.
    isFocusMusicStartedFromSession = false
}


// MARK: - Focus New device button

/// Outcome of a programmatic focus-session start, so callers (notably AppleScript scripting) can
/// surface a precise reason instead of a silent no-op.
enum FocusStartResult {
    case started
    case alreadyRunning
    case paused
    case hardcore
    case activityRunning
    case invalidDuration
    case modeNotFound
}

/// Start a focus session outside the normal UI flow (focus button, audio recording, and — via the
/// `focusModeIndex` override — AppleScript scripting). When `focusModeIndex` is nil the last-used
/// focus mode is started (device-button behaviour); when supplied, that specific mode is started.
@discardableResult
func startFocusModeFromFocusDeviceButton(diffMinutes:Int, shouldUpdateFocusButton:Bool, goal:String?, initiatedByRecording:Bool, focusModeIndex:Int? = nil) -> FocusStartResult{

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
        return .alreadyRunning
    }else if isFocusModePaused{
        addLog(text: "Ignoring focus device button: focus mode is paused")
        return .paused
    }else if isHardCorePomodoroModeOn{
        addLog(text: "Ignoring focus device button: hardcore pomodoro mode is active")
        return .hardcore
    }else if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_ || currentState == ._SHUTOFFMAC_{
        addLog(text: "Ignoring focus device button: reason :- current state is \(currentState)")
        return .activityRunning
    }
    
    
    if diffMinutes > 0{
        addLog(text: "Start focus mode from focus device button")
        if !getTaskPlayerVcObject().isViewLoaded{
            getTaskPlayerVcObject().loadView()
        }
        getTaskPlayerVcObject().loadRequest()
        
        var currentFocusModeIndex = 0

        if let overrideIndex = focusModeIndex{
            guard overrideIndex >= 0 && overrideIndex < arrFocusType.count else {
                addLog(text: "Ignoring focus start: focus mode index \(overrideIndex) out of range")
                return .modeNotFound
            }
            currentFocusModeIndex = overrideIndex
        }else{
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["id"] as? String  == lastRunningFocusModeId{
                    currentFocusModeIndex = i
                    break;
                }
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
        // #777: remember the chosen duration per focus mode (rides the same arrFocusType persistence/sync
        // as lastIntentionUsed) so each mode defaults to its own last duration next time.
        arrFocusType[currentFocusModeIndex]["lastDurationUsed"] = diffMinutes

        var intention = ""
        if let goal = goal{
            arrFocusType[currentFocusModeIndex]["lastIntentionUsed"] = goal
            intention = goal
        }else{
            intention = arrFocusType[currentFocusModeIndex]["lastIntentionUsed"] as? String ?? ""
        }
        
        
        shouldReloadTaskPlayer = true
        
        applyAutoDoNotDisturb(forFocusModeAt: currentFocusModeIndex, includingDeepWorkAndDefault: true)
        
        workBeforeFocusBegin(index: currentFocusModeIndex)
        isFocusModeRunning = true
        appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString:arrFocusType[currentFocusModeIndex]["color"] as? String ?? "")
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: intention)
        
        whatToAchieveInFocusBlock = intention

        // #2163: load this focus mode's saved task into the Todo Player, matching the menu/pomodoro start
        // paths (startFocusFromMenu / pomodoroVc). The Todo Player payload reads focusModeTaskString; this
        // path never set it, so sessions started from the focus button, audio recording or AppleScript
        // attached no task to the mode while a menu-started one did.
        focusModeTaskString = arrFocusType[currentFocusModeIndex]["lastTaskUsed"] as? String ?? ""

        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                    showRunningFocusSessionWindow()
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
        return .started
    }else{
        addLog(text: "Ignoring focus device button: invalid diffMinutes \(diffMinutes)")
        return .invalidDuration
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

/// Zoho's meeting product lives on `meeting.zoho.<region tld>` (`meeting.zoho.com`, `.eu`, `.in`,
/// `.com.au`, …). The default Meetings allow-list used to say `meet.zoho.com`, which never matches a
/// live Zoho call (#2388): the URL check is a substring wildcard, and "meet.zoho.com" is not a
/// substring of "meeting.zoho.com".
let zohoMeetingDomain = "meeting.zoho.com"
/// Prefix shared by every regional Zoho Meeting host; used by the browser-meeting detector.
let zohoMeetingHostPrefix = "meeting.zoho."
private let legacyZohoMeetingDomain = "meet.zoho.com"
private let zohoMeetingAppPath = "/Applications/Zoho Meeting.app"

/// One-time, idempotent repair of a user's existing Meetings focus mode (created once, then stored
/// locally and on the backend, so fixing the default alone leaves every existing user on the wrong
/// domain): swap the legacy `meet.zoho.com` allow-list entry for `meeting.zoho.com` and add the Zoho
/// Meeting desktop app. Returns true when something changed (the caller syncs it to the backend).
///
/// NOTE: `checkAllFocusModes()` calls this on EVERY app startup, and it re-adds any missing entry — so if
/// a user manually removes `meeting.zoho.com` from the allow-list, or the Zoho Meeting app from the
/// allowed apps, of their Meetings focus mode, both are added back on the next launch (and re-synced to
/// the backend). These entries are enforced on purpose (a Meetings focus must allow Zoho meetings); there
/// is currently no way for a user to permanently remove them.
private func repairMeetingsFocusModeZohoEntries(at index: Int) -> Bool {
    var changed = false
    var allowedUrls = arrFocusType[index]["allowed_urls"] as? [String] ?? []
    func stripped(_ url: String) -> String {
        url.lowercased().replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
    }
    if let legacyIndex = allowedUrls.firstIndex(where: { stripped($0) == legacyZohoMeetingDomain }) {
        allowedUrls[legacyIndex] = "http://\(zohoMeetingDomain)"
        changed = true
    }
    if !allowedUrls.contains(where: { stripped($0) == zohoMeetingDomain }) {
        allowedUrls.append("http://\(zohoMeetingDomain)")
        changed = true
    }
    var allowedApps = arrFocusType[index]["allowed_apps"] as? [String] ?? []
    if !allowedApps.contains(zohoMeetingAppPath) {
        allowedApps.append(zohoMeetingAppPath)
        changed = true
    }
    guard changed else { return false }
    arrFocusType[index]["allowed_urls"] = allowedUrls
    arrFocusType[index]["allowed_apps"] = allowedApps
    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
    addLog(text: "checkAllFocusModes: repaired Meetings focus mode Zoho entries (#2388)")
    return true
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
                    if repairMeetingsFocusModeZohoEntries(at: i) {
                        allApiObject.editFocusMode(focusType: arrFocusType[i], completionHandler: { _ in })
                    }
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
        // The default focus mode already exists (e.g. a returning / multi-device user). Capture its id
        // BEFORE any rearranging so the pending onboarding blocking schedule can still be linked to it.
        let existingDefaultFocusModeId = arrFocusType[defaultContainLocation]["id"] as? String ?? ""
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
        // Persist the onboarding "first blocking schedule" against the EXISTING default focus mode.
        // Previously createFirstBlockingSchedule was only called in the `if !isDefaultContain` branch
        // (when the default mode was freshly created), so a user who ALREADY had the default mode
        // (returning / multi-device) had their onboarding-created schedule silently dropped — it stayed
        // in the in-memory pendingFirstBlockingSchedule and was never saved or POSTed. Guarded on the
        // pending schedule so this only fires right after onboarding, not on every launch.
        if customBlockingScheduleManagerObj.pendingFirstBlockingSchedule != nil {
            customBlockingScheduleManagerObj.createFirstBlockingSchedule(focusModeId: existingDefaultFocusModeId)
        }
    }// if any new default focus mode created then count should be changed in kUserdefaultsFocusTipsShown
    
    if !isMeetingsContain{
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":"Meetings", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Teams.app", "/Applications/Microsoft Teams classic.app", "/Applications/zoom.us.app", "/Applications/Jitsi.app", "/Applications/Safari.app", "/Applications/Google Chrome.app", "/Applications/Firefox.app", "/Applications/Slack.app", "/Applications/Sidekick.app", "/Applications/Brave Browser.app", "/Applications/Zoho Meeting.app"], "allowed_urls": ["http://meet.google.com", "http://\(zohoMeetingDomain)", "focusmate.com", "shimmer.care", "webex.com", "gotomeeting.com", "goto.com/meeting",  "skype.com", "adobeconnect", "join.me", "joinme.com", "slack.com", "whereby.com", "chime.aws", "aws.amazon.com/chime/", "dialpad.com"], "isOn": false, "isAllowedAllApps":false, "isMeetings":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp, "isAutoDoNotDisturbEnabled": true]//#453 , "isBlockedAllUrls":false , "isAllowedAllUrls":false
        
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
