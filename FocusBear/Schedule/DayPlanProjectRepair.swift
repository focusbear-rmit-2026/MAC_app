//
//  DayPlanProjectRepair.swift
//  Focus Bear
//
//  Repairs Day Plan tasks whose `#project` only ever existed on this Mac. Before #2392 a project typed
//  in the Day Plan stayed in local UserDefaults — no backend project was created and the backing
//  to-do's `project_id` was never set — so it was invisible on web and mobile. The same happens going
//  forward whenever a project push fails (offline, token not ready). `DayPlanProjectSyncRules` is the
//  pure, unit-tested part (which tasks need repair, name dedupe, throttling, tag mirroring);
//  `DayPlanProjectRepair` drives it against `DayPlanTaskStore` and `DayPlanSync`.
//

import Foundation

/// Pure rules behind the project repair pass — no I/O, see `DayPlanProjectRepairTests`.
enum DayPlanProjectSyncRules {
    /// A task needing repair, with the `yyyy-MM-dd` day it is stored under.
    struct Candidate: Equatable {
        let dayKey: String
        let task: DayPlanTask
    }

    /// Minimum gap between two repair passes.
    static let minimumInterval: TimeInterval = 10 * 60

    /// A task needs repair when it names a project but its backing to-do isn't known to point at a
    /// project that exists on the backend. A task without a to-do can't be repaired here (the mint path
    /// pushes its project once it has one); an externally synced to-do's project belongs to ClickUp /
    /// Trello, and the backend nulls `project_id` for those anyway.
    ///
    /// A link to a project the user DELETED is not local-only either. The backend soft-deletes, so the
    /// to-do keeps its `project_id` and project tag, `GET /projects` stops returning the id, and this
    /// rule would otherwise re-create the project ten seconds after the delete (#2680).
    static func needsRepair(_ task: DayPlanTask, remoteProjectIDs: Set<String>,
                            deletedProjectIDs: Set<String> = []) -> Bool {
        guard task.sourceTaskId != nil,
              let project = task.project, !project.trimmingCharacters(in: .whitespaces).isEmpty,
              task.hasSyncedExternalProject != true else { return false }
        guard let linkedID = task.projectID else { return true }
        return !remoteProjectIDs.contains(linkedID) && !deletedProjectIDs.contains(linkedID)
    }

    /// Takes a deleted project off every Day Plan task that still names it — by its id, or by name for
    /// a task that was never linked — so the task stops being grouped under it and stops asking the
    /// repair pass to create it again (#2680). A task linked to a DIFFERENT project that happens to
    /// share the name is left alone: that project still exists. ClickUp/Trello projects are not ours
    /// to delete, so those tasks are untouched too.
    static func followingDeletion(_ tasksByDay: [String: [DayPlanTask]], projectID: String,
                                  name: String) -> [String: [DayPlanTask]] {
        let deletedName = name.trimmingCharacters(in: .whitespaces)
        return tasksByDay.mapValues { tasks in
            tasks.map { task -> DayPlanTask in
                guard task.hasSyncedExternalProject != true,
                      names(task, deletedProjectID: projectID, deletedName: deletedName) else { return task }
                var cleared = task
                cleared.project = nil
                cleared.projectID = nil
                cleared.tags = task.tags?.filter { $0.id != projectID }
                return cleared
            }
        }
    }

    private static func names(_ task: DayPlanTask, deletedProjectID: String, deletedName: String) -> Bool {
        if let linkedID = task.projectID { return linkedID == deletedProjectID }
        guard !deletedName.isEmpty, let named = task.project?.trimmingCharacters(in: .whitespaces) else { return false }
        return named.caseInsensitiveCompare(deletedName) == .orderedSame
    }

