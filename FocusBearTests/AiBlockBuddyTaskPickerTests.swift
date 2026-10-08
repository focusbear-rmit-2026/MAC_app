//
//  AiBlockBuddyTaskPickerTests.swift
//  FocusBearTests
//
//  Covers `aiBlockBuddyResolveTypedTaskTitle` — what a name typed into the AI-block check-in's
//  current-task picker means: adopt the existing Day Plan task it matches, or create a new one.
//  Regression: typing a brand-new task name and pressing Return did nothing at all.
//

@testable import Focus_Bear
import XCTest

final class AiBlockBuddyTaskPickerTests: XCTestCase {

    private let existing = ["Payroll", "Call Aaron Hughes RE schools", "📑 Summarise Sources (3-4)"]

    func testTypedNameWithNoMatchBecomesANewTask() {
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("reschedule podcast", existingTitles: existing),
                       "reschedule podcast")
    }

    func testExactMatchAdoptsTheExistingTask() {
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("Payroll", existingTitles: existing), "Payroll")
    }

    func testMatchIgnoresCaseAndReturnsTheCanonicalTitle() {
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("payroll", existingTitles: existing), "Payroll")
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("PAYROLL", existingTitles: existing), "Payroll")
    }

    func testSurroundingWhitespaceIsIgnoredAndTrimmed() {
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("  Payroll  ", existingTitles: existing), "Payroll")
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("  new task  ", existingTitles: existing), "new task")
    }

    func testPartialMatchIsANewTaskNotTheLongerExistingOne() {
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("Call Aaron", existingTitles: existing), "Call Aaron")
    }

    func testBlankInputResolvesToNothing() {
        XCTAssertNil(aiBlockBuddyResolveTypedTaskTitle("", existingTitles: existing))
        XCTAssertNil(aiBlockBuddyResolveTypedTaskTitle("   \n ", existingTitles: existing))
    }

    func testEmptyDayPlanStillCreatesTheTypedTask() {
        XCTAssertEqual(aiBlockBuddyResolveTypedTaskTitle("reschedule podcast", existingTitles: []),
                       "reschedule podcast")
    }

    // MARK: - What to offer once the current task is ticked off

    private let top = ["Payroll", "Call Aaron Hughes RE schools", "📑 Summarise Sources (3-4)"]
    private let rest = ["Book flights", "Draft the board pack"]

    func testSuggestsTheTopTaskWhenNothingIsCompleted() {
        XCTAssertEqual(aiBlockBuddyNextTaskSuggestion(topTitles: top, otherTitles: rest, excluding: []), "Payroll")
    }

    func testTheJustCompletedTaskIsNeverOfferedBack() {
        XCTAssertEqual(aiBlockBuddyNextTaskSuggestion(topTitles: top, otherTitles: rest, excluding: ["Payroll"]),
                       "Call Aaron Hughes RE schools")
    }

    func testExclusionIgnoresCaseAndWhitespace() {
        XCTAssertEqual(aiBlockBuddyNextTaskSuggestion(topTitles: top, otherTitles: rest, excluding: ["  payroll "]),
                       "Call Aaron Hughes RE schools")
    }

    func testFallsBackToTheRestOfTheDayPlanOnceTheTopTasksAreDone() {
        XCTAssertEqual(aiBlockBuddyNextTaskSuggestion(topTitles: top, otherTitles: rest, excluding: top),
                       "Book flights")
    }

    func testKeepsTheBuddysOwnRankingRatherThanReSorting() {
        // "Payroll" first because that's the order the top-task cards use — not alphabetical.
        XCTAssertEqual(aiBlockBuddyNextTaskSuggestion(topTitles: ["Payroll", "Book flights"], otherTitles: [], excluding: []),
                       "Payroll")
    }

    func testADuplicatedTitleAcrossTopAndRestIsOfferedOnlyOnce() {
        XCTAssertEqual(aiBlockBuddyNextTaskSuggestion(topTitles: ["Payroll"], otherTitles: ["payroll", "Book flights"],
                                                      excluding: ["Payroll"]),
                       "Book flights")
    }

    func testNothingLeftToSuggest() {
        XCTAssertNil(aiBlockBuddyNextTaskSuggestion(topTitles: top, otherTitles: rest, excluding: top + rest))
        XCTAssertNil(aiBlockBuddyNextTaskSuggestion(topTitles: [], otherTitles: [], excluding: []))
    }

    func testBlankTitlesAreSkipped() {
        XCTAssertEqual(aiBlockBuddyNextTaskSuggestion(topTitles: ["   ", ""], otherTitles: ["Book flights"], excluding: []),
                       "Book flights")
    }

    // MARK: - Setting a task must never edit the session goal (strictness bypass)

    func testSettingTheCurrentTaskLeavesTheSessionGoalAlone() {
        let goal = "Ship the Mac release"
        whatToAchieveInFocusBlock = goal
        aiBlockBuddySetCurrentFocusTask(title: "Payroll", id: "task-1", durationSeconds: 600)
        XCTAssertEqual(whatToAchieveInFocusBlock, goal)
    }

    func testSettingTheCurrentTaskLeavesASuperStrictSessionsGoalAlone() {
        let previousStrictness = currentFocusModeStrictness
        defer { currentFocusModeStrictness = previousStrictness }
        currentFocusModeStrictness = ._SUPER_STRICT_
        let goal = "Write the board pack"
        whatToAchieveInFocusBlock = goal
        aiBlockBuddySetCurrentFocusTask(title: "Payroll", id: "task-1", durationSeconds: 600)
        XCTAssertEqual(whatToAchieveInFocusBlock, goal,
                       "A super-strict session forbids changing the goal — the buddy must not edit it")
    }

    func testAnEmptyTaskTitleIsIgnoredAndStillLeavesTheGoalAlone() {
        let goal = "Ship the Mac release"
        whatToAchieveInFocusBlock = goal
        aiBlockBuddySetCurrentFocusTask(title: "   ", id: "task-1", durationSeconds: 600)
        XCTAssertEqual(whatToAchieveInFocusBlock, goal)
    }

    // MARK: - What the CURRENT TASK chip shows

    func testChipShowsTheActiveTaskWhenThereIsOne() {
        XCTAssertEqual(aiBlockBuddyCurrentTaskLabel(activeTaskTitle: "Payroll", focusIntention: "Ship the Mac release"),
                       "Payroll")
    }

    func testChipFallsBackToTheIntentionWithoutAnActiveTask() {
        XCTAssertEqual(aiBlockBuddyCurrentTaskLabel(activeTaskTitle: nil, focusIntention: "Ship the Mac release"),
                       "Ship the Mac release")
        XCTAssertEqual(aiBlockBuddyCurrentTaskLabel(activeTaskTitle: "   ", focusIntention: "Ship the Mac release"),
                       "Ship the Mac release")
    }

    func testChipIsEmptyWhenThereIsNeitherTaskNorIntention() {
        XCTAssertEqual(aiBlockBuddyCurrentTaskLabel(activeTaskTitle: nil, focusIntention: "  "), "")
    }

    // MARK: - Confirming a task change before the check-in closes (report 2026-09-17_13-54-19)

    func testAChangedTaskIsConfirmedLongEnoughToReadAndShortEnoughNotToWaitFor() {
        // The PO asked for the confirmation to hold the screen for half a second. Anything much
        // shorter is the abrupt dismissal they reported; anything longer stalls getting back to work.
        XCTAssertEqual(AiBlockBuddyTaskChange.confirmationSeconds, 0.5, accuracy: 0.0001)
    }

    func testTheConfirmationNamesTheTaskTheUserSwitchedTo() {
        XCTAssertEqual(AiBlockBuddyTaskChange.message(template: "Task changed to {0}",
                                                      placeholder: "{0}",
                                                      title: "Payroll"),
                       "Task changed to Payroll")
    }

    func testTheConfirmationSurvivesATemplateWithoutAPlaceholder() {
        // A translation that drops "{0}" must not lose the sentence as well.
        XCTAssertEqual(AiBlockBuddyTaskChange.message(template: "Task changed",
                                                      placeholder: "{0}",
                                                      title: "Payroll"),
                       "Task changed")
    }

    func testOnlyANonBlankNameIsConfirmedAndCommitted() {
        XCTAssertEqual(AiBlockBuddyTaskChange.committedTitle("  Payroll  "), "Payroll",
                       "The committed title is the trimmed one, so the confirmation reads cleanly")
        XCTAssertNil(AiBlockBuddyTaskChange.committedTitle("   "),
                     "A blank name must not confirm a change or dismiss the check-in")
        XCTAssertNil(AiBlockBuddyTaskChange.committedTitle(""))
    }
}

