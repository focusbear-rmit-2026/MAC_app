//
//  firstViewController+Schedule.swift
//  Focus Bear
//
//  Adds the "Schedule | Habits" tab to the normal habit-list screen and makes it a
//  ScheduleHost so the Schedule cards drive its existing Start/Done/Skip logic. Done as
//  an extension (with associated objects for the added views) so the storyboard and the
//  3.6k-line firstViewController stay untouched apart from one setup call in viewDidLoad.
//

import Cocoa

private var fvcScheduleVCKey: UInt8 = 0
private var fvcTitleHeightKey: UInt8 = 0

extension firstViewController: ScheduleHost {

    private var scheduleVC: scheduleViewController? {
        get { objc_getAssociatedObject(self, &fvcScheduleVCKey) as? scheduleViewController }
        set { objc_setAssociatedObject(self, &fvcScheduleVCKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Height-0 constraint that collapses lblTitle while the Day Plan fronts the habit list. Kept so
    /// it can be deactivated during a micro break, where lblTitle is the list's header (the
    /// "It's time to micro break…" title that was reported missing).
    private var dayPlanTitleHeight: NSLayoutConstraint? {
        get { objc_getAssociatedObject(self, &fvcTitleHeightKey) as? NSLayoutConstraint }
        set { objc_setAssociatedObject(self, &fvcTitleHeightKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Installs the Day Plan container (shown by default). Idempotent.
    func setupScheduleTab() {
        guard scheduleVC == nil else { return }
        // Seed completed-habit ids from the persisted cache so the first render hides already-done
        // habits even before current-activity-props returns (the old habit UI's source of truth).
        loadPersistedDayPlanCompletedIds()
        let sched = ScheduleTab.install(in: self)
        sched.host = self
        scheduleVC = sched
        // Collapse the routine greeting + "select the habit…" line so they don't overlap the Day Plan.
        // lblSelectHabits stays collapsed always; lblTitle is restored during a micro break (its
        // header), so keep a handle to its height constraint to toggle in updateScheduleTabForState.
        if let l = lblSelectHabits {
            l.isHidden = true
            l.stringValue = ""
            let h = l.heightAnchor.constraint(equalToConstant: 0); h.priority = .required; h.isActive = true
        }
        if let l = lblTitle {
            l.isHidden = true
            l.stringValue = ""
            let h = l.heightAnchor.constraint(equalToConstant: 0); h.priority = .required; h.isActive = true
            dayPlanTitleHeight = h
        }
        updateScheduleTabForState()            // sync visibility with the current state
    }

    func refreshScheduleIfVisible() {
        if scheduleVC?.view.isHidden == false { scheduleVC?.reload() }
    }

    /// Whether the Day Plan (not the Habits view) is currently showing.
    var isScheduleTabSelected: Bool { scheduleVC?.view.isHidden == false }

    /// Show the Day Plan and refresh it (used to keep the user on it after a remote completion
    /// re-syncs the routine instead of yanking them into the next habit).
    func selectScheduleTab() {
        scheduleVC?.view.isHidden = false
        setHabitListHiddenForDayPlan(true)
        scheduleVC?.startAutoRefresh()
    }

    /// Hide the habit list while the Day Plan covers it. A visible-but-occluded NSTableView still
    /// installs its cells' `activeAlways` tracking areas (which is why a hand cursor appeared over
    /// "blank" Day Plan areas) and stays hit-testable (so clicks fell through and started the
    /// selected habit). Hidden views neither track nor hit-test; the Day Plan still drives the
    /// table programmatically (reloadData/selectRowIndexes work while hidden).
    private func setHabitListHiddenForDayPlan(_ hidden: Bool) {
        // The legacy habit-selection controls behind the Day Plan (custom Button / cursorButton /
        // underLineButton classes) keep firing their activeAlways tracking areas (hand cursor) and
        // stay hit-testable (stray clicks — e.g. starting the selected habit), so suppress them while
        // the Day Plan fronts the list. The Day Plan's own buttons and the programmatic start (the
        // action is called directly) are unaffected.
        //
        // SHARED controls (Start button + habit table) are reused by the micro-break UI, so toggle
        // them symmetrically — they must be restored (un-hidden) when the Day Plan isn't fronting
        // the list, otherwise the break's Start button / activity list stay hidden.
        scrollViewHabits?.isHidden = hidden
        tblViewHabits?.isHidden = hidden
        btnStartFirstHabit?.isHidden = hidden
        // Habit-select-only controls — hide-only. The legacy state code (viewWillAppear) keeps these
        // hidden in break states anyway, so there's nothing to restore.
        if hidden {
            btnEditHabits?.isHidden = true
            btnSelectHabitsToDo?.isHidden = true
            btnInfo?.isHidden = true
            boxSegmentControlOfficeMode?.isHidden = true
        }
    }

    /// The Day Plan is shown for routine planning, but break activities (micro breaks / breathing)
    /// aren't part of planning — hide it then so the Habits view underneath shows instead.
    func updateScheduleTabForState() {
        guard let sched = scheduleVC else { return }
        let isBreak = currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_
        sched.view.isHidden = isBreak
        // Restore lblTitle as the micro-break list's header (the "It's time to micro break…" title);
        // it's collapsed in every other state because the Day Plan covers it.
        let showMicroBreakTitle = currentState == ._MICRO_BREAK_
        lblTitle?.isHidden = !showMicroBreakTitle
        dayPlanTitleHeight?.isActive = !showMicroBreakTitle
        // Hide the host habit list only when the Day Plan is actually COVERING it — i.e. visible
        // (not a break) AND showing its own content. In the custom-routine "Custom routine" tab the
        // Day Plan content is hidden to reveal this list, so it must stay visible (otherwise both are
        // hidden = blank screen). Onboarding reuses this screen with its own controls — leave them.
        let dayPlanCovering = !isBreak && !sched.isDayPlanContentHidden
        if currentState != ._ONBOARDING_ { setHabitListHiddenForDayPlan(dayPlanCovering) }
        // Drop any stale manual habit pick so the highlight follows the in-progress habit (now at the
        // top of the reordered list) when we return to the Day Plan after starting/pausing a habit.
        sched.clearSelectedHabit()
        if isBreak { sched.stopAutoRefresh() } else { sched.startAutoRefresh() }
        // Sync the player's time-of-day clock with what's actually on screen. (Don't use
        // setDateTimeClockHidden(!isBreak) — that hid the clock on the state change into a *playing*
        // habit, e.g. starting from the Postponed list, since this state isn't a break.)
        habitsVcObj?.refreshDateTimeClockVisibility()
    }

    /// Lightweight list-visibility re-sync (no reload/auto-refresh) — safe to call from within the
    /// Day Plan's reload, unlike updateScheduleTabForState().
    func refreshHabitListVisibilityForDayPlan() {
        guard let sched = scheduleVC else { return }
        let isBreak = currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_
        let dayPlanCovering = !isBreak && !sched.isDayPlanContentHidden
        if currentState != ._ONBOARDING_ { setHabitListHiddenForDayPlan(dayPlanCovering) }
    }

    // MARK: - ScheduleHost

    /// The habit array currently backing the Day Plan, matching the on-screen routine state. Shared by
    /// scheduleSegments (render) and scheduleStart (so the tapped index maps to the same habit).
    private var scheduleSourceHabits: [habit] {
        switch currentState {
        case ._EVENING_HABIT_, ._POSTPONE_EVENING_HABIT_:
            return arrFilteredEveningHabits
        case ._CUSTOM_ROUTINE_:
            let valid = currentRoutineIndex < arrAllCustomRoutine.count
            return valid ? arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits : []
        default:
            return arrFilteredMorningHabits
        }
    }

    func scheduleSegments(now: Date) -> [ScheduleRoutineSegment] {
        let source = scheduleSourceHabits
        let name: String
        let isMorning: Bool
        switch currentState {
        case ._EVENING_HABIT_, ._POSTPONE_EVENING_HABIT_:
            name = ScheduleText.eveningRoutineHabits; isMorning = false
        case ._CUSTOM_ROUTINE_:
            let valid = currentRoutineIndex < arrAllCustomRoutine.count
            name = valid ? "\(arrAllCustomRoutine[currentRoutineIndex].title) \(ScheduleText.habitsSuffix)" : ScheduleText.morningRoutineHabits
            isMorning = false
        default:
            name = ScheduleText.morningRoutineHabits; isMorning = true
        }
        return ScheduleTab.standardSegments(activeName: name,
                                            activeHabits: ScheduleTab.habitInputs(from: source, now: now),
                                            isMorningActive: isMorning, now: now)
    }

    /// Whether `index` is still a live habit in the routine the Day Plan rendered. The Day Plan can
    /// hand back a stale index (e.g. the habit list shrank from a skip/refresh between render and
    /// tap); acting on it would index past the habit array and crash (sortMorningHabitsBySelectedFirst
    /// etc.), so callers re-sync the Day Plan instead of starting/finishing the wrong habit.
    ///
    /// The **live routine array** is the authority, not `tblViewHabits.numberOfRows`. The Day Plan
    /// renders from `scheduleSourceHabits`, so an index it hands back is valid exactly when that array
    /// still holds it. Asking the table instead made every Day Plan action depend on this screen's
    /// (hidden, sometimes never-loaded) habit table: with the Habit Player fronting the routine,
    /// `tblViewHabits` can be nil and the guard then swallowed every Play/Done/Skip tap silently.
    /// `reloadData()` still runs so the table's cached row count can't hand `viewFor:row:` an index
    /// past the array (the crash this guard was added for).
    private func isLiveScheduleIndex(_ index: Int) -> Bool {
        tblViewHabits?.reloadData()
        return scheduleSourceHabits.indices.contains(index)
    }

    /// A habit is playing (or paused) in the Habit Player — i.e. the routine is mid-flight rather than
    /// waiting to be started.
    private var isRoutineUnderway: Bool {
        currentAction == ._INPROGRESS_ && currentHabitPlaying != nil
    }

    func scheduleStart(index: Int) {
        // A class session is in control — don't let the student start a habit from the Day Plan
        // (routines are postponed during the session and resume after it ends).
        if teacherSessionManagerObject.isTeacherSessionActive(){
            teacherSessionManagerObject.showTeacherSessionLockedAlert()
            return
        }
        guard isLiveScheduleIndex(index) else { refreshScheduleIfVisible(); return }
        let source = scheduleSourceHabits
        let target = source[index]
        // Tapping Play on the habit that's ALREADY in the player: resume it if it's paused (keeping
        // its elapsed time — never restart from zero), otherwise just switch back to its tab.
        if let playing = currentHabitPlaying, let pid = playing.id, target.id == pid {
            timerViewcontrollerObj?.showAllowedActivityPlayerTab()
            if timerViewcontrollerObj?.isActivityPaused == true {
                timerViewcontrollerObj?.btnPauseClicked(self)   // toggles: paused → resumed
            }
            return
        }
        // A routine is already underway and the user tapped Play on a DIFFERENT habit: that means
        // "switch to this one now", which is exactly what the player's own "Select another habit"
        // menu does (startAnotherHabitVc.btnStartClicked) — so route it there rather than through
        // btnStartFirstHabitClicked, which is the START-THE-ROUTINE path (it re-sorts the list, runs
        // the visualise-instructions flow, and with the high-priority sequence on ignores the tapped
        // habit entirely). Nothing is marked done or skipped, so no skip-password gate is bypassed.
        if isRoutineUnderway {
            startHabitMidRoutine(target)
            return
        }
        // Routine not started yet: the habit list is on screen, so drive its Start button as before.
        // btnStartFirstHabitClicked reads tblViewHabits.selectedRow unconditionally, so it needs a
        // real table.
        guard let tbl = tblViewHabits, index < tbl.numberOfRows else {
            addLog(text: "dayplan: scheduleStart(\(index)) skipped — habit table unavailable")
            refreshScheduleIfVisible()
            return
        }
        tbl.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        btnStartFirstHabitClicked(self)
    }

    /// Switch the live routine to `target` mid-flight, mirroring startAnotherHabitVc.btnStartClicked:
    /// move it to the current position in the routine array — so the habit that was playing/paused
    /// keeps its place directly behind it and comes up again afterwards, rather than being abandoned
    /// or completed — then start it in the player.
    private func startHabitMidRoutine(_ target: habit) {
        addLog(text: "[user-action] dayplan: start habit mid-routine \(target.name ?? "")")
        moveRoutineHabitToCurrentPosition(id: target.id)
        timerViewcontrollerObj?.showAllowedActivityPlayerTab()
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: target.durationSeconds,
                                                   name: target.name ?? "",
                                                   currentHabit: target,
                                                   currentTimerValue: 0)
        DispatchQueue.main.async { [weak self] in self?.refreshScheduleIfVisible() }
    }

    /// Re-orders the live routine array so the habit with `id` sits at the currently-playing position
    /// (`currentHabitIndex`), pushing the habit that was playing one place back. Same move the
    /// "Select another habit" sheet makes, but it also handles a habit that sits *before* the current
    /// one (the Day Plan can offer any habit in the routine, that sheet only later ones).
    private func moveRoutineHabitToCurrentPosition(id: String?) {
        guard let id = id else { return }
        let anchor = max(currentHabitIndex, 0)
        func reordered(_ habits: [habit]) -> [habit]? {
            guard let from = habits.firstIndex(where: { $0.id == id }) else { return nil }
            return RoutineReorder.moving(habits, at: from, toAnchor: anchor)
        }
        switch currentState {
        case ._EVENING_HABIT_, ._POSTPONE_EVENING_HABIT_:
            if let r = reordered(arrFilteredEveningHabits) { arrFilteredEveningHabits = r }
        case ._CUSTOM_ROUTINE_:
            guard currentRoutineIndex < arrAllCustomRoutine.count else { return }
            if let r = reordered(arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits) {
                arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits = r
            }
        default:
            if let r = reordered(arrFilteredMorningHabits) { arrFilteredMorningHabits = r }
        }
    }

    func scheduleDone(index: Int) {
        guard isLiveScheduleIndex(index) else { refreshScheduleIfVisible(); return }
        let proxy = NSButton(); proxy.tag = index
        btnDoneClicked(sender: proxy)
        // Reflect the completion straight away rather than waiting for the next refresh tick.
        DispatchQueue.main.async { [weak self] in self?.refreshScheduleIfVisible() }
    }

    func scheduleSkip(index: Int) {
        guard isLiveScheduleIndex(index) else { refreshScheduleIfVisible(); return }
        let proxy = NSButton(); proxy.tag = index
        btnSkipClicked(sender: proxy)
        DispatchQueue.main.async { [weak self] in self?.refreshScheduleIfVisible() }
    }

    // A past morning habit (today's "earlier today" accordion or a previous calendar day) completes BY
    // ID — never through the index-based btnDoneClicked path above, which targets the live routine (it
    // would complete the wrong habit while the evening routine runs). `performedAt` is that habit's slot
    // on the viewed day, sent as the backdated completion time. See completePastHabit.
    func schedulePastHabitDone(id: String, performedAt: Date) { completePastHabit(id: id, performedAt: performedAt) }

    /// Opens the same "choose which habits to do today" sheet as the Habits view's
    /// "I don't have time for all these habits" button.
    func scheduleSkipRoutineForToday() {
        // A routine is in progress here (firstViewController is the active-routine host), so skipping
        // from the Day Plan should CLOSE the window, like an in-routine skip. Leave openedFromDayPlan
        // at its default false (set in showChooseHabitsView) so chooseHabitsVC runs its window.close().
        // The postponed host (routinePostponedInfoVc) instead keeps the window open and reloads the plan.
        showChooseHabitsView()
    }

    // In-routine cancel closes the window (mirrors scheduleSkipRoutineForToday above): the Day Plan ✕
    // confirmation calls cancelRoutineForToday(openedFromDayPlan: false) for the active-routine host.
    var cancelRoutineKeepsWindowOpen: Bool { false }
}
