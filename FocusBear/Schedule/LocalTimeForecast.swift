// LocalTimeForecast.swift
// Pure Day Plan capacity and priority allocation. No API, persistence, UI or localization dependencies.

import Foundation

/// One allocator for the forecast, completion estimates, date suggestions and reviewed work plans.
/// Pass a complete, deduplicated portfolio snapshot and the same placed blocks the Day Plan shows.
/// All amounts are minutes; fractional minutes preserve short habits and partial calendar events.
enum LocalTimeForecast {
    struct CapacitySettings: Codable, Equatable {
        var sleepStartMinute = 22 * 60
        var sleepEndMinute = 6 * 60
        /// Extra time not already represented by calendar events or placed habits.
        var selfCareMinutes = 0
        var isValid: Bool {
            (0..<1440).contains(sleepStartMinute) && (0..<1440).contains(sleepEndMinute)
                && sleepStartMinute != sleepEndMinute && (0...1440).contains(selfCareMinutes)
        }
    }

    struct Interval: Equatable {
        let start: Date
        let end: Date
    }

    /// Time the day has already committed to something placed on it — a calendar event, or a habit
    /// from the Day Plan. Task work dropped onto one of these is ABSORBED by it: the day is already
    /// paying for those minutes, so charging the task for them again charges the day twice.
    ///
    /// One type for both kinds, because it is one rule. This used to be `Habit`, and only habits
    /// carried a `blockKey`, so only habits could absorb: dragging a task onto a calendar event
    /// charged the day the task's whole estimate while dragging the same task onto a habit charged
    /// nothing (report 2026-09-17_09-08-25).
    struct PlacedBlock {
        enum Kind { case meeting, habit }
        /// A single scheduled occurrence, not just a recurring habit's or event's server ID.
        let id: String
        let kind: Kind
        /// The `DayPlanTask.blockKey` a task carries once it is pinned here, so the absorption can
        /// find this block's budget. nil for a block nothing can be pinned to — a calendar event
        /// the Day Plan could not give an id, or a caller that only measures capacity.
        let blockKey: String?
        let interval: Interval

        static func meeting(id: String, blockKey: String? = nil, interval: Interval) -> PlacedBlock {
            PlacedBlock(id: id, kind: .meeting, blockKey: blockKey, interval: interval)
        }
        static func habit(id: String, blockKey: String, interval: Interval) -> PlacedBlock {
            PlacedBlock(id: id, kind: .habit, blockKey: blockKey, interval: interval)
        }
    }

    struct DayInput {
        let date: Date
        /// Everything already placed on the day, charged in this order: calendar events first —
        /// they are fixed — then habits, which are placed around them.
        let blocks: [PlacedBlock]
        var settings = CapacitySettings()
        var availableFrom: Date? = nil
        /// This day's plan is settled, so it holds only the work already placed on it.
        ///
        /// "Assume the day plan for today + tomorrow is locked in" (report 2026-09-17_09-04-13).
        /// A locked day still costs what it costs and still reads as over-committed when it is —
        /// it simply stops being somewhere the planner may put work the user has not put there.
        var isLocked = false

        init(date: Date, blocks: [PlacedBlock], settings: CapacitySettings = .init(),
             availableFrom: Date? = nil, isLocked: Bool = false) {
            self.date = date
            self.blocks = blocks
            self.settings = settings
            self.availableFrom = availableFrom
            self.isLocked = isLocked
        }

        /// Callers that only measure capacity: bare event intervals, with no id for a task to be
        /// pinned to. Keyed events reach the designated initializer through `fromDayPlan`.
        init(date: Date, meetings: [Interval], habits: [PlacedBlock],
             settings: CapacitySettings = .init(), availableFrom: Date? = nil, isLocked: Bool = false) {
            // Identified by the span itself, not by position: two snapshots of one date merge into
            // a single day, and the same event listed in both must not be charged twice — nor must
            // a different event be deduplicated away because it happened to be listed second.
            self.init(date: date,
                      blocks: meetings.map { interval in
                          .meeting(id: "meeting:\(interval.start.timeIntervalSince1970)-\(interval.end.timeIntervalSince1970)",
                                   interval: interval)
                      } + habits,
                      settings: settings, availableFrom: availableFrom, isLocked: isLocked)
        }

        /// The Day Plan's placed blocks are authoritative. Overflow markers, sleep, deep-work
        /// fillers and sprint-break fillers must not consume this budget a second time.
        ///
        /// Deep-work blocks are deliberately absent from both lists: a deep-work block is not time
        /// the day has committed elsewhere, it IS the day's work time. Giving it an absorption
        /// budget would refund the very minutes it represents.
        static func fromDayPlan(date: Date, blocks: [ScheduleBlock], settings: CapacitySettings = .init(),
                                availableFrom: Date? = nil, isLocked: Bool = false) -> DayInput {
            let meetings = blocks.filter { $0.kind == .meeting }.map { block in
                PlacedBlock.meeting(id: "\(block.eventID ?? block.title):\(block.start.timeIntervalSince1970)",
                                    blockKey: block.eventID.map { DayPlanBlockKey.event(id: $0) },
                                    interval: Interval(start: block.start, end: block.end))
            }
            let habits = blocks.filter { $0.kind == .habit && !$0.didOverflow }.map { block in
                PlacedBlock.habit(id: "\(block.habitId ?? block.title):\(block.start.timeIntervalSince1970)",
                                  blockKey: DayPlanBlockKey.habit(named: block.title),
                                  interval: Interval(start: block.start, end: block.end))
            }
            return DayInput(date: date, blocks: meetings + habits,
                            settings: settings, availableFrom: availableFrom, isLocked: isLocked)
        }
    }

    struct ProjectInput {
        let id: String
        /// The new outcome on the server's /10 scale. Do not pass the legacy 1–4 importance enum.
        var outcome: Int = 2
        var dueDate: Date? = nil
        /// The project's own task counters. The forecast only downloads *unfinished* tasks, so
        /// without these the work already done is invisible to it and a half-finished project reads
        /// as 0% (report 2026-09-12_20-50-16).
        var totalTaskCount: Int? = nil
        var uncompletedTaskCount: Int? = nil

        /// Whether the user has actually rated this project's deadline flexibility. `0` is the
        /// store's mapping of the server's `outcome: null`, and it means "no opinion" — not "the
        /// most relaxed band". Only a rated project may tighten its tasks (`effectiveOutcome`).
        var hasRating: Bool { outcome > 0 }

        /// Share of the project's tasks already finished, by count, when the counters make sense.
        /// By count, not by effort: the finished tasks' estimates were never downloaded.
        var completedShare: Double? {
            guard let total = totalTaskCount, let unfinished = uncompletedTaskCount,
                  total > 0, unfinished >= 0, unfinished <= total else { return nil }
            return Double(total - unfinished) / Double(total)
        }
    }

    /// A task pinned to one block on one day — the Day Plan drop that says "do this inside that".
    /// The block may be a habit or a calendar event; `DayPlanBlockKey.absorbs` decides which keys
    /// qualify, in one place, so a second call site cannot quietly disagree.
    struct BlockAssignment: Equatable {
        let date: Date
        let blockKey: String
    }

    struct TaskInput: Equatable {
        /// What the forecast plans with when a task carries no rating of its own.
        static let unratedOutcome = 2
        let id: String
        var projectID: String? = nil
        /// nil or <= 0 is unknown effort, never a free task or an invented duration.
        var estimatedMinutes: Double? = nil
        var outcome: Int = TaskInput.unratedOutcome
        var perspiration: Int = 1
        var dueDate: Date? = nil
        /// Explicit future Day Plan placement is a lower bound, not a deadline.
        var notBefore: Date? = nil
        var blockAssignment: BlockAssignment? = nil
        var completed: Bool = false

