//
//  timerViewcontroller.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa
import WebKit
class timerViewcontroller: NSViewController, WKNavigationDelegate{
    
    
  
    @IBOutlet weak var btnTabNotes: NSButton!
    @IBOutlet weak var btnTabVideo: NSButton!
    @IBOutlet weak var boxTakeNotes: NSBox!
    @IBOutlet weak var boxButtonTabViews: NSBox!
    @IBOutlet weak var lblTitleTakeNotes: NSTextField!
    @IBOutlet var textViewNotes: NSTextView!
    @IBOutlet weak var btnSkipHabit: underLineButton!
    @IBOutlet weak var boxPlay: NSBox!
    @IBOutlet weak var btnPause: NSButton!
    @IBOutlet weak var boxTimer: NSBox!
    @IBOutlet weak var boxTimerCenterY: NSLayoutConstraint!
    @IBOutlet weak var titleTopSpace: NSLayoutConstraint!
    @IBOutlet weak var webView: WKWebView!

    // @IBOutlet weak var videoView: AVPlayerView!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    
    var currentActicityTitle = ""
    var currentDurationInSeconds = 0
    var currentUrl:String?
    var logQuantityQuestion:String?
    var logQuantityType:String?
    var logActivityQuantity = false
    
    var timerHideBearAnimation:Timer?
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var startTimerValue = 0// we starts timer after video lodded completely and if user has postponed habit at 10 second then we start again habit after postpone time finished from 10 seconds directly  and to hold that value till video  load we are using this variable.

    
//    var btnPauseTitle = "Pause Activity"
//    var btnResumeTitle = "Resume Activity"
    let pauseIcon = NSImage(named: NSImage.touchBarPauseTemplateName)
    let playIcon = NSImage(named: NSImage.touchBarPlayTemplateName)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnTabVideo.title = "Video"
        btnTabNotes.title = "Notes"
        
        lblTitleTakeNotes.stringValue = "Take Notes"
        textViewNotes.delegate = self
        btnSkipHabit.isHidden = true
        self.webView.navigationDelegate = self
        boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.6)
        
        boxTimer.wantsLayer = true
        boxTimer.shadow = NSShadow()
        boxTimer.layer?.shadowOpacity = 0.3
        boxTimer.layer?.shadowColor = NSColor.black.cgColor
        boxTimer.layer?.shadowOffset = NSMakeSize(0, -2)
        boxTimer.layer?.shadowRadius = 5
        
