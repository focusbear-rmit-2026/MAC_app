//
//  AccessibilityChecks.swift
//  Focus BearUITests
//
//  What "VoiceOver makes sense" and "keyboard accessible" mean for this suite, as reusable checks.
//  Every failure names the screen and the element (type, label, identifier, position) so it can be
//  acted on without re-running anything.
//

import XCTest

/// A screen the accessibility checks run on, and the issues that already own some of its problems.
struct AccessibilityScreen {
    let name: String
    var voiceOverKnownIssues: [KnownAccessibilityIssue] = []
    var keyboardKnownIssues: [KnownAccessibilityIssue] = []
}

/// A problem that is ticketed and being fixed on another branch. Findings it covers are recorded as
/// expected (non-strict) failures against the ticket, so the suite stays green meanwhile and simply
/// stops reporting them once the fix lands.
struct KnownAccessibilityIssue {
    let ticket: String
    /// The finding mentions this (an element type, identifier or screen detail); empty covers all.
    var appliesTo: String = ""
    /// Why it is expected to fail, shown with the ticket.
    var reason = "being fixed on another branch"

    func covers(_ finding: String) -> Bool { appliesTo.isEmpty || finding.contains(appliesTo) }
}

/// What a finding from Apple's audit calls each audit type, so a known issue can be scoped to one.
enum AccessibilityAuditName {
    static let contrast = "contrast"
    static let elementDetection = "element detection"
    static let hitRegion = "hit region"
    static let elementDescription = "element description"
    static let action = "action"
    static let parentChild = "parent/child"

    /// How a finding of this audit type starts: "audit (contrast)".
    static func finding(_ name: String) -> String { "audit (\(name))" }

    /// How it starts when XCTest gave no element for the issue: "audit (parent/child) with no element".
    static func elementlessFinding(_ name: String) -> String { "\(finding(name)) with no element" }
}

/// Something the checks flag that is right as it is, and why — never a way to silence a real bug.
struct AcceptedAccessibilityFinding {
    let finding: String
    let reason: String

    static let all = [
        AcceptedAccessibilityFinding(finding: "Label duplicates role description — button “Focus Button”",
                                     reason: "Focus Button is the name of the hardware product, not a description of the control"),
    ]
}

extension FocusBearUITestCase {
    private static let interactiveTypes: Set<XCUIElement.ElementType> = [
        .button, .checkBox, .radioButton, .textField, .secureTextField, .searchField, .textView, .link,
        .popUpButton, .menuButton, .comboBox, .slider, .stepper, .incrementArrow, .switch, .toggle,
        .segmentedControl, .disclosureTriangle,
    ]
    private static let keyboardFocusableTypes: Set<XCUIElement.ElementType> = [
        .button, .checkBox, .radioButton, .textField, .secureTextField, .searchField, .textView, .link,
        .popUpButton, .menuButton, .comboBox, .slider, .stepper, .switch, .toggle, .segmentedControl,
    ]
    /// Read aloud, these say nothing about what the control does.
    private static let genericNames: Set<String> = [
        "button", "image", "checkbox", "check box", "text field", "link", "pop up button", "popup",
        "slider", "group", "icon", "switch", "toggle", "menu button", "untitled",
    ]
    /// An SF Symbol or asset name leaking through as the label: "square.and.pencil", "img_close",
    /// "NSTouchBarGoForwardTemplate", "eyeGray Icon".
    private static let assetNamePatterns = [
        #"^[a-z0-9]+(\.[a-z0-9]+)+$"#,
        #"^[A-Za-z0-9]+(_[A-Za-z0-9]+)+$"#,
        #"^NS[A-Z][A-Za-z]*Template$"#,
        #"^[a-z]+[A-Z][A-Za-z0-9]* [Ii]con$"#,
    ]
    /// Rows closer than this are on the same line for reading-order purposes.
    private static let readingOrderTolerance: CGFloat = 8
    private static let tabPressLimit = 60
    /// Scrolling is the arrow keys' job; a Tab stop on one is a stop that does nothing.
    private static let scrollerTypes: Set<XCUIElement.ElementType> = [.scrollBar, .scrollView, .valueIndicator]
    /// A control flush with the window edge reports a frame a point past it.
    private static let frameTolerance: CGFloat = 1

