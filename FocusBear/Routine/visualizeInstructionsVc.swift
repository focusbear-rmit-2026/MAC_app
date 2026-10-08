//
//  visualizeInstructions.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.

import Cocoa
import SwiftUI
import Combine

/// Routine-start screen: countdown / visual-focus prompt, star rating, and the Stats screen opened on
/// its Pep Talk tab. The pep talk used to be the dashboard.focusbear.io/webview/motivational-summary
/// webview (token bridge + load-failed overlay); the native StatsScreen now streams
/// /user/motivational-summary and gives the other stats tabs a look while the routine is pending.
/// How often the routine's pep talk should appear.
///
/// It lives on the "visualize" screen, which is shown for EVERY habit — so completing a habit and
/// coming back brought it round again. On one day 15 of 26 pep-talk requests were immediately
/// preceded by "Showing morning/evening habits from habit completed back button". The intended
/// behaviour is once per routine start per day: once in the morning, once in the evening
/// (report 2026-09-22_07-45-26, follow-up: "How could it be 26 times?").
///
/// Keyed by routine AND day, so postponing and resuming the morning routine does not earn a second
/// one, while the evening routine still gets its own.
enum PepTalkRoutineDisplay {

    static func shouldShow(routine: CURRENTSTATE,
                           now: Date = Date(),
                           lastShown: [CURRENTSTATE: Date],
                           calendar: Calendar = .current) -> Bool {
        guard let shown = lastShown[routine] else { return true }
        return !calendar.isDate(shown, inSameDayAs: now)
    }

    static func recording(_ routine: CURRENTSTATE,
                          at now: Date = Date(),
                          into lastShown: [CURRENTSTATE: Date]) -> [CURRENTSTATE: Date] {
        var updated = lastShown
        updated[routine] = now
        return updated
    }
}

/// Per-routine, per-day record of when the pep talk was last shown. A global because the screen it
/// lives on is rebuilt for every habit — instance state cannot outlive the thing being limited.
var pepTalkLastShownByRoutine: [CURRENTSTATE: Date] = [:]

class visualizeInstructionsVc: NSViewController {

    @IBOutlet weak var boxStarRating: NSBox!
    @IBOutlet weak var stackViewStarRating: NSStackView!
    @IBOutlet weak var btnSkipTimer: underLineButton!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var loader: NSProgressIndicator!
    /// The container the WKWebView used to fill; hosts the StatsScreen (Pep Talk tab first).
    @IBOutlet weak var pepTalkContainer: NSView!
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
    /// Created when the pep talk is shown and torn down when the screen hides, so each routine start
    /// opens one fresh Stats screen (one SSE stream) rather than piling up streams and loaded tabs.
    private var statsStore: StatsStore?
    private var statsHostingView: NSView?
    private var pepTalkObservers = Set<AnyCancellable>()
    private var isPepTalkVisible: Bool { !pepTalkContainer.isHidden }
    
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
        pepTalkContainer.isHidden = true
        
