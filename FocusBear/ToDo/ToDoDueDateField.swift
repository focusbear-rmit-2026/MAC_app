//
//  ToDoDueDateField.swift
//  Focus Bear
//
//  Due-date entry shared by the task editor and the new-project sheet: a presets menu, a text
//  field that understands typed dates ("2d", "fri", "28 sep", "25/9" — `ToDoDueDateParser`) on
//  Return, the resolved day ("Fri 11 Sep") or a red "Unrecognised date" hint beneath, and an
//  optional graphical calendar. All three drive the same `day` binding, so they never disagree.
//

import SwiftUI
import AppKit

/// One entry of the presets menu (web `TaskTimeline` options).
struct ToDoDuePreset {
    let key: ToDoStringKey
    let add: (Calendar, Date) -> Date?

    static let standard: [ToDoDuePreset] = [
        ToDoDuePreset(key: .today) { _, now in now },
        ToDoDuePreset(key: .tomorrow) { calendar, now in calendar.date(byAdding: .day, value: 1, to: now) },
        ToDoDuePreset(key: .inAFewDays) { calendar, now in calendar.date(byAdding: .day, value: 3, to: now) },
        ToDoDuePreset(key: .nextWeek) { calendar, now in calendar.date(byAdding: .day, value: 7, to: now) },
        ToDoDuePreset(key: .inTwoWeeks) { calendar, now in calendar.date(byAdding: .day, value: 14, to: now) },
        ToDoDuePreset(key: .inAMonth) { calendar, now in calendar.date(byAdding: .month, value: 1, to: now) },
        ToDoDuePreset(key: .inAFewMonths) { calendar, now in calendar.date(byAdding: .month, value: 3, to: now) },
        ToDoDuePreset(key: .inAYear) { calendar, now in calendar.date(byAdding: .year, value: 1, to: now) },
        ToDoDuePreset(key: .neverDoThis) { calendar, now in calendar.date(byAdding: .day, value: 3650, to: now) },
    ]
}

struct ToDoDueDateField: View {
    @Binding var day: Date?
    let strings: ToDoStrings
    var presets: [ToDoDuePreset] = ToDoDuePreset.standard
    /// Presets menu above the typed field instead of beside it — for a narrow column such as the
    /// task editor's TOP card, where a single row would not fit.
    var isStacked = false

    @SwiftUI.State private var input = ""
    @SwiftUI.State private var isInputUnrecognised = false
    @SwiftUI.State private var showExactDate = false

    private static let menuWidth: CGFloat = 170
    private static let inputWidth: CGFloat = 150
    private static let hintFontSize: CGFloat = 11

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isStacked {
                presetsMenu
                HStack(spacing: 8) {
                    typedField
                    exactDateButton
                }
            } else {
                HStack(spacing: 8) {
                    presetsMenu
                    typedField.frame(width: ToDoDueDateField.inputWidth)
                    exactDateButton
                }
            }
            resolvedLine
            if showExactDate {
                DatePicker("", selection: Binding(get: { day ?? Date() }, set: { day = Calendar.current.startOfDay(for: $0) }), displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
            }
        }
        // Typing again withdraws the "unrecognised" hint until the next Return.
        .onChange(of: input) { _ in isInputUnrecognised = false }
    }

    private var typedField: some View {
        ReturnGuardTextField(text: $input, placeholder: strings[.dueDatePlaceholder], onCommit: commitTypedDate)
            .help(strings[.dueDateGrammarHelp])
    }

    private var exactDateButton: some View {
        SwiftUI.Button(action: { showExactDate.toggle() }) { Text(strings[.exactDate]).font(.system(size: ToDoDueDateField.hintFontSize)) }
            .buttonStyle(BorderedButtonStyle())
            .pointingHandCursor()
    }

    private var presetsMenu: some View {
        Menu {
            ForEach(presets, id: \.key) { preset in
                SwiftUI.Button(action: {
                    if let date = preset.add(Calendar.current, Calendar.current.startOfDay(for: Date())) { day = date }
                }) { Text(strings[preset.key]) }
            }
            Divider()
            SwiftUI.Button(action: { day = nil }) { Text(strings[.clear]) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(day.map { strings.dueLabel(ToDoDates.ymd($0)) } ?? strings[.noDueDate])
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .frame(width: ToDoDueDateField.menuWidth)
    }

    /// Under the row: what the typed text resolved to, or a quiet red hint when it didn't.
    @ViewBuilder
    private var resolvedLine: some View {
        if isInputUnrecognised {
            Text(strings[.unrecognisedDate]).font(.system(size: ToDoDueDateField.hintFontSize)).foregroundColor(ToDoTheme.overdue)
        } else if let day = day {
            Text(ToDoDates.weekdayDayMonth(day)).font(.system(size: ToDoDueDateField.hintFontSize)).foregroundColor(.secondary)
        }
    }

    /// Return in the text field: a recognised date replaces the day; anything else leaves it alone.
    private func commitTypedDate() {
        let typed = input.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return }
        guard let parsed = ToDoDueDateParser.parse(typed) else {
            isInputUnrecognised = true
            return
        }
        isInputUnrecognised = false
        day = parsed
    }
}
