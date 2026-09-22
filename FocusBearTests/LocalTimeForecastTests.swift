@testable import Focus_Bear
import XCTest
import EventKit

final class LocalTimeForecastTests: XCTestCase {
    /// Renamed and re-expected: the ordering is now DEADLINE then rating, not rating then deadline.
    /// Comparing the rating first let a project with no due date — or a later one — take days from a
    /// project with a nearer deadline, which is what the PO hit ("UX has no due date so shouldn't be
    /// prioritised ahead of projects that have due date", report 2026-09-16_06-40-52).
    func testFreshProjectForecastIgnoresPreviousPlacementsAndUsesDeadlineThenRating() throws {
        let projects = [Project(id: "urgent-lower", name: "Lower", due_date: "2026-09-07", outcome: 8),
                        Project(id: "highest-later", name: "Later", due_date: "2026-09-09", outcome: 10),
                        Project(id: "highest-nearest", name: "Nearest", due_date: "2026-09-08", outcome: 10)]
        let rows = try projects.map { project in
            try remoteTask(["id": project.id, "project_id": project.id, "duration": 3600,
                            "outcome": project.id == "urgent-lower" ? 10 : 2,
                            "planned_date": "2030-01-01", "planned_block_key": "habit:Old placement"])
        }
        let tasks = LocalForecastSnapshot.projectTasks(remote: rows, projects: projects)
        XCTAssertTrue(tasks.allSatisfy { $0.notBefore == nil && $0.blockAssignment == nil })
        let inputs = projects.map { Forecast.ProjectInput(id: $0.id, outcome: $0.outcome ?? 0, dueDate: ToDoDates.parse($0.due_date)) }
        let result = calculate(days: [.init(date: date(), meetings: [interval(6, 21)], habits: [])], projects: inputs, tasks: tasks)
        XCTAssertEqual(result.days[0].capacity.availableWorkMinutes, 60)
        // "urgent-lower" is due the 7th, before both others, so it is worked first however the three
        // are rated; "highest-nearest" (8th) then "highest-later" (9th) follow by deadline.
        XCTAssertEqual(result.days[0].allocations.map(\.taskID), ["urgent-lower"])
        XCTAssertEqual(result.tasks.map { $0.task.id }, ["urgent-lower", "highest-nearest", "highest-later"])
    }

    func testFreshProjectForecastUsesOnlyKnownProjectBacklogAndUnambiguousImportIdentity() throws {
        let projects = [Project(id: "native", name: "Native"),
                        Project(id: "imported", name: "Imported", synced_project_id: "external"),
                        Project(id: "collision-a", name: "A", synced_project_id: "ambiguous"),
                        Project(id: "collision-b", name: "B", synced_project_id: "ambiguous")]
        let rows = try [remoteTask(["id": "n", "project_id": "native"]),
                        remoteTask(["id": "s", "synced_project_id": "external"]),
                        remoteTask(["id": "unprojected"]),
                        remoteTask(["id": "inactive", "project_id": "not-in-active-catalogue"]),
                        remoteTask(["id": "ambiguous", "synced_project_id": "ambiguous"])]
        let tasks = LocalForecastSnapshot.projectTasks(remote: rows + [rows[0]], projects: projects)
        XCTAssertEqual(tasks.map(\.id), ["n", "s"])
        XCTAssertEqual(tasks.compactMap(\.projectID), ["native", "imported"])
        XCTAssertTrue(tasks.allSatisfy { $0.estimatedMinutes == 17 })
    }

    func testFreshProjectForecastPreservesLegacyCompletionCoverageWithoutAllocatingDoneWork() throws {
        let project = Project(id: "p", name: "Project", custom_statuses: [
            .init(id: "open", label: "Open", should_complete_task: false),
            .init(id: "done", label: "Done", should_complete_task: true)])
        let rows = try [remoteTask(["id": "open", "project_id": "p", "status": "COMPLETED", "custom_status_id": "open"]),
                        remoteTask(["id": "done", "project_id": "p", "status": "NOT_STARTED", "custom_status_id": "done"])]
        let tasks = LocalForecastSnapshot.projectTasks(remote: rows, projects: [project])
        XCTAssertEqual(tasks.map(\.completed), [false, true])
        let result = calculate(days: [day()], projects: [.init(id: "p")], tasks: tasks)
        XCTAssertEqual(result.days[0].allocations.map(\.taskID), ["open"])
        XCTAssertEqual(result.projects[0].completedMinutes, 17)
        XCTAssertTrue(LocalForecastSnapshot.projectTasks(remote: rows, projects: [project], serverExcludedCompleted: true).allSatisfy { !$0.completed })
    }

    private func taskPage(_ rows: [[String: Any]], page: Int = 1, total: Int, next: Bool = false,
                          filtered: Bool? = true) throws -> AllApi.ForecastTasksPage {
        var meta: [String: Any] = ["page": page, "itemCount": total, "hasNextPage": next]
        if let filtered = filtered { meta["excludesCompleted"] = filtered }
        return try JSONDecoder().decode(AllApi.ForecastTasksPage.self,
            from: JSONSerialization.data(withJSONObject: ["data": rows, "meta": meta]))
    }

    private func unfinishedPage(_ ids: [String], page: Int = 1, total: Int, next: Bool = false,
                                filtered: Bool? = true) throws -> AllApi.ForecastTasksPage {
        try taskPage(ids.map { ["id": $0, "title": "Task", "status": "NOT_STARTED"] },
                     page: page, total: total, next: next, filtered: filtered)
    }

    func testForecastQueryRequestsEffectiveUnfinishedWorkWithStableServerOrdering() throws {
        let url = try XCTUnwrap(URLComponents(string: ToDoListQuery.forecast(page: 3).path))
        let query = Dictionary((url.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first })
        XCTAssertEqual(query["exclude_completed"], "true")
        XCTAssertEqual(query["sort_mode"], "DUE_DATE")
        XCTAssertEqual(query["page"], "3")
        XCTAssertEqual(query["take"], "50")
        XCTAssertNil(query["status"], "Exact enum filters would omit custom/external unfinished statuses")
        XCTAssertFalse(ToDoListQuery(page: 1).path.contains("exclude_completed"), "Other task callers keep their existing contract")
    }

    func testFilteredCatalogueAcceptsAllPagesAndEmptyUnfinishedWork() throws {
        var catalogue = LocalForecastTaskCatalogue()
        XCTAssertTrue(catalogue.append(try unfinishedPage(["a"], total: 2, next: true), page: 1))
        XCTAssertEqual(catalogue.expectedCount, 2)
        XCTAssertFalse(catalogue.isComplete)
        XCTAssertTrue(catalogue.append(try unfinishedPage(["b"], page: 2, total: 2), page: 2))
        XCTAssertEqual(catalogue.tasks.map(\.id), ["a", "b"])
        XCTAssertTrue(catalogue.isComplete)
        var empty = LocalForecastTaskCatalogue()
        XCTAssertTrue(empty.append(try unfinishedPage([], total: 0), page: 1))
        XCTAssertTrue(empty.isComplete)
    }

    func testUnfilteredServerIsDownloadedWholeAndFinishedWorkDroppedLocally() throws {
        for marker: Bool? in [nil, false] {
            var catalogue = LocalForecastTaskCatalogue(completingStatusIds: ["shipped"])
            XCTAssertTrue(catalogue.append(try taskPage(
                [["id": "open", "title": "Task", "status": "NOT_STARTED"],
                 ["id": "done", "title": "Task", "status": "COMPLETED"],
                 ["id": "shipped", "title": "Task", "status": "NOT_STARTED", "custom_status_id": "shipped"]],
                total: 4, next: true, filtered: marker), page: 1))
            XCTAssertTrue(catalogue.append(try taskPage(
                [["id": "later", "title": "Task", "status": "IN_PROGRESS"]],
                page: 2, total: 4, filtered: marker), page: 2))
            XCTAssertTrue(catalogue.isComplete)
            XCTAssertEqual(catalogue.downloadedCount, 4, "Paging arithmetic counts what the server sent")
            XCTAssertEqual(catalogue.tasks.map(\.id), ["open", "later"],
                           "Finished work is filtered here rather than refusing to forecast at all")
        }
    }

    /// Report 2026-09-15_17-41-45: "I completed all the tasks for MRFF by going into the project
    /// kanban and marking tasks complete. When I came back, it still said project at risk and 53%."
    ///
    /// Completing a task anywhere other than the kanban sets `status` alone and leaves
    /// `custom_status_id` on the open column the task was in. The server's `exclude_completed` reads
    /// the column first, so it hands those rows back as outstanding even though the kanban and the
    /// To-do list both draw them as done. The forecast planned that already-finished work and kept
    /// the project at risk. The local rule is authoritative, whatever the server filtered.
    func testTasksCompletedOutsideTheirColumnAreDroppedEvenWhenTheServerSaysItFiltered() throws {
        var catalogue = LocalForecastTaskCatalogue(completingStatusIds: ["done-column"])
        XCTAssertTrue(catalogue.append(try taskPage([
            ["id": "ticked-elsewhere", "title": "Task", "status": "COMPLETED", "custom_status_id": "todo-column"],
            ["id": "dragged-to-done", "title": "Task", "status": "NOT_STARTED", "custom_status_id": "done-column"],
            ["id": "still-to-do", "title": "Task", "status": "NOT_STARTED", "custom_status_id": "todo-column"]],
            total: 3, filtered: true), page: 1))
        XCTAssertTrue(catalogue.isComplete)
        XCTAssertEqual(catalogue.downloadedCount, 3, "Paging arithmetic still counts what the server sent")
        XCTAssertEqual(catalogue.tasks.map(\.id), ["still-to-do"])
    }

    func testCatalogueRejectsFilterCoverageChangingMidDownload() throws {
        var catalogue = LocalForecastTaskCatalogue()
        XCTAssertTrue(catalogue.append(try unfinishedPage(["a"], total: 2, next: true), page: 1))
        XCTAssertFalse(catalogue.append(try unfinishedPage(["b"], page: 2, total: 2, filtered: nil), page: 2),
                       "A server that filters page one and not page two is not a coherent catalogue")
        XCTAssertEqual(catalogue.tasks.map(\.id), ["a"])
    }

    func testFilteredCatalogueRejectsDuplicateRowsAndChangingCoverage() throws {
        var duplicate = LocalForecastTaskCatalogue()
        XCTAssertFalse(duplicate.append(try unfinishedPage(["a", "a"], total: 2), page: 1))
        var catalogue = LocalForecastTaskCatalogue()
        XCTAssertTrue(catalogue.append(try unfinishedPage(["a"], total: 3, next: true), page: 1))
        XCTAssertFalse(catalogue.append(try unfinishedPage(["a", "b"], page: 2, total: 3), page: 2))
        XCTAssertFalse(catalogue.append(try unfinishedPage(["b"], page: 2, total: 2), page: 2))
        XCTAssertFalse(catalogue.append(try unfinishedPage(["b"], page: 2, total: 3), page: 2))
        XCTAssertEqual(catalogue.tasks.map(\.id), ["a"], "Rejected pages cannot mutate accepted coverage")
        XCTAssertFalse(catalogue.isComplete)
    }

