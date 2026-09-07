//
//  NotesStore.swift
//  Focus Bear
//
//  State for the native Notes view. Behaves like the web dashboard's notes slice + webview page
//  (`store/reducer/note`, `pages/webview/notes`): first page + tags on open, 500 ms debounced search,
//  infinite-scroll paging, and a brain dump that auto-saves 2 s after the last keystroke.
//

import Foundation
import AppKit

/// Which note the editor sheet is for; nil note = create.
struct NoteEditorSession: Identifiable {
    let id = UUID()
    let note: Note?
}

final class NotesStore: ObservableObject {

    /// Web: `DEBOUNCE_DELAY.NOTE_SEARCH` / `TIMEOUT_DELAY.BRAIN_DUMP_SAVE`.
    static let searchDebounceSeconds: TimeInterval = 0.5
    static let brainDumpSaveDelaySeconds: TimeInterval = 2.0
    static let statusMessageSeconds: TimeInterval = 3.0
    /// Web: `LOCAL_STORAGE.WEBVIEW_BRAIN_DUMP_OPEN` — the Mac always opened on the brain dump
    /// (`?open=braindump`), so default to shown.
    private static let brainDumpVisibleKey = "kUserdefaultsNotesBrainDumpVisible"

    // List
    @Published private(set) var notes: [Note] = []
    @Published private(set) var isFetchingNotes = false
    @Published private(set) var hasNextPage = false
    private var currentPage = NotesPaging.firstPage

    // Search
    @Published var searchQuery = "" { didSet { scheduleSearch() } }
    @Published private(set) var searchResults: [Note]? = nil
    @Published private(set) var isSearching = false
    private var pendingSearch: DispatchWorkItem?

    // Tags
    @Published private(set) var userTags: [NoteTag] = []
    /// Web `GetNotesParams.tag_id`: nil = all notes. Search results (no server-side tag filter) are
    /// filtered client-side by the same tag.
    @Published var selectedTagId: String? = nil {
        didSet {
            guard selectedTagId != oldValue else { return }
            loadFirstPage()
        }
    }

    // Brain dump
    @Published var isBrainDumpVisible: Bool {
        didSet { UserDefaults.standard.set(isBrainDumpVisible, forKey: NotesStore.brainDumpVisibleKey) }
    }
    @Published var brainDumpBody = ""
    @Published private(set) var isSavingBrainDump = false
    /// The brain-dump note the editor is bound to (nil until one is found or the first save creates it).
    private var adoptedBrainDump: Note?
    /// Every brain-dump note seen in any response this session, by id — see adoptBrainDump.
    private var seenBrainDumps: [String: Note] = [:]
    private var lastSavedBrainDumpBody = ""
    private var pendingBrainDumpSave: DispatchWorkItem?
    private var hasScannedForBrainDump = false

    // Editor / delete / feedback
    @Published var editorSession: NoteEditorSession? = nil
    @Published private(set) var isSavingNote = false
    @Published var noteToDelete: Note? = nil
    @Published private(set) var isDeletingNote = false
    @Published private(set) var statusMessage: String? = nil
    private var pendingStatusClear: DispatchWorkItem?

    let strings: NotesStrings

    init(strings: NotesStrings) {
        self.strings = strings
        let defaults = UserDefaults.standard
        isBrainDumpVisible = defaults.object(forKey: NotesStore.brainDumpVisibleKey) as? Bool ?? true
    }

    /// Notes shown in the list: search results while searching, else the paged list — never the brain dump.
    var visibleNotes: [Note] {
        let source = isSearchActive ? (searchResults ?? []) : notes
        return source.filter { !$0.isBrainDump && carriesSelectedTag($0) }
    }

    private func carriesSelectedTag(_ note: Note) -> Bool {
        guard let tagId = selectedTagId else { return true }
        return note.tags?.contains { $0.id == tagId } ?? false
    }

