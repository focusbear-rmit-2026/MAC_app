//
//  FocusStatsStore.swift
//  Focus Bear
//
//  State for the two focus-session tabs — the web's `dashboard/stats/productivity` (alignment-
//  weighted focused minutes over the last 30 days/months/years) and `dashboard/stats/focusSummary`
//  (the sortable, filterable Focus Log with manual sessions, edit/delete, summary graph and CSV export).
//

import Foundation
import AppKit

// MARK: - Productivity

final class ProductivityStore: ObservableObject {
    @Published var period = ProductivityPeriod.daily {
        didSet { if period != oldValue { load() } }
    }
    @Published private(set) var sessions: [FocusSessionSummary] = []
    @Published private(set) var summary = ProductivitySummary()
    @Published private(set) var range: (from: Date, to: Date)?
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false
    private var requestId = 0

    func load() {
        let range = ProductivitySummary.dateRange(period, now: Date())
        self.range = range
        isLoading = true
        hasError = false
        requestId += 1
        let currentRequest = requestId
        let period = self.period
        allApiObject.getCompletedFocusBlocks(from: range.from, to: range.to) { [weak self] sessions in
            DispatchQueue.main.async {
                guard let self = self, currentRequest == self.requestId else { return }
                self.isLoading = false
                self.hasError = sessions == nil
                self.sessions = sessions ?? []
                self.summary = ProductivitySummary.compute(sessions: self.sessions, period: period)
            }
        }
    }
}

// MARK: - Focus log

/// Which session the editor sheet is for; nil entry = "Add Manual Session".
struct FocusLogEditorSession: Identifiable {
    let id = UUID()
    let entry: FocusLogEntry?
}

final class FocusLogStore: ObservableObject {
    static let statusMessageSeconds: TimeInterval = 3

    let strings: StatsStrings
    @Published private(set) var entries: [FocusLogEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false
    @Published private(set) var canLoadMore = false

    @Published var sortColumn = FocusLogColumn.startTime
    @Published var filterColumn: FocusLogColumn?
    @Published var filterText = ""
    @Published var filterDay: Date?

    @Published var detailEntry: FocusLogEntry?
    @Published var editorSession: FocusLogEditorSession?
    @Published var entryToDelete: FocusLogEntry?
    @Published var showsGraph = false
    @Published var graphPeriod = ProductivityPeriod.daily
    @Published private(set) var isSaving = false
    @Published private(set) var statusMessage: String?

    private var focusModes: [FocusModeSummary] = []

    init(strings: StatsStrings) { self.strings = strings }

    var visibleEntries: [FocusLogEntry] {
        var list = entries
        if let column = filterColumn {
            list = FocusLogMath.filtered(list, column: column, text: filterText, day: filterDay)
        }
        return FocusLogMath.sorted(list, by: sortColumn)
    }

    var graphPoints: [GraphPoint] { FocusLogMath.graphPoints(entries, period: graphPeriod) }

    func load() {
        isLoading = true
        hasError = false
        allApiObject.getFocusLog(limit: StatsRequestLimits.focusLogPageSize, offset: 0) { [weak self] entries in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                self.hasError = entries == nil
                self.entries = entries ?? []
                self.canLoadMore = (entries?.count ?? 0) == StatsRequestLimits.focusLogPageSize
            }
        }
        if focusModes.isEmpty {
            allApiObject.getFocusModeSummaries { [weak self] modes in
                DispatchQueue.main.async { self?.focusModes = modes ?? [] }
            }
        }
    }

    func loadMore() {
        guard canLoadMore, !isLoading else { return }
        isLoading = true
        allApiObject.getFocusLog(limit: StatsRequestLimits.focusLogPageSize, offset: entries.count) { [weak self] page in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                let page = page ?? []
                // Web `mergeFocusSummariesById`: keep order, drop rows already listed.
                let known = Set(self.entries.map(\.id))
                self.entries += page.filter { !known.contains($0.id) }
                self.canLoadMore = page.count == StatsRequestLimits.focusLogPageSize
            }
        }
    }

    func setFilter(column: FocusLogColumn?) {
        filterColumn = column
        filterText = ""
        filterDay = nil
    }

    // MARK: Create / edit / delete

    /// Web `resolveManualFocusModeId`: reuse the "Manual Entry" focus mode when it exists; the server
    /// creates one otherwise.
    private var manualFocusModeId: String? {
        focusModes.first { $0.metadata?.isManualEntry == true }?.id
    }

    func createManualSession(start: Date, finish: Date, intention: String, achievements: String, distractions: String) {
        let payload = CreateFocusBlockPayload(
            intention: intention, achievements: achievements, distractions: distractions,
            focusDurationSeconds: max(Int(finish.timeIntervalSince(start).rounded()), 0),
            startTime: StatsDates.iso(start), finishTime: StatsDates.iso(finish),
            focusModeId: manualFocusModeId)
        isSaving = true
        allApiObject.createFocusBlock(payload) { [weak self] success in
            DispatchQueue.main.async { self?.finishSave(success: success) }
        }
    }

    func updateSession(_ entry: FocusLogEntry, intention: String, achievements: String, distractions: String) {
        let payload = UpdateFocusBlockPayload(intention: intention, achievements: achievements, distractions: distractions)
        isSaving = true
        allApiObject.updateFocusBlock(id: entry.id, payload) { [weak self] success in
            DispatchQueue.main.async { self?.finishSave(success: success) }
        }
    }

    func confirmDelete() {
        guard let entry = entryToDelete else { return }
        entryToDelete = nil
        editorSession = nil
        detailEntry = nil
        isSaving = true
        allApiObject.deleteFocusBlock(id: entry.id) { [weak self] success in
            DispatchQueue.main.async { self?.finishSave(success: success) }
        }
    }

    private func finishSave(success: Bool) {
        isSaving = false
        if success {
            editorSession = nil
            detailEntry = nil
            load()
        } else {
            showStatus(strings.sessionSaveFailed)
        }
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + FocusLogStore.statusMessageSeconds) { [weak self] in
            if self?.statusMessage == message { self?.statusMessage = nil }
        }
    }

    // MARK: Export

    /// The web posted the CSV to the Mac's `download_focus_summaries` handler, which only pointed the
    /// user at the browser dashboard; natively we can just save the file.
    func exportCSV() {
        let headers = [strings.focusMode, strings.duration, strings.startTime, strings.finishTime,
                       strings.intention, strings.achievements, strings.distractions]
        let csv = FocusLogMath.csv(entries, headers: headers)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = FocusLogMath.csvFileName
        panel.allowedFileTypes = ["csv"]
        panel.canCreateDirectories = true
        let write: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                addLog(text: "stats export csv failed:- \(error.localizedDescription)")
            }
        }
        if let window = mainWindowControllerObj?.window {
            panel.beginSheetModal(for: window, completionHandler: write)
        } else {
            write(panel.runModal())
        }
    }
}
