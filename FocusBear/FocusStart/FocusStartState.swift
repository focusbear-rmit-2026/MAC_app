//
//  FocusStartState.swift
//  Focus Bear
//
//  The state behind the focus-session start screens. It is what the old storyboard outlets were:
//  `pomodoroVc`/`simplePomodoroVc` used to read `textFieldWorkDuration.integerValue`,
//  `sliderStrictness.integerValue`, `popUpBtnFocusType.indexOfSelectedItem` and friends straight off
//  the nib; they now read the same values from here. The start logic itself (validation, the
//  permissions gate, the postpone-extension flow, `pomodoroModeStarted()`) deliberately stayed in the
//  controllers, so swapping the UI could not silently change what happens when a session starts.
//

import Foundation
import Combine

/// One row of the block-list dropdown, flattened out of `arrFocusTypeForPomodoro` so the view never
/// touches the app's `[String: Any]` dictionaries.
struct FocusStartBlockList: Identifiable, Equatable {
    let id: String
    let name: String
    /// Apps + websites this list acts on, for the design's "12 apps/websites" subtitle.
    let itemCount: Int
    /// This list's own focus-alignment-score threshold, or nil to fall back to the app default.
    let focusAlignmentScoreThreshold: Int?
    let lastIntentionUsed: String
    let lastDurationUsedMinutes: Int?
    let isDefault: Bool
    let isRelaxFocus: Bool
    var isAIEnabled: Bool = true
}

/// Observable state shared by the simple and advanced start screens and their hosting controllers.
final class FocusStartState: ObservableObject {

    // MARK: - What the user is choosing

    @Published var duration = FocusStartDuration(minutes: FocusStartDuration.defaultMinutes)
    @Published var breakDurationMinutes = 5
    @Published var goal = ""
    // Compatibility input used by the simple controller's existing quick-task path.
    @Published var firstTask = ""
    @Published var projects: [Project] = []
    @Published var isEditingGoal = false
    @Published var isTaskSearchExpanded = false
    @Published var selectedProjectID: String?
    @Published var projectQuery = ""
    @Published var taskQuery = "" { didSet { scheduleTaskSearch() } }
    @Published var suggestedTasks: [ToDoTask] = []
    @Published var selectedTasks: [ToDoTask] = []
    @Published var isLoadingProjects = false
    @Published var isLoadingTasks = false
    @Published var workChoiceError: String?
    @Published var hasMoreTasks = false
    @Published var blockListQuery = ""
    @Published var breakFrequencyMinutes = max(1, breakAfterMinutes > 0 ? breakAfterMinutes : 60)
    var hasChosenGoal = false
    var shouldResetWorkChoicesOnNextOpen = false
    var isContinuingSuperFocusRun = false
    var taskSelectionChanged = false
    private var workAccountID: String?
    private var projectGeneration = 0
    private var taskGeneration = 0
    private var taskPage = 0
    private var pendingTaskSearch: DispatchWorkItem?
    @Published var selectedBlockListIndex = 0
    @Published var strictness = FocusStartStrictness.junior
    @Published var isAiBlockingOn = true
    @Published var isMicroBreaksOn = true
    @Published var isSuperFocusOn = false
    @Published var superFocusSessionCount = 2
    @Published var focusAlignmentScore = defaultFocusAlignmentScoreToShowDistractingPopUp

    // MARK: - What the screen is allowed to show

    @Published var blockLists: [FocusStartBlockList] = []
    @Published var expandedCard = FocusStartCard.duration

