//
//  ToDoStore.swift
//  Focus Bear
//
//  State for the native To-do List (Tasks tab). Behaves like the web dashboard's to-do slice +
//  `dashboard/to-do` page: three status buckets fetched per status (`GET /to-do?status=`), SMART /
//  chronological / due-date sort, 500 ms debounced search, client-side filters, per-status infinite
//  scroll, optimistic completion, and the brain-dump → tasks, CSV export and Procrastinate tools.
//

import Foundation
import AppKit

/// Which task the editor sheet is for; nil task = create (pre-filled with `initialTitle`).
struct ToDoEditorSession: Identifiable {
    let id = UUID()
    let task: ToDoTask?
    let initialTitle: String
    /// A new task opened from a project detail is pre-linked to that project. The object travels
    /// with the session so a just-created project is selected even before the catalogue re-fetches.
    var initialProject: Project? = nil
}

/// Paging state of one status bucket (web `todoStatusPagination`).
struct ToDoStatusPaging: Equatable {
    var page = ToDoPaging.firstPage
    var hasNextPage = false
    var itemCount = 0
}

final class ToDoStore: ObservableObject {

    /// Web `TO_DO_SEARCH_DEBOUNCE_DELAY`.
    static let searchDebounceSeconds: TimeInterval = 0.5
    static let statusMessageSeconds: TimeInterval = 3.0
    /// Web `STANDALONE_BRAIN_DUMP` vagueness gate + `BRAIN_DUMP_TIMEOUT`.
    static let brainDumpMinWords = 5
    static let brainDumpMinChars = 20
    static let brainDumpCharLimit = 1000
    private static let sortModeKey = "kUserdefaultsToDoListSortMode"
    private static let brainDumpTimeouts: [(maxLength: Int, seconds: TimeInterval)] = [(300, 30), (700, 45), (Int.max, 60)]

    let strings: ToDoStrings
    /// Fires after any task write succeeds (save, delete, complete) so other screens showing the
    /// same tasks (the project detail) can re-fetch.
    var onTaskChanged: (() -> Void)?
    /// Fires after `POST /projects` from the editor's inline field so the Projects tab can list it.
    var onProjectCreated: ((Project) -> Void)?

    // Tasks by status
    @Published private(set) var tasksByStatus: [ToDoStatus: [ToDoTask]] = [:]
    @Published private(set) var paging: [ToDoStatus: ToDoStatusPaging] = [:]
    @Published private(set) var isFetching = false
    @Published private(set) var loadingMoreStatus: ToDoStatus? = nil
    @Published private(set) var hasFetchedOnce = false
    private var fetchGeneration = 0

    // Search / sort / filter
    @Published var searchQuery = "" { didSet { scheduleSearch() } }
    @Published private(set) var searchResults: [ToDoTask]? = nil
    @Published private(set) var isSearching = false
    private var pendingSearch: DispatchWorkItem?
    @Published var sortMode: ToDoSortMode {
        didSet {
            guard sortMode != oldValue else { return }
            UserDefaults.standard.set(sortMode.rawValue, forKey: ToDoStore.sortModeKey)
            refreshAll()
        }
    }
    @Published var filters = ToDoFilters() {
        didSet {
            guard filters != oldValue else { return }
            // Only the project filter is server-side (web `refreshTodosAllStatuses` on project change).
            if filters.projectId != oldValue.projectId { refreshAll() }
        }
    }
    @Published var showFilters = false {
        didSet { if !showFilters { filters = ToDoFilters() } }
    }

    // Projects (for chips, custom statuses, the project filter and the editor)
    @Published private(set) var projects: [Project] = []
    private var projectsById: [String: Project] = [:]

    // Sections
    @Published var expandedSectionId: String? = nil
    private var hasAutoExpanded = false

    /// Token for the cross-screen completion bus (the Day Plan ticking one of these to-dos).
    private var completionObserver: NSObjectProtocol?

    // Row selection (the action bar beneath a clicked row)
    @Published var selectedTaskId: String? = nil
    /// RAW schedule-free minutes on a day, for the smart snooze — wired by the host to the Day Plan's
    /// provider (`scheduleViewController.scheduleFreeMinutes(on:)`); nil leaves the generic smart label.
    var scheduleFreeMinutes: ((Date) -> Int)?

