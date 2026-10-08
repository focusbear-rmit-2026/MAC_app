//
//  ProjectDetailView.swift
//  Focus Bear
//
//  One project, the native version of the web's `ProjectDetailPage`: header (back, lifecycle badge,
//  Members / Settings / Leave), Tasks (list or board by the project's columns, add task, move
//  between columns, drag a card to another) and Notes (create / rename / delete; the body is a Yjs
//  document edited natively by `ProjectNoteEditor`, with "Edit on the web" alongside it), plus the
//  Members and Settings sheets.
//

import SwiftUI
import AppKit

struct ProjectDetailView: View {
    @ObservedObject var store: ProjectDetailStore
    @ObservedObject var todoStore: ToDoStore
    let onBack: () -> Void
    let onShowInTaskList: () -> Void

    @SwiftUI.State private var isIconPopoverShown = false
    @SwiftUI.State private var isDuePopoverShown = false
    @SwiftUI.State private var isOutcomePopoverShown = false
    @SwiftUI.State private var isTagPopoverShown = false

    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            navRow
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(UITestContract.Identifier.Projects.detail)
            if store.notFound {
                notFound
            } else {
                if store.project.lifecycleStatus != .active { lifecycleBanner }
                identityRow
                if store.pageView == .tasks { ProjectTasksView(store: store, todoStore: todoStore) } else { ProjectNotesView(store: store) }
            }
        }
        .sheet(isPresented: $store.isMembersVisible) { ProjectMembersSheet(store: store) }
        .sheet(isPresented: $store.isSettingsVisible) {
            ProjectSettingsSheet(store: store, knownTags: ProjectTags.known(in: todoStore.projects))
        }
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
                .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.projectBackButton)
            if let message = store.statusMessage {
                Text(message).font(.system(size: 12)).foregroundColor(.secondary).transition(.opacity)
            }
            Spacer()
            SwiftUI.Button(action: onShowInTaskList) { Label(strings[.showInTaskList], systemImage: "line.horizontal.3") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
                .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.projectShowInTaskListButton)
            if store.canOpenMembers {
                SwiftUI.Button(action: { store.isMembersVisible = true }) {
                    Label(strings.format(.membersWithCount, ToDoStrings.countToken, String(store.members.count)), systemImage: "person.2")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
            if store.canOpenSettings {
                SwiftUI.Button(action: { store.isSettingsVisible = true }) { Label(strings[.settings], systemImage: "gearshape") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
                    .accessibilityIdentifier(UITestContract.Identifier.Projects.settingsButton)
            }
            if store.canLeave {
                SwiftUI.Button(action: { store.requestConfirmation(.leave) }) { Text(strings[.leave]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
        }
    }

    private var identityRow: some View {
        HStack(alignment: .top, spacing: 12) {
            // The icon belongs beside the name it labels. It sat past the tab picker at the far
            // right, where it read as another control rather than as part of the project's identity.
            projectIcon
            VStack(alignment: .leading, spacing: 3) {
                InlineRenameField(display: strings.projectName(store.project.name), value: store.project.name,
                                  placeholder: strings[.projectNamePlaceholder], fontSize: ProjectDetailView.nameFontSize,
                                  fontWeight: .bold, editHint: strings[.renameProjectHint],
                                  isEditable: store.canEditName,
                                  headingIdentifier: UITestContract.Identifier.TasksRegression.projectNameHeading,
                                  fieldIdentifier: UITestContract.Identifier.TasksRegression.projectRenameField) { store.rename(to: $0) }
                if let description = store.project.description, !description.isEmpty {
                    Text(description).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(2)
                }
                if store.project.isSynced {
                    Text(strings.projectSyncSource(store.project)).font(.system(size: 12)).foregroundColor(.secondary)
                }
                metaRow
                tagsRow
            }
            Spacer()
            Picker("", selection: $store.pageView) {
                Text(strings[.detailTabTasks]).tag(ProjectDetailStore.PageView.tasks)
                Text(strings[.detailTabNotes]).tag(ProjectDetailStore.PageView.notes)
            }
            .pickerStyle(SegmentedPickerStyle()).labelsHidden().frame(width: 180)
            .onChange(of: store.pageView) { view in if view == .notes { store.loadNotes() } }
        }
    }

    /// Due date and outcome beside the project name, so the two things a project is planned by are
    /// readable — and changeable — without opening Settings first (report 2026-09-15_10-27-17,
    /// follow-up). A viewer who may not edit sees the same facts as plain chips.
    private var metaRow: some View {
        HStack(spacing: 6) {
            if store.canEditName {
                SwiftUI.Button(action: { isDuePopoverShown = true }) { dueChip }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.editDueDate])
                    .popover(isPresented: $isDuePopoverShown, arrowEdge: .bottom) {
                        ToDoDueDatePopover(strings: strings, currentDue: store.project.due_date) { day in
                            isDuePopoverShown = false
                            store.setDueDate(day)
                        }
                    }
                SwiftUI.Button(action: { isOutcomePopoverShown = true }) { outcomeChip }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.editOutcome])
                    .popover(isPresented: $isOutcomePopoverShown, arrowEdge: .bottom) {
                        // The very picker the Settings sheet and the task editor use, so the header
                        // can never offer different words for the same number.
                        ForecastOutcomePicker(wireValue: Binding(get: { store.project.outcome },
                                                                 set: { store.setOutcome($0) }))
                            .padding(12)
                    }
            } else {
                dueChip
                outcomeChip
            }
        }
    }

    /// The project's tags, on their own line under the due/outcome chips.
    ///
    /// A separate line rather than more chips in `metaRow`: tags are open-ended where due and outcome
    /// are single values, so they are the part that grows, and keeping them off the name line keeps
    /// that line stable. A viewer who may not edit sees the tags without the add control, and an
    /// untagged project shows nothing at all — an empty label would be noise on most projects.
    ///
    /// The header is a *display*: past `maxVisibleTags` it collapses to a "+N" chip, the same way
    /// `ToDoTaskRow` handles a task in many projects. Everything — adding and removing — happens in
    /// the popover, so there is one place to manage tags and the header cannot grow without bound.
    @ViewBuilder
    private var tagsRow: some View {
        let tags = store.tags
        if store.canEditName || !tags.isEmpty {
            HStack(spacing: 6) {
                ForEach(tags.prefix(ProjectDetailView.maxVisibleTags), id: \.self) { tag in
                    tagChipButton(ToDoChip(text: tag, systemImage: "tag", tint: ToDoTheme.accent), help: tag)
                }
                if tags.count > ProjectDetailView.maxVisibleTags {
                    let hidden = tags.count - ProjectDetailView.maxVisibleTags
                    tagChipButton(ToDoChip(text: "+\(hidden)", tint: ToDoTheme.neutral),
                                  help: tags.dropFirst(ProjectDetailView.maxVisibleTags).joined(separator: "\n"))
                }
                // Always shown, not just on an untagged project: with the add control hidden behind
                // "click one of your existing tags", a user with one tag has no visible way to add a
                // second. The chip is the affordance; the tags beside it are also clickable.
                if store.canEditName {
                    tagChipButton(ToDoChip(text: tags.isEmpty ? strings[.addProjectTag] : "",
                                           systemImage: "plus", tint: ToDoTheme.accent),
                                  help: strings[.addProjectTag])
                }
            }
            .popover(isPresented: $isTagPopoverShown, arrowEdge: .bottom) {
                tagPopover.frame(width: ProjectDetailView.tagPopoverWidth)
            }
        }
    }

    /// A tag chip that opens the manage popover. Read-only viewers get the chip without the click,
    /// so nothing offers an edit that would fail.
    @ViewBuilder
    private func tagChipButton(_ chip: ToDoChip, help: String) -> some View {
        if store.canEditName {
            SwiftUI.Button(action: { isTagPopoverShown = true }) { chip.contentShape(Rectangle()) }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .help(help)
        } else {
            chip.help(help)
        }
    }

    private var tagPopover: some View {
        ProjectTagEditor(strings: strings,
                         applied: store.tags,
                         known: ProjectTags.known(in: todoStore.projects),
                         onAdd: { store.addTag($0) },
                         onRemove: { store.removeTag($0) })
    }

    private var dueChip: some View {
        let due = store.project.due_date
        let hasDue = !(due ?? "").isEmpty
        return ToDoChip(text: hasDue ? strings.format(.dueWithDate, ToDoStrings.dateToken, strings.dueLabel(due)) : strings[.setDueDate],
                        systemImage: "calendar",
                        tint: hasDue ? ToDoTheme.dueTint(due, isCompleted: false) : ToDoTheme.neutral)
    }

    private var outcomeChip: some View {
        let wire = store.project.outcome
        let text = wire.map { strings.outcomeOptionLabel(displayValue: $0 / ToDoScoring.outcomeWireFactor) } ?? strings[.setOutcome]
        return ToDoChip(text: text, systemImage: "flag", tint: ToDoTheme.neutral)
    }

    /// The icon is a button when the user may edit the project: clicking it picks a new emoji
    /// (report 2026-09-14_20-07-42). Read-only members still just see the glyph.
    @ViewBuilder
    private var projectIcon: some View {
        if store.canEditName {
            SwiftUI.Button(action: { isIconPopoverShown = true }) {
                ProjectIconGlyph(icon: store.project.iconEmoji, size: ProjectDetailView.iconSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .help(strings[.projectIconChange])
            .popover(isPresented: $isIconPopoverShown, arrowEdge: .bottom) {
                ProjectIconPicker(strings: strings) { chosen in
                    // Close first: the picker must go away the moment a choice is made, not when
                    // the server answers.
                    isIconPopoverShown = false
                    store.setIcon(chosen)
                }
            }
        } else {
            ProjectIconGlyph(icon: store.project.iconEmoji, size: ProjectDetailView.iconSize)
                .help(strings[.projectIconAutomatic])
        }
    }

    /// Past this the header collapses to a "+N" chip, as a task row does for its projects.
    private static let maxVisibleTags = 6
    private static let tagPopoverWidth: CGFloat = 230
    private static let iconSize: CGFloat = 22
    private static let nameFontSize: CGFloat = 18

    private var notFound: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.questionmark").font(.system(size: 36)).foregroundColor(.secondary)
            Text(strings[.projectNotFound]).font(.headline)
            SwiftUI.Button(action: onBack) { Text(strings[.backToProjects]) }.buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The user asked for an unmistakable marker: a project that is no longer active says so across
    /// the top of its detail, with the one-click way back out.
    private var lifecycleBanner: some View {
        let isArchived = store.project.lifecycleStatus == .archived
        return HStack(alignment: .center, spacing: 10) {
            Image(systemName: isArchived ? "archivebox.fill" : "checkmark.seal.fill")
                .foregroundColor(isArchived ? ToDoTheme.neutral : ToDoTheme.today)
            VStack(alignment: .leading, spacing: 2) {
                Text(strings.projectStatusLabel(store.project.lifecycleStatus)).font(.system(size: 13, weight: .bold))
                Text(strings[isArchived ? .projectArchivedBanner : .projectCompletedBanner])
                    .font(.system(size: 12)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if store.canManageLifecycle {
                SwiftUI.Button(action: { store.setLifecycle(.active) }) { Label(strings[.restoreProject], systemImage: "arrow.uturn.backward") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 28))
            }
        }
        .padding(12)
        .background((isArchived ? ToDoTheme.neutral : ToDoTheme.today).opacity(0.12))
        .cornerRadius(ToDoTheme.cornerRadius)
    }

    private func confirmationTitle(_ confirmation: ProjectDetailStore.PendingConfirmation) -> String {
        switch confirmation {
        case .leave: return strings[.leave]
        case .delete: return strings[.deleteProject]
        case .deleteNote: return strings[.delete]
        }
    }

    private func confirmationMessage(_ confirmation: ProjectDetailStore.PendingConfirmation) -> String {
        switch confirmation {
        case .leave: return strings[.leaveConfirm]
        case .delete: return strings[.deleteProjectConfirm]
        case .deleteNote: return strings[.deleteNoteConfirm]
        }
    }

    private func confirmationButton(_ confirmation: ProjectDetailStore.PendingConfirmation) -> String {
        switch confirmation {
        case .leave: return strings[.leave]
        case .delete, .deleteNote: return strings[.delete]
        }
    }
}

/// Manage a project's tags: add by typing a new one or picking one already in use, remove the ones
/// already applied.
///
/// Deliberately **not** `SearchableComboBoxField`, despite that being the app's existing "type and
/// choose" control: it resolves whatever is typed to an id from its fixed option list and overwrites
/// the text with the resolved name, so a tag the user is inventing — the whole point of the first
/// `#phd` — is erased as they type it. The suggestion list below gives the same recognition benefit
/// without closing off new values.
private struct ProjectTagEditor: View {
    let strings: ToDoStrings
    /// Tags already on this project: shown for removal, and not offered as suggestions.
    let applied: [String]
    /// Every tag in use across the user's projects.
    let known: [String]
    let onAdd: (String) -> Void
    let onRemove: (String) -> Void

    @SwiftUI.State private var typed = ""

    private static let listMaxHeight: CGFloat = 130
    private static let captionSize: CGFloat = 11
    private static let fieldHeight: CGFloat = 22
    private static let glyphSize: CGFloat = 10

    /// Suggestions matching what has been typed, minus the ones already on this project.
    private var suggestions: [String] {
        let query = ProjectTags.normalize(typed) ?? ""
        let appliedSet = Set(applied)
        return known.filter { !appliedSet.contains($0) && (query.isEmpty || $0.contains(query)) }
    }

    /// The tag the typed text would add, or nil when it would change nothing — blank, already
    /// applied, or the project is at the cap. Nil is also what disables Return.
    private var pendingTag: String? {
        ProjectTags.adding(typed, to: applied).flatMap { $0.last }
    }

    private var isFull: Bool { applied.count >= ProjectTags.maxCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isFull {
                Text(strings[.projectTagsFull])
                    .font(.system(size: ProjectTagEditor.captionSize)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ReturnGuardTextField(text: $typed, placeholder: strings[.projectTagPlaceholder],
                                     onCommit: commitTyped)
                    .frame(height: ProjectTagEditor.fieldHeight)
                if let tag = pendingTag {
                    SwiftUI.Button(action: commitTyped) {
                        Label(strings.format(.addProjectTagNamed, ToDoStrings.titleToken, tag), systemImage: "plus")
                    }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 26))
                }
            }
            if !applied.isEmpty { appliedSection }
            if !isFull, !suggestions.isEmpty { suggestionsSection }
        }
        .padding(12)
    }

    private var appliedSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(strings[.projectTags])
                .font(.system(size: ProjectTagEditor.captionSize)).foregroundColor(.secondary)
            ForEach(applied, id: \.self) { tag in
                HStack(spacing: 4) {
                    Image(systemName: "tag").font(.system(size: ProjectTagEditor.glyphSize))
                        .foregroundColor(ToDoTheme.accent)
                    Text(tag).font(.system(size: 12))
                    Spacer()
                    SwiftUI.Button(action: { onRemove(tag) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: ProjectTagEditor.captionSize))
                            .foregroundColor(.secondary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    .help(strings.format(.removeProjectTag, ToDoStrings.titleToken, tag))
                    .accessibilityLabel(strings.format(.removeProjectTag, ToDoStrings.titleToken, tag))
                }
            }
        }
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(strings[.projectTagSuggestions])
                .font(.system(size: ProjectTagEditor.captionSize)).foregroundColor(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(suggestions, id: \.self) { tag in
                        SwiftUI.Button(action: { onAdd(tag) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "tag").font(.system(size: ProjectTagEditor.glyphSize))
                                Text(tag).font(.system(size: 12))
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    }
                }
            }
            .frame(maxHeight: ProjectTagEditor.listMaxHeight)
        }
    }

    /// Adds the typed tag and clears the field, so several can be added without reopening.
    private func commitTyped() {
        guard let tag = pendingTag else { return }
        typed = ""
        onAdd(tag)
    }
}

