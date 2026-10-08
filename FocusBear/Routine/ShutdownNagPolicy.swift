//
//  ShutdownNagPolicy.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// The evening shutdown check is driven by a five-second repeating timer, and `shutOffMac()` used to
/// run its whole pipeline on every one of those ticks. Measured in a user's log on 2026-09-16, that
/// came to "Initiating shut off process." every five seconds without pause for the entire evening
/// routine — 20:16:03, :08, :13, :18, :23, :28 … still going at 20:22:48 — each tick re-entering the
/// same branch and reaching the same `NSApp.activate(ignoringOtherApps: true)`.
///
/// Two separate decisions were tangled up in that, and this file holds both of them as plain
/// functions over values, free of AppKit, timers and globals so each can be tested on its own:
///
///  * **Should the nag run at all on this tick** — once per situation, not once per timer beat.
///  * **May we take focus to show it** — never out of a menu the user has open.

// MARK: - Should the nag fire on this tick

/// What the shutdown check is looking at right now. Two ticks that agree on all of it are the same
/// nag repeated; a difference means the routine, the user, or the clock actually moved on, which is
/// the only thing that earns a second prompt.
struct ShutdownNagSituation: Equatable {
    let state: CURRENTSTATE
    let action: ACTION
    /// Which habit the routine is sitting on. Advancing to the next one is a real change.
    let habitIndex: Int
    /// The global "cut off for high priority activities" time has passed.
    let isCutOffPassed: Bool

    init(state: CURRENTSTATE, action: ACTION, habitIndex: Int, isCutOffPassed: Bool) {
        self.state = state
        self.action = action
        self.habitIndex = habitIndex
        self.isCutOffPassed = isCutOffPassed
    }
}

/// The nag that last ran, and when.
struct ShutdownNagRecord: Equatable {
    let situation: ShutdownNagSituation
    let firedAt: Date
}

enum ShutdownNagDecision: Equatable {
    case fire
    case stayQuiet
}

/// A shutdown prompt the user has already seen does not become more persuasive by being shown again
/// five seconds later; it just takes the screen away from whatever they were doing. So the rule is
/// one prompt per situation, with a slow backstop repeat for the case where the user walked away.
enum ShutdownNagPolicy {

    /// - Parameter routineTornDownForWakeAt: when the wake/unlock handler last ended the running routine
    ///   so this check could rebuild it (`returnFromSystemSleepCheckAppStateAgain`).
    static func decide(isShutdownAborted: Bool,
                       situation: ShutdownNagSituation,
                       lastNag: ShutdownNagRecord?,
                       now: Date,
                       routineTornDownForWakeAt: Date? = nil) -> ShutdownNagDecision {
        // The user explicitly cancelled tonight's shutdown. Nothing below may overrule that.
        if isShutdownAborted { return .stayQuiet }
        guard let lastNag else { return .fire }
        // Waking the Mac ends the evening routine on purpose, relying on this check to put it back.
        // The state it leaves behind can look exactly like the one the last prompt saw, so without
        // this the routine stayed away until the ten-minute backstop: on 2026-09-25 the Mac woke at
        // 22:31:07, the routine was torn down, and nothing came back until 22:36:18.
        if let tornDown = routineTornDownForWakeAt, tornDown > lastNag.firedAt { return .fire }
        // Something actually changed — a habit finished, the cut-off passed, the routine moved state.
        if lastNag.situation != situation { return .fire }
        guard now.timeIntervalSince(lastNag.firedAt) >= kShutdownNagRepeatSeconds else { return .stayQuiet }
        return .fire
    }

    /// Whether a stored "shutdown aborted until" date is still in force.
    static func isAborted(abortedUntil: Date?, now: Date) -> Bool {
        guard let abortedUntil else { return false }
        return now < abortedUntil
    }
}

/// Long enough that a user sitting at their machine is never nagged twice about the same thing, short
/// enough that someone who walked away mid-routine is still picked up again before the night is out.
let kShutdownNagRepeatSeconds: TimeInterval = 600

// MARK: - May we take focus to show it

/// How much the thing we are about to show is worth to the user.
enum ShutdownFocusUrgency: Equatable {
    /// Telling the user about something that already happened — a habit skipped because its cut-off
    /// passed. Nothing breaks if they read it a moment later.
    case notice
    /// The shutdown screen itself. This one is the point of the feature and has to be seen.
    case shutdownStarting
}

enum ShutdownFocusDecision: Equatable {
    /// `activate(ignoringOtherApps: true)` — the strongest grab macOS offers, and the one that
    /// dismisses any open menu in any application.
    case takeFocus
    /// Come forward the polite way, behind whatever the user is doing.
    case requestAttention
    /// The user is in a menu right now. Touch nothing.
    case deferToUser
}

/// `activate(ignoringOtherApps: true)` dismisses any open menu in any app, which is how a user trying
/// to open CleanShot's menu bar item ended up reporting that their clicks were being eaten. It is
/// only ever justified for the shutdown itself, and even then not while a menu is open — deferring a
/// second costs nothing.
enum ShutdownFocusPolicy {

    static func decide(urgency: ShutdownFocusUrgency,
                       menuBar: MenuBarActivity,
                       now: Date,
                       waitingSince: Date?) -> ShutdownFocusDecision {
        guard isMenuBarInUse(menuBar, now: now) else {
            return urgency == .shutdownStarting ? .takeFocus : .requestAttention
        }
        // A menu is open. A notice can simply wait for the next time we are asked.
        guard urgency == .shutdownStarting else { return .deferToUser }
        // The shutdown genuinely has to happen, but give the user their menu first — up to a point,
        // so a pointer parked in the menu bar can't hold the shutdown off all night.
        guard let waitingSince,
              now.timeIntervalSince(waitingSince) >= kShutdownFocusMaximumDeferralSeconds else {
            return .deferToUser
        }
        return .takeFocus
    }

    /// Reuses the menu-bar detector the Do Not Disturb work already built rather than adding a second
    /// one: with no deferral started, `MenuBarClickPolicy` says `.clickNow` exactly when the menu bar
    /// is free.
    private static func isMenuBarInUse(_ menuBar: MenuBarActivity, now: Date) -> Bool {
        MenuBarClickPolicy.decide(activity: menuBar, now: now, waitingSince: nil) != .clickNow
    }
}

/// How long the shutdown screen will wait for a user who is in a menu. Short — this is the one
/// prompt in the app that is allowed to insist.
let kShutdownFocusMaximumDeferralSeconds: TimeInterval = 10

/// How often to re-ask while holding the shutdown screen back.
let kShutdownFocusRetrySeconds: TimeInterval = 1