        /// The day this task is explicitly PLACED on (a Day Plan placement), not its deadline. The
        /// same value `calculate` treats as the earliest day it may be allocated to, so a day's
        /// over-commitment is measured against exactly what was pinned to it.
        var pinnedDay: Date? {
            [notBefore, blockAssignment?.date].compactMap { $0 }.max()
        }
    }

    struct Capacity {
        let day: Date
        let meetingMinutes: Double
        /// Union of placed habit intervals after removing calendar overlaps.
        let habitMinutes: Double
        let sleepMinutes: Double
        let selfCareMinutes: Double
        let totalMinutes: Double
        var sleepAndSelfCareMinutes: Double { sleepMinutes + selfCareMinutes }
        /// Work minutes that sit in stretches long enough to actually work in — the same total as
        /// `rawWorkMinutes` on an open day, but much smaller on a day chopped into slivers between
        /// back-to-back meetings. nil when the day was built without interval detail.
        var usableWorkMinutes: Double? = nil
        var rawWorkMinutes: Double { totalMinutes - meetingMinutes - habitMinutes - sleepAndSelfCareMinutes }
        /// A day whose only gaps are three and five minutes long has no time for work, whatever the
        /// subtraction says — it claimed "11m available for work" on a day with no free block at all
        /// (report 2026-09-11_21-07-09).
        var availableWorkMinutes: Double { max(0, min(rawWorkMinutes, usableWorkMinutes ?? rawWorkMinutes)) }
        var overcommittedMinutes: Double { max(0, -rawWorkMinutes) }
    }

    struct Allocation: Equatable {
        let taskID: String
        let projectID: String?
        let day: Date
        let workMinutes: Double
        let absorbedBlockMinutes: Double
        var totalMinutes: Double { workMinutes + absorbedBlockMinutes }
    }

    struct Day: Identifiable {
        let capacity: Capacity
        let allocations: [Allocation]
        /// This day's plan is settled — see `DayInput.isLocked`.
        var isLocked = false
        var id: Date { capacity.day }
        var date: Date { capacity.day }
        var allocatedWorkMinutes: Double { allocations.reduce(0) { $0 + $1.workMinutes } }
        var absorbedBlockMinutes: Double { allocations.reduce(0) { $0 + $1.absorbedBlockMinutes } }
        /// Minutes of this day's work window nothing has claimed yet. A LOCKED day still reports
        /// its real leftover here: the lock is a rule about what the planner may do, not a claim
        /// that the day is full, and the chosen-day warning must not tell the user a day they
        /// picked themselves has no time in it when it plainly does.
        var remainingWorkMinutes: Double { max(0, capacity.availableWorkMinutes - allocatedWorkMinutes) }
    }

    struct TaskResult {
        let task: TaskInput
        let allocations: [Allocation]
        let unallocatedMinutes: Double
        var hasEstimate: Bool { LocalTimeForecast.estimate(task) != nil }
        var completionDate: Date? {
            guard hasEstimate, !task.completed, unallocatedMinutes < 0.000_001 else { return nil }
            return allocations.last?.day
        }
    }

    struct ProjectResult: Identifiable {
        let project: ProjectInput
        let estimatedMinutes: Double
        let completedMinutes: Double
        let allocatedByDeadlineMinutes: Double
        let unknownTaskCount: Int
        /// Tasks still to be placed. Zero means the project has nothing left to do — which is not
        /// the same as having no estimates, and is why an empty backlog must not read as a risk.
        let outstandingTaskCount: Int
        let completionDate: Date?
        let hasUnallocatedWork: Bool
        var id: String { project.id }

        /// Every task the project had is done: the server still counts tasks against it, but none of
        /// them is outstanding work. A project that never had a task is not "finished", it is empty,
        /// so the counters have to say it once had some.
        var isFinished: Bool { outstandingTaskCount == 0 && (project.totalTaskCount ?? 0) > 0 }

        /// How much of the whole project is expected to be done by its due day (or by the end of
        /// the horizon when it has no deadline). Missing estimates suppress the percentage rather
        /// than making unknown work look complete.
        ///
        /// Two parts, because the forecast only sees unfinished work: what is already finished
        /// (from the project's own counters, by task count) plus the share of what is left that
        /// fits before the deadline. Without the first part a project whose remaining work cannot
        /// fit read 0% with half its tasks done (report 2026-09-12_20-50-16).
        var likelyCompletionPercent: Int? {
            if isFinished { return 100 }
            guard estimatedMinutes > 0, unknownTaskCount == 0 else { return nil }
            let remainingShare = min(1, max(0, (completedMinutes + allocatedByDeadlineMinutes) / estimatedMinutes))
            let done = project.completedShare ?? 0
            return min(100, max(0, Int(floor(100 * (done + (1 - done) * remainingShare)))))
        }
    }

    struct Week: Identifiable {
        let start: Date
        let days: [Day]
        var id: Date { start }
        var meetingMinutes: Double { days.reduce(0) { $0 + $1.capacity.meetingMinutes } }
        var habitMinutes: Double { days.reduce(0) { $0 + $1.capacity.habitMinutes } }
        var sleepAndSelfCareMinutes: Double { days.reduce(0) { $0 + $1.capacity.sleepAndSelfCareMinutes } }
        var allocatedWorkMinutes: Double { days.reduce(0) { $0 + $1.allocatedWorkMinutes } }
        var remainingWorkMinutes: Double { days.reduce(0) { $0 + $1.remainingWorkMinutes } }
        /// For a stacked time chart use workMinutes, not totalMinutes: absorbed work is already
        /// counted in habits. A project's drill-down may show both components separately.
        var workMinutesByProject: [String: Double] {
            days.flatMap(\.allocations).reduce(into: [:]) { result, allocation in
                if let id = allocation.projectID { result[id, default: 0] += allocation.workMinutes }
            }
        }
    }

    struct Result {
        let days: [Day]
        let tasks: [TaskResult]
        let projects: [ProjectResult]

        func weeks(calendar: Calendar) -> [Week] {
            let groups = Dictionary(grouping: days) {
                calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start ?? $0.date
            }
            return groups.keys.sorted().map { Week(start: $0, days: groups[$0] ?? []) }
        }
    }

    struct SlotSuggestion {
        let startDate: Date?
        let completionDate: Date?
        let unallocatedMinutes: Double
        /// The latest day this task's project allows, or nil when it has no project or no end date.
        /// A suggestion is as much a claim about a date as an explicit move is, so it is held to the
        /// same ceiling `proposeWorkPlan` applies.
        var projectEnd: Date? = nil
        /// The candidate can fit across the supplied horizon; it may require several days.
        var fits: Bool { completionDate != nil && unallocatedMinutes < 0.000_001 }
        /// The work fits somewhere, but only after the project it belongs to has ended.
        var exceedsProjectEnd: Bool {
            guard fits, let finish = completionDate else { return false }
            return ForecastCeiling.breaches(finish, ceiling: projectEnd)
        }
        /// THE day the app proposes for this task, and the only one it may name. A new task's due
        /// date defaults to it and the chosen-day warning points at it, so the app can never propose
        /// one date while calling another the next available (report 2026-09-15_20-08-56: the field
        /// defaulted to 24 Nov from `nextFreeDay` while the row read 28 Oct from `nextSlot`).
        ///
        /// nil once past the project's end date: a task in a project that ends on the 23rd must never
        /// be offered the 5th of the next month (report 2026-09-16_17-52-37 — a project rated 5/5 and
        /// due in seven days whose new task was suggested a date six weeks out).
        var proposedDay: Date? { fits && !exceedsProjectEnd ? completionDate : nil }
    }

