import XCTest
@testable import Focus_Bear

final class LocalForecastPortfolioTests: XCTestCase {
    func testAcknowledgedProjectEditsReplaceCachedDateAndLifecycleIncludingClearingDate() {
        let cached = Project(id: "p", name: "Old", task_count: 5, synced_project_id: "sync", synced_platform: "asana",
                             due_date: "2026-09-16", outcome: 4, status: "active", updated_at: "2026-09-11T01:00:00Z")
        var saved = Project(id: "p", name: "Updated", due_date: "2026-10-16", outcome: 7,
                            status: "completed", updated_at: "2026-09-11T02:00:00Z")
        let merged = ProjectListPresentation.reconcilingSavedProject(cached, saved: saved)
        XCTAssertEqual(merged.due_date, "2026-10-16")
        XCTAssertEqual(merged.lifecycleStatus, .completed)
        XCTAssertEqual(merged.outcome, 7)
        XCTAssertEqual(merged.task_count, 5)
        XCTAssertEqual(merged.synced_project_id, "sync")
        saved.due_date = nil
        XCTAssertNil(ProjectListPresentation.reconcilingSavedProject(cached, saved: saved).due_date)
        XCTAssertEqual(ProjectListPresentation.alphabetical([merged], search: "", status: .active, displayName: { $0 }), [])
        var later = cached; later.updated_at = "2026-09-11T03:00:00Z"
        XCTAssertEqual(ProjectListPresentation.reconcilingSavedProject(later, saved: saved), later)
        saved.id = "another"
        XCTAssertEqual(ProjectListPresentation.reconcilingSavedProject(cached, saved: saved), cached)
    }


    func testServerCountersKeepActualCompletionWithoutFetchingCompletedRows() throws {
        let native = Project(id: "native", name: "Native", task_count: 100, uncompleted_task_count: 20)
        let synced = Project(id: "synced", name: "Synced", task_count: 40, uncompleted_task_count: 0, synced_project_id: "external")
        var catalogue = LocalForecastProjectCatalogue()
        XCTAssertTrue(catalogue.append([native, synced]))
        XCTAssertEqual(catalogue.projectCompletions["native"], .init(completed: 80, total: 100))
        XCTAssertEqual(catalogue.projectCompletions["native"]?.percent, 80)
        XCTAssertEqual(catalogue.projectCompletions["synced"]?.percent, 100)
    }

    func testMixedNativeAndImportedCountsNeverInventACombinedPercentage() {
        let native = Project(id: "shared", name: "Native", task_count: 100, uncompleted_task_count: 20)
        let imported = Project(id: "shared", name: "Imported", task_count: 40, uncompleted_task_count: 0, synced_project_id: "external")
        for rows in [[native, imported], [imported, native]] {
            var catalogue = LocalForecastProjectCatalogue()
            XCTAssertTrue(catalogue.append(rows))
            XCTAssertEqual(catalogue.projects.count, 1)
            XCTAssertEqual(catalogue.projects.first?.synced_project_id, "external")
            XCTAssertNil(catalogue.projectCompletions["shared"])
        }
    }

    func testMissingInvalidOrEmptyProjectCountersRemainUnavailable() {
        for project in [Project(id: "p", name: "P"),
                        Project(id: "p", name: "P", task_count: 100),
                        Project(id: "p", name: "P", task_count: 100, uncompleted_task_count: 101),
                        Project(id: "p", name: "P", task_count: 100, uncompleted_task_count: -1),
                        Project(id: "p", name: "P", task_count: -1, uncompleted_task_count: 0),
                        Project(id: "p", name: "P", task_count: 0, uncompleted_task_count: 0)] {
            XCTAssertNil(ProjectListPresentation.completionFromCounts(project))
        }
    }
    func testActiveAlphabeticalListUsesCanonicalMetadataAcrossPagesAndKeepsSyncAssociation() {
        var catalogue = LocalForecastProjectCatalogue()
        XCTAssertTrue(catalogue.append([Project(id: "same", name: "external-placeholder", synced_project_id: "sync-id", synced_platform: "trello"),
                                        Project(id: "z", name: "Zulu")]))
        XCTAssertTrue(catalogue.append([Project(id: "same", name: "Alpha", outcome: 7), Project(id: "b", name: "Beta")]))
        let sorted = ProjectListPresentation.alphabetical(catalogue.projects, search: "", status: .active, displayName: { $0 })
        XCTAssertEqual(sorted.map(\.name), ["Alpha", "Beta", "Zulu"])
        XCTAssertEqual(sorted.first?.synced_project_id, "sync-id")
        XCTAssertEqual(sorted.first?.synced_platform, "trello")
        XCTAssertEqual(sorted.first?.outcome, 7)
        XCTAssertEqual(catalogue.nativeCount, 3)
    }

