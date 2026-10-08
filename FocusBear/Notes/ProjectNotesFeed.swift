//
//  ProjectNotesFeed.swift
//  Focus Bear
//
//  Lets the Notes screen list a user's *project* notes next to their personal ones (report
//  2026-09-15_10-39-04: "Notes section should include project notes"). Project notes live on
//  `/projects/:id/notes` and are already modelled by `ProjectNote` / `AllApi.getProjectNotes`; nothing
//  here re-implements them. This file only holds the pure logic the screen needs — which notes are
//  listed, in what order, and what the footer "Close" button should close — so it can be tested
//  without a network or an AppKit window.
//

import Foundation

/// One project note together with the project it belongs to. The note itself is the shared
/// `ProjectNote` model; a list row needs the project's name and id too, and neither is on the
/// `GET /projects/:id/notes` payload in a form the screen can rely on.
struct ProjectNoteEntry: Identifiable, Equatable {
    let projectId: String
    let projectName: String
    var note: ProjectNote

    var id: String { note.id }
    var title: String { note.title }
    /// Project notes are ordered by when they last changed, falling back to when they were created.
    var sortDateString: String? { note.updated_at ?? note.created_at }

    /// Flatten a fetch (`projectId -> its notes`) into entries. Projects with no notes drop out.
    static func entries(from notesByProjectId: [String: [ProjectNote]], projects: [Project]) -> [ProjectNoteEntry] {
        projects.flatMap { project in
            (notesByProjectId[project.id] ?? []).map {
                ProjectNoteEntry(projectId: project.id, projectName: project.name, note: $0)
            }
        }
    }

    /// The entry for a note just created in `project`. The chosen project is authoritative: it is what
    /// the row is grouped under and what the "edit on the web" deep link points at, whether or not the
    /// server echoed `project_id` back.
    static func created(note: ProjectNote, in project: Project) -> ProjectNoteEntry {
        ProjectNoteEntry(projectId: project.id, projectName: project.name, note: note)
    }

    /// Fold a fully fetched note (the list rows carry no body) back into the listed entries. Only the
    /// note with that id changes, and it keeps the project it was listed under.
    static func applying(_ full: ProjectNote, to entries: [ProjectNoteEntry]) -> [ProjectNoteEntry] {
        entries.map { entry in
            guard entry.id == full.id else { return entry }
            var updated = entry
            updated.note = full
            return updated
        }
    }
}

/// What one `GET /projects/:id/notes` came back with. A project the server refused to answer is not
/// a project with no notes, and the two must never collapse into the same value — that conflation is
/// what hid a note (see `ProjectNotesSweep`).
enum ProjectNotesOutcome: Equatable {
    case notes([ProjectNote])
    case failed
}

/// What a whole sweep came back with: the notes it gathered, and the projects it never got an answer
/// for. A sweep that lost projects is not a finished sweep, however complete its list looks.
struct ProjectNotesSweepResult: Equatable {
    var entries: [ProjectNoteEntry]
    var failedProjectIds: Set<String>

    var isComplete: Bool { failedProjectIds.isEmpty }
}

/// Fetching every project's notes without tripping the API's rate limiter.
///
/// The Notes screen needs one `GET /projects/:id/notes` per active project, and the first version
/// issued them all at once. With 128 active projects that is 128 simultaneous requests against an
/// endpoint that allows **10 per second** (`x-ratelimit-limit: 10`), so the server rejected most of
/// them with HTTP 429 — measured on the reporter's own account: 66 of 128 refused, the UX project
/// among them. `decodeToDo` turns a non-2xx into nil and the caller wrote `notes ?? []`, so every
/// rejected project was recorded as *a project with no notes*: its notes vanished from the list and
/// the project vanished from the filter dropdown, with no error anywhere. Which projects were lost
/// changed from run to run, which is why the same note was visible earlier in the day and gone later
/// (report 2026-09-15_10-39-04).
///
/// So: only a few requests in flight at a time, a rejected request is retried rather than believed,
/// and a project that still cannot be reached is reported as failed instead of as empty.
enum ProjectNotesSweep {
    /// The endpoint allows 10 requests a second. Four in flight keeps a sweep comfortably inside that
    /// while the rest of the app is also talking to the API, and still finishes 128 projects in a few
    /// seconds. Measured: 128 requests at 4 in flight, 128/128 accepted.
    static let maxConcurrentRequests = 4
    /// One first try plus three retries. Beyond that the server is not merely busy.
    static let maxAttempts = 4
    static let firstRetryDelaySeconds: TimeInterval = 0.5

