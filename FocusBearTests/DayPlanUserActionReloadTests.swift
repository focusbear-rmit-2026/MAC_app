@testable import Focus_Bear
import XCTest

/// Two reports, one cause (2026-09-21_08-09-07 "clicking Move to 24th Sept does nothing" and
/// 2026-09-21_08-10-15 "cmd-click to select/de-select, nothing updates in the UI").
///
/// `reload()` deliberately does nothing while a name field is focused — clearing the stack would
/// tear the field editor down mid-keystroke. Both reported actions changed state and then asked for
/// a redraw that never came, so the state moved and the screen did not. Both were reported while a
/// row happened to be in edit mode, which is what made them look like two unrelated bugs.
final class DayPlanUserActionReloadTests: XCTestCase {

    @MainActor
    private func withPanel(_ body: (DayPlanTasksPanel, NSWindow) -> Void) {
        let previousMock = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore.shared
        let day = Calendar.current.date(from: DateComponents(year: 2060, month: 9, day: 21))!
        let previousTasks = store.allTasks(for: day)
        store.loadMock([DayPlanTask(title: "Post the Focus Button"),
                        DayPlanTask(title: "Answer the support queue")], for: day)
        let panel = DayPlanTasksPanel(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        let window = NSWindow(contentRect: panel.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = panel
        panel.date = day
        defer {
            window.makeFirstResponder(nil)
            window.close()
            store.loadMock(previousTasks, for: day)
            DayPlanTaskStore.mockMode = previousMock
        }
        body(panel, window)
    }

    @MainActor
    private func focusAName(in panel: DayPlanTasksPanel, window: NSWindow) -> NSTextField? {
        func find(_ view: NSView) -> NSTextField? {
            if let field = view as? NSTextField, field.identifier?.rawValue.hasPrefix("name:") == true,
               field.isEditable { return field }
            for sub in view.subviews { if let hit = find(sub) { return hit } }
            return nil
        }
        guard let field = find(panel) else { return nil }
        window.makeFirstResponder(field)
        return field
    }

    /// The behaviour that made both reports look like nothing happened.
    @MainActor
    func testAPlainReloadIsSwallowedWhileANameFieldIsBeingEdited() {
        withPanel { panel, window in
            guard let field = focusAName(in: panel, window: window) else {
                return XCTFail("no editable name field in the panel")
            }
            XCTAssertTrue(window.firstResponder is NSTextView, "the field editor should own focus")

            panel.reload()

            XCTAssertTrue(window.firstResponder is NSTextView,
                          "reload() must leave a typing user alone — this is the deferral, not the bug")
            XCTAssertEqual((window.firstResponder as? NSTextView)?.delegate as? NSTextField, field)
        }
    }

    /// What a click the user actually made has to do instead.
    @MainActor
    func testAUserActionReloadRebuildsAndCommitsTheOpenField() {
        withPanel { panel, window in
            guard focusAName(in: panel, window: window) != nil else {
                return XCTFail("no editable name field in the panel")
            }
            XCTAssertTrue(window.firstResponder is NSTextView)

            panel.reloadAfterUserAction()

            XCTAssertFalse(window.firstResponder is NSTextView,
                           "the edit is committed so the list can actually redraw")
        }
    }

    /// Nothing typed may be lost on the way: ending the edit commits through controlTextDidEndEditing.
    @MainActor
    func testTheOpenNameIsCommittedRatherThanDiscarded() {
        withPanel { panel, window in
            guard let field = focusAName(in: panel, window: window) else {
                return XCTFail("no editable name field in the panel")
            }
            let id = String(field.identifier!.rawValue.dropFirst("name:".count))
            field.stringValue = "Renamed while selecting"

            panel.reloadAfterUserAction()

            let saved = DayPlanTaskStore.shared.allTasks(for: panel.date).first { $0.id == id }
            XCTAssertEqual(saved?.title, "Renamed while selecting")
        }
    }

    // MARK: Changing the day commits what is being typed (report 2026-09-21_20-47-13)
    //
    // Navigating while a name field was focused left the panel showing the PREVIOUS day's rows
    // under the new day's header — and committing afterwards looked the task up in the new day's
    // store, did not find it, and dropped what had been typed.
    //
    // The AppKit half (giving up the field editor) is not reachable from a unit test. The decision
    // that gates it is, and it is the half that would misfire: commit on every assignment and the
    // cursor is yanked out mid-word by an ordinary refresh.

    func testOnlyARealDayChangeCountsAsADayChange() {
        let monday = DateComponents(calendar: .current, year: 2026, month: 9, day: 21, hour: 9).date!
        let mondayLater = DateComponents(calendar: .current, year: 2026, month: 9, day: 21, hour: 20).date!
        let tuesday = DateComponents(calendar: .current, year: 2026, month: 9, day: 22, hour: 1).date!

        XCTAssertFalse(DayPlanDateChange.isADifferentDay(from: monday, to: monday))
        XCTAssertFalse(DayPlanDateChange.isADifferentDay(from: monday, to: mondayLater),
                       "a refresh later the same day must not end editing")
        XCTAssertTrue(DayPlanDateChange.isADifferentDay(from: monday, to: tuesday))
        XCTAssertTrue(DayPlanDateChange.isADifferentDay(from: tuesday, to: monday),
                      "backwards counts too — the report navigated to a PREVIOUS day")
    }

    func testMidnightIsADayChangeEvenSecondsApart() {
        let calendar = Calendar.current
        let justBefore = DateComponents(calendar: calendar, year: 2026, month: 9, day: 21,
                                        hour: 23, minute: 59, second: 59).date!
        let justAfter = DateComponents(calendar: calendar, year: 2026, month: 9, day: 22,
                                       hour: 0, minute: 0, second: 1).date!
        XCTAssertTrue(DayPlanDateChange.isADifferentDay(from: justBefore, to: justAfter),
                      "two seconds apart, but the Day Plan has rolled over")
    }

    func testTheComparisonIsCalendarBasedNotAFixedInterval() {
        // 25 hours apart yet the same calendar day is impossible; 2 hours apart spanning midnight is
        // not. A naive "more than 24h" test would get both wrong.
        let calendar = Calendar.current
        let lateMonday = DateComponents(calendar: calendar, year: 2026, month: 9, day: 21, hour: 23).date!
        let earlyTuesday = DateComponents(calendar: calendar, year: 2026, month: 9, day: 22, hour: 1).date!
        XCTAssertTrue(DayPlanDateChange.isADifferentDay(from: lateMonday, to: earlyTuesday))
        XCTAssertLessThan(earlyTuesday.timeIntervalSince(lateMonday), 24 * 60 * 60)
    }

}
