//
//  FocusStartTests.swift
//  Focus BearTests
//
//  The pure logic behind the focus-session start flow: how a duration resolves (including the
//  untimed session), the strictness mapping, the accordion summary lines, the Start button's label,
//  and which screen a given geek-mode flag lands you on.
//

import XCTest
@testable import Focus_Bear

final class FocusStartTests: XCTestCase {

    /// The English fallbacks, so the assertions don't depend on whatever config.json ships.
    private let strings = FocusStartStrings()

    // MARK: - Duration

    func testTimedSessionUsesTheMinutesTheUserPicked() {
        let duration = FocusStartDuration(minutes: 45)
        XCTAssertEqual(duration.effectiveMinutes, 45)
        XCTAssertEqual(duration.hoursComponent, 0)
        XCTAssertEqual(duration.minutesComponent, 45)
    }

    func testHoursAndMinutesSplitOnTheHour() {
        let duration = FocusStartDuration(minutes: 90)
        XCTAssertEqual(duration.hoursComponent, 1)
        XCTAssertEqual(duration.minutesComponent, 30)
    }

    func testUntimedSessionRunsForTwelveHours() {
        let duration = FocusStartDuration(minutes: 25, isUntimed: true)
        XCTAssertEqual(duration.effectiveMinutes, 12 * 60,
                       "Untimed is presented as ∞ but is really a 12-hour session, so endFocusModeTime still exists.")
        XCTAssertEqual(FocusStartDuration.untimedSessionMinutes, 720)
    }

    func testUntimedSessionKeepsTheUnderlyingMinutesForWhenItIsSwitchedBackOff() {
        var duration = FocusStartDuration(minutes: 25, isUntimed: true)
        XCTAssertEqual(duration.minutes, 25)
        duration.isUntimed = false
        XCTAssertEqual(duration.effectiveMinutes, 25)
    }

    func testEffectiveMinutesNeverFallsBelowTheAppsOneMinuteFloor() {
        XCTAssertEqual(FocusStartDuration(minutes: 0).effectiveMinutes, FocusStartDuration.minimumMinutes)
        XCTAssertEqual(FocusStartDuration(minutes: -10).effectiveMinutes, FocusStartDuration.minimumMinutes)
    }

    func testSteppingMovesInFiveMinuteStepsAndClampsAtBothEnds() {
        XCTAssertEqual(FocusStartDuration(minutes: 25).stepped(by: 1).minutes, 30)
        XCTAssertEqual(FocusStartDuration(minutes: 25).stepped(by: -1).minutes, 20)
        XCTAssertEqual(FocusStartDuration(minutes: 2).stepped(by: -1).minutes, FocusStartDuration.minimumMinutes)
        XCTAssertEqual(FocusStartDuration(minutes: 8 * 60).stepped(by: 1).minutes, FocusStartDuration.maximumMinutes)
    }

    func testSteppingAnUntimedSessionKeepsItUntimed() {
        XCTAssertTrue(FocusStartDuration(minutes: 25, isUntimed: true).stepped(by: 1).isUntimed)
    }

    func testSliderFractionSpansTheZeroToEightHourTrack() {
        XCTAssertEqual(FocusStartDuration(minutes: 0).sliderFraction, 0, accuracy: 0.0001)
        XCTAssertEqual(FocusStartDuration(minutes: 4 * 60).sliderFraction, 0.5, accuracy: 0.0001)
        XCTAssertEqual(FocusStartDuration(minutes: 8 * 60).sliderFraction, 1, accuracy: 0.0001)
    }

    func testSliderFractionIsClampedForOutOfRangeDurations() {
        XCTAssertEqual(FocusStartDuration(minutes: 20 * 60).sliderFraction, 1, accuracy: 0.0001)
        XCTAssertEqual(FocusStartDuration(minutes: -60).sliderFraction, 0, accuracy: 0.0001)
    }

