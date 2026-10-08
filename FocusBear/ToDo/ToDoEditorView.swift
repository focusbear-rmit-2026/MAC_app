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

    func isMine(_ comment: ToDoComment) -> Bool { (comment.user_id ?? currentUserId) == currentUserId }

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

/// When a new task's due date may be moved to the day the forecast proposes.
///
/// A default is not an opinion the app gets to keep re-asserting. It applies once, to a field the
/// user has not touched: the moment the date differs from the one the app put there, it is the
/// user's and is never overwritten (report 2026-09-15_20-08-56, "We should just default it to the
/// suggested date"). Applying once also stops the proposal chasing itself — the candidate's own due
/// date feeds the priority ordering that produces the next proposal.
enum ToDoDueDateDefault {
    /// The day to write, or nil to leave the field exactly as it is.
    static func dayToApply(proposal: Date?, current: Date?, lastDefaulted: Date?, hasDefaulted: Bool,
                           isNew: Bool, calendar: Calendar) -> Date? {
        guard isNew, !hasDefaulted, let proposal = proposal else { return nil }
        // Anything but the date the app itself seeded means the user has chosen one.
        guard let current = current, let seeded = lastDefaulted,
              calendar.isDate(current, inSameDayAs: seeded) else { return nil }
        guard !calendar.isDate(proposal, inSameDayAs: current) else { return nil }
        return proposal
    }
}

struct ToDoEditorSheet: View {
    @ObservedObject var store: ToDoStore
    let task: ToDoTask?
    let initialTitle: String
    let initialProject: Project?

    @SwiftUI.State private var draft: ToDoTask
    /// The sheet exactly as it opened, so "has anything been edited?" is one comparison.
    @SwiftUI.State private var originalSnapshot: ToDoEditorSnapshot
    @SwiftUI.State private var selectedProjectIds: [String]
    @SwiftUI.State private var statusOwnerProjectId: String?
    @SwiftUI.State private var durationMinutesText: String
    @SwiftUI.State private var pendingSubtask = ""
    @SwiftUI.State private var projectSearch = ""
    @SwiftUI.State private var newComment = ""
    @SwiftUI.State private var isGeneratingSubtasks = false
    /// The editor's own sheet window, so its confirmations can be attached to it (see `confirm`).
    @SwiftUI.State private var hostWindow: NSWindow?
    @SwiftUI.State private var previewedAttachment: ToDoAttachment?
    /// The date the app seeded the field with, and whether the forecast has since corrected it. See
    /// `ToDoDueDateDefault`: together they are how a default is told apart from a date the user chose.
    @SwiftUI.State private var seededDueDate: Date?
    @SwiftUI.State private var hasDefaultedDueDate = false
    @StateObject private var details: ToDoTaskDetailsStore
    /// The task's files. Its own store, shared verbatim with the Day Plan's task details
    /// (`ToDoAttachments.swift`) so the two surfaces can never drift apart.
    @StateObject private var attachments: ToDoAttachmentsStore

    private static let maxVisibleProjectChips = 12
    /// Up to this many statuses stay a segmented control; more collapse into a single menu.
    private static let maxSegmentedStatuses = 4
    private static let statusControlWidth: CGFloat = 400
    private static let statusMenuWidth: CGFloat = 220
    private static let durationFieldWidth: CGFloat = 60
    private static let projectSearchWidth: CGFloat = 300
    private typealias Identifiers = UITestContract.Identifier.TasksRegression
    private var strings: ToDoStrings { store.strings }
    private var isNew: Bool { task == nil }