    /// Rate limiting, a 5xx and a request that never arrived (status 0) are all "ask again shortly".
    /// A 401/403/404 is the server's settled answer and retrying it only spends the rate budget that
    /// the projects still waiting need.
    static func isTemporaryFailure(status: Int) -> Bool {
        status == 429 || status == 0 || (500..<600).contains(status)
    }

    /// How long to wait before attempt `attempt + 1`, or nil to stop trying. `attempt` is 1-based.
    /// The backoff doubles so a sweep that is being throttled backs away from the limiter instead of
    /// hammering it at a fixed interval.
    static func retryDelay(forStatus status: Int, attempt: Int) -> TimeInterval? {
        guard attempt >= 1, attempt < maxAttempts, isTemporaryFailure(status: status) else { return nil }
        return firstRetryDelaySeconds * pow(2, Double(attempt - 1))
    }

    /// Fold the per-project answers into the list the screen shows, keeping the projects that were
    /// never answered separate. A project missing from `outcomes` altogether counts as failed: the
    /// sweep cannot claim it is empty when it never heard back about it.
    static func result(from outcomes: [String: ProjectNotesOutcome], projects: [Project]) -> ProjectNotesSweepResult {
        var notesByProjectId: [String: [ProjectNote]] = [:]
        var failed: Set<String> = []
        for project in projects {
            switch outcomes[project.id] {
            case .notes(let notes): notesByProjectId[project.id] = notes
            case .failed, nil: failed.insert(project.id)
            }
        }
        return ProjectNotesSweepResult(entries: ProjectNoteEntry.entries(from: notesByProjectId, projects: projects),
                                       failedProjectIds: failed)
    }
}

/// Runs a `ProjectNotesSweep`: at most `maxConcurrentRequests` fetches in flight, each retried on a
/// temporary failure, finishing with one result for every project.
///
/// The fetch and the retry timer are both injected, so the scheduling this class exists for — how
/// many requests it allows at once, what it retries and how often — is testable without a network or
/// a wall clock.
final class ProjectNotesSweepRunner {
    typealias Fetch = (_ projectId: String, _ completion: @escaping (_ notes: [ProjectNote]?, _ statusCode: Int) -> Void) -> Void
    typealias Schedule = (_ delay: TimeInterval, _ work: @escaping () -> Void) -> Void

    private let fetch: Fetch
    private let schedule: Schedule
    private let maxConcurrentRequests: Int
    private let lock = NSLock()
    private var queue: [Project] = []
    private var outcomes: [String: ProjectNotesOutcome] = [:]
    private var projects: [Project] = []
    private var remaining = 0
    private var completion: ((ProjectNotesSweepResult) -> Void)?

