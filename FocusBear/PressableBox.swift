//
//  PressableBox.swift
//  Focus Bear
//
//  An NSBox drawn as a button — sidebar rows, the sidebar's section headers, the sign-up buttons.
//  A box is a plain container to VoiceOver and the keyboard, so none of these could be announced as
//  buttons, reached with Tab or pressed with Space. Subclasses say how to press themselves; this
//  gives them what a real button has: the button role and name, a focus ring when Full Keyboard
//  Access is on, and Space/Return to press.
//

import Cocoa

class PressableBox: NSBox {
    private static let pressKeys: Set<String> = [" ", "\r"]

    /// Whether it can be pressed right now.
    var isPressable: Bool { true }

    /// What VoiceOver calls it.
    var spokenTitle: String? { title }

    /// Does what a click does. Returns whether it did anything.
    @discardableResult
    func performPress() -> Bool { false }

    /// The title label and icon that draw the button: the button itself announces the title, so
    /// VoiceOver would otherwise read it twice. Controls inside (a hide or gear button) stay reachable.
    func hideDrawingFromAccessibility(_ views: NSView?...) {
        for view in views.compactMap({ $0 }) {
            view.setAccessibilityElement(false)
            // An image view or label reaches VoiceOver through its cell as well as itself.
            (view as? NSControl)?.cell?.setAccessibilityElement(false)
        }
    }

    // MARK: - Keyboard

    override var acceptsFirstResponder: Bool { isPressable }
    override var canBecomeKeyView: Bool { NSApp.isFullKeyboardAccessEnabled && isPressable && !isHiddenOrHasHiddenAncestor }
    override var focusRingMaskBounds: NSRect { bounds }

    override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius).fill()
    }

    /// Tab into a sidebar row below the fold (TOOLS expanded) and it scrolls into view, so the focus
    /// ring is never on something the person can't see.
    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else { return false }
        scrollToVisible(bounds)
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard Self.pressKeys.contains(event.charactersIgnoringModifiers ?? "") else { return super.keyDown(with: event) }
        performPress()
    }

    // MARK: - Accessibility

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .button }
    override func accessibilityLabel() -> String? { spokenTitle }
    override func isAccessibilityEnabled() -> Bool { isPressable }
    override func accessibilityPerformPress() -> Bool { performPress() }
}
