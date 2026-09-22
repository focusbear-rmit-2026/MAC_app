//
//  DNDClickPolicy.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation
import CoreGraphics

/// macOS exposes no API for Do Not Disturb, so Focus Bear toggles it by synthesising an option-click
/// on the menu-bar clock. That click goes into the *user's* menu bar: if a menu is open when it
/// fires, it dismisses their menu instead. This file holds the three decisions that keep that from
/// happening — when a click is owed at all, when it may be posted, and how much work it takes —
/// deliberately free of AppKit instances and timers so each one can be tested on its own.

// MARK: - Settle windows

/// How long a Do Not Disturb request is held before it is acted on.
///
/// Holding it briefly lets a reversal cancel the click outright, so a focus session that starts and
/// is abandoned seconds later costs no menu-bar clicks at all.
enum DNDSettleWindow {
    /// A start or stop the user asked for. They are watching, so it should take effect promptly.
    case standard
    /// The app started this session on the user's behalf — a meeting detected on the calendar, an
    /// approved postpone. These are the ones that get dismissed: measured on a real machine, a
    /// meeting session started at 15:58:02 and was stopped at 15:58:12, and another started at
    /// 16:57:57 and was cancelled at 16:58:01.
    case autoStartedSession
    /// The session ended into the "session complete — extend?" screen, so from the user's point of
    /// view it may not be over. Measured: a session finished at 16:22:31 and was extended at
    /// 16:22:46 — two menu-bar clicks for a session that never actually stopped.
    case sessionMayBeExtended

    var seconds: TimeInterval {
        switch self {
        case .standard: return kDNDStandardSettleSeconds
        case .autoStartedSession: return kDNDAutoStartSettleSeconds
        case .sessionMayBeExtended: return kDNDExtendOfferSettleSeconds
        }
    }
}

/// Short enough that a start the user asked for still feels immediate, long enough to swallow the
/// stray double-toggle.
let kDNDStandardSettleSeconds: TimeInterval = 6

/// Long enough to cover the time it takes to notice an unwanted meeting session and stop it —
/// measured at 4s and 10s. Nobody asked for this session, so nobody is waiting on its Do Not Disturb.
let kDNDAutoStartSettleSeconds: TimeInterval = 20

/// Covers the time the "extend?" screen is on screen. Releasing DND late only means notifications
/// resume a few seconds later than they could have; releasing it early costs two clicks.
let kDNDExtendOfferSettleSeconds: TimeInterval = 25

// MARK: - Coalescing

/// What reconciling a pending Do Not Disturb request came out to.
enum DNDReconciliation: Equatable {
    /// The system has to be toggled — a menu-bar click is owed.
    case toggle(to: Bool)
    /// The request reversed itself before its settle window elapsed; nothing to do.
    case settledWithoutClicking
    /// The settle window has not elapsed yet; ask again then.
    case notYetDue(deadline: Date)
    /// No request is outstanding.
    case nothingPending
}

/// Turns a stream of "DND should be on / off" requests into the smallest number of menu-bar clicks
/// that gets the system where the app wants it.
///
/// Focus sessions have transient boundaries — a meeting session auto-started and immediately
/// cancelled, a session that finishes and is extended — and driving the clock click straight off
/// those edges paid for every one of them. This collapses a request and its reversal to nothing.
final class DNDRequestCoalescer {

    /// What the app most recently asked for.
    private(set) var desiredState: Bool

    /// What has actually been clicked into the menu bar.
    private(set) var appliedState: Bool

    private var deadline: Date?

    init(appliedState: Bool = false) {
        self.appliedState = appliedState
        self.desiredState = appliedState
    }

    var pendingDeadline: Date? { deadline }

    func isDue(at now: Date) -> Bool {
        guard let deadline else { return false }
        return now >= deadline
    }

    /// Records what the app now wants.
    /// - Returns: the moment `reconcile(at:)` should next be called, or `nil` when the request asks
    ///   for the state the menu bar is already in — including the case where it cancels one that was
    ///   still waiting out its settle window.
    @discardableResult
    func request(_ enable: Bool, at now: Date, settle: DNDSettleWindow) -> Date? {
        desiredState = enable
        guard enable != appliedState else {
            deadline = nil
            return nil
        }
        let candidate = now.addingTimeInterval(settle.seconds)
        // Never push an already-pending click further out: a run of requests must not be able to
        // starve the toggle indefinitely.
        deadline = deadline.map { min($0, candidate) } ?? candidate
        return deadline
    }

    /// Commits the pending request once its settle window has elapsed.
    func reconcile(at now: Date) -> DNDReconciliation {
        guard let deadline else { return .nothingPending }
        guard now >= deadline else { return .notYetDue(deadline: deadline) }
        self.deadline = nil
        guard desiredState != appliedState else { return .settledWithoutClicking }
        appliedState = desiredState
        return .toggle(to: appliedState)
    }
}

// MARK: - Surviving a relaunch

