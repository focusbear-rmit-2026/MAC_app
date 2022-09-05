//
//  timerViewcontroller.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa
import WebKit
class timerViewcontroller: NSViewController {
    
    
    @IBOutlet weak var boxTimerCenterY: NSLayoutConstraint!
    @IBOutlet weak var titleTopSpace: NSLayoutConstraint!
    @IBOutlet weak var webView: WKWebView!

    // @IBOutlet weak var videoView: AVPlayerView!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    
    
    var timerHideBearAnimation:Timer?
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.6)
    }
    override func viewWillAppear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
    }
    override func viewWillDisappear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
    }
    func loadWebViewTo(url:String?){
        if var videoUrl = url{
            self.webView.isHidden = false
            if videoUrl.lowercased().contains("watch?v="){
                videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
            }else{
            
                if videoUrl.lowercased().contains("https://youtu.be/"){
                    //https://www.youtube.com/watch?v=lExuhKRS8vo
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
            self.webView.load(request)
        }else{
            self.webView.isHidden = true
        }
    }
    func  checkActivityExtraAllowedAppsAndUrls(allowedFocusMode:String){
        activityAllowedFocusApps.removeAll()
        activityAllowedFocusUrls.removeAll()
        
        
        if !allowedFocusMode.isEmpty{
            let filterArr = arrFocusType.filter { $0["name"] as? String == allowedFocusMode}
            if filterArr.count != 0{
                if let dic = filterArr.first{
                    let allowAppsPath = dic["allowed_apps"] as? [String] ?? []
                    print(allowAppsPath)
                    for path in allowAppsPath{
                        let url = URL(fileURLWithPath: path)
                        activityAllowedFocusApps.append(url.deletingPathExtension().lastPathComponent)
                    }
                    activityAllowedFocusUrls = dic["allowed_urls"] as? [String] ?? []
                }
                
            }
        }
        
    }
    
    func startTimerHabit(durationSeconds:Int, url:String?, name:String,currentHabit: habit) {
        graphOneMonthData = nil
        graphOneDayData = nil
        allApiObject.getACtivityStats(activityId: currentHabit.id, activityChoiceId: nil, completionHandler: {dic in
            
        })
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        disableSystemSleep()
        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentHabit.allowedFocusMode)
        if currentHabit.openSpecificApps{
            currentHabitPlaying = currentHabit
            mainWindowControllerObj?.window?.setIsVisible(false)
            appdelegate?.startTimerActivitiesAllowedApp()
            hideBlankWindowInSecondaryMonitor()
            showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false)
        }else{
            if activityAllowedFocusApps.count != 0{
                currentHabitPlaying = currentHabit
                mainWindowControllerObj?.window?.setIsVisible(false)
                appdelegate?.startTimerActivitiesAllowedApp()
                hideBlankWindowInSecondaryMonitor()
                showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false)
            }else{
                 currentHabitPlaying = nil
            }
        }
        
        loadWebViewTo(url: url)
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        lastActivityPerformedTime = Date()
        
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//arrAllMorningHabits[currentHabitIndex].name!)
        currentTimer = 0
        totalDuration = durationSeconds//durationInMinutes*60
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimer.stringValue = "\(minute):\(second)"

        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func hideBearAnimation(){
        resetConstraintsForVideoAndGif(kIsReducedMotion: true)
    }
    
    func resumeTimerHabit(durationSeconds:Int, url:String?, name:String){
//        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
//            if smallCountDownWcObj?.window != nil{
//                if getSmallCountDownWindowObject().window!.isVisible{
//                    if currentHabit.openSpecificApps{
//                        currentHabitPlaying = currentHabit
//                        mainWindowControllerObj?.window?.setIsVisible(false)
//                        appdelegate?.startTimerActivitiesAllowedApp()
//                        hideBlankWindowInSecondaryMonitor()
//                        showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false)
//                    }else{
//                        if activityAllowedFocusApps.count != 0{
//                            currentHabitPlaying = currentHabit
//                            mainWindowControllerObj?.window?.setIsVisible(false)
//                            appdelegate?.startTimerActivitiesAllowedApp()
//                            hideBlankWindowInSecondaryMonitor()
//                            showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false)
//                        }else{
//                             currentHabitPlaying = nil
//                        }
//                    }
//                }
//            }
//        }
        disableSystemSleep()
        loadWebViewTo(url: url)
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(arrAllMorningHabits[currentHabitIndex].name!)."
        totalDuration = durationSeconds//durationInMinutes*60
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimer.stringValue = "\(minute):\(second)"

        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    var currentActicityTitle = ""
    var currentDurationInSeconds = 0
    var currentUrl:String?
    var logQuantityQuestion:String?
    var logQuantityType:String?
    var logActivityQuantity = false
    func startTimerActivity(durationInSeconds:Int,name:String, url:String?, logQuantityQuestion:String?,currentActivity: breakActivity, currentChoice:activityChoice?,logQuantity:Bool, logQuantityType:String) {
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
        activityPostponeCount = 0
        
        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentActivity.allowedFocusMode)
        
        if currentActivity.openSpecificApps{
            currentActivityPlaying = currentActivity
            mainWindowControllerObj?.window?.setIsVisible(false)
            appdelegate?.startTimerActivitiesAllowedApp()
            hideBlankWindowInSecondaryMonitor()
            showSmallTimerWindow(durationSeconds: durationInSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false)
        }else{
            if activityAllowedFocusApps.count != 0{
                currentActivityPlaying = currentActivity
                mainWindowControllerObj?.window?.setIsVisible(false)
                appdelegate?.startTimerActivitiesAllowedApp()
                hideBlankWindowInSecondaryMonitor()
                showSmallTimerWindow(durationSeconds: durationInSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false)
            }else{
                 currentActivityPlaying = nil
            }
        }

        loadWebViewTo(url: url)
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        self.logQuantityQuestion = logQuantityQuestion
        self.logQuantityType = logQuantityType
        currentActicityTitle = name
        currentDurationInSeconds = durationInSeconds
        currentUrl = url
        lastActivityPerformedTime = Date()
        
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(name)."
        currentTimer = 0
        totalDuration = durationInSeconds
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimer.stringValue = "\(minute):\(second)"

        DispatchQueue.main.async {
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
            self.timerHideBearAnimation = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.hideBearAnimation), userInfo: nil, repeats: false)
        }
        if kIsReducedMotion && self.webView.isHidden == false{
            titleTopSpace.constant = 80
            boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.8)
        }else{
            titleTopSpace.constant = 210
            boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.6)
            self.timerHideBearAnimation = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.hideBearAnimation), userInfo: nil, repeats: false)
        }
    }
    func resumeTimerActivity(durationInSeconds:Int,name:String, url:String?) {
        disableSystemSleep()
        loadWebViewTo(url: url)
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(name)."
        totalDuration = durationInSeconds
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimer.stringValue = "\(minute):\(second)"

        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func startBreathing() {
        loadWebViewTo(url: introActivity!.urlsArray.randomElement())
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        
        lblTitle.stringValue = getDoSomeActivityText(activityName: introActivity!.name!)//"Do some \(introActivity!.name!)."
        currentTimer = 0
        totalDuration = introActivity!.durationSeconds!
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimer.stringValue = "\(minute):\(second)"

        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func loadBlankUrl(){
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    @objc func performTimerCount() {
        
        currentTimer += 1//todo 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
//        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
//        if hour.count == 1{
//            hour = "0\(h)"
//        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lblTimer.stringValue = "\(minute):\(second)"
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
}
