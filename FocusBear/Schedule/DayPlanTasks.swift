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

        let add = NSButton(title: "", target: self, action: #selector(addClicked))
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

/// Parse a natural-language snooze ("2d", "2w", "3mo", "1y", "tue", "tom", "today") into a target
/// day. A leading `-` (or "yesterday") moves to a PAST day so a task can be back-dated. Returns nil
/// if it can't be parsed.
func parseSnoozeDate(_ input: String, from base: Date) -> Date? {
    let s = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !s.isEmpty else { return nil }
    let cal = Calendar.current
    let today = cal.startOfDay(for: base)
    if s == "today" || s == "tod" { return today }
    if s == "tom" || s == "tmr" || s == "tomorrow" { return cal.date(byAdding: .day, value: 1, to: today) }
    if s == "yesterday" || s == "yest" || s == "yd" { return cal.date(byAdding: .day, value: -1, to: today) }
    // Weekday name → next occurrence (strictly after today).
    let weekdays: [(String, Int)] = [("sun",1),("mon",2),("tue",3),("wed",4),("thu",5),("fri",6),("sat",7)]
    for (name, wd) in weekdays where s.hasPrefix(name) {
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

/// One planned task for a given day. `sourceTaskId` links back to a backend to-do item when the
/// task was imported from the to-do list (nil for from-scratch tasks).
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

    /// Sub-tasks as a non-optional list, for convenient counting/rendering.
    var subtaskList: [DayPlanSubtask] { subtasks ?? [] }

    init(id: String = UUID().uuidString, title: String, durationMinutes: Int = 15,
         done: Bool = false, sourceTaskId: String? = nil, blockKey: String? = nil,
         project: String? = nil, notes: String? = nil, subtasks: [DayPlanSubtask]? = nil,
         outcome: Int? = nil, eisenhowerQuadrant: Int? = nil, manuallyPlanned: Bool? = nil) {
        self.id = id; self.title = title; self.durationMinutes = durationMinutes
        self.done = done; self.sourceTaskId = sourceTaskId; self.blockKey = blockKey
        self.project = project; self.notes = notes; self.subtasks = subtasks
        self.outcome = outcome; self.eisenhowerQuadrant = eisenhowerQuadrant
        self.manuallyPlanned = manuallyPlanned
    }

    /// Colour for an importance value, banded into 4 (higher = hotter). nil when unset.
    static func outcomeColor(_ outcome: Int?) -> NSColor? {
        guard let o = outcome else { return nil }
        switch o {
        case ...3:   return .systemGray      // 1–3 low
        case 4...6:  return .systemBlue      // 4–6 normal
        case 7...8:  return .systemOrange    // 7–8 high
        default:     return .systemRed       // 9–10 critical
        }
    }
    static func outcomeBandLabel(_ outcome: Int) -> String {
        switch outcome {
        case ...3:   return "Low"
        case 4...6:  return "Normal"
        case 7...8:  return "High"
        default:     return "Critical"
        }
    }
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

/// Pull a `*N` priority token (N = 1...10, the importance / "outcome") out of a typed task title and
/// strip it: "draft report *7" → ("draft report", 7). Only a standalone `*N` in range counts — a bare
/// `*`, `*0`, or `*11` is left untouched in the title. The last such token wins.
func extractPriorityToken(_ raw: String) -> (title: String, outcome: Int?) {
    let pattern = "(?:^|\\s)\\*(10|[1-9])(?=\\s|$)"
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
    return (title, outcome)
}

/// Seed the to-do player with the Day Plan tasks assigned to the habit being played (allowed-activity
/// habits show the player). Keyed by "habit:<name>" — the same key the Day Plan uses when a task is
/// dragged onto a habit. No-op when the habit has no assigned tasks, so it's safe to call generously.
func prepopulateDayPlanTasks(for habit: habit?) {
    guard let habit = habit, habit.isAllowedActivityHabit, let name = habit.name else { return }
    let tasks = DayPlanTaskStore.shared.tasks(assignedTo: "habit:\(name)", for: Date()).filter { !$0.done }
    guard !tasks.isEmpty else { return }
    let payload: [[String: Any]] = tasks.map { t in
        // Use the source to-do id where known so the player doesn't duplicate a task already loaded.
        ["id": t.sourceTaskId ?? t.id, "title": t.title, "duration": max(60, t.durationMinutes * 60)]
    }
    taskPlayerVcObj?.prepopulateTasks(payload)
}

/// Per-day local store for Day Plan tasks, persisted in UserDefaults as `{ "yyyy-MM-dd": [task] }`.
final class DayPlanTaskStore {
    static let shared = DayPlanTaskStore()
    private init() { load() }

    /// Mockup mode: in-memory only — never persists to UserDefaults and never rolls tasks over, so a
    /// mock render can't pollute or move the user's real data. Only ever set true by the DEBUG-only
    /// DayPlanMockup renderer, so in Release these guards are inert.
    static var mockMode = false

    /// Replace a day's tasks with mock data (mockup renderer only).
    func loadMock(_ tasks: [DayPlanTask], for date: Date) {
        byDay[dayKey(date)] = tasks
    }

    private let key = "dayPlanTasksByDay"
    private var byDay: [String: [DayPlanTask]] = [:]
    /// Local ids of from-scratch tasks currently having a backend to-do minted for them, so a rapid
    /// second edit doesn't mint a duplicate before the first create returns.
    private var mintingTaskIds = Set<String>()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.calendar = Calendar.current; return f
    }()
    private func dayKey(_ date: Date) -> String { Self.dayFormatter.string(from: date) }

    func tasks(for date: Date) -> [DayPlanTask] {
        rollOverIfNeeded()
        return byDay[dayKey(date)] ?? []
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
                if let sid = t.sourceTaskId, contains(sourceTaskId: sid, for: Date()) { continue }
                t.blockKey = nil                       // re-plan onto today, untimed
                byDay[todayKey, default: []].append(t)
            }
            byDay[dayK]?.removeAll { !$0.done && $0.manuallyPlanned != true }   // remove only the moved ones
            changed = true
        }
        UserDefaults.standard.set(todayKey, forKey: lastRolloverKey)
        if changed { save() }
    }

    func add(_ task: DayPlanTask, for date: Date) {
        // Never add the same imported to-do twice on a day.
        if let sid = task.sourceTaskId, contains(sourceTaskId: sid, for: date) { return }
        byDay[dayKey(date), default: []].append(task); save()
        // #2148: a Day Plan task backed by a to-do is planned via `planned_date` (the pointer model);
        // this makes it show on GET /day-plan/day and hydrate on other devices. Any to-do-backed task
        // syncs (PATCH /to-do/:id needs only its id — no quadrant). From-scratch tasks (no
        // sourceTaskId) stay local-only — the pointer model has nowhere to put them without minting a to-do.
        if let sid = task.sourceTaskId {
            DayPlanSync.shared.setTodoPlanned(todoID: sid, plannedDate: date, blockKey: task.blockKey, order: nil)
        }
    }

    func update(_ task: DayPlanTask, for date: Date) {
        let k = dayKey(date)
        guard let i = byDay[k]?.firstIndex(where: { $0.id == task.id }) else { return }
        let wasDone = byDay[k]![i].done
        byDay[k]?[i] = task; save()
        // #2148: reflect a completion flip onto the underlying to-do's status so web/mobile update.
        // Only on an actual done transition, and only when we can echo the to-do's title + quadrant
        // back (else we'd risk clobbering them on the upsert).
        if task.done != wasDone, let sid = task.sourceTaskId, let q = task.eisenhowerQuadrant {
            DayPlanSync.shared.setTodoStatus(todoID: sid, title: task.title, quadrant: q, completed: task.done)
        }
    }

    /// Call when a task's name is FINALIZED (Enter/blur), not on every keystroke. For a from-scratch
    /// task this mints a backend to-do (named after the whole title, not the first character typed);
    /// for an already-synced task it pushes the renamed title to its to-do so the new name syncs to
    /// other devices too.
    func syncNameOnCommit(_ task: DayPlanTask, on date: Date) {
        guard !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let sid = task.sourceTaskId {
            DayPlanSync.shared.setTodoTitle(todoID: sid, title: task.title, quadrant: task.eisenhowerQuadrant ?? 4)
        } else {
            mintTodoIfNeeded(for: task, on: date)
        }
    }

    /// Give a from-scratch task a backend to-do so it syncs across devices (the pointer model can only
    /// sync to-do-backed tasks). Mints once — on the first non-empty title — via `PUT /to-do` (create),
    /// then backfills the new id as `sourceTaskId` and plans it (`PATCH /to-do/:id`). Best-effort: on a
    /// failed create (e.g. offline) the task stays local and we retry on the next edit. No-op for tasks
    /// already backed by a to-do, blank rows, or those with a mint in kflight.
    private func mintTodoIfNeeded(for task: DayPlanTask, on date: Date) {
        guard task.sourceTaskId == nil,
              !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !mintingTaskIds.contains(task.id) else { return }
        mintingTaskIds.insert(task.id)
        let localId = task.id
        let quadrant = task.eisenhowerQuadrant ?? 4   // neutral default (not urgent / not important)
        // The /to-do API requires a real Date for due_date (empty string → 400 "due_date must be a Date
        // instance"), so use the day the task is planned on, ISO-8601 UTC like the other addTask callers.
        let dueDate = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        allApiObject.addTask(title: task.title, details: "", eisenhowerQuadrant: quadrant,
                             dueDate: dueDate, objective: "", tags: []) { [weak self] ok, json in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.mintingTaskIds.remove(localId)
                guard ok, let newId = json?["id"] as? String else { return }
                let k = self.dayKey(date)
                // The row may have moved/been deleted, or been imported over, while we waited.
                guard let idx = self.byDay[k]?.firstIndex(where: { $0.id == localId }),
                      self.byDay[k]?[idx].sourceTaskId == nil else { return }
                self.byDay[k]?[idx].sourceTaskId = newId
                self.byDay[k]?[idx].eisenhowerQuadrant = quadrant
                self.save()
                let planned = self.byDay[k]![idx]
                DayPlanSync.shared.setTodoPlanned(todoID: newId, plannedDate: date,
                                                  blockKey: planned.blockKey, order: nil)
            }
        }
    }

    func delete(id: String, for date: Date) {
        let removed = byDay[dayKey(date)]?.first { $0.id == id }
        byDay[dayKey(date)]?.removeAll { $0.id == id }; save()
        // Removing a to-do-backed task from the Day Plan just unplans it (clears planned_date); the
        // to-do itself is kept. From-scratch tasks have no backend row to clear.
        if let sid = removed?.sourceTaskId {
            DayPlanSync.shared.setTodoPlanned(todoID: sid, plannedDate: nil, blockKey: nil, order: nil)
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
            if self.hydrate(fromDay: raw, for: date) { onChange() }
            onComplete?(true)
        }
    }

    @discardableResult
    func hydrate(fromDay raw: NSDictionary, for date: Date) -> Bool {
        guard let arr = raw["tasks"] as? [[String: Any]] else { return false }
        let k = dayKey(date)
        var list = byDay[k] ?? []
        var indexBySource = [String: Int]()
        for (i, t) in list.enumerated() { if let s = t.sourceTaskId { indexBySource[s] = i } }
        var changed = false
        for obj in arr {
            guard let id = obj["id"] as? String else { continue }
            let done = ((obj["status"] as? String) ?? "") == "COMPLETED"
            if let idx = indexBySource[id] {
                // Upgrade-only: the backend may mark a task done (e.g. completed on another device),
                // but must NOT revert a local completion. The completion reflect (PUT /to-do status)
                // can lag or be skipped — e.g. a task imported before we captured its
                // eisenhower_quadrant — and clobbering local `done` here made ticked tasks reappear
                // un-ticked on the next Day Plan open (reported 2026-07-08).
                if done, !list[idx].done { list[idx].done = true; changed = true }
            } else {
                let title = (obj["title"] as? String) ?? "Task"
                let secs = (obj["duration"] as? Int) ?? 0
                let minutes = secs > 0 ? max(1, secs / 60) : 15
                let quadrant = obj["eisenhower_quadrant"] as? Int
                let blockKey = obj["planned_block_key"] as? String
                let tags = (obj["tags"] as? [[String: Any]]) ?? []
                let project = tags.first?["text"] as? String
                list.append(DayPlanTask(title: title, durationMinutes: minutes, done: done,
                                        sourceTaskId: id, blockKey: blockKey, project: project,
                                        eisenhowerQuadrant: quadrant))
                changed = true
            }
        }
        if changed { byDay[k] = list; save() }
        return changed
    }

    /// True if the to-do item is already on the given day (so the picker can avoid duplicates).
    func contains(sourceTaskId: String, for date: Date) -> Bool {
        tasks(for: date).contains { $0.sourceTaskId == sourceTaskId }
    }

    /// Tasks not nested under any schedule block (shown in the side panel).
    func unassignedTasks(for date: Date) -> [DayPlanTask] {
        tasks(for: date).filter { $0.blockKey == nil }
    }
    /// Tasks nested under a given schedule block (shown under that block's card).
    func tasks(assignedTo key: String, for date: Date) -> [DayPlanTask] {
        tasks(for: date).filter { $0.blockKey == key }
    }
    func task(withID id: String, for date: Date) -> DayPlanTask? {
        tasks(for: date).first { $0.id == id }
    }
    /// Nest a task under a block (key) or pull it back to the panel (nil).
    func setBlockKey(_ key: String?, forTaskID id: String, date: Date) {
        let k = dayKey(date)
        guard let i = byDay[k]?.firstIndex(where: { $0.id == id }) else { return }
        byDay[k]?[i].blockKey = key; save()
    }

    /// Project names fetched from the backend (`/projects`). Merged into autocomplete suggestions so
    /// the user can pick a real project before any task on the day uses it. Set by the host on load.
    var remoteProjectNames: [String] = []

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
        let k = dayKey(date)
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
    func moveTask(id: String, from: Date, to: Date) {
        let fk = dayKey(from), tk = dayKey(to)
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
            DayPlanSync.shared.setTodoPlanned(todoID: sid, plannedDate: to, blockKey: nil, order: nil)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [DayPlanTask]].self, from: data) else { return }
        byDay = decoded
        cleanup()
        rolloverIncompleteTasks()
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
        if Self.mockMode { return }   // mockups are in-memory only
        if let data = try? JSONEncoder().encode(byDay) { UserDefaults.standard.set(data, forKey: key) }
    }
}