    init(fetch: @escaping Fetch,
         schedule: @escaping Schedule = { delay, work in
             DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay, execute: work)
         },
         maxConcurrentRequests: Int = ProjectNotesSweep.maxConcurrentRequests) {
        self.fetch = fetch
        self.schedule = schedule
        self.maxConcurrentRequests = maxConcurrentRequests
    }

    /// Sweep `projects`, calling back once with every project accounted for.
    func run(projects: [Project], completion: @escaping (ProjectNotesSweepResult) -> Void) {
        guard !projects.isEmpty else {
            completion(ProjectNotesSweep.result(from: [:], projects: projects))
            return
        }
        lock.lock()
        self.projects = projects
        self.completion = completion
        queue = projects
        remaining = projects.count
        outcomes = [:]
        let slots = min(maxConcurrentRequests, projects.count)
        lock.unlock()
        for _ in 0..<slots { startNext() }
    }

    private func startNext() {
        lock.lock()
        guard !queue.isEmpty else { lock.unlock(); return }
        let project = queue.removeFirst()
        lock.unlock()
        attempt(project, attempt: 1)
    }

    private func attempt(_ project: Project, attempt number: Int) {
        fetch(project.id) { [weak self] notes, statusCode in
            guard let self = self else { return }
            if let notes = notes {
                self.finish(project, outcome: .notes(notes))
                return
            }
            guard let delay = ProjectNotesSweep.retryDelay(forStatus: statusCode, attempt: number) else {
                self.finish(project, outcome: .failed)
                return
            }
            self.retry(project, attempt: number + 1, after: delay)
        }
    }

    /// A retry keeps the slot it is already holding. Idling the slot for the backoff is the throttle:
    /// when the server is rate-limiting, the sweep should be making *fewer* requests per second, not
    /// handing the freed slot to the next project and keeping the pressure constant.
    private func retry(_ project: Project, attempt number: Int, after delay: TimeInterval) {
        schedule(delay) { [weak self] in
            self?.attempt(project, attempt: number)
        }
    }

    private func finish(_ project: Project, outcome: ProjectNotesOutcome) {
        lock.lock()
        outcomes[project.id] = outcome
        remaining -= 1
        let isDone = remaining == 0
        let result = isDone ? ProjectNotesSweep.result(from: outcomes, projects: projects) : nil
        let completion = isDone ? self.completion : nil
        if isDone { self.completion = nil }
        lock.unlock()
        if let completion = completion, let result = result {
            completion(result)
            return
        }
        startNext()
    }
}

/// Which notes the Notes screen lists.
///
/// `archived` is a view of shared notes rather than a fourth kind of note: archiving exists only for
/// project notes (a personal note is deleted, not filed away), so it belongs on the control that
/// already answers "which notes am I looking at" instead of a separate toggle beside it.
enum NotesScope: String, CaseIterable {
    case all, personal, project, archived

    var includesPersonalNotes: Bool { self == .all || self == .personal }
    var includesProjectNotes: Bool { self != .personal }
    /// Archived notes are hidden everywhere else — that is what archiving is for.
    var showsArchivedNotes: Bool { self == .archived }

    /// A scope worth reopening the screen on. Landing back in the archive later would read as every
    /// note having vanished, so — like the project filter — it is a momentary view, not a preference.
    var isWorthPersisting: Bool { self != .archived }
}

/// A row in the Notes list: either one of the user's own notes or a note inside one of their projects.
enum NotesListItem: Identifiable, Equatable {
    case personal(Note)
    case project(ProjectNoteEntry)

    /// Ids come from two different tables, so they are namespaced before SwiftUI sees them.
    static let personalIdPrefix = "personal-"
    static let projectIdPrefix = "project-"

    var id: String {
        switch self {
        case .personal(let note): return NotesListItem.personalIdPrefix + note.id
        case .project(let entry): return NotesListItem.projectIdPrefix + entry.id
        }
    }

    var projectEntry: ProjectNoteEntry? {
        guard case .project(let entry) = self else { return nil }
        return entry
    }

    /// Both kinds are placed on one timeline: a personal note by the date the list already shows
    /// (`logged_at ?? created_at`), a project note by when it last changed.
    var sortDate: Date? {
        switch self {
        case .personal(let note): return ToDoDates.parse(note.displayDateString)
        case .project(let entry): return ToDoDates.parse(entry.sortDateString)
        }
    }
}

/// Builds the Notes list from the two sources.
enum NotesFeed {

