//
//  ToDoListView.swift
//  Focus Bear
//
//  Native replacement for the dashboard.focusbear.io/webview/tools-todo-list webview: Tasks / Projects
//  tabs, the tasks toolbar (new / search / filter / sort / tools), the Doing · To do · Done sections
//  and the task rows (a click reveals Snooze · Edit · Mark complete · Delete beneath the row). SwiftUI,
//  hosted by todoListToolVc via NSHostingView. Same API behaviour as the web page it replaces, laid
//  out to scan faster: title first, everything else as small badges.
//

import SwiftUI
import AppKit

// MARK: - Theme

enum ToDoTheme {
    static let accent = Color(NSColor(named: "dark_OrangeColor") ?? NSColor.systemOrange)
    static let accentSoft = Color(NSColor(named: "light_OrangeColor") ?? NSColor.systemOrange).opacity(0.35)
    static let card = Color(NSColor.controlBackgroundColor)
    static let separator = Color(NSColor.separatorColor)
    static let field = Color(NSColor.textBackgroundColor)
    static let overdue = Color(NSColor.systemRed)
    static let today = Color(NSColor.systemOrange)
    static let good = Color(NSColor.systemGreen)
    static let neutral = Color(NSColor.tertiaryLabelColor)
    static let info = Color(NSColor.systemBlue)
    static let cornerRadius: CGFloat = 8
    static let rowSpacing: CGFloat = 6

    /// The colour a due date is shown in: red once it has passed, orange on the day, otherwise
    /// unremarkable. One definition so every due chip and metric agrees.
    static func dueTint(_ isoString: String?, isCompleted: Bool) -> Color {
        switch ToDoDates.dueState(isoString, isCompleted: isCompleted) {
        case .overdue: return overdue
        case .today: return today
        default: return neutral
        }
    }

    static func bucketColor(_ bucket: PortfolioBucket) -> Color {
        switch bucket {
        case .onTrack: return good
        case .atRisk: return today
        case .critical: return overdue
        case .noDeadline: return neutral
        }
    }

    static func quadrantColor(_ quadrant: EisenhowerQuadrant) -> Color {
        switch quadrant {
        case .doIt: return overdue
        case .decide: return today
        case .delegate: return info
        case .delete: return neutral
        }
    }
}

// MARK: - Shared small views

/// A small rounded badge: optional SF Symbol + text, tinted.
struct ToDoChip: View {
    var text: String
    var systemImage: String? = nil
    var tint: Color = ToDoTheme.neutral
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage = systemImage { Image(systemName: systemImage).font(.system(size: 9, weight: .semibold)) }
            Text(text).lineLimit(1)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(filled ? .white : tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(filled ? tint : tint.opacity(0.14))
        .cornerRadius(6)
    }
}

/// Single-line NSTextField that swallows Return itself. In the app's borderless full-screen window
/// the default button (the routine's "Start") otherwise fires on Return even while a text field has
/// focus — same guard as `EditOnClickTextField` in the Day Plan.
struct ReturnGuardTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void = {}
    /// Focus leaving the field. The due-date editor uses it to apply a typed date the user never
    /// pressed Return on — they typed "14d" and clicked Save, and the date was dropped
    /// (report 2026-09-11_21-40-57, follow-up).
    var onEndEditing: () -> Void = {}
    var isBordered = true
    var fontSize: CGFloat = 13

    final class GuardedTextField: NSTextField {
        var onCommit: () -> Void = {}
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            if event.type == .keyDown, event.keyCode == 36 || event.keyCode == 76,
               let editor = currentEditor(), window?.firstResponder === editor {
                onCommit()
                return true
            }
            return super.performKeyEquivalent(with: event)
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ReturnGuardTextField
        init(_ parent: ReturnGuardTextField) { self.parent = parent }
        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }
        func controlTextDidEndEditing(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
            parent.onEndEditing()
        }
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            // A normal field editor sends insertNewline to its delegate, without necessarily
            // passing through performKeyEquivalent (the borderless-window fallback above).
            parent.text = textView.string
            parent.onCommit()
            return true
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> GuardedTextField {
        let field = GuardedTextField()
        field.delegate = context.coordinator
        field.isBordered = isBordered
        field.isBezeled = isBordered
        field.bezelStyle = .roundedBezel
        field.drawsBackground = isBordered
        // Not literal white: in Dark mode that is white-on-white. Light mode is unchanged.
        field.backgroundColor = .textBackgroundColor
        field.focusRingType = .none
        field.font = NSFont.systemFont(ofSize: fontSize)
        field.lineBreakMode = .byTruncatingTail
        field.cell?.usesSingleLineMode = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateNSView(_ field: GuardedTextField, context: Context) {
        context.coordinator.parent = self
        field.onCommit = onCommit
        field.placeholderString = placeholder
        if field.stringValue != text { field.stringValue = text }
    }
}

