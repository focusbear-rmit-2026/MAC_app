//
//  timerViewcontroller.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa
import WebKit
class timerViewcontroller: NSViewController {
    
    
    @IBOutlet weak var webView: WKWebView!

    // @IBOutlet weak var videoView: AVPlayerView!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func loadWebViewTo(url:String?){
        if var videoUrl = url{
            self.webView.isHidden = false
            videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
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

    func startTimerHabit(durationSeconds:Int, url:String?, name:String,currentHabit: habit) {
        
        disableSystemSleep()
        if currentHabit.openSpecificApps{
            currentHabitPlaying = currentHabit
            mainWindowControllerObj?.window?.setIsVisible(false)
            appdelegate?.startTimerActivitiesAllowedApp()
            hideBlankWindowInSecondaryMonitor()
        }else{
            currentHabitPlaying = nil
        }

        if kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: newGifsNamesArray.randomElement() ?? "")
            imgViewGif.animates = true
        }
        
        lastActivityPerformedTime = Date()
        loadWebViewTo(url: url)
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
//        DispatchQueue.global().async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
//            RunLoop.current.run()
//        }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    func resumeTimerHabit(durationSeconds:Int, url:String?, name:String){
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
//        DispatchQueue.global().async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
//            RunLoop.current.run()
//        }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    var currentActicityTitle = ""
    var currentDurationInSeconds = 0
    var currentUrl:String?
    var logQuantityQuestion:String?
    var logActivityQuantity = false
    func startTimerActivity(durationInSeconds:Int,name:String, url:String?, logQuantityQuestion:String?,currentActivity: breakActivity,logQuantity:Bool) {
        disableSystemSleep()
        logActivityQuantity = logQuantity
        
        if currentActivity.openSpecificApps{
            currentActivityPlaying = currentActivity
            mainWindowControllerObj?.window?.setIsVisible(false)
            appdelegate?.startTimerActivitiesAllowedApp()
            hideBlankWindowInSecondaryMonitor()
            showSmallTimerWindow(durationSeconds: durationInSeconds, name: name, isFocusBreak: false)
        }else{
            currentActivityPlaying = nil
        }

        if kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: newGifsNamesArray.randomElement() ?? "")
            imgViewGif.animates = true
        }
        self.logQuantityQuestion = logQuantityQuestion
        currentActicityTitle = name
        currentDurationInSeconds = durationInSeconds
        currentUrl = url
        lastActivityPerformedTime = Date()
        loadWebViewTo(url: url)
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
//        DispatchQueue.global().async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
//            RunLoop.current.run()
//        }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
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
//        DispatchQueue.global().async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
//            RunLoop.current.run()
//        }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func startBreathing() {
        if kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: newGifsNamesArray.randomElement() ?? "")
            imgViewGif.animates = true
        }
        
        loadWebViewTo(url: introActivity!.urlsArray.randomElement())
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
//        DispatchQueue.global().async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
//            RunLoop.current.run()
//        }
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
        
        currentTimer += 1
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
