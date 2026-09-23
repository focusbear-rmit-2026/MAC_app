//
//  NotesView.swift
//  Focus Bear
//
//  Native replacement for the dashboard.focusbear.io/webview/notes webview: brain dump card, search /
//  new-note toolbar, infinite-scrolling note list, and the create/edit sheet. SwiftUI, hosted by
//  brainDumpVc via NSHostingView. Same layout and API behaviour as the web page it replaces.
//

import SwiftUI
import AppKit

/// User-facing strings, config-driven like every other screen (`configjson["notesViewInfo"]`, with
/// the English fallbacks below). Spanish lives in the assets repo config-es.json.
struct NotesStrings {
    var brainDumpTitle = "Brain Dump"
    var brainDumpInfo = "Use Brain Dump to capture ideas fast. Saved notes you've added or edited appear in the list below."
    var brainDumpPlaceholder = "Start typing your thoughts..."
    var showBrainDump = "Show brain dump"
    var hideBrainDump = "Hide brain dump"
    var saving = "Saving…"
    var save = "Save"
    var cancel = "Cancel"
    var close = "Close"
    var searchPlaceholder = "Search notes..."
    var newNote = "New note"
    var createNoteTitle = "Create Note"
    var editNoteTitle = "Edit Note"
    var noteTitlePlaceholder = "Title"
    var noteBodyPlaceholder = "Write your note here..."
    var tagsLabel = "Tags"
    var addTagPlaceholder = "Add a tag..."
    var addTag = "Add"
    var existingTags = "Existing tags"
    var linkedToHabit = "Linked to habit"
    var allTags = "All tags"
    var filterByTag = "Filter by tag"
    var noNotesFound = "No notes found"
    var noNotesMatchSearch = "No notes found matching your search"
    var deleteNoteTitle = "Delete Note"
    var deleteConfirmation = "Are you sure you want to delete this note?"
    var delete = "Delete"
    var noteCreated = "Note created successfully"
    var noteUpdated = "Note updated successfully"
    var noteDeleted = "Note deleted successfully"
    var couldNotCreateNote = "Could not create note"
    var couldNotUpdateNote = "Could not update note"
    var requestFailed = "Could not process the request"
    var bold = "Bold"
    var italic = "Italic"
    var underline = "Underline"
    var bulletList = "Bulleted list"
    var numberedList = "Numbered list"
    var scopeAll = "All notes"
    var scopePersonal = "Personal Notes"
    var scopeProjectNotes = "Shared Notes"
    var scopeArchived = "Archived"
    var newProjectNote = "New shared note"
    var backToNotes = "Back to notes"
    var projectFilterAll = "All projects"
    var projectFilterHelp = "Show shared notes from one project only"
    var noArchivedNotes = "No archived notes"
    var archiveNote = "Archive"
    var archiveNoteHelp = "File this note away — it leaves the list but keeps everything in it"
    var restoreNote = "Restore"
    var restoreNoteHelp = "Put this note back in the list"
    var noteArchived = "Note archived"
    var noteRestored = "Note restored"
    var couldNotArchiveNote = "Could not archive the note"
    var couldNotRestoreNote = "Could not restore the note"

