//
//  focusSessionFinishReport.swift
//  Focus Bear
//
//  Telling the server a focus session is over the moment it ends (#2678).
//
//  The end screen ("You did it!") used to be the only thing that sent the finish, and it sent it when
//  it went away. A quit, crash or restart while it was showing therefore left the session running on
//  the server: the next launch restored it — blocking included — until its original end time, and
//  every other device showed it running too.
//
//  So the finish is sent when the session ends, before the end screen is drawn, and what the user
//  enters on the end screen is attached to the finished session afterwards. Nothing the end screen
//  does is needed for the session to count as finished.
//
//  Three things can happen to a session once it has ended, and each is sent at most once:
//
//  - The end screen closes. If the finish reached the server, the achievements typed there are
//    attached to the finished session (and nothing is sent when there are none). If it did not, the
//    full finish is sent with the end screen's details, exactly as before.
//  - The session is extended from the end screen. The server has already closed it, so the extra
//    minutes start a new session there; extending a finished session would fail. If the finish never
//    landed, the still-open session is extended as before.
//  - The next session ends, which starts all of this over.
//

import Foundation

/// Immutable across credential callbacks and retries, which may outlive the finished session.
struct FocusSessionFinishSnapshot: Equatable {
    let tasks: String
    let durationSeconds: Int
    let alignmentScore: Double?
}

/// Identity only: queued work must not cross a sign-out/account-switch boundary.
final class FocusLifecycleIdentity {
    static let shared = FocusLifecycleIdentity()
    struct Snapshot {
        fileprivate let owner: FocusLifecycleIdentity
        fileprivate let generation: UUID
        let accountID: String?
        var isCurrent: Bool { owner.isCurrent(generation) }
    }

    private let lock = NSLock()
    private var accountID: String?
    private var generation = UUID()

    func updateAccountID(_ accountID: String?) {
        lock.lock()
        defer { lock.unlock() }
        let normalized = accountID.flatMap { $0.isEmpty ? nil : $0 }
        guard self.accountID != normalized else { return }
        self.accountID = normalized
        generation = UUID()
    }

    func capture() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return Snapshot(owner: self, generation: generation, accountID: accountID)
    }

    private func isCurrent(_ generation: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return accountID != nil && self.generation == generation
    }
}

/// A failed/ambiguous request cannot authorize a later operation against a mode-based endpoint.
/// This gate applies only to automatic meeting handoffs; ordinary manual sessions keep their behavior.
final class MeetingFocusTransport {
    static let shared = MeetingFocusTransport()

    final class FinishConfirmation {
        private(set) var succeeded: Bool?
        func settle(succeeded: Bool) {
            guard self.succeeded == nil else { return }
            self.succeeded = succeeded
        }
    }

    final class Segment {
        let predecessor = FinishConfirmation()
        fileprivate var modeID: String?
        private(set) var isRegistered = false
        private(set) var isReportingPending = false
        private var isFinished = false

        var canSendStart: Bool { predecessor.succeeded == true && !isReportingPending }
        var canSendMutation: Bool { isRegistered && !isReportingPending && !isFinished }

        func startSettled(succeeded: Bool) {
            guard !isReportingPending else { return }
            isRegistered = succeeded
            if !succeeded { isReportingPending = true }
        }

        func mutationSettled(succeeded: Bool, isFinish: Bool = false) {
            if !succeeded { isReportingPending = true }
            if succeeded && isFinish { isFinished = true }
        }
    }

    struct FinishRequest {
        let segment: Segment?
        let confirmation: FinishConfirmation?
        var canSend: Bool { segment?.canSendMutation ?? true }
        var allowsRetry: Bool { segment == nil && confirmation == nil }
        func settle(succeeded: Bool) {
            segment?.mutationSettled(succeeded: succeeded, isFinish: true)
            confirmation?.settle(succeeded: succeeded)
        }
    }

    private(set) var activeSegment: Segment?
    private var finishingDependency: FinishConfirmation?
    private var isStartingSegment = false

    func segmentForMode(_ modeID: String) -> Segment? {
        guard activeSegment?.modeID == modeID else { return nil }
        return activeSegment
    }

