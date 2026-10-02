//
//  DayPlanTasks.swift
//  Focus Bear
//
//  The "Tasks for today" side panel of the Day Plan and its local store. Tasks can be added
//  from scratch or (later) imported from the to-do list; each has a name, a completion checkbox
//  and an estimated duration. Duration and completion are kept LOCALLY for now (the backend has
//  no per-task duration and completes tasks via a web view) — a backend follow-up will sync these.
//

import Cocoa
import SwiftUI

/// Drag-and-drop plumbing for dropping a task onto a schedule block to nest it there.
enum DayPlanDrag {
    static let type = NSPasteboard.PasteboardType("io.focusbear.dayplantask")
    static let projectType = NSPasteboard.PasteboardType("io.focusbear.dayplanproject")
}

/// A draggable project group header. Drag one header onto another to reorder the project groups.
final class ProjectHeaderView: NSView, NSDraggingSource {
    var projectName = ""
    var onReorder: ((_ dragged: String, _ target: String) -> Void)?
    var onAdd: (() -> Void)?
    private let titleLabel = NSTextField(labelWithString: "")
    private let totalLabel = NSTextField(labelWithString: "")
    private var hovering = false { didSet { needsDisplay = true } }

    static func totalString(_ minutes: Int) -> String {
        guard minutes > 0 else { return "" }
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    init(title: String, name: String, totalMinutes: Int) {
        super.init(frame: .zero)
        projectName = name
        wantsLayer = true
        registerForDraggedTypes([DayPlanDrag.projectType])
        titleLabel.stringValue = "⠿  " + title
        titleLabel.font = .boldSystemFont(ofSize: 11)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.toolTip = "Drag to reorder projects"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        totalLabel.stringValue = Self.totalString(totalMinutes)
        totalLabel.font = .systemFont(ofSize: 10)
        totalLabel.textColor = .tertiaryLabelColor
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)

        let add = cursorButton(title: "", target: self, action: #selector(addClicked))
        add.bezelStyle = .inline; add.isBordered = false
        if #available(macOS 11.0, *) { add.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add task to project") } else { add.title = "+" }
        add.contentTintColor = .controlAccentColor
        add.toolTip = "Add a task to this project"
        add.translatesAutoresizingMaskIntoConstraints = false
        add.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(titleLabel); addSubview(totalLabel); addSubview(add)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            totalLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 6),
            totalLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            add.leadingAnchor.constraint(equalTo: totalLabel.trailingAnchor, constant: 4),
            add.trailingAnchor.constraint(equalTo: trailingAnchor),
            add.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            add.widthAnchor.constraint(equalToConstant: 18),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTotal(_ minutes: Int) { totalLabel.stringValue = Self.totalString(minutes) }

    @objc private func addClicked() { onAdd?() }

    /// Manual drop fallback (see TaskDragHandle) — gives the panel the dropped project + screen point
    /// to hit-test, because AppKit doesn't route drag destinations in the borderless full-screen window.
    var onManualDrop: ((_ draggedProject: String, _ screenPoint: NSPoint) -> Void)?
    // Live drag-visual hooks (the standard draggingEntered/draw indicator never fires in the borderless
    // full-screen window, so the panel draws its own insertion line driven by these).
    var onDragBegan: ((_ project: String, _ screenPoint: NSPoint) -> Void)?
    var onDragMoved: ((_ screenPoint: NSPoint) -> Void)?
    var onDragEnded: (() -> Void)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
    override func mouseDown(with event: NSEvent) {
        // Start the drag straight from mouse-down (AppKit handles tracking) — the manual event pump
        // got no drag events in the borderless full-screen window.
        let item = NSPasteboardItem()
        item.setString(projectName, forType: DayPlanDrag.projectType)
        let di = NSDraggingItem(pasteboardWriter: item)
        di.setDraggingFrame(bounds, contents: nil)
        beginDraggingSession(with: [di], event: event, source: self)
    }
    func draggingSession(_ s: NSDraggingSession, sourceOperationMaskFor c: NSDraggingContext) -> NSDragOperation { .generic }
    func draggingSession(_ s: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        onDragBegan?(projectName, screenPoint)
    }
    func draggingSession(_ s: NSDraggingSession, movedTo screenPoint: NSPoint) {
        onDragMoved?(screenPoint)
    }
    func draggingSession(_ s: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        onDragEnded?()
        if operation == [] { onManualDrop?(projectName, screenPoint) }
    }

    private func draggedName(_ s: NSDraggingInfo) -> String? {
        guard onReorder != nil, let n = s.draggingPasteboard.string(forType: DayPlanDrag.projectType),
              n.caseInsensitiveCompare(projectName) != .orderedSame else { return nil }
        return n
    }
    override func draggingEntered(_ s: NSDraggingInfo) -> NSDragOperation {
        guard draggedName(s) != nil else { return [] }
        hovering = true; return .generic
    }
    override func draggingExited(_ s: NSDraggingInfo?) { hovering = false }
    override func performDragOperation(_ s: NSDraggingInfo) -> Bool {
        hovering = false
        guard let n = draggedName(s) else { return false }
        onReorder?(n, projectName); return true
    }
    override func draw(_ r: NSRect) {
        super.draw(r)
        guard hovering else { return }
        NSColor.controlAccentColor.setStroke()
        let p = NSBezierPath(); p.lineWidth = 2
        p.move(to: NSPoint(x: 0, y: bounds.maxY - 1)); p.line(to: NSPoint(x: bounds.maxX, y: bounds.maxY - 1)); p.stroke()
    }
}

/// A task text field that (1) grabs focus on the FIRST click even while another field is being
/// edited (no double-click to switch tasks) and (2) wraps to its actual width when multi-line, by
/// keeping preferredMaxLayoutWidth in sync with its bounds so long names flow over up to 3 lines.
/// Multi-line notes editor that keeps Return/Enter for inserting a newline. Without this, Return
/// reaches a default button's key equivalent — the task-modal Save button, or (since suppressing the
/// window's `defaultButtonCell` doesn't take effect in the borderless full-screen window) the
/// schedule's habit "Start" button — and fires it instead of adding a line break. This is the
/// NSTextView counterpart of EditOnClickTextField's single-line-field guard below.
final class NewlineKeepingTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown, (event.keyCode == 36 || event.keyCode == 76),
           window?.firstResponder === self {
            insertNewline(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// A sub-task row's text field. Return adds the next sub-task instead of firing the modal's Save
/// button — the modal used to close on the first Return, which is not what you want halfway through
/// writing a checklist (report 2026-09-14_09-17-51).
final class SubtaskTextField: NSTextField {
    var onReturn: (() -> Void)?
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown, event.keyCode == 36 || event.keyCode == 76,
           let editor = currentEditor(), window?.firstResponder === editor {
            onReturn?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

final class EditOnClickTextField: NSTextField {
    /// Shift/⌘-click toggles multi-select instead of entering edit mode (for bulk actions).
    var onModifierClick: (() -> Void)?
    /// Plain click — used to reveal the per-task action row even if the editing-begin delegate
    /// notification doesn't fire (it proved unreliable, especially in full screen).
    var onPlainClick: (() -> Void)?
    override func mouseDown(with event: NSEvent) {
        if onModifierClick != nil,
           !event.modifierFlags.intersection([.shift, .command]).isEmpty {
            onModifierClick?()
            return
        }
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
        onPlainClick?()
    }
    // While THIS field is being edited, swallow Return/Enter at the key-equivalent stage so the
    // window's default button (the habit "Start" button) can't fire first. Suppressing the window's
    // defaultButtonCell works in a normal window but not in the borderless full-screen window, so we
    // intercept here regardless of window type. Ending editing commits via controlTextDidEndEditing.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown, (event.keyCode == 36 || event.keyCode == 76),
           let editor = currentEditor(), window?.firstResponder === editor {
            window?.makeFirstResponder(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
    // A task name is drawn transparently over the dark task panel / a coloured importance band, so
    // its display colour is often white (or a band-contrast colour). While editing, AppKit shows the
    // standard focused text-field surface, on which that light text is unreadable (reported: task
    // text illegible when clicking a task to edit it). For the duration of editing give the field a
    // real text box — system text background + matching text colour, which are guaranteed legible
    // together in any appearance — then restore the display colour when editing ends.
    private var displayTextColor: NSColor?
    override func becomeFirstResponder() -> Bool {
        // Set the editable colours BEFORE super installs the field editor, so it copies these (not the
        // selected-row colour the field currently carries). A selected row draws its name in
        // alternateSelectedControlTextColor; without this the field editor kept that colour and the
        // text was illegible on the plain edit surface (reported repeatedly: task/project text
        // unreadable — e.g. blue-on-blue — when clicking a task to edit it).
        let hadDisplayColor = displayTextColor != nil
        if !hadDisplayColor {
            displayTextColor = textColor
            textColor = .textColor
            backgroundColor = .textBackgroundColor
            drawsBackground = true
        }
        let began = super.becomeFirstResponder()
        guard began else {
            if !hadDisplayColor, let restore = displayTextColor {
                textColor = restore
                drawsBackground = false
                displayTextColor = nil
            }
            return false
        }
        // super may have already installed the field editor with the old colour — force it here too.
        forceEditorLegibleColours()
        return true
    }
    // Runs once the field editor is definitely installed and active (unlike becomeFirstResponder, where
    // currentEditor() can still be nil). This is the reliable place to fix the colour.
    override func textDidBeginEditing(_ notification: Notification) {
        super.textDidBeginEditing(notification)
        forceEditorLegibleColours()
    }
    /// Force the ACTIVE field editor to draw dark text on a light box. Setting the field's `textColor`
    /// alone wasn't enough — a #project token / selected-row colour left the editor's text storage
    /// carrying an accent (blue) foreground, so the text stayed blue-on-blue while editing. Overwriting
    /// the text storage's foreground colour over the whole range beats any such attributed colour.
    private func forceEditorLegibleColours() {
        guard let editor = currentEditor() as? NSTextView else { return }
        editor.textColor = .textColor
        editor.insertionPointColor = .textColor
        editor.drawsBackground = true
        editor.backgroundColor = .textBackgroundColor
        editor.typingAttributes = [
            .foregroundColor: NSColor.textColor,
            .font: font ?? NSFont.systemFont(ofSize: 13),
        ]
        let fullRange = NSRange(location: 0, length: (editor.string as NSString).length)
        editor.textStorage?.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)
    }
    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        if let restore = displayTextColor {
            textColor = restore
            drawsBackground = false
            displayTextColor = nil
        }
    }
    // Keep the wrap width in sync with the field's actual width so a multi-line field reports a
    // taller intrinsic size and grows over multiple lines.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if !usesSingleLineMode, abs(preferredMaxLayoutWidth - newSize.width) > 0.5 {
            preferredMaxLayoutWidth = newSize.width
            invalidateIntrinsicContentSize()
        }
    }
    // Explicitly compute the wrapped height for the field's current width. Relying on AppKit's
    // default intrinsicContentSize for an editable wrapping NSTextField is unreliable inside a stack
    // view (it keeps reporting a single line), so we measure the cell at the laid-out width.
    override var intrinsicContentSize: NSSize {
        guard !usesSingleLineMode else { return super.intrinsicContentSize }
        // NEVER report an intrinsic width for a multi-line field — otherwise, before it's laid out
        // (bounds.width == 0), it demands the full single-line text width, which can blow the panel
        // and window out wider than the screen on a day that has tasks. Width is driven by the
        // column constraint; we only supply the wrapped height.
        let width = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        guard width > 0, let cell = self.cell else {
            return NSSize(width: NSView.noIntrinsicMetric, height: super.intrinsicContentSize.height)
        }
        let measured = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        return NSSize(width: NSView.noIntrinsicMetric, height: ceil(measured.height))
    }
}

/// Ordinal suffixes accepted after a bare day number ("1st", "2nd", "3rd", "4th").
private let snoozeOrdinalSuffixes: Set<String> = ["st", "nd", "rd", "th"]
/// The highest day number any month can have — anything above this isn't a day of the month.
private let highestDayOfMonth = 31
/// How far ahead to look for a month that actually contains a day number (31 skips the short months).
private let monthsToSearchForDayNumber = 12

/// The day of the month a bare number names ("23", "23rd"), or nil if the text isn't one — a month
/// name, a slash, a relative unit or a sign all disqualify it, so the other grammars keep their input.
private func bareDayOfMonth(_ text: String) -> Int? {
    let digits = text.prefix(while: { $0.isNumber })
    guard let day = Int(digits), (1...highestDayOfMonth).contains(day) else { return nil }
    let suffix = String(text.dropFirst(digits.count))
    guard suffix.isEmpty || snoozeOrdinalSuffixes.contains(suffix) else { return nil }
    return day
}

/// The next day-of-month `day` on or after `today`: this month when that day hasn't passed yet,
/// otherwise the next month that HAS it — so 31 typed in February means 31 March, not 3 March.
private func nextOccurrence(ofDayOfMonth day: Int, onOrAfter today: Date, calendar: Calendar) -> Date? {
    var components = calendar.dateComponents([.year, .month], from: today)
    components.day = day
    for _ in 0...monthsToSearchForDayNumber {
        // A month too short for `day` rolls the date into the following month, which would answer a
        // day the user didn't type — the component check rejects those candidates.
        if let candidate = calendar.date(from: components),
           calendar.component(.day, from: candidate) == day,
           calendar.startOfDay(for: candidate) >= today {
            return calendar.startOfDay(for: candidate)
        }
        components.month = (components.month ?? 1) + 1
    }
    return nil
}

/// Parse a natural-language snooze ("2d", "2w", "3mo", "1y", "tue", "tom", "today", "23rd") into a
/// target day. A leading `-` (or "yesterday") moves to a PAST day so a task can be back-dated.
/// Returns nil if it can't be parsed.
func parseSnoozeDate(_ input: String, from base: Date) -> Date? {
    let s = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !s.isEmpty else { return nil }
    let cal = Calendar.current
    let today = cal.startOfDay(for: base)
    if s == "today" || s == "tod" { return today }
    if s == "tom" || s == "tmr" || s == "tomorrow" { return cal.date(byAdding: .day, value: 1, to: today) }
    if s == "yesterday" || s == "yest" || s == "yd" { return cal.date(byAdding: .day, value: -1, to: today) }
    // An explicit day number wins over a weekday shortcut: "fri 18th" can mean today.
    let weekdays: [(String, String, Int)] = [("sun", "sunday", 1), ("mon", "monday", 2),
        ("tue", "tuesday", 3), ("wed", "wednesday", 4), ("thu", "thursday", 5),
        ("fri", "friday", 6), ("sat", "saturday", 7)]
    let words = s.replacingOccurrences(of: ",", with: " ").split(whereSeparator: \.isWhitespace).map(String.init)
    if words.count == 2, let weekday = weekdays.first(where: { words[0] == $0.0 || words[0] == $0.1 }),
       let number = bareDayOfMonth(words[1]) {
        // An explicit weekday + day identifies this month's date, including a day before the
        // viewed Day Plan. Moving Saturday's task back to "fri 18th" must not jump to October.
        var components = cal.dateComponents([.year, .month], from: today)
        components.day = number
        guard let target = cal.date(from: components),
              cal.component(.month, from: target) == components.month,
              cal.component(.day, from: target) == number,
              cal.component(.weekday, from: target) == weekday.2 else { return nil }
        return target
    }
    // A weekday without a date still means its next occurrence, strictly after today.
    for (short, full, wd) in weekdays where s == short || s == full {
        var d = cal.date(byAdding: .day, value: 1, to: today)!
        while cal.component(.weekday, from: d) != wd { d = cal.date(byAdding: .day, value: 1, to: d)! }
        return d
    }
    // [±]<number><unit>: d/w/mo/y. A leading "-" back-dates the task (e.g. "-1d" = yesterday).
    var body = s
    var sign = 1
    if body.hasPrefix("-") { sign = -1; body = String(body.dropFirst()) }
    else if body.hasPrefix("+") { body = String(body.dropFirst()) }
    if let n = Int(body.prefix(while: { $0.isNumber })), n > 0 {
        let unit = String(body.drop(while: { $0.isNumber }))
        let m = sign * n
        switch unit {
        case "d", "day", "days":        return cal.date(byAdding: .day, value: m, to: today)
        case "w", "wk", "wks", "week", "weeks": return cal.date(byAdding: .day, value: m * 7, to: today)
        case "mo", "month", "months":   return cal.date(byAdding: .month, value: m, to: today)
        case "y", "yr", "yrs", "year", "years": return cal.date(byAdding: .year, value: m, to: today)
        default: break   // not a relative unit — fall through to absolute-date parsing ("1st July", "1/7"…)
        }
    }
    // A bare day number ("23", "23rd") means that day of the MONTH, not a count of days — "23" on the
    // 15th is the 23rd of this month. It resolves forward like every other branch here: a day that has
    // already passed means next month, because this control moves a task to a future day and the
    // grammar already has an explicit way to back-date ("-1d" / "yesterday").
    if let day = bareDayOfMonth(s), let target = nextOccurrence(ofDayOfMonth: day, onOrAfter: today, calendar: cal) {
        return target
    }
    // Absolute calendar date ("1st July", "July 1", "1/7", "Jul 1 2026"). NSDataDetector handles a wide
    // range of phrasings; if the day already passed this year (no year given), roll forward a year so a
    // snooze always lands in the future.
    if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        if let match = detector.firstMatch(in: input, options: [], range: range), let d = match.date {
            var day = cal.startOfDay(for: d)
            if day < today, let rolled = cal.date(byAdding: .year, value: 1, to: day) {
                day = cal.startOfDay(for: rolled)
            }
            return day >= today ? day : nil
        }
    }
    return nil
}

/// A small "⠿" grip on the left of each task row. Dragging it runs a direct mouse-tracking loop
/// (NOT NSDraggingSession): the session renders no drag image / no destination highlighting in the
/// app's borderless full-screen window and was laggy, so the panel draws its own feedback and we pump
/// the mouse events ourselves for smoothness.
final class TaskDragHandle: NSImageView {
    var taskID = ""
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }

    /// Called once the pointer has actually moved (a real drag, not a click). Panel creates the overlay.
    var onDragBegan: ((_ taskID: String, _ screenPoint: NSPoint) -> Void)?
    /// Called on each drag movement with the cursor's screen location.
    var onDragMoved: ((_ screenPoint: NSPoint) -> Void)?
    /// Called on mouse-up at the drop's screen location (only if a drag actually started).
    var onManualDrop: ((_ draggedTaskID: String, _ screenPoint: NSPoint) -> Void)?

    override func mouseDown(with event: NSEvent) {
        let start = NSEvent.mouseLocation
        var dragging = false
        // Modal event-tracking loop — direct, smooth event delivery in any window type.
        while let e = NSApp.nextEvent(matching: [.leftMouseDragged, .leftMouseUp],
                                      until: .distantFuture, inMode: .eventTracking, dequeue: true) {
            let pt = NSEvent.mouseLocation
            if e.type == .leftMouseUp {
                if dragging { onManualDrop?(taskID, pt) }
                return
            }
            if !dragging {   // require a few points of movement so a plain click isn't a drag
                if abs(pt.x - start.x) < 4, abs(pt.y - start.y) < 4 { continue }
                dragging = true
                onDragBegan?(taskID, pt)
            }
            onDragMoved?(pt)
        }
    }
}

/// A schedule card that accepts a dragged task. `onDrop` returns true if the task was accepted.
/// An NSStackView whose empty areas act as a button — used for the collapsible routine-section
/// header (clicking the title toggles the accordion; nested controls like the skip button still
/// receive their own clicks).
final class ClickableStack: NSStackView {
    var onClick: (() -> Void)?
    override func mouseDown(with event: NSEvent) {
        if onClick != nil { onClick?() } else { super.mouseDown(with: event) }
    }
    override func resetCursorRects() {
        super.resetCursorRects()
        if onClick != nil { addCursorRect(bounds, cursor: .pointingHand) }
    }
}

final class DropTargetView: NSView {
    var onDrop: ((String) -> Bool)?
    private var highlighted = false { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) { super.init(frame: frameRect); registerForDraggedTypes([DayPlanDrag.type]) }
    required init?(coder: NSCoder) { super.init(coder: coder); registerForDraggedTypes([DayPlanDrag.type]) }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard onDrop != nil else { return [] }
        highlighted = true
        return .generic
    }
    override func draggingExited(_ sender: NSDraggingInfo?) { highlighted = false }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        highlighted = false
        guard let id = sender.draggingPasteboard.string(forType: DayPlanDrag.type) else { return false }
        return onDrop?(id) ?? false
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if highlighted {
            NSColor.controlAccentColor.withAlphaComponent(0.18).setFill()
            let p = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
            p.fill()
        }
    }
}

/// A thin vertical strip the user drags to resize the tasks panel. Reports each drag step's
/// horizontal movement (in window coordinates) so the host can adjust the panel width.
final class PanelResizeHandle: NSView {
    var onResize: ((_ dxInWindow: CGFloat) -> Void)?
    private var lastX: CGFloat = 0
    override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeLeftRight) }
    override func mouseDown(with event: NSEvent) { lastX = event.locationInWindow.x }
    override func mouseDragged(with event: NSEvent) {
        let x = event.locationInWindow.x
        onResize?(x - lastX)
        lastX = x
    }
}

/// A task row in the panel that accepts another task dropped on it to reorder the list. Shows an
/// insertion line at its top edge while a drop is hovering.
final class TaskReorderRow: NSStackView {
    var taskID = ""
    var onReorder: ((_ draggedID: String, _ targetID: String) -> Void)?
    private var hovering = false { didSet { needsDisplay = true } }

    func enableReorder() {
        wantsLayer = true
        registerForDraggedTypes([DayPlanDrag.type])
    }

    private func draggedID(_ sender: NSDraggingInfo) -> String? {
        guard onReorder != nil,
              let id = sender.draggingPasteboard.string(forType: DayPlanDrag.type),
              id != taskID else { return nil }
        return id
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard draggedID(sender) != nil else { return [] }
        hovering = true
        return .generic
    }
    override func draggingExited(_ sender: NSDraggingInfo?) { hovering = false }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        hovering = false
        guard let id = draggedID(sender) else { return false }
        onReorder?(id, taskID)
        return true
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if hovering {
            NSColor.controlAccentColor.setStroke()
            let p = NSBezierPath()
            p.lineWidth = 2
            p.move(to: NSPoint(x: 0, y: bounds.maxY - 1))
            p.line(to: NSPoint(x: bounds.maxX, y: bounds.maxY - 1))
            p.stroke()
        }
    }
}

/// A checklist item under a task. Optional fields on DayPlanTask, so old stored data (which lacks
/// them) still decodes — Swift decodes missing keys of Optional properties as nil.
struct DayPlanSubtask: Codable, Equatable {
    var id: String
    var title: String
    var done: Bool
    init(id: String = UUID().uuidString, title: String, done: Bool = false) {
        self.id = id; self.title = title; self.done = done
    }
}

/// A to-do tag as the backend stores it (`{ id, text }`). Snapshotted from the to-do payload on import
/// so a project link can echo the to-do's label tags back — the `PUT /to-do` upsert replaces the whole
/// tag list, so sending only the project tag would drop them (see `DayPlanSync.setTodoProject`).
struct DayPlanTaskTag: Codable, Equatable {
    var id: String
    var text: String
}

/// The project-related fields of a backend to-do payload, read once at import so every import path
/// (day hydrate, due-list merge, to-do picker) stores the same thing.
struct TodoProjectFields {
    let projectID: String?
    let tags: [DayPlanTaskTag]
    /// The to-do belongs to an externally synced project (ClickUp / Trello, `synced_project_id`). The
    /// backend nulls `project_id` for those, so its tag must never be turned into a native project.
    let hasSyncedExternalProject: Bool
    /// The board column the to-do was last seen in. Completing here has to move the card as well as
    /// flip the status, and re-opening must only undo a move out of a column that finishes tasks —
    /// neither decision can be made without knowing where the task currently sits.
    let customStatusID: String?
    /// Who the to-do is assigned to, and a name to show for them.
    ///
    /// Read from the RELATION as well as the flat field, because `GET /to-do` sends only the relation
    /// (backend#2414). Reading the flat field alone reported every assigned task as unassigned.
    let assigneeID: String?
    let assigneeName: String?

    init(todo: [String: Any]) {
        projectID = todo["project_id"] as? String
        let assignee = todo["assignee"] as? [String: Any]
        assigneeID = ToDoAssigneeChoices.assigneeId(flat: todo["assignee_id"] as? String,
                                                    relation: assignee?["id"] as? String)
        assigneeName = (assignee?["username"] as? String) ?? (assignee?["email"] as? String)
        hasSyncedExternalProject = (todo["synced_project_id"] as? String).map { !$0.isEmpty } ?? false
        customStatusID = (todo["custom_status_id"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let raw = (todo["tags"] as? [[String: Any]]) ?? []
        tags = raw.compactMap { tag in
            guard let text = tag["text"] as? String,
                  let id = (tag["id"] as? String) ?? (tag["id"] as? NSNumber)?.stringValue else { return nil }
            return DayPlanTaskTag(id: id, text: text)
        }
    }

    init(todo: NSDictionary) {
        self.init(todo: (todo as? [String: Any]) ?? [:])
    }
}

/// Resolving a focus-session queue entry back to the planned task it came from.
///
/// The queue is built with `sourceTaskId ?? id` (see the focus player payload), so a queue id can be
/// either of a planned task's two identities — and completing a task in the focus UI left the Day Plan
/// showing it open because nothing joined the two back up (report 2026-09-14_10-09-59).
enum FocusQueueTaskMatch {
    static func task(for queueID: String, in tasks: [DayPlanTask]) -> DayPlanTask? {
        guard !queueID.isEmpty else { return nil }
        // The to-do id wins: it is what the queue carries whenever there is one, and two planned
        // copies of the same to-do would otherwise be told apart by the local id alone.
        return tasks.first { $0.sourceTaskId == queueID } ?? tasks.first { $0.id == queueID }
    }
}

/// One planned task for a given day. `sourceTaskId` links back to a backend to-do item when the
/// task was imported from the to-do list (nil for from-scratch tasks).
/// Eisenhower quadrant sent when a Day Plan task has none stored. The product does not use the
/// quadrant anywhere, so this is a filler the upsert requires rather than a meaningful value —
/// 4 is "not urgent, not important", the neutral corner.
let kDayPlanNeutralQuadrant = 4

struct DayPlanTask: Codable, Equatable {
    var id: String
    var title: String
    var durationMinutes: Int
    var done: Bool
    var sourceTaskId: String?
    /// Schedule block this task is nested under (set when dragged onto a block); nil = unassigned.
    var blockKey: String?
    /// Project/tag this task belongs to (from the to-do's tag, or typed as `#name`); nil = no project.
    var project: String?
    /// Longer description, editable in the task detail modal.
    var notes: String?
    /// Checklist sub-tasks (nil/absent for older tasks).
    var subtasks: [DayPlanSubtask]?
    /// Importance / "outcome" (1–10, higher = more important; maps to a to-do's `outcome`). nil = unset.
    var outcome: Int?
    /// The source to-do's Eisenhower quadrant (1–4), captured at import. Required to echo back on the
    /// `PUT /to-do` upsert (plan / complete) without clobbering it. nil for from-scratch tasks and for
    /// tasks imported before this field existed — sync is skipped in that case rather than risk a clobber.
    var eisenhowerQuadrant: Int?
    /// Set when the user deliberately moved this task to a PAST day (snooze/back-date). Rollover
    /// (which otherwise carries incomplete past tasks forward to today) skips these so a back-dated
    /// task stays where the user put it. nil/false = normal (rolls forward if left incomplete in the
    /// past). Optional so tasks stored before this field existed decode fine.
    var manuallyPlanned: Bool?

    /// Timestamp of the last edit the USER made to this task (add / rename / complete / re-plan / …),
    /// stamped by `DayPlanTaskStore` on `.user`-sourced writes only. Deliberately NOT set when the
    /// change arrives through the AppleScript scripting commands (`.appleScript` source), so an
    /// external automation polling `recently modified tasks` never loops on its own writes. nil for
    /// tasks stored before this field existed and for AppleScript-created tasks never touched by the user.
    var lastUserModifiedAt: Date?

    /// The backend project the backing to-do is KNOWN to point at (`to-do.project_id`), recorded on
    /// import and after a successful project link. nil = never linked / unknown — with a `project` name
    /// set, that is exactly what `DayPlanProjectRepair` scans for (a project living only on this Mac).
    var projectID: String?
    /// The to-do's tags as last seen from the backend, echoed back on a project link so label tags
    /// survive the upsert. nil = unknown (tags are then omitted so the backend keeps what it has).
    var tags: [DayPlanTaskTag]?
    /// See `TodoProjectFields.hasSyncedExternalProject`; excludes the task from project repair.
    var hasSyncedExternalProject: Bool?
    /// The backing to-do's board column as last seen from the backend (`to-do.custom_status_id`).
    /// nil for from-scratch tasks, for projects without custom columns, and for tasks stored before
    /// this field existed. Only ever used to decide whether a completion needs to move the card.
    var customStatusID: String?
    /// The backing to-do's `icon`, as the backend stores it (an emoji, or the hex code points for
    /// one). nil for from-scratch tasks and for tasks imported before this field existed.
    var icon: String?
    /// How many files the backing to-do had, the last time this Mac looked — which is whenever the
    /// task's details were opened. It is a CACHE, not a sync: `GET /to-do` carries no attachment
    /// count (the `to_do` entity has no attachments relation at all), so the only alternative to this
    /// would be one `GET /to-do/:id/attachments` per row on every render. nil = never looked.
    /// Backend ask to make it authoritative: an `attachment_count` on the to-do list response.
    var attachmentCount: Int?

    /// Who this task's backing to-do is assigned to, and a name to show for them. Optional so tasks
    /// already stored before this existed keep decoding.
    var assigneeId: String?
    var assigneeName: String?

    /// Whether the row should show the paperclip. A task with no backing to-do can have no files at
    /// all, so it never shows one whatever the cached count says.
    var hasAttachments: Bool { sourceTaskId != nil && (attachmentCount ?? 0) > 0 }

    /// Somebody else's work — hidden from this user's Day Plan, and not counted against their day.
    ///
    /// `assigneeId` is filled from the to-do's assignee RELATION (`TodoProjectFields`), never from the
    /// flat `assignee_id` the server does not send (backend#2414) — reading that would leave every
    /// task looking unassigned and this always false.
    var belongsToSomebodyElse: Bool {
        ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: assigneeId,
                                                     meId: appdelegate?.user?.userId)
    }

    /// The task's icon as a displayable emoji, using the same decoding as the To-do list.
    var iconEmoji: String? { EmojiIcon.resolve(icon) }

    /// Sub-tasks as a non-optional list, for convenient counting/rendering.
    var subtaskList: [DayPlanSubtask] { subtasks ?? [] }

    init(id: String = UUID().uuidString, title: String, durationMinutes: Int = 15,
         done: Bool = false, sourceTaskId: String? = nil, blockKey: String? = nil,
         project: String? = nil, notes: String? = nil, subtasks: [DayPlanSubtask]? = nil,
         outcome: Int? = nil, eisenhowerQuadrant: Int? = nil, manuallyPlanned: Bool? = nil,
         lastUserModifiedAt: Date? = nil, projectID: String? = nil, tags: [DayPlanTaskTag]? = nil,
         hasSyncedExternalProject: Bool? = nil, icon: String? = nil, attachmentCount: Int? = nil) {
        self.id = id; self.title = title; self.durationMinutes = durationMinutes
        self.done = done; self.sourceTaskId = sourceTaskId; self.blockKey = blockKey
        self.project = project; self.notes = notes; self.subtasks = subtasks
        self.outcome = outcome; self.eisenhowerQuadrant = eisenhowerQuadrant
        self.manuallyPlanned = manuallyPlanned; self.lastUserModifiedAt = lastUserModifiedAt
        self.projectID = projectID; self.tags = tags; self.hasSyncedExternalProject = hasSyncedExternalProject
        self.icon = icon; self.attachmentCount = attachmentCount
    }

    /// Apply the project-related fields of a backend to-do payload (import / re-hydrate).
    mutating func applyProjectFields(_ fields: TodoProjectFields) {
        projectID = fields.projectID
        tags = fields.tags
        hasSyncedExternalProject = fields.hasSyncedExternalProject
        customStatusID = fields.customStatusID
        // Only when the payload actually carried one: a partial refresh that says nothing about the
        // assignee must not be read as "unassigned" — that is the shape of the bug in backend#2414.
        if let assigneeID = fields.assigneeID {
            self.assigneeId = assigneeID
            self.assigneeName = fields.assigneeName
        }
    }

    /// Emphasise higher outcomes; unset and the lowest (1/5) band use the normal row background.
    static func outcomeColor(_ outcome: Int?) -> NSColor? {
        guard let o = outcome else { return nil }
        switch o {
        case ...3:   return nil              // 1/5: no emphasis
        case 4...6:  return .systemBlue      // 4–6 normal
        case 7...8:  return .systemOrange    // 7–8 high
        default:     return .systemRed       // 9–10 critical
        }
    }
    static func outcomeBandLabel(_ outcome: Int) -> String { ForecastText.outcomeLabel(outcome) }
    /// High-contrast text colour to draw on top of the importance background (white on dark bands,
    /// black on light ones, by luminance). nil when no importance is set.
    static func outcomeForeground(_ outcome: Int?) -> NSColor? {
        guard let bg = outcomeColor(outcome)?.usingColorSpace(.sRGB) else { return nil }
        let lum = 0.299 * bg.redComponent + 0.587 * bg.greenComponent + 0.114 * bg.blueComponent
        return lum > 0.6 ? .black : .white
    }
}

/// Pull a `#project` token out of a typed task title. Two conventions, chosen by the first word
/// right after the `#`:
///   • `#word_word` (contains an underscore) — that single token is the project and can sit anywhere,
///     keeping a title after it: "review notes #Focus_Bear" → ("review notes", "Focus Bear").
///   • otherwise — everything after the (last) `#` to the end of the line is the project, so a
///     multi-word project typed at the END just works: "Testing #Focus Bear" → ("Testing", "Focus Bear").
/// In both cases underscores become spaces and, if the project already exists, its canonical casing
/// is reused (so "#focus bear" reuses "Focus Bear").
func extractProjectToken(_ raw: String, known: [String]) -> (title: String, project: String?) {
    guard let hash = raw.lastIndex(of: "#") else {
        return (raw.trimmingCharacters(in: .whitespaces), nil)
    }
    let afterHash = raw[raw.index(after: hash)...]
    let firstWord = afterHash.prefix { !$0.isWhitespace }
    let candidate: String
    let removeRange: Range<String.Index>
    if firstWord.contains("_") {
        candidate = String(firstWord).replacingOccurrences(of: "_", with: " ")
        removeRange = hash..<raw.index(raw.index(after: hash), offsetBy: firstWord.count)
    } else {
        candidate = String(afterHash).replacingOccurrences(of: "_", with: " ")
        removeRange = hash..<raw.endIndex
    }
    let trimmed = candidate.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return (raw.trimmingCharacters(in: .whitespaces), nil) }   // stray '#'
    let project = known.first { $0.caseInsensitiveCompare(trimmed) == .orderedSame } ?? trimmed
    var title = raw
    title.removeSubrange(removeRange)
    title = title.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
    return (title, project)
}

