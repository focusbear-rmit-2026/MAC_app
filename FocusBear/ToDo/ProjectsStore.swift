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

final class ProjectsStore: ObservableObject {

    enum ViewMode: String, CaseIterable { case focus, all }

    static let searchDebounceSeconds: TimeInterval = 0.5
    static let statusMessageSeconds: TimeInterval = 3.0
    private static let viewModeKey = "kUserdefaultsProjectsListViewMode"

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
            // Web: switching to "What matters" clears the search.
            if viewMode == .focus { searchQuery = "" }
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
    /// Projects created this session stay at the top of "All projects": risk-sorting would put a
    /// deadline-less newcomer last, past the first page, and the user would think it wasn't created.
    private var pinnedProjectIds: [String] = []
    private var currentPage = ToDoPaging.firstPage
    private var fetchGeneration = 0
    @Published var searchQuery = "" { didSet { scheduleSearch() } }
    @Published private(set) var debouncedSearch = ""
    private var pendingSearch: DispatchWorkItem?
    @Published var statusFilter: ProjectLifecycleStatus = .active {
        didSet { if statusFilter != oldValue { loadProjects() } }
    }

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

    init(strings: ToDoStrings) {
        self.strings = strings
        viewMode = ViewMode(rawValue: UserDefaults.standard.string(forKey: ProjectsStore.viewModeKey) ?? "") ?? .focus
    }

    // MARK: - Derived

    var actionGroups: PortfolioActionGroups { PortfolioGrouping.group(portfolio?.projects ?? []) }
    var risksById: [String: PortfolioProject] {
        Dictionary((portfolio?.projects ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
    var sortedProjects: [Project] {
        let pinned = pinnedProjectIds.compactMap { id in projects.first { $0.id == id } }
        let rest = projects.filter { !pinnedProjectIds.contains($0.id) }
        return pinned + PortfolioGrouping.sortByRisk(rest, risks: risksById)
    }
    var isInitialPortfolioLoading: Bool { isPortfolioLoading && portfolio == nil }
    var isRefreshing: Bool { isPortfolioLoading || isProjectsLoading }

    /// Web `getProjectsListEmptyVariant`.
    enum EmptyVariant { case none, activeZero, search, completed, archived }

    var emptyVariant: EmptyVariant {
        guard projects.isEmpty, !isProjectsLoading else { return .none }
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
        refresh()
    }

    func refresh() {
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
                if let result = result { self.portfolio = result } else { self.showStatus(self.strings[.requestFailed]) }
            }
        }
    }

    func loadProjects() {
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
        allApiObject.getProjectsPage(page: page, take: ToDoPaging.projectsPerPage, search: debouncedSearch, status: statusFilter) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                defer { completion() }
                guard generation == self.fetchGeneration else { return }
                guard let result = result else {
                    self.showStatus(self.strings[.requestFailed])
                    return
                }
                if page == ToDoPaging.firstPage {
                    // The server's first page may not include a just-created pinned project yet, so keep
                    // it prepended — but ONLY in the default list. During a search, or under a non-Active
                    // filter, a pinned project the server didn't return genuinely doesn't belong in these
                    // results (otherwise it shows up in every search, matching or not).
                    let keepPinned = self.debouncedSearch.isEmpty && self.statusFilter == .active
                    let fetchedIds = Set(result.items.map { $0.id })
                    let pinned = keepPinned ? self.projects.filter { self.pinnedProjectIds.contains($0.id) && !fetchedIds.contains($0.id) } : []
                    self.projects = pinned + result.items
                } else {
                    let known = Set(self.projects.map { $0.id })
                    self.projects.append(contentsOf: result.items.filter { !known.contains($0.id) })
                }
                self.currentPage = page
                self.hasNextPage = result.hasNextPage
                self.totalCount = result.totalCount
            }
        }
    }

    private func loadInvitations() {
        allApiObject.getPendingProjectInvitations { [weak self] projects in
            DispatchQueue.main.async { self?.pendingInvitations = projects ?? [] }
        }
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
        let store = ProjectDetailStore(project: project, strings: strings)
        store.onProjectChanged = { [weak self] in
            self?.loadPortfolio()
            self?.loadProjects()
        }
        store.onClose = { [weak self] in self?.closeDetail() }
        detail = store
        store.screenAppeared()
    }

    func open(portfolioProject: PortfolioProject) {
        open(projects.first { $0.id == portfolioProject.id } ?? Project(id: portfolioProject.id, name: portfolioProject.name))
    }

    func closeDetail() {
        detail = nil
    }

    func showInTaskList(_ project: Project) {
        onSelectProject?(project)
    }

    /// `POST /projects { name[, due_date] }` then, like the web, re-fetch the portfolio + list. The
    /// created project is shown at once — on "All projects", pinned to the top — rather than only
    /// after the re-fetch (where it could land beyond the first page).
    func createProject(named name: String, dueDate: Date?, completion: @escaping (Bool) -> Void) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isCreatingProject else { completion(false); return }
        isCreatingProject = true
        allApiObject.createToDoProject(name: trimmed, dueDate: dueDate) { [weak self] project, serverMessage in
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

    /// Web `EditableDueMeta`: `PUT /projects/:id { due_date }` at local midday, then re-fetch the portfolio.
    func setDueDate(projectId: String, day: Date?) {
        var body: [String: Any] = [:]
        if let day = day, let midday = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: day) {
            body["due_date"] = ISO8601DateFormatter().string(from: midday)
        } else {
            body["due_date"] = NSNull()
        }
        allApiObject.updateProject(id: projectId, body: body) { [weak self] project in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard project != nil else {
                    self.showStatus(self.strings[.couldNotUpdateProject])
                    return
                }
                self.showStatus(self.strings[.projectUpdated])
                self.loadPortfolio()
                self.loadProjects()
            }
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
                if accept { self.refresh() }
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

extension Project {
    /// A minimal project when only the portfolio row is known (tapping a "What matters" card).
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