    func testDraggingTheSliderAllowsAnyWholeMinute() {
        // #2596: the slider is fine-grained, not snapped to the 5-minute stepper grid — 0.1 of 480
        // minutes is 48 (was snapped to 50), and non-multiples of five like 17 / 19 are reachable.
        XCTAssertEqual(FocusStartDuration.fromSliderFraction(0.1).minutes, 48)
        XCTAssertEqual(FocusStartDuration.fromSliderFraction(17.0 / Double(FocusStartDuration.maximumMinutes)).minutes, 17)
        XCTAssertEqual(FocusStartDuration.fromSliderFraction(19.0 / Double(FocusStartDuration.maximumMinutes)).minutes, 19)
        XCTAssertEqual(FocusStartDuration.fromSliderFraction(1).minutes, FocusStartDuration.maximumMinutes)
        XCTAssertEqual(FocusStartDuration.fromSliderFraction(0).minutes, FocusStartDuration.minimumMinutes)
    }

    func testDraggingBeyondTheTrackIsClamped() {
        XCTAssertEqual(FocusStartDuration.fromSliderFraction(3).minutes, FocusStartDuration.maximumMinutes)
        XCTAssertEqual(FocusStartDuration.fromSliderFraction(-2).minutes, FocusStartDuration.minimumMinutes)
    }

    // MARK: - Readout and button label

    func testClockIsPaddedToTwoDigits() {
        let formatter = FocusStartDurationFormatter(strings: strings)
        let clock = formatter.clockComponents(for: FocusStartDuration(minutes: 25))
        XCTAssertEqual(clock?.hours, "00")
        XCTAssertEqual(clock?.minutes, "25")
    }

    func testUntimedSessionHasNoClockToDraw() {
        let formatter = FocusStartDurationFormatter(strings: strings)
        XCTAssertNil(formatter.clockComponents(for: FocusStartDuration(minutes: 25, isUntimed: true)))
    }

    func testStartButtonNamesTheSessionLength() {
        let formatter = FocusStartDurationFormatter(strings: strings)
        XCTAssertEqual(formatter.startButtonTitle(for: FocusStartDuration(minutes: 25)), "Start a 25 min session")
        XCTAssertEqual(formatter.startButtonTitle(for: FocusStartDuration(minutes: 60)), "Start a 1 hr session")
        XCTAssertEqual(formatter.startButtonTitle(for: FocusStartDuration(minutes: 90)), "Start a 1 hr 30 min session")
    }

    func testStartButtonSaysUntimedRatherThanTwelveHours() {
        let formatter = FocusStartDurationFormatter(strings: strings)
        let title = formatter.startButtonTitle(for: FocusStartDuration(minutes: 25, isUntimed: true))
        XCTAssertEqual(title, strings.startUntimedButton)
        XCTAssertFalse(title.contains("12"), "The 12-hour cap is an implementation detail, not something the button says.")
    }

    func testSpanishTitleCanIntentionallyOmitTheEnglishSuffix() {
        let previous = configjson
        defer { configjson = previous }
        configjson = ["focusStartVcInfo": [
            "titleAdvancedPrefix": "Inicia una sesión de concentración ",
            "titleAdvancedEmphasis": "avanzada",
            "titleAdvancedSuffix": "",
        ]] as NSDictionary
        let localized = FocusStartStrings.load()
        XCTAssertEqual(localized.advancedTitlePrefix + localized.advancedTitleEmphasis + localized.advancedTitleSuffix,
                       "Inicia una sesión de concentración avanzada")
    }

    // MARK: - Strictness

    func testStrictnessKeepsTheStoredOneTwoThreeValues() {
        XCTAssertEqual(FocusStartStrictness.junior.storedValue, 1)
        XCTAssertEqual(FocusStartStrictness.captain.storedValue, 2)
        XCTAssertEqual(FocusStartStrictness.pawfessor.storedValue, 3)
    }

    func testStrictnessRoundTripsThroughItsStoredValue() {
        for level in FocusStartStrictness.allCases {
            XCTAssertEqual(FocusStartStrictness.fromStored(level.storedValue), level)
        }
    }

