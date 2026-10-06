//  AppleScriptScripting.swift
//
//  Cocoa scripting (AppleScript) support for Focus Bear. Exposes three capabilities to external
//  automation, declared in `FocusBear.sdef`:
//    1. `start focus session` — start a focus mode / block list with an intention + duration.
//    2. `make new task` / `set …` / `complete task` — create and edit Day Plan tasks.
//    3. `recently modified tasks` — poll tasks the USER changed (never AppleScript-driven changes),
//       so a third-party system can watch for real user activity without looping on its own writes.
//    4. `list to dos` — the signed-in account's to-do list from the server, fetched with the app's own
//       credentials, so local tools never need the access token itself.
//
//  The app is an LSUIElement agent, but Cocoa scripting still works: Apple events are delivered on
//  the main thread and routed through this file. Task writes coming through here are tagged
//  `.appleScript`, so they never stamp `lastUserModifiedAt` (see `TaskEditSource`) — that is what
//  keeps `recently modified tasks` free of AppleScript-originated churn.

import Cocoa

// MARK: - Scriptable task wrapper

/// A scripting proxy for one Day Plan task (today). Reads/writes flow through `DayPlanTaskStore`,
/// keyed by the task id, so the wrapper always reflects live data. Supports a short-lived "staging"
/// mode used by the standard `make new task` verb: before the object is inserted it holds its
/// properties in ivars, then `materializeIfNeeded()` creates the backing store task on insert.
@objc(FBScriptTask)
final class FBScriptTask: NSObject {

    /// Live task id once backed by the store; nil while a `make new task` object is being staged.
    private var boundID: String?
    private let day: Date

    // Values staged before insertion (standard `make` path only).
    private var stagedName = ""
    private var stagedCompleted = false
    private var stagedDuration = 15
    private var stagedProject = ""

    /// Bind to an existing task.
    init(taskID: String, day: Date = Date()) {
        self.boundID = taskID
        self.day = day
        super.init()
    }

    /// Staging init used by Cocoa's `make new task` before properties are applied.
    override init() {
        self.boundID = nil
        self.day = Date()
        super.init()
    }

    private var storeTask: DayPlanTask? {
        guard let id = boundID else { return nil }
        return DayPlanTaskStore.shared.task(withID: id, for: day)
    }

    /// Called when `make new task` inserts this staged object: create the backing store task as an
    /// AppleScript-sourced write (so it stays out of `recently modified tasks`) and bind to it.
    func materializeIfNeeded() {
        guard boundID == nil else { return }
        let task = DayPlanTask(title: stagedName,
                               durationMinutes: max(1, stagedDuration),
                               done: stagedCompleted,
                               project: stagedProject.isEmpty ? nil : stagedProject)
        DayPlanTaskStore.shared.add(task, for: day, source: .appleScript)
        boundID = task.id
        // Give the from-scratch task a backend to-do so it syncs across devices, same as a UI add.
        DayPlanTaskStore.shared.syncNameOnCommit(task, on: day)
    }

    private func mutate(_ change: (inout DayPlanTask) -> Void) {
        guard var task = storeTask else { return }
        change(&task)
        DayPlanTaskStore.shared.update(task, for: day, source: .appleScript)
    }

    // MARK: Scriptable properties

    @objc var uniqueID: String { boundID ?? "" }

    @objc var name: String {
        get { storeTask?.title ?? stagedName }
        set {
            guard storeTask != nil else { stagedName = newValue; return }
            mutate { $0.title = newValue }
            if let task = storeTask { DayPlanTaskStore.shared.syncNameOnCommit(task, on: day) }
        }
    }

    @objc var completed: Bool {
        get { storeTask?.done ?? stagedCompleted }
        set {
            guard storeTask != nil else { stagedCompleted = newValue; return }
            mutate { $0.done = newValue }
        }
    }

