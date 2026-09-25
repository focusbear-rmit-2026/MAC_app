import Foundation
import Combine
import EventKit

enum LocalForecastPreferences {
    static let didChange = Notification.Name("LocalForecastCapacitySettingsDidChange")
    static func load(account: String, defaults: UserDefaults = .standard) -> LocalTimeForecast.CapacitySettings {
        guard !account.isEmpty, let data = defaults.data(forKey: key(account)),
              let value = try? JSONDecoder().decode(LocalTimeForecast.CapacitySettings.self, from: data), value.isValid else { return .init() }
        return value
    }
    @discardableResult static func save(_ settings: LocalTimeForecast.CapacitySettings, account: String,
                                        currentAccount: () -> String, defaults: UserDefaults = .standard) -> Bool {
        guard !account.isEmpty, account == currentAccount(), settings.isValid,
              let data = try? JSONEncoder().encode(settings) else { return false }
        defaults.set(data, forKey: key(account))
        return true
    }
    private static func key(_ account: String) -> String { "localForecastCapacity.v1." + account }
}

/// Progress is local to a stage; network latency and calendar fetching have no reliable ETA.
struct LocalForecastLoadProgress: Equatable {
    enum Stage: Equatable { case projects, tasks, calendar, days, calculation }
    let stage: Stage
    var completed = 0
    var total: Int?
    var fraction: Double? {
        guard let total = total, total > 0 else { return nil }
        return min(1, max(0, Double(completed) / Double(total)))
    }
}

/// Owns an authenticated, complete portfolio snapshot. Calculations remain local and read-only.
final class LocalForecastStore: ObservableObject {
    typealias ProjectReader = (Int, String, @escaping (ProjectsPage?) -> Void) -> Void
    typealias TaskReader = (Int, String, @escaping (AllApi.ForecastTasksPage?) -> Void) -> Void
    /// Task id, the new `/10` wire outcome, the account that asked for the write, and whether it stuck.
    typealias OutcomeWriter = (String, Int, String, @escaping (Bool) -> Void) -> Void
    @Published private(set) var result: LocalTimeForecast.Result? {
        // Views that cache a derived calculation (the task editor's next-slot suggestion) watch
        // this token instead of re-deriving on every SwiftUI body pass.
        didSet { snapshotToken = UUID() }
    }
    @Published private(set) var snapshotToken = UUID()
    @Published private(set) var isLoading = false
    @Published private(set) var loadProgress: LocalForecastLoadProgress?
    @Published private(set) var error: String?
    @Published private(set) var calendarAvailable = false
    @Published var horizonDays = 90
    @Published var selectedDay: Date?
    @Published var showsWorkPlan = false
    /// "Don't change tasks scheduled for today or tomorrow" — the reschedule sheet's own checkbox.
    ///
    /// The two settled days were a hardcoded rule with no way out of it (report 2026-09-21_07-45-21).
    /// It is a planning rule rather than a filter on the finished list, so turning it off has to
    /// reach the days the forecast is calculated from: the planner may then put work on today and
    /// tomorrow, which is the whole point of asking for them back.
    ///
    /// Remembered between openings, like the other list preferences on this tab, and defaulting to
    /// on so the behaviour only changes for a user who asks it to.
    @Published var locksPlannedDays: Bool {
        didSet {
            guard locksPlannedDays != oldValue else { return }
            defaults.set(locksPlannedDays, forKey: LocalForecastStore.locksPlannedDaysKey)
            relockPlannedDays()
        }
    }
    static let locksPlannedDaysKey = "kUserdefaultsForecastLocksPlannedDays"
    /// The day the sheet was opened to fix, when it was opened from one day's "Fix" rather than from
    /// "re-prioritise everything". `nil` is the general case and changes nothing. See `ForecastDayFocus`.
    @Published private(set) var dayFocus: ForecastDayFocus.Target?
    @Published private(set) var capacitySettings = LocalTimeForecast.CapacitySettings()
    @Published private(set) var workPlan: LocalTimeForecast.WorkPlan?
    @Published private(set) var isApplying = false
    @Published private(set) var applyMessage: String?
    /// Dates the user typed over a proposal, keyed by the change's id. An instruction rather than a
    /// proposal, so `proposedPlan(from:)` puts them back after every recalculation.
    @Published private(set) var manualDates: [String: Date] = [:]
    private(set) var projects: [Project] = []
    private(set) var tasks: [ToDoTask] = []
    private(set) var projectCompletions: [String: ProjectListCompletion] = [:]

    /// The first day that still has room for new work — the sensible default due date when creating a
    /// task, instead of a flat "tomorrow" that ignores an already-full day (report 2026-09-14_19-50-05).
    /// nil until a forecast exists, and the caller falls back to tomorrow.
    var nextFreeDay: Date? {
        result.flatMap { LocalTimeForecast.firstDayWithRoom(forMinutes: 0, in: $0) }
    }

    /// Unfinished tasks per project, counted from the rows the forecast actually downloaded.
    ///
    /// The server's `uncompleted_task_count` only excludes the default COMPLETED status, so a task
    /// finished in a custom "done" column still counts as outstanding: a project with 5 to do and 11
    /// done in a custom column advertised "16 to do" (report 2026-09-13_21-20-29, follow-up "nope
    /// still not working. Look at the UX project"). These rows have already been filtered with each
    /// project's own `should_complete_task` columns, so they are the honest number.
    var unfinishedCountsByProject: [String: Int] {
        tasks.reduce(into: [:]) { counts, task in
            for tag in task.tagList { counts[tag.id, default: 0] += 1 }
            if let owner = task.project_id, !(task.tagList.contains { $0.id == owner }) {
                counts[owner, default: 0] += 1
            }
        }
    }
    private(set) var blocksByDay: [Date: [ScheduleBlock]] = [:]
    private(set) var dayInputs: [LocalTimeForecast.DayInput] = []
    private(set) var projectInputs: [LocalTimeForecast.ProjectInput] = []
    private(set) var taskInputs: [LocalTimeForecast.TaskInput] = []
    typealias RefreshScheduler = (TimeInterval, @escaping () -> Void) -> () -> Void
    static let automaticRefreshInterval: TimeInterval = 15 * 60
    private var cancelScheduledRefresh: (() -> Void)?
    private var scheduledRefreshID = UUID()
    private var lastRefreshAttempt: Date?
    private(set) var isSnapshotDirty = false
    /// Set when an edit makes the existing snapshot wrong rather than merely out of date, so the
    /// fifteen-minute reuse window is skipped instead of served.
    private(set) var requiresFreshSnapshot = false
    private let now: () -> Date
    private let scheduleRefresh: RefreshScheduler
    private var generation = 0
    private var accountID = ""
    private var observers: [NSObjectProtocol] = []
    private let currentAccount: () -> String
    private let calendarPermission: () -> Bool
    private let readProjects: ProjectReader
    private let readTasks: TaskReader
    private let writeOutcome: OutcomeWriter
    private let diagnostic: (String) -> Void
    /// Where the store's own preferences live. Injected because the app-hosted test runs under the
    /// app's bundle id, so `.standard` is the developer's real preferences.
    private let defaults: UserDefaults
    /// The work already placed on the Day Plan, which the forecast has to fit around.
    private let readPlanned: () -> [(date: Date, task: DayPlanTask)]
    var onApplied: (() -> Void)?
    var calendar: Calendar { Calendar.current }
    var settingsAccount: String { currentAccount() }
    /// Consumers must not combine an old calculation with a newly loading catalogue or another account.
    var hasCurrentSnapshot: Bool { result != nil && !isLoading && !accountID.isEmpty && currentAccount() == accountID }

