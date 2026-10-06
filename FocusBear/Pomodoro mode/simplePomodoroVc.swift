//
//  simplePomodoroVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.
//
//  The regular (non-geek) focus-session start screen. It used to be a storyboard scene of ~24 outlets
//  with a "Focus Settings" accordion hiding the strictness slider, the blocking-style radios, the
//  break duration and the intention. Those all moved to the advanced screen; what is left is the one
//  dial the design asks for, hosted from FocusBear/FocusStart (Figma "0.0/ Flow Start").
//
//  As in pomodoroVc, the start logic itself did not move: `startTapped()` and `pomodoroModeStarted()`
//  are the original code with the outlet reads swapped for reads off `state`.
//

import Cocoa
import SwiftUI

class simplePomodoroVc: NSViewController {

    /// Replaces the storyboard outlets. Held as AnyObject because FocusStartState is only meaningful
    /// to the macOS 11+ SwiftUI screen; stored properties cannot be `@available`-guarded.
    private var focusStartState: AnyObject?

    @available(macOS 11.0, *)
    var state: FocusStartState {
        if let existing = focusStartState as? FocusStartState { return existing }
        let created = FocusStartState()
        created.onStart = { [weak self] in self?.startTapped() }
        created.onFixPermissions = { [weak self] in self?.fixPermissionsTapped() }
        created.onSwitchMode = { [weak self] in self?.switchToAdvancedModeTapped() }
        created.onAiBlockingBlockedByTrial = { showUpgradeToProNagForAiBlocking() }
        focusStartState = created
        return created
    }

    var browserPermissionGiven = false
    var breakRatio = 1
    var isBreakDurationComesFromBreakRatio = false
    var workDurationZeroErrorText = "Work Duration can not be 0."

    var alertExtendPostpone: NSAlert?
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc

    var isIntentionFromMorningPostpone = false
    var intentionToShowAgain = ""
    var isViewVisible = false
    var arrAllTasks: [NSDictionary] = []

    /// Which of the two built-in focus modes this screen runs: the AI one (`isDeepWorkFocus`) or the
    /// super-distracting-sites one (`isDefault`). Driven by the AI-blocking choice, exactly as the old
    /// blocking-style radios did.
    var focusModeKey = "isDefault"

    // MARK: - Shims for the code outside this screen that used to poke its outlets

    var workDurationMinutes: Int {
        get {
            guard #available(macOS 11.0, *) else { return currentPomodoroWorkDuration }
            return state.duration.minutes
        }
        set {
            guard #available(macOS 11.0, *) else { return }
            state.duration = FocusStartDuration(minutes: FocusStartDuration.clamp(newValue),
                                                isUntimed: state.duration.isUntimed)
        }
    }

    var goalText: String {
        get {
            guard #available(macOS 11.0, *) else { return "" }
            return state.goal
        }
        set {
            guard #available(macOS 11.0, *) else { return }
            state.goal = newValue
        }
    }

    // MARK: - Lifecycle