    @objc var duration: Int {
        get { storeTask?.durationMinutes ?? stagedDuration }
        set {
            let minutes = max(1, newValue)
            guard storeTask != nil else { stagedDuration = minutes; return }
            mutate { $0.durationMinutes = minutes }
        }
    }

    @objc var project: String {
        get { storeTask?.project ?? stagedProject }
        set {
            guard storeTask != nil else { stagedProject = newValue; return }
            mutate { $0.project = newValue.isEmpty ? nil : newValue }
        }
    }

    @objc var modificationDate: Date? { storeTask?.lastUserModifiedAt }

    @objc var modifiedByUser: Bool { storeTask?.lastUserModifiedAt != nil }

    override var objectSpecifier: NSScriptObjectSpecifier? {
        guard let id = boundID else { return nil }
        // The application's scripting class description (the sdef "application" class, AE code 'capp'),
        // from the suite registry, falling back to the running app's class description. NOTE: the
        // committed code used `NSScriptClassDescription(for:)`, which isn't a valid initializer — it only
        // "compiled" via stale incremental object files, so every task reference returned nil here.
        let cappCode: FourCharCode = 0x63617070   // 'capp'
        guard let appDesc = NSScriptSuiteRegistry.shared().classDescription(withAppleEventCode: cappCode)
                ?? (NSApp?.classDescription as? NSScriptClassDescription) else { return nil }
        return NSUniqueIDSpecifier(containerClassDescription: appDesc,
                                   containerSpecifier: nil, key: "tasks", uniqueID: id)
    }

    /// Handles the `complete` verb (sdef <responds-to>). AppleScript sends the command to the task
    /// itself, so it's a method on FBScriptTask rather than an app-level NSScriptCommand — the latter
    /// was mis-routed ("task doesn't understand 'complete'"). `completed` defaults to true.
    @objc func handleCompleteScriptCommand(_ command: NSScriptCommand) -> Any? {
        let completedArg = (command.evaluatedArguments?["completed"] as? Bool) ?? true
        let id = boundID
        return command.runWhenAppReady {
            // Re-bind by id (self is a transient wrapper); writes go through the store by id.
            if let id = id { FBScriptTask(taskID: id).completed = completedArg }
            return nil
        }
    }
}

// MARK: - Application scripting container (today's tasks element)

extension AppDelegate {

    /// Route KVC scripting for the `tasks` element to this delegate rather than to NSApplication.
    @objc func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        return key == "tasks"
    }

    /// The `tasks` element of `application`: today's Day Plan tasks.
    @objc var tasks: [FBScriptTask] {
        fbNoteScriptingCommand()
        return DayPlanTaskStore.shared.tasks(for: Date()).map { FBScriptTask(taskID: $0.id) }
    }

    /// `task id "…"` lookups.
    @objc(valueInTasksWithUniqueID:)
    func valueInTasks(withUniqueID id: Any) -> FBScriptTask? {
        fbNoteScriptingCommand()
        guard let idStr = id as? String,
              DayPlanTaskStore.shared.task(withID: idStr, for: Date()) != nil else { return nil }
        return FBScriptTask(taskID: idStr)
    }

    /// `task "…"` (by-name) lookups.
    @objc(valueInTasksWithName:)
    func valueInTasks(withName name: String) -> FBScriptTask? {
        fbNoteScriptingCommand()
        guard let match = DayPlanTaskStore.shared.tasks(for: Date()).first(where: { $0.title == name })
        else { return nil }
        return FBScriptTask(taskID: match.id)
    }

    // `make new task` insertion hooks (the `tasks` key is delegate-handled). Both the unordered and
    // indexed forms materialize the staged object into the store.
    @objc(insertInTasks:)
    func insertInTasks(_ task: FBScriptTask) { fbNoteScriptingCommand(); task.materializeIfNeeded() }

    @objc(insertObject:inTasksAtIndex:)
    func insertObject(_ task: FBScriptTask, inTasksAt index: Int) { fbNoteScriptingCommand(); task.materializeIfNeeded() }
}

// MARK: - Cold-start readiness

