//
//  FocusSessionTests.swift
//  Focus BearTests
//
//  Tests for the pure logic behind the ongoing-focus-session screen: the session task queue codec and
//  its mutations, the countdown arithmetic, and the task-picker filter. These are the rules the
//  SwiftUI layer relies on, kept free of AppKit and of the app's globals so they can run headless.
//

@testable import Focus_Bear
import XCTest
import AppKit
import SwiftUI

class FocusSessionTests: XCTestCase {

    // MARK: - Helpers

    private func makeTask(id: String,
                          title: String,
                          status: FocusSessionTaskStatus = .notStarted,
                          isActive: Bool = false) -> FocusSessionTask {
        FocusSessionTask(id: id, title: title, status: status, isActive: isActive)
    }

    // MARK: - Queue decoding

    func test_decode_returnsEmpty_forEmptyString() {
        XCTAssertTrue(FocusSessionTaskQueue.decode("").isEmpty, "An empty task string is an empty queue")
    }

    func test_decode_returnsEmpty_forEmptyJsonArray() {
        XCTAssertTrue(FocusSessionTaskQueue.decode("[]").isEmpty, "\"[]\" is the player's empty queue")
    }

    func test_decode_returnsEmpty_forMalformedJson() {
        XCTAssertTrue(FocusSessionTaskQueue.decode("{not json").isEmpty,
                      "Malformed player output must not crash or half-populate the queue")
    }

    func test_decode_readsIdTitleStatusAndPlayingFlag() {
        let json = """
        [{"id":"a","title":"Write report","details":"notes","duration":900,"status":"IN_PROGRESS","isPlaying":true}]
        """
        let tasks = FocusSessionTaskQueue.decode(json)
        XCTAssertEqual(tasks.count, 1, "One entry in, one task out")
        XCTAssertEqual(tasks.first?.id, "a", "id should round-trip")
        XCTAssertEqual(tasks.first?.title, "Write report", "title should round-trip")
        XCTAssertEqual(tasks.first?.details, "notes", "details should round-trip")
        XCTAssertEqual(tasks.first?.durationSeconds, 900, "duration should round-trip")
        XCTAssertEqual(tasks.first?.status, .inProgress, "status should be parsed into the enum")
        XCTAssertTrue(tasks.first?.isActive ?? false, "isPlaying should map onto isActive")
    }

    func test_decode_acceptsStringDurations() {
        let tasks = FocusSessionTaskQueue.decode("[{\"id\":\"a\",\"title\":\"T\",\"duration\":\"1200\"}]")
        XCTAssertEqual(tasks.first?.durationSeconds, 1200, "The player has written durations as strings")
    }

    func test_decode_fallsBackToDefaultDuration_whenMissing() {
        let tasks = FocusSessionTaskQueue.decode("[{\"id\":\"a\",\"title\":\"T\"}]")
        XCTAssertEqual(tasks.first?.durationSeconds, FocusSessionTask.defaultDurationSeconds,
                       "A task with no duration should get the player's ten-minute default")
    }

    func test_decode_skipsEntriesWithNeitherIdNorTitle() {
        let tasks = FocusSessionTaskQueue.decode("[{\"duration\":60},{\"id\":\"a\",\"title\":\"T\"}]")
        XCTAssertEqual(tasks.count, 1, "An entry the user cannot act on should be dropped")
    }

    func test_encodeThenDecode_roundTrips() {
        let original = [makeTask(id: "a", title: "One", isActive: true),
                        makeTask(id: "b", title: "Two", status: .completed)]
        let decoded = FocusSessionTaskQueue.decode(FocusSessionTaskQueue.encode(original))
        XCTAssertEqual(decoded, original, "Encoding then decoding must not change the queue")
    }

    // MARK: - Active task

    func test_activeTask_prefersTheFlaggedTask() {
        let tasks = [makeTask(id: "a", title: "One"), makeTask(id: "b", title: "Two", isActive: true)]
        XCTAssertEqual(FocusSessionTaskQueue.activeTask(in: tasks)?.id, "b",
                       "The flagged task is the active one even when it isn't first")
    }

    func test_activeTask_fallsBackToFirstIncompleteTask() {
        let tasks = [makeTask(id: "a", title: "One", status: .completed), makeTask(id: "b", title: "Two")]
        XCTAssertEqual(FocusSessionTaskQueue.activeTask(in: tasks)?.id, "b",
                       "With nothing flagged, the first task still to do is active")
    }

    func test_activeTask_ignoresAFlaggedButCompletedTask() {
        let tasks = [makeTask(id: "a", title: "One", status: .completed, isActive: true),
                     makeTask(id: "b", title: "Two")]
        XCTAssertEqual(FocusSessionTaskQueue.activeTask(in: tasks)?.id, "b",
                       "A completed task must not stay in the active card")
    }

    func test_activeTask_isNil_forAnEmptyQueue() {
        XCTAssertNil(FocusSessionTaskQueue.activeTask(in: []), "No tasks means no active task")
    }