    override func loadView() {
        let container = NSView()
        guard #available(macOS 11.0, *) else {
            view = container
            return
        }
        let hosting = NSHostingView(rootView: FocusStartSimpleScreen(state: state))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // Let the window's size win over the hosting view's ideal size, or the main window grows to
        // fit the content instead of scrolling it.
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.setContentCompressionResistancePriority(.init(1), for: .vertical)
        hosting.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        hosting.setContentHuggingPriority(.init(1), for: .vertical)
        hosting.setContentHuggingPriority(.init(1), for: .horizontal)
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary {
            workDurationZeroErrorText = preferencesInfo.value(forKey: "workDurationZeroErrorText") as? String ?? workDurationZeroErrorText
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroTourShown) == nil {
            UserDefaults.standard.set(true, forKey: kUserdefaultsPomodoroTourShown)
        }
    }

    override func viewWillAppear() {
        guard #available(macOS 11.0, *) else { return }
        getTaskPlayerVcObject().loadView()
        getTaskPlayerVcObject().loadRequest()

        let strictnessStored = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeStrictness) as? Int
            ?? (SettingsManagerObject.isCuddlyModeEnabled ? FocusStartStrictness.junior.storedValue
                                                          : FocusStartStrictness.pawfessor.storedValue)
        state.strictness = FocusStartStrictness.fromStored(strictnessStored)

        applyAiBlockingSelection()
        loadLastIntentionOfFocusMode()

        state.isStartEnabled = true
        state.isDurationEditable = true
        startTimer()

        // #777: default the duration to the focus mode's last-used duration (fallback: last focus
        // mode's duration, then 20). applyAiBlockingSelection() has set focusModeKey to the mode in use.
        state.duration = FocusStartDuration(minutes: FocusStartDuration.clamp(defaultDurationMinutesForDefaultMode()),
                                            isUntimed: state.duration.isUntimed)
        updateBreakDuration()

        self.view.window?.styleMask.insert(.closable)
        if !nextFocusSessionIntention.isEmpty {
            state.goal = nextFocusSessionIntention
        }
        loadTaskSuggestions()
    }

    override func viewDidAppear() {
        guard #available(macOS 11.0, *) else { return }
        state.isExpired = isExpired
        refreshPermissionsBanner()
        applySuperStrictBlockingScheduleLock()
        isViewVisible = true
    }

    override func viewWillDisappear() {
        isIntentionFromMorningPostpone = false
        timer?.invalidate()
        timer = nil
        if alertExtendPostpone != nil {
            if alertExtendPostpone!.window.isVisible {
                self.view.window!.endSheet(alertExtendPostpone!.window)
            }
        }
        if enterPasswordVcObj != nil {
            if self == enterPasswordVcObj!.presentingViewController {
                enterPasswordVcObj!.dismiss(enterPasswordVcObj!)
            }
        }
        isViewVisible = false
    }

    // MARK: - Screen configuration

    /// The trial gate on AI blocking. A lapsed trial is forced onto the super-distracting-sites list;
    /// everyone else gets their remembered choice (defaulting to AI on). Unchanged from the old
    /// blocking-style radios — the choice now lives on the advanced screen's AI badge, and this screen
    /// inherits whatever it last stored.
    @available(macOS 11.0, *)
    private func applyAiBlockingSelection() {
        if isExpired {
            state.isAiBlockingOn = false
        } else if let stored = UserDefaults.standard.object(forKey: kUserdefaultsSimplePomodoroAiBlockingSelected) as? Bool {
            state.isAiBlockingOn = stored
        } else {
            UserDefaults.standard.set(true, forKey: kUserdefaultsSimplePomodoroAiBlockingSelected)
            state.isAiBlockingOn = true
        }
        focusModeKey = state.isAiBlockingOn ? "isDeepWorkFocus" : "isDefault"
    }

    @available(macOS 11.0, *)
    func loadLastIntentionOfFocusMode() {
        state.goal = ""
        for i in 0..<arrFocusType.count {
            // This key is only present on the built-in focus types.
            if arrFocusType[i][focusModeKey] as? Bool == true {
                state.goal = arrFocusType[i]["lastIntentionUsed"] as? String ?? ""
                break
            }
        }
    }

    /// #777: default duration (minutes) for the focus mode in use (`focusModeKey`) — its own last-used
    /// duration, else the last duration used for any focus mode, else 20 (spec default when nothing ran).
    private func defaultDurationMinutesForDefaultMode() -> Int {
        for i in 0..<arrFocusType.count {
            if arrFocusType[i][focusModeKey] as? Bool == true,
               let perMode = arrFocusType[i]["lastDurationUsed"] as? Int, perMode > 0 {
                return perMode
            }
        }
        let lastAny = UserDefaults.standard.integer(forKey: kUserdefaultsLastFocusModeMinutes)
        return lastAny > 0 ? lastAny : 20
    }

    /// The break length is derived from the session length on this screen (a fixed 5:1 work-to-break
    /// ratio), never entered by hand.
    func updateBreakDuration() {
        guard #available(macOS 11.0, *) else { return }
        state.recomputeBreakDuration(workRatio: 5, breakRatio: breakRatio)
        isBreakDurationComesFromBreakRatio = true
    }

    /// Feeds the Todo Player's "first task" the same list the old searchable combo box offered:
    /// non-completed tasks, newest first.
    private func loadTaskSuggestions() {
        arrAllTasks.removeAll()
        allApiObject.getAllTasks(completionHandler: { json in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let json = json else { return }
                let filteredTasks = json.filter { task in
                    (task.value(forKey: "status") as? String ?? "").uppercased() != "COMPLETED"
                }
                self.arrAllTasks = filteredTasks.sorted { first, second in
                    let firstDate = simplePomodoroVc.utcDate(from: first.value(forKey: "created_at") as? String ?? "") ?? Date.distantPast
                    let secondDate = simplePomodoroVc.utcDate(from: second.value(forKey: "created_at") as? String ?? "") ?? Date.distantPast
                    return firstDate > secondDate
                }
            }
        })
    }

    private static func utcDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.date(from: dateString)
    }

    @available(macOS 11.0, *)
    private func refreshPermissionsBanner() {
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil {
            browserPermissionGiven = false
            state.permissionsTip = state.strings.permissionsTipFirst
            return
        }
        browserPermissionGiven = false
        state.permissionsTip = nil
        DispatchQueue.global().async {
            if let arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String: Any]] {
                for info in arrBrowsersInfo where info["isEnabled"] as? Bool ?? false {
                    self.browserPermissionGiven = true
                    break
                }
            }
            DispatchQueue.main.async {
                if !self.browserPermissionGiven {
                    self.state.permissionsTip = self.state.strings.permissionsTipSecond
                }
            }
        }
    }

    /// A running super-strict blocking schedule stops a session being started at all from this screen.
    /// Any *other* running schedule only gets named — it blocks, but it is not a focus session and must
    /// not stop one being started (report 2026-09-16_15-13-57).
    @available(macOS 11.0, *)
    private func applySuperStrictBlockingScheduleLock() {
        state.isStartEnabled = true
        state.blockingScheduleNotice = nil
        state.activeBlockingScheduleText = nil
        guard let schedule = customBlockingScheduleManagerObj.runningSchedule else { return }
        guard currentFocusModeStrictness == ._SUPER_STRICT_ else {
            state.activeBlockingScheduleText = state.strings.activeBlockingScheduleText(
                name: schedule.name, until: schedule.endTime.formattedTime())
            return
        }
        state.isStartEnabled = false
        state.blockingScheduleNotice = state.strings.superStrictScheduleBlocksStart
    }

    func showAlert(msg: String) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        guard let window = self.view.window else { return }
        alertWarning.beginSheetModal(for: window, completionHandler: nil)
    }

    // MARK: - Screen actions

    func fixPermissionsTapped() {
        guard #available(macOS 11.0, *), let window = self.view.window else { return }
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil {
            presentBrowserPermissionsAlert(in: window, onProceedAnyway: nil)
            return
        }
        if !browserPermissionGiven {
            showExplainingPermissionsWindow(showingFromPomodoro: true)
            intentionToShowAgain = state.goal
            window.close()
        }
    }

    /// Follows the "Top Secret / Extra Powerful Options ›" link. Switched through
    /// `switchAppMode(toGeekMode:)` so all the isGeekModeEnabled read/write sites stay in step.
    func switchToAdvancedModeTapped() {
        addLog(text: "[user-action] focus start flow → extra powerful options")
        switchAppMode(toGeekMode: FocusStartMode.simple.geekModeAfterFollowingLink)
        appdelegate?.menuShowPomodoroModeView()
    }

    // MARK: - Starting a session

    func startTapped() {
        guard #available(macOS 11.0, *) else { return }
        addLog(text: "[user-action] btnLetsDoItClicked")
        if state.duration.effectiveMinutes < FocusStartDuration.minimumMinutes {
            showAlert(msg: workDurationZeroErrorText)
            return
        }

        // The permissions gate only fires when AI blocking is on — the super-distracting-sites list
        // works without browser permissions.
        if state.isAiBlockingOn, UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil {
            guard let window = self.view.window else { return }
            presentBrowserPermissionsAlert(in: window, onProceedAnyway: { [weak self] in self?.startTapped() })
            // Written immediately, before the sheet is answered, so the "No thanks" branch's recursive
            // call falls straight through this gate instead of looping.
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
            return
        }

        if UserDefaults.standard.object(forKey: kUserdefaultsManageTaskFirstTime) == nil {
            UserDefaults.standard.set(true, forKey: kUserdefaultsManageTaskFirstTime)
            // Previously prompted "Do you want to use Focus Bear for your to do list?". The prompt is
            // removed — default to the "Try it out" path directly: enable the To Do player, then fall
            // through to start the session.
            addLog(text: "UseToDoList first time from simple pomodoro view: defaulting to Try it out (no prompt)")
            if !SettingsManagerObject.showToDoPlayerAutomaticallyEnabled {
                SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = true
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
            }
        }

        currentPomodoroWorkDuration = state.duration.effectiveMinutes
        currentPomodoroBreakDuration = state.breakDurationMinutes

        let totalMinutes = state.duration.effectiveMinutes
        if currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_ {
            if presentPostponeExtensionAlertIfNeeded(totalMinutes: totalMinutes) { return }
        }
        nextFocusSessionIntention = ""
        pomodoroModeStarted()
        closeAfterStarting()
    }

    private func closeAfterStarting() {
        if currentState != ._MICRO_BREAK_ {
            // won't work if the view has changed (the task player is visible now), because the window
            // is nil once the main view swaps — v 2.28.438
            self.view.window?.close()
        } else {
            leftMenuVcObj?.showBreaksView()
        }
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
    }

    private func presentBrowserPermissionsAlert(in window: NSWindow, onProceedAnyway: (() -> Void)?) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = "Do you want to block distractions?"
        alertWarning.informativeText = "You will need to allow permissions to block distracting websites."
        var buttonBlockText = "Yeah - block them!"
        var buttonNoText = "No thanks"
        if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary {
            alertWarning.messageText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsTitle") as? String ?? alertWarning.messageText
            alertWarning.informativeText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsInfo") as? String ?? alertWarning.informativeText
            buttonBlockText = simplePomodoroVcInfo.value(forKey: "buttonBlockText") as? String ?? buttonBlockText
            buttonNoText = simplePomodoroVcInfo.value(forKey: "buttonNoText") as? String ?? buttonNoText
        }
        alertWarning.addButton(withTitle: buttonBlockText)
        alertWarning.addButton(withTitle: buttonNoText)
            .setAccessibilityIdentifier(UITestContract.Identifier.FocusStart.declineBlockingButton)
        alertWarning.beginSheetModal(for: window, completionHandler: { [weak self] modalResponse in
            guard let self = self else { return }
            if modalResponse == .alertFirstButtonReturn {
                showExplainingPermissionsWindow(showingFromPomodoro: true)
                if #available(macOS 11.0, *) { self.intentionToShowAgain = self.state.goal }
                self.view.window?.close()
            } else {
                onProceedAnyway?()
            }
        })
    }

    /// The habit-postpone extension flow. This screen's password matrix is smaller than the advanced
    /// one's: morning postpones extend with no password, evening ones only ask after a cut-off, and
    /// focus-summary postpones never ask. Returns true when it took over (an alert is up).
    private func presentPostponeExtensionAlertIfNeeded(totalMinutes: Int) -> Bool {
        guard let postponeTimer = getHabitsVcObject().postponeTimer, postponeTimer.isValid,
              let window = self.view.window else { return false }
        let diffMinute = Calendar.current.dateComponents([.minute], from: Date(), to: postponeTimer.fireDate).minute ?? 0
        guard diffMinute < totalMinutes else { return false }

        alertExtendPostpone = NSAlert()
        alertExtendPostpone!.setSharingType()
        alertExtendPostpone!.messageText = "Focus duration is longer than habit postpone duration."
        alertExtendPostpone!.informativeText = "You may want to extend the postpone duration to match the focus session duration. Click on the desired button to start the focus session."
        var buttonExtendPostponeText = "Extend postpone duration"
        var buttonDoNotExtendPostponeText = "Do not extend postpone duration"
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary {
            alertExtendPostpone!.messageText = pomodoroInfo.value(forKey: "alertExtendPostponeText") as? String ?? alertExtendPostpone!.messageText
            alertExtendPostpone!.informativeText = pomodoroInfo.value(forKey: "alertExtendPostponeDescription") as? String ?? alertExtendPostpone!.informativeText
            buttonExtendPostponeText = pomodoroInfo.value(forKey: "buttonExtendPostponeText") as? String ?? buttonExtendPostponeText
            buttonDoNotExtendPostponeText = pomodoroInfo.value(forKey: "buttonDoNotExtendPostponeText") as? String ?? buttonDoNotExtendPostponeText
        }
        alertExtendPostpone!.alertStyle = NSAlert.Style.warning
        alertExtendPostpone!.addButton(withTitle: buttonExtendPostponeText)
        alertExtendPostpone!.addButton(withTitle: buttonDoNotExtendPostponeText)
        alertExtendPostpone!.beginSheetModal(for: window, completionHandler: { [weak self] modalResponse in
            guard let self = self else { return }
            if modalResponse == .alertFirstButtonReturn {
                if self.extendPostponeThenStart(totalMinutes: totalMinutes) { return }
            } else if modalResponse == .alertSecondButtonReturn {
                self.pomodoroModeStarted()
            }
            self.closeAfterStarting()
        })
        return true
    }

    /// Returns true when it handed off to the password sheet, so the caller leaves the window open.
    private func extendPostponeThenStart(totalMinutes: Int) -> Bool {
        if currentState == ._POSTPONE_MORNING_HABIT_ {
            getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
            pomodoroModeStarted()
            return false
        }
        if currentState == ._POSTPONE_EVENING_HABIT_ {
            if SettingsManagerObject.isEasySkipEnabled {
                getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                pomodoroModeStarted()
                return false
            }
            let shouldAskPasswordForEvening = shouldAskPassword()
                && cutOffTime != nil
                && SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff
                && isCutOffTimeGoing()
            if shouldAskPasswordForEvening {
                if let passwordVc = enterPasswordVcObj {
                    presentAsSheet(passwordVc)
                    passwordVc.parentVc = self
                }
                return true
            }
            getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
            pomodoroModeStarted()
            return false
        }
        if currentState == ._POSTPONE_FOCUS_SUMMARY_ {
            getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
            pomodoroModeStarted()
        }
        return false
    }

    func pomodoroModeStarted() {
        guard #available(macOS 11.0, *) else { return }
        addLog(text: "pomodoro mode Started")
        isFocusModeStartedAutomatically = false
        if arrFocusTypeForPomodoro.count == 0 {
            return
        }
        switch state.strictness {
        case .junior:
            currentFocusModeStrictness = ._NORMAL_
            addLog(text: "focus mode is normal mode")
        case .captain:
            currentFocusModeStrictness = ._STRICT_
            addLog(text: "focus mode is strict mode")
        case .pawfessor:
            currentFocusModeStrictness = ._SUPER_STRICT_
            addLog(text: "focus mode is super strict mode")
        }
        UserDefaults.standard.set(state.strictness.storedValue, forKey: kUserdefaultsLastFocusModeStrictness)

        // App should remember the last focus session + break duration. If you change it to 40 minutes,
        // it should remember that for next time. 29/7/25 v 1.26.395
        let count = state.duration.effectiveMinutes
        if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int {
            if count != oldCount {
                SettingsManagerObject.isSettingsChanged = true
                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes)
                SettingsManagerObject.putUserLocalDeviceSettings()
            }
        }

        let minute = state.duration.effectiveMinutes
        let calendar = Calendar.current
        endFocusModeTime = calendar.date(byAdding: .minute, value: minute, to: Date())
        startFocusModeTime = Date()

        for i in 0..<arrFocusType.count {
            arrFocusType[i]["isOn"] = false
            arrFocusType[i]["isPaused"] = false
        }

        getTotalFocuedTime()
        // After finishing a pomodoro block, clicking "start another focus block" must use the right
        // focus mode #741 — so the AI choice is re-applied here, not just at open.
        focusModeKey = state.isAiBlockingOn ? "isDeepWorkFocus" : "isDefault"
        UserDefaults.standard.set(state.isAiBlockingOn, forKey: kUserdefaultsSimplePomodoroAiBlockingSelected)
        SettingsManagerObject.isAiCheckUrlEnabled = state.isAiBlockingOn

        minFocusAlignmentScoreToShowDistractingPopUp = 99.9
        if SettingsManagerObject.isDataCollectionModeEnabled {
            minFocusAlignmentScoreToShowDistractingPopUp = 0
        }
        for i in 0..<arrFocusType.count {
            // This key is only present on the built-in focus types.
            guard arrFocusType[i][focusModeKey] as? Bool == true else { continue }
            arrFocusType[i]["isOn"] = true
            arrFocusType[i]["lastStartedDate"] = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            arrFocusType[i]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            shouldReloadTaskPlayer = true
            let focusModeId = arrFocusType[i]["id"] as? String ?? ""
            let focusModeName = arrFocusType[i]["name"] as? String ?? ""
            addLog(text: "Focus mode name is:- \(focusModeName)")// added v 3.31.474
            addLog(text: "Focus mode id is:- \(focusModeId)")// added v 3.31.474

            if isAccessibilityEnabled(isPrompt: true) {
                DNDManager.shared.setDND(true)
            }
            workBeforeFocusBegin(index: i)
            arrFocusType[i]["lastIntentionUsed"] = state.goal.isEmpty ? "" : state.goal
            // #777: remember the chosen duration for this focus mode so it defaults to its own last
            // duration next time. Also bump the global last-duration so a brand-new focus mode
            // inherits it via the fallback.
            arrFocusType[i]["lastDurationUsed"] = minute
            UserDefaults.standard.set(minute, forKey: kUserdefaultsLastFocusModeMinutes)
            // Start with what this screen has, NOT the block list's `lastTaskUsed` — that is the
            // previous session's queue, and restoring it here silently re-queued work the user never
            // chose (report 2026-09-15_16-46-10). The simple screen has no task picker, so this is
            // normally an empty queue; the in-session screen's empty state is where a task is added.
            // Matches pomodoroVc's advanced start path.
            focusModeTaskString = state.taskQueueForSessionStart
            arrFocusType[i]["lastTaskUsed"] = focusModeTaskString
            SensitiveDefaults.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            updateAllFocusModes()
            taskCreatedByBlockPopup = ""
            appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString: arrFocusType[i]["color"] as? String ?? "")
            break
        }

        isFocusModeRunning = true
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: state.goal)
        appdelegate!.statusbutton?.imagePosition = .imageLeft

        if timerForFocusMode != nil {
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil {
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }

        appdelegate?.setFocusModeTimer(hour: nil, minute: minute)
        //focusButtonService
        focusButtonServiceObject.startFocusSession(seconds: minute * 60)

        isFocusModeStartedFromPomodoroMode = true
        isSkipBreakActivityDuringPomodoro = true
        addLog(text: "SkipBreakActivityDuringPomodoro is true in simple focus session.")
        whatToAchieveInFocusBlock = state.goal
        appdelegate!.focusModeStartted(isStartedByPusher: false)

        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled && currentState != ._MICRO_BREAK_ {
            applyFirstTaskToPlayer()
            showRunningFocusSessionWindow()
        } else {
            if !getTaskPlayerVcObject().isViewLoaded {
                getTaskPlayerVcObject().loadView()
            }
            applyFirstTaskToPlayer()
            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: state.goal)
            shouldReloadTaskPlayer = false
        }

        allApiObject.capturePosthog(event: "start-focus-session-manually", metadata: ["type": "simple-focus", "focusDuration": currentPomodoroWorkDuration, "breakDuration": currentPomodoroBreakDuration])
    }

    @available(macOS 11.0, *)
    private func applyFirstTaskToPlayer() {
        guard !state.firstTask.isEmpty else { return }
        taskPlayerVcObj?.taskToLoadForFirstTime = state.firstTask
        taskPlayerVcObj?.arrAllTasks = arrAllTasks
    }

    func passwordIsCorrect() {
        isHardCorePomodoroModeOn = false
        self.view.window?.close()
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
    }

    // MARK: - "Time spent unfocused" counter

    var timer: Timer?
    var currentTimer = 0

    func startTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        currentTimer = unfocusedTime
        setProgres()
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }

    func setProgres() {
        guard #available(macOS 11.0, *) else { return }
        let text = state.strings.unfocusedTimer.replacingOccurrences(of: FocusStartPlaceholder.time,
                                                                    with: formattedUnfocusedTime(currentTimer))
        DispatchQueue.main.async {
            self.state.unfocusedTimerText = text
        }
    }

    @objc func performTimerCount() {
        if !appdelegate!.isSystemSleep && !appdelegate!.isScreenSaverStart && currentState != ._MICRO_BREAK_ {
            currentTimer += 1
        }
        setProgres()
    }
}
