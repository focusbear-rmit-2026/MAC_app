import Foundation

/// The error path cannot authorize a postpone until a duration is selected and one uninterrupted
/// hold completes. Uses monotonic uptime, never the editable wall clock. The UI resets on release,
/// pointer exit, lost window focus, duration changes, retry, and dismissal.
struct AccountabilityPostponeRecovery {
    static let requiredHoldSeconds: TimeInterval = 10
    static let durations = [5, 10, 15, 25, 30, 45, 60, 90, 120, 180]
    /// Preselected so the card is one hold away from done. It used to open on "Pick how long", an extra
    /// step before anything could happen (report 2026-09-25_15-40-49: "default 15m"). The hold is still
    /// required, so preselecting a duration adds no free rein.
    static let defaultMinutes = 15

    private(set) var selectedMinutes: Int?
    private(set) var progress: Double = 0
    private(set) var isAvailable = false
    private var startedAt: TimeInterval?
    private var lastTick: TimeInterval?
    private var didConfirm = false

    mutating func setAvailable(_ available: Bool) {
        isAvailable = available
        resetHold()
    }

    mutating func select(minutes: Int?) {
        selectedMinutes = minutes.flatMap { Self.durations.contains($0) ? $0 : nil }
        resetHold()
    }

    mutating func beginHold(at uptime: TimeInterval) {
        guard isAvailable, selectedMinutes != nil, !didConfirm, uptime.isFinite else { return }
        // Repeated key-down / drag events cannot restart or accelerate the same hold.
        guard startedAt == nil else { return }
        startedAt = uptime
        lastTick = uptime
    }

    mutating func resetHold() {
        startedAt = nil
        lastTick = nil
        progress = 0
    }

    /// Returns the selected duration exactly once. A sleeping / stalled UI must start a new hold:
    /// elapsed time without receiving continuous input checks is not deliberate confirmation.
    mutating func tick(at uptime: TimeInterval) -> Int? {
        guard isAvailable, !didConfirm, let start = startedAt, let last = lastTick,
              let minutes = selectedMinutes else { return nil }
        guard uptime.isFinite, uptime >= last, uptime - last <= 1 else {
            resetHold()
            return nil
        }
        lastTick = uptime
        progress = min(1, max(0, (uptime - start) / Self.requiredHoldSeconds))
        guard progress >= 1 else { return nil }
        didConfirm = true
        return minutes
    }
}

/// Keep uncurated task/habit titles within the backend DTO's 200-code-point limit. Limiting Swift
/// Characters alone is insufficient for combining marks / joined emoji; preserving whole Characters
/// while budgeting UTF-16 units is conservative for both validator.js and JavaScript string length.
enum AccountabilityRequestText {
    static func bounded(_ text: String, limit: Int = 200) -> String {
        guard limit > 0 else { return "" }
        var result = ""
        var remaining = limit
        for character in text {
            let cost = String(character).utf16.count
            guard cost <= remaining else { break }
            result.append(character)
            remaining -= cost
        }
        return result
    }

    static func context(_ lines: [String]) -> [String] { lines.map { bounded($0) } }
}

/// Why the recovery card is showing, which decides what it says first.
///
/// Report 2026-09-25_15-40-49: one generic card ("Need to push your habits back?", "Try my buddy
/// again", "Do my habit") covered three different situations. When the buddy is going in circles the
/// card should start small and only ask; when the buddy can't be reached it should say so plainly,
/// because there is nobody left to keep talking to.
enum AccountabilityRecoveryReason: Equatable {
    /// No internet connection, so the buddy can't be reached at all.
    case offline
    /// The buddy's endpoint failed or answered with something unusable.
    case unavailable
    /// The conversation is repeating itself (`AccountabilityLoopGuard`).
    case stuck

    /// URL-loading failures that mean "this Mac can't reach the network" rather than "the server
    /// failed". A timeout is left out on purpose: the network worked, the server was slow.
    private static let offlineURLErrorCodes: Set<Int> = [
        NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed, NSURLErrorInternationalRoamingOff,
        NSURLErrorDataNotAllowed,
    ]

    static func from(error: Error) -> AccountabilityRecoveryReason {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return .unavailable }
        return offlineURLErrorCodes.contains(nsError.code) ? .offline : .unavailable
    }

    /// A stuck conversation first asks, subtly, whether to step outside it. An outage opens straight
    /// onto the explanation and the postpone controls, because there's no buddy to keep talking to.
    var startsCollapsed: Bool { self == .stuck }
}

/// Where the user is in their day, sent with each buddy request so the buddy can be lenient when most of
/// the routine is done or the day is nearly over, and a little more insistent when nothing's done yet
/// (report 2026-09-25_16-00-37: "If I've done 60% of my habits already, he should be pretty lax").
enum AccountabilityDayContext {
    static let minutesPerDay = 24 * 60
    private static let secondsPerMinute = 60.0
    private static let wholePercent = 100.0

    /// Share of the current routine's habits already done, 0...100. Nil when the routine has no habits,
    /// because "0% of nothing" would read to the buddy as "hasn't started".
    static func routineCompletionPercent(totalHabits: Int, remainingHabits: Int) -> Int? {
        guard totalHabits > 0 else { return nil }
        let done = min(totalHabits, max(0, totalHabits - remainingHabits))
        return Int((Double(done) / Double(totalHabits) * wholePercent).rounded())
    }

    /// Minutes until the user's shutdown time, 0 once it has passed. Nil when no shutdown time is set.
    /// A shutdown time earlier in the clock than `now` (e.g. 1 am) is tomorrow's, unless the shutdown
    /// window has already begun.
    static func minutesLeftInDay(now: Date, shutOff: Time?, isShutOffTime: Bool,
                                 calendar: Calendar = .current) -> Int? {
        guard let shutOff = shutOff else { return nil }
        if isShutOffTime { return 0 }
        guard var shutdown = calendar.date(bySettingHour: shutOff.hour, minute: shutOff.minute,
                                           second: shutOff.second, of: now) else { return nil }
        if shutdown <= now, let tomorrow = calendar.date(byAdding: .day, value: 1, to: shutdown) {
            shutdown = tomorrow
        }
        let minutes = Int(shutdown.timeIntervalSince(now) / secondsPerMinute)
        return min(minutesPerDay, max(0, minutes))
    }
}
