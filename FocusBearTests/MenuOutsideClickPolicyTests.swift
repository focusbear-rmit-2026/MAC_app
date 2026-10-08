import XCTest
import AppKit
@testable import Focus_Bear

/// The open menu is dismissed by two `NSEvent` monitors, and the LOCAL one sees the user's own
/// clicks — including the mouse-down on the status-bar icon that is about to toggle the menu.
/// Because the status item's window is not owned by the overlay panel, that click read as "outside"
/// and hid the menu microseconds before the button action re-showed it.
///
/// The PO's logs for report 2026-09-16_21-21-03 caught it: between 20:17:31 and 20:17:43 there are
/// seven `Top bar focus bear button clicked` lines, each followed by `overlay panel shown` — which
/// only runs when the panel was already hidden — and not one `closePopover`. Seven clicks in twelve
/// seconds, the menu never closing: "it takes multiple clicks to register".
///
/// These tests pin the decision itself: what counts as a click *away* from the menu.
final class MenuOutsideClickPolicyTests: XCTestCase {

    private let anywhere = NSPoint(x: 10, y: 10)

    // MARK: - The decision

    /// The reported bug, stated as a rule: the click that toggles the menu is not a click away.
    func testAClickOnTheStatusItemDoesNotDismissTheMenu() {
        XCTAssertEqual(MenuOutsideClickPolicy.decide(target: .menuOwnerChrome, isMenuVisible: true),
                       .keepOpen)
    }

    func testAClickInAnotherApplicationDismissesTheMenu() {
        XCTAssertEqual(MenuOutsideClickPolicy.decide(target: .otherApplication, isMenuVisible: true),
                       .dismiss)
    }

    func testAClickInsideTheMenuDoesNotDismissIt() {
        XCTAssertEqual(MenuOutsideClickPolicy.decide(target: .menu, isMenuVisible: true), .keepOpen)
    }

    /// Clicking the main window or the routine player while the menu floats over it still closes it —
    /// the dismissal is wanted, only the status item was ever wrong.
    func testAClickInAnotherFocusBearWindowDismissesTheMenu() {
        XCTAssertEqual(MenuOutsideClickPolicy.decide(target: .otherAppWindow, isMenuVisible: true),
                       .dismiss)
    }

    func testNothingIsDismissedWhileNoMenuIsOnScreen() {
        for target: MenuOutsideClickPolicy.ClickTarget in [.menu, .menuOwnerChrome, .otherAppWindow, .otherApplication] {
            XCTAssertEqual(MenuOutsideClickPolicy.decide(target: target, isMenuVisible: false),
                           .keepOpen, "\(target) with no menu open")
        }
    }

    // MARK: - Classifying the click

    private func classify(clicked: AnyObject?,
                          menu: AnyObject?,
                          hitOwnerChrome: Bool = false,
                          owned: Bool = false) -> MenuOutsideClickPolicy.ClickTarget {
        MenuOutsideClickPolicy.target(clickedWindow: clicked, menu: menu,
                                      hitOwnerChrome: hitOwnerChrome) { _, _ in owned }
    }

    /// The status item's window genuinely is a different window from the panel, and no ownership walk
    /// will ever connect them — which is exactly why ownership alone was the wrong question.
    func testTheStatusItemWindowIsChromeEvenThoughThePanelDoesNotOwnIt() {
        let statusBarWindow = NSObject(), panel = NSObject()
        XCTAssertEqual(classify(clicked: statusBarWindow, menu: panel, hitOwnerChrome: true, owned: false),
                       .menuOwnerChrome)
    }

    func testAnEventWithNoWindowOfOursIsAnotherApplication() {
        XCTAssertEqual(classify(clicked: nil, menu: NSObject()), .otherApplication)
    }

    func testAWindowOwnedByTheMenuIsTheMenu() {
        let sheet = NSObject(), panel = NSObject()
        XCTAssertEqual(classify(clicked: sheet, menu: panel, owned: true), .menu)
    }

    func testAnUnownedWindowOfOursIsAnotherAppWindow() {
        XCTAssertEqual(classify(clicked: NSObject(), menu: NSObject(), owned: false), .otherAppWindow)
    }

    /// With no menu window recorded there is nothing to be inside of, so the click is still "away".
    func testAClickWithNoMenuWindowRecordedIsOutside() {
        XCTAssertEqual(classify(clicked: NSObject(), menu: nil), .otherAppWindow)
    }

    // MARK: - Hit testing the chrome (geometry, not window class)