    var isSearchActive: Bool { !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    // MARK: - Lifecycle

    /// Web `WebviewNotes` mount: fetch tags and the first page (which also carries the brain dump).
    func screenAppeared() {
        loadTags()
        scanForBrainDumpOnce()
        if isSearchActive {
            runSearch()
        } else {
            loadFirstPage()
        }
    }

    /// Save anything the debounce is still holding (the view is going away).
    func flushPendingSaves() {
        guard let pending = pendingBrainDumpSave else { return }
        pending.cancel()
        pendingBrainDumpSave = nil
        saveBrainDump(brainDumpBody)
    }

    // MARK: - List

    func loadFirstPage() {
        fetchPage(NotesPaging.firstPage, append: false)
    }

    func loadNextPage() {
        guard !isFetchingNotes, hasNextPage, !isSearchActive else { return }
        fetchPage(currentPage + 1, append: true)
    }

    /// Infinite scroll trigger from the list's last visible row.
    func rowAppeared(_ note: Note) {
        guard note.id == visibleNotes.last?.id else { return }
        loadNextPage()
    }

    private func fetchPage(_ page: Int, append: Bool) {
        isFetchingNotes = true
        let tagId = selectedTagId
        allApiObject.getNotes(page: page, take: NotesPaging.pageSize, tagId: tagId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetchingNotes = false
                // A stale page for a filter the user has since changed must not replace the list.
                guard tagId == self.selectedTagId else { return }
                guard let result = result else {
                    self.showStatus(self.strings.requestFailed)
                    return
                }
                if append {
                    let known = Set(self.notes.map { $0.id })
                    self.notes.append(contentsOf: result.data.filter { !known.contains($0.id) })
                } else {
                    self.notes = result.data
                }
                self.hasNextPage = result.meta?.hasNextPage ?? false
                self.currentPage = page
                self.adoptBrainDump(from: result.data)
            }
        }
    }

    /// Web `createOrUpdateNote` / `deleteNote` re-fetch the list (and re-run an active search) after a
    /// successful write so the list reflects the server.
    private func refreshAfterWrite() {
        loadFirstPage()
        if isSearchActive { runSearch() }
    }

    // MARK: - Search

