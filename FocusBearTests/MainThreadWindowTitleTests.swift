import XCTest
import Cocoa
@testable import Focus_Bear

/// The window-title read used to happen on the main thread, once per 1s allowed-app tick and again on
/// every app switch, and it blocked in `mach_msg` waiting on the target app's Accessibility server
/// (Sentry FOCUS-BEAR-MACOS-1AD / -1EH). These tests pin the property that fixed it: reading a title
/// from the calling thread must not wait for Accessibility.
final class MainThreadWindowTitleTests: XCTestCase {

    /// Apps to read titles for. Real running applications, because the cost being measured is real
    /// cross-process Accessibility traffic — a stub would prove nothing about it.
    private var runningApps: [NSRunningApplication] {
        Array(NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }.prefix(10))
    }

    /// The budget below is chosen to sit far under what the old synchronous implementation could
    /// achieve, and far over what a cache read needs, so the test says something real without being a
    /// stopwatch on a loaded machine. One blocking `AXUIElementCopyAttributeValue` measured 1.5–182 ms
    /// against live apps, so 200 reads the old way could not have come in under a second; a dictionary
    /// lookup under a lock is microseconds.
    private static let readBudgetSeconds: TimeInterval = 0.25

    func testReadingTitlesNeverBlocksTheCallingThread() throws {
        let apps = runningApps
        try XCTSkipIf(apps.isEmpty, "No regular applications running to read titles from")

        let started = Date()
        for _ in 0..<20 {
            for app in apps { _ = claudeTitleReader.shared.titles(for: app) }
        }
        let elapsed = Date().timeIntervalSince(started)

        XCTAssertLessThan(elapsed, Self.readBudgetSeconds,
                          "\(20 * apps.count) title reads took \(elapsed)s on the calling thread; they must not wait on Accessibility")
    }

    /// A caller that keys a relevance decision on the title must not be told the first read has settled
    /// before it has, or it would key on a missing title and then re-key a tick later when it arrived —
    /// firing two AI checks where there used to be one.
    func testFirstReadIsNotReportedSettledUntilItCompletes() throws {
        let app = try XCTUnwrap(runningApps.first, "No regular applications running")

        // Whether this specific app has been read before depends on what else touched the reader, so
        // the assertion is on the invariant that holds either way: once settled, it stays settled, and
        // a settled reader answers immediately.
        let deadline = Date().addingTimeInterval(5)
        while !claudeTitleReader.shared.hasSettledTitles(for: app), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        XCTAssertTrue(claudeTitleReader.shared.hasSettledTitles(for: app),
                      "The first read must resolve (or time out) so the allowed-app check is never deferred forever")

        let started = Date()
        XCTAssertTrue(claudeTitleReader.shared.hasSettledTitles(for: app))
        XCTAssertLessThan(Date().timeIntervalSince(started), Self.readBudgetSeconds,
                          "A settled reader must answer from cache without another Accessibility round trip")
    }

    /// Reading from many threads at once must not trip over the background refresh writing the cache.
    func testConcurrentReadsAreSafe() throws {
        let apps = runningApps
        try XCTSkipIf(apps.isEmpty, "No regular applications running to read titles from")

        let finished = expectation(description: "concurrent reads complete")
        finished.expectedFulfillmentCount = 8
        for _ in 0..<8 {
            DispatchQueue.global().async {
                for _ in 0..<50 {
                    for app in apps {
                        _ = claudeTitleReader.shared.titles(for: app)
                        _ = claudeTitleReader.shared.hasSettledTitles(for: app)
                    }
                }
                finished.fulfill()
            }
        }
        wait(for: [finished], timeout: 30)
    }

    // MARK: Which text is the conversation title (report 2026-09-22_16-01-02)
    //
    // It used to be `texts[3]` — the fourth static text found depth-first. With chats pinned in the
    // sidebar that landed on "Shui cao Chinese translation", a conversation the user was not in, and
    // the relevance check then blocked their real work for being about Chinese translation.
    //
    // The fixture below is the reported window: a sidebar of chrome and pinned chats on the left, the
    // active conversation's header at the top of the content pane.

    private typealias Picker = claudeTitleReader.ChatTitlePicker
    private typealias Placed = claudeTitleReader.PlacedText

    private static let window = CGRect(x: 0, y: 0, width: 1320, height: 625)

    /// x < ~449 is sidebar for this window; the content pane starts around 478 in the screenshot.
    private static let reportedWindowTexts: [Placed] = [
        Placed(text: "Home", frame: CGRect(x: 40, y: 64, width: 60, height: 18)),
        Placed(text: "Code", frame: CGRect(x: 330, y: 64, width: 60, height: 18)),
        Placed(text: "New", frame: CGRect(x: 52, y: 107, width: 40, height: 18)),
        Placed(text: "More", frame: CGRect(x: 52, y: 138, width: 44, height: 18)),
        Placed(text: "Pinned", frame: CGRect(x: 28, y: 190, width: 50, height: 16)),
        Placed(text: "Anki", frame: CGRect(x: 52, y: 218, width: 40, height: 18)),
        Placed(text: "Example request", frame: CGRect(x: 70, y: 247, width: 130, height: 18)),
        Placed(text: "Hanging beam weight distribution on joists", frame: CGRect(x: 70, y: 276, width: 290, height: 18)),
        Placed(text: "Shui cao Chinese translation", frame: CGRect(x: 70, y: 305, width: 200, height: 18)),
        // The active conversation, in the content pane.
        Placed(text: "Sharing library files in ChatGPT business workspace",
               frame: CGRect(x: 478, y: 25, width: 380, height: 20)),
        Placed(text: "in my personal account I have the option but not in business.",
               frame: CGRect(x: 678, y: 328, width: 560, height: 18)),
    ]

    func testTheReportedWindowResolvesToTheActiveConversation() {
        XCTAssertEqual(Picker.pick(from: Self.reportedWindowTexts, windowFrame: Self.window),
                       "Sharing library files in ChatGPT business workspace")
    }

    func testAPinnedSidebarChatIsNeverMistakenForTheActiveOne() {
        let picked = Picker.pick(from: Self.reportedWindowTexts, windowFrame: Self.window)
        XCTAssertNotEqual(picked, "Shui cao Chinese translation",
                          "this is what the old positional read returned")
        XCTAssertNotEqual(picked, "Hanging beam weight distribution on joists")
    }

    /// The old rule's actual failure mode: pinning one more chat shifts every index by one. Geometry
    /// does not move, so the answer must not change.
    func testPinningMoreChatsDoesNotChangeTheAnswer() {
        var texts = Self.reportedWindowTexts
        for offset in 1...6 {
            texts.insert(Placed(text: "Pinned chat number \(offset)",
                                frame: CGRect(x: 70, y: 200 + Double(offset), width: 200, height: 18)),
                         at: 2)
        }
        XCTAssertEqual(Picker.pick(from: texts, windowFrame: Self.window),
                       "Sharing library files in ChatGPT business workspace")
    }

    /// Tree order is not visual order — a depth-first walk can reach body text before the header,
    /// which is precisely the assumption the old `texts[3]` rule rested on. Geometry must decide.
    func testTreeOrderDoesNotDecide() {
        let outOfOrder: [Placed] = [
            Placed(text: "in my personal account I have the option but not in business.",
                   frame: CGRect(x: 678, y: 328, width: 560, height: 18)),
            Placed(text: "Thought for 5s", frame: CGRect(x: 510, y: 420, width: 100, height: 18)),
            Placed(text: "Sharing library files in ChatGPT business workspace",
                   frame: CGRect(x: 478, y: 25, width: 380, height: 20)),
        ]
        XCTAssertEqual(Picker.pick(from: outOfOrder, windowFrame: Self.window),
                       "Sharing library files in ChatGPT business workspace",
                       "the header is last in the array and still has to win")
    }

    func testACollapsedSidebarStillResolvesTheHeader() {
        // Nothing on the left at all; the topmost content text is still the title.
        let texts = Self.reportedWindowTexts.filter { $0.frame.minX >= 478 }
        XCTAssertEqual(Picker.pick(from: texts, windowFrame: Self.window),
                       "Sharing library files in ChatGPT business workspace")
    }

    func testShortChromeIsNotATitle() {
        let texts = [
            Placed(text: "New", frame: CGRect(x: 600, y: 10, width: 30, height: 18)),
            Placed(text: "A real conversation title", frame: CGRect(x: 600, y: 40, width: 300, height: 18)),
        ]
        XCTAssertEqual(Picker.pick(from: texts, windowFrame: Self.window), "A real conversation title",
                       "a two-character button above the header must not win on being topmost")
    }

    func testNothingInTheContentPaneYieldsNoTitle() {
        let sidebarOnly = Self.reportedWindowTexts.filter { $0.frame.minX < 449 }
        XCTAssertNil(Picker.pick(from: sidebarOnly, windowFrame: Self.window),
                     "no title is better than a sidebar entry — that is the whole bug")
        XCTAssertNil(Picker.pick(from: [], windowFrame: Self.window))
        XCTAssertNil(Picker.pick(from: Self.reportedWindowTexts, windowFrame: .zero),
                     "a zero-width window tells us nothing about which column is which")
    }

}

