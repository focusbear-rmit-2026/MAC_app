//
//  EventDescriptionHTMLTests.swift
//  Focus BearTests
//
//  The Day Plan event editor renders a calendar event's HTML description instead of showing its
//  source (EventDescriptionHTML).
//
//  Reported as: "Can you make it render HTML? (safely - don't run scripts). Best way would be just to
//  support <br>, <b>, <a> and not styles or scripts" — so the tests pin that subset exactly: the
//  three tags render, everything else is stripped, and no href outside http(s) is ever actionable.
//

@testable import Focus_Bear
import AppKit
import XCTest

final class EventDescriptionHTMLTests: XCTestCase {

    private func link(_ html: String) -> URL? {
        EventDescriptionHTML.runs(from: html).compactMap(\.link).first
    }

    private func boldText(_ html: String) -> [String] {
        EventDescriptionHTML.runs(from: html).filter(\.isBold).map(\.text)
    }

    // MARK: - The reported description

    /// The exact shape from the report: a leading <br>, and an anchor whose target="_blank" was
    /// leaking into the middle of the sentence.
    func testRendersTheReportedGoogleCalendarDescription() {
        let html = "<br>Focus and Chill podcast recording<br>"
            + "<a href=\"https://us02web.zoom.us/j/88186982108\" target=\"_blank\">https://us02web.zoom.us/j/88186982108</a>"

        XCTAssertEqual(EventDescriptionHTML.plainText(from: html),
                       "Focus and Chill podcast recording\nhttps://us02web.zoom.us/j/88186982108")
        XCTAssertEqual(link(html)?.absoluteString, "https://us02web.zoom.us/j/88186982108")
    }

    // MARK: - The three supported tags

