//
//  pomodoroVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.
//
//  The advanced ("geek mode") focus-session start screen. It used to be a storyboard scene of ~30
//  outlets — a scroll view of stack views, text fields, a strictness slider and two pop-up buttons.
//  It now hosts the SwiftUI screen in FocusBear/FocusStart (Figma "0.1 Set Duration" / "0.2 Set Goal"
//  / "0.3 Set Blocking" — one screen, three accordion cards) in an NSHostingView, per this repo's
//  "new/modified Mac UI is SwiftUI" convention.
//
//  What deliberately did NOT move: everything between pressing Start and the session actually
//  starting. `startTapped()` → `checkStateAndStartPomodoroMode()` → `pomodoroModeStarted()` are the
//  same code they always were, with the outlet reads swapped for reads off `state`
//  (FocusStartState). That keeps the trial gate, the browser-permissions gate, the habit-postpone
//  extension flow and its password matrix, `workBeforeFocusBegin`, DND, Super Focus counts, the
//  focus-alignment-score threshold and the ordering of `isFocusSessionStartedFromPostponeIntention`
//  exactly as they were.
//

import Cocoa
import SwiftUI

class pomodoroVc: NSViewController {

    /// Replaces the storyboard outlets: what the user picked, and what the screen is allowed to show.
    /// Held as AnyObject because FocusStartState is only meaningful to the macOS 11+ SwiftUI screen;
    /// stored properties cannot be `@available`-guarded.
    private var focusStartState: AnyObject?

    @available(macOS 11.0, *)
    var state: FocusStartState {
        if let existing = focusStartState as? FocusStartState { return existing }
        let created = FocusStartState()
        created.onStart = { [weak self] in self?.startTapped() }
        created.onEditBlockLists = { [weak self] in self?.editBlockListsTapped() }
        created.onEditBlockList = { [weak self] id in self?.editBlockListsTapped(focusModeId: id) }
        created.onFixPermissions = { [weak self] in self?.fixPermissionsTapped() }
        created.onSwitchMode = { [weak self] in self?.switchToSimpleModeTapped() }
        created.onBlockListChanged = { [weak self] in self?.focusModeSelected() }
        created.onAiBlockingBlockedByTrial = { showUpgradeToProNagForAiBlocking() }
        focusStartState = created
        return created
    }

    var browserPermissionGiven = false

    var workRatio = 5
    var breakRatio = 1
    var isBreakDurationComesFromBreakRatio = false
    var isShowingMorningPomodoro = false
    var isShowingPomodoroManually = false
    var isShowingMorningHardcorePomodoro = false

    var workDurationZeroErrorText = "Work Duration can not be 0."

    var isSkipMicrobreaks = false
    var isFrictionLevelHigh = false

    var alertExtendPostpone: NSAlert?
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc // only for cutOffTime in hardskip

    var isIntentionFromMorningPostpone = false
    /// True once the user has manually edited the goal field this session, so switching the block-list
    /// dropdown won't overwrite what they typed. Reset in viewWillDisappear (like
    /// isIntentionFromMorningPostpone) so the block's last-used intention is auto-filled again next open.
    var hasUserTypedIntention = false
    var intentionToShowAgain = ""
    var titleAfterPostpone = "What do you want to do instead of your habits?"
    var isViewVisible = false

    // MARK: - Shims for the code outside this screen that used to poke its outlets

    /// Was `textFieldWorkDuration.integerValue`. Read by enterPasswordVc when it resumes a postpone,
    /// written by habitsVc when a postpone pre-fills the session length.
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