/// Pick a project's emoji without leaving the popover.
///
/// It deliberately does **not** call `NSApp.orderFrontCharacterPalette`: the system Character Viewer
/// is a separate floating panel that stays on screen after a choice and cannot be dismissed
/// programmatically, which is exactly what the report complained about (2026-09-14_20-07-42).
/// Choosing here reports the emoji straight back, so the caller can close the popover at once.
private struct ProjectIconPicker: View {
    let strings: ToDoStrings
    let onChoose: (String) -> Void

    @SwiftUI.State private var query = ""

    private static let columnCount = 8
    private static let cellSize: CGFloat = 28
    private static let cellSpacing: CGFloat = 4
    private static let emojiSize: CGFloat = 18
    private static let popoverWidth: CGFloat = 288
    private static let gridMaxHeight: CGFloat = 196
    private static let captionSize: CGFloat = 11

    private var choices: [ProjectIconChoice] { ProjectIcon.choices(matching: query) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ReturnGuardTextField(text: $query, placeholder: strings[.projectIconSearch],
                                 onCommit: chooseTyped)
            if choices.isEmpty {
                Text(strings[.projectIconNoMatches]).font(.system(size: ProjectIconPicker.captionSize))
                    .foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            } else {
                grid
            }
            SwiftUI.Button(action: { onChoose(ProjectIcon.cleared) }) {
                Text(strings[.projectIconClear]).font(.system(size: ProjectIconPicker.captionSize))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle()).pointingHandCursor()
        }
        .padding(12)
        .frame(width: ProjectIconPicker.popoverWidth)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(ProjectIconPicker.cellSize),
                                                         spacing: ProjectIconPicker.cellSpacing),
                                     count: ProjectIconPicker.columnCount),
                      spacing: ProjectIconPicker.cellSpacing) {
                ForEach(choices) { choice in
                    SwiftUI.Button(action: { onChoose(choice.emoji) }) {
                        Text(choice.emoji).font(.system(size: ProjectIconPicker.emojiSize))
                            .frame(width: ProjectIconPicker.cellSize, height: ProjectIconPicker.cellSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                }
            }
        }
        .frame(maxHeight: ProjectIconPicker.gridMaxHeight)
    }

    /// Return in the search box takes whatever emoji was typed or pasted, so an emoji the
    /// catalogue does not carry still works.
    private func chooseTyped() {
        let typed = ProjectIcon.normalise(query)
        guard !typed.isEmpty else { return }
        onChoose(typed)
    }
}

