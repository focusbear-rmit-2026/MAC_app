//
//  StatsCharts.swift
//  Focus Bear
//
//  Chart views for the Stats screen, drawn with SwiftUI shapes (Swift Charts needs macOS 13; the app
//  targets macOS 11): a bar/line chart with axes and a completion heat map.
//

import SwiftUI
import AppKit

/// Colours shared by the Stats views — system colours so light and dark mode both work, plus the
/// app's orange accent.
enum StatsPalette {
    static let orange = Color(NSColor(named: "dark_OrangeColor") ?? NSColor.systemOrange)
    static let card = Color(NSColor.controlBackgroundColor)
    static let page = Color(NSColor.windowBackgroundColor)
    static let separator = Color(NSColor.separatorColor)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    static let text = Color(NSColor.labelColor)
    static let positive = Color(NSColor.systemGreen)
    static let warning = Color(NSColor.systemYellow)
    static let info = Color(NSColor.systemBlue)
    static let highlight = Color(NSColor.systemPurple)
    /// Web `bg-gray-200` / `dark:bg-gray-600` — a day with no completions must still read as a cell
    /// (`quaternaryLabelColor` all but vanished in light mode, so the grid looked full of holes).
    static let emptyCell = Color(NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return isDark ? NSColor(red: 0x4B / 255, green: 0x55 / 255, blue: 0x63 / 255, alpha: 1)
                      : NSColor(red: 0xE5 / 255, green: 0xE7 / 255, blue: 0xEB / 255, alpha: 1)
    })

    /// Heat-map fill for `HeatMapBuilder.intensityLevel` 0…4.
    static func heat(level: Int) -> Color {
        switch level {
        case 0: return emptyCell
        case 1: return orange.opacity(0.3)
        case 2: return orange.opacity(0.55)
        case 3: return orange.opacity(0.8)
        default: return orange
        }
    }
}

// MARK: - Bar / line chart

struct StatsChart: View {
    enum Style { case bars, line }

    let points: [GraphPoint]
    let style: Style
    let yAxisTitle: String
    let xAxisTitle: String
    let emptyMessage: String
    var valueText: (Double) -> String = { StatsChart.plainNumber($0) }
    var accent: Color = StatsPalette.orange

    private static let gridLines = 4
    private static let maxXLabels = 6
    private static let yAxisWidth: CGFloat = 44
    private static let xAxisHeight: CGFloat = 22
    private static let chartHeight: CGFloat = 200

    static func plainNumber(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    private var maxValue: Double { max(points.map(\.value).max() ?? 0, 1) }

    var body: some View {
        if points.isEmpty {
            Text(emptyMessage)
                .foregroundColor(StatsPalette.secondaryText)
                .frame(maxWidth: .infinity, minHeight: StatsChart.chartHeight)
        } else {
            VStack(spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    yAxis
                    GeometryReader { geometry in
                        ZStack(alignment: .bottomLeading) {
                            gridLines(in: geometry.size)
                            plot(in: geometry.size)
                        }
                    }
                    .frame(height: StatsChart.chartHeight)
                }
                xAxis
                Text(xAxisTitle).font(.system(size: 11)).foregroundColor(StatsPalette.secondaryText)
            }
        }
    }

    private var yAxis: some View {
        VStack {
            ForEach((0...StatsChart.gridLines).reversed(), id: \.self) { step in
                Text(valueText(maxValue * Double(step) / Double(StatsChart.gridLines)))
                    .font(.system(size: 10))
                    .foregroundColor(StatsPalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                if step > 0 { Spacer(minLength: 0) }
            }
        }
        .frame(width: StatsChart.yAxisWidth, height: StatsChart.chartHeight)
        .overlay(Text(yAxisTitle).font(.system(size: 10)).foregroundColor(StatsPalette.secondaryText)
                    .rotationEffect(.degrees(-90)).fixedSize().frame(width: 12), alignment: .leading)
        .padding(.leading, 12)
    }

    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            for step in 0...StatsChart.gridLines {
                let y = size.height - size.height * CGFloat(step) / CGFloat(StatsChart.gridLines)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(StatsPalette.separator, lineWidth: 1)
    }

    private func x(for index: Int, in size: CGSize) -> CGFloat {
        let slot = size.width / CGFloat(points.count)
        return slot * (CGFloat(index) + 0.5)
    }

    private func y(for value: Double, in size: CGSize) -> CGFloat {
        size.height - size.height * CGFloat(value / maxValue)
    }

    @ViewBuilder
    private func plot(in size: CGSize) -> some View {
        switch style {
        case .bars:
            let slot = size.width / CGFloat(points.count)
            let barWidth = max(min(slot * 0.6, 28), 2)
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(accent)
                    .frame(width: barWidth, height: max(size.height - y(for: point.value, in: size), 1))
                    .offset(x: x(for: index, in: size) - barWidth / 2)
                    .help("\(point.label): \(valueText(point.value))")
            }
        case .line:
            linePath(in: size).stroke(accent, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            areaPath(in: size).fill(accent.opacity(0.12))
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .help("\(point.label): \(valueText(point.value))")
                    .position(x: x(for: index, in: size), y: y(for: point.value, in: size))
            }
        }
    }

