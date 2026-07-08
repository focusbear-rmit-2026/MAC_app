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

    /// Show/hide this VC's OWN Day Plan overlay. habitsStateVc is a container: for postpone /
    /// break-from-postpone it embeds routinePostponedInfoVc (via showRutinePostponedInfoView), which
    /// owns its own fully-working Day Plan. This overlay is pinned on top of that embedded view, so it
    /// must be hidden in those states — otherwise its no-op Play/Done/Skip swallow the clicks (the
    /// ScheduleHost actions here are intentionally empty, correct only for the read-only ._NOTHING_
    /// state). Shown for the states habitsStateVc renders itself (completed / next-routine / cancelled).
    func setOwnDayPlanHidden(_ hidden: Bool) {
        scheduleVC?.view.isHidden = hidden
    }

    // MARK: - ScheduleHost

    func scheduleSegments(now: Date) -> [ScheduleRoutineSegment] {
        let isMorning = currentState != ._EVENING_HABIT_ && currentState != ._POSTPONE_EVENING_HABIT_
        let name = isMorning ? ScheduleText.morningRoutineHabits : ScheduleText.eveningRoutineHabits

        // Recheck on every (re)build: if the routine has ALREADY run today (the app's own "done for
        // now" signal — the same condition reloadData uses for the "Great job… next routine" branch),
        // present it as a PAST completed routine, exactly like a previous day: read-only + struck
        // through, and Done-by-id (via the isEarlier flag) for any completion not yet synced — NOT an
        // active routine with a live action bar (whose Start/Done/Skip here are no-ops). Independent of
        // whether we're still inside the routine's time window. We deliberately use isHabitAlreadyShowed
        // rather than "all habit ids in dayPlanCompletedHabitIds", because that status can lag (e.g. the
        // just-finished last habit isn't in it yet) — which is the very case this fixes.
        if isHabitAlreadyShowed && !isShutOffTimeGoing() {
            let allDaySource = isMorning ? arrAllDaysMorningHabits : arrAllDaysEveningHabits
            let pastHabits = ScheduleTab.habitInputs(
                from: ScheduleTab.filterByWeekday(allDaySource, weekday: now.dayOfWeek()),
                now: now, dropCompleted: false)
            if !pastHabits.isEmpty {
                let windowStart = ScheduleTab.timeOnDate(isMorning ? startTime : shutOffTime, date: now) ?? now
                let windowEnd = ScheduleTab.timeOnDate(isMorning ? shutOffTime : cutOffTime, date: now)
                    ?? Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: now) ?? now
                let pastSeg = ScheduleRoutineSegment(
                    name: name, habits: pastHabits, windowStart: windowStart, windowEnd: windowEnd,
                    actionable: false, isEarlier: true)
                // Keep the OTHER routines' previews the standard build adds (evening preview / custom
                // routines); drop its actionable copy of THIS routine — replaced by the past one above.
                let previews = ScheduleTab.standardSegments(activeName: name, activeHabits: [],
                                                            isMorningActive: isMorning, now: now)
                    .filter { $0.name != name }
                return [pastSeg] + previews
            }
        }

        // Not yet run today (e.g. before the routine start): render as the upcoming routine.
        let source = isMorning ? arrFilteredMorningHabits : arrFilteredEveningHabits
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
    // A PAST habit completes BY ID, independent of the live routine state — so it's valid even here
    // (between-routines). Forward to the shared firstViewController flow (backdated /sync + popup on the
    // key window). Without this the default no-op ate the tap and nothing happened. See Mac #2005/#2012.
    func schedulePastHabitDone(id: String, performedAt: Date) {
        firstViewControllerObj?.completePastHabit(id: id, performedAt: performedAt)
    }

    func updateScheduleTabForState() {
        guard let sched = scheduleVC else { return }
        sched.view.isHidden = false
        sched.clearSelectedHabit()
        sched.startAutoRefresh()
    }

    func refreshHabitListVisibilityForDayPlan() { }

    /// #2010: when a routine is force-cancelled we keep the whole Day Plan visible and replace only that
    /// routine's section with an uncancel message + button. Return the section (its routineName, matched
    /// in makeHabitGroupCard) plus the morning/evening message + button text, or nil when nothing is
    /// cancelled. Driven by `cancelledRoutineName`, set in updateUncancelRoutineButtonVisibility.
    func cancelledRoutine() -> (sectionName: String, message: String, buttonTitle: String)? {
        guard let name = cancelledRoutineName else { return nil }
        let isEvening = (name == ScheduleText.eveningRoutineHabits)
        return (sectionName: name,
                message: isEvening ? ScheduleText.cancelledEveningRoutineMessage : ScheduleText.cancelledMorningRoutineMessage,
                buttonTitle: isEvening ? ScheduleText.uncancelEveningRoutineButton : ScheduleText.uncancelMorningRoutineButton)
    }

    /// The uncancel button in that section — force-uncompletes the routine (handles morning/evening).
    func uncancelRoutine() {
        btnUnCancelRoutineClicked(self)
    }

    /// #2010: the Day Plan now stays visible in ALL states — a cancelled routine is handled inline (its
    /// section becomes the uncancel message, see cancelledRoutine()), not by hiding the whole plan. So
    /// this only ever keeps the Day Plan up; the legacy message / resume views stay hidden.
    func applyDayPlanVisibility(cancelled: Bool) {
        scheduleVC?.view.isHidden = false
        lblTitle?.isHidden = true
        lblDescription?.isHidden = true
        btnResumeHabits?.isHidden = true
        scheduleVC?.startAutoRefresh()
    }
}
