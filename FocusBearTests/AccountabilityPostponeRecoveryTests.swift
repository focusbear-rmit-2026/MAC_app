import XCTest
@testable import Focus_Bear

final class AccountabilityPostponeRecoveryTests: XCTestCase {
    func testStaleBuddyApprovalClosesAndCancelsWithoutPostponing() {
        let savedState = currentState
        defer { currentState = savedState }
        currentState = ._MORNING_HABIT_
        var approvals = 0, cancellations = 0, dismissals = 0
        let controller = AccountabilityBuddyChatViewController(initialGoal: "", purpose: .extendSession(minutes: 15),
            onApproved: { _, _ in approvals += 1 }, onCancel: { cancellations += 1 },
            dismissSheet: { dismissed in
                dismissals += 1
                dismissed.viewDidDisappear()
            })
        currentState = ._MICRO_BREAK_
        let verdict = AccountabilityVerdict(approved: true, message: "Approved", intention: nil,
            allowedApps: [], allowedUrls: [], durationMinutes: 15)
        controller.startApprovedSession(verdict: verdict, goal: "Build safety system")
        XCTAssertEqual(approvals, 0)
        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(dismissals, 1)
        controller.cancelChat() // Close remains usable after the failed Start.
        XCTAssertEqual(dismissals, 2)
        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(currentState, ._MICRO_BREAK_)
    }

    func testStaleBackendErrorPostponeAlsoDismissesWithoutApproval() {
        let savedState = currentState
        defer { currentState = savedState }
        currentState = ._EVENING_HABIT_
        var approvals = 0, cancellations = 0, dismissals = 0
        let controller = AccountabilityBuddyChatViewController(initialGoal: "", purpose: .postponeRoutine,
            onApproved: { _, _ in approvals += 1 }, onCancel: { cancellations += 1 },
            dismissSheet: { _ in dismissals += 1 })
        currentState = ._NOTHING_
        controller.postponeAfterBackendError(minutes: 15)
        XCTAssertEqual(approvals, 0)
        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(dismissals, 1)
    }

    func testBuddyApprovalAndSubsequentCloseResolveCallbacksOnlyOnce() {
        let savedState = currentState
        defer { currentState = savedState }
        currentState = ._POSTPONE_MORNING_HABIT_
        var grants: [Int] = [], cancellations = 0, dismissals = 0
        let controller = AccountabilityBuddyChatViewController(initialGoal: "", purpose: .extendSession(minutes: 15),
            onApproved: { _, minutes in grants.append(minutes) }, onCancel: { cancellations += 1 },
            dismissSheet: { dismissed in
                dismissals += 1
                dismissed.viewDidDisappear()
            })
        let verdict = AccountabilityVerdict(approved: true, message: "Approved", intention: nil,
            allowedApps: [], allowedUrls: [], durationMinutes: 25)
        controller.startApprovedSession(verdict: verdict, goal: "Finish task")
        controller.startApprovedSession(verdict: verdict, goal: "Finish task")
        controller.cancelChat()
        XCTAssertEqual(grants, [15])
        XCTAssertEqual(cancellations, 0)
        XCTAssertEqual(dismissals, 2)
    }

    func testBuddySelectsOnlyOfferedStillUnfinishedTasksAndUsesTheirCurrentData() {
        let noat = DayPlanTask(id: "local-noat", title: "NOAT form", durationMinutes: 15,
                              sourceTaskId: "remote-noat", project: "Marketing")
        let done = DayPlanTask(id: "done", title: "Finished", done: true)
        let unoffered = DayPlanTask(id: "new", title: "Added after chat opened")
        let offered = AccountabilityTaskSelection.candidates(from: [noat, DayPlanTask(id: "done", title: "Finished")])
        let queue = AccountabilityTaskSelection.queue(selectedIDs: ["invented", "done", "local-noat", "local-noat", "new"],
                                                       offered: offered, currentTasks: [noat, done, unoffered])
        XCTAssertEqual(queue.map(\.id), ["remote-noat"])
        XCTAssertEqual(queue.first?.title, "NOAT form")
        XCTAssertEqual(queue.first?.durationSeconds, 900)
        XCTAssertEqual(queue.first?.projectName, "Marketing")
        XCTAssertEqual(queue.first?.isActive, true)
        XCTAssertTrue(AccountabilityTaskSelection.queue(selectedIDs: ["local-noat"], offered: offered, currentTasks: []).isEmpty)
    }

    func testBuddyCandidateKeepsItsLocalIdentityWhenATodoIsMintedDuringChat() {
        var task = DayPlanTask(id: "draft", title: "NOAT form")
        let offered = AccountabilityTaskSelection.candidates(from: [task])
        task.sourceTaskId = "new-backend-id"
        let queue = AccountabilityTaskSelection.queue(selectedIDs: ["draft"], offered: offered, currentTasks: [task])
        XCTAssertEqual(queue.first?.id, "new-backend-id")
    }

