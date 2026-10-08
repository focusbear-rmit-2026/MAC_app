//
//  MenuBarActivityProbe.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import AppKit
import CoreGraphics

/// Answers "is the user in their menu bar right now?" as cheaply and as honestly as macOS allows.
///
/// There is no public API for "is a menu open". Three imperfect signals together cover it:
///
///  * **An on-screen window at the pop-up-menu window level.** That is what an open menu *is* —
///    ours, another app's, or a menu-bar extra's — and `CGWindowListCopyWindowInfo` reports the
///    window list's metadata without Screen Recording permission. This is the load-bearing signal.
///  * **The pointer inside the menu bar strip.** Covers the instant before a menu opens, and the
///    menu-tracking run loops during which our event monitors see nothing.
///  * **A recent click in the menu bar**, from `NSEvent` monitors. Global monitors catch clicks into
///    other apps' menu bar items; the local one catches clicks on our own status item.
///
/// None of these is a guarantee, so the caller's rule is to prefer waiting over clicking regardless.
final class MenuBarActivityProbe {

    static let shared = MenuBarActivityProbe()

    private var lastMenuBarClick: Date?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    /// Installs the mouse monitors. Safe to call repeatedly; must be called on the main thread,
    /// because `NSEvent` monitors are AppKit state.
    func startMonitoring() {
        guard globalMonitor == nil, localMonitor == nil else { return }
        let mouseDown: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseDown) { [weak self] _ in
            self?.recordClickIfInMenuBar()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseDown) { [weak self] event in
            self?.recordClickIfInMenuBar()
            return event
        }
    }

    /// The current picture. Main-thread only, like the monitors that feed it.
    func activity() -> MenuBarActivity {
        MenuBarActivity(isAnyMenuOpen: MenuBarActivityProbe.isAnyMenuOpen(),
                        isCursorInMenuBar: MenuBarActivityProbe.isCursorInMenuBar(),
                        lastMenuBarClick: lastMenuBarClick)
    }

    private func recordClickIfInMenuBar() {
        guard MenuBarActivityProbe.isCursorInMenuBar() else { return }
        lastMenuBarClick = Date()
    }

    // MARK: - Signals

    /// An open menu draws into a window at the pop-up-menu level, whichever process owns it.
    private static func isAnyMenuOpen() -> Bool {
        let popUpMenuLevel = Int(CGWindowLevelForKey(.popUpMenuWindow))
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                       kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        return windows.contains { ($0[kCGWindowLayer as String] as? Int) == popUpMenuLevel }
    }

    /// `NSEvent.mouseLocation` is in AppKit's global, y-up coordinates, the same space as
    /// `NSScreen.frame`, so the strip can be compared directly.
    private static func isCursorInMenuBar() -> Bool {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.contains { menuBarStrip(of: $0).contains(location) }
    }

    private static func menuBarStrip(of screen: NSScreen) -> NSRect {
        let measuredHeight = screen.frame.maxY - screen.visibleFrame.maxY
        // An auto-hidden menu bar measures zero; fall back to its nominal thickness so the strip
        // still exists to be hovered.
        let height = max(measuredHeight, NSStatusBar.system.thickness)
        return NSRect(x: screen.frame.minX, y: screen.frame.maxY - height,
                      width: screen.frame.width, height: height)
    }
}