extension NSScriptCommand {
    /// Runs `work` once the app has finished its initial state setup (`isCheckWindowStateDone`), so a
    /// command that COLD-LAUNCHED the app (Apple events auto-launch it) doesn't execute before the
    /// windows / focus modes / task store are ready — which made a cold `start focus session` fail with
    /// "No focus mode named …". Apple events are delivered on the MAIN thread and the startup that flips
    /// the flag also runs there, so a blocking wait would deadlock; use Cocoa's suspend/resume and poll
    /// the runloop instead. Falls back to running after `timeout` so a never-ready app (e.g. logged out)
    /// still gets a reply rather than hanging forever.
    func runWhenAppReady(timeout: TimeInterval = NSScriptCommand.appReadyTimeout, _ work: @escaping () -> Any?) -> Any? {
        // Note that a script drove us so the app foregrounds itself out of a background cold launch
        // (AppDelegate.fbNoteScriptingCommand / checkWindowState handle the actual activation + splash).
        appdelegate?.fbNoteScriptingCommand()
        if appdelegate?.isCheckWindowStateDone == true { return work() }
        suspendExecution()
        NSScriptCommand.afterAppReady(timeout: timeout) { self.resumeExecution(withResult: work()) }
        return nil   // result delivered later via resumeExecution
    }

    static let appReadyTimeout: TimeInterval = 30
    static let appReadyPollInterval: TimeInterval = 0.3

    /// Calls `body` on the main thread once initial state setup is done, or after `timeout`. Unlike
    /// `runWhenAppReady` it neither suspends the command nor brings the app forward.
    static func afterAppReady(timeout: TimeInterval = appReadyTimeout, _ body: @escaping () -> Void) {
        let deadline = Date().addingTimeInterval(timeout)
        func poll() {
            if appdelegate?.isCheckWindowStateDone == true || Date() >= deadline {
                body()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + appReadyPollInterval, execute: poll)
            }
        }
        poll()
    }
}

// MARK: - start focus session

@objc(FBStartFocusSessionCommand)
final class FBStartFocusSessionCommand: NSScriptCommand {

    override func performDefaultImplementation() -> Any? {
        // Capture the parameters now (valid on the calling runloop), then run once the app is ready.
        let modeArg = (directParameter as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let args = evaluatedArguments ?? [:]
        let intention = (args["intention"] as? String) ?? ""
        let durationMinutes = (args["duration"] as? Int) ?? 25
        return runWhenAppReady { [weak self] in
            self?.start(modeArg: modeArg, intention: intention, durationMinutes: durationMinutes)
        }
    }

    /// Cold launch: the focus modes may not be in the in-memory global yet. Hydrate them from the store
    /// they are sealed in (mirrors startFocusFromMenu), so a session started right after launch still
    /// finds the mode.
    static func hydrateFocusModesIfNeeded() {
        guard arrFocusType.isEmpty,
              let stored = SensitiveDefaults.object(forKey: kUserdefaultsArrFocusTypes) as? [[String: Any]] else { return }
        arrFocusType = stored
    }

    private func start(modeArg: String, intention: String, durationMinutes: Int) -> Any? {
        Self.hydrateFocusModesIfNeeded()

        guard !modeArg.isEmpty else {
            fail(880, "Specify the name or id of the focus mode to start.")
            return nil
        }
        guard durationMinutes >= 1 else {
            fail(881, "Duration must be at least 1 minute.")
            return nil
        }

        guard let index = Self.focusModeIndex(matching: modeArg) else {
            fail(882, "No focus mode named or with id \"\(modeArg)\" was found.")
            return nil
        }
        let modeName = arrFocusType[index]["name"] as? String ?? modeArg

        let result = startFocusModeFromFocusDeviceButton(
            diffMinutes: durationMinutes,
            shouldUpdateFocusButton: true,
            goal: intention.isEmpty ? nil : intention,
            initiatedByRecording: false,
            focusModeIndex: index)

        switch result {
        case .started:
            return "Started focus session \"\(modeName)\" for \(durationMinutes) minute(s)."
        case .alreadyRunning:
            fail(883, "A focus session is already running. Stop it before starting another.")
        case .paused:
            fail(884, "A focus session is currently paused. Resume or stop it first.")
        case .hardcore:
            fail(885, "A hardcore pomodoro session is active and cannot be interrupted.")
        case .activityRunning:
            fail(886, "A routine or activity is running; a focus session cannot start right now.")
        case .invalidDuration:
            fail(881, "Duration must be at least 1 minute.")
        case .modeNotFound:
            fail(882, "No focus mode named or with id \"\(modeArg)\" was found.")
        }
        return nil
    }

    /// Match a focus mode by exact id or case-insensitive name.
    static func focusModeIndex(matching arg: String) -> Int? {
        for i in 0..<arrFocusType.count {
            let id = arrFocusType[i]["id"] as? String ?? ""
            let name = arrFocusType[i]["name"] as? String ?? ""
            if id == arg || name.lowercased() == arg.lowercased() { return i }
        }
        return nil
    }

    private func fail(_ number: Int, _ message: String) {
        scriptErrorNumber = number
        scriptErrorString = message
    }
}

// MARK: - recently modified tasks

@objc(FBRecentlyModifiedTasksCommand)
final class FBRecentlyModifiedTasksCommand: NSScriptCommand {