    /// Was `textViewAchieve.string` — the goal/intention field.
    var goalText: String {
        get {
            guard #available(macOS 11.0, *) else { return "" }
            return state.goal
        }
        set {
            guard #available(macOS 11.0, *) else { return }
            state.goal = newValue
            hasUserTypedIntention = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Was `lblTitle.stringValue = titleAfterPostpone`. The design's headline is fixed, so a postpone
    /// swaps it for its own question instead of writing into a label.
    func showPostponeTitle() {
        guard #available(macOS 11.0, *) else { return }
        state.postponeTitle = titleAfterPostpone
    }

    // MARK: - Lifecycle

    /// Built in code (no storyboard subviews) — new Mac UI is SwiftUI hosted in an NSHostingView.
    override func loadView() {
        let container = NSView()
        guard #available(macOS 11.0, *) else {
            view = container
            return
        }
        let hosting = NSHostingView(rootView: FocusStartAdvancedScreen(state: state))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // The hosting view's intrinsic (ideal) size is the whole card stack; at the default 750
        // compression resistance it outranks the window's size (windowSizeStayPut = 500) and would
        // grow the main window to fit. Let the window size win so the screen scrolls instead.
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
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary {
            titleAfterPostpone = pomodoroInfo.value(forKey: "titleAfterPostpone") as? String ?? titleAfterPostpone
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAdvancedPomodoroEnabled) == nil {
            UserDefaults.standard.set(false, forKey: kUserdefaultsIsAdvancedPomodoroEnabled)
        }
    }

    override func viewWillAppear() {
        guard #available(macOS 11.0, *) else { return }
        let strictnessStored = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeStrictness) as? Int
            ?? (SettingsManagerObject.isCuddlyModeEnabled ? FocusStartStrictness.junior.storedValue
                                                          : FocusStartStrictness.pawfessor.storedValue)
        state.strictness = FocusStartStrictness.fromStored(strictnessStored)

        state.isContinuingSuperFocusRun = isHardCorePomodoroModeOn && !isShowingMorningHardcorePomodoro
        state.isAiBlockingOn = SettingsManagerObject.isAiCheckUrlEnabled
        state.breakFrequencyMinutes = breakAfterMinutes > 0 ? breakAfterMinutes : 60
        if state.shouldResetWorkChoicesOnNextOpen {
            state.hasChosenGoal = false; state.selectedProjectID = nil; state.selectedTasks = []
            state.isEditingGoal = false; state.isTaskSearchExpanded = false
            state.projectQuery = ""; state.taskQuery = ""
            state.shouldResetWorkChoicesOnNextOpen = false
            state.taskSelectionChanged = false
        }
        if state.isContinuingSuperFocusRun && !state.taskSelectionChanged {
            state.goal = whatToAchieveInFocusBlock
            state.hasChosenGoal = true
            if let data = focusModeTaskString.data(using: .utf8),
               let tasks = try? JSONDecoder().decode([ToDoTask].self, from: data) {
                state.selectedTasks = tasks.filter { !$0.isCompleted }
            }
        }
        state.hasChosenGoal = state.hasChosenGoal || hasUserTypedIntention || isIntentionFromMorningPostpone || !nextFocusSessionIntention.isEmpty
        updateWorkBreakRatio()
        getTaskPlayerVcObject().loadView()
        getTaskPlayerVcObject().loadRequest()
        reFillFocusTypeList(restoreLastUsedOnOpen: true)

        isFrictionLevelHigh = false

        if isShowingMorningHardcorePomodoro {
            applySuperFocusLock(isMorningAutoStart: true)
        } else if isHardCorePomodoroModeOn {
            applySuperFocusLock(isMorningAutoStart: false)
        } else {
            isSkipMicrobreaks = SettingsManagerObject.isSkipBreakActivityDuringPomodoro
            state.isMicroBreaksOn = !isSkipMicrobreaks
            state.superFocusProgress = nil
            state.isDurationEditable = true
            state.isStrictnessEditable = true
            state.isBlockListEditable = true
            state.isSuperFocusEditable = true
            state.isStartEnabled = true
            state.isSuperFocusOn = false
            startTimer()
            if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int {
                state.duration = FocusStartDuration(minutes: FocusStartDuration.clamp(duration),
                                                    isUntimed: state.duration.isUntimed)
            }
            updateBreakDuration()
        }

        isFocusModeStartedAutomatically = false
        if isShowingMorningHardcorePomodoro {
            isHardCorePomodoroModeOn = true
            self.view.window?.styleMask.remove(.closable)
            currentPomodoroWorkDuration = state.duration.effectiveMinutes
            currentPomodoroBreakDuration = state.breakDurationMinutes
            hardcodePmodoroFocusModeName = state.selectedBlockList?.name ?? ""
            totalPomodoroCountInHardCorePomodoro = state.superFocusSessionCount
            completedPomodoroCountInHardcorePomodoro = 0
            totalMinutesRemainingForHardcodePomodoro = state.superFocusSessionCount * currentPomodoroWorkDuration
            allApiObject.capturePosthog(event: "start-super-focus-session-automatically", metadata: [:])
            isFocusModeStartedAutomatically = true
            focusModeSelected()
            pomodoroModeStarted()
        } else if isHardCorePomodoroModeOn {
            focusModeSelected()
            isFocusModeStartedAutomatically = true
            pomodoroModeStarted()
            self.view.window?.styleMask.remove(.closable)
        } else {
            focusModeSelected()
            self.view.window?.styleMask.insert(.closable)
        }

        state.isAdvancedOptionsEnabled = UserDefaults.standard.object(forKey: kUserdefaultsIsAdvancedPomodoroEnabled) as? Bool ?? false
        updateFocusAlignmentScoreVisibility()

        if !nextFocusSessionIntention.isEmpty {
            state.goal = nextFocusSessionIntention
        }
        state.loadWorkChoices()
        DayPlanTaskStore.shared.loadAndHydrate(for: Date(), onChange: { [weak self] in
            guard let self = self, self.state.canChooseDayPlanDefault else { return }
            if let project = FocusStartWorkSelection.topDayPlanProject(self.state.projects,
                dayPlan: DayPlanTaskStore.shared.incompleteTasksInDisplayOrder(for: Date())) {
                self.state.selectProject(project, automatic: true)
            }
        })
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
        hasUserTypedIntention = false   // next open should auto-fill the block's last-used intention again
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
        // The postpone question replaces the headline only while that postpone is in play.
        if #available(macOS 11.0, *) { state.postponeTitle = nil }
        isViewVisible = false
    }

