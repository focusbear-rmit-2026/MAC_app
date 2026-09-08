//
//  ProjectDetailView.swift
//  Focus Bear
//
//  One project, the native version of the web's `ProjectDetailPage`: header (back, lifecycle badge,
//  Members / Settings / Leave), Tasks (list or board by the project's columns, add task, move
//  between columns) and Notes (shared project notes, read-only with "Edit on the web"), plus the
//  Members and Settings sheets.
//

import SwiftUI
import AppKit

struct ProjectDetailView: View {
    @ObservedObject var store: ProjectDetailStore
    @ObservedObject var todoStore: ToDoStore
    let onBack: () -> Void
    let onShowInTaskList: () -> Void

    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            navRow
            if store.notFound {
                notFound
            } else {
                identityRow
                if store.pageView == .tasks { ProjectTasksView(store: store, todoStore: todoStore) } else { ProjectNotesView(store: store) }
            }
        }
        .sheet(isPresented: $store.isMembersVisible) { ProjectMembersSheet(store: store) }
        .sheet(isPresented: $store.isSettingsVisible) { ProjectSettingsSheet(store: store) }
        .alert(item: $store.pendingConfirmation) { confirmation in
            Alert(title: Text(confirmationTitle(confirmation)), message: Text(confirmationMessage(confirmation)),
                  primaryButton: .destructive(Text(confirmationButton(confirmation))) { store.confirm(confirmation) },
                  secondaryButton: .cancel(Text(strings[.cancel])))
        }
    }

    private var navRow: some View {
        HStack(spacing: 8) {
            SwiftUI.Button(action: onBack) { Label(strings[.backToProjects], systemImage: "chevron.left") }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .foregroundColor(ToDoTheme.accent)
            if store.project.lifecycleStatus != .active {
                ToDoChip(text: strings.projectStatusLabel(store.project.lifecycleStatus))
            }
            if let message = store.statusMessage {
                Text(message).font(.system(size: 12)).foregroundColor(.secondary).transition(.opacity)
            }
            Spacer()
            SwiftUI.Button(action: onShowInTaskList) { Label(strings[.showInTaskList], systemImage: "line.horizontal.3") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            if store.canOpenMembers {
                SwiftUI.Button(action: { store.isMembersVisible = true }) {
                    Label(strings.format(.membersWithCount, ToDoStrings.countToken, String(store.members.count)), systemImage: "person.2")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
            if store.canOpenSettings {
                SwiftUI.Button(action: { store.isSettingsVisible = true }) { Label(strings[.settings], systemImage: "gearshape") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
            if store.canLeave {
                SwiftUI.Button(action: { store.pendingConfirmation = .leave }) { Text(strings[.leave]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
        }
    }

    private var identityRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(strings.projectName(store.project.name)).font(.system(size: 18, weight: .bold)).lineLimit(1)
                if let description = store.project.description, !description.isEmpty {
                    Text(description).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(2)
                }
            }
            Spacer()
            Picker("", selection: $store.pageView) {
                Text(strings[.detailTabTasks]).tag(ProjectDetailStore.PageView.tasks)
                Text(strings[.detailTabNotes]).tag(ProjectDetailStore.PageView.notes)
            }
            .pickerStyle(SegmentedPickerStyle()).labelsHidden().frame(width: 180)
            .onChange(of: store.pageView) { view in if view == .notes { store.loadNotes() } }
            if let icon = store.project.icon, !icon.isEmpty { Text(icon).font(.system(size: 28)) }
        }
    }

    private var notFound: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.questionmark").font(.system(size: 36)).foregroundColor(.secondary)
            Text(strings[.projectNotFound]).font(.headline)
            SwiftUI.Button(action: onBack) { Text(strings[.backToProjects]) }.buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func confirmationTitle(_ confirmation: ProjectDetailStore.PendingConfirmation) -> String {
        switch confirmation {
        case .leave: return strings[.leave]
        case .delete: return strings[.deleteProject]
        case .markComplete: return strings[.markCompleteProject]
        case .archive: return strings[.archiveProject]
        case .restore: return strings[.restoreProject]
        case .deleteNote: return strings[.delete]
        }
    }

    private func confirmationMessage(_ confirmation: ProjectDetailStore.PendingConfirmation) -> String {
        switch confirmation {
        case .leave: return strings[.leaveConfirm]
        case .delete: return strings[.deleteProjectConfirm]
        case .markComplete: return strings[.markCompleteConfirm]
        case .archive: return strings[.archiveConfirm]
        case .restore: return strings[.restoreConfirm]
        case .deleteNote: return strings[.deleteNoteConfirm]
        }
    }

    private func confirmationButton(_ confirmation: ProjectDetailStore.PendingConfirmation) -> String {
        switch confirmation {
        case .leave: return strings[.leave]
        case .delete, .deleteNote: return strings[.delete]
        case .markComplete: return strings[.markCompleteProject]
        case .archive: return strings[.archiveProject]
        case .restore: return strings[.restoreProject]
        }
    }
}

// MARK: - Tasks (list / board)

private struct ProjectTasksView: View {
    @ObservedObject var store: ProjectDetailStore
    @ObservedObject var todoStore: ToDoStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            toolbar
            if store.isTasksLoading && store.tasks.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.tasks.isEmpty {
                emptyState
            } else if store.tasksMode == .board {
                board
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            if store.canAddTask {
                SwiftUI.Button(action: { todoStore.openEditor(for: nil, project: store.project) }) { Label(strings[.addTask], systemImage: "plus") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 28))
            }
            ToDoSearchField(text: $store.searchQuery, placeholder: strings[.searchPlaceholder], isBusy: false).frame(maxWidth: 240)
            Picker("", selection: $store.sortMode) {
                Text(strings[.sortSmart]).tag(ToDoSortMode.smart)
                Text(strings[.sortChronological]).tag(ToDoSortMode.chronological)
                Text(strings[.sortDueDate]).tag(ToDoSortMode.dueDate)
            }
            .pickerStyle(SegmentedPickerStyle()).labelsHidden().frame(width: 210)
            Spacer()
            Picker("", selection: $store.tasksMode) {
                Image(systemName: "list.bullet").tag(ProjectDetailStore.TasksMode.list).help(strings[.listView])
                Image(systemName: "rectangle.split.3x1").tag(ProjectDetailStore.TasksMode.board).help(strings[.boardView])
            }
            .pickerStyle(SegmentedPickerStyle()).labelsHidden().frame(width: 80)
            .disabled(store.tasks.isEmpty)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist").font(.system(size: 36)).foregroundColor(.secondary)
            Text(strings[.noTasksYet]).font(.headline)
            Text(strings[.createFirstTask]).font(.subheadline).foregroundColor(.secondary)
            if store.canAddTask {
                SwiftUI.Button(action: { todoStore.openEditor(for: nil, project: store.project) }) { Label(strings[.addTask], systemImage: "plus") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Web list mode: one section per column (custom columns include empty ones).
    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ToDoTheme.rowSpacing) {
                ForEach(store.columns) { column in listSection(column) }
            }
            .padding(.vertical, 2)
        }
    }

    private func columnHeader(_ column: ProjectColumn, count: Int, size: CGFloat) -> some View {
        HStack(spacing: 6) {
            if let color = column.color.flatMap({ NSColor(hex: $0) }) { Circle().fill(Color(color)).frame(width: 8, height: 8) }
            Text(column.label).font(.system(size: size, weight: .semibold)).lineLimit(1)
            Text("\(count)").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 1).background(ToDoTheme.neutral.opacity(0.18)).cornerRadius(8)
            Spacer()
        }
    }

    private func listSection(_ column: ProjectColumn) -> some View {
        let tasks = store.tasks(in: column)
        return Group {
            columnHeader(column, count: tasks.count, size: 13)
                .padding(.horizontal, 10).padding(.vertical, 6).background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
            if tasks.isEmpty {
                Text(strings[.sectionEmpty]).font(.system(size: 12)).foregroundColor(.secondary).padding(.horizontal, 12).padding(.vertical, 4)
            }
            ForEach(tasks) { task in
                ProjectTaskCard(store: store, todoStore: todoStore, task: task, compact: false)
            }
        }
    }

    private var board: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(store.columns) { column in boardColumn(column) }
            }
        }
    }

    private func boardColumn(_ column: ProjectColumn) -> some View {
        let tasks = store.tasks(in: column)
        return VStack(alignment: .leading, spacing: 6) {
            columnHeader(column, count: tasks.count, size: 12)
            ScrollView {
                VStack(spacing: 6) {
                    if tasks.isEmpty {
                        Text(strings[.noTasksInColumn]).font(.system(size: 11)).italic().foregroundColor(.secondary).padding(.vertical, 12)
                    }
                    ForEach(tasks) { task in
                        ProjectTaskCard(store: store, todoStore: todoStore, task: task, compact: true)
                    }
                }
            }
        }
        .padding(8)
        .frame(width: 240)
        .frame(maxHeight: .infinity, alignment: .top)
        .background((column.completes ? ToDoTheme.good : ToDoTheme.neutral).opacity(0.08))
        .cornerRadius(ToDoTheme.cornerRadius)
    }
}