/// Whether a Day Plan task's importance has to be written to its backing to-do. Pure, so the rule is
/// testable without the store or the network — see `DayPlanOutcomeSyncTests`.
///
/// Only a CHANGE is written, only for a task that has a to-do, and never for a task with no name yet:
/// the upsert echoes the title back, so an empty one would blank the to-do on every device (the same
/// guard `syncProject` has, report 2026-09-09_20-38-22).
enum DayPlanOutcomeSync {
    struct Write: Equatable {
        let todoID: String
        let outcome: Int?
    }

    static func write(previousOutcome: Int?, task: DayPlanTask) -> Write? {
        guard task.outcome != previousOutcome,
              let todoID = task.sourceTaskId,
              !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return Write(todoID: todoID, outcome: task.outcome)
    }
}

/// Pull a `!N` priority token (N = 1...5, the displayed outcome) out of a typed task title and
/// strip it: "draft report !4" → ("draft report", 8 on the wire). Only a standalone `!N` in range counts — a bare
/// `!`, `!0`, or `!6` is left untouched in the title. The last such token wins.
/// `!1`-`!5` sets the task's priority (outcome = twice the digit).
///
/// This was `*1`-`*5` until 2026-09-21. `*` now introduces a DURATION (`*15` = fifteen minutes),
/// which is the shape people reached for first — report 2026-09-21_07-42-02. The two cannot share
/// the prefix: `*5` has to mean one thing, and "five minutes" is the more common intent.
func extractPriorityToken(_ raw: String) -> (title: String, outcome: Int?) {
    let pattern = "(?:^|\\s)!([1-5])(?=\\s|$)"
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return (raw.trimmingCharacters(in: .whitespaces), nil)
    }
    let ns = raw as NSString
    let matches = regex.matches(in: raw, range: NSRange(location: 0, length: ns.length))
    guard let match = matches.last, let outcome = Int(ns.substring(with: match.range(at: 1))) else {
        return (raw.trimmingCharacters(in: .whitespaces), nil)
    }
    var title = ns.replacingCharacters(in: match.range, with: " ")
    title = title.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
    return (title, outcome * 2)
}

/// Seed the to-do player with the Day Plan tasks assigned to the habit being played (allowed-activity
/// habits show the player). Keyed by "habit:<name>" — the same key the Day Plan uses when a task is
/// dragged onto a habit. No-op when the habit has no assigned tasks, so it's safe to call generously.
func prepopulateDayPlanTasks(for habit: habit?) {
    guard let habit = habit, habit.isAllowedActivityHabit, let name = habit.name else { return }
    let tasks = DayPlanTaskStore.shared.tasks(assignedTo: HabitTaskChecklist.blockKey(forHabitNamed: name),
                                              for: Date()).filter { !$0.done }
    guard !tasks.isEmpty else { return }
    let payload: [[String: Any]] = tasks.map { t in
        // Use the source to-do id where known so the player doesn't duplicate a task already loaded.
        ["id": t.sourceTaskId ?? t.id, "title": t.title, "duration": max(60, t.durationMinutes * 60)]
    }
    taskPlayerVcObj?.prepopulateTasks(payload)
}

/// Who originated a task write. `.user` stamps `DayPlanTask.lastUserModifiedAt`; `.appleScript`
/// deliberately does not, so an external automation polling `recently modified tasks` (the AppleScript
/// scripting command) never loops on its own writes. See `DayPlanTask.lastUserModifiedAt`.
enum TaskEditSource {
    case user
    case appleScript
}

/// Per-day local store for Day Plan tasks, persisted in UserDefaults as `{ "yyyy-MM-dd": [task] }`.
final class DayPlanTaskStore {
    static let shared = DayPlanTaskStore()

    /// Posted after a change made on ANOTHER screen (the To-do list) lands in this store, so a Day
    /// Plan that happens to be open redraws instead of waiting for its next reload.
    static let forecastSnapshotDidChange = Notification.Name("io.focusbear.dayPlanForecastSnapshotDidChange")
    static let tasksDidChangeExternally = Notification.Name("io.focusbear.dayPlanTasksDidChangeExternally")

    private var completionObserver: NSObjectProtocol?

    private init() {
        load()
        // A to-do ticked in the native To-do list is the same task the Day Plan shows; mirror it here.
        completionObserver = TodoCompletionBus.observe { [weak self] change in
            self?.applyExternalCompletion(todoID: change.todoID, completed: change.completed)
        }
    }

    /// An isolated in-memory fixture, without loading the user's saved tasks or observing live edits.
    init(mockTasks: [String: [DayPlanTask]]) {
        precondition(Self.mockMode)
        byDay = mockTasks
    }

    /// A completion announced by another screen: tick every local copy of that to-do and tell an open
    /// Day Plan to redraw. Writes storage directly rather than going through `update(_:for:)` because
    /// the originating screen has already sent the status to the backend — routing it through the
    /// normal path would fire a second, redundant `PUT /to-do`. No-ops when the copies already carry
    /// the new state, so the Day Plan's OWN completions (which post too) don't come back around.
    private func applyExternalCompletion(todoID: String, completed: Bool) {
        guard !Self.mockMode,
              let updated = TodoCompletionMapping.applying(completed: completed, toSourceTaskId: todoID, in: byDay) else { return }
        byDay = updated
        save()
        NotificationCenter.default.post(name: DayPlanTaskStore.tasksDidChangeExternally, object: nil)
    }

    /// Mockup mode: in-memory only — never persists to UserDefaults and never rolls tasks over, so a
    /// mock render can't pollute or move the user's real data. Only ever set true by the DEBUG-only
    /// DayPlanMockup renderer, so in Release these guards are inert.
    static var mockMode = false

    /// Replace a day's tasks with mock data (mockup renderer only).
    func loadMock(_ tasks: [DayPlanTask], for date: Date) {
        byDay[dayKey(date)] = tasks
    }

