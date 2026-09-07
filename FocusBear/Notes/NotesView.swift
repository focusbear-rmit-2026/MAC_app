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

    private var strings: NotesStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.isBrainDumpVisible {
                BrainDumpCard(store: store)
            }
            toolbar
            NotesList(store: store)
            footer
        }
        .padding(16)
        .background(Color(backgroundColor))
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

            if !store.isBrainDumpVisible {
                SwiftUI.Button(action: { store.toggleBrainDumpVisible() }) {
                    Text("🧠 " + strings.showBrainDump)
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                .help(strings.showBrainDump)
            }
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
            SwiftUI.Button(action: onClose) { Text(strings.close) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
        }
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
    private var strings: NotesStrings { store.strings }

    var body: some View {
        Group {
            if store.visibleNotes.isEmpty {
                if store.isFetchingNotes || store.isSearching {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptyState
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.visibleNotes) { note in
                            NoteRow(note: note, strings: strings,
                                    onEdit: { store.openEditor(for: note) },
                                    onDelete: { store.requestDelete(note) })
                                .onAppear { store.rowAppeared(note) }
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "note.text").font(.system(size: 36)).foregroundColor(.secondary)
            Text(strings.noNotesFound).font(.headline)
            Text(store.isSearchActive ? strings.noNotesMatchSearch : strings.noNotesFound)
                .font(.subheadline).foregroundColor(.secondary)
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