    static func load() -> NotesStrings {
        var strings = NotesStrings()
        guard let info = configjson.value(forKey: "notesViewInfo") as? NSDictionary else {
            strings.loadCloseFallback()
            return strings
        }
        func read(_ key: String, _ target: inout String) {
            if let value = info.value(forKey: key) as? String, !value.isEmpty { target = value }
        }
        read("brainDumpTitle", &strings.brainDumpTitle)
        read("brainDumpInfoText", &strings.brainDumpInfo)
        read("brainDumpPlaceholder", &strings.brainDumpPlaceholder)
        read("showBrainDumpText", &strings.showBrainDump)
        read("hideBrainDumpText", &strings.hideBrainDump)
        read("savingText", &strings.saving)
        read("saveText", &strings.save)
        read("cancelText", &strings.cancel)
        read("searchPlaceholder", &strings.searchPlaceholder)
        read("newNoteText", &strings.newNote)
        read("createNoteTitle", &strings.createNoteTitle)
        read("editNoteTitle", &strings.editNoteTitle)
        read("noteTitlePlaceholder", &strings.noteTitlePlaceholder)
        read("noteBodyPlaceholder", &strings.noteBodyPlaceholder)
        read("tagsLabel", &strings.tagsLabel)
        read("addTagPlaceholder", &strings.addTagPlaceholder)
        read("addTagText", &strings.addTag)
        read("existingTagsText", &strings.existingTags)
        read("linkedToHabitText", &strings.linkedToHabit)
        read("allTagsText", &strings.allTags)
        read("filterByTagText", &strings.filterByTag)
        read("noNotesFoundText", &strings.noNotesFound)
        read("noNotesMatchSearchText", &strings.noNotesMatchSearch)
        read("deleteNoteTitle", &strings.deleteNoteTitle)
        read("deleteConfirmationText", &strings.deleteConfirmation)
        read("deleteText", &strings.delete)
        read("noteCreatedText", &strings.noteCreated)
        read("noteUpdatedText", &strings.noteUpdated)
        read("noteDeletedText", &strings.noteDeleted)
        read("couldNotCreateNoteText", &strings.couldNotCreateNote)
        read("couldNotUpdateNoteText", &strings.couldNotUpdateNote)
        read("requestFailedText", &strings.requestFailed)
        read("boldText", &strings.bold)
        read("italicText", &strings.italic)
        read("underlineText", &strings.underline)
        read("bulletListText", &strings.bulletList)
        read("numberedListText", &strings.numberedList)
        read("scopeAllText", &strings.scopeAll)
        read("scopePersonalText", &strings.scopePersonal)
        read("scopeProjectNotesText", &strings.scopeProjectNotes)
        read("scopeArchivedText", &strings.scopeArchived)
        read("newProjectNoteText", &strings.newProjectNote)
        read("backToNotesText", &strings.backToNotes)
        read("projectFilterAll", &strings.projectFilterAll)
        read("projectFilterHelp", &strings.projectFilterHelp)
        read("noArchivedNotesText", &strings.noArchivedNotes)
        read("archiveNoteText", &strings.archiveNote)
        read("archiveNoteHelpText", &strings.archiveNoteHelp)
        read("restoreNoteText", &strings.restoreNote)
        read("restoreNoteHelpText", &strings.restoreNoteHelp)
        read("noteArchivedText", &strings.noteArchived)
        read("noteRestoredText", &strings.noteRestored)
        read("couldNotArchiveNoteText", &strings.couldNotArchiveNote)
        read("couldNotRestoreNoteText", &strings.couldNotRestoreNote)
        strings.loadCloseFallback()
        return strings
    }

    /// "Close" already exists (and is translated) on the old brain dump screen's config block.
    private mutating func loadCloseFallback() {
        if let info = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary,
           let value = info.value(forKey: "buttonCloseText") as? String, !value.isEmpty {
            close = value
        }
    }
}

// MARK: - Screen

struct NotesScreen: View {
    @ObservedObject var store: NotesStore
    let onClose: () -> Void

    private static let projectFilterWidth: CGFloat = 160
    private static let projectFilterHeight: CGFloat = 24
    /// Four segments now ("All notes / Personal Notes / Shared Notes / Archived").
    private static let scopeWidth: CGFloat = 440
    private static let spinnerScale: CGFloat = 0.5
    private static let spinnerSide: CGFloat = 16
    private static let footerButtonHeight: CGFloat = 30

    private var strings: NotesStrings { store.strings }

