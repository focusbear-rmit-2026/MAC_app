//
//  DayPlanHabitEditor.swift
//  Focus Bear
//
//  SwiftUI sheets opened from the Day Plan: the per-habit editor (the "Edit" button in the selected
//  habit's action bar) and the routine start-time prompt (the routine header's "…" menu). Both write to
//  DayPlanRoutineDraft, which applies the change live and holds it until "Save and restart app".
//  The editor mirrors the web dashboard's habit editor: the inline row (emoji, name, timer/duration or
//  completion requirement) plus the "More options" modal's tabs — Timing · Add Videos · Allow Apps ·
//  Log Data · Sub habits · Instructions · Advanced.
//

import SwiftUI
import AppKit

// MARK: - Sheet host

/// Hosts a SwiftUI view in a fixed-size sheet. The hosting view's own intrinsic size is switched off
/// (it would otherwise try to grow the sheet/window to fit the content) — the SwiftUI root sizes itself
/// to `size` and scrolls internally.
@available(macOS 11.0, *)
final class DayPlanSheetController: NSViewController {
    private let size: NSSize
    private let hosting: NSHostingView<AnyView>

    init<Content: View>(size: NSSize, content: Content) {
        self.size = size
        self.hosting = NSHostingView(rootView: AnyView(content))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() {
        let root = NSView(frame: NSRect(origin: .zero, size: size))
        if #available(macOS 13.0, *) { hosting.sizingOptions = [] }
        hosting.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        hosting.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: root.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        view = root
        preferredContentSize = size
    }
}

// MARK: - Habit editor model

@available(macOS 11.0, *)
final class HabitEditModel: ObservableObject {
    @Published var values: HabitEditValues
    let section: RoutineSettingsSection
    let focusModes: [FocusModeOption]
    /// The habit that's playing right now can't be deleted — the routine player is indexing into it.
    let canDelete: Bool
    /// A habit being added (the routine menu's "Add new habit") rather than an existing one being edited.
    let isNew: Bool

    init(values: HabitEditValues, section: RoutineSettingsSection, canDelete: Bool = true, isNew: Bool = false) {
        self.values = values
        self.section = section
        self.canDelete = canDelete
        self.isNew = isNew
        // Same list the blocking-schedule editor offers (the meetings pseudo-mode isn't a real block list).
        focusModes = arrFocusType.compactMap { mode in
            if mode["isMeetings"] as? Bool ?? false { return nil }
            guard let id = mode["id"] as? String else { return nil }
            return FocusModeOption(id: id, name: mode["name"] as? String ?? "")
        }
    }

    /// Priority (Must do / Optional) is an evening + custom-routine option on the web; morning habits are
    /// always "standard" (AppDelegate never reads a morning habit's priority).
    var showsPriority: Bool { section != .morning }
    /// Weekly schedule is per-habit for morning/evening; a custom routine's days live on the routine.
    var showsDaysOfWeek: Bool {
        if case .custom = section { return false }
        return true
    }
    /// Late cutoff only applies to must-do evening habits (web `advanced-tab`).
    var showsCutoff: Bool { section == .evening && values.isHighPriority }
    var canRunMicroBreaks: Bool {
        !values.usesFocusMode && !(HabitEditValues.cleaned(values.allowedApps).isEmpty && HabitEditValues.cleaned(values.allowedUrls).isEmpty)
    }

    private static let videoHostPattern = #"^(https?://)?(www\.|m\.)?(youtube\.com|youtu\.be|vimeo\.com|player\.vimeo\.com)/"#
    private static let tagPattern = #"^[A-Za-z][A-Za-z_ (),&-]*$"#

    /// The first validation failure to show under the form, or nil when the form can be saved. Rules
    /// follow the web's `isMoreOptionsFormValid`.
    var validationMessage: String? {
        if !values.trimmedName.unicodeScalars.contains(where: { CharacterSet.letters.contains($0) }) {
            return ScheduleText.habitInvalidName
        }
        if values.usesTimer, !values.isDurationValid {
            return ScheduleText.habitInvalidDurationRange
        }
        if !values.usesTimer, values.completionRequirement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ScheduleText.habitInvalidCompletion
        }
        if showsDaysOfWeek, values.daysOfWeek.isEmpty { return ScheduleText.habitInvalidDays }
        if HabitEditValues.cleaned(values.videoUrls).contains(where: { $0.range(of: Self.videoHostPattern, options: [.regularExpression, .caseInsensitive]) == nil }) {
            return ScheduleText.habitInvalidVideo
        }
        if values.randomChoiceCount == 0, values.logQuantity, values.logQuestions.contains(where: { !$0.isValid }) {
            return ScheduleText.habitInvalidQuestions
        }
        if HabitEditValues.cleaned(values.tags).contains(where: { $0.range(of: Self.tagPattern, options: .regularExpression) == nil }) {
            return ScheduleText.habitInvalidTags
        }
        // A habit's late cutoff is deliberately NOT constrained against the global shutdown/startup/cutoff
        // times: it stands on its own (bug report 2026-09-09). `MinutesTimePicker` can only produce a real
        // time of day, so there is nothing further to validate here.
        return nil
    }

    func addLogQuestion() {
        values.logQuestions.append(HabitLogQuestionEdit(id: UUID().uuidString, question: "", minValue: "", maxValue: ""))
    }

    /// Turning the focus-mode option on replaces allowed apps/URLs (web behaviour); off clears the id.
    func setUsesFocusMode(_ on: Bool) {
        if on {
            values.allowedFocusModeId = focusModes.first?.id ?? ""
            values.allowedApps = []
            values.allowedUrls = []
            values.runMicroBreaks = false
        } else {
            values.allowedFocusModeId = ""
        }
    }
}

