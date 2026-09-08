//
//  ProjectDetailStore.swift
//  Focus Bear
//
//  State for one open project — the native version of the web's `ProjectDetailPage`: its tasks
//  (`GET /projects/:id/todos`, list or board by the project's columns), members (invite / role /
//  remove / leave), settings (`PUT /projects/:id`), lifecycle and delete, and the shared project
//  notes (`/projects/:id/notes`, read-only here).
//

import Foundation

final class ProjectDetailStore: ObservableObject {

    enum PageView: String, CaseIterable { case tasks, notes }
    enum TasksMode: String, CaseIterable { case list, board }

    /// Confirmations the view shows as alerts.
    enum PendingConfirmation: Identifiable {
        case leave, delete, markComplete, archive, restore
        case deleteNote(ProjectNote)

        var id: String {
            switch self {
            case .leave: return "leave"
            case .delete: return "delete"
            case .markComplete: return "markComplete"
            case .archive: return "archive"
            case .restore: return "restore"
            case .deleteNote(let note): return "deleteNote-\(note.id)"
            }
        }
    }

    private static let tasksModeKey = "kUserdefaultsProjectDetailTasksMode"
    static let nameMaxLength = 80
    static let defaultStatusColor = "#6B7280"

    let strings: ToDoStrings
    /// Fires when the project changed in a way the list / portfolio should reflect (settings, delete,
    /// leave, lifecycle) — the parent store re-fetches.
    var onProjectChanged: (() -> Void)?
    /// The parent pops the detail (delete / leave / not found).
    var onClose: (() -> Void)?

    @Published private(set) var project: Project
    @Published private(set) var isLoading = false
    @Published private(set) var notFound = false
    @Published var pageView: PageView = .tasks
    @Published var pendingConfirmation: PendingConfirmation? = nil
    @Published var isMembersVisible = false
    @Published var isSettingsVisible = false
    @Published private(set) var statusMessage: String? = nil
    private var pendingStatusClear: DispatchWorkItem?

    // Tasks
    @Published private(set) var tasks: [ToDoTask] = []
    @Published private(set) var isTasksLoading = false
    @Published private(set) var updatingTaskIds: Set<String> = []
    @Published var tasksMode: TasksMode {
        didSet { UserDefaults.standard.set(tasksMode.rawValue, forKey: ProjectDetailStore.tasksModeKey) }
    }
    @Published var sortMode: ToDoSortMode = .smart {
        didSet { if sortMode != oldValue { reloadTasks() } }
    }
    @Published var searchQuery = ""

    // Members
    @Published private(set) var isInviting = false
    @Published private(set) var busyMemberIds: Set<String> = []

    // Settings
    @Published private(set) var isSavingSettings = false

    // Notes
    @Published private(set) var notes: [ProjectNote] = []
    @Published private(set) var isNotesLoading = false
    @Published private(set) var openNote: ProjectNote? = nil
    @Published private(set) var isNoteLoading = false

    init(project: Project, strings: ToDoStrings) {
        self.project = project
        self.strings = strings
        tasksMode = TasksMode(rawValue: UserDefaults.standard.string(forKey: ProjectDetailStore.tasksModeKey) ?? "") ?? .list
    }

    // MARK: - Derived

    private var currentUserId: String { appdelegate?.user?.userId ?? "" }
    var viewerRole: ProjectMemberRole? { ProjectPermissions.viewerRole(in: project, userId: currentUserId) }
    var canOpenMembers: Bool { ProjectPermissions.canManageMembers(viewerRole) }
    var canOpenSettings: Bool { ProjectPermissions.canViewSettings(viewerRole) }
    var canLeave: Bool { ProjectPermissions.canLeave(viewerRole) }
    var canAddTask: Bool { ProjectPermissions.canAddTask(viewerRole) }
    var canEditName: Bool { ProjectPermissions.canEditName(viewerRole) }
    var canDeleteProject: Bool { ProjectPermissions.canDeleteProject(viewerRole) }
    var canManageLifecycle: Bool { ProjectPermissions.canManageMembers(viewerRole) }
    var members: [ProjectMember] { project.members ?? [] }

    var columns: [ProjectColumn] { ProjectKanban.columns(for: project, defaultLabels: strings.columnTitles()) }

    /// Web list-mode filtering: name substring, then the active sort.
    var visibleTasks: [ToDoTask] {
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = query.isEmpty ? tasks : tasks.filter { $0.title.lowercased().contains(query) }
        return ToDoSorting.sort(filtered, by: sortMode)
    }

    func tasks(in column: ProjectColumn) -> [ToDoTask] {
        visibleTasks.filter { ProjectKanban.columnId(for: $0, columns: columns, usesCustomStatuses: project.usesCustomStatuses) == column.id }
    }

