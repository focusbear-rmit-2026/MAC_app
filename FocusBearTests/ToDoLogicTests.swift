//
//  ToDoLogicTests.swift
//  Focus BearTests
//
//  Unit tests for the pure logic behind the native To-do List (ToDoLogic.swift): TOP-score maths,
//  the typed due-date grammar ("2d", "fri", "28 sep", "25/9"…), sort modes, the Doing / To do /
//  Done sectioning with project custom columns, the PUT /to-do body, editor drafts, lenient API
//  decoding, server error bodies and the portfolio "This week" regrouping. Each rule mirrors a
//  web-dashboard util, so these lock in parity.
//

@testable import Focus_Bear
import XCTest
import SwiftUI

extension ToDoLogicTests {
    func testBrainDumpPartialFailureKeepsUnconfirmedIDsForRetry() {
        let tasks = (1...3).map { BrainDumpTask(task_name: "Task \($0)", estimatedMinutes: 5, subtasks: []) }
        var attempted: [String] = []
        var responses: [(Bool) -> Void] = []
        var saved: [String] = []
        var results: [BrainDumpTaskWriter.Result] = []
        let writer = BrainDumpTaskWriter(tasks: tasks, isCurrent: { true }, write: { task, done in
            attempted.append(task.id); responses.append(done)
        }, didSave: { saved.append($0) }, completion: { results.append($0) })
        writer.start()
        XCTAssertEqual(attempted, [tasks[0].id])
        responses[0](true)
        XCTAssertEqual(attempted, [tasks[0].id, tasks[1].id])
        responses[0](true) // A duplicate callback cannot advance the second write.
        responses[1](false)
        XCTAssertEqual(saved, [tasks[0].id])
        XCTAssertEqual(results, [.failed(confirmedCount: 1)])
        let pending = tasks.filter { !saved.contains($0.id) }
        let retry = BrainDumpTaskWriter(tasks: pending, isCurrent: { true }, write: { task, done in
            attempted.append(task.id); done(true)
        }, didSave: { saved.append($0) }, completion: { results.append($0) })
        retry.start()
        XCTAssertEqual(attempted, [tasks[0].id, tasks[1].id, tasks[1].id, tasks[2].id])
        XCTAssertEqual(saved, tasks.map(\.id))
        XCTAssertEqual(results, [.failed(confirmedCount: 1), .complete])
    }

    func testBrainDumpAccountChangeStopsWritesAndDraftRemoval() {
        let tasks = (1...2).map { BrainDumpTask(task_name: "Task \($0)", estimatedMinutes: 5, subtasks: []) }
        var isCurrent = true
        var pending: ((Bool) -> Void)?
        var attempts = 0
        var saved: [String] = []
        var result: BrainDumpTaskWriter.Result?
        let writer = BrainDumpTaskWriter(tasks: tasks, isCurrent: { isCurrent }, write: { _, done in
            attempts += 1; pending = done
        }, didSave: { saved.append($0) }, completion: { result = $0 })
        writer.start()
        isCurrent = false
        pending?(true)
        XCTAssertEqual(attempts, 1)
        XCTAssertTrue(saved.isEmpty)
        XCTAssertEqual(result, .superseded)
    }

    func testBrainDumpDismissalIgnoresLateResponse() {
        let task = BrainDumpTask(task_name: "Review report", estimatedMinutes: 10, subtasks: [])
        var pending: ((Bool) -> Void)?
        var results: [BrainDumpTaskWriter.Result] = []
        let writer = BrainDumpTaskWriter(tasks: [task], isCurrent: { true }, write: { _, done in pending = done },
                                        didSave: { _ in XCTFail("Dismissed draft must not be changed") },
                                        completion: { results.append($0) })
        writer.start()
        writer.cancel()
        pending?(true)
        XCTAssertEqual(results, [.superseded])
    }

    func testBrainDumpRetryPayloadPreservesIdentityAndNullableRatings() {
        var task = BrainDumpTask(task_name: "Review report", estimatedMinutes: 10, subtasks: ["Read draft"])
        let first = BrainDumpTaskPayload.body(for: task, today: "2026-09-10")!
        XCTAssertEqual(first["id"] as? String, task.id.lowercased())
        XCTAssertTrue(first["outcome"] is NSNull)
        XCTAssertTrue(first["perspiration_level"] is NSNull)
        task.task_name = "Review revised report"
        task.outcome = 9
        task.perspiration_level = 3
        let retry = BrainDumpTaskPayload.body(for: task, today: "2026-09-10")!
        XCTAssertEqual(retry["id"] as? String, first["id"] as? String)
        XCTAssertEqual(retry["title"] as? String, task.task_name)
        XCTAssertEqual(retry["outcome"] as? Int, 9)
        XCTAssertEqual(retry["perspiration_level"] as? Int, 3)
        XCTAssertEqual(retry["duration"] as? Int, 600)
    }

    func testBrainDumpRejectsMissingAndOverflowingEffort() {
        for minutes in [0, -1, Int.max, Int(Int32.max) / 60 + 1] {
            XCTAssertNil(BrainDumpTaskPayload.body(for: BrainDumpTask(task_name: "Task", estimatedMinutes: minutes, subtasks: []), today: "2026-09-10"))
        }
    }

    func testBrainDumpDiscardsBlankAISubtasksBeforeValidatedWrite() {
        let task = BrainDumpTask(task_name: "Review report", estimatedMinutes: 10, subtasks: ["", " \n", " Read draft "])
        let body = BrainDumpTaskPayload.body(for: task, today: "2026-09-10")!
        let subtasks = body["subtasks"] as? [[String: Any]]
        XCTAssertEqual(subtasks?.count, 1)
        XCTAssertEqual(subtasks?.first?["name"] as? String, "Read draft")
        XCTAssertEqual(subtasks?.first?["is_completed"] as? Bool, false)
    }
}

final class ToDoLogicTests: XCTestCase {

    private let calendar = Calendar.current
    private lazy var today = calendar.startOfDay(for: Date())