    func testUnknownStoredStrictnessFallsBackToTheGentlestLevel() {
        XCTAssertEqual(FocusStartStrictness.fromStored(0), .junior)
        XCTAssertEqual(FocusStartStrictness.fromStored(99), .junior)
    }

    func testStrictnessLabelsAreTheDesignsNames() {
        XCTAssertEqual(strings.strictnessTitle(.junior), "Junior 🐻")
        XCTAssertEqual(strings.strictnessDescription(.junior), "Stop any time")
        XCTAssertEqual(strings.strictnessDescription(.captain), "15 sec delay")
        XCTAssertEqual(strings.strictnessDescription(.pawfessor), "No Stopping")
    }

    // MARK: - Accordion summaries

    func testDurationSummaryReadsMinutesAndBreaks() {
        let builder = FocusStartSummaryBuilder(strings: strings)
        let summary = builder.durationSummary(duration: FocusStartDuration(minutes: 25), breakCount: 1)
        XCTAssertEqual(summary, "25 mins · 1 break")
    }

    func testDurationSummaryPluralisesBreaks() {
        let builder = FocusStartSummaryBuilder(strings: strings)
        XCTAssertEqual(builder.durationSummary(duration: FocusStartDuration(minutes: 25), breakCount: 0),
                       "25 mins · 0 breaks")
    }

    func testUntimedDurationSummarySaysUntimedRatherThanAMinuteCount() {
        let builder = FocusStartSummaryBuilder(strings: strings)
        let summary = builder.durationSummary(duration: FocusStartDuration(minutes: 25, isUntimed: true), breakCount: 1)
        XCTAssertEqual(summary, "Untimed · 1 break")
    }

    func testGoalSummaryFallsBackToNoGoal() {
        let builder = FocusStartSummaryBuilder(strings: strings)
        XCTAssertEqual(builder.goalSummary(goal: "", taskCount: 0), "No Goal · 0 tasks")
        XCTAssertEqual(builder.goalSummary(goal: "   \n ", taskCount: 0), "No Goal · 0 tasks")
    }

    func testGoalSummaryUsesTheTypedGoalAndPluralisesTasks() {
        let builder = FocusStartSummaryBuilder(strings: strings)
        XCTAssertEqual(builder.goalSummary(goal: "Ship the release", taskCount: 1), "Ship the release · 1 task")
        XCTAssertEqual(builder.goalSummary(goal: "Ship the release", taskCount: 3), "Ship the release · 3 tasks")
    }

    func testBlockingSummaryPairsTheListWithTheStrictnessName() {
        let builder = FocusStartSummaryBuilder(strings: strings)
        XCTAssertEqual(builder.blockingSummary(blockListName: "Block super distracting apps/websites",
                                               strictness: .junior),
                       "Block super distracting apps/websites · Junior 🐻")
    }

    func testBlockingSummaryDropsTheSeparatorWhenThereIsNoBlockList() {
        let builder = FocusStartSummaryBuilder(strings: strings)
        XCTAssertEqual(builder.blockingSummary(blockListName: "", strictness: .captain), "Captain 🏴‍☠️")
    }

    // MARK: - Which screen, and switching between them

    func testGeekModeDecidesWhichScreenYouLandOn() {
        XCTAssertEqual(FocusStartMode.forGeekMode(true), .advanced)
        XCTAssertEqual(FocusStartMode.forGeekMode(false), .simple)
    }

    func testFollowingTheLinkFlipsGeekMode() {
        XCTAssertTrue(FocusStartMode.simple.geekModeAfterFollowingLink,
                      "'Extra Powerful Options' turns geek mode on.")
        XCTAssertFalse(FocusStartMode.advanced.geekModeAfterFollowingLink,
                       "'Regular Options' turns geek mode off.")
    }

    func testTheTwoModesPointAtEachOther() {
        XCTAssertEqual(FocusStartMode.simple.other, .advanced)
        XCTAssertEqual(FocusStartMode.advanced.other, .simple)
    }