/// The web "More options" tabs, in the web's order.
@available(macOS 11.0, *)
enum HabitEditorTab: CaseIterable {
    case timing, videos, allowApps, logData, subHabits, instructions, advanced

    var title: String {
        switch self {
        case .timing: return ScheduleText.habitTabTiming
        case .videos: return ScheduleText.habitTabVideos
        case .allowApps: return ScheduleText.habitTabAllowApps
        case .logData: return ScheduleText.habitTabLogData
        case .subHabits: return ScheduleText.habitTabSubHabits
        case .instructions: return ScheduleText.habitTabInstructions
        case .advanced: return ScheduleText.habitTabAdvanced
        }
    }

    var symbol: String {
        switch self {
        case .timing: return "clock"
        case .videos: return "play.rectangle"
        case .allowApps: return "laptopcomputer"
        case .logData: return "chart.bar"
        case .subHabits: return "checkmark.square"
        case .instructions: return "book"
        case .advanced: return "hexagon"
        }
    }
}

// MARK: - Habit editor view

@available(macOS 11.0, *)
struct HabitEditView: View {
    @ObservedObject var model: HabitEditModel
    let onSave: () -> Void
    let onCancel: () -> Void
    /// Removes the habit from its routine; nil hides the delete action (e.g. a preview).
    let onDelete: (() -> Void)?

    @SwiftUI.State private var selectedTab: HabitEditorTab
    @SwiftUI.State private var isConfirmingDelete = false

    private let labelWidth: CGFloat = 150
    private static let durationFieldWidth: CGFloat = 46

