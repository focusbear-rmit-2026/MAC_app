//
//  DNDManager.swift
//  FocusBear
//
//  Created by Manish Jain on 28/05/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import AppKit
import CoreGraphics

/// Do Not Disturb, driven by synthesising an option-click on the menu-bar clock because macOS
/// exposes no API for it.
///
/// That click goes into the user's menu bar, so it can dismiss a menu they have open — reported as
/// "when I open the Focus Bear menu or any other menu bar item, it closes after a second". Three
/// things keep that from happening, all decided in `DNDClickPolicy.swift`:
///
///  1. requests are coalesced, so a toggle that reverses within its settle window costs no click;
///  2. the click waits while the user is in their menu bar;
///  3. the reveal warp and its one-second wait are skipped unless the menu bar is auto-hidden.
class DNDManager {
    static let shared = DNDManager()

    private let coalescer = DNDRequestCoalescer(appliedState: DNDManager.restoredAppliedState())
    private var reconcileTimer: Timer?
    private var waitingForMenuBarSince: Date?
    private var appliedStateHeartbeat: Timer?

    /// What the app has asked for. Call sites read this to decide whether a release is owed, so it
    /// deliberately reports the *requested* state: a request still inside its settle window already
    /// counts as done, which is what makes a reversal collapse instead of queueing a second click.
    var isDndEnabled: Bool { coalescer.desiredState }

    func setDND(_ enable: Bool, settle: DNDSettleWindow = .standard) {
        let requestedAt = Date()
        onMainThread { [weak self] in
            guard let self else { return }
            addLog(text: "Request DND: \(enable)")

            if enable, self.isDNDOrFocusActive() {
                addLog(text: "Return:- Dnd Already enabled")
                return
            }

            MenuBarActivityProbe.shared.startMonitoring()
            self.refreshAppliedStateHeartbeat()

            guard let deadline = self.coalescer.request(enable, at: requestedAt, settle: settle) else {
                addLog(text: "DND: \(enable) is already what the menu bar was asked for — no click needed")
                self.cancelReconcile()
                return
            }
            addLog(text: "DND: \(enable) queued, settling for \(Int(settle.seconds))s")
            self.scheduleReconcile(at: deadline)
        }
    }

    // MARK: - Deciding whether the click still has to happen

    private func scheduleReconcile(at deadline: Date) {
        reconcileTimer?.invalidate()
        reconcileTimer = Timer.scheduledTimer(withTimeInterval: max(0, deadline.timeIntervalSinceNow),
                                              repeats: false) { [weak self] _ in
            self?.reconcile()
        }
    }

    private func cancelReconcile() {
        reconcileTimer?.invalidate()
        reconcileTimer = nil
        waitingForMenuBarSince = nil
    }

    private func reconcile() {
        let now = Date()

        guard coalescer.isDue(at: now) else {
            if let deadline = coalescer.pendingDeadline { scheduleReconcile(at: deadline) }
            return
        }

        // Asked before the request is committed, so a reversal arriving mid-deferral still collapses.
        switch MenuBarClickPolicy.decide(activity: MenuBarActivityProbe.shared.activity(),
                                         now: now, waitingSince: waitingForMenuBarSince) {
        case .waitForTheUser:
            if waitingForMenuBarSince == nil {
                waitingForMenuBarSince = now
                addLog(text: "DND: the menu bar is in use — holding the click back")
            }
            scheduleReconcile(at: now.addingTimeInterval(kMenuBarDeferralRetrySeconds))
            return
        case .clickAnyway:
            addLog(text: "DND: menu bar still busy after \(Int(kMenuBarMaximumDeferralSeconds))s — clicking anyway")
        case .clickNow:
            break
        }
        waitingForMenuBarSince = nil

        switch coalescer.reconcile(at: now) {
        case .toggle(let enable):
            addLog(text: "Local DND state updated: \(enable)")
            persistAppliedState(enable, at: now)
            optionClickClock()
        case .settledWithoutClicking:
            addLog(text: "DND: request reversed before it was applied — collapsed to no menu-bar click")
        case .notYetDue(let deadline):
            scheduleReconcile(at: deadline)
        case .nothingPending:
            break
        }
    }

