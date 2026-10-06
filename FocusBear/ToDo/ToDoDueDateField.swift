//
//  ToDoDueDateField.swift
//  Focus Bear
//
//  Due-date entry shared by the task editor and the new-project sheet: a typed field that
//  understands typed dates ("2d", "fri", "28 sep", "25/9" — `ToDoDueDateParser`), the resolved day
//  ("Fri 11 Sep") or a red "Unrecognised date" hint beneath, and an optional graphical calendar.
//  All three drive the same `day` binding, so they never disagree.
//
//  The field's text *is* the date: it opens showing the task's existing due date rather than a
//  placeholder (report 2026-09-15_19-50-02), and every keystroke that resolves to a day writes that
//  day straight to the binding (report 2026-09-15_19-49-26). It used to write only when the field
//  lost focus, which never happens when the next thing the user clicks is the editor's SwiftUI Save
//  button — a click on SwiftUI content does not end AppKit's field editing, so the typed date was
//  dropped and the old one saved.
//

import SwiftUI
import AppKit

struct ToDoDueDateField: View {
    @Binding var day: Date?
    let strings: ToDoStrings
    /// Calendar icon under the typed field instead of beside it — for a narrow column such as the
    /// task editor's TOP card, where a single row would not fit.
    var isStacked = false
    /// The typed field's accessibility identifier, where a UI test needs to read it.
    private let fieldIdentifier: String?

    /// What the field shows. Seeded from `day`, and re-seeded whenever the day moves underneath.
    @SwiftUI.State private var input: String
    /// True once typing has paused (or Return was pressed) — gates the red hint so it doesn't
    /// strobe through the unparseable prefixes of "28th".
    @SwiftUI.State private var hasTypingSettled = false
    @SwiftUI.State private var settleGeneration = 0
    @SwiftUI.State private var showExactDate = false

    private static let inputWidth: CGFloat = 150
    private static let hintFontSize: CGFloat = 11
    private static let settleDelay: TimeInterval = 0.6

    init(day: Binding<Date?>, strings: ToDoStrings, isStacked: Bool = false, fieldIdentifier: String? = nil) {
        _day = day
        self.strings = strings
        self.isStacked = isStacked
        self.fieldIdentifier = fieldIdentifier
        _input = SwiftUI.State(initialValue: ToDoDueDateFieldText.text(for: day.wrappedValue))
    }

    /// ONE place to enter a due date, plus a calendar icon for picking an exact one. It used to be
    /// three controls side by side — a presets menu, a typed field and a calendar toggle — which is
    /// three answers to the same question (report 2026-09-14_19-50-05). The typed field already
    /// understands "tomorrow", "2d", "fri" and "next week", so the presets menu was redundant and is
    /// gone entirely (follow-up: "we don't need the dropdown").
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                typedField.frame(maxWidth: isStacked ? .infinity : ToDoDueDateField.inputWidth)
                exactDateButton
            }
            resolvedLine
            if showExactDate {
                DatePicker("", selection: Binding(get: { day ?? Date() }, set: { day = Calendar.current.startOfDay(for: $0) }), displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
            }
        }
        // Every keystroke re-previews immediately, commits as soon as it resolves to a day, and
        // restarts the wait before the red hint may appear.
        .onChange(of: input) { text in
            restartSettleTimer()
            applyTypedDate(text)
        }
        // The calendar picker (or a forecast suggestion) writes `day` without touching the text.
        .onChange(of: day) { newDay in
            guard let reseeded = ToDoDueDateFieldText.reseed(current: input, day: newDay) else { return }
            input = reseeded
        }
    }

    private var typedField: some View {
        ReturnGuardTextField(text: $input, placeholder: strings[.dueDatePlaceholder],
                             onCommit: commitTypedDate, onEndEditing: commitTypedDate,
                             accessibilityIdentifier: fieldIdentifier)
            .help(strings[.dueDateGrammarHelp])
    }

    /// A calendar icon beside the typed field, and nothing else. The presets dropdown went with it:
    /// the typed field already understands "tomorrow", "2d", "fri", so a menu repeating those was a
    /// third way to say the same thing ("replace the caret on the right with a calendar icon (exact
    /// date). We don't need the dropdown" — report 2026-09-14_19-50-05, follow-up).
    private var exactDateButton: some View {
        SwiftUI.Button(action: { showExactDate.toggle() }) {
            Image(systemName: "calendar").font(.system(size: 12))
                .foregroundColor(showExactDate ? ToDoTheme.accent : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .help(strings[.exactDate])
    }

    /// Under the row: what the typed text resolves to right now, or a quiet red hint when it
    /// doesn't resolve to anything and the user has stopped typing.
    @ViewBuilder
    private var resolvedLine: some View {
        switch ToDoDueDatePreviewResolver.preview(input: input, committedDay: day, hasSettled: hasTypingSettled) {
        case .blank:
            EmptyView()
        case .unrecognised:
            Text(strings[.unrecognisedDate]).font(.system(size: ToDoDueDateField.hintFontSize)).foregroundColor(ToDoTheme.overdue)
        case .day(let previewed):
            Text(ToDoDates.weekdayDayMonth(previewed)).font(.system(size: ToDoDueDateField.hintFontSize)).foregroundColor(.secondary)
        }
    }

    /// Hides the red hint, then shows it again only if the text is still unparseable a beat later.
    private func restartSettleTimer() {
        hasTypingSettled = false
        settleGeneration += 1
        let generation = settleGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + ToDoDueDateField.settleDelay) {
            guard generation == settleGeneration else { return }
            hasTypingSettled = true
        }
    }

    /// The date the text currently means, written as soon as it means one. Text that resolves to
    /// nothing leaves the day alone; an emptied field clears it, which is the only way this control
    /// offers to say "no due date" now that the date is the field's own text.
    private func applyTypedDate(_ text: String) {
        let typed = text.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else {
            day = nil
            return
        }
        guard let parsed = ToDoDueDateParser.parse(typed), parsed != day else { return }
        day = parsed
    }

    /// Return or losing focus: settle the hint straight away rather than after the delay, and
    /// rewrite shorthand as the date it resolved to ("25" → "25 Sep 2026") so the field shows what
    /// was saved. Text the grammar didn't understand stays put, under its red hint.
    private func commitTypedDate() {
        hasTypingSettled = true
        applyTypedDate(input)
        guard let parsed = ToDoDueDateParser.parse(input.trimmingCharacters(in: .whitespaces)) else { return }
        input = ToDoDueDateFieldText.text(for: parsed)
    }
}