    init(model: HabitEditModel, onSave: @escaping () -> Void, onCancel: @escaping () -> Void, onDelete: (() -> Void)? = nil,
         initialTab: HabitEditorTab = .timing, confirmingDelete: Bool = false) {
        self.model = model
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        _selectedTab = SwiftUI.State(initialValue: initialTab)
        _isConfirmingDelete = SwiftUI.State(initialValue: confirmingDelete)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            basicsRow
            tabStrip
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    tabContent
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(FBColor.fieldBackground)
            Divider()
            footer
        }
        .background(FBColor.background)
    }

    // MARK: Header (orange bar: habit name + close), like the web modal header

    private var header: some View {
        HStack(spacing: 10) {
            Text(headerTitle)
                .font(.fbSemibold(16))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            SwiftUI.Button(action: onCancel) {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            }
            .buttonStyle(FBButtonStyle())
            .help(ScheduleText.habitCancel)
            // The footer's Cancel does the same; VoiceOver announcing two "Cancel"s reads as two actions.
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(FBColor.accent)
    }

    private var headerTitle: String {
        let fallback = model.isNew ? ScheduleText.newHabitTitle : ScheduleText.editHabitTitle
        let name = model.values.trimmedName.isEmpty ? fallback : model.values.trimmedName
        let icon = model.values.icon.trimmingCharacters(in: .whitespaces)
        return icon.isEmpty ? name : "\(icon) \(name)"
    }

    // MARK: Inline row (emoji · name · timer/duration or completion), like the web habit row

    private var basicsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // VoiceOver reads a SwiftUI field's placeholder as its only name, and this one is a glyph.
                TextField(Self.iconPlaceholder, text: $model.values.icon)
                    .frame(width: 48)
                    .multilineTextAlignment(.center)
                    .help(ScheduleText.habitPickEmoji)
                    .accessibilityLabel(ScheduleText.habitFieldIcon)
                emojiPickerButton
                TextField(ScheduleText.habitFieldName, text: $model.values.name)
                    .accessibilityLabel(ScheduleText.habitFieldName)
                    .accessibilityIdentifier(UITestContract.Identifier.DayPlanEditors.habitNameField)
            }
            HStack(spacing: 14) {
                Toggle(ScheduleText.habitFieldUseTimer, isOn: $model.values.usesTimer)
                if model.values.usesTimer {
                    durationFields
                } else {
                    Text(ScheduleText.habitFieldCompletion).font(.fbRegular(13))
                    TextField("", text: $model.values.completionRequirement)
                        .accessibilityLabel(ScheduleText.habitFieldCompletion)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
    }

    /// Minutes + seconds, like the web's duration input, with the resulting length spelled out.
    private var durationFields: some View {
        HStack(spacing: 6) {
            Text(ScheduleText.habitFieldDurationLabel).font(.fbRegular(13))
            TextField("", value: $model.values.durationMinutesPart, formatter: Self.minutesFormatter)
                .frame(width: Self.durationFieldWidth)
                .accessibilityLabel(durationFieldLabel(unit: ScheduleText.habitDurationMinutesUnit))
            unitLabel(ScheduleText.habitDurationMinutesUnit)
            TextField("", value: $model.values.durationSecondsPart, formatter: Self.secondsFormatter)
                .frame(width: Self.durationFieldWidth)
                .accessibilityLabel(durationFieldLabel(unit: ScheduleText.habitDurationSecondsUnit))
            unitLabel(ScheduleText.habitDurationSecondsUnit)
            Text(HabitDurationText.short(seconds: model.values.durationSeconds))
                .font(.fbSemibold(12)).foregroundColor(.secondary).padding(.leading, 4)
        }
    }

    private func unitLabel(_ text: String) -> some View {
        Text(text).font(.fbRegular(12)).foregroundColor(.secondary)
    }

    /// The two duration fields are told apart on screen only by the unit beside each one.
    private func durationFieldLabel(unit: String) -> String {
        "\(ScheduleText.habitFieldDurationLabel) (\(unit))"
    }

    /// Shown in the empty icon field so a new habit's blank emoji slot reads as one.
    private static let iconPlaceholder = "🙂"   // i18n-ignore — glyph only

    /// Opens the system emoji palette; it types into the focused field, so the user clicks the icon field
    /// first (the button never takes focus itself).
    private var emojiPickerButton: some View {
        SwiftUI.Button(action: { NSApp.orderFrontCharacterPalette(nil) }) {
            Image(systemName: "face.smiling").font(.system(size: 14)).foregroundColor(.secondary)
        }
        .buttonStyle(FBButtonStyle())
        .help(ScheduleText.habitPickEmoji)
        .accessibilityLabel(ScheduleText.habitPickEmoji)
    }

    // MARK: Tab strip

    private var tabStrip: some View {
        HStack(spacing: 2) {
            ForEach(HabitEditorTab.allCases, id: \.self) { tab in
                let isActive = tab == selectedTab
                SwiftUI.Button(action: { selectedTab = tab }) {
                    HStack(spacing: 5) {
                        Image(systemName: tab.symbol).font(.system(size: 11, weight: .semibold))
                        Text(tab.title).font(isActive ? .fbSemibold(12) : .fbRegular(12)).lineLimit(1).fixedSize()
                    }
                    .foregroundColor(isActive ? FBColor.accent : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 8)
                    .overlay(Rectangle().frame(height: 2).foregroundColor(isActive ? FBColor.accent : .clear), alignment: .bottom)
                }
                .buttonStyle(FBButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .background(FBColor.lightOrangeBackground)
        .overlay(Rectangle().frame(height: 1).foregroundColor(FBColor.lightOrangeBorder), alignment: .bottom)
    }

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case .timing: timingTab
        case .videos: videosTab
        case .allowApps: allowAppsTab
        case .logData: logDataTab
        case .subHabits: subHabitsTab
        case .instructions: instructionsTab
        case .advanced: advancedTab
        }
    }

    // MARK: Tabs

    @ViewBuilder private var timingTab: some View {
        if model.showsPriority {
            labelled(ScheduleText.habitFieldPriority) {
                Picker("", selection: $model.values.isHighPriority) {
                    Text(ScheduleText.habitPriorityHigh).tag(true)
                    Text(ScheduleText.habitPriorityStandard).tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .frame(width: 220)
            }
        }
        if model.showsDaysOfWeek {
            labelled(ScheduleText.habitFieldDays) {
                DayOfWeekPicker(selection: $model.values.daysOfWeek)
            }
        }
        if model.showsCutoff {
            Toggle(ScheduleText.habitFieldCutoff, isOn: $model.values.cutoffEnabled)
            if model.values.cutoffEnabled {
                MinutesTimePicker(title: ScheduleText.habitFieldCutoff, minutes: $model.values.cutoffMinutes)
                    .padding(.leading, 20)
            }
        }
    }

    @ViewBuilder private var videosTab: some View {
        hint(ScheduleText.habitFieldVideoUrls)
        EditableStringList(items: $model.values.videoUrls)
    }

    @ViewBuilder private var allowAppsTab: some View {
        Toggle(ScheduleText.habitFieldUseFocusMode,
               isOn: Binding(get: { model.values.usesFocusMode }, set: { model.setUsesFocusMode($0) }))
        if model.values.usesFocusMode {
            labelled(ScheduleText.habitFieldFocusMode) {
                Picker("", selection: $model.values.allowedFocusModeId) {
                    ForEach(model.focusModes) { mode in Text(mode.name).tag(mode.id) }
                }
                .labelsHidden()
                .frame(maxWidth: 260)
            }
        } else {
            hint(ScheduleText.habitFieldAllowedApps)
            AllowedAppsPicker(apps: $model.values.allowedApps)
                .zIndex(1)   // its suggestion list overhangs the fields below; siblings draw in order otherwise
            hint(ScheduleText.habitFieldAllowedUrls)
            EditableStringList(items: $model.values.allowedUrls)
            Toggle(ScheduleText.habitFieldRunMicroBreaks, isOn: $model.values.runMicroBreaks)
                .disabled(!model.canRunMicroBreaks)
        }
        Toggle(ScheduleText.habitFieldShowSavedSites, isOn: $model.values.showSavedDistractingWebsites)
    }

    @ViewBuilder private var logDataTab: some View {
        if model.values.randomChoiceCount > 0 {
            hint(String(format: ScheduleText.habitRandomChoicesNote, model.values.randomChoiceCount))
        } else {
            Toggle(ScheduleText.habitFieldLogQuantity, isOn: $model.values.logQuantity)
            if model.values.logQuantity {
                logQuestionRows
                SwiftUI.Button(action: model.addLogQuestion) {
                    Text("+ " + ScheduleText.habitAddQuestion).fbOutlineButtonLabel(.primary)
                }
                .buttonStyle(FBButtonStyle())
                labelled(ScheduleText.habitFieldLogType) {
                    Picker("", selection: $model.values.logSummaryType) {
                        Text(ScheduleText.habitLogTypeSum).tag(RoutineSettingsKey.logSummarySum)
                        Text(ScheduleText.habitLogTypeAverage).tag(RoutineSettingsKey.logSummaryAverage)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .frame(width: 220)
                }
            }
        }
        labelled(ScheduleText.habitFieldTakeNotes) {
            Picker("", selection: $model.values.takeNotes) {
                Text(ScheduleText.habitNotesNone).tag(NO_NOTE)
                Text(ScheduleText.habitNotesDuring).tag(DURING_ACTIVITY)
                Text(ScheduleText.habitNotesEnd).tag(END_OF_ACTIVITY)
            }
            .labelsHidden()
            .frame(maxWidth: 260)
        }
    }

    private var logQuestionRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(model.values.logQuestions.enumerated()), id: \.element.id) { index, _ in
                HStack(spacing: 6) {
                    TextField(ScheduleText.habitFieldQuestion, text: questionBinding(index, \.question))
                    TextField(ScheduleText.habitFieldMin, text: questionBinding(index, \.minValue)).frame(width: 56)
                    TextField(ScheduleText.habitFieldMax, text: questionBinding(index, \.maxValue)).frame(width: 56)
                    RemoveRowButton { removeQuestion(at: index) }
                }
            }
        }
    }

    @ViewBuilder private var subHabitsTab: some View {
        if model.values.randomChoiceCount > 0 {
            hint(String(format: ScheduleText.habitRandomChoicesNote, model.values.randomChoiceCount))
        } else {
            hint(ScheduleText.habitFieldChecklist)
            EditableStringList(items: $model.values.checklist)
        }
    }

    @ViewBuilder private var instructionsTab: some View {
        hint(ScheduleText.habitFieldInstructions)
        TextEditor(text: $model.values.textInstructions)
            .font(.fbRegular(13))
            .frame(minHeight: 90, maxHeight: 140)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FBColor.grayBorder, lineWidth: 1))
        hint(ScheduleText.habitFieldImages)
        EditableStringList(items: $model.values.imageUrls)
    }

    @ViewBuilder private var advancedTab: some View {
        hint(ScheduleText.habitFieldTags)
        EditableStringList(items: $model.values.tags)
    }

    @ViewBuilder private var footer: some View {
        if isConfirmingDelete, let onDelete = onDelete {
            deleteConfirmation(onDelete)
        } else {
            actions
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            if onDelete != nil, model.canDelete {
                SwiftUI.Button(action: { isConfirmingDelete = true }) {
                    Text(ScheduleText.habitDelete).fbOutlineButtonLabel(.red)
                }
                .buttonStyle(FBButtonStyle())
            }
            if let message = model.validationMessage {
                Text(message).font(.fbRegular(12)).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            SwiftUI.Button(action: onCancel) { Text(ScheduleText.habitCancel) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true))
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier(UITestContract.Identifier.DayPlanEditors.habitEditorCancelButton)
            SwiftUI.Button(action: onSave) { Text(ScheduleText.habitSave) }
                .buttonStyle(AppOrangeButtonStyle(secondary: false))
                .disabled(model.validationMessage != nil)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    /// Inline "are you sure?" that replaces the footer buttons, so a stray click can't remove a habit.
    private func deleteConfirmation(_ onDelete: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(String(format: ScheduleText.habitDeleteConfirm, model.values.trimmedName))
                .font(.fbRegular(12)).foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            SwiftUI.Button(action: { isConfirmingDelete = false }) { Text(ScheduleText.habitCancel) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true))
                .keyboardShortcut(.cancelAction)
            SwiftUI.Button(action: onDelete) { Text(ScheduleText.habitDeleteConfirmButton) }
                .buttonStyle(DestructiveButtonStyle())
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    // MARK: Helpers

    private static let minutesFormatter = wholeNumberFormatter(maximum: HabitEditValues.maxDurationMinutes)
    private static let secondsFormatter = wholeNumberFormatter(maximum: HabitEditValues.maxSecondsPart)

    private static func wholeNumberFormatter(maximum: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = NSNumber(value: maximum)
        return formatter
    }

    private func hint(_ text: String) -> some View {
        Text(text).font(.fbRegular(12)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
    }

    private func labelled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title).font(.fbRegular(13)).frame(width: labelWidth, alignment: .leading)
            content()
        }
    }

    /// Index-based binding that tolerates the row being removed mid-edit (a stale index reads "" and
    /// writes nothing) — safer than binding straight into the array subscript.
    private func questionBinding(_ index: Int, _ keyPath: WritableKeyPath<HabitLogQuestionEdit, String>) -> Binding<String> {
        Binding(get: { index < model.values.logQuestions.count ? model.values.logQuestions[index][keyPath: keyPath] : "" },
                set: { if index < model.values.logQuestions.count { model.values.logQuestions[index][keyPath: keyPath] = $0 } })
    }

    private func removeQuestion(at index: Int) {
        guard index < model.values.logQuestions.count else { return }
        model.values.logQuestions.remove(at: index)
    }
}

