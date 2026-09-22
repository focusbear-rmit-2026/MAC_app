import AppKit
import SwiftUI

/// A real continuous mouse/key hold. No click, Return default action, accessibility press, or keyboard
/// repeat can invoke confirmation. Space/Return key-up and mouse release always cancel incomplete holds.
struct AccountabilityHoldButton: NSViewRepresentable {
    let minutes: Int?
    let title: String
    let help: String
    let onProgress: (Double) -> Void
    let onConfirmed: (Int) -> Void

    func makeNSView(context: Context) -> AccountabilityHoldControl {
        let button = AccountabilityHoldControl()
        button.bezelStyle = .rounded
        button.controlSize = .large
        return button
    }

    func updateNSView(_ button: AccountabilityHoldControl, context: Context) {
        button.title = title
        button.toolTip = help
        button.setAccessibilityHelp(help)
        button.onProgress = onProgress
        button.onConfirmed = onConfirmed
        button.configure(minutes: minutes)
    }

    static func dismantleNSView(_ button: AccountabilityHoldControl, coordinator: ()) {
        button.cancelHold()
    }
}

final class AccountabilityHoldControl: NSButton {
    var onProgress: (Double) -> Void = { _ in }
    var onConfirmed: (Int) -> Void = { _ in }
    private var recovery = AccountabilityPostponeRecovery()
    private var timer: Timer?
    private var tracking: NSTrackingArea?
    private var heldKey: UInt16?
    private var mouseIsHeld = false
    private var focusObservers: [NSObjectProtocol] = []

    override var acceptsFirstResponder: Bool { isEnabled }

    func configure(minutes: Int?) {
        guard recovery.selectedMinutes != minutes || !recovery.isAvailable else { return }
        cancelHold()
        recovery.select(minutes: minutes)
        recovery.setAvailable(true)
        isEnabled = recovery.selectedMinutes != nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking = tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        tracking = area
        addTrackingArea(area)
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled, window?.isKeyWindow == true else { return }
        window?.makeFirstResponder(self)
        mouseIsHeld = true
        beginHold()
    }

    override func mouseDragged(with event: NSEvent) {
        if !bounds.contains(convert(event.locationInWindow, from: nil)) { cancelHold() }
    }

    override func mouseUp(with event: NSEvent) { cancelHold() }
    override func mouseExited(with event: NSEvent) { cancelHold() }

    override func keyDown(with event: NSEvent) {
        // Key codes are physical Space, Return, keypad Enter; Escape always abandons the hold.
        if event.keyCode == 53 { cancelHold(); return }
        guard [49, 36, 76].contains(event.keyCode) else { super.keyDown(with: event); return }
        guard !event.isARepeat, heldKey == nil, isEnabled else { return }
        heldKey = event.keyCode
        beginHold()
    }

    override func keyUp(with event: NSEvent) {
        if heldKey == event.keyCode { cancelHold() } else { super.keyUp(with: event) }
    }

    override func resignFirstResponder() -> Bool { cancelHold(); return super.resignFirstResponder() }
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        cancelHold()
        focusObservers.forEach { NotificationCenter.default.removeObserver($0) }
        focusObservers.removeAll()
        if let newWindow = newWindow {
            for (name, object) in [(NSWindow.didResignKeyNotification, newWindow as Any),
                                   (NSApplication.didResignActiveNotification, NSApp as Any)] {
                focusObservers.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                    self?.cancelHold()
                })
            }
        }
        super.viewWillMove(toWindow: newWindow)
    }
    override func accessibilityPerformPress() -> Bool { false }

    private func beginHold() {
        guard timer == nil else { return }
        recovery.beginHold(at: ProcessInfo.processInfo.systemUptime)
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tick() {
        guard NSApp.isActive, window?.isKeyWindow == true,
              window?.firstResponder === self, !isHiddenOrHasHiddenAncestor,
              heldKey != nil || (mouseIsHeld && NSEvent.pressedMouseButtons & 1 == 1) else {
            cancelHold()
            return
        }
        let minutes = recovery.tick(at: ProcessInfo.processInfo.systemUptime)
        onProgress(recovery.progress)
        if let minutes = minutes {
            timer?.invalidate()
            timer = nil
            mouseIsHeld = false
            heldKey = nil
            onConfirmed(minutes)
        }
    }

    func cancelHold() {
        timer?.invalidate()
        timer = nil
        mouseIsHeld = false
        heldKey = nil
        recovery.resetHold()
        // Updating an NSViewRepresentable must not synchronously mutate SwiftUI state.
        DispatchQueue.main.async { [weak self] in self?.onProgress(0) }
    }

    deinit {
        timer?.invalidate()
        focusObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