    @MainActor
    private func makeWindow(_ view: NSView) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 200, height: 100),
                              styleMask: [.borderless], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.contentView?.addSubview(view)
        window.orderFront(nil)
        return window
    }

    @MainActor
    func testAPointInsideTheButtonCountsAsChromeAndAPointBesideItDoesNot() {
        let button = NSButton(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        let window = makeWindow(button)
        defer { window.close() }
        XCTAssertTrue(MenuOutsideClickPolicy.hits(button, clickedWindow: window,
                                                  locationInWindow: NSPoint(x: 40, y: 30)))
        XCTAssertFalse(MenuOutsideClickPolicy.hits(button, clickedWindow: window,
                                                   locationInWindow: NSPoint(x: 5, y: 5)),
                       "A click next to the icon is not a click on it")
    }

    @MainActor
    func testTheSamePointInADifferentWindowIsNotChrome() {
        let button = NSButton(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        let window = makeWindow(button)
        let other = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 200, height: 100),
                             styleMask: [.borderless], backing: .buffered, defer: true)
        other.isReleasedWhenClosed = false
        defer { window.close(); other.close() }
        XCTAssertFalse(MenuOutsideClickPolicy.hits(button, clickedWindow: other,
                                                   locationInWindow: NSPoint(x: 40, y: 30)))
    }

    @MainActor
    func testHiddenChromeIsNeverHit() {
        let button = NSButton(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        let window = makeWindow(button)
        defer { window.close() }
        button.isHidden = true
        XCTAssertFalse(MenuOutsideClickPolicy.hits(button, clickedWindow: window,
                                                   locationInWindow: NSPoint(x: 40, y: 30)))
    }

    /// A windowless event — the global monitor, and any status-item click macOS reports that way —
    /// carries screen coordinates instead.
    @MainActor
    func testAScreenPointInsideTheButtonCountsAsChrome() {
        let button = NSButton(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        let window = makeWindow(button)
        defer { window.close() }
        let inside = window.convertPoint(toScreen: NSPoint(x: 40, y: 30))
        let outside = window.convertPoint(toScreen: NSPoint(x: 5, y: 5))
        XCTAssertTrue(MenuOutsideClickPolicy.hits(button, screenLocation: inside))
        XCTAssertFalse(MenuOutsideClickPolicy.hits(button, screenLocation: outside))
    }

    func testNoChromeMeansNoHit() {
        XCTAssertFalse(MenuOutsideClickPolicy.hits(nil, clickedWindow: nil, locationInWindow: anywhere))
        XCTAssertFalse(MenuOutsideClickPolicy.hits(nil, screenLocation: anywhere))
    }

    // MARK: - Chrome identified by what it does

    /// The floating bar's menu button is nested in boxes, so the click is matched by the button's
    /// action rather than by a rectangle.
    @MainActor
    func testAControlWiredToTheMenuToggleIsChromeAndAnotherButtonIsNot() {
        let toggle = NSButton(frame: NSRect(x: 0, y: 0, width: 40, height: 20))
        toggle.action = #selector(floatingTopBarVc.btnBarClicked(_:))
        let unrelated = NSButton(frame: NSRect(x: 0, y: 0, width: 40, height: 20))
        unrelated.action = #selector(NSWindow.close)
        let actions: Set<Selector> = [#selector(floatingTopBarVc.btnBarClicked(_:))]
        XCTAssertTrue(MenuOutsideClickPolicy.togglesMenu(viewUnderClick: toggle, toggleActions: actions))
        XCTAssertFalse(MenuOutsideClickPolicy.togglesMenu(viewUnderClick: unrelated, toggleActions: actions))
        XCTAssertFalse(MenuOutsideClickPolicy.togglesMenu(viewUnderClick: nil, toggleActions: actions))
    }

    /// The click lands on the button's image or label, not the button itself, so the walk goes up.
    @MainActor
    func testAViewInsideTheToggleButtonIsAlsoChrome() {
        let toggle = NSButton(frame: NSRect(x: 0, y: 0, width: 40, height: 20))
        toggle.action = #selector(floatingTopBarVc.btnBarClicked(_:))
        let label = NSView(frame: NSRect(x: 2, y: 2, width: 10, height: 10))
        toggle.addSubview(label)
        XCTAssertTrue(MenuOutsideClickPolicy.togglesMenu(viewUnderClick: label,
                                                         toggleActions: [#selector(floatingTopBarVc.btnBarClicked(_:))]))
    }

    @MainActor
    func testTheViewUnderAClickIsFoundInWindowCoordinates() {
        let button = NSButton(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        let window = makeWindow(button)
        defer { window.close() }
        let hit = MenuOutsideClickPolicy.viewUnderClick(in: window, locationInWindow: NSPoint(x: 40, y: 30))
        XCTAssertTrue(hit === button || hit?.isDescendant(of: button) == true,
                      "Expected the button under the click, got \(String(describing: hit))")
        XCTAssertNil(MenuOutsideClickPolicy.viewUnderClick(in: nil, locationInWindow: anywhere))
    }

    // MARK: The hover tooltip on a truncated focus goal (report 2026-09-21_16-29-14)
    //
    // The goal is shown with `.lineLimit(2)` and was unreadable once it overflowed. The tooltip is
    // an AppKit overlay, so hovering itself is not unit-testable — but the property that makes the
    // overlay safe to add IS, and it is the one that would break the screen if it regressed.

    @available(macOS 11.0, *)
    func testTheTooltipOverlayNeverSwallowsAClick() {
        let overlay = HoverTooltipOverlayView(message: "attend and stay focused in your meeting",
                                              preferredEdge: .minY)
        overlay.setFrameSize(NSSize(width: 200, height: 20))

        // The editable goal row is a Button underneath this overlay. If hitTest returned the view,
        // hovering would work and tapping the goal to edit it would silently stop.
        XCTAssertNil(overlay.hitTest(NSPoint(x: 100, y: 10)))
        XCTAssertNil(overlay.hitTest(NSPoint(x: 0, y: 0)))
    }

    @available(macOS 11.0, *)
    func testTheOverlayTracksHoverAcrossItsWholeBounds() {
        let overlay = HoverTooltipOverlayView(message: "a goal", preferredEdge: .minY)
        overlay.setFrameSize(NSSize(width: 200, height: 20))
        overlay.updateTrackingAreas()

        XCTAssertEqual(overlay.trackingAreas.count, 1, "exactly one, re-made rather than accumulated")
        overlay.updateTrackingAreas()
        XCTAssertEqual(overlay.trackingAreas.count, 1,
                       "a second layout pass must not leave two areas firing the tooltip twice")
    }

}