/// Whether the Do Not Disturb state recorded before the app last stopped can still be believed.
///
/// The applied state is the app's only record of what it has done to the menu bar, and it used to
/// live in memory alone. Yesterday's log shows three consecutive "turn it on" state changes with no
/// "off" between them — the app had forgotten across a relaunch, so it clicked to enable something
/// that was already enabled, which on this mechanism turns it *off*.
///
/// Trusted only briefly: a relaunch (an update, a crash) is seconds or minutes, whereas an overnight
/// gap says nothing about what the user has done with Do Not Disturb since.
enum DNDStateRestore {

    static func restoredState(persisted: Bool?, savedAt: Date?, now: Date) -> Bool {
        guard let persisted, let savedAt, savedAt <= now,
              now.timeIntervalSince(savedAt) < kDNDStateTrustWindowSeconds else { return false }
        return persisted
    }
}

/// Long enough to cover an app restart, short enough that a state from hours ago is discarded.
let kDNDStateTrustWindowSeconds: TimeInterval = 300

let kUserdefaultsDNDAppliedState = "kUserdefaultsDNDAppliedState"
let kUserdefaultsDNDAppliedStateSavedAt = "kUserdefaultsDNDAppliedStateSavedAt"

// MARK: - Is the user in their menu bar?

/// Everything the click needs to know about what the user is doing with their menu bar.
struct MenuBarActivity: Equatable {
    /// A menu is open somewhere on screen — ours or another app's.
    let isAnyMenuOpen: Bool
    /// The pointer is inside the menu bar strip right now.
    let isCursorInMenuBar: Bool
    /// When the user last clicked in the menu bar, if they have.
    let lastMenuBarClick: Date?

    static let idle = MenuBarActivity(isAnyMenuOpen: false, isCursorInMenuBar: false, lastMenuBarClick: nil)
}

enum MenuBarClickDecision: Equatable {
    case clickNow
    case waitForTheUser
    /// The menu bar has been busy longer than we are prepared to wait. Do Not Disturb actually
    /// working matters more than the remaining chance of stealing a click.
    case clickAnyway
}

/// A click that lands while the user has a menu open dismisses that menu. Deferring costs nothing —
/// Do Not Disturb a second or two late is invisible — so the default is to wait.
enum MenuBarClickPolicy {

    static func decide(activity: MenuBarActivity, now: Date, waitingSince: Date?) -> MenuBarClickDecision {
        guard isMenuBarInUse(activity, now: now) else { return .clickNow }
        guard let waitingSince,
              now.timeIntervalSince(waitingSince) >= kMenuBarMaximumDeferralSeconds else {
            return .waitForTheUser
        }
        return .clickAnyway
    }

    private static func isMenuBarInUse(_ activity: MenuBarActivity, now: Date) -> Bool {
        if activity.isAnyMenuOpen || activity.isCursorInMenuBar { return true }
        guard let lastClick = activity.lastMenuBarClick else { return false }
        return now.timeIntervalSince(lastClick) < kMenuBarQuietPeriodSeconds
    }
}

/// A click in the menu bar is usually followed within a moment by a menu opening, and the menu's own
/// tracking loop then starves our event monitors. Treating the click as "busy" for a beat covers the
/// gap between the two.
let kMenuBarQuietPeriodSeconds: TimeInterval = 2

/// How often to re-ask while deferring.
let kMenuBarDeferralRetrySeconds: TimeInterval = 1

/// A pointer parked in the menu bar must not disable Do Not Disturb for the rest of the session.
let kMenuBarMaximumDeferralSeconds: TimeInterval = 60

// MARK: - How much work the click takes

/// Whether the cursor has to be parked at the top of the screen — and the menu bar given a second to
/// slide down — before the click can land.
///
/// That reveal exists only for an auto-hidden menu bar. When the menu bar is permanently visible it
/// buys nothing and costs the whole second during which a click can be stolen.
enum MenuBarRevealPolicy {

    /// The menu bar is occupying screen space right now, so there is nothing to reveal. `visibleFrame`
    /// is the screen minus the menu bar and the Dock, and only the menu bar eats into the top edge.
    static func isMenuBarOnScreen(screenFrame: CGRect, visibleFrame: CGRect) -> Bool {
        screenFrame.maxY - visibleFrame.maxY >= kMinimumMenuBarHeightPoints
    }

    static func needsReveal(screenFrame: CGRect, visibleFrame: CGRect,
                            prefersAutoHiddenMenuBar: Bool) -> Bool {
        // Belt and braces: trust the preference, but also reveal if the menu bar measurably is not
        // on screen (a full-screen app owning the display, say).
        prefersAutoHiddenMenuBar || !isMenuBarOnScreen(screenFrame: screenFrame, visibleFrame: visibleFrame)
    }
}

/// Comfortably under the shortest real menu bar (24pt) and well clear of rounding noise.
let kMinimumMenuBarHeightPoints: CGFloat = 16
