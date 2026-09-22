//
//  StatsView.swift
//  Focus Bear
//
//  Native replacement for the dashboard.focusbear.io/webview/stats webview: the tab strip, shared
//  building blocks (cards, tiles, empty/error states) and the Streak, Progress, Your Goals and Pep
//  Talk tabs. SwiftUI, hosted by setUpVc via NSHostingView. Same tab set, order and API behaviour as
//  the web page it replaces.
//

import SwiftUI
import AppKit

struct StatsScreen: View {
    @ObservedObject var store: StatsStore
    private var strings: StatsStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                content
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(StatsPalette.page)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text(strings.title).font(.system(size: 20, weight: .semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(StatsTab.allCases) { tab in
                        StatsTabButton(title: tab.title(strings), systemImage: tab.systemImage,
                                       isSelected: store.selectedTab == tab) { store.selectedTab = tab }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch store.selectedTab {
        case .goals: LongTermGoalsTab(store: store.goals, strings: strings)
        case .progress: ProgressTab(store: store.onboarding, strings: strings)
        case .streak: StreakTab(store: store.onboarding, strings: strings)
        case .pepTalk: PepTalkTab(store: store.pepTalk, strings: strings)
        case .leaderboard: LeaderboardTab(store: store.leaderboard, strings: strings)
        case .habitStats: HabitStatsTab(store: store.habitStats, strings: strings)
        case .productivity: ProductivityTab(store: store.productivity, strings: strings)
        case .focusLog: FocusLogTab(store: store.focusLog, strings: strings)
        }
    }
}

// MARK: - Shared building blocks

struct StatsTabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.system(size: 12, weight: .semibold))
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .foregroundColor(isSelected ? .white : StatsPalette.text)
            .background(isSelected ? StatsPalette.orange : StatsPalette.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? StatsPalette.orange : StatsPalette.separator, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

struct StatsCard<Content: View>: View {
    var title: String? = nil
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StatsPalette.card)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(StatsPalette.separator, lineWidth: 1))
    }
}

struct StatTile: View {
    let label: String
    let value: String
    var color: Color = StatsPalette.orange
    /// Long values (a date plus a duration) wrap onto a second line instead of truncating.
    var valueLineLimit = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText).lineLimit(2)
            Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(color).lineLimit(valueLineLimit).minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StatsPalette.card)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(StatsPalette.separator, lineWidth: 1))
    }
}

