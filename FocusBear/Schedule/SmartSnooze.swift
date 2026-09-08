//
//  SmartSnooze.swift
//  Focus Bear
//
//  The "Move task to…" snooze control, shared by the Day Plan tasks panel and the native To-do list
//  so both offer the identical popover: the "Next free slot: Fri 15 Aug" smart button (the
//  cumulative-rollover model over the coming weekdays, `SmartSnoozeMath`), a free-text date
//  ("2d", "tue", "1 Jul" — `parseSnoozeDate`) with a live preview, Move / Cancel. The planner decides
//  where a task lands, the popover only asks; each host applies the move with its own store.
//

import AppKit
import SwiftUI

/// Pure, unit-tested maths for the "Choose a good time for me" smart snooze. Kept free of AppKit / store
/// dependencies so the calculations can be tested in isolation.
enum SmartSnoozeMath {
    /// Effective free minutes per day under the CUMULATIVE ROLLOVER model: people rarely finish
    /// everything, so `rolloverFraction` of each day's TOTAL task load (its own load plus what it carried
    /// from earlier days) is assumed to spill into the next day. So the load carried into day i is
    /// `rolloverFraction × (load[i-1] + carry[i-1])`, and effective free = schedule gaps − (own load +
    /// carried load). Near days look busier, so snooze targets a genuinely empty day. Can go negative.
    /// `scheduleFree` and `load` are parallel arrays (one entry per day, in chronological order).
    /// `initialCarry` seeds the rollover BEFORE the first horizon day — used to spill the SOURCE day's
    /// (e.g. today's) load into tomorrow, so a day still packed with today's work doesn't make tomorrow
    /// look free (the horizon itself starts at tomorrow).
    static func effectiveFree(scheduleFree: [Int], load: [Int], rolloverFraction: Double, initialCarry: Double = 0) -> [Int] {
        precondition(scheduleFree.count == load.count, "scheduleFree and load must be parallel")
        var carry = initialCarry
        var out: [Int] = []
        for i in scheduleFree.indices {
            let total = Double(load[i]) + carry
            out.append(scheduleFree[i] - Int(total.rounded()))
            carry = total * rolloverFraction
        }
        return out
    }

    /// Distribute `taskDurations` (in order) across the days: each task lands on the FIRST day whose
    /// effective free (with rollover, and this task added to that day's load) stays ≥ 0; if no day in
    /// range can fit it, the emptiest effective day. Returns the chosen day INDEX per task (parallel to
    /// `taskDurations`). `startLoad` is each day's existing task load. Assigning a task raises that day's
    /// load, which — via the rollover — makes later days busier too, so tasks spread out to empty days.
    static func distribute(taskDurations: [Int], scheduleFree: [Int], startLoad: [Int],
                           rolloverFraction: Double, initialCarry: Double = 0) -> [Int] {
        var load = startLoad
        var result: [Int] = []
        for dur in taskDurations {
            var placedIndex: Int?
            for i in load.indices {
                load[i] += dur
                if effectiveFree(scheduleFree: scheduleFree, load: load, rolloverFraction: rolloverFraction, initialCarry: initialCarry)[i] >= 0 {
                    placedIndex = i; break
                }
                load[i] -= dur
            }
            if let i = placedIndex {
                result.append(i)
            } else {
                let eff = effectiveFree(scheduleFree: scheduleFree, load: load, rolloverFraction: rolloverFraction, initialCarry: initialCarry)
                let idx = load.indices.max(by: { eff[$0] < eff[$1] }) ?? 0
                load[idx] += dur
                result.append(idx)
            }
        }
        return result
    }
}

/// A smart-snooze slot: the day to move to and whether it genuinely fits the required minutes (vs the
/// emptiest-day fallback used when nothing in the horizon fits).
struct SmartSnoozeSlot: Equatable {
    let target: Date
    let fits: Bool
    let bestFree: Int
}

/// Finds where a snoozed task should land: the coming weekdays, each with its RAW schedule-free minutes
/// (routine / meeting gaps, from the host) and its open Day Plan task load, run through the rollover
/// model. Built fresh for each popover — the scan is a cheap bounded schedule build per day.
struct SmartSnoozePlanner {
    static let horizonDays = 14
    static let extendedHorizonDays = 90
    static let rolloverFraction = 0.5

    /// The day being snoozed FROM; the horizon starts the day after, and this day's remaining load
    /// seeds the rollover.
    let sourceDate: Date
    /// RAW schedule-free minutes on a day (NOT net of tasks).
    let scheduleFreeMinutes: (Date) -> Int
    /// Minutes of open tasks already planned on a day.
    let openTaskMinutes: (Date) -> Int

