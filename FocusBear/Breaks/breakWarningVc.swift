//
//  breakWarningVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

class breakWarningVc: NSViewController {

    // SwiftUI conversion (#1590): the storyboard view is covered by a SwiftUI popup
    // driven by this view-model. The legacy outlets remain (storyboard-connected) but
    // are not shown; all presentation now flows through `breakViewModel`.
    let breakViewModel = BreakWarningViewModel()
    private var breakHostingView: NSHostingView<BreakWarningView>?
    
    @IBOutlet weak var lblTimeSinceLastBreak: NSTextField!
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
        btnSkip.isSecondaryButton = true
        btnPostpone.isSecondaryButton = true

        setupSwiftUIPopup()
    }

    /// Installs the SwiftUI popup over the storyboard view and wires its actions.
    private func setupSwiftUIPopup() {
        // Hide the storyboard buttons so that they cannot be clicked accidentally from the upper view.
        btnPostpone.isHidden = true
        btnStartMicroBreak.isHidden = true
        btnSkip.isHidden = true
        
        breakViewModel.startTitle = btnStartMicroBreak.title
        breakViewModel.skipTitle = btnSkip.title
        breakViewModel.postponeTitle = btnPostpone.title
        breakViewModel.selectMinutesTitle = lblTitleSelectMinutes.stringValue
        breakViewModel.minutesOptions = ["5", "10", "15", "20", "25", "30", "45", "60", "90"]
        
        breakViewModel.onStartBreak = { [weak self] in self?.startBreakNow() }
        breakViewModel.onSkip = { [weak self] in self?.skipBreak() }
        breakViewModel.onPostpone = { [weak self] in self?.postponeBreak() }
        // Pause the auto-start countdown while the user holds to postpone, so it can't
        // fire mid-hold; resume if they release without completing.
        breakViewModel.onPostponePressing = { [weak self] pressing in
            if pressing { self?.pauseCountdown() } else { self?.resumeCountdown() }
        }
        
        let hosting = NSHostingView(rootView: BreakWarningView(model: breakViewModel))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        breakHostingView = hosting
        // The storyboard pins the box to a fixed (narrower) width; deactivate it so the
        // window matches the SwiftUI card width — otherwise the card overflows and its
        // padding gets clipped.
        boxWidth?.isActive = false
        view.layoutSubtreeIfNeeded()
        // Size the popup to the SwiftUI content so the window frames it correctly.
        let fitting = hosting.fittingSize
        if fitting.width > 0, fitting.height > 0 {
            view.setFrameSize(fitting)
        }
    }

    override func viewWillDisappear() {
        if transparentWcObj != nil{
            transparentWcObj?.window?.close()
        }
    }
    
    func reloadTimeSinceLastBreak(){
        if let lastBreakTimeText = getTimeSinceLastBreak(){
            lblTimeSinceLastBreak.stringValue = lastBreakTimeText
            lblTimeSinceLastBreak.isHidden = false
            breakViewModel.timeSinceLastBreak = lastBreakTimeText
            breakViewModel.showTimeSinceLastBreak = true
        }else{
            lblTimeSinceLastBreak.isHidden = true
            breakViewModel.showTimeSinceLastBreak = false
        }
        breakViewModel.urgency = currentBreakUrgency()
    }

    /// 0…1 escalation based on how long since the last meaningful break (red by ~3h).
    private func currentBreakUrgency() -> Double {
        guard let lastEnd = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakEndTime) as? Date else { return 0 }
        let hours = Date().timeIntervalSince(lastEnd) / 3600.0
        return max(0, min(1, hours / 3.0))
    }
    
    func resetView(){
        var totalDuration = 0
        for activity in arrFinalBreakActivities{
            if activity.activity.useTimer{
                totalDuration += activity.activity.durationSeconds
            }
        }
        reloadTimeSinceLastBreak()

        popupButtonMinutes.selectItem(at: defaultSelectedIndex)
        progressBar.isHidden = false
        isPostponing = false

        // Escalating postpone friction (#1590): hold gets longer with each consecutive
        // postpone (5s → 10s → 15s, capped). Easy-skip users get a plain tap (0s).
        breakViewModel.selectedMinutes = popupButtonMinutes.title
        if SettingsManagerObject.isEasySkipEnabled {
            breakViewModel.requiredHoldSeconds = 0
        } else {
            // Starts at 5s for a fresh break, escalates 5→10→15 per consecutive postpone.
            breakViewModel.requiredHoldSeconds = Double(min(15, 5 * (breakPostponeHoldCount + 1)))
        }
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
                breakViewModel.quote = quote + " - " + attribution
            }
            
            