    func testBuddyQueueUsesModelOrderAndActivatesOnlyTheFirstMatch() {
        let tasks = [DayPlanTask(id: "a", title: "A"), DayPlanTask(id: "b", title: "B")]
        let queue = AccountabilityTaskSelection.queue(selectedIDs: ["b", "a"],
            offered: AccountabilityTaskSelection.candidates(from: tasks), currentTasks: tasks)
        XCTAssertEqual(queue.map(\.id), ["b", "a"])
        XCTAssertEqual(queue.map(\.isActive), [true, false])
        XCTAssertTrue(AccountabilityTaskSelection.queue(selectedIDs: [], offered: [], currentTasks: tasks).isEmpty)
    }

    func testBuddyTaskCandidatesRespectRequestBoundsAndExcludeFinishedWork() {
        let tasks = (0..<110).map { DayPlanTask(id: "task-\($0)", title: String(repeating: "N", count: 300)) }
        let offered = AccountabilityTaskSelection.candidates(from: [DayPlanTask(title: "Done", done: true), DayPlanTask(title: " ")] + tasks)
        XCTAssertEqual(offered.count, 100)
        XCTAssertEqual(offered.first?.apiValue["title"]?.count, 200)
    }

    func testOlderBuddyVerdictStillDecodesWithoutTaskSelection() throws {
        let data = Data(#"{"approved":true,"message":"Go","allowed_apps":[],"allowed_urls":[],"allowed_duration_minutes":25}"#.utf8)
        let verdict = try JSONDecoder().decode(AccountabilityVerdict.self, from: data)
        XCTAssertNil(verdict.selectedTaskIds)
        let task = DayPlanTask(id: "prior", title: "Previous session task")
        let queue = AccountabilityTaskSelection.queue(selectedIDs: verdict.selectedTaskIds,
            offered: AccountabilityTaskSelection.candidates(from: [task]), currentTasks: [task])
        XCTAssertEqual(FocusSessionTaskQueue.encode(queue), "[]", "Old-server approval explicitly clears the previous queue")
    }

    private func ready(minutes: Int = 25) -> AccountabilityPostponeRecovery {
        var recovery = AccountabilityPostponeRecovery()
        recovery.setAvailable(true)
        recovery.select(minutes: minutes)
        return recovery
    }

    private func hold(_ recovery: inout AccountabilityPostponeRecovery, from start: Double,
                      seconds: Int) -> Int? {
        recovery.beginHold(at: start)
        var result: Int?
        for halfSecond in 1...(seconds * 2) {
            result = recovery.tick(at: start + Double(halfSecond) / 2)
        }
        return result
    }

    func testTenContinuousSecondsConfirmsSelectedDurationExactlyOnce() {
        var recovery = ready(minutes: 45)
        XCTAssertNil(hold(&recovery, from: 100, seconds: 9))
        XCTAssertNil(recovery.tick(at: 109.5))
        XCTAssertEqual(recovery.tick(at: 110), 45)
        XCTAssertNil(recovery.tick(at: 110.5))
        recovery.resetHold()
        XCTAssertNil(hold(&recovery, from: 120, seconds: 10))
    }

    func testErrorAndDurationAloneNeverConfirm() {
        var recovery = ready()
        XCTAssertNil(recovery.tick(at: 1000))
        XCTAssertEqual(recovery.progress, 0)
    }

    func testHoldNeedsBothErrorAvailabilityAndExplicitValidDuration() {
        var recovery = AccountabilityPostponeRecovery()
        recovery.select(minutes: 25)
        XCTAssertNil(hold(&recovery, from: 100, seconds: 10))
        recovery.setAvailable(true)
        for value in [nil, 0, -5, 181, 999] as [Int?] {
            recovery.select(minutes: value)
            XCTAssertNil(hold(&recovery, from: 200, seconds: 10))
        }
    }

    func testReleaseLosesAllProgressAndRequiresNewFullHold() {
        var recovery = ready()
        XCTAssertNil(hold(&recovery, from: 100, seconds: 9))
        recovery.resetHold()
        XCTAssertEqual(recovery.progress, 0)
        XCTAssertNil(recovery.tick(at: 110))
        XCTAssertNil(hold(&recovery, from: 111, seconds: 9))
        XCTAssertNil(recovery.tick(at: 120.5))
        XCTAssertEqual(recovery.tick(at: 121), 25)
    }

    func testChangingDurationRequiresNewFullHold() {
        var recovery = ready()
        XCTAssertNil(hold(&recovery, from: 100, seconds: 9))
        recovery.select(minutes: 60)
        XCTAssertNil(recovery.tick(at: 110))
        XCTAssertEqual(hold(&recovery, from: 111, seconds: 10), 60)
    }

    func testRetryOrDismissalCancelsPendingConfirmation() {
        var recovery = ready()
        XCTAssertNil(hold(&recovery, from: 100, seconds: 9))
        recovery.setAvailable(false)
        XCTAssertNil(recovery.tick(at: 110))
        XCTAssertNil(hold(&recovery, from: 111, seconds: 10))
    }

    func testClockRollbackAndSuspendedTimerCannotCompleteHold() {
        for invalidTick in [99.0, 1000, Double.nan, Double.infinity] {
            var recovery = ready()
            XCTAssertNil(hold(&recovery, from: 100, seconds: 9))
            XCTAssertNil(recovery.tick(at: invalidTick))
            XCTAssertEqual(recovery.progress, 0)
            XCTAssertNil(recovery.tick(at: 110))
        }
    }

    func testRepeatedKeyDownDoesNotResetOrAccelerateHold() {
        var recovery = ready()
        recovery.beginHold(at: 100)
        for tick in 1...19 {
            let time = 100 + Double(tick) / 2
            recovery.beginHold(at: time)
            XCTAssertNil(recovery.tick(at: time))
        }
        XCTAssertEqual(recovery.tick(at: 110), 25)
    }

    func testLongDayPlanContextIsBoundedWithoutEditingStoredTask() {
        let title = String(repeating: "Long task title ", count: 40)
        let lines = [title + " [#project] (~25 min)", "Short task (~5 min)"]
        let payload = AccountabilityRequestText.context(lines)
        XCTAssertEqual(payload[0].utf16.count, 200)
        XCTAssertEqual(payload[1], lines[1])
        XCTAssertGreaterThan(lines[0].count, 200)
        XCTAssertEqual(payload.count, lines.count)
    }

    func testEmojiAndCombiningMarksCannotExceedServerLimitOrSplitCharacters() {
        for cluster in ["👩🏽‍💻", "e\u{301}", "🏳️‍🌈"] {
            let source = String(repeating: cluster, count: 200)
            let result = AccountabilityRequestText.bounded(source)
            XCTAssertLessThanOrEqual(result.utf16.count, 200)
            XCTAssertEqual(result, String(source.prefix(result.count)))
            XCTAssertEqual(Set(result), Set(cluster))
        }
    }

    func testMessageAndContextHaveDifferentBackendLimits() {
        let source = String(repeating: "a", count: 800)
        XCTAssertEqual(AccountabilityRequestText.bounded(source, limit: 500).count, 500)
        XCTAssertEqual(AccountabilityRequestText.context([source]).first?.count, 200)
        XCTAssertEqual(AccountabilityRequestText.bounded("", limit: 200), "")
        XCTAssertEqual(AccountabilityRequestText.bounded(source, limit: 0), "")
    }

    // MARK: When the buddy stops making progress (report 2026-09-22_16-07-17)
    //
    // The user answered everything asked — task, duration, urgency, habit status — and the buddy
    // kept demanding the same things, finally repeating one sentence word for word while they
    // replied "I already answered that", "get lost", "I already told you".

    private typealias Guard = AccountabilityLoopGuard

    /// The buddy's side of the reported conversation, in order.
    private static let reportedBuddyTurns = [
        "What specifically needs to be done now, how many minutes will it take, and why is it urgent right now? Also, why can't you do your habits first or at least a short essential habit before starting?",
        "What exactly do you need to finish for DMG in the next 30 minutes? Please name the specific task.",
        "Why is this urgent right now, and why can't you do your remaining habits first or at least a short essential habit before starting? How many minutes do you need for this task?",
        "What is the concrete deadline or consequence if this waits, and why can't you do your remaining habits first or a short essential habit before starting?",
    ]

    func testTheReportedConversationIsRecognisedAsStuck() {
        XCTAssertTrue(Guard.isStuck(buddyMessages: Self.reportedBuddyTurns))
    }

    func testAVerbatimRepeatIsStuckImmediately() {
        let demand = "I still need one concrete answer: what exactly must be done now, how many minutes it will take, and why it cannot wait."
        XCTAssertTrue(Guard.isStuck(buddyMessages: [demand, demand]),
                      "saying the same sentence twice is the clearest possible signal")
    }

    /// The same demand with different punctuation is the same demand.
    func testRepetitionIsNotFooledByPunctuationOrCase() {
        XCTAssertTrue(Guard.isStuck(buddyMessages: [
            "I still need one concrete answer: what exactly must be done now?",
            "I still need ONE concrete answer — what exactly must be done now!",
        ]))
    }

    func testANormalExchangeIsNotStuck() {
        XCTAssertFalse(Guard.isStuck(buddyMessages: []))
        XCTAssertFalse(Guard.isStuck(buddyMessages: [Self.reportedBuddyTurns[0]]))
        XCTAssertFalse(Guard.isStuck(buddyMessages: Array(Self.reportedBuddyTurns.prefix(2))),
                       "two questions is a conversation, not a loop")
    }

    func testDifferentQuestionsAreAllowedUpToTheTurnLimit() {
        let distinct = (1...Guard.maxBuddyTurns - 1).map { "A completely different question number \($0)" }
        XCTAssertFalse(Guard.isStuck(buddyMessages: distinct))
        XCTAssertTrue(Guard.isStuck(buddyMessages: distinct + ["And one more distinct question"]),
                      "even without repetition, the asking has to stop somewhere")
    }

    func testEmptyMessagesAreIgnoredRatherThanCountedAsRepeats() {
        XCTAssertFalse(Guard.isStuck(buddyMessages: ["", "   ", ""]),
                       "blank turns must not trip the escape on their own")
    }

}