    private func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today)! }

    private func task(_ id: String, status: ToDoStatus = .notStarted, due: Date? = nil, created: String = "2026-01-01T00:00:00.000Z",
                      outcome: Int? = nil, perspiration: Int? = nil, topScore: Double? = nil, customStatusId: String? = nil,
                      projectId: String? = nil, tags: [ToDoTag] = []) -> ToDoTask {
        ToDoTask(id: id, title: id, details: nil, objective: nil, status: status.rawValue, due_date: due.map { ToDoDates.ymd($0) },
                 created_at: created, eisenhower_quadrant: 1, outcome: outcome, perspiration_level: perspiration, top_score: topScore,
                 duration: nil, icon: nil, tags: tags, subtasks: nil, project_id: projectId, custom_status_id: customStatusId)
    }

    private func risk(_ id: String, bucket: PortfolioBucket, score: Double = 0, due: String? = nil, importance: Int = 2,
                      days: Int? = nil, badges: [PortfolioBadge] = [], hours: Double = 0) -> PortfolioProject {
        PortfolioProject(id: id, name: id, due_date: due, importance: importance, required_hours: hours, risk_score: score,
                         bucket: bucket.rawValue, deficit_hours: 0, days_until_due: days, latest_start: nil,
                         badges: badges.map { $0.rawValue })
    }

    // MARK: - TOP score

    func testTimePressureMatchesWebConstants() {
        XCTAssertEqual(ToDoScoring.timePressure(dueDate: nil, effortMinutes: 15), 0.1)
        XCTAssertEqual(ToDoScoring.timePressure(dueDate: day(0), effortMinutes: 15), 9)
        XCTAssertEqual(ToDoScoring.timePressure(dueDate: day(-3), effortMinutes: 15), 13)
        let future = ToDoScoring.timePressure(dueDate: day(10), effortMinutes: 60)
        XCTAssertGreaterThan(future, 0.1)
        XCTAssertLessThan(future, 9)
    }

    func testTopScoreIsTimesOutcomeOverPerspiration() {
        // Due today: T = 9, O = 5, P = 2 → 22.5
        XCTAssertEqual(ToDoScoring.topScore(outcome: 5, perspiration: 2, dueDate: day(0)), 22.5, accuracy: 0.0001)
        // Perspiration is clamped into 1…10.
        XCTAssertEqual(ToDoScoring.topScore(outcome: 5, perspiration: 0, dueDate: day(0)), 45, accuracy: 0.0001)
    }

    func testPerspirationForMinutesIsTheInverseOfTheWorkTable() {
        // The lowest level whose minutes cover the typed value; beyond the table the top level.
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 5), 1)
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 15), 2)
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 16), 3)
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 45), 4)
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 240), 5)
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 10_000), 10)
        // A level that already matches the minutes is kept, so the slider doesn't snap 6 → 5 / 8 → 7.
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 240, current: 6), 6)
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 480, current: 8), 8)
        XCTAssertEqual(ToDoScoring.perspiration(forMinutes: 480, current: 2), 7)
        for level in ToDoScoring.minLevel...ToDoScoring.maxLevel {
            XCTAssertEqual(ToDoScoring.perspiration(forMinutes: ToDoScoring.minutes(forPerspiration: level), current: level), level)
        }
    }

    func testStaleStoredScoreLosesToLocalFormula() {
        // Due 17 Aug, stored 0.2 while it was still weeks away: the server never re-scores, the
        // list must show the live overdue value the editor shows (T = 10 + 21, O = 6, P = 3 → 62).
        let overdue = task("a", due: day(-21), outcome: 6, perspiration: 3, topScore: 0.2)
        XCTAssertEqual(ToDoScoring.topScore(of: overdue), 62, accuracy: 0.0001)
        XCTAssertEqual(ToDoScoring.topScore(of: overdue),
                       ToDoScoring.topScore(outcome: 6, perspiration: 3, dueDate: day(-21)), accuracy: 0.0001, "list and editor agree")
        XCTAssertEqual(ToDoScoring.topScore(of: task("b", due: day(0), outcome: 5, perspiration: 2)), 22.5, accuracy: 0.0001)
        // Only a row with none of the inputs falls back to what the server stored.
        XCTAssertEqual(ToDoScoring.topScore(of: task("c", topScore: 7)), 7)
        XCTAssertEqual(ToDoScoring.topScore(of: task("d", due: day(3), topScore: 7)),
                       ToDoScoring.topScore(outcome: 1, perspiration: 1, dueDate: day(3)), accuracy: 0.0001)
    }

    func testSmartSortUsesLiveScores() {
        // Stored scores say "later" wins; the live formula says the overdue one does.
        let sorted = ToDoSorting.sort([task("later", due: day(10), outcome: 5, perspiration: 2, topScore: 50),
                                       task("overdue", due: day(-2), outcome: 5, perspiration: 2, topScore: 0.5)], by: .smart)
        XCTAssertEqual(sorted.map { $0.id }, ["overdue", "later"])
    }

    func testDurationFallsBackToPerspirationMinutes() {
        XCTAssertEqual(ToDoScoring.durationSeconds(explicit: 600, perspiration: 2), 600)
        XCTAssertEqual(ToDoScoring.durationSeconds(explicit: 0, perspiration: 2), 15 * 60)
        XCTAssertEqual(ToDoScoring.durationSeconds(explicit: nil, perspiration: 9), 3360 * 60)
    }

    // MARK: - Typed due-date grammar

    /// Melbourne, Gregorian, English — every case below resolves against Mon 7 Sep 2026 10:00.
    private let fixedCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        return calendar
    }()
    private let english = Locale(identifier: "en_US_POSIX")

    private func fixed(_ year: Int, _ month: Int, _ day: Int) -> Date {
        fixedCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func parsed(_ input: String, locale: Locale? = nil) -> Date? {
        let now = fixedCalendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 10))!
        return ToDoDueDateParser.parse(input, now: now, calendar: fixedCalendar, locale: locale ?? english)
    }

    func testParserKeywords() {
        XCTAssertEqual(parsed("today"), fixed(2026, 9, 7))
        XCTAssertEqual(parsed("Tomorrow"), fixed(2026, 9, 8))
        XCTAssertEqual(parsed("tmr"), fixed(2026, 9, 8))
        XCTAssertEqual(parsed("hoy"), fixed(2026, 9, 7))
        XCTAssertEqual(parsed("mañana"), fixed(2026, 9, 8))
    }

    func testParserRelativeUnits() {
        XCTAssertEqual(parsed("2d"), fixed(2026, 9, 9))
        XCTAssertEqual(parsed("3w"), fixed(2026, 9, 28))
        XCTAssertEqual(parsed("1m"), fixed(2026, 10, 7))
        XCTAssertEqual(parsed("1 week"), fixed(2026, 9, 14))
        XCTAssertEqual(parsed("in 2 days"), fixed(2026, 9, 9))
        XCTAssertEqual(parsed("in  3   weeks"), fixed(2026, 9, 28), "whitespace is collapsed")
        XCTAssertEqual(parsed("in 1 month"), fixed(2026, 10, 7))
    }

    /// "2y = 2 years" (report 2026-09-15_20-52-05): the field rejected it as unrecognised.
    func testParserRelativeUnitsUnderstandYears() {
        XCTAssertEqual(parsed("2y"), fixed(2028, 9, 7))
        XCTAssertEqual(parsed("1 year"), fixed(2027, 9, 7))
        XCTAssertEqual(parsed("3 years"), fixed(2029, 9, 7))
        XCTAssertEqual(parsed("in 2 years"), fixed(2028, 9, 7))
        XCTAssertEqual(parsed("-1y"), fixed(2025, 9, 7), "years back-date like every other unit")
    }

    /// `m` is months. Neither this grammar nor `parseSnoozeDate` has a minutes token, and the help
    /// text says so — the two differ only in that snooze spells months "mo", which is accepted here too.
    func testParserMeansMonthsByMAndTakesTheSnoozeSpellingsToo() {
        XCTAssertEqual(parsed("1m"), parsed("1mo"))
        XCTAssertEqual(parsed("2mo"), fixed(2026, 11, 7))
        XCTAssertEqual(parsed("2wk"), parsed("2w"))
        XCTAssertEqual(parsed("2wks"), fixed(2026, 9, 21))
        XCTAssertEqual(parsed("2yr"), parsed("2y"))
        XCTAssertEqual(parsed("2yrs"), fixed(2028, 9, 7))
    }

    /// Guarding the rules years share a pattern with: a bare number is still a day of the month.
    func testYearsDidNotSwallowTheBareDayNumberOrTheOtherUnits() {
        XCTAssertEqual(parsed("23"), fixed(2026, 9, 23), "a bare number is a day of the month, not a count")
        XCTAssertEqual(parsed("2d"), fixed(2026, 9, 9))
        XCTAssertEqual(parsed("3w"), fixed(2026, 9, 28))
        XCTAssertNil(parsed("2ys"))
        XCTAssertNil(parsed("2ms"))
    }

    func testParserRelativeUnitsGoBackwards() {
        XCTAssertEqual(parsed("-1d"), fixed(2026, 9, 6), "yesterday")
        XCTAssertEqual(parsed("-2w"), fixed(2026, 8, 24))
        XCTAssertEqual(parsed("-1m"), fixed(2026, 8, 7))
        XCTAssertEqual(parsed("-3 days"), fixed(2026, 9, 4))
        XCTAssertEqual(parsed("+2d"), fixed(2026, 9, 9), "an explicit + reads like the bare number")
        XCTAssertEqual(parsed("-0d"), fixed(2026, 9, 7))
    }

    func testParserStillRejectsALoneSign() {
        XCTAssertNil(parsed("-d"))
        XCTAssertNil(parsed("-"))
        XCTAssertNil(parsed("--1d"))
    }

    func testParserWeekdaysAreTheComingOneNeverToday() {
        XCTAssertEqual(parsed("fri"), fixed(2026, 9, 11))
        XCTAssertEqual(parsed("Friday"), fixed(2026, 9, 11))
        XCTAssertEqual(parsed("next fri"), fixed(2026, 9, 11), "'next' reads like the bare weekday")
        XCTAssertEqual(parsed("mon"), fixed(2026, 9, 14), "today is Monday → next Monday")
        XCTAssertEqual(parsed("next monday"), fixed(2026, 9, 14))
        XCTAssertEqual(parsed("sun"), fixed(2026, 9, 13))
    }

    func testParserBareDayOfMonthRollsForward() {
        XCTAssertEqual(parsed("28"), fixed(2026, 9, 28))
        XCTAssertEqual(parsed("28th"), fixed(2026, 9, 28))
        XCTAssertEqual(parsed("7"), fixed(2026, 10, 7), "today's day means next month")
        XCTAssertEqual(parsed("3rd"), fixed(2026, 10, 3))
        XCTAssertEqual(parsed("31"), fixed(2026, 10, 31), "September has no 31st → October")
    }

    func testParserDayAndMonthNames() {
        XCTAssertEqual(parsed("28 sep"), fixed(2026, 9, 28))
        XCTAssertEqual(parsed("sep 28"), fixed(2026, 9, 28))
        XCTAssertEqual(parsed("28th September"), fixed(2026, 9, 28))
        XCTAssertEqual(parsed("Sept 28, 2027"), fixed(2027, 9, 28))
        XCTAssertEqual(parsed("7 sep"), fixed(2026, 9, 7), "an explicit date may be today")
        XCTAssertEqual(parsed("1 jan"), fixed(2027, 1, 1), "already past this year → next year")
        XCTAssertEqual(parsed("30 feb"), nil)
    }

    func testParserNumericDates() {
        XCTAssertEqual(parsed("25/9"), fixed(2026, 9, 25))
        XCTAssertEqual(parsed("25.9"), fixed(2026, 9, 25))
        XCTAssertEqual(parsed("25/9/2027"), fixed(2027, 9, 25))
        XCTAssertEqual(parsed("25/9/27"), fixed(2027, 9, 25))
        XCTAssertEqual(parsed("1/1"), fixed(2027, 1, 1))
        XCTAssertEqual(parsed("9/25"), fixed(2026, 9, 25), "month/day is accepted when day/month can't be")
        XCTAssertEqual(parsed("2026-09-25"), fixed(2026, 9, 25))
        XCTAssertEqual(parsed("2026-12-25"), fixed(2026, 12, 25))
    }

    func testParserRejectsNonsense() {
        for input in ["", "   ", "soonish", "32", "0", "13/13", "in days", "2026-13-01", "next", "2x"] {
            XCTAssertNil(parsed(input), "'\(input)' must not change the date")
        }
    }

    func testParserUnderstandsTheAppLanguage() {
        let spanish = Locale(identifier: "es")
        XCTAssertEqual(parsed("viernes", locale: spanish), fixed(2026, 9, 11))
        XCTAssertEqual(parsed("vie", locale: spanish), fixed(2026, 9, 11))
        XCTAssertEqual(parsed("28 sept", locale: spanish), fixed(2026, 9, 28))
        XCTAssertEqual(parsed("fri", locale: spanish), fixed(2026, 9, 11), "English always works too")
    }

    // MARK: - Live preview beneath the typed field

    private func preview(_ input: String, saved: Date? = nil, settled: Bool = true) -> ToDoDueDatePreview {
        let now = fixedCalendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 10))!
        return ToDoDueDatePreviewResolver.preview(input: input, committedDay: saved, hasSettled: settled,
                                                  now: now, calendar: fixedCalendar, locale: english)
    }

    func testPreviewFollowsTheTypedTextNotTheSavedDate() {
        let saved = fixed(2026, 9, 10)
        XCTAssertEqual(preview("2d", saved: saved), .day(fixed(2026, 9, 9)), "typing replaces the stale date immediately")
        XCTAssertEqual(preview("fri", saved: saved), .day(fixed(2026, 9, 11)))
        XCTAssertEqual(preview("28 sep", saved: saved), .day(fixed(2026, 9, 28)))
    }

    func testPreviewResolvesLiveEvenBeforeTypingSettles() {
        XCTAssertEqual(preview("2d", settled: false), .day(fixed(2026, 9, 9)), "a parse never waits on the settle delay")
    }

    func testPreviewHoldsBackTheHintUntilTypingSettles() {
        let saved = fixed(2026, 9, 10)
        // "28th" is typed through "2", "28", "28t" — none of the drafts may flash the red hint.
        XCTAssertEqual(preview("28t", saved: saved, settled: false), .day(saved))
        XCTAssertEqual(preview("28t", saved: nil, settled: false), .blank)
        XCTAssertEqual(preview("28th", saved: saved, settled: false), .day(fixed(2026, 9, 28)))
    }

    func testPreviewMarksNonsenseOnceTypingSettles() {
        XCTAssertEqual(preview("soonish", saved: fixed(2026, 9, 10)), .unrecognised)
        XCTAssertEqual(preview("2x"), .unrecognised)
        XCTAssertEqual(preview("13/13"), .unrecognised)
    }

    func testPreviewOfAnEmptyFieldFallsBackToTheSavedDate() {
        let saved = fixed(2026, 9, 10)
        XCTAssertEqual(preview("", saved: saved), .day(saved), "clearing shows the existing due date, not an error")
        XCTAssertEqual(preview("   ", saved: saved), .day(saved))
        XCTAssertEqual(preview("", saved: nil), .blank)
    }

    // MARK: - Showing the year outside the current one (report 2026-09-15_20-52-05)

    /// The line under the typed field rendered "Tue 4 Apr" for a 2028 date, so scheduling far out
    /// looked like scheduling this year.
    func testTheResolvedLineShowsTheYearOnlyWhenItIsNotTheCurrentOne() {
        let now = fixed(2026, 9, 7)
        XCTAssertFalse(ToDoDates.weekdayDayMonth(fixed(2026, 12, 31), now: now).contains("2026"),
                       "a day in this year does not repeat the year")
        XCTAssertTrue(ToDoDates.weekdayDayMonth(fixed(2028, 4, 4), now: now).contains("2028"))
        XCTAssertTrue(ToDoDates.weekdayDayMonth(fixed(2027, 1, 1), now: now).contains("2027"),
                      "the very next year counts as outside this one")
        XCTAssertTrue(ToDoDates.weekdayDayMonth(fixed(2025, 4, 4), now: now).contains("2025"),
                      "a past year is just as misleading as a future one")
    }

    /// The list rows already had the rule; this pins that the two surfaces agree.
    func testTheDueLabelAgreesAboutWhenToShowTheYear() {
        let now = fixed(2026, 9, 7)
        let strings = ToDoStrings()
        XCTAssertFalse(strings.dueLabel(ToDoDates.ymd(fixed(2026, 12, 31)), now: now).contains("2026"))
        XCTAssertTrue(strings.dueLabel(ToDoDates.ymd(fixed(2028, 4, 4)), now: now).contains("2028"))
    }

    // MARK: - Sorting / sections

    func testDueDateSortPutsUndatedLast() {
        let sorted = ToDoSorting.sort([task("late", due: day(5)), task("none"), task("soon", due: day(1))], by: .dueDate)
        XCTAssertEqual(sorted.map { $0.id }, ["soon", "late", "none"])
    }

    func testChronologicalSortIsNewestFirst() {
        let sorted = ToDoSorting.sort([task("old", created: "2026-01-01T00:00:00.000Z"), task("new", created: "2026-02-01T00:00:00.000Z")], by: .chronological)
        XCTAssertEqual(sorted.map { $0.id }, ["new", "old"])
    }

    func testSmartSortIsHighestScoreFirst() {
        let sorted = ToDoSorting.sort([task("low", topScore: 1), task("high", topScore: 9)], by: .smart)
        XCTAssertEqual(sorted.map { $0.id }, ["high", "low"])
    }

    func testAliasedCustomColumnsFoldIntoDefaultSections() {
        let project = Project(id: "p", name: "P", description: nil, owner_id: nil,
                              custom_statuses: [ProjectCustomStatus(id: "s-todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                                                ProjectCustomStatus(id: "s-review", label: "Review", color: nil, order: 1, should_complete_task: false)],
                              icon: nil, members: nil, task_count: nil, uncompleted_task_count: nil, synced_project_id: nil, due_date: nil,
                              importance: nil, status: nil, created_at: nil, updated_at: nil)
        let tasks = [task("a", status: .inProgress), task("b", customStatusId: "s-todo", projectId: "p"), task("c", customStatusId: "s-review", projectId: "p")]
        let sections = ToDoSectioning.build(tasks: tasks, projects: [project], sortMode: .smart,
                                            sectionTitles: [.inProgress: "Doing", .notStarted: "To do", .completed: "Done"])
        XCTAssertEqual(sections.map { $0.id }, ["IN_PROGRESS", "NOT_STARTED", "COMPLETED", "custom__review"])
        XCTAssertEqual(sections[1].tasks.map { $0.id }, ["b"], "'To Do' is an alias of the default To do section")
        XCTAssertEqual(sections[3].tasks.map { $0.id }, ["c"])
        XCTAssertEqual(sections[3].title, "Review")
    }

    // MARK: - Section header counts

    func testHeaderCountKeepsTheServerTotalForRowsStillBehindPaging() {
        // "To do 145" with only the first page of 50 fetched still reads 145.
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 50, serverItemCount: 145, rowsReceived: 50), 145)
    }

    func testHeaderCountDropsATaskSectionedIntoAnotherColumn() {
        // The reported bug: the one IN_PROGRESS task sits in a project column called "Review", so
        // it renders under Review, not Doing. Doing must read 0, not "1" above "No tasks here".
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 0, serverItemCount: 1, rowsReceived: 1), 0)
    }

    func testHeaderCountDropsAnUndecodableRow() {
        // The server sent the row and we couldn't read it — it will never appear, so don't count it.
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 0, serverItemCount: 1, rowsReceived: 1), 0)
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 2, serverItemCount: 3, rowsReceived: 3), 2)
    }

    func testHeaderCountCountsRowsGainedFromOtherBuckets() {
        // A task fetched as IN_PROGRESS but sectioned into To do makes To do genuinely one longer.
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 51, serverItemCount: 145, rowsReceived: 50), 146)
    }

    func testHeaderCountFallsBackToRenderedRowsWithoutAServerTotal() {
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 4, serverItemCount: nil, rowsReceived: 0), 4)
    }

    func testHeaderCountNeverGoesNegativeWhenMoreArrivedThanPromised() {
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 3, serverItemCount: 1, rowsReceived: 3), 3)
    }

    func testLocalBucketMoveKeepsTheHeaderCountExact() {
        // Ticking a task moves it Doing → Done. Both totals must move together, or the Done header
        // gains one more than the row it just received.
        var done = ToDoStatusPaging(page: 1, hasNextPage: true, itemCount: 4550, receivedCount: 50)
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 50, serverItemCount: done.itemCount, rowsReceived: done.receivedCount), 4550)
        done.adjustForLocalChange(by: 1)
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 51, serverItemCount: done.itemCount, rowsReceived: done.receivedCount), 4551)

        var doing = ToDoStatusPaging(page: 1, hasNextPage: false, itemCount: 1, receivedCount: 1)
        doing.adjustForLocalChange(by: -1)
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: 0, serverItemCount: doing.itemCount, rowsReceived: doing.receivedCount), 0)
    }

    func testLocalChangeNeverDrivesAPagingTotalNegative() {
        var paging = ToDoStatusPaging(page: 1, hasNextPage: false, itemCount: 0, receivedCount: 0)
        paging.adjustForLocalChange(by: -1)
        XCTAssertEqual(paging.itemCount, 0)
        XCTAssertEqual(paging.receivedCount, 0)
    }

    func testPageReportsEveryRowItReceivedIncludingUndecodableOnes() throws {
        let json = """
        {"data":[{"id":"a","title":"A","status":"IN_PROGRESS","eisenhower_quadrant":1},{"nonsense":true}],
         "meta":{"page":1,"itemCount":2,"hasNextPage":false}}
        """
        let page = try JSONDecoder().decode(ToDoPage.self, from: Data(json.utf8))
        XCTAssertEqual(page.data.count, 1, "the unreadable row is dropped")
        XCTAssertEqual(page.receivedRowCount, 2, "but it still counts as delivered")
        XCTAssertEqual(ToDoSectionCount.headerCount(rendered: page.data.count, serverItemCount: page.meta?.itemCount,
                                                    rowsReceived: page.receivedRowCount), 1)
    }

    func testFiltersProjectEnergyAndDueRange() {
        var filters = ToDoFilters()
        filters.projectId = "p"
        XCTAssertTrue(filters.matches(task("a", projectId: "p")))
        XCTAssertTrue(filters.matches(task("b", tags: [ToDoTag(id: "p", text: "P")])))
        XCTAssertFalse(filters.matches(task("c")))
        filters = ToDoFilters()
        filters.energyLevel = .low
        XCTAssertTrue(filters.matches(task("d", perspiration: 3)))
        XCTAssertFalse(filters.matches(task("e", perspiration: 4)))
        filters = ToDoFilters()
        filters.dueDateStart = today
        filters.dueDateEnd = day(6)
        XCTAssertTrue(filters.matches(task("f", due: day(6))))
        XCTAssertFalse(filters.matches(task("g", due: day(7))))
        XCTAssertFalse(filters.matches(task("h")))
    }

    /// Report 2026-09-15_17-41-45. A task ticked off from the Day Plan, the To-do list, the routine
    /// player or another device keeps whatever open column it was in — `status` is the only thing
    /// that changes. `ToDoSectioning.build` and `ProjectKanban.columnId` both draw those as done, so
    /// this rule, which everything else reads completion from, has to agree with them.
    func testCompletionReadsStatusFirstSoWorkTickedOffElsewhereStillCountsAsDone() {
        let statuses = [ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                        ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 1, should_complete_task: true)]
        let completing = ToDoCompletionState.completingStatusIds(in: [Project(id: "p", name: "P", custom_statuses: statuses)])
        XCTAssertEqual(completing, ["done"])

        let tickedElsewhere = task("a", status: .completed, customStatusId: "todo")
        XCTAssertTrue(ToDoCompletionState.isFinished(tickedElsewhere, customStatuses: statuses))
        XCTAssertTrue(ToDoCompletionState.isFinished(tickedElsewhere, completingStatusIds: completing))

        XCTAssertTrue(ToDoCompletionState.isFinished(task("b", customStatusId: "done"), customStatuses: statuses))
        XCTAssertFalse(ToDoCompletionState.isFinished(task("c", customStatusId: "todo"), customStatuses: statuses))
        XCTAssertFalse(ToDoCompletionState.isFinished(task("d"), customStatuses: statuses))
        XCTAssertTrue(ToDoCompletionState.isFinished(task("e", status: .completed), customStatuses: []))
        XCTAssertFalse(ToDoCompletionState.isFinished(task("f", customStatusId: "done"), customStatuses: []),
                       "An unknown column is no evidence either way; the status decides")
    }

    /// Report 2026-09-15_17-41-45, follow-up: "hang on - why are tasks remaining in ToDo when they
    /// were completed? Day plan needs to update the status properly."
    ///
    /// Completing outside the project board has to move the card too, or the task keeps the open
    /// column it was in and every other client still reads it as outstanding.
    func testCompletingOutsideTheBoardMovesTheTaskIntoTheProjectsCompletingColumn() {
        let columns = [ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                       ProjectCustomStatus(id: "review", label: "Review", color: nil, order: 1, should_complete_task: false),
                       ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 2, should_complete_task: true)]
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: "todo", customStatuses: columns), .move(to: "done"))
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: nil, customStatuses: columns), .move(to: "done"))
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: "done", customStatuses: columns), .leaveAlone,
                       "Already there: nothing to write")
        // Several completing columns: the first by order, matching the kanban checkbox.
        let twoDone = columns + [ProjectCustomStatus(id: "shipped", label: "Shipped", color: nil, order: 3, should_complete_task: true)]
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: "todo", customStatuses: twoDone), .move(to: "done"))
        // Unordered input must not change the answer.
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: "todo", customStatuses: twoDone.reversed()), .move(to: "done"))
    }

    /// A project with no completing column must not end up worse off than before: parking a finished
    /// task in a column the server reads as open is the bug, not the fix.
    func testAProjectWithNoCompletingColumnKeepsTheTaskWhereItIs() {
        let noDone = [ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                      ProjectCustomStatus(id: "later", label: "Later", color: nil, order: 1, should_complete_task: false)]
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: "todo", customStatuses: noDone), .leaveAlone)
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: false, currentColumnID: "later", customStatuses: noDone), .leaveAlone)
        // No project, or a project without custom columns at all.
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: nil, customStatuses: []), .leaveAlone)
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: true, currentColumnID: "stale", customStatuses: []), .leaveAlone)
    }

    /// Re-opening has to undo the move, or the task sits in "Done" with a NOT_STARTED status — the
    /// same inconsistency mirrored, and one the server would read as finished.
    func testReopeningMovesBackOutOfADoneColumnButNeverOutOfAnOpenOne() {
        let columns = [ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                       ProjectCustomStatus(id: "doing", label: "In Progress", color: nil, order: 1, should_complete_task: false),
                       ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 2, should_complete_task: true)]
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: false, currentColumnID: "done", customStatuses: columns), .move(to: "todo"))
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: false, currentColumnID: "doing", customStatuses: columns), .leaveAlone,
                       "An un-tick must not drag a task out of In Progress")
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: false, currentColumnID: "todo", customStatuses: columns), .leaveAlone)
        XCTAssertEqual(ToDoCompletionState.columnWrite(completed: false, currentColumnID: nil, customStatuses: columns), .leaveAlone)
    }

    func testStatusToggleUsesProjectDoneColumn() {
        let statuses = [ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                        ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 1, should_complete_task: true)]
        let completed = ToDoStatusToggle.apply(to: task("a", customStatusId: "todo"), completed: true, customStatuses: statuses)
        XCTAssertEqual(completed.status, "COMPLETED")
        XCTAssertEqual(completed.custom_status_id, "done")
        let reopened = ToDoStatusToggle.apply(to: completed, completed: false, customStatuses: statuses)
        XCTAssertEqual(reopened.status, "NOT_STARTED")
        XCTAssertEqual(reopened.custom_status_id, "todo")
        let plain = ToDoStatusToggle.apply(to: task("b"), completed: true, customStatuses: [])
        XCTAssertEqual(plain.status, "COMPLETED")
        XCTAssertNil(plain.custom_status_id)
        // Web parity: a task without a column id still moves into the project's done column.
        let legacy = ToDoStatusToggle.apply(to: task("c"), completed: true, customStatuses: statuses)
        XCTAssertEqual(legacy.custom_status_id, "done")
        // A project with NO completing column keeps the task where it is rather than taking web's
        // "else the last column" fallback: that column is one the server reads as open, so writing it
        // would mark a finished task outstanding (report 2026-09-15_17-41-45). `ProjectKanban.columnId`
        // still renders a COMPLETED task under the done column, so the card does not move either way.
        let noDone = statuses.map { ProjectCustomStatus(id: $0.id, label: $0.label, color: nil, order: $0.order, should_complete_task: false) }
        let completedWithoutDoneColumn = ToDoStatusToggle.apply(to: task("d", customStatusId: "todo"), completed: true, customStatuses: noDone)
        XCTAssertEqual(completedWithoutDoneColumn.custom_status_id, "todo")
        XCTAssertEqual(completedWithoutDoneColumn.status, "COMPLETED")
        XCTAssertEqual(ProjectKanban.columnId(for: completedWithoutDoneColumn,
                                              columns: ProjectKanban.columns(for: Project(id: "p", name: "P", custom_statuses: noDone), defaultLabels: [:]),
                                              usesCustomStatuses: true), "done", "Still rendered under the done column")
        XCTAssertNil(ToDoStatusToggle.apply(to: task("e"), completed: true, customStatuses: noDone).custom_status_id)
        XCTAssertEqual(ToDoStatusToggle.apply(to: task("d", status: .completed, customStatusId: "done"), completed: false, customStatuses: noDone).custom_status_id, "todo")
    }

    func testBoardTaskAssigneeResolvesFromTheRelationBeforeAWrite() {
        // `GET /to-do` sends the assignee as a relation and no flat `assignee_id` (backend#2414), so a
        // task off the project board has the flat field nil. Every kanban drag and checkbox toggle
        // writes through `ToDoUpsertBody.make`, where nil means "unassign" — so without resolving the
        // two shapes first, each one silently unassigned the task. This is the resolution
        // `ProjectDetailStore.persist` applies; `make` itself must keep nil meaning unassigned.
        XCTAssertEqual(ToDoAssigneeChoices.assigneeId(flat: nil, relation: "user-7"), "user-7")
        XCTAssertEqual(ToDoAssigneeChoices.assigneeId(flat: "flat", relation: "user-7"), "flat")
        XCTAssertNil(ToDoAssigneeChoices.assigneeId(flat: nil, relation: nil),
                     "genuinely unassigned must stay nil, or Unassigned could never be chosen")
    }

    func testUpsertBodySendsNullToClearProject() {
        var t = task("a", due: day(1), outcome: 5, perspiration: 2)
        t.subtasks = [ToDoSubtask(name: "s", is_completed: true)]
        let body = ToDoUpsertBody.make(from: t)
        XCTAssertEqual(body["id"] as? String, "a")
        XCTAssertTrue(body["project_id"] is NSNull)
        XCTAssertTrue(body["custom_status_id"] is NSNull)
        XCTAssertEqual((body["subtasks"] as? [[String: Any]])?.first?["name"] as? String, "s")
        XCTAssertEqual(body["due_date"] as? String, ToDoDates.ymd(day(1)))
        XCTAssertNil(body["top_score"], "read-only fields are never sent")
        var cleared = t
        cleared.due_date = nil
        XCTAssertTrue(ToDoUpsertBody.make(from: cleared)["due_date"] is NSNull, "an explicit null clears the due date")
    }

    /// The create payload with a project must match the web's `handleSubmit`: the project as a
    /// `{ id, text }` tag, `project_id` a UUID, no `synced_project_id`, and nothing the DTO would
    /// reject (`due_date` a date string, quadrant 1…4, levels 1…10).
    func testCreateBodyWithProjectMatchesWeb() {
        let project = self.project(owner: "o", members: [])
        var draft = ToDoDraft.newTask(title: "Paint the room", project: project, now: today)
        draft.tags = [ToDoTag(id: project.id, text: project.name)]
        let body = ToDoUpsertBody.make(from: draft)
        let tags = body["tags"] as? [[String: Any]]
        XCTAssertEqual(tags?.count, 1)
        XCTAssertEqual(tags?.first?["id"] as? String, "p")
        XCTAssertEqual(tags?.first?["text"] as? String, "P")
        XCTAssertEqual(Set(tags?.first?.keys.map { $0 } ?? []), ["id", "text"], "a tag is exactly { id, text } like the web's Tag")
        XCTAssertEqual(body["project_id"] as? String, "p")
        XCTAssertNil(body["synced_project_id"])
        XCTAssertNil(body["top_score"])
        XCTAssertEqual(body["due_date"] as? String, ToDoDates.ymd(day(1)))
        XCTAssertEqual(body["eisenhower_quadrant"] as? Int, 1, "the hidden quadrant still defaults to Do")
        XCTAssertEqual(body["status"] as? String, "NOT_STARTED")
        XCTAssertTrue(body["custom_status_id"] is NSNull, "no custom columns → null, as the web sends")
        for key in ["id", "title", "details", "objective", "tags", "subtasks", "duration", "outcome", "perspiration_level"] {
            XCTAssertNotNil(body[key], "\(key) is part of every write")
        }
    }

    // MARK: - Editor drafts

    func testNewTaskDraftPreselectsTheProjectFromTheObject() {
        let statuses = [ProjectCustomStatus(id: "review", label: "Review", color: nil, order: 1, should_complete_task: false),
                        ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false)]
        let project = self.project(owner: "o", members: [], statuses: statuses)
        let draft = ToDoDraft.newTask(title: "T", project: project, now: today)
        XCTAssertEqual(draft.tagList, [ToDoTag(id: "p", text: "P")], "selected chip comes from the object, not a catalogue lookup")
        XCTAssertEqual(draft.project_id, "p")
        XCTAssertEqual(draft.custom_status_id, "todo", "starts in the project's first column")
        XCTAssertEqual(draft.due_date, ToDoDates.ymd(day(1)))
        XCTAssertEqual(draft.eisenhower_quadrant, 1)
        let plain = ToDoDraft.newTask(title: "T", project: self.project(owner: "o", members: []), now: today)
        XCTAssertNil(plain.custom_status_id, "no custom columns → default statuses")
        let none = ToDoDraft.newTask(title: "T", now: today)
        XCTAssertTrue(none.tagList.isEmpty)
        XCTAssertNil(none.project_id)
    }

    func testEditableDraftNormalisesServerFields() {
        var t = task("a", due: day(2))
        t.due_date = "2026-09-09T00:00:00.000Z"
        t.details = "<p>Hello&nbsp;<b>world</b></p>"
        let draft = ToDoDraft.editable(t)
        XCTAssertEqual(draft.due_date, ToDoDates.ymd(ToDoDates.parse("2026-09-09T00:00:00.000Z")!))
        XCTAssertNil(draft.outcome, "Opening an unrated task must not assign an outcome")
        XCTAssertEqual(draft.perspiration_level, ToDoScoring.defaultPerspiration)
        XCTAssertEqual(draft.details, "Hello world")
    }

    // MARK: - Server error bodies

    func testServerErrorMessageShapes() {
        func body(_ json: String) -> Data { json.data(using: .utf8)! }
        XCTAssertEqual(ToDoServerError.message(from: body(#"{"statusCode":400,"message":"Project with id x not found"}"#)), "Project with id x not found")
        XCTAssertEqual(ToDoServerError.message(from: body(#"{"message":["title should not be empty","due_date must be a Date instance"]}"#)),
                       "title should not be empty; due_date must be a Date instance")
        let validationErrors = #"{"message":[{"property":"project_id","constraints":{"isUuid":"project_id must be a UUID"}},{"property":"tags","constraints":{"isArray":"tags must be an array"}}]}"#
        XCTAssertEqual(ToDoServerError.message(from: body(validationErrors)), "project_id must be a UUID; tags must be an array")
        XCTAssertNil(ToDoServerError.message(from: body(#"{"message":""}"#)))
        XCTAssertNil(ToDoServerError.message(from: body(#"{"error":"Bad Request"}"#)))
        XCTAssertNil(ToDoServerError.message(from: nil))
        XCTAssertEqual(ToDoStore.failureText("Could not create task", reason: "Project not found"), "Could not create task: Project not found")
        XCTAssertEqual(ToDoStore.failureText("Could not create task", reason: nil), "Could not create task")
    }

    /// The API's auth layer answers `text/plain`, so a 401 used to leave the toast with no reason
    /// and the debug log with no evidence (report 2026-09-16_15-14-36).
    func testServerErrorMessageReadsPlainTextRejections() {
        func body(_ text: String) -> Data { text.data(using: .utf8)! }
        XCTAssertEqual(ToDoServerError.message(from: body("Token missing or corrupted!")), "Token missing or corrupted!")
        XCTAssertEqual(ToDoServerError.message(from: body("  Unauthorized\n")), "Unauthorized")
        XCTAssertNil(ToDoServerError.message(from: body("   ")), "Whitespace is not a reason")
        XCTAssertNil(ToDoServerError.message(from: body("<html><body>502 Bad Gateway</body></html>")),
                     "A proxy's HTML page is not a reason to show a user")
        XCTAssertNil(ToDoServerError.message(from: body(String(repeating: "x", count: 500))),
                     "An overlong body is not a reason to show a user")
    }

    // MARK: - Editor: every edit counts (report 2026-09-16_15-14-36)

    private static func editorBaseline() -> ToDoEditorSnapshot {
        var draft = ToDoTask(id: "t1", title: "Widgets and Dynamic Island Design",
                             status: ToDoStatus.notStarted.rawValue, created_at: "")
        draft.assignee_id = "user-a"
        return ToDoEditorSnapshot(draft: draft, selectedProjectIds: ["p1"], statusOwnerProjectId: "p1",
                                  durationMinutesText: "15", pendingSubtask: "")
    }

    /// One mutation per editable field of the snapshot. `testEveryEditorFieldIsCovered` fails if a
    /// field is added to `ToDoEditorSnapshot` without a case here, so the next field cannot quietly
    /// stop counting as an edit.
    private static let editorFieldMutations: [String: (inout ToDoEditorSnapshot) -> Void] = [
        "draft": { $0.draft.title = "Renamed" },
        "selectedProjectIds": { $0.selectedProjectIds = ["p1", "p2"] },
        "statusOwnerProjectId": { $0.statusOwnerProjectId = "p2" },
        "durationMinutesText": { $0.durationMinutesText = "30" },
        "pendingSubtask": { $0.pendingSubtask = "Draft the widget sizes" },
    ]

    func testEveryEditorFieldMarksTheSheetEdited() {
        let baseline = Self.editorBaseline()
        for (field, mutate) in Self.editorFieldMutations {
            var edited = baseline
            mutate(&edited)
            XCTAssertNotEqual(edited, baseline, "Editing \(field) must count as an unsaved change")
        }
    }

    func testEveryEditorFieldIsCovered() {
        let fields = Set(Mirror(reflecting: Self.editorBaseline()).children.compactMap { $0.label })
        XCTAssertEqual(fields, Set(Self.editorFieldMutations.keys),
                       "A field was added to ToDoEditorSnapshot without a case proving it counts as an edit")
    }

    /// The reported field, named on its own so a regression says which one broke.
    func testChangingOnlyTheAssigneeMarksTheSheetEdited() {
        let baseline = Self.editorBaseline()
        var edited = baseline
        edited.draft.assignee_id = "user-b"
        XCTAssertNotEqual(edited, baseline)
        edited.draft.assignee_id = nil
        XCTAssertNotEqual(edited, baseline, "Clearing the assignee is an edit too")
    }

    func testAnUntouchedSheetIsNotEdited() {
        XCTAssertEqual(Self.editorBaseline(), Self.editorBaseline())
    }

    // MARK: - The assignee survives a round-trip (report 2026-09-16_15-14-36 follow-up)

    /// A `GET /to-do` row exactly as production returns it: the assignee is a relation and there is
    /// no `assignee_id` key at all. Captured from the user's own account while diagnosing the report.
    private static let assignedTaskJSON = """
    {"id":"c4ac2cdb-9bed-45e2-8a19-ef7802e76dc9",
     "title":"Allow tracking progress towards goals. Habits link to goals",
     "status":"NOT_STARTED","created_at":"2026-06-26T00:00:00.000Z",
     "assignee":{"id":"b86e3f05-fec7-49d7-ad9f-a76fee762d32","username":null}}
    """

    private static func decodeAssignedTask() throws -> ToDoTask {
        try JSONDecoder().decode(ToDoTask.self, from: Data(assignedTaskJSON.utf8))
    }

    func testEditorResolvesTheAssigneeFromTheRelationWhenThereIsNoFlatId() throws {
        let fetched = try Self.decodeAssignedTask()
        XCTAssertNil(fetched.assignee_id, "Production really does omit the flat key")
        let draft = ToDoDraft.editable(fetched)
        XCTAssertEqual(draft.assignee_id, "b86e3f05-fec7-49d7-ad9f-a76fee762d32",
                       "Re-opening an assigned task must not show it as Unassigned")
    }

    /// The damaging half: the editor sends `assignee_id` on every save, so an unresolved nil silently
    /// unassigned the task the moment anyone opened it and pressed Save.
    func testSavingAnUntouchedAssignedTaskKeepsItsAssignee() throws {
        let draft = ToDoDraft.editable(try Self.decodeAssignedTask())
        let body = ToDoUpsertBody.make(from: draft)
        XCTAssertEqual(body["assignee_id"] as? String, "b86e3f05-fec7-49d7-ad9f-a76fee762d32")
    }

    func testAFlatAssigneeIdStillWins() {
        var task = ToDoTask(id: "t1", title: "T", status: ToDoStatus.notStarted.rawValue, created_at: "")
        task.assignee_id = "flat"
        task.assignee = ToDoAssignee(id: "relation", username: nil, email: nil)
        XCTAssertEqual(ToDoDraft.editable(task).assignee_id, "flat")
    }

    func testClearingTheAssigneeStillSendsAnExplicitNull() {
        var draft = ToDoDraft.editable((try? Self.decodeAssignedTask()) ?? ToDoTask(id: "t", title: "T", status: "", created_at: ""))
        draft.assignee_id = nil
        XCTAssertTrue(ToDoUpsertBody.make(from: draft)["assignee_id"] is NSNull,
                      "Choosing Unassigned must still clear it server-side")
    }

    /// Nothing in this app can read or set the MCP token, and the server never returns it, so nil
    /// only ever means "this client never knew" — sending null wiped an agent's claim on the task.
    func testAnUnknownMcpTokenIsLeftAloneRatherThanNulled() throws {
        let draft = ToDoDraft.editable(try Self.decodeAssignedTask())
        XCTAssertNil(draft.assigned_mcp_token_id)
        XCTAssertNil(ToDoUpsertBody.make(from: draft)["assigned_mcp_token_id"],
                     "An unknown MCP token must be omitted, not cleared")
    }

    func testAKnownMcpTokenIsStillSent() {
        var task = ToDoTask(id: "t1", title: "T", status: ToDoStatus.notStarted.rawValue, created_at: "")
        task.assigned_mcp_token_id = "token-1"
        XCTAssertEqual(ToDoUpsertBody.make(from: task)["assigned_mcp_token_id"] as? String, "token-1")
    }

    // MARK: - Models

    func testPageKeepsRowsMissingTitleOrCreatedAt() throws {
        // `GET /to-do?sort_mode=DUE_DATE` has returned a completed row with no `title`; the whole
        // bucket used to fail to decode and every refresh toasted "Could not process the request".
        let json = """
        {"data":[{"id":"a","status":"COMPLETED","created_at":"2023-08-05T06:01:28.120Z"},
                 {"id":"b","title":null,"status":"NOT_STARTED","created_at":"2026-01-01T00:00:00.000Z"},
                 {"id":"c","title":"Fine","status":"NOT_STARTED"},
                 "not-a-row"],
         "meta":{"itemCount":4,"hasNextPage":false}}
        """.data(using: .utf8)!
        let page = try JSONDecoder().decode(ToDoPage.self, from: json)
        XCTAssertEqual(page.data.map { $0.id }, ["a", "b", "c"], "a row that isn't an object is dropped, the rest survive")
        XCTAssertEqual(page.data[0].title, "")
        XCTAssertEqual(page.data[1].title, "")
        XCTAssertEqual(page.data[2].created_at, "", "a create response has no created_at either")
        XCTAssertEqual(page.meta?.itemCount, 4)
        let single = try JSONDecoder().decode(ToDoTask.self, from: #"{"id":"d","status":"NOT_STARTED"}"#.data(using: .utf8)!)
        XCTAssertEqual(single.title, "")
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(single)) as? [String: Any]
        XCTAssertEqual(encoded?["title"] as? String, "", "encodes as a plain string")
    }

    func testLenientDurationAndHexIcon() throws {
        let json = """
        {"id":"x","title":"T","status":"NOT_STARTED","created_at":"2026-01-01T00:00:00.000Z","duration":"300","icon":"1f600"}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ToDoTask.self, from: json)
        XCTAssertEqual(decoded.durationSeconds, 300)
        XCTAssertEqual(decoded.iconEmoji, "😀")
        var glyph = decoded
        glyph.icon = "🐻"
        XCTAssertEqual(glyph.iconEmoji, "🐻")
    }

    func testSyncedProjectIdsAreNeverShownBare() {
        XCTAssertTrue(ToDoStrings.looksLikeIdentifier("22170000000022013"))
        XCTAssertTrue(ToDoStrings.looksLikeIdentifier("639c1fd9cb32760060b9b298"))
        XCTAssertFalse(ToDoStrings.looksLikeIdentifier("Focus Bear"))
        XCTAssertFalse(ToDoStrings.looksLikeIdentifier("B2B Marketing"))
        XCTAssertFalse(ToDoStrings.looksLikeIdentifier("deadbeefcafe"), "letters-only hex words are names")
        let strings = ToDoStrings()
        XCTAssertEqual(strings.projectName("22170000000022013"), "Synced project …2013")
        XCTAssertEqual(strings.projectName("Focus Bear"), "Focus Bear")
    }

    // MARK: - Completion banner batching

    func testCompletionBannerBatchesRapidCompletions() {
        let t0 = Date()
        let first = ToDoCompletionBatch.recording("A", into: nil, phrase: "Woah", now: t0)
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(first.lastTitle, "A")
        let second = ToDoCompletionBatch.recording("B", into: first, phrase: "Cool", now: t0.addingTimeInterval(2))
        XCTAssertEqual(second.count, 2, "a completion within the lifetime joins the batch")
        XCTAssertEqual(second.phrase, "Woah", "the batch keeps its first phrase")
        XCTAssertEqual(second.expiresAt, t0.addingTimeInterval(2 + ToDoCompletionBatch.lifetime), "each completion restarts the clock")
        let afterExpiry = ToDoCompletionBatch.recording("C", into: second, phrase: "Cool", now: second.expiresAt.addingTimeInterval(1))
        XCTAssertEqual(afterExpiry.count, 1, "an expired batch starts over")
        XCTAssertEqual(afterExpiry.phrase, "Cool")
    }

    func testCompletionBannerUncompleteDecrementsAndHides() {
        let t0 = Date()
        var batch = ToDoCompletionBatch.recording("A", into: nil, phrase: "Woah", now: t0)
        batch = ToDoCompletionBatch.recording("B", into: batch, phrase: "Woah", now: t0)
        let decremented = batch.uncompleting(at: t0.addingTimeInterval(1))
        XCTAssertEqual(decremented?.count, 1)
        XCTAssertNil(decremented?.uncompleting(at: t0.addingTimeInterval(1)), "taking back the last completion hides the banner")
        XCTAssertNil(batch.uncompleting(at: batch.expiresAt.addingTimeInterval(1)), "nothing to take back once expired")
    }

    func testCompletionBannerWording() {
        let strings = ToDoStrings()
        let single = ToDoCompletionBatch(phrase: "Woah", lastTitle: "Write report", count: 1, expiresAt: Date())
        XCTAssertEqual(ToDoStore.bannerText(single, strings: strings), "Woah, 'Write report' completed!")
        let many = ToDoCompletionBatch(phrase: "Woah", lastTitle: "Write report", count: 3, expiresAt: Date())
        XCTAssertEqual(ToDoStore.bannerText(many, strings: strings), "Woah, you're on a roll! 3 tasks completed")
    }

    // MARK: - Project permissions / kanban

    private func project(owner: String, members: [(String, ProjectMemberRole)], statuses: [ProjectCustomStatus] = []) -> Project {
        Project(id: "p", name: "P", description: nil, owner_id: owner,
                custom_statuses: statuses, icon: nil,
                members: members.map { ProjectMember(id: "m-\($0.0)", user_id: $0.0, email: "\($0.0)@x.io", role: $0.1.rawValue, invitation_status: "accepted") },
                task_count: nil, uncompleted_task_count: nil, synced_project_id: nil, due_date: nil, importance: nil, status: nil,
                created_at: nil, updated_at: nil)
    }

    func testViewerRoleAndHeaderPermissions() {
        let p = project(owner: "o", members: [("a", .admin), ("m", .member)])
        XCTAssertEqual(ProjectPermissions.viewerRole(in: p, userId: "o"), .owner, "owner_id wins when there is no member row")
        XCTAssertEqual(ProjectPermissions.viewerRole(in: p, userId: "a"), .admin)
        XCTAssertNil(ProjectPermissions.viewerRole(in: p, userId: "stranger"))
        XCTAssertTrue(ProjectPermissions.canViewSettings(.admin))
        XCTAssertFalse(ProjectPermissions.canViewSettings(.member))
        XCTAssertFalse(ProjectPermissions.canLeave(.owner))
        XCTAssertTrue(ProjectPermissions.canLeave(.member))
        XCTAssertTrue(ProjectPermissions.canEditName(.owner))
        XCTAssertFalse(ProjectPermissions.canEditName(.admin))
    }

    func testMemberActionMatrix() {
        let ownerOnAdmin = ProjectPermissions.memberActions(viewer: .owner, target: .admin, isTargetCurrentUser: false)
        XCTAssertEqual(ownerOnAdmin, .init(canInvite: true, canRemove: true, canChangeRole: true))
        let adminOnAdmin = ProjectPermissions.memberActions(viewer: .admin, target: .admin, isTargetCurrentUser: false)
        XCTAssertEqual(adminOnAdmin, .init(canInvite: true, canRemove: false, canChangeRole: false))
        let adminOnMember = ProjectPermissions.memberActions(viewer: .admin, target: .member, isTargetCurrentUser: false)
        XCTAssertEqual(adminOnMember, .init(canInvite: true, canRemove: true, canChangeRole: true))
        let anyoneOnOwner = ProjectPermissions.memberActions(viewer: .owner, target: .owner, isTargetCurrentUser: false)
        XCTAssertEqual(anyoneOnOwner, .init(canInvite: true, canRemove: false, canChangeRole: false))
        let onSelf = ProjectPermissions.memberActions(viewer: .owner, target: .owner, isTargetCurrentUser: true)
        XCTAssertFalse(onSelf.canRemove)
        let member = ProjectPermissions.memberActions(viewer: .member, target: .member, isTargetCurrentUser: false)
        XCTAssertEqual(member, .init(canInvite: false, canRemove: false, canChangeRole: false))
    }

    // MARK: - Re-sending a project invitation (report 2026-09-15_20-37-45)

    private func member(status: ProjectInvitationStatus, sentAt: String? = nil) -> ProjectMember {
        ProjectMember(id: "m", user_id: nil, email: "kayla@x.io", role: ProjectMemberRole.member.rawValue,
                      invitation_status: status.rawValue, invitation_sent_at: sentAt, invitation_responded_at: nil)
    }

    func testResendIsOnlyOfferedForAnOutstandingInvitation() {
        XCTAssertTrue(ProjectInvitationResend.canResend(viewer: .owner, status: .pending))
        XCTAssertTrue(ProjectInvitationResend.canResend(viewer: .owner, status: .failed),
                      "A failed send is exactly what resending is for")
        XCTAssertFalse(ProjectInvitationResend.canResend(viewer: .owner, status: .accepted),
                       "An accepted member has nothing to re-send — the server 400s on it")
        XCTAssertFalse(ProjectInvitationResend.canResend(viewer: .owner, status: .declined),
                       "They answered; re-sending would be nagging")
    }

    func testResendIsOnlyOfferedToSomeoneWhoCouldHaveInvited() {
        XCTAssertTrue(ProjectInvitationResend.canResend(viewer: .admin, status: .pending))
        XCTAssertFalse(ProjectInvitationResend.canResend(viewer: .member, status: .pending))
        XCTAssertFalse(ProjectInvitationResend.canResend(viewer: nil, status: .pending))
    }

    func testResendWaitsOutTheCooldownSinceTheLastSend() {
        let now = Date(timeIntervalSince1970: 1_789_000_000)
        let justSent = now.addingTimeInterval(-1)
        let longAgo = now.addingTimeInterval(-ProjectInvitationResend.cooldownSeconds - 1)
        XCTAssertFalse(ProjectInvitationResend.cooldownElapsed(sentAt: justSent, now: now))
        XCTAssertTrue(ProjectInvitationResend.cooldownElapsed(sentAt: longAgo, now: now))
        XCTAssertTrue(ProjectInvitationResend.cooldownElapsed(sentAt: nil, now: now),
                      "An invitation with no recorded send time is sendable")
    }

    func testResendReadsTheServersOwnSentTimestamp() {
        let sent = member(status: .pending, sentAt: "2026-09-15T10:00:00.000Z")
        XCTAssertEqual(ProjectInvitationResend.lastSentAt(sent),
                       ToDoDates.parse("2026-09-15T10:00:00.000Z"))
        XCTAssertNil(ProjectInvitationResend.lastSentAt(member(status: .pending)))
    }

    func testFailedInvitationsAreNoLongerMisreadAsDeclined() {
        XCTAssertEqual(member(status: .failed).invitationStatus, .failed)
        XCTAssertEqual(member(status: .pending).invitationStatus, .pending)
        XCTAssertEqual(ProjectMember(id: "m", user_id: nil, email: nil, role: nil, invitation_status: "nonsense",
                                     invitation_sent_at: nil, invitation_responded_at: nil).invitationStatus, .declined,
                       "Anything unrecognised still falls back to declined")
    }

    func testKanbanColumnsAndMoves() {
        let statuses = [ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 2, should_complete_task: true),
                        ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                        ProjectCustomStatus(id: "doing", label: "Doing", color: nil, order: 1, should_complete_task: false)]
        let p = project(owner: "o", members: [], statuses: statuses)
        let columns = ProjectKanban.columns(for: p, defaultLabels: [:])
        XCTAssertEqual(columns.map { $0.id }, ["todo", "doing", "done"], "columns follow `order`")
        // Legacy tasks without a custom status map by default status.
        XCTAssertEqual(ProjectKanban.columnId(for: task("a", status: .inProgress), columns: columns, usesCustomStatuses: true), "doing")
        XCTAssertEqual(ProjectKanban.columnId(for: task("b", status: .completed), columns: columns, usesCustomStatuses: true), "done")
        XCTAssertEqual(ProjectKanban.columnId(for: task("c", customStatusId: "todo"), columns: columns, usesCustomStatuses: true), "todo")
        // Moving derives the default status from the target column.
        let moved = ProjectKanban.moved(task("a"), toColumn: "done", columns: columns, usesCustomStatuses: true)
        XCTAssertEqual(moved.custom_status_id, "done")
        XCTAssertEqual(moved.status, "COMPLETED")
        let first = ProjectKanban.moved(task("a", status: .completed), toColumn: "todo", columns: columns, usesCustomStatuses: true)
        XCTAssertEqual(first.status, "NOT_STARTED")
        let middle = ProjectKanban.moved(task("a"), toColumn: "doing", columns: columns, usesCustomStatuses: true)
        XCTAssertEqual(middle.status, "IN_PROGRESS")
        // Without custom statuses the column id is the status.
        let plain = ProjectKanban.columns(for: project(owner: "o", members: []), defaultLabels: [.notStarted: "To Do"])
        XCTAssertEqual(plain.map { $0.id }, ["NOT_STARTED", "IN_PROGRESS", "COMPLETED"])
        let movedPlain = ProjectKanban.moved(task("a"), toColumn: "COMPLETED", columns: plain, usesCustomStatuses: false)
        XCTAssertEqual(movedPlain.status, "COMPLETED")
        XCTAssertNil(movedPlain.custom_status_id)
    }

    func testCompletedTaskWithStaleOpenColumnLandsInDone() {
        let statuses = [ProjectCustomStatus(id: "todo", label: "To Do", color: nil, order: 0, should_complete_task: false),
                        ProjectCustomStatus(id: "qa", label: "In QA", color: nil, order: 1, should_complete_task: false),
                        ProjectCustomStatus(id: "done", label: "Done", color: nil, order: 2, should_complete_task: true)]
        let columns = ProjectKanban.columns(for: project(owner: "o", members: [], statuses: statuses), defaultLabels: [:])
        // Ticked off from the Day Plan / mobile: status COMPLETED, custom id still "To Do".
        XCTAssertEqual(ProjectKanban.columnId(for: task("a", status: .completed, customStatusId: "todo"), columns: columns, usesCustomStatuses: true), "done")
        XCTAssertEqual(ProjectKanban.columnId(for: task("b", status: .completed, customStatusId: "qa"), columns: columns, usesCustomStatuses: true), "done")
        // An open task keeps its column, a completed one in the done column stays there.
        XCTAssertEqual(ProjectKanban.columnId(for: task("c", status: .inProgress, customStatusId: "qa"), columns: columns, usesCustomStatuses: true), "qa")
        XCTAssertEqual(ProjectKanban.columnId(for: task("d", status: .completed, customStatusId: "done"), columns: columns, usesCustomStatuses: true), "done")
        // No column flagged as completing: the last column is the done column.
        let noDone = statuses.map { ProjectCustomStatus(id: $0.id, label: $0.label, color: nil, order: $0.order, should_complete_task: false) }
        let plainColumns = ProjectKanban.columns(for: project(owner: "o", members: [], statuses: noDone), defaultLabels: [:])
        XCTAssertEqual(ProjectKanban.columnId(for: task("e", status: .completed, customStatusId: "todo"), columns: plainColumns, usesCustomStatuses: true), "done")
        // The main list reads the same task as Done rather than under the column's section.
        let p = project(owner: "o", members: [], statuses: statuses)
        let sections = ToDoSectioning.build(tasks: [task("a", status: .completed, customStatusId: "todo"), task("b", status: .completed, customStatusId: "qa"),
                                                    task("c", status: .inProgress, customStatusId: "qa")],
                                            projects: [p], sortMode: .chronological, sectionTitles: [:])
        XCTAssertEqual(sections.first { $0.status == .completed }?.tasks.map { $0.id }, ["a", "b"])
        XCTAssertEqual(sections.first { $0.status == .notStarted }?.tasks.map { $0.id }, [])
        XCTAssertEqual(sections.first { $0.id == "custom__in qa" }?.tasks.map { $0.id }, ["c"])
    }

    func testProjectTagIsKeptLast() {
        let p = project(owner: "o", members: [])
        let t = task("a", tags: [ToDoTag(id: "p", text: "P"), ToDoTag(id: "label", text: "urgent")])
        XCTAssertEqual(ProjectKanban.tags(for: t, project: p).map { $0.id }, ["label", "p"])
        XCTAssertEqual(ProjectKanban.tags(for: task("b"), project: p).map { $0.id }, ["p"], "the project tag is added when missing")
    }

    func testProjectNotePlainText() throws {
        let json = """
        {"id":"n","title":"T","content":{"type":"doc","content":[{"type":"heading","content":[{"type":"text","text":"Kickoff"}]},{"type":"paragraph","content":[{"type":"text","text":"Hello "},{"type":"text","text":"world"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"item"}]}]}]}]}}
        """.data(using: .utf8)!
        let note = try JSONDecoder().decode(ProjectNote.self, from: json)
        XCTAssertEqual(note.plainText, "Kickoff\nHello world\nitem")
    }

    // MARK: - Portfolio grouping

    func testGroupingSplitsBucketsAndSorts() {
        let groups = PortfolioGrouping.group([
            risk("critical-low", bucket: .critical, score: 70),
            risk("critical-high", bucket: .critical, score: 90),
            risk("at-risk", bucket: .atRisk, score: 40, days: 3),
            risk("overdue", bucket: .onTrack, score: 10, days: -2, badges: [.startNow]),
            risk("no-deadline", bucket: .noDeadline),
            risk("on-track", bucket: .onTrack, score: 5, due: "2026-10-01T00:00:00.000Z", days: 20),
        ])
        XCTAssertEqual(groups.askForExtension.map { $0.id }, ["critical-high", "critical-low"])
        XCTAssertEqual(groups.startNow.map { $0.id }, ["overdue", "at-risk"], "overdue first, then risk desc")
        XCTAssertEqual(groups.backBurner.map { $0.id }, ["on-track", "no-deadline"], "due-dated first")
    }

    func testGroupingPromotesBackBurnerWhenNothingToStart() {
        let groups = PortfolioGrouping.group([
            risk("later", bucket: .onTrack, due: "2026-12-01T00:00:00.000Z", importance: 2),
            risk("sooner", bucket: .onTrack, due: "2026-11-01T00:00:00.000Z", importance: 1),
            risk("undated", bucket: .noDeadline, importance: 4),
        ])
        XCTAssertEqual(groups.startNow.map { $0.id }.sorted(), ["later", "sooner"])
        XCTAssertEqual(groups.backBurner.map { $0.id }, ["undated"])
    }

    func testRecommendedDailyHoursAndRounding() {
        XCTAssertNil(PortfolioGrouping.recommendedDailyHours(risk("a", bucket: .noDeadline, hours: 2)))
        XCTAssertEqual(PortfolioGrouping.recommendedDailyHours(risk("b", bucket: .critical, days: -1, hours: 2)), 2)
        XCTAssertEqual(PortfolioGrouping.recommendedDailyHours(risk("c", bucket: .atRisk, days: 4, hours: 2)), 0.5)
        let parts = PortfolioGrouping.durationParts(hours: 1.51)
        XCTAssertEqual(parts.hours, 1)
        XCTAssertEqual(parts.minutes, 30)
        XCTAssertEqual(PortfolioGrouping.durationParts(hours: 0.01).minutes, 5, "never below 5 minutes")
    }

    func testUnscheduledDueDatedProjectsNeedStartingNow() {
        // #2418: "on track" only means there is free space; a due-dated project with nothing in the
        // Day Plan still needs starting. Undated unscheduled work stays on the back burner.
        let groups = PortfolioGrouping.group([
            risk("planned", bucket: .onTrack, score: 5, due: "2026-10-01T00:00:00.000Z", days: 20),
            risk("unplanned", bucket: .onTrack, score: 4, due: "2026-10-05T00:00:00.000Z", days: 24, badges: [.unscheduled]),
            risk("undated-unplanned", bucket: .noDeadline, badges: [.unscheduled]),
        ])
        XCTAssertEqual(groups.startNow.map { $0.id }, ["unplanned"])
        XCTAssertEqual(groups.backBurner.map { $0.id }, ["planned", "undated-unplanned"])
    }

    func testPortfolioDecodesDayPlanFieldsAndUnknownBadges() throws {
        let json = """
        {"projects":[{"id":"p1","name":"P1","bucket":"on_track","badges":["unscheduled","pushed_back","brand_new_badge"],
          "required_hours":5,"scheduled_hours":2,"unscheduled_hours":3,"projected_completion_date":"2026-09-20",
          "plan_feasible":false,"pushed_task_ids":["t1"]},
         {"id":"p2","name":"P2","bucket":"critical"}],
         "plan_feasible":false,"pushed_tasks":[{"id":"t1","project_id":"p1","planned_date":"2026-09-07","projected_date":"2026-09-09"}]}
        """
        let portfolio = try JSONDecoder().decode(PortfolioResponse.self, from: Data(json.utf8))
        let p1 = portfolio.projects[0]
        XCTAssertEqual(p1.badgeList, [.unscheduled, .pushedBack, .unknown], "an unknown badge never fails the decode")
        XCTAssertTrue(p1.hasScheduleBreakdown)
        XCTAssertEqual(p1.scheduled_hours, 2)
        XCTAssertEqual(p1.plan_feasible, false)
        XCTAssertEqual(p1.pushed_task_ids, ["t1"])
        XCTAssertEqual(portfolio.pushedTasks.first?.projected_date, "2026-09-09")
        // Older backends: none of the new fields, nothing to show.
        let p2 = portfolio.projects[1]
        XCTAssertFalse(p2.hasScheduleBreakdown)
        XCTAssertTrue(p2.badgeList.isEmpty)
        XCTAssertNil(p2.plan_feasible)
    }

    func testOvercommittedNamesTruncate() {
        let projects = ["A", "B", "C", "D", "E"].map { risk($0, bucket: .critical) }
        XCTAssertEqual(PortfolioGrouping.overcommittedNames(projects) { "and \($0) more" }, "A, B, C, and 2 more")
        XCTAssertEqual(PortfolioGrouping.overcommittedNames(Array(projects.prefix(2))) { "and \($0) more" }, "A, B")
    }

    // MARK: - Cross-screen completion (TodoCompletionSync)

    /// A Day Plan storage dictionary: one day key per entry, each holding `(sourceTaskId, done)` pairs.
    private func planned(_ days: [String: [(String?, Bool)]]) -> [String: [DayPlanTask]] {
        days.mapValues { entries in
            entries.map { DayPlanTask(title: "task", done: $0.1, sourceTaskId: $0.0) }
        }
    }

    func testCompletionMapsToThePlannedDayEntry() {
        let byDay = planned(["2026-09-07": [("todo-1", false), ("todo-2", false)],
                             "2026-09-08": [("todo-3", false)]])
        let updated = TodoCompletionMapping.applying(completed: true, toSourceTaskId: "todo-1", in: byDay)
        XCTAssertEqual(updated?["2026-09-07"]?.map { $0.done }, [true, false], "only the matching to-do ticks")
        XCTAssertEqual(updated?["2026-09-08"]?.map { $0.done }, [false], "other days are untouched")
    }

    func testUncompletePropagatesAndUnknownOrUnchangedToDosDoNot() {
        let byDay = planned(["2026-09-07": [("todo-1", true)]])
        XCTAssertEqual(TodoCompletionMapping.applying(completed: false, toSourceTaskId: "todo-1", in: byDay)?["2026-09-07"]?.first?.done,
                       false, "an undo propagates too")
        XCTAssertNil(TodoCompletionMapping.applying(completed: true, toSourceTaskId: "todo-1", in: byDay),
                     "already done: nothing changes, so the change is an echo of our own")
        XCTAssertNil(TodoCompletionMapping.applying(completed: true, toSourceTaskId: "not-planned", in: byDay))
    }

    func testEveryStaleCopyOfTheSameToDoTicks() {
        // A to-do should sit on one day, but a stale duplicate must not be left half-ticked.
        let byDay = planned(["2026-09-07": [("todo-1", false)], "2026-09-08": [("todo-1", false), (nil, false)]])
        let updated = TodoCompletionMapping.applying(completed: true, toSourceTaskId: "todo-1", in: byDay)
        XCTAssertEqual(updated?["2026-09-07"]?.first?.done, true)
        XCTAssertEqual(updated?["2026-09-08"]?.map { $0.done }, [true, false], "a local-only task is left alone")
    }

    func testCompletionBusRoundTripsItsChange() {
        let expectation = XCTestExpectation(description: "change delivered")
        let token = TodoCompletionBus.observe { change in
            XCTAssertEqual(change, TodoCompletionBus.Change(todoID: "todo-1", completed: true))
            expectation.fulfill()
        }
        TodoCompletionBus.post(todoID: "todo-1", completed: true)
        wait(for: [expectation], timeout: 1)
        NotificationCenter.default.removeObserver(token)
    }

    // MARK: - Project card "NEXT" task (PortfolioNextTask)

    /// Reproduces the reported bug: the wire payload's own `top_priority_task` named a to-do the user
    /// had already ticked off (14 of 30 project cards on the reporter's account), because the server
    /// ranks completed tasks on the score they kept from before they were finished.
    func testNextTaskNeverPicksACompletedTask() {
        let tasks = [task("done", status: .completed, due: day(-3), outcome: 8, perspiration: 2, topScore: 44),
                     task("open", due: day(2), outcome: 3, perspiration: 2)]
        XCTAssertEqual(PortfolioNextTask.pick(from: tasks)?.id, "open")
    }

    func testNextTaskIsTheHighestScoringOpenTask() {
        let tasks = [task("low", due: day(30), outcome: 1, perspiration: 5),
                     task("high", due: day(0), outcome: 9, perspiration: 1),
                     task("mid", due: day(5), outcome: 5, perspiration: 3)]
        let picked = PortfolioNextTask.pick(from: tasks)
        XCTAssertEqual(picked?.id, "high")
        XCTAssertEqual(picked?.top_score, ToDoScoring.topScore(of: tasks[1]), "the card shows the locally computed score")
    }

    func testNextTaskIsNilWhenEveryTaskIsDone() {
        XCTAssertNil(PortfolioNextTask.pick(from: [task("a", status: .completed), task("b", status: .completed)]),
                     "a finished project offers no next task rather than a stale one")
        XCTAssertNil(PortfolioNextTask.pick(from: []))
    }

    func testCompletedTasksScoreZeroSoTheySortLast() {
        let completed = task("done", status: .completed, due: day(-30), outcome: 10, perspiration: 1, topScore: 400)
        XCTAssertEqual(ToDoScoring.topScore(of: completed), 0, "web getTOPScore: completed tasks do not compete")
        let open = task("open", due: day(10), outcome: 1, perspiration: 5)
        XCTAssertEqual(ToDoSorting.sort([completed, open], by: .smart).map { $0.id }, ["open", "done"])
    }

    func testFetchTargetsSkipEmptyProjectsAndDeduplicate() {
        let withTasks = listedProject(id: "a", taskCount: 3)
        let empty = listedProject(id: "b", taskCount: 0)
        let synced = listedProject(id: "c", taskCount: 1, syncedProjectId: "ext-c")
        let targets = PortfolioNextTask.fetchTargets(projects: [withTasks, empty, synced],
                                                    additionalProjectIds: ["a", "portfolio-only"])
        XCTAssertEqual(targets.map { $0.projectId }, ["a", "c", "portfolio-only"],
                       "empty projects are skipped; a listed project is not fetched twice")
        XCTAssertEqual(targets[1].syncedProjectId, "ext-c", "a synced project is queried by its external id")
        XCTAssertNil(targets[2].syncedProjectId)
    }

    func testUncachedTargetsSkipAlreadyResolvedProjects() {
        let targets = PortfolioNextTask.fetchTargets(projects: [listedProject(id: "a", taskCount: 1),
                                                                listedProject(id: "b", taskCount: 1)])
        XCTAssertEqual(PortfolioNextTask.uncached(targets, resolved: ["a"]).map { $0.projectId }, ["b"])
        XCTAssertTrue(PortfolioNextTask.uncached(targets, resolved: ["a", "b"]).isEmpty)
    }

    // MARK: - Project lifecycle (mark complete / archive / restore)

    func testLifecycleActionsVisibleForEachStatus() {
        XCTAssertEqual(lifecycleActions(for: .active), [.markComplete, .archive])
        XCTAssertEqual(lifecycleActions(for: .completed), [.archive, .restore])
        XCTAssertEqual(lifecycleActions(for: .archived), [.restore])
    }

    func testLifecycleStatusRoundTripsThroughTheWirePayload() {
        XCTAssertEqual(listedProject(id: "a", taskCount: 0, status: nil).lifecycleStatus, .active,
                       "no status on the payload means active")
        XCTAssertEqual(listedProject(id: "a", taskCount: 0, status: "completed").lifecycleStatus, .completed)
        XCTAssertEqual(listedProject(id: "a", taskCount: 0, status: "archived").lifecycleStatus, .archived)
        XCTAssertEqual(listedProject(id: "a", taskCount: 0, status: "nonsense").lifecycleStatus, .active)
    }

    private enum LifecycleAction { case markComplete, archive, restore }

    /// Mirrors `lifecycleSection`'s visibility rules in ProjectDetailView.
    private func lifecycleActions(for status: ProjectLifecycleStatus) -> [LifecycleAction] {
        var actions: [LifecycleAction] = []
        if status == .active { actions.append(.markComplete) }
        if status != .archived { actions.append(.archive) }
        if status != .active { actions.append(.restore) }
        return actions
    }

    // MARK: - Card badges under a section heading (report 2026-09-11_20-39-23)

    func testBadgesDropTheOnesTheSectionHeadingAlreadySays() {
        let all: [PortfolioBadge] = [.startNow, .overcommitted, .sacrifice, .unscheduled]
        XCTAssertEqual(PortfolioGrouping.badges(all, in: .askForExtension), [.sacrifice, .unscheduled],
                       "Overloaded repeats the heading and Start now contradicts it")
        XCTAssertEqual(PortfolioGrouping.badges(all, in: .startNow), [.overcommitted, .sacrifice, .unscheduled],
                       "Overloaded still says something outside the extension section")
        XCTAssertEqual(PortfolioGrouping.badges(all, in: nil), all,
                       "An ungrouped card has no heading to lean on")
    }

    // MARK: - Project merge (report 2026-09-11_07-31-36)

    private func mergeProject(id: String, name: String, owner: String? = "me", synced: String? = nil,
                              status: String? = nil, statuses: [ProjectCustomStatus] = []) -> Project {
        Project(id: id, name: name, description: nil, owner_id: owner, custom_statuses: statuses, icon: nil,
                members: nil, task_count: nil, uncompleted_task_count: nil, synced_project_id: synced,
                due_date: nil, importance: nil, status: status, created_at: nil, updated_at: nil)
    }

    func testMergeDestinationsExcludeTheSourceSyncedAndInactiveProjects() {
        let source = mergeProject(id: "src", name: "Grant application")
        let all = [source,
                   mergeProject(id: "a", name: "Grant Application (old)"),
                   mergeProject(id: "b", name: "House"),
                   mergeProject(id: "c", name: "Grant synced", synced: "zoho-1"),
                   mergeProject(id: "d", name: "Grant archived", status: ProjectLifecycleStatus.archived.rawValue),
                   mergeProject(id: "e", name: "Grant of a stranger", owner: "someone-else")]
        let everything = ProjectMerge.destinations(all, excluding: source, userId: "me").map(\.id)
        XCTAssertEqual(everything, ["a", "b"], "Only active, native, writable projects other than the source")
        let filtered = ProjectMerge.destinations(all, excluding: source, query: "grant", userId: "me").map(\.id)
        XCTAssertEqual(filtered, ["a"], "The search filters by name, case-insensitively")
    }

    func testCanMergeRequiresManagingTheSourceAndWritingToTheTarget() {
        let source = mergeProject(id: "src", name: "Source")
        XCTAssertTrue(ProjectMerge.canMerge(source, into: mergeProject(id: "t", name: "Target"), userId: "me"))
        XCTAssertFalse(ProjectMerge.canMerge(source, into: source, userId: "me"), "A project cannot merge into itself")
        XCTAssertFalse(ProjectMerge.canMerge(source, into: mergeProject(id: "t", name: "T", synced: "zoho-1"), userId: "me"),
                       "A synced project's tasks belong to the external tool")
        XCTAssertFalse(ProjectMerge.canMerge(mergeProject(id: "src", name: "S", owner: "someone-else"),
                                             into: mergeProject(id: "t", name: "T"), userId: "me"),
                       "Only someone who can manage the source may empty it")
    }

    func testMergeReassignmentRepointsTheProjectTagAndClearsTheOldColumn() throws {
        let source = mergeProject(id: "src", name: "Source")
        let target = mergeProject(id: "dst", name: "Target",
                                  statuses: [ProjectCustomStatus(id: "col-1", label: "To do", color: nil, order: 0, should_complete_task: false)])
        var task = ToDoTask(id: "t1", title: "Fix references", status: ToDoStatus.notStarted.rawValue, created_at: "")
        task.project_id = source.id
        task.custom_status_id = "source-column"
        task.tags = [ToDoTag(id: source.id, text: "Source"), ToDoTag(id: "label", text: "#deep")]
        let body = try ProjectMerge.reassignment(of: task, from: source, to: target).get()
        XCTAssertEqual(body["project_id"] as? String, "dst")
        XCTAssertEqual(body["custom_status_id"] as? String, "col-1", "The task lands in the target's first column")
        let tags = try XCTUnwrap(body["tags"] as? [[String: String]])
        XCTAssertEqual(tags.map { $0["id"] }, ["label", "dst"], "The source's project tag is replaced, other labels survive")
        XCTAssertEqual(body["title"] as? String, "Fix references", "The rest of the task is sent unchanged")
    }

    func testMergeReassignmentClearsTheColumnWhenTheTargetHasNoBoard() throws {
        let source = mergeProject(id: "src", name: "Source")
        var task = ToDoTask(id: "t1", title: "Task", status: ToDoStatus.notStarted.rawValue, created_at: "")
        task.custom_status_id = "source-column"
        let body = try ProjectMerge.reassignment(of: task, from: source, to: mergeProject(id: "dst", name: "Target")).get()
        XCTAssertTrue(body["custom_status_id"] is NSNull, "A column from the source board cannot follow the task")
    }

    func testMergeLeavesExternallySyncedTasksAlone() {
        let source = mergeProject(id: "src", name: "Source")
        var task = ToDoTask(id: "t1", title: "Zoho task", status: ToDoStatus.notStarted.rawValue, created_at: "")
        task.synced_project_id = "zoho-1"
        guard case .failure(let skip) = ProjectMerge.reassignment(of: task, from: source, to: mergeProject(id: "dst", name: "T")) else {
            return XCTFail("A task owned by an external tool must not be re-pointed")
        }
        XCTAssertEqual(skip, .externallySynced)
    }

    func testMergeOutcomeOnlyArchivesAFullyEmptiedProject() {
        XCTAssertTrue(ProjectMerge.Outcome(moved: 3, skipped: 0, failed: 0).archivesSource)
        XCTAssertFalse(ProjectMerge.Outcome(moved: 3, skipped: 1, failed: 0).archivesSource,
                       "A project still holding synced tasks is not empty")
        XCTAssertFalse(ProjectMerge.Outcome(moved: 3, skipped: 0, failed: 1).archivesSource)
        XCTAssertFalse(ProjectMerge.Outcome(moved: 3, skipped: 0, failed: 1).succeeded)
    }

    private func listedProject(id: String, taskCount: Int, syncedProjectId: String? = nil, status: String? = nil) -> Project {
        Project(id: id, name: id, description: nil, owner_id: nil, custom_statuses: nil, icon: nil, members: nil,
                task_count: taskCount, uncompleted_task_count: nil, synced_project_id: syncedProjectId, due_date: nil,
                importance: nil, status: status, created_at: nil, updated_at: nil)
    }
}


extension ToDoLogicTests {
    func testDueDateFieldEditorReturnCommitsCurrentTextAndConsumesDefaultAction() {
        var input = ""
        var commits: [String] = []
        let binding = Binding<String>(get: { input }, set: { input = $0 })
        let field = ReturnGuardTextField(text: binding, placeholder: "", onCommit: { commits.append(input) })
        let coordinator = field.makeCoordinator()
        let editor = NSTextView()
        editor.string = "5w"
        XCTAssertTrue(coordinator.control(NSTextField(), textView: editor, doCommandBy: #selector(NSResponder.insertNewline(_:))))
        XCTAssertEqual(commits, ["5w"])
        XCTAssertNotNil(ToDoDueDateParser.parse(commits[0]))
        XCTAssertFalse(coordinator.control(NSTextField(), textView: editor, doCommandBy: #selector(NSResponder.moveLeft(_:))))
        XCTAssertEqual(commits.count, 1)
    }

    // MARK: What "Close" closes (report 2026-09-14_19-4x)

    func testCloseStepsBackFromTheNoteFirst() {
        XCTAssertEqual(ToDoCloseStep.next(hasOpenNote: true, hasOpenProject: true), .closeNote)
    }

    func testCloseThenStepsBackFromTheProject() {
        XCTAssertEqual(ToDoCloseStep.next(hasOpenNote: false, hasOpenProject: true), .closeProject)
    }

    func testCloseOnlyDismissesTheScreenWhenNothingIsOpen() {
        XCTAssertEqual(ToDoCloseStep.next(hasOpenNote: false, hasOpenProject: false), .closeScreen)
    }

    func testAnOpenNoteWithoutAProjectStillClosesTheNote() {
        XCTAssertEqual(ToDoCloseStep.next(hasOpenNote: true, hasOpenProject: false), .closeNote,
                       "The innermost thing wins regardless of how it was reached")
    }

    // MARK: New-task due date (report 2026-09-14_19-50-05)

    func testANewTaskTakesTheNextFreeDayWhenOneIsKnown() {
        let now = Date(timeIntervalSince1970: 1_757_800_000)
        let free = Calendar.current.date(byAdding: .day, value: 4, to: now)!
        let task = ToDoDraft.newTask(title: "Write it up", now: now, dueDate: free)
        XCTAssertEqual(task.due_date, ToDoDates.ymd(free))
    }

    func testWithoutAForecastANewTaskIsStillDueTomorrow() {
        let now = Date(timeIntervalSince1970: 1_757_800_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        XCTAssertEqual(ToDoDraft.newTask(title: "Write it up", now: now).due_date, ToDoDates.ymd(tomorrow))
    }

    // MARK: - Project icons (report 2026-09-14_20-07-42)

    func testProjectIconSendsTheLiteralEmojiNotAHexCodepoint() {
        // The server validates `icon` with the same check its own generator writes through
        // (`normalizeSingleEmoji`), so "1f3af" is rejected — the character itself is the contract.
        XCTAssertEqual(ProjectIcon.normalise("\u{1F3AF}"), "\u{1F3AF}")
        XCTAssertEqual(ProjectIcon.normalise("1f3af"), ProjectIcon.cleared, "hex is not the wire format")
    }

    func testProjectIconKeepsAZeroWidthJoinerSequenceWhole() {
        // "\u{1F486}\u{200D}\u{2642}\u{FE0F}" is one grapheme cluster; splitting it would send half an emoji.
        let joined = "\u{1F486}\u{200D}\u{2642}\u{FE0F}"
        XCTAssertEqual(ProjectIcon.normalise(joined), joined)
        XCTAssertTrue(ProjectIcon.isSingleEmoji(joined))
    }

    func testProjectIconTakesOnlyTheFirstEmojiAndTrims() {
        XCTAssertEqual(ProjectIcon.normalise("  \u{1F680}  "), "\u{1F680}")
        XCTAssertEqual(ProjectIcon.normalise("\u{1F680}\u{1F3AF}"), "\u{1F680}", "the server accepts exactly one")
        XCTAssertFalse(ProjectIcon.isSingleEmoji("\u{1F680}\u{1F3AF}"))
    }

    func testProjectIconRejectsPlainText() {
        XCTAssertEqual(ProjectIcon.normalise("health"), ProjectIcon.cleared)
        XCTAssertEqual(ProjectIcon.normalise(""), ProjectIcon.cleared)
        XCTAssertFalse(ProjectIcon.isSingleEmoji("health"))
    }

    func testProjectIconSearchFindsByKeyword() {
        // The reported screenshot was of someone searching "health" in the system palette.
        let emojis = ProjectIcon.choices(matching: "health").map { $0.emoji }
        XCTAssertFalse(emojis.isEmpty, "searching health must offer something")
        XCTAssertTrue(emojis.contains("\u{1FA7A}"), "the stethoscope is a health icon")
        XCTAssertTrue(ProjectIcon.choices(matching: "zzzz").isEmpty)
    }

    func testProjectIconSearchReachesEmojiOutsideTheCuratedGrid() {
        // Report 2026-09-17: "it seems to only have a limited set of icons?" The grid is 59 rows;
        // searching has to reach the rest of Unicode, by the words in each emoji's official name.
        let curated = Set(ProjectIcon.catalogue.map { $0.emoji })
        let penguins = ProjectIcon.choices(matching: "penguin").map { $0.emoji }
        XCTAssertTrue(penguins.contains("\u{1F427}"), "🐧 is not curated but is searchable")
        XCTAssertFalse(curated.contains("\u{1F427}"), "the point of the test is that it is not in the grid")

        let violins = ProjectIcon.choices(matching: "violin").map { $0.emoji }
        XCTAssertTrue(violins.contains("\u{1F3BB}"))
    }

    func testProjectIconSearchPutsCuratedMatchesBeforeTheRest() {
        // ICU names 🚀 "ROCKET" too, so both lists match "rocket" — the curated one must lead,
        // because those are the icons chosen to read well at 22pt.
        let choices = ProjectIcon.choices(matching: "rocket")
        XCTAssertEqual(choices.first?.emoji, "\u{1F680}")
    }

    func testProjectIconSearchDoesNotShowTheSameEmojiTwice() {
        // ⭐️ is curated with a variation selector; bare U+2B50 sits in the indexed block. Comparing
        // without U+FE0F is what keeps one of them out.
        let stars = ProjectIcon.choices(matching: "star").map { $0.emoji.filter { $0 != "\u{FE0F}" } }
        XCTAssertEqual(stars.filter { $0 == "\u{2B50}" }.count, 1)
    }

    func testProjectIconEmptySearchStillShowsOnlyTheCuratedGrid() {
        // The full index is for searching; dumping ~1,000 emoji into the popover on open is not.
        XCTAssertEqual(ProjectIcon.choices(matching: "").map { $0.emoji },
                       ProjectIcon.catalogue.map { $0.emoji })
    }

    func testProjectIconSearchOffersAPastedEmojiFirst() {
        // An emoji outside the catalogue must still be pickable.
        let choices = ProjectIcon.choices(matching: "\u{1F9A5}")
        XCTAssertEqual(choices.first?.emoji, "\u{1F9A5}")
    }

    func testProjectIconCatalogueIsWholeAndUnique() {
        let emojis = ProjectIcon.catalogue.map { $0.emoji }
        XCTAssertEqual(Set(emojis).count, emojis.count, "a duplicate emoji would break ForEach identity")
        for choice in ProjectIcon.catalogue {
            XCTAssertEqual(ProjectIcon.normalise(choice.emoji), choice.emoji, "\(choice.emoji) is not one emoji")
            XCTAssertFalse(choice.keywords.isEmpty, "\(choice.emoji) is unsearchable")
        }
        XCTAssertEqual(ProjectIcon.choices(matching: "").count, ProjectIcon.catalogue.count)
    }

    /// Display still has to read both shapes: `habit_icon` is hex, a project's `icon` is the
    /// character, and the same glyph view renders each.
    func testEmojiIconResolvesBothHexAndALiteralCharacter() {
        XCTAssertEqual(EmojiIcon.resolve("1f3af"), "\u{1F3AF}")
        XCTAssertEqual(EmojiIcon.resolve("1f486-200d-2642-fe0f"), "\u{1F486}\u{200D}\u{2642}\u{FE0F}")
        XCTAssertEqual(EmojiIcon.resolve("\u{1F3AF}"), "\u{1F3AF}")
        XCTAssertNil(EmojiIcon.resolve(""))
        XCTAssertNil(EmojiIcon.resolve(nil))
    }

    // MARK: - Remote completion (`todo-completed` Pusher event)

    /// The body the backend broadcasts (`TodoCompletedEventPayload`), as it arrives on the wire.
    private func todoCompletedEventJSON(todoID: String = "todo-1",
                                        extra: String = "\"is_completed\": true,") -> String {
        """
        {"todo_id": "\(todoID)", \(extra) "status": "COMPLETED",
         "completed_at": "2026-09-14T09:37:51.000Z", "title": "Ship it", "planned_date": "2026-09-14"}
        """
    }

    func testRemoteCompletionEventDecodesTheBackendPayload() {
        let payload = TodoCompletedPusherEvent.payload(fromJSON: todoCompletedEventJSON())
        XCTAssertEqual(payload, TodoCompletedPusherEvent.Payload(todoID: "todo-1", isCompleted: true,
                                                                completedAt: "2026-09-14T09:37:51.000Z"))
    }

    func testRemoteCompletionEventTreatsAMissingFlagAsCompleted() {
        // The event name already says what happened; a missing flag must never UN-tick a task.
        let payload = TodoCompletedPusherEvent.payload(fromJSON: todoCompletedEventJSON(extra: ""))
        XCTAssertEqual(payload?.isCompleted, true)
    }

    func testRemoteCompletionEventIgnoresUnusablePayloads() {
        XCTAssertNil(TodoCompletedPusherEvent.payload(fromJSON: nil))
        XCTAssertNil(TodoCompletedPusherEvent.payload(fromJSON: "not json"))
        XCTAssertNil(TodoCompletedPusherEvent.payload(fromJSON: #"{"status": "COMPLETED"}"#),
                     "no to-do id: nothing to tick")
        XCTAssertNil(TodoCompletedPusherEvent.payload(fromJSON: todoCompletedEventJSON(todoID: "")))
    }

    func testRemoteCompletionEventAnnouncesTheChangeExactlyOnce() {
        var announced: [(String, Bool)] = []
        let record: (String, Bool) -> Void = { id, done in announced.append((id, done)) }

        let understood = TodoCompletedPusherEvent.handle(eventData: todoCompletedEventJSON(), announce: record)
        XCTAssertTrue(understood)
        XCTAssertEqual(announced.count, 1)
        XCTAssertEqual(announced.first?.0, "todo-1")
        XCTAssertEqual(announced.first?.1, true)

        announced.removeAll()
        let garbage = TodoCompletedPusherEvent.handle(eventData: "not json", announce: record)
        XCTAssertFalse(garbage)
        XCTAssertTrue(announced.isEmpty, "an undecodable event changes nothing")
    }

    func testRemoteCompletionReachesTheStoresThroughTheCompletionBus() {
        let expectation = XCTestExpectation(description: "bus change delivered")
        let token = TodoCompletionBus.observe { change in
            XCTAssertEqual(change, TodoCompletionBus.Change(todoID: "todo-remote", completed: true))
            expectation.fulfill()
        }
        TodoCompletedPusherEvent.handle(eventData: todoCompletedEventJSON(todoID: "todo-remote"))
        wait(for: [expectation], timeout: 1)
        NotificationCenter.default.removeObserver(token)
    }

    func testRemoteCompletionDoesNotEchoAWriteBackToTheServer() {
        // The loop this guards: routing an incoming completion through `DayPlanTaskStore.update` (or
        // straight to `DayPlanSync`) would `PUT /to-do` back at the server that just told us.
        DayPlanSync.lastTodoStatusWrite = nil
        TodoCompletedPusherEvent.handle(eventData: todoCompletedEventJSON(todoID: "todo-remote"))
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertNil(DayPlanSync.lastTodoStatusWrite, "a remote completion must not write back")
    }

    func testRemoteCompletionTicksTheDayPlanCopyOfTheToDo() {
        let byDay = planned(["2026-09-14": [("todo-remote", false), ("todo-other", false)]])
        guard let payload = TodoCompletedPusherEvent.payload(fromJSON: todoCompletedEventJSON(todoID: "todo-remote")) else {
            return XCTFail("event should decode")
        }
        let updated = TodoCompletionMapping.applying(completed: payload.isCompleted,
                                                     toSourceTaskId: payload.todoID, in: byDay)
        XCTAssertEqual(updated?["2026-09-14"]?.map { $0.done }, [true, false])
    }
}

// MARK: - Task editor Save

final class ToDoEditorSaveTests: XCTestCase {

    /// The reported bug: attaching a file changes nothing in the task draft, so a rule gated on
    /// "has the draft changed" left Save dead for the rest of the editing session. Both exits from
    /// an upload — recorded, or failed — clear the in-flight flag, so Save must come back either way.
    func testSaveIsHeldDuringAnUploadAndComesBackWhenItEnds() {
        XCTAssertFalse(ToDoEditorSave.canSave(titleIsBlank: false, isSavingTask: false, isUploadingAttachment: true),
                       "the sheet must not close while bytes are still going to storage")
        XCTAssertTrue(ToDoEditorSave.canSave(titleIsBlank: false, isSavingTask: false, isUploadingAttachment: false),
                      "an attachment does not touch the draft, so Save cannot depend on the draft changing")
    }

    func testSaveNeedsATitle() {
        XCTAssertFalse(ToDoEditorSave.canSave(titleIsBlank: true, isSavingTask: false, isUploadingAttachment: false))
    }

    func testSaveIsHeldWhileTheTaskIsBeingSaved() {
        XCTAssertFalse(ToDoEditorSave.canSave(titleIsBlank: false, isSavingTask: true, isUploadingAttachment: false))
    }
}

// MARK: - Image preview sizing

final class ImagePreviewSizingTests: XCTestCase {

    private let screen = CGSize(width: 1512, height: 982)
    /// Both sides are rounded to whole points (a half-point frame just blurs the image), which can
    /// shift the ratio by up to half a point on the shorter edge.
    private let ratioTolerance = 0.05

    func testAWideImageIsLimitedByTheScreenWidthAndKeepsItsAspectRatio() {
        let size = ImagePreviewSizing.fit(image: CGSize(width: 4000, height: 2000), available: screen)
        XCTAssertEqual(size.width, (screen.width * ImagePreviewSizing.availableFraction).rounded(), accuracy: 1)
        XCTAssertEqual(size.width / size.height, 2, accuracy: ratioTolerance)
    }

    func testATallImageIsLimitedByTheScreenHeightAndKeepsItsAspectRatio() {
        let size = ImagePreviewSizing.fit(image: CGSize(width: 1000, height: 4000), available: screen)
        XCTAssertEqual(size.height, (screen.height * ImagePreviewSizing.availableFraction).rounded(), accuracy: 1)
        XCTAssertEqual(size.height / size.width, 4, accuracy: ratioTolerance)
    }

    func testAnImageSmallerThanTheScreenIsNotBlownUp() {
        let natural = CGSize(width: 694, height: 352)
        XCTAssertEqual(ImagePreviewSizing.fit(image: natural, available: screen), natural)
    }

    func testTheSameImageGetsALargerPreviewOnALargerScreen() {
        let image = CGSize(width: 4000, height: 2500)
        let onLaptop = ImagePreviewSizing.fit(image: image, available: screen)
        let onDesktop = ImagePreviewSizing.fit(image: image, available: CGSize(width: 3008, height: 1692))
        XCTAssertGreaterThan(onDesktop.width, onLaptop.width, "the size comes from the screen, not a fixed maximum")
    }

    func testAnUnmeasurableImageHasNoPreviewSize() {
        XCTAssertEqual(ImagePreviewSizing.fit(image: .zero, available: screen), .zero)
        XCTAssertEqual(ImagePreviewSizing.fit(image: CGSize(width: 100, height: 100), available: .zero), .zero)
    }

    // MARK: - Who a task is assigned to

    private static let me = ToDoAssigneeOption(id: "me", label: "Me (me@example.com)")
    private static let colleague = ToDoAssigneeOption(id: "them", label: "them@example.com")

    // The flat-vs-relation contract already has its own tests above, against the real production
    // payload. These cover the rules the Day Plan's new picker shares with the editor's.

    func testTheSharedReaderPrefersTheFlatIdAndFallsBackToTheRelation() {
        XCTAssertEqual(ToDoAssigneeChoices.assigneeId(flat: "flat", relation: "rel"), "flat")
        XCTAssertEqual(ToDoAssigneeChoices.assigneeId(flat: nil, relation: "rel"), "rel")
        XCTAssertEqual(ToDoAssigneeChoices.assigneeId(flat: "", relation: "rel"), "rel")
        XCTAssertNil(ToDoAssigneeChoices.assigneeId(flat: nil, relation: nil))
    }

    func testThereIsNoAssigneeControlForASoloProject() {
        // "If the project has other members" — alone, the picker would offer one name, which is noise
        // (report 2026-09-14_19-50-36), so the control is not drawn at all.
        let options = ToDoAssigneeChoices.options(me: Self.me, members: [], current: nil)
        XCTAssertEqual(options, [Self.me])
        XCTAssertFalse(ToDoAssigneeChoices.canAssign(options: options, currentAssigneeId: nil, meId: "me"))
    }

    func testTheAssigneeControlAppearsOnceTheProjectHasAnotherMember() {
        let options = ToDoAssigneeChoices.options(me: Self.me, members: [Self.colleague], current: nil)
        XCTAssertEqual(options, [Self.me, Self.colleague])
        XCTAssertTrue(ToDoAssigneeChoices.canAssign(options: options, currentAssigneeId: nil, meId: "me"))
    }

    func testAnExistingAssignmentKeepsTheControlVisibleEvenInASoloProject() {
        // A task assigned to somebody who has since left would otherwise show no control at all, and
        // the assignment could never be undone.
        let options = ToDoAssigneeChoices.options(me: Self.me, members: [], current: Self.colleague)
        XCTAssertTrue(options.contains(Self.colleague), "an unknown assignee must still be listed")
        XCTAssertTrue(ToDoAssigneeChoices.canAssign(options: options, currentAssigneeId: "them", meId: "me"))
    }

    func testAnAssignmentToMyselfDoesNotForceTheControlOpen() {
        let options = ToDoAssigneeChoices.options(me: Self.me, members: [], current: Self.me)
        XCTAssertFalse(ToDoAssigneeChoices.canAssign(options: options, currentAssigneeId: "me", meId: "me"))
    }

    func testTheUserIsNeverListedTwice() {
        // The user is also an accepted member of their own project, so both sources offer them.
        let options = ToDoAssigneeChoices.options(me: Self.me,
                                                  members: [ToDoAssigneeOption(id: "me", label: "me@example.com")],
                                                  current: ToDoAssigneeOption(id: "me", label: "me"))
        XCTAssertEqual(options.map(\.id), ["me"])
        XCTAssertEqual(options.first?.label, Self.me.label, "the friendlier label wins")
    }

    // MARK: The Day Plan reads the same payload

    func testTheDayPlanReadsAnAssigneeFromTheRelationToo() {
        // The Day Plan imports raw to-do dictionaries of its own, so it has to make the same
        // flat-vs-relation decision the editor does — and `GET /to-do` sends only the relation.
        let fields = TodoProjectFields(todo: ["assignee": ["id": "them", "username": "Them"]])
        XCTAssertEqual(fields.assigneeID, "them")
        XCTAssertEqual(fields.assigneeName, "Them")
    }

    func testTheDayPlanLeavesAnUnmentionedAssigneeAlone() {
        // A partial refresh that says nothing about the assignee must not be read as "unassigned";
        // that is the shape of the bug in backend#2414.
        var task = DayPlanTask(title: "Write the spec", sourceTaskId: "todo-1")
        task.assigneeId = "them"
        task.assigneeName = "Them"
        task.applyProjectFields(TodoProjectFields(todo: ["project_id": "p1"]))
        XCTAssertEqual(task.assigneeId, "them", "a payload with no assignee key must not clear it")
    }

    func testTheDayPlanTakesANewAssigneeFromARefresh() {
        var task = DayPlanTask(title: "Write the spec", sourceTaskId: "todo-1")
        task.applyProjectFields(TodoProjectFields(todo: ["assignee": ["id": "them", "email": "them@example.com"]]))
        XCTAssertEqual(task.assigneeId, "them")
        XCTAssertEqual(task.assigneeName, "them@example.com")
    }

    // MARK: Somebody else's task is not my day

    func testAnUnassignedTaskIsMine() {
        // Most tasks are unassigned. Treating nil as "not mine" would empty the Day Plan.
        XCTAssertFalse(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: nil, meId: "me"))
        XCTAssertFalse(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: "", meId: "me"))
    }

    func testATaskAssignedToMeIsMine() {
        XCTAssertFalse(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: "me", meId: "me"))
    }

    func testATaskAssignedToSomebodyElseIsNotMine() {
        // "If it's assigned to someone else, it shouldn't appear on my day plan."
        XCTAssertTrue(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: "them", meId: "me"))
    }

    func testNothingIsHiddenWhileTheSignedInUserIsUnknown() {
        // On a cold launch the account may not be resolved yet. Guessing would blank the whole day,
        // which is far worse than briefly showing one extra row.
        XCTAssertFalse(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: "them", meId: nil))
        XCTAssertFalse(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: "them", meId: ""))
    }

    func testOwnershipIsDecidedFromTheRelationWhenTheFlatFieldIsMissing() {
        // The risk worth guarding: GET /to-do sends no flat assignee_id (backend#2414). A filter
        // reading the flat field alone sees every task as unassigned and hides nothing at all.
        let payload: [String: Any] = ["assignee": ["id": "them", "username": "Them"]]
        let fields = TodoProjectFields(todo: payload)
        XCTAssertNil(payload["assignee_id"], "the production payload really has no flat key")
        XCTAssertTrue(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: fields.assigneeID, meId: "me"))
    }

    func testReassigningBackMakesTheTaskMineAgain() {
        // The round trip, not just the hide: the filter is a filter, so putting the assignee back
        // makes the very same task the user's again with nothing to restore.
        var task = DayPlanTask(title: "Design accountability buddy", sourceTaskId: "todo-1")
        task.applyProjectFields(TodoProjectFields(todo: ["assignee": ["id": "them"]]))
        XCTAssertTrue(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: task.assigneeId, meId: "me"))

        task.applyProjectFields(TodoProjectFields(todo: ["assignee": ["id": "me"]]))
        XCTAssertFalse(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: task.assigneeId, meId: "me"))
    }

    func testTheSameRuleDecidesWhatIsShownAndWhatIsCounted() {
        // Capacity is summed from the same filtered list the panel draws, so the two cannot disagree
        // about what occupies a day. Expressed here as the rule both sides call.
        let mine = ["", "me"].map { ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: $0, meId: "me") }
        XCTAssertEqual(mine, [false, false])
        XCTAssertTrue(ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: "them", meId: "me"))
    }

    func testATaskStoredBeforeAssigneesExistedStillDecodes() {
        let legacy = #"{"id":"1","title":"Old","durationMinutes":15,"done":false}"#
        let restored = try? JSONDecoder().decode(DayPlanTask.self, from: Data(legacy.utf8))
        XCTAssertNotNil(restored)
        XCTAssertNil(restored?.assigneeId)
    }
}