struct StatsEmptyState: View {
    let systemImage: String
    let title: String
    var description: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage).font(.system(size: 36)).foregroundColor(StatsPalette.secondaryText)
            Text(title).font(.headline).multilineTextAlignment(.center)
            if let description = description {
                Text(description).font(.subheadline).foregroundColor(StatsPalette.secondaryText).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct StatsErrorView: View {
    let strings: StatsStrings
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark").font(.system(size: 30)).foregroundColor(StatsPalette.secondaryText)
            Text(strings.loadFailed).foregroundColor(StatsPalette.secondaryText).multilineTextAlignment(.center)
            SwiftUI.Button(action: retry) { Text(strings.retry) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct StatsLoadingView: View {
    var body: some View {
        ProgressView().frame(maxWidth: .infinity).padding(.vertical, 60)
    }
}

/// A segmented Daily / Monthly / Yearly control (web `SegmentedControl`).
struct PeriodPicker: View {
    @Binding var period: ProductivityPeriod
    let strings: StatsStrings

    private func title(_ period: ProductivityPeriod) -> String {
        switch period {
        case .daily: return strings.daily
        case .monthly: return strings.monthly
        case .yearly: return strings.yearly
        }
    }

    var body: some View {
        Picker("", selection: $period) {
            ForEach(ProductivityPeriod.allCases, id: \.self) { option in
                Text(title(option)).tag(option)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .labelsHidden()
        .frame(maxWidth: 280)
    }
}

// MARK: - Streak

struct StreakTab: View {
    @ObservedObject var store: OnboardingStatsStore
    let strings: StatsStrings

    var body: some View {
        if store.isLoading && store.stats == nil {
            StatsLoadingView()
        } else if let stats = store.stats {
            VStack(spacing: 12) {
                RoutineLevelRow(systemImage: "sunrise.fill", title: strings.morningRoutine,
                                streak: stats.morningRoutineCompletionStreakDays ?? 0, threshold: stats.routinesThreshold ?? 0,
                                average: StatsStrings.fill(strings.percentValue, ["value": StatsChart.plainNumber(stats.averageMorningRoutinesCompletionPercentage.doubleValue)]),
                                strings: strings)
                RoutineLevelRow(systemImage: "moon.stars.fill", title: strings.eveningRoutine,
                                streak: stats.eveningRoutineCompletionStreakDays ?? 0, threshold: stats.routinesThreshold ?? 0,
                                average: StatsStrings.fill(strings.percentValue, ["value": StatsChart.plainNumber(stats.averageEveningRoutinesCompletionPercentage.doubleValue)]),
                                strings: strings)
                RoutineLevelRow(systemImage: "scope", title: strings.focusBlocks,
                                streak: stats.focusModeCompletionStreakDays ?? 0, threshold: stats.focusModesThreshold ?? 0,
                                average: StatsStrings.fill(strings.perDayValue, ["value": StatsChart.plainNumber(stats.averageNumFocusModesCompletedPerDay.doubleValue)]),
                                strings: strings)
            }
        } else {
            StatsErrorView(strings: strings) { store.load() }
        }
    }
}

private struct RoutineLevelRow: View {
    let systemImage: String
    let title: String
    let streak: Int
    let threshold: Int
    let average: String
    let strings: StatsStrings

    var body: some View {
        StatsCard {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(StatsPalette.orange)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 16, weight: .semibold))
                    if threshold - streak > 0 {
                        Text(StatsStrings.fill(strings.daysUntilLevelUp, ["days": String(threshold - streak)]))
                            .font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
                    }
                    HStack(spacing: 4) {
                        Text(strings.averageCompletion).font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
                        Text(average).font(.system(size: 12, weight: .semibold))
                    }
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(String(streak)).font(.system(size: 30, weight: .bold)).foregroundColor(StatsPalette.orange)
                    Text(strings.dayStreak).font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
                }
            }
        }
    }
}

// MARK: - Progress (levels)

struct ProgressTab: View {
    @ObservedObject var store: OnboardingStatsStore
    let strings: StatsStrings

    var body: some View {
        if store.isLoading && store.stats == nil {
            StatsLoadingView()
        } else if let stats = store.stats {
            VStack(alignment: .leading, spacing: 16) {
                levelHeaders(currentLevel: stats.level)
                levelCard(stats: stats)
                if stats.level < LevelTargets.maxLevel {
                    nextLevels(stats: stats)
                }
            }
        } else {
            StatsErrorView(strings: strings) { store.load() }
        }
    }

    private func headerTitle(_ index: Int) -> String {
        if index == 0 { return strings.start }
        if index == LevelTargets.maxLevel + 1 { return strings.end }
        return StatsStrings.fill(strings.levelTitle, ["level": String(index)])
    }

    private func levelHeaders(currentLevel: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(LevelTargets.visibleHeaderRange(level: currentLevel)), id: \.self) { index in
                let isShown = index == store.displayedLevel
                SwiftUI.Button(action: { store.previewLevel = index == currentLevel ? nil : index }) {
                    Text(headerTitle(index))
                        .font(.system(size: 12, weight: isShown ? .semibold : .regular))
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .foregroundColor(isShown ? .white : (index <= currentLevel ? StatsPalette.text : StatsPalette.secondaryText))
                        .background(isShown ? StatsPalette.orange : StatsPalette.card)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(StatsPalette.separator, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
            }
        }
    }

    private func levelCard(stats: OnboardingStats) -> some View {
        let level = store.displayedLevel
        return StatsCard {
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: 6) {
                    levelBadge(level: level)
                    Text(strings.levelName(level)).font(.system(size: 13, weight: .semibold))
                }
                .frame(width: 120)
                if level > 0 {
                    RequirementsList(title: StatsStrings.fill(strings.levelGoals, ["level": String(level)]),
                                     requirements: LevelTargets.requirements(level: level, stats: stats), strings: strings)
                } else {
                    OnboardingChecklist(stats: stats, strings: strings)
                }
                Spacer()
            }
        }
    }

    /// The level's bear figure, as on the web dashboard. Falls back to the numbered orange disc when a
    /// level has no artwork in this build, so a future server-side level still renders something.
    @ViewBuilder
    private func levelBadge(level: Int) -> some View {
        if let name = LevelArtwork.assetName(level: level), let image = NSImage(named: name) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 104, height: 116)
                .accessibilityLabel(strings.levelName(level))
        } else {
            Text(String(level))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(StatsPalette.orange)
                .clipShape(Circle())
        }
    }

    private func nextLevels(stats: OnboardingStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SwiftUI.Button(action: { store.showsNextLevels.toggle() }) {
                Label(strings.nextLevelRequirements, systemImage: store.showsNextLevels ? "chevron.up" : "chevron.down")
            }
            .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
            if store.showsNextLevels {
                HStack(alignment: .top, spacing: 12) {
                    ForEach([stats.level + 1, stats.level + 2].filter { $0 <= LevelTargets.maxLevel }, id: \.self) { level in
                        StatsCard {
                            RequirementsList(title: StatsStrings.fill(strings.levelGoals, ["level": String(level)]),
                                             requirements: LevelTargets.requirements(level: level, stats: stats), strings: strings)
                        }
                    }
                }
            }
        }
    }
}

private struct RequirementsList: View {
    let title: String
    let requirements: [LevelRequirement]
    let strings: StatsStrings

