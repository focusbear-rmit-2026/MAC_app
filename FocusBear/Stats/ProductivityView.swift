//
//  ProductivityView.swift
//  Focus Bear
//
//  The Productivity tab (web `dashboard/stats/productivity`): alignment-weighted focused time over
//  the last 30 days / months / years as summary tiles and a bar chart.
//

import SwiftUI

struct ProductivityTab: View {
    @ObservedObject var store: ProductivityStore
    let strings: StatsStrings

    private let tileColumns = [GridItem(.adaptive(minimum: 170), spacing: 12)]
    private static let rangePattern = "MMM dd, yyyy"

    var body: some View {
        if store.isLoading && store.sessions.isEmpty {
            StatsLoadingView()
        } else if store.hasError {
            StatsErrorView(strings: strings) { store.load() }
        } else if store.sessions.isEmpty {
            VStack(spacing: 16) {
                StatsEmptyState(systemImage: "chart.bar", title: strings.noProductivityData)
                PeriodPicker(period: $store.period, strings: strings)
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                if let range = store.range {
                    Text("\(StatsDates.format(range.from, ProductivityTab.rangePattern)) - \(StatsDates.format(range.to, ProductivityTab.rangePattern))")
                        .font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
                }
                tiles
                chartCard
            }
        }
    }

    private var summary: ProductivitySummary { store.summary }

    private func focusedTimeText(_ minutes: Double) -> String {
        let humanized = HumanizedFocusTime.from(totalMinutes: minutes)
        let value = StatsChart.plainNumber(humanized.value)
        switch humanized.unit {
        case .minutes: return StatsStrings.fill(strings.minutesValue, ["value": value])
        case .hours: return StatsStrings.fill(strings.hoursValue, ["value": value])
        case .days:
            let days = StatsStrings.fill(strings.daysValue, ["value": value])
            let hours = StatsStrings.fill(strings.hoursValue, ["value": String(humanized.remainingHours)])
            return "\(days), \(hours)"
        }
    }

    private var mostFocusedDayText: String {
        guard let day = summary.mostFocusedDay else { return "-" }
        return "\(StatsDates.format(day.date, ProductivityTab.rangePattern)) (\(focusedTimeText(day.value)))"
    }

    private var tiles: some View {
        LazyVGrid(columns: tileColumns, spacing: 12) {
            StatTile(label: "\(strings.focusedMinutes) (\(strings.total))", value: focusedTimeText(summary.focusedMinutes))
            StatTile(label: strings.averageFocusPerDay, value: focusedTimeText(summary.averageMinutesPerDay), color: StatsPalette.info)
            StatTile(label: strings.mostFocusedDay, value: mostFocusedDayText, color: StatsPalette.positive, valueLineLimit: 2)
            if summary.hasTabMetrics {
                StatTile(label: strings.averageTabCount,
                         value: StatsStrings.fill(strings.tabsValue, ["value": StatsChart.plainNumber(summary.averageTabCount)]), color: StatsPalette.highlight)
                StatTile(label: strings.averageTabDuration,
                         value: StatsStrings.fill(strings.secondsShortValue, ["value": StatsChart.plainNumber(summary.averageTabDuration)]), color: StatsPalette.highlight)
            }
        }
    }

    private var chartCard: some View {
        let title = summary.usesHours ? strings.focusedHours : strings.focusedMinutes
        return StatsCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 15, weight: .semibold))
                    HStack(spacing: 4) {
                        Text(strings.focusedMinutesDescription).font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
                        Image(systemName: "info.circle").foregroundColor(StatsPalette.secondaryText).help(strings.alignmentScoreTooltip)
                    }
                }
                Spacer()
            }
            StatsChart(points: summary.chart, style: .bars, yAxisTitle: title, xAxisTitle: strings.date,
                       emptyMessage: strings.noProductivityData)
            HStack {
                Spacer()
                PeriodPicker(period: $store.period, strings: strings)
                Spacer()
            }
        }
    }
}
