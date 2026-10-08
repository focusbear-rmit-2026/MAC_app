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

/// The last pep talk that arrived, kept so an automatic screen appearance can show it again
/// instead of generating a new one.
///
/// Every pep talk is an LLM call against a per-user budget the backend caps at 60 a day
/// (`@Throttle` on `GET /user/motivational-summary`). The routine screen builds a FRESH
/// `StatsStore` each time it appears, so each appearance spent one — 57, 60, 49 and 48 on
/// consecutive days from a single Mac, which is the entire budget. The user then met a 429 while
/// doing nothing unusual, and the screen invited them to press Retry (report
/// 2026-09-22_07-45-26).
///
/// Static because the store it serves is rebuilt on every appearance; instance state cannot outlive
/// the thing that causes the problem.
enum PepTalkCache {

    /// How long a message stays worth showing again. Long enough that a routine with several steps
    /// costs one call rather than several; short enough that coming back later still feels fresh.
    /// This is a product judgement, not a derived constant — it is the number to change if pep talks
    /// start feeling stale.
    static let reuseWindow: TimeInterval = 30 * 60

    private static var cachedText = ""
    private static var cachedTone = ""
    private static var cachedLanguage = ""
    private static var cachedAt: Date?

    /// Whether something cached at `cachedAt` may still be shown at `now`.
    static func isFresh(cachedAt: Date?, now: Date, window: TimeInterval = reuseWindow) -> Bool {
        guard let cachedAt else { return false }
        let age = now.timeIntervalSince(cachedAt)
        // A cache stamped in the FUTURE means the clock moved; treat it as stale rather than
        // trusting it for the next half hour.
        return age >= 0 && age < window
    }

    /// The message to reuse for `language`, or nil when there is nothing worth reusing.
    static func reusable(language: String, now: Date = Date()) -> (text: String, tone: String)? {
        guard isFresh(cachedAt: cachedAt, now: now), !cachedText.isEmpty,
              cachedLanguage == language else { return nil }
        return (cachedText, cachedTone)
    }

    static func store(text: String, tone: String, language: String, now: Date = Date()) {
        guard !text.isEmpty else { return }
        cachedText = text; cachedTone = tone; cachedLanguage = language; cachedAt = now
    }

    /// Used by tests, and when signing out — one account's pep talk is not another's.
    static func clear() {
        cachedText = ""; cachedTone = ""; cachedLanguage = ""; cachedAt = nil
    }
}

final class PepTalkStore: ObservableObject {
    /// Web `AiToneOptions`, in the order the tone buttons appear.
    static let tones = ["humorous", "sassy", "court jester", "pirate", "future self in twenty years",
                        "scientist", "cheerleader", "upbeat", "factual"]

    @Published private(set) var tone = PepTalkStore.tones[0]
    @Published private(set) var text = ""
    @Published private(set) var isStreaming = false
    @Published private(set) var failed = false
    private var stream: MotivationalSummaryStream?
    private var generation = 0

    /// Called when the screen appears — which, on the routine screen, is every appearance.
    ///
    /// Shows a recent pep talk when there is one rather than generating another. A DELIBERATE action
    /// (tapping a tone, pressing Retry) still streams: the point is to stop spending the daily
    /// budget on appearances the user did not ask for.
    func load() {
        let language = currentLanguageCode.isEmpty ? "en" : currentLanguageCode
        if let reusable = PepTalkCache.reusable(language: language) {
            tone = reusable.tone
            text = reusable.text
            failed = false
            failure = nil
            isStreaming = false
            return
        }
        select(tone: PepTalkStore.tones.randomElement() ?? tone)
    }

    /// A tone the user chose, or a retry. Always streams.
    func select(tone: String) {
        self.tone = tone
        cancel()
        text = ""
        failed = false
        isStreaming = true
        let token = generation
        let stream = MotivationalSummaryStream(onChunk: { [weak self] chunk in
            guard let self = self, self.generation == token else { return }
            self.text += chunk
        }, onFinish: { [weak self] succeeded, failure in
            guard let self = self, self.generation == token else { return }
            self.isStreaming = false
            if succeeded {
                PepTalkCache.store(text: self.text, tone: self.tone,
                                   language: currentLanguageCode.isEmpty ? "en" : currentLanguageCode)
            }
            self.failed = !succeeded
            self.failure = failure
            // Hold Retry for as long as the server asked. Pressing it during a rate limit cannot
            // work, and offering the button anyway is what produced five 429s in two minutes
            // (report 2026-09-22_07-45-26).
            if let delay = failure?.retryDelay {
                self.retryAvailableAt = Date().addingTimeInterval(delay)
            } else {
                self.retryAvailableAt = nil
            }
        })
        self.stream = stream
        stream.start(tone: tone, language: currentLanguageCode.isEmpty ? "en" : currentLanguageCode)
    }

    /// Why the last attempt failed, so the message can say something truer than "try again later".
    @Published private(set) var failure: PepTalkFailure?

    /// When Retry becomes useful again; nil when it is useful now.
    @Published private(set) var retryAvailableAt: Date?

    /// Whether the last failure was the server asking us to slow down.
    var isRateLimited: Bool {
        if case .rateLimited = failure { return true }
        return false
    }

    /// A rate limit is the one failure where trying again immediately is guaranteed to fail.
    var canRetryNow: Bool {
        guard let retryAvailableAt else { return true }
        return Date() >= retryAvailableAt
    }

    func cancel() {
        generation += 1
        stream?.cancel()
        stream = nil
        isStreaming = false
    }

    /// Stop streaming and clear the message (the routine-start screen's old `about:blank` reload).
    func reset() {
        cancel()
        text = ""
        failed = false
        failure = nil
        retryAvailableAt = nil
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