/// The report list worked out each report's area inside a SwiftUI `body` getter, so a queue of a few
/// hundred reports re-ran tens of thousands of substring searches on every render
/// (Sentry FOCUS-BEAR-MACOS-1G6). The answer is memoised now; these pin that memoising it did not
/// change what it answers.
final class LocalReportAreaCachingTests: XCTestCase {

    func testRepeatedDetectionIsStable() {
        for _ in 0..<3 {
            XCTAssertEqual(LocalReportArea.detect(title: "Day plan free time is wrong", notes: nil), .dayPlan)
            XCTAssertEqual(LocalReportArea.detect(title: "Focus session UI looks broken", notes: nil), .focusSession)
            XCTAssertEqual(LocalReportArea.detect(title: "Something entirely new", notes: nil), .other)
        }
    }

    /// The memo is keyed on the notes as well as the title, so the same title with different notes must
    /// still be classified on its own words rather than served the first answer.
    func testNotesArePartOfTheMemoKey() {
        XCTAssertEqual(LocalReportArea.detect(title: "still seeing this", notes: nil), .other)
        XCTAssertEqual(LocalReportArea.detect(title: "still seeing this", notes: "The break screen took over"), .routinesBreaks)
        XCTAssertEqual(LocalReportArea.detect(title: "still seeing this", notes: "The day plan is empty"), .dayPlan)
        XCTAssertEqual(LocalReportArea.detect(title: "still seeing this", notes: nil), .other)
    }

