import Foundation

/// Notices when the main thread stops responding, and says so in the log.
///
/// A beachball leaves nothing behind: the app simply stops logging, and afterwards all anyone has is
/// a gap. Report 2026-09-14_22-12-31 is ten and a half minutes of silence whose last line
/// ("FocusButton: HandleLine << ACK") says nothing about what was actually stuck, because whatever
/// blocked the main thread also blocked the logging that would have named it.
///
/// This pings the main queue from a background timer. If a ping is not answered within
/// `stallThreshold`, the main thread is wedged — and because this timer runs on its OWN queue, it can
/// still write to the log while the app is frozen. The log then contains the stall, its duration, and
/// where the main thread was, instead of a hole.
final class MainThreadWatchdog {
    static let shared = MainThreadWatchdog()

    /// Long enough that ordinary work (a big Day Plan render, a routine transition) never trips it;
    /// short enough to catch a hang the user would notice.
    private static let stallThreshold: TimeInterval = 4
    private static let pingInterval: TimeInterval = 2

    private let queue = DispatchQueue(label: "io.focusbear.mainThreadWatchdog")
    private var timer: DispatchSourceTimer?
    /// When the outstanding ping was sent; nil when the main thread has answered.
    private var pendingSince: Date?
    /// Stops one long stall from filling the log with a line every two seconds.
    private var reportedCurrentStall = false

    private init() {}

    func start() {
        queue.async { [weak self] in
            guard let self = self, self.timer == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now() + Self.pingInterval, repeating: Self.pingInterval)
            timer.setEventHandler { [weak self] in self?.tick() }
            self.timer = timer
            timer.resume()
            addLog(text: "main-thread watchdog: armed (stall threshold \(Int(Self.stallThreshold))s)")
        }
    }

    private func tick() {
        if let since = pendingSince {
            let stalled = Date().timeIntervalSince(since)
            if stalled >= Self.stallThreshold, !reportedCurrentStall {
                reportedCurrentStall = true
                // Written from the watchdog's own queue, so it lands even while the app is frozen.
                addLog(text: "main-thread watchdog: STALLED for \(Int(stalled))s — the app is unresponsive. "
                           + "Last main-thread activity before this is the line above.")
            }
            return   // a ping is already outstanding; don't queue another behind it
        }
        let sent = Date()
        pendingSince = sent
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.queue.async {
                let waited = Date().timeIntervalSince(sent)
                if self.reportedCurrentStall {
                    addLog(text: "main-thread watchdog: recovered after \(Int(waited))s")
                }
                self.pendingSince = nil
                self.reportedCurrentStall = false
            }
        }
    }
}