    // MARK: - Remembering what was clicked, across a relaunch

    private static func restoredAppliedState() -> Bool {
        let defaults = UserDefaults.standard
        let state = defaults.object(forKey: kUserdefaultsDNDAppliedState) as? Bool
        let savedAt = defaults.object(forKey: kUserdefaultsDNDAppliedStateSavedAt) as? Date
        let restored = DNDStateRestore.restoredState(persisted: state, savedAt: savedAt, now: Date())
        if restored {
            addLog(text: "DND: carrying the applied state (on) across the relaunch")
        }
        return restored
    }

    private func persistAppliedState(_ enable: Bool, at now: Date) {
        DNDManager.writeAppliedState(enable, at: now)
        refreshAppliedStateHeartbeat()
    }

    /// The stamp has to mean "the app was alive and Do Not Disturb was on this recently", not "this
    /// is when it was switched on" — otherwise a session longer than the trust window is forgotten
    /// across a relaunch, which is the case this exists to cover.
    private func refreshAppliedStateHeartbeat() {
        guard coalescer.appliedState else {
            appliedStateHeartbeat?.invalidate()
            appliedStateHeartbeat = nil
            return
        }
        guard appliedStateHeartbeat == nil else { return }
        appliedStateHeartbeat = Timer.scheduledTimer(withTimeInterval: kDNDAppliedStateHeartbeatSeconds,
                                                     repeats: true) { _ in
            DNDManager.writeAppliedState(true, at: Date())
        }
    }

    private static func writeAppliedState(_ enable: Bool, at now: Date) {
        UserDefaults.standard.set(enable, forKey: kUserdefaultsDNDAppliedState)
        UserDefaults.standard.set(now, forKey: kUserdefaultsDNDAppliedStateSavedAt)
    }

    // MARK: - The click itself

    /// Where the synthetic option-click has to land, and how much ceremony it needs. Resolved on the
    /// main thread because `NSScreen` is AppKit state; nothing else in the click is main-thread work.
    private struct ClockClickGeometry {
        let revealPoint: CGPoint
        let clickPoint: CGPoint
        let restorePoint: CGPoint
        /// The menu bar is auto-hidden, so the cursor has to park at the top edge and wait for it.
        let needsReveal: Bool
    }

    /// Serialised so two DND toggles in quick succession can't interleave their clicks and leave
    /// the cursor parked in the menu bar.
    private static let clockClickQueue = DispatchQueue(label: "com.focusbear.dnd.clock-click")

    private static func clockClickGeometry() -> ClockClickGeometry? {
        guard let menuBarScreen = NSScreen.main else { return nil }

        // NSScreen.frame is AppKit-flipped (Y up from the bottom of the primary screen); CGEvent
        // wants Y down from the top. Convert once here rather than at each use.
        let primaryScreenHeight = NSScreen.screens[0].frame.height
        let screenFrame = menuBarScreen.frame
        let cgY = primaryScreenHeight - (screenFrame.origin.y + screenFrame.height)
        let cgX = screenFrame.origin.x + screenFrame.width - 60

        let oldLocation = NSEvent.mouseLocation
        return ClockClickGeometry(
            revealPoint: CGPoint(x: cgX, y: cgY),
            clickPoint: CGPoint(x: cgX, y: cgY + 11),
            restorePoint: CGPoint(x: oldLocation.x, y: primaryScreenHeight - oldLocation.y),
            needsReveal: MenuBarRevealPolicy.needsReveal(
                screenFrame: screenFrame, visibleFrame: menuBarScreen.visibleFrame,
                prefersAutoHiddenMenuBar: prefersAutoHiddenMenuBar()))
    }

    /// The system-wide "Automatically hide and show the menu bar" setting, plus whatever our own app
    /// has asked for — either one means the menu bar may not be there when the click arrives.
    private static func prefersAutoHiddenMenuBar() -> Bool {
        if NSApp?.presentationOptions.contains(.autoHideMenuBar) == true { return true }
        return UserDefaults.standard.bool(forKey: kGlobalAutoHideMenuBarDefaultsKey)
    }

