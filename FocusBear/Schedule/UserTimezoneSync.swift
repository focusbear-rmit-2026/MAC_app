//
//  UserTimezoneSync.swift
//  Focus Bear
//
//  Keeps the backend's declared user timezone (`PATCH /user/timezone`) equal to the Mac's IANA zone.
//  The busy-hours endpoint validates its day keys against that timezone (backend #2364), which the Mac
//  never wrote before — it defaulted to UTC, so a user west of UTC reporting "today" every evening
//  would have been rejected. Sent on launch, whenever the system zone changes, and before each
//  busy-hours report; unchanged values are never re-sent.
//

import Foundation

/// The "should we send?" rule, kept pure so it's unit-tested (UserTimezoneSyncTests).
enum UserTimezoneSyncDecision {
    /// A named IANA zone ("Australia/Melbourne", "UTC"); fixed offsets ("GMT+1000") are rejected server-side.
    static func isNamedTimeZone(_ identifier: String) -> Bool {
        identifier == "UTC" || identifier.contains("/")
    }

    /// First run (nothing sent yet) or a different zone than last sent — never an unchanged one.
    static func shouldSend(current: String, lastSent: String?) -> Bool {
        guard isNamedTimeZone(current) else { return false }
        return current != lastSent
    }
}

final class UserTimezoneSync {
    static let shared = UserTimezoneSync()

    private enum DefaultsKey {
        static let lastSentTimezone = "kUserdefaultsUserTimezoneLastSent"
    }
    /// After a server rejection don't retry on every trigger — the next day-change / launch is soon enough.
    static let retryAfterFailure: TimeInterval = 3600

    private var isSending = false
    private var lastFailureAt: Date?
    private var hasLoggedFailure = false
    private var timeZoneObserver: NSObjectProtocol?

    /// Called once at launch; the request path refreshes the Auth0 credential itself, so a launch before
    /// login just yields status 0 and the next trigger retries.
    func start() {
        guard timeZoneObserver == nil else { return }
        timeZoneObserver = NotificationCenter.default.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.syncIfNeeded()
        }
        syncIfNeeded()
    }

    /// Sends the current zone when it differs from the last one the server accepted; `completion` runs
    /// either way so a caller (the busy-hours report) can proceed once the server's day window is right.
    func syncIfNeeded(completion: (() -> Void)? = nil) {
        let current = TimeZone.current.identifier
        let defaults = UserDefaults.standard
        guard !isSending,
              UserTimezoneSyncDecision.shouldSend(current: current, lastSent: defaults.string(forKey: DefaultsKey.lastSentTimezone)),
              lastFailureAt.map({ Date().timeIntervalSince($0) >= Self.retryAfterFailure }) ?? true else {
            completion?()
            return
        }
        isSending = true
        allApiObject.updateUserTimezone(current) { [weak self] statusCode in
            DispatchQueue.main.async {
                defer { completion?() }
                guard let self = self else { return }
                self.isSending = false
                switch statusCode {
                case 200..<300:
                    defaults.set(current, forKey: DefaultsKey.lastSentTimezone)
                    addLog(text: "timezone sync: declared \(current)")
                case 0:
                    break   // no credentials / no network yet — the next trigger retries
                default:
                    self.lastFailureAt = Date()
                    guard !self.hasLoggedFailure else { return }
                    self.hasLoggedFailure = true
                    addLog(text: "timezone sync: server returned \(statusCode) for \(current)")
                }
            }
        }
    }
}
