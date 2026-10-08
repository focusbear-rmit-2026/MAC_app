//
//  DayPlanCustomRoutines.swift
//  Focus Bear
//
//  Create / edit / delete custom routines from the Day Plan, without the settings webview. Everything
//  here goes through `DayPlanRoutineDraft`, so a change is applied to the live state straight away and
//  parked in the draft until the Day Plan's "Save and restart app" banner PUTs it — exactly the model
//  the habit editor already uses. Habits inside a routine are edited with the SAME `HabitEditView`.
//
//  The JSON written mirrors the web dashboard's `INIT_CUSTOM_ROUTINE`
//  (web_dashboard/src/assets/data/index.ts:1093) — see `DayPlanRoutineDraft.writeRoutineEntry`.
//

import SwiftUI

/// The manager's screen state plus its view of the draft. It re-reads the draft after every mutation
/// rather than keeping a parallel copy, so the list can never drift from what will actually be saved.
@available(macOS 11.0, *)
final class CustomRoutineManagerModel: ObservableObject {
    enum Route: Equatable {
        case list
        case new
        case edit(sequenceId: String)
    }

    /// A habit being edited or added from inside a routine — the payload of the nested habit sheet.
    struct HabitEditorContext: Identifiable {
        let id: String
        let model: HabitEditModel
        /// nil when the habit is being added rather than edited.
        let habitId: String?
    }

    @Published private(set) var routines: [CustomRoutineSummary] = []
    @Published var route: Route = .list
    /// The routine-level form of the routine being created or edited.
    @Published var form = CustomRoutineEditValues.newRoutine()
    @Published var habitEditor: HabitEditorContext?
    /// The routine the user has asked to delete, held until they confirm.
    @Published var pendingDeleteId: String?

    private let draft: DayPlanRoutineDraft

    init(draft: DayPlanRoutineDraft = .shared) {
        self.draft = draft
        reload()
    }

    func reload() { routines = draft.customRoutineSummaries() }

    var editingRoutine: CustomRoutineSummary? {
        guard case .edit(let sequenceId) = route else { return nil }
        return routines.first { $0.id == sequenceId }
    }

    /// The first problem with the routine form, or nil when it can be saved.
    var formValidationMessage: String? {
        if form.trimmedName.isEmpty { return ScheduleText.customRoutineInvalidName }
        if form.daysOfWeek.isEmpty { return ScheduleText.habitInvalidDays }
        if !form.isWindowValid { return ScheduleText.customRoutineInvalidWindow }
        return nil
    }

    // MARK: Routine-level actions

    func startNewRoutine() {
        form = .newRoutine()
        route = .new
    }

    func startEditing(_ routine: CustomRoutineSummary) {
        form = routine.values
        route = .edit(sequenceId: routine.id)
    }

    func backToList() {
        route = .list
        reload()
    }

    /// Creates the routine and stays on it, so habits can be added right away (a routine with no
    /// habits is dropped by the settings parser, so the user has to get to that step).
    func createRoutine() {
        guard formValidationMessage == nil, let sequenceId = draft.applyCustomRoutineAdd(values: form) else { return }
        DayPlanAnalytics.capture(DayPlanAnalytics.customRoutineAdded)
        reload()
        route = .edit(sequenceId: sequenceId)
    }

    func saveRoutine() {
        guard case .edit(let sequenceId) = route, formValidationMessage == nil else { return }
        draft.applyCustomRoutineEdit(sequenceId: sequenceId, values: form)
        DayPlanAnalytics.capture(DayPlanAnalytics.customRoutineEdited)
        backToList()
    }

    func deleteRoutine(sequenceId: String) {
        draft.applyCustomRoutineDelete(sequenceId: sequenceId)
        DayPlanAnalytics.capture(DayPlanAnalytics.customRoutineDeleted)
        pendingDeleteId = nil
        backToList()
    }

    // MARK: Habit actions inside a routine

    func addHabit() {
        guard case .edit(let sequenceId) = route else { return }
        let section = RoutineSettingsSection.custom(sequenceId: sequenceId)
        let model = HabitEditModel(values: HabitEditValues.newHabit(in: section), section: section,
                                   canDelete: false, isNew: true)
        habitEditor = HabitEditorContext(id: UUID().uuidString, model: model, habitId: nil)
    }

