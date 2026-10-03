//
//  FocusSessionStore.swift
//  Focus Bear
//
//  The bridge between the SwiftUI ongoing-focus-session screen and the app's existing focus-mode
//  globals. Everything here is a thin adapter: the session clock still lives in `endFocusModeTime`,
//  the queue still lives in `focusModeTaskString` / the focus mode's `lastTaskUsed`, and every
//  pause/resume/stop still routes through menuViewController so the teacher-session, strict and
//  super-strict gates keep applying. No new endpoints and no new persistence.
//

import AppKit
import Combine
import SwiftUI

/// How much the +/- controls move the session end, in minutes.
let focusSessionDurationStepMinutes = 5

/// The clock only needs to be right to the second.
private let focusSessionTickInterval: TimeInterval = 1
/// The left menu's "Focusing (Nm left)" row only shows whole minutes, so it refreshes far less often.
let leftMenuFocusMinutesTickInterval: TimeInterval = 20
/// Typing the focus goal shouldn't evaluate JS in the To Do Player on every keystroke.
private let focusSessionGoalSaveDelay: TimeInterval = 0.6
/// The brain dump auto-saves after a pause in typing, like the Notes screen's own editor.
private let focusSessionBrainDumpSaveDelay: TimeInterval = 2

/// The one modal the screen can be showing. A single enum (rather than a bool per sheet) because
/// stacking several `.sheet` modifiers on one view is unreliable on macOS 11.
enum FocusSessionSheet: String, Identifiable {
    case taskPicker
    case endSessionConfirm
    case editTask
    /// The notes list, shown over the session screen rather than navigated to.
    case notes
    case music

    var id: String { rawValue }
}

/// Which page the task sheet is showing. The design reaches "Create new task" and "Add Filters" from
/// the picker's own chrome, with a back arrow, rather than as separate modals.
enum FocusSessionTaskPickerPage {
    case selectTasks
    case createTask
    case filters
}

/// Which of the three in-session states the screen is showing.
enum FocusSessionPhase {
    case running
    case paused
    case superFocus
    /// Nothing is running — the screen is only reachable in this state transiently, while the
    /// session is being torn down.
    case idle
}

/// The one write path for the focus session's task queue.
///
/// The queue is a global (`focusModeTaskString`) that several screens read, so completing a task has
/// to reach all of them. Both places a person can tick a task off during a session — the in-session
/// screen and the menu bar's focus card — go through here, so there is a single completion path and a
/// single announcement on `TodoCompletionBus` rather than two that drift apart.
@available(macOS 11.0, *)
enum FocusSessionQueueWriter {
    /// The live queue, as every reader of `focusModeTaskString` sees it.
    static var tasks: [FocusSessionTask] { FocusSessionTaskQueue.decode(focusModeTaskString) }

    /// The task the session is working on right now, read straight from the live queue.
    static var activeTask: FocusSessionTask? { FocusSessionTaskQueue.activeTask(in: tasks) }

    /// During a class session the frontend owns the checklist — the student must not reshuffle it.
    static var isTaskEditingLocked: Bool { teacherSessionManagerObject.isTeacherSessionActive() }

    /// Writes a queue everywhere it is read from: the global, the derived caches
    /// (`updateFocusModeTask`), and the running focus mode's persisted `lastTaskUsed`.
    static func persist(_ tasks: [FocusSessionTask]) {
        let json = FocusSessionTaskQueue.encode(tasks)
        updateFocusModeTask(taskString: json)
        guard let index = runningFocusModeIndex() else { return }
        arrFocusType[index]["lastTaskUsed"] = json
        updateAllFocusModes()
    }

    /// Completes one queue entry and returns the new queue.
    @discardableResult
    static func complete(id: String, in tasks: [FocusSessionTask]) -> [FocusSessionTask] {
        let updated = FocusSessionTaskQueue.completing(tasks, id: id)
        // The player owns "complete the current task and play the next one" as a single operation, so
        // hand it the successor with the completion flag rather than sending two half-updates.
        if let next = FocusSessionTaskQueue.activeTask(in: updated) {
            taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: next.title,
                                                         id: next.id,
                                                         duration: next.durationSeconds,
                                                         shouldCompleteCurrentTask: true)
        }
        if updated != tasks { persist(updated) }
        markPlannedTaskComplete(queueID: id)
        return updated
    }

    /// A queue entry IS a planned task, so completing it has to tick it in the Day Plan and the To-do
    /// list too — it used to stay struck through in the session and open everywhere else (report
    /// 2026-09-14_10-09-59). Routed through the Day Plan's own write path, which pushes the status to
    /// the backing to-do and announces it on `TodoCompletionBus` for every other view.
    ///
    /// The player's `shouldCompleteCurrentTask` can't carry this on its own: it is only sent when
    /// there IS a next task, so finishing the last task of a session reached nothing at all.
    private static func markPlannedTaskComplete(queueID: String) {
        let today = Date()
        guard var planned = FocusQueueTaskMatch.task(for: queueID,
                                                     in: DayPlanTaskStore.shared.tasks(for: today)),
              !planned.done else { return }
        planned.done = true
        DayPlanTaskStore.shared.update(planned, for: today)
    }

    /// The focus mode this session is running: matched by id where we have one, else the flagged mode.
    private static func runningFocusModeIndex() -> Int? {
        let runningId = currentRunningFocusType["id"] as? String ?? ""
        if !runningId.isEmpty,
           let index = arrFocusType.firstIndex(where: { $0["id"] as? String == runningId }) {
            return index
        }
        return arrFocusType.firstIndex { $0["isOn"] as? Bool == true || $0["isPaused"] as? Bool == true }
    }
}

@available(macOS 11.0, *)
final class FocusSessionStore: ObservableObject {

    // MARK: - Published state

