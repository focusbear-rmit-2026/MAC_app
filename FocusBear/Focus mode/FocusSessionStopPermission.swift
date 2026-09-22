//
//  FocusSessionStopPermission.swift
//  Focus Bear
//
//  Who started the focus session that's running, and whether Stop / Pause may therefore be
//  password-gated. Super-strict exists so a session the USER opted into can't be abandoned on a whim —
//  it was never meant to trap the user in a session the APP started for them (a Late No More meeting,
//  or an approved-postpone accountability buddy). Those must stay stoppable and pausable at any
//  strictness, for the session's whole life, including after a relaunch.
//
//  The decisions are pure functions so they can be unit-tested without the app running; the globals
//  they read are marshalled by `isCurrentFocusSessionAutoStarted()` / `restoreFocusSessionAutoStarted…`.
//

import Foundation

/// True while the currently running (or paused) focus session was started by the app rather than by the
/// user. Persisted, so it survives a relaunch/crash: `resumeFocusModeAfterAppStartted` restores it right
/// where it restores the strictness, independently of `restoreAccountabilityBuddySessionIfNeeded()` —
/// that one can only attach once `isFocusModeRunning` is true, and if it fails the resumed meeting
/// session is left super-strict with no buddy attached, i.e. impossible to stop.
var isFocusSessionAutoStarted = false

/// Keys inside the persisted marker dictionary.
private let kFocusSessionAutoStartedFlagKey = "autoStarted"
private let kFocusSessionAutoStartedModeIdKey = "focusModeId"

/// The focus mode the marker is recorded against. `getRunningFocusModeId()` scans `arrFocusType` for the
/// `isOn` entry, which every start path sets before the marker is written; `currentRunningFocusType` is
/// the fallback for the restore path, where the resumed mode is assigned to that global directly.
private func runningFocusModeIdForAutoStartedMarker() -> String {
    let idFromList = getRunningFocusModeId()
    return idFromList.isEmpty ? (currentRunningFocusType["id"] as? String ?? "") : idFromList
}

/// Record whether the session that just started was auto-started, in memory and on disk at once, so the
/// two can never disagree. Scoped to the running focus mode, so the marker can only ever be applied back
/// to that same session.
///
/// Deliberately NOT cleared when the session finishes. The marker describes the LAST session started,
/// and every start (`focusModeStartted`, on every path) overwrites it — so it can't leak onto a session
/// the user starts themselves. Letting it outlive its own session is what keeps a session the backend
/// re-reports as running after the app was killed (see `checkIsAnyOldFoucsModeRemaining`) stoppable
/// rather than resurrecting it as a locked super-strict session the user can't end.
func setFocusSessionAutoStarted(_ autoStarted: Bool) {
    isFocusSessionAutoStarted = autoStarted
    UserDefaults.standard.set([kFocusSessionAutoStartedFlagKey: autoStarted,
                               kFocusSessionAutoStartedModeIdKey: runningFocusModeIdForAutoStartedMarker()],
                              forKey: kUserdefaultsIsFocusSessionAutoStarted)
}

/// Re-read the marker for a focus session the app resumed after a relaunch. Scoped to the focus mode
/// being resumed: a marker recorded for a different mode says nothing about this session, so it reads as
/// user-started and keeps its password gate.
func restoreFocusSessionAutoStartedFlag(resumedFocusModeId: String) {
    let stored = UserDefaults.standard.dictionary(forKey: kUserdefaultsIsFocusSessionAutoStarted)
    isFocusSessionAutoStarted = FocusSessionStopPermission.restoredAutoStartedFlag(
        storedFlag: stored?[kFocusSessionAutoStartedFlagKey] as? Bool,
        storedFocusModeId: stored?[kFocusSessionAutoStartedModeIdKey] as? String,
        resumedFocusModeId: resumedFocusModeId)
}

/// True when no marker has ever been written — a session started by a build that predates it, where
/// "user-started" would be a guess rather than a fact. Callers that must stay compatible with such a
/// session treat this as unknown rather than as a negative answer.
func focusSessionAutoStartedMarkerIsAbsent() -> Bool {
    UserDefaults.standard.dictionary(forKey: kUserdefaultsIsFocusSessionAutoStarted) == nil
}

/// Whether the running session was auto-started, reading the app's live globals.
func isCurrentFocusSessionAutoStarted() -> Bool {
    FocusSessionStopPermission.isAutoStarted(flag: isFocusSessionAutoStarted,
                                             hasLiveBuddySession: currentAccountabilityBuddySession != nil)
}

/// Whether Stop / Pause must password-gate the running session, reading the app's live globals.
func currentFocusSessionRequiresPasswordToStop() -> Bool {
    FocusSessionStopPermission.requiresPassword(strictness: currentFocusModeStrictness,
                                                flag: isFocusSessionAutoStarted,
                                                hasLiveBuddySession: currentAccountabilityBuddySession != nil)
}

enum FocusSessionStopPermission {

    /// True when the running session was started by the app, not the user.
    ///
    /// `flag` is the durable marker that survives a relaunch. `hasLiveBuddySession` is the in-memory
    /// `currentAccountabilityBuddySession`. Either alone is enough: the flag covers a session restored
    /// after a restart (when the buddy globals are gone, or its restore hasn't run yet), the buddy
    /// session covers one started before the marker existed.
    static func isAutoStarted(flag: Bool, hasLiveBuddySession: Bool) -> Bool {
        flag || hasLiveBuddySession
    }

    /// True when Stop / Pause must demand the password (or the random-characters view, when no password
    /// is set). Super-strict is the only strictness that gates, and an auto-started session never does.
    static func requiresPassword(strictness: FOCUSMODESTRICTNESS,
                                 flag: Bool,
                                 hasLiveBuddySession: Bool) -> Bool {
        if isAutoStarted(flag: flag, hasLiveBuddySession: hasLiveBuddySession) { return false }
        return strictness == ._SUPER_STRICT_
    }

    /// The marker to apply to a session resumed after a relaunch. Only a marker recorded for the SAME
    /// focus mode counts; anything else (no marker at all, or one from a different mode) reads as
    /// user-started, so a resumed session is never unlocked on the strength of an unrelated record.
    static func restoredAutoStartedFlag(storedFlag: Bool?,
                                        storedFocusModeId: String?,
                                        resumedFocusModeId: String) -> Bool {
        guard let storedFlag, let storedFocusModeId, storedFocusModeId == resumedFocusModeId else {
            return false
        }
        return storedFlag
    }
}