    /// `personal` is what the screen already computed (brain dump excluded, tag filter and server-side
    /// search applied). Project notes are filtered here because they are fetched whole, not searched
    /// server-side, and the list rows carry no body to search.
    ///
    /// A tag filter excludes project notes entirely: note tags are a personal-notes concept, so
    /// "only notes tagged phd" can never mean a project note, and silently keeping them would make the
    /// filter look broken.
    /// `projectFilter` is a project id, or nil for "every project". Filtering to one project also
    /// drops personal notes: they belong to no project, so showing them under "Project X" would be
    /// the same kind of lie as keeping project notes under a tag filter.
    static func items(personal: [Note], projectNotes: [ProjectNoteEntry], scope: NotesScope,
                      searchQuery: String, isTagFilterActive: Bool,
                      projectFilter: String? = nil) -> [NotesListItem] {
        var items: [NotesListItem] = []
        if scope.includesPersonalNotes && projectFilter == nil {
            items += personal.map(NotesListItem.personal)
        }
        if scope.includesProjectNotes && !isTagFilterActive {
            var entries = matching(projectNotes, query: searchQuery)
            if let projectFilter {
                entries = entries.filter { $0.projectId == projectFilter }
            }
            items += entries.map(NotesListItem.project)
        }
        return items.sorted(by: isNewerFirst)
    }

    /// Which project notes the list draws on. Active and archived notes are two separate server
    /// fetches (`?archived=true`), so a default view cannot show an archived note even when one is
    /// still sitting in memory from the archive view.
    ///
    /// Each set is then checked against the note's own `archived_at` rather than against which
    /// request it arrived on. A server that does not understand the filter yet answers both requests
    /// with the same active notes, and the archive must show an honest empty list rather than present
    /// live notes as filed away.
    static func projectNotes(active: [ProjectNoteEntry], archived: [ProjectNoteEntry],
                             scope: NotesScope) -> [ProjectNoteEntry] {
        guard scope.showsArchivedNotes else { return active.filter { !$0.note.isArchived } }
        return archived.filter { $0.note.isArchived }
    }

    /// Where a note lands after it is archived or restored: out of one list and into the other, never
    /// in both. It is put at the front of its new list only so it is somewhere definite — what the
    /// screen actually shows is `items(...)`, which sorts by when each note was last edited, and
    /// archiving deliberately does not count as an edit (the server leaves `updated_at` alone, so a
    /// restored note goes back where its real last edit puts it rather than jumping to the top).
    static func moved(_ entry: ProjectNoteEntry, saved: ProjectNote, archived: Bool,
                      active: [ProjectNoteEntry], archive: [ProjectNoteEntry])
        -> (active: [ProjectNoteEntry], archive: [ProjectNoteEntry]) {
        var moved = entry
        moved.note = saved
        var remainingActive = active.filter { $0.id != saved.id }
        var remainingArchive = archive.filter { $0.id != saved.id }
        if archived {
            remainingArchive.insert(moved, at: 0)
        } else {
            remainingActive.insert(moved, at: 0)
        }
        return (remainingActive, remainingArchive)
    }

    /// Projects that actually have a note, newest note first, for the filter control. Offering a
    /// project with nothing in it would just be a way to empty the list.
    static func filterableProjects(_ entries: [ProjectNoteEntry]) -> [(id: String, name: String)] {
        var seen = Set<String>()
        var result: [(id: String, name: String)] = []
        // ISO-8601 timestamps sort chronologically as strings, so no parsing is needed here; an
        // entry with no timestamp sinks to the bottom rather than jumping to the top.
        let newestFirst = entries.sorted { ($0.sortDateString ?? "") > ($1.sortDateString ?? "") }
        for entry in newestFirst where seen.insert(entry.projectId).inserted {
            result.append((id: entry.projectId, name: entry.projectName))
        }
        return result
    }