/// Bordered search box with a magnifier and an optional spinner.
struct ToDoSearchField: View {
    @Binding var text: String
    var placeholder: String
    var isBusy: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            ReturnGuardTextField(text: $text, placeholder: placeholder, isBordered: false)
            if isBusy {
                ProgressView().scaleEffect(0.5).frame(width: 16, height: 16)
            } else if !text.isEmpty {
                SwiftUI.Button(action: { text = "" }) { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
                    .buttonStyle(PlainButtonStyle())
                    .pointingHandCursor()
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 30)
        .background(ToDoTheme.field)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ToDoTheme.separator))
        .cornerRadius(6)
    }
}

/// Toolbar icon button (bordered, square).
struct ToDoIconButton: View {
    var systemImage: String
    var help: String
    var isActive: Bool = false
    var action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isActive ? .white : .primary)
                .frame(width: 30, height: 30)
                .background(isActive ? ToDoTheme.accent : ToDoTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(isActive ? ToDoTheme.accent : ToDoTheme.separator))
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .help(help)
    }
}

// MARK: - Screen

enum ToDoScreenTab: String, CaseIterable { case tasks, projects }

struct ToDoScreen: View {
    @ObservedObject var todoStore: ToDoStore
    @ObservedObject var projectsStore: ProjectsStore
    @Binding var selectedTab: ToDoScreenTab
    let onClose: () -> Void

    private var strings: ToDoStrings { todoStore.strings }

    /// The screen's own window, so a confirmation can be attached to it rather than presented
    /// app-modally — see `NSAlert.presentAsSheet`.
    @SwiftUI.State private var hostWindow: NSWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("", selection: $selectedTab) {
                    Text(strings[.tabTasks]).tag(ToDoScreenTab.tasks)
                    Text(strings[.tabProjects]).tag(ToDoScreenTab.projects)
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .frame(width: 220)
                Spacer()
            }
            if selectedTab == .tasks {
                TasksTabView(store: todoStore)
            } else {
                ProjectsTabView(store: projectsStore, todoStore: todoStore)
            }
            footer
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(backgroundColor))
        .sheet(item: $todoStore.editorSession) { session in
            ToDoEditorSheet(store: todoStore, task: session.task, initialTitle: session.initialTitle, initialProject: session.initialProject)
        }
        .background(HostWindowReader { hostWindow = $0 })
        // A sheet on this window rather than a SwiftUI Alert: an Alert raised while the editor sheet
        // is up is drawn on the window underneath it, so it holds the keyboard where nobody can see
        // it (report 2026-09-14_11-50-38).
        .onChange(of: todoStore.taskToDelete) { task in
            guard task != nil else { return }
            confirmDelete()
        }
    }

    private func confirmDelete() {
        let alert = NSAlert()
        alert.messageText = strings[.deleteTask]
        alert.informativeText = strings[.deleteTaskConfirmation]
        alert.addButton(withTitle: strings[.delete])      // .alertFirstButtonReturn
        alert.addButton(withTitle: strings[.cancel])
        alert.buttons.first?.hasDestructiveAction = true
        alert.presentAsSheet(for: hostWindow) { response in
            if response == .alertFirstButtonReturn {
                todoStore.confirmDelete()
            } else {
                todoStore.taskToDelete = nil
            }
        }
    }

    private var footer: some View {
        HStack {
            if let message = selectedTab == .tasks ? todoStore.statusMessage : projectsStore.statusMessage {
                Text(message).font(.system(size: 12)).foregroundColor(.secondary).transition(.opacity)
            }
            Spacer()
            // #2598-related: the macOS window's title-bar close is the single way out — no in-view
            // Close button. Stepping back from an open project/note uses that view's own Back control.
        }
    }
}

