import XCTest
import AppKit
import SwiftUI
@testable import Focus_Bear

/// Project tags (`projects.metadata.tags`, backend#2412).
///
/// The rules here mirror the server's `normalizeProjectTags` and its DTO validator. That duplication
/// is deliberate — the client stores what the server will store, so a tag the user sees is exactly
/// what `GET /projects?tag=` will match — which is why it is worth pinning on this side too.
final class ProjectTagsTests: XCTestCase {

    // MARK: - Normalizing

    func testFoldsCaseSoOneHeadingIsOneTag() {
        // The report asked to tag a project "phd" while a `PhD` project already existed. Folding is
        // what stops those being two headings.
        XCTAssertEqual(ProjectTags.normalize(["PhD", "  phd  ", "PHD"]), ["phd"])
    }

    func testDropsBlanksAndKeepsFirstSeenOrder() {
        XCTAssertEqual(ProjectTags.normalize(["writing", "   ", "phd", "", "Writing"]), ["writing", "phd"])
    }

    func testNormalizingASingleBlankTagIsNil() {
        XCTAssertNil(ProjectTags.normalize("   "))
        XCTAssertNil(ProjectTags.normalize(""))
    }

    func testTruncatesToTheServersLength() {
        let long = String(repeating: "x", count: ProjectTags.maxLength + 10)
        XCTAssertEqual(ProjectTags.normalize(long)?.count, ProjectTags.maxLength)
    }

    func testCapsTheListAtTheServersMaximum() {
        let many = (0..<(ProjectTags.maxCount + 5)).map { "tag\($0)" }
        XCTAssertEqual(ProjectTags.normalize(many).count, ProjectTags.maxCount)
    }

    // MARK: - Adding and removing

    func testAddingReturnsTheNewList() {
        XCTAssertEqual(ProjectTags.adding("PhD", to: ["writing"]), ["writing", "phd"])
    }

    func testAddingSomethingAlreadyThereIsANoOp() {
        // Nil means "do not call the server" — a duplicate must not cost a request.
        XCTAssertNil(ProjectTags.adding("phd", to: ["phd"]))
        XCTAssertNil(ProjectTags.adding("  PHD ", to: ["phd"]))
    }

    func testAddingBlankIsANoOp() {
        XCTAssertNil(ProjectTags.adding("   ", to: ["phd"]))
    }

    func testAddingBeyondTheCapIsANoOp() {
        let full = (0..<ProjectTags.maxCount).map { "tag\($0)" }
        XCTAssertNil(ProjectTags.adding("onemore", to: full))
    }

    func testRemovingReturnsTheListWithoutIt() {
        XCTAssertEqual(ProjectTags.removing("phd", from: ["phd", "writing"]), ["writing"])
    }

    func testRemovingTheLastTagGivesAnEmptyList() {
        // Empty, not nil: the caller must still write `{"tags": []}` so the server clears them.
        XCTAssertEqual(ProjectTags.removing("phd", from: ["phd"]), [])
    }

    func testRemovingSomethingAbsentIsANoOp() {
        XCTAssertNil(ProjectTags.removing("missing", from: ["phd"]))
    }

    // MARK: - Suggestions

    func testKnownTagsAreDedupedAndSortedAcrossProjects() {
        let projects = [
            project(id: "1", tags: ["PhD", "writing"]),
            project(id: "2", tags: ["phd", "admin"]),
            project(id: "3", tags: nil),
        ]
        XCTAssertEqual(ProjectTags.known(in: projects), ["admin", "phd", "writing"])
    }

    func testKnownTagsOfAnUntaggedPortfolioIsEmpty() {
        XCTAssertEqual(ProjectTags.known(in: [project(id: "1", tags: nil)]), [])
    }

    // MARK: - The wire body

