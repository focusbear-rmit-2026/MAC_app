//
//  ToDoToolsViews.swift
//  Focus Bear
//
//  The tools behind the To-do List's "⋯" menu, each a sheet: Brain dump → AI tasks
//  (`POST /to-do/convert-brain-dump`, web `standalone-brain-dump`), the Eisenhower matrix (web
//  `EisenhowerMatrixModal`) and Procrastinate — save distracting links for later (`/saved-website`,
//  web `dashboard/to-do/procrastinate`).
//

import SwiftUI
import AppKit

// MARK: - Sheet chrome

private struct ToDoSheetHeader<Trailing: View>: View {
    let title: String
    let closeTitle: String
    var canClose: Bool = true
    let onClose: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title).font(.title2).bold()
            Spacer()
            trailing()
            SwiftUI.Button(action: onClose) { Text(closeTitle) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                .keyboardShortcut(.cancelAction)
                .disabled(!canClose)
        }
    }
}

// MARK: - Brain dump → tasks

struct ToDoBrainDumpSheet: View {
    @ObservedObject var store: ToDoStore
    private var strings: ToDoStrings { store.strings }
    private var hasConvertedTasks: Bool { !store.brainDumpTasks.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ToDoSheetHeader(title: hasConvertedTasks ? strings[.tasksFromBrainDump] : strings[.brainDumpTitle],
                            closeTitle: strings[.close], canClose: !store.isCreatingBrainDumpTasks, onClose: close) {
                if hasConvertedTasks {
                    SwiftUI.Button(action: { store.createBrainDumpTasks() }) {
                        Text(store.isCreatingBrainDumpTasks ? strings[.saving] : strings[.createTasks])
                    }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                    .disabled(store.validBrainDumpTasks.isEmpty || store.validBrainDumpTasks.count != store.brainDumpTasks.count || store.isCreatingBrainDumpTasks)
                }
            }
            if hasConvertedTasks { convertedList } else { input }
            if hasConvertedTasks && store.validBrainDumpTasks.count != store.brainDumpTasks.count {
                Text(strings[.brainDumpInvalidDraft]).foregroundColor(.red).font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let error = store.brainDumpError {
                Text(error).foregroundColor(.red).font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(minWidth: 620, idealWidth: 660, minHeight: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func close() {
        guard !store.isCreatingBrainDumpTasks else { return }
        store.resetBrainDump()
        store.isBrainDumpVisible = false
    }

    private var input: some View {
        VStack(alignment: .leading, spacing: 10) {
            ToDoMultilineEditor(text: $store.brainDumpText, placeholder: strings[.brainDumpPlaceholder], height: 180)
            HStack {
                Text("\(store.brainDumpText.count) / \(ToDoStore.brainDumpCharLimit)").font(.system(size: 11)).foregroundColor(.secondary)
                Spacer()
                SwiftUI.Button(action: { store.convertBrainDump(force: false) }) {
                    Label(store.isConvertingBrainDump ? strings[.converting] : strings[.brainDumpToTasks], systemImage: "sparkles")
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                .disabled(store.brainDumpText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isConvertingBrainDump)
            }
            if store.showVaguePrompt {
                VStack(alignment: .leading, spacing: 8) {
                    Text(strings[.vagueInputPrompt]).font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
                    SwiftUI.Button(action: { store.convertBrainDump(force: true) }) { Text(strings[.convertAnyway]) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                }
                .padding(10)
                .background(ToDoTheme.today.opacity(0.12))
                .cornerRadius(ToDoTheme.cornerRadius)
            }
            Spacer(minLength: 0)
        }
    }

    private var convertedList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.format(.tasksWillBeCreated, ToDoStrings.countToken, String(store.validBrainDumpTasks.count)))
                .font(.system(size: 12)).foregroundColor(.secondary)
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(store.brainDumpTasks) { task in
                        BrainDumpTaskRow(store: store, task: task)
                            .disabled(store.isCreatingBrainDumpTasks)
                    }
                }
            }
        }
    }
}

private struct BrainDumpTaskRow: View {
    @ObservedObject var store: ToDoStore
    let task: BrainDumpTask
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("", text: Binding(get: { task.task_name }, set: { var copy = task; copy.task_name = $0; store.updateBrainDumpTask(copy) }))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("", text: Binding(get: { String(task.estimatedMinutes) }, set: { var copy = task; copy.estimatedMinutes = Int($0) ?? 0; store.updateBrainDumpTask(copy) }))
                    .textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 50)
                Text(strings[.minutes]).font(.system(size: 11)).foregroundColor(.secondary)
                SwiftUI.Button(action: { store.removeBrainDumpTask(task) }) { Image(systemName: "trash").foregroundColor(.secondary) }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
            }
            if !task.subtasks.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text(strings[.subtasks] + ":").font(.system(size: 11)).foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(task.subtasks.enumerated()), id: \.offset) { index, name in
                            HStack(spacing: 4) {
                                Text("• \(name)").font(.system(size: 11))
                                SwiftUI.Button(action: { var copy = task; copy.subtasks.remove(at: index); store.updateBrainDumpTask(copy) }) {
                                    Image(systemName: "xmark.circle").font(.system(size: 10)).foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(ToDoTheme.card)
        .cornerRadius(ToDoTheme.cornerRadius)
    }
}

// MARK: - Eisenhower matrix

struct ToDoEisenhowerSheet: View {
    @ObservedObject var store: ToDoStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ToDoSheetHeader(title: strings[.eisenhowerMatrix], closeTitle: strings[.close], onClose: { store.isMatrixVisible = false }) {
                SwiftUI.Button(action: { store.exportAllTasks() }) { Label(strings[.exportCsv], systemImage: "square.and.arrow.up") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                    .disabled(store.isExporting)
            }
            HStack(spacing: 8) {
                Spacer().frame(width: 20)
                Text(strings[.urgent]).font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity)
                Text(strings[.notUrgent]).font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity)
            }
            HStack(spacing: 8) {
                axisLabel(strings[.important])
                quadrantCell(.doIt)
                quadrantCell(.decide)
            }
            HStack(spacing: 8) {
                axisLabel(strings[.notImportant])
                quadrantCell(.delegate)
                quadrantCell(.delete)
            }
        }
        .padding(16)
        .frame(minWidth: 760, idealWidth: 820, minHeight: 560, idealHeight: 620)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func axisLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            .rotationEffect(.degrees(-90)).frame(width: 20)
    }

    private func quadrantCell(_ quadrant: EisenhowerQuadrant) -> some View {
        let tasks = store.matrixTasks(quadrant)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(strings.quadrantShortLabel(quadrant)).font(.system(size: 13, weight: .bold))
                ToDoChip(text: "\(tasks.count)", tint: ToDoTheme.quadrantColor(quadrant))
                Spacer()
            }
            Text(strings.quadrantLabel(quadrant)).font(.system(size: 11)).foregroundColor(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(tasks) { task in
                        SwiftUI.Button(action: { store.isMatrixVisible = false; store.openEditor(for: task) }) {
                            HStack(spacing: 6) {
                                if let emoji = task.iconEmoji { Text(emoji) }
                                Text(task.title).font(.system(size: 12)).lineLimit(1)
                                Spacer()
                                if task.due_date != nil {
                                    Text(strings.dueLabel(task.due_date)).font(.system(size: 10)).foregroundColor(.secondary)
                                }
                            }
                            .padding(6).background(ToDoTheme.field).cornerRadius(5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ToDoTheme.quadrantColor(quadrant).opacity(0.12))
        .cornerRadius(ToDoTheme.cornerRadius)
    }
}

// MARK: - Procrastinate (saved websites)

struct ToDoProcrastinateSheet: View {
    @ObservedObject var store: ToDoStore
    @SwiftUI.State private var url = ""
    @SwiftUI.State private var note = ""
    @SwiftUI.State private var selectedIds: Set<String> = []
    @SwiftUI.State private var isAdding = false

    private static let noteMaxLength = 255
    private var strings: ToDoStrings { store.strings }

    private var urlError: String? {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard ToDoProcrastinateSheet.isValidUrl(trimmed) else { return strings[.invalidUrl] }
        if store.savedWebsites.contains(where: { ToDoProcrastinateSheet.normalized($0.url) == ToDoProcrastinateSheet.normalized(trimmed) }) {
            return strings[.duplicateUrl]
        }
        return nil
    }
    private var canAdd: Bool { !url.trimmingCharacters(in: .whitespaces).isEmpty && urlError == nil && !isAdding }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ToDoSheetHeader(title: strings[.procrastinate], closeTitle: strings[.close], onClose: { store.isProcrastinateVisible = false }) {
                if !selectedIds.isEmpty {
                    SwiftUI.Button(action: { store.deleteSavedWebsites(ids: Array(selectedIds)); selectedIds = [] }) { Text(strings[.deleteAll]) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                }
            }
            Text(strings[.procrastinateInfo]).font(.system(size: 12)).foregroundColor(.secondary)
            form
            Divider()
            list
        }
        .padding(16)
        .frame(minWidth: 620, idealWidth: 660, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(strings[.url]).font(.system(size: 12, weight: .semibold)).frame(width: 40, alignment: .leading)
                TextField("https://", text: $url, onCommit: add).textFieldStyle(RoundedBorderTextFieldStyle())
            }
            if let error = urlError {
                Text(error).font(.system(size: 11)).foregroundColor(ToDoTheme.overdue).padding(.leading, 48)
            }
            HStack(alignment: .top, spacing: 8) {
                Text(strings[.note]).font(.system(size: 12, weight: .semibold)).frame(width: 40, alignment: .leading)
                VStack(alignment: .trailing, spacing: 2) {
                    ToDoMultilineEditor(text: $note, placeholder: strings[.note], height: 56)
                        .onChange(of: note) { value in
                            if value.count > ToDoProcrastinateSheet.noteMaxLength { note = String(value.prefix(ToDoProcrastinateSheet.noteMaxLength)) }
                        }
                    Text("\(note.count) / \(ToDoProcrastinateSheet.noteMaxLength)").font(.system(size: 10)).foregroundColor(.secondary)
                }
                SwiftUI.Button(action: add) { Text(strings[.add]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                    .disabled(!canAdd)
            }
        }
    }

    private var list: some View {
        Group {
            if store.isFetchingSavedWebsites && store.savedWebsites.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.savedWebsites.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark.slash").font(.system(size: 30)).foregroundColor(.secondary)
                    Text(strings[.noUrlsFound]).font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(store.savedWebsites) { website in row(website) }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ website: SavedWebsite) -> some View {
        HStack(alignment: .top, spacing: 8) {
            SwiftUI.Button(action: { toggle(website.id) }) {
                Image(systemName: selectedIds.contains(website.id) ? "checkmark.square.fill" : "square")
                    .foregroundColor(selectedIds.contains(website.id) ? ToDoTheme.accent : .secondary)
            }
            .buttonStyle(PlainButtonStyle()).pointingHandCursor()
            VStack(alignment: .leading, spacing: 2) {
                if let title = website.title, !title.isEmpty { Text(title).font(.system(size: 12, weight: .semibold)) }
                SwiftUI.Button(action: { open(website.url) }) {
                    Text(website.url).font(.system(size: 12)).foregroundColor(Color(NSColor.linkColor)).lineLimit(1)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                if let note = website.note, !note.isEmpty {
                    Text("\(strings[.note]): \(note)").font(.system(size: 11)).foregroundColor(.secondary)
                }
            }
            Spacer()
            SwiftUI.Button(action: { store.deleteSavedWebsite(website) }) { Image(systemName: "trash").foregroundColor(.secondary) }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .help(strings[.delete])
        }
        .padding(8)
        .background(ToDoTheme.card)
        .cornerRadius(ToDoTheme.cornerRadius)
    }

    private func toggle(_ id: String) {
        if selectedIds.contains(id) { selectedIds.remove(id) } else { selectedIds.insert(id) }
    }

    private func add() {
        guard canAdd else { return }
        isAdding = true
        store.addSavedWebsite(url: url.trimmingCharacters(in: .whitespaces), note: note.trimmingCharacters(in: .whitespacesAndNewlines)) { success in
            isAdding = false
            if success { url = ""; note = "" }
        }
    }

    /// Saved URLs are stored without a scheme; add one before opening in the browser.
    private func open(_ raw: String) {
        let withScheme = raw.contains("://") ? raw : "https://\(raw)"
        if let url = URL(string: withScheme) { NSWorkspace.shared.open(url) }
    }

    private static func isValidUrl(_ value: String) -> Bool {
        let withScheme = value.contains("://") ? value : "https://\(value)"
        guard let url = URL(string: withScheme), let host = url.host else { return false }
        return host.contains(".") && !host.hasPrefix(".") && !host.hasSuffix(".")
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "^https?://", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
