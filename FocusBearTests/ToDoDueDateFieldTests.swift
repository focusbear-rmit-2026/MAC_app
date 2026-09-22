//
//  ToDoDueDateFieldTests.swift
//  Focus BearTests
//
//  The due-date field in a real window, because both bugs it answers are about AppKit focus rather
//  than about the date grammar:
//   - a date typed and then saved without ever leaving the field must reach the binding the editor's
//     draft is built from (report 2026-09-15_19-49-26 — "I changed the due date to 25th but … it
//     still showed 11th"). A click on SwiftUI content does not end AppKit's field editing, so a
//     value that waits for `controlTextDidEndEditing` is simply lost;
//   - the field opens showing the existing due date, not a placeholder (report 2026-09-15_19-50-02).
//

@testable import Focus_Bear
import AppKit
import SwiftUI
import XCTest

@MainActor
final class ToDoDueDateFieldTests: XCTestCase {

    /// Everything the harness reports back out of a SwiftUI value type.
    final class Recorder {
        /// The latest value written to the `day` binding — what the editor's draft would hold, and
        /// therefore what `ToDoUpsertBody` would send.
        var day: Date?
    }

    /// The editor's TOP card in miniature: the real due-date field, and a second text field to click
    /// into when a test needs focus to move somewhere.
    private struct Harness: View {
        let strings: ToDoStrings
        let recorder: Recorder
        @SwiftUI.State private var day: Date?
        @SwiftUI.State private var other = ""

