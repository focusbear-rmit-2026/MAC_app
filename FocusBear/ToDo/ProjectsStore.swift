//
//  ProjectsStore.swift
//  Focus Bear
//
//  State for the Projects tab. Mirrors the web dashboard's `dashboard/projects` page: the portfolio
//  "What matters" view (`GET /portfolio`, buckets computed server-side, regrouped client-side by
//  `PortfolioGrouping`), the "All projects" grid (`GET /projects` paged, searched, filtered by
//  lifecycle status, sorted by risk), pending invitations and the time-budget (capacity) settings.
//

import Foundation
import Combine

final class ProjectsStore: ObservableObject {

    enum ViewMode: String, CaseIterable { case focus, all, forecast }

    static let searchDebounceSeconds: TimeInterval = 0.5
    static let statusMessageSeconds: TimeInterval = 3.0
    private static let viewModeKey = "kUserdefaultsProjectsListViewMode"

    private var forecastObservation: AnyCancellable?
    let forecast: LocalForecastStore
    let strings: ToDoStrings
    /// "Show in task list": filters the Tasks tab to the project (the host switches tabs).
    var onSelectProject: ((Project) -> Void)?
    /// Fires after `POST /projects` so the Tasks tab's project catalogue learns the new project.
    var onProjectCreated: ((Project) -> Void)?
    /// The open project detail, nil on the list.
    @Published private(set) var detail: ProjectDetailStore? = nil

    @Published var viewMode: ViewMode {
        didSet {
            UserDefaults.standard.set(viewMode.rawValue, forKey: ProjectsStore.viewModeKey)
            // Both list modes search now, so a query typed in one carries into the other rather
            // than being wiped on the way to "What matters" (report 2026-09-11_21-39-35).
        }
    }

    // Portfolio
    @Published private(set) var portfolio: PortfolioResponse? = nil
    @Published private(set) var isPortfolioLoading = false

    // All projects
    @Published private(set) var projects: [Project] = []
    @Published private(set) var isProjectsLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasNextPage = false
    @Published private(set) var totalCount = 0
    /// Keep newly created projects visible until the server's catalogue includes them.
    private var pinnedProjectIds: [String] = []
    private var pageCatalogue = LocalForecastProjectCatalogue()
    @Published private var resolvedProjectMetadata: [String: Project] = [:]
    @Published private var savedProjects: [String: Project] = [:]
    @Published private(set) var updatingProjectIDs: Set<String> = []
    private var resolvedMetadataAccountID = ""
    private var currentPage = ToDoPaging.firstPage
    /// Bumped on every first-page reload, so a response for a filter the user has already moved on
    /// from is dropped rather than replacing the list.
    private(set) var fetchGeneration = 0
    @Published var searchQuery = "" { didSet { scheduleSearch() } }
    @Published private(set) var debouncedSearch = ""
    private var pendingSearch: DispatchWorkItem?
    /// Narrow the list to one tag (`metadata.tags`), empty for "all tags". Written only through
    /// `applyTagFilter`, which is the whole design: see there.
    @Published private(set) var tagFilter = ""

    /// What the tag picker shows as chosen — nil is the "all tags" row.
    var tagFilterSelection: String? { tagFilter.isEmpty ? nil : tagFilter }

    @Published var statusFilter: ProjectLifecycleStatus = .active {
        didSet { if statusFilter != oldValue { loadProjects() } }
    }

    /// The NEXT task each card shows, recomputed from the project's open to-dos because the payload's
    /// own `top_priority_task` happily names a completed one (see `PortfolioNextTask`). A project id
    /// present in `resolvedNextTaskProjectIds` has been fetched; a missing entry there means "open
    /// tasks, none" rather than "not looked up yet".
    @Published private(set) var nextTaskByProjectId: [String: ProjectTopPriorityTask] = [:]
    @Published private(set) var resolvedNextTaskProjectIds: Set<String> = []
    /// Projects whose fetch failed, skipped until the next invalidation — a sweep re-runs itself when
    /// it finishes, and without this a project the server keeps refusing would spin it forever.
    private var failedNextTaskProjectIds: Set<String> = []
    private var isNextTaskLoading = false