/// What a half-typed inline rename should do when its field goes away.
///
/// Navigating away — Back, or the whole screen closing — is not "throw this away": the user typed a
/// new title and left, which everywhere else in this app means keep it (`popoverWillClose` saves a
/// click-away for the same reason). Escape is the discard route, and it leaves nothing pending
/// because it clears the edit first. Blank and unchanged titles are not renames.
enum InlineRenameDismissal: Equatable {
    case save(String)
    case discard

    static func onDismiss(draft: String, value: String, isEditing: Bool) -> InlineRenameDismissal {
        guard isEditing else { return .discard }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != value else { return .discard }
        return .save(trimmed)
    }
}

/// A heading that turns into a text field when clicked, so renaming doesn't mean opening a form.
/// Return or clicking away commits; Escape puts the old value back. Without `isEditable` it is just
/// the heading, with no hover affordance to promise an edit that would be refused.
///
/// Shared by the project name and the note title: both are a plain string on the server that the
/// Mac may overwrite last-write-wins, and their edit affordance must not drift apart.
private struct InlineRenameField: View {
    /// What to show — already localised / defaulted, so it can differ from the stored value.
    let display: String
    /// The stored value, which is what an edit starts from and commits against.
    let value: String
    let placeholder: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let editHint: String
    let isEditable: Bool
    /// Whether a rename is in progress, for callers that must give Escape to the field while it is.
    var onEditingChanged: (Bool) -> Void = { _ in }
    /// Empty is SwiftUI's "none".
    var headingIdentifier = ""
    var fieldIdentifier: String? = nil
    let onCommit: (String) -> Void