//        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
//            btnPauseTitle = activityInfo.value(forKey: "buttonPauseText") as? String ?? btnPauseTitle
//            btnResumeTitle = activityInfo.value(forKey: "buttonResumeText") as? String ?? btnResumeTitle
//        }
        
        boxPlay.wantsLayer = true
        boxPlay.shadow = NSShadow()
        boxPlay.layer?.shadowOpacity = 0.3
        boxPlay.layer?.shadowColor = NSColor.black.cgColor
        boxPlay.layer?.shadowOffset = NSMakeSize(0, -2)
        boxPlay.layer?.shadowRadius = 5
        
        
        btnSkipHabit.title = "Skip this habit for today"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnTabVideo.title = activityInfo.value(forKey: "buttonVideoText") as? String ?? btnTabVideo.title
            btnTabNotes.title = activityInfo.value(forKey: "buttonNotesText") as? String ?? btnTabNotes.title
            lblTitleTakeNotes.stringValue = activityInfo.value(forKey: "titleTakeNotes") as? String ?? lblTitleTakeNotes.stringValue
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        
    }
    override func viewWillAppear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
        btnSkipHabit.isHidden = true
    }
    override func viewWillDisappear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
    }
    @IBAction func btnTabNotesClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = false
        btnTabVideo.state = .off
        btnTabNotes.state = .on
    }
    @IBAction func btnTabVideoClicked(_ sender: Any) {
        webView.isHidden = false
        boxTakeNotes.isHidden = true
        btnTabVideo.state = .on
        btnTabNotes.state = .off
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        if isVideoLoding{
            isVideoLoding = false
        }
    }
    var isVideoLoding = false{
        didSet{
            if isVideoLoding{
                mainViewControllerObj?.btnAbort.isEnabled = false
                btnPause.isEnabled = false
            }else{
                mainViewControllerObj?.btnAbort.isEnabled = true
                btnPause.isEnabled = true
                currentTimer = startTimerValue
                startTimerValue = 0
            }
        }
    }
    var isVideoLodded = false
    func loadWebViewTo(url:String?){
        isVideoLodded = false
        if var videoUrl = url{
            self.webView.isHidden = false
            isVideoLodded = true
            if videoUrl.lowercased().contains("watch?v="){
                videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
            }else{
                // doing this beacuse if video is embedded than it will not play
                if videoUrl.lowercased().contains("https://youtu.be/"){
                    if let lastItem =  videoUrl.components(separatedBy: "/").last{
                       videoUrl = "https://www.youtube.com/embed/" + lastItem
                    }
                    
                }
            }
            if videoUrl.contains("?"){
                videoUrl = videoUrl + "&autoplay=1"
            }else{
                videoUrl = videoUrl + "?autoplay=1"
            }
            let link = URL(string:videoUrl)!
            let request = URLRequest(url: link)
            if #available(macOS 12.0, *) {
                self.webView.setAllMediaPlaybackSuspended(false)
            } else {
                // Fallback on earlier versions
            }
            self.webView.load(request)
            allApiObject.capturePosthog(event: "play-youtube-video-in-activity", metadata: [:])
            
            if Reachability.isConnectedToNetwork() == false {
                allApiObject.isInternetOn(completionHandler: {isInternetOn in
                    DispatchQueue.main.async {
                        if !isInternetOn{
                            if self.isVideoLoding{
                                self.isVideoLoding = false
                            }
                        }
                    }
                    
                })
            }
            isVideoLoding = true
        }else{
            isVideoLoding = false
            self.webView.isHidden = true
        }
    }
    func  checkActivityExtraAllowedAppsAndUrls(allowedFocusMode:String){
        //        activityAllowedFocusApps.removeAll()
        //        activityAllowedFocusUrls.removeAll()
        //                activityAllowedFocusMode = nil
        isAnyAllowedFocusModeActivityRunning = false
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        
        if !allowedFocusMode.isEmpty{
            let filterArr = arrFocusType.filter { $0["id"] as? String == allowedFocusMode}
            if filterArr.count != 0{ //if activity has focus mode and and any focus mode is running then silently terminate focus mode
                isAnyAllowedFocusModeActivityRunning = true
                whatToAchieveInFocusBlock = ""
                if let dic = filterArr.first{
                    currentRunningFocusType = dic

                }
                
            }
        }
       
    }
    
    func getRandomVideoUrl(activityId:String, urlsArray: [String])->String?{
        
        if urlsArray.count == 0{
            return nil
        }else{
            var lastVideoIndex = -1
            var  lastSavedVideosDic = [String : Int]()
            if let savedVideosDic = UserDefaults.standard.object(forKey: "lastSavedVideosDic") as? [String:Int]{
                lastSavedVideosDic = savedVideosDic
                if let val = lastSavedVideosDic[activityId]{
                    lastVideoIndex = val
                }
            }

            if lastVideoIndex == -1 || urlsArray.count == 1{
                lastVideoIndex = 0
                lastSavedVideosDic[activityId] = lastVideoIndex
                UserDefaults.standard.set(lastSavedVideosDic, forKey: "lastSavedVideosDic")
                return urlsArray[lastVideoIndex]
            }
            
            lastVideoIndex += 1
            
            if urlsArray.count <= lastVideoIndex{
                lastVideoIndex = 0
            }
            
            let newVideoUrl = urlsArray[lastVideoIndex]
            
            lastSavedVideosDic[activityId] = lastVideoIndex
            UserDefaults.standard.set(lastSavedVideosDic, forKey: "lastSavedVideosDic")
            
            return newVideoUrl;
        }
    }
    func startTimerHabit(durationSeconds:Int, name:String,currentHabit: habit, currentTimerValue:Int) {
        
        let url = getRandomVideoUrl(activityId:currentHabit.id, urlsArray: currentHabit.urlsArray)
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        isAnyAllowedFocusModeActivityRunning = false
        if !(mainViewControllerObj?.isBreakActivityPostponeInsideAllowedHabit ?? false){
            mainViewControllerObj?.stopActivityTimer()
        }
        if isFocusModeOn(){
            addLog(text: "Activity start:- Focus Mode Finished")
            appdelegate?.focusModeFinished(isSilent: true)
        }
        isLastActivityStoppedInRunningState = false
        lastActivityRunningId = ""
        lastActivityStoppedTimerCount = 0
        lastActivityRunningId = currentHabit.id
        
        isActivityPaused = false
        self.btnPause.image = pauseIcon
        btnSkipHabit.isHidden = true
        graphOneMonthData = nil
        graphOneDayData = nil
        allApiObject.getACtivityStats(activityId: currentHabit.id, activityChoiceId: nil, completionHandler: {dic in
            
        })
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        disableSystemSleep()
        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentHabit.allowedFocusMode)
        
        
        
        var shouldLaunchAppAndUrl = true
        if currentTimerValue == 0{
            shouldLaunchAppAndUrl = true
        }else{
            shouldLaunchAppAndUrl = false
        }
        
        
        
        if currentHabit.openSpecificApps{
            currentHabitPlaying = currentHabit
            showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:currentTimerValue)
            mainWindowControllerObj?.window?.setIsVisible(false)
            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: shouldLaunchAppAndUrl)
            hideBlankWindowInSecondaryMonitor()
        }else{
            if isAnyAllowedFocusModeActivityRunning{//if activityAllowedFocusApps.count != 0{
                currentHabitPlaying = currentHabit
                showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:currentTimerValue)
                mainWindowControllerObj?.window?.setIsVisible(false)
                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: shouldLaunchAppAndUrl)
                hideBlankWindowInSecondaryMonitor()
            }else{
                 currentHabitPlaying = nil
            }
        }
        if currentHabitPlaying == nil{// do not allow  video  if activity is allow app type
            loadWebViewTo(url: url)
        }
        if currentHabit.take_notes == DURING_ACTIVITY{//  har jgh ye block load video k niche rakho
            textViewNotes.enclosingScrollView?.isHidden = false
            if shouldLaunchAppAndUrl{
                textViewNotes.string = ""
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            }else{
                textViewNotes.string = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
            }
            
            if isVideoLodded{
                boxTakeNotes.isHidden = true
                boxButtonTabViews.isHidden = false
                btnTabVideo.state = .on
                btnTabNotes.state = .off
            }else{
                boxTakeNotes.isHidden = false
                boxButtonTabViews.isHidden = true
            }
            
        }else{
            boxButtonTabViews.isHidden = true
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            textViewNotes.string = ""
            textViewNotes.enclosingScrollView?.isHidden = true
            boxTakeNotes.isHidden = true
        }
        
        
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        lastActivityPerformedTime = Date()
        
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//arrFilteredMorningHabits[currentHabitIndex].name!)
        startTimerValue = currentTimerValue
        currentTimer = currentTimerValue
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
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

        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func hideBearAnimation(){
        resetConstraintsForVideoAndGif(kIsReducedMotion: true)
    }
    
    func resumeTimerHabit(durationSeconds:Int, url:String?, name:String){
        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                    if currentHabitPlaying != nil{
                        if currentHabitPlaying!.openSpecificApps{
                            currentHabitPlaying = currentHabitPlaying!
                            mainWindowControllerObj?.window?.setIsVisible(false)
                            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: false)
                            hideBlankWindowInSecondaryMonitor()
                            getsmallCountDownVcObject().resumeTimerHabit(durationSeconds: durationSeconds)
                        }else{
                            if isAnyAllowedFocusModeActivityRunning{//activityAllowedFocusApps.count != 0{
                                currentHabitPlaying = currentHabitPlaying!
                                mainWindowControllerObj?.window?.setIsVisible(false)
                                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: false)
                                hideBlankWindowInSecondaryMonitor()
                                getsmallCountDownVcObject().resumeTimerHabit(durationSeconds: durationSeconds)
                            }else{
                                 currentHabitPlaying = nil
                            }
                        }
                    }
                    
                }
            }
        }//!getsmallCountDownVcObject().isFocusBreak{
        disableSystemSleep()
        btnSkipHabit.isHidden = true

        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(arrFilteredMorningHabits[currentHabitIndex].name!)."
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
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

        if !isActivityPaused{
            if url != nil{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(false)
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
                RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            }
        }else{
            if url != nil{
                if #available(macOS 12.0, *) {
                    
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            btnSkipHabit.isHidden = false
        }
        
    }
    
    
    
    func startTimerActivity(durationInSeconds:Int,name:String, urlsArray:[String], logQuantityQuestion:String?,currentActivity: breakActivity, currentChoice:activityChoice?,logQuantity:Bool, logQuantityType:String) {
//        isLastActivityStoppedInRunningState = false
        //lastActivityRunningId = ""
        //lastActivityStoppedTimerCount = 0
        
        var url: String?
        
        if currentChoice == nil{
            url = getRandomVideoUrl(activityId:currentActivity.id, urlsArray: urlsArray)
        }else{
            url = getRandomVideoUrl(activityId:currentChoice!.id, urlsArray: urlsArray)
        }
        
        
        
        if isFocusModeOn(){
            addLog(text: "Activity start:- Focus Mode Finished")
            appdelegate?.focusModeFinished(isSilent: true)
        }
        
        isAnyAllowedFocusModeActivityRunning = false
        btnSkipHabit.isHidden = true
        isActivityPaused = false
        self.btnPause.image = pauseIcon
        graphOneMonthData = nil
        graphOneDayData = nil
        allApiObject.getACtivityCurrentDayStats(activityId: currentActivity.id, activityChoiceId: currentChoice?.id, completionHandler: {dic in
            
        })
        allApiObject.getACtivityStats(activityId: currentActivity.id, activityChoiceId: currentChoice?.id, completionHandler: {dic in
        
        })
        
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        

        
        disableSystemSleep()
        logActivityQuantity = logQuantity
//        activityPostponeCount = 0
        
        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentActivity.allowedFocusMode)
        
        if currentActivity.openSpecificApps{
            currentActivityPlaying = currentActivity
            mainWindowControllerObj?.window?.setIsVisible(false)
            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: true)
            hideBlankWindowInSecondaryMonitor()
            showSmallTimerWindow(durationSeconds: durationInSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:0)
        }else{
            if isAnyAllowedFocusModeActivityRunning{//if activityAllowedFocusApps.count != 0{
                currentActivityPlaying = currentActivity
                mainWindowControllerObj?.window?.setIsVisible(false)
                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: true)
                hideBlankWindowInSecondaryMonitor()
                showSmallTimerWindow(durationSeconds: durationInSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:0)
            }else{
                 currentActivityPlaying = nil
            }
        }
        if currentActivityPlaying == nil{// do not allow  video  if activity is allow app type
            loadWebViewTo(url: url)
        }
        if currentActivity.take_notes == DURING_ACTIVITY{//  har jgh ye block load video k niche rakho
            textViewNotes.enclosingScrollView?.isHidden = false
            textViewNotes.string = ""
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastActivitySavedNotes)
            
            if isVideoLodded{
                boxTakeNotes.isHidden = true
                boxButtonTabViews.isHidden = false
                btnTabVideo.state = .on
                btnTabNotes.state = .off
            }else{
                boxTakeNotes.isHidden = false
                boxButtonTabViews.isHidden = true
            }
            
        }else{
            boxButtonTabViews.isHidden = true
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastActivitySavedNotes)
            textViewNotes.string = ""
            textViewNotes.enclosingScrollView?.isHidden = true
            boxTakeNotes.isHidden = true
        }
        
        
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        self.logQuantityQuestion = logQuantityQuestion
        self.logQuantityType = logQuantityType
        currentActicityTitle = name
        currentDurationInSeconds = durationInSeconds
        currentUrl = url
        lastActivityPerformedTime = Date()
        
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(name)."
        currentTimer = 0
        startTimerValue = 0
        totalDuration = durationInSeconds
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
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

        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
  
    func resetConstraintsForVideoAndGif(kIsReducedMotion:Bool){
        if kIsReducedMotion{
            imgViewGif.image = nil
            self.timerHideBearAnimation?.invalidate()//need to do this
            self.timerHideBearAnimation = nil
        }else{
            imgViewGif.image = NSImage(named: newGifsNamesArray.randomElement() ?? "")
            imgViewGif.animates = true
            self.timerHideBearAnimation?.invalidate()
            self.timerHideBearAnimation = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.hideBearAnimation), userInfo: nil, repeats: false)
        }
        if kIsReducedMotion && isVideoLodded{
            titleTopSpace.constant = 80
            boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.8)
        }else{
            titleTopSpace.constant = 210
            boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.6)
        }
    }
    func resumeTimerActivity(durationInSeconds:Int,name:String, url:String?) {
        disableSystemSleep()
        btnSkipHabit.isHidden = true
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(name)."
        totalDuration = durationInSeconds
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
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

        
        if !isActivityPaused{
            if url != nil{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(false)
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
                RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            }
        }else{
            if url != nil{
                if #available(macOS 12.0, *) {
                    
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
        }
    }
    func startBreathing() {
        isActivityPaused = false
        btnSkipHabit.isHidden = true
        self.btnPause.image = pauseIcon
        loadWebViewTo(url: introActivity!.urlsArray.randomElement())
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        boxButtonTabViews.isHidden = true
        textViewNotes.string = ""
        textViewNotes.enclosingScrollView?.isHidden = true
        boxTakeNotes.isHidden = true
        
        lblTitle.stringValue = getDoSomeActivityText(activityName: introActivity!.name!)//"Do some \(introActivity!.name!)."
        currentTimer = 0
        totalDuration = introActivity!.durationSeconds!
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
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

        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func loadBlankUrl(){
        if boxButtonTabViews.isHidden == false{
            btnTabVideoClicked(self)
        }
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    @objc func performTimerCount() {
        currentTimer += 1//todo 1
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            if self.isVideoLoding{
                if self.currentTimer >= 5{
                    self.isVideoLoding = false
                }
            }else{
                if h == 0{
                    self.lblTimer.stringValue = "\(minute):\(second)"
                }else{
                    self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
                }
            }
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            enableSystemSleep()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.loadBlankUrl()
                    if currentState == ._BREATHING_{
                        mainViewControllerObj?.breathingOver()
                    }else if currentState == ._MORNING_HABIT_ {
                        mainViewControllerObj?.morningHabitOver()
                    }else if currentState == ._EVENING_HABIT_ {
                        mainViewControllerObj?.eveningHabitOver()
                    }else if currentState == ._ACTIVITY_{
                        mainViewControllerObj?.activityOver()
                    }
                }
            }
        }
    }
    var isActivityPaused = false
    @IBAction func btnPauseClicked(_ sender: Any) {
        if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
            timerViewcontrollerObj?.btnTabVideoClicked(self)
        }
        
        if isActivityPaused{
            isActivityPaused = false
            allApiObject.capturePosthog(event: "resume-activity", metadata: [:])
            DispatchQueue.main.async {
                self.btnPause.image = self.pauseIcon
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
                RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            }
            if #available(macOS 12.0, *) {
                webView.setAllMediaPlaybackSuspended(false)
            } else {
                // Fallback on earlier versions
            }
            btnSkipHabit.isHidden = true
        }else{
            self.btnPause.image = playIcon
            isActivityPaused = true
            allApiObject.capturePosthog(event: "pause-activity", metadata: [:])
            timer?.invalidate()
            if #available(macOS 12.0, *) {
                webView.setAllMediaPlaybackSuspended(true)
            } else {
                // Fallback on earlier versions
            }
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                btnSkipHabit.isHidden = false
            }else{
                btnSkipHabit.isHidden = true
            }
        }
        
    }
    
    @IBAction func btnSkipHabitClicked(_ sender: Any) {
        mainViewControllerObj?.showWhySkipHabitView()
    }
}

extension timerViewcontroller:NSTextViewDelegate{
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textViewNotes{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastHabitSavedNotes)
            }else if currentState == ._ACTIVITY_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastActivitySavedNotes)
            }
        }
    }
}