    init(store: ToDoStore, task: ToDoTask?, initialTitle: String, initialProject: Project? = nil) {
        self.store = store
        self.task = task
        self.initialTitle = initialTitle
        self.initialProject = initialProject
        // A new task starts on the first day with room left, not a flat "tomorrow" that ignores an
        // already-full day (report 2026-09-14_19-50-05). This is only a cheap opening value:
        // `nextFreeDay` scans for leftover slack, while the day the app actually proposes comes from
        // the full next-slot allocation, which is far too expensive to run here on every open. The
        // advice view hands that back and `ToDoDueDateDefault` corrects the field once it arrives —
        // which is what stopped the field saying November while the forecast said October
        // (report 2026-09-15_20-08-56).
        let base = task.map(ToDoDraft.editable)
            ?? ToDoDraft.newTask(title: initialTitle, project: initialProject,
                                 dueDate: store.forecast.nextFreeDay)
        // One opening snapshot seeds every editable field, so a field added to `ToDoEditorSnapshot`
        // is initialised and compared in the same place.
        let opening = ToDoEditorSnapshot(draft: base,
                                         selectedProjectIds: base.tagList.map { $0.id },
                                         statusOwnerProjectId: base.project_id,
                                         durationMinutesText: ToDoEditorSheet.durationText(for: base),
                                         pendingSubtask: "")
        _originalSnapshot = SwiftUI.State(initialValue: opening)
        _draft = SwiftUI.State(initialValue: opening.draft)
        _seededDueDate = SwiftUI.State(initialValue: ToDoDates.parse(base.due_date))
        _selectedProjectIds = SwiftUI.State(initialValue: opening.selectedProjectIds)
        _statusOwnerProjectId = SwiftUI.State(initialValue: opening.statusOwnerProjectId)
        _durationMinutesText = SwiftUI.State(initialValue: opening.durationMinutesText)
        _details = StateObject(wrappedValue: ToDoTaskDetailsStore(taskId: task?.id, strings: store.strings, showStatus: { [weak store] in store?.showStatus($0) }))
        _attachments = StateObject(wrappedValue: ToDoAttachmentsStore(taskId: task?.id, strings: store.strings, showStatus: { [weak store] in store?.showStatus($0) }))
    }

    // MARK: Derived

