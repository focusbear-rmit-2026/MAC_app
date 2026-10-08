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
        let p = QuickAddTaskParser.parse("ship release !4 2h #Focus Bear")
        XCTAssertEqual(p.title, "ship release")
        XCTAssertEqual(p.project, "Focus Bear")
        XCTAssertEqual(p.durationMinutes, 120)
        XCTAssertEqual(p.outcome, 8)
    }

    // MARK: The 2026-09-21 token change (report 2026-09-21_07-42-02)

    /// `*` used to mean priority and now means minutes. `*5` therefore has to read as five minutes,
    /// not priority 5 — that reversal is the whole point of the report.
    func testStarIsNowADurationAndBangIsPriority() {
        let star = QuickAddTaskParser.parse("post focus button *5")
        XCTAssertEqual(star.title, "post focus button")
        XCTAssertEqual(star.durationMinutes, 5)
        XCTAssertNil(star.outcome)

        let bang = QuickAddTaskParser.parse("post focus button !5")
        XCTAssertEqual(bang.title, "post focus button")
        XCTAssertEqual(bang.outcome, 10)
        XCTAssertNil(bang.durationMinutes)
    }

    func testStarDurationTakesMoreThanOneDigit() {
        XCTAssertEqual(QuickAddTaskParser.parse("write spec *90").durationMinutes, 90)
        XCTAssertEqual(QuickAddTaskParser.parse("write spec *15").durationMinutes, 15)
    }

    /// The report's exact example: the star form is what the user reached for on a Day Plan row,
    /// where a spelled "30m" is deliberately left in the name.
    func testTheDayPlanRowTakesAStarDurationButNotASpelledOne() {
        guard case .save(let starred) = TaskNameCommit.forDayPlanRow("post focus button *5",
                                                                     knownProjects: []) else {
            return XCTFail("expected a save")
        }
        XCTAssertEqual(starred.title, "post focus button")
        XCTAssertEqual(starred.durationMinutes, 5)

        guard case .save(let spelled) = TaskNameCommit.forDayPlanRow("run 30m sprint",
                                                                     knownProjects: []) else {
            return XCTFail("expected a save")
        }
        XCTAssertEqual(spelled.title, "run 30m sprint", "a spelled duration is prose on this row")
        XCTAssertNil(spelled.durationMinutes)
    }

    func testTheDayPlanRowStillTakesPriorityAndProject() {
        guard case .save(let parsed) = TaskNameCommit.forDayPlanRow("draft memo !3 #Focus Bear",
                                                                    knownProjects: ["Focus Bear"]) else {
            return XCTFail("expected a save")
        }
        XCTAssertEqual(parsed.title, "draft memo")
        XCTAssertEqual(parsed.outcome, 6)
        XCTAssertEqual(parsed.project, "Focus Bear")
    }

    /// A star with no digits is not a duration, so it stays in the name rather than vanishing.
    func testABareStarIsStillJustText() {
        let p = QuickAddTaskParser.parse("rate it ***")
        XCTAssertEqual(p.title, "rate it ***")
        XCTAssertNil(p.durationMinutes)
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

    // MARK: `#project` suggestions (report 2026-09-14_16-17-22)

    private let projects = ["product", "Product marketing", "admin", "Geelong Trees"]

    func testTheTokenBeingTypedIsEverythingAfterTheLastHash() {
        XCTAssertEqual(QuickAddProjectSuggestions.activeToken(in: "write up #prod"), "prod")
        XCTAssertEqual(QuickAddProjectSuggestions.activeToken(in: "write up #life admin"), "life admin",
                       "A multi-word project runs to the end of the line, as the parser reads it")
        XCTAssertNil(QuickAddProjectSuggestions.activeToken(in: "no token here"))
    }

    func testNamesStartingWithTheTokenComeBeforeNamesMerelyContainingIt() {
        XCTAssertEqual(QuickAddProjectSuggestions.matches(for: "task #pro", knownProjects: projects),
                       ["product", "Product marketing"])
        XCTAssertEqual(QuickAddProjectSuggestions.matches(for: "task #marketing", knownProjects: projects),
                       ["Product marketing"])
    }

    func testABareHashOffersTheProjectsYouHave() {
        XCTAssertEqual(QuickAddProjectSuggestions.matches(for: "task #", knownProjects: projects, limit: 2),
                       ["product", "Product marketing"])
    }

    func testAnExactMatchNeedsNoSuggesting() {
        XCTAssertTrue(QuickAddProjectSuggestions.matches(for: "task #admin", knownProjects: projects).isEmpty)
        XCTAssertTrue(QuickAddProjectSuggestions.matches(for: "task #ADMIN", knownProjects: projects).isEmpty)
    }

    func testNoSuggestionsWithoutAToken() {
        XCTAssertTrue(QuickAddProjectSuggestions.matches(for: "just a task", knownProjects: projects).isEmpty)
    }

    func testAcceptingASuggestionReplacesOnlyTheHalfTypedToken() {
        XCTAssertEqual(QuickAddProjectSuggestions.applying("Geelong Trees", to: "email Tim 30m #gee"),
                       "email Tim 30m #Geelong Trees")
        XCTAssertEqual(QuickAddProjectSuggestions.applying("admin", to: "no hash"), "no hash")
    }

    func testAnAcceptedSuggestionParsesBackToThatProject() {
        let line = QuickAddProjectSuggestions.applying("Geelong Trees", to: "email Tim 30m #gee")
        let parsed = QuickAddTaskParser.parse(line, knownProjects: projects)
        XCTAssertEqual(parsed.project, "Geelong Trees")
        XCTAssertEqual(parsed.title, "email Tim")
        XCTAssertEqual(parsed.durationMinutes, 30)
    }

    // MARK: Tab accepts the highlighted suggestion (report 2026-09-15_12-24-31)

    func testTabAcceptsWhicheverSuggestionIsHighlighted() {
        XCTAssertEqual(QuickAddProjectSuggestions.accepting("task #pro", knownProjects: projects, suggestion: 0),
                       "task #product")
        XCTAssertEqual(QuickAddProjectSuggestions.accepting("task #pro", knownProjects: projects, suggestion: 1),
                       "task #Product marketing",
                       "Tab accepts the row the arrow keys moved the highlight to, not always the first")
    }

    /// The guard that keeps Tab from becoming a worse bug than the one it fixes: with nothing to accept
    /// the decision is nil, the field's Tab handler returns false, and AppKit moves the focus as usual.
    func testThereIsNothingToAcceptWithoutAMatchingSuggestion() {
        XCTAssertNil(QuickAddProjectSuggestions.accepting("just a task", knownProjects: projects, suggestion: 0),
                     "no `#` token at all")
        XCTAssertNil(QuickAddProjectSuggestions.accepting("task #zzz", knownProjects: projects, suggestion: 0),
                     "a token that matches no project")
        XCTAssertNil(QuickAddProjectSuggestions.accepting("task #admin", knownProjects: projects, suggestion: 0),
                     "an exact match is already the project; there is nothing left to accept")
        XCTAssertNil(QuickAddProjectSuggestions.accepting("task #pro", knownProjects: projects, suggestion: 9),
                     "a highlight past the end of the list accepts nothing rather than crashing")
        XCTAssertNil(QuickAddProjectSuggestions.accepting("task #pro", knownProjects: projects, suggestion: -1))
    }

    /// Clicking a row and pressing Tab on that same row are the same act, so they go through one
    /// function. This pins that: accepting row N is exactly the list's Nth match applied to the line.
    func testClickingARowAndTabbingOntoItAcceptTheSameThing() {
        let line = "BAS statements #pro"
        let matches = QuickAddProjectSuggestions.matches(for: line, knownProjects: projects)
        XCTAssertFalse(matches.isEmpty)
        for index in matches.indices {
            XCTAssertEqual(QuickAddProjectSuggestions.accepting(line, knownProjects: projects, suggestion: index),
                           QuickAddProjectSuggestions.applying(matches[index], to: line),
                           "Tab and a click must accept the same suggestion the same way")
        }
    }

    /// The data-loss guard: accepting a project must not turn a token-only line into a task with a
    /// blank title. It only rewrites the token — the line stays `isEmpty`, so Enter still refuses it.
    func testAcceptingOnATokenOnlyLineStillLeavesNothingWorthAdding() {
        let accepted = QuickAddProjectSuggestions.accepting("#pro", knownProjects: projects, suggestion: 0)
        XCTAssertEqual(accepted, "#product")
        let parsed = QuickAddTaskParser.parse(accepted ?? "", knownProjects: projects)
        XCTAssertEqual(parsed.project, "product")
        XCTAssertTrue(parsed.isEmpty, "a line that is still only a project token must never be added")
        XCTAssertEqual(TaskNameCommit.forQuickAdd(accepted ?? "", knownProjects: projects), .refuseTokensOnly)
    }

    func testAcceptingKeepsTheRestOfTheLineIntact() {
        let accepted = QuickAddProjectSuggestions.accepting("email Tim 30m #gee", knownProjects: projects, suggestion: 0)
        XCTAssertEqual(accepted, "email Tim 30m #Geelong Trees")
        let parsed = QuickAddTaskParser.parse(accepted ?? "", knownProjects: projects)
        XCTAssertEqual(parsed.title, "email Tim")
        XCTAssertEqual(parsed.durationMinutes, 30)
        XCTAssertFalse(parsed.isEmpty)
    }

    // MARK: - Duration fields (report 2026-07-15_20-25-27)

    /// The reported bug: the Day Plan's duration fields stripped non-digits, so "4h" became 4 minutes.
    func testHoursInADurationFieldAreNotReadAsMinutes() {
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "4h"), 240)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "1h30"), 90)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "2 hrs"), 120)
    }

    /// A bare number is the commonest thing typed into a duration field and still means minutes.
    func testBareNumberIsMinutes() {
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "30"), 30)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "90"), 90)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: " 45 "), 45)
    }

    func testExplicitMinuteSuffixesStillWork() {
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "30m"), 30)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "45min"), 45)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "90 mins"), 90)
    }

    func testEmptyOrZeroIsNoDuration() {
        XCTAssertNil(QuickAddTaskParser.durationMinutes(fromFieldText: ""))
        XCTAssertNil(QuickAddTaskParser.durationMinutes(fromFieldText: "   "))
        XCTAssertNil(QuickAddTaskParser.durationMinutes(fromFieldText: "0"))
        XCTAssertNil(QuickAddTaskParser.durationMinutes(fromFieldText: "abc"))
    }

    func testDurationFieldIsClampedToADay() {
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "99h"), QuickAddTaskParser.maxDurationMinutes)
        XCTAssertEqual(QuickAddTaskParser.durationMinutes(fromFieldText: "5000"), QuickAddTaskParser.maxDurationMinutes)
    }
}