// MARK: - Routine timing view

@available(macOS 11.0, *)
struct RoutineTimingView: View {
    let routineName: String
    @SwiftUI.State var minutes: Int
    let showsCutoff: Bool
    @SwiftUI.State var cutoffEnabled: Bool
    @SwiftUI.State var cutoffMinutes: Int
    let morningStartMinutes: Int?
    let onSave: (Int, Int?) -> Void
    let onCancel: () -> Void

    private var timingQuestion: String { String(format: ScheduleText.routineTimingQuestion, routineName) }

    private var cutoffIsValid: Bool {
        !showsCutoff || DayPlanRoutineDraft.isEveningCutoffValid(cutoffEnabled ? cutoffMinutes : nil,
            eveningStart: minutes, morningStart: morningStartMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(timingQuestion)
                .font(.fbSemibold(16))
                .fixedSize(horizontal: false, vertical: true)
            MinutesTimePicker(title: timingQuestion, minutes: $minutes)
            Text(ScheduleText.routineTimingHint).font(.fbRegular(12)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if showsCutoff {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(ScheduleText.routineCutoffLabel, isOn: $cutoffEnabled).font(.fbMedium(13))
                        .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.routineTimingCutoffToggle)
                    if cutoffEnabled {
                        MinutesTimePicker(title: ScheduleText.routineCutoffLabel, minutes: $cutoffMinutes)
                        Text(ScheduleText.routineCutoffHint).font(.fbRegular(12)).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !cutoffIsValid {
                        Text(ScheduleText.routineCutoffInvalid).font(.fbRegular(12)).foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            HStack {
                Spacer()
                SwiftUI.Button(action: onCancel) { Text(ScheduleText.habitCancel) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true))
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier(UITestContract.Identifier.DayPlanEditors.routineTimingCancelButton)
                SwiftUI.Button(action: { onSave(minutes, showsCutoff && cutoffEnabled ? cutoffMinutes : nil) }) { Text(ScheduleText.habitSave) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false))
                    .keyboardShortcut(.defaultAction)
                    .disabled(!cutoffIsValid)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FBColor.background)
    }
}

// MARK: - Form building blocks

/// An hour:minute picker bound to minutes-since-midnight (the form's unit for cutoffs and routine starts).
@available(macOS 11.0, *)
struct MinutesTimePicker: View {
    /// What VoiceOver calls the field and its up/down stepper — the visible label sits beside it.
    let title: String
    @Binding var minutes: Int

    var body: some View {
        DatePicker(title, selection: dateBinding, displayedComponents: .hourAndMinute)
            .labelsHidden()
            .fixedSize()
    }

    private var dateBinding: Binding<Date> {
        Binding(get: {
            Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
        }, set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        })
    }
}

/// Seven day chips ("MON"…"SUN" codes, locale-short labels) plus weekdays / weekend / every-day shortcuts.
@available(macOS 11.0, *)
struct DayOfWeekPicker: View {
    @Binding var selection: Set<String>