    func editHabit(_ habit: CustomRoutineHabitSummary) {
        guard case .edit(let sequenceId) = route, let values = draft.habitEditValues(id: habit.id) else { return }
        let section = RoutineSettingsSection.custom(sequenceId: sequenceId)
        // The habit that's playing right now can't be removed mid-routine (same rule as the Day Plan).
        let model = HabitEditModel(values: values, section: section, canDelete: currentHabitPlaying?.id != habit.id)
        habitEditor = HabitEditorContext(id: habit.id, model: model, habitId: habit.id)
    }

    func commitHabitEditor(_ context: HabitEditorContext) {
        guard case .edit(let sequenceId) = route else { return }
        if let habitId = context.habitId {
            draft.applyHabitEdit(id: habitId, values: context.model.values)
            DayPlanAnalytics.capture(DayPlanAnalytics.habitEdited)
        } else {
            draft.applyHabitAdd(routine: .custom(sequenceId: sequenceId), values: context.model.values)
            DayPlanAnalytics.capture(DayPlanAnalytics.habitAdded)
        }
        habitEditor = nil
        reload()
    }

    func deleteHabit(id: String) {
        draft.applyHabitDelete(id: id)
        DayPlanAnalytics.capture(DayPlanAnalytics.habitDeleted)
        habitEditor = nil
        reload()
    }

    func moveHabit(from: Int, to: Int) {
        guard case .edit(let sequenceId) = route else { return }
        draft.applyHabitMove(in: .custom(sequenceId: sequenceId), from: from, to: to)
        DayPlanAnalytics.capture(DayPlanAnalytics.customRoutineHabitMoved)
        reload()
    }
}

// MARK: - Manager sheet

/// The whole custom-routines manager: a list of routines that swaps in place for the routine form,
/// rather than stacking a second AppKit sheet on the first.
@available(macOS 11.0, *)
struct CustomRoutineManagerView: View {
    @ObservedObject var model: CustomRoutineManagerModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(FBColor.background)
        .sheet(item: $model.habitEditor) { context in
            HabitEditView(model: context.model,
                          onSave: { model.commitHabitEditor(context) },
                          onCancel: { model.habitEditor = nil },
                          onDelete: context.habitId.map { id in { model.deleteHabit(id: id) } })
                .frame(width: 700, height: 600)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if model.route != .list {
                SwiftUI.Button(action: { model.backToList() }) {
                    Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                }
                .buttonStyle(FBButtonStyle())
                .help(ScheduleText.customRoutineBack)
            }
            Text(headerTitle).font(.fbSemibold(16)).foregroundColor(.white).lineLimit(1)
            Spacer()
            SwiftUI.Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            }
            .buttonStyle(FBButtonStyle())
            .help(ScheduleText.habitCancel)
            .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.customRoutineManagerCloseButton)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(FBColor.accent)
    }

    private var headerTitle: String {
        switch model.route {
        case .list: return ScheduleText.customRoutinesTitle
        case .new: return ScheduleText.customRoutineNewTitle
        case .edit:
            let name = model.editingRoutine?.values.trimmedName ?? ""
            return name.isEmpty ? ScheduleText.customRoutineEditTitle : name
        }
    }

    @ViewBuilder private var content: some View {
        switch model.route {
        case .list: CustomRoutineListView(model: model)
        case .new, .edit: CustomRoutineEditView(model: model)
        }
    }
}

// MARK: - List