    func captureStart(modeID: String) -> Segment? {
        guard let segment = activeSegment else { return nil }
        if segment.modeID == nil { segment.modeID = modeID }
        return segmentForMode(modeID)
    }

    func captureFinish(modeID: String) -> FinishRequest {
        FinishRequest(segment: segmentForMode(modeID), confirmation: finishingDependency)
    }

    func finishPredecessor(of segment: Segment, action: () -> Void) {
        precondition(Thread.isMainThread)
        finishingDependency = segment.predecessor
        defer { finishingDependency = nil }
        action()
    }

    func start(_ segment: Segment, action: () -> Void) {
        precondition(Thread.isMainThread)
        activeSegment = segment
        isStartingSegment = true
        defer { isStartingSegment = false }
        action()
    }

    func sessionStarted() {
        if !isStartingSegment { activeSegment = nil }
    }
}

/// Orders only focus-session lifecycle requests; local enforcement never waits for transport.
final class FocusLifecycleRequestQueue {
    static let shared = FocusLifecycleRequestQueue()
    private static let MAXIMUM_ATTEMPTS = 2
    private static let REQUEST_DEADLINE = URLSessionConfiguration.default.timeoutIntervalForRequest
        * Double(MAXIMUM_ATTEMPTS)
    typealias DeadlineScheduler = (TimeInterval, @escaping () -> Void) -> (() -> Void)

    final class Lease {
        private let lock = NSLock()
        private var active = true
        private var cancelTask: (() -> Void)?
        private var completion: ((NSDictionary?) -> Void)?
        private let isValid: () -> Bool
        let expectedAccountID: String?

        init(isValid: @escaping () -> Bool, expectedAccountID: String?,
             completion: @escaping (NSDictionary?) -> Void) {
            self.isValid = isValid
            self.expectedAccountID = expectedAccountID
            self.completion = completion
        }

        var isActive: Bool {
            lock.lock()
            let wasActive = active
            lock.unlock()
            guard wasActive else { return false }
            guard isValid() else {
                finish(nil, cancelling: true)
                return false
            }
            return true
        }

        func permitsCredentialAccount(_ accountID: String?) -> Bool {
            isActive && expectedAccountID != nil && expectedAccountID == accountID
        }

        func attachCancellation(_ cancellation: @escaping () -> Void) {
            lock.lock()
            let shouldCancel = !active
            if active { cancelTask = cancellation }
            lock.unlock()
            if shouldCancel { cancellation() }
        }

        func finish(_ result: NSDictionary?, cancelling: Bool = false) {
            lock.lock()
            guard active else { lock.unlock(); return }
            active = false
            let callback = completion
            let cancellation = cancelling ? cancelTask : nil
            completion = nil
            cancelTask = nil
            lock.unlock()
            cancellation?()
            callback?(result)
        }
    }

    private struct Pending {
        let isValid: () -> Bool
        let expectedAccountID: String?
        let start: (Lease) -> Void
        let completion: (NSDictionary?) -> Void
    }
    private var pending: [Pending] = []
    private var activeID: UUID?
    private var cancelDeadline: (() -> Void)?
    private let scheduleDeadline: DeadlineScheduler
    private let deliver: (@escaping () -> Void) -> Void

    init(scheduleDeadline: @escaping DeadlineScheduler = { interval, action in
        let work = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: work)
        return { work.cancel() }
    }, deliver: @escaping (@escaping () -> Void) -> Void = { DispatchQueue.main.async(execute: $0) }) {
        self.scheduleDeadline = scheduleDeadline
        self.deliver = deliver
    }

    func enqueue(isValid: @escaping () -> Bool = { true }, expectedAccountID: String? = nil, start: @escaping (Lease) -> Void,
                 completion: @escaping (NSDictionary?) -> Void) {
        precondition(Thread.isMainThread)
        pending.append(Pending(isValid: isValid, expectedAccountID: expectedAccountID, start: start, completion: completion))
        startNextIfIdle()
    }

    private func startNextIfIdle() {
        guard activeID == nil, !pending.isEmpty else { return }
        let job = pending.removeFirst()
        let id = UUID()
        activeID = id
        let lease = Lease(isValid: job.isValid, expectedAccountID: job.expectedAccountID) { [weak self] result in
            guard let self else { return }
            self.deliver {
                guard self.activeID == id else { return }
                self.cancelDeadline?()
                self.cancelDeadline = nil
                self.activeID = nil
                job.completion(job.isValid() ? result : nil)
                self.startNextIfIdle()
            }
        }
        cancelDeadline = scheduleDeadline(Self.REQUEST_DEADLINE) { lease.finish(nil, cancelling: true) }
        if lease.isActive { job.start(lease) }
    }
}