    func test_queuedTasks_excludesTheActiveTask() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true), makeTask(id: "b", title: "Two")]
        XCTAssertEqual(FocusSessionTaskQueue.queuedTasks(in: tasks).map { $0.id }, ["b"],
                       "The active task is shown in its own card, not repeated in the queue")
    }

    /// Report 2026-09-15_16-46-10: "Task queue should be 0 in this case since the task was completed."
    /// The completed row stays on screen (struck through, as the design draws it) but the heading
    /// counts outstanding work, so a finished queue reads zero.
    func test_outstanding_isEmpty_whenEveryQueuedTaskIsCompleted() {
        let tasks = [makeTask(id: "a", title: "Software Development", status: .completed)]
        XCTAssertNil(FocusSessionTaskQueue.activeTask(in: tasks), "A completed task is not active")
        XCTAssertEqual(FocusSessionTaskQueue.queuedTasks(in: tasks).count, 1,
                       "The completed row is still drawn, struck through")
        XCTAssertTrue(FocusSessionTaskQueue.outstanding(in: FocusSessionTaskQueue.queuedTasks(in: tasks)).isEmpty,
                      "The heading must read 0 once the queue's only task is done")
    }

    func test_outstanding_countsOnlyTheTasksStillToDo() {
        let tasks = [makeTask(id: "a", title: "Done", status: .completed),
                     makeTask(id: "b", title: "Still to do"),
                     makeTask(id: "c", title: "Also to do", status: .inProgress)]
        XCTAssertEqual(FocusSessionTaskQueue.outstanding(in: tasks).map { $0.id }, ["b", "c"],
                       "In-progress work still counts; completed work does not")
    }

    func test_completingTheOnlyTask_dropsTheQueueHeadingToZero() {
        let tasks = [makeTask(id: "a", title: "Software Development", isActive: true)]
        let updated = FocusSessionTaskQueue.completing(tasks, id: "a")
        XCTAssertEqual(FocusSessionTaskQueue.outstanding(in: FocusSessionTaskQueue.queuedTasks(in: updated)).count, 0,
                       "Completing the session's only task must leave nothing outstanding")
    }

    // MARK: - Mutations

    func test_focusing_movesTheFlagAndClearsTheOthers() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true), makeTask(id: "b", title: "Two")]
        let updated = FocusSessionTaskQueue.focusing(tasks, on: "b")
        XCTAssertFalse(updated[0].isActive, "The previously active task should lose the flag")
        XCTAssertTrue(updated[1].isActive, "The chosen task should gain the flag")
    }

    func test_completing_marksTheTaskAndPromotesTheNextOne() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true), makeTask(id: "b", title: "Two")]
        let updated = FocusSessionTaskQueue.completing(tasks, id: "a")
        XCTAssertEqual(updated[0].status, .completed, "The completed task should carry the status")
        XCTAssertFalse(updated[0].isActive, "A completed task must not remain active")
        XCTAssertTrue(updated[1].isActive, "The session should move on to the next task")
    }

    func test_completing_theLastTask_leavesNoActiveTask() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true)]
        let updated = FocusSessionTaskQueue.completing(tasks, id: "a")
        XCTAssertNil(FocusSessionTaskQueue.activeTask(in: updated),
                     "Completing the only task should empty the active card, not re-activate it")
    }

    func test_removing_dropsTheTaskAndPromotesTheNextOne() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true), makeTask(id: "b", title: "Two")]
        let updated = FocusSessionTaskQueue.removing(tasks, id: "a")
        XCTAssertEqual(updated.map { $0.id }, ["b"], "The removed task should be gone")
        XCTAssertTrue(updated[0].isActive, "Removing the active task should promote the next one")
    }

    func test_removing_anInactiveTask_leavesTheActiveTaskAlone() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true), makeTask(id: "b", title: "Two")]
        let updated = FocusSessionTaskQueue.removing(tasks, id: "b")
        XCTAssertTrue(updated[0].isActive, "Removing a queued task must not move the session's focus")
    }

    func test_appending_skipsTasksAlreadyInTheQueue() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true)]
        let updated = FocusSessionTaskQueue.appending(tasks, newTasks: [makeTask(id: "a", title: "One")])
        XCTAssertEqual(updated.count, 1, "Queueing a task that is already there must not duplicate it")
    }

    func test_appending_toAnEmptyQueue_activatesTheFirstTask() {
        let updated = FocusSessionTaskQueue.appending([], newTasks: [makeTask(id: "a", title: "One"),
                                                                    makeTask(id: "b", title: "Two")])
        XCTAssertEqual(FocusSessionTaskQueue.activeTask(in: updated)?.id, "a",
                       "A session with no task should start working on the first task added")
    }

    func test_appending_toANonEmptyQueue_keepsTheCurrentActiveTask() {
        let tasks = [makeTask(id: "a", title: "One", isActive: true)]
        let updated = FocusSessionTaskQueue.appending(tasks, newTasks: [makeTask(id: "b", title: "Two")])
        XCTAssertEqual(FocusSessionTaskQueue.activeTask(in: updated)?.id, "a",
                       "Adding tasks mid-session must not yank the user off what they're doing")
    }

    func test_moving_swapsAdjacentTasks() {
        let tasks = [makeTask(id: "a", title: "One"), makeTask(id: "b", title: "Two")]
        XCTAssertEqual(FocusSessionTaskQueue.moving(tasks, id: "b", by: -1).map { $0.id }, ["b", "a"],
                       "Moving a task up should swap it with its predecessor")
    }

    func test_moving_pastTheEnds_isANoOp() {
        let tasks = [makeTask(id: "a", title: "One"), makeTask(id: "b", title: "Two")]
        XCTAssertEqual(FocusSessionTaskQueue.moving(tasks, id: "a", by: -1), tasks,
                       "The first task cannot move up")
        XCTAssertEqual(FocusSessionTaskQueue.moving(tasks, id: "b", by: 1), tasks,
                       "The last task cannot move down")
    }

    func test_moving_anUnknownId_isANoOp() {
        let tasks = [makeTask(id: "a", title: "One")]
        XCTAssertEqual(FocusSessionTaskQueue.moving(tasks, id: "zzz", by: 1), tasks,
                       "A stale id must leave the queue untouched")
    }

    // MARK: - Clock

    private let units = FocusSessionDurationUnits(hour: "hr", minute: "min", second: "sec")

    func test_remainingSeconds_countsDownToTheEndDate() {
        let now = Date()
        let end = now.addingTimeInterval(90)
        XCTAssertEqual(FocusSessionClock.remainingSeconds(until: end, now: now), 90,
                       "Ninety seconds out should read as ninety seconds")
    }

    func test_remainingSeconds_neverGoesNegative() {
        let now = Date()
        XCTAssertEqual(FocusSessionClock.remainingSeconds(until: now.addingTimeInterval(-30), now: now), 0,
                       "An overrun session should read zero, not count backwards")
    }

    func test_headline_showsMinutesAndSeconds() {
        XCTAssertEqual(FocusSessionClock.headline(remainingSeconds: 24 * 60 + 36, units: units),
                       "24 min 36 sec", "This is the format the design specifies")
    }

    func test_headline_showsHoursAndMinutes_pastAnHour() {
        XCTAssertEqual(FocusSessionClock.headline(remainingSeconds: 3600 + 24 * 60 + 36, units: units),
                       "1 hr 24 min", "Seconds are dropped once the session is over an hour")
    }

    func test_headline_showsSecondsOnly_inTheLastMinute() {
        XCTAssertEqual(FocusSessionClock.headline(remainingSeconds: 36, units: units), "36 sec",
                       "Under a minute there is nothing but seconds to show")
    }

    func test_headline_handlesZero() {
        XCTAssertEqual(FocusSessionClock.headline(remainingSeconds: 0, units: units), "0 sec",
                       "A finished session should read zero seconds")
    }

    func test_clockText_padsMinutesAndSeconds() {
        XCTAssertEqual(FocusSessionClock.clockText(seconds: 7 * 60 + 4), "07:04",
                       "Under an hour the clock is mm:ss")
    }

    func test_clockText_addsHours_pastAnHour() {
        XCTAssertEqual(FocusSessionClock.clockText(seconds: 3600 + 7 * 60 + 4), "01:07:04",
                       "Past an hour the clock gains an hours field")
    }

    func test_progress_isTheFractionElapsed() {
        XCTAssertEqual(FocusSessionClock.progress(elapsedSeconds: 300, totalSeconds: 1200), 0.25,
                       accuracy: 0.0001, "A quarter through should be 0.25")
    }

    func test_progress_isZero_whenTotalIsUnknown() {
        XCTAssertEqual(FocusSessionClock.progress(elapsedSeconds: 300, totalSeconds: 0), 0,
                       "Without a session length there is nothing to divide by")
    }

    func test_progress_isClampedToOne() {
        XCTAssertEqual(FocusSessionClock.progress(elapsedSeconds: 2000, totalSeconds: 1200), 1,
                       "An overrun session should fill the bar, not overflow it")
    }

    // MARK: - Scale

    func test_scaleFactor_isOne_atTheDesignWidth() {
        XCTAssertEqual(FocusSessionTokens.scaleFactor(forContentWidth: FocusSessionTokens.designWidthPoints), 1,
                       accuracy: 0.0001, "At the design width nothing should be scaled")
    }

    func test_scaleFactor_isClampedAtBothEnds() {
        XCTAssertEqual(FocusSessionTokens.scaleFactor(forContentWidth: 100),
                       FocusSessionTokens.minimumScaleFactor, accuracy: 0.0001,
                       "A very narrow window should stop shrinking and scroll instead")
        XCTAssertEqual(FocusSessionTokens.scaleFactor(forContentWidth: 5000),
                       FocusSessionTokens.maximumScaleFactor, accuracy: 0.0001,
                       "A very wide window should not blow the design up past its authored size")
    }

    func test_scaleFactor_handlesAZeroWidth() {
        XCTAssertEqual(FocusSessionTokens.scaleFactor(forContentWidth: 0),
                       FocusSessionTokens.maximumScaleFactor, accuracy: 0.0001,
                       "A not-yet-laid-out view must not produce a zero or NaN scale")
    }

    func test_scale_convertsDesignPixelsToPoints() {
        let scale = FocusSessionScale(contentWidth: FocusSessionTokens.designWidthPoints)
        XCTAssertEqual(scale.pt(96), 48, accuracy: 0.0001,
                       "The design is a 2x capture, so 96 design pixels is 48 points")
    }

    func test_ongoingViewport_mainWindowWithExpandedSidebarKeepsFigmaColumnHierarchy() {
        // Measured 1600×900 window minus the 230pt app sidebar and 25pt menu-bar inset.
        let layout = FocusSessionViewportLayout(size: CGSize(width: 1370, height: 875))
        XCTAssertTrue(layout.showsSideRail)
        XCTAssertLessThan(layout.taskPanelWidth / layout.contentWidth, 0.33,
                          "The overflowing Figma node must not consume 40% of the visible page")
        XCTAssertGreaterThan(layout.sessionColumnWidth, layout.taskPanelWidth * 1.2,
                             "The main project/timer card needs the reference's wider center column")
    }

    func test_ongoingViewport_scaledDesktopDoesNotLoseMusicAndNotesAtAnArbitraryHeight() {
        let layout = FocusSessionViewportLayout(size: CGSize(width: 1280, height: 720))
        XCTAssertTrue(layout.showsSideRail,
                      "The scaled design fits here; a fixed 820pt cutoff incorrectly removes its rail")
    }

    func test_ongoingViewport_genuinelyShortDesktopKeepsBearLeftAndTaskAlongside() {
        let layout = FocusSessionViewportLayout(size: CGSize(width: 1370, height: 550))
        XCTAssertTrue(layout.isWide)
        XCTAssertTrue(layout.isCompact)
        XCTAssertFalse(layout.showsSideRail)
        XCTAssertNotNil(FocusSessionCompactLayout.bearWidth(availableWidth: layout.sessionColumnWidth,
                                                           scale: layout.scale))
    }

    func test_ongoingViewport_secondaryDisplayWithSidebarPrioritizesTheActiveTask() {
        let layout = FocusSessionViewportLayout(size: CGSize(width: 794, height: 644))
        XCTAssertFalse(layout.isWide)
        XCTAssertTrue(layout.isCompact, "Stacked screens must show the active task before the bear")
        let rowWidth = layout.contentWidth - layout.scale.pt(FocusSessionLayout.screenPadding) * 2
        XCTAssertNotNil(FocusSessionCompactLayout.bearWidth(availableWidth: rowWidth, scale: layout.scale))
    }

    func test_ongoingViewport_ultrawideDisplayCentersTheDesignInsteadOfInflatingIt() {
        let layout = FocusSessionViewportLayout(size: CGSize(width: 3000, height: 1400))
        XCTAssertLessThan(layout.contentWidth, 1800)
        XCTAssertEqual(layout.scale.factor, 1)
        XCTAssertGreaterThan(layout.contentHeight, 0)
    }

    // MARK: - Task picker filter

    private func makePickerTask(id: String,
                                title: String,
                                status: FocusSessionTaskStatus = .notStarted,
                                perspiration: Int = FocusSessionScoring.minimum,
                                projectId: String? = nil,
                                dueInDays: Int? = nil,
                                now: Date = Date()) -> FocusSessionPickerTask {
        FocusSessionPickerTask(id: id,
                               title: title,
                               status: status,
                               perspirationLevel: perspiration,
                               projectId: projectId,
                               dueDate: dueInDays.flatMap {
                                   Calendar(identifier: .gregorian).date(byAdding: .day, value: $0, to: now)
                               })
    }

    func test_filter_returnsEverything_forAnEmptyQuery() {
        let tasks = [makePickerTask(id: "a", title: "One"), makePickerTask(id: "b", title: "Two")]
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "  ", excludingIds: []).count, 2,
                       "A blank query should not filter anything out")
    }

    func test_filter_matchesTitlesCaseInsensitively() {
        let tasks = [makePickerTask(id: "a", title: "Summarise Sources")]
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "summarise", excludingIds: []).count, 1,
                       "Search should not care about case")
    }

    func test_filter_matchesIgnoringAccents() {
        let tasks = [makePickerTask(id: "a", title: "Revisión de código")]
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "revision", excludingIds: []).count, 1,
                       "Spanish users should not have to type the accents")
    }

    func test_filter_excludesTasksAlreadyQueued() {
        let tasks = [makePickerTask(id: "a", title: "One"), makePickerTask(id: "b", title: "Two")]
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "", excludingIds: ["a"]).map { $0.id },
                       ["b"], "The picker should only offer tasks not already in the session")
    }

    func test_filter_excludesCompletedTasks() {
        let tasks = [makePickerTask(id: "a", title: "One", status: .completed)]
        XCTAssertTrue(FocusSessionTaskFilter.matching(tasks, query: "", excludingIds: []).isEmpty,
                      "A finished to-do is not work to queue")
    }

    /// Report 2026-09-15_16-46-10: "the empty state is not good. It should let me click to add a task
    /// and have it bring up the task selection modal." The empty active-task card's action is
    /// `presentTaskPicker`, which must land on the picker with tasks to choose from.
    func test_emptyActiveTaskState_opensTheTaskSelectionModal() {
        let previousMockMode = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let dayPlan = DayPlanTaskStore.shared
        let today = Date()
        let previousPlan = dayPlan.tasks(for: today)
        defer { dayPlan.loadMock(previousPlan, for: today); DayPlanTaskStore.mockMode = previousMockMode }
        dayPlan.loadMock([DayPlanTask(id: "planned", title: "Planned task")], for: today)

        let store = FocusSessionStore.visualFixture(tasks: [], subtasks: [], blockListName: "Deep Work",
                                                    goal: "", notes: "")
        XCTAssertNil(store.activeTask, "The fixture starts on the empty state the report is about")
        XCTAssertNil(store.activeSheet, "Nothing is presented until the empty state is clicked")

        store.presentTaskPicker()

        XCTAssertEqual(store.activeSheet, .taskPicker, "The empty state must bring up the task picker")
        XCTAssertEqual(store.pickerPage, .selectTasks, "…on its task-selection page")
        XCTAssertEqual(store.visiblePickerTasks.map { $0.id }, ["planned"],
                       "…already offering today's planned work to choose from")
    }

    // MARK: - Strings

    func test_taskQueueHeading_substitutesTheCount() {
        var strings = FocusSessionStrings()
        strings.taskQueueLabel = "Task Queue (<COUNT>):"
        XCTAssertEqual(strings.taskQueueHeading(count: 3), "Task Queue (3):",
                       "<COUNT> should be replaced with the real number")
    }

    func test_queueTasksButton_usesTheSingularCopy_forOneTask() {
        var strings = FocusSessionStrings()
        strings.queueSingleTaskButton = "Queue 1 task"
        XCTAssertEqual(strings.queueTasksButton(count: 1), "Queue 1 task",
                       "One task should not read as \"Queue 1 tasks\"")
    }

    func test_durationBadge_substitutesTheMinutes() {
        var strings = FocusSessionStrings()
        strings.durationBadge = "DURATION: <MINUTES> MINS"
        XCTAssertEqual(strings.durationBadge(minutes: 30), "DURATION: 30 MINS",
                       "<MINUTES> should be replaced with the task's duration")
    }

    // MARK: - Emoji decoding

    func test_emoji_returnsNil_whenIconIsMissingOrBlank() {
        XCTAssertNil(FocusSessionEmoji.decode(nil), "No icon means no glyph")
        XCTAssertNil(FocusSessionEmoji.decode("   "), "A blank icon means no glyph")
    }

    func test_emoji_passesThroughAGlyph() {
        XCTAssertEqual(FocusSessionEmoji.decode("📚"), "📚", "An emoji icon is already a glyph")
    }

    func test_emoji_decodesAHexUnifiedCode() {
        XCTAssertEqual(FocusSessionEmoji.decode("1f4da"), "📚",
                       "The API also sends icons as hex unified codes")
    }

    func test_emoji_decodesAMultiScalarHexCode() {
        XCTAssertEqual(FocusSessionEmoji.decode("1f1e6-1f1e8"), "🇦🇨",
                       "Multi-scalar codes are hyphen separated")
    }

    func test_emoji_leavesANonHexStringAlone() {
        XCTAssertEqual(FocusSessionEmoji.decode("book"), "book",
                       "A word is not a hex code and must not be mangled")
    }

    // MARK: - Reading a to-do row

    private func makeToDo(id: String = "a",
                          title: String = "Summarise Sources",
                          duration: Int? = 1800,
                          outcome: Int? = 7,
                          perspiration: Int? = 2,
                          dueDate: String? = "2026-09-10",
                          topScore: Double? = nil,
                          icon: String? = "1f4da") -> ToDoTask {
        var task = ToDoTask(id: id, title: title, status: ToDoStatus.notStarted.rawValue, created_at: "")
        task.details = "notes"
        task.duration = duration.map { LenientInt($0) }
        task.outcome = outcome
        task.perspiration_level = perspiration
        task.due_date = dueDate
        task.top_score = topScore
        task.icon = icon
        task.project_id = "p1"
        return task
    }

    func test_pickerTask_readsTheFieldsTheDesignShows() {
        let task = FocusSessionPickerTask.make(from: makeToDo())
        XCTAssertEqual(task?.iconEmoji, "📚", "icon drives the design's per-task emoji")
        XCTAssertEqual(task?.outcome, 7, "outcome drives the edit sheet's Outcome slider")
        XCTAssertEqual(task?.perspirationLevel, 2, "perspiration_level drives the spoons filter")
        XCTAssertEqual(task?.projectId, "p1", "project_id drives the project filter")
        XCTAssertNotNil(task?.dueDate, "due_date drives the due-date filter")
        XCTAssertEqual(task?.durationSeconds, 1800, "An explicit duration is used as-is")
    }

    func test_pickerTask_usesTheComputedTopScore_notTheStoredOne() {
        // The stored score goes stale as soon as the due date moves, which is why every row was
        // showing the same number; ToDoScoring recomputes it from the task's own inputs.
        let task = makeToDo(topScore: 9.0)
        let row = FocusSessionPickerTask.make(from: task)
        XCTAssertEqual(row?.topScore ?? 0, ToDoScoring.topScore(of: task), accuracy: 0.0001,
                       "The badge must show the score the rest of the app computes")
    }

    func test_pickerTask_fallsBackToPerspirationEffort_whenDurationIsMissing() {
        let row = FocusSessionPickerTask.make(from: makeToDo(duration: nil))
        XCTAssertEqual(row?.durationSeconds,
                       ToDoScoring.durationSeconds(explicit: nil, perspiration: 2),
                       "A task with no duration shows the effort its perspiration level implies")
        XCTAssertNotEqual(row?.durationSeconds, 60, "It must not collapse to the one-minute minimum")
    }

    func test_pickerTask_clampsScoresIntoTheOneToTenScale() {
        let row = FocusSessionPickerTask.make(from: makeToDo(outcome: 99, perspiration: 0))
        XCTAssertEqual(row?.outcome, FocusSessionScoring.maximum, "Outcome is a 1-10 scale")
        XCTAssertEqual(row?.perspirationLevel, FocusSessionScoring.minimum, "Perspiration is a 1-10 scale")
    }

    func test_pickerTask_isNil_withoutAnIdOrTitle() {
        XCTAssertNil(FocusSessionPickerTask.make(from: makeToDo(id: "")), "A row with no id is unusable")
        XCTAssertNil(FocusSessionPickerTask.make(from: makeToDo(title: "")), "A row with no title is unusable")
    }

    func test_pickerOrder_matchesTheAppsCanonicalSmartOrder() {
        let low = makeToDo(id: "low", title: "Low", outcome: 1, perspiration: 10, dueDate: nil)
        let high = makeToDo(id: "high", title: "High", outcome: 10, perspiration: 1, dueDate: "2026-09-10")
        let source = [low, high]
        let rows = source.compactMap { FocusSessionPickerTask.make(from: $0) }
        let expected = ToDoSorting.sort(source, by: .smart).map { $0.id }
        XCTAssertEqual(FocusSessionTaskFilter.ordered(rows, sourceTasks: source).map { $0.id }, expected,
                       "The picker must use the same comparator as the Day Plan and the To-do list")
    }

    // MARK: - Upsert body

    private var originalRow: [String: Any] {
        ["id": "a", "title": "Old", "details": "old details", "status": "NOT_STARTED",
         "tags": [["id": "t1", "text": "work"]], "subtasks": [["name": "s", "is_completed": false]],
         "duration": 1800, "eisenhower_quadrant": 2, "created_at": "2026-01-01", "top_score": 4.2,
         "due_date": "2026-10-01", "outcome": NSNull(), "perspiration_level": 1,
         "project_id": NSNull(), "synced_project_id": NSNull(), "updated_at": "2026-09-10T01:00:00.000Z"]
    }

    private var sampleEdits: FocusSessionTaskEdits {
        FocusSessionTaskEdits(title: "  New  ", details: "new details", status: .inProgress,
                              dueDate: Date(timeIntervalSince1970: 0), outcome: 7,
                              perspirationLevel: 3, projectId: "p1")
    }

    func test_upsertBody_keepsTheId_soThePutUpdatesRatherThanCreates() {
        let body = FocusSessionTaskUpsert.body(updating: originalRow, with: sampleEdits)
        XCTAssertEqual(body["id"] as? String, "a", "PUT /to-do only updates when the body carries an id")
    }

    func test_upsertBody_writesTheEditedFields() {
        let body = FocusSessionTaskUpsert.body(updating: originalRow, with: sampleEdits)
        XCTAssertEqual(body["title"] as? String, "New", "The title is trimmed before it is sent")
        XCTAssertEqual(body["details"] as? String, "new details", "The description is sent as details")
        XCTAssertEqual(body["status"] as? String, "IN_PROGRESS", "The status radio is sent")
        XCTAssertEqual(body["outcome"] as? Int, 7, "The Outcome slider is sent")
        XCTAssertEqual(body["perspiration_level"] as? Int, 3, "The Perspiration slider is sent")
        XCTAssertEqual(body["project_id"] as? String, "p1", "The project picker is sent")
        XCTAssertNotNil(body["due_date"] as? String, "The due date is sent as an ISO string")
    }

    func test_upsertBody_omitsUneditedFieldsSoTheServerPreservesThem() {
        let body = FocusSessionTaskUpsert.body(updating: originalRow, with: sampleEdits)
        XCTAssertNil(body["tags"], "Omission preserves tags; stale cached values must not overwrite them")
        XCTAssertNil(body["subtasks"], "An unrelated edit must not overwrite subtasks")
        XCTAssertEqual(body["eisenhower_quadrant"] as? Int, 2, "The quadrant must survive an edit")
        XCTAssertNil(body["duration"], "The server retains the duration when it is omitted")
    }

    func test_upsertBody_stripsServerOwnedFields() {
        let body = FocusSessionTaskUpsert.body(updating: originalRow, with: sampleEdits)
        XCTAssertNil(body["created_at"], "created_at is server-owned and must not be echoed back")
        XCTAssertNil(body["top_score"], "top_score is recomputed server-side")
    }

    func test_upsertBody_clearsTheDueDateWithAnExplicitNull() {
        var edits = sampleEdits
        edits.dueDate = nil
        let body = FocusSessionTaskUpsert.body(updating: originalRow, with: edits)
        XCTAssertTrue(body["due_date"] is NSNull, "An empty string would fail the DTO's date validator")
    }

    func test_voiceShortcutUsesTheMenuActionAndDoesNotRestartRecording() {
        let model = MenuModel()
        var starts = 0
        model.onMic = { starts += 1 }
        model.micAvailable = false
        model.beginVoiceInput()
        XCTAssertEqual(starts, 0)
        model.micAvailable = true
        model.beginVoiceInput()
        XCTAssertTrue(model.inVoiceMode)
        XCTAssertEqual(starts, 1)
        model.beginVoiceInput()
        XCTAssertEqual(starts, 1)
        model.voiceStatus = .processing
        model.beginVoiceInput()
        XCTAssertEqual(starts, 1)
        model.voiceStatus = .done
        model.beginVoiceInput()
        XCTAssertEqual(starts, 2)
    }

    func test_focusSessionNewTaskIsDueToday() {
        let store = FocusSessionStore()
        XCTAssertTrue(Calendar.current.isDateInToday(store.newTaskDraft.dueDate!))
        XCTAssertEqual(FocusSessionTaskUpsert.creationBody(with: store.newTaskDraft)["duration"] as? Int,
                       store.newTaskDraft.effectiveDurationMinutes * 60)
    }

    func test_durationMinutesAreSavedInSecondsAndPreservedWhenUnchanged() {
        var edits = FocusSessionTaskSnapshot.edits(originalRow)!
        XCTAssertEqual(edits.durationMinutes, 30)
        edits.title = "Renamed"
        XCTAssertNil(FocusSessionTaskUpsert.body(updating: originalRow, with: edits)["duration"])
        edits.durationMinutes = 17
        XCTAssertEqual(FocusSessionTaskUpsert.body(updating: originalRow, with: edits)["duration"] as? Int, 1020)
        XCTAssertEqual(FocusSessionTaskUpsert.creationBody(with: edits)["duration"] as? Int, 1020)
        edits.durationMinutes = 0
        XCTAssertFalse(edits.isValid)
        edits.durationMinutes = Int.max
        XCTAssertFalse(edits.isValid)
    }

    func test_durationChangeInvalidatesAnOpenEditSnapshot() {
        var updated = originalRow
        updated["duration"] = 600
        XCTAssertFalse(FocusSessionTaskSnapshot.unchanged(updated, since: originalRow))
    }

    func test_creationBody_omitsTheId_soThePutInserts() {
        let body = FocusSessionTaskUpsert.creationBody(with: sampleEdits)
        XCTAssertNil(body["id"], "A create must not carry an id")
        XCTAssertEqual(body["title"] as? String, "New", "A create still sends the edited fields")
    }

    func test_edits_areInvalid_withABlankTitle() {
        XCTAssertFalse(FocusSessionTaskEdits(title: "   ").isValid, "A task needs a name")
        XCTAssertTrue(FocusSessionTaskEdits(title: "Write").isValid, "A named task can be saved")
    }

    func test_outcomePicker_mapsFiveExplicitChoicesToWireWithoutRoundingLegacyRatings() {
        XCTAssertEqual((1...5).map(FocusSessionOutcome.wireValue), [2, 4, 6, 8, 10])
        XCTAssertEqual(FocusSessionOutcome.displayValue(forWire: 7), 3.5)
        XCTAssertEqual(FocusSessionOutcome.displayValue(forWire: 1), 1)
        var raw = originalRow
        for outcome in [1, 3, 7, 9] {
            raw["outcome"] = outcome
            var edits = FocusSessionTaskSnapshot.edits(raw)!
            XCTAssertEqual(edits.outcome, outcome)
            edits.title = "Renamed"
            XCTAssertNil(FocusSessionTaskUpsert.body(updating: raw, with: edits)["outcome"])
        }
    }

    func test_outcomeUnsetRemainsUnsetUntilAnExplicitChoiceOrClear() {
        var edits = FocusSessionTaskSnapshot.edits(originalRow)!
        XCTAssertNil(edits.outcome)
        edits.title = "Renamed"
        XCTAssertNil(FocusSessionTaskUpsert.body(updating: originalRow, with: edits)["outcome"])
        var rated = originalRow; rated["outcome"] = 7
        XCTAssertTrue(FocusSessionTaskUpsert.body(updating: rated, with: edits)["outcome"] is NSNull)
        edits.outcome = FocusSessionOutcome.wireValue(forDisplay: 5)
        XCTAssertEqual(FocusSessionTaskUpsert.body(updating: rated, with: edits)["outcome"] as? Int, 10)
    }

    func test_snapshotRejectsMissingRecordAndIncompleteReadContracts() {
        XCTAssertTrue(FocusSessionTaskSnapshot.isEditable(originalRow, id: "a"))
        XCTAssertFalse(FocusSessionTaskSnapshot.isEditable(originalRow, id: "deleted-id"))
        for key in FocusSessionTaskSnapshot.requiredKeys {
            var incomplete = originalRow; incomplete.removeValue(forKey: key)
            XCTAssertFalse(FocusSessionTaskSnapshot.isEditable(incomplete, id: "a"), "Missing \(key) must disable editing")
        }
    }

    func test_snapshotRevalidationRejectsConcurrentUpdatesAndQuadrantChanges() {
        XCTAssertTrue(FocusSessionTaskSnapshot.unchanged(originalRow, since: originalRow))
        for (key, value) in [("updated_at", "2026-09-10T02:00:00.000Z" as Any),
                             ("outcome", 8 as Any), ("eisenhower_quadrant", 4 as Any),
                             ("project_id", "another-project" as Any), ("status", "COMPLETED" as Any)] {
            var changed = originalRow; changed[key] = value
            XCTAssertFalse(FocusSessionTaskSnapshot.unchanged(changed, since: originalRow), key)
        }
    }

    private var lookupRow: [String: Any] {
        var row = originalRow
        row["id"] = "665d67e7-2476-491d-8efe-fc2bcf35e61c"
        return row
    }

    private func lookupData(_ value: Any) -> Data {
        try! JSONSerialization.data(withJSONObject: value)
    }

    private var legacyLookupRow: [String: Any] {
        var row = lookupRow
        for key in ["updated_at", "eisenhower_quadrant", "outcome", "perspiration_level", "synced_project_id"] {
            row.removeValue(forKey: key)
        }
        return row
    }

    func test_taskLookupIncompleteServerProjectionExplainsUpdateInsteadOfReconnect() {
        var requests = 0
        FocusSessionTaskLookup.loadResult(id: lookupRow["id"] as! String, day: "2026-09-10",
            accountIsCurrent: { true }, read: { _, done in
                requests += 1
                done(self.lookupData(requests == 1 ? [self.legacyLookupRow] as Any : ["day": "2026-09-10", "tasks": []]), 200)
            }, completion: { result in
                guard case .failure(.incompleteServerSnapshot) = result else { return XCTFail("Expected a schema compatibility failure") }
                var strings = FocusSessionStrings()
                strings.taskServerUpdateRequired = "server update"
                strings.couldNotLoadTask = "retry connection"
                XCTAssertEqual(strings.taskLoadError(result), "server update")
            })
        XCTAssertEqual(requests, 2)
    }

    func test_taskLookupTransportFailureKeepsConnectionRecovery() {
        FocusSessionTaskLookup.loadResult(id: lookupRow["id"] as! String, day: "2026-09-10",
            accountIsCurrent: { true }, read: { _, done in done(nil, 0) }, completion: { result in
                guard case .failure(.unavailable) = result else { return XCTFail("Expected transport failure") }
                var strings = FocusSessionStrings()
                strings.couldNotLoadTask = "retry connection"
                XCTAssertEqual(strings.taskLoadError(result), "retry connection")
            })
    }

    func test_taskLookupCompleteByIDNeedsOneReadAndKeepsUnknownMetadata() {
        let row = lookupRow, id = row["id"] as! String
        var paths: [String] = []
        var result: [String: Any]?
        FocusSessionTaskLookup.load(id: id, day: "2026-09-10", accountIsCurrent: { true }, read: { path, done in
            paths.append(path); done(self.lookupData([row]), 200)
        }, completion: { result = $0 })
        XCTAssertEqual(paths, ["/to-do/by-ids?ids=\(id)"])
        XCTAssertEqual(result?["tags"] as? [[String: String]], [["id": "t1", "text": "work"]])
        XCTAssertEqual(result?["updated_at"] as? String, row["updated_at"] as? String)
    }

    func test_taskLookupLegacyByIDUsesOneCompleteDayPlanSnapshotWithoutCombiningRows() {
        var full = lookupRow
        full["title"] = "Renamed since the by-ID read"
        full["outcome"] = 7
        full["perspiration_level"] = 9
        full["updated_at"] = "2026-09-10T02:00:00.000Z"
        let id = full["id"] as! String, partial = legacyLookupRow
        var paths: [String] = []
        var result: [String: Any]?
        FocusSessionTaskLookup.load(id: id, day: "2026-09-10", accountIsCurrent: { true }, read: { path, done in
            paths.append(path)
            done(self.lookupData(paths.count == 1 ? [partial] as Any : ["day": "2026-09-10", "tasks": [full]]), 200)
        }, completion: { result = $0 })
        XCTAssertEqual(paths, ["/to-do/by-ids?ids=\(id)", "/day-plan/day/2026-09-10"])
        XCTAssertEqual(result?["title"] as? String, full["title"] as? String)
        XCTAssertEqual(result?["outcome"] as? Int, 7)
        XCTAssertEqual(result?["perspiration_level"] as? Int, 9)
        XCTAssertTrue(FocusSessionTaskSnapshot.unchanged(result!, since: full))
        XCTAssertFalse(FocusSessionTaskSnapshot.unchanged(result!, since: lookupRow))
        var edits = FocusSessionTaskSnapshot.edits(result!)!
        edits.title = "One explicit change"
        let body = FocusSessionTaskUpsert.body(updating: result!, with: edits)
        XCTAssertEqual(Set(body.keys), ["id", "title", "eisenhower_quadrant"])
        XCTAssertEqual(FocusSessionSubtasks.decode(result!), FocusSessionSubtasks.decode(full))
    }

    func test_taskLookupMissingByIDDoesNotResurrectFromAnotherRead() {
        let id = lookupRow["id"] as! String
        for response in [[], [originalRow]] {
            var requests = 0, completed = false
            FocusSessionTaskLookup.load(id: id, day: "2026-09-10", accountIsCurrent: { true }, read: { _, done in
                requests += 1; done(self.lookupData(response), 200)
            }, completion: { XCTAssertNil($0); completed = true })
            XCTAssertEqual(requests, 1)
            XCTAssertTrue(completed)
        }
    }

    func test_taskLookupFallbackRejectsWrongDayWrongIDAndIncompleteSnapshots() {
        let id = lookupRow["id"] as! String
        let invalidPayloads: [[String: Any]] = [
            ["day": "2026-09-09", "tasks": [lookupRow]],
            ["day": "2026-09-10", "tasks": [originalRow]],
            ["day": "2026-09-10", "tasks": [legacyLookupRow]],
            ["day": "2026-09-10", "tasks": []]
        ]
        for payload in invalidPayloads {
            var requests = 0, completed = false
            FocusSessionTaskLookup.load(id: id, day: "2026-09-10", accountIsCurrent: { true }, read: { _, done in
                requests += 1
                done(self.lookupData(requests == 1 ? [self.legacyLookupRow] as Any : payload), 200)
            }, completion: { XCTAssertNil($0); completed = true })
            XCTAssertEqual(requests, 2)
            XCTAssertTrue(completed)
        }
    }

    func test_taskLookupAccountSwitchRejectsEitherDelayedResponse() {
        for switchDuringFallback in [false, true] {
            var current = true, requests = 0, completed = false
            var pending: ((Data?, Int) -> Void)?
            FocusSessionTaskLookup.load(id: lookupRow["id"] as! String, day: "2026-09-10",
                                       accountIsCurrent: { current }, read: { _, done in
                requests += 1; pending = done
            }, completion: { XCTAssertNil($0); completed = true })
            if switchDuringFallback {
                pending?(lookupData([legacyLookupRow]), 200)
                XCTAssertEqual(requests, 2)
            }
            current = false
            pending?(lookupData(switchDuringFallback ? ["day": "2026-09-10", "tasks": [lookupRow]] as Any : [legacyLookupRow]), 200)
            XCTAssertTrue(completed)
            XCTAssertEqual(requests, switchDuringFallback ? 2 : 1)
        }
    }

    func test_taskLookupFailedHTTPResponseDoesNotBecomeAnEditableRowOrTriggerFallback() {
        for status in [0, 401, 404, 500] {
            var requests = 0, completed = false
            FocusSessionTaskLookup.load(id: lookupRow["id"] as! String, day: "2026-09-10",
                                       accountIsCurrent: { true }, read: { _, done in
                requests += 1; done(self.lookupData([self.lookupRow]), status)
            }, completion: { XCTAssertNil($0); completed = true })
            XCTAssertEqual(requests, 1)
            XCTAssertTrue(completed)
        }
    }

    func test_taskLookupDiagnosesMissingPlannedTaskWithoutLoggingTaskContent() {
        let row = legacyLookupRow, id = row["id"] as! String
        var diagnostics: [String] = []
        var requests = 0
        FocusSessionTaskLookup.load(id: id, day: "2026-09-10", accountIsCurrent: { true }, read: { _, done in
            requests += 1
            done(self.lookupData(requests == 1 ? [row] as Any : ["day": "2026-09-10", "tasks": []]), 200)
        }, diagnostic: { diagnostics.append($0) }, completion: { XCTAssertNil($0) })
        XCTAssertEqual(requests, 2)
        XCTAssertTrue(diagnostics.contains { $0.contains("stage=by-id") && $0.contains("editable=false") && $0.contains("updated_at") })
        XCTAssertTrue(diagnostics.contains { $0.contains("stage=day-plan rows=0 matchingRow=false") })
        XCTAssertFalse(diagnostics.joined().contains(id))
        XCTAssertFalse(diagnostics.joined().contains(row["title"] as! String))
    }

    func test_subtaskReadDistinguishesEmptyFromMissingOrMalformed() {
        var raw = originalRow
        raw["subtasks"] = NSNull()
        XCTAssertEqual(FocusSessionSubtasks.decode(raw), [])
        raw.removeValue(forKey: "subtasks")
        XCTAssertNil(FocusSessionSubtasks.decode(raw))
        raw["subtasks"] = [["name": "Missing completion flag"]]
        XCTAssertNil(FocusSessionSubtasks.decode(raw))
    }

    func test_subtaskWriteTouchesOnlySubtasksAndRequiredIdentityFields() {
        let updated = [ToDoSubtask(id: "legacy-id", name: "Done", is_completed: true)]
        let body = FocusSessionSubtasks.body(updating: originalRow, subtasks: updated)!
        XCTAssertEqual(Set(body.keys), Set(["id", "title", "eisenhower_quadrant", "subtasks"]))
        XCTAssertEqual(body["eisenhower_quadrant"] as? Int, 2)
        let rows = body["subtasks"] as? [[String: Any]]
        XCTAssertEqual(rows?.first?["name"] as? String, "Done")
        XCTAssertEqual(rows?.first?["is_completed"] as? Bool, true)
        XCTAssertNil(rows?.first?["id"], "The canonical backend subtask shape has no client-generated ID")
        XCTAssertTrue(FocusSessionSubtasks.sameValues(updated, [.init(name: "Done", is_completed: true)]))
        XCTAssertFalse(FocusSessionSubtasks.sameValues(updated, [.init(name: "Done", is_completed: false)]))
        var incomplete = originalRow; incomplete.removeValue(forKey: "subtasks")
        XCTAssertNil(FocusSessionSubtasks.body(updating: incomplete, subtasks: []))
    }

    // MARK: - Spoons band

    func test_spoonsBands_splitTheScaleAtThree() {
        XCTAssertTrue(FocusSessionSpoonsBand.lowSpoons.contains(3), "1-3 is low spoons")
        XCTAssertFalse(FocusSessionSpoonsBand.lowSpoons.contains(4), "4 and up is not low spoons")
        XCTAssertTrue(FocusSessionSpoonsBand.fullSpoons.contains(4), "4-10 is full spoons")
        XCTAssertFalse(FocusSessionSpoonsBand.fullSpoons.contains(1), "1 is not full spoons")
    }

    // MARK: - Due-date scale

    func test_dueDateScale_roundTripsItsLabelledStops() {
        for stop in FocusSessionDueDateScale.stops {
            XCTAssertEqual(FocusSessionDueDateScale.days(atPosition: stop.position), stop.days,
                           "Each labelled stop must map back to its own day count")
        }
    }

    func test_dueDateScale_clampsOutsideTheTrack() {
        XCTAssertEqual(FocusSessionDueDateScale.days(atPosition: -1), FocusSessionDueDateScale.lowestDays,
                       "Dragging past the left edge pins to the first stop")
        XCTAssertEqual(FocusSessionDueDateScale.days(atPosition: 2), FocusSessionDueDateScale.highestDays,
                       "Dragging past the right edge pins to the last stop")
    }

    func test_dueDateScale_interpolatesBetweenStops() {
        let stops = FocusSessionDueDateScale.stops
        let midway = (stops[2].position + stops[3].position) / 2
        let days = FocusSessionDueDateScale.days(atPosition: midway)
        XCTAssertTrue(days > stops[2].days && days < stops[3].days,
                      "Half way between 'In a week' and 'In 2 weeks' is a day count between the two")
    }

    func test_dueDateScale_positionIsTheInverseOfDays() {
        for stop in FocusSessionDueDateScale.stops {
            XCTAssertEqual(FocusSessionDueDateScale.position(forDays: stop.days), stop.position,
                           accuracy: 0.0001, "position(forDays:) must undo days(atPosition:)")
        }
    }

    // MARK: - Filters

    private let referenceNow = Date(timeIntervalSince1970: 1_780_000_000)

    func test_filters_countOnlyTheControlsThatNarrow() {
        var filters = FocusSessionTaskFilters.none
        XCTAssertEqual(filters.activeCount, 0, "An untouched sheet adds no filters")
        filters.spoons = .lowSpoons
        filters.projectId = "p1"
        filters.dueInDaysUpperBound = 8
        XCTAssertEqual(filters.activeCount, 3, "All three controls count once each")
    }

    func test_filters_emptyProjectIdDoesNotCount() {
        var filters = FocusSessionTaskFilters.none
        filters.projectId = ""
        XCTAssertTrue(filters.isEmpty, "A cleared project is not an active filter")
    }

    func test_filter_bySpoons() {
        let tasks = [makePickerTask(id: "a", title: "Easy", perspiration: 2),
                     makePickerTask(id: "b", title: "Hard", perspiration: 8)]
        var filters = FocusSessionTaskFilters.none
        filters.spoons = .lowSpoons
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "", excludingIds: [], filters: filters).map { $0.id },
                       ["a"], "Low spoons keeps only the cheap task")
    }

    func test_filter_byProject() {
        let tasks = [makePickerTask(id: "a", title: "One", projectId: "p1"),
                     makePickerTask(id: "b", title: "Two", projectId: "p2")]
        var filters = FocusSessionTaskFilters.none
        filters.projectId = "p2"
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "", excludingIds: [], filters: filters).map { $0.id },
                       ["b"], "The project filter keeps only that project's tasks")
    }

    func test_filter_byDueDateRange() {
        let tasks = [makePickerTask(id: "soon", title: "Soon", dueInDays: 2, now: referenceNow),
                     makePickerTask(id: "later", title: "Later", dueInDays: 20, now: referenceNow)]
        var filters = FocusSessionTaskFilters.none
        filters.dueInDaysLowerBound = 0
        filters.dueInDaysUpperBound = 8
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "", excludingIds: [],
                                                       filters: filters, now: referenceNow).map { $0.id },
                       ["soon"], "Only tasks due inside the range survive")
    }

    func test_filter_dueDateRangeStartingAtOverdueKeepsPastDueTasks() {
        let tasks = [makePickerTask(id: "late", title: "Late", dueInDays: -5, now: referenceNow)]
        var filters = FocusSessionTaskFilters.none
        filters.dueInDaysLowerBound = FocusSessionDueDateScale.overdueDays
        filters.dueInDaysUpperBound = 8
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "", excludingIds: [],
                                                       filters: filters, now: referenceNow).count, 1,
                       "The leftmost stop is 'Overdue', so it must keep everything already past due")
    }

    func test_filter_dueDateRangeExcludesTasksWithNoDueDate() {
        let tasks = [makePickerTask(id: "undated", title: "Undated")]
        var filters = FocusSessionTaskFilters.none
        filters.dueInDaysUpperBound = 8
        XCTAssertTrue(FocusSessionTaskFilter.matching(tasks, query: "", excludingIds: [],
                                                      filters: filters, now: referenceNow).isEmpty,
                      "A task with no due date cannot satisfy a due-date range")
    }

    func test_filter_combinesWithTheSearchQuery() {
        let tasks = [makePickerTask(id: "a", title: "Summarise", perspiration: 2),
                     makePickerTask(id: "b", title: "Summarise later", perspiration: 8)]
        var filters = FocusSessionTaskFilters.none
        filters.spoons = .lowSpoons
        XCTAssertEqual(FocusSessionTaskFilter.matching(tasks, query: "summarise", excludingIds: [], filters: filters).map { $0.id },
                       ["a"], "Search and filters both apply")
    }

    // MARK: - Project search

    func test_projectFilter_matchesIgnoringCaseAndAccents() {
        let projects = [FocusSessionProject(id: "p1", name: "Revisión de código"),
                        FocusSessionProject(id: "p2", name: "Soil Sampling")]
        XCTAssertEqual(FocusSessionTaskFilter.matching(projects, query: "revision").map { $0.id }, ["p1"],
                       "Project search should not require accents")
        XCTAssertEqual(FocusSessionTaskFilter.matching(projects, query: "  ").count, 2,
                       "A blank query lists every project")
    }

    func test_projectList_skipsRowsMissingAnIdOrName() {
        let raw: [NSDictionary] = [["id": "p1", "name": "Real"], ["id": "p2"], ["name": "Nameless"]]
        XCTAssertEqual(FocusSessionProject.list(from: raw).map { $0.id }, ["p1"],
                       "A project needs both an id and a name to be selectable")
    }

    // MARK: - Queue carries the design's badges

    func test_queue_roundTripsTheIconAndTopScore() {
        let task = FocusSessionTask(id: "a", title: "One", topScore: 4.2, iconEmoji: "📚")
        let decoded = FocusSessionTaskQueue.decode(FocusSessionTaskQueue.encode([task]))
        XCTAssertEqual(decoded.first?.topScore, 4.2, "The TOP score must survive a queue round trip")
        XCTAssertEqual(decoded.first?.iconEmoji, "📚", "The emoji must survive a queue round trip")
    }

    // MARK: - More strings

    func test_addFiltersButton_usesTheSingularCopy_forOneFilter() {
        var strings = FocusSessionStrings()
        strings.addSingleFilterButton = "Add 1 filter"
        XCTAssertEqual(strings.addFiltersButton(count: 1), "Add 1 filter",
                       "One filter should not read as \"Add 1 filters\"")
    }

    func test_daysFromToday_signsPositiveOffsets() {
        var strings = FocusSessionStrings()
        strings.daysFromToday = "<COUNT> days"
        XCTAssertEqual(strings.daysFromToday(8), "+8 days", "The design shows a leading + for future days")
        XCTAssertEqual(strings.daysFromToday(0), "0 days", "Today has no sign")
        XCTAssertEqual(strings.daysFromToday(-3), "-3 days", "Overdue days keep their minus")
    }

    func test_topScoreBadge_showsOneDecimal() {
        var strings = FocusSessionStrings()
        strings.topScoreBadge = "TOP: <SCORE>"
        XCTAssertEqual(strings.topScoreBadge(4.25), "TOP: 4.2", "The design shows one decimal place")
    }

    func test_bandLabel_mapsTheOneToTenScale() {
        var strings = FocusSessionStrings()
        strings.bandLow = "Low"; strings.bandNormal = "Normal"
        strings.bandHigh = "High"; strings.bandCritical = "Critical"
        XCTAssertEqual(strings.bandLabel(forLevel: 2), "Low", "1-3 reads as low")
        XCTAssertEqual(strings.bandLabel(forLevel: 5), "Normal", "4-6 reads as normal")
        XCTAssertEqual(strings.bandLabel(forLevel: 8), "High", "7-8 reads as high")
        XCTAssertEqual(strings.bandLabel(forLevel: 10), "Critical", "9-10 reads as critical")
    }

    // MARK: - Session-start routing

    func test_headlessPlayerReload_onlyWhenPendingAndSomethingIsBlocking() {
        XCTAssertTrue(FocusSessionRouting.shouldReloadHeadlessPlayer(isReloadPending: true, isBlockingActive: true),
                      "A flagged reload while something is blocking must happen")
        XCTAssertFalse(FocusSessionRouting.shouldReloadHeadlessPlayer(isReloadPending: true, isBlockingActive: false),
                       "There is nothing to reload the player for when nothing is blocking")
        XCTAssertFalse(FocusSessionRouting.shouldReloadHeadlessPlayer(isReloadPending: false, isBlockingActive: true),
                       "Without a pending flag the player must not be reloaded on every navigation")
    }

    // MARK: - A blocking schedule is not a focus session (report 2026-09-16_15-13-57)

    func test_blockingScheduleWithNoSession_reportsNoSession() {
        XCTAssertFalse(FocusSessionPresence.isInSession(isFocusModeOn: false,
                                                        isFocusModePaused: false,
                                                        isSuperFocusOn: false),
                       "A running blocking schedule contributes nothing to isInSession — it is a timetable, not a session")
        XCTAssertTrue(FocusSessionPresence.isBlockingActive(isInSession: false,
                                                            isAllowedActivityRunning: false,
                                                            isCustomScheduleOn: true),
                      "…but it IS blocking, and the blocking state must still say so")
        XCTAssertEqual(FocusSessionRouting.destination(isInSession: false, isAllowedActivityRunning: false),
                       .startSession,
                       "With only a schedule running, the Focus Session tab must offer to start a session")
    }

    func test_focusSession_reportsASession() {
        XCTAssertTrue(FocusSessionPresence.isInSession(isFocusModeOn: true,
                                                       isFocusModePaused: false,
                                                       isSuperFocusOn: false),
                      "A running focus mode is a session")
        XCTAssertTrue(FocusSessionPresence.isInSession(isFocusModeOn: false,
                                                       isFocusModePaused: true,
                                                       isSuperFocusOn: false),
                      "A paused session is still the user's session")
        XCTAssertTrue(FocusSessionPresence.isInSession(isFocusModeOn: false,
                                                       isFocusModePaused: false,
                                                       isSuperFocusOn: true),
                      "A super-focus run is a session")
        XCTAssertEqual(FocusSessionRouting.destination(isInSession: true, isAllowedActivityRunning: false),
                       .runningSession,
                       "A real session shows the ongoing-session screen")
    }

    func test_focusSessionDuringABlockingSchedule_stillReportsASession() {
        let inSession = FocusSessionPresence.isInSession(isFocusModeOn: true,
                                                         isFocusModePaused: false,
                                                         isSuperFocusOn: false)
        XCTAssertTrue(inSession, "A schedule running alongside a session must not hide the session")
        XCTAssertTrue(FocusSessionPresence.isBlockingActive(isInSession: inSession,
                                                            isAllowedActivityRunning: false,
                                                            isCustomScheduleOn: true),
                      "Both at once is still blocking")
        XCTAssertEqual(FocusSessionRouting.destination(isInSession: inSession, isAllowedActivityRunning: false),
                       .runningSession,
                       "The session wins the screen; the schedule keeps blocking in the background")
    }

    func test_nothingRunning_isNeitherASessionNorBlocking() {
        let inSession = FocusSessionPresence.isInSession(isFocusModeOn: false,
                                                         isFocusModePaused: false,
                                                         isSuperFocusOn: false)
        XCTAssertFalse(inSession, "Nothing running is no session")
        XCTAssertFalse(FocusSessionPresence.isBlockingActive(isInSession: inSession,
                                                             isAllowedActivityRunning: false,
                                                             isCustomScheduleOn: false),
                       "Nothing running is nothing blocking")
        XCTAssertEqual(FocusSessionRouting.destination(isInSession: inSession, isAllowedActivityRunning: false),
                       .startSession,
                       "Nothing running means offer to start")
    }

    func test_allowedRoutineActivity_blocksAndKeepsItsScreen_butIsNotASession() {
        XCTAssertTrue(FocusSessionPresence.isBlockingActive(isInSession: false,
                                                            isAllowedActivityRunning: true,
                                                            isCustomScheduleOn: false),
                      "A routine habit with a block list is blocking")
        XCTAssertEqual(FocusSessionRouting.destination(isInSession: false, isAllowedActivityRunning: true),
                       .runningSession,
                       "The routine paths that ask for this screen are mid-activity and keep it — unchanged by the schedule fix")
    }

    func test_startingASession_doesNotResizeAnOrdinaryWindow() {
        XCTAssertEqual(FocusSessionRouting.windowSizing(isFullScreenWindowVisible: false,
                                                        isFullScreenModeEnabled: false),
                       .leaveAsIs,
                       "Starting a session must leave a normal window at the size the user gave it")
        XCTAssertEqual(FocusSessionRouting.windowSizing(isFullScreenWindowVisible: false,
                                                        isFullScreenModeEnabled: true),
                       .leaveAsIs,
                       "Full-screen mode being enabled must not blow a small window up to full screen just because a session started")
    }

    func test_startingASession_keepsABorderlessFullScreenActivityFullScreen() {
        XCTAssertEqual(FocusSessionRouting.windowSizing(isFullScreenWindowVisible: true,
                                                        isFullScreenModeEnabled: true),
                       .keepFullScreen,
                       "A routine or break owning the whole screen must not be shrunk to a 1008x600 window, which would expose the desktop")
    }

    func test_borderlessWindowIsRestored_whenFullScreenModeHasBeenTurnedOff() {
        XCTAssertEqual(FocusSessionRouting.windowSizing(isFullScreenWindowVisible: true,
                                                        isFullScreenModeEnabled: false),
                       .restoreSmallWindow,
                       "A borderless window with the setting off must get its title bar back, not be left unmovable")
    }

    // MARK: - Compact layout: the bear beside the timing card

    func test_compactBear_sitsBesideTheCardAtTheUsersWindowSize() {
        // The user's report was a window about 780pt wide; the row gets that less the screen padding.
        let scale = FocusSessionScale(contentWidth: 780)
        let available = 780 - scale.pt(FocusSessionLayout.screenPadding) * 2
        let width = FocusSessionCompactLayout.bearWidth(availableWidth: available, scale: scale)
        XCTAssertNotNil(width, "At the user's window size the bear must be drawn, not dropped")
        XCTAssertLessThanOrEqual(width ?? 0, available / 2,
                                 "The bear takes at most its half, leaving the timing card the other half")
        XCTAssertGreaterThan(width ?? 0, 0, "A drawn bear needs a real width")
    }

    func test_compactBear_neverExceedsItsDesignSize() {
        let scale = FocusSessionScale(contentWidth: 1600)
        let width = FocusSessionCompactLayout.bearWidth(availableWidth: 1400, scale: scale)
        XCTAssertEqual(width ?? 0, scale.pt(FocusSessionBearArtwork.width), accuracy: 0.01,
                       "In a wide but short window the bear stays at its design size and the card keeps the rest")
    }

    func test_compactBear_isDroppedRatherThanSquashedInANarrowWindow() {
        let scale = FocusSessionScale(contentWidth: 420)
        XCTAssertNil(FocusSessionCompactLayout.bearWidth(availableWidth: 420, scale: scale),
                     "Below the floor two columns stop working, so the card goes back to full width")
        XCTAssertNil(FocusSessionCompactLayout.bearWidth(availableWidth: 0, scale: scale),
                     "A zero-width row draws no bear")
    }

    func test_compactBear_floorIsInclusive() {
        let scale = FocusSessionScale(contentWidth: 700)
        XCTAssertNotNil(FocusSessionCompactLayout.bearWidth(
                            availableWidth: FocusSessionCompactLayout.sideBySideMinimumWidth, scale: scale),
                        "Exactly at the floor the two columns still fit")
    }

    // MARK: - Left-menu "Focusing (Nm left)" row

    func test_minutesRemaining_roundsUp_soAlmostDoneNeverReadsZero() {
        let now = Date()
        XCTAssertEqual(FocusSessionClock.minutesRemaining(until: now.addingTimeInterval(20), now: now), 1,
                       "Twenty seconds left should read 1m, not 0m")
        XCTAssertEqual(FocusSessionClock.minutesRemaining(until: now.addingTimeInterval(29 * 60), now: now), 29,
                       "An exact 29 minutes reads 29m")
        XCTAssertEqual(FocusSessionClock.minutesRemaining(until: now.addingTimeInterval(29 * 60 + 5), now: now), 30,
                       "A part-minute rounds up to the next whole minute")
    }

    func test_minutesRemaining_isZero_onceTheSessionHasPassed() {
        let now = Date()
        XCTAssertEqual(FocusSessionClock.minutesRemaining(until: now.addingTimeInterval(-120), now: now), 0,
                       "An overrun session has no minutes left rather than negative ones")
    }

    // MARK: - Intention and current task are separate

    func test_workContext_keepsTheIntentionAndTheTaskApart() {
        let context = FocusSessionWorkContext.resolve(activeTaskTitle: "Re-do proposal",
                                                      intention: "call schools")
        XCTAssertEqual(context.currentTask, "Re-do proposal", "The task is what the user is doing now")
        XCTAssertEqual(context.intention, "call schools", "The intention is the session's stated goal")
    }

    func test_workContext_hasNoTask_whenTheQueueIsEmpty() {
        let context = FocusSessionWorkContext.resolve(activeTaskTitle: nil, intention: "call schools")
        XCTAssertNil(context.currentTask, "No queued task means no current task, not a copy of the goal")
        XCTAssertEqual(context.intention, "call schools", "The goal is unaffected")
    }

    func test_workContext_treatsABlankTaskAsAbsentAndTrims() {
        XCTAssertNil(FocusSessionWorkContext.resolve(activeTaskTitle: "  ", intention: "g").currentTask,
                     "A blank title is not a task")
        XCTAssertEqual(FocusSessionWorkContext.resolve(activeTaskTitle: " Re-do proposal ", intention: " g ").currentTask,
                       "Re-do proposal", "Values are sent onward, so they are trimmed")
    }

    // MARK: - The intention is not editable from outside the goal editor

    func test_superStrictSessionForbidsChangingTheIntention() {
        XCTAssertFalse(FocusSessionIntentionLock.mayChangeIntention(isSuperStrict: true),
                       "A super-strict session locks the focus goal")
        XCTAssertTrue(FocusSessionIntentionLock.mayChangeIntention(isSuperStrict: false),
                      "Other strictness levels allow editing the goal")
    }

    func test_changingTheCurrentTaskIsAllowedInEveryStrictness() {
        XCTAssertTrue(FocusSessionIntentionLock.mayChangeCurrentTask(isSuperStrict: true),
                      "Picking what you work on next is never locked — only the stated goal is")
        XCTAssertTrue(FocusSessionIntentionLock.mayChangeCurrentTask(isSuperStrict: false),
                      "Same at other strictness levels")
    }

    /// Regression for the strictness bypass: a caller that "set the current task" by writing
    /// `whatToAchieveInFocusBlock` edited the goal, which a super-strict session forbids.
    func test_settingTheCurrentTaskLeavesASuperStrictIntentionUntouched() {
        let intention = "call schools"
        var queue = [makeTask(id: "a", title: intention, isActive: true)]
        queue = FocusSessionTaskQueue.appending(queue, newTasks: [makeTask(id: "b", title: "Re-do proposal")])
        queue = FocusSessionTaskQueue.focusing(queue, on: "b")

        let context = FocusSessionWorkContext.resolve(
            activeTaskTitle: FocusSessionTaskQueue.activeTask(in: queue)?.title, intention: intention)
        XCTAssertEqual(context.currentTask, "Re-do proposal", "The task followed the change")
        XCTAssertEqual(context.intention, intention,
                       "The session's goal must be unchanged — writing it here bypassed the super-strict lock")
        XCTAssertFalse(FocusSessionIntentionLock.mayChangeIntention(isSuperStrict: true),
                       "…and that lock is still in force")
    }

    func test_currentTask_followsAQueueChangeMadeElsewhere() {
        var queue = [makeTask(id: "a", title: "call schools", isActive: true),
                     makeTask(id: "b", title: "Re-do proposal")]
        XCTAssertEqual(FocusSessionTaskQueue.activeTask(in: queue)?.title, "call schools",
                       "Before the buddy changes it")
        queue = FocusSessionTaskQueue.focusing(queue, on: "b")
        XCTAssertEqual(FocusSessionTaskQueue.activeTask(in: queue)?.title, "Re-do proposal",
                       "After the buddy changes it, the session screen's active task follows")
    }

    // MARK: - Session total / progress (the bar that never moved)

    /// Regression: `focusModeSecondsToPerform` can still hold a *previous* session's value when a new
    /// one starts. Reading it alone gave a total shorter than the time remaining, so elapsed clamped
    /// to zero — the bar sat at 00:00 and the total disagreed with the countdown.
    func test_sessionTotal_isNeverShorterThanTheTimeRemaining() {
        let total = FocusSessionClock.sessionTotalSeconds(plannedMinutes: 0, liveSeconds: 270,
                                                          remainingSeconds: 1192)
        XCTAssertGreaterThanOrEqual(total, 1192,
                                    "A stale live length must not make the total shorter than what is left")
        XCTAssertGreaterThan(total - 1192, -1, "…so elapsed can never be negative")
    }

    func test_sessionTotal_prefersThePlannedLength() {
        XCTAssertEqual(FocusSessionClock.sessionTotalSeconds(plannedMinutes: 30, liveSeconds: 0,
                                                             remainingSeconds: 1200),
                       1800, "A 30-minute session totals 30 minutes")
    }

    func test_sessionTotal_followsAnExtendedSession() {
        XCTAssertEqual(FocusSessionClock.sessionTotalSeconds(plannedMinutes: 30, liveSeconds: 2400,
                                                             remainingSeconds: 2300),
                       2400, "Extending the session grows the total the bar measures against")
    }

    func test_progress_advancesAsTheSessionRuns() {
        let total = FocusSessionClock.sessionTotalSeconds(plannedMinutes: 30, liveSeconds: 0,
                                                           remainingSeconds: 1800)
        let atStart = FocusSessionClock.progress(elapsedSeconds: total - 1800, totalSeconds: total)
        let laterTotal = FocusSessionClock.sessionTotalSeconds(plannedMinutes: 30, liveSeconds: 0,
                                                               remainingSeconds: 900)
        let halfway = FocusSessionClock.progress(elapsedSeconds: laterTotal - 900, totalSeconds: laterTotal)
        XCTAssertEqual(atStart, 0, accuracy: 0.0001, "Nothing elapsed at the start")
        XCTAssertEqual(halfway, 0.5, accuracy: 0.0001, "Half the session gone is half the bar")
    }

    // MARK: - Time on the current task

    func test_compactElapsed_readsCoarselySoTheCardIsNotTicking() {
        let units = FocusSessionDurationUnits(hour: "hr", minute: "min", second: "sec")
        XCTAssertEqual(FocusSessionClock.compactElapsed(seconds: 42, units: units), "42 sec",
                       "Seconds in the first minute")
        XCTAssertEqual(FocusSessionClock.compactElapsed(seconds: 12 * 60 + 30, units: units), "12 min",
                       "Whole minutes after that — no second-by-second churn")
        XCTAssertEqual(FocusSessionClock.compactElapsed(seconds: 3600 + 5 * 60, units: units), "1 hr 5 min",
                       "Hours and minutes past the hour")
    }

    func test_taskTimer_countsFromWhenTheTaskBecameActive() {
        let start = Date()
        var timer = FocusSessionTaskTimer()
        timer.activate(taskId: "a", now: start)
        XCTAssertEqual(timer.elapsedSeconds(now: start.addingTimeInterval(90)), 90,
                       "Time on the task is measured from when it became active")
    }

    func test_taskTimer_restartsWhenTheActiveTaskChanges() {
        let start = Date()
        var timer = FocusSessionTaskTimer()
        timer.activate(taskId: "a", now: start)
        timer.activate(taskId: "b", now: start.addingTimeInterval(120))
        XCTAssertEqual(timer.elapsedSeconds(now: start.addingTimeInterval(150)), 30,
                       "Switching tasks starts the new task's count from zero")
    }

    func test_taskTimer_ignoresBeingToldTheSameTaskAgain() {
        let start = Date()
        var timer = FocusSessionTaskTimer()
        timer.activate(taskId: "a", now: start)
        timer.activate(taskId: "a", now: start.addingTimeInterval(60))
        XCTAssertEqual(timer.elapsedSeconds(now: start.addingTimeInterval(90)), 90,
                       "A refresh must not reset the clock")
    }

    func test_taskTimer_doesNotAccrueWhileThePauseIsOn() {
        let start = Date()
        var timer = FocusSessionTaskTimer()
        timer.activate(taskId: "a", now: start)
        timer.pause(now: start.addingTimeInterval(60))
        XCTAssertEqual(timer.elapsedSeconds(now: start.addingTimeInterval(600)), 60,
                       "A paused session accrues no time on the task")
        timer.resume(now: start.addingTimeInterval(600))
        XCTAssertEqual(timer.elapsedSeconds(now: start.addingTimeInterval(630)), 90,
                       "Resuming picks up where it left off")
    }

    func test_taskTimer_isEmptyWithNoTask() {
        var timer = FocusSessionTaskTimer()
        timer.activate(taskId: nil)
        XCTAssertEqual(timer.elapsedSeconds(), 0, "No task means nothing to count")
        XCTAssertFalse(timer.isRunning, "…and nothing running")
    }

    // MARK: - Changing the block list mid-session (report 2026-09-11_10-15-13)

    func testBlockListMayBeSwappedOnlyWhenTheSessionAllowsIt() {
        XCTAssertTrue(FocusSessionBlockListSwitch.isAllowed(isSessionRunning: true, strictness: ._NORMAL_,
                                                            isClassSession: false))
        XCTAssertTrue(FocusSessionBlockListSwitch.isAllowed(isSessionRunning: true, strictness: ._STRICT_,
                                                            isClassSession: false),
                      "Strict still lets you choose what you are blocking")
        XCTAssertFalse(FocusSessionBlockListSwitch.isAllowed(isSessionRunning: true, strictness: ._SUPER_STRICT_,
                                                             isClassSession: false),
                       "Swapping to a laxer list is what super-strict exists to prevent")
        XCTAssertFalse(FocusSessionBlockListSwitch.isAllowed(isSessionRunning: true, strictness: ._NORMAL_,
                                                             isClassSession: true),
                       "During a class session the teacher owns the settings")
        XCTAssertFalse(FocusSessionBlockListSwitch.isAllowed(isSessionRunning: false, strictness: ._NORMAL_,
                                                             isClassSession: false),
                       "Nothing to switch when no session is running")
    }

    // MARK: - Picker row icons (report 2026-09-11_07-33-27)

    func test_projectList_decodesTheProjectIcon() {
        let projects = FocusSessionProject.list(from: [["id": "p1", "name": "Grant", "icon": "1f4dd"] as NSDictionary])
        XCTAssertEqual(projects.first?.iconEmoji, "📝", "Hex code points decode the same way a to-do's icon does")
    }

    func test_projectIcon_prefersTheProjectIdOverTheName() {
        let projects = [FocusSessionProject(id: "p1", name: "Grant", icon: "📝"),
                        FocusSessionProject(id: "p2", name: "grant", icon: "🏠")]
        XCTAssertEqual(FocusSessionProject.icon(for: "p2", name: "Grant", in: projects), "🏠",
                       "A row that knows its project id must not be matched by name")
    }

    func test_projectIcon_fallsBackToACaseInsensitiveNameMatch() {
        let projects = [FocusSessionProject(id: "p1", name: "Grant application", icon: "📝")]
        XCTAssertEqual(FocusSessionProject.icon(for: nil, name: "grant application", in: projects), "📝",
                       "Day Plan rows carry only the project name they were imported with")
        XCTAssertNil(FocusSessionProject.icon(for: nil, name: "Other", in: projects))
        XCTAssertNil(FocusSessionProject.icon(for: nil, name: "  ", in: projects), "Blank names match nothing")
    }

    func test_pickerRow_carriesTheToDoIcon() {
        XCTAssertEqual(FocusSessionPickerTask.make(from: makeToDo())?.iconEmoji, "📚",
                       "The row shows the to-do's own emoji")
        XCTAssertNil(FocusSessionPickerTask.make(from: makeToDo(icon: nil))?.iconEmoji, "No icon stays no icon")
    }

    // MARK: - Modal panel height (report 2026-09-17_12-59-15)

    /// The design height of the task/notes panels, in POINTS at 1× — 1509 design pixels on a 2× frame.
    private let designSheetHeightPoints: CGFloat = 754.5
    private var sheetScale: FocusSessionScale {
        FocusSessionScale(contentWidth: FocusSessionTokens.designWidthPoints)
    }

    private func sheetHeight(onScreenOf visibleHeight: CGFloat) -> CGFloat {
        FocusSessionSheetMetrics.height(designPixels: FocusSessionSheetMetrics.designHeightPixels,
                                        scale: sheetScale,
                                        visibleScreenHeight: visibleHeight)
    }

    func test_sheetHeight_isTheDesignHeightAtDesignScale() {
        XCTAssertEqual(sheetScale.pt(FocusSessionSheetMetrics.designHeightPixels), designSheetHeightPoints,
                       accuracy: 0.01, "The panel is authored at 1509 design pixels = 754.5pt")
    }

    func test_sheetHeight_shrinksToFitALowResolutionScreen() {
        // A 1280x800 display leaves about 775pt once the menu bar is gone. The design panel is 754.5pt,
        // which LOOKS like it fits — but centred with the window's chrome it pushed Cancel and the
        // create button off the bottom. The panel now gives the screen its margin back.
        let height = sheetHeight(onScreenOf: 775)
        XCTAssertEqual(height, 775 - FocusSessionSheetMetrics.screenMarginPoints, accuracy: 0.01)
        XCTAssertLessThan(height, designSheetHeightPoints, "A short screen must cap the panel")
    }

    func test_sheetHeight_keepsTheDesignHeightWhenItFits() {
        // A 1440pt-tall display has room to spare, so nothing about the design changes there.
        XCTAssertEqual(sheetHeight(onScreenOf: 1440), designSheetHeightPoints, accuracy: 0.01)
    }

    func test_sheetHeight_neverExceedsTheScreenItOpensOn() {
        for visible in stride(from: CGFloat(400), through: 1600, by: 25) {
            let height = sheetHeight(onScreenOf: visible)
            XCTAssertLessThanOrEqual(height, visible,
                                     "A panel taller than the screen puts its footer buttons out of reach")
            XCTAssertLessThanOrEqual(height, designSheetHeightPoints + 0.01,
                                     "The panel never draws larger than the design")
        }
    }

    func test_sheetHeight_stopsShrinkingAtAUsableFloor() {
        // Below the floor there is no form area left to scroll in, so the panel stops following the
        // screen down rather than collapsing to a title bar.
        XCTAssertEqual(sheetHeight(onScreenOf: 200), FocusSessionSheetMetrics.minimumHeightPoints, accuracy: 0.01)
        XCTAssertEqual(sheetHeight(onScreenOf: 1), FocusSessionSheetMetrics.minimumHeightPoints, accuracy: 0.01)
    }

    func test_sheetHeight_fallsBackToTheDesignWhenTheScreenIsUnknown() {
        XCTAssertEqual(sheetHeight(onScreenOf: 0), designSheetHeightPoints, accuracy: 0.01,
                       "No screen to measure is not a reason to shrink the panel")
        XCTAssertEqual(sheetHeight(onScreenOf: -1), designSheetHeightPoints, accuracy: 0.01)
    }
}

