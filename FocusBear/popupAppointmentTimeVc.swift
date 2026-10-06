//
//  popupAppointmentTime.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class popupAppointmentTimeVc: NSViewController {

    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnBackToHabits: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    //var duration = 300
    var enterPasswordVcObj: enterPasswordVc?
    var currentTimer = 0
    var totalDuration = 120
    var timer:Timer?
    var endTime:Date?
    /// The meeting's title, kept so attending it can start a strict AI focus session with the meeting as
    /// the intention (Late No More → AI session), and so a dismissal here can be reported to the backend
    /// and silence the same meeting on the user's other devices.
    var appointmentTitle = ""
    // Fires startAppointment() once the meeting's own end time passes, so the popup can't sit open
    // (and the routine stay stuck) indefinitely if the user just doesn't click a button — the window
    // has no close button and nothing else was closing it. Only used on the no-password branch: the
    // password branch already has its own 120s give-up timer (performTimerCount below), and
    // auto-advancing past a required password would defeat the postpone-after-cutoff gate above.
    var autoCloseTimer: Timer?
    /// The meeting's start instant, as reported by Late No More. Together with the title this is how
    /// every platform identifies the same meeting — see `LateNoMoreDismissSync`.
    var appointmentStartTime: Date?
    /// One dismissal report per popup; the "Thanks!" and "I don't need to attend" paths both report.
    private var didReportDismissal = false
    /// Whether the postpone currently in flight came from the user acting on this popup. `autoCloseTimer`
    /// postpones the routine too, but a timeout is not the user telling us they dealt with the meeting,
    /// so it must not silence the reminder on their other devices.
    private var isPostponeUserInitiated = true
    var subTitle = "Unlocking your Mac so you can turn off Late No More appointment reminders. You have <TIMELEFT> to turn it off. Enter a password to continue using it until your appointment ends at <TIME>"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        btnOk.title = "Thanks!"
        btnBackToHabits.title = "Back to habits - I don't need to attend"
        
        if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
            lblTitle.stringValue = popupAppointmentTimeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            btnBackToHabits.title = popupAppointmentTimeVcInfo.value(forKey: "buttonBackToHabitsText") as? String ?? btnBackToHabits.title
            subTitle = popupAppointmentTimeVcInfo.value(forKey: "subTitle") as? String ?? subTitle
        }
        btnBackToHabits.isSecondaryButton = true
        lblTimer.isHidden = true
    }
    var shouldAskPassword = false

    /// The routine this popup will postpone, captured when the popup opens.
    ///
    /// `lastCurrentState` is a shared global that other flows overwrite while this window sits open —
    /// the countdown box's extend-postpone writes it, and so does every abort screen. When it no longer
    /// named a postponable routine, `startAppointment()` matched none of its branches: the window
    /// closed, NOTHING was postponed, and the user was dropped back on the Day Plan to postpone by hand
    /// (report 2026-09-14_11-53-06).
    private var routineToPostpone: CURRENTSTATE?

    /// The four routines this popup knows how to postpone; anything else is not one.
    private static func postponableRoutine(_ state: CURRENTSTATE) -> CURRENTSTATE? {
        [._MORNING_HABIT_, ._EVENING_HABIT_, ._MICRO_BREAK_, ._CUSTOM_ROUTINE_].contains(state) ? state : nil
    }

    func resetView(title:String, startTime:Date?, endTime:Date){
        self.endTime = endTime
        self.appointmentTitle = title
        // Prefer the state the event handler recorded; fall back to what is running right now.
        routineToPostpone = Self.postponableRoutine(lastCurrentState) ?? Self.postponableRoutine(currentState)
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        self.appointmentStartTime = startTime
        self.didReportDismissal = false
        if currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_{
            btnBackToHabits.isHidden = true
        }else{
            btnBackToHabits.isHidden = false
        }
        var message = "It looks like you have an appointment that is about to start: <EVENT_TITLE>. Pausing your habits so you can attend the appointment."
        if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
            message = popupAppointmentTimeVcInfo.value(forKey: "title") as? String ?? message
        }
        message = message.replacingOccurrences(of: "<EVENT_TITLE>", with: title)
        lblTitle.stringValue = message
        
        shouldAskPassword = computeShouldAskPassword()

        if !shouldAskPassword{
            if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
                btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            }
            lblSubTitle.isHidden = true

            btnOk.title = "Thanks!"
            if let popupAppointmentTimeVcInfo = configjson.value(forKey: "popupAppointmentTimeVcInfo") as? NSDictionary{
                btnOk.title = popupAppointmentTimeVcInfo.value(forKey: "buttonThanksText") as? String ?? btnOk.title
            }

            let fireInterval = max(endTime.timeIntervalSinceNow, 1)
            autoCloseTimer = Timer.scheduledTimer(withTimeInterval: fireInterval, repeats: false) { [weak self] _ in
                addLog(text: "popupAppointmentTimeVc:- auto-closing at meeting end time, no user action taken")
                // Re-evaluate the gate here too: the popup may have opened before the cutoff but be
                // auto-closing after it, in which case the postpone must now demand the password.
                self?.confirmPostpone(userInitiated: false)
            }
            RunLoop.main.add(autoCloseTimer!, forMode: .common)
        }else{
            lblSubTitle.isHidden = false
            btnOk.title = "Enter Password"
            startTimer()
        }
    }
    
    /// Tell the backend this meeting's reminder is done with on the Mac, so the user's other devices
    /// stop alerting for it (backend#2395 / mobile-app#5108). Best effort: the popup has already been
    /// dismissed locally by the time this runs, and a network failure neither reverts that nor is shown.
    private func reportDismissal(reason: LateNoMoreDismissReason) {
        guard !didReportDismissal else { return }
        guard let startTime = appointmentStartTime else {
            // Late No More omits event_start_time only on a malformed deep link; without it the backend
            // cannot identify which meeting was dismissed, so there is nothing useful to send.
            addLog(text: "popupAppointmentTimeVc:- no start time, not syncing dismissal")
            return
        }
        didReportDismissal = true
        let meeting = LateNoMoreMeeting(title: appointmentTitle, startDate: startTime)
        LateNoMoreDismissalRegistry.shared.recordDismissal(of: meeting)
        allApiObject.reportLateNoMoreDismissal(meeting: meeting, reason: reason)
    }

    @IBAction func btnOkClicked(_ sender: Any) {
        addLog(text: "[user-action] smallCountDownVc:- button Ok clicked")
        confirmPostpone()
    }

    // This popup always POSTPONES the running routine (startAppointment() below calls
    // postponeMorningHabitFor/postponeEveningHabitFor, never a skip), so it must honour the
    // postpone-specific password settings — not the skip ones. It used to check
    // isPasswordRequireInSkip{Morning,Evening,EveningAfterCutOff}, so a user with only the
    // postpone rules enabled (and skip rules off) got no password prompt at all when a Late No
    // More appointment postponed their routine, including after cutoff (bug report 2026-07-17).
    func computeShouldAskPassword() -> Bool {
        guard Focus_Bear.shouldAskPassword(forPostpone: true) else { return false }
        if currentState == ._MORNING_HABIT_ && SettingsManagerObject.isPasswordRequireInPostponeMorning{
            return true
        }else if currentState == ._EVENING_HABIT_ && SettingsManagerObject.isPasswordRequireInPostponeEvening && !isHighPrioritySequenceGoing && !isCutOffTimeGoing(){
            // This is the BEFORE-cutoff evening branch. Exclude cutoff time here so it doesn't
            // short-circuit the else-if and prevent the after-cutoff branch below from running.
            return true
        }else if currentState == ._EVENING_HABIT_ && SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff && (isHighPrioritySequenceGoing || isCutOffTimeGoing()){
            // isPasswordRequireInPostponeEveningAfterCutOff is an Evening-Habit-specific setting, so
            // this branch only governs postponing the evening habit — when a meeting/high-priority
            // sequence is running or it's past the cutoff time.
            // NOTE (tradeoff): this intentionally no longer requires the password past cutoff in
            // NON-evening states (shutoff / custom routine / break). An earlier version kept this
            // branch state-independent so a meeting popup appearing past cutoff in those states
            // couldn't be dismissed without a password. If that cross-state protection is still
            // wanted, gate each state on its own postpone-password setting rather than the evening one.
            return true
        }
        return false
    }

    // Confirm (or auto-close) the appointment postpone. The gate is RECOMPUTED here rather than trusting
    // the value cached in resetView: a Late No More meeting popup can open BEFORE the cutoff and only be
    // confirmed AFTER it (the meeting starts near the cutoff and the window sits open in between). With the
    // stale value, isCutOffTimeGoing() was false at open time so the after-cutoff branch never armed, and
    // the routine got postponed past cutoff with no password (bug report 2026-08-24). Recomputing at
    // action time re-arms isCutOffTimeGoing() / isHighPrioritySequenceGoing.
    func confirmPostpone(userInitiated: Bool = true) {
        isPostponeUserInitiated = userInitiated
        shouldAskPassword = computeShouldAskPassword()
        if !shouldAskPassword{
            startAppointment()
        }else{
            addLog(text: "smallCountDownVc:- enterPassword")
            if enterPasswordVcObj == nil{
                enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
            }
            self.presentAsSheet(enterPasswordVcObj!)
        }
    }

    func startAppointment(){
        addLog(text: "smallCountDownVc:- startAppointment")
        if isPostponeUserInitiated{
            // The user acknowledged the reminder here and is attending the meeting on this Mac.
            reportDismissal(reason: .joinedOnMac)
        }
        focusButtonServiceObject.dismissNotification()
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        // Seconds left in THIS meeting — sizes the strict AI focus session started below.
        // Deliberately NOT the postpone length: the postpone covers the whole live/imminent
        // chain (see `postponeSeconds`), while the AI session is scoped to this meeting.
        let duration = Calendar.current.dateComponents([.second], from: Date(), to: endTime!).second ?? 0
        // The postpone has to cover every meeting that is live or imminent — not just this popup's
        // own one — and must never come out SHORTER than a postpone already running. This used to be
        // `secondsRemainingInThisMeeting + 160`, which is fine when the user clicks "Thanks!" as the
        // meeting starts but collapses to a flat 160s on the auto-close path, where the popup fires
        // AT its meeting's end and there is no time remaining. With a meeting following straight on
        // (Lunch 12:45-13:00, UX checkin 13:00-13:20) that postponed the routine for 2m40s and the
        // "Habit resumes in…" countdown appeared 40s into the next call (report 2026-09-15_13-03-02).
        let postponeSeconds = MeetingCoverage.postponeSeconds(now: Date(),
                                                              meetings: AnnouncedMeetingRegister.shared.activeMeetings(),
                                                              appointmentEnd: endTime,
                                                              currentPostponeEnd: currentRoutinePostponeEndDate())
        addLog(text: "startAppointment:- postponing for \(postponeSeconds) seconds (meeting-aware)")
        // The captured routine, not the live global — see `routineToPostpone`.
        let routine = routineToPostpone ?? Self.postponableRoutine(lastCurrentState)
        switch routine {
        case ._MORNING_HABIT_?:
            getHabitsVcObject().postponeMorningHabitFor(minutes: 0, secondsToPostpone: postponeSeconds, showAskFocusModeView:false, showAskIntention:false)
        case ._EVENING_HABIT_?:
            getHabitsVcObject().postponeEveningHabitFor(minutes: 0, secondsToPostpone: postponeSeconds, showAskFocusModeView:false, showAskIntention:false)
        case ._MICRO_BREAK_?:
            // Breaks get THIS meeting's coverage, never the chain's — see `recursThroughTheDay`.
            let breakSeconds = MeetingCoverage.postponeSeconds(for: routine, now: Date(),
                                                              meetings: AnnouncedMeetingRegister.shared.activeMeetings(),
                                                              appointmentEnd: endTime,
                                                              currentPostponeEnd: currentRoutinePostponeEndDate(),
                                                              breaksAllowedDuringMeetings: SettingsManagerObject.IsShowBreaksInCallEnabled,
                                                              breakIntervalSeconds: breakAfterMinutes * 60)
            addLog(text: "startAppointment:- break postpone \(breakSeconds)s (this meeting only, not the \(postponeSeconds)s chain)")
            getHabitsVcObject().postponeBreakActivitiesFor(minutes: 0, secondsToPostpone: breakSeconds, isFromBreakWarningWindow: false)
        case ._CUSTOM_ROUTINE_?:
            getHabitsVcObject().postponeCustomRoutineFor(minutes: 0, secondsToPostpone: postponeSeconds, showAskFocusModeView: false, showAskIntention: false, fromRoutineWarning:false)
        default:
            // Never silent again: this is the "postpone did nothing and I was back on the Day Plan" case.
            addLog(text: "startAppointment: nothing to postpone (captured=\(String(describing: routineToPostpone)) last=\(lastCurrentState) current=\(currentState))")
        }
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()

        // The user is attending the meeting → run a strict AI focus session for its duration with the
        // meeting title as the intention, so only meeting-relevant apps/sites stay open. Gated on the
        // same AI-accountability setting as the postpone buddy, so it's opt-in.
        // The event-about-to-start handler already starts this session at meeting-start for the full
        // duration, so only start here if one isn't already live — otherwise the auto-close-at-end timer
        // (duration ≈ 0) would restart it as a useless ~1-minute session. This start remains as a fallback
        // for any path that reaches startAppointment without the handler having started a session.
        if SettingsManagerObject.isAccountabilityBuddyEnabled, currentAccountabilityBuddySession == nil {
            startMeetingFocusSession(title: appointmentTitle, durationMinutes: max(1, duration / 60))
        }
    }

    @IBAction func btnBackToHabitsClicked(_ sender: Any) {
        addLog(text: "[user-action] smallCountDownVc:- button back to habits clicked")
        // The meeting AI focus session is auto-started when the event begins (see AppDelegate
        // event-about-to-start), independently of this popup. Choosing "I don't need to attend" must
        // CANCEL that session — otherwise it keeps running and overrides the routine's allowed apps.
        if currentAccountabilityBuddySession != nil {
            addLog(text: "back-to-habits: cancelling auto-started meeting focus session")
            appdelegate?.tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false, allowExtend: false, isCustomRoutineTime: false, shouldUpdateFocusButton: true)
        }
        // "I don't need to attend" — the user is skipping the meeting, so every device should stop.
        reportDismissal(reason: .stopReminders)
        returnToHabits()
    }

    /// Close the popup and hand the screen back to the routine. Shared by the user's "I don't need to
    /// attend" click and the password give-up timeout; only the click reports a cross-device dismissal.
    private func returnToHabits() {
        focusButtonServiceObject.dismissNotification()
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()
        if currentHabitPlaying == nil && currentActivityPlaying == nil{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
        }else{
//            getSmallCountDownWindowObject().showWindow(self)
//            getsmallCountDownVcObject().view.isHidden = false
            showSmallTimerView()
        }
        mainViewControllerObj?.showHabitsView()
        getHabitsVcObject().abortCancel()
    }
    
    func startTimer() {
        currentTimer = 0
        totalDuration = 120
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
       
        let stringDate = getDisplayStringFromDate(date: endTime!, dateFormat: "hh:mm a")
        var subTitleText = subTitle.replacingOccurrences(of: "<TIMELEFT>", with: "\(minute):\(second)")
        subTitleText = subTitleText.replacingOccurrences(of: "<TIME>", with: stringDate)
        lblSubTitle.stringValue =  subTitleText
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
            let stringDate = getDisplayStringFromDate(date: self.endTime!, dateFormat: "hh:mm a")
            var subTitleText = self.subTitle.replacingOccurrences(of: "<TIMELEFT>", with: "\(minute):\(second)")
            subTitleText = subTitleText.replacingOccurrences(of: "<TIME>", with: stringDate)
            self.lblSubTitle.stringValue =  subTitleText
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.lblTimer.isHidden = true
                    if self.enterPasswordVcObj != nil{
                        if self == self.enterPasswordVcObj?.presentingViewController{
                            self.enterPasswordVcObj!.dismiss(self.enterPasswordVcObj!)
                        }
                    }
                    self.returnToHabits()
                }
            }
        }
    }
}
