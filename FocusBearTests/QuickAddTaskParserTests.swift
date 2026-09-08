//
//  QuickAddTaskParserTests.swift
//  Focus BearTests
//
//  Grammar tests for the menu-bar popover's one-line quick-add composer.
//

import XCTest
@testable import Focus_Bear

final class QuickAddTaskParserTests: XCTestCase {

    // MARK: Plain titles

    func testPlainTitleHasNoTokens() {
        let p = QuickAddTaskParser.parse("write the sprint report")
        XCTAssertEqual(p.title, "write the sprint report")
        XCTAssertNil(p.project)
        XCTAssertNil(p.durationMinutes)
        XCTAssertNil(p.outcome)
        XCTAssertFalse(p.isEmpty)
    }

    func testBlankInputIsEmpty() {
        XCTAssertTrue(QuickAddTaskParser.parse("   ").isEmpty)
        XCTAssertTrue(QuickAddTaskParser.parse("").isEmpty)
    }

    func testTitleIsTrimmed() {
        XCTAssertEqual(QuickAddTaskParser.parse("  tidy inbox  ").title, "tidy inbox")
    }

    // MARK: `#project` (delegated to the Day Plan composer's extractProjectToken)

    func testTrailingMultiWordProject() {
        let p = QuickAddTaskParser.parse("draft the brief #Focus Bear")
        XCTAssertEqual(p.title, "draft the brief")
        XCTAssertEqual(p.project, "Focus Bear")
    }

    func testUnderscoreProjectKeepsTrailingTitle() {
        let p = QuickAddTaskParser.parse("review notes #Focus_Bear then ship")
        XCTAssertEqual(p.title, "review notes then ship")
        XCTAssertEqual(p.project, "Focus Bear")
    }

    func testKnownProjectCasingIsReused() {
        let p = QuickAddTaskParser.parse("ping the team #focus bear", knownProjects: ["Focus Bear"])
        XCTAssertEqual(p.project, "Focus Bear")
    }

    func testStrayHashIsNotAProject() {
        let p = QuickAddTaskParser.parse("buy milk #")
        XCTAssertEqual(p.title, "buy milk #")
        XCTAssertNil(p.project)
    }

    // MARK: Duration forms

    func testMinutesForms() {
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("standup 30m").minutes, 30)
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("standup 45min").minutes, 45)
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("standup 45mins").minutes, 45)
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("standup 90 m").minutes, 90)
    }

    func testHourForms() {
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("deep work 1h").minutes, 60)
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("deep work 2hr").minutes, 120)
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("deep work 2hrs").minutes, 120)
    }

    func testCombinedHourMinuteForms() {
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("plan 1h30").minutes, 90)
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("plan 1h30m").minutes, 90)
        XCTAssertEqual(QuickAddTaskParser.extractDurationToken("plan 1H30M").minutes, 90)
    }

    func testDurationIsStrippedFromTitle() {
        let p = QuickAddTaskParser.parse("book the venue 1h30")
        XCTAssertEqual(p.title, "book the venue")
        XCTAssertEqual(p.durationMinutes, 90)
    }

    func testLastDurationTokenWins() {
        XCTAssertEqual(QuickAddTaskParser.parse("swim 30m then run 1h").durationMinutes, 60)
    }

    func testDurationIsClampedToADay() {
        XCTAssertEqual(QuickAddTaskParser.parse("marathon 99h").durationMinutes, 24 * 60)
        XCTAssertEqual(QuickAddTaskParser.parse("marathon 5000m").durationMinutes, 24 * 60)
    }

    func testZeroDurationIsNotADuration() {
        let p = QuickAddTaskParser.parse("stretch 0m")
        XCTAssertNil(p.durationMinutes)
        XCTAssertEqual(p.title, "stretch 0m")
    }

    func testBareNumberIsNotADuration() {
        let p = QuickAddTaskParser.parse("read chapter 3")
        XCTAssertNil(p.durationMinutes)
        XCTAssertEqual(p.title, "read chapter 3")
    }

    func testDurationMustStandAlone() {
        // "30mins" inside a word — no whitespace boundary before the digits — isn't a token.
        let p = QuickAddTaskParser.parse("email tim30m")
        XCTAssertNil(p.durationMinutes)
        XCTAssertEqual(p.title, "email tim30m")
    }

    // MARK: Combinations

    func testProjectAndDurationTogetherTrailingDuration() {
        let p = QuickAddTaskParser.parse("write the spec #Focus_Bear 45m")
        XCTAssertEqual(p.title, "write the spec")
        XCTAssertEqual(p.project, "Focus Bear")
        XCTAssertEqual(p.durationMinutes, 45)
    }

    /// The duration must be stripped BEFORE the project, or the "`#` to end of line" convention would
    /// swallow "Focus Bear 45m" as the project name.
    func testDurationAfterMultiWordProject() {
        let p = QuickAddTaskParser.parse("write the spec #Focus Bear 45m")
        XCTAssertEqual(p.title, "write the spec")
        XCTAssertEqual(p.project, "Focus Bear")
        XCTAssertEqual(p.durationMinutes, 45)
    }

    func testDurationBeforeProject() {
        let p = QuickAddTaskParser.parse("write the spec 45m #Focus Bear")
        XCTAssertEqual(p.title, "write the spec")
        XCTAssertEqual(p.project, "Focus Bear")
        XCTAssertEqual(p.durationMinutes, 45)
    }

    func testProjectDurationAndPriority() {
        let p = QuickAddTaskParser.parse("ship release *8 2h #Focus Bear")
        XCTAssertEqual(p.title, "ship release")
        XCTAssertEqual(p.project, "Focus Bear")
        XCTAssertEqual(p.durationMinutes, 120)
        XCTAssertEqual(p.outcome, 8)
    }

    func testOnlyTokensIsEmpty() {
        XCTAssertTrue(QuickAddTaskParser.parse("#Focus Bear").isEmpty)
        XCTAssertTrue(QuickAddTaskParser.parse("30m").isEmpty)
    }

    func testJunkIsKeptAsATitle() {
        let p = QuickAddTaskParser.parse("!!! ??? ***")
        XCTAssertEqual(p.title, "!!! ??? ***")
        XCTAssertNil(p.project)
        XCTAssertNil(p.durationMinutes)
        XCTAssertNil(p.outcome)
    }

    // MARK: Duration label

    func testDurationLabel() {
        XCTAssertEqual(QuickAddTaskParser.durationLabel(45), "45m")
        XCTAssertEqual(QuickAddTaskParser.durationLabel(120), "2h")
        XCTAssertEqual(QuickAddTaskParser.durationLabel(90), "1h 30m")
    }
}