    /// A server that doesn't understand `exclude_completed` is slower, not a failure: the forecast is
    /// computed locally from a calendar the server never sees, so it must not depend on server-side
    /// filtering (report 2026-09-14 — the Projects screen showed "not available on the server yet").
    func testServerWithoutTheFilterStillForecasts() throws {
        let projects = try JSONDecoder().decode(ProjectsPage.self, from: Data(#"{"data":[],"meta":{"page":1,"itemCount":0,"hasNextPage":false}}"#.utf8))
        let first = try taskPage([["id": "open", "title": "Task", "status": "NOT_STARTED"],
                                  ["id": "history", "title": "Task", "status": "COMPLETED"]],
                                 total: 3, next: true, filtered: nil)
        let second = try taskPage([["id": "later", "title": "Task", "status": "IN_PROGRESS"]],
                                  page: 2, total: 3, filtered: nil)
        var reads = 0
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { false },
            readProjects: { _, _, completed in completed(projects) },
            readTasks: { page, _, completed in reads += 1; completed(page == 1 ? first : second) },
            diagnostic: { _ in })
        store.horizonDays = 7
        let finished = expectation(description: "Old server forecasts from what it sent")
        store.refresh { success in XCTAssertTrue(success); finished.fulfill() }
        wait(for: [finished], timeout: 10)
        XCTAssertEqual(reads, 2, "Every page is downloaded, completed history included")
        XCTAssertNil(store.error)
        XCTAssertEqual(store.tasks.map(\.id), ["open", "later"], "Finished work never reaches the forecast")
        XCTAssertFalse(store.isLoading)
    }

    func testOldAccountTaskCallbackCannotPublishErrorOrProgress() throws {
        let projects = try JSONDecoder().decode(ProjectsPage.self, from: Data(#"{"data":[],"meta":{"page":1,"itemCount":0,"hasNextPage":false}}"#.utf8))
        let history = try unfinishedPage(["history"], total: 4708, next: true, filtered: nil)
        var account = "a"
        var taskResponse: ((AllApi.ForecastTasksPage?) -> Void)?
        let requested = expectation(description: "Original account task request")
        let store = LocalForecastStore(currentAccount: { account }, calendarPermission: { false },
            readProjects: { _, _, completed in completed(projects) },
            readTasks: { _, captured, completed in
                XCTAssertEqual(captured, "a"); taskResponse = completed; requested.fulfill()
            }, diagnostic: { _ in })
        let finished = expectation(description: "Old account callback rejected")
        store.refresh { success in XCTAssertFalse(success); finished.fulfill() }
        wait(for: [requested], timeout: 2)
        account = "b"
        taskResponse?(history)
        wait(for: [finished], timeout: 2)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.loadProgress, .init(stage: .tasks))
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertFalse(store.hasCurrentSnapshot)
    }

    func testSnapshotHonorsCustomOpenAndDoneColumnsWithoutCreditingCompletedHistory() throws {
        let project = Project(id: "p", name: "Project", custom_statuses: [
            .init(id: "open", label: "Open", should_complete_task: false),
            .init(id: "done", label: "Open legacy duplicate", should_complete_task: false),
            .init(id: "done", label: "Done", should_complete_task: true)])
        let rows = try [
            remoteTask(["id": "custom-open", "project_id": "p", "status": "COMPLETED", "custom_status_id": "open"]),
            remoteTask(["id": "custom-done", "project_id": "p", "status": "NOT_STARTED", "custom_status_id": "done"]),
            remoteTask(["id": "external", "project_id": "p", "status": "Review"]),
            remoteTask(["id": "legacy-done", "project_id": "p", "status": "COMPLETED", "custom_status_id": "removed-column"])
        ]
        let tasks = LocalForecastSnapshot.tasks(remote: rows, local: [], projects: [project], today: date(), calendar: calendar)
        XCTAssertEqual(tasks.map(\.id), ["custom-open", "external"])
        XCTAssertTrue(tasks.allSatisfy { !$0.completed && $0.projectID == "p" })
    }

    func testServerFilteredCustomOpenTaskWithoutProjectMetadataStillConsumesCapacity() throws {
        let native = try remoteTask(["id": "native", "project_id": "inactive-project", "status": "COMPLETED", "custom_status_id": "open"])
        let imported = try remoteTask(["id": "imported", "synced_project_id": "unknown-import", "status": "COMPLETED", "custom_status_id": "open"])
        let tasks = LocalForecastSnapshot.tasks(remote: [native, imported], local: [], projects: [],
            today: date(), calendar: calendar, serverExcludedCompleted: true)
        XCTAssertEqual(tasks.map(\.id), ["native", "imported"])
        XCTAssertTrue(tasks.allSatisfy { !$0.completed && $0.projectID == nil })
        XCTAssertEqual(calculate(days: [day()], tasks: tasks).days[0].allocatedWorkMinutes, 34)
    }

    func testHydratedDoneCopyCannotOverrideAnAcknowledgedUnfinishedCustomOpenTask() throws {
        let remote = try remoteTask(["id": "server", "project_id": "p", "status": "COMPLETED", "custom_status_id": "open", "due_date": "2026-09-07"])
        // DayPlanTaskStore.hydrate currently persists done=true from raw COMPLETED and never
        // downgrades it. This is the real cached shape, not proof of a pending user completion.
        let hydrated = DayPlanTask(id: "local", title: "Local title", durationMinutes: 17, done: true,
            sourceTaskId: "server", blockKey: "habit:Study", project: "Project")
        let project = Project(id: "p", name: "Project", custom_statuses: [.init(id: "open", label: "Open", should_complete_task: false)])
        for projects in [[project], []] {
            let tasks = LocalForecastSnapshot.tasks(remote: [remote], local: [(date(), hydrated)], projects: projects,
                today: date(), calendar: calendar, serverExcludedCompleted: true)
            XCTAssertEqual(tasks.count, 1)
            XCTAssertFalse(try XCTUnwrap(tasks.first).completed)
            XCTAssertEqual(tasks.first?.id, "server")
            XCTAssertEqual(tasks.first?.blockAssignment?.blockKey, "habit:Study")
            XCTAssertEqual(calculate(days: [day()], tasks: tasks).days[0].allocatedWorkMinutes, 17)
        }
    }

    func testLocalCompletedHabitShareIsReservedOnceWithoutInventingProjectProgress() throws {
        let done = DayPlanTask(id: "local", title: "Done", durationMinutes: 7, done: true,
                              sourceTaskId: "done-server", blockKey: "habit:Study", project: "Project")
        var duplicate = done; duplicate.id = "other-local-copy"
        let pending = try remoteTask(["id": "pending", "project_id": "p", "duration": 420,
                                      "planned_date": "2026-09-07", "due_date": "2026-09-07", "planned_block_key": "habit:Study"])
        let tasks = LocalForecastSnapshot.tasks(remote: [pending], local: [(date(), done), (date(), duplicate)],
            projects: [Project(id: "p", name: "Project")], today: date(), calendar: calendar)
        XCTAssertEqual(tasks.filter(\.completed).count, 1)
        XCTAssertNil(tasks.first { $0.completed }?.projectID)
        let habit = Forecast.PlacedBlock.habit(id: "study", blockKey: "habit:Study",
            interval: .init(start: date(hour: 12), end: date(hour: 12, minute: 10)))
        let result = calculate(days: [.init(date: date(), meetings: [], habits: [habit])],
                               projects: [.init(id: "p")], tasks: tasks)
        XCTAssertEqual(result.days[0].absorbedBlockMinutes, 3)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 4)
        XCTAssertEqual(result.projects[0].completedMinutes, 0)
        XCTAssertEqual(result.projects[0].estimatedMinutes, 7)
    }

    func testDefaultSleepAndZeroExtraCareDoNotDoubleCountCalendarSleepOrWakeOverlap() {
        let input = Forecast.DayInput(date: date(), meetings: [interval(0, 6),
            .init(start: date(hour: 5), end: date(hour: 6, minute: 30)),
            .init(start: date(hour: 6, minute: 15), end: date(hour: 7, minute: 30))], habits: [
                .habit(id: "routine", blockKey: "habit:routine", interval: interval(7, 9))])
        let capacity = calculate(days: [input]).days[0].capacity
        XCTAssertEqual(capacity.totalMinutes, 1440)
        XCTAssertEqual(capacity.sleepMinutes, 480)
        XCTAssertEqual(capacity.selfCareMinutes, 0)
        XCTAssertEqual(capacity.meetingMinutes, 90)
        XCTAssertEqual(capacity.habitMinutes, 90)
        XCTAssertEqual(capacity.availableWorkMinutes, 780)
    }

    func testConfiguredOvernightAndDaytimeSleepExcludeOnlyTheirActualOverlap() {
        let meetings = [interval(6, 8), interval(15, 17)]
        let overnight = Forecast.CapacitySettings(sleepStartMinute: 23 * 60, sleepEndMinute: 7 * 60, selfCareMinutes: 30)
        let first = calculate(days: [.init(date: date(), meetings: meetings, habits: [], settings: overnight)]).days[0].capacity
        XCTAssertEqual(first.sleepMinutes, 480)
        XCTAssertEqual(first.meetingMinutes, 180)
        XCTAssertEqual(first.availableWorkMinutes, 750)
        let daytime = Forecast.CapacitySettings(sleepStartMinute: 10 * 60, sleepEndMinute: 18 * 60)
        let second = calculate(days: [.init(date: date(), meetings: meetings, habits: [], settings: daytime)]).days[0].capacity
        XCTAssertEqual(second.meetingMinutes, 120)
        XCTAssertEqual(second.availableWorkMinutes, 840)
    }

    func testTodayCannotReuseElapsedCalendarOrHabitTimeAndNetsPlannedWorkOnce() {
        let blocks = [ScheduleBlock(kind: .meeting, title: "Past", start: date(hour: 8), end: date(hour: 9)),
                      ScheduleBlock(kind: .habit, title: "Study", start: date(hour: 12), end: date(hour: 13))]
        let input = Forecast.DayInput.fromDayPlan(date: date(), blocks: blocks, availableFrom: date(hour: 12, minute: 30))
        let result = calculate(days: [input], tasks: [.init(id: "t", estimatedMinutes: 75,
            blockAssignment: .init(date: date(), blockKey: "habit:Study"))])
        let day = result.days[0]
        XCTAssertEqual(day.capacity.totalMinutes, 690)
        XCTAssertEqual(day.capacity.meetingMinutes, 0)
        XCTAssertEqual(day.capacity.habitMinutes, 30)
        XCTAssertEqual(day.capacity.sleepMinutes, 120)
        XCTAssertEqual(day.absorbedBlockMinutes, 30)
        XCTAssertEqual(day.allocatedWorkMinutes, 45)
        XCTAssertEqual(day.capacity.availableWorkMinutes, 540)
        XCTAssertEqual(day.remainingWorkMinutes, 495)
        XCTAssertEqual(day.remainingWorkMinutes + day.allocatedWorkMinutes, 540, "Day Plan free plus planned work equals the shared work window")
        let past = Forecast.DayInput.fromDayPlan(date: date(), blocks: blocks, availableFrom: date(hour: 14))
        XCTAssertEqual(calculate(days: [past], tasks: [.init(id: "t", estimatedMinutes: 75,
            blockAssignment: .init(date: date(), blockKey: "habit:Study"))]).days[0].absorbedBlockMinutes, 0)
    }

    func testFallDSTUsesTwentyFiveHourDayAndNineHourOvernightSleep() {
        let start = date(5, month: 4)
        let end = date(6, month: 4)
        XCTAssertEqual(end.timeIntervalSince(start), 25 * 3600)
        let capacity = calculate(days: [.init(date: start, meetings: [], habits: [])]).days[0].capacity
        XCTAssertEqual(capacity.totalMinutes, 1500)
        XCTAssertEqual(capacity.sleepMinutes, 540)
        XCTAssertEqual(capacity.availableWorkMinutes, 960)
    }

    func testCapacitySettingsAreAccountScopedAllowZeroAndRejectInvalidOrStaleSaves() throws {
        let suite = "LocalForecastSettingsTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var account = "a"
        let zero = Forecast.CapacitySettings(sleepStartMinute: 23 * 60, sleepEndMinute: 7 * 60, selfCareMinutes: 0)
        XCTAssertTrue(LocalForecastPreferences.save(zero, account: "a", currentAccount: { account }, defaults: defaults))
        XCTAssertEqual(LocalForecastPreferences.load(account: "a", defaults: defaults), zero)
        XCTAssertEqual(LocalForecastPreferences.load(account: "b", defaults: defaults), .init())
        let invalid = Forecast.CapacitySettings(sleepStartMinute: 0, sleepEndMinute: 0, selfCareMinutes: -1)
        XCTAssertFalse(LocalForecastPreferences.save(invalid, account: "a", currentAccount: { account }, defaults: defaults))
        account = "b"
        XCTAssertFalse(LocalForecastPreferences.save(.init(selfCareMinutes: 90), account: "a", currentAccount: { account }, defaults: defaults))
        XCTAssertEqual(LocalForecastPreferences.load(account: "a", defaults: defaults), zero)
        XCTAssertFalse(LocalForecastPreferences.save(zero, account: "", currentAccount: { "" }, defaults: defaults))
    }

    func testInvalidCapacityInputFallsBackToValidSleepRatherThanCreatingExtraHours() {
        let input = Forecast.DayInput(date: date(), meetings: [], habits: [],
            settings: .init(sleepStartMinute: 1440, sleepEndMinute: -1, selfCareMinutes: -100))
        let capacity = calculate(days: [input]).days[0].capacity
        XCTAssertEqual(capacity.sleepMinutes, 480)
        XCTAssertEqual(capacity.availableWorkMinutes, 960)
    }

    func testSettingsChangeDuringFirstLoadInvalidatesOldForecastGeneration() {
        let reloaded = expectation(description: "Settings invalidate initial forecast")
        var reads = 0
        var oldResponse: ((ProjectsPage?) -> Void)?
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { _, _, response in
                reads += 1
                if reads == 1 { oldResponse = response } else { reloaded.fulfill(); response(nil) }
            }, readTasks: { _, _, _ in XCTFail() }, diagnostic: { _ in })
        store.refresh()
        NotificationCenter.default.post(name: LocalForecastPreferences.didChange, object: nil)
        wait(for: [reloaded], timeout: 3)
        XCTAssertEqual(reads, 2)
        oldResponse?(nil)
    }

    func testCatalogueProgressCountsActualNativeRowsAndTasksThenClearsOnFailure() throws {
        let projectPages = try (1...2).map { page in
            try JSONDecoder().decode(ProjectsPage.self, from: Data("{\"data\":[{\"id\":\"p\(page)\",\"name\":\"Project\"}],\"meta\":{\"page\":\(page),\"itemCount\":2,\"hasNextPage\":\(page == 1)}}".utf8))
        }
        let firstTasks = try JSONDecoder().decode(AllApi.ForecastTasksPage.self, from: Data(#"{"data":[{"id":"t1","title":"Task","status":"NOT_STARTED"}],"meta":{"page":1,"itemCount":2,"hasNextPage":true,"excludesCompleted":true}}"#.utf8))
        var snapshots: [LocalForecastLoadProgress?] = []
        var store: LocalForecastStore!
        defer { store = nil }
        store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { page, _, complete in
                snapshots.append(store.loadProgress)
                complete(projectPages[page - 1])
            }, readTasks: { page, _, complete in
                snapshots.append(store.loadProgress)
                complete(page == 1 ? firstTasks : nil)
            }, diagnostic: { _ in })
        let finished = expectation(description: "Partial task catalogue is still rejected")
        store.refresh { success in XCTAssertFalse(success); finished.fulfill() }
        wait(for: [finished], timeout: 2)
        XCTAssertEqual(snapshots, [.init(stage: .projects), .init(stage: .projects, completed: 1, total: 2),
                                   .init(stage: .tasks), .init(stage: .tasks, completed: 1, total: 2)])
        XCTAssertNil(store.loadProgress)
        XCTAssertNil(store.result)
        XCTAssertNotNil(store.error)
    }

    func testAbandonedRefreshCannotPublishOldProgress() throws {
        var account = "first"
        var responses: [(ProjectsPage?) -> Void] = []
        let store = LocalForecastStore(currentAccount: { account }, calendarPermission: { true },
            readProjects: { _, _, complete in responses.append(complete) },
            readTasks: { _, _, _ in XCTFail("Old account cannot start task loading") }, diagnostic: { _ in })
        store.refresh()
        account = "second"
        store.refresh()
        let oldPage = try JSONDecoder().decode(ProjectsPage.self, from: Data(#"{"data":[{"id":"p1","name":"Old"}],"meta":{"page":1,"itemCount":2,"hasNextPage":true}}"#.utf8))
        responses[0](oldPage)
        let drained = expectation(description: "Old callback drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
        XCTAssertEqual(store.loadProgress, .init(stage: .projects))
        XCTAssertTrue(store.isLoading)
        account = ""
        store.refresh()
        XCTAssertNil(store.loadProgress)
        XCTAssertFalse(store.isLoading)
    }

    func testStageProgressRequiresAKnownPositiveDenominatorAndClampsFractions() {
        XCTAssertNil(LocalForecastLoadProgress(stage: .calendar).fraction)
        XCTAssertNil(LocalForecastLoadProgress(stage: .tasks, completed: 0, total: 0).fraction)
        XCTAssertEqual(LocalForecastLoadProgress(stage: .days, completed: 45, total: 90).fraction, 0.5)
        XCTAssertEqual(LocalForecastLoadProgress(stage: .tasks, completed: 120, total: 100).fraction, 1)
    }

    func testCatalogueFailureDoesNotInventMissingCalendarPermission() {
        let finished = expectation(description: "Failed catalogue")
        var readAccount: String?
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { _, account, complete in readAccount = account; complete(nil) },
            readTasks: { _, _, _ in XCTFail("Tasks cannot be loaded from an incomplete project catalogue") },
            diagnostic: { _ in })
        store.refresh { success in XCTAssertFalse(success); finished.fulfill() }
        wait(for: [finished], timeout: 2)
        XCTAssertTrue(store.calendarAvailable)
        XCTAssertEqual(readAccount, "test-account")
        XCTAssertNotNil(store.error)
        XCTAssertNil(store.result)
        XCTAssertFalse(store.isLoading)
    }

    func testCalendarPermissionRefreshIsIndependentOfRepeatedCatalogueFailures() {
        var permission = false
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { permission },
            readProjects: { _, _, complete in complete(nil) }, readTasks: { _, _, _ in XCTFail() }, diagnostic: { _ in })
        XCTAssertFalse(store.calendarAvailable)
        permission = true
        let finished = expectation(description: "Permission refreshed")
        store.refresh { _ in finished.fulfill() }
        wait(for: [finished], timeout: 2)
        XCTAssertTrue(store.calendarAvailable)
    }

    func testIncompleteProjectCountIsDiagnosedWithoutProjectNamesOrIDs() throws {
        let json = #"{"data":[{"id":"private-project-id","name":"Private project name"}],"meta":{"page":1,"take":50,"itemCount":2,"hasNextPage":false}}"#
        let page = try JSONDecoder().decode(ProjectsPage.self, from: Data(json.utf8))
        var diagnostics: [String] = []
        let finished = expectation(description: "Missing project diagnosed")
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { _, _, complete in complete(page) }, readTasks: { _, _, _ in XCTFail() },
            diagnostic: { diagnostics.append($0) })
        store.refresh { success in XCTAssertFalse(success); finished.fulfill() }
        wait(for: [finished], timeout: 2)
        XCTAssertTrue(diagnostics.contains { $0.contains("nativeUnique=1") && $0.contains("expected=2") })
        XCTAssertFalse(diagnostics.joined().contains("private-project-id"))
        XCTAssertFalse(diagnostics.joined().contains("Private project name"))
        XCTAssertTrue(store.calendarAvailable)
        XCTAssertNil(store.result)
    }

    func testRepeatedProjectWithinAPageDoesNotInflateTheCompleteCatalogueCount() throws {
        let json = #"{"data":[{"id":"same","name":"Project"},{"id":"same","name":"Project"}],"meta":{"page":1,"take":50,"itemCount":1,"hasNextPage":false}}"#
        let page = try JSONDecoder().decode(ProjectsPage.self, from: Data(json.utf8))
        var taskReads = 0
        var diagnostics: [String] = []
        let finished = expectation(description: "Complete unique project catalogue accepted")
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { _, _, complete in complete(page) },
            readTasks: { _, _, complete in taskReads += 1; complete(nil) },
            diagnostic: { diagnostics.append($0) })
        store.refresh { _ in finished.fulfill() }
        wait(for: [finished], timeout: 2)
        XCTAssertEqual(taskReads, 1)
        XCTAssertTrue(diagnostics.contains { $0.contains("nativeUnique=1") && $0.contains("duplicates=1") })
    }