    private func name(_ kind: LevelRequirement.Kind) -> String {
        switch kind {
        case .morning: return strings.morningRoutineStreak
        case .microBreak: return strings.microBreakStreak
        case .evening: return strings.eveningRoutineStreak
        case .focusMode: return strings.focusModeStreak
        case .chat: return strings.chatWithFocusBear
        case .focusModeSetup: return strings.setUpFocusMode
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14, weight: .semibold))
            ForEach(requirements) { requirement in
                HStack(spacing: 8) {
                    if !requirement.isBoolean {
                        Text("\(requirement.current)/\(requirement.target)")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(StatsPalette.orange.opacity(0.15))
                            .cornerRadius(4)
                    }
                    Text(name(requirement.kind)).font(.system(size: 13))
                    Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(requirement.isMet ? StatsPalette.positive : StatsPalette.secondaryText)
                }
            }
        }
    }
}

/// Level-0 checklist: the web's explainer links, opened in the browser (the webview posted
/// `open_ios_app` / `open_android_app` to the host for the same effect).
private struct OnboardingChecklist: View {
    let stats: OnboardingStats
    let strings: StatsStrings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row(strings.setupBlockedUrls, done: stats.hasEditedAlwaysBlockedUrls ?? false, url: StatsExternalLinks.setupBlockedUrls)
            HStack(spacing: 8) {
                row(strings.installMobileApp, done: stats.hasInstalledMobileApp ?? false, url: StatsExternalLinks.installMobileApp)
                StatsLinkButton(systemImage: "apple.logo", url: StatsExternalLinks.iosApp)
                StatsLinkButton(systemImage: "play.rectangle.fill", url: StatsExternalLinks.androidApp)
            }
            row(strings.editYourHabits, done: stats.hasEditedSettings ?? false, url: StatsExternalLinks.editHabits)
        }
    }

    private func row(_ title: String, done: Bool, url: String) -> some View {
        HStack(spacing: 8) {
            SwiftUI.Button(action: { openExternal(url) }) {
                Text(title).font(.system(size: 13)).underline().foregroundColor(StatsPalette.info)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            Image(systemName: done ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(done ? StatsPalette.positive : StatsPalette.secondaryText)
        }
    }
}

struct StatsLinkButton: View {
    let systemImage: String
    let url: String

    var body: some View {
        SwiftUI.Button(action: { openExternal(url) }) {
            Image(systemName: systemImage).foregroundColor(StatsPalette.secondaryText)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}

func openExternal(_ url: String) {
    guard let link = URL(string: url) else { return }
    NSWorkspace.shared.open(link)
}

// MARK: - Your Goals

struct LongTermGoalsTab: View {
    @ObservedObject var store: LongTermGoalsStore
    let strings: StatsStrings

    var body: some View {
        if store.isLoading {
            StatsLoadingView()
        } else if store.hasError {
            StatsErrorView(strings: strings) { store.load() }
        } else {
            StatsCard(title: strings.tabGoals) {
                if store.goals.isEmpty {
                    Text(strings.noLongTermGoals).foregroundColor(StatsPalette.secondaryText)
                }
                ForEach(store.goals.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        Text("\(index + 1).").foregroundColor(StatsPalette.secondaryText).frame(width: 24, alignment: .trailing)
                        TextField(strings.goalPlaceholder, text: $store.goals[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        SwiftUI.Button(action: { store.removeGoal(at: index) }) {
                            Image(systemName: "trash").foregroundColor(StatsPalette.secondaryText)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .pointingHandCursor()
                        .help(strings.delete)
                    }
                }
                HStack {
                    SwiftUI.Button(action: { store.addGoal() }) { Label(strings.addGoal, systemImage: "plus") }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                    Spacer()
                    if let message = store.statusMessage {
                        Text(message).font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
                    }
                    SwiftUI.Button(action: { store.save() }) { Text(strings.save) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                        .disabled(!store.hasUnsavedChanges || store.isSaving)
                }
            }
        }
    }
}

// MARK: - Pep Talk

struct PepTalkTab: View {
    @ObservedObject var store: PepTalkStore
    let strings: StatsStrings

    private let toneColumns = [GridItem(.adaptive(minimum: 210), spacing: 8)]
    private static let messageFontSize: CGFloat = 15
    private static let messageLineSpacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatsCard {
                LazyVGrid(columns: toneColumns, alignment: .leading, spacing: 8) {
                    ForEach(PepTalkStore.tones, id: \.self) { tone in
                        StatsTabButton(title: strings.toneName(tone), systemImage: "sparkles", isSelected: store.tone == tone) {
                            store.select(tone: tone)
                        }
                        .disabled(store.isStreaming)
                    }
                }
            }
            StatsCard {
                if store.text.isEmpty && store.isStreaming {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
                } else if store.failed && store.text.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Say which failure it was. "Try again later" for a rate limit is advice the
                        // user cannot act on, and they pressed Retry five times because of it.
                        Text(store.isRateLimited ? strings.pepTalkRateLimited : strings.pepTalkUnavailable)
                            .foregroundColor(StatsPalette.secondaryText)
                        SwiftUI.Button(strings.retry) { store.select(tone: store.tone) }
                            .disabled(!store.canRetryNow)
                    }
                } else {
                    MarkdownText(markdown: store.text, fontSize: PepTalkTab.messageFontSize,
                                 lineSpacing: PepTalkTab.messageLineSpacing, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
