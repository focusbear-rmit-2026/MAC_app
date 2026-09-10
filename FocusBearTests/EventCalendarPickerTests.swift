//
//  EventCalendarPickerTests.swift
//  Focus BearTests
//
//  The Day Plan event editor's "Calendar" popup (EventCalendarPicker in CalendarManager.swift).
//  Regression cover for a report where an event from a read-only university calendar was shown — and
//  would have been saved — as belonging to an unrelated "Birthdays" calendar, because the popup listed
//  writable calendars only and silently sat on the first one when the lookup failed.
//

@testable import Focus_Bear
import XCTest

final class EventCalendarPickerTests: XCTestCase {

    private typealias Cal = CalendarManager.EventCalendar

    private func cal(_ id: String, _ title: String, source: String = "iCloud", writable: Bool = true) -> Cal {
        Cal(id: id, title: title, source: source, isWritable: writable)
    }

    // MARK: - Which calendars are listed

    func testWritableCalendarsAreListedUnchangedWhenTheEventLivesInOneOfThem() {
        let writable = [cal("birthdays", "Birthdays"), cal("personal", "Personal")]
        let choices = EventCalendarPicker.choices(writable: writable, owning: writable[1])
        XCTAssertEqual(choices, writable, "an event already in a writable calendar must not add a duplicate row")
    }

    func testReadOnlyOwningCalendarIsAppendedSoTheEditorCanShowIt() {
        let writable = [cal("birthdays", "Birthdays"), cal("personal", "Personal")]
        let rmit = cal("rmit", "s3255727@student.rmit.edu.au", source: "Subscribed", writable: false)
        let choices = EventCalendarPicker.choices(writable: writable, owning: rmit)
        XCTAssertEqual(choices.count, 3)
        XCTAssertEqual(choices.last, rmit)
    }

    func testNoOwningCalendarLeavesTheWritableListAlone() {
        let writable = [cal("personal", "Personal")]
        XCTAssertEqual(EventCalendarPicker.choices(writable: writable, owning: nil), writable)
    }

    // MARK: - Which one is preselected

    func testTheEventsOwnReadOnlyCalendarIsPreselectedRatherThanTheFirstRow() {
        let writable = [cal("birthdays", "Birthdays"), cal("personal", "Personal")]
        let rmit = cal("rmit", "RMIT", source: "Subscribed", writable: false)
        let choices = EventCalendarPicker.choices(writable: writable, owning: rmit)
        XCTAssertEqual(EventCalendarPicker.selectedIndex(in: choices, owningID: rmit.id), 2,
                       "the reported bug: this used to be nil, leaving the popup on 'Birthdays'")
    }

    func testWritableOwningCalendarIsPreselectedAtItsOwnIndex() {
        let writable = [cal("birthdays", "Birthdays"), cal("personal", "Personal")]
        XCTAssertEqual(EventCalendarPicker.selectedIndex(in: writable, owningID: "personal"), 1)
    }

    func testUnknownOwningCalendarSelectsNothingSoTheCallerWontWriteItBack() {
        let writable = [cal("birthdays", "Birthdays")]
        XCTAssertNil(EventCalendarPicker.selectedIndex(in: writable, owningID: nil))
        XCTAssertNil(EventCalendarPicker.selectedIndex(in: writable, owningID: "deleted-calendar"))
    }

    // MARK: - Menu labels

    func testDistinctTitlesAreShownPlain() {
        let choices = [cal("a", "Personal"), cal("b", "Work")]
        XCTAssertEqual(EventCalendarPicker.menuTitles(for: choices), ["Personal", "Work"])
    }

    func testDuplicateTitlesAcrossAccountsAreQualifiedWithTheAccount() {
        let choices = [cal("a", "Calendar", source: "jeremy@focusbear.io"),
                       cal("b", "Calendar", source: "s3255727@student.rmit.edu.au"),
                       cal("c", "Work", source: "jeremy@focusbear.io")]
        XCTAssertEqual(EventCalendarPicker.menuTitles(for: choices),
                       ["Calendar (jeremy@focusbear.io)",
                        "Calendar (s3255727@student.rmit.edu.au)",
                        "Work"])
    }

    func testDuplicateTitlesWithNoAccountNameStayPlainRatherThanGainingEmptyParentheses() {
        let choices = [cal("a", "Calendar", source: ""), cal("b", "Calendar", source: "")]
        XCTAssertEqual(EventCalendarPicker.menuTitles(for: choices), ["Calendar", "Calendar"])
    }
}
