//
//  ToDoEditorView.swift
//  Focus Bear
//
//  The create / edit task sheet — the native version of the web's task drawer
//  (`dashboard/to-do/task-drawer`): title, status (default or the project's custom columns), the
//  TOP card — Timeline (due-date presets + typed dates + exact date), Outcome and Perspiration
//  sliders with the live T × O ÷ P score, and the duration in minutes kept in step with
//  Perspiration — projects, assignee, description, objective, subtasks
//  (incl. AI generation), comments, reactions and delete. The Eisenhower quadrant is no longer
//  asked for — a new task silently gets "Do" like the web, an edited task keeps what it had.
//

import SwiftUI
import AppKit

/// Comments + reactions of the task being edited (web `taskComments` / `taskReactions`).
final class ToDoTaskDetailsStore: ObservableObject {
    static let reactionPalette = ["👍", "🎉", "❤️", "🔥", "👀", "🚀"]

    @Published private(set) var comments: [ToDoComment] = []
    @Published private(set) var reactions: [ToDoReaction] = []
    @Published private(set) var isBusy = false
    private let taskId: String?
    private let showStatus: (String) -> Void
    private let strings: ToDoStrings

    init(taskId: String?, strings: ToDoStrings, showStatus: @escaping (String) -> Void) {
        self.taskId = taskId
        self.strings = strings
        self.showStatus = showStatus
    }

    private var currentUserId: String { appdelegate?.user?.userId ?? "" }

    func load() {
        guard let taskId = taskId else { return }
        allApiObject.getToDoComments(taskId: taskId) { [weak self] comments in
            DispatchQueue.main.async {
                self?.comments = comments ?? []
                self?.loadCommentReactions(taskId: taskId)
            }
        }
        allApiObject.getToDoReactions(taskId: taskId) { [weak self] reactions in
            DispatchQueue.main.async { self?.reactions = reactions ?? [] }
        }
    }

    func addComment(_ content: String, completion: @escaping (Bool) -> Void) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let taskId = taskId, !trimmed.isEmpty else { completion(false); return }
        isBusy = true
        allApiObject.addToDoComment(taskId: taskId, content: trimmed) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isBusy = false
                self.showStatus(self.strings[success ? .commentAdded : .couldNotAddComment])
                if success { self.load() }
                completion(success)
            }
        }
    }

    /// Web `fetchTaskComments` then one `GET …/comments/:id/reactions` per comment, merged in.
    private func loadCommentReactions(taskId: String) {
        for comment in comments {
            allApiObject.getToDoCommentReactions(taskId: taskId, commentId: comment.id) { [weak self] reactions in
                DispatchQueue.main.async {
                    guard let self = self, let index = self.comments.firstIndex(where: { $0.id == comment.id }) else { return }
                    self.comments[index].reactions = reactions ?? []
                }
            }
        }
    }

    func updateComment(_ comment: ToDoComment, content: String, completion: @escaping (Bool) -> Void) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let taskId = taskId, !trimmed.isEmpty else { completion(false); return }
        isBusy = true
        allApiObject.updateToDoComment(taskId: taskId, commentId: comment.id, content: trimmed) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isBusy = false
                self.showStatus(self.strings[success ? .commentUpdated : .couldNotUpdateComment])
                if success, let index = self.comments.firstIndex(where: { $0.id == comment.id }) { self.comments[index].content = trimmed }
                completion(success)
            }
        }
    }

    func isMine(_ comment: ToDoComment) -> Bool { comment.user_id == currentUserId && !currentUserId.isEmpty }

    func hasReacted(_ emoji: String, on comment: ToDoComment) -> Bool {
        comment.reactionList.contains { $0.emoji == emoji && $0.user_id == currentUserId }
    }

    /// Optimistic, like the web's `addCommentReaction` / `removeCommentReaction`.
    func toggleCommentReaction(_ emoji: String, on comment: ToDoComment) {
        guard let taskId = taskId, let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        let remove = hasReacted(emoji, on: comment)
        if remove {
            comments[index].reactions?.removeAll { $0.emoji == emoji && $0.user_id == currentUserId }
            allApiObject.removeToDoCommentReaction(taskId: taskId, commentId: comment.id, emoji: emoji) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if !success { self.showStatus(self.strings[.couldNotRemoveReaction]); self.loadCommentReactions(taskId: taskId) }
                }
            }
        } else {
            let optimistic = ToDoReaction(id: UUID().uuidString, task_id: taskId, comment_id: comment.id, user_id: currentUserId, emoji: emoji, created_at: nil)
            comments[index].reactions = comment.reactionList + [optimistic]
            allApiObject.addToDoCommentReaction(taskId: taskId, commentId: comment.id, emoji: emoji) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if !success { self.showStatus(self.strings[.couldNotAddReaction]) }
                    self.loadCommentReactions(taskId: taskId)
                }
            }
        }
    }

    func deleteComment(_ comment: ToDoComment) {
        guard let taskId = taskId else { return }
        allApiObject.deleteToDoComment(taskId: taskId, commentId: comment.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.showStatus(self.strings[success ? .commentDeleted : .couldNotDeleteComment])
                if success { self.comments.removeAll { $0.id == comment.id } }
            }
        }
    }

    func count(for emoji: String) -> Int { reactions.filter { $0.emoji == emoji }.count }
    func hasReacted(_ emoji: String) -> Bool { reactions.contains { $0.emoji == emoji && $0.user_id == currentUserId } }

    /// Optimistic toggle, like the web; refetch on failure.
    func toggleReaction(_ emoji: String) {
        guard let taskId = taskId else { return }
        let remove = hasReacted(emoji)
        if remove {
            reactions.removeAll { $0.emoji == emoji && $0.user_id == currentUserId }
            allApiObject.removeToDoReaction(taskId: taskId, emoji: emoji) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if !success { self.showStatus(self.strings[.couldNotRemoveReaction]); self.load() }
                }
            }
        } else {
            reactions.append(ToDoReaction(id: UUID().uuidString, task_id: taskId, comment_id: nil, user_id: currentUserId, emoji: emoji, created_at: nil))
            allApiObject.addToDoReaction(taskId: taskId, emoji: emoji) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if !success { self.showStatus(self.strings[.couldNotAddReaction]) }
                    self.load()
                }
            }
        }
    }
}

