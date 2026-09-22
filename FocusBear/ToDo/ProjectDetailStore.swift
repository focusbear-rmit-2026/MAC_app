//
//  ProjectDetailStore.swift
//  Focus Bear
//
//  State for one open project — the native version of the web's `ProjectDetailPage`: its tasks
//  (`GET /projects/:id/todos`, list or board by the project's columns), members (invite / role /
//  remove / leave), settings (`PUT /projects/:id`), lifecycle and delete, and the shared project
//  notes (`/projects/:id/notes` — metadata here; the collaborative Yjs body lives in
//  ProjectNoteEditorSession).
//

import Foundation

final class ProjectDetailStore: ObservableObject {

    enum PageView: String, CaseIterable { case tasks, notes }
    enum TasksMode: String, CaseIterable { case list, board }

    /// Confirmations the view shows as alerts. Lifecycle changes are deliberately absent: they apply
    /// on the click and are undone from the detail's banner instead of behind a modal.
    enum PendingConfirmation: Identifiable {
        case leave, delete
        case deleteNote(ProjectNote)

        var id: String {
            switch self {
            case .leave: return "leave"
            case .delete: return "delete"
            case .deleteNote(let note): return "deleteNote-\(note.id)"
            }
        }
    }

    private static let tasksModeKey = "kUserdefaultsProjectDetailTasksMode"
    static let nameMaxLength = 80
    static let defaultStatusColor = "#6B7280"
    /// The `PUT /projects/:id` field the icon is written to.
    private static let iconField = "icon"

    let strings: ToDoStrings
    /// Fires when the project changed in a way the list / portfolio should reflect (settings, delete,
    /// leave, lifecycle) — the parent store re-fetches.
    var onProjectChanged: (() -> Void)?
    var onProjectLoaded: ((Project) -> Void)?
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
    /// The member whose "Resend invitation" button is armed and waiting for a second click. Resending
    /// emails a real person, so a single stray click must never send — see `ProjectInvitationResend`.
    @Published private(set) var armedResendMemberId: String?
    private var disarmResendWork: DispatchWorkItem?

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
    var canMoveTask: Bool { ProjectPermissions.canMoveTask(viewerRole) }
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
        let id = project.id, account = currentUserId
        allApiObject.getProject(id: id) { [weak self] project in
            DispatchQueue.main.async {
                guard let self = self, self.currentUserId == account, self.project.id == id else { return }
                self.isLoading = false
                guard let project = project else {
                    self.notFound = true
                    return
                }
                guard project.id == id else { self.notFound = true; return }
                self.project = ProjectListPresentation.preservingSync(project, from: self.project)
                self.onProjectLoaded?(self.project)
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
    /// Every way of moving a card — drag, the card's "Move to" menu, its context menu — lands here,
    /// so the permission check and the column/status rule are applied once (`ProjectTaskMove.plan`).
    func move(_ task: ToDoTask, toColumn columnId: String) {
        guard let moved = ProjectTaskMove.plan(task, toColumn: columnId, project: project,
                                               columns: columns, canMove: canMoveTask) else { return }
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
        // Resolve the assignee from whichever shape the server sent BEFORE building the write.
        // `GET /to-do` carries the assignee only as a relation and no flat `assignee_id`
        // (backend#2414), so a task straight off the board has the flat field nil — and the write
        // sends `assignee_id` unconditionally, where nil means "unassign". Every kanban drag and
        // every checkbox toggle comes through here, so each one silently unassigned the task.
        // `ToDoDraft.editable` does the same resolution for the editor; the board never did.
        var outgoing = task
        outgoing.assignee_id = ToDoAssigneeChoices.assigneeId(flat: task.assignee_id,
                                                              relation: task.assignee?.id)
        allApiObject.upsertToDo(ToDoUpsertBody.make(from: outgoing)) { [weak self] saved, statusCode, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updatingTaskIds.remove(task.id)
                let outcome = ProjectTaskMove.settled(statusCode: statusCode, saved: saved, attempted: task, previous: previous)
                self.replaceLocally(outcome.task)
                guard !outcome.failed else {
                    self.showStatus(ToDoStore.failureText(self.strings.format(.couldNotUpdateTask, ToDoStrings.titleToken, task.title), reason: serverMessage))
                    return
                }
                self.announceCompletionChange(from: previous, to: outcome.task)
            }
        }
    }

    /// A kanban move or a checkbox here is the same completion everywhere else in the app, so the
    /// To-do list, the Day Plan and the project forecast have to hear about it instead of waiting
    /// for their own next reload — the forecast in particular reused a snapshot taken before the
    /// tasks were finished and kept the project at risk (report 2026-09-15_17-41-45). Announced only
    /// on a real change, and only once the server has taken the write, so a rollback never posts.
    private func announceCompletionChange(from previous: ToDoTask, to saved: ToDoTask) {
        let statuses = project.usesCustomStatuses ? project.customStatuses : []
        let completed = ToDoCompletionState.isFinished(saved, customStatuses: statuses)
        guard completed != ToDoCompletionState.isFinished(previous, customStatuses: statuses) else { return }
        TodoCompletionBus.post(todoID: saved.id, completed: completed)
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

    /// Whether this member's invitation may be re-sent right now: an outstanding invitation, a viewer
    /// allowed to invite, and the server's own cooldown since the last send elapsed.
    func canResendInvitation(_ member: ProjectMember, now: Date = Date()) -> Bool {
        guard ProjectInvitationResend.canResend(viewer: viewerRole, status: member.invitationStatus) else { return false }
        return ProjectInvitationResend.cooldownElapsed(sentAt: ProjectInvitationResend.lastSentAt(member), now: now)
    }

    func isResendArmed(_ member: ProjectMember) -> Bool { armedResendMemberId == member.id }

    /// First click arms, second click sends. The armed state disarms itself so a button left armed
    /// can't be triggered by a much later stray click.
    func armResend(_ member: ProjectMember) {
        armedResendMemberId = member.id
        disarmResendWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard self?.armedResendMemberId == member.id else { return }
            self?.armedResendMemberId = nil
        }
        disarmResendWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + ProjectInvitationResend.confirmWindowSeconds, execute: work)
    }

