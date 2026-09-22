//
//  DayPlanDestination.swift
//  Focus Bear
//
//  Where the menu's "View full day plan" should actually take the user.
//
//  There are two Day Plans on screen at different times: the main window's own pane (reached via
//  the sidebar's Day Plan row) and the copy embedded as a tab inside the allowed-activity habit
//  player. While an allowed-app habit is playing, the player owns the habits area and
//  `leftMenuVc.showDayPlanForCurrentState()` deliberately early-returns (a routine is live), so
//  aiming at the main window's pane left the user looking at the Habit Player tab.
//
//  User report: 2026-06-25_18-11-05 — "if an allowed app habit is running, it should switch to the
//  day plan task".
//

import Foundation

enum DayPlanDestination {

    enum Target: Equatable {
        /// The main window's Day Plan pane (sidebar row + `showDayPlanForCurrentState()`).
        case mainWindowDayPlan
        /// The Day Plan tab embedded in the allowed-activity habit player.
        case allowedActivityDayPlanTab
    }

    /// - Parameter hasAllowedActivityTabs: whether the allowed-activity player's
    ///   "Habit Player | Day Plan" tab bar is currently on screen.
    static func target(hasAllowedActivityTabs: Bool) -> Target {
        hasAllowedActivityTabs ? .allowedActivityDayPlanTab : .mainWindowDayPlan
    }
}