    private static func post(_ type: CGEventType, at point: CGPoint,
                             source: CGEventSource?, optionDown: Bool = false) {
        guard let event = CGEvent(mouseEventSource: source, mouseType: type,
                                  mouseCursorPosition: point, mouseButton: .left) else { return }
        if optionDown { event.flags = .maskAlternate }
        event.post(tap: .cgSessionEventTap)
    }

    /// Toggles Do Not Disturb by option-clicking the menu-bar clock. Runs entirely off the main
    /// thread: posting a Quartz event reaches IOHIDPostEvent, whose first call dlopens a framework,
    /// and a slow dlopen on the main thread beachballs the whole app mid-click — observed hanging the
    /// meeting "pausing your habits" prompt.
    private static func postOptionClick(_ geometry: ClockClickGeometry) {
        if geometry.needsReveal {
            // Move the cursor to the top edge, or an auto-hidden menu bar isn't there to be clicked,
            // then let it animate down — clicking before it arrives hits whatever is underneath.
            CGWarpMouseCursorPosition(geometry.revealPoint)
            post(.mouseMoved, at: geometry.revealPoint, source: nil)
            Thread.sleep(forTimeInterval: kAutoHiddenMenuBarRevealSeconds)
        } else {
            // A permanently visible menu bar needs neither the warp nor the wait; posting the move at
            // the clock is enough for the hover to register. This is what shrinks the window in which
            // the click can steal one of the user's from ~1.1s to ~0.1s.
            post(.mouseMoved, at: geometry.clickPoint, source: nil)
            Thread.sleep(forTimeInterval: kClockClickPacingSeconds)
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        post(.leftMouseDown, at: geometry.clickPoint, source: source, optionDown: true)
        Thread.sleep(forTimeInterval: kClockClickPacingSeconds)
        post(.leftMouseUp, at: geometry.clickPoint, source: source, optionDown: true)

        // Warping back too soon re-opens the menu it just closed (regression fixed in 3.32.491).
        Thread.sleep(forTimeInterval: kClockClickPacingSeconds)
        CGWarpMouseCursorPosition(geometry.restorePoint)
        post(.mouseMoved, at: geometry.restorePoint, source: nil)
    }

    func optionClickClock() {
        onMainThread {
            guard let geometry = DNDManager.clockClickGeometry() else {
                addLog(text: "DND: no menu bar screen, skipping the clock click")
                return
            }
            DNDManager.clockClickQueue.async {
                DNDManager.postOptionClick(geometry)
            }
        }
    }

    func isDNDOrFocusActive() -> Bool {
        let defaults = UserDefaults.standard
        // Read the persistent domain for the Control Center directly
        defaults.synchronize()
        if let controlCenterPrefs = defaults.persistentDomain(forName: "com.apple.controlcenter") {

            // 1. Check the universal master focus visibility token (macOS 13+)
            if let focusModeState = controlCenterPrefs["NSStatusItem Visible FocusModes"] as? Int, focusModeState == 1 {
                return true
            }

            // 2. Check the legacy standalone DND visibility token
            if let dndState = controlCenterPrefs["NSStatusItem Visible DoNotDisturb"] as? String, dndState == "1" {
                return true
            }
        }

        return false
    }

    private func onMainThread(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}

/// How long an auto-hidden menu bar takes to slide down once the cursor reaches the top edge.
let kAutoHiddenMenuBarRevealSeconds: TimeInterval = 1

/// Pacing between the parts of the synthetic click, so the menu bar sees a hover, a press and a
/// release rather than one indivisible event.
let kClockClickPacingSeconds: TimeInterval = 0.05

/// `NSGlobalDomain` key behind System Settings → "Automatically hide and show the menu bar".
let kGlobalAutoHideMenuBarDefaultsKey = "_HIHideMenuBar"

/// Comfortably inside the trust window, so a relaunch mid-session still finds a fresh stamp.
let kDNDAppliedStateHeartbeatSeconds: TimeInterval = 60
