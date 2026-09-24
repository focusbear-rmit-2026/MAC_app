@testable import Focus_Bear
import XCTest

/// The reschedule screen (`ForecastReschedulePlanSheet`): the project each proposed move belongs to,
/// the per-row deadline-flexibility control, and what pinning a task to a fixed date does to the
/// list (report 2026-09-15_21-00-07).
final class ForecastReschedulingTests: XCTestCase {
    private typealias Forecast = LocalTimeForecast

    // MARK: The 1-5 control and the /10 wire value behind it

    func testOutcomeSliderStepsMapOntoTheUnchangedWireScale() {
        for step in 1...ToDoScoring.outcomeSteps {
            let wire = step * ToDoScoring.outcomeWireFactor
            XCTAssertEqual(ForecastOutcomeSlider.displayStep(forWire: wire), step,
                           "Step \(step) must survive the round trip through its wire value")
        }
        XCTAssertEqual(ForecastOutcomeSlider.displayStep(forWire: 10), ToDoScoring.outcomeSteps)
        // Legacy odd values round to the nearest step instead of silently reading as the one below.
        XCTAssertEqual(ForecastOutcomeSlider.displayStep(forWire: 5), 3)
        XCTAssertEqual(ForecastOutcomeSlider.displayStep(forWire: 7), 4)
        // An unrated task shows what the forecast actually planned it with, not an invented middle.
        XCTAssertEqual(ForecastOutcomeSlider.displayStep(forWire: nil),
                       ForecastOutcomeSlider.displayStep(forWire: Forecast.TaskInput.unratedOutcome))
        XCTAssertEqual(ForecastOutcomeSlider.displayStep(forWire: 0), 1)
        XCTAssertEqual(ForecastOutcomeSlider.displayStep(forWire: 99), ToDoScoring.outcomeSteps)
    }

    /// The scale is a SHIFTABILITY scale, and its five rungs and five day-allowances are one thing:
    /// every label says how far the item may be pushed back, and `postponementDays` must grant
    /// exactly that (report 2026-09-16_08-52-35). If these two ever disagree, the planner is doing
    /// something to a task that its own label does not describe.
    func testEachRungsWordsAndItsDayAllowanceAgree() {
        let strings = ToDoStrings.load()
        let expected: [(step: Int, days: Int?, key: ToDoStringKey)] = [
            (5, 0, .outcomeBand5), (4, 7, .outcomeBand4), (3, 21, .outcomeBand3),
            (2, 90, .outcomeBand2), (1, nil, .outcomeBand1),
        ]
        for rung in expected {
            let wire = rung.step * ToDoScoring.outcomeWireFactor
            XCTAssertEqual(Forecast.postponementDays(outcome: wire), rung.days,
                           "Rung \(rung.step) grants the slack its words promise")
            XCTAssertEqual(strings.outcomeLabel(wire), strings[rung.key],
                           "Rung \(rung.step) reads from its own token")
        }
        // Direction: 5 is the strict end, 1 the loosest — nothing inverted.
        XCTAssertEqual(Forecast.postponementDays(outcome: 10), 0)
        XCTAssertNil(Forecast.postponementDays(outcome: 2))
        for wire in 1...9 {
            XCTAssertTrue(Forecast.allowsPostponement(outcome: wire), "wire \(wire) may still move")
        }
        XCTAssertFalse(Forecast.allowsPostponement(outcome: 10), "Only the top rung cannot shift")
    }

    func testTheFiveRungsReadFromOneTokenisedSourceAndSayShift() {
        let strings = ToDoStrings.load()
        let words = (1...ToDoScoring.outcomeSteps).map { strings.outcomeLabel($0 * ToDoScoring.outcomeWireFactor) }
        XCTAssertEqual(Set(words).count, ToDoScoring.outcomeSteps, "Five rungs, five distinct words")
        XCTAssertTrue(words.allSatisfy { !$0.isEmpty })
        // Every rung is phrased as how far it can be pushed back — that is what makes it a
        // shiftability scale rather than an urgency one.
        XCTAssertTrue(words.dropLast().allSatisfy { $0.lowercased().contains("postpone") },
                      "Rungs 1-4 say how far they can be postponed")
        XCTAssertTrue(words.last?.lowercased().contains("shift") == true,
                      "The top rung says it can't shift")
        // The picker composes its rows from the same one definition.
        XCTAssertEqual(strings.outcomeOptionLabel(displayValue: 4), "4 / 5 · " + words[3])
    }

    // MARK: A fixed date takes the row off the list, and the rest re-flows

    func testFixedDateLeavesTheListBecausePostponementIsZeroAndTheRestReflows() {
        let pinned = Forecast.TaskInput(id: "pinned", projectID: "p", estimatedMinutes: 30, outcome: 6, dueDate: date(7))
        let other = Forecast.TaskInput(id: "other", projectID: "p", estimatedMinutes: 30, outcome: 8, dueDate: date(7))
        let project = Forecast.ProjectInput(id: "p", outcome: 6, dueDate: date(30))

        let before = plan(tasks: [pinned, other], project: project)
        XCTAssertEqual(proposal(before, "pinned"), date(9), "The lower-rated task starts out proposed for the later day")
        XCTAssertEqual(proposal(before, "other"), date(8))

        var fixed = pinned
        fixed.outcome = 10
        let after = plan(tasks: [fixed, other], project: project)
        XCTAssertNil(proposal(after, "pinned"), "A task that may not be postponed has no move to propose")
        XCTAssertFalse(after.reviewableConflicts.contains { $0.itemID == "pinned" },
                       "Its own fixed date is not a conflict to review, so the row leaves the screen entirely")
        // It no longer records a `.hardDeadline` conflict either, and that is the improvement: a 5 is
        // now placed on its OWN due day (report 2026-09-16_09-40-20), so its finish equals its due
        // date and there is nothing to refuse. Previously it was allocated to whichever day had room
        // and the plan had to explain why it would not move it there.
        XCTAssertFalse(after.conflicts.contains { $0.itemID == "pinned" },
                       "Nothing to refuse: the task is already on the day it is due")
        // …and the rest re-flows BETTER: the pinned task no longer occupies day 8, which it was never
        // really on, so `other` gets it.
        XCTAssertEqual(proposal(after, "other"), date(8), "Pinning one task frees the days it was borrowing")
    }

    func testEveryOtherConflictStillReachesTheScreen() {
        // The unrated task is deliberately unprojected. A task inside a rated project is no longer
        // unrated — it inherits the project's rating (`effectiveOutcome`), which is the point of the
        // inheritance rule: the project has already answered how flexible this work is, so blocking
        // the reschedule over a missing per-task rating would be noise. "Rate this" is therefore
        // only asked of work no project speaks for.
        let unrated = Forecast.TaskInput(id: "unrated", estimatedMinutes: 30, outcome: 0, dueDate: date(7))
        let tooFar = Forecast.TaskInput(id: "too-far", projectID: "q", estimatedMinutes: 30, outcome: 8, dueDate: date(7))
        let result = Forecast.calculate(days: [day(7, workMinutes: 0), day(8, workMinutes: 0), day(9, workMinutes: 0),
                                               day(90, workMinutes: 30), day(91, workMinutes: 30)],
                                        // An end date past the far end of the horizon, so this test
                                        // asks only about the flexibility bands. The project
                                        // end-date ceiling has its own tests below.
                                        projects: [.init(id: "q", outcome: 8, dueDate: date(31, month: 12))],
                                        tasks: [unrated, tooFar], calendar: calendar)
        let reviewable = Forecast.proposeWorkPlan(result, calendar: calendar).reviewableConflicts
        XCTAssertTrue(reviewable.contains { $0.itemID == "unrated" && $0.reason == .missingOutcome })
        XCTAssertTrue(reviewable.contains { $0.itemID == "too-far" && $0.reason == .postponementLimit })
    }

    func testAnUnratedTaskInsideARatedProjectInheritsInsteadOfAskingToBeRated() {
        let unrated = Forecast.TaskInput(id: "unrated", projectID: "p", estimatedMinutes: 30, outcome: 0, dueDate: date(7))
        let plan = self.plan(tasks: [unrated], project: .init(id: "p", outcome: 4, dueDate: date(30)))
        XCTAssertFalse(plan.conflicts.contains { $0.reason == .missingOutcome },
                       "The project's rating answers the question the task left unanswered")
        XCTAssertEqual(proposal(plan, "unrated"), date(8))
    }

    // MARK: The store — project chips, persistence, and the list re-flowing around the edit

    func testRowNamesItsProjectAndDegradesWithoutOne() throws {
        let store = try loadedStore()
        XCTAssertEqual(store.projectChipName(forTaskID: "overdue"), "Alpha")
        XCTAssertNil(store.projectChipName(forTaskID: "not-in-this-snapshot"),
                     "A task with no project shows no chip rather than an empty one")
        let projectRow = Forecast.DueDateChange(kind: .project, itemID: "alpha", previousDate: nil, proposedDate: Date())
        XCTAssertNil(store.projectChipName(for: projectRow), "A project row is already named by its own title")
        let taskRow = Forecast.DueDateChange(kind: .task, itemID: "overdue", previousDate: nil, proposedDate: Date())
        XCTAssertEqual(store.projectChipName(for: taskRow), "Alpha")
    }

    func testFixedDateEditPersistsTheOutcomeForAnOverdueTaskAlreadyOnToday() throws {
        var written: [(id: String, outcome: Int, account: String)] = []
        let store = try loadedStore { id, outcome, account, done in
            written.append((id, outcome, account)); done(true)
        }
        store.prepareWorkPlan()
        XCTAssertFalse(try XCTUnwrap(store.workPlan).changes.contains { $0.itemID == "overdue" },
                       "An overdue task already appears on today's locked plan without a date correction")

        let hardDeadline = ToDoScoring.outcomeSteps * ToDoScoring.outcomeWireFactor
        store.setTaskOutcome(hardDeadline, forTaskID: "overdue")
        drainCallbacks()

        XCTAssertEqual(written.count, 1)
        XCTAssertEqual(written.first?.id, "overdue")
        XCTAssertEqual(written.first?.outcome, hardDeadline, "The /5 step is written as its /10 wire value")
        XCTAssertEqual(written.first?.account, "test-account")
        XCTAssertEqual(store.outcome(forTaskID: "overdue"), hardDeadline)
        let plan = try XCTUnwrap(store.workPlan)
        XCTAssertFalse(plan.changes.contains { $0.itemID == "overdue" }, "The pinned row leaves the proposal list")
        XCTAssertFalse(plan.reviewableConflicts.contains { $0.itemID == "overdue" }, "…and does not reappear as a conflict")
        XCTAssertNil(store.applyMessage)
    }

    func testRejectedOutcomeWriteRestoresTheRowAndSaysSo() throws {
        let store = try loadedStore { _, _, _, done in done(false) }
        store.prepareWorkPlan()
        let before = store.outcome(forTaskID: "overdue")
        let priorChanges = try XCTUnwrap(store.workPlan).changes.map(\.id)
        store.setTaskOutcome(ToDoScoring.outcomeSteps * ToDoScoring.outcomeWireFactor, forTaskID: "overdue")
        drainCallbacks()
        XCTAssertEqual(store.outcome(forTaskID: "overdue"), before, "A refused write leaves the task as it was")
        XCTAssertEqual(try XCTUnwrap(store.workPlan).changes.map(\.id), priorChanges)
        XCTAssertEqual(store.applyMessage, ForecastText[.outcomeNotSaved])
    }

    // MARK: The bug — "I tried rescheduling some but it didn't work"
    //
    // THE regression test of this set. The reschedule sheet re-read each row before writing it and
    // compared `updated_at` with the reviewed copy. The reviewed copy comes from the LIST endpoint,
    // whose serialisation has no `updated_at` at all, while the re-read comes from `/to-do/by-ids`,
    // whose serialisation does — so the comparison was a real timestamp against a permanent nil, it
    // never matched, the loop aborted at index 0 and no `PUT /to-do` was ever sent.

    func testAWriteIsNotRefusedJustBecauseTheReviewedRowCameFromAnEndpointWithoutUpdatedAt() throws {
        let previous = try listRow()
        let latest = try byIDsRow()
        XCTAssertNil(previous.updated_at, "The list serialisation this screen reviews carries no updated_at")
        XCTAssertNotNil(latest.updated_at, "The per-id serialisation it re-reads does")
        XCTAssertNil(ForecastRowGuard.refusal(latest: latest, previous: previous),
                     "An unchanged row must be writable even though only one of the two payloads dates it")
    }

    func testTheGuardStillRefusesARowThatMovedUnderTheReview() throws {
        var edited = try byIDsRow()
        edited.due_date = "2026-10-01T14:00:00.000Z"
        XCTAssertEqual(ForecastRowGuard.refusal(latest: edited, previous: try listRow()), .editedElsewhere,
                       "A due date changed elsewhere is exactly what this guard exists to catch")

        var renamed = try byIDsRow()
        renamed.title = "Renamed elsewhere"
        XCTAssertEqual(ForecastRowGuard.refusal(latest: renamed, previous: try listRow()), .editedElsewhere)

        var finished = try byIDsRow()
        finished.status = "COMPLETED"
        XCTAssertEqual(ForecastRowGuard.refusal(latest: finished, previous: try listRow()), .editedElsewhere)

        // And when BOTH payloads do date the row, a newer timestamp is still a refusal.
        var dated = try listRow()
        dated.updated_at = "2026-09-01T00:00:00.000Z"
        XCTAssertEqual(ForecastRowGuard.refusal(latest: try byIDsRow(), previous: dated), .editedElsewhere)

        XCTAssertEqual(ForecastRowGuard.refusal(latest: nil, previous: try listRow()), .missingRow)
        XCTAssertEqual(ForecastRowGuard.refusal(latest: try byIDsRow(), previous: nil), .unknownToSnapshot)
    }

