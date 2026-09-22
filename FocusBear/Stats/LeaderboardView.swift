//
//  LeaderboardView.swift
//  Focus Bear
//
//  The Leaderboard tab (web `dashboard/stats/leaderBoard.tsx`): sortable streak table with the
//  current user highlighted, expandable per-user details, and the leaderboard username editor.
//

import SwiftUI

struct LeaderboardTab: View {
    @ObservedObject var store: LeaderboardStore
    let strings: StatsStrings

    private static let rankWidth: CGFloat = 50
    private static let streakWidth: CGFloat = 110

    var body: some View {
        if store.isLoading && store.response == nil {
            StatsLoadingView()
        } else if store.hasError && store.response == nil {
            StatsErrorView(strings: strings) { store.load() }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                toolbar
                StatsCard {
                    table
                }
                usernameEditor
            }
        }
    }

    private func sortTitle(_ key: LeaderboardSortKey) -> String {
        switch key {
        case .morning: return strings.morningStreak
        case .microBreak: return strings.breakStreak
        case .evening: return strings.eveningStreak
        case .focusMode: return strings.focusMode
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Text(strings.sortBy).foregroundColor(StatsPalette.secondaryText)
            Picker("", selection: $store.sortKey) {
                ForEach(LeaderboardSortKey.allCases) { key in
                    Text(sortTitle(key)).tag(key)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 180)
            SwiftUI.Button(action: { store.ascending.toggle() }) {
                Label(store.ascending ? strings.ascending : strings.descending,
                      systemImage: store.ascending ? "arrow.up" : "arrow.down")
            }
            .buttonStyle(BorderedButtonStyle())
            .pointingHandCursor()
            .help(store.ascending ? strings.ascending : strings.descending)
            if store.isReloading {
                ProgressView().scaleEffect(0.5).frame(width: 16, height: 16)
            }
            Spacer()
        }
    }

    private var table: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                headerCell(strings.rank, width: LeaderboardTab.rankWidth)
                headerCell(strings.name, width: nil)
                headerCell(strings.morningStreak, width: LeaderboardTab.streakWidth)
                headerCell(strings.breakStreak, width: LeaderboardTab.streakWidth)
                headerCell(strings.eveningStreak, width: LeaderboardTab.streakWidth)
                headerCell(strings.focusMode, width: LeaderboardTab.streakWidth)
            }
            .padding(.vertical, 6)
            Divider()
            if store.users.isEmpty {
                Text(strings.noUserFound).foregroundColor(StatsPalette.secondaryText).padding(.vertical, 24)
            }
            ForEach(Array(store.users.enumerated()), id: \.element.id) { index, user in
                LeaderboardRow(user: user, rank: index + 1, isCurrentUser: user.id == store.currentUserId,
                               isExpanded: store.expandedUserId == user.id, strings: strings,
                               rankWidth: LeaderboardTab.rankWidth, streakWidth: LeaderboardTab.streakWidth) {
                    store.toggleExpanded(user)
                }
                Divider()
            }
        }
    }

    private func headerCell(_ title: String, width: CGFloat?) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(StatsPalette.secondaryText)
            .lineLimit(1)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private var usernameEditor: some View {
        StatsCard(title: strings.leaderboardUsername) {
            HStack(spacing: 8) {
                TextField(strings.leaderboardUsername, text: $store.usernameDraft)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 260)
                if store.canUpdateUsername {
                    SwiftUI.Button(action: { store.saveUsername() }) { Text(strings.update) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 28))
                }
                if !store.usernameDraft.isEmpty && !store.isUsernameValid {
                    Text(strings.usernameRule).font(.system(size: 12)).foregroundColor(Color(NSColor.systemRed))
                }
                Spacer()
            }
        }
    }
}

private struct LeaderboardRow: View {
    let user: LeaderboardUser
    let rank: Int
    let isCurrentUser: Bool
    let isExpanded: Bool
    let strings: StatsStrings
    let rankWidth: CGFloat
    let streakWidth: CGFloat
    let onTap: () -> Void

    private static let usernamePlaceholder = "-----"

    /// One column of the row: the "{percent}%" headline plus the "(completed / total)" fraction; the
    /// current streak count sits in the tooltip and the expanded details.
    private struct Metric {
        let title: String
        let value: String
        let values: LeaderboardMetric
    }

    private func metric(_ key: LeaderboardSortKey, title: String) -> Metric {
        let values = LeaderboardSorting.metric(user, key: key)
        return Metric(title: title, value: StatsStrings.fill(strings.percentValue, ["value": StatsChart.plainNumber(values.percentage)]),
                      values: values)
    }

    private var metrics: [Metric] {
        [metric(.morning, title: strings.morningStreak),
         metric(.microBreak, title: strings.breakStreak),
         metric(.evening, title: strings.eveningStreak),
         metric(.focusMode, title: strings.focusMode)]
    }

    private func streakText(_ metric: Metric) -> String {
        StatsStrings.fill(strings.streakValue, ["streak": StatsChart.plainNumber(metric.values.streak)])
    }

    /// The collapsed row only has room for "(84/84)", which is the half of the story that confuses
    /// people; the tooltip carries the streak and the sentence explaining the denominator.
    private func tooltip(_ metric: Metric) -> String {
        streakText(metric) + "\n" + LeaderboardSorting.completionSummary(metric.values, strings: strings)
    }

    var body: some View {
        VStack(spacing: 0) {
            SwiftUI.Button(action: onTap) {
                HStack(spacing: 8) {
                    Text(String(rank)).frame(width: rankWidth, alignment: .leading)
                    Text(user.username ?? LeaderboardRow.usernamePlaceholder)
                        .fontWeight(isCurrentUser ? .semibold : .regular)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                        HStack(spacing: 4) {
                            Text(metric.value).fontWeight(.medium)
                            if metric.values.windowDays > 0 {
                                Text("(\(StatsChart.plainNumber(metric.values.completedDays))/\(StatsChart.plainNumber(metric.values.windowDays)))")
                                    .font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
                            }
                        }
                        .frame(width: streakWidth, alignment: .leading)
                        .help(tooltip(metric))
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(isCurrentUser ? StatsPalette.orange.opacity(0.12) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            if isExpanded {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric.title).font(.system(size: 12, weight: .semibold))
                            Text(metric.value).font(.system(size: 18, weight: .bold)).foregroundColor(StatsPalette.orange)
                            Text(streakText(metric))
                                .font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
                            Text(LeaderboardSorting.completionSummary(metric.values, strings: strings))
                                .font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(StatsPalette.page)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