    /// The projects that have notes, in the shape the searchable dropdown takes.
    private var projectFilterOptions: [SearchableComboBoxField.Option] {
        store.filterableProjects.map { SearchableComboBoxField.Option(id: $0.id, name: $0.name) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let entry = store.openProjectNote {
                ProjectNoteOpenView(store: store, entry: entry)
            } else {
                noteList
            }
            footer
        }
        .padding(16)
        .background(Color(backgroundColor))
        // An open project note owns a live collaborative document (web view, realtime channel, poll
        // timer). Leaving the screen has to hand it back, or it keeps running behind a screen nobody
        // is looking at. Hosts whose view tree survives a close (brainDumpVc) also call this from
        // viewDidDisappear, where onDisappear never fires.
        .onDisappear { store.screenDisappeared() }
        .sheet(item: $store.editorSession) { session in
            NoteEditorSheet(store: store, note: session.note)
        }
        .alert(item: $store.noteToDelete) { note in
            Alert(
                title: Text(strings.deleteNoteTitle),
                message: Text(strings.deleteConfirmation),
                primaryButton: .destructive(Text(strings.delete)) { store.confirmDelete() },
                secondaryButton: .cancel(Text(strings.cancel)))
        }
    }

    private var noteList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.isBrainDumpVisible {
                BrainDumpCard(store: store)
            }
            toolbar
            scopeBar
            if store.isCreateProjectNoteVisible {
                NewProjectNoteCard(store: store)
            }
            NotesList(store: store)
        }
    }

    /// Personal notes, project notes, or both. Project notes are the reason this exists
    /// (report 2026-09-15_10-39-04) — before it, they were reachable only inside a project.
    private var scopeBar: some View {
        HStack(spacing: 10) {
            Picker(selection: $store.scope, label: EmptyView()) {
                Text(strings.scopeAll).tag(NotesScope.all)
                Text(strings.scopePersonal).tag(NotesScope.personal)
                Text(strings.scopeProjectNotes).tag(NotesScope.project)
                Text(strings.scopeArchived).tag(NotesScope.archived)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .frame(maxWidth: NotesScreen.scopeWidth)

            // Only worth showing once project notes are actually in view and there is more than one
            // project to choose between — otherwise it is a control with a single option. A flat
            // Picker was unusable with many projects, so this one filters its menu as you type.
            if store.scope.includesProjectNotes, store.filterableProjects.count > 1 {
                SearchableComboBoxField(options: projectFilterOptions,
                                        selectedId: $store.projectFilter,
                                        clearedOptionTitle: strings.projectFilterAll)
                    .frame(width: NotesScreen.projectFilterWidth, height: NotesScreen.projectFilterHeight)
                    .help(strings.projectFilterHelp)
            }

            if store.isLoadingProjectNotes || store.isLoadingArchivedProjectNotes {
                ProgressView().scaleEffect(NotesScreen.spinnerScale)
                    .frame(width: NotesScreen.spinnerSide, height: NotesScreen.spinnerSide)
            }

            // minLength 0 lets the gap fully collapse on a narrow window, so the "Show brain dump"
            // button stays on screen instead of being pushed past the right edge.
            Spacer(minLength: 0)

            if !store.isBrainDumpVisible {
                SwiftUI.Button(action: { store.toggleBrainDumpVisible() }) {
                    Text("🧠 " + strings.showBrainDump)
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                .fixedSize()
                .help(strings.showBrainDump)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField(strings.searchPlaceholder, text: $store.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                if store.isSearching {
                    ProgressView().scaleEffect(0.5).frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(Color(NSColor.textBackgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor)))
            .cornerRadius(6)
            .frame(maxWidth: 320)

            if !store.userTags.isEmpty {
                tagFilter
            }

            Spacer()

            SwiftUI.Button(action: { store.openEditor(for: nil) }) {
                Label(strings.newNote, systemImage: "plus")
            }
            .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            .disabled(store.isFetchingNotes && store.visibleNotes.isEmpty)

            // A new note is an active note, so offering it from the archive would only file something
            // into the list the user is not looking at.
            if !store.scope.showsArchivedNotes {
                SwiftUI.Button(action: { store.beginCreateProjectNote() }) {
                    Label(strings.newProjectNote, systemImage: "folder.badge.plus")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                .help(strings.newProjectNote)
                .disabled(store.isCreateProjectNoteVisible)
            }

            // #2598: no in-view close here — the macOS window's title-bar close is the single way out.
        }
    }

    /// Web has no tag filter in the webview, but `GET /note` supports `tag_id`; this exposes it.
    private var tagFilter: some View {
        let selection = Binding<String>(
            get: { store.selectedTagId ?? "" },
            set: { store.selectedTagId = $0.isEmpty ? nil : $0 })
        return Picker(selection: selection, label: Image(systemName: "tag")) {
            Text(strings.allTags).tag("")
            ForEach(store.userTags, id: \.listIdentity) { tag in
                Text(tag.text).tag(tag.id)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(maxWidth: 200)
        .help(strings.filterByTag)
    }

    private var footer: some View {
        HStack {
            if let message = store.statusMessage {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            Spacer()
            footerButton
        }
    }

    /// Close belongs to the list. On an open note it was a duplicate of "Back to notes", so Archive
    /// takes it instead (report 2026-09-15_20-22-23) — the way out of a note is still Back, or Escape
    /// when no rename is in progress, and then the list's ✕ / Close dismisses the screen.
    @ViewBuilder
    private var footerButton: some View {
        switch NotesFooterAction.next(openNote: store.openProjectNote?.note) {
        case .closeScreen:
            // #2598: the macOS title-bar close is enough — no redundant in-view Close button.
            EmptyView()
        case .archiveNote:
            archiveButton(title: strings.archiveNote, help: strings.archiveNoteHelp, archived: true)
        case .restoreNote:
            archiveButton(title: strings.restoreNote, help: strings.restoreNoteHelp, archived: false)
        }
    }

    @ViewBuilder
    private func archiveButton(title: String, help: String, archived: Bool) -> some View {
        SwiftUI.Button(action: { if let entry = store.openProjectNote { store.setArchived(entry, archived: archived) } }) {
            Label(title, systemImage: archived ? "archivebox" : "arrow.uturn.backward")
        }
        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: NotesScreen.footerButtonHeight))
        .disabled(store.isArchivingNote)
        .help(help)
    }

}

// MARK: - Open project note

/// An open project note, shown inside the Notes screen. It is rendered by `ProjectNoteDetailView`,
/// the same view the Projects screen uses, so a note is editable wherever it was opened and there is
/// one implementation rather than two that can drift.
private struct ProjectNoteOpenView: View {
    @ObservedObject var store: NotesStore
    let entry: ProjectNoteEntry

    private static let spinnerScale: CGFloat = 0.5
    private static let spinnerSide: CGFloat = 16

    /// Mid-rename Escape belongs to the title field, not to Back — see `NoteEscapeTarget`.
    @SwiftUI.State private var isRenamingTitle = false

    private var strings: NotesStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                backButton
                ProjectNameChip(name: entry.projectName, label: store.projectStrings[.filterProject])
                // The note's own metadata (title, last edited) is re-fetched on open; the body has
                // its own status line inside the editor.
                if store.isLoadingOpenProjectNote {
                    ProgressView().scaleEffect(ProjectNoteOpenView.spinnerScale)
                        .frame(width: ProjectNoteOpenView.spinnerSide, height: ProjectNoteOpenView.spinnerSide)
                }
                Spacer()
            }
            ProjectNoteDetailView(note: entry.note, projectId: entry.projectId,
                                  strings: store.projectStrings, webURL: store.webURL(for: entry),
                                  onRename: { store.renameProjectNote(entry, to: $0) },
                                  onRenamingChanged: { isRenamingTitle = $0 })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Back saves a half-typed title (`InlineRenameDismissal`), so Escape must not also mean Back
    /// while one is being typed — that would leave no way to abandon a rename. `.cancelAction` is a
    /// window-wide key equivalent and beats the field's own Escape handling, so it is taken off the
    /// button for exactly as long as the rename lasts.
    @ViewBuilder
    private var backButton: some View {
        let button = SwiftUI.Button(action: { store.closeProjectNote() }) {
            Label(strings.backToNotes, systemImage: "chevron.left")
        }
        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
        switch NoteEscapeTarget.next(isRenamingTitle: isRenamingTitle) {
        case .discardTitleEdit: button
        case .backToList: button.keyboardShortcut(.cancelAction)
        }
    }
}

// MARK: - New project note

/// Create a note straight into a project without visiting the project first. The title is asked for
/// up front because creating a note is a `POST { title }` — the body is a separate collaborative
/// document, written afterwards in the editor the new note opens into.
private struct NewProjectNoteCard: View {
    @ObservedObject var store: NotesStore

    private static let projectFieldWidth: CGFloat = 240
    /// Matches the scope bar's filter, so the two project fields line up.
    private static let projectFieldHeight: CGFloat = 24

    /// nil until a project is chosen — the same "nothing picked" the shared combo box reports.
    @SwiftUI.State private var projectId: String?
    @SwiftUI.State private var title = ""

    private var strings: NotesStrings { store.strings }
    private var projectStrings: ToDoStrings { store.projectStrings }
    private var canCreate: Bool { NewProjectNote.canCreate(projectId: projectId) && !store.isCreatingProjectNote }
    private var projectOptions: [SearchableComboBoxField.Option] {
        store.projects.map { SearchableComboBoxField.Option(id: $0.id, name: $0.name) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.newProjectNote).font(.system(size: 13, weight: .semibold))
            if store.projects.isEmpty {
                Text(store.isLoadingProjectNotes ? projectStrings[.loading] : projectStrings[.noExistingProjects])
                    .font(.system(size: 12)).foregroundColor(.secondary)
            } else {
                HStack(spacing: 8) {
                    // The same typeahead the filter above uses. A flat Picker listing every project
                    // is unusable once there are more than a handful, and this account has 128.
                    SearchableComboBoxField(options: projectOptions, selectedId: $projectId,
                                            clearedOptionTitle: projectStrings[.filterProject])
                        .frame(width: NewProjectNoteCard.projectFieldWidth,
                               height: NewProjectNoteCard.projectFieldHeight)
                    TextField(strings.noteTitlePlaceholder, text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            HStack(spacing: 8) {
                Spacer()
                SwiftUI.Button(action: { store.cancelCreateProjectNote() }) { Text(strings.cancel) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                SwiftUI.Button(action: { if let projectId = projectId { store.createProjectNote(projectId: projectId, title: title) } }) {
                    Text(store.isCreatingProjectNote ? strings.saving : projectStrings[.createNote])
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 26))
                .disabled(!canCreate)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        // Deliberately no default project. A Picker had to show something, so it pre-selected the
        // first project and Create would file the note there if the user never touched it; a field
        // you type into starts empty, and Create stays disabled until a project is actually chosen.
    }
}

/// The project a note belongs to, so a row in a merged list says where it lives.
struct ProjectNameChip: View {
    let name: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder")
            Text(name).lineLimit(1)
        }
        .font(.system(size: 11))
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(ToDoTheme.accent.opacity(0.12))
        .cornerRadius(10)
        .help(label + ": " + name)
    }
}

// MARK: - Brain dump

private struct BrainDumpCard: View {
    @ObservedObject var store: NotesStore
    @StateObject private var editorController = NoteEditorController()

    private static let editorHeight: CGFloat = 150
    private var strings: NotesStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(Color(NSColor(named: "dark_OrangeColor") ?? .systemOrange))
                Text(strings.brainDumpInfo)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if store.isSavingBrainDump {
                    Text(strings.saving).font(.system(size: 12)).foregroundColor(.secondary)
                }
                SwiftUI.Button(action: { store.toggleBrainDumpVisible() }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .help(strings.hideBrainDump)
            }
            NoteFormattingToolbar(controller: editorController, strings: strings)
            NoteRichTextEditor(html: $store.brainDumpBody, placeholder: strings.brainDumpPlaceholder, controller: editorController)
                .frame(height: BrainDumpCard.editorHeight)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor)))
                .onChange(of: store.brainDumpBody) { store.brainDumpChanged($0) }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Formatting toolbar

struct NoteFormattingToolbar: View {
    let controller: NoteEditorController
    let strings: NotesStrings

    var body: some View {
        HStack(spacing: 4) {
            toolbarButton(Text("B").bold(), help: strings.bold) { controller.toggleBold() }
            toolbarButton(Text("I").italic(), help: strings.italic) { controller.toggleItalic() }
            toolbarButton(Text("U").underline(), help: strings.underline) { controller.toggleUnderline() }
            Divider().frame(height: 16)
            toolbarButton(Image(systemName: "list.bullet"), help: strings.bulletList) { controller.toggleBulletList() }
            toolbarButton(Image(systemName: "list.number"), help: strings.numberedList) { controller.toggleNumberedList() }
            Spacer()
        }
    }

    private func toolbarButton<Content: View>(_ content: Content, help: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            content
                .font(.system(size: 13, weight: .medium))
                .frame(width: 26, height: 22)
        }
        .buttonStyle(BorderedButtonStyle())
        .pointingHandCursor()
        .help(help)
    }
}

// MARK: - List

private struct NotesList: View {
    @ObservedObject var store: NotesStore

    private static let emptyGlyphSize: CGFloat = 36

    private var strings: NotesStrings { store.strings }

    var body: some View {
        Group {
            if store.listItems.isEmpty {
                if store.isFetchingNotes || store.isSearching || store.isLoadingProjectNotes
                    || store.isLoadingArchivedProjectNotes {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptyState
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.listItems) { item in
                            row(for: item)
                        }
                        if store.isFetchingNotes && store.hasNextPage && !store.isSearchActive {
                            ProgressView().padding()
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func row(for item: NotesListItem) -> some View {
        switch item {
        case .personal(let note):
            NoteRow(note: note, strings: strings,
                    onEdit: { store.openEditor(for: note) },
                    onDelete: { store.requestDelete(note) })
                // Paging is driven by the personal list, which is the only paged source.
                .onAppear { store.rowAppeared(note) }
        case .project(let entry):
            ProjectNoteRow(entry: entry, strings: strings, projectStrings: store.projectStrings,
                           onOpen: { store.open(entry) })
        }
    }

    private var emptyState: some View {
        // An empty archive is the normal state, not a failure — say what is actually missing.
        let isArchive = store.scope.showsArchivedNotes
        let heading = isArchive ? strings.noArchivedNotes : strings.noNotesFound
        let detail = store.isSearchActive ? strings.noNotesMatchSearch : heading
        return VStack(spacing: 8) {
            Image(systemName: isArchive ? "archivebox" : "note.text")
                .font(.system(size: NotesList.emptyGlyphSize)).foregroundColor(.secondary)
            Text(heading).font(.headline)
            Text(detail).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NoteRow: View {
    let note: Note
    let strings: NotesStrings
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var preview: String { NoteHTML.plainText(fromHTML: note.body ?? "") }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let emoji = note.activity_emoji, !emoji.isEmpty { Text(emoji) }
                Text(note.title).font(.system(size: 15, weight: .medium))
                Spacer()
            }
            if let habit = note.activity_name, !habit.isEmpty {
                HStack(spacing: 4) {
                    Text(strings.linkedToHabit + ":").foregroundColor(.secondary)
                    Text(habit).fontWeight(.medium)
                }
                .font(.system(size: 12))
            }
            if !preview.isEmpty {
                Text(preview).font(.system(size: 13)).lineLimit(3).foregroundColor(.primary)
            }
            if let tags = note.tags, !tags.isEmpty {
                NoteTagChips(tags: tags, onRemove: nil, onSelect: nil)
            }
            HStack {
                Text(NoteDateFormatting.display(note.displayDateString))
                    .font(.system(size: 11)).foregroundColor(.secondary)
                Spacer()
                SwiftUI.Button(action: onEdit) { Image(systemName: "pencil") }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                SwiftUI.Button(action: onDelete) { Image(systemName: "trash").foregroundColor(.red) }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(NSColor.separatorColor)))
        .cornerRadius(8)
        .onTapGesture(count: 2, perform: onEdit)
    }
}

/// A note that lives in a project. The list payload carries no body, so the row shows what it has —
/// the title, the project, and when it last changed — and opening it fetches the rest.
private struct ProjectNoteRow: View {
    let entry: ProjectNoteEntry
    let strings: NotesStrings
    let projectStrings: ToDoStrings
    let onOpen: () -> Void

    private var displayTitle: String {
        entry.title.isEmpty ? projectStrings[.untitledNote] : entry.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(displayTitle).font(.system(size: 15, weight: .medium))
                Spacer()
                ProjectNameChip(name: entry.projectName, label: projectStrings[.filterProject])
            }
            HStack {
                Text(projectStrings.format(.lastEdited, ToDoStrings.dateToken,
                                           ToDoDates.abbreviated(entry.sortDateString)))
                    .font(.system(size: 11)).foregroundColor(.secondary)
                Spacer()
                SwiftUI.Button(action: onOpen) { Image(systemName: "chevron.right") }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    .accessibilityLabel(displayTitle)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ToDoTheme.accent.opacity(0.35)))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .pointingHandCursor()
    }
}

// MARK: - Editor sheet

struct NoteEditorSheet: View {
    @ObservedObject var store: NotesStore
    let note: Note?

    @SwiftUI.State private var title: String
    @SwiftUI.State private var bodyHTML: String
    @SwiftUI.State private var selectedTags: [NoteTag]
    @SwiftUI.State private var newTagText = ""
    @StateObject private var editorController = NoteEditorController()

    private static let editorHeight: CGFloat = 220
    private static let maxSuggestedTags = 10
    private var strings: NotesStrings { store.strings }

    init(store: NotesStore, note: Note?) {
        self.store = store
        self.note = note
        _title = SwiftUI.State(initialValue: note?.title ?? "")
        _bodyHTML = SwiftUI.State(initialValue: note?.body ?? "")
        _selectedTags = SwiftUI.State(initialValue: note?.tags ?? [])
    }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !store.isSavingNote }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(note == nil ? strings.createNoteTitle : strings.editNoteTitle).font(.title2).bold()
                Spacer()
                SwiftUI.Button(action: { store.closeEditor() }) { Text(strings.cancel) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                    .keyboardShortcut(.cancelAction)
                SwiftUI.Button(action: save) { Text(store.isSavingNote ? strings.saving : strings.save) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                    .disabled(!canSave)
            }
            TextField(strings.noteTitlePlaceholder, text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 14))
            NoteFormattingToolbar(controller: editorController, strings: strings)
            NoteRichTextEditor(html: $bodyHTML, placeholder: strings.noteBodyPlaceholder, controller: editorController)
                .frame(height: NoteEditorSheet.editorHeight)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor)))
            tagsSection
            if let habit = note?.activity_name, !habit.isEmpty {
                HStack(spacing: 6) {
                    if let emoji = note?.activity_emoji { Text(emoji) }
                    Text(strings.linkedToHabit + ":").foregroundColor(.secondary)
                    Text(habit).fontWeight(.medium)
                }
                .font(.system(size: 12))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(minWidth: 560, idealWidth: 640, minHeight: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings.tagsLabel).font(.system(size: 12, weight: .medium))
            if !selectedTags.isEmpty {
                NoteTagChips(tags: selectedTags, onRemove: removeTag, onSelect: nil)
            }
            HStack(spacing: 8) {
                TextField(strings.addTagPlaceholder, text: $newTagText, onCommit: addTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SwiftUI.Button(action: addTag) { Text(strings.addTag) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                    .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            let suggestions = store.userTags
                .filter { tag in !selectedTags.contains { $0.id == tag.id } }
                .prefix(NoteEditorSheet.maxSuggestedTags)
            if !suggestions.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text(strings.existingTags + ":").font(.system(size: 11)).foregroundColor(.secondary)
                    NoteTagChips(tags: Array(suggestions), onRemove: nil, onSelect: { selectedTags.append($0) })
                }
            }
        }
    }

    /// Web `NotesDrawer.handleAddTag`: reuse an existing tag with the same text, otherwise a new one
    /// with a random colour.
    private func addTag() {
        let text = newTagText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        defer { newTagText = "" }
        if let existing = store.userTags.first(where: { $0.text.lowercased() == text.lowercased() }) {
            if !selectedTags.contains(where: { $0.id == existing.id }) { selectedTags.append(existing) }
            return
        }
        guard !selectedTags.contains(where: { $0.text.lowercased() == text.lowercased() }) else { return }
        selectedTags.append(NoteTag(id: "", text: text, color: NoteTagColors.random()))
    }

    private func removeTag(_ tag: NoteTag) {
        selectedTags.removeAll { $0.text == tag.text }
    }

    private func save() {
        store.saveNote(id: note?.id, title: title, body: bodyHTML, tags: selectedTags,
                       completedActivityId: note?.completed_activity_id) { _ in }
    }
}

// MARK: - Tag chips

private struct NoteTagChips: View {
    let tags: [NoteTag]
    let onRemove: ((NoteTag) -> Void)?
    let onSelect: ((NoteTag) -> Void)?

    var body: some View {
        // A wrapping flow layout isn't available on macOS 11; a horizontal scroller keeps long tag
        // rows usable without clipping.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.listIdentity) { tag in
                    chip(tag)
                }
            }
        }
    }

    private func chip(_ tag: NoteTag) -> some View {
        let background = Color(hex: tag.color) ?? NoteTagColors.fallback
        let hasColor = Color(hex: tag.color) != nil
        return HStack(spacing: 4) {
            Text(tag.text)
            if let onRemove = onRemove {
                SwiftUI.Button(action: { onRemove(tag) }) { Text("×") }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
            }
        }
        .font(.system(size: 11))
        .foregroundColor(hasColor ? .white : .primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(background)
        .cornerRadius(10)
        .onTapGesture { onSelect?(tag) }
        .pointingHandCursor()
    }
}

/// Web `NOTE_TAG_COLORS` (`utils/note.util.ts`) — a new tag gets one of these at random.
enum NoteTagColors {
    static let palette = ["#ef4444", "#f97316", "#eab308", "#22c55e", "#14b8a6", "#8b5cf6", "#ec4899"]
    static let fallback = Color(NSColor.tertiaryLabelColor)

    static func random() -> String { palette.randomElement() ?? palette[0] }
}

extension Color {
    /// "#RRGGBB" → Color; nil for anything else.
    init?(hex: String?) {
        guard var hex = hex?.trimmingCharacters(in: .whitespaces), hex.hasPrefix("#") else { return nil }
        hex.removeFirst()
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}

/// Web `formatAbbrMonthDayYearTime`: "MMM D, YYYY hh:mm A".
enum NoteDateFormatting {
    private static let isoWithFractions: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let iso = ISO8601DateFormatter()
    private static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.dateFormat = "MMM d, yyyy hh:mm a"
        return formatter
    }()

    static func display(_ isoString: String) -> String {
        guard let date = isoWithFractions.date(from: isoString) ?? iso.date(from: isoString) else { return "" }
        return display.string(from: date)
    }
}
