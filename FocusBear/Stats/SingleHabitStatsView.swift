//
//  SingleHabitStatsView.swift
//  Focus Bear
//
//  The per-habit stats sheet opened from the "Stats" button in a habit's Day Plan action bar: current
//  streak and completion tiles, the completion heat map, and one chart per log-quantity question
//  (labelled Total or Average to match how the backend aggregates that question).
//
//  Everything here is built from the Stats screen's existing pieces — StatTile, StatsCard, HeatMapView,
//  StatsChart — so a habit's stats look the same wherever they're shown.
//

import SwiftUI

@available(macOS 11.0, *)
struct SingleHabitStatsView: View {
    @ObservedObject var store: SingleHabitStatsStore
    let strings: StatsStrings
    let onClose: () -> Void

    private let tileColumns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { store.load() }
    }

    private var header: some View {
        HStack {
            Text(store.title).font(.system(size: 16, weight: .semibold)).lineLimit(1)
            Spacer()
            SwiftUI.Button(action: onClose) { Text(strings.close) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 28))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            StatsLoadingView()
        } else if store.hasError {
            StatsErrorView(strings: strings) { store.load() }
        } else if !store.hasAnyData {
            StatsEmptyState(systemImage: "chart.bar", title: strings.noDataAvailable)
                .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    tiles
                    heatMapCard
                    ForEach(store.questionGraphs) { graph in
                        questionCard(graph)
                    }
                }
                .padding(20)
            }
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: tileColumns, spacing: 12) {
            StatTile(label: strings.currentStreak,
                     value: StatsStrings.fill(strings.daysValue, ["value": String(store.summary.currentStreak)]),
                     color: StatsPalette.orange)
            StatTile(label: strings.totalCompletions, value: String(store.summary.totalCompletions),
                     color: StatsPalette.positive)
            StatTile(label: strings.last30Days,
                     value: StatsStrings.fill(strings.percentValue, ["value": String(store.summary.last30DaysPercentage)]),
                     color: StatsPalette.highlight)
            // Hidden for a quantity habit: `summary` is the logged amount there, not seconds.
            if store.showsHoursSpent {
                StatTile(label: strings.hoursSpent,
                         value: StatsStrings.fill(strings.hoursValue, ["value": StatsChart.plainNumber(store.summary.hoursSpent)]),
                         color: StatsPalette.info)
            }
        }
    }

    private var heatMapCard: some View {
        StatsCard {
            HeatMapView(model: store.heatMap, strings: strings)
            Text(strings.habitCompletionHistory).font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
        }
    }

    /// One question's series. The axis title says whether each point is that day's total or its
    /// average, since the backend has already aggregated the day per the question's `log_summary_type`.
    private func questionCard(_ graph: HabitQuestionGraph) -> some View {
        StatsCard {
            Text(graph.question).font(.system(size: 14, weight: .semibold))
            StatsChart(points: graph.points, style: .line,
                       yAxisTitle: graph.isAveraged ? strings.dailyAverage : strings.dailyTotal,
                       xAxisTitle: strings.date, emptyMessage: strings.noDataAvailable)
            Text(strings.logQuantityHistory).font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
        }
    }
}