    func testAlphabeticalListSearchLifecycleAndEqualNameOrderingAreDeterministic() {
        let projects = [Project(id: "z", name: "Alpha"), Project(id: "a", name: "Alpha"),
                        Project(id: "other", name: "Beta"), Project(id: "done", name: "Alpha", status: "completed")]
        XCTAssertEqual(ProjectListPresentation.alphabetical(projects, search: " ALP ", status: .active, displayName: { $0 }).map(\.id), ["a", "z"])
        XCTAssertEqual(ProjectListPresentation.alphabetical(projects, search: "", status: .completed, displayName: { $0 }).map(\.id), ["done"])
    }

    func testFreshDetailNameRetainsKnownSyncAssociationWithoutReplacingAnotherIdentity() {
        let previous = Project(id: "same", name: "external-id", synced_project_id: "sync-id", synced_platform: "trello", outcome: 7)
        let merged = ProjectListPresentation.preservingSync(Project(id: "same", name: "Actual name"), from: previous)
        XCTAssertEqual(merged.name, "Actual name")
        XCTAssertEqual(merged.synced_project_id, "sync-id")
        XCTAssertEqual(merged.synced_platform, "trello")
        XCTAssertNil(merged.outcome, "A fresh null remains null; no unrelated metadata is invented")
        XCTAssertNil(ProjectListPresentation.preservingSync(Project(id: "other", name: "Other"), from: previous).synced_project_id)
        XCTAssertNil(ProjectListPresentation.preservingSync(Project(id: "same", name: "Changed association", synced_project_id: "other-sync"), from: previous).synced_platform)
    }

    func testDetailDisplayReconciliationPreservesForecastMetadataAndYieldsToNewerCatalogue() {
        var catalogue = Project(id: "same", name: "external-id", due_date: "2026-10-01", outcome: 7,
                                status: "active", updated_at: "2026-09-10T10:00:00Z")
        let detail = Project(id: "same", name: "Actual name", synced_project_id: "sync-id", synced_platform: "asana", due_date: "2026-11-01", outcome: 2,
                             status: "archived", updated_at: "2026-09-10T11:00:00Z")
        let resolved = ProjectListPresentation.reconcilingDisplayMetadata(catalogue, detail: detail)
        XCTAssertEqual(resolved.name, "Actual name")
        XCTAssertEqual(resolved.synced_project_id, "sync-id")
        XCTAssertEqual(resolved.synced_platform, "asana")
        XCTAssertEqual(resolved.due_date, catalogue.due_date)
        XCTAssertEqual(resolved.outcome, 7)
        XCTAssertEqual(resolved.status, "active")
        catalogue.name = "Renamed later"; catalogue.updated_at = "2026-09-10T12:00:00Z"
        XCTAssertEqual(ProjectListPresentation.reconcilingDisplayMetadata(catalogue, detail: detail).name, "Renamed later")
    }