    @Published private(set) var phase: FocusSessionPhase = .idle
    @Published private(set) var remainingSeconds = 0
    @Published private(set) var totalSeconds = 0
    @Published private(set) var focusModeName = ""
    @Published private(set) var tasks: [FocusSessionTask] = []
    @Published private(set) var isDurationLocked = false
    @Published private(set) var isGoalLocked = false
    @Published private(set) var isTaskEditingLocked = false
    /// #2786: true while this is a teacher-owned class checklist. The queue is the teacher's checklist
    /// (tasks can't be added/edited/reordered — `isTaskEditingLocked` is also true), but the student may
    /// still tick the first incomplete task and un-tick the latest completed one, routed to the
    /// class-session endpoints.
    @Published private(set) var isClassChecklist = false
    /// Set when a class-session tick/un-tick failed and the row was reverted; shown under the queue.
    @Published private(set) var classChecklistError: String?
    /// Whether the block list this session enforces may be changed from here.
    @Published private(set) var canChangeBlockList = false

    /// Bound to the goal editor. Written back to `whatToAchieveInFocusBlock` after a short pause.
    @Published var focusGoal = "" {
        didSet {
            guard focusGoal != oldValue, !isGoalLocked else { return }
            scheduleGoalSave()
        }
    }

    // Modals
    @Published var activeSheet: FocusSessionSheet?
    @Published var pickerPage: FocusSessionTaskPickerPage = .selectTasks
    /// Filters applied to the picker, and the draft the filter page edits before "Add N filters".
    @Published private(set) var appliedFilters = FocusSessionTaskFilters.none
    @Published var filterDraft = FocusSessionTaskFilters.none
    @Published private(set) var projects: [FocusSessionProject] = []
    @Published var projectQuery = ""
    /// The task the edit sheet is working on, and its in-progress fields.
    @Published private(set) var taskBeingEdited: FocusSessionPickerTask?
    @Published var taskEdits = FocusSessionTaskEdits()
    @Published private(set) var editFailed = false
    @Published private(set) var taskEditError: String?
    private var editSnapshot: [String: Any]?
    private var editAccountID = ""
    private var editGeneration = 0
    @Published private(set) var activeSubtasks: [ToDoSubtask] = []
    @Published private(set) var isLoadingSubtasks = false
    @Published private(set) var isSavingSubtask = false
    @Published private(set) var subtaskError: String?
    /// The server's snapshot of this task is missing fields the app needs to edit it safely. Recorded
    /// on load but NOT shown: the message is about editing, and it was appearing on every task the
    /// user merely looked at ("still seeing this message", report 2026-09-14_19-50-12). It surfaces
    /// when an edit is actually attempted.
    @Published private(set) var subtasksNeedServerUpdate = false
    @Published var subtaskName = ""
    private var subtaskSnapshot: [String: Any]?
    private var subtaskIdentity = ""
    private var subtaskGeneration = 0
    @Published private(set) var pickerTasks: [FocusSessionPickerTask] = []
    @Published private(set) var pickerSource = FocusSessionPickerSource.dayPlan
    /// Time on the current task in this session. Derived, not persisted — see FocusSessionTaskTimer.
    @Published private(set) var taskTimer = FocusSessionTaskTimer()
    @Published private(set) var isLoadingPickerTasks = false
    @Published private(set) var isSavingTask = false
    @Published var pickerQuery = ""
    @Published var selectedPickerTaskIds: Set<String> = []

    /// The rail's quick brain dump. Saved through the same `PUT /note` upsert the Notes screen uses.
    @Published var brainDump = "" {
        didSet {
            guard brainDump != oldValue, !isSuppressingBrainDumpSave else { return }
            scheduleBrainDumpSave()
        }
    }

    let strings = FocusSessionStrings.load()
    /// Backs the notes lightbox. Same store type the Notes screen uses, so notes stay in sync.
    lazy var notesStore = NotesStore(strings: NotesStrings.load())

    private var tickTimer: Timer?
    private var goalSaveWorkItem: DispatchWorkItem?
    private var brainDumpSaveWorkItem: DispatchWorkItem?
    private var isSuppressingBrainDumpSave = false

    // MARK: - Derived state

    var activeTask: FocusSessionTask? { FocusSessionTaskQueue.activeTask(in: tasks) }

    /// "Working for 12 min" — how long the current task has been the active one this session.
    var timeOnTaskText: String {
        strings.timeOnTask(FocusSessionClock.compactElapsed(seconds: taskTimer.elapsedSeconds(),
                                                            units: strings.durationUnits))
    }

    /// The card shows the running indicator only while the session is actually running.
    var isTaskRunning: Bool { phase == .running && activeTask != nil }
    var queuedTasks: [FocusSessionTask] { FocusSessionTaskQueue.queuedTasks(in: tasks) }
    /// Drives the queue heading's count. The rows themselves still include completed tasks.
    var outstandingQueuedTasks: [FocusSessionTask] { FocusSessionTaskQueue.outstanding(in: queuedTasks) }
    var workTitle: String {
        let project = activeTask?.projectName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !project.isEmpty { return project }
        let goal = focusGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        return goal.isEmpty ? focusModeName : goal
    }

    var elapsedSeconds: Int { max(0, totalSeconds - remainingSeconds) }
    var progress: Double {
        FocusSessionClock.progress(elapsedSeconds: elapsedSeconds, totalSeconds: totalSeconds)
    }

    /// `.idle` keeps the running headline because it is only ever on screen for the fraction of a
    /// second between a session ending and the tab being handed back — `leaveIfNoSessionLeftToShow()`
    /// guarantees it can't persist. It used to persist, which is how a running blocking schedule ended
    /// up headed "Ongoing Focus Session" for a whole working day (report 2026-09-16_15-13-57).
    var headlineTitle: String {
        switch phase {
        case .paused: return strings.sessionPausedTitle
        case .superFocus: return strings.superFocusRunningTitle
        case .running, .idle: return strings.sessionRunningTitle
        }
    }

    var countdownText: String {
        FocusSessionClock.headline(remainingSeconds: remainingSeconds, units: strings.durationUnits)
    }

    var elapsedText: String { FocusSessionClock.clockText(seconds: elapsedSeconds) }
    var totalText: String { FocusSessionClock.clockText(seconds: totalSeconds) }

    /// "5 min of 30 min" — the bar in words, so a bare pair of timestamps isn't a puzzle.
    var progressText: String {
        strings.sessionProgress(
            elapsed: FocusSessionClock.compactElapsed(seconds: elapsedSeconds, units: strings.durationUnits),
            total: FocusSessionClock.compactElapsed(seconds: totalSeconds, units: strings.durationUnits))
    }