// MARK: - Which of the two things the check-in blames

/// The product owner, in a super-strict session: "If the user is in a super strict focus mode and the
/// task they set doesn't align with the focus intention, the message here isn't clear" — the check-in
/// said Docker Desktop didn't align with the current task, when the current task was itself off-goal and
/// so *everything* was being blocked (report 2026-09-17_13-52-25).
///
/// It applies only where the session demanded that activity align with the intention — the predicate
/// `isTaskRequiredToAlignToFocusIntention()`, which is what makes the relevance request send
/// `task_must_align_to_focus_intention` (PO, 2026-09-17: "This only applies when the focus session is in
/// the strictest mode. It's not at all times"). That gate is covered here alongside everything else.
///
/// The decision is a pure function over the strictness and the server's answer, so every branch —
/// aligned, conflicting, conflicting-with-no-words, offline, nothing-to-ask, not-strict-enough — is
/// covered here without a server.
final class AiBlockBuddySubtitleTests: XCTestCase {
    func testSafetyResponseBooleanControlsTaskMisalignmentWithoutAnotherRequest() {
        XCTAssertEqual(AiBlockBuddyTaskIntention.subtitle(misaligned: true, mustAlign: true, reason: " Task conflicts "),
                       .currentTaskOffIntention(reason: "Task conflicts"))
        for flag: Bool? in [nil, false] {
            XCTAssertEqual(AiBlockBuddyTaskIntention.subtitle(misaligned: flag, mustAlign: true, reason: "anything"), .itemOffTask)
        }
        XCTAssertEqual(AiBlockBuddyTaskIntention.subtitle(misaligned: true, mustAlign: false, reason: "anything"), .itemOffTask)
    }