    func disarmResend() {
        disarmResendWork?.cancel()
        armedResendMemberId = nil
    }

    /// Re-sends an outstanding invitation. Permission and status are re-checked here as well as in the
    /// view, so the only way to reach the network is through a state that genuinely allows it.
    func resendInvitation(_ member: ProjectMember) {
        disarmResend()
        guard canResendInvitation(member), let email = member.email, !email.isEmpty else { return }
        guard !busyMemberIds.contains(member.id) else { return }
        // Never re-send as "owner": the server refuses that role on an invite.
        let role = member.memberRole == .owner ? ProjectMemberRole.member : (member.memberRole ?? .member)
        busyMemberIds.insert(member.id)
        allApiObject.resendProjectInvitation(projectId: project.id, email: email, role: role.rawValue) { [weak self] success, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.busyMemberIds.remove(member.id)
                self.showStatus(success ? self.strings[.invitationResent]
                                        : ToDoStore.failureText(self.strings[.couldNotResendInvitation], reason: serverMessage))
                if success { self.reloadProject() }
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
        case .deleteNote(let note): deleteNote(note)
        }
    }

    /// A confirmation raised from inside the Settings sheet. macOS will not put an alert on top of a
    /// presented sheet, so the sheet closes first — otherwise the click looks like it did nothing.
    func requestConfirmation(_ confirmation: PendingConfirmation) {
        guard isSettingsVisible else {
            pendingConfirmation = confirmation
            return
        }
        isSettingsVisible = false
        DispatchQueue.main.async { [weak self] in self?.pendingConfirmation = confirmation }
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

    // MARK: - Lifecycle (complete / archive / restore)

    /// Lifecycle changes send `{ status }` alone (web danger zone). They apply straight away — the
    /// banner and the Settings sheet flip before the request lands — and roll back with the server's
    /// own reason if the `PUT` fails, so the button is never a silent no-op.
    func setLifecycle(_ status: ProjectLifecycleStatus) {
        let previous = project
        let account = currentUserId
        guard !account.isEmpty, canManageLifecycle, status != previous.lifecycleStatus else { return }
        project.status = status.rawValue
        isSettingsVisible = false
        showStatus(strings[lifecycleToast(status)])
        allApiObject.updateProject(id: previous.id, body: ["status": status.rawValue], expectedAccountID: account) { [weak self] updated, serverMessage in
            DispatchQueue.main.async {
                guard let self = self, self.currentUserId == account else { return }
                guard let updated = updated else {
                    self.project = previous
                    self.showStatus(ToDoStore.failureText(self.strings[.couldNotUpdateProject], reason: serverMessage))
                    return
                }
                self.project = updated
                self.onProjectChanged?()
            }
        }
    }

    private func lifecycleToast(_ status: ProjectLifecycleStatus) -> ToDoStringKey {
        switch status {
        case .completed: return .projectMarkedComplete
        case .archived: return .projectArchived
        case .active: return .projectRestored
        }
    }

    // MARK: - Settings

    struct SettingsForm: Equatable {
        var name: String
        var description: String
        var dueDate: Date?
        var outcome: Int?
        var statuses: [ProjectCustomStatus]

        init(project: Project) {
            name = project.name
            description = project.description ?? ""
            dueDate = ToDoDates.parse(project.due_date)
            // Legacy `importance` is not part of the form: it is the server's own ranking input,
            // not the user's rating, and the sheet must not write it (backend#2385).
            outcome = project.outcome
            statuses = project.orderedStatuses
        }
    }

    /// Web `buildProjectSettingsUpdatePayload`: `PUT /projects/:id` with name / description /
    /// custom_statuses / due_date (local `YYYY-MM-DD`, null clears) / outcome.
    func saveSettings(_ form: SettingsForm, completion: @escaping (Bool) -> Void) {
        isSavingSettings = true
        update(body: ProjectDetailStore.settingsBody(form, name: canEditName ? nil : project.name)) { [weak self] success in
            self?.isSavingSettings = false
            if success { self?.isSettingsVisible = false }
            completion(success)
        }
    }

    /// The settings payload, as a pure function of the form so it can be asserted on directly.
    /// `name` overrides the form's when the viewer may not rename the project.
    static func settingsBody(_ form: SettingsForm, name: String?) -> [String: Any] {
        var body: [String: Any] = [
            "name": name ?? form.name.trimmingCharacters(in: .whitespaces),
            "custom_statuses": form.statuses.enumerated().map { index, status -> [String: Any] in
                ["id": status.id, "label": status.label, "color": status.color ?? ProjectDetailStore.defaultStatusColor,
                 "order": index, "should_complete_task": status.should_complete_task ?? false]
            },
            "due_date": form.dueDate.map { ToDoDates.ymd($0) } ?? NSNull(),
            // `outcome` is the rating, on the server's 1–10 wire scale; null clears it. `importance`
            // is deliberately absent — it is the legacy 1–4 field the server's portfolio risk ranks
            // by, not the user's rating, and deriving it here would quietly rewrite it (backend#2385).
            "outcome": form.outcome ?? NSNull(),
        ]
        let description = form.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty { body["description"] = description }
        return body
    }

    /// Rename from the heading (`PUT /projects/:id { name }`) rather than through the Settings sheet.
    /// An empty name, an unchanged one, or a viewer without the right is a silent no-op — the field
    /// has already put the old name back by the time this is called.
    func rename(to name: String) {
        guard canEditName else { return }
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(ProjectDetailStore.nameMaxLength))
        guard !trimmed.isEmpty, trimmed != project.name else { return }
        update(body: ["name": trimmed])
    }