    // MARK: - Screen configuration

    /// Super Focus ("hardcore pomodoro") locks the duration, block list, strictness and micro-breaks
    /// for the whole run — the old screen did this by disabling half its controls.
    @available(macOS 11.0, *)
    private func applySuperFocusLock(isMorningAutoStart: Bool) {
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil {
            if SettingsManagerObject.isPasswordRequireInStopPomodoro {
                isFrictionLevelHigh = true
            }
        }
        state.unfocusedTimerText = ""
        state.isSuperFocusOn = true
        state.isSuperFocusEditable = false
        state.isDurationEditable = false
        state.isBlockListEditable = false
        state.isStrictnessEditable = false
        state.isStartEnabled = true

        if isMorningAutoStart {
            state.superFocusSessionCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedCount) as? Int ?? 2
            if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String,
               let index = state.blockLists.firstIndex(where: { $0.name == name }) {
                state.selectedBlockListIndex = index
            }
            isSkipMicrobreaks = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroSkipMicroBreaks) as? Bool ?? false
            state.isMicroBreaksOn = !isSkipMicrobreaks
            if let duration = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int {
                state.duration = FocusStartDuration(minutes: FocusStartDuration.clamp(duration))
            }
            updateBreakDuration()
            state.superFocusProgress = nil
        } else {
            if let index = state.blockLists.firstIndex(where: { $0.name == hardcodePmodoroFocusModeName }) {
                state.selectedBlockListIndex = index
            }
            let remaining = totalPomodoroCountInHardCorePomodoro - completedPomodoroCountInHardcorePomodoro
            var text = "You have completed <COMPLETED_POMODORO> of <TOTAL_POMODORO> pomodoros. <REMAINING_POMODORO> more to go."
            if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary,
               let title = pomodoroInfo.value(forKey: "completedPomodoroCountText") as? String {
                text = title
            }
            text = text.replacingOccurrences(of: "<COMPLETED_POMODORO>", with: "\(completedPomodoroCountInHardcorePomodoro)")
            text = text.replacingOccurrences(of: "<TOTAL_POMODORO>", with: "\(totalPomodoroCountInHardCorePomodoro)")
            text = text.replacingOccurrences(of: "<REMAINING_POMODORO>", with: "\(remaining)")
            state.superFocusProgress = text
        }
    }

    /// The focus-alignment-score row is only meaningful with advanced options on, cuddly mode on, AI
    /// URL checking on and a strictness below super strict — the same four conditions as before.
    @available(macOS 11.0, *)
    private func updateFocusAlignmentScoreVisibility() {
        state.isFocusAlignmentScoreVisible = state.isAdvancedOptionsEnabled
            && SettingsManagerObject.isCuddlyModeEnabled
            && SettingsManagerObject.isAiCheckUrlEnabled
            && state.strictness != .pawfessor
    }

    /// The "Distraction blocking inactive…" strip. Unchanged logic: never-asked shows the first tip,
    /// asked-but-no-browser-enabled shows the second, and everything else hides the strip.
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

    /// A running super-strict blocking schedule pins the block list to the schedule's own list and
    /// stops the user changing it.
    /// Any *other* running schedule only gets named — it blocks, but it is not a focus session and must
    /// not stop one being started (report 2026-09-16_15-13-57).
    @available(macOS 11.0, *)
    private func applySuperStrictBlockingScheduleLock() {
        state.activeBlockingScheduleText = nil
        guard let schedule = customBlockingScheduleManagerObj.runningSchedule else { return }
        state.activeBlockingScheduleText = state.strings.activeBlockingScheduleText(
            name: schedule.name, until: schedule.endTime.formattedTime())
        guard state.isBlockListEditable, currentFocusModeStrictness == ._SUPER_STRICT_,
              let index = state.blockLists.firstIndex(where: { $0.id == schedule.focusModeID }) else { return }
        state.selectedBlockListIndex = index
        state.isBlockListEditable = false
        state.blockingScheduleNotice = state.strings.superStrictScheduleBlocksList
    }

    // MARK: - Block list

    func reFillFocusTypeList(restoreLastUsedOnOpen: Bool = false, applyDefaults: Bool = true) {
        arrFocusTypeForPomodoro.removeAll()
        for focusMode in HiddenFocusModeManager.visibleFocusModes(from: arrFocusType) {
            if !(focusMode["isMeetings"] as? Bool ?? false == true) {
                arrFocusTypeForPomodoro.append(focusMode)
            }
        }
        guard #available(macOS 11.0, *) else { return }
        // On a fresh open, default to the block list the user picked for their last focus session from
        // this screen — otherwise it always reset to the first list.
        let restoredId = restoreLastUsedOnOpen
            ? UserDefaults.standard.string(forKey: kUserdefaultsLastPomodoroFocusModeId)
            : state.selectedBlockList?.id
        state.reloadBlockLists(selectedId: restoredId)
        // #2602: skip re-applying the block list's default duration on a plain refresh (e.g. returning
        // from the block-list editor), so the user's chosen duration survives.
        if applyDefaults { applySelectedBlockListDefaults() }
    }

    /// Called when the dropdown changes and whenever the list is rebuilt: seed the alignment score,
    /// warn about the no-AI default list, and pre-fill the goal and duration for this block list.
    func focusModeSelected() {
        guard #available(macOS 11.0, *) else { return }
        applySelectedBlockListDefaults()

        if state.selectedBlockList?.isDefault == true {
            var warningDefaultFocusMode = "Heads up: this will not use AI blocking. Focus Bear will only block the sites in your super distracting sites list"
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary,
               let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary {
                warningDefaultFocusMode = startingFocusModeInfo.value(forKey: "warningDefaultFocusMode") as? String ?? warningDefaultFocusMode
            }
            state.blockingScheduleNotice = warningDefaultFocusMode
        } else if state.isBlockListEditable {
            state.blockingScheduleNotice = nil
        }

        if isIntentionFromMorningPostpone { return }  // only show intention from postpone habit box // 17/5/24

        // Pre-fill the goal with this block list's last-used intention as a convenience — but only
        // while the user hasn't typed their own this session.
        if !hasUserTypedIntention && !state.hasChosenGoal && state.selectedProjectID == nil {
            state.goal = state.selectedBlockList?.lastIntentionUsed ?? ""
        }
        // #777: default the duration to this focus mode's last-used duration (fallback: last focus
        // mode's duration, then 20). Only when the duration is user-editable — Super Focus locks it.
        if state.isDurationEditable {
            state.duration = FocusStartDuration(minutes: state.defaultDurationMinutes(forBlockListAt: state.selectedBlockListIndex),
                                                isUntimed: state.duration.isUntimed)
            updateBreakDuration()
        }
    }

    @available(macOS 11.0, *)
    private func applySelectedBlockListDefaults() {
        state.focusAlignmentScore = state.selectedBlockList?.focusAlignmentScoreThreshold
            ?? defaultFocusAlignmentScoreToShowDistractingPopUp
    }

    /// Selects a block list by id and pins the session to `duration` seconds. Called from the menu-bar
    /// overlay and the focus-mode suggestion flows.
    func selectFocusModeWithId(id: String, duration: Int) {
        guard #available(macOS 11.0, *) else { return }
        guard let index = state.blockLists.firstIndex(where: { $0.id == id }) else {
            showAlert(msg: "Focus mode not found.")
            return
        }
        state.selectedBlockListIndex = index
        state.duration = FocusStartDuration(minutes: FocusStartDuration.clamp(duration / 60),
                                            isUntimed: state.duration.isUntimed)
        updateBreakDuration()
    }

    func updateBreakDuration() {
        guard #available(macOS 11.0, *) else { return }
        state.recomputeBreakDuration(workRatio: workRatio, breakRatio: breakRatio)
        isBreakDurationComesFromBreakRatio = true
    }

    func updateWorkBreakRatio() {
        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro) as? Int {
            workRatio = ratio
            if workRatio <= 0 {
                workRatio = 1
                UserDefaults.standard.set(workRatio, forKey: SettingsManagerObject.kUserdefaultsWorkRatioInPomodoro)
            }
        }
        if let ratio = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro) as? Int {
            breakRatio = ratio
            if breakRatio <= 0 {
                breakRatio = 1
                UserDefaults.standard.set(breakRatio, forKey: SettingsManagerObject.kUserdefaultsBreakRatioInPomodoro)
            }
        }
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

    func editBlockListsTapped(focusModeId: String? = nil) {
        guard #available(macOS 11.0, *) else { return }
        addLog(text: "[user-action] btnEditFocusModeClicked — open block lists as sheet")
        // #2602: open the Block Lists editor as a SHEET (same as the blocking-schedule "edit block list"
        // flow) with the tapped row's block list selected — replacing the old full-view navigation that
        // always showed the default block list. The pencil passes its row's id; the "Edit block lists"
        // link (no id) falls back to the currently selected block list.
        if focusPreferencesVcObj == nil { getFocusPreferencesVcObject().loadView() }
        getFocusPreferencesVcObject().btnBackToCustomBlocking.isHidden = false   // sheet back arrow dismisses (see #2593)
        getFocusPreferencesVcObject().btnBack.isHidden = true
        presentAsSheet(getFocusPreferencesVcObject())
        if let focusModeId = focusModeId ?? state.selectedBlockList?.id {
            getFocusPreferencesVcObject().selectFocusModeWithId(id: focusModeId)
        }
    }

    /// The "Fix it" button on the permissions strip. Unchanged: when permissions have never been
    /// asked for it re-runs the same block/no-thanks alert (without starting a session); otherwise it
    /// opens the explaining-permissions window and stashes the typed goal to restore afterwards.
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

    /// Follows the "‹ Go back / Regular Options" link. The flag is switched through
    /// `switchAppMode(toGeekMode:)` so all 75 read/write sites of isGeekModeEnabled stay in step.
    func switchToSimpleModeTapped() {
        addLog(text: "[user-action] focus start flow → regular options")
        switchAppMode(toGeekMode: FocusStartMode.advanced.geekModeAfterFollowingLink)
        appdelegate?.menuShowSimplePomodoroModeView()
    }

    // MARK: - Starting a session

    /// Was `btnLetsDoItClicked`. Every gate below is the original code with the outlet reads swapped
    /// for `state`.
    func startTapped() {
        guard #available(macOS 11.0, *) else { return }
        addLog(text: "[user-action] btnLetsDoItClicked")
        if state.isDurationEditable && state.duration.effectiveMinutes < FocusStartDuration.minimumMinutes {
            showAlert(msg: workDurationZeroErrorText)
            return
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil {
            guard let window = self.view.window else { return }
            presentBrowserPermissionsAlert(in: window, onProceedAnyway: { [weak self] in self?.startTapped() })
            // Written immediately, before the sheet is answered, so the "No thanks" branch's recursive
            // call falls straight through this gate instead of looping.
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
            return
        }

        // Remember the block list the user is starting this session with so the dropdown defaults to it
        // next time (see reFillFocusTypeList). Saved on the common path so it applies to BOTH Super
        // Focus and single sessions.
        if let focusModeId = state.selectedBlockList?.id {
            UserDefaults.standard.set(focusModeId, forKey: kUserdefaultsLastPomodoroFocusModeId)
        }

        if isHardCorePomodoroModeOn {
            // Re-shown between two Super Focus sessions: nothing starts here, the run is already armed.
            continueRunningSuperFocusSession()
            return
        }

        currentPomodoroWorkDuration = state.duration.effectiveMinutes
        currentPomodoroBreakDuration = state.breakDurationMinutes

        if state.isSuperFocusOn {
            isHardCorePomodoroModeOn = true
            hardcodePmodoroFocusModeName = state.selectedBlockList?.name ?? ""
            totalPomodoroCountInHardCorePomodoro = state.superFocusSessionCount
            completedPomodoroCountInHardcorePomodoro = 0
            totalMinutesRemainingForHardcodePomodoro = state.superFocusSessionCount * state.duration.effectiveMinutes
        }

        let totalMinutes = state.duration.effectiveMinutes
        if currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_ {
            if presentPostponeExtensionAlertIfNeeded(totalMinutes: totalMinutes) { return }
        }
        checkStateAndStartPomodoroMode()
    }

    /// The browser-permissions sheet. `onProceedAnyway` is the recursive retry the Start path needs on
    /// "No thanks"; the "Fix it" button passes nil so declining just dismisses.
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

    /// The Start button while a Super Focus run is already going: no new session, just re-point the
    /// status bar and the Todo Player at the goal the user typed, then close.
    @available(macOS 11.0, *)
    private func continueRunningSuperFocusSession() {
        whatToAchieveInFocusBlock = state.goal
        focusModeTaskString = state.taskQueueForSessionStart
        state.shouldResetWorkChoicesOnNextOpen = true
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
        let minute = state.duration.effectiveMinutes
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled {
            showRunningFocusSessionWindow()
        } else {
            if !getTaskPlayerVcObject().isViewLoaded {
                getTaskPlayerVcObject().loadView()
            }
            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: state.goal)
            shouldReloadTaskPlayer = false
        }
        if let focusModeId = state.selectedBlockList?.id {
            for i in 0..<arrFocusType.count where arrFocusType[i]["id"] as? String ?? "" == focusModeId {
                arrFocusType[i]["lastTaskUsed"] = focusModeTaskString
                updateFocusModeTask(taskString: focusModeTaskString)
                arrFocusType[i]["lastIntentionUsed"] = state.goal.isEmpty ? "" : state.goal
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                updateAllFocusModes()
                break
            }
        }
        self.view.window?.close()
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
    }

    /// The habit-postpone extension flow: when the focus session outlives the postpone, offer to
    /// stretch the postpone to match. Returns true when it took over (an alert is up).
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
                self.extendPostponeThenStart(totalMinutes: totalMinutes)
            } else if modalResponse == .alertSecondButtonReturn {
                self.checkStateAndStartPomodoroMode()
            }
        })
        return true
    }

    /// The password matrix behind extending a postpone: morning postpones honour
    /// `isPasswordRequireInPostponeMorning`, evening/focus-summary ones honour
    /// `isPasswordRequireInPostponeEveningAfterCutOff` during a cut-off and
    /// `isPasswordRequireInPostponeEvening` otherwise — all bypassed by easy-skip mode.
    private func extendPostponeThenStart(totalMinutes: Int) {
        if currentState == ._POSTPONE_MORNING_HABIT_ {
            if SettingsManagerObject.isEasySkipEnabled {
                getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                checkStateAndStartPomodoroMode()
                return
            }
            if SettingsManagerObject.isPasswordRequireInPostponeMorning && shouldAskPassword(forPostpone: true) {
                presentPasswordSheet(isShowingForRelaxFocusMode: false)
                return
            }
            getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
            checkStateAndStartPomodoroMode()
            return
        }

        guard currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_ else { return }
        var shouldAskPasswordForEvening = false
        if shouldAskPassword(forPostpone: true) && !SettingsManagerObject.isEasySkipEnabled {
            if isCutOffTimeGoing() {
                shouldAskPasswordForEvening = SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff
            } else {
                shouldAskPasswordForEvening = SettingsManagerObject.isPasswordRequireInPostponeEvening
            }
        }
        if shouldAskPasswordForEvening {
            presentPasswordSheet(isShowingForRelaxFocusMode: false)
            return
        }
        if currentState == ._POSTPONE_EVENING_HABIT_ {
            getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
        } else if currentState == ._POSTPONE_FOCUS_SUMMARY_ {
            getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
        }
        checkStateAndStartPomodoroMode()
    }

    private func presentPasswordSheet(isShowingForRelaxFocusMode: Bool) {
        guard let passwordVc = enterPasswordVcObj else { return }
        presentAsSheet(passwordVc)
        passwordVc.parentVc = self
        passwordVc.isShowingForRelaxFocusMode = isShowingForRelaxFocusMode
    }

    func checkStateAndStartPomodoroMode() {
        guard #available(macOS 11.0, *) else { return }
        nextFocusSessionIntention = ""
        let isRelaxFocus = state.selectedBlockList?.isRelaxFocus ?? false
        if isRelaxFocus && shouldAskPassword() && SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode && self.view.window != nil {
            presentPasswordSheet(isShowingForRelaxFocusMode: true)
            return
        }
        pomodoroModeStarted()
        if currentState != ._MICRO_BREAK_ {
            // won't work if the view has changed (the task player is visible now), because the window
            // is nil once the main view swaps — v 2.28.438
            self.view.window?.close()
        } else {
            leftMenuVcObj?.showBreaksView()
        }
        allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
    }

    func pomodoroModeStarted() {
        guard #available(macOS 11.0, *) else { return }
        addLog(text: "pomodoro mode Started")
        if arrFocusTypeForPomodoro.count == 0 {
            return
        }
        switch state.strictness {
        case .junior:
            addLog(text: "focus mode is normal mode")
            currentFocusModeStrictness = ._NORMAL_
        case .captain:
            addLog(text: "focus mode is strict mode")
            currentFocusModeStrictness = ._STRICT_
        case .pawfessor:
            addLog(text: "focus mode is super strict mode")
            currentFocusModeStrictness = ._SUPER_STRICT_
        }

        UserDefaults.standard.set(state.strictness.storedValue, forKey: kUserdefaultsLastFocusModeStrictness)

        // App should remember the last focus session + break duration. If you change it to 40 minutes,
        // it should remember that for next time. 29/7/25 v 1.26.395
        let count = state.duration.effectiveMinutes
        if let oldCount = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes) as? Int {
            if count != oldCount {
                SettingsManagerObject.isSettingsChanged = true
                UserDefaults.standard.set(count, forKey: SettingsManagerObject.kUserdefaultsPomodoroDurationMinutes)
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

        if let focusModeId = state.selectedBlockList?.id {
            for i in 0..<arrFocusType.count where arrFocusType[i]["id"] as? String ?? "" == focusModeId {
                arrFocusType[i]["isOn"] = true
                arrFocusType[i]["lastStartedDate"] = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                arrFocusType[i]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
                shouldReloadTaskPlayer = true
                let focusModeName = arrFocusType[i]["name"] as? String ?? ""
                addLog(text: "Focus mode name is:- \(focusModeName)")// added v 3.31.474
                addLog(text: "Focus mode id is:- \(focusModeId)")// added v 3.31.474

                applyAutoDoNotDisturb(forFocusModeAt: i, includingDeepWorkAndDefault: true)

                workBeforeFocusBegin(index: i)

                let oldFocusAlignmentScoreThreshold = arrFocusType[i]["focusAlignmentScoreThreshold"] as? Int ?? -1
                let focusAlignmentScoreThreshold = state.focusAlignmentScore
                if oldFocusAlignmentScoreThreshold != focusAlignmentScoreThreshold {
                    arrFocusType[i]["focusAlignmentScoreThreshold"] = focusAlignmentScoreThreshold
                    allApiObject.capturePosthog(event: "focus-alignment-score-threshold-changed", metadata: [:])
                }
                // Use this screen's selected to-dos, with their original IDs, rather than silently
                // restoring an unrelated queue from the previous session using this block list.
                focusModeTaskString = state.taskQueueForSessionStart
                arrFocusType[i]["lastTaskUsed"] = focusModeTaskString
                arrFocusType[i]["lastIntentionUsed"] = state.goal.isEmpty ? "" : state.goal

                // #777: remember the chosen duration for this focus mode so it defaults to its own
                // last duration next time (persisted + synced with the intention below). Also bump the
                // global last-duration so a brand-new focus mode inherits it via the fallback.
                arrFocusType[i]["lastDurationUsed"] = minute
                UserDefaults.standard.set(minute, forKey: kUserdefaultsLastFocusModeMinutes)

                taskCreatedByBlockPopup = ""
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                updateAllFocusModes()
                break
            }
        }
        minFocusAlignmentScoreToShowDistractingPopUp = Double(state.focusAlignmentScore)
        if SettingsManagerObject.isDataCollectionModeEnabled {
            minFocusAlignmentScoreToShowDistractingPopUp = 0
        }
        isFocusModeRunning = true
        state.shouldResetWorkChoicesOnNextOpen = true
        appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString: selectedBlockListColorString())
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
        isSkipMicrobreaks = !state.isMicroBreaksOn
        if isSkipMicrobreaks {
            isSkipBreakActivityDuringPomodoro = true
            addLog(text: "checkBoxSkipMicrobreaks is on in geek mode focus session.")
        } else {
            isSkipBreakActivityDuringPomodoro = false
            addLog(text: "checkBoxSkipMicrobreaks is off in geek mode focus session.")
        }
        if SettingsManagerObject.isSkipBreakActivityDuringPomodoro != isSkipBreakActivityDuringPomodoro {
            SettingsManagerObject.isSkipBreakActivityDuringPomodoro = isSkipBreakActivityDuringPomodoro
            SettingsManagerObject.isSettingsChanged = true
        }

        if state.isMicroBreaksOn {
            if !SettingsManagerObject.isMicroBreaksEnabled {
                SettingsManagerObject.isMicroBreaksEnabled = true
                SettingsManagerObject.isSettingsChanged = true
            }
            if breakAfterMinutes != state.breakFrequencyMinutes {
                BreakFrequencyStreakTracker.shared.saveNewBreakFrequency(state.breakFrequencyMinutes)
                // Preserve an already-due break; recompute only the cadence and any too-distant due time.
                getHabitsVcObject().stopActivityTimer()
                getHabitsVcObject().setActivityTimer()
            }
        }

        // A focus session started FROM a postpone should honour the user's "show breaks while
        // postponed" preference rather than silently suppress breaks for the whole block. Applied to
        // the runtime flag only (AFTER the persist-sync above) so the user's saved skip-breaks-during-
        // focus preference is left untouched.
        if isIntentionFromMorningPostpone && SettingsManagerObject.IsShowBreaksInPostponeEnabled {
            isSkipBreakActivityDuringPomodoro = false
            addLog(text: "Focus session started from postpone with 'show breaks in postpone' on — keeping breaks enabled.")
        }

        SettingsManagerObject.putUserLocalDeviceSettings()

        whatToAchieveInFocusBlock = state.goal
        appdelegate!.focusModeStartted(isStartedByPusher: false)
        // #2571 (5): mark THIS session as the one started from the postpone flow, so stopping it
        // resumes the postponed routine — but a *different* session started later (e.g. after leaving
        // and returning to the Start Focus screen, with a new intention) does NOT resume it just
        // because the routine still happens to be postponed. `isIntentionFromMorningPostpone` is set
        // only by the postpone→intention flow and cleared on viewWillDisappear; `focusModeStartted`
        // above just reset the session flag, so stamp it here after.
        if isIntentionFromMorningPostpone {
            isFocusSessionStartedFromPostponeIntention = true
        }
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled && currentState != ._MICRO_BREAK_ { // added is micro break is running :- v 2.28.438
            if isHardCorePomodoroModeOn {
                // Done because when isHardCorePomodoroModeOn is enabled, showTaskPlayerWindow prevents
                // viewDidAppear from being called properly. v 2.28.440
                let goal = state.goal
                DispatchQueue.global().async {
                    sleep(1)
                    DispatchQueue.main.async {
                        showRunningFocusSessionWindow()
                    }
                }
            } else {
                showRunningFocusSessionWindow()
            }
        } else {
            if !getTaskPlayerVcObject().isViewLoaded {
                getTaskPlayerVcObject().loadView()
            }
            taskPlayerVcObj?.reloadData(totalDuration: minute, intention: state.goal)
            shouldReloadTaskPlayer = false
        }

        if isShowingPomodoroManually {
            let type = isHardCorePomodoroModeOn ? "super-focus" : "single-focus"
            allApiObject.capturePosthog(event: "start-focus-session-manually", metadata: ["type": type, "focusDuration": currentPomodoroWorkDuration, "breakDuration": currentPomodoroBreakDuration])
        }
    }

    @available(macOS 11.0, *)
    private func selectedBlockListColorString() -> String {
        guard let id = state.selectedBlockList?.id else { return "" }
        for focusMode in arrFocusTypeForPomodoro where focusMode["id"] as? String == id {
            return focusMode["color"] as? String ?? ""
        }
        return ""
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

/// "01:23:45" from a second count — shared by both start screens' unfocused-time counters.
func formattedUnfocusedTime(_ seconds: Int) -> String {
    let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
    return String(format: "%02d:%02d:%02d", h, m, s)
}

/// The lapsed-trial nag shown when someone tries to switch AI blocking on. Shared by both start
/// screens so the wording and the PostHog `reason` stay identical.
func showUpgradeToProNagForAiBlocking() {
    var titleNoAiBlocking = "AI blocking is only supported in Pro edition."
    if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary {
        titleNoAiBlocking = upgradeToProNagVcInfo.value(forKey: "titleNoAiBlocking") as? String ?? titleNoAiBlocking
    }
    showUpgradeToProNagWindow(titleText: titleNoAiBlocking, reason: "activate_ai_blocking_focus_session")
}
