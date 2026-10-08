//
//  BlockListComboBoxTests.swift
//  Focus BearTests
//
//  The menu's "Select Focus Mode" picker (BlockListComboBox in MenuView.swift).
//
//  Reported as: "it's not showing suggestions as I type" — the picker was a bare NSComboBox, whose
//  `completes` flag only does inline *prefix* completion inside the field editor and never opens the
//  menu, so typing "deep" against a list called "Work — deep" did nothing visible. It now runs on
//  `searchableComboBox`, which substring-filters and expands the menu on each keystroke.
//
//  What's testable without a window is the matching rule the picker resolves the typed text with;
//  the filtering and menu expansion belong to `searchableComboBox` itself.
//

@testable import Focus_Bear
import XCTest

@available(macOS 11.0, *)
final class BlockListComboBoxTests: XCTestCase {

    private let items = [
        MenuBlockList(id: "1", name: "Work — deep"),
        MenuBlockList(id: "2", name: "Meetings"),
        MenuBlockList(id: "3", name: "Deep clean"),
    ]

    private func resolve(_ text: String) -> String? {
        BlockListComboBox.resolve(text: text, items: items)
    }

    /// The reported case: "deep" appears mid-name in two lists, so it is ambiguous and must not pick
    /// one — but it is exactly the text the menu now narrows down for the user to choose from.
    func testAmbiguousSubstringResolvesToNothing() {
        XCTAssertNil(resolve("deep"))
    }

    func testSubstringMatchingExactlyOneListPicksIt() {
        XCTAssertEqual(resolve("clean"), "3")
        XCTAssertEqual(resolve("meet"), "2")
    }

    func testMatchingIsCaseInsensitive() {
        XCTAssertEqual(resolve("CLEAN"), "3")
        XCTAssertEqual(resolve("MeEtInGs"), "2")
    }

    /// An exact name wins even when it is also a substring of another list, so a list can always be
    /// chosen by typing its full name.
    func testExactNameBeatsAnAmbiguousSubstring() {
        let overlapping = [
            MenuBlockList(id: "a", name: "Deep"),
            MenuBlockList(id: "b", name: "Deep clean"),
        ]
        XCTAssertEqual(BlockListComboBox.resolve(text: "Deep", items: overlapping), "a")
        XCTAssertEqual(BlockListComboBox.resolve(text: "deep", items: overlapping), "a")
    }

    func testSurroundingWhitespaceIsIgnored() {
        XCTAssertEqual(resolve("  Meetings  "), "2")
    }

    func testEmptyTextResolvesToNothing() {
        XCTAssertNil(resolve(""))
        XCTAssertNil(resolve("   "))
    }

    func testTextMatchingNoListResolvesToNothing() {
        XCTAssertNil(resolve("gardening"))
    }

    func testNoListsResolvesToNothing() {
        XCTAssertNil(BlockListComboBox.resolve(text: "anything", items: []))
    }
}
