//
//  routinePostponedInfoVc+Schedule.swift
//  Focus Bear
//
//  Same "Schedule | Habits" tab as firstViewController+Schedule, but for the postponed
//  habit-list screen (shown when a routine has been postponed). Bridges the Schedule
//  cards to this screen's own Play/Done/Skip logic.
//

import Cocoa

private var rpScheduleVCKey: UInt8 = 0

extension routinePostponedInfoVc: ScheduleHost {

    private var scheduleVC: scheduleViewController? {
        get { objc_getAssociatedObject(self, &rpScheduleVCKey) as? scheduleViewController }
        set { objc_setAssociatedObject(self, &rpScheduleVCKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setupScheduleTab() {
        guard scheduleVC == nil else { return }
        let sched = ScheduleTab.install(in: self)
        sched.host = self
        scheduleVC = sched
        // Drop the "Morning/Evening routine postponed…" banner — redundant in the new UI —
        // and collapse its reserved height so the habit list moves up.
        if let title = lblTitle {
            title.isHidden = true
            title.stringValue = ""
            title.setContentHuggingPriority(.required, for: .vertical)
            let h = title.heightAnchor.constraint(equalToConstant: 0)
            h.priority = .required
            h.isActive = true
        }
        updateScheduleTabForState()
    }

    func refreshScheduleIfVisible() {
        if scheduleVC?.view.isHidden == false { scheduleVC?.reload() }
    }

    var isScheduleTabSelected: Bool { scheduleVC?.view.isHidden == false }

    func selectScheduleTab() {
        scheduleVC?.view.isHidden = false
        setHabitListHiddenForDayPlan(true)
        scheduleVC?.startAutoRefresh()
    }

    /// Hide the habit list while the Day Plan covers it. A visible-but-occluded NSTableView still
    /// installs its cells' `activeAlways` tracking areas (hand cursor over "blank" Day Plan areas)
    /// and stays hit-testable (clicks fell through and started the selected habit). Hidden views
    /// neither track nor hit-test; the Day Plan still drives the table programmatically.
    private func setHabitListHiddenForDayPlan(_ hidden: Bool) {
        tblViewHabits?.isHidden = hidden
        tblViewHabits?.enclosingScrollView?.isHidden = hidden
        // The legacy "Start <habit>" button sits behind the Day Plan but its custom `Button` class
        // installs an activeAlways tracking area (hand cursor) and stays hit-testable — clicks on
        // it run playSelectedHabit() and start the selected habit. Hide it while the Day Plan is
        // front (verified via breakpoint: btnStartFirstHabitClicked fired on "blank" clicks).
        btnStartFirstHabit?.isHidden = hidden
    }

    /// Hide the Day Plan during break activities (micro break / breathing) so the Habits view
    /// underneath shows instead; restore it afterwards.
    func updateScheduleTabForState() {
        guard let sched = scheduleVC else { return }
        let isBreak = currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_
        sched.view.isHidden = isBreak
        // Hide the list beneath the Day Plan in habit states; restore it during a micro break (the
        // Start button + table are reused by the break UI, so they must come back — pass false).
        setHabitListHiddenForDayPlan(!isBreak)
        // Drop any stale manual habit pick so the highlight follows the in-progress habit (now at the
        // top of the reordered list) when we return to the Day Plan after starting/pausing a habit.
        sched.clearSelectedHabit()
        if isBreak { sched.stopAutoRefresh() } else { sched.startAutoRefresh() }
        // Sync the player's time-of-day clock with what's actually on screen. (Don't use
        // setDateTimeClockHidden(!isBreak) — that hid the clock on the state change into a *playing*
        // habit started from this Postponed list, since the playing state isn't a break.)
        habitsVcObj?.refreshDateTimeClockVisibility()
    }

    /// Lightweight list-visibility re-sync (no reload/auto-refresh) — safe to call from within the
    /// Day Plan's reload, unlike updateScheduleTabForState().
    func refreshHabitListVisibilityForDayPlan() {
        guard let sched = scheduleVC else { return }
        let isBreak = currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_
        setHabitListHiddenForDayPlan(!isBreak && !sched.isDayPlanContentHidden)
    }

    // MARK: - ScheduleHost

    func scheduleSegments(now: Date) -> [ScheduleRoutineSegment] {
        let isMorning = lCurrentState != ._EVENING_HABIT_
        let source: [habit] = isMorning ? arrFilteredMorningHabits : arrFilteredEveningHabits
        let name = isMorning ? ScheduleText.morningRoutineHabits : ScheduleText.eveningRoutineHabits
        return ScheduleTab.standardSegments(activeName: name,
                                            activeHabits: ScheduleTab.habitInputs(from: source, now: now),
                                            isMorningActive: isMorning, now: now)
    }

    func scheduleStart(index: Int) {
        if let tbl = tblViewHabits, index >= 0, index < tbl.numberOfRows {
            tbl.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        playSelectedHabit()
    }

    func scheduleDone(index: Int) {
        let proxy = NSButton(); proxy.tag = index
        btnDoneClicked(sender: proxy)
    }

    func scheduleSkip(index: Int) {
        let proxy = NSButton(); proxy.tag = index
        btnSkipClicked(sender: proxy)
    }

    // A PAST habit completes BY ID, independent of the (postponed) live routine — forward to the shared
    // firstViewController flow (backdated /sync + popup/password on the key window). Without this the
    // default no-op ate the tap: symptom was clicking Complete while the routine is postponed did nothing
    // and wrote no log line. See Mac #2012.
    func schedulePastHabitDone(id: String, performedAt: Date) {
        firstViewControllerObj?.completePastMorningHabit(id: id, performedAt: performedAt)
    }

    /// Opens the shared "choose which habits to do today" sheet, mirroring the Habits view's
    /// "I don't have time for all these habits" action.
    func scheduleSkipRoutineForToday() {
        guard view.window != nil else { return }
        guard let vc = mainStoryboard.instantiateController(
            withIdentifier: NSStoryboard.SceneIdentifier("chooseHabitsVC")) as? chooseHabitsVC else { return }
        vc.currentHabitIndex = -1
        presentAsSheet(vc)
    }
}