    @SwiftUI.State private var isEditing = false
    @SwiftUI.State private var draft = ""

    private static let editorWidth: CGFloat = 380

    var body: some View {
        Group {
            if isEditing {
                // Commit on blur as well as Return. Typing a note title and clicking into the note body
                // (rather than pressing Return) left the new title in a field nobody read: the list kept
                // saying "Untitled note" and nothing reached the server (report 2026-09-14_16-18-22).
                ReturnGuardTextField(text: $draft, placeholder: placeholder,
                                     onCommit: commit, onEndEditing: commit,
                                     accessibilityIdentifier: fieldIdentifier)
                    .frame(width: InlineRenameField.editorWidth)
                    .onExitCommand(perform: cancel)
            } else if isEditable {
                heading
                    .contentShape(Rectangle())
                    .onTapGesture(perform: beginEditing)
                    .pointingHandCursor()
                    .help(editHint)
            } else {
                heading
            }
        }
        // A reload, or a different project / note opened, must not leave a stale draft over the new
        // value — and must not strand the field in edit mode over something else's name.
        .onChange(of: value) { newValue in
            draft = newValue
            setEditing(false)
        }
        // Clicking "Back" (or the screen closing) removes this field without the field editor ever
        // resigning, so `controlTextDidEndEditing` never fires and the typed title was dropped
        // (report 2026-09-15_20-24-10). Save it on the way out; nothing is notified because the
        // caller is going away with us.
        .onDisappear {
            guard case .save(let title) = dismissal else { return }
            isEditing = false
            onCommit(title)
        }
    }