    private let key = "dayPlanTasksByDay"
    /// One-time flag: the cross-day snooze-clone de-dupe (see `dedupeSnoozeClones`) has run for this install.
    private let snoozeCloneDedupeKey = "dayPlanSnoozeCloneDedupeDone"
    private var byDay: [String: [DayPlanTask]] = [:]
    /// Local ids of from-scratch tasks currently having a backend to-do minted for them, so a rapid
    /// second edit doesn't mint a duplicate before the first create returns.
    private var mintingTaskIds = Set<String>()
    /// Local task id → what to run once that task has a backing to-do, or is known not to be getting
    /// one. See `whenBackedByTodo`.
    private var pendingMintCallbacks: [String: [(String?) -> Void]] = [:]

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.calendar = Calendar.current; return f
    }()
    private func dayKey(_ date: Date) -> String { Self.dayFormatter.string(from: date) }

    /// Read-only snapshot for forecasting. Opening a forecast must not trigger rollover writes.
    func forecastSnapshot() -> [(date: Date, task: DayPlanTask)] {
        byDay.keys.sorted().flatMap { key -> [(date: Date, task: DayPlanTask)] in
            guard let date = Self.dayFormatter.date(from: key) else { return [] }
            // Same rule as the day itself: a colleague's task is not work this user has to fit in.
            return (byDay[key] ?? []).filter { !$0.belongsToSomebodyElse }.map { (date: date, task: $0) }
        }
    }

    /// The day's tasks as the user should see them — somebody else's work filtered out.
    ///
    /// The filter lives HERE, at the one gateway every consumer reads through, rather than at each
    /// point of display. The panel, the timeline and the capacity model all come through this call, so
    /// filtering once is what makes them agree: a task assigned to a colleague cannot show in one and
    /// be counted in another. (`remainingMins`, which drives "not enough time for all tasks", is
    /// summed from this list.) Two views of a day disagreeing about what occupies it is the shape of
    /// the offline-completion bug found on this machine the same day.
    ///
    /// It is a filter, not a deletion: the task stays in the store and keeps syncing, so reassigning
    /// it back puts it straight back on the day with nothing to restore.
    func tasks(for date: Date) -> [DayPlanTask] {
        allTasks(for: date).filter { !$0.belongsToSomebodyElse }
    }

    /// Every task stored for the day, including ones assigned to somebody else.
    ///
    /// For the store's own bookkeeping only — de-duplication on import above all. `contains` asking
    /// the filtered list would answer "not here" for a colleague's task and re-add it on every sync.
    func allTasks(for date: Date) -> [DayPlanTask] {
        rollOverIfNeeded()
        return byDay[dayKey(date)] ?? []
    }

    private func storageDay(for id: String, preferred date: Date) -> String {
        let preferred = dayKey(date)
        if byDay[preferred]?.contains(where: { $0.id == id }) == true { return preferred }
        return byDay.keys.sorted().first { byDay[$0]?.contains(where: { $0.id == id }) == true } ?? preferred
    }

    /// Carry incomplete tasks forward from past days to today, once per day. Completed tasks stay in
    /// their original day (history); rolled tasks lose their time-box (yesterday's blocks are gone)
    /// and land under "Not yet time boxed". Idempotent — guarded by a stored last-rollover day.
    private let lastRolloverKey = "dayPlanLastRolloverDay"
    // Re-entrancy guard: the dedup check below calls contains() -> tasks(for:) -> rollOverIfNeeded(),
    // and the once-per-day flag is only written at the end, so without this the midnight rollover
    // recurses until the stack overflows (crash 2026-07-06). Break the cycle explicitly.
    private var isRollingOver = false
    func rollOverIfNeeded() {
        if Self.mockMode { return }
        if isRollingOver { return }
        let todayKey = dayKey(Date())
        if UserDefaults.standard.string(forKey: lastRolloverKey) == todayKey { return }
        isRollingOver = true
        defer { isRollingOver = false }
        var changed = false
        for (dayK, tasks) in byDay where dayK < todayKey {   // yyyy-MM-dd sorts chronologically
            // Don't roll tasks the user deliberately back-dated (manuallyPlanned) — leave them put.
            let incomplete = tasks.filter { !$0.done && $0.manuallyPlanned != true }
            guard !incomplete.isEmpty else { continue }
            for var t in incomplete {
                // Don't duplicate an imported to-do that's already on today.
                if let sid = t.sourceTaskId, byDay[todayKey]?.contains(where: { $0.sourceTaskId == sid }) == true { continue }
                t.blockKey = nil                       // re-plan onto today, untimed
                byDay[todayKey, default: []].append(t)
            }
            byDay[dayK]?.removeAll { !$0.done && $0.manuallyPlanned != true }   // remove only the moved ones
            changed = true
        }
        UserDefaults.standard.set(todayKey, forKey: lastRolloverKey)
        if changed { save() }
    }

    func add(_ task: DayPlanTask, for date: Date, source: TaskEditSource = .user) {
        var task = task
        // A user-made add counts as a user modification; an AppleScript-made one deliberately does not,
        // so `recently modified tasks` never surfaces the automation's own creations.
        if source == .user { task.lastUserModifiedAt = Date() }
        // Never add the same imported to-do twice on a day.
        if let sid = task.sourceTaskId, contains(sourceTaskId: sid, for: date) { return }
        byDay[dayKey(date), default: []].append(task); save()
        // #2148: a Day Plan task backed by a to-do is planned via `planned_date` (the pointer model);
        // this makes it show on GET /day-plan/day and hydrate on other devices. From-scratch tasks (no
        // sourceTaskId) stay local-only — the pointer model has nowhere to put them without minting a to-do.
        if let sid = task.sourceTaskId {
            DayPlanSync.shared.setTodoPlanned(todoID: sid, title: task.title, quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                              plannedDate: date, blockKey: task.blockKey, order: nil)
        }
    }

    /// Where the backing to-do's board column should end up after this completion flip. A task with
    /// no project, a project we haven't loaded, or a project with no custom columns is left alone.
    func columnWrite(for task: DayPlanTask, completed: Bool) -> ToDoCompletionState.ColumnWrite {
        guard let projectID = task.projectID, let columns = customStatusesByProject[projectID] else { return .leaveAlone }
        return ToDoCompletionState.columnWrite(completed: completed, currentColumnID: task.customStatusID,
                                               customStatuses: columns)
    }

    func update(_ task: DayPlanTask, for date: Date, source: TaskEditSource = .user) {
        let k = storageDay(for: task.id, preferred: date)
        guard let i = byDay[k]?.firstIndex(where: { $0.id == task.id }) else { return }
        let wasDone = byDay[k]![i].done
        let oldSubtasks = byDay[k]![i].subtasks
        let oldProject = byDay[k]![i].project
        let oldOutcome = byDay[k]![i].outcome
        var task = task
        if k != dayKey(date) { task.blockKey = byDay[k]?[i].blockKey }
        // Stamp the user's edit time so `recently modified tasks` can report it; AppleScript-sourced
        // writes leave it untouched so the automation never sees its own changes.
        if source == .user { task.lastUserModifiedAt = Date() }
        // The recorded link (and its mirrored tag) are for the OLD project; drop them so a failed push
        // below leaves the task eligible for `DayPlanProjectRepair` instead of looking synced.
        let projectChanged = task.project != oldProject
        if projectChanged, let oldProjectID = byDay[k]![i].projectID {
            task.tags = task.tags?.filter { $0.id != oldProjectID }
        }
        if projectChanged { task.projectID = nil }
        byDay[k]?[i] = task; save()
        // #2148: reflect a completion flip onto the underlying to-do's status so web/mobile update.
        // The upsert replaces the row, so the quadrant has to be echoed back with it. This used to be
        // gated on already knowing the quadrant, which meant a task stored before that field existed (or
        // imported by a path that never set it) ticked off locally and stayed OPEN on web and mobile —
        // silently, which is the worst version. The quadrant isn't used anywhere in the product, so
        // defaulting it is the right trade: a synced completion beats a preserved value nobody reads.
        if task.done != wasDone, let sid = task.sourceTaskId {
            // The card has to move as well as the tick: a finished task left in an open column reads
            // as outstanding on the kanban, on web and on mobile (report 2026-09-15_17-41-45). Both
            // go in the one PUT, and the local copy follows so a second tick doesn't re-send it.
            let column = columnWrite(for: task, completed: task.done)
            DayPlanSync.shared.setTodoStatus(todoID: sid, title: task.title,
                                             quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                             completed: task.done, column: column)
            if case .move(let columnID) = column {
                task.customStatusID = columnID
                byDay[k]?[i].customStatusID = columnID
                save()
            }
        }
        // …and tell the rest of the app, so the same to-do ticks in the native To-do list right away.
        // Announced even without a quadrant (when the status push above is skipped): the in-app views
        // must still agree, whatever the backend ends up knowing.
        if task.done != wasDone, let sid = task.sourceTaskId {
            TodoCompletionBus.post(todoID: sid, completed: task.done)
        }
        // Reflect an edited checklist onto the backing to-do's `subtasks` so web/mobile see them
        // (they were previously kept only in local UserDefaults, invisible to other devices). Only
        // on an actual change, and only when we can echo title + quadrant back to avoid clobbering.
        if task.subtasks != oldSubtasks, let sid = task.sourceTaskId {
            DayPlanSync.shared.setTodoSubtasks(todoID: sid, title: task.title,
                                               quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                               subtasks: task.subtaskList)
        }
        // A `#project` picked or created here used to stay in local UserDefaults only — the to-do's
        // `project_id` never changed, so web/mobile never saw the project. Push it (creating the
        // backend project when the name is new); from-scratch tasks get it at mint time instead.
        if projectChanged { syncProject(of: task) }
        // Importance was local-only: a typed `!5` (or the editor's importance menu) tinted the row, and
        // the next to-do refresh (`mergeDueTodos`) copied the server's untouched `outcome` back over it,
        // so the row went white again (report 2026-09-24_20-33-35).
        if let write = DayPlanOutcomeSync.write(previousOutcome: oldOutcome, task: task) {
            DayPlanSync.shared.setTodoOutcome(todoID: write.todoID, title: task.title,
                                              quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                              outcome: write.outcome)
        }
    }

    /// The ONE route by which a task's `project` reaches its backing to-do. Every entry path — a typed
    /// `#token`, a suggestion pick, the editor's project field, a drag onto another group, AppleScript,
    /// the mint of a from-scratch task and `DayPlanProjectRepair` — ends here. Resolves the name to a
    /// backend project (creating it when new), `PUT`s the to-do, and records the linked `projectID` so
    /// the repair pass knows the task is done. No-op without a to-do (the mint path calls back in once
    /// there is one). A missing quadrant is NOT a reason to skip: the upsert has to echo one back, but
    /// the product doesn't use the value, so a task that never had one falls back to the neutral corner
    /// rather than silently never syncing its project. On failure (offline, 4xx) `projectID` stays nil,
    /// so the repair pass retries on its next run. A task with no name yet is NOT pushed either: the
    /// upsert echoes the title back, so an empty one would clear the to-do's name on every device —
    /// which is how a `#project` typed on its own used to blank a real task (report
    /// 2026-09-09_20-38-22), and the same reason `TodoColumnRepair` skips titleless rows. The project
    /// is kept locally and `projectID` stays nil, so the repair pass pushes it once there is a name.
    func syncProject(of task: DayPlanTask, completion: ((_ succeeded: Bool) -> Void)? = nil) {
        guard let sid = task.sourceTaskId,
              !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { completion?(false); return }
        let quadrant = task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant
        DayPlanSync.shared.setTodoProject(todoID: sid, title: task.title, quadrant: quadrant,
                                          projectName: task.project, labelTags: task.tags) { [weak self] outcome in
            guard let self = self else { completion?(false); return }
            switch outcome {
            case .linked(let projectID):
                self.markProjectLinked(taskID: task.id, projectID: projectID, projectName: task.project)
                completion?(true)
            case .cleared:
                self.markProjectLinked(taskID: task.id, projectID: nil, projectName: nil)
                completion?(true)
            case .failed:
                completion?(false)
            }
        }
    }

    /// Record a confirmed to-do ↔ project link (or a confirmed clear, `projectID` nil) on the task
    /// wherever it now lives — it may have moved days while the request was in flight. Also mirrors the
    /// tag list the backend now holds (see `DayPlanProjectSyncRules.ensureProjectTag`).
    private func markProjectLinked(taskID: String, projectID: String?, projectName: String?) {
        for (day, tasks) in byDay {
            guard let i = tasks.firstIndex(where: { $0.id == taskID }) else { continue }
            byDay[day]?[i].projectID = projectID
            if let tags = tasks[i].tags {
                byDay[day]?[i].tags = DayPlanProjectSyncRules.ensureProjectTag(tags, projectID: projectID,
                                                                               projectName: projectName)
            }
            save()
            return
        }
    }

    /// Point every Day Plan task that still names a merged-away project at the project it was merged
    /// into. See `DayPlanProjectSyncRules.followingMerge` for why leaving the old name behind
    /// re-creates the archived project on the next sync.
    func followProjectMerge(from source: String, to target: String, targetID: String?) {
        let updated = DayPlanProjectSyncRules.followingMerge(byDay, from: source, to: target, targetID: targetID)
        guard updated != byDay else { return }
        byDay = updated
        save()
    }

    /// Projects this user deleted. Remembered across launches because the backend only soft-deletes:
    /// the project's to-dos keep pointing at it, so every later hydrate would bring its name back and
    /// the repair pass would create it again (#2680).
    private(set) var deletedProjectIDs: Set<String> = DayPlanTaskStore.mockMode ? []
        : Set(UserDefaults.standard.stringArray(forKey: DayPlanTaskStore.deletedProjectIDsKey) ?? [])
    private static let deletedProjectIDsKey = "dayPlanDeletedProjectIDs"

    /// A project was deleted (`DELETE /projects/:id` succeeded): forget it, and take it off every Day
    /// Plan task still naming it. See `DayPlanProjectSyncRules.followingDeletion`.
    func followProjectDeletion(id: String, name: String) {
        remoteProjectsByID[id] = nil
        deletedProjectIDs.insert(id)
        if !Self.mockMode {
            UserDefaults.standard.set(Array(deletedProjectIDs), forKey: Self.deletedProjectIDsKey)
        }
        let updated = DayPlanProjectSyncRules.followingDeletion(byDay, projectID: id, name: name)
        guard updated != byDay else { return }
        byDay = updated
        save()
        NotificationCenter.default.post(name: Self.tasksDidChangeExternally, object: nil)
    }

    /// Call when a task's name is FINALIZED (Enter/blur), not on every keystroke. For a from-scratch
    /// task this mints a backend to-do (named after the whole title, not the first character typed);
    /// for an already-synced task it pushes the renamed title to its to-do so the new name syncs to
    /// other devices too.
    func syncNameOnCommit(_ task: DayPlanTask, on date: Date) {
        guard !Self.mockMode,
              !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let sid = task.sourceTaskId {
            DayPlanSync.shared.setTodoTitle(todoID: sid, title: task.title, quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant)
        } else {
            mintTodoIfNeeded(for: task, on: date)
        }
    }

    /// Run `action` once this local task has a backing to-do id — with nil if the mint failed.
    ///
    /// The menu's quick-add needs it: an image pasted while typing a task name has nowhere to go until
    /// the task exists server-side (attachments hang off `/to-do/:id`), and the mint is a round trip.
    /// Fires immediately for a task that is already backed, so the caller has one path either way, and
    /// always fires exactly once — a caller holding a pasted picture has to be told when to give up on
    /// it rather than waiting for a callback that never comes.
    func whenBackedByTodo(localId: String, _ action: @escaping (String?) -> Void) {
        if let existing = byDay.values.flatMap({ $0 }).first(where: { $0.id == localId })?.sourceTaskId {
            action(existing)
            return
        }
        pendingMintCallbacks[localId, default: []].append(action)
    }

    /// Hand the outcome to everyone that asked for it, once — nil when the to-do could not be created.
    private func announceMint(localId: String, todoId: String?) {
        guard let waiting = pendingMintCallbacks.removeValue(forKey: localId) else { return }
        waiting.forEach { $0(todoId) }
    }

    /// Give a from-scratch task a backend to-do so it syncs across devices (the pointer model can only
    /// sync to-do-backed tasks). Mints once — on the first non-empty title — via `PUT /to-do` (create),
    /// then backfills the new id as `sourceTaskId` and plans it (`PUT /to-do` upsert). Best-effort: on a
    /// failed create (e.g. offline) the task stays local and we retry on the next edit. No-op for tasks
    /// already backed by a to-do, blank rows, or those with a mint in kflight.
    private func mintTodoIfNeeded(for task: DayPlanTask, on date: Date) {
        guard task.sourceTaskId == nil,
              !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !mintingTaskIds.contains(task.id) else { return }
        mintingTaskIds.insert(task.id)
        let localId = task.id
        let quadrant = task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant
        // The /to-do API requires a real Date for due_date (empty string → 400 "due_date must be a Date
        // instance"), so use the day the task is planned on, ISO-8601 UTC like the other addTask callers.
        let dueDate = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        allApiObject.addTask(title: task.title, details: "", eisenhowerQuadrant: quadrant,
                             dueDate: dueDate, objective: "", tags: []) { [weak self] ok, json in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.mintingTaskIds.remove(localId)
                guard ok, let newId = json?["id"] as? String else {
                    self.announceMint(localId: localId, todoId: nil); return
                }
                let k = self.dayKey(date)
                // The row may have moved/been deleted, or been imported over, while we waited.
                guard let idx = self.byDay[k]?.firstIndex(where: { $0.id == localId }),
                      self.byDay[k]?[idx].sourceTaskId == nil else {
                    // Already backed by an import, or gone. Either way the waiters get an answer.
                    self.announceMint(localId: localId,
                                      todoId: self.byDay[k]?.first { $0.id == localId }?.sourceTaskId)
                    return
                }
                self.byDay[k]?[idx].sourceTaskId = newId
                self.byDay[k]?[idx].eisenhowerQuadrant = quadrant
                self.byDay[k]?[idx].tags = []   // a freshly minted to-do has no tags yet
                self.save()
                let planned = self.byDay[k]![idx]
                DayPlanSync.shared.setTodoPlanned(todoID: newId, title: planned.title, quadrant: quadrant,
                                                  plannedDate: date, blockKey: planned.blockKey, order: nil)
                // A `#project` given before the task was synced (typed, picked, or from the group's +)
                // now has a to-do to attach to — same route as every other project change.
                if let project = planned.project, !project.isEmpty { self.syncProject(of: planned) }
                // A from-scratch task can already carry subtasks (added in the modal before it was
                // synced); the create DTO above didn't include them, so push them now that it has a
                // backing to-do, else they'd stay local-only and never reach web/mobile.
                if !planned.subtaskList.isEmpty {
                    DayPlanSync.shared.setTodoSubtasks(todoID: newId, title: planned.title,
                                                       quadrant: quadrant, subtasks: planned.subtaskList)
                }
                // …and so can an importance (`!5` typed with the name): the create DTO has no outcome.
                if let write = DayPlanOutcomeSync.write(previousOutcome: nil, task: planned) {
                    DayPlanSync.shared.setTodoOutcome(todoID: write.todoID, title: planned.title,
                                                      quadrant: quadrant, outcome: write.outcome)
                }
                // Last, so nothing a waiter does can invalidate the row this block is still reading.
                self.announceMint(localId: localId, todoId: newId)
            }
        }
    }

    /// Move a placed task from one day to another, keeping the same row.
    ///
    /// The reschedule sheet's only way of putting a task somewhere else: it writes due dates, and a
    /// due date does not move anything (`DayPlanRepositioning`). Returns whether anything moved, so
    /// the caller can log a real move rather than a hopeful one.
    ///
    /// **The block key is dropped.** A key names one occurrence on one day — "habit:📞 Cold calls" is
    /// Friday's cold-calls block, an `event:` key is one calendar occurrence — so carrying it to
    /// another day would pin the task to a block that is not there, and the day's absorption
    /// arithmetic would credit it for time nothing is paying for. The task lands untimed, exactly as
    /// `rollOverIfNeeded` lands rolled work.
    @discardableResult
    func move(taskID: String, from: Date, to: Date) -> Bool {
        let source = storageDay(for: taskID, preferred: from), destination = dayKey(to)
        guard source != destination,
              let index = byDay[source]?.firstIndex(where: { $0.id == taskID }) else { return false }
        var task = byDay[source]!.remove(at: index)
        task.blockKey = nil
        byDay[destination, default: []].append(task)
        save()
        // #2148 pointer model: the backend knows a Day Plan placement only as the to-do's
        // `planned_date`, so the move has to be pushed the same way `add` pushes a placement — without
        // it the task returns to its old day on the next hydrate from another device.
        if !Self.mockMode, let sid = task.sourceTaskId {
            DayPlanSync.shared.setTodoPlanned(todoID: sid, title: task.title,
                                              quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                              plannedDate: to, blockKey: nil, order: nil)
        }
        // `save()` already announces the forecast snapshot; this is the other half — an open Day Plan
        // redraws instead of still showing the task on the day it has just left.
        NotificationCenter.default.post(name: DayPlanTaskStore.tasksDidChangeExternally, object: nil)
        return true
    }

    func delete(id: String, for date: Date) {
        let k = storageDay(for: id, preferred: date)
        let removed = byDay[k]?.first { $0.id == id }
        byDay[k]?.removeAll { $0.id == id }; save()
        // Removing a to-do-backed task clears its due date and legacy planned_date; the
        // to-do itself is kept. From-scratch tasks have no backend row to clear.
        if let sid = removed?.sourceTaskId, let removed = removed {
            DayPlanSync.shared.setTodoPlanned(todoID: sid, title: removed.title,
                                              quadrant: removed.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                              plannedDate: nil, blockKey: nil, order: nil)
        }
    }

    /// Pull the day's planned to-dos from the backend and reconcile them into the local store, so a
    /// task ticked (or planned) on another device shows correctly here (#2148 follow-up: the cross-
    /// device *read*). `GET /day-plan/day/:day` returns `tasks: ToDo[]` — the to-dos whose
    /// `planned_date` is this day. Matching is by `sourceTaskId == to-do id`; backend `status` wins
    /// for the `done` flag; a planned to-do we don't have locally is brought onto the Day Plan.
    /// Local from-scratch tasks (no sourceTaskId) are never touched. Returns true if anything changed.
    /// `onComplete(fetched:)` reports whether the backend actually returned data (false when the request
    /// was skipped because we're not authed yet, e.g. right after launch) so the caller can retry rather
    /// than treat a no-op as a successful hydrate.
    func loadAndHydrate(for date: Date, onChange: @escaping () -> Void, onComplete: ((_ fetched: Bool) -> Void)? = nil) {
        DayPlanSync.shared.loadDay(date) { [weak self] _, raw in
            guard let self = self, let raw = raw else { onComplete?(false); return }
            if date < Calendar.current.startOfDay(for: Date()), self.hydrate(fromDay: raw, for: date) { onChange() }
            onComplete?(true)
        }
    }

    /// Map a backend to-do's `subtasks` (canonical `{ name, is_completed }` shape) into local
    /// `DayPlanSubtask`s. Returns nil when the to-do has no (valid) subtasks, matching the "absent =
    /// nil" convention on `DayPlanTask.subtasks`. Skips entries with an empty name.
    private func mapSubtasks(from obj: [String: Any]) -> [DayPlanSubtask]? {
        guard let raw = obj["subtasks"] as? [[String: Any]] else { return nil }
        let mapped: [DayPlanSubtask] = raw.compactMap { entry in
            guard let name = entry["name"] as? String,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return DayPlanSubtask(title: name, done: (entry["is_completed"] as? Bool) ?? false)
        }
        return mapped.isEmpty ? nil : mapped
    }

    @discardableResult
    func hydrate(fromDay raw: NSDictionary, for date: Date) -> Bool {
        guard let arr = raw["tasks"] as? [[String: Any]] else { return false }
        let k = dayKey(date)
        var list = byDay[k] ?? []
        var indexBySource = [String: Int]()
        for (i, t) in list.enumerated() { if let s = t.sourceTaskId { indexBySource[s] = i } }
        // A to-do lives on exactly one day (the pointer model), so never re-add one that already sits on
        // ANOTHER day locally. The backend's `planned_date` can lag the local placement — a snooze/move
        // repoints the task instantly but its `setTodoPlanned` push is fire-and-forget, and
        // `rolloverIncompleteTasks` carries a task forward without touching the backend — so a
        // GET /day-plan/day for the stale day still returns it. Appending it here (the `else` branch below
        // only dedups WITHIN `k`) is what stranded a duplicate on both the origin and the target day.
        // mergeDueTodos guards the same way via its cross-day `placed` set; hydrate lacked it. A
        // *completed* copy on a PAST day is excluded from that set — it's a historical record the
        // store never prunes, not a live placement, and letting it veto would strand the to-do.
        let placedOnOtherDay = Set(byDay.filter { $0.key != k }.values.flatMap { $0 }.filter { !$0.done }.compactMap(\.sourceTaskId))
        var changed = false
        for obj in arr {
            guard let id = obj["id"] as? String else { continue }
            let done = Self.isFinished(status: obj["status"] as? String,
                                       customStatusId: obj["custom_status_id"] as? String,
                                       completingStatusIds: completingStatusIds)
            if let idx = indexBySource[id] {
                // Upgrade-only: the backend may mark a task done (e.g. completed on another device),
                // but must NOT revert a local completion. The completion reflect (PUT /to-do status)
                // can lag or be skipped — e.g. a task imported before we captured its
                // eisenhower_quadrant — and clobbering local `done` here made ticked tasks reappear
                // un-ticked on the next Day Plan open (reported 2026-07-08).
                if done, !list[idx].done { list[idx].done = true; changed = true }
                // Pull a rename made on another device — the backend to-do's title is the source of
                // truth for a synced task, so reflect it locally (a local rename was already pushed via
                // setTodoTitle, so the backend is up to date by the next hydrate). Unlike `done` this
                // is last-write-wins, not upgrade-only, since a title has no "greater" value.
                if let backendTitle = obj["title"] as? String,
                   !backendTitle.isEmpty, backendTitle != list[idx].title {
                    list[idx].title = backendTitle; changed = true
                }
                // Pull subtasks set on another device onto a task that has none locally. Fill-when-
                // empty (not last-write-wins) so a local checklist that hasn't finished syncing isn't
                // clobbered — the local edit was already pushed via setTodoSubtasks, so by the next
                // hydrate the backend carries it and both sides agree.
                if list[idx].subtaskList.isEmpty, let backendSubs = mapSubtasks(from: obj) {
                    list[idx].subtasks = backendSubs; changed = true
                }
                // The icon is display-only, so the backend's value simply wins — including being
                // cleared, which is how the user removes an emoji on another device.
                if obj.keys.contains("icon") {
                    let icon = (obj["icon"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                    if list[idx].icon != icon { list[idx].icon = icon; changed = true }
                }
                // Backfill the quadrant on a task imported before it was captured, so its project /
                // status / subtask pushes stop being skipped for fear of clobbering it.
                if list[idx].eisenhowerQuadrant == nil, let quadrant = obj["eisenhower_quadrant"] as? Int {
                    list[idx].eisenhowerQuadrant = quadrant; changed = true
                }
                // The backend is the truth for what the to-do is linked to: refresh the recorded
                // `project_id` / tags so `DayPlanProjectRepair` neither re-links a task that is already
                // fine nor trusts a link that was undone on another device.
                if obj.keys.contains("project_id") || obj.keys.contains("synced_project_id") || obj.keys.contains("tags") {
                    let fields = TodoProjectFields(todo: obj)
                    var refreshed = list[idx]
                    refreshed.applyProjectFields(fields)
                    // Keep the display name consistent with a refreshed/cleared backend link;
                    // otherwise Focus Start can match the stale name as a legacy project default.
                    // A locally typed name with no known link still belongs to project repair.
                    if list[idx].projectID != nil || list[idx].hasSyncedExternalProject == true ||
                        fields.projectID != nil || fields.hasSyncedExternalProject {
                        refreshed.project = projectName(for: fields)
                    }
                    if refreshed != list[idx] { list[idx] = refreshed; changed = true }
                }
            } else if !placedOnOtherDay.contains(id) {
                let title = (obj["title"] as? String) ?? "Task"
                let minutes = TodoFieldParsing.durationMinutes(obj["duration"])
                let quadrant = obj["eisenhower_quadrant"] as? Int
                let blockKey = obj["planned_block_key"] as? String
                let fields = TodoProjectFields(todo: obj)
                var imported = DayPlanTask(title: title, durationMinutes: minutes, done: done,
                                           sourceTaskId: id, blockKey: blockKey, project: projectName(for: fields),
                                           subtasks: mapSubtasks(from: obj),
                                           eisenhowerQuadrant: quadrant, projectID: fields.projectID,
                                           tags: fields.tags, hasSyncedExternalProject: fields.hasSyncedExternalProject,
                                           icon: obj["icon"] as? String)
                imported.assigneeId = fields.assigneeID
                imported.assigneeName = fields.assigneeName
                list.append(imported)
                changed = true
            }
        }
        if changed { byDay[k] = list; save() }
        return changed
    }

    /// Reconcile a complete unfinished catalogue by due date. A planned_date pointer is legacy
    /// metadata, never an independent date that can hide a due task or keep a postponed task here.
    private var isLoadingDueTasks = false
    private var storageRevision = 0
    private var dueTaskCallbacks: [() -> Void] = []

    func loadAndMergeDueTodos(for date: Date, onChange: @escaping () -> Void) {
        guard !Self.mockMode, let account = appdelegate?.user?.userId, !account.isEmpty else { return }
        dueTaskCallbacks.append(onChange)
        guard !isLoadingDueTasks else { return }
        isLoadingDueTasks = true
        let revision = storageRevision
        var catalogue = LocalForecastTaskCatalogue(completingStatusIds: completingStatusIds)
        func finish(_ rows: [ToDoTask]?) {
            isLoadingDueTasks = false
            let callbacks = dueTaskCallbacks
            dueTaskCallbacks.removeAll()
            guard appdelegate?.user?.userId == account, storageRevision == revision, let rows = rows,
                  let data = try? JSONEncoder().encode(rows),
                  let objects = try? JSONSerialization.jsonObject(with: data) as? [NSDictionary] else { return }
            if mergeDueTodos(objects, into: Date()) { callbacks.forEach { $0() } }
        }
        func read(_ page: Int) {
            allApiObject.getForecastTasksPage(page: page, expectedAccountID: account) { response in
                DispatchQueue.main.async {
                    guard appdelegate?.user?.userId == account, let response = response,
                          catalogue.append(response, page: page) else { finish(nil); return }
                    if catalogue.isComplete { finish(catalogue.tasks) }
                    else if page < 400 { read(page + 1) }
                    else { finish(nil) }
                }
            }
        }
        read(1)
    }

    @discardableResult
    func mergeDueTodos(_ todos: [NSDictionary], into date: Date) -> Bool {
        let todayKey = dayKey(date)
        let prior = byDay.keys.sorted().reversed().flatMap { day in
            (byDay[day] ?? []).map { (day, $0) }
        }
        let rows: [(due: String, task: DayPlanTask)] = todos.compactMap { todo in
            guard let id = todo["id"] as? String,
                  let due = DayPlanDueProjection.canonicalDay(dueDate: todo["due_date"] as? String, today: todayKey),
                  !Self.isFinished(status: todo["status"] as? String,
                                   customStatusId: todo["custom_status_id"] as? String,
                                   completingStatusIds: completingStatusIds) else { return nil }
            let fields = TodoProjectFields(todo: todo)
            guard !ToDoAssigneeChoices.isAssignedToSomebodyElse(assigneeId: fields.assigneeID,
                                                               meId: appdelegate?.user?.userId) else { return nil }
            let old = prior.first { $0.1.sourceTaskId == id && !$0.1.done }
            var task = old?.1 ?? DayPlanTask(title: todo["title"] as? String ?? "", sourceTaskId: id)
            task.title = todo["title"] as? String ?? task.title
            if old == nil { task.durationMinutes = TodoFieldParsing.durationMinutes(todo["duration"]) }
            task.done = false
            task.icon = todo["icon"] as? String
            task.subtasks = mapSubtasks(from: todo as? [String: Any] ?? [:])
            task.manuallyPlanned = nil
            if old?.0 != due {
                task.blockKey = ToDoDates.parse(todo["planned_date"] as? String).flatMap {
                    dayKey($0) == due ? todo["planned_block_key"] as? String : nil
                }
            }
            task.eisenhowerQuadrant = todo["eisenhower_quadrant"] as? Int
            task.outcome = todo["outcome"] as? Int
            task.applyProjectFields(fields)
            task.project = projectName(for: fields)
            task.assigneeId = fields.assigneeID
            task.assigneeName = fields.assigneeName
            return (due, task)
        }
        let reconciled = DayPlanDueProjection.reconcile(byDay, rows: rows, today: todayKey)
        guard reconciled != byDay else { return false }
        byDay = reconciled
        save()
        return true
    }

    /// A successful due-date edit from the To-do screen updates the open Day Plan immediately.
    /// This mirrors an acknowledged write; it must not issue another backend write.
    func applyDueDate(todoID: String, dueDate: String?) {
        let copies = byDay.keys.sorted().flatMap { day in
            (byDay[day] ?? []).filter { $0.sourceTaskId == todoID && !$0.done }
        }
        guard var task = copies.first else { return }
        for day in Array(byDay.keys) {
            byDay[day]?.removeAll { $0.sourceTaskId == todoID && !$0.done }
        }
        if let day = DayPlanDueProjection.canonicalDay(dueDate: dueDate, today: dayKey(Date())) {
            task.blockKey = nil
            task.manuallyPlanned = nil
            byDay[day, default: []].append(task)
        }
        save()
        NotificationCenter.default.post(name: Self.tasksDidChangeExternally, object: nil)
    }

    /// True if the to-do item is already on the given day (so the picker can avoid duplicates).
    func contains(sourceTaskId: String, for date: Date) -> Bool {
        allTasks(for: date).contains { $0.sourceTaskId == sourceTaskId }
    }

    /// The Day Plan copy of a backend to-do and the day it sits on, if it is planned at all — so a snooze
    /// from the To-do list can move it the way the Day Plan does. A to-do lives on at most one day.
    func plannedCopy(ofSourceTask sourceTaskId: String) -> (day: Date, task: DayPlanTask)? {
        rollOverIfNeeded()
        for (dayKey, tasks) in byDay {
            guard let task = tasks.first(where: { $0.sourceTaskId == sourceTaskId }),
                  let day = Self.dayFormatter.date(from: dayKey) else { continue }
            return (day, task)
        }
        return nil
    }

    /// Tasks not nested under any schedule block (shown in the side panel).
    func unassignedTasks(for date: Date) -> [DayPlanTask] {
        tasks(for: date).filter { $0.blockKey == nil }
    }
    /// Tasks nested under a given schedule block (shown under that block's card).
    func tasks(assignedTo key: String, for date: Date) -> [DayPlanTask] {
        tasks(for: date).filter { $0.blockKey == key }
    }
    /// Deliberately the UNfiltered list: this is an identity lookup, not a listing. The details sheet
    /// has to keep finding the task it is showing at the very moment it is reassigned away — that is
    /// when it needs to put a refused write back.
    func task(withID id: String, for date: Date) -> DayPlanTask? {
        allTasks(for: date).first { $0.id == id }
    }

    /// Tasks the USER changed on `date` (never AppleScript-driven changes), newest first. With `since`
    /// nil, every task that carries a user-edit stamp; otherwise only those edited strictly after it.
    /// Backs the `recently modified tasks` AppleScript command (see `AppleScriptScripting.swift`).
    func recentlyUserModifiedTasks(since: Date?, for date: Date) -> [DayPlanTask] {
        tasks(for: date)
            .compactMap { task -> (DayPlanTask, Date)? in
                guard let at = task.lastUserModifiedAt else { return nil }
                if let since = since, at <= since { return nil }
                return (task, at)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
    /// Nest a task under a block (key) or pull it back to the panel (nil).
    func setBlockKey(_ key: String?, forTaskID id: String, date: Date) {
        if key != nil, storageDay(for: id, preferred: date) != dayKey(date) {
            moveTask(id: id, from: date, to: date)
        }
        let k = storageDay(for: id, preferred: date)
        guard let i = byDay[k]?.firstIndex(where: { $0.id == id }) else { return }
        byDay[k]?[i].blockKey = key; save()
    }

    /// Backend projects (`/projects`), id → name. Merged into autocomplete suggestions so the user can
    /// pick a real project before any task on the day uses it, and used to resolve a task's
    /// `project_id` to its name (and a typed name back to an id when syncing). Set by the host on load.
    private(set) var remoteProjectsByID: [String: String] = [:]
    /// True once `/projects` has been fetched successfully this session. Until then a typed name can't
    /// be trusted as "new" — creating it would duplicate a project that merely hasn't loaded yet.
    private(set) var remoteProjectsLoaded = false
    private var remoteProjectRefreshCompletions: [(_ loaded: Bool) -> Void] = []

    var remoteProjectNames: [String] { Array(remoteProjectsByID.values).sorted() }
    var remoteProjectIDs: Set<String> { Set(remoteProjectsByID.keys) }

    /// Every stored task, keyed by `yyyy-MM-dd` — what `DayPlanProjectRepair` scans.
    var tasksByDay: [String: [DayPlanTask]] { byDay }

    /// Custom board columns that finish a task. A project can mark a task done by moving it into
    /// one of these; the to-do's own `status` stays whatever it was, which is why a task completed
    /// on the phone kept its unticked box on the Day Plan (report 2026-09-13_20-06-43).
    private(set) var completingStatusIds: Set<String> = []

    /// Each project's board columns, keyed by project id. The flat `completingStatusIds` above
    /// answers "is this row finished?"; moving a completed task into the right column needs to know
    /// which columns belong to ITS project, so both are kept.
    private(set) var customStatusesByProject: [String: [ProjectCustomStatus]] = [:]

    func setCompletingStatusIds(_ ids: Set<String>) { completingStatusIds = ids }

    func setCustomStatusesByProject(_ statuses: [String: [ProjectCustomStatus]]) {
        customStatusesByProject = statuses
    }

    /// Whether a backend to-do row counts as finished: its own status, or a board column that
    /// completes it. `columnIds` is the set of completing columns across the user's projects.
    static func isFinished(status: String?, customStatusId: String?, completingStatusIds: Set<String>) -> Bool {
        if (status ?? "") == "COMPLETED" { return true }
        guard let columnId = customStatusId, !columnId.isEmpty else { return false }
        return completingStatusIds.contains(columnId)
    }

    func setRemoteProjects(_ projects: [(id: String, name: String)]) {
        remoteProjectsByID = Dictionary(projects.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        remoteProjectsLoaded = true
    }

    /// Fetch the user's projects (`/projects`, all pages) into `remoteProjectsByID`. Concurrent callers
    /// share one request. `completion(loaded)` runs on the main thread; `loaded` is false when the fetch
    /// couldn't happen (not authed yet / offline), in which case the cache is left as it was.
    func refreshRemoteProjects(completion: @escaping (_ loaded: Bool) -> Void) {
        remoteProjectRefreshCompletions.append(completion)
        guard remoteProjectRefreshCompletions.count == 1 else { return }
        allApiObject.getProjectsList { [weak self] dicts in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let dicts = dicts {
                    let projects = dicts.compactMap { dict -> (id: String, name: String)? in
                        guard let id = dict.value(forKey: "id") as? String,
                              let name = dict.value(forKey: "name") as? String else { return nil }
                        return (id: id, name: name)
                    }
                    self.setRemoteProjects(projects)
                    var completing = Set<String>()
                    var columnsByProject: [String: [ProjectCustomStatus]] = [:]
                    for dict in dicts {
                        let raw = (dict.value(forKey: "custom_statuses") as? [[String: Any]]) ?? []
                        for status in raw {
                            guard let id = status["id"] as? String,
                                  status["should_complete_task"] as? Bool == true else { continue }
                            completing.insert(id)
                        }
                        guard let projectID = dict.value(forKey: "id") as? String else { continue }
                        let columns = raw.compactMap { status -> ProjectCustomStatus? in
                            guard let id = status["id"] as? String, !id.isEmpty else { return nil }
                            return ProjectCustomStatus(id: id, label: status["label"] as? String ?? "",
                                                       color: status["color"] as? String,
                                                       order: status["order"] as? Int,
                                                       should_complete_task: status["should_complete_task"] as? Bool)
                        }
                        if !columns.isEmpty { columnsByProject[projectID] = columns }
                    }
                    self.setCompletingStatusIds(completing)
                    self.setCustomStatusesByProject(columnsByProject)
                }
                let waiting = self.remoteProjectRefreshCompletions
                self.remoteProjectRefreshCompletions = []
                waiting.forEach { $0(dicts != nil) }
            }
        }
    }

    // MARK: Project members (for the task details assignee control)

    /// Accepted members per project id. nil for a project means "never looked", which is not the same
    /// as "solo" — the details sheet shows no assignee control until it actually knows.
    private var projectMembersByID: [String: [ToDoAssigneeOption]] = [:]
    private var projectMemberCompletions: [String: [([ToDoAssigneeOption]) -> Void]] = [:]

    /// Cached members, or nil if this project has not been looked up yet.
    func cachedProjectMembers(projectID: String) -> [ToDoAssigneeOption]? { projectMembersByID[projectID] }

    /// Fetch a project's accepted members once and cache them. Concurrent callers share one request,
    /// and `completion` runs on the main thread — the details sheet reveals its assignee row from it.
    func loadProjectMembers(projectID: String, completion: @escaping ([ToDoAssigneeOption]) -> Void) {
        if let cached = projectMembersByID[projectID] { completion(cached); return }
        projectMemberCompletions[projectID, default: []].append(completion)
        guard projectMemberCompletions[projectID]?.count == 1 else { return }
        allApiObject.getProject(id: projectID) { [weak self] project in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // A failed fetch caches nothing: "we could not ask" must stay distinguishable from
                // "this project is solo", or one bad response hides the control until relaunch.
                let members = project.map { fetched in
                    fetched.acceptedMembers.compactMap { member -> ToDoAssigneeOption? in
                        guard let userId = member.user_id, !userId.isEmpty else { return nil }
                        return ToDoAssigneeOption(id: userId, label: member.email ?? userId)
                    }
                }
                if let members = members { self.projectMembersByID[projectID] = members }
                let waiting = self.projectMemberCompletions.removeValue(forKey: projectID) ?? []
                waiting.forEach { $0(members ?? []) }
            }
        }
    }

    func registerRemoteProject(id: String, name: String) {
        remoteProjectsByID[id] = name
    }

    func remoteProjectID(named name: String) -> String? {
        remoteProjectsByID.first { $0.value.caseInsensitiveCompare(name) == .orderedSame }?.key
    }

    /// The project name a backend to-do belongs to: its `project_id` resolved against the fetched
    /// projects, else the first tag's text (the backend mirrors a native project as a tag, and
    /// ClickUp-synced to-dos only carry the tag). None for a project the user deleted — its to-dos
    /// still carry its id and tag, and naming it again is what brought it back (#2680).
    func projectName(for fields: TodoProjectFields) -> String? {
        if let id = fields.projectID {
            if deletedProjectIDs.contains(id) { return nil }
            if let name = remoteProjectsByID[id] { return name }
        }
        return fields.tags.first?.text
    }

    // MARK: Project ordering (user-draggable order of project groups in the panel)

    private let projectOrderKey = "dayPlanProjectOrder"
    private var projectOrder: [String] = UserDefaults.standard.stringArray(forKey: "dayPlanProjectOrder") ?? []

    /// Order a set of present project names by the user's saved order; unknown projects keep their
    /// given (first-appearance) order at the end.
    func orderedProjects(_ present: [String]) -> [String] {
        var remaining = present
        var out: [String] = []
        for p in projectOrder {
            if let i = remaining.firstIndex(where: { $0.caseInsensitiveCompare(p) == .orderedSame }) {
                out.append(remaining.remove(at: i))
            }
        }
        out.append(contentsOf: remaining)
        return out
    }

    /// Today's incomplete tasks in the SAME order the Day Plan panel renders them: grouped by the user's
    /// saved project order ("No project" last), tasks in store order within a group. Mirrors
    /// `addProjectGroups` so the AI-block buddy's "top tasks" are literally the first tasks the user sees
    /// at the top of their Day Plan — not a separate importance re-sort that diverges from the view.
    func incompleteTasksInDisplayOrder(for date: Date) -> [DayPlanTask] {
        var order: [String] = []
        var groups: [String: [DayPlanTask]] = [:]
        var noProject: [DayPlanTask] = []
        for t in tasks(for: date) where !t.done {
            if let p = t.project, !p.isEmpty {
                if groups[p] == nil { groups[p] = []; order.append(p) }
                groups[p]?.append(t)
            } else {
                noProject.append(t)
            }
        }
        var out: [DayPlanTask] = []
        for p in orderedProjects(order) { out.append(contentsOf: groups[p] ?? []) }
        out.append(contentsOf: noProject)
        return out
    }

    /// Move project `name` to sit immediately before `target`, working from the FULL current display
    /// order (`current`) so the saved order is dense — otherwise moving past several projects only
    /// reshuffles the few names already in the sparse saved order, landing the project in the wrong spot.
    func moveProject(_ name: String, before target: String, within current: [String]) {
        guard name.caseInsensitiveCompare(target) != .orderedSame else { return }
        var order = current
        // Make sure both names are present even if `current` somehow omitted one.
        for n in [name, target] where !order.contains(where: { $0.caseInsensitiveCompare(n) == .orderedSame }) {
            order.append(n)
        }
        order.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        if let ti = order.firstIndex(where: { $0.caseInsensitiveCompare(target) == .orderedSame }) {
            order.insert(name, at: ti)
        } else { order.append(name) }
        projectOrder = order
        UserDefaults.standard.set(order, forKey: projectOrderKey)
    }

    /// Distinct project names for `#` autocomplete: backend projects first, then any used locally.
    func allProjectNames() -> [String] {
        var seen = Set<String>(); var out: [String] = []
        func add(_ p: String) {
            guard !p.isEmpty, !seen.contains(p.lowercased()) else { return }
            seen.insert(p.lowercased()); out.append(p)
        }
        remoteProjectNames.forEach(add)
        for tasks in byDay.values { for t in tasks { if let p = t.project { add(p) } } }
        return out
    }

    /// Reorder `id` to sit immediately before `targetID` in the day's list (panel drag-to-reorder).
    func reorder(id: String, before targetID: String, for date: Date) {
        let k = storageDay(for: id, preferred: date)
        guard id != targetID, var arr = byDay[k],
              let from = arr.firstIndex(where: { $0.id == id }) else { return }
        let task = arr.remove(at: from)
        if let target = arr.firstIndex(where: { $0.id == targetID }) {
            arr.insert(task, at: target)
        } else {
            arr.append(task)   // target vanished; keep the task rather than drop it
        }
        byDay[k] = arr; save()
    }

    /// Move a task to another day (snooze). Clears any time-box assignment since it no longer applies.
    func moveTask(id: String, from: Date, to: Date, dueDate: Date? = nil) {
        let fk = storageDay(for: id, preferred: from), tk = dayKey(to)
        guard fk != tk, let i = byDay[fk]?.firstIndex(where: { $0.id == id }) else { return }
        var task = byDay[fk]!.remove(at: i)
        task.blockKey = nil
        // Back-dating: mark a task moved to a PAST day as manually planned so rollover doesn't drag it
        // back to today. Moving to today/future clears the flag (rollover doesn't touch those days
        // anyway, and it should roll normally if later left incomplete in the past).
        task.manuallyPlanned = (tk < dayKey(Date())) ? true : nil
        byDay[tk, default: []].append(task)
        save()
        // Keep the backend's planned_date in sync for imported to-dos, otherwise the next hydrate
        // re-plants the task on its old day (the backend still says it's planned there). From-scratch
        // tasks (no sourceTaskId) have no backend pointer, so nothing to update.
        if let sid = task.sourceTaskId {
            DayPlanSync.shared.setTodoPlanned(todoID: sid, title: task.title, quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                              plannedDate: to, blockKey: nil, order: nil, dueDate: dueDate)
        }
    }

    /// Snooze changes the backing due date, like an explicit move to another day.
    /// Local-only tasks retain their local date because they have no backing to-do.
    func snooze(id: String, from: Date, to: Date) {
        // Snooze = move the task to `to` AND push the new date onto the to-do's `due_date`. Both go in
        // one `PUT /to-do` upsert (planned_date + due_date together) so there's a single, ordered write
        // — previously a second due-date-only write raced/undid the planned_date and left a duplicate.
        moveTask(id: id, from: from, to: to, dueDate: to)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [DayPlanTask]].self, from: data) else { return }
        byDay = decoded
        cleanup()
        dedupeSnoozeClones()
        rolloverIncompleteTasks()
    }

    /// Repair the snooze-clone bug: a to-do (`sourceTaskId`) must live on at most ONE day and appear
    /// once, so collapse any that appear more than once — whether cloned onto its original day while the
    /// real task snoozed forward (the pre-#2237 bug), or duplicated on a single day. Keep the copy that
    /// still has a project, then the one on the latest day (snoozes move forward), and carry over a
    /// completion from any dropped copy so a tick is never lost.
    ///
    /// Runs on EVERY load (self-healing), not once — the one-time guard let any duplicate that appeared
    /// after the first run linger forever. The going-forward fix means the Mac makes no new clones, but
    /// this also cleans up any that arrive from elsewhere (e.g. an older mobile client). No-op unless a
    /// `sourceTaskId` genuinely appears more than once, so it's safe to run each time.
    private func dedupeSnoozeClones() {
        var copiesBySource: [String: [(day: String, task: DayPlanTask)]] = [:]
        for (dayKey, tasks) in byDay {
            for task in tasks where task.sourceTaskId != nil {
                copiesBySource[task.sourceTaskId!, default: []].append((day: dayKey, task: task))
            }
        }

        var changed = false
        for (sid, copies) in copiesBySource where copies.count > 1 {
            let anyDone = copies.contains { $0.task.done }
            // Prefer a copy that kept its project; break ties toward the latest (snoozed-to) day.
            let keeper = copies.max { a, b in
                let aHasProject = a.task.project?.isEmpty == false
                let bHasProject = b.task.project?.isEmpty == false
                if aHasProject != bHasProject { return !aHasProject && bHasProject }
                return a.day < b.day
            }!
            for day in Set(copies.map { $0.day }) { byDay[day]?.removeAll { $0.sourceTaskId == sid } }
            var kept = keeper.task
            if anyDone { kept.done = true }
            byDay[keeper.day, default: []].append(kept)
            changed = true
        }
        if changed { save() }
    }

    /// Carry forward any incomplete tasks from past days to today (completed ones stay in their day
    /// as history). Time-box assignments are dropped since they no longer apply. Runs on load.
    func rolloverIncompleteTasks() {
        let todayKey = dayKey(Date())
        var changed = false
        for (k, tasks) in byDay where k < todayKey {   // "yyyy-MM-dd" sorts chronologically
            // Don't roll tasks the user deliberately back-dated (manuallyPlanned) — leave them put.
            let incomplete = tasks.filter { !$0.done && $0.manuallyPlanned != true }
            guard !incomplete.isEmpty else { continue }
            byDay[k] = tasks.filter { $0.done || $0.manuallyPlanned == true }
            for var t in incomplete { t.blockKey = nil; byDay[todayKey, default: []].append(t) }
            changed = true
        }
        if changed { save() }
    }

    /// One-time hygiene on load: drop duplicate imports (same source to-do) and orphaned blank
    /// from-scratch rows that piled up from earlier buggy sessions.
    private func cleanup() {
        var changed = false
        for (k, tasks) in byDay {
            var seenSourceIDs = Set<String>()
            var cleaned: [DayPlanTask] = []
            for t in tasks {
                if t.sourceTaskId == nil && t.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
                if let sid = t.sourceTaskId {
                    if seenSourceIDs.contains(sid) { continue }
                    seenSourceIDs.insert(sid)
                }
                cleaned.append(t)
            }
            if cleaned.count != tasks.count { byDay[k] = cleaned; changed = true }
        }
        if changed { save() }
    }
    private func save() {
        storageRevision += 1
        if Self.mockMode { return }   // mockups are in-memory only
        if let data = try? JSONEncoder().encode(byDay) {
            UserDefaults.standard.set(data, forKey: key)
            NotificationCenter.default.post(name: Self.forecastSnapshotDidChange, object: nil)
        }
    }
}