    /// Follows a finished project merge into the Day Plan's own copy of the data.
    ///
    /// The merge moves the backing to-dos on the server and then archives the emptied source, but a
    /// Day Plan task stores its project as a NAME, not an id. `GET /projects` defaults to active
    /// only, so a task still naming the archived source misses the name lookup on its next sync and
    /// `POST /projects` creates that project again — which is how merging one duplicate produces an
    /// endless supply of archived ones (report 2026-09-18_21-46-48: three archived "Classroom mode").
    /// Rewriting the name is what stops the next sync asking for it.
    ///
    /// A to-do whose project belongs to ClickUp/Trello is left alone; the merge did not move it
    /// either. Matching is case-insensitive on the trimmed name, the same comparison the name lookup
    /// (`remoteProjectID(named:)`) uses to decide the project already exists.
    static func followingMerge(_ tasksByDay: [String: [DayPlanTask]], from source: String,
                               to target: String, targetID: String?) -> [String: [DayPlanTask]] {
        let wanted = source.trimmingCharacters(in: .whitespaces)
        guard !wanted.isEmpty, wanted.caseInsensitiveCompare(target.trimmingCharacters(in: .whitespaces)) != .orderedSame
        else { return tasksByDay }
        return tasksByDay.mapValues { tasks in
            tasks.map { task -> DayPlanTask in
                guard task.hasSyncedExternalProject != true,
                      let name = task.project?.trimmingCharacters(in: .whitespaces),
                      name.caseInsensitiveCompare(wanted) == .orderedSame else { return task }
                var moved = task
                moved.project = target
                moved.projectID = targetID
                if let tags = task.tags {
                    // `ensureProjectTag` can only drop a tag matching the id it is given, so the
                    // retired project's own tag has to go explicitly — otherwise the web keeps
                    // showing the merged-away project beside the one it was merged into.
                    let withoutSource = tags.filter { $0.id != task.projectID }
                    moved.tags = ensureProjectTag(withoutSource, projectID: targetID, projectName: target)
                }
                return moved
            }
        }
    }

    /// Every task needing repair, by day then stored order, so passes are predictable.
    static func candidates(in tasksByDay: [String: [DayPlanTask]], remoteProjectIDs: Set<String>,
                           deletedProjectIDs: Set<String> = []) -> [Candidate] {
        tasksByDay.keys.sorted().flatMap { day -> [Candidate] in
            (tasksByDay[day] ?? [])
                .filter { needsRepair($0, remoteProjectIDs: remoteProjectIDs, deletedProjectIDs: deletedProjectIDs) }
                .map { Candidate(dayKey: day, task: $0) }
        }
    }

    /// Candidates whose to-do can be PUT (quadrant known — the upsert requires it and would otherwise
    /// clobber it) versus those whose project can only be created, not linked, until a hydrate backfills
    /// the quadrant.
    static func split(_ candidates: [Candidate]) -> (linkable: [Candidate], missingQuadrant: [Candidate]) {
        (candidates.filter { $0.task.eisenhowerQuadrant != nil },
         candidates.filter { $0.task.eisenhowerQuadrant == nil })
    }

    /// Distinct project names across the candidates, case-insensitively, keeping the first-seen casing
    /// and order — so ten tasks tagged `#thesis` / `#Thesis` create ONE project.
    static func distinctProjectNames(_ candidates: [Candidate]) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for candidate in candidates {
            guard let name = candidate.task.project?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { continue }
            if seen.insert(name.lowercased()).inserted { names.append(name) }
        }
        return names
    }

    /// Whether a pass may run now: never more than once per `minimumInterval` (nil = never ran).
    static func isDue(now: Date, lastRun: Date?, minimumInterval: TimeInterval = minimumInterval) -> Bool {
        guard let lastRun = lastRun else { return true }
        return now.timeIntervalSince(lastRun) >= minimumInterval
    }

    /// The tag list a project link sends, mirroring the web dashboard's `ensureProjectTaskTags`: the
    /// to-do's label tags plus exactly one `{ id: projectID, text: projectName }` tag. With no
    /// `projectID` (clearing) the labels are returned as they are.
    static func ensureProjectTag(_ tags: [DayPlanTaskTag], projectID: String?, projectName: String?) -> [DayPlanTaskTag] {
        guard let projectID = projectID else { return tags }
        let labels = tags.filter { $0.id != projectID }
        return labels + [DayPlanTaskTag(id: projectID, text: projectName ?? "")]
    }
}

/// Why a repair pass was asked for (only reported in the log line).
enum DayPlanProjectRepairTrigger: String {
    case launch
    case projectsLoaded
    case dayPlanBuild
}

/// Drives `DayPlanProjectSyncRules` against the live store: finds tasks whose project never reached
/// the backend, creates each distinct project once, then links every to-do through the same
/// `DayPlanTaskStore.syncProject(of:)` route a user edit takes. Runs after launch/login, after each
/// successful projects fetch and after each Day Plan build — at most once per 10 minutes, and only when
/// there is something to repair.
final class DayPlanProjectRepair {
    static let shared = DayPlanProjectRepair()
    private init() {}