    private var dismissal: InlineRenameDismissal {
        InlineRenameDismissal.onDismiss(draft: draft, value: value, isEditing: isEditing)
    }

    private var heading: some View {
        Text(display).font(.system(size: fontSize, weight: fontWeight)).lineLimit(1)
            .accessibilityIdentifier(headingIdentifier)
    }

    private func beginEditing() {
        draft = value
        setEditing(true)
    }

    private func cancel() {
        draft = value
        setEditing(false)
    }

    private func setEditing(_ editing: Bool) {
        guard isEditing != editing else { return }
        isEditing = editing
        onEditingChanged(editing)
    }

    /// Idempotent: leaving edit mode tears the field down, which fires end-editing again. Clearing
    /// `isEditing` first makes that second call a no-op, so one rename never becomes two PUTs.
    private func commit() {
        guard isEditing else { return }
        let outcome = dismissal
        setEditing(false)
        guard case .save(let title) = outcome else { return }
        onCommit(title)
    }
}

// MARK: - Tasks (list / board)

private struct ProjectTasksView: View {
    @ObservedObject var store: ProjectDetailStore
    @ObservedObject var todoStore: ToDoStore
    /// Which card is being dragged and which column it is over. Starting, crossing a column and
    /// dropping are the only changes it publishes, so the columns redraw on those and not per pixel.
    @StateObject private var drag = ProjectCardDrag()
    /// The pointer itself, on its own object: it changes with every mouse movement and only the
    /// floating preview needs to follow it.
    @StateObject private var pointer = ProjectCardDragPointer()
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
        .coordinateSpace(name: ProjectTasksView.dragSpace)
        .onPreferenceChange(ProjectColumnFramesKey.self) { drag.columnFrames = $0 }
        .overlay(dragPreview, alignment: .topLeading)
    }

    /// The card under the pointer while it is being dragged. Drawn over the whole tasks area rather
    /// than inside a column so it is never clipped by a column's scroll view, and hit-testing is off
    /// so it cannot steal the drop from the column underneath it.
    @ViewBuilder private var dragPreview: some View {
        if let task = drag.task {
            ProjectCardDragPreview(pointer: pointer, title: task.title, hint: dropHint)
        }
    }

    /// What dropping here would do, phrased as the change rather than the column: a column flagged
    /// `should_complete_task` finishes the task, any other column reopens a finished one. Silent
    /// over the column the card came from, which is the no-op the drop already is.
    private var dropHint: String? {
        guard let task = drag.task, let columnId = drag.targetColumnId,
              let column = store.columns.first(where: { $0.id == columnId }) else { return nil }
        let statuses = store.project.usesCustomStatuses ? store.project.customStatuses : []
        let wasFinished = ToDoCompletionState.isFinished(task, customStatuses: statuses)
        if column.completes { return wasFinished ? nil : strings[.dropMarksComplete] }
        if wasFinished { return strings[.dropReopens] }
        return "\(strings[.moveTo]) \(column.label)"
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            if store.canAddTask {
                SwiftUI.Button(action: { todoStore.openEditor(for: nil, project: store.project) }) { Label(strings[.addTask], systemImage: "plus") }
                    .accessibilityIdentifier(UITestContract.Identifier.Projects.addTaskButton)
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 28))
            }
            ToDoSearchField(text: $store.searchQuery, placeholder: strings[.searchPlaceholder], isBusy: false,
                            accessibilityLabel: strings[.searchTasks])
                .frame(maxWidth: 240)
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
            .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.projectTasksModePicker)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist").font(.system(size: 36)).foregroundColor(.secondary)
            Text(strings[.noTasksYet]).font(.headline)
            Text(strings[.createFirstTask]).font(.subheadline).foregroundColor(.secondary)
            if store.canAddTask {
                SwiftUI.Button(action: { todoStore.openEditor(for: nil, project: store.project) }) { Label(strings[.addTask], systemImage: "plus") }
                    .accessibilityIdentifier(UITestContract.Identifier.Projects.addTaskButton)
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
        return VStack(alignment: .leading, spacing: ToDoTheme.rowSpacing) {
            columnHeader(column, count: tasks.count, size: 13)
                .padding(.horizontal, 10).padding(.vertical, 6).background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
            if tasks.isEmpty {
                Text(strings[.sectionEmpty]).font(.system(size: 12)).foregroundColor(.secondary).padding(.horizontal, 12).padding(.vertical, 4)
            }
            ForEach(tasks) { task in
                ProjectTaskCard(store: store, todoStore: todoStore, drag: drag, pointer: pointer, task: task, compact: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ProjectColumnDropTarget(column: column, drag: drag))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UITestContract.Identifier.Projects.column)
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
                        ProjectTaskCard(store: store, todoStore: todoStore, drag: drag, pointer: pointer, task: task, compact: true)
                    }
                }
            }
        }
        .padding(8)
        .frame(width: ProjectTasksView.boardColumnWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background((column.completes ? ToDoTheme.good : ToDoTheme.neutral).opacity(0.08))
        .cornerRadius(ToDoTheme.cornerRadius)
        .modifier(ProjectColumnDropTarget(column: column, drag: drag))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UITestContract.Identifier.Projects.column)
    }

    private static let boardColumnWidth: CGFloat = 240
    /// Columns report their frames, and the pointer is read, in this one space, so "which column is
    /// under the pointer" is a comparison and not a chain of conversions.
    static let dragSpace = "projectTasksDrag"
}

