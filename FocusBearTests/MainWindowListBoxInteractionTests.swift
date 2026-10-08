import AppKit
import XCTest
@testable import Focus_Bear

@MainActor
final class MainWindowListBoxInteractionTests: XCTestCase {
    func testOneClickOnIconLabelOrPaddingSelectsTheRowInCollapsedAndExpandedSidebars() throws {
        for collapsed in [true, false] {
            let fixture = makeFixture(collapsed: collapsed)
            defer { fixture.window.close() }
            let row = fixture.row
            let icon = try XCTUnwrap(row.imageView)
            XCTAssertEqual(row.bounds.width, 185, accuracy: 0.01, "Collapsing clips the full-width row; it must not compress it")
            // Auto Layout sizes the alignment rect. AppKit's info.circle image adds vertical
            // alignment insets (3pt per side here), so a 19pt layout has 25pt view bounds.
            let iconLayout = icon.alignmentRect(forFrame: icon.frame)
            XCTAssertEqual(iconLayout.width, 19, accuracy: 0.01)
            XCTAssertEqual(iconLayout.height, 19, accuracy: 0.01)
            let visibleIcon = fixture.sidebar.convert(icon.bounds, from: icon)
            XCTAssertTrue(fixture.sidebar.bounds.contains(visibleIcon), "The entire icon remains inside the collapsed sidebar")
            let iconCenter = row.convert(NSPoint(x: icon.bounds.midX, y: icon.bounds.midY), from: icon)
            var points = [iconCenter, NSPoint(x: 2, y: row.bounds.midY),
                          NSPoint(x: collapsed ? 20 : row.bounds.midX, y: 2)]
            if !collapsed {
                let label = try XCTUnwrap(row.contentView?.subviews.first { $0 is NSTextField })
                points.append(row.convert(NSPoint(x: label.bounds.midX, y: label.bounds.midY), from: label))
            }
            XCTAssertFalse(fixture.window.isKeyWindow, "The fixture must never take focus from the user's app")
            for (index, point) in points.enumerated() {
                row.isSelected = false
                let location = row.convert(point, to: fixture.root)
                let hit = try XCTUnwrap(fixture.root.hitTest(location))
                XCTAssertTrue(hit === row, "Passive content must share the row's action at \(point), collapsed=\(collapsed)")
                XCTAssertTrue(hit.acceptsFirstMouse(for: nil), "The activation click must also navigate")
                try click(fixture, point: point)
                XCTAssertTrue(row.isSelected)
                XCTAssertEqual(fixture.delegate.userSelections, index + 1,
                               "One complete click must navigate exactly once, including over the icon")
                XCTAssertEqual(fixture.delegate.selectionChanges, index + 1)
            }
            XCTAssertFalse(fixture.root.hitTest(NSPoint(x: 1, y: 1)) === row,
                           "A click outside the row must not select it")
        }
    }

    func testDisabledRowsAndSelectionVetoStillPreventNavigation() throws {
        let fixture = makeFixture(collapsed: true)
        defer { fixture.window.close() }
        let row = fixture.row
        let icon = try XCTUnwrap(row.imageView)
        let point = row.convert(NSPoint(x: icon.bounds.midX, y: icon.bounds.midY), from: icon)
        row.isEnabled = false
        XCTAssertFalse(row.acceptsFirstMouse(for: nil))
        try click(fixture, point: point)
        XCTAssertEqual(fixture.delegate.selectionChecks, 0)
        XCTAssertEqual(fixture.delegate.userSelections, 0)
        XCTAssertFalse(row.isSelected)

        row.isEnabled = true
        fixture.delegate.allowSelection = false
        try click(fixture, point: point)
        XCTAssertEqual(fixture.delegate.selectionChecks, 1)
        XCTAssertEqual(fixture.delegate.userSelections, 0)
        XCTAssertFalse(row.isSelected)

        fixture.delegate.allowSelection = true
        try click(fixture, point: point)
        XCTAssertEqual(fixture.delegate.userSelections, 1)
        try click(fixture, point: point)
        XCTAssertEqual(fixture.delegate.userSelections, 1, "An already-selected row must not repeat navigation")
    }

    func testHideButtonKeepsItsOwnHitAndDoesNotSelectTheRow() throws {
        for collapsed in [true, false] {
            let fixture = makeFixture(collapsed: collapsed)
            defer { fixture.window.close() }
            let row = fixture.row
            row.showsHideButton = true
            var hides = 0
            row.onHideRequested = { hides += 1 }
            row.mouseEntered(with: try mouseEvent(.mouseEntered, fixture: fixture))
            let button = try XCTUnwrap(row.contentView?.subviews.first { $0 is NSButton } as? NSButton)
            XCTAssertFalse(button.isHidden)
            let point = row.convert(NSPoint(x: button.bounds.midX, y: button.bounds.midY), from: button)
            if collapsed {
                XCTAssertGreaterThan(fixture.sidebar.convert(button.bounds, from: button).minX, fixture.sidebar.bounds.maxX,
                                     "The hide control stays at the far end of the full-width row")
                for clippedPoint in [point, NSPoint(x: row.bounds.midX, y: row.bounds.midY)] {
                    let hit = fixture.root.hitTest(row.convert(clippedPoint, to: fixture.root))
                    XCTAssertFalse(hit === row || hit === button || hit?.isDescendant(of: row) == true,
                                   "A clipped part of the row must not receive a click outside the sidebar")
                    try click(fixture, point: clippedPoint)
                }
                XCTAssertEqual(hides, 0)
                XCTAssertEqual(fixture.delegate.userSelections, 0)
                XCTAssertFalse(row.isSelected)
                let icon = try XCTUnwrap(row.imageView)
                try click(fixture, point: row.convert(NSPoint(x: icon.bounds.midX, y: icon.bounds.midY), from: icon))
                XCTAssertEqual(fixture.delegate.userSelections, 1, "The clipped hide control must not intercept the visible icon")
                XCTAssertEqual(hides, 0)
            } else {
                let hit = try XCTUnwrap(fixture.root.hitTest(row.convert(point, to: fixture.root)))
                XCTAssertTrue(hit === button || hit.isDescendant(of: button))
                try click(fixture, point: point)
                XCTAssertEqual(hides, 1)
                XCTAssertEqual(fixture.delegate.userSelections, 0)
                XCTAssertFalse(row.isSelected)
            }
            row.isEnabled = false
            XCTAssertTrue(button.isHidden, "Disabling a hovered row must also disable its hide action")
        }
    }

