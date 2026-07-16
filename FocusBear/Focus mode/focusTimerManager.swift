//
//  GCDTimerManager.swift
//  FocusBear
//
//  Created by Manish Jain on 21/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Foundation
// v 2.27.434 - 2.27.435
class focusTimerManager {
    
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "focusTimerManager")
    private var isRunning = AtomicBool(false) // we'll implement a tiny AtomicBool below
    
    /// Start the repeating timer (calls checkInBackground every 1 sec)
    func startUrlTimer(browserName:String) {
        // Prevent starting again if already running
        let nameLowercased = browserName
        if arrBrowsersLowerCasedNames.contains(nameLowercased){
            if nameLowercased == "sigmaos"{
                sigmaOsBrowserName = "SigmaOs"
            }else if nameLowercased == "sigmaos_latest"{
                sigmaOsBrowserName = "SigmaOS_latest"
            }
            
            if timer != nil { return }
            
            let newTimer = DispatchSource.makeTimerSource(queue: queue)
            newTimer.schedule(deadline: .now(), repeating: 1)
            
            newTimer.setEventHandler { [weak self] in
                self?.checkInBackground()
            }
            
            newTimer.resume()
            timer = newTimer
        }
    }
    
    /// Stop the timer completely
    func stopUrlTimer() {
        timer?.cancel()
        timer = nil
    }
    
    
    @objc func checkInBackground(){
        addLog(text:"func call:- checkInBackground")
        
        if !isRunning.testAndSet() {
            addLog(text: "return-> func is already running")
            return
        }
        defer { isRunning.clear() }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            addLog(text:"Browsers Permissions not set by user return;")
            return;
        }
        
        if !isFocusModeOn() && !customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            self.stopUrlTimer()
            addLog(text:"focus mode is not running return;")
            return;
        }
        
        var isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
        let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
        let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
        
        if let isDefault = currentRunningFocusType["isDefault"] as? Bool{//this key will only be awailable in default focus type
            if  isDefault{
                isAllowedListApproachInFocus = false
            }
        }
        
        var stringTime: String = ""
        
        if let date = endFocusModeTime{
            stringTime = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        }
        
        
        var currentRunningFocusModeName = ""
        var focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
        var focusMode = ""
        let intention = whatToAchieveInFocusBlock.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        let dic = currentRunningFocusType
        focusMode = dic["name"] as? String ?? ""
        currentRunningFocusModeName = focusMode
        if dic["isOn"] as? Bool == true{
            if let isRelaxFocus = dic["isRelaxFocus"] as? Bool{
                if  isRelaxFocus{
                    addLog(text:"relax focus mode:- return;")
                    return;
                }
            }
        }
        focusModeExpiryTimeString = focusModeExpiryTimeString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        focusMode = focusMode.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        
        // get running app
        let runningApp = getFrontmostAppSafe()
        
        
        if let runningApp = runningApp, let name = runningApp.localizedName{
            
            var script: String = ""
            var tabUrl = ""
            var fullUrl = ""
            var needToBlockImmediately = false
            var currentBrowser:BROWSER!
            let nameLowercased = name.lowercased()
            var tabTitle: String?
            
            
            if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                currentBrowser = browser
            }else{
                if nameLowercased != selfAppName.lowercased(){
                    DispatchQueue.main.async {
                        closePopupBlockWindowIfRunningForUrl()
                    }
                }
                
                self.stopUrlTimer()
                return;
            }
            
            var defaultPageOfBrowser = "chrome:"
            if currentBrowser == ._SAFARI_{
                defaultPageOfBrowser = "favorites:"
            }else if currentBrowser == ._MICROSOFT_EDGE_{
                defaultPageOfBrowser = "edge://newtab"
            }else if currentBrowser == ._SIGMA_OS_{
                defaultPageOfBrowser = "sigma://newpage"
            }else if currentBrowser == ._FIREFOX_{
                defaultPageOfBrowser = "about:newtab"
            }else{
                defaultPageOfBrowser = "chrome:"
            }
            tabMatricsObject.calculateCurrentBrowserTabCount(currentBrowser: currentBrowser)
            
            
            if !checkIsCurrentTabAllowed(currentBrowser: currentBrowser){
                return;
            }
            
            
            
            var domain = ""
            var originalUrlStringFromBrowser = ""
            
            guard var url = getURLSafeInBackground(browser: currentBrowser) else {
                DispatchQueue.main.async {
                    self.urlInvalidCloseEveryThing()
                }
                
                return;
            }
            
            originalUrlStringFromBrowser = url
            
            if currentBrowser == ._OPERA_GX_{
                if url.contains("gxcorner.games"){ //  alllow gxcorner (default url) and (chrome:" is also default url which is handled)
                    DispatchQueue.main.async {
                        self.urlInvalidCloseEveryThing()
                    }
                    return;
                }
            }
            if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                url = "https://"+url
            }
            //
            
            // New block page work (when browser is in full screen or stage manager is enable)
            if SettingsManagerObject.isCuddlyModeEnabled{
                if url.localizedCaseInsensitiveContains("yes-i-need=true"){
                    focusAlllowUrlClickedFromNewBlockPage(url: url, currentBrowser: currentBrowser)
                    return;
                }
                
                if url.localizedCaseInsensitiveContains("block-it=true"){
                    if let extractedUrl = focusBlockUrlClickedFromNewBlockPage(url: url, currentBrowser: currentBrowser){
                        url = extractedUrl
                        originalUrlStringFromBrowser = url
                    }
                }
                
                if url.localizedCaseInsensitiveContains("convince-ai-intention="){
                    if let extractedUrl = focusConvinceAiIntentionFromNewBlockPage(url: url, currentBrowser: currentBrowser, currentRunningFocusModeName: currentRunningFocusModeName){
                        url = extractedUrl
                        originalUrlStringFromBrowser = url
                    }
                }
                
                if url.localizedCaseInsensitiveContains("want-achieve="){
                    if let extractedUrl = focusSetUseIntentionFromNewBlockPage(url: url, currentBrowser: currentBrowser){
                        url = extractedUrl
                        originalUrlStringFromBrowser = url
                    }
                }
            }
            
            //------------unlock url work//----------------
            if checkUrlIsUnlock(url: url, arrBlockedUrlsForFocus: arrBlockedUrlsForFocus, currentBrowser: currentBrowser, originalUrlStringFromBrowser: originalUrlStringFromBrowser){ // if true it means no need to check any thing else //
                return;
            }
            
            //-----------------/
            
            
            for turl in defaultAllowedUrl{
                if url.contains(turl){
                    DispatchQueue.main.async {
                        self.urlInvalidCloseEveryThing()
                    }
                    return;
                }
            }
            if url == "https://"{
                DispatchQueue.main.async {
                    self.urlInvalidCloseEveryThing()
                }
                return;
            }
            
            if !url.contains(defaultPageOfBrowser){
                domain = getDomainFromUrl(url: url)
                let path = getPathFromUrl(url: url, domain: domain)//getDomainFromUrl(url: url)
                focusModeOpenCurrentUrlForAlignmentScoreForBackgroundThread(domain: path)
                tabMatricsObject.frontDomainChanged(domain: path)
                
                DispatchQueue.main.async {
                    closeAlwaysBlockPopupsIfNotForeCurrentDomain(domain: domain, runningApp: runningApp)
                }
                
                var isBlocked = false
                var isAllowed = false
                if SettingsManagerObject.isCuddlyModeEnabled{
                    if arrAllowedDomianInCuddlyModeCurrentFocus.count != 0{
                        if arrAllowedDomianInCuddlyModeCurrentFocus.contains(domain){
                            DispatchQueue.main.async {
                                closePopupBlockWindowIfRunningForUrl()
                            }
                            return;
                        }
                    }
                }
                if arrAllowedUrlsInCuddlyModeCurrentFocus.contains(path){
                    if let title = getTabTitleSafeInBackground(browser: currentBrowser)?.lowercased(){
                        if !arrAllowedTabTitlesInCuddlyModeCurrentFocus.contains(title){
                            arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(title)
                        }
                    }
                    DispatchQueue.main.async {
                        closePopupBlockWindowIfRunningForUrl()
                    }
                    return
                }
                if SettingsManagerObject.isCuddlyModeEnabled{
                    if url.contains("focus_bear_temporarily_allow=true"){// old users
                        var isAlwaysBlockedUrl = false
                        for i in 0..<arrAlwaysBlockedSitesData.count{
                            let dictionary = arrAlwaysBlockedSitesData[i]
                            if let blockUrl = dictionary["url"] as? String{
                                if blockUrl.lowercased() == path.lowercased(){
                                    arrAlwaysBlockedSitesData.remove(at: i)
                                    isAlwaysBlockedUrl = true
                                    break;
                                }
                            }
                        }
                        if isAlwaysBlockedUrl{
                            if url.contains("?focus_bear_temporarily_allow=true"){
                                DispatchQueue.main.async {
                                    setUrlToBrowser(browser: currentBrowser, url: url.replacingOccurrences(of: "?focus_bear_temporarily_allow=true", with: ""))
                                }
                            }else if url.contains("&focus_bear_temporarily_allow=true"){
                                DispatchQueue.main.async {
                                    setUrlToBrowser(browser: currentBrowser, url: url.replacingOccurrences(of: "&focus_bear_temporarily_allow=true", with: ""))
                                }
                            }
                            
                        }else{
                            for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                                if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(path){
                                    arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                    break;
                                }
                            }
                        }
                        return;
                    }
                }
                if isAllowedListApproachInFocus{
                    for turl in arrBlockedUrlsForFocus{
                        isBlocked = validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                        if isBlocked{
                            needToBlockImmediately = true
                            break;
                        }
                    }
                    
                    if !isBlocked{
                        for turl in arrAllowedUrlsForFocus{
                            isAllowed = validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                            if isAllowed{
                                break;
                            }
                        }
                        if !isAllowed{
                            if let title = getTabTitleSafeInBackground(browser: currentBrowser)?.lowercased(){
                                tabTitle = title
                                for turl in arrAllowedUrlsForFocus{
                                    var starUrl: String = ""
                                    starUrl = "*" + turl.lowercased() + "*"
                                    isAllowed = wildcard(title, pattern: starUrl)
                                    if isAllowed{
                                        break;
                                    }
                                }
                            }
                        }
                        // Teacher sessions honour the teacher's AI toggle via isAIBlockingEnabled()
                        // (teacher session → isAiBlockingEnabledForAllowList), so when the teacher
                        // hasn't asked for AI, focusTryToBlockUnwantedUrl's grizzly path blocks
                        // immediately with no ~3-4s AI round trip — no special-case needed here.
                    }
                }else{
                    isAllowed = true
                    for turl in arrBlockedUrlsForFocus{
                        isBlocked = validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                        if isBlocked{
                            isAllowed = false
                            needToBlockImmediately = true
                            break;
                        }
                    }
                }
                
                if !isAllowed{
                    if isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                        var bool = false
                        let arrBlockedUrls = getBlockedUrlsToBlock()
                        for turl in arrBlockedUrls{
                            //Change all suggested blocked apps in onboarding to start with https:// #1233
                            bool = validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                            if bool{
                                //                                            self.isCurrentUrlNotAllowedInCurrentFocsMode = true //
                                //                                            Regression: Unblock super distracting URL is not prompting for time limit or intention #1469
                                // no need to immediately block from now // 19/7/25 version 1.26.392   #1469
                                blockAlwaysBlockUrl(currentBrowser: currentBrowser, url: url, runningApp: runningApp, blockItem: turl, isCurrentUrlAllowedInFocsMode: false)
                                return;
                            }
                        }
                    }
                    
                    tabUrl = path
                    fullUrl = url
                    url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                    
                    var cuddly_bear_modeString = ""
                    var aiReasonToBlockString = ""
                    if SettingsManagerObject.isCuddlyModeEnabled{
                        cuddly_bear_modeString = "&cuddly_bear_mode=true"// this will show "oops i actually need this- unblock it" url button
                        aiReasonToBlockString = "<AIREASON>"
                    }
                    
                    if let currentBrowser = currentBrowser{
                        script = getBlockScriptForFocusMode(url: url, currentBrowser: currentBrowser, intention: intention, cuddly_bear_modeString: cuddly_bear_modeString, aiReasonToBlockString: aiReasonToBlockString, focusMode: focusMode, focusModeExpiryTimeString: focusModeExpiryTimeString)
                    }else{
                        DispatchQueue.main.async {
                            closePopupBlockWindowIfRunningForUrl()
                        }
                    }
                    
                    
                }else{
                    currentBrowserUrlForAi = ""
                    if !isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                        var bool = false
                        let arrBlockedUrls = getBlockedUrlsToBlock()
                        for turl in arrBlockedUrls{
                            //Change all suggested blocked apps in onboarding to start with https:// #1233
                            bool = validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                            if bool{
                                blockAlwaysBlockUrl(currentBrowser: currentBrowser, url: url, runningApp: runningApp, blockItem: turl, isCurrentUrlAllowedInFocsMode: false)
                            }
                        }
                    }else{//super distracting site is allowed in a Focus Mode and focus mode is running - result = should show intention popup. 756
                        if !SettingsManagerObject.immediatelyBlockDistractingSites{
                            var bool = false
                            let arrBlockedUrls = getBlockedUrlsToBlock()
                            for turl in arrBlockedUrls{
                                //Change all suggested blocked apps in onboarding to start with https:// #1233
                                bool = validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                if bool{
                                    blockAlwaysBlockUrl(currentBrowser: currentBrowser, url: url, runningApp: runningApp, blockItem: turl, isCurrentUrlAllowedInFocsMode: true)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        closePopupBlockWindowIfRunningForUrl()
                    }
                    if /*isCuddlyModeEnabled() && SettingsManagerObject.isAIBlockingEnabled() &&*/  !isBlockSuperDistractingFocusModeOn(){
                        if dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path] == nil{
                            addEntryInfocusAlignmentScoreCsv(url: path, tabTitle: tabTitle ?? "", focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: "", allowedProbability: "1.0", totalScore: "")
                            var reason = appAllowedInFocusModeText.replacingOccurrences(of: "<APP>", with: path)
                            reason = reason.replacingOccurrences(of: "<FOCUSMODE>", with: currentRunningFocusModeName)
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path] = ["probability":1.0, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason": reason]
                            DispatchQueue.main.async {
                                boxForStatusBarForTooltip?.customToolTip = reason
                            }
                        }else{
                            var reason = appAllowedInFocusModeText.replacingOccurrences(of: "<APP>", with: path)
                            reason = reason.replacingOccurrences(of: "<FOCUSMODE>", with: currentRunningFocusModeName)
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path]!["probability"] = 1.0
                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path]!["reason"] = reason
                        }
                        DispatchQueue.main.async{
                            calculateFocusAlignmentScore()
                        }
                    }
                    return
                }
            }else{
                DispatchQueue.main.async {
                    self.urlInvalidCloseEveryThing()
                }
                return;
            }
            
            
            
            DispatchQueue.main.async {
                if needToBlockImmediately{
                    focusBlockUnwantedUrl(script: script, url: tabUrl, lastBlockReasonFromAi: nil, browser: currentBrowser, isUrlBlockByAi: false, blockReason: "block_in_focus_mode")
                }else{
                    focusTryToBlockUnwantedUrl(script: script, url: tabUrl, browser: currentBrowser, tabTitle: tabTitle, fullUrl: fullUrl, runningApp:runningApp, domain: domain)
                }
                
            }
        }
    }
    
    func urlInvalidCloseEveryThing(){
        closeSetIntentionBlockedUrlsWinddowIfVisible()
        closeIntentionBlockedUrlsWinddowIfVisible()
        closePopupBlockWindowIfRunningForUrl()
        if SettingsManagerObject.isAIBlockingEnabled(){
            setFocusBearIconToNormal()
            focusModeCloseCurrentUrlForAlignmentScore()
        }
        tabMatricsObject.closeLastDomainIfStarted()
    }
    
    func checkUrlIsUnlock(url:String, arrBlockedUrlsForFocus:[String], currentBrowser:BROWSER, originalUrlStringFromBrowser:String)->Bool{
        if url.localizedCaseInsensitiveContains("unblock_it=true"){
            allApiObject.capturePosthog(event: "unblock-it-for-me-found", metadata: [:])
            if SettingsManagerObject.isCuddlyModeEnabled{
                if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") {
                    print("Extracted substring: \(extractedUrl)")
                    extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                    let extractedPath = getPathFromUrl(url: extractedUrl)//getDomainFromUrl(url: url)
                    
                    var isAlwaysBlockedUrl = false
                    for i in 0..<arrAlwaysBlockedSitesData.count{
                        let dictionary = arrAlwaysBlockedSitesData[i]
                        if let blockUrl = dictionary["url"] as? String{
                            if blockUrl.lowercased() == extractedPath.lowercased(){
                                arrAlwaysBlockedSitesData.remove(at: i)
                                isAlwaysBlockedUrl = true
                                break;
                            }
                        }
                    }
                    if !isAlwaysBlockedUrl{
                        let domainBlockedUrl = getDomainFromUrl(url: extractedUrl)
                        
                        for i in 0..<arrAlwaysBlockedSitesData.count{
                            let dictionary = arrAlwaysBlockedSitesData[i]
                            if let blockUrl = dictionary["url"] as? String{
                                if blockUrl.lowercased() == domainBlockedUrl.lowercased(){
                                    arrAlwaysBlockedSitesData.remove(at: i)
                                    isAlwaysBlockedUrl = true
                                    break;
                                }
                            }
                        }
                    }
                    
                    
                    for turl in arrBlockedUrlsForFocus{
                        let isBlocked = validation.isUrlValid(urlToCheck: extractedUrl, allowUrl: turl)
                        if isBlocked{
                            allApiObject.capturePosthog(event: "unblock-it-for-me-not-working-reason-block-url-in-focus-mode", metadata: [:])
                            let hitNewUrl = originalUrlStringFromBrowser.replacingOccurrences(of: "unblock_it=true", with: "")
                            setUrlToBrowser(browser: currentBrowser, url: hitNewUrl)
                            var msg = "You can't unblock this site because it's currently listed under the blocked URLs for your focus session"
                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                msg = common.value(forKey: "unblockNotAvailableForFocusBlockedUrlText") as? String ?? msg
                            }
                            DispatchQueue.main.async {
                                showCustomAlert(title: msg, body: nil, buttonOkText: buttonOkText, buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl:nil, buttonLinkText: nil, completionHandler: {isOkClicked in
                                    print(isOkClicked)
                                    if isOkClicked{
                                        
                                    }
                                })
                            }
                            return true;
                        }
                    }
                    
                    
                    if !isAlwaysBlockedUrl{
                        for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                            if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(extractedPath){
                                arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                break;
                            }
                        }
                    }
                    allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                    DispatchQueue.main.async {
                        setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                    }
                    
                    return true;
                } else {
                    print("Substring not found.")
                    // work for always block site// if change anything in always block site code then a change also done in blockUrlsInBackground function
                    var extractedUrl: String = ""
                    extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&block_type") ?? ""
                    if extractedUrl.isEmpty{
                        extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") ?? ""
                    }
                    
                    if !extractedUrl.isEmpty {
                        print("Extracted substring: \(extractedUrl)")
                        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                        let extractedPath = getDomainFromUrl(url: extractedUrl)
                        
                        if url.localizedCaseInsensitiveContains("unlock_duration_minutes"){// new blocking page work if browser full screen
                            var minutesToUnlock = 0
                            var intentionToShow = ""
                            let urlInfo = url.components(separatedBy: "&")
                            if urlInfo.count > 1{
                                for info in urlInfo{
                                    if info.localizedCaseInsensitiveContains("unlock_duration_minutes"){
                                        let durationInfo = info.components(separatedBy: "=")
                                        if durationInfo.count > 1{
                                            let minutesString = durationInfo[1]
                                            let minutes = Int(minutesString)
                                            minutesToUnlock = minutes ?? 0
                                        }
                                        
                                    }else if info.localizedCaseInsensitiveContains("distraction_intention"){
                                        let intentionInfo = info.components(separatedBy: "=")
                                        if intentionInfo.count > 1{
                                            intentionToShow = intentionInfo[1]
                                            intentionToShow = intentionToShow.removingPercentEncoding ?? intentionToShow
                                        }
                                        
                                    }
                                }
                            }
                            for i in 0..<arrAlwaysBlockedSitesData.count{
                                let dictionary = arrAlwaysBlockedSitesData[i]
                                if let blockUrl = dictionary["url"] as? String{
                                    if blockUrl.lowercased() == extractedPath.lowercased(){
                                        arrAlwaysBlockedSitesData.remove(at: i)
                                        break;
                                    }
                                }
                            }
                            appdelegate!.saveIntentionForBlockedUrl(url: extractedPath, script: "", browser: nil, intention: intentionToShow, seconds: minutesToUnlock * 60, currentPid: nil)
                            
                            
                            allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                            DispatchQueue.main.async {
                                setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                            }
                        }else{
                            
                            for i in 0..<arrAlwaysBlockedSitesData.count{
                                let dictionary = arrAlwaysBlockedSitesData[i]
                                if let blockUrl = dictionary["url"] as? String{
                                    if blockUrl.lowercased() == extractedPath.lowercased(){
                                        arrAlwaysBlockedSitesData.remove(at: i)
                                        break;
                                    }
                                }
                            }
                            allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                            DispatchQueue.main.async {
                                setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                            }
                            
                            // doing this because url is not allowed in focus mode and blocked in always blocked urls then we immidiatly blocked it if immidiatly block setting is on thats why after clicking unblock it is blocking again. to handle this problem  allowing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
                            if SettingsManagerObject.immediatelyBlockDistractingSites{
                                let seconds =  24*60*60
                                let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
                                arrAlwaysBlockedSitesData.append(["url": extractedPath, "isBlocked": false, "intention" : "", "closed":false, "endTime": endTime, "duration": seconds, "allowFor24Hours": true])
                            }
                        }
                        
                        return true;
                    } else {
                        print("Substring not found.")
                    }
                    //
                }
            }else{
                // C6:- during a teacher-controlled class session the student can't self-unblock a URL
                // ("unblock it for me" is off — the teacher owns the allow-list). Instead of the
                // super-strict dead-end below, navigate the browser back off the unblock URL and open
                // the teacher unlock-request window pre-filled with the blocked URL, so the student can
                // request the teacher to unlock it.
                if teacherSessionManagerObject.isTeacherSessionActive(){
                    addLog(text: "teacher session:- unblock-it-for-me blocked, routing to unlock request window")
                    allApiObject.capturePosthog(event: "unblock-it-for-me-not-working-reason-teacher-session", metadata: [:])
                    let hitNewUrl = originalUrlStringFromBrowser.replacingOccurrences(of: "unblock_it=true", with: "")
                    DispatchQueue.main.async {
                        setUrlToBrowser(browser: currentBrowser, url: hitNewUrl)
                    }

                    if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") {
                        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                        addLog(text: "teacher session:- opening unlock request window for url: \(extractedUrl)")
                        DispatchQueue.main.async {
                            teacherSessionManagerObject.showTeacherUnlockRequestWindow()
                            if let teacherUnlockRequestVcObj = teacherSessionManagerObject.teacherUnlockRequestWindow?.contentViewController as? teacherUnlockRequestVc{
                                teacherUnlockRequestVcObj.textFieldAppOrUrl.stringValue = extractedUrl
                            }

                        }
                    }
                    return false;
                }
                
                allApiObject.capturePosthog(event: "unblock-it-for-me-not-working-reason-super-strict", metadata: [:])
                let hitNewUrl = originalUrlStringFromBrowser.replacingOccurrences(of: "unblock_it=true", with: "")
                DispatchQueue.main.async {
                    setUrlToBrowser(browser: currentBrowser, url: hitNewUrl)
                }
                var msg = "You're in Grizzly Bear mode - change your settings to unblock" 
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    msg = common.value(forKey: "unblockNotAvailableNewText") as? String ?? msg
                }
                DispatchQueue.main.async {
                    showCustomAlert(title: msg, body: nil, buttonOkText: buttonOkText, buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl:nil, buttonLinkText: nil, completionHandler: {isOkClicked in
                        print(isOkClicked)
                        if isOkClicked{
                            
                        }
                    })
                }
                return true;
            }
        }
        return false// it mens funcshould go ahed and check remaining things
    }
    
}

