import XCTest
@testable import Focus_Bear

final class AccountabilityPostponeRecoveryTests: XCTestCase {
    @MainActor
    func testQueuedCredentialMustMatchCapturedAccountAndCurrentGeneration() {
        let identity = FocusLifecycleIdentity()
        identity.updateAccountID("account A")
        let snapshot = identity.capture()
        let queue = FocusLifecycleRequestQueue(scheduleDeadline: { _, _ in {} }, deliver: { $0() })
        var request: FocusLifecycleRequestQueue.Lease?
        queue.enqueue(isValid: { snapshot.isCurrent }, expectedAccountID: snapshot.accountID,
                      start: { request = $0 }, completion: { _ in })
        XCTAssertTrue(request?.permitsCredentialAccount("account A") ?? false)
        XCTAssertFalse(request?.permitsCredentialAccount("account B") ?? true)
        XCTAssertFalse(request?.permitsCredentialAccount(nil) ?? true)
        XCTAssertFalse(request?.permitsCredentialAccount("") ?? true)
        identity.updateAccountID("account B")
        XCTAssertFalse(request?.permitsCredentialAccount("account A") ?? true)
        XCTAssertFalse(request?.isActive ?? true)
    }

    func testIdentityGenerationRejectsLogoutAndReturnToSameAccount() {
        let identity = FocusLifecycleIdentity()
        XCTAssertFalse(identity.capture().isCurrent)
        identity.updateAccountID("account A")
        let original = identity.capture()
        identity.updateAccountID("account A")
        XCTAssertTrue(original.isCurrent, "A same-account credential refresh does not invalidate work")
        identity.updateAccountID(nil)
        XCTAssertFalse(original.isCurrent)
        identity.updateAccountID("account A")
        XCTAssertFalse(original.isCurrent, "Logging back in must not revive old callbacks")
        let second = identity.capture()
        identity.updateAccountID("account B")
        XCTAssertFalse(second.isCurrent)
    }

    @MainActor
    func testAccountChangeCancelsActiveLeaseAndDropsQueuedOldAccountRequests() {
        let identity = FocusLifecycleIdentity()
        identity.updateAccountID("account A")
        let original = identity.capture()
        let queue = FocusLifecycleRequestQueue(scheduleDeadline: { _, _ in {} }, deliver: { $0() })
        var active: FocusLifecycleRequestQueue.Lease?
        var transmitted = 0
        var cancelled = 0
        var completed = 0
        queue.enqueue(isValid: { original.isCurrent }, start: { lease in
            active = lease
            lease.attachCancellation { cancelled += 1 }
        }, completion: { result in XCTAssertNil(result); completed += 1 })
        queue.enqueue(isValid: { original.isCurrent }, start: { _ in transmitted += 1 },
                      completion: { result in XCTAssertNil(result); completed += 1 })
        identity.updateAccountID("account B")
        XCTAssertFalse(active?.isActive ?? true)
        XCTAssertEqual(cancelled, 1)
        XCTAssertEqual(completed, 2)
        XCTAssertEqual(transmitted, 0)
        let current = identity.capture()
        queue.enqueue(isValid: { current.isCurrent }, start: { lease in transmitted += 1; lease.finish([:]) },
                      completion: { XCTAssertNotNil($0) })
        XCTAssertEqual(transmitted, 1)
    }

    @MainActor
    func testMeetingExtensionWaitsForRegistrationAndDropsAfterUnconfirmedStart() {
        let segment = MeetingFocusTransport.Segment()
        segment.predecessor.settle(succeeded: true)
        let queue = FocusLifecycleRequestQueue(scheduleDeadline: { _, _ in {} }, deliver: { $0() })
        var startLease: FocusLifecycleRequestQueue.Lease?
        var extensionsSent = 0
        queue.enqueue(start: { startLease = $0 }, completion: { segment.startSettled(succeeded: $0 != nil) })
        queue.enqueue(start: { lease in
            if segment.canSendMutation { extensionsSent += 1; lease.finish([:]) }
            else { lease.finish(nil) }
        }, completion: { segment.mutationSettled(succeeded: $0 != nil) })
        XCTAssertEqual(extensionsSent, 0)
        startLease?.finish(nil)
        XCTAssertEqual(extensionsSent, 0)
        XCTAssertTrue(segment.isReportingPending)
    }

