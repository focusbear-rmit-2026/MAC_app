//
//  SafeInteraction.swift
//  Focus BearUITests
//
//  Every click and key press in the suite goes through here, so none can land outside the app under
//  test. Real incident: `app.menuItems.firstMatch` resolved to the MENU BAR's Apple ▸ About This
//  Mac, and a test clicked it on a developer's Mac. So:
//    • tap() clicks only a hittable element inside one of the test app's own windows, below the menu
//      bar — never a menu-bar or status item;
//    • chooseMenuItem() picks only from the menu the given control just opened;
//    • press() types only while the test app is frontmost with focus in it and not in the menu bar;
//    • any system window a test opens is closed afterwards and that test is failed by name.
//

import AppKit
import XCTest

extension FocusBearUITestCase {
    /// The menu bar's height on the main display — taller than the classic 25 on notched and scaled
    /// displays, which put app elements at y 26–30 in it.
    static let menuBarHeight: CGFloat = {
        let classicHeight: CGFloat = 25
        guard let main = NSScreen.screens.first else { return classicHeight }
        return max(classicHeight, main.frame.maxY - main.visibleFrame.maxY)
    }()
    private static let forbiddenTypes: Set<XCUIElement.ElementType> = [.menuBar, .menuBarItem, .statusItem]
    /// The one short wait for things that may or may not be there (an optional step, an absence).
    static let optionalWait: TimeInterval = 1
    private static let appearancePollInterval: TimeInterval = 0.1
    private static let scrollAttemptLimit = 6
    private static let middle = CGVector(dx: 0.5, dy: 0.5)

    // MARK: - Clicking