/// A focus session that has ended on this Mac, identified by its block list and the finish time the
/// end screen shows.
struct EndedFocusSession: Equatable {
    let focusModeId: String
    let finishTime: Date
}

/// Whether the server accepted the finish of an ended session.
enum FocusSessionFinishOutcome: Equatable {
    case succeeded
    case failed
}

/// What closing the end screen sends to the server, once the finish sent at the end has settled.
enum EndScreenCloseReport: Equatable {
    /// The finish never reached the server, so send it now with the end screen's details.
    case finishWithDetails
    /// The session is finished on the server; attach what the user wrote on the end screen.
    case attachAchievements(String)
    /// The session is finished on the server and the end screen added nothing to it.
    case nothing

    /// `outcome` is nil when no finish was sent for the session, which only the legacy path can hit.
    static func after(_ outcome: FocusSessionFinishOutcome?, achievements: String) -> EndScreenCloseReport {
        guard outcome == .succeeded else { return .finishWithDetails }
        let hasAchievements = !achievements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasAchievements ? .attachAchievements(achievements) : .nothing
    }
}

/// The server calls the finish flow makes. Injected so the flow can be tested without a network.
protocol FocusSessionFinishTransport {
    func finish(_ session: EndedFocusSession, completion: @escaping (FocusSessionFinishOutcome) -> Void)
    func attachAchievements(_ achievements: String, to session: EndedFocusSession, completion: @escaping () -> Void)
    func extendOpenSession(focusModeId: String, until finishTime: Date)
    func startSession(focusModeId: String, from startTime: Date, until finishTime: Date)
}

/// Sends the finish of the session that just ended, and makes sure the end screen's close and an
/// extension from it each act on that session once. Confined to the main thread: every entry point is
/// called from it, and transport results are handed back to it through `deliver`.
final class FocusSessionFinishReporter {
    static let shared = FocusSessionFinishReporter(
        transport: ServerFocusSessionFinishTransport(),
        deliver: { DispatchQueue.main.async(execute: $0) })

    private let transport: FocusSessionFinishTransport
    private let deliver: (@escaping () -> Void) -> Void

    private(set) var endedSession: EndedFocusSession?
    /// Nil while the finish is in flight.
    private(set) var finishOutcome: FocusSessionFinishOutcome?
    /// The end screen has closed, or the session was extended from it: nothing more is sent for it.
    private(set) var isEndScreenResolved = false
    private var actionsAwaitingOutcome: [(FocusSessionFinishOutcome) -> Void] = []

    init(transport: FocusSessionFinishTransport, deliver: @escaping (@escaping () -> Void) -> Void) {
        self.transport = transport
        self.deliver = deliver
    }

    /// The session running on `focusModeId` has ended and its end screen is about to show.
    func sessionEnded(focusModeId: String, finishTime: Date) {
        actionsAwaitingOutcome.removeAll()
        finishOutcome = nil
        isEndScreenResolved = false
        guard !focusModeId.isEmpty else {
            endedSession = nil
            return
        }
        let session = EndedFocusSession(focusModeId: focusModeId, finishTime: finishTime)
        endedSession = session
        transport.finish(session) { [weak self] outcome in
            self?.deliver { self?.finishSettled(outcome, for: session) }
        }
    }

    /// The end screen is closing. `finishWithDetails` is the legacy full finish, sent only when the
    /// finish from the end never reached the server; it calls its argument when done. `completion` runs
    /// once whatever this sends has been answered, on any thread.
    func endScreenClosed(achievements: String,
                         finishWithDetails: @escaping (_ done: @escaping () -> Void) -> Void,
                         completion: @escaping () -> Void) {
        guard let session = endedSession else {
            finishWithDetails(completion)
            return
        }
        guard !isEndScreenResolved else {
            completion()
            return
        }
        isEndScreenResolved = true
        whenFinishSettles { [transport] outcome in
            switch EndScreenCloseReport.after(outcome, achievements: achievements) {
            case .finishWithDetails:
                finishWithDetails(completion)
            case .attachAchievements(let text):
                transport.attachAchievements(text, to: session, completion: completion)
            case .nothing:
                completion()
            }
        }
    }