    private func linePath(in size: CGSize) -> Path {
        Path { path in
            for (index, point) in points.enumerated() {
                let location = CGPoint(x: x(for: index, in: size), y: y(for: point.value, in: size))
                if index == 0 { path.move(to: location) } else { path.addLine(to: location) }
            }
        }
    }

    private func areaPath(in size: CGSize) -> Path {
        var path = linePath(in: size)
        guard let last = points.indices.last else { return path }
        path.addLine(to: CGPoint(x: x(for: last, in: size), y: size.height))
        path.addLine(to: CGPoint(x: x(for: 0, in: size), y: size.height))
        path.closeSubpath()
        return path
    }

    /// At most six evenly spaced labels, centred under their bar/point, so long ranges stay readable.
    private var xAxis: some View {
        let stride = max(Int((Double(points.count) / Double(StatsChart.maxXLabels)).rounded(.up)), 1)
        return HStack(alignment: .top, spacing: 4) {
            Color.clear.frame(width: StatsChart.yAxisWidth + 12, height: 1)
            GeometryReader { geometry in
                ForEach(Array(points.enumerated().filter { $0.offset % stride == 0 }), id: \.element.id) { index, point in
                    Text(point.label)
                        .font(.system(size: 10))
                        .foregroundColor(StatsPalette.secondaryText)
                        .fixedSize()
                        .position(x: x(for: index, in: geometry.size), y: StatsChart.xAxisHeight / 2)
                }
            }
        }
        .frame(height: StatsChart.xAxisHeight)
    }
}

// MARK: - Heat map

struct HeatMapView: View {
    let model: HeatMapModel
    let strings: StatsStrings

    private static let cellSize: CGFloat = 12
    private static let cellGap: CGFloat = 4
    private static let dayLabelWidth: CGFloat = 32
    /// Days after today are faded placeholders that keep the last column a whole week.
    private static let futureCellOpacity = 0.35
    private static let dayLabelFontSize: CGFloat = 8
    /// Sunday-first, matching the heat-map columns.
    private static var localizedDayLabels: [String] { StatsCalendar.shortWeekdaySymbols(languageCode: currentLanguageCode) }
    private var columnStride: CGFloat { HeatMapView.cellSize + HeatMapView.cellGap }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            monthLabels
            HStack(alignment: .top, spacing: HeatMapView.cellGap) {
                dayLabelColumn
                ForEach(Array(model.columns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: HeatMapView.cellGap) {
                        ForEach(column) { cell in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(fill(for: cell))
                                .frame(width: HeatMapView.cellSize, height: HeatMapView.cellSize)
                                .help(tooltip(for: cell))
                        }
                    }
                }
            }
            legend
        }
    }

    private var monthLabels: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(height: 14)
            ForEach(model.monthLabels) { month in
                Text(month.label)
                    .font(.system(size: 10))
                    .foregroundColor(StatsPalette.secondaryText)
                    .offset(x: HeatMapView.dayLabelWidth + HeatMapView.cellGap + CGFloat(month.weekIndex) * columnStride)
            }
        }
    }

    /// Every row is labelled (the web labels only Mon / Wed / Fri); the font is small enough for
    /// consecutive labels not to collide at the 12pt row height.
    private var dayLabelColumn: some View {
        VStack(spacing: HeatMapView.cellGap) {
            ForEach(Array(HeatMapView.localizedDayLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: HeatMapView.dayLabelFontSize))
                    .lineLimit(1)
                    .foregroundColor(StatsPalette.secondaryText)
                    .frame(width: HeatMapView.dayLabelWidth, height: HeatMapView.cellSize, alignment: .trailing)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Spacer()
            Text(strings.less).font(.system(size: 10)).foregroundColor(StatsPalette.secondaryText)
            ForEach(0..<HeatMapBuilder.intensityLevels, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(StatsPalette.heat(level: level))
                    .frame(width: HeatMapView.cellSize, height: HeatMapView.cellSize)
            }
            Text(strings.more).font(.system(size: 10)).foregroundColor(StatsPalette.secondaryText)
        }
    }

    private func fill(for cell: HeatMapCell) -> Color {
        if cell.isFuture { return StatsPalette.emptyCell.opacity(HeatMapView.futureCellOpacity) }
        return StatsPalette.heat(level: HeatMapBuilder.intensityLevel(count: cell.count, maxCount: model.maxCount))
    }

    private func tooltip(for cell: HeatMapCell) -> String {
        let day = StatsDates.format(cell.date, LogQuantityGraph.labelPattern)
        guard !cell.isFuture else { return day }
        let noun = cell.count == 1 ? strings.completion : strings.completions
        return "\(day): \(cell.count) \(noun)"
    }
}