    func testMigratedSyncedExtrasDoNotHideNativeRowsOnLaterPages() throws {
        // Deployed shape: 128 native rows over three pages; page one's three extras
        // reuse IDs from page two. One forecast project must retain both identities.
        let native = (0..<128).map { Project(id: "project-\($0)", name: "Native \($0)") }
        let extras = (50..<53).map { Project(id: "project-\($0)", name: "Imported \($0)", synced_project_id: "external-\($0)") }
        let pages = [Array(native[0..<50]) + extras, Array(native[50..<100]), Array(native[100..<128])]
        var requested: [Int] = []
        var taskReads = 0
        var diagnostics: [String] = []
        let finished = expectation(description: "Complete migrated catalogue reaches task loading")
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { page, _, complete in
                requested.append(page)
                let meta = "{\"page\":\(page),\"take\":50,\"itemCount\":128,\"hasNextPage\":\(page < 3)}"
                let rows = String(data: try! JSONEncoder().encode(pages[page - 1]), encoding: .utf8)!
                complete(try! JSONDecoder().decode(ProjectsPage.self, from: Data("{\"data\":\(rows),\"meta\":\(meta)}".utf8)))
            }, readTasks: { _, _, complete in taskReads += 1; complete(nil) },
            diagnostic: { diagnostics.append($0) })
        store.refresh { _ in finished.fulfill() }
        wait(for: [finished], timeout: 2)
        XCTAssertEqual(requested, [1, 2, 3])
        XCTAssertEqual(taskReads, 1)
        XCTAssertTrue(diagnostics.contains { $0.contains("uniqueRows=128") && $0.contains("nativeUnique=128") })
    }

    func testProjectCataloguePreservesNativeMetadataAndSyncedTaskAssociationInEitherOrder() {
        let native = Project(id: "migrated", name: "Native name", due_date: "2026-10-01", outcome: 4)
        let imported = Project(id: "migrated", name: "Imported name", synced_project_id: "external")
        for rows in [[native, imported], [imported, native]] {
            var catalogue = LocalForecastProjectCatalogue()
            XCTAssertTrue(catalogue.append(rows))
            XCTAssertEqual(catalogue.nativeCount, 1)
            XCTAssertEqual(catalogue.identityCount, 2)
            XCTAssertEqual(catalogue.projects.count, 1)
            let merged = catalogue.projects[0]
            XCTAssertEqual(merged.name, native.name)
            XCTAssertEqual(merged.due_date, native.due_date)
            XCTAssertEqual(merged.outcome, native.outcome)
            XCTAssertEqual(merged.synced_project_id, "external")
            XCTAssertTrue(merged.isSynced) // Retain the existing imported-project edit protection.
        }
    }

    func testSyncedExtraCannotStandInForAMissingNativeProject() throws {
        let json = #"{"data":[{"id":"one","name":"Native"},{"id":"two","name":"Imported","synced_project_id":"external"}],"meta":{"page":1,"take":50,"itemCount":2,"hasNextPage":false}}"#
        let page = try JSONDecoder().decode(ProjectsPage.self, from: Data(json.utf8))
        let finished = expectation(description: "Missing native project rejected")
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { _, _, complete in complete(page) },
            readTasks: { _, _, _ in XCTFail("Imported extras must not fill a native catalogue gap") }, diagnostic: { _ in })
        store.refresh { success in XCTAssertFalse(success); finished.fulfill() }
        wait(for: [finished], timeout: 2)
        XCTAssertNil(store.result)
    }

    func testProjectCatalogueRejectsConflictingImportedAssociations() {
        var catalogue = LocalForecastProjectCatalogue()
        XCTAssertTrue(catalogue.append([Project(id: "same", name: "One", synced_project_id: "external-one")]))
        XCTAssertFalse(catalogue.append([Project(id: "same", name: "Two", synced_project_id: "external-two")]))
    }

    func testForecastUsesDayPlanSeriesAndLegacyEventDismissals() {
        let hidden = CalendarEventDismissalSnapshot(ids: ["series:weekly", "legacy-event"], calendar: calendar)
        XCTAssertTrue(hidden.isDismissed(eventID: "next-occurrence", externalID: "weekly", on: date(11)))
        XCTAssertTrue(hidden.isDismissed(eventID: "another-occurrence", externalID: "weekly", on: date(12)))
        XCTAssertTrue(hidden.isDismissed(eventID: "legacy-event", externalID: nil, on: date(11)))
        XCTAssertFalse(hidden.isDismissed(eventID: "attending", externalID: "different-series", on: date(11)))
        XCTAssertFalse(hidden.isDismissed(eventID: "attending", externalID: "", on: date(11)))
    }

    func testDaySpecificHideExcludesOnlyThatLocalDay() {
        let empty = CalendarEventDismissalSnapshot(ids: [], calendar: calendar)
        let hidden = CalendarEventDismissalSnapshot(ids: [empty.perDayKey("event", day: date(11))], calendar: calendar)
        XCTAssertEqual(empty.perDayKey("event", day: date(11)), "event|day:2026-09-11")
        XCTAssertTrue(hidden.isDismissed(eventID: "event", externalID: "weekly", on: date(11, hour: 16)))
        XCTAssertFalse(hidden.isDismissed(eventID: "event", externalID: "weekly", on: date(12, hour: 16)))
        XCTAssertFalse(hidden.isDismissed(eventID: "other", externalID: "weekly", on: date(11)))
    }

    func testDaySpecificHideClipsCrossMidnightEventWithoutHidingTheNextDay() {
        let snapshot = CalendarEventDismissalSnapshot(ids: ["overnight|day:2026-09-11"], calendar: calendar)
        let visible = snapshot.visiblePortions(eventID: "overnight", externalID: nil,
            start: date(11, hour: 23), end: date(12, hour: 2), from: date(11), to: date(13))
        XCTAssertEqual(visible, [DateInterval(start: date(12), end: date(12, hour: 2))])
        let input = LocalTimeForecast.DayInput(date: date(12), meetings: visible.map { .init(start: $0.start, end: $0.end) }, habits: [])
        XCTAssertEqual(calculate(days: [input]).days[0].capacity.meetingMinutes, 0, "The remaining event is wholly inside sleep")
    }

    func testHiddenBusyAllDayEventDoesNotConsumeForecastCapacity() {
        let snapshot = CalendarEventDismissalSnapshot(ids: ["series:away"], calendar: calendar)
        let visible = snapshot.visiblePortions(eventID: "away-on-friday", externalID: "away",
            start: date(11), end: date(12), from: date(11), to: date(12))
        XCTAssertTrue(visible.isEmpty)
        let input = LocalTimeForecast.DayInput(date: date(11), meetings: [], habits: [])
        XCTAssertEqual(calculate(days: [input]).days[0].capacity.availableWorkMinutes, 960)
    }

    func testVisibleCalendarPortionsStayInsideRequestedHorizon() {
        let snapshot = CalendarEventDismissalSnapshot(ids: [], calendar: calendar)
        let visible = snapshot.visiblePortions(eventID: "overnight", externalID: nil,
            start: date(10, hour: 22), end: date(12, hour: 2), from: date(11), to: date(12))
        XCTAssertEqual(visible, [DateInterval(start: date(11), end: date(12))])
        XCTAssertTrue(snapshot.visiblePortions(eventID: "invalid", externalID: nil,
            start: date(12), end: date(11), from: date(11), to: date(12)).isEmpty)
    }

    func testConcurrentMeetingRowsOnlyReserveTimeOnceThroughTheRealDayPlanAdapter() {
        // Reproduce the report: five distinct standups at 16:00, each ending at16:15.
        // The drilldown can show all names, but their shared quarter-hour is reserved only once.
        let meetings = (0..<5).map { ScheduleMeetingInput(id: "standup-\($0)", title: "Meeting \($0)",
            start: date(11, hour: 16), end: date(11, hour: 16, minute: 15)) }
        let blocks = ScheduleBuilder.build(segments: [], meetings: meetings, now: date(11), dayEnd: date(12),
            leaveBufferSeconds: 0, outOfOrderAllowed: false, meetingsFrom: date(11))
        XCTAssertEqual(blocks.filter { $0.kind == .meeting }.count, 5)
        let result = calculate(days: [.fromDayPlan(date: date(11), blocks: blocks)])
        XCTAssertEqual(result.days[0].capacity.meetingMinutes, 15)
        XCTAssertEqual(result.days[0].capacity.availableWorkMinutes, 945)
    }

    func testDismissalChangeDuringInitialForecastLoadWaitsForScheduledRefresh() {
        let clock = ForecastRefreshClock()
        var responses: [(ProjectsPage?) -> Void] = []
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { true },
            readProjects: { _, _, response in responses.append(response) },
            readTasks: { _, _, _ in XCTFail("No complete project catalogue") }, diagnostic: { _ in },
            now: { clock.now }, scheduleRefresh: clock.schedule)
        store.refresh()
        NotificationCenter.default.post(name: CalendarManager.dismissedEventsDidChange, object: nil)
        XCTAssertEqual(responses.count, 1, "Hide must not abandon an in-flight catalogue")
        XCTAssertTrue(store.isSnapshotDirty)
        responses[0](nil)
        drainForecastCallbacks()
        XCTAssertEqual(clock.pendingCount, 1)
        clock.advance(899)
        XCTAssertEqual(responses.count, 1)
        clock.advance(1)
        XCTAssertEqual(responses.count, 2)
    }

    func testAutomaticFailuresAndRepeatedNotificationsShareOneFifteenMinuteDeadline() {
        let clock = ForecastRefreshClock()
        var reads = 0
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { false },
            readProjects: { _, _, response in reads += 1; response(nil) },
            readTasks: { _, _, _ in XCTFail() }, diagnostic: { _ in },
            now: { clock.now }, scheduleRefresh: clock.schedule)
        store.refreshIfNeeded()
        drainForecastCallbacks()
        let failure = store.error
        for _ in 0..<20 {
            store.refreshIfNeeded()
            store.markDirty() // project edits
            NotificationCenter.default.post(name: DayPlanTaskStore.forecastSnapshotDidChange, object: nil)
            NotificationCenter.default.post(name: .EKEventStoreChanged, object: nil)
        }
        XCTAssertEqual(reads, 1)
        XCTAssertEqual(store.error, failure)
        XCTAssertEqual(clock.pendingCount, 1, "Repeated edits must not postpone or duplicate the deadline")
        clock.advance(899)
        XCTAssertEqual(reads, 1)
        clock.advance(1)
        drainForecastCallbacks()
        XCTAssertEqual(reads, 2)
        XCTAssertEqual(clock.pendingCount, 1, "A failed automatic attempt also waits fifteen minutes")
        clock.advance(899)
        XCTAssertEqual(reads, 2)
    }

    func testAutomaticDeadlineNeverRestartsAnInflightReadAndCoalescesLateChanges() {
        let clock = ForecastRefreshClock()
        var responses: [(ProjectsPage?) -> Void] = []
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { false },
            readProjects: { _, _, response in responses.append(response) },
            readTasks: { _, _, _ in XCTFail() }, diagnostic: { _ in },
            now: { clock.now }, scheduleRefresh: clock.schedule)
        store.refreshIfNeeded()
        clock.advance(1000)
        for _ in 0..<10 { store.markDirty(); store.refreshIfNeeded() }
        XCTAssertEqual(responses.count, 1)
        XCTAssertTrue(store.isLoading)
        responses[0](nil)
        drainForecastCallbacks()
        XCTAssertEqual(clock.pendingCount, 1)
        clock.advance(0)
        XCTAssertEqual(responses.count, 2, "One delayed calculation replaces all in-flight invalidations")
        XCTAssertFalse(store.isSnapshotDirty)
    }

    func testManualRefreshAndPreflightCompletionBypassCacheAndCancelOlderTimer() {
        let clock = ForecastRefreshClock()
        var reads = 0
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { false },
            readProjects: { _, _, response in reads += 1; response(nil) },
            readTasks: { _, _, _ in XCTFail() }, diagnostic: { _ in },
            now: { clock.now }, scheduleRefresh: clock.schedule)
        store.refreshIfNeeded()
        drainForecastCallbacks()
        let staleTimer = clock.actions[0].action
        clock.advance(20)
        let manual = expectation(description: "Manual/preflight API returns the actual new read result")
        store.refresh { success in XCTAssertFalse(success); manual.fulfill() }
        wait(for: [manual], timeout: 2)
        XCTAssertEqual(reads, 2)
        staleTimer() // A cancelled DispatchWorkItem may already have been enqueued.
        XCTAssertEqual(reads, 2)
        XCTAssertEqual(clock.pendingCount, 1)
        clock.advance(899)
        XCTAssertEqual(reads, 2)
        clock.advance(1)
        XCTAssertEqual(reads, 3)
    }

    func testAccountSwitchBypassesCachedDeadlineAndRejectsOlderReadBeforeProgress() throws {
        let clock = ForecastRefreshClock()
        var account = "first"
        var requestedAccounts: [String] = []
        var responses: [(ProjectsPage?) -> Void] = []
        let store = LocalForecastStore(currentAccount: { account }, calendarPermission: { false },
            readProjects: { _, id, response in requestedAccounts.append(id); responses.append(response) },
            readTasks: { _, _, _ in XCTFail("An old account cannot start its tasks") }, diagnostic: { _ in },
            now: { clock.now }, scheduleRefresh: clock.schedule)
        store.refreshIfNeeded()
        account = "second"
        store.refreshIfNeeded()
        XCTAssertEqual(requestedAccounts, ["first", "second"])
        let oldPage = try JSONDecoder().decode(ProjectsPage.self, from: Data(#"{"data":[],"meta":{"page":1,"itemCount":0,"hasNextPage":false}}"#.utf8))
        responses[0](oldPage)
        drainForecastCallbacks()
        XCTAssertEqual(store.loadProgress, .init(stage: .projects))
        XCTAssertTrue(store.projects.isEmpty)
        responses[1](nil)
        drainForecastCallbacks()
        XCTAssertEqual(clock.pendingCount, 1)
        account = "third"
        store.refreshIfNeeded()
        XCTAssertEqual(requestedAccounts, ["first", "second", "third"], "An old account's failure cannot rate-limit a new one")
        account = ""
        store.refreshIfNeeded()
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.result)
        XCTAssertTrue(store.projects.isEmpty)
        XCTAssertNil(store.workPlan)
        XCTAssertEqual(clock.pendingCount, 0)
    }

    func testExplicitSettingsAndHorizonRefreshReplaceInflightCachedAttempt() {
        let clock = ForecastRefreshClock()
        var reads = 0
        let store = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { false },
            readProjects: { _, _, _ in reads += 1 }, readTasks: { _, _, _ in XCTFail() }, diagnostic: { _ in },
            now: { clock.now }, scheduleRefresh: clock.schedule)
        store.refreshIfNeeded()
        NotificationCenter.default.post(name: LocalForecastPreferences.didChange, object: nil)
        XCTAssertEqual(reads, 2)
        store.horizonDays = 30
        store.refresh() // The explicit horizon picker uses the same force API.
        XCTAssertEqual(reads, 3)
        store.refreshIfNeeded()
        XCTAssertEqual(reads, 3)
    }

    func testUnusedForecastIgnoresAutomaticNotificationsAndDeinitCancelsTimer() {
        let clock = ForecastRefreshClock()
        var reads = 0
        var store: LocalForecastStore? = LocalForecastStore(currentAccount: { "test-account" }, calendarPermission: { false },
            readProjects: { _, _, response in reads += 1; response(nil) }, readTasks: { _, _, _ in XCTFail() }, diagnostic: { _ in },
            now: { clock.now }, scheduleRefresh: clock.schedule)
        store?.markDirty()
        XCTAssertEqual(reads, 0)
        store?.refreshIfNeeded()
        drainForecastCallbacks()
        XCTAssertEqual(clock.pendingCount, 1)
        store = nil
        XCTAssertEqual(clock.pendingCount, 0)
        clock.advance(900)
        XCTAssertEqual(reads, 1)
    }

    private func drainForecastCallbacks() {
        let drained = expectation(description: "Forecast response callback")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
    }

    private final class ForecastRefreshClock {
        final class Action {
            let due: Date
            let action: () -> Void
            var cancelled = false
            init(due: Date, action: @escaping () -> Void) { self.due = due; self.action = action }
        }
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        var actions: [Action] = []
        var pendingCount: Int { actions.filter { !$0.cancelled }.count }
        func schedule(_ delay: TimeInterval, _ action: @escaping () -> Void) -> () -> Void {
            let scheduled = Action(due: now.addingTimeInterval(delay), action: action)
            actions.append(scheduled)
            return { scheduled.cancelled = true }
        }
        func advance(_ seconds: TimeInterval) {
            now = now.addingTimeInterval(seconds)
            let due = actions.filter { !$0.cancelled && $0.due <= now }
            for action in due { action.cancelled = true; action.action() }
        }
    }

    func testOptionalEveningHabitsDoNotConsumeForecastTimeOrDisplaceRequiredHabits() {
        let optional = forecastHabit(id: "optional", required: false, minutes: 90)
        let required = forecastHabit(id: "required", required: true, minutes: 30)
        let inputs = ScheduleTab.habitInputs(from: [optional, required], now: date(hour: 20),
                                            dropCompleted: false, includeOptional: false)
        XCTAssertEqual(inputs.map(\.id), ["required"])
        XCTAssertEqual(inputs.map(\.index), [1], "Filtering preserves the actual habit index")
        let segment = ScheduleRoutineSegment(name: "Evening", habits: inputs, windowStart: date(hour: 20),
                                              windowEnd: date(hour: 21), actionable: false)
        let blocks = ScheduleBuilder.build(segments: [segment], meetings: [], now: date(),
            dayEnd: date(8), leaveBufferSeconds: 0, outOfOrderAllowed: false)
        let placed = blocks.filter { $0.kind == .habit }
        XCTAssertEqual(placed.count, 1)
        XCTAssertEqual(placed.first?.start, date(hour: 20))
        XCTAssertEqual(placed.first?.end, date(hour: 20, minute: 30))
        XCTAssertFalse(placed.contains { $0.didOverflow })
        let result = calculate(days: [.fromDayPlan(date: date(), blocks: blocks)])
        XCTAssertEqual(result.days[0].capacity.habitMinutes, 30)
        XCTAssertEqual(result.days[0].capacity.availableWorkMinutes, 930)
    }

    func testOrdinaryDayPlanInputsKeepOptionalMorningCustomAndEveningHabits() {
        let habits = [forecastHabit(id: "optional", required: false, minutes: 60),
                      forecastHabit(id: "required", required: true, minutes: 30)]
        let inputs = ScheduleTab.habitInputs(from: habits, now: date(hour: 8), dropCompleted: false)
        XCTAssertEqual(inputs.map(\.id), ["optional", "required"], "Only the explicit evening forecast path opts out")
        XCTAssertEqual(inputs.map(\.durationSeconds), [3600, 1800])
        XCTAssertTrue(ScheduleTab.habitInputs(from: [habits[0]], now: date(),
            dropCompleted: false, includeOptional: false).isEmpty)
    }

    private func forecastHabit(id: String, required: Bool, minutes: Int) -> habit {
        habit(id: id, name: id, durationSeconds: minutes * 60, urlsArray: [], logQuantity: false,
              logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "",
              activity_sequence_id: "forecast-fixture", run_micro_breaks: false, take_notes: NO_NOTE,
              isPriorityHigh: required, days_of_week: [], text_instructions: "", imgUrls: [],
              completion_requirements: "", useTimer: true, checkList: [], tutorial: "")
    }

    // MARK: Day Plan header — planned total + buffer (report 2026-09-15_22-33-09)

    /// A day with slack: the work planned on it, and a POSITIVE buffer, with nothing to warn about.
    func testDayWithSlackShowsPlannedTotalAndAPositiveBufferAndNoBanner() {
        let load = Forecast.dayLoad(day: date(7), capacityMinutes: 109, plannedMinutes: 105)
        XCTAssertEqual(load.committedMinutes, 105)
        XCTAssertEqual(load.bufferMinutes, 4)
        XCTAssertFalse(load.isOvercommitted, "a positive buffer must not raise the banner")
        XCTAssertEqual(ForecastText.format(.plannedTotal, ["<DURATION>": ForecastText.duration(load.committedMinutes)]),
                       "1h 45m of tasks planned")
        XCTAssertEqual(ForecastText.format(.bufferTotal, ["<BUFFER>": ForecastText.signedDuration(load.bufferMinutes)]),
                       "4m buffer")
    }

    /// A day over capacity: the buffer goes negative in the row, and the banner says so in words.
    /// The PO asked for both — the banner is the alarm, the row is the detail.
    func testDayOverCapacityShowsANegativeBufferAndTheBanner() {
        let load = Forecast.dayLoad(day: date(7), capacityMinutes: 95, plannedMinutes: 105)
        XCTAssertTrue(load.isOvercommitted)
        XCTAssertEqual(load.bufferMinutes, -10)
        XCTAssertEqual(ForecastText.format(.bufferTotal, ["<BUFFER>": ForecastText.signedDuration(load.bufferMinutes)]),
                       "-10m buffer")
        XCTAssertEqual(ForecastText.format(.notEnoughTimeForTasks,
                                           ["<DURATION>": ForecastText.duration(load.overcommittedMinutes)]),
                       "Not enough time for all tasks (over by 10m)")
    }

    /// The banner's figure and the row's are two halves of one `bufferMinutes`, never two sums.
    func testBannerAndBufferAreTheSameFigureFromTheSameCall() {
        for (capacity, planned) in [(95.0, 105.0), (0.0, 36.0), (120.0, 121.0)] {
            let load = Forecast.dayLoad(day: date(7), capacityMinutes: capacity, plannedMinutes: planned)
            XCTAssertEqual(load.overcommittedMinutes, -load.bufferMinutes, accuracy: 0.000_001)
            XCTAssertEqual(load.freeMinutes, 0)
            XCTAssertEqual(ForecastText.signedDuration(load.bufferMinutes),
                           "-" + ForecastText.duration(load.overcommittedMinutes))
        }
    }

    /// Nothing planned: no planned total to show, the whole day is buffer, and no banner. An unknown
    /// schedule (nil free minutes) is the caller's business — here it degrades to a full buffer.
    func testDayWithNothingPlannedDegradesToAFullBufferAndNoBanner() {
        let load = Forecast.dayLoad(day: date(7), capacityMinutes: 120, plannedMinutes: 0)
        XCTAssertEqual(load.committedMinutes, 0, "nothing to render as a planned total")
        XCTAssertEqual(load.bufferMinutes, 120)
        XCTAssertFalse(load.isOvercommitted)
        let empty = Forecast.dayLoad(day: date(7), capacityMinutes: 0, plannedMinutes: 0)
        XCTAssertEqual(empty.bufferMinutes, 0)
        XCTAssertFalse(empty.isOvercommitted, "an empty day with no capacity is not over capacity")
    }

    /// Absorbed work does not spend the buffer twice. The header separately shows the full planned
    /// duration; the capacity equation uses only the net committed load.
    func testCommittedLoadAndBufferAlwaysAddUpToTheDaysCapacity() {
        let load = Forecast.dayLoad(day: date(7), capacityMinutes: 109, plannedMinutes: 125, absorbedMinutes: 20)
        XCTAssertEqual(load.committedMinutes, 105, "the 20m absorbed into a habit was already paid for")
        XCTAssertEqual(load.committedMinutes + load.bufferMinutes, load.capacityMinutes)
    }

    /// The new header copy carries the same placeholders in English and Spanish.
    func testHeaderCopyKeepsIdenticalPlaceholdersInEnglishAndSpanish() throws {
        let english = try shippedForecastStrings(BundledConfigLanguage.english)
        let spanish = try shippedForecastStrings("es")
        for (key, expected) in [("plannedTotal", ["<DURATION>"]), ("bufferTotal", ["<BUFFER>"]),
                                ("notEnoughTimeForTasks", ["<DURATION>"])] {
            let source = try XCTUnwrap(english[key], key)
            let translation = try XCTUnwrap(spanish[key], key)
            XCTAssertEqual(placeholders(in: source), expected, key)
            XCTAssertEqual(placeholders(in: translation), expected, key)
        }
    }

    // MARK: One number for a day's load (report 2026-09-15_20-08-56, "-5 minutes" vs "-36 minutes")

    /// The reported bug, reproduced: 36 minutes of task work pinned to a day with no capacity left.
    /// The Day Plan header and the task editor's advice now read the SAME `DayLoad`, so they cannot
    /// print different numbers for the same day again. The editor used to read `remainingWorkMinutes`,
    /// which clamps at zero and so could only ever say "you are 5 minutes short of a day with nothing
    /// left" — never "this day is already 36 minutes over".
    func testDayPlanHeaderAndEditorAdviceReadTheSameOvercommitment() throws {
        // A day with no room at all, and 36 minutes explicitly placed on it.
        let pinned = Forecast.TaskInput(id: "pinned", estimatedMinutes: 36, notBefore: date(7))
        let forecast = calculate(days: [day(7, workMinutes: 0), day(8, workMinutes: 240)], tasks: [pinned])
        XCTAssertEqual(forecast.days[0].capacity.availableWorkMinutes, 0)
        XCTAssertEqual(forecast.days[0].remainingWorkMinutes, 0, "the allocator clamps, so nothing here says 'over'")

        // What the editor reads out of the horizon forecast.
        let editor = try XCTUnwrap(Forecast.dayLoad(on: date(7), forecast: forecast, calendar: calendar))
        // What the Day Plan header computes from its own tasks-for-the-day and schedule-free figure.
        let dayPlan = Forecast.dayLoad(day: date(7), capacityMinutes: 0, plannedMinutes: 36, absorbedMinutes: 0)

        XCTAssertEqual(editor.overcommittedMinutes, 36)
        XCTAssertEqual(editor.overcommittedMinutes, dayPlan.overcommittedMinutes)
        XCTAssertEqual(editor.committedMinutes, dayPlan.committedMinutes)
        XCTAssertEqual(editor.capacityMinutes, dayPlan.capacityMinutes)
        XCTAssertTrue(editor.isOvercommitted)
    }

    /// And the sentence says so in the PO's own words rather than a negative quantity.
    func testOvercommittedDayIsNamedAsOverCapacityNotAsNegativeAvailability() throws {
        let pinned = Forecast.TaskInput(id: "pinned", estimatedMinutes: 36, notBefore: date(7))
        let inputs = [day(7, workMinutes: 0), day(8, workMinutes: 240)]
        let forecast = calculate(days: inputs, tasks: [pinned])
        let candidate = Forecast.TaskInput(id: "draft", estimatedMinutes: 5)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [pinned], calendar: calendar)
        guard case .shortfall(let warning) = advice(day: date(7), candidate: candidate, slot: slot, forecast: forecast)
        else { return XCTFail("a day 36m over capacity must warn") }
        XCTAssertEqual(warning.amountMinutes, 36, "the day's own state, not this task's 5-minute shortfall")
        let message = ForecastText.dayAdvice(warning)
        XCTAssertEqual(message, "\(ToDoDates.weekdayDayMonth(date(7))) is already \(ForecastText.duration(36))"
                       + " over capacity. Suggested date: \(ToDoDates.weekdayDayMonth(try XCTUnwrap(slot.proposedDay)))")
        XCTAssertFalse(message.contains("-"), "a negative quantity is what the reader could not interpret")
        XCTAssertFalse(message.contains("<"), message)
    }

    /// A day that is not over capacity but cannot hold this task gets the other sentence — including
    /// the smallest case, one minute left, which must still read as a sentence.
    func testDayWithTooLittleLeftSaysHowMuchIsLeftIncludingASingleMinute() throws {
        let inputs = [day(7, workMinutes: 1), day(8, workMinutes: 240)]
        let forecast = calculate(days: inputs)
        let candidate = Forecast.TaskInput(id: "draft", estimatedMinutes: 15)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        guard case .shortfall(let warning) = advice(day: date(7), candidate: candidate, slot: slot, forecast: forecast)
        else { return XCTFail("15 minutes of work does not fit in 1 minute") }
        XCTAssertFalse(warning.load.isOvercommitted)
        XCTAssertEqual(warning.amountMinutes, 1)
        let message = ForecastText.dayAdvice(warning)
        XCTAssertTrue(message.contains("has only \(ForecastText.duration(1)) left"), message)
        XCTAssertFalse(message.contains("-"), message)
    }

    /// Today and tomorrow are written the same way as any other day — `weekdayDayMonth` never
    /// substitutes a relative word, so the sentence cannot come out as "Today is already …".
    func testTodayAndTomorrowAreWrittenAsDatesNotRelativeWords() {
        let today = Date(), tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        for moment in [today, tomorrow] {
            let rendered = ToDoDates.weekdayDayMonth(moment)
            XCTAssertFalse(rendered.lowercased().contains("today"), rendered)
            XCTAssertFalse(rendered.lowercased().contains("tomorrow"), rendered)
            XCTAssertEqual(rendered.split(separator: " ").count, 3, rendered)
        }
    }

    /// Habit-absorbed time is work the day was already paying for, so it is not charged twice — the
    /// one place that rule lives now, rather than once in the Day Plan header and once here.
    func testAbsorbedHabitTimeIsNotChargedTwiceInEitherSurface() {
        let load = Forecast.dayLoad(day: date(7), capacityMinutes: 60, plannedMinutes: 40, absorbedMinutes: 25)
        XCTAssertEqual(load.committedMinutes, 15)
        XCTAssertEqual(load.freeMinutes, 45)
        XCTAssertFalse(load.isOvercommitted)
        // Absorption can exceed the planned work; the day is never credited with negative work.
        XCTAssertEqual(Forecast.dayLoad(day: date(7), capacityMinutes: 60, plannedMinutes: 10,
                                        absorbedMinutes: 25).committedMinutes, 0)
    }

    // MARK: The due-date default (report 2026-09-15_20-08-56)

    /// The bug, reproduced from the two calls that produced it. `nextFreeDay` scans for a day with
    /// leftover slack AFTER everything else is placed; `nextSlot` re-runs the allocation WITH the
    /// draft at its own priority, so it can land earlier by pushing lower-priority work back. That is
    /// how the field came to say 24 Nov while the row beneath said 28 Oct. The default now uses the
    /// same call as the proposal, so the two cannot name different days.
    func testDueDateDefaultUsesTheProposalNotTheFirstDayWithLeftoverSlack() {
        // Every early day is filled by a lower-priority task; only a late day has slack left over.
        let inputs = (7...11).map { day($0, workMinutes: 60) }
        let occupied = (0..<4).map { Forecast.TaskInput(id: "filler\($0)", estimatedMinutes: 60, outcome: 2) }
        let forecast = calculate(days: inputs, tasks: occupied)
        let leftoverSlack = try? XCTUnwrap(Forecast.firstDayWithRoom(forMinutes: 0, in: forecast))
        XCTAssertEqual(leftoverSlack, date(11), "every earlier day is full of other work")

        let candidate = Forecast.TaskInput(id: "draft", estimatedMinutes: 60, outcome: 10)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: occupied, calendar: calendar)
        XCTAssertEqual(slot.proposedDay, date(7), "at its own priority the task goes first, not last")
        XCTAssertNotEqual(slot.proposedDay, leftoverSlack, "this divergence is the reported bug")

        // The default follows the proposal.
        let applied = ToDoDueDateDefault.dayToApply(proposal: slot.proposedDay, current: leftoverSlack,
                                                    lastDefaulted: leftoverSlack, hasDefaulted: false,
                                                    isNew: true, calendar: calendar)
        XCTAssertEqual(applied, date(7))
    }

    /// The day defaulted to holds the whole 15 minutes — the two earlier days are full, so nothing is
    /// split — and the app never then argues with the day it just proposed.
    func testDefaultedDayHasRoomForTheEstimateAndIsNeverWarnedAbout() throws {
        let task = try remoteTask(["id": "draft", "duration": 900])
        let candidate = Forecast.TaskInput.draft(task, projectID: nil, durationMinutes: 15)
        let inputs = [day(7, workMinutes: 0), day(8, workMinutes: 0), day(9, workMinutes: 60)]
        let forecast = calculate(days: inputs)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        let proposal = try XCTUnwrap(slot.proposedDay)
        XCTAssertEqual(proposal, date(9), "the only day with any room at all")
        let room = try XCTUnwrap(forecast.days.first { calendar.isDate($0.date, inSameDayAs: proposal) })
        XCTAssertGreaterThanOrEqual(Forecast.availableMinutes(on: room, for: candidate.id), 15,
                                    "the day defaulted to must hold the whole estimate")
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: proposal, candidate: candidate, forecast: forecast,
                                              proposedDay: proposal, calendar: calendar))
        XCTAssertEqual(advice(day: proposal, candidate: candidate, slot: slot, forecast: forecast), .none)
    }

    /// Work that has to be split still gets a default: the proposal is the day the task is FINISHED
    /// by, which is what a due date means, even though no single day held all of it.
    func testSplitWorkDefaultsToTheDayItIsFinishedBy() throws {
        let task = try remoteTask(["id": "draft", "duration": 900])
        let candidate = Forecast.TaskInput.draft(task, projectID: nil, durationMinutes: 15)
        let inputs = [day(7, workMinutes: 10), day(8, workMinutes: 10)]
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        XCTAssertTrue(slot.fits)
        XCTAssertEqual(slot.startDate, date(7))
        XCTAssertEqual(slot.proposedDay, date(8), "10 minutes on the 7th, the last 5 on the 8th")
    }

    /// A date the user typed or picked is theirs. The default applies once, to a field still holding
    /// exactly what the app seeded — never to a date that has since changed, and never twice.
    func testDefaultNeverOverwritesAUserChosenDateAndOnlyAppliesOnce() {
        let seeded = date(11), proposal = date(7), chosen = date(9)
        XCTAssertEqual(ToDoDueDateDefault.dayToApply(proposal: proposal, current: seeded, lastDefaulted: seeded,
                                                     hasDefaulted: false, isNew: true, calendar: calendar), proposal)
        XCTAssertNil(ToDoDueDateDefault.dayToApply(proposal: proposal, current: chosen, lastDefaulted: seeded,
                                                   hasDefaulted: false, isNew: true, calendar: calendar))
        XCTAssertNil(ToDoDueDateDefault.dayToApply(proposal: proposal, current: seeded, lastDefaulted: seeded,
                                                   hasDefaulted: true, isNew: true, calendar: calendar))
        XCTAssertNil(ToDoDueDateDefault.dayToApply(proposal: proposal, current: seeded, lastDefaulted: seeded,
                                                   hasDefaulted: false, isNew: false, calendar: calendar))
        XCTAssertNil(ToDoDueDateDefault.dayToApply(proposal: nil, current: seeded, lastDefaulted: seeded,
                                                   hasDefaulted: false, isNew: true, calendar: calendar))
        // Already on the proposed day: nothing to write, so the one-shot is not spent either.
        XCTAssertNil(ToDoDueDateDefault.dayToApply(proposal: proposal, current: proposal, lastDefaulted: proposal,
                                                   hasDefaulted: false, isNew: true, calendar: calendar))
    }

    /// One proposal, one call: the day the field defaults to and the day the warning points at are
    /// the same `SlotSuggestion.proposedDay`, so no two lines on the screen can name different days.
    func testProposalBehindTheDefaultAndTheWarningIsTheSameCall() throws {
        let task = try remoteTask(["id": "draft", "duration": 900])
        let candidate = Forecast.TaskInput.draft(task, projectID: nil, durationMinutes: 15)
        let inputs = [day(7, workMinutes: 5), day(8, workMinutes: 60)]
        let forecast = calculate(days: inputs)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        let proposal = try XCTUnwrap(slot.proposedDay)
        let defaulted = ToDoDueDateDefault.dayToApply(proposal: slot.proposedDay, current: date(7),
                                                      lastDefaulted: date(7), hasDefaulted: false,
                                                      isNew: true, calendar: calendar)
        guard case .shortfall(let warning) = advice(day: date(7), candidate: candidate, slot: slot, forecast: forecast)
        else { return XCTFail("a 15m task on a day with 5m free must warn") }
        XCTAssertEqual(defaulted, proposal)
        XCTAssertEqual(warning.suggestedDay, proposal)
        XCTAssertEqual(warning.suggestedDay, defaulted)
        XCTAssertTrue(ForecastText.dayAdvice(warning).contains(ToDoDates.weekdayDayMonth(proposal)))
    }

    /// A task too big for the whole horizon has no day to propose, so the screen says exactly that
    /// once rather than pairing "does not fit" with a shortfall naming a day.
    func testTaskThatFitsNowhereSaysSoInsteadOfProposingADay() throws {
        let task = try remoteTask(["id": "huge", "duration": 36000])
        let candidate = Forecast.TaskInput.draft(task, projectID: nil, durationMinutes: 600)
        let inputs = [day(7, workMinutes: 60), day(8, workMinutes: 60)]
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        XCTAssertNil(slot.proposedDay)
        XCTAssertEqual(advice(day: date(7), candidate: candidate, slot: slot, forecast: calculate(days: inputs)),
                       .doesNotFit)
    }

    // MARK: The editor's own path to the warning (follow-up: "I don't see the warning")

    /// The whole chain the task editor walks — a task row, the duration the editor seeds its field
    /// with, the candidate it builds from both, the decision the warning view makes, and the sentence
    /// it renders — for a 15-minute task on a day with only 10 minutes left.
    func testFifteenMinuteTaskOnADayWithTenMinutesFreeWarnsThroughTheEditorsOwnPath() throws {
        let task = try remoteTask(["id": "editing", "duration": 900])
        let minutes = try XCTUnwrap(Int(ToDoEditorSheet.durationText(for: task)))
        XCTAssertEqual(minutes, 15)
        let candidate = Forecast.TaskInput.draft(task, projectID: nil, durationMinutes: minutes)
        let inputs = [day(7, workMinutes: 10), day(8, workMinutes: 10), day(9, workMinutes: 60)]
        let forecast = calculate(days: inputs)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        guard case .shortfall(let warning) = advice(day: date(7), candidate: candidate, slot: slot, forecast: forecast)
        else { return XCTFail("expected a shortfall, got \(advice(day: date(7), candidate: candidate, slot: slot, forecast: forecast))") }
        let proposal = try XCTUnwrap(slot.proposedDay)
        XCTAssertEqual(warning.availableMinutes, 10)
        XCTAssertEqual(warning.suggestedDay, proposal, "the warning may only ever point at the one proposal")
        let message = ForecastText.dayAdvice(warning)
        XCTAssertTrue(message.contains(ForecastText.duration(10)), message)
        XCTAssertTrue(message.contains(ToDoDates.weekdayDayMonth(date(7))), message)
        XCTAssertTrue(message.contains(ToDoDates.weekdayDayMonth(proposal)), message)
    }

    /// The same path stays silent when it should: a day with room, and a day taken from the
    /// suggestion row (which must not be argued with immediately after the app proposed it).
    /// The same path stays silent when it should: a day with room, the day the app itself proposes
    /// (which it must never argue with), no forecast yet, and no date at all.
    func testEditorsPathStaysSilentForADayWithRoomOrTheDayItProposes() throws {
        let task = try remoteTask(["id": "editing", "duration": 900])
        let candidate = Forecast.TaskInput.draft(task, projectID: nil, durationMinutes: 15)
        let inputs = [day(7, workMinutes: 10), day(8, workMinutes: 60)]
        let forecast = calculate(days: inputs)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        XCTAssertEqual(advice(day: date(8), candidate: candidate, slot: slot, forecast: forecast), .none)
        XCTAssertEqual(advice(day: slot.proposedDay, candidate: candidate, slot: slot, forecast: forecast), .none)
        XCTAssertEqual(advice(day: date(7), candidate: candidate, slot: slot, forecast: nil), .none)
        XCTAssertEqual(advice(day: nil, candidate: candidate, slot: slot, forecast: forecast), .none)
    }

    /// An overdue task's stored date is a day the forecast never costed: no warning, and the
    /// diagnostic says so in as many words rather than leaving the next report to guesswork.
    func testOverdueStoredDateIsNotACapacityClaimAndIsDiagnosed() throws {
        let task = try remoteTask(["id": "overdue", "duration": 900])
        let candidate = Forecast.TaskInput.draft(task, projectID: nil, durationMinutes: 15)
        let inputs = [day(7, workMinutes: 10), day(9, workMinutes: 60)]
        let forecast = calculate(days: inputs)
        let slot = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [], calendar: calendar)
        XCTAssertEqual(advice(day: date(5), candidate: candidate, slot: slot, forecast: forecast), .none)
        let gone = try XCTUnwrap(ForecastDueDateAdvisor.diagnostic(day: date(5), candidate: candidate, slot: slot,
                                                                   forecast: forecast, calendar: calendar))
        XCTAssertTrue(gone.contains("available=not-forecast"), gone)
        XCTAssertTrue(gone.contains("over=not-forecast"), gone)
        let short = try XCTUnwrap(ForecastDueDateAdvisor.diagnostic(day: date(7), candidate: candidate, slot: slot,
                                                                    forecast: forecast, calendar: calendar))
        XCTAssertTrue(short.contains("needed=15m"), short)
        XCTAssertTrue(short.contains("available=10m"), short)
        XCTAssertTrue(short.contains("proposed=2026-09-09"), short)
    }

    private func advice(day: Date?, candidate: Forecast.TaskInput, slot: Forecast.SlotSuggestion?,
                        forecast: Forecast.Result?) -> ForecastDueDateAdvisor.Advice {
        ForecastDueDateAdvisor.advice(day: day, candidate: candidate, slot: slot, forecast: forecast,
                                      isLoading: false, error: nil, calendar: calendar)
    }

    // MARK: Chosen-day capacity warning (report 2026-09-15_17-59-04)

    /// 30 of the 60 minutes are missing on the chosen day, and the message says exactly that: the
    /// shortfall, the day it applies to, and a day that could take the task instead.
    func testChosenDayShortfallNamesTheMissingTimeItsDayAndADayWithRoom() throws {
        let inputs = [day(7, workMinutes: 30), day(8, workMinutes: 20), day(9, workMinutes: 120)]
        let forecast = calculate(days: inputs)
        let candidate = Forecast.TaskInput(id: "draft", estimatedMinutes: 60)
        let proposal = Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [],
                                         calendar: calendar).proposedDay
        let warning = Forecast.capacityWarning(forChosenDay: date(7), candidate: candidate,
                                               forecast: forecast, proposedDay: proposal, calendar: calendar)
        XCTAssertEqual(warning?.availableMinutes, 30)
        XCTAssertEqual(warning?.day, date(7))
        XCTAssertEqual(warning?.suggestedDay, date(9))
        let message = ForecastText.dayAdvice(try XCTUnwrap(warning))
        XCTAssertTrue(message.contains(ForecastText.duration(30)), message)
        XCTAssertTrue(message.contains(ToDoDates.weekdayDayMonth(date(7))), message)
        XCTAssertTrue(message.contains(ToDoDates.weekdayDayMonth(date(9))), message)
        XCTAssertFalse(message.contains("<"), message)
    }

    /// The day offered has to be one the whole task actually lands on: neither the chosen day (30 of
    /// the 60 minutes) nor tomorrow (20) can finish it, so the proposal is the day it completes — and
    /// the app never then warns about the day it just proposed.
    func testSuggestedDayIsTheDayTheTaskCompletesNotSimplyTomorrow() throws {
        let inputs = [day(7, workMinutes: 30), day(8, workMinutes: 20), day(9, workMinutes: 120)]
        let forecast = calculate(days: inputs)
        let candidate = Forecast.TaskInput(id: "draft", estimatedMinutes: 60)
        let proposal = try XCTUnwrap(Forecast.nextSlot(for: candidate, days: inputs, projects: [], tasks: [],
                                                       calendar: calendar).proposedDay)
        XCTAssertEqual(proposal, date(9))
        XCTAssertNotEqual(proposal, date(8))
        let suggested = Forecast.capacityWarning(forChosenDay: date(7), candidate: candidate, forecast: forecast,
                                                 proposedDay: proposal, calendar: calendar)?.suggestedDay
        XCTAssertEqual(suggested, proposal)
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: proposal, candidate: candidate, forecast: forecast,
                                              proposedDay: proposal, calendar: calendar))
    }

    /// A day with room says nothing at all, and neither does a task with no estimate to fit.
    func testDayWithEnoughCapacityAndAnUnestimatedTaskProduceNoWarning() {
        let forecast = calculate(days: [day(7, workMinutes: 120)])
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: date(7),
                                              candidate: Forecast.TaskInput(id: "draft", estimatedMinutes: 60),
                                              forecast: forecast, proposedDay: nil, calendar: calendar))
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: date(7),
                                              candidate: Forecast.TaskInput(id: "draft", estimatedMinutes: nil),
                                              forecast: forecast, proposedDay: nil, calendar: calendar))
    }

    /// Time the day already reserved for this same task is room it may reuse — re-picking the day a
    /// task is already on must not demand its own minutes twice.
    func testChosenDayCountsTheTasksOwnReservedTimeAsRoomAndWarnsOutsideTheHorizon() {
        let candidate = Forecast.TaskInput(id: "planned", estimatedMinutes: 60)
        let forecast = calculate(days: [day(7, workMinutes: 60)], tasks: [candidate])
        XCTAssertEqual(forecast.days[0].remainingWorkMinutes, 0)
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: date(7), candidate: candidate,
                                              forecast: forecast, proposedDay: nil, calendar: calendar))
        // A day the forecast never costed gets no capacity claim at all. Every overdue task's stored
        // date is such a day, and "no time available" on a day that has gone is noise, not news.
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: date(30), candidate: candidate,
                                              forecast: forecast, proposedDay: nil, calendar: calendar))
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: date(1), candidate: candidate,
                                              forecast: forecast, proposedDay: nil, calendar: calendar))
    }

    /// The Spanish copy must carry the same placeholders as the English: a previous capacity string
    /// lost a token in translation and shipped a half-built sentence.
    func testShortfallCopyKeepsIdenticalPlaceholdersInEnglishAndSpanish() throws {
        let keys = ["dayOverCapacity", "dayNotEnoughRoom"]
        let english = try shippedForecastStrings(BundledConfigLanguage.english)
        let spanish = try shippedForecastStrings("es")
        for key in keys {
            let source = try XCTUnwrap(english[key], key)
            let translation = try XCTUnwrap(spanish[key], key)
            XCTAssertEqual(placeholders(in: source), placeholders(in: translation), key)
            XCTAssertFalse(placeholders(in: source).isEmpty, key)
        }
        XCTAssertEqual(placeholders(in: try XCTUnwrap(english["dayOverCapacity"])),
                       ["<DATE>", "<DURATION>", "<SUGGESTED_DATE>"])
    }

    private func shippedForecastStrings(_ language: String) throws -> [String: String] {
        let url = try XCTUnwrap(Bundle.main.url(forResource: BundledConfigLanguage.resource(language),
                                                withExtension: "json"), language)
        let json = try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]
        return try XCTUnwrap(json?["localForecastViewInfo"] as? [String: String], language)
    }

    private func placeholders(in text: String) -> [String] {
        text.split(whereSeparator: { $0 == "<" || $0 == ">" })
            .map(String.init).filter { $0 == $0.uppercased() && $0.contains(where: \.isLetter) }
            .map { "<" + $0 + ">" }.sorted()
    }

    private typealias Forecast = LocalTimeForecast
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Australia/Melbourne")!
        value.firstWeekday = 2
        return value
    }
    private func date(_ day: Int = 7, hour: Int = 0, minute: Int = 0, month: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }
    private func interval(_ startHour: Int, _ endHour: Int, day: Int = 7) -> Forecast.Interval {
        Forecast.Interval(start: date(day, hour: startHour), end: date(day, hour: endHour))
    }
    /// Explicit two-hour additional-care fixture plus awake meeting time leaves the requested budget.
    private func day(_ day: Int = 7, workMinutes: Double = 840, habits: [Forecast.PlacedBlock] = []) -> Forecast.DayInput {
        let start = date(day)
        let awake = date(day, hour: 6)
        let meeting = Forecast.Interval(start: awake, end: awake.addingTimeInterval((840 - workMinutes) * 60))
        return Forecast.DayInput(date: start, meetings: [meeting], habits: habits, settings: .init(selfCareMinutes: 120))
    }
    private func calculate(days: [Forecast.DayInput], projects: [Forecast.ProjectInput] = [],
                           tasks: [Forecast.TaskInput] = []) -> Forecast.Result {
        Forecast.calculate(days: days, projects: projects, tasks: tasks, calendar: calendar)
    }

    func testExplicitAdditionalCareKeepsWeekendCapacity() {
        let result = calculate(days: [day(12)])
        XCTAssertEqual(result.days[0].capacity.availableWorkMinutes, 14 * 60)
        XCTAssertEqual(result.days[0].capacity.sleepAndSelfCareMinutes, 10 * 60)
        XCTAssertEqual(result.days[0].remainingWorkMinutes, 14 * 60)
    }

    func testMeetingUnionClipsAcrossMidnightAndDoesNotDoubleCountHabits() {
        let input = Forecast.DayInput(date: date(), meetings: [
            .init(start: date(6, hour: 23), end: date(hour: 1)), interval(9, 11), interval(10, 12)
        ], habits: [
            .habit(id: "one", blockKey: "habit:one", interval: interval(11, 13)),
            .habit(id: "two", blockKey: "habit:two", interval: interval(12, 14))
        ])
        let capacity = calculate(days: [input]).days[0].capacity
        XCTAssertEqual(capacity.meetingMinutes, 180)
        XCTAssertEqual(capacity.habitMinutes, 120)
        XCTAssertEqual(capacity.availableWorkMinutes, 660)
    }

    func testDayPlanAdapterIgnoresSleepFillersBreaksAndOverflowMarkers() {
        let blocks = [
            ScheduleBlock(kind: .habit, title: "Study", start: date(hour: 8), end: date(hour: 9)),
            ScheduleBlock(kind: .habit, title: "Overflow", start: date(hour: 9), end: date(hour: 10), didOverflow: true),
            ScheduleBlock(kind: .sleep, title: "", start: date(), end: date(hour: 8)),
            ScheduleBlock(kind: .deepWork, title: "", start: date(hour: 10), end: date(hour: 12)),
            ScheduleBlock(kind: .breakSprint, title: "", start: date(hour: 12), end: date(hour: 13))
        ]
        let capacity = calculate(days: [.fromDayPlan(date: date(), blocks: blocks)]).days[0].capacity
        XCTAssertEqual(capacity.habitMinutes, 60)
        XCTAssertEqual(capacity.availableWorkMinutes, 900)
    }

    func testVeryBusyDayExposesDeficitAndNeverAllocatesNegativeTime() {
        let input = Forecast.DayInput(date: date(), meetings: [interval(0, 24)], habits: [], settings: .init(selfCareMinutes: 120))
        let result = calculate(days: [input], tasks: [.init(id: "a", estimatedMinutes: 20)])
        XCTAssertEqual(result.days[0].capacity.overcommittedMinutes, 120)
        XCTAssertEqual(result.tasks[0].unallocatedMinutes, 20)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 0)
    }

    /// Inverted on purpose. A rating is a claim about how far something may be POSTPONED, not about
    /// urgency, so it must never take the only free hour from a project with an earlier deadline
    /// (report 2026-09-16_06-40-52). The nearer deadline wins even when the other side is rated 10.
    func testAnEarlierProjectDeadlineBeatsAHigherRating() {
        let projects = [Forecast.ProjectInput(id: "low", outcome: 4, dueDate: date()),
                        Forecast.ProjectInput(id: "high", outcome: 10, dueDate: date(8))]
        let result = calculate(days: [day(workMinutes: 60)], projects: projects, tasks: [
            .init(id: "low-task", projectID: "low", estimatedMinutes: 60, outcome: 10),
            .init(id: "high-task", projectID: "high", estimatedMinutes: 60, outcome: 2)
        ])
        XCTAssertEqual(result.tasks[0].task.id, "low-task", "Due today beats rated 10 due in a week")
        XCTAssertEqual(result.tasks[0].unallocatedMinutes, 0)
        XCTAssertEqual(result.tasks[1].unallocatedMinutes, 60)
    }

    /// Within a project the order is DUE then rating then perspiration then id. The rating moved
    /// below the due date for the same reason it did between projects: being hard to move is not a
    /// reason to take a day from a task that is due sooner.
    func testTaskOrderingUsesDueThenOutcomeThenPerspirationAndStableID() {
        let project = Forecast.ProjectInput(id: "p")
        let inputs: [Forecast.TaskInput] = [
            .init(id: "b", projectID: "p", estimatedMinutes: 10, outcome: 6, perspiration: 2, dueDate: date()),
            .init(id: "a", projectID: "p", estimatedMinutes: 10, outcome: 6, perspiration: 2, dueDate: date()),
            .init(id: "harder", projectID: "p", estimatedMinutes: 10, outcome: 6, perspiration: 8, dueDate: date()),
            .init(id: "later", projectID: "p", estimatedMinutes: 10, outcome: 6, perspiration: 1, dueDate: date(8)),
            .init(id: "important", projectID: "p", estimatedMinutes: 10, outcome: 10, dueDate: date(9))
        ]
        let result = calculate(days: [day()], projects: [project], tasks: inputs)
        // Due date first: the three due today (a, b, harder — tied, so split by perspiration then
        // id), then "later" on the 8th, then "important" on the 9th. Being rated 10 no longer moves
        // "important" to the front of tasks that are due before it.
        XCTAssertEqual(result.tasks.map { $0.task.id }, ["a", "b", "harder", "later", "important"])
        let shuffled = calculate(days: [day()], projects: [project], tasks: Array(inputs.reversed()))
        XCTAssertEqual(result.tasks.map { $0.task.id }, shuffled.tasks.map { $0.task.id })
    }

    func testLikelyCompletionIncludesKnownCompletedEffortAndDeadlineIsInclusive() {
        let project = Forecast.ProjectInput(id: "p", dueDate: date())
        let result = calculate(days: [day(workMinutes: 60), day(8)], projects: [project], tasks: [
            .init(id: "done", projectID: "p", estimatedMinutes: 20, completed: true),
            .init(id: "todo", projectID: "p", estimatedMinutes: 80)
        ])
        XCTAssertEqual(result.projects[0].likelyCompletionPercent, 80)
        XCTAssertEqual(result.projects[0].completionDate, date(8))
    }

    /// Report 2026-09-12_20-50-16: "it says likely to complete 0% but I've already completed half of
    /// the tasks". The forecast only downloads unfinished work, so finished tasks were invisible to
    /// it; the project's own counters supply that half.
    func testLikelyCompletionCountsWorkAlreadyFinishedFromTheProjectCounters() {
        // Half the tasks done, a deadline already past, and no capacity left: nothing more fits.
        let project = Forecast.ProjectInput(id: "p", dueDate: date(6), totalTaskCount: 4, uncompletedTaskCount: 2)
        let result = calculate(days: [day(workMinutes: 0)], projects: [project], tasks: [
            .init(id: "a", projectID: "p", estimatedMinutes: 60),
            .init(id: "b", projectID: "p", estimatedMinutes: 60)
        ])
        XCTAssertEqual(result.projects[0].likelyCompletionPercent, 50,
                       "Nothing more fits, but half the project is already done")
    }

    func testLikelyCompletionCombinesFinishedWorkWithWhatStillFits() {
        // Half done; of the two hours left, one fits before the deadline: 50% + 50% of 50%.
        let project = Forecast.ProjectInput(id: "p", dueDate: date(), totalTaskCount: 4, uncompletedTaskCount: 2)
        let result = calculate(days: [day(workMinutes: 60), day(8)], projects: [project], tasks: [
            .init(id: "a", projectID: "p", estimatedMinutes: 60),
            .init(id: "b", projectID: "p", estimatedMinutes: 60)
        ])
        XCTAssertEqual(result.projects[0].likelyCompletionPercent, 75)
    }

    func testLikelyCompletionIgnoresCountersThatMakeNoSense() {
        let project = Forecast.ProjectInput(id: "p", dueDate: date(), totalTaskCount: 2, uncompletedTaskCount: 5)
        let result = calculate(days: [day(workMinutes: 60)], projects: [project], tasks: [
            .init(id: "a", projectID: "p", estimatedMinutes: 60)
        ])
        XCTAssertEqual(result.projects[0].likelyCompletionPercent, 100,
                       "More unfinished than total is nonsense; fall back to what the forecast can see")
    }

    /// The counters come from the server, whose `uncompleted_task_count` ignores custom "done"
    /// columns, so they can insist on outstanding tasks the forecast can no longer see. What the
    /// forecast downloaded is the honest number: nothing left to place means nothing left to do.
    func testProjectWhoseTasksAreAllFinishedReadsAsCompleteDespiteStaleServerCounters() {
        let project = Forecast.ProjectInput(id: "p", dueDate: date(), totalTaskCount: 15, uncompletedTaskCount: 5)
        let result = calculate(days: [day(workMinutes: 60)], projects: [project], tasks: [])
        XCTAssertEqual(result.projects[0].outstandingTaskCount, 0)
        XCTAssertTrue(result.projects[0].isFinished)
        XCTAssertEqual(result.projects[0].likelyCompletionPercent, 100)
    }

    func testProjectWithWorkStillOutstandingIsNeverReportedAsFinished() {
        let project = Forecast.ProjectInput(id: "p", dueDate: date(), totalTaskCount: 15, uncompletedTaskCount: 5)
        let result = calculate(days: [day(workMinutes: 60)], projects: [project], tasks: [
            .init(id: "left", projectID: "p", estimatedMinutes: 30)
        ])
        XCTAssertEqual(result.projects[0].outstandingTaskCount, 1)
        XCTAssertFalse(result.projects[0].isFinished)
    }

    func testAProjectThatNeverHadATaskIsEmptyRatherThanFinished() {
        let result = calculate(days: [day(workMinutes: 60)], projects: [.init(id: "p", dueDate: date())], tasks: [])
        XCTAssertFalse(result.projects[0].isFinished, "No counters is not evidence that work was done")
        XCTAssertNil(result.projects[0].likelyCompletionPercent)
    }

    func testUnknownEffortSuppressesMisleadingCompletionPercentage() {
        let result = calculate(days: [day()], projects: [.init(id: "p")], tasks: [
            .init(id: "known", projectID: "p", estimatedMinutes: 20),
            .init(id: "unknown", projectID: "p", estimatedMinutes: 0)
        ])
        XCTAssertNil(result.projects[0].likelyCompletionPercent)
        XCTAssertEqual(result.projects[0].unknownTaskCount, 1)
        XCTAssertNil(result.projects[0].completionDate)
        XCTAssertTrue(Forecast.proposeWorkPlan(result, calendar: calendar).conflicts.contains { $0.reason == .missingEstimate })
    }

    func testSeventeenMinuteTaskInTenMinuteHabitOnlyUsesSevenWorkMinutes() {
        let habit = Forecast.PlacedBlock.habit(id: "occurrence", blockKey: "habit:Study",
                                   interval: .init(start: date(hour: 12), end: date(hour: 12, minute: 10)))
        let input = Forecast.DayInput(date: date(), meetings: [], habits: [habit])
        let result = calculate(days: [input], tasks: [
            .init(id: "task", estimatedMinutes: 17, blockAssignment: .init(date: date(), blockKey: "habit:Study"))
        ])
        XCTAssertEqual(result.days[0].capacity.habitMinutes, 10)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 7)
        XCTAssertEqual(result.days[0].absorbedBlockMinutes, 10)
        XCTAssertEqual(result.days[0].remainingWorkMinutes, 943)
    }

    func testMultipleLinkedTasksShareHabitCapacityExactlyOnce() {
        let habit = Forecast.PlacedBlock.habit(id: "occurrence", blockKey: "habit:Study",
                                   interval: .init(start: date(hour: 12), end: date(hour: 12, minute: 10)))
        let assignment = Forecast.BlockAssignment(date: date(), blockKey: "habit:Study")
        let result = calculate(days: [.init(date: date(), meetings: [], habits: [habit])], tasks: [
            .init(id: "a", estimatedMinutes: 7, outcome: 10, blockAssignment: assignment),
            .init(id: "b", estimatedMinutes: 7, outcome: 2, blockAssignment: assignment)
        ])
        XCTAssertEqual(result.tasks[0].allocations[0].absorbedBlockMinutes, 7)
        XCTAssertEqual(result.tasks[1].allocations[0].absorbedBlockMinutes, 3)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 4)
    }

    func testCompletedLinkedTaskHasAlreadyUsedItsHabitShare() {
        let habit = Forecast.PlacedBlock.habit(id: "occurrence", blockKey: "habit:Study",
                                   interval: .init(start: date(hour: 12), end: date(hour: 12, minute: 10)))
        let assignment = Forecast.BlockAssignment(date: date(), blockKey: "habit:Study")
        let result = calculate(days: [.init(date: date(), meetings: [], habits: [habit])],
                               projects: [.init(id: "p")], tasks: [
            .init(id: "done", projectID: "p", estimatedMinutes: 7, blockAssignment: assignment, completed: true),
            .init(id: "pending", projectID: "p", estimatedMinutes: 7, blockAssignment: assignment)
        ])
        XCTAssertEqual(result.days[0].absorbedBlockMinutes, 3)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 4)
        XCTAssertEqual(result.projects[0].completedMinutes, 7)
        XCTAssertEqual(result.projects[0].allocatedByDeadlineMinutes, 7)
        XCTAssertEqual(result.projects[0].likelyCompletionPercent, 100)
    }

    func testMeetingOverlapCannotBeClaimedAgainByAssignedTask() {
        let input = Forecast.DayInput(date: date(), meetings: [interval(9, 10)], habits: [
            .habit(id: "occurrence", blockKey: "habit:Study", interval: interval(9, 11))
        ])
        let result = calculate(days: [input], tasks: [
            .init(id: "a", estimatedMinutes: 90, blockAssignment: .init(date: date(), blockKey: "habit:Study"))
        ])
        XCTAssertEqual(result.days[0].absorbedBlockMinutes, 60)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 30)
    }

    func testFutureBlockAssignmentDoesNotSpendTodayOrBorrowAnotherDaysHabit() {
        let input = Forecast.DayInput(date: date(8), meetings: [], habits: [
            .habit(id: "occurrence", blockKey: "habit:Study", interval: interval(9, 10, day: 8))
        ])
        let result = calculate(days: [day(), input], tasks: [
            .init(id: "a", estimatedMinutes: 60, blockAssignment: .init(date: date(8), blockKey: "habit:Study"))
        ])
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 0)
        XCTAssertEqual(result.tasks[0].completionDate, date(8))
        XCTAssertEqual(result.days[1].absorbedBlockMinutes, 60)
    }

    func testDuplicateDaysTasksAndHabitSnapshotsDoNotCreateExtraCapacity() {
        let habit = Forecast.PlacedBlock.habit(id: "same", blockKey: "habit:Study", interval: interval(12, 13))
        let input = Forecast.DayInput(date: date(), meetings: [], habits: [habit])
        let task = Forecast.TaskInput(id: "same", estimatedMinutes: 20)
        let result = calculate(days: [input, input], tasks: [task, task])
        XCTAssertEqual(result.days.count, 1)
        XCTAssertEqual(result.tasks.count, 1)
        XCTAssertEqual(result.days[0].capacity.habitMinutes, 60)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 20)
    }

    func testSlotSuggestionUsesOutcomeAndPerspirationWithoutFullDayFallback() {
        let input = [day(workMinutes: 20), day(8, workMinutes: 20)]
        let existing = Forecast.TaskInput(id: "existing", estimatedMinutes: 20, outcome: 6, perspiration: 8)
        let candidate = Forecast.TaskInput(id: "candidate", estimatedMinutes: 20, outcome: 6, perspiration: 2)
        let suggestion = Forecast.nextSlot(for: candidate, days: input, projects: [], tasks: [existing], calendar: calendar)
        XCTAssertEqual(suggestion.startDate, date())
        XCTAssertTrue(suggestion.fits)
        let tooLarge = Forecast.nextSlot(for: .init(id: "large", estimatedMinutes: 100), days: input,
                                        projects: [], tasks: [], calendar: calendar)
        XCTAssertFalse(tooLarge.fits)
        XCTAssertNil(tooLarge.completionDate)
        XCTAssertEqual(tooLarge.unallocatedMinutes, 60)
    }

    func testManualDateWarningDoesNotDisplaceExistingWork() {
        let candidate = Forecast.TaskInput(id: "new", estimatedMinutes: 20)
        let existing = Forecast.TaskInput(id: "existing", estimatedMinutes: 20, outcome: 10)
        let input = [day(workMinutes: 20), day(8, workMinutes: 20)]
        let forecast = calculate(days: input, tasks: [existing])
        let proposal = Forecast.nextSlot(for: candidate, days: input, projects: [],
                                         tasks: [existing], calendar: calendar).proposedDay
        let warning = Forecast.capacityWarning(forChosenDay: date(), candidate: candidate,
                                               forecast: forecast, proposedDay: proposal, calendar: calendar)
        XCTAssertEqual(warning?.availableMinutes, 0)
        XCTAssertEqual(warning?.suggestedDay, date(8))
        XCTAssertEqual(proposal, date(8))
        XCTAssertNil(Forecast.capacityWarning(forChosenDay: date(8), candidate: candidate,
                                              forecast: forecast, proposedDay: proposal, calendar: calendar))
    }

    func testWorkPlanPreservesHardProjectAndTaskDeadlines() {
        let result = calculate(days: [day(workMinutes: 0), day(8)], projects: [
            .init(id: "p", outcome: 10, dueDate: date())
        ], tasks: [.init(id: "t", projectID: "p", estimatedMinutes: 20, outcome: 10, dueDate: date())])
        let plan = Forecast.proposeWorkPlan(result, calendar: calendar)
        XCTAssertTrue(plan.changes.isEmpty)
        // Neither reports a conflict any more, and that is the point of reserving capacity for a 5
        // (report 2026-09-16_09-40-20): the task is now held on its OWN due day rather than being
        // allocated to whichever day had room, so its finish equals its due date — and the project's
        // finish, which is the latest of its tasks', therefore equals the project's deadline too.
        // Previously the task was pushed to the 8th and the plan had to explain itself twice.
        XCTAssertTrue(plan.conflicts.isEmpty,
                      "A hard deadline sitting on its own day has nothing to refuse and nothing to report")
        XCTAssertEqual(result.tasks[0].allocations.map(\.day), [date()],
                       "…because the work is held on the day it is due, even though that day has no room")
        XCTAssertEqual(result.tasks[0].task.dueDate, date(), "Generating a plan cannot mutate the snapshot")
    }

    /// The ratings moved a rung when the scale was re-cut (report 2026-09-16_08-52-35): "a few
    /// months" is now 2/5 (wire 4, 90 days) and "a few weeks" 3/5 (wire 6, 21 days). The ids still
    /// name the band they stand for; only the number behind each band changed.
    func testWorkPlanExtendsWithinOutcomeAllowanceButReportsExcess() {
        let result = calculate(days: [day(30)], projects: [
            .init(id: "months", outcome: 4, dueDate: date()),
            .init(id: "weeks", outcome: 6, dueDate: date())
        ], tasks: [
            .init(id: "m", projectID: "months", estimatedMinutes: 20, outcome: 4, dueDate: date()),
            .init(id: "w", projectID: "weeks", estimatedMinutes: 20, outcome: 6, dueDate: date())
        ])
        let plan = Forecast.proposeWorkPlan(result, calendar: calendar)
        XCTAssertTrue(plan.changes.contains { $0.kind == .project && $0.itemID == "months" && $0.proposedDate == date(30) })
        XCTAssertTrue(plan.conflicts.contains { $0.kind == .project && $0.itemID == "weeks" && $0.reason == .postponementLimit })
        XCTAssertFalse(plan.changes.contains { $0.itemID == "weeks" })
    }

    func testWorkPlanPullsTasksForwardWithoutMovingAchievableProjectDeadline() {
        let result = calculate(days: [day()], projects: [.init(id: "p", dueDate: date(10))], tasks: [
            .init(id: "t", projectID: "p", estimatedMinutes: 20, dueDate: date(10))
        ])
        let plan = Forecast.proposeWorkPlan(result, calendar: calendar)
        XCTAssertEqual(plan.changes.count, 1)
        XCTAssertEqual(plan.changes[0].kind, .task)
        XCTAssertEqual(plan.changes[0].proposedDate, date())
    }

    func testWeeksUseCalendarBoundariesAndProjectChartDoesNotDoubleCountAbsorption() {
        let habit = Forecast.PlacedBlock.habit(id: "occurrence", blockKey: "habit:Study", interval: interval(12, 13))
        let result = calculate(days: [.init(date: date(), meetings: [], habits: [habit]), day(14)], projects: [.init(id: "p")], tasks: [
            .init(id: "t", projectID: "p", estimatedMinutes: 90, blockAssignment: .init(date: date(), blockKey: "habit:Study"))
        ])
        let weeks = result.weeks(calendar: calendar)
        XCTAssertEqual(weeks.count, 2)
        XCTAssertEqual(weeks[0].start, date())
        XCTAssertEqual(weeks[0].workMinutesByProject["p"], 30)
        XCTAssertEqual(weeks[0].habitMinutes, 60)
    }

    func testSpringDSTUsesActualDayAndSleepLengthsWithoutStealingFromTomorrow() {
        // Melbourne skips an hour on 4 October 2026. A midnight-crossing event still contributes
        // only its actual overlap; using +86400 as the day end would steal an hour from tomorrow.
        let start = date(4, month: 10)
        let end = date(5, month: 10)
        XCTAssertEqual(end.timeIntervalSince(start), 23 * 3600)
        let input = Forecast.DayInput(date: start, meetings: [
            .init(start: date(4, hour: 23, month: 10), end: date(5, hour: 1, month: 10))
        ], habits: [])
        let capacity = calculate(days: [input]).days[0].capacity
        XCTAssertEqual(capacity.meetingMinutes, 0)
        XCTAssertEqual(capacity.totalMinutes, 1380)
        XCTAssertEqual(capacity.sleepMinutes, 420)
        XCTAssertEqual(capacity.availableWorkMinutes, 960)
    }

    func testFractionalMinuteHabitsAreNotRoundedAway() {
        let input = Forecast.DayInput(date: date(), meetings: [], habits: [
            .habit(id: "brief", blockKey: "habit:brief", interval: .init(start: date(hour: 12), end: date(hour: 12).addingTimeInterval(30)))
        ])
        XCTAssertEqual(calculate(days: [input]).days[0].capacity.availableWorkMinutes, 959.5)
    }
    private func remoteTask(_ extra: [String: Any] = [:]) throws -> ToDoTask {
        var values: [String: Any] = ["id": "remote", "title": "Task", "status": "NOT_STARTED", "eisenhower_quadrant": 1, "duration": 1020]
        extra.forEach { values[$0.key] = $0.value }
        return try JSONDecoder().decode(ToDoTask.self, from: JSONSerialization.data(withJSONObject: values))
    }

    func testSnapshotReconcilesImportedTaskAndLocalBlockAssignmentOnce() throws {
        let task = try remoteTask(["project_id": "project", "due_date": "2026-09-07"])
        let local = DayPlanTask(id: "local", title: "Edited task", durationMinutes: 17,
                                sourceTaskId: "remote", blockKey: "habit:Study", project: "Project")
        let result = LocalForecastSnapshot.tasks(remote: [task], local: [(date: date(), task: local)],
                                                projects: [Project(id: "project", name: "Project")], today: date(), calendar: calendar)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "remote")
        XCTAssertEqual(result[0].blockAssignment?.blockKey, "habit:Study")
        XCTAssertEqual(result[0].estimatedMinutes, 17)
    }

    func testSnapshotMapsSyncedProjectIDToItsDisplayedProjectID() throws {
        let task = try remoteTask(["synced_project_id": "external"])
        let project = Project(id: "tag", name: "External project", synced_project_id: "external")
        let result = LocalForecastSnapshot.tasks(remote: [task], local: [], projects: [project], today: date(), calendar: calendar)
        XCTAssertEqual(result.first?.projectID, "tag")
    }

    func testSnapshotDoesNotResurrectADeletedSyncedTaskFromLocalStorage() {
        let deleted = DayPlanTask(title: "Stale", sourceTaskId: "deleted")
        let result = LocalForecastSnapshot.tasks(remote: [], local: [(date: date(), task: deleted)],
                                                projects: [], today: date(), calendar: calendar)
        XCTAssertTrue(result.isEmpty)
    }

    func testUnratedEditorPreservesNilAndClearingOutcomeIsExplicitOnWire() throws {
        let task = try remoteTask()
        XCTAssertNil(ToDoDraft.editable(task).outcome)
        XCTAssertNil(ToDoUpsertBody.make(from: task)["outcome"])
        XCTAssertTrue(ToDoUpsertBody.make(from: task, clearOutcome: true)["outcome"] is NSNull)
        let odd = try remoteTask(["outcome": 7])
        XCTAssertEqual(ToDoDraft.editable(odd).outcome, 7)
        XCTAssertEqual(ToDoUpsertBody.make(from: odd)["outcome"] as? Int, 7)
    }

    func testProjectOutcomeIsSeparateFromLegacyImportanceAndPreservesOddValues() throws {
        let data = Data(#"{"id":"p","name":"Project","importance":4,"outcome":7}"#.utf8)
        let project = try JSONDecoder().decode(Project.self, from: data)
        // Legacy importance stays on the model for the server's portfolio ranking; the settings
        // form carries only the rating the user edits, so saving cannot rewrite importance.
        XCTAssertEqual(project.importance, 4)
        XCTAssertEqual(project.outcome, 7)
        var form = ProjectDetailStore.SettingsForm(project: project)
        form.description = "Unrelated edit"
        XCTAssertEqual(form.outcome, 7)
    }

    // MARK: - Outcome scale: one definition for tasks and projects (report 2026-09-15_20-12-49)

    func testOutcomeScaleReadsAsDeadlineFlexibilityAtEveryLevel() {
        let strings = ToDoStrings.load()
        // Re-cut by the PO (report 2026-09-16_08-52-35). Every rung still says how far the item can
        // be pushed back — that is what makes this a shiftability scale rather than an urgency one.
        let expected = ["Can postpone a year or more", "Can postpone a few months", "Can postpone a few weeks",
                        "Can postpone a few days", "Hard deadline — can't shift"]
        for step in 1...ToDoScoring.outcomeSteps {
            XCTAssertEqual(strings.outcomeLabel(step * ToDoScoring.outcomeWireFactor), expected[step - 1],
                           "step \(step) should read as how far it can be pushed back")
        }
    }

    func testEveryOutcomeStepHasARowAndTheWireMappingIsUnchanged() {
        let strings = ToDoStrings.load()
        for step in 1...ToDoScoring.outcomeSteps {
            let wire = step * ToDoScoring.outcomeWireFactor
            XCTAssertEqual(wire, step * 2, "the 1–5 display still doubles onto the 1–10 wire scale")
            let row = strings.outcomeOptionLabel(displayValue: step)
            XCTAssertTrue(row.hasPrefix("\(step) / \(ToDoScoring.outcomeSteps) · "), "row \(step) is \(row)")
            XCTAssertFalse(strings.outcomeLabel(wire).isEmpty)
        }
    }

    /// The project picker and the task picker must not merely agree today — they must read the same
    /// label from the same function, which is what stops them drifting apart again.
    func testProjectAndTaskPickersDescribeTheSameNumberIdentically() {
        let strings = ToDoStrings.load()
        for wire in ToDoScoring.minLevel...ToDoScoring.maxLevel {
            XCTAssertEqual(ForecastText.outcomeLabel(wire), strings.outcomeLabel(wire),
                           "wire \(wire) must read the same wherever it is shown")
        }
    }

    func testOutcomeWordingMatchesTheDeadlineBandsTheForecastPlansAgainst() {
        let strings = ToDoStrings.load()
        // The scale was re-cut by the PO (report 2026-09-16_08-52-35); the words and the day
        // allowances move together, because the words are what the allowance is FOR.
        // 10 = no slack at all, and the forecast refuses to move such a due date.
        XCTAssertEqual(LocalTimeForecast.postponementDays(outcome: 10), 0)
        XCTAssertEqual(strings.outcomeLabel(10), "Hard deadline — can't shift")
        // 8–9 ≈ a week, 6–7 ≈ three weeks, 4–5 ≈ three months, below that unbounded.
        XCTAssertEqual(LocalTimeForecast.postponementDays(outcome: 8), 7)
        XCTAssertEqual(strings.outcomeLabel(8), "Can postpone a few days")
        XCTAssertEqual(LocalTimeForecast.postponementDays(outcome: 6), 21)
        XCTAssertEqual(strings.outcomeLabel(6), "Can postpone a few weeks")
        XCTAssertEqual(LocalTimeForecast.postponementDays(outcome: 4), 90)
        XCTAssertEqual(strings.outcomeLabel(4), "Can postpone a few months")
        XCTAssertNil(LocalTimeForecast.postponementDays(outcome: 2))
        XCTAssertEqual(strings.outcomeLabel(2), "Can postpone a year or more")
    }

    // MARK: - Project outcome saves, and the heading shows it (reports 2026-09-11_20-00-34 / 2026-09-15_10-27-17)

    func testProjectSettingsSendsOutcomeAndLeavesLegacyImportanceAlone() throws {
        let data = Data(#"{"id":"p","name":"Project","importance":4,"outcome":2}"#.utf8)
        let project = try JSONDecoder().decode(Project.self, from: data)
        var form = ProjectDetailStore.SettingsForm(project: project)
        form.outcome = ToDoScoring.outcomeSteps * ToDoScoring.outcomeWireFactor
        let body = ProjectDetailStore.settingsBody(form, name: project.name)
        XCTAssertEqual(body["outcome"] as? Int, 10, "the 5 / 5 step goes out as the wire value 10")
        XCTAssertNil(body["importance"], "the legacy ranking field must not be rewritten from the rating")
    }

    func testClearingAProjectOutcomeIsExplicitOnTheWire() throws {
        let data = Data(#"{"id":"p","name":"Project","outcome":6}"#.utf8)
        let project = try JSONDecoder().decode(Project.self, from: data)
        var form = ProjectDetailStore.SettingsForm(project: project)
        form.outcome = nil
        XCTAssertTrue(ProjectDetailStore.settingsBody(form, name: project.name)["outcome"] is NSNull)
    }

    func testAProjectWithNoOutcomeIsUnaffectedAndItsHeadingSaysSo() throws {
        let data = Data(#"{"id":"p","name":"Project","importance":3}"#.utf8)
        let project = try JSONDecoder().decode(Project.self, from: data)
        XCTAssertNil(project.outcome)
        XCTAssertNil(project.due_date)
        let form = ProjectDetailStore.SettingsForm(project: project)
        XCTAssertNil(form.outcome, "an unrated project stays unrated until the user rates it")
        XCTAssertNil(form.dueDate)
        // Saving an untouched form must not invent a rating for it.
        XCTAssertTrue(ProjectDetailStore.settingsBody(form, name: project.name)["outcome"] is NSNull)
    }

    func testProjectHeadingShowsTheOutcomeWhenPresentAndPromptsWhenNot() throws {
        let strings = ToDoStrings.load()
        let rated = try JSONDecoder().decode(Project.self, from: Data(#"{"id":"p","name":"P","outcome":8}"#.utf8))
        XCTAssertEqual(strings.outcomeOptionLabel(displayValue: (rated.outcome ?? 0) / ToDoScoring.outcomeWireFactor),
                       "4 / 5 · Can postpone a few days")
        let unrated = try JSONDecoder().decode(Project.self, from: Data(#"{"id":"p","name":"P"}"#.utf8))
        XCTAssertNil(unrated.outcome)
        XCTAssertFalse(strings[.setOutcome].isEmpty, "an unrated project offers the way to rate it")
    }

    func testProjectHeadingDueDateDegradesGracefullyWhenMissing() throws {
        let strings = ToDoStrings.load()
        let dated = try JSONDecoder().decode(Project.self, from: Data(#"{"id":"p","name":"P","due_date":"2026-09-15"}"#.utf8))
        XCTAssertFalse(strings.dueLabel(dated.due_date).isEmpty)
        let undated = try JSONDecoder().decode(Project.self, from: Data(#"{"id":"p","name":"P"}"#.utf8))
        XCTAssertNil(undated.due_date)
        XCTAssertFalse(strings[.setDueDate].isEmpty, "an undated project offers the way to date it")
    }

    func testProjectWithoutOutcomeDoesNotGetAnUnboundedDeadlineExtension() {
        let result = calculate(days: [day(8)], projects: [.init(id: "p", outcome: 0, dueDate: date())], tasks: [
            .init(id: "t", projectID: "p", estimatedMinutes: 20)
        ])
        let plan = Forecast.proposeWorkPlan(result, calendar: calendar)
        XCTAssertFalse(plan.changes.contains { $0.kind == .project })
        XCTAssertTrue(plan.conflicts.contains { $0.kind == .project && $0.reason == .missingOutcome })
    }

    func testTypedTaskOutcomeUsesDisplayedFivePointScale() {
        // `!N` since 2026-09-21; `*` now introduces a duration (report 2026-09-21_07-42-02).
        let parsed = extractPriorityToken("Draft report !4")
        XCTAssertEqual(parsed.title, "Draft report")
        XCTAssertEqual(parsed.outcome, 8)
        XCTAssertNil(extractPriorityToken("Keep !6 literal").outcome)
    }

    func testBusyAllDayAbsenceConsumesCapacityButFreeBirthdayDoesNot() {
        XCTAssertTrue(CalendarManager.countsAsBusy(isAllDay: true, availability: .busy, isCancelled: false, hasDeclined: false))
        XCTAssertTrue(CalendarManager.countsAsBusy(isAllDay: true, availability: .unavailable, isCancelled: false, hasDeclined: false))
        XCTAssertFalse(CalendarManager.countsAsBusy(isAllDay: true, availability: .free, isCancelled: false, hasDeclined: false))
        XCTAssertFalse(CalendarManager.countsAsBusy(isAllDay: true, availability: .notSupported, isCancelled: false, hasDeclined: false))
        XCTAssertFalse(CalendarManager.countsAsBusy(isAllDay: true, availability: .busy, isCancelled: true, hasDeclined: false))
        let absence = Forecast.Interval(start: date(6), end: date(9))
        let result = calculate(days: [
            .init(date: date(), meetings: [absence], habits: []),
            .init(date: date(8), meetings: [absence], habits: [])
        ], tasks: [.init(id: "task", estimatedMinutes: 60)])
        XCTAssertEqual(result.days.map { $0.capacity.meetingMinutes }, [960, 960])
        XCTAssertEqual(result.days.map { $0.remainingWorkMinutes }, [0, 0])
        XCTAssertEqual(result.tasks[0].unallocatedMinutes, 60)
    }

    func testReviewedForecastAccountIsForwardedToDeferredWriter() {
        let account = ForecastWriteAccount(id: "reviewer-a")
        var writtenAccount: String?
        var pending: ((Bool) -> Void)?
        var outcome: Bool?
        account.perform(currentAccount: { "reviewer-a" }, writer: { expectedAccount, completed in
            writtenAccount = expectedAccount
            pending = completed
        }, completion: { outcome = $0 })
        XCTAssertEqual(writtenAccount, "reviewer-a")
        XCTAssertNil(outcome)
        pending?(true)
        XCTAssertEqual(outcome, true)
    }

    func testSharedProjectReviewCannotStartWritingAsAnotherAccount() {
        let reviewed = ForecastWriteAccount(id: "reviewer-a")
        var writes = 0
        var outcome: Bool?
        // Both accounts may have permission to the same project; identity still must match review.
        reviewed.perform(currentAccount: { "reviewer-b" }, writer: { _, completed in
            writes += 1
            completed(true)
        }, completion: { outcome = $0 })
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(outcome, false)
    }

    func testAccountSwitchDuringDateWriteRejectsCompletionAndFollowingWrites() {
        let reviewed = ForecastWriteAccount(id: "reviewer-a")
        var currentAccount: String? = "reviewer-a"
        var pending: ((Bool) -> Void)?
        var writes = 0
        var outcome: Bool?
        reviewed.perform(currentAccount: { currentAccount }, writer: { expectedAccount, completed in
            XCTAssertEqual(expectedAccount, "reviewer-a")
            writes += 1
            pending = completed
        }, completion: { success in
            outcome = success
            if success { writes += 1 }
        })
        currentAccount = "reviewer-b"
        pending?(true)
        XCTAssertEqual(outcome, false)
        XCTAssertEqual(writes, 1)
    }

    func testSignOutDuringDateWriteRejectsCompletion() {
        let reviewed = ForecastWriteAccount(id: "reviewer-a")
        var currentAccount: String? = "reviewer-a"
        var pending: ((Bool) -> Void)?
        var outcome: Bool?
        reviewed.perform(currentAccount: { currentAccount }, writer: { _, completed in
            pending = completed
        }, completion: { outcome = $0 })
        currentAccount = nil
        pending?(true)
        XCTAssertEqual(outcome, false)
    }

    func testUnidentifiedAndFailedForecastWritesNeverReportSuccess() {
        var writes = 0
        ForecastWriteAccount(id: "").perform(currentAccount: { "" }, writer: { _, completed in
            writes += 1
            completed(true)
        }, completion: { XCTAssertFalse($0) })
        XCTAssertEqual(writes, 0)
        ForecastWriteAccount(id: "reviewer-a").perform(currentAccount: { "reviewer-a" }, writer: { _, completed in
            writes += 1
            completed(false)
        }, completion: { XCTAssertFalse($0) })
        XCTAssertEqual(writes, 1)
    }

    // MARK: - A task dropped on a calendar event (report 2026-09-17_09-08-25)

    /// The PO's sentence, as an assertion: "if I drag a task to an event, it should be the same
    /// impact on day plan free time as if I drag it to a habit".
    func testATaskDroppedOnAnEventCostsTheDayExactlyWhatTheSameTaskOnAHabitCosts() {
        func charged(_ block: ScheduleBlock, pinnedTo key: String) -> (absorbed: Double, work: Double, free: Double) {
            let input = Forecast.DayInput.fromDayPlan(date: date(), blocks: [block])
            let result = calculate(days: [input], tasks: [.init(id: "t", estimatedMinutes: 30,
                blockAssignment: .init(date: date(), blockKey: key))])
            return (result.days[0].absorbedBlockMinutes, result.days[0].allocatedWorkMinutes,
                    result.days[0].remainingWorkMinutes)
        }
        let onEvent = charged(ScheduleBlock(kind: .meeting, title: "📅 Standup", start: date(hour: 9),
                                            end: date(hour: 10), eventID: "standup"),
                              pinnedTo: DayPlanBlockKey.event(id: "standup"))
        let onHabit = charged(ScheduleBlock(kind: .habit, title: "Study", start: date(hour: 9), end: date(hour: 10)),
                              pinnedTo: DayPlanBlockKey.habit(named: "Study"))
        XCTAssertEqual(onEvent.absorbed, 30)
        XCTAssertEqual(onEvent.work, 0)
        XCTAssertEqual(onEvent.absorbed, onHabit.absorbed)
        XCTAssertEqual(onEvent.work, onHabit.work)
        XCTAssertEqual(onEvent.free, onHabit.free)
    }

    func testAnEventAbsorbsUpToItsOwnLengthAndTheDayPaysOnlyForTheOverrun() {
        let event = ScheduleBlock(kind: .meeting, title: "📅 Review", start: date(hour: 9),
                                  end: date(hour: 9, minute: 20), eventID: "review")
        let input = Forecast.DayInput.fromDayPlan(date: date(), blocks: [event])
        func day(taskMinutes: Double) -> Forecast.Day {
            calculate(days: [input], tasks: [.init(id: "t", estimatedMinutes: taskMinutes,
                blockAssignment: .init(date: date(), blockKey: DayPlanBlockKey.event(id: "review")))]).days[0]
        }
        let fits = day(taskMinutes: 12)
        XCTAssertEqual(fits.absorbedBlockMinutes, 12)
        XCTAssertEqual(fits.allocatedWorkMinutes, 0, "a task that fits inside its event costs the day nothing")
        let overruns = day(taskMinutes: 35)
        XCTAssertEqual(overruns.absorbedBlockMinutes, 20)
        XCTAssertEqual(overruns.allocatedWorkMinutes, 15, "only the overrun is charged")
    }

    func testBackToBackEventsKeepSeparateBudgetsAndAnOverlappingOneOnlyItsOwnNewMinutes() {
        let first = ScheduleBlock(kind: .meeting, title: "📅 One", start: date(hour: 9), end: date(hour: 10), eventID: "one")
        let second = ScheduleBlock(kind: .meeting, title: "📅 Two", start: date(hour: 10), end: date(hour: 11), eventID: "two")
        let backToBack = calculate(days: [.fromDayPlan(date: date(), blocks: [first, second])], tasks: [
            .init(id: "a", estimatedMinutes: 60, blockAssignment: .init(date: date(), blockKey: DayPlanBlockKey.event(id: "one"))),
            .init(id: "b", estimatedMinutes: 60, blockAssignment: .init(date: date(), blockKey: DayPlanBlockKey.event(id: "two")))]).days[0]
        XCTAssertEqual(backToBack.capacity.meetingMinutes, 120)
        XCTAssertEqual(backToBack.absorbedBlockMinutes, 120, "neither event may spend the other's hour")
        XCTAssertEqual(backToBack.allocatedWorkMinutes, 0)
        // An overlapping second event owns only the half-hour the first one does not.
        let overlapping = ScheduleBlock(kind: .meeting, title: "📅 Overlap", start: date(hour: 9, minute: 30),
                                        end: date(hour: 10, minute: 30), eventID: "overlap")
        let shared = calculate(days: [.fromDayPlan(date: date(), blocks: [first, overlapping])],
            tasks: [.init(id: "b", estimatedMinutes: 60,
                          blockAssignment: .init(date: date(), blockKey: DayPlanBlockKey.event(id: "overlap")))]).days[0]
        XCTAssertEqual(shared.capacity.meetingMinutes, 90, "the same 90 minutes the union always charged")
        XCTAssertEqual(shared.absorbedBlockMinutes, 30)
        XCTAssertEqual(shared.allocatedWorkMinutes, 30)
    }

    func testAnAllDayEventAbsorbsItsAwakeHoursAndLeavesTheDayNoWorkTime() {
        let allDay = ScheduleBlock(kind: .meeting, title: "📅 Conference", start: date(), end: date(8), eventID: "conf")
        let result = calculate(days: [.fromDayPlan(date: date(), blocks: [allDay])],
            tasks: [.init(id: "t", estimatedMinutes: 45,
                          blockAssignment: .init(date: date(), blockKey: DayPlanBlockKey.event(id: "conf")))])
        XCTAssertEqual(result.days[0].capacity.meetingMinutes, 960, "sixteen awake hours, the eight asleep excluded")
        XCTAssertEqual(result.days[0].capacity.availableWorkMinutes, 0)
        XCTAssertEqual(result.days[0].absorbedBlockMinutes, 45)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 0)
        XCTAssertEqual(result.tasks[0].unallocatedMinutes, 0, "the work happens inside the event it was pinned to")
    }

    func testDeepWorkIsNotAbsorbingTimeBecauseItIsTheDaysWorkTime() {
        XCTAssertTrue(DayPlanBlockKey.absorbs(DayPlanBlockKey.habit(named: "Study")))
        XCTAssertTrue(DayPlanBlockKey.absorbs(DayPlanBlockKey.event(id: "standup")))
        XCTAssertFalse(DayPlanBlockKey.absorbs(DayPlanBlockKey.deepWork(startingAt: date(hour: 9))))
        XCTAssertFalse(DayPlanBlockKey.absorbs(nil))
        let sprint = ScheduleBlock(kind: .deepWork, title: "Deep work", start: date(hour: 9), end: date(hour: 11))
        let input = Forecast.DayInput.fromDayPlan(date: date(), blocks: [sprint])
        XCTAssertTrue(input.blocks.isEmpty, "a deep-work block is free work time, not time already committed")
        let result = calculate(days: [input], tasks: [.init(id: "t", estimatedMinutes: 30,
            blockAssignment: .init(date: date(), blockKey: DayPlanBlockKey.deepWork(startingAt: date(hour: 9))))])
        XCTAssertEqual(result.days[0].absorbedBlockMinutes, 0)
        XCTAssertEqual(result.days[0].allocatedWorkMinutes, 30)
    }

    // MARK: - Today and tomorrow are locked in (report 2026-09-17_09-04-13)

    func testALockedDayKeepsItsOwnWorkAndOffersRoomToNothingElse() {
        XCTAssertEqual(Forecast.lockedPlanDays, 2, "today and tomorrow")
        let days = (0..<4).map { offset in
            Forecast.DayInput(date: date(7 + offset), meetings: [], habits: [],
                              isLocked: offset < Forecast.lockedPlanDays)
        }
        let result = calculate(days: days, tasks: [
            .init(id: "pinned-today", estimatedMinutes: 60, notBefore: date(7)),
            .init(id: "unplanned", estimatedMinutes: 60)])
        XCTAssertEqual(result.tasks.first { $0.task.id == "pinned-today" }?.allocations.map(\.day), [date(7)],
                       "work the user put on today still happens today")
        XCTAssertEqual(result.tasks.first { $0.task.id == "unplanned" }?.allocations.map(\.day), [date(9)],
                       "everything else starts the day after tomorrow")
        // A locked day still reports the hours it really has left — the lock is a rule about what
        // the planner may do with them, not a claim that the day is full — but the planner's own
        // "where would this go?" skips it, so the editor's default date and the row it shows agree.
        XCTAssertTrue(result.days[0].remainingWorkMinutes > 0)
        XCTAssertEqual(Forecast.firstDayWithRoom(forMinutes: 30, in: result), date(9))
        XCTAssertEqual(Forecast.availableMinutes(on: result.days[0], for: "pinned-today"), 960,
                       "the task already on today may still re-pick today")
    }

    func testWorkThatOverflowsALockedDaySpillsPastTomorrowRatherThanFillingIt() {
        let today = Forecast.DayInput(date: date(7), meetings: [interval(6, 21)], habits: [], isLocked: true)
        let tomorrow = Forecast.DayInput(date: date(8), meetings: [], habits: [], isLocked: true)
        let open = Forecast.DayInput(date: date(9), meetings: [], habits: [])
        let result = calculate(days: [today, tomorrow, open],
                               tasks: [.init(id: "t", estimatedMinutes: 90, notBefore: date(7))])
        XCTAssertEqual(result.days[0].capacity.availableWorkMinutes, 60)
        XCTAssertEqual(result.tasks[0].allocations.map(\.day), [date(7), date(9)])
        XCTAssertEqual(result.tasks[0].allocations.map(\.workMinutes), [60, 30])
        XCTAssertEqual(result.tasks[0].completionDate, date(9))
    }

    func testThePlanNeverProposesADateOnADayWhosePlanIsLockedIn() {
        let days = [Forecast.DayInput(date: date(7), meetings: [], habits: [], isLocked: true),
                    Forecast.DayInput(date: date(8), meetings: [], habits: [], isLocked: true)]
            + (2..<6).map { Forecast.DayInput(date: date(7 + $0), meetings: [], habits: []) }
        let unplanned = Forecast.calculate(days: days, projects: [.init(id: "p")],
            tasks: [.init(id: "t", projectID: "p", estimatedMinutes: 60, dueDate: date(20))], calendar: calendar)
        XCTAssertEqual(unplanned.tasks[0].completionDate, date(9))
        XCTAssertEqual(Forecast.proposeWorkPlan(unplanned, calendar: calendar)
                        .changes.first { $0.kind == .task }?.proposedDate, date(9))
        // Work already planned onto today finishes today — and produces no row at all, instead of a
        // "brought forward to today" for work that was already today's.
        let pinned = Forecast.calculate(days: days, projects: [.init(id: "p")],
            tasks: [.init(id: "t", projectID: "p", estimatedMinutes: 60, dueDate: date(20), notBefore: date(7))],
            calendar: calendar)
        XCTAssertEqual(pinned.tasks[0].completionDate, date(7))
        XCTAssertTrue(Forecast.proposeWorkPlan(pinned, calendar: calendar).changes.isEmpty)
    }

    // MARK: - …unless the user unticks the checkbox (report 2026-09-21_07-45-21)

    func testOnlyTheFirstTwoDaysOfTheHorizonAreLockedAndOnlyWhileTheUserAsksForIt() {
        for offset in 0..<4 {
            XCTAssertEqual(Forecast.isPlanLocked(date(7 + offset), horizonStart: date(7),
                                                 locksPlannedDays: true, calendar: calendar),
                           offset < Forecast.lockedPlanDays, "day \(offset) of the horizon")
            XCTAssertFalse(Forecast.isPlanLocked(date(7 + offset), horizonStart: date(7),
                                                 locksPlannedDays: false, calendar: calendar),
                           "unticked, no day is settled")
        }
        // A day before the horizon starts is not settled — it is not planned at all. `relockPlannedDays`
        // re-derives every day's flag from the earliest day it holds, and an overdue placement must
        // not become "locked" by sorting ahead of it.
        XCTAssertFalse(Forecast.isPlanLocked(date(6), horizonStart: date(7),
                                             locksPlannedDays: true, calendar: calendar))
        // Any time of day on a locked date is that date: the flag is per day, not per instant.
        XCTAssertTrue(Forecast.isPlanLocked(date(8, hour: 23), horizonStart: date(7, hour: 9),
                                            locksPlannedDays: true, calendar: calendar))
    }

    func testUnlockingTheNextTwoDaysLetsThePlannerUseThemAgain() {
        let days = (0..<4).map { Forecast.DayInput(date: date(7 + $0), meetings: [], habits: []) }
        let result = Forecast.calculate(days: days, projects: [.init(id: "p")],
            tasks: [.init(id: "t", projectID: "p", estimatedMinutes: 60, dueDate: date(20))], calendar: calendar)
        XCTAssertEqual(result.tasks[0].completionDate, date(7), "unplanned work starts today once nothing is locked")
        XCTAssertEqual(Forecast.firstDayWithRoom(forMinutes: 30, in: result), date(7))
        XCTAssertEqual(Forecast.proposeWorkPlan(result, calendar: calendar)
                        .changes.first { $0.kind == .task }?.proposedDate, date(7),
                       "and the plan may now name today")
    }

    /// The reason the lock was worth having does not go away when it is turned off, so the cheap half
    /// of it is kept unconditionally: a proposal that names the date the task already has is not a
    /// change and is never listed, locked or not. What unticking DOES reintroduce is a row for work
    /// planned onto today whose deadline is some other day — that one is a real date change, and the
    /// user who unticked the box asked to see it.
    func testANoOpProposalIsStillFilteredWithTheLockOff() {
        let days = (0..<3).map { Forecast.DayInput(date: date(7 + $0), meetings: [], habits: []) }
        let sameDate = Forecast.calculate(days: days, projects: [.init(id: "p")],
            tasks: [.init(id: "t", projectID: "p", estimatedMinutes: 60, dueDate: date(7), notBefore: date(7))],
            calendar: calendar)
        XCTAssertEqual(sameDate.tasks[0].completionDate, date(7))
        // Tasks only: the project itself has no end date at all, and being given a first one is a
        // proposal in its own right rather than a no-op this filter is about.
        XCTAssertTrue(Forecast.proposeWorkPlan(sameDate, calendar: calendar)
                        .changes.filter { $0.kind == .task }.isEmpty,
                      "due today and finishing today is not a change to review")
        let laterDeadline = Forecast.calculate(days: days, projects: [.init(id: "p")],
            tasks: [.init(id: "t", projectID: "p", estimatedMinutes: 60, dueDate: date(20), notBefore: date(7))],
            calendar: calendar)
        XCTAssertEqual(Forecast.proposeWorkPlan(laterDeadline, calendar: calendar)
                        .changes.first { $0.kind == .task }?.proposedDate, date(7))
    }

    /// "Monday and Tuesday are 1h over buffer — it didn't suggest rescheduling those tasks."
    func testADayTheUsersOwnPlanOverfillsReadsAsOverAndItsOverflowIsProposedForALaterDay() {
        let monday = Forecast.DayInput(date: date(21), meetings: [interval(6, 21, day: 21)], habits: [])
        let tuesday = Forecast.DayInput(date: date(22), meetings: [], habits: [])
        let result = Forecast.calculate(days: [monday, tuesday], projects: [.init(id: "p")], tasks: [
            .init(id: "a", projectID: "p", estimatedMinutes: 60, dueDate: date(30), notBefore: date(21)),
            .init(id: "b", projectID: "p", estimatedMinutes: 30, dueDate: date(30), notBefore: date(21))],
            calendar: calendar)
        let load = Forecast.dayLoad(on: date(21), forecast: result, calendar: calendar)
        XCTAssertEqual(load?.capacityMinutes, 60)
        XCTAssertEqual(load?.committedMinutes, 90)
        XCTAssertEqual(load?.overcommittedMinutes, 30)
        XCTAssertEqual(Forecast.proposeWorkPlan(result, calendar: calendar)
                        .changes.first { $0.itemID == "b" }?.proposedDate, date(22))
    }

    // MARK: Applying a proposal moves the Day Plan, not just the deadline
    //
    // "It still didn't reschedule Monday for me - it didn't suggest moving any of these tasks"
    // (report 2026-09-17_09-04-13, follow-up). The rows above WERE produced and could be applied;
    // what the apply path wrote was a due date, which moves nothing the user can see.

    /// The whole point: a proposal that sends an over-committed Monday's overflow to Tuesday has to
    /// take the Day Plan placement with it, or Monday is exactly as over-committed afterwards.
    func testApplyingTheOverflowsNewDateMovesItOffTheDayThePlanSaidWasOver() throws {
        let monday = Forecast.DayInput(date: date(21), meetings: [interval(6, 21, day: 21)], habits: [])
        let tuesday = Forecast.DayInput(date: date(22), meetings: [], habits: [])
        let result = Forecast.calculate(days: [monday, tuesday], projects: [.init(id: "p")], tasks: [
            .init(id: "a", projectID: "p", estimatedMinutes: 60, dueDate: date(30), notBefore: date(21)),
            .init(id: "b", projectID: "p", estimatedMinutes: 30, dueDate: date(30), notBefore: date(21))],
            calendar: calendar)
        let proposed = try XCTUnwrap(Forecast.proposeWorkPlan(result, calendar: calendar)
                                        .changes.first { $0.itemID == "b" }?.proposedDate)
        XCTAssertEqual(DayPlanRepositioning.move(taskID: "b", plannedOn: date(21), proposedDate: proposed,
                                                 today: date(17), lockedDays: [date(17), date(18)],
                                                 calendar: calendar),
                       .init(taskID: "b", from: date(21), to: date(22)),
                       "The task leaves Monday, which is the only thing that empties Monday")
    }

    func testATaskThatStaysWhereItIsMovesNothing() {
        XCTAssertNil(DayPlanRepositioning.move(taskID: "a", plannedOn: date(21), proposedDate: date(21),
                                               today: date(17), lockedDays: [], calendar: calendar),
                     "A proposal naming the day the task is already on is not a move")
        XCTAssertNil(DayPlanRepositioning.move(taskID: "a", plannedOn: nil, proposedDate: date(22),
                                               today: date(17), lockedDays: [], calendar: calendar),
                     "A task the user never placed has no placement to move")
    }

    /// A placement on a day that has gone is history. `rollOverIfNeeded` owns those, and re-dating
    /// months of past placements would be a fiction of a different kind.
    func testAPlacementInThePastIsLeftAlone() {
        XCTAssertNil(DayPlanRepositioning.move(taskID: "a", plannedOn: date(10), proposedDate: date(22),
                                               today: date(17), lockedDays: [], calendar: calendar))
    }

    /// The lock has to mean the same thing whoever chose the date. `proposeWorkPlan` never names a
    /// locked day, but a hand-typed date bypasses that check and would otherwise drop work straight
    /// onto the two days the plan is not allowed to touch.
    func testNothingIsEverMovedOntoALockedDayOrIntoThePast() {
        XCTAssertNil(DayPlanRepositioning.move(taskID: "a", plannedOn: date(21), proposedDate: date(18),
                                               today: date(17), lockedDays: [date(17), date(18)],
                                               calendar: calendar),
                     "Tomorrow is locked in, even when the user types it")
        XCTAssertNil(DayPlanRepositioning.move(taskID: "a", plannedOn: date(21), proposedDate: date(10),
                                               today: date(17), lockedDays: [], calendar: calendar),
                     "A day that has gone is not somewhere work can be planned")
        XCTAssertEqual(DayPlanRepositioning.move(taskID: "a", plannedOn: date(21), proposedDate: date(19),
                                                 today: date(17), lockedDays: [date(17), date(18)],
                                                 calendar: calendar),
                       .init(taskID: "a", from: date(21), to: date(19)),
                       "The first day past the lock is fair game, earlier or later")
    }

    /// Times of day do not decide a placement — the Day Plan is keyed by day.
    func testTheMoveIsMeasuredInWholeDays() {
        XCTAssertNil(DayPlanRepositioning.move(taskID: "a", plannedOn: date(21, hour: 9),
                                               proposedDate: date(21, hour: 17), today: date(17, hour: 23),
                                               lockedDays: [], calendar: calendar),
                     "Same day, different clock, no move")
    }

    func testThePortfolioForecastUsesDueDateAndIgnoresConflictingPlacements() throws {
        let rows = try ["future", "stale", "boxed"].map {
            try remoteTask(["id": $0, "project_id": "p", "duration": 1800,
                            "due_date": $0 == "stale" ? "2026-09-02" : "2026-09-09"])
        }
        let planned: [(date: Date, task: DayPlanTask)] = [
            (date(9), DayPlanTask(title: "Future", durationMinutes: 30, sourceTaskId: "future")),
            (date(2), DayPlanTask(title: "Stale", durationMinutes: 30, sourceTaskId: "stale")),
            (date(9), DayPlanTask(title: "Boxed", durationMinutes: 30, sourceTaskId: "boxed",
                                  blockKey: DayPlanBlockKey.event(id: "standup")))]
        let tasks = LocalForecastSnapshot.projectTasks(remote: rows, projects: [Project(id: "p", name: "P")],
            planned: planned, today: date(7), calendar: calendar, serverExcludedCompleted: true)
        XCTAssertEqual(tasks.first { $0.id == "future" }?.notBefore, date(9))
        XCTAssertEqual(tasks.first { $0.id == "stale" }?.notBefore, date(7),
                       "Overdue work belongs on today regardless of its cached placement")
        XCTAssertEqual(tasks.first { $0.id == "boxed" }?.blockAssignment,
                       .init(date: date(9), blockKey: DayPlanBlockKey.event(id: "standup")))
    }

    func testReprioritisingUsesPlacedDurationsToClearTheDayPlanShortfall() throws {
        let lengths = [5, 15, 15]
        let rows = try lengths.indices.map { index in
            try remoteTask(["id": "task-\(index)", "project_id": "p", "duration": 0,
                            "perspiration_level": 1, "outcome": 2, "due_date": "2026-09-21"])
        }
        let placed = lengths.indices.map { index in
            (date: date(21), task: DayPlanTask(title: "Task", durationMinutes: lengths[index],
                                              sourceTaskId: "task-\(index)"))
        }
        let inputs = LocalForecastSnapshot.projectTasks(remote: rows, projects: [Project(id: "p", name: "P")],
            planned: placed, today: date(18), calendar: calendar, serverExcludedCompleted: true)
        XCTAssertEqual(inputs.compactMap(\.estimatedMinutes), [5, 15, 15])
        let result = calculate(days: [day(21, workMinutes: 10), day(22, workMinutes: 60)],
                               projects: [.init(id: "p", outcome: 0)], tasks: inputs)
        let changes = Forecast.proposeWorkPlan(result, calendar: calendar).changes.filter { $0.kind == .task }
        let movedIDs = Set(changes.filter { $0.proposedDate > date(21) }.map(\.itemID))
        let remaining = placed.filter { !movedIDs.contains($0.task.sourceTaskId!) }
            .reduce(0) { $0 + $1.task.durationMinutes }
        XCTAssertLessThanOrEqual(remaining, 10, "Applying every offered move must clear the 25-minute shortfall")
    }

    func testAmbiguousLocalProjectNameDoesNotAssignAnArbitraryProject() {
        let local = DayPlanTask(title: "Task", project: "shared name")
        let projects = [Project(id: "a", name: "Shared name"), Project(id: "b", name: "Shared Name")]
        let result = LocalForecastSnapshot.tasks(remote: [], local: [(date: date(), task: local)],
                                                projects: projects, today: date(), calendar: calendar)
        XCTAssertNil(result.first?.projectID)
    }

}