@available(macOS 11.0, *)
private struct CustomRoutineListView: View {
    @ObservedObject var model: CustomRoutineManagerModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if model.routines.isEmpty {
                        Text(ScheduleText.customRoutineNone)
                            .font(.fbRegular(13)).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(model.routines) { routine in
                        row(routine)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(FBColor.fieldBackground)
            Divider()
            HStack {
                Text(ScheduleText.customRoutineDraftHint)
                    .font(.fbRegular(11)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                SwiftUI.Button(action: { model.startNewRoutine() }) { Text(ScheduleText.customRoutineNew) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false))
                    .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.customRoutineNewButton)
            }
            .padding(16)
        }
    }

    private func row(_ routine: CustomRoutineSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(displayName(routine)).font(.fbSemibold(14)).lineLimit(1)
                Spacer()
                SwiftUI.Button(action: { model.startEditing(routine) }) { Text(ScheduleText.editHabit) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true))
                SwiftUI.Button(action: { model.pendingDeleteId = routine.id }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(FBButtonStyle())
                .help(ScheduleText.customRoutineDelete)
            }
            Text(scheduleSummary(routine)).font(.fbRegular(12)).foregroundColor(.secondary)
            if routine.isEmpty {
                Text(ScheduleText.customRoutineEmptyHabits)
                    .font(.fbRegular(11)).foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.pendingDeleteId == routine.id {
                HStack(spacing: 8) {
                    Text(ScheduleText.customRoutineDeleteConfirm).font(.fbRegular(12))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    SwiftUI.Button(action: { model.pendingDeleteId = nil }) { Text(ScheduleText.habitCancel) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true))
                    SwiftUI.Button(action: { model.deleteRoutine(sequenceId: routine.id) }) {
                        Text(ScheduleText.habitDeleteConfirmButton)
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            }
        }
        .padding(12)
        .background(FBColor.lightOrangeBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FBColor.lightOrangeBorder, lineWidth: 1))
        .cornerRadius(8)
    }

    private func displayName(_ routine: CustomRoutineSummary) -> String {
        routine.values.trimmedName.isEmpty ? ScheduleText.customRoutineUntitled : routine.values.trimmedName
    }

    /// "On demand · 3 habits" or "Mon, Tue · 12:00–13:00 · 3 habits".
    private func scheduleSummary(_ routine: CustomRoutineSummary) -> String {
        let count = routine.habits.count == 1 ? ScheduleText.customRoutineHabitCountOne
                                              : String(format: ScheduleText.customRoutineHabitCount, routine.habits.count)
        let separator = ScheduleText.customRoutineSummarySeparator
        if routine.values.triggerOnDemand {
            return [ScheduleText.customRoutineTriggerOnDemand, count].joined(separator: separator)
        }
        let window = "\(DayPlanRoutineDraft.timeString(fromMinutes: routine.values.startMinutes))–"
            + DayPlanRoutineDraft.timeString(fromMinutes: routine.values.endMinutes)
        return [CustomRoutineDaysText.label(routine.values.orderedDays), window, count].joined(separator: separator)
    }
}

/// Short day summary for a routine row: "Every day", "Weekdays", "Weekend", else the locale-short names.
@available(macOS 11.0, *)
enum CustomRoutineDaysText {
    static func label(_ days: [String]) -> String {
        let set = Set(days)
        if set == Set(HabitEditValues.weekdayCodes) { return ScheduleText.habitDaysAll }
        if set == Set(["MON", "TUE", "WED", "THU", "FRI"]) { return ScheduleText.habitDaysWeekdays }
        if set == Set(["SAT", "SUN"]) { return ScheduleText.habitDaysWeekend }
        return days.map(DayOfWeekPicker.shortLabel).joined(separator: ScheduleText.customRoutineDaySeparator)
    }
}

// MARK: - Routine form

@available(macOS 11.0, *)
private struct CustomRoutineEditView: View {
    @ObservedObject var model: CustomRoutineManagerModel
    @SwiftUI.State private var isConfirmingDelete = false