    private var titleIsBlank: Bool { draft.title.trimmingCharacters(in: .whitespaces).isEmpty }
    /// The task as the sheet opened it, for the handful of places that need to compare one field.
    private var original: ToDoTask { originalSnapshot.draft }
    private var currentSnapshot: ToDoEditorSnapshot {
        ToDoEditorSnapshot(draft: draft, selectedProjectIds: selectedProjectIds,
                           statusOwnerProjectId: statusOwnerProjectId,
                           durationMinutesText: durationMinutesText,
                           pendingSubtask: pendingSubtask.trimmingCharacters(in: .whitespaces))
    }
    private var hasChanges: Bool { currentSnapshot != originalSnapshot }
    /// What the duration field starts with: the explicit minutes, else the perspiration's.
    static func durationText(for task: ToDoTask) -> String {
        String(ToDoScoring.durationSeconds(explicit: task.durationSeconds, perspiration: task.effectivePerspiration) / 60)
    }
    /// See `ToDoEditorSave.canSave` for why this is not gated on `hasChanges`.
    private var canSave: Bool {
        ToDoEditorSave.canSave(titleIsBlank: titleIsBlank, isSavingTask: store.isSavingTask,
                               isUploadingAttachment: attachments.isUploading)
    }
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
                    labelled(strings[.description]) {
                        ToDoMultilineEditor(text: detailsBinding, placeholder: strings[.description],
                                            accessibilityIdentifier: Identifiers.editorDescription)
                    }
                    subtasksSection
                    attachmentsSection
                    if !isNew {
                        reactionsSection
                        commentsSection
                        deleteSection
                    }
                }
                .padding(.trailing, 4)
            }
        }
        .padding(16)
        .frame(minWidth: 680, idealWidth: 720, minHeight: 600, idealHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .background(HostWindowReader { hostWindow = $0 })
        .onAppear {
            details.load()
            attachments.load()
            // Every open needs a forecast now, not just a new task's: the due date's capacity warning
            // is shown for existing tasks too.
            store.forecast.refreshIfNeeded()
        }
        .sheet(item: $previewedAttachment) { attachment in
            ToDoAttachmentPreviewSheet(attachment: attachment, strings: strings) { previewedAttachment = nil }
        }
    }

    /// Ask something destructive, attached to the editor's own sheet window.
    ///
    /// SwiftUI's `Alert` is presented on the window *underneath* a `.sheet`, so a confirmation raised
    /// from in here was drawn behind the editor — present the whole time, holding the keyboard, and
    /// invisible ("Delete task doesn't work - modal appears behind the edit task popup",
    /// report 2026-09-14_11-50-38, still reproducing after the alert was moved into the sheet).
    private func confirm(title: String, message: String?, confirmTitle: String, onConfirm: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        if let message = message { alert.informativeText = message }
        alert.addButton(withTitle: confirmTitle)      // .alertFirstButtonReturn
        alert.addButton(withTitle: strings[.cancel])
        alert.buttons.first?.hasDestructiveAction = true
        alert.presentAsSheet(for: hostWindow) { response in
            guard response == .alertFirstButtonReturn else { return }
            onConfirm()
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
                .accessibilityIdentifier(Identifiers.editorCancelButton)
            SwiftUI.Button(action: save) { Text(store.isSavingTask ? strings[.saving] : strings[.save]) }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                .disabled(!canSave)
                .keyboardShortcut("s", modifiers: .command)
                .help(titleIsBlank ? strings[.titleIsNeeded] : strings[.save])
                .accessibilityIdentifier(UITestContract.Identifier.ToDo.editorSaveButton)
        }
    }

    private func closeAttempt() {
        guard !store.isSavingTask else { return }
        guard hasChanges else { store.closeEditor(); return }
        confirm(title: strings[.unsavedChanges], message: nil, confirmTitle: strings[.discard]) { store.closeEditor() }
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
            // NOT SwiftUI's TextField: its `onCommit` also fires when the field loses focus, so typing
            // a title and then clicking the due-date field saved the task and closed the sheet
            // mid-edit (report 2026-09-14_11-51-05). This field tells Return apart from blur, and
            // only Return saves.
            ReturnGuardTextField(text: $draft.title, placeholder: strings[.addATask],
                                 onCommit: { if canSave { save() } }, fontSize: 15,
                                 accessibilityIdentifier: UITestContract.Identifier.ToDo.editorTitleField,
                                 focusesWhenShown: true)
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
                .accessibilityIdentifier(Identifiers.editorStatusPicker)
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
            }
            HStack(alignment: .top, spacing: 16) {
                topRow(letter: "T", title: strings[.timelineDueDate]) {
                    // The bare time-pressure sub-score ("1.7") meant nothing next to the TOP score
                    // above it and made the card look busy (report 2026-09-14_19-50-05).
                    ToDoDueDateField(day: Binding(get: { dueDate }, set: { draft.due_date = $0.map(ToDoDates.ymd) }), strings: strings, isStacked: true,
                                     fieldIdentifier: Identifiers.editorDueDateField)
                    // Everything the forecast has to say about this date sits under the control it is
                    // about, not at the foot of the card where it read as a comment on the whole task
                    // (reports 2026-09-15_17-59-04 and _20-08-56). NOT gated on `isNew`: re-dating a
                    // task that already exists — an overdue one especially — is exactly when "that day
                    // has no room either" is worth knowing, and gating it was why the warning never
                    // appeared at all.
                    ForecastDueDateAdvice(store: store.forecast, task: draft, projectID: resolvedOwnerProjectId,
                                          durationMinutes: Int(durationMinutesText) ?? 0,
                                          selectedDate: dueDate, onProposal: applyProposedDueDate)
                }
                ForecastOutcomePicker(wireValue: $draft.outcome)
                topRow(letter: "P", title: strings[.perspiration]) {
                    levelSlider(value: Binding(get: { draft.effectivePerspiration }, set: { setPerspiration($0) }),
                                title: strings[.perspiration], label: strings.perspirationLabel(draft.effectivePerspiration))
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
                .accessibilityLabel(strings[.duration])
                .accessibilityIdentifier(Identifiers.editorDurationField)
                .onChange(of: durationMinutesText) { text in
                    guard let minutes = Int(text.trimmingCharacters(in: .whitespaces)), minutes > 0 else { return }
                    let level = ToDoScoring.perspiration(forMinutes: minutes, current: draft.effectivePerspiration)
                    if level != draft.effectivePerspiration { draft.perspiration_level = level }
                }
            Text(strings[.minutes]).font(.system(size: 11)).foregroundColor(.secondary)
        }
    }

    private func applyProposedDueDate(_ proposal: Date) {
        guard let day = ToDoDueDateDefault.dayToApply(proposal: proposal, current: dueDate,
                                                      lastDefaulted: seededDueDate, hasDefaulted: hasDefaultedDueDate,
                                                      isNew: isNew, calendar: .current) else { return }
        hasDefaultedDueDate = true
        seededDueDate = day
        draft.due_date = ToDoDates.ymd(day)
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

    /// `title` is the row heading drawn above the slider; SwiftUI doesn't tie the two together, so
    /// without it the slider is announced with no name at all.
    private func levelSlider(value: Binding<Int>, title: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0.rounded()) }),
                   in: Double(ToDoScoring.minLevel)...Double(ToDoScoring.maxLevel), step: 1)
                .accessibilityLabel(title)
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
                chipRow(selectedProjects.map { ($0.id, strings.projectName($0.name), $0.name) }, selected: true,
                        identifier: Identifiers.editorSelectedProjectChip) { toggleProject($0) }
            }
            // Return only — SwiftUI's own `onCommit` also fires on losing focus, which would create a
            // project simply because the user typed a search and clicked elsewhere (the same defect
            // as the New Project sheet, report 2026-09-15_20-13-26).
            ReturnGuardTextField(text: $projectSearch, placeholder: strings[.searchProjectsPlaceholder],
                                 onCommit: createProjectFromSearch,
                                 accessibilityIdentifier: Identifiers.editorProjectSearchField)
                .frame(maxWidth: ToDoEditorSheet.projectSearchWidth)
            if store.projects.isEmpty {
                Text(strings[.noExistingProjects]).font(.system(size: 12)).foregroundColor(.secondary)
            } else if filteredProjects.isEmpty {
                Text(strings[.noProjectsFound]).font(.system(size: 12)).foregroundColor(.secondary)
            } else {
                chipRow(filteredProjects.prefix(ToDoEditorSheet.maxVisibleProjectChips).map { ($0.id, strings.projectName($0.name), $0.name) }, selected: false,
                        identifier: Identifiers.editorAvailableProjectChip) { toggleProject($0) }
            }
            if let name = creatableProjectName {
                SwiftUI.Button(action: createProjectFromSearch) {
                    Label(strings.format(.createProjectNamed, ToDoStrings.projectToken, name), systemImage: "plus")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                .accessibilityIdentifier(Identifiers.editorCreateProjectButton)
            }
        }
    }

    private func chipRow(_ items: [(id: String, name: String, projectName: String)], selected: Bool, identifier: String,
                         onTap: @escaping (String) -> Void) -> some View {
        // No wrapping flow layout on macOS 11: a horizontal scroller keeps long rows usable.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.id) { item in
                    SwiftUI.Button(action: { onTap(item.id) }) {
                        ToDoChip(text: item.name, systemImage: selected ? "checkmark" : "plus", tint: ToDoTheme.accent, filled: selected)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    .accessibilityIdentifier(UITestContract.Identifier.named(identifier, item.projectName))
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

    /// Web `TaskAssignee` candidates: me, then accepted members of the selected projects. The rules
    /// live in `ToDoAssigneeChoices` because the Day Plan's task details offers the same control and
    /// the two must not drift (report 2026-09-17_09-01-33).
    private var assigneeOptions: [ToDoAssigneeOption] {
        let me = (appdelegate?.user?.userId).flatMap { id -> ToDoAssigneeOption? in
            guard !id.isEmpty else { return nil }
            return ToDoAssigneeOption(id: id, label: "\(strings[.me]) (\(appdelegate?.user?.email ?? ""))")
        }
        let members = selectedProjects.flatMap { $0.acceptedMembers }.compactMap { member -> ToDoAssigneeOption? in
            guard let userId = member.user_id, !userId.isEmpty else { return nil }
            return ToDoAssigneeOption(id: userId, label: member.email ?? userId)
        }
        let current = draft.assignee_id.map {
            ToDoAssigneeOption(id: $0, label: draft.assignee?.username ?? draft.assignee?.email ?? $0)
        }
        return ToDoAssigneeChoices.options(me: me, members: members, current: current)
    }

    private var canAssignToSomebodyElse: Bool {
        ToDoAssigneeChoices.canAssign(options: assigneeOptions, currentAssigneeId: draft.assignee_id,
                                      meId: appdelegate?.user?.userId)
    }

    @ViewBuilder
    private var assigneeSection: some View {
        if canAssignToSomebodyElse { assigneePicker }
    }

    private var assigneePicker: some View {
        HStack(spacing: 8) {
            sectionTitle(strings[.assignee])
            Picker("", selection: Binding(get: { draft.assignee_id ?? ToDoAssigneeChoices.unassignedTag },
                                          set: { draft.assignee_id = $0.isEmpty ? nil : $0 })) {
                Text(strings[.unassigned]).tag(ToDoAssigneeChoices.unassignedTag)
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
            ForEach(Array(draft.subtaskList.enumerated()), id: \.offset) { index, subtask in
                HStack(spacing: 8) {
                    SwiftUI.Button(action: { draft.subtasks?[index].is_completed.toggle() }) {
                        Image(systemName: subtask.is_completed ? "checkmark.square.fill" : "square")
                            .foregroundColor(subtask.is_completed ? ToDoTheme.good : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    TextField(strings[.addASubtask], text: Binding(get: { draft.subtasks?[index].name ?? "" }, set: { draft.subtasks?[index].name = $0 }))
                        .textFieldStyle(PlainTextFieldStyle())
                        .accessibilityLabel(strings[.addASubtask])
                        .foregroundColor(subtask.is_completed ? .secondary : .primary)
                    SwiftUI.Button(action: { draft.subtasks?.remove(at: index) }) { Image(systemName: "trash").foregroundColor(.secondary) }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(ToDoTheme.card).cornerRadius(6)
            }
            HStack(spacing: 8) {
                // A TextField's title is only its placeholder; VoiceOver needs it as the name too.
                TextField(strings[.addASubtask], text: $pendingSubtask, onCommit: addSubtask).textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel(strings[.addASubtask])
                AddItemButton(title: strings[.addSubtask], action: addSubtask)
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

    /// Files on the task. Attaching needs the task to exist (the endpoint is `/to-do/:id/attachments`),
    /// so a brand-new task says so rather than offering a button that cannot work
    /// (report 2026-09-14_12-18-21). The rows, the picker and the preview are shared with the Day
    /// Plan's task details — see `ToDoAttachments.swift`.
    private var attachmentsSection: some View {
        labelled(strings[.attachments]) {
            ToDoAttachmentsList(store: attachments, strings: strings,
                                unavailableMessage: strings[.attachmentsAfterSaving],
                                onPreview: { previewedAttachment = $0 },
                                pasteLabel: "todo-editor")
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
                TextField(strings[.addCommentPlaceholder], text: $newComment, onCommit: addComment).textFieldStyle(RoundedBorderTextFieldStyle())
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
            // Confirmed on the editor's own window: `delete()` removes the task and closes the editor.
            SwiftUI.Button(action: confirmDelete) {
                Label(strings[.deleteTask], systemImage: "trash").foregroundColor(ToDoTheme.overdue)
            }
            .buttonStyle(PlainButtonStyle()).pointingHandCursor()
        }
    }

    private func confirmDelete() {
        guard let task = task else { return }
        confirm(title: strings[.deleteTask], message: strings[.deleteTaskConfirmation],
                confirmTitle: strings[.delete]) { store.delete(task) }
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

    // MARK: Save

    /// Web `TaskForm.handleSubmit` payload: tags from the selected projects, `project_id` = the
    /// status-owner project, the pending subtask appended, duration explicit or from perspiration.
    private func save() {
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
        store.saveTask(toSave, isNew: isNew, clearOutcome: draft.outcome == nil && original.outcome != nil) { _ in }
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
    /// Empty is SwiftUI's "none".
    var accessibilityIdentifier = ""

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 13))
                .padding(4)
                .accessibilityLabel(placeholder)
                .accessibilityIdentifier(accessibilityIdentifier)
            if text.isEmpty {
                // Drawn text, not a real placeholder: VoiceOver would read it as a stray label beside
                // the editor that already carries it as its name.
                Text(placeholder).font(.system(size: 13)).foregroundColor(Color.gray.opacity(0.7))
                    .padding(.horizontal, 9).padding(.vertical, 8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: height)
        .background(ToDoTheme.field)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ToDoTheme.separator))
        .cornerRadius(6)
    }
}

/// The one "add another one of these" control a task editor offers — a sub-task, a file.
///
/// It exists because there were two of them. The Day Plan's task details drew "Add sub-task" as a
/// small AppKit push button with a leading +, and the attachments' "Add file…" right underneath it as
/// a wide filled pill; the to-do editor used the pill for both. "Can you make the add attachment
/// button match the add sub task button?" (report 2026-09-15_11-16-30 follow-up) is what happens when
/// one control is written twice. Copying one style onto the other would only have reset the clock, so
/// every add button — either host, either toolkit — is now THIS view.
struct AddItemButton: View {
    let title: String
    let action: () -> Void

    /// The leading glyph: the one the sub-task button already showed, and the one the reporter asked
    /// the file button to look like.
    static let symbol = "plus"

    var body: some View {
        SwiftUI.Button(action: action) {
            Label(title, systemImage: Self.symbol)
        }
        .controlSize(.small)
        .pointingHandCursor()
    }

    /// The same control for an AppKit form — the Day Plan's task details popover is hand-built stack
    /// views, and a second NSButton styled to match is exactly the drift being removed here.
    ///
    /// Hugging is required rather than default: an `NSHostingView` that lets the stack view around it
    /// stretch it turns a small + button into a full-width bar — the same class of mistake as a hosted
    /// view growing the window it sits in.
    static func hosted(title: String, action: @escaping () -> Void) -> NSView {
        let view = NSHostingView(rootView: AddItemButton(title: title, action: action))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }
}

/// Reports the AppKit window a SwiftUI view is living in. Inside a `.sheet` that is the sheet's own
/// window — the one a confirmation has to be attached to so it cannot be ordered behind the sheet.
struct HostWindowReader: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView { WindowReportingView(onWindow: onWindow) }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class WindowReportingView: NSView {
        private let onWindow: (NSWindow?) -> Void

        init(onWindow: @escaping (NSWindow?) -> Void) {
            self.onWindow = onWindow
            super.init(frame: .zero)
        }

        @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            let window = self.window
            // SwiftUI is mid-update while this fires; handing it back on the next turn of the run loop
            // avoids mutating @State during a layout pass.
            DispatchQueue.main.async { [onWindow] in onWindow(window) }
        }
    }
}