/// Which card is in flight and which column it would land in.
///
/// Published sparingly — a drag starts, crosses into another column, and ends — so the board redraws
/// on those three things. The pointer lives on `ProjectCardDragPointer` instead, because it changes
/// with every mouse movement and only the floating preview follows it.
private final class ProjectCardDrag: ObservableObject {
    @Published private(set) var task: ToDoTask?
    @Published private(set) var targetColumnId: String?
    /// Every column's frame in `ProjectTasksView.dragSpace`, refreshed by the layout itself.
    var columnFrames: [String: CGRect] = [:]
    /// Where the card started, so hovering its own column offers nothing: that drop is a no-op.
    private var originColumnId: String?

    func begin(_ task: ToDoTask, from originColumnId: String?) {
        self.task = task
        self.originColumnId = originColumnId
        targetColumnId = nil
    }

    func update(to point: CGPoint) {
        let column = ProjectBoardDrag.columnId(at: point, frames: columnFrames)
        targetColumnId = column == originColumnId ? nil : column
    }

    /// Ends the drag and reports the column to drop on, if the pointer is over one.
    func end() -> String? {
        defer { task = nil; targetColumnId = nil; originColumnId = nil }
        return targetColumnId
    }

    func isDragging(_ task: ToDoTask) -> Bool { self.task?.id == task.id }
}

/// The pointer during a card drag, in `ProjectTasksView.dragSpace`.
private final class ProjectCardDragPointer: ObservableObject {
    @Published var location: CGPoint = .zero
}

/// Each column publishes its frame so the drag can tell which one the pointer is over.
private struct ProjectColumnFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, latest in latest }
    }
}

/// Publishes a column's frame for the drag to hit-test against, and fills and outlines it in the
/// accent colour while the pointer is over it so the drop has somewhere visible to land — including
/// an empty column, which has nothing else to show. A list section is a column too, so both modes
/// take the same modifier.
private struct ProjectColumnDropTarget: ViewModifier {
    let column: ProjectColumn
    @ObservedObject var drag: ProjectCardDrag

    func body(content: Content) -> some View {
        let isTarget = drag.targetColumnId == column.id
        return content
            .background(GeometryReader { geometry in
                Color.clear.preference(key: ProjectColumnFramesKey.self,
                                       value: [column.id: geometry.frame(in: .named(ProjectTasksView.dragSpace))])
            })
            .overlay(
                RoundedRectangle(cornerRadius: ToDoTheme.cornerRadius)
                    .fill(ToDoTheme.accent.opacity(isTarget ? ProjectColumnDropTarget.targetFillOpacity : 0))
                    .overlay(RoundedRectangle(cornerRadius: ToDoTheme.cornerRadius)
                        .strokeBorder(ToDoTheme.accent, lineWidth: isTarget ? ProjectColumnDropTarget.targetBorderWidth : 0))
                    .allowsHitTesting(false)
            )
    }

    private static let targetBorderWidth: CGFloat = 2
    private static let targetFillOpacity: Double = 0.1
}

/// The card that follows the pointer, with what dropping it here would do. It observes the pointer
/// alone, so a mouse movement redraws this and nothing else.
private struct ProjectCardDragPreview: View {
    @ObservedObject var pointer: ProjectCardDragPointer
    let title: String
    let hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 12, weight: .medium)).lineLimit(1)
            if let hint = hint {
                Text(hint).font(.system(size: 10)).foregroundColor(ToDoTheme.accent).lineLimit(1)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .frame(maxWidth: ProjectCardDragPreview.maxWidth, alignment: .leading)
        .background(ToDoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ToDoTheme.accent, lineWidth: 1))
        .cornerRadius(6)
        .shadow(radius: ProjectCardDragPreview.shadowRadius)
        .opacity(ProjectCardDragPreview.opacity)
        .offset(x: pointer.location.x + ProjectCardDragPreview.pointerOffset,
                y: pointer.location.y + ProjectCardDragPreview.pointerOffset)
        .allowsHitTesting(false)
    }

    private static let maxWidth: CGFloat = 200
    private static let shadowRadius: CGFloat = 4
    private static let opacity: Double = 0.95
    /// Sits below and right of the pointer so the pointer itself, and the column under it, stay visible.
    private static let pointerOffset: CGFloat = 10
}

