//
//  NotesStore.swift
//  Focus Bear
//
//  State for the native Notes view. Behaves like the web dashboard's notes slice + webview page
//  (`store/reducer/note`, `pages/webview/notes`): first page + tags on open, 500 ms debounced search,
//  infinite-scroll paging, and a brain dump that auto-saves 2 s after the last keystroke.
//
//  It also lists the user's *project* notes (report 2026-09-15_10-39-04), fetched through the existing
//  `/projects/:id/notes` calls in ToDoApi and merged into one timeline by `NotesFeed`.
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
    /// Which of "All notes / My notes / Project notes" the user last looked at.
    private static let scopeKey = "kUserdefaultsNotesScope"

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

    // Project notes
    /// Which project's notes to show, or nil for all of them. Deliberately NOT persisted: a scope is
    /// a lasting preference, but narrowing to one project is a momentary act, and coming back to a
    /// silently filtered list later reads as missing notes.
    @Published var projectFilter: String?

    @Published var scope: NotesScope {
        didSet {
            // The archive is a place you visit, not a place you live — see `isWorthPersisting`.
            if scope.isWorthPersisting { UserDefaults.standard.set(scope.rawValue, forKey: NotesStore.scopeKey) }
            if scope.showsArchivedNotes { loadArchivedProjectNotes() }
        }
    }
    @Published private(set) var projects: [Project] = []
    @Published private(set) var projectNotes: [ProjectNoteEntry] = []
    @Published private(set) var isLoadingProjectNotes = false
    /// Archived notes are a separate `?archived=true` fetch, made only when the archive is opened —
    /// one request per project is too much to spend on a view most sessions never visit.
    @Published private(set) var archivedProjectNotes: [ProjectNoteEntry] = []
    @Published private(set) var isLoadingArchivedProjectNotes = false
    @Published private(set) var isArchivingNote = false
    private var hasLoadedArchivedProjectNotes = false
    private var archivedNotesGeneration = 0
    /// The project note being read, nil on the list.
    @Published private(set) var openProjectNote: ProjectNoteEntry? = nil
    @Published private(set) var isLoadingOpenProjectNote = false
    @Published var isCreateProjectNoteVisible = false
    @Published private(set) var isCreatingProjectNote = false
    /// One sweep per session: the project catalogue plus a page of notes per project is a lot of
    /// requests to repeat every time the screen is opened.
    private var hasLoadedProjectNotes = false
    private var projectNotesGeneration = 0
    /// Sweeps in progress. A `ProjectNotesSweepRunner` drives itself through its own callbacks, so
    /// something has to keep it alive until it reports back.
    private var activeSweeps: [ProjectNotesSweepRunner] = []

    let strings: NotesStrings
    /// Project-note copy ("Create note", "Untitled note", "Edit on the web", …) already exists and is
    /// translated on the Projects screen; reuse it rather than shipping a second set of the same words.
    let projectStrings: ToDoStrings

    init(strings: NotesStrings, projectStrings: ToDoStrings = ToDoStrings.load()) {
        self.strings = strings
        self.projectStrings = projectStrings
        let defaults = UserDefaults.standard
        isBrainDumpVisible = defaults.object(forKey: NotesStore.brainDumpVisibleKey) as? Bool ?? true
        let savedScope = NotesScope(rawValue: defaults.string(forKey: NotesStore.scopeKey) ?? "") ?? .all
        scope = savedScope.isWorthPersisting ? savedScope : .all
    }

    /// Notes shown in the list: search results while searching, else the paged list — never the brain dump.
    var visibleNotes: [Note] {
        let source = isSearchActive ? (searchResults ?? []) : notes
        return source.filter { !$0.isBrainDump && carriesSelectedTag($0) }
    }

    /// The project notes the current scope draws on: the active ones, or the archive.
    var scopedProjectNotes: [ProjectNoteEntry] {
        NotesFeed.projectNotes(active: projectNotes, archived: archivedProjectNotes, scope: scope)
    }

    /// Everything the list renders: personal notes and project notes on one newest-first timeline.
    var listItems: [NotesListItem] {
        NotesFeed.items(personal: visibleNotes, projectNotes: scopedProjectNotes, scope: scope,
                        searchQuery: searchQuery, isTagFilterActive: selectedTagId != nil,
                        projectFilter: projectFilter)
    }

    /// Projects offered by the filter control — only those that actually have a note in view, so the
    /// archive offers the projects with archived notes rather than the projects with active ones.
    var filterableProjects: [(id: String, name: String)] {
        NotesFeed.filterableProjects(scopedProjectNotes)
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
        loadProjectNotes()
        if scope.showsArchivedNotes { loadArchivedProjectNotes() }
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

    /// The screen is going away. Pending brain-dump text is saved, and an open project note is closed
    /// so the collaborative document behind it (web view, realtime channel, poll timer) is torn down
    /// instead of left running out of sight — the editor's own teardown runs when the view is removed.
    func screenDisappeared() {
        flushPendingSaves()
        closeProjectNote()
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
                self.searchResults = nil
                self.loadFirstPage()
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

    /// A brain-dump value equal to what the server already has (e.g. the body just loaded from the
    /// API, or a cursor move that emitted the same HTML) is not an edit and must not start the
    /// debounce — otherwise every screen showing the brain dump would re-save on appear.
    static func shouldScheduleBrainDumpSave(body: String, lastSavedBody: String) -> Bool {
        body != lastSavedBody
    }

    /// Whether a debounced brain-dump body is actually worth sending to `PUT /note`. Unchanged content
    /// is a no-op. Empty content may overwrite an existing brain dump — clearing it should stick across
    /// a restart — but must never *create* a brand-new empty one.
    static func shouldCommitBrainDump(body: String, lastSavedBody: String, hasExistingNote: Bool) -> Bool {
        guard body != lastSavedBody else { return false }
        return hasExistingNote || !NoteHTML.plainText(fromHTML: body).isEmpty
    }

    /// Called on every change of the brain dump editor's value; saves 2 s after the last keystroke.
    func brainDumpChanged(_ html: String) {
        pendingBrainDumpSave?.cancel()
        guard NotesStore.shouldScheduleBrainDumpSave(body: html, lastSavedBody: lastSavedBrainDumpBody) else {
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

    /// Web `BrainDumpNote.saveBrainDump`: skip empty or unchanged content; upsert by id when known.
    private func saveBrainDump(_ html: String) {
        guard NotesStore.shouldCommitBrainDump(body: html, lastSavedBody: lastSavedBrainDumpBody,
                                               hasExistingNote: adoptedBrainDump != nil) else { return }
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

    // MARK: - Project notes

    /// Every active project's notes, so the list can show them without visiting each project first.
    /// `GET /projects/:id/notes` is per-project, so this is one catalogue call plus one call per
    /// project — hence the once-per-session gate.
    func loadProjectNotes(force: Bool = false) {
        guard !isLoadingProjectNotes else { return }
        guard force || !hasLoadedProjectNotes else { return }
        isLoadingProjectNotes = true
        projectNotesGeneration += 1
        let generation = projectNotesGeneration
        allApiObject.getAllActiveProjects { [weak self] projects in
            guard let self = self else { return }
            guard let projects = projects else {
                DispatchQueue.main.async {
                    guard self.projectNotesGeneration == generation else { return }
                    self.isLoadingProjectNotes = false
                    self.showStatus(self.strings.requestFailed)
                }
                return
            }
            self.fetchNotes(for: projects, generation: generation)
        }
    }

    private func fetchNotes(for projects: [Project], generation: Int) {
        fetchNotes(for: projects, archived: false) { [weak self] result in
            guard let self = self, self.projectNotesGeneration == generation else { return }
            self.isLoadingProjectNotes = false
            // A sweep that lost projects has not really loaded: caching it would leave those notes
            // missing for the rest of the session, which is exactly the failure being fixed here.
            // Leaving the gate open means simply reopening the screen tries them again.
            self.hasLoadedProjectNotes = result.isComplete
            self.projects = projects
            self.projectNotes = result.entries
            self.reportIncompleteSweep(result)
            // The archive can be opened before the project catalogue lands; pick it up once it has.
            if self.scope.showsArchivedNotes { self.loadArchivedProjectNotes() }
        }
    }

    /// Say so when some projects could not be reached. The list is about to be missing their notes,
    /// and a quietly short list is indistinguishable from having no notes — the whole point of the
    /// bug this replaces.
    private func reportIncompleteSweep(_ result: ProjectNotesSweepResult) {
        guard !result.isComplete else { return }
        addLog(text: "project notes sweep incomplete:- \(result.failedProjectIds.count) project(s) unanswered")
        showStatus(strings.requestFailed)
    }

    /// The archive, fetched on demand the first time it is opened. It reuses whatever project
    /// catalogue the active sweep already has; before that has landed there is nothing to ask about.
    func loadArchivedProjectNotes(force: Bool = false) {
        guard !isLoadingArchivedProjectNotes, !projects.isEmpty else { return }
        guard force || !hasLoadedArchivedProjectNotes else { return }
        isLoadingArchivedProjectNotes = true
        archivedNotesGeneration += 1
        let generation = archivedNotesGeneration
        let projects = self.projects
        fetchNotes(for: projects, archived: true) { [weak self] result in
            guard let self = self, self.archivedNotesGeneration == generation else { return }
            self.isLoadingArchivedProjectNotes = false
            self.hasLoadedArchivedProjectNotes = result.isComplete
            self.archivedProjectNotes = result.entries
            self.reportIncompleteSweep(result)
        }
    }

    /// One `GET /projects/:id/notes` per project, a few at a time and retried when the API pushes
    /// back — `ProjectNotesSweep` explains why firing them all at once lost notes. The runner is held
    /// for the duration of the sweep; nothing else owns it.
    private func fetchNotes(for projects: [Project], archived: Bool,
                            completion: @escaping (ProjectNotesSweepResult) -> Void) {
        let runner = ProjectNotesSweepRunner(fetch: { projectId, done in
            allApiObject.getProjectNotes(projectId: projectId, archived: archived, completionHandler: done)
        })
        activeSweeps.append(runner)
        runner.run(projects: projects) { [weak self] result in
            DispatchQueue.main.async {
                self?.activeSweeps.removeAll { $0 === runner }
                completion(result)
            }
        }
    }

    /// Open a project note for editing. The body is loaded by `ProjectNoteEditor` from the
    /// collaborative document endpoint; this fetch is for the note's own fields (title, timestamps),
    /// which the list rows carry only partly.
    func open(_ entry: ProjectNoteEntry) {
        openProjectNote = entry
        isLoadingOpenProjectNote = true
        allApiObject.getProjectNote(projectId: entry.projectId, noteId: entry.note.id) { [weak self] full in
            DispatchQueue.main.async {
                guard let self = self, self.openProjectNote?.id == entry.id else { return }
                self.isLoadingOpenProjectNote = false
                guard let full = full else { return }
                self.openProjectNote?.note = full
                self.projectNotes = ProjectNoteEntry.applying(full, to: self.projectNotes)
            }
        }
    }

    /// Step back from an open project note to the notes list — never straight out of the screen
    /// (report 2026-09-14_19-4x). Dropping the note also removes the editor from the view tree, which
    /// is what closes its document session.
    func closeProjectNote() {
        openProjectNote = nil
    }

    /// Rename an open project note. Only the title: the body is a Yjs document written through the
    /// separate document endpoint by `ProjectNoteEditor`, so this screen and that editor never write
    /// the same field. An empty or unchanged title is a no-op, like the Projects screen's rename.
    func renameProjectNote(_ entry: ProjectNoteEntry, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != entry.note.title else { return }
        allApiObject.renameProjectNote(projectId: entry.projectId, noteId: entry.note.id, title: trimmed) { [weak self] saved in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let saved = saved else {
                    self.showStatus(self.projectStrings[.couldNotRenameNote])
                    return
                }
                // Patch the title in place: the rename response carries no body, and the list rows
                // never had one.
                if let index = self.projectNotes.firstIndex(where: { $0.id == saved.id }) {
                    self.projectNotes[index].note.title = saved.title
                }
                if self.openProjectNote?.id == saved.id { self.openProjectNote?.note.title = saved.title }
                self.showStatus(self.projectStrings[.noteRenamed])
            }
        }
    }

    func beginCreateProjectNote() {
        loadProjectNotes()
        isCreateProjectNoteVisible = true
    }

    func cancelCreateProjectNote() {
        isCreateProjectNoteVisible = false
    }

    /// `POST /projects/:id/notes { title }`, then open the new note. The note is attached to the
    /// project the user picked, which is also what its "edit on the web" link points at.
    func createProjectNote(projectId: String, title: String) {
        guard NewProjectNote.canCreate(projectId: projectId),
              let project = projects.first(where: { $0.id == projectId }) else { return }
        isCreatingProjectNote = true
        let resolvedTitle = NewProjectNote.resolvedTitle(typed: title, fallback: projectStrings[.untitledNote])
        allApiObject.createProjectNote(projectId: projectId, title: resolvedTitle) { [weak self] note in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCreatingProjectNote = false
                guard let note = note else {
                    self.showStatus(self.projectStrings[.couldNotCreateNote])
                    return
                }
                let entry = ProjectNoteEntry.created(note: note, in: project)
                self.projectNotes.insert(entry, at: 0)
                self.isCreateProjectNoteVisible = false
                self.openProjectNote = entry
                self.showStatus(self.strings.noteCreated)
            }
        }
    }

    /// Archive the open note, or restore it. Archiving files a note away — it leaves the default list
    /// but keeps its content, its history and its collaborative document, and it can be brought back
    /// from the archive view. Nothing is decided locally: the note moves between the two lists only
    /// once the server has confirmed, so the Mac never shows a state the web and mobile disagree with.
    func setArchived(_ entry: ProjectNoteEntry, archived: Bool) {
        guard !isArchivingNote else { return }
        isArchivingNote = true
        allApiObject.setProjectNoteArchived(projectId: entry.projectId, noteId: entry.note.id, archived: archived) { [weak self] saved in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isArchivingNote = false
                guard let saved = saved else {
                    self.showStatus(archived ? self.strings.couldNotArchiveNote : self.strings.couldNotRestoreNote)
                    return
                }
                self.moveBetweenLists(entry, saved: saved, archived: archived)
                switch ArchivedNoteDisposition.next(archived: archived) {
                case .stepBackToList: self.closeProjectNote()
                case .stayOpen: if self.openProjectNote?.id == saved.id { self.openProjectNote?.note = saved }
                }
                self.showStatus(archived ? self.strings.noteArchived : self.strings.noteRestored)
            }
        }
    }

    private func moveBetweenLists(_ entry: ProjectNoteEntry, saved: ProjectNote, archived: Bool) {
        let lists = NotesFeed.moved(entry, saved: saved, archived: archived,
                                    active: projectNotes, archive: archivedProjectNotes)
        projectNotes = lists.active
        archivedProjectNotes = lists.archive
    }

    func webURL(for entry: ProjectNoteEntry) -> URL? {
        ProjectNoteLinks.webURL(projectId: entry.projectId, noteId: entry.note.id)
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
