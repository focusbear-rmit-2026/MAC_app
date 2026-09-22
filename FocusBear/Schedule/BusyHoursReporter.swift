//
//  BusyHoursReporter.swift
//  Focus Bear
//
//  Day-Plan-aware portfolio risk (#2418, backend #2363):
//    • `BusyHoursReporter` sends the Mac's EventKit busy hours to `PUT /portfolio/busy-hours` after the
//      Day Plan builds and otherwise hourly, so the backend's simulation stops overstating free time.
//    • `DayPlanPushedTasks` caches the portfolio's `pushed_tasks` (to-dos the simulation couldn't fit on
//      their planned day) for the tasks panel's "Doesn't fit today" hint.
//

import Foundation

final class BusyHoursReporter {
    static let shared = BusyHoursReporter()

    enum Trigger { case dayPlanBuilt, hourly }

    private enum DefaultsKey {
        static let lastSentFingerprint = "kUserdefaultsBusyHoursLastSentFingerprint"
        static let lastSentAt = "kUserdefaultsBusyHoursLastSentAt"
    }

    static let hourlyInterval: TimeInterval = 3600
    /// The Day Plan auto-refreshes every 30 s; rescanning a fortnight of events each time is wasteful.
    static let dayPlanBuildDebounce: TimeInterval = 60
    /// An unchanged payload is still re-sent this often so the server row stays inside its 2-day
    /// freshness window (older client reports are ignored server-side).
    static let resendIdenticalAfter: TimeInterval = 12 * 3600
    /// After a non-2xx (404 until the backend endpoint ships) don't hammer it on every reload.
    static let retryAfterFailure: TimeInterval = 3600
    private static let horizonCacheLifetime: TimeInterval = 3600

    private var timer: Timer?
    private var isSending = false
    private var lastComputedAt: Date?
    private var lastFailureAt: Date?
    private var cachedHorizonDays: Int?
    private var horizonFetchedAt: Date?

    /// Called once at launch: the hourly tick covers the case where the Day Plan is never opened.
    func start() {
        guard timer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: Self.hourlyInterval, repeats: true) { [weak self] _ in
            self?.report(trigger: .hourly)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        report(trigger: .hourly)
    }

    func report(trigger: Trigger) {
        if trigger == .hourly { DayPlanPushedTasks.shared.refresh() }
        // Nothing to report without calendar access — an all-zero payload would just claim free days.
        guard CalendarManager.shared.access == .authorized, !isSending else { return }
        let now = Date()
        if trigger == .dayPlanBuilt, let computed = lastComputedAt, now.timeIntervalSince(computed) < Self.dayPlanBuildDebounce { return }
        if let failed = lastFailureAt, now.timeIntervalSince(failed) < Self.retryAfterFailure { return }
        lastComputedAt = now
        // The server validates the day keys against the user's declared timezone — make sure it's ours first.
        UserTimezoneSync.shared.syncIfNeeded { [weak self] in
            self?.withHorizonDays { horizonDays in
                // buildReport reads EventKit across the whole planning horizon, and both callbacks
                // above run synchronously on the caller's thread in the steady state (timezone already
                // declared, horizon cached) — which is the main thread, since .dayPlanBuilt fires at the
                // end of reloadLive. events(matching:) is a blocking XPC call to CalendarAgent that can
                // take tens of seconds while calendars sync, so it must never run there. See
                // CalendarManager's "Meetings cache" note. `send` and the isSending/lastFailureAt state
                // stay on the main thread.
                DispatchQueue.global(qos: .utility).async {
                    let report = Self.buildReport(horizonDays: horizonDays)
                    DispatchQueue.main.async { self?.send(report) }
                }
            }
        }
    }

    static func buildReport(horizonDays: Int, now: Date = Date()) -> BusyHoursReport {
        let events = CalendarManager.shared.busyEvents(from: now, days: horizonDays)
        let days = BusyHoursCalculator.hoursByDay(events: events, firstDay: now, horizonDays: horizonDays)
        return BusyHoursReport(source: BusyHoursReport.macEventKitSource, days: days)
    }