    func testSyncedSourceDecodesOptionalProviderAndKeepsUnknownOrLegacyResponsesHonest() throws {
        let decoder = JSONDecoder()
        let legacy = try decoder.decode(Project.self, from: Data(#"{"id":"p","name":"Project","synced_project_id":"external"}"#.utf8))
        XCTAssertNil(legacy.synced_platform)
        let strings = ToDoStrings(values: [.syncedSource: "Sincronizado desde <SOURCE>", .syncedSourceUnavailable: "Origen no disponible"])
        XCTAssertEqual(strings.projectSyncSource(legacy), "Origen no disponible")
        for (platform, name) in [("zoho", "Zoho"), ("clickup", "ClickUp"), ("trello", "Trello"), ("jira", "Jira"),
                                 ("asana", "Asana"), ("monday", "monday.com"), ("google", "Google"), ("microsoft", "Microsoft")] {
            let data = try JSONSerialization.data(withJSONObject: ["id": "p", "name": "Project", "synced_project_id": "external", "synced_platform": platform])
            let project = try decoder.decode(Project.self, from: data)
            XCTAssertEqual(strings.projectSyncSource(project), "Sincronizado desde \(name)")
        }
        var unknown = legacy
        unknown.synced_platform = "future-provider"
        XCTAssertEqual(try decoder.decode(Project.self, from: JSONEncoder().encode(unknown)).synced_platform, "future-provider")
        XCTAssertEqual(strings.projectSyncSource(unknown), "Origen no disponible")
        let nullable = try decoder.decode(Project.self, from: Data(#"{"id":"p","name":"Project","synced_project_id":"external","synced_platform":null}"#.utf8))
        XCTAssertEqual(strings.projectSyncSource(nullable), "Origen no disponible")
    }

    // MARK: - Snapshot freshness

    /// Report 2026-09-15_17-41-45: the snapshot behind the project card was up to fifteen minutes
    /// old, and completing a task — the one edit that changes how much work is left — did not expire
    /// it. Coming back to the Projects screen re-served the pre-completion calculation.
    func testCompletingATaskExpiresTheForecastSnapshotInsteadOfReusingIt() {
        let reads = CountingProjectReader()
        let store = forecastStore(reads: reads)

        store.refreshIfNeeded()
        flushMainQueue()
        XCTAssertEqual(reads.count, 1)

        store.refreshIfNeeded()
        flushMainQueue()
        XCTAssertEqual(reads.count, 1, "Within the reuse window an ordinary appearance serves the snapshot")

        store.invalidateForCompletionChange()
        flushMainQueue()
        XCTAssertEqual(reads.count, 2, "A completion recalculates rather than waiting out the window")
        XCTAssertFalse(store.requiresFreshSnapshot)

        store.refreshIfNeeded()
        flushMainQueue()
        XCTAssertEqual(reads.count, 2, "The reuse window starts again from the fresh calculation")
    }

    /// The kanban, the To-do list, the Day Plan and the routine player all announce completions on
    /// `TodoCompletionBus`; the forecast has to be one of the listeners.
    func testACompletionAnnouncedByAnotherScreenReachesTheForecast() {
        let reads = CountingProjectReader()
        let store = forecastStore(reads: reads)
        store.refreshIfNeeded()
        flushMainQueue()
        XCTAssertEqual(reads.count, 1)

        TodoCompletionBus.post(todoID: "completed-in-the-kanban", completed: true)
        wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in reads.count == 2 }, object: nil)], timeout: 2)
    }

    private final class CountingProjectReader {
        var count = 0
    }

    /// A store whose reads fail immediately: enough to count recalculations without a network, a
    /// calendar or a day-by-day build.
    private func forecastStore(reads: CountingProjectReader) -> LocalForecastStore {
        let clock = today
        return LocalForecastStore(currentAccount: { "account" }, calendarPermission: { false },
                                  readProjects: { _, _, completion in reads.count += 1; completion(nil) },
                                  readTasks: { _, _, completion in completion(nil) },
                                  diagnostic: { _ in }, now: { clock }, scheduleRefresh: { _, _ in {} })
    }

