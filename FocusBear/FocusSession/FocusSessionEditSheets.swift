//
//  FocusSessionEditSheets.swift
//  Focus Bear
//
//  The two task-management modals of the ongoing-focus-session screen:
//    • "Edit task"    (Figma 1.1.1) — edits a real to-do through `PUT /to-do` (upsert with an id)
//    • "Add Filters"  (Figma 1.2.2) — narrows the task picker by perspiration, project and due date
//
//  Both are built from the same field/chip/slider parts, which the "Create new task" page reuses.
//

import SwiftUI

// MARK: - Edit task (Figma 1.1.1)

@available(macOS 11.0, *)
struct FocusSessionEditTaskSheet: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore

    private static let sheetWidthDesignPixels: CGFloat = 1180

    private var scale: FocusSessionScale {
        FocusSessionScale(contentWidth: FocusSessionTokens.designWidthPoints)
    }

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            header
            ScrollView {
                FocusSessionTaskForm(store: store, edits: $store.taskEdits, scale: scale, showsStatus: true)
                    .disabled(store.isSavingTask || store.isTaskEditingLocked)
            }
            if let error = store.taskEditError {
                Text(error).font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.destructive)
            }
            if store.editFailed {
                Text(store.strings.couldNotSaveTask)
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.destructive)
            }
            actions
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
        .focusSessionSheetFrame(widthDesignPixels: Self.sheetWidthDesignPixels, scale: scale)
        .background(FocusSessionPalette.panelBackground)
    }

    private var header: some SwiftUI.View {
        HStack {
            Text(store.strings.editTaskTitle)
                .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                .foregroundColor(FocusSessionPalette.primaryText)
            Spacer()
            SwiftUI.Button(action: { store.activeSheet = nil }) {
                Image(systemName: "xmark")
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.secondaryText)
            }
            .buttonStyle(FBButtonStyle())
            .help(store.strings.closeButton)
            .disabled(store.isSavingTask)
        }
    }

    private var actions: some SwiftUI.View {
        VStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
            FocusSessionSecondaryButton(title: store.strings.cancelButton, scale: scale) {
                store.activeSheet = nil
            }
            .disabled(store.isSavingTask)
            FocusSessionPrimaryButton(
                title: store.isSavingTask ? store.strings.savingTask : store.strings.saveTaskButton,
                scale: scale,
                isEnabled: !store.isSavingTask && !store.isTaskEditingLocked && store.taskEdits.isValid
            ) {
                store.saveTaskEdits()
            }
        }
    }
}

// MARK: - Add filters (Figma 1.2.2)