    /// The countdown and progress bar are shown whenever there is a session length to count against —
    /// including while paused, where the design dims them rather than hiding them.
    var showsCountdown: Bool { (phase == .running || phase == .paused) && totalSeconds > 0 }

    /// Only a running session can have its duration adjusted.
    var showsDurationControls: Bool { phase == .running && totalSeconds > 0 }

    var visiblePickerTasks: [FocusSessionPickerTask] {
        FocusSessionTaskFilter.matching(pickerTasks,
                                        query: pickerQuery,
                                        excludingIds: Set(tasks.map { $0.id }),
                                        filters: appliedFilters)
    }

    var visibleProjects: [FocusSessionProject] {
        FocusSessionTaskFilter.matching(projects, query: projectQuery)
    }

    // MARK: - Lifecycle

#if DEBUG
    /// A frozen render fixture. Never starts the session lifecycle, loads an account, or saves notes.
    /// The caller supplies synthetic copy so no personal task or note data enters screenshots.
    static func visualFixture(tasks: [FocusSessionTask], subtasks: [ToDoSubtask],
                              blockListName: String, goal: String, notes: String) -> FocusSessionStore {
        precondition(LogicTestHost.isEnabled)
        let store = FocusSessionStore()
        store.phase = .running
        store.totalSeconds = 1800
        store.remainingSeconds = 1476
        store.focusModeName = blockListName
        store.tasks = tasks
        store.activeSubtasks = subtasks
        store.withoutGoalSave { store.focusGoal = goal }
        store.isSuppressingBrainDumpSave = true
        store.brainDump = notes
        store.isSuppressingBrainDumpSave = false
        store.isMusicPanelExpanded = true
        store.isNotesPanelExpanded = true
        store.taskTimer.activate(taskId: store.activeTask?.id, now: Date(timeIntervalSince1970: 0))
        store.taskTimer.pause(now: Date(timeIntervalSince1970: 324))
        return store
    }
#endif

    /// Called from the hosting controller's viewWillAppear. Re-reads every global, because anything
    /// (Pusher, the menu bar, the To Do Player) may have changed them while the screen was away.
    func screenAppeared() {
        refreshFromGlobals()
        loadBrainDump()
        startTicking()
    }

    /// #2571 (18): re-read the shared brain-dump note whenever the running screen appears, so edits made
    /// in the main Brain Dump tab are reflected here (the rail previously kept its own in-memory copy and
    /// never reloaded it). Mirrors `NotesStore.adoptBrainDump`: take the most recently updated brain-dump
    /// note, and never clobber text the user is mid-edit — a pending debounced save means local edits win.
    private func loadBrainDump() {
        guard brainDumpSaveWorkItem == nil else { return }
        allApiObject.getNotes(page: 1, take: 50) { [weak self] page in
            DispatchQueue.main.async {
                guard let self = self, self.brainDumpSaveWorkItem == nil else { return }
                guard let latest = (page?.data ?? [])
                        .filter({ $0.isBrainDump })
                        .max(by: { $0.updated_at < $1.updated_at }) else { return }
                // The note body is CKEditor HTML (<p>…</p>); this rail is a plain TextEditor, so show
                // plain text rather than the raw tags.
                let body = NoteHTML.plainText(fromHTML: latest.body ?? "")
                guard body != self.brainDump else { return }
                self.isSuppressingBrainDumpSave = true
                self.brainDump = body
                self.isSuppressingBrainDumpSave = false
            }
        }
    }

    func screenDisappeared() {
        stopTicking()
        flushPendingGoalSave()
        flushPendingBrainDumpSave()
    }

    // MARK: - Side rail

    /// Rail panels expand and collapse in place. Navigating away from a running session — especially
    /// a strict one — is worse than annoying, so nothing in the rail leaves the screen; "See other
    /// notes" opens the notes list in a sheet over the session instead.
    @Published var isMusicPanelExpanded = false
    @Published var isNotesPanelExpanded = true

    func toggleMusicPanel() { isMusicPanelExpanded.toggle() }
    func toggleNotesPanel() { isNotesPanelExpanded.toggle() }

    /// Opens the notes list as a lightbox over the session screen.
    func presentNotesLightbox() {
        flushPendingBrainDumpSave()
        notesStore.screenAppeared()
        activeSheet = .notes
    }

    /// Now-playing title from the shared Focus Music model, when something is actually playing.
    var nowPlayingTitle: String? { FocusMusicViewModel.shared.nowPlaying?.title }
    var isMusicPlaying: Bool { FocusMusicViewModel.shared.nowPlaying != nil }