    override func performDefaultImplementation() -> Any? {
        let since = evaluatedArguments?["since"] as? Date
        return runWhenAppReady {
            // Return the scriptable objects; with the sdef result declared as a nested <type … list="yes"/>,
            // Foundation packages the AEList and calls each object's objectSpecifier.
            DayPlanTaskStore.shared.recentlyUserModifiedTasks(since: since, for: Date())
                .map { FBScriptTask(taskID: $0.id) }
        }
    }
}

// (The `complete` verb is handled by FBScriptTask.handleCompleteScriptCommand: via the sdef
//  <responds-to>, not an app-level NSScriptCommand — see AppleScript object-targeting dispatch.)

// MARK: - list to dos

/// Why `list to dos` could not answer. Numbers continue the 88x range `start focus session` uses.
enum ScriptToDoListError: Error, Equatable {
    case invalidStatus(String)
    case invalidSortMode(String)
    case notSignedIn
    case requestFailed(statusCode: Int)
    case unreadableResponse

    var number: Int {
        switch self {
        case .invalidStatus: return 890
        case .invalidSortMode: return 891
        case .notSignedIn: return 892
        case .requestFailed: return 893
        case .unreadableResponse: return 894
        }
    }

    var message: String {
        switch self {
        case .invalidStatus(let value):
            let accepted = (ToDoStatus.allCases.map(\.rawValue) + [ScriptToDoListRequest.allStatuses]).joined(separator: ", ")
            return "Unknown status \"\(value)\". Use one of: \(accepted)."
        case .invalidSortMode(let value):
            return "Unknown sort mode \"\(value)\". Use one of: \(ToDoSortMode.allCases.map(\.rawValue).joined(separator: ", "))."
        case .notSignedIn:
            return "Focus Bear is not signed in."
        case .requestFailed(let statusCode):
            return statusCode == 0 ? "Focus Bear could not reach the server." : "The server returned HTTP \(statusCode)."
        case .unreadableResponse:
            return "The server's to-do list could not be read."
        }
    }
}

/// The validated arguments of `list to dos`.
struct ScriptToDoListRequest: Equatable {
    /// Omits the status filter.
    static let allStatuses = "ALL"

    let status: ToDoStatus?
    let sortMode: ToDoSortMode
    let take: Int