    // MARK: A project's importance reaches its tasks

    func testATaskPlansUnderTheStrongerOfItsOwnRatingAndItsProjects() {
        let relaxed = Forecast.TaskInput(id: "t", projectID: "p", outcome: 4)
        XCTAssertEqual(Forecast.effectiveOutcome(task: relaxed, project: .init(id: "p", outcome: 10)), 10,
                       "A hard-deadline project is inherited by every task in it")
        XCTAssertTrue(Forecast.inheritsProjectOutcome(task: relaxed, project: .init(id: "p", outcome: 10)))

        let pinned = Forecast.TaskInput(id: "t", projectID: "p", outcome: 10)
        XCTAssertEqual(Forecast.effectiveOutcome(task: pinned, project: .init(id: "p", outcome: 2)), 10,
                       "A relaxed project never loosens a deadline the user pinned themselves")
        XCTAssertFalse(Forecast.inheritsProjectOutcome(task: pinned, project: .init(id: "p", outcome: 2)))

        let unprojected = Forecast.TaskInput(id: "t", outcome: 4)
        XCTAssertEqual(Forecast.effectiveOutcome(task: unprojected, project: nil), 4)
        XCTAssertFalse(Forecast.inheritsProjectOutcome(task: unprojected, project: nil))
    }

    /// The regression behind "why does it say deadline set by project? UX has no deadline. These
    /// tasks definitely aren't urgent" (report 2026-09-16_06-40-52). An UNRATED project must
    /// contribute nothing — it is the overwhelmingly common case (130 of the 131 projects on the
    /// account this was measured against carry `outcome: null`), and a project with no opinion
    /// reading as a claim would pull tasks out of rescheduling and call them urgent.
    ///
    /// `ProjectInput.outcome` defaults to `2`, so this is pinned deliberately rather than left to
    /// `max`: a call site that omits the argument must not turn every unrated project into a claim.
    func testAnUnratedProjectNeverRaisesATasksEffectiveOutcome() {
        let task = Forecast.TaskInput(id: "t", projectID: "p", outcome: 1)
        // 0 is what the store maps the server's `outcome: null` to.
        let unrated = Forecast.ProjectInput(id: "p", outcome: 0)
        XCTAssertFalse(unrated.hasRating)
        XCTAssertEqual(Forecast.effectiveOutcome(task: task, project: unrated), 1,
                       "An unrated project has no opinion and must not raise its tasks")
        XCTAssertFalse(Forecast.inheritsProjectOutcome(task: task, project: unrated),
                       "…and must not be credited with setting the task's rating")
        // A negative or absurd value is still "no rating", never a claim.
        XCTAssertEqual(Forecast.effectiveOutcome(task: task, project: .init(id: "p", outcome: -5)), 1)
        XCTAssertFalse(Forecast.ProjectInput(id: "p", outcome: -5).hasRating)
    }

    func testAnUnratedProjectDoesNotInventACorrectionForWorkAlreadyDueToday() throws {
        let store = try loadedStore()
        // The fixture's project carries no outcome, exactly like 130 of the 131 real ones.
        store.prepareWorkPlan()
        XCTAssertFalse(try XCTUnwrap(store.workPlan).changes.contains { $0.itemID == "overdue" },
                       "Overdue work is already visible today without a separate placement correction")
        XCTAssertNil(store.inheritedOutcome(forTaskID: "overdue"),
                     "…and no row may claim the project set its rating")
        XCTAssertTrue(store.fixedProjectOrders.isEmpty,
                      "…nor may an unrated project appear as one that has fixed its tasks")
    }

    /// The wording the PO objected to. A project's *rating* and a project's *end date* are two
    /// different claims; this note is about the rating, so it must not call it a deadline.
    func testTheInheritedRatingNoteNamesTheRatingAndNotADeadline() {
        let note = ForecastText.format(.inheritedFromProject, ["<PROJECT>": "UX", "<OUTCOME>": "4 / 5"])
        XCTAssertTrue(note.contains("UX"), "It names the project whose rating is in force")
        XCTAssertTrue(note.contains("4 / 5"), "…and the rating the plan is actually using")
        XCTAssertFalse(note.lowercased().contains("deadline"),
                       "A project with no due date has no deadline to set — saying so was the bug")
    }

    // MARK: A rating is not a deadline — it must not compete for earlier slots