/// The right-hand "Tasks for today" panel. Self-contained: renders the day's tasks with a
/// checkbox, an editable name and an editable duration, plus an add-from-scratch button. Calls
/// `onChange` after any edit so the host can refresh anything that depends on tasks.
final class DayPlanTasksPanel: NSView, NSTextFieldDelegate, NSComboBoxDelegate {

    var date = Date() { didSet { reload() } }
    var onChange: (() -> Void)?
    /// Hook the host provides to present the "add from to-do list" picker.
    var onAddFromList: (() -> Void)?

    private let stack = NSStackView()
    private var isReloading = false   // guards against re-entrant reload() duplicating the list

    // Trailing spacer height reserved after the last task row so its action row (Expand/Snooze/Remove,
    // revealed on click) and a fully-wrapped 3-line name aren't left unreachable by scrolling — see the
    // comment on the spacer in reload() for why this can't be done via NSScrollView.contentInsets.
    // Sized for the worst case: ~2 extra wrapped lines over a 1-line row (≈ 34pt) + the action row's own
    // height plus its stack spacing (≈ 30pt), with headroom.
    private let bottomScrollReserveHeight: CGFloat = 90

    private var headTopConstraint: NSLayoutConstraint?
    /// Extra top padding added in full screen so the header clears the menu-bar reveal overlay.
    var extraTopInset: CGFloat = 0 { didSet { headTopConstraint?.constant = 14 + extraTopInset } }