struct ToDoEditorSheet: View {
    @ObservedObject var store: ToDoStore
    let task: ToDoTask?
    let initialTitle: String
    let initialProject: Project?

    @SwiftUI.State private var draft: ToDoTask
    @SwiftUI.State private var original: ToDoTask
    @SwiftUI.State private var selectedProjectIds: [String]
    @SwiftUI.State private var statusOwnerProjectId: String?
    @SwiftUI.State private var durationMinutesText: String
    @SwiftUI.State private var pendingSubtask = ""
    @SwiftUI.State private var projectSearch = ""
    @SwiftUI.State private var newComment = ""
    @SwiftUI.State private var isGeneratingSubtasks = false
    // One alert at a time: SwiftUI on macOS only presents a single `.alert` per view hierarchy, so
    // separate discard/delete alerts silently suppressed each other. Drive both from one enum.
    @SwiftUI.State private var activeAlert: EditorAlert?

    private enum EditorAlert: Identifiable { case discard, delete; var id: Int { hashValue } }
    @StateObject private var details: ToDoTaskDetailsStore

    private static let maxVisibleProjectChips = 12
    /// Up to this many statuses stay a segmented control; more collapse into a single menu.
    private static let maxSegmentedStatuses = 4
    private static let statusControlWidth: CGFloat = 400
    private static let statusMenuWidth: CGFloat = 220
    private static let durationFieldWidth: CGFloat = 60
    private static let projectSearchWidth: CGFloat = 300
    private var strings: ToDoStrings { store.strings }
    private var isNew: Bool { task == nil }

    init(store: ToDoStore, task: ToDoTask?, initialTitle: String, initialProject: Project? = nil) {
        self.store = store
        self.task = task
        self.initialTitle = initialTitle
        self.initialProject = initialProject
        let base = task.map(ToDoDraft.editable) ?? ToDoDraft.newTask(title: initialTitle, project: initialProject)
        _draft = SwiftUI.State(initialValue: base)
        _original = SwiftUI.State(initialValue: base)
        _selectedProjectIds = SwiftUI.State(initialValue: base.tagList.map { $0.id })
        _statusOwnerProjectId = SwiftUI.State(initialValue: base.project_id)
        _durationMinutesText = SwiftUI.State(initialValue: ToDoEditorSheet.durationText(for: base))
        _details = StateObject(wrappedValue: ToDoTaskDetailsStore(taskId: task?.id, strings: store.strings, showStatus: { [weak store] in store?.showStatus($0) }))
    }