    func testFollowingBothLinksReturnsYouToWhereYouStarted() {
        let start = FocusStartMode.simple
        let afterFirstLink = FocusStartMode.forGeekMode(start.geekModeAfterFollowingLink)
        let afterSecondLink = FocusStartMode.forGeekMode(afterFirstLink.geekModeAfterFollowingLink)
        XCTAssertEqual(afterSecondLink, start)
    }

    // MARK: - Break duration

    func testBreakDurationFollowsTheWorkToBreakRatio() {
        let state = FocusStartState()
        state.duration = FocusStartDuration(minutes: 25)
        state.recomputeBreakDuration(workRatio: 5, breakRatio: 1)
        XCTAssertEqual(state.breakDurationMinutes, 5)
    }

    func testBreakDurationNeverDropsBelowOneMinute() {
        let state = FocusStartState()
        state.duration = FocusStartDuration(minutes: 2)
        state.recomputeBreakDuration(workRatio: 5, breakRatio: 1)
        XCTAssertEqual(state.breakDurationMinutes, 1)
    }

    func testZeroRatiosAreTreatedAsOneRatherThanDividingByZero() {
        let state = FocusStartState()
        state.duration = FocusStartDuration(minutes: 30)
        state.recomputeBreakDuration(workRatio: 0, breakRatio: 0)
        XCTAssertEqual(state.breakDurationMinutes, 30)
    }

    // MARK: - Scaling

    func testTheDesignFrameRendersAtExactlyOneToOne() {
        let scale = FocusStartScale(contentWidth: FocusStartTokens.designWidthPoints)
        XCTAssertEqual(scale.factor, 1, accuracy: 0.0001)
        XCTAssertEqual(scale.pt(96), 48, accuracy: 0.0001, "A 96px design measurement is 48pt at 2×.")
    }

    func testNarrowWindowsStopShrinkingAtTheLegibilityFloor() {
        let scale = FocusStartScale(contentWidth: 200)
        XCTAssertEqual(scale.factor, FocusStartTokens.minimumScaleFactor, accuracy: 0.0001)
    }

    func testWideWindowsCentreRatherThanScaleUp() {
        let scale = FocusStartScale(contentWidth: FocusStartTokens.designWidthPoints * 3)
        XCTAssertEqual(scale.factor, FocusStartTokens.maximumScaleFactor, accuracy: 0.0001)
    }

    func testProjectDefaultMatchesDayPlanOrderRatherThanImportance() throws {
        let projects = try workProjects([["id": "a", "name": "Alpha", "importance": 4],
                                        ["id": "b", "name": "Beta", "importance": 1]])
        let plan = [DayPlanTask(title: "Top", project: "Beta", projectID: "b"),
                    DayPlanTask(title: "Later", project: "Alpha", projectID: "a")]
        XCTAssertEqual(FocusStartWorkSelection.topDayPlanProject(projects, dayPlan: plan)?.id, "b")
        XCTAssertEqual(FocusStartWorkSelection.projects(projects, dayPlan: plan).map { $0.id }, ["b", "a"])
    }

    func testProjectDefaultNeverGuessesBetweenDuplicateNames() throws {
        let projects = try workProjects([["id": "a", "name": "Research"], ["id": "b", "name": "Research"]])
        XCTAssertNil(FocusStartWorkSelection.topDayPlanProject(projects, dayPlan: [DayPlanTask(title: "Old task", project: "Research")]))
        XCTAssertEqual(FocusStartWorkSelection.topDayPlanProject(projects, dayPlan: [DayPlanTask(title: "Linked", project: "Old name", projectID: "b")])?.id, "b")
    }

    func testProjectDefaultSkipsCompletedAndUnlinkedTasks() throws {
        let projects = try workProjects([["id": "a", "name": "Alpha"], ["id": "b", "name": "Beta"]])
        let plan = [DayPlanTask(title: "Done", done: true, projectID: "a"),
                    DayPlanTask(title: "No project"), DayPlanTask(title: "Next", projectID: "b")]
        XCTAssertEqual(FocusStartWorkSelection.topDayPlanProject(projects, dayPlan: plan)?.id, "b")
    }