    // Editor / delete / tools
    @Published var editorSession: ToDoEditorSession? = nil
    @Published var taskToDelete: ToDoTask? = nil
    @Published private(set) var isSavingTask = false
    @Published private(set) var isCreatingProject = false
    @Published private(set) var updatingTaskIds: Set<String> = []
    @Published var isBrainDumpVisible = false
    @Published var isMatrixVisible = false
    @Published var isProcrastinateVisible = false

    // Brain dump
    @Published var brainDumpText = ""
    @Published private(set) var brainDumpTasks: [BrainDumpTask] = []
    @Published private(set) var isConvertingBrainDump = false
    @Published private(set) var showVaguePrompt = false
    @Published private(set) var isCreatingBrainDumpTasks = false

    // Procrastinate
    @Published private(set) var savedWebsites: [SavedWebsite] = []
    @Published private(set) var isFetchingSavedWebsites = false

    // Feedback
    @Published private(set) var statusMessage: String? = nil
    @Published private(set) var completionBanner: ToDoCompletionBatch? = nil
    @Published private(set) var isExporting = false
    private var pendingStatusClear: DispatchWorkItem?
    private var pendingBannerClear: DispatchWorkItem?

    init(strings: ToDoStrings) {
        self.strings = strings
        sortMode = ToDoSortMode(rawValue: UserDefaults.standard.string(forKey: ToDoStore.sortModeKey) ?? "") ?? .smart
        // The Day Plan shows the same to-dos; a tick there must show here without a refresh.
        completionObserver = TodoCompletionBus.observe { [weak self] change in
            self?.applyExternalCompletion(todoID: change.todoID, completed: change.completed)
        }
    }

    deinit {
        if let observer = completionObserver { NotificationCenter.default.removeObserver(observer) }
    }

    // MARK: - Derived

    var isSearchActive: Bool { !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// Every loaded task (all three buckets), web `state.toDo.tasks`.
    var loadedTasks: [ToDoTask] { ToDoSectioning.defaultOrder.flatMap { tasksByStatus[$0] ?? [] } }

    /// Web `ListOfTasks` pipeline: search results (or the buckets) → client filters → sections.
    var sections: [ToDoSection] {
        let source = isSearchActive ? (searchResults ?? []) : loadedTasks
        let filtered = source.filter { filters.matches($0) }
        return ToDoSectioning.build(tasks: filtered, projects: projects, sortMode: sortMode, sectionTitles: strings.sectionTitles())
    }

    /// Web `getTotalCountByStatus`: the server total while no client filter narrows the bucket.
    func totalCount(for section: ToDoSection) -> Int {
        guard let status = section.status, !isSearchActive, !filters.isActive,
              let serverCount = paging[status]?.itemCount else { return section.tasks.count }
        return max(serverCount, section.tasks.count)
    }

    func hasMore(for section: ToDoSection) -> Bool {
        guard let status = section.status, !isSearchActive else { return false }
        return paging[status]?.hasNextPage ?? false
    }

    var visibleTaskCount: Int { sections.reduce(0) { $0 + $1.tasks.count } }
    var loadedTaskCount: Int { loadedTasks.count }

    /// Web `EmptyState` selection.
    enum EmptyState { case none, loading, firstTask, noSearchMatch, noFilterMatch }

    var emptyState: EmptyState {
        guard visibleTaskCount == 0 else { return .none }
        if isFetching && loadedTaskCount == 0 { return .loading }
        if isSearching && isSearchActive { return .loading }
        if loadedTaskCount == 0 && !isSearchActive { return .firstTask }
        return isSearchActive ? .noSearchMatch : .noFilterMatch
    }

    func project(id: String?) -> Project? {
        guard let id = id else { return nil }
        return projectsById[id]
    }

    /// Custom statuses of the project a task's status belongs to (web `getProjectCustomStatusesById`).
    func customStatuses(for task: ToDoTask) -> [ProjectCustomStatus] {
        project(id: task.project_id)?.customStatuses ?? []
    }

    func customStatusLabel(id: String?) -> String? {
        guard let id = id else { return nil }
        for project in projects {
            if let status = project.customStatuses.first(where: { $0.id == id }) { return status.label }
        }
        return nil
    }

    /// Open tasks in a quadrant for the Eisenhower matrix (web filters out completed).
    func matrixTasks(_ quadrant: EisenhowerQuadrant) -> [ToDoTask] {
        loadedTasks.filter { $0.quadrant == quadrant && !$0.isCompleted }
    }

    // MARK: - Lifecycle

    /// Web `ToDosTab` mount: all active projects, then all three status buckets.
    func screenAppeared() {
        loadProjects()
        if isSearchActive { runSearch() }
        refreshAll()
    }

    func loadProjects(completion: (() -> Void)? = nil) {
        allApiObject.getAllActiveProjects { [weak self] projects in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let projects = projects { self.setProjects(projects) }
                completion?()
            }
        }
    }