// MARK: - Tasks tab

struct TasksTabView: View {
    @ObservedObject var store: ToDoStore
    /// The same forecast store the Projects tab uses — `ProjectsStore` is constructed with
    /// `todoStore.forecast` — so the reschedule plan has one owner and one implementation wherever
    /// it is opened from.
    @ObservedObject private var forecast: LocalForecastStore
    init(store: ToDoStore) {
        self.store = store
        self.forecast = store.forecast
    }
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            toolbar
            if let banner = store.completionBannerText {
                completionBanner(banner)
            }
            reprioritiseBanner
            if store.showFilters {
                ToDoFiltersPanel(store: store)
            }
            ToDoSectionsList(store: store)
        }
        .sheet(isPresented: $store.isBrainDumpVisible) { ToDoBrainDumpSheet(store: store) }
        .sheet(isPresented: $store.isMatrixVisible) { ToDoEisenhowerSheet(store: store) }
        .sheet(isPresented: $store.isProcrastinateVisible) { ToDoProcrastinateSheet(store: store) }
        // The reschedule plan belongs to the task list, not the project list ("Move reschedule tasks
        // to the Tasks list screen rather than Projects screen", report 2026-09-16_06-38-30). Same
        // sheet, same store — the Projects tab no longer presents it.
        .sheet(isPresented: $forecast.showsWorkPlan) { ForecastReschedulePlanSheet(store: forecast) }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            SwiftUI.Button(action: { store.openEditor(for: nil) }) { Label(strings[.newTask], systemImage: "plus") }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                .keyboardShortcut("n", modifiers: .command)
            ToDoSearchField(text: $store.searchQuery, placeholder: strings[.searchPlaceholder], isBusy: store.isSearching)
                .frame(maxWidth: 300)
            ToDoIconButton(systemImage: "line.horizontal.3.decrease.circle", help: strings[.filter],
                           isActive: store.showFilters || store.filters.isActive) { store.showFilters.toggle() }
            sortPicker
            Spacer()
            ToDoIconButton(systemImage: "arrow.clockwise", help: strings[.refresh]) { store.refreshAll() }
            toolsMenu
        }
    }

    private var sortPicker: some View {
        Picker("", selection: $store.sortMode) {
            Text(strings[.sortSmart]).tag(ToDoSortMode.smart).help(strings[.sortSmartTooltip])
            Text(strings[.sortChronological]).tag(ToDoSortMode.chronological).help(strings[.sortChronologicalTooltip])
            Text(strings[.sortDueDate]).tag(ToDoSortMode.dueDate).help(strings[.sortDueDateTooltip])
        }
        .pickerStyle(SegmentedPickerStyle())
        .labelsHidden()
        .frame(width: 210)
        .help(sortHelp)
    }

    private var sortHelp: String {
        switch store.sortMode {
        case .smart: return strings[.sortSmartTooltip]
        case .chronological: return strings[.sortChronologicalTooltip]
        case .dueDate: return strings[.sortDueDateTooltip]
        }
    }

    private var toolsMenu: some View {
        Menu {
            // This menu is where the Tasks list already keeps its whole-list actions that open a
            // sheet — brain dump, the Eisenhower matrix, procrastinate — so the reschedule plan goes
            // here rather than as a fourth button crowding a toolbar that already holds New task,
            // search, filter and a three-way sort picker.
            SwiftUI.Button(action: { forecast.prepareWorkPlanLoadingIfNeeded() }) {
                Label(ForecastText[.reprioritiseMenuItem], systemImage: "calendar.badge.clock")
            }
            .disabled(forecast.isApplying)
            Divider()
            SwiftUI.Button(action: { store.resetBrainDump(); store.isBrainDumpVisible = true }) {
                Label(strings[.brainDumpToTasks], systemImage: "brain")
            }
            SwiftUI.Button(action: { store.exportAllTasks() }) { Label(strings[.exportCsv], systemImage: "square.and.arrow.up") }
                .disabled(store.isExporting)
            SwiftUI.Button(action: { store.isMatrixVisible = true }) { Label(strings[.eisenhowerMatrix], systemImage: "square.grid.2x2") }
            SwiftUI.Button(action: { store.loadSavedWebsites(); store.isProcrastinateVisible = true }) {
                Label(strings[.procrastinate], systemImage: "bookmark")
            }
            Divider()
            SwiftUI.Button(action: { openDashboardIntegrations() }) { Label(strings[.manageIntegrations], systemImage: "link") }
        } label: {
            Image(systemName: "ellipsis.circle").font(.system(size: 15, weight: .medium))
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .menuItemIcons()
        .frame(width: 30, height: 30)
        .background(ToDoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ToDoTheme.separator))
        .cornerRadius(6)
        .help(strings[.moreOptions])
    }

    /// Third-party sync (ClickUp, Trello, calendars, MCP) is managed on the web dashboard.
    private func openDashboardIntegrations() {
        if let url = URL(string: ToDoExternalLinks.integrations) { NSWorkspace.shared.open(url) }
    }

    /// A suggestion, not an alarm: it offers the reschedule plan when the backlog has grown past
    /// what hand-fixing is pleasant, and it can be sent away.
    ///
    /// This is a NEW banner because the Tasks list has none. The Day Plan gets the same offer added
    /// to the over-capacity banner it already shows, rather than a second banner saying nearly the
    /// same thing beside it.
    @ViewBuilder private var reprioritiseBanner: some View {
        if let reason = forecast.reprioritiseSuggestion {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                Text(ReprioritiseSuggestion.text(for: reason))
                    .font(.system(size: 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                SwiftUI.Button(ForecastText[.reprioritiseLink]) { forecast.prepareWorkPlanLoadingIfNeeded() }
                    .buttonStyle(LinkButtonStyle())
                Spacer(minLength: 8)
                SwiftUI.Button(action: { forecast.dismissReprioritiseSuggestion() }) {
                    Image(systemName: "xmark").foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .help(ForecastText[.reprioritiseDismiss])
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(ToDoTheme.cornerRadius)
            .transition(.opacity)
        }
    }

    private func completionBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(ToDoTheme.good)
            Text(text).font(.system(size: 13, weight: .medium)).lineLimit(1)
            Spacer()
            SwiftUI.Button(action: { store.dismissCompletionBanner() }) { Image(systemName: "xmark").foregroundColor(.secondary) }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ToDoTheme.good.opacity(0.12))
        .cornerRadius(ToDoTheme.cornerRadius)
        .transition(.opacity)
    }
}