    private func scheduleBrainDumpSave() {
        brainDumpSaveWorkItem?.cancel()
        let body = brainDump
        let work = DispatchWorkItem { [weak self] in self?.commitBrainDump(body) }
        brainDumpSaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + focusSessionBrainDumpSaveDelay, execute: work)
    }

    private func flushPendingBrainDumpSave() {
        guard let pending = brainDumpSaveWorkItem else { return }
        pending.cancel()
        brainDumpSaveWorkItem = nil
        commitBrainDump(brainDump)
    }

    private func commitBrainDump(_ body: String) {
        brainDumpSaveWorkItem = nil
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        addLog(text: "focus session: saving brain dump")
        // This rail edits plain text, but the note stores CKEditor HTML (the Notes tab reads/renders it
        // as HTML). Convert the plain text back to <p>…</p> so the two surfaces stay consistent and the
        // Notes tab doesn't show it as one unformatted blob.
        let html = NoteHTML.html(from: NSAttributedString(
            string: body, attributes: [.font: NSFont.systemFont(ofSize: 12)]))
        allApiObject.upsertBrainDumpNote(body: html) { _, statusCode in
            addLog(text: "focus session: brain dump saved \(statusCode)")
        }
    }

    /// Re-read the app's focus-mode globals. Also the hook AppDelegate's pause/resume paths call.
    func refreshFromGlobals() {
        phase = currentPhase()
        focusModeName = currentFocusModeName()
        isGoalLocked = currentFocusModeStrictness == ._SUPER_STRICT_
        isDurationLocked = currentFocusModeStrictness == ._SUPER_STRICT_
        // #2216: during a class session the frontend owns the checklist — the student must not
        // reshuffle it from here (the combo box this screen replaces was disabled for the same reason).
        isTaskEditingLocked = FocusSessionQueueWriter.isTaskEditingLocked
        isClassChecklist = !classSessionTodoSessionId.isEmpty && teacherSessionManagerObject.isTeacherSessionActive()
        canChangeBlockList = FocusSessionBlockListSwitch.isAllowed(
            isSessionRunning: isFocusModeRunning, strictness: currentFocusModeStrictness,
            isClassSession: teacherSessionManagerObject.isTeacherSessionActive())
        if focusGoal != whatToAchieveInFocusBlock {
            // Assigning through the published property would re-trigger a save of what we just read.
            withoutGoalSave { focusGoal = whatToAchieveInFocusBlock }
        }
        tasks = FocusSessionTaskQueue.decode(focusModeTaskString)
        syncTaskTimer()
        updateRemaining()
    }

    /// Keeps the per-task timer pointed at whatever is active, and stopped whenever the session is not
    /// running, so a paused session doesn't accrue task time.
    private func syncTaskTimer() {
        taskTimer.activate(taskId: activeTask?.id)
        if phase == .running { taskTimer.resume() } else { taskTimer.pause() }
        loadActiveSubtasks()
    }

    func loadActiveSubtasks(force: Bool = false) {
        // #2786: a class-checklist task is not a personal to-do, so it has no editable subtasks. Don't
        // look it up (the fetch would fail and surface a "couldn't load this task" error with a Retry),
        // and clear any state so a personal task that becomes active after the class session reloads.
        if isClassChecklist {
            isLoadingSubtasks = false; activeSubtasks = []; subtaskName = ""
            subtaskError = nil; subtasksNeedServerUpdate = false; subtaskSnapshot = nil
            subtaskIdentity = ""
            return
        }
        let account = appdelegate?.user?.userId ?? "", id = activeTask?.id ?? ""
        let identity = account + ":" + id
        guard force || identity != subtaskIdentity else { return }
        if identity != subtaskIdentity { subtaskName = ""; activeSubtasks = [] }
        subtaskIdentity = identity; subtaskGeneration += 1
        let token = subtaskGeneration
        subtaskSnapshot = nil; subtaskError = nil; subtasksNeedServerUpdate = false; isSavingSubtask = false
        guard !id.isEmpty, !account.isEmpty else { isLoadingSubtasks = false; return }
        isLoadingSubtasks = true
        allApiObject.getFocusSessionTaskResult(id: id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, token == self.subtaskGeneration,
                      appdelegate?.user?.userId == account, self.activeTask?.id == id else { return }
                self.isLoadingSubtasks = false
                guard let raw = try? result.get(), let subtasks = FocusSessionSubtasks.decode(raw) else {
                    // An incomplete snapshot only matters once the user tries to change something, and
                    // the copy itself says "you can keep working on the task" — so note it and stay
                    // quiet. Anything else is a genuine load failure worth showing now.
                    if case .failure(.incompleteServerSnapshot) = result {
                        self.subtasksNeedServerUpdate = true
                    } else {
                        self.subtaskError = self.strings.taskLoadError(result)
                    }
                    return
                }
                self.subtaskSnapshot = raw; self.activeSubtasks = subtasks
            }
        }
    }

    func addSubtask() {
        let name = subtaskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard !reportServerUpdateIfNeeded() else { return }
        saveSubtasks(activeSubtasks + [.init(name: name, is_completed: false)], clearsDraft: true)
    }

    /// Say why an edit cannot proceed, at the moment it is attempted. Returns true when it can't.
    @discardableResult
    private func reportServerUpdateIfNeeded() -> Bool {
        guard subtasksNeedServerUpdate else { return false }
        subtaskError = strings.taskServerUpdateRequired
        return true
    }

    func setSubtaskCompleted(at index: Int, completed: Bool) {
        guard activeSubtasks.indices.contains(index) else { return }
        guard !reportServerUpdateIfNeeded() else { return }
        var updated = activeSubtasks; updated[index].is_completed = completed
        saveSubtasks(updated)
    }

    func removeSubtask(at index: Int) {
        guard activeSubtasks.indices.contains(index) else { return }
        guard !reportServerUpdateIfNeeded() else { return }
        var updated = activeSubtasks; updated.remove(at: index)
        saveSubtasks(updated)
    }

    private func saveSubtasks(_ updated: [ToDoSubtask], clearsDraft: Bool = false) {
        guard !isSavingSubtask, !isLoadingSubtasks, !isTaskEditingLocked,
              !teacherSessionManagerObject.isTeacherSessionActive(),
              let previous = subtaskSnapshot, let id = activeTask?.id,
              let account = appdelegate?.user?.userId else { return }
        let token = subtaskGeneration
        isSavingSubtask = true; subtaskError = nil
        allApiObject.getFocusSessionTask(id: id) { [weak self] latest in
            DispatchQueue.main.async {
                guard let self = self, token == self.subtaskGeneration, self.activeTask?.id == id else { return }
                guard appdelegate?.user?.userId == account, !teacherSessionManagerObject.isTeacherSessionActive(),
                      let latest = latest, FocusSessionTaskSnapshot.unchanged(latest, since: previous),
                      FocusSessionSubtasks.decode(latest) == FocusSessionSubtasks.decode(previous),
                      let body = FocusSessionSubtasks.body(updating: latest, subtasks: updated) else {
                    self.isSavingSubtask = false; self.subtaskError = self.strings.subtaskChanged; return
                }
                allApiObject.upsertToDo(body, expectedAccountID: account) { [weak self] saved, status, _ in
                    DispatchQueue.main.async {
                        guard let self = self, token == self.subtaskGeneration, self.activeTask?.id == id else { return }
                        self.isSavingSubtask = false
                        guard appdelegate?.user?.userId == account, (200..<300).contains(status),
                              let saved = saved, saved.id == id,
                              FocusSessionSubtasks.sameValues(saved.subtaskList, updated) else {
                            self.subtaskError = self.strings.couldNotSaveTask; return
                        }
                        self.activeSubtasks = saved.subtaskList
                        if clearsDraft { self.subtaskName = "" }
                        self.loadActiveSubtasks(force: true)
                    }
                }
            }
        }
    }

    private func currentPhase() -> FocusSessionPhase {
        if isFocusModeOn() { return .running }
        if isFocusModePaused() { return .paused }
        if isHardCorePomodoroModeOn { return .superFocus }
        return .idle
    }

    private func currentFocusModeName() -> String {
        let name = currentRunningFocusType["name"] as? String ?? ""
        return name.isEmpty ? strings.untitledFocusMode : name
    }

    /// The session length the progress bar measures against.
    ///
    /// `focusModeSecondsToPerform` is only the stretch since the last extend/reduce/pause re-based the
    /// countdown, and can still hold a *previous* session's value at the moment a new one starts — see
    /// `FocusSessionClock.sessionTotalSeconds` for how the banked time and the guards combine.
    private func currentTotalSeconds() -> Int {
        let isCountingDown = phase == .running
        return FocusSessionClock.sessionTotalSeconds(plannedMinutes: focusModeMinutesToPerform,
                                                     performedSeconds: focusModeActualDurationPerformed,
                                                     segmentSeconds: isCountingDown ? focusModeSecondsToPerform : 0,
                                                     remainingSeconds: remainingSeconds)
    }

    // MARK: - Clock

    private func startTicking() {
        stopTicking()
        let timer = Timer(timeInterval: focusSessionTickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
        tick()
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        if leaveIfNoSessionLeftToShow() { return }
        let phaseNow = currentPhase()
        if phaseNow != phase { refreshFromGlobals(); return }
        adoptExternalQueueChanges()
        updateRemaining()
        // The timer's own value is computed on read, but the view needs a nudge to re-read it.
        if isTaskRunning { objectWillChange.send() }
    }

    /// Hands the tab back to the start-a-session screen once the session this screen was showing has
    /// gone. Returns whether it navigated away.
    ///
    /// Nothing else does it: a *silent* finish (stopping a postpone-started session, a session ended
    /// from another device) tears the session down without touching the main window, so the screen
    /// stayed up in `.idle` — and `.idle` renders the running-session headline. With a blocking
    /// schedule also running, `currentRunningFocusType` is the schedule's block list, so the screen
    /// read "Ongoing Focus Session / <the schedule's block list>" for the rest of the day
    /// (report 2026-09-16_15-13-57). The schedule is still blocking; it just isn't a session.
    @discardableResult
    private func leaveIfNoSessionLeftToShow() -> Bool {
        guard FocusSessionRouting.destinationNow == .startSession else { return false }
        stopTicking()
        // Only swap the content of a window the user is already looking at — the start screen's entry
        // points show and activate the main window, and a background tick must never pop it open.
        // `isViewVisible` also keeps this off the focus-completed screen, which takes the same slot
        // when a session ends the normal (non-silent) way and must be left alone.
        guard mainWindowControllerObj?.window?.isVisible ?? false,
              leftMenuVcObj?.boxFocusSession.isSelected ?? false,
              focusModeStateVcObj?.isViewVisible ?? false else { return true }
        addLog(text: "focus session screen: no session left to show — returning to the start screen")
        leftMenuVcObj?.showStartFocusSessionView()
        return true
    }

    /// The queue is not ours alone: the AI-block buddy's task picker, the block popup and the To Do
    /// Player all change the active task through `addAndPlayTaskInCurrentList`. Without this the
    /// screen would keep showing the task that was active when it appeared, and the two notions of
    /// "current task" would diverge again from the other side.
    private func adoptExternalQueueChanges() {
        let live = FocusSessionTaskQueue.decode(focusModeTaskString)
        guard live != tasks else { return }
        tasks = live
        syncTaskTimer()
    }

    private func updateRemaining() {
        switch phase {
        case .running:
            remainingSeconds = endFocusModeTime.map {
                FocusSessionClock.remainingSeconds(until: $0, now: Date())
            } ?? 0
        case .paused:
            // A paused session has no end date; AppDelegate banked what was left when it paused.
            remainingSeconds = max(0, appdelegate?.remainingFocusModeSecondsAfterPaused ?? 0)
        case .superFocus, .idle:
            remainingSeconds = 0
        }
        // The total is derived from what is left, so it has to be recomputed alongside it — not once
        // when the screen appears, which is why the bar sat still.
        totalSeconds = currentTotalSeconds()
    }

    // MARK: - Timer controls

    func extendSession() {
        appdelegate?.extendFocusModeFor(minutes: focusSessionDurationStepMinutes)
        refreshFromGlobals()
    }

    func reduceSession() {
        guard !isDurationLocked else { return }
        appdelegate?.reduceFocusModeFor(minutes: focusSessionDurationStepMinutes)
        refreshFromGlobals()
    }

    /// Pause and resume keep going through menuViewController, which owns the strictness gates
    /// (super-strict asks for the password, strict shows the aborting screen, and a teacher-run
    /// class session refuses outright).
    func pauseSession() {
        menuViewControllerObj?.pauseFocusModeClicked()
    }

    func resumeSession() {
        menuViewControllerObj?.resumeFocusMode()
    }

    /// Confirmed end. `stopFocusMode()` runs the same friction gate the old stop menu item did.
    func endSession() {
        activeSheet = nil
        menuViewControllerObj?.stopFocusMode()
    }

    /// A teacher-run session can't be stopped early — surface the unlock-request alert rather than
    /// showing a confirmation the user can't act on.
    func requestEndSession() {
        if teacherSessionManagerObject.isTeacherSessionActive() {
            teacherSessionManagerObject.showTeacherSessionLockedAlert()
            return
        }
        activeSheet = .endSessionConfirm
    }

    // MARK: - Focus goal

    private var isSuppressingGoalSave = false

    private func withoutGoalSave(_ body: () -> Void) {
        isSuppressingGoalSave = true
        body()
        isSuppressingGoalSave = false
    }

    private func scheduleGoalSave() {
        guard !isSuppressingGoalSave else { return }
        goalSaveWorkItem?.cancel()
        let goal = focusGoal
        let work = DispatchWorkItem { [weak self] in
            self?.commitGoal(goal)
        }
        goalSaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + focusSessionGoalSaveDelay, execute: work)
    }

    private func flushPendingGoalSave() {
        guard let pending = goalSaveWorkItem else { return }
        pending.cancel()
        goalSaveWorkItem = nil
        commitGoal(focusGoal)
    }

    private func commitGoal(_ goal: String) {
        goalSaveWorkItem = nil
        guard !isGoalLocked, whatToAchieveInFocusBlock != goal else { return }
        whatToAchieveInFocusBlock = goal
        taskPlayerVcObj?.updateIntentionToPlayer()
    }

    // MARK: - Task queue

    func markActiveTaskComplete() {
        guard let active = activeTask else { return }
        if isClassChecklist { tickClassTask(id: active.id); return }
        guard !isTaskEditingLocked else { return }
        completeTask(id: active.id)
    }

    func completeTask(id: String) {
        if isClassChecklist { tickClassTask(id: id); return }
        guard !isTaskEditingLocked else { return }
        let updated = FocusSessionQueueWriter.complete(id: id, in: tasks)
        guard updated != tasks else { return }
        tasks = updated
        syncTaskTimer()
    }

    // MARK: - Class checklist tick / un-tick (#2786)

    /// Whether the student may tick `id` now — only the first incomplete task, per the class rules.
    func canTickClassTask(id: String) -> Bool {
        isClassChecklist && ClassSessionChecklistRules.canTick(id: id, in: tasks)
    }

    /// Whether the student may un-tick `id` now — only the latest completed task.
    func canUntickClassTask(id: String) -> Bool {
        isClassChecklist && ClassSessionChecklistRules.canUntick(id: id, in: tasks)
    }

    func tickClassTask(id: String) { setClassTask(id: id, complete: true) }
    func untickClassTask(id: String) { setClassTask(id: id, complete: false) }

    /// Optimistically tick/un-tick a class checklist row, then report it to the class session. On
    /// failure the row is reverted and an error is surfaced. Writes `focusModeTaskString` directly
    /// because `updateFocusModeTask` deliberately no-ops during a class session.
    private func setClassTask(id: String, complete: Bool) {
        guard isClassChecklist else { return }
        let sessionId = classSessionTodoSessionId
        guard !sessionId.isEmpty else { return }
        let proposed = complete
            ? ClassSessionChecklistRules.ticking(tasks, id: id)
            : ClassSessionChecklistRules.unticking(tasks, id: id)
        guard proposed != tasks else { return }   // not an allowed move (gating rejected it)
        let snapshot = tasks
        classChecklistError = nil
        applyClassTasks(proposed)
        allApiObject.setClassSessionTaskCompleted(sessionId: sessionId, taskId: id, complete: complete) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self, self.isClassChecklist else { return }
                // Only revert if nothing else moved the queue on in the meantime (a refetch, a later tick).
                guard !success, self.tasks == proposed else { return }
                self.applyClassTasks(snapshot)
                self.classChecklistError = "Couldn't update the task — check your connection and try again."   // i18n-ignore: transient toast
            }
        }
    }

    /// Writes a class checklist queue to the store and the global the screen reads, without the
    /// personal-to-do side effects of `FocusSessionQueueWriter` (class tasks are not personal to-dos,
    /// and `updateFocusModeTask` no-ops mid-class-session anyway).
    private func applyClassTasks(_ updated: [FocusSessionTask]) {
        tasks = updated
        focusModeTaskString = FocusSessionTaskQueue.encode(updated)
        syncTaskTimer()
    }

    func focusOnTask(id: String) {
        guard !isTaskEditingLocked, let task = tasks.first(where: { $0.id == id }) else { return }
        taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: task.title,
                                                     id: task.id,
                                                     duration: task.durationSeconds,
                                                     shouldCompleteCurrentTask: false)
        apply(FocusSessionTaskQueue.focusing(tasks, on: id))
    }

    func removeTask(id: String) {
        guard !isTaskEditingLocked else { return }
        apply(FocusSessionTaskQueue.removing(tasks, id: id))
    }

    func moveTask(id: String, by offset: Int) {
        guard !isTaskEditingLocked else { return }
        apply(FocusSessionTaskQueue.moving(tasks, id: id, by: offset))
    }

    func canMoveTask(id: String, by offset: Int) -> Bool {
        FocusSessionTaskQueue.moving(tasks, id: id, by: offset) != tasks
    }

    /// Writes a new queue everywhere it is read from.
    private func apply(_ updated: [FocusSessionTask]) {
        guard updated != tasks else { return }
        tasks = updated
        syncTaskTimer()
        FocusSessionQueueWriter.persist(updated)
    }

    // MARK: - Task picker

    func presentTaskPicker() {
        guard !isTaskEditingLocked else { return }
        pickerQuery = ""
        selectedPickerTaskIds = []
        pickerPage = .selectTasks
        activeSheet = .taskPicker
        loadPickerTasks()
        loadProjects()
    }

    /// The picker opens on the backend's SMART (priority) order — the same order the Day Plan picker
    /// and the web to-do list show — and switches to the search endpoint once the user types. A
    /// project filter is applied server-side so a project's tasks are found even when they fall
    /// outside the unfiltered top 50.
    /// The picker offers, in order of preference:
    ///
    ///  1. **today's Day Plan**, in the Day Plan's own (user-draggable) order — the list the user has
    ///     already decided to do today, so the picker agrees with the panel they planned in;
    ///  2. the **to-do list** in SMART order, when the Day Plan is empty for today;
    ///  3. a **search of the whole to-do list**, whenever the user types (`runPickerSearch`) — the
    ///     Day Plan is a handful of tasks, so search must not be limited to what is loaded.
    func loadPickerTasks() {
        // The rows show a project icon, which only the project catalogue carries.
        loadProjects()
        let planned = FocusSessionStore.dayPlanTasks()
        if !planned.isEmpty {
            pickerSource = .dayPlan
            isLoadingPickerTasks = false
            pickerTasks = planned
            return
        }
        pickerSource = .toDoList
        isLoadingPickerTasks = true
        let query = ToDoListQuery(page: ToDoPaging.firstPage,
                                  status: .notStarted,
                                  sortMode: .smart,
                                  projectId: appliedFilters.projectId)
        allApiObject.getToDoPage(query) { [weak self] page in
            DispatchQueue.main.async {
                self?.isLoadingPickerTasks = false
                self?.pickerTasks = FocusSessionStore.pickerTasks(from: page?.data)
            }
        }
    }

    /// Today's Day Plan rows, in the store's own order — the order the panel shows, which the user can
    /// drag. Deliberately not re-sorted: that order is the user's, not a score's.
    private static func dayPlanTasks() -> [FocusSessionPickerTask] {
        DayPlanTaskStore.shared.tasks(for: Date())
            .filter { !$0.done }
            .map { task in
                FocusSessionPickerTask(id: task.sourceTaskId ?? task.id,
                                       title: task.title,
                                       details: task.notes ?? "",
                                       durationSeconds: max(60, task.durationMinutes * 60),
                                       status: .notStarted,
                                       iconEmoji: task.iconEmoji,
                                       outcome: FocusSessionScoring.clamp(task.outcome ?? FocusSessionScoring.minimum),
                                       projectId: task.projectID,
                                       projectName: task.project)
            }
    }

    /// The block lists this session could switch to, excluding the one it is already running.
    /// Ordered as the user's own list is, which is the order they know them in.
    var switchableBlockLists: [(id: String, name: String)] {
        guard canChangeBlockList else { return [] }
        let currentId = currentRunningFocusType["id"] as? String ?? ""
        return arrFocusType.compactMap { mode in
            guard let id = mode["id"] as? String, !id.isEmpty, id != currentId else { return nil }
            let name = mode["name"] as? String ?? ""
            return (id: id, name: name.isEmpty ? strings.untitledFocusMode : name)
        }
    }

    /// Swap the running session's block list. The session keeps its clock, goal and task queue.
    func switchBlockList(toId id: String) {
        guard canChangeBlockList, let index = arrFocusType.firstIndex(where: { $0["id"] as? String == id }) else { return }
        guard switchRunningFocusMode(toIndex: index) else { return }
        refreshFromGlobals()
    }

    /// The project icon for a picker row, or nil while the catalogue is still loading.
    func projectIcon(for task: FocusSessionPickerTask) -> String? {
        FocusSessionProject.icon(for: task.projectId, name: task.projectName, in: projects)
    }

    /// The project icon for a queued task, which carries the project's name but not its id.
    func projectIcon(named name: String?) -> String? {
        FocusSessionProject.icon(for: nil, name: name, in: projects)
    }

    private func loadProjects() {
        guard projects.isEmpty else { return }
        allApiObject.getProjectsList { [weak self] result in
            DispatchQueue.main.async {
                self?.projects = FocusSessionProject.list(from: result)
            }
        }
    }

    // MARK: - Filters

    func presentFilters() {
        filterDraft = appliedFilters
        projectQuery = ""
        pickerPage = .filters
    }

    func toggleSpoonsFilter(_ band: FocusSessionSpoonsBand) {
        filterDraft.spoons = filterDraft.spoons == band ? nil : band
    }

    func toggleProjectFilter(_ id: String) {
        filterDraft.projectId = filterDraft.projectId == id ? nil : id
    }

    func setDueDateFilter(lowerDays: Int?, upperDays: Int?) {
        filterDraft.dueInDaysLowerBound = lowerDays
        filterDraft.dueInDaysUpperBound = upperDays
    }

    /// Commits the draft. A changed project filter re-queries, because that one is server-side.
    func applyFilters() {
        let projectChanged = filterDraft.projectId != appliedFilters.projectId
        appliedFilters = filterDraft
        pickerPage = .selectTasks
        if projectChanged { loadPickerTasks() }
    }

    func cancelFilters() {
        filterDraft = appliedFilters
        pickerPage = .selectTasks
    }

    // MARK: - Editing a task

    /// Resolve the queued ID before presenting an editable snapshot; cached titles cannot prove
    /// the task still exists. A missing snapshot leaves the queue intact and shows a retryable error.
    func editTask(id: String) {
        guard !isTaskEditingLocked else { return }
        guard tasks.contains(where: { $0.id == id }), let account = appdelegate?.user?.userId else { return }
        editGeneration += 1
        let token = editGeneration
        editSnapshot = nil; taskBeingEdited = nil; taskEditError = nil
        isLoadingPickerTasks = true
        allApiObject.getFocusSessionTaskResult(id: id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, token == self.editGeneration else { return }
                self.isLoadingPickerTasks = false
                guard appdelegate?.user?.userId == account,
                      !teacherSessionManagerObject.isTeacherSessionActive() else { return }
                guard let raw = try? result.get(), let edits = FocusSessionTaskSnapshot.edits(raw) else {
                    self.taskEditError = self.strings.taskLoadError(result); return
                }
                self.editSnapshot = raw; self.editAccountID = account
                self.beginEditing(FocusSessionPickerTask(id: id, title: edits.title, details: edits.details,
                    durationSeconds: edits.effectiveDurationMinutes * 60,
                    status: edits.status, outcome: edits.outcome, perspirationLevel: edits.perspirationLevel,
                    projectId: edits.projectId, dueDate: edits.dueDate, raw: raw))
            }
        }
    }

    private func beginEditing(_ task: FocusSessionPickerTask) {
        loadProjects()
        taskBeingEdited = task
        taskEdits = task.edits
        editFailed = false
        activeSheet = .editTask
    }

    /// Saves the edit through `PUT /to-do` and mirrors the new title/status into the session queue.
    func saveTaskEdits(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let task = taskBeingEdited, let previous = editSnapshot, taskEdits.isValid, !isSavingTask,
              !teacherSessionManagerObject.isTeacherSessionActive(), appdelegate?.user?.userId == editAccountID else { completion(false); return }
        isSavingTask = true
        editFailed = false
        taskEditError = nil
        let edits = taskEdits
        let account = editAccountID, token = editGeneration
        allApiObject.getFocusSessionTask(id: task.id) { [weak self] latest in
            DispatchQueue.main.async {
                guard let self = self else { completion(false); return }
                guard token == self.editGeneration, appdelegate?.user?.userId == account,
                      !teacherSessionManagerObject.isTeacherSessionActive(),
                      let latest = latest, FocusSessionTaskSnapshot.unchanged(latest, since: previous) else {
                    self.isSavingTask = false; self.taskEditError = self.strings.taskChanged; completion(false); return
                }
                let body = FocusSessionTaskUpsert.body(updating: latest, with: edits)
                allApiObject.upsertToDo(body: body) { [weak self] succeeded, json in
                    DispatchQueue.main.async {
                        guard let self = self, token == self.editGeneration else { completion(false); return }
                        self.isSavingTask = false
                        guard succeeded, appdelegate?.user?.userId == account else {
                            self.editFailed = true; completion(false); return
                        }
                        self.absorbSavedTask(json, fallbackId: task.id, edits: edits)
                        self.taskBeingEdited = nil; self.editSnapshot = nil; self.activeSheet = nil
                        completion(true)
                    }
                }
            }
        }
    }

    /// Reflects a saved to-do back into the picker cache and the session queue.
    /// Decodes the row `PUT /to-do` echoed back, so a saved task keeps the server's own values.
    private static func savedTask(from json: NSDictionary?) -> FocusSessionPickerTask? {
        guard let json = json,
              let data = try? JSONSerialization.data(withJSONObject: json),
              let task = try? JSONDecoder().decode(ToDoTask.self, from: data) else { return nil }
        return FocusSessionPickerTask.make(from: task)
    }

    private static func queueTask(fromSaved json: NSDictionary?) -> FocusSessionTask? {
        savedTask(from: json)?.asQueueTask
    }

    private func absorbSavedTask(_ json: NSDictionary?, fallbackId: String, edits: FocusSessionTaskEdits) {
        if let saved = FocusSessionStore.savedTask(from: json),
           let index = pickerTasks.firstIndex(where: { $0.id == saved.id }) {
            pickerTasks[index] = saved
        }
        let title = edits.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedQueueTask = FocusSessionStore.queueTask(fromSaved: json)
        var updated = tasks.map { task -> FocusSessionTask in
            guard task.id == fallbackId else { return task }
            var edited = savedQueueTask ?? task
            edited.isActive = task.isActive
            // A minimal response may omit project expansion. Resolve a changed native project from
            // the same catalogue used by the editor instead of retaining an unrelated old label.
            if edited.projectName == nil {
                edited.projectName = projects.first(where: { $0.id == edits.projectId })?.name
            }
            edited.title = title
            edited.details = edits.details
            edited.status = edits.status
            edited.durationSeconds = edits.effectiveDurationMinutes * 60
            if edits.status.isCompleted { edited.isActive = false }
            return edited
        }
        // Completing the task from the edit sheet has to hand the session on, like the queue menu does.
        if edits.status.isCompleted, FocusSessionTaskQueue.activeTask(in: updated) == nil,
           let next = updated.first(where: { !$0.status.isCompleted }) {
            updated = FocusSessionTaskQueue.focusing(updated, on: next.id)
        }
        apply(updated)
        loadActiveSubtasks(force: true)
    }

    func runPickerSearch() {
        let query = pickerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { loadPickerTasks(); return }
        isLoadingPickerTasks = true
        // The search endpoint ranks by title match and ignores sort_mode, so the results are put back
        // into the list's own SMART order client-side.
        pickerSource = .search
        allApiObject.searchToDoTasks(title: query) { [weak self] tasks in
            DispatchQueue.main.async {
                self?.isLoadingPickerTasks = false
                self?.pickerTasks = FocusSessionStore.pickerTasks(from: tasks)
            }
        }
    }

    func togglePickerSelection(_ id: String) {
        if selectedPickerTaskIds.contains(id) {
            selectedPickerTaskIds.remove(id)
        } else {
            selectedPickerTaskIds.insert(id)
        }
    }

    /// Adds the ticked to-dos to the session queue and mirrors them into the To Do Player.
    func queueSelectedTasks() {
        let additions = pickerTasks
            .filter { selectedPickerTaskIds.contains($0.id) }
            .map { $0.asQueueTask }
        guard !additions.isEmpty else { return }
        for task in additions {
            taskPlayerVcObj?.addTaskInCurrentList(taskName: task.title,
                                                  id: task.id,
                                                  duration: task.durationSeconds)
        }
        apply(FocusSessionTaskQueue.appending(tasks, newTasks: additions))
        activeSheet = nil
    }

    /// Creates a brand-new to-do (`PUT /to-do` with no id) and queues it. Uses the same body builder
    /// as the edit sheet so a created task and an edited one carry the same fields.
    func createTask(_ edits: FocusSessionTaskEdits, completion: @escaping (Bool) -> Void) {
        guard edits.isValid else { completion(false); return }
        isSavingTask = true
        editFailed = false
        let title = edits.title.trimmingCharacters(in: .whitespacesAndNewlines)
        addLog(text: "focus session: create task \(title)")
        allApiObject.upsertToDo(body: FocusSessionTaskUpsert.creationBody(with: edits)) { [weak self] succeeded, json in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSavingTask = false
                guard succeeded, let id = json?.value(forKey: FocusSessionToDoKey.id) as? String else {
                    self.editFailed = true
                    completion(false)
                    return
                }
                let task = FocusSessionStore.queueTask(fromSaved: json)
                    ?? FocusSessionTask(id: id, title: title, details: edits.details,
                                        durationSeconds: edits.effectiveDurationMinutes * 60)
                taskPlayerVcObj?.addTaskInCurrentList(taskName: task.title,
                                                      id: task.id,
                                                      duration: task.durationSeconds)
                self.apply(FocusSessionTaskQueue.appending(self.tasks, newTasks: [task]))
                self.activeSheet = nil
                completion(true)
            }
        }
    }

    /// A task added to the current focus session is due today.
    var newTaskDraft: FocusSessionTaskEdits {
        // #2571 (17): carry the text typed in the picker's search field over as the new task's title,
        // so tapping "Create new task" after searching for a name that isn't found pre-fills that name
        // instead of opening a blank form.
        let typedName = pickerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return FocusSessionTaskEdits(title: typedName, dueDate: defaultNewTaskDueDate)
    }

    /// The default due date the create sheet opens on.
    var defaultNewTaskDueDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Maps and orders a page of to-dos with the app's canonical comparator, so this picker shows the
    /// same order as the Day Plan picker and the native To-do list.
    private static func pickerTasks(from tasks: [ToDoTask]?) -> [FocusSessionPickerTask] {
        let source = tasks ?? []
        let rows = source.compactMap { FocusSessionPickerTask.make(from: $0) }
        return FocusSessionTaskFilter.ordered(rows, sourceTasks: source)
    }
}