    @MainActor
    func testUnconfirmedFinishDropsDependentStartAndStopDespiteLateSuccess() {
        var deadlines: [() -> Void] = []
        let queue = FocusLifecycleRequestQueue(scheduleDeadline: { _, callback in
            deadlines.append(callback)
            return {}
        }, deliver: { $0() })
        let segment = MeetingFocusTransport.Segment()
        var finishLease: FocusLifecycleRequestQueue.Lease?
        var transmittedStarts = 0
        var transmittedStops = 0
        queue.enqueue(start: { finishLease = $0 }, completion: {
            segment.predecessor.settle(succeeded: $0 != nil)
        })
        queue.enqueue(start: { lease in
            if segment.canSendStart { transmittedStarts += 1; lease.finish([:]) }
            else { lease.finish(nil) }
        }, completion: { segment.startSettled(succeeded: $0 != nil) })
        queue.enqueue(start: { lease in
            if segment.canSendMutation { transmittedStops += 1; lease.finish([:]) }
            else { lease.finish(nil) }
        }, completion: { segment.mutationSettled(succeeded: $0 != nil, isFinish: true) })
        deadlines[0]()
        XCTAssertEqual(transmittedStarts, 0)
        XCTAssertEqual(transmittedStops, 0)
        XCTAssertTrue(segment.isReportingPending)
        finishLease?.finish([:])
        XCTAssertEqual(segment.predecessor.succeeded, false)
        XCTAssertFalse(segment.canSendStart)
        XCTAssertFalse(segment.canSendMutation)
    }

    func testConfirmedFinishAndStartPermitMutationsUntilFinish() {
        let segment = MeetingFocusTransport.Segment()
        XCTAssertFalse(segment.canSendStart)
        segment.predecessor.settle(succeeded: true)
        XCTAssertTrue(segment.canSendStart)
        XCTAssertFalse(segment.canSendMutation)
        segment.startSettled(succeeded: true)
        XCTAssertTrue(segment.canSendMutation)
        segment.mutationSettled(succeeded: true)
        XCTAssertTrue(segment.canSendMutation)
        segment.mutationSettled(succeeded: true, isFinish: true)
        XCTAssertFalse(segment.canSendMutation)
        XCTAssertFalse(segment.isReportingPending)
    }

    func testAmbiguousStartNeverAuthorizesStopOrAutomaticRestoration() {
        let meeting = MeetingFocusTransport.Segment()
        meeting.predecessor.settle(succeeded: true)
        meeting.startSettled(succeeded: false)
        meeting.startSettled(succeeded: true)
        XCTAssertFalse(meeting.canSendMutation, "Late success must not revive an uncertain segment")
        let restored = MeetingFocusTransport.Segment()
        let finish = MeetingFocusTransport.FinishRequest(segment: meeting, confirmation: restored.predecessor)
        XCTAssertFalse(finish.canSend)
        XCTAssertFalse(finish.allowsRetry)
        finish.settle(succeeded: false)
        XCTAssertFalse(restored.canSendStart)
        restored.startSettled(succeeded: false)
        XCTAssertTrue(restored.isReportingPending)
    }

    @MainActor
    func testMeetingTransportScopeKeepsManualSessionRequestsUnchanged() {
        let transport = MeetingFocusTransport()
        let meeting = MeetingFocusTransport.Segment()
        transport.finishPredecessor(of: meeting) {
            XCTAssertFalse(transport.captureFinish(modeID: "original").allowsRetry)
            transport.captureFinish(modeID: "original").settle(succeeded: true)
        }
        XCTAssertTrue(transport.captureFinish(modeID: "original").allowsRetry)
        transport.start(meeting) {
            transport.sessionStarted()
            XCTAssertTrue(transport.activeSegment === meeting)
            XCTAssertTrue(transport.captureStart(modeID: "meeting") === meeting)
            XCTAssertNil(transport.segmentForMode("unrelated"))
            XCTAssertTrue(transport.captureFinish(modeID: "unrelated").allowsRetry)
            XCTAssertFalse(transport.captureFinish(modeID: "meeting").allowsRetry)
        }
        transport.sessionStarted()
        XCTAssertNil(transport.activeSegment)
        XCTAssertTrue(transport.captureFinish(modeID: "original").canSend)
        XCTAssertTrue(transport.captureFinish(modeID: "original").allowsRetry)
    }