    private static let weekdays: Set<String> = ["MON", "TUE", "WED", "THU", "FRI"]
    private static let weekend: Set<String> = ["SAT", "SUN"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(HabitEditValues.weekdayCodes, id: \.self) { code in
                    let isOn = selection.contains(code)
                    SwiftUI.Button(action: { toggle(code) }) {
                        Text(Self.shortLabel(code))
                            .font(.fbSemibold(11))
                            .frame(width: 34, height: 24)
                            .background(isOn ? FBColor.accent : FBColor.fieldBackground)
                            .foregroundColor(isOn ? .white : .primary)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FBColor.grayBorder, lineWidth: isOn ? 0 : 1))
                    }
                    .buttonStyle(FBButtonStyle())
                }
            }
            HStack(spacing: 10) {
                shortcut(ScheduleText.habitDaysWeekdays, Self.weekdays)
                shortcut(ScheduleText.habitDaysWeekend, Self.weekend)
                shortcut(ScheduleText.habitDaysAll, Self.weekdays.union(Self.weekend))
            }
        }
    }

    private func shortcut(_ title: String, _ days: Set<String>) -> some View {
        SwiftUI.Button(action: { selection = days }) {
            Text(title).font(.fbRegular(11)).underline().foregroundColor(.secondary)
        }
        .buttonStyle(FBButtonStyle())
    }

    private func toggle(_ code: String) {
        if selection.contains(code) { selection.remove(code) } else { selection.insert(code) }
    }

    /// Locale-aware 2-3 letter day label; `shortWeekdaySymbols` starts at Sunday.
    static func shortLabel(_ code: String) -> String {
        guard let index = HabitEditValues.weekdayCodes.firstIndex(of: code) else { return code }
        let symbols = Calendar.current.shortWeekdaySymbols
        return symbols[(index + 1) % symbols.count]
    }
}

/// A list of single-line text rows with remove buttons and an "Add" row (video URLs, allowed apps, …).
@available(macOS 11.0, *)
private struct EditableStringList: View {
    @Binding var items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: 6) {
                    TextField("", text: binding(index))
                    RemoveRowButton { remove(at: index) }
                }
            }
            SwiftUI.Button(action: { items.append("") }) {
                Text("+ " + ScheduleText.habitAddItem).font(.fbRegular(12)).foregroundColor(FBColor.accent)
            }
            .buttonStyle(FBButtonStyle())
        }
    }

    private func binding(_ index: Int) -> Binding<String> {
        Binding(get: { index < items.count ? items[index] : "" },
                set: { if index < items.count { items[index] = $0 } })
    }

    private func remove(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
    }
}

/// The filled red counterpart of `AppOrangeButtonStyle` for the delete confirmation.
@available(macOS 11.0, *)
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .frame(minWidth: 110)
            .padding(.vertical, 9).padding(.horizontal, 18)
            .background(configuration.isPressed ? Color.red.opacity(0.7) : Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(Rectangle())
            .pointingHandCursor()
    }
}

// MARK: - Allowed apps typeahead

/// Allowed-apps entry: a text field that suggests installed apps as you type (↑/↓ to move, Return to
/// pick, Esc to dismiss) and still accepts any typed name, plus a chip per allowed app. Entries are the
/// app's `.app` filename stem — what the web dashboard saves and the routine player matches against.
@available(macOS 11.0, *)
private struct AllowedAppsPicker: View {
    @Binding var apps: [String]

    @SwiftUI.State private var query = ""
    @SwiftUI.State private var installed: [InstalledApp] = []
    @SwiftUI.State private var highlightedRow = 0
    @SwiftUI.State private var isDropdownOpen = false

