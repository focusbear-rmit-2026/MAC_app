//
//  UITestRunnerYield.swift
//  Focus Bear
//
//  DEBUG builds only — a Release build contains none of this (UITestRunnerYieldTests checks the
//  `#if DEBUG` fence). It lets a UI test run on a developer's Mac (scripts/run-ui-tests.sh) take the
//  screen from a routine screen nobody is using.
//
//  The routine window sits above every other window, so it takes every click the UI tests synthesize;
//  the runner therefore refused to start under it (exit 75). On 2026-10-04 a routine sat on its
//  "finished" screen all night and no run started. The runner now publishes a lease (a small JSON file
//  plus a distributed notification) and this steps the routine window aside — orders it out, never
//  ends, skips or postpones anything — only when ALL of these hold:
//    • the lease is valid: not expired, not claiming more than `maximumLeaseLifetime`, and its runner
//      process is alive and is the process that wrote it (a reused PID started later);
//    • nobody has touched the Mac for `minimumIdleBeforeYield` at the moment of yielding;
//    • no habit is running: a morning, evening or custom routine waiting to start or showing a finished
//      habit, with no countdown, playing or paused habit, allowed-activity habit or focus session.
//  The window comes back as soon as the lease ends (the runner exits or dies, or the lease expires),
//  the routine leaves those states (a break, a focus session, a habit starting), or the yield has lasted
//  `maximumYieldDuration` — and a lease gets one yield, so it cannot idle its way into a second.
//
//  Idle is measured only at the moment of yielding. XCUITest moves the real pointer and types through
//  the HID event system, which resets the idle clock, so "input ends the yield" would end it at the
//  suite's first click and could not tell the suite from a person. That is not a way round a routine:
//  it needs a Debug build, a runner script started on purpose, and five minutes away from the Mac with
//  no habit running first — and the routine itself is never touched, only hidden until the run ends.
//

#if DEBUG
import AppKit
import CoreGraphics
import Darwin

/// What scripts/run-ui-tests.sh publishes while it runs. The file location, notification name and
/// field names are shared with scripts/ui-test-runner-lease.sh — change both together.
struct UITestRunnerLease: Equatable, Decodable {
    let runnerPID: pid_t
    let startedAt: Date
    let expiresAt: Date

    private enum CodingKeys: String, CodingKey {
        case runnerPID = "runner_pid"
        case startedAt = "started_at"
        case expiresAt = "expires_at"
    }

    /// Renewals move only the expiry, so the runner and its start identify one run.
    func isSameRun(as other: UITestRunnerLease?) -> Bool {
        runnerPID == other?.runnerPID && startedAt == other?.startedAt
    }

    static func parse(_ data: Data) -> UITestRunnerLease? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(UITestRunnerLease.self, from: data)
    }
}

/// The pure decision. `UITestRunnerYieldController` gathers the inputs and applies the result.
enum UITestRunnerYield {
    static let leaseFileName = "com.focusbear.uitest-lease.json"
    static let leaseChangedNotification = Notification.Name("com.focusbear.uitest-lease-changed")
    static let minimumIdleBeforeYield: TimeInterval = 5 * 60
    /// A lease is renewed while its run lasts; one claiming longer than this is not the runner's.
    static let maximumLeaseLifetime: TimeInterval = 30 * 60
    /// However the lease is renewed, the routine is back after this — longer than a full Regression run.
    static let maximumYieldDuration: TimeInterval = 2 * 60 * 60
    /// Process start times and the lease's own stamp come from different clocks' rounding.
    static let runnerStartTolerance: TimeInterval = 2
    /// The app under test is never the one to step aside: its routine is what the routine tests drive.
    static let testBuildBundleSuffix = ".uitests"

    static let routineStates: Set<CURRENTSTATE> = [._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_]
    /// Waiting for the first habit, or a habit's finished screen. `_INPROGRESS_` is a habit playing or
    /// paused; `_VISUALIZE_` and `_BRAIN_DUMP_` are routine steps the user is in the middle of.
    static let idleRoutineActions: Set<ACTION> = [._START_, ._END_]

    enum LeaseStatus: Equatable {
        case valid, missing, expired, overlong, runnerGone
    }

