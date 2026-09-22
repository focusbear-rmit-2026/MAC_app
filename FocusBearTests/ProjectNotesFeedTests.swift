//
//  ProjectNotesFeedTests.swift
//  Focus BearTests
//
//  Unit tests for the logic that puts project notes on the Notes screen (ProjectNotesFeed.swift,
//  report 2026-09-15_10-39-04): which notes are listed and in what order, that a fetched body lands
//  on the right entry, that a note created from here is attached to the project the user chose, and
//  that "Close" steps back to the list instead of shutting the window.
//
//  It also covers the searchable project dropdown that replaced the flat Picker: what it offers,
//  how typing narrows it, what a typed name resolves to, and that a SwiftUI refresh cannot eat the
//  text being typed.
//

@testable import Focus_Bear
import XCTest
import SwiftUI

final class ProjectNotesFeedTests: XCTestCase {

    // MARK: - Fixtures

    private func personal(_ id: String, title: String = "", created: String, logged: String? = nil,
                          tags: [NoteTag]? = nil) -> Note {
        Note(id: id, title: title.isEmpty ? id : title, body: nil, completed_activity_id: nil, tags: tags,
             embedded_todo_ids: nil, activity_name: nil, activity_emoji: nil, logged_at: logged,
             created_at: created, updated_at: created, is_brain_dump: nil)
    }

    private func projectNote(_ id: String, title: String = "", projectId: String = "p1",
                             updated: String? = nil, created: String? = "2026-01-01T00:00:00.000Z",
                             content: JSONValue? = nil, archivedAt: String? = nil) -> ProjectNote {
        ProjectNote(id: id, project_id: projectId, created_by: nil, title: title.isEmpty ? id : title,
                    content: content, created_at: created, updated_at: updated, archived_at: archivedAt)
    }

    private func entry(_ id: String, title: String = "", projectId: String = "p1",
                       projectName: String = "Project One", updated: String? = nil,
                       archivedAt: String? = nil) -> ProjectNoteEntry {
        ProjectNoteEntry(projectId: projectId, projectName: projectName,
                         note: projectNote(id, title: title, projectId: projectId, updated: updated,
                                           archivedAt: archivedAt))
    }

    /// Only id and name matter to the notes feed; every other `Project` field is optional and defaults
    /// to nil, so spelling them out here would just break whenever the model gains a field.
    private func project(_ id: String, name: String) -> Project {
        Project(id: id, name: name)
    }

    private func ids(_ items: [NotesListItem]) -> [String] { items.map { $0.id } }

    // MARK: - What the list contains and in what order

    func testAllScopeInterleavesPersonalAndProjectNotesNewestFirst() {
        let personalNotes = [personal("own-old", created: "2026-09-01T10:00:00.000Z"),
                             personal("own-new", created: "2026-09-10T10:00:00.000Z")]
        let projectNotes = [entry("proj-mid", updated: "2026-09-05T10:00:00.000Z"),
                            entry("proj-newest", updated: "2026-09-12T10:00:00.000Z")]

        let items = NotesFeed.items(personal: personalNotes, projectNotes: projectNotes, scope: .all,
                                    searchQuery: "", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["project-proj-newest", "personal-own-new",
                                    "project-proj-mid", "personal-own-old"])
    }

    func testPersonalNotesAreDatedByTheDateTheListAlreadyShows() {
        // displayDateString is `logged_at ?? created_at`, so a back-dated log sorts by when it happened.
        let notes = [personal("logged-earlier", created: "2026-09-20T10:00:00.000Z", logged: "2026-09-02T10:00:00.000Z")]
        let projectNotes = [entry("project-note", updated: "2026-09-10T10:00:00.000Z")]

        let items = NotesFeed.items(personal: notes, projectNotes: projectNotes, scope: .all,
                                    searchQuery: "", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["project-project-note", "personal-logged-earlier"])
    }

    func testProjectNotesFallBackToTheirCreatedDateWhenNeverEdited() {
        let never = ProjectNoteEntry(projectId: "p1", projectName: "Project One",
                                     note: projectNote("never-edited", updated: nil, created: "2026-09-15T10:00:00.000Z"))
        let older = entry("edited", updated: "2026-09-14T10:00:00.000Z")

        let items = NotesFeed.items(personal: [], projectNotes: [older, never], scope: .all,
                                    searchQuery: "", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["project-never-edited", "project-edited"])
    }

    func testUndatedNotesSinkToTheBottomInAStableOrder() {
        let undatedB = ProjectNoteEntry(projectId: "p1", projectName: "Project One",
                                        note: projectNote("b", updated: nil, created: nil))
        let undatedA = ProjectNoteEntry(projectId: "p1", projectName: "Project One",
                                        note: projectNote("a", updated: nil, created: nil))
        let dated = entry("dated", updated: "2026-09-01T10:00:00.000Z")

        let items = NotesFeed.items(personal: [], projectNotes: [undatedB, dated, undatedA], scope: .all,
                                    searchQuery: "", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["project-dated", "project-a", "project-b"])
    }

    // MARK: - Scope

    func testPersonalScopeHidesProjectNotes() {
        let items = NotesFeed.items(personal: [personal("own", created: "2026-09-01T10:00:00.000Z")],
                                    projectNotes: [entry("proj", updated: "2026-09-02T10:00:00.000Z")],
                                    scope: .personal, searchQuery: "", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["personal-own"])
    }

    func testProjectScopeHidesPersonalNotes() {
        let items = NotesFeed.items(personal: [personal("own", created: "2026-09-01T10:00:00.000Z")],
                                    projectNotes: [entry("proj", updated: "2026-09-02T10:00:00.000Z")],
                                    scope: .project, searchQuery: "", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["project-proj"])
    }

    // MARK: - Search and tag filter