    static let maxSuggestions = 8
    private static let fieldHeight: CGFloat = 24
    private static let rowHeight: CGFloat = 26
    private static let iconSize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TypeaheadTextField(text: $query, placeholder: ScheduleText.habitAllowedAppsPlaceholder,
                               onMove: moveHighlight, onCommit: commit, onEscape: dismissDropdown)
                .frame(height: Self.fieldHeight)
                .overlay(dropdown, alignment: .topLeading)
                .zIndex(1)   // the list must draw over the chips and the fields below
            if !apps.isEmpty {
                ChipFlow(items: apps) { index in apps.remove(at: index) } label: { name in chipLabel(name) }
            }
        }
        .onAppear { InstalledApps.shared.load { installed = $0 } }
        .onChange(of: query) { _ in
            highlightedRow = 0
            isDropdownOpen = !query.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: Rows

    /// Installed apps matching the query, the ones starting with it first; already-allowed apps are hidden.
    private var suggestions: [InstalledApp] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return [] }
        let candidates = installed.filter { $0.matches(needle) && !isAllowed($0.name) }
        let prefixed = candidates.filter { $0.hasPrefix(needle) }
        let contained = candidates.filter { !$0.hasPrefix(needle) }
        return Array((prefixed + contained).prefix(Self.maxSuggestions))
    }

    /// The typed text as a free-form entry, offered when it isn't exactly an installed app's name.
    private var customEntry: String? {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty, !isAllowed(needle),
              !suggestions.contains(where: { $0.name.caseInsensitiveCompare(needle) == .orderedSame }) else { return nil }
        return needle
    }

    private var rowCount: Int { suggestions.count + (customEntry == nil ? 0 : 1) }

    private func isAllowed(_ name: String) -> Bool {
        apps.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    // MARK: Keyboard

    private func moveHighlight(_ delta: Int) {
        guard isDropdownOpen, rowCount > 0 else { return }
        highlightedRow = (highlightedRow + delta + rowCount) % rowCount
    }

    private func commit() {
        if isDropdownOpen, highlightedRow < suggestions.count {
            add(suggestions[highlightedRow].name)
        } else if let custom = customEntry {
            add(custom)
        }
    }

    /// Returns whether Esc was consumed — only while the list is open, so it otherwise still cancels the sheet.
    private func dismissDropdown() -> Bool {
        guard isDropdownOpen else { return false }
        isDropdownOpen = false
        return true
    }

    private func add(_ name: String) {
        apps.append(name)
        query = ""
        isDropdownOpen = false
    }

    // MARK: Dropdown

    @ViewBuilder private var dropdown: some View {
        if isDropdownOpen, rowCount > 0 {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, app in
                    suggestionRow(app, isHighlighted: index == highlightedRow) { add(app.name) }
                }
                if let custom = customEntry {
                    customRow(custom, isHighlighted: highlightedRow == suggestions.count) { add(custom) }
                }
            }
            .background(FBColor.fieldBackground)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FBColor.grayBorder, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.15), radius: 6, y: 2)
            .padding(.top, Self.fieldHeight + 2)
        }
    }

    private func suggestionRow(_ app: InstalledApp, isHighlighted: Bool, action: @escaping () -> Void) -> some View {
        dropdownRow(isHighlighted: isHighlighted, action: action) {
            appIcon(app)
            Text(app.name).font(.fbRegular(12)).lineLimit(1)
            if let displayName = InstalledApps.shared.distinctDisplayName(for: app) {
                Text(displayName).font(.fbRegular(11)).foregroundColor(.secondary).lineLimit(1)
            }
        }
    }

    private func customRow(_ name: String, isHighlighted: Bool, action: @escaping () -> Void) -> some View {
        dropdownRow(isHighlighted: isHighlighted, action: action) {
            Image(systemName: "plus.circle").font(.system(size: 12)).foregroundColor(.secondary)
            Text(String(format: ScheduleText.habitAllowedAppsAddCustom, name)).font(.fbRegular(12)).lineLimit(1)
        }
    }

    private func dropdownRow<Content: View>(isHighlighted: Bool, action: @escaping () -> Void,
                                            @ViewBuilder content: () -> Content) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 8) { content(); Spacer(minLength: 0) }
                .padding(.horizontal, 8)
                .frame(height: Self.rowHeight)
                .background(isHighlighted ? FBColor.accent.opacity(0.18) : Color.clear)
        }
        .buttonStyle(FBButtonStyle())
    }

    // MARK: Chips

    private func chipLabel(_ name: String) -> some View {
        HStack(spacing: 5) {
            if let app = installed.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                appIcon(app)
            }
            Text(name).font(.fbRegular(12)).lineLimit(1)
        }
    }

    private func appIcon(_ app: InstalledApp) -> some View {
        Image(nsImage: InstalledApps.shared.icon(for: app)).resizable().frame(width: Self.iconSize, height: Self.iconSize)
    }
}