//            btnPostpone.title = breakWarningVcInfo.value(forKey: "buttonPostponeText") as? String ?? btnPostpone.title
        }
        
        lblTitle.stringValue = title.replacingOccurrences(of: "<DURATION>", with: "\(totalDuration)")
        breakViewModel.title = lblTitle.stringValue
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
        breakViewModel.timerText = self.lblTimer.stringValue
        breakViewModel.countdownProgress = 1

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
            self.breakViewModel.timerText = self.lblTimer.stringValue
            if self.totalDuration > 0 {
                self.breakViewModel.countdownProgress = Double(remainingSeconds) / Double(self.totalDuration)
            }

            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
                transparentWcObj?.window?.close()
                if self.isPostponing{
                    getHabitsVcObject().postponeBreakActivitiesFor(minutes: Int(self.popupButtonMinutes.title) ?? 5, secondsToPostpone: nil, isFromBreakWarningWindow: true)
                    postponeBreaksFromBreaksWarningCount += 1
                    if postponeBreaksFromBreaksWarningCount >= 2{
                        postponeBreaksFromBreaksWarningCount = 0
                        showDeactivateBreaksWindow()
                    }
                }else{
                    if currentState == ._MICRO_BREAK_{// whenever show waring then make current state _MICRO_BREAK_ beacuse if any thing will happen during waring curent state will change (ex. app can bhi in shutoff state when warning is about to over in this case we will not execute break activity)
                        allApiObject.capturePosthog(event: "break-warning-started-after-30-seconds-delay", metadata: [:])
                        breakPostponeHoldCount = 0   // taking the break resets the escalating hold time
                        getHabitsVcObject().performBreakActivities()
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
    
    // Storyboard actions (the buttons are covered by the SwiftUI popup, but the
    // outlets/actions stay connected). All real flow goes through the private handlers
    // below, which are also invoked by the SwiftUI view's callbacks.
    @IBAction func btnStartMicroBreakClicked(_ sender: Any) { startBreakNow() }
    @IBAction func btnSkipClicked(_ sender: Any) { skipBreak() }
    @IBAction func btnPostponeClicked(_ sender: Any) { postponeBreak() }

    private func startBreakNow() {
        self.timer?.invalidate()
        self.view.window?.close()
        transparentWcObj?.window?.close()
        breakPostponeHoldCount = 0   // taking a break resets the escalating hold time
        if currentState == ._MICRO_BREAK_{
            allApiObject.capturePosthog(event: "break-warning-user-started-early", metadata: [:])
            getHabitsVcObject().performBreakActivities()
        }
    }

    /// Pause/resume the auto-start countdown (used while the user holds to postpone).
    private func pauseCountdown() {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func resumeCountdown() {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
        }
    }

    private func skipBreak() {
        addLog(text: "[user-action] breakWarningVc - Skip Break Activities Completely Clicked")
        allApiObject.capturePosthog(event: "skip-breaks-from-warning", metadata: [:])
        self.timer?.invalidate()
        self.view.window?.close()
        getHabitsVcObject().postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil, isFromBreakWarningWindow: true)
    }

    /// Called when the user completes the press-and-hold on the postpone control
    /// (#1590). The hold itself is the friction (escalating duration), so this just
    /// performs the postpone.
    private func postponeBreak() {
        addLog(text: "[user-action]breakWarningVc:- postpone hold completed (hold \(Int(breakViewModel.requiredHoldSeconds))s, count \(activityPostponeCount))")
        allApiObject.capturePosthog(event: "postpone-breaks-from-warning", metadata: ["hold_seconds": Int(breakViewModel.requiredHoldSeconds), "postpone_count": activityPostponeCount])
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()
        transparentWcObj?.window?.close()
        activityPostponeCount += 1
        breakPostponeHoldCount += 1   // next break popup requires a longer hold
        getHabitsVcObject().postponeBreakActivitiesFor(minutes: Int(breakViewModel.selectedMinutes) ?? 5, secondsToPostpone: nil, isFromBreakWarningWindow: true)
        postponeBreaksFromBreaksWarningCount += 1
        if postponeBreaksFromBreaksWarningCount >= 2{
            postponeBreaksFromBreaksWarningCount = 0
            showDeactivateBreaksWindow()
        }
    }
}