/// A task in the project (board card or list row): title, due / TOP / tag chips, "Move to" menu.
private struct ProjectTaskCard: View {
    @ObservedObject var store: ProjectDetailStore
    @ObservedObject var todoStore: ToDoStore
    let task: ToDoTask
    let compact: Bool
    private var strings: ToDoStrings { store.strings }
    private var isUpdating: Bool { store.updatingTaskIds.contains(task.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !compact {
                SwiftUI.Button(action: { store.toggleComplete(task) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").font(.system(size: 16))
                        .foregroundColor(task.isCompleted ? ToDoTheme.good : .secondary)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if let emoji = task.iconEmoji { Text(emoji).font(.system(size: 12)) }
                    Text(task.title).font(.system(size: 13, weight: .medium)).strikethrough(task.isCompleted).lineLimit(2)
                }
                HStack(spacing: 4) {
                    if task.due_date != nil {
                        let state = ToDoDates.dueState(task.due_date, isCompleted: task.isCompleted)
                        ToDoChip(text: strings.format(.dueWithDate, ToDoStrings.dateToken, strings.dueLabel(task.due_date)), systemImage: "calendar",
                                 tint: state == .overdue ? ToDoTheme.overdue : (state == .today ? ToDoTheme.today : ToDoTheme.neutral))
                    }
                    let score = ToDoScoring.topScore(of: task)
                    if score > 0 { ToDoChip(text: "\(strings[.topShort]) \(ToDoScoring.rounded(score))", tint: ToDoTheme.accent) }
                    if !task.subtaskList.isEmpty { ToDoChip(text: "\(task.subtaskList.count) \(strings[.subtasks].lowercased())", systemImage: "checklist") }
                    if let tag = task.tagList.first(where: { $0.id != store.project.id }) { ToDoChip(text: strings.projectName(tag.text)) }
                }
            }
            Spacer(minLength: 4)
            if isUpdating {
                ProgressView().scaleEffect(0.4).frame(width: 14, height: 14)
            } else {
                Menu {
                    ForEach(store.columns) { column in
                        SwiftUI.Button(action: { store.move(task, toColumn: column.id) }) { Text(column.label) }
                    }
                } label: {
                    Image(systemName: "arrow.right.square").foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle()).frame(width: 22).help(strings[.moveTo])
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ToDoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ToDoTheme.separator))
        .cornerRadius(6)
        .opacity(task.isCompleted ? 0.7 : 1)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { todoStore.openEditor(for: task) }
        .contextMenu {
            SwiftUI.Button(action: { todoStore.openEditor(for: task) }) { Text(strings[.editTaskTitle]) }
            ForEach(store.columns) { column in
                SwiftUI.Button(action: { store.move(task, toColumn: column.id) }) { Text("\(strings[.moveTo]): \(column.label)") }
            }
        }
    }
}

// MARK: - Notes

private struct ProjectNotesView: View {
    @ObservedObject var store: ProjectDetailStore
    private var strings: ToDoStrings { store.strings }
    private static let listWidth: CGFloat = 280