    /// Stable identity of a payload (sorted days) so identical reports aren't re-sent.
    static func fingerprint(_ report: BusyHoursReport) -> String {
        let days = report.days.keys.sorted().map { "\($0)=\(report.days[$0] ?? 0)" }.joined(separator: ",")
        return "\(report.source)|\(days)"
    }

    /// `planning_horizon_days` from `GET /portfolio/settings`, cached for an hour; the backend default
    /// when the fetch fails (not logged in yet, offline).
    private func withHorizonDays(_ completion: @escaping (Int) -> Void) {
        if let cached = cachedHorizonDays, let fetched = horizonFetchedAt, Date().timeIntervalSince(fetched) < Self.horizonCacheLifetime {
            completion(cached)
            return
        }
        allApiObject.getPortfolioSettings { [weak self] settings in
            DispatchQueue.main.async {
                if let days = settings?.planning_horizon_days, days > 0 {
                    self?.cachedHorizonDays = days
                    self?.horizonFetchedAt = Date()
                }
                completion(settings?.planning_horizon_days ?? PortfolioSettings.defaultHorizonDays)
            }
        }
    }

    private func send(_ report: BusyHoursReport) {
        let fingerprint = Self.fingerprint(report)
        let defaults = UserDefaults.standard
        if fingerprint == defaults.string(forKey: DefaultsKey.lastSentFingerprint),
           let sentAt = defaults.object(forKey: DefaultsKey.lastSentAt) as? Date,
           Date().timeIntervalSince(sentAt) < Self.resendIdenticalAfter {
            return
        }
        isSending = true
        allApiObject.reportPortfolioBusyHours(report) { [weak self] statusCode in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSending = false
                switch statusCode {
                case 200..<300:
                    defaults.set(fingerprint, forKey: DefaultsKey.lastSentFingerprint)
                    defaults.set(Date(), forKey: DefaultsKey.lastSentAt)
                    addLog(text: "busy hours: reported \(report.days.count) day(s) to the portfolio")
                    // The server re-simulates with the new busy hours; pick up the pushed tasks it now reports.
                    DayPlanPushedTasks.shared.refresh()
                case 0:
                    break   // no credentials / no network yet — the next Day Plan build simply retries
                default:
                    self.lastFailureAt = Date()
                    addLog(text: "busy hours: server returned \(statusCode) (endpoint not deployed yet?) — retrying in an hour")
                }
            }
        }
    }
}

/// The portfolio's `pushed_tasks`, keyed by to-do id. Fed by every `GET /portfolio` (the Projects
/// tab and the busy-hours reporter) so the Day Plan can flag a task that won't get done today.
final class DayPlanPushedTasks {
    static let shared = DayPlanPushedTasks()
    static let didChange = Notification.Name("DayPlanPushedTasksDidChange")

    private(set) var byTodoId: [String: PortfolioPushedTask] = [:]
    private var isRefreshing = false

    func update(from portfolio: PortfolioResponse) {
        let fresh = Dictionary(portfolio.pushedTasks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        guard fresh != byTodoId else { return }
        byTodoId = fresh
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        allApiObject.getPortfolio { [weak self] portfolio in
            DispatchQueue.main.async {
                self?.isRefreshing = false
                if let portfolio = portfolio { self?.update(from: portfolio) }
            }
        }
    }

    /// The day the simulation expects `todoId` to actually complete, nil when it fits its plan.
    func projectedDay(forTodoId todoId: String?) -> Date? {
        guard let todoId = todoId, let pushed = byTodoId[todoId] else { return nil }
        return ToDoDates.parse(pushed.projected_date)
    }

    /// Once the user moves the task the server will re-simulate; drop the entry so the hint doesn't
    /// linger on the moved task until the next fetch.
    func remove(todoId: String) {
        guard byTodoId.removeValue(forKey: todoId) != nil else { return }
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }
}
