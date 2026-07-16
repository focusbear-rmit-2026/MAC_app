//
//  FocusGlowBorderManager.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

extension Notification.Name {
    /// Posted to tell every visible glow window to restart its one-time "glow worm" sweep — used to
    /// draw the eye back to the border right when something focus-relevant just happened, rather
    /// than waiting for the user to notice the (otherwise static) border on their own.
    static let focusGlowBorderPulseWorm = Notification.Name("focusGlowBorderPulseWorm")
}

/// Shows a glowing border around the edge of every screen while a focus session is running, as an
/// ambient reminder the user is "in the zone" — visible even when Focus Bear's own window isn't
/// (the user is normally in another app during a session).
///
/// There's no single start/stop notification for focus sessions in this codebase (isFocusModeRunning
/// is set imperatively at ~10 scattered call sites), so this polls isFocusModeOn() on its own 1-second
/// timer rather than trying to hook every toggle site — a missed site would otherwise leave the border
/// stuck on or off. A borderless, click-through, always-on-top window per screen (following the same
/// configuration this app's other overlay windows use — see getTransparentWindowObject() /
/// AppDelegate.showExtraWindows()) hosts the actual glow content.
final class FocusGlowBorderManager {
    static let shared = FocusGlowBorderManager()
    private init() {}

    private var pollTimer: Timer?
    private var windows: [NSWindow] = []
    private var isShowing = false

    func start() {
        guard pollTimer == nil else { return }
        refresh()
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildIfShowing),
                                                name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func refresh() {
        let isGlowEnabled = SettingsManagerObject.isFocusGlowBorderEnabled
        let shouldShow = isGlowEnabled && (isFocusModeOn() || isAnyAllowedFocusModeActivityRunning)
        guard shouldShow != isShowing else { return }
        isShowing = shouldShow
        shouldShow ? showWindows() : hideWindows()
    }

    /// Display reconfiguration (monitor plugged/unplugged) — rebuild to match the new screen list.
    @objc private func rebuildIfShowing() {
        guard isShowing else { return }
        hideWindows()
        showWindows()
    }

    /// Restarts the glow worm's one-time sweep on every currently-visible glow window — call this
    /// when something happened that the user should notice (a Late No More appointment popup, a URL
    /// just got blocked as off-task) instead of waiting for them to glance at the border. No-op if
    /// the border isn't currently showing (no active focus session, or the user has it turned off).
    func pulseWorm() {
        guard isShowing else { return }
        NotificationCenter.default.post(name: .focusGlowBorderPulseWorm, object: nil)
    }

    private func showWindows() {
        hideWindows()
        for screen in NSScreen.screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.maximumWindow)))
            // .fullScreenAuxiliary (not used by this app's other overlay windows) keeps the glow visible
            // even when another app — e.g. a code editor — is in native full-screen.
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.isExcludedFromWindowsMenu = true
            window.hidesOnDeactivate = false
            window.isRestorable = false
            window.animationBehavior = .none
            window.contentView = NSHostingView(rootView: FocusGlowBorderView())
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    private func hideWindows() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }
}