    /// Clicks `element` if, and only if, it is a control inside a test-app window.
    func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        failIfCovered(file: file, line: line)
        // The usual case, in one element-tree query: a control already wholly on screen in a test-app
        // window. Every check below costs a query each, and asking `isHittable` of a SwiftUI button
        // took up to 1.7 s. A switch or checkbox gets XCUITest's own click (its hit point: the switch,
        // not its label); anything else is clicked at its middle. A row a scroll view clips while it
        // is still inside the window (the Settings sidebar) is scrolled in by its own helper.
        if let node = plainlyClickableSnapshot(element) {
            if Self.pressableTypes.contains(node.elementType), pressInApp(node, action: .press) { return }
            if Self.focusableTypes.contains(node.elementType), pressInApp(node, action: .focus) { return }

            if Self.hitPointTypes.contains(node.elementType) { return element.click() }
            return clickPoint(CGPoint(x: node.frame.midX, y: node.frame.midY), orMiddleOf: element)
        }
        scrollIntoView(element)
        waitUntilHittable(element)
        if unsafeTapReason(element) == nil { return element.click() }
        // A SwiftUI plain-style button often reports itself unhittable (its hit point resolves to its
        // own label or icon) while plainly visible; once wholly inside a test-app window, its middle
        // is still the button.
        if isWhollyInsideTestAppWindow(element), unsafeTapReason(element, requiringHittable: false) == nil {
            return element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }
        recordDiagnostics(named: "refused click")
        XCTFail("refused to click \(Self.describe(element: element)): \(unsafeTapReason(element) ?? "unknown")",
                file: file, line: line)
    }

    /// Clicks a screen point already known to be inside a test-app window. Relative to the app, not
    /// the element: clicking an element's own coordinate looks the element up again, about 0.45 s.
    private func clickPoint(_ point: CGPoint, orMiddleOf element: XCUIElement) {
        let appFrame = app.frame
        guard !appFrame.isEmpty, appFrame.contains(point) else {
            return element.coordinate(withNormalizedOffset: Self.middle).click()
        }
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x - appFrame.minX, dy: point.y - appFrame.minY)).click()
    }

    private func plainlyClickableSnapshot(_ element: XCUIElement) -> XCUIElementSnapshot? {
        guard let node = try? element.snapshot(), !Self.forbiddenTypes.contains(node.elementType) else { return nil }
        let frame = node.frame
        guard !frame.isEmpty, frame.minY >= Self.menuBarHeight, testAppWindowFrames().contains(where: { $0.contains(frame) }) else { return nil }
        return node
    }

    /// Buttons are pressed, and text fields focused, the way VoiceOver does it (`pressInApp`): about
    /// 0.15 s instead of XCUITest's 0.4–0.6 s synthesized click. A test about the pointer itself
    /// (hit-testing, something drawn over a control) uses `clickWithPointer`.
    /// Not pop-up or menu buttons: their menu is what the test goes on to use, and a real click is
    /// what opens it where XCUITest can see it. Not radio buttons: a SwiftUI segment reports the press
    /// as done without selecting itself (the To-do sort modes didn't change).
    private static let pressableTypes: Set<XCUIElement.ElementType> = [.button, .checkBox, .disclosureTriangle]
    private static let focusableTypes: Set<XCUIElement.ElementType> = [.textField, .secureTextField, .textView, .searchField]


    /// Asks the test app to press the control the snapshot shows (`UITestContract.Command.press`) and
    /// waits for its answer. False — so the caller clicks instead — when the app can't single it out.
    private func pressInApp(_ node: XCUIElementSnapshot, action: UITestContract.PressAction) -> Bool {
        typealias Command = UITestContract.Command
        guard !node.identifier.isEmpty else { return false }
        let requestId = String(UUID().uuidString.prefix(Self.pressRequestIdLength))
        let request = [requestId, node.identifier, "\(node.frame.midX)", "\(node.frame.midY)", action.rawValue,
                       "\(Date().timeIntervalSince1970)"]
            .joined(separator: String(Command.requestFieldSeparator))
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(Command.press), object: request,
                                                                     userInfo: nil, deliverImmediately: true)
        let answer = Command.pressDonePrefix + requestId + ":"
        let statusItem = app.descendants(matching: .any).matching(identifier: UITestContract.Identifier.MenuBar.statusItem).firstMatch
        let deadline = Date().addingTimeInterval(UITestContract.Command.pressRequestLifetime + Self.pressAnswerMargin)
        repeat {
            if let value = statusItem.value as? String, value.hasPrefix(answer) {
                guard value == answer + UITestContract.PressOutcome.pressed.rawValue else { return false }
                // The app answers first and presses on its next run-loop turn. A second round trip
                // is answered only after that turn, so the press has happened before the test reads
                // its result (Use AI read the checkbox before it flipped, 1 run in 3). A press that
                // opened a modal holds the round trip, which then simply lapses.
                _ = focusedIdentifierFromApp()
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.pressPollInterval))
        } while Date() < deadline
        return false
    }

    /// Selects the table row `element` is drawn in, as clicking the row does. False when it isn't in
    /// a table the app can find, or isn't plainly on screen.
    func selectRowInApp(_ element: XCUIElement) -> Bool {
        guard let node = plainlyClickableSnapshot(element) else { return false }
        return pressInApp(node, action: .select)
    }

    private static let pressRequestIdLength = 8
    /// The app answers within a few hundredths of a second; one that doesn't (an alert's own event
    /// loop running) gets a real click instead, after the request has lapsed in the app.
    private static let pressAnswerMargin: TimeInterval = 0.05
    private static let pressPollInterval: TimeInterval = 0.02

    /// A real, synthesized mouse click, for tests whose subject is the pointer (hit-testing, overlays).
    func clickWithPointer(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        failIfCovered(file: file, line: line)
        guard let node = plainlyClickableSnapshot(element) else { return tap(element, file: file, line: line) }
        if Self.hitPointTypes.contains(node.elementType) { return element.click() }
        clickPoint(CGPoint(x: node.frame.midX, y: node.frame.midY), orMiddleOf: element)
    }

    /// Controls whose clickable part isn't their middle: the box or switch sits at one end of the row.
    /// Pop-up and menu buttons too: their menu opened from a click at a bare screen point didn't
    /// list its items in time for the Escape test.
    private static let hitPointTypes: Set<XCUIElement.ElementType> = [.checkBox, .switch, .toggle, .radioButton,
                                                                      .popUpButton, .menuButton]

    private func isWhollyInsideTestAppWindow(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        return !frame.isEmpty && testAppWindowFrames().contains { $0.contains(frame) }
    }

    /// Clicks the middle of something drawn but not itself a control (a Day Plan habit row's text,
    /// under the row's own click handling) — still only inside a test-app window.
    func tapCenter(of element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        if let problem = unsafeTapReason(element, requiringHittable: false) {
            XCTFail("refused to click \(Self.describe(element: element)): \(problem)", file: file, line: line)
            return
        }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
    }

    /// A sheet sliding in exists before it can be clicked.
    private func waitUntilHittable(_ element: XCUIElement) {
        let deadline = Date().addingTimeInterval(Self.optionalWait)
        while element.exists, !element.isHittable, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(Self.appearancePollInterval))
        }
    }

    /// Scrolls the scroll view holding `element` until the element is wholly inside it — a sidebar
    /// item below the fold once TOOLS is expanded, or a Stats tab past the right edge of its strip.
    /// (XCUITest calls a clipped control hittable when its centre is still in the window, and the
    /// click then lands on whatever covers that point.) Scroll events go only to a scroll view inside
    /// a test-app window.
    func scrollIntoView(_ element: XCUIElement) {
        guard element.exists, !element.identifier.isEmpty,
              let scrollView = innermostScrollView(holding: element),
              unsafeTapReason(scrollView, requiringHittable: false) == nil else { return }
        let visible = scrollView.frame
        // Scrolled at a point rather than on the element: a scroll view filled by its table or
        // document view has no hit point of its own.
        let middle = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        for _ in 0..<Self.scrollAttemptLimit where !visible.contains(element.frame) {
            let frame = element.frame
            let isClippedVertically = frame.minY < visible.minY || frame.maxY > visible.maxY
            let deltaY = isClippedVertically ? (frame.midY > visible.midY ? -visible.height : visible.height) / 2 : 0
            let isClippedHorizontally = frame.minX < visible.minX || frame.maxX > visible.maxX
            let deltaX = isClippedHorizontally ? (frame.midX > visible.midX ? -visible.width : visible.width) / 2 : 0
            middle.scroll(byDeltaX: deltaX, deltaY: deltaY)
        }
    }

    private func innermostScrollView(holding element: XCUIElement) -> XCUIElement? {
        app.scrollViews.containing(element.elementType, identifier: element.identifier).allElementsBoundByIndex
            .filter { $0.exists && !$0.frame.isEmpty }
            .min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
    }

    private func unsafeTapReason(_ element: XCUIElement, requiringHittable: Bool = true) -> String? {
        // A window of another app over the test app would take the click.
        if let thief = bringTestAppToFront() { return "another app took focus: \(thief)" }
        guard element.exists else { return "it doesn't exist" }
        guard !Self.forbiddenTypes.contains(element.elementType) else { return "it is in the menu bar" }
        guard !requiringHittable || element.isHittable else { return "it isn't hittable" }
        let frame = element.frame
        guard frame.minY >= Self.menuBarHeight else { return "it is in the menu bar area" }
        guard testAppWindowFrames().contains(where: { $0.intersects(frame) }) else {
            return "it is outside the test app's windows"
        }
        return nil
    }

    /// The test app's windows that are on a display (sheets and popovers are windows too), plus any
    /// menu it has open below the menu bar — a pop-up or context menu, never a menu-bar menu, which
    /// nothing here opens (menu-bar items can't be tapped).
    ///
    /// Read from the window server, not the element tree: a sheet or menu closing between listing
    /// the app's windows and reading one's frame failed the test ("No matches found for Element at
    /// index 3").
    private func testAppWindowFrames() -> [CGRect] {
        let displays = NSScreen.screens.map(\.frame)
        return testAppWindows().compactMap(Self.frame(of:)).filter { frame in
            !frame.isEmpty && frame.minY >= Self.menuBarHeight && displays.contains { $0.intersects(frame) }
        }
    }

    /// The test app's on-screen windows, front to back, menus and popovers included.
    private func testAppWindows() -> [[String: Any]] {
        guard let testPid = NSRunningApplication.runningApplications(withBundleIdentifier: UITestContract.bundleIdentifier).first?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        else { return [] }
        return windows.filter { ($0[kCGWindowOwnerPID as String] as? pid_t) == testPid }
    }

    // MARK: - Menus

    /// Opens `control`'s menu and chooses its `index`th item — from that menu only.
    func chooseMenuItem(at index: Int, openedBy control: XCUIElement,
                        file: StaticString = #filePath, line: UInt = #line) {
        guard let items = openMenu(of: control, file: file, line: line), items.indices.contains(index) else {
            XCTFail("the menu from \(Self.describe(element: control)) has no item \(index)", file: file, line: line)
            return
        }
        items[index].click()
    }

    /// Opens `control`'s menu and chooses the item titled `title` — from that menu only.
    func chooseMenuItem(titled title: String, openedBy control: XCUIElement,
                        file: StaticString = #filePath, line: UInt = #line) {
        guard let item = openMenu(of: control, file: file, line: line)?.first(where: { $0.title == title }) else {
            XCTFail("the menu from \(Self.describe(element: control)) has no “\(title)”", file: file, line: line)
            return
        }
        item.click()
    }

    /// Opens `control`'s menu and chooses the item with accessibility id `identifier` — from that
    /// menu only.
    func chooseMenuItem(identifiedBy identifier: String, openedBy control: XCUIElement,
                        file: StaticString = #filePath, line: UInt = #line) {
        guard let item = openMenu(of: control, file: file, line: line)?.first(where: { $0.identifier == identifier }) else {
            XCTFail("the menu from \(Self.describe(element: control)) has no item \(identifier)", file: file, line: line)
            return
        }
        item.click()
    }

    /// As `chooseMenuItem(identifiedBy:openedBy:)`, for a SwiftUI menu whose items may not report
    /// their ids: then the item at `position` of that same menu — and only if the menu has exactly
    /// `itemCount` items, so a menu that has changed fails instead of choosing the wrong entry.
    func chooseMenuItem(identifiedBy identifier: String, orAt position: Int, of itemCount: Int, openedBy control: XCUIElement,
                        file: StaticString = #filePath, line: UInt = #line) {
        let items = openMenu(of: control, file: file, line: line) ?? []
        if let item = items.first(where: { $0.identifier == identifier }) { return item.click() }
        guard items.count == itemCount, items.indices.contains(position) else {
            recordDiagnostics(named: "menu has no \(identifier)")
            return XCTFail("the menu from \(Self.describe(element: control)) has no item \(identifier)", file: file, line: line)
        }
        items[position].click()
    }

    /// The items of the menu `control` opened: a visible menu below the menu bar, never a menu-bar menu.
    func openMenu(of control: XCUIElement, file: StaticString = #filePath, line: UInt = #line) -> [XCUIElement]? {
        // A click while the control's last menu is still closing only closes it (testDarkModeCanBeChosen
        // lists the choices, presses Escape, then opens the menu again).
        let lastMenu = control.menus.firstMatch
        _ = waitUntil(NSPredicate { _, _ in !lastMenu.exists || self.visibleItems(of: lastMenu) == nil }, isTrueOf: NSNull(),
                      within: Self.optionalWait)
        // A real click: a menu opened through the accessibility press never showed where XCUITest
        // could list its items.
        clickWithPointer(control, file: file, line: line)
        let deadline = Date().addingTimeInterval(Self.screenTimeout)
        repeat {
            // The control's own menu first: one query, and never another menu still closing. Walking
            // every menu the app has (the menu bar's two dozen) read each one's frame, and could pick
            // up the previous pop-up's menu on its way out.
            let ownMenu = control.menus.firstMatch
            if ownMenu.exists, let items = visibleItems(of: ownMenu) { return items }
            let menus = app.menus.allElementsBoundByIndex.filter { menu in
                menu.exists && !menu.frame.isEmpty && menu.frame.minY >= Self.menuBarHeight && menu.isHittable
            }
            if let menu = menus.last, let items = visibleItems(of: menu) { return items }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.optionalWait / 4))
        } while Date() < deadline
        return nil
    }

    /// A menu's choosable items, once it is on screen with its items laid out.
    private func visibleItems(of menu: XCUIElement) -> [XCUIElement]? {
        let items = menu.menuItems.allElementsBoundByIndex.filter { $0.isHittable && $0.isEnabled }
        return items.isEmpty ? nil : items
    }

    // MARK: - Keys

    /// Presses a key only while the test app is frontmost and keyboard focus is in it, not its menu bar.
    /// With `on:`, also only while that control has focus — Space and Return act on whatever does.
    @discardableResult
    func press(_ key: XCUIKeyboardKey, modifiers: XCUIElement.KeyModifierFlags = [], on target: XCUIElement? = nil,
               file: StaticString = #filePath, line: UInt = #line) -> Bool {
        if let problem = unsafeKeyReason(target: target) {
            XCTFail("refused to press \(key.rawValue): \(problem)", file: file, line: line)
            return false
        }
        app.typeKey(key, modifierFlags: modifiers)
        return true
    }

    /// A character shortcut such as ⌘N, under the same conditions as `press`.
    func press(_ character: String, modifiers: XCUIElement.KeyModifierFlags, file: StaticString = #filePath, line: UInt = #line) {
        if let problem = unsafeKeyReason(target: nil) {
            XCTFail("refused to press \(character): \(problem)", file: file, line: line)
            return
        }
        app.typeKey(character, modifierFlags: modifiers)
    }

    /// Enters `text` into whatever has focus, under the same conditions as `press`. Into a text field
    /// it is pasted — one ⌘V, where XCUITest types a character at a time (0.1–0.3 s each) — and a
    /// trailing newline is pressed as Return. Anything else that takes keys (the duration readout)
    /// gets the keys typed. A test about typing itself uses `typeCharacters`.
    func typeIntoFocus(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        if let problem = unsafeKeyReason(target: nil) {
            XCTFail("refused to type: \(problem)", file: file, line: line)
            return
        }
        guard let focus = focusedSnapshot(), Self.textInputTypes.contains(focus.elementType) else {
            return app.typeText(text)
        }
        let endsWithReturn = text.hasSuffix("\n")
        paste(endsWithReturn ? String(text.dropLast()) : text)
        if endsWithReturn { app.typeKey(.return, modifierFlags: []) }
    }

    /// One key event per character, for tests whose subject is typing (Return handling, shortcuts).
    func typeCharacters(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        if let problem = unsafeKeyReason(target: nil) {
            XCTFail("refused to type: \(problem)", file: file, line: line)
            return
        }
        app.typeText(text)
    }

    /// Through the clipboard, which is put back afterwards: a paste is a real edit, so bindings and
    /// text-change notifications fire as they do for typing.
    func paste(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        app.typeKey("v", modifierFlags: .command)
        pasteboard.clearContents()
        if let previousContents { pasteboard.setString(previousContents, forType: .string) }
    }

    private static let textInputTypes: Set<XCUIElement.ElementType> = [.textField, .secureTextField, .textView, .searchField, .comboBox]

    private func unsafeKeyReason(target: XCUIElement?) -> String? {
        if let thief = bringTestAppToFront() { return "another app took focus: \(thief)" }
        if let target {
            guard hasKeyboardFocus(target) else { return "\(Self.describe(element: target)) doesn't have focus" }
            return unsafeTapReason(target).map { "the focused control \($0)" }
        }
        guard let focused = focusedSnapshot() else { return nil }   // the window itself: keys stay in the app
        guard !Self.isInMenuBar(focused) else {
            return "focus is in the menu bar (\(Self.describe(focused)))"
        }
        return nil
    }

    /// Focus reported by the frontmost test app is inside it, even on a control scrolled out of view;
    /// the one place a key could still escape to is the menu bar, whose Apple menu belongs to macOS.
    /// Read from a snapshot: asking the element for its type and then its frame was a query each.
    static func isInMenuBar(_ node: XCUIElementSnapshot) -> Bool {
        forbiddenTypes.contains(node.elementType) || node.frame.minY < menuBarHeight
    }

    func hasKeyboardFocus(_ element: XCUIElement) -> Bool {
        if (element.value(forKey: "hasKeyboardFocus") as? Bool) == true { return true }
        // XCUITest never sees focus on a secure text field; the app says which control has it.
        guard element.elementType == .secureTextField, !element.identifier.isEmpty else { return false }
        return focusedIdentifierFromApp() == element.identifier
    }

    func focusedElement() -> XCUIElement? {
        let focused = focusQuery
        return focused.exists ? focused : nil
    }

    /// The focused element in one query (`exists` and then `snapshot` were two, and every property
    /// read after that another). A secure text field never reports hasKeyboardFocus, so when XCUITest
    /// sees nothing focused the app is asked (`UITestContract.Command.focusQuery`).
    func focusedSnapshot() -> XCUIElementSnapshot? {
        let reported = try? focusQuery.snapshot()
        if let reported, !Self.focusContainerTypes.contains(reported.elementType),
           reported.identifier != Self.autoFillListIdentifier { return reported }
        guard let identifier = focusedIdentifierFromApp(), !identifier.isEmpty,
              let fromApp = try? element(identifier).snapshot() else {
            // Never the AutoFill list: it isn't a stop, and counting it made the walk depend on
            // whether macOS happened to show it.
            return reported?.identifier == Self.autoFillListIdentifier ? nil : reported
        }
        return fromApp
    }

    /// macOS's AutoFill suggestions under an email or password field. XCUITest reports them as
    /// focused while they show, but the keys stay with the field: Tab moves on from it (the app's own
    /// focus log shows it), so the app is asked instead.
    private static let autoFillListIdentifier = "CompletionListTableView"
    /// What XCUITest reports as focused when the real focus is somewhere it can't see (a secure field).
    private static let focusContainerTypes: Set<XCUIElement.ElementType> = [.window, .group, .other, .application]

    private func focusedIdentifierFromApp() -> String? {
        typealias Command = UITestContract.Command
        let requestId = String(UUID().uuidString.prefix(Self.pressRequestIdLength))
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(Command.focusQuery), object: requestId,
                                                                     userInfo: nil, deliverImmediately: true)
        let answer = Command.focusAnswerPrefix + requestId + ":"
        let statusItem = app.descendants(matching: .any).matching(identifier: UITestContract.Identifier.MenuBar.statusItem).firstMatch
        let deadline = Date().addingTimeInterval(Command.pressRequestLifetime)
        repeat {
            if let value = statusItem.value as? String, value.hasPrefix(answer) { return String(value.dropFirst(answer.count)) }
            RunLoop.current.run(until: Date().addingTimeInterval(Self.pressPollInterval))
        } while Date() < deadline
        return nil
    }

    /// Cells excluded: a view-based NSTableView's mock cells (NSTableViewCellMockElement) always
    /// report keyboard focus, even while another control has it, and the Settings category table came
    /// first in the tree — the walk then saw focus "stuck" on the table while it was moving on.
    private var focusQuery: XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasKeyboardFocus == true AND elementType != %d", XCUIElement.ElementType.cell.rawValue))
            .firstMatch
    }

    /// Re-activates the test app if something else came to the front (a helper app raising its
    /// window, a notification), so a run never depends on staying frontmost throughout. Returns the
    /// other app's name when the test app can't get the focus back.
    func bringTestAppToFront() -> String? {
        // Asked of macOS directly: `app.state` is a round trip to the test daemon, before every key.
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier != UITestContract.bundleIdentifier else { return nil }
        app.activate()
        guard !app.wait(for: .runningForeground, timeout: Self.optionalWait) else { return nil }
        return Self.frontmostAppName
    }

    static var frontmostAppName: String {
        let front = NSWorkspace.shared.frontmostApplication
        return front?.localizedName ?? front?.bundleIdentifier ?? "an unknown app"   // i18n-ignore: test failure message
    }

    /// Whether focus is inside the test app: not in another app, not in the menu bar.
    var isFocusInsideTestApp: Bool {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == UITestContract.bundleIdentifier else { return false }
        guard let focused = focusedSnapshot() else { return true }
        return !Self.isInMenuBar(focused)
    }

    // MARK: - Waiting, and noticing slowness

    /// Waits for `element`. Past `slowScreenThreshold` on a step that doesn't wait on the network,
    /// it is reported as a PERFORMANCE finding (screen, element, seconds) — to be fixed in the app,
    /// never absorbed by a longer timeout.
    @discardableResult
    func appears(_ element: XCUIElement, within timeout: TimeInterval = screenTimeout, waitsOnNetwork: Bool = false) -> Bool {
        // Polled finely: waitForExistence re-checks about once a second, so it can't tell 0.1 s from 1 s.
        let started = Date()
        var found = element.exists
        while !found, Date().timeIntervalSince(started) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(Self.appearancePollInterval))
            found = element.exists
        }
        let elapsed = Date().timeIntervalSince(started)
        if found, !waitsOnNetwork, elapsed > Self.slowScreenThreshold {
            recordSlowness(of: element, seconds: elapsed)
        }
        if !found { failIfCovered() }
        return found
    }

    func recordSlowness(of element: XCUIElement, seconds: TimeInterval) {
        let finding = String(format: "PERFORMANCE: %@ — %@ took %.1f s to appear", name, Self.describe(element: element), seconds)
        print(finding)   // collected from the run log into the PR's slow-screens table
        let attachment = XCTAttachment(string: finding)
        attachment.name = "performance"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Another app in the way

    /// Another app's window over the test app (a meeting prompt, a time-tracker dialog) takes the
    /// clicks and the keyboard, and every step after it times out with a misleading message. So:
    /// bring the test app back to the front, and if something still covers it, fail once, naming it.
    func failIfCovered(file: StaticString = #filePath, line: UInt = #line) {
        guard let cover = windowCoveringTestApp() else { return }
        app.activate()
        RunLoop.current.run(until: Date().addingTimeInterval(Self.optionalWait))
        guard windowCoveringTestApp() != nil else { return }
        recordDiagnostics(named: "covered")
        XCTFail("covered by \(cover)", file: file, line: line)
    }

    /// "<app>: <window title>" for the frontmost window of another app that overlaps the test app's
    /// main window and sits above it, or nil. Window order comes front to back.
    func windowCoveringTestApp() -> String? {
        guard let testPid = NSRunningApplication.runningApplications(withBundleIdentifier: UITestContract.bundleIdentifier).first?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        else { return nil }
        let normalWindows = windows.filter { ($0[kCGWindowLayer as String] as? Int) == Self.normalWindowLayer }
        guard let ours = normalWindows.first(where: { ($0[kCGWindowOwnerPID as String] as? pid_t) == testPid }),
              let ourFrame = Self.frame(of: ours) else { return nil }
        // Floating and modal-panel windows of other apps sit above every normal window: "Focus Bear
        // (UI Test) quit unexpectedly" after a crash took a click meant for the To-do sort control.
        // The installed Focus Bear's full-screen routine counts too: it sits above everything at shield
        // level, so every screenshot the contrast audit took behind it failed while nothing reported the
        // cover. Other apps' shield-level windows are left alone — CleanShot keeps screen-sized ones up.
        if let floating = windows.first(where: { window in
            guard let layer = window[kCGWindowLayer as String] as? Int,
                  let owner = window[kCGWindowOwnerPID as String] as? pid_t, owner != testPid,
                  ((window[kCGWindowAlpha as String] as? Double) ?? 1) > 0,
                  let frame = Self.frame(of: window), frame.width > Self.overlayMinimumSide, frame.height > Self.overlayMinimumSide
            else { return false }
            let isFloating = Self.floatingLayers.contains(layer) && !Self.isScreenOverlay(frame)
            let isFocusBearShield = layer >= Self.shieldLayerFloor && Self.isInstalledFocusBear(owner)
            guard isFloating || isFocusBearShield else { return false }
            return frame.intersects(ourFrame)
        }) {
            let owner = floating[kCGWindowOwnerName as String] as? String ?? "another app"   // i18n-ignore: test failure message
            let title = floating[kCGWindowName as String] as? String ?? ""
            return title.isEmpty ? owner : "\(owner): \(title)"
        }
        for window in normalWindows {
            if (window[kCGWindowOwnerPID as String] as? pid_t) == testPid { return nil }   // reached ours: nothing above it
            guard let frame = Self.frame(of: window), frame.intersects(ourFrame) else { continue }
            let owner = window[kCGWindowOwnerName as String] as? String ?? "another app"   // i18n-ignore: test failure message
            let title = window[kCGWindowName as String] as? String ?? ""
            return title.isEmpty ? owner : "\(owner): \(title)"
        }
        return nil
    }

    private static let normalWindowLayer = 0
    /// Above normal windows and below the menu bar: floating panels, modal panels, alerts.
    private static let floatingLayers = 1..<24
    /// Above pop-up menus: where the installed Focus Bear's full-screen routine and break screens sit
    /// (999 and 2147483631 have both been seen).
    private static let shieldLayerFloor = Int(CGWindowLevelForKey(.overlayWindow))
    /// The user's own Focus Bear — a release or a development build, never the test build.
    private static let installedFocusBearBundlePrefixes = ["com.focusbear.", "com.App.EarnYourScreentime"]

    private static func isInstalledFocusBear(_ pid: pid_t) -> Bool {
        guard let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier,
              bundle != UITestContract.bundleIdentifier else { return false }
        return installedFocusBearBundlePrefixes.contains { bundle.hasPrefix($0) }
    }
    /// Smaller than this is a badge or an invisible helper, not something covering a control.
    private static let overlayMinimumSide: CGFloat = 50

    /// A transparent window as big as a screen (Notification Centre keeps one up) takes no clicks.
    private static func isScreenOverlay(_ frame: CGRect) -> Bool {
        NSScreen.screens.contains { screen in
            frame.width >= screen.frame.width * screenOverlayFraction && frame.height >= screen.frame.height * screenOverlayFraction
        }
    }

    private static let screenOverlayFraction: CGFloat = 0.9

    private static func frame(of window: [String: Any]) -> CGRect? {
        guard let bounds = window[kCGWindowBounds as String] as? NSDictionary else { return nil }
        return CGRect(dictionaryRepresentation: bounds as CFDictionary)
    }

    // MARK: - Stray system windows

    private static let systemWindowApps = ["com.apple.SystemProfiler", "com.apple.systempreferences", "com.apple.finder"]

    /// The system apps' processes running now, to compare with after the test.
    static func runningSystemWindowApps() -> Set<pid_t> {
        Set(systemWindowApps.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }.map(\.processIdentifier))
    }

    /// Closes any system app window this test launched (About This Mac is System Information) and
    /// fails the test for opening it.
    private static func parentProcessName(of pid: pid_t) -> String {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var request = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&request, u_int(request.count), &info, &size, nil, 0) == 0 else { return "unknown" }
        let parent = info.kp_eproc.e_ppid
        let name = NSRunningApplication(processIdentifier: parent)?.localizedName ?? "pid \(parent)"
        return name
    }

    func closeStraySystemWindows(openedSince before: Set<pid_t>, testStart: Date) {
        // Launched during this test, and not merely unlisted when it started: NSRunningApplication
        // once missed a System Settings that had been open for days (pid 791), and it was closed.
        let stray = Self.systemWindowApps.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }
            .filter { !before.contains($0.processIdentifier) && $0.bundleIdentifier != "com.apple.finder" }
            .filter { ($0.launchDate ?? .distantPast) >= testStart }
        for app in stray {
            // Who launched it is what tells the test app apart from something else on the Mac.
            let parent = Self.parentProcessName(of: app.processIdentifier)
            XCTFail("\(name): \(app.localizedName ?? app.bundleIdentifier ?? "a system app") (pid \(app.processIdentifier), started by \(parent)) opened outside the test app — closed it")   // i18n-ignore: test failure message, never shown to users
            app.terminate()
        }
    }
}