    /// Report 2026-09-11_09-27-50: the rows show a TOP score, so the list must be in TOP order.
    /// The selected project still comes first; the Day Plan's hand-arranged order does not apply here.
    func testTaskSearchPrioritizesSelectedProjectThenTopScoreAndOmitsCompleted() throws {
        let project = try workProjects([["id": "p", "name": "Project"]])[0]
        let tasks = try workTasks([["id": "other", "title": "Other", "project_id": "q", "outcome": 10],
                                  ["id": "later", "title": "Later", "project_id": "p", "outcome": 10],
                                  ["id": "top", "title": "Top", "project_id": "p", "outcome": 1],
                                  ["id": "done", "title": "Done", "project_id": "p", "status": "COMPLETED"]])
        let result = FocusStartWorkSelection.tasks(tasks, project: project,
            dayPlan: [DayPlanTask(title: "Top", sourceTaskId: "top"), DayPlanTask(title: "Duplicate local copy", sourceTaskId: "top")])
        XCTAssertEqual(result.map { $0.id }, ["later", "top", "other"],
                       "Being on the Day Plan no longer outranks a higher TOP score")
    }

    func testTaskSearchUsesSyncedProjectIdentity() throws {
        let project = try workProjects([["id": "p", "name": "External", "synced_project_id": "external"]])[0]
        let tasks = try workTasks([["id": "other", "title": "Other", "outcome": 10],
                                  ["id": "linked", "title": "Linked", "synced_project_id": "external", "outcome": 1]])
        XCTAssertEqual(FocusStartWorkSelection.tasks(tasks, project: project, dayPlan: []).first?.id, "linked")
    }

    func testSelectedTodoIDsAndOrderReachSessionQueue() throws {
        let projects = try workProjects([["id": "p", "name": "Project"]])
        let tasks = try workTasks([["id": "first", "title": "First", "project_id": "p", "duration": 900],
                                  ["id": "second", "title": "Second", "project_id": "p"]])
        let queue = FocusSessionTaskQueue.decode(FocusStartWorkSelection.sessionQueue(tasks, projects: projects))
        XCTAssertEqual(queue.map { $0.id }, ["first", "second"])
        XCTAssertEqual(queue.first?.durationSeconds, 900)
        XCTAssertEqual(queue.first?.projectName, "Project")
        XCTAssertEqual(queue.filter { $0.isActive }.map { $0.id }, ["first"])
        XCTAssertTrue(FocusSessionTaskQueue.decode(FocusStartWorkSelection.sessionQueue([], projects: projects)).isEmpty)
    }

    /// Report 2026-09-17_13-52-53: "if I click + this view collapses and I have to click add task
    /// again". Queueing a task must leave the picker ready for the next one.
    func testAddingATaskLeavesTheSearchOpenAndClearedForTheNextOne() throws {
        let state = FocusStartState()
        let tasks = try workTasks([["id": "first", "title": "Write up spec"],
                                   ["id": "second", "title": "Set up staging"]])
        state.taskQuery = "spec"
        state.selectTask(tasks[0])
        XCTAssertTrue(state.showsTaskSearch, "The search stays open so the next task is one click away")
        XCTAssertTrue(state.taskQuery.isEmpty,
                      "The words that found this task only hide the next one, so the query is cleared")
        state.selectTask(tasks[1])
        XCTAssertEqual(state.selectedTasks.map { $0.id }, ["first", "second"],
                       "Both tasks queue without reopening the search in between")
        XCTAssertTrue(state.showsTaskSearch)
    }