    func testBrBecomesALineBreak() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "one<br>two<br/>three<br />four"),
                       "one\ntwo\nthree\nfour")
    }

    func testBoldTagMarksItsTextBold() {
        let runs = EventDescriptionHTML.runs(from: "plain <b>loud</b> plain")
        XCTAssertEqual(runs.map(\.text), ["plain ", "loud", " plain"])
        XCTAssertEqual(runs.map(\.isBold), [false, true, false])
    }

    func testAnchorTextKeepsItsHref() {
        let runs = EventDescriptionHTML.runs(from: "join <a href=\"https://example.com/room\">here</a> now")
        XCTAssertEqual(runs.map(\.text), ["join ", "here", " now"])
        XCTAssertEqual(runs.map { $0.link?.absoluteString }, [nil, "https://example.com/room", nil])
    }

    func testSingleQuotedHrefIsRead() {
        XCTAssertEqual(link("<a href='https://example.com'>x</a>")?.absoluteString, "https://example.com")
    }

    // MARK: - Nesting and unclosed tags

    func testNestedBoldStaysBoldUntilTheOuterTagCloses() {
        let runs = EventDescriptionHTML.runs(from: "<b>a<b>b</b>c</b>d")
        XCTAssertEqual(runs.map(\.text), ["a", "b", "c", "d"])
        XCTAssertEqual(runs.map(\.isBold), [true, true, true, false])
    }

    func testBoldInsideALinkKeepsBoth() {
        let runs = EventDescriptionHTML.runs(from: "<a href=\"https://example.com\">see <b>this</b></a>")
        XCTAssertEqual(boldText("<a href=\"https://example.com\">see <b>this</b></a>"), ["this"])
        XCTAssertTrue(runs.allSatisfy { $0.link?.absoluteString == "https://example.com" })
    }

    func testUnclosedBoldAppliesToTheRestOfTheDescription() {
        let runs = EventDescriptionHTML.runs(from: "before <b>after")
        XCTAssertEqual(runs.map(\.text), ["before ", "after"])
        XCTAssertEqual(runs.map(\.isBold), [false, true])
    }

    func testUnclosedAnchorLinksTheRestOfTheDescription() {
        XCTAssertEqual(link("call <a href=\"https://example.com\">from here on")?.absoluteString,
                       "https://example.com")
    }

    func testStrayClosingTagIsIgnored() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "text</b></a> more"), "text more")
    }

    // MARK: - Everything else is stripped

    func testUnknownTagIsStrippedButItsTextIsKept() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "<div><span class=\"x\">kept</span></div>"), "kept")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "<h1>title</h1>body"), "titlebody")
    }

    func testStylesAreNotHonoured() {
        let runs = EventDescriptionHTML.runs(from: "<span style=\"font-weight:bold\">not bold</span>")
        XCTAssertEqual(runs.map(\.text), ["not bold"])
        XCTAssertEqual(runs.map(\.isBold), [false])
    }

    /// A script's *content* is code, not prose, so it goes with the tag — showing "alert(1)" in a
    /// meeting description would be as wrong as running it.
    func testScriptAndStyleContentIsDropped() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "a<script>alert(1)</script>b"), "ab")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "a<style>.x{color:red}</style>b"), "ab")
    }

    func testHtmlCommentIsDropped() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "a<!-- hidden -->b"), "ab")
    }

    // MARK: - Entities

    func testSupportedEntitiesAreDecoded() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "Tom &amp; Jerry"), "Tom & Jerry")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "&lt;tag&gt;"), "<tag>")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "say &quot;hi&quot;"), "say \"hi\"")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "it&#39;s"), "it's")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "a&nbsp;b"), "a b")
    }

    /// Decoding happens after tagging, so escaped markup stays visible as text rather than becoming
    /// a tag on a second pass.
    func testEscapedMarkupIsNotReparsedAsATag() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "&lt;b&gt;not bold&lt;/b&gt;"), "<b>not bold</b>")
        XCTAssertEqual(boldText("&lt;b&gt;not bold&lt;/b&gt;"), [])
    }

    func testUnknownEntityIsLeftAlone() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "100 &fake; ok"), "100 &fake; ok")
    }

    // MARK: - Unsafe hrefs

    func testJavascriptHrefIsNotActionable() {
        let html = "<a href=\"javascript:alert(1)\">click me</a>"
        XCTAssertNil(link(html), "a javascript: href must never become a clickable link")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: html), "click me", "but its text stays legible")
    }

    func testOtherUnsafeSchemesAreNotActionable() {
        XCTAssertNil(link("<a href=\"file:///etc/passwd\">f</a>"))
        XCTAssertNil(link("<a href=\"data:text/html;base64,PHNjcmlwdD4=\">d</a>"))
        XCTAssertNil(link("<a href=\"JaVaScRiPt:alert(1)\">mixed case</a>"))
        XCTAssertNil(link("<a href=\"  javascript:alert(1)  \">padded</a>"))
        XCTAssertNil(link("<a href=\"/relative/path\">r</a>"), "a scheme-less href can't be resolved")
        XCTAssertNil(link("<a>no href</a>"))
    }

    func testOpenableURLAcceptsOnlyHttpAndHttps() {
        XCTAssertEqual(EventDescriptionHTML.openableURL(from: "http://example.com")?.scheme, "http")
        XCTAssertEqual(EventDescriptionHTML.openableURL(from: "https://example.com")?.scheme, "https")
        XCTAssertNil(EventDescriptionHTML.openableURL(from: "javascript:alert(1)"))
        XCTAssertNil(EventDescriptionHTML.openableURL(from: "mailto:someone@example.com"))
        XCTAssertNil(EventDescriptionHTML.openableURL(from: ""))
    }

    /// The renderer refuses the href, so the attributed string the text view shows carries no link
    /// attribute at all for it.
    func testAttributedStringAttachesNoLinkForAnUnsafeHref() {
        let attributed = EventDescriptionHTML.attributedString(from: "<a href=\"javascript:alert(1)\">x</a>",
                                                               font: .systemFont(ofSize: 13),
                                                               textColor: .textColor)
        var found = false
        attributed.enumerateAttribute(.link, in: NSRange(location: 0, length: attributed.length)) { value, _, _ in
            if value != nil { found = true }
        }
        XCTAssertFalse(found)
    }

    func testAttributedStringAttachesTheLinkForASafeHref() {
        let attributed = EventDescriptionHTML.attributedString(from: "<a href=\"https://example.com\">x</a>",
                                                               font: .systemFont(ofSize: 13),
                                                               textColor: .textColor)
        XCTAssertEqual(attributed.attribute(.link, at: 0, effectiveRange: nil) as? URL,
                       URL(string: "https://example.com"))
    }

    // MARK: - Plain text passes through

    func testPlainTextIsUntouched() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "Just a normal description."),
                       "Just a normal description.")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "line one\nline two"), "line one\nline two")
        XCTAssertEqual(EventDescriptionHTML.plainText(from: ""), "")
    }

    /// A bare "<" that isn't a tag must not swallow the rest of the description.
    func testLoneAngleBracketIsKept() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "5 < 6 and 7 > 6"), "5 < 6 and 7 > 6")
    }

    // MARK: - Saving (the round-trip guard)

    /// The point of the whole exercise: the editor shows the description rendered, so an untouched
    /// description must go back to the calendar as the HTML it arrived as. Otherwise moving a meeting
    /// by half an hour would flatten the description for every other attendee.
    func testAnUntouchedDescriptionSavesTheOriginalHtml() {
        let original = "<b>Agenda</b><br><a href=\"https://example.com\">https://example.com</a>"
        let rendered = EventDescriptionHTML.plainText(from: original)
        XCTAssertEqual(EventDescriptionHTML.notesToSave(edited: rendered, rendered: rendered, original: original),
                       original)
    }

    func testAnEditedDescriptionSavesWhatTheUserTyped() {
        let original = "<b>Agenda</b><br>old"
        let rendered = EventDescriptionHTML.plainText(from: original)
        XCTAssertEqual(EventDescriptionHTML.notesToSave(edited: "Agenda\nnew", rendered: rendered, original: original),
                       "Agenda\nnew")
    }

    func testClearingTheDescriptionSavesItEmpty() {
        let original = "<b>Agenda</b>"
        let rendered = EventDescriptionHTML.plainText(from: original)
        XCTAssertEqual(EventDescriptionHTML.notesToSave(edited: "", rendered: rendered, original: original), "")
    }

    /// A description that was already plain text renders to itself, so it round-trips byte for byte.
    func testPlainDescriptionRoundTripsUnchanged() {
        let original = "Bring the laptop."
        let rendered = EventDescriptionHTML.plainText(from: original)
        XCTAssertEqual(rendered, original)
        XCTAssertEqual(EventDescriptionHTML.notesToSave(edited: rendered, rendered: rendered, original: original),
                       original)
    }

    // MARK: - Trimming

    func testLeadingAndTrailingBlankLinesAreTrimmed() {
        XCTAssertEqual(EventDescriptionHTML.plainText(from: "<br><br>body<br><br>"), "body")
    }
}
