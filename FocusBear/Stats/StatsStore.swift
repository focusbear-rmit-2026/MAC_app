//
//  StatsStore.swift
//  Focus Bear
//
//  State for the native Stats screen: the tab strip plus the smaller tabs (Streak, Progress, Your
//  Goals, Pep Talk, Leaderboard). Habit Stats and the focus tabs have their own stores. Behaviour
//  follows the web's `DeviceStatsUI` — a tab loads the first time it is visited, and every open of
//  the screen reloads (the webview reloaded the page on each open).
//

import Foundation

enum StatsTab: String, CaseIterable, Identifiable {
    case goals, progress, streak, pepTalk, leaderboard, habitStats, productivity, focusLog
    var id: String { rawValue }
    /// Web `STATS_TAB_INDICES.STREAK` is the default selection.
    static let defaultTab = StatsTab.streak

    func title(_ strings: StatsStrings) -> String {
        switch self {
        case .goals: return strings.tabGoals
        case .progress: return strings.tabProgress
        case .streak: return strings.tabStreak
        case .pepTalk: return strings.tabPepTalk
        case .leaderboard: return strings.tabLeaderboard
        case .habitStats: return strings.tabHabitStats
        case .productivity: return strings.tabProductivity
        case .focusLog: return strings.tabFocusLog
        }
    }

    var systemImage: String {
        switch self {
        case .goals: return "target"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .streak: return "bolt.fill"
        case .pepTalk: return "sparkles"
        case .leaderboard: return "person.3.fill"
        case .habitStats: return "rosette"
        case .productivity: return "chart.bar.fill"
        case .focusLog: return "list.bullet.rectangle"
        }
    }
}

final class StatsStore: ObservableObject {
    private static let selectedTabKey = "kUserdefaultsStatsSelectedTab"

    let strings: StatsStrings
    /// The Stats tool remembers the last tab; the routine-start screen always opens on Pep Talk.
    private let remembersSelectedTab: Bool
    @Published var selectedTab: StatsTab {
        didSet {
            if remembersSelectedTab {
                UserDefaults.standard.set(selectedTab.rawValue, forKey: StatsStore.selectedTabKey)
            }
            loadIfNeeded(selectedTab)
        }
    }

    let onboarding: OnboardingStatsStore
    let goals: LongTermGoalsStore
    let pepTalk: PepTalkStore
    let leaderboard: LeaderboardStore
    let habitStats: HabitStatsStore
    let productivity: ProductivityStore
    let focusLog: FocusLogStore

    private var loadedTabs = Set<StatsTab>()

    /// `initialTab` fixes the opening tab (and turns off remembering it); nil restores the last-used tab.
    init(strings: StatsStrings, initialTab: StatsTab? = nil) {
        self.strings = strings
        onboarding = OnboardingStatsStore()
        goals = LongTermGoalsStore(strings: strings)
        pepTalk = PepTalkStore()
        leaderboard = LeaderboardStore()
        habitStats = HabitStatsStore()
        productivity = ProductivityStore()
        focusLog = FocusLogStore(strings: strings)
        remembersSelectedTab = initialTab == nil
        let saved = UserDefaults.standard.string(forKey: StatsStore.selectedTabKey).flatMap(StatsTab.init(rawValue:))
        selectedTab = initialTab ?? saved ?? StatsTab.defaultTab
    }

    /// Reload every tab the next time it is shown (called from `viewWillAppear`).
    func screenAppeared() {
        loadedTabs = []
        loadIfNeeded(selectedTab)
    }

    func screenDisappeared() {
        pepTalk.cancel()
    }

    private func loadIfNeeded(_ tab: StatsTab) {
        guard loadedTabs.insert(tab).inserted else { return }
        switch tab {
        case .streak, .progress: onboarding.load()
        case .goals: goals.load()
        case .pepTalk: pepTalk.load()
        case .leaderboard: leaderboard.load()
        case .habitStats: habitStats.load()
        case .productivity: productivity.load()
        case .focusLog: focusLog.load()
        }
    }
}

// MARK: - Streak + Progress

final class OnboardingStatsStore: ObservableObject {
    @Published private(set) var stats: OnboardingStats?
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false
    /// The level header the user tapped to preview (nil = the current level).
    @Published var previewLevel: Int?
    @Published var showsNextLevels = false

    var displayedLevel: Int { previewLevel ?? stats?.level ?? 0 }

    func load() {
        isLoading = true
        hasError = false
        allApiObject.getOnboardingStats { [weak self] stats in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.hasError = stats == nil
                if let stats = stats {
                    self?.stats = stats
                    self?.previewLevel = nil
                }
            }
        }
    }
}

// MARK: - Your Goals

final class LongTermGoalsStore: ObservableObject {
    static let statusMessageSeconds: TimeInterval = 3

    let strings: StatsStrings
    @Published var goals: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var hasError = false
    @Published private(set) var statusMessage: String?
    private var savedGoals: [String] = []