    /// How loaded a day is: what it can hold, and what is already committed to it.
    ///
    /// THE definition, shared by the Day Plan's header and the task editor's due-date advice. They
    /// used to compute it separately and print different numbers for the same day — the editor said
    /// "-5m available on Fri 2 Oct" while the Day Plan said "over by 36m" (report
    /// 2026-09-15_20-08-56). The editor was reading `remainingWorkMinutes`, which clamps at zero and
    /// so can never express a day that is ALREADY over its capacity.
    struct DayLoad: Equatable {
        let day: Date
        let capacityMinutes: Double
        /// Work committed to this day: for the Day Plan, the tasks placed on it; for a horizon
        /// forecast, the work pinned to it (see `dayLoad(on:forecast:calendar:)`).
        let committedMinutes: Double
        /// What is left after the committed work — NEGATIVE when the day is over its capacity. The
        /// Day Plan header shows this as the day's "buffer"; `freeMinutes` and `overcommittedMinutes`
        /// are just its two clamped halves, so the row's figure and the banner's can never differ.
        var bufferMinutes: Double { capacityMinutes - committedMinutes }
        /// Minutes past what the day can hold. Zero unless it is genuinely over-committed.
        var overcommittedMinutes: Double { max(0, -bufferMinutes) }
        /// Minutes still unspoken for. Zero once the day is full.
        var freeMinutes: Double { max(0, bufferMinutes) }
        var isOvercommitted: Bool { overcommittedMinutes > capacityEpsilon }
    }

    /// The Day Plan header's arithmetic, in one place: time absorbed by a habit is work the day was
    /// already paying for, so it does not count twice.
    static func dayLoad(day: Date, capacityMinutes: Double, plannedMinutes: Double,
                        absorbedMinutes: Double = 0) -> DayLoad {
        DayLoad(day: day, capacityMinutes: capacityMinutes,
                committedMinutes: max(0, plannedMinutes - absorbedMinutes))
    }

