//
//  habitsStateVc+Schedule.swift
//  Focus Bear
//
//  Gives the "between routines" state screen (habitsStateVc — shown once the morning/evening routine is
//  marked done for the day) the same Day Plan schedule the active/postponed screens have, instead of the
//  plain "next routine" message. #2010: the Day Plan should stay visible when a routine is complete, with
//  a force-uncomplete action in place of Skip so the user can resume (also recovers from a wrongly-derived
//  completion).
//
//  Unlike firstViewController/routinePostponedInfoVc this screen has no habit table, so the schedule is
//  effectively read-only here (the routine is done); Start/Done/Skip route to resuming the routine.
//

import Cocoa

private var hsScheduleVCKey: UInt8 = 0

extension habitsStateVc: ScheduleHost {

    private var scheduleVC: scheduleViewController? {
        get { objc_getAssociatedObject(self, &hsScheduleVCKey) as? scheduleViewController }
        set { objc_setAssociatedObject(self, &hsScheduleVCKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Install the Day Plan over the message. Idempotent.
    func setupScheduleTab() {
        guard scheduleVC == nil else { return }
        let sched = ScheduleTab.install(in: self)
        sched.host = self
        scheduleVC = sched
        // The Day Plan covers the whole area; hide the legacy "next routine" message + resume button so
        // they don't show through. (They stay in the view tree for the non-Day-Plan states.)
        lblTitle?.isHidden = true
        lblDescription?.isHidden = true
        btnResumeHabits?.isHidden = true
        btnUnCancelRoutine?.isHidden = true
        updateScheduleTabForState()
    }

    func refreshScheduleIfVisible() {
        if scheduleVC?.view.isHidden == false { scheduleVC?.reload() }
    }

    // MARK: - ScheduleHost

    func scheduleSegments(now: Date) -> [ScheduleRoutineSegment] {
        // Render the (completed) morning routine — dropCompleted:false so the done habits still show —
        // plus the evening / custom previews, so the whole day is visible even after completion.
        let isMorning = currentState != ._EVENING_HABIT_ && currentState != ._POSTPONE_EVENING_HABIT_
        let source = isMorning ? arrFilteredMorningHabits : arrFilteredEveningHabits
        let name = isMorning ? ScheduleText.morningRoutineHabits : ScheduleText.eveningRoutineHabits
        return ScheduleTab.standardSegments(
            activeName: name,
            activeHabits: ScheduleTab.habitInputs(from: source, now: now, dropCompleted: false),
            isMorningActive: isMorning, now: now)
    }

    // READ-ONLY here: this is the between-routines state (currentState == ._NOTHING_), where the routine
    // is not active — so the normal Play/Done/Skip/postpone flows (and their password gates) don't apply.
    // Do NOT route habit actions into resume/postpone from here, or they'd bypass the skip-password
    // checks that only guard the active _MORNING_HABIT_/_EVENING_HABIT_ states. The only action offered
    // in this state is the force-uncomplete (#2010, added separately).
    func scheduleStart(index: Int) { }
    func scheduleDone(index: Int)  { }
    func scheduleSkip(index: Int)  { }
    func scheduleSkipRoutineForToday() { }

    func updateScheduleTabForState() {
        guard let sched = scheduleVC else { return }
        sched.view.isHidden = false
        sched.clearSelectedHabit()
        sched.startAutoRefresh()
    }

    func refreshHabitListVisibilityForDayPlan() { }

    /// Gate the Day Plan by state: a CANCELLED (force-completed) routine shows the uncancel message
    /// instead of the Day Plan; every other state (genuinely complete / postponed / next-routine) keeps
    /// the Day Plan up. Called from updateUncancelRoutineButtonVisibility once the backend reports
    /// was_force_completed for today's routine.
    func applyDayPlanVisibility(cancelled: Bool) {
        scheduleVC?.view.isHidden = cancelled
        lblTitle?.isHidden = !cancelled
        lblDescription?.isHidden = !cancelled
        btnResumeHabits?.isHidden = !cancelled
        if !cancelled { scheduleVC?.startAutoRefresh() } else { scheduleVC?.stopAutoRefresh() }
    }
}