    /// Two reports whose words differ must not be served each other's entry, and nil notes must agree
    /// with empty notes — `detect` reads them as the same text, so the memo must not disagree.
    func testMemoDistinguishesReportsAndTreatsNilNotesAsEmpty() {
        XCTAssertEqual(LocalReportArea.detect(title: "routine", notes: nil),
                       LocalReportArea.detect(title: "routine", notes: ""))
        XCTAssertEqual(LocalReportArea.detect(title: "Menu bar popover is blank", notes: nil), .menuBar)
        XCTAssertEqual(LocalReportArea.detect(title: "Leaderboard streak reset", notes: nil), .stats)
        XCTAssertEqual(LocalReportArea.detect(title: "Menu bar popover is blank", notes: nil), .menuBar,
                       "A later lookup must still get this report's own area, not the one detected in between")
    }

    /// The memo is bounded and drops everything once full; the answers either side of that must match.
    func testAnswersSurviveTheMemoFillingUp() {
        let known = LocalReportArea.detect(title: "Day plan free time is wrong", notes: nil)
        for index in 0..<1200 {
            _ = LocalReportArea.detect(title: "unrelated report number \(index)", notes: nil)
        }
        XCTAssertEqual(LocalReportArea.detect(title: "Day plan free time is wrong", notes: nil), known)
    }
}
