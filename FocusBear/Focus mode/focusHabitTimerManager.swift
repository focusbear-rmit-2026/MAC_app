//
//  habitBlockTimerManager.swift
//  FocusBear
//
//  Created by Manish Jain on 22/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation
// v 2.27.434 - 2.27.435
class habitBlockTimerManager {

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "habitBlockTimerManager")
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
                self?.checkInBackgroundForActivity()
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

    
    @objc func checkInBackgroundForActivity(){
        addLog(text:"func call:- checkInBackgroundForActivity")
        
        if !isRunning.testAndSet() {
            addLog(text: "return-> func is already running")
            return
        } // returns false if already set
        
        defer { isRunning.clear() }
        
        
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            addLog(text:"Browsers Permissions not set by user return;")
            return;
        }
        
        if currentActivityPlaying == nil && currentHabitPlaying == nil{
            self.stopUrlTimer()
            addLog(text:"No habit found:- return;")
            return;
        }
        
        // get running app
        let runningApp = getFrontmostAppSafe()
        
        
        if let runningApp = runningApp, let name = runningApp.localizedName{
            var script: String = ""
            var tabUrl = ""
            var fullUrl = ""
            var needToBlockImmediately = false
            var currentBrowser:BROWSER!
            let nameLowercased = name.lowercased()
            var tabTitle:String?
            if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                currentBrowser = browser
            }else{
                self.stopUrlTimer()
                return;
            }
            var defaultPageOfBrowser = ""
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
            
            if isAnyAllowedFocusModeActivityRunning{
                tabMatricsObject.calculateCurrentBrowserTabCount(currentBrowser: currentBrowser)
            }
            
            if !checkIsCurrentTabAllowed(currentBrowser: currentBrowser){
                return;
            }
            
            var domain = ""
            var originalUrlStringFromBrowser = ""
            
            guard var url = getURLSafeInBackground(browser: currentBrowser) else {
                if isAnyAllowedFocusModeActivityRunning{
                    tabMatricsObject.closeLastDomainIfStarted()
                }
                DispatchQueue.main.async {
                    closePopupBlockWindowIfRunningForUrl()
                }
                return;
            }
            
            originalUrlStringFromBrowser = url
            if currentBrowser == ._OPERA_GX_{
                if url.contains("gxcorner.games"){ //  alllow gxcorner (default url)
                    DispatchQueue.main.async {
                        self.urlInvalidCloseEveryThing()
                    }
                    return;
                }
            }
            // New block page work (when browser is in full screen or stage manager is enable)
            if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{// no need additional check
                if url.localizedCaseInsensitiveContains("yes-i-need=true"){
                    focusAlllowUrlClickedFromNewBlockPage(url: url, currentBrowser: currentBrowser)
                    return;
                }
                
                if url.localizedCaseInsensitiveContains("block-it=true"){
                    if let extractedUrl = focusBlockUrlClickedFromNewBlockPage(url: url, currentBrowser: currentBrowser){
                        url = extractedUrl
                        // originalUrlStringFromBrowser = url
                    }
                }
                
                if url.localizedCaseInsensitiveContains("convince-ai-intention="){
                    let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                    if let extractedUrl = focusConvinceAiIntentionFromNewBlockPage(url: url, currentBrowser: currentBrowser, currentRunningFocusModeName: currentRunningFocusModeName){
                        url = extractedUrl
                        // originalUrlStringFromBrowser = url
                    }
                }
                
                if url.localizedCaseInsensitiveContains("want-achieve="){
                    if let extractedUrl = focusSetUseIntentionFromNewBlockPage(url: url, currentBrowser: currentBrowser){
                        url = extractedUrl
                        //originalUrlStringFromBrowser = url
                    }
                }
                
                if url.localizedCaseInsensitiveContains("unblock_it=true"){
                    allApiObject.capturePosthog(event: "unblock-it-for-me-found", metadata: [:])
                    
                    if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&block_type") {
                        print("Extracted substring: \(extractedUrl)")
                        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                        var extractedPath = getPathFromUrl(url: extractedUrl)//getDomainFromUrl(url: url)
                        
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
                                            extractedPath = domainBlockedUrl// bacuase extractedPath was having / in last eg. facebook.com/
                                            isAlwaysBlockedUrl = true
                                            break;
                                        }
                                    }
                                }
                            }
                            
                            appdelegate!.saveIntentionForBlockedUrl(url: extractedPath, script: "", browser: nil, intention: intentionToShow, seconds: minutesToUnlock * 60, currentPid: nil)
                            
                            
                            allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                            DispatchQueue.main.async {
                                setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                            }
                            return;
                        }
                        
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
                        let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
                        for turl in arrBlockedUrlsForFocus{
                            let isBlocked = validation.isUrlValid(urlToCheck: extractedUrl, allowUrl: turl)
                            if isBlocked{
                                allApiObject.capturePosthog(event: "unblock-it-for-me-not-working-reason-block-url-in-focus-mode", metadata: [:])
                                let hitNewUrl = originalUrlStringFromBrowser.replacingOccurrences(of: "unblock_it=true", with: "")
                                DispatchQueue.main.async {
                                    setUrlToBrowser(browser: currentBrowser, url: hitNewUrl)
                                }
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
                                return;
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
                        
                        return;
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
                            
                            return;
                        } else {
                            print("Substring not found.")
                        }
                        //
                    }
                }
            }
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
            var activityAllowUrls = [String]()
            
            
            if !url.contains(defaultPageOfBrowser){
                domain = getDomainFromUrl(url: url)
                let path = getPathFromUrl(url: url, domain: domain)//getDomainFromUrl(url: url)
                if isAnyAllowedFocusModeActivityRunning{
                    DispatchQueue.main.async {
                        focusModeOpenCurrentUrlForAlignmentScore(domain: path)
                    }
                    tabMatricsObject.frontDomainChanged(domain: path)
                }
                DispatchQueue.main.async {
                    closeAlwaysBlockPopupsIfNotForeCurrentDomain(domain: domain, runningApp: runningApp)
                }
                var isBlocked = false
                var isAllowed = false
                
                
                if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{// no need additional check
                    
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
                    DispatchQueue.main.async {
                        closePopupBlockWindowIfRunningForUrl()
                    }
                    return;
                }
                
                if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{// no need additional check
                    if url.contains("focus_bear_temporarily_allow=true"){//old
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
                
                
                
                var blockType = ""
                if currentState == ._MICRO_BREAK_{
                    if currentActivityPlaying != nil{
                        activityAllowUrls = currentActivityPlaying!.allowUrls
                    }
                    blockType = "break-activity"
                }else if currentState == ._MORNING_HABIT_{
                    if currentHabitPlaying != nil{
                        activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "morning-habit"
                }else if currentState == ._EVENING_HABIT_{
                    if currentHabitPlaying != nil{
                        activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "evening-habit"
                }else if currentState == ._SPECIAL_ACTIVITY_{
                    if currentHabitPlaying != nil{
                        activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "special-activity"
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if currentHabitPlaying != nil{
                        activityAllowUrls = currentHabitPlaying!.allowUrls
                    }
                    blockType = "custom-routine"
                }
                
                
                
                if isAnyAllowedFocusModeActivityRunning == false{
                    for turl in activityAllowUrls{
                        isAllowed = validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                        if isAllowed{
                            break;
                        }
                    }
                    
                    if !isAllowed{
                        if let title = getTabTitleSafeInBackground(browser: currentBrowser)?.lowercased(){
                            tabTitle = title
                            for turl in activityAllowUrls{
                                var starUrl: String = ""
                                starUrl = "*" + turl.lowercased() + "*"
                                isAllowed = wildcard(title, pattern: starUrl)
                                if isAllowed{
                                    break;
                                }
                            }
                        }
                    }
                }else if isAnyAllowedFocusModeActivityRunning{
                    
                    let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
                    let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
                    let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
                    let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
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
                        }
                    }else{
                        //                                    if !isBlockedAllUrlsInFocus{#453
                        isAllowed = true
                        for turl in arrBlockedUrlsForFocus{
                            isBlocked = validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                            if isBlocked{
                                isAllowed = false
                                needToBlockImmediately = true
                                break;
                            }
                        }
                        //                                    }
                    }
                    if !isAllowed{
                        if isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                            var bool = false
                            let arrBlockedUrls = getBlockedUrlsToBlock()
                            for turl in arrBlockedUrls{
                                //Change all suggested blocked apps in onboarding to start with https:// #1233
                                bool = validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                if bool{
                                    //                                                self.isCurrentUrlNotAllowedInCurrentFocsMode = true// Regression: Unblock super distracting URL is not prompting for time limit or intention #1469
                                    // no need to immediately block from now // 19/7/25 version 1.26.392   #1469
                                    blockAlwaysBlockUrl(currentBrowser: currentBrowser, url: url, runningApp: runningApp, blockItem: turl, isCurrentUrlAllowedInFocsMode: false)
                                    return;
                                }
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
                                        //appdelegate!.isCurrentUrlAllowedInCurrentFocsMode = true//
                                        blockAlwaysBlockUrl(currentBrowser: currentBrowser, url: url, runningApp: runningApp, blockItem: turl, isCurrentUrlAllowedInFocsMode: true)
                                    }
                                }
                            }
                        }
                        if !isBlockSuperDistractingFocusModeOn(){
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
                        //                                    return// no need to return here
                    }
                }
                
                
                if !isAllowed{
                    
                    tabUrl = path
                    fullUrl = url
                    url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                    
                    var cuddly_bear_modeString = ""
                    var aiReasonToBlockString = ""
                    if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{
                        cuddly_bear_modeString = "&cuddly_bear_mode=true"
                        aiReasonToBlockString = "<AIREASON>"
                    }
                    
                    switch currentBrowser{
                        
                    case ._SAFARI_:
                        script = getSafariBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._GOOGLE_CHROME_:
                        script = getGoogleChromeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._OPERA_:
                        script = getOperaBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._OPERA_GX_:
                        script = getOperaGxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._VIVALDI_:
                        script = getVivaldiBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._BRAVE_BROWSER_:
                        script = getBraveBrowserBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._SIDEKICK_:
                        script = getSidekickBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._MICROSOFT_EDGE_:
                        script = getMicrosoftEdgeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                        
                    case ._ARC_:
                        script = getArcBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                    case ._FIREFOX_:
                        script = getFirefoxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                    case ._SIGMA_OS_:
                        script = getSigmaOsBrowserBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                    case .none:
                        DispatchQueue.main.async {
                            closePopupBlockWindowIfRunningForUrl()
                        }
                        return
                    }
                    
                }else{
                    DispatchQueue.main.async {
                        closePopupBlockWindowIfRunningForUrl()
                    }
                    return
                }
            }else{
                DispatchQueue.main.async {
                    self.urlInvalidCloseEveryThing()
                }
                return;
            }
            
            
            
            if isAnyAllowedFocusModeActivityRunning{
                DispatchQueue.main.async {
                    if needToBlockImmediately{
                        focusBlockUnwantedUrl(script: script, url: tabUrl, lastBlockReasonFromAi: nil, browser: currentBrowser, isUrlBlockByAi: false, blockReason: "block_in_focus_mode")
                    }else{
                        focusTryToBlockUnwantedUrl(script: script, url: tabUrl, browser: currentBrowser, tabTitle: tabTitle, fullUrl: fullUrl, runningApp:runningApp, domain: domain)
                    }
                }
            }else{
                currentBrowserUrlForAi = ""
                addLog(text:"blockActivityBlockedUrl:- \(tabUrl)")
                script = script.replacingOccurrences(of: "<NEWPAGE>", with: "")
                DispatchQueue.main.async {
                    executeScript(script: script)
                }
                allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":"block_in_habit"])
            }
            
            
        }
    }
    
    func urlInvalidCloseEveryThing(){
        closeSetIntentionBlockedUrlsWinddowIfVisible()
        closeIntentionBlockedUrlsWinddowIfVisible()
        closePopupBlockWindowIfRunningForUrl()
        if isCuddlyModeEnabled() && SettingsManagerObject.isAIBlockingEnabled() && isAnyAllowedFocusModeActivityRunning && !isBlockSuperDistractingFocusModeOn(){
            setFocusBearIconToNormal()
            focusModeCloseCurrentUrlForAlignmentScore()
        }
        if isAnyAllowedFocusModeActivityRunning{
            tabMatricsObject.closeLastDomainIfStarted()
        }
    }
}