@available(macOS 11.0, *)
struct FocusSessionFiltersPage: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    let scale: FocusSessionScale

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.sectionGap)) {
                    perspirationSection
                    projectSection
                    dueDateSection
                }
            }
            actions
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
    }

    private var header: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
            SwiftUI.Button(action: store.cancelFilters) {
                Image(systemName: "arrow.left")
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.primaryText)
            }
            .buttonStyle(FBButtonStyle())
            Text(store.strings.addFiltersTitle)
                .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                .foregroundColor(FocusSessionPalette.primaryText)
            Spacer()
        }
    }

    // Perspiration: two mutually exclusive chips over the to-do's `perspiration_level` (1-10).
    private var perspirationSection: some SwiftUI.View {
        FocusSessionFilterSection(title: store.strings.filterPerspirationLabel,
                                  symbol: "figure.strengthtraining.traditional",
                                  scale: scale) {
            HStack(spacing: scale.pt(FocusSessionLayout.cardGap)) {
                ForEach(FocusSessionSpoonsBand.allCases) { band in
                    FocusSessionChip(title: label(for: band),
                                     isSelected: store.filterDraft.spoons == band,
                                     scale: scale) {
                        store.toggleSpoonsFilter(band)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func label(for band: FocusSessionSpoonsBand) -> String {
        switch band {
        case .fullSpoons: return store.strings.filterFullSpoons
        case .lowSpoons: return store.strings.filterLowSpoons
        }
    }

    // Project: search the catalogue from `GET /projects`, then pick one — applied server-side.
    private var projectSection: some SwiftUI.View {
        FocusSessionFilterSection(title: store.strings.filterProjectLabel,
                                  symbol: "heart",
                                  scale: scale) {
            VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
                FocusSessionSearchField(placeholder: store.strings.searchProjectPlaceholder,
                                        text: $store.projectQuery,
                                        scale: scale)
                FocusSessionWrappingChips(items: store.visibleProjects.map { ($0.id, $0.name) },
                                          selectedId: store.filterDraft.projectId,
                                          scale: scale) { id in
                    store.toggleProjectFilter(id)
                }
            }
        }
    }

    // Due date: a two-handle range over the design's Overdue → In a month axis, matched against the
    // to-do's `due_date`.
    private var dueDateSection: some SwiftUI.View {
        FocusSessionFilterSection(title: store.strings.filterDueDateLabel,
                                  symbol: "clock",
                                  scale: scale) {
            FocusSessionDueDateRange(store: store, scale: scale)
        }
    }

    private var actions: some SwiftUI.View {
        VStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
            FocusSessionSecondaryButton(title: store.strings.cancelButton, scale: scale) {
                store.cancelFilters()
            }
            FocusSessionPrimaryButton(title: store.strings.addFiltersButton(count: store.filterDraft.activeCount),
                                      scale: scale,
                                      isEnabled: true) {
                store.applyFilters()
            }
        }
    }
}

/// The design's two-handle due-date slider: an axis of labelled stops (Overdue … In a month) with the
/// selected range tinted between the handles.
@available(macOS 11.0, *)
private struct FocusSessionDueDateRange: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    let scale: FocusSessionScale

    private static let trackHeightDesignPixels: CGFloat = 18
    private static let handleSizeDesignPixels: CGFloat = 56
    private static let captionGapDesignPixels: CGFloat = 40

    private var lowerDays: Int { store.filterDraft.dueInDaysLowerBound ?? FocusSessionDueDateScale.lowestDays }
    private var upperDays: Int { store.filterDraft.dueInDaysUpperBound ?? FocusSessionDueDateScale.highestDays }

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(Self.captionGapDesignPixels)) {
            HStack {
                Text(store.strings.daysFromToday(lowerDays))
                Spacer()
                Text(store.strings.daysFromToday(upperDays))
            }
            .font(scale.font(FocusSessionLayout.bodyFont))
            .foregroundColor(FocusSessionPalette.secondaryText)

            GeometryReader { geometry in
                track(width: geometry.size.width)
            }
            .frame(height: scale.pt(Self.handleSizeDesignPixels))

            axisCaptions
        }
    }

    private func track(width: CGFloat) -> some SwiftUI.View {
        let handle = scale.pt(Self.handleSizeDesignPixels)
        let usable = max(1, width - handle)
        let lowerX = CGFloat(FocusSessionDueDateScale.position(forDays: lowerDays)) * usable
        let upperX = CGFloat(FocusSessionDueDateScale.position(forDays: upperDays)) * usable
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(FocusSessionPalette.mutedFill)
                .frame(height: scale.pt(Self.trackHeightDesignPixels))
            Capsule()
                .fill(FocusSessionPalette.accent)
                .frame(width: max(0, upperX - lowerX), height: scale.pt(Self.trackHeightDesignPixels))
                .offset(x: lowerX + handle / 2)
            handleView(at: lowerX, usable: usable, isLower: true)
            handleView(at: upperX, usable: usable, isLower: false)
        }
    }

    private func handleView(at offset: CGFloat, usable: CGFloat, isLower: Bool) -> some SwiftUI.View {
        let size = scale.pt(Self.handleSizeDesignPixels)
        return RoundedRectangle(cornerRadius: size / 3)
            .fill(FocusSessionPalette.accent.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: size / 3)
                    .strokeBorder(FocusSessionPalette.accent, lineWidth: scale.pt(FocusSessionLayout.hairline))
            )
            .frame(width: size, height: size)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let position = Double(min(max(0, value.location.x - size / 2), usable) / usable)
                        commit(days: FocusSessionDueDateScale.days(atPosition: position), isLower: isLower)
                    }
            )
    }

    /// Handles can't cross: dragging one past the other pins it at the other's value.
    private func commit(days: Int, isLower: Bool) {
        if isLower {
            store.setDueDateFilter(lowerDays: min(days, upperDays), upperDays: upperDays)
        } else {
            store.setDueDateFilter(lowerDays: lowerDays, upperDays: max(days, lowerDays))
        }
    }

    private var axisCaptions: some SwiftUI.View {
        HStack(spacing: 0) {
            ForEach(captions, id: \.self) { caption in
                Text(caption)
                    .font(scale.font(FocusSessionLayout.bodyFont))
                    .foregroundColor(FocusSessionPalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var captions: [String] {
        [store.strings.dueOverdue, store.strings.dueToday, store.strings.dueInAWeek,
         store.strings.dueInTwoWeeks, store.strings.dueInAMonth]
    }
}

// MARK: - Shared form parts

/// The task fields shared by "Edit task" and "Create new task".
@available(macOS 11.0, *)
struct FocusSessionTaskForm: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    @SwiftUI.Binding var edits: FocusSessionTaskEdits
    let scale: FocusSessionScale
    /// The create page has no status picker — a new task is always "not started".
    let showsStatus: Bool
    @SwiftUI.State private var durationText = ""

    private static let descriptionHeightDesignPixels: CGFloat = 220
    /// `NSComboBox` draws at its own control metrics, so this is in points, not design pixels — the
    /// same height the Notes screen gives the identical control.
    private static let comboBoxHeightPoints: CGFloat = 24

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            field(store.strings.taskNameLabel) {
                TextField(store.strings.taskNamePlaceholder, text: $edits.title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .padding(scale.pt(FocusSessionLayout.cardPadding))
                    .background(cardChrome(scale: scale))
            }
            field(store.strings.taskDescriptionLabel) {
                TextEditor(text: $edits.details)
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .frame(height: scale.pt(Self.descriptionHeightDesignPixels))
                    .padding(scale.pt(FocusSessionLayout.tightGap))
                    .background(cardChrome(scale: scale))
            }
            field(store.strings.projectLabel) { projectPicker }
            if showsStatus {
                field(store.strings.taskStatusLabel) { statusPicker }
            }
            field(store.strings.taskDueDateLabel) { dueDatePicker }
            field(store.strings.outcomeLabel) { outcomePicker }
            field(ToDoStrings.load()[.duration]) {
                HStack {
                    TextField("", text: $durationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .onChange(of: durationText) { text in
                            let minutes = Int(text.trimmingCharacters(in: .whitespaces)) ?? 0
                            edits.durationMinutes = minutes
                            if minutes > 0 {
                                edits.perspirationLevel = ToDoScoring.perspiration(forMinutes: minutes,
                                                                                current: edits.perspirationLevel)
                            }
                        }
                    Text(ToDoStrings.load()[.minutes])
                }
            }
        }
        .onAppear { durationText = String(edits.effectiveDurationMinutes) }
        .environment(\.locale, Locale(identifier: currentLanguageCode.isEmpty ? "en" : currentLanguageCode))
    }

    private var outcomePicker: some SwiftUI.View {
        // The same rows the To-do and Projects pickers show, from the one shared definition — this
        // sheet used to keep its own copy of the wording (report 2026-09-15_20-12-49).
        let outcomeRows = ToDoStrings.load()
        return Picker("", selection: $edits.outcome) {
            Text(store.strings.outcomeNotSet).tag(nil as Int?)
            if let wire = edits.outcome, wire % ToDoScoring.outcomeWireFactor != 0 {
                Text(currentOutcomeLabel(wire)).tag(Optional(wire))
            }
            ForEach(1...ToDoScoring.outcomeSteps, id: \.self) { step in
                Text(outcomeRows.outcomeOptionLabel(displayValue: step))
                    .tag(Optional(FocusSessionOutcome.wireValue(forDisplay: step)))
            }
        }.labelsHidden().font(scale.font(FocusSessionLayout.rowTitleFont))
    }

    private func currentOutcomeLabel(_ wire: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode.isEmpty ? "en" : currentLanguageCode)
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: FocusSessionOutcome.displayValue(forWire: wire))) ?? "1"
        return store.strings.currentOutcome.replacingOccurrences(of: FocusSessionPlaceholder.score, with: value)
    }

    /// "Add to project" was a flat `Picker` — a scroll through every project the user has, which is
    /// unusable past a couple of dozen (report 2026-09-17_12-59-15). It is now the app's existing
    /// type-to-filter control, the same one the Notes project filter and the project note editor use,
    /// rather than a fourth typeahead. Its first row clears the selection back to "No project".
    private var projectPicker: some SwiftUI.View {
        SearchableComboBoxField(options: projectOptions,
                                selectedId: $edits.projectId,
                                clearedOptionTitle: store.strings.noProjectOption)
            .frame(height: Self.comboBoxHeightPoints)
    }

    private var projectOptions: [SearchableComboBoxField.Option] {
        store.projects.map { SearchableComboBoxField.Option(id: $0.id, name: $0.name) }
    }

    private var statusPicker: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.sectionGap)) {
            ForEach(FocusSessionTaskStatus.allCases, id: \.rawValue) { status in
                SwiftUI.Button(action: { edits.status = status }) {
                    HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
                        Image(systemName: edits.status == status ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(edits.status == status
                                             ? FocusSessionPalette.accent
                                             : FocusSessionPalette.secondaryText)
                        Text(store.strings.statusLabel(for: status))
                            .foregroundColor(FocusSessionPalette.primaryText)
                    }
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                }
                .buttonStyle(FBButtonStyle())
            }
            Spacer(minLength: 0)
        }
    }

    private var dueDatePicker: some SwiftUI.View {
        DatePicker("", selection: dueDateSelection, displayedComponents: .date)
            .labelsHidden()
            .font(scale.font(FocusSessionLayout.rowTitleFont))
    }

    /// The API allows a null due date; the picker can't show "none", so an unset date opens on today.
    private var dueDateSelection: Binding<Date> {
        Binding(get: { edits.dueDate ?? Date() }, set: { edits.dueDate = $0 })
    }

    private func field<Content: SwiftUI.View>(_ label: String,
                                              @ViewBuilder content: () -> Content) -> some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.tightGap)) {
            Text(label)
                .font(scale.font(FocusSessionLayout.rowTitleFont))
                .foregroundColor(FocusSessionPalette.primaryText)
            content()
        }
    }
}

