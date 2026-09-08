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
                         badges: badges.map { $0.rawValue }, top_priority_task: nil)
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
                              importance: nil, status: nil, top_priority_task: nil, created_at: nil, updated_at: nil)
        let tasks = [task("a", status: .inProgress), task("b", customStatusId: "s-todo", projectId: "p"), task("c", customStatusId: "s-review", projectId: "p")]
        let sections = ToDoSectioning.build(tasks: tasks, projects: [project], sortMode: .smart,
                                            sectionTitles: [.inProgress: "Doing", .notStarted: "To do", .completed: "Done"])
        XCTAssertEqual(sections.map { $0.id }, ["IN_PROGRESS", "NOT_STARTED", "COMPLETED", "custom__review"])
        XCTAssertEqual(sections[1].tasks.map { $0.id }, ["b"], "'To Do' is an alias of the default To do section")
        XCTAssertEqual(sections[3].tasks.map { $0.id }, ["c"])
        XCTAssertEqual(sections[3].title, "Review")
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
        // Web parity: a task without a column id still moves into the project's done column, and a
        // project with no completing column falls back to its last one.
        let legacy = ToDoStatusToggle.apply(to: task("c"), completed: true, customStatuses: statuses)
        XCTAssertEqual(legacy.custom_status_id, "done")
        let noDone = statuses.map { ProjectCustomStatus(id: $0.id, label: $0.label, color: nil, order: $0.order, should_complete_task: false) }
        XCTAssertEqual(ToDoStatusToggle.apply(to: task("d"), completed: true, customStatuses: noDone).custom_status_id, "done")
        XCTAssertEqual(ToDoStatusToggle.apply(to: task("d", status: .completed, customStatusId: "done"), completed: false, customStatuses: noDone).custom_status_id, "todo")
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
        XCTAssertEqual(draft.outcome, ToDoScoring.defaultOutcome)
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
                top_priority_task: nil, created_at: nil, updated_at: nil)
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
}