    @MainActor
    func testLifecycleTransportOrdersFinishStartAndPauseUntilEachCompletes() {
        var deadlines: [() -> Void] = []
        let queue = FocusLifecycleRequestQueue(scheduleDeadline: { _, action in
            deadlines.append(action)
            return {}
        }, deliver: { $0() })
        var leases: [FocusLifecycleRequestQueue.Lease] = []
        var events: [String] = []
        for name in ["finish original", "start meeting", "finish meeting", "resume original", "pause original"] {
            queue.enqueue(start: { lease in events.append(name); leases.append(lease) }, completion: { _ in })
        }
        XCTAssertEqual(events, ["finish original"])
        leases[0].finish([:])
        XCTAssertEqual(events, ["finish original", "start meeting"])
        leases[1].finish(nil)
        XCTAssertEqual(events.last, "finish meeting", "A failed request must release the queue")
        leases[2].finish([:])
        XCTAssertEqual(events.last, "resume original")
        leases[3].finish([:])
        XCTAssertEqual(events.last, "pause original", "Pause cannot overtake the restored start")
        leases[4].finish([:])
        XCTAssertEqual(deadlines.count, events.count)
    }

    @MainActor
    func testLifecycleDeadlineCancelsTransportAndIgnoresLateCallbacks() {
        var deadlines: [() -> Void] = []
        let queue = FocusLifecycleRequestQueue(scheduleDeadline: { _, action in
            deadlines.append(action)
            return {}
        }, deliver: { $0() })
        var first: FocusLifecycleRequestQueue.Lease?
        var cancellations = 0
        var completions = 0
        var nextStarts = 0
        queue.enqueue(start: { lease in
            first = lease
            lease.attachCancellation { cancellations += 1 }
        }, completion: { _ in completions += 1 })
        queue.enqueue(start: { _ in nextStarts += 1 }, completion: { _ in })
        deadlines[0]()
        XCTAssertFalse(first?.isActive ?? true)
        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(nextStarts, 1)
        first?.finish([:])
        deadlines[0]()
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(nextStarts, 1)
    }

    @MainActor
    func testLifecycleMissingCredentialsAndLateTaskCreationCannotStrandQueue() {
        var deadlines: [() -> Void] = []
        let queue = FocusLifecycleRequestQueue(scheduleDeadline: { _, action in
            deadlines.append(action)
            return {}
        }, deliver: { $0() })
        var waitingForCredentials: FocusLifecycleRequestQueue.Lease?
        var followingCompleted = false
        queue.enqueue(start: { waitingForCredentials = $0 }, completion: { _ in })
        queue.enqueue(start: { $0.finish(nil) }, completion: { _ in followingCompleted = true })
        deadlines[0]()
        XCTAssertTrue(followingCompleted)
        var lateTaskCancelled = false
        waitingForCredentials?.attachCancellation { lateTaskCancelled = true }
        XCTAssertTrue(lateTaskCancelled, "A task created after expiry must be cancelled before sending")
    }

    func testMeetingHandoffStartsAfterQueuedFinishCleanupAndAcceptsFinishStateChange() {
        var state = "running"
        var callbacks: [() -> Void] = []
        var events: [String] = []
        scheduleMeetingFocusHandoff(finish: {
            events.append("finish report")
            state = "finished"
            callbacks.append { events.append("finish UI cleanup") }
        }, currentState: { state }, enqueue: { callbacks.append($0) },
            cancelled: { XCTFail("The finish's own state change must not cancel the handoff") },
            start: { events.append("start resumed segment") })
        XCTAssertEqual(events, ["finish report"])
        callbacks.forEach { $0() }
        XCTAssertEqual(events, ["finish report", "finish UI cleanup", "start resumed segment"])
    }

    func testRoutineTransitionAfterMeetingFinishCancelsQueuedRestore() {
        var state = "postponed"
        var callbacks: [() -> Void] = []
        var cancelled = false
        scheduleMeetingFocusHandoff(finish: {}, currentState: { state },
            enqueue: { callbacks.append($0) }, cancelled: { cancelled = true },
            start: { XCTFail("A newly active routine must not be replaced by saved focus") })
        state = "routine active"
        callbacks.forEach { $0() }
        XCTAssertTrue(cancelled)
    }

    func testFinishedSegmentSnapshotCannotFollowTheNewSessionsMutableState() {
        var tasks = "original queue"
        var duration = 127
        var score = 84.0
        let snapshot = FocusSessionFinishSnapshot(tasks: tasks, durationSeconds: duration, alignmentScore: score)
        tasks = "meeting queue"
        duration = 0
        score = 100
        XCTAssertEqual(snapshot.tasks, "original queue")
        XCTAssertEqual(snapshot.durationSeconds, 127)
        XCTAssertEqual(snapshot.alignmentScore, 84)
        XCTAssertNotEqual(snapshot.tasks, tasks)
        XCTAssertNotEqual(snapshot.durationSeconds, duration)
        XCTAssertNotEqual(snapshot.alignmentScore, score)
    }