    init(currentAccount: @escaping () -> String = { appdelegate?.user?.userId ?? "" },
         calendarPermission: @escaping () -> Bool = { CalendarManager.shared.access == .authorized },
         readProjects: @escaping ProjectReader = { page, account, completion in
             allApiObject.getProjectsPage(page: page, take: 50, search: nil, status: .active,
                                          expectedAccountID: account, completionHandler: completion)
         },
         readTasks: @escaping TaskReader = { page, account, completion in
             allApiObject.getForecastTasksPage(page: page, expectedAccountID: account, completion: completion)
         }, writeOutcome: @escaping OutcomeWriter = LocalForecastStore.writeTaskOutcome,
         diagnostic: @escaping (String) -> Void = { addLog(text: $0) },
         now: @escaping () -> Date = Date.init,
         defaults: UserDefaults = .standard,
         readPlanned: @escaping () -> [(date: Date, task: DayPlanTask)] = { DayPlanTaskStore.shared.forecastSnapshot() },
         scheduleRefresh: @escaping RefreshScheduler = { delay, action in
             let work = DispatchWorkItem(block: action)
             DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
             return { work.cancel() }
         }) {
        self.currentAccount = currentAccount; self.calendarPermission = calendarPermission
        self.readProjects = readProjects; self.readTasks = readTasks; self.writeOutcome = writeOutcome
        self.diagnostic = diagnostic
        self.now = now; self.scheduleRefresh = scheduleRefresh
        self.defaults = defaults; self.readPlanned = readPlanned
        capacitySettings = LocalForecastPreferences.load(account: currentAccount())
        // Absent means "never answered", which is the default answer rather than `false`.
        locksPlannedDays = defaults.object(forKey: LocalForecastStore.locksPlannedDaysKey) as? Bool ?? true
        calendarAvailable = calendarPermission()
        for name in [DayPlanTaskStore.forecastSnapshotDidChange, Notification.Name.EKEventStoreChanged, CalendarManager.dismissedEventsDidChange, LocalForecastPreferences.didChange] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                guard let self = self else { return }
                if notification.name == LocalForecastPreferences.didChange {
                    // Explicit capacity edits must use their new settings immediately.
                    if self.lastRefreshAttempt != nil || self.isLoading { self.refresh() }
                } else { self.markDirty() }
            })
        }
        observers.append(TodoCompletionBus.observe { [weak self] _ in self?.invalidateForCompletionChange() })
    }
    deinit {
        cancelScheduledRefresh?()
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    /// Display consumers reuse the account's snapshot (or failure) for fifteen minutes. A
    /// manual refresh, capacity/horizon edit, and work-plan preflight use refresh() instead.
    func refreshIfNeeded() {
        guard !isApplying else { return }
        guard currentAccount() == accountID, lastRefreshAttempt != nil else { refresh(); return }
        guard !isLoading else { return } // Never restart an in-flight automatic calculation.
        guard !requiresFreshSnapshot else { refresh(); return }
        if let last = lastRefreshAttempt, now().timeIntervalSince(last) < Self.automaticRefreshInterval {
            scheduleAutomaticRefresh()
        } else { refresh() }
    }

    /// Task/calendar/project edits coalesce into the next scheduled calculation. The existing
    /// snapshot stays visible, and explicit work-plan approval still performs a fresh read.
    func markDirty() {
        isSnapshotDirty = true
        guard lastRefreshAttempt != nil || isLoading || result != nil else { return }
        refreshIfNeeded()
    }

    /// Completing a task is the one edit that changes the answer the forecast exists to give: how
    /// much work is left. Reusing the snapshot for the rest of its fifteen minutes showed the user a
    /// project still at risk after they had just finished it (report 2026-09-15_17-41-45), so a
    /// completion expires the snapshot outright rather than coalescing like other edits. The
    /// recalculation still happens once, when a consumer next appears or the in-flight one lands.
    func invalidateForCompletionChange() {
        requiresFreshSnapshot = true
        markDirty()
    }

    private func cancelAutomaticRefresh() {
        scheduledRefreshID = UUID()
        cancelScheduledRefresh?()
        cancelScheduledRefresh = nil
    }

    private func scheduleAutomaticRefresh() {
        guard cancelScheduledRefresh == nil, let last = lastRefreshAttempt,
              !accountID.isEmpty, !isLoading, !isApplying else { return }
        // A completion that landed while the previous calculation was in flight is not worth
        // waiting a further fifteen minutes for; `refresh` clears the flag, so this cannot loop.
        guard !requiresFreshSnapshot else { refresh(); return }
        let scheduledID = UUID()
        scheduledRefreshID = scheduledID
        // Count failed attempts too, so an unavailable server cannot cause a retry storm.
        let delay = max(0, last.addingTimeInterval(Self.automaticRefreshInterval).timeIntervalSince(now()))
        cancelScheduledRefresh = scheduleRefresh(delay) { [weak self] in
            guard let self = self, self.scheduledRefreshID == scheduledID else { return }
            self.cancelScheduledRefresh = nil
            self.refreshIfNeeded()
        }
    }

    private func clearSnapshot() {
        result = nil; projects = []; tasks = []; blocksByDay = [:]
        projectCompletions = [:]
        dayInputs = []; taskInputs = []; projectInputs = []; workPlan = nil
        showsWorkPlan = false; selectedDay = nil
        lastRefreshAttempt = nil; isSnapshotDirty = false; requiresFreshSnapshot = false
    }

    func saveCapacitySettings(_ settings: LocalTimeForecast.CapacitySettings, expectedAccount: String) -> Bool {
        guard !isApplying, LocalForecastPreferences.save(settings, account: expectedAccount, currentAccount: currentAccount) else { return false }
        capacitySettings = settings
        workPlan = nil; showsWorkPlan = false
        // This observer performs the single forced refresh when the forecast was already used.
        NotificationCenter.default.post(name: LocalForecastPreferences.didChange, object: nil)
        if lastRefreshAttempt == nil { refresh() }
        return true
    }

    func refresh(completion: ((Bool) -> Void)? = nil) {
        guard !isApplying else { completion?(false); return }
        cancelAutomaticRefresh()
        generation += 1
        loadProgress = nil
        let token = generation
        // Calendar permission is independent of whether the project/task requests succeed.
        calendarAvailable = calendarPermission()
        let account = currentAccount()
        capacitySettings = LocalForecastPreferences.load(account: account)
        if accountID != account { clearSnapshot() }
        accountID = account
        guard !account.isEmpty else {
            clearSnapshot(); isLoading = false; error = ForecastText[.loadFailed]; completion?(false); return
        }
        lastRefreshAttempt = now()
        isSnapshotDirty = false
        requiresFreshSnapshot = false
        isLoading = true
        loadProgress = .init(stage: .projects)
        error = nil
        loadProjects(page: 1, catalogue: LocalForecastProjectCatalogue(), expectedCount: nil, token: token) { [weak self] projects in
            guard let self = self, self.isCurrent(token, account: account) else { completion?(false); return }
            guard let projects = projects else { self.failed(completion); return }
            self.loadProgress = .init(stage: .tasks)
            let completing = LocalForecastTaskCatalogue.completingStatusIds(in: projects)
            self.loadTasks(page: 1, catalogue: LocalForecastTaskCatalogue(completingStatusIds: completing),
                           token: token) { [weak self] tasks in
                guard let self = self, self.isCurrent(token, account: account) else { completion?(false); return }
                guard let tasks = tasks else { self.failed(completion); return }
                self.projects = projects
                self.tasks = tasks
                self.buildDays(token: token, account: account, completion: completion)
            }
        }
    }

    private func isCurrent(_ token: Int, account: String) -> Bool {
        token == generation && currentAccount() == account
    }
    private func failed(_ completion: ((Bool) -> Void)?) {
        isLoading = false; loadProgress = nil; result = nil; error = error ?? ForecastText[.loadFailed]
        scheduleAutomaticRefresh()
        completion?(false)
    }
    private func loadProjects(page: Int, catalogue: LocalForecastProjectCatalogue, expectedCount: Int?, token: Int, completion: @escaping ([Project]?) -> Void) {
        let account = accountID
        readProjects(page, account) { [weak self] response in
            DispatchQueue.main.async {
                guard let self = self, self.isCurrent(token, account: account) else { completion(nil); return }
                if let response = response {
                    self.diagnostic("forecast projects: requestedPage=\(page) responsePage=\(response.meta?.page ?? -1) reportedCount=\(response.meta?.itemCount ?? -1) previousCount=\(expectedCount ?? -1) hasNext=\(String(describing: response.meta?.hasNextPage)) rows=\(response.items.count) nativeRows=\(response.items.filter { !$0.isSynced }.count) dataRows=\(response.data?.count ?? -1) aliasRows=\(response.projects?.count ?? -1)")
                } else { self.diagnostic("forecast projects: requestedPage=\(page) missingResponse=true") }
                guard let response = response, let meta = response.meta,
                      let hasNext = meta.hasNextPage, let count = meta.itemCount,
                      meta.page == page, expectedCount == nil || expectedCount == count else { completion(nil); return }
                var merged = catalogue
                guard count >= 0, merged.append(response.items) else { completion(nil); return }
                self.loadProgress = .init(stage: .projects, completed: merged.nativeCount, total: count)
                let added = merged.identityCount - catalogue.identityCount
                self.diagnostic("forecast projects: requestedPage=\(page) uniqueRows=\(merged.projects.count) nativeUnique=\(merged.nativeCount) duplicates=\(response.items.count - added) expected=\(count)")
                if hasNext {
                    guard page < 100, added > 0 else { completion(nil); return }
                    self.loadProjects(page: page + 1, catalogue: merged, expectedCount: count, token: token, completion: completion)
                } else {
                    // Synced extras can reuse a native project's ID after the tag migration.
                    // Count the native rows separately, while keeping one forecast project and
                    // its synced-task mapping. A genuinely missing native row still fails.
                    guard merged.nativeCount == count else { completion(nil); return }
                    self.projectCompletions = merged.projectCompletions
                    completion(merged.projects)
                }
            }
        }
    }
    private func loadTasks(page: Int, catalogue: LocalForecastTaskCatalogue, token: Int, completion: @escaping ([ToDoTask]?) -> Void) {
        let account = accountID
        readTasks(page, account) { [weak self] response in
            DispatchQueue.main.async {
                guard let self = self, self.isCurrent(token, account: account) else { completion(nil); return }
                guard let response = response else { completion(nil); return }
                // Once per download, not once per page — an unfiltered account is ~95 pages.
                if page == 1, response.meta.excludesCompleted != true {
                    self.diagnostic("forecast tasks: unfinishedFilterUnsupported=true — downloading every page and filtering here")
                }
                var merged = catalogue
                guard merged.append(response, page: page) else { completion(nil); return }
                self.loadProgress = .init(stage: .tasks, completed: merged.downloadedCount, total: merged.expectedCount)
                if merged.isComplete {
                    self.diagnostic("forecast tasks: pages=\(page) downloaded=\(merged.downloadedCount) planned=\(merged.tasks.count)")
                    completion(merged.tasks)
                } else {
                    guard page < 400 else { completion(nil); return }
                    self.loadTasks(page: page + 1, catalogue: merged, token: token, completion: completion)
                }
            }
        }
    }

    private func buildDays(token: Int, account: String, completion: ((Bool) -> Void)?) {
        let cal = calendar
        let now = self.now()
        let start = cal.startOfDay(for: now)
        let settings = capacitySettings
        let dates = (0..<min(366, max(7, horizonDays))).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
        guard let last = dates.last, let end = cal.date(byAdding: .day, value: 1, to: last) else { failed(completion); return }
        calendarAvailable = calendarPermission()
        // Capture routine globals on the main thread; EventKit fetching and pure calculation use
        // worker queues. No 90-day series of blocking EventKit queries runs on the UI thread.
        let segments = dates.map {
            ScheduleTab.segmentsForDate($0, includeCompleted: true, includeOptionalEvening: false)
        }
        let labels = ScheduleText.engineLabels
        let outOfOrder = SettingsManagerObject.isOutOfOrderHabitsAllowed
        let locksPlanned = locksPlannedDays
        let projectSnapshot = projects
        let remoteTasks = tasks
        // What the user has actually placed on their days. Read here, on the main thread, with the
        // other stores — the portfolio forecast used to ignore it entirely, which is why a day the
        // Day Plan called an hour over capacity looked perfectly fine to the reschedule plan
        // (report 2026-09-17_09-04-13).
        let plannedSnapshot = readPlanned()
        loadProgress = .init(stage: .calendar)
        LocalForecastCalendarReader.read(from: start, to: end, authorized: calendarAvailable,
                                         meetingLabel: ScheduleText.meetingDefaultTitle, dismissals: CalendarManager.shared.dismissalSnapshot) { [weak self] meetings in
            DispatchQueue.global(qos: .userInitiated).async {
                var inputs: [LocalTimeForecast.DayInput] = []
                var blocks: [Date: [ScheduleBlock]] = [:]
                for (index, date) in dates.enumerated() {
                    guard let dayEnd = cal.date(byAdding: .day, value: 1, to: date) else { continue }
                    let dayMeetings = meetings.filter { $0.end > date && $0.start < dayEnd }
                    let built = ScheduleBuilder.build(segments: segments[index], meetings: dayMeetings,
                        now: date, dayEnd: dayEnd, leaveBufferSeconds: 120, outOfOrderAllowed: outOfOrder,
                        meetingsFrom: date, labels: labels)
                    blocks[date] = built
                    inputs.append(.fromDayPlan(date: date, blocks: built, settings: settings, availableFrom: now,
                                               isLocked: LocalTimeForecast.isPlanLocked(date, horizonStart: start,
                                                                                        locksPlannedDays: locksPlanned,
                                                                                        calendar: cal)))
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, self.isCurrent(token, account: account), self.isLoading else { return }
                        self.loadProgress = .init(stage: .days, completed: index + 1, total: dates.count)
                    }
                }
                let projectInputs = projectSnapshot.map {
                    LocalTimeForecast.ProjectInput(id: $0.id, outcome: $0.outcome ?? 0,
                                                   dueDate: ToDoDates.parse($0.due_date),
                                                   totalTaskCount: $0.task_count,
                                                   uncompletedTaskCount: $0.uncompleted_task_count)
                }
                let taskInputs = LocalForecastSnapshot.projectTasks(remote: remoteTasks, projects: projectSnapshot,
                    planned: plannedSnapshot, today: start, calendar: cal, serverExcludedCompleted: true)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.isCurrent(token, account: account), self.isLoading else { return }
                    self.loadProgress = .init(stage: .calculation)
                }
                let result = LocalTimeForecast.calculate(days: inputs, projects: projectInputs, tasks: taskInputs, calendar: cal)
                DispatchQueue.main.async {
                    guard let self = self, self.isCurrent(token, account: account) else { completion?(false); return }
                    self.blocksByDay = blocks; self.dayInputs = inputs
                    self.projectInputs = projectInputs; self.taskInputs = taskInputs
                    self.result = result; self.isLoading = false; self.loadProgress = nil
                    self.scheduleAutomaticRefresh()
                    completion?(true)
                }
            }
        }
    }

    func projectName(_ id: String?) -> String {
        guard let id = id else { return ForecastText[.unprojected] }
        return projects.first { $0.id == id }?.name ?? ForecastText[.unprojected]
    }
    func taskName(_ id: String) -> String {
        tasks.first { $0.id == id }?.title ?? DayPlanTaskStore.shared.forecastSnapshot().first {
            ($0.task.sourceTaskId ?? $0.task.id) == id
        }?.task.title ?? id
    }
    func name(for change: LocalTimeForecast.DueDateChange) -> String {
        change.kind == .project ? projectName(change.itemID) : taskName(change.itemID)
    }
    func name(for conflict: LocalTimeForecast.PlanConflict) -> String {
        conflict.kind == .project ? projectName(conflict.itemID) : taskName(conflict.itemID)
    }
    func prepareWorkPlan() {
        guard let result = result, !isLoading else { return }
        workPlan = proposedPlan(from: result)
        applyMessage = nil; showsWorkPlan = true
    }

    /// Open the reschedule plan from a screen that has not necessarily calculated a forecast yet.
    ///
    /// The Tasks list is such a screen. Making it price the whole portfolio on every visit — 128
    /// projects, 200+ tasks, EventKit and a day-by-day build — would be a heavy cost imposed on
    /// every visit for a menu item most visits never touch, so the sheet opens immediately and the
    /// calculation it needs runs underneath it. The sheet already shows a spinner while `isLoading`,
    /// and `error` when the load fails.
    /// A **dirty** snapshot is reloaded, not reused. `markDirty` only *schedules* a recalculation
    /// when the snapshot is inside its fifteen-minute window, so a project created moments earlier
    /// was still absent from `projects` — and the row's project picker, which lists exactly that,
    /// silently offered a list without it ("I added a new project … but it wasn't there",
    /// report 2026-09-16_08-53-08). A picker that omits a project states an absence as fact; worse,
    /// the plan itself would have been computed without that project's work. Opening this sheet is
    /// the deliberate, explicit action the existing comment on `markDirty` says should perform a
    /// fresh read, so it does.
    func prepareWorkPlanLoadingIfNeeded(focusing target: ForecastDayFocus.Target? = nil) {
        guard !isApplying else { return }
        applyMessage = nil
        // Set before the sheet is shown, and cleared by whoever opens it without a day, so the
        // section can never be left over from the previous visit.
        dayFocus = target
        showsWorkPlan = true
        if hasCurrentSnapshot && !requiresFreshSnapshot && !isSnapshotDirty {
            prepareWorkPlan()
            return
        }
        refresh { [weak self] success in
            // The user may have closed the sheet while the portfolio was loading; finishing the
            // calculation is fine, re-opening the sheet behind their back is not.
            guard let self = self, self.showsWorkPlan, success else { return }
            self.prepareWorkPlan()
        }
    }
    /// The project the plan actually scheduled this row under, ready for a chip. `nil` — a task with
    /// no project, or a project row whose own name is already the row title — means no chip at all
    /// rather than an empty one.
    func projectChipName(for change: LocalTimeForecast.DueDateChange) -> String? {
        guard change.kind == .task else { return nil }
        return projectChipName(forTaskID: change.itemID)
    }
    func projectChipName(forTaskID id: String) -> String? {
        let ownerID = taskInputs.first { $0.id == id }?.projectID ?? tasks.first { $0.id == id }?.project_id
        guard let ownerID = ownerID, let raw = projects.first(where: { $0.id == ownerID })?.name else { return nil }
        let name = ToDoStrings.load().projectName(raw)
        return name.isEmpty ? nil : name
    }

    /// The outcome the plan used for this task — its own, or the forecast's default when it has
    /// none — so a row's control can never show a number the calculation did not actually apply.
    func outcome(forTaskID id: String) -> Int? {
        taskInputs.first { $0.id == id }?.outcome ?? tasks.first { $0.id == id }?.outcome
    }

    private func projectInput(forTaskID id: String) -> LocalTimeForecast.ProjectInput? {
        guard let ownerID = taskInputs.first(where: { $0.id == id })?.projectID else { return nil }
        return projectInputs.first { $0.id == ownerID }
    }

    /// The project rating this task is actually being planned under, when the project's is the
    /// stronger of the two. `nil` means the task's own slider value is the one in force. The screen
    /// shows this so an inherited rating never looks like a per-task setting being ignored.
    func inheritedOutcome(forTaskID id: String) -> Int? {
        guard let task = taskInputs.first(where: { $0.id == id }),
              let project = projectInput(forTaskID: id),
              LocalTimeForecast.inheritsProjectOutcome(task: task, project: project) else { return nil }
        return project.outcome
    }

    /// Every project this snapshot knows about, for the row's project dropdown. Sorted by name
    /// because a 128-project list is navigated by typing, and the menu that narrows as you type
    /// should narrow through a predictable order.
    var projectPickerOptions: [SearchableComboBoxField.Option] {
        projects.map { .init(id: $0.id, name: ToDoStrings.load().projectName($0.name)) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func projectID(forTaskID id: String) -> String? {
        taskInputs.first { $0.id == id }?.projectID ?? tasks.first { $0.id == id }?.project_id
    }

    /// Move a task into another project from the reschedule row.
    ///
    /// The body comes from `ProjectMerge.reassignment`, the same helper the project-merge flow uses,
    /// so `project_id`, the project **tag** and `custom_status_id` keep moving together — a stale tag
    /// would leave the list still showing the old project, and a source column id does not exist on
    /// the target's board. Reusing it also inherits its refusal of externally synced tasks.
    ///
    /// The new project's rating and end date apply immediately: the snapshot is patched and the plan
    /// recalculated here, so the row's inherited-rating note and the fixed-order section re-evaluate
    /// against the NEW project rather than keeping the old one's claim.
    func reassign(taskID: String, toProjectID projectID: String, completion: ((Bool) -> Void)? = nil) {
        guard !isApplying, !isLoading,
              let task = tasks.first(where: { $0.id == taskID }),
              let target = projects.first(where: { $0.id == projectID }),
              target.id != task.project_id else { completion?(false); return }
        let account = ForecastWriteAccount(id: accountID)
        guard account.matches(currentAccount()) else { completion?(false); return }
        let source = projects.first { $0.id == task.project_id }
        guard case .success(let body) = ProjectMerge.reassignment(of: task, from: source, to: target) else {
            applyMessage = ForecastText[.projectNotChanged]
            completion?(false); return
        }
        applyMessage = nil
        isApplying = true
        diagnostic("forecast reassign: task=\(taskID) from=\(task.project_id ?? "none") to=\(projectID)")
        allApiObject.upsertToDo(body, expectedAccountID: account.id) { [weak self] saved, code, _ in
            DispatchQueue.main.async {
                guard let self = self, account.matches(self.currentAccount()), self.accountID == account.id else {
                    completion?(false); return
                }
                self.isApplying = false
                guard (200..<300).contains(code), saved?.project_id == projectID else {
                    self.applyMessage = ForecastText[.projectNotChanged]
                    completion?(false); return
                }
                self.applyProjectLocally(projectID, toTaskID: taskID)
                completion?(true)
            }
        }
    }

    /// Patch the snapshot and recalculate, the same way an outcome edit does, so the plan re-flows
    /// around the move without a round trip and the row stops quoting the old project.
    private func applyProjectLocally(_ projectID: String, toTaskID id: String) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].project_id = projectID
        if let inputIndex = taskInputs.firstIndex(where: { $0.id == id }) {
            taskInputs[inputIndex].projectID = projectID
        }
        isSnapshotDirty = true
        let recalculated = LocalTimeForecast.calculate(days: dayInputs, projects: projectInputs,
                                                       tasks: taskInputs, calendar: calendar)
        result = recalculated
        workPlan = proposedPlan(from: recalculated)
    }

    /// This task's estimate, for the row's duration badge. `nil` when the snapshot has no estimate
    /// for it — the badge says so rather than inventing a number.
    func durationMinutes(forTaskID id: String) -> Int? {
        if let minutes = taskInputs.first(where: { $0.id == id })?.estimatedMinutes,
           minutes > 0, minutes.isFinite, minutes < Double(Int.max) {
            return Int(ceil(minutes))
        }
        guard let task = tasks.first(where: { $0.id == id }), task.durationSeconds > 0 else { return nil }
        return task.durationSeconds / 60
    }

    /// Set a task's estimate from the row's duration badge. The text is parsed by
    /// `QuickAddTaskParser.durationMinutes(fromFieldText:)` — the same parser the Day Plan's duration
    /// field uses — so `45m`, `1h30` and a bare `45` mean here exactly what they mean there. A second
    /// parser for one syntax is how `4h` once became `4`.
    func setDuration(minutes: Int, forTaskID id: String, completion: ((Bool) -> Void)? = nil) {
        guard !isApplying, !isLoading, minutes > 0, minutes <= Int.max / 60,
              let task = tasks.first(where: { $0.id == id }),
              task.durationSeconds != minutes * 60 || durationMinutes(forTaskID: id) != minutes else {
            completion?(false); return
        }
        var body = ToDoUpsertBody.make(from: task)
        body["duration"] = minutes * 60
        write(body, taskID: id, failureMessage: .durationNotSaved, completion: completion) { store in
            let dayPlan = DayPlanTaskStore.shared
            for placement in dayPlan.forecastSnapshot() where placement.task.sourceTaskId == id {
                var updated = placement.task
                updated.durationMinutes = minutes
                dayPlan.update(updated, for: placement.date)
            }
            NotificationCenter.default.post(name: DayPlanTaskStore.tasksDidChangeExternally, object: nil)
            store.patchTask(id) { task, input in
                task.duration = LenientInt(minutes * 60)
                input.estimatedMinutes = Double(minutes)
            }
        }
    }

    /// Tick a task off from the row. A finished task is no longer work to schedule, so it leaves the
    /// plan and the days it was holding are freed for the rest — the same reason `markDirty` treats
    /// completion as the one edit that invalidates a snapshot outright.
    func completeTask(_ id: String, completion: ((Bool) -> Void)? = nil) {
        guard !isApplying, !isLoading, let task = tasks.first(where: { $0.id == id }), !task.isCompleted else {
            completion?(false); return
        }
        let columns = projects.first { $0.id == task.project_id }?.customStatuses ?? []
        let finished = ToDoStatusToggle.apply(to: task, completed: true, customStatuses: columns)
        write(ToDoUpsertBody.make(from: finished), taskID: id, failureMessage: .taskNotCompleted,
              completion: completion) { store in
            store.patchTask(id) { task, input in
                task.status = finished.status
                task.custom_status_id = finished.custom_status_id
                input.completed = true
            }
        }
    }

    /// One `PUT /to-do` from a reschedule row: write, then patch the snapshot and re-propose so the
    /// list re-flows immediately instead of after a round trip. Shared by the duration and complete
    /// buttons so both report failure the same way and neither invents its own recalculation.
    private func write(_ body: [String: Any], taskID: String, failureMessage: ForecastText.Key,
                       completion: ((Bool) -> Void)?, onSaved: @escaping (LocalForecastStore) -> Void) {
        let account = ForecastWriteAccount(id: accountID)
        guard account.matches(currentAccount()) else { completion?(false); return }
        applyMessage = nil
        isApplying = true
        allApiObject.upsertToDo(body, expectedAccountID: account.id) { [weak self] _, code, _ in
            DispatchQueue.main.async {
                guard let self = self, account.matches(self.currentAccount()), self.accountID == account.id else {
                    completion?(false); return
                }
                self.isApplying = false
                guard (200..<300).contains(code) else {
                    self.applyMessage = ForecastText[failureMessage]
                    completion?(false); return
                }
                onSaved(self)
                completion?(true)
            }
        }
    }

    /// Patch one task in the snapshot and recalculate from it, the same way an outcome edit does.
    private func patchTask(_ id: String, _ edit: (inout ToDoTask, inout LocalTimeForecast.TaskInput) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }),
              let inputIndex = taskInputs.firstIndex(where: { $0.id == id }) else { return }
        edit(&tasks[index], &taskInputs[inputIndex])
        isSnapshotDirty = true
        let recalculated = LocalTimeForecast.calculate(days: dayInputs, projects: projectInputs,
                                                       tasks: taskInputs, calendar: calendar)
        result = recalculated
        workPlan = proposedPlan(from: recalculated)
    }

    /// Re-apply the lock to the snapshot already in hand and re-flow the plan from it.
    ///
    /// Nothing about the days themselves changes when the checkbox does — only whether the planner
    /// may use the first two — so this costs one recalculation rather than a fresh EventKit read and
    /// portfolio download. It is not a snapshot edit either: the data is the same data, so the
    /// fifteen-minute reuse window is left alone rather than being marked dirty.
    private func relockPlannedDays() {
        guard !dayInputs.isEmpty, let start = dayInputs.map(\.date).min(), !isApplying else { return }
        let locked = locksPlannedDays
        dayInputs = dayInputs.map { input in
            var day = input
            day.isLocked = LocalTimeForecast.isPlanLocked(day.date, horizonStart: start,
                                                          locksPlannedDays: locked, calendar: calendar)
            return day
        }
        let recalculated = LocalTimeForecast.calculate(days: dayInputs, projects: projectInputs,
                                                       tasks: taskInputs, calendar: calendar)
        result = recalculated
        // Only where there is already a plan on screen: this must not conjure one behind a sheet
        // that has not been opened.
        if workPlan != nil { workPlan = proposedPlan(from: recalculated) }
    }

    /// The plan the screen shows: the forecast's proposal with the user's own typed dates put back.
    /// Every plan is built here rather than by calling `proposeWorkPlan` directly, because the sheet
    /// recalculates after every edit and a hand-typed date must survive each one.
    private func proposedPlan(from result: LocalTimeForecast.Result) -> LocalTimeForecast.WorkPlan {
        LocalTimeForecast.proposeWorkPlan(result, calendar: calendar)
            .applyingManualDates(manualDates, calendar: calendar)
            .adoptingManualDates(manualDates, previousDate: { [weak self] kind, id in
                guard let self = self else { return nil }
                return kind == .task ? self.dueDate(forTaskID: id)
                    : self.projects.first { $0.id == id }.flatMap { ToDoDates.parse($0.due_date) }
            }, calendar: calendar)
    }

    func manualDate(forChangeID id: String) -> Date? { manualDates[id] }

    /// The id a manual date is filed under, for a row that is currently a **conflict** rather than a
    /// proposal. It is deliberately the id the change would have, so that typing a date and the plan
    /// then adopting it as a change keeps one key and one entry rather than orphaning the first.
    func changeID(for conflict: LocalTimeForecast.PlanConflict) -> String {
        "\(conflict.kind.rawValue):\(conflict.itemID)"
    }

    func projectDueDate(forProjectID id: String) -> Date? {
        projects.first { $0.id == id }.flatMap { ToDoDates.parse($0.due_date) }
    }

    /// Why the plan refused this row, with the facts the sentence needs filled in from the snapshot.
    ///
    /// The lookups live here rather than in `ForecastText` because only the store knows the task's
    /// effective rating and the owning project's end date — and both are what make the new wording
    /// checkable instead of the old "exceeds the extension allowed by this outcome".
    func conflictReason(_ conflict: LocalTimeForecast.PlanConflict) -> String {
        let owner = conflict.kind == .task ? projectInput(forTaskID: conflict.itemID) : nil
        let outcome = conflict.kind == .task
            ? taskInputs.first { $0.id == conflict.itemID }
                .map { LocalTimeForecast.effectiveOutcome(task: $0, project: owner) }
            : projectInputs.first { $0.id == conflict.itemID }?.outcome
        return ForecastText.conflict(conflict.reason, earliest: conflict.earliestCompletionDate,
                                     outcome: outcome,
                                     projectName: owner.map { projectName($0.id) },
                                     projectEnd: owner?.dueDate)
    }

    // MARK: Fixing one day

    /// The proposals that take work off the focused day. Empty when the sheet was not opened from a
    /// day's "Fix".
    var dayFocusChanges: [LocalTimeForecast.DueDateChange] {
        guard let focus = dayFocus, let plan = workPlan else { return [] }
        return ForecastDayFocus.changes(movingWorkOff: focus.day, in: plan.changes,
                                        plannedDay: { [weak self] in self?.plannedDay(forTaskID: $0) },
                                        calendar: calendar)
    }

    /// How much of the focused day's shortfall those proposals clear, measured in the **Day Plan's**
    /// own durations — the same ruler the number they were shown was measured with.
    var dayFocusRelief: ForecastDayFocus.Relief? {
        guard let focus = dayFocus else { return nil }
        let offered = Set(dayFocusChanges.map(\.itemID))
        let pinned = DayPlanTaskStore.shared.tasks(for: focus.day)
            .filter { !$0.done }
            .compactMap { task -> (id: String, minutes: Double)? in
                let id = task.sourceTaskId ?? task.id
                guard !offered.contains(id), isPinnedByRating(taskID: id) else { return nil }
                return (id: id, minutes: Double(task.durationMinutes))
            }
        return ForecastDayFocus.relief(freeing: dayFocusChanges, target: focus,
                                       minutes: { [weak self] in self?.plannedMinutes(forTaskID: $0) ?? 0 },
                                       immovable: pinned)
    }

    /// A task the plan may not re-date because the user rated it "hard deadline — can't shift".
    /// "It shouldn't move hard deadline tasks from their current position in the day plan"
    /// (report 2026-09-16_09-40-20), so these stay put and the sheet says so instead of hiding them.
    private func isPinnedByRating(taskID: String) -> Bool {
        guard let task = taskInputs.first(where: { $0.id == taskID }) else { return false }
        let owner = task.projectID.flatMap { id in projectInputs.first { $0.id == id } }
        return !LocalTimeForecast.allowsPostponement(
            outcome: LocalTimeForecast.effectiveOutcome(task: task, project: owner))
    }

    /// The day this task currently sits on in the Day Plan, if any.
    private func plannedDay(forTaskID id: String) -> Date? {
        DayPlanTaskStore.shared.plannedCopy(ofSourceTask: id)?.day
    }

    /// Read the placed duration, matching the estimate used for this task in the forecast.
    private func plannedMinutes(forTaskID id: String) -> Double {
        Double(DayPlanTaskStore.shared.plannedCopy(ofSourceTask: id)?.task.durationMinutes ?? 0)
    }

    /// Type a date over a proposal. Nothing is written yet — it is still a proposal the user reviews
    /// and applies, it is simply *their* date rather than the forecast's.
    func setManualDate(_ date: Date?, forChangeID id: String) {
        guard !isApplying, !isLoading else { return }
        if let date = date {
            manualDates[id] = calendar.startOfDay(for: date)
        } else {
            manualDates.removeValue(forKey: id)
        }
        applyMessage = nil
        if let result = result { workPlan = proposedPlan(from: result) }
    }

    /// Unfinished to-dos whose due date has already passed. Counted from the rows the forecast
    /// downloaded, through the same `ToDoDates.dueState` the list's own red chips use, so the banner
    /// and the chips can never disagree about what "overdue" means.
    var overdueCount: Int {
        tasks.filter { ToDoDates.dueState($0.due_date, isCompleted: $0.isCompleted, now: now()) == .overdue }.count
    }

    /// How far past its capacity the worst of the **next few days** is, in minutes; 0 when they all fit.
    ///
    /// Bounded to `ReprioritiseSuggestion.horizonDays`, and the worst single day inside it. It used to
    /// scan the forecast's whole ninety-day horizon while the banner rendered the result as "Today is
    /// …", so a day weeks away was reported as today's problem ("it says 4h over", report
    /// 2026-09-16_22-22-50). The Day Plan's own header was right at the same moment, because it only
    /// ever describes the day it is showing.
    ///
    /// Reads days already in the cached snapshot, so it costs nothing on a render and never triggers
    /// a re-plan. With no snapshot there is no number and therefore no banner, which is the honest
    /// answer rather than a guess.
    var worstDayOvercommitMinutes: Double {
        guard let result = result else { return 0 }
        let today = calendar.startOfDay(for: now())
        guard let end = calendar.date(byAdding: .day, value: ReprioritiseSuggestion.horizonDays, to: today) else { return 0 }
        return result.days
            .filter { $0.date >= today && $0.date < end }
            .compactMap { LocalTimeForecast.dayLoad(on: $0.date, forecast: result, calendar: calendar) }
            .map(\.overcommittedMinutes).max() ?? 0
    }

    /// Whether to offer the reschedule plan right now, and why. `nil` says nothing.
    var reprioritiseSuggestion: ReprioritiseSuggestion.Reason? {
        ReprioritiseSuggestion.reason(overdueCount: overdueCount,
                                      worstDayOvercommitMinutes: worstDayOvercommitMinutes,
                                      dismissedAt: ReprioritiseSuggestionDismissal.dismissedAt(account: accountID),
                                      now: now(), calendar: calendar)
    }

    func dismissReprioritiseSuggestion() {
        ReprioritiseSuggestionDismissal.dismiss(account: accountID, now: now())
        objectWillChange.send()
    }

    /// The project's rating when it is actually overriding at least one of these tasks' own, so a
    /// group heading can state the fact once instead of every row repeating it.
    func inheritedOutcome(inProject id: String, taskIDs: [String]) -> Int? {
        taskIDs.compactMap { inheritedOutcome(forTaskID: $0) }.max()
    }

    /// The projects whose own rating has fixed every task in them. Dates are settled for these, so
    /// the screen offers their work order instead (`moveTask`).
    var fixedProjectOrders: [LocalTimeForecast.FixedProjectOrder] {
        result.map { LocalTimeForecast.fixedProjectOrders(in: $0, calendar: calendar) } ?? []
    }

    func dueDate(forTaskID id: String) -> Date? {
        tasks.first { $0.id == id }.flatMap { ToDoDates.parse($0.due_date) }
    }

    /// The due dates the reorder control permutes, in the order shown.
    func datedTasks(_ ids: [String]) -> [LocalTimeForecast.DatedTask] {
        ids.map { .init(id: $0, dueDate: dueDate(forTaskID: $0)) }
    }

    /// Whether `moveTask` would do anything, so the button can be disabled rather than silently inert.
    func canMoveTask(_ id: String, within ids: [String], earlier: Bool) -> Bool {
        !isApplying && !isLoading && LocalTimeForecast.reorder(datedTasks(ids), moving: id, earlier: earlier) != nil
    }

    /// Move a task one place earlier or later among its project's fixed-date tasks by swapping its
    /// due date with its neighbour's. Both writes go through the same guarded due-date path the plan
    /// uses, and the snapshot is reloaded afterwards so the order shown is the order the server holds.
    func moveTask(_ id: String, within ids: [String], earlier: Bool, completion: ((Bool) -> Void)? = nil) {
        guard !isApplying, !isLoading,
              let swap = LocalTimeForecast.reorder(datedTasks(ids), moving: id, earlier: earlier) else {
            completion?(false); return
        }
        let account = ForecastWriteAccount(id: accountID)
        guard account.matches(currentAccount()) else { completion?(false); return }
        applyMessage = nil
        isApplying = true
        diagnostic("forecast reorder: task=\(id) earlier=\(earlier) swaps=\(swap.map { $0.id }.joined(separator: ","))")
        writeSwap(swap, index: 0, reviewedAccount: account, completion: completion)
    }

    private func writeSwap(_ swap: [LocalTimeForecast.DatedTask], index: Int,
                           reviewedAccount: ForecastWriteAccount, completion: ((Bool) -> Void)?) {
        guard index < swap.count else {
            isApplying = false
            requiresFreshSnapshot = true
            refresh()
            completion?(true)
            return
        }
        writeTaskDueDate(swap[index], reviewedAccount: reviewedAccount) { [weak self] saved in
            guard let self = self, reviewedAccount.matches(self.currentAccount()) else { completion?(false); return }
            guard saved else {
                self.isApplying = false
                // A half-applied swap leaves two tasks on one date; reloading is what makes the
                // screen agree with the server again rather than showing an order nobody stored.
                self.applyMessage = ForecastText[.reorderNotSaved]
                self.requiresFreshSnapshot = true
                self.refresh()
                completion?(false)
                return
            }
            self.writeSwap(swap, index: index + 1, reviewedAccount: reviewedAccount, completion: completion)
        }
    }

    /// One guarded task due-date write: re-read the row, refuse if it moved under us, then PUT the
    /// date with the identity fields the DTO insists on. Shared with the plan's apply loop through
    /// `ForecastRowGuard` so both refuse for the same reasons.
    private func writeTaskDueDate(_ target: LocalTimeForecast.DatedTask, reviewedAccount: ForecastWriteAccount,
                                  completion: @escaping (Bool) -> Void) {
        guard let date = target.dueDate else { completion(false); return }
        let dateString = ToDoDates.ymd(date)
        let calendar = self.calendar
        allApiObject.getForecastTask(id: target.id) { [weak self] latest in
            DispatchQueue.main.async {
                guard let self = self, reviewedAccount.matches(self.currentAccount()) else { completion(false); return }
                let previous = latest.flatMap { row in self.tasks.first { $0.id == row.id } }
                if let refusal = ForecastRowGuard.refusal(latest: latest, previous: previous) {
                    self.diagnostic("forecast reorder: refused task=\(target.id) reason=\(refusal.rawValue)")
                    completion(false); return
                }
                guard let latest = latest, let quadrant = latest.eisenhower_quadrant else { completion(false); return }
                let body: [String: Any] = ["id": latest.id, "title": latest.title,
                                           "eisenhower_quadrant": quadrant, "due_date": dateString]
                allApiObject.upsertToDo(body, expectedAccountID: reviewedAccount.id) { saved, code, _ in
                    let stuck = (200..<300).contains(code)
                        && saved.flatMap { ToDoDates.parse($0.due_date) }.map { calendar.isDate($0, inSameDayAs: date) } == true
                    DispatchQueue.main.async { completion(stuck) }
                }
            }
        }
    }

    /// A row-level deadline-flexibility edit from the reschedule screen. The value is written to the
    /// task and applied to this snapshot at once, then the plan is proposed again from it: pinning a
    /// task to a fixed date takes it off the list — `allowsPostponement` refuses to move it — and
    /// frees the days it was going to occupy, so the rest of the list re-flows around it.
    func setTaskOutcome(_ wireValue: Int, forTaskID id: String, completion: ((Bool) -> Void)? = nil) {
        guard !isApplying, !isLoading, !dayInputs.isEmpty,
              let existing = tasks.first(where: { $0.id == id }) else { completion?(false); return }
        let account = ForecastWriteAccount(id: accountID)
        guard account.matches(currentAccount()) else { completion?(false); return }
        let clamped = ToDoScoring.clampLevel(wireValue)
        let previous = existing.outcome
        guard previous != clamped else { completion?(true); return }
        applyMessage = nil
        diagnostic("forecast outcome: task=\(id) from=\(previous.map(String.init) ?? "none") to=\(clamped)")
        applyOutcomeLocally(clamped, toTaskID: id)
        writeOutcome(id, clamped, account.id) { [weak self] saved in
            DispatchQueue.main.async {
                guard let self = self, account.matches(self.currentAccount()),
                      self.accountID == account.id else { completion?(false); return }
                if !saved {
                    self.applyOutcomeLocally(previous, toTaskID: id)
                    self.applyMessage = ForecastText[.outcomeNotSaved]
                }
                completion?(saved)
            }
        }
    }

    /// Patch this snapshot in place and recalculate. The same inputs and the same calculation a
    /// refresh performs — only the catalogue download is skipped — so the list re-flows immediately
    /// instead of after a round trip that would leave the sheet showing a stale proposal.
    private func applyOutcomeLocally(_ outcome: Int?, toTaskID id: String) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].outcome = outcome
        if let inputIndex = taskInputs.firstIndex(where: { $0.id == id }) {
            taskInputs[inputIndex].outcome = outcome ?? LocalTimeForecast.TaskInput.unratedOutcome
        }
        // The server row has moved on, so the next automatic calculation should re-read it; the
        // snapshot in hand is already consistent, so nothing is forced now.
        isSnapshotDirty = true
        let recalculated = LocalTimeForecast.calculate(days: dayInputs, projects: projectInputs,
                                                       tasks: taskInputs, calendar: calendar)
        result = recalculated
        workPlan = proposedPlan(from: recalculated)
    }

    /// The default outcome write: re-read the row first, so the identity fields the DTO insists on
    /// cannot overwrite a title edited elsewhere, then PUT the outcome alongside them. Same shape as
    /// the due-date writes this screen already performs.
    static func writeTaskOutcome(id: String, outcome: Int, expectedAccountID: String,
                                 completion: @escaping (Bool) -> Void) {
        allApiObject.getForecastTask(id: id) { latest in
            DispatchQueue.main.async {
                guard let latest = latest, latest.id == id, let quadrant = latest.eisenhower_quadrant else {
                    completion(false); return
                }
                let body: [String: Any] = ["id": latest.id, "title": latest.title,
                                           "eisenhower_quadrant": quadrant, "outcome": outcome]
                allApiObject.upsertToDo(body, expectedAccountID: expectedAccountID) { saved, code, _ in
                    completion((200..<300).contains(code) && saved?.outcome == outcome)
                }
            }
        }
    }

    func canApply(_ change: LocalTimeForecast.DueDateChange) -> Bool {
        if change.kind == .task { return tasks.contains { $0.id == change.itemID } }
        guard let project = projects.first(where: { $0.id == change.itemID }), !project.isSynced else { return false }
        if project.owner_id == accountID { return true }
        let role = ProjectPermissions.viewerRole(in: project, userId: accountID)
        return ProjectPermissions.canViewSettings(role)
    }
    /// Explicitly selected changes only. Reload and compare the source snapshot before any write;
    /// each write sends only the due date plus the mandatory to-do identity fields.
    func applySelected(_ ids: Set<String>) {
        guard !isApplying, !isLoading, calendarAvailable, let plan = workPlan else { return }
        let reviewedAccount = ForecastWriteAccount(id: accountID)
        guard reviewedAccount.matches(appdelegate?.user?.userId) else { refresh(); return }
        let selected = plan.changes.filter { ids.contains($0.id) && canApply($0) }
        guard !selected.isEmpty else { return }
        let oldTasks = tasks, oldProjects = projects
        let oldInputs = taskInputs
        applyMessage = nil
        refresh { [weak self] success in
            guard let self = self else { return }
            guard reviewedAccount.matches(appdelegate?.user?.userId), self.accountID == reviewedAccount.id else {
                // Do not replace a newer account's work plan from this older review callback.
                if self.accountID == reviewedAccount.id { self.refresh() }
                return
            }
            guard success, self.calendarAvailable, CalendarManager.shared.access == .authorized,
                  self.taskInputs == oldInputs,
                  self.tasks == oldTasks, self.projects == oldProjects,
                  let current = self.result,
                  self.proposedPlan(from: current).changes.map({ $0.id + ToDoDates.ymd($0.proposedDate) }) == plan.changes.map({ $0.id + ToDoDates.ymd($0.proposedDate) }) else {
                self.applyMessage = ForecastText[.planChanged]
                if let result = self.result { self.workPlan = self.proposedPlan(from: result) }
                return
            }
            self.isApplying = true
            self.apply(selected, index: 0, reviewedAccount: reviewedAccount)
        }
    }
    private func apply(_ changes: [LocalTimeForecast.DueDateChange], index: Int, reviewedAccount: ForecastWriteAccount) {
        guard reviewedAccount.matches(appdelegate?.user?.userId), calendarAvailable, CalendarManager.shared.access == .authorized else { finishApply(index, success: false, reviewedAccount: reviewedAccount); return }
        guard index < changes.count else { finishApply(index, success: true, reviewedAccount: reviewedAccount); return }
        let change = changes[index]
        let dateString = ToDoDates.ymd(change.proposedDate)
        if change.kind == .project {
            allApiObject.getProject(id: change.itemID) { [weak self] latest in
                DispatchQueue.main.async {
                    guard let self = self, let latest = latest,
                          reviewedAccount.matches(appdelegate?.user?.userId), CalendarManager.shared.access == .authorized,
                          let previous = self.projects.first(where: { $0.id == latest.id }),
                          latest.updated_at == previous.updated_at, latest.due_date == previous.due_date,
                          ProjectPermissions.canViewSettings(ProjectPermissions.viewerRole(in: latest, userId: reviewedAccount.id)) else {
                        self?.finishApply(index, success: false, reviewedAccount: reviewedAccount); return
                    }
                    let calendar = self.calendar
                    self.writeDueDate(changes, index: index, reviewedAccount: reviewedAccount) { expectedAccountID, completed in
                        allApiObject.updateProject(id: latest.id, body: ["due_date": dateString], expectedAccountID: expectedAccountID) { saved, _ in
                            completed(saved.flatMap { ToDoDates.parse($0.due_date) }.map { calendar.isDate($0, inSameDayAs: change.proposedDate) } == true)
                        }
                    }
                }
            }
        } else {
            allApiObject.getForecastTask(id: change.itemID) { [weak self] latest in
                DispatchQueue.main.async {
                    guard let self = self,
                          reviewedAccount.matches(appdelegate?.user?.userId), CalendarManager.shared.access == .authorized else {
                        self?.finishApply(index, success: false, reviewedAccount: reviewedAccount); return
                    }
                    let previous = latest.flatMap { row in self.tasks.first { $0.id == row.id } }
                    if let refusal = ForecastRowGuard.refusal(latest: latest, previous: previous) {
                        self.diagnostic("forecast apply: refused task=\(change.itemID) reason=\(refusal.rawValue)")
                        self.finishApply(index, success: false, reviewedAccount: reviewedAccount); return
                    }
                    guard let latest = latest, let quadrant = latest.eisenhower_quadrant else {
                        self.finishApply(index, success: false, reviewedAccount: reviewedAccount); return
                    }
                    let body: [String: Any] = ["id": latest.id, "title": latest.title,
                                               "eisenhower_quadrant": quadrant, "due_date": dateString]
                    let calendar = self.calendar
                    self.writeDueDate(changes, index: index, reviewedAccount: reviewedAccount) { expectedAccountID, completed in
                        allApiObject.upsertToDo(body, expectedAccountID: expectedAccountID) { saved, code, _ in
                            completed((200..<300).contains(code) && saved.flatMap { ToDoDates.parse($0.due_date) }.map { calendar.isDate($0, inSameDayAs: change.proposedDate) } == true)
                        }
                    }
                }
            }
        }
    }
    private func writeDueDate(_ changes: [LocalTimeForecast.DueDateChange], index: Int,
                              reviewedAccount: ForecastWriteAccount,
                              writer: (String, @escaping (Bool) -> Void) -> Void) {
        reviewedAccount.perform(currentAccount: { appdelegate?.user?.userId }, writer: writer) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard reviewedAccount.matches(appdelegate?.user?.userId), success else {
                    self.finishApply(index, success: false, reviewedAccount: reviewedAccount); return
                }
                self.repositionDayPlan(for: changes[index])
                self.apply(changes, index: index + 1, reviewedAccount: reviewedAccount)
            }
        }
    }

    /// Put the task on the day the plan says it is actually done, now that the date has been written.
    ///
    /// Done per change, immediately after its own write succeeds, rather than in one sweep at the end:
    /// a partially applied plan must leave the Day Plan agreeing with the dates that actually landed,
    /// not with the dates that were proposed.
    ///
    /// Why this exists at all: the sheet writes due dates, and for a task the user has dragged onto a
    /// day that changes nothing about where it sits. Monday stayed exactly as over-committed after
    /// applying as before ("It still didn't reschedule Monday for me", report 2026-09-17_09-04-13,
    /// follow-up). `DayPlanRepositioning` holds the rules about which placements may move.
    private func repositionDayPlan(for change: LocalTimeForecast.DueDateChange) {
        guard change.kind == .task else { return }
        let store = DayPlanTaskStore.shared
        guard let placement = store.plannedCopy(ofSourceTask: change.itemID) else { return }
        let lockedDays = result?.days.filter(\.isLocked).map(\.date) ?? []
        guard let move = DayPlanRepositioning.move(taskID: placement.task.id, plannedOn: placement.day,
                                                   proposedDate: change.proposedDate,
                                                   today: calendar.startOfDay(for: now()),
                                                   lockedDays: lockedDays, calendar: calendar),
              store.move(taskID: move.taskID, from: move.from, to: move.to) else { return }
        diagnostic("forecast apply: day plan moved task=\(change.itemID) \(ToDoDates.ymd(move.from)) -> \(ToDoDates.ymd(move.to))")
    }
    private func finishApply(_ count: Int, success: Bool, reviewedAccount: ForecastWriteAccount) {
        isApplying = false
        guard reviewedAccount.matches(appdelegate?.user?.userId) else {
            // Discard old-account progress without notifying consumers as though their data changed.
            applyMessage = ForecastText[.planChanged]
            workPlan = nil
            refresh()
            return
        }
        applyMessage = ForecastText.format(success ? .planSaved : .planPartiallySaved, ["<COUNT>": String(count)])
        // The typed dates have been written, so they are the row's real date now rather than a
        // pending instruction. Keeping them would re-apply them to whatever the next plan proposes.
        manualDates.removeAll()
        workPlan = nil
        onApplied?()
        refresh()
    }
}

