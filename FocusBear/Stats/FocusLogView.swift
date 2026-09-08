//
//  FocusLogView.swift
//  Focus Bear
//
//  The Focus Log tab (web `dashboard/stats/focusSummary`): sortable / filterable session table,
//  per-session detail, manual-session creation, edit/delete, the summary graph and CSV export.
//

import SwiftUI

struct FocusLogTab: View {
    @ObservedObject var store: FocusLogStore
    let strings: StatsStrings

    var body: some View {
        if store.isLoading && store.entries.isEmpty {
            StatsLoadingView()
        } else if store.hasError && store.entries.isEmpty {
            StatsErrorView(strings: strings) { store.load() }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                toolbar
                if store.entries.isEmpty {
                    StatsEmptyState(systemImage: "list.bullet.rectangle", title: strings.noFocusSummary,
                                    description: strings.startFocusSessionHint)
                } else {
                    FocusLogTable(store: store, strings: strings)
                    if store.canLoadMore {
                        HStack {
                            Spacer()
                            SwiftUI.Button(action: { store.loadMore() }) { Text(strings.loadMoreSessions) }
                                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                                .disabled(store.isLoading)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            if let message = store.statusMessage {
                Text(message).font(.system(size: 12)).foregroundColor(Color(NSColor.systemRed))
            }
            Spacer()
            SwiftUI.Button(action: { store.editorSession = FocusLogEditorSession(entry: nil) }) {
                Label(strings.addManualSession, systemImage: "plus")
            }
            .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            SwiftUI.Button(action: { store.load() }) { Label(strings.refresh, systemImage: "arrow.clockwise") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
            SwiftUI.Button(action: { store.showsGraph = true }) { Label(strings.focusBlockSummary, systemImage: "chart.xyaxis.line") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                .disabled(store.entries.isEmpty)
            SwiftUI.Button(action: { store.exportCSV() }) { Label(strings.export, systemImage: "square.and.arrow.up") }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                .disabled(store.entries.isEmpty)
        }
        .sheet(item: $store.editorSession) { session in
            FocusLogEditorSheet(store: store, entry: session.entry, strings: strings)
        }
        .background(
            // Separate anchors: SwiftUI on macOS 11 only honours one presentation modifier per view.
            Color.clear.sheet(isPresented: $store.showsGraph) { FocusLogGraphSheet(store: store, strings: strings) }
        )
    }
}

// MARK: - Table

private struct FocusLogTable: View {
    @ObservedObject var store: FocusLogStore
    let strings: StatsStrings

    private static let durationWidth: CGFloat = 130
    private static let timeWidth: CGFloat = 150
    private static let modeWidth: CGFloat = 130
    private static let actionsWidth: CGFloat = 32
    private static let timePattern = "MMM dd yyyy, hh:mm a"

    private func title(_ column: FocusLogColumn) -> String {
        switch column {
        case .duration: return strings.duration
        case .startTime: return strings.startTime
        case .finishTime: return strings.finishTime
        case .intention: return strings.intention
        case .distractions: return strings.distractions
        case .focusMode: return strings.focusMode
        }
    }

    private func width(_ column: FocusLogColumn) -> CGFloat? {
        switch column {
        case .duration: return FocusLogTable.durationWidth
        case .startTime, .finishTime: return FocusLogTable.timeWidth
        case .focusMode: return FocusLogTable.modeWidth
        case .intention, .distractions: return nil
        }
    }

    static func timeText(_ raw: String?) -> String {
        guard let date = StatsDates.parse(raw) else { return "--" }
        return StatsDates.format(date, timePattern)
    }

    var body: some View {
        StatsCard {
            VStack(spacing: 0) {
                header
                if store.filterColumn != nil { filterBar }
                Divider()
                if store.visibleEntries.isEmpty {
                    Text(strings.noFocusSummary).foregroundColor(StatsPalette.secondaryText).padding(.vertical, 24)
                }
                ForEach(store.visibleEntries) { entry in
                    row(entry)
                    Divider()
                }
            }
            .alert(item: $store.entryToDelete) { _ in
                Alert(title: Text(strings.delete), message: Text(strings.confirmDeleteSession),
                      primaryButton: .destructive(Text(strings.delete)) { store.confirmDelete() },
                      secondaryButton: .cancel(Text(strings.cancel)))
            }
        }
        .background(
            Color.clear.sheet(item: $store.detailEntry) { entry in
                FocusLogDetailSheet(store: store, entry: entry, strings: strings)
            }
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            ForEach(FocusLogColumn.allCases) { column in
                HStack(spacing: 2) {
                    Text(title(column)).font(.system(size: 11, weight: .semibold)).foregroundColor(StatsPalette.secondaryText).lineLimit(1)
                    SwiftUI.Button(action: { store.sortColumn = column }) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(store.sortColumn == column ? StatsPalette.orange : StatsPalette.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                    SwiftUI.Button(action: { store.setFilter(column: store.filterColumn == column ? nil : column) }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .font(.system(size: 10))
                            .foregroundColor(store.filterColumn == column ? StatsPalette.orange : StatsPalette.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
                }
                .frame(width: width(column), alignment: .leading)
                .frame(maxWidth: width(column) == nil ? .infinity : nil, alignment: .leading)
            }
            Color.clear.frame(width: FocusLogTable.actionsWidth, height: 1)
        }
        .padding(.vertical, 6)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            if let column = store.filterColumn {
                Text(title(column)).font(.system(size: 12, weight: .semibold))
                if column.isDateColumn {
                    DatePicker("", selection: Binding(get: { store.filterDay ?? Date() }, set: { store.filterDay = $0 }),
                               displayedComponents: .date)
                        .labelsHidden()
                } else {
                    TextField(strings.filterPlaceholder, text: $store.filterText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 260)
                }
                SwiftUI.Button(action: { store.setFilter(column: nil) }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Color(NSColor.systemRed))
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
            }
            Spacer()
        }
        .padding(.bottom, 6)
    }

    private func row(_ entry: FocusLogEntry) -> some View {
        HStack(spacing: 8) {
            Text(FocusLogMath.humanizeSeconds(FocusLogMath.effectiveDurationSeconds(entry))).frame(width: FocusLogTable.durationWidth, alignment: .leading)
            Text(FocusLogTable.timeText(entry.startTime)).frame(width: FocusLogTable.timeWidth, alignment: .leading)
            Text(FocusLogTable.timeText(entry.finishTime)).frame(width: FocusLogTable.timeWidth, alignment: .leading)
            Text(FocusLogMath.displayText(entry.intention)).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
            Text(FocusLogMath.displayText(entry.distractions)).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
            Text(entry.focusModeName).lineLimit(1).frame(width: FocusLogTable.modeWidth, alignment: .leading)
            SwiftUI.Button(action: { store.detailEntry = entry }) {
                Image(systemName: "ellipsis.circle").foregroundColor(StatsPalette.secondaryText)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .frame(width: FocusLogTable.actionsWidth)
            .help(strings.more)
        }
        .font(.system(size: 12))
        .padding(.vertical, 8)
    }
}

// MARK: - Detail sheet ("More")

private struct FocusLogDetailSheet: View {
    @ObservedObject var store: FocusLogStore
    let entry: FocusLogEntry
    let strings: StatsStrings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.focusModeName.isEmpty ? strings.focusMode : entry.focusModeName).font(.system(size: 16, weight: .semibold))
            detailRow(strings.duration, FocusLogMath.humanizeSeconds(FocusLogMath.effectiveDurationSeconds(entry)))
            detailRow(strings.startTime, FocusLogTable.timeText(entry.startTime))
            detailRow(strings.finishTime, FocusLogTable.timeText(entry.finishTime))
            detailRow(strings.intention, FocusLogMath.displayText(entry.intention))
            detailRow(strings.achievements, FocusLogMath.displayText(entry.achievements))
            detailRow(strings.distractions, FocusLogMath.displayText(entry.distractions))
            HStack {
                Spacer()
                if entry.isManual {
                    SwiftUI.Button(action: {
                        store.detailEntry = nil
                        store.editorSession = FocusLogEditorSession(entry: entry)
                    }) { Text(strings.edit) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                }
                SwiftUI.Button(action: { store.detailEntry = nil }) { Text(strings.close) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(StatsPalette.secondaryText).frame(width: 110, alignment: .leading)
            Text(value).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Editor sheet (create manual / edit)

private struct FocusLogEditorSheet: View {
    @ObservedObject var store: FocusLogStore
    let entry: FocusLogEntry?
    let strings: StatsStrings

    @SwiftUI.State private var start = Date().addingTimeInterval(-3600)
    @SwiftUI.State private var finish = Date()
    @SwiftUI.State private var intention = ""
    @SwiftUI.State private var achievements = ""
    @SwiftUI.State private var distractions = ""

    private var isCreating: Bool { entry == nil }

    /// Web `FocusSummaryValidationMessage` rules.
    private var validationMessage: String? {
        guard isCreating else { return nil }
        let now = Date()
        if start > now { return strings.startInFuture }
        if finish > now { return strings.finishInFuture }
        if finish <= start { return strings.finishAfterStart }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isCreating ? strings.addManualSession : (entry?.focusModeName.isEmpty == false ? entry!.focusModeName : strings.edit))
                .font(.system(size: 16, weight: .semibold))
            if isCreating {
                DatePicker(strings.startTime, selection: $start)
                DatePicker(strings.finishTime, selection: $finish)
                Text("\(strings.duration): \(FocusLogMath.humanizeSeconds(max(Int(finish.timeIntervalSince(start)), 0)))")
                    .font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
                if let message = validationMessage {
                    Text(message).font(.system(size: 12)).foregroundColor(Color(NSColor.systemRed))
                }
            } else if let entry = entry {
                Text("\(FocusLogTable.timeText(entry.startTime)) → \(FocusLogTable.timeText(entry.finishTime))")
                    .font(.system(size: 12)).foregroundColor(StatsPalette.secondaryText)
            }
            field(strings.intention, $intention)
            field(strings.achievements, $achievements)
            field(strings.distractions, $distractions)
            HStack {
                if !isCreating, let entry = entry {
                    SwiftUI.Button(action: { store.entryToDelete = entry }) { Text(strings.delete) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                        .alert(item: $store.entryToDelete) { _ in
                            Alert(title: Text(strings.delete), message: Text(strings.confirmDeleteSession),
                                  primaryButton: .destructive(Text(strings.delete)) { store.confirmDelete() },
                                  secondaryButton: .cancel(Text(strings.cancel)))
                        }
                }
                Spacer()
                SwiftUI.Button(action: { store.editorSession = nil }) { Text(strings.cancel) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                SwiftUI.Button(action: save) { Text(strings.save) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                    .disabled(store.isSaving || validationMessage != nil)
            }
        }
        .padding(20)
        .frame(width: 560)
        .onAppear {
            guard let entry = entry else { return }
            intention = FocusLogMath.displayText(entry.intention) == "-" ? "" : FocusLogMath.displayText(entry.intention)
            achievements = entry.achievements ?? ""
            distractions = entry.distractions ?? ""
        }
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(StatsPalette.secondaryText)
            TextEditor(text: text)
                .font(.system(size: 13))
                .frame(height: 60)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(StatsPalette.separator))
        }
    }

    private func save() {
        if let entry = entry {
            store.updateSession(entry, intention: intention, achievements: achievements, distractions: distractions)
        } else {
            store.createManualSession(start: start, finish: finish, intention: intention, achievements: achievements, distractions: distractions)
        }
    }
}

// MARK: - Summary graph sheet

private struct FocusLogGraphSheet: View {
    @ObservedObject var store: FocusLogStore
    let strings: StatsStrings

    private static let hoursDecimals = "%.2f"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.focusBlockSummary).font(.system(size: 16, weight: .semibold))
            StatsChart(points: store.graphPoints, style: .bars, yAxisTitle: strings.durationHours, xAxisTitle: strings.date,
                       emptyMessage: strings.noFocusSummary,
                       valueText: { String(format: FocusLogGraphSheet.hoursDecimals, $0 / 3600) })
            HStack {
                PeriodPicker(period: $store.graphPeriod, strings: strings)
                Spacer()
                SwiftUI.Button(action: { store.showsGraph = false }) { Text(strings.close) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            }
        }
        .padding(20)
        .frame(width: 720)
    }
}