#if DEBUG
// Opt-in visual capture uses the real SwiftUI screen inside the isolated XCTest host. It is skipped
// for ordinary local test runs and never starts a real session or performs network requests.
extension FocusSessionTests {
    func test_ongoingVisualFixtures() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["FOCUSBEAR_CAPTURE_ONGOING"] == "1"
                || environment["TEST_RUNNER_FOCUSBEAR_CAPTURE_ONGOING"] == "1" else {
            throw XCTSkip("Enable FOCUSBEAR_CAPTURE_ONGOING to export the deterministic visual fixtures")
        }
        XCTAssertTrue(LogicTestHost.isEnabled)
        if Thread.isMainThread { try captureOngoingFixtures() }
        else { try DispatchQueue.main.sync { try self.captureOngoingFixtures() } }
    }

    private func captureOngoingFixtures() throws {
        let environment = ProcessInfo.processInfo.environment
        let outputPath = try XCTUnwrap(environment["FOCUSBEAR_CAPTURE_DIRECTORY"]
            ?? environment["TEST_RUNNER_FOCUSBEAR_CAPTURE_DIRECTORY"])
        guard outputPath.hasPrefix("/") else {
            XCTFail("Capture output must be an explicit absolute directory"); return
        }
        let output = URL(fileURLWithPath: outputPath, isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        let oldArguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        var arguments = oldArguments
        arguments[kUserdefaultsCustomSpotifyTracks] = Data("[]".utf8)
        arguments[kUserdefaultsYouTubeMusicTracks] = Data("[]".utf8)
        // Volatile overrides prevent the visual fixture reading or backfilling personal music links.
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
        let oldTracks = arrAllTracks, oldFont = SettingsManagerObject.selectedFontIndex
        arrAllTracks = []
        SettingsManagerObject.selectedFontIndex = systemFontIndex
        FocusSessionVisualNetworkGuard.reset()
        URLProtocol.registerClass(FocusSessionVisualNetworkGuard.self)
        defer {
            URLProtocol.unregisterClass(FocusSessionVisualNetworkGuard.self)
            UserDefaults.standard.setVolatileDomain(oldArguments, forName: UserDefaults.argumentDomain)
            arrAllTracks = oldTracks
            SettingsManagerObject.selectedFontIndex = oldFont
        }

        let tasks = [
            FocusSessionTask(id: "11111111-1111-4111-8111-111111111111", title: "The Soil Sampling Report",
                             details: "Describe the sampling method and compare the results from each site.",
                             durationSeconds: 1800, status: .inProgress, isActive: true, topScore: 6.3,
                             iconEmoji: "🧪", projectName: "Soil Sampling Lab Report"),
            FocusSessionTask(id: "22222222-2222-4222-8222-222222222222", title: "Review the field notes",
                             durationSeconds: 900, topScore: 4.8, iconEmoji: "📒"),
            FocusSessionTask(id: "33333333-3333-4333-8333-333333333333", title: "Prepare the results table",
                             durationSeconds: 1200, topScore: 4.1, iconEmoji: "📊")
        ]
        let subtasks: [ToDoSubtask] = [
            .init(name: "Check the soil collection locations", is_completed: true),
            .init(name: "Summarise the sample preparation method", is_completed: false),
            .init(name: "Compare moisture and texture measurements", is_completed: false)
        ]
        let sizes: [(String, NSSize)] = [
            ("wide", NSSize(width: 1728, height: 1117)),
            ("wide-short", NSSize(width: 1280, height: 720)),
            ("compact", NSSize(width: 900, height: 720)),
            // Measured window sizes after subtracting the expanded sidebar and menu-bar inset.
            ("native-main-content", NSSize(width: 1370, height: 875)),
            ("native-secondary-content", NSSize(width: 794, height: 644))
        ]
        var manifest: [[String: Any]] = []
        for (sizeName, size) in sizes {
            for dark in [false, true] {
                let store = FocusSessionStore.visualFixture(tasks: tasks, subtasks: subtasks,
                    blockListName: "Study", goal: "Finish the methods section and check the results table.",
                    notes: "Remember to compare the moisture readings.\n\nCheck the field notebook for the collection times.\n\nAdd the reference for the sampling method.")
                manifest.append(try capture(store: store, size: size, dark: dark,
                                            name: "ongoing-\(sizeName)-\(dark ? "dark" : "light")",
                                            into: output))
            }
        }
        // The two task-panel states this change is about, which the fixture above (three live tasks)
        // never reaches: the clickable empty active-task card, and a queue whose only task is done —
        // whose heading must read "Task Queue (0)".
        let taskPanelStateSize = NSSize(width: 1370, height: 875)
        let completedTask = FocusSessionTask(id: "44444444-4444-4444-8444-444444444444",
                                             title: "Software Development", durationSeconds: 600,
                                             status: .completed, iconEmoji: "\u{1F4BB}")
        for dark in [false, true] {
            let appearance = dark ? "dark" : "light"
            let empty = FocusSessionStore.visualFixture(tasks: [], subtasks: [], blockListName: "Study",
                                                        goal: "", notes: "")
            manifest.append(try capture(store: empty, size: taskPanelStateSize, dark: dark,
                                        name: "ongoing-empty-task-\(appearance)", into: output))
            let finished = FocusSessionStore.visualFixture(tasks: [completedTask], subtasks: [],
                                                           blockListName: "Study", goal: "", notes: "")
            manifest.append(try capture(store: finished, size: taskPanelStateSize, dark: dark,
                                        name: "ongoing-completed-queue-\(appearance)", into: output))
        }
        XCTAssertEqual(FocusSessionVisualNetworkGuard.requestCount, 0, "Visual fixtures must never contact live services")
        let data = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: output.appendingPathComponent("manifest.json"), options: .atomic)
    }

    /// Renders one prepared store offscreen and writes it as `name`.png. Returns its manifest row.
    private func capture(store: FocusSessionStore, size: NSSize, dark: Bool,
                         name: String, into output: URL) throws -> [String: Any] {
        let root = FocusSessionScreen(store: store).environment(\.colorScheme, dark ? .dark : .light)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.setContentHuggingPriority(.init(1), for: .horizontal)
        hosting.setContentHuggingPriority(.init(1), for: .vertical)
        hosting.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        hosting.setContentCompressionResistancePriority(.init(1), for: .vertical)
        if #available(macOS 13.0, *) { hosting.sizingOptions = [] }
        hosting.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        window.isExcludedFromWindowsMenu = true
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        // The window stays unordered and never becomes key; cacheDisplay renders offscreen.
        window.contentView = hosting
        window.setContentSize(size)
        window.layoutIfNeeded()
        for _ in 0..<6 {
            window.makeFirstResponder(nil)
            hosting.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        hosting.layoutSubtreeIfNeeded()
        let bearRenderers = FocusBearAnimationView.freezeAnimationsForVisualFixture(in: hosting)
        XCTAssertEqual(bearRenderers.count, 1, "The capture must include the real bundled bear animation")
        XCTAssertEqual(bearRenderers.first?["capture"], "Main Thread")
        hosting.layoutSubtreeIfNeeded()
        XCTAssertEqual(hosting.bounds.width, size.width, accuracy: 1)
        XCTAssertEqual(hosting.bounds.height, size.height, accuracy: 1)
        // Match the window's actual backing density. Forcing 2x in an offscreen 1x window can
        // composite cached SwiftUI layers at the wrong coordinates.
        let bitmap = try XCTUnwrap(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
        hosting.needsDisplay = true
        hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        XCTAssertGreaterThan(png.count, 20_000, "The real screen should render substantial visual content")
        try png.write(to: output.appendingPathComponent(name + ".png"), options: .atomic)
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        defer { window.contentView = nil; window.close() }
        return ["file": name + ".png", "width": Int(size.width), "height": Int(size.height),
                "pixelsWide": bitmap.pixelsWide, "pixelsHigh": bitmap.pixelsHigh,
                "scale": Double(bitmap.pixelsWide) / Double(size.width),
                "appearance": dark ? "dark" : "light", "syntheticData": true,
                "bearRenderers": bearRenderers, "bearFrameProgress": 0.35]
    }
}

private final class FocusSessionVisualNetworkGuard: URLProtocol {
    private static let lock = NSLock()
    private static var count = 0
    static var requestCount: Int { lock.lock(); defer { lock.unlock() }; return count }
    static func reset() { lock.lock(); count = 0; lock.unlock() }
    override class func canInit(with request: URLRequest) -> Bool {
        ["http", "https"].contains(request.url?.scheme?.lowercased() ?? "")
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock(); Self.count += 1; Self.lock.unlock()
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }
    override func stopLoading() {}
}
#endif