/// A single-line field whose delegate turns the keys a typeahead needs (↑ ↓ Return Esc) into callbacks.
@available(macOS 11.0, *)
private struct TypeaheadTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onMove: (Int) -> Void          // -1 = up, +1 = down
    let onCommit: () -> Void
    let onEscape: () -> Bool           // true = consumed (list closed), false = let the sheet cancel

    func makeNSView(context: Context) -> KeyGuardingTextField {
        let field = KeyGuardingTextField()
        field.delegate = context.coordinator
        field.font = getRegularFont(size: 13)
        field.onReturn = { context.coordinator.parent.onCommit() }
        field.onEscape = { context.coordinator.parent.onEscape() }
        return field
    }

    func updateNSView(_ field: KeyGuardingTextField, context: Context) {
        context.coordinator.parent = self
        field.placeholderString = placeholder
        if field.stringValue != text { field.stringValue = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TypeaheadTextField
        init(parent: TypeaheadTextField) { self.parent = parent }

        func controlTextDidChange(_ notification: Notification) {
            parent.text = (notification.object as? NSTextField)?.stringValue ?? ""
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.moveUp(_:)): parent.onMove(-1)
            case #selector(NSResponder.moveDown(_:)): parent.onMove(1)
            case #selector(NSResponder.insertNewline(_:)): parent.onCommit()
            case #selector(NSResponder.cancelOperation(_:)): return parent.onEscape()
            default: return false
            }
            return true
        }
    }
}

/// Return and Esc are claimed at the key-equivalent stage while this field is being edited: in the
/// borderless full-screen window the habit "Start" button would otherwise take Return (see
/// EditOnClickTextField), and the sheet's Cancel shortcut would take Esc before the list could close.
final class KeyGuardingTextField: NSTextField {
    var onReturn: (() -> Void)?
    var onEscape: (() -> Bool)?

    private static let returnKeyCodes: Set<UInt16> = [36, 76]
    private static let escapeKeyCode: UInt16 = 53

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown, let editor = currentEditor(), window?.firstResponder === editor else {
            return super.performKeyEquivalent(with: event)
        }
        if Self.returnKeyCodes.contains(event.keyCode) {
            onReturn?()
            return true
        }
        if event.keyCode == Self.escapeKeyCode, onEscape?() == true {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// Removable chips that wrap onto new lines (macOS 11 has no `Layout`, so this is the alignment-guide
/// flow layout: each chip's leading/top guides are computed from a running x/y as the row fills).
@available(macOS 11.0, *)
private struct ChipFlow<Label: View>: View {
    let items: [String]
    let onRemove: (Int) -> Void
    @ViewBuilder let label: (String) -> Label

    @SwiftUI.State private var contentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in flow(in: geometry.size.width) }
            .frame(height: contentHeight)
    }

    private func flow(in width: CGFloat) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                chip(item, index: index)
                    .alignmentGuide(.leading) { dimensions in
                        if x + dimensions.width > width {
                            x = 0
                            y += dimensions.height + ChipFlowMetrics.spacing
                        }
                        let leading = x
                        x += dimensions.width + ChipFlowMetrics.spacing
                        if index == items.count - 1 { x = 0 }
                        return -leading
                    }
                    .alignmentGuide(.top) { _ in
                        let top = y
                        if index == items.count - 1 { y = 0 }
                        return -top
                    }
            }
        }
        .background(GeometryReader { proxy in
            Color.clear.preference(key: ChipFlowHeightKey.self, value: proxy.size.height)
        })
        .onPreferenceChange(ChipFlowHeightKey.self) { contentHeight = $0 }
    }

    private func chip(_ item: String, index: Int) -> some View {
        HStack(spacing: 4) {
            label(item)
            SwiftUI.Button(action: { onRemove(index) }) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 12)).foregroundColor(.secondary)
            }
            .buttonStyle(FBButtonStyle())
            .help(ScheduleText.habitRemoveItem)
        }
        .padding(.leading, 8).padding(.trailing, 6).padding(.vertical, 4)
        .background(FBColor.lightOrangeBackground)
        .overlay(Capsule().strokeBorder(FBColor.lightOrangeBorder, lineWidth: 1))
        .clipShape(Capsule())
    }
}

/// Generic types can't hold static constants, so the flow's spacing lives here.
private enum ChipFlowMetrics {
    static let spacing: CGFloat = 6
}

private struct ChipFlowHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

@available(macOS 11.0, *)
private struct RemoveRowButton: View {
    let action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            Image(systemName: "minus.circle").foregroundColor(.secondary)
        }
        .buttonStyle(FBButtonStyle())
        .help(ScheduleText.habitRemoveItem)
    }
}

// MARK: - Shorten a habit for one day

/// The "Shorten" sheet from the selected habit's action bar: pick a shorter length for the day being
/// viewed, or put the habit back to its real length.
///
/// The trim is local to this Mac and scoped to one day (`DayPlanHabitDurations`) — nothing here writes
/// to the habit, so Settings › Edit habits keeps showing the true duration (report 2026-09-15_20-29-02).
@available(macOS 11.0, *)
struct DayPlanShortenHabitView: View {
    /// The wording that differs between shortening a habit and shortening a meeting. Everything else
    /// on this sheet — the presets, the typed length, "Full length" — is the same question either way,
    /// so the sheet is shared and only the two sentences that would otherwise lie are swapped.
    struct Copy: Equatable {
        /// What the trim applies to, spelled out under the options.
        let scopeHint: String
        /// Shown instead of the options when nothing shorter can be offered.
        let noOptions: String

        static func habit(dayLabel: String) -> Copy {
            Copy(scopeHint: ScheduleText.habitShortenHint(dayLabel),
                 noOptions: ScheduleText.habitShortenNoOptions)
        }

        /// A meeting's trim is a Day-Plan-only overlay (`CalendarManager.LocalEventOverride`), so it
        /// must not claim the meeting itself got shorter — the other attendees see no change.
        static func meeting(dayLabel: String) -> Copy {
            Copy(scopeHint: ScheduleText.dayFixMeetingShortenHint(dayLabel),
                 noOptions: ScheduleText.dayFixMeetingShortenNoOptions)
        }
    }