    static func leaseStatus(_ lease: UITestRunnerLease?, now: Date, runnerStartedAt: Date?) -> LeaseStatus {
        guard let lease = lease else { return .missing }
        guard lease.expiresAt > now else { return .expired }
        guard lease.expiresAt.timeIntervalSince(now) <= maximumLeaseLifetime else { return .overlong }
        guard let runnerStartedAt = runnerStartedAt,
              runnerStartedAt <= lease.startedAt.addingTimeInterval(runnerStartTolerance) else { return .runnerGone }
        return .valid
    }

    struct RoutineScreen: Equatable {
        var state: CURRENTSTATE
        var action: ACTION
        var isHabitPlaying: Bool
        var isAllowedActivityRunning: Bool
        var isFocusSessionOn: Bool
        var isCompletionCountdownRunning: Bool
    }

    enum Ineligibility: Equatable, CustomStringConvertible {
        case notARoutine(CURRENTSTATE)
        case routineStep(ACTION)
        case habitPlaying
        case allowedActivityRunning
        case focusSession
        case completionCountdown

        var description: String {
            switch self {
            case .notARoutine(let state): return "state \(state) is not an idle routine"
            case .routineStep(let action): return "routine step \(action) is in progress"
            case .habitPlaying: return "a habit is playing"
            case .allowedActivityRunning: return "an allowed-activity habit is running"
            case .focusSession: return "a focus session is on"
            case .completionCountdown: return "the next habit's countdown is running"
            }
        }
    }

    /// Why the routine screen must stay, or nil when it may step aside.
    static func ineligibility(of screen: RoutineScreen) -> Ineligibility? {
        guard routineStates.contains(screen.state) else { return .notARoutine(screen.state) }
        guard idleRoutineActions.contains(screen.action) else { return .routineStep(screen.action) }
        if screen.isHabitPlaying { return .habitPlaying }
        if screen.isAllowedActivityRunning { return .allowedActivityRunning }
        if screen.isFocusSessionOn { return .focusSession }
        if screen.isCompletionCountdownRunning { return .completionCountdown }
        return nil
    }

    enum Decision: Equatable {
        case stay
        case yield
        case restore(reason: String)
    }

    /// - Parameter hasLeaseYielded: this lease has had its yield already. One per lease, so a run cannot
    ///   outlast `maximumYieldDuration` (or a break) by idling into a second one.
    static func decide(yieldedAt: Date?, hasLeaseYielded: Bool, lease: LeaseStatus, idleSeconds: TimeInterval,
                       screen: RoutineScreen, isShieldShowing: Bool, now: Date) -> Decision {
        guard let yieldedAt = yieldedAt else {
            let mayYield = !hasLeaseYielded && isShieldShowing && lease == .valid
                && idleSeconds >= minimumIdleBeforeYield && ineligibility(of: screen) == nil
            return mayYield ? .yield : .stay
        }
        if lease != .valid { return .restore(reason: "lease \(lease)") }
        if let reason = ineligibility(of: screen) { return .restore(reason: reason.description) }
        if now.timeIntervalSince(yieldedAt) >= maximumYieldDuration { return .restore(reason: "yield reached its time limit") }
        return .stay
    }
}

/// Watches for a runner's lease and steps the routine window aside while `UITestRunnerYield` allows.
final class UITestRunnerYieldController: NSObject {
    static let shared = UITestRunnerYieldController()

    /// How often a published lease is re-checked: the runner dying, the lease expiring, the Mac reaching
    /// its idle threshold, and anything that ordered the routine window back in while yielded.
    private static let evaluationInterval: TimeInterval = 1
    /// `kCGAnyInputEventType`: every keyboard, mouse and tablet event.
    private static let anyInputEvent = CGEventType(rawValue: ~0)!
    /// Above pop-up menus — where the routine and break windows sit. Same floor as
    /// scripts/installed-focus-bear-cover.swift.
    private static let shieldLevelFloor = Int(CGWindowLevelForKey(.overlayWindow))

    private var timer: Timer?
    private var yieldedAt: Date?
    /// The lease the routine last stepped aside for.
    private var yieldedLease: UITestRunnerLease?
    private var isStarted = false