    /// One horizon day: raw schedule-free minutes and its current open-task load.
    struct Day: Equatable {
        let day: Date
        let scheduleFree: Int
        let load: Int
    }

    /// The Day Plan's planner: the schedule's free time and the Day Plan's own open tasks per day.
    static func dayPlan(from sourceDate: Date, scheduleFreeMinutes: @escaping (Date) -> Int) -> SmartSnoozePlanner {
        SmartSnoozePlanner(sourceDate: sourceDate, scheduleFreeMinutes: scheduleFreeMinutes, openTaskMinutes: { day in
            DayPlanTaskStore.shared.tasks(for: day).filter { !$0.done }.reduce(0) { $0 + $1.durationMinutes }
        })
    }

    /// Gather the horizon (tomorrow … +`days`), each with its RAW schedule-free minutes and existing
    /// open-task load. Weekends (Sat/Sun) are skipped so the auto-suggested "Next free slot" lands on a
    /// weekday — the app has no per-user work-week setting, so Sat/Sun are treated as non-working by
    /// default (a user can still type an explicit weekend date into the field).
    func horizon(days: Int = SmartSnoozePlanner.horizonDays) -> [Day]? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: sourceDate)
        var out: [Day] = []
        for offset in 1...days {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            // Skip Sat/Sun by explicit Gregorian weekday number (1 = Sun, 7 = Sat). NOT
            // `isDateInWeekend`, which is locale-dependent — some regions define the weekend as
            // Sunday-only (or Fri/Sat), which let Saturday slip into the horizon and be suggested as the
            // "Next free slot" (e.g. Sat 5 Sep on a Sunday-only-weekend Mac).
            let weekday = cal.component(.weekday, from: day)
            if weekday == 1 || weekday == 7 { continue }
            out.append(Day(day: day, scheduleFree: scheduleFreeMinutes(day), load: openTaskMinutes(day)))
        }
        return out.isEmpty ? nil : out
    }

    /// The horizon to snooze into: the cheap near-term fortnight, extended into future weeks ONLY when the
    /// fortnight can't fit `requiredMinutes` (so a fully-booked two weeks rolls out to a genuinely free week
    /// instead of suggesting a cramped day). Shared by the button-label preview and the actual move so
    /// they agree.
    func horizon(for requiredMinutes: Int) -> [Day]? {
        guard let near = horizon(days: SmartSnoozePlanner.horizonDays) else { return nil }
        if effectiveFree(near).contains(where: { $0 >= requiredMinutes }) { return near }
        return horizon(days: SmartSnoozePlanner.extendedHorizonDays) ?? near
    }

    /// Effective free minutes per horizon day under the cumulative-rollover model.
    func effectiveFree(_ horizon: [Day]) -> [Int] {
        SmartSnoozeMath.effectiveFree(scheduleFree: horizon.map { $0.scheduleFree }, load: horizon.map { $0.load },
                                      rolloverFraction: SmartSnoozePlanner.rolloverFraction, initialCarry: sourceDayCarry)
    }

    /// Rollover seeded from the SOURCE day: `rolloverFraction` of its remaining undone task minutes is
    /// assumed to spill into tomorrow — so a today that's still packed with tasks doesn't make TOMORROW
    /// look free (the horizon starts at tomorrow, so without this today is ignored).
    var sourceDayCarry: Double { Double(openTaskMinutes(sourceDate)) * SmartSnoozePlanner.rolloverFraction }

    /// The first horizon day whose EFFECTIVE free time is at least `requiredMinutes` (`fits: true`), else
    /// the emptiest effective day (`fits: false`), or nil when there is no horizon. A task with no
    /// duration (0) fits any non-overloaded day, so it still gets a suggested date.
    func slot(requiredMinutes: Int) -> SmartSnoozeSlot? {
        guard requiredMinutes >= 0, let horizon = horizon(for: requiredMinutes) else { return nil }
        let eff = effectiveFree(horizon)
        var bestFree = Int.min
        var bestDay: Date?
        for i in horizon.indices {
            if eff[i] > bestFree { bestFree = eff[i]; bestDay = horizon[i].day }
            if eff[i] >= requiredMinutes { return SmartSnoozeSlot(target: horizon[i].day, fits: true, bestFree: eff[i]) }
        }
        guard let target = bestDay else { return nil }
        return SmartSnoozeSlot(target: target, fits: false, bestFree: bestFree)
    }

    /// The day for each of `durations` (in order) under the rollover model — each lands on the first day
    /// that still has effective room, and placing it makes later days busier, so several tasks spread
    /// out to genuinely empty days instead of piling onto an already-full tomorrow. Uses the same
    /// requirement-aware horizon as `slot` so the move lands where the button promised.
    func distribute(durations: [Int]) -> [Date]? {
        guard let horizon = horizon(for: durations.reduce(0, +)) else { return nil }
        let chosen = SmartSnoozeMath.distribute(taskDurations: durations, scheduleFree: horizon.map { $0.scheduleFree },
                                                startLoad: horizon.map { $0.load },
                                                rolloverFraction: SmartSnoozePlanner.rolloverFraction, initialCarry: sourceDayCarry)
        return chosen.map { horizon[$0].day }
    }
}