/// Whether a date assignment actually moves the panel to another day.
///
/// The panel's date is re-assigned on plenty of refreshes that land on the same day, and committing
/// an open name editor on every one of those would yank the cursor out mid-word. Only a real day
/// change should end editing.
enum DayPlanDateChange {
    static func isADifferentDay(from oldDate: Date, to newDate: Date,
                                calendar: Calendar = .current) -> Bool {
        !calendar.isDate(oldDate, inSameDayAs: newDate)
    }
}

/// The right-hand "Tasks for today" panel. Self-contained: renders the day's tasks with a
/// checkbox, an editable name and an editable duration, plus an add-from-scratch button. Calls
/// `onChange` after any edit so the host can refresh anything that depends on tasks.
final class DayPlanTasksPanel: NSView, NSTextFieldDelegate, NSComboBoxDelegate, NSPopoverDelegate {

    /// The day this panel shows.
    ///
    /// `willSet` commits any open name editor while `date` is still the OLD day, and that ordering
    /// is the whole point. Setting the date used to only trigger `reload()`, which defers while a
    /// name field is focused — so navigating to another day left the panel rendering the previous
    /// day's rows under the new day's header ("Mon 21 Sep" over "Tasks for Tuesday"), and worse,
    /// committing the field afterwards looked the task up in the NEW day's store, failed to find
    /// it, and silently dropped what had been typed (report 2026-09-21_20-47-13).
    var date = Date() {
        willSet {
            guard DayPlanDateChange.isADifferentDay(from: date, to: newValue) else { return }
            // Ends editing, which commits through controlTextDidEndEditing against the old date.
            endNameEditing()
        }
        didSet { reloadAfterUserAction() }
    }

    /// Give up the field editor if this panel owns it. Safe to call when nothing is focused.
    private func endNameEditing() {
        let editor = window?.firstResponder as? NSTextView
        guard (editor?.delegate as? NSTextField)?.isDescendant(of: self) == true else { return }
        window?.makeFirstResponder(nil)
    }
    var onChange: (() -> Void)?
    /// Hook the host provides to present the "add from to-do list" picker.
    var onAddFromList: (() -> Void)?

    private let stack = NSStackView()
    private var isReloading = false   // guards against re-entrant reload() duplicating the list
    private var pendingReloadAfterEditing = false   // a reload arrived while editing; run it on blur

    // Trailing spacer height reserved after the last task row so its action row (Expand/Snooze/Remove,
    // revealed on click) and a fully-wrapped 3-line name aren't left unreachable by scrolling — see the
    // comment on the spacer in reload() for why this can't be done via NSScrollView.contentInsets.
    // Sized for the worst case: ~2 extra wrapped lines over a 1-line row (≈ 34pt) + the action row's own
    // height plus its stack spacing (≈ 30pt), with headroom.
    private let bottomScrollReserveHeight: CGFloat = 90

    private var headTopConstraint: NSLayoutConstraint?
    /// Extra top padding added in full screen so the header clears the menu-bar reveal overlay.
    var extraTopInset: CGFloat = 0 { didSet { headTopConstraint?.constant = 14 + extraTopInset } }

    /// Sticky container for the bulk multi-select action bar, pinned between the fixed header and the
    /// scrolling task list so Snooze / Remove / Clear stay reachable regardless of scroll position.
    /// Empty (height collapsed to 0 via `bulkBarHostEmptyHeight`) when nothing is selected.
    private let bulkBarHost = NSView()
    private var bulkBarHostEmptyHeight: NSLayoutConstraint?

    // Snooze popover state.
    // Snooze popover state (the popover itself is the shared `SmartSnoozePopover`).
    private var snoozePopover: SmartSnoozePopover?
    private var snoozeTaskID: String?
    /// The main window's default button, detached while the task-detail modal is open so Return inside
    /// it can't start a habit; restored when the modal closes.
    private var snoozeSavedDefaultButton: NSButtonCell?

    // Click-revealed per-task action row (Expand / Snooze / Remove) shown beneath the focused task.
    private weak var actionRow: NSView?
    private var actionRowTaskID: String?
    /// The shortcut explainer card shown under the task being edited, until its ✕ retires it for good.
    private weak var shortcutCard: TaskShortcutCardView?

    // Multi-select (shift/⌘-click a task) for bulk snooze/remove.
    private var selectedTaskIDs: Set<String> = []
    private var snoozeBulk = false

    /// RAW schedule-free minutes on a future day (routine/meeting gaps, NOT net of tasks) — also supplied
    /// by the host. Smart snooze needs schedule-free and task load separately to apply its rollover model.
    var scheduleFreeMinutesForDate: ((Date) -> Int)?

    /// blockKey → the name of the block a time-boxed task is pinned to ("📅 Standup · 9–9:15am"),
    /// supplied by the host on every render so the clock badge can say WHICH block, not just that
    /// there is one. A key with no entry (a stale box whose block is gone) falls back to the plain label.
    var timeBoxedBlockTitles: [String: String] = [:] { didSet { if oldValue != timeBoxedBlockTitles { reload() } } }

    // Task detail modal state.
    private var taskModalPopover: NSPopover?
    private var modalTaskID: String?
    private var modalSubtasks: [DayPlanSubtask] = []
    private weak var modalTitleField: NSTextField?
    private weak var modalProjectField: NSTextField?
    private weak var modalDurationField: NSTextField?
    private weak var modalImportancePopup: NSPopUpButton?
    private weak var modalImportanceSwatch: NSView?
    private weak var modalNotesView: NSTextView?
    private weak var modalSubtaskStack: NSStackView?
    /// Files on the task being edited. Deliberately a strong reference that outlives the popover: the
    /// file picker and the preview both close the modal (see `chooseTaskAttachment`), and an upload
    /// already in flight has to survive that.
    private var modalAttachments: ToDoAttachmentsStore?
    /// Local ids of tasks with a pasted image waiting on their to-do being minted. Keyed by id, not a
    /// single flag, because the sheet is closed and rebuilt by the picker and the preview.
    private var pendingPasteTaskIDs: Set<String> = []
    /// The "waiting" line in the open sheet, so it can be shown the moment a ⌘V is taken.
    private weak var modalPendingPasteLabel: NSTextField?
    /// The assignee row in the open sheet. Hidden until the project's members are known — a project
    /// the user is alone in never reveals it ("if the project has other members").
    private weak var modalAssigneeRow: NSStackView?
    private weak var modalAssigneePopup: NSPopUpButton?
    /// The assignee the sheet last showed, so a refused write can be put back.
    private var modalAssigneeShown: String?
    /// In-flight uploads of pasted images. The store owns the request, so it must outlive this call.
    private var pastedImageUploads: [ToDoAttachmentsStore] = []
    /// Loaded once per modal rather than per row — the whole attachment UI is shared with the to-do
    /// editor and reads that screen's strings.
    private var attachmentStrings = ToDoStrings.load()

    /// The paperclip badge drawn under a task that carries files. A text glyph, not an SF Symbol, so it
    /// matches the sub-task count ("☑ 1/3") sitting beside it.
    private static let attachmentBadgeGlyph = "📎"
    /// Font size of the badges under a task name (paperclip, sub-task count).
    private static let rowBadgeFontSize: CGFloat = 10

    static func attachmentBadgeTitle(_ count: Int, color: NSColor) -> NSAttributedString {
        NSAttributedString(string: "\(attachmentBadgeGlyph) \(count)", attributes: [
            .font: NSFont.systemFont(ofSize: rowBadgeFontSize),
            .foregroundColor: color,
        ])
    }

    /// Width of the modal's fields; the attachments section matches so the form stays a single column.
    private static let modalFieldWidth: CGFloat = 320
    /// The attachment rows scroll past this height — a task may hold 20 files and the modal is a
    /// popover with no scroll view of its own.
    private static let modalAttachmentsMaxHeight: CGFloat = 120

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        buildChrome()
        // The portfolio's pushed-task set arrives asynchronously (#2418); re-render so the hint appears.
        NotificationCenter.default.addObserver(self, selector: #selector(pushedTasksDidChange),
                                               name: DayPlanPushedTasks.didChange, object: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // Paint the background via updateLayer so windowBackgroundColor is resolved against THIS panel's
    // effectiveAppearance every display pass. The old approach cached a cgColor and relied on
    // viewDidChangeEffectiveAppearance firing — but when only the rows were rebuilt (via an external
    // appearance-change reload) the panel kept a stale dark fill, showing dark in Light mode.
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true   // repaint the background (updateLayer) for the new appearance
        reload()              // rebuild the rows so their fills track it too
    }