    /// The other half: the search is still closeable, so the card can go back to being compact.
    func testTheUserCanCloseTheTaskSearchOnceTheyAreDone() throws {
        let state = FocusStartState()
        state.selectTask(try workTasks([["id": "task", "title": "Task"]])[0])
        state.hideTaskSearch()
        XCTAssertFalse(state.showsTaskSearch)
        XCTAssertEqual(state.selectedTasks.count, 1, "Closing the search keeps what was queued")
    }

    func testCollapsedWorkSelectionKeepsTheTaskQueueWhileEditingTheGoal() throws {
        let state = FocusStartState()
        let project = try workProjects([["id": "p", "name": "Project"]])[0]
        state.projects = [project]
        state.selectProject(project)
        XCTAssertFalse(state.showsProjectSearch)
        let task = try workTasks([["id": "task", "title": "Task", "project_id": "p"]])[0]
        state.selectTask(task)
        // Re-encoding a dictionary can reorder JSON keys without changing the task queue.
        // Compare every serialized field and the array order, independent of object key order.
        func serializedQueue() throws -> NSArray {
            try XCTUnwrap(JSONSerialization.jsonObject(with: Data(state.sessionTaskQueue.utf8)) as? NSArray)
        }
        let queue = try serializedQueue()
        // Adding a task leaves the search open now (report 2026-09-17_13-52-53); collapsing it is the
        // user's own action, and collapsing must not disturb what they have already queued.
        XCTAssertTrue(state.showsTaskSearch)
        state.hideTaskSearch()
        XCTAssertFalse(state.showsTaskSearch)
        XCTAssertEqual(try serializedQueue(), queue)
        state.isTaskSearchExpanded = true
        XCTAssertTrue(state.showsTaskSearch)
        XCTAssertEqual(try serializedQueue(), queue)
        state.editGoal()
        XCTAssertTrue(state.showsProjectSearch)
        state.projectQuery = ""
        XCTAssertFalse(state.canChooseDayPlanDefault, "An active edit must survive a late default response")
        XCTAssertEqual(try serializedQueue(), queue)
    }

    func testClearingTheGoalClearsSelectionAndDoesNotRestoreAnAutomaticDefault() throws {
        let state = FocusStartState()
        state.selectProject(try workProjects([["id": "p", "name": "Project"]])[0])
        state.selectTask(try workTasks([["id": "task", "title": "Task"]])[0])
        state.clearGoal()
        XCTAssertNil(state.selectedProjectID)
        XCTAssertTrue(state.goal.isEmpty)
        XCTAssertTrue(state.selectedTasks.isEmpty)
        XCTAssertTrue(state.taskSelectionChanged)
        XCTAssertTrue(state.showsProjectSearch)
        XCTAssertTrue(state.showsTaskSearch)
        XCTAssertFalse(state.canChooseDayPlanDefault)
    }

    func testContinuingSuperFocusKeepsTheExistingQueueUntilSelectionChanges() throws {
        let previous = focusModeTaskString
        defer { focusModeTaskString = previous }
        focusModeTaskString = "[{\"id\":\"running\",\"isPlaying\":true,\"duration\":342}]"
        let state = FocusStartState()
        state.isContinuingSuperFocusRun = true
        state.selectedTasks = try workTasks([["id": "new", "title": "New selection"]])
        XCTAssertEqual(state.taskQueueForSessionStart, focusModeTaskString)
        state.taskSelectionChanged = true
        let data = try XCTUnwrap(state.taskQueueForSessionStart.data(using: .utf8))
        XCTAssertEqual(try JSONDecoder().decode([ToDoTask].self, from: data).map { $0.id }, ["new"])
    }

    /// Report 2026-09-15_16-46-10: "it shouldn't recycle tasks from last time - it keeps adding this
    /// old Software Development task that I didn't actually choose." A brand-new session must start
    /// with what the start screen chose, never with the block list's persisted `lastTaskUsed`.
    func testANewSessionNeverInheritsThePreviousSessionsQueue() {
        let previous = focusModeTaskString
        defer { focusModeTaskString = previous }
        focusModeTaskString = "[{\"id\":\"old\",\"title\":\"Software Development\",\"status\":\"COMPLETED\"}]"
        let state = FocusStartState()
        XCTAssertFalse(state.isContinuingSuperFocusRun)
        XCTAssertEqual(state.taskQueueForSessionStart, FocusStartWorkSelection.emptyQueue,
                       "A session started with nothing chosen must start with an empty queue")
    }