    init(strings: StatsStrings) { self.strings = strings }

    var hasUnsavedChanges: Bool { goals != savedGoals }

    func load() {
        isLoading = true
        hasError = false
        allApiObject.getLongTermGoals { [weak self] goals in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.hasError = goals == nil
                if let goals = goals {
                    self?.goals = goals
                    self?.savedGoals = goals
                }
            }
        }
    }

    func addGoal() { goals.append("") }

    func removeGoal(at index: Int) {
        guard goals.indices.contains(index) else { return }
        goals.remove(at: index)
    }

    func save() {
        let cleaned = goals.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        isSaving = true
        allApiObject.updateLongTermGoals(cleaned) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSaving = false
                if success {
                    self.goals = cleaned
                    self.savedGoals = cleaned
                }
                self.showStatus(success ? self.strings.goalsSaved : self.strings.goalsSaveFailed)
            }
        }
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + LongTermGoalsStore.statusMessageSeconds) { [weak self] in
            if self?.statusMessage == message { self?.statusMessage = nil }
        }
    }
}

// MARK: - Pep Talk

final class PepTalkStore: ObservableObject {
    /// Web `AiToneOptions`, in the order the tone buttons appear.
    static let tones = ["humorous", "sassy", "court jester", "pirate", "future self in twenty years",
                        "scientist", "cheerleader", "upbeat", "factual"]

    @Published private(set) var tone = PepTalkStore.tones[0]
    @Published private(set) var text = ""
    @Published private(set) var isStreaming = false
    @Published private(set) var failed = false
    private var stream: MotivationalSummaryStream?

    /// Web picks a random tone on mount.
    func load() {
        select(tone: PepTalkStore.tones.randomElement() ?? tone)
    }

    func select(tone: String) {
        self.tone = tone
        cancel()
        text = ""
        failed = false
        isStreaming = true
        let stream = MotivationalSummaryStream(onChunk: { [weak self] chunk in
            self?.text += chunk
        }, onFinish: { [weak self] succeeded in
            self?.isStreaming = false
            self?.failed = !succeeded
        })
        self.stream = stream
        stream.start(tone: tone, language: currentLanguageCode.isEmpty ? "en" : currentLanguageCode)
    }

    func cancel() {
        stream?.cancel()
        stream = nil
        isStreaming = false
    }

    /// Stop streaming and clear the message (the routine-start screen's old `about:blank` reload).
    func reset() {
        cancel()
        text = ""
        failed = false
    }
}

// MARK: - Leaderboard

final class LeaderboardStore: ObservableObject {
    /// Web validates the username against `/^[A-Za-z_]*$/`.
    private static let allowedUsernameCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_")

    @Published private(set) var response: LeaderboardResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false
    /// The server ranks (and picks the top N) by `streak_type`, so a sort change refetches; the rows
    /// are then ordered locally by that column's percentage (`LeaderboardSorting`).
    @Published var sortKey = LeaderboardSortKey.morning {
        didSet { if sortKey != oldValue { load() } }
    }
    @Published var ascending = false
    @Published var expandedUserId: String?
    @Published var usernameDraft = ""
    @Published private(set) var isSavingUsername = false
    private var savedUsername = ""

    var users: [LeaderboardUser] {
        LeaderboardSorting.sort(response?.usersRankings ?? [], by: sortKey, ascending: ascending)
    }

    /// A refetch for a new sort key while the previous table is still on screen.
    var isReloading: Bool { isLoading && response != nil }

    var currentUserId: String? { response?.userRank?.id }

    var isUsernameValid: Bool {
        !usernameDraft.isEmpty && usernameDraft.unicodeScalars.allSatisfy { LeaderboardStore.allowedUsernameCharacters.contains($0) }
    }

    var canUpdateUsername: Bool { isUsernameValid && usernameDraft != savedUsername && !isSavingUsername }

    func load() {
        isLoading = true
        hasError = false
        let requestedKey = sortKey
        allApiObject.getLeaderboard(limit: StatsRequestLimits.leaderboardLimit, streakType: requestedKey.rawValue) { [weak self] response in
            DispatchQueue.main.async {
                guard let self = self, requestedKey == self.sortKey else { return }
                self.isLoading = false
                self.hasError = response == nil
                guard let response = response else { return }
                self.response = response
                self.savedUsername = response.userRank?.username ?? ""
                self.usernameDraft = self.savedUsername
            }
        }
    }

    func toggleExpanded(_ user: LeaderboardUser) {
        expandedUserId = expandedUserId == user.id ? nil : user.id
    }

    func saveUsername() {
        guard canUpdateUsername else { return }
        isSavingUsername = true
        let username = usernameDraft
        allApiObject.updateUsername(username) { [weak self] success in
            DispatchQueue.main.async {
                self?.isSavingUsername = false
                guard success else { return }
                self?.savedUsername = username
                self?.load()
            }
        }
    }
}