    func testMeetingHandoffRetainsPreviousSessionAcrossMeetingStartAndConsumesItOnce() {
        var handoff = MeetingFocusHandoff<String>()
        let generation = handoff.suspend("original session")
        XCTAssertTrue(handoff.beginStart(generation))
        handoff.sessionStarted()
        handoff.endStart()
        XCTAssertEqual(handoff.consume()?.0, "original session")
        XCTAssertNil(handoff.consume())
    }

    func testUnrelatedSessionInvalidatesQueuedMeetingOrResume() {
        var handoff = MeetingFocusHandoff<String>()
        let generation = handoff.suspend("original session")
        handoff.sessionStarted()
        XCTAssertFalse(handoff.beginStart(generation))
        XCTAssertNil(handoff.consume())
    }

    func testOldMeetingCallbackCannotCancelNewerHandoff() {
        var handoff = MeetingFocusHandoff<String>()
        let old = handoff.suspend("old")
        let current = handoff.suspend("new")
        handoff.cancel(ifCurrent: old)
        XCTAssertFalse(handoff.beginStart(old))
        XCTAssertTrue(handoff.beginStart(current))
        XCTAssertEqual(handoff.consume()?.0, "new")
    }

    func testInterruptedRemainingTimePreservesSecondsAndPausedDuration() {
        let now = Date(timeIntervalSinceReferenceDate: 1000)
        XCTAssertEqual(MeetingFocusResumeTiming.remainingSeconds(
            end: now.addingTimeInterval(61.2), pausedSeconds: nil, now: now), 62)
        XCTAssertEqual(MeetingFocusResumeTiming.remainingSeconds(
            end: now.addingTimeInterval(-500), pausedSeconds: 37, now: now), 37)
        XCTAssertNil(MeetingFocusResumeTiming.remainingSeconds(end: now, pausedSeconds: nil, now: now))
        XCTAssertNil(MeetingFocusResumeTiming.remainingSeconds(end: nil, pausedSeconds: nil, now: now))
        XCTAssertNil(MeetingFocusResumeTiming.remainingSeconds(end: nil, pausedSeconds: 0, now: now))
    }

    func testRestoredStrictnessUsesTheExistingPersistedValues() {
        XCTAssertEqual(MeetingFocusResumeTiming.storedStrictness(._NORMAL_), FocusStartStrictness.junior.storedValue)
        XCTAssertEqual(MeetingFocusResumeTiming.storedStrictness(._STRICT_), FocusStartStrictness.captain.storedValue)
        XCTAssertEqual(MeetingFocusResumeTiming.storedStrictness(._SUPER_STRICT_), FocusStartStrictness.pawfessor.storedValue)
    }

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


    // MARK: The calendar actually reaches the request (report 2026-09-23_09-25-08)
    //
    // The client built the calendar lines, logged them, and then left them out of the body under a
    // comment saying the endpoint did not accept them. It does. So the buddy replied "I can see your
    // calendar is not provided here, so I can't verify the meeting" about a meeting ten minutes away
    // and plainly on the calendar, and made the user argue for it.

    private typealias Calendar = AccountabilityCalendarPayload

    func testOrdinaryCalendarLinesPassThroughUnchanged() {
        let events = ["Head to RMIT — ended at 09:15",
                      "Focusbear app discussion - Deakin DRC — at 09:30 (in 8 min)"]
        XCTAssertEqual(Calendar.forRequest(events), events)
    }

    func testBlankLinesAreDroppedRatherThanSent() {
        XCTAssertEqual(Calendar.forRequest(["", "   ", "Standup — at 10:00"]), ["Standup — at 10:00"])
        XCTAssertTrue(Calendar.forRequest([]).isEmpty)
        XCTAssertTrue(Calendar.forRequest(["  "]).isEmpty,
                      "an all-blank list must come out empty so the caller omits the field entirely")
    }

    /// The DTO 400s past its outer bounds, and a 400 here means no calendar at all — the exact state
    /// being fixed. Degrade instead.
    func testACrowdedCalendarDegradesInsteadOfFailingTheRequest() {
        let many = (1...Calendar.maximumEvents + 40).map { "Meeting \($0) — at 10:00" }
        XCTAssertEqual(Calendar.forRequest(many).count, Calendar.maximumEvents)

        let stuffed = String(repeating: "a", count: Calendar.maximumLineLength + 500)
        XCTAssertEqual(Calendar.forRequest([stuffed]).first?.count, Calendar.maximumLineLength)
    }