    /// The simple start screen has no task picker at all, so this is the shape every one of its
    /// sessions takes — and the shape `simplePomodoroVc.pomodoroModeStarted()` now writes.
    func testQueueForSessionStartInheritsOnlyAContinuingRun() {
        let chosen = "[{\"id\":\"chosen\"}]"
        let running = "[{\"id\":\"stale\"}]"
        XCTAssertEqual(FocusStartWorkSelection.queueForSessionStart(chosen: chosen, runningQueue: running,
                                                                    isContinuingRun: false,
                                                                    hasChangedSelection: false),
                       chosen, "A brand-new session uses only what the start screen chose")
        XCTAssertEqual(FocusStartWorkSelection.queueForSessionStart(chosen: chosen, runningQueue: running,
                                                                    isContinuingRun: true,
                                                                    hasChangedSelection: false),
                       running, "Continuing a run keeps the queue that run is already working through")
        XCTAssertEqual(FocusStartWorkSelection.queueForSessionStart(chosen: chosen, runningQueue: running,
                                                                    isContinuingRun: true,
                                                                    hasChangedSelection: true),
                       chosen, "Re-picking during a run replaces the queue with the new selection")
    }

    /// The other half of the rule: work the user DID choose has to reach the session.
    func testTasksTheUserChoseDoReachTheNewSessionsQueue() throws {
        let previous = focusModeTaskString
        defer { focusModeTaskString = previous }
        focusModeTaskString = "[{\"id\":\"old\",\"title\":\"Software Development\"}]"
        let state = FocusStartState()
        state.selectedTasks = try workTasks([["id": "chosen", "title": "Chosen"]])
        let queue = FocusSessionTaskQueue.decode(state.taskQueueForSessionStart)
        XCTAssertEqual(queue.map { $0.id }, ["chosen"], "Only the chosen task starts the session")
        XCTAssertTrue(queue.first?.isActive ?? false, "The chosen task is what the session plays first")
    }

    func testDayPlanHydrationRetainsAndRefreshesBackendProjectIdentity() {
        let previousMockMode = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore(mockTasks: [:])
        let date = Date(timeIntervalSince1970: 4_000_000_000)
        let previous = store.tasks(for: date)
        defer { store.loadMock(previous, for: date); DayPlanTaskStore.mockMode = previousMockMode }
        store.loadMock([], for: date)
        let id = UUID().uuidString
        XCTAssertTrue(store.hydrate(fromDay: ["tasks": [["id": id, "project_id": "first", "title": "Task",
                                                       "tags": [["id": "project-tag-first", "text": "First project"]]]]], for: date))
        XCTAssertEqual(store.tasks(for: date).first?.projectID, "first")
        XCTAssertEqual(store.tasks(for: date).first?.project, "First project")
        XCTAssertTrue(store.hydrate(fromDay: ["tasks": [["id": id, "title": "Renamed task"]]], for: date))
        XCTAssertEqual(store.tasks(for: date).first?.projectID, "first", "An omitted project payload must preserve its known identity")
        XCTAssertEqual(store.tasks(for: date).first?.project, "First project")
        XCTAssertTrue(store.hydrate(fromDay: ["tasks": [["id": id, "project_id": "second",
                                                       "tags": [["id": "project-tag-second", "text": "Second project"]]]]], for: date))
        XCTAssertEqual(store.tasks(for: date).first?.projectID, "second")
        XCTAssertEqual(store.tasks(for: date).first?.project, "Second project")
        XCTAssertTrue(store.hydrate(fromDay: ["tasks": [["id": id, "project_id": NSNull()]]], for: date))
        XCTAssertNil(store.tasks(for: date).first?.projectID)
        XCTAssertNil(store.tasks(for: date).first?.project, "A cleared project must not match its old name as a legacy fallback")
        store.loadMock([DayPlanTask(title: "Local task", sourceTaskId: id, project: "Awaiting project repair")], for: date)
        _ = store.hydrate(fromDay: ["tasks": [["id": id, "project_id": NSNull(), "tags": []]]], for: date)
        XCTAssertNil(store.tasks(for: date).first?.projectID)
        XCTAssertEqual(store.tasks(for: date).first?.project, "Awaiting project repair", "An unlinked local name must survive until project repair confirms its link")
    }