    /// The regression behind "Same issue - UX has no due date so shouldn't be prioritised ahead of
    /// projects that have due date" (report 2026-09-16_06-40-52, follow-up).
    ///
    /// The ordering compared a project's RATING before its due date, so a project with no due date
    /// at all sorted ahead of every project that had one. Measured on the real account: of 129
    /// projects exactly two carried a rating, and UX — rated 8 with `due_date: null` — outranked all
    /// fourteen dated-but-unrated projects, one of them already overdue, hauling its tasks months
    /// forward into their days.
    func testAnUndatedProjectNeverOutranksOneWithARealDeadline() {
        let undatedButRated = Forecast.ProjectInput(id: "ux", outcome: 8, dueDate: nil)
        let datedAndUnrated = Forecast.ProjectInput(id: "mrff", outcome: 0, dueDate: date(18))
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 30), day(9, workMinutes: 30)]
        let tasks = [
            Forecast.TaskInput(id: "ux-task", projectID: "ux", estimatedMinutes: 30, outcome: 6, dueDate: date(30)),
            Forecast.TaskInput(id: "mrff-task", projectID: "mrff", estimatedMinutes: 30, outcome: 1, dueDate: date(30)),
        ]
        let result = Forecast.calculate(days: days, projects: [undatedButRated, datedAndUnrated],
                                        tasks: tasks, calendar: calendar)
        XCTAssertEqual(completion(result, "mrff-task"), date(8),
                       "The project with a real deadline gets the first day it can work in")
        XCTAssertEqual(completion(result, "ux-task"), date(9),
                       "A rating is not deadline pressure, so an undated project waits its turn")
    }

    func testDeadlineOrderIsNotDisturbedByRatingsAcrossSeveralProjects() {
        let days = (7...11).map { day($0, workMinutes: $0 == 7 ? 0 : 30) }
        let projects = [
            Forecast.ProjectInput(id: "undated-high", outcome: 10, dueDate: nil),
            Forecast.ProjectInput(id: "soon", outcome: 0, dueDate: date(18)),
            Forecast.ProjectInput(id: "later", outcome: 0, dueDate: date(25)),
        ]
        let tasks = projects.map {
            Forecast.TaskInput(id: $0.id + "-task", projectID: $0.id, estimatedMinutes: 30, outcome: 1, dueDate: date(30))
        }
        let result = Forecast.calculate(days: days, projects: projects, tasks: tasks, calendar: calendar)
        let order = result.tasks.compactMap { row in row.completionDate.map { ($0, row.task.id) } }
            .sorted { $0.0 < $1.0 }.map { $0.1 }
        XCTAssertEqual(order, ["soon-task", "later-task", "undated-high-task"],
                       "Deadlines decide the order; the undated project goes last however it is rated")
    }

    func testRatingStillBreaksTiesBetweenProjectsSharingADeadline() {
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 30), day(9, workMinutes: 30)]
        let projects = [Forecast.ProjectInput(id: "relaxed", outcome: 2, dueDate: date(18)),
                        Forecast.ProjectInput(id: "firm", outcome: 8, dueDate: date(18))]
        let tasks = projects.map {
            Forecast.TaskInput(id: $0.id + "-task", projectID: $0.id, estimatedMinutes: 30, outcome: 1, dueDate: date(30))
        }
        let result = Forecast.calculate(days: days, projects: projects, tasks: tasks, calendar: calendar)
        XCTAssertEqual(completion(result, "firm-task"), date(8),
                       "Between two projects due the same day, the harder-to-move one goes first")
        XCTAssertEqual(completion(result, "relaxed-task"), date(9))
    }

    func testWithinAProjectTheTaskDueSoonestIsWorkedFirst() {
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 30), day(9, workMinutes: 30)]
        let tasks = [
            Forecast.TaskInput(id: "hard-but-later", projectID: "p", estimatedMinutes: 30, outcome: 8, dueDate: date(25)),
            Forecast.TaskInput(id: "due-sooner", projectID: "p", estimatedMinutes: 30, outcome: 1, dueDate: date(18)),
        ]
        let result = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 0, dueDate: date(31, month: 12))],
                                        tasks: tasks, calendar: calendar)
        XCTAssertEqual(completion(result, "due-sooner"), date(8),
                       "Being hard to move is not a reason to take a day from a task due sooner")
        XCTAssertEqual(completion(result, "hard-but-later"), date(9))
    }

    /// The rating's legitimate job, deliberately left alone: it caps how far a date may be pushed
    /// BACK. That is what "hard to move once scheduled" actually means.
    func testTheRatingStillGovernsHowFarADateMayBePushedBack() {
        XCTAssertEqual(Forecast.postponementDays(outcome: 10), 0)
        XCTAssertEqual(Forecast.postponementDays(outcome: 8), 7)
        let tooFar = Forecast.TaskInput(id: "too-far", projectID: "q", estimatedMinutes: 30, outcome: 8, dueDate: date(7))
        let result = Forecast.calculate(days: [day(7, workMinutes: 0), day(90, workMinutes: 30)],
                                        projects: [.init(id: "q", outcome: 0, dueDate: date(31, month: 12))],
                                        tasks: [tooFar], calendar: calendar)
        XCTAssertTrue(Forecast.proposeWorkPlan(result, calendar: calendar)
            .reviewableConflicts.contains { $0.itemID == "too-far" && $0.reason == .postponementLimit },
                      "A rating still refuses a push beyond its band — that is what it is for")
    }

    // MARK: The project-level fact is said once per group, not once per row

    func testChangesGroupByProjectInThePlansOwnOrder() {
        let changes = [
            change(.task, "ux-1"), change(.task, "mrff-1"), change(.task, "ux-2"),
            change(.project, "mrff"), change(.task, "loose"),
        ]
        let owners = ["ux-1": "ux", "ux-2": "ux", "mrff-1": "mrff"]
        let groups = ForecastChangeGrouping.groups(changes, taskProjectID: { owners[$0] })
        XCTAssertEqual(groups.map(\.id), ["ux", "mrff", "__unprojected"],
                       "Each project appears where its first row did, so the list still reads top to bottom")
        XCTAssertEqual(groups[0].changes.map(\.itemID), ["ux-1", "ux-2"])
        XCTAssertEqual(groups[1].changes.map(\.itemID), ["mrff-1", "mrff"],
                       "A project's own row joins its tasks rather than heading a group of one")
        XCTAssertEqual(groups[2].changes.map(\.itemID), ["loose"])
        XCTAssertNil(groups[2].projectID, "A row with no project still has somewhere to go")
    }

    func testTheProjectNoteIsAskedForOncePerGroupNotOncePerRow() throws {
        let store = try loadedStore()
        XCTAssertNil(store.inheritedOutcome(inProject: "alpha", taskIDs: ["overdue"]),
                     "An unrated project contributes no note for the group either")
        let groups = ForecastChangeGrouping.groups([change(.task, "overdue")],
                                                   taskProjectID: { store.projectID(forTaskID: $0) })
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.projectID, "alpha", "The row's project is named once, by its group")
    }

    // MARK: A dirty snapshot is reloaded, not reused

    /// "I added a new project on the projects screen and then clicked reschedule tasks and tried to
    /// change this task to the new project but it wasn't there" (report 2026-09-16_08-53-08).
    ///
    /// `markDirty` only *schedules* a recalculation while the snapshot is inside its fifteen-minute
    /// window, so a project created moments earlier was still missing from `projects` — and the
    /// row's picker lists exactly that. Opening the plan is a deliberate action and must read fresh.
    func testOpeningThePlanAfterAnEditReloadsInsteadOfServingTheStaleSnapshot() throws {
        var projectPages = 0
        let store = try loadedStore(onProjectsPage: { projectPages += 1 })
        let loadsAfterFirstSnapshot = projectPages
        XCTAssertTrue(store.hasCurrentSnapshot)

        // Nothing has changed: the warm snapshot is reused and nothing is refetched.
        store.prepareWorkPlanLoadingIfNeeded()
        XCTAssertEqual(projectPages, loadsAfterFirstSnapshot, "A clean snapshot is reused")
        XCTAssertNotNil(store.workPlan)
        store.showsWorkPlan = false

        // Something changed — a project was created — so the next open must go back to the server.
        store.markDirty()
        XCTAssertTrue(store.isSnapshotDirty)
        store.prepareWorkPlanLoadingIfNeeded()
        drainCallbacks()
        XCTAssertGreaterThan(projectPages, loadsAfterFirstSnapshot,
                             "A dirty snapshot is reloaded, so a project created moments ago is in the picker")
        XCTAssertTrue(store.showsWorkPlan, "…and the sheet opens straight away rather than waiting for the load")
    }

    func testThePickerOffersEveryProjectTheSnapshotKnows() throws {
        let store = try loadedStore()
        XCTAssertEqual(store.projectPickerOptions.map(\.id), ["alpha"])
        XCTAssertEqual(store.projectPickerOptions.map(\.name), ["Alpha"])
        XCTAssertEqual(store.projectID(forTaskID: "overdue"), "alpha")
    }

    // MARK: Row actions — duration and complete

    /// One parser for one syntax. The Day Plan's duration field reads the same strings through the
    /// same call; a second parser is how `4h` once became `4`.
    func testTheDurationBadgeReadsTheSameSyntaxAsTheDayPlanField() {
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "45m"), 45)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "1h30"), 90)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "2h"), 120)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "45"), 45, "A bare number is minutes")
        XCTAssertNil(QuickAddTaskParser.durationMinutes(fromFieldText: "  "))
        // And the badge renders through the same helper, so what it shows round-trips.
        for minutes in [45, 90, 120] {
            XCTAssertEqual(QuickAddTaskParser.durationMinutes(
                fromFieldText: QuickAddTaskParser.durationLabel(minutes)), minutes,
                "\(minutes) survives label → parse")
        }
    }

    func testTheRowShowsTheEstimateItHasAndSaysSoWhenItHasNone() throws {
        let store = try loadedStore()
        XCTAssertEqual(store.durationMinutes(forTaskID: "overdue"), 1, "The fixture's 60s estimate reads as a minute")
        XCTAssertNil(store.durationMinutes(forTaskID: "not-in-this-snapshot"))
        XCTAssertFalse(ForecastText[.noEstimate].isEmpty, "A task with no estimate says so rather than showing 0m")
    }

    /// Completing a task takes it out of the plan: finished work is not work to schedule, and the
    /// days it was holding are freed for the rest.
    func testACompletedTaskLeavesThePlan() {
        var done = Forecast.TaskInput(id: "done", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(7))
        let other = Forecast.TaskInput(id: "other", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(7))
        let before = plan(tasks: [done, other], project: .init(id: "p", outcome: 0, dueDate: date(30)))
        XCTAssertNotNil(proposal(before, "done"))
        XCTAssertEqual(proposal(before, "other"), date(9))

        done.completed = true
        let after = plan(tasks: [done, other], project: .init(id: "p", outcome: 0, dueDate: date(30)))
        XCTAssertNil(proposal(after, "done"), "A finished task has no move to propose")
        XCTAssertFalse(after.conflicts.contains { $0.itemID == "done" }, "…and is not a problem to review either")
        XCTAssertEqual(proposal(after, "other"), date(8), "The day it was holding is freed for the rest")
    }

    // MARK: A 5 cannot shift — in either direction

    /// "It's a hard deadline - means it probably shouldn't change" (report 2026-09-16_09-40-20).
    ///
    /// The guard sat inside the "is this a postponement?" branch, so the top rung was immovable
    /// backwards and freely movable FORWARDS — a task pinned to the 18th was proposed for the 16th.
    /// "Can't shift" has to mean both directions.
    func testAHardDeadlineIsNotPulledForwardEither() {
        let pinned = Forecast.TaskInput(id: "pinned", projectID: "p", estimatedMinutes: 30, outcome: 10, dueDate: date(18))
        let other = Forecast.TaskInput(id: "other", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(18))
        let plan = self.plan(tasks: [pinned, other], project: .init(id: "p", outcome: 0, dueDate: date(30)))

        XCTAssertNil(proposal(plan, "pinned"), "A 5 must not be pulled forward any more than pushed back")
        XCTAssertTrue(plan.conflicts.contains { $0.itemID == "pinned" && $0.reason == .hardDeadline },
                      "…and the forecast records that it refused")
        XCTAssertNotNil(proposal(plan, "other"), "Every other rung may still be brought forward")
    }

    func testBringingForwardStillWorksForEveryOtherRung() {
        for wire in [1, 4, 6, 8] {
            let movable = Forecast.TaskInput(id: "t", projectID: "p", estimatedMinutes: 30, outcome: wire, dueDate: date(18))
            XCTAssertNotNil(proposal(plan(tasks: [movable], project: .init(id: "p", outcome: 0, dueDate: date(30))), "t"),
                            "wire \(wire) may be brought forward")
        }
        let fixed = Forecast.TaskInput(id: "t", projectID: "p", estimatedMinutes: 30, outcome: 10, dueDate: date(18))
        XCTAssertNil(proposal(plan(tasks: [fixed], project: .init(id: "p", outcome: 0, dueDate: date(30))), "t"))
    }

    // MARK: A 5 reserves the capacity it is already using

    /// The PO's decision on report 2026-09-16_09-40-20: "It shouldn't move hard deadline tasks from
    /// their current position in the day plan. It should calculate capacity subtracting the tasks
    /// with 5." A day holding hard-deadline work must offer that much less to everything else.
    func testADayHoldingAHardDeadlineOffersLessToEverythingElse() {
        let days = [day(8, workMinutes: 60)]
        let filler = Forecast.TaskInput(id: "filler", projectID: "p", estimatedMinutes: 60, outcome: 4, dueDate: date(7))
        let project = Forecast.ProjectInput(id: "p", outcome: 0, dueDate: date(30))

        let withoutFixed = Forecast.calculate(days: days, projects: [project], tasks: [filler], calendar: calendar)
        XCTAssertEqual(allocated(withoutFixed, "filler", on: date(8)), 60, "The whole hour is available")

        // The same day, with 45 minutes of hard-deadline work sitting on it.
        let pinned = Forecast.TaskInput(id: "pinned", projectID: "p", estimatedMinutes: 45, outcome: 10, dueDate: date(8))
        let withFixed = Forecast.calculate(days: days, projects: [project], tasks: [filler, pinned], calendar: calendar)
        XCTAssertEqual(allocated(withFixed, "pinned", on: date(8)), 45, "The 5 keeps its own day")
        XCTAssertEqual(allocated(withFixed, "filler", on: date(8)), 15,
                       "…and the day offers exactly 45 minutes less to everything else")
    }

    /// The reservation must read the EFFECTIVE outcome. A task inheriting 5 from its project has to
    /// reserve exactly as an explicitly-rated one does, or the bug returns by another route.
    func testAnInheritedHardDeadlineReservesExactlyAsAnExplicitOneDoes() {
        let days = [day(8, workMinutes: 60)]
        let filler = Forecast.TaskInput(id: "filler", estimatedMinutes: 60, outcome: 4, dueDate: date(7))

        let explicit = Forecast.TaskInput(id: "fixed", projectID: "p", estimatedMinutes: 45, outcome: 10, dueDate: date(8))
        let byExplicit = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 0, dueDate: date(30))],
                                            tasks: [filler, explicit], calendar: calendar)

        // Same task rated 1, inside a project rated 5.
        let inherited = Forecast.TaskInput(id: "fixed", projectID: "p", estimatedMinutes: 45, outcome: 1, dueDate: date(8))
        let byInheritance = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 10, dueDate: date(30))],
                                               tasks: [filler, inherited], calendar: calendar)

        XCTAssertEqual(allocated(byInheritance, "fixed", on: date(8)), 45)
        XCTAssertEqual(allocated(byInheritance, "filler", on: date(8)),
                       allocated(byExplicit, "filler", on: date(8)),
                       "An inherited 5 reserves exactly what an explicit 5 reserves")
    }

    func testADayWhoseHardDeadlineWorkExceedsItsCapacityOffersZeroNotNegative() {
        let days = [day(8, workMinutes: 30), day(9, workMinutes: 60)]
        let oversized = Forecast.TaskInput(id: "oversized", projectID: "p", estimatedMinutes: 120, outcome: 10, dueDate: date(8))
        let other = Forecast.TaskInput(id: "other", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(7))
        let result = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 0, dueDate: date(30))],
                                        tasks: [oversized, other], calendar: calendar)

        XCTAssertEqual(allocated(result, "other", on: date(8)), 0, "Nothing else fits on a day already over-spent")
        XCTAssertEqual(allocated(result, "other", on: date(9)), 30, "It goes to the next day with room")
        let eighth = result.days.first { calendar.isDate($0.date, inSameDayAs: date(8)) }
        XCTAssertEqual(eighth?.remainingWorkMinutes, 0, "Remaining capacity floors at zero, never negative")
        // And the day is visibly over capacity rather than silently refusing slots while looking free.
        let load = Forecast.dayLoad(on: date(8), forecast: result, calendar: calendar)
        XCTAssertEqual(load?.overcommittedMinutes, 90)
        XCTAssertTrue(load?.isOvercommitted == true)
        XCTAssertEqual((load?.committedMinutes ?? 0) + (load?.bufferMinutes ?? 0), load?.capacityMinutes,
                       "planned + buffer = capacity still holds")
    }

    func testAHardDeadlinesProposedDateAlwaysEqualsItsCurrentDate() {
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 60), day(9, workMinutes: 60)]
        for dueDay in [8, 9] {
            let pinned = Forecast.TaskInput(id: "pinned", projectID: "p", estimatedMinutes: 30, outcome: 10, dueDate: date(dueDay))
            let result = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 0, dueDate: date(30))],
                                            tasks: [pinned], calendar: calendar)
            XCTAssertEqual(completion(result, "pinned"), date(dueDay), "A 5 is worked on its own day (\(dueDay))")
            let plan = Forecast.proposeWorkPlan(result, calendar: calendar)
            XCTAssertNil(proposal(plan, "pinned"), "…and is never proposed a different one")
        }
    }

    func testAHardDeadlineWithNoDueDateHasNoPositionToReserve() {
        let days = [day(8, workMinutes: 60)]
        let undated = Forecast.TaskInput(id: "undated", projectID: "p", estimatedMinutes: 30, outcome: 10, dueDate: nil)
        let result = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 0, dueDate: date(30))],
                                        tasks: [undated], calendar: calendar)
        XCTAssertEqual(allocated(result, "undated", on: date(8)), 30,
                       "With no date to keep it is planned like anything else")
    }

    /// A task already placed on a day keeps going through the main loop, which handles habit
    /// absorption — reserving its time here as well would charge the day twice.
    func testAPlacedHardDeadlineIsNotChargedTwice() {
        let days = [day(8, workMinutes: 60)]
        var placed = Forecast.TaskInput(id: "placed", projectID: "p", estimatedMinutes: 45, outcome: 10, dueDate: date(8))
        placed.notBefore = date(8)
        let result = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 0, dueDate: date(30))],
                                        tasks: [placed], calendar: calendar)
        XCTAssertEqual(allocated(result, "placed", on: date(8)), 45, "Charged once, by the main loop")
        let eighth = result.days.first { calendar.isDate($0.date, inSameDayAs: date(8)) }
        XCTAssertEqual(eighth?.allocatedWorkMinutes, 45, "…and the day records 45 minutes, not 90")
    }

    private func allocated(_ result: Forecast.Result, _ taskID: String, on day: Date) -> Double {
        result.tasks.first { $0.task.id == taskID }?.allocations
            .filter { calendar.isDate($0.day, inSameDayAs: day) }
            .reduce(0) { $0 + $1.workMinutes } ?? 0
    }

    // MARK: A typed date is an instruction, not a proposal

    func testATypedDateReplacesTheProposalAndSurvivesRecalculation() throws {
        let task = Forecast.TaskInput(id: "t", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(18))
        let project = Forecast.ProjectInput(id: "p", outcome: 0, dueDate: date(30))
        let plan = self.plan(tasks: [task], project: project)
        let row = try XCTUnwrap(plan.changes.first { $0.itemID == "t" })

        let chosen = date(23)
        let overridden = plan.applyingManualDates([row.id: chosen], calendar: calendar)
        XCTAssertEqual(overridden.changes.first { $0.itemID == "t" }?.proposedDate, chosen,
                       "The user's date replaces the forecast's")
        XCTAssertEqual(overridden.changes.first { $0.itemID == "t" }?.previousDate, row.previousDate,
                       "…without rewriting where it is moving from")
        // The sheet recalculates after every edit, so re-applying the overrides must land identically.
        let again = self.plan(tasks: [task], project: project).applyingManualDates([row.id: chosen], calendar: calendar)
        XCTAssertEqual(again.changes.first { $0.itemID == "t" }?.proposedDate, chosen)
    }

    func testTypingBackTheDateItAlreadyHasIsNotAChange() throws {
        let task = Forecast.TaskInput(id: "t", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(18))
        let plan = self.plan(tasks: [task], project: .init(id: "p", outcome: 0, dueDate: date(30)))
        let row = try XCTUnwrap(plan.changes.first { $0.itemID == "t" })
        XCTAssertFalse(plan.applyingManualDates([row.id: date(18)], calendar: calendar).changes.contains { $0.itemID == "t" },
                       "Typing back the date it already has leaves nothing to apply")
        XCTAssertTrue(plan.applyingManualDates([:], calendar: calendar).changes.contains { $0.itemID == "t" },
                      "…and no overrides leaves the plan exactly as proposed")
    }

    /// One grammar for typed dates: `ToDoDueDateParser`, the shared superset of the snooze field's
    /// parser, so the reschedule row cannot drift from the task editor or the snooze UI.
    func testTheTypedDateGrammarIsTheSharedOne() {
        let base = date(16)
        XCTAssertEqual(ToDoDueDateParser.parse("14d", now: base, calendar: calendar), date(30))
        XCTAssertEqual(ToDoDueDateParser.parse("3wk", now: base, calendar: calendar), date(7, month: 10))
        // `m` is MONTHS in this grammar and never minutes.
        XCTAssertEqual(ToDoDueDateParser.parse("1m", now: base, calendar: calendar), date(16, month: 10))
        XCTAssertNil(ToDoDueDateParser.parse("not a date", now: base, calendar: calendar))
    }

    // MARK: A project's deadline row is not a task row

    func testProjectDeadlineRowsAreSplitOutOfTheTaskGroups() {
        let changes = [change(.task, "ux-1"), change(.project, "ux"), change(.task, "ux-2")]
        let split = ForecastChangeGrouping.split(changes)
        XCTAssertEqual(split.tasks.map(\.itemID), ["ux-1", "ux-2"],
                       "A project's deadline row must not sit among its tasks looking like one of them")
        XCTAssertEqual(split.projectDeadlines.map(\.itemID), ["ux"])
        let groups = ForecastChangeGrouping.groups(split.tasks, taskProjectID: { _ in "ux" })
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].changes.count, 2, "The task card holds only tasks")
    }

    func testTheProjectDeadlineRowSaysWhatItActuallyChanges() {
        let sentence = ForecastText.format(.projectDeadlineRow, ["<PROJECT>": "UX", "<DATE>": "28 Oct 2026"])
        XCTAssertTrue(sentence.contains("UX"))
        XCTAssertTrue(sentence.contains("28 Oct 2026"))
        XCTAssertTrue(sentence.lowercased().contains("project"),
                      "It must say the word 'project' — that is the whole difference from a task row")
        XCTAssertFalse(ForecastText[.projectDeadlineHeading].isEmpty)
        XCTAssertFalse(ForecastText[.projectDeadlineExplanation].isEmpty)
    }

    /// Whatever the planner decides, the row says why. "Not clear why it changed it from 18th to
    /// 16th" was half of report 2026-09-16_09-40-20.
    func testEveryProposalHasAReasonToShow() {
        for key in [ForecastText.Key.reasonYouChoseIt, .reasonBroughtForward, .reasonPushedBack] {
            XCTAssertFalse(ForecastText[key].isEmpty, "\(key) needs words")
            XCTAssertNotEqual(ForecastText[key], key.rawValue, "\(key) must resolve to real copy")
        }
    }

    // MARK: The settled days are the user's call (report 2026-09-21_07-45-21)

    /// "Instead of hardcoding today and tomorrow not included, have a checkbox".
    ///
    /// The checkbox has to reach the days the forecast is *calculated* from. Filtering the finished
    /// list instead would leave the planner still refusing to put work on today and tomorrow, so
    /// unticking it would surface nothing but the work that was already planned there.
    func testTheCheckboxDecidesWhetherTheNextTwoDaysAreSettled() throws {
        let key = LocalForecastStore.locksPlannedDaysKey
        let original = UserDefaults.standard.object(forKey: key)
        defer {
            if let original = original { UserDefaults.standard.set(original, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        UserDefaults.standard.removeObject(forKey: key)

        let store = try loadedStore()
        XCTAssertTrue(store.locksPlannedDays, "Unanswered means the behaviour nobody asked to change")
        store.prepareWorkPlan()
        let settled = try XCTUnwrap(store.result).days
        XCTAssertEqual(settled.prefix(Forecast.lockedPlanDays).filter(\.isLocked).count, Forecast.lockedPlanDays,
                       "today and tomorrow")
        XCTAssertTrue(settled.dropFirst(Forecast.lockedPlanDays).allSatisfy { !$0.isLocked })

        store.locksPlannedDays = false
        XCTAssertTrue(try XCTUnwrap(store.result).days.allSatisfy { !$0.isLocked })
        XCTAssertNotNil(store.workPlan, "the sheet that is open re-flows rather than emptying")
        XCTAssertEqual(UserDefaults.standard.object(forKey: key) as? Bool, false,
                       "…and the answer survives the sheet being closed")
    }

    func testTheCheckboxAndTheSentenceUnderItBothHaveWords() {
        for key in [ForecastText.Key.keepPlannedDays, .plannedDaysLocked] {
            XCTAssertFalse(ForecastText[key].isEmpty, "\(key) needs words")
            XCTAssertNotEqual(ForecastText[key], key.rawValue, "\(key) must resolve to real copy")
        }
    }

    // MARK: Select every proposal in one project

    func testSelectAllTakesTheWholeGroupThenClearsIt() {
        let ids = ["task:a", "task:b", "task:c"]
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: ids, selected: []), .none)
        let all = ForecastGroupSelection.toggled(selectableIDs: ids, selected: [])
        XCTAssertEqual(all, Set(ids))
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: ids, selected: all), .all)
        XCTAssertTrue(ForecastGroupSelection.toggled(selectableIDs: ids, selected: all).isEmpty,
                      "A full box clears the group")
    }

    func testAPartFilledGroupOffersToFinishItRatherThanClearIt() {
        let ids = ["task:a", "task:b", "task:c"]
        let some: Set<String> = ["task:b"]
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: ids, selected: some), .some)
        XCTAssertEqual(ForecastGroupSelection.toggled(selectableIDs: ids, selected: some), Set(ids),
                       "A part-filled box selects the rest instead of throwing away what is ticked")
    }

    /// Select-all must not appear to take rows it cannot write. A row with no permission is left
    /// alone rather than ticked and silently skipped at apply time.
    func testSelectAllSkipsRowsThatCannotBeApplied() {
        let changes = [change(.task, "ok"), change(.task, "locked"), change(.task, "also-ok")]
        let ids = ForecastGroupSelection.selectableIDs(changes) { $0.itemID != "locked" }
        XCTAssertEqual(ids, ["task:ok", "task:also-ok"])
        let selected = ForecastGroupSelection.toggled(selectableIDs: ids, selected: [])
        XCTAssertFalse(selected.contains("task:locked"), "An unwritable row is never swept in")
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: ids, selected: selected), .all,
                       "…and the group still reads as fully selected, because those two are all it can take")
    }

    func testAGroupWithNothingSelectableHasNoSelectAllState() {
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: [], selected: ["task:a"]), .none)
        XCTAssertTrue(ForecastGroupSelection.selectableIDs([change(.task, "x")]) { _ in false }.isEmpty)
    }

    func testSelectAllLeavesOtherProjectsSelectionAlone() {
        let mine = ["task:a", "task:b"]
        let theirs: Set<String> = ["task:z"]
        let after = ForecastGroupSelection.toggled(selectableIDs: mine, selected: theirs)
        XCTAssertTrue(after.contains("task:z"), "Another project's ticks survive")
        XCTAssertEqual(after, Set(mine).union(theirs))
        let cleared = ForecastGroupSelection.toggled(selectableIDs: mine, selected: after)
        XCTAssertEqual(cleared, theirs, "…and clearing this group leaves them too")
    }

    func testTheSelectAllSymbolNamesEachState() {
        XCTAssertNotEqual(ForecastGroupSelection.symbol(for: .none), ForecastGroupSelection.symbol(for: .some))
        XCTAssertNotEqual(ForecastGroupSelection.symbol(for: .some), ForecastGroupSelection.symbol(for: .all))
        XCTAssertFalse(ForecastText[.selectAllInProject].isEmpty)
    }

    // MARK: A suggestion is held to the project's end date too

    /// "The project deadline was in 7 days and project importance was 5/5. It should have suggested
    /// a due date for this task within 7 days" (report 2026-09-16_17-52-37). Verified against the
    /// real project: DMG Fine Wines, `outcome: 10`, due 2026-09-23 — and the editor offered 5 Oct.
    ///
    /// `proposeWorkPlan` applied the ceiling; `nextSlot` never did. A suggested date is as much a
    /// claim about a date as an explicit move, so it is held to the same ceiling.
    func testASuggestionIsNeverOfferedPastTheProjectsEndDate() {
        // Room only after the project has ended.
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 0), day(20, workMinutes: 120)]
        let project = Forecast.ProjectInput(id: "p", outcome: 10, dueDate: date(9))
        let candidate = Forecast.TaskInput(id: "new", projectID: "p", estimatedMinutes: 60, outcome: 2)

        let slot = Forecast.nextSlot(for: candidate, days: days, projects: [project], tasks: [], calendar: calendar)
        XCTAssertTrue(slot.fits, "The work does fit somewhere in the horizon…")
        XCTAssertEqual(slot.completionDate, date(20))
        XCTAssertEqual(slot.projectEnd, date(9), "…but the project ends on the 9th")
        XCTAssertTrue(slot.exceedsProjectEnd)
        XCTAssertNil(slot.proposedDay, "So there is no day inside the project to offer")
    }

    func testASuggestionInsideTheProjectIsStillOffered() {
        let days = [day(7, workMinutes: 120), day(20, workMinutes: 120)]
        let project = Forecast.ProjectInput(id: "p", outcome: 10, dueDate: date(9))
        let candidate = Forecast.TaskInput(id: "new", projectID: "p", estimatedMinutes: 60, outcome: 2)
        let slot = Forecast.nextSlot(for: candidate, days: days, projects: [project], tasks: [], calendar: calendar)
        XCTAssertEqual(slot.proposedDay, date(7), "Room before the deadline is still proposed")
        XCTAssertFalse(slot.exceedsProjectEnd)
    }

    func testAProjectWithNoEndDateStillCeilingsNothingForSuggestions() {
        let days = [day(7, workMinutes: 0), day(20, workMinutes: 120)]
        let candidate = Forecast.TaskInput(id: "new", projectID: "p", estimatedMinutes: 60, outcome: 2)
        let slot = Forecast.nextSlot(for: candidate, days: days,
                                     projects: [.init(id: "p", outcome: 10, dueDate: nil)], tasks: [], calendar: calendar)
        XCTAssertNil(slot.projectEnd)
        XCTAssertEqual(slot.proposedDay, date(20), "No end date is no ceiling")
    }

    /// The candidate must not be pinned to the date currently in the field — that is the very thing
    /// being chosen, and pinning it would hand the field's own value back as the "suggestion".
    func testTheCandidateIsNotReservedOnTheDateBeingChosen() {
        let days = [day(7, workMinutes: 120), day(8, workMinutes: 120)]
        let project = Forecast.ProjectInput(id: "p", outcome: 10, dueDate: date(30))
        // A 5 whose field currently says the 8th: the suggestion should still be the 7th, the first
        // day with room, not an echo of the 8th.
        let candidate = Forecast.TaskInput(id: "new", projectID: "p", estimatedMinutes: 60,
                                           outcome: 10, dueDate: date(8))
        let slot = Forecast.nextSlot(for: candidate, days: days, projects: [project], tasks: [], calendar: calendar)
        XCTAssertEqual(slot.proposedDay, date(7), "The candidate is placed by capacity, not by its own field")

        // Every OTHER hard deadline keeps its reservation, so the candidate is placed around it.
        let committed = Forecast.TaskInput(id: "committed", projectID: "p", estimatedMinutes: 120,
                                           outcome: 10, dueDate: date(7))
        let around = Forecast.nextSlot(for: candidate, days: days, projects: [project],
                                       tasks: [committed], calendar: calendar)
        XCTAssertEqual(around.proposedDay, date(8), "The 7th is spoken for, so the candidate goes to the 8th")
    }

    func testTheEditorSaysTheProjectEndedRatherThanGoingSilent() {
        let end = date(9)
        let advice = ForecastDueDateAdvisor.Advice.pastProjectEnd(end)
        let text = ForecastDueDateAdvisor.text(for: advice)
        XCTAssertNotNil(text)
        XCTAssertTrue(text?.contains(ForecastText.date(end)) == true, "It names the project's end date")
        XCTAssertNotEqual(text, ForecastText[.noSlot],
                          "‘fits, but only after the project ends’ is a different fact from ‘fits nowhere’")
    }

    // MARK: One ceiling predicate, asked by every path that names a date

    /// A pure refactor, pinned so it stays one. The app names a date in two places —
    /// `proposeWorkPlan` proposes a move, `nextSlot` suggests a due date — and both must refuse a day
    /// past the owning project's end. They derived the ceiling from the same function but each
    /// compared against it separately, which is how a suggestion six weeks past a project's deadline
    /// shipped while the reschedule sheet refused the very same day (report 2026-09-16_17-52-37).
    func testTheCeilingPredicateIsTheOneDefinitionOfInsideTheProject() {
        let ceiling = date(9)
        XCTAssertTrue(Forecast.ForecastCeiling.allows(date(8), ceiling: ceiling))
        XCTAssertTrue(Forecast.ForecastCeiling.allows(date(9), ceiling: ceiling), "The end date itself is inside")
        XCTAssertFalse(Forecast.ForecastCeiling.allows(date(10), ceiling: ceiling))
        // breaches is exactly the inverse, so a call site may read whichever way is clearer.
        for day in [date(8), date(9), date(10)] {
            XCTAssertEqual(Forecast.ForecastCeiling.breaches(day, ceiling: ceiling),
                           !Forecast.ForecastCeiling.allows(day, ceiling: ceiling))
        }
    }

    /// The part each call site would otherwise re-decide for itself.
    func testANilCeilingIsTheAbsenceOfOneNeverAnInfiniteOne() {
        XCTAssertTrue(Forecast.ForecastCeiling.allows(date(31, month: 12), ceiling: nil),
                      "No ceiling never refuses a day")
        XCTAssertFalse(Forecast.ForecastCeiling.breaches(date(31, month: 12), ceiling: nil))
    }

    func testTheCeilingDerivationIsUnchangedByTheRefactor() {
        let task = Forecast.TaskInput(id: "t", projectID: "p")
        let project = Forecast.ProjectInput(id: "p", outcome: 10, dueDate: date(9, hour: 13))
        XCTAssertEqual(Forecast.ForecastCeiling.forTask(task, project: project, calendar: calendar), date(9),
                       "Normalised to the start of the day, as before")
        XCTAssertEqual(Forecast.ForecastCeiling.forTask(task, project: project, calendar: calendar),
                       Forecast.projectCeiling(task: task, project: project, calendar: calendar),
                       "The wrapper and the derivation it wraps cannot disagree")
        XCTAssertNil(Forecast.ForecastCeiling.forTask(task, project: .init(id: "p", outcome: 10, dueDate: nil),
                                                     calendar: calendar))
        XCTAssertNil(Forecast.ForecastCeiling.forTask(Forecast.TaskInput(id: "t"), project: project,
                                                      calendar: calendar),
                     "A task with no project is held by nothing")
    }

    /// Both date-naming paths agree about the same day — which is the property the refactor exists
    /// to keep true, and the one that was false when this was two comparisons.
    func testBothDateNamingPathsRefuseTheSameDay() {
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 0), day(20, workMinutes: 120)]
        let project = Forecast.ProjectInput(id: "p", outcome: 4, dueDate: date(9))
        let task = Forecast.TaskInput(id: "t", projectID: "p", estimatedMinutes: 60, outcome: 4, dueDate: date(7))

        // The suggestion path refuses to offer the 20th…
        let slot = Forecast.nextSlot(for: task, days: days, projects: [project], tasks: [], calendar: calendar)
        XCTAssertEqual(slot.completionDate, date(20))
        XCTAssertNil(slot.proposedDay)

        // …and the plan path refuses to propose it, for the same reason and on the same day.
        let plan = Forecast.proposeWorkPlan(Forecast.calculate(days: days, projects: [project], tasks: [task],
                                                               calendar: calendar), calendar: calendar)
        XCTAssertNil(proposal(plan, "t"))
        XCTAssertTrue(plan.conflicts.contains { $0.itemID == "t" && $0.reason == .projectEndDate })
    }

    // MARK: A bulk select never takes a project's deadline

    /// "Select all editable changes shouldn't select the project due date assignments"
    /// (report 2026-09-16_17-47-42). A project row moves a whole project's deadline, which is why it
    /// has its own section — and why no bulk control may sweep it up.
    func testABulkSelectTakesTaskChangesAndNeverProjectDeadlines() {
        let changes = [change(.task, "a"), change(.project, "ux"), change(.task, "b")]
        let ids = ForecastGroupSelection.bulkSelectableIDs(changes) { _ in true }
        XCTAssertEqual(ids, ["task:a", "task:b"])
        XCTAssertFalse(ids.contains("project:ux"), "A project deadline is never bulk-selected")
        // …and it is still individually selectable.
        var selected: Set<String> = Set(ids)
        selected.insert("project:ux")
        XCTAssertTrue(selected.contains("project:ux"))
    }

    func testTheGroupSelectAllUsesTheSameRule() {
        let changes = [change(.task, "a"), change(.project, "ux")]
        XCTAssertEqual(ForecastGroupSelection.selectableIDs(changes) { _ in true }, ["task:a"],
                       "One rule, so the sheet-wide button and the per-project one cannot drift")
    }

    // MARK: Selecting a whole accordion

    /// "it needs to let me select all in the minor changes accordion" (report 2026-09-16_17-49-54,
    /// follow-up). The value is accepting the minor pile wholesale while still reading the major one
    /// row by row — so the control must be scoped to its own accordion and touch nothing else.
    func testSelectingAllMinorChangesLeavesTheMajorPileUntouched() {
        let minor = [Forecast.DueDateChange(kind: .task, itemID: "m1", previousDate: date(7), proposedDate: date(8)),
                     Forecast.DueDateChange(kind: .task, itemID: "m2", previousDate: date(7), proposedDate: date(9))]
        let major = [Forecast.DueDateChange(kind: .task, itemID: "M1", previousDate: date(7), proposedDate: date(20))]
        XCTAssertTrue(minor.allSatisfy { !ForecastChangeGrouping.isMajor($0, calendar: calendar) })
        XCTAssertTrue(major.allSatisfy { ForecastChangeGrouping.isMajor($0, calendar: calendar) })

        let minorIDs = ForecastGroupSelection.bulkSelectableIDs(minor) { _ in true }
        let selected = ForecastGroupSelection.toggled(selectableIDs: minorIDs, selected: [])
        XCTAssertEqual(selected, ["task:m1", "task:m2"])
        XCTAssertFalse(selected.contains("task:M1"), "The major pile is untouched")

        // And the major accordion still reads as empty-selected.
        let majorIDs = ForecastGroupSelection.bulkSelectableIDs(major) { _ in true }
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: majorIDs, selected: selected), .none)
    }

    /// The third selection control reads the same function as the other two, so it inherits the
    /// project-due-date exclusion rather than re-implementing it (report 2026-09-16_17-47-42).
    func testAnAccordionSelectAllNeverTakesAProjectDeadline() {
        let changes = [change(.task, "a"), change(.project, "ux"), change(.task, "b")]
        let ids = ForecastGroupSelection.bulkSelectableIDs(changes) { _ in true }
        XCTAssertEqual(ids, ["task:a", "task:b"])
        let selected = ForecastGroupSelection.toggled(selectableIDs: ids, selected: [])
        XCTAssertFalse(selected.contains("project:ux"))
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: ids, selected: selected), .all,
                       "…and the accordion still reads as full, because those two are all it can take")
    }

    /// The accordion box and the project boxes nested inside it must agree: ticking every project
    /// individually has to leave the accordion showing "all", not "some".
    func testTickingEveryProjectIndividuallyFillsTheAccordionControl() {
        let changes = [
            Forecast.DueDateChange(kind: .task, itemID: "ux-1", previousDate: date(7), proposedDate: date(8)),
            Forecast.DueDateChange(kind: .task, itemID: "ux-2", previousDate: date(7), proposedDate: date(9)),
            Forecast.DueDateChange(kind: .task, itemID: "mrff-1", previousDate: date(7), proposedDate: date(8)),
        ]
        let owners = ["ux-1": "ux", "ux-2": "ux", "mrff-1": "mrff"]
        let accordionIDs = ForecastGroupSelection.bulkSelectableIDs(changes) { _ in true }

        var selected: Set<String> = []
        for group in ForecastChangeGrouping.groups(changes, taskProjectID: { owners[$0] }) {
            let groupIDs = ForecastGroupSelection.selectableIDs(group.changes) { _ in true }
            // Part-way through, the accordion reads "some".
            selected = ForecastGroupSelection.toggled(selectableIDs: groupIDs, selected: selected)
            XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: groupIDs, selected: selected), .all,
                           "each project reads as full once ticked")
        }
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: accordionIDs, selected: selected), .all,
                       "Ticking every project individually fills the accordion control too")

        // The union of the per-project sets IS the accordion's set — which is why they can agree.
        let union = ForecastChangeGrouping.groups(changes, taskProjectID: { owners[$0] })
            .flatMap { ForecastGroupSelection.selectableIDs($0.changes) { _ in true } }
        XCTAssertEqual(Set(union), Set(accordionIDs))
    }

    func testAnAccordionSelectAllIsPartFilledWhenOnlySomeAreTicked() {
        let changes = [change(.task, "a"), change(.task, "b"), change(.task, "c")]
        let ids = ForecastGroupSelection.bulkSelectableIDs(changes) { _ in true }
        XCTAssertEqual(ForecastGroupSelection.state(selectableIDs: ids, selected: ["task:b"]), .some)
        XCTAssertEqual(ForecastGroupSelection.toggled(selectableIDs: ids, selected: ["task:b"]), Set(ids),
                       "A part-filled accordion box finishes the job, like the project one")
    }

    func testAnEmptyPileOffersNoSelectAllAtAll() {
        XCTAssertTrue(ForecastGroupSelection.bulkSelectableIDs([]) { _ in true }.isEmpty)
        // Nothing selectable also means nothing to render — the view guards on the same emptiness.
        XCTAssertTrue(ForecastGroupSelection.bulkSelectableIDs([change(.project, "ux")]) { _ in true }.isEmpty,
                      "A pile of nothing but project deadlines offers no bulk control either")
    }

    func testTheAccordionSelectAllTooltipCountsWhatItWillTake() {
        let tip = ForecastText.format(.selectAllInGroup, ["<COUNT>": "4"])
        XCTAssertTrue(tip.contains("4"))
        XCTAssertFalse(tip.contains("<COUNT>"))
        XCTAssertNotEqual(ForecastText[.selectAllInGroup], ForecastText[.selectAllInProject],
                          "The two controls say what they each cover")
    }

    // MARK: Major and minor piles

    func testDaysMovedIsAbsoluteSoAnEarlierPullCountsTheSame() {
        let later = Forecast.DueDateChange(kind: .task, itemID: "a", previousDate: date(7), proposedDate: date(16))
        let earlier = Forecast.DueDateChange(kind: .task, itemID: "b", previousDate: date(16), proposedDate: date(7))
        XCTAssertEqual(ForecastChangeGrouping.daysMoved(later, calendar: calendar), 9)
        XCTAssertEqual(ForecastChangeGrouping.daysMoved(earlier, calendar: calendar), 9,
                       "A task dragged nine days earlier interferes as much as one pushed nine days later")
        XCTAssertTrue(ForecastChangeGrouping.isMajor(earlier, calendar: calendar))
    }

    /// The PO wrote "> 5" and "< 5", which leaves 5 itself unhomed. It goes in the pile they said
    /// they want to read.
    func testExactlyFiveDaysCountsAsMajor() {
        let five = Forecast.DueDateChange(kind: .task, itemID: "a", previousDate: date(7), proposedDate: date(12))
        XCTAssertEqual(ForecastChangeGrouping.daysMoved(five, calendar: calendar), ForecastChangeGrouping.majorThresholdDays)
        XCTAssertTrue(ForecastChangeGrouping.isMajor(five, calendar: calendar), "5 errs toward scrutiny")

        let four = Forecast.DueDateChange(kind: .task, itemID: "b", previousDate: date(7), proposedDate: date(11))
        XCTAssertFalse(ForecastChangeGrouping.isMajor(four, calendar: calendar))
    }

    func testATaskThatHadNoDeadlineAtAllIsMajor() {
        let fresh = Forecast.DueDateChange(kind: .task, itemID: "a", previousDate: nil, proposedDate: date(8))
        XCTAssertTrue(ForecastChangeGrouping.isMajor(fresh, calendar: calendar),
                      "Giving a deadline to work that had none is a bigger claim than any number of days")
    }

    func testProjectsAreStillGroupedInsideEachPile() {
        let changes = [
            Forecast.DueDateChange(kind: .task, itemID: "ux-far", previousDate: date(7), proposedDate: date(20)),
            Forecast.DueDateChange(kind: .task, itemID: "ux-near", previousDate: date(7), proposedDate: date(8)),
            Forecast.DueDateChange(kind: .task, itemID: "mrff-far", previousDate: date(7), proposedDate: date(20)),
        ]
        let owners = ["ux-far": "ux", "ux-near": "ux", "mrff-far": "mrff"]
        let major = changes.filter { ForecastChangeGrouping.isMajor($0, calendar: calendar) }
        let minor = changes.filter { !ForecastChangeGrouping.isMajor($0, calendar: calendar) }
        XCTAssertEqual(major.map(\.itemID), ["ux-far", "mrff-far"])
        XCTAssertEqual(minor.map(\.itemID), ["ux-near"])
        XCTAssertEqual(ForecastChangeGrouping.groups(major, taskProjectID: { owners[$0] }).map(\.id), ["ux", "mrff"],
                       "Projects still group inside the major pile")
        XCTAssertEqual(ForecastChangeGrouping.groups(minor, taskProjectID: { owners[$0] }).map(\.id), ["ux"])
    }

    func testBothAccordionTitlesCarryTheirCount() {
        for key in [ForecastText.Key.majorChanges, .minorChanges] {
            let title = ForecastText.format(key, ["<COUNT>": "3"])
            XCTAssertTrue(title.contains("3"), "\(key) shows how many are inside")
            XCTAssertFalse(title.contains("<COUNT>"))
        }
    }

    // MARK: Fixing ONE day — why the useful rows were invisible

    /// The finding behind `ForecastDayFocus`, pinned so it cannot be forgotten and re-argued.
    ///
    /// Today and tomorrow are locked (`lockedPlanDays`), so the earliest day any proposal may name is
    /// the day after tomorrow. For an over-committed day, the work that overflows it lands a day or
    /// two later — which is **always** under the 5-day major threshold, so every proposal that could
    /// fix that day is filed as "minor", and the minor pile is collapsed at the PO's own request. The
    /// lock and the grouping are each correct, and between them they hid the entire useful output.
    func testEveryProposalThatCanFixAnOvercommittedDayIsClassifiedMinor() {
        // The real shape: work planned onto the over-committed day and due that same day. Its
        // overflow can only go to the next open day, so the proposal moves it ONE day.
        let result = Forecast.calculate(days: [day(21, workMinutes: 60), day(22, workMinutes: 600)],
                                        projects: [.init(id: "p")], tasks: [
            .init(id: "a", projectID: "p", estimatedMinutes: 60, dueDate: date(21), notBefore: date(21)),
            .init(id: "b", projectID: "p", estimatedMinutes: 30, dueDate: date(21), notBefore: date(21))],
            calendar: calendar)
        let plan = Forecast.proposeWorkPlan(result, calendar: calendar)
        let offered = ForecastDayFocus.changes(movingWorkOff: date(21), in: plan.changes,
                                               plannedDay: { _ in self.date(21) }, calendar: calendar)
        XCTAssertFalse(offered.isEmpty, "There IS something to propose for the over-committed day")
        XCTAssertTrue(offered.allSatisfy { !ForecastChangeGrouping.isMajor($0, calendar: calendar) },
                      "…and every one of them is 'minor' — inside the accordion that starts closed")
    }

    func testOnlyAProposalThatActuallyTakesWorkOffTheDayCounts() {
        let leaving = Forecast.DueDateChange(kind: .task, itemID: "a",
                                             previousDate: date(21), proposedDate: date(23))
        let arriving = Forecast.DueDateChange(kind: .task, itemID: "b",
                                              previousDate: date(28), proposedDate: date(21))
        let elsewhere = Forecast.DueDateChange(kind: .task, itemID: "c",
                                               previousDate: date(22), proposedDate: date(25))
        let planned = ["a": date(21), "b": date(21), "c": date(22)]
        let offered = ForecastDayFocus.changes(movingWorkOff: date(21), in: [leaving, arriving, elsewhere],
                                               plannedDay: { planned[$0] }, calendar: calendar)
        XCTAssertEqual(offered.map(\.itemID), ["a"],
                       "Being proposed FOR the day frees none of it, and neither does a task on another day")
    }

    /// The honest half. Five rows that do not add up to the gap are worse than being told the gap
    /// cannot be closed from here.
    func testTheReliefLineSaysWhenTheOfferedMovesCannotCloseTheGap() {
        let change = Forecast.DueDateChange(kind: .task, itemID: "a",
                                            previousDate: date(21), proposedDate: date(23))
        let short = ForecastDayFocus.relief(freeing: [change],
                                            target: .init(day: date(21), shortfallMinutes: 33),
                                            minutes: { _ in 28 }, immovable: [])
        XCTAssertEqual(short.freedMinutes, 28)
        XCTAssertEqual(short.remainingMinutes, 5)
        XCTAssertFalse(short.clearsTheDay)
        XCTAssertFalse(short.remainderIsPinned, "Nothing is pinned, so pinning does not explain the remainder")

        let enough = ForecastDayFocus.relief(freeing: [change],
                                             target: .init(day: date(21), shortfallMinutes: 20),
                                             minutes: { _ in 28 }, immovable: [])
        XCTAssertTrue(enough.clearsTheDay)
        XCTAssertEqual(enough.remainingMinutes, 0)
    }

    /// When what is left over is exactly the work the user pinned, the sheet has done everything it
    /// is allowed to do and should say so rather than look as though it gave up.
    func testARemainderMadeEntirelyOfHardDeadlineWorkIsNamedAsSuch() {
        let change = Forecast.DueDateChange(kind: .task, itemID: "a",
                                            previousDate: date(21), proposedDate: date(23))
        let relief = ForecastDayFocus.relief(freeing: [change],
                                             target: .init(day: date(21), shortfallMinutes: 33),
                                             minutes: { _ in 28 },
                                             immovable: [(id: "pinned", minutes: 15)])
        XCTAssertEqual(relief.remainingMinutes, 5)
        XCTAssertEqual(relief.immovableCount, 1)
        XCTAssertTrue(relief.remainderIsPinned,
                      "15m of pinned work more than covers the 5m still over, so pinning is the reason")
    }

    func testAnEmptyOfferFreesNothingAndNeverClaimsToFixTheDay() {
        let relief = ForecastDayFocus.relief(freeing: [], target: .init(day: date(21), shortfallMinutes: 33),
                                             minutes: { _ in 99 }, immovable: [])
        XCTAssertEqual(relief.freedMinutes, 0)
        XCTAssertFalse(relief.clearsTheDay)
    }

    // MARK: "Couldn't pick a date" — the rows the planner refused

    private func conflict(_ id: String, _ reason: Forecast.ConflictReason,
                          earliest: Date? = nil) -> Forecast.PlanConflict {
        .init(kind: .task, itemID: id, reason: reason, earliestCompletionDate: earliest)
    }

    /// "Let me reschedule manually if I want to". Every refusal is a refusal to *invent* a date, not
    /// a claim that the user may not choose one — so a typed date turns the row into an ordinary
    /// proposal and the conflict stops being raised.
    func testADateTypedOnARefusedRowBecomesAProposal() {
        let plan = Forecast.WorkPlan(changes: [], conflicts: [
            conflict("limit", .postponementLimit, earliest: date(30)),
            conflict("ends", .projectEndDate, earliest: date(30))])
        let adopted = plan.adoptingManualDates(["task:limit": date(25)],
                                               previousDate: { _, _ in self.date(21) }, calendar: calendar)
        XCTAssertEqual(adopted.changes.map(\.itemID), ["limit"])
        XCTAssertEqual(adopted.changes.first?.proposedDate, date(25))
        XCTAssertEqual(adopted.changes.first?.previousDate, date(21), "It keeps the date it is moving from")
        XCTAssertEqual(adopted.conflicts.map(\.itemID), ["ends"], "The row the user answered stops being raised")
    }

    /// Without an estimate the task cannot be placed at all, so a date on it is a date the plan
    /// cannot keep. That row's fix is the estimate, which the row already offers.
    func testAMissingEstimateStillRefusesADate() {
        let plan = Forecast.WorkPlan(changes: [], conflicts: [conflict("no-est", .missingEstimate)])
        let adopted = plan.adoptingManualDates(["task:no-est": date(25)],
                                               previousDate: { _, _ in nil }, calendar: calendar)
        XCTAssertTrue(adopted.changes.isEmpty)
        XCTAssertEqual(adopted.conflicts.map(\.itemID), ["no-est"])
    }

    func testTypingTheDateARowAlreadyHasAnswersItWithoutInventingAChange() {
        let plan = Forecast.WorkPlan(changes: [], conflicts: [conflict("same", .postponementLimit)])
        let adopted = plan.adoptingManualDates(["task:same": date(21)],
                                               previousDate: { _, _ in self.date(21) }, calendar: calendar)
        XCTAssertTrue(adopted.changes.isEmpty, "Its date is not changing, so there is nothing to apply")
        XCTAssertTrue(adopted.conflicts.isEmpty, "…but the user has answered it, so it stops being raised")
    }

    /// "It should have the same grouping by project" — the same key and the same first-seen order as
    /// the proposal list, not a second convention.
    func testRefusedRowsGroupByProjectTheSameWayProposalsDo() {
        let owners = ["a": "ux", "b": "mrff", "c": "ux"]
        let groups = ForecastConflictGrouping.groups(
            [conflict("a", .postponementLimit), conflict("b", .projectEndDate),
             conflict("c", .postponementLimit), conflict("d", .postponementLimit)],
            taskProjectID: { owners[$0] })
        XCTAssertEqual(groups.map(\.id), ["ux", "mrff", "__unprojected"])
        XCTAssertEqual(groups.first?.conflicts.map(\.itemID), ["a", "c"])
        XCTAssertNil(groups.last?.projectID, "A task with no project still gets a home")
    }

    /// The old copy — "Completion would exceed the extension allowed by this outcome. Review the
    /// scope or priority." — was this code's vocabulary, and nothing in it was checkable or
    /// actionable. Both common refusals now name the date the work would actually land on.
    func testTheRefusalSentencesNameADateTheUserCanCheck() {
        let limit = ForecastText.conflict(.postponementLimit, earliest: date(30), outcome: 8)
        XCTAssertTrue(limit.contains(ForecastText.date(date(30))), "It says when the work could actually be done")
        XCTAssertFalse(limit.lowercased().contains("outcome"), "…and not in this code's vocabulary")
        XCTAssertFalse(limit.contains("<DATE>"))
        XCTAssertFalse(limit.contains("<BAND>"))

        let ends = ForecastText.conflict(.projectEndDate, earliest: date(30),
                                         projectName: "MRFF", projectEnd: date(25))
        XCTAssertTrue(ends.contains(ForecastText.date(date(30))))
        XCTAssertTrue(ends.contains(ForecastText.date(date(25))), "…and the deadline it breaches")
        XCTAssertTrue(ends.contains("MRFF"))
        XCTAssertFalse(ends.contains("<ENDDATE>"))
    }

    /// A refusal with nothing to name must still read as a sentence rather than leak a token.
    func testARefusalWithNoDateStillReadsAsASentence() {
        for text in [ForecastText.conflict(.postponementLimit, outcome: 8),
                     ForecastText.conflict(.projectEndDate, earliest: date(30))] {
            XCTAssertFalse(text.contains("<"), "no unreplaced placeholder in: \(text)")
            XCTAssertFalse(text.isEmpty)
        }
    }

    // MARK: When to offer to re-prioritise

    private func suggestion(overdue: Int = 0, over: Double = 0, dismissedAt: Date? = nil,
                            now: Date? = nil) -> ReprioritiseSuggestion.Reason? {
        ReprioritiseSuggestion.reason(overdueCount: overdue, worstDayOvercommitMinutes: over,
                                      dismissedAt: dismissedAt, now: now ?? date(16), calendar: calendar)
    }

    /// The PO's rule, verbatim: "> 4 overdue tasks", taken literally as five or more
    /// (report 2026-09-16_22-22-50, follow-up). This replaces a threshold of ten measured from their
    /// own backlog — the measurement was the better-argued number, but it is not the one they asked
    /// for, and they asked twice.
    func testMoreThanFourOverdueTasksIsTheRule() {
        XCTAssertEqual(ReprioritiseSuggestion.overdueThreshold, 5)
        XCTAssertNil(suggestion(overdue: 4), "Four is not more than four")
        XCTAssertEqual(suggestion(overdue: 5), .overdue(5), "Five is")
        XCTAssertEqual(suggestion(overdue: 42), .overdue(42))
    }

    func testADayMerelyOverCapacityIsNotWorthASuggestion() {
        XCTAssertEqual(ReprioritiseSuggestion.massivelyOverMinutes, 120)
        XCTAssertNil(suggestion(over: 15), "Fifteen minutes over is a working lunch, not a crisis")
        XCTAssertNil(suggestion(over: 119))
        XCTAssertEqual(suggestion(over: 120), .dayOverCapacity(120), "Two hours is the line")
        XCTAssertEqual(suggestion(over: 300), .dayOverCapacity(300))
    }

    /// The window the capacity reason measures: today plus the next four.
    func testTheCapacityWindowIsFiveDaysIncludingToday() {
        XCTAssertEqual(ReprioritiseSuggestion.horizonDays, 5,
                       "Today is the day most likely to be over, so excluding it would be the odd choice")
    }

    func testEitherConditionIsEnoughAndOverdueIsNamedFirst() {
        XCTAssertEqual(suggestion(overdue: 6, over: 0), .overdue(6))
        XCTAssertEqual(suggestion(overdue: 0, over: 240), .dayOverCapacity(240))
        XCTAssertEqual(suggestion(overdue: 6, over: 240), .overdue(6),
                       "A backlog is the more useful thing to name when both are true")
        XCTAssertNil(suggestion(overdue: 0, over: 0))
    }

    /// A declined suggestion stays declined. Per-day would nag up to seven times for one persistent
    /// backlog; forever would spend the feature the first time the user was merely busy.
    func testADismissedSuggestionStaysGoneForAWeekThenComesBack() {
        XCTAssertEqual(ReprioritiseSuggestion.dismissalDays, 7)
        let dismissed = date(16)
        XCTAssertNil(suggestion(overdue: 20, dismissedAt: dismissed, now: date(16)), "Gone immediately")
        XCTAssertNil(suggestion(overdue: 20, dismissedAt: dismissed, now: date(20)), "…and mid-week")
        XCTAssertNil(suggestion(overdue: 20, dismissedAt: dismissed, now: date(22)),
                     "…right up to the last moment of the seventh day")
        XCTAssertEqual(suggestion(overdue: 20, dismissedAt: dismissed, now: date(23)), .overdue(20),
                       "A week later a still-unfixed backlog may ask once more")
    }

    func testDismissingSilencesBothReasonsNotJustTheOneShowing() {
        let dismissed = date(16)
        XCTAssertNil(suggestion(overdue: 0, over: 500, dismissedAt: dismissed, now: date(17)),
                     "Declining the offer declines it, whichever condition raises it next")
    }

    func testTheBannerSentenceNamesTheNumberItIsTalkingAbout() {
        let overdue = ReprioritiseSuggestion.text(for: .overdue(14))
        XCTAssertTrue(overdue.contains("14"))
        XCTAssertFalse(overdue.contains("<COUNT>"))
        let over = ReprioritiseSuggestion.text(for: .dayOverCapacity(150))
        XCTAssertFalse(over.contains("<DURATION>"))
        XCTAssertNotEqual(overdue, over, "The two reasons do not share a sentence")
    }

    /// The sentence has to describe what the number measures. It said "Today is <DURATION> over"
    /// while carrying the worst day of a ninety-day horizon, which is the whole of "Today is not
    /// 3h18m over" and then "still the same - it says 4h over"
    /// (report 2026-09-16_22-22-50, two follow-ups).
    func testTheCapacitySentenceNeverClaimsTheProblemIsToday() {
        let text = ReprioritiseSuggestion.text(for: .dayOverCapacity(244))
        XCTAssertFalse(text.lowercased().contains("today"),
                       "It is the worst of the next few days — saying 'today' was the bug, twice")
        XCTAssertTrue(text.contains(String(ReprioritiseSuggestion.horizonDays)),
                      "…and it names the window it measured, from the same constant that bounds it")
        XCTAssertFalse(text.contains("<DAYS>"))
        XCTAssertFalse(text.contains("<DURATION>"))
    }

    /// The PO gave two spellings deliberately — "todo" for the menu item, "to-do" for the link — and
    /// both are used verbatim rather than normalised.
    func testTheMenuItemAndTheLinkUseThePOsOwnWording() {
        XCTAssertEqual(ForecastText[.reprioritiseMenuItem], "Re-prioritise todo list")
        XCTAssertEqual(ForecastText[.reprioritiseLink], "Help me re-prioritise to-do list")
    }

    func testADismissalIsRememberedPerAccount() {
        let defaults = UserDefaults(suiteName: "reprioritise-tests-\(UUID().uuidString)")!
        XCTAssertNil(ReprioritiseSuggestionDismissal.dismissedAt(account: "a", defaults: defaults))
        ReprioritiseSuggestionDismissal.dismiss(account: "a", now: date(16), defaults: defaults)
        XCTAssertEqual(ReprioritiseSuggestionDismissal.dismissedAt(account: "a", defaults: defaults), date(16))
        XCTAssertNil(ReprioritiseSuggestionDismissal.dismissedAt(account: "b", defaults: defaults),
                     "Two people on one Mac have different backlogs")
        // An empty account id is not a bucket to write into.
        ReprioritiseSuggestionDismissal.dismiss(account: "", now: date(16), defaults: defaults)
        XCTAssertNil(ReprioritiseSuggestionDismissal.dismissedAt(account: "", defaults: defaults))
    }

    func testTheStoreCountsOverdueTheSameWayTheListsRedChipsDo() throws {
        let store = try loadedStore()
        // The fixture's one task is due yesterday, which is exactly what the red chip calls overdue.
        XCTAssertEqual(store.overdueCount, 1)
        XCTAssertNil(store.reprioritiseSuggestion, "One overdue task is not more than four")
    }

    /// The number the banner shows comes from the next five days only.
    ///
    /// Built as the shape that produced the bug: a nearby day with a small over-commitment and a day
    /// far outside the window with a huge one. The old query took the maximum across the forecast's
    /// whole ninety-day horizon and the sentence called it today's.
    func testTheCapacityNumberIgnoresDaysOutsideTheWindow() {
        let today = date(16)
        func day(_ offset: Int, freeMinutes: Double) -> LocalTimeForecast.DayInput {
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            let start = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date)!
            let eaten = max(0, 960 - freeMinutes)
            return .init(date: date,
                         blocks: eaten > 0 ? [.habit(id: "filler\(offset)", blockKey: "habit:filler",
                                                     interval: .init(start: start, end: start.addingTimeInterval(eaten * 60)))] : [],
                         settings: .init(selfCareMinutes: 0))
        }
        // Day 2 is 60m over; day 30 — far outside the five-day window — is 600m over.
        func pinned(_ id: String, offset: Int, minutes: Double) -> LocalTimeForecast.TaskInput {
            .init(id: id, projectID: "p", estimatedMinutes: minutes,
                  notBefore: calendar.date(byAdding: .day, value: offset, to: today)!)
        }
        let days = (0..<40).map { day($0, freeMinutes: $0 == 2 ? 60 : ($0 == 30 ? 60 : 960)) }
        let tasks = [pinned("near", offset: 2, minutes: 120), pinned("far", offset: 30, minutes: 660)]
        let forecast = LocalTimeForecast.calculate(days: days, projects: [.init(id: "p")],
                                                   tasks: tasks, calendar: calendar)
        let windowed = forecast.days.prefix(ReprioritiseSuggestion.horizonDays)
            .compactMap { LocalTimeForecast.dayLoad(on: $0.date, forecast: forecast, calendar: calendar) }
            .map(\.overcommittedMinutes).max() ?? 0
        let wholeHorizon = forecast.days
            .compactMap { LocalTimeForecast.dayLoad(on: $0.date, forecast: forecast, calendar: calendar) }
            .map(\.overcommittedMinutes).max() ?? 0
        XCTAssertEqual(windowed, 60, accuracy: 0.001, "The worst day the user can act on this week")
        XCTAssertEqual(wholeHorizon, 600, accuracy: 0.001, "…and the far-off day the banner used to quote")
        XCTAssertLessThan(ReprioritiseSuggestion.massivelyOverMinutes, wholeHorizon,
                          "The old number would have fired the banner; the windowed one must not")
        XCTAssertNil(suggestion(over: windowed), "An hour over, four days out, is not a crisis")
    }

    // MARK: Row layout — the trailing actions must survive a narrow panel

    /// The complete button was pushed past the right edge by a long title and clipped, leaving a row
    /// that could not be completed (report 2026-09-16_09-27-24). The row's widths are stated once in
    /// `ForecastRowMetrics` so the arithmetic can be checked without a window: at any panel width the
    /// reserved action column and the scroller clearance come out of the TITLE's share, never out of
    /// the buttons.
    func testTheRowAlwaysReservesRoomForItsTrailingActionsAndTheScroller() {
        XCTAssertGreaterThan(ForecastRowMetrics.actionWidth, 0)
        XCTAssertGreaterThan(ForecastRowMetrics.scrollerClearance, 0,
                             "A trailing control must never sit under the vertical scroller")
        let rowSpacing: CGFloat = 8
        // The sheet is 660 wide with 18pt padding each side; the narrower values are the case that
        // actually broke.
        for panel in [CGFloat(660 - 36), 420, 320, 240] {
            let available = panel - ForecastRowMetrics.scrollerClearance
            let titleShare = available - ForecastRowMetrics.actionWidth - rowSpacing
            XCTAssertGreaterThan(titleShare, 0,
                                 "At \(panel)pt the title still has room beside the fixed action column")
            XCTAssertLessThanOrEqual(titleShare + rowSpacing + ForecastRowMetrics.actionWidth, available,
                                     "At \(panel)pt the row fits without the button overflowing")
        }
    }

    func testEachRowsStateIsPinnedToItsOwnChange() {
        // A row's identity is its change's id, so a control left open on one row cannot be carried
        // onto another when the plan re-flows. Ids must be unique per row and stable across rebuilds.
        let changes = [change(.task, "a"), change(.task, "b"), change(.project, "a")]
        XCTAssertEqual(Set(changes.map(\.id)).count, changes.count,
                       "A task and its project are different rows and must not share state")
        XCTAssertEqual(change(.task, "a").id, change(.task, "a").id)
    }

    private func change(_ kind: Forecast.ChangeKind, _ id: String) -> Forecast.DueDateChange {
        .init(kind: kind, itemID: id, previousDate: nil, proposedDate: date(8))
    }
    private func completion(_ result: Forecast.Result, _ taskID: String) -> Date? {
        result.tasks.first { $0.task.id == taskID }?.completionDate
    }

    func testEveryTaskInAHardDeadlineProjectLeavesTheDateList() {
        let movable = Forecast.TaskInput(id: "movable", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(7))
        let other = Forecast.TaskInput(id: "other", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(7))

        let flexible = plan(tasks: [movable, other], project: .init(id: "p", outcome: 4, dueDate: date(30)))
        XCTAssertEqual(proposal(flexible, "movable"), date(8), "A flexible project proposes new dates as before")
        XCTAssertEqual(proposal(flexible, "other"), date(9))

        let fixed = plan(tasks: [movable, other], project: .init(id: "p", outcome: 10, dueDate: date(30)))
        for id in ["movable", "other"] {
            XCTAssertNil(proposal(fixed, id), "\(id) inherits the project's hard deadline, so it has no move to propose")
            XCTAssertFalse(fixed.reviewableConflicts.contains { $0.itemID == id },
                           "…and an inherited fixed date is not a conflict to review either")
            // No conflict at all now: an inherited 5 is reserved on its own due day, so its finish
            // equals its due date and there is nothing to report (report 2026-09-16_09-40-20).
            XCTAssertFalse(fixed.conflicts.contains { $0.itemID == id },
                           "\(id) sits on the day it is due, so there is nothing to refuse")
        }
        // Both tasks are held on the 7th, which is what reserves that day's capacity.
        XCTAssertEqual(fixed.changes.count, 0, "A hard-deadline project proposes no date changes at all")
    }

    func testATaskOutsideAnyProjectIsUntouchedByProjectRules() {
        let loose = Forecast.TaskInput(id: "loose", estimatedMinutes: 30, outcome: 4, dueDate: date(7))
        let owned = Forecast.TaskInput(id: "owned", projectID: "p", estimatedMinutes: 30, outcome: 4, dueDate: date(7))
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 30), day(9, workMinutes: 30)]
        let result = Forecast.calculate(days: days, projects: [.init(id: "p", outcome: 10, dueDate: date(8))],
                                        tasks: [loose, owned], calendar: calendar)
        let plan = Forecast.proposeWorkPlan(result, calendar: calendar)
        XCTAssertNotNil(proposal(plan, "loose"),
                        "A task with no project inherits nothing and is ceilinged by nothing")
        XCTAssertNil(proposal(plan, "owned"))
    }

    // MARK: The project's end date is a ceiling, not a hint

    func testAProposalPastTheProjectEndDateIsRefusedAndSaysWhy() {
        let plan = self.plan(tasks: [ceilingTask("first"), ceilingTask("second")],
                             project: .init(id: "p", outcome: 4, dueDate: date(8)))
        XCTAssertEqual(proposal(plan, "first"), date(8), "A proposal on the project's last day is allowed")
        XCTAssertNil(proposal(plan, "second"), "One past it is not")
        XCTAssertTrue(plan.reviewableConflicts.contains { $0.itemID == "second" && $0.reason == .projectEndDate },
                      "And the reason is shown rather than the row vanishing")
        XCTAssertFalse(ForecastText[.projectEndDate].isEmpty, "The reason has words to show")
    }

    func testAProjectWithNoEndDateImposesNoCeiling() {
        let plan = self.plan(tasks: [ceilingTask("first"), ceilingTask("second")],
                             project: .init(id: "p", outcome: 4, dueDate: nil))
        XCTAssertEqual(proposal(plan, "first"), date(8))
        XCTAssertEqual(proposal(plan, "second"), date(9),
                       "A nil end date is the absence of a ceiling, never an infinite one")
        XCTAssertFalse(plan.conflicts.contains { $0.reason == .projectEndDate })
    }

    func testTheCeilingAppliesEvenWhenTheTaskItselfIsFlexible() {
        // outcome 1 has no finite postponement allowance at all, so only the project's end date can
        // stop this task — which is the whole point of the ceiling being a separate rule.
        let plan = self.plan(tasks: [ceilingTask("first", outcome: 1), ceilingTask("second", outcome: 1)],
                             project: .init(id: "p", outcome: 1, dueDate: date(8)))
        XCTAssertNil(Forecast.postponementDays(outcome: 1), "…the band really is unlimited")
        XCTAssertTrue(plan.conflicts.contains { $0.itemID == "second" && $0.reason == .projectEndDate })
    }

    // MARK: What is left for a fixed project — the order

    func testOnlyProjectsThatFixTheirTasksOfferAnOrderAndTheyOfferItInWorkOrder() {
        // Room for all three tasks, so the order they appear in is the order they were planned in
        // rather than an artefact of one of them not fitting.
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 30), day(9, workMinutes: 30), day(10, workMinutes: 30)]
        let fixedTasks = [Forecast.TaskInput(id: "later", projectID: "fixed", estimatedMinutes: 30, outcome: 10, dueDate: date(9)),
                          Forecast.TaskInput(id: "sooner", projectID: "fixed", estimatedMinutes: 30, outcome: 10, dueDate: date(8))]
        let loose = Forecast.TaskInput(id: "loose", projectID: "open", estimatedMinutes: 30, outcome: 4, dueDate: date(7))
        let result = Forecast.calculate(days: days,
                                        projects: [.init(id: "fixed", outcome: 10, dueDate: date(30)),
                                                   .init(id: "open", outcome: 4, dueDate: date(30))],
                                        tasks: fixedTasks + [loose], calendar: calendar)
        let orders = Forecast.fixedProjectOrders(in: result, calendar: calendar)
        XCTAssertEqual(orders.map(\.projectID), ["fixed"], "A project that can still move its dates is not on this list")
        XCTAssertEqual(orders.first?.endDate, date(30))
        XCTAssertEqual(orders.first?.taskIDs, ["sooner", "later"], "Listed in the order the forecast will work them")
    }

    /// Opened from the Tasks list the plan spans the whole portfolio, so SEVERAL fixed projects can
    /// appear at once (report 2026-09-16_06-38-30). Each must stay its own group with its own
    /// ceiling: tasks must not pool into one list, and one project's end date must never be shown
    /// against another's work.
    func testSeveralFixedProjectsEachKeepTheirOwnGroupAndTheirOwnCeiling() throws {
        let days = (7...12).map { day($0, workMinutes: $0 == 7 ? 0 : 30) }
        let tasks = [
            Forecast.TaskInput(id: "a2", projectID: "alpha", estimatedMinutes: 30, outcome: 10, dueDate: date(9)),
            Forecast.TaskInput(id: "a1", projectID: "alpha", estimatedMinutes: 30, outcome: 10, dueDate: date(8)),
            Forecast.TaskInput(id: "b1", projectID: "beta", estimatedMinutes: 30, outcome: 10, dueDate: date(8)),
            Forecast.TaskInput(id: "c1", projectID: "gamma", estimatedMinutes: 30, outcome: 4, dueDate: date(8)),
        ]
        let result = Forecast.calculate(days: days, projects: [
            .init(id: "alpha", outcome: 10, dueDate: date(20)),
            .init(id: "beta", outcome: 10, dueDate: nil),
            .init(id: "gamma", outcome: 4, dueDate: date(20)),
        ], tasks: tasks, calendar: calendar)

        let orders = Forecast.fixedProjectOrders(in: result, calendar: calendar)
        XCTAssertEqual(Set(orders.map(\.projectID)), ["alpha", "beta"],
                       "Only the projects that fix their tasks; the flexible one still reschedules by date")
        let alpha = try XCTUnwrap(orders.first { $0.projectID == "alpha" })
        let beta = try XCTUnwrap(orders.first { $0.projectID == "beta" })
        XCTAssertEqual(alpha.taskIDs, ["a1", "a2"], "alpha lists only its own tasks, in work order")
        XCTAssertEqual(beta.taskIDs, ["b1"], "…and beta only its own")
        XCTAssertEqual(alpha.endDate, date(20))
        XCTAssertNil(beta.endDate, "A project with no end date shows no ceiling, not its neighbour's")
        XCTAssertFalse(orders.contains { $0.taskIDs.contains("c1") },
                       "A flexible project's task never appears in the order-only section")
    }

    /// Reordering is per project even when several are on screen: a swap may only ever exchange two
    /// dates inside one group, so moving alpha's first task cannot reach beta's.
    func testReorderingStaysInsideOneProjectWhenSeveralAreListed() throws {
        let alpha = [Forecast.DatedTask(id: "a1", dueDate: date(8)), Forecast.DatedTask(id: "a2", dueDate: date(9))]
        let swap = try XCTUnwrap(Forecast.reorder(alpha, moving: "a2", earlier: true))
        XCTAssertEqual(swap.map(\.id).sorted(), ["a1", "a2"])
        XCTAssertNil(Forecast.reorder(alpha, moving: "b1", earlier: true),
                     "Another project's task is not in this group and cannot be moved through it")
    }

    func testMovingATaskEarlierSwapsTheTwoDueDatesAndInventsNothing() {
        let ordered = [Forecast.DatedTask(id: "a", dueDate: date(8)),
                       Forecast.DatedTask(id: "b", dueDate: date(9)),
                       Forecast.DatedTask(id: "c", dueDate: date(10))]
        XCTAssertEqual(Forecast.reorder(ordered, moving: "b", earlier: true),
                       [.init(id: "b", dueDate: date(8)), .init(id: "a", dueDate: date(9))])
        XCTAssertEqual(Forecast.reorder(ordered, moving: "b", earlier: false),
                       [.init(id: "b", dueDate: date(10)), .init(id: "c", dueDate: date(9))])
        XCTAssertNil(Forecast.reorder(ordered, moving: "a", earlier: true), "Nothing above the first row")
        XCTAssertNil(Forecast.reorder(ordered, moving: "c", earlier: false), "Nothing below the last")
        XCTAssertNil(Forecast.reorder(ordered, moving: "missing", earlier: true))
    }

    func testAReorderNeverClearsADeadlineOrWritesTwoNoOps() {
        let sameDay = [Forecast.DatedTask(id: "a", dueDate: date(8)), Forecast.DatedTask(id: "b", dueDate: date(8))]
        XCTAssertNil(Forecast.reorder(sameDay, moving: "b", earlier: true), "Swapping equal dates would write two no-ops")
        let undated = [Forecast.DatedTask(id: "a", dueDate: nil), Forecast.DatedTask(id: "b", dueDate: date(8))]
        XCTAssertNil(Forecast.reorder(undated, moving: "b", earlier: true),
                     "A reorder must never be the thing that clears a task's deadline")
    }

    /// The two serialisations of the SAME row, as production returned them on 2026-09-15 within the
    /// same minute. The only difference that matters is `updated_at`, present in one and absent from
    /// the other — which is the entire bug.
    private func listRow() throws -> ToDoTask {
        try JSONDecoder().decode(ToDoTask.self, from: Data("""
        {"id":"e3db766e","created_at":"2026-09-01T19:25:14.457Z","project_id":"30f9237d",\
        "title":"Finder quick look should not be allowed by default","due_date":"2026-09-24T14:00:00.000Z",\
        "eisenhower_quadrant":4,"outcome":1,"perspiration_level":1,"status":"NOT_STARTED","duration":"0",\
        "top_score":0.1,"tags":[],"subtasks":[]}
        """.utf8))
    }
    private func byIDsRow() throws -> ToDoTask {
        try JSONDecoder().decode(ToDoTask.self, from: Data("""
        {"id":"e3db766e","updated_at":"2026-09-15T01:19:47.838Z","project_id":"30f9237d",\
        "title":"Finder quick look should not be allowed by default","due_date":"2026-09-24T14:00:00.000Z",\
        "eisenhower_quadrant":4,"outcome":1,"perspiration_level":1,"status":"NOT_STARTED","duration":"0",\
        "tags":[],"subtasks":[]}
        """.utf8))
    }
    /// Two of these fill the only two days with room, so the second necessarily lands on day 9.
    private func ceilingTask(_ id: String, outcome: Int = 4) -> Forecast.TaskInput {
        Forecast.TaskInput(id: id, projectID: "p", estimatedMinutes: 30, outcome: outcome, dueDate: date(7))
    }

    func testMatchingDueDateDoesNotOfferASeparatePlacementCorrection() {
        let task = Forecast.TaskInput(id: "placed", estimatedMinutes: 30, outcome: 6,
                                      dueDate: date(8), notBefore: date(7))
        let result = Forecast.calculate(days: [day(7, workMinutes: 0), day(8, workMinutes: 30)],
                                        projects: [], tasks: [task], calendar: calendar)
        XCTAssertNil(proposal(Forecast.proposeWorkPlan(result, calendar: calendar), "placed"))
    }

    func testMatchingDueDateDoesNotOfferAnImmovableLockedPlacement() {
        let task = Forecast.TaskInput(id: "locked", estimatedMinutes: 30, outcome: 6,
                                      dueDate: date(8), notBefore: date(7))
        var locked = day(7, workMinutes: 0)
        locked.isLocked = true
        let result = Forecast.calculate(days: [locked, day(8, workMinutes: 30)],
                                        projects: [], tasks: [task], calendar: calendar)
        XCTAssertNil(proposal(Forecast.proposeWorkPlan(result, calendar: calendar), "locked"))
    }

    // MARK: Fixtures

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        value.firstWeekday = 2
        return value
    }
    private func date(_ day: Int, month: Int = 9, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }
    /// Explicit two-hour additional-care fixture plus awake meeting time leaves the requested budget.
    private func day(_ day: Int, workMinutes: Double) -> Forecast.DayInput {
        let awake = date(day, hour: 6)
        let meeting = Forecast.Interval(start: awake, end: awake.addingTimeInterval((840 - workMinutes) * 60))
        return Forecast.DayInput(date: date(day), meetings: [meeting], habits: [], settings: .init(selfCareMinutes: 120))
    }
    /// Three near-empty days then room on the ninth, so the order tasks are planned in decides which
    /// day each one lands on — which is exactly what an outcome edit changes.
    private func plan(tasks: [Forecast.TaskInput], project: Forecast.ProjectInput) -> Forecast.WorkPlan {
        let days = [day(7, workMinutes: 0), day(8, workMinutes: 30), day(9, workMinutes: 30)]
        let result = Forecast.calculate(days: days, projects: [project], tasks: tasks, calendar: calendar)
        return Forecast.proposeWorkPlan(result, calendar: calendar)
    }
    private func proposal(_ plan: Forecast.WorkPlan, _ taskID: String) -> Date? {
        plan.changes.first { $0.kind == .task && $0.itemID == taskID }?.proposedDate
    }

    /// A store with a real snapshot: one project, one overdue one-minute task. Overdue is the point —
    /// its completion date is necessarily later than its due date whatever the machine's own calendar
    /// and routines say, so it is always proposed for a new date until it is pinned.
    /// The developer's own `locksPlannedDays`, put back after each test. These run in the
    /// app-hosted target and share its UserDefaults, so without this the suite both READS and
    /// OVERWRITES a real preference.
    private var storedPlannedDaysLock: Any?

    override func setUp() {
        super.setUp()
        storedPlannedDaysLock = UserDefaults.standard.object(forKey: LocalForecastStore.locksPlannedDaysKey)
        UserDefaults.standard.set(true, forKey: LocalForecastStore.locksPlannedDaysKey)
    }

    override func tearDown() {
        if let stored = storedPlannedDaysLock {
            UserDefaults.standard.set(stored, forKey: LocalForecastStore.locksPlannedDaysKey)
        } else {
            UserDefaults.standard.removeObject(forKey: LocalForecastStore.locksPlannedDaysKey)
        }
        super.tearDown()
    }

    private func loadedStore(writeOutcome: @escaping LocalForecastStore.OutcomeWriter = { _, _, _, done in done(true) },
                             onProjectsPage: @escaping () -> Void = {}) throws -> LocalForecastStore {
        let projects = try JSONDecoder().decode(ProjectsPage.self, from: Data(
            #"{"data":[{"id":"alpha","name":"Alpha"}],"meta":{"page":1,"itemCount":1,"hasNextPage":false}}"#.utf8))
        let yesterday = ToDoDates.ymd(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        let tasksJSON = """
        {"data":[{"id":"overdue","title":"Overdue task","status":"NOT_STARTED","eisenhower_quadrant":1,\
        "duration":60,"outcome":4,"project_id":"alpha","due_date":"\(yesterday)"}],\
        "meta":{"page":1,"itemCount":1,"hasNextPage":false,"excludesCompleted":true}}
        """
        let tasks = try JSONDecoder().decode(AllApi.ForecastTasksPage.self, from: Data(tasksJSON.utf8))
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { false },
            readProjects: { page, _, complete in onProjectsPage(); complete(page == 1 ? projects : nil) },
            readTasks: { page, _, complete in complete(page == 1 ? tasks : nil) },
            writeOutcome: writeOutcome, diagnostic: { _ in })
        // Pin the today/tomorrow lock instead of inheriting it.
        //
        // `locksPlannedDays` is read from UserDefaults, and these tests run in the app-hosted test
        // target — so they were reading the DEVELOPER'S OWN preference. Unticking that checkbox in
        // the running app (which the user did, and reported) unlocks today, overdue work then earns
        // a placement correction, and two tests here started failing. The self-hosted CI runner is
        // the same Mac, so integration's Unit Tests went red because of a checkbox in the UI.
        //
        // A test must not depend on a user preference — nor CHANGE one. Assigning
        // `store.locksPlannedDays` persists through its `didSet`, so the first version of this fix
        // silently re-ticked the developer's checkbox (verified: the stored value went 0 → 1).
        // Write the key before the store reads it at init, and put the user's value back afterwards.
        // The key is already pinned in setUp, so the store read `true` at init; assigning here
        // would persist through `didSet` and clobber the real preference.
        store.horizonDays = ForecastReschedulingTests.testHorizonDays
        let loaded = expectation(description: "Forecast snapshot")
        store.refresh { success in XCTAssertTrue(success); loaded.fulfill() }
        wait(for: [loaded], timeout: 20)
        XCTAssertNotNil(store.result)
        return store
    }
    /// The smallest horizon `buildDays` will build, so the fixture does not price ninety days of
    /// routines to answer a question about one overdue task.
    private static let testHorizonDays = 7

    private func drainCallbacks() {
        let drained = expectation(description: "Outcome write callback")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 5)
    }

    // MARK: Fixed-order projects due soon come first (report 2026-09-21_07-45-21, follow-up)
    //
    // "maybe because they were in the bottom section of tasks that can't be moved? We should bring
    // those up higher - at least the ones due in the next two weeks."
    //
    // They sit at the bottom because they cannot be date-moved, only reordered. That is right for a
    // project due in three months and wrong for one due next week.

    private typealias Priority = LocalTimeForecast.FixedProjectPriority

    private func group(_ id: String, endingInDays days: Int?, now: Date) -> LocalTimeForecast.FixedProjectOrder {
        let end = days.map { Calendar.current.date(byAdding: .day, value: $0, to: now)! }
        return LocalTimeForecast.FixedProjectOrder(projectID: id, endDate: end, taskIDs: [])
    }

    func testDeadlinesInsideTheFortnightComeFirst() {
        let now = Date()
        let groups = [group("far", endingInDays: 60, now: now),
                      group("soon", endingInDays: 3, now: now)]
        XCTAssertEqual(Priority.prioritised(groups, now: now).map(\.projectID), ["soon", "far"])
    }

    func testTheBoundaryIsTwoWeeks() {
        let now = Date()
        let groups = [group("justOutside", endingInDays: Priority.soonDays + 1, now: now),
                      group("justInside", endingInDays: Priority.soonDays, now: now)]
        XCTAssertEqual(Priority.prioritised(groups, now: now).map(\.projectID),
                       ["justInside", "justOutside"])
    }

    /// Overdue is the most pressing case there is; it must not fall through to the bottom for being
    /// a negative number of days away.
    func testOverdueProjectsAreTreatedAsSoon() {
        let now = Date()
        let groups = [group("later", endingInDays: 30, now: now),
                      group("overdue", endingInDays: -5, now: now)]
        XCTAssertEqual(Priority.prioritised(groups, now: now).map(\.projectID), ["overdue", "later"])
    }

    func testAProjectWithNoEndDateIsNotPressing() {
        let now = Date()
        let groups = [group("none", endingInDays: nil, now: now),
                      group("soon", endingInDays: 2, now: now)]
        XCTAssertEqual(Priority.prioritised(groups, now: now).map(\.projectID), ["soon", "none"])
    }

    /// Both halves keep their existing order, so the sequence stays stable across recalculations
    /// rather than shuffling under the user between renders.
    func testOrderWithinEachHalfIsPreserved() {
        let now = Date()
        let groups = [group("soonA", endingInDays: 1, now: now),
                      group("farA", endingInDays: 40, now: now),
                      group("soonB", endingInDays: 5, now: now),
                      group("farB", endingInDays: 50, now: now)]
        XCTAssertEqual(Priority.prioritised(groups, now: now).map(\.projectID),
                       ["soonA", "soonB", "farA", "farB"])
    }

    func testNothingIsDroppedOrDuplicated() {
        let now = Date()
        let groups = (1...6).map { group("p\($0)", endingInDays: $0 * 10, now: now) }
        let result = Priority.prioritised(groups, now: now)
        XCTAssertEqual(Set(result.map(\.projectID)), Set(groups.map(\.projectID)))
        XCTAssertEqual(result.count, groups.count, "ordering only — nothing is hidden")
    }

}
