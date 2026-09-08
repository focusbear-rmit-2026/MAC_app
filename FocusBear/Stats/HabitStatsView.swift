//
//  HabitStatsView.swift
//  Focus Bear
//
//  The Habit Stats tab (web `dashboard/stats/activityStats`): most/least consistent habit rankings,
//  the selected habit's stat cards, its completion heat map and the logged-quantity graph.
//

import SwiftUI

struct HabitStatsTab: View {
    @ObservedObject var store: HabitStatsStore
    let strings: StatsStrings

    private let tileColumns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        if store.isLoading || !store.hasLoaded {
            StatsLoadingView()
        } else if store.hasError {
            StatsErrorView(strings: strings) { store.load() }
        } else if !store.hasHabits {
            StatsEmptyState(systemImage: "tray", title: strings.noHabitsTitle,
                            description: StatsStrings.fill(strings.noHabitsDescription, ["navItem": strings.editHabitsNavItem]))
        } else {
            VStack(alignment: .leading, spacing: 16) {
                rankingCard
                if let habit = store.selectedHabit {
                    selectedHabit(habit)
                }
            }
        }
    }

    private var rankingCard: some View {
        StatsCard {
            HStack(alignment: .top, spacing: 24) {
                ConsistencySection(title: strings.mostConsistentHabits, items: store.ranking.mostConsistent,
                                   color: StatsPalette.positive, selectedId: store.selectedHabitId, strings: strings) { store.select($0) }
                if store.ranking.showsLeastSection {
                    ConsistencySection(title: strings.leastConsistentHabits, items: store.ranking.leastConsistent,
                                       color: StatsPalette.warning, selectedId: store.selectedHabitId, strings: strings) { store.select($0) }
                }
            }
        }
    }

    private func selectedHabit(_ habit: StatsActivity) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if store.isLoadingDetails {
                StatsLoadingView()
            } else if let details = store.details {
                LazyVGrid(columns: tileColumns, spacing: 12) {
                    StatTile(label: strings.totalCompletions, value: String(details.summary.totalCompletions), color: StatsPalette.positive)
                    StatTile(label: strings.hoursSpent, value: StatsStrings.fill(strings.hoursValue, ["value": StatsChart.plainNumber(details.summary.hoursSpent)]), color: StatsPalette.info)
                    StatTile(label: strings.currentStreak, value: StatsStrings.fill(strings.daysValue, ["value": String(details.summary.currentStreak)]), color: StatsPalette.orange)
                    StatTile(label: strings.last30Days, value: StatsStrings.fill(strings.percentValue, ["value": String(details.summary.last30DaysPercentage)]), color: StatsPalette.highlight)
                }
                if !details.isEmpty {
                    historyCard(habit: habit, details: details)
                }
            }
        }
    }

    private func historyCard(habit: StatsActivity, details: HabitDetails) -> some View {
        StatsCard {
            HStack {
                Text(habitTitle(habit)).font(.system(size: 15, weight: .semibold))
                Spacer()
                if habit.questions.count > 1 {
                    questionPicker(habit)
                }
            }
            HeatMapView(model: details.heatMap, strings: strings)
            Text(strings.habitCompletionHistory).font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
            if store.selectedQuestionId != nil {
                Divider()
                StatsChart(points: details.questionPoints, style: .line, yAxisTitle: strings.quantityLogged,
                           xAxisTitle: strings.date, emptyMessage: strings.noDataAvailable)
                Text(strings.logQuantityHistory).font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
            }
        }
    }

    private func habitTitle(_ habit: StatsActivity) -> String {
        [habit.habitIcon, habit.name].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func questionPicker(_ habit: StatsActivity) -> some View {
        let selection = Binding<String>(
            get: { store.selectedQuestionId ?? "" },
            set: { store.selectQuestion($0.isEmpty ? nil : $0) })
        return Picker("", selection: selection) {
            Text(strings.selectQuestions).tag("")
            ForEach(habit.questions, id: \.id) { question in
                Text(question.question ?? question.id).tag(question.id)
            }
        }
        .labelsHidden()
        .frame(maxWidth: 260)
    }
}

private struct ConsistencySection: View {
    let title: String
    let items: [HabitConsistencyItem]
    let color: Color
    let selectedId: String?
    let strings: StatsStrings
    let onSelect: (StatsActivity) -> Void

    private static let rowHeight: CGFloat = 46
    private static let visibleRows = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            Text(StatsStrings.fill(strings.percentOfLastDays, ["days": String(HabitConsistencyRanking.windowMaxDays)]))
                .font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(items) { item in
                        ConsistencyRow(item: item, color: color, isSelected: item.id == selectedId) { onSelect(item.activity) }
                    }
                }
            }
            .frame(height: ConsistencySection.rowHeight * CGFloat(min(items.count, ConsistencySection.visibleRows)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ConsistencyRow: View {
    let item: HabitConsistencyItem
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        SwiftUI.Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.activity.habitIcon?.isEmpty == false ? item.activity.habitIcon! : "•")
                    Text(item.activity.name ?? "").lineLimit(1)
                    Spacer()
                    Text("\(item.percentage)%").font(.system(size: 12, weight: .semibold))
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(StatsPalette.separator)
                        Capsule().fill(color).frame(width: geometry.size.width * CGFloat(item.percentage) / 100)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? StatsPalette.orange.opacity(0.12) : Color.clear)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? StatsPalette.orange : Color.clear, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }
}