// Tiny atomic bool helper for reentrancy (thread-safe)
final class AtomicBool {
    private let queue = DispatchQueue(label: "AtomicBool")
    private var _value: Bool
    init(_ v: Bool = false) { _value = v }
    @discardableResult
    func testAndSet() -> Bool {
        return queue.sync {
            if _value { return false }
            _value = true
            return true
        }
    }
    func clear() {
        queue.sync { _value = false }
    }
}


//
func blockAlwaysBlockUrl(currentBrowser:BROWSER, url:String, runningApp:NSRunningApplication, blockItem:String, isCurrentUrlAllowedInFocsMode:Bool = false){
    addLog(text:"func call:- blockAlwaysBlockUrl")
    
    currentBrowserUrlForAi = ""
    DispatchQueue.main.async { //
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if !popUpBlockConfirmVcObj!.isAppBlocking{
                    popUpBlockConfirmVcObj?.closeWindow()
                }
            }
        }
    }
    
    var url = url
    var script: String = ""
    var tabUrl:String = ""
    
    let domain = getDomainFromUrl(url: url)//getDomainFromUrl(url: url)
    tabUrl = domain

    var shouldReturn = false
    let semaphore = DispatchSemaphore(value: 0)

    DispatchQueue.main.async {
        if let wnd = setIntentionBlockedUrlsWcObj,
           wnd.window?.isVisible ?? false {

            if setIntentionBlockedUrlsVcObj?.tabUrl == domain {
                exitFullScreen(runningApp: runningApp)
                shouldReturn = true
            } else {
                setIntentionBlockedUrlsVcObj?.closeWindow()
            }
        }
        semaphore.signal()     // tell background thread “done”
    }

    semaphore.wait()           // background thread waits here (safe)

    if shouldReturn {
        return
    }
    
    url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
    
    switch currentBrowser{
        
    case ._SAFARI_:
        script = getSafariBlockScript(url:url)
        
    case ._GOOGLE_CHROME_:
        script = getGoogleChromeBlockScript(url:url)
        
    case ._OPERA_:
        script = getOperaBlockScript(url:url)
        
    case ._OPERA_GX_:
        script = getOperaGxBlockScript(url:url)
        
    case ._VIVALDI_:
        script = getVivaldiBlockScript(url:url)
        
    case ._BRAVE_BROWSER_:
        script = getBraveBrowserBlockScript(url:url)
        
    case ._SIDEKICK_:
        script = getSidekickBlockScript(url:url)
        
    case ._MICROSOFT_EDGE_:
        script = getMicrosoftEdgeBlockScript(url:url)
        
    case ._ARC_:
        script = getArcBlockScript(url:url)
        
    case ._FIREFOX_:
        script = getFirefoxBlockScript(url:url)
        
    case ._SIGMA_OS_:
        script = getSigmaOsBrowserBlockScript(url: url)
    case ._COMET_:
        script = getCometBlockScript(url: url)
    }
    
    
    
    var modeString = ""
    if SettingsManagerObject.isCuddlyModeEnabled{
        modeString = "&block_mode=cuddly"
    }else{
        modeString = "&block_mode=grizzly"
    }
    var isOnboardingString = ""
    
    let blockPageTourShowed = UserDefaults.standard.object(forKey: kUserDefaultsBlockPageTourShowed) as? Bool ?? false
    var shouldShowTour = !blockPageTourShowed
    
    
    if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
            shouldShowTour = false
        }
    }
    //
    if shouldShowTour{
        isOnboardingString = "&show_tour=true"
        UserDefaults.standard.set(true, forKey: kUserDefaultsBlockPageTourShowed)
    }
    
    
    if isCurrentUrlAllowedInFocsMode{
        
        var cuddly_bear_modeString = ""
        var aiReasonToBlockString = ""
        if SettingsManagerObject.isCuddlyModeEnabled{
            cuddly_bear_modeString = "&cuddly_bear_mode=true"
            aiReasonToBlockString = "&reason=This site is always blocked."//The website URL is allowed in focus mode
        }
        if isAnyAllowedFocusModeActivityRunning == true{
            var blockType = ""
            if currentState == ._MICRO_BREAK_{
                blockType = "break-activity"
            }else if currentState == ._MORNING_HABIT_{
                blockType = "morning-habit"
            }else if currentState == ._EVENING_HABIT_{
                blockType = "evening-habit"
            }else if currentState == ._SPECIAL_ACTIVITY_{
                blockType = "special-activity"
            }else if currentState == ._CUSTOM_ROUTINE_{
                blockType = "custom-routine"
            }
            
            script = script.replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)\(modeString)")
        }else{
            var focusMode = ""
            let intention = whatToAchieveInFocusBlock.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
            for dic in arrFocusType{
                if dic["isOn"] as? Bool == true{
                    focusMode = dic["name"] as? String ?? ""
                    break;
                }
            }
            var stringTime: String = ""
            if let date = endFocusModeTime{
                stringTime = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            }
            let focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
            script = script.replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
        }
    }else{
        script = script.replacingOccurrences(of: "<PARAMS>", with: "&block_type=always-blocked\(modeString)\(isOnboardingString)")
    }
    if script.isEmpty{
        return
    }
    DispatchQueue.main.async {
        appdelegate!.tryToBlockAlwaysBlockedUrl(script: script, url: tabUrl, browser: currentBrowser, runningApp: runningApp, blockItem: blockItem)
    }
}


func getURLSafeInBackground(browser: BROWSER) -> String? {
    // Call directly on the caller's (background) thread. runAppleScriptSafely already runs the script
    // off the main thread on its own serial queue, so the old DispatchQueue.main bounce was unnecessary
    // AND harmful: it forced the blocking browser AppleScript onto the main thread (~5–7s per call),
    // freezing the UI — the cause of the AppHangs / blank Day Plan.
    return getActiveTabUrlForBlocking(browser: browser)
}

func getTabTitleSafeInBackground(browser: BROWSER) -> String? {
    // See getURLSafeInBackground — do not bounce to the main thread; the script runs off-main already.
    return getActiveTabTitleOf(browser: browser)
}



func getFrontmostAppSafe() -> NSRunningApplication? {
    var runningApp: NSRunningApplication?
    let semaphore = DispatchSemaphore(value: 0)
    
    DispatchQueue.main.async {
        runningApp = NSWorkspace.shared.frontmostApplication
        semaphore.signal()
    }
    
    semaphore.wait()
    return runningApp
}



