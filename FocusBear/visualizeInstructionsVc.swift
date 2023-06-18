//
//  visualizeInstructions.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class visualizeInstructionsVc: NSViewController, WKNavigationDelegate {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var btnSkipHabit: underLineButton!
    @IBOutlet weak var btnMain: Button!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblVisualizeText: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
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
        lblTitle.stringValue = "Get Focused"
        lblVisualizeText.stringValue = "Before you begin your morning routine, take 30 seconds to engage in \"extrapersonal focus\": try your best to keep your eyes fixed on the target. Research from Balcetis and colleagues in 2020 indicates that concentrating on a visual point will sharpen your focus and increase the likelihood of completing your routine."
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            lblVisualizeText.stringValue = activityInfo.value(forKey: "visualizeDescriptionText") as? String ?? lblVisualizeText.stringValue
            lblTitle.stringValue = activityInfo.value(forKey: "titleGetFocused") as? String ?? lblTitle.stringValue
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
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.setAccessTokenToWebView()
                self.loader.stopAnimation(self)
                self.webView.isHidden = false
            }
        }
    }
   

    func setAccessTokenToWebView(){
        let stringJson1 = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\"}"
        
        let javascript = "loadAccessTokenForInspirationPage(\(stringJson1));"
        
        webView.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }
    func startTimer(){
        self.imgView.isHidden = false
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
        }
        
        webView.isHidden = true
        btnMain.isHidden = true
        btnSkipHabit.isHidden = true
        lblTimer.stringValue = ""
        lblVisualizeText.isHidden = false
        
        
        
        
        if SettingsManagerObject.isMotivationalMessageEnabled{
            if Reachability.isConnectedToNetwork() == false{
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
                showWebView()
            }
        }else{
            startTimer(duration: 30)
        }
        
    }

    func showWebView(){
        //
        self.imgView.isHidden = true
        self.timer?.invalidate()
        self.btnMain.isHidden = false
        self.btnSkipHabit.isHidden = false
        self.lblTimer.isHidden = true
        self.isTimerGoingOn = false
        lblTimer.stringValue = ""
        webView.isHidden = true
        lblVisualizeText.isHidden = true
        let url = "http://dashboard.focusbear.io/webview/motivational-summary"
        let link = URL(string:url)!
        let request = URLRequest(url: link)
        self.webView.load(request)
        self.btnMain.title = self.arrOptions.randomElement() ?? ""
        loader.startAnimation(self)
    }
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0
    
    func startTimer(duration:Int) {
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
        currentTimer += 1// todo 1 kro
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
                }
                
                if self.webView.isHidden == false{
                    self.btnMain.title = self.arrOptions.randomElement() ?? ""
                }
            }
        }
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        addLog(text:"visualizeInstructionsVc - btnMainClicked :- \(btnMain.title)")
        if currentState == ._MORNING_HABIT_{
            mainViewControllerObj?.startFirstMorningHabit()
        }else{
            mainViewControllerObj?.startFirstEveningHabit()
        }
        if self.webView.isHidden == false{
            let link = URL(string:"about:blank")!
            let request = URLRequest(url: link)
            self.webView.load(request)
        }
    }
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text:"visualizeInstructionsVc - btnSkipClicked :- \(btnSkipHabit.title)")
        thirdVcObj?.loadView()
        thirdVcObj?.btnSkipHabitClicked(self)
    }
}