/// An icon + title heading over one filter control.
@available(macOS 11.0, *)
private struct FocusSessionFilterSection<Content: SwiftUI.View>: SwiftUI.View {
    let title: String
    let symbol: String
    let scale: FocusSessionScale
    @ViewBuilder let content: Content

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                Image(systemName: symbol)
                    .font(scale.font(FocusSessionLayout.bodyFont))
                    .foregroundColor(FocusSessionPalette.primaryText)
                Text(title)
                    .font(scale.font(FocusSessionLayout.bodyFont))
                    .foregroundColor(FocusSessionPalette.primaryText)
            }
            content
        }
    }
}

/// A selectable pill, orange when chosen — the design's filter chip.
@available(macOS 11.0, *)
struct FocusSessionChip: SwiftUI.View {
    let title: String
    let isSelected: Bool
    let scale: FocusSessionScale
    let action: () -> Void

    private static let cornerRadiusDesignPixels: CGFloat = 34
    private static let paddingDesignPixels: CGFloat = 40

    var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(scale.font(FocusSessionLayout.bodyFont))
                .foregroundColor(isSelected ? FocusSessionPalette.accent : FocusSessionPalette.secondaryText)
                .padding(.horizontal, scale.pt(Self.paddingDesignPixels))
                .padding(.vertical, scale.pt(FocusSessionLayout.cardPadding))
                .background(
                    RoundedRectangle(cornerRadius: scale.pt(Self.cornerRadiusDesignPixels))
                        .fill(isSelected ? FocusSessionPalette.accent.opacity(0.15) : FocusSessionPalette.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: scale.pt(Self.cornerRadiusDesignPixels))
                                .strokeBorder(isSelected ? FocusSessionPalette.accent : FocusSessionPalette.border,
                                              lineWidth: scale.pt(FocusSessionLayout.hairline))
                        )
                )
        }
        .buttonStyle(FBButtonStyle())
    }
}

