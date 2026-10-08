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

    /// Whether the allowed-activity tab bar is really on screen. Its bar is only unhidden when an
    /// allowed-app habit STARTS and only re-hidden when the next habit starts, so after the routine's
    /// last habit ends it stays unhidden inside a player that has already been taken out of the
    /// habits area. Trusting the bar alone sent the end-of-routine Day Plan into that detached player
    /// and left the main window blank (report 2026-09-28_13-28-20).
    /// - Parameters:
    ///   - isTabBarUnhidden: the tab bar's own hidden flag is off.
    ///   - isHabitPlayerMounted: the habit player's view is still in the habits area.
    static func isAllowedActivityTabBarOnScreen(isTabBarUnhidden: Bool, isHabitPlayerMounted: Bool) -> Bool {
        isTabBarUnhidden && isHabitPlayerMounted
    }
}