    func testSidebarHoverUsesPassiveNativeTooltipAndPreservesTranslatedDisableReason() throws {
        let fixture = makeFixture(collapsed: true)
        defer { fixture.window.close() }
        let row = fixture.row
        let previousPopover = popoverTooltip
        row.title = "Ayuda y soporte"
        XCTAssertEqual(row.toolTip, "Ayuda y soporte")
        row.mouseEntered(with: try mouseEvent(.mouseEntered, fixture: fixture))
        XCTAssertTrue(popoverTooltip === previousPopover,
                      "Sidebar hover must not create a transient popover that eats the next click")
        row.mouseExited(with: try mouseEvent(.mouseExited, fixture: fixture))
        row.setDisableWithRaason(reason: "Guarda tus cambios primero")
        XCTAssertEqual(row.toolTip, "Guarda tus cambios primero")
        row.isEnabled = true
        XCTAssertEqual(row.toolTip, "Ayuda y soporte")
    }

    private struct Fixture {
        let window: SidebarFixtureWindow
        let root: NSView
        let sidebar: NSView
        let row: mainWindowListBox
        let delegate: SelectionRecorder
    }

    private func makeFixture(collapsed: Bool) -> Fixture {
        let window = SidebarFixtureWindow(contentRect: NSRect(x: -12000, y: -12000, width: 260, height: 120),
                                          styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 120))
        window.contentView = root
        // Main.storyboard keeps Jhl-8A-abn at width230 (snI-dc-RzR), while its outer host
        // collapses to50. Help's row remains185 wide with no content margins; only its leading
        // portion is visible. Shrinking the row itself creates constraints the real host never has.
        let sidebar = NSView(frame: NSRect(x: 0, y: 0, width: collapsed ? 50 : 230, height: 120))
        sidebar.wantsLayer = true
        sidebar.layer?.masksToBounds = true
        root.addSubview(sidebar)
        let inner = NSView(frame: NSRect(x: 0, y: 0, width: 230, height: 120))
        sidebar.addSubview(inner)
        let row = mainWindowListBox(frame: NSRect(x: 15, y: 40, width: 185, height: 32))
        row.contentViewMargins = .zero
        row.title = "Help and support"
        row.imageIcon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        let delegate = SelectionRecorder()
        row.delegate = delegate
        inner.addSubview(row)
        root.layoutSubtreeIfNeeded()
        window.orderBack(nil)
        return Fixture(window: window, root: root, sidebar: sidebar, row: row, delegate: delegate)
    }

    private func mouseEvent(_ type: NSEvent.EventType, fixture: Fixture, point: NSPoint = .zero) throws -> NSEvent {
        let location = fixture.row.convert(point, to: nil)
        if type == .mouseEntered || type == .mouseExited {
            return try XCTUnwrap(NSEvent.enterExitEvent(with: type, location: location, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: fixture.window.windowNumber,
                context: nil, eventNumber: 0, trackingNumber: 0, userData: nil))
        }
        return try XCTUnwrap(NSEvent.mouseEvent(with: type, location: location, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: fixture.window.windowNumber,
            context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0))
    }

    /// Only the test process's offscreen window receives these events. Posting the release lets
    /// the real NSButton finish its tracking loop; no system mouse input or app activation occurs.
    private func click(_ fixture: Fixture, point: NSPoint) throws {
        let down = try mouseEvent(.leftMouseDown, fixture: fixture, point: point)
        let up = try mouseEvent(.leftMouseUp, fixture: fixture, point: point)
        NSApp.postEvent(up, atStart: true)
        fixture.window.sendEvent(down)
        if let release = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .eventTracking, dequeue: true) {
            fixture.window.sendEvent(release)
        }
    }
}

private final class SidebarFixtureWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

private final class SelectionRecorder: mainWindowListBoxDelegate {
    var allowSelection = true
    var selectionChecks = 0
    var selectionChanges = 0
    var userSelections = 0

    func selectableListBoxShouldChangeSelection(_ box: mainWindowListBox) -> Bool {
        selectionChecks += 1
        return allowSelection
    }
    func selectableListBoxSelectionDidChange(_ box: mainWindowListBox) { selectionChanges += 1 }
    func selectableListBoxDidChangeSelectionByUser(_ box: mainWindowListBox) { userSelections += 1 }
}