    // Invitations / settings / create
    @Published private(set) var pendingInvitations: [Project] = []
    @Published var isInvitationsVisible = false
    @Published private(set) var settings: PortfolioSettings? = nil
    @Published private(set) var isSavingSettings = false
    @Published var isSettingsVisible = false
    @Published var isCreateVisible = false
    @Published private(set) var isCreatingProject = false
    @Published private(set) var statusMessage: String? = nil
    private var pendingStatusClear: DispatchWorkItem?

    init(strings: ToDoStrings, forecast: LocalForecastStore = LocalForecastStore()) {
        self.forecast = forecast
        self.strings = strings
        viewMode = ViewMode(rawValue: UserDefaults.standard.string(forKey: ProjectsStore.viewModeKey) ?? "") ?? .focus
        forecastObservation = forecast.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - Derived

    var localPortfolio: LocalForecastPortfolio? {
        guard forecast.hasCurrentSnapshot, let result = forecast.result else { return nil }
        return LocalForecastPortfolio.make(projects: forecast.projects.map(resolvedMetadata), forecast: result, calendar: forecast.calendar)
    }
    /// The local forecast is the better answer, but it cannot always run — it needs the server's
    /// unfinished-task filtering, which is not deployed everywhere yet. Without this fallback the
    /// whole "What matters" screen rendered as one red line and nothing else (report
    /// 2026-09-13_20-05-06); the server's own portfolio rows still group perfectly well.
    var actionGroups: PortfolioActionGroups {
        if let local = localPortfolio { return local.groups }
        return PortfolioGrouping.group(portfolio?.projects ?? [])
    }
    /// Projects the local forecast actually assessed. Empty while it is unavailable, so those cards
    /// render in the neutral tint rather than claiming a risk judgement nothing made.
    var assessedProjectIDs: Set<String> { localPortfolio?.assessedProjectIDs ?? [] }
    var risksById: [String: PortfolioProject] {
        Dictionary((portfolio?.projects ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
    var sortedProjects: [Project] {
        let source = hasCompleteActiveCatalogue ? forecast.projects : projects
        let known = Set(source.map(\.id))
        let recent = projects.filter { pinnedProjectIds.contains($0.id) && !known.contains($0.id) }
        return ProjectListPresentation.alphabetical((source + recent).map(resolvedMetadata),
            search: debouncedSearch, status: statusFilter, tag: tagFilter,
            displayName: { strings.projectName($0) })
    }
    var hasCompleteActiveCatalogue: Bool { statusFilter == .active && forecast.hasCurrentSnapshot }

    /// Every tag the user has, for the filter picker.
    ///
    /// Read from the unfiltered catalogue rather than `sortedProjects`, or choosing a tag would prune
    /// the very list the options come from and leave the picker holding only the tag already chosen.
    var knownTags: [String] {
        // The complete catalogue when there is one, plus the paged rows, which can hold a project
        // created since the snapshot. `known` de-duplicates.
        let catalogue = hasCompleteActiveCatalogue ? forecast.projects : []
        return ProjectTags.known(in: catalogue + projects)
    }
    var showsMoreProjects: Bool { hasNextPage && !hasCompleteActiveCatalogue }
    func metadata(for id: String) -> Project? {
        (forecast.projects.first { $0.id == id } ?? projects.first { $0.id == id }).map(resolvedMetadata)
    }
    private func resolvedMetadata(_ project: Project) -> Project {
        guard !resolvedMetadataAccountID.isEmpty, appdelegate?.user?.userId == resolvedMetadataAccountID else { return project }
        if let saved = savedProjects[project.id] {
            return ProjectListPresentation.reconcilingSavedProject(project, saved: saved)
        }
        guard let fresh = resolvedProjectMetadata[project.id] else { return project }
        return ProjectListPresentation.reconcilingDisplayMetadata(project, detail: fresh)
    }
    func completion(for project: Project) -> ProjectListCompletion? {
        guard forecast.hasCurrentSnapshot else { return nil }
        return forecast.projectCompletions[project.id]
    }
    var isInitialPortfolioLoading: Bool { isPortfolioLoading && portfolio == nil }
    var isRefreshing: Bool { isPortfolioLoading || isProjectsLoading }

    /// Web `getProjectsListEmptyVariant`.
    enum EmptyVariant { case none, activeZero, search, tagFiltered, completed, archived }

    var emptyVariant: EmptyVariant {
        guard sortedProjects.isEmpty, !isProjectsLoading else { return .none }
        // The tag is named before the search: it is the filter the user is least likely to remember
        // setting, because unlike a search box a chosen tag leaves no text on screen to explain the
        // emptiness. When both are on, clearing the tag is offered first and the search survives it.
        if !tagFilter.isEmpty { return .tagFiltered }
        if !debouncedSearch.isEmpty { return .search }
        switch statusFilter {
        case .completed: return .completed
        case .archived: return .archived
        case .active: return .activeZero
        }
    }

    // MARK: - Loading

    /// Web `useProjectsListData` bootstrap: invitations + portfolio + first projects page.
    func screenAppeared() {
        forecast.refreshIfNeeded()
        loadPortfolio()
        loadProjects()
        loadInvitations()
    }

    func refresh() {
        forecast.refresh()
        loadPortfolio()
        loadProjects()
        loadInvitations()
    }

    func loadPortfolio() {
        isPortfolioLoading = true
        allApiObject.getPortfolio { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isPortfolioLoading = false
                guard let result = result else {
                    self.showStatus(self.strings[.requestFailed])
                    return
                }
                self.portfolio = result
                DayPlanPushedTasks.shared.update(from: result)   // the Day Plan's "Doesn't fit today" hint
                self.invalidateNextTasks(for: result.projects.map { $0.id })
            }
        }
    }

    func loadProjects() {
        // Keep acknowledged edits while list/forecast reads are in flight. A later server
        // updated_at supersedes them during reconciliation.
        fetchGeneration += 1
        let generation = fetchGeneration
        isProjectsLoading = true
        fetchProjects(page: ToDoPaging.firstPage, generation: generation) { [weak self] in
            guard generation == self?.fetchGeneration else { return }
            self?.isProjectsLoading = false
        }
    }

    func loadMore() {
        guard hasNextPage, !isLoadingMore, !isProjectsLoading else { return }
        isLoadingMore = true
        fetchProjects(page: currentPage + 1, generation: fetchGeneration) { [weak self] in self?.isLoadingMore = false }
    }

    private func fetchProjects(page: Int, generation: Int, completion: @escaping () -> Void) {
        allApiObject.getProjectsPage(page: page, take: ToDoPaging.projectsPerPage, search: debouncedSearch,
                                     status: statusFilter, tag: tagFilter) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                defer { completion() }
                guard generation == self.fetchGeneration else { return }
                guard let result = result else {
                    self.showStatus(self.strings[.requestFailed])
                    return
                }
                if page == ToDoPaging.firstPage {
                    self.pageCatalogue = LocalForecastProjectCatalogue()
                }
                guard self.pageCatalogue.append(result.items) else {
                    self.showStatus(self.strings[.requestFailed])
                    return
                }
                if page == ToDoPaging.firstPage {
                    // The server's first page may not include a pinned newcomer yet; keep it.
                    let fetchedIds = Set(result.items.map { $0.id })
                    let pinned = self.projects.filter { self.pinnedProjectIds.contains($0.id) && !fetchedIds.contains($0.id) }
                    self.projects = pinned + self.pageCatalogue.projects
                } else {
                    let fetchedIds = Set(self.pageCatalogue.projects.map(\.id))
                    let pinned = self.projects.filter { self.pinnedProjectIds.contains($0.id) && !fetchedIds.contains($0.id) }
                    self.projects = pinned + self.pageCatalogue.projects
                }
                self.currentPage = page
                self.hasNextPage = result.hasNextPage
                self.totalCount = result.totalCount
                self.invalidateNextTasks(for: result.items.map { $0.id })
            }
        }
    }

    // MARK: - Card "NEXT" task

    /// The task a project card offers as the next one to do, or nil when the project has none open.
    func nextTask(for projectId: String) -> ProjectTopPriorityTask? {
        if let result = forecast.result {
            let open = result.tasks.filter { $0.task.projectID == projectId && !$0.task.completed }
            let ids = Set(open.map { $0.task.id })
            if let next = PortfolioNextTask.pick(from: forecast.tasks.filter { ids.contains($0.id) }) { return next }
            // Local-only Day Plan tasks are also in the complete snapshot, without a remote TOP score.
            return open.first.map { ProjectTopPriorityTask(id: $0.task.id, title: forecast.taskName($0.task.id), top_score: nil) }
        }
        return nextTaskByProjectId[projectId]
    }

    /// True until the project's to-dos have come back — the row shows nothing rather than guessing.
    func isNextTaskPending(_ projectId: String) -> Bool { forecast.result == nil && !resolvedNextTaskProjectIds.contains(projectId) }

    /// Freshly fetched projects may have had tasks completed elsewhere, so their NEXT task is re-resolved.
    /// The cached value stays visible meanwhile — dropping it would blank every card on each refresh.
    private func invalidateNextTasks(for projectIds: [String]) {
        resolvedNextTaskProjectIds.subtract(projectIds)
        failedNextTaskProjectIds.subtract(projectIds)
        loadNextTasks()
    }

    /// Web `fetchPortfolioTopPriorityTasks`: the listed projects that have tasks, plus the
    /// portfolio-only ones, fetched `PortfolioNextTask.maxConcurrency` at a time.
    private func loadNextTasks() {
        let targets = PortfolioNextTask.fetchTargets(projects: projects,
                                                     additionalProjectIds: (portfolio?.projects ?? []).map { $0.id })
        let targetIds = Set(targets.map { $0.projectId })
        // A project with no tasks needs no request — it has no next task, and its row says so instead
        // of sitting blank forever.
        for project in projects where !targetIds.contains(project.id) {
            resolvedNextTaskProjectIds.insert(project.id)
            nextTaskByProjectId[project.id] = nil
        }
        guard !isNextTaskLoading else { return }
        let pending = PortfolioNextTask.uncached(targets, resolved: resolvedNextTaskProjectIds.union(failedNextTaskProjectIds))
        guard !pending.isEmpty else { return }
        isNextTaskLoading = true
        fetchNextTasks(pending.reversed())
    }

    /// `remaining` is reversed so `popLast()` keeps the caller's order.
    private func fetchNextTasks(_ remaining: [PortfolioNextTask.FetchTarget]) {
        var queue = remaining
        let batch = (0..<PortfolioNextTask.maxConcurrency).compactMap { _ in queue.popLast() }
        guard !batch.isEmpty else {
            isNextTaskLoading = false
            // Projects invalidated while this sweep was in flight were not in its queue.
            loadNextTasks()
            return
        }
        let group = DispatchGroup()
        for target in batch {
            group.enter()
            allApiObject.getProjectNextTaskCandidates(target: target) { [weak self] tasks in
                DispatchQueue.main.async {
                    defer { group.leave() }
                    guard let self = self else { return }
                    // A failed fetch stays unresolved, so the next refresh retries it — but is parked
                    // meanwhile rather than retried immediately by the sweep's own tail call.
                    guard let tasks = tasks else {
                        self.failedNextTaskProjectIds.insert(target.projectId)
                        return
                    }
                    self.resolvedNextTaskProjectIds.insert(target.projectId)
                    self.nextTaskByProjectId[target.projectId] = PortfolioNextTask.pick(from: tasks)
                }
            }
        }
        group.notify(queue: .main) { [weak self] in self?.fetchNextTasks(queue) }
    }

    private func loadInvitations() {
        allApiObject.getPendingProjectInvitations { [weak self] projects in
            DispatchQueue.main.async { self?.pendingInvitations = projects ?? [] }
        }
    }

    /// Narrow the list to `tag`, or to nothing when it is nil. Reloads at once, like `statusFilter`
    /// and unlike `searchQuery`.
    ///
    /// Immediate is safe because the picker is a `SearchableComboBoxField` in `.whenResolved` mode:
    /// it calls this only when the box names exactly one tag (or is empty), never while the text is
    /// still ambiguous. Two earlier attempts are worth knowing about, because each fixed the other's
    /// bug and reintroduced its own:
    ///
    /// - **Per keystroke** was the first shape. `resolve` answers nil while the typed text matches
    ///   more than one tag, so narrowing towards `phd` fetched the *unfiltered* list mid-word, once
    ///   per letter.
    /// - **Debounced** hid that behind half a second, and so applied the tag only after the user had
    ///   stopped and looked away. That read as "applies on blur", which the PO rejected.
    /// - **Selection-only** then refused to apply typed text at all, waiting for a pop-up row or
    ///   Return. Typing `phd` and looking at the screen did nothing whatsoever, which is
    ///   indistinguishable from the original bug — the PO's verdict was "no improvement".
    ///
    /// Resolution, not timing and not gesture, is the thing that actually separates "still typing"
    /// from "means `phd`". `applyTagFilter` returning early on an unchanged tag is what keeps the
    /// remaining keystrokes free: `ph`, `phd` both resolve to `phd`, so only the first fetches.
    ///
    /// Independent of `searchQuery` on purpose: the two combine as AND (the server ANDs them, and
    /// `alphabetical` ANDs them locally), and clearing one leaves the other alone.
    func applyTagFilter(_ tag: String?) {
        let chosen = ProjectTags.normalize(tag ?? "") ?? ""
        guard chosen != tagFilter else { return }
        tagFilter = chosen
        loadProjects()
    }

    private func scheduleSearch() {
        pendingSearch?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let trimmed = self.searchQuery.trimmingCharacters(in: .whitespaces)
            guard trimmed != self.debouncedSearch else { return }
            self.debouncedSearch = trimmed
            self.loadProjects()
        }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ProjectsStore.searchDebounceSeconds, execute: work)
    }

    // MARK: - Actions

    /// Tapping a card opens the project detail (web navigates to `/projects/:id`).
    func open(_ project: Project) {
        let account = appdelegate?.user?.userId ?? ""
        let store = ProjectDetailStore(project: project, strings: strings)
        store.onProjectLoaded = { [weak self] fresh in
            guard !account.isEmpty, appdelegate?.user?.userId == account else { return }
            if self?.resolvedMetadataAccountID != account { self?.resolvedProjectMetadata = [:] }
            self?.resolvedMetadataAccountID = account
            self?.resolvedProjectMetadata[fresh.id] = fresh
        }
        store.onProjectChanged = { [weak self, weak store] in
            guard !account.isEmpty, appdelegate?.user?.userId == account else { return }
            if let updated = store?.project { self?.acceptSavedProject(updated, account: account) }
            self?.forecast.refresh()
            self?.loadPortfolio()
            self?.loadProjects()
        }
        store.onClose = { [weak self] in self?.closeDetail() }
        detail = store
        store.screenAppeared()
    }

    func open(portfolioProject: PortfolioProject) {
        open(forecast.projects.first { $0.id == portfolioProject.id } ?? projects.first { $0.id == portfolioProject.id } ?? Project(id: portfolioProject.id, name: portfolioProject.name))
    }

    func closeDetail() {
        // Tasks ticked off inside the detail change what the card should offer next.
        if let projectId = detail?.project.id { invalidateNextTasks(for: [projectId]) }
        detail = nil
    }

    func showInTaskList(_ project: Project) {
        onSelectProject?(project)
    }

    /// `POST /projects { name[, due_date] }` then, like the web, re-fetch the portfolio + list. The
    /// created project is shown at once — on "All projects", pinned to the top — rather than only
    /// after the re-fetch (where it could land beyond the first page).
    func createProject(named name: String, dueDate: Date?, outcome: Int? = nil,
                       completion: @escaping (Bool) -> Void) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isCreatingProject else { completion(false); return }
        isCreatingProject = true
        allApiObject.createToDoProject(name: trimmed, dueDate: dueDate, outcome: outcome) { [weak self] project, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCreatingProject = false
                guard let project = project else {
                    self.showStatus(ToDoStore.failureText(self.strings[.couldNotCreateProject], reason: serverMessage))
                    completion(false)
                    return
                }
                self.isCreateVisible = false
                self.insertProject(project)
                self.viewMode = .all
                self.onProjectCreated?(project)
                self.showStatus(self.strings[.projectCreated])
                self.forecast.markDirty()
                self.loadPortfolio()
                self.loadProjects()
                completion(true)
            }
        }
    }

    /// Adds a project created elsewhere (the task editor's inline field) to the list, pinned first.
    func insertProject(_ project: Project) {
        if !pinnedProjectIds.contains(project.id) { pinnedProjectIds.insert(project.id, at: 0) }
        guard !projects.contains(where: { $0.id == project.id }) else { return }
        projects.insert(project, at: 0)
        totalCount += 1
    }

    /// An explicit project edit bypasses the automatic forecast cache after the API acknowledges it.
    func setDueDate(projectId: String, day: Date?) {
        saveProject(id: projectId, body: ["due_date": day.map { ToDoDates.ymd($0) as Any } ?? NSNull()],
                    message: strings[.projectUpdated])
    }

    func canManage(_ project: Project) -> Bool {
        ProjectPermissions.canManageMembers(ProjectPermissions.viewerRole(in: project, userId: appdelegate?.user?.userId))
    }

    func setLifecycle(_ project: Project, status: ProjectLifecycleStatus) {
        guard canManage(project), status != project.lifecycleStatus else { return }
        let key: ToDoStringKey = status == .completed ? .projectMarkedComplete : status == .archived ? .projectArchived : .projectRestored
        saveProject(id: project.id, body: ["status": status.rawValue], message: strings[key])
    }

    private func saveProject(id: String, body: [String: Any], message: String) {
        let account = appdelegate?.user?.userId ?? ""
        guard !account.isEmpty, !updatingProjectIDs.contains(id) else { return }
        updatingProjectIDs.insert(id)
        allApiObject.updateProject(id: id, body: body, expectedAccountID: account) { [weak self] project, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updatingProjectIDs.remove(id)
                guard appdelegate?.user?.userId == account else { return }
                guard let project = project, project.id == id else {
                    self.showStatus(ToDoStore.failureText(self.strings[.couldNotUpdateProject], reason: serverMessage))
                    return
                }
                self.acceptSavedProject(project, account: account)
                self.showStatus(message)
                self.forecast.refresh()
                self.loadPortfolio()
                self.loadProjects()
            }
        }
    }

    private func acceptSavedProject(_ project: Project, account: String) {
        guard !account.isEmpty, appdelegate?.user?.userId == account else { return }
        if resolvedMetadataAccountID != account {
            savedProjects = [:]; resolvedProjectMetadata = [:]
        }
        resolvedMetadataAccountID = account
        savedProjects[project.id] = project
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = ProjectListPresentation.reconcilingSavedProject(projects[index], saved: project)
        }
    }

    // MARK: - Merging a project into another (report 2026-09-11_07-31-36)

    /// The project whose "Merge into…" sheet is open, if any.
    @Published var mergeSource: Project? = nil
    @Published var mergeQuery = ""
    @Published private(set) var mergeCandidates: [Project] = []
    @Published private(set) var isLoadingMergeCandidates = false
    /// Set while a merge is running, so the sheet can show progress and refuse a second one.
    @Published private(set) var mergingIntoProjectID: String? = nil

    var visibleMergeCandidates: [Project] {
        guard let source = mergeSource else { return [] }
        return ProjectMerge.destinations(mergeCandidates, excluding: source,
                                         query: mergeQuery, userId: appdelegate?.user?.userId)
    }

    /// Opens the merge picker. The destination list is every active project, not just the loaded
    /// page — the whole point is finding the near-duplicate that is probably further down the list.
    func beginMerge(_ project: Project) {
        guard canManage(project), !project.isSynced else { return }
        mergeSource = project
        mergeQuery = ""
        mergingIntoProjectID = nil
        guard mergeCandidates.isEmpty else { return }
        let account = appdelegate?.user?.userId ?? ""
        guard !account.isEmpty else { return }
        isLoadingMergeCandidates = true
        allApiObject.getAllActiveProjects { [weak self] projects in
            DispatchQueue.main.async {
                guard let self = self, appdelegate?.user?.userId == account else { return }
                self.isLoadingMergeCandidates = false
                self.mergeCandidates = projects ?? []
                if projects == nil { self.showStatus(self.strings[.couldNotLoadProjects]) }
            }
        }
    }

    func cancelMerge() {
        guard mergingIntoProjectID == nil else { return }
        mergeSource = nil
        mergeQuery = ""
    }

    /// Moves every task of the open merge source into `target`, then archives the emptied source.
    /// Tasks owned by an external provider are left where they are and reported, and a single
    /// failed write stops the source being archived — a half-merged project must stay visible.
    func merge(into target: Project) {
        let account = appdelegate?.user?.userId ?? ""
        guard let source = mergeSource, !account.isEmpty, mergingIntoProjectID == nil,
              ProjectMerge.canMerge(source, into: target, userId: account) else { return }
        mergingIntoProjectID = target.id
        loadTasks(ofProject: source.id, account: account, page: ToDoPaging.firstPage, accumulated: []) { [weak self] tasks in
            guard let self = self, let tasks = tasks else {
                self?.finishMerge(source: source, target: target, outcome: nil, account: account)
                return
            }
            self.moveTasks(tasks, from: source, to: target, account: account,
                           outcome: ProjectMerge.Outcome(moved: 0, skipped: 0, failed: 0))
        }
    }

    private func loadTasks(ofProject id: String, account: String, page: Int, accumulated: [ToDoTask],
                           completion: @escaping ([ToDoTask]?) -> Void) {
        allApiObject.getToDoPage(ToDoListQuery(page: page, projectId: id)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, appdelegate?.user?.userId == account else { completion(nil); return }
                guard let result = result else { completion(accumulated.isEmpty ? nil : accumulated); return }
                let known = Set(accumulated.map { $0.id })
                let merged = accumulated + result.data.filter { !known.contains($0.id) }
                guard result.meta?.hasNextPage == true, !result.data.isEmpty,
                      page < ToDoPaging.allProjectsMaxPages else { completion(merged); return }
                self.loadTasks(ofProject: id, account: account, page: page + 1, accumulated: merged, completion: completion)
            }
        }
    }

    /// One task at a time: the merge is a sequence of independent writes, and sending them together
    /// would make a partial failure impossible to report accurately.
    private func moveTasks(_ tasks: [ToDoTask], from source: Project, to target: Project,
                           account: String, outcome: ProjectMerge.Outcome) {
        var outcome = outcome
        var remaining = tasks
        while let task = remaining.first {
            remaining.removeFirst()
            switch ProjectMerge.reassignment(of: task, from: source, to: target) {
            case .failure:
                outcome.skipped += 1
            case .success(let body):
                let rest = remaining
                let pending = outcome
                allApiObject.upsertToDo(body, expectedAccountID: account) { [weak self] saved, _, _ in
                    DispatchQueue.main.async {
                        guard let self = self, appdelegate?.user?.userId == account else { return }
                        var next = pending
                        if saved == nil { next.failed += 1 } else { next.moved += 1 }
                        self.moveTasks(rest, from: source, to: target, account: account, outcome: next)
                    }
                }
                return
            }
        }
        finishMerge(source: source, target: target, outcome: outcome, account: account)
    }

    private func finishMerge(source: Project, target: Project, outcome: ProjectMerge.Outcome?, account: String) {
        guard appdelegate?.user?.userId == account else { return }
        mergingIntoProjectID = nil
        mergeSource = nil
        mergeQuery = ""
        guard let outcome = outcome else {
            showStatus(strings[.couldNotMergeProject]); return
        }
        showStatus(strings.projectMergeResult(moved: outcome.moved, skipped: outcome.skipped,
                                              failed: outcome.failed, target: target.name))
        // The Day Plan stores a project by NAME, and archiving the source hides it from `GET /projects`,
        // so a task left naming it would have the next sync create it again.
        DayPlanTaskStore.shared.followProjectMerge(from: source.name, to: target.name, targetID: target.id)
        if outcome.archivesSource, source.lifecycleStatus == .active {
            saveProject(id: source.id, body: ["status": ProjectLifecycleStatus.archived.rawValue],
                        message: strings.projectMergeArchived(source.name))
        } else {
            forecast.refresh()
            loadPortfolio()
            loadProjects()
        }
    }

    func respondToInvitation(_ project: Project, accept: Bool) {
        allApiObject.respondToProjectInvitation(projectId: project.id, accept: accept) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard success else {
                    self.showStatus(self.strings[.couldNotRespondInvitation])
                    return
                }
                self.pendingInvitations.removeAll { $0.id == project.id }
                self.showStatus(self.strings[accept ? .invitationAccepted : .invitationDeclined])
                if accept {
                    self.forecast.markDirty()
                    self.loadPortfolio(); self.loadProjects(); self.loadInvitations()
                }
            }
        }
    }

    // MARK: - Capacity settings

    func openSettings() {
        isSettingsVisible = true
        allApiObject.getPortfolioSettings { [weak self] settings in
            DispatchQueue.main.async { self?.settings = settings }
        }
    }

    func saveSettings(_ settings: PortfolioSettings) {
        isSavingSettings = true
        allApiObject.updatePortfolioSettings(settings) { [weak self] saved in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSavingSettings = false
                guard let saved = saved else {
                    self.showStatus(self.strings[.couldNotSaveCapacity])
                    return
                }
                self.settings = saved
                self.isSettingsVisible = false
                self.showStatus(self.strings[.capacitySaved])
                self.forecast.refresh()
                self.loadPortfolio()
            }
        }
    }

    // MARK: - Status toast

    private func showStatus(_ message: String) {
        statusMessage = message
        pendingStatusClear?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.statusMessage = nil }
        pendingStatusClear = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ProjectsStore.statusMessageSeconds, execute: work)
    }
}