    private let totalLabel = NSTextField(labelWithString: "")
    /// Shown at the top of the panel only while the day is over its capacity.
    private let overCapacityBanner = NSTextField(labelWithString: "")
    /// The offer that sits beside the over-capacity banner. The Day Plan deliberately does NOT get a
    /// second banner: the one it already has says the day is over capacity, and a second one saying
    /// nearly the same thing beside it would be noise (report 2026-09-16_22-22-50). Only the action
    /// was missing, so only the action is added — shown and hidden with the banner it belongs to.
    ///
    /// That action is **Fix**, not the re-prioritise link this slot briefly held: "on day plan ignore
    /// this instruction - check the other queued task to add a Fix link on the day plan when the
    /// warning appears". Re-prioritising is still reachable — it is one of the routes inside the Fix
    /// modal — so the Day Plan never loses the ability to act on its own warning.
    private lazy var reprioritiseLink: NSButton = {
        let b = cursorButton(title: ScheduleText.dayFixLink, target: self,
                             action: #selector(reprioritiseClicked))
        b.isBordered = false
        b.bezelStyle = .inline
        b.contentTintColor = .controlAccentColor
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    @objc private func reprioritiseClicked() { openDayFixModal() }
    private weak var headerLabel: NSTextField?
    private var remainingMins = 0
    /// Schedule-free minutes for the day (gaps left by meetings/habits/breaks), set by the host.
    /// The header shows this MINUS the day's tasks still to do (see `refreshTotalLabel`), so it's the
    /// raw schedule figure here — nil only when there's no schedule at all for the day.
    var scheduleFreeMinutes: Int? { didSet { refreshTotalLabel() } }
    var forecastAbsorbedMinutes: Double = 0 { didSet { refreshTotalLabel() } }

    private static func hm(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    /// Show the full duration of unfinished tasks, including work that fits inside a habit block.
    /// The buffer still uses the forecast's net committed load so absorbed work is not charged twice.
    /// The over-capacity banner and buffer share that same forecast figure.
    private func refreshTotalLabel() {
        let font = totalLabel.font ?? .systemFont(ofSize: 11)
        let baseAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.secondaryLabelColor]
        let result = NSMutableAttributedString()
        let load = LocalTimeForecast.dayLoad(day: date, capacityMinutes: Double(scheduleFreeMinutes ?? 0),
                                             plannedMinutes: Double(remainingMins),
                                             absorbedMinutes: forecastAbsorbedMinutes)
        let known = scheduleFreeMinutes != nil
        if remainingMins > 0 {
            let text = ForecastText.format(.plannedTotal, ["<DURATION>": ForecastText.duration(Double(remainingMins))])
            result.append(NSAttributedString(string: text, attributes: baseAttrs))
        }
        if known {
            let text = ForecastText.format(.bufferTotal, ["<BUFFER>": ForecastText.signedDuration(load.bufferMinutes)])
            var attrs = baseAttrs
            if load.isOvercommitted { attrs[.foregroundColor] = NSColor.systemRed }
            if result.length > 0 {
                result.append(NSAttributedString(string: DayPlanTasksPanel.totalsSeparator, attributes: baseAttrs))
            }
            result.append(NSAttributedString(string: text, attributes: attrs))
        }
        totalLabel.attributedStringValue = result
        totalLabel.isHidden = result.length == 0
        // Hiding it removes it from the stack entirely, so the banner costs no height on a day that fits.
        overCapacityBanner.stringValue = known && load.isOvercommitted
            ? ForecastText.format(.notEnoughTimeForTasks, ["<DURATION>": ForecastText.duration(load.overcommittedMinutes)])
            : ""
        overCapacityBanner.isHidden = overCapacityBanner.stringValue.isEmpty
        // Merely over is normal and the banner alone says so; only a day that no amount of effort
        // rescues is worth offering to re-prioritise.
        // Shown with the warning itself, not on a stricter threshold. The two-hour rule existed for
        // the re-prioritise link, whose answer was wrong for a day fifteen minutes over; "Fix" offers
        // shortening a single habit too, which is exactly the right size of answer for a small gap.
        reprioritiseLink.isHidden = overCapacityBanner.isHidden
    }

    private var settingsPopover: NSPopover?
    private static let showCompletedKey = "dayPlanShowCompletedTasks"
    private var showCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.showCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.showCompletedKey) }
    }
    @objc private func toggleShowCompleted(_ sender: NSButton) {
        showCompleted = (sender.state == .on)
        reloadAfterUserAction()
    }

    /// Settings popover behind the header cog. Currently just the show-completed toggle.
    @objc private func openSettingsClicked(_ sender: NSButton) {
        let completedCount = DayPlanTaskStore.shared.tasks(for: date).filter { $0.done }.count
        let toggleTitle = completedCount > 0
            ? String(format: ScheduleText.tasksShowCompletedCount, completedCount)
            : ScheduleText.tasksShowCompleted
        let check = cursorButton(checkboxWithTitle: toggleTitle, target: self, action: #selector(toggleShowCompleted(_:)))
        check.state = showCompleted ? .on : .off
        let heading = label(ScheduleText.tasksSettings, size: 13, bold: true)
        let form = NSStackView(views: [heading, check])
        form.orientation = .vertical; form.alignment = .leading; form.spacing = 10
        form.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView(); container.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            form.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])
        let vc = NSViewController(); vc.view = container
        let pop = NSPopover(); pop.contentViewController = vc; pop.behavior = .transient
        pop.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        settingsPopover = pop
    }

    /// "Tasks for today" when the shown day is today, else "Tasks for <Weekday>" (localised).
    private func headerText(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return ScheduleText.tasksForToday }
        let f = DateFormatter(); f.dateFormat = "EEEE"; f.calendar = Calendar.current
        return String(format: ScheduleText.tasksForDay, f.string(from: day))
    }

    private static let totalsSeparator = " · "
    private static let bannerFontSize: CGFloat = 11
    private static let bannerMaxLines = 2

    private func buildChrome() {
        let header = label(ScheduleText.tasksForToday, size: 15, bold: true)
        headerLabel = header
        // Above the header, and only while the day is over capacity. Capped at two truncating lines
        // and hugging its content vertically so a narrow panel can never let it squeeze the task list
        // — which lives in a scroll view pinned to the panel's bottom, so it shrinks rather than
        // being pushed off-screen.
        overCapacityBanner.font = .systemFont(ofSize: DayPlanTasksPanel.bannerFontSize, weight: .medium)
        overCapacityBanner.textColor = .systemRed
        overCapacityBanner.maximumNumberOfLines = DayPlanTasksPanel.bannerMaxLines
        overCapacityBanner.lineBreakMode = .byTruncatingTail
        overCapacityBanner.translatesAutoresizingMaskIntoConstraints = false
        overCapacityBanner.setContentHuggingPriority(.required, for: .vertical)
        overCapacityBanner.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        overCapacityBanner.isHidden = true
        totalLabel.font = .systemFont(ofSize: 11)
        totalLabel.textColor = .secondaryLabelColor
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        let addNew = cursorButton(title: ScheduleText.tasksAddNew, target: self, action: #selector(addFromScratchClicked))
        addNew.bezelStyle = .rounded
        if #available(macOS 11.0, *) { addNew.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil); addNew.imagePosition = .imageLeading }
        let addList = cursorButton(title: ScheduleText.tasksAddFromList, target: self, action: #selector(addFromList))
        addList.bezelStyle = .rounded
        if #available(macOS 11.0, *) { addList.image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: nil); addList.imagePosition = .imageLeading }
        let addRow = NSStackView(views: [addNew, addList])
        addRow.orientation = .horizontal; addRow.spacing = 8; addRow.distribution = .fillEqually

        // Settings cog (holds the show-completed toggle and any future options). It sits on the
        // totals row, right-aligned — NOT the top-right corner, where the full-screen "Exit
        // Fullscreen" button would overlap it.
        let cog = cursorButton(title: "", target: self, action: #selector(openSettingsClicked(_:)))
        cog.bezelStyle = .inline; cog.isBordered = false
        if #available(macOS 11.0, *) { cog.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings") } else { cog.title = "⚙" }
        cog.contentTintColor = .secondaryLabelColor
        cog.toolTip = ScheduleText.tasksSettings
        cog.setContentHuggingPriority(.required, for: .horizontal)
        let totalRow = NSStackView(views: [totalLabel, NSView(), cog])
        totalRow.orientation = .horizontal; totalRow.alignment = .centerY; totalRow.spacing = 6

        stack.orientation = .vertical
        stack.alignment = .leading        // .fill via per-row width below would over-constrain; leading is safe
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Title + (totals + cog) row + the two add buttons, full panel width. The banner sits under
        // the day's title and directly above the buffer figure it explains, rather than above the
        // title where it read as a header for the whole panel (report 2026-09-16_08-45-37).
        let bannerRow = NSStackView(views: [overCapacityBanner, reprioritiseLink])
        bannerRow.orientation = .horizontal; bannerRow.alignment = .firstBaseline; bannerRow.spacing = 8
        bannerRow.translatesAutoresizingMaskIntoConstraints = false
        let head = NSStackView(views: [header, bannerRow, totalRow, addRow])
        head.orientation = .vertical; head.alignment = .leading; head.spacing = 6
        head.setCustomSpacing(8, after: totalRow)
        head.translatesAutoresizingMaskIntoConstraints = false
        totalRow.widthAnchor.constraint(equalTo: head.widthAnchor).isActive = true   // so the cog hugs the right edge

        // Tasks list lives in a scroll view so a long list scrolls instead of overflowing the panel
        // (which previously pushed the Custom Routines panel below out of the layout).
        let clip = TopFlippedClipView(); clip.drawsBackground = false
        let scroll = NSScrollView()
        scroll.contentView = clip
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .legacy   // always-visible scrollbar on the tasks list, even with no custom routines below
        scroll.documentView = stack
        scroll.translatesAutoresizingMaskIntoConstraints = false
        // The inline #project suggestion list is a panel subview anchored to the field's on-screen
        // position — it can't follow the rows as they scroll. So close it when the task list scrolls
        // instead of letting it float detached at the old spot.
        clip.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(tasksDidScroll),
                                               name: NSView.boundsDidChangeNotification, object: clip)
        // The To-do list ticked a task that is planned here — redraw so the row shows it at once.
        NotificationCenter.default.addObserver(self, selector: #selector(storeChangedExternally),
                                               name: DayPlanTaskStore.tasksDidChangeExternally, object: nil)
        // NB: room to scroll past the last task is reserved via a trailing spacer arranged subview in
        // reload(), NOT scroll.contentInsets — verified (offscreen AppKit harness) that contentInsets.bottom
        // does not extend NSClipView's constrainBoundsRect/documentRect, so it never actually created any
        // extra scrollable headroom here despite the old comment claiming otherwise (bug report 2026-07-18:
        // the last task's click-revealed action row was unreachable/unclickable at max scroll).

        bulkBarHost.translatesAutoresizingMaskIntoConstraints = false
        // When no tasks are selected the host holds no subview; pin its height to 0 so the scroll list
        // sits directly under the header exactly as before. reload() deactivates this when a bar is added.
        let hostEmpty = bulkBarHost.heightAnchor.constraint(equalToConstant: 0)
        bulkBarHostEmptyHeight = hostEmpty

        addSubview(head)
        addSubview(bulkBarHost)
        addSubview(scroll)
        let headTop = head.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 14)
        headTopConstraint = headTop
        NSLayoutConstraint.activate([
            // Pin the header below the safe-area top; `extraTopInset` adds more in full screen so
            // "Tasks for today" + the add buttons clear the menu-bar reveal (clock / Exit Full
            // Screen) overlay.
            headTop,
            head.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            head.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            // Sticky bulk-action bar host sits between the fixed header and the scroll list.
            bulkBarHost.topAnchor.constraint(equalTo: head.bottomAnchor, constant: 12),
            bulkBarHost.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            bulkBarHost.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            hostEmpty,
            // Scrollable tasks list fills the panel below the sticky bar host. No gap here: the 12pt
            // below the bar lives inside the host (bar's bottom inset), so an empty host collapses to
            // exactly the original 12pt head→list spacing with no leftover gap.
            scroll.topAnchor.constraint(equalTo: bulkBarHost.bottomAnchor, constant: 0),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: clip.topAnchor),
            stack.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: clip.widthAnchor),
        ])
        // NOTE: reload() is driven by the host setting `date` (after the panel is in the window),
        // not here during init — doing view work mid-property-init can leave the host half-built.
    }

    /// Rebuild the list even though a field is focused, by committing that edit first.
    ///
    /// `reload()` deliberately does nothing while the user is typing — clearing the stack would tear
    /// down the field editor mid-keystroke. That is right for a background refresh and wrong for
    /// something the user just did: selecting a task, or moving it to another day, changes state and
    /// then asks for a redraw that never arrives, so the click reads as doing nothing at all. The
    /// state had changed; only the screen had not (reports 2026-09-21_08-09-07, 2026-09-21_08-10-15 —
    /// both reported while a name field happened to be open, which is what made them look unrelated).
    ///
    /// Ending editing commits the name through `controlTextDidEndEditing`, so nothing typed is lost.
    func reloadAfterUserAction() {
        let editor = window?.firstResponder as? NSTextView
        if (editor?.delegate as? NSTextField)?.isDescendant(of: self) == true {
            window?.makeFirstResponder(nil)
        }
        reload()
    }

    func reload() {
        // Clearing the stack ends editing of any field, which can re-enter reload() mid-build and
        // duplicate the whole list — guard against that.
        if isReloading { return }
        // Don't rebuild the list while the user is actively typing in a field (a new task, a rename, a
        // duration) — clearing the stack would tear down the field and steal focus mid-keystroke. Defer
        // the reload until editing ends (flushed in controlTextDidEndEditing).
        // AppKit may not send textDidBeginEditing until the first keystroke. A restored field
        // already owns the field editor before then, and a periodic refresh must preserve it too.
        let focusedField = (window?.firstResponder as? NSTextView)?.delegate as? NSTextField
        if editingFieldCount > 0 || focusedField?.isDescendant(of: self) == true {
            pendingReloadAfterEditing = true
            return
        }
        pendingReloadAfterEditing = false
        isReloading = true
        defer {
            isReloading = false
            if let id = taskToRevealAfterReload {
                taskToRevealAfterReload = nil
                let editorText = projectEditorToRestore?.text
                projectEditorToRestore = nil
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let field = self.nameField(forTaskID: id) else { return }
                    self.layoutSubtreeIfNeeded()
                    field.scrollToVisible(field.bounds)
                    if let text = editorText {
                        field.stringValue = text
                        field.placeholderString = self.pendingProjectSelections[id].map { "#" + $0 }
                        field.window?.makeFirstResponder(field)
                        if let editor = field.currentEditor() as? NSTextView {
                            editor.string = text
                            editor.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
                        }
                    }
                    self.highlightMovedTask(id)
                }
            }
        }
        needsDisplay = true   // refresh the panel background for the current appearance
        // Resolve the cgColor row fills built below against this panel's appearance (not NSApp's), so
        // they track Light/Dark even when rebuilt outside a draw cycle.
        let savedAppearance = NSAppearance.current
        NSAppearance.current = effectiveAppearance
        defer { NSAppearance.current = savedAppearance }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionRow = nil; actionRowTaskID = nil   // the cleared stack took the action row with it
        shortcutCard = nil                       // …and the shortcut card under it
        refreshBulkBar()
        headerLabel?.stringValue = headerText(for: date)
        let stored = DayPlanTaskStore.shared.tasks(for: date)
        // Completed tasks are hidden unless the user opts in (toggle lives in the settings cog popover).
        let all = showCompleted ? stored : stored.filter { !$0.done }
        selectedTaskIDs.formIntersection(Set(stored.map { $0.id }))   // drop selections for gone tasks
        // Total estimated time for tasks still to do (free time is appended in refreshTotalLabel).
        remainingMins = all.filter { !$0.done }.reduce(0) { $0 + $1.durationMinutes }
        refreshTotalLabel()
        if all.isEmpty {
            let empty = label(ScheduleText.tasksEmpty, size: 12, bold: false)
            empty.textColor = .secondaryLabelColor
            empty.lineBreakMode = .byWordWrapping
            empty.preferredMaxLayoutWidth = 230
            stack.addArrangedSubview(empty)
            return
        }
        // Single combined list — no "time boxed" / "not yet time boxed" split. Time-boxed tasks
        // (dropped onto a schedule block, blockKey != nil) are flagged with a clock badge on their
        // row instead of living under a separate section header. Tasks stay grouped by project.
        addProjectGroups(all)
        // Real trailing content (not a scroll inset — see the comment on `scroll` above) so the last
        // task's click-revealed action row is always fully reachable by scrolling, instead of landing
        // right at the visual boundary with the Custom Routines panel below and reading as "hidden
        // behind" it.
        let bottomSpacer = NSView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.heightAnchor.constraint(equalToConstant: bottomScrollReserveHeight).isActive = true
        stack.addArrangedSubview(bottomSpacer)
    }

    /// Sub-group a section's tasks by project (first-appearance order; "No project" last) and render
    /// a project sub-header above each group. The header is only shown once there's >1 group so a
    /// project-less day stays flat.
    private func addProjectGroups(_ tasks: [DayPlanTask]) {
        var order: [String] = []
        var groups: [String: [DayPlanTask]] = [:]
        var noProject: [DayPlanTask] = []
        for t in tasks {
            if let p = t.project, !p.isEmpty {
                if groups[p] == nil { groups[p] = []; order.append(p) }
                groups[p]?.append(t)
            } else {
                noProject.append(t)
            }
        }
        let hasProjects = !order.isEmpty
        let ordered = DayPlanTaskStore.shared.orderedProjects(order)
        for p in ordered {
            let groupTasks = groups[p] ?? []
            let total = groupTasks.filter { !$0.done }.reduce(0) { $0 + $1.durationMinutes }
            addProjectHeader(p, totalMinutes: total, allOrdered: ordered)   // draggable header + per-project total + add
            for t in groupTasks { addTaskRow(t) }
        }
        if !noProject.isEmpty {
            if hasProjects { addPlainHeader(ScheduleText.tasksNoProject) }   // not draggable; always last
            for t in noProject { addTaskRow(t) }
        }
    }

    /// A draggable project-group header (drag one onto another to reorder the groups) with the
    /// project's total time and a + button to add a task straight into the project.
    private func addProjectHeader(_ project: String, totalMinutes: Int, allOrdered: [String]) {
        let h = ProjectHeaderView(title: project, name: project, totalMinutes: totalMinutes)
        h.translatesAutoresizingMaskIntoConstraints = false
        h.onReorder = { [weak self] dragged, target in
            guard let self = self else { return }
            DayPlanTaskStore.shared.moveProject(dragged, before: target, within: allOrdered)
            self.reload(); self.onChange?()
        }
        h.onAdd = { [weak self] in self?.addFromScratch(project: project) }
        h.onDragBegan = { [weak self] _, screenPoint in self?.beginProjectDragVisual(at: screenPoint) }
        h.onDragMoved = { [weak self] screenPoint in self?.moveProjectDragVisual(to: screenPoint) }
        h.onDragEnded = { [weak self] in self?.endDragVisual() }
        h.onManualDrop = { [weak self] dragged, screenPoint in
            guard let self = self, let window = self.window else { return }
            let winPoint = window.convertPoint(fromScreen: screenPoint)
            // 1. Precise hit on a project header.
            var view = window.contentView?.hitTest(winPoint)
            while let cur = view {
                if let target = cur as? ProjectHeaderView, target.projectName.caseInsensitiveCompare(dragged) != .orderedSame {
                    DayPlanTaskStore.shared.moveProject(dragged, before: target.projectName, within: allOrdered)
                    self.reload(); self.onChange?(); return
                }
                view = cur.superview
            }
            // 2. Fallback: nearest project header, so a drop in the gap (e.g. moving up past several
            //    projects) still reorders instead of doing nothing.
            if let nearest = self.nearestProjectHeader(toWindowPoint: winPoint),
               nearest.projectName.caseInsensitiveCompare(dragged) != .orderedSame {
                DayPlanTaskStore.shared.moveProject(dragged, before: nearest.projectName, within: allOrdered)
                self.reload(); self.onChange?()
            }
        }
        stack.addArrangedSubview(h)
        h.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    private func addPlainHeader(_ text: String) {
        let h = label("▾ " + text, size: 11, bold: true)
        h.textColor = .secondaryLabelColor
        stack.addArrangedSubview(h)
    }

    private func addTaskRow(_ task: DayPlanTask) {
        let row = makeRow(task)
        stack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true   // share an ancestor first
        // Give the name column a *definite* width (row width minus the fixed columns) so the
        // multi-line field has a concrete wrap width — without this the horizontal stack leaves the
        // width ambiguous and the field truncates instead of wrapping.
        if let rowStack = row as? NSStackView,
           let col = rowStack.arrangedSubviews.first(where: {
               $0.identifier?.rawValue.hasPrefix("namecol:") == true }) {
            let c = col.widthAnchor.constraint(equalTo: row.widthAnchor, constant: -142)   // -120 fixed cols + 16 time-boxed badge + 6 spacing
            c.priority = NSLayoutConstraint.Priority(999)   // just below required so it can't conflict
            c.isActive = true
        }
    }

    // MARK: Rows

    private func makeRow(_ task: DayPlanTask) -> NSView {
        let check = cursorButton(checkboxWithTitle: "", target: self, action: #selector(toggleDone(_:)))
        check.state = task.done ? .on : .off
        check.identifier = NSUserInterfaceItemIdentifier(task.id)

        // Name: looks like plain text, but a focus ring (border) appears only while editing.
        // Wraps over up to 3 lines for long names.
        let name = EditOnClickTextField(string: task.title)
        name.isBordered = false
        name.drawsBackground = false
        name.focusRingType = .default
        name.font = .systemFont(ofSize: 13)
        name.textColor = task.done ? .secondaryLabelColor : .labelColor
        name.placeholderString = ScheduleText.tasksNamePlaceholder
        name.toolTip = ScheduleText.tasksProjectHint
        name.identifier = NSUserInterfaceItemIdentifier("name:\(task.id)")
        name.delegate = self
        name.target = self; name.action = #selector(commitName(_:))
        name.cell?.sendsActionOnEndEditing = false   // blur is handled in controlTextDidEndEditing (no reload)
        name.usesSingleLineMode = false
        name.cell?.wraps = true
        name.cell?.isScrollable = false
        name.lineBreakMode = .byWordWrapping
        name.maximumNumberOfLines = 3
        name.setContentHuggingPriority(.defaultLow, for: .horizontal)
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if task.done { name.attributedStringValue = struckThrough(task.title) }
        name.onModifierClick = { [weak self] in self?.toggleSelection(task.id) }
        name.onPlainClick = { [weak self] in
            // Deferred so it runs after the field's mouse-tracking loop, with a stable view tree.
            DispatchQueue.main.async { self?.showActionRow(forTaskID: task.id) }
        }

        let dur = EditOnClickTextField(string: "\(task.durationMinutes)m")
        dur.isBordered = false
        dur.drawsBackground = false
        dur.focusRingType = .default
        dur.usesSingleLineMode = true
        dur.alignment = .right
        dur.font = .systemFont(ofSize: 12)
        dur.textColor = .secondaryLabelColor
        dur.identifier = NSUserInterfaceItemIdentifier("dur:\(task.id)")
        dur.delegate = self
        dur.target = self; dur.action = #selector(commitDuration(_:))
        dur.cell?.sendsActionOnEndEditing = false   // blur handled in controlTextDidEndEditing
        dur.translatesAutoresizingMaskIntoConstraints = false
        dur.widthAnchor.constraint(equalToConstant: 50).isActive = true
        name.nextKeyView = dur   // Tab from name jumps to duration

        // Name plus a sub-task count line beneath it (always shown when the task has sub-tasks). The
        // snooze/remove buttons that used to sit on the right are now in a click-revealed action row.
        var nameColViews: [NSView] = [name]
        let subs = task.subtaskList
        var subtaskCountBtn: NSButton?
        let subtasksAllDone = !subs.isEmpty && subs.allSatisfy { $0.done }
        if !subs.isEmpty {
            let doneCount = subs.filter { $0.done }.count
            // Clickable sub-task count — opens the task detail modal.
            let countBtn = cursorButton(title: "", target: self, action: #selector(subtaskCountClicked(_:)))
            countBtn.isBordered = false; countBtn.bezelStyle = .inline
            countBtn.identifier = NSUserInterfaceItemIdentifier(task.id)
            countBtn.attributedTitle = NSAttributedString(string: "☑ \(doneCount)/\(subs.count)", attributes: [
                .font: NSFont.systemFont(ofSize: 10),
                .foregroundColor: subtasksAllDone ? NSColor.systemGreen : NSColor.secondaryLabelColor,
            ])
            countBtn.toolTip = ScheduleText.tasksExpand
            subtaskCountBtn = countBtn
            nameColViews.append(countBtn)
        }
        // Paperclip when the task is known to carry files — the same borderless-inline treatment as the
        // sub-task count above, on its own line so a narrow row wraps instead of collapsing a column.
        var attachmentBtn: NSButton?
        if task.hasAttachments {
            let clip = cursorButton(title: "", target: self, action: #selector(subtaskCountClicked(_:)))
            clip.isBordered = false; clip.bezelStyle = .inline
            clip.identifier = NSUserInterfaceItemIdentifier(task.id)
            clip.attributedTitle = Self.attachmentBadgeTitle(task.attachmentCount ?? 0,
                                                             color: .secondaryLabelColor)
            clip.toolTip = attachmentStrings[.attachments]
            attachmentBtn = clip
            nameColViews.append(clip)
        }
        var pushedBackHint: PushedBackHint?
        if let projected = pushedBackProjectedDay(for: task) {
            let hint = makePushedBackHint(taskID: task.id, projectedDay: projected)
            pushedBackHint = hint
            nameColViews.append(hint.view)
        }
        let nameColumn = NSStackView(views: nameColViews)
        nameColumn.orientation = .vertical
        nameColumn.alignment = .leading
        nameColumn.spacing = 1
        nameColumn.translatesAutoresizingMaskIntoConstraints = false
        nameColumn.identifier = NSUserInterfaceItemIdentifier("namecol:\(task.id)")
        // A vertical stack doesn't stretch its children horizontally, so pin the name field to the
        // column's width — the column itself gets a concrete width in addTaskRow, giving the
        // multi-line field a definite wrap width.
        let nameW = name.widthAnchor.constraint(equalTo: nameColumn.widthAnchor)
        nameW.priority = NSLayoutConstraint.Priority(999)
        nameW.isActive = true

        // Grip to drag the task onto a schedule block. Give it a definite, generous hit area and a
        // clearly-visible tint so it reads as draggable (and so a click reliably lands on it).
        let handle = TaskDragHandle()
        handle.taskID = task.id
        if #available(macOS 11.0, *) { handle.image = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: "Drag") }
        handle.imageScaling = .scaleNone
        handle.contentTintColor = .secondaryLabelColor
        handle.toolTip = ScheduleText.tasksDragHint
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.widthAnchor.constraint(equalToConstant: 20).isActive = true
        handle.heightAnchor.constraint(equalToConstant: 24).isActive = true
        handle.onManualDrop = { [weak self] draggedID, screenPoint in
            self?.endDragVisual()
            self?.handleManualTaskDrop(draggedID: draggedID, at: screenPoint)
        }
        handle.onDragBegan = { [weak self] draggedID, screenPoint in
            self?.beginDragVisual(taskID: draggedID, at: screenPoint)
        }
        handle.onDragMoved = { [weak self] screenPoint in
            self?.moveDragVisual(to: screenPoint)
        }

        // Time-boxed badge: a clock on tasks that have been dropped onto a schedule block
        // (blockKey != nil). The column is always present — image nil when un-boxed — so the
        // duration column stays aligned across every row. Replaces the old separate section header.
        let timeBadge = NSImageView()
        timeBadge.translatesAutoresizingMaskIntoConstraints = false
        timeBadge.imageScaling = .scaleProportionallyDown
        timeBadge.contentTintColor = .secondaryLabelColor
        timeBadge.widthAnchor.constraint(equalToConstant: 16).isActive = true
        if let key = task.blockKey, #available(macOS 11.0, *) {
            timeBadge.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Time-boxed")
            // Name the block the task is boxed under; fall back to the plain label when the host hasn't
            // rendered yet, or the block it was pinned to no longer exists on this day.
            timeBadge.toolTip = timeBoxedBlockTitles[key].map {
                String(format: ScheduleText.tasksTimeBoxedUnder, $0)
            } ?? ScheduleText.tasksTimeBoxed
        }

        // Importance: tint the whole task row with the band colour and draw its text in a high-contrast
        // colour (instead of a small dot). A selected row instead uses the system selection pair (solid
        // fill + alternateSelectedControlText) so text stays legible on the highlight in both
        // appearances — the previous 15%-alpha tint left default label text unreadable (reproduced when
        // a single project makes its task selected by default).
        let isSelected = selectedTaskIDs.contains(task.id)
        let importanceBG = DayPlanTask.outcomeColor(task.outcome)
        if isSelected {
            let selectedFG = NSColor.alternateSelectedControlTextColor
            name.textColor = task.done ? selectedFG.withAlphaComponent(0.6) : selectedFG
            dur.textColor = selectedFG.withAlphaComponent(0.85)
            if task.blockKey != nil { timeBadge.contentTintColor = selectedFG }
            if let cb = subtaskCountBtn {
                cb.attributedTitle = NSAttributedString(string: cb.attributedTitle.string, attributes: [
                    .font: NSFont.systemFont(ofSize: 10),
                    .foregroundColor: selectedFG,
                ])
            }
            attachmentBtn?.attributedTitle = Self.attachmentBadgeTitle(task.attachmentCount ?? 0,
                                                                       color: selectedFG)
        } else if let fg = DayPlanTask.outcomeForeground(task.outcome) {
            if !task.done { name.textColor = fg }
            dur.textColor = fg.withAlphaComponent(0.85)
            if task.blockKey != nil { timeBadge.contentTintColor = fg }
            // The subtask count needs the high-contrast band colour in BOTH states — systemGreen (the
            // "all done" cue used on the plain background) is unreadable on the saturated orange/red band,
            // so use `fg` even when all subtasks are done (the "2/2" text itself still conveys done-ness).
            if let cb = subtaskCountBtn {
                cb.attributedTitle = NSAttributedString(string: cb.attributedTitle.string, attributes: [
                    .font: NSFont.systemFont(ofSize: 10),
                    .foregroundColor: fg,
                ])
            }
            attachmentBtn?.attributedTitle = Self.attachmentBadgeTitle(task.attachmentCount ?? 0, color: fg)
            pushedBackHint?.marker.textColor = fg.withAlphaComponent(0.85)
            pushedBackHint?.moveButton.contentTintColor = fg
        }
        let row = TaskReorderRow(views: [handle, check, nameColumn, timeBadge, dur])
        row.orientation = .horizontal
        row.alignment = .top   // top-align so a wrapped (multi-line) name keeps the controls aligned
        row.spacing = 6
        row.edgeInsets = NSEdgeInsets(top: 10, left: 8, bottom: 14, right: 8)   // breathing room around the importance tint; extra at the bottom because the multi-line name label under-reports its height, so its last line otherwise sits tight against the colour band's lower edge
        if isSelected {   // selection highlight wins over the importance tint
            row.wantsLayer = true
            // Saturated accent fill (not selectedContentBackgroundColor, which dims to a low-contrast
            // grey in this borderless, often-not-key window — leaving the name, incl. a #project tag,
            // blue-on-blue). controlAccentColor pairs reliably with alternateSelectedControlText (white).
            row.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            row.layer?.cornerRadius = 4
        } else if let bg = importanceBG {
            row.wantsLayer = true
            row.layer?.backgroundColor = bg.cgColor
            row.layer?.cornerRadius = 4
            row.toolTip = ForecastText.outcomeValue(task.outcome ?? 2) + " · " + DayPlanTask.outcomeBandLabel(task.outcome ?? 2)
        }
        // Re-assert the badge's own tooltip AFTER the row-level one above. A parent's tooltip registers
        // a rect over its whole bounds, so setting it later masked the clock's "Time boxed under <habit>"
        // and hovering the icon said nothing (report 2026-09-10_07-53-47, follow-up "not working —
        // nothing happens when I mouse over"). Re-assigning re-registers the child's rect last.
        if let badgeTip = timeBadge.toolTip, !badgeTip.isEmpty { timeBadge.toolTip = badgeTip }
        row.translatesAutoresizingMaskIntoConstraints = false
        row.taskID = task.id
        row.enableReorder()
        row.onReorder = { [weak self] dragged, target in
            guard let self = self else { return }
            DayPlanTaskStore.shared.reorder(id: dragged, before: target, for: self.date)
            self.reload()
            self.onChange?()
        }
        // NB: width is constrained to the stack in reload() *after* the row is added — activating
        // it here (before the row has a superview) throws "no common ancestor" and blanks the view.
        return row
    }

    // MARK: "Doesn't fit today" (portfolio pushed tasks, #2418)

    private struct PushedBackHint {
        let view: NSView
        let marker: NSTextField
        let moveButton: NSButton
    }

    /// The day the backend's Day Plan simulation expects this to-do to actually get done, when that
    /// is later than the day it's planned on. Only for today's panel (the wording says "today"),
    /// incomplete tasks, and tasks backed by a to-do (the simulation only knows those).
    private func pushedBackProjectedDay(for task: DayPlanTask) -> Date? {
        let cal = Calendar.current
        guard !task.done, cal.isDateInToday(date),
              let projected = DayPlanPushedTasks.shared.projectedDay(forTodoId: task.sourceTaskId),
              cal.startOfDay(for: projected) > cal.startOfDay(for: date) else { return nil }
        return projected
    }

    /// A subtle one-liner under the task name: "Doesn't fit today · Move to Tue 9 Sep".
    private func makePushedBackHint(taskID: String, projectedDay: Date) -> PushedBackHint {
        let marker = label(ScheduleText.tasksDoesNotFitToday, size: 10, bold: false)
        marker.textColor = .secondaryLabelColor
        let move = cursorButton(title: ScheduleText.tasksMoveToProjectedDay(ToDoDates.weekdayDayMonth(projectedDay)),
                                target: self, action: #selector(moveToProjectedDayClicked(_:)))
        move.isBordered = false
        move.bezelStyle = .inline
        move.font = .systemFont(ofSize: 10, weight: .semibold)
        move.contentTintColor = .controlAccentColor
        move.identifier = NSUserInterfaceItemIdentifier(taskID)
        // Stacked, not side by side. On one line the pair is wider than the tasks panel (306pt for this
        // user), so AppKit squeezed BOTH: "Doesn't fit today" shrank to "Do" and the blue "Move to Mon
        // 28 Sep" was still clipped at the edge — the action was unreadable, which is the whole point of
        // it (report 2026-09-11_19-55-34, follow-up "this was about 'Move to…' the blue text").
        // Two short lines fit any width the panel can be dragged to.
        let row = NSStackView(views: [marker, move])
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 1
        // The button must never be the thing that gives way; the marker above it may truncate.
        move.setContentCompressionResistancePriority(.required, for: .horizontal)
        marker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        marker.lineBreakMode = .byTruncatingTail
        return PushedBackHint(view: row, marker: marker, moveButton: move)
    }

    @objc private func moveToProjectedDayClicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue, let task = task(for: id),
              let projected = pushedBackProjectedDay(for: task) else { NSSound.beep(); return }
        // A plan move (re-points `planned_date`, like dragging the task to another day) — deliberately
        // not `snooze`, which would also rewrite the to-do's due date.
        DayPlanTaskStore.shared.moveTask(id: id, from: date, to: projected)
        if let sourceId = task.sourceTaskId { DayPlanPushedTasks.shared.remove(todoId: sourceId) }
        let daysAhead = Calendar.current.dateComponents([.day], from: date, to: projected).day ?? 0
        DayPlanAnalytics.capture(DayPlanAnalytics.taskMovedToProjectedDay, ["days_ahead": daysAhead])
        reloadAfterUserAction(); onChange?()
    }

    @objc private func pushedTasksDidChange() {
        guard Calendar.current.isDateInToday(date) else { return }
        reload()
    }

    /// Perform a task drop by hit-testing the view under the drop point ourselves. Used because
    /// AppKit's drag-destination routing doesn't deliver in the app's borderless full-screen window.
    /// Walks up from the hit view to find a TaskReorderRow (reorder) or a DropTargetView (time-box
    /// onto a schedule block), and invokes the same handler the native drop path would.
    // MARK: Manual drag visuals (the system draws nothing in the borderless full-screen window)

    private var dragOverlay: NSImageView?
    private var dragInsertLine: NSView?

    /// Snapshot the dragged row into a floating overlay (which we move with the cursor) and create the
    /// blue insertion line. Added to the window's content view so they sit above the scroll view.
    private func beginDragVisual(taskID: String, at screenPoint: NSPoint) {
        endDragVisual()
        guard let content = window?.contentView,
              let row = stack.arrangedSubviews.compactMap({ $0 as? TaskReorderRow }).first(where: { $0.taskID == taskID }),
              row.bounds.width > 0, row.bounds.height > 0,
              let rep = row.bitmapImageRepForCachingDisplay(in: row.bounds) else { return }
        row.cacheDisplay(in: row.bounds, to: rep)
        let img = NSImage(size: row.bounds.size); img.addRepresentation(rep)
        let iv = NSImageView(frame: NSRect(origin: .zero, size: row.bounds.size))
        iv.image = img
        iv.alphaValue = 0.92
        iv.wantsLayer = true
        iv.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor
        iv.layer?.cornerRadius = 4
        iv.layer?.borderWidth = 1
        iv.layer?.borderColor = NSColor.separatorColor.cgColor   // a border (no shadow — shadows are laggy when moving)
        content.addSubview(iv)
        dragOverlay = iv

        let line = NSView(frame: .zero)
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        line.layer?.cornerRadius = 1
        content.addSubview(line)
        dragInsertLine = line

        moveDragVisual(to: screenPoint)
    }

    private func moveDragVisual(to screenPoint: NSPoint) {
        guard let window = window, let content = window.contentView, let iv = dragOverlay else { return }
        let p = window.convertPoint(fromScreen: screenPoint)
        iv.frame.origin = NSPoint(x: p.x - iv.frame.width / 2, y: p.y - iv.frame.height / 2)
        // Position the insertion line at the top edge of the nearest task row (in content coords).
        if let nearest = nearestRow(toWindowPoint: p) {
            let f = nearest.convert(nearest.bounds, to: content)
            dragInsertLine?.frame = NSRect(x: f.minX, y: f.maxY - 1, width: f.width, height: 2)
            dragInsertLine?.isHidden = false
        } else {
            dragInsertLine?.isHidden = true
        }
    }

    private func endDragVisual() {
        dragOverlay?.removeFromSuperview(); dragOverlay = nil
        dragInsertLine?.removeFromSuperview(); dragInsertLine = nil
    }

    // MARK: Project-header drag visual (insertion line only)

    private func beginProjectDragVisual(at screenPoint: NSPoint) {
        endDragVisual()
        guard let content = window?.contentView else { return }
        let line = NSView(frame: .zero)
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        line.layer?.cornerRadius = 1
        content.addSubview(line)
        dragInsertLine = line
        moveProjectDragVisual(to: screenPoint)
    }

    private func moveProjectDragVisual(to screenPoint: NSPoint) {
        guard let window = window, let content = window.contentView else { return }
        let p = window.convertPoint(fromScreen: screenPoint)
        if let nearest = nearestProjectHeader(toWindowPoint: p) {
            let f = nearest.convert(nearest.bounds, to: content)
            dragInsertLine?.frame = NSRect(x: f.minX, y: f.maxY - 1, width: f.width, height: 2)
            dragInsertLine?.isHidden = false
        } else {
            dragInsertLine?.isHidden = true
        }
    }

    /// The project header whose vertical centre (in window coords) is nearest the given window point.
    private func nearestProjectHeader(toWindowPoint p: NSPoint) -> ProjectHeaderView? {
        stack.arrangedSubviews.compactMap { $0 as? ProjectHeaderView }.min(by: {
            abs($0.convert($0.bounds, to: nil).midY - p.y) < abs($1.convert($1.bounds, to: nil).midY - p.y)
        })
    }

    /// The task row whose vertical centre (in window coords) is nearest the given window point.
    private func nearestRow(toWindowPoint p: NSPoint) -> TaskReorderRow? {
        let rows = stack.arrangedSubviews.compactMap { $0 as? TaskReorderRow }
        return rows.min(by: {
            abs($0.convert($0.bounds, to: nil).midY - p.y) < abs($1.convert($1.bounds, to: nil).midY - p.y)
        })
    }

    private func handleManualTaskDrop(draggedID: String, at screenPoint: NSPoint) {
        guard let window = self.window else { return }
        let winPoint = window.convertPoint(fromScreen: screenPoint)
        // 1. Precise hit: a different task row (reorder + adopt its project), a project header (adopt
        //    that project), or a schedule block (time-box).
        var view = window.contentView?.hitTest(winPoint)
        while let cur = view {
            if let row = cur as? TaskReorderRow, row.taskID != draggedID {
                dropTask(draggedID, ontoRow: row.taskID); return
            }
            if let header = cur as? ProjectHeaderView {
                dropTask(draggedID, intoProject: header.projectName); return
            }
            if let drop = cur as? DropTargetView {
                _ = drop.onDrop?(draggedID); return
            }
            view = cur.superview
        }
        // 2. Fallback: dropped in the tasks panel but not exactly on a target. Reorder relative to the
        //    NEAREST task row, so a drop anywhere in the list lands somewhere sensible.
        let panelRectInWindow = convert(bounds, to: nil)
        guard panelRectInWindow.contains(NSPoint(x: winPoint.x, y: panelRectInWindow.midY)) else { return }
        if let nearest = nearestRow(toWindowPoint: winPoint), nearest.taskID != draggedID {
            dropTask(draggedID, ontoRow: nearest.taskID)
        }
    }

    /// Reorder the dragged task to sit before the target task, AND adopt the target's project (so
    /// dragging a task into another project's group reassigns it).
    private func dropTask(_ draggedID: String, ontoRow targetID: String) {
        let tasks = DayPlanTaskStore.shared.tasks(for: date)
        if let target = tasks.first(where: { $0.id == targetID }),
           var dragged = tasks.first(where: { $0.id == draggedID }),
           dragged.project != target.project {
            dragged.project = target.project
            DayPlanTaskStore.shared.update(dragged, for: date)
        }
        DayPlanTaskStore.shared.reorder(id: draggedID, before: targetID, for: date)
        reload(); onChange?()
    }

    /// Assign the dragged task to a project (dropped onto that project's header).
    private func dropTask(_ draggedID: String, intoProject project: String?) {
        let tasks = DayPlanTaskStore.shared.tasks(for: date)
        guard var dragged = tasks.first(where: { $0.id == draggedID }), dragged.project != project else { return }
        dragged.project = project
        DayPlanTaskStore.shared.update(dragged, for: date)
        reload(); onChange?()
    }

    // MARK: NSTextFieldDelegate — Enter saves the task (doesn't bubble up to start a habit)

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let field = control as? NSTextField, let id = field.identifier?.rawValue else { return false }

        // ↑/↓ move the highlighted `#project` suggestion when the list is showing; otherwise let the
        // arrow keys move the caret in the multi-line name editor as usual.
        if id.hasPrefix("name:"), suggestOverlay != nil {
            if commandSelector == #selector(NSResponder.moveDown(_:)) { return moveSuggestSelection(by: 1) }
            if commandSelector == #selector(NSResponder.moveUp(_:)) { return moveSuggestSelection(by: -1) }
        }
        // Tab accepts the highlighted `#project` suggestion if the list is showing; otherwise it jumps
        // from the name field to its duration field (the multi-line name editor would otherwise insert a
        // literal tab).
        if commandSelector == #selector(NSResponder.insertTab(_:)), id.hasPrefix("name:") {
            if suggestOverlay != nil, suggestMatches.indices.contains(suggestSelectedIndex) {
                acceptProjectSuggestion(suggestMatches[suggestSelectedIndex], keepEditing: true)
                return true
            }
            let taskID = String(id.dropFirst("name:".count))
            if case .refusedTokensOnly = saveName(field) { return true }
            if let dur = durationField(forTaskID: taskID) { window?.makeFirstResponder(dur) }
            return true
        }
        // Enter inside the "create new project" name field saves the new project.
        if commandSelector == #selector(NSResponder.insertNewline(_:)), id == "newProjectName" {
            saveNewProject(); return true
        }
        // Enter accepts the highlighted `#project` suggestion when the list is open, or creates the
        // new project when the create-prompt is open; otherwise it commits and ends editing (so it
        // can't bubble up and start a habit).
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if id.hasPrefix("name:"), suggestOverlay != nil {
                if suggestMatches.indices.contains(suggestSelectedIndex) {
                    acceptProjectSuggestion(suggestMatches[suggestSelectedIndex]); return true
                }
                if createProjectField != nil { saveNewProject(); return true }
            }
            dismissProjectSuggestions()
            if id.hasPrefix("name:") { commitName(field) } else if id.hasPrefix("dur:") { commitDuration(field) }
            window?.makeFirstResponder(nil)
            return true
        }
        // Escape in the new-project prompt dismisses it.
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            if id == "newProjectName" { dismissProjectSuggestions(); window?.makeFirstResponder(nil); return true }
            // Escape while the #project suggestion list is open just closes the list (keeps editing the name).
            if id.hasPrefix("name:"), suggestOverlay != nil { dismissProjectSuggestions(); return true }
        }
        return false
    }

    /// The duration field for a given task id in the currently-rendered rows (used by Tab navigation).
    /// Show what `!N` and `*N` will do WHILE they are typed, instead of only after the name commits.
    ///
    /// `reload()` is deliberately blocked during editing — rebuilding would tear the field down
    /// mid-keystroke — so the two affected views are updated directly rather than through a rebuild
    /// (report 2026-09-21_20-39-15, follow-up: "shouldn't need to wait until you save").
    ///
    /// Nothing is written to the store here. This is a preview of a name that is still being typed;
    /// the commit path remains the one that decides.
    private func previewNameTokens(forTaskID id: String, typed: String) {
        guard case .save(let parsed) = TaskNameCommit.forDayPlanRow(
                typed,
                knownProjects: DayPlanTaskStore.shared.allProjectNames(),
                pendingProject: pendingProjectSelections[id]) else { return }

        if let minutes = parsed.durationMinutes, let field = durationField(forTaskID: id) {
            // Never while the duration field is itself being edited — that would overwrite the
            // digits the user is typing into it.
            let editor = (window?.firstResponder as? NSTextView)?.delegate as? NSTextField
            if editor !== field {
                let shown = "\(minutes)m"
                if field.stringValue != shown { field.stringValue = shown }
            }
        }
        if let outcome = parsed.outcome { applyImportanceTint(forTaskID: id, outcome: outcome) }
    }

    /// Re-apply just the importance band to one row. Mirrors the row builder's branch, including the
    /// part that matters: a SELECTED row keeps the selection fill, which outranks the tint.
    private func applyImportanceTint(forTaskID id: String, outcome: Int) {
        guard !selectedTaskIDs.contains(id) else { return }
        guard let row = stack.arrangedSubviews.first(where: { ($0 as? TaskReorderRow)?.taskID == id }),
              let bg = DayPlanTask.outcomeColor(outcome) else { return }
        row.wantsLayer = true
        row.layer?.backgroundColor = bg.cgColor
        row.layer?.cornerRadius = 4
        row.toolTip = ForecastText.outcomeValue(outcome) + " · " + DayPlanTask.outcomeBandLabel(outcome)
    }

    private func durationField(forTaskID id: String) -> NSTextField? {
        for row in stack.arrangedSubviews {
            guard let rowStack = row as? NSStackView else { continue }
            for v in rowStack.arrangedSubviews {
                if let tf = v as? NSTextField, tf.identifier?.rawValue == "dur:\(id)" { return tf }
            }
        }
        return nil
    }

    private func struckThrough(_ s: String) -> NSAttributedString {
        NSAttributedString(string: s, attributes: [
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 13)
        ])
    }

    /// The UNfiltered list on purpose: an identity lookup, not a listing. The details sheet holds an
    /// id and must keep resolving it even at the moment the task is assigned away — otherwise saving
    /// the sheet would fail its own guard and quietly drop the title and notes edited alongside the
    /// new assignee.
    private func task(for id: String) -> DayPlanTask? {
        DayPlanTaskStore.shared.allTasks(for: date).first { $0.id == id }
    }

    // MARK: Actions

    @objc private func addFromScratchClicked() { addFromScratch(project: nil) }

    private func addFromScratch(project: String?) {
        // Don't pile up blank rows — drop any existing unnamed one first.
        for t in DayPlanTaskStore.shared.tasks(for: date)
        where t.sourceTaskId == nil && t.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            DayPlanTaskStore.shared.delete(id: t.id, for: date)
        }
        DayPlanAnalytics.capture(DayPlanAnalytics.taskAdded, ["source": "scratch", "has_project": project != nil])
        let t = DayPlanTask(title: "", project: project)
        DayPlanTaskStore.shared.add(t, for: date)
        reload()
        onChange?()
        // Focus the new row's name field AND scroll it into view so you can see the input.
        if let field = nameField(forTaskID: t.id) {
            window?.makeFirstResponder(field)
            DispatchQueue.main.async { field.scrollToVisible(field.bounds) }
        }
    }

    private func nameField(forTaskID id: String) -> NSTextField? {
        for row in stack.arrangedSubviews {
            guard let rowStack = row as? NSStackView else { continue }
            for v in rowStack.arrangedSubviews {
                if let sub = v as? NSStackView {   // name now lives inside the name column
                    for w in sub.arrangedSubviews where (w as? NSTextField)?.identifier?.rawValue == "name:\(id)" {
                        return w as? NSTextField
                    }
                }
                if let tf = v as? NSTextField, tf.identifier?.rawValue == "name:\(id)" { return tf }
            }
        }
        return nil
    }

    /// The vertical column holding a task's name field and the notes stacked under it.
    private func nameColumn(forTaskID id: String) -> NSStackView? {
        for row in stack.arrangedSubviews {
            guard let rowStack = row as? NSStackView else { continue }
            for v in rowStack.arrangedSubviews {
                if let column = v as? NSStackView, column.identifier?.rawValue == "namecol:\(id)" { return column }
            }
        }
        return nil
    }

    // MARK: Per-task action row (Expand / Snooze / Remove)

    /// Show the action row directly beneath the given task. Moving focus to another task moves the row;
    /// a reload removes it. We deliberately don't hide it on blur so clicking its own buttons works.
    private func showActionRow(forTaskID id: String) {
        if actionRowTaskID == id, actionRow?.superview != nil { return }
        actionRow?.removeFromSuperview(); actionRow = nil; actionRowTaskID = nil
        guard let idx = stack.arrangedSubviews.firstIndex(where: { ($0 as? TaskReorderRow)?.taskID == id }) else { return }
        let expand = actionButton(ScheduleText.tasksExpand, symbol: "square.and.pencil", id: id, action: #selector(expandTask(_:)))
        let snooze = actionButton(ScheduleText.tasksSnooze, symbol: "clock.arrow.circlepath", id: id, action: #selector(snoozeTask(_:)))
        let remove = actionButton(ScheduleText.tasksRemove, symbol: "trash", id: id, action: #selector(deleteTask(_:)))
        let indent = NSView()
        indent.translatesAutoresizingMaskIntoConstraints = false
        indent.widthAnchor.constraint(equalToConstant: 26).isActive = true   // line up past the grip + checkbox
        let bar = NSStackView(views: [indent, expand, snooze, remove])
        bar.orientation = .horizontal; bar.spacing = 6; bar.alignment = .centerY
        bar.translatesAutoresizingMaskIntoConstraints = false
        stack.insertArrangedSubview(bar, at: idx + 1)
        bar.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true   // share the row width so it lays out
        actionRow = bar; actionRowTaskID = id
        showShortcutCard(below: bar)
        stack.layoutSubtreeIfNeeded()
    }

    /// The card explaining what can be typed into a task name, directly under the task being edited
    /// (report 2026-09-21_07-42-02). It follows focus the way the action row above it does — one card
    /// at a time — and its ✕ retires it for every task, for good.
    ///
    /// It lists the DAY PLAN ROW grammar, which is not quite the menu composer's: a spelled "30m" is
    /// part of the name here, so the card must not offer it. See `TaskShortcutCard.Composer`.
    private func showShortcutCard(below actionRow: NSView) {
        shortcutCard?.removeFromSuperview()
        shortcutCard = nil
        guard !TaskShortcutCardPreference.isDismissedForCurrentUser,
              let index = stack.arrangedSubviews.firstIndex(of: actionRow) else { return }
        let card = TaskShortcutCardView(hints: TaskShortcutCard.hints(for: .dayPlanRow),
                                        title: TaskShortcutCard.title,
                                        dismissTooltip: TaskShortcutCard.dismissTooltip)
        card.onDismiss = { [weak self] in
            TaskShortcutCardPreference.dismissForCurrentUser()
            self?.shortcutCard = nil
        }
        stack.insertArrangedSubview(card, at: index + 1)
        card.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true   // share the row width so it lays out
        shortcutCard = card
    }

    private func actionButton(_ title: String, symbol: String, id: String, action: Selector) -> NSButton {
        let b = cursorButton(title: " " + title, target: self, action: action)
        b.bezelStyle = .rounded
        b.controlSize = .small
        b.font = .systemFont(ofSize: 11)
        b.identifier = NSUserInterfaceItemIdentifier(id)
        if #available(macOS 11.0, *) {
            b.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            b.imagePosition = .imageLeading
        }
        return b
    }

    @objc private func expandTask(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        openTaskModal(taskID: id, from: sender)
    }

    @objc private func subtaskCountClicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        openTaskModal(taskID: id, from: sender)
    }

    // MARK: Multi-select bulk actions

    private func toggleSelection(_ id: String) {
        if selectedTaskIDs.contains(id) { selectedTaskIDs.remove(id) } else { selectedTaskIDs.insert(id) }
        reloadAfterUserAction()
    }

    /// The "N selected · Snooze · Remove · Clear" bar shown at the top of the list while ≥1 task is
    /// multi-selected. Returns nil when nothing is selected.
    /// Populate the sticky `bulkBarHost` from the current selection. When a bar exists it's pinned to
    /// all four host edges (with a 12pt bottom inset that supplies the gap to the scroll list) and the
    /// collapse constraint is deactivated; when nothing is selected the host is emptied and collapses
    /// back to 0 height so the task list sits directly under the header.
    private func refreshBulkBar() {
        bulkBarHost.subviews.forEach { $0.removeFromSuperview() }
        guard let bar = makeBulkBar() else {
            bulkBarHostEmptyHeight?.isActive = true
            return
        }
        bulkBarHostEmptyHeight?.isActive = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        bulkBarHost.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: bulkBarHost.topAnchor),
            bar.leadingAnchor.constraint(equalTo: bulkBarHost.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: bulkBarHost.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: bulkBarHost.bottomAnchor, constant: -12),
        ])
    }

    private func makeBulkBar() -> NSView? {
        guard !selectedTaskIDs.isEmpty else { return nil }
        let count = label(String(format: ScheduleText.tasksSelectedCount, selectedTaskIDs.count), size: 11, bold: true)
        count.textColor = .controlAccentColor
        let snooze = cursorButton(title: " " + ScheduleText.tasksSnooze, target: self, action: #selector(bulkSnoozeClicked(_:)))
        snooze.bezelStyle = .rounded; snooze.controlSize = .small
        let remove = cursorButton(title: " " + ScheduleText.tasksRemove, target: self, action: #selector(bulkRemoveClicked))
        remove.bezelStyle = .rounded; remove.controlSize = .small
        let clear = cursorButton(title: ScheduleText.tasksClearSelection, target: self, action: #selector(clearSelectionClicked))
        clear.bezelStyle = .rounded; clear.controlSize = .small; clear.isBordered = false
        if #available(macOS 11.0, *) {
            snooze.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: nil); snooze.imagePosition = .imageLeading
            remove.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil); remove.imagePosition = .imageLeading
        }
        let bar = NSStackView(views: [count, snooze, remove, clear])
        bar.orientation = .horizontal; bar.spacing = 8; bar.alignment = .centerY
        return bar
    }

    @objc private func bulkSnoozeClicked(_ sender: NSButton) {
        guard !selectedTaskIDs.isEmpty else { return }
        snoozeBulk = true; snoozeTaskID = nil
        presentSnoozePopover(from: sender)
    }

    @objc private func bulkRemoveClicked() {
        DayPlanAnalytics.capture(DayPlanAnalytics.taskRemoved, ["bulk": true, "count": selectedTaskIDs.count])
        for id in selectedTaskIDs { DayPlanTaskStore.shared.delete(id: id, for: date) }
        selectedTaskIDs.removeAll()
        reloadAfterUserAction(); onChange?()
    }

    @objc private func clearSelectionClicked() {
        selectedTaskIDs.removeAll(); reloadAfterUserAction()
    }

    // MARK: "Fix" — turning the over-capacity warning into an action

    /// The habits the routine route offers, longest first. Supplied by the host, because the Day Plan's
    /// blocks live on the schedule controller, not in this panel.
    var dayFixHabits: (() -> [DayFixHabitRow])?
    /// Skip / un-skip one habit for this day, then reload. The host owns both, so the Fix modal drives
    /// exactly the same paths the row's own ⏭ and ⏱ buttons do rather than a second implementation.
    var dayFixSkipHabit: ((String) -> Void)?
    var dayFixShortenHabit: ((String) -> Void)?
    /// The day's remaining meetings, longest first, and the three things the modal can do to one.
    /// Supplied by the host for the same reason as the habits: the meetings and the editor's
    /// confirm → scope → remove flow belong to the schedule controller.
    var dayFixMeetings: (() -> [DayFixMeetingRow])?
    var dayFixSkipMeeting: ((DayFixMeetingRow) -> Void)?
    var dayFixCancelMeeting: ((DayFixMeetingRow) -> Void)?
    var dayFixShortenMeeting: ((DayFixMeetingRow) -> Void)?

    private var dayFixSheet: NSViewController?

    /// Every route in here must move the number at the top — that is what "make the plan feasible"
    /// means — so a route with nothing behind it is not offered at all.
    @objc private func openDayFixModal() {
        let load = LocalTimeForecast.dayLoad(day: date, capacityMinutes: Double(scheduleFreeMinutes ?? 0),
                                             plannedMinutes: Double(remainingMins),
                                             absorbedMinutes: forecastAbsorbedMinutes)
        let habits = dayFixHabits?() ?? []
        let habitMinutes = habits.filter { !$0.isSkipped }.reduce(0.0) { $0 + Double($1.seconds) / 60 }
        let meetings = dayFixMeetings?() ?? []
        // A meeting already skipped for the day costs the day nothing, so it cannot free anything
        // either — same rule the habits follow.
        let meetingMinutes = meetings.filter { !$0.isSkipped }.reduce(0.0) { $0 + Double($1.seconds) / 60 }
        let options = DayFixPlan.options(meetingMinutes: meetingMinutes, habitMinutes: habitMinutes,
                                         taskMinutes: Double(remainingMins))
        var sheet: DayPlanSheetController!
        let view = DayFixView(
            overcommittedMinutes: load.overcommittedMinutes,
            options: options,
            meetings: meetings,
            habits: habits,
            onSkip: { [weak self] id in self?.dayFixSkipHabit?(id); self?.closeDayFixSheet(sheet) },
            onShorten: { [weak self] id in self?.closeDayFixSheet(sheet); self?.dayFixShortenHabit?(id) },
            onSkipMeeting: { [weak self] row in self?.dayFixSkipMeeting?(row); self?.closeDayFixSheet(sheet) },
            onCancelMeeting: { [weak self] row in self?.closeDayFixSheet(sheet); self?.dayFixCancelMeeting?(row) },
            onShortenMeeting: { [weak self] row in self?.closeDayFixSheet(sheet); self?.dayFixShortenMeeting?(row) },
            // The sheet is told WHICH day it was asked to fix, and the shortfall the user was just
            // shown. Without that it opens as a whole-backlog re-prioritisation and the proposals
            // that clear this day land in the collapsed "Minor changes" pile, which is exactly where
            // they were invisible (report 2026-09-16_22-22-50, follow-up). The number travels with
            // the day so the sheet quotes the figure on this banner rather than recomputing its own.
            onPostponeTasks: { [weak self] in
                guard let self = self else { return }
                self.closeDayFixSheet(sheet)
                showReprioritisePlanWindow(focusing: .init(day: self.date,
                                                           shortfallMinutes: load.overcommittedMinutes))
            },
            onClose: { [weak self] in self?.closeDayFixSheet(sheet) })
        sheet = DayPlanSheetController(size: NSSize(width: 420, height: 420), content: view)
        dayFixSheet = sheet
        enclosingViewController?.presentAsSheet(sheet)
    }

    private func closeDayFixSheet(_ sheet: NSViewController?) {
        if let sheet = sheet { enclosingViewController?.dismiss(sheet) }
        dayFixSheet = nil
    }

    // MARK: Task detail modal (title, project, duration, description, sub-tasks)

    private func openTaskModal(taskID: String, from anchor: NSView) {
        guard let task = task(for: taskID) else { return }
        DayPlanAnalytics.capture(DayPlanAnalytics.taskSettingsOpened, ["from_todo": task.sourceTaskId != nil])
        // Re-read in case the downloaded config landed after this panel was built.
        attachmentStrings = ToDoStrings.load()
        modalTaskID = taskID
        modalSubtasks = task.subtaskList

        let header = label(ScheduleText.tasksDetailsTitle, size: 14, bold: true)

        let titleField = NSTextField(string: task.title)
        titleField.placeholderString = ScheduleText.tasksNamePlaceholder
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.widthAnchor.constraint(equalToConstant: 320).isActive = true
        // "taskModal…" identifier tells AppDelegate's global Return-key monitor to let this field
        // handle Return itself instead of advancing/starting the current habit — see the matching
        // allowlist check there.
        titleField.identifier = NSUserInterfaceItemIdentifier("taskModalTitle")
        modalTitleField = titleField

        // Searchable dropdown of known projects (still free-text, so a new project can be typed).
        let projectField = NSComboBox()
        projectField.completes = false   // prefix-only completion is misleading; we substring-filter the list instead
        projectField.hasVerticalScroller = true
        projectField.numberOfVisibleItems = 10
        projectField.identifier = NSUserInterfaceItemIdentifier("projectFilter")
        projectField.delegate = self
        projectField.addItems(withObjectValues: DayPlanTaskStore.shared.allProjectNames())
        // The backend project list is fetched once when the Day Plan loads, so a project created
        // later in the To-do list was missing here — typing its name offered nothing
        // (report 2026-09-11_21-37-03). Refresh while the modal is open and re-filter what the user
        // has already typed once the newer list lands.
        DayPlanTaskStore.shared.refreshRemoteProjects { [weak self, weak projectField] loaded in
            guard loaded, let self = self, let field = projectField, field.window != nil else { return }
            // Re-stock only. Offering a suggestion overlay here popped the task's own project name
            // over the Duration row the moment the popover opened (report 2026-09-16_09-25-06).
            self.restockProjectCombo(field)
        }
        projectField.stringValue = task.project ?? ""
        projectField.placeholderString = ScheduleText.tasksProjectField
        projectField.translatesAutoresizingMaskIntoConstraints = false
        projectField.widthAnchor.constraint(equalToConstant: 220).isActive = true
        modalProjectField = projectField

        let durationField = NSTextField(string: "\(task.durationMinutes)")
        durationField.translatesAutoresizingMaskIntoConstraints = false
        durationField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        durationField.identifier = NSUserInterfaceItemIdentifier("taskModalDuration")
        modalDurationField = durationField

        // Outcome displays 1–5; the menu item tag retains the server's /10 value.
        let importancePopup = NSPopUpButton()
        importancePopup.addItem(withTitle: ScheduleText.tasksImportanceUnset)   // index 0 = unset
        for value in 1...5 {
            importancePopup.addItem(withTitle: "\(value) / 5 · \(ForecastText.outcomeLabel(value * 2))")
            importancePopup.lastItem?.tag = value * 2
        }
        if let old = task.outcome, old % 2 != 0 {
            importancePopup.addItem(withTitle: ForecastText.outcomeValue(old) + " · " + ForecastText.outcomeLabel(old))
            importancePopup.lastItem?.tag = old
        }
        importancePopup.selectItem(withTag: task.outcome ?? 0)
        importancePopup.target = self; importancePopup.action = #selector(modalImportanceChanged(_:))
        modalImportancePopup = importancePopup
        let importanceSwatch = NSView()
        importanceSwatch.wantsLayer = true
        importanceSwatch.translatesAutoresizingMaskIntoConstraints = false
        importanceSwatch.widthAnchor.constraint(equalToConstant: 14).isActive = true
        importanceSwatch.heightAnchor.constraint(equalToConstant: 14).isActive = true
        importanceSwatch.layer?.cornerRadius = 7
        modalImportanceSwatch = importanceSwatch
        updateImportanceSwatch(task.outcome)
        let importanceRow = NSStackView(views: [importancePopup, importanceSwatch])
        importanceRow.orientation = .horizontal; importanceRow.spacing = 8; importanceRow.alignment = .centerY

        // A bare NSTextView has a zero frame and the scroll view won't size it, so its text shows
        // blank — configure size + resizing explicitly.
        let notesView = NewlineKeepingTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 70))
        notesView.minSize = NSSize(width: 0, height: 0)
        notesView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        notesView.isVerticallyResizable = true
        // Long URLs need a scrollable document width, not just a scrollbar on a fixed-width view.
        notesView.isHorizontallyResizable = true
        notesView.autoresizingMask = []
        notesView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                                       height: CGFloat.greatestFiniteMagnitude)
        notesView.textContainer?.widthTracksTextView = false
        notesView.font = .systemFont(ofSize: 13)
        notesView.isRichText = false
        notesView.textContainerInset = NSSize(width: 4, height: 4)
        notesView.string = task.notes ?? ""
        // Without this identifier, AppDelegate's global Return-key monitor (which advances/starts the
        // current habit on Enter) sees an unrecognised field and hijacks Return before it ever reaches
        // NewlineKeepingTextView.performKeyEquivalent below — Enter would start the next habit instead
        // of inserting a newline. See the matching allowlist check there.
        notesView.identifier = NSUserInterfaceItemIdentifier("taskModalNotes")
        modalNotesView = notesView
        let notesScroll = NSScrollView()
        notesScroll.documentView = notesView
        notesScroll.hasVerticalScroller = true
        notesScroll.hasHorizontalScroller = true
        notesScroll.autohidesScrollers = false
        notesScroll.scrollerStyle = .legacy // Overlay scrollers disappear even when autohiding is disabled.
        notesScroll.borderType = .bezelBorder
        notesScroll.translatesAutoresizingMaskIntoConstraints = false
        notesScroll.widthAnchor.constraint(equalToConstant: 320).isActive = true
        notesScroll.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let subtaskStack = NSStackView()
        subtaskStack.orientation = .vertical; subtaskStack.alignment = .leading; subtaskStack.spacing = 4
        subtaskStack.translatesAutoresizingMaskIntoConstraints = false
        modalSubtaskStack = subtaskStack

        // The shared add control, not an NSButton dressed up to look like one: "Add file…" sits two
        // rows below this and the pair drifted apart the moment they were written separately
        // (report 2026-09-15_11-16-30 follow-up). See `AddItemButton`.
        let addSub = AddItemButton.hosted(title: ScheduleText.tasksAddSubtask) { [weak self] in
            self?.addSubtaskClicked()
        }

        // Attachments: the very same store, rows, picker and preview the to-do editor uses
        // (`ToDoAttachments.swift`) — asked for in report 2026-09-15_20-54-33. A Day Plan row is only
        // backed by a to-do once it has been minted (`mintTodoIfNeeded`), and the endpoint is
        // `/to-do/:id/attachments`, so a row with no `sourceTaskId` shows the unavailable state.
        // Reuse the store when re-opening the SAME task — the file picker and the preview both close
        // this modal and re-open it afterwards, and a fresh store would throw away an upload in flight.
        let attachments = modalAttachments.flatMap { $0.taskId == task.sourceTaskId ? $0 : nil }
            ?? ToDoAttachmentsStore(taskId: task.sourceTaskId, strings: attachmentStrings,
                                    showStatus: { [weak self] message in self?.showAttachmentStatus(message) })
        attachments.onCountChanged = { [weak self] count in
            self?.recordAttachmentCount(count, forTaskID: taskID)
        }
        modalAttachments = attachments
        attachments.load()
        let attachmentsHost = NSHostingView(rootView: ToDoAttachmentsList(
            store: attachments,
            strings: attachmentStrings,
            unavailableMessage: attachmentStrings[.attachmentsNeedTodo],
            maximumListHeight: Self.modalAttachmentsMaxHeight,
            onPreview: { [weak self] attachment in self?.previewTaskAttachment(attachment) },
            onAdd: { [weak self] in self?.chooseTaskAttachment() },
            // ⌘V before the row has a to-do. `canHold` is asked at the key press, so a task minted
            // while this sheet sits open answers yes even though the store was built saying no —
            // which is exactly the window the paste kept falling into
            // (report 2026-09-15_20-54-33, fourth round).
            pendingImage: ToDoPendingImageSink(
                canHold: { [weak self] in self?.canHoldPastedImage(forTaskID: taskID) ?? false },
                hold: { [weak self] image in self?.holdPastedImage(image, forTaskID: taskID) }),
            pasteLabel: "dayplan-details"))
        attachmentsHost.translatesAutoresizingMaskIntoConstraints = false
        attachmentsHost.widthAnchor.constraint(equalToConstant: Self.modalFieldWidth).isActive = true

        // Who the task is assigned to. Built hidden and revealed only once the project's members are
        // known and there is somebody other than the user to pick — asked for as "if the project has
        // other members" (report 2026-09-17_09-01-33). A plain popup, not the searchable combo the
        // project field uses: a member list is a handful of names, and a search box over three entries
        // is more control than the job needs.
        let assigneePopup = NSPopUpButton()
        assigneePopup.target = self
        assigneePopup.action = #selector(modalAssigneeChanged(_:))
        modalAssigneePopup = assigneePopup
        let assigneeLabel = label(attachmentStrings[.assignee], size: 12, bold: false)
        assigneeLabel.textColor = .secondaryLabelColor
        assigneeLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        let assigneeRow = NSStackView(views: [assigneeLabel, assigneePopup])
        assigneeRow.orientation = .horizontal; assigneeRow.alignment = .firstBaseline; assigneeRow.spacing = 8
        assigneeRow.isHidden = true
        modalAssigneeRow = assigneeRow
        refreshAssigneeControl(for: task)

        // Shown the moment a ⌘V is taken and hidden when the upload finishes, so a picture that is
        // waiting on a mint is never invisible. The menu's quick-add has the same chip.
        let pendingPaste = label(attachmentStrings[.attachmentPastePending], size: 11, bold: false)
        pendingPaste.textColor = .secondaryLabelColor
        pendingPaste.isHidden = !pendingPasteTaskIDs.contains(taskID)
        modalPendingPasteLabel = pendingPaste

        let cancel = cursorButton(title: ScheduleText.eventCancel, target: self, action: #selector(cancelTaskModal))
        cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"
        let save = cursorButton(title: ScheduleText.eventSave, target: self, action: #selector(saveTaskModal))
        save.bezelStyle = .rounded; save.keyEquivalent = "\r"
        let buttons = NSStackView(views: [NSView(), cancel, save])
        buttons.orientation = .horizontal; buttons.spacing = 8

        func row(_ text: String, _ control: NSView) -> NSStackView {
            let l = label(text, size: 12, bold: false); l.textColor = .secondaryLabelColor
            l.widthAnchor.constraint(equalToConstant: 80).isActive = true
            let s = NSStackView(views: [l, control]); s.orientation = .horizontal; s.alignment = .firstBaseline; s.spacing = 8
            return s
        }

        let form = NSStackView(views: [
            header,
            titleField,
            row(ScheduleText.tasksProjectLabel, projectField),
            row(ScheduleText.tasksDurationLabel, durationField),
            row(ForecastText[.outcome], importanceRow),
            assigneeRow,
            label(ScheduleText.tasksDetailsLabel, size: 12, bold: false),
            notesScroll,
            label(ScheduleText.tasksSubtasksLabel, size: 12, bold: false),
            subtaskStack,
            addSub,
            label(attachmentStrings[.attachments], size: 12, bold: false),
            attachmentsHost,
            pendingPaste,
            buttons,
        ])
        form.orientation = .vertical; form.alignment = .leading; form.spacing = 10
        form.translatesAutoresizingMaskIntoConstraints = false
        buttons.widthAnchor.constraint(equalTo: titleField.widthAnchor).isActive = true

        rebuildSubtaskRows()

        let container = NSView()
        container.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            form.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        let vc = NSViewController(); vc.view = container
        let pop = NSPopover(); pop.contentViewController = vc; pop.behavior = .transient
        pop.delegate = self
        // Keep Return inside the modal from starting a habit while it's open.
        snoozeSavedDefaultButton = snoozeSavedDefaultButton ?? window?.defaultButtonCell
        window?.defaultButtonCell = nil
        pop.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        taskModalPopover = pop
        vc.view.window?.makeFirstResponder(titleField)
    }

    /// Identifier prefix for a sub-task row's text field; the suffix is its index in `modalSubtasks`.
    private var subtaskFieldPrefix: String { "taskModalSubtask:" }

    /// Re-render the sub-task rows from `modalSubtasks`. Each row is [checkbox, title field, ✕].
    private func rebuildSubtaskRows() {
        guard let stackV = modalSubtaskStack else { return }
        stackV.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, sub) in modalSubtasks.enumerated() {
            let check = cursorButton(checkboxWithTitle: "", target: nil, action: nil)
            check.state = sub.done ? .on : .off
            check.tag = i
            let field = SubtaskTextField(string: sub.title)
            field.placeholderString = ScheduleText.tasksSubtaskPlaceholder
            field.tag = i
            field.delegate = self          // every keystroke lands in modalSubtasks, not just on Save
            field.onReturn = { [weak self] in self?.addSubtaskClicked() }
            field.identifier = NSUserInterfaceItemIdentifier("\(subtaskFieldPrefix)\(i)")
            field.translatesAutoresizingMaskIntoConstraints = false
            field.widthAnchor.constraint(equalToConstant: 250).isActive = true
            let del = cursorButton(title: "✕", target: self, action: #selector(deleteSubtaskClicked(_:)))
            del.bezelStyle = .circular; del.controlSize = .small; del.tag = i
            let r = NSStackView(views: [check, field, del])
            r.orientation = .horizontal; r.spacing = 6; r.alignment = .centerY
            stackV.addArrangedSubview(r)
        }
    }

    /// Pull the current checkbox states + titles back into `modalSubtasks` before any structural change.
    private func syncSubtasksFromFields() {
        guard let stackV = modalSubtaskStack else { return }
        for r in stackV.arrangedSubviews {
            guard let rs = r as? NSStackView,
                  let check = rs.arrangedSubviews.first as? NSButton,
                  let field = rs.arrangedSubviews.first(where: { $0 is NSTextField }) as? NSTextField,
                  modalSubtasks.indices.contains(field.tag) else { continue }
            modalSubtasks[field.tag].title = field.stringValue
            modalSubtasks[field.tag].done = (check.state == .on)
        }
    }

    @objc private func addSubtaskClicked() {
        syncSubtasksFromFields()
        modalSubtasks.append(DayPlanSubtask(title: ""))
        rebuildSubtaskRows()
        if let last = (modalSubtaskStack?.arrangedSubviews.last as? NSStackView)?
            .arrangedSubviews.first(where: { $0 is NSTextField }) {
            // The rows live in the popover's window, not the panel's — `window` here is the wrong one.
            last.window?.makeFirstResponder(last)
        }
    }

    @objc private func deleteSubtaskClicked(_ sender: NSButton) {
        syncSubtasksFromFields()
        guard modalSubtasks.indices.contains(sender.tag) else { return }
        modalSubtasks.remove(at: sender.tag)
        rebuildSubtaskRows()
    }

    /// Cancel button: the one dismissal that throws the edits away.
    @objc private func cancelTaskModal() {
        dismissTaskModal()
    }

    /// Tear the modal down without saving. Detaching the delegate first stops `popoverWillClose`
    /// from treating a deliberate Save/Cancel as an accidental click-away.
    private func dismissTaskModal() {
        taskModalPopover?.delegate = nil
        taskModalPopover?.close(); taskModalPopover = nil; modalTaskID = nil
        if let cell = snoozeSavedDefaultButton { window?.defaultButtonCell = cell; snoozeSavedDefaultButton = nil }
    }

    /// Clicking outside a transient popover is not "discard" — it is usually an accident mid-edit, and
    /// losing a half-typed sub-task list to it is the bug in report 2026-09-14_09-17-51. Cancel (or Esc)
    /// stays the way to throw the edits away.
    func popoverWillClose(_ notification: Notification) {
        guard (notification.object as? NSPopover) === taskModalPopover else { return }
        saveTaskModal()
    }

    @objc private func saveTaskModal() {
        // Before reading the task: the row's own blur commit writes to the store (see commitTaskDetails).
        endNameEditing()
        guard let id = modalTaskID, var t = task(for: id) else { dismissTaskModal(); return }
        syncSubtasksFromFields()
        let newTitle = (modalTitleField?.stringValue ?? t.title).trimmingCharacters(in: .whitespacesAndNewlines)
        if !newTitle.isEmpty { t.title = newTitle }
        let proj = (modalProjectField?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        t.project = proj.isEmpty ? nil : proj
        if let mins = QuickAddTaskParser.durationMinutes(fromFieldText: modalDurationField?.stringValue ?? "") {
            t.durationMinutes = mins
        }
        let notes = (modalNotesView?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        t.notes = notes.isEmpty ? nil : notes
        let imp = modalImportancePopup?.selectedItem?.tag ?? 0 // Wire /10; zero is unset.
        t.outcome = imp >= 1 ? imp : nil
        let cleaned = modalSubtasks
            .map { DayPlanSubtask(id: $0.id, title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines), done: $0.done) }
            .filter { !$0.title.isEmpty }
        t.subtasks = cleaned.isEmpty ? nil : cleaned
        dismissTaskModal()
        commitTaskDetails(t)
    }

    /// Store what the details popover saved, push a changed title to the backing to-do, and redraw.
    ///
    /// Clicking a task's name to reach Expand leaves that row's name field holding the field editor.
    /// With it still focused, `reload()` defers the redraw — so the row kept its old title, duration
    /// and planned total — and the eventual blur ran `saveName` on the field's OLD text, writing the
    /// old title back over the one just saved (#2679). Editing is ended first, so that blur commits
    /// before this write rather than after it. The title also has to reach the to-do: the next to-do
    /// refresh (`mergeDueTodos`) copies the server's title onto the row.
    func commitTaskDetails(_ edited: DayPlanTask) {
        endNameEditing()
        let titleBeforeSave = task(for: edited.id)?.title
        DayPlanTaskStore.shared.update(edited, for: date)
        if TaskNameCommit.needsSync(originalTitle: titleBeforeSave, committedTitle: edited.title,
                                    isBackedByTodo: edited.sourceTaskId != nil) {
            DayPlanTaskStore.shared.syncNameOnCommit(edited, on: date)
        }
        reload(); onChange?()
    }

    // MARK: Task attachments (shared with the to-do editor — see ToDoAttachments.swift)

    /// Pick a file to attach, and preview one: both need a window-level panel, and the task modal is a
    /// TRANSIENT popover that dismisses itself the moment a sheet takes key focus. So the modal is
    /// closed deliberately first — through `saveTaskModal`, which is exactly what clicking outside it
    /// does, so the user's edits are kept — rather than leaving a sheet floating over a half-vanished
    /// form (the same trap `ScheduleViewController.cancelOrDeclineEvent` documents).
    private func chooseTaskAttachment() {
        guard let attachments = modalAttachments, let taskID = modalTaskID else { return }
        saveTaskModal()
        ToDoAttachmentPicker.present(from: window) { [weak self] url in
            attachments.attach(url)
            // A refused file (too big, task already full) has put its own sheet on the window — leave it
            // there. An accepted one is uploading, so go straight back to the details where the spinner
            // and then the new row are somewhere the user can see them.
            guard attachments.isUploading else { return }
            self?.reopenTaskModal(taskID: taskID)
        }
    }

    /// Can a ⌘V on this task go anywhere — now, or once its to-do exists?
    ///
    /// Asked at the key press. Yes when the row is already backed, and yes when it has a name, because
    /// a named row is minted (`syncNameOnCommit`). A row with no name never is, so ⌘V is left alone
    /// there rather than swallowed into a picture nothing will ever upload.
    private func canHoldPastedImage(forTaskID id: String) -> Bool {
        guard let task = task(for: id) else { return false }
        if task.sourceTaskId != nil { return true }
        return !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Take a pasted image now and upload it when the task has a to-do to hang it off.
    ///
    /// The same shape as the menu's quick-add, deliberately: the picture is held, the sheet says so,
    /// and `whenBackedByTodo` — which fires exactly once on every path, including a failed mint —
    /// decides whether it is uploaded or the user is told it could not be.
    private func holdPastedImage(_ image: ToDoPastedImage, forTaskID id: String) {
        guard let task = task(for: id) else { return }
        // Already backed by the time the key landed: the store was built before the mint returned, so
        // go straight to the upload rather than waiting for an announcement that has already happened.
        if let todoId = task.sourceTaskId {
            addLog(text: "paste image: task already backed, uploading now")
            uploadPastedImage(image, toTodo: todoId, localId: id)
            return
        }
        addLog(text: "paste image: held pending mint for local task \(id)")
        showPendingPaste(true, forTaskID: id)
        // A row whose name was typed but never committed has no mint in flight; this starts one.
        // It is a no-op for a task already being minted.
        DayPlanTaskStore.shared.syncNameOnCommit(task, on: date)
        DayPlanTaskStore.shared.whenBackedByTodo(localId: id) { [weak self] todoId in
            guard let self = self else { return }
            guard let todoId = todoId else {
                addLog(text: "paste image: mint failed, the held image cannot be uploaded")
                self.showPendingPaste(false, forTaskID: id)
                self.showAttachmentStatus(self.attachmentStrings[.attachmentFailed])
                return
            }
            addLog(text: "paste image: task minted, uploading the held image")
            self.uploadPastedImage(image, toTodo: todoId, localId: id)
        }
    }

    /// Send the picture through the ordinary attachment upload — same limits, same error message.
    ///
    /// A store built here is referenced by nothing else, so it is held until the upload reports back;
    /// without that it is deallocated mid-request and the picture vanishes silently. Failures are
    /// reported by the store's own status callback, so this completion only cleans up — reporting
    /// again here would put two alerts on screen for one paste.
    private func uploadPastedImage(_ image: ToDoPastedImage, toTodo todoId: String, localId: String) {
        let store = modalAttachments.flatMap { $0.taskId == todoId ? $0 : nil }
            ?? ToDoAttachmentsStore(taskId: todoId, strings: attachmentStrings,
                                    showStatus: { [weak self] message in self?.showAttachmentStatus(message) })
        let isBorrowed = store === modalAttachments
        if !isBorrowed { pastedImageUploads.append(store) }
        showPendingPaste(true, forTaskID: localId)
        store.attach(pasted: image) { [weak self] ok in
            guard let self = self else { return }
            if !isBorrowed { self.pastedImageUploads.removeAll { $0 === store } }
            self.showPendingPaste(false, forTaskID: localId)
            addLog(text: "paste image: upload finished ok=\(ok)")
        }
    }

    /// Show or hide the "waiting" line, both in the sheet that is open now and in the one that will be
    /// rebuilt after the picker or the preview closes it.
    private func showPendingPaste(_ pending: Bool, forTaskID id: String) {
        DispatchQueue.main.async {
            if pending { self.pendingPasteTaskIDs.insert(id) } else { self.pendingPasteTaskIDs.remove(id) }
            guard self.modalTaskID == id else { return }
            self.modalPendingPasteLabel?.isHidden = !pending
        }
    }

    // MARK: Assignee

    /// Fill the assignee popup and show it only if this project has somebody else in it.
    ///
    /// Members are cached per project, so re-opening a sheet is instant; the first open for a project
    /// fetches them and reveals the row when they land. While it is unknown the row simply is not
    /// there — better than a picker that says "Loading…" and might turn out to have one entry.
    private func refreshAssigneeControl(for task: DayPlanTask) {
        guard let projectName = task.project, !projectName.isEmpty,
              let projectID = DayPlanTaskStore.shared.remoteProjectID(named: projectName),
              task.sourceTaskId != nil else {
            // No project, or no backing to-do to write an assignment to.
            modalAssigneeRow?.isHidden = true
            return
        }
        if let cached = DayPlanTaskStore.shared.cachedProjectMembers(projectID: projectID) {
            applyAssigneeOptions(cached, for: task)
            return
        }
        let taskID = task.id
        DayPlanTaskStore.shared.loadProjectMembers(projectID: projectID) { [weak self] members in
            // The sheet may have been closed or moved on to another task while we asked.
            guard let self = self, self.modalTaskID == taskID, let current = self.task(for: taskID) else { return }
            self.applyAssigneeOptions(members, for: current)
        }
    }

    private func applyAssigneeOptions(_ members: [ToDoAssigneeOption], for task: DayPlanTask) {
        guard let popup = modalAssigneePopup else { return }
        let myId = appdelegate?.user?.userId
        let me = myId.flatMap { id -> ToDoAssigneeOption? in
            guard !id.isEmpty else { return nil }
            return ToDoAssigneeOption(id: id, label: "\(attachmentStrings[.me]) (\(appdelegate?.user?.email ?? ""))")
        }
        let current = task.assigneeId.map {
            ToDoAssigneeOption(id: $0, label: task.assigneeName ?? $0)
        }
        let options = ToDoAssigneeChoices.options(me: me, members: members, current: current)
        guard ToDoAssigneeChoices.canAssign(options: options, currentAssigneeId: task.assigneeId,
                                            meId: myId) else {
            modalAssigneeRow?.isHidden = true
            return
        }
        popup.removeAllItems()
        // Unassigned stays reachable whatever else is on the list — the way back to nobody.
        popup.addItem(withTitle: attachmentStrings[.unassigned])
        popup.lastItem?.representedObject = ToDoAssigneeChoices.unassignedTag
        for option in options {
            popup.addItem(withTitle: option.label)
            popup.lastItem?.representedObject = option.id
        }
        let selected = task.assigneeId ?? ToDoAssigneeChoices.unassignedTag
        let index = popup.itemArray.firstIndex { ($0.representedObject as? String) == selected } ?? 0
        popup.selectItem(at: index)
        modalAssigneeShown = task.assigneeId
        modalAssigneeRow?.isHidden = false
    }

    /// Write the new assignment straight away — this popup is not part of the Save button's draft, the
    /// same way the attachment list is not.
    @objc private func modalAssigneeChanged(_ sender: NSPopUpButton) {
        guard let taskID = modalTaskID, let task = task(for: taskID), let todoID = task.sourceTaskId else { return }
        let chosen = (sender.selectedItem?.representedObject as? String).flatMap { $0.isEmpty ? nil : $0 }
        guard chosen != modalAssigneeShown else { return }
        let previous = modalAssigneeShown
        modalAssigneeShown = chosen
        var updated = task
        updated.assigneeId = chosen
        updated.assigneeName = sender.selectedItem?.title
        DayPlanTaskStore.shared.update(updated, for: date)
        DayPlanSync.shared.setTodoAssignee(todoID: todoID, title: task.title,
                                           quadrant: task.eisenhowerQuadrant ?? kDayPlanNeutralQuadrant,
                                           assigneeID: chosen) { [weak self] succeeded in
            guard let self = self, !succeeded else { return }
            // Refused — most likely backend#2413, which lets only the task's creator write to it. Put
            // the old value back rather than leaving a menu showing an assignment the server rejected.
            addLog(text: "DayPlanSync setTodoAssignee refused; restoring \(previous ?? "unassigned")")
            var reverted = task
            reverted.assigneeId = previous
            DayPlanTaskStore.shared.update(reverted, for: self.date)
            self.modalAssigneeShown = previous
            if self.modalTaskID == taskID { self.applyAssigneeOptions(
                DayPlanTaskStore.shared.cachedProjectMembers(projectID: task.projectID ?? "") ?? [], for: reverted) }
            self.showAttachmentStatus(self.attachmentStrings[.assigneeNotChanged])
        }
    }

    private func previewTaskAttachment(_ attachment: ToDoAttachment) {
        guard let taskID = modalTaskID, let host = enclosingViewController else { return }
        saveTaskModal()
        // The controller owns dismissal — the ✕ and Esc both reach it, so the details cannot come back
        // for one and not the other. Sizing lives there too.
        let controller = ToDoAttachmentPreviewSheetController(
            attachment: attachment, strings: attachmentStrings,
            onClose: { [weak self] in self?.reopenTaskModal(taskID: taskID) })
        host.presentAsSheet(controller)
    }

    /// Bring the task details back after a sheet has had the window. Both attachment entry points have
    /// to close the modal first, and leaving it closed would hide the very thing the user just did.
    private func reopenTaskModal(taskID: String) {
        showActionRow(forTaskID: taskID)
        guard let anchor = (actionRow as? NSStackView)?.arrangedSubviews
            .compactMap({ $0 as? NSButton })
            .first(where: { $0.identifier?.rawValue == taskID }) else { return }
        openTaskModal(taskID: taskID, from: anchor)
    }

    /// Cache how many files the task has, so the list can draw a paperclip without asking the server
    /// per row. Deliberately does NOT reload: the details popover is anchored to a row that a reload
    /// would rebuild out from under it. The badge appears the next time the list is built, which is
    /// what closing the details does anyway.
    private func recordAttachmentCount(_ count: Int, forTaskID id: String) {
        guard var task = task(for: id), task.attachmentCount != count else { return }
        task.attachmentCount = count
        DayPlanTaskStore.shared.update(task, for: date)
    }

    /// The Day Plan has no status banner of its own, so an attachment problem ("too large", "that
    /// failed") gets a sheet. A refusal lands while the modal is still closed by the picker; a later
    /// upload failure closes it again on its way in, which saves the edits exactly as clicking outside
    /// would. Either way the user is told, rather than the file quietly not arriving.
    private func showAttachmentStatus(_ message: String) {
        let alert = NSAlert()
        alert.messageText = attachmentStrings[.attachments]
        alert.informativeText = message
        alert.addButton(withTitle: attachmentStrings[.close])
        alert.presentAsSheet(for: window)
    }

    /// The view controller this panel is installed in, for presenting a sheet from an NSView.
    private var enclosingViewController: NSViewController? {
        var responder: NSResponder? = self
        while let next = responder?.nextResponder {
            if let controller = next as? NSViewController { return controller }
            responder = next
        }
        return nil
    }

    @objc private func modalImportanceChanged(_ sender: NSPopUpButton) {
        let wire = sender.selectedItem?.tag ?? 0
        updateImportanceSwatch(wire >= 1 ? wire : nil)
    }

    private func updateImportanceSwatch(_ outcome: Int?) {
        let color = DayPlanTask.outcomeColor(outcome)
        modalImportanceSwatch?.layer?.backgroundColor = (color ?? .clear).cgColor
        modalImportanceSwatch?.layer?.borderWidth = color == nil ? 1 : 0
        modalImportanceSwatch?.layer?.borderColor = NSColor.separatorColor.cgColor
    }

    @objc private func addFromList() { onAddFromList?() }

    @objc private func toggleDone(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue, var t = task(for: id) else { return }
        t.done = (sender.state == .on)
        DayPlanAnalytics.capture(t.done ? DayPlanAnalytics.taskCompleted : DayPlanAnalytics.taskUncompleted,
                                 ["from_todo": t.sourceTaskId != nil])
        DayPlanTaskStore.shared.update(t, for: date)
        reload(); onChange?()
    }

    /// What committing a name did, for the two callers that have to react differently.
    private enum NameCommitOutcome {
        /// Nothing to regroup or relayout — and we must NOT reload, or clicking straight into another
        /// row would destroy that row mid-click (the "click twice to switch fields" bug).
        case plainRename
        /// Task deleted, project/importance changed, or the title was rewritten by stripping a
        /// `#token` — the list has to be rebuilt.
        case structural
        /// The name was nothing but tokens. The edit is unfinished, so it was not committed: the
        /// typed text is still in the field and the row is still there.
        case refusedTokensOnly
    }

    /// Persist a name edit. See `TaskNameCommit` for the rule this follows — in particular why a name
    /// made only of tokens is refused rather than committed as a blank title.
    @discardableResult
    private func saveName(_ sender: NSTextField) -> NameCommitOutcome {
        guard let raw = sender.identifier?.rawValue, raw.hasPrefix("name:") else { return .plainRename }
        let id = String(raw.dropFirst("name:".count))
        guard var t = task(for: id) else { return .plainRename }
        let trimmed = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        switch TaskNameCommit.forDayPlanRow(trimmed, knownProjects: DayPlanTaskStore.shared.allProjectNames(),
                                               pendingProject: pendingProjectSelections[id]) {
        case .discard:
            DayPlanTaskStore.shared.delete(id: id, for: date)   // empty name = discard
            return .structural

        case .refuseTokensOnly:
            // Keep the raw text — on the row, in the field, and in the store, so the tokens survive a
            // relaunch as a findable task literally called "#class" instead of being pruned as a blank
            // row. Nothing is synced: an unfinished name has no business reaching the backend.
            // `titleBeforeEdit` is deliberately left in place, since the edit isn't over.
            if !trimmed.isEmpty { t.title = trimmed }
            else if t.sourceTaskId == nil { t.title = "#" + (pendingProjectSelections[id] ?? "") }
            DayPlanTaskStore.shared.update(t, for: date)
            // Only when it actually differs (whitespace), so Tab — which commits with the field editor
            // still attached — doesn't rewrite the text out from under the caret.
            if sender.stringValue != trimmed { sender.stringValue = trimmed }
            showNameNeededHint(forTaskID: id)
            return .refusedTokensOnly

        case .save(let parsed):
            pendingProjectSelections.removeValue(forKey: id)
            sender.placeholderString = nil
            let oldProject = t.project
            let oldOutcome = t.outcome
            // A typed `#project` assigns the task to that project (already resolved to an existing
            // project's canonical casing where there is one) and a typed `!N` sets its importance;
            // both have been stripped out of `parsed.title`.
            if let project = parsed.project {
                if project != oldProject { taskToRevealAfterReload = id }
                t.project = project
            }
            if let outcome = parsed.outcome { t.outcome = outcome }
            // `*15` sets the duration. This was parsed and stripped from the title and then thrown
            // away, so typing "write spec *2" produced a task called "write spec" that still ran for
            // the default 15 minutes — the token silently did nothing (report 2026-09-21_20-39-15).
            if let minutes = parsed.durationMinutes { t.durationMinutes = minutes }
            t.title = parsed.title
            DayPlanTaskStore.shared.update(t, for: date)
            clearNameNeededHint(forTaskID: id)
            // Name is finalized here (Enter/blur) — now, not per-keystroke, sync it: mint a to-do for a
            // from-scratch task, or push the renamed title to an already-synced one. Skip the rename API
            // when the title didn't actually change (a plain click-in/out) — but a from-scratch task still
            // attempts to mint (idempotent) since it may not be synced yet. `nil` original (begin-edit not
            // seen) is treated as "changed" so a genuine rename is never missed.
            let original = titleBeforeEdit.removeValue(forKey: id)
            if TaskNameCommit.needsSync(originalTitle: original, committedTitle: parsed.title,
                                        isBackedByTodo: t.sourceTaskId != nil) {
                DayPlanTaskStore.shared.syncNameOnCommit(t, on: date)
            }
            let changedShape = (t.project != oldProject) || (t.outcome != oldOutcome) || (parsed.title != trimmed)
            return changedShape ? .structural : .plainRename
        }
    }

    @objc private func commitName(_ sender: NSTextField) {
        let outcome = saveName(sender)
        onChange?()
        switch outcome {
        case .structural:
            // reloadAfterUserAction, not reload: Return leaves the field editor attached, and
            // `reload()` refuses to rebuild while a name field is focused — correctly, since that
            // would tear down a field mid-keystroke. The deferred rebuild then waits for editing to
            // end, so the row kept showing the RAW text the user typed. With tokens in it that
            // reads as "!5 and *2 were ignored" when in fact they were applied and stripped
            // (report 2026-09-21_20-39-15). The commit has already happened by this point, so
            // ending the edit here loses nothing.
            reloadAfterUserAction()
        case .refusedTokensOnly:
            // Return ended editing; put the cursor straight back so the half-typed name can be
            // finished rather than abandoned. Deferred so it runs after AppKit has torn the field
            // editor down, otherwise the focus is taken away again immediately.
            DispatchQueue.main.async { [weak self] in self?.window?.makeFirstResponder(sender) }
        case .plainRename:
            break
        }
    }

    /// Tell the user why a name made only of tokens wasn't saved: a small note stacked under the name,
    /// in the same name column (and the same 10pt secondary shape) the sub-task count line already uses,
    /// drawn in the warning colour. Inserted into the live row rather than through `reload()`, which
    /// would destroy the field the user is still typing in — the whole point of refusing.
    private func showNameNeededHint(forTaskID id: String) {
        guard let column = nameColumn(forTaskID: id), let field = nameField(forTaskID: id) else { return }
        guard nameNeededHint(forTaskID: id) == nil else { return }   // already shown; don't stack them
        let hint = label(ScheduleText.tasksNameNeeded, size: 10, bold: false)
        hint.textColor = .systemRed
        hint.identifier = NSUserInterfaceItemIdentifier(Self.nameNeededHintPrefix + id)
        hint.maximumNumberOfLines = 2
        hint.lineBreakMode = .byWordWrapping
        hint.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let index = column.arrangedSubviews.firstIndex(of: field).map { $0 + 1 } ?? column.arrangedSubviews.count
        column.insertArrangedSubview(hint, at: index)
        // Match the name field's own width pin, so the note wraps to the column instead of forcing it wider.
        let width = hint.widthAnchor.constraint(equalTo: column.widthAnchor)
        width.priority = NSLayoutConstraint.Priority(999)
        width.isActive = true
    }

    /// Take the note away again — the user is fixing it, or has.
    private func clearNameNeededHint(forTaskID id: String) {
        nameNeededHint(forTaskID: id)?.removeFromSuperview()
    }

    private func nameNeededHint(forTaskID id: String) -> NSView? {
        nameColumn(forTaskID: id)?.arrangedSubviews
            .first { $0.identifier?.rawValue == Self.nameNeededHintPrefix + id }
    }

    private static let nameNeededHintPrefix = "nameneeded:"

    /// Persist a duration edit in place (reformats the field) without a reload, so switching fields
    /// doesn't destroy the row you're clicking into.
    @objc private func commitDuration(_ sender: NSTextField) {
        guard let raw = sender.identifier?.rawValue, raw.hasPrefix("dur:") else { return }
        let id = String(raw.dropFirst("dur:".count))
        guard var t = task(for: id) else { return }
        if let m = QuickAddTaskParser.durationMinutes(fromFieldText: sender.stringValue) {
            t.durationMinutes = m
        }
        DayPlanTaskStore.shared.update(t, for: date)
        sender.stringValue = "\(t.durationMinutes)m"
        updateTotals()   // keep the overall + per-project totals live without a full reload
        onChange?()
    }

    /// Recompute the overall and per-project time totals in place (no reload).
    private func updateTotals() {
        let all = DayPlanTaskStore.shared.tasks(for: date)
        remainingMins = all.filter { !$0.done }.reduce(0) { $0 + $1.durationMinutes }
        refreshTotalLabel()
        var perProject: [String: Int] = [:]
        for t in all where !t.done {
            if let p = t.project, !p.isEmpty { perProject[p, default: 0] += t.durationMinutes }
        }
        for v in stack.arrangedSubviews {
            if let header = v as? ProjectHeaderView { header.setTotal(perProject[header.projectName] ?? 0) }
        }
    }

    @objc private func deleteTask(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        DayPlanAnalytics.capture(DayPlanAnalytics.taskRemoved, ["bulk": false])
        DayPlanTaskStore.shared.delete(id: id, for: date)
        // #2573: the action row sits under the focused task, whose name field is the first responder,
        // so a plain reload() hits its "don't rebuild while editing" guard and defers — the task was
        // removed from the store but the list never refreshed ("nothing happens"). Resign the field
        // first (as bulk remove does) so the rebuild actually runs.
        reloadAfterUserAction(); onChange?()
    }

    // MARK: Snooze (move a task to another day via natural-language input)

    @objc private func snoozeTask(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        snoozeTaskID = id
        snoozeBulk = false
        presentSnoozePopover(from: sender)
    }

    /// The shared smart-snooze planner for the viewed day, or nil until the host wires the free-time provider.
    private func smartSnoozePlanner() -> SmartSnoozePlanner? {
        guard let scheduleFreeFor = scheduleFreeMinutesForDate else { return nil }
        return SmartSnoozePlanner.dayPlan(from: date, scheduleFreeMinutes: scheduleFreeFor)
    }

    private func presentSnoozePopover(from sender: NSView) {
        // Eagerly find the slot now so the button names the actual day — "Next free slot: Fri 15 Aug" —
        // and one click confirms it. (One click still distributes via rollover.)
        let suggestion = smartSnoozePlanner()?.slot(requiredMinutes: snoozeRequiredMinutes(snoozeTargetIds()))
        let popover = SmartSnoozePopover(baseDate: date, suggestion: suggestion,
                                         onSmart: { [weak self] in self?.smartSnooze() },
                                         onMove: { [weak self] target in self?.confirmSnooze(to: target) },
                                         onDismiss: { [weak self] in self?.snoozePopover = nil; self?.snoozeTaskID = nil })
        snoozePopover = popover
        popover.show(relativeTo: sender.bounds, of: sender)
    }

    private func confirmSnooze(to target: Date) {
        if snoozeBulk {
            snoozeTasks(Dictionary(uniqueKeysWithValues: selectedTaskIDs.map { ($0, target) }))
            selectedTaskIDs.removeAll()
        } else if let id = snoozeTaskID {
            snoozeTasks([id: target])
        } else {
            NSSound.beep(); return
        }
        let daysAhead = Calendar.current.dateComponents([.day], from: date, to: target).day ?? 0
        DayPlanAnalytics.capture(DayPlanAnalytics.taskSnoozed, ["bulk": snoozeBulk, "days_ahead": daysAhead])
        cancelSnooze()
        reload(); onChange?()
    }

    /// Explicit moves end the name/duration editor before changing its backing row. Otherwise the
    /// refresh guard correctly preserves editing, but leaves a moved task displayed on its old day.
    func snoozeTasks(_ destinations: [String: Date]) {
        guard !destinations.isEmpty else { return }
        window?.makeFirstResponder(nil)
        for id in destinations.keys.sorted() {
            DayPlanTaskStore.shared.snooze(id: id, from: date, to: destinations[id]!)
        }
    }

    /// The task ids the snooze popover currently targets (all selected for a bulk snooze, else the one).
    private func snoozeTargetIds() -> [String] {
        snoozeBulk ? Array(selectedTaskIDs) : (snoozeTaskID.map { [$0] } ?? [])
    }

    /// Total minutes the snooze needs to fit — the SUM of the targeted tasks' durations (one for a single).
    private func snoozeRequiredMinutes(_ ids: [String]) -> Int {
        DayPlanTaskStore.shared.tasks(for: date).filter { ids.contains($0.id) }.reduce(0) { $0 + $1.durationMinutes }
    }

    private func smartSnooze() {
        let ids = snoozeTargetIds()
        guard !ids.isEmpty else { NSSound.beep(); return }
        // Look up the targeted tasks (preserve order) so we distribute by real durations.
        let byId = Dictionary(uniqueKeysWithValues:
            DayPlanTaskStore.shared.tasks(for: date).filter { ids.contains($0.id) }.map { ($0.id, $0) })
        let orderedIds = ids.filter { byId[$0] != nil }
        guard !orderedIds.isEmpty, let planner = smartSnoozePlanner(),
              let days = planner.distribute(durations: orderedIds.map { byId[$0]!.durationMinutes }) else { NSSound.beep(); return }
        var assigned: [String: Date] = [:]
        for (n, id) in orderedIds.enumerated() { assigned[id] = days[n] }
        snoozeTasks(assigned)
        if snoozeBulk { selectedTaskIDs.removeAll() }
        let distinctDays = Set(assigned.values).count
        addLog(text: "smart snooze (rollover): distributed \(orderedIds.count) task(s) across \(distinctDays) day(s)")
        DayPlanAnalytics.capture(DayPlanAnalytics.taskSnoozed,
                                 ["bulk": snoozeBulk, "smart": true, "count": orderedIds.count, "days": distinctDays])
        cancelSnooze()
        reload(); onChange?()
    }

    /// Close the popover and let ITS dismissal clear our state: the popover is the only object that can
    /// restore the window's default button, and `NSPopover.delegate` is weak — dropping our strong
    /// reference here would deallocate it mid-close and leave the habit "Start" button detached from Return.
    private func cancelSnooze() {
        snoozePopover?.close()
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        if field.identifier?.rawValue == "projectFilter", let combo = field as? NSComboBox {
            filterProjectCombo(combo); return
        }
        if let raw = field.identifier?.rawValue, raw.hasPrefix(subtaskFieldPrefix) {
            // Keep every keystroke in `modalSubtasks` so nothing depends on the field committing.
            if modalSubtasks.indices.contains(field.tag) { modalSubtasks[field.tag].title = field.stringValue }
            return
        }
        if let raw = field.identifier?.rawValue, raw.hasPrefix("name:") {
            // Persist the typed text continuously so a task is never lost even if blur/Enter is
            // missed. Project-token stripping happens on commit/accept; here we just keep the text.
            let id = String(raw.dropFirst("name:".count))
            if var t = task(for: id) {
                t.title = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                DayPlanTaskStore.shared.update(t, for: date)
            }
            // The "give it a name" note goes as soon as the user starts giving it one.
            clearNameNeededHint(forTaskID: id)
            // Re-measure so the field grows over multiple lines WHILE typing, not only on commit.
            field.invalidateIntrinsicContentSize()
            // Keep the habit "Start" default button suppressed while typing, in case a refresh
            // (e.g. day navigation) re-installed it — otherwise Return would start a habit.
            if editingFieldCount > 0 { window?.defaultButtonCell = nil }
            // Reflect !N / *N on the row as they are typed.
            previewNameTokens(forTaskID: id, typed: field.stringValue)
            let editor = obj.userInfo?["NSFieldEditor"] as? NSTextView
            updateProjectSuggestions(for: field, editor: editor)
        }
    }

    // MARK: `#project` suggestions — a non-intrusive in-panel list. We never auto-insert text (that
    // trapped the caret so you couldn't backspace); the user accepts with Tab or by clicking.

    private weak var suggestField: NSTextField?
    private var suggestMatches: [String] = []
    private var suggestOverlay: NSView?
    // Keyboard-highlighted row in the `#project` suggestion list (↑/↓ to move, Tab/Return to accept).
    private var suggestSelectedIndex = 0
    private var suggestButtons: [NSButton] = []
    /// Range of the `#token` currently being typed (from its `#` up to the caret), captured when the
    /// suggestions are shown. Accepting a suggestion removes exactly this range — so a `#` typed in the
    /// MIDDLE of a name replaces only the token, without truncating the rest of the title.
    private var suggestTokenRange: NSRange?

    /// The `#token` (sans `#`) immediately before the caret. nil if there's no live `#` token.
    private func projectTokenBeforeCaret(in editor: NSTextView) -> String? {
        let s = editor.string as NSString
        let caret = editor.selectedRange().location
        guard caret <= s.length else { return nil }
        let upToCaret = s.substring(to: caret) as NSString
        let hashLoc = upToCaret.range(of: "#", options: .backwards).location
        guard hashLoc != NSNotFound else { return nil }
        let frag = upToCaret.substring(from: hashLoc + 1)
        // Allow spaces in the partial so "#Focus B" can still match "Focus Bear".
        guard !frag.isEmpty, !frag.contains("#") else { return nil }
        return frag
    }

    private func updateProjectSuggestions(for field: NSTextField, editor: NSTextView?) {
        guard let editor = editor, let raw = projectTokenBeforeCaret(in: editor),
              raw.trimmingCharacters(in: .whitespaces).count >= 2 else {
            dismissProjectSuggestions(); return
        }
        // Record the exact range of the `#token` (its `#` up to the caret) so accepting a suggestion
        // removes ONLY the token, not everything after it — a `#` typed mid-name mustn't truncate the rest.
        let ns = editor.string as NSString
        let caret = min(editor.selectedRange().location, ns.length)
        let hashLoc = (ns.substring(to: caret) as NSString).range(of: "#", options: .backwards).location
        suggestTokenRange = hashLoc == NSNotFound ? nil : NSRange(location: hashLoc, length: caret - hashLoc)
        // Underscores are equivalent to spaces, so "#Focus_B" matches the "Focus Bear" project.
        let token = raw.replacingOccurrences(of: "_", with: " ")
        let all = DayPlanTaskStore.shared.allProjectNames()
        let prefix = all.filter { $0.range(of: token, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil }
        let contains = all.filter { p in
            !prefix.contains(p) && p.range(of: token, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
        let matches = Array((prefix + contains).prefix(6))
        // No existing project matches the typed `#token`: offer to create it as a new project.
        guard !matches.isEmpty else { showCreateProjectPrompt(token.trimmingCharacters(in: .whitespaces), for: field); return }
        showProjectSuggestions(matches, for: field)
    }

    /// Style an inline #project overlay as a floating menu: themed fill + hairline border, rounded
    /// corners, and a drop shadow so it reads as elevated above the task list. masksToBounds stays
    /// false so the shadow isn't clipped (content is inset enough not to reach the corners). Must be
    /// called within the panel's appearance context so the cgColors resolve to the right theme.
    private func styleSuggestionBox(_ box: NSView) {
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        box.layer?.borderColor = NSColor.separatorColor.cgColor
        box.layer?.borderWidth = 1
        box.layer?.cornerRadius = 8
        box.layer?.masksToBounds = false
        box.layer?.shadowColor = NSColor.black.cgColor
        box.layer?.shadowOpacity = 0.28
        box.layer?.shadowRadius = 12
        box.layer?.shadowOffset = CGSize(width: 0, height: -3)
    }

    private func showProjectSuggestions(_ matches: [String], for field: NSTextField) {
        // Resolve the layer cgColors below against THIS panel's appearance, not NSApp's — otherwise the
        // box background/border bake to the wrong theme (e.g. a light box in dark mode).
        let savedAppearance = NSAppearance.current
        NSAppearance.current = effectiveAppearance
        defer { NSAppearance.current = savedAppearance }
        suggestField = field
        suggestMatches = matches
        suggestSelectedIndex = 0
        suggestButtons = []
        suggestOverlay?.removeFromSuperview()

        let list = NSStackView()
        list.orientation = .vertical; list.alignment = .leading; list.spacing = 0
        list.translatesAutoresizingMaskIntoConstraints = false
        for (i, name) in matches.enumerated() {
            // Merge: cursorButton gives the pointing-hand cursor (#2242) while .regularSquare (no bezel)
            // keeps the highlighted suggestion legible — the old .inline bezel drew its own accent pill and
            // tinted the title with controlAccentColor, giving illegible blue-text-on-blue-pill. The row's
            // own layer background + the attributedTitle colour (set in updateSuggestHighlight) render.
            let b = cursorButton(title: name, target: self, action: #selector(suggestionClicked(_:)))
            b.isBordered = false; b.bezelStyle = .regularSquare; b.alignment = .left
            b.wantsLayer = true
            b.tag = i
            list.addArrangedSubview(b)
            b.widthAnchor.constraint(equalTo: list.widthAnchor).isActive = true
            suggestButtons.append(b)
        }
        updateSuggestHighlight()
        let box = NSView()
        box.translatesAutoresizingMaskIntoConstraints = false
        styleSuggestionBox(box)
        box.addSubview(list)
        NSLayoutConstraint.activate([
            list.topAnchor.constraint(equalTo: box.topAnchor, constant: 5),
            list.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -5),
            list.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 8),
            list.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -8),
        ])
        addSubview(box)
        // Below the field by default (panel is non-flipped, so "below" is a smaller y); flip to
        // above when that would spill off the panel's bottom edge (next to the Custom Routines panel).
        let rect = convert(field.bounds, from: field)
        box.layoutSubtreeIfNeeded()
        let h = box.fittingSize.height
        let belowY = rect.minY - h - 2
        let y = belowY < 2 ? rect.maxY + 2 : belowY
        box.setFrameOrigin(NSPoint(x: rect.minX, y: y))
        // Wide enough that no row truncates: measure the actual button fitting width (which includes the
        // cell's own insets + the head-indent) for the widest title, plus the list's 8+8 insets.
        let measurer = cursorButton(); measurer.isBordered = false; measurer.bezelStyle = .inline
        let mpara = NSMutableParagraphStyle(); mpara.firstLineHeadIndent = 8; mpara.headIndent = 8
        let mfont = NSFont.systemFont(ofSize: 13)
        var widestButton: CGFloat = 0
        for m in matches {
            measurer.attributedTitle = NSAttributedString(string: "↹ " + m, attributes: [.font: mfont, .paragraphStyle: mpara])
            widestButton = max(widestButton, measurer.fittingSize.width)
        }
        // The box lays out with autolayout (translatesAutoresizingMaskIntoConstraints = false), so
        // setFrameSize is IGNORED and the width comes from the list's content. For a single SHORT match
        // ("PhD") that left the box ~62pt, clipping "↹ PhD" down to just the glyph — the reported "the
        // project doesn't show for one suggestion". Pin an explicit width so every match stays readable
        // (min 160, or wider to fit the longest suggestion).
        box.widthAnchor.constraint(equalToConstant: max(160, rect.width, ceil(widestButton) + 16 + 6)).isActive = true
        suggestOverlay = box
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Close the inline #project suggestion list when the task list scrolls (the overlay is anchored to
    /// the field's on-screen position and can't follow the scrolling rows).
    @objc private func tasksDidScroll() {
        if suggestOverlay != nil { dismissProjectSuggestions() }
    }

    /// A completion made on another screen has landed in the store: redraw the rows and let the host
    /// rebuild the schedule around them.
    @objc private func storeChangedExternally() {
        reload(); onChange?()
    }

    private func dismissProjectSuggestions() {
        suggestOverlay?.removeFromSuperview(); suggestOverlay = nil
        suggestField = nil; suggestMatches = []; suggestButtons = []; suggestSelectedIndex = 0
        suggestTokenRange = nil
        createProjectField = nil
    }

    // The editable name field inside the "create new project" prompt (shown when the typed `#token`
    // matches no existing project). Non-nil only while that prompt is on screen.
    private weak var createProjectField: NSTextField?

    /// Shown when the typed `#token` matches no project: a small labelled text field (pre-filled with
    /// the token) plus a Save button, so the user can confirm/adjust the name and create the project.
    /// Reuses the suggestion overlay's slot/position; saving assigns the new project to the task, which
    /// makes it a known project for future autocomplete.
    private func showCreateProjectPrompt(_ suggestedName: String, for field: NSTextField) {
        guard !suggestedName.isEmpty else { dismissProjectSuggestions(); return }
        // Resolve the layer cgColors below against THIS panel's appearance (see showProjectSuggestions).
        let savedAppearance = NSAppearance.current
        NSAppearance.current = effectiveAppearance
        defer { NSAppearance.current = savedAppearance }
        suggestField = field
        suggestMatches = []
        suggestButtons = []
        suggestOverlay?.removeFromSuperview()

        let caption = label(ScheduleText.tasksNewProjectPrompt, size: 11, bold: false)
        caption.textColor = .secondaryLabelColor

        let input = NSTextField(string: suggestedName)
        input.identifier = NSUserInterfaceItemIdentifier("newProjectName")
        input.delegate = self
        input.translatesAutoresizingMaskIntoConstraints = false
        input.widthAnchor.constraint(equalToConstant: 150).isActive = true
        createProjectField = input

        let save = cursorButton(title: ScheduleText.tasksNewProjectSave, target: self, action: #selector(saveNewProjectClicked(_:)))
        save.bezelStyle = .rounded; save.controlSize = .small

        let row = NSStackView(views: [input, save])
        row.orientation = .horizontal; row.spacing = 6; row.alignment = .firstBaseline

        let stack = NSStackView(views: [caption, row])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        let box = NSView()
        box.translatesAutoresizingMaskIntoConstraints = false
        styleSuggestionBox(box)
        box.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: box.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -6),
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -8),
        ])
        addSubview(box)
        let rect = convert(field.bounds, from: field)
        box.layoutSubtreeIfNeeded()
        let h = box.fittingSize.height
        let belowY = rect.minY - h - 2
        let y = belowY < 2 ? rect.maxY + 2 : belowY
        box.setFrameOrigin(NSPoint(x: rect.minX, y: y))
        // Autolayout drives the box width here too (see the sibling suggestion box), so pin it instead of
        // setFrameSize so the caption + input + Save always fit.
        box.widthAnchor.constraint(equalToConstant: max(200, rect.width) - 20).isActive = true
        suggestOverlay = box
    }

    @objc private func saveNewProjectClicked(_ sender: NSButton) { saveNewProject() }

    /// Create the project named in the prompt and assign it to the task (via acceptProjectSuggestion,
    /// which also strips the typed `#partial`). Used names become known projects automatically.
    private func saveNewProject() {
        let name = (createProjectField?.stringValue ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { NSSound.beep(); return }
        acceptProjectSuggestion(name)
    }

    /// Redraw the suggestion rows so the keyboard-selected one is highlighted and prefixed with the
    /// accept marker (the same marker Tab/Return act on). The selected row draws white text on a solid
    /// accent fill. Use controlAccentColor (a stable, saturated blue) for the fill rather than
    /// selectedContentBackgroundColor, which dims to a low-contrast grey when the app's borderless
    /// full-screen window isn't the emphasised/key window — that greying is why the text was still hard
    /// to read. contentTintColor is set alongside the attributed title so the button cell can't override
    /// the colour.
    private func updateSuggestHighlight() {
        // Resolve the highlight cgColors against THIS panel's appearance (called on arrow-key nav too).
        let savedAppearance = NSAppearance.current
        NSAppearance.current = effectiveAppearance
        defer { NSAppearance.current = savedAppearance }
        let para = NSMutableParagraphStyle()
        para.firstLineHeadIndent = 8   // left padding so the arrow/title isn't flush against the row edge
        para.headIndent = 8
        let font = NSFont.systemFont(ofSize: 13)
        for (i, b) in suggestButtons.enumerated() {
            let selected = i == suggestSelectedIndex
            // Use the system selection pair (fill + its matching text) so the highlighted #project row is
            // legible for ANY accent colour — the old white-on-controlAccent / controlAccent-on-clear was
            // unreadable with a light accent (e.g. the brand orange). Non-selected uses plain label colour.
            let textColor: NSColor = selected ? .alternateSelectedControlTextColor : .labelColor
            b.contentTintColor = textColor
            // Keep the "↹ " slot in EVERY row (transparent when not selected) so selecting a row doesn't
            // widen its text and truncate the title. Only the colours/fill change on selection.
            let attr = NSMutableAttributedString(string: "↹ ", attributes: [
                .foregroundColor: selected ? textColor : NSColor.clear, .font: font, .paragraphStyle: para,
            ])
            attr.append(NSAttributedString(string: suggestMatches[i], attributes: [
                .foregroundColor: textColor, .font: font, .paragraphStyle: para,
            ]))
            b.attributedTitle = attr
            b.layer?.cornerRadius = 4
            // Saturated accent fill (not selectedContentBackgroundColor, which dims to a near-invisible
            // grey in this borderless, often-not-key panel — that's what hid the highlighted "phd" row).
            // Pairs reliably with the white alternateSelectedControlText above.
            b.layer?.backgroundColor = selected ? NSColor.controlAccentColor.cgColor : NSColor.clear.cgColor
        }
    }

    /// Move the highlighted `#project` suggestion by ±1 (clamped). Returns false if no list is showing,
    /// so the caller can let the arrow key fall through to normal caret movement.
    private func moveSuggestSelection(by delta: Int) -> Bool {
        guard suggestOverlay != nil, !suggestMatches.isEmpty else { return false }
        suggestSelectedIndex = max(0, min(suggestMatches.count - 1, suggestSelectedIndex + delta))
        updateSuggestHighlight()
        return true
    }

    @objc private func suggestionClicked(_ sender: NSButton) {
        guard suggestMatches.indices.contains(sender.tag) else { return }
        acceptProjectSuggestion(suggestMatches[sender.tag])
    }

    /// Assign the picked project to the task and strip the typed `#partial` from its title.
    private func acceptProjectSuggestion(_ project: String, keepEditing: Bool = true) {
        guard let field = suggestField, let raw = field.identifier?.rawValue, raw.hasPrefix("name:") else {
            dismissProjectSuggestions(); return
        }
        let id = String(raw.dropFirst("name:".count))
        taskToRevealAfterReload = id
        // Remove ONLY the typed `#token` (the range captured when suggestions were shown), keeping any
        // text after it — a `#` typed in the MIDDLE of a name must not truncate the rest of the title.
        // Fall back to stripping from the last `#` to the end only if we have no captured range.
        var text = field.stringValue
        let ns = text as NSString
        if let r = suggestTokenRange, r.location != NSNotFound, r.location + r.length <= ns.length {
            text = ns.replacingCharacters(in: r, with: "")
        } else if let hash = text.lastIndex(of: "#") {
            text.removeSubrange(hash...)
        }
        let cleanTitle = text.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
        // Accepting a suggestion for a line that is ONLY the token — "#v2" then Tab — leaves nothing to
        // call the task. `saveName` refuses that, but accepting a suggestion writes to the store directly
        // and bypassed it: the task was saved with an empty title and vanished, taking the typing with it
        // (report 2026-09-09_20-38-22, follow-up "still an issue. If I type #v2 and press tab, the task
        // vanishes"). Take the project, keep the caret in the field, say what is missing, and wait for a
        // real title. No reload here — it would destroy the field the user is still in.
        guard !cleanTitle.isEmpty else {
            pendingProjectSelections[id] = project
            if var t = task(for: id) {
                t.project = project
                if t.sourceTaskId == nil { t.title = "#" + project } // Preserve an unfinished local draft.
                DayPlanTaskStore.shared.update(t, for: date)
            }
            dismissProjectSuggestions()
            field.stringValue = ""
            field.placeholderString = "#" + project
            if let editor = field.currentEditor() as? NSTextView {
                editor.string = ""
                editor.setSelectedRange(NSRange(location: 0, length: 0))
            } else {
                field.window?.makeFirstResponder(field)
            }
            regroupProjectAndContinueEditing(id: id, text: "")
            return
        }
        if var t = task(for: id) {
            t.project = project
            t.title = cleanTitle
            DayPlanTaskStore.shared.update(t, for: date)
        }
        // Replace the field text too, so the blur-triggered saveName re-parse sees no `#partial` and
        // keeps the project we just picked (otherwise it re-extracts the stale text and can override it).
        field.stringValue = cleanTitle
        dismissProjectSuggestions()
        if keepEditing {
            regroupProjectAndContinueEditing(id: id, text: cleanTitle)
            return
        }
        window?.makeFirstResponder(nil)
        reload(); onChange?()
    }

    private func regroupProjectAndContinueEditing(id: String, text: String) {
        projectEditorToRestore = (id, text)
        pendingReloadAfterEditing = false
        window?.makeFirstResponder(nil)
        reload()
        onChange?()
    }

    private func highlightMovedTask(_ id: String) {
        guard let row = stack.arrangedSubviews.compactMap({ $0 as? TaskReorderRow })
            .first(where: { $0.taskID == id }) else { return }
        row.wantsLayer = true
        let highlight = CALayer()
        highlight.frame = row.bounds
        highlight.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        highlight.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
        highlight.cornerRadius = 6
        row.layer?.addSublayer(highlight)
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            fade.duration = 1.2
            highlight.opacity = 0
            highlight.add(fade, forKey: "projectMoveHighlight")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { highlight.removeFromSuperlayer() }
    }

    // While editing a task field, suppress the window's default button (the habit "Start" button is
    // the window default and fires on Return via performKeyEquivalent — before the field sees Enter).
    private var savedDefaultButtonCell: NSButtonCell?
    private var editingFieldCount = 0
    /// Title of a task when its name field began editing, so on commit we only push a rename to the
    /// backend if it actually changed (a plain click-in/click-out shouldn't hit the API).
    private var titleBeforeEdit: [String: String] = [:]
    private var pendingProjectSelections: [String: String] = [:]
    private var taskToRevealAfterReload: String?
    private var projectEditorToRestore: (id: String, text: String)?
    // Live project suggestions shown under the project combo. NSComboBox's own dropdown only opens on
    // the chevron, not as you type, so we draw our own list (case-insensitive substring) inside the
    // task-details popover.
    private weak var comboSuggestField: NSComboBox?
    private var comboSuggestMatches: [String] = []
    private var comboSuggestOverlay: NSView?

    /// Case-insensitive substring filter for the project combo box (e.g. "but" → "Focus Button"): keeps
    /// the combo's own (chevron) list filtered AND shows a live suggestion list under it as you type.
    /// The project names the combo currently offers, narrowed to what has been typed.
    private func projectComboMatches(_ combo: NSComboBox) -> [String] {
        let typed = combo.stringValue.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return [] }
        return DayPlanTaskStore.shared.allProjectNames()
            .filter { $0.range(of: typed, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    /// Re-stock the combo's own dropdown from the latest project list. **No suggestion overlay.**
    ///
    /// This is what a background project refresh should do. The overlay is a response to TYPING, and
    /// showing it here is what put a blue project name in the middle of the Task details popover the
    /// instant it opened: `openTaskModal` seeds the combo with the task's own project and then calls
    /// `refreshRemoteProjects`, whose callback narrowed the list to that one name and floated it
    /// under the combo — directly over the "Duration (min)" row, so it read as a project token in the
    /// duration field (report 2026-09-16_09-25-06, "I didn't click on the project selector").
    private func restockProjectCombo(_ combo: NSComboBox) {
        let matches = projectComboMatches(combo)
        combo.removeAllItems()
        combo.addItems(withObjectValues: matches.isEmpty ? DayPlanTaskStore.shared.allProjectNames() : matches)
    }

    /// Typing narrowed the list: re-stock it AND offer the matches as a suggestion overlay.
    private func filterProjectCombo(_ combo: NSComboBox) {
        restockProjectCombo(combo)
        showComboProjectSuggestions(Array(projectComboMatches(combo).prefix(6)), for: combo)
    }

    private func showComboProjectSuggestions(_ matches: [String], for combo: NSComboBox) {
        comboSuggestOverlay?.removeFromSuperview(); comboSuggestOverlay = nil
        guard !matches.isEmpty, let container = combo.window?.contentView else {
            comboSuggestField = nil; comboSuggestMatches = []; return
        }
        comboSuggestField = combo
        comboSuggestMatches = matches

        let list = NSStackView()
        list.orientation = .vertical; list.alignment = .leading; list.spacing = 0
        list.translatesAutoresizingMaskIntoConstraints = false
        for (i, name) in matches.enumerated() {
            let b = cursorButton(title: name, target: self, action: #selector(comboSuggestionClicked(_:)))
            b.isBordered = false; b.bezelStyle = .inline; b.alignment = .left
            b.contentTintColor = .controlAccentColor
            b.tag = i
            list.addArrangedSubview(b)
        }
        let box = NSView()
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        box.layer?.borderColor = NSColor.separatorColor.cgColor
        box.layer?.borderWidth = 1
        box.layer?.cornerRadius = 6
        box.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(list)
        NSLayoutConstraint.activate([
            list.topAnchor.constraint(equalTo: box.topAnchor, constant: 5),
            list.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -5),
            list.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 8),
            list.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -8),
        ])
        container.addSubview(box)
        // Popover content view is non-flipped (origin bottom-left); sit just below the combo, flipping
        // above only if that would spill off the bottom.
        let rect = container.convert(combo.bounds, from: combo)
        box.layoutSubtreeIfNeeded()
        let h = box.fittingSize.height
        let belowY = rect.minY - h - 2
        let y = belowY < 2 ? rect.maxY + 2 : belowY
        box.setFrameOrigin(NSPoint(x: rect.minX, y: y))
        box.setFrameSize(NSSize(width: max(180, rect.width), height: h))
        comboSuggestOverlay = box
    }

    @objc private func comboSuggestionClicked(_ sender: NSButton) {
        guard comboSuggestMatches.indices.contains(sender.tag), let combo = comboSuggestField else { return }
        combo.stringValue = comboSuggestMatches[sender.tag]
        dismissComboProjectSuggestions()
    }

    private func dismissComboProjectSuggestions() {
        comboSuggestOverlay?.removeFromSuperview(); comboSuggestOverlay = nil
        comboSuggestField = nil; comboSuggestMatches = []
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        if editingFieldCount == 0 { savedDefaultButtonCell = window?.defaultButtonCell }
        editingFieldCount += 1
        window?.defaultButtonCell = nil
        // While editing, always draw the text in the plain label colour on the field's light editing
        // background. A selected/importance-tinted row sets the name to white (or a band colour), which
        // becomes illegible once the field editor opens (white-on-white) — reported for #project tags.
        if let editedField = obj.object as? NSTextField, let id = editedField.identifier?.rawValue,
           id.hasPrefix("name:") || id.hasPrefix("dur:") {
            editedField.textColor = .labelColor
        }
        // Clicking (focusing) a task reveals its Expand / Snooze / Remove action row beneath it.
        if let id = (obj.object as? NSTextField)?.identifier?.rawValue, id.hasPrefix("name:") {
            let taskID = String(id.dropFirst("name:".count))
            titleBeforeEdit[taskID] = task(for: taskID)?.title ?? ""
            DispatchQueue.main.async { [weak self] in self?.showActionRow(forTaskID: taskID) }
        }
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        editingFieldCount = max(0, editingFieldCount - 1)
        if editingFieldCount == 0, let cell = savedDefaultButtonCell { window?.defaultButtonCell = cell; savedDefaultButtonCell = nil }
        // Project autocomplete intentionally replaces this editor after regrouping. Its text is
        // already preserved; treating this internal blur as a commit would save a half-written task.
        if projectEditorToRestore != nil { return }
        // Editing fully ended — run any reload that was deferred while the user was typing.
        defer {
            if editingFieldCount == 0 && pendingReloadAfterEditing { reload() }
        }
        // Persist on blur WITHOUT reloading — reloading here would tear down the row the user just
        // clicked into, which is what forced the "click twice to switch fields" behaviour. Any
        // regrouping from a typed #project happens on the next explicit reload / Enter.
        guard let field = obj.object as? NSTextField, let id = field.identifier?.rawValue else { return }
        if id == "projectFilter" { dismissComboProjectSuggestions(); return }
        if id.hasPrefix("name:") {
            // Losing focus (clicking outside, or into another field) closes the #project suggestion list.
            // Deferred so a click ON a suggestion button still fires its action before the overlay is torn
            // down (acceptProjectSuggestion dismisses it first, making this a no-op in that case).
            DispatchQueue.main.async { [weak self] in self?.dismissProjectSuggestions() }
            // Reload on blur only for a *structural* change (project assigned/stripped, or deleted) so
            // the task regroups immediately. A plain rename doesn't reload, so switching fields stays
            // a single click.
            // A token-only name is refused rather than committed; the note stays under the row until
            // it's fixed. Focus is NOT dragged back here — the user is on their way somewhere else,
            // and the typed text is safe on the row either way.
            let outcome = saveName(field)
            onChange?()
            if case .structural = outcome { reload() }
        } else if id.hasPrefix("dur:") {
            // commitDuration persists in place (no reload).
            commitDuration(field)
        }
    }

    private func label(_ text: String, size: CGFloat, bold: Bool) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
}

/// The dismissible "shortcuts you can type in the name" card (report 2026-09-21_07-42-02), shown
/// under the task whose name is being edited and closed for good by its ✕.
///
/// AppKit rather than SwiftUI because it is inserted into and removed from the live row stack while
/// a field editor is open, exactly like the action row and the name-needed hint it sits with; an
/// NSHostingView in that stack has to be told its own height, which a card of wrapping translated
/// text does not have in advance.
final class TaskShortcutCardView: NSView {

    /// Called once, when the ✕ is clicked. The card removes itself; the caller records the dismissal
    /// and forgets its reference.
    var onDismiss: (() -> Void)?

    init(hints: [String], title: String, dismissTooltip: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.cornerRadius = 6
        box.borderWidth = 1
        // Dynamic NSColors, resolved by the box at draw time, so the card tracks Light/Dark without
        // the panel having to rebuild it the way its cgColor row fills are rebuilt.
        box.borderColor = .separatorColor
        box.fillColor = .controlBackgroundColor
        box.contentViewMargins = NSSize(width: 8, height: 6)
        box.translatesAutoresizingMaskIntoConstraints = false
        addSubview(box)

        let heading = Self.label(title, size: 11, bold: true)
        let close = cursorButton(title: "", target: self, action: #selector(dismissClicked))
        close.isBordered = false
        close.toolTip = dismissTooltip
        close.setAccessibilityLabel(dismissTooltip)
        if #available(macOS 11.0, *) {
            close.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
        } else {
            close.title = "✕"   // i18n-ignore: the close glyph, not a word
        }
        close.setContentHuggingPriority(.required, for: .horizontal)
        let headingRow = NSStackView(views: [heading, NSView(), close])
        headingRow.orientation = .horizontal
        headingRow.alignment = .centerY
        headingRow.spacing = 6

        let column = NSStackView(views: [headingRow] + hints.map { Self.label($0, size: 11, bold: false) })
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 3
        column.translatesAutoresizingMaskIntoConstraints = false
        // The box is a BACKGROUND, not a container: the column is a sibling drawn over it rather
        // than its `contentView`. Assigning an auto-layout subtree to `contentView` left the box
        // with nothing to derive a height from, so the whole card measured zero and its labels drew
        // on top of the task rows above and below it (the report's screenshot). Owning the insets
        // here means the card's height is its content's height, which is the thing the stack needs.
        addSubview(column)

        let inset = box.contentViewMargins
        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: leadingAnchor),
            box.trailingAnchor.constraint(equalTo: trailingAnchor),
            box.topAnchor.constraint(equalTo: topAnchor),
            box.bottomAnchor.constraint(equalTo: bottomAnchor),
            column.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset.width),
            column.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset.width),
            column.topAnchor.constraint(equalTo: topAnchor, constant: inset.height),
            column.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset.height),
            headingRow.widthAnchor.constraint(equalTo: column.widthAnchor),
        ])
        // Pin every line to the card's own width so a long translation wraps instead of widening the
        // panel — the same guard the name-needed hint uses.
        for line in column.arrangedSubviews where line !== headingRow {
            let width = line.widthAnchor.constraint(equalTo: column.widthAnchor)
            width.priority = NSLayoutConstraint.Priority(999)
            width.isActive = true
        }
    }

    required init?(coder: NSCoder) { nil }

    private static func label(_ text: String, size: CGFloat, bold: Bool) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        l.textColor = bold ? .labelColor : .secondaryLabelColor
        l.maximumNumberOfLines = 3
        l.lineBreakMode = .byWordWrapping
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    @objc private func dismissClicked() {
        removeFromSuperview()
        onDismiss?()
    }
}