    func testSearchFiltersProjectNotesByTitle() {
        let entries = [entry("a", title: "Roadmap review"), entry("b", title: "Hiring plan")]

        let items = NotesFeed.items(personal: [], projectNotes: entries, scope: .all,
                                    searchQuery: "roadmap", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["project-a"])
    }

    func testSearchIgnoresCaseAndAccents() {
        XCTAssertTrue(NotesFeed.matches(title: "Reunión de equipo", query: "reunion"))
        XCTAssertTrue(NotesFeed.matches(title: "Roadmap", query: "  ROAD "))
        XCTAssertFalse(NotesFeed.matches(title: "Roadmap", query: "budget"))
    }

    func testAnEmptySearchKeepsEveryProjectNote() {
        XCTAssertTrue(NotesFeed.matches(title: "anything", query: "   "))
    }

    func testSearchDoesNotRefilterPersonalNotesTheServerAlreadySearched() {
        // `GET /note/search` matches bodies too, so a result whose title misses the query must stay.
        let result = personal("hit", title: "Untitled", created: "2026-09-01T10:00:00.000Z")

        let items = NotesFeed.items(personal: [result], projectNotes: [], scope: .all,
                                    searchQuery: "something in the body", isTagFilterActive: false)

        XCTAssertEqual(ids(items), ["personal-hit"])
    }

    func testATagFilterExcludesProjectNotesEntirely() {
        // Tags are a personal-notes concept; project notes carry none, so "only notes tagged X"
        // can never mean a project note.
        let tagged = personal("own", created: "2026-09-01T10:00:00.000Z",
                              tags: [NoteTag(id: "t1", text: "phd", color: nil)])

        let items = NotesFeed.items(personal: [tagged], projectNotes: [entry("proj", updated: "2026-09-09T10:00:00.000Z")],
                                    scope: .all, searchQuery: "", isTagFilterActive: true)

        XCTAssertEqual(ids(items), ["personal-own"])
    }

    // MARK: - Building entries from a fetch