    private let lastRunKey = "dayPlanProjectRepairLastRun"
    /// Lets the app settle (credentials, first fetches) before the launch pass touches the API.
    private static let launchDelaySeconds: TimeInterval = 20
    private var isRunning = false

    private var lastRun: Date? {
        get { UserDefaults.standard.object(forKey: lastRunKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastRunKey) }
    }

    /// Launch / login hook (AppDelegate, once credentials are in).
    func scheduleAfterLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.launchDelaySeconds) { [weak self] in
            self?.runIfDue(trigger: .launch)
        }
    }

    /// Run a pass if there is anything to repair and the throttle allows. Safe to call generously
    /// (every Day Plan build): with nothing to do it is a cheap scan and no network. Fetches the
    /// projects list first when it hasn't loaded — until then a local name can't be told apart from a
    /// real project that merely hasn't loaded, and creating it would duplicate that project.
    func runIfDue(trigger: DayPlanProjectRepairTrigger) {
        guard !DayPlanTaskStore.mockMode, DayPlanSync.shared.isAuthed else { return }
        // Shares these triggers rather than adding another launch hook. Deliberately above the
        // project-sync guards below, so it is not gated on unrelated repair candidates. It carries
        // its own one-shot marker and returns before any network once this account has been swept.
        TodoColumnRepair.shared.runIfNeeded()
        guard !isRunning else { return }
        let store = DayPlanTaskStore.shared
        let knownProjectIDs = store.remoteProjectsLoaded ? store.remoteProjectIDs : []
        guard !DayPlanProjectSyncRules.candidates(in: store.tasksByDay, remoteProjectIDs: knownProjectIDs,
                                                  deletedProjectIDs: store.deletedProjectIDs).isEmpty,
              DayPlanProjectSyncRules.isDue(now: Date(), lastRun: lastRun) else { return }
        lastRun = Date()
        isRunning = true
        if store.remoteProjectsLoaded {
            run(trigger: trigger)
        } else {
            store.refreshRemoteProjects { [weak self] loaded in
                if loaded { self?.run(trigger: trigger) } else { self?.isRunning = false }
            }
        }
    }

    private func run(trigger: DayPlanProjectRepairTrigger) {
        let store = DayPlanTaskStore.shared
        let candidates = DayPlanProjectSyncRules.candidates(in: store.tasksByDay, remoteProjectIDs: store.remoteProjectIDs,
                                                            deletedProjectIDs: store.deletedProjectIDs)
        guard !candidates.isEmpty else { isRunning = false; return }
        let (linkable, missingQuadrant) = DayPlanProjectSyncRules.split(candidates)
        let names = DayPlanProjectSyncRules.distinctProjectNames(candidates)
        let knownBefore = store.remoteProjectIDs
        var created = 0, projectFailures = 0, linked = 0, linkFailures = 0
        let group = DispatchGroup()
        // 1. Every distinct name → one backend project (looked up, else created once).
        for name in names {
            group.enter()
            DayPlanSync.shared.ensureProjectSynced(named: name) { projectID in
                if let projectID = projectID {
                    if !knownBefore.contains(projectID) { created += 1 }
                } else {
                    projectFailures += 1
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            // 2. Point each to-do at its (now cached) project — the same route a user edit takes, so the
            //    link is recorded on the task and it drops out of the next scan.
            for candidate in linkable {
                group.enter()
                store.syncProject(of: candidate.task) { succeeded in
                    if succeeded { linked += 1 } else { linkFailures += 1 }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                addLog(text: "DayPlanProjectRepair(\(trigger.rawValue)): \(candidates.count) task(s) with a local-only project "
                    + "across \(names.count) project name(s) — projects created \(created), failed \(projectFailures); "
                    + "to-dos linked \(linked), failed \(linkFailures), skipped \(missingQuadrant.count) (no quadrant yet)")
                self?.isRunning = false
            }
        }
    }
}

// MARK: - One-off column repair for already-completed to-dos

/// Pure rules behind the one-off column repair — no I/O, see `TodoColumnRepairTests`.
///
/// Before this change, completing a task from the Day Plan, the To-do list, the routine player or
/// another device set `status: COMPLETED` and left `custom_status_id` on whatever open column the
/// task was in. Those rows still read as outstanding on the kanban, on web, on mobile and to the
/// server's own `exclude_completed` (report 2026-09-15_17-41-45). The forward fix stops new ones
/// being made; these rules find the ones already stored so they can be filed where they belong.
///
/// **`status` is the only evidence of completion here.** Completion is never inferred from a
/// column — that inference is the bug this whole change exists to remove — so a row is a candidate
/// only when the backend itself says `COMPLETED`.
enum TodoColumnRepairRules {
    /// Bump to re-run the sweep after changing these rules. Stored per account, so a repaired
    /// account is never swept twice and a deliberate re-run is one number away.
    ///
    /// v2: v1 read completed to-dos newest-first and stopped at 500 rows of 4,596. Due-date order put
    /// 500 project-less rows on the front, so it found nothing, reported `noColumn=500` and stored its
    /// marker — on an account with 47 rows to repair. v2 reads the far smaller corpus that actually
    /// contains them and refuses to record a truncated pass as complete.
    static let schemaVersion = 2

    /// One row to move, and where.
    struct Repair: Equatable {
        let taskID: String
        let projectID: String
        let fromColumnID: String
        let toColumnID: String
    }

    /// A row left alone, and why. Every skip is logged: silence is what let this go unnoticed.
    struct Skip: Equatable {
        enum Reason: String {
            case notCompleted            // status is not COMPLETED — never infer completion from a column
            case noColumn                // custom_status_id came back null: `status` alone already reads correctly
            case noProject               // not in a native project
            case projectNotLoaded        // its project's columns were not available
            case columnUnknown           // custom_status_id names no column of that project
            case columnAlreadyCompletes  // correctly filed already
            case projectHasNoDoneColumn  // nowhere better to put it
        }
        let taskID: String
        let reason: Reason
    }

    /// Split `tasks` into the rows that are unambiguously mis-filed and the rows to leave alone.
    static func plan(tasks: [ToDoTask],
                     columnsByProject: [String: [ProjectCustomStatus]]) -> (repairs: [Repair], skips: [Skip]) {
        var repairs: [Repair] = []
        var skips: [Skip] = []
        for task in tasks where !task.id.isEmpty {
            func skip(_ reason: Skip.Reason) { skips.append(Skip(taskID: task.id, reason: reason)) }
            guard task.isCompleted else { skip(.notCompleted); continue }
            guard let columnID = task.custom_status_id, !columnID.isEmpty else { skip(.noColumn); continue }
            guard let projectID = task.project_id, !projectID.isEmpty else { skip(.noProject); continue }
            guard let columns = columnsByProject[projectID] else { skip(.projectNotLoaded); continue }
            guard let current = columns.first(where: { $0.id == columnID }) else { skip(.columnUnknown); continue }
            guard !(current.should_complete_task ?? false) else { skip(.columnAlreadyCompletes); continue }
            let ordered = columns.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            guard let target = ordered.first(where: { $0.should_complete_task ?? false }) else {
                skip(.projectHasNoDoneColumn); continue
            }
            repairs.append(Repair(taskID: task.id, projectID: projectID,
                                  fromColumnID: columnID, toColumnID: target.id))
        }
        return (repairs, skips)
    }

    static func summary(_ skips: [Skip]) -> String {
        Dictionary(grouping: skips, by: \.reason)
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.rawValue)=\($0.value.count)" }
            .joined(separator: " ")
    }
}

/// Drives `TodoColumnRepairRules` against the backend, ONCE per account.
///
/// Wired into `DayPlanProjectRepair.runIfDue(trigger:)` with the product owner's direct
/// go-ahead ("yes wire up the change"), after it was first shipped deliberately inert.
///
/// This performs a one-off correction of data the app did not create, with the product owner's
/// explicit approval ("happy for it to fix my data", follow-up to report 2026-09-15_17-41-45). It is
/// not a general migration: it moves a to-do the backend already calls `COMPLETED` out of an open
/// column and into its project's done column, and touches nothing else. Every row it changes and
/// every row it declines to change is written to the debug log.
///
/// Safety properties, in order of importance:
/// - `status: COMPLETED` is the only completion evidence; a column never implies completion.
/// - A row it cannot reason about (unknown column, unloaded project, no done column) is skipped.
/// - Writes go through `DayPlanSync.setTodoStatus`, the same single PUT the forward fix uses.
/// - Writes are spaced, so a large backlog cannot become a burst.
/// - The version marker is stored only after a complete pass, so an interrupted sweep resumes.
/// - Re-running on repaired data plans zero writes: a moved row's column now completes.
final class TodoColumnRepair {
    static let shared = TodoColumnRepair()
    private init() {}

    /// Most pages the scan will read, against a corpus of roughly five.
    ///
    /// Rows come from `ToDoListQuery.forecast` — the SAME query the forecast uses,
    /// `exclude_completed=true` — and not from `status=COMPLETED`. A row needing repair is one the
    /// backend calls COMPLETED that sits in a non-completing column, and that is exactly the
    /// condition which makes the server's column-first `exclude_completed` hand it back as
    /// unfinished. Every candidate is therefore in this corpus by construction, and the corpus is
    /// two orders of magnitude smaller: 205 rows against 4,596 on the account this was measured on,
    /// with both queries agreeing on the same 47 repairs.
    ///
    /// If the backend ever resolves completion status-first (backend#2407) this query stops
    /// returning them and the sweep finds nothing — the right answer by then, because every client
    /// reads the rows correctly at that point and there is nothing user-visible left to repair. An
    /// old server that ignores the flag returns everything, which this selection also handles.
    ///
    /// Hitting this cap means something changed, so such a pass is explicitly NOT recorded as
    /// complete: a truncated scan cannot prove there is nothing left.
    private static let maximumPages = 40
    /// Gap between two PUTs, so a backlog trickles instead of bursting.
    private static let writeSpacingSeconds: TimeInterval = 0.4
    private var isRunning = false

    private func versionKey(_ account: String) -> String { "todoColumnRepair.version." + account }
    private func completedVersion(_ account: String) -> Int {
        UserDefaults.standard.integer(forKey: versionKey(account))
    }

    /// Runs at most one full pass per account per schema version. Cheap to call generously: with the
    /// marker already stored it returns before any network.
    func runIfNeeded() {
        let account = appdelegate?.user?.userId ?? ""
        guard !isRunning, !DayPlanTaskStore.mockMode, DayPlanSync.shared.isAuthed, !account.isEmpty,
              completedVersion(account) < TodoColumnRepairRules.schemaVersion else { return }
        isRunning = true
        let store = DayPlanTaskStore.shared
        if store.remoteProjectsLoaded, !store.customStatusesByProject.isEmpty {
            scan(account: account)
        } else {
            store.refreshRemoteProjects { [weak self] loaded in
                guard let self = self else { return }
                guard loaded else {
                    addLog(text: "TodoColumnRepair: skipped — projects could not be loaded; will retry next launch")
                    self.isRunning = false
                    return
                }
                self.scan(account: account)
            }
        }
    }

    /// How many rows in a raw page actually carried a `custom_status_id` KEY.
    ///
    /// A key the response omits and a key that is genuinely null are identical once decoded, so a
    /// sweep that cannot see the field looks exactly like a sweep with nothing to do. That is not
    /// hypothetical: v1 reported `noColumn=500`, 0 repairs, and stored its marker. Counting key
    /// presence separately is what makes "the rows have no column" distinguishable from "this pass is
    /// blind", and a blind pass aborts instead of recording success.
    static func rowsCarryingColumnField(in data: Data) -> Int {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = root["data"] as? [[String: Any]] else { return 0 }
        return rows.filter { $0.keys.contains("custom_status_id") }.count
    }

    private func scan(account: String, page: Int = 1, collected: [ToDoTask] = [], carryingField: Int = 0) {
        let query = ToDoListQuery.forecast(page: page)
        allApiObject.getTaskSnapshotData(path: query.path, expectedAccountID: account) { [weak self] data, statusCode in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard (200..<300).contains(statusCode), let data = data,
                      let result = try? JSONDecoder().decode(ToDoPage.self, from: data) else {
                    addLog(text: "TodoColumnRepair: aborted on page \(page) (HTTP \(statusCode)) — "
                        + "the to-do read failed; marker NOT stored, will retry next launch")
                    self.isRunning = false
                    return
                }
                let rows = collected + result.data
                let carrying = carryingField + Self.rowsCarryingColumnField(in: data)
                let hasMore = result.meta?.hasNextPage == true
                guard hasMore, page < Self.maximumPages else {
                    if hasMore {
                        // A truncated scan cannot prove there is nothing left, so it must not be
                        // recorded as done — v1 did exactly that and abandoned 47 rows.
                        addLog(text: "TodoColumnRepair: stopped at the \(Self.maximumPages)-page cap with more "
                            + "pages available — this pass is incomplete and its marker will NOT be stored")
                    }
                    self.apply(rows: rows, carryingField: carrying, account: account,
                               pagesRead: page, truncated: hasMore)
                    return
                }
                self.scan(account: account, page: page + 1, collected: rows, carryingField: carrying)
            }
        }
    }

    private func apply(rows: [ToDoTask], carryingField: Int, account: String, pagesRead: Int, truncated: Bool) {
        let columns = DayPlanTaskStore.shared.customStatusesByProject
        let (repairs, skips) = TodoColumnRepairRules.plan(tasks: rows, columnsByProject: columns)
        addLog(text: "TodoColumnRepair: scanned \(rows.count) row(s) over \(pagesRead) page(s) "
            + "across \(columns.count) project(s) with columns — \(carryingField) row(s) carried a "
            + "custom_status_id field — \(repairs.count) to repair, \(skips.count) left alone "
            + "[\(TodoColumnRepairRules.summary(skips))]")
        // The blindness guard: rows came back, but not one of them carried the field this sweep is
        // entirely about. That is a broken read, not an empty result, and must never be recorded.
        guard rows.isEmpty || carryingField > 0 else {
            addLog(text: "TodoColumnRepair: ABORTED — \(rows.count) row(s) came back and none carried a "
                + "custom_status_id field, so this pass could not see what it exists to fix. "
                + "Marker NOT stored; the response shape needs checking.")
            isRunning = false
            return
        }
        guard !truncated else {
            addLog(text: "TodoColumnRepair: pass incomplete (page cap) — \(repairs.count) repair(s) identified "
                + "but the marker is NOT stored, so the next launch scans again")
            isRunning = false
            return
        }
        guard !repairs.isEmpty else {
            // Nothing to do, on a scan that reached the end and could see the field: a complete pass.
            self.finish(account: account, repaired: 0)
            return
        }
        let titles = Dictionary(rows.map { ($0.id, $0.title) }, uniquingKeysWith: { first, _ in first })
        let quadrants = Dictionary(rows.map { ($0.id, $0.eisenhower_quadrant) }, uniquingKeysWith: { first, _ in first })
        write(repairs, index: 0, titles: titles, quadrants: quadrants, account: account)
    }

    /// One spaced PUT per row, through the forward fix's own write path.
    private func write(_ repairs: [TodoColumnRepairRules.Repair], index: Int, titles: [String: String],
                       quadrants: [String: Int?], account: String) {
        guard index < repairs.count else {
            finish(account: account, repaired: repairs.count)
            return
        }
        let repair = repairs[index]
        let title = titles[repair.taskID] ?? ""
        guard !title.isEmpty else {
            // The upsert echoes the title back; without one it would clear it. Never worth the risk.
            addLog(text: "TodoColumnRepair: skipped \(repair.taskID) — no title to echo back on the upsert")
            write(repairs, index: index + 1, titles: titles, quadrants: quadrants, account: account)
            return
        }
        addLog(text: "TodoColumnRepair: moving to-do \(repair.taskID) \(LogPrivacy.text(title)) in project \(repair.projectID) "
            + "from column \(repair.fromColumnID) to \(repair.toColumnID)")
        DayPlanSync.shared.setTodoStatus(todoID: repair.taskID, title: title,
                                         quadrant: (quadrants[repair.taskID] ?? nil) ?? kDayPlanNeutralQuadrant,
                                         completed: true, column: .move(to: repair.toColumnID))
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.writeSpacingSeconds) { [weak self] in
            self?.write(repairs, index: index + 1, titles: titles, quadrants: quadrants, account: account)
        }
    }

    /// Only a pass that read the whole corpus, could see the column field, and wrote everything it
    /// planned stores the marker. Anything else retries on the next launch.
    private func finish(account: String, repaired: Int) {
        UserDefaults.standard.set(TodoColumnRepairRules.schemaVersion, forKey: versionKey(account))
        addLog(text: "TodoColumnRepair: pass complete — \(repaired) to-do(s) re-filed; "
            + "marker v\(TodoColumnRepairRules.schemaVersion) stored, this account will not be swept again")
        isRunning = false
    }
}