    var body: some View {
        Group {
            if store.isNotesLoading && store.notes.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.notes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "note.text").font(.system(size: 36)).foregroundColor(.secondary)
                    Text(strings[.noNotesYet]).font(.headline)
                    Text(strings[.noNotesDescription]).font(.subheadline).foregroundColor(.secondary)
                    SwiftUI.Button(action: { store.createNote() }) { Label(strings[.createNote], systemImage: "plus") }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 10) {
                    notesList.frame(width: ProjectNotesView.listWidth)
                    noteDetail.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notesList: some View {
        VStack(spacing: 6) {
            SwiftUI.Button(action: { store.createNote() }) { Label(strings[.createNote], systemImage: "plus") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(store.notes) { note in
                        let isOpen = store.openNote?.id == note.id
                        HStack(spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.title.isEmpty ? strings[.untitledNote] : note.title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                Text(strings.format(.lastEdited, ToDoStrings.dateToken, ToDoDates.abbreviated(note.updated_at))).font(.system(size: 10)).foregroundColor(.secondary)
                            }
                            Spacer()
                            SwiftUI.Button(action: { store.pendingConfirmation = .deleteNote(note) }) { Image(systemName: "trash").foregroundColor(.secondary) }
                                .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.delete])
                        }
                        .padding(8)
                        .background(isOpen ? ToDoTheme.accent.opacity(0.12) : ToDoTheme.card)
                        .cornerRadius(6)
                        .contentShape(Rectangle())
                        .onTapGesture { store.open(note) }
                        .pointingHandCursor()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var noteDetail: some View {
        if let note = store.openNote {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.title.isEmpty ? strings[.untitledNote] : note.title).font(.system(size: 16, weight: .semibold))
                    Spacer()
                    SwiftUI.Button(action: { if let url = store.webURL(for: note) { NSWorkspace.shared.open(url) } }) {
                        Label(strings[.editOnWeb], systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
                }
                if store.isNoteLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        let text = note.plainText
                        Text(text.isEmpty ? strings[.emptyNote] : text)
                            .font(.system(size: 13))
                            .foregroundColor(text.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(12)
            .background(ToDoTheme.card)
            .cornerRadius(ToDoTheme.cornerRadius)
        } else {
            Text(strings[.selectNoteTitle]).font(.system(size: 13)).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
        }
    }
}

// MARK: - Members sheet

struct ProjectMembersSheet: View {
    @ObservedObject var store: ProjectDetailStore
    @SwiftUI.State private var showInvite = false
    @SwiftUI.State private var email = ""
    @SwiftUI.State private var role: ProjectMemberRole = .member
    @SwiftUI.State private var attemptedInvite = false
    private var strings: ToDoStrings { store.strings }
    private var emailIsValid: Bool { ProjectMembersSheet.isEmail(email) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(strings.format(.membersWithCount, ToDoStrings.countToken, String(store.members.count))).font(.title2).bold()
                Spacer()
                if store.actions(for: ProjectMember(id: "", role: nil)).canInvite {
                    SwiftUI.Button(action: { showInvite.toggle() }) { Label(strings[.inviteMember], systemImage: "person.badge.plus") }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 28))
                }
                SwiftUI.Button(action: { store.isMembersVisible = false }) { Text(strings[.close]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28)).keyboardShortcut(.cancelAction)
            }
            if showInvite { inviteForm }
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(store.members) { member in memberRow(member) }
                }
            }
            if let message = store.statusMessage { Text(message).font(.system(size: 12)).foregroundColor(.secondary) }
        }
        .padding(16)
        .frame(minWidth: 560, idealWidth: 600, minHeight: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var inviteForm: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                TextField(strings[.emailPlaceholder], text: $email, onCommit: invite).textFieldStyle(RoundedBorderTextFieldStyle())
                if attemptedInvite && !emailIsValid {
                    Text(strings[.invalidEmail]).font(.system(size: 11)).foregroundColor(ToDoTheme.overdue)
                }
            }
            Picker("", selection: $role) {
                Text(strings.roleLabel(.member)).tag(ProjectMemberRole.member)
                Text(strings.roleLabel(.admin)).tag(ProjectMemberRole.admin)
            }
            .labelsHidden().pickerStyle(MenuPickerStyle()).frame(width: 130)
            SwiftUI.Button(action: invite) { Text(store.isInviting ? strings[.inviting] : strings[.invite]) }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 28))
                .disabled(store.isInviting || email.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(10).background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
    }

    private func invite() {
        attemptedInvite = true
        guard emailIsValid else { return }
        store.invite(email: email.trimmingCharacters(in: .whitespaces), role: role) { success in
            if success { email = ""; role = .member; attemptedInvite = false; showInvite = false }
        }
    }

    private func memberRow(_ member: ProjectMember) -> some View {
        let actions = store.actions(for: member)
        let busy = store.busyMemberIds.contains(member.id)
        return HStack(spacing: 10) {
            Circle().fill(store.isMe(member) ? ToDoTheme.accent : ToDoTheme.neutral).frame(width: 28, height: 28)
                .overlay(Text(ProjectMembersSheet.initial(member, isMe: store.isMe(member))).font(.system(size: 12, weight: .bold)).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(store.displayName(member)).font(.system(size: 13, weight: .medium))
                HStack(spacing: 6) {
                    if !store.isMe(member), let email = member.email, !email.isEmpty { Text(email).font(.system(size: 11)).foregroundColor(.secondary) }
                    ToDoChip(text: strings.roleLabel(member.memberRole), systemImage: "person", tint: member.memberRole == .member ? ToDoTheme.neutral : Color(NSColor.systemBlue))
                    ToDoChip(text: strings.invitationLabel(member.invitationStatus),
                             tint: member.invitationStatus == .accepted ? ToDoTheme.good : (member.invitationStatus == .pending ? ToDoTheme.today : ToDoTheme.overdue))
                }
            }
            Spacer()
            if busy {
                ProgressView().scaleEffect(0.5).frame(width: 16, height: 16)
            } else {
                if actions.canChangeRole {
                    Picker("", selection: Binding(get: { member.memberRole ?? .member }, set: { store.changeRole(member, to: $0) })) {
                        Text(strings.roleLabel(.member)).tag(ProjectMemberRole.member)
                        Text(strings.roleLabel(.admin)).tag(ProjectMemberRole.admin)
                    }
                    .labelsHidden().pickerStyle(MenuPickerStyle()).frame(width: 130)
                }
                if actions.canRemove {
                    SwiftUI.Button(action: { store.remove(member) }) { Image(systemName: "trash").foregroundColor(ToDoTheme.overdue) }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.removeMember])
                }
            }
        }
        .padding(8).background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
    }

    /// Web `getMemberAvatarInitial`: first letter of the email, else O for the owner, else U.
    private static func initial(_ member: ProjectMember, isMe: Bool) -> String {
        if let first = member.email?.first { return String(first).uppercased() }
        return member.memberRole == .owner ? "O" : "U"
    }

    private static func isEmail(_ value: String) -> Bool {
        let pattern = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"
        return value.trimmingCharacters(in: .whitespaces).range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Settings sheet

struct ProjectSettingsSheet: View {
    @ObservedObject var store: ProjectDetailStore
    @SwiftUI.State private var form: ProjectDetailStore.SettingsForm
    @SwiftUI.State private var original: ProjectDetailStore.SettingsForm
    @SwiftUI.State private var newStatusLabel = ""
    @SwiftUI.State private var showDueDatePicker = false
    private var strings: ToDoStrings { store.strings }

    init(store: ProjectDetailStore) {
        self.store = store
        let form = ProjectDetailStore.SettingsForm(project: store.project)
        _form = SwiftUI.State(initialValue: form)
        _original = SwiftUI.State(initialValue: form)
    }

    private var trimmedName: String { form.name.trimmingCharacters(in: .whitespaces) }
    /// Web `CreateProjectModal` name rules, ported here for parity.
    private var nameError: String? {
        guard !trimmedName.isEmpty else { return nil }
        if trimmedName.count > ProjectDetailStore.nameMaxLength { return strings[.nameTooLong] }
        if trimmedName.allSatisfy({ $0.isNumber }) { return strings[.nameOnlyDigits] }
        return nil
    }
    private var canSave: Bool { form != original && !store.isSavingSettings && !(store.canEditName && (trimmedName.isEmpty || nameError != nil)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(strings[.settings]).font(.title2).bold()
                Spacer()
                SwiftUI.Button(action: { store.isSettingsVisible = false }) { Text(strings[.cancel]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28)).keyboardShortcut(.cancelAction)
                SwiftUI.Button(action: { store.saveSettings(form) { _ in } }) { Text(store.isSavingSettings ? strings[.saving] : strings[.save]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 28)).disabled(!canSave)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    labelled(strings[.name]) {
                        TextField(strings[.name], text: $form.name).textFieldStyle(RoundedBorderTextFieldStyle()).disabled(!store.canEditName)
                        if let error = nameError { Text(error).font(.system(size: 11)).foregroundColor(ToDoTheme.overdue) }
                    }
                    labelled(strings[.description]) { ToDoMultilineEditor(text: $form.description, placeholder: strings[.description], height: 90) }
                    HStack(alignment: .top, spacing: 16) {
                        labelled(strings[.filterDueDate]) {
                            HStack(spacing: 6) {
                                SwiftUI.Button(action: { showDueDatePicker.toggle() }) {
                                    Label(form.dueDate.map { strings.dueLabel(ToDoDates.ymd($0)) } ?? strings[.noDueDate], systemImage: "calendar")
                                }
                                .buttonStyle(BorderedButtonStyle()).pointingHandCursor()
                                if form.dueDate != nil {
                                    SwiftUI.Button(action: { form.dueDate = nil }) { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
                                        .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.clear])
                                }
                            }
                            if showDueDatePicker {
                                DatePicker("", selection: Binding(get: { form.dueDate ?? Date() }, set: { form.dueDate = $0 }), displayedComponents: [.date])
                                    .datePickerStyle(GraphicalDatePickerStyle()).labelsHidden()
                            }
                        }
                        labelled(strings[.importance]) {
                            Picker("", selection: $form.importance) {
                                ForEach(PortfolioImportance.allCases, id: \.self) { Text(strings.importanceLabel($0)).tag($0) }
                            }
                            .labelsHidden().pickerStyle(MenuPickerStyle()).frame(width: 140)
                        }
                    }
                    statusesSection
                    if store.canManageLifecycle { lifecycleSection }
                    if store.canDeleteProject { dangerZone }
                }
                .padding(.trailing, 4)
            }
        }
        .padding(16)
        .frame(minWidth: 560, idealWidth: 600, minHeight: 560, idealHeight: 640)
        .background(Color(NSColor.windowBackgroundColor))
    }

    /// Web custom-statuses editor: rename, completes-task, reorder, delete, add.
    private var statusesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(strings[.customStatuses]) (\(form.statuses.count))").font(.system(size: 12, weight: .semibold))
            ForEach(Array(form.statuses.enumerated()), id: \.element.id) { index, _ in
                statusRow(index)
            }
            HStack(spacing: 8) {
                TextField(strings[.newStatusPlaceholder], text: $newStatusLabel, onCommit: addStatus).textFieldStyle(RoundedBorderTextFieldStyle())
                SwiftUI.Button(action: addStatus) { Text(strings[.addStatus]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                    .disabled(newStatusLabel.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func statusRow(_ index: Int) -> some View {
        let color = form.statuses[index].color.flatMap { NSColor(hex: $0) } ?? NSColor.tertiaryLabelColor
        let label = Binding<String>(get: { form.statuses[index].label }, set: { form.statuses[index].label = $0 })
        let completes = Binding<Bool>(get: { form.statuses[index].should_complete_task ?? false }, set: { form.statuses[index].should_complete_task = $0 })
        let isLast = index == form.statuses.count - 1
        return HStack(spacing: 8) {
            Circle().fill(Color(color)).frame(width: 10, height: 10)
            TextField("", text: label).textFieldStyle(RoundedBorderTextFieldStyle())
            Toggle(strings[.completesTask], isOn: completes).font(.system(size: 11))
            statusButton("chevron.up", disabled: index == 0) { form.statuses.swapAt(index, index - 1) }
            statusButton("chevron.down", disabled: isLast) { form.statuses.swapAt(index, index + 1) }
            statusButton("trash", disabled: false) { form.statuses.remove(at: index) }
        }
        .padding(6).background(ToDoTheme.card).cornerRadius(6)
    }

    private func statusButton(_ symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) { Image(systemName: symbol).foregroundColor(symbol == "trash" ? ToDoTheme.overdue : .secondary) }
            .buttonStyle(PlainButtonStyle()).pointingHandCursor().disabled(disabled)
    }

    private func addStatus() {
        let label = newStatusLabel.trimmingCharacters(in: .whitespaces)
        guard !label.isEmpty else { return }
        form.statuses.append(ProjectCustomStatus(id: UUID().uuidString.lowercased(), label: label, color: ProjectDetailStore.defaultStatusColor,
                                                 order: form.statuses.count, should_complete_task: false))
        newStatusLabel = ""
    }

    /// Web `getProjectLifecycleActionVisibility`.
    private var lifecycleSection: some View {
        let status = store.project.lifecycleStatus
        return HStack(spacing: 8) {
            if status == .active {
                SwiftUI.Button(action: { store.pendingConfirmation = .markComplete }) { Label(strings[.markCompleteProject], systemImage: "checkmark.square") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
            if status != .archived {
                SwiftUI.Button(action: { store.pendingConfirmation = .archive }) { Label(strings[.archiveProject], systemImage: "archivebox") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
            if status != .active {
                SwiftUI.Button(action: { store.pendingConfirmation = .restore }) { Label(strings[.restoreProject], systemImage: "arrow.uturn.backward") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings[.dangerZone]).font(.system(size: 12, weight: .semibold)).foregroundColor(ToDoTheme.overdue)
            Text(strings[.deleteWarning]).font(.system(size: 11)).foregroundColor(.secondary)
            SwiftUI.Button(action: { store.pendingConfirmation = .delete }) { Label(strings[.deleteProject], systemImage: "trash") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: ToDoTheme.cornerRadius).stroke(ToDoTheme.overdue.opacity(0.5)))
    }

    private func labelled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 12, weight: .semibold))
            content()
        }
    }
}
