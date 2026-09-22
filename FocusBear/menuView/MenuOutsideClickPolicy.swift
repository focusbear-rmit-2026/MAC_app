//
//  MenuOutsideClickPolicy.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import AppKit

/// Decides whether a mouse-down dismisses the open Focus Bear menu.
///
/// Neither the detached menu window nor the full-screen overlay panel auto-dismisses the way a
/// `.transient` NSPopover does, so `AppDelegate` installs a global + a **local** `NSEvent` monitor
/// while one of them is open. A local monitor sees every mouse-down destined for our OWN app —
/// **including the click on the status-bar icon that is about to toggle the menu**. Treating that as
/// a click "outside" hid the menu microseconds before the button action re-showed it, so the icon
/// could never close the menu and every click tore the menu down and rebuilt it.
///
/// The user's logs for report 2026-09-16_21-21-03 show it plainly: seven consecutive
/// `Top bar focus bear button clicked` lines between 20:17:31 and 20:17:43, each one followed by
/// `overlay panel shown` — which only runs when the panel was already hidden — and not one
/// `closePopover`. That is the whole "it takes multiple clicks to register" symptom.
///
/// The rule this type encodes: **a click on the chrome that owns the menu is not a click away from
/// it.** The toggle action owns that decision; the monitor must stay out of its way. Ownership is
/// asked by geometry and by the window-parent walk (`MenuWindowOwnership`) rather than by matching
/// window classes, because `NSStatusBarWindow` and friends are private AppKit types.
enum MenuOutsideClickPolicy {

    /// What a mouse-down landed on, seen from the open menu.
    enum ClickTarget: Equatable {
        /// The menu window / overlay panel itself, or a sheet, child window or popover it presented.
        case menu
        /// The status-bar icon or the floating-bar button whose action toggles the menu.
        case menuOwnerChrome
        /// Some other Focus Bear window — the main window, the routine player, a dialog.
        case otherAppWindow
        /// Another application: the click never reached a window of ours.
        case otherApplication
    }

    enum Decision: Equatable {
        case dismiss
        case keepOpen
    }

    static func decide(target: ClickTarget, isMenuVisible: Bool) -> Decision {
        guard isMenuVisible else { return .keepOpen }
        switch target {
        case .menu, .menuOwnerChrome:
            return .keepOpen
        case .otherAppWindow, .otherApplication:
            return .dismiss
        }
    }

    /// Classify a click. Written against an opaque ownership test so it can be exercised without
    /// real windows, the same shape `MenuWindowOwnership` uses.
    ///
    /// - Parameters:
    ///   - clickedWindow: the window the event was delivered to; `nil` when the event carried no
    ///     window of ours (a global-monitor event from another application).
    ///   - menu: the menu window or overlay panel currently on screen.
    ///   - hitOwnerChrome: the click's location is inside a view whose action toggles the menu.
    ///   - isOwnedByMenu: does the clicked window belong to the menu (itself, a sheet, a child)?
    static func target(clickedWindow: AnyObject?,
                       menu: AnyObject?,
                       hitOwnerChrome: Bool,
                       isOwnedByMenu: (AnyObject, AnyObject) -> Bool) -> ClickTarget {
        if hitOwnerChrome { return .menuOwnerChrome }
        guard let clicked = clickedWindow else { return .otherApplication }
        if let menu, isOwnedByMenu(clicked, menu) { return .menu }
        return .otherAppWindow
    }

    // MARK: - Hit testing the chrome that owns the menu

    /// Did a click delivered to `clickedWindow` at `locationInWindow` land inside `view`?
    ///
    /// Geometry, not window class: the status item's window is a private AppKit type
    /// (`NSStatusBarWindow`), so the honest question is whether the point is inside the button we
    /// own, not what kind of window happens to host it.
    static func hits(_ view: NSView?, clickedWindow: NSWindow?, locationInWindow: NSPoint) -> Bool {
        guard let view, let window = view.window, window === clickedWindow, isVisible(view) else {
            return false
        }
        return view.bounds.contains(view.convert(locationInWindow, from: nil))
    }

    /// Screen-coordinate fallback for an event that carries no window — a global-monitor event, and
    /// any status-item click macOS chooses to report that way. `NSEvent.locationInWindow` already
    /// holds screen coordinates when `window` is nil.
    static func hits(_ view: NSView?, screenLocation: NSPoint) -> Bool {
        guard let view, let window = view.window, isVisible(view) else { return false }
        let inWindow = window.convertPoint(fromScreen: screenLocation)
        return view.bounds.contains(view.convert(inWindow, from: nil))
    }

    /// Does the view under the click — or any view above it — carry an action that toggles the menu?
    ///
    /// The floating bar's menu button is nested inside boxes and its `boxFakeView` outlet is a
    /// two-point spacer used only to anchor the popover, so there is no single rectangle to test.
    /// Asking the control what it *does* is both more accurate and immune to that layout changing.
    static func togglesMenu(viewUnderClick: NSView?, toggleActions: Set<Selector>) -> Bool {
        var candidate = viewUnderClick
        while let view = candidate {
            if let action = (view as? NSControl)?.action, toggleActions.contains(action) { return true }
            candidate = view.superview
        }
        return false
    }

    /// The view a click at `locationInWindow` would be delivered to, if any. `NSView.hitTest` takes a
    /// point in the *superview's* space, and a content view's superview space is the window's own,
    /// so the event location goes in unconverted.
    static func viewUnderClick(in window: NSWindow?, locationInWindow: NSPoint) -> NSView? {
        window?.contentView?.hitTest(locationInWindow)
    }

    private static func isVisible(_ view: NSView) -> Bool {
        !view.isHiddenOrHasHiddenAncestor && (view.window?.isVisible ?? false)
    }
}
