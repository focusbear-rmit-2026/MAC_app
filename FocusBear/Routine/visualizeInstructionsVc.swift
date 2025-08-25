//
//  visualizeInstructions.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.

import Cocoa
import WebKit

class visualizeInstructionsVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var boxStarRating: NSBox!
    @IBOutlet weak var stackViewStarRating: NSStackView!
    @IBOutlet weak var btnSkipTimer: underLineButton!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var btnSkipHabit: underLineButton!
    @IBOutlet weak var btnMain: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblVisualizeText: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnStarFirst: cursorButton!
    @IBOutlet weak var btnStarSecond: cursorButton!
    @IBOutlet weak var btnStarThird: cursorButton!
    @IBOutlet weak var btnStarFourth: cursorButton!
    @IBOutlet weak var btnStarFifth: cursorButton!
    @IBOutlet weak var lblHowMotivated: NSTextField!
    @IBOutlet weak var textFieldRating: NSTextField!
    
    var isMotivationalMessageShowing = false
    
    var arrOptions = ["I'm feeling energized - time to begin my habits",
                      "Let's kick things off - I'm motivated to start my habits",
                      "I'm ready to get going - let's start implementing my habits",
                      "I'm pumped up and ready to begin my habits",
                      "Let's get this show on the road - I'm fired up to start my habits",
                      "I'm feeling enthusiastic - it's time to start my habits",
                      "I'm excited to begin my habits - let's get started",
                      "Let's dive right in - I'm ready to start my habits",
                      "I'm fired up and ready to make my habits stick",
                      "I'm eager to start implementing my habits - let's go",
                      "I'm amped up to begin my habits - let's start now",
                      "I'm feeling motivated - time to start my habits",
                      "Let's start building my habits - I'm feeling inspired",
                      "I'm energized and ready to begin my habits",
                      "I'm fired up and raring to go - let's start my habits"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblHowMotivated.stringValue = "How motivated do you feel to do your habits?"
        lblTitle.stringValue = "Get Focused"
        lblVisualizeText.stringValue = "Before you begin your morning routine, take 30 seconds to engage in \"extrapersonal focus\": try your best to keep your eyes fixed on the target. Research from Balcetis and colleagues in 2020 indicates that concentrating on a visual point will sharpen your focus and increase the likelihood of completing your routine."
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            lblVisualizeText.stringValue = activityInfo.value(forKey: "visualizeDescriptionText") as? String ?? lblVisualizeText.stringValue
            lblTitle.stringValue = activityInfo.value(forKey: "titleGetFocused") as? String ?? lblTitle.stringValue
            lblHowMotivated.stringValue = activityInfo.value(forKey: "questionHowMotivatedText") as? String ?? lblHowMotivated.stringValue
        }
        btnSkipHabit.title = "Skip this habit for today"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        webView.isHidden = true
        
        if let inspirations = configjson.value(forKey: "inspirations") as? [String]{
            arrOptions = inspirations
        }
        self.webView.navigationDelegate = self
        btnSkipTimer.title = "Skip"
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            btnSkipTimer.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkipTimer.title
        }
        textFieldRating.placeholderString = "What is motivating you to do your habits today?"
    }
    
    override func viewWillDisappear() {
        isMotivationalMessageShowing = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            //sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                self.setAccessTokenToWebView()
                self.loader.stopAnimation(self)
                self.webView.isHidden = false
                self.boxStarRating.isHidden = false
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
  

    var webViewLoadFailedVcObj:webViewLoadFailedVc?
    func removeWebViewLoadFailedView(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                webViewLoadFailedVcObj?.view.removeFromSuperview()
            }
        }
    }
   
    func handleLoadError(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                webViewLoadFailedVcObj?.reloadData()
                return;
            }
        }
        webViewLoadFailedVcObj = getWebViewLoadFailedVcObject()
        webViewLoadFailedVcObj!.customDelegate = self
        webViewLoadFailedVcObj?.webView = webView
        webView.addSubview(webViewLoadFailedVcObj!.view)
        webView.addConstraints(subView: webViewLoadFailedVcObj!.view)
        webViewLoadFailedVcObj?.reloadData()
    }

    func reloadClicked(webView:WKWebView) {
        loadWebView()
    }
    
    func setAccessTokenToWebView(){
        let theme = getWindowTheme()
        
        let flags = "[\"migrate-stats-to-motivational-summary\"]"
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\",\"font\":\"\(selectedFont)\",\"lang\":\"\(currentLanguageCode)\",\"theme\":\"\(theme)\",\"motivation_type\":\"desktop\",\"flags\":\(flags)}"
        
//        let javascript = "loadAccessTokenForInspirationPage(\(stringJson));"
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadAccessTokenForInspirationPage) { loadAccessTokenForInspirationPage(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }

    var currentRatingCount = 0
    func updateStarRatingView(){
        btnStarFirst.image = NSImage(named: "star_Gray")
        btnStarSecond.image = NSImage(named: "star_Gray")
        btnStarThird.image = NSImage(named: "star_Gray")
        btnStarFourth.image = NSImage(named: "star_Gray")
        btnStarFifth.image = NSImage(named: "star_Gray")
        
//        if currentRatingCount == 0{
//            btnMain.isEnabled = false
//            btnSkipHabit.isEnabled = false
//        }else{
//            btnMain.isEnabled = true
//            btnSkipHabit.isEnabled = true
//        }
        if currentRatingCount == 1{
            btnStarFirst.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 2{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 3{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 4{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
            btnStarFourth.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 5{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
            btnStarFourth.image = NSImage(named: "star_Golden")
            btnStarFifth.image = NSImage(named: "star_Golden")
        }
    }
    
    func startTimer(){
        currentRatingCount = 0
        updateStarRatingView()
        textFieldRating.stringValue = ""
        btnSkipTimer.isHidden = true
        if currentState == ._MORNING_HABIT_{
            if arrFilteredMorningHabits.count != 0 {
                let time = arrFilteredMorningHabits[0].durationSeconds!
                btnMain.title = getstartActivityButtonText(seconds: time, name: arrFilteredMorningHabits[0].name!)
            }
        }else if currentState == ._EVENING_HABIT_{
            if arrFilteredEveningHabits.count != 0 {
                let time = arrFilteredEveningHabits[0].durationSeconds!
                btnMain.title = getstartActivityButtonText(seconds: time, name: arrFilteredEveningHabits[0].name!)
            }
        }else if currentState == ._CUSTOM_ROUTINE_{
            let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
            if arrHabits.count != 0 {
                let time = arrHabits[0].durationSeconds!
                btnMain.title = getstartActivityButtonText(seconds: time, name: arrHabits[0].name!)
            }
        }
        
        if !isMotivationalMessageShowing{
            if SettingsManagerObject.isMotivationalMessageEnabled{
                allApiObject.isInternetOn(completionHandler: {isInternetOn in
                    DispatchQueue.main.async {
                        if isInternetOn{
                            self.showWebView()
                        }else{
                            self.startTimer(duration: 30)
                        }
                    }
                })
            }else{
                startTimer(duration: 30)
            }
        }
        
        // after screen shows if webview is not lodded show star rating after 2 seconds
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { timer in
            self.boxStarRating.isHidden = false
        }
    }
    func tryPreLoadMotivationalMessage(){
        self.isMotivationalMessageShowing = false
        self.imgView.isHidden = false
        webView.isHidden = true
        btnMain.isHidden = true
        btnSkipHabit.isHidden = true
        lblTimer.stringValue = ""
        lblVisualizeText.isHidden = false
        if SettingsManagerObject.isMotivationalMessageEnabled{
            allApiObject.isInternetOn(completionHandler: {isInternetOn in
                DispatchQueue.main.async {
                    if isInternetOn{
                        self.showWebView()
                    }
                }
            })
        }
    }
    func showWebView(){
        isMotivationalMessageShowing = true
        self.boxStarRating.isHidden = true
        self.imgView.isHidden = true
        self.timer?.invalidate()
        self.btnMain.isHidden = false
        self.btnSkipHabit.isHidden = false
        self.btnSkipTimer.isHidden = true
        self.lblTimer.isHidden = true
        self.isTimerGoingOn = false
        lblTimer.stringValue = ""
        webView.isHidden = true
        lblVisualizeText.isHidden = true
        loadWebView()
        self.btnMain.title = self.arrOptions.randomElement() ?? ""
    }
    
    func loadWebView(){
        let url = "http://dashboard.focusbear.io/webview/motivational-summary?bust_cache=\(getUuid())"
        let link = URL(string:url)!
        let request = URLRequest(url: link)
        self.webView.load(request)
        loader.startAnimation(self)
    }
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0
    
    func startTimer(duration:Int) {
        btnSkipTimer.isHidden = false
        self.imgView.isHidden = false
        webView.isHidden = true
        btnMain.isHidden = true
        btnSkipHabit.isHidden = true
        lblTimer.stringValue = ""
        lblVisualizeText.isHidden = false
        
        isMotivationalMessageShowing = false
        if isTimerGoingOn{
            btnMain.isHidden = true
            lblTimer.isHidden = false
            btnSkipHabit.isHidden = true
            return
        }
        btnMain.isHidden = true
        btnSkipHabit.isHidden = true
        lblTimer.isHidden = false
        isTimerGoingOn = true
        currentTimer = 0
        totalDuration = duration
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
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lblTimer.isHidden = false
            self.lblTimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            
            self.timer?.invalidate()
            DispatchQueue.main.async {
                self.btnSkipTimer.isHidden = true
                playEveryActivitySound()
                self.btnMain.isHidden = false
                self.btnSkipHabit.isHidden = false
                self.lblTimer.isHidden = true
                self.isTimerGoingOn = false
                
                if currentState == ._MORNING_HABIT_{
                    if arrFilteredMorningHabits.count != 0 {
                        let time = arrFilteredMorningHabits[0].durationSeconds!
                        self.btnMain.title = getstartActivityButtonText(seconds: time, name: arrFilteredMorningHabits[0].name!)

                    }
                }else if currentState == ._EVENING_HABIT_{
                    if arrFilteredEveningHabits.count != 0 {
                        if isHighPrioritySequenceGoing{
                            for i in 0..<arrFilteredEveningHabits.count{
                                if arrFilteredEveningHabits[i].isPriorityHigh{
                                    if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                                        let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                        let currentDate = Date()
                                        if currentDate > cutOffDate{
                                            addLog(text: "evening habit skipped:- this next habit is high priority habit but cutoff time of this habit has passed:- \(arrFilteredEveningHabits[i].name)  \(arrFilteredEveningHabits[i].id)") // remove this
                                            continue;
                                        }
                                    }
                                    let time = arrFilteredEveningHabits[i].durationSeconds!
                                    self.btnMain.title = getstartActivityButtonText(seconds: time, name: arrFilteredEveningHabits[i].name!)
                                    break;
                                    
                                }
                            } 
                        }else{
                            let time = arrFilteredEveningHabits[0].durationSeconds!
                            self.btnMain.title = getstartActivityButtonText(seconds: time, name: arrFilteredEveningHabits[0].name!)
                        }
                        

                    }
                }else if currentState == ._CUSTOM_ROUTINE_{
                    let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
                    if arrHabits.count != 0 {
                        let time = arrHabits[0].durationSeconds!
                        self.btnMain.title = getstartActivityButtonText(seconds: time, name: arrHabits[0].name!)

                    }
                }
                
                if self.webView.isHidden == false{
                    self.btnMain.title = self.arrOptions.randomElement() ?? ""
                }
            }
        }
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        addLog(text:"[user-action] visualizeInstructionsVc - btnMainClicked :- \(btnMain.title)")
        if currentState == ._MORNING_HABIT_{
            allApiObject.capturePosthog(event: "routine-motivation-level", metadata: ["routine-type":"morning_routine", "motivation-level":currentRatingCount, "motivation-comments":textFieldRating.stringValue])
            getHabitsVcObject().startFirstMorningHabit()
        }else if currentState == ._EVENING_HABIT_{
            allApiObject.capturePosthog(event: "routine-motivation-level", metadata: ["routine-type":"evening_routine", "motivation-level":currentRatingCount, "motivation-comments":textFieldRating.stringValue])
            getHabitsVcObject().startFirstEveningHabit()
        }else if currentState == ._CUSTOM_ROUTINE_{
            allApiObject.capturePosthog(event: "routine-motivation-level", metadata: ["routine-type":"custom_routine", "motivation-level":currentRatingCount, "motivation-comments":textFieldRating.stringValue])
            getHabitsVcObject().startFirstCustomRoutineHabit()
        }
        if self.webView.isHidden == false{
            let link = URL(string:"about:blank")!
            let request = URLRequest(url: link)
            self.webView.load(request)
        }
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text:"[user-action] visualizeInstructionsVc - btnSkipClicked :- \(btnSkipHabit.title)")
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        thirdVcObj?.menuItemSkipHabitClicked()
    }
    @IBAction func btnSkipTimerClicked(_ sender: Any) {
        currentTimer = totalDuration
        performTimerCount()
    }
    
    @IBAction func btnStarFirstClicked(_ sender: Any) {
        currentRatingCount = 1
        updateStarRatingView()
    }
    
    @IBAction func btnStarSecondClicked(_ sender: Any) {
        currentRatingCount = 2
        updateStarRatingView()
    }
    
    @IBAction func btnStarThirdClicked(_ sender: Any) {
        currentRatingCount = 3
        updateStarRatingView()
    }
    
    @IBAction func btnStarFourthClicked(_ sender: Any) {
        currentRatingCount = 4
        updateStarRatingView()
    }
    
    @IBAction func btnStarFifthClicked(_ sender: Any) {
        currentRatingCount = 5
        updateStarRatingView()
    }
    
}
