//
//  breakWarningVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class breakWarningVc: NSViewController {

    @IBOutlet weak var btnSkip: Button!
    @IBOutlet weak var btnStartMicroBreak: Button!
    @IBOutlet weak var boxWidth: NSLayoutConstraint!
    @IBOutlet weak var popupButtonMinutes: NSPopUpButton!
    @IBOutlet weak var lblTitleSelectMinutes: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var btnPostpone: Button!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var isPostponing = false
    var defaultSelectedIndex = 4
    var arrayQuote:[[String:String]] = [
        [
            "attribution": "Alan Cohen",
            "quote": "There is virtue in work and there is virtue in rest. Use both and overlook neither."
        ],
        [
            "attribution": "Cynthia Mendenhall",
            "quote": "No matter how strong or strong-willed you are, you cannot live a stressful, maxed-out life without that pace eventually biting you in the butt. It is necessary to take breaks, set parameters, and be kind to yourself if you want to continue making an impact in your little corner of the world."
        ],
        [
            "attribution": "Helen Edwards",
            "quote": "In this game, everyone needs a break to refuel, recharge, and jump back in full throttle."
        ],
        [
            "attribution": "Louisa May Alcott",
            "quote": "Have regular hours for work and play; make each day both useful and pleasant, and prove that you understand the worth of time by employing it well."
        ],
        [
            "attribution": "Catherine Pulsifer",
            "quote": "Sometimes we just need a mental vacation. Take a 15-minute break and start planning your next vacation."
        ],
        [
            "attribution": "Emily Griffin",
            "quote": "I think it's important to try to be present with whatever it is you're doing. And if you can't be present, take a break."
        ],
        [
            "attribution": "May Sarton",
            "quote": "The most valuable thing we can do for the psyche, occasionally, is to let it rest, wander, live in the changing light of room, not try to be or do anything whatever."
        ],
        [
            "attribution": "Sall Clarkson",
            "quote": "Managing our stress and our rest is a sign of living wisely. Refueling as a way to find joy, to create pleasure, and to celebrate life in the midst of all its demands fills our hearts with renewed hope. When we take the time to breathe, listen, and rest from the daily grind to see miracles bubbling up in our lives."
        ],
        [
            "attribution": "Izey Victoria Odiase",
            "quote": "Relax, Recharge and Reflect. Sometimes it’s OK to do nothing."
        ],
        [
            "attribution": "Anne Lamott",
            "quote": "Almost everything will work again if you unplug it for a few minutes, including you."
        ],
        [
            "attribution": "Oprah Winfrey",
            "quote": "Breathe. Let go. And remind yourself that this very moment is the only one you know you have for sure."
        ],
        [
            "attribution": "Harper Reed",
            "quote": "The opportunity to step away from everything and take a break is something that shouldn’t be squandered."
        ],
        [
            "attribution": "Sri Sri Ravi Shankar",
            "quote": "Wisdom is knowing when to have rest, when to have activity, and how much of each to have."
        ],
        [
            "attribution": "Anne Lamott",
            "quote": "When you rest, you catch your breath and it holds you up, like water wings…"
        ],
        [
            "attribution": "Pico Iyer",
            "quote": "It’s precisely those who are busiest who most need to give themselves a break."
        ],
        [
            "attribution": "Banksy",
            "quote": "If you get tired, learn to rest, not to quit."
        ],
        [
            "attribution": "Bryant McGill",
            "quote": "Your calm mind is the ultimate weapon against your challenges."
        ],
        [
            "attribution": "Jennifer Williamson",
            "quote": "Real rest feels like every cell is thanking you for taking care of you. It’s calm, not full of checklists and chores. It’s simple: not multitasking; not fixing broken things."
        ],
        [
            "attribution": "Akiroq Brost",
            "quote": "Do something nice for yourself today. Find some quiet, sit in stillness, breathe. Put your problems on pause. You deserve a break."
        ],
        [
            "attribution": "Lailah Gifty Akita",
            "quote": "Try to pause each day and take a walk to view nature."
        ],
        [
            "attribution": "Russell Eric Dobda",
            "quote": "Taking a break can lead to breakthroughs."
        ],
        [
            "attribution": "Giridhar Alwar",
            "quote": "When things are not happening as planned just stop worrying and take an unplanned break to regain yourself."
        ],
        [
            "attribution": "Hiral Nagda",
            "quote": "Sometimes doing nothing makes way for everything."
        ],
        [
            "attribution": "Hiral Nagda",
            "quote": "Don't underestimate the power of resting. It builds you back unlike anything."
        ],
        [
            "attribution": "Rodolfo Peon",
            "quote": "For those of us who live in a sunny and hot desert, a cloudy day is sometimes all we need to clear our minds..."
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnSkip.title = "Skip"
        btnPostpone.title = "Postpone"
        btnStartMicroBreak.title = "Start micro break now"
        lblTitleSelectMinutes.stringValue = "Select minutes to postpone:"
        
        popupButtonMinutes.removeAllItems()
        popupButtonMinutes.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "60", "90"])
        
        lblDescription.stringValue = "Micro breaks help keep your energy + alertness levels consistent throughout the day and have positive impacts on your posture (no more screen headaches)."
        if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
            lblDescription.stringValue = breakWarningVcInfo.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            btnStartMicroBreak.title = breakWarningVcInfo.value(forKey: "buttonStartBreakNowText") as? String ?? btnStartMicroBreak.title
            btnSkip.title = breakWarningVcInfo.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
            btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonPostponeNewText") as? String ?? btnPostpone.title
        }
        
        if let easyPostponeVcInfo = configjson.value(forKey: "easyPostponeVcInfo") as? NSDictionary{
            lblTitleSelectMinutes.stringValue = easyPostponeVcInfo.value(forKey: "titleSelectMinutes") as? String ?? lblTitleSelectMinutes.stringValue
        }
        if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
            boxWidth.constant = 350
        }else{
            boxWidth.constant = 300
        }
        btnSkip.buttonColor = NSColor.white.cgColor
        btnPostpone.buttonColor = NSColor.white.cgColor
    }
    override func viewWillDisappear() {
        if transparentWcObj != nil{
            transparentWcObj?.window?.close()
        }
    }
    func resetView(){
        var totalDuration = 0
        for activity in arrFinalBreakActivities{
            if activity.activity.useTimer{
                totalDuration += activity.activity.durationSeconds
            }
        }
        popupButtonMinutes.selectItem(at: defaultSelectedIndex)
        progressBar.isHidden = false
        isPostponing = false
        var title = "Your <DURATION> seconds micro break starts in"
        btnPostpone.title = "Postpone"
        if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
            btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonPostponeNewText") as? String ?? btnPostpone.title
        }
        startTimer(durationSeconds: 30)
        setProgres()
        
        if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
            if isBreakActivityShowingWhileMeeting{
                title = "Your <DURATION> seconds mid meeting break starts in"
//                lblDescription.stringValue = "Micro breaks can help you stay focused in meetings."

                title = breakWarningVcInfo.value(forKey: "titleMeetings") as? String ?? title
//                lblDescription.stringValue = breakWarningVcInfo.value(forKey: "descriptionMeetingsText") as? String ?? lblDescription.stringValue
            }else{
                title = "Your <DURATION> seconds micro break starts in"
//                lblDescription.stringValue = "Micro breaks help keep your energy + alertness levels consistent throughout the day and have positive impacts on your posture (no more screen headaches)."

                title = breakWarningVcInfo.value(forKey: "title") as? String ?? title
//                lblDescription.stringValue = breakWarningVcInfo.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            }
            
            arrayQuote = breakWarningVcInfo.value(forKey: "arrayQuote") as? [[String:String]] ?? arrayQuote
            if let randomElement = arrayQuote.randomElement(){
                let quote = randomElement["quote"] ?? ""
                let attribution = randomElement["attribution"] ?? ""
                lblDescription.stringValue = quote + " - " + attribution
            }
            
            
//            btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
        }
        
        lblTitle.stringValue = title.replacingOccurrences(of: "<DURATION>", with: "\(totalDuration)")
        popUpBtnClicked(self)
    }
    func startTimer(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        
        currentTimer = 0
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1 {
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
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func setProgres(){
        let remainingSeconds = self.totalDuration-currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"

        if hour.count == 1 {
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            if !self.isPostponing{
                self.progressBar.doubleValue = Double(remainingSeconds)
                if transparentWcObj != nil{
                    if transparentWcObj!.window?.isVisible ?? false{
                        transparentWcObj?.window?.alphaValue = CGFloat(self.currentTimer) / CGFloat(self.totalDuration)
                    }
                }
            }
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
                transparentWcObj?.window?.close()
                if self.isPostponing{
                    mainViewControllerObj?.postponeBreakActivitiesFor(minutes: Int(self.popupButtonMinutes.title) ?? 5, secondsToPostpone: nil)
                    postponeBreaksFromBreaksWarningCount += 1
                    if postponeBreaksFromBreaksWarningCount >= 2{
                        postponeBreaksFromBreaksWarningCount = 0
                        showDeactivateBreaksWindow()
                    }
                }else{
                    if currentState == ._ACTIVITY_{// whenever show waring then make current state _ACTIVITY_ beacuse if any thing will happen during waring curent state will change (ex. app can bhi in shutoff state when warning is about to over in this case we will not execute break activity)
                        allApiObject.capturePosthog(event: "break-warning-started-after-30-seconds-delay", metadata: [:])
                        mainViewControllerObj?.performBreakActivities()
                    }
                }
            }
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        setProgres()
    }
    
    @IBAction func popUpBtnClicked(_ sender: Any) {
//        btnPostpone.title = "Postpone for 5 minutes"
//        let duration = Int(popupButtonMinutes.title) ?? 5
//        if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
//            let title = breakWarningVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
//            btnPostpone.title = title.replacingOccurrences(of: "5", with: "\(duration)")
//        }
    }
    
    @IBAction func btnStartMicroBreakClicked(_ sender: Any) {
        self.timer?.invalidate()
        self.view.window?.close()
        transparentWcObj?.window?.close()
        if currentState == ._ACTIVITY_{// whenever show waring then make current state _ACTIVITY_ beacuse if any thing will happen during waring curent state will change (ex. app can bhi in shutoff state when warning is about to over in this case we will not execute break activity)
            allApiObject.capturePosthog(event: "break-warning-user-started-early", metadata: [:])
            mainViewControllerObj?.performBreakActivities()
        }
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] breakWarningVc - Skip Break Activities Completely Clicked")
        allApiObject.capturePosthog(event: "skip-breaks-from-warning", metadata: [:])
        self.timer?.invalidate()
        self.view.window?.close()
        mainViewControllerObj?.postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil)
    }
    @IBAction func btnPostponeClicked(_ sender: Any) {
        if isPostponing{
            addLog(text: "[user-action]breakWarningVc:- btn take break clicked")
            self.timer?.invalidate()
            self.view.window?.close()
            if currentState == ._ACTIVITY_{// whenever show waring then make current state _ACTIVITY_ beacuse if any thing will happen during waring curent state will change (ex. app can bhi in shutoff state when warning is about to over in this case we will not execute break activity)
                mainViewControllerObj?.performBreakActivities()
            }
            
        }else{
            addLog(text: "[user-action]breakWarningVc:- btn Postpone clicked")
            if activityPostponeCount > 0 && !SettingsManagerObject.isEasySkipEnabled{
                addLog(text: "breakWarningVc:- btn Postpone timer begin")
                isPostponing = true
                self.timer?.invalidate()
                lblTitle.stringValue = "You postponed the last break - are you sure you can't make time for The break now?"
                btnPostpone.title = "Argh ok I'll take a break!"
                progressBar.isHidden = true
                startTimer(durationSeconds: 15)
                if let breakWarningVcInfo = configjson.value(forKey: "breakWarningVcInfo") as? NSDictionary{
                    lblTitle.stringValue = breakWarningVcInfo.value(forKey: "postponeConfirmText") as? String ?? lblTitle.stringValue
                    btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonTakeBreakText") as? String ?? btnPostpone.title
                }
                if transparentWcObj != nil{
                    transparentWcObj?.window?.close()
                }
            }else{
                allApiObject.capturePosthog(event: "postpone-breaks-from-warning", metadata: [:])
                self.timer?.invalidate()
                self.view.window?.close()
                activityPostponeCount += 1
                mainViewControllerObj?.postponeBreakActivitiesFor(minutes: Int(popupButtonMinutes.title) ?? 5, secondsToPostpone: nil)
                postponeBreaksFromBreaksWarningCount += 1
                if postponeBreaksFromBreaksWarningCount >= 2{
                    postponeBreaksFromBreaksWarningCount = 0
                    showDeactivateBreaksWindow()
                }
            }
        }
    }
}