/// The "Move task to…" popover (AppKit, as the Day Plan is). Owns its text field delegate and the
/// main window's default-button guard: while it is open the habit "Start" button is detached from
/// Return (it would otherwise fire before the field sees the key), and reattached when it closes —
/// however it closes, including a click outside.
final class SmartSnoozePopover: NSObject, NSTextFieldDelegate, NSPopoverDelegate {
    static let fieldWidth: CGFloat = 230
    static let suggestionDateFormat = "EEE d MMM"
    private static let previewDateFormat = "EEE d MMM yyyy"
    private static let inputIdentifier = NSUserInterfaceItemIdentifier("snoozeInput")
    private static let padding: CGFloat = 14
    private static let infoIconSize: CGFloat = 15

    private let baseDate: Date
    private let suggestion: SmartSnoozeSlot?
    private let onSmart: () -> Void
    private let onMove: (Date) -> Void
    private let onDismiss: () -> Void
    private var popover: NSPopover?
    private weak var field: NSTextField?
    private weak var parsedLabel: NSTextField?
    private weak var hostWindow: NSWindow?
    private var savedDefaultButton: NSButtonCell?

    /// - Parameters:
    ///   - baseDate: what relative input ("2d", "tue") counts from.
    ///   - suggestion: the planner's slot, named on the smart button; nil shows the generic label.
    ///   - onSmart: the smart button — the host distributes with its planner and moves.
    ///   - onMove: Move (or Return) with a recognised typed date.
    ///   - onDismiss: after the popover closed for any reason, once.
    init(baseDate: Date, suggestion: SmartSnoozeSlot?, onSmart: @escaping () -> Void,
         onMove: @escaping (Date) -> Void, onDismiss: @escaping () -> Void = {}) {
        self.baseDate = baseDate
        self.suggestion = suggestion
        self.onSmart = onSmart
        self.onMove = onMove
        self.onDismiss = onDismiss
    }

    var isShown: Bool { popover?.isShown ?? false }

    /// The smart button's title for a suggestion: "Next free slot: Fri 15 Aug", else the generic label.
    static func smartTitle(for suggestion: SmartSnoozeSlot?) -> String {
        guard let slot = suggestion else { return ScheduleText.tasksSnoozeSmart }
        let formatter = DateFormatter()
        formatter.dateFormat = suggestionDateFormat
        return ScheduleText.tasksSnoozeNextSlot(formatter.string(from: slot.target))
    }

    func show(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge = .minY) {
        guard popover == nil else { return }
        let pop = NSPopover()
        pop.contentViewController = makeContent()
        pop.behavior = .transient
        pop.delegate = self
        hostWindow = view.window
        savedDefaultButton = view.window?.defaultButtonCell
        view.window?.defaultButtonCell = nil
        pop.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
        popover = pop
        if let field = field { field.window?.makeFirstResponder(field) }
    }

    func close() {
        popover?.close()
    }

    // MARK: Content

