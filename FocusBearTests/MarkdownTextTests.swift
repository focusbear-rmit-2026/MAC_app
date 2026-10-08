//
//  MarkdownTextTests.swift
//  Focus BearTests
//
//  Tests for MarkdownParser — the markdown subset the pep talk / motivational summary render.
//

import XCTest
@testable import Focus_Bear

final class MarkdownTextTests: XCTestCase {

    private func runs(_ block: MarkdownBlock) -> [MarkdownRun] { block.runs }

    func testBoldRunsAreSplitOutOfPlainText() {
        let blocks = MarkdownParser.parse("Your **focus blocks** streak is a powerhouse")
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(runs(blocks[0]), [
            MarkdownRun(text: "Your "),
            MarkdownRun(text: "focus blocks", isBold: true),
            MarkdownRun(text: " streak is a powerhouse"),
        ])
    }

    func testUnderscoreBoldAndItalicMarkers() {
        XCTAssertEqual(MarkdownParser.parseInline("__bold__ and _italic_"), [
            MarkdownRun(text: "bold", isBold: true),
            MarkdownRun(text: " and "),
            MarkdownRun(text: "italic", isItalic: true),
        ])
        XCTAssertEqual(MarkdownParser.parseInline("*italic*"), [MarkdownRun(text: "italic", isItalic: true)])
    }

    func testNestedItalicInsideBold() {
        XCTAssertEqual(MarkdownParser.parseInline("**bold *both* bold**"), [
            MarkdownRun(text: "bold ", isBold: true),
            MarkdownRun(text: "both", isBold: true, isItalic: true),
            MarkdownRun(text: " bold", isBold: true),
        ])
    }

    func testUnclosedMarkerStaysLiteral() {
        XCTAssertEqual(MarkdownParser.parseInline("2 * 3 * 4 and snake_case_words"),
                       [MarkdownRun(text: "2 * 3 * 4 and snake_case_words")])
        XCTAssertEqual(MarkdownParser.parseInline("a **b"), [MarkdownRun(text: "a **b")])
    }

    func testStreamingPartialBoldRendersLiterallyUntilClosed() {
        let full = "You're doing amazing! 💪 Your **focus blocks** streak is a powerhouse"
        var streamed = ""
        for character in full {
            streamed.append(character)
            let blocks = MarkdownParser.parse(streamed)
            XCTAssertEqual(blocks.count, 1)
            // Lines are trimmed, so a chunk ending in a space renders without it until more arrives.
            XCTAssertEqual(blocks[0].plainText.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces),
                           streamed.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces))
        }
        XCTAssertEqual(MarkdownParser.parse("Your **focus blocks*")[0].runs, [MarkdownRun(text: "Your **focus blocks*")])
        XCTAssertEqual(MarkdownParser.parse("Your **focus bl")[0].runs, [MarkdownRun(text: "Your **focus bl")])
        XCTAssertEqual(MarkdownParser.parse(full)[0].runs.map { $0.isBold }, [false, true, false])
    }

    func testEmojiAndPunctuationPassThrough() {
        let text = "Keep going! 🚀🎯 It's 100% worth it — you've earned it."
        XCTAssertEqual(MarkdownParser.parseInline(text), [MarkdownRun(text: text)])
    }

    func testBlankLinesSeparateParagraphsAndSingleNewlinesJoin() {
        let blocks = MarkdownParser.parse("First line\nstill first\n\n\nSecond paragraph")
        XCTAssertEqual(blocks, [
            .paragraph([MarkdownRun(text: "First line\nstill first")]),
            .paragraph([MarkdownRun(text: "Second paragraph")]),
        ])
    }

    func testHeadingsAndHashtagsAreDistinguished() {
        let blocks = MarkdownParser.parse("# Big\n## Medium\n### Small\n#### too deep\n#hashtag")
        XCTAssertEqual(blocks[0], .heading(level: 1, runs: [MarkdownRun(text: "Big")]))
        XCTAssertEqual(blocks[1], .heading(level: 2, runs: [MarkdownRun(text: "Medium")]))
        XCTAssertEqual(blocks[2], .heading(level: 3, runs: [MarkdownRun(text: "Small")]))
        XCTAssertEqual(blocks[3], .paragraph([MarkdownRun(text: "#### too deep\n#hashtag")]))
    }

    func testBulletsAndNumberedLines() {
        let blocks = MarkdownParser.parse("- dash\n* star\n• dot\n1. first\n2) second\n*not a bullet*")
        XCTAssertEqual(blocks, [
            .bullet([MarkdownRun(text: "dash")]),
            .bullet([MarkdownRun(text: "star")]),
            .bullet([MarkdownRun(text: "dot")]),
            .numbered(label: "1.", runs: [MarkdownRun(text: "first")]),
            .numbered(label: "2)", runs: [MarkdownRun(text: "second")]),
            .paragraph([MarkdownRun(text: "not a bullet", isItalic: true)]),
        ])
    }

    func testInlineCodeSuppressesMarkersInside() {
        XCTAssertEqual(MarkdownParser.parseInline("run `a**b**c` now"), [
            MarkdownRun(text: "run "),
            MarkdownRun(text: "a**b**c", isCode: true),
            MarkdownRun(text: " now"),
        ])
        XCTAssertEqual(MarkdownParser.parseInline("`unclosed"), [MarkdownRun(text: "`unclosed")])
    }

    func testLinksCarryTheirURL() {
        XCTAssertEqual(MarkdownParser.parseInline("see [the **docs**](https://focusbear.io/help) today"), [
            MarkdownRun(text: "see "),
            MarkdownRun(text: "the ", linkURL: "https://focusbear.io/help"),
            MarkdownRun(text: "docs", isBold: true, linkURL: "https://focusbear.io/help"),
            MarkdownRun(text: " today"),
        ])
        XCTAssertEqual(MarkdownParser.parseInline("[not a link] (x)"), [MarkdownRun(text: "[not a link] (x)")])
    }

    func testAdjacentRunsWithSameStyleMerge() {
        XCTAssertEqual(MarkdownParser.parseInline("**a****b**"), [MarkdownRun(text: "ab", isBold: true)])
    }
}