struct ProjectListCompletion: Equatable {
    let completed: Int
    let total: Int
    var percent: Int { Int((Double(completed) / Double(total) * 100).rounded(.down)) }
}

enum ProjectListPresentation {
    /// Project-wide server counters include completed history without downloading those task rows.
    /// Call only for a single known source; native/imported unions have different denominators.
    static func completionFromCounts(_ project: Project) -> ProjectListCompletion? {
        guard let total = project.task_count, let unfinished = project.uncompleted_task_count,
              total > 0, unfinished >= 0, unfinished <= total else { return nil }
        return ProjectListCompletion(completed: total - unfinished, total: total)
    }
    static func reconcilingDisplayMetadata(_ project: Project, detail: Project) -> Project {
        guard project.id == detail.id else { return project }
        if let catalogueDate = ToDoDates.parse(project.updated_at), let detailDate = ToDoDates.parse(detail.updated_at),
           catalogueDate > detailDate { return project }
        var result = project
        result.name = detail.name
        if result.synced_project_id == nil { result.synced_project_id = detail.synced_project_id }
        if result.synced_platform == nil, result.synced_project_id == detail.synced_project_id {
            result.synced_platform = detail.synced_platform
        }
        return result
    }

    /// Successful write responses are authoritative, including null due dates and lifecycle changes.
    /// Display-only detail reconciliation remains separate from this acknowledged edit path.
    static func reconcilingSavedProject(_ project: Project, saved: Project) -> Project {
        guard project.id == saved.id else { return project }
        if let currentDate = ToDoDates.parse(project.updated_at), let savedDate = ToDoDates.parse(saved.updated_at),
           currentDate > savedDate { return project }
        var result = preservingSync(saved, from: project)
        result.task_count = saved.task_count ?? project.task_count
        result.uncompleted_task_count = saved.uncompleted_task_count ?? project.uncompleted_task_count
        return result
    }