    /// Report 2026-09-11_07-33-27: the focus session's task picker renders a task emoji, but rows
    /// built from the Day Plan never carried one because the store dropped the to-do's icon on import.
    func testDayPlanHydrationCarriesAndRefreshesTheToDoIcon() {
        let previousMockMode = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore(mockTasks: [:])
        let date = Date(timeIntervalSince1970: 4_000_000_000)
        let previous = store.tasks(for: date)
        defer { store.loadMock(previous, for: date); DayPlanTaskStore.mockMode = previousMockMode }
        store.loadMock([], for: date)
        let id = UUID().uuidString
        XCTAssertTrue(store.hydrate(fromDay: ["tasks": [["id": id, "title": "Task", "icon": "1f4dd"]]], for: date))
        XCTAssertEqual(store.tasks(for: date).first?.iconEmoji, "📝", "The imported task shows the to-do's emoji")
        XCTAssertTrue(store.hydrate(fromDay: ["tasks": [["id": id, "icon": "1f3e0"]]], for: date))
        XCTAssertEqual(store.tasks(for: date).first?.iconEmoji, "🏠", "A changed icon follows the backend")
        XCTAssertTrue(store.hydrate(fromDay: ["tasks": [["id": id, "icon": ""]]], for: date))
        XCTAssertNil(store.tasks(for: date).first?.iconEmoji, "Clearing the emoji elsewhere clears it here")
        XCTAssertFalse(store.hydrate(fromDay: ["tasks": [["id": id, "title": "Task"]]], for: date),
                       "A payload without an icon field changes nothing")
    }

    func testDayPlanSuggestionsUseVisibleGroupsAndPutUngroupedTasksLast() {
        let previousMockMode = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore(mockTasks: [:])
        let date = Date(timeIntervalSince1970: 4_000_000_000)
        let previous = store.tasks(for: date)
        defer { store.loadMock(previous, for: date); DayPlanTaskStore.mockMode = previousMockMode }
        let project = UUID().uuidString
        store.loadMock([DayPlanTask(id: "loose", title: "Loose"),
                        DayPlanTask(id: "first", title: "First", project: project),
                        DayPlanTask(id: "done", title: "Done", done: true, project: project),
                        DayPlanTask(id: "second", title: "Second", project: project)], for: date)
        XCTAssertEqual(store.incompleteTasksInDisplayOrder(for: date).map { $0.id }, ["first", "second", "loose"])
    }

    func testOlderDayPlanTasksStillDecodeWithoutProjectIdentity() throws {
        let legacy = DayPlanTask(title: "Legacy", project: "Project")
        let data = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(DayPlanTask.self, from: data)
        XCTAssertNil(decoded.projectID)
        XCTAssertEqual(decoded.project, "Project")
    }

    private func workProjects(_ values: [[String: Any]]) throws -> [Project] {
        try JSONDecoder().decode([Project].self, from: JSONSerialization.data(withJSONObject: values))
    }

    private func workTasks(_ values: [[String: Any]]) throws -> [ToDoTask] {
        let rows = values.map { row -> [String: Any] in
            var row = row
            if row["status"] == nil { row["status"] = "NOT_STARTED" }
            return row
        }
        return try JSONDecoder().decode([ToDoTask].self, from: JSONSerialization.data(withJSONObject: rows))
    }

}
