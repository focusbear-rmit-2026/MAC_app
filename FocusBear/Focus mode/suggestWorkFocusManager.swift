//
//  suggestWorkFocusManager.swift
//  FocusBear
//
//  Created by Manish Jain on 01/04/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


class suggestWorkFocusManager {
    
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "suggestWorkFocusManager")
    private var isRunning = AtomicBool(false)
    private var runningApp:NSRunningApplication?
    
    private var alertIsVisible:Bool = false
    private var nextSuggestionAllowedTime: Date?
    
    /// Start the repeating timer (calls checkInBackground every 1 sec)
    func startUrlTimer(browserName:String, runningApp:NSRunningApplication) {
        // Prevent starting again if already running
        if alertIsVisible{
            return;
        }
        
        let nameLowercased = browserName
        self.runningApp = runningApp
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
        }else{// check app v 3.32.491
            if alertIsVisible || isFocusModeRunning{
                return;
            }
            
            if let nextTime = nextSuggestionAllowedTime,
               Date() < nextTime {
                return;
            }
            checkCheckApp(runningApp: runningApp)
        }
    }
    
    /// Stop the timer completely
    func stopUrlTimer() {
        timer?.cancel()
        timer = nil
    }
    
    
    func checkCheckApp(runningApp:NSRunningApplication){
        if let appUrl = runningApp.bundleURL{
            let name = appUrl.deletingPathExtension().lastPathComponent
            let nameLowercased = name.lowercased()
            
            if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
                return;
            }
            
            for i in 0..<arrFocusType.count{
                let workFocusMode = arrFocusType[i]
                
                let isAllowedListApproachInFocus = workFocusMode["isAllowedListApproach"] as? Bool ?? false
                let allowAppsPath = workFocusMode["allowed_apps"] as? [String] ?? []
                let doNotSuggestAnyMore = arrFocusType[i]["doNotSuggestAnyMore"] as? Bool ?? false
                
                let autoSuggestFocusModeOnAllowedURL = arrFocusType[i]["autoSuggestFocusModeOnAllowedURL"] as? Bool ?? false
                if !autoSuggestFocusModeOnAllowedURL{
                    continue;
                }
                if doNotSuggestAnyMore || !isAllowedListApproachInFocus{
                    continue;
                }
                
                
                var isAllowed = false
                
                
                for path in allowAppsPath{
                    let url = URL(fileURLWithPath: path)
                    if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                        isAllowed = true
                        break;
                    }
                }
                
                
                if alertIsVisible{
                    return;
                }
                if isAllowed{
                    print("suggestion given to user")
                    alertIsVisible = true
                    let name = arrFocusType[i]["name"] as? String ?? ""
                    DispatchQueue.main.async {
                        var title = "You’re currently using a app allowed for <WORK> Focus Mode."
                        var subTitle = "Would you like to start Focus Mode now?"
                        var buttonYes = "Yes, Start"
                        var buttonNotNow = "Not Now"
                        
                        if let info = configjson.value(forKey: "alertStartWorkFocusMode") as? NSDictionary{
                            title = info.value(forKey: "titleApp") as? String ?? title
                            subTitle = info.value(forKey: "subTitle") as? String ?? subTitle
                            buttonYes = info.value(forKey: "buttonYes") as? String ?? buttonYes
                            buttonNotNow = info.value(forKey: "buttonNotNow") as? String ?? buttonNotNow
                        }
                        
                        title = title.replacingOccurrences(of: "<WORK>", with: name)
                        showSuggestFocusWindow(title: title, body: subTitle, buttonOkText: buttonYes, buttonCancelText: buttonNotNow, checkBoxText: nil, autoClose: true, completionHandler: {isOkClicked, duration, intention in
                            print(isOkClicked)
                            if isOkClicked{
                                startWorkFocusAutomaticallyClicked(id: arrFocusType[i]["id"] as? String ?? "", minutes:duration ?? 25, intention:intention ?? "")
                                arrFocusType[i]["doNotSuggestAnyMore"] = false
                            }else{
                                arrFocusType[i]["doNotSuggestAnyMore"] = true
                                
                                // ADD (30 min cooldown)
                                self.nextSuggestionAllowedTime = Date().addingTimeInterval(30 * 60)
                            }
                            self.alertIsVisible = false
                        })
                    }
                    break;
                }
            }
        }
    }
    
    @objc func checkInBackground(){
        if alertIsVisible || isFocusModeRunning{
            return;
        }
        
        if let nextTime = nextSuggestionAllowedTime,
           Date() < nextTime {
            return;
        }
        
        if !isRunning.testAndSet() {
            addLog(text: "return-> func is already running")
            return
        }
        defer { isRunning.clear() }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            addLog(text:"Browsers Permissions not set by user return;")
            return;
        }
        
        guard let runningApp = runningApp else{
            return;
        }
        if let name = runningApp.localizedName{
            var currentBrowser:BROWSER!
            let nameLowercased = name.lowercased()
            
            if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                currentBrowser = browser
            }else{
                self.stopUrlTimer()
                return;
            }
            
            guard var url = getURLSafeInBackground(browser: currentBrowser) else {
                return;
            }
            
            if url == "https://"{
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
            
            
            
            if currentBrowser == ._OPERA_GX_{
                if url.contains("gxcorner.games"){ //  alllow gxcorner (default url) and (chrome:" is also default url which is handled)
                    return;
                }
            }
            if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                url = "https://"+url
            }
            
            
            for turl in defaultAllowedUrl{
                if url.contains(turl){
                    return;
                }
            }
            if !url.contains(defaultPageOfBrowser){
                for i in 0..<arrFocusType.count{
                    let workFocusMode = arrFocusType[i]
                    
                    let isAllowedListApproachInFocus = workFocusMode["isAllowedListApproach"] as? Bool ?? false
                    let arrAllowedUrlsForFocus = workFocusMode["allowed_urls"] as? [String] ?? []
                    let doNotSuggestAnyMore = arrFocusType[i]["doNotSuggestAnyMore"] as? Bool ?? false
                    
                    let autoSuggestFocusModeOnAllowedURL = arrFocusType[i]["autoSuggestFocusModeOnAllowedURL"] as? Bool ?? false
                    if !autoSuggestFocusModeOnAllowedURL{
                        continue;
                    }
                    if doNotSuggestAnyMore || !isAllowedListApproachInFocus{
                        continue;
                    }

                    
                    var isAllowed = false
                    
                    
                    for turl in arrAllowedUrlsForFocus{
                        isAllowed = validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                        if isAllowed{
                            break;
                        }
                    }
                    if !isAllowed{
                        if let title = getTabTitleSafeInBackground(browser: currentBrowser)?.lowercased(){
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
                    
                    
                    if alertIsVisible{
                        return;
                    }
                    if isAllowed{
                        print("suggestion given to user")
                        alertIsVisible = true
                        let name = arrFocusType[i]["name"] as? String ?? ""
                        DispatchQueue.main.async {
                            var title = "You’re currently using a website allowed for <WORK> Focus Mode."
                            var subTitle = "Would you like to start Focus Mode now?"
                            var buttonYes = "Yes, Start"
                            var buttonNotNow = "Not Now"
                            
                            if let info = configjson.value(forKey: "alertStartWorkFocusMode") as? NSDictionary{
                                title = info.value(forKey: "title") as? String ?? title
                                subTitle = info.value(forKey: "subTitle") as? String ?? subTitle
                                buttonYes = info.value(forKey: "buttonYes") as? String ?? buttonYes
                                buttonNotNow = info.value(forKey: "buttonNotNow") as? String ?? buttonNotNow
                            }
                            
                            title = title.replacingOccurrences(of: "<WORK>", with: name)
                            showSuggestFocusWindow(title: title, body: subTitle, buttonOkText: buttonYes, buttonCancelText: buttonNotNow, checkBoxText: nil, autoClose: true, completionHandler: {isOkClicked, duration, intention in
                                print(isOkClicked)
                                if isOkClicked{
                                    startWorkFocusAutomaticallyClicked(id: arrFocusType[i]["id"] as? String ?? "", minutes:duration ?? 25, intention:intention ?? "")
                                    arrFocusType[i]["doNotSuggestAnyMore"] = false
                                }else{
                                    arrFocusType[i]["doNotSuggestAnyMore"] = true
                                    
                                    // ADD (30 min cooldown)
                                    self.nextSuggestionAllowedTime = Date().addingTimeInterval(30 * 60)
                                }
                                self.alertIsVisible = false
                            })
                        }
                        break;
                    }
                }
            }
        }
    }
    
}


