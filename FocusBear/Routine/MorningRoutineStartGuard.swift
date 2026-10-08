//
//  MorningRoutineStartGuard.swift
//  Focus Bear
//
//  Pure decision logic for "may the background poller start/resume the morning routine
//  right now?".
//
//  Background: `AppDelegate.backgroundThread()`'s `getLastActivityInfo` completion resumes a
//  pending morning routine. Its in_progress/postponed branch already refuses to do that while a
//  custom routine is running, but that `if` has no `else`, so control falls through to the
//  unconditional `startHabitsCall(...)` below it — which logs "Initiating morning habits." and
//  calls `abortAllProcess()`, tearing down the custom routine the user just started.
//
//  A custom routine owns the routine window while it runs, so every route into
//  `startHabitsCall` must respect it. Keeping the rule here (rather than repeating
//  `currentState != ._CUSTOM_ROUTINE_` at each call site) means the guard cannot be bypassed by
//  a future branch that forgets it, and makes the rule unit-testable without an app host.
//
//  User report: 2026-06-24_16-19-02 — "I tried starting a custom routine and it immediately
//  exited it and went back to morning routine".
//

import Foundation

enum MorningRoutineStartGuard {

    /// Whether morning habits may be started/resumed while the app is in `currentState`.
    ///
    /// A running custom routine is the one state that must veto it: starting morning habits
    /// aborts every in-flight process, which is exactly the reported bug.
    static func shouldStartMorningRoutine(currentState: CURRENTSTATE) -> Bool {
        currentState != ._CUSTOM_ROUTINE_
    }
}
