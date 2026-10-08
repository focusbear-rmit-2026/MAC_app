//
//  PostponeGate.swift
//  Focus Bear
//
//  Which friction the postpone dialog should apply when it opens.
//
//  Repeated postponing is gated by a press-and-hold countdown (5→10→15s, `showHabitTimerView`).
//  Separately, settings can require the user's password before postponing. When BOTH applied, the
//  user paid twice: the password was asked first, and then — because the postpone dialog reopens
//  through `resetView()`, which only looked at `activityPostponeCount` — the hold countdown was
//  demanded again on the way back.
//
//  The password is the stronger gate, so satisfying it stands in for the hold. This keeps the rule
//  in one testable place instead of as a condition buried in `resetView()`.
//
//  User report: 2026-06-24_21-01-49 — "it shouldn't bother with the 5s countdown if a password is
//  required".
//

import Foundation

enum PostponeGate {

    /// What the postpone dialog should present when it opens.
    enum Step: Equatable {
        /// Straight to the postpone options (minutes dropdown / hold-to-set).
        case postponeOptions
        /// The press-and-hold confirmation first; completing it leads to the options.
        case holdToConfirm
    }

    /// - Parameters:
    ///   - activityPostponeCount: how many times this routine has already been postponed today.
    ///   - passwordAlreadySatisfied: the user just entered the correct password for *this* postpone.
    static func step(activityPostponeCount: Int, passwordAlreadySatisfied: Bool) -> Step {
        // Entering the password is friction enough — don't charge for the hold as well.
        if passwordAlreadySatisfied { return .postponeOptions }
        // The hold only escalates once they've started postponing repeatedly.
        return activityPostponeCount == 0 ? .postponeOptions : .holdToConfirm
    }
}