    private func setProjects(_ projects: [Project]) {
        self.projects = projects.sorted { strings.projectName($0.name).localizedCaseInsensitiveCompare(strings.projectName($1.name)) == .orderedAscending }
        projectsById = Dictionary(projects.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Adds a project the catalogue doesn't know yet (created on the Projects tab, or opened from a
    /// detail before the list refreshed) so chips, custom statuses and the editor can resolve it.
    func insertProject(_ project: Project) {
        guard projectsById[project.id] == nil else { return }
        setProjects(projects + [project])
    }

    // MARK: - Fetching

    /// Web `refreshTodosAllStatuses`: page 1 of every bucket with the current sort + project filter.
    func refreshAll() {
        fetchGeneration += 1
        let generation = fetchGeneration
        isFetching = true
        var remaining = ToDoSectioning.defaultOrder.count
        for status in ToDoSectioning.defaultOrder {
            fetchPage(ToDoPaging.firstPage, status: status, generation: generation) { [weak self] in
                remaining -= 1
                guard remaining == 0, let self = self, generation == self.fetchGeneration else { return }
                self.isFetching = false
                self.hasFetchedOnce = true
                self.autoExpandIfNeeded()
            }
        }
    }

    func loadNextPage(for section: ToDoSection) {
        guard let status = section.status, hasMore(for: section), loadingMoreStatus == nil, !isSearchActive else { return }
        let next = (paging[status]?.page ?? ToDoPaging.firstPage) + 1
        loadingMoreStatus = status
        fetchPage(next, status: status, generation: fetchGeneration) { [weak self] in self?.loadingMoreStatus = nil }
    }

    private func fetchPage(_ page: Int, status: ToDoStatus, generation: Int, completion: @escaping () -> Void) {
        let query = ToDoListQuery(page: page, status: status, sortMode: sortMode, projectId: filters.projectId)
        allApiObject.getToDoPage(query) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                defer { completion() }
                // A stale page for a sort/filter the user has since changed must not replace the list.
                guard generation == self.fetchGeneration else { return }
                guard let result = result else {
                    self.showStatus(self.strings[.requestFailed])
                    return
                }
                var bucket = page == ToDoPaging.firstPage ? [] : (self.tasksByStatus[status] ?? [])
                let known = Set(bucket.map { $0.id })
                bucket.append(contentsOf: result.data.filter { !known.contains($0.id) })
                self.tasksByStatus[status] = bucket
                self.paging[status] = ToDoStatusPaging(page: page, hasNextPage: result.meta?.hasNextPage ?? false,
                                                       itemCount: result.meta?.itemCount ?? bucket.count)
            }
        }
    }

    /// Web accordion: open Doing when it has tasks, else To do — once.
    private func autoExpandIfNeeded() {
        guard !hasAutoExpanded else { return }
        hasAutoExpanded = true
        if !(tasksByStatus[.inProgress] ?? []).isEmpty {
            expandedSectionId = ToDoStatus.inProgress.rawValue
        } else if !(tasksByStatus[.notStarted] ?? []).isEmpty {
            expandedSectionId = ToDoStatus.notStarted.rawValue
        }
    }

    func toggleSection(_ section: ToDoSection) {
        expandedSectionId = expandedSectionId == section.id ? nil : section.id
        selectedTaskId = nil
    }

    // MARK: - Row selection

