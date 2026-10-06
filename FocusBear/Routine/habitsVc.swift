//
//  habitsVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 05/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class habitsVc: NSViewController {
    
    @IBOutlet weak var habitsView: NSView!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var btnAbort: Button!
    @IBOutlet weak var lblCurrentDateTime: NSTextField!
    
    var breakTimer: Timer?
    var postponeTimer: Timer?
    var postponeNotificationTimer: Timer?
    var breakInactivitySecondsToCheck = 5
    var isWaitingForInactivityToStartMicroBreak = false
    var inActivityStartTime:Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnAbort.setAccessibilityIdentifier(UITestContract.Identifier.Routine.postponeButton)
        lblMessage.stringValue = "OK - Stay focused throughout the day!"
        lblMessage.isHidden = true
        btnAbort.title = "Please spare me"
        //btnAbort.borderWidth = 2
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblMessage.stringValue = common.value(forKey: "stayFocusedText") as? String ?? lblMessage.stringValue
            btnAbort.title = common.value(forKey: "buttonAbortText") as? String ?? btnAbort.title
        }
        isMainWindowLoaded = true
        
        
        btnAbort.isSecondaryButton = true
    }
    
    
    var dateTimeTimer:Timer?
    func startDateTimer() {
        // Time-of-day clock shown above the habit name on the habit player. It must stay hidden while a
        // Day Plan is on screen (the Day Plan has its own clock and the label overlaps its tasks panel).
        // Entering full screen calls this, so don't force it visible — only show it when a habit player
        // is the front content. The player/Day-Plan transitions (setDateTimeClockHidden /
        // updateScheduleTabForState) keep it in sync afterwards.
        dateTimeTimer?.invalidate()
        dateTimeTimer = nil
        ensureDateTimerRunning()
        refreshDateTimeClockVisibility()
    }

    /// Start the 1-second clock timer if it isn't already running. Idempotent, so it's safe to call from
    /// `refreshDateTimeClockVisibility` (which fires on every transition into a playing activity, and on
    /// each tick) — that's what makes the clock self-heal if the timer was ever invalidated (e.g. by
    /// `viewWillDisappear`) while an activity is still on screen, instead of freezing. The timer is stored
    /// BEFORE the first `setDateTime()` so the visibility refresh it triggers sees a live timer and can't
    /// recurse.
    func ensureDateTimerRunning() {
        guard dateTimeTimer == nil else { return }
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(setDateTime), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        dateTimeTimer = timer
        setDateTime()
    }

    /// True when an activity player is the front content of the habits area: the habit / custom-
    /// routine timer (timerViewcontroller) or a running micro-break activity (activityCompletionVc).
    /// The time-of-day clock belongs to these, so Day-Plan visibility code must not hide it.
    var isActivityPlayerFront: Bool {
        let players = [timerViewcontrollerObj?.view, activityCompletionVcObj?.view].compactMap { $0 }
        return players.contains { habitsView.subviews.contains($0) }
    }

    /// Set the clock's visibility from what's actually on screen. It is shown ONLY when the app's
    /// "Play habits in full screen mode" setting is enabled AND an activity is running in full screen
    /// — a habit, a custom-routine habit, or a micro-break activity — and not on the habit player's
    /// own Day Plan tab (which has its own clock and overlaps the tasks panel). Hidden in every other
    /// case: no activity running, the Day Plan list, the small window, the setting off, etc.
    /// Use this instead of `setDateTimeClockHidden(!isBreak)`: the host Day Plans stay "selected"
    /// (their scheduleVC isn't hidden) while a player runs on top, so a state change into a *running*
    /// activity would otherwise hide the clock the player just showed.
    func refreshDateTimeClockVisibility() {
        let onDayPlanTab = timerViewcontrollerObj?.isAllowedActivityDayPlanFront ?? false
        let show = checkIsFullScreenEnabled() && isActivityPlayerFront && !onDayPlanTab
        lblCurrentDateTime?.isHidden = !show
        // Whenever the clock is on screen it must be ticking — restart the timer if something invalidated
        // it (viewWillDisappear / a small-window transition) while an activity is still playing, so it
        // never shows a frozen time.
        if show { ensureDateTimerRunning() }
    }

    /// Hide/show the time-of-day clock. Hidden while a Day Plan is the visible content (its tasks panel
    /// overlaps this label and it has its own clock); shown on the habit player.
    func setDateTimeClockHidden(_ hidden: Bool) {
        lblCurrentDateTime?.isHidden = hidden
    }
    
    @objc func setDateTime(){
        // Keep visibility in sync each tick: an activity can become the front content without a state
        // change (e.g. a micro-break activity starting mid-break), which wouldn't otherwise re-run the
        // visibility logic. The timer only runs in full screen, so this is cheap and self-correcting.
        refreshDateTimeClockVisibility()
        if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
            print(dict)
            lblCurrentDateTime.stringValue = getDisplayStringFromDate(date: Date(), dateFormat: dict["DateFormat"] as? String ?? "EEE d MMM h:mm:ss")  // i18n-ignore: a date pattern, not text
        }else{
            lblCurrentDateTime.stringValue = getDisplayStringFromDate(date: Date(), dateFormat: "EEE d MMM h:mm:ss")  // i18n-ignore: a date pattern, not text
        }
    }
    
    override func viewWillDisappear() {
        // Keep the clock ticking while a full-screen activity is still on screen (it's shown and must
        // keep updating) — a spurious viewWillDisappear here is what froze the clock mid-habit. It's
        // restarted on full-screen enter / by refreshDateTimeClockVisibility in every other case.
        if !(checkIsFullScreenEnabled() && isActivityPlayerFront) {
            dateTimeTimer?.invalidate()
            dateTimeTimer = nil
        }
    }
    
    override func viewWillAppear() {

    }
    

    func hideCloseButtons(){
        self.btnAbort.isHidden = true
    }
    
    func showCloseButtons(){
        self.btnAbort.isHidden = false
    }
    
    func stopPostponeEndTimer(){
        if postponeTimer != nil{
            postponeTimer?.invalidate()
            postponeTimer = nil
        }
        if postponeNotificationTimer != nil{
            postponeNotificationTimer?.invalidate()
            postponeNotificationTimer = nil
        }
    }
    
    @objc func showFocusSummaryView(){
        appdelegate!.checkSystemTimeAndShowWindow()
        if startTime == nil || shutOffTime == nil{
            return;
        }
        
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{
            
        }else if curreentDate < startDate{
            
        }else{// not shutoff time
            currentState = ._NOTHING_
            if mainWindowControllerObj?.window?.isVisible ?? false{
                self.view.window?.close()
                hideBlankWindowInSecondaryMonitor()
            }
            return;
        }
        allActivityTodaySummaryData = nil
        currentState = ._FOCUS_SUMMARY_
        if SettingsManagerObject.isGeekModeEnabled{
            allApiObject.getAllActivityDaySummary(completionHandler: {dic in
                DispatchQueue.main.async {
                    if !(mainWindowControllerObj?.window!.isVisible)! {
                        mainWindowControllerObj?.showWindow(self)
                    }
                    showBlankWindowInSecondaryMonitor()
                    
                    addLog(text: "Showing Focus Summary")
                    self.hideCloseButtons()
                    self.removeSubViews()
                    self.habitsView.addSubview(focusSummaryVcObj!.view)
                    self.habitsView.addConstraints(subView: focusSummaryVcObj!.view)
                    focusSummaryVcObj!.reloadData()
                    leftMenuVcObj?.showHabitsView()
                }
            })
        }else{
            if !(mainWindowControllerObj?.window!.isVisible)! {
                mainWindowControllerObj?.showWindow(self)
            }
            showBlankWindowInSecondaryMonitor()
            
            addLog(text: "Showing Focus Summary: simnple mode")
            self.hideCloseButtons()
            self.removeSubViews()
            self.habitsView.addSubview(focusSummaryVcObj!.view)
            self.habitsView.addConstraints(subView: focusSummaryVcObj!.view)
            focusSummaryVcObj!.reloadData()
            leftMenuVcObj?.showHabitsView()
        }
        
        
    }
    
    @objc func showDayEndFocusCompletedView(){
        currentState = ._FOCUS_SUMMARY_
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        showBlankWindowInSecondaryMonitor()
        
        addLog(text: "show Day End Focus Completed View")
        self.hideCloseButtons()
        self.removeSubViews()
        self.habitsView.addSubview(focusCompletedFullScreenVcObj!.view)
        self.habitsView.addConstraints(subView: focusCompletedFullScreenVcObj!.view)
    }
    
    @objc func showMorningRoutineFocusCompletedView(){
        currentState = ._MORNING_HABIT_
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        showBlankWindowInSecondaryMonitor()
        
        addLog(text: "show Morning Routine Focus Completed View")
        self.hideCloseButtons()
        self.removeSubViews()
        self.habitsView.addSubview(focusCompletedFullScreenVcObj!.view)
        self.habitsView.addConstraints(subView: focusCompletedFullScreenVcObj!.view)
    }
    
    @objc func showCustomRoutineFocusCompletedView(){
        currentState = ._CUSTOM_ROUTINE_
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        showBlankWindowInSecondaryMonitor()
        
        addLog(text: "show custom Routine Focus Completed View")
        self.hideCloseButtons()
        self.removeSubViews()
        self.habitsView.addSubview(focusCompletedFullScreenVcObj!.view)
        self.habitsView.addConstraints(subView: focusCompletedFullScreenVcObj!.view)
    }
    
    @objc func showLoaderView(){
        mainViewControllerObj?.showLoaderView()
    }
    
    @objc func hideLoaderView(){
        mainViewControllerObj?.hideLoaderView()
    }
    
    var timerGiveOneMoreMinut:Timer?
    func giveOneMoreMinuteBeforeShutOffMac(){// state _FOCUS_SUMMARY_hi rahne denge taki kuch or bich mai naa aay
        mainWindowControllerObj?.window?.close()
        hideBlankWindowInSecondaryMonitor()
        
        DispatchQueue.global().sync {
            self.timerGiveOneMoreMinut = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.showFocusSummaryViewAgain), userInfo: nil, repeats: false)
            RunLoop.main.add((self.timerGiveOneMoreMinut!), forMode: RunLoop.Mode.common)
        }
        var msg = "One minute timer ends in"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
                msg = focusSummaryInfo.value(forKey: "oneMinuteTimerText") as? String ?? msg
            }
        }
        
        showSmallTimerWindow(durationSeconds: 60, msg: msg, isFocusBreak: false, currentTimerValue:0)
    }
    
    @objc func showFocusSummaryViewAgain(){
        DispatchQueue.main.async {
            addLog(text: "Showing Focus Summary again")

            // If the user spent the one-minute break in another app's native full screen (it sits on its
            // own Space), Focus Bear can't surface over it — activate() alone is refused on macOS 14+.
            // Drop that app out of full screen (same AXFullScreen helper the blocking flow uses; it's a
            // no-op if the app isn't full screen) so we're back on the desktop Space, then show the
            // summary and bring Focus Bear forward.
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.processIdentifier != NSRunningApplication.current.processIdentifier {
                exitFullScreen(runningApp: frontApp)
            }
            self.showFocusSummaryView()
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func showLogQuantityView(){
        allApiObject.capturePosthog(event: "log-quantity-view-shown", metadata: [:])
        self.view.addSubview(logQuantityVcObj!.view)
        self.view.addConstraints(subView: logQuantityVcObj!.view)
    }
    
    func showTakeNotesView(){
        allApiObject.capturePosthog(event: "take-notes-view-shown", metadata: [:])
        self.view.addSubview(getTakeActivityNotesVcObj().view)
        self.view.addConstraints(subView: getTakeActivityNotesVcObj().view)
    }
    
    func showFocusCompletedView(){
        allApiObject.capturePosthog(event: "focus-completed-for-activity-view-shown", metadata: [:])
        self.view.addSubview(getFocusCompletedForActivityVcObj().view)
        self.view.addConstraints(subView: getFocusCompletedForActivityVcObj().view)
    }
    
    func checkIsAnyUserInputSubViewAdded()->Bool{
        if logQuantityVcObj != nil{
            if self.view.subviews.contains(logQuantityVcObj!.view){
                return true
            }
        }
        
        if takeActivityNotesVcObj != nil{
            if self.view.subviews.contains(takeActivityNotesVcObj!.view){
                return true
            }
        }
        
        if focusCompletedForActivityVcObj != nil{
            if self.view.subviews.contains(focusCompletedForActivityVcObj!.view){
                return true
            }
        }
        return false
    }
    
    func showSkipHabitView(){
        addLog(text: "show SkipHabit View")
        self.view.addSubview(getSkipHabitVcObject().view)
        self.view.addConstraints(subView: getSkipHabitVcObject().view)
        getSkipHabitVcObject().resetView()
    }

    func showWhySkipHabitView(){
        addLog(text: "show whySkipHabit View")
        self.view.addSubview(getWhySkipHabitVcObject().view)
        self.view.addConstraints(subView: getWhySkipHabitVcObject().view)
    }
    
    func showAskPostponeView(){
        // A postpone that has already been granted must not be asked for again. The accountability
        // buddy approves an extension and starts the session; `abortCurrentState()` is then reached
        // from several routes (the window closing, the small countdown, the main view) and each one
        // re-entered this flow, so the user was asked for a reason two more times in twelve seconds
        // after unlocking once (report 2026-09-23_09-25-08):
        //
        //   09:23:00  accountability-buddy-session-extended: started super-strict session (15m)
        //   09:23:03  show AskPostpone View
        //   09:23:12  show AskPostpone View
        //
        // A live buddy session IS the granted postpone, so there is nothing left to ask.
        if currentAccountabilityBuddySession != nil {
            addLog(text: "showAskPostponeView: a buddy session is already running, not asking again")
            return
        }
        addLog(text: "show AskPostpone View")
        // AI accountability buddy: skip the "minutes to postpone" picker for habit postpones and go
        // straight to the chat (the AI sets the duration). Placeholder minutes here — the real duration
        // comes from the AI-approved verdict on `onApproved`.
        if SettingsManagerObject.isAccountabilityBuddyActive {
            switch currentState {
            case ._MORNING_HABIT_:
                postponeMorningHabitFor(minutes: 30, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true); return
            case ._EVENING_HABIT_:
                postponeEveningHabitFor(minutes: 30, secondsToPostpone: nil, showAskFocusModeView: true, showAskIntention: true); return
            case ._FOCUS_SUMMARY_:
                postponeFocusSummaryFor(minutes: 30, showAskIntention: true); return
            default:
                break
            }
        }
        // Host on the window's content view (always window-sized and on top) rather than habitsVc.view,
        // which grows to the full Day Plan height — there the centred dialog landed off-screen, and it
        // wasn't visible at all from the Tools/Help screens. Idempotent so re-triggers don't stack it.
        let host = mainWindowControllerObj?.window?.contentView ?? self.view
        let dialog = getAskPostponeVcObject().view
        if dialog.superview !== host {
            dialog.removeFromSuperview()
            host.addSubview(dialog)
            host.addConstraints(subView: dialog)
        }
        getAskPostponeVcObject().resetView()
    }
    
    func abortOnboardingWork(){
        allApiObject.capturePosthog(event: "onboarding-skip-clicked", metadata: [:])
        hideCloseButtons()
        if currentAction == ._INPROGRESS_{
            if timerViewcontrollerObj != nil {
                if timerViewcontrollerObj?.timer != nil {
                    timerViewcontrollerObj?.timer?.invalidate()
                    enableSystemSleep()
                    if timerViewcontrollerObj?.isVideoLodded ?? false{
                        if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                            if #available(macOS 12.0, *) {
                                if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
                                    timerViewcontrollerObj?.btnTabVideoClicked(self)
                                }
                                timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
                            } else {
                                // Fallback on earlier versions
                                timerViewcontrollerObj?.loadBlankUrl()
                            }
                        }
                    }
                }
            }
        }
        
        if currentState == ._ONBOARDING_{
            abortOboardingWorkTime()
            
        }else if currentState == ._BREATHING_{
            isFirstRun = true
            breathingFinishedUnlockMachine()
        }
    }
    
    func abortOboardingWorkTime(){
        if UserDefaults.standard.object(forKey: kUserdefaultsStartupTimeFromOnboarding) == nil{
            UserDefaults.standard.set(defaultStartTime, forKey: kUserdefaultsStartupTimeFromOnboarding)
            UserDefaults.standard.set(defaultShutDownTime, forKey: kUserdefaultsShutOffTimeFromOnboarding)
        }
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        
        isFirstRun = true
        breathingFinishedUnlockMachine()
    }
 
    func stopActivityCountDownTimer(){
        if currentAction == ._INPROGRESS_{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        
                        //focusButtonService---//
                        focusButtonServiceObject.pauseHabit()
                        //--------------//
                        
                        enableSystemSleep()
                        if timerViewcontrollerObj?.isVideoLodded ?? false{
                            if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                if #available(macOS 12.0, *) {
                                    if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
                                        timerViewcontrollerObj?.btnTabVideoClicked(self)
                                    }
                                    timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
                                } else {
                                    // Fallback on earlier versions
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                            }
                        }
                    }
                }

                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                
            }
        }
    }
    
    @IBAction func btnAbortClicked(_ sender: Any) {
        addLog(text: "[user-action] button Abort Clicked")
        abortCurrentState()
    }
    
    func abortCurrentState(){// added on 10/4/25 in 1.21.356
        // A state snapshot, the way `btnMinimizeClicked` already logs one.
        //
        // "I clicked exit full screen and minimise but nothing happened" has been unanswerable since
        // June (report 2026-06-24_16-18-08) because this function logs only that it was entered. It
        // then branches through a dozen paths, several of which return silently — so a click that
        // does nothing looks identical in the log to a click that did something, and the one detail
        // that would crack it is which branch was taken in which state.
        addLog(text: "func abortCurrentState state=\(currentState) action=\(currentAction) "
             + "playing=\(currentHabitPlaying?.name ?? "none") "
             + "allowedActivity=\(isAllowedActivityHabitCurrentlyRunning) "
             + "postponeCount=\(activityPostponeCount) "
             + "easySkip=\(SettingsManagerObject.isEasySkipEnabled) "
             + "buddy=\(currentAccountabilityBuddySession != nil) "
             + "subviews=\(view.subviews.count)")
        if currentState == ._ONBOARDING_ || currentState == ._BREATHING_{
            abortOnboardingWork()
            return;
        }
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._START_ && firstViewControllerObj != nil && editHabitRoutineVcObj != nil{
            if firstViewControllerObj!.isViewLoaded{
                if habitsView.subviews.contains(firstViewControllerObj!.view){
                    if firstViewControllerObj!.view.subviews.contains(editHabitRoutineVcObj!.view){
                        editHabitRoutineVcObj!.view.removeFromSuperview()
                        firstViewControllerObj!.btnEditHabits.isHidden = false
                        return;
                    }
                }
            }
        }

        // Report 2026-09-17_17-05-10: after the cutoff, a user who requires a password to postpone the
        // evening routine has declared that window off-limits — there is nothing left to postpone into,
        // so refuse here rather than opening the picker, the AI buddy chat or the password sheet. This
        // is the ONE funnel for user-initiated evening/shutdown postpones (the easy-skip window, the
        // minutes picker and the password sheet all hang off the branches below), so nothing has been
        // mutated yet and the user simply stays in their routine.
        // No cutoff refusal here. Past the cutoff, a user who asked for a password gets asked for it
        // by `popupAppointmentTimeVc.computeShouldAskPassword()`, which is one of the branches below —
        // that is the gate the setting describes. Refusing at this point pre-empted it.

        switch currentState {// added on 9/9/25 in 2.27.413

        case ._NOTHING_:
            addLog(text: "current state is:- nothing")
        case ._MORNING_HABIT_:
            addLog(text: "current state is:- morning routine")
        case ._EVENING_HABIT_:
            addLog(text: "current state is:- evening routine")
        case ._MICRO_BREAK_:
            addLog(text: "current state is:- micro breaks")
        case ._SHUTOFFMAC_:
            addLog(text: "current state is:- shutoff mac")
        case ._BREATHING_:
            addLog(text: "current state is:- breating")
        case ._ABORT_:
            addLog(text: "current state is:- aborting")
        case ._FOCUS_SUMMARY_:
            addLog(text: "current state is:- focus summary")
        case ._POSTPONE_MORNING_HABIT_:
            addLog(text: "current state is:- postpone morning routine")
        case ._POSTPONE_EVENING_HABIT_:
            addLog(text: "current state is:- postpone evening routine")
        case ._POSTPONE_FOCUS_SUMMARY_:
            addLog(text: "current state is:- postpone focus summary")
        case ._ONBOARDING_:
            addLog(text: "current state is:- ask app work")
        case ._SPECIAL_ACTIVITY_:
            addLog(text: "current state is:- special ativity")
        case ._CUSTOM_ROUTINE_:
            addLog(text: "current state is:- custom routine")
        case ._LOGIN_:
            addLog(text: "current state is:- login")
        }
        lastCurrentState = currentState
        lastCurrentAction = currentAction
        hideCloseButtons()
        
        stopActivityCountDownTimer()
        
        if currentState == ._MORNING_HABIT_{
            
            refreshLastPostponeCount()
            
            if SettingsManagerObject.isEasySkipEnabled{
                
                if currentHabitPlaying != nil{
                    closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                }
                showEasyPostponeWindow()
                stopActivityTimer()
                
                if currentHabitPlaying != nil{
                    closePupUpBlockIfVisible()
                }
                
            }else{
                stopActivityTimer()
                if activityPostponeCount == 0{
                    showAskPostponeView()
                }else{
                    if shouldAskPassword(){
                        if SettingsManagerObject.isPasswordRequireInPostponeMorning{
                            mainViewControllerObj?.showPasswordView()
                            enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                        }else{
                            showAskPostponeView()
                        }
                        
                    }else{
                        showAskPostponeView()
                    }
                    
                }
            }
            
        }else if currentState == ._EVENING_HABIT_{
            refreshLastPostponeCount()

            // Minimise/abort leads to the POSTPONE popup, so after cutoff it must honour the *postpone*
            // cutoff password setting (not the skip one) — and ask the password FIRST, before the popup,
            // regardless of easy-skip. Without this, easy-skip/the skip-gated path showed the postpone
            // popup with no password even though "require password to postpone after cutoff" was on.
            if isCutOffTimeGoing() && shouldAskPassword(forPostpone: true)
                && SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff {
                stopActivityTimer()
                showPasswordView()
                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                return
            }

            if SettingsManagerObject.isEasySkipEnabled {

                if currentHabitPlaying != nil{
                    closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                }
                showEasyPostponeWindow()
                stopActivityTimer()
                
                if currentHabitPlaying != nil{
                    closePupUpBlockIfVisible()
                }
                
            }else{
                stopActivityTimer()
                
                if activityPostponeCount == 0{
                    if isCutOffTimeGoing(){// changed in 2.27.422  : isHighPrioritySequenceGoing->isCutOffTimeGoing()
                        if shouldAskPassword(){
                            if SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff{
                                showPasswordView()
                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                            }else{
                                showAskPostponeView()
                            }
                        }else{
                            showAskPostponeView()
                        }
                    }else{
                        showAskPostponeView()
                    }
                }else{
                    if shouldAskPassword(){
                        if isCutOffTimeGoing(){// changed in 2.27.422  : isHighPrioritySequenceGoing->isCutOffTimeGoing()
                            if SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff{
                                showPasswordView()
                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                            }else{
                                showAskPostponeView()
                            }
                        }else{
                            if SettingsManagerObject.isPasswordRequireInPostponeEvening{
                                showPasswordView()
                                enterPasswordVcObj?.parentVc = getAskPostponeVcObject()
                            }else{
                                showAskPostponeView()
                            }
                        }
                    }else{
                        showAskPostponeView()
                    }
                }
            }
        }else if currentState == ._MICRO_BREAK_{
            var lastSavedPostponeTime = Date()
            activityPostponeCount = 0
            var lastSavedPostponeCount = activityPostponeCount
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            
            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakActivityPostponeInfo) as? [String:Any]{
                if let postponeCount =  infoDic["postponeCount"] as? Int{
                    lastSavedPostponeCount = postponeCount
                }
                if let date =  infoDic["date"] as? Date{
                    lastSavedPostponeTime = date
                }
            }
            
            if lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                activityPostponeCount = lastSavedPostponeCount
            }
            
            if SettingsManagerObject.isEasySkipEnabled{
                if currentAction == ._START_ || currentAction == ._BRAIN_DUMP_{
                    
                    if currentActivityPlaying != nil{
                        closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                    }
                    showEasyPostponeWindow()
                    if currentActivityPlaying != nil{
                        closePupUpBlockIfVisible()
                    }
                    if (getHabitsVcObject().habitsView.subviews.contains(firstViewControllerObj!.view)){
                        if firstViewControllerObj!.isTimerGoingOn{
                            firstViewControllerObj?.stopTimer()// stop 5 seconds timer if clicked postpone
                        }
                    }
                }else{
                    postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil, isFromBreakWarningWindow:false)
                }
            }else{
                if (getHabitsVcObject().habitsView.subviews.contains(firstViewControllerObj!.view)){
                    if firstViewControllerObj!.isTimerGoingOn{
                        firstViewControllerObj?.stopTimer()// stop 5 seconds timer if clicked postpone
                    }
                }
                
                if currentAction == ._START_{// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
                    showAskPostponeView()
                }else{
                    showAskPostponeView()
                }
            }
            
        }else if currentState == ._FOCUS_SUMMARY_{
            // #1942: cancel any pending "one more minute" timer before opening the postpone
            // dialog so it can't re-show the Focus Summary on top of / after the postpone,
            // and close its countdown box so the "one minute timer" window doesn't linger.
            timerGiveOneMoreMinut?.invalidate()
            timerGiveOneMoreMinut = nil
            closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            showAskPostponeView()
        }else if currentState == ._SPECIAL_ACTIVITY_{
            specialActivityFinish()
        }else if currentState == ._CUSTOM_ROUTINE_{
            if currentHabitPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            showEasyPostponeWindow()
            
            if currentHabitPlaying != nil{
                closePupUpBlockIfVisible()
            }
        }else if currentState == ._SHUTOFFMAC_{ // minimise button was not working in full screen. solved // v 2.28.450 #1632
            if !(shutOffTimeVcObj?.btnGetAccessNow.isHidden ?? true){
                if mainViewControllerObj?.isEnterPasswordViewVisible() ?? false{
                    addLog(text: "Enter password View is visible:- return;")
                    return;
                }
                if !(leftMenuVcObj?.boxHabits.isSelected ?? false){
                    leftMenuVcObj?.showHabitsView()
                }
                shutOffTimeVcObj?.btnGetAccessNowClicked(self)
            }else{
                addLog(text: "btn get access now is hidden:- return;")
            }
        }else{
            addLog(text: "If the state we expected is not among the current states, then just close the window.")// added on 9/9/25 in 2.27.413
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
        }
    }
    
    func processAborting(){
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if shouldAskPassword(){
                if activityPostponeCount == 0{//it  means we did not ask for password when user clicked on please apare me button so need to ask now
                    if currentState == ._MORNING_HABIT_{
                        if SettingsManagerObject.isPasswordRequireInSkipMorning{
                            showPasswordView()
                        }else{
                            showAbortStartView()
                        }
                    }else if currentState == ._EVENING_HABIT_{
                        
                        if isCutOffTimeGoing(){// changed in 2.27.422  : isHighPrioritySequenceGoing->isCutOffTimeGoing()
                            if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                showPasswordView()
                            }else{
                                showAbortStartView()
                            }
                        }else{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                showPasswordView()
                            }else{
                                showAbortStartView()
                            }
                        }
                    }
                }else{
                    showAbortStartView()
                }
            }else{
                showAbortStartView()
            }
            
        }else{
            showAbortStartView()
        }
    }
    
    func showPasswordView(){
        // Same window-content-view hosting as showAskPostponeView so the prompt is centred on-screen
        // and visible regardless of which screen (Day Plan / Tools / Help) is showing.
        let host = mainWindowControllerObj?.window?.contentView ?? self.view
        if enterPasswordVcObj!.view.superview !== host {
            enterPasswordVcObj!.view.removeFromSuperview()
            host.addSubview(enterPasswordVcObj!.view)
            host.addConstraints(subView: enterPasswordVcObj!.view)
        }
        enterPasswordVcObj?.removeConstraints()
        enterPasswordVcObj?.parentVc = nil
        enterPasswordVcObj?.pendingAction = nil
        enterPasswordVcObj?.cancelAction = nil
        addLog(text: "Showing enter password view")
    }
    
    func showAbortStartView(){
        addLog(text: "showAbortStartView")
        removeSubViews()
        habitsView.addSubview(abortingCountDownVcObj!.view)
        habitsView.addConstraints(subView: abortingCountDownVcObj!.view)
        abortingCountDownVcObj?.startTimer()
        currentState = ._ABORT_
    }
    
    func abortCancel(){
        addLog(text: "abortCancel")
        
        if lastCurrentState == ._MICRO_BREAK_{
            self.showCloseButtons()
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                currentState = ._MICRO_BREAK_
                currentAction = ._START_
                activityCompletionVcObj?.startBreakActivity()
                firstViewControllerObj?.isFirstTime = false
                
                habitsView.addSubview(firstViewControllerObj!.view)
                habitsView.addConstraints(subView: firstViewControllerObj!.view)
                firstViewControllerObj?.tblViewHabits.reloadData()
                break
            case ._INPROGRESS_:
                habitsView.addSubview(timerViewcontrollerObj!.view)
                habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
                
                timerViewcontrollerObj?.resumeTimerActivity(durationInSeconds: timerViewcontrollerObj?.currentDurationInSeconds ?? 0, name: timerViewcontrollerObj?.currentActicityTitle ?? "", url: timerViewcontrollerObj?.currentUrl, useTimer:timerViewcontrollerObj?.currentActivityUseTimer ?? true)
                currentState = ._MICRO_BREAK_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                self.showCloseButtons()
                removeSubViews()
                habitsView.addSubview(activityCompletionVcObj!.view)
                habitsView.addConstraints(subView: activityCompletionVcObj!.view)
                currentState = ._MICRO_BREAK_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                break
            case ._BRAIN_DUMP_:
                currentState = ._MICRO_BREAK_
                currentAction = ._BRAIN_DUMP_
                
                activityCompletionVcObj?.startBreakActivity()
                //showBreaksBrainDump()
                
                break
            }
        }else if lastCurrentState == ._MORNING_HABIT_{
            self.showCloseButtons()
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                showAllMorningHabitsAbortCancel()
            case ._INPROGRESS_:
                habitsView.addSubview(timerViewcontrollerObj!.view)
                habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, url: arrFilteredMorningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrFilteredMorningHabits[currentHabitIndex].name!, useTimer: arrFilteredMorningHabits[currentHabitIndex].useTimer)
                currentState = ._MORNING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                self.showCloseButtons()
                removeSubViews()
                habitsView.addSubview(activityCompletionVcObj!.view)
                habitsView.addConstraints(subView: activityCompletionVcObj!.view)
                currentState = ._MORNING_HABIT_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                currentState = ._MORNING_HABIT_
                getHabitsVcObject().showVisualizeInstructionsVc()
                break
            case ._BRAIN_DUMP_:
                break
            }
            
        }else if lastCurrentState == ._EVENING_HABIT_{
            self.showCloseButtons()
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                showAllEveningHabitsAbortCancel()
            case ._INPROGRESS_:
                habitsView.addSubview(timerViewcontrollerObj!.view)
                habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, url: arrFilteredEveningHabits[currentHabitIndex].urlsArray.randomElement(), name: arrFilteredEveningHabits[currentHabitIndex].name!, useTimer: arrFilteredEveningHabits[currentHabitIndex].useTimer)
                currentState = ._EVENING_HABIT_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                self.showCloseButtons()
                removeSubViews()
                habitsView.addSubview(activityCompletionVcObj!.view)
                habitsView.addConstraints(subView: activityCompletionVcObj!.view)
                currentState = ._EVENING_HABIT_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                currentState = ._EVENING_HABIT_
                getHabitsVcObject().showVisualizeInstructionsVc()
                break
            case ._BRAIN_DUMP_:
                break
            }
            
        }else if lastCurrentState == ._SHUTOFFMAC_{
            self.showCloseButtons()
            removeSubViews()
            shutOffMac()
        }else if lastCurrentState == ._FOCUS_SUMMARY_{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            self.hideCloseButtons()
            self.removeSubViews()
            self.habitsView.addSubview(focusSummaryVcObj!.view)
            self.habitsView.addConstraints(subView: focusSummaryVcObj!.view)
            currentState = ._FOCUS_SUMMARY_
        }else if lastCurrentState == ._CUSTOM_ROUTINE_{
            self.showCloseButtons()
            removeSubViews()
            switch lastCurrentAction {
            case ._START_:
                showAllCustomRoutineHabitsAbortCancel()
            case ._INPROGRESS_:
                habitsView.addSubview(timerViewcontrollerObj!.view)
                habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
                let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
                timerViewcontrollerObj?.resumeTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, url: arrHabits[currentHabitIndex].urlsArray.randomElement(), name: arrHabits[currentHabitIndex].name!, useTimer: arrHabits[currentHabitIndex].useTimer)
                currentState = ._CUSTOM_ROUTINE_
                currentAction = ._INPROGRESS_
                break
            case ._END_:
                self.showCloseButtons()
                removeSubViews()
                habitsView.addSubview(activityCompletionVcObj!.view)
                habitsView.addConstraints(subView: activityCompletionVcObj!.view)
                currentState = ._CUSTOM_ROUTINE_
                currentAction = ._END_
                break
            case ._VISUALIZE_:
                currentState = ._CUSTOM_ROUTINE_
                getHabitsVcObject().showVisualizeInstructionsVc()
                break
            case ._BRAIN_DUMP_:
                break
            }
        }
        
    }
    
    
    func showAbortConfirmationView(){
        addLog(text: "showAbortConfirmationView")
        hideCloseButtons()
        removeSubViews()
        habitsView.addSubview(abortingConfirmVcObj!.view)
        habitsView.addConstraints(subView: abortingConfirmVcObj!.view)
        abortingConfirmVcObj!.resetData()
        currentState = ._ABORT_
        activityPostponeCount = 0
    }
    
    func showAbortStartSmallVc(isAnyHabitRemoved:Bool){
        addLog(text: "showAbortStartSmallVc")
        hideCloseButtons()
        removeSubViews()
        habitsView.addSubview(abortingCantHandleVcObj!.view)
        habitsView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = true
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: isAnyHabitRemoved)
        currentState = ._ABORT_
    }
    
    func showAbortDisableMorningRoutineVc(){
        addLog(text: "showAbortDisableMorningRoutineVc")
        hideCloseButtons()
        removeSubViews()
        habitsView.addSubview(abortingCantHandleVcObj!.view)
        habitsView.addConstraints(subView: abortingCantHandleVcObj!.view)
        abortingCantHandleVcObj!.isViewStartingSmall = false
        abortingCantHandleVcObj!.resetView(isAnyHabitRemoved: false)
        currentState = ._ABORT_
    }
    func showAbortDoneView(){
        addLog(text: "showAbortDoneView")
        hideCloseButtons()
        removeSubViews()
        habitsView.addSubview(abortDoneVcObj!.view)
        habitsView.addConstraints(subView: abortDoneVcObj!.view)
        abortDoneVcObj?.startTimer()
        currentState = ._ABORT_
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    func removeSubViews(){
        // The break start screen owns a countdown and an unsaved brain dump; tell it that it's going.
        breakStartVcObj?.breakStartDismissed()
        let viewsArr = habitsView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
    }
    
    func shutOffMac(){
        isHabitAlreadyShowed = false
        if currentState == ._SHUTOFFMAC_{
            return;
        }
        addLog(text: "Showing Shut Off screen.")
        hideCloseButtons()
        removeSubViews()
        habitsView.addSubview(shutOffTimeVcObj!.view)
        habitsView.addConstraints(subView: shutOffTimeVcObj!.view)
        currentState = ._SHUTOFFMAC_
        stopActivityTimer()
        // The shutdown screen is the one prompt in here that genuinely has to be seen, so it is
        // allowed to insist — but still not out of a menu the user has open.
        appdelegate?.requestShutdownFocus(urgency: .shutdownStarting)
    }
    
    func showAlertNoHighPriorityActivities(){
        addLog(text: "Showing Alert No High Priority Activities.")
        if let window = mainWindowControllerObj?.window{
            let alert = NSAlert()
            alert.setSharingType()
            var noHighPriorityActivityText = "No activities with high Priority found"
            
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                noHighPriorityActivityText = common.value(forKey: "noHighPriorityActivityText") as? String ?? noHighPriorityActivityText
            }
            
            alert.messageText = noHighPriorityActivityText
            alert.addButton(withTitle: buttonOkText)
            
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.beginSheetModal(for: window)
        }
    }
    
    func showFirstTimeVc(){
        addLog(text: "Showing first time welcome activity.")
        self.showCloseButtons()
        removeSubViews()
        firstViewControllerObj?.isFirstTime = true//ik bar object bna or dusri line mai true hua debug mode mai qki debug mode mai sare global variables ya obj call krne k baad initialize hote hai
        firstViewControllerObj?.isFirstTime = true
        habitsView.addSubview(firstViewControllerObj!.view)
        habitsView.addConstraints(subView: firstViewControllerObj!.view)
        currentState = ._BREATHING_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showVisualizeInstructionsVc(){
        addLog(text: "show Visualize Instructions Vc.")
        self.showCloseButtons()
        removeSubViews()
        currentAction = ._VISUALIZE_
        habitsView.addSubview(getvisualizeInstructionsObject().view)
        habitsView.addConstraints(subView: getvisualizeInstructionsObject().view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    /*
    func showBreaksBrainDump(){
        allApiObject.capturePosthog(event: "breaks-brain-dump-shown", metadata: [:])
        addLog(text: "show Breaks Brain Dump.")
        self.showCloseButtons()
        removeSubViews()
        currentAction = ._BRAIN_DUMP_
        habitsView.addSubview(getBreaksBrainDumpVcObject().view)
        habitsView.addConstraints(subView: getBreaksBrainDumpVcObject().view)
        NSApplication.shared.activate(ignoringOtherApps: true)
        breaksBrainDumpVcObj?.resetBrainDump()
    }
    */
    
    func showAllEveningHabits(){
        addLog(text: "func showAllEveningHabits:- Initiate and run Evening Habits.")
        closeEasyPostponeWindowIfVisible()
        
        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
            currentState = ._EVENING_HABIT_
            showVisualizeInstructionsVc()
            addLog(text: "func showAllEveningHabits:- current action is visualize:- return")
            return;
        }
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitID)
        
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        var lastActivityIndex = -1
        if isHighPrioritySequenceGoing{
            if !arrFilteredEveningHabits[0].isPriorityHigh{
                isLastActivityStoppedInRunningState = false
            }
        }
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
                for i in 0..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].id == lastSavedActivityId{
                        lastActivityIndex = i
                        if isHighPrioritySequenceGoing{
                            if !arrFilteredEveningHabits[lastActivityIndex].isPriorityHigh{
                                lastActivityIndex = -1
                            }
                        }
                        break;
                    }
                }
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        let currentDate = Date()
        var shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: currentDate)!
        if currentDate < shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: tomorrowDate) ?? tomorrowDate
            
        }
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredEveningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllEveningHabits:- Activity Postpone In Running State:- start direct \(LogPrivacy.text(arrFilteredEveningHabits[0].name)) in running state")
            removeSubViews()
            self.showCloseButtons()
            
            currentHabitIndex = 0
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastActivityIndex != -1{
            if lastActivityIndex != -1{//user can start random habit
                let habit = arrFilteredEveningHabits[lastActivityIndex]
                arrFilteredEveningHabits.remove(at: lastActivityIndex)
                arrFilteredEveningHabits.insert(habit, at: 0)
            }
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllEveningHabits:- app terminate In Running State:- start direct \(LogPrivacy.text(arrFilteredEveningHabits[0].name)) in running state")
            removeSubViews()
            self.showCloseButtons()
            currentHabitIndex = 0
            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
        }else{
            addLog(text:"func showAllEveningHabits:- show All Evening Habits")
            SensitiveDefaults.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            isLastActivityStoppedInRunningState = false
            isPromptToRememberHabitShowedInLastHabit = false
            self.showCloseButtons()
            removeSubViews()
            
            if isHighPrioritySequenceGoing{
                for i in 0..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].isPriorityHigh{
                        currentHabitIndex = i - 1
                        break;
                    }
                }
            }else{
                currentHabitIndex = -1
            }
            
            habitTotalCompletedSeconds = 0
            currentState = ._EVENING_HABIT_
            currentAction = ._START_
            firstViewControllerObj?.isFirstTime = false
            firstViewControllerObj?.shouldIgnoreVisualizeInstructions = false
            habitsView.addSubview(firstViewControllerObj!.view)
            habitsView.addConstraints(subView: firstViewControllerObj!.view)
            NSApplication.shared.activate(ignoringOtherApps: true)
            playStartMorningEveningRoutineSound()
        }
    }
    
    func showAllEveningHabitsAbortCancel(){
        addLog(text: "Abort Cancel:-Initiate and run Evening Habits.")
        habitTotalCompletedSeconds = 0
        isPromptToRememberHabitShowedInLastHabit = false
        self.showCloseButtons()
        removeSubViews()
        currentState = ._EVENING_HABIT_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
        habitsView.addSubview(firstViewControllerObj!.view)
        habitsView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showAllMorningHabits(){
        addLog(text: "func showAllMorningHabits:- Showing morning habits.")
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        
        closeEasyPostponeWindowIfVisible()
        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
            currentState = ._MORNING_HABIT_
            showVisualizeInstructionsVc()
            addLog(text: "func showAllMorningHabits:- current action is visualize:- return")
            return;
        }
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitID)
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        var lastActivityIndex = -1
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
                for i in 0..<arrFilteredMorningHabits.count{
                    if arrFilteredMorningHabits[i].id == lastSavedActivityId{
                        lastActivityIndex = i
                        break;
                    }
                }
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredMorningHabits[0].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllMorningHabits:- Activity Postpone In Running State:- start direct \(LogPrivacy.text(arrFilteredMorningHabits[0].name)) in running state")
            removeSubViews()
            self.showCloseButtons()
            
            currentHabitIndex = 0
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastActivityIndex != -1{
            if lastActivityIndex != -1{//user can start random habit
                let habit = arrFilteredMorningHabits[lastActivityIndex]
                arrFilteredMorningHabits.remove(at: lastActivityIndex)
                arrFilteredMorningHabits.insert(habit, at: 0)
            }
            
            isLastActivityStoppedInRunningState = false
            addLog(text:"func showAllMorningHabits:- app terminate In Running State:- start direct \(LogPrivacy.text(arrFilteredMorningHabits[0].name)) in running state")
            removeSubViews()
            self.showCloseButtons()
            currentHabitIndex = 0
            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
        }else{
            addLog(text:"func showAllMorningHabits:- show All Morning Habits")
            SensitiveDefaults.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            isLastActivityStoppedInRunningState = false
            isPromptToRememberHabitShowedInLastHabit = false
            lastShownRandomChoiceDic = [String:activityChoice]()
            self.showCloseButtons()
            removeSubViews()
            currentHabitIndex = -1
            habitTotalCompletedSeconds = 0
            currentState = ._MORNING_HABIT_
            currentAction = ._START_
            firstViewControllerObj?.isFirstTime = false
            firstViewControllerObj?.shouldIgnoreVisualizeInstructions = false
            habitsView.addSubview(firstViewControllerObj!.view)
            habitsView.addConstraints(subView: firstViewControllerObj!.view)
            firstViewControllerObj?.checkMorningHabitDelayTime()
            NSApplication.shared.activate(ignoringOtherApps: true)
            playStartMorningEveningRoutineSound()
            getTotalFocuedTime()
        }
    }
    
    func showAllMorningHabitsAbortCancel(){
        addLog(text: "Abort Cancel Showing morning habits.")
        habitTotalCompletedSeconds = 0
        isPromptToRememberHabitShowedInLastHabit = false
        lastShownRandomChoiceDic = [String:activityChoice]()
        self.showCloseButtons()
        removeSubViews()
        currentState = ._MORNING_HABIT_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
        firstViewControllerObj?.shouldIgnoreVisualizeInstructions = false
        habitsView.addSubview(firstViewControllerObj!.view)
        habitsView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func removeCompletedHabitsForMorningEveningRoutine(){
        if currentState == ._MORNING_HABIT_{
            if currentHabitIndex != -1{
                // remove habits which are completed
                let tempHabits = arrFilteredMorningHabits
                arrFilteredMorningHabits.removeAll()
                
                for i in currentHabitIndex+1..<tempHabits.count{
                    arrFilteredMorningHabits.append(tempHabits[i])
                }
                
                // now remove from main array
                for i in 0...currentHabitIndex{
                    let removedHabitId = tempHabits[i].id
                    if let index = arrPreFilteredMorningHabits.firstIndex(where: { $0.id == removedHabitId }) {
                        arrPreFilteredMorningHabits.remove(at: index)
                    }
                }
            }
            
        }else if currentState == ._EVENING_HABIT_{
            if currentHabitIndex != -1{
                let tempHabits = arrFilteredEveningHabits
                arrFilteredEveningHabits.removeAll()
                
                for i in currentHabitIndex+1..<tempHabits.count{
                    arrFilteredEveningHabits.append(tempHabits[i])
                }
                
                // now remove from main array
                for i in 0...currentHabitIndex{
                    let removedHabitId = tempHabits[i].id
                    if let index = arrPreFilteredEveningHabits.firstIndex(where: { $0.id == removedHabitId }) {
                        arrPreFilteredEveningHabits.remove(at: index)
                    }
                }
            }
        }
    }
    
    func saveRemainingHabitIdForPostponedRoutineList(state:CURRENTSTATE){
        removeCompletedHabitsForMorningEveningRoutine()
        
        if state == ._MORNING_HABIT_{
            let ids = arrFilteredMorningHabits.map { $0.id }
            let preFilteredIds = arrPreFilteredMorningHabits.map { $0.id }
            UserDefaults.standard.set(ids, forKey: kUserdefaultsLastHabitsIdsBeforePostpone)
            UserDefaults.standard.set(preFilteredIds, forKey: kUserdefaultsPrefilterLastHabitsIdsBeforePostpone)
        }else if state == ._EVENING_HABIT_{
            let ids = arrFilteredEveningHabits.map { $0.id }
            let preFilteredIds = arrPreFilteredEveningHabits.map { $0.id }
            UserDefaults.standard.set(ids, forKey: kUserdefaultsLastHabitsIdsBeforePostpone)
            UserDefaults.standard.set(preFilteredIds, forKey: kUserdefaultsPrefilterLastHabitsIdsBeforePostpone)
        }
    }
    
    func showAllMorningEveningHabitsFromHabitCompleted(){
        // Back resets the routine index; neither a live timer nor queued completion may use it.
        timerViewcontrollerObj?.cancelActivityTimer()
        
        removeCompletedHabitsForMorningEveningRoutine()
        
        addLog(text: "Showing morning/evening habits from habit completed back button.")
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        isLastActivityStoppedInRunningState = false
        isPromptToRememberHabitShowedInLastHabit = false
        lastShownRandomChoiceDic = [String:activityChoice]()
        self.showCloseButtons()
        removeSubViews()
        currentHabitIndex = -1
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
        firstViewControllerObj?.shouldIgnoreVisualizeInstructions = true
        habitsView.addSubview(firstViewControllerObj!.view)
        habitsView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func startMorningRoutineHabitFromDeviceButton(name:String, shouldUpdateDeviceButton:Bool){
        addLog(text: "Start Morning Routine Habit From Device Button.")
        if let mainWindowControllerObj = mainWindowControllerObj, !(mainWindowControllerObj.window?.isVisible ?? false){
            mainWindowControllerObj.showWindow(self)
        }
        removeCompletedHabitsForMorningEveningRoutine()
        for i in 0..<arrFilteredMorningHabits.count{
            if arrFilteredMorningHabits[i].fakeIdForDevice == name || arrFilteredMorningHabits[i].name.lowercased() == name || arrFilteredMorningHabits[i].nameWithoutIcon.lowercased() == name{
                let habit = arrFilteredMorningHabits[i]
                arrFilteredMorningHabits.remove(at: i)
                arrFilteredMorningHabits.insert(habit, at: 0)
                self.showCloseButtons()
                removeSubViews()
                currentHabitIndex = -1
                currentState = ._MORNING_HABIT_
                currentAction = ._INPROGRESS_
                getHabitsVcObject().startFirstMorningHabit(shouldUpdateDeviceButton: shouldUpdateDeviceButton)
                break;
            }
        }
    }
    
    func startEveningRoutineHabitFromDeviceButton(name:String, shouldUpdateDeviceButton:Bool){
        addLog(text: "Start Evening Routine Habit From Device Button.")
        if let mainWindowControllerObj = mainWindowControllerObj, !(mainWindowControllerObj.window?.isVisible ?? false){
            mainWindowControllerObj.showWindow(self)
        }
        removeCompletedHabitsForMorningEveningRoutine()
        for i in 0..<arrFilteredEveningHabits.count{
            if arrFilteredEveningHabits[i].fakeIdForDevice == name || arrFilteredEveningHabits[i].name.lowercased() == name || arrFilteredEveningHabits[i].nameWithoutIcon.lowercased() == name{
                let habit = arrFilteredEveningHabits[i]
                arrFilteredEveningHabits.remove(at: i)
                arrFilteredEveningHabits.insert(habit, at: 0)
                self.showCloseButtons()
                removeSubViews()
                currentHabitIndex = -1
                currentState = ._EVENING_HABIT_
                currentAction = ._INPROGRESS_
                getHabitsVcObject().startFirstEveningHabit(shouldUpdateDeviceButton: shouldUpdateDeviceButton)
                break;
            }
        }
    }
    
    func showAllCustomRoutineHabitsAbortCancel(){
        addLog(text: "Abort Cancel Showing Custom Routine habits.")
        habitTotalCompletedSeconds = 0
        isPromptToRememberHabitShowedInLastHabit = false
        lastShownRandomChoiceDic = [String:activityChoice]()
        self.showCloseButtons()
        removeSubViews()
        currentState = ._CUSTOM_ROUTINE_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
        habitsView.addSubview(firstViewControllerObj!.view)
        habitsView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func startFirstMorningHabit(shouldUpdateDeviceButton:Bool = true) {
        addLog(text:"current startFirstMorningHabit from list called")
        self.showCloseButtons()
        removeSubViews()
        currentHabitIndex = 0
        // #2794: flip the routine state BEFORE presenting the habit's timer/intention UI. The
        // `currentState` didSet re-shows the habits view (removeSubViews → re-add), which fires
        // `timerViewcontroller.viewWillDisappear` and dismisses the focus-mode "what's your intention?"
        // sheet. When this ran AFTER `tryStartTimerHabit`, that teardown tore down the just-presented
        // sheet (~1s later) whenever the routine was started from an idle Day Plan (currentState was
        // ._NOTHING_, so the transition really fired). Setting state first means the teardown happens
        // before the sheet exists — the same order the menu-bar start path
        // (startMorningRoutineHabitFromDeviceButton) already uses safely.
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:0, shouldUpdateDeviceButton: shouldUpdateDeviceButton)

        // #1982 follow-up: the user is starting the morning routine now — clear any saved
        // postponed-routine state so a stale postpone isn't restored as a postponed habit list on the
        // next app launch.
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        allApiObject.capturePosthog(event: "start-morning-routine", metadata: ["routine-type":"morning_routine"])
    }
    
    func startFirstEveningHabit(shouldUpdateDeviceButton:Bool = true) {
        addLog(text:"current startFirstEveningHabit from list called")
        self.showCloseButtons()
        removeSubViews()
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        
        if isHighPrioritySequenceGoing{
            for i in 0..<arrFilteredEveningHabits.count{
                if arrFilteredEveningHabits[i].isPriorityHigh{
                    if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                        let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                        let currentDate = Date()
                        if currentDate > cutOffDate{
                            addLog(text: "evening habit skipped:- cutoff time for this first habit passed:- \(LogPrivacy.text(arrFilteredEveningHabits[i].name))  \(arrFilteredEveningHabits[i].id)") // remove this
                            continue;
                        }
                    }
                    currentHabitIndex = i
                    break;
                }
            }
        }else{
            currentHabitIndex = 0
        }
        
        // #2794: set state before presenting the sheet — see startFirstMorningHabit for why.
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:0, shouldUpdateDeviceButton: shouldUpdateDeviceButton)

        // #1982 follow-up: the user is starting the evening routine now — clear any saved
        // postponed-routine state so a stale postpone isn't restored as a postponed habit list on the
        // next app launch.
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        allApiObject.capturePosthog(event: "start-evening-routine", metadata: ["routine-type":"evening_routine"])
    }
    
    func startFirstCustomRoutineHabit() {
        addLog(text:"current startFirstCustomRoutineHabit called")
        self.showCloseButtons()
        removeSubViews()
        currentHabitIndex = 0
        // #2794: set state before presenting the sheet — see startFirstMorningHabit for why.
        currentState = ._CUSTOM_ROUTINE_
        currentAction = ._INPROGRESS_
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:0)
        allApiObject.capturePosthog(event: "start-custom-routine", metadata: ["routine-type":"custom_routine"])
    }
    
    
    func startBreathing() {
        addLog(text:"current startBreathing called")
        self.showCloseButtons()
        removeSubViews()
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.startBreathing()
        currentState = ._BREATHING_
        currentAction = ._INPROGRESS_
        allApiObject.capturePosthog(event: "start-first-routine", metadata: ["routine-type":"first_routine"])
    }
    
    func breathingOver(isSKipped:Bool) {
        addLog(text:"current breathing Habit Over called")
        hideCloseButtons()
        removeSubViews()
        habitsView.addSubview(activityCompletionVcObj!.view)
        habitsView.addConstraints(subView: activityCompletionVcObj!.view)
        activityCompletionVcObj!.breathingFinished(isSKipped: isSKipped)
        currentState = ._BREATHING_
        currentAction = ._END_
        allApiObject.capturePosthog(event: "complete-first-routine", metadata: ["routine-type":"first_routine"])
    }
    
    func morningHabitOver() {
        guard arrFilteredMorningHabits.indices.contains(currentHabitIndex) else {
            addLog(text: "morningHabitOver: ignoring stale completion index \(currentHabitIndex)")
            return
        }
        addLog(text:"current morning Habit Over called")
        getHabitsVcObject().stopActivityTimer()
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            //mainViewControllerObj?.checkIsFullScreenNeeded()
            leftMenuVcObj?.showHabitsView()
        }else{
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            // mainViewControllerObj?.checkIsFullScreenNeeded()
            leftMenuVcObj?.showHabitsView()
        }
        addLog(text:"setDocBarTo passed")
        if isAnyAllowedFocusModeActivityRunning{
            closeNudgeFocusAlignmentScoreWindow()
        }
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        
        taskPlayerVcObj?.getToDosFromPlayer()
        
        leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
        addLog(text:"toolBoxWinow close passed")
        refreshFocusModeData()
        setAppIconForFocusModeScore(probability: nil)
        
        closePupUpBlockIfVisible()
        addLog(text:"closePupUpBlockIfVisible passed")
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        addLog(text:"showCloseButtons passed")
        removeSubViews()
        addLog(text:"removeSubViews passed")
        habitsView.addSubview(activityCompletionVcObj!.view)
        habitsView.addConstraints(subView: activityCompletionVcObj!.view)
        activityCompletionVcObj!.morningHabitFinished(index: currentHabitIndex)
        addLog(text:"morningHabitFinished passed")
        currentState = ._MORNING_HABIT_
        currentAction = ._END_
        if activityPostponeCount > 3{
            activityPostponeCount = 3//I complete a habit after postponing, it should go back to a 15 second postpone the next time
            savePostpneCount(state: ._MORNING_HABIT_)
        }
        addLog(text:"savePostpneCount passed")
    }
    
    func startDirectIncompleteMorningHabitAtIndex(index:Int, isLastActivitySkipped:Bool) {
        addLog(text:"func:- startDirectIncompleteMorningHabitAtIndex")
        // Guard the index — the habits array can be shorter than the caller expects (it's refetched/
        // filtered async), and an out-of-range subscript below crashes (Sentry FOCUS-BEAR-MACOS-18M,
        // EXC_BREAKPOINT at arrFilteredMorningHabits[index]). Bail safely instead of trapping.
        guard index >= 0, index < arrFilteredMorningHabits.count else {
            addLog(text:"startDirectIncompleteMorningHabitAtIndex: index \(index) out of range (count \(arrFilteredMorningHabits.count)) — skipping")
            return
        }
        currentState = ._MORNING_HABIT_// changing state here because in load completed habit graph there is a check about current state
        currentAction = ._END_
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        
        refreshFocusModeData()
        
        closePupUpBlockIfVisible()
        
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        removeSubViews()
        
        closeEasyPostponeWindowIfVisible()
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        var lastActivityIndex = -1
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
                for i in 0..<arrFilteredMorningHabits.count{
                    if arrFilteredMorningHabits[i].id == lastSavedActivityId{
                        lastActivityIndex = i
                        break;
                    }
                }
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        // Re-validate the index right before subscripting. The entry guard only proved `index` was
        // in range on entry, but the setup calls above (focus-mode refresh, UI teardown, etc.) can
        // re-filter arrFilteredMorningHabits and shrink it, leaving `index` stale — which traps in
        // Array._checkSubscript below (Sentry EXC_BREAKPOINT, issue 7671202979). Bail safely instead.
        guard index >= 0, index < arrFilteredMorningHabits.count else {
            addLog(text:"startDirectIncompleteMorningHabitAtIndex: index \(index) out of range after setup (count \(arrFilteredMorningHabits.count)) — skipping")
            return
        }
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredMorningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- Activity Postpone In Running State:- start direct \(LogPrivacy.text(arrFilteredMorningHabits[index].name)) in running state")
            
            currentHabitIndex = index
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
            
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrFilteredMorningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- app terminate In Running State:- start direct \(LogPrivacy.text(arrFilteredMorningHabits[index].name)) in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastActivityIndex != -1 && lastActivityIndex > index{//user can start random habit
            
            if lastActivityIndex != -1{//user can start random habit
                let habit = arrFilteredMorningHabits[lastActivityIndex]
                arrFilteredMorningHabits.remove(at: lastActivityIndex)
                arrFilteredMorningHabits.insert(habit, at: index)
            }
            
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- app terminate In Running State:- start direct \(LogPrivacy.text(arrFilteredMorningHabits[index].name)) in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrFilteredMorningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._MORNING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else{
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- morningHabitFinishedAndStartIncompleteNew")
            isLastActivityStoppedInRunningState = false
            
            if index == 0{
                showAllMorningHabits()
            }else{
                habitsView.addSubview(activityCompletionVcObj!.view)
                habitsView.addConstraints(subView: activityCompletionVcObj!.view)
                currentHabitIndex = index-1
                activityCompletionVcObj!.morningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
            }
            
        }
        
    }
    
    func showRoutineAllHabits(routineIndex:Int){
        addLog(text: "func showRoutineAllHabits:- Showing Routine habits.")
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
        closeEasyPostponeWindowIfVisible()
        if currentAction == ._VISUALIZE_{// did this beacuse we dont want user do to visualize again if he has don once for a habit
            currentState = ._CUSTOM_ROUTINE_
            showVisualizeInstructionsVc()
            addLog(text: "func showRoutineAllHabits:- current action is visualize:- return")
            return;
        }
        habitTotalCompletedSeconds = 0
        self.showCloseButtons()
        removeSubViews()
        currentHabitIndex = -1
        currentState = ._CUSTOM_ROUTINE_
        currentAction = ._START_
        firstViewControllerObj?.isFirstTime = false
        habitsView.addSubview(firstViewControllerObj!.view)
        habitsView.addConstraints(subView: firstViewControllerObj!.view)
        NSApplication.shared.activate(ignoringOtherApps: true)
        playStartMorningEveningRoutineSound()
        getTotalFocuedTime()
    }
    
    func startDirectIncompleteCustomRoutineHabitAtIndex(index:Int, isLastActivitySkipped:Bool) {
        addLog(text:"func:- startDirectIncompleteCustomRoutineHabitAtIndex")
        currentState = ._CUSTOM_ROUTINE_// changing state here because in load completed habit graph there is a check about current state
        currentAction = ._END_
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        refreshFocusModeData()
        
        closePupUpBlockIfVisible()
        
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        removeSubViews()
        closeEasyPostponeWindowIfVisible()
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        var lastActivityIndex = -1
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastCustomRoutineHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
                for i in 0..<arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.count{
                    if arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[i].id == lastSavedActivityId{
                        lastActivityIndex = i
                        break;
                    }
                }
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        
        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        
        if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastSavedActivityId == arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[index].id{
            addLog(text:"func startDirectIncompleteCustomRoutineHabitAtIndex:- app terminate In Running State:- start direct \(LogPrivacy.text(arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[index].name)) in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._CUSTOM_ROUTINE_
            currentAction = ._INPROGRESS_
            let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else if lastSavedActivityTime.compare(startDate) == .orderedDescending && lastActivityIndex != -1 && lastActivityIndex > index{//user can start random habit
            
            
            if lastActivityIndex != -1{//user can start random habit
                let habit = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits[lastActivityIndex]
                arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.remove(at: lastActivityIndex)
                arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits.insert(habit, at: index)
            }
            let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
            addLog(text:"func startDirectIncompleteCustomRoutineHabitAtIndex:- app terminate In Running State:- start direct \(LogPrivacy.text(arrFilteredMorningHabits[index].name)) in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._CUSTOM_ROUTINE_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else{
            addLog(text:"func startDirectIncompleteMorningHabitAtIndex:- morningHabitFinishedAndStartIncompleteNew")
            if index == 0{
                showRoutineAllHabits(routineIndex: currentRoutineIndex)
            }else{
                habitsView.addSubview(activityCompletionVcObj!.view)
                habitsView.addConstraints(subView: activityCompletionVcObj!.view)
                currentHabitIndex = index-1
                activityCompletionVcObj!.customRoutineHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
            }
            
        }
        
    }
    
    func showThirdVc(){
        removeSubViews()
        habitsView.addSubview(activityCompletionVcObj!.view)
        habitsView.addConstraints(subView: activityCompletionVcObj!.view)
    }
    
    func eveningHabitOver() {// current evening habit over
        addLog(text:"current evening Habit Over called")
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        getHabitsVcObject().stopActivityTimer()
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            leftMenuVcObj?.showHabitsView()
        }else{
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            leftMenuVcObj?.showHabitsView()
        }
        if isAnyAllowedFocusModeActivityRunning{
            closeNudgeFocusAlignmentScoreWindow()
        }
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        currentRelaxHabitPlaying = nil
        
        taskPlayerVcObj?.getToDosFromPlayer()
        
        leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
        refreshFocusModeData()
        setAppIconForFocusModeScore(probability: nil)
        
        closePupUpBlockIfVisible()
        
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        removeSubViews()
        //        if currentHabitIndex < arrFilteredEveningHabits.count-1 {
        habitsView.addSubview(activityCompletionVcObj!.view)
        habitsView.addConstraints(subView: activityCompletionVcObj!.view)
        activityCompletionVcObj!.eveningHabitFinished(index: currentHabitIndex)
        currentState = ._EVENING_HABIT_
        currentAction = ._END_
        
        if activityPostponeCount > 3{
            activityPostponeCount = 3//I complete a habit after postponing, it should go back to a 15 second postpone the next time
            savePostpneCount(state: ._EVENING_HABIT_)
        }
    }
    
    func startDirectIncompleteEveningHabitAtIndex(index:Int, isLastActivitySkipped:Bool, skippedActivities:[String], completedActivities:[String]) {
        addLog(text:"func startDirectIncompleteEveningHabitAtIndex")
        currentState = ._EVENING_HABIT_
        currentAction = ._END_
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        refreshFocusModeData()
        
        closePupUpBlockIfVisible()
        
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        removeSubViews()
        closeEasyPostponeWindowIfVisible()
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        
        var lastSavedActivityTime = Date()
        var lastSavedActivityProgress = 0
        var lastSavedActivityId = ""
        var lastActivityIndex = -1
        
        if isHighPrioritySequenceGoing{
            if !arrFilteredEveningHabits[index].isPriorityHigh{
                isLastActivityStoppedInRunningState = false
            }
        }
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitRunningInfo) as? [String:Any]{
            
            if let id =  infoDic["id"] as? String{
                lastSavedActivityId = id
            }
            if let duration =  infoDic["duration"] as? Int{
                lastSavedActivityProgress = duration
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedActivityTime = date
                for i in 0..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].id == lastSavedActivityId{
                        lastActivityIndex = i
                        if isHighPrioritySequenceGoing{
                            if !arrFilteredEveningHabits[lastActivityIndex].isPriorityHigh{
                                lastActivityIndex = -1
                            }
                            if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                let currentDate = Date()
                                if currentDate > cutOffDate{
                                    addLog(text: "evening habit skipped:- cutoff time for this incomplete habit passed:- \(LogPrivacy.text(arrFilteredEveningHabits[i].name))  \(arrFilteredEveningHabits[i].id ?? "")") // remove this
                                    lastActivityIndex = -1
                                }
                            }
                        }
                        
                        
                        break;
                    }
                }
            }else{
                lastSavedActivityId = ""
                lastSavedActivityProgress = 0
            }
        }
        let currentDate = Date()
        var shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: currentDate)!
        if currentDate < shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: tomorrowDate) ?? tomorrowDate
            
        }
        
        if isLastActivityStoppedInRunningState && lastActivityRunningId == arrFilteredEveningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- Activity Postpone In Running State:- start direct\(LogPrivacy.text(arrFilteredEveningHabits[index].name))in running state")
            
            currentHabitIndex = index
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastActivityStoppedTimerCount)
        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastSavedActivityId == arrFilteredEveningHabits[index].id{
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- app terminate In Running State:- start direct \(LogPrivacy.text(arrFilteredEveningHabits[index].name)) in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else if lastSavedActivityTime.compare(shutOffdate) == .orderedDescending && lastActivityIndex != -1 && lastActivityIndex > index{
            
            if lastActivityIndex != -1{//user can start random habit
                let habit = arrFilteredEveningHabits[lastActivityIndex]
                arrFilteredEveningHabits.remove(at: lastActivityIndex)
                arrFilteredEveningHabits.insert(habit, at: index)
            }
            
            isLastActivityStoppedInRunningState = false
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- app terminate In Running State:- start direct \(LogPrivacy.text(arrFilteredEveningHabits[index].name)) in running state")
            
            currentHabitIndex = index
            if lastSavedActivityProgress > arrFilteredEveningHabits[currentHabitIndex].durationSeconds{
                lastSavedActivityProgress = 0
            }
            habitsView.addSubview(timerViewcontrollerObj!.view)
            habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
            currentState = ._EVENING_HABIT_
            currentAction = ._INPROGRESS_
            timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:lastSavedActivityProgress)
            
            
        }else{
            addLog(text:"func startDirectIncompleteEveningHabitAtIndex:- eveningHabitFinishedAndStartIncompleteNew")
            isLastActivityStoppedInRunningState = false
            
            if index == 0{
                showAllEveningHabits()
            }else{
                currentHabitIndex = index-1
                if currentHabitIndex >= 0{
                    let lastHabit = arrFilteredEveningHabits[currentHabitIndex]
                    if let lastHabitId = lastHabit.id{
                        if !completedActivities.contains(lastHabitId) && !skippedActivities.contains(lastHabitId){
                            currentHabitIndex = -1
                        }
                    }
                }
                if currentHabitIndex != -1{
                    habitsView.addSubview(activityCompletionVcObj!.view)
                    habitsView.addConstraints(subView: activityCompletionVcObj!.view)
                    activityCompletionVcObj!.eveningHabitFinishedAndStartIncompleteNew(index: currentHabitIndex, isLastActivitySkipped:isLastActivitySkipped)
                }else{
                    showAllEveningHabits()
                }
            }
        }
    }
    
    func eveningHabitFinishShowUnlock(){//evening habit Sequence Finished
        addLog(text: "eveningHabitFinishShowUnlock")
        // #1982 follow-up: evening routine completed — clear the saved postponed-routine state so the
        // app doesn't restore the postponed habit list on the next launch.
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
        leftMenuVcObj?.habitOver()
        currentHabitIndex = -1
        hideBlankWindowInSecondaryMonitor()
        // Surface the "well done — sleep / shut down" prompt at the bottom of the Day Plan (#2005 part 4).
        // ONLY on the unlock path (before cutoff): here the old shutdown-time screen isn't shown yet, so
        // this prompt is the user's only way to sleep/shut down. The shutOff path (after cutoff) already
        // shows that screen, so eveningHabitFinishShowShutOff() must NOT set this.
        markEveningRoutineDoneForShutdownPrompt()
    }

    func eveningHabitFinishShowShutOff(){//evening habit Sequence Finished
        addLog(text: "evening habit Finished")
        // #1982 follow-up: evening routine completed — clear the saved postponed-routine state so the
        // app doesn't restore the postponed habit list on the next launch.
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
        leftMenuVcObj?.habitOver()
        shutOffMac()
        currentHabitIndex = -1
    }
    
    func specialActivityFinish(){//special Activity Sequence Finished
        addLog(text: "special Activity Finished")
        hideCloseButtons()
        removeSubViews()
        lblMessage.isHidden = true
        mainWindowControllerObj?.window?.close()
        hideBlankWindowInSecondaryMonitor()
        currentState = ._NOTHING_
    }
    
    func activityOver() {//current breaks activity Over
        addLog(text:"current activityOver called")
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            //mainViewControllerObj?.checkIsFullScreenNeeded()
            leftMenuVcObj?.showBreaksView()
        }else{
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            // mainViewControllerObj?.checkIsFullScreenNeeded()
            leftMenuVcObj?.showBreaksView()
        }
        if isAnyAllowedFocusModeActivityRunning{
            closeNudgeFocusAlignmentScoreWindow()
        }
        isAnyAllowedFocusModeActivityRunning = false
        currentActivityPlaying = nil
        closePupUpBlockIfVisible()
        
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        removeSubViews()
        habitsView.addSubview(activityCompletionVcObj!.view)
        habitsView.addConstraints(subView: activityCompletionVcObj!.view)
        activityCompletionVcObj!.activityFinished(index: currentActivityIndex)
        currentState = ._MICRO_BREAK_
        currentAction = ._END_
    }
    
    func specialActivityOver() {//current special activity Over
        addLog(text:"current specialActivity Over called")
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            leftMenuVcObj?.showHabitsView()
        }else{
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            leftMenuVcObj?.showHabitsView()
        }
        if isAnyAllowedFocusModeActivityRunning{
            closeNudgeFocusAlignmentScoreWindow()
        }
        isAnyAllowedFocusModeActivityRunning = false
        currentActivityPlaying = nil
        currentHabitPlaying = nil
        refreshFocusModeData()
        closePupUpBlockIfVisible()
        
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        removeSubViews()
        habitsView.addSubview(activityCompletionVcObj!.view)
        habitsView.addConstraints(subView: activityCompletionVcObj!.view)
        activityCompletionVcObj!.specialActivityFinished()
        currentState = ._SPECIAL_ACTIVITY_
        currentAction = ._END_
    }
    
    func customRoutineHabitOver() {
        addLog(text:"current custom routine Habit Over called")
        getHabitsVcObject().stopActivityTimer()
        if mainWindowControllerObj?.window?.isVisible == false{
            mainWindowControllerObj?.window?.setIsVisible(true)
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            leftMenuVcObj?.showCustomRoutineView()
        }else{
            showBlankWindowInSecondaryMonitor()
            setDocBarTo(isHide: false)
            leftMenuVcObj?.showCustomRoutineView()
        }
        
        if isAnyAllowedFocusModeActivityRunning{
            closeNudgeFocusAlignmentScoreWindow()
        }
        isAnyAllowedFocusModeActivityRunning = false
        currentHabitPlaying = nil
        
        
        taskPlayerVcObj?.getToDosFromPlayer()
        
        leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
        refreshFocusModeData()
        setAppIconForFocusModeScore(probability: nil)
        
        closePupUpBlockIfVisible()
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        self.showCloseButtons()
        removeSubViews()
        habitsView.addSubview(activityCompletionVcObj!.view)
        habitsView.addConstraints(subView: activityCompletionVcObj!.view)
        activityCompletionVcObj!.customRoutineHabitFinished(index: currentHabitIndex)
        currentState = ._CUSTOM_ROUTINE_
        currentAction = ._END_
    }
    
    
    func changeCustomRoutineHabit() {//start another Custom habit
        addLog(text:"current change Custom Routine Habit called")
        self.showCloseButtons()
        removeSubViews()
        currentHabitIndex += 1
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrHabits[currentHabitIndex].durationSeconds, name: arrHabits[currentHabitIndex].name!, currentHabit: arrHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._CUSTOM_ROUTINE_
        currentAction = ._INPROGRESS_
    }
    
    func changeMorningHabit() {//start another morning habit
        addLog(text:"current change Morning Habit called")
        self.showCloseButtons()
        removeSubViews()
        currentHabitIndex += 1
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredMorningHabits[currentHabitIndex].durationSeconds, name: arrFilteredMorningHabits[currentHabitIndex].name!, currentHabit: arrFilteredMorningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    func changeEveningHabit() {
        addLog(text:"current change Evening Habit called")
        self.showCloseButtons()
        removeSubViews()
        currentHabitIndex += 1
        if isHighPrioritySequenceGoing{
            var newIndexFound = false
            while !newIndexFound{
                if let cutOffTime = arrFilteredEveningHabits[currentHabitIndex].cutOffTime{
                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                    let currentDate = Date()
                    if currentDate < cutOffDate{
                        if arrFilteredEveningHabits[currentHabitIndex].isPriorityHigh{
                            newIndexFound = true
                        }else{
                            addLog(text: "evening habit skipped:- this next habit is not High Priority habit:- \(LogPrivacy.text(arrFilteredEveningHabits[currentHabitIndex].name))  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
                            currentHabitIndex = currentHabitIndex + 1
                        }
                    }else{
                        addLog(text: "evening habit skipped:- cutoff time for this next habit passed:- \(LogPrivacy.text(arrFilteredEveningHabits[currentHabitIndex].name))  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
                        currentHabitIndex = currentHabitIndex + 1
                    }
                }else{
                    if arrFilteredEveningHabits[currentHabitIndex].isPriorityHigh{
                        newIndexFound = true
                    }else{
                        addLog(text: "evening habit skipped:- this next habit is not High Priority habit and this habit has no cutOffTime:- \(LogPrivacy.text(arrFilteredEveningHabits[currentHabitIndex].name))  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
                        currentHabitIndex = currentHabitIndex + 1
                    }
                    
                }
            }
        }
        
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: arrFilteredEveningHabits[currentHabitIndex].durationSeconds, name: arrFilteredEveningHabits[currentHabitIndex].name!, currentHabit: arrFilteredEveningHabits[currentHabitIndex], currentTimerValue:0)
        currentState = ._EVENING_HABIT_
        currentAction = ._INPROGRESS_
    }
    
    func startSpecialActivity(duration:Int,habit:habit?, activity:breakActivity?){//start special activity
        addLog(text: "func:- startSpecialActivity")
        closeEasyPostponeWindowIfVisible()
        if isFocusModeOnOrPaused(){
            addLog(text: "Special Activity start:- Focus Mode Finished")
            appdelegate?.tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
            
        }
        mainWindowControllerObj?.showWindow(self)
        showBlankWindowInSecondaryMonitor()
        
        currentState = ._SPECIAL_ACTIVITY_
        currentAction = ._INPROGRESS_
        self.showCloseButtons()
        removeSubViews()
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        
        var currentChoice:activityChoice?
        if activity != nil{
            if activity!.choiceType == ._RANDOM_{
                if let randomChoice = activity!.choices.randomElement(){
                    currentChoice = randomChoice
                }
            }
        }
        
        timerViewcontrollerObj?.startSpecialActivity(durationSeconds: duration, currentHabit: habit, currentActivity: activity, currentChoice: currentChoice)
    }
    
    func startCurrentActivity() {//start break activity
        allApiObject.capturePosthog(event: "start-break-activity", metadata: ["routine-type":"break_activity"])
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastBreaksStartTime)
        addLog(text:"start Current Activity called")
        self.showCloseButtons()
        removeSubViews()
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        currentActivityIndex += 1
        if arrFinalBreakActivities.count <= currentActivityIndex{
            currentActivityIndex = arrFinalBreakActivities.count - 1// crash solved
        }
        let activity = arrFinalBreakActivities[currentActivityIndex]
        let currentActivity = activity.activity!
        if let randomChoice = activity.randomChoice{//currentActivity.choices.randomElement(){
            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestions, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
        }else{
            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestions, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
        }
        
        currentState = ._MICRO_BREAK_
        currentAction = ._INPROGRESS_
    }
    
    
    func changeActivity() {//start another break activity
        addLog(text:"current change Activity called")
        self.showCloseButtons()
        removeSubViews()
        habitsView.addSubview(timerViewcontrollerObj!.view)
        habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        
        currentActivityIndex += 1
        
        let activity = arrFinalBreakActivities[currentActivityIndex]
        let currentActivity = activity.activity!
        if let randomChoice = activity.randomChoice{//currentActivity.choices.randomElement(){
            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: randomChoice.name, urlsArray: randomChoice.urlsArray, logQuantityQuestion: randomChoice.logQuantityQuestions, currentActivity: currentActivity, currentChoice: randomChoice, logQuantity: randomChoice.logQuantity, logQuantityType: randomChoice.logQuantityType)
        }else{
            timerViewcontrollerObj?.startTimerActivity(durationInSeconds: currentActivity.durationSeconds, name: currentActivity.name!, urlsArray: currentActivity.urlsArray, logQuantityQuestion: currentActivity.logQuantityQuestions, currentActivity: currentActivity, currentChoice: nil, logQuantity: currentActivity.logQuantity, logQuantityType: currentActivity.logQuantityType)
        }
        
        currentState = ._MICRO_BREAK_
        currentAction = ._INPROGRESS_
    }
    
    func habitsFinishedUnlockMachine() {
        addLog(text: "morning habit Finished")

        // #1982 follow-up: morning routine completed — clear the saved postponed-routine state so the
        // app doesn't restore the postponed habit list on the next launch.
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        SensitiveDefaults.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
        hideCloseButtons()
        removeSubViews()
        // Morning routine done: no "stay focused for the day" message — the app stays open on the Day
        // Plan instead (set below), so this end-of-routine text is redundant.
        lblMessage.isHidden = true
        currentHabitIndex = -1


        unfocusedTime = 0
        let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool ?? false
        if state && SettingsManagerObject.isGeekModeEnabled{
            appdelegate?.showMorningPomodoroModeView()
            unlockMachineWork()
            hideBlankWindowInSecondaryMonitor()
        }else if SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled{
            showBrainDumpWindow()
            unlockMachineWork()
            hideBlankWindowInSecondaryMonitor()
        }else{
            // Don't auto-close the routine window (which read like the app quitting). Do the normal
            // unlock cleanup WITHOUT closing the window, then open the Day Plan so the user lands there.
            unlockMachineWork()
            hideBlankWindowInSecondaryMonitor()
            // Clear the morning-routine state BEFORE opening the Day Plan: showDayPlanForCurrentState()
            // early-returns (leaving the area blank) while currentState still reads ._MORNING_HABIT_,
            // which is the case here until line below. Set it now so the Day Plan actually populates.
            currentState = ._NOTHING_
            menuViewControllerObj?.openDayPlanSchedule()
        }

        currentState = ._NOTHING_
        
        // FIX: Moved leftMenuVcObj?.habitOver() above all return statements to prevent early exit bug present before v3.31.479
        // (Previously placed below showSurveyWindow()'s return, causing habitOver() to be skipped)
        // bug:- feedback_message: Blocked from starting focus session after completing morning routine
        leftMenuVcObj?.habitOver()
        
        let currentDate = Date()
        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
        let diffDays = Calendar.current.dateComponents([.day], from: firstRunDate, to: currentDate).day ?? 0
        
        if diffDays > 2{
            if UserDefaults.standard.object(forKey: kUserdefaultsEnableScreenTimeShown) == nil &&  UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabledOneTime) == nil{
                UserDefaults.standard.set(true, forKey: kUserdefaultsEnableScreenTimeShown)
                showTimeTrackerWindow(showingAutomatically:true)
                return;
            }
        }
        
        if diffDays > 3{
            if UserDefaults.standard.object(forKey: kUserdefaultsSurveyShown) == nil{
                UserDefaults.standard.set(true, forKey: kUserdefaultsSurveyShown)
                showSurveyWindow()
                return;
            }
        }
        
        
        if diffDays > 10{
            if UserDefaults.standard.object(forKey: kUserdefaultsGetLateNoMoreShown) == nil{
                UserDefaults.standard.set(true, forKey: kUserdefaultsGetLateNoMoreShown)
                showLateNoMoreWindow()
            }
        }
    }
    
    
    @objc func unlockMachine() {
        addLog(text:"current unlockMachine called")
        mainWindowControllerObj?.window?.close()
        hideBlankWindowInSecondaryMonitor()
        unlockMachineWork()
    }
    
    func unlockMachineWork(){
        lblMessage.isHidden = true
        
        activityPostponeCount = 0
        activitySkipCount = 0
        if isFirstRun{//welcome routine k baad set krenge (when first time)
            UserDefaults.standard.removeObject(forKey: kUserdefaultsPasswordSetInOnboarding)
            SettingsManagerObject.isFullScreenEnabled = false
            SettingsManagerObject.storedCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = true
            SettingsManagerObject.doNotBlockUrlsDuringSuperPomodoroBreaksDefaultValue = true
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
            SettingsManagerObject.immediatelyBlockDistractingSites = false
            SettingsManagerObject.immediatelyBlockDistractingApps = false
            
            SettingsManagerObject.isGeekModeEnabled = false // for new user app is in simple mode
            
            if UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool == false{
                UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
            }
            appdelegate!.needToCheckEmailVerification = false// if onboarding then dont show till menu tour is over
            appdelegate!.getUserSubscriptionInfo()
            appdelegate!.statusbutton?.action = nil
            UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
        }else{
            setActivityTimer()
        }
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
            }
        }
    }
    
    func stopActivityTimer(){
        if breakTimer != nil{
            breakTimer?.invalidate()
            breakTimer = nil
            if isWaitingForInactivityToStartMicroBreak{
                self.breakInactivitySecondsToCheck = 5
                self.isWaitingForInactivityToStartMicroBreak = false
                self.inActivityStartTime = nil
                setFocusBearIconToNormal()
            }
            
            addLog(text: "stopActivityTimer")
        }
    }
    
    func setActivityTimer(forceReset: Bool = false){
        // Only restart the break countdown to a full interval when the user actually takes a break (in
        // Focus Bear or a natural break) or postpones one — those callers pass forceReset:true. Plain
        // app-state transitions (focus mode changing, routine checks, waking from sleep, returning to
        // idle, etc.) call this WITHOUT forceReset, so a break that's already counting down is not
        // pushed back to a full interval each time the app re-evaluates state.
        if !forceReset, let runningTimer = breakTimer, runningTimer.isValid {
            addLog(text: "setActivityTimer: break countdown already running — keeping it (no forceReset).")
            return
        }
        if arrAllbreakActivities.count != 0 {
            // The break countdown schedules toward a PERSISTED "next break due" wall-clock time
            // (kUserdefaultsNextBreakDueTime). Only a forced reset — the user actually took/finished a
            // break or postponed one — restarts a fresh full interval and moves that due date. Every other
            // caller (pause/resume, settings reload, a deferred break re-checking) reschedules toward the
            // SAME due date, so a countdown that's already partway through is not thrown away and restarted
            // each time the app re-evaluates state. Without this, once the last real break drifts older than
            // one interval the countdown perpetually resets and breaks stop firing entirely.
            let fullInterval = TimeInterval(breakAfterMinutes * 60)
            guard fullInterval > 0 else {
                addLog(text: "Break Activity Timer: breakAfterMinutes is \(breakAfterMinutes) — no break scheduled.")
                return
            }
            let now = Date()
            let dueDefaults = UserDefaults.standard
            var interval = fullInterval
            var dueNote = ""
            // The lastBreakEndTime floor below exists to stop a break firing seconds after a break was
            // TAKEN (a completed break leaves an overdue due date + short-retry). It must NOT clamp a due
            // date that's still in the FUTURE — a postpone ("remind me in 10 min") or a normal countdown
            // resumed after a lock — otherwise it would push those out to a full interval. So only floor
            // the overdue / seed cases.
            var applyBreakFloor = true

            if forceReset {
                dueDefaults.set(now.addingTimeInterval(fullInterval), forKey: kUserdefaultsNextBreakDueTime)
                interval = fullInterval
                dueNote = "forceReset → fresh full interval"
            } else if let due = dueDefaults.object(forKey: kUserdefaultsNextBreakDueTime) as? Date {
                let remaining = due.timeIntervalSince(now)
                if remaining > fullInterval {
                    // Remaining is longer than a whole interval — the interval was shortened (server
                    // settings change). Cap to the new full interval so we don't wait longer than one.
                    dueDefaults.set(now.addingTimeInterval(fullInterval), forKey: kUserdefaultsNextBreakDueTime)
                    interval = fullInterval
                    dueNote = "remaining \(Int(remaining))s exceeds interval (settings change?) → capped to full interval"
                    applyBreakFloor = false   // future due — don't floor it out
                } else if remaining > 0 {
                    // Preserve progress across the stop/reschedule — this is the key fix.
                    interval = remaining
                    dueNote = "preserved remaining \(Int(remaining))s toward existing due date"
                    applyBreakFloor = false   // future due (incl. a postpone) — respect it, don't floor
                } else if remaining < -(fullInterval * breakStaleOverdueIntervalMultiple) {
                    // Overdue by more than one interval (app closed a long time / overnight) — stale.
                    // Start fresh so a yesterday break doesn't fire moments after launch.
                    dueDefaults.set(now.addingTimeInterval(fullInterval), forKey: kUserdefaultsNextBreakDueTime)
                    interval = fullInterval
                    dueNote = "stale due date (overdue \(Int(-remaining))s) → fresh full interval"
                } else {
                    // Due/recently overdue — fire as soon as conditions allow, keep the due date.
                    interval = TimeInterval(breakRetryWhenDueSeconds)
                    dueNote = "break due (overdue \(Int(-remaining))s) → short retry, due date preserved"
                }
            } else {
                // First schedule with no persisted due date: seed it, carrying over a RECENT last break
                // (one within the current interval) so first-schedule-after-launch behaves as before — a
                // stale/yesterday break falls through to a fresh full interval, not the 60s floor.
                if let elapsed = secondsSinceLastBreakEnd(), elapsed > 0, elapsed < Int(fullInterval) {
                    interval = max(fullInterval - Double(elapsed), 60)
                }
                dueDefaults.set(now.addingTimeInterval(interval), forKey: kUserdefaultsNextBreakDueTime)
                dueNote = "no persisted due date → carry-over from last break, seeded due date"
            }
            // A break RECORDED since we last scheduled resets the clock: the next break must not come before
            // lastBreakEndTime + fullInterval. Any break-completion path (a Focus Bear micro-break, a natural
            // break) writes lastBreakEndTime; not all of them call forceReset. Without this floor, finishing a
            // break leaves the (now-overdue) persisted due date in place and the short-retry fires ANOTHER
            // break seconds later ("time since last break: 0m" → a fresh break). Only applies to a RECENT
            // break (elapsed < one interval); a stale/old break doesn't push the due date out.
            if applyBreakFloor, !forceReset, let elapsed = secondsSinceLastBreakEnd(), elapsed >= 0, elapsed < Int(fullInterval) {
                let intervalFromBreak = fullInterval - Double(elapsed)
                if intervalFromBreak > interval {
                    interval = intervalFromBreak
                    dueDefaults.set(now.addingTimeInterval(interval), forKey: kUserdefaultsNextBreakDueTime)
                    dueNote += " | floored to a full interval from a break \(elapsed)s ago"
                }
            }
            // Never schedule below the short-retry floor (guards against a 0s/near-0s remaining busy-loop).
            interval = max(interval, TimeInterval(breakRetryWhenDueSeconds))
            addLog(text: "Break Activity Timer reset Done. Next break in \(Int(interval))s (interval \(breakAfterMinutes)m; \(dueNote)).")
            DispatchQueue.global().sync {
                stopActivityTimer()
                self.breakTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)

                RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
            }
        }
    }

    /// A break came due but can't be shown right now (meeting / focus session / presentation / active
    /// blocking schedule / routine in progress). The user hasn't taken a break, so don't reset to a full
    /// interval — re-check shortly so the break fires soon after the blocking condition clears.
    func rescheduleBreakSoonAfterBlocked(){
        if arrAllbreakActivities.count != 0 {
            DispatchQueue.global().sync {
                stopActivityTimer()
                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(breakRetryWhenBlockedSeconds), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)
                RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
            }
        }
    }
    var isBreakActivityPostponeInsideAllowedHabit = false// using this beacuse we dont want reset activity timer again (in resuming habit) if user has postponed activity inside allow app habit
    func postponeBreakActivitiesFor(minutes:Int, secondsToPostpone:Int?, isFromBreakWarningWindow:Bool){
        // Postponing a running activity stops it — tell the Focus Button so it
        // doesn't keep counting down (matches postponeMorning/EveningHabitFor).
        if currentAction == ._INPROGRESS_ {
            focusButtonServiceObject.cancelHabit()
        }
        var seconds = 0
        if secondsToPostpone != nil{
            seconds = secondsToPostpone!
            if seconds == 0 && minutes != 0{
                seconds = minutes*60
            }
        }else{
            seconds = minutes*60
        }
        
        addLog(text: "postpone Break Activities, Timer reset Done:- \(seconds) seconds")
        hideCloseButtons()
        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
        
        // isFromBreakWarningWindow added on 24/7/25 v 1.26.394
        if currentAction != ._START_ && currentAction != ._BRAIN_DUMP_ && !isFromBreakWarningWindow{
            if let startTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreaksStartTime) as? Date{
                let currentDate = Date()
                let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: currentDate).second ?? 0
                if diffSeconds > 0{
                    var arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
                    arrDuration.append(diffSeconds)
                    UserDefaults.standard.set(arrDuration, forKey: kUserdefaultsArrayBreaksDurations)
                }
                UserDefaults.standard.set(currentDate, forKey: kUserdefaultsLastBreakEndTime)
            }
        }
        if !isFromBreakWarningWindow{
            removeSubViews()
        }
        
        currentState = ._NOTHING_
        
        if !isFromBreakWarningWindow{
            leftMenuVcObj?.microBreaksOver()
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
        }
        
        if arrAllbreakActivities.count != 0 {
            // Persist the postpone target as the next-break due time so it survives a stop/reschedule —
            // e.g. a screen-lock/sleep pauses (nils) the live breakTimer below, and on unlock
            // setActivityTimer reschedules from the PERSISTED due date. Without this it read the stale
            // pre-postpone due date and the break came due far too soon after a postpone.
            UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(seconds)), forKey: kUserdefaultsNextBreakDueTime)
            DispatchQueue.global().sync {//async {
                print("breakAfterMinutesxxxx")
                stopActivityTimer()
                self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)//  seconds kro
                RunLoop.main.add((breakTimer!), forMode: RunLoop.Mode.common)
            }
        }
        if popUpCheckListWcObj != nil{
            if popUpCheckListWcObj?.window?.isVisible ?? false{
                popUpCheckListWcObj?.window?.close()
            }
        }
        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
            isBreakActivityPostponeInsideAllowedHabit = true
            DispatchQueue.global().async {
                sleep(5)
                self.isBreakActivityPostponeInsideAllowedHabit = false
            }
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            appdelegate!.backgroundThread()
        }
        if isBreakActivityExecuteFromPostponeMorningHabit{
            currentState = ._POSTPONE_MORNING_HABIT_
            isBreakActivityExecuteFromPostponeMorningHabit = false
        }
        
        if isBreakActivityExecuteFromPostponeEveningHabit{
            currentState = ._POSTPONE_EVENING_HABIT_
            isBreakActivityExecuteFromPostponeEveningHabit = false
        }
        writeStringToHabitInfo(isFinishTime: true, activityName: "")
    }
    
    
    func breaksScreenIsIdleResetBreaks(){
        addLog(text: "breaksScreenIsIdleResetBreaks")
        allApiObject.capturePosthog(event: "break-cancelled-due-to-user-inactivity", metadata: [:])
        hideCloseButtons()
        removeSubViews()
        activityPostponeCount = 0
        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
        print(infoDic)
        currentActivityIndex = -1
        unlockMachine()
        currentState = ._NOTHING_
        leftMenuVcObj?.microBreaksOver()
        if shouldShowPomodoroAfterBreak{
            shouldShowPomodoroAfterBreak = false
            if SettingsManagerObject.isGeekModeEnabled{
                if let date = shouldEndPomodoroBreakAtTime{
                    let currentDate = Date()
                    if currentDate > date{
                        appdelegate!.showAutoPomodoroModeView()
                    }else{
                        let diffSeconds = Calendar.current.dateComponents([.second], from: currentDate, to: date).second ?? 0
                        appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(diffSeconds))
                        showSmallTimerWindow(durationSeconds: diffSeconds, msg: "", isFocusBreak: true, currentTimerValue:0)
                        if isAppEnable{
                            isFocusBreakOn = true
                        }
                    }
                }else{
                    appdelegate!.showAutoPomodoroModeView()
                }
            }
        }
        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            addLog(text: "breaksScreenIsIdleResetBreaks:- Try resume Habit Routine")
            appdelegate!.backgroundThread()
        }
        if isBreakActivityExecuteFromPostponeMorningHabit{
            currentState = ._POSTPONE_MORNING_HABIT_
            isBreakActivityExecuteFromPostponeMorningHabit = false
            addLog(text: "breaksScreenIsIdleResetBreaks:- activity was started from postpone morning habit. Try postpone Habit Routine")
        }
        if isBreakActivityExecuteFromPostponeEveningHabit{
            currentState = ._POSTPONE_EVENING_HABIT_
            isBreakActivityExecuteFromPostponeEveningHabit = false
            addLog(text: "breaksScreenIsIdleResetBreaks:- activity was started from postpone evening habit. Try postpone Habit Routine")
        }
        writeStringToHabitInfo(isFinishTime: true, activityName: "")
    }
    
    func savePostpneCount(state:CURRENTSTATE){
        if state == ._MORNING_HABIT_{
            if arrFilteredMorningHabits.count != 0 {
                let infoDic:[String:Any] = ["sequenceId":arrFilteredMorningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":Date()]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
                print(infoDic)
            }
        }else if state == ._EVENING_HABIT_{
            if arrFilteredEveningHabits.count != 0 {
                
                var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                
                let curreentDate = Date()
                if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                    startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? startDate
                    
                }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                    
                }
                
                let infoDic:[String:Any] = ["sequenceId":arrFilteredEveningHabits[0].activity_sequence_id ?? "", "postponeCount":activityPostponeCount, "date":startDate]
                UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastSequencePostponeInfo)
                print(infoDic)
            }
        }
    }
    func refreshLastPostponeCount(){
        var lastSavedPostponeTime = Date()
        activityPostponeCount = 0
        var lastSavedPostponeCount = activityPostponeCount
        var lastSavedSequenceId = ""
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequencePostponeInfo) as? [String:Any]{
            
            if let id =  infoDic["sequenceId"] as? String{
                lastSavedSequenceId = id
            }
            if let postponeCount =  infoDic["postponeCount"] as? Int{
                lastSavedPostponeCount = postponeCount
            }
            if let date =  infoDic["date"] as? Date{
                lastSavedPostponeTime = date
            }
        }
        if currentState == ._MORNING_HABIT_{
            if arrFilteredMorningHabits.count != 0 {
                if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                    activityPostponeCount = lastSavedPostponeCount
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            if arrFilteredEveningHabits.count != 0 {
                if lastSavedSequenceId == arrFilteredEveningHabits[0].activity_sequence_id && lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                    activityPostponeCount = lastSavedPostponeCount
                }
            }
        }
    }
    /// Help/Settings navigation detaches the Day Plan without ending its routine. After password
    /// authentication the next approval sheet must use the window that is still on screen.
    func postponeIntentionPresenter() -> NSViewController? {
        guard let window = mainWindowControllerObj?.window,
              window.isVisible, !window.isMiniaturized else { return nil }
        if isViewLoaded, view.window === window { return self }
        guard let root = window.contentViewController,
              root.isViewLoaded, root.view.window === window else { return nil }
        return root
    }

    func postponeMorningHabitFor(minutes:Int, secondsToPostpone:Int?, showAskFocusModeView:Bool, showAskIntention:Bool, isExtendingPostponeFromAppStart:Bool = false){
        var showAskIntention = showAskIntention
        
        // Super-gentle drops the postpone-intention prompt — but NOT when the AI accountability buddy is
        // on. That setting is an explicit "gate my postpones through the buddy", so it must always show the
        // chat, even if the aggregate strictness vote lands on super-gentle (e.g. full-screen off tips the
        // tie-break there). Without the buddy setting, behaviour is unchanged. (#2636)
        if SettingsManagerObject.isStrictnessLevelSuperGentle() && !SettingsManagerObject.isAccountabilityBuddyActive{
            addLog(text: "postponeMorningHabitFor:- strictness level is super gentle so don't show postpone Intention view")
            showAskIntention = false
        }
        if showAskIntention{
            if let presenter = postponeIntentionPresenter(){
                if SettingsManagerObject.isAccountabilityBuddyActive{
                    // AI accountability buddy: gate the postpone via the chat (sheet, so it shows over the
                    // full-screen routine). Only its approval actually postpones (showAskIntention:false).
                    addLog(text: "postponeMorningHabitFor:- AI accountability buddy")
                    AccountabilityBuddyChatViewController.present(over: presenter, initialGoal: "",
                        onApproved: { [weak self] goal, duration in
                            self?.postponeMorningHabitFor(minutes: duration, secondsToPostpone: nil, showAskFocusModeView: showAskFocusModeView, showAskIntention: false)
                            if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled && !goal.isEmpty{
                                pomodoroVcObj?.isIntentionFromMorningPostpone = true
                                // The start screen is SwiftUI now — use its shims, not the removed outlets.
                                pomodoroVcObj?.goalText = goal
                                pomodoroVcObj?.showPostponeTitle()
                            }
                        },
                        onCancel: { [weak self] in self?.showCloseButtons() })   // gave up — habit not postponed, routine continues; restore the exit/close button abortCurrentState() hid
                }else{
                    addLog(text: "postponeMorningHabitFor:- askPostponeIntention")// added in 2.28.444
                    presenter.presentAsSheet(getAskPostponeIntentionVcObject())
                    askPostponeIntentionVcObj?.resetData(minutes: minutes, secondsToPostpone: secondsToPostpone, showAskFocusModeView: showAskFocusModeView, lastCurrentState: ._MORNING_HABIT_)
                }
            }else{
                addLog(text: "postponeMorningHabitFor:- window is nil")// added in 2.28.444
            }
        }else{
            var seconds = 0
            if secondsToPostpone != nil{
                seconds = secondsToPostpone!
                if seconds == 0 && minutes != 0{
                    seconds = minutes*60
                }
            }else{
                seconds = minutes*60
            }
            addLog(text: "postpone morning habits, Timer reset Done:- \(seconds) seconds")
            savePostpneCount(state: ._MORNING_HABIT_)
            
            if currentState != ._CUSTOM_ROUTINE_{
                if currentAction == ._INPROGRESS_{
                    isLastActivityStoppedInRunningState = true
                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                }else{
                    isLastActivityStoppedInRunningState = false
                    lastActivityRunningId = ""
                }
                //Extend postpone time not working for 2 minute warning popup#923
                if currentState == ._POSTPONE_MORNING_HABIT_{
                    closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
                }
                
                if !isFocusModeOn(){
                    leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
                }
                currentState = ._POSTPONE_MORNING_HABIT_
                hideBlankWindowInSecondaryMonitor()
                //focusButtonService-------//
                focusButtonServiceObject.cancelHabit()
                //---------//
            }
            
            closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            
            if popUpCheckListWcObj != nil{
                if popUpCheckListWcObj?.window?.isVisible ?? false{
                    popUpCheckListWcObj?.window?.close()
                }
            }
            
            if completionRequirementsWcObj != nil{
                if completionRequirementsWcObj?.window?.isVisible ?? false{
                    completionRequirementsWcObj?.window?.close()
                }
            }
            
            if currentState != ._CUSTOM_ROUTINE_{
                if isAnyAllowedFocusModeActivityRunning{
                    closeNudgeFocusAlignmentScoreWindow()
                }
                isAnyAllowedFocusModeActivityRunning = false
                isAllowedActivityHabitPlaying = false   // #2050: clear alongside so a postponed allowed-activity habit doesn't leave minimise in "background without postpone" mode
                currentHabitPlaying = nil
                if !isFocusModeOn(){
                    refreshFocusModeData()
                    setAppIconForFocusModeScore(probability: nil)
                }
                closePupUpBlockIfVisible()
                
                habitBlockTimerHelper.stopUrlTimer()
                appdelegate?.timerAllowAppForActivity?.invalidate()
            }
            
            if arrFilteredMorningHabits.count != 0 {
                DispatchQueue.global().sync{//async {
                    if self.postponeTimer != nil{
                        self.postponeTimer?.invalidate()
                        self.postponeTimer = nil
                    }
                    self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.resumeMorningHabit), userInfo: nil, repeats: false)//  seconds
                    RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
                    
                    
                    // saving postpone information //Remember postpone status when app is restarted #1582  v 2.28.454
                    let postponeEndDate = Date().addingTimeInterval(TimeInterval(seconds))
                    UserDefaults.standard.set(postponeEndDate, forKey: kUserDefaultsLastRoutinePostponeEndDate)
                    UserDefaults.standard.set(CURRENTSTATE._POSTPONE_MORNING_HABIT_.rawValue,forKey: kUserDefaultsLastRoutinePostponeState)
                    
                    if seconds > MeetingPostponeRules.endNotificationLeadSeconds{
                        setPostponeNotificationTimer(duration: (seconds - MeetingPostponeRules.endNotificationLeadSeconds))
                    }
                }
            }
            
            // check for breaktimer nil becasuse whenever user extended focus session for another 15 minutes it also extent postpone duration and then breaks always reset so if break timer is nil then only set it. this willl solve (reset breaktimer awalys and break didn't come ) problem #1272
            if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                if breakTimer == nil{
                    setActivityTimer()
                }
            }
            if currentState != ._CUSTOM_ROUTINE_{
                if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled{
                    appdelegate?.menuShowPomodoroModeView()
                    if !(pomodoroVcObj?.isViewLoaded ?? false){
                        pomodoroVcObj?.loadView()
                    }
                    pomodoroVcObj!.workDurationMinutes = minutes - 1
                    pomodoroVcObj!.updateBreakDuration()
                    pomodoroVcObj!.showPostponeTitle()
                    
                }else{
                    if !(leftMenuVcObj?.boxFocusSession.isSelected ?? false){// without this check app is crashing because add task vc dissmiss cause crash because that view will be change before dissmiss v 2.28.440
                        removeSubViews()
                        leftMenuVcObj?.showHabitsView()
                        habitsVcObj?.showHabitState()
                    }
                }
            }
            writeStringToHabitInfo(isFinishTime: true, activityName: "")
            if !isExtendingPostponeFromAppStart{
                saveRemainingHabitIdForPostponedRoutineList(state: ._MORNING_HABIT_)
            }
            menuViewControllerObj?.reloadIfNeeded()
            leftMenuVcObj?.habitOver()
        }
    }
    
    func postponeCustomRoutineFor(minutes:Int, secondsToPostpone:Int?, showAskFocusModeView:Bool, showAskIntention:Bool, fromRoutineWarning:Bool){
        // Postponing a running activity stops it — tell the Focus Button so it
        // doesn't keep counting down (matches postponeMorning/EveningHabitFor).
        if currentAction == ._INPROGRESS_ {
            focusButtonServiceObject.cancelHabit()
        }
        var seconds = 0
        if secondsToPostpone != nil{
            seconds = secondsToPostpone!
            if seconds == 0 && minutes != 0{
                seconds = minutes*60
            }
        }else{
            seconds = minutes*60
        }
        addLog(text: "postpone Custom habits ")
        
        
        if !fromRoutineWarning{
            hideCloseButtons()
            removeSubViews()
        }
        
        if !isFocusModeOn(){
            leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
        }
        
        
        if !fromRoutineWarning{
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
        }
        currentState = ._NOTHING_
        
        if currentHabitPlaying != nil{
            closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
        }
        
        if popUpCheckListWcObj != nil{
            if popUpCheckListWcObj?.window?.isVisible ?? false{
                popUpCheckListWcObj?.window?.close()
            }
        }
        
        if isAnyAllowedFocusModeActivityRunning{
            closeNudgeFocusAlignmentScoreWindow()
        }
        isAnyAllowedFocusModeActivityRunning = false
        isAllowedActivityHabitPlaying = false   // #2050: clear alongside so a postponed allowed-activity habit doesn't leave minimise in "background without postpone" mode
        currentHabitPlaying = nil

        if !isFocusModeOn(){
            refreshFocusModeData()
            setAppIconForFocusModeScore(probability: nil)
        }
        closePupUpBlockIfVisible()
        
        habitBlockTimerHelper.stopUrlTimer()
        appdelegate?.timerAllowAppForActivity?.invalidate()
        
        if !arrAllCustomRoutine[currentRoutineIndex].triggerOnDemand{
            let currentDate = Date()
            let secondsToAdd: TimeInterval = TimeInterval(seconds)
            let nextSheduledTime = Calendar.current.date(byAdding: .second, value: Int(secondsToAdd), to: currentDate)
            arrAllCustomRoutine[currentRoutineIndex].nextSheduledTime = nextSheduledTime
        }
        
        menuViewControllerObj?.reloadIfNeeded()
        isCustomRoutineWasRunningBetweenMorningHabit = false
        isCustomRoutineWasRunningBetweenEveningHabit = false
        leftMenuVcObj?.habitOver()
    }
    
    
    func postponeEveningHabitFor(minutes:Int, secondsToPostpone:Int?, showAskFocusModeView:Bool, showAskIntention:Bool, isExtendingPostponeFromAppStart:Bool = false){
        var showAskIntention = showAskIntention
        
        // Super-gentle drops the intention prompt — but not when the AI accountability buddy is on, which
        // must always gate the postpone through its chat regardless of the strictness vote. (#2636)
        if SettingsManagerObject.isStrictnessLevelSuperGentle() && !SettingsManagerObject.isAccountabilityBuddyActive{
            addLog(text: "postponeEveningHabitFor:- strictness level is super gentle so don't show postpone Intention view")// log was postponeMorningHabitFor before 2.27.428
            showAskIntention = false
        }
        
        if showAskIntention{
            if let presenter = postponeIntentionPresenter(){
                if SettingsManagerObject.isAccountabilityBuddyActive{
                    addLog(text: "postponeEveningHabitFor:- AI accountability buddy")
                    AccountabilityBuddyChatViewController.present(over: presenter, initialGoal: "",
                        onApproved: { [weak self] goal, duration in
                            self?.postponeEveningHabitFor(minutes: duration, secondsToPostpone: nil, showAskFocusModeView: showAskFocusModeView, showAskIntention: false)
                            if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled && !goal.isEmpty{
                                pomodoroVcObj?.isIntentionFromMorningPostpone = true
                                // The start screen is SwiftUI now — use its shims, not the removed outlets.
                                pomodoroVcObj?.goalText = goal
                                pomodoroVcObj?.showPostponeTitle()
                            }
                        },
                        onCancel: { [weak self] in self?.showCloseButtons() })   // gave up — restore the exit/close button abortCurrentState() hid
                }else{
                    addLog(text: "postponeEveningHabitFor:- askPostponeIntention")// added in 2.28.444
                    presenter.presentAsSheet(getAskPostponeIntentionVcObject())
                    askPostponeIntentionVcObj?.resetData(minutes: minutes, secondsToPostpone: secondsToPostpone, showAskFocusModeView: showAskFocusModeView, lastCurrentState: ._EVENING_HABIT_)
                }
            }else{
                addLog(text: "postponeEveningHabitFor:- window is nil")// added in 2.28.444
            }
        }else{
            var seconds = 0
            if secondsToPostpone != nil{
                seconds = secondsToPostpone!
                if seconds == 0 && minutes != 0{
                    seconds = minutes*60
                }
            }else{
                seconds = minutes*60
            }
            // Report 2026-09-17_17-05-10: a postpone must not end after the cutoff — the app abandons
            // running postpones there anyway, so longer grants were a promise it would break.
            let requestedSeconds = seconds
            seconds = cutoffLimitedPostponeSeconds(seconds)
            if seconds != requestedSeconds{
                addLog(text: "postpone evening habits, clamped to cutoff \(cutOffTimeString):- \(requestedSeconds)s -> \(seconds)s")
            }
            addLog(text: "postpone evening habits, Timer reset Done:- \(seconds) seconds")
            
            savePostpneCount(state: ._EVENING_HABIT_)
            eveningRoutineLastPostponeTime = Date()
            if currentAction == ._INPROGRESS_{
                isLastActivityStoppedInRunningState = true
                lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
            }else{
                isLastActivityStoppedInRunningState = false
                lastActivityRunningId = ""
            }
            
            hideCloseButtons()
            //Extend postpone time not working for 2 minute warning popup#923
            if currentState == ._POSTPONE_EVENING_HABIT_{
                closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
            }
            //
            if !isFocusModeOn(){
                leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
            }
            currentState = ._POSTPONE_EVENING_HABIT_
            hideBlankWindowInSecondaryMonitor()
            if currentHabitPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            
            //focusButtonService-------//
            focusButtonServiceObject.cancelHabit()
            //---------//
            
            if popUpCheckListWcObj != nil{
                if popUpCheckListWcObj?.window?.isVisible ?? false{
                    popUpCheckListWcObj?.window?.close()
                }
            }
            if isAnyAllowedFocusModeActivityRunning{
                closeNudgeFocusAlignmentScoreWindow()
            }
            isAnyAllowedFocusModeActivityRunning = false
            isAllowedActivityHabitPlaying = false   // #2050: clear alongside so a postponed allowed-activity habit doesn't leave minimise in "background without postpone" mode
            currentHabitPlaying = nil

            if !isFocusModeOn(){
                refreshFocusModeData()
                setAppIconForFocusModeScore(probability: nil)
            }
            closePupUpBlockIfVisible()
            
            habitBlockTimerHelper.stopUrlTimer()
            appdelegate?.timerAllowAppForActivity?.invalidate()
            
            
            if completionRequirementsWcObj != nil{
                if completionRequirementsWcObj?.window?.isVisible ?? false{
                    completionRequirementsWcObj?.window?.close()
                }
            }
            
            if arrFilteredEveningHabits.count != 0 {
                DispatchQueue.global().sync{//async {
                    if self.postponeTimer != nil{
                        self.postponeTimer?.invalidate()
                        self.postponeTimer = nil
                    }
                    self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.resumeEveningHabit), userInfo: nil, repeats: false)//  seconds
                    RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
                    
                    
                    // saving postpone information //Remember postpone status when app is restarted #1582  v 2.28.454
                    let postponeEndDate = Date().addingTimeInterval(TimeInterval(seconds))
                    UserDefaults.standard.set(postponeEndDate, forKey: kUserDefaultsLastRoutinePostponeEndDate)
                    UserDefaults.standard.set(CURRENTSTATE._POSTPONE_EVENING_HABIT_.rawValue,forKey: kUserDefaultsLastRoutinePostponeState)
                    
                    
                    if seconds > MeetingPostponeRules.endNotificationLeadSeconds{
                        setPostponeNotificationTimer(duration: (seconds - MeetingPostponeRules.endNotificationLeadSeconds))
                    }
                }
            }
            
            if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                if breakTimer == nil{
                    setActivityTimer()
                }
            }
            if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled{
                appdelegate?.menuShowPomodoroModeView()
                
                if !(pomodoroVcObj?.isViewLoaded ?? false){
                    pomodoroVcObj?.loadView()
                }
                pomodoroVcObj!.workDurationMinutes = minutes - 1
                pomodoroVcObj!.updateBreakDuration()
                pomodoroVcObj!.showPostponeTitle()
                
            }else{
                removeSubViews()
                leftMenuVcObj?.showHabitsView()
                habitsVcObj?.showHabitState()
            }
            writeStringToHabitInfo(isFinishTime: true, activityName: "")
            if !isExtendingPostponeFromAppStart{
                saveRemainingHabitIdForPostponedRoutineList(state: ._EVENING_HABIT_)
            }
            menuViewControllerObj?.reloadIfNeeded()
            leftMenuVcObj?.habitOver()
        }
    }
    
    func postponeFocusSummaryFor(minutes requestedMinutes:Int, showAskIntention:Bool){
        // Report 2026-09-17_17-05-10: the shutdown's Focus Summary was postponed 10 minutes PAST the
        // 17:00 cutoff. A postpone must not end after the cutoff — the app abandons running postpones
        // there anyway, so longer grants were a promise it would break.
        let minutes = cutoffLimitedPostponeMinutes(requestedMinutes)
        if minutes != requestedMinutes{
            addLog(text: "postpone Focus Summary clamped to cutoff \(cutOffTimeString):- \(requestedMinutes) -> \(minutes) minutes")
        }
        addLog(text: "postpone Focus Summary Done:- \(minutes) minutes")

        // #1942: a pending "one more minute" timer (giveOneMoreMinuteBeforeShutOffMac)
        // would otherwise fire showFocusSummaryViewAgain and re-display the Focus Summary
        // a few seconds after postponing, resetting the state and defeating the postpone.
        // Also close its countdown box so the "one minute timer" window doesn't linger.
        timerGiveOneMoreMinut?.invalidate()
        timerGiveOneMoreMinut = nil
        closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()

        var showAskIntention = showAskIntention
        
        // Super-gentle drops the intention prompt — but not when the AI accountability buddy is on, which
        // must always gate the postpone through its chat regardless of the strictness vote. (#2636)
        if SettingsManagerObject.isStrictnessLevelSuperGentle() && !SettingsManagerObject.isAccountabilityBuddyActive{
            addLog(text: "postponeFocusSummaryFor:- strictness level is super gentle so don't show postpone Intention view")
            showAskIntention = false
        }
        if showAskIntention{
            if let presenter = postponeIntentionPresenter(){
                if SettingsManagerObject.isAccountabilityBuddyActive{
                    addLog(text: "postponeFocusSummaryFor:- AI accountability buddy")
                    AccountabilityBuddyChatViewController.present(over: presenter, initialGoal: "",
                        onApproved: { [weak self] _, duration in
                            self?.postponeFocusSummaryFor(minutes: duration, showAskIntention: false)
                        },
                        onCancel: { [weak self] in self?.showCloseButtons() })   // gave up — restore the exit/close button abortCurrentState() hid
                }else{
                    addLog(text: "postponeFocusSummaryFor:- askPostponeIntention")// added in 2.28.444
                    presenter.presentAsSheet(getAskPostponeIntentionVcObject())
                    askPostponeIntentionVcObj?.resetData(minutes: minutes, secondsToPostpone: nil, showAskFocusModeView: false, lastCurrentState: ._FOCUS_SUMMARY_)
                }
            }else{
                addLog(text: "postponeFocusSummaryFor:- window is nil")// added in 2.28.444
            }
        }else{
            hideCloseButtons()
            removeSubViews()
            currentState = ._POSTPONE_FOCUS_SUMMARY_
            hideBlankWindowInSecondaryMonitor()
            DispatchQueue.global().sync{//async {
                if self.postponeTimer != nil{
                    self.postponeTimer?.invalidate()
                    self.postponeTimer = nil
                }
                focusSummaryLastPostponeTime = Date()
                self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(minutes*60), target: self, selector: #selector(self.resumeFocusSummary), userInfo: nil, repeats: false)//  minutes*60 kroTimeInterval(minutes*60)
                RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
                
                
                // saving postpone information //Remember postpone status when app is restarted #1582  v 2.28.454
                let postponeEndDate = Date().addingTimeInterval(TimeInterval(minutes*60))
                UserDefaults.standard.set(postponeEndDate, forKey: kUserDefaultsLastRoutinePostponeEndDate)
                UserDefaults.standard.set(CURRENTSTATE._POSTPONE_FOCUS_SUMMARY_.rawValue,forKey: kUserDefaultsLastRoutinePostponeState)
                
                
                if minutes*60 > MeetingPostponeRules.endNotificationLeadSeconds{
                    setPostponeNotificationTimer(duration: ((minutes*60) - MeetingPostponeRules.endNotificationLeadSeconds))
                }
            }
            if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                if breakTimer == nil{
                    setActivityTimer()
                }
            }
            menuViewControllerObj?.reloadIfNeeded()
            leftMenuVcObj?.habitOver()
            if SettingsManagerObject.isGeekModeEnabled{
                appdelegate?.menuShowPomodoroModeView()
                
                if !(pomodoroVcObj?.isViewLoaded ?? false){
                    pomodoroVcObj?.loadView()
                }
                pomodoroVcObj!.workDurationMinutes = minutes - 1
                pomodoroVcObj!.updateBreakDuration()
                pomodoroVcObj!.showPostponeTitle()
                
            }else{
                removeSubViews()
                leftMenuVcObj?.showHabitsView()
                habitsVcObj?.showHabitState()
            }
        }
    }
    
    func setPostponeNotificationTimer(duration:Int){
        
        if self.postponeNotificationTimer != nil{
            self.postponeNotificationTimer?.invalidate()
            self.postponeNotificationTimer = nil
        }
        self.postponeNotificationTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.showPostponeEndNotification), userInfo: nil, repeats: false)
        RunLoop.main.add((postponeNotificationTimer!), forMode: RunLoop.Mode.common)
    }

    /// Stretches a running postpone over the meeting chain that is live or about to start, and
    /// reports whether it did.
    ///
    /// A postpone exists so the routine waits while the user is busy, and a meeting Focus Bear
    /// itself announced is the clearest possible "busy". Sized for one meeting, the postpone
    /// expired into the next one; re-postponing here re-arms the countdown timer as well, so the
    /// check repeats for each meeting in the chain until nothing is left to cover.
    @discardableResult
    func extendPostponeToCoverAnnouncedMeetings() -> Bool {
        guard let seconds = MeetingCoverage.extensionSecondsToCoverMeeting(now: Date(),
                                                                          meetings: AnnouncedMeetingRegister.shared.activeMeetings(),
                                                                          currentPostponeEnd: currentRoutinePostponeEndDate()) else {
            return false
        }
        // Only the two habit postpones can be re-armed this way; a postponed focus summary has no
        // habits left to protect, so it is left to end normally.
        switch currentState {
        case ._POSTPONE_MORNING_HABIT_:
            addLog(text: "extendPostponeToCoverAnnouncedMeetings:- morning postpone extended to \(seconds) seconds to cover a live/imminent meeting")
            postponeMorningHabitFor(minutes: 0, secondsToPostpone: seconds, showAskFocusModeView: false, showAskIntention: false)
        case ._POSTPONE_EVENING_HABIT_:
            addLog(text: "extendPostponeToCoverAnnouncedMeetings:- evening postpone extended to \(seconds) seconds to cover a live/imminent meeting")
            postponeEveningHabitFor(minutes: 0, secondsToPostpone: seconds, showAskFocusModeView: false, showAskIntention: false)
        default:
            return false
        }
        // Still the meeting session's postpone, so it must still end when that session does.
        if currentAccountabilityBuddySession?.isMeeting == true && isFocusSessionStartedFromPostponeIntention {
            tieSavedPostponeToMeetingSession()
        }
        return true
    }

    /// Records the routine postpone just saved as the one a meeting focus session covers, so it ends
    /// with that session and is dropped at launch without it — see `MeetingPostponeSession`.
    func tieSavedPostponeToMeetingSession() {
        UserDefaults.standard.set(UserDefaults.standard.object(forKey: kUserDefaultsLastRoutinePostponeEndDate),
                                  forKey: kUserDefaultsMeetingSessionPostponeEndDate)
    }

    /// What the meeting session that has just run out means for the routine postpone it covered.
    func routinePostponeOutcomeWhenMeetingSessionRunsOut() -> MeetingPostponeSession.SessionRunOutOutcome {
        let postponed = routinePostponeStateToReCoverOnExtend()
        return MeetingPostponeSession.outcomeWhenSessionRunsOut(
            now: Date(),
            isRoutinePostponed: postponed == ._POSTPONE_MORNING_HABIT_ || postponed == ._POSTPONE_EVENING_HABIT_,
            postponeEnd: UserDefaults.standard.object(forKey: kUserDefaultsLastRoutinePostponeEndDate) as? Date,
            tiedPostponeEnd: UserDefaults.standard.object(forKey: kUserDefaultsMeetingSessionPostponeEndDate) as? Date,
            meetings: AnnouncedMeetingRegister.shared.activeMeetings())
    }

    /// Covers a meeting that follows straight on from one whose session just ran out: it gets a
    /// meeting session of its own, and the routine stays postponed until exactly that session ends.
    func continueMeetingPostpone(into meeting: AnnouncedMeeting) {
        let minutes = MeetingPostponeSession.sessionMinutes(secondsRemaining: Int(meeting.end.timeIntervalSinceNow))
        let seconds = minutes * 60
        switch routinePostponeStateToReCoverOnExtend() {
        case ._POSTPONE_MORNING_HABIT_?:
            postponeMorningHabitFor(minutes: 0, secondsToPostpone: seconds, showAskFocusModeView: false, showAskIntention: false)
        case ._POSTPONE_EVENING_HABIT_?:
            postponeEveningHabitFor(minutes: 0, secondsToPostpone: seconds, showAskFocusModeView: false, showAskIntention: false)
        default:
            return
        }
        tieSavedPostponeToMeetingSession()
        // This is the continuation of a meeting-owned postpone, not a new independent postpone.
        startMeetingFocusSession(title: meeting.title, durationMinutes: minutes, wasRoutineAlreadyPostponed: false)
    }
    
    @objc func showPostponeEndNotification(){
        // Never announce "Habit resumes in…" over a meeting that is live or seconds away — extend
        // the postpone past it instead (report 2026-09-15_13-03-02).
        if extendPostponeToCoverAnnouncedMeetings(){ return }
        if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_ || currentState == ._POSTPONE_MORNING_HABIT_ || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit && !isCustomRoutineWasRunningBetweenMorningHabit) || (currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit && !isCustomRoutineWasRunningBetweenEveningHabit){
            var msg = "Habit resumes in"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                msg = common.value(forKey: "postponeEndsText") as? String ?? msg
            }
            addLog(text: "Show Postpone End Notification")
            showSmallTimerWindow(durationSeconds: MeetingPostponeRules.endNotificationLeadSeconds, msg: msg, isFocusBreak: true, currentTimerValue: 0)
        }
    }
    

    /// The meeting guard in front of every resume, now aware of WHICH entry point is asking.
    ///
    /// `resumeMorningHabit` and friends are reached two ways: the postpone timer elapsing, and the user
    /// stopping a session that was started by postponing (`stopFocusModeAndResumeRoutine`). The guard was
    /// written for the first and silently swallowed the second (report 2026-09-17_12-03-44), which is why
    /// the entry point is an input rather than something inferred here.
    ///
    /// - Parameter isMeetingSessionLive: must be sampled BEFORE the session is finished — the stop path
    ///   finishes the session first, so reading it here would always see `false`.
    /// - Returns: true when the routine should resume now. When it should not, this has already extended
    ///   the postpone if that was the right answer.
    func shouldResumeRoutineNow(trigger: RoutineResumeTrigger, isMeetingSessionLive: Bool) -> Bool {
        let isRoutinePostponed = currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_
        let hasMeetingToCover = MeetingCoverage.extensionSecondsToCoverMeeting(
            now: Date(), meetings: AnnouncedMeetingRegister.shared.activeMeetings()) != nil
        let decision = RoutineResume.decision(trigger: trigger,
                                              isRoutinePostponed: isRoutinePostponed,
                                              hasMeetingToCover: hasMeetingToCover,
                                              isMeetingSessionLive: isMeetingSessionLive)
        addLog(text: "routine resume: \(decision) (trigger=\(trigger) state=\(currentState) postponed=\(isRoutinePostponed) meetingToCover=\(hasMeetingToCover) meetingSessionLive=\(isMeetingSessionLive))")
        switch decision {
        case .resume:
            return true
        case .extendPostponeOverMeeting:
            extendPostponeToCoverAnnouncedMeetings()
            return false
        case .stayPostponed:
            return false
        }
    }

    @objc func resumeMorningHabit(){// func name "backgrounThread" will do work for showing morning routing again we just need to false this (currentState) variable
        resumePostponedMorningRoutine(for: .postponeElapsed)
    }

    func resumePostponedMorningRoutine(for trigger: RoutineResumeTrigger,
                                       isMeetingSessionLive: Bool = currentAccountabilityBuddySession?.isMeeting == true){
        addLog(text: "Morning habits postpone finished")
        // Last line of defence: a meeting announced inside the final countdown would otherwise land
        // the routine on screen mid-call. An explicit user request is exempt — see RoutineResume.
        if !shouldResumeRoutineNow(trigger: trigger, isMeetingSessionLive: isMeetingSessionLive){ return }
        if currentState == ._POSTPONE_MORNING_HABIT_{
            currentState = ._NOTHING_
            stopActivityTimer()
            if appdelegate!.isActivityTimerPaused{// if habit is postponed and system goes to sleep then  it stops break activity timer and while system is in sleep mode at that time postpone  time finish so it need to change isActivityTimerPaused to false otherwise when system wakes up it will again set activity timer
                appdelegate!.isActivityTimerPaused = false
            }
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{
            stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            
            isBreakActivityExecuteFromPostponeMorningHabit = false
            currentState = ._NOTHING_
            closePupUpBlockIfVisible()
            currentActivityPlaying = nil
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit && !isCustomRoutineWasRunningBetweenMorningHabit{
            stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            closePupUpBlockIfVisible()
            currentHabitPlaying = nil
            isCustomRoutineWasRunningInPostponeMorningHabit = false
            currentState = ._NOTHING_
        }
        hideCustomRoutineTimeWindowIfVisible()// hide custom routine coming window if visible
    }
    
    @objc func resumeEveningHabit(){// func name "backgrounThread" will do work for showing evening routing again we just need to false this (currentState) variable
        resumePostponedEveningRoutine(for: .postponeElapsed)
    }

    func resumePostponedEveningRoutine(for trigger: RoutineResumeTrigger,
                                       isMeetingSessionLive: Bool = currentAccountabilityBuddySession?.isMeeting == true){
        addLog(text: "Evening habits postpone finished")
        // Last line of defence — see resumeMorningHabit.
        if !shouldResumeRoutineNow(trigger: trigger, isMeetingSessionLive: isMeetingSessionLive){ return }
        if currentState == ._POSTPONE_EVENING_HABIT_{
            currentState = ._NOTHING_
            stopActivityTimer()
            if appdelegate!.isActivityTimerPaused{// if habit is postponed and system goes to sleep then  it stops break activity timer and while system is in sleep mode at that time postpone  time finish so it need to change isActivityTimerPaused to false otherwise when system wakes up it will again set activity timer
                appdelegate!.isActivityTimerPaused = false
            }
        }else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
            stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            
            isBreakActivityExecuteFromPostponeEveningHabit = false
            currentState = ._NOTHING_
            closePupUpBlockIfVisible()
            currentActivityPlaying = nil
        }else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit && !isCustomRoutineWasRunningBetweenEveningHabit{
            stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            closePupUpBlockIfVisible()
            currentHabitPlaying = nil
            isCustomRoutineWasRunningInPostponeEveningHabit = false
            currentState = ._NOTHING_
        }
    }
    
    @objc func resumeFocusSummary(){// func name "backgrounThread" will do work for showing morning routing again we just need to false this (isMorningRoutinePostpone) variable
        addLog(text: "Focus Summary postpone finished")
        if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit{
            stopActivityCountDownTimer()
            if currentActivityPlaying != nil{
                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
            }
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
            closePupUpBlockIfVisible()
            currentHabitPlaying = nil
            isCustomRoutineWasRunningInPostponeEveningHabit = false
            currentState = ._NOTHING_
        }
        currentState = ._NOTHING_
    }
    
    func activityFinishedUnlockMachine() {
        addLog(text: "Break Activities Finished")
        hideCloseButtons()
        removeSubViews()
        activityPostponeCount = 0
        let infoDic:[String:Any] = ["postponeCount":activityPostponeCount, "date":Date()]
        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastBreakActivityPostponeInfo)
        print(infoDic)
        
        if let startTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreaksStartTime) as? Date{
            let currentDate = Date()
            let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: currentDate).second ?? 0
            if diffSeconds > 0{
                var arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
                arrDuration.append(diffSeconds)
                UserDefaults.standard.set(arrDuration, forKey: kUserdefaultsArrayBreaksDurations)
            }
            UserDefaults.standard.set(currentDate, forKey: kUserdefaultsLastBreakEndTime)
        }
        
        currentActivityIndex = -1
        unlockMachine()
        currentState = ._NOTHING_
        leftMenuVcObj?.microBreaksOver()
        if shouldShowPomodoroAfterBreak{
            shouldShowPomodoroAfterBreak = false
            if SettingsManagerObject.isGeekModeEnabled{
                if let date = shouldEndPomodoroBreakAtTime{
                    let currentDate = Date()
                    if currentDate > date{
                        appdelegate!.showAutoPomodoroModeView()
                    }else{
                        let diffSeconds = Calendar.current.dateComponents([.second], from: currentDate, to: date).second ?? 0
                        appdelegate?.setTimerForPomodoroMode(delay: TimeInterval(diffSeconds))
                        showSmallTimerWindow(durationSeconds: diffSeconds, msg: "", isFocusBreak: true, currentTimerValue:0)
                        if isAppEnable{
                            isFocusBreakOn = true
                        }
                    }
                }else{
                    appdelegate!.showAutoPomodoroModeView()
                }
            }
        }else{
            // A break interrupts a focus session; ending it has to hand the user back to that session.
            // This used to call showToDoListWindow(), which landed on the session's task player back
            // when the To-do slot rendered it — that slot no longer always does, so ask for the
            // session screen by name. Paused counts: it is still the user's session to resume.
            switch BreakStartKit.destinationAfterBreak(isFocusSessionActive: isFocusModeOnOrPaused()){
            case .focusSession:
                showRunningFocusSessionWindow()
            case .suggestFocusSession:
                appdelegate!.showAutoPomodoroModeView()
            }
        }
        
        if isBreakActivityExecuteFromMorningHabit || isBreakActivityExecuteFromEveningHabit{
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            addLog(text: "Break Activity Finished:- Try resume Habit Routine")
            appdelegate!.backgroundThread()
        }
        if isBreakActivityExecuteFromPostponeMorningHabit{
            currentState = ._POSTPONE_MORNING_HABIT_
            isBreakActivityExecuteFromPostponeMorningHabit = false
            addLog(text: "Break Activity Finished:- activity was started from postpone morning habit. Try postpone Habit Routine")
        }
        if isBreakActivityExecuteFromPostponeEveningHabit{
            currentState = ._POSTPONE_EVENING_HABIT_
            isBreakActivityExecuteFromPostponeEveningHabit = false
            addLog(text: "Break Activity Finished:- activity was started from postpone evening habit. Try postpone Habit Routine")
        }
        
        var microBreaksDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsMicroBreaksDoneCount) as? Int ?? 0//
        microBreaksDoneCount += 1
        UserDefaults.standard.set(microBreaksDoneCount, forKey: kUserdefaultsMicroBreaksDoneCount)
    }
    
    func customRoutineFinishedUnlockMachine() {
        addLog(text: "custom Routine Finished")
        hideCloseButtons()
        removeSubViews()
        currentHabitIndex = -1
        
        unlockMachine()
        currentState = ._NOTHING_
        isCustomRoutineWasRunningBetweenMorningHabit = false
        isCustomRoutineWasRunningBetweenEveningHabit = false
        leftMenuVcObj?.habitOver()
    }
    
    func breathingFinishedUnlockMachine(){
        addLog(text: "breathing Finished")
        hideCloseButtons()
        removeSubViews()
        lblMessage.isHidden = true
        unlockMachine()
        currentState = ._NOTHING_
    }
    


    @objc func timeToStartBreakActivities() {
        DispatchQueue.main.async {
            addLog(text: "Initiating Break Activities")
            self.breakTimer?.invalidate()
            self.breakTimer = nil
            
            
            if !SettingsManagerObject.isMicroBreaksEnabled{
                // Breaks are intentionally off — push the due date out a full interval (forceReset) so this
                // doesn't short-retry in a tight loop while disabled.
                self.setActivityTimer(forceReset: true)
                addLog(text: "Breaks are not enabled :- Break Activities cancelled.")
                if self.isWaitingForInactivityToStartMicroBreak{
                    self.breakInactivitySecondsToCheck = 5
                    self.isWaitingForInactivityToStartMicroBreak = false
                    self.inActivityStartTime = nil
                    setFocusBearIconToNormal()
                }
                return;
            }

            if FeatureSnooze.isSnoozed(.breakNotifications){
                // Breaks paused from the quit popup — push the due date out a full interval (forceReset)
                // so this doesn't short-retry in a tight loop while paused; it resumes on its own once
                // the pause window passes.
                self.setActivityTimer(forceReset: true)
                addLog(text: "Breaks are paused (quit-popup snooze) :- Break Activities cancelled.")
                if self.isWaitingForInactivityToStartMicroBreak{
                    self.breakInactivitySecondsToCheck = 5
                    self.isWaitingForInactivityToStartMicroBreak = false
                    self.inActivityStartTime = nil
                    setFocusBearIconToNormal()
                }
                return;
            }

            if let disableBreaksForTodayDate = UserDefaults.standard.object(forKey: kUserdefaultsDisableBreaksForToday) as? Date{
                if Calendar.current.isDateInToday(disableBreaksForTodayDate){
                    // Breaks are intentionally off for today — push the due date out a full interval
                    // (forceReset) rather than short-retrying in a tight loop.
                    self.setActivityTimer(forceReset: true)
                    addLog(text: "Breaks are disabled for today :- Break Activities cancelled.")
                    
                    if self.isWaitingForInactivityToStartMicroBreak{
                        self.breakInactivitySecondsToCheck = 5
                        self.isWaitingForInactivityToStartMicroBreak = false
                        self.inActivityStartTime = nil
                        setFocusBearIconToNormal()
                    }
                    
                    return;
                }else{
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsDisableBreaksForToday)
                }
            }
            
            // No micro-breaks while a class session is running.
            if teacherSessionManagerObject.isTeacherSessionActive(){
                addLog(text: "Teacher session active, Break Activities cancelled.")
                self.rescheduleBreakSoonAfterBlocked()
                return;
            }
            
            if currentState == ._SHUTOFFMAC_{
                addLog(text: "App is in shutoff state, Break Activities cancelled.")
                return;
            }
            if currentState == ._ABORT_{
                addLog(text: "App state is abort, Break Activities cancelled.")
                return;
            }
            
            if isShutOffTimeGoing(){
                if currentState == ._POSTPONE_FOCUS_SUMMARY_ || currentState == ._POSTPONE_EVENING_HABIT_{
                    if !SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                        addLog(text: "Routine is postponed. Show breaks in Postpone not enabled, Break Activities cancelled.")
                        return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga// iise focus summary  k time per bhi rreturn ho jayga
                    }
                }else if currentState != ._EVENING_HABIT_ {
                    addLog(text: "not working hours, Break Activities cancelled.")
                    return;//agar kisi ne shutdown abort bhi kr diya to bhi kuch ni hoga// iise focus summary  k time per bhi rreturn ho jayga
                }
            }
            
            
            //
            if currentState == ._CUSTOM_ROUTINE_{
                self.rescheduleBreakSoonAfterBlocked()
                addLog(text: "Custom routine is running :- Break Activities cancelled.")
                return;
            }
            
            if arrAllbreakActivities.count == 0 {
                self.setActivityTimer()
                addLog(text: "Break Activities count is 0 :- Break Activities cancelled.")
                return;
            }
            if currentState == ._SPECIAL_ACTIVITY_{
                self.rescheduleBreakSoonAfterBlocked()
                addLog(text: "Special activity is running :- Break Activities cancelled.")
                return;
            }
            
            if popupAppointmentTimeWcObj != nil{
                if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                    addLog(text: "Appointment popup is visible :- Break Activities cancelled.")
                    return;
                }
            }
            
            let isFocusModeOn = isFocusModeOn()
            if isFocusModeOn && isFocusModeStartedFromPomodoroMode && isSkipBreakActivityDuringPomodoro{
                self.rescheduleBreakSoonAfterBlocked()
                addLog(text: "Pomodoro mode is On and Skip Break Activity During Focus is enabled: Break Activities cancelled.")
                return;
            }else if isHardCorePomodoroModeOn && isSkipBreakActivityDuringPomodoro{
                self.rescheduleBreakSoonAfterBlocked()
                addLog(text: "Super Pomodoro mode is On and Skip Break Activity During Focus is enabled: Break Activities cancelled.")
                return;
            }else if isFocusModeOn && isSkipBreakActivityDuringFocus{// will never return true beacuse isSkipBreakActivityDuringFocus is not in use now
                self.rescheduleBreakSoonAfterBlocked()
                addLog(text: "Focus mode is On and Skip Break Activity During Focus is enabled: Break Activities cancelled.")
                return;
            }
            
            
            if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                if !customBlockingScheduleManagerObj.isMicroBreaksEnabled(){
                    self.rescheduleBreakSoonAfterBlocked()
                    addLog(text: "Custom Blocking is On and Skip Break Activity During Custom Blocking is enabled: Break Activities cancelled.")
                    return;
                }
            }
            
            
            //show the break as soon as there are 5 seconds of inactivity
            var lastEvent:CFTimeInterval = 0
            lastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
            
            let idleTimeValue = Int(lastEvent)
            if idleTimeValue < self.breakInactivitySecondsToCheck{
                if !self.isWaitingForInactivityToStartMicroBreak{
                    self.isWaitingForInactivityToStartMicroBreak = true
                    self.inActivityStartTime = Date()
                }
                if let startTime = self.inActivityStartTime{
                    let diffSeconds = Calendar.current.dateComponents([.second], from: startTime, to: Date()).second ?? 0
                    if diffSeconds < 120{// 2 minutes
                        self.breakInactivitySecondsToCheck = 5
                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactiveWaiting_icon"))
                    }else if diffSeconds > 600{// 10 minutes
                        self.breakInactivitySecondsToCheck = 1
                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactive5Minutes_icon"))
                    }else if diffSeconds > 300{// 5 minutes
                        self.breakInactivitySecondsToCheck = 2
                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactive5Minutes_icon"))
                    }else if diffSeconds > 120{// 2 minutes
                        self.breakInactivitySecondsToCheck = 3
                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("inactive2Minutes_icon"))
                    }
                    addLog(text: "waiting since \(diffSeconds) seconds")
                }
                
                addLog(text: "idleTimeValue is less then \(self.breakInactivitySecondsToCheck) seconds :- try break activities after \(self.breakInactivitySecondsToCheck) seconds.")
                print("idleTimeValue is less then \(self.breakInactivitySecondsToCheck) seconds :- try break activities after \(self.breakInactivitySecondsToCheck) seconds.")
                DispatchQueue.global().sync {
                    print("breakAfterMinutesxxxx")
                    self.breakTimer?.invalidate()
                    self.breakTimer = nil
                    self.breakTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.breakInactivitySecondsToCheck), target: self, selector: #selector(self.timeToStartBreakActivities), userInfo: nil, repeats: false)
                    
                    RunLoop.main.add((self.breakTimer!), forMode: RunLoop.Mode.common)
                }
                
                return;
            }
            if self.isWaitingForInactivityToStartMicroBreak{
                self.breakInactivitySecondsToCheck = 5
                self.isWaitingForInactivityToStartMicroBreak = false
                self.inActivityStartTime = nil
                setFocusBearIconToNormal()
            }
            
            isBreakActivityExecuteFromPostponeMorningHabit = false
            isBreakActivityExecuteFromPostponeEveningHabit = false
            
            isBreakActivityExecuteFromMorningHabit = false
            isBreakActivityExecuteFromEveningHabit = false
            checkLogFileRotation()
            
            isBreakActivityShowingWhileMeeting = false
            if appdelegate!.isUserOnMeeting{
                if !SettingsManagerObject.IsShowBreaksInCallEnabled{
                    addLog(text: "isUserOnMeeting True: Break Activities cancelled.")
                    self.rescheduleBreakSoonAfterBlocked()
                    isBreakActivityShowingWhileMeeting = false
                    return;
                }else{
                    var anyOfficeFriendlyActivityFound = false
                    for activity in arrAllbreakActivities{
                        if activity.isOfficeFriendly{
                            anyOfficeFriendlyActivityFound = true
                            break;
                        }
                    }
                    if !anyOfficeFriendlyActivityFound{
                        addLog(text: "User is On Meeting;- no office friendly activity found: Break Activities cancelled.")
                        self.rescheduleBreakSoonAfterBlocked()
                        isBreakActivityShowingWhileMeeting = false
                        return;
                    }
                    isBreakActivityShowingWhileMeeting = true
                }
            }
            
            if isAnyPresentationOrVideoShowing(){
                if !SettingsManagerObject.IsShowBreaksInCallEnabled{
                    addLog(text: "PresentationOrVideoShowing True: Break Activities cancelled.")
                    self.rescheduleBreakSoonAfterBlocked()
                    isBreakActivityShowingWhileMeeting = false
                    return;
                }else{
                    var anyOfficeFriendlyActivityFound = false
                    for activity in arrAllbreakActivities{
                        if activity.isOfficeFriendly{
                            anyOfficeFriendlyActivityFound = true
                            break;
                        }
                    }
                    if !anyOfficeFriendlyActivityFound{
                        addLog(text: "User is On Meeting;- no office friendly activity found: Break Activities cancelled.")
                        self.rescheduleBreakSoonAfterBlocked()
                        isBreakActivityShowingWhileMeeting = false
                        return;
                    }
                    isBreakActivityShowingWhileMeeting = true
                }
            }
            
            if currentState == ._MORNING_HABIT_{// ⚠️ do not change current state inside this block
                // new work // 23/12/22
                if currentHabitPlaying != nil && !(mainWindowControllerObj?.window?.isVisible ?? false) && currentAction == ._INPROGRESS_{//it means background morning habit and now break activity is allowed in allowed app morning habit // 23/12/22
                    addLog(text: "Morning habit showing, Break Activities allowed in allowed app morning habit.")
                    
                    // pause  morning activity and start break activity
                    // will not change current state here beacuse we do not want to execute background thread during warning but need to handle when pc goint to sleep during warning
                    mainWindowControllerObj?.window?.close()
                    hideBlankWindowInSecondaryMonitor()
                    isLastActivityStoppedInRunningState = true
                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                    isBreakActivityExecuteFromMorningHabit = true
                    
                    if timerViewcontrollerObj != nil {
                        if timerViewcontrollerObj?.timer != nil {
                            timerViewcontrollerObj?.timer?.invalidate()
                            
                            //focusButtonService---//
                            focusButtonServiceObject.pauseHabit()
                            //--------------//
                            
                            enableSystemSleep()
                            if timerViewcontrollerObj?.isVideoLodded ?? false{
                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                            }
                        }
                    }
                    
                    if currentHabitPlaying != nil{
                        if isAnyAllowedFocusModeActivityRunning{
                            closeNudgeFocusAlignmentScoreWindow()
                        }
                        isAnyAllowedFocusModeActivityRunning = false
                        currentHabitPlaying = nil
                        refreshFocusModeData()
                        setAppIconForFocusModeScore(probability: nil)
                        closePupUpBlockIfVisible()
                        
                        closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                    }
                    
                }else{
                    addLog(text: "Morning habit showing, Break Activities cancelled.")
                    return;
                }
                
            }
            
            
            if currentState == ._EVENING_HABIT_{// ⚠️ do not change current state inside this block
                
                // new work // 23/12/22
                if currentHabitPlaying != nil && !(mainWindowControllerObj?.window?.isVisible ?? false) && currentAction == ._INPROGRESS_{//it means background evening habit and now break activity is allowed in allowed app morning habit // 23/12/22
                    addLog(text: "Evening habit showing, Break Activities allowed in allowed app Evening habit.")
                    
                    // pause  evening activity and start break activity
                    // will not change current state here beacuse we do not want to execute background thread during warning but need to handle when pc goint to sleep during warning
                    mainWindowControllerObj?.window?.close()
                    hideBlankWindowInSecondaryMonitor()
                    isLastActivityStoppedInRunningState = true
                    lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                    isBreakActivityExecuteFromEveningHabit = true
                    
                    if timerViewcontrollerObj != nil {
                        if timerViewcontrollerObj?.timer != nil {
                            timerViewcontrollerObj?.timer?.invalidate()
                            
                            //focusButtonService---//
                            focusButtonServiceObject.pauseHabit()
                            //--------------//
                            
                            enableSystemSleep()
                            if timerViewcontrollerObj?.isVideoLodded ?? false{
                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                            }
                        }
                    }
                    
                    if currentHabitPlaying != nil{
                        if isAnyAllowedFocusModeActivityRunning{
                            closeNudgeFocusAlignmentScoreWindow()
                        }
                        isAnyAllowedFocusModeActivityRunning = false
                        currentHabitPlaying = nil
                        refreshFocusModeData()
                        setAppIconForFocusModeScore(probability: nil)
                        
                        closePupUpBlockIfVisible()
                        closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                    }
                    
                    
                    // //////////////
                }else{
                    addLog(text: "Evening habit showing, Break Activities cancelled.")
                    return;
                }
                
            }
            
            self.reFillBreakActivitiesArray()
            if arrFinalBreakActivities.count == 0{
                addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
                self.setActivityTimer()//possible nahi hai
                return;
            }
            if currentState == ._POSTPONE_MORNING_HABIT_{// ⚠️ do not change current state inside this block
                // new work // 20/04/23
                if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                    isBreakActivityExecuteFromPostponeMorningHabit = true// morning habit postpone over hua to activity timer bhi band hoga or agar activity chal rhi hui to vo bhi band hokar uska timer band hoga
                }else{
                    return;
                }
            }
            
            if currentState == ._POSTPONE_EVENING_HABIT_{// ⚠️ do not change current state inside this block
                if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                    isBreakActivityExecuteFromPostponeEveningHabit = true
                }else{
                    return;
                }
            }
            
            if currentState == ._POSTPONE_FOCUS_SUMMARY_{// ⚠️ do not change current state inside this block
                if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                    isBreakActivityExecuteFromPostponeEveningHabit = true
                }else{
                    return;
                }
            }
            
            if !(leftMenuVcObj?.boxHabits.isSelected ?? false) && !(leftMenuVcObj?.boxCustomRoutine.isSelected ?? false) && !(leftMenuVcObj?.boxMicroBreaks.isSelected ?? false){
                self.removeSubViews() // so that if firstviewcontroller or thirdvc or any view lodded we will remvoe them but if user already inside habitsvc then don't touch
            }
            
            showBreakWarningWindow()
            currentState = ._MICRO_BREAK_
            currentAction = ._START_// added on 24/7/25 v 1.26.394
            shouldShowPomodoroAfterBreak = false
        }
    }
    
    func reFillBreakActivitiesArray(excludingActivityIDs: Set<String> = []){
        var isAnyMandatoryActivityIncluded = false
        var arrActivitiesIncludeInEveryBreak = [breakActivity]()
        var arrActivitiesExcludeInEveryBreak = [breakActivity]()
        
        for activity in BreakStartKit.unplayedActivities(from: arrAllbreakActivities, excludingIDs: excludingActivityIDs){
            if isBreakActivityShowingWhileMeeting{
                if !activity.isOfficeFriendly{
                    continue;
                }
            }else{
                if SettingsManagerObject.isOfficeModeEnabled{
                    if !activity.isOfficeFriendly{
                        continue;
                    }
                }
            }
            if activity.IncludeInEveryBreak{
                isAnyMandatoryActivityIncluded = true//than two step will be happen// first mandatory arra than normal array
                arrActivitiesIncludeInEveryBreak.append(activity)
            }else{
                arrActivitiesExcludeInEveryBreak.append(activity)
            }
        }
        //                checking if  Office Mode is on and if there is not any activity office friendly than turn off office mode
        if SettingsManagerObject.isOfficeModeEnabled{
            if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0
                && (excludingActivityIDs.isEmpty || !BreakStartKit.canEnterOfficeMode(from: arrAllbreakActivities)) {
                addLog(text: "SettingsManagerObject.isOfficeModeEnabled false becuse no office friendly activity found.")
                SettingsManagerObject.isOfficeModeEnabled = false
                NSApplication.shared.applicationIconImage = nil
                UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsOfficeModeEnabled)
                
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
                
                
                for activity in BreakStartKit.unplayedActivities(from: arrAllbreakActivities, excludingIDs: excludingActivityIDs){
                    if activity.IncludeInEveryBreak{
                        isAnyMandatoryActivityIncluded = true//than two step will be happen// first mandatory array than normal array
                        arrActivitiesIncludeInEveryBreak.append(activity)
                    }else{
                        arrActivitiesExcludeInEveryBreak.append(activity)
                    }
                }
                
            }
        }
        arrFinalBreakActivities.removeAll()//Tell user what break activities are coming up#479
        if arrActivitiesExcludeInEveryBreak.count == 0 && arrActivitiesIncludeInEveryBreak.count == 0{
            addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
            return;
        }
        
        currentActivityIndex = -1
        if isAnyMandatoryActivityIncluded{
            for activity in arrActivitiesIncludeInEveryBreak{
                arrFinalBreakActivities.append(breakActivityFilter(activity: activity, randomChoice: nil))
            }
            
            if arrActivitiesExcludeInEveryBreak.count != 0{
                let randomActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
                arrFinalBreakActivities.append(breakActivityFilter(activity: arrActivitiesExcludeInEveryBreak[randomActivityIndex], randomChoice: nil))
            }
        }else{
            let randomActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
            arrFinalBreakActivities.append(breakActivityFilter(activity: arrActivitiesExcludeInEveryBreak[randomActivityIndex], randomChoice: nil))
        }
        
        for i in 0..<arrFinalBreakActivities.count{//
            let filterActivity = arrFinalBreakActivities[i]
            if let currentActivity = filterActivity.activity{
                if currentActivity.choiceType == ._RANDOM_{
                    var currentActivityChoice = currentActivity.choices.randomElement()
                    
                    if currentActivity.choices.count != 1{
                        if let lastChoice = lastShownRandomChoiceDic[currentActivity.id]{
                            while lastChoice.id == currentActivityChoice!.id {
                                currentActivityChoice = currentActivity.choices.randomElement()
                            }
                        }
                    }
                    lastShownRandomChoiceDic[currentActivity.id ?? ""] = currentActivityChoice
                    arrFinalBreakActivities[i].randomChoice = currentActivityChoice
                }
            }
        }
        //--------------------------------------------------------------------//
        //After the 7 day free trial, let's allow users to downgrade to Free Basic.//Support freemium#1066
        //if ap is expired max 5 habits in the morning and evening routines (if the user has more than 5, only show the first 5)#1066
        isActivitiesReducedInExpiredApp = false
        if isExpired{
            if arrFinalBreakActivities.count > activitiesCountInExpireApp{
                isActivitiesReducedInExpiredApp = true
                let arrTempBreakActivities = arrFinalBreakActivities
                arrFinalBreakActivities.removeAll()
                for i in 0..<activitiesCountInExpireApp{
                    arrFinalBreakActivities.append(arrTempBreakActivities[i])
                }
            }
        }
        //----------------------------------------------------------------------//
    }
    
    @objc func executeBreakActivities() {//   is any this is new in this func  we should also review this fucc "okClickedFromCustomMessage()"{
        shouldShowPomodoroAfterBreak = false
        isBreakActivityShowingWhileMeeting = false
        addLog(text: "startBreakActivities")
        stopActivityTimer()
        if arrAllbreakActivities.count != 0 {
            
            reFillBreakActivitiesArray()
            
            if arrFinalBreakActivities.count == 0{
                addLog(text: "filterd arrActivitiesExcludeInEveryBreak and arrActivitiesIncludeInEveryBreak is zero .")
                self.setActivityTimer()//possible nahi hai
                return;
            }
            
            self.removeSubViews()
            currentState = ._MICRO_BREAK_
            
            
            self.performBreakActivities()
            
        }
        
    }
    func enableOfficeModeAndRestartBreakActivities(){
        addLog(text: "enableOfficeModeAndRestartBreakActivities")
        var officeModeEnableText = "Ok I'll give you some break activities that are appropriate to do in an office environment."
        
        if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
            officeModeEnableText = activityPostponeInfo.value(forKey: "officeModeEnableText") as? String ?? officeModeEnableText
        }
        
        showCustomMessageView(msg: officeModeEnableText)
    }
    func showCustomMessageView(msg:String){
        addLog(text: "show Custom Message View")
        self.view.addSubview(getCustomMessageVcObject().view)
        self.view.addConstraints(subView: getCustomMessageVcObject().view)
        customMessageVcObj?.lblMessage.stringValue = msg
    }
    
    func okClickedFromCustomMessage(){
        addLog(text: "ok Clicked From CustomMessage")
        addLog(text: "enableOfficeMode from postpone nag")//
        SettingsManagerObject.isOfficeModeEnabled = true
        allApiObject.capturePosthog(event: "enable-office-mode", metadata: [:])
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
        NSApplication.shared.applicationIconImage = NSImage(named: NSImage.Name("Bear-Office-icon"))
        
        
        reFillBreakActivitiesArray()
        self.removeSubViews()
        currentState = ._MICRO_BREAK_
        
        if currentAction == ._BRAIN_DUMP_{
            addLog(text: "ok Clicked From Custom Message:- performBreakActivities break activity ")
            self.performBreakActivities()
        }else{
            addLog(text: "ok Clicked From Custom Message:- list break activity ")
            self.showCloseButtons()
            activityCompletionVcObj?.startBreakActivity()
            showBreakActivityListView()
        }
    }
    
    func performBreakActivities(){
        addLog(text: "perform Break Activities")
        guard hasBreakActivityToPlay() else { return }
        self.showCloseButtons()
        postponeBreaksFromBreaksWarningCount = 0
        if !(activityCompletionVcObj?.isViewLoaded ?? false){
            activityCompletionVcObj?.loadView()
        }
        activityCompletionVcObj?.startBreakActivity()
        mainWindowControllerObj?.window?.setIsVisible(true)
        showBlankWindowInSecondaryMonitor()
        
        showBreakActivityListView()
        
        /*
        if isBreakActivityShowingWhileMeeting{
            showBreakActivityListView()
        }else{
            currentAction = ._BRAIN_DUMP_//new work #502
            showBreaksBrainDump()
        }
         */
        
        shouldShowPomodoroAfterBreak = false
        leftMenuVcObj?.microBreaksStarted()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    /// The break-warning "Start" path reaches here without the refill the timed trigger does, so the
    /// list can be empty (every activity excluded or already played) — and `startBreakActivity()` used
    /// to crash subscripting it. Refill once; if there is still nothing to play, drop the break the way
    /// the timed trigger does and schedule the next one.
    private func hasBreakActivityToPlay() -> Bool {
        if arrFinalBreakActivities.isEmpty { reFillBreakActivitiesArray() }
        guard arrFinalBreakActivities.isEmpty else { return true }
        addLog(text: "performBreakActivities:- no break activity to play, cancelling this break")
        if currentState == ._MICRO_BREAK_ { currentState = ._NOTHING_ }
        setActivityTimer()
        return false
    }

    func showBreakActivityListView(){
        addLog(text: "showBreakActivityListView")
        currentAction = ._START_//new work #502
        self.removeSubViews()
        // The break start screen is its own SwiftUI screen (breakStartVc); routine habit lists still
        // use firstViewController.
        let breakStart = getBreakStartVcObject()
        habitsView.addSubview(breakStart.view)
        habitsView.addConstraints(subView: breakStart.view)
        breakStart.showBreakStart()
    }
    
    @IBAction func btnHiddenClicked(_ sender: Any) {
    }
    
    func showHabitState(){
        addLog(text: "showHabitState")
        self.removeSubViews()
        self.hideCloseButtons()
        habitsView.addSubview(getHabitsStateVcObject().view)
        habitsView.addConstraints(subView: getHabitsStateVcObject().view)
    }
    
    func showCustomRoutineState(){
        addLog(text: "showCustomRoutineState")
        self.removeSubViews()
        self.hideCloseButtons()
        habitsView.addSubview(getCustomRoutineStateVcObject().view)
        habitsView.addConstraints(subView: getCustomRoutineStateVcObject().view)
    }
    
    func showBreakState(){
        addLog(text: "showBreakState")
        self.removeSubViews()
        self.hideCloseButtons()
        habitsView.addSubview(getBreaksStateVcObject().view)
        habitsView.addConstraints(subView: getBreaksStateVcObject().view)
    }
}