    /// The session was extended from the end screen until `finishTime`.
    func sessionExtended(focusModeId: String, from startTime: Date, until finishTime: Date) {
        guard let session = endedSession, !isEndScreenResolved else {
            transport.extendOpenSession(focusModeId: focusModeId, until: finishTime)
            return
        }
        isEndScreenResolved = true
        whenFinishSettles { [transport] outcome in
            if outcome == .succeeded {
                transport.startSession(focusModeId: session.focusModeId, from: startTime, until: finishTime)
            } else {
                transport.extendOpenSession(focusModeId: session.focusModeId, until: finishTime)
            }
        }
    }

    private func finishSettled(_ outcome: FocusSessionFinishOutcome, for session: EndedFocusSession) {
        guard session == endedSession else { return }   // a later session has ended since
        finishOutcome = outcome
        let actions = actionsAwaitingOutcome
        actionsAwaitingOutcome.removeAll()
        actions.forEach { $0(outcome) }
    }

    private func whenFinishSettles(_ action: @escaping (FocusSessionFinishOutcome) -> Void) {
        if let finishOutcome {
            action(finishOutcome)
        } else {
            actionsAwaitingOutcome.append(action)
        }
    }
}

/// The server's `achievements` limit is 255 characters, and the Mac has always sent them
/// percent-encoded; both ways of storing them must write the same shape.
private let maxEncodedAchievementsLength = 250

/// Achievements as the finish call has always stored them, so the ones attached later match.
func encodedFocusSessionAchievements(_ achievements: String) -> String {
    let encoded = achievements.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? achievements
    return String(encoded.prefix(maxEncodedAchievementsLength))
}

extension FocusLogEntry {
    /// The focus log is newest first by start time, so the session that has just finished is the
    /// first row for its block list. Manual entries are the user's own records, never a live session.
    static func justFinishedSessionId(focusModeId: String, in entries: [FocusLogEntry]) -> String? {
        entries.first { $0.focusMode?.id == focusModeId && !$0.isManual }?.id
    }
}

/// How many focus-log rows to read back to find the session that has just finished.
private let justFinishedSessionLookupLimit = 5

/// The live server calls.
struct ServerFocusSessionFinishTransport: FocusSessionFinishTransport {
    func finish(_ session: EndedFocusSession, completion: @escaping (FocusSessionFinishOutcome) -> Void) {
        // The end screen still lists the session's tasks, so they are read without clearing them.
        allApiObject.finishFocusMode(id: session.focusModeId, achievements: "", distractions: "",
                                     finish_time: session.finishTime, rating: nil,
                                     sessionTasks: focusModeTaskString) { response in
            completion(response == nil ? .failed : .succeeded)
        }
    }

    func attachAchievements(_ achievements: String, to session: EndedFocusSession, completion: @escaping () -> Void) {
        allApiObject.getFocusLog(limit: justFinishedSessionLookupLimit, offset: 0) { entries in
            guard let blockId = FocusLogEntry.justFinishedSessionId(focusModeId: session.focusModeId,
                                                                    in: entries ?? []) else {
                addLog(text: "attachAchievements: no finished session found for focus mode \(session.focusModeId)")
                completion()
                return
            }
            allApiObject.attachFocusBlockAchievements(id: blockId,
                                                      achievements: encodedFocusSessionAchievements(achievements)) { _ in
                completion()
            }
        }
    }

    func extendOpenSession(focusModeId: String, until finishTime: Date) {
        allApiObject.extendFocusMode(id: focusModeId, finish_time: finishTime) { _ in }
    }

    func startSession(focusModeId: String, from startTime: Date, until finishTime: Date) {
        allApiObject.startFocusMode(id: focusModeId, intention: whatToAchieveInFocusBlock,
                                    start_time: startTime, finish_time: finishTime) { _ in }
    }
}