    func isMe(_ member: ProjectMember) -> Bool { member.user_id == currentUserId && !currentUserId.isEmpty }

    /// Web `getMemberDisplayName`: You → email → Project Owner → Unknown User.
    func displayName(_ member: ProjectMember) -> String {
        if isMe(member) { return strings[.you] }
        if let email = member.email, !email.isEmpty { return email }
        return member.memberRole == .owner ? strings[.projectOwner] : strings[.unknownUser]
    }

    func actions(for member: ProjectMember) -> ProjectPermissions.MemberActions {
        ProjectPermissions.memberActions(viewer: viewerRole, target: member.memberRole, isTargetCurrentUser: isMe(member))
    }

    // MARK: - Loading

    func screenAppeared() {
        reloadProject()
        reloadTasks()
    }

    func reloadProject() {
        isLoading = true
        allApiObject.getProject(id: project.id) { [weak self] project in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                guard let project = project else {
                    self.notFound = true
                    return
                }
                self.project = project
            }
        }
    }

    func reloadTasks() {
        isTasksLoading = true
        let sort = sortMode
        allApiObject.getProjectTasks(project: project, sortMode: sort) { [weak self] page in
            DispatchQueue.main.async {
                guard let self = self, sort == self.sortMode else { return }
                self.isTasksLoading = false
                if let page = page { self.tasks = page.data } else { self.showStatus(self.strings[.requestFailed]) }
            }
        }
    }

    // MARK: - Tasks

    /// Web `moveProjectDetailsKanbanTask`: optimistic column move, `PUT /to-do`, rollback + toast.
    func move(_ task: ToDoTask, toColumn columnId: String) {
        guard ProjectKanban.columnId(for: task, columns: columns, usesCustomStatuses: project.usesCustomStatuses) != columnId else { return }
        var moved = ProjectKanban.moved(task, toColumn: columnId, columns: columns, usesCustomStatuses: project.usesCustomStatuses)
        moved.tags = ProjectKanban.tags(for: moved, project: project)
        moved.project_id = project.isSynced ? moved.project_id : project.id
        persist(moved, revertTo: task)
    }

    /// Checkbox toggle in list mode (web `buildProjectDetailsTaskStatusToggle`).
    func toggleComplete(_ task: ToDoTask) {
        let updated = ToDoStatusToggle.apply(to: task, completed: !task.isCompleted, customStatuses: project.usesCustomStatuses ? project.customStatuses : [])
        persist(updated, revertTo: task)
    }

    private func persist(_ task: ToDoTask, revertTo previous: ToDoTask) {
        replaceLocally(task)
        updatingTaskIds.insert(task.id)
        allApiObject.upsertToDo(ToDoUpsertBody.make(from: task)) { [weak self] saved, statusCode, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updatingTaskIds.remove(task.id)
                guard (200..<300).contains(statusCode) else {
                    self.replaceLocally(previous)
                    self.showStatus(ToDoStore.failureText(self.strings.format(.couldNotUpdateTask, ToDoStrings.titleToken, task.title), reason: serverMessage))
                    return
                }
                self.replaceLocally(saved ?? task)
            }
        }
    }

    private func replaceLocally(_ task: ToDoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) { tasks[index] = task } else { tasks.insert(task, at: 0) }
    }

    // MARK: - Members

    func invite(email: String, role: ProjectMemberRole, completion: @escaping (Bool) -> Void) {
        isInviting = true
        allApiObject.inviteProjectMember(projectId: project.id, email: email, role: role.rawValue) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isInviting = false
                self.showStatus(self.strings[success ? .invitationSent : .couldNotSendInvitation])
                if success { self.reloadProject() }
                completion(success)
            }
        }
    }

    func remove(_ member: ProjectMember) {
        busyMemberIds.insert(member.id)
        allApiObject.removeProjectMember(projectId: project.id, memberId: member.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.busyMemberIds.remove(member.id)
                self.showStatus(self.strings[success ? .memberRemoved : .couldNotRemoveMember])
                if success { self.reloadProject() }
            }
        }
    }

    func changeRole(_ member: ProjectMember, to role: ProjectMemberRole) {
        guard member.memberRole != role else { return }
        busyMemberIds.insert(member.id)
        allApiObject.updateProjectMemberRole(projectId: project.id, memberId: member.id, role: role.rawValue) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.busyMemberIds.remove(member.id)
                self.showStatus(self.strings[success ? .memberRoleUpdated : .couldNotUpdateMemberRole])
                if success { self.reloadProject() }
            }
        }
    }

    // MARK: - Confirmations

    func confirm(_ confirmation: PendingConfirmation) {
        pendingConfirmation = nil
        switch confirmation {
        case .leave: leave()
        case .delete: deleteProject()
        case .markComplete: setLifecycle(.completed)
        case .archive: setLifecycle(.archived)
        case .restore: setLifecycle(.active)
        case .deleteNote(let note): deleteNote(note)
        }
    }

    private func leave() {
        allApiObject.leaveProject(id: project.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard success else {
                    self.showStatus(self.strings[.couldNotLeave])
                    return
                }
                self.onProjectChanged?()
                self.onClose?()
            }
        }
    }

    private func deleteProject() {
        allApiObject.deleteProject(id: project.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard success else {
                    self.showStatus(self.strings[.couldNotDeleteProject])
                    return
                }
                self.onProjectChanged?()
                self.onClose?()
            }
        }
    }

    /// Lifecycle changes send `{ status }` alone (web danger zone).
    private func setLifecycle(_ status: ProjectLifecycleStatus) {
        update(body: ["status": status.rawValue])
    }

    // MARK: - Settings

    struct SettingsForm: Equatable {
        var name: String
        var description: String
        var dueDate: Date?
        var importance: PortfolioImportance
        var statuses: [ProjectCustomStatus]

        init(project: Project) {
            name = project.name
            description = project.description ?? ""
            dueDate = ToDoDates.parse(project.due_date)
            importance = project.importanceLevel
            statuses = project.orderedStatuses
        }
    }

    /// Web `buildProjectSettingsUpdatePayload`: `PUT /projects/:id` with name / description /
    /// custom_statuses / due_date (local `YYYY-MM-DD`, null clears) / importance.
    func saveSettings(_ form: SettingsForm, completion: @escaping (Bool) -> Void) {
        var body: [String: Any] = [
            "name": canEditName ? form.name.trimmingCharacters(in: .whitespaces) : project.name,
            "custom_statuses": form.statuses.enumerated().map { index, status -> [String: Any] in
                ["id": status.id, "label": status.label, "color": status.color ?? ProjectDetailStore.defaultStatusColor,
                 "order": index, "should_complete_task": status.should_complete_task ?? false]
            },
            "due_date": form.dueDate.map { ToDoDates.ymd($0) } ?? NSNull(),
            "importance": form.importance.rawValue,
        ]
        let description = form.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty { body["description"] = description }
        isSavingSettings = true
        update(body: body) { [weak self] success in
            self?.isSavingSettings = false
            if success { self?.isSettingsVisible = false }
            completion(success)
        }
    }

    private func update(body: [String: Any], completion: ((Bool) -> Void)? = nil) {
        allApiObject.updateProject(id: project.id, body: body) { [weak self] project in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let project = project else {
                    self.showStatus(self.strings[.couldNotUpdateProject])
                    completion?(false)
                    return
                }
                self.project = project
                self.showStatus(self.strings[.projectUpdated])
                self.onProjectChanged?()
                completion?(true)
            }
        }
    }

    // MARK: - Notes

    func loadNotes() {
        isNotesLoading = true
        allApiObject.getProjectNotes(projectId: project.id) { [weak self] notes in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isNotesLoading = false
                if let notes = notes { self.notes = notes } else { self.showStatus(self.strings[.requestFailed]) }
            }
        }
    }

    func open(_ note: ProjectNote) {
        openNote = note
        isNoteLoading = true
        allApiObject.getProjectNote(projectId: project.id, noteId: note.id) { [weak self] full in
            DispatchQueue.main.async {
                guard let self = self, self.openNote?.id == note.id else { return }
                self.isNoteLoading = false
                if let full = full { self.openNote = full }
            }
        }
    }

    /// `POST /projects/:id/notes { title: "Untitled note" }`, then open it (the body is edited on the web).
    func createNote() {
        allApiObject.createProjectNote(projectId: project.id, title: strings[.untitledNote]) { [weak self] note in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let note = note else {
                    self.showStatus(self.strings[.couldNotCreateNote])
                    return
                }
                self.notes.insert(note, at: 0)
                self.openNote = note
            }
        }
    }

    private func deleteNote(_ note: ProjectNote) {
        allApiObject.deleteProjectNote(projectId: project.id, noteId: note.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard success else {
                    self.showStatus(self.strings[.couldNotDeleteNote])
                    return
                }
                self.notes.removeAll { $0.id == note.id }
                if self.openNote?.id == note.id { self.openNote = nil }
                self.showStatus(self.strings[.noteDeleted])
            }
        }
    }

    /// Deep link the web uses for a note (`/projects/:id?tab=notes&note_id=`).
    func webURL(for note: ProjectNote?) -> URL? {
        var path = "\(ToDoExternalLinks.dashboard)/projects/\(project.id)?tab=notes"
        if let note = note { path += "&note_id=\(note.id)" }
        return URL(string: path)
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