    // MARK: Derived

    private var titleIsBlank: Bool { draft.title.trimmingCharacters(in: .whitespaces).isEmpty }
    private var hasChanges: Bool {
        draft != original || selectedProjectIds != original.tagList.map { $0.id } || !pendingSubtask.trimmingCharacters(in: .whitespaces).isEmpty
            || durationMinutesText != ToDoEditorSheet.durationText(for: original)
    }
    /// What the duration field starts with: the explicit minutes, else the perspiration's.
    private static func durationText(for task: ToDoTask) -> String {
        String(ToDoScoring.durationSeconds(explicit: task.durationSeconds, perspiration: task.effectivePerspiration) / 60)
    }
    // Enabled whenever there's a valid title and no save in flight. Not gated on hasChanges: comments
    // and reactions persist on their own (they aren't in the task draft, so hasChanges never sees them),
    // and the user still expects Save to dismiss the sheet after adding one. save() closes without a
    // network write when the task itself is unchanged.
    private var canSave: Bool { !titleIsBlank && !store.isSavingTask }
    /// The pre-linked project resolves from the session itself, so it shows as selected even if
    /// the catalogue is still the one fetched before it was created.
    private var selectedProjects: [Project] {
        selectedProjectIds.compactMap { id in store.project(id: id) ?? (initialProject?.id == id ? initialProject : nil) }
    }
    private var ownerProject: Project? { store.project(id: resolvedOwnerProjectId) }
    private var dueDate: Date? { ToDoDates.parse(draft.due_date) }
    private var topScore: Double {
        ToDoScoring.topScore(outcome: draft.effectiveOutcome, perspiration: draft.effectivePerspiration, dueDate: dueDate)
    }