        init(strings: ToDoStrings, recorder: Recorder, initialDay: Date?) {
            self.strings = strings
            self.recorder = recorder
            _day = SwiftUI.State(initialValue: initialDay)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                ToDoDueDateField(day: Binding(get: { day }, set: { day = $0; recorder.day = $0 }),
                                 strings: strings, isStacked: true)
                ReturnGuardTextField(text: $other, placeholder: "")
                Spacer()
            }
            .padding(16)
            .frame(width: 320, height: 240, alignment: .topLeading)
        }
    }

    private struct Fixture {
        let window: NSWindow
        let hosting: NSHostingView<Harness>
        /// The due-date field.
        let field: ReturnGuardTextField.GuardedTextField
        /// The neighbouring field, somewhere for focus to go.
        let otherField: ReturnGuardTextField.GuardedTextField
        let recorder: Recorder
    }

    private static let windowSize = NSRect(x: 0, y: 0, width: 320, height: 240)
    private static let runLoopSpin: TimeInterval = 0.05
    private static let eleventh = day(2026, 9, 11)
    /// Typed with its month and year so the test means the same day whatever today is.
    private static let typedDate = "25/9/2027"
    private static let typedDay = day(2027, 9, 25)
    private static let fixedNow = day(2026, 9, 15)

    private static func day(_ year: Int, _ month: Int, _ dayOfMonth: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: dayOfMonth))!
    }

    // MARK: Fixture

    private func makeFixture(initialDay: Date?) throws -> Fixture {
        let recorder = Recorder()
        recorder.day = initialDay
        let window = NSWindow(contentRect: ToDoDueDateFieldTests.windowSize, styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let hosting = NSHostingView(rootView: Harness(strings: ToDoStrings(), recorder: recorder,
                                                      initialDay: initialDay))
        hosting.frame = ToDoDueDateFieldTests.windowSize
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)
        hosting.layoutSubtreeIfNeeded()
        spin()
        let fields = ToDoDueDateFieldTests.guardedFields(in: hosting)
        XCTAssertEqual(fields.count, 2, "the harness renders the due-date field and one neighbour")
        let placeholder = ToDoStrings()[.dueDatePlaceholder]
        return Fixture(window: window, hosting: hosting,
                       field: try XCTUnwrap(fields.first { $0.placeholderString == placeholder }),
                       otherField: try XCTUnwrap(fields.first { $0.placeholderString != placeholder }),
                       recorder: recorder)
    }

    private static func guardedFields(in view: NSView) -> [ReturnGuardTextField.GuardedTextField] {
        if let field = view as? ReturnGuardTextField.GuardedTextField { return [field] }
        return view.subviews.flatMap { guardedFields(in: $0) }
    }

    /// Let SwiftUI flush the state changes AppKit just made.
    private func spin(_ seconds: TimeInterval = ToDoDueDateFieldTests.runLoopSpin) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// Types into the live field editor exactly as the user does — not `stringValue =`, which skips
    /// the change notification the binding rides on.
    private func type(_ text: String, into fixture: Fixture) throws {
        XCTAssertTrue(fixture.window.makeFirstResponder(fixture.field), "the field must take focus")
        let editor = try XCTUnwrap(fixture.field.currentEditor() as? NSTextView, "the field editor must exist")
        editor.selectAll(nil)
        if text.isEmpty {
            editor.deleteBackward(nil)
        } else {
            editor.insertText(text, replacementRange: editor.selectedRange())
        }
        spin()
    }

    /// A real left click on an AppKit view, delivered through the window the way AppKit does.
    private func click(_ target: NSView, in fixture: Fixture) {
        ToDoDueDateFieldTests.click(target, in: fixture.window)
        spin()
    }

    /// An AppKit text field runs its own mouse-tracking loop from `mouseDown`, so the release has to
    /// be queued *before* the press is delivered or that loop never sees it and the test hangs.
    static func click(_ target: NSView, in window: NSWindow) {
        let point = target.convert(NSPoint(x: target.bounds.midX, y: target.bounds.midY), to: nil)
        func event(_ type: NSEvent.EventType) -> NSEvent? {
            NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                               timestamp: ProcessInfo.processInfo.systemUptime,
                               windowNumber: window.windowNumber, context: nil,
                               eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0)
        }
        guard let down = event(.leftMouseDown), let up = event(.leftMouseUp) else { return }
        NSApp.postEvent(up, atStart: false)
        window.sendEvent(down)
    }

    private func isEditing(_ fixture: Fixture) -> Bool {
        guard let editor = fixture.field.currentEditor() else { return false }
        return fixture.window.firstResponder === editor
    }

    // MARK: A typed date must not wait for the field to lose focus

    /// The reported bug. Clicking the editor's Save button leaves the field editor first responder —
    /// SwiftUI buttons don't end AppKit editing — so anything that waits for `controlTextDidEndEditing`
    /// is never written, and the old date is what the PUT carries.
    func testATypedDateReachesTheBindingWhileTheFieldStillHasFocus() throws {
        let fixture = try makeFixture(initialDay: ToDoDueDateFieldTests.eleventh)
        defer { fixture.window.orderOut(nil) }
        try type(ToDoDueDateFieldTests.typedDate, into: fixture)
        XCTAssertTrue(isEditing(fixture), "this is the whole point: focus never left the field")
        XCTAssertEqual(fixture.recorder.day, ToDoDueDateFieldTests.typedDay,
                       "Save clicked right now must send the 25th, not the 11th")
    }

    /// The control for the test above: a click that *does* move focus is delivered by this harness,
    /// and commits too. Without this, "focus never left the field" could just mean "no event arrived".
    func testClickingIntoAnotherFieldAlsoCommitsTheTypedDate() throws {
        let fixture = try makeFixture(initialDay: ToDoDueDateFieldTests.eleventh)
        defer { fixture.window.orderOut(nil) }
        try type(ToDoDueDateFieldTests.typedDate, into: fixture)
        click(fixture.otherField, in: fixture)
        XCTAssertFalse(isEditing(fixture), "clicking an AppKit text field does move focus")
        XCTAssertEqual(fixture.recorder.day, ToDoDueDateFieldTests.typedDay)
    }

    /// Return keeps working, and rewrites the shorthand as the day it resolved to.
    func testReturnCommitsAndSpellsOutTheResolvedDay() throws {
        let fixture = try makeFixture(initialDay: ToDoDueDateFieldTests.eleventh)
        defer { fixture.window.orderOut(nil) }
        try type(ToDoDueDateFieldTests.typedDate, into: fixture)
        let editor = try XCTUnwrap(fixture.field.currentEditor() as? NSTextView)
        XCTAssertTrue(fixture.field.delegate?.control?(fixture.field, textView: editor,
                                                       doCommandBy: #selector(NSResponder.insertNewline(_:))) == true)
        spin()
        XCTAssertEqual(fixture.recorder.day, ToDoDueDateFieldTests.typedDay)
        XCTAssertEqual(fixture.field.stringValue, ToDoDates.dayMonthYear(ToDoDueDateFieldTests.typedDay))
    }

    // MARK: The field shows the date, not a placeholder

    func testTheFieldOpensOnTheExistingDueDateInsteadOfThePlaceholder() throws {
        let fixture = try makeFixture(initialDay: ToDoDueDateFieldTests.eleventh)
        defer { fixture.window.orderOut(nil) }
        XCTAssertEqual(fixture.field.stringValue, ToDoDates.dayMonthYear(ToDoDueDateFieldTests.eleventh),
                       "reopening the editor shows the saved date as the field's value")
        XCTAssertEqual(fixture.field.placeholderString, ToDoStrings()[.dueDatePlaceholder],
                       "the placeholder is still there for an empty field — it is just not what shows")
    }

    func testATaskWithoutADueDateStillShowsThePlaceholder() throws {
        let fixture = try makeFixture(initialDay: nil)
        defer { fixture.window.orderOut(nil) }
        XCTAssertEqual(fixture.field.stringValue, "")
    }

    /// Deleting the date is the only "no due date" gesture this control offers, so an emptied field
    /// clears the day. It cannot happen by accident: an untouched field carries the date as its text.
    func testEmptyingTheFieldClearsTheDueDate() throws {
        let fixture = try makeFixture(initialDay: ToDoDueDateFieldTests.eleventh)
        defer { fixture.window.orderOut(nil) }
        try type("", into: fixture)
        XCTAssertNil(fixture.recorder.day)
    }

    /// The report itself: "2y" typed into the real field must reach the binding as two years out,
    /// with no Return and no click anywhere.
    func testTypingTwoYearsSchedulesTwoYearsOut() throws {
        let fixture = try makeFixture(initialDay: ToDoDueDateFieldTests.eleventh)
        defer { fixture.window.orderOut(nil) }
        try type("2y", into: fixture)
        let expected = Calendar.current.date(byAdding: .year, value: 2,
                                             to: Calendar.current.startOfDay(for: Date()))
        XCTAssertEqual(fixture.recorder.day, expected)
    }

    // MARK: Re-seeding (the calendar picker writes `day`, not the text)

    func testADayChosenElsewhereReplacesTheTypedText() {
        XCTAssertEqual(ToDoDueDateFieldText.reseed(current: "25", day: ToDoDueDateFieldTests.day(2026, 9, 30),
                                                  now: ToDoDueDateFieldTests.fixedNow),
                       ToDoDates.dayMonthYear(ToDoDueDateFieldTests.day(2026, 9, 30)),
                       "picking 30 Sep in the calendar must not leave '25' behind to overwrite it")
    }

    func testTypingKeepsItsOwnTextWhileItAlreadyMeansThatDay() {
        XCTAssertNil(ToDoDueDateFieldText.reseed(current: "25", day: ToDoDueDateFieldTests.day(2026, 9, 25),
                                                 now: ToDoDueDateFieldTests.fixedNow),
                     "rewriting '25' to '25 Sep 2026' mid-word would move the caret under the user")
    }

    func testClearingTheDayEmptiesTheText() {
        XCTAssertEqual(ToDoDueDateFieldText.reseed(current: "25 Sep 2026", day: nil), "")
    }

    // MARK: The text the field writes must be text the grammar reads back

    /// Four years a day at a time, so the format cannot drift into something the grammar drops on
    /// the next save. The span matters: "2y" makes a date two years out an ordinary thing to type
    /// (report 2026-09-15_20-52-05), and a year-less rendering of a day already past in the current
    /// year would re-read as next year.
    func testEveryRenderedDayParsesBackToItself() {
        let calendar = Calendar.current
        let start = ToDoDueDateFieldTests.day(2026, 9, 15)
        for offset in 0..<1_500 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            let rendered = ToDoDueDateFieldText.text(for: date)
            XCTAssertEqual(ToDoDueDateParser.parse(rendered, now: start), date,
                           "'\(rendered)' must read back as the day it came from")
        }
    }

    func testTheFieldsOwnTextAlwaysCarriesTheYearEvenForThisYear() {
        let thisYear = ToDoDueDateFieldTests.day(2026, 1, 4)
        let rendered = ToDoDueDateFieldText.text(for: thisYear)
        XCTAssertTrue(rendered.contains("2026"),
                      "dropping the year here would re-read '4 Jan' as next January and move the task")
        XCTAssertEqual(ToDoDueDateParser.parse(rendered, now: ToDoDueDateFieldTests.day(2026, 9, 15)), thisYear)
    }

    func testFarFutureDatesSurviveTheRoundTrip() {
        let now = ToDoDueDateFieldTests.day(2026, 9, 15)
        for date in [ToDoDueDateFieldTests.day(2027, 2, 28), ToDoDueDateFieldTests.day(2028, 4, 4),
                     ToDoDueDateFieldTests.day(2028, 2, 29), ToDoDueDateFieldTests.day(2029, 12, 31)] {
            let rendered = ToDoDueDateFieldText.text(for: date)
            XCTAssertEqual(ToDoDueDateParser.parse(rendered, now: now), date, "'\(rendered)'")
        }
    }

    func testTheWeekdayFormatIsNotUsedBecauseTheGrammarCannotReadItBack() {
        let now = ToDoDueDateFieldTests.day(2026, 9, 15)
        for date in [ToDoDueDateFieldTests.eleventh, ToDoDueDateFieldTests.day(2028, 4, 4)] {
            let rendered = ToDoDates.weekdayDayMonth(date, now: now)
            XCTAssertNil(ToDoDueDateParser.parse(rendered, now: now),
                         "'\(rendered)' is the preview line's format, not the field's — seeding it would drop the date")
        }
    }
}