    private var leaseFile: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches", isDirectory: true)
            .appendingPathComponent(UITestRunnerYield.leaseFileName)
    }

    func start() {
        guard !isStarted, !(Bundle.main.bundleIdentifier ?? "").hasSuffix(UITestRunnerYield.testBuildBundleSuffix) else { return }
        isStarted = true
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(leaseChanged),
                                                            name: UITestRunnerYield.leaseChangedNotification,
                                                            object: nil, suspensionBehavior: .deliverImmediately)
        evaluate()
    }

    /// `mainWindowController` calls this when the routine window's visibility changes, so a route that
    /// shows it again while yielded is undone at once rather than on the next tick.
    func mainWindowVisibilityChanged() {
        guard yieldedAt != nil else { return }
        keepShieldOrderedOut()
    }

    @objc private func leaseChanged(_ notification: Notification) {
        addLog(text: "UI test yield: runner lease changed")
        evaluate()
    }

    private func evaluate() {
        let now = Date()
        let lease = readLease()
        let status = UITestRunnerYield.leaseStatus(lease, now: now,
                                                   runnerStartedAt: lease.flatMap { processStartDate($0.runnerPID) })
        // A stale lease cannot become valid again: the next runner writes a new one and says so.
        guard yieldedAt != nil || status == .valid else { return stopTimer() }
        startTimerIfNeeded()
        let decision = UITestRunnerYield.decide(yieldedAt: yieldedAt, hasLeaseYielded: lease?.isSameRun(as: yieldedLease) ?? false,
                                                lease: status, idleSeconds: secondsSinceLastInput(),
                                                screen: currentRoutineScreen(), isShieldShowing: isShieldShowing, now: now)
        switch decision {
        case .yield:
            yieldedLease = lease
            yield(runner: lease?.runnerPID)
        case .restore(let reason): restore(reason: reason)
        case .stay where yieldedAt != nil: keepShieldOrderedOut()
        case .stay: break
        }
    }

    private func yield(runner: pid_t?) {
        yieldedAt = Date()
        addLog(text: "UI test yield: stepping the routine window aside for runner \(runner.map(String.init) ?? "?") "
               + "(idle \(Int(secondsSinceLastInput())) s, \(currentState) / \(currentAction))")
        keepShieldOrderedOut()
    }

    private func restore(reason: String) {
        yieldedAt = nil
        addLog(text: "UI test yield: restoring the routine window — \(reason)")
        mainWindowControllerObj?.showWindow(nil)
        appdelegate?.showExtraWindows()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func keepShieldOrderedOut() {
        if let window = mainWindowControllerObj?.window, window.isVisible {
            window.orderOut(nil)
            addLog(text: "UI test yield: routine window ordered out")
        }
        if !arrWindows.isEmpty { hideBlankWindowInSecondaryMonitor() }
    }

    private var isShieldShowing: Bool {
        guard let window = mainWindowControllerObj?.window else { return false }
        return window.isVisible && window.level.rawValue >= Self.shieldLevelFloor
    }

    private func currentRoutineScreen() -> UITestRunnerYield.RoutineScreen {
        UITestRunnerYield.RoutineScreen(
            state: currentState, action: currentAction,
            isHabitPlaying: currentHabitPlaying != nil || currentRelaxHabitPlaying != nil || currentActivityPlaying != nil,
            isAllowedActivityRunning: isAllowedActivityHabitCurrentlyRunning,
            isFocusSessionOn: isFocusModeOn(),
            isCompletionCountdownRunning: activityCompletionVcObj?.isTimerGoingOn ?? false)
    }

    /// Hardware input only (`hidSystemState`), the clock the screen saver uses.
    private func secondsSinceLastInput() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: Self.anyInputEvent)
    }

    private func readLease() -> UITestRunnerLease? {
        guard let data = try? Data(contentsOf: leaseFile) else { return nil }
        return UITestRunnerLease.parse(data)
    }

    /// When `pid` started, or nil when no such process exists.
    private func processStartDate(_ pid: pid_t) -> Date? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var query: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&query, u_int(query.count), &info, &size, nil, 0) == 0, size > 0 else { return nil }
        let started = info.kp_proc.p_un.__p_starttime
        return Date(timeIntervalSince1970: TimeInterval(started.tv_sec) + TimeInterval(started.tv_usec) / 1_000_000)
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: Self.evaluationInterval, repeats: true) { [weak self] _ in self?.evaluate() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
#endif