    private func flushMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
    }

    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        return result
    }
    private var today: Date { calendar.date(from: DateComponents(year: 2026, month: 9, day: 10))! }
    private func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today)! }
    private func project(_ id: String, outcome: Int = 6, due: Int? = nil) -> Project {
        Project(id: id, name: id, due_date: due.map { ISO8601DateFormatter().string(from: day($0)) }, outcome: outcome)
    }
    private func task(_ id: String, project: String, minutes: Double?, notBefore: Int? = nil,
                      completed: Bool = false) -> LocalTimeForecast.TaskInput {
        .init(id: id, projectID: project, estimatedMinutes: minutes,
              notBefore: notBefore.map(day), completed: completed)
    }
    private func forecast(_ projects: [Project], tasks: [LocalTimeForecast.TaskInput], days: Int = 3) -> LocalTimeForecast.Result {
        let inputs: [LocalTimeForecast.DayInput] = (0..<days).map { offset in
            let date = day(offset)
            // Fourteen awake hours busy leaves two work hours/day with default sleep and zero extra care.
            return .init(date: date, meetings: [.init(start: date.addingTimeInterval(6 * 3600), end: date.addingTimeInterval(20 * 3600))], habits: [])
        }
        return LocalTimeForecast.calculate(days: inputs, projects: projects.map {
            .init(id: $0.id, outcome: $0.outcome ?? 0, dueDate: ToDoDates.parse($0.due_date))
        }, tasks: tasks, calendar: calendar)
    }
    private func portfolio(_ projects: [Project], tasks: [LocalTimeForecast.TaskInput], days: Int = 3) -> LocalForecastPortfolio {
        .make(projects: projects, forecast: forecast(projects, tasks: tasks, days: days), calendar: calendar)
    }

    /// The server's own task counters, which a portfolio row needs to tell "finished" from "empty".
    private func countedProject(_ id: String, due: Int?, totalTasks: Int, uncompletedTasks: Int) -> Project {
        Project(id: id, name: id, task_count: totalTasks, uncompleted_task_count: uncompletedTasks,
                due_date: due.map { ISO8601DateFormatter().string(from: day($0)) }, outcome: 6)
    }

    private func portfolioWithCounts(_ projects: [Project], tasks: [LocalTimeForecast.TaskInput],
                                     days: Int = 3) -> LocalForecastPortfolio {
        let inputs: [LocalTimeForecast.DayInput] = (0..<days).map { offset in
            let date = day(offset)
            return .init(date: date, meetings: [.init(start: date.addingTimeInterval(6 * 3600), end: date.addingTimeInterval(20 * 3600))], habits: [])
        }
        let result = LocalTimeForecast.calculate(days: inputs, projects: projects.map {
            .init(id: $0.id, outcome: $0.outcome ?? 0, dueDate: ToDoDates.parse($0.due_date),
                  totalTaskCount: $0.task_count, uncompletedTaskCount: $0.uncompleted_task_count)
        }, tasks: tasks, calendar: calendar)
        return .make(projects: projects, forecast: result, calendar: calendar)
    }

    func testRestoresAllThreeGroupsUsingLocalDeadlineAndAllocationEvidence() {
        let projects = [project("missed", outcome: 10, due: 0), project("urgent", outcome: 8, due: 1), project("later", due: 4)]
        let result = portfolio(projects, tasks: [task("a", project: "missed", minutes: 180),
            task("b", project: "urgent", minutes: 60), task("c", project: "later", minutes: 30, notBefore: 2)])
        XCTAssertEqual(result.groups.askForExtension.map(\.id), ["missed"])
        XCTAssertEqual(result.groups.startNow.map(\.id), ["urgent"])
        XCTAssertEqual(result.groups.backBurner.map(\.id), ["later"])
        XCTAssertEqual(result.rows.map(\.portfolioBucket), [.critical, .atRisk, .onTrack])
        XCTAssertTrue(result.isOvercommitted)
        XCTAssertEqual(result.assessedProjectIDs, Set(projects.map(\.id)))
    }

    /// Report 2026-09-15_17-41-45: "I completed all the tasks for MRFF ... it still said project at
    /// risk and 53%. Should have moved it to on track."
    ///
    /// With every task finished there is no outstanding work left to miss the deadline with, so the
    /// zero-estimate branch — written for a project whose remaining work has no estimates — must not
    /// claim a risk. The server counters still insist five of fifteen tasks are open (they ignore
    /// custom "done" columns); what the forecast downloaded is the honest number.
    func testFinishingEveryTaskMovesAProjectFromAtRiskToOnTrack() throws {
        let finished = countedProject("mrff", due: 0, totalTasks: 15, uncompletedTasks: 5)
        let result = portfolioWithCounts([finished], tasks: [])
        let row = try XCTUnwrap(result.rows.first)
        XCTAssertEqual(row.portfolioBucket, .onTrack)
        XCTAssertTrue(result.assessedProjectIDs.contains("mrff"), "A finished project is an assessment, not a guess")
        XCTAssertTrue(result.groups.askForExtension.isEmpty)
        XCTAssertTrue(result.groups.startNow.isEmpty)
        XCTAssertFalse(result.isOvercommitted)
        XCTAssertTrue(row.badgeList.isEmpty)
    }

    func testAProjectWithWorkStillOutstandingStaysAtRisk() throws {
        let project = countedProject("mrff", due: 0, totalTasks: 15, uncompletedTasks: 5)
        let result = portfolioWithCounts([project], tasks: [task("left", project: "mrff", minutes: nil)])
        XCTAssertEqual(try XCTUnwrap(result.rows.first).portfolioBucket, .atRisk)
        XCTAssertEqual(result.groups.startNow.map(\.id), ["mrff"])
    }

    func testAnEmptyProjectWithADeadlineIsStillNotAnAssessedOnTrackProject() throws {
        let result = portfolioWithCounts([countedProject("empty", due: 0, totalTasks: 0, uncompletedTasks: 0)], tasks: [])
        XCTAssertEqual(try XCTUnwrap(result.rows.first).portfolioBucket, .atRisk)
        XCTAssertFalse(result.assessedProjectIDs.contains("empty"))
    }

    func testMissingEstimatesStayVisibleWithoutInventedRiskOrTotalEffort() throws {
        let result = portfolio([project("unknown", due: 0)], tasks: [task("a", project: "unknown", minutes: nil)])
        XCTAssertEqual(result.groups.startNow.map(\.id), ["unknown"])
        XCTAssertTrue(result.groups.askForExtension.isEmpty)
        XCTAssertFalse(result.assessedProjectIDs.contains("unknown"))
        XCTAssertNil(try XCTUnwrap(result.rows.first).required_hours)
        XCTAssertNil(result.rows.first?.projected_completion_date)
        XCTAssertFalse(result.isOvercommitted)
    }

    func testDeadlineBeyondHorizonIsNotAFailedDeadlineWhenWorkRemains() {
        let result = portfolio([project("distant", due: 20)], tasks: [task("a", project: "distant", minutes: 1000)], days: 1)
        XCTAssertTrue(result.groups.askForExtension.isEmpty)
        XCTAssertFalse(result.assessedProjectIDs.contains("distant"))
        XCTAssertNil(result.rows.first?.projected_completion_date)
        XCTAssertFalse(result.isOvercommitted)
    }

    func testEmptyAndCompletedProjectsAreNotPromotedAsWorkToStart() {
        let result = portfolio([project("empty", outcome: 10, due: 0), project("finished", outcome: 8, due: 0)],
            tasks: [task("a", project: "finished", minutes: 30, completed: true)])
        XCTAssertTrue(result.groups.askForExtension.isEmpty)
        XCTAssertTrue(result.groups.startNow.isEmpty)
        XCTAssertEqual(result.groups.backBurner.map(\.id), ["empty", "finished"])
        XCTAssertFalse(result.assessedProjectIDs.contains("empty"))
        XCTAssertTrue(result.assessedProjectIDs.contains("finished"))
    }

    func testCompletedUnestimatedTasksDoNotBecomeWorkToStart() {
        let result = portfolio([project("finished", outcome: 10, due: 0)],
            tasks: [task("done", project: "finished", minutes: nil, completed: true)])
        XCTAssertTrue(result.groups.askForExtension.isEmpty)
        XCTAssertTrue(result.groups.startNow.isEmpty)
        XCTAssertEqual(result.groups.backBurner.map(\.id), ["finished"])
        XCTAssertFalse(result.isOvercommitted)
        XCTAssertFalse(result.assessedProjectIDs.contains("finished"), "Do not invent effort or percentage from missing historical estimates")
    }

    func testKnownDeadlineMissRemainsActionableEvenWhenOtherWorkHasNoEstimate() {
        let result = portfolio([project("missed", due: 0)], tasks: [task("a", project: "missed", minutes: 180),
            task("b", project: "missed", minutes: nil)])
        XCTAssertEqual(result.groups.askForExtension.map(\.id), ["missed"])
        XCTAssertTrue(result.assessedProjectIDs.contains("missed"))
        XCTAssertNil(result.rows.first?.required_hours, "Known effort is only a lower bound, not the project's total")
    }

    func testGroupOrderingUsesOutcomeAndDoesNotDropCardsAtTheVisualLimit() {
        let projects = (0..<9).map { project("p\($0)", outcome: 10 - $0, due: 0) }
        let tasks = projects.map { task($0.id, project: $0.id, minutes: 180) }
        let result = portfolio(Array(projects.reversed()), tasks: tasks)
        XCTAssertEqual(result.groups.askForExtension.map(\.id), projects.map(\.id))
        XCTAssertEqual(result.rows.count, 9, "Only the existing view's Start/backburner limit may trim visible cards")
    }

    func testDetailMeetingsHideSleepAndRetainOnlyAwakeTail() throws {
        let hidden = ScheduleBlock(kind: .meeting, title: "Night", start: today, end: today.addingTimeInterval(6 * 3600), eventID: "night")
        let partial = ScheduleBlock(kind: .meeting, title: "Sleep", start: today, end: today.addingTimeInterval(6.5 * 3600), eventID: "sleep")
        let rows = LocalTimeForecast.detailBlocks([hidden, partial], on: today, calendar: calendar)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(row.title, "Sleep")
        XCTAssertEqual(row.eventID, "sleep")
        XCTAssertEqual(row.start, today.addingTimeInterval(6 * 3600))
        XCTAssertEqual(row.durationSeconds, 30 * 60)
        XCTAssertEqual(partial.durationSeconds, 390 * 60, "Display preparation must not change the original schedule")
    }

    func testDetailDaytimeSleepSplitsOneEventAndPreservesIdentity() {
        let block = ScheduleBlock(kind: .meeting, title: "Long event", start: today.addingTimeInterval(8 * 3600),
                                  end: today.addingTimeInterval(18 * 3600), subtitle: "Original", eventID: "event")
        let settings = LocalTimeForecast.CapacitySettings(sleepStartMinute: 12 * 60, sleepEndMinute: 14 * 60)
        let rows = LocalTimeForecast.detailBlocks([block], on: today, settings: settings, calendar: calendar)
        XCTAssertEqual(rows.map(\.start), [today.addingTimeInterval(8 * 3600), today.addingTimeInterval(14 * 3600)])
        XCTAssertEqual(rows.map(\.end), [today.addingTimeInterval(12 * 3600), today.addingTimeInterval(18 * 3600)])
        XCTAssertEqual(rows.map(\.eventID), ["event", "event"])
        XCTAssertEqual(rows.map(\.title), ["Long event", "Long event"])
        XCTAssertEqual(rows.map(\.subtitle), ["Original", "Original"])
    }

    func testDetailRowsUseSnapshotRemainingTimeAndCalendarDayBounds() {
        let spanning = ScheduleBlock(kind: .meeting, title: "Spanning", start: day(-1), end: day(2))
        let rows = LocalTimeForecast.detailBlocks([spanning], on: today,
            availableFrom: today.addingTimeInterval(15 * 3600), calendar: calendar)
        XCTAssertEqual(rows.map(\.start), [today.addingTimeInterval(15 * 3600)])
        XCTAssertEqual(rows.map(\.end), [today.addingTimeInterval(22 * 3600)])
        XCTAssertTrue(LocalTimeForecast.detailBlocks([spanning], on: today, availableFrom: day(1), calendar: calendar).isEmpty)
        let next = LocalTimeForecast.detailBlocks([spanning], on: day(1), availableFrom: today, calendar: calendar)
        XCTAssertEqual(next.map(\.start), [day(1).addingTimeInterval(6 * 3600)])
        XCTAssertEqual(next.map(\.end), [day(1).addingTimeInterval(22 * 3600)])
    }

    func testDetailKeepsShortPlacedHabitMetadataAndExcludesFillersAndOverflow() throws {
        let start = today.addingTimeInterval(7 * 3600)
        var habit = ScheduleBlock(kind: .habit, title: "Short habit", start: start, end: start.addingTimeInterval(30),
                                  habitIndex: 2, isActionable: true, routineName: "Morning")
        habit.habitId = "habit-id"
        let overflow = ScheduleBlock(kind: .habit, title: "Overflow", start: start, end: start.addingTimeInterval(60), didOverflow: true)
        let filler = ScheduleBlock(kind: .deepWork, title: "Work", start: start, end: start.addingTimeInterval(60))
        let rows = LocalTimeForecast.detailBlocks([habit, overflow, filler], on: today,
            availableFrom: start.addingTimeInterval(10), calendar: calendar)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(row.durationSeconds, 20)
        XCTAssertEqual(row.habitId, "habit-id")
        XCTAssertEqual(row.habitIndex, 2)
        XCTAssertEqual(row.routineName, "Morning")
        XCTAssertTrue(row.isActionable)
    }

    func testDetailOverlappingEventsKeepTheirNamesButCapacityCountsTheirUnion() throws {
        let blocks = [ScheduleBlock(kind: .meeting, title: "First", start: today.addingTimeInterval(5 * 3600), end: today.addingTimeInterval(7 * 3600)),
                      ScheduleBlock(kind: .meeting, title: "Second", start: today.addingTimeInterval(6.5 * 3600), end: today.addingTimeInterval(8 * 3600))]
        let rows = LocalTimeForecast.detailBlocks(blocks, on: today, calendar: calendar)
        let result = LocalTimeForecast.calculate(days: [.fromDayPlan(date: today, blocks: blocks)], projects: [], tasks: [], calendar: calendar)
        let fromRows = LocalTimeForecast.calculate(days: [.fromDayPlan(date: today, blocks: rows)], projects: [], tasks: [], calendar: calendar)
        XCTAssertEqual(rows.map(\.title), ["First", "Second"])
        XCTAssertEqual(rows.reduce(0) { $0 + $1.durationSeconds }, 150 * 60)
        XCTAssertEqual(try XCTUnwrap(result.days.first).capacity.meetingMinutes, 120)
        XCTAssertEqual(fromRows.days.first?.capacity.meetingMinutes, result.days.first?.capacity.meetingMinutes)
    }

    func testDetailSleepClippingUsesLocalClockAcrossBothDSTChanges() throws {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        for (month, date, length) in [(3, 8, 23), (11, 1, 25)] {
            let start = try XCTUnwrap(local.date(from: DateComponents(year: 2026, month: month, day: date)))
            let end = try XCTUnwrap(local.date(byAdding: .day, value: 1, to: start))
            XCTAssertEqual(end.timeIntervalSince(start) / 3600, Double(length))
            let event = ScheduleBlock(kind: .meeting, title: "All day", start: start, end: end)
            let rows = LocalTimeForecast.detailBlocks([event], on: start, calendar: local)
            let row = try XCTUnwrap(rows.first)
            XCTAssertEqual(rows.count, 1)
            XCTAssertEqual(local.component(.hour, from: row.start), 6)
            XCTAssertEqual(local.component(.hour, from: row.end), 22)
            XCTAssertEqual(row.durationSeconds, 16 * 3600)
        }
    }

    func testDetailInvalidSettingsUsesTheSameDefaultsAsCapacity() throws {
        let invalid = LocalTimeForecast.CapacitySettings(sleepStartMinute: 0, sleepEndMinute: 0)
        let event = ScheduleBlock(kind: .meeting, title: "All day", start: today, end: day(1))
        let rows = LocalTimeForecast.detailBlocks([event], on: today, settings: invalid, calendar: calendar)
        let result = LocalTimeForecast.calculate(days: [.fromDayPlan(date: today, blocks: [event], settings: invalid)],
                                                 projects: [], tasks: [], calendar: calendar)
        XCTAssertEqual(rows.map(\.durationSeconds), [16 * 3600])
        XCTAssertEqual(try XCTUnwrap(result.days.first).capacity.meetingMinutes, 16 * 60)
    }

    func testRemainingEffortExcludesCompletedTasksAndHabitAbsorptionIsNotLost() throws {
        let projects = [project("work", due: 0)]
        let input = LocalTimeForecast.DayInput(date: today, meetings: [],
            habits: [.habit(id: "habit", blockKey: "habit:test", interval: .init(start: today.addingTimeInterval(6 * 3600), end: today.addingTimeInterval(7 * 3600)))])
        let result = LocalTimeForecast.calculate(days: [input], projects: [.init(id: "work", dueDate: today)],
            tasks: [task("done", project: "work", minutes: 30, completed: true),
                    .init(id: "open", projectID: "work", estimatedMinutes: 60,
                          blockAssignment: .init(date: today, blockKey: "habit:test"))], calendar: calendar)
        let grouped = LocalForecastPortfolio.make(projects: projects, forecast: result, calendar: calendar)
        let row = try XCTUnwrap(grouped.rows.first)
        XCTAssertEqual(row.required_hours, 1)
        XCTAssertEqual(row.deficit_hours, nil)
        XCTAssertTrue(grouped.groups.askForExtension.isEmpty)
        XCTAssertTrue(row.badgeList.contains(.startNow), "Habit-absorbed task work still counts as today's work")
        XCTAssertNil(row.scheduled_hours, "Forecast allocation must not be presented as an already-saved schedule")
    }
}