    static func preservingSync(_ fresh: Project, from previous: Project) -> Project {
        guard fresh.id == previous.id else { return fresh }
        var result = fresh
        if result.synced_project_id == nil { result.synced_project_id = previous.synced_project_id }
        if result.synced_platform == nil, result.synced_project_id == previous.synced_project_id {
            result.synced_platform = previous.synced_platform
        }
        return result
    }

    /// `tag` is applied here as well as being sent to the server: when a current forecast snapshot
    /// makes the active catalogue complete, the screen renders from that local set without re-fetching,
    /// so a server-only filter would appear to do nothing. Both halves AND with `search`.
    static func alphabetical(_ projects: [Project], search: String, status: ProjectLifecycleStatus,
                             tag: String = "", displayName: (String) -> String) -> [Project] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let wanted = ProjectTags.normalize(tag)
        func matchesTag(_ project: Project) -> Bool {
            guard let wanted = wanted else { return true }
            return project.tagList.contains(wanted)
        }
        return projects.filter {
            $0.lifecycleStatus == status
                && (query.isEmpty || displayName($0.name).localizedStandardContains(query))
                && matchesTag($0)
        }.sorted {
            let comparison = displayName($0.name).localizedStandardCompare(displayName($1.name))
            return comparison == .orderedSame ? $0.id < $1.id : comparison == .orderedAscending
        }
    }


}

extension Project {
    /// A minimal project when only the portfolio row is known (tapping a "What matters" card).
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