enum ToDoExternalLinks {
    static let dashboard = "https://dashboard.focusbear.io"
    static let integrations = "\(dashboard)/integrations"
}

// MARK: - Filters panel

private struct ToDoFiltersPanel: View {
    @ObservedObject var store: ToDoStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            filterColumn(strings[.filterDueDate]) {
                let selection = Binding<String>(
                    get: { store.activeDueDatePreset.map { presetKey($0) } ?? "" },
                    set: { value in store.applyDueDatePreset(ToDoStore.DueDatePreset.allCases.first { presetKey($0) == value }) })
                Picker("", selection: selection) {
                    Text(strings[.filterAll]).tag("")
                    ForEach(ToDoStore.DueDatePreset.allCases, id: \.self) { preset in
                        Text(presetLabel(preset)).tag(presetKey(preset))
                    }
                }
                .labelsHidden()
                .pickerStyle(MenuPickerStyle())
            }
            filterColumn(strings[.filterEnergyLevel]) {
                let selection = Binding<String>(
                    get: { store.filters.energyLevel?.rawValue ?? "" },
                    set: { store.filters.energyLevel = ToDoFilters.EnergyLevel(rawValue: $0) })
                Picker("", selection: selection) {
                    Text(strings[.filterAll]).tag("")
                    Text("\(strings[.lowSpoons]) · \(strings[.lowSpoonsSubtitle])").tag(ToDoFilters.EnergyLevel.low.rawValue)
                    Text("\(strings[.fullSpoons]) · \(strings[.fullSpoonsSubtitle])").tag(ToDoFilters.EnergyLevel.full.rawValue)
                }
                .labelsHidden()
                .pickerStyle(MenuPickerStyle())
            }
            filterColumn(strings[.filterProject]) {
                let selection = Binding<String>(
                    get: { store.filters.projectId ?? "" },
                    set: { store.setProjectFilter($0.isEmpty ? nil : $0) })
                Picker("", selection: selection) {
                    Text(strings[.filterAll]).tag("")
                    ForEach(store.projects) { project in
                        Text(strings.projectName(project.name)).tag(project.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(MenuPickerStyle())
            }
            Spacer()
            if store.filters.isActive {
                SwiftUI.Button(action: { store.filters = ToDoFilters() }) { Text(strings[.clearFilters]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
            }
        }
        .padding(12)
        .background(ToDoTheme.card)
        .cornerRadius(ToDoTheme.cornerRadius)
    }

    private func filterColumn<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            content().frame(width: 200)
        }
    }

    private func presetKey(_ preset: ToDoStore.DueDatePreset) -> String { String(describing: preset) }

    private func presetLabel(_ preset: ToDoStore.DueDatePreset) -> String {
        switch preset {
        case .today: return strings[.dueToday]
        case .thisWeek: return strings[.dueThisWeek]
        case .nextWeek: return strings[.dueNextWeek]
        case .next30Days: return strings[.next30Days]
        }
    }
}

// MARK: - Sections list

private struct ToDoSectionsList: View {
    @ObservedObject var store: ToDoStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        Group {
            switch store.emptyState {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .firstTask:
                emptyState(strings[.addYourFirstTask], showNewTask: true)
            case .noSearchMatch:
                emptyState(strings[.couldNotFindTasks], showNewTask: false)
            case .noFilterMatch:
                emptyState(strings[.noTasksMatchFilters], showNewTask: false)
            case .none:
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ToDoTheme.rowSpacing) {
                        ForEach(store.sections) { section in
                            sectionHeader(section)
                            if store.expandedSectionId == section.id {
                                sectionBody(section)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                // A click on empty space (rows take their own clicks first) or Escape drops the selection.
                .contentShape(Rectangle())
                .onTapGesture { store.clearSelection() }
                .onExitCommand { store.clearSelection() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionHeader(_ section: ToDoSection) -> some View {
        let isOpen = store.expandedSectionId == section.id
        return SwiftUI.Button(action: { store.toggleSection(section) }) {
            HStack(spacing: 8) {
                Image(systemName: isOpen ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary).frame(width: 12)
                Text(section.title).font(.system(size: 13, weight: .semibold))
                Text("\(store.totalCount(for: section))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(ToDoTheme.neutral.opacity(0.18)).cornerRadius(8)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(ToDoTheme.card)
            .cornerRadius(ToDoTheme.cornerRadius)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
    }

    @ViewBuilder
    private func sectionBody(_ section: ToDoSection) -> some View {
        if section.tasks.isEmpty {
            Text(strings[.sectionEmpty]).font(.system(size: 12)).foregroundColor(.secondary).padding(.horizontal, 12).padding(.vertical, 6)
        } else {
            ForEach(section.rows) { row in
                ToDoTaskRow(store: store, task: row.task)
                    .onAppear {
                        if row.task.id == section.tasks.last?.id { store.loadNextPage(for: section) }
                    }
            }
            if store.loadingMoreStatus == section.status && section.status != nil {
                ProgressView().scaleEffect(0.6).frame(maxWidth: .infinity).padding(4)
            } else if store.hasMore(for: section) {
                SwiftUI.Button(action: { store.loadNextPage(for: section) }) { Text(strings[.loadMore]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                    .padding(.vertical, 4)
            }
        }
    }

    private func emptyState(_ title: String, showNewTask: Bool) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist").font(.system(size: 36)).foregroundColor(.secondary)
            Text(title).font(.headline)
            if showNewTask {
                SwiftUI.Button(action: { store.openEditor(for: nil) }) { Label(strings[.newTask], systemImage: "plus") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Task row

struct ToDoTaskRow: View {
    @ObservedObject var store: ToDoStore
    let task: ToDoTask
    @SwiftUI.State private var isDuePopoverShown = false
    @SwiftUI.State private var isSnoozeShown = false
    @SwiftUI.State private var isConfirmingDelete = false

    private static let maxProjectChips = 3
    private static let selectedBorderWidth: CGFloat = 2

    private var strings: ToDoStrings { store.strings }
    private var isUpdating: Bool { store.updatingTaskIds.contains(task.id) }
    private var isSelected: Bool { store.selectedTaskId == task.id }

    /// Every project the task belongs to, by name: its tags (the tag id is the project id), plus the
    /// status-owner `project_id` when it isn't among them. Nothing when unassigned.
    private var projectNames: [String] {
        var ids = task.tagList.map { $0.id }
        if let owner = task.project_id, !ids.contains(owner) { ids.append(owner) }
        var seen = Set<String>()
        return ids.compactMap { id -> String? in
            guard seen.insert(id).inserted else { return nil }
            // A project deleted on this Mac is soft-deleted on the backend, so the task keeps its tag.
            // store.project(id:) is already nil, but the tag fallback below would resurrect the old
            // name — skip it, the same way the Day Plan does (DayPlanTaskStore.projectName). (#2680)
            if DayPlanTaskStore.shared.deletedProjectIDs.contains(id) { return nil }
            let raw = store.project(id: id)?.name ?? task.tagList.first { $0.id == id }?.text
            guard let name = raw, !name.isEmpty else { return nil }
            return strings.projectName(name)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            rowContent
            if isSelected { actionBar }
        }
        .background(ToDoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: ToDoTheme.cornerRadius)
                    .stroke(isSelected ? ToDoTheme.accent : ToDoTheme.separator, lineWidth: isSelected ? ToDoTaskRow.selectedBorderWidth : 1))
        .cornerRadius(ToDoTheme.cornerRadius)
        .opacity(task.isCompleted && !isSelected ? 0.7 : 1)
        .onChange(of: isSelected) { selected in if !selected { isConfirmingDelete = false; isSnoozeShown = false } }
        .contextMenu {
            SwiftUI.Button(action: { store.openEditor(for: task) }) { Text(strings[.editTaskTitle]) }
            SwiftUI.Button(action: { store.toggleComplete(task) }) { Text(task.isCompleted ? strings[.markIncomplete] : strings.format(.markComplete, ToDoStrings.titleToken, task.title)) }
            SwiftUI.Button(action: { store.requestDelete(task) }) { Text(strings[.delete]) }
        }
    }

    /// The row proper. A click selects it (and reveals the action bar), a double-click opens the editor;
    /// the checkbox and the Due cell keep their own clicks.
    private var rowContent: some View {
        HStack(alignment: .top, spacing: 10) {
            checkbox
            VStack(alignment: .leading, spacing: 4) {
                titleLine
                metadataLine
            }
            Spacer(minLength: 8)
            metrics
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { store.openEditor(for: task) }
        .onTapGesture { store.select(task) }
    }

    /// Beneath the selected row, joined to it inside the orange border like the Day Plan's selected
    /// unit: Snooze (the Day Plan's smart-snooze popover) · Edit · Mark complete / incomplete · Delete,
    /// which asks inline before it goes.
    private var actionBar: some View {
        HStack(spacing: 8) {
            if isConfirmingDelete {
                Text(strings[.deleteTaskConfirmation]).font(.system(size: 12)).lineLimit(1)
                Spacer()
                SwiftUI.Button(action: { isConfirmingDelete = false }) { Text(strings[.cancel]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 24))
                    .keyboardShortcut(.cancelAction)
                SwiftUI.Button(action: { store.delete(task) }) { Label(strings[.delete], systemImage: "trash") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 24))
            } else {
                actionButton(strings[.snooze], systemImage: "clock.arrow.circlepath") { isSnoozeShown = true }
                    .background(SmartSnoozePopoverPresenter(isPresented: $isSnoozeShown, baseDate: Date(),
                                                            suggestion: { store.snoozeSuggestion(for: task) },
                                                            onSmart: { store.smartSnooze(task) },
                                                            onMove: { store.snooze(task, to: $0) }))
                actionButton(strings[.edit], systemImage: "square.and.pencil") { store.openEditor(for: task) }
                actionButton(task.isCompleted ? strings[.markIncomplete] : strings[.markCompleteShort],
                             systemImage: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle") { store.toggleComplete(task) }
                actionButton(strings[.delete], systemImage: "trash") { isConfirmingDelete = true }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(ToDoTheme.accent.opacity(0.1))
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) { Label(title, systemImage: systemImage) }
            .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 24))
            .disabled(isUpdating)
    }

    private var checkbox: some View {
        Group {
            if isUpdating {
                ProgressView().scaleEffect(0.5).frame(width: 18, height: 18)
            } else {
                SwiftUI.Button(action: { store.toggleComplete(task) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(task.isCompleted ? ToDoTheme.good : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .pointingHandCursor()
                .help(task.isCompleted ? strings[.markIncomplete] : strings.format(.markComplete, ToDoStrings.titleToken, task.title))
            }
        }
        .padding(.top, 1)
    }

    private var titleLine: some View {
        HStack(spacing: 6) {
            if let emoji = task.iconEmoji { Text(emoji).font(.system(size: 14)) }
            Text(task.title)
                .font(.system(size: 14, weight: .medium))
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
                .lineLimit(2)
        }
    }

    private var metadataLine: some View {
        let projects = projectNames
        return HStack(spacing: 6) {
            ForEach(projects.prefix(ToDoTaskRow.maxProjectChips), id: \.self) { name in
                ToDoChip(text: "#\(name)", tint: ToDoTheme.accent)
            }
            if projects.count > ToDoTaskRow.maxProjectChips {
                ToDoChip(text: "+\(projects.count - ToDoTaskRow.maxProjectChips)")
                    .help(projects.dropFirst(ToDoTaskRow.maxProjectChips).joined(separator: "\n"))
            }
            if task.durationSeconds > 0 {
                ToDoChip(text: ToDoDates.durationLabel(seconds: task.durationSeconds), systemImage: "clock")
            }
            if !task.subtaskList.isEmpty {
                let done = task.subtaskList.filter { $0.is_completed }.count
                ToDoChip(text: "\(done)/\(task.subtaskList.count) \(strings[.subtasks].lowercased())", systemImage: "checklist")
                    .help(task.subtaskList.map { "• \($0.name)" }.joined(separator: "\n"))
            }
            if task.hasDetails {
                Image(systemName: "text.alignleft").font(.system(size: 10)).foregroundColor(.secondary)
                    .help(ToDoHTML.plainText(task.details ?? ""))
            }
            if let label = store.customStatusLabel(id: task.custom_status_id) {
                ToDoChip(text: label)
            }
        }
    }

    /// Web `TaskSortSegment`: Due · Created · TOP, the active sort key highlighted. The Due cell is
    /// also the due-date popover trigger ("2d", "fri", "30th"…, or clear), like the web.
    private var metrics: some View {
        HStack(spacing: 10) {
            dueMetric
            metric(strings[.createdShort], ToDoDates.abbreviated(task.created_at), active: store.sortMode == .chronological)
            let score = ToDoScoring.topScore(of: task)
            metric(strings[.topShort], score > 0 ? ToDoScoring.rounded(score) : "—", active: store.sortMode == .smart)
                .help(strings[.topScoreTooltip])
        }
    }

    private var dueMetric: some View {
        let state = ToDoDates.dueState(task.due_date, isCompleted: task.isCompleted)
        let tint: Color? = state == .overdue ? ToDoTheme.overdue : (state == .today ? ToDoTheme.today : nil)
        return SwiftUI.Button(action: { isDuePopoverShown = true }) {
            metric(strings[.dueShort], task.due_date == nil ? "—" : strings.dueLabel(task.due_date), active: store.sortMode == .dueDate, tint: tint)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .help(strings[.editDueDate])
        .popover(isPresented: $isDuePopoverShown, arrowEdge: .bottom) {
            ToDoDueDatePopover(strings: strings, currentDue: task.due_date) { day in
                isDuePopoverShown = false
                store.setDueDate(task, day: day)
            }
        }
    }

    private func metric(_ label: String, _ value: String, active: Bool, tint: Color? = nil) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label.uppercased()).font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
            Text(value).font(.system(size: 11, weight: active || tint != nil ? .semibold : .regular))
                .foregroundColor(tint ?? (active ? ToDoTheme.accent : .primary))
        }
        .frame(minWidth: 52, alignment: .trailing)
    }
}

// MARK: - Due-date popover

/// Web `DueDateSnoozePopover`: free-text ("2d", "30th", "fri"), live preview, presets, clear.
struct ToDoDueDatePopover: View {
    let strings: ToDoStrings
    let currentDue: String?
    let onCommit: (Date?) -> Void
    @SwiftUI.State private var input = ""

    private var parsed: Date? { ToDoDueDateParser.parse(input) }
    private var trimmed: String { input.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings[.editDueDate]).font(.system(size: 12, weight: .semibold))
            ReturnGuardTextField(text: $input, placeholder: strings[.dueDatePlaceholder], onCommit: commit)
                .frame(width: 220)
            if !trimmed.isEmpty {
                Text(parsed.map { strings.dueLabel(ToDoDates.ymd($0)) } ?? strings[.unrecognisedDate])
                    .font(.system(size: 11))
                    .foregroundColor(parsed == nil ? ToDoTheme.overdue : .secondary)
                HStack {
                    Spacer()
                    SwiftUI.Button(action: commit) { Text(strings[.save]) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                        .disabled(parsed == nil)
                }
            } else {
                HStack(spacing: 6) {
                    presetButton(strings[.today]) { onCommit(Calendar.current.startOfDay(for: Date())) }
                    presetButton(strings[.tomorrow]) { onCommit(Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))) }
                    presetButton(strings[.nextWeek]) { onCommit(Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: Date()))) }
                    if let due = currentDue, !due.isEmpty {
                        presetButton(strings[.clear]) { onCommit(nil) }
                    }
                }
            }
        }
        .padding(12)
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) { Text(title).font(.system(size: 11)) }
            .buttonStyle(BorderedButtonStyle())
            .pointingHandCursor()
    }

    private func commit() {
        guard let day = parsed else { return }
        onCommit(day)
    }
}

/// macOS renders SwiftUI menu labels title-only unless the style says otherwise, so every
/// `Label(_, systemImage:)` inside a `Menu` silently loses its icon — the icons were always
/// specified, they were just never drawn (report 2026-09-16_08-45-24). Applying this to the `Menu`
/// rather than each item means it reaches them through the environment, so an item added later
/// gets its icon without the author having to know about this quirk.
///
/// `.titleAndIcon` is macOS 12+ and this app targets macOS 11, hence the availability split.
struct MenuItemIconsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 12.0, *) {
            content.labelStyle(.titleAndIcon)
        } else {
            content
        }
    }
}

extension View {
    func menuItemIcons() -> some View { modifier(MenuItemIconsModifier()) }
}