    private let labelWidth: CGFloat = 130

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    fields
                    if model.editingRoutine != nil {
                        Divider()
                        habitsSection
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(FBColor.fieldBackground)
            Divider()
            footer
        }
    }

    @ViewBuilder private var fields: some View {
        labelled(ScheduleText.customRoutineFieldName) {
            TextField(ScheduleText.customRoutineFieldName, text: $model.form.name)
                .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.customRoutineNameField)
        }
        labelled(ScheduleText.customRoutineFieldTrigger) {
            Picker("", selection: $model.form.triggerOnDemand) {
                Text(ScheduleText.customRoutineTriggerScheduled).tag(false)
                Text(ScheduleText.customRoutineTriggerOnDemand).tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .frame(width: 260)
        }
        labelled(ScheduleText.habitFieldDays) {
            DayOfWeekPicker(selection: $model.form.daysOfWeek)
        }
        if !model.form.triggerOnDemand {
            labelled(ScheduleText.customRoutineFieldStart) {
                MinutesTimePicker(title: ScheduleText.customRoutineFieldStart, minutes: $model.form.startMinutes)
            }
            labelled(ScheduleText.customRoutineFieldEnd) {
                MinutesTimePicker(title: ScheduleText.customRoutineFieldEnd, minutes: $model.form.endMinutes)
            }
        } else {
            Text(ScheduleText.customRoutineOnDemandHint)
                .font(.fbRegular(11)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var habitsSection: some View {
        Text(ScheduleText.customRoutineHabitsTitle).font(.fbSemibold(13))
        if let routine = model.editingRoutine {
            if routine.habits.isEmpty {
                Text(ScheduleText.customRoutineEmptyHabits)
                    .font(.fbRegular(12)).foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(routine.habits.enumerated()), id: \.element.id) { index, habit in
                habitRow(habit, index: index, count: routine.habits.count)
            }
        }
        SwiftUI.Button(action: { model.addHabit() }) { Text(ScheduleText.customRoutineAddHabit) }
            .buttonStyle(AppOrangeButtonStyle(secondary: true))
    }

    private func habitRow(_ habit: CustomRoutineHabitSummary, index: Int, count: Int) -> some View {
        HStack(spacing: 8) {
            VStack(spacing: 2) {
                moveButton("chevron.up", help: ScheduleText.customRoutineMoveUp, enabled: index > 0) {
                    model.moveHabit(from: index, to: index - 1)
                }
                moveButton("chevron.down", help: ScheduleText.customRoutineMoveDown, enabled: index < count - 1) {
                    model.moveHabit(from: index, to: index + 1)
                }
            }
            Text(habit.name.isEmpty ? ScheduleText.newHabitTitle : habit.name).font(.fbRegular(13)).lineLimit(1)
            Spacer()
            Text(habit.durationLabel).font(.fbRegular(12)).foregroundColor(.secondary)
            SwiftUI.Button(action: { model.editHabit(habit) }) { Image(systemName: "pencil") }
                .buttonStyle(FBButtonStyle())
                .help(ScheduleText.editHabit)
            SwiftUI.Button(action: { model.deleteHabit(id: habit.id) }) { Image(systemName: "trash") }
                .buttonStyle(FBButtonStyle())
                .help(ScheduleText.customRoutineRemoveHabit)
        }
        .padding(8)
        .background(FBColor.lightOrangeBackground)
        .cornerRadius(6)
    }

    private func moveButton(_ symbol: String, help: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            Image(systemName: symbol).font(.system(size: 9, weight: .bold))
                .foregroundColor(enabled ? .primary : .secondary)
        }
        .buttonStyle(FBButtonStyle())
        .disabled(!enabled)
        .help(help)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let message = model.formValidationMessage {
                Text(message).font(.fbRegular(12)).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                if let routine = model.editingRoutine {
                    if isConfirmingDelete {
                        Text(ScheduleText.customRoutineDeleteConfirm).font(.fbRegular(12))
                            .fixedSize(horizontal: false, vertical: true)
                        SwiftUI.Button(action: { isConfirmingDelete = false }) { Text(ScheduleText.habitCancel) }
                            .buttonStyle(AppOrangeButtonStyle(secondary: true))
                        SwiftUI.Button(action: { model.deleteRoutine(sequenceId: routine.id) }) {
                            Text(ScheduleText.habitDeleteConfirmButton)
                        }
                        .buttonStyle(DestructiveButtonStyle())
                    } else {
                        SwiftUI.Button(action: { isConfirmingDelete = true }) { Text(ScheduleText.customRoutineDelete) }
                            .buttonStyle(DestructiveButtonStyle())
                    }
                }
                Spacer()
                SwiftUI.Button(action: { model.backToList() }) { Text(ScheduleText.habitCancel) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true))
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier(UITestContract.Identifier.TasksRegression.customRoutineEditCancelButton)
                SwiftUI.Button(action: saveOrCreate) { Text(saveTitle) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false))
                    .disabled(model.formValidationMessage != nil)
            }
        }
        .padding(16)
    }

    private var saveTitle: String {
        model.editingRoutine == nil ? ScheduleText.customRoutineCreate : ScheduleText.habitSave
    }

    private func saveOrCreate() {
        if model.editingRoutine == nil { model.createRoutine() } else { model.saveRoutine() }
    }

    private func labelled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title).font(.fbRegular(13)).frame(width: labelWidth, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }
}