    func select(_ task: ToDoTask) {
        selectedTaskId = task.id
    }

    func clearSelection() {
        selectedTaskId = nil
    }

    // MARK: - Search

    private func scheduleSearch() {
        pendingSearch?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isSearchActive { self.runSearch() } else { self.searchResults = nil }
        }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ToDoStore.searchDebounceSeconds, execute: work)
    }

    private func runSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        allApiObject.searchToDoTasks(title: query) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSearching = false
                guard query == self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                self.searchResults = result ?? []
            }
        }
    }

    // MARK: - Filters

    func setProjectFilter(_ projectId: String?) {
        var updated = filters
        updated.projectId = projectId
        if projectId != nil { showFilters = true }
        filters = updated
    }

    /// Web due-date presets: today / this ISO week / next ISO week / next 30 days.
    enum DueDatePreset: CaseIterable { case today, thisWeek, nextWeek, next30Days }

    /// The local day range a preset selects (both ends inclusive).
    static func dueDateRange(for preset: DueDatePreset, now: Date = Date()) -> (start: Date, end: Date) {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale.current
        let today = calendar.startOfDay(for: now)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        switch preset {
        case .today:
            return (today, today)
        case .thisWeek:
            return (weekStart, calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart)
        case .nextWeek:
            let nextStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? weekStart
            return (nextStart, calendar.date(byAdding: .day, value: 6, to: nextStart) ?? nextStart)
        case .next30Days:
            return (today, calendar.date(byAdding: .day, value: 30, to: today) ?? today)
        }
    }

    func applyDueDatePreset(_ preset: DueDatePreset?) {
        var updated = filters
        let range = preset.map { ToDoStore.dueDateRange(for: $0) }
        updated.dueDateStart = range?.start
        updated.dueDateEnd = range?.end
        filters = updated
    }

    var activeDueDatePreset: DueDatePreset? {
        guard let start = filters.dueDateStart, let end = filters.dueDateEnd else { return nil }
        return DueDatePreset.allCases.first { preset in
            let range = ToDoStore.dueDateRange(for: preset)
            return range.start == start && range.end == end
        }
    }

    // MARK: - Local merge (web `applyMergedTodoTaskFromPayload`)

    private func upsertLocally(_ task: ToDoTask) {
        let newStatus = task.defaultStatus
        var removedFrom: ToDoStatus? = nil
        for status in ToDoSectioning.defaultOrder {
            if tasksByStatus[status]?.contains(where: { $0.id == task.id }) == true {
                tasksByStatus[status]?.removeAll { $0.id == task.id }
                removedFrom = status
            }
        }
        tasksByStatus[newStatus, default: []].insert(task, at: 0)
        // Keep the per-bucket server counts (used by totalCount(for:)) in step with an optimistic bucket
        // move, so the section headers don't read one-too-high / one-too-low until the next refresh.
        // A same-bucket update (e.g. a due-date edit, or re-applying the saved row) leaves counts alone.
        if removedFrom != newStatus {
            if let old = removedFrom {
                paging[old]?.itemCount = max(0, (paging[old]?.itemCount ?? 1) - 1)
            }
            paging[newStatus]?.itemCount = (paging[newStatus]?.itemCount ?? 0) + 1
        }
        if let index = searchResults?.firstIndex(where: { $0.id == task.id }) { searchResults?[index] = task }
    }

    private func removeLocally(id: String) {
        for status in ToDoSectioning.defaultOrder {
            if let index = tasksByStatus[status]?.firstIndex(where: { $0.id == id }) {
                tasksByStatus[status]?.remove(at: index)
                paging[status]?.itemCount = max(0, (paging[status]?.itemCount ?? 1) - 1)
            }
        }
        searchResults?.removeAll { $0.id == id }
    }

    // MARK: - Row actions

    /// Web `useTaskCompletionToggle`: optimistic bucket move, `PUT /to-do`, revert on failure.
    func toggleComplete(_ task: ToDoTask) {
        let completed = !task.isCompleted
        let updated = ToDoStatusToggle.apply(to: task, completed: completed, customStatuses: customStatuses(for: task))
        upsertLocally(updated)
        // Optimistically, so the Day Plan ticks with this row rather than a request later. `persist`
        // announces the revert if the write fails.
        TodoCompletionBus.post(todoID: task.id, completed: completed)
        persist(updated, revertTo: task) { [weak self] saved in
            if saved.isCompleted { self?.notifyCompleted(saved.title) } else { self?.notifyUncompleted() }
            // The server can settle on a different status than the optimistic one (a project's custom
            // done column), so announce what it actually saved.
            TodoCompletionBus.post(todoID: saved.id, completed: saved.isCompleted)
        }
    }

    /// A to-do completed (or un-completed) on the Day Plan: reflect it in the cached row and count it
    /// in the completion banner. No second write — the Day Plan already sent the status — and no
    /// announcement back, so this can't loop. The state check is what makes our OWN toggle a no-op
    /// here (the row is already updated by then), keeping a tick from being banner-counted twice.
    private func applyExternalCompletion(todoID: String, completed: Bool) {
        guard let task = loadedTasks.first(where: { $0.id == todoID }), task.isCompleted != completed else { return }
        let updated = ToDoStatusToggle.apply(to: task, completed: completed, customStatuses: customStatuses(for: task))
        upsertLocally(updated)
        if completed { notifyCompleted(updated.title) } else { notifyUncompleted() }
        onTaskChanged?()
    }

    /// Web `TaskInfo.handleDueDateSave` — `nil` clears the due date.
    func setDueDate(_ task: ToDoTask, day: Date?) {
        var updated = task
        updated.due_date = day.map { ToDoDates.ymd($0) }
        guard ToDoDates.ymd(fromISO: task.due_date) != updated.due_date else { return }
        upsertLocally(updated)
        persist(updated, revertTo: task) { _ in }
    }

    // MARK: - Snooze (the Day Plan's)

    /// Minutes the snooze has to fit: the task's duration, else its perspiration's work minutes.
    private func snoozeMinutes(_ task: ToDoTask) -> Int {
        ToDoScoring.durationSeconds(explicit: task.durationSeconds, perspiration: task.effectivePerspiration) / 60
    }

    private func smartSnoozePlanner() -> SmartSnoozePlanner? {
        guard let scheduleFreeMinutes = scheduleFreeMinutes else { return nil }
        return SmartSnoozePlanner.dayPlan(from: Date(), scheduleFreeMinutes: scheduleFreeMinutes)
    }

    /// The "Next free slot" the popover names for a task — the same scan the Day Plan runs.
    func snoozeSuggestion(for task: ToDoTask) -> SmartSnoozeSlot? {
        smartSnoozePlanner()?.slot(requiredMinutes: snoozeMinutes(task))
    }

    /// Snooze to the day the planner picks (the popover's smart button).
    func smartSnooze(_ task: ToDoTask) {
        guard let day = smartSnoozePlanner()?.distribute(durations: [snoozeMinutes(task)])?.first else {
            showStatus(strings[.requestFailed])
            return
        }
        snooze(task, to: day)
    }

    /// Snooze = the Day Plan's snooze. A task that sits on the Day Plan moves there too, through
    /// `DayPlanTaskStore.snooze` — the one `PUT /to-do` carrying `planned_date` + `due_date` that the
    /// Day Plan's own popover sends; a task that isn't planned gets its due date through the same
    /// upsert (`setDueDate`). Either way the row shows the new date at once.
    func snooze(_ task: ToDoTask, to day: Date) {
        selectedTaskId = nil
        guard let planned = DayPlanTaskStore.shared.plannedCopy(ofSourceTask: task.id) else {
            setDueDate(task, day: day)
            return
        }
        DayPlanTaskStore.shared.snooze(id: planned.task.id, from: planned.day, to: day)
        var updated = task
        updated.due_date = ToDoDates.ymd(day)
        upsertLocally(updated)
        onTaskChanged?()
    }

    private func persist(_ task: ToDoTask, revertTo previous: ToDoTask, completion: @escaping (ToDoTask) -> Void) {
        updatingTaskIds.insert(task.id)
        allApiObject.upsertToDo(ToDoUpsertBody.make(from: task)) { [weak self] saved, statusCode, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updatingTaskIds.remove(task.id)
                guard (200..<300).contains(statusCode) else {
                    self.upsertLocally(previous)
                    // A completion that didn't save must un-tick wherever it was optimistically ticked.
                    if previous.isCompleted != task.isCompleted {
                        TodoCompletionBus.post(todoID: previous.id, completed: previous.isCompleted)
                    }
                    self.showFailure(self.strings.format(.couldNotUpdateTask, ToDoStrings.titleToken, task.title), reason: serverMessage)
                    return
                }
                // A 2xx whose body doesn't decode still saved; keep the optimistic row.
                let result = saved ?? task
                self.upsertLocally(result)
                self.onTaskChanged?()
                completion(result)
            }
        }
    }

    /// One banner that batches rapid completions (web consolidates too): a random phrase per batch,
    /// the count rising while completions keep landing within the lifetime.
    private func notifyCompleted(_ title: String) {
        let phrase = strings.list(.taskCompletedPhrases).randomElement() ?? ""
        completionBanner = ToDoCompletionBatch.recording(title, into: completionBanner, phrase: phrase, now: Date())
        scheduleBannerExpiry()
    }

    private func notifyUncompleted() {
        completionBanner = completionBanner?.uncompleting(at: Date())
        if completionBanner == nil { pendingBannerClear?.cancel() }
    }

    private func scheduleBannerExpiry() {
        pendingBannerClear?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.completionBanner = nil }
        pendingBannerClear = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ToDoCompletionBatch.lifetime, execute: work)
    }

    func dismissCompletionBanner() {
        pendingBannerClear?.cancel()
        completionBanner = nil
    }

    var completionBannerText: String? {
        guard let banner = completionBanner else { return nil }
        return ToDoStore.bannerText(banner, strings: strings)
    }

    static func bannerText(_ banner: ToDoCompletionBatch, strings: ToDoStrings) -> String {
        if banner.count == 1 {
            return strings.format(.taskCompletedSingle, [ToDoStrings.phraseToken: banner.phrase, ToDoStrings.titleToken: banner.lastTitle])
        }
        return strings.format(.taskCompletedMultiple, [ToDoStrings.phraseToken: banner.phrase, ToDoStrings.countToken: String(banner.count)])
    }

    // MARK: - Editor

    func openEditor(for task: ToDoTask?, project: Project? = nil) {
        if let project = project { insertProject(project) }
        // Web pre-fills a new task's title with the current search text.
        editorSession = ToDoEditorSession(task: task, initialTitle: task == nil && project == nil ? searchQuery.trimmingCharacters(in: .whitespaces) : "",
                                          initialProject: project)
    }

    func closeEditor() {
        editorSession = nil
    }

    /// Web `submitToDoFromFlow`: `PUT /to-do`, then refresh every bucket and close the editor.
    func saveTask(_ task: ToDoTask, isNew: Bool, completion: @escaping (_ success: Bool) -> Void) {
        isSavingTask = true
        allApiObject.upsertToDo(ToDoUpsertBody.make(from: task)) { [weak self] saved, statusCode, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSavingTask = false
                guard (200..<300).contains(statusCode) else {
                    self.showFailure(self.strings.format(isNew ? .couldNotCreateTask : .couldNotUpdateTask, ToDoStrings.titleToken, task.title), reason: serverMessage)
                    completion(false)
                    return
                }
                self.upsertLocally(saved ?? task)
                self.refreshAll()
                self.onTaskChanged?()
                self.closeEditor()
                self.showStatus(self.strings[isNew ? .taskCreated : .taskUpdated])
                completion(true)
            }
        }
    }

    func requestDelete(_ task: ToDoTask) {
        taskToDelete = task
    }

    func confirmDelete() {
        guard let task = taskToDelete else { return }
        taskToDelete = nil
        delete(task)
    }

    /// `DELETE /to-do` straight away (the row's inline confirmation already asked).
    func delete(_ task: ToDoTask) {
        if selectedTaskId == task.id { selectedTaskId = nil }
        allApiObject.deleteToDo(id: task.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard success else {
                    self.showStatus(self.strings[.couldNotDeleteTask])
                    return
                }
                self.removeLocally(id: task.id)
                self.onTaskChanged?()
                if self.editorSession?.task?.id == task.id { self.closeEditor() }
                self.showStatus(self.strings[.taskDeleted])
            }
        }
    }

    /// `POST /projects { name }` from the editor's inline "Create “…”" row.
    func createProject(named name: String, completion: @escaping (Project?) -> Void) {
        guard !isCreatingProject else { return }
        isCreatingProject = true
        allApiObject.createToDoProject(name: name, dueDate: nil) { [weak self] project, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCreatingProject = false
                guard let project = project else {
                    self.showFailure(self.strings[.couldNotCreateProject], reason: serverMessage)
                    completion(nil)
                    return
                }
                self.insertProject(project)
                self.onProjectCreated?(project)
                completion(project)
            }
        }
    }

    // MARK: - Brain dump → tasks

    /// Web `isStandaloneBrainDumpInputVague`.
    var isBrainDumpVague: Bool {
        let trimmed = brainDumpText.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.split { $0.isWhitespace }.count
        return words < ToDoStore.brainDumpMinWords || trimmed.count < ToDoStore.brainDumpMinChars
    }

    func convertBrainDump(force: Bool) {
        let contents = brainDumpText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !contents.isEmpty, !isConvertingBrainDump else { return }
        if isBrainDumpVague && !force {
            showVaguePrompt = true
            return
        }
        showVaguePrompt = false
        isConvertingBrainDump = true
        let timeout = ToDoStore.brainDumpTimeouts.first { contents.count <= $0.maxLength }?.seconds ?? 60
        allApiObject.convertBrainDumpToTasks(contents: contents, timeout: timeout) { [weak self] tasks in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isConvertingBrainDump = false
                guard let tasks = tasks, !tasks.isEmpty else {
                    self.showStatus(self.strings[.brainDumpFailed])
                    return
                }
                self.brainDumpTasks = tasks
            }
        }
    }

    func updateBrainDumpTask(_ task: BrainDumpTask) {
        guard let index = brainDumpTasks.firstIndex(where: { $0.id == task.id }) else { return }
        brainDumpTasks[index] = task
    }

    func removeBrainDumpTask(_ task: BrainDumpTask) {
        brainDumpTasks.removeAll { $0.id == task.id }
    }

    var validBrainDumpTasks: [BrainDumpTask] {
        brainDumpTasks.filter { !$0.task_name.trimmingCharacters(in: .whitespaces).isEmpty && $0.estimatedMinutes > 0 }
    }

    /// Web `submitAllBrainDumpTasks`: one `PUT /to-do` per task, then refresh and close.
    func createBrainDumpTasks() {
        let tasks = validBrainDumpTasks
        guard !tasks.isEmpty, !isCreatingBrainDumpTasks else { return }
        isCreatingBrainDumpTasks = true
        let today = ToDoDates.ymd(Date())
        var remaining = tasks.count
        for task in tasks {
            let body: [String: Any] = [
                "id": UUID().uuidString.lowercased(),
                "title": task.task_name,
                "details": "",
                "objective": "",
                "tags": [],
                "due_date": task.due_date ?? today,
                "duration": task.estimatedMinutes * 60,
                "eisenhower_quadrant": EisenhowerQuadrant.doIt.rawValue,
                "subtasks": task.subtasks.map { ["name": $0, "is_completed": false] as [String: Any] },
                "status": ToDoStatus.notStarted.rawValue,
                "outcome": task.outcome ?? ToDoScoring.defaultOutcome,
                "perspiration_level": task.perspiration_level ?? ToDoScoring.defaultPerspiration,
            ]
            allApiObject.upsertToDo(body) { [weak self] _, _, _ in
                DispatchQueue.main.async {
                    remaining -= 1
                    guard remaining == 0, let self = self else { return }
                    self.isCreatingBrainDumpTasks = false
                    self.brainDumpTasks = []
                    self.brainDumpText = ""
                    self.isBrainDumpVisible = false
                    self.refreshAll()
                }
            }
        }
    }

    func resetBrainDump() {
        brainDumpTasks = []
        showVaguePrompt = false
    }

    // MARK: - Export CSV

    /// Web `useExportCsv`: every task (no filters), 50 per page, up to 400 pages, then a save panel.
    func exportAllTasks() {
        guard !isExporting else { return }
        isExporting = true
        collectAllTasks(page: ToDoPaging.firstPage, accumulated: []) { [weak self] tasks, truncated, failed in
            guard let self = self else { return }
            self.isExporting = false
            let rows = failed ? self.loadedTasks : tasks
            let csv = ToDoCSV.build(tasks: rows, headers: self.csvHeaders,
                                    statusLabel: { self.strings.statusLabel($0.defaultStatus) },
                                    quadrantLabel: { self.strings.quadrantLabel($0.quadrant) })
            self.saveExport(csv)
            if failed { self.showStatus(self.strings[.exportFailed]) } else if truncated { self.showStatus(self.strings[.exportTruncated]) }
        }
    }

    private var csvHeaders: [String] {
        [strings[.createTaskTitle], strings[.description], strings[.objective], strings[.status], strings[.quadrant],
         strings[.filterProject], strings[.subtasks], strings[.filterDueDate], strings[.createdShort]]
    }

    private func collectAllTasks(page: Int, accumulated: [ToDoTask],
                                 completion: @escaping (_ tasks: [ToDoTask], _ truncated: Bool, _ failed: Bool) -> Void) {
        let query = ToDoListQuery(page: page, sortMode: .chronological)
        allApiObject.getToDoPage(query) { [weak self] result in
            DispatchQueue.main.async {
                guard let result = result else { completion(accumulated, false, true); return }
                let merged = accumulated + result.data
                let hasNext = result.meta?.hasNextPage ?? false
                if hasNext && page < ToDoPaging.exportMaxPages {
                    self?.collectAllTasks(page: page + 1, accumulated: merged, completion: completion)
                } else {
                    completion(merged, hasNext, false)
                }
            }
        }
    }

    private func saveExport(_ csv: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "focus-bear-tasks.csv"
        panel.allowedFileTypes = ["csv"]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            showStatus(strings[.exportSaved])
        } catch {
            addLog(text: "todo export write error: \(error.localizedDescription)")
            showStatus(strings[.requestFailed])
        }
    }

    // MARK: - Procrastinate (saved websites)

    func loadSavedWebsites() {
        isFetchingSavedWebsites = true
        allApiObject.getSavedWebsites { [weak self] websites in
            DispatchQueue.main.async {
                self?.isFetchingSavedWebsites = false
                self?.savedWebsites = websites ?? []
            }
        }
    }

    func addSavedWebsite(url: String, note: String, completion: @escaping (Bool) -> Void) {
        allApiObject.addSavedWebsite(url: url, note: note) { [weak self] success in
            DispatchQueue.main.async {
                if success { self?.loadSavedWebsites() } else { self?.showStatus(self?.strings[.requestFailed] ?? "") }
                completion(success)
            }
        }
    }

    func deleteSavedWebsite(_ website: SavedWebsite) {
        allApiObject.deleteSavedWebsite(id: website.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success { self.savedWebsites.removeAll { $0.id == website.id } } else { self.showStatus(self.strings[.couldNotDeleteWebsites]) }
            }
        }
    }

    func deleteSavedWebsites(ids: [String]) {
        guard !ids.isEmpty else { return }
        allApiObject.deleteSavedWebsites(ids: ids) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.savedWebsites.removeAll { ids.contains($0.id) }
                    self.showStatus(self.strings[.websitesDeleted])
                } else {
                    self.showStatus(self.strings[.couldNotDeleteWebsites])
                }
            }
        }
    }

    // MARK: - Status toast

    /// The generic failure line plus the server's reason when it gave one — a rejected write is
    /// diagnosable from the toast instead of only from the log.
    func showFailure(_ generic: String, reason: String?) {
        showStatus(ToDoStore.failureText(generic, reason: reason))
    }

    static func failureText(_ generic: String, reason: String?) -> String {
        guard let reason = reason, !reason.isEmpty else { return generic }
        return "\(generic): \(reason)"
    }

    func showStatus(_ message: String) {
        statusMessage = message
        pendingStatusClear?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.statusMessage = nil }
        pendingStatusClear = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ToDoStore.statusMessageSeconds, execute: work)
    }
}