/// Chips laid out in rows that wrap. SwiftUI on macOS 11 has no flow layout, so the rows are chunked
/// by a fixed count — enough for the project list the design shows.
@available(macOS 11.0, *)
private struct FocusSessionWrappingChips: SwiftUI.View {
    let items: [(id: String, title: String)]
    let selectedId: String?
    let scale: FocusSessionScale
    let onSelect: (String) -> Void

    private static let chipsPerRow = 3

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.rowGap)) {
            ForEach(rows, id: \.first!.id) { row in
                HStack(spacing: scale.pt(FocusSessionLayout.cardGap)) {
                    ForEach(row, id: \.id) { item in
                        FocusSessionChip(title: item.title,
                                         isSelected: selectedId == item.id,
                                         scale: scale) { onSelect(item.id) }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var rows: [[(id: String, title: String)]] {
        stride(from: 0, to: items.count, by: Self.chipsPerRow).map { start in
            Array(items[start..<min(start + Self.chipsPerRow, items.count)])
        }
    }
}

/// A magnifying-glass search field on a card, used by both the task and project searches.
@available(macOS 11.0, *)
struct FocusSessionSearchField: SwiftUI.View {
    let placeholder: String
    @SwiftUI.Binding var text: String
    let scale: FocusSessionScale
    var onCommit: () -> Void = {}

    var body: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.inlineGap)) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(FocusSessionPalette.secondaryText)
            TextField(placeholder, text: $text, onCommit: onCommit)
                .textFieldStyle(PlainTextFieldStyle())
                .font(scale.font(FocusSessionLayout.rowTitleFont))
        }
        .padding(scale.pt(FocusSessionLayout.cardPadding))
        .background(cardChrome(scale: scale))
    }
}

