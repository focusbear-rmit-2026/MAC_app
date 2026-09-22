import Foundation

/// The error path cannot authorize a postpone until a duration is selected and one uninterrupted
/// hold completes. Uses monotonic uptime, never the editable wall clock. The UI resets on release,
/// pointer exit, lost window focus, duration changes, retry, and dismissal.
struct AccountabilityPostponeRecovery {
    static let requiredHoldSeconds: TimeInterval = 10
    static let durations = [5, 10, 15, 25, 30, 45, 60, 90, 120, 180]

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