    /// Web `resolveStatusOwnerProjectId`.
    private var resolvedOwnerProjectId: String? {
        if let owner = statusOwnerProjectId, selectedProjectIds.contains(owner) { return owner }
        if let customId = draft.custom_status_id,
           let owner = selectedProjects.first(where: { $0.customStatuses.contains { $0.id == customId } }) { return owner.id }
        if let owner = selectedProjects.first(where: { $0.usesCustomStatuses }) { return owner.id }
        return selectedProjectIds.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    titleField
                    statusSection
                    topSection
                    projectsSection
                    assigneeSection
                    labelled(strings[.description]) { ToDoMultilineEditor(text: detailsBinding, placeholder: strings[.description]) }
                    labelled(strings[.objective]) { TextField(strings[.objectivePlaceholder], text: objectiveBinding).textFieldStyle(RoundedBorderTextFieldStyle()) }
                    subtasksSection
                    if !isNew {
                        reactionsSection
                        commentsSection
                        deleteSection
                    }
                }
                // Breathing room so the focus ring of the first/edge fields (title, objective) isn't
                // clipped by the ScrollView's bounds; extra trailing for the scroller.
                .padding(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 6))
            }
        }
        .padding(16)
        .frame(minWidth: 680, idealWidth: 720, minHeight: 600, idealHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { details.load() }
        .alert(item: $activeAlert) { which in
            switch which {
            case .discard:
                return Alert(title: Text(strings[.unsavedChanges]),
                             primaryButton: .destructive(Text(strings[.discard])) { store.closeEditor() },
                             secondaryButton: .cancel(Text(strings[.cancel])))
            case .delete:
                return Alert(title: Text(strings[.deleteTask]),
                             message: Text(strings[.deleteTaskConfirmation]),
                             primaryButton: .destructive(Text(strings[.delete])) { if let task = task { store.delete(task) } },
                             secondaryButton: .cancel(Text(strings[.cancel])))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text(isNew ? strings[.createTaskTitle] : strings[.editTaskTitle]).font(.title2).bold()
            if !isNew, let created = task?.created_at, !created.isEmpty {
                Text(strings.format(.created, ToDoStrings.dateToken, ToDoDates.abbreviated(created)))
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }
            Spacer()
            SwiftUI.Button(action: closeAttempt) { Text(strings[.cancel]) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                .keyboardShortcut(.cancelAction)
            SwiftUI.Button(action: save) { Text(store.isSavingTask ? strings[.saving] : strings[.save]) }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                .disabled(!canSave)
                .keyboardShortcut("s", modifiers: .command)
                .help(titleIsBlank ? strings[.titleIsNeeded] : strings[.save])
        }
    }

    private func closeAttempt() {
        guard !store.isSavingTask else { return }
        if hasChanges { activeAlert = .discard } else { store.closeEditor() }
    }

    // MARK: Title / status

    private var titleField: some View {
        HStack(spacing: 8) {
            SwiftUI.Button(action: { setCompleted(draft.defaultStatus != .completed) }) {
                Image(systemName: draft.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20)).foregroundColor(draft.isCompleted ? ToDoTheme.good : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            // No onCommit-to-save here: on macOS SwiftUI's onCommit also fires when the field loses
            // first responder (there's no onSubmit on the macOS 11 target to distinguish Return), so
            // saving on commit closed the sheet whenever focus left the title — e.g. after nudging the
            // Outcome/Perspiration sliders (which don't steal first responder) and then clicking another
            // field. Save is via the Save button / ⌘S instead.
            TextField(strings[.addATask], text: $draft.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 15))
            if titleIsBlank {
                Image(systemName: "exclamationmark.triangle").foregroundColor(ToDoTheme.today).help(strings[.titleIsNeeded])
            }
        }
    }

    private func setCompleted(_ completed: Bool) {
        draft = ToDoStatusToggle.apply(to: draft, completed: completed, customStatuses: ownerProject?.customStatuses ?? [])
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                sectionTitle(strings[.status])
                if selectedProjects.count > 1 {
                    Text(strings[.statusAppliesTo]).font(.system(size: 11)).foregroundColor(.secondary)
                    Picker("", selection: Binding(get: { resolvedOwnerProjectId ?? "" }, set: { statusOwnerProjectId = $0 })) {
                        ForEach(selectedProjects) { project in Text(strings.projectName(project.name)).tag(project.id) }
                    }
                    .labelsHidden().pickerStyle(MenuPickerStyle()).frame(maxWidth: 220)
                }
            }
            if let owner = ownerProject, owner.usesCustomStatuses {
                customStatusPicker(owner)
            } else {
                Picker("", selection: Binding(get: { draft.defaultStatus }, set: { status in
                    draft.status = status.rawValue
                    draft.custom_status_id = nil
                })) {
                    ForEach(ToDoStatus.allCases, id: \.self) { status in Text(strings.statusLabel(status)).tag(status) }
                }
                .labelsHidden().pickerStyle(SegmentedPickerStyle()).frame(maxWidth: ToDoEditorSheet.statusControlWidth)
            }
        }
    }

    /// A project's custom columns: up to `maxSegmentedStatuses` fit as equal segments; beyond that
    /// the whole control becomes one menu, so a fifth column never ends up as an odd popup next to
    /// the segments.
    @ViewBuilder
    private func customStatusPicker(_ project: Project) -> some View {
        let ordered = project.orderedStatuses
        let selection = Binding<String>(get: { draft.custom_status_id ?? ordered.first?.id ?? "" }, set: { id in
            draft.custom_status_id = id
            let completes = ordered.first { $0.id == id }?.should_complete_task ?? false
            draft.status = completes ? ToDoStatus.completed.rawValue : (id == ordered.first?.id ? ToDoStatus.notStarted.rawValue : ToDoStatus.inProgress.rawValue)
        })
        if ordered.count <= ToDoEditorSheet.maxSegmentedStatuses {
            Picker("", selection: selection) {
                ForEach(ordered) { status in Text(status.label).tag(status.id) }
            }
            .labelsHidden().pickerStyle(SegmentedPickerStyle()).frame(maxWidth: ToDoEditorSheet.statusControlWidth)
        } else {
            Picker("", selection: selection) {
                ForEach(ordered) { status in Text(status.label).tag(status.id) }
            }
            .labelsHidden().pickerStyle(MenuPickerStyle()).frame(maxWidth: ToDoEditorSheet.statusMenuWidth)
        }
    }

    // MARK: TOP (due date, outcome, perspiration + duration)

    private var topSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill").foregroundColor(ToDoTheme.accent)
                sectionTitle(strings[.topScore])
                ToDoChip(text: ToDoScoring.rounded(topScore), tint: ToDoTheme.accent, filled: true)
                Spacer()
                Text(strings.format(.scoreFormula, ToDoStrings.scoreToken, ToDoScoring.rounded(topScore)))
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }
            HStack(alignment: .top, spacing: 16) {
                topRow(letter: "T", title: strings[.timelineDueDate]) {
                    let pressure = ToDoScoring.timePressure(dueDate: dueDate, effortMinutes: ToDoScoring.minutes(forPerspiration: draft.effectivePerspiration))
                    Text(ToDoScoring.rounded(pressure)).font(.system(size: 11)).foregroundColor(.secondary)
                    ToDoDueDateField(day: Binding(get: { dueDate }, set: { draft.due_date = $0.map(ToDoDates.ymd) }), strings: strings, isStacked: true)
                }
                topRow(letter: "O", title: strings[.outcome]) {
                    levelSlider(value: Binding(get: { draft.effectiveOutcome }, set: { draft.outcome = $0 }), label: strings.outcomeLabel(draft.effectiveOutcome))
                }
                topRow(letter: "P", title: strings[.perspiration]) {
                    levelSlider(value: Binding(get: { draft.effectivePerspiration }, set: { setPerspiration($0) }), label: strings.perspirationLabel(draft.effectivePerspiration))
                    durationField
                }
            }
        }
        .padding(12)
        .background(ToDoTheme.card)
        .cornerRadius(ToDoTheme.cornerRadius)
    }

    /// The task's duration in minutes, editable: typing moves the Perspiration slider to the level
    /// that covers it, and the slider writes its level's minutes back here, so the two never disagree.
    private var durationField: some View {
        HStack(spacing: 6) {
            TextField("", text: $durationMinutesText)
                .textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: ToDoEditorSheet.durationFieldWidth)
                .onChange(of: durationMinutesText) { text in
                    guard let minutes = Int(text.trimmingCharacters(in: .whitespaces)), minutes > 0 else { return }
                    let level = ToDoScoring.perspiration(forMinutes: minutes, current: draft.effectivePerspiration)
                    if level != draft.effectivePerspiration { draft.perspiration_level = level }
                }
            Text(strings[.minutes]).font(.system(size: 11)).foregroundColor(.secondary)
        }
    }

    private func setPerspiration(_ level: Int) {
        draft.perspiration_level = level
        durationMinutesText = String(ToDoScoring.minutes(forPerspiration: level))
    }

    private func topRow<Content: View>(letter: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(letter).font(.system(size: 13, weight: .bold)).foregroundColor(ToDoTheme.accent)
                Text(title).font(.system(size: 12, weight: .medium))
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func levelSlider(value: Binding<Int>, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0.rounded()) }),
                   in: Double(ToDoScoring.minLevel)...Double(ToDoScoring.maxLevel), step: 1)
            Text("\(value.wrappedValue) · \(label)").font(.system(size: 11)).foregroundColor(.secondary)
        }
    }

    // MARK: Projects

    private var filteredProjects: [Project] {
        let query = projectSearch.trimmingCharacters(in: .whitespaces).lowercased()
        let matching = query.isEmpty ? store.projects : store.projects.filter { strings.projectName($0.name).lowercased().contains(query) }
        return matching.filter { !selectedProjectIds.contains($0.id) }
    }

    /// The typed search names a project nobody has yet: no catalogue entry (selected or not) is
    /// called exactly that, so an inline "Create" row is offered (web `TaskProjects` create input).
    private var creatableProjectName: String? {
        let typed = projectSearch.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty, !store.isCreatingProject else { return nil }
        let exists = store.projects.contains { strings.projectName($0.name).caseInsensitiveCompare(typed) == .orderedSame || $0.name.caseInsensitiveCompare(typed) == .orderedSame }
        return exists ? nil : typed
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionTitle(strings[.projects])
                Text("\(selectedProjectIds.count) / \(store.projects.count)").font(.system(size: 11)).foregroundColor(.secondary)
            }
            if !selectedProjects.isEmpty {
                chipRow(selectedProjects.map { ($0.id, strings.projectName($0.name)) }, selected: true) { toggleProject($0) }
            }
            // No onCommit: on macOS it also fires on focus loss, so clicking away from a non-matching
            // search term would create a project. Use the explicit "Create “…”" button below instead.
            TextField(strings[.searchProjectsPlaceholder], text: $projectSearch)
                .textFieldStyle(RoundedBorderTextFieldStyle()).frame(maxWidth: ToDoEditorSheet.projectSearchWidth)
            if store.projects.isEmpty {
                Text(strings[.noExistingProjects]).font(.system(size: 12)).foregroundColor(.secondary)
            } else if filteredProjects.isEmpty {
                Text(strings[.noProjectsFound]).font(.system(size: 12)).foregroundColor(.secondary)
            } else {
                chipRow(filteredProjects.prefix(ToDoEditorSheet.maxVisibleProjectChips).map { ($0.id, strings.projectName($0.name)) }, selected: false) { toggleProject($0) }
            }
            if let name = creatableProjectName {
                SwiftUI.Button(action: createProjectFromSearch) {
                    Label(strings.format(.createProjectNamed, ToDoStrings.projectToken, name), systemImage: "plus")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
            }
        }
    }

    private func chipRow(_ items: [(id: String, name: String)], selected: Bool, onTap: @escaping (String) -> Void) -> some View {
        // No wrapping flow layout on macOS 11: a horizontal scroller keeps long rows usable.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.id) { item in
                    SwiftUI.Button(action: { onTap(item.id) }) {
                        ToDoChip(text: item.name, systemImage: selected ? "checkmark" : "plus", tint: ToDoTheme.accent, filled: selected)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
            }
        }
    }

    private func toggleProject(_ id: String) {
        if let index = selectedProjectIds.firstIndex(of: id) {
            selectedProjectIds.remove(at: index)
        } else {
            selectedProjectIds.append(id)
        }
        // Web: the status-owner project follows the selection; a stale custom status is dropped.
        if let owner = ownerProject, !owner.customStatuses.contains(where: { $0.id == draft.custom_status_id }) {
            draft.custom_status_id = nil
        }
    }

    /// `POST /projects` with the typed name, then select it and clear the search. Return in the
    /// search field does the same, so "type a name, press Enter" creates when nothing matched.
    private func createProjectFromSearch() {
        guard let name = creatableProjectName else { return }
        store.createProject(named: name) { project in
            guard let project = project else { return }
            selectedProjectIds.append(project.id)
            projectSearch = ""
        }
    }

    // MARK: Assignee

    /// Web `TaskAssignee` candidates: me, then accepted members of the selected projects.
    private var assigneeOptions: [(id: String, label: String)] {
        var options: [(id: String, label: String)] = []
        var seen = Set<String>()
        if let me = appdelegate?.user?.userId, !me.isEmpty {
            options.append((me, "\(strings[.me]) (\(appdelegate?.user?.email ?? ""))"))
            seen.insert(me)
        }
        for project in selectedProjects {
            for member in project.acceptedMembers {
                guard let userId = member.user_id, !seen.contains(userId) else { continue }
                seen.insert(userId)
                options.append((userId, member.email ?? userId))
            }
        }
        if let current = draft.assignee_id, !seen.contains(current) {
            options.append((current, draft.assignee?.username ?? draft.assignee?.email ?? current))
        }
        return options
    }

    private var assigneeSection: some View {
        HStack(spacing: 8) {
            sectionTitle(strings[.assignee])
            Picker("", selection: Binding(get: { draft.assignee_id ?? "" }, set: { draft.assignee_id = $0.isEmpty ? nil : $0 })) {
                Text(strings[.unassigned]).tag("")
                ForEach(assigneeOptions, id: \.id) { option in Text(option.label).tag(option.id) }
            }
            .labelsHidden().pickerStyle(MenuPickerStyle()).frame(maxWidth: 300)
        }
    }

    // MARK: Subtasks

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionTitle(strings[.createSubtasks])
                Spacer()
                SwiftUI.Button(action: generateSubtasks) {
                    Label(isGeneratingSubtasks ? strings[.loading] : strings[.generateSubtasksViaAI], systemImage: "sparkles")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                .disabled(titleIsBlank || isGeneratingSubtasks)
            }
            // The row index is only valid for the current render; deleting a subtask shrinks the array,
            // so every subscript is bounds-guarded — an unguarded `draft.subtasks?[index]` traps
            // (Index out of range) when a row is removed mid-render (the `?` only guards nil).
            ForEach(Array(draft.subtaskList.enumerated()), id: \.offset) { index, subtask in
                HStack(spacing: 8) {
                    SwiftUI.Button(action: { if index < draft.subtaskList.count { draft.subtasks?[index].is_completed.toggle() } }) {
                        Image(systemName: subtask.is_completed ? "checkmark.square.fill" : "square")
                            .foregroundColor(subtask.is_completed ? ToDoTheme.good : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    TextField(strings[.addASubtask], text: Binding(
                        get: { index < draft.subtaskList.count ? draft.subtaskList[index].name : "" },
                        set: { if index < draft.subtaskList.count { draft.subtasks?[index].name = $0 } }))
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(subtask.is_completed ? .secondary : .primary)
                    SwiftUI.Button(action: { if index < draft.subtaskList.count { draft.subtasks?.remove(at: index) } }) { Image(systemName: "trash").foregroundColor(.secondary) }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(ToDoTheme.card).cornerRadius(6)
            }
            HStack(spacing: 8) {
                TextField(strings[.addASubtask], text: $pendingSubtask, onCommit: addSubtask).textFieldStyle(RoundedBorderTextFieldStyle())
                SwiftUI.Button(action: addSubtask) { Text(strings[.addSubtask]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                    .disabled(pendingSubtask.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addSubtask() {
        let name = pendingSubtask.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        draft.subtasks = draft.subtaskList + [ToDoSubtask(name: name, is_completed: false)]
        pendingSubtask = ""
    }

    private func generateSubtasks() {
        isGeneratingSubtasks = true
        allApiObject.generateSubtasks(task: draft.title) { generated in
            DispatchQueue.main.async {
                isGeneratingSubtasks = false
                guard let generated = generated else {
                    store.showStatus(strings[.couldNotGenerateSubtasks])
                    return
                }
                draft.subtasks = draft.subtaskList + generated.map { ToDoSubtask(name: $0, is_completed: false) }
                store.showStatus(strings[.subtasksGenerated])
            }
        }
    }

    // MARK: Reactions / comments / delete

    private var reactionsSection: some View {
        HStack(spacing: 6) {
            sectionTitle(strings[.reactions])
            ForEach(ToDoTaskDetailsStore.reactionPalette, id: \.self) { emoji in
                let count = details.count(for: emoji)
                let mine = details.hasReacted(emoji)
                SwiftUI.Button(action: { details.toggleReaction(emoji) }) {
                    HStack(spacing: 3) {
                        Text(emoji)
                        if count > 0 { Text("\(count)").font(.system(size: 11, weight: .semibold)) }
                    }
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(mine ? ToDoTheme.accentSoft : ToDoTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(mine ? ToDoTheme.accent : ToDoTheme.separator))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .help(strings[.addReaction])
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(strings[.comments])
            if details.comments.isEmpty {
                Text(strings[.noCommentsYet]).font(.system(size: 12)).foregroundColor(.secondary)
            }
            ForEach(details.comments) { comment in
                ToDoCommentRow(details: details, comment: comment, strings: strings)
            }
            HStack(spacing: 8) {
                // No onCommit: on macOS it also fires on focus loss, so clicking away would post a
                // half-typed comment (visible to other members). Use the "Add" button instead.
                TextField(strings[.addCommentPlaceholder], text: $newComment).textFieldStyle(RoundedBorderTextFieldStyle())
                SwiftUI.Button(action: addComment) { Text(strings[.add]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty || details.isBusy)
            }
        }
    }

    private func addComment() {
        details.addComment(newComment) { success in if success { newComment = "" } }
    }

    private var deleteSection: some View {
        HStack {
            Spacer()
            // Confirm inside the sheet (via the single activeAlert): store.taskToDelete's alert lives on
            // the list view behind the sheet, so it can't appear until the sheet closes. delete() removes
            // the task and closes the editor itself.
            SwiftUI.Button(action: { activeAlert = .delete }) {
                Label(strings[.deleteTask], systemImage: "trash").foregroundColor(ToDoTheme.overdue)
            }
            .buttonStyle(PlainButtonStyle()).pointingHandCursor()
        }
    }

    // MARK: Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 12, weight: .semibold))
    }

    private func labelled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(title)
            content()
        }
    }

    private var detailsBinding: Binding<String> { Binding(get: { draft.details ?? "" }, set: { draft.details = $0 }) }
    private var objectiveBinding: Binding<String> { Binding(get: { draft.objective ?? "" }, set: { draft.objective = $0 }) }

    // MARK: Save

    /// Web `TaskForm.handleSubmit` payload: tags from the selected projects, `project_id` = the
    /// status-owner project, the pending subtask appended, duration explicit or from perspiration.
    private func save() {
        // Nothing changed on the task itself (e.g. only a comment/reaction was added, which already
        // persisted) — just close, no redundant PUT.
        if !isNew && !hasChanges { store.closeEditor(); return }
        var toSave = draft
        toSave.title = draft.title.trimmingCharacters(in: .whitespaces)
        toSave.details = (draft.details ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        toSave.tags = selectedProjects.map { ToDoTag(id: $0.id, text: $0.name) }
        toSave.project_id = resolvedOwnerProjectId
        if !(ownerProject?.usesCustomStatuses ?? false) { toSave.custom_status_id = nil }
        var subtasks = draft.subtaskList.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let pending = pendingSubtask.trimmingCharacters(in: .whitespaces)
        if !pending.isEmpty { subtasks.append(ToDoSubtask(name: pending, is_completed: false)) }
        toSave.subtasks = subtasks
        let explicitMinutes = Int(durationMinutesText.trimmingCharacters(in: .whitespaces)) ?? 0
        toSave.duration = LenientInt(ToDoScoring.durationSeconds(explicit: explicitMinutes * 60, perspiration: draft.effectivePerspiration))
        store.saveTask(toSave, isNew: isNew) { _ in }
    }
}

/// One comment: author + date, body (inline-editable for your own), edit / delete, emoji reactions
/// (web `TaskComments` + `CommentReactions`).
private struct ToDoCommentRow: View {
    @ObservedObject var details: ToDoTaskDetailsStore
    let comment: ToDoComment
    let strings: ToDoStrings
    @SwiftUI.State private var isEditing = false
    @SwiftUI.State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(comment.user?.username ?? "").font(.system(size: 11, weight: .semibold))
                        Text(ToDoDates.abbreviated(comment.created_at)).font(.system(size: 11)).foregroundColor(.secondary)
                    }
                    if isEditing {
                        TextField("", text: $draft, onCommit: saveEdit).textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(comment.content).font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                if isEditing {
                    SwiftUI.Button(action: { isEditing = false }) { Text(strings[.cancel]) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 24))
                    SwiftUI.Button(action: saveEdit) { Text(strings[.save]) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 24))
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || details.isBusy)
                } else if details.isMine(comment) {
                    SwiftUI.Button(action: { draft = comment.content; isEditing = true }) { Image(systemName: "pencil").foregroundColor(.secondary) }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.editComment])
                    SwiftUI.Button(action: { details.deleteComment(comment) }) { Image(systemName: "trash").foregroundColor(.secondary) }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.deleteComment])
                }
            }
            HStack(spacing: 4) {
                ForEach(ToDoTaskDetailsStore.reactionPalette, id: \.self) { emoji in
                    let count = comment.reactionList.filter { $0.emoji == emoji }.count
                    let mine = details.hasReacted(emoji, on: comment)
                    // Unused emoji stay small until hovered/clicked so the row reads as the comment first.
                    SwiftUI.Button(action: { details.toggleCommentReaction(emoji, on: comment) }) {
                        HStack(spacing: 2) {
                            Text(emoji).font(.system(size: count > 0 ? 12 : 10)).opacity(count > 0 ? 1 : 0.5)
                            if count > 0 { Text("\(count)").font(.system(size: 10, weight: .semibold)) }
                        }
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(mine ? ToDoTheme.accentSoft : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(mine ? ToDoTheme.accent : (count > 0 ? ToDoTheme.separator : Color.clear)))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    .help(strings[.addReaction])
                }
            }
        }
        .padding(8).background(ToDoTheme.card).cornerRadius(6)
    }

    private func saveEdit() {
        details.updateComment(comment, content: draft) { success in if success { isEditing = false } }
    }
}

/// Multi-line text box with a placeholder (macOS 11 `TextEditor` has none).
struct ToDoMultilineEditor: View {
    @Binding var text: String
    let placeholder: String
    var height: CGFloat = 80

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 13))
                .padding(4)
            if text.isEmpty {
                Text(placeholder).font(.system(size: 13)).foregroundColor(Color.gray.opacity(0.7))
                    .padding(.horizontal, 9).padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: height)
        .background(ToDoTheme.field)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ToDoTheme.separator))
        .cornerRadius(6)
    }
}