/// Top-aligned clip so the routine list grows downward and scrolls.
final class TopFlippedClipView: NSClipView { override var isFlipped: Bool { true } }

/// Bottom-right panel: a minimal replacement for the custom-routines screen. Lists the user's
/// on-demand ("ad hoc") custom routines, each with a play button to start it.
final class CustomRoutinesPanel: NSView {

    private let stack = NSStackView()
    private let titleLabel = NSTextField(labelWithString: ScheduleText.customRoutinesTitle)
    private lazy var manageButton = makeManageButton()

    /// Opens the custom-routine manager (create / edit / delete). Set by the Day Plan host; the panel
    /// itself owns no editing state.
    var onManage: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // Resolve the background against this panel's effectiveAppearance each display pass so it tracks
    // Light/Dark (previously a cached cgColor set once in init that never updated).
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
        reload()
    }

    private func build() {
        titleLabel.font = .boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        let clip = TopFlippedClipView(); clip.drawsBackground = false
        let scroll = NSScrollView()
        scroll.contentView = clip
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.documentView = stack
        scroll.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(manageButton)
        addSubview(scroll)
        // The scroll's bottom-to-panel tie is what otherwise forces a minimum panel height (header +
        // scroll), keeping the title visible even at height 0. Make it yield so that when the host
        // sets the panel height to 0 (hiddenForActiveRoutine) the whole panel — title included —
        // collapses; it's still satisfied normally since nothing else competes for the scroll's bottom.
        let scrollBottom = scroll.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        scrollBottom.priority = .defaultLow
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: manageButton.leadingAnchor, constant: -6),
            manageButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            manageButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            manageButton.widthAnchor.constraint(equalToConstant: 20),
            scroll.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            scrollBottom,
            stack.topAnchor.constraint(equalTo: clip.topAnchor),
            stack.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: clip.widthAnchor),
        ])
    }

    /// Whether there's at least one on-demand custom routine to show (host uses this to decide
    /// whether to reserve space for the panel).
    static var hasOnDemandRoutines: Bool { arrAllCustomRoutine.contains { $0.triggerOnDemand } }

    /// The whole panel (title + list) is hidden only while a morning/evening routine is actively
    /// running — you can't start an on-demand routine on top of one. POSTPONED states are NOT
    /// included: with a routine paused, starting a custom routine alongside is allowed, so the panel
    /// stays visible there.
    private var hiddenForActiveRoutine: Bool {
        switch currentState {
        // Keep the on-demand Custom Routines panel reachable while a morning/evening routine runs —
        // that's exactly when the Day Plan is shown full-screen, and it was previously hidden there.
        // Hide it on the end-of-routine summary and the shutdown screen, where it has no place — and
        // once a custom routine is itself running (._CUSTOM_ROUTINE_): you're already in one, so the
        // "start a custom routine" list shouldn't offer to start another.
        case ._FOCUS_SUMMARY_, ._SHUTOFFMAC_, ._CUSTOM_ROUTINE_:
            return true
        default:
            return false
        }
    }

    /// Natural height for the current content (header + one row per on-demand routine + buffer), so
    /// the host can size the panel to just what it needs (capped at 1/5 elsewhere).
    var preferredHeight: CGFloat {
        if hiddenForActiveRoutine { return 0 }   // whole panel hidden while a routine runs
        if isCutOffTimeGoing() { return 45 + 60 + 10 }   // header + wrapped wind-down message
        let rows = max(arrAllCustomRoutine.filter { $0.triggerOnDemand }.count, 1)
        return 45 + CGFloat(rows) * 28 + 10   // title area + rows + bottom buffer
    }

    func reload() {
        // Hide the ENTIRE panel (including the "Custom routines" title) while a morning/evening
        // routine is actively running; show it otherwise (including when a routine is postponed).
        // preferredHeight returns 0 so the host also collapses the reserved space.
        isHidden = hiddenForActiveRoutine
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if hiddenForActiveRoutine { return }

        // After the cutoff time, on-demand routines are deactivated (wind-down) — show a message
        // instead of the list.
        if isCutOffTimeGoing() {
            let msg = NSTextField(labelWithString: ScheduleText.customRoutinesAfterCutoff)
            msg.font = .systemFont(ofSize: 12)
            msg.textColor = .secondaryLabelColor
            msg.lineBreakMode = .byWordWrapping
            msg.maximumNumberOfLines = 0
            msg.preferredMaxLayoutWidth = 220
            stack.addArrangedSubview(msg)
            return
        }

        var any = false
        for (i, r) in arrAllCustomRoutine.enumerated() where r.triggerOnDemand {
            any = true
            let row = makeRow(title: r.title, index: i)
            stack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        if !any {
            let empty = NSTextField(labelWithString: ScheduleText.customRoutinesEmpty)
            empty.font = .systemFont(ofSize: 12)
            empty.textColor = .secondaryLabelColor
            empty.lineBreakMode = .byWordWrapping
            empty.maximumNumberOfLines = 2
            empty.preferredMaxLayoutWidth = 220
            stack.addArrangedSubview(empty)
        }
    }

    private func makeRow(title: String, index: Int) -> NSView {
        let play = cursorButton(title: "", target: self, action: #selector(playClicked(_:)))
        play.bezelStyle = .circular
        play.controlSize = .small
        play.tag = index
        if #available(macOS 11.0, *) { play.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Start") } else { play.title = "▶" }
        play.contentTintColor = .controlAccentColor
        play.translatesAutoresizingMaskIntoConstraints = false
        play.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let name = NSTextField(labelWithString: title)
        name.font = .systemFont(ofSize: 13)
        name.lineBreakMode = .byTruncatingTail
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [play, name])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    private func makeManageButton() -> NSButton {
        let btn = cursorButton(title: "", target: self, action: #selector(manageClicked))
        btn.isBordered = false
        btn.bezelStyle = .inline
        btn.imagePosition = .imageOnly
        btn.contentTintColor = .secondaryLabelColor
        if #available(macOS 11.0, *),
           let image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: ScheduleText.customRoutineManage) {
            btn.image = image
        } else {
            btn.title = "⋯"   // i18n-ignore — glyph only
        }
        btn.toolTip = ScheduleText.customRoutineManage
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setContentHuggingPriority(.required, for: .horizontal)
        return btn
    }

    @objc private func manageClicked() { onManage?() }

    @objc private func playClicked(_ sender: NSButton) {
        // A class session is in control — don't let the student start an on-demand custom routine.
        if teacherSessionManagerObject.isTeacherSessionActive(){
            teacherSessionManagerObject.showTeacherSessionLockedAlert()
            return
        }
        // Mirror the custom-routines screen: gate behind purchase, then start on-demand.
        if isPurchased == false && daysLeft <= 0 { showUpgradeNowWindow(reason: "habit_play_clicked_expired"); return }
        startCustomRoutine(index: sender.tag, isOnDemand: true)
    }
}