    /// Case- and accent-insensitive title match, like a person would expect from a search box.
    static func matches(title: String, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return title.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    private static func matching(_ entries: [ProjectNoteEntry], query: String) -> [ProjectNoteEntry] {
        entries.filter { matches(title: $0.title, query: query) }
    }

    /// Newest first. Undated rows sink to the bottom, and ties fall back to the id so the order is
    /// stable across re-renders instead of shuffling.
    private static func isNewerFirst(_ lhs: NotesListItem, _ rhs: NotesListItem) -> Bool {
        let left = lhs.sortDate ?? .distantPast
        let right = rhs.sortDate ?? .distantPast
        if left != right { return left > right }
        return lhs.id < rhs.id
    }
}

/// What the Notes screen's "Close" button should close.
///
/// Closing a project note used to be reachable only from the Projects screen, where Close went
/// straight to `window.close()` and read as the whole app quitting — this window is the app's only
/// visible surface (report 2026-09-14_19-4x). Opening project notes from the Notes screen must not
/// reintroduce that: Close steps back to the note list first and only dismisses the screen once there
/// is nothing left to step back from.
enum NotesCloseStep: Equatable {
    case closeProjectNote, closeScreen

    static func next(hasOpenProjectNote: Bool) -> NotesCloseStep {
        hasOpenProjectNote ? .closeProjectNote : .closeScreen
    }
}

/// Who owns Escape while a project note is open.
///
/// Back saves a half-typed title rather than dropping it (report 2026-09-15_20-24-10), so Escape
/// cannot also mean Back while one is being typed — the user would have no way to abandon a rename.
/// While the title field is in edit mode Escape is its discard; the rest of the time it steps back to
/// the list. They cannot share it: `.cancelAction` is a window-wide key equivalent, which AppKit
/// dispatches before the focused field ever sees the key.
enum NoteEscapeTarget: Equatable {
    case discardTitleEdit, backToList

    static func next(isRenamingTitle: Bool) -> NoteEscapeTarget {
        isRenamingTitle ? .discardTitleEdit : .backToList
    }
}

/// The Notes footer's primary button.
///
/// The product owner asked for Archive to replace Close on an open note (report
/// 2026-09-15_20-22-23), and on that screen Close was already a duplicate: "Back to notes" steps back
/// to the list and Escape does the same. So Archive takes the button only while a note is open, and
/// the list keeps Close — which means `NotesCloseStep` now only ever runs from the list and can never
/// dismiss the screen from inside a note.
enum NotesFooterAction: Equatable {
    case archiveNote, restoreNote, closeScreen

    static func next(openNote: ProjectNote?) -> NotesFooterAction {
        guard let note = openNote else { return .closeScreen }
        return note.isArchived ? .restoreNote : .archiveNote
    }
}

/// What happens to the note on screen once it is archived or restored.
///
/// Archiving is "I am done with this": the note has just left the list behind it, and leaving its
/// collaborative session open on something the user filed away is the wrong default — so it steps
/// back, exactly like Back. Restoring is the opposite intent, rescuing a note to work on, so it stays
/// open.
enum ArchivedNoteDisposition: Equatable {
    case stepBackToList, stayOpen

    static func next(archived: Bool) -> ArchivedNoteDisposition {
        archived ? .stepBackToList : .stayOpen
    }
}

/// Creating a project note from the Notes screen (`POST /projects/:id/notes { title }`).
enum NewProjectNote {
    /// A project must be chosen; the title may be left blank and defaults like it does in the
    /// Projects screen's "Create note".
    static func canCreate(projectId: String?) -> Bool {
        guard let projectId = projectId else { return false }
        return !projectId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func resolvedTitle(typed: String, fallback: String) -> String {
        let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

/// The dashboard deep link for a project note, shared by the Projects detail and the Notes screen so
/// the two cannot drift apart.
enum ProjectNoteLinks {
    static func webURL(projectId: String, noteId: String?) -> URL? {
        var path = "\(ToDoExternalLinks.dashboard)/projects/\(projectId)?tab=notes"
        if let noteId = noteId, !noteId.isEmpty { path += "&note_id=\(noteId)" }
        return URL(string: path)
    }
}