/// A task in the project (board card or list row): title, due / TOP / tag chips, "Move to" menu.
private struct ProjectTaskCard: View {
    @ObservedObject var store: ProjectDetailStore
    @ObservedObject var todoStore: ToDoStore
    @ObservedObject var drag: ProjectCardDrag
    let pointer: ProjectCardDragPointer
    let task: ToDoTask
    let compact: Bool
    private var strings: ToDoStrings { store.strings }
    private var isUpdating: Bool { store.updatingTaskIds.contains(task.id) }
    private var isBeingDragged: Bool { drag.isDragging(task) }

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
                        ToDoChip(text: strings.format(.dueWithDate, ToDoStrings.dateToken, strings.dueLabel(task.due_date)), systemImage: "calendar",
                                 tint: ToDoTheme.dueTint(task.due_date, isCompleted: task.isCompleted))
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
            } else if store.canMoveTask {
                Menu {
                    ForEach(store.columns) { column in
                        SwiftUI.Button(action: { store.move(task, toColumn: column.id) }) { Text(column.label) }
                    }
                } label: {
                    Image(systemName: "arrow.right.square").foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle()).frame(width: 22).help(strings[.moveTo])
                .accessibilityIdentifier(UITestContract.Identifier.Projects.moveTaskMenu)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ToDoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ToDoTheme.separator))
        .cornerRadius(6)
        // The card itself fades where it started, so the preview under the pointer is plainly the
        // same card in flight rather than a copy.
        .opacity(isBeingDragged ? ProjectTaskCard.draggedOpacity : (task.isCompleted ? 0.7 : 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UITestContract.Identifier.Projects.taskCard)
        .contentShape(Rectangle())
        // One click opens the editor. A card has no inline actions to reveal first (unlike a Tasks
        // list row), so a double-click requirement just read as a dead click. The drag takes the
        // press first, but only once the pointer has actually moved, so a click still lands here.
        .onTapGesture { todoStore.openEditor(for: task) }
        .pointingHandCursor()
        // High priority so the press becomes a drag before anything else claims it, but masked down
        // to the subviews' own gestures for someone with no role in the project: they still click a
        // card open, they just cannot carry it anywhere. `ProjectTaskMove.plan` refuses too.
        .highPriorityGesture(cardDrag, including: store.canMoveTask ? .all : .subviews)
        .contextMenu {
            SwiftUI.Button(action: { todoStore.openEditor(for: task) }) { Text(strings[.editTaskTitle]) }
            if store.canMoveTask {
                ForEach(store.columns) { column in
                    SwiftUI.Button(action: { store.move(task, toColumn: column.id) }) { Text("\(strings[.moveTo]): \(column.label)") }
                }
            }
        }
    }

    /// Carrying the card to another column. The board tracks it rather than `onDrag` — see
    /// `ProjectBoardDrag` for why an `NSDraggingSession` never showed up in this window.
    private var cardDrag: some Gesture {
        DragGesture(minimumDistance: ProjectBoardDrag.minimumDistance,
                    coordinateSpace: .named(ProjectTasksView.dragSpace))
            .onChanged { value in
                if !isBeingDragged {
                    drag.begin(task, from: ProjectKanban.columnId(for: task, columns: store.columns,
                                                                  usesCustomStatuses: store.project.usesCustomStatuses))
                }
                pointer.location = value.location
                drag.update(to: value.location)
            }
            .onEnded { value in
                pointer.location = value.location
                drag.update(to: value.location)
                guard let columnId = drag.end() else { return }
                store.move(task, toColumn: columnId)
            }
    }

    private static let draggedOpacity: Double = 0.35
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
                            SwiftUI.Button(action: { store.requestConfirmation(.deleteNote(note)) }) { Image(systemName: "trash").foregroundColor(.secondary) }
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
            ProjectNoteDetailView(note: note, projectId: store.project.id, strings: strings,
                                  webURL: store.webURL(for: note),
                                  onRename: { store.renameNote(note, to: $0) })
        } else {
            Text(strings[.selectNoteTitle]).font(.system(size: 13)).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
        }
    }
}

/// One open project note: its title, renameable in place, an "edit on the web" link, and its body.
///
/// The body is a collaborative (Yjs) document, edited natively by `ProjectNoteEditor`. That editor
/// owns the document session — realtime channel, local recovery drafts, autosave — for exactly as
/// long as this view is in the view tree, and closes it when the view is removed, so whoever shows
/// this view only has to stop showing it. The `.id(identity)` keeps one session per note: switching
/// notes tears the old one down rather than re-pointing it.
///
/// The Projects screen and the Notes screen both render a note through here, so a note is equally
/// editable wherever it was opened and only ever has one writer.
struct ProjectNoteDetailView: View {
    let note: ProjectNote
    let projectId: String
    let strings: ToDoStrings
    let webURL: URL?
    let onRename: (String) -> Void
    /// Whether the title is being renamed right now. A screen with its own Escape handling needs this
    /// so the field, not the screen, owns Escape mid-rename — see `NoteEscapeTarget`.
    var onRenamingChanged: (Bool) -> Void = { _ in }