    private let intention = "Ship the Mac release"
    private let task = "Water the office plants"

    override func setUp() {
        super.setUp()
        aiBlockBuddyTaskIntentionCache.removeAll()
    }

    override func tearDown() {
        aiBlockBuddyTaskIntentionCache.removeAll()
        super.tearDown()
    }

    // MARK: Which sessions demand alignment at all

    /// The gate must stay the SAME predicate the relevance request uses for
    /// `task_must_align_to_focus_intention` — otherwise the check-in blames the task in sessions the
    /// server was never asked to judge that way.
    func testOnlyTheStrictestFocusModeDemandsAlignment() {
        let strictness = currentFocusModeStrictness
        let buddy = currentAccountabilityBuddySession
        defer {
            currentFocusModeStrictness = strictness
            currentAccountabilityBuddySession = buddy
        }
        currentAccountabilityBuddySession = nil

        currentFocusModeStrictness = ._NORMAL_
        XCTAssertFalse(isTaskRequiredToAlignToFocusIntention())
        currentFocusModeStrictness = ._STRICT_
        XCTAssertFalse(isTaskRequiredToAlignToFocusIntention(),
                       "Strict is not the strictest: the PO asked for the strictest mode only")
        currentFocusModeStrictness = ._SUPER_STRICT_
        XCTAssertTrue(isTaskRequiredToAlignToFocusIntention())
    }

    func testAnAccountabilityBuddySessionDemandsAlignmentAtAnyStrictness() {
        let strictness = currentFocusModeStrictness
        let buddy = currentAccountabilityBuddySession
        defer {
            currentFocusModeStrictness = strictness
            currentAccountabilityBuddySession = buddy
        }
        currentFocusModeStrictness = ._NORMAL_
        currentAccountabilityBuddySession = AccountabilityBuddySession(
            goal: intention, allowedApps: [], allowedUrls: [], durationMinutes: 30)
        XCTAssertTrue(isTaskRequiredToAlignToFocusIntention(),
                      "A buddy session judges everything against the goal, so it mis-blames the app the same way")
    }

    // MARK: Is the question worth asking

    func testAPairWorthCheckingIsCheckedWhenTheSessionDemandedAlignment() {
        XCTAssertTrue(AiBlockBuddyTaskIntention.shouldCheck(intention: intention,
                                                           taskName: task,
                                                           mustAlignToFocusIntention: true))
    }