    // Snooze popover state.
    private var snoozePopover: NSPopover?
    private var snoozeTaskID: String?
    private weak var snoozeField: NSTextField?
    private var snoozeSavedDefaultButton: NSButtonCell?

    private weak var snoozeParsedLabel: NSTextField?

    // Click-revealed per-task action row (Expand / Snooze / Remove) shown beneath the focused task.
    private weak var actionRow: NSView?
    private var actionRowTaskID: String?

    // Multi-select (shift/⌘-click a task) for bulk snooze/remove.
    private var selectedTaskIDs: Set<String> = []
    private var snoozeBulk = false

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

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        buildChrome()
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
    private weak var headerLabel: NSTextField?
    private var remainingMins = 0
    /// Free (unscheduled) time for the day, set by the host so it can sit next to the task total.
    var freeTimeMinutes: Int? { didSet { refreshTotalLabel() } }

    private static func hm(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    /// "≈ 1h 59m of tasks to do   🕒 2h free" — the task total with free time appended.
    private func refreshTotalLabel() {
        var parts: [String] = []
        if remainingMins > 0 { parts.append("≈ " + Self.hm(remainingMins) + " of tasks to do") }
        if let f = freeTimeMinutes, f > 0 { parts.append("🕒 " + Self.hm(f) + " free") }
        totalLabel.stringValue = parts.joined(separator: "    ")
        totalLabel.isHidden = parts.isEmpty
    }
    private var settingsPopover: NSPopover?
    private static let showCompletedKey = "dayPlanShowCompletedTasks"
    private var showCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.showCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.showCompletedKey) }
    }
    @objc private func toggleShowCompleted(_ sender: NSButton) {
        showCompleted = (sender.state == .on)
        reload()
    }

    /// Settings popover behind the header cog. Currently just the show-completed toggle.
    @objc private func openSettingsClicked(_ sender: NSButton) {
        let completedCount = DayPlanTaskStore.shared.tasks(for: date).filter { $0.done }.count
        let toggleTitle = completedCount > 0
            ? String(format: ScheduleText.tasksShowCompletedCount, completedCount)
            : ScheduleText.tasksShowCompleted
        let check = NSButton(checkboxWithTitle: toggleTitle, target: self, action: #selector(toggleShowCompleted(_:)))
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

    private func buildChrome() {
        let header = label(ScheduleText.tasksForToday, size: 15, bold: true)
        headerLabel = header
        totalLabel.font = .systemFont(ofSize: 11)
        totalLabel.textColor = .secondaryLabelColor
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        let addNew = NSButton(title: ScheduleText.tasksAddNew, target: self, action: #selector(addFromScratchClicked))
        addNew.bezelStyle = .rounded
        if #available(macOS 11.0, *) { addNew.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil); addNew.imagePosition = .imageLeading }
        let addList = NSButton(title: ScheduleText.tasksAddFromList, target: self, action: #selector(addFromList))
        addList.bezelStyle = .rounded
        if #available(macOS 11.0, *) { addList.image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: nil); addList.imagePosition = .imageLeading }
        let addRow = NSStackView(views: [addNew, addList])
        addRow.orientation = .horizontal; addRow.spacing = 8; addRow.distribution = .fillEqually

        // Settings cog (holds the show-completed toggle and any future options). It sits on the
        // totals row, right-aligned — NOT the top-right corner, where the full-screen "Exit
        // Fullscreen" button would overlap it.
        let cog = NSButton(title: "", target: self, action: #selector(openSettingsClicked(_:)))
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

        // Title + (totals + cog) row + the two add buttons, full panel width.
        let head = NSStackView(views: [header, totalRow, addRow])
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
        // NB: room to scroll past the last task is reserved via a trailing spacer arranged subview in
        // reload(), NOT scroll.contentInsets — verified (offscreen AppKit harness) that contentInsets.bottom
        // does not extend NSClipView's constrainBoundsRect/documentRect, so it never actually created any
        // extra scrollable headroom here despite the old comment claiming otherwise (bug report 2026-07-18:
        // the last task's click-revealed action row was unreachable/unclickable at max scroll).

        addSubview(head)
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
            // Scrollable tasks list fills the panel below the header.
            scroll.topAnchor.constraint(equalTo: head.bottomAnchor, constant: 12),
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

    func reload() {
        // Clearing the stack ends editing of any field, which can re-enter reload() mid-build and
        // duplicate the whole list — guard against that.
        if isReloading { return }
        isReloading = true
        defer { isReloading = false }
        needsDisplay = true   // refresh the panel background for the current appearance
        // Resolve the cgColor row fills built below against this panel's appearance (not NSApp's), so
        // they track Light/Dark even when rebuilt outside a draw cycle.
        let savedAppearance = NSAppearance.current
        NSAppearance.current = effectiveAppearance
        defer { NSAppearance.current = savedAppearance }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        actionRow = nil; actionRowTaskID = nil   // the cleared stack took the action row with it
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
        if let bar = makeBulkBar() { stack.addArrangedSubview(bar) }   // bulk action bar at the top
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
        let check = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleDone(_:)))
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
            let countBtn = NSButton(title: "", target: self, action: #selector(subtaskCountClicked(_:)))
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
        if task.blockKey != nil, #available(macOS 11.0, *) {
            timeBadge.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Time-boxed")
            timeBadge.toolTip = ScheduleText.tasksTimeBoxed
        }

        // Importance: tint the whole task row with the band colour and draw its text in a
        // high-contrast colour (instead of a small dot).
        let importanceBG = DayPlanTask.outcomeColor(task.outcome)
        if let fg = DayPlanTask.outcomeForeground(task.outcome) {
            if !task.done { name.textColor = fg }
            dur.textColor = fg.withAlphaComponent(0.85)
            if task.blockKey != nil { timeBadge.contentTintColor = fg }
            // The subtask count also needs the high-contrast colour, else it's unreadable on the
            // saturated importance band (reported on red/orange cards).
            if let cb = subtaskCountBtn {
                cb.attributedTitle = NSAttributedString(string: cb.attributedTitle.string, attributes: [
                    .font: NSFont.systemFont(ofSize: 10),
                    .foregroundColor: subtasksAllDone ? NSColor.systemGreen : fg,
                ])
            }
        }
        let row = TaskReorderRow(views: [handle, check, nameColumn, timeBadge, dur])
        row.orientation = .horizontal
        row.alignment = .top   // top-align so a wrapped (multi-line) name keeps the controls aligned
        row.spacing = 6
        row.edgeInsets = NSEdgeInsets(top: 10, left: 8, bottom: 14, right: 8)   // breathing room around the importance tint; extra at the bottom because the multi-line name label under-reports its height, so its last line otherwise sits tight against the colour band's lower edge
        if selectedTaskIDs.contains(task.id) {   // selection highlight wins over the importance tint
            row.wantsLayer = true
            row.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            row.layer?.cornerRadius = 4
        } else if let bg = importanceBG {
            row.wantsLayer = true
            row.layer?.backgroundColor = bg.cgColor
            row.layer?.cornerRadius = 4
            row.toolTip = String(format: ScheduleText.tasksImportanceTooltip, task.outcome ?? 0, DayPlanTask.outcomeBandLabel(task.outcome ?? 0))
        }
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
                acceptProjectSuggestion(suggestMatches[suggestSelectedIndex])
                return true
            }
            let taskID = String(id.dropFirst("name:".count))
            saveName(field)   // persist without a full reload so the duration field survives
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
            if id == "snoozeInput" { confirmSnooze(); return true }
            if id.hasPrefix("name:") { commitName(field) } else if id.hasPrefix("dur:") { commitDuration(field) }
            window?.makeFirstResponder(nil)
            return true
        }
        // Escape in the snooze field closes the popover; Escape in the new-project prompt dismisses it.
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            if id == "snoozeInput" { cancelSnooze(); return true }
            if id == "newProjectName" { dismissProjectSuggestions(); window?.makeFirstResponder(nil); return true }
            // Escape while the #project suggestion list is open just closes the list (keeps editing the name).
            if id.hasPrefix("name:"), suggestOverlay != nil { dismissProjectSuggestions(); return true }
        }
        return false
    }

    /// The duration field for a given task id in the currently-rendered rows (used by Tab navigation).
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

    private func task(for id: String) -> DayPlanTask? {
        DayPlanTaskStore.shared.tasks(for: date).first { $0.id == id }
    }

    // MARK: Actions

    @objc private func addFromScratchClicked() { addFromScratch(project: nil) }

    private func addFromScratch(project: String?) {
        // Don't pile up blank rows — drop any existing unnamed one first.
        for t in DayPlanTaskStore.shared.tasks(for: date)
        where t.sourceTaskId == nil && t.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            DayPlanTaskStore.shared.delete(id: t.id, for: date)
        }
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
        stack.layoutSubtreeIfNeeded()
    }

    private func actionButton(_ title: String, symbol: String, id: String, action: Selector) -> NSButton {
        let b = NSButton(title: " " + title, target: self, action: action)
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
        reload()
    }

    /// The "N selected · Snooze · Remove · Clear" bar shown at the top of the list while ≥1 task is
    /// multi-selected. Returns nil when nothing is selected.
    private func makeBulkBar() -> NSView? {
        guard !selectedTaskIDs.isEmpty else { return nil }
        let count = label(String(format: ScheduleText.tasksSelectedCount, selectedTaskIDs.count), size: 11, bold: true)
        count.textColor = .controlAccentColor
        let snooze = NSButton(title: " " + ScheduleText.tasksSnooze, target: self, action: #selector(bulkSnoozeClicked(_:)))
        snooze.bezelStyle = .rounded; snooze.controlSize = .small
        let remove = NSButton(title: " " + ScheduleText.tasksRemove, target: self, action: #selector(bulkRemoveClicked))
        remove.bezelStyle = .rounded; remove.controlSize = .small
        let clear = NSButton(title: ScheduleText.tasksClearSelection, target: self, action: #selector(clearSelectionClicked))
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
        for id in selectedTaskIDs { DayPlanTaskStore.shared.delete(id: id, for: date) }
        selectedTaskIDs.removeAll()
        reload(); onChange?()
    }

    @objc private func clearSelectionClicked() {
        selectedTaskIDs.removeAll(); reload()
    }

    // MARK: Task detail modal (title, project, duration, description, sub-tasks)

    private func openTaskModal(taskID: String, from anchor: NSView) {
        guard let task = task(for: taskID) else { return }
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

        // Importance (outcome 1–10, higher = more important) → 4 colour bands shown on the task row.
        let importancePopup = NSPopUpButton()
        importancePopup.addItem(withTitle: ScheduleText.tasksImportanceUnset)   // index 0 = unset
        for o in 1...10 { importancePopup.addItem(withTitle: "\(o) — \(DayPlanTask.outcomeBandLabel(o))") }
        importancePopup.selectItem(at: task.outcome ?? 0)
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
        notesView.isHorizontallyResizable = false
        notesView.autoresizingMask = [.width]
        notesView.textContainer?.containerSize = NSSize(width: 320, height: CGFloat.greatestFiniteMagnitude)
        notesView.textContainer?.widthTracksTextView = true
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
        notesScroll.borderType = .bezelBorder
        notesScroll.translatesAutoresizingMaskIntoConstraints = false
        notesScroll.widthAnchor.constraint(equalToConstant: 320).isActive = true
        notesScroll.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let subtaskStack = NSStackView()
        subtaskStack.orientation = .vertical; subtaskStack.alignment = .leading; subtaskStack.spacing = 4
        subtaskStack.translatesAutoresizingMaskIntoConstraints = false
        modalSubtaskStack = subtaskStack

        let addSub = NSButton(title: ScheduleText.tasksAddSubtask, target: self, action: #selector(addSubtaskClicked))
        addSub.bezelStyle = .rounded; addSub.controlSize = .small
        if #available(macOS 11.0, *) { addSub.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil); addSub.imagePosition = .imageLeading }

        let cancel = NSButton(title: ScheduleText.eventCancel, target: self, action: #selector(cancelTaskModal))
        cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"
        let save = NSButton(title: ScheduleText.eventSave, target: self, action: #selector(saveTaskModal))
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
            row(ScheduleText.tasksImportanceLabel, importanceRow),
            label(ScheduleText.tasksDetailsLabel, size: 12, bold: false),
            notesScroll,
            label(ScheduleText.tasksSubtasksLabel, size: 12, bold: false),
            subtaskStack,
            addSub,
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
        // Keep Return inside the modal from starting a habit while it's open.
        snoozeSavedDefaultButton = snoozeSavedDefaultButton ?? window?.defaultButtonCell
        window?.defaultButtonCell = nil
        pop.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        taskModalPopover = pop
        vc.view.window?.makeFirstResponder(titleField)
    }

    /// Re-render the sub-task rows from `modalSubtasks`. Each row is [checkbox, title field, ✕].
    private func rebuildSubtaskRows() {
        guard let stackV = modalSubtaskStack else { return }
        stackV.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, sub) in modalSubtasks.enumerated() {
            let check = NSButton(checkboxWithTitle: "", target: nil, action: nil)
            check.state = sub.done ? .on : .off
            check.tag = i
            let field = NSTextField(string: sub.title)
            field.placeholderString = ScheduleText.tasksSubtaskPlaceholder
            field.tag = i
            field.identifier = NSUserInterfaceItemIdentifier("taskModalSubtask:\(i)")
            field.translatesAutoresizingMaskIntoConstraints = false
            field.widthAnchor.constraint(equalToConstant: 250).isActive = true
            let del = NSButton(title: "✕", target: self, action: #selector(deleteSubtaskClicked(_:)))
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
            window?.makeFirstResponder(last)
        }
    }

    @objc private func deleteSubtaskClicked(_ sender: NSButton) {
        syncSubtasksFromFields()
        guard modalSubtasks.indices.contains(sender.tag) else { return }
        modalSubtasks.remove(at: sender.tag)
        rebuildSubtaskRows()
    }

    @objc private func cancelTaskModal() {
        taskModalPopover?.close(); taskModalPopover = nil; modalTaskID = nil
        if let cell = snoozeSavedDefaultButton { window?.defaultButtonCell = cell; snoozeSavedDefaultButton = nil }
    }

    @objc private func saveTaskModal() {
        guard let id = modalTaskID, var t = task(for: id) else { cancelTaskModal(); return }
        syncSubtasksFromFields()
        let newTitle = (modalTitleField?.stringValue ?? t.title).trimmingCharacters(in: .whitespacesAndNewlines)
        if !newTitle.isEmpty { t.title = newTitle }
        let proj = (modalProjectField?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        t.project = proj.isEmpty ? nil : proj
        if let mins = Int((modalDurationField?.stringValue ?? "").filter(\.isNumber)), mins > 0 {
            t.durationMinutes = min(mins, 24 * 60)
        }
        let notes = (modalNotesView?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        t.notes = notes.isEmpty ? nil : notes
        let imp = modalImportancePopup?.indexOfSelectedItem ?? 0   // 0 = unset, 1...10 = outcome
        t.outcome = imp >= 1 ? imp : nil
        let cleaned = modalSubtasks
            .map { DayPlanSubtask(id: $0.id, title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines), done: $0.done) }
            .filter { !$0.title.isEmpty }
        t.subtasks = cleaned.isEmpty ? nil : cleaned
        DayPlanTaskStore.shared.update(t, for: date)
        cancelTaskModal()
        reload(); onChange?()
    }

    @objc private func modalImportanceChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        updateImportanceSwatch(idx >= 1 ? idx : nil)
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
        DayPlanTaskStore.shared.update(t, for: date)
        reload(); onChange?()
    }

    /// Persist a name edit. Returns true if the change is *structural* (task deleted, project
    /// changed, or the title was rewritten by stripping a `#token`) and so needs a full reload.
    /// A plain rename returns false — we must NOT reload then, or clicking straight into another
    /// row would destroy that row mid-click (the "click twice to switch fields" bug).
    @discardableResult
    private func saveName(_ sender: NSTextField) -> Bool {
        guard let raw = sender.identifier?.rawValue, raw.hasPrefix("name:") else { return false }
        let id = String(raw.dropFirst("name:".count))
        guard var t = task(for: id) else { return false }
        let trimmed = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            DayPlanTaskStore.shared.delete(id: id, for: date)   // empty name = discard
            return true
        }
        // A typed `#project` token assigns the task to that project (matched against known project
        // names, longest first, so multi-word projects work) and is stripped from the title.
        let known = DayPlanTaskStore.shared.allProjectNames()
        let (cleanTitle, token) = extractProjectToken(trimmed, known: known)
        let oldProject = t.project
        let oldOutcome = t.outcome
        var newTitle = trimmed
        if let token = token {
            let existing = known.first { $0.caseInsensitiveCompare(token) == .orderedSame }
            t.project = existing ?? token
            newTitle = cleanTitle
        }
        // A typed `*N` (1-10) sets the task's priority/importance and is stripped from the title.
        let (titleNoPriority, outcome) = extractPriorityToken(newTitle)
        if let outcome = outcome {
            t.outcome = outcome
            newTitle = titleNoPriority
        }
        t.title = newTitle
        DayPlanTaskStore.shared.update(t, for: date)
        // Name is finalized here (Enter/blur) — now, not per-keystroke, sync it: mint a to-do for a
        // from-scratch task, or push the renamed title to an already-synced one. Skip the rename API
        // when the title didn't actually change (a plain click-in/out) — but a from-scratch task still
        // attempts to mint (idempotent) since it may not be synced yet. `nil` original (begin-edit not
        // seen) is treated as "changed" so a genuine rename is never missed.
        let original = titleBeforeEdit.removeValue(forKey: id)
        let titleChanged = (original == nil) || (original != newTitle)
        if t.sourceTaskId == nil || titleChanged {
            DayPlanTaskStore.shared.syncNameOnCommit(t, on: date)
        }
        return (t.project != oldProject) || (t.outcome != oldOutcome) || (newTitle != trimmed)
    }

    @objc private func commitName(_ sender: NSTextField) {
        let structural = saveName(sender)
        onChange?()
        if structural { reload() }   // only regroup/relayout when grouping or the title text changed
    }

    /// Persist a duration edit in place (reformats the field) without a reload, so switching fields
    /// doesn't destroy the row you're clicking into.
    @objc private func commitDuration(_ sender: NSTextField) {
        guard let raw = sender.identifier?.rawValue, raw.hasPrefix("dur:") else { return }
        let id = String(raw.dropFirst("dur:".count))
        guard var t = task(for: id) else { return }
        let digits = sender.stringValue.filter(\.isNumber)
        if let m = Int(digits), m > 0 { t.durationMinutes = min(m, 24 * 60) }
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
        DayPlanTaskStore.shared.delete(id: id, for: date)
        reload(); onChange?()
    }

    // MARK: Snooze (move a task to another day via natural-language input)

    @objc private func snoozeTask(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        snoozeTaskID = id
        snoozeBulk = false
        presentSnoozePopover(from: sender)
    }

    private func presentSnoozePopover(from sender: NSView) {
        let header = label(ScheduleText.tasksSnoozeTitle, size: 13, bold: true)

        let field = NSTextField()
        field.placeholderString = ScheduleText.tasksSnoozePlaceholder
        field.identifier = NSUserInterfaceItemIdentifier("snoozeInput")
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: 230).isActive = true
        snoozeField = field

        let parsed = label("", size: 12, bold: true)
        parsed.textColor = .controlAccentColor
        snoozeParsedLabel = parsed

        let hint = label(ScheduleText.tasksSnoozeHelp, size: 11, bold: false)
        hint.textColor = .secondaryLabelColor
        hint.lineBreakMode = .byWordWrapping
        hint.maximumNumberOfLines = 0
        hint.preferredMaxLayoutWidth = 230

        let move = NSButton(title: ScheduleText.tasksSnoozeConfirm, target: self, action: #selector(confirmSnooze))
        move.bezelStyle = .rounded; move.keyEquivalent = "\r"
        let cancel = NSButton(title: ScheduleText.tasksSnoozeCancel, target: self, action: #selector(cancelSnooze))
        cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"
        let buttons = NSStackView(views: [NSView(), cancel, move])
        buttons.orientation = .horizontal; buttons.spacing = 8

        let form = NSStackView(views: [header, field, parsed, hint, buttons])
        form.orientation = .vertical; form.alignment = .leading; form.spacing = 8
        form.translatesAutoresizingMaskIntoConstraints = false
        buttons.widthAnchor.constraint(equalTo: field.widthAnchor).isActive = true

        let container = NSView()
        container.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            form.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            form.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            form.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])
        let vc = NSViewController(); vc.view = container
        let pop = NSPopover(); pop.contentViewController = vc; pop.behavior = .transient
        // While the snooze popover is open, neutralise the main window's default button (the habit
        // "Start" button responds to Return via performKeyEquivalent before the snooze field sees it,
        // which is why Return was starting a habit instead of confirming the snooze).
        snoozeSavedDefaultButton = window?.defaultButtonCell
        window?.defaultButtonCell = nil
        pop.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        snoozePopover = pop
        vc.view.window?.makeFirstResponder(field)
    }

    private func updateSnoozeParsed() {
        let input = snoozeField?.stringValue ?? ""
        if let d = parseSnoozeDate(input, from: date) {
            let f = DateFormatter(); f.dateFormat = "EEE d MMM yyyy"
            snoozeParsedLabel?.stringValue = "→ " + f.string(from: d)
        } else {
            snoozeParsedLabel?.stringValue = input.isEmpty ? "" : "— ?"
        }
    }

    @objc private func confirmSnooze() {
        guard let input = snoozeField?.stringValue,
              let target = parseSnoozeDate(input, from: date) else { NSSound.beep(); return }
        if snoozeBulk {
            for id in selectedTaskIDs { DayPlanTaskStore.shared.moveTask(id: id, from: date, to: target) }
            selectedTaskIDs.removeAll()
        } else if let id = snoozeTaskID {
            DayPlanTaskStore.shared.moveTask(id: id, from: date, to: target)
        } else {
            NSSound.beep(); return
        }
        cancelSnooze()
        reload(); onChange?()
    }

    @objc private func cancelSnooze() {
        snoozePopover?.close(); snoozePopover = nil; snoozeTaskID = nil
        // Restore the habit "Start" default button we suppressed while the popover was open.
        if let cell = snoozeSavedDefaultButton { window?.defaultButtonCell = cell; snoozeSavedDefaultButton = nil }
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        if field.identifier?.rawValue == "snoozeInput" { updateSnoozeParsed(); return }
        if field.identifier?.rawValue == "projectFilter", let combo = field as? NSComboBox {
            filterProjectCombo(combo); return
        }
        if let raw = field.identifier?.rawValue, raw.hasPrefix("name:") {
            // Persist the typed text continuously so a task is never lost even if blur/Enter is
            // missed. Project-token stripping happens on commit/accept; here we just keep the text.
            let id = String(raw.dropFirst("name:".count))
            if var t = task(for: id) {
                t.title = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                DayPlanTaskStore.shared.update(t, for: date)
            }
            // Re-measure so the field grows over multiple lines WHILE typing, not only on commit.
            field.invalidateIntrinsicContentSize()
            // Keep the habit "Start" default button suppressed while typing, in case a refresh
            // (e.g. day navigation) re-installed it — otherwise Return would start a habit.
            if editingFieldCount > 0 { window?.defaultButtonCell = nil }
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
            let b = NSButton(title: name, target: self, action: #selector(suggestionClicked(_:)))
            b.isBordered = false; b.bezelStyle = .inline; b.alignment = .left
            b.contentTintColor = .controlAccentColor
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
        let measurer = NSButton(); measurer.isBordered = false; measurer.bezelStyle = .inline
        let mpara = NSMutableParagraphStyle(); mpara.firstLineHeadIndent = 8; mpara.headIndent = 8
        let mfont = NSFont.systemFont(ofSize: 13)
        var widestButton: CGFloat = 0
        for m in matches {
            measurer.attributedTitle = NSAttributedString(string: "↹ " + m, attributes: [.font: mfont, .paragraphStyle: mpara])
            widestButton = max(widestButton, measurer.fittingSize.width)
        }
        box.setFrameSize(NSSize(width: max(160, rect.width, ceil(widestButton) + 16 + 6), height: h))
        suggestOverlay = box
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Close the inline #project suggestion list when the task list scrolls (the overlay is anchored to
    /// the field's on-screen position and can't follow the scrolling rows).
    @objc private func tasksDidScroll() {
        if suggestOverlay != nil { dismissProjectSuggestions() }
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

        let save = NSButton(title: ScheduleText.tasksNewProjectSave, target: self, action: #selector(saveNewProjectClicked(_:)))
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
        box.setFrameSize(NSSize(width: max(200, rect.width) - 20, height: h))
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
            let textColor: NSColor = selected ? .white : .controlAccentColor
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
    private func acceptProjectSuggestion(_ project: String) {
        guard let field = suggestField, let raw = field.identifier?.rawValue, raw.hasPrefix("name:") else {
            dismissProjectSuggestions(); return
        }
        let id = String(raw.dropFirst("name:".count))
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
        if var t = task(for: id) {
            t.project = project
            t.title = cleanTitle
            DayPlanTaskStore.shared.update(t, for: date)
        }
        // Replace the field text too, so the blur-triggered saveName re-parse sees no `#partial` and
        // keeps the project we just picked (otherwise it re-extracts the stale text and can override it).
        field.stringValue = cleanTitle
        dismissProjectSuggestions()
        window?.makeFirstResponder(nil)
        reload(); onChange?()
    }

    // While editing a task field, suppress the window's default button (the habit "Start" button is
    // the window default and fires on Return via performKeyEquivalent — before the field sees Enter).
    private var savedDefaultButtonCell: NSButtonCell?
    private var editingFieldCount = 0
    /// Title of a task when its name field began editing, so on commit we only push a rename to the
    /// backend if it actually changed (a plain click-in/click-out shouldn't hit the API).
    private var titleBeforeEdit: [String: String] = [:]
    // Live project suggestions shown under the project combo. NSComboBox's own dropdown only opens on
    // the chevron, not as you type, so we draw our own list (case-insensitive substring) inside the
    // task-details popover.
    private weak var comboSuggestField: NSComboBox?
    private var comboSuggestMatches: [String] = []
    private var comboSuggestOverlay: NSView?

    /// Case-insensitive substring filter for the project combo box (e.g. "but" → "Focus Button"): keeps
    /// the combo's own (chevron) list filtered AND shows a live suggestion list under it as you type.
    private func filterProjectCombo(_ combo: NSComboBox) {
        let typed = combo.stringValue.trimmingCharacters(in: .whitespaces)
        let all = DayPlanTaskStore.shared.allProjectNames()
        let matches = typed.isEmpty ? [] : all.filter { $0.range(of: typed, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        combo.removeAllItems()
        combo.addItems(withObjectValues: matches.isEmpty ? all : matches)
        showComboProjectSuggestions(Array(matches.prefix(6)), for: combo)
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
            let b = NSButton(title: name, target: self, action: #selector(comboSuggestionClicked(_:)))
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
            let structural = saveName(field)
            onChange?()
            if structural { reload() }
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

/// Top-aligned clip so the routine list grows downward and scrolls.
final class TopFlippedClipView: NSClipView { override var isFlipped: Bool { true } }

/// Bottom-right panel: a minimal replacement for the custom-routines screen. Lists the user's
/// on-demand ("ad hoc") custom routines, each with a play button to start it.
final class CustomRoutinesPanel: NSView {

    private let stack = NSStackView()
    private let titleLabel = NSTextField(labelWithString: ScheduleText.customRoutinesTitle)

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
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
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
        let play = NSButton(title: "", target: self, action: #selector(playClicked(_:)))
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