    func testEntriesGroupNotesUnderTheirProjectAndSkipEmptyProjects() {
        let projects = [project("p1", name: "Project One"), project("p2", name: "Project Two")]
        let fetched = ["p1": [projectNote("n1", projectId: "p1")],
                       "p2": []]

        let entries = ProjectNoteEntry.entries(from: fetched, projects: projects)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.projectId, "p1")
        XCTAssertEqual(entries.first?.projectName, "Project One")
    }

    func testEntriesIgnoreProjectsMissingFromTheFetch() {
        let projects = [project("p1", name: "Project One")]

        XCTAssertTrue(ProjectNoteEntry.entries(from: [:], projects: projects).isEmpty)
    }

    // MARK: - Creating a project note attaches it to the chosen project

    func testACreatedNoteIsAttachedToTheChosenProject() {
        let chosen = project("p2", name: "Project Two")
        // The POST response need not echo project_id; the chosen project is what the row belongs to.
        let created = projectNote("new", title: "Kickoff", projectId: "", updated: "2026-09-15T10:00:00.000Z")

        let entry = ProjectNoteEntry.created(note: created, in: chosen)

        XCTAssertEqual(entry.projectId, "p2")
        XCTAssertEqual(entry.projectName, "Project Two")
        XCTAssertEqual(entry.title, "Kickoff")
        XCTAssertEqual(ProjectNoteLinks.webURL(projectId: entry.projectId, noteId: entry.id)?.absoluteString,
                       "https://dashboard.focusbear.io/projects/p2?tab=notes&note_id=new")
    }

    func testACreatedNoteAppearsInTheListUnderThatProject() {
        let chosen = project("p2", name: "Project Two")
        let entries = [ProjectNoteEntry.created(note: projectNote("new", updated: "2026-09-15T10:00:00.000Z"), in: chosen)]

        let items = NotesFeed.items(personal: [], projectNotes: entries, scope: .project,
                                    searchQuery: "", isTagFilterActive: false)

        XCTAssertEqual(items.first?.projectEntry?.projectName, "Project Two")
    }

    func testCreateNeedsAProject() {
        XCTAssertFalse(NewProjectNote.canCreate(projectId: nil))
        XCTAssertFalse(NewProjectNote.canCreate(projectId: "   "))
        XCTAssertTrue(NewProjectNote.canCreate(projectId: "p1"))
    }

    func testABlankTitleFallsBackToTheUntitledLabel() {
        XCTAssertEqual(NewProjectNote.resolvedTitle(typed: "   ", fallback: "Untitled note"), "Untitled note")
        XCTAssertEqual(NewProjectNote.resolvedTitle(typed: "  Kickoff  ", fallback: "Untitled note"), "Kickoff")
    }

    // MARK: - A fetched body round-trips onto the right entry

    func testFetchingANoteBodyUpdatesOnlyThatEntry() {
        let entries = [entry("n1", title: "First", projectId: "p1", projectName: "Project One"),
                       entry("n2", title: "Second", projectId: "p2", projectName: "Project Two")]
        let full = projectNote("n2", title: "Second", projectId: "p2", updated: "2026-09-16T10:00:00.000Z",
                               content: .object(["type": .string("doc"),
                                                 "content": .array([.object(["type": .string("text"),
                                                                             "text": .string("Body text")])])]))

        let updated = ProjectNoteEntry.applying(full, to: entries)

        XCTAssertEqual(updated.count, 2)
        XCTAssertEqual(updated[0].note.plainText, "", "The untouched entry keeps its body-less stub")
        XCTAssertTrue(updated[1].note.plainText.contains("Body text"))
        XCTAssertEqual(updated[1].projectId, "p2", "The entry stays under the project it was listed in")
        XCTAssertEqual(updated[1].projectName, "Project Two")
    }

    func testAFetchedNoteForSomethingNotListedChangesNothing() {
        let entries = [entry("n1")]

        XCTAssertEqual(ProjectNoteEntry.applying(projectNote("other"), to: entries), entries)
    }

    // MARK: - What "Close" closes

    func testCloseStepsBackFromAnOpenProjectNoteFirst() {
        XCTAssertEqual(NotesCloseStep.next(hasOpenProjectNote: true), .closeProjectNote)
    }

    func testCloseOnlyDismissesTheScreenWhenNoProjectNoteIsOpen() {
        XCTAssertEqual(NotesCloseStep.next(hasOpenProjectNote: false), .closeScreen)
    }

    // MARK: - Deep link

    func testTheProjectNotesTabLinkOmitsTheNoteIdWhenThereIsNoNote() {
        XCTAssertEqual(ProjectNoteLinks.webURL(projectId: "p1", noteId: nil)?.absoluteString,
                       "https://dashboard.focusbear.io/projects/p1?tab=notes")
        XCTAssertEqual(ProjectNoteLinks.webURL(projectId: "p1", noteId: "")?.absoluteString,
                       "https://dashboard.focusbear.io/projects/p1?tab=notes")
    }

    // MARK: - Scope flags

    func testScopeFlags() {
        XCTAssertTrue(NotesScope.all.includesPersonalNotes)
        XCTAssertTrue(NotesScope.all.includesProjectNotes)
        XCTAssertTrue(NotesScope.personal.includesPersonalNotes)
        XCTAssertFalse(NotesScope.personal.includesProjectNotes)
        XCTAssertFalse(NotesScope.project.includesPersonalNotes)
        XCTAssertTrue(NotesScope.project.includesProjectNotes)
        // Archiving exists only for shared notes, so the archive is a shared-notes view.
        XCTAssertFalse(NotesScope.archived.includesPersonalNotes)
        XCTAssertTrue(NotesScope.archived.includesProjectNotes)
    }

    // MARK: - Project filter (report 2026-09-15_16-46-25)

    func testProjectFilterKeepsOnlyThatProjectsNotes() {
        let entries = [entry("a", projectId: "p1", projectName: "Alpha", updated: "2026-09-15T10:00:00.000Z"),
                       entry("b", projectId: "p2", projectName: "Beta", updated: "2026-09-15T09:00:00.000Z")]
        let items = NotesFeed.items(personal: [], projectNotes: entries, scope: .all,
                                    searchQuery: "", isTagFilterActive: false, projectFilter: "p1")
        XCTAssertEqual(items.count, 1)
    }

    /// Personal notes belong to no project, so listing them under "Project X" would be a lie.
    func testFilteringToAProjectDropsPersonalNotes() {
        let items = NotesFeed.items(personal: [personal("mine", created: "2026-09-15T12:00:00.000Z")],
                                    projectNotes: [entry("a", projectId: "p1", updated: "2026-09-15T10:00:00.000Z")],
                                    scope: .all, searchQuery: "", isTagFilterActive: false,
                                    projectFilter: "p1")
        XCTAssertEqual(items.count, 1, "Only the filtered project's note survives")
    }

    func testNoFilterKeepsPersonalAndEveryProject() {
        let items = NotesFeed.items(personal: [personal("mine", created: "2026-09-15T12:00:00.000Z")],
                                    projectNotes: [entry("a", projectId: "p1", updated: "2026-09-15T10:00:00.000Z"),
                                                   entry("b", projectId: "p2", updated: "2026-09-15T09:00:00.000Z")],
                                    scope: .all, searchQuery: "", isTagFilterActive: false,
                                    projectFilter: nil)
        XCTAssertEqual(items.count, 3)
    }

    /// The control must not offer a project with nothing in it — that is only a way to empty the list.
    func testFilterableProjectsAreDeduplicatedNewestFirst() {
        let entries = [entry("a", projectId: "p2", projectName: "Beta", updated: "2026-09-15T09:00:00.000Z"),
                       entry("b", projectId: "p1", projectName: "Alpha", updated: "2026-09-15T11:00:00.000Z"),
                       entry("c", projectId: "p1", projectName: "Alpha", updated: "2026-09-15T10:00:00.000Z")]
        XCTAssertEqual(NotesFeed.filterableProjects(entries).map(\.id), ["p1", "p2"])
    }

    func testFilterableProjectsIsEmptyWithoutAnyNotes() {
        XCTAssertTrue(NotesFeed.filterableProjects([]).isEmpty)
    }

    // MARK: - Searchable project dropdown (report 2026-09-15_10-39-04 follow-up)

    private static let allProjectsTitle = "All projects"

    func testDropdownSelectionCommitsBeforeEditingEnds() {
        var selected: String? = nil
        let field = SearchableComboBoxField(options: dropdownOptions,
            selectedId: Binding(get: { selected }, set: { selected = $0 }),
            clearedOptionTitle: Self.allProjectsTitle, commitPolicy: .whenResolved)
        let coordinator = field.makeCoordinator()
        let box = SearchableComboBoxField.makeFilteringBox(placeholder: "")
        box.items = SearchableComboBoxField.titles(clearedOptionTitle: Self.allProjectsTitle,
                                                  options: dropdownOptions)
        box.customDelegate = coordinator
        box.filterData(comboBox: box, selectedText: "")
        XCTAssertNil(selected, "Rebuilding the menu must not commit a selection")
        box.selectItem(at: 2)
        box.comboBoxSelectionDidChange(Notification(name: NSComboBox.selectionDidChangeNotification, object: box))
        XCTAssertEqual(selected, "p2", "Selecting UX must update the binding without blur or Return")
    }

    private var dropdownOptions: [SearchableComboBoxField.Option] {
        [SearchableComboBoxField.Option(id: "p1", name: "NDIA Q3"),
         SearchableComboBoxField.Option(id: "p2", name: "UX"),
         SearchableComboBoxField.Option(id: "p3", name: "MRFF Mental Health grant application")]
    }

    private func dropdownBox() -> searchableComboBox {
        let box = SearchableComboBoxField.makeFilteringBox(placeholder: Self.allProjectsTitle)
        box.items = SearchableComboBoxField.titles(clearedOptionTitle: Self.allProjectsTitle,
                                                   options: dropdownOptions)
        box.filterdItems = box.items
        return box
    }

    func testTheDropdownOffersAllProjectsBeforeEveryProjectWithANote() {
        XCTAssertEqual(SearchableComboBoxField.titles(clearedOptionTitle: Self.allProjectsTitle,
                                                      options: dropdownOptions),
                       ["All projects", "NDIA Q3", "UX", "MRFF Mental Health grant application"])
    }

    /// The point of the control: a long list narrows to what was typed, anywhere in the name.
    func testTypingNarrowsTheDropdownToMatchingProjects() {
        let box = dropdownBox()
        box.filterData(comboBox: box, selectedText: "ment")
        XCTAssertEqual(box.filterdItems, ["MRFF Mental Health grant application"])
        box.filterData(comboBox: box, selectedText: "nd")
        XCTAssertEqual(box.filterdItems, ["NDIA Q3"])
    }

    func testClearingTheTypedTextRestoresEveryRowOfTheDropdown() {
        let box = dropdownBox()
        box.filterData(comboBox: box, selectedText: "ux")
        XCTAssertEqual(box.filterdItems, ["UX"])
        box.filterData(comboBox: box, selectedText: "")
        XCTAssertEqual(box.filterdItems.count, dropdownOptions.count + 1, "The cleared row comes back too")
    }

    func testTypingSomethingNoProjectMatchesLeavesTheDropdownEmpty() {
        let box = dropdownBox()
        box.filterData(comboBox: box, selectedText: "zzz")
        XCTAssertTrue(box.filterdItems.isEmpty)
    }

    /// Picking a row hands the feed a project id, and the feed drops everything else.
    func testSelectingAProjectFromTheDropdownFiltersTheNotes() {
        let chosen = SearchableComboBoxField.resolve(text: "UX", options: dropdownOptions)
        XCTAssertEqual(chosen, "p2")
        let items = NotesFeed.items(personal: [personal("mine", created: "2026-09-15T12:00:00.000Z")],
                                    projectNotes: [entry("a", projectId: "p1", updated: "2026-09-15T10:00:00.000Z"),
                                                   entry("b", projectId: "p2", updated: "2026-09-15T09:00:00.000Z")],
                                    scope: .all, searchQuery: "", isTagFilterActive: false,
                                    projectFilter: chosen)
        XCTAssertEqual(items.map(\.id), [NotesListItem.projectIdPrefix + "b"])
    }

    func testChoosingAllProjectsRestoresEverything() {
        let cleared = SearchableComboBoxField.resolve(text: Self.allProjectsTitle, options: dropdownOptions)
        XCTAssertNil(cleared)
        let items = NotesFeed.items(personal: [personal("mine", created: "2026-09-15T12:00:00.000Z")],
                                    projectNotes: [entry("a", projectId: "p1", updated: "2026-09-15T10:00:00.000Z"),
                                                   entry("b", projectId: "p2", updated: "2026-09-15T09:00:00.000Z")],
                                    scope: .all, searchQuery: "", isTagFilterActive: false,
                                    projectFilter: cleared)
        XCTAssertEqual(items.count, 3)
    }

    /// Text that narrows the menu to one row means that row — the user typed enough and clicked away.
    func testTypingEnoughToLeaveOneProjectSelectsIt() {
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "ndia", options: dropdownOptions), "p1")
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "  ux  ", options: dropdownOptions), "p2")
    }

    /// An unknown or still-ambiguous name must clear the filter rather than leave the field showing a
    /// project that filters the list to nothing.
    func testUnknownOrAmbiguousTextClearsTheFilter() {
        XCTAssertNil(SearchableComboBoxField.resolve(text: "zzz", options: dropdownOptions))
        XCTAssertNil(SearchableComboBoxField.resolve(text: "", options: dropdownOptions))
        let ambiguous = [SearchableComboBoxField.Option(id: "p1", name: "Design system"),
                         SearchableComboBoxField.Option(id: "p2", name: "Design review")]
        XCTAssertNil(SearchableComboBoxField.resolve(text: "design", options: ambiguous))
    }

    func testTheFieldShowsTheSelectedProjectOrTheClearedRow() {
        XCTAssertEqual(SearchableComboBoxField.displayName(for: "p2", options: dropdownOptions,
                                                           clearedOptionTitle: Self.allProjectsTitle), "UX")
        XCTAssertEqual(SearchableComboBoxField.displayName(for: nil, options: dropdownOptions,
                                                           clearedOptionTitle: Self.allProjectsTitle),
                       Self.allProjectsTitle)
        XCTAssertEqual(SearchableComboBoxField.displayName(for: "gone", options: dropdownOptions,
                                                           clearedOptionTitle: Self.allProjectsTitle),
                       Self.allProjectsTitle, "A project that stopped having notes falls back to the cleared row")
    }

    /// `updateNSView` runs on every SwiftUI refresh. Writing the selection back while the user is
    /// typing ate each keystroke in `BlockListComboBox`; this dropdown uses the same shared rule.
    func testTypedTextSurvivesASwiftUIRefresh() {
        for partial in ["N", "ND", "NDI"] {
            XCTAssertFalse(ComboBoxTextSync.shouldOverwriteText(isEditing: true, current: partial,
                                                                selectedName: Self.allProjectsTitle),
                           "Refreshing mid-edit must not replace \(partial)")
        }
        XCTAssertTrue(ComboBoxTextSync.shouldOverwriteText(isEditing: false, current: "",
                                                           selectedName: "NDIA Q3"),
                      "Once editing is over the field shows the selection")
        XCTAssertFalse(ComboBoxTextSync.shouldOverwriteText(isEditing: false, current: "NDIA Q3",
                                                            selectedName: "NDIA Q3"),
                       "Nothing to write when the field already agrees")
    }

    // MARK: - Renaming a note and leaving (report 2026-09-15_20-24-10)

    /// The reported bug: type a new title, click Back, and the rename was dropped because the field
    /// editor never resigned, so end-editing never fired.
    func testBackSavesATitleThatWasTypedButNeverEntered() {
        XCTAssertEqual(InlineRenameDismissal.onDismiss(draft: "Live widget tests", value: "Untitled note",
                                                       isEditing: true),
                       .save("Live widget tests"))
    }

    func testASavedTitleIsTrimmed() {
        XCTAssertEqual(InlineRenameDismissal.onDismiss(draft: "  Spaced out  ", value: "Old", isEditing: true),
                       .save("Spaced out"))
    }

    /// Escape is the discard route: it leaves edit mode first, so there is nothing pending to save.
    func testTheDiscardRouteLeavesNothingToSave() {
        XCTAssertEqual(InlineRenameDismissal.onDismiss(draft: "Thrown away", value: "Old", isEditing: false),
                       .discard)
    }

    func testABlankOrUnchangedTitleIsNotARename() {
        XCTAssertEqual(InlineRenameDismissal.onDismiss(draft: "", value: "Old", isEditing: true), .discard)
        XCTAssertEqual(InlineRenameDismissal.onDismiss(draft: "   ", value: "Old", isEditing: true), .discard)
        XCTAssertEqual(InlineRenameDismissal.onDismiss(draft: "Old", value: "Old", isEditing: true), .discard)
    }

    /// Back saves, so Escape cannot also mean Back while a rename is in progress — that would leave no
    /// way to abandon one.
    func testEscapeBelongsToTheTitleFieldOnlyWhileRenaming() {
        XCTAssertEqual(NoteEscapeTarget.next(isRenamingTitle: true), .discardTitleEdit)
        XCTAssertEqual(NoteEscapeTarget.next(isRenamingTitle: false), .backToList)
    }

    // MARK: - Archiving a project note (report 2026-09-15_20-22-23)

    private static let archivedStamp = "2026-09-15T20:30:00.000Z"

    func testANoteIsArchivedOnlyOnceTheServerHasStampedIt() {
        XCTAssertFalse(projectNote("a").isArchived)
        XCTAssertTrue(projectNote("a", archivedAt: Self.archivedStamp).isArchived)
    }

    /// Archived notes are a separate fetch, so no default view can show one even with the archive
    /// still in memory from a previous visit.
    func testArchivedNotesAreAbsentFromEveryDefaultList() {
        let active = [entry("a", updated: "2026-09-15T10:00:00.000Z")]
        let archived = [entry("b", updated: "2026-09-15T09:00:00.000Z", archivedAt: Self.archivedStamp)]
        for scope in [NotesScope.all, .personal, .project] {
            XCTAssertEqual(NotesFeed.projectNotes(active: active, archived: archived, scope: scope).map(\.id),
                           ["a"], "\(scope) must not show an archived note")
        }
    }

    func testTheArchiveShowsTheArchivedNotesAndNothingElse() {
        let active = [entry("a", updated: "2026-09-15T10:00:00.000Z")]
        let archived = [entry("b", updated: "2026-09-15T09:00:00.000Z", archivedAt: Self.archivedStamp)]
        XCTAssertEqual(NotesFeed.projectNotes(active: active, archived: archived, scope: .archived).map(\.id),
                       ["b"])
    }

    /// A personal note is deleted, never archived, so the archive is shared notes only.
    func testTheArchiveHidesPersonalNotes() {
        let archived = [entry("b", updated: "2026-09-15T09:00:00.000Z", archivedAt: Self.archivedStamp)]
        let items = NotesFeed.items(personal: [personal("mine", created: "2026-09-15T12:00:00.000Z")],
                                    projectNotes: archived, scope: .archived,
                                    searchQuery: "", isTagFilterActive: false)
        XCTAssertEqual(ids(items), [NotesListItem.projectIdPrefix + "b"])
    }

    /// Until the archive endpoint is deployed, both fetches come back with the same active notes. The
    /// archive must then be honestly empty rather than presenting live notes as filed away.
    func testAnApiThatIgnoresTheArchiveFilterShowsAnEmptyArchiveNotLiveNotes() {
        let active = [entry("a", updated: "2026-09-15T10:00:00.000Z"),
                      entry("b", updated: "2026-09-15T09:00:00.000Z")]
        XCTAssertTrue(NotesFeed.projectNotes(active: active, archived: active, scope: .archived).isEmpty)
        XCTAssertEqual(NotesFeed.projectNotes(active: active, archived: active, scope: .all).map(\.id),
                       ["a", "b"], "and the ordinary list is untouched")
    }

    /// Coming back to Notes later and finding only archived notes would read as everything vanishing.
    func testTheArchiveIsNotRemembered() {
        XCTAssertFalse(NotesScope.archived.isWorthPersisting)
        for scope in [NotesScope.all, .personal, .project] {
            XCTAssertTrue(scope.isWorthPersisting, "\(scope) is a lasting preference")
        }
    }

    /// Close belongs to the list; on an open note the footer button archives (or restores) instead.
    func testTheFooterButtonArchivesAnOpenNoteAndOtherwiseCloses() {
        XCTAssertEqual(NotesFooterAction.next(openNote: nil), .closeScreen)
        XCTAssertEqual(NotesFooterAction.next(openNote: projectNote("a")), .archiveNote)
        XCTAssertEqual(NotesFooterAction.next(openNote: projectNote("a", archivedAt: Self.archivedStamp)),
                       .restoreNote)
    }

    /// Replacing Close must not strand anyone inside a note: Back still steps back before the screen
    /// is dismissed, which is the regression `NotesCloseStep` exists for.
    func testCloseStillStepsBackFromAnOpenNoteBeforeDismissingTheScreen() {
        XCTAssertEqual(NotesCloseStep.next(hasOpenProjectNote: true), .closeProjectNote)
        XCTAssertEqual(NotesCloseStep.next(hasOpenProjectNote: false), .closeScreen)
    }

    func testArchivingStepsBackToTheListAndRestoringStaysOnTheNote() {
        XCTAssertEqual(ArchivedNoteDisposition.next(archived: true), .stepBackToList)
        XCTAssertEqual(ArchivedNoteDisposition.next(archived: false), .stayOpen)
    }

    func testArchivingMovesTheNoteOutOfTheListAndIntoTheArchive() {
        let note = entry("a", updated: "2026-09-15T10:00:00.000Z")
        let other = entry("b", updated: "2026-09-15T09:00:00.000Z")
        let saved = projectNote("a", archivedAt: Self.archivedStamp)
        let lists = NotesFeed.moved(note, saved: saved, archived: true, active: [note, other], archive: [])
        XCTAssertEqual(lists.active.map(\.id), ["b"])
        XCTAssertEqual(lists.archive.map(\.id), ["a"])
        XCTAssertTrue(lists.archive[0].note.isArchived)
    }

    /// Restoring returns the note to the active list. Where it then *appears* is decided by
    /// `items(...)` from its last-edited date, not by this position — archiving is not an edit.
    func testRestoringPutsTheNoteBackInTheList() {
        let archivedEntry = entry("a", updated: "2026-09-15T10:00:00.000Z", archivedAt: Self.archivedStamp)
        let other = entry("b", updated: "2026-09-15T09:00:00.000Z")
        let saved = projectNote("a")
        let lists = NotesFeed.moved(archivedEntry, saved: saved, archived: false,
                                    active: [other], archive: [archivedEntry])
        XCTAssertEqual(lists.active.map(\.id), ["a", "b"])
        XCTAssertTrue(lists.archive.isEmpty)
        XCTAssertFalse(lists.active[0].note.isArchived)
    }

    /// A note lives in exactly one of the two lists — archiving twice must not duplicate it.
    func testANoteIsNeverInBothLists() {
        let note = entry("a", updated: "2026-09-15T10:00:00.000Z")
        let saved = projectNote("a", archivedAt: Self.archivedStamp)
        let once = NotesFeed.moved(note, saved: saved, archived: true, active: [note], archive: [])
        let twice = NotesFeed.moved(note, saved: saved, archived: true,
                                    active: once.active, archive: once.archive)
        XCTAssertTrue(twice.active.isEmpty)
        XCTAssertEqual(twice.archive.map(\.id), ["a"])
    }

    /// The project filter offers whatever is in view, so inside the archive it offers the projects
    /// with archived notes — not the ones with active notes.
    func testTheProjectFilterFollowsTheArchiveScope() {
        let active = [entry("a", projectId: "p1", projectName: "Alpha", updated: "2026-09-15T10:00:00.000Z")]
        let archived = [entry("b", projectId: "p2", projectName: "Beta", updated: "2026-09-15T09:00:00.000Z",
                              archivedAt: Self.archivedStamp)]
        let inArchive = NotesFeed.projectNotes(active: active, archived: archived, scope: .archived)
        XCTAssertEqual(NotesFeed.filterableProjects(inArchive).map(\.id), ["p2"])
        let inList = NotesFeed.projectNotes(active: active, archived: archived, scope: .all)
        XCTAssertEqual(NotesFeed.filterableProjects(inList).map(\.id), ["p1"])
    }

    // MARK: - Sweeping every project's notes without being rate limited
    //
    // The bug these cover (report 2026-09-15_10-39-04, "I'm not seeing the project note from the UX
    // project"): the screen fired one GET /projects/:id/notes per active project all at once. The
    // endpoint allows 10 requests a second, so on an account with 128 projects the server refused
    // most of them with 429 — measured live: 66 of 128, the UX project among them. Each refusal was
    // recorded as `notes ?? []`, i.e. as a project that HAS no notes, so real notes disappeared from
    // the list and their projects disappeared from the filter, silently and differently each run.

    func testARefusedProjectIsNotReportedAsAProjectWithNoNotes() {
        let projects = [project("p1", name: "Alpha"), project("p2", name: "UX")]
        let result = ProjectNotesSweep.result(from: ["p1": .notes([projectNote("a", projectId: "p1")]),
                                                     "p2": .failed],
                                              projects: projects)
        XCTAssertEqual(result.entries.map(\.id), ["a"])
        XCTAssertEqual(result.failedProjectIds, ["p2"])
        XCTAssertFalse(result.isComplete, "a sweep that lost a project has not finished loading")
    }

    /// An empty project and a refused one produce the same empty list; only `failedProjectIds` can
    /// tell them apart, which is exactly what the old code threw away.
    func testAnEmptyProjectIsNotConfusedWithARefusedOne() {
        let projects = [project("p1", name: "Alpha"), project("p2", name: "UX")]
        let result = ProjectNotesSweep.result(from: ["p1": .notes([]), "p2": .failed], projects: projects)
        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertEqual(result.failedProjectIds, ["p2"])
    }

    /// A project the sweep never heard back about at all is a failure, not an empty project.
    func testAProjectMissingFromTheAnswersCountsAsFailed() {
        let projects = [project("p1", name: "Alpha"), project("p2", name: "UX")]
        let result = ProjectNotesSweep.result(from: ["p1": .notes([])], projects: projects)
        XCTAssertEqual(result.failedProjectIds, ["p2"])
    }

    func testRateLimitingAndTransportFailuresAreRetriedButRefusalsAreNot() {
        XCTAssertTrue(ProjectNotesSweep.isTemporaryFailure(status: 429))
        XCTAssertTrue(ProjectNotesSweep.isTemporaryFailure(status: 0), "the request never left the Mac")
        XCTAssertTrue(ProjectNotesSweep.isTemporaryFailure(status: 503))
        XCTAssertFalse(ProjectNotesSweep.isTemporaryFailure(status: 401))
        XCTAssertFalse(ProjectNotesSweep.isTemporaryFailure(status: 403))
        XCTAssertFalse(ProjectNotesSweep.isTemporaryFailure(status: 404))
    }

    /// Retrying a 404 would spend rate-limit budget the projects still waiting need.
    func testAPermanentFailureIsNotRetried() {
        XCTAssertNil(ProjectNotesSweep.retryDelay(forStatus: 404, attempt: 1))
    }

    func testBackoffDoublesAndThenGivesUp() {
        let delays = (1...ProjectNotesSweep.maxAttempts).map {
            ProjectNotesSweep.retryDelay(forStatus: 429, attempt: $0)
        }
        XCTAssertEqual(delays.dropLast().compactMap { $0 },
                       [ProjectNotesSweep.firstRetryDelaySeconds,
                        ProjectNotesSweep.firstRetryDelaySeconds * 2,
                        ProjectNotesSweep.firstRetryDelaySeconds * 4])
        XCTAssertNil(delays.last!, "the last attempt has nothing after it")
    }

    // MARK: - The sweep runner's scheduling

    /// Records how many fetches were in flight at once, and answers each one as the test dictates.
    private final class FakeNotesAPI {
        private let lock = NSLock()
        private(set) var peakConcurrency = 0
        private(set) var attemptsByProject: [String: Int] = [:]
        private var inFlight = 0
        /// `(attemptNumber) -> (notes, statusCode)` per project.
        var answer: (String, Int) -> ([ProjectNote]?, Int) = { _, _ in (nil, 200) }

        func fetch(_ projectId: String, _ completion: @escaping ([ProjectNote]?, Int) -> Void) {
            lock.lock()
            inFlight += 1
            peakConcurrency = max(peakConcurrency, inFlight)
            let attempt = (attemptsByProject[projectId] ?? 0) + 1
            attemptsByProject[projectId] = attempt
            lock.unlock()
            let reply = answer(projectId, attempt)
            lock.lock()
            inFlight -= 1
            lock.unlock()
            completion(reply.0, reply.1)
        }
    }

    /// Holds every request open instead of answering it, so a test can look at how many the runner
    /// put on the wire before any of them came back. A fake that answers immediately cannot measure
    /// that at all — it never has more than one request outstanding, so it would pass just as happily
    /// against the unbounded fan-out this is here to rule out.
    private final class DeferredNotesAPI {
        private let lock = NSLock()
        private var pending: [(String, ([ProjectNote]?, Int) -> Void)] = []
        private(set) var peakConcurrency = 0
        private(set) var askedProjectIds: Set<String> = []

        func fetch(_ projectId: String, _ completion: @escaping ([ProjectNote]?, Int) -> Void) {
            lock.lock()
            pending.append((projectId, completion))
            askedProjectIds.insert(projectId)
            peakConcurrency = max(peakConcurrency, pending.count)
            lock.unlock()
        }

        var inFlight: Int {
            lock.lock()
            defer { lock.unlock() }
            return pending.count
        }

        /// Answer everything outstanding. Answering frees slots, so the runner starts more requests
        /// while this is draining — those land in a fresh `pending` for the next drain.
        func drainAll(_ answer: (String) -> ([ProjectNote]?, Int)) {
            lock.lock()
            let batch = pending
            pending = []
            lock.unlock()
            for (projectId, completion) in batch {
                let reply = answer(projectId)
                completion(reply.0, reply.1)
            }
        }
    }

    /// Runs retries immediately so the backoff does not make the test slow, and counts the waits.
    private final class FakeClock {
        private(set) var delays: [TimeInterval] = []
        func schedule(_ delay: TimeInterval, _ work: @escaping () -> Void) {
            delays.append(delay)
            work()
        }
    }

    private func runSweep(projects: [Project], api: FakeNotesAPI, clock: FakeClock,
                          maxConcurrentRequests: Int = ProjectNotesSweep.maxConcurrentRequests)
        -> ProjectNotesSweepResult {
        let runner = ProjectNotesSweepRunner(fetch: { api.fetch($0, $1) },
                                             schedule: { clock.schedule($0, $1) },
                                             maxConcurrentRequests: maxConcurrentRequests)
        var result: ProjectNotesSweepResult?
        runner.run(projects: projects) { result = $0 }
        guard let finished = result else {
            XCTFail("the sweep never reported back")
            return ProjectNotesSweepResult(entries: [], failedProjectIds: [])
        }
        return finished
    }

    /// The fix itself: 128 projects are no longer 128 simultaneous requests. This is the assertion
    /// that fails against the old fan-out — it would have found 128 requests outstanding, which is
    /// what the API answered with 429s.
    func testTheSweepKeepsOnlyAFewRequestsInFlight() {
        let projects = (1...128).map { project("p\($0)", name: "Project \($0)") }
        let api = DeferredNotesAPI()
        let clock = FakeClock()
        let runner = ProjectNotesSweepRunner(fetch: { api.fetch($0, $1) },
                                             schedule: { clock.schedule($0, $1) })
        var result: ProjectNotesSweepResult?
        runner.run(projects: projects) { result = $0 }

        XCTAssertEqual(api.inFlight, ProjectNotesSweep.maxConcurrentRequests,
                       "the sweep should be holding a handful of requests open, not all 128")
        XCTAssertNil(result, "nothing can be reported until the requests come back")

        var drains = 0
        while result == nil && drains < projects.count * 2 {
            api.drainAll { _ in ([], 200) }
            drains += 1
        }

        XCTAssertNotNil(result)
        XCTAssertEqual(api.askedProjectIds.count, projects.count, "every project is asked about")
        XCTAssertLessThanOrEqual(api.peakConcurrency, ProjectNotesSweep.maxConcurrentRequests)
        XCTAssertTrue(result?.isComplete == true)
    }

    /// Every project is accounted for however large the list is — no cap, no truncation, and the
    /// order the catalogue arrived in does not decide who gets left out.
    func testEveryProjectIsAccountedForRegardlessOfPosition() {
        let projects = (1...128).map { project("p\($0)", name: "Project \($0)") }
        let api = FakeNotesAPI()
        api.answer = { id, _ in ([self.projectNote("note-\(id)", projectId: id)], 200) }
        let result = runSweep(projects: projects, api: api, clock: FakeClock())
        XCTAssertEqual(result.entries.count, 128)
        XCTAssertEqual(Set(result.entries.map(\.projectId)), Set(projects.map(\.id)))
        XCTAssertTrue(result.isComplete)
    }

    /// The reported symptom, reproduced: a project rate-limited on its first try still ends up in the
    /// list. Before the fix its note was silently dropped.
    func testARateLimitedProjectIsRetriedAndItsNotesStillArrive() {
        let projects = [project("p1", name: "Alpha"), project("ux", name: "UX")]
        let api = FakeNotesAPI()
        api.answer = { id, attempt in
            guard id == "ux" else { return ([], 200) }
            return attempt == 1 ? (nil, 429) : ([self.projectNote("live-widget-test", projectId: "ux")], 200)
        }
        let clock = FakeClock()
        let result = runSweep(projects: projects, api: api, clock: clock)
        XCTAssertEqual(result.entries.map(\.id), ["live-widget-test"])
        XCTAssertEqual(result.entries.first?.projectName, "UX")
        XCTAssertTrue(result.isComplete)
        XCTAssertEqual(clock.delays, [ProjectNotesSweep.firstRetryDelaySeconds])
    }

    func testAProjectRateLimitedEveryTimeIsReportedAsFailedNotAsEmpty() {
        let projects = [project("ux", name: "UX")]
        let api = FakeNotesAPI()
        api.answer = { _, _ in (nil, 429) }
        let result = runSweep(projects: projects, api: api, clock: FakeClock())
        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertEqual(result.failedProjectIds, ["ux"])
        XCTAssertEqual(api.attemptsByProject["ux"], ProjectNotesSweep.maxAttempts)
    }

    func testASweepOfNoProjectsFinishesAndIsComplete() {
        let result = runSweep(projects: [], api: FakeNotesAPI(), clock: FakeClock())
        XCTAssertTrue(result.entries.isEmpty)
        XCTAssertTrue(result.isComplete)
    }

    // MARK: - The searchable dropdown's matching

    /// Typing a project's name and clicking a button straight away used to act on the previous
    /// selection, because a SwiftUI click never ends AppKit field editing. The control now resolves
    /// the text itself, so these are the rules that decide what the button sees.
    func testTypedTextResolvesToTheProjectTheUserIsLookingAt() {
        let options = [SearchableComboBoxField.Option(id: "p1", name: "UX"),
                       SearchableComboBoxField.Option(id: "p2", name: "NDIA Q3"),
                       SearchableComboBoxField.Option(id: "p3", name: "MRFF Mental Health grant application")]
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "UX", options: options), "p1")
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "ux", options: options), "p1",
                       "case does not matter")
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "  NDIA Q3  ", options: options), "p2",
                       "stray whitespace does not matter")
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "mrff", options: options), "p3",
                       "a unique fragment picks the one option still on screen")
        XCTAssertNil(SearchableComboBoxField.resolve(text: "", options: options),
                     "an empty field means no project, never the first one")
        XCTAssertNil(SearchableComboBoxField.resolve(text: "nothing like this", options: options))
    }

    /// An ambiguous fragment must not silently pick one of the candidates.
    func testAnAmbiguousFragmentResolvesToNothing() {
        let options = [SearchableComboBoxField.Option(id: "p1", name: "UX"),
                       SearchableComboBoxField.Option(id: "p2", name: "UX research")]
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "UX r", options: options), "p2",
                       "a fragment only one project still matches picks that project")
        XCTAssertNil(SearchableComboBoxField.resolve(text: "U", options: options),
                     "two projects still match, so nothing is chosen")
        XCTAssertEqual(SearchableComboBoxField.resolve(text: "UX", options: options), "p1",
                       "an exact name beats the fact that it is also a prefix of another")
    }

    func testTheMenuOffersTheClearedRowFirstThenEveryProject() {
        let options = [SearchableComboBoxField.Option(id: "p1", name: "UX"),
                       SearchableComboBoxField.Option(id: "p2", name: "NDIA Q3")]
        XCTAssertEqual(SearchableComboBoxField.titles(clearedOptionTitle: "All projects", options: options),
                       ["All projects", "UX", "NDIA Q3"])
        XCTAssertEqual(SearchableComboBoxField.displayName(for: "p2", options: options,
                                                           clearedOptionTitle: "All projects"), "NDIA Q3")
        XCTAssertEqual(SearchableComboBoxField.displayName(for: nil, options: options,
                                                           clearedOptionTitle: "All projects"), "All projects")
        XCTAssertEqual(SearchableComboBoxField.displayName(for: "gone", options: options,
                                                           clearedOptionTitle: "All projects"), "All projects",
                       "a selection whose project vanished falls back to the cleared row")
    }

    /// Creating a note needs a project actually chosen — there is no longer a preselected first one.
    func testCreatingANoteNeedsAProjectChosenDeliberately() {
        XCTAssertFalse(NewProjectNote.canCreate(projectId: nil))
        XCTAssertFalse(NewProjectNote.canCreate(projectId: "   "))
        XCTAssertTrue(NewProjectNote.canCreate(projectId: "p1"))
    }
}