    func testTheNearestEventsAreTheOnesKept() {
        // The context is built nearest-first, so trimming from the end drops the furthest away.
        let many = (1...Calendar.maximumEvents + 5).map { "Meeting \($0)" }
        XCTAssertEqual(Calendar.forRequest(many).first, "Meeting 1")
        XCTAssertEqual(Calendar.forRequest(many).last, "Meeting \(Calendar.maximumEvents)")
    }

}

// MARK: - Recovery card: which situation it is explaining (report 2026-09-25_15-40-49)

extension AccountabilityPostponeRecoveryTests {
    private typealias Reason = AccountabilityRecoveryReason

    func testNoConnectionReadsAsOffline() {
        for code in [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotFindHost,
                     NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed] {
            XCTAssertEqual(Reason.from(error: NSError(domain: NSURLErrorDomain, code: code)), .offline, "\(code)")
        }
    }

    func testAServerSideFailureReadsAsUnavailableNotOffline() {
        // A timeout means the network worked and the server was slow: telling the user they're offline
        // would send them to fix the wrong thing.
        XCTAssertEqual(Reason.from(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)), .unavailable)
        XCTAssertEqual(Reason.from(error: NSError(domain: "AccountabilityBuddy", code: 500)), .unavailable)
    }

    func testOnlyAStuckConversationStartsAsTheSubtleQuestion() {
        XCTAssertTrue(Reason.stuck.startsCollapsed)
        XCTAssertFalse(Reason.offline.startsCollapsed)
        XCTAssertFalse(Reason.unavailable.startsCollapsed)
    }

    func testTheDefaultDurationIsOneTheCardOffers() {
        XCTAssertEqual(AccountabilityPostponeRecovery.defaultMinutes, 15)
        XCTAssertTrue(AccountabilityPostponeRecovery.durations.contains(AccountabilityPostponeRecovery.defaultMinutes))
    }
}

// MARK: - Day context sent to the buddy (report 2026-09-25_16-00-37)

extension AccountabilityPostponeRecoveryTests {
    private typealias Day = AccountabilityDayContext

    private var fixedCalendar: Foundation.Calendar {
        var calendar = Foundation.Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        return calendar
    }

    private func at(_ hour: Int, _ minute: Int) -> Date {
        fixedCalendar.date(from: DateComponents(year: 2026, month: 9, day: 25, hour: hour, minute: minute))!
    }

    func testRoutineCompletionIsTheShareOfHabitsDone() {
        XCTAssertEqual(Day.routineCompletionPercent(totalHabits: 10, remainingHabits: 4), 60)
        XCTAssertEqual(Day.routineCompletionPercent(totalHabits: 6, remainingHabits: 6), 0)
        XCTAssertEqual(Day.routineCompletionPercent(totalHabits: 3, remainingHabits: 0), 100)
        XCTAssertEqual(Day.routineCompletionPercent(totalHabits: 3, remainingHabits: 1), 67)
    }

    func testARoutineWithNoHabitsSendsNothingRatherThanZero() {
        XCTAssertNil(Day.routineCompletionPercent(totalHabits: 0, remainingHabits: 0))
    }

    func testImpossibleCountsStayInRange() {
        XCTAssertEqual(Day.routineCompletionPercent(totalHabits: 4, remainingHabits: 9), 0)
        XCTAssertEqual(Day.routineCompletionPercent(totalHabits: 4, remainingHabits: -2), 100)
    }

    func testMinutesLeftCountDownToTheShutdownTime() {
        // The reported case: 45 minutes before shutdown.
        let left = Day.minutesLeftInDay(now: at(16, 15), shutOff: Time(hour: 17, minute: 0, second: 0),
                                        isShutOffTime: false, calendar: fixedCalendar)
        XCTAssertEqual(left, 45)
    }

    func testAShutdownAfterMidnightIsTomorrows() {
        let left = Day.minutesLeftInDay(now: at(23, 0), shutOff: Time(hour: 1, minute: 0, second: 0),
                                        isShutOffTime: false, calendar: fixedCalendar)
        XCTAssertEqual(left, 120)
    }

    func testOnceShutdownHasBegunNoTimeIsLeft() {
        XCTAssertEqual(Day.minutesLeftInDay(now: at(21, 0), shutOff: Time(hour: 17, minute: 0, second: 0),
                                            isShutOffTime: true, calendar: fixedCalendar), 0)
    }

    func testNoShutdownTimeSendsNothing() {
        XCTAssertNil(Day.minutesLeftInDay(now: at(12, 0), shutOff: nil, isShutOffTime: false, calendar: fixedCalendar))
    }
}
