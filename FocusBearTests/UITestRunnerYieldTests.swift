//
//  UITestRunnerYieldTests.swift
//  FocusBearTests
//
//  When a Debug build's routine screen may step aside for a UI test run (UITestRunnerYield.swift).
//  The feature must never become a way round a routine, so most cases here are refusals: a lease that
//  is stale or isn't the runner's, a Mac that someone was using, a habit in progress. No window or
//  timer is involved — every input, including the clock and the idle time, is passed in.
//

@testable import Focus_Bear
import XCTest

/// `ACTION` is module-qualified: the test target also sees Darwin's `ACTION` (search.h).
final class UITestRunnerYieldTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let runnerPID: pid_t = 4242
    private let oneMinute: TimeInterval = 60

    private func lease(startedSecondsAgo: TimeInterval = 60, expiresIn: TimeInterval = 25 * 60) -> UITestRunnerLease {
        UITestRunnerLease(runnerPID: runnerPID, startedAt: now.addingTimeInterval(-startedSecondsAgo),
                          expiresAt: now.addingTimeInterval(expiresIn))
    }

    /// A morning routine sitting on a finished habit's screen, nothing running: the 2026-10-04 night.
    private func screen(state: CURRENTSTATE = ._MORNING_HABIT_, action: Focus_Bear.ACTION = ._END_,
                        isHabitPlaying: Bool = false, isAllowedActivityRunning: Bool = false,
                        isFocusSessionOn: Bool = false,
                        isCompletionCountdownRunning: Bool = false) -> UITestRunnerYield.RoutineScreen {
        UITestRunnerYield.RoutineScreen(state: state, action: action, isHabitPlaying: isHabitPlaying,
                                        isAllowedActivityRunning: isAllowedActivityRunning,
                                        isFocusSessionOn: isFocusSessionOn,
                                        isCompletionCountdownRunning: isCompletionCountdownRunning)
    }

    private func decide(yieldedAt: Date? = nil, hasLeaseYielded: Bool = false,
                        lease: UITestRunnerYield.LeaseStatus = .valid,
                        idleSeconds: TimeInterval = UITestRunnerYield.minimumIdleBeforeYield,
                        screen routineScreen: UITestRunnerYield.RoutineScreen? = nil,
                        isShieldShowing: Bool = true) -> UITestRunnerYield.Decision {
        UITestRunnerYield.decide(yieldedAt: yieldedAt, hasLeaseYielded: hasLeaseYielded, lease: lease,
                                 idleSeconds: idleSeconds, screen: routineScreen ?? screen(),
                                 isShieldShowing: isShieldShowing, now: now)
    }

    private var everyState: [CURRENTSTATE] {
        Array(sequence(first: CURRENTSTATE._NOTHING_) { CURRENTSTATE(rawValue: $0.rawValue + 1) })
    }

    // MARK: - The lease file

    func testParsesTheLeaseTheRunnerWrites() {
        let json = #"{"runner_pid": 4242, "started_at": 1799999940, "expires_at": 1800001500}"#
        XCTAssertEqual(UITestRunnerLease.parse(Data(json.utf8)), lease(startedSecondsAgo: 60, expiresIn: 1500))
    }

    func testRejectsALeaseMissingAFieldOrNotJSON() {
        XCTAssertNil(UITestRunnerLease.parse(Data(#"{"runner_pid": 4242, "expires_at": 1800001500}"#.utf8)))
        XCTAssertNil(UITestRunnerLease.parse(Data(#"{"runner_pid": "4242", "started_at": 1, "expires_at": 2}"#.utf8)))
        XCTAssertNil(UITestRunnerLease.parse(Data("runner 4242".utf8)))
        XCTAssertNil(UITestRunnerLease.parse(Data()))
    }

    func testARenewedLeaseIsTheSameRunAndANewRunnerIsNot() {
        let first = lease(expiresIn: 10 * oneMinute)
        XCTAssertTrue(lease(expiresIn: 29 * oneMinute).isSameRun(as: first))
        XCTAssertFalse(lease(startedSecondsAgo: 5).isSameRun(as: first))
        XCTAssertFalse(UITestRunnerLease(runnerPID: runnerPID + 1, startedAt: first.startedAt,
                                         expiresAt: first.expiresAt).isSameRun(as: first))
        XCTAssertFalse(first.isSameRun(as: nil))
    }

    // MARK: - Lease validity

    func testALiveRunnersUnexpiredLeaseIsValid() {
        let started = now.addingTimeInterval(-2 * oneMinute)
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(), now: now, runnerStartedAt: started), .valid)
    }

    func testNoLeaseFileIsMissing() {
        XCTAssertEqual(UITestRunnerYield.leaseStatus(nil, now: now, runnerStartedAt: now), .missing)
    }

    func testALeasePastItsExpiryIsExpired() {
        let started = now.addingTimeInterval(-2 * oneMinute)
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(expiresIn: 0), now: now, runnerStartedAt: started), .expired)
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(expiresIn: -1), now: now, runnerStartedAt: started), .expired)
    }

    func testALeaseClaimingMoreThanThirtyMinutesIsRefused() {
        let started = now.addingTimeInterval(-2 * oneMinute)
        let limit = UITestRunnerYield.maximumLeaseLifetime
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(expiresIn: limit), now: now, runnerStartedAt: started), .valid)
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(expiresIn: limit + 1), now: now, runnerStartedAt: started), .overlong)
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(expiresIn: 24 * 60 * oneMinute), now: now, runnerStartedAt: started),
                       .overlong)
    }

    func testADeadRunnerEndsTheLease() {
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(), now: now, runnerStartedAt: nil), .runnerGone)
    }

    /// The runner died and its PID went to a process started after the lease was written.
    func testAReusedRunnerPIDEndsTheLease() {
        let writtenAt = lease().startedAt
        let tolerance = UITestRunnerYield.runnerStartTolerance
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(), now: now, runnerStartedAt: writtenAt.addingTimeInterval(tolerance)),
                       .valid)
        XCTAssertEqual(UITestRunnerYield.leaseStatus(lease(), now: now,
                                                     runnerStartedAt: writtenAt.addingTimeInterval(tolerance + 1)),
                       .runnerGone)
    }

    // MARK: - Which routine screens may step aside

    func testAnIdleRoutineScreenMayStepAside() {
        for state in [CURRENTSTATE._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_] {
            for action in [Focus_Bear.ACTION._START_, ._END_] {
                XCTAssertNil(UITestRunnerYield.ineligibility(of: screen(state: state, action: action)), "\(state) \(action)")
            }
        }
    }

    func testAHabitInProgressOrARoutineStepKeepsTheScreen() {
        for action in [Focus_Bear.ACTION._INPROGRESS_, ._VISUALIZE_, ._BRAIN_DUMP_] {
            XCTAssertEqual(UITestRunnerYield.ineligibility(of: screen(action: action)), .routineStep(action))
        }
    }

    /// Breaks, the focus summary, shut-off time, the breathing intro, an abort countdown, postponed and
    /// idle states: none of them is a routine waiting for its next habit.
    func testEveryOtherStateKeepsTheScreen() {
        let routineStates: Set<CURRENTSTATE> = [._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_]
        let others = everyState.filter { !routineStates.contains($0) }
        XCTAssertTrue(others.contains(._MICRO_BREAK_) && others.contains(._SHUTOFFMAC_) && others.contains(._LOGIN_))
        for state in others {
            XCTAssertEqual(UITestRunnerYield.ineligibility(of: screen(state: state)), .notARoutine(state))
        }
    }

    func testAnythingRunningKeepsTheScreen() {
        XCTAssertEqual(UITestRunnerYield.ineligibility(of: screen(isHabitPlaying: true)), .habitPlaying)
        XCTAssertEqual(UITestRunnerYield.ineligibility(of: screen(isAllowedActivityRunning: true)), .allowedActivityRunning)
        XCTAssertEqual(UITestRunnerYield.ineligibility(of: screen(isFocusSessionOn: true)), .focusSession)
        XCTAssertEqual(UITestRunnerYield.ineligibility(of: screen(isCompletionCountdownRunning: true)), .completionCountdown)
    }

    // MARK: - Yielding

    func testYieldsAfterFiveIdleMinutesOnAnIdleRoutine() {
        XCTAssertEqual(decide(), .yield)
    }

    func testAMacUsedInTheLastFiveMinutesKeepsTheScreen() {
        XCTAssertEqual(decide(idleSeconds: UITestRunnerYield.minimumIdleBeforeYield - 1), .stay)
        XCTAssertEqual(decide(idleSeconds: 0), .stay)
    }

    func testOnlyAValidLeaseYields() {
        for status in [UITestRunnerYield.LeaseStatus.missing, .expired, .overlong, .runnerGone] {
            XCTAssertEqual(decide(lease: status), .stay, "\(status)")
        }
    }

    func testARunningHabitKeepsTheScreenHoweverLongTheMacIsIdle() {
        XCTAssertEqual(decide(idleSeconds: 8 * 60 * oneMinute, screen: screen(action: ._INPROGRESS_)), .stay)
        XCTAssertEqual(decide(idleSeconds: 8 * 60 * oneMinute, screen: screen(state: ._MICRO_BREAK_)), .stay)
    }

    func testNothingToStepAsideFromWithoutTheShieldOnScreen() {
        XCTAssertEqual(decide(isShieldShowing: false), .stay)
    }

    func testALeaseGetsOneYield() {
        XCTAssertEqual(decide(hasLeaseYielded: true, idleSeconds: 60 * oneMinute), .stay)
    }

    // MARK: - Restoring

    private var yieldedAt: Date { now.addingTimeInterval(-10 * oneMinute) }

    func testStaysAsideWhileTheRunGoesOnEvenThoughTheSuiteResetsTheIdleClock() {
        XCTAssertEqual(decide(yieldedAt: yieldedAt, idleSeconds: 0), .stay)
    }

    func testTheRoutineReturnsWhenTheLeaseEnds() {
        for status in [UITestRunnerYield.LeaseStatus.missing, .expired, .overlong, .runnerGone] {
            XCTAssertEqual(decide(yieldedAt: yieldedAt, lease: status), .restore(reason: "lease \(status)"))
        }
    }

    func testTheRoutineReturnsWhenSomethingStarts() {
        XCTAssertEqual(decide(yieldedAt: yieldedAt, screen: screen(action: ._INPROGRESS_)),
                       .restore(reason: UITestRunnerYield.Ineligibility.routineStep(._INPROGRESS_).description))
        XCTAssertEqual(decide(yieldedAt: yieldedAt, screen: screen(state: ._MICRO_BREAK_)),
                       .restore(reason: UITestRunnerYield.Ineligibility.notARoutine(._MICRO_BREAK_).description))
        XCTAssertEqual(decide(yieldedAt: yieldedAt, screen: screen(isFocusSessionOn: true)),
                       .restore(reason: UITestRunnerYield.Ineligibility.focusSession.description))
    }

    func testTheRoutineReturnsAfterTheYieldTimeLimit() {
        let limit = UITestRunnerYield.maximumYieldDuration
        XCTAssertEqual(decide(yieldedAt: now.addingTimeInterval(-limit + 1)), .stay)
        XCTAssertEqual(decide(yieldedAt: now.addingTimeInterval(-limit)), .restore(reason: "yield reached its time limit"))
    }

    // MARK: - Release builds

    /// A Release build must contain no yield path: the whole file sits inside `#if DEBUG`, and every
    /// line elsewhere that reaches it is fenced the same way.
    func testTheYieldIsCompiledOutOfReleaseBuilds() throws {
        let appSources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FocusBear")
        let yieldLines = try codeLines(of: appSources.appendingPathComponent("Routine/UITestRunnerYield.swift"))
        XCTAssertEqual(yieldLines.first, "#if DEBUG")
        XCTAssertEqual(yieldLines.last, "#endif")
        XCTAssertEqual(yieldLines.filter { $0.hasPrefix("#if") }.count, 1, "one fence around the whole file")

        for file in ["AppDelegate.swift", "mainWindowController.swift"] {
            let lines = try codeLines(of: appSources.appendingPathComponent(file))
            var fences: [String] = []
            var callSites = 0
            for line in lines {
                if line.hasPrefix("#if") { fences.append(line) }
                else if line.hasPrefix("#else") || line.hasPrefix("#elseif") { fences[fences.count - 1] = line }
                else if line.hasPrefix("#endif") { fences.removeLast() }
                else if line.contains("UITestRunnerYield") {
                    callSites += 1
                    XCTAssertEqual(fences.last, "#if DEBUG", "\(file): \(line)")
                }
            }
            XCTAssertGreaterThan(callSites, 0, "\(file) no longer reaches the yield — update this test")
        }
    }

    /// Trimmed lines, without blank lines and `//` comments.
    private func codeLines(of file: URL) throws -> [String] {
        try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("//") }
    }
}