/// Whether the server row is still the one the user reviewed, so a due-date write cannot clobber an
/// edit made elsewhere.
///
/// Compared field by field, NOT by timestamp. The snapshot this screen reviews is built from the
/// list serialisation (`GET /to-do?…&sort_mode=DUE_DATE&exclude_completed=true`), which omits
/// `updated_at` entirely, while the re-read before each write (`GET /to-do/by-ids`) includes it —
/// verified against production on 2026-09-15, same task id, same minute. So the old
/// `latest.updated_at != nil, latest.updated_at == previous.updated_at` pair compared a real
/// timestamp against a permanent `nil` and refused **every** task write: the apply loop aborted at
/// index 0, never issued a `PUT /to-do`, and the sheet reported "Saved 0 date changes"
/// (report 2026-09-15_21-00-07, "I tried rescheduling some but it didn't work"). The neighbouring
/// outcome write has always worked precisely because it never took that timestamp.
///
/// The timestamp is still honoured when the reviewed row actually carries one, so a snapshot loaded
/// from an endpoint that does serialise it keeps the stronger check.
enum ForecastRowGuard {
    enum Refusal: String { case missingRow, unknownToSnapshot, editedElsewhere }

    /// `nil` when the write may proceed.
    static func refusal(latest: ToDoTask?, previous: ToDoTask?) -> Refusal? {
        guard let latest = latest else { return .missingRow }
        guard let previous = previous, previous.id == latest.id else { return .unknownToSnapshot }
        if let reviewed = previous.updated_at, let current = latest.updated_at, reviewed != current {
            return .editedElsewhere
        }
        guard latest.due_date == previous.due_date, latest.title == previous.title,
              latest.status == previous.status else { return .editedElsewhere }
        return nil
    }
}