    /// Set the project's icon, or clear it back to the automatic one.
    ///
    /// The wire format is the **literal emoji character**. An earlier pass guessed hex codepoints
    /// ("1f3af") from `EmojiIcon.resolve`, which is a *display* function, and that changed nothing:
    /// the value was never what failed. `icon` was undeclared on the server's `UpdateProjectDto`
    /// and the global pipe strips undeclared fields, so the update had nothing to set and the
    /// resulting `UpdateValuesMissingError` surfaced as a bare 500 (report 2026-09-14_20-07-42,
    /// backend#2404). `normalizeSingleEmoji` — what the server's own icon generator writes through
    /// — is the real contract. `habit_icon` is the odd one out that genuinely is hex.
    func setIcon(_ emoji: String) {
        guard canEditName else { return }
        let chosen = ProjectIcon.normalise(emoji)
        guard chosen != (project.icon ?? ProjectIcon.cleared) else { return }
        update(body: [ProjectDetailStore.iconField: chosen], failureMessage: strings[.couldNotSaveIcon])
    }

    /// Set the due date from the heading rather than through the Settings sheet — the user asked to
    /// see it and change it without opening settings (report 2026-09-15_10-27-17, follow-up).
    /// `nil` clears it.
    func setDueDate(_ day: Date?) {
        guard canEditName else { return }
        let ymd = day.map { ToDoDates.ymd($0) }
        guard ymd != project.due_date else { return }
        update(body: ["due_date": ymd ?? NSNull()])
    }