    // MARK: - VoiceOver

    /// Apple's audit plus the suite's own label, image, duplicate and reading-order checks on
    /// whatever is on screen now.
    func checkVoiceOver(on screen: AccessibilityScreen, in root: XCUIElement? = nil,
                        file: StaticString = #filePath, line: UInt = #line) throws {
        var findings = [String]()
        findings += auditFindings(scopedTo: root)
        findings += try labelFindings(in: root ?? mainWindow)
        report(findings, on: screen.name, known: screen.voiceOverKnownIssues,
               file: file, line: line)
    }

    /// `scope`: the window or sheet the screen under test is, when the caller knows it.
    private func auditFindings(scopedTo scope: XCUIElement? = nil) -> [String] {
        guard #available(macOS 14.0, *) else { return [] }
        var findings = [String]()
        let chromeFrames = systemChromeFrames()
        let foreground = scope.flatMap(treeKeys(of:)) ?? frontOverlayContents()
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                let auditName = Self.name(of: issue.auditType)
                // XCTest sometimes reports an issue with no element, or one gone before it can be
                // read. There is then nothing to name and nothing to rule out as macOS's own chrome,
                // so it is reported by audit type alone, for a ticket to own by type and screen.
                guard let node = issue.element.flatMap({ try? $0.snapshot() }) else {
                    findings.append("\(AccessibilityAuditName.elementlessFinding(auditName)): \(issue.compactDescription)")
                    return true
                }
                if Self.isSystemChrome(node) || Self.isUITestLandmark(node)
                    || chromeFrames.contains(where: { $0.contains(node.frame) }) { return true }
                if let foreground, !foreground.contains(Self.treeKey(of: node)) { return true }
                findings.append("\(AccessibilityAuditName.finding(auditName)): \(issue.compactDescription) — \(Self.describe(node))"
                                + (issue.auditType == .contrast ? " [\(issue.detailedDescription)]" : ""))
                return true
            }
        } catch {
            findings.append("the accessibility audit could not run: \(error)")
        }
        return Array(Set(findings)).sorted()
    }

    /// While a sheet, popover or modal dialog is up, the elements inside it — keyed by type, id and
    /// frame. The audit reads the window underneath through the sheet's dimming and reports its text
    /// as low-contrast; those elements are audited on their own screen, so findings are kept only for
    /// what is inside the thing on top. Nil when nothing is on top: everything counts.
    private func frontOverlayContents() -> Set<String>? {
        let candidates = [app.sheets, app.popovers, app.dialogs].flatMap(\.allElementsBoundByIndex)
        return candidates.last(where: \.exists).flatMap(treeKeys(of:))
    }

    private func treeKeys(of element: XCUIElement) -> Set<String>? {
        guard let root = try? element.snapshot() else { return nil }
        var keys = Set<String>()
        var stack = [root]
        while let node = stack.popLast() {
            keys.insert(Self.treeKey(of: node))
            stack.append(contentsOf: node.children)
        }
        return keys
    }

    private static func treeKey(of node: XCUIElementSnapshot) -> String {
        "\(node.elementType.rawValue)|\(node.identifier)|\(node.frame)"
    }

    /// The window's own close/minimise/zoom buttons, the menu bar, the Touch Bar and scroll bars
    /// belong to macOS, not the app.
    private static let systemChromeIdentifierPrefix = "_XCUI:"
    /// A help tag is the tooltip macOS shows while the pointer rests on a control: its window, not the app's.
    private static let systemChromeTypes: Set<XCUIElement.ElementType> = [
        .menuBar, .menuBarItem, .statusItem, .touchBar, .scrollBar, .valueIndicator, .incrementArrow, .decrementArrow,
        .helpTag,
    ]

    static func isSystemChrome(_ node: XCUIElementSnapshot) -> Bool {
        node.identifier.hasPrefix(systemChromeIdentifierPrefix) || systemChromeTypes.contains(node.elementType)
            || node.frame.maxY <= menuBarHeight || node.frame.minY < 0   // menu-bar extras such as "emoji & symbols"
    }

    /// The window buttons' own parts (the zoom button's inner group) have no identifier of their own.
    /// Each window's title bar too: macOS draws an inactive window's title (the main window behind a
    /// sheet or pop-up) in its own dimmed grey, which the contrast audit flags as the app's text.
    private func systemChromeFrames() -> [CGRect] {
        let windowButtons = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", Self.systemChromeIdentifierPrefix))
            .allElementsBoundByIndex.map(\.frame)
        let titleBars = app.windows.allElementsBoundByIndex.map(\.frame).filter { !$0.isEmpty }
            .map { CGRect(x: $0.minX, y: $0.minY, width: $0.width, height: Self.titleBarHeight) }
        return windowButtons + titleBars
    }

    private static let titleBarHeight: CGFloat = 28

    /// The unnamed groups only a UI-test build adds, so tests can tell screens apart — not app UI.
    private static let uiTestLandmarkPrefixes = [
        UITestContract.Identifier.Screen.prefix, UITestContract.Identifier.Settings.panePrefix,
        UITestContract.Identifier.Onboarding.stepPrefix, UITestContract.Identifier.DayPlan.view,
        UITestContract.Identifier.Blocking.intentionPrompt, UITestContract.Identifier.Blocking.focusBlockPrompt,
        UITestContract.Identifier.Routine.accountabilityBuddySheet,
        UITestContract.Identifier.CustomAlert.view, UITestContract.Identifier.TeacherSession.lockedAlert,
    ]

    private static func isUITestLandmark(_ node: XCUIElementSnapshot) -> Bool {
        uiTestLandmarkPrefixes.contains { node.identifier.hasPrefix($0) }
    }

    private func labelFindings(in root: XCUIElement) throws -> [String] {
        let window = try root.snapshot()
        var findings = [String]()
        walk(window) { node, parent in
            guard !node.frame.isEmpty, !Self.isSystemChrome(node) else { return }
            findings += Self.nameFindings(for: node)
            if let parent { findings += Self.siblingFindings(in: parent) }
        }
        return Array(Set(findings)).sorted()
    }

    private static func nameFindings(for node: XCUIElementSnapshot) -> [String] {
        let name = spokenName(of: node)
        if node.elementType == .image {
            if name.isEmpty { return ["decorative image isn't hidden from VoiceOver — \(describe(node))"] }
            return isAssetName(name) ? ["image is announced by its asset name “\(name)” — \(describe(node))"] : []
        }
        guard interactiveTypes.contains(node.elementType) else { return [] }
        if name.isEmpty { return ["no accessible name — \(describe(node))"] }
        if isAssetName(name) { return ["announced by its asset name “\(name)” — \(describe(node))"] }
        if genericNames.contains(name.lowercased()) { return ["announced only as “\(name)” — \(describe(node))"] }
        return []
    }

    private static func siblingFindings(in parent: XCUIElementSnapshot) -> [String] {
        let controls = parent.children.filter { interactiveTypes.contains($0.elementType) && !$0.frame.isEmpty }
        var findings = [String]()
        let groups = Dictionary(grouping: controls) { "\(spokenName(of: $0))|\(String(describing: $0.value ?? ""))" }
        for (key, twins) in groups where twins.count > 1 && !key.hasPrefix("|") {
            findings.append("\(twins.count) sibling controls are all announced as “\(spokenName(of: twins[0]))” — \(describe(twins[0]))")
        }
        let placed = parent.children.filter { !$0.frame.isEmpty }
        for (earlier, later) in zip(placed, placed.dropFirst()) where readsUpward(from: earlier, to: later) {
            findings.append("reading order goes up: \(describe(later)) is read after \(describe(earlier)), which is below it")
        }
        return findings
    }

    /// `later` is read after `earlier` but sits wholly above it in the same column.
    private static func readsUpward(from earlier: XCUIElementSnapshot, to later: XCUIElementSnapshot) -> Bool {
        let sameColumn = later.frame.minX < earlier.frame.maxX && earlier.frame.minX < later.frame.maxX
        return sameColumn && later.frame.maxY + readingOrderTolerance <= earlier.frame.minY
    }

    // MARK: - Keyboard

    /// Tabs through the screen and checks every control on it can be reached, and that focus moves.
    /// Returns the elements focus visited, in order.
    ///
    /// Controls are matched by what they are (type, name, id), not where: Tab scrolls the sidebar
    /// and long pages, so the same control is at a different place later in the walk.
    @discardableResult
    func checkKeyboardReachability(on screen: AccessibilityScreen, in root: XCUIElement? = nil,
                                   file: StaticString = #filePath, line: UInt = #line) throws -> [String] {
        let window = try (root ?? mainWindow).snapshot()
        let controls = reachableControls(in: window)
        var visited = [String]()
        var visitedKeys = Set<String>()
        var firstKey: String?
        var findings = [String]()
        var previous: String?
        var focus = focusedSnapshot()
        for _ in 0..<Self.tabPressLimit {
            guard let step = tabStep(from: focus) else { break }
            guard step.isInsideTestApp else {
                findings.append("Tab moves focus out of the app (to \(Self.frontmostAppName))")
                break
            }
            focus = step.focus
            guard let node = step.focus else { continue }
            let focused = Self.describe(node)
            if !node.frame.isEmpty, !window.frame.contains(node.frame.insetBy(dx: Self.frameTolerance, dy: Self.frameTolerance)) {
                findings.append("focus not scrolled into view: \(focused)")
            }
            if focused == previous {
                findings.append("focus trap: Tab leaves focus on \(focused)")
                break
            }
            if Self.scrollerTypes.contains(node.elementType) {
                findings.append("Tab stops on a scroller: \(focused)")
            }
            // Back to a control already seen: the cycle is complete. Each control once per cycle
            // means it comes back to the first stop, not to one in the middle.
            let key = Self.identity(of: node)
            guard visitedKeys.insert(key).inserted else {
                if key != firstKey {
                    findings.append("Tab cycle doesn't wrap to its start: after \(visited.count) stops it returns to \(focused)")
                }
                break
            }
            visited.append(focused)
            firstKey = firstKey ?? key
            previous = focused
        }
        if visited.isEmpty { findings.append("Tab never moves keyboard focus onto anything") }
        for control in controls where control.keys.isDisjoint(with: visitedKeys) {
            findings.append("can't reach with Tab: \(control.description)")
        }
        findings += shiftTabFindings(expected: visitedKeys, count: visited.count)
        report(findings, on: screen.name, known: screen.keyboardKnownIssues,
               file: file, line: line)
        return visited
    }

    /// Shift-Tab should walk the same controls backwards. Where it sticks is named, since that is
    /// what makes everything behind it unreachable.
    private func shiftTabFindings(expected: Set<String>, count: Int) -> [String] {
        guard count > 1 else { return [] }
        var seen = Set<String>()
        var previous: String?
        var focus = focusedSnapshot()
        for _ in 0...count {
            guard let step = tabStep(from: focus, backwards: true), step.isInsideTestApp else { break }
            focus = step.focus
            guard let node = step.focus else { continue }
            let key = Self.identity(of: node)
            if key == previous { return ["Shift-Tab trap: focus stays on \(Self.describe(node))"] }
            seen.insert(key)
            previous = key
        }
        let missing = expected.subtracting(seen)
        return missing.isEmpty ? [] : ["Shift-Tab doesn't reach: \(missing.sorted().joined(separator: "; "))"]
    }

    /// One Tab (or Shift-Tab) and one look at where focus went. Pressing is safe while the test app is
    /// frontmost and focus isn't in the menu bar; the previous step's look answers the second half.
    /// Each Tab was four queries of the focused element — about 0.4 s — and a page walk is dozens.
    /// Nil when it isn't safe to press.
    private func tabStep(from focus: XCUIElementSnapshot?, backwards: Bool = false) -> (isInsideTestApp: Bool, focus: XCUIElementSnapshot?)? {
        if let thief = bringTestAppToFront() {
            XCTFail("refused to press Tab: another app took focus: \(thief)")
            return nil
        }
        if let focus, Self.isInMenuBar(focus) {
            XCTFail("refused to press Tab: focus is in the menu bar (\(Self.describe(focus)))")
            return nil
        }
        app.typeKey(.tab, modifierFlags: backwards ? .shift : [])
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == UITestContract.bundleIdentifier else {
            return (false, nil)
        }
        let now = focusedSnapshot()
        return (now.map { !Self.isInMenuBar($0) } ?? true, now)
    }

    /// What a control is, independent of where it has scrolled to.
    private static func identity(of node: XCUIElementSnapshot) -> String {
        let identifier = node.identifier.isEmpty ? "" : " id=\(node.identifier)"
        return "\(typeName(node.elementType)) “\(spokenName(of: node))”\(identifier)"
    }

    /// A Tab stop the keyboard should reach, and the focused elements that count as reaching it.
    private struct TabStop {
        let keys: Set<String>
        let description: String
    }

    /// Controls a segmented control or radio group is drawn with: one Tab stop, ← / → between them.
    private static let groupTypes: Set<XCUIElement.ElementType> = [.segmentedControl, .radioGroup]

    /// Enabled, visible controls in the front window that the keyboard should be able to reach. A
    /// segmented control is one stop, reached by focusing any of its segments; a search field's
    /// magnifier and clear buttons are part of the field, never stops of their own.
    private func reachableControls(in window: XCUIElementSnapshot) -> [TabStop] {
        var stops = [TabStop]()
        var groupIndex = [String: Int]()
        walk(window) { node, parent in
            guard Self.keyboardFocusableTypes.contains(node.elementType), node.isEnabled, !Self.isSystemChrome(node),
                  !node.frame.isEmpty, window.frame.intersects(node.frame),
                  parent?.elementType != .searchField else { return }
            guard let parent, Self.groupTypes.contains(parent.elementType) else {
                stops.append(TabStop(keys: [Self.identity(of: node)], description: Self.describe(node)))
                return
            }
            let groupKey = Self.describe(parent)
            if let index = groupIndex[groupKey] {
                let stop = stops[index]
                stops[index] = TabStop(keys: stop.keys.union([Self.identity(of: node)]),
                                       description: stop.description + ", “\(Self.spokenName(of: node))”")
            } else {
                groupIndex[groupKey] = stops.count
                stops.append(TabStop(keys: [Self.identity(of: node)],
                                     description: "\(Self.typeName(parent.elementType)) of “\(Self.spokenName(of: node))”"))
            }
        }
        return stops
    }

    /// Moves focus with Tab until `element` has it. Returns false once focus has gone all the way
    /// round, or stopped moving, without getting there.
    @discardableResult
    func tab(to element: XCUIElement) -> Bool {
        var seen = Set<String>()
        for _ in 0..<Self.tabPressLimit {
            if hasKeyboardFocus(element) { return true }
            guard press(.tab), isFocusInsideTestApp else { return false }
            guard let focused = focusedElementDescription() else { continue }
            if !seen.insert(focused).inserted { return hasKeyboardFocus(element) }
        }
        return hasKeyboardFocus(element)
    }

    func focusedElementDescription() -> String? {
        focusedSnapshot().map(Self.describe)
    }

    // MARK: - Reporting

    func report(_ findings: [String], on screen: String, known: [KnownAccessibilityIssue] = [],
                file: StaticString = #filePath, line: UInt = #line) {
        let findings = findings.filter { finding in !AcceptedAccessibilityFinding.all.contains { finding.contains($0.finding) } }
        guard !findings.isEmpty else { return }
        let known = known + KnownAccessibilityIssue.everyScreen
        if findings.contains(where: { finding in !known.contains { $0.covers(finding) } }) {
            recordDiagnostics(named: "accessibility — \(screen)")
        }
        let location = XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: file, lineNumber: line))
        XCTContext.runActivity(named: "\(screen): \(findings.count) accessibility problem(s)") { _ in
            for finding in findings {
                let issue = XCTIssue(type: .assertionFailure, compactDescription: "[\(screen)] \(finding)",
                                     sourceCodeContext: location)
                if let owner = known.first(where: { $0.covers(finding) }) {
                    XCTExpectFailure("\(owner.ticket): \(owner.reason)", options: .nonStrict()) {
                        self.record(issue)
                    }
                } else {
                    record(issue)
                }
            }
        }
    }

    // MARK: - Snapshot helpers

    /// Every element under `node`, except inside a scroll bar: its page areas are unnamed buttons
    /// macOS draws, which VoiceOver reads as part of the scroll bar.
    private func walk(_ node: XCUIElementSnapshot, parent: XCUIElementSnapshot? = nil,
                      visit: (XCUIElementSnapshot, XCUIElementSnapshot?) -> Void) {
        visit(node, parent)
        guard node.elementType != .scrollBar else { return }
        for child in node.children { walk(child, parent: node, visit: visit) }
    }

    static func spokenName(of node: XCUIElementSnapshot) -> String {
        [node.label, node.title, node.placeholderValue ?? ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    private static func isAssetName(_ name: String) -> Bool {
        assetNamePatterns.contains { name.range(of: $0, options: .regularExpression) != nil }
    }

    static func describe(_ node: XCUIElementSnapshot?) -> String {
        guard let node else { return "(no element)" }
        let name = spokenName(of: node)
        let identifier = node.identifier.isEmpty ? "" : " id=\(node.identifier)"
        let frame = node.frame.integral
        return "\(typeName(node.elementType)) “\(name)”\(identifier) at (\(Int(frame.minX)),\(Int(frame.minY)) \(Int(frame.width))×\(Int(frame.height)))"
    }

    static func describe(element: XCUIElement?) -> String {
        describe(element.flatMap { try? $0.snapshot() })
    }

    private static func typeName(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .button: return "button"
        case .checkBox: return "checkbox"
        case .radioButton: return "radio button"
        case .textField: return "text field"
        case .secureTextField: return "secure text field"
        case .searchField: return "search field"
        case .textView: return "text view"
        case .link: return "link"
        case .popUpButton: return "pop-up button"
        case .menuButton: return "menu button"
        case .comboBox: return "combo box"
        case .slider: return "slider"
        case .switch: return "switch"
        case .image: return "image"
        case .segmentedControl: return "segmented control"
        case .radioGroup: return "radio group"
        case .stepper: return "stepper"
        case .table: return "table"
        case .outline: return "outline"
        case .staticText: return "text"
        case .group: return "group"
        case .window: return "window"
        case .scrollBar: return "scroll bar"
        case .popover: return "popover"
        case .other: return "container"
        default: return "element(\(type.rawValue))"
        }
    }

    @available(macOS 14.0, *)
    private static func name(of type: XCUIAccessibilityAuditType) -> String {
        let names: [(XCUIAccessibilityAuditType, String)] = [
            (.contrast, AccessibilityAuditName.contrast), (.elementDetection, AccessibilityAuditName.elementDetection),
            (.hitRegion, AccessibilityAuditName.hitRegion),
            (.sufficientElementDescription, AccessibilityAuditName.elementDescription),
            (.action, AccessibilityAuditName.action), (.parentChild, AccessibilityAuditName.parentChild),
        ]
        return names.filter { type.contains($0.0) }.map(\.1).joined(separator: ", ")
    }
}