    func testTheSamePairIsNotWorthCheckingWhenTheSessionDidNotDemandAlignment() {
        XCTAssertFalse(AiBlockBuddyTaskIntention.shouldCheck(intention: intention,
                                                            taskName: task,
                                                            mustAlignToFocusIntention: false),
                       "A session the server was never asked to judge strictly keeps the wording it has always had, and pays for no check")
    }

    func testASessionWithNoGoalIsNotWorthChecking() {
        XCTAssertFalse(AiBlockBuddyTaskIntention.shouldCheck(intention: "  ",
                                                             taskName: task,
                                                             mustAlignToFocusIntention: true),
                       "Nothing to judge the task against")
    }

    func testASessionWithNoTaskIsNotWorthChecking() {
        XCTAssertFalse(AiBlockBuddyTaskIntention.shouldCheck(intention: intention,
                                                             taskName: "",
                                                             mustAlignToFocusIntention: true),
                       "The chip is echoing the goal; there is no second thing to compare")
    }

    func testATaskThatIsJustTheGoalIsNotWorthChecking() {
        XCTAssertFalse(AiBlockBuddyTaskIntention.shouldCheck(intention: intention,
                                                             taskName: intention,
                                                             mustAlignToFocusIntention: true))
        XCTAssertFalse(AiBlockBuddyTaskIntention.shouldCheck(intention: intention,
                                                            taskName: "  ship the mac release ",
                                                            mustAlignToFocusIntention: true),
                       "Same string, differently cased and padded — it cannot disagree with itself")
    }

    // MARK: Turning the answer into copy

    func testAnAlignedTaskLeavesTheOrdinaryWordingAlone() {
        XCTAssertEqual(
            AiBlockBuddyTaskIntention.subtitle(for: .success(TaskIntentionAlignment(aligns: true, reason: "Fits"))),
            .itemOffTask)
    }

    func testAConflictingTaskIsNamedWithTheServersOwnSentence() {
        let sentence = #"You said you'd "Ship the Mac release", but you're on "Water the office plants"."#
        XCTAssertEqual(
            AiBlockBuddyTaskIntention.subtitle(for: .success(TaskIntentionAlignment(aligns: false, reason: sentence))),
            .currentTaskOffIntention(reason: sentence))
    }

    func testAConflictWithNoSentenceLeavesTheScreenToWordItItself() {
        XCTAssertEqual(
            AiBlockBuddyTaskIntention.subtitle(for: .success(TaskIntentionAlignment(aligns: false, reason: "  "))),
            .currentTaskOffIntention(reason: ""))
    }

    func testAnUnreachableServerFailsOpen() {
        XCTAssertEqual(
            AiBlockBuddyTaskIntention.subtitle(for: .failure(URLError(.notConnectedToInternet))),
            .itemOffTask,
            "Never tell someone their task is wrong on the strength of a request that never happened")
    }

    func testAnUnparseableAnswerFailsOpen() {
        XCTAssertEqual(
            AiBlockBuddyTaskIntention.subtitle(for: .failure(TaskIntentionCheckError.badResponse(statusCode: 500))),
            .itemOffTask)
    }

    // MARK: The whole check, with the network injected

    private func awaitSubtitle(intention: String,
                               taskName: String,
                               mustAlignToFocusIntention: Bool = true,
                               checker: TaskIntentionChecking,
                               timeout: TimeInterval = 2) -> AiBlockBuddySubtitle? {
        let answered = expectation(description: "subtitle")
        var subtitle: AiBlockBuddySubtitle?
        AiBlockBuddyTaskIntention.check(intention: intention,
                                        taskName: taskName,
                                        focusMode: "Deep work",
                                        mustAlignToFocusIntention: mustAlignToFocusIntention,
                                        checker: checker,
                                        timeout: timeout) {
            subtitle = $0
            answered.fulfill()
        }
        waitForExpectations(timeout: 5)
        return subtitle
    }