    /// Emoji + name, as the Day Plan row shows it.
    let habitTitle: String
    /// The wording for what is being shortened.
    let copy: Copy
    /// The habit's real length in seconds.
    let actualSeconds: Int
    /// The trim currently in force for this day, if any.
    let currentSeconds: Int?
    let onPick: (Int) -> Void
    let onFullLength: () -> Void
    let onCancel: () -> Void

    /// What the user has typed into the length field. `ReturnGuardTextField` writes it on every
    /// keystroke, so "Use this length" reads the current text without the field having to lose focus
    /// first — the ordering that dropped a typed due date and four other commits today.
    @SwiftUI.State private var typedLength = ""
    /// Why the typed length wasn't used, shown under the field. Cleared as soon as it's retyped.
    @SwiftUI.State private var typedError: String?

    private var options: [Int] { DayPlanHabitDurations.options(forActualSeconds: actualSeconds) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The sheet is a fixed size (its host switches off SwiftUI's intrinsic sizing so it can't
            // grow the window), and the hint wraps to more lines in a longer language — so the body
            // scrolls rather than clipping its last line, which is what it did at 300pt tall.
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(ScheduleText.habitShortenTitle).font(.fbSemibold(16))
                    Text(habitTitle).font(.fbRegular(14))
                    Text(ScheduleText.habitShortenFullLength(
                        ScheduleText.habitShortenMinutes(DayPlanHabitDurations.minutesLabel(actualSeconds))))
                        .font(.fbRegular(12)).foregroundColor(.secondary)

                    if options.isEmpty {
                        Text(copy.noOptions).font(.fbRegular(13)).foregroundColor(.secondary)
                    } else {
                        HStack(spacing: Self.optionSpacing) {
                            ForEach(options, id: \.self) { seconds in optionButton(seconds) }
                        }
                    }

                    typedLengthField

                    SwiftUI.Button(action: onFullLength) {
                        Text(ScheduleText.habitShortenFullLengthAction).fbOutlineButtonLabel()
                    }
                    .buttonStyle(FBButtonStyle())
                    .disabled(currentSeconds == nil)
                    .opacity(currentSeconds == nil ? Self.disabledOpacity : 1)

                    Text(copy.scopeHint).font(.fbRegular(11)).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                SwiftUI.Button(action: onCancel) { Text(ScheduleText.habitCancel).fbOutlineButtonLabel() }
                    .buttonStyle(FBButtonStyle())
            }
            .padding(.top, 12)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Type a length instead of picking one. Return applies it, and so does the button beside it —
    /// neither waits for the field to lose focus.
    private var typedLengthField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Self.optionSpacing) {
                ReturnGuardTextField(text: $typedLength, placeholder: ScheduleText.habitShortenTypePlaceholder,
                                     onCommit: applyTypedLength, onEndEditing: validateTypedLength)
                    .frame(width: Self.typedFieldWidth)
                SwiftUI.Button(action: applyTypedLength) {
                    Text(ScheduleText.habitShortenUseTyped).fbOutlineButtonLabel()
                }
                .buttonStyle(FBButtonStyle())
            }
            if let typedError = typedError {
                Text(typedError).font(.fbRegular(11)).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Applies whatever is in the field right now. Nothing is written for a length that isn't shorter
    /// than the habit — this only ever shortens, and "Full length" is how a trim is cleared.
    private func applyTypedLength() {
        switch DayPlanHabitDurations.typedTrim(typedLength, actualSeconds: actualSeconds) {
        case .apply(let seconds):
            typedError = nil
            onPick(seconds)
        case .notADuration:
            typedError = ScheduleText.habitShortenTypeInvalid
        case .notShorter:
            typedError = ScheduleText.habitShortenTypeNotShorter(
                ScheduleText.habitShortenMinutes(DayPlanHabitDurations.minutesLabel(actualSeconds)))
        }
    }

    /// Losing focus only reports whether the text reads as a shorter length — it must never apply one
    /// by itself, or clicking a preset would silently commit whatever was half-typed in the field.
    private func validateTypedLength() {
        guard !typedLength.trimmingCharacters(in: .whitespaces).isEmpty else {
            typedError = nil
            return
        }
        switch DayPlanHabitDurations.typedTrim(typedLength, actualSeconds: actualSeconds) {
        case .apply: typedError = nil
        case .notADuration: typedError = ScheduleText.habitShortenTypeInvalid
        case .notShorter:
            typedError = ScheduleText.habitShortenTypeNotShorter(
                ScheduleText.habitShortenMinutes(DayPlanHabitDurations.minutesLabel(actualSeconds)))
        }
    }

    private func optionButton(_ seconds: Int) -> some View {
        let isCurrent = currentSeconds == seconds
        return SwiftUI.Button(action: { onPick(seconds) }) {
            Text(ScheduleText.habitShortenMinutes(DayPlanHabitDurations.minutesLabel(seconds)))
                .font(.fbSemibold(13))
                .foregroundColor(isCurrent ? .white : .primary)
                .frame(minWidth: Self.optionWidth)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrent ? FBColor.accent : FBColor.lightOrangeBackground))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isCurrent ? FBColor.accent : FBColor.lightOrangeBorder, lineWidth: 1))
        }
        .buttonStyle(FBButtonStyle())
    }

    private static let optionSpacing: CGFloat = 8
    private static let optionWidth: CGFloat = 56
    private static let typedFieldWidth: CGFloat = 110
    private static let disabledOpacity: Double = 0.4
}