/// Text fields whose Return action *creates* something. SwiftUI's `TextField(_:text:onCommit:)` calls
/// `onCommit` when the field merely loses focus, so on macOS "type a name, click the next box" ran the
/// Return action: the New Project sheet created the project and dismissed itself the moment the user
/// clicked the due-date box (report 2026-09-15_20-13-26 — `POST /projects` at 20:10:35, five seconds
/// before the screenshot of the reopened sheet). These screens use `ReturnGuardTextField` instead,
/// which separates Return (`onCommit`) from losing focus (`onEndEditing`).
@MainActor
final class ToDoFieldCommitTests: XCTestCase {

    private final class Counts {
        var commits = 0
        var endedEditing = 0
    }

    private struct TwoFields: View {
        let counts: Counts
        @SwiftUI.State private var first = ""
        @SwiftUI.State private var second = ""

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                ReturnGuardTextField(text: $first, placeholder: TwoFields.firstPlaceholder,
                                     onCommit: { counts.commits += 1 },
                                     onEndEditing: { counts.endedEditing += 1 })
                ReturnGuardTextField(text: $second, placeholder: "second")
                Spacer()
            }
            .padding(16)
            .frame(width: 320, height: 200, alignment: .topLeading)
        }

        static let firstPlaceholder = "first"
    }

    private static let windowSize = NSRect(x: 0, y: 0, width: 320, height: 200)

    private func spin() { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }

    private static func guardedFields(in view: NSView) -> [ReturnGuardTextField.GuardedTextField] {
        if let field = view as? ReturnGuardTextField.GuardedTextField { return [field] }
        return view.subviews.flatMap { guardedFields(in: $0) }
    }

    private static func textFields(in view: NSView) -> [NSTextField] {
        if let field = view as? NSTextField { return [field] }
        return view.subviews.flatMap { textFields(in: $0) }
    }

    private func click(_ target: NSView, in window: NSWindow) {
        ToDoDueDateFieldTests.click(target, in: window)
        spin()
    }

    private func window<Content: View>(hosting content: Content) -> (NSWindow, NSHostingView<Content>) {
        let window = NSWindow(contentRect: ToDoFieldCommitTests.windowSize, styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let hosting = NSHostingView(rootView: content)
        hosting.frame = ToDoFieldCommitTests.windowSize
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)
        hosting.layoutSubtreeIfNeeded()
        spin()
        return (window, hosting)
    }

    func testClickingIntoTheNextFieldEndsEditingWithoutRunningTheReturnAction() throws {
        let counts = Counts()
        let (host, hosting) = window(hosting: TwoFields(counts: counts))
        defer { host.orderOut(nil) }
        let fields = ToDoFieldCommitTests.guardedFields(in: hosting)
        XCTAssertEqual(fields.count, 2)
        let first = try XCTUnwrap(fields.first { $0.placeholderString == TwoFields.firstPlaceholder })
        let second = try XCTUnwrap(fields.first { $0.placeholderString != TwoFields.firstPlaceholder })
        XCTAssertTrue(host.makeFirstResponder(first))
        try XCTUnwrap(first.currentEditor() as? NSTextView).insertText("Ship the thing", replacementRange: NSRange(location: 0, length: 0))
        spin()
        click(second, in: host)
        XCTAssertEqual(counts.endedEditing, 1, "focus did move on")
        XCTAssertEqual(counts.commits, 0, "clicking the next box must not run the Return action")
    }

    func testReturnStillRunsTheReturnAction() throws {
        let counts = Counts()
        let (host, hosting) = window(hosting: TwoFields(counts: counts))
        defer { host.orderOut(nil) }
        let first = try XCTUnwrap(ToDoFieldCommitTests.guardedFields(in: hosting)
            .first { $0.placeholderString == TwoFields.firstPlaceholder })
        XCTAssertTrue(host.makeFirstResponder(first))
        let editor = try XCTUnwrap(first.currentEditor() as? NSTextView)
        editor.insertText("Ship the thing", replacementRange: NSRange(location: 0, length: 0))
        spin()
        XCTAssertTrue(first.delegate?.control?(first, textView: editor,
                                               doCommandBy: #selector(NSResponder.insertNewline(_:))) == true)
        XCTAssertEqual(counts.commits, 1)
    }

    // MARK: - The Day Plan's "Shorten this habit" sheet (report 2026-09-15_20-29-02, follow-up)

    /// Records what the sheet was asked to apply, without needing to reach into its `@State`.
    private final class PickedLengths {
        var seconds: [Int] = []
    }

    private static let shortenHabitRealSeconds = 30 * 60

    @available(macOS 11.0, *)
    private func shortenSheet(_ picked: PickedLengths) -> DayPlanShortenHabitView {
        DayPlanShortenHabitView(habitTitle: "Run", copy: .habit(dayLabel: "Wed 16 Sep"),
                                actualSeconds: ToDoFieldCommitTests.shortenHabitRealSeconds,
                                currentSeconds: nil,
                                onPick: { picked.seconds.append($0) },
                                onFullLength: {}, onCancel: {})
    }

    func testTheShortenHabitSheetUsesAGuardedFieldOnly() throws {
        guard #available(macOS 11.0, *) else { throw XCTSkip("SwiftUI sheet needs macOS 11") }
        let (host, hosting) = window(hosting: shortenSheet(PickedLengths()))
        defer { host.orderOut(nil) }
        let guarded = ToDoFieldCommitTests.guardedFields(in: hosting)
        let editable = ToDoFieldCommitTests.textFields(in: hosting).filter { $0.isEditable }
        XCTAssertEqual(editable.count, guarded.count,
                       "an editable box here that is not a ReturnGuardTextField acts on blur")
        XCTAssertEqual(guarded.count, 1)
        XCTAssertEqual(guarded.first?.placeholderString, ScheduleText.habitShortenTypePlaceholder)
    }

    /// The ordering that has bitten five times today: the value must reach the confirming action
    /// straight from the field, without waiting for focus to leave it first.
    func testATypedLengthIsAppliedWithoutTheFieldLosingFocusFirst() throws {
        guard #available(macOS 11.0, *) else { throw XCTSkip("SwiftUI sheet needs macOS 11") }
        let picked = PickedLengths()
        let (host, hosting) = window(hosting: shortenSheet(picked))
        defer { host.orderOut(nil) }
        let field = try XCTUnwrap(ToDoFieldCommitTests.guardedFields(in: hosting).first)
        XCTAssertTrue(host.makeFirstResponder(field))
        let editor = try XCTUnwrap(field.currentEditor() as? NSTextView)
        editor.insertText("12", replacementRange: NSRange(location: 0, length: 0))
        spin()
        // Confirm while the field still has focus — no end-editing has happened.
        XCTAssertTrue(field.delegate?.control?(field, textView: editor,
                                               doCommandBy: #selector(NSResponder.insertNewline(_:))) == true)
        spin()
        XCTAssertEqual(picked.seconds, [12 * 60], "the typed 12 minutes reached the action")
    }

    /// The other half of the same rule: losing focus must not apply anything by itself, or clicking a
    /// preset would silently commit whatever was half-typed in the box.
    func testLosingFocusOnTheLengthFieldAppliesNothing() throws {
        guard #available(macOS 11.0, *) else { throw XCTSkip("SwiftUI sheet needs macOS 11") }
        let picked = PickedLengths()
        let (host, hosting) = window(hosting: shortenSheet(picked))
        defer { host.orderOut(nil) }
        let field = try XCTUnwrap(ToDoFieldCommitTests.guardedFields(in: hosting).first)
        XCTAssertTrue(host.makeFirstResponder(field))
        let editor = try XCTUnwrap(field.currentEditor() as? NSTextView)
        editor.insertText("12", replacementRange: NSRange(location: 0, length: 0))
        spin()
        XCTAssertTrue(host.makeFirstResponder(nil))
        spin()
        XCTAssertEqual(picked.seconds, [], "blur reports, it does not apply")
    }

    func testATypedLengthLongerThanTheHabitAppliesNothing() throws {
        guard #available(macOS 11.0, *) else { throw XCTSkip("SwiftUI sheet needs macOS 11") }
        let picked = PickedLengths()
        let (host, hosting) = window(hosting: shortenSheet(picked))
        defer { host.orderOut(nil) }
        let field = try XCTUnwrap(ToDoFieldCommitTests.guardedFields(in: hosting).first)
        XCTAssertTrue(host.makeFirstResponder(field))
        let editor = try XCTUnwrap(field.currentEditor() as? NSTextView)
        // Four hours, on a thirty-minute habit. It must never become a four-minute trim, and it must
        // never lengthen the habit either.
        editor.insertText("4h", replacementRange: NSRange(location: 0, length: 0))
        spin()
        XCTAssertTrue(field.delegate?.control?(field, textView: editor,
                                               doCommandBy: #selector(NSResponder.insertNewline(_:))) == true)
        spin()
        XCTAssertEqual(picked.seconds, [], "refused rather than applied")
    }

    /// The reported screen itself: both of its text boxes must be the guarded control, so neither the
    /// name nor the due date can create the project by losing focus.
    func testTheNewProjectSheetUsesGuardedFieldsOnly() {
        let strings = ToDoStrings()
        let store = ProjectsStore(strings: strings)
        let (host, hosting) = window(hosting: ProjectCreateSheet(store: store))
        defer { host.orderOut(nil) }
        let guarded = ToDoFieldCommitTests.guardedFields(in: hosting)
        let all = ToDoFieldCommitTests.textFields(in: hosting).filter { $0.isEditable }
        XCTAssertEqual(all.count, guarded.count,
                       "an editable box here that is not a ReturnGuardTextField commits on blur")
        XCTAssertTrue(guarded.contains { $0.placeholderString == strings[.projectNamePlaceholder] },
                      "the project name box is the one that created the project on blur")
        XCTAssertTrue(guarded.contains { $0.placeholderString == strings[.dueDatePlaceholder] })
    }
}