/// The design's filled orange confirm button.
@available(macOS 11.0, *)
struct FocusSessionPrimaryButton: SwiftUI.View {
    let title: String
    let scale: FocusSessionScale
    let isEnabled: Bool
    let action: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(scale.font(FocusSessionLayout.bodyFont, .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: scale.pt(FocusSessionLayout.primaryButtonHeight))
                .background(
                    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                        .fill(FocusSessionPalette.accent)
                )
        }
        .buttonStyle(FBButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// The design's muted grey cancel button.
@available(macOS 11.0, *)
struct FocusSessionSecondaryButton: SwiftUI.View {
    let title: String
    let scale: FocusSessionScale
    let action: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(scale.font(FocusSessionLayout.rowTitleFont))
                .foregroundColor(FocusSessionPalette.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: scale.pt(FocusSessionLayout.primaryButtonHeight))
                .background(
                    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                        .fill(FocusSessionPalette.mutedFill)
                )
        }
        .buttonStyle(FBButtonStyle())
    }
}

/// The notes list, shown over the session screen. Reuses the app's own Notes screen (the one
/// `brainDumpVc` hosts) so there is one notes UI, presented here as a lightbox instead of a
/// destination — navigating away from a running session loses the session.
@available(macOS 11.0, *)
struct FocusSessionNotesSheet: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore

    private static let sheetWidthDesignPixels: CGFloat = 1600

    private var scale: FocusSessionScale {
        FocusSessionScale(contentWidth: FocusSessionTokens.designWidthPoints)
    }

    var body: some SwiftUI.View {
        NotesScreen(store: store.notesStore) { store.activeSheet = nil }
            .focusSessionSheetFrame(widthDesignPixels: Self.sheetWidthDesignPixels, scale: scale)
            .background(FocusSessionPalette.panelBackground)
    }
}

/// A project chip, in the treatment the native To-do list uses: accent text on a soft accent fill,
/// led by the project's own emoji when it has one.
@available(macOS 11.0, *)
struct FocusSessionProjectChip: SwiftUI.View {
    let name: String
    let scale: FocusSessionScale
    var icon: String?

    var body: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
            if let icon = icon, !icon.isEmpty { Text(icon) }
            Text(name).lineLimit(1)
        }
        .font(scale.font(FocusSessionLayout.badgeFont, .medium))
        .foregroundColor(FocusSessionPalette.accent)
        .padding(.horizontal, scale.pt(FocusSessionLayout.cardPadding))
        .padding(.vertical, scale.pt(FocusSessionLayout.tightGap))
        .background(Capsule().fill(FocusSessionPalette.accent.opacity(0.14)))
    }
}

/// The design's purple "⚡ TOP: 4.2" badge. Only shown when the backend sent a score.
@available(macOS 11.0, *)
struct FocusSessionTopScoreBadge: SwiftUI.View {
    let score: Double
    let strings: FocusSessionStrings
    let scale: FocusSessionScale

    var body: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
            Image(systemName: "bolt.fill")
                .font(scale.font(FocusSessionLayout.badgeFont))
            Text(strings.topScoreBadge(score))
                .font(scale.font(FocusSessionLayout.badgeFont, .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, scale.pt(FocusSessionLayout.cardPadding))
        .padding(.vertical, scale.pt(FocusSessionLayout.tightGap))
        .background(Capsule().fill(FocusSessionPalette.scoreBadge))
    }
}