/// Carries the account that reviewed a write through an asynchronous writer and its result.
/// The API also checks this identity after credential refresh and immediately before transmission.
struct ForecastWriteAccount {
    let id: String

    func matches(_ currentAccount: String?) -> Bool { !id.isEmpty && currentAccount == id }

    func perform(currentAccount: @escaping () -> String?,
                 writer: (String, @escaping (Bool) -> Void) -> Void,
                 completion: @escaping (Bool) -> Void) {
        guard matches(currentAccount()) else { completion(false); return }
        writer(id) { succeeded in
            completion(self.matches(currentAccount()) && succeeded)
        }
    }
}

/// The only impure bridge for task planning. Backend IDs reconcile local Day Plan copies without
/// charging both; a local title/block assignment remains authoritative for a pending local edit.
enum LocalForecastSnapshot {
    /// Price the project backlog on its due dates, rolling overdue work onto today. Local copies
    /// contribute duration and same-day block assignments, never an independent placement date.
    /// Local-only tasks are absent from this project forecast. Completed remote history is kept
    /// only for accurate progress when using the legacy API.
    static func projectTasks(remote: [ToDoTask], projects: [Project],
                             planned: [(date: Date, task: DayPlanTask)] = [],
                             today: Date = .distantPast, calendar: Calendar = .current,
                             serverExcludedCompleted: Bool = false) -> [LocalTimeForecast.TaskInput] {
        let projectByID = Dictionary(projects.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let imported = Dictionary(grouping: projects.filter { $0.synced_project_id != nil }) { $0.synced_project_id! }
        // The latest placement wins when the same to-do sits on more than one day.
        let placementByTaskID = Dictionary(
            planned.map { ($0.task.sourceTaskId ?? $0.task.id, $0) },
            uniquingKeysWith: { left, right in left.date > right.date ? left : right })
        let startOfToday = calendar.startOfDay(for: today)
        var seen = Set<String>()
        return remote.compactMap { task in
            let native = task.project_id.flatMap { projectByID[$0] }
            let importedMatches = task.synced_project_id.flatMap { imported[$0] } ?? []
            guard let project = native ?? (importedMatches.count == 1 ? importedMatches[0] : nil),
                  !task.id.isEmpty, seen.insert(task.id).inserted else { return nil }
            let columns = project.customStatuses.filter { $0.id == task.custom_status_id }
            let completed = !serverExcludedCompleted && (columns.isEmpty ? task.isCompleted : columns.contains { $0.should_complete_task == true })
            let dueDay = ToDoDates.parse(task.due_date).map { max(startOfToday, calendar.startOfDay(for: $0)) }
            let placement = placementByTaskID[task.id].map { (day: calendar.startOfDay(for: $0.date), task: $0.task) }
                .flatMap { $0.day == dueDay ? $0 : nil }
            let assignment = placement.flatMap { placed in
                DayPlanBlockKey.absorbs(placed.task.blockKey)
                    ? placed.task.blockKey.map { LocalTimeForecast.BlockAssignment(date: placed.day, blockKey: $0) } : nil
            }
            // Price placed work exactly as the Day Plan does. Otherwise the forecast can claim
            // a 15-minute card needs only five minutes (or has no estimate) and leave the day over.
            let minutes = placementByTaskID[task.id].map { Double($0.task.durationMinutes) }
                ?? (task.durationSeconds > 0 ? Double(task.durationSeconds) / 60
                    : task.perspiration_level.map { Double(ToDoScoring.minutes(forPerspiration: $0)) })
            return .init(id: task.id, projectID: project.id, estimatedMinutes: minutes,
                         outcome: task.outcome ?? LocalTimeForecast.TaskInput.unratedOutcome,
                         perspiration: task.effectivePerspiration,
                         dueDate: ToDoDates.parse(task.due_date), notBefore: dueDay,
                         blockAssignment: assignment, completed: completed)
        }
    }

    /// Known native custom columns override the legacy raw status, matching the server filter.
    static func isCompleted(_ task: ToDoTask, project: Project?) -> Bool {
        if let columnID = task.custom_status_id {
            let matching = project?.customStatuses.filter { $0.id == columnID } ?? []
            if !matching.isEmpty { return matching.contains { $0.should_complete_task == true } }
        }
        return task.isCompleted
    }

    static func tasks(remote: [ToDoTask], local: [(date: Date, task: DayPlanTask)], projects: [Project],
                      today: Date, calendar: Calendar, serverExcludedCompleted: Bool = false) -> [LocalTimeForecast.TaskInput] {
        let localByID = Dictionary(local.map { ($0.task.sourceTaskId ?? $0.task.id, $0) }, uniquingKeysWith: { left, right in left.date > right.date ? left : right })
        let projectIDs = Set(projects.map(\.id))
        let projectByID = Dictionary(projects.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let syncedIDs = Dictionary(projects.compactMap { project in
            project.synced_project_id.map { ($0, project.id) }
        }, uniquingKeysWith: { first, _ in first })
        let projectsByName = Dictionary(grouping: projects) { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let projectByName = projectsByName.compactMapValues { matches in matches.count == 1 ? matches.first?.id : nil }
        var seen: Set<String> = []
        var result: [LocalTimeForecast.TaskInput] = remote.compactMap { task in
            var projectID = task.synced_project_id.flatMap { syncedIDs[$0] } ?? task.project_id
            if let id = projectID, !projectIDs.contains(id) {
                // The filtered server has authoritative completion metadata even for a project
                // outside this active catalogue. Its unfinished work still needs capacity.
                guard serverExcludedCompleted else { return nil }
                projectID = nil
            }
            seen.insert(task.id)
            let copy = localByID[task.id]
            let planned = ToDoDates.parse(task.due_date).map { max(today, calendar.startOfDay(for: $0)) }
            let key = copy.flatMap { calendar.startOfDay(for: $0.date) == planned ? $0.task.blockKey : nil }
                ?? ToDoDates.parse(task.planned_date).flatMap {
                    calendar.startOfDay(for: $0) == planned ? task.planned_block_key : nil
                }
            let assignment = planned.flatMap { date in
                DayPlanBlockKey.absorbs(key) ? key.map { LocalTimeForecast.BlockAssignment(date: date, blockKey: $0) } : nil
            }
            // Day Plan hydration derives done from raw status and keeps it upgrade-only. It has
            // no reliable pending-completion marker, so that cached flag cannot override an
            // acknowledged unfinished server row (for example raw COMPLETED in a custom-open column).
            let completed = serverExcludedCompleted ? false :
                (isCompleted(task, project: task.project_id.flatMap { projectByID[$0] }) || copy?.task.done == true)
            // Local completion may race the filtered read. Keep only its dated habit reservation;
            // partial completed history must not inflate a project's remaining-work percentage.
            if completed {
                guard let assignment = assignment, calendar.startOfDay(for: assignment.date) >= today else { return nil }
            }
            let minutes = copy.map { Double($0.task.durationMinutes) } ?? (task.durationSeconds > 0 ? Double(task.durationSeconds) / 60 : task.perspiration_level.map { Double(ToDoScoring.minutes(forPerspiration: $0)) })
            return .init(id: task.id, projectID: completed ? nil : projectID, estimatedMinutes: minutes,
                         outcome: copy?.task.outcome ?? task.outcome ?? LocalTimeForecast.TaskInput.unratedOutcome,
                         perspiration: task.effectivePerspiration,
                         dueDate: ToDoDates.parse(task.due_date), notBefore: planned.map { max(today, calendar.startOfDay(for: $0)) },
                         blockAssignment: assignment, completed: completed)
        }
        for entry in local where !seen.contains(entry.task.sourceTaskId ?? entry.task.id) {
            let task = entry.task
            let assignment = DayPlanBlockKey.absorbs(task.blockKey)
                ? task.blockKey.map { LocalTimeForecast.BlockAssignment(date: entry.date, blockKey: $0) } : nil
            // Completed local work can reserve an already-used share of a still-available habit.
            // Missing unfinished server records are never resurrected from a stale local copy.
            if task.done {
                guard assignment != nil, calendar.startOfDay(for: entry.date) >= today else { continue }
            } else if task.sourceTaskId != nil { continue }
            let id = task.sourceTaskId ?? task.id
            guard seen.insert(id).inserted else { continue }
            result.append(.init(id: id, projectID: task.done ? nil : task.project.flatMap { projectByName[$0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] },
                                estimatedMinutes: Double(task.durationMinutes),
                                outcome: task.outcome ?? LocalTimeForecast.TaskInput.unratedOutcome,
                                notBefore: max(today, calendar.startOfDay(for: entry.date)),
                                blockAssignment: assignment,
                                completed: task.done))
        }
        return result
    }
}

private enum LocalForecastCalendarReader {
    private static let queue = DispatchQueue(label: "io.focusbear.forecast-calendar", qos: .userInitiated)
    static func read(from start: Date, to end: Date, authorized: Bool, meetingLabel: String,
                     dismissals: CalendarEventDismissalSnapshot,
                     completion: @escaping ([ScheduleMeetingInput]) -> Void) {
        guard authorized else { completion([]); return }
        queue.async {
            // A queue-confined store avoids touching CalendarManager's main-thread cache off-thread.
            let store = EKEventStore()
            let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
            let events = store.events(matching: predicate).filter { event in
                let declined = event.organizer?.isCurrentUser != true
                    && event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus == .declined
                return event.endDate > event.startDate && CalendarManager.countsAsBusy(isAllDay: event.isAllDay,
                    availability: event.availability, isCancelled: event.status == .canceled, hasDeclined: declined)
            }.flatMap { event -> [ScheduleMeetingInput] in
                let title = (event.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let id = CalendarManager.eventID(event)
                return dismissals.visiblePortions(eventID: id, externalID: event.calendarItemExternalIdentifier,
                    start: event.startDate, end: event.endDate, from: start, to: end).map { portion in
                        ScheduleMeetingInput(id: id, title: "📅 " + (title.isEmpty ? meetingLabel : title),
                                             start: portion.start, end: portion.end)
                    }
            }
            completion(events)
        }
    }
}


/// Validates one complete task catalogue for the forecast.
///
/// The server removes finished tasks itself when it understands `exclude_completed` and says so in
/// `meta.excludesCompleted`. An older server ignores the query and returns everything — which is a
/// slower download, not a reason to refuse: the forecast is computed locally (from a Mac calendar
/// the server never sees), so it must never depend on the server being able to filter. Either way
/// we keep every row for the paging arithmetic and drop the finished ones on the way out
/// (report 2026-09-14, "why is this still complaining about the server?").
///
/// `exclude_completed` is a download optimisation, never the authority on what "finished" means.
/// The server's filter reads `custom_status_id` first, so a task completed anywhere OTHER than the
/// project kanban — the Day Plan, the To-do list, the routine player, another device — keeps the
/// open column it was sitting in and comes back as outstanding, even with `status` COMPLETED. The
/// kanban (`ProjectKanban.columnId`) and the To-do list (`ToDoSectioning.build`) both show those
/// rows as done, so trusting the server's answer made the forecast plan work the user had already
/// finished and could see struck through (report 2026-09-15_17-41-45, "I completed all the tasks
/// for MRFF … it still said project at risk and 53%").
///
/// Whether the server filtered is decided by the first page and must not change mid-catalogue.
struct LocalForecastTaskCatalogue {
    /// Custom column ids whose tasks count as finished.
    static func completingStatusIds(in projects: [Project]) -> Set<String> {
        ToDoCompletionState.completingStatusIds(in: projects)
    }

    private let completingStatusIds: Set<String>
    private var rows: [ToDoTask] = []
    /// Only guards that the server's answer does not change mid-catalogue; it no longer decides
    /// which rows survive, so nothing outside reads it.
    private var serverFilteredCompleted: Bool?
    private(set) var expectedCount: Int?
    private(set) var isComplete = false
    private var nextPage = 1

    init(completingStatusIds: Set<String> = []) { self.completingStatusIds = completingStatusIds }

    /// Rows the forecast should plan, finished work excluded however the server answered. The local
    /// rule runs even when the server filtered: it is a no-op for every row the server got right,
    /// and it is the only thing that removes one the server got wrong.
    var tasks: [ToDoTask] { rows.filter { !isFinished($0) } }
    /// Rows downloaded so far — the count the server's paging totals refer to.
    var downloadedCount: Int { rows.count }

    private func isFinished(_ task: ToDoTask) -> Bool {
        ToDoCompletionState.isFinished(task, completingStatusIds: completingStatusIds)
    }

    mutating func append(_ response: AllApi.ForecastTasksPage, page: Int) -> Bool {
        let filtered = response.meta.excludesCompleted == true
        guard !isComplete, page == nextPage, response.meta.page == page,
              serverFilteredCompleted == nil || serverFilteredCompleted == filtered,
              let count = response.meta.itemCount, count >= 0,
              let hasNext = response.meta.hasNextPage,
              expectedCount == nil || expectedCount == count else { return false }
        let ids = response.data.map(\.id)
        guard ids.allSatisfy({ !$0.isEmpty }), Set(ids).count == ids.count,
              Set(rows.map(\.id)).isDisjoint(with: ids) else { return false }
        let size = rows.count + response.data.count
        guard hasNext ? (!ids.isEmpty && size < count) : size == count else { return false }
        rows += response.data
        serverFilteredCompleted = filtered
        expectedCount = count
        isComplete = !hasNext
        nextPage += 1
        return true
    }
}

/// The API includes synced extras on page one. Their tag IDs can also identify native
/// projects on a later page (the backend migrated tags into projects retaining IDs).
/// Preserve both kinds of source identity for completeness without duplicating forecast work.
struct LocalForecastProjectCatalogue {
    private var orderedIDs: [String] = []
    private var native: [String: Project] = [:]
    private var synced: [String: Project] = [:]
    var nativeCount: Int { native.count }
    var identityCount: Int { native.count + synced.count }
    var projectCompletions: [String: ProjectListCompletion] {
        var result: [String: ProjectListCompletion] = [:]
        for id in orderedIDs {
            // Native counts cover project_id, imported counts cover synced_project_id. The sets
            // may overlap after migration, so neither counter is an authoritative union total.
            guard native[id] == nil || synced[id] == nil,
                  let project = native[id] ?? synced[id],
                  let completion = ProjectListPresentation.completionFromCounts(project) else { continue }
            result[id] = completion
        }
        return result
    }
    var projects: [Project] {
        orderedIDs.compactMap { id in
            guard var project = native[id] ?? synced[id] else { return nil }
            // Native metadata supplies due dates/outcomes. Retain the synced association
            // so imported tasks resolve to this project and remain protected from edits.
            if let extra = synced[id] {
                project.synced_project_id = extra.synced_project_id
                project.synced_platform = extra.synced_platform
            }
            return project
        }
    }

    mutating func append(_ rows: [Project]) -> Bool {
        for row in rows {
            guard !row.id.isEmpty else { return false }
            if native[row.id] == nil && synced[row.id] == nil { orderedIDs.append(row.id) }
            if row.isSynced {
                if let previous = synced[row.id], previous.synced_project_id != row.synced_project_id {
                    return false // Ambiguous task association; do not invent a mapping.
                }
                if synced[row.id] == nil { synced[row.id] = row }
            } else if native[row.id] == nil { native[row.id] = row }
        }
        return true
    }
}