    /// Set the outcome from the heading, on the server's 1–10 wire scale. `nil` clears the rating.
    func setOutcome(_ wire: Int?) {
        guard canEditName else { return }
        guard wire != project.outcome else { return }
        update(body: ["outcome": wire ?? NSNull()])
    }

    // MARK: - Tags

    /// The project's tags, in the stored (folded) form.
    var tags: [String] { ProjectTags.normalize(project.tagList) }

    /// Add a typed tag. A blank, duplicate or over-cap entry is a silent no-op rather than a request.
    func addTag(_ raw: String) {
        guard canEditName, let next = ProjectTags.adding(raw, to: project.tagList) else { return }
        update(body: ProjectDetailStore.tagsBody(next), failureMessage: strings[.couldNotSaveTags])
    }

    func removeTag(_ tag: String) {
        guard canEditName, let next = ProjectTags.removing(tag, from: project.tagList) else { return }
        update(body: ProjectDetailStore.tagsBody(next), failureMessage: strings[.couldNotSaveTags])
    }

    /// `PUT /projects/:id { metadata: { tags } }` — the tags key and nothing else.
    ///
    /// Two things this must never do, both of them ways the server would take more than was meant:
    ///
    /// - **Never send the rest of the bag.** `metadata` is open and other clients own keys this app
    ///   cannot read. The server shallow-merges (`jsonb ||`), so sending `tags` alone leaves those
    ///   keys untouched; echoing back a bag decoded into a Swift struct would drop whatever did not
    ///   round-trip. That is the mistake that nulled `assigned_mcp_token_id` on every task save.
    /// - **Never send `metadata: null` to mean "no tags".** Null clears the *whole bag*. Clearing the
    ///   last tag sends `{"tags": []}`, which empties the list and leaves every other key alone.
    static func tagsBody(_ tags: [String]) -> [String: Any] {
        ["metadata": ["tags": ProjectTags.normalize(tags)]]
    }

    /// `failureMessage` names the specific edit that failed — "Could not save the icon" rather than
    /// the generic "Could not update project" — while keeping whatever reason the server gave.
    private func update(body: [String: Any], failureMessage: String? = nil, completion: ((Bool) -> Void)? = nil) {
        let account = currentUserId
        guard !account.isEmpty else { completion?(false); return }
        allApiObject.updateProject(id: project.id, body: body, expectedAccountID: account) { [weak self] project, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard self.currentUserId == account else { completion?(false); return }
                guard let project = project else {
                    self.showStatus(ToDoStore.failureText(failureMessage ?? self.strings[.couldNotUpdateProject], reason: serverMessage))
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
        // One project, one request — nothing here can trip the rate limiter, so the status code the
        // sweep needs is of no use to this screen.
        allApiObject.getProjectNotes(projectId: project.id) { [weak self] notes, _ in
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

    /// `POST /projects/:id/notes { title: "Untitled note" }`, then open the collaborative editor.
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

    /// Step back from the open note to this project's note list.
    func closeNote() { openNote = nil }

    /// Rename the open note. The body is saved separately through the document endpoint.
    /// An empty or unchanged title is a no-op.
    func renameNote(_ note: ProjectNote, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != note.title else { return }
        allApiObject.renameProjectNote(projectId: project.id, noteId: note.id, title: trimmed) { [weak self] saved in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let saved = saved else {
                    self.showStatus(self.strings[.couldNotRenameNote])
                    return
                }
                // The list row carries no body, so patch its title in place rather than re-fetching.
                if let index = self.notes.firstIndex(where: { $0.id == saved.id }) { self.notes[index].title = saved.title }
                if self.openNote?.id == saved.id { self.openNote?.title = saved.title }
                self.showStatus(self.strings[.noteRenamed])
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
        ProjectNoteLinks.webURL(projectId: project.id, noteId: note?.id)
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
