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