    func testAConflictReachesTheScreen() {
        let sentence = "That task isn't part of this session."
        let checker = StubBuddyIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: sentence)))
        XCTAssertEqual(awaitSubtitle(intention: intention, taskName: task, checker: checker),
                       .currentTaskOffIntention(reason: sentence))
        XCTAssertEqual(checker.receivedIntention, intention)
        XCTAssertEqual(checker.receivedTaskName, task)
    }

    func testAConflictNeverReachesTheScreenWhenTheSessionDidNotDemandAlignment() {
        let checker = StubBuddyIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "That task isn't part of this session.")))
        XCTAssertEqual(awaitSubtitle(intention: intention, taskName: task,
                                     mustAlignToFocusIntention: false, checker: checker),
                       .itemOffTask,
                       "Only a session that demanded alignment re-blames the task; everywhere else the old copy stands")
        XCTAssertFalse(checker.wasAsked, "And it costs no round trip")
    }

    func testASkippedCheckCachesNothingForASessionThatDoesAsk() {
        let checker = StubBuddyIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "Off-goal")))
        _ = awaitSubtitle(intention: intention, taskName: task,
                          mustAlignToFocusIntention: false, checker: checker)
        XCTAssertEqual(awaitSubtitle(intention: intention, taskName: task,
                                     mustAlignToFocusIntention: true, checker: checker),
                       .currentTaskOffIntention(reason: "Off-goal"),
                       "The skipped check must not poison the cache for a session that does ask")
    }

    func testNothingToAskIsAnsweredWithoutTouchingTheNetwork() {
        let checker = StubBuddyIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "Never asked")))
        XCTAssertEqual(awaitSubtitle(intention: "  ", taskName: task, checker: checker), .itemOffTask)
        XCTAssertFalse(checker.wasAsked)
    }

    func testAServerThatNeverAnswersSettlesForTheOrdinaryWording() {
        XCTAssertEqual(awaitSubtitle(intention: intention, taskName: task,
                                     checker: SilentBuddyIntentionChecker(), timeout: 0.2),
                       .itemOffTask,
                       "The check-in is already on screen; a stalled request must never change it later")
    }

    // MARK: One question per pair

    func testTheSameQuestionIsOnlyAskedOnce() {
        let checker = StubBuddyIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "Off-goal")))
        _ = awaitSubtitle(intention: intention, taskName: task, checker: checker)
        _ = awaitSubtitle(intention: "  \(intention) ", taskName: task.uppercased(), checker: checker)
        XCTAssertEqual(checker.askCount, 1,
                       "The check-in is re-presented per blocked app; the answer depends only on the pair")
    }

    func testADifferentTaskIsANewQuestion() {
        let checker = StubBuddyIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: true, reason: "")))
        _ = awaitSubtitle(intention: intention, taskName: task, checker: checker)
        _ = awaitSubtitle(intention: intention, taskName: "Fix the release script", checker: checker)
        XCTAssertEqual(checker.askCount, 2)
    }

    func testAFailedCheckIsNotRemembered() {
        let offline = StubBuddyIntentionChecker(outcome: .failure(URLError(.notConnectedToInternet)))
        XCTAssertEqual(awaitSubtitle(intention: intention, taskName: task, checker: offline), .itemOffTask)
        let online = StubBuddyIntentionChecker(
            outcome: .success(TaskIntentionAlignment(aligns: false, reason: "Off-goal")))
        XCTAssertEqual(awaitSubtitle(intention: intention, taskName: task, checker: online),
                       .currentTaskOffIntention(reason: "Off-goal"),
                       "One dropped request must not silence the explanation for the rest of the session")
    }
}

/// An alignment check with a canned answer, so the decision can be tested without a server.
private final class StubBuddyIntentionChecker: TaskIntentionChecking {
    private let outcome: Result<TaskIntentionAlignment, Error>
    private(set) var askCount = 0
    private(set) var receivedIntention = ""
    private(set) var receivedTaskName = ""
    var wasAsked: Bool { askCount > 0 }

    init(outcome: Result<TaskIntentionAlignment, Error>) {
        self.outcome = outcome
    }

    func checkTaskIntentionAlignment(intention: String,
                                     taskName: String,
                                     focusMode: String?,
                                     completion: @escaping (Result<TaskIntentionAlignment, Error>) -> Void) {
        askCount += 1
        receivedIntention = intention
        receivedTaskName = taskName
        DispatchQueue.main.async { completion(self.outcome) }
    }
}

/// A check that never answers — the stalled-request path.
private final class SilentBuddyIntentionChecker: TaskIntentionChecking {
    func checkTaskIntentionAlignment(intention: String,
                                     taskName: String,
                                     focusMode: String?,
                                     completion: @escaping (Result<TaskIntentionAlignment, Error>) -> Void) {}
}