        if let inspirations = configjson.value(forKey: "inspirations") as? [String]{
            arrOptions = inspirations
        }
        btnSkipTimer.title = "Skip"
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            btnSkipTimer.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkipTimer.title
        }
        textFieldRating.placeholderString = "What is motivating you to do your habits today?"
    }
    
    override func viewWillDisappear() {
        isMotivationalMessageShowing = false
        tearDownStatsScreen()
    }

    /// A fresh Stats screen on the Pep Talk tab, filling the old webview container. `screenAppeared()`
    /// starts the pep talk stream (the Pep Talk tab loads on selection, as in the Stats tool); the other
    /// tabs load when the user visits them.
    private func showStatsScreen() {
        tearDownStatsScreen()
        let store = StatsStore(strings: StatsStrings.load(), initialTab: .pepTalk)
        let hosting = NSHostingView(rootView: StatsScreen(store: store))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // Let the container's size win over the hosted content's ideal size (see setUpVc): the tabs
        // scroll inside the container instead of pushing the Start button off the screen.
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.setContentCompressionResistancePriority(.init(1), for: .vertical)
        hosting.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        hosting.setContentHuggingPriority(.init(1), for: .vertical)
        hosting.setContentHuggingPriority(.init(1), for: .horizontal)
        pepTalkContainer.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: pepTalkContainer.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: pepTalkContainer.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: pepTalkContainer.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: pepTalkContainer.bottomAnchor),
        ])
        // The storyboard spinner sits over the container: spin until the first streamed chunk lands.
        store.pepTalk.$isStreaming.combineLatest(store.pepTalk.$text)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isStreaming, text in
                guard let self = self else { return }
                if isStreaming && text.isEmpty { self.loader.startAnimation(self) } else { self.loader.stopAnimation(self) }
            }
            .store(in: &pepTalkObservers)
        statsStore = store
        statsHostingView = hosting
        store.screenAppeared()
    }

    private func tearDownStatsScreen() {
        pepTalkObservers = []
        loader.stopAnimation(self)
        statsStore?.screenDisappeared()
        statsStore = nil
        statsHostingView?.removeFromSuperview()
        statsHostingView = nil
    }

    var currentRatingCount = 0
    func updateStarRatingView(){
        btnStarFirst.image = NSImage(named: "star_Gray")
        btnStarSecond.image = NSImage(named: "star_Gray")
        btnStarThird.image = NSImage(named: "star_Gray")
        btnStarFourth.image = NSImage(named: "star_Gray")
        btnStarFifth.image = NSImage(named: "star_Gray")

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
            // #2617: the VISIBLE visualize screen is already shown at most once per routine per day — its
            // caller (firstViewController) only reaches here when RoutineVisualizePrompt.shouldShow(for:)
            // is true and calls markShown(for:) immediately after. So the pep talk on this visible path
            // must NOT add its own PepTalkRoutineDisplay once-per-day check: doing so created a race where
            // the background pre-load could record the slot first (even into a detached, never-seen view)
            // and then deny this visible screen its pep talk, leaving the plain 30-second target. When the
            // screen shows, the pep talk shows. (The PRE-LOAD keeps PepTalkRoutineDisplay to throttle its
            // own streaming; only the once-a-day visible screen is unconditional here.)
            if SettingsManagerObject.isMotivationalMessageEnabled {
                allApiObject.isInternetOn(completionHandler: {isInternetOn in
                    DispatchQueue.main.async {
                        if isInternetOn{
                            self.showPepTalk()
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
        pepTalkContainer.isHidden = true
        btnMain.isHidden = true
        btnSkipHabit.isHidden = true
        lblTimer.stringValue = ""
        lblVisualizeText.isHidden = false
        // The pre-load path has to ask the same question, or it reintroduces the per-habit pep talk
        // through the back door.
        //
        // #2617: it must ALSO honour shouldIgnoreVisualizeInstructions. Returning from a completed habit
        // sets that flag true and re-runs the morning/evening setup — which calls this pre-load — while
        // the *visible* visualize screen is deliberately skipped (firstViewController gates it on the
        // same flag). Without this guard the pre-load still ran, calling showPepTalk() on a screen that
        // never becomes visible: it streamed into a detached view AND recorded the once-per-day slot, so
        // the real routine-start visualize screen was then denied the pep talk and fell through to the
        // 30-second target. Don't pre-load (or consume the slot) when the screen won't be shown.
        if firstViewControllerObj?.shouldIgnoreVisualizeInstructions == true { return }
        // Nor when this routine's visualize screen has already had today's showing, so it will not appear
        // again. `pepTalkLastShownByRoutine` below is in memory, so after a relaunch into such a routine
        // the pre-load streamed a pep talk nobody could see (2026-09-24 19:46). The screen's own record is
        // persisted, and it is the one that decides whether the screen shows at all.
        if let routine = RoutineVisualizePrompt.Routine.current(state: currentState, customRoutineIndex: currentRoutineIndex),
           !RoutineVisualizePrompt.shouldShow(for: routine) { return }
        if SettingsManagerObject.isMotivationalMessageEnabled,
           PepTalkRoutineDisplay.shouldShow(routine: currentState, lastShown: pepTalkLastShownByRoutine) {
            allApiObject.isInternetOn(completionHandler: {isInternetOn in
                DispatchQueue.main.async {
                    if isInternetOn{
                        self.showPepTalk()
                    }
                }
            })
        }
    }
    
    /// Reveal the Stats screen (Pep Talk tab, random tone like the web page) in place of the countdown
    /// and start streaming. The container shows straight away; the spinner covers it until text arrives.
    func showPepTalk(){
        isMotivationalMessageShowing = true
        pepTalkLastShownByRoutine = PepTalkRoutineDisplay.recording(currentState,
                                                                    into: pepTalkLastShownByRoutine)
        self.boxStarRating.isHidden = true
        self.imgView.isHidden = true
        self.timer?.invalidate()
        self.btnMain.isHidden = false
        self.btnSkipHabit.isHidden = false
        self.btnSkipTimer.isHidden = true
        self.lblTimer.isHidden = true
        self.isTimerGoingOn = false
        lblTimer.stringValue = ""
        lblVisualizeText.isHidden = true
        pepTalkContainer.isHidden = false
        showStatsScreen()
        self.btnMain.title = self.arrOptions.randomElement() ?? ""
    }
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0
    
    func startTimer(duration:Int) {
        btnSkipTimer.isHidden = false
        self.imgView.isHidden = false
        pepTalkContainer.isHidden = true
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
                                            addLog(text: "evening habit skipped:- this next habit is high priority habit but cutoff time of this habit has passed:- \(LogPrivacy.text(arrFilteredEveningHabits[i].name))  \(arrFilteredEveningHabits[i].id)") // remove this
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
                
                if self.isPepTalkVisible{
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
        if isPepTalkVisible{
            tearDownStatsScreen()
        }
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text:"[user-action] visualizeInstructionsVc - btnSkipClicked :- \(btnSkipHabit.title)")
        if !(activityCompletionVcObj?.isViewLoaded ?? false){
            activityCompletionVcObj?.loadView()
        }
        activityCompletionVcObj?.menuItemSkipHabitClicked()
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