    func testBodySendsOnlyTheTagsKey() {
        // The partial-write rule: `metadata` is an open bag and other clients own keys this app cannot
        // read. The server shallow-merges, so sending `tags` alone leaves those keys alone. Anything
        // else in this dictionary would be a field the Mac is silently rewriting.
        let body = ProjectDetailStore.tagsBody(["PhD"])

        XCTAssertEqual(Array(body.keys), ["metadata"])
        let metadata = body["metadata"] as? [String: Any]
        XCTAssertEqual(metadata.map { Array($0.keys) }, ["tags"])
        XCTAssertEqual(metadata?["tags"] as? [String], ["phd"])
    }

    func testClearingTheLastTagSendsAnEmptyArrayNotNull() {
        // `metadata: null` would clear the *whole bag*, taking every other client's keys with it.
        let body = ProjectDetailStore.tagsBody([])
        let metadata = body["metadata"] as? [String: Any]

        XCTAssertNotNil(metadata)
        XCTAssertFalse(metadata?["tags"] is NSNull)
        XCTAssertEqual(metadata?["tags"] as? [String], [])
    }

    func testBodyNormalizesBeforeSending() {
        let body = ProjectDetailStore.tagsBody(["  Writing ", "writing", "PhD"])
        let metadata = body["metadata"] as? [String: Any]

        XCTAssertEqual(metadata?["tags"] as? [String], ["writing", "phd"])
    }

    // MARK: - Decoding