    private func makeContent() -> NSViewController {
        let header = label(ScheduleText.tasksSnoozeTitle, size: 13, bold: true)

        let input = NSTextField()
        input.placeholderString = ScheduleText.tasksSnoozePlaceholder
        input.identifier = SmartSnoozePopover.inputIdentifier
        input.delegate = self
        input.translatesAutoresizingMaskIntoConstraints = false
        input.widthAnchor.constraint(equalToConstant: SmartSnoozePopover.fieldWidth).isActive = true
        field = input

        let parsed = label("", size: 12, bold: true)
        parsed.textColor = .controlAccentColor
        parsedLabel = parsed

        let hint = label(ScheduleText.tasksSnoozeHelp, size: 11, bold: false)
        hint.textColor = .secondaryLabelColor
        hint.lineBreakMode = .byWordWrapping
        hint.maximumNumberOfLines = 0
        hint.preferredMaxLayoutWidth = SmartSnoozePopover.fieldWidth

        // Smart snooze: the app picks the next day with enough free time, instead of the user typing one.
        // The button names the suggested day whether or not it perfectly "fits" — the emptiest upcoming
        // weekday is a better, actionable suggestion than the generic label.
        let smart = cursorButton(title: SmartSnoozePopover.smartTitle(for: suggestion), target: self, action: #selector(smartClicked))
        smart.bezelStyle = .rounded
        let info = NSImageView()
        info.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: ScheduleText.tasksSnoozeSmartInfo)
        info.contentTintColor = .secondaryLabelColor
        info.toolTip = ScheduleText.tasksSnoozeSmartInfo
        info.translatesAutoresizingMaskIntoConstraints = false
        info.widthAnchor.constraint(equalToConstant: SmartSnoozePopover.infoIconSize).isActive = true
        info.heightAnchor.constraint(equalToConstant: SmartSnoozePopover.infoIconSize).isActive = true
        let smartRow = NSStackView(views: [smart, info, NSView()])
        smartRow.orientation = .horizontal; smartRow.spacing = 6; smartRow.alignment = .centerY

        let move = cursorButton(title: ScheduleText.tasksSnoozeConfirm, target: self, action: #selector(moveClicked))
        move.bezelStyle = .rounded; move.keyEquivalent = "\r"
        let cancel = cursorButton(title: ScheduleText.tasksSnoozeCancel, target: self, action: #selector(cancelClicked))
        cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"
        let buttons = NSStackView(views: [NSView(), cancel, move])
        buttons.orientation = .horizontal; buttons.spacing = 8

        let form = NSStackView(views: [header, smartRow, input, parsed, hint, buttons])
        form.orientation = .vertical; form.alignment = .leading; form.spacing = 8
        form.translatesAutoresizingMaskIntoConstraints = false
        buttons.widthAnchor.constraint(equalTo: input.widthAnchor).isActive = true

        let container = NSView()
        container.addSubview(form)
        let padding = SmartSnoozePopover.padding
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),
            form.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding),
        ])
        let controller = NSViewController()
        controller.view = container
        return controller
    }

    private func label(_ text: String, size: CGFloat, bold: Bool) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    // MARK: Actions

    /// The typed text as a day, if the grammar recognises it.
    private var typedDate: Date? {
        parseSnoozeDate(field?.stringValue ?? "", from: baseDate)
    }

    private func updatePreview() {
        let input = field?.stringValue ?? ""
        if let date = typedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = SmartSnoozePopover.previewDateFormat
            parsedLabel?.stringValue = "→ " + formatter.string(from: date)
        } else {
            parsedLabel?.stringValue = input.isEmpty ? "" : "— ?"
        }
    }

    @objc private func smartClicked() {
        onSmart()
    }

    @objc private func moveClicked() {
        guard let target = typedDate else { NSSound.beep(); return }
        onMove(target)
    }

    @objc private func cancelClicked() {
        close()
    }

    // MARK: Delegates

    func controlTextDidChange(_ notification: Notification) {
        updatePreview()
    }

    /// Return in the field moves, Escape closes — handled here rather than left to bubble up, where the
    /// host window's own key handling would see them.
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) { moveClicked(); return true }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) { close(); return true }
        return false
    }

    func popoverDidClose(_ notification: Notification) {
        popover = nil
        if let cell = savedDefaultButton { hostWindow?.defaultButtonCell = cell; savedDefaultButton = nil }
        onDismiss()
    }
}

/// Presents `SmartSnoozePopover` from SwiftUI: sit it in the `.background` of the button that opens
/// the snooze and flip `isPresented`. The suggestion is computed when the popover opens, not on
/// every render — the planner scans the coming weeks' schedules.
struct SmartSnoozePopoverPresenter: NSViewRepresentable {
    @Binding var isPresented: Bool
    let baseDate: Date
    let suggestion: () -> SmartSnoozeSlot?
    let onSmart: () -> Void
    let onMove: (Date) -> Void

    final class Coordinator {
        var popover: SmartSnoozePopover?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        let coordinator = context.coordinator
        if isPresented, coordinator.popover == nil {
            let popover = SmartSnoozePopover(baseDate: baseDate, suggestion: suggestion(), onSmart: onSmart, onMove: onMove,
                                             onDismiss: { DispatchQueue.main.async { coordinator.popover = nil; isPresented = false } })
            coordinator.popover = popover
            // Not inside the layout pass that called us; the anchor must be in its window by then.
            DispatchQueue.main.async {
                guard view.window != nil else { coordinator.popover = nil; isPresented = false; return }
                popover.show(relativeTo: view.bounds, of: view)
            }
        } else if !isPresented, let popover = coordinator.popover {
            popover.close()
        }
    }
}