    static func parse(status: String?, sortMode: String?, take: Int?) -> Result<ScriptToDoListRequest, ScriptToDoListError> {
        let statusText = (status ?? ToDoStatus.notStarted.rawValue).trimmingCharacters(in: .whitespaces).uppercased()
        let parsedStatus: ToDoStatus?
        if statusText == allStatuses {
            parsedStatus = nil
        } else if let known = ToDoStatus(rawValue: statusText) {
            parsedStatus = known
        } else {
            return .failure(.invalidStatus(status ?? ""))
        }
        let sortText = (sortMode ?? ToDoSortMode.smart.rawValue).trimmingCharacters(in: .whitespaces).uppercased()
        guard let parsedSort = ToDoSortMode(rawValue: sortText) else { return .failure(.invalidSortMode(sortMode ?? "")) }
        let clampedTake = min(max(take ?? ToDoPaging.tasksPerPage, 1), ToDoPaging.tasksPerPage)
        return .success(ScriptToDoListRequest(status: parsedStatus, sortMode: parsedSort, take: clampedTake))
    }

    var query: ToDoListQuery {
        ToDoListQuery(page: ToDoPaging.firstPage, take: take, status: status, sortMode: sortMode)
    }
}

/// Answers `list to dos` with the app's own credentials. The caller gets the to-do JSON in the
/// server's order; the token never leaves the app, and the request is pinned to the signed-in account.
struct ScriptToDoListResponder {
    typealias Fetch = (_ path: String, _ accountID: String, _ completion: @escaping (Data?, Int) -> Void) -> Void

    let accountID: () -> String?
    let fetch: Fetch

    static let live = ScriptToDoListResponder(
        accountID: { appdelegate?.user?.userId },
        fetch: { path, accountID, completion in
            allApiObject.getTaskSnapshotData(path: path, expectedAccountID: accountID, completion: completion)
        })

    func respond(to request: ScriptToDoListRequest, completion: @escaping (Result<String, ScriptToDoListError>) -> Void) {
        guard let account = accountID(), !account.isEmpty else {
            completion(.failure(.notSignedIn))
            return
        }
        fetch(request.query.path, account) { data, statusCode in
            guard (200..<300).contains(statusCode), let data else {
                completion(.failure(.requestFailed(statusCode: statusCode)))
                return
            }
            guard let json = Self.tasksJSON(from: data) else {
                completion(.failure(.unreadableResponse))
                return
            }
            completion(.success(json))
        }
    }

    /// The `data` array of a `GET /to-do` page (or a bare array), re-serialised as JSON text.
    static func tasksJSON(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        let tasks = (object as? [String: Any])?["data"] ?? object
        guard tasks is [Any], let encoded = try? JSONSerialization.data(withJSONObject: tasks) else { return nil }
        return String(data: encoded, encoding: .utf8)
    }
}

@objc(FBListToDosCommand)
final class FBListToDosCommand: NSScriptCommand {
    private enum Argument {
        static let status = "status"
        static let sortMode = "sortMode"
        static let take = "take"
    }

    override func performDefaultImplementation() -> Any? {
        let args = evaluatedArguments ?? [:]
        let parsed = ScriptToDoListRequest.parse(status: args[Argument.status] as? String,
                                                 sortMode: args[Argument.sortMode] as? String,
                                                 take: args[Argument.take] as? Int)
        let request: ScriptToDoListRequest
        switch parsed {
        case .failure(let error):
            fail(error)
            return nil
        case .success(let value):
            request = value
        }
        // A read-only query: answer without bringing the app forward (no fbNoteScriptingCommand).
        suspendExecution()
        NSScriptCommand.afterAppReady {
            ScriptToDoListResponder.live.respond(to: request) { result in
                DispatchQueue.main.async { self.finish(with: result) }
            }
        }
        return nil
    }

    private func finish(with result: Result<String, ScriptToDoListError>) {
        switch result {
        case .success(let json):
            resumeExecution(withResult: json)
        case .failure(let error):
            fail(error)
            resumeExecution(withResult: nil)
        }
    }

    private func fail(_ error: ScriptToDoListError) {
        scriptErrorNumber = error.number
        scriptErrorString = error.message
    }
}