    func testDecodesTagsFromTheServerPayload() throws {
        let json = """
        {"id":"p1","name":"RCT","metadata":{"tags":["phd","writing"]}}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Project.self, from: json)

        XCTAssertEqual(decoded.tagList, ["phd", "writing"])
    }

    func testAProjectWithNoMetadataHasNoTags() throws {
        let json = #"{"id":"p1","name":"RCT"}"#.data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(Project.self, from: json).tagList, [])
    }

    func testMetadataHoldingOnlyAnotherClientsKeyDecodesWithNoTags() throws {
        // Unknown keys are not modelled, and must not make the payload undecodable.
        let json = #"{"id":"p1","name":"RCT","metadata":{"someOtherClientKey":{"a":1}}}"#.data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(Project.self, from: json).tagList, [])
    }

    func testNullMetadataDecodesWithNoTags() throws {
        let json = #"{"id":"p1","name":"RCT","metadata":null}"#.data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(Project.self, from: json).tagList, [])
    }

    // MARK: - Filtering the project list

    func testTagFilterKeepsOnlyProjectsCarryingIt() {
        let projects = [
            project(id: "1", name: "RCT", tags: ["phd"]),
            project(id: "2", name: "Sales", tags: ["work"]),
            project(id: "3", name: "Ethics", tags: ["phd", "writing"]),
        ]
        let filtered = ProjectListPresentation.alphabetical(projects, search: "", status: .active,
                                                           tag: "phd", displayName: { $0 })

        XCTAssertEqual(filtered.map(\.id), ["3", "1"])
    }

    func testTagFilterFoldsCaseLikeTheServer() {
        let projects = [project(id: "1", name: "RCT", tags: ["phd"])]
        let filtered = ProjectListPresentation.alphabetical(projects, search: "", status: .active,
                                                           tag: "  PhD ", displayName: { $0 })

        XCTAssertEqual(filtered.map(\.id), ["1"])
    }

    func testEmptyTagFiltersNothingOut() {
        let projects = [
            project(id: "1", name: "RCT", tags: ["phd"]),
            project(id: "2", name: "Sales", tags: nil),
        ]
        let filtered = ProjectListPresentation.alphabetical(projects, search: "", status: .active,
                                                           tag: "", displayName: { $0 })

        XCTAssertEqual(filtered.count, 2)
    }

    func testTagAndSearchCombineAsAnd() {
        // Both narrow: neither replaces the other, and clearing one must leave the other applied.
        let projects = [
            project(id: "1", name: "RCT writing", tags: ["phd"]),
            project(id: "2", name: "RCT admin", tags: ["work"]),
            project(id: "3", name: "Thesis writing", tags: ["phd"]),
        ]
        let both = ProjectListPresentation.alphabetical(projects, search: "RCT", status: .active,
                                                        tag: "phd", displayName: { $0 })
        XCTAssertEqual(both.map(\.id), ["1"])

        let tagOnly = ProjectListPresentation.alphabetical(projects, search: "", status: .active,
                                                           tag: "phd", displayName: { $0 })
        XCTAssertEqual(tagOnly.map(\.id), ["1", "3"])

        let searchOnly = ProjectListPresentation.alphabetical(projects, search: "RCT", status: .active,
                                                              tag: "", displayName: { $0 })
        XCTAssertEqual(searchOnly.map(\.id), ["2", "1"])
    }

    func testTagFilterStillRespectsLifecycleStatus() {
        var archived = project(id: "1", name: "Old", tags: ["phd"])
        archived.status = ProjectLifecycleStatus.archived.rawValue
        let filtered = ProjectListPresentation.alphabetical([archived], search: "", status: .active,
                                                            tag: "phd", displayName: { $0 })

        XCTAssertTrue(filtered.isEmpty)
    }

    func testAProjectWithNoTagsIsHiddenByAnyTagFilter() {
        let projects = [project(id: "1", name: "Untagged", tags: nil)]
        let filtered = ProjectListPresentation.alphabetical(projects, search: "", status: .active,
                                                            tag: "phd", displayName: { $0 })

        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - The picker applies when the text resolves, not on a timer and not only on a pick

    /// The behaviour the report is actually about: type the tag and the list narrows, with no second
    /// gesture. Verified against the reported case — the logs show `phd` resolving fine, so this is
    /// the whole difference between "no improvement" and working.
    ///
    /// The binding here counts writes rather than driving a real `ProjectsStore`: a write is what
    /// calls `applyTagFilter`, which fetches, and a test must not put a request on the wire.
    func testTypingATagInFullAppliesItWithoutAnySecondGesture() {
        let picker = tagPicker()
        defer { picker.teardown() }

        picker.type("phd")

        XCTAssertEqual(picker.applied, ["phd"], "typing the tag is the answer — no Return, no pick")
    }

    /// Enough letters to leave one tag standing is equally an answer, so the filter does not wait
    /// for the word to be finished.
    func testTypingEnoughToNarrowToOneTagAppliesIt() {
        let picker = tagPicker()
        defer { picker.teardown() }

        picker.type("ph")

        XCTAssertEqual(picker.applied, ["phd"])
    }

    /// The bound on fetches, and the reason immediate is affordable: the rest of the word resolves
    /// to the tag already applied, and `applyTagFilter` returns early on an unchanged tag.
    func testFinishingTheWordDoesNotApplyItTwice() {
        let picker = tagPicker()
        defer { picker.teardown() }

        picker.type("ph")
        picker.type("phd")

        XCTAssertEqual(picker.applied, ["phd"], "one write for one tag, however many keystrokes")
    }

    func testTypingPartOfATagAppliesNothingWhileItIsStillAmbiguous() {
        let picker = tagPicker()
        defer { picker.teardown() }

        picker.type("p")

        XCTAssertEqual(picker.applied, [], "text matching both tags is not an answer — it must not fetch")
    }

    /// The bug the per-keystroke version had: `resolve` answers nil while the text still matches more
    /// than one tag, and writing that nil reads as "all tags" — a full *unfiltered* fetch mid-word.
    func testTypingTextMatchingSeveralTagsDoesNotClearTheFilter() {
        let picker = tagPicker(chosen: "phd")
        defer { picker.teardown() }

        picker.type("p")

        XCTAssertEqual(picker.applied, [], "an ambiguous prefix must not be read as \"all tags\"")
    }

    /// Nor does text that matches nothing at all — a typo leaves the filter where it was.
    func testTypingTextMatchingNoTagLeavesTheFilterAlone() {
        let picker = tagPicker(chosen: "phd")
        defer { picker.teardown() }

        picker.type("zzz")

        XCTAssertEqual(picker.applied, [])
    }

    /// Emptying the box is the one nil that *is* an answer, so clearing stays instant.
    func testEmptyingTheFieldClearsTheFilterAtOnce() {
        let picker = tagPicker(chosen: "phd")
        defer { picker.teardown() }

        picker.type("")

        XCTAssertEqual(picker.applied, [ProjectTagsTests.clearedMarker])
    }

    func testChoosingATagFromTheListAppliesItExactlyOnce() {
        let picker = tagPicker()
        defer { picker.teardown() }

        picker.pick("phd")

        XCTAssertEqual(picker.applied, ["phd"])
    }

    func testReturnOnACompleteTagAppliesIt() {
        let picker = tagPicker()
        defer { picker.teardown() }

        picker.type("phd")
        picker.pressReturn()

        XCTAssertEqual(picker.applied, ["phd"])
    }

    /// Return is not a way round the resolution rule: pressing it on text that names several tags
    /// must not be read as "all tags" either.
    func testReturnOnAmbiguousTextAppliesNothingAndRestoresTheField() {
        let picker = tagPicker(chosen: "phd")
        defer { picker.teardown() }

        picker.type("p")
        picker.pressReturn()

        XCTAssertEqual(picker.applied, [])
        XCTAssertEqual(picker.box.stringValue, "phd")
    }

    /// The reported gesture: text in the box, focus moves away. Nothing is applied, and the box goes
    /// back to naming what *is* applied rather than leaving a tag on screen that is filtering nothing.
    func testClickingAwayFromPartTypedTextAppliesNothingAndRestoresTheField() {
        let picker = tagPicker()
        defer { picker.teardown() }

        picker.type("p")
        picker.blur()

        XCTAssertEqual(picker.applied, [])
        XCTAssertEqual(picker.box.stringValue, ProjectTagsTests.allTagsTitle)
    }

    /// The "All tags" row is an answer, not part-typed text — the one nil `.whenResolved` acts on
    /// besides an empty box.
    func testPickingTheAllTagsRowClearsTheFilter() {
        let picker = tagPicker(chosen: "phd")
        defer { picker.teardown() }

        picker.pick(ProjectTagsTests.allTagsTitle)

        XCTAssertEqual(picker.applied, [ProjectTagsTests.clearedMarker])
    }

    /// Every other combo box in the app — the create-task project picker, the focus-mode goal — is
    /// still `.asTyped`, because a SwiftUI button click never ends AppKit field editing and those
    /// bindings are read by a button. Changing the tag filter must not have changed them.
    func testTheOtherPickersStillResolveOnEveryKeystroke() {
        let picker = tagPicker(policy: .asTyped)
        defer { picker.teardown() }

        picker.type("phd")

        XCTAssertEqual(picker.applied, ["phd"])
    }

    /// The store side of "exactly once": re-choosing what is already chosen is not a change, so it
    /// does not reload. Safe to run against a real store precisely because it returns before fetching.
    func testApplyingTheTagAlreadyAppliedDoesNotReload() {
        let store = ProjectsStore(strings: ToDoStrings())
        let before = store.fetchGeneration

        store.applyTagFilter(nil)

        XCTAssertEqual(store.fetchGeneration, before)
        XCTAssertNil(store.tagFilterSelection)
    }

    // MARK: - Helpers

    private static let allTagsTitle = "All tags"
    /// What the recorder writes down for "the binding was set back to nil".
    private static let clearedMarker = "<cleared>"
    private static let tags = ["personal", "phd"]

    /// The real control and the real coordinator, in a real window, with the binding recorded.
    private final class TagPickerHarness {
        let box: searchableComboBox
        private let window: NSWindow
        private let coordinator: SearchableComboBoxField.Coordinator
        private let recorder: Recorder

        final class Recorder { var applied: [String] = [] }

        var applied: [String] { recorder.applied }

        init(policy: SearchableComboBoxField.CommitPolicy, chosen: String?) {
            let recorder = Recorder()
            self.recorder = recorder
            var selected = chosen
            let field = SearchableComboBoxField(
                options: ProjectTagsTests.tags.map { SearchableComboBoxField.Option(id: $0, name: $0) },
                selectedId: SwiftUI.Binding(get: { selected },
                                            set: { tag in
                                                selected = tag
                                                recorder.applied.append(tag ?? ProjectTagsTests.clearedMarker)
                                            }),
                clearedOptionTitle: ProjectTagsTests.allTagsTitle,
                commitPolicy: policy)
            coordinator = field.makeCoordinator()
            box = field.makeBox(coordinator: coordinator)
            box.frame = NSRect(x: 0, y: 0, width: 150, height: 24)
            window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 100),
                              styleMask: [.titled], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView?.addSubview(box)
            field.apply(to: box, coordinator: coordinator)
        }

        /// Replace whatever is in the box with `text`, the way retyping the field does. An empty
        /// `text` is a deletion rather than an insertion, so it goes through `deleteBackward` —
        /// inserting nothing is not guaranteed to tell the control the text changed.
        func type(_ text: String) {
            focus()
            guard let editor = box.currentEditor() as? NSTextView else { return }
            let all = NSRange(location: 0, length: editor.string.count)
            if text.isEmpty {
                editor.setSelectedRange(all)
                editor.deleteBackward(nil)
            } else {
                editor.insertText(text, replacementRange: all)
            }
            dearmPopUp()
        }

        /// A row taken out of the pop-up list: the list highlights it and the control sends its
        /// action, without editing ending.
        func pick(_ title: String) {
            guard let index = box.filterdItems.firstIndex(of: title) else { return XCTFail("no row \(title)") }
            box.selectItem(at: index)
            coordinator.comboCommitted(box)
            dearmPopUp()
        }

        func pressReturn() {
            dearmPopUp()
            guard let editor = box.currentEditor() as? NSTextView else { return }
            editor.insertNewline(nil)
        }

        func blur() {
            dearmPopUp()
            window.makeFirstResponder(nil)
        }

        func teardown() {
            dearmPopUp()
            window.makeFirstResponder(nil)
            window.orderOut(nil)
        }

        private func focus() {
            guard box.currentEditor() == nil else { return }
            window.makeFirstResponder(box)
        }

        /// Typing makes `expandPopUp` ask the cell to expand, and AppKit honours that by scheduling
        /// `NSComboBoxCell.popUp:` — a *modal event loop*. With no mouse to dismiss it, the first run
        /// loop that services the delayed perform blocks for minutes (sampled: eight of them). These
        /// tests never need the menu drawn, so the request is withdrawn before anything can spin.
        /// Nothing else here needs a run loop either: every callback under test is sent synchronously
        /// from `insertText` / `makeFirstResponder`.
        private func dearmPopUp() {
            box.cell?.setAccessibilityExpanded(false)
            guard let cell = box.cell else { return }
            NSObject.cancelPreviousPerformRequests(withTarget: cell)
        }
    }

    private func tagPicker(policy: SearchableComboBoxField.CommitPolicy = .whenResolved,
                           chosen: String? = nil) -> TagPickerHarness {
        TagPickerHarness(policy: policy, chosen: chosen)
    }

    private func project(id: String, name: String? = nil, tags: [String]?) -> Project {
        var project = Project(id: id, name: name ?? "Project \(id)")
        project.status = ProjectLifecycleStatus.active.rawValue
        project.metadata = tags.map { ProjectMetadata(tags: $0) }
        return project
    }
}