    /// The same reading taken from a horizon forecast. The allocator never over-fills a day — surplus
    /// spills onto later days and `remainingWorkMinutes` clamps at zero — so a day's over-commitment
    /// survives only as work PINNED to it (an explicit Day Plan placement) that the day could not
    /// hold. That is what makes this agree with the Day Plan's own figure.
    static func dayLoad(on day: Date, forecast: Result, calendar: Calendar) -> DayLoad? {
        guard let row = forecast.days.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) else { return nil }
        let pinnedHere = forecast.tasks.filter { result in
            guard !result.task.completed, let pinned = result.task.pinnedDay else { return false }
            return calendar.isDate(pinned, inSameDayAs: row.date)
        }
        let demanded = pinnedHere.reduce(0) { $0 + (estimate($1.task) ?? 0) }
        let absorbed = pinnedHere.flatMap(\.allocations)
            .filter { calendar.isDate($0.day, inSameDayAs: row.date) }
            .reduce(0) { $0 + $1.absorbedBlockMinutes }
        // Work not pinned to this day still occupies it, and counts towards how full it is.
        let otherWork = row.allocations
            .filter { allocation in !pinnedHere.contains { $0.task.id == allocation.taskID } }
            .reduce(0) { $0 + $1.workMinutes }
        return dayLoad(day: row.date, capacityMinutes: row.capacity.availableWorkMinutes,
                       plannedMinutes: demanded + otherWork, absorbedMinutes: absorbed)
    }

    /// A chosen day that cannot hold a task, in the words the day itself calls for: already over its
    /// capacity, or merely short of room. Plus the day the app proposes instead.
    struct DayCapacityWarning: Equatable {
        let load: DayLoad
        /// Room this candidate could actually use on the day, its own reserved time included.
        let availableMinutes: Double
        /// Always present: with nothing to propose there is nothing actionable to say, and the advice
        /// says "does not fit" instead.
        let suggestedDay: Date
        var day: Date { load.day }
        /// The amount the sentence names: how far over the day already is, else how little is left.
        var amountMinutes: Double { load.isOvercommitted ? load.overcommittedMinutes : availableMinutes }
    }

    enum ChangeKind: String { case task, project }
    struct DueDateChange: Identifiable {
        let kind: ChangeKind
        let itemID: String
        let previousDate: Date?
        let proposedDate: Date
        var id: String { "\(kind.rawValue):\(itemID)" }
    }
    enum ConflictReason: String {
        case hardDeadline, postponementLimit, outsideHorizon, missingEstimate, missingOutcome
        /// The proposal lands after the owning project's own due date. A project's end date is a
        /// ceiling over all of its work, not a hint, so the move is refused rather than made.
        case projectEndDate
    }
    struct PlanConflict: Identifiable {
        let kind: ChangeKind
        let itemID: String
        let reason: ConflictReason
        let earliestCompletionDate: Date?
        var id: String { "\(kind.rawValue):\(itemID):\(reason.rawValue)" }
    }
    /// This value is only a proposal. The caller must show the exact changes and obtain explicit
    /// review before its existing task/project APIs write anything; generating this has no effects.
    struct WorkPlan {
        let changes: [DueDateChange]
        let conflicts: [PlanConflict]

        /// The conflicts a rescheduling screen should still raise. A hard deadline is not a problem
        /// to review — it is the user's own instruction that the date is fixed, and
        /// `allowsPostponement` has already refused to propose a new one — so listing it would keep
        /// a row on a screen that has nothing left to offer for it.
        var reviewableConflicts: [PlanConflict] { conflicts.filter { $0.reason != .hardDeadline } }

        /// The same plan with the dates the user typed themselves put back.
        ///
        /// A hand-typed date is an instruction, not a proposal, so it must survive every
        /// recalculation the sheet performs — and the sheet recalculates after every edit
        /// ("Let me override the due date by clicking on the -> new date", report
        /// 2026-09-16_09-39-37). A row whose override equals the date it already has is not a change
        /// at all and drops out, exactly as a computed proposal would.
        func applyingManualDates(_ dates: [String: Date], calendar: Calendar) -> WorkPlan {
            guard !dates.isEmpty else { return self }
            let updated = changes.compactMap { change -> DueDateChange? in
                guard let chosen = dates[change.id] else { return change }
                let day = calendar.startOfDay(for: chosen)
                if let previous = change.previousDate, calendar.isDate(previous, inSameDayAs: day) { return nil }
                return DueDateChange(kind: change.kind, itemID: change.itemID,
                                     previousDate: change.previousDate, proposedDate: day)
            }
            return WorkPlan(changes: updated, conflicts: conflicts)
        }

        /// A date typed on a row the planner **refused** turns that row into a proposal.
        ///
        /// "Let me reschedule manually if I want to" (report 2026-09-16_22-22-50, follow-up), said of
        /// the "Can't be rescheduled" list. Those rows are exactly the ones the automatic pass gave up
        /// on, which makes a dead-end list the worst possible thing to leave there: the app has just
        /// told the user it cannot decide, and then denied them the decision.
        ///
        /// The refusals are all refusals to *invent* a date — past the postponement the rating allows,
        /// past the project's end. None of them is a claim that the user may not choose one. So a
        /// typed date is honoured, the conflict stops being raised, and the row joins the changes to
        /// be reviewed and applied like any other.
        ///
        /// `.missingEstimate` is deliberately still refused: without an estimate the task cannot be
        /// placed at all, so a date on it would be a date the plan cannot keep. That row's fix is the
        /// estimate, which the row already offers.
        func adoptingManualDates(_ dates: [String: Date], previousDate: (ChangeKind, String) -> Date?,
                                 calendar: Calendar) -> WorkPlan {
            guard !dates.isEmpty else { return self }
            let alreadyProposed = Set(changes.map(\.id))
            var adopted: [DueDateChange] = []
            var kept: [PlanConflict] = []
            for conflict in conflicts {
                let changeID = "\(conflict.kind.rawValue):\(conflict.itemID)"
                guard conflict.reason != .missingEstimate, !alreadyProposed.contains(changeID),
                      let chosen = dates[changeID] else { kept.append(conflict); continue }
                let day = calendar.startOfDay(for: chosen)
                let previous = previousDate(conflict.kind, conflict.itemID)
                // A date equal to the one it already has is not a change, exactly as for a computed
                // proposal — but the conflict is gone either way, because the user has answered it.
                if previous.map({ calendar.isDate($0, inSameDayAs: day) }) != true {
                    adopted.append(DueDateChange(kind: conflict.kind, itemID: conflict.itemID,
                                                 previousDate: previous, proposedDate: day))
                }
            }
            guard !adopted.isEmpty || kept.count != conflicts.count else { return self }
            return WorkPlan(changes: changes + adopted, conflicts: kept)
        }
    }

    /// `unreservedTaskID` opts one task out of the hard-deadline capacity reservation below. Only
    /// `nextSlot` uses it, and only for the task whose date is being chosen — see the note there.
    static func calculate(days: [DayInput], projects: [ProjectInput], tasks: [TaskInput],
                          calendar: Calendar, unreservedTaskID: String? = nil) -> Result {
        let uniqueProjects = unique(projects, id: { $0.id })
        let uniqueTasks = unique(tasks, id: { $0.id })
        let projectByID = Dictionary(uniqueKeysWithValues: uniqueProjects.map { ($0.id, $0) })
        var budgets = preparedDays(days, calendar: calendar)
        let ordered = uniqueTasks.sorted { left, right in
            precedes(left, right, projects: projectByID, calendar: calendar)
        }
        // A completed task linked to today's habit has already used its share. Reserve that
        // share before planning remaining work, without counting completed effort twice in the
        // project's numerator. No execution date is invented for other completed tasks.
        for task in ordered where task.completed {
            guard let duration = estimate(task), let assignment = task.blockAssignment,
                  let index = budgets.firstIndex(where: { calendar.isDate($0.capacity.day, inSameDayAs: assignment.date) }) else { continue }
            _ = budgets[index].consume(key: assignment.blockKey, requested: duration)
        }
        // Hard deadlines are not scheduled by the planner — they are already scheduled, by the user.
        //
        // "It shouldn't move hard deadline tasks from their current position in the day plan. It
        // should calculate capacity subtracting the tasks with 5" (report 2026-09-16_09-40-20). So a
        // 5 is placed on its own day and that time comes out of the day BEFORE anything else is
        // allocated, and the rest of the plan is built around it. Without this, a day's committed
        // hard-deadline work was invisible to the model and the plan proposed days the user had
        // already spent — "16th is already overloaded".
        //
        // Its due date IS its position: that is what a hard deadline means, and it is the date the
        // reschedule screen already shows and already refuses to move.
        //
        // Deliberately narrow, to avoid double-counting:
        //   · only tasks with no explicit placement — one carrying a `notBefore` or a habit
        //     assignment is already pinned by the main loop below, which also handles habit
        //     absorption, and taking its time here as well would charge the day twice;
        //   · only when its day falls inside the horizon — there is no modelled day to reserve
        //     otherwise, so nothing changes for those;
        //   · a 5 with no due date has no position to keep, so it is planned like anything else and
        //     the plan proposes it a first date;
        //   · never onto a LOCKED day. A locked day's plan is the one the user is about to work; a
        //     hard deadline landing on it is a reason to warn, not a licence to book its hours.
        var fixedResults: [String: TaskResult] = [:]
        for task in ordered where !task.completed && task.pinnedDay == nil && task.id != unreservedTaskID {
            guard let duration = estimate(task), duration > 0,
                  !allowsPostponement(outcome: effectiveOutcome(task: task,
                                                                project: task.projectID.flatMap { projectByID[$0] })),
                  let due = task.dueDate,
                  let index = budgets.firstIndex(where: { calendar.isDate($0.capacity.day, inSameDayAs: due) }),
                  budgets[index].acceptsUnplannedWork
            else { continue }
            let day = budgets[index].capacity.day
            // Floored at zero: a day whose hard-deadline work alone exceeds its capacity offers
            // nothing to anything else, never a negative budget. The day still reads as
            // over-capacity in `dayLoad`, because this allocation counts as planned work — it does
            // not quietly look free while refusing every slot.
            budgets[index].remainingWork = max(0, budgets[index].remainingWork - duration)
            let allocation = Allocation(taskID: task.id, projectID: task.projectID, day: day,
                                        workMinutes: duration, absorbedBlockMinutes: 0)
            budgets[index].allocations.append(allocation)
            fixedResults[task.id] = TaskResult(task: task, allocations: [allocation], unallocatedMinutes: 0)
        }
        var results: [TaskResult] = []
        for task in ordered {
            if let fixed = fixedResults[task.id] { results.append(fixed); continue }
            guard let duration = estimate(task), !task.completed else {
                results.append(TaskResult(task: task, allocations: [], unallocatedMinutes: 0))
                continue
            }
            var remaining = duration
            var allocations: [Allocation] = []
            let earliest = [task.notBefore, task.blockAssignment?.date].compactMap { $0 }.map { calendar.startOfDay(for: $0) }.max()
            for index in budgets.indices where remaining > 0.000_001 {
                let day = budgets[index].capacity.day
                guard earliest.map({ day >= $0 }) ?? true else { continue }
                // A locked day holds only what is already placed on it. Work pinned here by the
                // user's own Day Plan still runs here; anything else waits for the first day whose
                // plan is still open. Work pinned here that does not FIT still spills forward, and
                // that spill is the proposal the reschedule screen makes.
                guard budgets[index].acceptsUnplannedWork
                        || task.pinnedDay.map { calendar.isDate($0, inSameDayAs: day) } == true else { continue }
                var absorbed: Double = 0
                if let assignment = task.blockAssignment, calendar.isDate(assignment.date, inSameDayAs: day) {
                    absorbed = budgets[index].consume(key: assignment.blockKey, requested: remaining)
                }
                let work = min(remaining - absorbed, budgets[index].remainingWork)
                guard work + absorbed > 0 else { continue }
                budgets[index].remainingWork -= work
                remaining = max(0, remaining - absorbed - work)
                let allocation = Allocation(taskID: task.id, projectID: task.projectID, day: day,
                                            workMinutes: work, absorbedBlockMinutes: absorbed)
                allocations.append(allocation)
                budgets[index].allocations.append(allocation)
            }
            results.append(TaskResult(task: task, allocations: allocations, unallocatedMinutes: remaining))
        }
        let projectResults = uniqueProjects.sorted {
            projectPrecedes($0, $1, calendar: calendar)
        }.map { project -> ProjectResult in
            let members = results.filter { $0.task.projectID == project.id }
            let deadline = project.dueDate.map { calendar.startOfDay(for: $0) }
            let known = members.reduce(0) { $0 + (estimate($1.task) ?? 0) }
            let completed = members.filter { $0.task.completed }.reduce(0) { $0 + (estimate($1.task) ?? 0) }
            let byDeadline = members.flatMap(\.allocations).filter { allocation in
                deadline.map { allocation.day <= $0 } ?? true
            }.reduce(0) { $0 + $1.totalMinutes }
            let unknown = members.filter { estimate($0.task) == nil }.count
            let outstanding = members.filter { !$0.task.completed }.count
            let unallocated = members.contains { $0.unallocatedMinutes > 0.000_001 }
            let finish = unknown == 0 && !unallocated ? members.compactMap(\.completionDate).max() : nil
            return ProjectResult(project: project, estimatedMinutes: known, completedMinutes: completed,
                                 allocatedByDeadlineMinutes: byDeadline, unknownTaskCount: unknown,
                                 outstandingTaskCount: outstanding,
                                 completionDate: finish, hasUnallocatedWork: unallocated)
        }
        return Result(days: budgets.map {
                          Day(capacity: $0.capacity, allocations: $0.allocations, isLocked: !$0.acceptsUnplannedWork)
                      },
                      tasks: results, projects: projectResults)
    }

    /// Re-runs the same priority allocation including the draft. It never picks a full day as a
    /// successful fallback, and outcome/perspiration take effect through the shared task ordering.
    /// The candidate is deliberately NOT given the hard-deadline reservation the other tasks get.
    /// That reservation pins a 5 to its own due date, which is the right answer when the date is
    /// settled — but here the date is the very thing being chosen, so pinning it would hand the
    /// field's current value straight back as the "suggestion". Every other task keeps its
    /// reservation, so the candidate is placed around work that is genuinely committed.
    static func nextSlot(for candidate: TaskInput, days: [DayInput], projects: [ProjectInput],
                         tasks: [TaskInput], calendar: Calendar) -> SlotSuggestion {
        let result = calculate(days: days, projects: projects,
                               tasks: tasks.filter { $0.id != candidate.id } + [candidate],
                               calendar: calendar, unreservedTaskID: candidate.id)
        let row = result.tasks.first { $0.task.id == candidate.id }
        let owner = candidate.projectID.flatMap { id in projects.first { $0.id == id } }
        return SlotSuggestion(startDate: row?.allocations.first?.day,
                              completionDate: row?.completionDate,
                              unallocatedMinutes: row?.unallocatedMinutes ?? (estimate(candidate) ?? 0),
                              projectEnd: ForecastCeiling.forTask(candidate, project: owner, calendar: calendar))
    }

    /// Minutes of work a day can still give this candidate: its unused work time plus whatever it has
    /// already reserved for this same candidate, because re-picking a day the task already occupies
    /// must not ask for that time twice. Only the candidate's own habit absorption counts — another
    /// task's habit budget is not available to it.
    static func availableMinutes(on day: Day, for candidateID: String?) -> Double {
        day.remainingWorkMinutes + day.allocations.filter { $0.taskID == candidateID }
            .reduce(0) { $0 + $1.workMinutes + $1.absorbedBlockMinutes }
    }

    /// The first day that still has room for `minutes` of work, counting `candidateID`'s own existing
    /// allocations as room it may reuse. `minutes` of 0 asks only for a day that is not already full —
    /// the rule behind the new-task due-date default (`LocalForecastStore.nextFreeDay`). The chosen-day
    /// warning passes the task's whole estimate instead, so the day it suggests really does fit it.
    static func firstDayWithRoom(forMinutes minutes: Double, candidateID: String? = nil,
                                 in forecast: Result) -> Date? {
        // Locked days are skipped, because this is the planner's own question — "where would the app
        // put this?" — and `nextSlot` will not put anything on one. The two answers have to match:
        // the field defaulting to a day the row then argues with is the bug from report
        // 2026-09-15_20-08-56, and a locked day is a fresh way to reintroduce it.
        forecast.days.first { !$0.isLocked && hasRoom(on: $0, forMinutes: minutes, candidateID: candidateID) }?.date
    }

    private static func hasRoom(on day: Day, forMinutes minutes: Double, candidateID: String?) -> Bool {
        let room = availableMinutes(on: day, for: candidateID)
        return minutes > capacityEpsilon ? room >= minutes - capacityEpsilon : room > capacityEpsilon
    }

    /// Why a manually chosen day cannot hold the task, and where it could go instead. Existing
    /// allocations remain reserved: choosing a date must not silently move somebody else's planned
    /// task. The shortfall, the day it applies to and the suggestion all come out of this one
    /// calculation, so the warning's numbers can never disagree with the reason it is showing.
    ///
    /// nil means there is nothing to say: the day has room, the task has no estimate to fit, or the
    /// day is one the forecast never costed. That last case matters — every overdue task's stored
    /// date is a day that has gone, and claiming "no time available" on it would be a capacity
    /// statement about a day whose capacity was never calculated.
    static func capacityWarning(forChosenDay day: Date, candidate: TaskInput, forecast: Result,
                                proposedDay: Date?, calendar: Calendar) -> DayCapacityWarning? {
        guard let needed = estimate(candidate), let proposedDay = proposedDay,
              let chosen = forecast.days.first(where: { calendar.isDate($0.date, inSameDayAs: day) }),
              let load = dayLoad(on: day, forecast: forecast, calendar: calendar) else { return nil }
        // The day the app itself proposes is never argued with: at this task's priority it fits there,
        // even though the day's leftover slack alone would not cover it.
        guard !calendar.isDate(proposedDay, inSameDayAs: day) else { return nil }
        let available = availableMinutes(on: chosen, for: candidate.id)
        guard needed > available + capacityEpsilon else { return nil }
        return DayCapacityWarning(load: load, availableMinutes: available, suggestedDay: proposedDay)
    }

    static func proposeWorkPlan(_ forecast: Result, calendar: Calendar) -> WorkPlan {
        var changes: [DueDateChange] = []
        var conflicts: [PlanConflict] = []
        let projectByID = Dictionary(forecast.projects.map { ($0.id, $0.project) }, uniquingKeysWith: { first, _ in first })
        let lockedDays = forecast.days.filter(\.isLocked).map(\.date)
        func isLocked(_ day: Date) -> Bool { lockedDays.contains { calendar.isDate($0, inSameDayAs: day) } }
        func consider(kind: ChangeKind, id: String, outcome: Int, due: Date?, finish: Date?, unknown: Bool,
                      unallocated: Bool, ceiling: Date? = nil, planned: Date? = nil) {
            if unknown {
                conflicts.append(PlanConflict(kind: kind, itemID: id, reason: .missingEstimate, earliestCompletionDate: finish))
                return
            }
            guard let finish = finish, !unallocated else {
                conflicts.append(PlanConflict(kind: kind, itemID: id, reason: .outsideHorizon, earliestCompletionDate: finish))
                return
            }
            let normalizedDue = due.map { calendar.startOfDay(for: $0) }
            let isPostponement = normalizedDue.map { finish > $0 } == true
            // An unrated item is judged first: with no rating there is no band to judge it against,
            // and the fix is to rate it rather than to argue with its project.
            if isPostponement, outcome <= 0 {
                conflicts.append(PlanConflict(kind: kind, itemID: id, reason: .missingOutcome, earliestCompletionDate: finish))
                return
            }
            // The project's end date is a ceiling on its tasks, and it outranks the flexibility
            // bands: it is the more specific reason, and — unlike `.hardDeadline`, which is filtered
            // out of `reviewableConflicts` as the user's own instruction — it is one the screen
            // shows, so a task fixed by its project says *why* instead of vanishing. A project with
            // no due date passes `nil` and is not ceilinged: an absent end date is the absence of a
            // ceiling, never an infinite one.
            if ForecastCeiling.breaches(finish, ceiling: ceiling), normalizedDue != finish {
                conflicts.append(PlanConflict(kind: kind, itemID: id, reason: .projectEndDate, earliestCompletionDate: finish))
                return
            }
            // "Hard deadline — can't shift" means it cannot shift, in EITHER direction.
            //
            // This guard used to sit inside the `isPostponement` branch, so the top rung was
            // immovable backwards and freely movable forwards: a task the user had pinned to the
            // 18th was quietly proposed for the 16th ("It's a hard deadline - means it probably
            // shouldn't change", report 2026-09-16_09-40-20). Pulling work forward is still right for
            // every other rung — that is how a nearer deadline's work gets done first — but a rung
            // whose own words are "can't shift" must be exempt from it.
            if let old = normalizedDue, finish != old, !allowsPostponement(outcome: outcome) {
                conflicts.append(PlanConflict(kind: kind, itemID: id, reason: .hardDeadline, earliestCompletionDate: finish))
                return
            }
            if let old = normalizedDue, isPostponement {
                if let allowance = postponementDays(outcome: outcome),
                   let latest = calendar.date(byAdding: .day, value: allowance, to: old), finish > latest {
                    conflicts.append(PlanConflict(kind: kind, itemID: id, reason: .postponementLimit, earliestCompletionDate: finish))
                    return
                }
            }
            // Projects keep an achievable due date; task proposals also bring later dates forward
            // to reflect the work that must be done first for the highest-outcome project.
            if normalizedDue == finish { return }
            if kind == .project && normalizedDue.map({ finish < $0 }) == true { return }
            // Never a date on a locked day. The only work that finishes on one is work the user has
            // already planned there, and re-dating that changes nothing about when it happens — it
            // just fills the screen with rows saying "brought forward to today" for work that was
            // already today's (report 2026-09-17_09-04-13). Not a conflict either: there is nothing
            // here for the user to decide.
            if isLocked(finish) { return }
            changes.append(DueDateChange(kind: kind, itemID: id, previousDate: due, proposedDate: finish))
        }
        for task in forecast.tasks where !task.task.completed {
            let owner = task.task.projectID.flatMap { projectByID[$0] }
            consider(kind: .task, id: task.task.id,
                     outcome: effectiveOutcome(task: task.task, project: owner), due: task.task.dueDate,
                     finish: task.completionDate, unknown: !task.hasEstimate,
                     unallocated: task.unallocatedMinutes > 0.000_001,
                     ceiling: ForecastCeiling.forTask(task.task, project: owner, calendar: calendar),
                     planned: task.task.pinnedDay)
        }
        for project in forecast.projects where project.completedMinutes < project.estimatedMinutes || project.unknownTaskCount > 0 {
            consider(kind: .project, id: project.id, outcome: project.project.outcome, due: project.project.dueDate,
                     finish: project.completionDate, unknown: project.unknownTaskCount > 0, unallocated: project.hasUnallocatedWork)
        }
        return WorkPlan(changes: changes, conflicts: conflicts)
    }

    /// The deadline flexibility a task is actually planned under. A project is a claim over all of
    /// its work — "if the project is hard deadline importance then all its tasks inherit that"
    /// (report 2026-09-15_21-00-07) — so the project's rating can only ever *tighten* a task's,
    /// never loosen it. That is why this is a maximum and not an override: a task the user has
    /// personally pinned to a hard deadline inside a relaxed project keeps its own pin, while every
    /// task in a hard-deadline project inherits the project's regardless of its own setting.
    /// A task with no project, an **unrated** project, or one rated no higher, keeps its own rating.
    ///
    /// `hasRating` is the load-bearing part and is checked explicitly rather than left to `max`.
    /// Almost every real project is unrated — on the account this was measured against, 130 of 131
    /// carried `outcome: null` — and an unrated project must contribute *nothing*. `max` alone gets
    /// that right only because the store maps `nil` to `0`; `ProjectInput.outcome` itself defaults
    /// to `2`, so any call site that omits the argument would silently make every unrated project
    /// claim a rating over its tasks. That is the worst direction for this to fail in — it would
    /// pull tasks out of rescheduling and tell the user work is urgent when it is not — so the
    /// absence is stated here and pinned by a test rather than being an emergent property of `max`.
    static func effectiveOutcome(task: TaskInput, project: ProjectInput?) -> Int {
        guard let project = project, project.hasRating else { return task.outcome }
        return max(task.outcome, project.outcome)
    }

    /// Whether this task's rating came from its project rather than from itself, so the screen can
    /// say so instead of looking as though it ignored a per-task setting.
    static func inheritsProjectOutcome(task: TaskInput, project: ProjectInput?) -> Bool {
        guard let project = project, project.hasRating else { return false }
        return project.outcome > task.outcome
    }

    /// The latest day a task may be moved to: its project's own due date. `nil` when the task has no
    /// project or the project has no due date — an absent end date imposes no ceiling.
    ///
    /// Prefer `ForecastCeiling.forTask` and `ForecastCeiling.allows` at call sites; this stays as the
    /// derivation they share.
    static func projectCeiling(task: TaskInput, project: ProjectInput?, calendar: Calendar) -> Date? {
        guard task.projectID != nil, let due = project?.dueDate else { return nil }
        return calendar.startOfDay(for: due)
    }

    /// The one question every path that names a date must ask before offering one.
    ///
    /// The app names a date in two places — `proposeWorkPlan` proposes a move, `nextSlot` suggests a
    /// due date — and both must refuse a day past the owning project's end. They derived the ceiling
    /// from the same function but each compared against it in its own way, which is how a suggestion
    /// six weeks past a project's deadline shipped while the reschedule sheet refused the very same
    /// day (report 2026-09-16_17-52-37). Three of the last four bugs on this screen had that shape:
    /// the rule existed, and a second code path did not apply it.
    ///
    /// So the comparison lives here, once. A third date-naming path has to ask this rather than
    /// write `finish > ceiling` again and get to decide for itself what `nil` means.
    enum ForecastCeiling {
        /// The ceiling a task is held under, or `nil` when nothing constrains it.
        static func forTask(_ task: TaskInput, project: ProjectInput?, calendar: Calendar) -> Date? {
            projectCeiling(task: task, project: project, calendar: calendar)
        }

        /// Whether `day` is inside the ceiling. A `nil` ceiling is the ABSENCE of a ceiling — never an
        /// infinite one, and never a reason to refuse — which is the part each call site would
        /// otherwise re-decide.
        static func allows(_ day: Date, ceiling: Date?) -> Bool {
            guard let ceiling = ceiling else { return true }
            return day <= ceiling
        }

        /// The inverse, for call sites that read better as a refusal.
        static func breaches(_ day: Date, ceiling: Date?) -> Bool { !allows(day, ceiling: ceiling) }
    }

    /// A project whose tasks have all inherited a fixed date, and the order the forecast will work
    /// them in. Dates are settled for these — the only thing left to decide is which goes first.
    struct FixedProjectOrder: Equatable {
        let projectID: String
        /// The ceiling every one of these tasks is held under; `nil` when the project has no due date.
        let endDate: Date?
        /// Work order: the day the forecast finishes each task, then its deadline, then its id, so
        /// the sequence is stable across recalculations.
        let taskIDs: [String]
    }

    /// The projects that can no longer be date-rescheduled because their own rating fixes every task
    /// in them. Ordering is all that remains for these, so this is what a rescheduling screen offers
    /// in place of dates. Projects rated flexibly are absent, and so are empty ones.
    static func fixedProjectOrders(in forecast: Result, calendar: Calendar) -> [FixedProjectOrder] {
        let fixed = forecast.projects.filter { !allowsPostponement(outcome: $0.project.outcome) }
        guard !fixed.isEmpty else { return [] }
        let byID = Dictionary(fixed.map { ($0.id, $0.project) }, uniquingKeysWith: { first, _ in first })
        let members = forecast.tasks.filter { task in
            !task.task.completed && task.task.projectID.map { byID[$0] != nil } == true
        }
        let grouped = Dictionary(grouping: members) { $0.task.projectID ?? "" }
        return fixed.compactMap { project in
            guard let rows = grouped[project.id], !rows.isEmpty else { return nil }
            let ordered = rows.sorted { left, right in
                let lf = left.completionDate ?? .distantFuture, rf = right.completionDate ?? .distantFuture
                if lf != rf { return lf < rf }
                let ld = left.task.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
                let rd = right.task.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
                if ld != rd { return ld < rd }
                return left.task.id < right.task.id
            }
            return FixedProjectOrder(projectID: project.id,
                                     endDate: project.project.dueDate.map { calendar.startOfDay(for: $0) },
                                     taskIDs: ordered.map { $0.task.id })
        }
    }

    /// One due date, as the reorder control sees it.
    struct DatedTask: Equatable {
        let id: String
        let dueDate: Date?
    }

    /// Moving a task one place earlier or later within its project swaps its due date with its
    /// neighbour's. A permutation of the dates the project's tasks already hold: no date is
    /// invented, none lands outside the project, and the project's end date cannot be breached
    /// because neither of the two dates breached it. `nil` when there is no neighbour to swap with,
    /// when both hold the same date and the swap would write two no-ops, or when either side has no
    /// due date at all — a swap must never be the thing that clears a task's deadline.
    static func reorder(_ ordered: [DatedTask], moving id: String, earlier: Bool) -> [DatedTask]? {
        guard let index = ordered.firstIndex(where: { $0.id == id }) else { return nil }
        let neighbour = earlier ? index - 1 : index + 1
        guard ordered.indices.contains(neighbour) else { return nil }
        let moved = ordered[index], other = ordered[neighbour]
        guard let movedDate = moved.dueDate, let otherDate = other.dueDate, movedDate != otherDate else { return nil }
        return [DatedTask(id: moved.id, dueDate: otherDate), DatedTask(id: other.id, dueDate: movedDate)]
    }

    /// Whether this outcome leaves any room to push the date back at all. `postponementDays` already
    /// answers it: the top band is granted zero days, so a task rated there simply does not move.
    /// Everything that drops a fixed-date item out of a rescheduling proposal reads this, rather than
    /// testing the wire number itself, so the scale has exactly one place that decides.
    static func allowsPostponement(outcome: Int) -> Bool { postponementDays(outcome: outcome) != 0 }

    /// How far a date rated this way may be pushed BACK. This is the rating's whole job: it resists
    /// a move, it never wins an earlier slot (see `projectPrecedes`).
    ///
    /// The numbers are the /5 wording, literally, and were re-cut with it
    /// (report 2026-09-16_08-52-35) so the planner cannot do something to a task that its own label
    /// does not describe:
    ///
    ///   5/5 `Hard deadline — can't shift`      → 0 days
    ///   4/5 `Can postpone a few days`          → 7
    ///   3/5 `Can postpone a few weeks`         → 21
    ///   2/5 `Can postpone a few months`        → 90
    ///   1/5 `Can postpone a year or more`      → no finite limit ("or more")
    static func postponementDays(outcome: Int) -> Int? {
        switch outcome {
        case 10...: return 0
        case 8...9: return 7
        case 6...7: return 21
        case 4...5: return 90
        default: return nil
        }
    }

    /// Minutes one placed block can still absorb. `key` is nil for a block nothing can be pinned
    /// to, which simply never matches a request.
    private struct BlockBudget {
        let kind: PlacedBlock.Kind
        let key: String?
        var minutes: Double
    }
    private struct DayBudget {
        let capacity: Capacity
        var remainingWork: Double
        var blocks: [BlockBudget]
        /// False for a locked day: it may still finish the work already pinned to it, but the
        /// planner may not move anything else in.
        let acceptsUnplannedWork: Bool
        var allocations: [Allocation] = []
        mutating func consume(key: String, requested: Double) -> Double {
            var consumed: Double = 0
            for index in blocks.indices where blocks[index].key == key {
                let amount = min(blocks[index].minutes, requested - consumed)
                blocks[index].minutes -= amount
                consumed += amount
                if consumed >= requested { break }
            }
            return consumed
        }
    }

    private static func preparedDays(_ days: [DayInput], calendar: Calendar) -> [DayBudget] {
        // Duplicate snapshots for one local date are merged rather than granting another 24 hours.
        let grouped = Dictionary(grouping: days) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted().compactMap { day in
            guard let end = calendar.date(byAdding: .day, value: 1, to: day), let inputs = grouped[day] else { return nil }
            let bounds = Interval(start: min(end, max(day, inputs.compactMap(\.availableFrom).max() ?? day)), end: end)
            let settings = inputs.first?.settings.isValid == true ? inputs[0].settings : CapacitySettings()
            let sleep = sleepIntervals(on: day, settings: settings, calendar: calendar).compactMap { clipped($0, to: bounds) }
            var occupied = union(sleep)
            var budgets: [BlockBudget] = []
            // Events before habits, each charged only for the time nothing ahead of it already
            // holds. Summed, the events come to exactly what the old `union(meetings) - sleep`
            // total came to — the difference is that each one now keeps its own share, which is
            // what a task pinned to it can be absorbed by.
            let placed = unique(inputs.flatMap(\.blocks), id: { $0.id }).sorted {
                if $0.kind != $1.kind { return $0.kind == .meeting }
                if $0.interval.start != $1.interval.start { return $0.interval.start < $1.interval.start }
                return $0.id < $1.id
            }
            for block in placed {
                guard let interval = clipped(block.interval, to: bounds) else { continue }
                let overlap = occupied.compactMap { clipped($0, to: interval) }
                let minutes = max(0, measure([interval]) - measure(union(overlap)))
                budgets.append(BlockBudget(kind: block.kind, key: block.blockKey, minutes: minutes))
                occupied = union(occupied + [interval])
            }
            func minutes(of kind: PlacedBlock.Kind) -> Double {
                budgets.filter { $0.kind == kind }.reduce(0) { $0 + $1.minutes }
            }
            // Self-care is a bare number of minutes rather than a placed interval, so it is taken
            // off the usable total the same way `rawWorkMinutes` takes it off the arithmetic one.
            let usableGaps = measure(gaps(in: bounds, occupied: occupied).filter {
                measure([$0]) >= minimumUsableWorkMinutes
            })
            let capacity = Capacity(day: day, meetingMinutes: minutes(of: .meeting),
                                    habitMinutes: minutes(of: .habit),
                                    sleepMinutes: measure(sleep), selfCareMinutes: Double(settings.selfCareMinutes),
                                    totalMinutes: max(0, end.timeIntervalSince(bounds.start) / 60),
                                    usableWorkMinutes: max(0, usableGaps - Double(settings.selfCareMinutes)))
            return DayBudget(capacity: capacity, remainingWork: capacity.availableWorkMinutes, blocks: budgets,
                             acceptsUnplannedWork: !inputs.contains { $0.isLocked })
        }
    }

    /// Detail rows use the same snapshot bounds and sleep settings as capacity. A calendar
    /// event spanning sleep is split into its awake portions without losing its identity.
    /// Rows still describe individual events: use Capacity's union totals for group summaries.
    static func detailBlocks(_ blocks: [ScheduleBlock], on date: Date,
                             settings: CapacitySettings = .init(), availableFrom: Date? = nil,
                             calendar: Calendar) -> [ScheduleBlock] {
        let day = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: day) else { return [] }
        let bounds = Interval(start: min(end, max(day, availableFrom ?? day)), end: end)
        let validSettings = settings.isValid ? settings : CapacitySettings()
        let sleep = union(sleepIntervals(on: day, settings: validSettings, calendar: calendar))
        return blocks.flatMap { block -> [ScheduleBlock] in
            guard block.kind == .meeting || (block.kind == .habit && !block.didOverflow),
                  let interval = clipped(Interval(start: block.start, end: block.end), to: bounds) else { return [] }
            var portions = [interval]
            if block.kind == .meeting {
                for rest in sleep {
                    portions = portions.flatMap { portion -> [Interval] in
                        guard let overlap = clipped(rest, to: portion) else { return [portion] }
                        var awake: [Interval] = []
                        if portion.start < overlap.start { awake.append(Interval(start: portion.start, end: overlap.start)) }
                        if overlap.end < portion.end { awake.append(Interval(start: overlap.end, end: portion.end)) }
                        return awake
                    }
                }
            }
            return portions.map { portion in
                var row = block
                row.start = portion.start
                row.end = portion.end
                return row
            }
        }
    }

    /// Local wall-clock boundaries preserve seven/nine actual overnight hours at DST changes.
    static func sleepIntervals(on date: Date, settings: CapacitySettings, calendar: Calendar) -> [Interval] {
        let day = calendar.startOfDay(for: date)
        guard settings.isValid, let end = calendar.date(byAdding: .day, value: 1, to: day) else { return [] }
        func clock(_ minutes: Int) -> Date? {
            calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day,
                          matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)
        }
        guard let start = clock(settings.sleepStartMinute), let finish = clock(settings.sleepEndMinute) else { return [] }
        if settings.sleepStartMinute < settings.sleepEndMinute { return [Interval(start: start, end: finish)] }
        return [Interval(start: day, end: finish), Interval(start: start, end: end)]
    }

    /// How many days from today the user's Day Plan is taken as settled: today and tomorrow.
    ///
    /// "Change in rule for reprioritising: assume the day plan for today + tomorrow is locked in"
    /// (report 2026-09-17_09-04-13). Those two days are the ones already being worked, so a plan
    /// that rearranges them is a plan the user cannot act on. Two, not more: locking a week would
    /// leave the planner nowhere to put anything and turn every proposal into a conflict.
    static let lockedPlanDays = 2

    /// Whether `day` falls inside that settled stretch at the start of the horizon.
    ///
    /// `locksPlannedDays` is the user's own answer to "Don't change tasks scheduled for today or
    /// tomorrow" in the reschedule sheet. The rule used to be hardcoded, so a user who *wanted*
    /// their next two days re-planned had no way to say so (report 2026-09-21_07-45-21). It
    /// defaults to on, so nothing changes for anyone who never touches the checkbox.
    ///
    /// One function rather than an index comparison at each call site: the lock has to mean the
    /// same thing to the days the forecast first builds and to the days it re-locks when the
    /// checkbox is toggled. A day before the horizon starts is not locked — it is not planned.
    static func isPlanLocked(_ day: Date, horizonStart: Date, locksPlannedDays: Bool, calendar: Calendar) -> Bool {
        guard locksPlannedDays,
              let offset = calendar.dateComponents([.day], from: calendar.startOfDay(for: horizonStart),
                                                   to: calendar.startOfDay(for: day)).day else { return false }
        return (0..<lockedPlanDays).contains(offset)
    }

    /// Below this a day counts as full: floating-point capacity arithmetic must not leave a day with a
    /// millionth of a minute left looking like somewhere to put work.
    private static let capacityEpsilon = 0.000_001

    private static func estimate(_ task: TaskInput) -> Double? {
        guard let value = task.estimatedMinutes, value.isFinite, value > 0 else { return nil }
        return value
    }
    private static func unique<T>(_ values: [T], id: (T) -> String) -> [T] {
        var seen: Set<String> = []
        return values.filter { seen.insert(id($0)).inserted }
    }
    private static func clipped(_ interval: Interval, to bounds: Interval) -> Interval? {
        let start = max(interval.start, bounds.start), end = min(interval.end, bounds.end)
        return end > start ? Interval(start: start, end: end) : nil
    }
    /// The shortest stretch that counts as time to work in. Anything less is the few minutes
    /// between two meetings, which no task actually gets done in. Ten, not fifteen, by the user's
    /// call: plenty of real to-dos are five- and ten-minute jobs.
    static let minimumUsableWorkMinutes: Double = 10

    /// What is left of `bounds` once every occupied interval is removed.
    static func gaps(in bounds: Interval, occupied: [Interval]) -> [Interval] {
        var result: [Interval] = []
        var cursor = bounds.start
        for interval in union(occupied).compactMap({ clipped($0, to: bounds) }).sorted(by: { $0.start < $1.start }) {
            if interval.start > cursor { result.append(Interval(start: cursor, end: interval.start)) }
            cursor = max(cursor, interval.end)
        }
        if cursor < bounds.end { result.append(Interval(start: cursor, end: bounds.end)) }
        return result
    }

    private static func union(_ intervals: [Interval]) -> [Interval] {
        var result: [Interval] = []
        for interval in intervals.filter({ $0.end > $0.start }).sorted(by: { $0.start < $1.start }) {
            if let previous = result.last, interval.start <= previous.end {
                result[result.count - 1] = Interval(start: previous.start, end: max(previous.end, interval.end))
            } else { result.append(interval) }
        }
        return result
    }
    private static func measure(_ intervals: [Interval]) -> Double {
        intervals.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) / 60 }
    }
    /// Which project's work is done first.
    ///
    /// **Deadline before rating.** A due date says "this must be done by then" and is the only claim
    /// on *when* work happens relative to other projects; a rating says "this is hard to move once
    /// scheduled", which is a claim about postponement, not about urgency. Comparing the rating
    /// first — as this did — let a project with NO due date displace projects with real ones: on the
    /// account this was measured against, UX (rated 8, no due date) sorted ahead of all fourteen
    /// dated-but-unrated projects, including one already overdue, and its tasks were hauled months
    /// forward into their days ("UX has no due date so shouldn't be prioritised ahead of projects
    /// that have due date", report 2026-09-16_06-40-52).
    ///
    /// The rating is kept only as a tie-break, where it cannot take a day from a nearer deadline:
    /// between two projects due the same day, the one the user said is harder to move goes first.
    /// Its real job is elsewhere — `postponementDays` caps how far a date may be pushed back, which
    /// is what "hard to move" actually means.
    private static func projectPrecedes(_ left: ProjectInput, _ right: ProjectInput, calendar: Calendar) -> Bool {
        let ld = left.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
        let rd = right.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
        if ld != rd { return ld < rd }
        if left.outcome != right.outcome { return left.outcome > right.outcome }
        return left.id < right.id
    }
    private static func precedes(_ left: TaskInput, _ right: TaskInput,
                                 projects: [String: ProjectInput], calendar: Calendar) -> Bool {
        // Unprojected tasks act as individual projects using their own outcome/deadline. They
        // compete for the same hours instead of disappearing from portfolio capacity.
        let lp = left.projectID.flatMap { projects[$0] } ?? ProjectInput(id: "unprojected", outcome: left.outcome, dueDate: left.dueDate)
        let rp = right.projectID.flatMap { projects[$0] } ?? ProjectInput(id: "unprojected", outcome: right.outcome, dueDate: right.dueDate)
        if lp.id != rp.id { return projectPrecedes(lp, rp, calendar: calendar) }
        // Deadline before rating here too, for the same reason: within one project, the task due
        // soonest is the one to do first, and a task being hard to move is not a reason to take a
        // day from a task that is due sooner. The rating still breaks ties between tasks due the
        // same day, which is where "harder to move, so schedule it while there is room" is true.
        let ld = left.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
        let rd = right.dueDate.map { calendar.startOfDay(for: $0) } ?? .distantFuture
        if ld != rd { return ld < rd }
        if left.outcome != right.outcome { return left.outcome > right.outcome }
        if left.perspiration != right.perspiration { return left.perspiration < right.perspiration }
        return left.id < right.id
    }
}