    /// #2571 (7): let a card's chevron both expand and collapse. The accordion keeps its "exactly one
    /// open" invariant — clicking the already-open card collapses it back to the first card
    /// (`.duration`), which is the home state the screen opens in — so there's never a "nothing open"
    /// state for the bear panel to describe. Clicking a different card just opens it, as before.
    func toggleCard(_ card: FocusStartCard) {
        expandedCard = (expandedCard == card) ? .duration : card
    }
    /// #2449: break settings are a collapsible section inside the duration card, collapsed by default
    /// so the card leads with the session length.
    @Published var isBreakSettingsExpanded = false
    /// Super Focus locks the duration, the block list and the strictness for its whole run.
    @Published var isDurationEditable = true
    @Published var isBlockListEditable = true
    @Published var isStrictnessEditable = true
    @Published var isSuperFocusEditable = true
    @Published var isStartEnabled = true
    /// `kUserdefaultsIsAdvancedPomodoroEnabled` — gates Super Focus and the alignment-score row, the
    /// same way the old "Show advanced options" switch did.
    @Published var isAdvancedOptionsEnabled = false
    @Published var isFocusAlignmentScoreVisible = false
    @Published var isExpired = false

    // MARK: - Banners

    /// Non-nil when the browser-permissions banner should show; the string is the explanatory tip.
    @Published var permissionsTip: String?
    /// Non-nil when a super-strict blocking schedule is constraining this screen.
    @Published var blockingScheduleNotice: String?
    /// Non-nil while a custom blocking schedule is blocking right now — "<NAME> is blocking until
    /// <TIME>". Purely informational: a schedule is not a focus session, so it must not stop one being
    /// started (report 2026-09-16_15-13-57), but the person does need to see that blocking is on.
    @Published var activeBlockingScheduleText: String?
    /// "You have completed 1 of 4 pomodoros…", only during a Super Focus run.
    @Published var superFocusProgress: String?
    /// The "Time spent unfocused" counter; empty hides the line.
    @Published var unfocusedTimerText = ""
    /// Set while the screen was reached by postponing a routine, when the headline becomes "What do
    /// you want to do instead of your habits?" instead of the design's fixed title.
    @Published var postponeTitle: String?

    let strings: FocusStartStrings
    let todoStrings: ToDoStrings
    private let dayPlanTasks: () -> [DayPlanTask]

    /// Read-only inputs let visual fixtures render the real screen without loading user data.
    init(strings: FocusStartStrings = .load(), todoStrings: ToDoStrings = .load(),
         dayPlanTasks: @escaping () -> [DayPlanTask] = {
             DayPlanTaskStore.shared.incompleteTasksInDisplayOrder(for: Date())
         }) {
        self.strings = strings
        self.todoStrings = todoStrings
        self.dayPlanTasks = dayPlanTasks
    }

    // MARK: - Actions the view raises back to its controller

    var onStart: () -> Void = {}
    var onEditBlockLists: () -> Void = {}
    var onEditBlockList: (String) -> Void = { _ in }
    var onFixPermissions: () -> Void = {}
    var onSwitchMode: () -> Void = {}
    var onBlockListChanged: () -> Void = {}
    var onAiBlockingBlockedByTrial: () -> Void = {}

    // MARK: - Derived text

    private var summaryBuilder: FocusStartSummaryBuilder { FocusStartSummaryBuilder(strings: strings) }
    var durationFormatter: FocusStartDurationFormatter { FocusStartDurationFormatter(strings: strings) }

    var selectedBlockList: FocusStartBlockList? {
        guard selectedBlockListIndex >= 0, selectedBlockListIndex < blockLists.count else { return nil }
        return blockLists[selectedBlockListIndex]
    }

    var durationSummary: String {
        if duration.isUntimed && isMicroBreaksOn { return strings.untimedSummary + " · " + breakSettingsSummary }
        return summaryBuilder.durationSummary(duration: duration, breakCount: microBreakCount)
    }

    var goalSummary: String {
        summaryBuilder.goalSummary(goal: goal, taskCount: selectedTasks.count)
    }

    var blockingSummary: String {
        summaryBuilder.blockingSummary(blockListName: selectedBlockList?.name ?? "", strictness: strictness)
    }

