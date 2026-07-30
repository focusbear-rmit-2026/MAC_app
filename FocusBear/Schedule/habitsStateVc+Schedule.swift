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
        // Which routine this between-routines view pertains to: the evening routine during the shutoff
        // window (or the evening / postpone-evening states), else the morning routine. isShutOffTimeGoing
        // is the discriminator because the evening routine runs inside the shutoff window.
        let isMorning = !(currentState == ._EVENING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_
                          || isShutOffTimeGoing())
        let name = isMorning ? ScheduleText.morningRoutineHabits : ScheduleText.eveningRoutineHabits
        let todayHabits = ScheduleTab.filterByWeekday(
            isMorning ? arrAllDaysMorningHabits : arrAllDaysEveningHabits, weekday: now.dayOfWeek())

        // Treat it as a PAST completed routine when that routine actually RAN today, per the completion
        // data — any of today's habits marked done in dayPlanCompletedHabitIds / the per-day cache the
        // #2150 fetch fills (isHabitDoneForDay). This works for BOTH morning and evening, unlike the old
        // isHabitAlreadyShowed && !isShutOffTimeGoing() signal, which excluded the evening routine (it
        // runs during the shutoff window). Rendered read-only + struck through, with Done-by-id
        // (isEarlier) for any completion not yet synced — exactly like a previous day, never a live
        // (here no-op) action bar. "Ran today" via any-habit-done is robust: a routine that's been done
        // has at least its earlier habits completed even if the just-finished last one is still syncing.
        let dayKey = getStringFromDate(date: now, dateFormat: "yyyy-MM-dd")
        // For the MORNING routine, also treat it as ran-today when isHabitAlreadyShowed is set — the same
        // "morning done, before shutoff" signal reloadData uses for its "next routine" message. Without
        // this, a completed morning whose habit ids aren't yet in the completion data (isHabitDoneForDay
        // empty — e.g. before the #2150 refetch) fell through to the "not run yet" branch below and
        // rendered a live (here no-op) Play/Skip/Done bar. Evening keeps isHabitDoneForDay only, since it
        // runs during the shutoff window where isHabitAlreadyShowed doesn't apply.
        let routineRanToday = todayHabits.contains { $0.id.map { isHabitDoneForDay($0, dayKey: dayKey) } ?? false }
            || (isMorning && isHabitAlreadyShowed)
        if routineRanToday {
            let pastHabits = ScheduleTab.habitInputs(from: todayHabits, now: now, dropCompleted: false)
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

        // Not run yet today (e.g. before the routine start): render as the upcoming routine.
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
    // Between routines is READ-ONLY (see above): the Play/Done/Skip/skip-routine actions are no-ops
    // here, so the Schedule view must not render the (dead) action bar even when a block is still
    // flagged isActionable (e.g. an evening routine shown after being force-completed).
    var supportsLiveHabitActions: Bool { false }
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