    private static let titleFontSize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                InlineRenameField(display: note.title.isEmpty ? strings[.untitledNote] : note.title,
                                  value: note.title, placeholder: strings[.untitledNote],
                                  fontSize: ProjectNoteDetailView.titleFontSize, fontWeight: .semibold,
                                  editHint: strings[.renameNoteHint], isEditable: true,
                                  onEditingChanged: onRenamingChanged, onCommit: onRename)
                Spacer()
                SwiftUI.Button(action: { if let url = webURL { NSWorkspace.shared.open(url) } }) {
                    Label(strings[.editOnWeb], systemImage: "arrow.up.right.square")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
                .disabled(webURL == nil)
            }
            let identity = ProjectNoteIdentity(accountID: appdelegate?.user?.userId ?? "",
                                               projectID: projectId, noteID: note.id)
            ProjectNoteEditor(identity: identity).id(identity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ToDoTheme.card)
        .cornerRadius(ToDoTheme.cornerRadius)
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
                // Return only: SwiftUI's `onCommit` also fires on losing focus, and an invitation
                // sent because the user clicked the role picker cannot be taken back (the same
                // defect as the New Project sheet, report 2026-09-15_20-13-26).
                ReturnGuardTextField(text: $email, placeholder: strings[.emailPlaceholder], onCommit: invite)
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
                resendButton(member)
                if actions.canRemove {
                    SwiftUI.Button(action: { store.remove(member) }) { Image(systemName: "trash").foregroundColor(ToDoTheme.overdue) }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor().help(strings[.removeMember])
                }
            }
        }
        .padding(8).background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
    }

    /// "Resend invitation", shown only on a row whose invitation is still outstanding and only to a
    /// viewer allowed to invite. It takes two clicks: the first arms the button (it says so), the second
    /// sends — a resend is an email to someone else, and the members box has already sent one by
    /// accident once (report 2026-09-15_20-13-26). Rows still inside the server's cooldown say why
    /// instead of offering a button.
    @ViewBuilder
    private func resendButton(_ member: ProjectMember) -> some View {
        if ProjectInvitationResend.canResend(viewer: store.viewerRole, status: member.invitationStatus) {
            if store.canResendInvitation(member) {
                let armed = store.isResendArmed(member)
                SwiftUI.Button(action: { armed ? store.resendInvitation(member) : store.armResend(member) }) {
                    Label(armed ? strings[.confirmResendInvitation] : strings[.resendInvitation],
                          systemImage: armed ? "exclamationmark.circle" : "paperplane")
                        .font(.system(size: 11))
                        .foregroundColor(armed ? ToDoTheme.overdue : ToDoTheme.accent)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .help(strings[.resendInvitation])
            } else {
                Text(strings[.invitationJustSent]).font(.system(size: 11)).foregroundColor(.secondary)
            }
        }
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
    /// Every tag in use across the user's projects, for the editor's suggestions.
    let knownTags: [String]
    @SwiftUI.State private var form: ProjectDetailStore.SettingsForm
    @SwiftUI.State private var original: ProjectDetailStore.SettingsForm
    @SwiftUI.State private var newStatusLabel = ""
    @SwiftUI.State private var showDueDatePicker = false
    private var strings: ToDoStrings { store.strings }

    init(store: ProjectDetailStore, knownTags: [String]) {
        self.store = store
        self.knownTags = knownTags
        let form = ProjectDetailStore.SettingsForm(project: store.project)
        _form = SwiftUI.State(initialValue: form)
        _original = SwiftUI.State(initialValue: form)
    }

    private var trimmedName: String { form.name.trimmingCharacters(in: .whitespaces) }

    /// Tags, the same editor the project header shows in a popover.
    ///
    /// Tags apply as they are clicked rather than waiting for Save, because both surfaces go through
    /// the one store path (`addTag` / `removeTag` -> `tagsBody`). Routing them through `SettingsForm`
    /// instead would mean a second place that builds a `metadata` body, and a second such place is
    /// exactly how the assignee save learned to blank `assigned_mcp_token_id`. The note under the
    /// heading says so, so Cancel is not read as undoing them.
    private var tagsSection: some View {
        labelled(strings[.projectTags]) {
            Text(strings[.projectTagsApplyImmediately])
                .font(.system(size: 11)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ProjectTagEditor(strings: strings,
                             applied: store.tags,
                             known: knownTags,
                             onAdd: { store.addTag($0) },
                             onRemove: { store.removeTag($0) })
        }
    }
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
                        // Outcome again, not importance: projects gained a real `outcome` column
                        // (backend#2385, merged), so the rating a project carries is now the same
                        // one — same scale, same words — a task carries. Legacy `importance` (1–4)
                        // stays untouched on the model; it is what the server's portfolio risk
                        // ranks by and is not the user's rating. Reports 2026-09-11_20-00-34 and
                        // 2026-09-15_10-27-17 ("There is no outcome field in settings").
                        ForecastOutcomePicker(wireValue: $form.outcome)
                    }
                    if store.canEditName { tagsSection }
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
                SwiftUI.Button(action: { store.setLifecycle(.completed) }) { Label(strings[.markCompleteProject], systemImage: "checkmark.square") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
            if status != .archived {
                SwiftUI.Button(action: { store.setLifecycle(.archived) }) { Label(strings[.archiveProject], systemImage: "archivebox") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
            if status != .active {
                SwiftUI.Button(action: { store.setLifecycle(.active) }) { Label(strings[.restoreProject], systemImage: "arrow.uturn.backward") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
            }
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings[.dangerZone]).font(.system(size: 12, weight: .semibold)).foregroundColor(ToDoTheme.overdue)
            Text(strings[.deleteWarning]).font(.system(size: 11)).foregroundColor(.secondary)
            SwiftUI.Button(action: { store.requestConfirmation(.delete) }) { Label(strings[.deleteProject], systemImage: "trash") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
                .accessibilityIdentifier(UITestContract.Identifier.Projects.deleteButton)
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