    /// "3 min breaks · Micro-breaks on" — shown on the break-settings header in both states, so
    /// collapsing the section never hides a setting the user has changed.
    var breakSettingsSummary: String {
        guard isMicroBreaksOn else { return strings.microBreaksOffSummary }
        return strings.breakFrequencySummary.replacingOccurrences(of: FocusStartPlaceholder.count,
                                                                  with: "\(breakFrequencyMinutes)")
    }

    /// A break at the session end is outside the work period. Untimed sessions show cadence instead.
    var microBreakCount: Int {
        guard isMicroBreaksOn, !duration.isUntimed else { return 0 }
        return max(0, (duration.minutes - 1) / max(1, breakFrequencyMinutes))
    }

    var startButtonTitle: String {
        durationFormatter.startButtonTitle(for: duration)
    }


    // MARK: - Project and to-do selection

    var canChooseDayPlanDefault: Bool {
        // #2571 (5): never override an existing goal with the auto-selected top Day Plan project. A
        // postpone intention sets `goal` before the async project fetch returns (and before
        // `hasChosenGoal` is stamped), so without the `goal.isEmpty` check the callback replaced the
        // typed intention with the project name.
        !hasChosenGoal && !isEditingGoal
            && goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && projectQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && taskQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedTasks.isEmpty
    }
    var selectedProject: Project? { projects.first { $0.id == selectedProjectID } }
    var showsProjectSearch: Bool { isEditingGoal || goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var showsTaskSearch: Bool { selectedTasks.isEmpty || isTaskSearchExpanded }

    func editGoal() { hasChosenGoal = true; isEditingGoal = true; projectQuery = goal }
    func clearGoal() {
        goal = ""; selectedProjectID = nil; selectedTasks = []
        hasChosenGoal = true; taskSelectionChanged = true; isEditingGoal = true; isTaskSearchExpanded = false
        projectQuery = ""; taskQuery = ""
        loadTaskSuggestions()
    }
    var visibleProjects: [Project] {
        let query = projectQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let ordered = FocusStartWorkSelection.projects(projects,
            dayPlan: dayPlanTasks())
        return query.isEmpty ? ordered : ordered.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    var visibleTaskSuggestions: [ToDoTask] {
        let selected = Set(selectedTasks.map { $0.id })
        return suggestedTasks.filter { !$0.isCompleted && !selected.contains($0.id) }
    }
    var taskQueueForSessionStart: String {
        FocusStartWorkSelection.queueForSessionStart(chosen: sessionTaskQueue,
                                                     runningQueue: focusModeTaskString,
                                                     isContinuingRun: isContinuingSuperFocusRun,
                                                     hasChangedSelection: taskSelectionChanged)
    }
    var sessionTaskQueue: String {
        FocusStartWorkSelection.sessionQueue(selectedTasks, projects: projects)
    }

    func loadWorkChoices() {
        let account = appdelegate?.user?.userId
        if account != workAccountID {
            if workAccountID != nil {
                selectedProjectID = nil; selectedTasks = []; projects = []; suggestedTasks = []
                isEditingGoal = false; isTaskSearchExpanded = false
                goal = ""; projectQuery = ""; taskQuery = ""; hasChosenGoal = false
            }
            taskGeneration += 1
            workAccountID = account
        }
        guard account != nil else { return }
        projectGeneration += 1
        let generation = projectGeneration
        isLoadingProjects = true
        allApiObject.getAllActiveProjects { [weak self] projects in
            DispatchQueue.main.async {
                guard let self = self, self.projectGeneration == generation,
                      self.workAccountID == account, appdelegate?.user?.userId == account else { return }
                self.isLoadingProjects = false
                guard let projects = projects else { self.workChoiceError = self.strings.workChoicesUnavailable; return }
                self.projects = projects
                if self.canChooseDayPlanDefault,
                   let first = FocusStartWorkSelection.topDayPlanProject(projects,
                       dayPlan: self.dayPlanTasks()) {
                    self.selectProject(first, automatic: true)
                } else { self.loadTaskSuggestions() }
            }
        }
    }

    func selectProject(_ project: Project, automatic: Bool = false) {
        selectedProjectID = project.id
        isEditingGoal = false; isTaskSearchExpanded = false
        goal = project.name
        projectQuery = ""
        hasChosenGoal = !automatic
        if !automatic { selectedTasks.removeAll(); taskSelectionChanged = true }
        taskQuery = ""
        loadTaskSuggestions()
    }

    func useCustomGoal() {
        let value = projectQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        goal = value; selectedProjectID = nil; hasChosenGoal = true
        isEditingGoal = false; isTaskSearchExpanded = false
        projectQuery = ""; selectedTasks.removeAll(); taskQuery = ""; taskSelectionChanged = true
        loadTaskSuggestions()
    }

    /// Queue a task for the session. Adding one used to collapse the search back to an "Add more tasks"
    /// link, so building a list of three tasks cost two extra clicks (report 2026-09-17_13-52-53).
    /// Picking a task is a signal the user is still choosing, so the search stays open — and the query
    /// is cleared, because the words that found this task only narrow the list away from the next one.
    /// `hideTaskSearch()` is how the user closes it once they are done.
    func selectTask(_ task: ToDoTask) {
        guard !task.isCompleted, !selectedTasks.contains(where: { $0.id == task.id }) else { return }
        selectedTasks.append(task)
        isTaskSearchExpanded = true
        // Assigning re-runs the debounced search, so only pay for it when there is a query to clear.
        if !taskQuery.isEmpty { taskQuery = "" }
        hasChosenGoal = true; taskSelectionChanged = true
    }

    /// Collapse the task search once the user has what they want, back to the "Add more tasks" link.
    func hideTaskSearch() { isTaskSearchExpanded = false }

    func removeSelectedTask(_ id: String) {
        selectedTasks.removeAll { $0.id == id }
        taskSelectionChanged = true
    }

    func loadTaskSuggestions(more: Bool = false) {
        pendingTaskSearch?.cancel()
        taskGeneration += 1
        let generation = taskGeneration
        guard let account = workAccountID, appdelegate?.user?.userId == account else {
            isLoadingTasks = false
            return
        }
        let page = more ? taskPage + 1 : 1
        if !more { suggestedTasks = []; taskPage = 0 }
        isLoadingTasks = true; workChoiceError = nil
        let project = selectedProject
        let query = taskQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let receive: ([ToDoTask]?, Bool) -> Void = { [weak self] tasks, hasMore in
            DispatchQueue.main.async {
                guard let self = self, self.taskGeneration == generation,
                      appdelegate?.user?.userId == account else { return }
                self.isLoadingTasks = false
                guard let tasks = tasks else { self.workChoiceError = self.strings.workChoicesUnavailable; return }
                let previous = more ? self.suggestedTasks : []
                let known = Set(previous.map { $0.id })
                self.suggestedTasks = FocusStartWorkSelection.tasks(previous + tasks.filter { !known.contains($0.id) },
                    project: project, dayPlan: self.dayPlanTasks())
                self.hasMoreTasks = hasMore; self.taskPage = page
            }
        }
        if !query.isEmpty {
            // Search the to-do catalogue, keeping selected-project matches at the top.
            allApiObject.searchToDoTasks(title: query) { receive($0, false) }
        } else {
            let request = ToDoListQuery(page: page, status: nil, sortMode: .smart,
                projectId: project?.isSynced == true ? nil : project?.id,
                syncedProjectId: project?.synced_project_id)
            allApiObject.getToDoPage(request) { receive($0?.data, $0?.meta?.hasNextPage ?? false) }
        }
    }

    private func scheduleTaskSearch() {
        pendingTaskSearch?.cancel()
        taskGeneration += 1 // Immediately invalidate a request for text that is no longer visible.
        let work = DispatchWorkItem { [weak self] in self?.loadTaskSuggestions() }
        pendingTaskSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    // MARK: - Seeding from the app's globals

    /// Rebuilds the block-list rows from `arrFocusTypeForPomodoro` (which `pomodoroVc` fills from
    /// `HiddenFocusModeManager.visibleFocusModes`) and keeps the current selection where it can.
    /// Number of apps/websites a block list actually contains — mirrors BlockListStore.storedUrls/Apps
    /// so the row count matches the editor: relax modes block nothing; the Default mode uses the app-wide
    /// "super distracting" list; allow-list modes count allowed_*; everything else counts its own
    /// blockUrlsArray/blockAppsArray. Previously every blocked list showed the same global count. (#2602)
    static func blockListItemCount(_ focusMode: [String: Any]) -> Int {
        if focusMode["isRelaxFocus"] as? Bool == true { return 0 }
        if focusMode["isDefault"] as? Bool == true {
            return SettingsManagerObject.arrBlockedUrls.count + SettingsManagerObject.arrBlockedApps.count
        }
        if focusMode["isAllowedListApproach"] as? Bool == true {
            return ((focusMode["allowed_urls"] as? [Any])?.count ?? 0) + ((focusMode["allowed_apps"] as? [Any])?.count ?? 0)
        }
        return ((focusMode["blockUrlsArray"] as? [Any])?.count ?? 0) + ((focusMode["blockAppsArray"] as? [Any])?.count ?? 0)
    }

    func reloadBlockLists(selectedId: String?) {
        blockLists = arrFocusTypeForPomodoro.map { focusMode in
            return FocusStartBlockList(
                id: focusMode["id"] as? String ?? "",
                name: focusMode["name"] as? String ?? "",
                itemCount: Self.blockListItemCount(focusMode),
                focusAlignmentScoreThreshold: focusMode["focusAlignmentScoreThreshold"] as? Int,
                lastIntentionUsed: focusMode["lastIntentionUsed"] as? String ?? "",
                lastDurationUsedMinutes: focusMode["lastDurationUsed"] as? Int,
                isDefault: focusMode["isDefault"] as? Bool ?? false,
                isRelaxFocus: focusMode["isRelaxFocus"] as? Bool ?? false,
                isAIEnabled: focusMode["is_ai_enabled"] as? Bool ?? true
            )
        }
        if let selectedId = selectedId,
           let index = blockLists.firstIndex(where: { $0.id == selectedId }) {
            selectedBlockListIndex = index
        } else if selectedBlockListIndex >= blockLists.count {
            selectedBlockListIndex = 0
        }
    }

    /// Mirrors the break-duration ratio the old screen recomputed on every keystroke of the work
    /// field: break = work / workRatio * breakRatio, never below one minute.
    func recomputeBreakDuration(workRatio: Int, breakRatio: Int) {
        let safeWorkRatio = max(1, workRatio)
        let safeBreakRatio = max(1, breakRatio)
        let computed = Int((Double(duration.minutes) / Double(safeWorkRatio)) * Double(safeBreakRatio))
        breakDurationMinutes = max(1, computed)
    }

    /// The duration this block list should default to: its own last-used duration, else the last
    /// duration used for any block list, else 20 — the #777 rule the old screen implemented.
    func defaultDurationMinutes(forBlockListAt index: Int) -> Int {
        if index >= 0, index < blockLists.count,
           let perMode = blockLists[index].lastDurationUsedMinutes, perMode > 0 {
            return perMode
        }
        let lastAny = UserDefaults.standard.integer(forKey: kUserdefaultsLastFocusModeMinutes)
        return lastAny > 0 ? lastAny : 20
    }

    /// The user tapped the "AI Enabled" badge. This is the old simple screen's AI-blocking radio: on a
    /// lapsed trial it refuses and shows the upgrade nag instead of flipping (the money-affecting
    /// half of that gate), otherwise it toggles the app's AI URL checking for the session.
    func toggleAiBlocking() {
        guard !isExpired else {
            onAiBlockingBlockedByTrial()
            return
        }
        isAiBlockingOn.toggle()
    }
}