    private func scheduleSearch() {
        pendingSearch?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isSearchActive {
                self.runSearch()
            } else {
                // Clearing the search just reveals the paged list again — it was never touched while
                // searching (only searchResults was). Refetching here would reset `notes` to page 1
                // and drop everything infinite-scroll had loaded, so only fetch if we have nothing.
                self.searchResults = nil
                if self.notes.isEmpty { self.loadFirstPage() }
            }
        }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + NotesStore.searchDebounceSeconds, execute: work)
    }

    private func runSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        allApiObject.searchNotes(query: query, take: NotesPaging.searchTake) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSearching = false
                // Ignore a stale response if the query moved on meanwhile.
                guard query == self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                self.searchResults = result ?? []
            }
        }
    }

    // MARK: - Tags

    private func loadTags() {
        allApiObject.getNoteTags { [weak self] tags in
            DispatchQueue.main.async { self?.userTags = tags ?? [] }
        }
    }

    // MARK: - Brain dump

    func toggleBrainDumpVisible() {
        isBrainDumpVisible.toggle()
    }

    /// Called on every change of the brain dump editor's value; saves 2 s after the last keystroke. A
    /// value equal to what the server has (e.g. the body just loaded from the API) is not an edit.
    func brainDumpChanged(_ html: String) {
        pendingBrainDumpSave?.cancel()
        guard html != lastSavedBrainDumpBody else {
            pendingBrainDumpSave = nil
            return
        }
        let work = DispatchWorkItem { [weak self] in
            self?.pendingBrainDumpSave = nil
            self?.saveBrainDump(html)
        }
        pendingBrainDumpSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + NotesStore.brainDumpSaveDelaySeconds, execute: work)
    }

    /// Upsert the brain dump by id when known; skip when unchanged. Empty content is allowed to persist
    /// only when a brain dump already exists (so the user can clear it and have that stick after a
    /// restart) — we still never *create* a brand-new brain dump from empty content.
    private func saveBrainDump(_ html: String) {
        guard html != lastSavedBrainDumpBody else { return }
        guard adoptedBrainDump != nil || !NoteHTML.plainText(fromHTML: html).isEmpty else { return }
        isSavingBrainDump = true
        let payload = NoteUpsertPayload(id: adoptedBrainDump?.id, title: strings.brainDumpTitle, body: html, tags: nil,
                                        completed_activity_id: nil, is_brain_dump: true)
        allApiObject.upsertNote(payload) { [weak self] saved, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSavingBrainDump = false
                guard let saved = saved else {
                    self.showStatus(self.strings.requestFailed)
                    return
                }
                self.adoptedBrainDump = saved
                self.seenBrainDumps[saved.id] = saved
                self.lastSavedBrainDumpBody = html
            }
        }
    }

    /// Web `BrainDumpNote`: the brain dump is whichever listed note has `is_brain_dump`. The list is
    /// ordered by created_at, so an old brain dump can fall off page 1 — the web then creates a
    /// duplicate, and accounts hit by that carry several brain-dump notes. Track every one seen this
    /// session and bind the editor to the most recently updated (ISO-8601 timestamps compare as strings).
    private func adoptBrainDump(from listed: [Note]) {
        for note in listed where note.isBrainDump { seenBrainDumps[note.id] = note }
        guard let latest = seenBrainDumps.values.max(by: { $0.updated_at < $1.updated_at }) else { return }
        if let current = adoptedBrainDump, current.id == latest.id, current.updated_at == latest.updated_at { return }
        applyBrainDump(latest)
    }

    /// One larger page (`take=50`), once per session, so the live brain dump is found even when it has
    /// fallen off page 1 — instead of letting the first save create yet another one.
    private func scanForBrainDumpOnce() {
        guard !hasScannedForBrainDump else { return }
        hasScannedForBrainDump = true
        allApiObject.getNotes(page: NotesPaging.firstPage, take: NotesPaging.brainDumpScanTake) { [weak self] result in
            DispatchQueue.main.async { self?.adoptBrainDump(from: result?.data ?? []) }
        }
    }

    private func applyBrainDump(_ note: Note) {
        let body = note.body ?? ""
        // Don't clobber text the user is still typing (unsaved local edits win, like the web's ref check).
        let hasUnsavedEdits = pendingBrainDumpSave != nil || brainDumpBody != lastSavedBrainDumpBody
        adoptedBrainDump = note
        lastSavedBrainDumpBody = body
        if !hasUnsavedEdits {
            brainDumpBody = body
        }
    }

    // MARK: - Create / edit

    func openEditor(for note: Note?) {
        editorSession = NoteEditorSession(note: note)
    }

    func closeEditor() {
        editorSession = nil
    }

    /// Web `NotesDrawer.handleSave` → `createOrUpdateNote`: PUT the note, then refresh the list and
    /// close the editor on success.
    func saveNote(id: String?, title: String, body: String, tags: [NoteTag], completedActivityId: String?,
                  completion: @escaping (_ success: Bool) -> Void) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { completion(false); return }
        isSavingNote = true
        let isUpdate = id != nil
        let payload = NoteUpsertPayload(
            id: id,
            title: trimmedTitle,
            body: body,
            tags: tags.map { NoteTagPayload(id: $0.id.isEmpty ? nil : $0.id, text: $0.text, color: $0.color) },
            completed_activity_id: completedActivityId,
            is_brain_dump: nil)
        allApiObject.upsertNote(payload) { [weak self] saved, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSavingNote = false
                guard saved != nil else {
                    self.showStatus(isUpdate ? self.strings.couldNotUpdateNote : self.strings.couldNotCreateNote)
                    completion(false)
                    return
                }
                self.refreshAfterWrite()
                self.loadTags()
                self.closeEditor()
                self.showStatus(isUpdate ? self.strings.noteUpdated : self.strings.noteCreated)
                completion(true)
            }
        }
    }

    // MARK: - Delete

    func requestDelete(_ note: Note) {
        noteToDelete = note
    }

    func confirmDelete() {
        guard let note = noteToDelete else { return }
        noteToDelete = nil
        isDeletingNote = true
        allApiObject.deleteNote(id: note.id) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isDeletingNote = false
                guard success else {
                    self.showStatus(self.strings.requestFailed)
                    return
                }
                self.notes.removeAll { $0.id == note.id }
                self.searchResults?.removeAll { $0.id == note.id }
                self.refreshAfterWrite()
                self.showStatus(self.strings.noteDeleted)
            }
        }
    }

    // MARK: - Status toast

    private func showStatus(_ message: String) {
        statusMessage = message
        pendingStatusClear?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.statusMessage = nil }
        pendingStatusClear = work
        DispatchQueue.main.asyncAfter(deadline: .now() + NotesStore.statusMessageSeconds, execute: work)
    }
}
